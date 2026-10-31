extends Node
## The telescope's jump (the author, 2026-10-16: « tu rajouteras la possibilité de se téléporter où on veut dans
## la scène (quand on zoome avec le télescope) », « tu feras une animation pour la téléportation »). At the
## eyepiece (scripts/telescope.gd), Enter goes to the ground at the reticle's middle: the gardens, their avenues,
## the terrace and the Place du Capitole. The eyepiece reads its distance, or that no ground is in the sights (the
## sky, the city, the hall from outside).
## The aim runs along the view, marched over the ground (palace_gardens.gd ground_at), and stops at the hall's
## walls, the library wing and the square's buildings (capitole_square.gd in_building), landing at their foot.
## The jump is a flight in an arc over the trees, eased in and out. The view is drawn into its middle as it goes,
## a zoom blur stronger towards the edges, and lit as it lands. There the visitor stands on foot with the scooter
## parked beside (scripts/segway.gd land_at), or still riding it.

const MAX_D := 1500.0       # m: the furthest ground aimed at
const HALL_TOP := 34.0      # m: the hall's walls and drum, for the aim
const BUILDING_H := 16.0    # m over the square's paving: its buildings, for the aim
const ARC := Vector2(0.12, 40.0)   # the arc's height: this much of the way, at most this many metres
const EYE := 1.7

var flying := false
## For tests: jumps made, aims refused, the last jump.
var stats := {"jumps": 0, "refused": 0, "last": {}}

var _obs: Node3D
var _cam: Camera3D
var _seg: Node
var _gardens: Node
var _views: Node
var _veil: ColorRect
var _t := 0.0
var _dur := 1.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _mid := Vector3.ZERO
var _yaw := 0.0
var _pitch0 := 0.0
var _spot := Vector2.ZERO
var _ride := false
var _from_roof := false
var _back := Transform3D()
var _back_look := Vector2.ZERO
var _paused: Array = []   # [node, processing, physics processing] stopped for the flight
var _flash := 0.0
var _aim := {}
var _aim_frame := -100


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_cam = camera


func _ready() -> void:
	# After the scooter, the walking body and the roof's hold (870), before the telescope (890) and view_fit (900).
	process_priority = 885
	_build_ui()


func _find() -> void:
	if _obs == null:
		return
	if _gardens == null:
		_gardens = _obs.get_node_or_null("PalaceGardens")
	if _seg == null:
		_seg = _obs.get_node_or_null("Segway")
	if _views == null:
		_views = _obs.get_node_or_null("ExtraViews")


## What the reticle's middle rests on: {"ok", "m" (the distance), "why" ("" on the ground, "hall", "wing",
## "building", "sky", "far")}, and when ok "spot", where one would stand (x, z). Worked out at most every third
## frame.
func aim() -> Dictionary:
	var f := Engine.get_process_frames()
	if f - _aim_frame < 3 and not _aim.is_empty():
		return _aim
	_aim_frame = f
	_aim = _aim_now()
	return _aim


func _aim_now() -> Dictionary:
	_find()
	if _cam == null or _gardens == null or _seg == null or not _seg.has_method("spot_at"):
		return {"ok": false, "why": "none", "m": 0.0}
	var o := _cam.global_position
	var d := -_cam.global_basis.z.normalized()
	var outer := float(_obs.get("outer_radius")) + 1.0
	var inside_hall := Vector2(o.x, o.z).length() < outer and o.y < HALL_TOP
	var sq := _gardens.get("_capitole") as Node3D
	var wing := _obs.get_node_or_null("LibraryWing")
	var t := 0.3
	var prev := 0.0
	var hit := Vector3.INF
	var why := ""
	while t < MAX_D:
		var s := o + d * t
		var flat := Vector2(s.x, s.z)
		if s.y <= float(_gardens.call("ground_at", flat)):
			var a := prev
			var b := t
			for i in 12:
				var m := (a + b) * 0.5
				var sm := o + d * m
				if sm.y <= float(_gardens.call("ground_at", Vector2(sm.x, sm.z))):
					b = m
				else:
					a = m
			hit = o + d * b
			break
		if not inside_hall and flat.length() < outer and s.y < HALL_TOP:
			why = "hall"
		elif wing != null and wing.has_method("contains") and bool(wing.call("contains", s)):
			why = "wing"
		elif sq != null and s.y < sq.global_position.y + BUILDING_H and bool(sq.call("in_building", flat)):
			why = "building"
		if why != "":
			hit = s
			break
		prev = t
		t += maxf(0.25, t * 0.01)
	if hit == Vector3.INF:
		return {"ok": false, "why": "sky" if d.y >= 0.0 else "far", "m": 0.0}
	# Stopped by a wall: at its foot, on the near side; by the hall, out on the terrace round it.
	var foot := Vector2(hit.x, hit.z)
	if why == "hall":
		foot = foot.normalized() * (outer + 1.5)
	elif why != "":
		var fd := Vector2(d.x, d.z)
		foot -= (fd.normalized() if fd.length() > 1e-3 else Vector2.ZERO) * 0.6
	var spot: Vector2 = _seg.call("spot_at", foot)
	var r := {"ok": spot != Vector2.INF, "why": why, "m": o.distance_to(hit), "at": hit}
	if spot != Vector2.INF:
		r.spot = spot
	elif why == "":
		r.why = "far"
	return r


