extends Node3D
## The library wing off bay 10 (artpass/foundation/NOTES.md; the author, 2026-10-12: « ajoute une aile
## de bibliothèque inspirée des images : hauts rayonnages, galerie, bustes, grands piliers et lumière
## chaude »). From the hall, a portal where bay 10's shelves were; a vaulted vestibule; then the long
## room: eight bays of alcoves lined with books, a giant order of piers carrying a gallery and an
## entablature, a bust before each pier, a barrel vault in dark wood, and at the far end a tall window on
## the night city's great drum, which stands on the wing's axis (scripts/night_city.gd). Outside: stone
## walls on a balustraded terrace at the hall's floor, a lead roof, and a paved court below.
## Made by extra_views.gd beside the gardens (scripts/palace_gardens.gd), which cut the bay's wall and
## shelves as they do for their glazed bays and hand the walking body and the riders to walk() and
## push_out(). The wing's own lights reach only its own meshes (render layer 13), so the hall is lit as it
## was. Everything is built in the wing's frame: x across, y up, z out along the axis from the hall
## wall's inner face. --no-wing (?wing=0) leaves the hall as it was.

const WING_BAY := 10
const STONE_SHADER_PATH := "res://assets/wing_stone.gdshader"
const INTERIOR_SHADER_PATH := "res://assets/wing_interior.gdshader"
const CARPET_SHADER_PATH := "res://assets/wing_carpet.gdshader"
const STONE_TEX_PATH := "res://assets/garden_stone.png"
const MARBLE_SHADER_PATH := "res://assets/statue_marble.gdshader"
const MARBLE_PATH := "res://assets/stone_marble.png"
const PORTAL_W := 4.4      # palace_gardens.gd's OPEN_W: the wall's cut is the glazed bays'
const PORTAL_H := 5.15     # their HEAD; the hall's first walkway's underside is at 5.85
const WALKWAY := 5.85
## The canopy over the portal on the hall's side: how far it comes out under the walkway, whose inner
## edge is 4 m from the wall (observatory.gd: outer_radius 18, the walkway from 14), and its half width,
## inside the bay's at that edge (2.78 m).
const CANOPY_Z := -3.9
const CANOPY_HW := 2.6
const RECESS_Z := -0.24    # the recess's face, flush with the hall's shelves' sides (SCREEN_Z)
const VEST_Z0 := 0.1
const VEST_HW := 2.6
const VEST_SPRING := 4.4
const NAVE_Z0 := 4.6       # the near end wall's inner face
const NEAR_T := 0.9
const BAYS := 8
const PITCH := 4.8
const AISLE_HW := 3.2
const PIER_X := Vector2(3.2, 4.2)
const CASE_FRONT := 6.3
const WALL_IN := 6.8
const SKIN := 6.86         # the inner skin (lit stone) and the outer wall (self-lit) meet here
const WALL_OUT := 7.7
const PLINTH := 0.25
const CASE_TOP := 4.65
const GALLERY_Y := 5.0
const GALLERY_X := 3.7     # the gallery's front edge, halfway through the piers
const UPPER_TOP := 8.85
const SIDE_CEILING := 9.15
const ENTABLATURE := 10.2  # its top, where the vault springs
const VAULT_A := 4.3
const VAULT_B := 4.0
const END_T := 0.9
const EAVE_Y := 11.0
const RIDGE_Y := 16.0
const ROOF_HW := 8.3
const ROW_PITCH := 0.55
const WINDOW := Vector3(0.8, 5.6, 8.6)       # the gallery's windows: half width, sill, head
const END_WINDOW := Vector3(2.6, 1.0, 9.4)  # the end window: half width, sill, spring of its round head
const PODIUM_Y := -10.0    # palace_gardens.gd's GROUND_Y
const PODIUM_HW := 8.8
const ESPLANADE := Vector2(18.9, 60.0)    # the court round the wing's terrace
const PARK := 600.0        # m: a dark park beyond the court, then the night city's low streets
## The wing's render layer: its meshes are on it and on layer 1, its lights reach only it. Layer 2 is
## taken: the hall's floor and the steel shell are on it (observatory.gd, HallProbe's reflection_mask).
const LAYER := 1 << 12
## The looking glasses' layer under Compatibility alone: out of the reflection probes' captures.
const MIRROR_LAYER := 1 << 13
const TERRACE_HW := 14.0   # the terrace round the wing, at the hall's floor
const TERRACE_END := 12.0  # beyond the end wall
const CHANDELIER_Y := 6.6
## Under Compatibility (the web build) there is no bounce light and no tonemapped HDR: the lamps, high
## over the floor, light it a third as much as under Forward+ (artpass/foundation/shots/lighttest*).
const COMPAT_GAIN := 3.0
const WARM := Color(1.0, 0.74, 0.46)

var stats := {}
var _obs: Node3D
var _core := Vector3(-0.468, 0.867, -0.170)
var _outer := 18.0
var _angle := 0.0
var _frame := Transform3D()
var _inv := Transform3D()
var _m := {}
var _mat := {}
var _parts := {}           # "chunk/material" -> [mesh, transform] pairs, in the wing's frame
var _books := {}           # chunk -> _fill_board's dictionary
var _book_mmis: Array[MultiMeshInstance3D] = []
var _hall_out := false      # under Compatibility, the hall's lights faded out (_fade_hall)
var _hall_faded := []       # [light, fade enabled, begin, length, cull mask] as they were
var _book_full: Mesh
var _book_low: Mesh
var _solids: Array[Rect2] = []   # what the walking body walks round, in the wing's (x, z)
var _interior: Node3D
var _exterior: Node3D
var _grounds: Node3D
var _lights: Array[Light3D] = []
var _windows: Array[Vector3] = []  # the end window's points, in the wing's frame
var _level := -1
var _rng := RandomNumberGenerator.new()
var _compat := false
var _chandeliers: Array[OmniLight3D] = []
var _portal: Array[Vector3] = []   # points round the portal, in the wing's frame
var _time := 0.0


## Whether the wing is wanted: not with --no-wing (?wing=0), nor without the gardens, which open its bay.
static func wanted() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--no-wing") or args.has("--no-gardens"):
		return false
	if OS.has_feature("web"):
		var q := "new URLSearchParams(location.search).get('%s') || ''"
		if str(JavaScriptBridge.eval(q % "wing", true)) == "0" or str(JavaScriptBridge.eval(q % "gardens", true)) == "0":
			return false
	return true


## observatory: the hall, for its dimensions and materials; core: the galactic core's direction.
func configure(observatory: Node3D, core: Vector3) -> void:
	_obs = observatory
	_core = core


func _ready() -> void:
	process_priority = 905  # after the gardens (900), which ask it what the camera sees
	var t0 := Time.get_ticks_usec()
	_rng.seed = 7319
	_outer = float(_obs.get("outer_radius"))
	_angle = TAU * (WING_BAY + 0.5) / int(_obs.get("bay_count"))
	var u := Vector3(cos(_angle), 0.0, sin(_angle))
	_frame = Transform3D(Basis(Vector3(u.z, 0.0, -u.x), Vector3.UP, u), u * _outer)
	_inv = _frame.affine_inverse()
	_m = _obs.get("_m")
	_materials()
	_interior = _group("Interior", _frame)
	_exterior = _group("Exterior", _frame)
	_grounds = _group("Grounds", Transform3D())
	_build_portal()
	_build_vestibule()
	for j in BAYS:
		_build_bay(j)
	for k in BAYS + 1:
		_build_pier_line(k)
	_build_vault()
	_build_end_walls()
	_build_shell()
	_build_terrace()
	_build_grounds()
	_build_busts()
	_build_mirrors()
	_build_chandeliers()
	_build_lights()
	_build_probes()
	_flush()
	stats.solids = _solids.size()
	stats.build_ms = snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.1)


func _group(node_name: String, xf: Transform3D) -> Node3D:
	var g := Node3D.new()
	g.name = node_name
	g.transform = xf
	add_child(g)
	return g


# --- Materials ------------------------------------------------------------------------------------

func _materials() -> void:
	_compat = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	# Inside, warm limestone (assets/wing_interior.gdshader) rather than the hall's blue-grey marble,
	# under lamplight; the hall's own wood, books and floor.
	var lime := ShaderMaterial.new()
	lime.shader = load(INTERIOR_SHADER_PATH)
	if ResourceLoader.exists(STONE_TEX_PATH):
		lime.set_shader_parameter("detail_tex", load(STONE_TEX_PATH))
	else:
		lime.set_shader_parameter("detail", 0.0)
	_mat.pier = lime
	_mat.dark = _m.get("stone_dark", _m.get("stone"))
	_mat.wood = _m.get("wood")
	# The floor: cream and dark marble squares on the diagonal, polished, so that the chandeliers stand
	# in it (assets/wing_interior.gdshader's checker).
	var paved := ShaderMaterial.new()
	paved.shader = lime.shader
	paved.set_shader_parameter("detail_tex", lime.get_shader_parameter("detail_tex"))
	paved.set_shader_parameter("detail", lime.get_shader_parameter("detail"))
	paved.set_shader_parameter("checker", 0.85)
	paved.set_shader_parameter("tint", Vector3(0.44, 0.38, 0.3))
	paved.set_shader_parameter("tint2", Vector3(0.1, 0.085, 0.075))
	paved.set_shader_parameter("checker_roughness", 0.2)
	_mat.floor = paved
	# Under Compatibility the nave's shadows took the sky's blue ambient (shots/wing2h-gl_compatibility):
	# a warm fill there for the bounce Forward+ gets from SDFGI.
	lime.set_shader_parameter("compat_fill", Vector3(0.42, 0.28, 0.13))
	paved.set_shader_parameter("compat_fill", Vector3(0.24, 0.16, 0.08))
	_mat.lamp = _m.get("shelf_light")
	_mat.bronze = _m.get("bronze")
	# Gilt that catches the lamps rather than glowing: the hall's gilt glows by itself, and its thin
	# bands read here as neon tubes (artpass/foundation/shots/wing1-forward_plus). Under Compatibility a
	# fully metallic surface with little to reflect comes out black: half metallic there.
	var gilt := StandardMaterial3D.new()
	gilt.albedo_color = Color(0.8, 0.6, 0.3)
	gilt.metallic = 0.45 if _compat else 0.9
	gilt.roughness = 0.4
	gilt.emission_enabled = true
	gilt.emission = Color(1.0, 0.7, 0.35)
	gilt.emission_energy_multiplier = 0.06
	_mat.gold = gilt
	# Looking glass: SSR and the wing's reflection probes under Forward+, the rays in the native build.
	var mirror := StandardMaterial3D.new()
	mirror.albedo_color = Color(0.86, 0.87, 0.9)
	mirror.metallic = 1.0
	mirror.roughness = 0.04
	if _compat:
		# Under Compatibility the vestibule's probe holds the nave's vault dark, and a glass seen aslant
		# from the portal showed it as black voids (artpass/foundation/shots/compat-wing4/portal.png): there
		# an old glass's haze, a little lamplight on it and a faint warm glow.
		mirror.metallic = 0.85
		mirror.roughness = 0.08
		mirror.emission_enabled = true
		mirror.emission = Color(1.0, 0.82, 0.6)
		mirror.emission_energy_multiplier = 0.05
	_mat.mirror = mirror
	var candle := StandardMaterial3D.new()
	candle.albedo_color = Color(0.9, 0.85, 0.74)
	candle.roughness = 0.6
	candle.emission_enabled = true
	candle.emission = Color(1.0, 0.8, 0.55)
	candle.emission_energy_multiplier = 0.25
	_mat.candle = candle
	var carpet := ShaderMaterial.new()
	carpet.shader = load(CARPET_SHADER_PATH)
	carpet.set_shader_parameter("z0", NAVE_Z0)
	carpet.set_shader_parameter("repeat", PITCH)
	_mat.carpet = carpet
	# The vault's coffers, painted midnight blue between their gilt-beaded battens.
	var coffer := StandardMaterial3D.new()
	coffer.albedo_color = Color(0.035, 0.05, 0.1)
	coffer.roughness = 0.62
	_mat.coffer = coffer
	if ResourceLoader.exists(MARBLE_SHADER_PATH) and ResourceLoader.exists(MARBLE_PATH):
		var marble := ShaderMaterial.new()
		marble.shader = load(MARBLE_SHADER_PATH)
		marble.set_shader_parameter("marble", load(MARBLE_PATH))
		marble.set_shader_parameter("marble_tile", 0.3)
		_mat.marble = marble
	else:
		_mat.marble = _m.get("stone")
	# Outside, self-lit as the gardens are (assets/wing_stone.gdshader): the wing's walls floodlit from
	# the terrace and lit by its lanterns, the terrace's retaining wall and the hall's plinth from the
	# court below.
	var lanterns := {"base_y": 0.0, "lamp_x": TERRACE_HW - 0.25, "lamp_y": 1.45}
	_mat.ext = _stone_mat(0, Color(0.56, 0.53, 0.48), lanterns.merged({"uplight": 0.3, "up_reach": 9.0, "lamp_energy": 0.7}))
	# The windows' glass seen from outside, lit from within (one-sided: from inside, the night through it).
	_mat.pane = _stone_mat(3, Color.WHITE, {"lamp_energy": 0.16})
	_mat.roof = _stone_mat(1, Color(0.2, 0.22, 0.25), {"uplight": 0.0, "city_energy": 0.14, "lamp_energy": 0.0})
	_mat.paving = _stone_mat(2, Color(0.42, 0.4, 0.37), lanterns.merged({"uplight": 0.0, "lamp_reach": 5.0}))
	_mat.retaining = _stone_mat(0, Color(0.5, 0.48, 0.44), {"uplight": 0.6, "lamp_energy": 0.0, "rustic": 1.0, "ashlar": Vector2(2.0, 0.9)})
	_mat.court = _stone_mat(2, Color(0.3, 0.29, 0.27), {"uplight": 0.0, "lamp_energy": 0.0})
	_mat.plinth = _stone_mat(0, Color(0.5, 0.48, 0.44), {"uplight": 0.6, "cylinder": 1.0, "lamp_energy": 0.0})
	_mat.ext_lamp = _stone_mat(3, Color.WHITE, {})
	_book_full = _obs.call("_book_mesh")
	_book_low = _obs.call("low_poly", "book")


