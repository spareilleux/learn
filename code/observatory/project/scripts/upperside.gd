extends Node3D
## Trantor's Upperside round the observatory's roof, for the roof view (scripts/extra_views.gd,
## key 9). In Prelude to Foundation, Upperside is the top of the domes that cover the world; here
## only the observatory's roof and drum rise out of it. Built the first time the camera goes
## outside, and hidden while it is inside, so a visitor who never climbs pays nothing:
##   - the roof: a low cone of lead with standing seams, from a stone cornice to the drum;
##   - the drum's outer face, its 24 lancets lit from inside, and a cornice round the open oculus;
##   - Upperside: a plated deck to 3 km, and domes of every size on it, some with lit windows and
##     red beacons (assets/upperside.gdshader lights them from the galactic core).
## Everything draws with its own shader, unshaded: no light is added to the scene.

const SHADER_PATH := "res://assets/upperside.gdshader"
## Dressed stone with a grain of metal, from Blender and ComfyUI (artpass/exterior/): a tile
## 4 m wide and 1 m high, a steel band along its top and bottom edges.
const ASHLAR_ALBEDO_PATH := "res://assets/exterior_ashlar_albedo.png"
const ASHLAR_NORMAL_PATH := "res://assets/exterior_ashlar_normal.png"
const ASHLAR_TILE := 4.0
const GLASS_SHADER_PATH := "res://assets/stained_glass.gdshader"
const REACH := 3000.0     ## metres: the deck's radius; the sky is drawn at 3500

var stats := {}
## Off, the roof and the drum alone, with no deck or domes round them: the palace gardens
## (scripts/palace_gardens.gd) take their place, as the author chose on 2026-10-04 ("Remplacer
## Upperside"). Set before the node enters the tree.
var deck := true
var _obs: Node3D
var _core := Vector3(-0.468, 0.867, -0.170)


## observatory: for the hall's dimensions and glass panels; core: the galactic core's direction.
func configure(observatory: Node3D, core: Vector3) -> void:
	_obs = observatory
	_core = core


func _ready() -> void:
	_build()


func _mat(albedo: Color, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER_PATH)
	m.set_shader_parameter("albedo", albedo)
	m.set_shader_parameter("core_dir", _core)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## The roof's measures, from the hall's: the slab's top, the eave, the drum's outer face, the roof's
## top at the drum, and the balustrade round the eave. scripts/lift.gd and scripts/walk_physics.gd
## walk on it.
static func profile(obs: Object) -> Dictionary:
	var slab_top := float(obs.get("_ceiling_y")) + 0.6
	var eave := float(obs.get("outer_radius")) + 1.3
	return {"slab_top": slab_top, "eave": eave, "drum_out": float(obs.get("oculus_radius")) + 0.56,
		"roof_top": slab_top + 0.65, "rail_r": eave - 0.35}


## The lead's height at radius r: a cone from the eave, 5 cm over the slab, up to the drum.
static func roof_height(prof: Dictionary, r: float) -> float:
	var y0: float = prof.slab_top + 0.05
	return y0 + (float(prof.roof_top) - y0) * (float(prof.eave) - r) / (float(prof.eave) - float(prof.drum_out))


