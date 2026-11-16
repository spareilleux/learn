extends Node
## The cinematic: the Observatory filmed as a game's cut scene, in real time, from the scene as it
## stands. Trantor from above under the galactic core, down through the oculus round the drum, the
## hall from the floor, a fresco gathering on the frieze, Seldon's recording, the IX hologram, three
## TARS walking, the drone flying past, and up from the Prime Radiant to the sky. The author asked for
## "des cinématiques aussi bien sinon mieux que GTA V", in the scene and as a path-traced video on
## the RTX (artpass/cinematic/NOTES.md).
##
## Key 0 plays it (scripts/extra_views.gd), as do --cinematic and ?cinematic=1. Any key, click or tap
## ends it. Its own camera films: the visitor stays where they stood, their interface put aside as
## the drone does it (scripts/drone.gd), and has the view back at the end. Bars make the picture
## 2.39:1 on screens wider than 1.2:1; an upright phone has no bars and a wider field, as
## scripts/view_fit.gd gives the visitor. Depth of field only under Forward+ on a GPU that keeps the
## top quality levels (scripts/quality.gd); under reduced motion no handheld sway, and each move
## shrinks to a slow drift. Shots are timed by the clock when frames are slow, so a weak GPU plays it
## in the same time.

const SKIP_TEXT := {
	"en": ["Any key: skip", "Tap: skip"],
	"fr": ["Une touche : passer", "Touchez : passer"],
	"es": ["Cualquier tecla: saltar", "Toque: saltar"],
}
const TITLE := {"en": "OBSERVATORY", "fr": "L'OBSERVATOIRE", "es": "EL OBSERVATORIO"}
const RATIO := 2.39          # the picture's width over its height between the bars
const WIDE := 1.2            # screens at least this wide get bars; narrower ones a wider field
const BARS_S := 0.8          # the bars coming in or going
const DIP_S := 0.45          # a fade to or from black between acts
const CARD_S := 3.2          # the title over black at the end
const WARM_S := 2.4          # the title over black at the start, at least, while the shots warm up
const OUT_S := 0.6           # back to the visitor's view
const HUSH_DB := -80.0       # the scene's sound while the warm-up brings the set pieces on, behind black
const SOUND_IN_S := 2.0      # and its coming back with the first shot
const GILT := Color(0.95, 0.84, 0.6)
## Where the shots look: the Prime Radiant's middle, and the galactic core's direction when the
## night sky's shader does not say (extra_views.gd reads it the same way).
const RADIANT := Vector3(0.0, 7.2, 0.0)
const CORE := Vector3(-0.468, 0.867, -0.170)

var playing := false
var reduced_motion := false
var touch := false
var lang := "en"
## For tests: plays, ends, skips, the shots begun in order, frames filmed, and what the screen got.
var stats := {"plays": 0, "ends": 0, "skips": 0, "refused": 0, "shots": [], "shot": "", "frames": 0, "dof": false,
	"bars_px": 0.0, "hidden_layers": 0, "cues": [], "tars": 0, "drone_frames": 0, "phase": "idle"}

var _obs: Node3D
var _camera: Camera3D        # the visitor's (fly_camera.gd)
var _cam: Camera3D           # the cinematic's own
var _attrs: CameraAttributesPractical
var _fill: OmniLight3D       # a film crew's soft fill on the camera, for the close shots
var _layer: CanvasLayer
var _top: ColorRect
var _bottom: ColorRect
var _fade: ColorRect
var _skip: Label
var _title: Label
var _phase := "idle"         # idle, in, shot, card, out
var _phase_t := 0.0
var _shots: Array = []
var _i := -1
var _t := 0.0
var _cue_i := 0
var _bars := 0.0             # 0 none .. 1 full
# The first play visits every shot's start, middle and end behind black, under the title, so that
# the web build compiles what they show before the film runs: headless Chrome had stalls of 0.8 to
# 1.8 s in the first shots, each the first sight of something (artpass/cinematic/NOTES.md).
var _warmed := false
var _warm: Array = []        # [camera, look at, fov]
var _warm_i := 0
var _warm_frames := 0
var _warm_tars: Node3D       # the TARS the warm-up shows the shaders, gone before the first shot
var _warm_open := {}         # "recording", "holo": opened by the warm-up
var _warm_closed := {}       # and closed by it, maybe still fading: the shot's cue opens them again
var _bus_db := 0.0           # the Master bus's level before the warm-up hushed it
var _hushed := false
var _hush_t := 0.0
var _last_us := 0
var _dof_ok := false
# What the cinematic puts aside and gives back.
var _hidden_layers: Array[CanvasLayer] = []
var _paused: Array[Node] = []
var _mouse_mode := Input.MOUSE_MODE_VISIBLE
var _hold_was := true
var _auto_holo_was := false
# The players it borrows.
var _drone: Node
var _drone_on := false
var _track := Vector3.INF
var _track_at := Vector3.INF
var _spawned: Array[Node3D] = []
var _opened := {}            # "recording", "holo": what it opened, closed at the end


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	# After the drone (865), so that a borrowed drone has stepped; before extra_views.gd (870), which
	# shows Upperside to the camera that looks.
	process_priority = 868
	reduced_motion = OS.get_cmdline_user_args().has("--reduced-motion")
	if OS.has_feature("web"):
		reduced_motion = reduced_motion or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	touch = _obs != null and _obs.get_node_or_null("TouchControls") != null
	_cam = Camera3D.new()
	_cam.name = "CinematicCamera"
	add_child(_cam)
	_attrs = CameraAttributesPractical.new()
	# No shadow, a short reach: it lifts a TARS or the drone out of the dark (under Compatibility a
	# TARS a metre and a half away was nearly black) and leaves the hall's light alone.
	_fill = OmniLight3D.new()
	_fill.name = "Fill"
	_fill.light_color = Color(1.0, 0.93, 0.84)
	_fill.omni_range = 3.0
	_fill.omni_attenuation = 1.5
	_fill.shadow_enabled = false
	_fill.light_energy = 0.0
	_fill.visible = false
	_fill.position = Vector3(0.25, 0.15, 0.0)
	_cam.add_child(_fill)
	_build_ui()
	set_process(false)


