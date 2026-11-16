extends Node3D
## A troupe of seven small TARS that the whistle calls up where it points (scripts/curio_wheel.gd):
## they dance for seventeen seconds, facing you, hold the finale a moment and are gone. The author
## asked for the group dance in the scene, out of a new curio of the wheel (2026-10-03).
## The dance is the previs of 2026-10-03 (C:/tmp/observatory-tars-dance-previs/ensemble-20261003,
## option B, at 120 crotchets a minute): the lead's moonwalk entrance, unison, a canon, call and
## response, a staggered arrowhead opening into a V, a held finale. Its motion was simulated and
## checked there (no collisions, no floating, no planted foot sliding) and baked at 24 frames a
## second into assets/tars_ensemble_tracks.tres (godot-int/make_godot_tracks.py); this plays the
## baked frames back, interpolated as Blender's linear keys were, so what is seen is what was
## checked. The robots are built as scripts/tars.gd builds its own, in brushed aluminium, with a band
## of each one's colour at the foot of each slab, lit as it lands, and the lead's joints and pin in
## gold; a cabaret spot follows them (_light).
## A second number, by turns with the first (the author, 2026-10-03: "second numero"): an original jig
## in 6/8, the seven in one straight line, simulated, checked and baked the same way
## (tars_ensemble.py --routine=jig) into assets/tars_ensemble_jig_tracks.tres.
## Nothing here walks by itself: where they may dance is checked once, before they appear (fits).
## The curio wheel keeps both baked dances and a warmed troupe's materials from its start, under the
## web build's renderer, so that a call neither loads nor compiles them (curio_wheel.gd _warm_troupe).

const TRACKS_PATH := "res://assets/tars_ensemble_tracks.tres"
const JIG_TRACKS_PATH := "res://assets/tars_ensemble_jig_tracks.tres"
const NUMBERS := [TRACKS_PATH, JIG_TRACKS_PATH]  # the whistle's numbers, by turns: the first dance, the jig
const TARS_SCRIPT_PATH := "res://scripts/tars.gd"  # its steel_material(), the wand's TARS's too
const H := 0.36            # m, a slab's length, at size 1: scripts/tars.gd's
const R := H * 0.5
const W := 0.034
const GAP := 0.004
const D := 0.042           # a slab's depth, unless the baked dance says otherwise (metadata "depth")
const CH := 8              # x, y, z, yaw, rx0, rx1, l0, l1 per dancer per frame
const HOLD_EXTRA := 1.0    # s the finale is held past the dance's end
const GLOW_TAU := 0.1      # s a landing's glow takes to fade to a third, as in the previs
const SHELF_R := 17.14     # the shelves' front, from the hall's centre
const RAIL_R := 13.78      # a gallery's rail
const CLEAR := 0.05        # m kept from obstacles beyond the feet's reach, at size 1
const SPOT_COLOUR := Color(1.0, 0.9, 0.76)  # warm, as the previs's lead spot, a little whiter: at its 0.85, 0.62 the web build's aluminium went cream
const SPOT_ENERGY := 8.0          # under Forward+; the web build's marble took 6 without burning (WEB_SPOT_ENERGY)
const WEB_SPOT_ENERGY := 6.0
const BEAM_SHADER := """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint = vec3(1.0, 0.9, 0.76);
uniform float strength = 0.05;
varying float along;
void vertex() {
	along = VERTEX.y + 0.5;  // 0 where it meets the floor, 1 at the lamp
}
void fragment() {
	// Brightest where the cone is seen face on, as a lit haze is thickest along the axis; nothing at
	// its rim.
	float face = abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = tint;
	ALPHA = strength * face * face * mix(0.4, 1.0, along);
}
"""

var size := 1.0
var number := 0            # which of NUMBERS it dances
var duration := 17.0
## Counts for tests: frames played, cue sounds, landings lit, whether it ended or was stopped.
var stats := {"frames": 0, "cues": 0, "clanks": 0, "landings": 0, "done": false, "stopped": false}
var gone := false

