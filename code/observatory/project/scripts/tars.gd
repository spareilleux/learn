extends Node3D
## A small TARS, after the robot of Interstellar (2014): four slabs of brushed metal side by side,
## hinged together at mid-height, a lit panel on the inner two. The author asked for little TARS
## robots "that really walk" out of the wand (2026-10-02); the wand conjures them
## (scripts/curio_wheel.gd). Built here from boxes; nothing is copied.
## It walks as a compass: one pair of slabs (the outer two, or the inner two) stands on the floor
## while the other swings past it, drawn up along its length so as not to scuff; the hinge vaults over
## the planted feet. A planted foot does not slide: it is where the step that put it there ended, and
## stays until it lifts. It turns with the swinging pair, which comes round to the new heading as it
## swings while the planted pair keeps its own, so for a moment the slabs splay; turning the whole
## body on the planted feet made the outer pair's feet, 11 cm apart, scrub 2.5 cm a step. It wanders a few
## metres at a time on the floor it stands on, round the steel box, the piers, the pedestal and the
## lift, inside the shelves and the galleries' rail, and pauses; the ankh calls it home, where it is
## gone. --reduced-motion keeps the walk: it is what it is for.

const H := 0.36            # m, a slab's length, at size 1
const R := H * 0.5         # from the hinge to a foot
const W := 0.034           # a slab's width
const GAP := 0.004
const D := 0.042           # its depth
const STRIDE := 0.35       # rad, each pair's swing either side of upright: 20 degrees
const STEP_S := 0.42       # s a step takes, wandering
const HOME_STEP_S := 0.34  # and called home
const LIFT := 0.022        # m a swinging pair is drawn up, at most
const TURN := 0.45         # rad of turn at most in a step
const HOME_R := 0.55       # m from home's centre, where it is gone
const CLEAR := 0.1         # m kept from obstacles, at size 1

var size := 1.0
## Counts for tests: steps, the largest slide of a planted foot (m), arrivals.
var stats := {"steps": 0, "slide_max": 0.0, "walked": 0.0, "home": false}
var spawned_at := Vector3.ZERO
var gone := false

var _cw: Node                # the curio wheel: the walker, the lift, home, sounds
var _yaw := 0.0
var _foot := Vector3.ZERO    # the planted pair's feet, their middle
var _stance := 0             # 0: the outer pair stands, 1: the inner
var _mode := "fall"          # fall, stand, step
var _home := false
var _a0 := 0.0               # the standing pair's angle from upright at the step's start and end
var _a1 := 0.0
var _t := 0.0
var _dur := 1.0
var _yaw0 := 0.0
var _turn := 0.0
var _swing0 := 0.0           # the swinging pair's heading against the standing pair's, at the start
var _last_turn := 0.0
var _pause := 0.0
var _target := Vector3.INF
var _fall_v := 0.0
var _home_t := 0.0
var _detour := 0             # steps left going round something, home-bound
var _detour_dir := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _pivots: Array[Node3D] = []
var _slabs: Array[Node3D] = []
var _planted_at: Array[Vector3] = []  # the standing pair's feet, when they were put down
static var _mats := {}


## cw: the curio wheel. at: where the spell landed; it falls from there to the floor. facing: the
## way it looks, flat.
func configure(cw: Node, at: Vector3, facing: Vector3, s: float, seed_: int) -> void:
	_cw = cw
	size = s
	spawned_at = at
	_rng.seed = seed_
	_foot = at
	var f := Vector2(facing.x, facing.z)
	_yaw = atan2(-f.x, -f.y) if f.length() > 1e-4 else 0.0
	_build()


func _ready() -> void:
	_pose(0.0, 0.0, 0.0)


func call_home() -> void:
	_home = true
	_home_t = 0.0
	_detour = 0
	if _mode == "stand":
		_pause = 0.0


