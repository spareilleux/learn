extends RefCounted
## The package, run as a reader runs it, with what it shows written down (artpass/publish/rtx/NOTES.md).
## rtx_play.gd starts it when the program is given a folder to write to:
##   Observatory-RTX.exe -- --rtx-probe=<dir> [--rtx-ladder]
## 15 s after the start: what the player chose, the line, the badge, the buttons, the scene's quality
## level, the fill lights, a capture and its mean luma (start.png). Where it started path traced: the same
## 60 s after the start (the fork brings the materials into the rays over the first half minute, then the
## player steers DLSS's setting for 60 frames a second; pt.png); then a click on the frame generation
## button and the state 6 s later (fg), a click on the path tracing button and the state 8 s later
## (raster.png), each click a real mouse event at the button's centre, with the mouse mode after it: a
## button must not hand the mouse to the scene. With --rtx-ladder (and --rtx-slow-fps=<more than the card
## renders>), nothing is clicked: the state 75 s after the start, when the player has stepped down through
## DLSS's settings and switched the path tracer off (ladder.png). Writes report.json, prints it on one
## line, RTXPROBE {...}, and quits.
## --rtx-quick stops after the first capture. --rtx-sweep=<variant>,<variant>,... compares looks of the
## hall in one run, from 40 s after the start, the DLSS setting no longer steered: a variant is letters
## with their numbers, f the fill lights' energy (times observatory.gd's), e the exposure (times the
## scene's), b the bounces, s the samples a pixel, a the ambient energy (times the scene's), d the DLSS
## setting (0 DLAA to 4 Ultra Performance), p the path tracer (1 or 0), g frame generation (1 or 0), k the
## hall's reading lamps' energy (times observatory.gd's) while path tracing; f, e, a, k at 1 and b, s at
## the scene's own where a variant does not name them, d, p and g as they are.
## Anything after the last number only tells two variants apart. Each is captured 5 s after it is set
## (--rtx-hold=<s> for longer: a change of bounces or samples compiles new hit shaders), as
## sweep_<variant>.png, with its state. Without DLSS the sweep runs too, rasterized (the edges of the
## scene's own anti-aliasing).
## With --rtx-motion, each variant is also judged on its edges, on one place of the picture (REGION, as
## the start view shows it): two frames in a row at rest, how much they differ and how sharp they are
## (<variant>-rest.png), and the same while the camera turns 2 degrees a second (<variant>-move.png).
## --rtx-views[=<name>,...] ends the run with views of the place, the camera put there and the hints
## hidden, each captured 6 s after (view_<name>.png): after the sweep as its last variant left the
## program, or from 45 s after the start as the player steers it.

const AXIS_DEG := 236.25  # the wing's axis, and the views, as artpass/foundation/foundationshots.gd has them
const VIEWS := {
	"hall": [Vector3(0.0, 1.7, 10.4), Vector3(0.0, 6.0, 0.0), 64.0],
	"hall_axis": ["@", Vector3(10.5, 1.7, 0.0), Vector3(60.0, 4.0, 0.0), 64.0],
	"wing_mid": ["@", Vector3(40.0, 1.7, -2.4), Vector3(44.0, 3.4, 6.5), 64.0],
	"wing_gallery": ["@", Vector3(25.0, 6.7, -5.2), Vector3(60.0, 6.5, -5.2), 66.0],
	"wing_window": ["@", Vector3(30.0, 1.7, 0.0), Vector3(70.0, 4.5, 0.0), 64.0],
	"terrace": [Vector3(11.0, 1.7, 20.5), Vector3(260.0, 45.0, 1600.0), 62.0],
	"basin": [Vector3(0.0, -8.3, 66.0), Vector3(0.0, -5.5, 95.0), 55.0],
	"palace": [Vector3(0.0, -8.3, 230.0), Vector3(0.0, 2.0, 430.0), 64.0],
	"roof_city": [Vector3(10.15, 26.0, 3.69), Vector3(-1823.0, 330.0, -1139.0), 60.0],
}
const VIEW_S := 6.0
const REGION := Rect2(0.198, 0.4528, 0.0885, 0.1607)  # of the window: shelves and a pillar's gilt edge, no beam
const TURN_DEG := 2.0     # a second, while the moving frame is taken

var _p  # the player, rtx_play.gd: untyped, its own members are read and its own methods called
var _out := ""
var _ladder := false
var _motion := false
var _sweep := PackedStringArray()
var _sweep_i := 0
var _views := PackedStringArray()
var _view_i := 0
var _base := {}
var _hold := 5.0
var _cam: Camera3D
var _t0 := 0
var _stage := 0
var _r := {}