var _cw: Node
var _xf := Transform3D.IDENTITY
var _data: Resource
var _toward := Vector3.ZERO
var _tracks := PackedFloat32Array()
var _footprint := PackedVector2Array()
var _hues := PackedColorArray()
var _n := 7
var _frames := 408
var _fps := 24.0
var _lead := 3
var _hold_from := 16.22
var _reach := 1.4
var _cell := 0.15
var _t := 0.0
var _rigs: Array = []      # {root, pivots, slabs, panel, feet: [pair 0, pair 1]}
var _cues: Array = []      # {t, f, who: [[dancer, pair], ...]}, by time
var _next_cue := 0
var _landed: Array = []    # per dancer: the time each pair last landed
var _mats := {}
var _depth := D
var _spot: SpotLight3D
var _beam: MeshInstance3D
var _beam_mat: ShaderMaterial
var _lamp := Vector3.ZERO  # where the spot hangs, in the world
var _spot_keys := PackedFloat32Array()  # (time, how open) pairs: 0 on the lead, 1 on all
var _spot_all := 1.3       # m, how wide the spot opens on all, at size 1
var _web := RenderingServer.get_current_rendering_method() == "gl_compatibility"
var _ground := Rect2()     # the footprint's bounds, in the stage's own frame at size 1
## The beam's shader while anything holds it (the curio wheel keeps the warmed troupe's): a new Shader
## is compiled anew by the web build's renderer at every call.
static var _beam_shader: WeakRef


## Number n's baked dance (ResourceLoader keeps one copy while a troupe, or the curio wheel, holds it).
static func data(n := 0) -> Resource:
	return load(NUMBERS[clampi(n, 0, NUMBERS.size() - 1)])


## How far from its centre the troupe may reach in number n, at size 1 (m): the feet included.
static func reach(n := 0) -> float:
	return float(data(n).get_meta("reach", 1.4))


## cw: the curio wheel. at: the stage's centre, on its floor. toward: the audience, which the troupe
## faces; s: its size, 1 for robots 36 cm tall; n: the number, 0 the first dance, 1 the jig.
func configure(cw: Node, at: Vector3, toward: Vector3, s: float, n := 0) -> void:
	_cw = cw
	size = s
	number = clampi(n, 0, NUMBERS.size() - 1)
	_toward = toward
	var d := data(number)
	_data = d
	_tracks = d.get_meta("tracks")
	_footprint = d.get_meta("footprint")
	_ground = Rect2(_footprint[0], Vector2.ZERO) if not _footprint.is_empty() else Rect2()
	for p in _footprint:
		_ground = _ground.expand(p)
	_hues = d.get_meta("hues")
	_n = int(d.get_meta("dancers"))
	_frames = int(d.get_meta("frames"))
	_fps = float(d.get_meta("fps"))
	_lead = int(d.get_meta("lead"))
	_hold_from = float(d.get_meta("hold_from"))
	duration = float(d.get_meta("duration"))
	_reach = float(d.get_meta("reach"))
	_depth = float(d.get_meta("depth", D))
	_cell = float(d.get_meta("cell"))
	# The first number's resource predates the spot's cues: lit as it was tuned.
	_spot_keys = d.get_meta("spot", PackedFloat32Array([0.0, 0.0, 2.2, 0.0, 3.2, 1.0, _hold_from, 1.0, _hold_from + 0.45, 0.0]))
	_spot_all = float(d.get_meta("spot_all", 1.3))
	var to :=Vector2(toward.x - at.x, toward.z - at.z)
	var yaw := atan2(to.x, to.y) if to.length() > 1e-4 else 0.0
	_xf = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), at)


