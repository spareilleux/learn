extends Node3D
## Dice and dominoes, with real physics. The author, 2026-10-16: « mitraillette double en plastique, mais
## celle-là qui lance des dés ... comme des dés octogonaux ou hexagonaux ou dés à 12 faces ... pouvoir en
## balancer plein et les voir rouler », and « avec le gun, créer des genres de trucs de dominos ... des trucs
## complexes ... des trucs géants, et pouvoir les voir avec la physique des dominos qui tombent les uns sur
## les autres ».
## Made by scripts/duck_gun.gd for its modes 3 (two dice guns) and 4 (the domino layer). Godot's rigid
## bodies (on Jolt, project.godot) over static shapes of what they meet: in the hall its floor, its shelves'
## front, the galleries' walkways and rails, the colonnade's arches, the ceiling, the piers and their
## plinths, the pedestals, the steel box and the lift's shaft; outside the hall's facade, drum and roof,
## the terrace, the ramp, the gardens' ground and what stands on it (the riders' solids, palace_gardens.gd
## _solids, up to SOLID_H); the library wings (library_wing.gd toy_boxes). The shelves' and the facade's
## rings stop below the head of each bay the gardens open (the meta open_bays): the French doors, whose
## leaves are bodies that follow them as they swing, and the wings' portals. A body follows the visitor on
## foot or riding, which knocks the toys it meets. Not yet: the orrery, high under the oculus.
## The dice: d6 (pips), d8, d12, d20 (numbers, 6 and 9 underlined), opposite faces summing to one more than
## the faces, in bright plastic. Their shapes, numbers and pips, the dominoes and the sounds are made here.

const STATIC_LAYER := 2
const TOY_LAYER := 4
const VISITOR_LAYER := 8           # the visitor's body (_follow_visitor): the toys meet it, aim and support do not
const KINDS := ["d6", "d8", "d12", "d20"]
const DIE_R := 0.07                 # m from a die's centre to its corners: a d6 8 cm, a toy's; at 0.05 they were specks on the hall's floor
const DIE_MASS := 0.12              # kg
const DIE_COLOURS := [Color(0.86, 0.08, 0.1), Color(0.08, 0.3, 0.92), Color(0.06, 0.62, 0.28), Color(1.0, 0.8, 0.06),
	Color(0.56, 0.18, 0.82), Color(1.0, 0.42, 0.04), Color(0.95, 0.95, 0.92), Color(0.06, 0.06, 0.07)]
const MAX_DICE := 400
const MAX_DOMINOES := 2000
const DOMINO := Vector3(0.5, 1.0, 0.16)  # its width, height and thickness, to its height
const DOMINO_DENSITY := 650.0       # kg/m³, a plastic-skinned tile
const GAP := 0.55                   # m between two dominoes' centres, to the nearer one's height
const GROW := 1.15                  # each domino of a growing line to the one before
const GROW_MAX := 8.0               # m, the tallest of a growing line
const KILL_Y := -60.0               # m: a toy fallen under this is gone
const SOLID_H := 1.6                # m: the gardens' solids, as standing shapes
const CLACK_RATE := 30.0            # clacks a second at most, all toys

var stats := {"dice": 0, "dominoes": 0, "thrown": 0, "laid": 0, "pushed": 0, "fallen": 0, "clacks": 0, "shapes": 0,
	"solids": 0, "undone": 0, "cleared": 0, "awake": 0}
var _obs: Node3D
var _static: StaticBody3D
var _dice: Array[RigidBody3D] = []
var _dominoes: Array[RigidBody3D] = []
var _strokes: Array = []            # each a line of dominoes laid in one hold of the button
var _die_kit := {}                  # kind -> {"shape", "faces": [{"n", "value"}], "meshes": [one per colour]}
var _domino_mesh: BoxMesh
var _domino_mats: Array[StandardMaterial3D] = []
var _box_shapes := {}               # size, rounded to the mm -> BoxShape3D
var _die_phys: PhysicsMaterial
var _domino_phys: PhysicsMaterial
var _ghost: MeshInstance3D
var _ghost_mat: StandardMaterial3D
var _players: Array[AudioStreamPlayer3D] = []
var _next_player := 0
var _sounds := {}
var _clack_budget := 0.0
var _rng := RandomNumberGenerator.new()
var _hue := 0
var _down := {}                     # the dominoes fallen, by instance id
var _leaves: Array = []             # [body, the door leaf it follows, the body's place in the leaf's frame]
var _visitor: AnimatableBody3D      # follows the visitor on foot or riding (_follow_visitor)
var _visitor_at := Vector3.INF


func setup(obs: Node3D) -> void:
	_obs = obs
	_rng.seed = 20261016
	_die_phys = PhysicsMaterial.new()
	_die_phys.friction = 0.45
	_die_phys.bounce = 0.32
	_domino_phys = PhysicsMaterial.new()
	_domino_phys.friction = 0.45
	_domino_phys.bounce = 0.04
	var t0 := Time.get_ticks_usec()
	_build_static()
	var t1 := Time.get_ticks_usec()
	for kind: String in KINDS:
		_die_kit[kind] = _make_die(kind)
	stats.static_ms = snappedf(float(t1 - t0) / 1000.0, 0.1)
	stats.dice_ms = snappedf(float(Time.get_ticks_usec() - t1) / 1000.0, 0.1)
	_domino_mesh = BoxMesh.new()
	_domino_mesh.size = Vector3.ONE
	for k in 12:
		_domino_mats.append(_plastic(Color.from_hsv(float(k) / 12.0, 0.82, 0.95), 0.3))
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.3)
	_ghost_mat.no_depth_test = false
	_ghost = MeshInstance3D.new()
	_ghost.name = "DominoGhost"
	_ghost.mesh = _domino_mesh
	_ghost.material_override = _ghost_mat
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.visible = false
	add_child(_ghost)
	_make_sounds()


