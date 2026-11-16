@tool
extends Node3D
## Hari Seldon in white marble, on a dark marble pedestal with a gilt inscription. observatory.gd
## stands it in the hall on the axis of the last bay, the Streeling University shelves, facing
## the centre. The figure is a TRELLIS.2 mesh generated locally from a Z-Image-Turbo concept,
## remeshed in ComfyUI and normalised in Blender (artpass/statue/NOTES.md): 1 unit high, feet at
## the origin, facing +Z.

const MESH_PATH := "res://assets/seldon_statue.glb"
const MARBLE_SHADER_PATH := "res://assets/statue_marble.gdshader"
const MARBLE_PATH := "res://assets/stone_marble.png"  # observatory.gd's marble
const FIGURE_HEIGHT := 2.2  # metres, the figure with its own square base: a little over life size
## The sphere in his hands, fitted in the normalised mesh (artpass/statue/logs/08-sphere-fit.log).
const SPHERE_CENTRE := Vector3(0.027, 0.642, 0.112)
const SPHERE_RADIUS := 0.044
## Only the statue and its pedestal take its key light, so the floor keeps within the
## Compatibility renderer's per-object light limit.
const LIGHT_LAYER := 1 << 3
## "Born in the 11,988th year of the Galactic Era; died 12,069" (Encyclopedia Galactica, in
## Asimov's Foundation). The era's abbreviation follows the reader's language.
const DATES := {"en": "11988 – 12069 G.E.", "fr": "11988 – 12069 E.G.", "es": "11988 – 12069 E.G."}
const GILT := Color(0.8, 0.62, 0.33)
const INCISED := Color(0.03, 0.03, 0.04)
## The pedestal's pieces, by the half-width of the square each one's section grows from: a profile
## point d out from it has corners of radius d, so a piece's eased edges, beads and ovolo are true
## offsets of its faces round the corners. The die's face is 12 mm out: its corners are 12 mm.
const S_BASE := 0.73
const S_STEP := 0.625
const S_DIE := 0.588
const S_SLAB := 0.7
## The inscription reads its glyphs through mipmaps, filtered anisotropically (the scene agent's fourth
## pass, artpass/agent/NOTES.md). The fallback font has none: seen edge-on the letters broke into a
## column of gilt dots, from across the hall the dates lost strokes, and both crawled as the eye moved.
## false: the letters as before.
const INSCRIPTION_MIPMAPS := true

var stats := {}
var _obs: Node3D
var _dates: Array[Label3D] = []


## Called by observatory.gd before add_child: its materials (gold, dark stone) and marble.
func configure(observatory: Node3D) -> void:
	_obs = observatory


func _ready() -> void:
	_build()


## The inscription's second line in the reader's language; observatory.gd passes the course
## shelves' choice.
func set_lang(lang: String) -> void:
	for label in _dates:
		label.text = DATES.get(lang, DATES.en)
	stats.lang = lang if DATES.has(lang) else "en"


