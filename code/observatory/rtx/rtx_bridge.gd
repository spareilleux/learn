extends RefCounted
## The scene agent's eyes and hands in the native package (artpass/publish/rtx/NOTES.md): a JSON-lines TCP
## server on 127.0.0.1 only, which mcp_observatory.py turns into MCP tools for Claude Code. rtx_play.gd starts
## it when the program is given a port:
##   Observatory-RTX.exe -- --rtx-bridge[=8798] [--rtx-shots=<dir>]
## The protocol of artpass/agent/agent_session.gd (pose, goto, walk, turn, look, fov, shot, get, set, tree,
## stats, release, take), on the player's own scene, and for the native settings:
##   view   name secs                       one of rtx_probe.gd's views (hall, wing_mid, terrace...)
##   player [pt] [setting] [fg] [plain_aa] [bounces] [samples] [shelf] [fill] [exposure] [hud]
##                                          set what is given, then return them all; setting is 0 DLAA to
##                                          3 Performance, 5 no DLSS. The player's own steering stops.
##   env    [prop value]                    the scene's Environment: one property, or the usual ones
##   frames n [yaw] [forward] [rect] [name] n frames in a row saved as PNGs (rect in fractions of the
##                                          window), the eye turned by yaw degrees and moved forward metres
##                                          after each: flicker.py scores them (moiré, crawling edges)
## Moves are animated so a watcher sees them, and their reply comes when they end. Prints RTXBRIDGE lines.

const PROBE := "res://rtx/rtx_probe.gd"

var _p   # the player, rtx_play.gd
var _scene: Node3D
var _cam: Camera3D
var _fly: Camera3D
var _server := TCPServer.new()
var _peers: Array = []          # [StreamPeerTCP, buffer]
var _busy := false
var _queue: Array = []          # [peer, request]
var _out := ""
var _shots := 0
var _views := {}


func start(player: Object, port: int, out: String) -> void:
	_p = player
	_out = out
	DirAccess.make_dir_recursive_absolute(_out)
	_views = (load(PROBE) as Script).get_script_constant_map().get("VIEWS", {})
	var err := _server.listen(port, "127.0.0.1")
	print("RTXBRIDGE listening port=%d err=%d shots=%s" % [port, err, _out])
	_p.process_frame.connect(_poll)


func _ready_eye() -> bool:
	if _cam != null:
		return true
	_scene = _p._scene
	if _scene == null or not _scene.is_inside_tree():
		return false
	_fly = _scene.get_node_or_null("FlyCamera") as Camera3D
	_cam = Camera3D.new()
	_cam.name = "AgentEye"
	_scene.add_child(_cam)
	if _fly:
		_cam.global_transform = _fly.global_transform
		_cam.fov = _fly.fov
	_take_eye()
	return true


func _take_eye() -> void:
	if _fly:
		_fly.set_process(false)
		_fly.set_process_input(false)
		_fly.set_process_unhandled_input(false)
	for n: Node in [_scene.get_node_or_null("WalkBody"), _scene.get_node_or_null("WalkBody/Early")]:
		if n != null:
			n.set_process(false)
			n.set_physics_process(false)
	_cam.make_current()


func _poll() -> void:
	while _server.is_connection_available():
		var p := _server.take_connection()
		p.set_no_delay(true)
		_peers.append([p, PackedByteArray()])
	for entry: Array in _peers.duplicate():
		var p: StreamPeerTCP = entry[0]
		p.poll()
		if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.erase(entry)
			continue
		var n := p.get_available_bytes()
		if n > 0:
			var got := p.get_data(n)
			if got[0] == OK:
				entry[1] = (entry[1] as PackedByteArray) + (got[1] as PackedByteArray)
		var buf: PackedByteArray = entry[1]
		var nl := buf.find(10)
		while nl >= 0:
			var line := buf.slice(0, nl).get_string_from_utf8().strip_edges()
			buf = buf.slice(nl + 1)
			if line != "":
				_queue.append([p, line])
			nl = buf.find(10)
		entry[1] = buf
	if not _busy and not _queue.is_empty():
		var job: Array = _queue.pop_front()
		_run(job[0], job[1])