## Where each slab's foot is, in the world: the middle of its bottom edge.
func feet() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for k in 4:
		out.append(_slabs[k].global_transform * Vector3(0.0, -R, 0.0))
	return out


## 0 if the outer pair stands, 1 the inner; -1 while both do, or neither.
func planted_pair() -> int:
	return _stance if _mode == "step" else -1


## The robot's box in the world, for the Index: its transform and half size.
func bounds() -> Array:
	return [Transform3D(Basis(Vector3.UP, _yaw), _hinge(0.0) if _mode != "fall" else global_position), Vector3(2.0 * W + 1.5 * GAP, R, D) * size]


func _process(delta: float) -> void:
	if gone:
		return
	if _home:
		_home_t += delta
		if _home_t > 20.0:
			_vanish()
			return
	match _mode:
		"fall":
			_fall_v += 9.8 * delta
			var floor_y := _floor_at(_foot, _foot.y + 0.05)
			_foot.y -= _fall_v * delta
			if _foot.y <= floor_y:
				_foot.y = floor_y
				_land_on_floor()
			_pose(0.0, 0.0, 0.0)
		"stand":
			_pause -= delta
			_pose(0.0, 0.0, 0.0)
			if _pause <= 0.0:
				_next(0.0)
		"step":
			_t += delta / _dur
			if _t >= 1.0:
				_end_step()
			else:
				_pose_step()


func _land_on_floor() -> void:
	var p := _clear_of(Vector2(_foot.x, _foot.z))
	_foot = Vector3(p.x, _foot.y, p.y)
	_mode = "stand"
	_pause = 0.6
	_cw.call("_sound_at", "clank", _foot, 0.8)


# --- Steps --------------------------------------------------------------------------------------

## The next step from a standing pose (a0 = 0) or from mid-walk (a0 = -STRIDE): towards the target,
## a new one when there is none or it is reached, a closing step when the way is blocked.
func _next(a0: float) -> void:
	if _home:
		var h: Vector3 = _cw.call("_home")
		if Vector2(h.x - _foot.x, h.z - _foot.z).length() < HOME_R * maxf(1.0, size):
			_vanish()
			return
		_target = h
		if _detour > 0:
			_target = _foot + _detour_dir * 2.0
	elif _target == Vector3.INF or _flat_dist(_target) < 2.0 * R * sin(STRIDE) * size:
		if a0 != 0.0:
			_start(a0, 0.0)  # arrived: feet together
			return
		_target = _wander_target()
		if _target == Vector3.INF:
			_mode = "stand"
			_pause = 1.5
			return
	var want := atan2(-(_target.x - _foot.x), -(_target.z - _foot.z))
	var turn := clampf(wrapf(want - _yaw, -PI, PI), -TURN, TURN)
	var a1 := STRIDE
	var yaw1 := _yaw + turn
	var land := _foot + (Vector3(-sin(_yaw), 0.0, -cos(_yaw)) + Vector3(-sin(yaw1), 0.0, -cos(yaw1))) * (R * size * sin(a1))
	if not _ok(land):
		if a0 != 0.0:
			_start(a0, 0.0)  # blocked: feet together, then think again
		else:
			_blocked()
		return
	_start(a0, a1, turn)


func _start(a0: float, a1: float, turn := 0.0) -> void:
	_a0 = a0
	_a1 = a1
	_t = 0.0
	_dur = (HOME_STEP_S if _home else STEP_S) * absf(a1 - a0) / (2.0 * STRIDE) * sqrt(size)
	_yaw0 = _yaw
	_turn = turn
	# Mid-walk, the pair about to swing still has the heading it stood on, the last turn behind.
	_swing0 = -_last_turn if a0 != 0.0 else 0.0
	_mode = "step"
	_planted_at = _stance_feet()