# --- Playing and stopping -------------------------------------------------------------------------

## Plays the cinematic from its first shot (or from shot `from`, for tests and captures). Refused while
## the drone flies or in the corridor behind the steel box, which has no sky.
func play(from := 0) -> bool:
	if playing or _obs == null or _camera == null:
		return false
	_drone = _obs.get_node_or_null("Drone")
	var corridor := _obs.get_node_or_null("Multiverse")
	if (_drone != null and _drone.has_method("is_flying") and bool(_drone.call("is_flying"))) \
			or (corridor != null and bool(corridor.get("inside"))):
		stats.refused += 1
		return false
	var lib := _obs.get_node_or_null("Generated/CourseShelves")
	if lib != null:
		lang = str(lib.get("lang"))
	if not TITLE.has(lang):
		lang = "en"
	_shots = _plan()
	if _shots.is_empty():
		return false
	playing = true
	stats.plays += 1
	(stats.shots as Array).clear()
	(stats.cues as Array).clear()
	_i = clampi(from, 0, _shots.size() - 1) - 1
	_warm_closed.clear()
	_put_aside()
	_cam.near = _camera.near
	_cam.far = _camera.far
	_cam.cull_mask = _camera.cull_mask
	_dof_ok = _dof_allowed()
	stats.dof = _dof_ok
	_cam.attributes = _attrs if _dof_ok else null
	_skip.text = str((SKIP_TEXT[lang] as Array)[1 if touch else 0])
	_title.text = str(TITLE[lang])
	_title.modulate.a = 0.0
	_layer.visible = true
	_set_phase("in")
	_last_us = 0
	set_process(true)
	_layout()
	return true


## Ends it at once from wherever it is: through black, back to the visitor.
func skip() -> void:
	if not playing or _phase == "out":
		return
	stats.skips += 1
	_set_phase("out")


## Web tests: the phase, the shot, how many shots began, plays and skips, the bars' height.
func _publish() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__obsCinema = %s" % JSON.stringify({"phase": _phase, "shot": stats.shot,
		"shots": (stats.shots as Array).size(), "plays": stats.plays, "skips": stats.skips, "ends": stats.ends,
		"bars": stats.bars_px}), true)


func _set_phase(p: String) -> void:
	_phase = p
	_phase_t = 0.0
	stats.phase = p
	_publish()


func _finish() -> void:
	_borrow_drone(false)
	_warm_props_out()
	_unhush()
	_fill.visible = false
	for k: String in _opened.keys():
		var n := _obs.get_node_or_null("Hologram" if k == "holo" else "SeldonRecording")
		if n != null and n.has_method("close"):
			n.call("close")
	_opened.clear()
	for r in _spawned:
		if is_instance_valid(r) and r.has_method("call_home"):
			r.call("call_home")
	_spawned.clear()
	_camera.make_current()
	_give_back()
	playing = false
	stats.ends += 1


# --- Every frame ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _phase == "idle":
		set_process(false)
		return
	# Time by the clock when frames are slow, as seldon_recording.gd does: Godot cuts delta to 0.133 s
	# under 7.5 frames a second.
	var now := Time.get_ticks_usec()
	var real := float(now - _last_us) / 1e6 if _last_us > 0 else delta
	_last_us = now
	var step := delta if delta < 0.12 else maxf(delta, minf(real, 0.5))
	_phase_t += step
	match _phase:
		"in":
			# The bars come in over the visitor's view, then black, then the first shot.
			_bars = clampf(_phase_t / BARS_S, 0.0, 1.0)
			_fade.color.a = clampf((_phase_t - BARS_S * 0.6) / DIP_S, 0.0, 1.0)
			_skip.modulate.a = clampf(_phase_t / 0.5, 0.0, 0.75)
			if _phase_t >= BARS_S * 0.6 + DIP_S:
				if _warmed:
					_next_shot()
				else:
					_warm = _warm_poses()
					_warm_i = 0
					_warm_frames = 0
					_cam.make_current()
					_set_phase("warm")
					_warm_props_in()
		"warm":
			# Behind black, under the title: two frames at each pose, then the first shot.
			_bars = 1.0
			_fade.color.a = 1.0
			_title.modulate.a = clampf(_phase_t / 0.6, 0.0, 1.0)
			if _warm_i < _warm.size():
				var w: Array = _warm[_warm_i]
				_aim(w[0], w[1], float(w[2]), 0.0)
				if w.size() > 3:
					# The fill as its shot has it: under Compatibility a light more or less on a surface is
					# another shader to compile.
					_fill.light_energy = float(w[3])
					_fill.visible = _fill.light_energy > 0.0
				_warm_frames += 1
				if _warm_frames >= 2:
					_warm_frames = 0
					_warm_i += 1
			elif _phase_t >= WARM_S:
				_warmed = true
				stats.warm_poses = _warm.size()
				stats.warm_s = snappedf(_phase_t, 0.01)
				_warm_props_out()
				_next_shot()
		"shot":
			_title.modulate.a = maxf(0.0, _title.modulate.a - step * 2.0)
			if _hushed:
				_sound_in(step)
			_film(step)
			_skip.modulate.a = clampf(1.0 - (_t - 2.5) / 0.8, 0.0, 0.75) if stats.shots.size() <= 1 else 0.0
		"card":
			_fade.color.a = 1.0
			_title.modulate.a = clampf(minf(_phase_t / 0.8, (CARD_S - _phase_t) / 0.8), 0.0, 1.0)
			if _phase_t >= CARD_S:
				_finish()
				_set_phase("out")
				_phase_t = DIP_S  # already black
		"out":
			_skip.modulate.a = 0.0
			_title.modulate.a = maxf(0.0, _title.modulate.a - step * 3.0)
			if playing:
				# A skip: to black first, then the visitor's view.
				_fade.color.a = maxf(_fade.color.a, clampf(_phase_t / 0.3, 0.0, 1.0))
				if _phase_t >= 0.3:
					_finish()
					_phase_t = DIP_S
			else:
				var k := clampf((_phase_t - DIP_S) / OUT_S, 0.0, 1.0)
				_fade.color.a = 1.0 - k
				_bars = 1.0 - k
				if k >= 1.0:
					_layer.visible = false
					_set_phase("idle")
					set_process(false)
	_layout_bars()
	stats.frames += 1