# --- What the toys meet --------------------------------------------------------------------------

func _hall(key: String, fallback: float) -> float:
	var v: Variant = _obs.get(key) if _obs != null else null
	return float(v) if v != null else fallback


func _build_static() -> void:
	_static = StaticBody3D.new()
	_static.name = "ToyGround"
	_static.collision_layer = STATIC_LAYER
	_static.collision_mask = 0
	var ground := PhysicsMaterial.new()
	ground.friction = 0.7
	ground.bounce = 0.2
	_static.physics_material_override = ground
	var outer := _hall("outer_radius", 18.0)
	var face := outer + 0.65
	var ceil_y := _hall("_ceiling_y", 20.5)
	var ocu := _hall("oculus_radius", 10.0)
	var col := _hall("colonnade_radius", 13.0)
	var spring := _hall("column_height", 19.0) - 2.9
	var shelf := 17.15
	var g_in := col + 0.78
	# The hall's floor, out to its facade, and the ground's plane under everything else.
	var floor_shape := CylinderShape3D.new()
	floor_shape.radius = face
	floor_shape.height = 10.0
	_add_shape(floor_shape, Transform3D(Basis.IDENTITY, Vector3(0.0, -5.0, 0.0)))
	var gardens := _obs.get_node_or_null("PalaceGardens") if _obs != null else null
	var gc: Dictionary = (gardens.get_script() as Script).get_script_constant_map() if gardens != null else {}
	var ground_y := float(gc.get("GROUND_Y", -10.0))
	# The plane on a body of its own (Jolt takes no world boundary within a compound of shapes), the body at
	# the ground's height and the plane through it: Plane(UP, -10) stood at +10 m under Jolt, the whole hall
	# inside its solid half (artpass/curios/toytest.gd, 2026-10-16), at -10 m under Godot's own physics.
	var plane_body := StaticBody3D.new()
	plane_body.name = "ToyGroundPlane"
	plane_body.collision_layer = STATIC_LAYER
	plane_body.collision_mask = 0
	plane_body.physics_material_override = ground
	plane_body.position = Vector3(0.0, ground_y, 0.0)
	var plane := WorldBoundaryShape3D.new()
	plane.plane = Plane(Vector3.UP, 0.0)
	var plane_owner := plane_body.create_shape_owner(plane_body)
	plane_body.shape_owner_add_shape(plane_owner, plane)
	add_child(plane_body)
	if gardens != null:
		# The terrace, the half disc on the gardens' side at the hall's floor (ground_at), and the ramp down.
		var z0 := float(gc.get("RAMP_Z0", 60.0))
		var z1 := float(gc.get("RAMP_Z1", 100.0))
		var half := float(gc.get("RAMP_HALF", 5.5)) + 0.4
		var terrace := PackedVector3Array()
		for k in 49:
			var a := PI * float(k) / 48.0
			terrace.append(Vector3(cos(a) * z0, 0.0, sin(a) * z0))
			terrace.append(Vector3(cos(a) * z0, ground_y, sin(a) * z0))
		var t_shape := ConvexPolygonShape3D.new()
		t_shape.points = terrace
		_add_shape(t_shape, Transform3D.IDENTITY)
		var ramp := ConvexPolygonShape3D.new()
		ramp.points = PackedVector3Array([Vector3(-half, 0.0, z0 - 0.6), Vector3(half, 0.0, z0 - 0.6), Vector3(-half, ground_y, z0 - 0.6),
			Vector3(half, ground_y, z0 - 0.6), Vector3(-half, ground_y, z1), Vector3(half, ground_y, z1), Vector3(-half, 0.0, z0), Vector3(half, 0.0, z0)])
		_add_shape(ramp, Transform3D.IDENTITY)
		_solids(gardens)
		_doors(gardens)
	var wing := _obs.get_node_or_null("LibraryWing") if _obs != null else null
	if wing != null and wing.has_method("toy_boxes"):
		for b: Array in wing.call("toy_boxes"):
			_add_shape(_box(b[1]), b[0])
			stats.wing_boxes = int(stats.get("wing_boxes", 0)) + 1
	# The bays the gardens opened (palace_gardens.gd _open_bays): [their middle's angle, the opening's half width,
	# its head], the French doors' head their transom, the wings' portals' the walkway's underside.
	var gaps := []
	var open: Array = _obs.get_meta("open_bays", []) if _obs != null else []
	if gardens != null:
		var glazed: Array = gc.get("BAYS", [])
		for i: int in open:
			gaps.append([TAU * (i + 0.5) / _hall("bay_count", 16.0), float(gc.get("OPEN_W", 4.4)) * 0.5,
				float(gc.get("TRANSOM", 4.0)) if i in glazed else float(gc.get("HEAD", 5.15))])
	stats.gaps = gaps.size()
	# The shelves' front, up past the ceiling; outside, the facade, the roof's lead and the drum round the oculus.
	_ring(shelf, shelf + 0.6, 0.0, ceil_y + 0.6, 192, gaps)
	_ring(face - 0.6, face, 0.0, 21.2, 192, gaps)
	_ring(ocu + 1.2, 19.3, 21.0, 21.6)
	_ring(ocu, ocu + 1.2, ceil_y, ceil_y + 4.7)
	_ring(ocu, shelf, ceil_y, ceil_y + 0.6)
	# The galleries: each walkway and its gilded edge, 0.62 m deep, and its rail.
	var levels: Variant = _obs.get("gallery_levels") if _obs != null else null
	if levels is PackedFloat32Array:
		for g: float in (levels as PackedFloat32Array):
			_ring(g_in - 0.3, shelf, g - 0.62, g)
			_ring(g_in - 0.04, g_in + 0.04, g, g + 1.07)
	# The colonnade's capitals, arches and entablature.
	_ring(col - 1.0, col + 1.0, spring - 0.75, ceil_y)
	# The piers and their plinths, the pedestals, the steel box, as boxes.
	if _obs != null:
		for n in _obs.find_children("*", "MeshInstance3D", true, false):
			var m := n as MeshInstance3D
			var id := String(m.name)
			if m.mesh == null or not (id == "Pedestal" or (id.begins_with("Pier") and id.trim_prefix("Pier").is_valid_int())
					or (id.begins_with("Plinth") and id.trim_prefix("Plinth").is_valid_int())):
				continue
			var xf := m.global_transform
			var bb := m.mesh.get_aabb()
			var size := bb.size * xf.basis.get_scale()
			_add_shape(_box(size), Transform3D(xf.basis.orthonormalized(), xf * bb.get_center()))
		var steel := _obs.get_node_or_null("SteelCube") as Node3D
		if steel != null:
			var s: Vector3 = steel.get("box_size")
			_add_shape(_box(s), Transform3D(Basis.IDENTITY, steel.global_position + Vector3(0.0, s.y * 0.5, 0.0)))
		var lift := _obs.get_node_or_null("Lift")
		if lift != null and lift.get_script() != null:
			var c: Dictionary = (lift.get_script() as Script).get_script_constant_map()
			var a := TAU * (float(c.get("LIFT_BAY", 3)) + 0.5) / _hall("bay_count", 16.0)
			var at := Vector2(cos(a), sin(a)) * float(c.get("AXIS_R", 16.1))
			var shaft := CylinderShape3D.new()
			shaft.radius = 1.25
			shaft.height = ceil_y
			_add_shape(shaft, Transform3D(Basis.IDENTITY, Vector3(at.x, ceil_y * 0.5, at.y)))
	# Into the tree once every shape is on it: in the tree, each shape added rebuilt the whole body, 11 s for
	# its 8595 shapes under Jolt (2026-10-16).
	add_child(_static)


