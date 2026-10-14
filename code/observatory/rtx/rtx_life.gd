extends RefCounted
## What moves in the native RTX package's hall (artpass/publish/rtx/NOTES.md), over the scene as it is, for
## rtx_play.gd's column to switch. The author, 2026-10-14: "si tu as l'opportunité de faire bouger des
## trucs dans la scène, dans la bibliothèque, ça serait sympa […] des petits effets de courant d'air […] les
## bandeaux où il y a marqué le département […] comme du tissu", "les rayons verts, ça manque un peu de
## feeling à la Matrix […] les symboles qui défilent", "un peu de poussière, mais pas trop".
##   - glyphs: a column of falling glyphs wrapped round each green rain beam, and a curtain of them round
##     the central bundle (GLYPH_SHADER). Each glyph is drawn from strokes on a 3 x 4 lattice chosen by a
##     hash, so they are this scene's own: no font and no image file. Blended additively, so the fork draws
##     them over the path traced picture rather than in its rays (see GLYPH_SHADER's comment).
##   - cloth: the course banners (course_library.gd's CourseBanners, a flat quad each) as cloth hanging from
##     their brass rod, moved by a draught: one mesh of 9 x 17 vertices whose blend shapes are waves that run
##     down the cloth (a sine and a cosine each: their weights cos and -sin of the time make a travelling
##     wave), a swing about the rod and a twist; their weights follow gusts that go round the hall. The
##     lettering, the gilt edges and the hem, which stood in front of the flat quad, are drawn into the cloth
##     (a texture rendered once from the banner's own Label3D lines), so they move with it.
##   - dust: a few motes drifting round the eye, lit by the scene's lights; few and small ("pas trop").
## Each one can be switched off and on; the scene rebuilds itself when one of its settings changes, and
## what was built here with it: looked for again every second.

## The glyphs: 64 of them drawn once into an atlas (ATLAS_SHADER, a canvas shader rendered in a SubViewport at
## the start), each from strokes on a 3 x 4 lattice chosen by a hash; the beams' shader reads the atlas, with
## mipmaps for the distant beams. Cut out by discard, unshaded, the tubes were in the path tracer's rays, whose hit
## shaders ran for every ray that met one: 16.7 to 17.0 ms a frame at the start view, path traced at DLSS
## Quality, against 15.2 without them, whether the strokes were drawn in the shader or read from the atlas, the
## clock TIME or a uniform, set every frame or ten times a second. Blended additively, the fork leaves them out of
## the rays and draws them over its picture: 15.25 ms (2026-10-14, seq-glyphcost4). They light nothing, which as
## emitters among thousands of surfaces they hardly did.
const GLYPH_LIB := """
uint mix32(uint x) {
	x ^= x >> 16u;
	x *= 2146121005u;
	x ^= x >> 15u;
	x *= 2221713035u;
	x ^= x >> 16u;
	return x;
}

float h01(uint x) {
	return float(mix32(x) & 16777215u) / 16777216.0;
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * t);
}

// A glyph: strokes between the points of a 3 x 4 lattice, each there when its bit is set.
float glyph(vec2 q, uint g, uint diag) {
	float d = 9.0;
	int bit = 0;
	for (int r = 0; r < 4; r++) {
		for (int c = 0; c < 2; c++) {
			if (((g >> uint(bit)) & 1u) == 1u) {
				d = min(d, seg(q, vec2(float(c) * 0.5, float(r) / 3.0), vec2(float(c) * 0.5 + 0.5, float(r) / 3.0)));
			}
			bit++;
		}
	}
	for (int c = 0; c < 3; c++) {
		for (int r = 0; r < 3; r++) {
			if (((g >> uint(bit)) & 1u) == 1u) {
				d = min(d, seg(q, vec2(float(c) * 0.5, float(r) / 3.0), vec2(float(c) * 0.5, float(r + 1) / 3.0)));
			}
			bit++;
		}
	}
	for (int c = 0; c < 2; c++) {
		for (int r = 0; r < 3; r++) {
			int k = c * 3 + r;
			if (((diag >> uint(k)) & 1u) == 1u) {
				bool down = ((diag >> uint(k + 8)) & 1u) == 1u;
				vec2 a = vec2(float(c) * 0.5, float(down ? r : r + 1) / 3.0);
				vec2 b = vec2(float(c) * 0.5 + 0.5, float(down ? r + 1 : r) / 3.0);
				d = min(d, seg(q, a, b));
			}
		}
	}
	return d;
}
"""