func _next_shot() -> void:
	_borrow_drone(false)
	_i += 1
	if _i >= _shots.size():
		_set_phase("card")
		return
	var shot: Dictionary = _shots[_i]
	_t = 0.0
	_cue_i = 0
	_track = Vector3.INF
	_track_at = Vector3.INF
	_fill.light_energy = float(shot.get("fill", 0.0))
	_fill.visible = _fill.light_energy > 0.0
	(stats.shots as Array).append(str(shot.name))
	stats.shot = str(shot.name)
	_set_phase("shot")
	if not _cam.current:
		_cam.make_current()
	_film(0.0)


## Where the warm-up looks, two frames each, [camera, look at, fov, fill]: first at the TARS and the
## drone it brought on (the TARS shot's first frame); then along every shot's planned path, from start
## to end, a pose every 4 m or so (3 at least, 5 in the long shots, 12 at most), and along the drone's
## flight on its tour; last the fresco it summoned across the hall, gathering by then.
func _warm_poses() -> Array:
	var out := []
	var tail := []
	for shot: Dictionary in _shots:
		var cam_c: Dictionary = shot.cam
		var fov_v: Vector2 = shot.fov
		var fill := float(shot.get("fill", 0.0))
		if shot.has("spot"):
			out.push_front([_along(cam_c, 0.0), _along(shot.look as Dictionary, 0.0), fov_v.x, fill])
		if shot.has("warm_bay"):
			tail.append([shot.warm_cam, shot.warm_look, fov_v.x, fill])
		if shot.has("s0") and _drone != null and _drone.get("_tour") is Dictionary:
			var tour: Dictionary = _drone.get("_tour")
			for d: float in [0.0, 4.0, 8.0, 12.0, 16.0]:
				var a: Vector3 = (_drone.call("path_at", tour, float(shot.s0) + d) as Array)[0]
				var b: Vector3 = (_drone.call("path_at", tour, float(shot.s0) + d + 1.5) as Array)[0]
				out.append([a - (b - a).normalized() * 0.75 + Vector3(0, 0.18, 0), b, lerpf(fov_v.x, fov_v.y, d / 16.0), fill])
			continue
		var n := clampi(ceili(float(cam_c.L) / 4.0) + 1, 5 if float(shot.dur) >= 10.0 else 3, 12)
		var us: Array = []
		for j in n:
			us.append(lerpf(0.02, 0.98, float(j) / float(n - 1)))
		for u: float in us:
			var p := _along(cam_c, u)
			var at := Vector3.ZERO
			if shot.has("ahead"):
				at = _along(cam_c, minf(1.0, u + float(shot.ahead) / maxf(0.001, float(cam_c.L))))
				if at.distance_to(p) < 0.5:
					at = p + (_along(cam_c, 1.0) - _along(cam_c, 0.98)).normalized() * 5.0
				if shot.has("toward"):
					var w: Vector2 = shot.toward_w
					at = at.lerp(shot.toward as Vector3, smoothstep(w.x, 1.0, u) * w.y)
			else:
				at = _along(shot.look as Dictionary, u)
			out.append([p, at, lerpf(fov_v.x, fov_v.y, u), fill])
	out.append_array(tail)
	return out


## Behind black, before the poses, the set pieces the shots bring on are brought on once, hushed, so
## that their shaders compile now and not in the middle of a shot: in the web build each froze the
## picture 0.2 to 0.6 s the first time it was drawn (2026-10-03). Seldon's recording and the hologram
## open; a fresco gathers across the hall from the shot's; a TARS out of its puff and the drone, rotors
## and their blur, stand where the TARS shot begins; the depth of field is on (the fill light goes on
## and off with the poses, as in their shots).
func _warm_props_in() -> void:
	_bus_db = AudioServer.get_bus_volume_db(0)
	AudioServer.set_bus_volume_db(0, HUSH_DB)
	_hushed = true
	_hush_t = 0.0
	if _dof_ok:
		_attrs.dof_blur_far_enabled = true
		_attrs.dof_blur_near_enabled = true
		_attrs.dof_blur_amount = 0.05
	var props := []
	var rec := _obs.get_node_or_null("SeldonRecording")
	if rec != null and not bool(rec.call("is_open")):
		rec.call("open")
		_warm_open["recording"] = true
	var holo := _obs.get_node_or_null("Hologram")
	if holo != null and not bool(holo.call("is_open")):
		holo.call("open", 0)
		_warm_open["holo"] = true
	props.append_array(_warm_open.keys())
	for shot: Dictionary in _shots:
		if shot.has("warm_bay"):
			var frieze := _obs.get_node_or_null("FrescoFrieze")
			if frieze != null and frieze.has_method("summon") and bool(frieze.call("summon", int(shot.warm_bay))):
				props.append("fresco")
		if shot.has("spot"):
			var at: Vector3 = shot.spot
			var facing: Vector3 = shot.toward_cam
			var cw := _obs.get_node_or_null("CurioWheel")
			if cw != null and cw.has_method("_add_tars"):
				_warm_tars = cw.call("_add_tars", at + Vector3(0, 0.5, 0), facing, 1.25) as Node3D
				if cw.has_method("_sparkle"):
					cw.call("_sparkle", at + Vector3(0, 0.5, 0), GILT, 1.3)
				props.append("tars")
			var craft: Node3D = _drone.get("_craft") as Node3D if _drone != null else null
			if craft != null:
				craft.global_position = at + facing * 0.8 + Vector3(0, 0.5, 0)
				craft.visible = true
				_drone.set("_spin", 0.35)  # the blades and their blur both drawn; at rest it runs down
				props.append("drone")
	stats.warm_props = props