func _end_step() -> void:
	_t = 1.0
	_pose_step()
	var landed := _swing_foot()
	_check_planted()
	stats.walked = float(stats.walked) + Vector2(landed.x - _foot.x, landed.z - _foot.z).length()
	_yaw = _yaw0 + _turn  # the pair that swung, now standing
	_last_turn = _turn
	_foot = Vector3(landed.x, _floor_at(landed, _foot.y + 0.1 * size), landed.z)
	stats.steps = int(stats.steps) + 1
	if _cw.has_method("_sound_at") and _near_camera():
		_cw.call("_sound_at", "clank", _foot, 0.35)
	if _detour > 0:
		_detour -= 1
	if _a1 == 0.0:
		# Feet together: the pair that swung stands beside the other, upright.
		_mode = "stand"
		_pause = 0.0 if _home else _rng.randf_range(0.8, 2.4)
		_stance = 1 - _stance
		_pose(0.0, 0.0, 0.0)
		return
	_stance = 1 - _stance
	_next(-STRIDE)


## In the way: on the way home, a few steps aside; wandering, somewhere else.
func _blocked() -> void:
	if _home:
		var to := (_target - _foot)
		to.y = 0.0
		var side := Vector3(-to.z, 0.0, to.x).normalized() * (1.0 if _rng.randf() < 0.5 else -1.0)
		_detour = 4
		_detour_dir = side
		_target = _foot + side * 2.0
	else:
		_target = _wander_target()
	_mode = "stand"
	_pause = 0.3


func _vanish() -> void:
	gone = true
	stats.home = true
	_cw.call("_tars_home", self)


# --- Pose ---------------------------------------------------------------------------------------

## A step's pose at _t: the standing pair's angle from a0 to a1, the swinging pair's its opposite,
## drawn up in the middle of its swing and coming round from its old heading to the new one.
func _pose_step() -> void:
	var e := _t * _t * (3.0 - 2.0 * _t) * 0.35 + _t * 0.65  # a little slower at both ends
	var a := lerpf(_a0, _a1, e)
	_pose(a, -a, LIFT * sin(PI * _t) * (1.0 if _a0 != _a1 else 0.0), lerpf(_swing0, _turn, e))
	_check_planted()


## The hinge over the planted feet with the standing pair at angle a from upright (forward
## positive), the swinging pair at b, drawn up by lift and turned by swing_yaw about the hinge.
func _pose(a: float, b: float, lift: float, swing_yaw := 0.0) -> void:
	global_transform = Transform3D(Basis(Vector3.UP, _yaw).scaled(Vector3.ONE * size), _hinge(a))
	for k in 4:
		var stands := (k == 0 or k == 3) == (_stance == 0)
		var y := 0.0 if stands else swing_yaw
		_pivots[k].position = Basis(Vector3.UP, y) * Vector3((k - 1.5) * (W + GAP), 0.0, 0.0)
		_pivots[k].rotation = Vector3(-(a if stands else b), y, 0.0)
		_slabs[k].position = Vector3(0.0, 0.0 if stands else lift, 0.0)


func _hinge(a: float) -> Vector3:
	var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	return _foot + (fwd * sin(a) + Vector3.UP * cos(a)) * R * size


func _swing_foot() -> Vector3:
	var k := 1 if _stance == 0 else 0
	return _slabs[k].global_transform * Vector3(0.0, -R - _slabs[k].position.y, 0.0) \
		+ (_slabs[3 - k].global_transform * Vector3(0.0, -R - _slabs[3 - k].position.y, 0.0) - _slabs[k].global_transform * Vector3(0.0, -R - _slabs[k].position.y, 0.0)) * 0.5


func _stance_feet() -> Array[Vector3]:
	var all := feet()
	# Two returns, not a ternary: a ternary of two literals is an untyped Array, refused at runtime.
	if _stance == 0:
		return [all[0], all[3]]
	return [all[1], all[2]]