func _run(p: StreamPeerTCP, line: String) -> void:
	_busy = true
	var req: Variant = JSON.parse_string(line)
	var reply: Dictionary
	if typeof(req) != TYPE_DICTIONARY:
		reply = {"ok": false, "error": "not a JSON object"}
	elif not _ready_eye():
		reply = {"ok": false, "error": "the scene is not there yet"}
	else:
		reply = await _handle(req)
	print("RTXBRIDGE %s %s" % [str((req as Dictionary).get("cmd", "?")) if typeof(req) == TYPE_DICTIONARY else "?", JSON.stringify(reply).left(240)])
	if p.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		p.put_data((JSON.stringify(reply) + "\n").to_utf8_buffer())
	_busy = false


func _handle(r: Dictionary) -> Dictionary:
	var cmd := str(r.get("cmd", ""))
	var secs := float(r.get("secs", 1.5))
	match cmd:
		"pose":
			return _pose()
		"goto":
			var to := _v3(r.get("pos"), _cam.global_position)
			var xf := Transform3D(Basis(), to)
			if r.has("look"):
				xf = xf.looking_at(_v3(r.get("look"), to + Vector3.FORWARD), Vector3.UP)
			else:
				xf.basis = _cam.global_transform.basis
			await _move(xf, secs)
			return _pose()
		"walk":
			var yaw := _cam.global_rotation.y
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			var d := fwd * float(r.get("forward", 0.0)) + right * float(r.get("right", 0.0)) + Vector3.UP * float(r.get("up", 0.0))
			await _move(Transform3D(_cam.global_transform.basis, _cam.global_position + d), secs)
			return _pose()
		"turn":
			var rot := _cam.global_rotation
			var pitch := clampf(rot.x + deg_to_rad(float(r.get("pitch", 0.0))), deg_to_rad(-85), deg_to_rad(85))
			var b := Basis.from_euler(Vector3(pitch, rot.y + deg_to_rad(float(r.get("yaw", 0.0))), 0.0))
			await _move(Transform3D(b, _cam.global_position), secs)
			return _pose()
		"look":
			var at := _v3(r.get("at"), _cam.global_position + Vector3.FORWARD)
			await _move(Transform3D(Basis(), _cam.global_position).looking_at(at, Vector3.UP), secs)
			return _pose()
		"view":
			var name := str(r.get("name", "hall"))
			if not _views.has(name):
				return {"ok": false, "error": "no view '%s'" % name, "views": _views.keys()}
			var v: Array = _views[name]
			var on_axis := str(v[0]) == "@"
			var eye: Vector3 = _axis_point(v[1]) if on_axis else v[0]
			var at: Vector3 = _axis_point(v[2]) if on_axis else v[1]
			_cam.fov = float(v[3] if on_axis else v[2])
			await _move(Transform3D(Basis(), eye).looking_at(at, Vector3.UP), secs)
			return _pose()
		"fov":
			var tw: Tween = _p.create_tween()
			tw.tween_property(_cam, "fov", float(r.get("value", 70.0)), secs)
			await tw.finished
			return _pose()
		"shot":
			return await _shot(str(r.get("name", "view")), bool(r.get("hud", false)), r.get("rect", []) as Array)
		"frames":
			return await _frames(r)
		"player":
			return await _player(r)
		"env":
			var env: Environment = _p._env
			if env == null:
				return {"ok": false, "error": "no Environment"}
			if r.has("prop"):
				var prop := str(r.get("prop"))
				var before: Variant = env.get(prop)
				if r.has("value"):
					env.set(prop, _variant(r.get("value"), before))
					for i in 3:
						await _p.process_frame
				return {"ok": true, "prop": prop, "before": _json(before), "value": _json(env.get(prop))}
			return {"ok": true, "env": _env_summary(env)}
		"get":
			var n := _node(str(r.get("node", "")))
			if n == null:
				return {"ok": false, "error": "no node " + str(r.get("node", ""))}
			return {"ok": true, "value": _json(n.get_indexed(NodePath(str(r.get("prop", "")))))}
		"set":
			var n := _node(str(r.get("node", "")))
			if n == null:
				return {"ok": false, "error": "no node " + str(r.get("node", ""))}
			var prop := NodePath(str(r.get("prop", "")))
			var before: Variant = n.get_indexed(prop)
			n.set_indexed(prop, _variant(r.get("value"), before))
			for i in 3:
				await _p.process_frame
			return {"ok": true, "before": _json(before), "after": _json(n.get_indexed(prop))}
		"tree":
			var n := _node(str(r.get("node", "")))
			if n == null:
				return {"ok": false, "error": "no node"}
			return {"ok": true, "tree": _tree(n, int(r.get("depth", 1)))}
		"find":
			var found := []
			for n in _scene.find_children(str(r.get("pattern", "*")), str(r.get("class", "")), true, false):
				found.append({"path": str(_scene.get_path_to(n)), "class": n.get_class()})
				if found.size() >= int(r.get("max", 60)):
					break
			return {"ok": true, "found": found}
		"life":
			# rtx_life.gd's moving things: one switched (key, on), and what was built.
			var life: RefCounted = _p._life
			if life == null:
				return {"ok": false, "error": "rtx_life.gd is not running"}
			if r.has("key"):
				life.call("set_on", str(r.key), bool(r.get("on", true)))
				_p._refresh()
				for i in 3:
					await _p.process_frame
			return {"ok": true, "stats": _json(life.get("stats")), "on": _json(life.get("_on"))}
		"press":
			# A button of the column, as a click presses it.
			var b: Button = _p._buttons.get(str(r.get("button", "")))
			if b == null:
				return {"ok": false, "error": "no button '%s'; there are %s" % [r.get("button", ""), _p._buttons.keys()]}
			b.pressed.emit()
			for i in int(r.get("settle", 3)):
				await _p.process_frame
			return {"ok": true, "text": b.text, "disabled": b.disabled, "player": _player_state()}
		"stats":
			var n := _node(str(r.get("node", "")))
			return {"ok": true, "stats": _json(n.get("stats") if n else null)}
		"release":
			if _fly:
				_fly.global_transform = _cam.global_transform
				_fly.set_process(true)
				_fly.set_process_input(true)
				_fly.set_process_unhandled_input(true)
				_fly.make_current()
			return {"ok": true}
		"take":
			if _fly:
				_cam.global_transform = _fly.global_transform
			_take_eye()
			return _pose()
	return {"ok": false, "error": "unknown cmd '%s'" % cmd}