const ATLAS_SHADER := """shader_type canvas_item;
uniform float stroke = 0.12;   // half a stroke's width, in the glyph's own units
// LIB
void fragment() {
	vec2 at = UV * 8.0;
	vec2 id = floor(at);
	uint cid = uint(id.y) * 8u + uint(id.x) + 101u;
	uint g = mix32(cid * 31u) & mix32(cid * 37u + 11u);
	g |= 1u << (8u + (mix32(cid * 3u) % 9u));  // never empty: one upright stroke at least
	uint diag = mix32(cid * 41u + 23u) & mix32(cid * 43u + 29u) & mix32(cid * 47u + 31u);
	diag = (diag & 63u) | (mix32(cid * 53u) & 16128u);
	vec2 q = (fract(at) - vec2(0.2, 0.14)) / vec2(0.6, 0.72);
	float d = glyph(q, g, diag);
	COLOR = vec4(1.0, 1.0, 1.0, 1.0 - smoothstep(stroke - 0.035, stroke + 0.035, d));
}
"""

const GLYPH_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform vec3 tint : source_color = vec3(0.32, 1.0, 0.55);
uniform float energy = 3.0;
uniform float columns = 4.0;   // glyph columns round the beam
uniform float cell = 0.19;     // a glyph's height, m
uniform float speed = 1.4;     // m/s, a stream's head
uniform float trail = 4.0;     // m of glyphs behind it
uniform float rate = 2.5;      // a glyph's changes a second, at most
varying flat vec2 v_inst;      // the beam's length (m) and a seed
// LIB
void vertex() {
	v_inst = INSTANCE_CUSTOM.xy;
}

void fragment() {
	float len = max(v_inst.x, 0.5);
	vec2 at = vec2(UV.x * columns, UV.y * len / cell);
	vec2 id = floor(at);
	uint col = uint(id.x) + uint(v_inst.y * 65521.0) * 7u;
	float sp = speed * (0.65 + 0.7 * h01(col * 3u + 1u));
	float span = len + trail;
	float head = mod(TIME * sp + h01(col * 3u + 2u) * span, span);
	float behind = head - (id.y + 0.5) * cell;
	float live = step(0.0, behind) * step(behind, trail);
	uint cid = col * 4099u + uint(id.y);
	float t = TIME * rate * (0.15 + 0.85 * h01(cid * 5u + 3u)) + h01(cid * 5u + 4u);
	uint gi = mix32(cid * 31u + uint(t)) % 64u;
	vec2 cellxy = vec2(float(gi % 8u), float(gi / 8u));
	float ink = texture(atlas, (cellxy + fract(at)) / 8.0).a;
	float k = 1.0 - behind / trail;
	vec3 c = tint * k * k;
	if (behind < cell) {
		c = mix(c, vec3(0.8, 1.0, 0.88), 0.75);  // the head, nearly white
	}
	ALBEDO = c * energy * ink * live;
}
"""

const CLOTH_SHADER := """shader_type spatial;
render_mode cull_disabled;
uniform vec3 cloth : source_color = vec3(0.5, 0.2, 0.2);
uniform vec3 gilt : source_color = vec3(0.86, 0.7, 0.4);
uniform sampler2D letters : source_color, filter_linear_mipmap_anisotropic;
uniform vec2 size = vec2(1.3, 2.5);   // m
uniform float glow = 0.5;
uniform float letter_glow = 0.45;