## How far the standing pair's feet have moved since they were put down: nothing, if it walks.
func _check_planted() -> void:
	if _planted_at.size() != 2:
		return
	var now := _stance_feet()
	for i in 2:
		stats.slide_max = maxf(float(stats.slide_max), now[i].distance_to(_planted_at[i]))


# --- Where it may go -----------------------------------------------------------------------------

func _walker() -> Node:
	return _cw.call("_walker")


func _floor_at(p: Vector3, top: float) -> float:
	var w := _walker()
	if w == null or not w.has_method("_support"):
		return 0.0
	return float(w.call("_support", Vector2(p.x, p.z), top))


## Whether a planted foot may go to p: on the same floor, near enough in height, clear of the
## obstacles and the lift, inside the shelves and, on a gallery, outside its rail.
func _ok(p: Vector3) -> bool:
	var w := _walker()
	if w == null:
		return true
	if w.get("region") != null:
		return false  # the corridor's walls are its own: it stays put there
	var flat := Vector2(p.x, p.z)
	var m := CLEAR * size + (2.0 * W + 1.5 * GAP) * size
	var r := flat.length()
	if r > 17.14 - m:
		return false
	var floor_y := _floor_at(p, _foot.y + 0.1 * size)
	if absf(floor_y - _foot.y) > 0.08 * size:
		return false
	if _foot.y > 1.0 and _foot.y < 20.0 and r < 13.78 + m:
		return false  # a gallery's rail
	var obs := _cw.get("_obs") as Node
	var lift: Node = obs.get_node_or_null("Lift") if obs != null else null
	if lift != null and lift.has_method("in_shaft"):
		for o in [Vector2.ZERO, Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
			if bool(lift.call("in_shaft", flat + o)):
				return false
	if _foot.y < 1.0 and w.has_method("_boxes"):
		for b: Array in w.call("_boxes", flat):
			var d: Vector2 = flat - (b[0] as Vector2)
			var h: Vector2 = b[3]
			if absf(d.dot(b[1])) < h.x + m and absf(d.dot(b[2])) < h.y + m:
				return false
	return true


## Out of any obstacle it fell into, by the nearest side.
func _clear_of(p: Vector2) -> Vector2:
	var w := _walker()
	var r := p.length()
	var m := CLEAR * size + 0.08 * size
	if r > 17.14 - m:
		p = p.normalized() * (17.14 - m)
	if w != null and w.has_method("_boxes") and _foot.y < 1.0:
		for b: Array in w.call("_boxes", p):
			var c: Vector2 = b[0]
			var u: Vector2 = b[1]
			var v: Vector2 = b[2]
			var h: Vector2 = b[3]
			var local := Vector2((p - c).dot(u), (p - c).dot(v))
			if absf(local.x) < h.x + m and absf(local.y) < h.y + m:
				var pen := h + Vector2(m, m) - local.abs()
				if pen.x < pen.y:
					local.x = (h.x + m) * signf(local.x if local.x != 0.0 else 1.0)
				else:
					local.y = (h.y + m) * signf(local.y if local.y != 0.0 else 1.0)
				p = c + u * local.x + v * local.y
	return p


## Somewhere one to three metres off on its floor that it may stand on, or INF.
func _wander_target() -> Vector3:
	for i in 12:
		var a := _yaw + _rng.randf_range(-1.6, 1.6)
		var d := _rng.randf_range(1.0, 3.0) * sqrt(size)
		var p := _foot + Vector3(-sin(a), 0.0, -cos(a)) * d
		if _ok(p) and _ok(_foot.lerp(p, 0.5)):
			return p
	return Vector3.INF


func _flat_dist(p: Vector3) -> float:
	return Vector2(p.x - _foot.x, p.z - _foot.z).length()


func _near_camera() -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(_foot) < 10.0


# --- The model ------------------------------------------------------------------------------------

func _build() -> void:
	name = "Tars"
	if _mats.is_empty():
		_mats.steel = steel_material()
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.07, 0.075, 0.08)
		dark.metallic = 0.6
		dark.roughness = 0.5
		_mats.dark = dark
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = Color(0.62, 0.92, 1.0)
		_mats.glow = glow
	var slab := BoxMesh.new()
	slab.size = Vector3(W, H, D)
	var groove := BoxMesh.new()
	groove.size = Vector3(W * 1.002, 0.0025, D * 1.004)
	var screen := BoxMesh.new()
	screen.size = Vector3(W * 0.82, H * 0.13, 0.002)
	var line := BoxMesh.new()
	line.size = Vector3(W * 0.6, 0.0022, 0.0006)
	for k in 4:
		var pivot := Node3D.new()
		pivot.name = "Pivot%d" % k
		pivot.position = Vector3((k - 1.5) * (W + GAP), 0.0, 0.0)
		add_child(pivot)
		_pivots.append(pivot)
		var s := Node3D.new()
		s.name = "Slab"
		pivot.add_child(s)
		_slabs.append(s)
		# The slabs cast a shadow, so that it stands on the marble; the small parts do not.
		_mesh(s, slab, _mats.steel, Vector3.ZERO).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# Its joints, as the film's: grooves across the slab at a third and two thirds.
		for y in [-H / 6.0, H / 6.0]:
			_mesh(s, groove, _mats.dark, Vector3(0.0, y, 0.0))
		if k == 1 or k == 2:
			# The panel high on the inner pair, and its lines of text, lit.
			_mesh(s, screen, _mats.dark, Vector3(0.0, H * 0.33, -D * 0.5 - 0.001))
			for j in 3:
				var l := _mesh(s, line, _mats.glow, Vector3((j % 2) * W * 0.08 - W * 0.04, H * 0.33 + 0.012 - j * 0.012, -D * 0.5 - 0.0022))
				l.scale = Vector3(1.0 - 0.25 * j, 1.0, 1.0)
	var pin := CylinderMesh.new()
	pin.top_radius = 0.0055
	pin.bottom_radius = 0.0055
	pin.height = 4.0 * W + 3.0 * GAP + 0.008
	pin.radial_segments = 12
	pin.rings = 1
	var p := _mesh(self, pin, _mats.dark, Vector3.ZERO)
	p.rotation = Vector3(0.0, 0.0, PI * 0.5)