## The warm-up's set pieces put back before the first shot, or at a skip during it: the recording and
## the hologram closed (their cues open them again while they fade), the TARS gone, the drone hidden.
func _warm_props_out() -> void:
	for k: String in _warm_open.keys():
		var n := _obs.get_node_or_null("Hologram" if k == "holo" else "SeldonRecording")
		if n != null:
			n.call("close")
			_warm_closed[k] = true
	_warm_open.clear()
	if is_instance_valid(_warm_tars):
		var cw := _obs.get_node_or_null("CurioWheel")
		var robots: Variant = cw.get("_robots") if cw != null else null
		if robots is Array:
			(robots as Array).erase(_warm_tars)
		_warm_tars.queue_free()
	_warm_tars = null
	var craft: Node3D = _drone.get("_craft") as Node3D if _drone != null else null
	if craft != null and not _drone_on:
		craft.visible = false


## The scene's sound back with the first shot after the warm-up, over SOUND_IN_S.
func _sound_in(dt: float) -> void:
	_hush_t += dt
	var k := clampf(_hush_t / SOUND_IN_S, 0.0, 1.0)
	if k >= 1.0:
		_unhush()
		return
	AudioServer.set_bus_volume_db(0, linear_to_db(lerpf(db_to_linear(HUSH_DB), db_to_linear(_bus_db), k * k)))


func _unhush() -> void:
	if _hushed:
		AudioServer.set_bus_volume_db(0, _bus_db)
		_hushed = false


func _exit_tree() -> void:
	_unhush()


## A frame of the current shot, dt seconds on.
func _film(dt: float) -> void:
	var shot: Dictionary = _shots[_i]
	_t += dt
	var dur := float(shot.dur)
	var cues: Array = shot.get("cues", [])
	while _cue_i < cues.size() and _t >= float((cues[_cue_i] as Array)[0]):
		var c: Array = cues[_cue_i]
		_cue(str(c[1]), c[2] if c.size() > 2 else null)
		_cue_i += 1
	var u := clampf(_t / dur, 0.0, 1.0)
	if reduced_motion:
		u = 0.42 + 0.16 * u  # a drift round the shot's middle
	var k := _ease(u, float(shot.get("ease", 0.8)))
	var cam_c: Dictionary = shot.cam
	var p := _along(cam_c, k)
	var at := Vector3.ZERO
	if shot.has("ahead"):
		var L := maxf(0.001, float(cam_c.L))
		at = _along(cam_c, k + float(shot.ahead) / L)
		if k + float(shot.ahead) / L > 1.0:
			at = p + (_along(cam_c, 1.0) - _along(cam_c, 0.98)).normalized() * float(shot.ahead)
		if shot.has("toward"):
			var w: Vector2 = shot.toward_w
			at = at.lerp(shot.toward as Vector3, smoothstep(w.x, 1.0, k) * w.y)
	else:
		at = _along(shot.look as Dictionary, k)
	var follow := str(shot.get("follow", ""))
	var fov_v: Vector2 = shot.fov
	var fov := lerpf(fov_v.x, fov_v.y, k)
	# A followed subject keeps about its size on an upright screen, whose field is taller: nearer.
	var near := clampf(tan(deg_to_rad(fov) * 0.5) / tan(deg_to_rad(_screen_fov(fov)) * 0.5), 0.6, 1.0) \
		if _aspect() < WIDE else 1.0
	if follow == "drone" and _drone_on:
		# A camera car: behind it and to the hall's side, late on it, looking where it goes.
		_drone.set("_spin", 1.0)
		_drone.call("step", dt if dt > 0.0 else 1.0 / 60.0)
		stats.drone_frames += 1
		var cp := (_drone.get("_craft") as Node3D).global_position
		var v: Vector3 = _drone.get("_v")
		var dir := v.normalized() if v.length() > 0.2 else Vector3.FORWARD
		var side := dir.cross(Vector3.UP).normalized()
		if side.dot(Vector3(-cp.x, 0.0, -cp.z)) < 0.0:
			side = -side
		p = _tracked(cp + (-dir * 0.75 + side * 0.3 + Vector3(0, 0.18, 0)) * near, dt, 7.0)
		at = _tracked_at(cp + dir * 0.4, dt, 10.0)
	elif follow == "tars":
		# Low, at their height, in front of the first and largest as it finds its feet and walks: the
		# three wander apart, and their middle is floor (an upright phone's frame showed none of them).
		var lead: Node3D = null
		if not _spawned.is_empty() and is_instance_valid(_spawned[0]):
			lead = _spawned[0]
		if lead != null:
			var feet: Array = lead.call("feet")
			var s := float(lead.get("size"))
			var on := _tracked((feet[0] as Vector3).lerp(feet[3] as Vector3, 0.5), dt, 2.0)
			var toward: Vector3 = shot.toward_cam
			p = on + (toward * 1.5 + toward.cross(Vector3.UP) * lerpf(-0.5, 0.5, k)) * near + Vector3(0, 0.2, 0)
			at = on + Vector3(0, 0.2 * s, 0)
	_aim(p, at, fov, float(shot.get("sway", 0.25)))
	if _dof_ok:
		var focus := p.distance_to(at)
		_attrs.dof_blur_far_enabled = true
		_attrs.dof_blur_far_distance = focus * 1.35 + 1.0
		_attrs.dof_blur_far_transition = focus * 1.5 + 2.0
		_attrs.dof_blur_near_enabled = focus > 2.0
		_attrs.dof_blur_near_distance = focus * 0.45
		_attrs.dof_blur_near_transition = focus * 0.3
		_attrs.dof_blur_amount = float(shot.get("dof", 0.06))
	# Into and out of black at an act's edges.
	var a := 0.0
	if str(shot.get("in", "cut")) == "dip":
		a = maxf(a, 1.0 - clampf(_t / DIP_S, 0.0, 1.0))
	var out := str(shot.get("out", "cut"))
	if out == "dip":
		a = maxf(a, clampf((_t - (dur - DIP_S)) / DIP_S, 0.0, 1.0))
	elif out == "long":
		a = maxf(a, clampf((_t - (dur - 2.6)) / 2.6, 0.0, 1.0))
	_fade.color.a = a
	if _t >= dur:
		_next_shot()