func _stone_mat(kind: int, albedo: Color, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(STONE_SHADER_PATH)
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("albedo", albedo)
	m.set_shader_parameter("core_dir", _core)
	m.set_shader_parameter("base_y", PODIUM_Y)
	m.set_shader_parameter("wing_origin", _frame.origin)
	m.set_shader_parameter("wing_x", _frame.basis.x)
	m.set_shader_parameter("wing_z", _frame.basis.z)
	m.set_shader_parameter("lamp_z1", NAVE_Z0 + BAYS * PITCH + END_T + TERRACE_END - 1.0)
	if ResourceLoader.exists(STONE_TEX_PATH) and kind != 1:
		m.set_shader_parameter("detail_tex", load(STONE_TEX_PATH))
		m.set_shader_parameter("stone_detail", 1.0)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


# --- Parts ----------------------------------------------------------------------------------------

## The chunk a point of the wing's frame belongs to: 0 the portal and vestibule, 1 to BAYS the bays,
## BAYS + 1 the far end. Each chunk's meshes are drawn apart, so that the frustum culls them and no
## mesh under Compatibility meets more lights than it takes.
static func _chunk(z: float) -> int:
	if z < NAVE_Z0:
		return 0
	return clampi(int(floor((z - NAVE_Z0) / PITCH)) + 1, 1, BAYS + 1)


func _put(chunk: int, key: String, part: Array) -> void:
	var k := "%d/%s" % [chunk, key]
	if _compat:
		# Under Compatibility a mesh takes the 8 lights that score best for it, the distance from its
		# box's middle over range times energy (servers/rendering/renderer_scene_cull.cpp): a bay's
		# meshes from wall to wall had their middle on the axis, where the chandeliers beat the alcoves'
		# lamps, and the alcoves went dark (artpass/foundation/shots/compat-all1/wing_alcove.png). There
		# each side is drawn apart.
		var mesh: Mesh = part[0]
		var xf: Transform3D = part[1]
		k += "/" + "LCR"[_side(xf * mesh.get_aabb().get_center())]
	if not _parts.has(k):
		_parts[k] = []
	(_parts[k] as Array).append(part)


## The side of the aisle a point of the wing's frame is on: 0 left, 1 the middle, 2 right.
static func _side(p: Vector3) -> int:
	return 0 if p.x < -2.0 else (2 if p.x > 2.0 else 1)


## A box from its two corners, in the wing's frame, into the chunk of its middle.
func _box(key: String, lo: Vector3, hi: Vector3, chunk := -1) -> void:
	var b := BoxMesh.new()
	b.size = (hi - lo).abs()
	var c := (lo + hi) * 0.5
	_put(_chunk(c.z) if chunk < 0 else chunk, key, [b, Transform3D(Basis(), c)])


## The box and its mirror across the axis.
func _pair(key: String, lo: Vector3, hi: Vector3, chunk := -1) -> void:
	_box(key, lo, hi, chunk)
	_box(key, Vector3(-hi.x, lo.y, lo.z), Vector3(-lo.x, hi.y, hi.z), chunk)


func _mesh_part(chunk: int, key: String, mesh: Mesh, xf := Transform3D()) -> void:
	_put(chunk, key, [mesh, xf])


## Every chunk's parts merged, one mesh per material, and its books.
func _flush() -> void:
	var meshes := 0
	var tris := 0
	var groups := {}
	for k: String in _parts:
		var bits := k.split("/")
		var chunk := int(bits[0])
		var key := bits[1]
		var side := bits[2] if bits.size() > 2 else ""
		var outside := key in ["ext", "roof", "ext_lamp", "paving", "retaining", "pane"]
		var parent: Node3D = _exterior if outside else _interior
		var gname := ("Out%d" if outside else "Bay%d") % chunk
		var g: Node3D = groups.get(gname)
		if g == null:
			g = Node3D.new()
			g.name = gname
			parent.add_child(g)
			groups[gname] = g
		var mesh: ArrayMesh = _obs.call("_merge", _parts[k])
		var mi := MeshInstance3D.new()
		mi.name = key.capitalize().replace(" ", "") + side
		mi.mesh = mesh
		mi.material_override = _mat.get(key)
		mi.layers = 1 | LAYER
		if key == "mirror" and _compat:
			mi.layers = MIRROR_LAYER  # out of the probes' captures (_build_probes)
		if outside:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		elif key in ["lamp", "gold", "carpet", "candle", "mirror"]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(mi)
		meshes += 1
		tris += mesh.surface_get_array_len(0) / 3
	_parts.clear()
	var books := 0
	for at: int in _books:
		var out: Dictionary = _books[at]
		if (out.xf as Array).is_empty():
			continue
		var chunk := floori(at / 3.0)
		var side := at - chunk * 3
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = _book_full
		mm.instance_count = (out.xf as Array).size()
		for i in mm.instance_count:
			mm.set_instance_transform(i, out.xf[i])
			mm.set_instance_color(i, out.col[i])
			mm.set_instance_custom_data(i, out.cus[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Books%d" % chunk + ("" if not _compat else "LCR"[side])
		mmi.multimesh = mm
		mmi.material_override = _m.get("book_bindings")
		mmi.layers = 1 | LAYER
		# The cases and the piers cast the chandeliers' shadows; a book apiece would cost each shadowed
		# light a pass over a million triangles.
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var g: Node3D = groups.get("Bay%d" % chunk)
		(g if g != null else _interior).add_child(mmi)
		_book_mmis.append(mmi)
		books += mm.instance_count
	stats.meshes = meshes
	stats.triangles = tris
	stats.books = books
	stats.book_meshes = _book_mmis.size()


# --- Shapes ---------------------------------------------------------------------------------------

## A flat convex face from its corners, its triangles facing along n (Godot's front faces wind
## clockwise as seen from in front).
static func _face(st: SurfaceTool, pts: Array, n: Vector3) -> void:
	for k in range(1, pts.size() - 1):
		var p0: Vector3 = pts[0]
		var p1: Vector3 = pts[k]
		var p2: Vector3 = pts[k + 1]
		if (p1 - p0).cross(p2 - p0).dot(n) > 0.0:
			var t := p1
			p1 = p2
			p2 = t
		for p: Vector3 in [p0, p1, p2]:
			st.set_normal(n)
			st.set_uv(Vector2(p.x + p.z, p.y))
			st.add_vertex(p)


## A quad with a normal at each corner, wound by their mean.
static func _quad_n(st: SurfaceTool, pts: Array, ns: Array) -> void:
	var avg: Vector3 = (ns[0] + ns[1] + ns[2] + ns[3]) as Vector3
	var order := [0, 1, 2, 0, 2, 3]
	var p0: Vector3 = pts[0]
	var p1: Vector3 = pts[1]
	var p2: Vector3 = pts[2]
	if (p1 - p0).cross(p2 - p0).dot(avg) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for i: int in order:
		var p: Vector3 = pts[i]
		st.set_normal(ns[i])
		st.set_uv(Vector2(p.x + p.z, p.y))
		st.add_vertex(p)


## A point of the half ellipse (a across, b up, springing at y0), t from 0 (x = a) to PI (x = -a), and
## its normal towards the inside.
static func _ell(a: float, b: float, y0: float, t: float) -> Vector3:
	return Vector3(a * cos(t), y0 + b * sin(t), 0.0)


static func _ell_n(a: float, b: float, t: float) -> Vector3:
	return -Vector3(cos(t) / a, sin(t) / b, 0.0).normalized()


## The inside of a half-elliptic barrel from z0 to z1, inset by `inset` along its normal.
static func _barrel(st: SurfaceTool, a: float, b: float, y0: float, z0: float, z1: float, seg: int, t0 := 0.0, t1 := PI, inset := 0.0) -> void:
	for i in seg:
		var ta := lerpf(t0, t1, float(i) / seg)
		var tb := lerpf(t0, t1, float(i + 1) / seg)
		var na := _ell_n(a, b, ta)
		var nb := _ell_n(a, b, tb)
		var pa := _ell(a, b, y0, ta) + na * inset
		var pb := _ell(a, b, y0, tb) + nb * inset
		_quad_n(st, [pa + Vector3(0, 0, z0), pb + Vector3(0, 0, z0), pb + Vector3(0, 0, z1), pa + Vector3(0, 0, z1)], [na, nb, nb, na])


## A rib round the barrel at z, `w` wide and standing `d` off it: its face and its two sides.
static func _rib(st: SurfaceTool, a: float, b: float, y0: float, z: float, w: float, d: float, seg: int) -> void:
	_barrel(st, a, b, y0, z - w * 0.5, z + w * 0.5, seg, 0.0, PI, d)
	for i in seg:
		var ta := PI * i / seg
		var tb := PI * (i + 1) / seg
		var na := _ell_n(a, b, ta)
		var nb := _ell_n(a, b, tb)
		var pa := _ell(a, b, y0, ta)
		var pb := _ell(a, b, y0, tb)
		for side: float in [-1.0, 1.0]:
			var zz := Vector3(0, 0, z + side * w * 0.5)
			var n := Vector3(0, 0, side)
			_face(st, [pa + zz, pb + zz, pb + nb * d + zz, pa + na * d + zz], n)


## A batten along the barrel at angle t, from z0 to z1: `w` wide, standing `d` off it.
static func _batten(st: SurfaceTool, a: float, b: float, y0: float, t: float, z0: float, z1: float, w: float, d: float) -> void:
	var n := _ell_n(a, b, t)
	var p := _ell(a, b, y0, t)
	var tan := Vector3(-n.y, n.x, 0.0)
	var c0 := p - tan * w * 0.5
	var c1 := p + tan * w * 0.5
	var zs := [Vector3(0, 0, z0), Vector3(0, 0, z1)]
	_face(st, [c0 + n * d + zs[0], c1 + n * d + zs[0], c1 + n * d + zs[1], c0 + n * d + zs[1]], n)
	_face(st, [c0 + zs[0], c0 + n * d + zs[0], c0 + n * d + zs[1], c0 + zs[1]], -tan)
	_face(st, [c1 + zs[0], c1 + n * d + zs[0], c1 + n * d + zs[1], c1 + zs[1]], tan)


## A wall across the wing from z0 to z1 with an opening on its axis: `outline` is its left half, from
## the foot of the axis or of the opening round to the axis's top, then down the opening (see
## _wall_outline). Both faces, and every edge but those on the axis, where the two halves meet.
static func _wall(st: SurfaceTool, outline: PackedVector2Array, z0: float, z1: float) -> void:
	var tri := Geometry2D.triangulate_polygon(outline)
	var area := 0.0
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		area += a.x * b.y - b.x * a.y
	for mirror: float in [1.0, -1.0]:
		for i in range(0, tri.size(), 3):
			var pts := []
			for k in 3:
				var q := outline[tri[i + k]]
				pts.append(Vector3(q.x * mirror, q.y, 0.0))
			for zz: float in [z0, z1]:
				var face := []
				for p: Vector3 in pts:
					face.append(p + Vector3(0, 0, zz))
				_face(st, face, Vector3(0, 0, -1.0 if zz == z0 else 1.0))
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i + 1) % outline.size()]
			if absf(a.x) < 1e-4 and absf(b.x) < 1e-4:
				continue
			var e := b - a
			var n2 := Vector2(e.y, -e.x).normalized() * (1.0 if area > 0.0 else -1.0)
			var n := Vector3(n2.x * mirror, n2.y, 0.0)
			var pa := Vector3(a.x * mirror, a.y, 0.0)
			var pb := Vector3(b.x * mirror, b.y, 0.0)
			_face(st, [pa + Vector3(0, 0, z0), pb + Vector3(0, 0, z0), pb + Vector3(0, 0, z1), pa + Vector3(0, 0, z1)], n)


## The left half of a wall's outline: `profile` from (-w, 0) up to the axis's top (x = 0), then down an
## opening on the axis, `hw` wide, round-headed from `spring`, from `sill` (0: a doorway).
static func _wall_outline(profile: Array, hw: float, sill: float, spring: float, seg := 12) -> PackedVector2Array:
	var out := PackedVector2Array()
	if sill > 0.0:
		out.append(Vector2(0.0, 0.0))
	else:
		out.append(Vector2(-hw, 0.0))
	for p: Vector2 in profile:
		out.append(p)
	out.append(Vector2(0.0, spring + hw))
	for i in range(1, seg + 1):
		var t := PI * 0.5 + PI * 0.5 * i / seg
		out.append(Vector2(hw * cos(t), spring + hw * sin(t)))
	if sill > 0.0:
		out.append(Vector2(-hw, sill))
		out.append(Vector2(0.0, sill))
	return out


## The inside's section, left half, from the floor at the wall up to the vault's crown.
static func _section(seg := 16) -> Array:
	var pts := [Vector2(-WALL_IN, 0.0), Vector2(-WALL_IN, SIDE_CEILING), Vector2(-VAULT_A, SIDE_CEILING)]
	for i in seg + 1:
		var t := PI - PI * 0.5 * i / seg
		pts.append(Vector2(VAULT_A * cos(t), ENTABLATURE + VAULT_B * sin(t)))
	return pts


## The outside's, under the roof: the wall up to the eave, the gable up to just under the ridge.
static func _gable() -> Array:
	return [Vector2(-WALL_OUT, 0.0), Vector2(-WALL_OUT, _roof_y(WALL_OUT) - 0.1), Vector2(0.0, RIDGE_Y - 0.1)]


## The roof's top over x.
static func _roof_y(x: float) -> float:
	return RIDGE_Y - (RIDGE_Y - EAVE_Y) * absf(x) / ROOF_HW


# --- The portal and the vestibule -----------------------------------------------------------------

func _build_portal() -> void:
	var hw := PORTAL_W * 0.5
	# On the hall's side, as the glazed bays: the recess's face from the floor to the walkway, piers either
	# side of the opening and a lintel, in dark stone; an architrave round the opening in the lighter
	# stone, a keystone, and a gilt bead inside it.
	_pair("dark", Vector3(hw, 0.0, RECESS_Z), Vector3(3.2, WALKWAY, 0.0), 0)
	_box("dark", Vector3(-hw, PORTAL_H, RECESS_Z), Vector3(hw, WALKWAY, 0.0), 0)
	_pair("pier", Vector3(hw, 0.0, RECESS_Z - 0.08), Vector3(hw + 0.32, PORTAL_H + 0.32, RECESS_Z), 0)
	_box("pier", Vector3(-hw - 0.32, PORTAL_H, RECESS_Z - 0.08), Vector3(hw + 0.32, PORTAL_H + 0.32, RECESS_Z), 0)
	_box("pier", Vector3(-hw - 0.45, PORTAL_H + 0.32, RECESS_Z - 0.11), Vector3(hw + 0.45, PORTAL_H + 0.46, RECESS_Z), 0)
	_box("pier", Vector3(-0.26, PORTAL_H - 0.12, RECESS_Z - 0.15), Vector3(0.26, PORTAL_H + 0.5, RECESS_Z), 0)
	# Over the architrave, a stone canopy under the hall's walkway, out to its edge, on two stepped
	# consoles, a gilt bead under its front: the recess's dark face and the walkway's dark underside left
	# a black gap there, over which the walkway's shelves read as a bar of books in the air (the author on
	# version 42, 2026-10-13). 12 mm under the walkway: coplanar faces fight in WebGL.
	var top := PORTAL_H + 0.46
	_box("pier", Vector3(-CANOPY_HW, top, CANOPY_Z), Vector3(CANOPY_HW, WALKWAY - 0.012, RECESS_Z), 0)
	_box("gold", Vector3(-CANOPY_HW, top - 0.03, CANOPY_Z - 0.02), Vector3(CANOPY_HW, top + 0.03, CANOPY_Z + 0.04), 0)
	_pair("pier", Vector3(CANOPY_HW - 0.34, top - 0.3, -1.7), Vector3(CANOPY_HW, top, RECESS_Z), 0)
	_pair("pier", Vector3(CANOPY_HW - 0.34, top - 0.62, -0.95), Vector3(CANOPY_HW, top - 0.3, RECESS_Z), 0)
	_pair("gold", Vector3(hw - 0.03, 0.0, RECESS_Z - 0.1), Vector3(hw, PORTAL_H, RECESS_Z - 0.04), 0)
	_box("gold", Vector3(-hw, PORTAL_H - 0.03, RECESS_Z - 0.1), Vector3(hw, PORTAL_H, RECESS_Z - 0.04), 0)
	# The reveals through the hall's wall, a little inside its cut (palace_gardens.gd _open_bays), out to
	# the vestibule's width.
	# Behind the recess's face, so that no face lies on one of its own; the soffit 6 mm under the wall's.
	_pair("pier", Vector3(hw - 0.02, 0.0, 0.0), Vector3(VEST_HW + 0.4, PORTAL_H, VEST_Z0 + 0.4), 0)
	_box("pier", Vector3(-VEST_HW - 0.4, PORTAL_H - 0.006, 0.0), Vector3(VEST_HW + 0.4, VEST_SPRING + VEST_HW + 0.4, VEST_Z0 + 0.4), 0)
	# The floor through, 6 mm under the hall's where they overlap: coplanar faces fight in WebGL.
	_box("floor", Vector3(-hw, -0.3, -1.2), Vector3(hw, -0.006, VEST_Z0 + 0.4), 0)
	for x: float in [-hw, 0.0, hw]:
		for y: float in [0.2, PORTAL_H * 0.5, PORTAL_H]:
			_portal.append(Vector3(x, y, 0.0))


func _build_vestibule() -> void:
	var z0 := VEST_Z0 + 0.4
	var z1 := NAVE_Z0 - NEAR_T
	# Its walls, a floor with gilt lines leading in, a barrel vault with two gilt ribs.
	_pair("pier", Vector3(VEST_HW, 0.0, z0), Vector3(VEST_HW + 0.4, VEST_SPRING, z1), 0)
	_pair("gold", Vector3(VEST_HW - 0.02, VEST_SPRING - 0.12, z0), Vector3(VEST_HW, VEST_SPRING - 0.06, z1), 0)
	_box("floor", Vector3(-VEST_HW, -0.3, z0), Vector3(VEST_HW, 0.0, z1 + 0.1), 0)
	_pair("gold", Vector3(1.55, 0.0, z0), Vector3(1.6, 0.004, NAVE_Z0), 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_barrel(st, VEST_HW, VEST_HW, VEST_SPRING, z0, z1, 16)
	_mesh_part(0, "pier", st.commit())
	var ribs := SurfaceTool.new()
	ribs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z: float in [z0 + 0.8, z1 - 0.8]:
		_rib(ribs, VEST_HW, VEST_HW, VEST_SPRING, z, 0.16, 0.06, 16)
	_mesh_part(0, "gold", ribs.commit())
	# Lanterns on bronze brackets, either side of each wall's looking glass (_build_mirrors).
	for s: float in [-1.0, 1.0]:
		for z: float in [z0 + 0.32, z1 - 0.32]:
			var at := Vector3(s * (VEST_HW - 0.3), 3.1, z)
			_box("bronze", Vector3(s * (VEST_HW - 0.34), 2.86, at.z - 0.04), Vector3(s * VEST_HW, 2.92, at.z + 0.04), 0)
			var globe := SphereMesh.new()
			globe.radius = 0.11
			globe.height = 0.26
			globe.radial_segments = 12
			globe.rings = 6
			_mesh_part(0, "lamp", globe, Transform3D(Basis(), at))
	# The near end wall, its doorway round-headed as the vestibule's vault.
	var near := SurfaceTool.new()
	near.begin(Mesh.PRIMITIVE_TRIANGLES)
	_wall(near, _wall_outline(_section(), VEST_HW, 0.0, VEST_SPRING), z1, NAVE_Z0)
	_mesh_part(1, "pier", near.commit())
	# An archivolt round the doorway on the nave's side, gilt.
	var arch := SurfaceTool.new()
	arch.begin(Mesh.PRIMITIVE_TRIANGLES)
	_arch_ring(arch, VEST_HW, VEST_HW + 0.3, VEST_SPRING, NAVE_Z0, NAVE_Z0 + 0.06)
	_mesh_part(1, "pier", arch.commit())
	_pair("pier", Vector3(VEST_HW, 0.0, NAVE_Z0), Vector3(VEST_HW + 0.3, VEST_SPRING, NAVE_Z0 + 0.06), 1)


## A moulding round a round head: from r0 to r1 about its spring's middle, between z0 and z1, its face
## towards +z (facing 1) or -z (facing -1), and its inner and outer sides.
static func _arch_ring(st: SurfaceTool, r0: float, r1: float, spring: float, z0: float, z1: float, facing := 1.0, seg := 16) -> void:
	for i in seg:
		var ta := PI * i / seg
		var tb := PI * (i + 1) / seg
		var a0 := Vector3(r0 * cos(ta), spring + r0 * sin(ta), 0)
		var b0 := Vector3(r0 * cos(tb), spring + r0 * sin(tb), 0)
		var a1 := Vector3(r1 * cos(ta), spring + r1 * sin(ta), 0)
		var b1 := Vector3(r1 * cos(tb), spring + r1 * sin(tb), 0)
		var zf := Vector3(0, 0, z1 if facing > 0.0 else z0)
		_face(st, [a0 + zf, b0 + zf, b1 + zf, a1 + zf], Vector3(0, 0, facing))
		var no := Vector3(cos((ta + tb) * 0.5), sin((ta + tb) * 0.5), 0)
		_face(st, [a1 + Vector3(0, 0, z0), b1 + Vector3(0, 0, z0), b1 + Vector3(0, 0, z1), a1 + Vector3(0, 0, z1)], no)
		_face(st, [a0 + Vector3(0, 0, z0), b0 + Vector3(0, 0, z0), b0 + Vector3(0, 0, z1), a0 + Vector3(0, 0, z1)], -no)


# --- The bays -------------------------------------------------------------------------------------

## Where the bay lines are: the piers and the bookcases behind them.
static func _line_z(k: int) -> float:
	return NAVE_Z0 + k * PITCH


## Bay j (0 to BAYS - 1) between lines j and j + 1, on both sides: the floor, the back cases and the
## spines' faces in the alcoves, the gallery over them with its balustrade, the upper cases either side
## of a window, the side ceiling, the entablature on the piers and the cornice's lamps.
func _build_bay(j: int) -> void:
	var c := j + 1
	var z0 := _line_z(j)
	var z1 := _line_z(j + 1)
	var zc := (z0 + z1) * 0.5
	_box("floor", Vector3(-WALL_IN, -0.3, z0), Vector3(WALL_IN, 0.0, z1), c)
	# The aisle's runner, with a gilt line either side of it.
	_box("carpet", Vector3(-1.2, 0.0, z0), Vector3(1.2, 0.012, z1), c)
	_pair("gold", Vector3(1.2, 0.0, z0), Vector3(1.26, 0.014, z1), c)
	_pair("gold", Vector3(AISLE_HW - 0.85, 0.0, z0), Vector3(AISLE_HW - 0.8, 0.004, z1), c)
	var rows := roundi((CASE_TOP - PLINTH) / ROW_PITCH)
	var pitch := (CASE_TOP - PLINTH) / rows
	var urows := roundi((UPPER_TOP - GALLERY_Y - 0.12) / ROW_PITCH)
	var upitch := (UPPER_TOP - GALLERY_Y - 0.12) / urows
	for s: float in [-1.0, 1.0]:
		var sx := func(x0: float, x1: float) -> Vector2: return Vector2(minf(s * x0, s * x1), maxf(s * x0, s * x1))
		# The back case, from spine to spine.
		var a := z0 + 0.5
		var b := z1 - 0.5
		var cx: Vector2 = sx.call(CASE_FRONT, WALL_IN)
		_box("wood", Vector3(cx.x, 0.0, a), Vector3(cx.y, PLINTH - 0.03, b), c)
		_box("wood", Vector3(cx.x, CASE_TOP - 0.03, a), Vector3(cx.y, CASE_TOP + 0.1, b), c)
		var back: Vector2 = sx.call(WALL_IN - 0.06, WALL_IN)
		_box("wood", Vector3(back.x, 0.0, a), Vector3(back.y, GALLERY_Y, b), c)
		var base := Transform3D(Basis(Vector3(0, 0, s), Vector3.UP, Vector3(-s, 0, 0)), Vector3(s * (CASE_FRONT + 0.3), 0.0, zc))
		for r in rows + 1:
			var y := PLINTH + r * pitch
			_box("wood", Vector3(cx.x, y - 0.03, a), Vector3(cx.y, y + 0.03, b), c)
			if r < rows:
				_shelf(c, base, -(b - a) * 0.5 + 0.04, (b - a) * 0.5 - 0.04, y + 0.03, pitch - 0.06)
		# The gallery over the alcove and the piers' line: its floor, a fascia with a gilt band, and a
		# balustrade between the piers.
		var gx: Vector2 = sx.call(GALLERY_X, WALL_IN)
		_box("wood", Vector3(gx.x, GALLERY_Y - 0.28, z0), Vector3(gx.y, GALLERY_Y, z1), c)
		var fx: Vector2 = sx.call(GALLERY_X - 0.1, GALLERY_X)
		_box("wood", Vector3(fx.x, GALLERY_Y - 0.45, z0 + 0.5), Vector3(fx.y, GALLERY_Y + 0.05, z1 - 0.5), c)
		var bx: Vector2 = sx.call(GALLERY_X - 0.12, GALLERY_X - 0.1)
		_box("gold", Vector3(bx.x, GALLERY_Y - 0.24, z0 + 0.5), Vector3(bx.y, GALLERY_Y - 0.18, z1 - 0.5), c)
		var rx: Vector2 = sx.call(GALLERY_X + 0.02, GALLERY_X + 0.22)
		_box("wood", Vector3(rx.x, GALLERY_Y, z0 + 0.5), Vector3(rx.y, GALLERY_Y + 0.12, z1 - 0.5), c)
		var tx: Vector2 = sx.call(GALLERY_X, GALLERY_X + 0.24)
		_box("gold", Vector3(tx.x, GALLERY_Y + 0.95, z0 + 0.5), Vector3(tx.y, GALLERY_Y + 1.03, z1 - 0.5), c)
		var n := int((z1 - z0 - 1.0) / 0.24)
		var px: Vector2 = sx.call(GALLERY_X + 0.08, GALLERY_X + 0.16)
		for i in n:
			var z := z0 + 0.5 + (i + 0.5) * (z1 - z0 - 1.0) / n
			_box("wood", Vector3(px.x, GALLERY_Y + 0.12, z - 0.04), Vector3(px.y, GALLERY_Y + 0.95, z + 0.04), c)
		# Up on the gallery: the cases either side of the window, and the wall's inner skin round it.
		for half: float in [-1.0, 1.0]:
			var ua := zc + WINDOW.x + 0.2 if half > 0.0 else a
			var ub := b if half > 0.0 else zc - WINDOW.x - 0.2
			var y0 := GALLERY_Y + 0.12
			_box("wood", Vector3(cx.x, GALLERY_Y, ua), Vector3(cx.y, y0 - 0.03, ub), c)
			_box("wood", Vector3(cx.x, UPPER_TOP - 0.03, ua), Vector3(cx.y, UPPER_TOP + 0.12, ub), c)
			var ubase := Transform3D(base.basis, Vector3(base.origin.x, 0.0, (ua + ub) * 0.5))
			for r in urows + 1:
				var y := y0 + r * upitch
				_box("wood", Vector3(cx.x, y - 0.03, ua), Vector3(cx.y, y + 0.03, ub), c)
				if r < urows:
					_shelf(c, ubase, -(ub - ua) * 0.5 + 0.04, (ub - ua) * 0.5 - 0.04, y + 0.03, upitch - 0.06)
			_box("wood", Vector3(back.x, GALLERY_Y, ua), Vector3(back.y, UPPER_TOP + 0.1, ub), c)
			# Each case's upright beside the window.
			var ez := ua if half > 0.0 else ub
			_box("wood", Vector3(cx.x, GALLERY_Y, ez - 0.05), Vector3(cx.y, UPPER_TOP + 0.12, ez + 0.05), c)
		var skin: Vector2 = sx.call(WALL_IN, SKIN)
		_box("pier", Vector3(skin.x, UPPER_TOP, z0), Vector3(skin.y, SIDE_CEILING, z1), c)
		_box("pier", Vector3(skin.x, GALLERY_Y, z0), Vector3(skin.y, UPPER_TOP, zc - WINDOW.x), c)
		_box("pier", Vector3(skin.x, GALLERY_Y, zc + WINDOW.x), Vector3(skin.y, UPPER_TOP, z1), c)
		_box("pier", Vector3(skin.x, GALLERY_Y, zc - WINDOW.x), Vector3(skin.y, WINDOW.y, zc + WINDOW.x), c)
		_box("pier", Vector3(skin.x, WINDOW.z, zc - WINDOW.x), Vector3(skin.y, UPPER_TOP, zc + WINDOW.x), c)
		# The window's reveals in the lit stone, its sill, and its bronze mullion and transom.
		var rv: Vector2 = sx.call(WALL_IN - 0.12, WALL_OUT)
		_box("pier", Vector3(rv.x, WINDOW.y - 0.12, zc - WINDOW.x - 0.12), Vector3(rv.y, WINDOW.y, zc + WINDOW.x + 0.12), c)
		var mx: Vector2 = sx.call(SKIN + 0.3, SKIN + 0.38)
		_box("bronze", Vector3(mx.x, WINDOW.y, zc - 0.04), Vector3(mx.y, WINDOW.z, zc + 0.04), c)
		_box("bronze", Vector3(mx.x, 7.55, zc - WINDOW.x), Vector3(mx.y, 7.63, zc + WINDOW.x), c)
		# The side ceiling, its beams over the bay lines and the bay's middle.
		var cl: Vector2 = sx.call(PIER_X.y, WALL_IN)
		_box("wood", Vector3(cl.x, SIDE_CEILING, z0), Vector3(cl.y, SIDE_CEILING + 0.15, z1), c)
		for z: float in [z0 + 0.15, zc, z1 - 0.15]:
			_box("wood", Vector3(cl.x, SIDE_CEILING - 0.22, z - 0.12), Vector3(cl.y, SIDE_CEILING, z + 0.12), c)
		# The entablature on the piers: architrave, frieze with a gilt fillet, cornice; and on the
		# cornice, a lamp strip lighting the vault.
		var ax: Vector2 = sx.call(PIER_X.x - 0.1, PIER_X.y + 0.1)
		_box("pier", Vector3(ax.x, SIDE_CEILING, z0), Vector3(ax.y, 9.55, z1), c)
		var fr: Vector2 = sx.call(PIER_X.x - 0.05, PIER_X.y + 0.05)
		_box("wood", Vector3(fr.x, 9.55, z0), Vector3(fr.y, 9.85, z1), c)
		var gf: Vector2 = sx.call(PIER_X.x - 0.07, PIER_X.x - 0.05)
		_box("gold", Vector3(gf.x, 9.66, z0), Vector3(gf.y, 9.74, z1), c)
		var co: Vector2 = sx.call(PIER_X.x - 0.25, PIER_X.y + 0.25)
		_box("pier", Vector3(co.x, 9.85, z0), Vector3(co.y, ENTABLATURE, z1), c)
		var ls: Vector2 = sx.call(PIER_X.x - 0.2, PIER_X.x - 0.02)
		_box("lamp", Vector3(ls.x, ENTABLATURE, z0), Vector3(ls.y, ENTABLATURE + 0.04, z1), c)
	# The vault's coffers over the bay are in _build_vault.


## One shelf's books, from _fill_board in the base's frame (+z out of the case), into the chunk's.
## Keyed chunk * 3 + side: under Compatibility each side's books apart, as _put's parts; under Forward+
## one MultiMesh a chunk, the middle's.
func _shelf(chunk: int, base: Transform3D, x0: float, x1: float, y: float, clear: float) -> void:
	var at := chunk * 3 + (_side(base.origin) if _compat else 1)
	if not _books.has(at):
		_books[at] = {"xf": [], "col": [], "cus": [], "crystals": [], "series": 0, "leaning": 0, "lying": 0}
	_obs.call("_fill_board", _rng, base, x0, x1, y, clear, _books[at])


## Bay line k (0 to BAYS): either side, a pier of the giant order from the floor to the entablature,
## and behind it a bookcase out to the back cases, its books on both faces (one at the ends, against
## the end walls), its upper part a panelled partition between the gallery's bays; before the pier, a
## pedestal for a bust (_build_busts).
func _build_pier_line(k: int) -> void:
	var z := _line_z(k)
	var lo := z if k == 0 else z - 0.5
	var hi := z if k == BAYS else z + 0.5
	var c := clampi(k, 1, BAYS)
	var rows := roundi((CASE_TOP - PLINTH) / ROW_PITCH)
	var pitch := (CASE_TOP - PLINTH) / rows
	for s: float in [-1.0, 1.0]:
		var sx := func(x0: float, x1: float) -> Vector2: return Vector2(minf(s * x0, s * x1), maxf(s * x0, s * x1))
		var pl := lo - (0.1 if k > 0 else 0.0)
		var ph := hi + (0.1 if k < BAYS else 0.0)
		var px: Vector2 = sx.call(PIER_X.x - 0.1, PIER_X.y + 0.1)
		_box("pier", Vector3(px.x, 0.0, pl), Vector3(px.y, 0.5, ph), c)
		var sh: Vector2 = sx.call(PIER_X.x, PIER_X.y)
		_box("pier", Vector3(sh.x, 0.5, lo), Vector3(sh.y, 8.7, hi), c)
		_box("pier", Vector3(px.x, 8.7, pl), Vector3(px.y, SIDE_CEILING, ph), c)
		var ring: Vector2 = sx.call(PIER_X.x - 0.03, PIER_X.y + 0.03)
		for y: float in [0.5, 8.62]:
			_box("gold", Vector3(ring.x, y, lo - (0.03 if k > 0 else 0.0)), Vector3(ring.y, y + 0.06, hi + (0.03 if k < BAYS else 0.0)), c)
		# A sconce on the pier's face to the aisle, over the bust.
		if k > 0 and k < BAYS:
			var f := s * (PIER_X.x - 0.22)
			_box("bronze", Vector3(minf(f, s * PIER_X.x), 3.02, z - 0.04), Vector3(maxf(f, s * PIER_X.x), 3.08, z + 0.04), c)
			var globe := SphereMesh.new()
			globe.radius = 0.1
			globe.height = 0.24
			globe.radial_segments = 10
			globe.rings = 5
			_mesh_part(c, "lamp", globe, Transform3D(Basis(), Vector3(f, 3.24, z)))
			_solids.append(Rect2(minf(s * 2.6, s * 3.1), z - 0.26, 0.5, 0.52))
		_solids.append(Rect2(minf(s * (PIER_X.x - 0.1), s * WALL_IN), pl, WALL_IN - PIER_X.x + 0.1, ph - pl))
		# The bookcase behind the pier.
		var bx: Vector2 = sx.call(PIER_X.y, CASE_FRONT)
		_box("wood", Vector3(bx.x, 0.0, lo), Vector3(bx.y, PLINTH - 0.03, hi), c)
		_box("wood", Vector3(bx.x, CASE_TOP - 0.03, lo), Vector3(bx.y, CASE_TOP + 0.1, hi), c)
		_box("wood", Vector3(bx.x, 0.0, z - 0.03), Vector3(bx.y, CASE_TOP, z + 0.03), c)
		# Behind the cases' ends, solid back to the wall's skin.
		var bk: Vector2 = sx.call(CASE_FRONT, SKIN)
		_box("wood", Vector3(bk.x, 0.0, lo), Vector3(bk.y, GALLERY_Y - 0.28, hi), c)
		for face: float in [-1.0, 1.0]:
			if (k == 0 and face < 0.0) or (k == BAYS and face > 0.0):
				continue
			var fz := z + face * 0.5
			var fb := Transform3D(Basis(Vector3(face, 0, 0), Vector3.UP, Vector3(0, 0, face)), Vector3(s * (PIER_X.y + CASE_FRONT) * 0.5, 0.0, fz - face * 0.3))
			var w := CASE_FRONT - PIER_X.y
			for r in rows + 1:
				var y := PLINTH + r * pitch
				_box("wood", Vector3(bx.x, y - 0.03, minf(z, fz)), Vector3(bx.y, y + 0.03, maxf(z, fz)), c)
				if r < rows:
					_shelf(c if face < 0.0 or k == 0 else clampi(k + 1, 1, BAYS), fb, -w * 0.5 + 0.04, w * 0.5 - 0.04, y + 0.03, pitch - 0.06)
		# Up on the gallery, a panelled partition from the pier back to the wall, with a doorway through it
		# between bays, so that the gallery runs the wing's length.
		var up: Vector2 = sx.call(PIER_X.y, WALL_IN)
		var p0 := z - 0.15 if k > 0 else z
		var p1 := z + 0.15 if k < BAYS else z
		if k == 0 or k == BAYS:
			_box("wood", Vector3(up.x, GALLERY_Y, p0), Vector3(up.y, SIDE_CEILING, p1), c)
		else:
			var jamb0: Vector2 = sx.call(PIER_X.y, 4.6)
			var jamb1: Vector2 = sx.call(5.8, WALL_IN)
			var head: Vector2 = sx.call(4.6, 5.8)
			_box("wood", Vector3(jamb0.x, GALLERY_Y, p0), Vector3(jamb0.y, SIDE_CEILING, p1), c)
			_box("wood", Vector3(jamb1.x, GALLERY_Y, p0), Vector3(jamb1.y, SIDE_CEILING, p1), c)
			_box("wood", Vector3(head.x, GALLERY_Y + 2.4, p0), Vector3(head.y, SIDE_CEILING, p1), c)
			# A gilt bead round the doorway, on both faces.
			for fz: float in [p0 - 0.02, p1]:
				var bead: Vector2 = sx.call(4.6, 5.8)
				_box("gold", Vector3(bead.x, GALLERY_Y + 2.4, fz), Vector3(bead.y, GALLERY_Y + 2.46, fz + 0.02), c)


# --- The vault ------------------------------------------------------------------------------------

## The coffered barrel over the aisle, from the near end wall to the far one: a stone arch over each bay
## line; between them a grid of wooden battens, five along the vault and two across each bay, each with
## a gilt bead on its face; the coffers they frame painted midnight blue, a gilt rosette in each; a
## gilt boss on each arch's crown.
func _build_vault() -> void:
	var rosette := _ellipsoid(Vector3(0.13, 0.13, 0.04), 12, 6)
	for j in BAYS:
		var c := j + 1
		var z0 := _line_z(j)
		var z1 := _line_z(j + 1)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_barrel(st, VAULT_A, VAULT_B, ENTABLATURE, z0, z1, 24)
		_mesh_part(c, "coffer", st.commit())
		var arch := SurfaceTool.new()
		arch.begin(Mesh.PRIMITIVE_TRIANGLES)
		_rib(arch, VAULT_A, VAULT_B, ENTABLATURE, z1 if j + 1 < BAYS else z1 - 0.2, 0.42, 0.2, 24)
		if j == 0:
			_rib(arch, VAULT_A, VAULT_B, ENTABLATURE, z0 + 0.2, 0.42, 0.2, 24)
		_mesh_part(c, "pier", arch.commit())
		# The battens: along the vault, and across it a third and two thirds of the way between arches.
		var lo := z0 + 0.21
		var hi := z1 - 0.21
		var wood := SurfaceTool.new()
		wood.begin(Mesh.PRIMITIVE_TRIANGLES)
		var gilt := SurfaceTool.new()
		gilt.begin(Mesh.PRIMITIVE_TRIANGLES)
		for m in range(1, 6):
			_batten(wood, VAULT_A, VAULT_B, ENTABLATURE, PI * m / 6.0, lo, hi, 0.12, 0.12)
			_batten(gilt, VAULT_A, VAULT_B, ENTABLATURE, PI * m / 6.0, lo, hi, 0.03, 0.135)
		for k: int in [1, 2]:
			var zt := lo + (hi - lo) * k / 3.0
			_rib(wood, VAULT_A, VAULT_B, ENTABLATURE, zt, 0.12, 0.12, 24)
			_rib(gilt, VAULT_A, VAULT_B, ENTABLATURE, zt, 0.03, 0.135, 24)
		_mesh_part(c, "wood", wood.commit())
		_mesh_part(c, "gold", gilt.commit())
		# A rosette in each coffer, a little proud of the paint.
		for m in 6:
			var t := PI * (m + 0.5) / 6.0
			var nrm := _ell_n(VAULT_A, VAULT_B, t)
			var p := _ell(VAULT_A, VAULT_B, ENTABLATURE, t) + nrm * 0.02
			for i in 3:
				var zc := lo + (hi - lo) * (i + 0.5) / 3.0
				_mesh_part(c, "gold", rosette, Transform3D(Basis.looking_at(nrm, Vector3(0, 0, 1)), Vector3(p.x, p.y, zc)))
		var crown := _ell(VAULT_A, VAULT_B, ENTABLATURE, PI * 0.5)
		_box("gold", Vector3(-0.3, crown.y - 0.32, z1 - 0.3), Vector3(0.3, crown.y - 0.18, z1 + 0.3), c)


# --- The ends -------------------------------------------------------------------------------------

## The far end wall and its window, inside in the lit stone and outside in the self-lit (both layers
## with the same opening), the window's bronze tracery, and its surround inside.
func _build_end_walls() -> void:
	var end_z := _line_z(BAYS)
	var c := BAYS + 1
	var hw := END_WINDOW.x
	var inside := SurfaceTool.new()
	inside.begin(Mesh.PRIMITIVE_TRIANGLES)
	_wall(inside, _wall_outline(_section(), hw, END_WINDOW.y, END_WINDOW.z), end_z, end_z + 0.06)
	_mesh_part(c, "pier", inside.commit())
	var outside := SurfaceTool.new()
	outside.begin(Mesh.PRIMITIVE_TRIANGLES)
	_wall(outside, _wall_outline(_gable(), hw, END_WINDOW.y, END_WINDOW.z), end_z + 0.06, end_z + END_T)
	_mesh_part(c, "ext", outside.commit())
	# Inside: a surround and a gilt keystone, a sill, and a panelled dado under it across the wall.
	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	_arch_ring(ring, hw, hw + 0.36, END_WINDOW.z, end_z - 0.08, end_z, -1.0)
	_mesh_part(c, "pier", ring.commit())
	_pair("pier", Vector3(hw, END_WINDOW.y, end_z - 0.08), Vector3(hw + 0.36, END_WINDOW.z, end_z), c)
	_box("gold", Vector3(-0.22, END_WINDOW.z + hw - 0.05, end_z - 0.14), Vector3(0.22, END_WINDOW.z + hw + 0.45, end_z), c)
	_box("pier", Vector3(-hw - 0.4, END_WINDOW.y - 0.14, end_z - 0.22), Vector3(hw + 0.4, END_WINDOW.y, end_z + 0.3), c)
	_box("wood", Vector3(-WALL_IN, 0.0, end_z - 0.06), Vector3(WALL_IN, END_WINDOW.y - 0.14, end_z), c)
	# The tracery, out in the wall: a frame, two mullions, transoms, and spokes in the round head.
	var tz := end_z + 0.5
	var b := 0.05
	for x: float in [-hw, -hw / 3.0, hw / 3.0, hw]:
		var x0 := clampf(x - b, -hw, hw - 2.0 * b)
		_box("bronze", Vector3(x0, END_WINDOW.y, tz - 0.05), Vector3(x0 + 2.0 * b, END_WINDOW.z, tz + 0.05), c)
	for y: float in [END_WINDOW.y, 3.8, 6.6, END_WINDOW.z - b]:
		_box("bronze", Vector3(-hw, y, tz - 0.05), Vector3(hw, y + 2.0 * b, tz + 0.05), c)
	var tr := SurfaceTool.new()
	tr.begin(Mesh.PRIMITIVE_TRIANGLES)
	for facing: float in [-1.0, 1.0]:
		_arch_ring(tr, hw - 0.1, hw, END_WINDOW.z, tz - 0.05, tz + 0.05, facing)
		_arch_ring(tr, hw * 0.45, hw * 0.45 + 0.08, END_WINDOW.z, tz - 0.05, tz + 0.05, facing)
	_mesh_part(c, "bronze", tr.commit())
	for i in range(1, 6):
		var t := PI * i / 6.0
		var dir := Vector3(cos(t), sin(t), 0.0)
		var mid := Vector3(0, END_WINDOW.z, tz) + dir * (hw * 0.45 + hw - 0.1) * 0.5
		var spoke := BoxMesh.new()
		spoke.size = Vector3(hw * 0.55, 0.08, 0.1)
		_mesh_part(c, "bronze", spoke, Transform3D(Basis(Vector3.BACK, t), mid))
	for i in 13:
		var t := PI * i / 12.0
		_windows.append(Vector3(hw * cos(t), END_WINDOW.z + hw * sin(t), end_z + 0.5))
	_windows.append(Vector3(-hw, END_WINDOW.y, end_z + 0.5))
	_windows.append(Vector3(hw, END_WINDOW.y, end_z + 0.5))
	_windows.append(Vector3(0.0, (END_WINDOW.y + END_WINDOW.z) * 0.5, end_z + 0.5))
	# Its glass from outside, inside the tracery.
	_mesh_part(BAYS + 2, "pane", _arched(hw, END_WINDOW.y, END_WINDOW.z), Transform3D(Basis(), Vector3(0.0, 0.0, end_z + 0.42)))


# --- Outside --------------------------------------------------------------------------------------

## The walls outside the inner skin, with the gallery's windows through them, buttresses on the bay
## lines, an eave cornice, surrounds round the windows, the roof in lead, and the podium.
func _build_shell() -> void:
	var o := BAYS + 2  # outside: one chunk, drawn as one
	var end_z := _line_z(BAYS) + END_T
	var near := -1.0
	for s: float in [-1.0, 1.0]:
		var sx := func(x0: float, x1: float) -> Vector2: return Vector2(minf(s * x0, s * x1), maxf(s * x0, s * x1))
		var wx: Vector2 = sx.call(SKIN, WALL_OUT)
		_box("ext", Vector3(wx.x, -0.3, near), Vector3(wx.y, EAVE_Y, NAVE_Z0), o)
		_box("ext", Vector3(wx.x, -0.3, _line_z(BAYS)), Vector3(wx.y, EAVE_Y, end_z), o)
		for j in BAYS:
			var z0 := _line_z(j)
			var z1 := _line_z(j + 1)
			var zc := (z0 + z1) * 0.5
			_box("ext", Vector3(wx.x, -0.3, z0), Vector3(wx.y, WINDOW.y, z1), o)
			_box("ext", Vector3(wx.x, WINDOW.z, z0), Vector3(wx.y, EAVE_Y, z1), o)
			_box("ext", Vector3(wx.x, WINDOW.y, z0), Vector3(wx.y, WINDOW.z, zc - WINDOW.x), o)
			_box("ext", Vector3(wx.x, WINDOW.y, zc + WINDOW.x), Vector3(wx.y, WINDOW.z, z1), o)
			# The window's surround: jambs, a lintel with a keystone, a sill.
			var jx: Vector2 = sx.call(WALL_OUT, WALL_OUT + 0.12)
			_box("ext", Vector3(jx.x, WINDOW.y - 0.1, zc - WINDOW.x - 0.3), Vector3(jx.y, WINDOW.z, zc - WINDOW.x), o)
			_box("ext", Vector3(jx.x, WINDOW.y - 0.1, zc + WINDOW.x), Vector3(jx.y, WINDOW.z, zc + WINDOW.x + 0.3), o)
			_box("ext", Vector3(jx.x, WINDOW.z, zc - WINDOW.x - 0.4), Vector3(jx.y, WINDOW.z + 0.36, zc + WINDOW.x + 0.4), o)
			var kx: Vector2 = sx.call(WALL_OUT, WALL_OUT + 0.2)
			_box("ext", Vector3(kx.x, WINDOW.z - 0.1, zc - 0.2), Vector3(kx.y, WINDOW.z + 0.5, zc + 0.2), o)
			_box("ext", Vector3(kx.x, WINDOW.y - 0.22, zc - WINDOW.x - 0.4), Vector3(kx.y, WINDOW.y - 0.06, zc + WINDOW.x + 0.4), o)
		# Buttresses on the bay lines, and at the corners.
		for k in BAYS + 1:
			var z := _line_z(k)
			if k == BAYS:
				z = end_z - 0.5
			var bx: Vector2 = sx.call(WALL_OUT, WALL_OUT + 0.45)
			_box("ext", Vector3(bx.x, -0.3, z - 0.5), Vector3(bx.y, EAVE_Y - 0.7, z + 0.5), o)
			var cx: Vector2 = sx.call(WALL_OUT, WALL_OUT + 0.55)
			_box("ext", Vector3(cx.x, EAVE_Y - 0.7, z - 0.6), Vector3(cx.y, EAVE_Y - 0.45, z + 0.6), o)
		# The eave cornice, the plinth course.
		var ex: Vector2 = sx.call(WALL_OUT - 0.1, ROOF_HW + 0.05)
		_box("ext", Vector3(ex.x, EAVE_Y - 0.45, near), Vector3(ex.y, EAVE_Y - 0.05, end_z + 0.25), o)
		var px: Vector2 = sx.call(WALL_OUT, WALL_OUT + 0.25)
		_box("ext", Vector3(px.x, -0.3, near), Vector3(px.y, 0.9, end_z + 0.1), o)
	# The far end's cornice round the gable's foot, and the end's buttresses.
	_box("ext", Vector3(-WALL_OUT - 0.1, EAVE_Y - 0.45, end_z), Vector3(WALL_OUT + 0.1, EAVE_Y - 0.05, end_z + 0.25), o)
	for s: float in [-1.0, 1.0]:
		var x := s * (END_WINDOW.x + 1.6)
		_box("ext", Vector3(x - 0.45, -0.3, end_z), Vector3(x + 0.45, EAVE_Y - 0.7, end_z + 0.4), o)
	# The roof: two slopes of lead from the eaves to the ridge, their near edge following the hall's drum,
	# and a ridge roll.
	var roof := SurfaceTool.new()
	roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 12
	var drum := _outer + 0.42
	for s: float in [-1.0, 1.0]:
		var n := Vector3(s * (RIDGE_Y - EAVE_Y), ROOF_HW, 0.0).normalized()
		for i in seg:
			var xa := ROOF_HW * i / seg
			var xb := ROOF_HW * (i + 1) / seg
			var za := sqrt(drum * drum - xa * xa) - _outer
			var zb := sqrt(drum * drum - xb * xb) - _outer
			var pa := Vector3(s * xa, _roof_y(xa), 0.0)
			var pb := Vector3(s * xb, _roof_y(xb), 0.0)
			_face(roof, [pa + Vector3(0, 0, za), pb + Vector3(0, 0, zb), pb + Vector3(0, 0, end_z + 0.3), pa + Vector3(0, 0, end_z + 0.3)], n)
			# Its underside and the eave's edge.
			var d := Vector3(0, -0.25, 0)
			_face(roof, [pa + d + Vector3(0, 0, za), pb + d + Vector3(0, 0, zb), pb + d + Vector3(0, 0, end_z + 0.3), pa + d + Vector3(0, 0, end_z + 0.3)], -n)
		var e := Vector3(s * ROOF_HW, EAVE_Y, 0.0)
		var ze := sqrt(drum * drum - ROOF_HW * ROOF_HW) - _outer
		_face(roof, [e + Vector3(0, 0, ze), e + Vector3(0, -0.25, ze), e + Vector3(0, -0.25, end_z + 0.3), e + Vector3(0, 0, end_z + 0.3)], Vector3(s, 0, 0))
	# The gable's verge at the far end.
	var g0 := Vector3(-ROOF_HW, EAVE_Y, end_z + 0.3)
	var g1 := Vector3(0.0, RIDGE_Y, end_z + 0.3)
	var g2 := Vector3(ROOF_HW, EAVE_Y, end_z + 0.3)
	var dn := Vector3(0, -0.25, 0)
	_face(roof, [g0, g1, g1 + dn, g0 + dn], Vector3(0, 0, 1))
	_face(roof, [g1, g2, g2 + dn, g1 + dn], Vector3(0, 0, 1))
	_mesh_part(o, "roof", roof.commit())
	_box("roof", Vector3(-0.14, RIDGE_Y - 0.1, drum - _outer), Vector3(0.14, RIDGE_Y + 0.14, end_z + 0.3), o)
	# The gallery's windows' glass from outside, behind their mullions.
	for j in BAYS:
		var zc := (_line_z(j) + _line_z(j + 1)) * 0.5
		for s: float in [-1.0, 1.0]:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var x := s * (SKIN + 0.2)
			_face(st, [Vector3(x, WINDOW.y, zc - WINDOW.x), Vector3(x, WINDOW.y, zc + WINDOW.x), Vector3(x, WINDOW.z, zc + WINDOW.x), Vector3(x, WINDOW.z, zc - WINDOW.x)], Vector3(s, 0, 0))
			_mesh_part(o, "pane", st.commit())
	stats.end_z = end_z


## Behind the hall: its own plinth down to the court (on the gardens' side the terrace's wall is
## there), the court's paving round the wing's terrace, and a park's dark lawn beyond it out to where
## the night city's low streets take over (scripts/night_city.gd).
func _build_grounds() -> void:
	var plinth: ArrayMesh = _obs.call("ring_sector", _outer, _outer + 1.0, -0.02 - (PODIUM_Y - 0.6), PI - 0.06, TAU + 0.06, 96)
	_add(_grounds, "HallPlinth", plinth, _mat.plinth, Transform3D(Basis(), Vector3(0, PODIUM_Y - 0.6, 0)))
	var pave: ArrayMesh = _obs.call("ring_sector", ESPLANADE.x, ESPLANADE.y, 0.4, PI - 0.02, TAU + 0.02, 128)
	_add(_grounds, "Court", pave, _mat.court, Transform3D(Basis(), Vector3(0, PODIUM_Y - 0.3, 0)))
	var lawn := StandardMaterial3D.new()
	lawn.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lawn.albedo_color = Color(0.03, 0.045, 0.04)
	var park: ArrayMesh = _obs.call("ring_sector", ESPLANADE.y - 0.5, PARK, 0.05, PI - 0.02, TAU + 0.02, 128)
	_add(_grounds, "Park", park, lawn, Transform3D(Basis(), Vector3(0, PODIUM_Y - 0.62, 0)))


## The terrace the wing stands on, at the hall's floor, as the gardens' terrace before the glazed bays:
## its paving out from the hall's drum, a retaining wall down to the court, and along its edge the
## gardens' balustrade, pedestals and lanterns (palace_gardens.gd _build_terrace), their materials too.
func _build_terrace() -> void:
	var o := BAYS + 2
	var end_t := _line_z(BAYS) + END_T + TERRACE_END
	var drum := _outer + 0.42
	var hw := TERRACE_HW
	var near := sqrt(drum * drum - hw * hw) - _outer
	# The paving: from the drum's arc out to the far edge.
	var outline := PackedVector2Array()
	var seg := 24
	for i in seg + 1:
		var x := lerpf(-hw, hw, float(i) / seg)
		outline.append(Vector2(x, sqrt(drum * drum - x * x) - _outer))
	outline.append(Vector2(hw, end_t))
	outline.append(Vector2(-hw, end_t))
	var tri := Geometry2D.triangulate_polygon(outline)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, tri.size(), 3):
		var pts := []
		for k in 3:
			var q := outline[tri[i + k]]
			pts.append(Vector3(q.x, -0.012, q.y))
		_face(st, pts, Vector3.UP)
	_mesh_part(o, "paving", st.commit())
	# The retaining wall, and a coping on it under the balustrade.
	var wall_lo := near - 0.2
	for s: float in [-1.0, 1.0]:
		var sx := func(x0: float, x1: float) -> Vector2: return Vector2(minf(s * x0, s * x1), maxf(s * x0, s * x1))
		var wx: Vector2 = sx.call(hw, hw + 0.6)
		_box("retaining", Vector3(wx.x, PODIUM_Y - 0.4, wall_lo), Vector3(wx.y, -0.02, end_t + 0.6), o)
		var cx: Vector2 = sx.call(hw - 0.15, hw + 0.7)
		_box("retaining", Vector3(cx.x, -0.3, wall_lo), Vector3(cx.y, -0.02, end_t + 0.7), o)
	_box("retaining", Vector3(-hw - 0.6, PODIUM_Y - 0.4, end_t), Vector3(hw + 0.6, -0.02, end_t + 0.6), o)
	for s: float in [-1.0, 1.0]:
		var sx := func(x0: float, x1: float) -> Vector2: return Vector2(minf(s * x0, s * x1), maxf(s * x0, s * x1))
		var pc: Vector2 = sx.call(hw + 0.6, hw + 0.85)
		_box("retaining", Vector3(pc.x, PODIUM_Y - 0.4, wall_lo), Vector3(pc.y, PODIUM_Y + 0.9, end_t + 0.85), o)
		var sc: Vector2 = sx.call(hw + 0.6, hw + 0.72)
		_box("retaining", Vector3(sc.x, -0.62, wall_lo), Vector3(sc.y, -0.48, end_t + 0.72), o)
		var zp := 2.0
		while zp < end_t - 1.0:
			var pl: Vector2 = sx.call(hw + 0.6, hw + 0.9)
			_box("retaining", Vector3(pl.x, PODIUM_Y + 0.9, zp - 0.6), Vector3(pl.y, -0.62, zp + 0.6), o)
			zp += 9.6
	_box("retaining", Vector3(-hw - 0.85, PODIUM_Y - 0.4, end_t + 0.6), Vector3(hw + 0.85, PODIUM_Y + 0.9, end_t + 0.85), o)
	_box("retaining", Vector3(-hw - 0.72, -0.62, end_t + 0.6), Vector3(hw + 0.72, -0.48, end_t + 0.72), o)
	for x: float in [-4.8, 4.8]:
		_box("retaining", Vector3(x - 0.6, PODIUM_Y + 0.9, end_t + 0.6), Vector3(x + 0.6, -0.62, end_t + 0.9), o)
	_box("retaining", Vector3(-hw - 0.7, -0.3, end_t - 0.15), Vector3(hw + 0.7, -0.02, end_t + 0.7), o)
	# The balustrade: a plinth and a coping, balusters between, and a pedestal with a lantern every 9.6 m
	# along the sides (the lanterns' pools are drawn by assets/wing_stone.gdshader) and at the far corners.
	var rail := hw - 0.25
	var runs := []  # [from, to] in the wing's frame, along the balustrade's line
	for s: float in [-1.0, 1.0]:
		runs.append([Vector3(s * rail, 0.0, near + 0.5), Vector3(s * rail, 0.0, end_t - 0.25)])
	runs.append([Vector3(-rail, 0.0, end_t - 0.25), Vector3(rail, 0.0, end_t - 0.25)])
	var posts: Array[Vector3] = []
	var z := 2.0
	while z < end_t - 1.0:
		posts.append(Vector3(-rail, 0.0, z))
		posts.append(Vector3(rail, 0.0, z))
		z += 9.6
	posts.append(Vector3(-rail, 0.0, end_t - 0.25))
	posts.append(Vector3(rail, 0.0, end_t - 0.25))
	for x: float in [-4.8, 4.8]:
		posts.append(Vector3(x, 0.0, end_t - 0.25))
	var bal_xf: Array[Transform3D] = []
	for run: Array in runs:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var along := (b - a).normalized()
		var yaw := atan2(along.x, along.z)
		var c := (a + b) * 0.5
		var length := a.distance_to(b)
		var plinth := BoxMesh.new()
		plinth.size = Vector3(0.4, 0.18, length)
		_mesh_part(o, "retaining", plinth, Transform3D(Basis(Vector3.UP, yaw), c + Vector3(0, 0.09, 0)))
		var coping := BoxMesh.new()
		coping.size = Vector3(0.44, 0.14, length)
		_mesh_part(o, "retaining", coping, Transform3D(Basis(Vector3.UP, yaw), c + Vector3(0, 1.07, 0)))
		var n := int(length / 0.3)
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			var clear := true
			for q: Vector3 in posts:
				if p.distance_to(q) < 0.42:
					clear = false
			if clear:
				bal_xf.append(_frame * Transform3D(Basis(Vector3.UP, yaw), p + Vector3(0, 0.18, 0)))
	var gardens := _obs.get_node_or_null("PalaceGardens")
	var kit := "res://assets/garden_%s.obj"
	var from: Node = null
	if gardens != null:
		from = gardens.get_node_or_null("Garden/Terrace")
	var bal_mat: Material = _mat.retaining
	if from != null and from.get_node_or_null("Balusters") != null:
		bal_mat = (from.get_node("Balusters") as GeometryInstance3D).material_override
	if ResourceLoader.exists(kit % "baluster"):
		_kit_multi("Balusters", load(kit % "baluster") as Mesh, bal_mat, bal_xf)
	var post_xf: Array[Transform3D] = []
	var lamp_xf: Array[Transform3D] = []
	for p in posts:
		post_xf.append(_frame * Transform3D(Basis(), p))
		lamp_xf.append(_frame * Transform3D(Basis(), p + Vector3(0, 1.26, 0)))
	var names := {"pedestal": "Pedestals", "lantern_frame": "LanternFrames", "lantern_glass": "LanternGlass"}
	for part: String in names:
		if not ResourceLoader.exists(kit % part):
			continue
		var mat: Material = _mat.retaining if part == "pedestal" else _mat.ext_lamp
		if from != null and from.get_node_or_null(str(names[part])) != null:
			mat = (from.get_node(str(names[part])) as GeometryInstance3D).material_override
		if part == "pedestal":
			_kit_multi(str(names[part]), load(kit % part) as Mesh, mat, post_xf)
		else:
			_kit_multi(str(names[part]), load(kit % part) as Mesh, mat, lamp_xf)
	stats.terrace_posts = posts.size()
	stats.balusters = bal_xf.size()


## The gardens' kit, as a MultiMesh among the grounds (world transforms).
func _kit_multi(node_name: String, mesh: Mesh, mat: Material, xforms: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_grounds.add_child(mmi)


func _add(parent: Node3D, node_name: String, mesh: Mesh, mat: Material, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	return mi


# --- Busts ----------------------------------------------------------------------------------------

## A bust in white marble on a pedestal before each free-standing pier, facing the aisle; three heads
## in turn (bearded, clean-shaven, hair gathered up), each a little turned.
func _build_busts() -> void:
	var kinds := [_bust_mesh(0), _bust_mesh(1), _bust_mesh(2)]
	var n := 0
	for k in range(1, BAYS):
		var z := _line_z(k)
		for s: float in [-1.0, 1.0]:
			var x := s * 2.86
			_box("dark", Vector3(x - 0.22, 0.0, z - 0.22), Vector3(x + 0.22, 1.1, z + 0.22), k)
			_box("dark", Vector3(x - 0.27, 0.0, z - 0.27), Vector3(x + 0.27, 0.18, z + 0.27), k)
			_box("dark", Vector3(x - 0.27, 1.1, z - 0.27), Vector3(x + 0.27, 1.18, z + 0.27), k)
			_box("gold", Vector3(x - 0.225, 0.95, z - 0.225), Vector3(x + 0.225, 0.99, z + 0.225), k)
			var turn := -s * PI * 0.5 + _rng.randf_range(-0.25, 0.25)
			_mesh_part(k, "marble", kinds[n % kinds.size()], Transform3D(Basis(Vector3.UP, turn), Vector3(x, 1.18, z)))
			n += 1
	stats.busts = n


## A bust about 0.72 m high, facing +z from its socle's foot at the origin: a turned socle, the chest
## and shoulders cut in a curve, the neck, the head, and by kind a beard, or hair gathered into a knot.
func _bust_mesh(kind: int) -> ArrayMesh:
	var parts := []
	var socle := CylinderMesh.new()
	socle.top_radius = 0.09
	socle.bottom_radius = 0.13
	socle.height = 0.14
	socle.radial_segments = 16
	parts.append([socle, Transform3D(Basis(), Vector3(0, 0.07, 0))])
	var neck_ring := CylinderMesh.new()
	neck_ring.top_radius = 0.12
	neck_ring.bottom_radius = 0.075
	neck_ring.height = 0.06
	neck_ring.radial_segments = 16
	parts.append([neck_ring, Transform3D(Basis(), Vector3(0, 0.17, 0))])
	parts.append([_ellipsoid(Vector3(0.25, 0.17, 0.14), 20, 10), Transform3D(Basis(), Vector3(0, 0.33, 0))])
	var neck := CylinderMesh.new()
	neck.top_radius = 0.052
	neck.bottom_radius = 0.065
	neck.height = 0.16
	neck.radial_segments = 12
	parts.append([neck, Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 0.5, 0.01))])
	var head := Transform3D(Basis(Vector3.RIGHT, -0.08), Vector3(0, 0.62, 0.025))
	parts.append([_ellipsoid(Vector3(0.088, 0.118, 0.105), 18, 12), head])
	# The brow, the nose and the chin, so that the head reads as a face in profile.
	parts.append([_ellipsoid(Vector3(0.07, 0.025, 0.04), 10, 6), head * Transform3D(Basis(), Vector3(0, 0.03, 0.075))])
	parts.append([_ellipsoid(Vector3(0.016, 0.04, 0.03), 8, 6), head * Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, -0.005, 0.1))])
	parts.append([_ellipsoid(Vector3(0.04, 0.03, 0.035), 10, 6), head * Transform3D(Basis(), Vector3(0, -0.085, 0.07))])
	for side: float in [-1.0, 1.0]:
		parts.append([_ellipsoid(Vector3(0.015, 0.032, 0.022), 8, 6), head * Transform3D(Basis(), Vector3(side * 0.088, 0.0, -0.005))])
	match kind:
		0:
			parts.append([_ellipsoid(Vector3(0.075, 0.075, 0.06), 14, 8), head * Transform3D(Basis(), Vector3(0, -0.085, 0.055))])
			parts.append([_ellipsoid(Vector3(0.095, 0.07, 0.1), 14, 8), head * Transform3D(Basis(), Vector3(0, 0.07, -0.01))])
		1:
			parts.append([_ellipsoid(Vector3(0.093, 0.06, 0.1), 14, 8), head * Transform3D(Basis(), Vector3(0, 0.075, -0.012))])
		2:
			parts.append([_ellipsoid(Vector3(0.094, 0.08, 0.108), 14, 8), head * Transform3D(Basis(), Vector3(0, 0.05, -0.012))])
			parts.append([_ellipsoid(Vector3(0.05, 0.045, 0.045), 12, 8), head * Transform3D(Basis(), Vector3(0, 0.07, -0.105))])
	# A drape over one shoulder.
	parts.append([_ellipsoid(Vector3(0.12, 0.05, 0.15), 12, 8), Transform3D(Basis(Vector3.BACK, 0.5), Vector3(0.1, 0.42, 0.0))])
	return _obs.call("_merge", parts)