## The gardens' solids (the riders', palace_gardens.gd _solids) standing SOLID_H over their ground: posts,
## lamps, statues, trees, hedges and the maze's walls. The great ones (a basin, the canal, the forecourt) are
## water or paving, not walls: left out.
func _solids(gardens: Node) -> void:
	var seen := {}
	var all: Dictionary = gardens.get("_solids")
	for cell: Vector2i in all:
		for s: Vector4 in all[cell]:
			if seen.has(s):
				continue
			seen[s] = true
			var c := Vector2(s.x, s.y)
			var y := float(gardens.call("ground_at", c))
			if s.w < 0.0:
				if s.z > 3.0:
					continue
				var cyl := CylinderShape3D.new()
				cyl.radius = s.z
				cyl.height = SOLID_H
				_add_shape(cyl, Transform3D(Basis.IDENTITY, Vector3(c.x, y + SOLID_H * 0.5, c.y)))
			else:
				if minf(s.z, s.w) > 0.8 and maxf(s.z, s.w) > 3.0:
					continue
				_add_shape(_box(Vector3(s.z * 2.0, SOLID_H, s.w * 2.0)), Transform3D(Basis.IDENTITY, Vector3(c.x, y + SOLID_H * 0.5, c.y)))
			stats.solids += 1


## A ring of n boxes from radius r0 to r1, height y0 to y1, round the hall's axis. A box whose middle is in one
## of the openings ([angle, half width in metres, head], _build_static) starts at the opening's head instead.
func _ring(r0: float, r1: float, y0: float, y1: float, n := 64, gaps := []) -> void:
	var width := 2.0 * r1 * sin(PI / n) + 0.05
	var r := (r0 + r1) * 0.5
	for k in n:
		var a := TAU * (float(k) + 0.5) / n
		var lo := y0
		for g: Array in gaps:
			if absf(angle_difference(a, float(g[0]))) * r < float(g[1]):
				lo = maxf(lo, float(g[2]))
		if lo >= y1:
			continue
		var radial := Vector3(cos(a), 0.0, sin(a))
		var tangent := Vector3(-sin(a), 0.0, cos(a))
		var at := radial * r + Vector3(0.0, (lo + y1) * 0.5, 0.0)
		_add_shape(_box(Vector3(width, y1 - lo, r1 - r0)), Transform3D(Basis(tangent, Vector3.UP, -radial), at))


## The French doors' leaves (palace_gardens.gd _build_doors), each a body that follows its leaf as it swings
## (_physics_process): 6 cm thick, from the sill to the transom, from its hinge to the middle. Under them, the sill
## across the opening, from the floor: without it a rolling die went out under the leaves (toytest.gd, 2026-10-16).
func _doors(gardens: Node) -> void:
	var gc: Dictionary = (gardens.get_script() as Script).get_script_constant_map()
	var sill := float(gc.get("SILL", 0.15))
	var top := float(gc.get("TRANSOM", 4.0)) - 0.05
	var glass_z := float(gc.get("GLASS_Z", 0.0))
	for door: Variant in gardens.get("_doors"):
		var leaves: Array = (door as Dictionary).get("leaves", [])
		if leaves.is_empty():
			continue
		# The door's frame is in the leaves' parent's space (the gardens' node).
		var f: Transform3D = (leaves[0] as Node3D).get_parent().global_transform * ((door as Dictionary).get("frame", Transform3D()) as Transform3D)
		_add_shape(_box(Vector3(float(gc.get("OPEN_W", 4.4)), sill, 0.3)), f * Transform3D(Basis.IDENTITY, Vector3(0.0, sill * 0.5, glass_z)))
		stats.sills = int(stats.get("sills", 0)) + 1
		for leaf: Node3D in (door as Dictionary).get("leaves", []):
			var side := float(leaf.get_meta("side", 1.0))
			var w := float(leaf.get_meta("width", 2.1))
			var body := AnimatableBody3D.new()
			body.name = "ToyDoor"
			body.collision_layer = STATIC_LAYER
			body.collision_mask = 0
			body.sync_to_physics = false
			var owner := body.create_shape_owner(body)
			body.shape_owner_add_shape(owner, _box(Vector3(w, top - sill, 0.12)))
			add_child(body)
			var offset := Transform3D(Basis.IDENTITY, Vector3(-side * w * 0.5, (sill + top) * 0.5, 0.0))
			body.global_transform = leaf.global_transform * offset
			_leaves.append([body, leaf, offset])
	stats.door_leaves = _leaves.size()