## The camera at p looking at `at`, with a vertical field of fov degrees in the picture between the
## bars, and a handheld operator's slow sway of about `sway` degrees.
func _aim(p: Vector3, at: Vector3, fov: float, sway: float) -> void:
	var d := at - p
	if d.length() < 0.01:
		return
	var up := Vector3.UP if absf(d.normalized().y) < 0.995 else Vector3.BACK
	_cam.look_at_from_position(p, at, up)
	if not reduced_motion and sway > 0.0:
		var t := float(Time.get_ticks_msec()) / 1000.0
		var a := deg_to_rad(sway)
		_cam.rotate_object_local(Vector3.UP, a * (0.6 * sin(0.71 * t + 1.3) + 0.4 * sin(1.37 * t + 0.2)))
		_cam.rotate_object_local(Vector3.RIGHT, a * (0.6 * sin(0.53 * t) + 0.4 * sin(1.13 * t + 2.1)))
		_cam.rotate_object_local(Vector3.FORWARD, a * 0.5 * sin(0.37 * t + 0.7))
	_cam.fov = _screen_fov(fov)


## The camera's vertical field for a picture of `fov` degrees: between the bars on a wide screen, the
## full height being taller; on an upright one, widened as view_fit.gd does for the visitor.
func _screen_fov(fov: float) -> float:
	var size := get_viewport().get_visible_rect().size
	var a := size.x / maxf(1.0, size.y)
	if a >= WIDE:
		var band := minf(1.0, a / RATIO)
		return rad_to_deg(2.0 * atan(tan(deg_to_rad(fov) * 0.5) / band))
	var across := rad_to_deg(2.0 * atan(tan(deg_to_rad(fov) * 0.5) * a))
	if across >= 60.0:
		return fov
	return clampf(rad_to_deg(2.0 * atan(tan(deg_to_rad(60.0) * 0.5) / a)), fov, maxf(fov, 90.0))


func _aspect() -> float:
	var size := get_viewport().get_visible_rect().size
	return size.x / maxf(1.0, size.y)


## Follows a moving point late, as an operator does, at `rate` per second: the camera's place, and
## (_tracked_at) where it looks.
func _tracked(p: Vector3, dt: float, rate: float) -> Vector3:
	if _track == Vector3.INF:
		_track = p
	else:
		_track = _track.lerp(p, 1.0 - exp(-rate * dt))
	return _track


func _tracked_at(p: Vector3, dt: float, rate: float) -> Vector3:
	if _track_at == Vector3.INF:
		_track_at = p
	else:
		_track_at = _track_at.lerp(p, 1.0 - exp(-rate * dt))
	return _track_at


static func _ease(u: float, amount: float) -> float:
	return lerpf(u, u * u * (3.0 - 2.0 * u), amount)


# --- What happens in the shots --------------------------------------------------------------------

func _cue(what: String, arg: Variant) -> void:
	(stats.cues as Array).append(what)
	match what:
		"fresco":
			var frieze := _obs.get_node_or_null("FrescoFrieze")
			if frieze != null and frieze.has_method("summon"):
				frieze.call("summon", int(arg))
		"recording":
			var rec := _obs.get_node_or_null("SeldonRecording")
			if rec != null and (not bool(rec.call("is_open")) or _warm_closed.has("recording")):
				rec.call("open")
				_opened["recording"] = true
			_warm_closed.erase("recording")
		"recording_off":
			var rec := _obs.get_node_or_null("SeldonRecording")
			if rec != null:
				rec.call("close")
				_opened.erase("recording")
		"holo":
			var holo := _obs.get_node_or_null("Hologram")
			if holo != null and (not bool(holo.call("is_open")) or _warm_closed.has("holo")):
				holo.call("open", int(arg))
				_opened["holo"] = true
			_warm_closed.erase("holo")
		"tars":
			_spawn_tars(arg as Array)
		"drone":
			_borrow_drone(true, float(arg))


