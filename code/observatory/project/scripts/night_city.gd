extends Node3D
## Trantor at night round the palace grounds, in place of the painted strips (the author, 2026-10-12: "À
## l'extérieur, crée un panorama nocturne de Trantor, bleu-cyan, avec des tours et de grandes structures
## circulaires"; photographs of a television series were shown as inspiration only, and nothing here is
## taken from them). Made by scripts/palace_gardens.gd (_build_city) and drawn with the gardens, lit by its
## own shader (assets/night_city.gdshader): no light is added to the scene.
##   - the towers: a ring of them from R0 to R1, square and round, cut by avenues every 22.5 degrees,
##     rising further out and in a few downtowns; podiums under the tall ones, crowns and needles on the
##     tallest, a cyan line round a few roofs. Two MultiMeshes, two draw calls. A city of square glass
##     towers in an amber haze read as Manhattan to the author (2026-10-04, artpass/gardens/NOTES.md):
##     here the round forms and the rings carry the skyline;
##   - the great round structures (STRUCTURES): stepped drums under a low dome and a floating crown, rings
##     held high on pillars, round towers girdled by platforms, each in a plaza ringed with light; the
##     drum on the library wing's axis is what the wing's end window frames (scripts/library_wing.gd);
##   - raised rings round districts (VIADUCTS), lined in cyan, traffic running round them;
##   - the ground between them seen from above: streets of lights and lit roofs, and the rings' roads;
##   - the city's glow round the whole horizon, and columns of light rising from the plazas into it.

const SHADER_PATH := "res://assets/night_city.gdshader"
const GLOW_SHADER_PATH := "res://assets/palace_glow.gdshader"
## The ground's lights at night, the whole city's map over x and z in [-3200, 3200] m
## (artpass/foundation/city/make_plan.py's aerial_src.png, as drawn there: not refined by ComfyUI).
const AERIAL_PATH := "res://assets/city/night_aerial.png"
## The blocks' podiums and the towers' sites, laid out on that map's streets (make_plan.py): rows of
## (kind 0 podium, 1 tower, 2 round tower; x; z; yaw; width; depth; the district's density; a seed).
const PLAN_PATH := "res://assets/city/city_plan.tres"
## Facades at night, 4 x 2 kinds of building (artpass/foundation/city/make_facades.py, ComfyUI).
const FACADES_PATH := "res://assets/city/facades.png"
## The downtown (the author, 2026-10-12: « Essaie de rajouter un centre ville avec des immeubles
## iconiques », « Façon futuriste »): six landmark towers modelled in Blender
## (artpass/foundation/city/make_landmarks.py), round a point between the viaduct's ring at 190 degrees and
## the drum on the wing's axis, so that both the roof and the wing's terrace see them. (azimuth in
## degrees, distance m, radius m kept free of the plan's blocks: make_plan.py reads it.)
const LANDMARKS_AT := Vector3(212.0, 2150.0, 360.0)
const LANDMARK_DIR := "res://assets/city/landmarks/"
## [name, metres out from the hall, metres across (anticlockwise), turn in degrees, facade tile]
const LANDMARKS := [
	["helix", 0.0, 0.0, 10.0, 0],
	["twins", 150.0, -170.0, 30.0, 7],
	["needle", -190.0, 120.0, 0.0, 3],
	["sail", 80.0, 220.0, -60.0, 0],
	["stack", -140.0, -190.0, 15.0, 1],
	["hyperboloid", 230.0, 120.0, 0.0, 6],
]
const SEED := 20261012
## From the hall's middle: past the woods (palace_gardens.gd WOODS_R ends at 1560 m), and inside the sky,
## which is drawn 3500 m round the camera when the camera may ride 400 m out (palace_gardens.gd RIDE_R).
const R0 := 1660.0
const R1 := 3000.0
const PITCH := 74.0           # m between towers, round and out
const AVENUES := 16           # avenues, radial, one every 22.5 degrees from +X
const AVENUE_HALF := 24.0     # m
## Where the city rises: (azimuth in degrees from +X towards +Z, how much higher at R1). The garden's
## axis (90 degrees) is left lower, so that the ring behind the palace stands clear over it.
const DOWNTOWNS := [Vector2(58.0, 1.4), Vector2(124.0, 1.2), Vector2(200.0, 1.0), Vector2(275.0, 1.5), Vector2(340.0, 1.1)]
## [kind, azimuth (degrees), distance from the hall's middle (m), size]. The first drum stands on the
## library wing's axis (bay 10's middle, 236.25 degrees).
const STRUCTURES := [
	["drum", 236.25, 2300.0, 1.35],
	["halo", 76.0, 2550.0, 1.6],
	["halo", 24.0, 2150.0, 0.8],
	["crown", 133.0, 2050.0, 1.0],
	["crown", 314.0, 2350.0, 0.9],
	["drum", 168.0, 2750.0, 0.85],
]
## Raised rings round districts: (azimuth, distance, radius, height), all in metres but the azimuth.
const VIADUCTS := [Vector4(236.25, 2300.0, 560.0, 120.0), Vector4(70.0, 2350.0, 420.0, 95.0),
	Vector4(110.0, 2250.0, 380.0, 150.0), Vector4(190.0, 2300.0, 450.0, 105.0), Vector4(290.0, 2200.0, 400.0, 135.0),
	Vector4(350.0, 2450.0, 470.0, 115.0), Vector4(20.0, 2150.0, 520.0, 75.0)]