## Enter at the eyepiece: the flight to the ground in the sights. False, and nothing moves, when there is none.
func go() -> bool:
	if flying:
		return false
	_aim_frame = -100
	var a := aim()
	if not bool(a.ok):
		stats.refused += 1
		return false
	_spot = a.spot
	_ride = bool(_seg.get("riding"))
	var out := _ride or bool(_seg.get("on_foot"))
	_from_roof = not out and _views != null and bool(_views.get("on_roof"))
	if _from_roof:
		_views.call("_leave_roof", true)
	var move := _obs.get_node_or_null("ViewMove")
	if move != null and move.has_method("cut"):
		move.call("cut")
	_back = _cam.global_transform
	_back_look = Vector2(float(_cam.get("_yaw")), float(_cam.get("_pitch")))
	var gy := float(_gardens.call("ground_at", _spot))
	var walk_eye = _cam.get("walking_eye_height")
	var eye := (float(_seg.get_script().get("DECK")) + float(_seg.get_script().get("EYE"))) if _ride else (float(walk_eye) if walk_eye != null else EYE)
	_from = _cam.global_position
	_to = Vector3(_spot.x, gy + eye, _spot.y)
	var dist := _from.distance_to(_to)
	var h := clampf(dist * ARC.x, 1.0, ARC.y)
	# A quadratic Bézier: its top h over the chord's middle.
	_mid = (_from + _to) * 0.5 + Vector3.UP * (2.0 * h)
	var flat := Vector2(_to.x - _from.x, _to.z - _from.z)
	_yaw = atan2(-flat.x, -flat.y) if flat.length() > 0.5 else float(_cam.get("_yaw"))
	_yaw = float(_cam.get("_yaw")) + wrapf(_yaw - float(_cam.get("_yaw")), -PI, PI)
	_pitch0 = float(_cam.get("_pitch"))
	_dur = clampf(0.6 + dist / 700.0, 0.7, 1.4)
	_t = 0.0
	flying = true
	# Nothing else moves the camera on the way: the fly camera, the walking body, the scooter.
	_paused.clear()
	var walker := _obs.get_node_or_null("WalkBody")
	for n: Node in [_cam, walker, walker.get_node_or_null("Early") if walker != null else null, _seg]:
		if n != null and (n.is_processing() or n.is_physics_processing()):
			_paused.append([n, n.is_processing(), n.is_physics_processing()])
			n.set_process(false)
			n.set_physics_process(false)
	var scope := get_parent()
	if scope != null and scope.has_method("set_on"):
		scope.call("set_on", false)
	stats.jumps += 1
	stats.last = {"from": [snappedf(_from.x, 0.01), snappedf(_from.y, 0.01), snappedf(_from.z, 0.01)],
		"spot": [snappedf(_spot.x, 0.01), snappedf(_spot.y, 0.01)], "m": snappedf(dist, 0.1),
		"s": snappedf(_dur, 0.01), "why": a.why, "ride": _ride}
	return true


func _process(delta: float) -> void:
	if flying:
		_t += delta
		var u := clampf(_t / _dur, 0.0, 1.0)
		var e := u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
		var v := 1.0 - e
		_cam.global_position = _from * (v * v) + _mid * (2.0 * v * e) + _to * (e * e)
		var pitch := lerpf(_pitch0, -0.06, smoothstep(0.0, 1.0, u))
		var yaw := lerpf(float(_back_look.x), _yaw, smoothstep(0.0, 0.35, u))
		_cam.set("_yaw", yaw)
		_cam.set("_pitch", pitch)
		_cam.rotation = Vector3(pitch, yaw, 0.0)
		_set_veil(pow(sin(PI * u), 0.7), 0.0)
		if u >= 1.0:
			_arrive()
		return
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 2.8, 0.0)
		_set_veil(0.0, _flash)


func _arrive() -> void:
	flying = false
	for e: Array in _paused:
		var n: Node = e[0]
		if is_instance_valid(n):
			n.set_process(bool(e[1]))
			n.set_physics_process(bool(e[2]))
	_paused.clear()
	var ok := bool(_seg.call("land_at", _spot, _ride, _yaw, _from_roof, _back, _back_look))
	if not ok:
		_cam.set("_free_fly", true)
	stats.last.landed = ok
	_flash = 1.0
	_set_veil(0.0, _flash)


func _set_veil(k: float, flash: float) -> void:
	_veil.visible = k > 0.002 or flash > 0.002
	var m := _veil.material as ShaderMaterial
	m.set_shader_parameter("k", k)
	m.set_shader_parameter("flash", flash)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4  # the telescope's: under the course UI (5), the touch controls (6) and the curio wheel (40)
	add_child(layer)
	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
// The jump (scripts/teleport.gd): the view drawn into its middle, more towards its edges, darkening to the
// telescope's sand there; at the landing, a light that fades.
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float k = 0.0;
uniform float flash = 0.0;

void fragment() {
	vec2 d = SCREEN_UV - vec2(0.5);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float r = length(vec2(d.x * aspect, d.y));
	float pull = k * 0.28 * smoothstep(0.05, 0.6, r);
	vec3 acc = vec3(0.0);
	for (int i = 0; i < 14; i++) {
		float t = float(i) / 13.0;
		acc += texture(screen, vec2(0.5) + d * (1.0 - pull * t)).rgb;
	}
	vec3 col = acc / 14.0;
	float edge = smoothstep(0.3, 0.85, r);
	col = mix(col, col * 0.3 + vec3(1.0, 0.72, 0.4) * 0.06, edge * k);
	col += vec3(1.0, 0.93, 0.82) * flash * 0.55 * (1.0 - 0.5 * r);
	COLOR = vec4(col, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_veil.material = m
	_veil.visible = false
	layer.add_child(_veil)