## Three TARS out of a puff of gilt, side by side, facing `spot[1]`: [at, facing].
func _spawn_tars(spot: Array) -> void:
	var cw := _obs.get_node_or_null("CurioWheel")
	if cw == null or not cw.has_method("_add_tars"):
		return
	var at: Vector3 = spot[0]
	var facing: Vector3 = spot[1]
	var side := facing.cross(Vector3.UP).normalized()
	for j in 3:
		var p := at + side * (float(j) - 1.0) * 0.9 - facing * absf(float(j) - 1.0) * 0.5 + Vector3(0, 0.5, 0)
		var r: Node3D = cw.call("_add_tars", p, facing, 1.5 if j == 0 else 1.25)
		if r != null:
			_spawned.append(r)
			stats.tars += 1
		if cw.has_method("_sparkle"):
			cw.call("_sparkle", p, GILT, 1.3)
	var sounds: Variant = cw.get("_sounds")
	if sounds is Dictionary and (sounds as Dictionary).has("spell") and cw.has_method("_sound_at"):
		cw.call("_sound_at", "spell", at, 0.8)


## The drone flown by the cinematic, from `s` metres along its tour, or put back.
func _borrow_drone(on: bool, s := 0.0) -> void:
	if _drone == null or not _drone.has_method("place_at"):
		_drone_on = false
		return
	var craft := _drone.get("_craft") as Node3D
	if on:
		_drone.call("place_at", s, 1.0)
		craft.visible = true
		_drone.set("_spin", 1.0)
		_drone_on = true
	elif _drone_on:
		craft.visible = false
		_drone_on = false


# --- The shots ------------------------------------------------------------------------------------

## The shot list, from the scene as it is: each a Dictionary with its name, its seconds, the camera's
## path (a curve), what it looks at (a curve, or a distance ahead on its own path bent towards a
## point), its field from and to, how much the move eases, cues at times, and its edges.
func _plan() -> Array:
	var shots := []
	var core := CORE
	var sky := _obs.get_node_or_null("Generated/Ceiling/NightSky") as GeometryInstance3D
	if sky != null and sky.material_override is ShaderMaterial:
		var c: Variant = (sky.material_override as ShaderMaterial).get_shader_parameter("core_dir")
		if c is Vector3:
			core = (c as Vector3).normalized()
	# 1. Trantor: over the domes, from the galactic core down to the drum.
	var p0 := _pol(25.0, 33.0, 37.0)
	shots.append({"name": "trantor", "dur": 8.0, "in": "dip", "ease": 0.9, "sway": 0.25, "fov": Vector2(46, 40),
		"cam": _curve([p0, _pol(42.0, 28.0, 34.5), _pol(58.0, 24.0, 32.0)]),
		"look": _curve([p0 + core * 14.0, Vector3(0, 27.0, 0), Vector3(0, 25.0, 0)])})
	# 2. In: the drone's own way over the lancets, over the cornice and down round the drum, the view
	# bending to the Prime Radiant (drone.gd's tour, which keeps clear of everything).
	var way := _tour_between(_pol(135.0, 12.6, 23.4), _pol(270.0, 7.5, 13.0))
	if way.size() > 4:
		shots.append({"name": "descent", "dur": 12.0, "ease": 0.55, "sway": 0.15, "fov": Vector2(62, 54),
			"cam": _curve(way, 2), "ahead": 5.0, "toward": RADIANT, "toward_w": Vector2(0.3, 0.85)})
	# 3. The hall from the floor: a low dolly across the entrance's side, craning up to the beam.
	shots.append({"name": "hall", "dur": 8.0, "ease": 0.9, "sway": 0.3, "fov": Vector2(56, 50), "dof": 0.03,
		"cam": _curve([Vector3(-3.2, 0.45, 10.4), Vector3(0.0, 1.6, 10.9), Vector3(3.2, 3.4, 10.3)]),
		"look": _curve([Vector3(0, 6.0, 0), Vector3(0, 10.5, 0)])})
	# 4. A fresco gathering over a bay of the first gallery, pushed in on.
	var bays := int(_obs.get("bay_count"))
	var bay := 10 % maxi(1, bays)
	var a0 := 360.0 * (float(bay) + 0.5) / float(maxi(1, bays))
	var r_panel := float(_obs.get("colonnade_radius")) - 0.74
	var y_panel := float(_obs.get("column_height")) + 0.42
	var panel := _pol(a0, r_panel, y_panel)
	# The warm-up's, across the hall: the same mosaic's shaders, and this one still to gather.
	var bay_w := (bay + int(float(maxi(1, bays)) * 0.5)) % maxi(1, bays)
	var a_w := 360.0 * (float(bay_w) + 0.5) / float(maxi(1, bays))
	shots.append({"name": "fresco", "dur": 7.0, "ease": 0.85, "sway": 0.2, "fov": Vector2(44, 34), "dof": 0.05,
		"cam": _curve([_pol(a0, 4.0, 14.5), _pol(a0, 7.2, 16.8)]), "look": _curve([panel, panel]),
		"cues": [[0.0, "fresco", bay]],
		"warm_bay": bay_w, "warm_cam": _pol(a_w, 4.0, 14.5), "warm_look": _pol(a_w, r_panel, y_panel)})
	var statue := _obs.find_child("SeldonStatue", true, false) as Node3D
	if statue != null:
		var T := statue.global_transform
		var stand := Vector3(1.55, 0.0, 0.5)
		# 5. Seldon's recording: a slow arc round him as he forms and turns to the lens.
		var arc := []
		for j in 4:
			var th := deg_to_rad(lerpf(25.0, 65.0, float(j) / 3.0))
			arc.append(T * (stand + Vector3(sin(th) * 3.4, lerpf(1.15, 1.45, float(j) / 3.0), cos(th) * 3.4)))
		shots.append({"name": "seldon", "dur": 10.0, "ease": 0.7, "sway": 0.3, "fov": Vector2(38, 36), "dof": 0.08,
			"cam": _curve(arc), "look": _curve([T * (stand + Vector3(0, 1.3, 0)), T * (stand + Vector3(0, 1.65, 0))]),
			"cues": [[0.0, "recording"]]})
		# 6. The IX hologram over the statue, the recording lifting away: up its spiral, close to the
		# panels (1.55 m from the axis, from 3.75 m up), round and up as they light.
		var spiral := []
		var axis := []
		for j in 4:
			var f := float(j) / 3.0
			var th := deg_to_rad(lerpf(15.0, 55.0, f))
			var h := lerpf(3.3, 4.4, f)
			spiral.append(T * Vector3(sin(th) * 2.7, h, cos(th) * 2.7))
			axis.append(T * Vector3(0.0, h + 0.25, 0.0))
		shots.append({"name": "hologram", "dur": 8.0, "ease": 0.8, "sway": 0.25, "fov": Vector2(54, 50), "dof": 0.04,
			"cam": _curve(spiral), "look": _curve(axis), "cues": [[0.0, "recording_off"], [0.3, "holo", 0]]})
	# 7. The TARS: three out of a puff of gilt, followed low at their height.
	# The camera on the hall's side of them, the three facing it.
	var spot := _pol(205.0, 8.5, 0.0)
	var toward_cam := -Vector3(spot.x, 0, spot.z).normalized()
	shots.append({"name": "tars", "dur": 8.0, "ease": 0.6, "sway": 0.35, "fov": Vector2(46, 42), "dof": 0.1, "fill": 0.8,
		"cam": _curve([spot + toward_cam * 1.9 + Vector3(0, 0.2, 0), spot + toward_cam * 1.9 + Vector3(0, 0.2, 0)]),
		"look": _curve([spot + Vector3(0, 0.3, 0), spot + Vector3(0, 0.3, 0)]), "follow": "tars", "toward_cam": toward_cam,
		"cues": [[0.0, "tars", [spot, toward_cam]]], "spot": spot})
	# 8. The drone into the first gallery through a bay, over the rail and along the books, from a
	# camera car behind it.
	var s0 := _tour_s(_pol(262.0, 10.0, 7.6))
	if s0 >= 0.0:
		var start := _pol(262.0, 10.0, 7.6)
		shots.append({"name": "drone", "dur": 9.0, "ease": 0.7, "sway": 0.3, "fov": Vector2(42, 38), "dof": 0.04, "fill": 0.5,
			"cam": _curve([start, start]), "look": _curve([start, start]),
			"follow": "drone", "cues": [[0.0, "drone", s0]], "s0": s0})
	# 9. Up from the Prime Radiant through the oculus to the sky; then the title.
	shots.append({"name": "finale", "dur": 10.0, "ease": 0.8, "sway": 0.2, "fov": Vector2(58, 70), "out": "long",
		"cam": _curve([Vector3(0, 1.5, 7.0), Vector3(0, 2.0, 6.3), Vector3(0, 2.6, 5.6)]),
		"look": _curve([RADIANT, Vector3(0, 14.0, -0.5), Vector3(0, 30.0, -1.0)])})
	return shots


