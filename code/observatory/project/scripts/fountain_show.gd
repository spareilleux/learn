extends Node3D
## The Grand Canal's fountain show, after the author's « des fontaines colorées et peut-être des jets d'eau
## qui font un peu comme à Las Vegas des formes particulières » (2026-10-13): two rows of nozzles along the
## canal, a line of shooters down its middle, three rings and a fan at its far end, playing a loop of ten
## scenes (assets/fountain_show.gdshaderinc: a veil, a wave, a sway, a vault of arches, a helix, baskets, a
## braid on a torus knot, a chase, a peacock's fan, a finale).
##
## Nothing is simulated here. Each jet is a ribbon of one MultiMesh whose vertex shader
## (assets/fountain_jet.gdshader) puts the water where it is: what left the nozzle tau seconds ago, with the
## speed and the lean the show gave the nozzle then, fallen freely since. This node keeps the show's clock,
## and a second, small view of the jets alone, mirrored in the water's plane, which the canal's water adds
## as their reflection (palace_garden.gdshader kind 4, show_mirror).
##
## Made by palace_gardens.gd (_build_show); --show=off (?show=off) leaves it out, --show-t=<s> holds the
## clock there (captures).

const JET_SHADER_PATH := "res://assets/fountain_jet.gdshader"
const POOL_SHADER_PATH := "res://assets/fountain_pool.gdshader"
const CROWN_SHADER_PATH := "res://assets/fountain_crown.gdshader"
const SPRAY_TEX_PATH := "res://assets/fountain_spray.png"
const LOOP := 120.0            # s: fountain_show.gdshaderinc SHOW_LOOP
const SEGMENTS := 48           # along a jet
const ROW_X := 8.5             # m from the canal's middle line to a row
const ROW_STEP := 2.0
const SHOOTER_STEP := 6.0
const RING_R := 5.5
const RING_N := 24
const FAN_N := 21
const END := 6.0               # m from the canal's ends to the first and last nozzles
## Each group's jets: half width at the nozzle (m), longest flight drawn (s), widening (m/s), strength.
const ROWS := [0.1, 4.8, 0.16, 0.55]
const SHOOTERS := [0.3, 7.4, 0.3, 0.5]
const RINGS := [0.09, 3.7, 0.14, 0.6]
const FAN := [0.12, 5.2, 0.18, 0.45]
const MIRROR_SCALE := 0.5      # the reflection's view, of the screen's size

var stats := {"nozzles": 0, "triangles": 0, "mirror": [0, 0], "clock": 0.0}
## Seconds into the loop, and whether it is held there.
var clock := 0.0
var held := false

var _water: ShaderMaterial
var _water_y := 0.0
var _mats: Array[ShaderMaterial] = []
var _view: SubViewport
var _eye: Camera3D
var _crowns: MultiMeshInstance3D
var _level := 0


## water: the canal's material; water_y: its surface; canal: its two ends along z, its middle line x = 0.
## false, with nothing built, when a shader or the spray's texture is missing.
func setup(water: ShaderMaterial, water_y: float, canal: Vector2) -> bool:
	for path: String in [JET_SHADER_PATH, POOL_SHADER_PATH, CROWN_SHADER_PATH, SPRAY_TEX_PATH]:
		if not ResourceLoader.exists(path):
			return false
	_water = water
	_water_y = water_y
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--show-t="):
			clock = fposmod(float(a.trim_prefix("--show-t=")), LOOP)
			held = true
	var xforms: Array[Transform3D] = []
	var customs: Array[Color] = []
	var colours: Array[Color] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261013
	var y := water_y + 0.04
	var z0 := canal.x + END
	var z1 := canal.y - END
	# The rows: +X towards the canal's middle, +Z down the canal for both.
	var n := int(floor((z1 - z0) / ROW_STEP)) + 1
	for side: float in [-1.0, 1.0]:
		for i in n:
			xforms.append(Transform3D(Basis(Vector3(-side, 0.0, 0.0), Vector3.UP, Vector3.BACK), Vector3(side * ROW_X, y, z0 + i * ROW_STEP)))
			customs.append(Color(float(i) / (n - 1), 0.0, side, rng.randf()))
			colours.append(_par(ROWS))
	# The shooters, by turns a little to either side of the middle line: all on it, they stood one behind
	# another from the terrace and from the canal's head, a single white column (shots/show/a2 head_t114).
	n = int(floor((z1 - z0 - 6.0) / SHOOTER_STEP)) + 1
	for i in n:
		xforms.append(Transform3D(Basis(), Vector3(1.3 if i % 2 == 0 else -1.3, y, z0 + 3.0 + i * SHOOTER_STEP)))
		customs.append(Color(float(i) / (n - 1), 1.0, float(i), rng.randf()))
		colours.append(_par(SHOOTERS))
	# The rings, a quarter, a half and three quarters of the way down: +X to the ring's middle, +Z round it.
	for r in 3:
		var mid := Vector3(0.0, y, lerpf(canal.x, canal.y, 0.25 * (r + 1)))
		for i in RING_N:
			var a := TAU * i / RING_N
			var out := Vector3(cos(a), 0.0, sin(a))
			xforms.append(Transform3D(Basis(-out, Vector3.UP, Vector3(-sin(a), 0.0, cos(a))), mid + out * RING_R))
			customs.append(Color(float(i) / RING_N, 2.0, r + 0.5 * (i % 2), rng.randf()))
			colours.append(_par(RINGS))
	# The fans, each on a short bar across the canal, one at either end: the far one alone was hidden from
	# the terrace and the canal's head by everything before it (shots/show/a4 head_t102).
	for z: float in [canal.x + 8.0, canal.y - 8.0]:
		for i in FAN_N:
			var u := float(i) / (FAN_N - 1)
			xforms.append(Transform3D(Basis(), Vector3((u * 2.0 - 1.0) * 1.5, y, z)))
			customs.append(Color(u, 3.0, 0.0, rng.randf()))
			colours.append(_par(FAN))
	var jets := _instances(_ribbon(), xforms, customs, colours)
	var pools := _instances(_quad(), xforms, customs, colours)
	var spray: Texture2D = load(SPRAY_TEX_PATH)
	var jet_mat := _mat(JET_SHADER_PATH, {"spray_tex": spray, "water_y": water_y})
	var mirror_mat := _mat(JET_SHADER_PATH, {"spray_tex": spray, "water_y": water_y, "mirror": 1.0})
	# Whatever the nozzles do, the water stays within this: the canal's width, 70 m up, and as far down for
	# its mirror.
	var box := AABB(Vector3(-16.0, water_y - 70.0, canal.x - 6.0), Vector3(32.0, 140.0, canal.y - canal.x + 12.0))
	add_child(_draw("Jets", jets, jet_mat, box))
	# The spray where each jet stalls at its highest. (The same ribbons drawn again four times as wide, as
	# a mist round the jets, cost 0.15 to 0.28 ms and turned to stars and facets where a jet turns back:
	# shots/show/a5.)
	_crowns = _draw("Crowns", pools, _mat(CROWN_SHADER_PATH, {"spray_tex": spray, "water_y": water_y}), box)
	add_child(_crowns)
	add_child(_draw("Pools", pools, _mat(POOL_SHADER_PATH, {"spray_tex": spray, "energy": 0.6}), box))
	add_child(_draw("Foam", pools, _mat(POOL_SHADER_PATH, {"spray_tex": spray, "landing": 1.0}), box))
	# The reflection's world: the same jets, mirrored, and an eye that follows the camera.
	_view = SubViewport.new()
	_view.name = "Mirror"
	_view.own_world_3d = true
	_view.size = Vector2i(64, 36)
	_view.msaa_3d = Viewport.MSAA_DISABLED
	_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_view)
	_eye = Camera3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	_eye.environment = env
	_view.add_child(_eye)
	_view.add_child(_draw("JetsMirrored", jets, mirror_mat, box))
	_view.add_child(_draw("CrownsMirrored", pools, _mat(CROWN_SHADER_PATH, {"spray_tex": spray, "water_y": water_y, "mirror": 1.0}), box))
	stats.nozzles = xforms.size()
	stats.triangles = xforms.size() * (SEGMENTS * 2 + 2)
	return true