## A unit sphere scaled by r, its normals scaled by the inverse (an ellipsoid, as a mesh, so that the
## merge's transforms stay unscaled).
static func _ellipsoid(r: Vector3, seg: int, rings: int) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = seg
	sm.rings = rings
	var arrays := sm.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in v.size():
		v[i] = v[i] * r
		nrm[i] = (nrm[i] / r).normalized()
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = nrm
	arrays[Mesh.ARRAY_TANGENT] = null
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


# --- Looking glass ---------------------------------------------------------------------------------

## Looking glasses as in a hall of mirrors: one in each of the vestibule's walls, between its lanterns,
## and a tall one over the doorway on the nave's side, facing the end window, so that the nave and its
## chandeliers run on in it. Each in a gilt frame.
func _build_mirrors() -> void:
	var z0 := VEST_Z0 + 0.4
	var z1 := NAVE_Z0 - NEAR_T
	for s: float in [-1.0, 1.0]:
		# Built facing +z, turned to face the vestibule's axis.
		var xf := Transform3D(Basis(Vector3.UP, -s * PI * 0.5), Vector3(s * (VEST_HW - 0.012), 0.0, (z0 + z1) * 0.5))
		_mesh_part(0, "mirror", _arched(0.9, 0.5, 3.0), xf)
		_mesh_part(0, "gold", _arched_frame(0.9, 0.5, 3.0, 0.1), xf)
	var over := Transform3D(Basis(), Vector3(0.0, 0.0, NAVE_Z0 + 0.012))
	_mesh_part(1, "mirror", _arched(2.0, 7.5, 11.0), over)
	_mesh_part(1, "gold", _arched_frame(2.0, 7.5, 11.0, 0.16), over)
	stats.mirrors = 3