## Light, in sRGB as palace_glow.gdshader takes its colour.
const GLOW_COLOUR := Color(0.26, 0.58, 0.95)
const BEAM_COLOUR := Color(0.45, 0.85, 1.0)

var stats := {}
var _compat := false
var _ground_y := -10.0
var _rng := RandomNumberGenerator.new()
var _clear: Array[Vector3] = []        # (x, z, radius): kept free of towers round the structures
var _lanes: Array[Vector3] = []        # (x, z, radius): ring roads under the viaducts, kept free too
var _rings: Array[Vector4] = []        # (x, z, radius, width): rings of light on the ground
var _beams: Array[Vector3] = []        # (x, z, height): columns of light
var _boxes := {"xf": [], "custom": []}
var _rounds := {"xf": [], "custom": []}
## On the roofs (the author, 2026-10-12: « Rajoute des rooftops », « Et des penthouse », « Façon
## futuriste », « Et quelques piscines sur le toit »): glass pavilions lit from within under a
## cantilevered slab, square and round, and pools, a few of them reaching out past the roof's edge.
var _penthouses := {"xf": [], "custom": []}
var _round_penthouses := {"xf": [], "custom": []}
var _pools := {"xf": [], "custom": []}


## compat: drawn by the Compatibility renderer; ground_y: the gardens' ground (palace_gardens.gd GROUND_Y).
func configure(compat: bool, ground_y: float) -> void:
	_compat = compat
	_ground_y = ground_y


func _ready() -> void:
	var t0 := Time.get_ticks_usec()
	_rng.seed = SEED
	for s: Array in STRUCTURES:
		_structure(s)
	_build_viaducts()
	_build_landmarks()
	_build_towers()
	_build_ground()
	_build_glow()
	_build_beams()
	stats.build_ms = snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.1)


# --- Helpers ------------------------------------------------------------------------------------

func _mat(shape: int, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER_PATH)
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("ground_y", _ground_y - 2.0)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