## Brushed aluminium, as the film's TARS, this one's and the whistle's troupe's
## (scripts/tars_ensemble.gd): mostly a light grey lit by the hall, a little metal. At metallic 0.85,
## this TARS's until version 38, it mirrored the gilt hall into copper under Forward+ and went near
## black in the web build's renderer (artpass/tarsdance/NOTES.md). There a neutral grey: a warmer one,
## as the steel box's against the cool keys, went beige under the troupe's warm spot. Under Forward+
## the light on the hall's floor is warm enough (the shelves' bounce, the gilt) that a grey albedo
## came out brown, (69, 41, 37) on the screen against the steel box's (59, 59, 68): a cooler albedo
## and a faint neutral glow bring it back to grey.
static func steel_material() -> StandardMaterial3D:
	var web := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.63, 0.64, 0.66) if web else Color(0.42, 0.52, 0.68)
	steel.metallic = 0.25 if web else 0.3
	steel.roughness = 0.42
	steel.albedo_texture = _brushed()
	if not web:
		steel.emission_enabled = true
		steel.emission = Color(0.55, 0.58, 0.62)
		steel.emission_energy_multiplier = 0.06
	return steel


## Fine streaks along a slab's length, light and dark by a few per cent: the brushing. A slab's
## faces map their length onto v, so the noise is stretched along v.
static func _brushed() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = 1977
	noise.frequency = 0.05
	noise.fractal_octaves = 3
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.92, 0.92, 0.92))
	ramp.set_color(1, Color(1, 1, 1))
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 16
	tex.seamless = true
	tex.noise = noise
	tex.color_ramp = ramp
	return tex


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