func start(player: Object, out: String) -> void:
	_p = player
	_out = out
	for arg in OS.get_cmdline_user_args():
		if arg == "--rtx-ladder":
			_ladder = true
		elif arg == "--rtx-motion":
			_motion = true
		elif arg.begins_with("--rtx-sweep="):
			_sweep = arg.trim_prefix("--rtx-sweep=").split(",", false)
		elif arg.begins_with("--rtx-hold="):
			_hold = float(arg.trim_prefix("--rtx-hold="))
		elif arg == "--rtx-views":
			_views = PackedStringArray(VIEWS.keys())
		elif arg.begins_with("--rtx-views="):
			_views = arg.trim_prefix("--rtx-views=").split(",", false)
	DirAccess.make_dir_recursive_absolute(_out)
	_t0 = Time.get_ticks_msec()
	_p.process_frame.connect(_frame)


func _state(prefix: String) -> void:
	var s := {"setting": _p.SETTINGS[_p._i][0], "path_tracing": _p._pt, "frame_generation": _p._fg, "auto": _p._auto,
		"scale_3d": snappedf(_p._vp.scaling_3d_scale, 0.0001),
		"ceiling": _p._ceiling, "line": _p._label.text, "badge": _p._badge.text, "mouse_mode": Input.mouse_mode}
	var buttons := {}
	for key: String in _p._buttons:
		var b: Button = _p._buttons[key]
		buttons[key] = b.text + ("" if not b.disabled else "  [disabled]")
	s.buttons = buttons
	s.bar_visible = _p._bar.visible
	s.letters_px = _p._px
	if _p._quality != null:
		s.quality = {"level": _p._quality.get("level"), "auto": _p._quality.get("_auto")}
	if is_instance_valid(_p._fill):
		var energies := []
		for l in (_p._fill as Node3D).get_children():
			if l is Light3D:
				energies.append(snappedf((l as Light3D).light_energy, 0.001))
		s.fill = {"visible": (_p._fill as Node3D).visible, "energies": energies}
	var lights := 0
	for l in (_p._scene as Node).find_children("*", "Light3D", true, false):
		if (l as Light3D).is_visible_in_tree():
			lights += 1
	s.lights_visible = lights
	if _p._env != null:
		s.env = {"exposure": snappedf((_p._env as Environment).tonemap_exposure, 0.001),
			"bounces": (_p._env as Environment).get("pathtracing_max_bounces")}
	var sl: Object = Engine.get_singleton("Streamline") if Engine.has_singleton("Streamline") else null
	if sl != null and sl.has_method("get_status"):
		var st: Dictionary = sl.call("get_status")
		s.status = {"dlss": st.get("dlss_evaluations", 0), "rr": st.get("dlss_rr_evaluations", 0),
			"render": str(st.get("render_size", "")), "output": str(st.get("output_size", "")), "fg": st.get("frame_generation", false)}
	_r[prefix] = s


func _grab() -> Image:
	return (_p.root as Window).get_texture().get_image()


## The window as it is drawn, saved, with its mean luma and the share of it that is nearly black (on the
## picture reduced to 96 x 54, as the values are stored: a comparison between captures, not a photometry).
## With edges: REGION of it too, against the same place a frame later.
func _shot(name: String, edges := false) -> void:
	await RenderingServer.frame_post_draw
	var img := _grab()
	var shot := {"saved": img.save_png(_out.path_join(name + ".png")) == OK}
	if edges:
		var a := _region(img)
		await RenderingServer.frame_post_draw
		var b := _region(_grab())
		b.save_png(_out.path_join(name + "-rest.png"))
		shot.rest = _compare(a, b)
	img.resize(96, 54, Image.INTERPOLATE_BILINEAR)
	var sum := 0.0
	var dark := 0
	var bright := 0
	for y in img.get_height():
		for x in img.get_width():
			var l := img.get_pixel(x, y).get_luminance()
			sum += l
			if l < 0.04:
				dark += 1
			elif l > 0.9:
				bright += 1
	var n := float(img.get_width() * img.get_height())
	shot.mean_luma = snappedf(sum / n, 0.0001)
	shot.dark_share = snappedf(dark / n, 0.001)
	shot.bright_share = snappedf(bright / n, 0.001)  # nearly white: a lamp blooming, or burnt highlights
	_r[name + "_png"] = shot