## The visitor as a body in the toys' way: a capsule 0.3 m round from the feet to the eye, on foot (the hall's
## walking body, the gardens' walk) or riding; out of the way while flying or at a view. A jump of more than a
## metre in a step (the telescope's, a preset) carries it there with its collisions off for that step, so that it
## sweeps nothing on the way.
func _follow_visitor() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var walk := _obs.get_node_or_null("WalkBody") if _obs != null else null
	var seg := _obs.get_node_or_null("Segway") if _obs != null else null
	var on := cam != null and ((walk != null and walk.has_method("is_walking") and bool(walk.call("is_walking")))
		or (seg != null and (bool(seg.get("riding")) or bool(seg.get("on_foot")))))
	if _visitor == null:
		_visitor = AnimatableBody3D.new()
		_visitor.name = "ToyVisitor"
		_visitor.collision_mask = 0
		_visitor.sync_to_physics = false
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.3
		capsule.height = 1.7
		var owner := _visitor.create_shape_owner(_visitor)
		_visitor.shape_owner_add_shape(owner, capsule)
		add_child(_visitor)
	if not on:
		_visitor.collision_layer = 0
		_visitor_at = Vector3.INF
		return
	var at := cam.global_position - Vector3(0.0, 0.85, 0.0)
	_visitor.collision_layer = VISITOR_LAYER if _visitor_at != Vector3.INF and _visitor_at.distance_to(at) < 1.0 else 0
	_visitor.global_position = at
	_visitor_at = at


func _add_shape(shape: Shape3D, xf: Transform3D) -> void:
	var owner := _static.create_shape_owner(_static)
	_static.shape_owner_add_shape(owner, shape)
	_static.shape_owner_set_transform(owner, xf)
	stats.shapes += 1


func _box(size: Vector3) -> BoxShape3D:
	var key := Vector3i(roundi(size.x * 1000.0), roundi(size.y * 1000.0), roundi(size.z * 1000.0))
	if not _box_shapes.has(key):
		var b := BoxShape3D.new()
		b.size = size
		_box_shapes[key] = b
	return _box_shapes[key]


# --- Dice ----------------------------------------------------------------------------------------

## A die of `kind` (or one of KINDS at random) from `at`, going at v, turning as it leaves.
func throw_die(at: Vector3, v: Vector3, kind := "", colour := -1) -> RigidBody3D:
	if kind == "":
		kind = KINDS[_rng.randi_range(0, KINDS.size() - 1)]
	if colour < 0:
		colour = _rng.randi_range(0, DIE_COLOURS.size() - 1)
	var kit: Dictionary = _die_kit[kind]
	var body := RigidBody3D.new()
	body.name = "Die"
	body.collision_layer = TOY_LAYER
	body.collision_mask = STATIC_LAYER | TOY_LAYER | VISITOR_LAYER
	body.mass = DIE_MASS
	body.continuous_cd = true
	body.physics_material_override = _die_phys
	body.angular_damp = 0.4
	body.set_meta("kind", kind)
	var owner := body.create_shape_owner(body)
	body.shape_owner_add_shape(owner, kit.shape)
	var mi := MeshInstance3D.new()
	mi.mesh = (kit.meshes as Array)[colour % (kit.meshes as Array).size()]
	body.add_child(mi)
	add_child(body)
	body.global_transform = Transform3D(Basis(Quaternion.from_euler(Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU))), at)
	body.linear_velocity = v
	body.angular_velocity = Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * 18.0
	_dice.append(body)
	stats.thrown += 1
	while _dice.size() > MAX_DICE:
		var old: RigidBody3D = _dice.pop_front()
		old.queue_free()
	stats.dice = _dice.size()
	return body


## The value on a die's top face, or 0 for something that is not one of these dice.
func top_face(die: RigidBody3D) -> int:
	if not is_instance_valid(die) or not die.has_meta("kind"):
		return 0
	var kit: Dictionary = _die_kit[str(die.get_meta("kind"))]
	var best := -2.0
	var value := 0
	for f: Dictionary in kit.faces:
		var up := (die.global_basis * (f.n as Vector3)).y
		if up > best:
			best = up
			value = int(f.value)
	return value


func dice() -> Array[RigidBody3D]:
	return _dice


## Every die taken away, the dominoes left standing.
func clear_dice() -> void:
	for d in _dice:
		if is_instance_valid(d):
			d.queue_free()
	stats.cleared += _dice.size()
	_dice.clear()
	stats.dice = 0


## A die's mesh, its pips or numbers on it: for the dice guns' hoppers (duck_gun.gd).
func die_mesh(kind: String, colour: int) -> Mesh:
	var meshes: Array = (_die_kit[kind] as Dictionary).meshes
	return meshes[colour % meshes.size()]


