extends RefCounted
## What the fork's path tracer needs of the scene beyond dlss_play.gd's F9, applied when it starts and
## undone when it stops (artpass/dlss/NOTES.md, "Foundation path traced", 2026-10-12):
##   - the night sky: the Environment shows a Sky drawn by pt_night_sky.gdshader (assets/night_sky.gdshader
##     as a sky shader) with the dome's own uniforms, the Galaxy's photograph among them. Without it a ray
##     that left the scene read a radiance map the colour background never filled: a black sky, and no
##     Milky Way through the oculus or over the city. Radiance 2048 (a texel about 0.1 degree; the rays
##     read the sky there, also from the camera), computed once (PROCESS_MODE_QUALITY: it does not move);
##   - the gardens' trees (scripts/palace_gardens.gd, _veg): their meshes give way to painted views past
##     near_r from the eye, a distance garden_plant.gdshader takes from MODEL_MATRIX's origin. In the rays a
##     MultiMesh is one object, its origin the node's, so every tree measured as far and dithered itself
##     away, while the views are cards turned to the camera by their vertex stage, which the rays never
##     run on the geometry. Path traced: the meshes everywhere (near_r 0, their chunks' visibility range
##     off), the views that stand for them gone (near_r beyond any distance: they discard themselves).
## restore() puts all of it back for the rasterizer.

const SKY_SHADER_FILE := "pt_night_sky.gdshader"
const RADIANCE_PX := 2048
const FAR_AWAY := 1.0e6

var _env: Environment
var _saved_env := {}
var _saved_params: Array = []   # [material, parameter, value]
var _saved_nodes: Array = []    # [node, property, value]


static func _dome_material(dome: Node) -> ShaderMaterial:
	if dome == null:
		return null
	for n: Node in [dome] + dome.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if gi == null:
			continue
		if gi.material_override is ShaderMaterial:
			return gi.material_override
		var mi := gi as MeshInstance3D
		if mi != null and mi.mesh != null:
			if mi.get_surface_override_material(0) is ShaderMaterial:
				return mi.get_surface_override_material(0)
			if mi.mesh.surface_get_material(0) is ShaderMaterial:
				return mi.mesh.surface_get_material(0)
	return null


func _param(m: ShaderMaterial, name: String, value: Variant) -> void:
	_saved_params.append([m, name, m.get_shader_parameter(name)])
	m.set_shader_parameter(name, value)


func _prop(n: Object, name: String, value: Variant) -> void:
	_saved_nodes.append([n, name, n.get(name)])
	n.set(name, value)


func apply(scene: Node, env: Environment, dome: Node) -> Dictionary:
	var r := {}
	_env = env
	# The sky.
	var shader := Shader.new()
	shader.code = FileAccess.get_file_as_string((get_script() as Script).resource_path.get_base_dir().path_join(SKY_SHADER_FILE))
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var src := _dome_material(dome)
	var copied := 0
	if src != null:
		for u in shader.get_shader_uniform_list():
			var v: Variant = src.get_shader_parameter(u.name)
			if v != null:
				mat.set_shader_parameter(u.name, v)
				copied += 1
	# A radiance texel's angle: an octahedral map of n x n texels covers 4 pi steradians.
	mat.set_shader_parameter("px_cube", sqrt(4.0 * PI) / RADIANCE_PX)
	var sky := Sky.new()
	sky.sky_material = mat
	sky.radiance_size = Sky.RADIANCE_SIZE_2048
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	_saved_env = {"background_mode": env.background_mode, "sky": env.sky}
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	r.sky = {"dome_material": src != null, "uniforms_copied": copied, "radiance": RADIANCE_PX}
	# The trees.
	var gardens: Node = null
	for n in scene.find_children("*", "Node3D", true, false):
		var s := n.get_script() as Script
		if s != null and s.resource_path.ends_with("palace_gardens.gd"):
			gardens = n
			break
	if gardens != null:
		var veg: Dictionary = gardens.get("_veg")
		if bool(veg.get("ok", false)):
			for m: ShaderMaterial in veg.near_mats:
				_param(m, "near_r", 0.0)
			for m: ShaderMaterial in veg.far_mats:
				_param(m, "near_r", FAR_AWAY)
			for c: MultiMeshInstance3D in veg.chunks:
				_prop(c, "visible", true)
				_prop(c, "visibility_range_end", 0.0)
			r.trees = {"near_materials": (veg.near_mats as Array).size(), "views_hidden": (veg.far_mats as Array).size(),
				"chunks": (veg.chunks as Array).size()}
	return r


func restore() -> void:
	if _env != null and not _saved_env.is_empty():
		_env.background_mode = _saved_env.background_mode
		_env.sky = _saved_env.sky
	_saved_env = {}
	for i in range(_saved_params.size() - 1, -1, -1):
		var e: Array = _saved_params[i]
		(e[0] as ShaderMaterial).set_shader_parameter(e[1], e[2])
	_saved_params.clear()
	for i in range(_saved_nodes.size() - 1, -1, -1):
		var e: Array = _saved_nodes[i]
		(e[0] as Object).set(e[1], e[2])
	_saved_nodes.clear()