## Whether the whole dance fits where it was put: every ground the hinges cover, with the feet's
## reach, on the stage's own floor (no step, no edge), inside the shelves and, on a gallery, outside
## its rail, clear of the lift's shaft, the steel box, the piers, the pedestal and the door, and not
## on top of the audience. Asked before the troupe enters the hall.
func fits() -> bool:
	var w: Node = _cw.call("_walker") if _cw != null else null
	if w != null and w.get("region") != null:
		return false  # the corridor's walls are its own
	var floor_y := _xf.origin.y
	var m := (R + CLEAR) * size + _cell * 0.71 * size
	var obs := _cw.get("_obs") as Node if _cw != null else null
	var lift: Node = obs.get_node_or_null("Lift") if obs != null else null
	var you := Vector2(_toward.x, _toward.z)
	for p in _footprint:
		var g := _xf * Vector3(p.x, 0.0, p.y)
		var flat := Vector2(g.x, g.z)
		var r := flat.length()
		if r > SHELF_R - m:
			return false
		if flat.distance_to(you) < m + 0.35:
			return false
		if floor_y > 1.0 and floor_y < 20.0 and r < RAIL_R + m:
			return false
		if w != null and w.has_method("_support"):
			if absf(float(w.call("_support", flat, floor_y + 0.1 * size)) - floor_y) > 0.03 * size:
				return false
		if lift != null and lift.has_method("in_shaft"):
			for o in [Vector2.ZERO, Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
				if bool(lift.call("in_shaft", flat + o)):
					return false
		if floor_y < 1.0 and w != null and w.has_method("_boxes"):
			for b: Array in w.call("_boxes", flat):
				var dd: Vector2 = flat - (b[0] as Vector2)
				var h: Vector2 = b[3]
				if absf(dd.dot(b[1])) < h.x + m and absf(dd.dot(b[2])) < h.y + m:
					return false
	return true


func _ready() -> void:
	name = "TarsTroupe"
	global_transform = _xf
	_build()
	var by_frame := {}
	var td: PackedInt32Array = _data.get_meta("touchdowns")
	for k in range(0, td.size(), 3):
		var f := td[k]
		if not by_frame.has(f):
			by_frame[f] = []
		(by_frame[f] as Array).append([td[k + 1], td[k + 2]])
	var keys := by_frame.keys()
	keys.sort()
	for f: int in keys:
		_cues.append({"t": f / _fps, "f": f, "who": by_frame[f]})
	for i in _n:
		_landed.append([-INF, -INF])
	_pose_at(0.0)
	_make_spot()
	_light(0.0)



## The ankh: they bow out at once.
func stop() -> void:
	if gone:
		return
	stats.stopped = true
	_finish()


## The corners of every ground the dance covers, in the world, at the floor and at a robot's height and
## a half (its hops): what the curio wheel frames.
func extent() -> PackedVector3Array:
	var out := PackedVector3Array()
	for c: Vector2 in [_ground.position, Vector2(_ground.end.x, _ground.position.y), _ground.end,
			Vector2(_ground.position.x, _ground.end.y)]:
		for h: float in [0.0, H * 1.5]:
			out.append(_xf * Vector3(c.x, h, c.y))
	return out


## Each robot's box in the world, for the Index: its transform and half size.
func bounds_list() -> Array:
	var out := []
	for rig: Dictionary in _rigs:
		var root := rig.root as Node3D
		out.append([Transform3D(root.global_basis.orthonormalized(), root.global_position), Vector3(2.0 * W + 1.5 * GAP, R, _depth) * size])
	return out


## Where each robot's hinge is, in the world.
func hinges() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for rig: Dictionary in _rigs:
		out.append((rig.root as Node3D).global_position)
	return out


func _process(delta: float) -> void:
	if gone:
		return
	_t += delta
	stats.frames = int(stats.frames) + 1
	_pose_at(minf(_t, duration))
	while _next_cue < _cues.size() and float(_cues[_next_cue].t) <= _t:
		_cue(_cues[_next_cue])
		_next_cue += 1
	_glow()
	_light(_t)
	if int(stats.frames) % 15 == 1:
		_publish()
	if _t >= duration + HOLD_EXTRA:
		_finish()


## The baked pose at t, each channel interpolated between the two frames around it.
func _pose_at(t: float) -> void:
	var u := clampf(t * _fps, 0.0, float(_frames - 1))
	var f0 := mini(int(u), _frames - 1)
	var f1 := mini(f0 + 1, _frames - 1)
	var k := u - f0
	for i in _n:
		var a := (f0 * _n + i) * CH
		var b := (f1 * _n + i) * CH
		var v := PackedFloat32Array()
		v.resize(CH)
		for c in CH:
			v[c] = lerpf(_tracks[a + c], _tracks[b + c], k)
		var rig: Dictionary = _rigs[i]
		var root := rig.root as Node3D
		root.position = Vector3(v[0], v[1], v[2])
		root.rotation = Vector3(0.0, v[3], 0.0)
		for s in 4:
			var p := 0 if (s == 0 or s == 3) else 1
			(rig.pivots[s] as Node3D).rotation = Vector3(v[4 + p], 0.0, 0.0)
			(rig.slabs[s] as Node3D).position = Vector3(0.0, v[6 + p], 0.0)


## A cue: the robots that land on this frame. Their bands light, and one knock of metal sounds for
## them all, louder the more there are, where they are, if you are near enough to hear it.
func _cue(cue: Dictionary) -> void:
	stats.cues = int(stats.cues) + 1
	var at := Vector3.ZERO
	var who: Array = cue.who
	for w: Array in who:
		(_landed[int(w[0])] as Array)[int(w[1])] = float(cue.t)
		at += ((_rigs[int(w[0])] as Dictionary).root as Node3D).global_position
		stats.landings = int(stats.landings) + 1
	at /= float(who.size())
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if _cw != null and _cw.has_method("_sound_at") and cam != null and cam.global_position.distance_to(at) < 14.0:
		_cw.call("_sound_at", "clank", at, minf(0.9, 0.3 + 0.06 * who.size()))
		stats.clanks = int(stats.clanks) + 1


## The panels glow in each robot's colour and flare as it lands; the band at a slab's foot lights as
## its pair lands and fades; the lead's panel stays lit through the held finale.
func _glow() -> void:
	for i in _n:
		var rig: Dictionary = _rigs[i]
		var hue := _hues[i]
		var last: Array = _landed[i]
		var flare := 0.0
		for p in 2:
			var e := exp(-maxf(0.0, _t - float(last[p])) / GLOW_TAU) if float(last[p]) > -INF else 0.0
			flare = maxf(flare, e)
			(rig.feet[p] as StandardMaterial3D).albedo_color = _dim(hue, 0.22 + 0.78 * e)
		var held := 1.0 if (i == _lead and _t >= _hold_from) else 0.0
		(rig.panel as StandardMaterial3D).albedo_color = _dim(hue, 0.6 + 0.4 * maxf(flare, held))


## Gone: a puff of each one's colour where it stood, two beeps, and the curio wheel is told.
func _finish() -> void:
	gone = true
	stats.done = true
	var mid := Vector3.ZERO
	for i in _rigs.size():
		var at := ((_rigs[i] as Dictionary).root as Node3D).global_position + Vector3(0.0, 0.05 * size, 0.0)
		mid += at
		if _cw != null and _cw.has_method("_sparkle"):
			_cw.call("_sparkle", at, _hues[i], size)
	mid /= maxf(1.0, float(_rigs.size()))
	if _cw != null and _cw.has_method("_sound_at"):
		_cw.call("_sound_at", "beep", mid, 0.8)
	if _cw != null and _cw.has_method("_troupe_done"):
		_cw.call("_troupe_done", self)
	_publish()
	queue_free()


## Web tests: the number, its time and size, the cues and landings so far, whether it ended or was
## sent off (window.__obsTroupe), every quarter second at 60 frames a second and at the end.
func _publish() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__obsTroupe = %s" % JSON.stringify({"number": number, "t": snappedf(_t, 0.01),
		"size": snappedf(size, 0.01), "cues": stats.cues, "landings": stats.landings, "frames": stats.frames,
		"done": stats.done, "stopped": stats.stopped}), true)