## A polyhedron of circumradius 1: its corners, and its faces as rings of corners, counter-clockwise seen from
## outside, each face's normal the dual's corner.
static func polyhedron(kind: String) -> Dictionary:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var cube: Array[Vector3] = []
	for x: float in [-1.0, 1.0]:
		for y: float in [-1.0, 1.0]:
			for z: float in [-1.0, 1.0]:
				cube.append(Vector3(x, y, z))
	var octa: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	var icosa: Array[Vector3] = []
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			icosa.append(Vector3(0.0, a, b * phi))
			icosa.append(Vector3(a, b * phi, 0.0))
			icosa.append(Vector3(b * phi, 0.0, a))
	# The dodecahedron as the icosahedron's dual: a corner over each of its triangles (corners 2 apart), so
	# that each is the other's faces' normals. Written out with coordinates of its own, it was turned the
	# other way: the d12's faces came out single corners.
	var dodeca: Array[Vector3] = []
	for i in icosa.size():
		for j in range(i + 1, icosa.size()):
			for k in range(j + 1, icosa.size()):
				if absf(icosa[i].distance_to(icosa[j]) - 2.0) < 1e-3 and absf(icosa[j].distance_to(icosa[k]) - 2.0) < 1e-3 \
						and absf(icosa[i].distance_to(icosa[k]) - 2.0) < 1e-3:
					dodeca.append(icosa[i] + icosa[j] + icosa[k])
	var pick := {"d6": [cube, octa], "d8": [octa, cube], "d12": [dodeca, icosa], "d20": [icosa, dodeca]}
	var verts := PackedVector3Array()
	for v: Vector3 in (pick[kind][0] as Array):
		verts.append(v.normalized())
	var faces: Array = []
	for nv: Vector3 in (pick[kind][1] as Array):
		var n := nv.normalized()
		var top := -2.0
		for v in verts:
			top = maxf(top, v.dot(n))
		var ring: Array = []
		var c := Vector3.ZERO
		for i in verts.size():
			if verts[i].dot(n) > top - 1e-3:
				ring.append(i)
				c += verts[i]
		c /= float(ring.size())
		var u := (verts[ring[0]] - c).normalized()
		var w := n.cross(u)
		ring.sort_custom(func(a: int, b: int) -> bool:
			return atan2((verts[a] - c).dot(w), (verts[a] - c).dot(u)) < atan2((verts[b] - c).dot(w), (verts[b] - c).dot(u)))
		faces.append({"ring": ring, "n": n, "c": c})
	# Values: opposite faces sum to one more than the faces.
	var count := faces.size()
	var next := 1
	for f: Dictionary in faces:
		if f.has("value"):
			continue
		f.value = next
		for o: Dictionary in faces:
			if not o.has("value") and (o.n as Vector3).dot(f.n) < -0.999:
				o.value = count + 1 - next
				break
		next += 1
	return {"verts": verts, "faces": faces}


func _make_die(kind: String) -> Dictionary:
	var p := polyhedron(kind)
	var verts: PackedVector3Array = p.verts
	var shape := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for v in verts:
		pts.append(v * DIE_R)
	shape.points = pts
	var meshes: Array[ArrayMesh] = []
	var faces: Array = []
	for f: Dictionary in p.faces:
		faces.append({"n": f.n, "value": f.value})
	for ci in DIE_COLOURS.size():
		var colour: Color = DIE_COLOURS[ci]
		var ink := Color(0.04, 0.05, 0.1) if colour.get_luminance() > 0.55 else Color(0.97, 0.96, 0.92)
		var mesh := ArrayMesh.new()
		var body := SurfaceTool.new()
		body.begin(Mesh.PRIMITIVE_TRIANGLES)
		var marks := SurfaceTool.new()
		marks.begin(Mesh.PRIMITIVE_TRIANGLES)
		for f: Dictionary in p.faces:
			var ring: Array = f.ring
			var n: Vector3 = f.n
			body.set_normal(n)
			for k in range(1, ring.size() - 1):
				# Godot's front faces are clockwise: the ring (counter-clockwise seen from outside) reversed.
				body.add_vertex(verts[ring[0]] * DIE_R)
				body.add_vertex(verts[ring[k + 1]] * DIE_R)
				body.add_vertex(verts[ring[k]] * DIE_R)
			_mark_face(marks, kind, f, verts)
		body.commit(mesh)
		marks.commit(mesh)
		mesh.surface_set_material(0, _plastic(colour, 0.22))
		mesh.surface_set_material(1, _plastic(ink, 0.4))
		meshes.append(mesh)
	return {"shape": shape, "faces": faces, "meshes": meshes}