func _add_to(parent: Node3D, node_name: String, mesh: Mesh, mat: Material, xf := Transform3D()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	return mi


static func _cylinder(segments: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 1.0
	c.bottom_radius = 1.0
	c.height = 1.0
	c.radial_segments = segments
	c.rings = 1
	return c


## A flat ring from r0 to r1, `thick` metres high round y = 0: its outer and inner walls, top and bottom,
## in metres (the shader reads its radii from ring_r and its wall from `band`).
static func _ring(r0: float, r1: float, thick: float, segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y0 := -thick * 0.5
	var y1 := thick * 0.5
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var up := Vector3(0, y1, 0)
		var dn := Vector3(0, y0, 0)
		var quads := [
			[[d0 * r1 + up, d1 * r1 + up, d1 * r1 + dn, d0 * r1 + dn], (d0 + d1).normalized()],
			[[d1 * r0 + up, d0 * r0 + up, d0 * r0 + dn, d1 * r0 + dn], -(d0 + d1).normalized()],
			[[d0 * r0 + up, d1 * r0 + up, d1 * r1 + up, d0 * r1 + up], Vector3.UP],
			[[d1 * r0 + dn, d0 * r0 + dn, d0 * r1 + dn, d1 * r1 + dn], Vector3.DOWN],
		]
		for q: Array in quads:
			var pts: Array = q[0]
			var n: Vector3 = q[1]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var p0: Vector3 = pts[tri[0]]
				var p1: Vector3 = pts[tri[1]]
				var p2: Vector3 = pts[tri[2]]
				if (p1 - p0).cross(p2 - p0).dot(n) > 0.0:
					var t := p1
					p1 = p2
					p2 = t
				for p: Vector3 in [p0, p1, p2]:
					st.set_normal(n)
					st.add_vertex(p)
	return st.commit()


## A tower part of size (w, h, d) standing at p (x, z) from y0 up, turned by yaw: custom is (seed, share
## lit, share warm, roof line).
func _part(into: Dictionary, p: Vector2, yaw: float, size: Vector3, y0: float, custom: Color) -> void:
	(into.xf as Array).append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(size), Vector3(p.x, y0 + size.y * 0.5, p.y)))
	(into.custom as Array).append(custom)


func _at(az_deg: float, r: float) -> Vector2:
	var a := deg_to_rad(az_deg)
	return Vector2(cos(a), sin(a)) * r


# --- The great structures -----------------------------------------------------------------------

## A drum's tier in the atlas's ribbon windows (facades.png, tile 1) rather than rows of dashes, which
## read as a grid through the library wing's end window; the podium (t 0) stays dimmer.
func _ribbons(t: int) -> Dictionary:
	if not ResourceLoader.exists(FACADES_PATH):
		return {}
	return {"facades": load(FACADES_PATH), "use_facades": true, "facade_style": 1, "facade_tile": 30.0,
		"lit": 0.12 if t == 0 else 0.3}


func _structure(s: Array) -> void:
	var kind: String = s[0]
	var c := _at(s[1], s[2])
	var k: float = s[3]
	var foot := _ground_y - 2.0
	var g := Node3D.new()
	g.name = "%s%d" % [kind.capitalize(), get_child_count()]
	g.position = Vector3(c.x, 0.0, c.y)
	add_child(g)
	var cyl := _cylinder(96)
	if kind == "drum":
		# A podium, three stepped tiers in ribbons of windows, a low dome and a crown floating over it.
		var radii := [300.0 * k, 250.0 * k, 190.0 * k, 130.0 * k]
		var heights := [36.0 * k, 85.0 * k, 72.0 * k, 60.0 * k]
		var y := foot
		for t in radii.size():
			var h: float = heights[t]
			_add_to(g, "Tier%d" % t, cyl, _mat(1, {"lit": 0.14 if t == 0 else 0.5, "warm": 0.12, "cell": Vector2(5.0, 7.0),
				"pane": Vector2(0.82, 0.22), "seed": 0.31 + t * 0.1, "window_energy": 1.9, "rim_width": 2.4, "rim_energy": 2.6}.merged(_ribbons(t), true)),
				Transform3D(Basis.from_scale(Vector3(radii[t], h, radii[t])), Vector3(0.0, y + h * 0.5, 0.0)))
			y += h
		var dome := SphereMesh.new()
		dome.radius = 1.0
		dome.height = 1.0
		dome.is_hemisphere = true
		dome.radial_segments = 64
		dome.rings = 12
		_add_to(g, "Dome", dome, _mat(1, {"lit": 0.1, "cell": Vector2(8.0, 8.0), "pane": Vector2(0.3, 0.3), "seed": 0.77,
			"rim_on": 0.0}), Transform3D(Basis.from_scale(Vector3(122.0 * k, 52.0 * k, 122.0 * k)), Vector3(0.0, y, 0.0)))
		var crown := Vector2(128.0 * k, 146.0 * k)
		_add_to(g, "Crown", _ring(crown.x, crown.y, 7.0 * k, 128), _mat(1, {"lit": 0.5, "cell": Vector2(3.0, 3.0),
			"pane": Vector2(0.7, 0.5), "seed": 0.52, "ring_r": crown, "band": Vector2(-3.5 * k, 3.5 * k), "rim_width": 1.8,
			"rim_energy": 3.2}), Transform3D(Basis(), Vector3(0.0, y + 40.0 * k, 0.0)))
		_clear.append(Vector3(c.x, c.y, 345.0 * k))
		_rings.append(Vector4(c.x, c.y, 330.0 * k, 7.0))
		_beams.append(Vector3(c.x, c.y, 1300.0))
	elif kind == "halo":
		# A ring held high on eight pillars over an open plaza, both its edges lined in cyan.
		var r := Vector2(190.0 * k, 255.0 * k)
		var thick := 22.0 * k
		var high := 350.0 * k
		_add_to(g, "Ring", _ring(r.x, r.y, thick, 160), _mat(1, {"lit": 0.42, "warm": 0.08, "cell": Vector2(3.0, 4.0),
			"pane": Vector2(0.72, 0.36), "seed": 0.13, "ring_r": r, "band": Vector2(-thick * 0.5, thick * 0.5),
			"rim_width": 2.6, "rim_energy": 3.0}), Transform3D(Basis(), Vector3(0.0, foot + high, 0.0)))
		for i in 8:
			var a := TAU * (i + 0.5) / 8.0
			var p := c + Vector2(cos(a), sin(a)) * (r.x + r.y) * 0.5
			_part(_boxes, p, -a, Vector3(30.0 * k, high - thick * 0.5, 30.0 * k), foot, Color(_rng.randf(), 0.2, 0.1, 0.0))
		_clear.append(Vector3(c.x, c.y, 300.0 * k))
		_rings.append(Vector4(c.x, c.y, 222.0 * k, 9.0))
		_beams.append(Vector3(c.x, c.y, 1500.0))
	else:
		# A round tower girdled by three platforms, on a ringed base, under a needle.
		var tr := 46.0 * k
		var th := 720.0 * k
		_add_to(g, "Shaft", cyl, _mat(1, {"lit": 0.4, "cell": Vector2(4.0, 5.0), "pane": Vector2(0.55, 0.4), "seed": 0.66,
			"rim_width": 2.0}), Transform3D(Basis.from_scale(Vector3(tr, th, tr)), Vector3(0.0, foot + th * 0.5, 0.0)))
		_add_to(g, "Base", cyl, _mat(1, {"lit": 0.18, "seed": 0.21}),
			Transform3D(Basis.from_scale(Vector3(125.0 * k, 34.0 * k, 125.0 * k)), Vector3(0.0, foot + 17.0 * k, 0.0)))
		for f: float in [0.38, 0.62, 0.84]:
			var w := 58.0 * k * (1.15 - f * 0.4)
			var rr := Vector2(tr - 2.0, tr + w)
			_add_to(g, "Platform%d" % int(f * 100.0), _ring(rr.x, rr.y, 10.0 * k, 96), _mat(1, {"lit": 0.48, "cell": Vector2(2.6, 3.0),
				"pane": Vector2(0.74, 0.5), "seed": 0.44 + f, "ring_r": rr, "band": Vector2(-5.0 * k, 5.0 * k), "rim_width": 1.6,
				"rim_energy": 3.0}), Transform3D(Basis(), Vector3(0.0, foot + th * f, 0.0)))
		_part(_boxes, c, 0.0, Vector3(5.0, 150.0 * k, 5.0), foot + th, Color(0.5, 0.0, 0.0, 1.0))
		_clear.append(Vector3(c.x, c.y, 160.0 * k))
		_rings.append(Vector4(c.x, c.y, 150.0 * k, 5.0))
		_beams.append(Vector3(c.x + 175.0 * k, c.y, 900.0))
	stats[kind] = int(stats.get(kind, 0)) + 1


## Raised ring roads round districts, on slim piers, lined in cyan, traffic running round them.
func _build_viaducts() -> void:
	var g := Node3D.new()
	g.name = "Viaducts"
	add_child(g)
	var foot := _ground_y - 2.0
	for v in VIADUCTS:
		var c := _at(v.x, v.y)
		var r := Vector2(v.z - 7.0, v.z + 7.0)
		_add_to(g, "Viaduct%d" % int(v.x), _ring(r.x, r.y, 5.0, 192), _mat(1, {"lit": 0.0, "ring_r": r, "band": Vector2(-2.5, 2.5),
			"rim_width": 1.1, "rim_energy": 2.4, "traffic": 1.6}), Transform3D(Basis(), Vector3(c.x, foot + v.w, c.y)))
		var n := int(TAU * v.z / 90.0)
		for i in n:
			var a := TAU * i / n
			_part(_boxes, c + Vector2(cos(a), sin(a)) * v.z, -a, Vector3(6.0, v.w - 2.5, 6.0), foot, Color(0.0, 0.0, 0.0, 0.0))
		_lanes.append(Vector3(c.x, c.y, v.z))
		_rings.append(Vector4(c.x, c.y, v.z, 3.0))
	stats.viaducts = VIADUCTS.size()


# --- The downtown -------------------------------------------------------------------------------

func _build_landmarks() -> void:
	var c := _at(LANDMARKS_AT.x, LANDMARKS_AT.y)
	var a := deg_to_rad(LANDMARKS_AT.x)
	var out := Vector2(cos(a), sin(a))
	var across := Vector2(-sin(a), cos(a))
	var g := Node3D.new()
	g.name = "Downtown"
	add_child(g)
	var facades: Texture2D = load(FACADES_PATH) if ResourceLoader.exists(FACADES_PATH) else null
	for l: Array in LANDMARKS:
		var path := LANDMARK_DIR + str(l[0]) + ".glb"
		if not ResourceLoader.exists(path):
			continue
		var tower: Node3D = (load(path) as PackedScene).instantiate()
		var p := c + out * float(l[1]) + across * float(l[2])
		tower.name = str(l[0]).capitalize()
		tower.position = Vector3(p.x, _ground_y - 2.0, p.y)
		tower.rotation.y = deg_to_rad(float(l[3]))
		g.add_child(tower)
		for mi: MeshInstance3D in tower.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			if mi.name.begins_with("Lights"):
				mi.material_override = _mat(5, {"rim_energy": 2.4, "warm": 0.25 if str(l[0]) == "stack" else 0.0})
			else:
				mi.material_override = _mat(0, {"use_uv": true, "use_facades": facades != null, "facades": facades,
					"facade_style": int(l[4]), "facade_tile": 40.0, "lit": 0.32, "warm": 0.15, "seed": _rng.randf(), "rim_on": 0.0})
		stats.landmarks = int(stats.get("landmarks", 0)) + 1


# --- The towers ---------------------------------------------------------------------------------

func _on_avenue(a: float, r: float) -> bool:
	var step := TAU / AVENUES
	return absf(a - roundf(a / step) * step) * r < AVENUE_HALF


func _blocked(p: Vector2, half: float) -> bool:
	for c in _clear:
		if p.distance_to(Vector2(c.x, c.y)) < c.z + half:
			return true
	for l in _lanes:
		if absf(p.distance_to(Vector2(l.x, l.y)) - l.z) < 16.0 + half:
			return true
	return false


func _height(r: float, a: float) -> float:
	var t := clampf((r - R0) / (R1 - R0), 0.0, 1.0)
	var h := lerpf(40.0, 270.0, t * (0.3 + 0.7 * t)) * exp(_rng.randfn(0.0, 0.45))
	# Lower round the great structures, so that each stands over its district.
	var p := Vector2(cos(a), sin(a)) * r
	for c in _clear:
		var d := p.distance_to(Vector2(c.x, c.y)) - c.z
		h *= lerpf(0.3, 1.0, smoothstep(0.0, 650.0, d))
	for d: Vector2 in DOWNTOWNS:
		var da := absf(angle_difference(a, deg_to_rad(d.x)))
		h *= 1.0 + d.y * exp(-da * da / (2.0 * 0.1 * 0.1)) * (0.3 + 0.7 * t)
	return clampf(h, 26.0, 1100.0)


## What stands on a roof at height `top`: a penthouse, a pool, both, or nothing. (w, d): the roof's sides,
## turned by yaw as _part turns them; round: a round tower's roof, w its diameter. Custom data: (seed,
## lit 1 or 0, warm, 1 for a slab's or a pool's lit edge, or a pool reaching out).
func _roof(p: Vector2, yaw: float, w: float, d: float, top: float, round: bool, sd: float) -> void:
	var roll := _rng.randf()
	var has_ph := roll < 0.5
	var has_pool := roll > 0.3 and roll < 0.62 and not round
	var u := Vector2(cos(yaw), -sin(yaw))
	var v := Vector2(sin(yaw), cos(yaw))
	if has_ph:
		# Glass, one or two storeys, set back; a slab over it wider than it, its edge a line of light.
		var pw := w * (_rng.randf_range(0.4, 0.52) if has_pool else _rng.randf_range(0.45, 0.7))
		var pd := d * _rng.randf_range(0.45, 0.7)
		var ph := _rng.randf_range(7.0, 13.0)
		var along := -1.0 if has_pool else _rng.randf_range(-1.0, 1.0)
		var c := p + u * (w - pw) * 0.5 * along + v * (d - pd) * 0.5 * _rng.randf_range(-1.0, 1.0)
		var warm := _rng.randf()
		if round:
			_part(_round_penthouses, c, 0.0, Vector3(pw * 0.5, ph, pw * 0.5), top, Color(sd, 1.0, warm, 0.0))
			_part(_round_penthouses, c, 0.0, Vector3(pw * 0.64, 0.9, pw * 0.64), top + ph, Color(sd, 0.0, warm, 1.0))
		else:
			_part(_penthouses, c, yaw, Vector3(pw, ph, pd), top, Color(sd, 1.0, warm, 0.0))
			_part(_penthouses, c + u * pw * 0.1, yaw, Vector3(pw * 1.32, 0.9, pd * 1.22), top + ph, Color(sd, 0.0, warm, 1.0))
		stats.penthouses = int(stats.get("penthouses", 0)) + 1
	if has_pool:
		# Water lit from under, on the roof's other side; one in three reaching out past its edge on glass.
		var lw := w * _rng.randf_range(0.28, 0.42)
		var ld := d * _rng.randf_range(0.45, 0.8)
		var out := _rng.randf() < 0.35
		var c := p + u * ((w - lw) * 0.5 + (lw * 0.45 if out else 0.0)) + v * (d - ld) * 0.5 * _rng.randf_range(-1.0, 1.0)
		_part(_pools, c, yaw, Vector3(lw, 1.6, ld), top, Color(sd, 1.0, 0.0, 1.0 if out else 0.0))
		stats.pools = int(stats.get("pools", 0)) + 1


## The towers on the plan's blocks: a podium over each block, and the towers it carries, turned with
## their streets (the author, 2026-10-12: « je veux pas d'effet grille »).
func _build_from_plan() -> void:
	var plan: Resource = load(PLAN_PATH)
	var s: PackedFloat32Array = plan.get_meta("sites")
	var cols: int = plan.get_meta("columns")
	var foot := _ground_y - 2.0
	var tall := 0
	for i in range(0, s.size(), cols):
		var kind := int(s[i])
		var p := Vector2(s[i + 1], s[i + 2])
		var yaw: float = s[i + 3]
		var w: float = s[i + 4]
		var d: float = s[i + 5]
		var dens: float = s[i + 6]
		var sd: float = s[i + 7]
		var r := p.length()
		var low := r < R0 - 90.0
		if p.distance_to(_at(LANDMARKS_AT.x, LANDMARKS_AT.y)) < LANDMARKS_AT.z:
			continue  # the downtown's (make_plan.py leaves it free already)
		if kind == 0:
			var ph := _rng.randf_range(8.0, 20.0) if low else _rng.randf_range(14.0, 36.0) * (0.75 + 0.25 * dens)
			_part(_boxes, p, yaw, Vector3(w, ph, d), foot,
				Color(sd, _rng.randf_range(0.05, 0.16), _rng.randf_range(0.1, 0.35), 1.0 if _rng.randf() < 0.04 else 0.0))
			continue
		var h := _rng.randf_range(38.0, 80.0) if low else _height(r, atan2(p.y, p.x)) * clampf(dens / 1.4, 0.65, 1.5)
		var custom := Color(sd, _rng.randf_range(0.08, 0.36), _rng.randf_range(0.04, 0.2),
			1.0 if h > 520.0 or _rng.randf() < 0.08 else 0.0)
		if kind == 2:
			var rad := (w + d) * 0.25
			_part(_rounds, p, 0.0, Vector3(rad, h, rad), foot, custom)
			if h > 260.0 and _rng.randf() < 0.4:
				_part(_rounds, p, 0.0, Vector3(rad * 0.7, h * 0.12, rad * 0.7), foot + h, Color(custom.r, custom.g, custom.b, 1.0))
			else:
				_roof(p, 0.0, rad * 2.0, rad * 2.0, foot + h, true, sd)
			continue
		_part(_boxes, p, yaw, Vector3(w, h, d), foot, custom)
		if h > 300.0 and _rng.randf() > 0.6:
			var ch := h * _rng.randf_range(0.08, 0.16)
			_part(_boxes, p, yaw, Vector3(w * 0.62, ch, d * 0.62), foot + h, Color(fmod(custom.r + 0.37, 1.0), custom.g * 1.3, custom.b, 1.0))
			if h > 600.0:
				_part(_boxes, p, yaw, Vector3(3.5, h * 0.16, 3.5), foot + h + ch, Color(0.0, 0.0, 0.0, 1.0))
				tall += 1
		else:
			_roof(p, yaw, w, d, foot + h, false, sd)
	_multi("Towers", BoxMesh.new(), 0, _boxes)
	_multi("RoundTowers", _cylinder(20), 1, _rounds)
	_multi("Penthouses", BoxMesh.new(), 3, _penthouses)
	_multi("RoundPenthouses", _cylinder(24), 3, _round_penthouses, {"round_mesh": true})
	_multi("Pools", BoxMesh.new(), 4, _pools)
	stats.towers = (_boxes.xf as Array).size()
	stats.round_towers = (_rounds.xf as Array).size()
	stats.supertall = tall
	stats.plan = true


func _build_towers() -> void:
	if ResourceLoader.exists(PLAN_PATH):
		_build_from_plan()
		return
	var foot := _ground_y - 2.0
	var r := R0
	var tall := 0
	while r < R1:
		var n := int(TAU * r / PITCH)
		var turn := _rng.randf()
		for i in n:
			var a := TAU * (i + turn + _rng.randf_range(-0.3, 0.3)) / n
			var rr := r + _rng.randf_range(-0.3, 0.3) * PITCH
			var p := Vector2(cos(a), sin(a)) * rr
			var h := _height(rr, a)
			var grow := 1.0 + h / 900.0
			var size := Vector3(_rng.randf_range(24.0, 48.0) * grow, h, _rng.randf_range(24.0, 48.0) * grow)
			var roll := _rng.randf()
			var custom := Color(_rng.randf(), _rng.randf_range(0.08, 0.36), _rng.randf_range(0.04, 0.2),
				1.0 if h > 520.0 or _rng.randf() < 0.08 else 0.0)
			if _on_avenue(a, rr) or _blocked(p, maxf(size.x, size.z) * 0.6):
				continue
			if rr < R0 + 260.0 and _rng.randf() < 0.45:
				continue  # the near edge thinner, so that the skyline behind it reads in layers
			if roll < 0.4:
				# Round: a drum of a tower, sometimes stepped in once near its top.
				var rad := (size.x + size.z) * 0.32
				_part(_rounds, p, 0.0, Vector3(rad, h, rad), foot, custom)
				if h > 260.0 and roll < 0.2:
					_part(_rounds, p, 0.0, Vector3(rad * 0.7, h * 0.12, rad * 0.7), foot + h, Color(custom.r, custom.g, custom.b, 1.0))
				continue
			var yaw := -a + (PI * 0.25 if roll > 0.88 else 0.0) + _rng.randf_range(-0.07, 0.07)
			if h > 200.0 and roll < 0.62:
				var ph := _rng.randf_range(22.0, 46.0)
				_part(_boxes, p, yaw, Vector3(size.x * 1.7, ph, size.z * 1.7), foot, Color(custom.r, 0.2, 0.25, 0.0))
			_part(_boxes, p, yaw, size, foot, custom)
			if h > 300.0 and roll > 0.45:
				var ch := h * _rng.randf_range(0.08, 0.16)
				_part(_boxes, p, yaw, Vector3(size.x * 0.62, ch, size.z * 0.62), foot + h, Color(fmod(custom.r + 0.37, 1.0), custom.g * 1.3, custom.b, 1.0))
				if h > 600.0:
					_part(_boxes, p, yaw, Vector3(3.5, h * 0.16, 3.5), foot + h + ch, Color(0.0, 0.0, 0.0, 1.0))
					tall += 1
		r += PITCH
	_multi("Towers", BoxMesh.new(), 0, _boxes)
	_multi("RoundTowers", _cylinder(20), 1, _rounds)
	stats.towers = (_boxes.xf as Array).size()
	stats.round_towers = (_rounds.xf as Array).size()
	stats.supertall = tall


func _multi(node_name: String, mesh: Mesh, shape: int, parts: Dictionary, params := {}) -> void:
	var xf: Array = parts.xf
	var cus: Array = parts.custom
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_custom_data(i, cus[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	var mat := _mat(shape, {"instanced": true})
	for k in params:
		mat.set_shader_parameter(k, params[k])
	if shape <= 1 and ResourceLoader.exists(FACADES_PATH):
		mat.set_shader_parameter("facades", load(FACADES_PATH))
		mat.set_shader_parameter("use_facades", true)
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(mmi)


# --- The ground, the glow, the beams ------------------------------------------------------------

func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 256
	var r0 := R0 - 90.0
	var r1 := R1 + 80.0
	var y := _ground_y - 0.6  # under the gardens' own ground where the two overlap
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p := [Vector3(cos(a0) * r0, y, sin(a0) * r0), Vector3(cos(a1) * r0, y, sin(a1) * r0),
			Vector3(cos(a1) * r1, y, sin(a1) * r1), Vector3(cos(a0) * r1, y, sin(a0) * r1)]
		for tri: Array in [[0, 2, 1], [0, 3, 2]]:
			for j: int in tri:
				st.set_normal(Vector3.UP)
				st.add_vertex(p[j])
	# Behind the palace, the half the gardens leave: the low city from beyond the park round the library
	# wing's court (scripts/library_wing.gd, PARK) out to the towers, so that from the roof the city runs
	# on under the horizon instead of a void. Nearer, its 60 m blocks read as a lit grid.
	var lseg := 128
	for i in lseg:
		var a0 := PI - 0.02 + (PI + 0.04) * i / lseg
		var a1 := PI - 0.02 + (PI + 0.04) * (i + 1) / lseg
		var p := [Vector3(cos(a0) * 595.0, y, sin(a0) * 595.0), Vector3(cos(a1) * 595.0, y, sin(a1) * 595.0),
			Vector3(cos(a1) * (r0 + 5.0), y, sin(a1) * (r0 + 5.0)), Vector3(cos(a0) * (r0 + 5.0), y, sin(a0) * (r0 + 5.0))]
		for tri: Array in [[0, 2, 1], [0, 3, 2]]:
			for j: int in tri:
				st.set_normal(Vector3.UP)
				st.add_vertex(p[j])
	var mat := _mat(2)
	if ResourceLoader.exists(AERIAL_PATH):
		mat.set_shader_parameter("aerial", load(AERIAL_PATH))
		mat.set_shader_parameter("has_aerial", true)
		stats.aerial = true
	var rings: Array[Vector4] = []
	for k in mini(_rings.size(), 8):
		rings.append(_rings[k])
	while rings.size() < 8:
		rings.append(Vector4.ZERO)
	mat.set_shader_parameter("rings", rings)
	mat.set_shader_parameter("ring_count", mini(_rings.size(), 8))
	_add_to(self, "Ground", st.commit(), mat)
	stats.ground_rings = mini(_rings.size(), 8)


func _glow_mat(colour: Color, energy: float, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(GLOW_SHADER_PATH)
	m.set_shader_parameter("colour", colour)
	m.set_shader_parameter("energy", energy)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## The city's glow all round the horizon, behind the towers: UV.x stays in the middle (no ends to fade),
## UV.y from its top (0) to its foot (1).
func _build_glow() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 96
	var r := R1 + 140.0
	var lo := _ground_y - 2.0
	var hi := 900.0
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var c0 := Vector3(cos(a0), 0, sin(a0)) * r
		var c1 := Vector3(cos(a1), 0, sin(a1)) * r
		for v: Array in [[c0 + Vector3(0, hi, 0), 0.0], [c1 + Vector3(0, hi, 0), 0.0], [c1 + Vector3(0, lo, 0), 1.0],
				[c0 + Vector3(0, hi, 0), 0.0], [c1 + Vector3(0, lo, 0), 1.0], [c0 + Vector3(0, lo, 0), 1.0]]:
			st.set_uv(Vector2(0.5, v[1]))
			st.add_vertex(v[0])
	_add_to(self, "CityGlow", st.commit(), _glow_mat(GLOW_COLOUR, 0.16, {"fade_top": 0.97, "fade_foot": 0.02, "edge": 0.5,
		"near_fade_from": -1.0, "near_fade_to": 0.0}))


## Columns of light from the plazas: two crossed sheets each, brightest at the foot; each column's foot in UV2,
## by which assets/palace_glow.gdshader's mode 4 sways it or turns it as a searchlight, with pulses rising up it.
func _build_beams() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foot := _ground_y - 2.0
	for b in _beams:
		for s in 2:
			var d := Vector3(1, 0, 0) if s == 0 else Vector3(0, 0, 1)
			var w := 16.0
			var p := Vector3(b.x, foot, b.y)
			var lo0 := p - d * w
			var lo1 := p + d * w
			var hi0 := lo0 + Vector3(0, b.z, 0)
			var hi1 := lo1 + Vector3(0, b.z, 0)
			for v: Array in [[hi0, Vector2(0, 0)], [hi1, Vector2(1, 0)], [lo1, Vector2(1, 1)], [hi0, Vector2(0, 0)], [lo1, Vector2(1, 1)], [lo0, Vector2(0, 1)]]:
				st.set_uv(v[1])
				st.set_uv2(Vector2(b.x, b.y))
				st.add_vertex(v[0])
	var beams := _add_to(self, "Beams", st.commit(), _glow_mat(BEAM_COLOUR, 0.16, {"fade_top": 0.92, "fade_foot": 0.03,
		"edge": 0.85, "near_fade_from": -1.0, "near_fade_to": 0.0, "mode": 4, "beam_foot_y": foot}))
	# Leaning, their tops go past the sheets' bounds.
	beams.extra_cull_margin = 400.0
	stats.beams = _beams.size()