## The native settings: what the request names, applied as the bar's buttons would, then all of them.
func _player(r: Dictionary) -> Dictionary:
	var changed := false
	if r.has("pt"):
		_p._pt = bool(r.pt) and _p._dlss and _p._env != null
		_p._pt_chosen = true
		changed = true
	if r.has("setting"):
		_p._i = clampi(int(r.setting), 0, _p.SETTINGS.size() - 1)
		_p._auto = false
		changed = true
	if r.has("fg"):
		_p._fg = bool(r.fg)
		changed = true
	if r.has("plain_aa") and _p.PLAIN.has(str(r.plain_aa)):
		_p.plain_aa = str(r.plain_aa)
		changed = true
	if r.has("shelf"):
		_p.shelf = float(r.shelf)
		_p._set_shelf_lamps()
	if r.has("fill") and is_instance_valid(_p._fill):
		_p.fill = float(r.fill)
		for l in (_p._fill as Node3D).get_children():
			if l is Light3D and l.has_meta("rtx_energy"):
				(l as Light3D).light_energy = float(l.get_meta("rtx_energy")) * _p.fill
	if r.has("hud"):
		_p._hud = int(r.hud)
		_p._label.visible = _p._hud == 0
		_p._badge_box.visible = _p._hud < 2
	if changed:
		if _p._pt and not bool(_p.SETTINGS[_p._i][1]):
			_p._i = 0
		_p._apply()
		_p._mine = [_p._i, _p._pt]
	var env: Environment = _p._env
	if env != null:
		if r.has("bounces"):
			env.set("pathtracing_max_bounces", int(r.bounces))
		if r.has("samples"):
			env.set("pathtracing_samples_per_pixel", int(r.samples))
		if r.has("exposure"):
			env.tonemap_exposure = float(r.exposure)
	for i in int(r.get("settle", 3)):
		await _p.process_frame
	return {"ok": true, "player": _player_state()}


func _player_state() -> Dictionary:
	var env: Environment = _p._env
	var st := {"setting": _p._setting_name(_p._i), "setting_index": _p._i, "pt": _p._pt, "fg": _p._fg,
		"auto": _p._auto, "plain_aa": _p.plain_aa, "shelf": _p.shelf, "fill": _p.fill, "dlss_available": _p._dlss,
		"msaa_3d": _p._vp.msaa_3d, "screen_space_aa": _p._vp.screen_space_aa, "use_taa": _p._vp.use_taa,
		"scaling_3d_mode": _p._vp.scaling_3d_mode, "scaling_3d_scale": _p._vp.scaling_3d_scale,
		"line": _p._label.text.get_slice("\n", 0), "badge": _p._badge.text}
	if env != null:
		st.bounces = env.get("pathtracing_max_bounces")
		st.samples = env.get("pathtracing_samples_per_pixel")
		st.exposure = env.tonemap_exposure
	return st