## A face's pips (d6) or number (the others), 0.6 mm proud of it.
func _mark_face(st: SurfaceTool, kind: String, f: Dictionary, verts: PackedVector3Array) -> void:
	var ring: Array = f.ring
	var n: Vector3 = f.n
	var c: Vector3 = (f.c as Vector3) * DIE_R + n * 0.0006
	var value := int(f.value)
	var ri := INF
	for k in ring.size():
		var a := verts[ring[k]] * DIE_R
		var b := verts[ring[(k + 1) % ring.size()]] * DIE_R
		var e := (b - a).normalized()
		var off := (c - a) - e * (c - a).dot(e)
		ri = minf(ri, off.length())
	st.set_normal(n)
	if kind == "d6":
		var a0 := verts[ring[0]] * DIE_R
		var a1 := verts[ring[1]] * DIE_R
		var up := ((a0 + a1) * 0.5 - c).normalized()
		up = (up - n * up.dot(n)).normalized()
		var right := up.cross(n)
		var s := ri * 0.52
		var spots := {1: [Vector2.ZERO], 2: [Vector2(-1, 1), Vector2(1, -1)], 3: [Vector2(-1, 1), Vector2.ZERO, Vector2(1, -1)],
			4: [Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)],
			5: [Vector2(-1, 1), Vector2(1, 1), Vector2.ZERO, Vector2(-1, -1), Vector2(1, -1)],
			6: [Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(1, 1), Vector2(1, 0), Vector2(1, -1)]}
		for o: Vector2 in (spots[value] as Array):
			var at := c + right * o.x * s + up * o.y * s
			var pr := ri * (0.2 if value == 1 else 0.15)
			for k in 12:
				var a := TAU * float(k) / 12.0
				var b := TAU * float(k + 1) / 12.0
				st.add_vertex(at)
				st.add_vertex(at + (right * cos(a) + up * sin(a)) * pr)
				st.add_vertex(at + (right * cos(b) + up * sin(b)) * pr)
		return
	var up := (verts[ring[0]] * DIE_R - c)
	up = (up - n * up.dot(n)).normalized()
	var right := up.cross(n)
	var text := str(value)
	var h := ri * (0.95 if text.length() == 1 else 0.78)
	if kind == "d12":
		h *= 0.85
	var w := 0.13 * h
	var width := float(text.length()) * 0.6 + float(text.length() - 1) * 0.22
	var x0 := -width * 0.5
	for ch in text:
		for line: Array in DIGITS[ch]:
			for k in line.size() - 1:
				_stroke(st, c, right, up, Vector2(x0 + (line[k] as Vector2).x, (line[k] as Vector2).y - 0.5) * h,
					Vector2(x0 + (line[k + 1] as Vector2).x, (line[k + 1] as Vector2).y - 0.5) * h, w)
		x0 += 0.82
	if value == 6 or value == 9:
		_stroke(st, c, right, up, Vector2(-width * 0.5, -0.7) * h, Vector2(width * 0.5, -0.7) * h, w)


## A stroke of width w from a to b on the face (x along right, y along up), its ends squared past them.
func _stroke(st: SurfaceTool, c: Vector3, right: Vector3, up: Vector3, a: Vector2, b: Vector2, w: float) -> void:
	var d := (b - a).normalized() if (b - a).length() > 1e-6 else Vector2.RIGHT
	var side := Vector2(-d.y, d.x) * w * 0.5
	var a2 := a - d * w * 0.5
	var b2 := b + d * w * 0.5
	var q := [a2 - side, b2 - side, b2 + side, a2 + side]  # counter-clockwise, seen from outside
	var p: Array[Vector3] = []
	for v: Vector2 in q:
		p.append(c + right * v.x + up * v.y)
	for tri: Array in [[0, 2, 1], [0, 3, 2]]:
		for i: int in tri:
			st.add_vertex(p[i])


## The digits as strokes in a box 0.6 wide and 1 high, drawn here.
const DIGITS := {
	"0": [[Vector2(0.0, 0.15), Vector2(0.0, 0.85), Vector2(0.15, 1.0), Vector2(0.45, 1.0), Vector2(0.6, 0.85), Vector2(0.6, 0.15),
		Vector2(0.45, 0.0), Vector2(0.15, 0.0), Vector2(0.0, 0.15)]],
	"1": [[Vector2(0.1, 0.78), Vector2(0.32, 1.0), Vector2(0.32, 0.0)], [Vector2(0.1, 0.0), Vector2(0.54, 0.0)]],
	"2": [[Vector2(0.0, 0.82), Vector2(0.15, 1.0), Vector2(0.45, 1.0), Vector2(0.6, 0.82), Vector2(0.6, 0.62), Vector2(0.0, 0.0),
		Vector2(0.6, 0.0)]],
	"3": [[Vector2(0.0, 0.86), Vector2(0.15, 1.0), Vector2(0.45, 1.0), Vector2(0.6, 0.86), Vector2(0.6, 0.66), Vector2(0.45, 0.53),
		Vector2(0.2, 0.53)], [Vector2(0.45, 0.53), Vector2(0.6, 0.38), Vector2(0.6, 0.15), Vector2(0.45, 0.0), Vector2(0.15, 0.0),
		Vector2(0.0, 0.14)]],
	"4": [[Vector2(0.46, 0.0), Vector2(0.46, 1.0), Vector2(0.0, 0.3), Vector2(0.62, 0.3)]],
	"5": [[Vector2(0.58, 1.0), Vector2(0.06, 1.0), Vector2(0.02, 0.56), Vector2(0.42, 0.6), Vector2(0.6, 0.42), Vector2(0.6, 0.15),
		Vector2(0.45, 0.0), Vector2(0.15, 0.0), Vector2(0.0, 0.12)]],
	"6": [[Vector2(0.56, 0.94), Vector2(0.42, 1.0), Vector2(0.16, 1.0), Vector2(0.0, 0.8), Vector2(0.0, 0.15), Vector2(0.15, 0.0),
		Vector2(0.45, 0.0), Vector2(0.6, 0.15), Vector2(0.6, 0.42), Vector2(0.45, 0.56), Vector2(0.15, 0.56), Vector2(0.0, 0.42)]],
	"7": [[Vector2(0.0, 1.0), Vector2(0.6, 1.0), Vector2(0.2, 0.0)]],
	"8": [[Vector2(0.3, 0.55), Vector2(0.08, 0.67), Vector2(0.05, 0.86), Vector2(0.18, 1.0), Vector2(0.42, 1.0), Vector2(0.55, 0.86),
		Vector2(0.52, 0.67), Vector2(0.3, 0.55), Vector2(0.05, 0.41), Vector2(0.0, 0.18), Vector2(0.15, 0.0), Vector2(0.45, 0.0),
		Vector2(0.6, 0.18), Vector2(0.55, 0.41), Vector2(0.3, 0.55)]],
	"9": [[Vector2(0.04, 0.06), Vector2(0.18, 0.0), Vector2(0.44, 0.0), Vector2(0.6, 0.2), Vector2(0.6, 0.85), Vector2(0.45, 1.0),
		Vector2(0.15, 1.0), Vector2(0.0, 0.85), Vector2(0.0, 0.58), Vector2(0.15, 0.44), Vector2(0.45, 0.44), Vector2(0.6, 0.58)]],
}