func _build() -> void:
	stats = {"figure": false, "lang": "en"}
	var m: Dictionary = _obs.get("_m")
	var dark: Material = m.get("stone_blocks", m.stone_dark)

	# Pedestal: a base with an eased edge, a step with a bullnose, a die of dark marble between two
	# gilt beads, an ovolo under the cornice's slab and a third bead round the slab. Each moulding
	# is its profile swept round a rounded square (observatory.gd, moulding): the stacked boxes it
	# replaces had sharp arrises that sparkled, and level faces that fought for the depth test
	# (pedestal_probe.gd). A profile point's d is its distance out from its piece's square.
	var top := 1.32
	var base := [Vector2(S_BASE, S_BASE)]
	var step := [Vector2(S_STEP, S_STEP)]
	var die := [Vector2(S_DIE, S_DIE)]
	var slab := [Vector2(S_SLAB, S_SLAB)]
	var p := [[Vector2(0.02, 0.0), Vector2(1, 0)] + base]
	_obs.call("profile_arc", p, Vector2(0.01, 0.19), 0.01, 0.01, 0.0, PI / 2, 4, base)
	p.append([Vector2(0.035, 0.2), Vector2(0, 1)] + step)
	p.append([Vector2(0.035, 0.2), Vector2(1, 0)] + step)
	_obs.call("profile_arc", p, Vector2(0.005, 0.27), 0.03, 0.03, 0.0, PI / 2, 6, step)
	p.append([Vector2(0.012, 0.3), Vector2(0, 1)] + die)
	p.append([Vector2(0.012, 0.3), Vector2(1, 0)] + die)
	p.append([Vector2(0.012, 1.1), Vector2(1, 0)] + die)
	_obs.call("profile_arc", p, Vector2(0.012, 1.2), 0.06, 0.1, -PI / 2, 0.0, 8, die)
	p.append([Vector2(0.072, 1.2), Vector2(0, -1)] + die)
	_obs.call("profile_arc", p, Vector2(0.012, 1.208), 0.008, 0.008, -PI / 2, 0.0, 3, slab)
	_obs.call("profile_arc", p, Vector2(0.01, top - 0.01), 0.01, 0.01, 0.0, PI / 2, 4, slab)
	# The top, as a last strip in to a 1 mm square under the figure's base.
	p.append([Vector2(0.0005, top), Vector2(0, 1), Vector2(0.0005, 0.0005)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_obs.call("moulding", st, p)
	_layer(_obs.call("_add", self, "Pedestal", st.commit(), dark, Transform3D()))
	# Half-round beads: the die's two rest on the step and under the ovolo, each end on a face at a
	# right angle, so no gilt face lies in a stone one.
	var gilt := SurfaceTool.new()
	gilt.begin(Mesh.PRIMITIVE_TRIANGLES)
	for bead in [[Vector2(0.012, 0.3175), 0.0175, die], [Vector2(0.012, 1.0825), 0.0175, die], [Vector2(0.02, 1.3), 0.01, slab]]:
		_obs.call("moulding", gilt, _obs.call("profile_bead", bead[0], bead[1], Vector2(1, 0), 8, bead[2]))
	_layer(_obs.call("_add", self, "PedestalGilt", gilt.commit(), m.gold, Transform3D(), false))

	# Inscription on the face towards the hall: gilt letters over their own incised shadow.
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	if INSCRIPTION_MIPMAPS and ThemeDB.fallback_font is FontFile:
		# On a copy, so the interface's own text keeps the font as it was.
		var glyphs := ThemeDB.fallback_font.duplicate() as FontFile
		glyphs.generate_mipmaps = true
		font.base_font = glyphs
	stats.inscription_mipmaps = font.base_font != ThemeDB.fallback_font
	font.spacing_glyph = 6
	# [text, height of the line on the die, metres per font pixel]: capitals about 7 and 4.5 cm high.
	var lines := [["HARI SELDON", 0.78, 0.0015], ["", 0.6, 0.00095]]
	for i in lines.size():
		for shadow in [true, false]:
			var label := Label3D.new()
			label.name = "Inscription%d%s" % [i, "Shadow" if shadow else ""]
			label.font = font
			label.font_size = 64
			label.outline_size = 0
			label.pixel_size = lines[i][2]
			label.text = lines[i][0]
			# Gold leaf: the letters keep their shine whatever the light; their incised shadow is lit.
			label.shaded = shadow
			if stats.inscription_mipmaps:
				label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			label.double_sided = false
			label.modulate = INCISED if shadow else GILT
			label.position = Vector3(0.0025, lines[i][1] - 0.0025, 0.6012) if shadow else Vector3(0, lines[i][1], 0.603)
			label.layers = LIGHT_LAYER | 1
			add_child(label)
			if i == 1:
				_dates.append(label)
	set_lang("en")

	# The figure, from the imported GLB, in statuary marble.
	if not ResourceLoader.exists(MESH_PATH):
		return
	var scene: Node = (load(MESH_PATH) as PackedScene).instantiate()
	var src := scene.find_children("*", "MeshInstance3D", true, false)
	if src.is_empty():
		scene.free()
		return
	var mesh: Mesh = (src[0] as MeshInstance3D).mesh
	scene.free()
	var marble := ShaderMaterial.new()
	marble.shader = load(MARBLE_SHADER_PATH)
	if ResourceLoader.exists(MARBLE_PATH):
		marble.set_shader_parameter("marble", load(MARBLE_PATH))
	var figure_xf := Transform3D(Basis.from_scale(Vector3.ONE * FIGURE_HEIGHT), Vector3(0, top, 0))
	_layer(_obs.call("_add", self, "Figure", mesh, marble, figure_xf))

	# The sphere in his hands glows faintly green, like the data rain: a Prime Radiant.
	var glow := SphereMesh.new()
	glow.radius = SPHERE_RADIUS * 1.1  # in the figure's units: figure_xf scales it
	glow.height = glow.radius * 2.0
	glow.radial_segments = 24
	glow.rings = 12
	var radiant: StandardMaterial3D = m.green_glow.duplicate()
	radiant.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	radiant.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	radiant.albedo_color = Color(0, 0, 0, 1)
	radiant.emission_energy_multiplier = 0.9
	if bool(_obs.call("_compatibility")):
		# Compatibility draws the marble near white, and green added to white is white: blend it over,
		# dimmer, so the sphere still reads as green glass in his hands.
		radiant.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		radiant.albedo_color = Color(0.04, 0.2, 0.1, 0.7)
		radiant.emission_energy_multiplier = 0.3
	_obs.call("_add", self, "PrimeRadiant", glow, radiant, figure_xf * Transform3D(Basis(), SPHERE_CENTRE), false)

	# A warm key light from high on the hall side, for the statue alone.
	var key := SpotLight3D.new()
	key.name = "StatueKey"
	var aim := Vector3(0, top + FIGURE_HEIGHT * 0.6, 0)
	key.transform = Transform3D(Basis(), Vector3(0, top + 5.5, 4.2)).looking_at(aim, Vector3.UP)
	key.light_color = Color(1.0, 0.86, 0.68)
	key.light_energy = 8.0
	key.light_specular = 0.4
	key.spot_range = 10.0
	key.spot_angle = 16.0
	key.spot_attenuation = 0.8
	key.light_cull_mask = LIGHT_LAYER
	key.shadow_enabled = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	key.light_volumetric_fog_energy = 0.0
	add_child(key)
	stats.figure = true
	stats.figure_faces = mesh.get_faces().size() / 3


func _layer(mi: MeshInstance3D) -> void:
	mi.layers = LIGHT_LAYER | 1