# --- The spot -----------------------------------------------------------------------------------

## The cabaret spot the author asked for (2026-10-03), lit as the previs was: a follow spot on the
## lead through its moonwalk, opening onto the whole troupe as the moonwalk ends (the previs's
## reveal), back onto the lead for the held finale, out as they go. One light, so as not to add to
## the web build's: hung high in front, to the audience's left, where the robots' panels turn, below
## any gallery over the stage; its beam drawn as a faint cone, since the web build has no fog for a
## light to show in. Neither scales with the troupe's node: both are top level. In the jig it is open
## on the line from the start, and closes onto the lead for its call (the baked dance's cues).
func _make_spot() -> void:
	var flat := _xf.basis.orthonormalized()
	var up := 3.0 + 0.6 * size
	var obs: Node = _cw.get("_obs") if _cw != null else null
	var levels = obs.get("gallery_levels") if obs != null else null
	if levels is PackedFloat32Array:
		for g in levels:
			if g > _xf.origin.y + 0.5:
				up = minf(up, g - _xf.origin.y - 0.5)
	_lamp = _xf.origin + flat * (Vector3(-1.6, 0.0, 2.2) * size) + Vector3(0.0, up, 0.0)
	_spot = SpotLight3D.new()
	_spot.name = "CabaretSpot"
	_spot.top_level = true
	_spot.light_color = SPOT_COLOUR
	_spot.light_energy = 0.0
	_spot.spot_range = (_lamp - _xf.origin).length() * 1.8
	_spot.spot_attenuation = 0.6
	_spot.spot_angle_attenuation = 0.35  # a firm edge, as a follow spot's
	_spot.shadow_enabled = not _web
	add_child(_spot)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 32
	cone.rings = 1
	cone.cap_top = false
	cone.cap_bottom = false
	_beam_mat = ShaderMaterial.new()
	var sh: Shader = _beam_shader.get_ref() if _beam_shader != null else null
	if sh == null:
		sh = Shader.new()
		sh.code = BEAM_SHADER
		_beam_shader = weakref(sh)
	_beam_mat.shader = sh
	_beam = MeshInstance3D.new()
	_beam.name = "CabaretBeam"
	_beam.top_level = true
	_beam.mesh = cone
	_beam.material_override = _beam_mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)