# --- Dominoes ------------------------------------------------------------------------------------

## Where the view's ray from `from` along `dir` first meets what the toys stand on, within `reach`: {"at",
## "normal"}, or {} when it meets nothing.
func aim(from: Vector3, dir: Vector3, reach := 200.0) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * reach, STATIC_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return {}
	return {"at": hit.position, "normal": hit.normal}


## Where a domino of height h would stand at (x, z) near height y: the ground's height there, if it is
## level enough to stand on, else NAN.
func support(xz: Vector2, y: float, h: float) -> float:
	var from := Vector3(xz.x, y + h + 1.0, xz.y)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * (2.0 * h + 4.0), STATIC_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or (hit.normal as Vector3).y < 0.85:
		return NAN
	return float((hit.position as Vector3).y)


## The transform of a domino of height h standing at (x, z) on ground y, its face across `along`.
static func domino_transform(xz: Vector2, y: float, along: Vector2, h: float) -> Transform3D:
	var d := Vector3(along.x, 0.0, along.y).normalized()
	return Transform3D(Basis.looking_at(d, Vector3.UP), Vector3(xz.x, y + h * 0.5 + 0.002, xz.y))


## A new line of dominoes: lay() adds to it until the next begin_line().
func begin_line() -> void:
	_strokes.append([])


## A domino of height h at xf, unless another stands in its way: the body, or null.
func lay(xf: Transform3D, h: float) -> RigidBody3D:
	var size := DOMINO * h
	var shape := _box(size)
	# Nothing in its way, toy, wall or the visitor (a little smaller than itself, so that it may touch them and the
	# ground). One laid in the visitor's body was thrown out at once: web version 49's first build, whose staged
	# load (duck_gun.gd _toy_test) has its outer ring through the start view, lost 212 of its 932 to the chain.
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = _box(size * 0.9)
	probe.transform = xf
	probe.collision_mask = TOY_LAYER | STATIC_LAYER | VISITOR_LAYER
	if not get_world_3d().direct_space_state.intersect_shape(probe, 1).is_empty():
		return null
	var body := RigidBody3D.new()
	body.name = "Domino"
	body.collision_layer = TOY_LAYER
	body.collision_mask = STATIC_LAYER | TOY_LAYER | VISITOR_LAYER
	body.mass = maxf(DOMINO_DENSITY * size.x * size.y * size.z, 0.05)
	body.physics_material_override = _domino_phys
	body.can_sleep = true
	body.set_meta("h", h)
	var owner := body.create_shape_owner(body)
	body.shape_owner_add_shape(owner, shape)
	var mi := MeshInstance3D.new()
	mi.mesh = _domino_mesh
	mi.scale = size
	mi.material_override = _domino_mats[_hue % _domino_mats.size()]
	_hue += 1
	body.add_child(mi)
	add_child(body)
	body.global_transform = xf
	body.sleeping = true
	_dominoes.append(body)
	if _strokes.is_empty():
		_strokes.append([])
	(_strokes[_strokes.size() - 1] as Array).append(body)
	stats.laid += 1
	while _dominoes.size() > MAX_DOMINOES:
		_remove_domino(_dominoes[0])
	stats.dominoes = _dominoes.size()
	return body


func _remove_domino(d: RigidBody3D) -> void:
	_dominoes.erase(d)
	for s: Array in _strokes:
		s.erase(d)
	if is_instance_valid(d):
		_down.erase(d.get_instance_id())
		d.queue_free()


## A push on the domino (or die) the ray from `from` along `dir` meets, at its top, the way the ray goes; or,
## when it meets none, on the domino nearest where it meets the ground, within 3 m. True if one was pushed.
func push(from: Vector3, dir: Vector3, reach := 200.0) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * reach, STATIC_LAYER | TOY_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var target: RigidBody3D = null
	if not hit.is_empty() and hit.collider is RigidBody3D:
		target = hit.collider
	elif not hit.is_empty():
		var at: Vector3 = hit.position
		var best := 3.0
		for d in _dominoes:
			var dist := d.global_position.distance_to(at)
			if dist < best:
				best = dist
				target = d
	if target == null:
		return false
	var flat := Vector3(dir.x, 0.0, dir.z).normalized()
	if target.has_meta("h"):
		var h := float(target.get_meta("h"))
		# Its face square to the push, at its top: the push along the domino's own thin side.
		var thin := target.global_basis.z.normalized()
		if thin.dot(flat) < 0.0:
			thin = -thin
		target.sleeping = false
		target.apply_impulse(thin * target.mass * 0.9 * sqrt(h), target.global_basis.y.normalized() * h * 0.45)
	else:
		target.sleeping = false
		target.apply_central_impulse((flat + Vector3.UP * 0.4) * target.mass * 3.0)
	stats.pushed += 1
	return true


## The last line laid, taken away.
func undo() -> int:
	while not _strokes.is_empty():
		var s: Array = _strokes.pop_back()
		var n := 0
		for d: RigidBody3D in s:
			if is_instance_valid(d):
				_remove_domino(d)
				n += 1
		if n > 0:
			stats.undone += n
			stats.dominoes = _dominoes.size()
			return n
	return 0