func _env_summary(env: Environment) -> Dictionary:
	var out := {}
	for prop in ["background_mode", "ambient_light_source", "ambient_light_energy", "ambient_light_color",
			"tonemap_mode", "tonemap_exposure", "tonemap_white", "glow_enabled", "glow_intensity", "glow_strength",
			"glow_bloom", "glow_hdr_threshold", "glow_blend_mode", "fog_enabled", "fog_density", "fog_light_energy",
			"volumetric_fog_enabled", "volumetric_fog_density", "volumetric_fog_albedo", "volumetric_fog_emission_energy",
			"ssr_enabled", "ssao_enabled", "ssao_intensity", "ssil_enabled", "sdfgi_enabled", "sdfgi_energy",
			"adjustment_enabled", "adjustment_brightness", "adjustment_contrast", "adjustment_saturation",
			"pathtracing_enabled", "pathtracing_max_bounces", "pathtracing_samples_per_pixel", "pathtracing_denoiser"]:
		if prop in env:
			out[prop] = _json(env.get(prop))
	return out


func _move(to: Transform3D, secs: float) -> void:
	if secs <= 0.0:
		_cam.global_transform = to
		return
	var from := _cam.global_transform
	var q0 := from.basis.get_rotation_quaternion()
	var q1 := to.basis.get_rotation_quaternion()
	var t := 0.0
	while t < secs:
		await _p.process_frame
		t += _p.root.get_process_delta_time()
		var k := smoothstep(0.0, 1.0, clampf(t / secs, 0.0, 1.0))
		_cam.global_transform = Transform3D(Basis(q0.slerp(q1, k)), from.origin.lerp(to.origin, k))
	_cam.global_transform = to


func _hide_hud(hide: bool) -> Array[CanvasLayer]:
	var hidden: Array[CanvasLayer] = []
	if hide:
		for n in (_p.root as Window).find_children("*", "CanvasLayer", true, false):
			var layer := n as CanvasLayer
			if layer.visible:
				layer.visible = false
				hidden.append(layer)
	return hidden


func _shot(name: String, hud: bool, rect: Array = []) -> Dictionary:
	var hidden := _hide_hud(not hud)
	var vp: RID = (_p.root as Window).get_viewport_rid()
	var gpu := 0.0
	for i in 30:
		await _p.process_frame
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	await RenderingServer.frame_post_draw
	_shots += 1
	var path := _out.path_join("%03d-%s.png" % [_shots, name.validate_filename()])
	var img := (_p.root as Window).get_texture().get_image()
	img.save_png(path)
	for layer in hidden:
		layer.visible = true
	var pose := _pose()
	pose.merge({"path": path, "gpu_ms": snappedf(gpu / 30.0, 0.01), "size": [img.get_width(), img.get_height()],
		"luma": _luma(img, rect), "player": _player_state()}, true)
	return pose


## n frames in a row, each saved whole or as rect, the eye stepped between them by a fixed amount a frame
## (not a time): a stalled frame (saving a PNG takes a while) moves the picture no more than any other.
func _frames(r: Dictionary) -> Dictionary:
	var n := clampi(int(r.get("n", 8)), 2, 60)
	var yaw := deg_to_rad(float(r.get("yaw", 0.0)))
	var fwd := float(r.get("forward", 0.0))
	var rect: Array = r.get("rect", [])
	var name := str(r.get("name", "frames")).validate_filename()
	var hidden := _hide_hud(not bool(r.get("hud", false)))
	for i in 20:  # settle after the HUD goes: temporal anti-aliasing keeps a history
		await _p.process_frame
	var dir := _out.path_join("%s-%d" % [name, Time.get_ticks_msec()])
	DirAccess.make_dir_recursive_absolute(dir)
	var paths := []
	var back := _cam.global_transform
	for i in n:
		await RenderingServer.frame_post_draw
		var img := (_p.root as Window).get_texture().get_image()
		if rect.size() == 4:
			var w := img.get_width()
			var h := img.get_height()
			img = img.get_region(Rect2i(int(float(rect[0]) * w), int(float(rect[1]) * h),
				int((float(rect[2]) - float(rect[0])) * w), int((float(rect[3]) - float(rect[1])) * h)))
		var path := dir.path_join("%02d.png" % i)
		img.save_png(path)
		paths.append(path)
		_cam.global_rotate(Vector3.UP, yaw)
		var f := -_cam.global_transform.basis.z
		_cam.global_position += Vector3(f.x, 0.0, f.z).normalized() * fwd
	_cam.global_transform = back
	for layer in hidden:
		layer.visible = true
	return {"ok": true, "dir": dir, "paths": paths, "player": _player_state()}