func _region(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	return img.get_region(Rect2i(int(w * REGION.position.x), int(h * REGION.position.y), int(w * REGION.size.x), int(h * REGION.size.y)))


## Two pictures of one place, as greys: how much a pixel differs from one to the other (the mean, and the
## share of pixels that differ by more than 5 of 255), and how sharp the second is (the mean step between
## neighbours, across and down).
func _compare(a: Image, b: Image) -> Dictionary:
	var ga := a.duplicate() as Image
	ga.convert(Image.FORMAT_L8)
	var gb := b.duplicate() as Image
	gb.convert(Image.FORMAT_L8)
	var da := ga.get_data()
	var db := gb.get_data()
	var w := gb.get_width()
	var n := mini(da.size(), db.size())
	var diff := 0
	var over := 0
	var edge := 0
	for i in n:
		var d := absi(da[i] - db[i])
		diff += d
		if d > 5:
			over += 1
		if i % w != 0:
			edge += absi(db[i] - db[i - 1])
		if i >= w:
			edge += absi(db[i] - db[i - w])
	return {"diff": snappedf(diff / (255.0 * n), 0.00001), "over": snappedf(over / float(n), 0.0001),
		"sharp": snappedf(edge / (510.0 * n), 0.00001)}


## The walk and the camera's own steering stopped: the camera stays where this script puts it.
func _freeze(fly: bool) -> void:
	var scene: Node = _p._scene
	if _cam == null:
		_cam = scene.get_node_or_null("FlyCamera") as Camera3D
		for n: Node in [scene.get_node_or_null("WalkBody"), scene.get_node_or_null("WalkBody/Early"), _cam]:
			if n != null:
				n.set_process(false)
				n.set_physics_process(false)
				n.set_process_input(false)
				n.set_process_unhandled_input(false)
	if fly and _cam != null:
		_cam.set("_free_fly", true)
		for c in scene.find_children("*", "Node", true, false):
			var s := c.get_script() as Script
			if s != null and s.resource_path.ends_with("view_fit.gd"):
				c.set("enabled", false)


## REGION while the camera turns, a second into the turn, against the frame after it; then the camera back.
func _moving(name: String) -> void:
	_freeze(false)
	if _cam == null:
		return
	var back := _cam.global_transform
	var t0 := Time.get_ticks_msec()
	var last := t0
	while Time.get_ticks_msec() - t0 < 1000:
		await _p.process_frame
		var now := Time.get_ticks_msec()
		_cam.global_rotate(Vector3.UP, deg_to_rad(TURN_DEG) * (now - last) / 1000.0)
		last = now
	await RenderingServer.frame_post_draw
	var a := _region(_grab())
	_cam.global_rotate(Vector3.UP, deg_to_rad(TURN_DEG) / 60.0)
	await RenderingServer.frame_post_draw
	var b := _region(_grab())
	b.save_png(_out.path_join(name + "-move.png"))
	(_r[name + "_png"] as Dictionary).move = _compare(a, b)
	_cam.global_transform = back


## One look of the hall, set: what the variant names, the rest as the header says.
func _variant(spec: String) -> void:
	var env: Environment = _p._env
	if _base.is_empty():
		_base = {"e": _p._exposure_was, "b": _p._bounces_was, "s": env.get("pathtracing_samples_per_pixel"),
			"a": env.ambient_light_energy}
		_r.sweep_base = _base
	var v := {"f": 1.0, "e": 1.0, "b": float(_base.b), "s": float(_base.s), "a": 1.0, "d": float(_p._i),
		"p": 1.0 if _p._pt else 0.0, "g": 1.0 if _p._fg else 0.0}
	var re := RegEx.create_from_string("([a-z])([0-9.]+)")
	for m in re.search_all(spec):
		v[m.get_string(1)] = float(m.get_string(2))
	var setting := int(v.d)
	var traced: bool = float(v.p) > 0.5
	var generated: bool = float(v.g) > 0.5
	if setting != int(_p._i) or traced != bool(_p._pt) or generated != bool(_p._fg):
		_p._i = setting
		_p._pt = traced
		_p._fg = generated
		_p._apply()
		_p._mine = [setting, traced]
	env.tonemap_exposure = float(_base.e) * float(v.e)
	env.set("pathtracing_max_bounces", int(v.b))
	env.set("pathtracing_samples_per_pixel", int(v.s))
	env.ambient_light_energy = float(_base.a) * float(v.a)
	_p.shelf = float(v.get("k", 1.0))  # the player sets the reading lamps from it
	_p._set_shelf_lamps()
	if is_instance_valid(_p._fill):
		for l in (_p._fill as Node3D).get_children():
			if l is Light3D and l.has_meta("rtx_energy"):
				(l as Light3D).light_energy = float(l.get_meta("rtx_energy")) * float(v.f)


func _axis_point(v: Vector3) -> Vector3:
	var a := deg_to_rad(AXIS_DEG)
	return Vector3(cos(a), 0.0, sin(a)) * v.x + Vector3.UP * v.y + Vector3(-sin(a), 0.0, cos(a)) * v.z


func _put(name: String) -> void:
	var v: Array = VIEWS.get(name, VIEWS.hall)
	var on_axis := str(v[0]) == "@"
	var eye: Vector3 = _axis_point(v[1]) if on_axis else v[0]
	var at: Vector3 = _axis_point(v[2]) if on_axis else v[1]
	var fov: float = v[3] if on_axis else v[2]
	_cam.look_at_from_position(eye, at, Vector3.UP)
	_cam.fov = fov


## After the comparisons: the views, the hints and the bar hidden (the badge stays), or the end.
func _next() -> void:
	if _views.is_empty():
		_finish()
		return
	_freeze(true)
	if _cam == null:
		_r.views = "no FlyCamera"
		_finish()
		return
	for c in (_p._scene as Node).find_children("*", "CanvasLayer", true, false):
		(c as CanvasLayer).visible = false
	(_p._bar.get_parent() as CanvasLayer).visible = false
	_p._label.visible = false
	_view_i = 0
	_put(_views[0])
	_t0 = Time.get_ticks_msec()
	_stage = 31


## A press and a release of the left button at the middle of one of the bar's buttons.
func _click(key: String) -> void:
	var b: Button = _p._buttons[key]
	var at := b.get_global_rect().get_center()
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		e.global_position = at
		Input.parse_input_event(e)


func _frame() -> void:
	var t := (Time.get_ticks_msec() - _t0) / 1000.0
	if _stage == 0 and t > 15.0 and (_p.root as Window).size.x < DisplayServer.screen_get_size().x * 0.95:
		# Nothing is measured in a window that is not maximised (logs/plain-msaa8: 1600 x 900).
		print("RTXPROBE window %s: maximised again" % str((_p.root as Window).size))
		(_p.root as Window).mode = Window.MODE_MAXIMIZED
		_t0 = Time.get_ticks_msec() - 10000
	elif _stage == 0 and t > 15.0:
		_stage = 1
		_r.streamline_singleton = Engine.has_singleton("Streamline")
		_r.dlss = _p._dlss
		_r.environment = _p._env != null
		_r.window = str((_p.root as Window).size)
		_r.adapter = RenderingServer.get_video_adapter_name()
		_r.engine = Engine.get_version_info().string
		_r.slow_fps = _p.slow_fps
		_r.fill = _p.fill
		_r.exposure = _p.exposure
		_r.bounces = _p.bounces
		_state("start")
		await _shot("start")
		var compare := not (_sweep.is_empty() and _views.is_empty())
		_stage = 2 if (_p._pt or compare) and not OS.get_cmdline_user_args().has("--rtx-quick") else 9
	elif _stage == 2 and not _sweep.is_empty() and t > 40.0:
		_stage = 20
		_p._auto = false       # the setting and the path tracer stay while the looks are compared
		_p._pt_chosen = true
		_sweep_i = 0
		_variant(_sweep[0])
		_t0 = Time.get_ticks_msec()
		_stage = 21
	elif _stage == 21 and t > _hold:
		_stage = 22
		var name: String = "sweep_" + _sweep[_sweep_i]
		_state(name)
		await _shot(name, _motion)
		if _motion:
			await _moving(name)
		_sweep_i += 1
		if _sweep_i < _sweep.size():
			_variant(_sweep[_sweep_i])
			_t0 = Time.get_ticks_msec()
			_stage = 21
		else:
			_next()
	elif _stage == 2 and not _views.is_empty() and t > 45.0:
		_stage = 30
		_state("before_views")
		_next()
	elif _stage == 31 and t > VIEW_S:
		_stage = 32
		var name: String = "view_" + _views[_view_i]
		_state(name)
		await _shot(name)
		_view_i += 1
		if _view_i < _views.size():
			_put(_views[_view_i])
			_t0 = Time.get_ticks_msec()
			_stage = 31
		else:
			_finish()
	elif _stage == 2 and _ladder and t > 75.0:
		_stage = 3
		_state("ladder")
		await _shot("ladder")
		_finish()
	elif _stage == 2 and not _ladder and t > 60.0:
		_stage = 3
		_state("pt")
		await _shot("pt")
		_click("fg")
		_t0 = Time.get_ticks_msec()
		_stage = 4
	elif _stage == 4 and t > 6.0:
		_stage = 5
		_state("fg")
		_click("pt")
		_t0 = Time.get_ticks_msec()
		_stage = 6
	elif _stage == 6 and t > 8.0:
		_stage = 7
		_state("raster")
		await _shot("raster")
		_finish()
	elif _stage == 9:
		_stage = 10
		_finish()


func _finish() -> void:
	var text := JSON.stringify(_r)
	var f := FileAccess.open(_out.path_join("report.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	print("RTXPROBE ", text)
	_p.quit(0)