## Every die and domino taken away.
func clear() -> void:
	for d in _dice:
		if is_instance_valid(d):
			d.queue_free()
	for d in _dominoes:
		if is_instance_valid(d):
			d.queue_free()
	stats.cleared += _dice.size() + _dominoes.size()
	_dice.clear()
	_dominoes.clear()
	_strokes.clear()
	_down.clear()
	stats.dice = 0
	stats.dominoes = 0
	stats.fallen = 0


func dominoes() -> Array[RigidBody3D]:
	return _dominoes


## The ghost of the next domino, where it would stand, in its colour; or hidden.
func show_ghost(on: bool, xf := Transform3D(), h := 1.0) -> void:
	_ghost.visible = on
	if on:
		_ghost.global_transform = Transform3D(xf.basis * Basis.from_scale(DOMINO * h), xf.origin)
		var c := (_domino_mats[_hue % _domino_mats.size()]).albedo_color
		_ghost_mat.albedo_color = Color(c, 0.35)


func next_colour() -> Color:
	return (_domino_mats[_hue % _domino_mats.size()]).albedo_color


# --- Each step -----------------------------------------------------------------------------------

## Each step, the toys awake only: the sleeping keep where and how they were (_down). Reading every toy each step
## cost about 0.5 ms with 1236 of them at rest (artpass/curios/NOTES.md, 2026-10-16).
func _physics_process(delta: float) -> void:
	_clack_budget = minf(_clack_budget + CLACK_RATE * delta, 4.0)
	for l: Array in _leaves:
		if is_instance_valid(l[1]):
			(l[0] as AnimatableBody3D).global_transform = (l[1] as Node3D).global_transform * (l[2] as Transform3D)
	_follow_visitor()
	var awake := 0
	for kind in 2:
		var list: Array = _dice if kind == 0 else _dominoes
		var i := list.size() - 1
		while i >= 0:
			var b: RigidBody3D = list[i]
			i -= 1
			if not is_instance_valid(b):
				list.remove_at(i + 1)
				continue
			if b.sleeping:
				continue
			awake += 1
			if b.global_position.y < KILL_Y:
				list.remove_at(i + 1)
				_down.erase(b.get_instance_id())
				b.queue_free()
				continue
			if kind == 1:
				if b.global_basis.y.normalized().y < 0.5:
					_down[b.get_instance_id()] = true
				else:
					_down.erase(b.get_instance_id())
			# A knock: the speed changing at once, more than falling or rolling changes it.
			var v := b.linear_velocity
			var was: Vector3 = b.get_meta("v", v)
			b.set_meta("v", v)
			var jolt := (v - was).length() - 9.8 * delta * 1.5
			if jolt > 0.6 and _clack_budget >= 1.0:
				_clack_budget -= 1.0
				_clack(b, jolt)
	stats.fallen = _down.size()
	stats.awake = awake
	stats.dice = _dice.size()
	stats.dominoes = _dominoes.size()


func _clack(b: RigidBody3D, strength: float) -> void:
	if _players.is_empty():
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	var domino := b.has_meta("h")
	var h := float(b.get_meta("h", 0.1))
	p.stream = _sounds.tock if domino else (_sounds.clack if _rng.randf() < 0.5 else _sounds.clack2)
	p.pitch_scale = clampf(1.0 / sqrt(maxf(h, 0.1)), 0.35, 2.0) * _rng.randf_range(0.92, 1.08) if domino else _rng.randf_range(0.9, 1.15)
	p.volume_db = clampf(-22.0 + 9.0 * log(1.0 + strength) / log(2.0), -24.0, -2.0) + (minf(h, 4.0) * 1.5 if domino else 0.0)
	p.global_position = b.global_position
	p.play()
	stats.clacks += 1


## Toys' sounds, synthesized: a die's clack on stone (two), a domino's tock.
func _make_sounds() -> void:
	var noise := RandomNumberGenerator.new()
	noise.seed = 61
	_sounds.clack = _synth(0.09, func(t: float) -> float:
		return noise.randf_range(-1.0, 1.0) * exp(-t / 0.003) * 0.7 + sin(TAU * 3150.0 * t) * exp(-t / 0.014) * 0.5 \
			+ sin(TAU * 4720.0 * t) * exp(-t / 0.009) * 0.3)
	_sounds.clack2 = _synth(0.09, func(t: float) -> float:
		return noise.randf_range(-1.0, 1.0) * exp(-t / 0.0025) * 0.7 + sin(TAU * 2680.0 * t) * exp(-t / 0.016) * 0.5 \
			+ sin(TAU * 5310.0 * t) * exp(-t / 0.007) * 0.25)
	_sounds.tock = _synth(0.16, func(t: float) -> float:
		return noise.randf_range(-1.0, 1.0) * exp(-t / 0.004) * 0.5 + sin(TAU * 820.0 * t) * exp(-t / 0.03) * 0.7 \
			+ sin(TAU * 1930.0 * t) * exp(-t / 0.012) * 0.3)
	for k in 12:
		var p := AudioStreamPlayer3D.new()
		p.name = "Clack%d" % k
		p.unit_size = 4.0
		p.max_distance = 80.0
		add_child(p)
		_players.append(p)


static func _synth(seconds: float, wave: Callable) -> AudioStreamWAV:
	var rate := 22050
	var n := int(seconds * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := clampf(float(wave.call(float(i) / rate)) * 0.6, -1.0, 1.0)
		data.encode_s16(i * 2, roundi(v * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.data = data
	return s


static func _plastic(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = 0.6
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.06
	return m