## An arched panel in the xy plane, facing +z: hw either side of x = 0, from y0 up to the spring of its
## round head.
static func _arched(hw: float, y0: float, spring: float, seg := 16) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_face(st, [Vector3(-hw, y0, 0), Vector3(hw, y0, 0), Vector3(hw, spring, 0), Vector3(-hw, spring, 0)], Vector3(0, 0, 1))
	for i in seg:
		var ta := PI * i / seg
		var tb := PI * (i + 1) / seg
		_face(st, [Vector3(0, spring, 0), Vector3(hw * cos(ta), spring + hw * sin(ta), 0), Vector3(hw * cos(tb), spring + hw * sin(tb), 0)], Vector3(0, 0, 1))
	return st.commit()


## Its frame, w wide, standing 5 cm proud: the round head, the stiles and the foot.
func _arched_frame(hw: float, y0: float, spring: float, w: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_arch_ring(st, hw, hw + w, spring, -0.02, 0.05, 1.0)
	var parts := [[st.commit(), Transform3D()]]
	for s: float in [-1.0, 1.0]:
		var stile := BoxMesh.new()
		stile.size = Vector3(w, spring - y0 + w, 0.07)
		parts.append([stile, Transform3D(Basis(), Vector3(s * (hw + w * 0.5), (y0 - w + spring) * 0.5, 0.015))])
	var foot := BoxMesh.new()
	foot.size = Vector3(2.0 * (hw + w), w, 0.07)
	parts.append([foot, Transform3D(Basis(), Vector3(0.0, y0 - w * 0.5, 0.015))])
	return _obs.call("_merge", parts)


# --- Chandeliers ------------------------------------------------------------------------------------

## A brass chandelier over the aisle in each bay, hung on a rod from the vault's crown: a turned body,
## two tiers of arms and rings, candles on them with their flames, a finial below; its light from its
## middle, every other one casting shadows, all flickering a little as candles do (_process).
func _build_chandeliers() -> void:
	var brass := []
	var wax := []
	var flames := []
	_chandelier(brass, wax, flames)
	var crown := ENTABLATURE + VAULT_B
	for j in BAYS:
		var c := j + 1
		var at := Vector3(0.0, CHANDELIER_Y, _line_z(j) + PITCH * 0.5)
		var xf := Transform3D(Basis(Vector3.UP, 0.3 * j), at)
		for group: Array in [["gold", brass], ["candle", wax], ["lamp", flames]]:
			for part: Array in group[1]:
				var pxf: Transform3D = part[1]
				_mesh_part(c, str(group[0]), part[0] as Mesh, xf * pxf)
		var rod := CylinderMesh.new()
		rod.top_radius = 0.018
		rod.bottom_radius = 0.018
		rod.height = crown - 0.05 - (CHANDELIER_Y + 1.0)
		rod.radial_segments = 6
		rod.rings = 1
		_mesh_part(c, "gold", rod, Transform3D(Basis(), Vector3(0.0, (crown - 0.05 + CHANDELIER_Y + 1.0) * 0.5, at.z)))
		var l := _light("Chandelier%d" % j, at + Vector3(0, -0.02, 0), 1.5, 9.0, 0.6)
		l.omni_attenuation = 0.7
		l.light_size = 0.4
		# Shadows from every other one, under Forward+ (and the native build): the web build's budget is
		# spent already.
		l.set_meta("shadow", j % 2 == 0 and not _compat)
		if bool(l.get_meta("shadow")):
			l.shadow_enabled = true
			l.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID
			l.shadow_bias = 0.06
			l.shadow_normal_bias = 1.5
			l.shadow_blur = 1.5
		l.set_meta("energy", l.light_energy)
		_chandeliers.append(l)
	stats.chandeliers = _chandeliers.size()


## One chandelier's parts about its middle: [mesh, transform] in brass, in wax and in flame.
func _chandelier(brass: Array, wax: Array, flames: Array) -> void:
	brass.append([_ellipsoid(Vector3(0.16, 0.22, 0.16), 16, 10), Transform3D()])
	brass.append([_ellipsoid(Vector3(0.09, 0.14, 0.09), 12, 8), Transform3D(Basis(), Vector3(0, 0.42, 0))])
	var stem := CylinderMesh.new()
	stem.top_radius = 0.035
	stem.bottom_radius = 0.045
	stem.height = 1.3
	stem.radial_segments = 10
	brass.append([stem, Transform3D(Basis(), Vector3(0, 0.35, 0))])
	var finial := CylinderMesh.new()
	finial.top_radius = 0.07
	finial.bottom_radius = 0.0
	finial.height = 0.36
	finial.radial_segments = 10
	brass.append([finial, Transform3D(Basis(), Vector3(0, -0.36, 0))])
	# [ring radius, height, candles]
	for tier: Array in [[0.85, -0.12, 12], [0.5, 0.36, 8]]:
		var r: float = tier[0]
		var y: float = tier[1]
		var n: int = tier[2]
		var ring := TorusMesh.new()
		ring.inner_radius = r - 0.022
		ring.outer_radius = r + 0.022
		ring.rings = 32
		ring.ring_segments = 6
		brass.append([ring, Transform3D(Basis(), Vector3(0, y, 0))])
		for i in n:
			var a := TAU * (i + 0.5) / n
			var dir := Vector3(cos(a), 0.0, sin(a))
			# An arm from the body, curving up to its cup.
			var arm := BoxMesh.new()
			arm.size = Vector3(r, 0.025, 0.025)
			if i % 2 == 0:
				brass.append([arm, Transform3D(Basis(Vector3.UP, -a), dir * r * 0.5 + Vector3(0, y - 0.04, 0))])
			var cup := CylinderMesh.new()
			cup.top_radius = 0.05
			cup.bottom_radius = 0.025
			cup.height = 0.04
			cup.radial_segments = 8
			brass.append([cup, Transform3D(Basis(), dir * r + Vector3(0, y + 0.03, 0))])
			var candle := CylinderMesh.new()
			candle.top_radius = 0.022
			candle.bottom_radius = 0.022
			candle.height = 0.17
			candle.radial_segments = 8
			candle.rings = 1
			wax.append([candle, Transform3D(Basis(), dir * r + Vector3(0, y + 0.135, 0))])
			flames.append([_ellipsoid(Vector3(0.016, 0.04, 0.016), 8, 5), Transform3D(Basis(), dir * r + Vector3(0, y + 0.26, 0))])


# --- Reflections ------------------------------------------------------------------------------------

## A reflection probe in the nave and one in the vestibule, box-projected and taken once, so that the
## floor, the gilt and the looking glasses reflect the wing about them, the chandeliers too; their
## ambient left to the lights.
func _build_probes() -> void:
	var end_z := _line_z(BAYS)
	for spec: Array in [["NaveProbe", Vector3(0.0, 7.4, (NAVE_Z0 + end_z) * 0.5), Vector3(2.0 * WALL_IN, 14.8, end_z - NAVE_Z0)],
			["VestibuleProbe", Vector3(0.0, 3.5, (VEST_Z0 + 0.4 + NAVE_Z0 - NEAR_T) * 0.5), Vector3(2.0 * VEST_HW, 7.0, NAVE_Z0 - NEAR_T - VEST_Z0 - 0.4)]]:
		var probe := ReflectionProbe.new()
		probe.name = str(spec[0])
		var at: Vector3 = spec[1]
		probe.position = at
		probe.size = spec[2]
		probe.origin_offset = Vector3(0.0, 1.7 - at.y, 0.0)  # taken at eye height
		probe.box_projection = true
		probe.interior = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.intensity = 0.8
		probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
		if _compat:
			# A probe taken under Compatibility saw the opposite glass black, having nothing yet to reflect,
			# and each glass then showed it (artpass/foundation/mirrorprobe.gd: a black arch with a strip of
			# vestibule beside it). The glasses are left out of the captures there: each shows the wall
			# across, its lanterns and the nave.
			probe.cull_mask = 0xFFFFF & ~MIRROR_LAYER
		_interior.add_child(probe)
	stats.probes = 2


# --- Light ----------------------------------------------------------------------------------------

## Warm lamplight that reaches only the wing's meshes: the chandeliers (_build_chandeliers), one in
## each alcove, two under the vault, one in the vestibule.
func _build_lights() -> void:
	for j in BAYS:
		var zc := _line_z(j) + PITCH * 0.5
		for s: float in [-1.0, 1.0]:
			# Under the gallery's floor: with no shadows, it lights the alcove's cases and, through the
			# floor, the gallery's from below.
			var l := _light("Alcove%d%s" % [j, "L" if s < 0.0 else "R"], Vector3(s * 5.3, 3.6, zc), 1.2, 6.0, 0.1)
			l.omni_attenuation = 0.8
	for f: float in [0.25, 0.75]:
		_light("Vault%d" % int(f * 4.0), Vector3(0.0, 12.6, lerpf(NAVE_Z0, _line_z(BAYS), f)), 1.2, 11.0, 0.2)
	_light("Vestibule", Vector3(0.0, 3.6, (VEST_Z0 + NAVE_Z0 - NEAR_T) * 0.5 + 0.2), 1.6, 5.5, 0.4)
	stats.lights = _lights.size()


func _light(node_name: String, at: Vector3, energy: float, reach: float, fog: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = node_name
	l.position = at
	l.light_color = WARM
	l.light_energy = energy * (COMPAT_GAIN if _compat else 1.0)
	l.omni_range = reach
	l.omni_attenuation = 1.1
	l.light_specular = 0.35
	l.light_cull_mask = LAYER | MIRROR_LAYER
	l.light_volumetric_fog_energy = fog
	l.shadow_enabled = false
	# Dropped once far: under Compatibility a frame draws at most 32 lights, the first found, and a light
	# past its fade does not count (drivers/gles3/rasterizer_scene_gles3.cpp); from the hall, the wing's
	# would otherwise take the hall's places.
	l.distance_fade_enabled = true
	l.distance_fade_begin = 30.0
	l.distance_fade_length = 8.0
	_interior.add_child(l)
	_lights.append(l)
	return l


# --- For the others -------------------------------------------------------------------------------

## p (world) in the wing's frame.
func local(p: Vector3) -> Vector3:
	return _inv * p


## Whether p (world) is inside the wing, past the hall's wall: extra_views.gd does not count it as
## outside, and the gardens show through its windows.
func contains(p: Vector3) -> bool:
	var q := _inv * p
	return q.z > 0.05 and q.z < _line_z(BAYS) + 0.1 and absf(q.x) < WALL_IN + 0.1 and q.y > -1.0 and q.y < ENTABLATURE + VAULT_B + 0.5


## How far from the hall's middle a walker may go: the wing's far end.
func far_radius() -> float:
	return (_frame * Vector3(WALL_IN, 0.0, _line_z(BAYS))).length() + 1.0


## For the hall's walking body (palace_gardens.gd bay_walk): where a body of radius r going to p (x,
## z) stays, in the portal, the vestibule or the nave; Vector2.INF when p is not the wing's.
func walk(p: Vector2, r: float) -> Vector2:
	var q3 := _inv * Vector3(p.x, 0.0, p.y)
	var q := Vector2(q3.x, q3.z)
	var hw := PORTAL_W * 0.5 - 0.1
	if q.y < -2.0 or q.y > _line_z(BAYS) + 2.0 or absf(q.x) > WALL_OUT + 2.0:
		return Vector2.INF
	if q.y < VEST_Z0 + 0.4:
		if absf(q.x) > hw:
			return Vector2.INF  # beside the portal: the hall's shelves hold the body
		q.x = clampf(q.x, -(hw - r), hw - r)
	elif q.y < NAVE_Z0:
		q.x = clampf(q.x, -(VEST_HW - r), VEST_HW - r)
	else:
		q.x = clampf(q.x, -(CASE_FRONT - r), CASE_FRONT - r)
		q.y = minf(q.y, _line_z(BAYS) - r)
		if q.y < NAVE_Z0 + r and absf(q.x) > VEST_HW - r:
			q.y = NAVE_Z0 + r
		for b in _solids:
			q = _out_of(q, b, r)
	var w := _frame * Vector3(q.x, 0.0, q.y)
	return Vector2(w.x, w.z)


## For the flying camera (walk_physics.gd): where a camera of radius r flying to p (world) stays in the
## portal, the vestibule or the nave, clear of their walls and under their ceilings; it flies past the
## piers and busts, as past the hall's columns. Vector3.INF when p is not the wing's. Above an opening's
## head the wall stops it on the side it came from: in the hall the hall's own bound, in the nave the
## near end wall.
func fly(p: Vector3, r: float) -> Vector3:
	var q := _inv * p
	var hw := PORTAL_W * 0.5 - 0.1
	if q.z < -2.0 or q.z > _line_z(BAYS) + 2.0 or absf(q.x) > WALL_OUT + 2.0:
		return Vector3.INF
	var portal := q.z < VEST_Z0 + 0.4
	if portal and q.z < 0.0 and (absf(q.x) > hw or q.y > PORTAL_H - r):
		return Vector3.INF  # beside or over the portal, in the hall
	if portal and q.y > PORTAL_H - r:
		q.z = VEST_Z0 + 0.4  # in the wall's thickness over the portal's soffit, from the vestibule: back in it
		portal = false
	if not portal and q.z < NAVE_Z0 and q.y > _vest_top(q.x) - r:
		q.z = NAVE_Z0 + r  # over the vestibule's vault, from the nave: the near end wall
	var top := PORTAL_H
	if portal:
		q.x = clampf(q.x, -(hw - r), hw - r)
	elif q.z < NAVE_Z0:
		q.x = clampf(q.x, -(VEST_HW - r), VEST_HW - r)
		top = _vest_top(q.x)
	else:
		q.x = clampf(q.x, -(CASE_FRONT - r), CASE_FRONT - r)
		q.z = minf(q.z, _line_z(BAYS) - r)
		if q.z < NAVE_Z0 + r and absf(q.x) > VEST_HW - r:
			q.z = NAVE_Z0 + r
		top = SIDE_CEILING if absf(q.x) > VAULT_A else ENTABLATURE + VAULT_B * sqrt(1.0 - pow(q.x / VAULT_A, 2.0))
	q.y = clampf(q.y, r, top - r)
	return _frame * q


## The vestibule's barrel vault over x (_build_vestibule).
static func _vest_top(x: float) -> float:
	return VEST_SPRING + sqrt(maxf(0.0, VEST_HW * VEST_HW - x * x))


## A circle of radius r at p, out of the rectangle b.
static func _out_of(p: Vector2, b: Rect2, r: float) -> Vector2:
	var near := p.clamp(b.position, b.end)
	var off := p - near
	if off.length_squared() >= r * r:
		return p
	if off.length_squared() > 1e-8:
		return near + off.normalized() * r
	var best := Vector2(b.position.x - r - p.x, 0.0)
	for o: Vector2 in [Vector2(b.end.x + r - p.x, 0.0), Vector2(0.0, b.position.y - r - p.y), Vector2(0.0, b.end.y + r - p.y)]:
		if o.length() < best.length():
			best = o
	return p + best


## Under Compatibility a frame draws at most 32 omni lights, the first found, and one past its distance
## fade does not count (drivers/gles3/rasterizer_scene_gles3.cpp _setup_lights). From the wing the hall's,
## behind its wall, took the wing's places: up on the gallery a mean luma of 19.6 with them, 67.3 without
## (artpass/foundation/shots/compat-nohall). Faded out and on no layer while the camera is in the wing
## past its vestibule with the portal out of view, then each put back as it was; their visibility, which
## others set, is left alone.
func _fade_hall(out: bool) -> void:
	if out == _hall_out:
		return
	_hall_out = out
	if not out:
		for f: Array in _hall_faded:
			var l: Light3D = f[0]
			if is_instance_valid(l):
				l.distance_fade_enabled = f[1]
				l.distance_fade_begin = f[2]
				l.distance_fade_length = f[3]
				l.light_cull_mask = f[4]
		_hall_faded.clear()
		return
	var ceiling := float(_obs.get("_ceiling_y"))
	for l: Light3D in _obs.find_children("*", "Light3D", true, false):
		if l is DirectionalLight3D or is_ancestor_of(l):
			continue
		var g := l.global_position
		if Vector2(g.x, g.z).length() > _outer + 0.5 or g.y > ceiling + 1.0:
			continue
		_hall_faded.append([l, l.distance_fade_enabled, l.distance_fade_begin, l.distance_fade_length, l.light_cull_mask])
		l.distance_fade_enabled = true
		l.distance_fade_begin = 0.0
		l.distance_fade_length = 0.01
		# Faded, a light still takes one of a mesh's 8 places (renderer_scene_cull.cpp pairs by range
		# and energy alone): on no layer, it takes none.
		l.light_cull_mask = 0
	stats.hall_lights_faded = _hall_faded.size()


## Whether the camera in the wing has a point of the portal in its view.
func _portal_in_view(cam: Camera3D) -> bool:
	for v: Vector3 in _portal:
		if cam.is_position_in_frustum(_frame * v):
			return true
	return false


## Whether the camera in the hall has the portal in its view, or is close to it.
func _portal_seen(cam: Camera3D) -> bool:
	var q := _inv * cam.global_position
	if q.z > -6.0 and absf(q.x) < 4.0:
		return true
	for v: Vector3 in _portal:
		if cam.is_position_in_frustum(_frame * v):
			return true
	return false


## For a rider in the gardens (palace_gardens.gd push_out): out of the terrace's retaining walls, at
## the court's level.
func push_out(p: Vector2, r: float, y: float) -> Vector2:
	if y > PODIUM_Y + 1.0:
		return p
	var q3 := _inv * Vector3(p.x, 0.0, p.y)
	var end_t := _line_z(BAYS) + END_T + TERRACE_END
	var b := Rect2(-TERRACE_HW - 0.7, -8.0, 2.0 * (TERRACE_HW + 0.7), end_t + 8.7)
	var q := _out_of(Vector2(q3.x, q3.z), b, r)
	if q.is_equal_approx(Vector2(q3.x, q3.z)):
		return p
	var w := _frame * Vector3(q.x, 0.0, q.y)
	return Vector2(w.x, w.z)


## Whether the camera sees out of a window of the wing: from inside it, always (its windows line both
## sides and its end); from the hall, when the end window shows through the portal.
func window_in_view() -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var p := cam.global_position
	if contains(p):
		return true
	var q := _inv * p
	if q.z > 0.0 or q.y > WALKWAY:
		return false
	for w: Vector3 in _windows:
		if not cam.is_position_in_frustum(_frame * w):
			continue
		# Through the portal: where the line from the eye to the window crosses the hall's wall.
		var t := (0.0 - q.z) / (w.z - q.z)
		var at := q.lerp(w, t)
		if absf(at.x) < PORTAL_W * 0.5 and at.y < PORTAL_H:
			return true
	return false


func _process(delta: float) -> void:
	_time += delta
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		# Inside the hall, the outside is behind its walls.
		var p := cam.global_position
		var in_hall := Vector2(p.x, p.z).length() < _outer + 0.3 and p.y < float(_obs.get("_ceiling_y"))
		_exterior.visible = not in_hall
		_grounds.visible = not in_hall
		# Under Compatibility (the web build), the inside too while the portal is out of sight. Not under
		# Forward+, where SDFGI takes in what is shown as the camera moves: the wing hidden then would be
		# open air to its light until the cascades were taken again.
		if _compat:
			_interior.visible = not in_hall or _portal_seen(cam)
			_fade_hall(contains(p) and (_inv * p).z > NAVE_Z0 and not _portal_in_view(cam))
	# The candles flicker, each chandelier at its own pace.
	for i in _chandeliers.size():
		var l := _chandeliers[i]
		var e := float(l.get_meta("energy"))
		l.light_energy = e * (1.0 + 0.035 * sin(_time * 7.3 + i * 1.9) + 0.025 * sin(_time * 13.1 + i * 0.7))
	var quality := _obs.get_node_or_null("Quality")
	var level := int(quality.get("level")) if quality != null else 0
	if level != _level:
		_level = level
		# From level 3, the books as boxes (observatory.gd low_poly), as the hall's.
		for mmi in _book_mmis:
			mmi.multimesh.mesh = _book_full if level < 3 else _book_low
		for l in _lights:
			if l.name.begins_with("Alcove") and l.name.ends_with("R"):
				l.visible = level < 4
		for l in _chandeliers:
			l.shadow_enabled = bool(l.get_meta("shadow")) and level < 3
		stats.level = level