## The drone's tour from the sample nearest `a` to the one nearest `b`, going forwards.
func _tour_between(a: Vector3, b: Vector3) -> Array:
	var out := []
	var d := _obs.get_node_or_null("Drone")
	if d == null or not d.has_method("tour_samples"):
		return out
	var P: PackedVector3Array = d.call("tour_samples")
	if P.size() < 4:
		return out
	var ia := _nearest(P, a)
	var ib := _nearest(P, b)
	var i := ia
	while true:
		out.append(P[i])
		if i == ib or out.size() > P.size():
			break
		i = (i + 1) % P.size()
	return out


## Metres along the drone's tour of the sample nearest p, or -1 without the drone.
func _tour_s(p: Vector3) -> float:
	var d := _obs.get_node_or_null("Drone")
	if d == null or not d.has_method("tour_samples"):
		return -1.0
	var P: PackedVector3Array = d.call("tour_samples")
	var tour: Variant = d.get("_tour")
	if P.is_empty() or not tour is Dictionary or not (tour as Dictionary).has("S"):
		return -1.0
	var S: PackedFloat32Array = (tour as Dictionary).S
	return S[_nearest(P, p)]


static func _nearest(P: PackedVector3Array, p: Vector3) -> int:
	var best := 0
	var dist := INF
	for i in P.size():
		var dd := P[i].distance_squared_to(p)
		if dd < dist:
			dist = dd
			best = i
	return best


## A point round the hall's axis, as drone.gd's tour gives them: degrees from +x towards +z (90, the
## entrance), metres out, height.
static func _pol(deg: float, r: float, h: float) -> Vector3:
	var a := deg_to_rad(deg)
	return Vector3(cos(a) * r, h, sin(a) * r)


## A Catmull-Rom curve through the points, sampled `per` times a span, with the length run at each.
static func _curve(points: Array, per := 16) -> Dictionary:
	var pts := PackedVector3Array()
	for q: Vector3 in points:
		pts.append(q)
	if pts.size() == 1:
		pts.append(pts[0])
	var n := pts.size()
	var P := PackedVector3Array()
	for i in n - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var pre: Vector3 = pts[i - 1] if i > 0 else a - (b - a)
		var post: Vector3 = pts[i + 2] if i + 2 < n else b + (b - a)
		for j in per:
			P.append(a.cubic_interpolate(b, pre, post, float(j) / float(per)))
	P.append(pts[n - 1])
	var S := PackedFloat32Array([0.0])
	var run := 0.0
	for i in range(1, P.size()):
		run += P[i].distance_to(P[i - 1])
		S.append(run)
	return {"P": P, "S": S, "L": run}