func _luma(img: Image, rect: Array) -> Dictionary:
	var small := img.duplicate() as Image
	small.convert(Image.FORMAT_RGB8)
	small.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	var out := {"frame": _luma_in(small, Rect2i(0, 0, 320, 180))}
	if rect.size() == 4:
		var rr := Rect2i(int(float(rect[0]) * 320), int(float(rect[1]) * 180), 0, 0)
		rr.end = Vector2i(int(float(rect[2]) * 320), int(float(rect[3]) * 180))
		out["rect"] = _luma_in(small, rr)
	return out


func _luma_in(img: Image, r: Rect2i) -> Dictionary:
	var sum := 0.0
	var dark := 0
	var bright := 0
	var n := 0
	for y in range(maxi(r.position.y, 0), mini(r.end.y, img.get_height())):
		for x in range(maxi(r.position.x, 0), mini(r.end.x, img.get_width())):
			var c := img.get_pixel(x, y)
			var l := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			sum += l
			n += 1
			if l < 0.04:
				dark += 1
			elif l > 0.9:
				bright += 1
	var m := maxf(n, 1.0)
	return {"mean": snappedf(sum / m, 0.001), "dark": snappedf(dark / m, 0.001), "white": snappedf(bright / m, 0.001)}


func _pose() -> Dictionary:
	var p := _cam.global_position
	var r := _cam.global_rotation
	var fwd := -_cam.global_transform.basis.z
	var vp: RID = (_p.root as Window).get_viewport_rid()
	return {"ok": true, "pos": [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)],
		"yaw": snappedf(rad_to_deg(r.y), 0.1), "pitch": snappedf(rad_to_deg(r.x), 0.1), "fov": snappedf(_cam.fov, 0.1),
		"looking": [snappedf(fwd.x, 0.01), snappedf(fwd.y, 0.01), snappedf(fwd.z, 0.01)],
		"fps": Engine.get_frames_per_second(), "gpu_ms": snappedf(RenderingServer.viewport_get_measured_render_time_gpu(vp), 0.01),
		"window": str((_p.root as Window).size)}


func _axis_point(v: Vector3) -> Vector3:
	var a := deg_to_rad(float((load(PROBE) as Script).get_script_constant_map().get("AXIS_DEG", 236.25)))
	return Vector3(cos(a), 0.0, sin(a)) * v.x + Vector3.UP * v.y + Vector3(-sin(a), 0.0, cos(a)) * v.z


func _node(path: String) -> Node:
	if path == "" or path == ".":
		return _scene
	if path == "/root":
		return _p.root
	return _scene.get_node_or_null(path)


func _tree(n: Node, depth: int) -> Array:
	var out := []
	for c in n.get_children():
		var item := {"name": String(c.name), "class": c.get_class()}
		if depth > 1 and c.get_child_count() > 0:
			item.children = _tree(c, depth - 1) if c.get_child_count() <= 40 else "%d children" % c.get_child_count()
		out.append(item)
		if out.size() >= 80:
			out.append("…%d more" % (n.get_child_count() - 80))
			break
	return out


func _v3(v: Variant, fallback: Vector3) -> Vector3:
	if typeof(v) == TYPE_ARRAY and (v as Array).size() == 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return fallback


func _variant(v: Variant, like: Variant) -> Variant:
	match typeof(like):
		TYPE_VECTOR3:
			if typeof(v) == TYPE_ARRAY:
				return Vector3(float(v[0]), float(v[1]), float(v[2]))
		TYPE_COLOR:
			if typeof(v) == TYPE_ARRAY:
				return Color(float(v[0]), float(v[1]), float(v[2]), float(v[3]) if (v as Array).size() > 3 else 1.0)
		TYPE_INT:
			return int(v)
		TYPE_FLOAT:
			return float(v)
		TYPE_BOOL:
			return bool(v)
	return v


func _json(v: Variant) -> Variant:
	match typeof(v):
		TYPE_VECTOR3:
			return [v.x, v.y, v.z]
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return [v.x, v.y]
		TYPE_COLOR:
			return [v.r, v.g, v.b, v.a]
		TYPE_DICTIONARY, TYPE_ARRAY, TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_NIL:
			return JSON.parse_string(JSON.stringify(v))
	return str(v)