static func _par(group: Array) -> Color:
	return Color(group[0], group[1] / 8.0, group[2], group[3])


func _mat(path: String, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	for k: String in params:
		m.set_shader_parameter(k, params[k])
	m.set_shader_parameter("show_t", clock)
	_mats.append(m)
	return m


static func _instances(mesh: Mesh, xforms: Array[Transform3D], customs: Array[Color], colours: Array[Color]) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colours[i])
		mm.set_instance_custom_data(i, customs[i])
	return mm


static func _draw(node_name: String, mm: MultiMesh, mat: Material, box: AABB) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.custom_aabb = box
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return mmi


## A jet's ribbon: SEGMENTS quads, UV.x across it, UV.y along it. Its vertices are placed by the shader.
static func _ribbon() -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in SEGMENTS + 1:
		var s := float(i) / SEGMENTS
		for x: float in [0.0, 1.0]:
			verts.append(Vector3(x - 0.5, s, 0.0))
			uvs.append(Vector2(x, s))
		if i < SEGMENTS:
			var b := i * 2
			idx.append_array(PackedInt32Array([b, b + 1, b + 2, b + 1, b + 3, b + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


## A pool of light's quad, flat, 2 m across before the shader sizes it.
static func _quad() -> PlaneMesh:
	var q := PlaneMesh.new()
	q.size = Vector2(2.0, 2.0)
	return q


func _ready() -> void:
	# After the camera has moved this frame, palace_gardens.gd has shown or hidden the gardens.
	process_priority = 950
	_water.set_shader_parameter("show_mirror", _view.get_texture())
	_water.set_shader_parameter("show_mirror_k", 1.0)


## From level 2 on, no reflection and no crowns (palace_gardens.gd hides the show itself from level 3).
func set_quality(level: int) -> void:
	_level = level
	_crowns.visible = level < 2 and not OS.get_cmdline_user_args().has("--show-crowns=off")


func _process(delta: float) -> void:
	var on := is_visible_in_tree()
	if on and not held:
		clock = fposmod(clock + delta, LOOP)
	if on:
		for m in _mats:
			m.set_shader_parameter("show_t", clock)
	var mirror := on and _level < 2
	if mirror != (_view.render_target_update_mode == SubViewport.UPDATE_ALWAYS):
		_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if mirror else SubViewport.UPDATE_DISABLED
		_water.set_shader_parameter("show_mirror_k", 1.0 if mirror else 0.0)
	stats.clock = snappedf(clock, 0.01)
	if not mirror:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var size := Vector2i((get_viewport().get_visible_rect().size * MIRROR_SCALE).max(Vector2(64.0, 36.0)))
	if _view.size != size:
		_view.size = size
		stats.mirror = [size.x, size.y]
	_eye.global_transform = cam.global_transform
	# Camera3D.fov refuses less than a degree, set_perspective does not (scripts/view_fit.gd): the
	# telescope's x100 is 0.66 degrees, and the mirror has to keep the view's field.
	if cam.fov < 1.0:
		_eye.set_perspective(cam.fov, cam.near, cam.far)
	else:
		_eye.fov = cam.fov
		_eye.near = cam.near
		_eye.far = cam.far
	_eye.keep_aspect = cam.keep_aspect
