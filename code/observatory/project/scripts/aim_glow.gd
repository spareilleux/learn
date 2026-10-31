extends RefCounted
## One look for whatever in the scene can be clicked, while the view or the pointer rests on it (the author,
## 2026-10-18, relayed by IX's session: « quand on regarde les choses qui sont cliquables, par exemple les cours, ça
## devrait avoir un style particulier, comme un espèce de glow. Alors peut-être que l'objet devrait s'allumer »).
## The object lights up from within, with a warm rim breathing slowly. The light is laid over the object's own
## materials (material_overlay), which it leaves untouched. Each object gets its own copy of the material, so that it
## eases in and out on its own: `amount` 0 to 1.
## Used by scripts/holo_tree.gd (the glass pieces) and scripts/course_library.gd (a shell round the aimed book, its
## books being instances of one MultiMesh). Additive and unshaded, so it draws the same under Compatibility.

const GLOW := Color(1.0, 0.84, 0.52)
const SHADER := """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
uniform vec3 glow = vec3(1.0, 0.84, 0.52);
uniform float amount = 0.0;
uniform float body = 0.2;
void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float breath = 0.85 + 0.15 * sin(TIME * 2.6);
	ALBEDO = glow * (body + 0.85 * rim) * amount * breath;
}
"""
static var _shader: Shader


static func make(amount := 0.0, body := 0.2) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	# Set, not left to the default: the RTX fork packs an unset colour default as linear.
	m.set_shader_parameter("glow", Vector3(GLOW.r, GLOW.g, GLOW.b))
	m.set_shader_parameter("amount", amount)
	m.set_shader_parameter("body", body)
	return m


## Every mesh at and under `node` lit by `amount`; at 0, its overlay taken off.
static func light(node: Node, amount: float) -> void:
	if node == null or not is_instance_valid(node):
		return
	for mi: MeshInstance3D in _meshes(node):
		if amount <= 0.0:
			if mi.has_meta("aim_glow"):
				mi.material_overlay = null
				mi.remove_meta("aim_glow")
			continue
		var m: ShaderMaterial = mi.get_meta("aim_glow") if mi.has_meta("aim_glow") else null
		if m == null:
			m = make()
			mi.set_meta("aim_glow", m)
			mi.material_overlay = m
		m.set_shader_parameter("amount", amount)


static func _meshes(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c: Node in node.get_children():
		out.append_array(_meshes(c))
	return out