func _build() -> void:
	var oculus: float = _obs.get("oculus_radius")
	var dome_y: float = _obs.get("_dome_y")
	var prof := profile(_obs)
	var slab_top: float = prof.slab_top
	var eave: float = prof.eave
	var drum_out: float = prof.drum_out
	var roof_top: float = prof.roof_top
	# The lift's kiosk stands in a hole in the roof (scripts/lift.gd).
	var lift := _obs.get_node_or_null("Lift")
	var hole: Vector3 = lift.call("roof_hole") if lift != null and lift.has_method("roof_hole") else Vector3.ZERO

	var lead := _mat(Color(0.25, 0.27, 0.29), {"sheen": 0.45, "plates": 1.0, "plate_size": 1.2, "hole": hole})
	var stone := _mat(Color(0.5, 0.47, 0.43), {"sheen": 0.05, "plates": 1.0, "plate_size": 0.9})
	if ResourceLoader.exists(ASHLAR_ALBEDO_PATH) and ResourceLoader.exists(ASHLAR_NORMAL_PATH):
		stone.set_shader_parameter("ashlar", 1.0)
		stone.set_shader_parameter("ashlar_albedo", load(ASHLAR_ALBEDO_PATH))
		stone.set_shader_parameter("ashlar_normal", load(ASHLAR_NORMAL_PATH))
		stats.ashlar = 1

	# The roof, the seams on it, the cornice at its eave.
	_mesh("Roof", _cone(eave, slab_top + 0.05, drum_out, roof_top, 128), lead)
	var seams := SurfaceTool.new()
	seams.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_seams := 64
	for i in n_seams:
		var a := TAU * i / n_seams
		_seam(seams, a, eave, slab_top + 0.05, drum_out, roof_top)
	_mesh("RoofSeams", seams.commit(), _mat(Color(0.3, 0.32, 0.34), {"sheen": 0.6, "hole": hole}))
	_mesh("Cornice", _ring(eave - 0.1, eave + 0.45, slab_top - 0.35, slab_top + 0.3, 128, slab_top + 0.27), stone)
	_balustrade(prof)

	# The drum's outer face above the roof, its lit lancets, and the cornice round the oculus.
	_mesh("DrumOuter", _ring(drum_out - 0.06, drum_out, roof_top - 0.05, dome_y, 128, roof_top - 0.05), stone)
	_mesh("DrumCornice", _ring(oculus - 0.05, drum_out + 0.35, dome_y, dome_y + 0.3, 128, dome_y + 0.27), stone)
	_windows(oculus, drum_out, roof_top, dome_y)

	# Upperside: the deck, from the eave to the horizon, and the domes on it.
	if not deck:
		stats.upperside = 0
		return
	var plated := _mat(Color(0.2, 0.21, 0.22), {"sheen": 0.25, "plates": 1.0, "plate_size": 6.0, "moss": 1.0})
	_mesh("Deck", _disc(eave + 0.4, REACH, slab_top - 0.3, 96), plated)
	_domes(eave, slab_top - 0.3)
	stats.upperside = 1


## A bronze balustrade on the lead, 35 cm inside the eave, where a walker on the roof stops
## (scripts/walk_physics.gd): posts every 1.2 m or so, a handrail 1.05 m up, two lower rails. No
## balusters between the posts: thin bars far off would shimmer.
func _balustrade(prof: Dictionary) -> void:
	var r: float = prof.rail_r
	var y := roof_height(prof, r)
	var metal := _mat(Color(0.34, 0.27, 0.18), {"sheen": 0.75})
	_mesh("RailTop", _ring(r - 0.035, r + 0.035, y + 1.0, y + 1.05, 256), metal)
	_mesh("RailMid", _ring(r - 0.015, r + 0.015, y + 0.52, y + 0.55, 256), metal)
	_mesh("RailLow", _ring(r - 0.02, r + 0.02, y + 0.1, y + 0.14, 256), metal)
	var post := BoxMesh.new()
	post.size = Vector3(0.06, 1.05, 0.06)
	var n := int(TAU * r / 1.2)
	var xfs: Array[Transform3D] = []
	for i in n:
		var a := TAU * (i + 0.5) / n
		xfs.append(Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * r, y + 0.5, sin(a) * r)))
	_multi("RailPosts", post, metal, xfs)
	stats.rail_posts = n