## The spot at t: on the lead or open on all as the baked dance's cues say (the first number: opening
## onto all from 2.2 s to 3.2 s, closing back onto the lead as the finale is held), fading in at the
## start and out in the last quarter second.
func _light(t: float) -> void:
	if _spot == null:
		return
	var lead := ((_rigs[_lead] as Dictionary).root as Node3D).global_position
	var lead_aim := Vector3(lead.x, _xf.origin.y + 0.2 * size, lead.z)
	var all_aim := _xf.origin + Vector3(0.0, 0.2 * size, 0.0)
	var open := _open_at(t)
	var aim := lead_aim.lerp(all_aim, open)
	var radius := lerpf(0.42, _spot_all, open) * size
	var dist := (aim - _lamp).length()
	var half := atan(radius / dist)
	var end := duration + HOLD_EXTRA
	var k := smoothstep(0.0, 0.35, t) * (1.0 - smoothstep(end - 0.25, end, t))
	_spot.global_transform = Transform3D(Basis.looking_at(aim - _lamp, Vector3.UP), _lamp)
	_spot.spot_angle = rad_to_deg(half)
	_spot.light_energy = (WEB_SPOT_ENERGY if _web else SPOT_ENERGY) * k
	# The beam: from the lamp along the axis to the floor, as wide there as the light.
	var axis := (aim - _lamp).normalized()
	var reach := (_lamp.y - _xf.origin.y) / maxf(0.05, -axis.y)
	var floor_at := _lamp + axis * reach
	var y := -axis
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var r := reach * tan(half)
	_beam.global_transform = Transform3D(Basis(x * r, y * reach, z * r), (_lamp + floor_at) * 0.5)
	_beam_mat.set_shader_parameter("strength", 0.08 * k)