## The point a fraction f of the way along a curve, by length.
static func _along(c: Dictionary, f: float) -> Vector3:
	var P: PackedVector3Array = c.P
	var S: PackedFloat32Array = c.S
	var L: float = c.L
	if L <= 1e-5:
		return P[0]
	var s := clampf(f, 0.0, 1.0) * L
	var lo := 0
	var hi := S.size() - 1
	while hi - lo > 1:
		var m := (lo + hi) >> 1
		if S[m] <= s:
			lo = m
		else:
			hi = m
	return P[lo].lerp(P[hi], (s - S[lo]) / maxf(1e-6, S[hi] - S[lo]))


# --- The visitor, put aside and given back --------------------------------------------------------

## As drone.gd does while it flies: every other layer hidden, the walking body and the fly camera
## stopped; the held curio hidden, since the cinematic's camera may see where the visitor stands; the
## hologram's one opening by itself kept for the visitor's own approach.
func _put_aside() -> void:
	_hidden_layers.clear()
	for n in _obs.find_children("*", "CanvasLayer", true, false):
		var l := n as CanvasLayer
		if l != _layer and l.visible:
			l.visible = false
			_hidden_layers.append(l)
	stats.hidden_layers = _hidden_layers.size()
	_paused.clear()
	var walker := _obs.get_node_or_null("WalkBody")
	for n: Node in [_camera, walker, walker.get_node_or_null("Early") if walker != null else null]:
		if n != null and n.is_processing():
			n.set_process(false)
			n.set_process_input(false)
			n.set_process_unhandled_input(false)
			_paused.append(n)
	_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var cw := _obs.get_node_or_null("CurioWheel")
	var hold := cw.get("_hold") as Node3D if cw != null else null
	_hold_was = hold == null or hold.visible
	if hold != null:
		hold.visible = false
	var holo := _obs.get_node_or_null("Hologram")
	if holo != null:
		_auto_holo_was = bool(holo.get("_auto_done"))
		holo.set("_auto_done", true)


func _give_back() -> void:
	for l in _hidden_layers:
		if is_instance_valid(l):
			l.visible = true
	_hidden_layers.clear()
	for n in _paused:
		if is_instance_valid(n):
			n.set_process(true)
			n.set_process_input(true)
			n.set_process_unhandled_input(true)
	_paused.clear()
	Input.mouse_mode = _mouse_mode
	var cw := _obs.get_node_or_null("CurioWheel")
	var hold := cw.get("_hold") as Node3D if cw != null else null
	if hold != null:
		hold.visible = _hold_was
	var holo := _obs.get_node_or_null("Hologram")
	# The warm-up's opening behind black doesn't count: only the hologram shot's.
	if holo != null and not _auto_holo_was and not (stats.cues as Array).has("holo"):
		holo.set("_auto_done", false)


## Every key, click and touch is the cinematic's while it plays: the first one ends it.
func _input(event: InputEvent) -> void:
	if not playing:
		return
	var key := event as InputEventKey
	var mb := event as InputEventMouseButton
	var tt := event as InputEventScreenTouch
	if (key != null and key.pressed and not key.echo) or (mb != null and mb.pressed) or (tt != null and tt.pressed):
		skip()
	get_viewport().set_input_as_handled()


func _dof_allowed() -> bool:
	if _obs.has_method("_compatibility") and bool(_obs.call("_compatibility")):
		return false
	var quality := _obs.get_node_or_null("Quality")
	return quality == null or int(quality.get("level")) <= 1


# --- On screen ------------------------------------------------------------------------------------

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "CinematicUI"
	_layer.layer = 90
	_layer.visible = false
	add_child(_layer)
	_fade = _rect("Fade")
	_fade.color = Color(0, 0, 0, 0)
	_top = _rect("BarTop")
	_bottom = _rect("BarBottom")
	_skip = Label.new()
	_skip.name = "Skip"
	_skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_skip.add_theme_color_override("font_color", Color(0.85, 0.82, 0.76))
	_skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip.modulate.a = 0.0
	_layer.add_child(_skip)
	_title = Label.new()
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", GILT)
	var spaced := FontVariation.new()
	spaced.base_font = ThemeDB.fallback_font
	spaced.spacing_glyph = 6
	_title.add_theme_font_override("font", spaced)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.modulate.a = 0.0
	_layer.add_child(_title)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _rect(n: String) -> ColorRect:
	var r := ColorRect.new()
	r.name = n
	r.color = Color.BLACK
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(r)
	return r


func _layout() -> void:
	if _fade == null:
		return
	var size := get_viewport().get_visible_rect().size
	_fade.position = Vector2.ZERO
	_fade.size = size
	_title.position = Vector2.ZERO
	_title.size = size
	_title.add_theme_font_size_override("font_size", int(clampf(minf(size.x, size.y) * 0.06, 22.0, 72.0)))
	_layout_bars()


func _layout_bars() -> void:
	var size := get_viewport().get_visible_rect().size
	var a := size.x / maxf(1.0, size.y)
	var full := size.y * (1.0 - minf(1.0, a / RATIO)) * 0.5 if a >= WIDE else 0.0
	var h := full * smoothstep(0.0, 1.0, _bars)
	stats.bars_px = h
	_top.position = Vector2.ZERO
	_top.size = Vector2(size.x, h)
	_bottom.position = Vector2(0, size.y - h)
	_bottom.size = Vector2(size.x, h)
	var fs := int(clampf(minf(size.x, size.y) * 0.022, 12.0, 22.0))
	_skip.add_theme_font_size_override("font_size", fs)
	var strip := maxf(h, fs * 2.4)
	_skip.position = Vector2(0, size.y - strip)
	_skip.size = Vector2(size.x - fs * 1.5, strip)