func _mesh(name: String, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(mi)
	return mi


## A cone's side, from radius r0 at y0 up to r1 at y1, facing out and up.
func _cone(r0: float, y0: float, r1: float, y1: float, seg: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
		var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
		var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
		# Clockwise seen from outside and above: Godot's front face.
		st.add_vertex(p00); st.add_vertex(p01); st.add_vertex(p10)
		st.add_vertex(p01); st.add_vertex(p11); st.add_vertex(p10)
	st.generate_normals()
	return st.commit()


## A standing seam along the roof's slope at angle a: a thin fin 6 cm high.
func _seam(st: SurfaceTool, a: float, r0: float, y0: float, r1: float, y1: float) -> void:
	var dir := Vector3(cos(a), 0.0, sin(a))
	var side := Vector3(-sin(a), 0.0, cos(a)) * 0.02
	var b0 := dir * r0 + Vector3(0.0, y0, 0.0)
	var b1 := dir * r1 + Vector3(0.0, y1, 0.0)
	var up := Vector3(0.0, 0.06, 0.0)
	# The two flanks, then the top.
	_quad(st, b0 + side, b1 + side, b1 + side + up, b0 + side + up)
	_quad(st, b1 - side, b0 - side, b0 - side + up, b1 - side + up)
	_quad(st, b0 + side + up, b1 + side + up, b1 - side + up, b0 - side + up)


## A thick ring: outer and inner walls, a top and an underside, from y0 to y1. Its UVs count
## ashlar tiles: u round the circle, a whole number of tiles so that it closes, and v down from
## band_y, where a steel band runs; on the top and underside, v runs inwards from the rim.
func _ring(r_in: float, r_out: float, y0: float, y1: float, seg: int, band_y := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_out := maxf(1.0, roundf(TAU * r_out / ASHLAR_TILE))
	var n_in := maxf(1.0, roundf(TAU * r_in / ASHLAR_TILE))
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var u0 := -float(i) / seg
		var u1 := -float(i + 1) / seg
		var c0 := Vector3(cos(a0), 0.0, sin(a0))
		var c1 := Vector3(cos(a1), 0.0, sin(a1))
		var o00 := c0 * r_out + Vector3(0, y0, 0)
		var o01 := c1 * r_out + Vector3(0, y0, 0)
		var o10 := c0 * r_out + Vector3(0, y1, 0)
		var o11 := c1 * r_out + Vector3(0, y1, 0)
		var i00 := c0 * r_in + Vector3(0, y0, 0)
		var i01 := c1 * r_in + Vector3(0, y0, 0)
		var i10 := c0 * r_in + Vector3(0, y1, 0)
		var i11 := c1 * r_in + Vector3(0, y1, 0)
		var vb := band_y - y0
		var vt := band_y - y1
		# The top and the underside within one course, from 6 to 44 cm below its band.
		var vr := 0.44
		_quad(st, o00, o01, o11, o10, [Vector2(u0 * n_out, vb), Vector2(u1 * n_out, vb), Vector2(u1 * n_out, vt), Vector2(u0 * n_out, vt)])
		_quad(st, i01, i00, i10, i11, [Vector2(u1 * n_in, vb), Vector2(u0 * n_in, vb), Vector2(u0 * n_in, vt), Vector2(u1 * n_in, vt)])
		_quad(st, o10, o11, i11, i10, [Vector2(u0 * n_out, 0.06), Vector2(u1 * n_out, 0.06), Vector2(u1 * n_out, vr), Vector2(u0 * n_out, vr)])
		_quad(st, i00, i01, o01, o00, [Vector2(u0 * n_out, vr), Vector2(u1 * n_out, vr), Vector2(u1 * n_out, 0.06), Vector2(u0 * n_out, 0.06)])
	return st.commit()


## A flat face a, b, c, d, clockwise seen from its front as Godot's front faces are, with its own
## normal.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv := []) -> void:
	var pts := [a, b, c, d]
	st.set_normal((d - a).cross(b - a).normalized())
	for k in [0, 1, 2, 0, 2, 3]:
		if not uv.is_empty():
			st.set_uv(uv[k])
		st.add_vertex(pts[k])


## A flat annulus facing up, from r0 to r1 at height y, in rings that widen outwards.
func _disc(r0: float, r1: float, y: float, seg: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radii := [r0]
	var r := r0
	while r < r1:
		r = minf(r1, r * 1.35 + 4.0)
		radii.append(r)
	for k in radii.size() - 1:
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p00 := Vector3(cos(a0) * radii[k], y, sin(a0) * radii[k])
			var p01 := Vector3(cos(a1) * radii[k], y, sin(a1) * radii[k])
			var p10 := Vector3(cos(a0) * radii[k + 1], y, sin(a0) * radii[k + 1])
			var p11 := Vector3(cos(a1) * radii[k + 1], y, sin(a1) * radii[k + 1])
			st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p01)
			st.add_vertex(p10); st.add_vertex(p11); st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


## The lancets seen from outside: the same panels, lit from within the drum, a little dimmer.
func _windows(oculus: float, drum_out: float, roof_top: float, dome_y: float) -> void:
	var count: int = _obs.get("stained_glass_windows")
	var panels: Array = _obs.get_script().get_script_constant_map().get("GLASS_PANELS", [])
	if count <= 0 or panels.is_empty() or not ResourceLoader.exists(GLASS_SHADER_PATH):
		return
	var w := 1.1
	var h := minf(dome_y - roof_top - 0.5, w * 2.2)
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	var mats := []
	for k in panels.size():
		var m := ShaderMaterial.new()
		m.shader = load(GLASS_SHADER_PATH)
		m.set_shader_parameter("glass", load(panels[k][0]))
		m.set_shader_parameter("energy", 1.1)
		m.set_shader_parameter("aspect", h / w)
		m.set_shader_parameter("seed", float(k) + 0.5)
		mats.append(m)
	var cy := roof_top + 0.25 + h * 0.5
	for i in count:
		var a := TAU * (i + 0.5) / count
		var out := Vector3(cos(a), 0.0, sin(a))
		var mi := MeshInstance3D.new()
		mi.name = "LancetOut%02d" % i
		mi.mesh = quad
		mi.material_override = mats[i % mats.size()]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# A quad faces +Z: turn it to face outwards, just proud of the drum.
		mi.transform = Transform3D(Basis.looking_at(-out, Vector3.UP), out * (drum_out + 0.02) + Vector3(0.0, cy, 0.0))
		add_child(mi)
	stats.lancets_out = count


## Domes on the deck, larger with distance: in rings round the observatory, each ring as wide as
## its domes, the domes jittered and some left out so that the rings do not show: linear in the
## number of domes, where testing each dome against every other placed one is quadratic.
func _domes(eave: float, deck_y: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11031
	var placed: Array[Vector3] = []  # x, radius, z
	var d := eave + 40.0
	while d < REACH * 0.92:
		var r := lerpf(9.0, 150.0, pow(d / REACH, 0.85))
		var slots := int(TAU * d / (2.3 * r))
		var turn := rng.randf() * TAU
		for i in slots:
			if rng.randf() < 0.22:
				continue
			var ri := r * rng.randf_range(0.55, 1.0)
			var a := turn + TAU * (i + rng.randf_range(-0.2, 0.2)) / slots
			var di := d + r * rng.randf_range(-0.35, 0.35)
			placed.append(Vector3(cos(a) * di, ri, sin(a) * di))
		d += 2.3 * r
	var cap := SphereMesh.new()
	cap.radius = 1.0
	cap.height = 1.0
	cap.is_hemisphere = true
	cap.radial_segments = 40
	cap.rings = 10
	var plain: Array[Transform3D] = []
	var lit: Array[Transform3D] = []
	var beacons: Array[Transform3D] = []
	for p in placed:
		var r := p.y
		var hgt := r * rng.randf_range(0.28, 0.6)
		var xf := Transform3D(Basis.from_scale(Vector3(r, hgt, r)), Vector3(p.x, deck_y - r * 0.02, p.z))
		if rng.randf() < 0.3:
			lit.append(xf)
		else:
			plain.append(xf)
		if rng.randf() < 0.35:
			beacons.append(Transform3D(Basis.from_scale(Vector3.ONE * clampf(r * 0.012, 0.35, 1.6)), Vector3(p.x, deck_y + hgt + 0.3, p.z)))
	var metal := _mat(Color(0.3, 0.31, 0.33), {"sheen": 0.5, "plates": 1.0, "plate_size": 8.0, "moss": 0.6})
	var windowed := _mat(Color(0.28, 0.29, 0.31), {"sheen": 0.45, "plates": 1.0, "plate_size": 8.0, "windows": 0.22})
	_multi("Domes", cap, metal, plain)
	_multi("LitDomes", cap, windowed, lit)
	var bulb := SphereMesh.new()
	bulb.radius = 1.0
	bulb.height = 2.0
	bulb.radial_segments = 8
	bulb.rings = 4
	var red := StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color = Color(1.0, 0.18, 0.1) * 2.5
	_multi("Beacons", bulb, red, beacons)
	stats.domes = placed.size()
	stats.beacons = beacons.size()


func _multi(name: String, mesh: Mesh, mat: Material, xfs: Array[Transform3D]) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(mmi)