void fragment() {
	vec2 m = UV * size;   // m from the top left
	float fold = 0.8 + 0.2 * sin(UV.x * 31.4) * sin(UV.x * 12.6 + 1.3);
	float hem = mix(0.7, 1.0, 1.0 - smoothstep(0.9, 0.98, UV.y));
	vec3 c = cloth * fold * hem;
	// The gilt edges and hem that stood in front of the flat banner (course_library.gd's brass_xf).
	float edge = min(abs(m.x - 0.05), abs(m.x - (size.x - 0.05)));
	float band = step(edge, 0.009) * step(0.03, m.y) * step(m.y, size.y - 0.03);
	band = max(band, step(size.y - 0.025, m.y));
	// The letters: white in the texture, with a dark outline as Label3D draws them.
	vec4 l = texture(letters, UV);
	float ink = l.a * l.r;
	float g = max(band, ink);
	ALBEDO = mix(mix(c, vec3(0.02), l.a * (1.0 - l.r)), gilt * 0.55, g);
	ROUGHNESS = mix(0.92, 0.45, g);
	METALLIC = 0.7 * g;
	EMISSION = mix(c * glow * fold * (1.0 - l.a), gilt * letter_glow, ink);
}
"""

const NX := 8                 # the cloth's quads across
const NY := 16                # and down
const BANNER := Vector2(1.3, 2.5)  # course_library.gd's BANNER_W, BANNER_H
const LETTERS_PX := 420.0     # the letters' texture, pixels a metre
const DUST := 160
const DUST_BOX := 7.0         # m: the box round the eye the motes drift in

var _p: SceneTree
var _scene: Node
var _on := {"glyphs": true, "cloth": true, "dust": true}
var _glyphs: MultiMeshInstance3D
var _core_glyphs: MultiMeshInstance3D
var _atlas: Texture2D         # the 64 glyphs (_make_atlas)
var _glyph_building := false
var _rain: Node3D             # the scene's Generated/Rain the glyphs were built for
var _banners: Array = []      # [MeshInstance3D, phase, angle round the hall] a banner
var _banner_src: MultiMeshInstance3D
var _hidden: Array[Node3D] = []  # the flat banners' labels, hidden while the cloth hangs there
var _brass: MultiMeshInstance3D
var _brass_was := {}          # instance index: the transform zeroed while the cloth hangs there
var _cloth_mesh: ArrayMesh
var _dust: MultiMeshInstance3D
var _motes := PackedVector3Array()
var _t := 0.0
var _look := 0.0              # seconds to the next look for what the scene rebuilt
var _building := false
var stats := {}


func start(player: SceneTree, scene: Node) -> void:
	_p = player
	_scene = scene


func has(key: String) -> bool:
	match key:
		"glyphs":
			return _rain != null or _find_rain() != null
		"cloth":
			return _banner_src != null or _find_banners() != null
		"dust":
			return true
	return false


func is_on(key: String) -> bool:
	return bool(_on.get(key, false))


func set_on(key: String, on: bool) -> void:
	_on[key] = on
	_look = 0.0
	match key:
		"glyphs":
			for g in [_glyphs, _core_glyphs]:
				if is_instance_valid(g):
					(g as Node3D).visible = on
		"cloth":
			_show_cloth(on)
		"dust":
			if is_instance_valid(_dust):
				_dust.visible = on


func step(delta: float) -> void:
	_t += delta
	_look -= delta
	if _look <= 0.0:
		_look = 1.0
		_keep_up()
	if _on.cloth and not _banners.is_empty():
		_blow()
	if _on.dust and is_instance_valid(_dust):
		_drift(delta)


## What the scene rebuilt, built again for it.
func _keep_up() -> void:
	if _on.glyphs and not is_instance_valid(_glyphs):
		_build_glyphs()
	if _on.cloth and not _building and (_banners.is_empty() or not is_instance_valid(_banners[0][0])):
		_build_cloth()
	if _on.dust and not is_instance_valid(_dust):
		_build_dust()


# The glyphs.

func _find_rain() -> MultiMeshInstance3D:
	return _scene.get_node_or_null("Generated/Rain/RainBeams") as MultiMeshInstance3D


## The atlas: ATLAS_SHADER on a rectangle in a SubViewport of 8 x 8 glyphs of 32 x 42 pixels (a glyph's cell
## on the beams is about 0.14 m wide and 0.19 m tall), read back once, with mipmaps for the distant beams.
func _make_atlas() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 336)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var rect := ColorRect.new()
	rect.size = Vector2(vp.size)
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = ATLAS_SHADER.replace("// LIB", GLYPH_LIB)
	mat.shader = sh
	rect.material = mat
	vp.add_child(rect)
	_p.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.generate_mipmaps()
	_atlas = ImageTexture.create_from_image(img)


func _build_glyphs() -> void:
	var beams := _find_rain()
	if beams == null or beams.multimesh == null or _glyph_building:
		return
	if _atlas == null:
		_glyph_building = true
		await _make_atlas()
		_glyph_building = false
		if not is_instance_valid(beams):
			return
	_rain = beams.get_parent() as Node3D
	var src := beams.multimesh
	var rng := RandomNumberGenerator.new()
	rng.seed = 1984
	# Round each rain beam: a tube of four columns, as long as the beam.
	var xfs: Array[Transform3D] = []
	var customs: Array[Color] = []
	for i in src.instance_count:
		var xf := src.get_instance_transform(i)
		xfs.append(xf)
		customs.append(Color(xf.basis.y.length(), rng.randf(), 0.0, 0.0))
	_glyphs = _glyph_tubes("RtxGlyphRain", 0.09, xfs, customs, {})
	_glyphs.transform = beams.transform
	_rain.add_child(_glyphs)
	stats.glyph_beams = src.instance_count
	# Round the central bundle, from the steel box to the sky: one wide curtain of columns, the hall's own
	# column of falling glyphs, the beams seen through its gaps.
	var core := _rain.get_node_or_null("CoreBeams") as MultiMeshInstance3D
	if core != null and core.multimesh != null and core.multimesh.instance_count > 0:
		var cm := core.multimesh
		var centre := Vector2.ZERO
		var top := -INF
		var bottom := INF
		for i in cm.instance_count:
			var xf := cm.get_instance_transform(i)
			centre += Vector2(xf.origin.x, xf.origin.z) / cm.instance_count
			top = maxf(top, xf.origin.y + xf.basis.y.length() * 0.5)
			bottom = minf(bottom, xf.origin.y - xf.basis.y.length() * 0.5)
		var r := 0.0
		for i in cm.instance_count:
			var o := cm.get_instance_transform(i).origin
			r = maxf(r, Vector2(o.x, o.z).distance_to(centre))
		r += 0.18
		var columns := float(maxi(8, roundi(TAU * r / 0.15)))
		var at := Transform3D(Basis.from_scale(Vector3(r, top - bottom, r)), Vector3(centre.x, (top + bottom) * 0.5, centre.y))
		var curtain := _glyph_tubes("RtxGlyphCore", 1.0, [at], [Color(top - bottom, 0.37, 0.0, 0.0)],
			{"columns": columns, "energy": 2.4, "speed": 1.7, "trail": 3.2})
		curtain.transform = core.transform
		_rain.add_child(curtain)
		_core_glyphs = curtain
		stats.glyph_core = {"radius": snappedf(r, 0.01), "columns": columns, "height": snappedf(top - bottom, 0.01)}
	print("RTXLIFE glyph rain round %d beams and the central bundle" % src.instance_count)


## Glyph tubes of radius r (or 1, scaled by the transforms) at those transforms, with their custom data
## (length, seed), and the shader's uniforms set as given.
func _glyph_tubes(node_name: String, r: float, xfs: Array, customs: Array, uniforms: Dictionary) -> MultiMeshInstance3D:
	var tube := CylinderMesh.new()
	tube.top_radius = r
	tube.bottom_radius = r
	tube.height = 1.0
	tube.radial_segments = 16 if r < 0.5 else 64
	tube.rings = 1
	tube.cap_top = false
	tube.cap_bottom = false
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = tube
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_custom_data(i, customs[i])
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GLYPH_SHADER.replace("// LIB", GLYPH_LIB)
	mat.shader = sh
	mat.set_shader_parameter("atlas", _atlas)
	for k: String in uniforms:
		mat.set_shader_parameter(k, uniforms[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visible = _on.glyphs
	return mmi


# The cloth.

func _find_banners() -> MultiMeshInstance3D:
	for n in _scene.find_children("CourseBanners", "MultiMeshInstance3D", true, false):
		return n as MultiMeshInstance3D
	return null


func _build_cloth() -> void:
	var src := _find_banners()
	if src == null or src.multimesh == null or src.multimesh.instance_count == 0:
		return
	_building = true
	for b: Array in _banners:
		if is_instance_valid(b[0]):
			(b[0] as Node).queue_free()
	_banners.clear()
	_hidden.clear()
	_brass_was.clear()
	_banner_src = src
	if _cloth_mesh == null:
		_cloth_mesh = _make_cloth()
	var lib := src.get_parent() as Node3D
	var mm := src.multimesh
	var labels := lib.find_children("*", "Label3D", false, false)
	_brass = lib.get_node_or_null("CourseBrass") as MultiMeshInstance3D
	var built := 0
	for i in mm.instance_count:
		var xf := src.transform * mm.get_instance_transform(i)  # in the library's frame
		var at := Transform3D(xf.basis.orthonormalized(), xf.origin)
		var lines: Array[Label3D] = []
		for l in labels:
			var local := at.affine_inverse() * (l as Label3D).transform.origin
			if absf(local.x) < BANNER.x * 0.5 and absf(local.y) < BANNER.y * 0.5 and absf(local.z) < 0.02:
				lines.append(l as Label3D)
		var mat := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = CLOTH_SHADER
		mat.shader = sh
		var c := mm.get_instance_color(i) if mm.use_colors else Color(0.5, 0.2, 0.2)
		mat.set_shader_parameter("cloth", c)
		mat.set_shader_parameter("size", BANNER)
		mat.set_shader_parameter("letters", await _letters(lines, at))
		if not is_instance_valid(src):
			_building = false
			return  # the scene rebuilt itself meanwhile
		var mi := MeshInstance3D.new()
		mi.name = "RtxCloth%d" % i
		mi.mesh = _cloth_mesh
		mi.material_override = mat
		mi.transform = at
		lib.add_child(mi)
		var g := lib.global_transform * at.origin
		_banners.append([mi, float(i) * 1.7, atan2(g.z, g.x)])
		_hidden.append_array(lines)
		_hide_brass(at)
		built += 1
	_building = false
	_show_cloth(_on.cloth)
	stats.banners = built
	print("RTXLIFE cloth banners: %d, their %d lines of letters drawn into the cloth" % [built, _hidden.size()])


## The brass hem and side strips of the banner at `at` (course_library.gd's brass_xf: the strips stand in
## front of it, and the cloth now moves through them): found by their place and size, zeroed while the cloth
## hangs there. The rod stays: the cloth hangs from it.
func _hide_brass(at: Transform3D) -> void:
	if _brass == null or _brass.multimesh == null:
		return
	var mm := _brass.multimesh
	for j in mm.instance_count:
		var xf := _brass.transform * mm.get_instance_transform(j)
		var local := at.affine_inverse() * xf.origin
		var s := Vector3(xf.basis.x.length(), xf.basis.y.length(), xf.basis.z.length())
		if absf(local.z) > 0.02 or absf(local.x) > BANNER.x * 0.5 or absf(local.y) > BANNER.y * 0.5:
			continue
		var hem := is_equal_approx(snappedf(s.y, 0.001), 0.025) and s.x <= BANNER.x + 0.001
		var strip := s.x < 0.02 and s.y > BANNER.y * 0.9
		if hem or strip:
			_brass_was[j] = mm.get_instance_transform(j)


func _show_cloth(on: bool) -> void:
	for b: Array in _banners:
		if is_instance_valid(b[0]):
			(b[0] as Node3D).visible = on
	if is_instance_valid(_banner_src):
		_banner_src.visible = not on
	for l in _hidden:
		if is_instance_valid(l):
			l.visible = not on
	if _brass != null and is_instance_valid(_brass) and _brass.multimesh != null:
		for j: int in _brass_was:
			var xf: Transform3D = _brass_was[j]
			_brass.multimesh.set_instance_transform(j, Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), xf.origin) if on else xf)


## The banner's lines of letters rendered once into a texture the size of the cloth, where each Label3D
## stood: the same text, font, size, wrapping and colour.
func _letters(lines: Array[Label3D], at: Transform3D) -> Texture2D:
	var px := Vector2i(roundi(BANNER.x * LETTERS_PX), roundi(BANNER.y * LETTERS_PX))
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.disable_3d = true
	for l in lines:
		var local := at.affine_inverse() * l.transform.origin
		var scale := l.pixel_size * LETTERS_PX  # texture pixels per label pixel
		var lab := Label.new()
		lab.text = l.text
		if l.font != null:
			lab.add_theme_font_override("font", l.font)
		lab.add_theme_font_size_override("font_size", maxi(1, roundi(l.font_size * scale)))
		lab.add_theme_color_override("font_color", Color(1, 1, 1))
		lab.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		lab.add_theme_constant_override("outline_size", roundi(l.outline_size * scale))
		lab.add_theme_constant_override("line_spacing", roundi(l.line_spacing * scale))
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.autowrap_mode = l.autowrap_mode
		var w := l.width * scale
		lab.size = Vector2(w, px.y)
		var centre := Vector2((local.x / BANNER.x + 0.5) * px.x, (0.5 - local.y / BANNER.y) * px.y)
		lab.position = centre - lab.size * 0.5
		vp.add_child(lab)
	_p.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## The cloth: a grid hanging from its top edge, local +Z towards the hall as the flat quad faced, UV (0, 0)
## at the top left; and its blend shapes, each a unit of one motion (metres at the hem for weight 1):
## 0, 1 a wave of 1.6 m running down (sine, cosine), 2, 3 a slanting ripple of 0.9 m (sine, cosine),
## 4 a swing about the rod, 5 a twist.
func _make_cloth() -> ArrayMesh:
	var base := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	for j in NY + 1:
		for i in NX + 1:
			base.append(Vector3((float(i) / NX - 0.5) * BANNER.x, (0.5 - float(j) / NY) * BANNER.y, 0.0))
			uv.append(Vector2(float(i) / NX, float(j) / NY))
	for j in NY:
		for i in NX:
			var a := j * (NX + 1) + i
			idx.append_array([a, a + 1, a + NX + 2, a, a + NX + 2, a + NX + 1])
	var k1 := TAU / 1.6
	var k2 := TAU / 0.9
	var k3 := TAU / 1.1
	var shapes: Array[Callable] = [
		func(x: float, s: float) -> float: return 0.085 * _reach(s) * sin(k1 * s),
		func(x: float, s: float) -> float: return 0.085 * _reach(s) * cos(k1 * s),
		func(x: float, s: float) -> float: return 0.035 * _reach(s) * sin(k2 * s + k3 * x),
		func(x: float, s: float) -> float: return 0.035 * _reach(s) * cos(k2 * s + k3 * x),
		func(x: float, s: float) -> float: return 0.08 * s,
		func(x: float, s: float) -> float: return 0.07 * x * s / BANNER.y,
	]
	var normals := PackedVector3Array()
	normals.resize(base.size())
	normals.fill(Vector3(0, 0, 1))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = base
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	var blends := []
	var mesh := ArrayMesh.new()
	# Normalized: base (1 - sum of weights) + each shape times its weight, so that a shape given as the base
	# plus its motion moves by weight x motion, whatever the sign. Relative added the shapes' positions whole:
	# the banner flew a metre off its rod (2026-10-14, cloth-pt-c and -d).
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for n in shapes.size():
		mesh.add_blend_shape("motion%d" % n)
		var f: Callable = shapes[n]
		var pos := PackedVector3Array()
		var nor := PackedVector3Array()
		for v in base:
			var s := BANNER.y * 0.5 - v.y  # m below the rod
			var e := 0.01
			var dzdx := (float(f.call(v.x + e, s)) - float(f.call(v.x - e, s))) / (2.0 * e)
			var dzds := (float(f.call(v.x, s + e)) - float(f.call(v.x, s - e))) / (2.0 * e)
			pos.append(v + Vector3(0, 0, float(f.call(v.x, s))))
			# z(x, y) with y = H/2 - s: the normal (-dz/dx, -dz/dy, 1) and dz/dy = -dz/ds.
			nor.append(Vector3(-dzdx, dzds, 1.0).normalized())
		var shape := []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX] = pos
		shape[Mesh.ARRAY_NORMAL] = nor
		blends.append(shape)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blends)
	return mesh


## How far the cloth moves s metres below its rod: nothing at the rod, the most at the hem.
func _reach(s: float) -> float:
	return pow(clampf(s / BANNER.y, 0.0, 1.0), 1.3)


## The draught: gusts that go round the hall once a minute or so, each banner's waves and swing weighted by
## the gust where it hangs.
func _blow() -> void:
	for b: Array in _banners:
		var mi := b[0] as MeshInstance3D
		if not is_instance_valid(mi) or not mi.visible:
			continue
		var ph: float = b[1]
		var around: float = b[2]
		var gust := 0.55 + 0.3 * sin(_t * 0.11 - around) + 0.15 * sin(_t * 0.37 + ph)
		gust = clampf(gust, 0.15, 1.0)
		var w1 := 1.9 + 0.2 * sin(ph)
		var w2 := 2.9 + 0.3 * cos(ph)
		mi.set_blend_shape_value(0, gust * cos(_t * w1 + ph))
		mi.set_blend_shape_value(1, -gust * sin(_t * w1 + ph))
		mi.set_blend_shape_value(2, 0.7 * gust * cos(_t * w2 + ph * 2.0))
		mi.set_blend_shape_value(3, -0.7 * gust * sin(_t * w2 + ph * 2.0))
		mi.set_blend_shape_value(4, gust * (0.5 + 0.5 * sin(_t * 0.8 + ph)))
		mi.set_blend_shape_value(5, 0.6 * gust * sin(_t * 0.53 + ph * 3.0))


# The dust.

func _build_dust() -> void:
	var cam := _p.root.get_camera_3d()
	if cam == null:
		return
	var mote := SphereMesh.new()
	mote.radius = 0.0022
	mote.height = 0.0044
	mote.radial_segments = 6
	mote.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.86, 0.74)
	mat.roughness = 1.0
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.82, 0.68)
	mat.emission_energy_multiplier = 0.08
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mote
	mm.instance_count = DUST
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_motes.resize(DUST)
	var corner := cam.global_position - Vector3.ONE * DUST_BOX * 0.5
	for i in DUST:
		_motes[i] = corner + Vector3(rng.randf(), rng.randf(), rng.randf()) * DUST_BOX
	_dust = MultiMeshInstance3D.new()
	_dust.name = "RtxDust"
	_dust.top_level = true  # the motes' places are the world's
	_dust.multimesh = mm
	_dust.material_override = mat
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dust.visible = _on.dust
	_scene.add_child(_dust)
	_drift(0.0)
	stats.dust = DUST


## Each mote drifts on a slow swirl and settles a little, where it is in the world; the box they fill
## follows the eye: a mote it leaves behind on one side comes back on the other.
func _drift(delta: float) -> void:
	var cam := _p.root.get_camera_3d()
	if cam == null:
		return
	var corner := cam.global_position - Vector3.ONE * DUST_BOX * 0.5
	var buf := PackedFloat32Array()
	buf.resize(DUST * 12)
	for i in DUST:
		var w := _motes[i]
		var v := Vector3(sin(w.y * 0.9 + _t * 0.21) + 0.5 * sin(w.z * 1.7 + _t * 0.4),
			-0.35 + 0.5 * sin(w.x * 1.1 + w.z * 0.7 + _t * 0.17),
			cos(w.x * 0.8 - _t * 0.23) + 0.5 * cos(w.y * 1.5 + _t * 0.31)) * 0.035
		var rel := w + v * delta - corner
		var p := corner + Vector3(fposmod(rel.x, DUST_BOX), fposmod(rel.y, DUST_BOX), fposmod(rel.z, DUST_BOX))
		_motes[i] = p
		var o := i * 12
		buf[o] = 1.0
		buf[o + 5] = 1.0
		buf[o + 10] = 1.0
		buf[o + 3] = p.x
		buf[o + 7] = p.y
		buf[o + 11] = p.z
	_dust.multimesh.buffer = buf