## How open the spot is at t, 0 on the lead and 1 on all: eased from each cue to the next, held
## before the first and after the last.
func _open_at(t: float) -> float:
	var k := _spot_keys
	if k.size() < 2:
		return 1.0
	if t <= k[0]:
		return k[1]
	for j in range(2, k.size() - 1, 2):
		if t <= k[j]:
			return lerpf(k[j - 1], k[j + 1], smoothstep(k[j - 2], k[j], t))
	return k[k.size() - 1]


# --- The robots ---------------------------------------------------------------------------------

func _build() -> void:
	if _mats.is_empty():  # each troupe its own: shared statics outlive the scene at exit
		# Brushed aluminium, the wand's TARS's too (scripts/tars.gd steel_material).
		_mats.steel = load(TARS_SCRIPT_PATH).call("steel_material")
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.07, 0.075, 0.08)
		dark.metallic = 0.3
		dark.roughness = 0.5
		_mats.dark = dark
		# Gold for the lead, not quite metal: at metallic 1 the web build's renderer draws it black.
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color(0.86, 0.64, 0.28)
		gold.metallic = 0.45
		gold.roughness = 0.32
		_mats.gold = gold
	var slab := BoxMesh.new()
	slab.size = Vector3(W, H, _depth)
	var groove := BoxMesh.new()
	groove.size = Vector3(W * 1.002, 0.0025, _depth * 1.004)
	var band := BoxMesh.new()
	band.size = Vector3(W * 1.004, 0.006, _depth * 1.006)
	var screen := BoxMesh.new()
	screen.size = Vector3(W * 0.82, H * 0.13, 0.002)
	var line := BoxMesh.new()
	line.size = Vector3(W * 0.6, 0.0022, 0.0006)
	var pin := CylinderMesh.new()
	pin.top_radius = 0.0055
	pin.bottom_radius = 0.0055
	pin.height = 4.0 * W + 3.0 * GAP + 0.008
	pin.radial_segments = 12
	pin.rings = 1
	for i in _n:
		var trim: Material = _mats.gold if i == _lead else _mats.dark
		var panel := _unshaded(_dim(_hues[i], 0.6))
		var feet := [_unshaded(_dim(_hues[i], 0.22)), _unshaded(_dim(_hues[i], 0.22))]
		var root := Node3D.new()
		root.name = str((_data.get_meta("names") as PackedStringArray)[i])
		add_child(root)
		var pivots: Array[Node3D] = []
		var slabs: Array[Node3D] = []
		for k in 4:
			var pivot := Node3D.new()
			pivot.position = Vector3((k - 1.5) * (W + GAP), 0.0, 0.0)
			root.add_child(pivot)
			pivots.append(pivot)
			var s := Node3D.new()
			pivot.add_child(s)
			slabs.append(s)
			_mesh(s, slab, _mats.steel, Vector3.ZERO).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			for y in [-H / 6.0, H / 6.0]:
				_mesh(s, groove, trim, Vector3(0.0, y, 0.0))
			_mesh(s, band, feet[0 if (k == 0 or k == 3) else 1], Vector3(0.0, -H * 0.5 + 0.007, 0.0))
			if k == 1 or k == 2:
				_mesh(s, screen, _mats.dark, Vector3(0.0, H * 0.33, -_depth * 0.5 - 0.001))
				for j in 3:
					var l := _mesh(s, line, panel, Vector3((j % 2) * W * 0.08 - W * 0.04, H * 0.33 + 0.012 - j * 0.012, -_depth * 0.5 - 0.0022))
					l.scale = Vector3(1.0 - 0.25 * j, 1.0, 1.0)
		_mesh(root, pin, trim, Vector3.ZERO).rotation = Vector3(0.0, 0.0, PI * 0.5)
		_rigs.append({"root": root, "pivots": pivots, "slabs": slabs, "panel": panel, "feet": feet})


## A colour darkened to k of itself, opaque.
static func _dim(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, 1.0)


static func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
