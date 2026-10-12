@tool
extends Node3D
## Weathered steel research box at the centre of the atrium: riveted panels,
## a door left ajar, and warm light spilling from a corridor of receding doors.
## door_open_degrees updates the hinge live; the other values rebuild the box.

@export var box_size := Vector3(4.0, 4.4, 4.0):
	set(value):
		box_size = value
		_queue_rebuild()
@export_range(0.0, 110.0, 1.0) var door_open_degrees := 38.0:
	set(value):
		door_open_degrees = value
		stats.door_open_degrees = value
		if is_instance_valid(_hinge):
			_hinge.rotation.y = -deg_to_rad(value)
## Art pass: use the Blender-authored shell (assets/steel_portal.glb, from
## artpass/blender/steel_portal.blend). Off, or if the file is missing: procedural boxes.
@export var use_blender_shell := true:
	set(value):
		use_blender_shell = value
		_queue_rebuild()
## Detail pass: SP_Steel panels get assets/steel_brushed.gdshader (fully metallic, anisotropic,
## ComfyUI stains and streaks) and the dark frames a gunmetal finish. Off: the GLB's materials.
@export var steel_detail := true:
	set(value):
		steel_detail = value
		_queue_rebuild()
@export var shell_scene: PackedScene:
	set(value):
		shell_scene = value
		_queue_rebuild()
## Two cool spotlights that give the steel readable highlights against the dark hall.
@export_range(0.0, 20.0, 0.1) var key_light_energy := 5.0:
	set(value):
		key_light_energy = value
		_queue_rebuild()
@export var warm_color := Color(1.0, 0.72, 0.42):
	set(value):
		warm_color = value
		_queue_rebuild()
@export_range(0.0, 20.0, 0.1) var warm_energy := 4.5:
	set(value):
		warm_energy = value
		_queue_rebuild()
## DoorSpill energy as a multiple of warm_energy (v1: 2.2). At 2.2 its highlight on the
## polished floor clipped to a white streak (finish pass).
@export_range(0.0, 5.0, 0.1) var spill_ratio := 1.2:
	set(value):
		spill_ratio = value
		_queue_rebuild()
## DoorSpill's specular term (v1: 1.0). Its highlight on the polished floor at a grazing
## angle saturates whatever the energy, so it is damped here instead.
@export_range(0.0, 1.0, 0.05) var spill_specular := 0.2:
	set(value):
		spill_specular = value
		_queue_rebuild()
@export_range(1, 16, 1) var corridor_doors := 9:
	set(value):
		corridor_doors = value
		_queue_rebuild()
## Gaia art pass (OBSERVATORY-GAIA-ART-20261006), built in the isolated copy C:/tmp/observatory-gaia
## and taken into the prototype, with the Blender shell and preset 3, after "applique la nouvelle
## boîte au prototype" (the author, 2026-10-06). On the steel box only: panel joints, rounded vertical edges, a slight per-plate cast and a hand-polished patch by the handle on
## the steel (assets/steel_brushed.gdshader); a door that glows warm rather than near-white; a softer
## green receiver. The DoorSpill pool on the floor is kept. Off: the box as before.
@export var gaia_art := true:
	set(value):
		gaia_art = value
		_queue_rebuild()
## Gaia steel, against "La boite fait encore tres cartoon" (the author, 2026-10-06, on the first
## path-traced renders of the gaia pass): 1 = that first pass alone; 2 and 3 also dim the two cool
## keys that lit the front flat and even, smooth the sheet so that it mirrors the hall under the path
## tracer, darken it a little, and strengthen stains, streaks, run-off, dust and plate-to-plate tone.
## 3 goes further than 2 (GAIA_STEEL). Read only while gaia_art is on. The author chose 3: "garde le
## preset 3" (2026-10-06, after the presets page and the Blender shell renders).
@export_range(1, 3, 1) var gaia_steel := 3:
	set(value):
		gaia_steel = value
		_queue_rebuild()
## Gaia geometry, after "ok repare la geometrie de la boite" / "utilise blender" (2026-10-06): the
## shell rebuilt in Blender (steel_portal_gaia.py: artpass/blender/ in the prototype, artpass/gaia/blender/
## in the gaia copy; assets/steel_portal_gaia.glb):
## the sheet folded round the corners instead of round rods, slimmer bands, smaller and irregular
## rivets, a stepped cornice and plinth, hinges, a lever handle, a conduit. Same footprint, door,
## band heights, node and material names. Read only while gaia_art is on; off: steel_portal.glb.
@export var gaia_shell := true:
	set(value):
		gaia_shell = value
		_queue_rebuild()

var stats := {}
var _rebuild_pending := false
var _hinge: Node3D

const SHELL_PATH := "res://assets/steel_portal.glb"
const SHELL_GAIA_PATH := "res://assets/steel_portal_gaia.glb"
const STEEL_SHADER_PATH := "res://assets/steel_brushed.gdshader"
const STEEL_GRIME_PATH := "res://assets/steel_grime.png"
const DOOR_W := 1.5
const DOOR_H := 2.8
const WALL := 0.14
const VANISH_Y := 1.45
## gaia_steel 2 and 3: roughness_scale of plates and door (1.3 before) and of the trims (1.45),
## anisotropy (0.25), oil-canning (0.05), stain and streak strength (1, 1), run-off (0.5) and dust
## (0.5) on the plates, plate variation (0.11 in the first gaia pass), a factor on every base colour,
## and one on the keys' energy (key_light_energy, 5). The corridor behind the door: the cream's colour
## and glow (first gaia pass: (0.8, 0.69, 0.52), 0.15), the doorframes' and far door's factor (door_k,
## 0.5), the jamb glow's (0.56), and the interior light's energy factor (0.7) and depth (z 0.3 m).
const GAIA_STEEL := {
	2: {"rough": 1.0, "trim_rough": 1.2, "aniso": 0.4, "oil_can": 0.08, "stain": 1.5, "streak": 1.4,
		"run": 0.7, "dust": 0.65, "plate": 0.15, "base_k": 0.92, "keys_k": 0.45,
		"cream": Color(0.62, 0.52, 0.38), "cream_glow": 0.08, "door_k": 0.35, "jamb_k": 0.4, "glow_k": 0.45, "glow_z": -0.6},
	3: {"rough": 0.8, "trim_rough": 1.05, "aniso": 0.55, "oil_can": 0.1, "stain": 1.8, "streak": 1.6,
		"run": 0.8, "dust": 0.75, "plate": 0.18, "base_k": 0.86, "keys_k": 0.25,
		"cream": Color(0.5, 0.42, 0.31), "cream_glow": 0.05, "door_k": 0.25, "jamb_k": 0.3, "glow_k": 0.35, "glow_z": -0.9},
}


func _ready() -> void:
	_rebuild()


func _queue_rebuild() -> void:
	if _rebuild_pending or not is_inside_tree():
		return
	_rebuild_pending = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_pending = false
	var old := get_node_or_null("Generated")
	if old:
		remove_child(old)
		old.queue_free()
	var g := Node3D.new()
	g.name = "Generated"
	add_child(g)
	var gaia_geometry := gaia_art and gaia_shell and shell_scene == null and ResourceLoader.exists(SHELL_GAIA_PATH)

	var steel := _steel_material()
	var dark := _mat(Color(0.12, 0.13, 0.14), 0.6, 0.8)
	var brass := _mat(Color(0.8, 0.62, 0.34), 0.3, 1.0)
	var cream := _mat(Color(0.93, 0.84, 0.66), 0.65, 0.0, warm_color, 0.35)
	# Gaia art pass: the doorway read near-white. Its emissive parts glow at about half, the cream
	# corridor is a deeper, warmer cream, and the interior light is at 0.7; DoorSpill is unchanged.
	var door_k := 0.5 if gaia_art else 1.0
	if gaia_art:
		cream = _mat(Color(0.8, 0.69, 0.52), 0.65, 0.0, warm_color, 0.15)
	# gaia_steel 2 and 3: through the open door the corridor read as a flat, evenly glowing cream box.
	# A darker, duller cream, dimmer frames and far door, and the interior light weaker and deeper in,
	# so that the corridor falls off towards the door instead of glowing evenly.
	var box_p: Dictionary = GAIA_STEEL.get(gaia_steel, {}) if gaia_art else {}
	var jamb_k := 0.56 if gaia_art else 1.0
	var glow_k := 0.7 if gaia_art else 1.0
	var glow_z := 0.3
	if not box_p.is_empty():
		door_k = box_p.door_k
		jamb_k = box_p.jamb_k
		glow_k = box_p.glow_k
		glow_z = box_p.glow_z
		cream = _mat(box_p.cream, 0.75, 0.0, warm_color, box_p.cream_glow)
	var sx := box_size.x
	var sy := box_size.y
	var sz := box_size.z
	var hx := sx * 0.5
	var hz := sz * 0.5

	# Shell: the Blender-authored GLB when available, otherwise procedural boxes.
	var shell_meshes := 0
	var brushed_surfaces := 0
	var rivet_count := 0
	var detailed_surfaces := 0
	var brushed_shader: ShaderMaterial
	var trim_shader: ShaderMaterial
	var door_shader: ShaderMaterial
	var gunmetal: StandardMaterial3D
	if steel_detail and ResourceLoader.exists(STEEL_SHADER_PATH) and ResourceLoader.exists(STEEL_GRIME_PATH):
		brushed_shader = ShaderMaterial.new()
		brushed_shader.shader = load(STEEL_SHADER_PATH)
		brushed_shader.set_shader_parameter("grime", load(STEEL_GRIME_PATH))
		# Box realism pass: the trims (bands, ribs, door frame and panels, vents, rivets) share the
		# brushing in a darker tone, without the plates' contact shadow; the door leaf moves, so it
		# gets neither the seam shadow nor the run-off below the bands (artpass/box/NOTES.md).
		trim_shader = brushed_shader.duplicate()
		trim_shader.set_shader_parameter("base_color", Color(0.58, 0.58, 0.59))
		trim_shader.set_shader_parameter("roughness_scale", 1.45)
		trim_shader.set_shader_parameter("plate_variation", 0.0)
		trim_shader.set_shader_parameter("seam_shadow", 0.0)
		trim_shader.set_shader_parameter("run_strength", 0.12)
		door_shader = brushed_shader.duplicate()
		door_shader.set_shader_parameter("seam_shadow", 0.0)
		door_shader.set_shader_parameter("run_strength", 0.0)
		door_shader.set_shader_parameter("dust_strength", 0.25)
		if gaia_art:
			# Gaia art pass: on the plates only (the trims and the door were duplicated above): a joint
			# 0.96 m either side of each wide face's centre line, which frames the door (its frame
			# reaches 0.87 m), rounded vertical edges over 3 cm, more plate-to-plate variation. The
			# door leaf: polished where hands take it, round the handle (1.3, 1.25 m in the leaf's frame,
			# artpass/gaia/inspect_shell.gd).
			brushed_shader.set_shader_parameter("joint_s", 0.96)
			# The gaia shell has real folded corners: the shading cue would round them twice.
			brushed_shader.set_shader_parameter("edge_roll", 0.0 if gaia_geometry else 0.03)
			brushed_shader.set_shader_parameter("plate_variation", 0.11)
			brushed_shader.set_shader_parameter("plate_hue", 0.025)
			door_shader.set_shader_parameter("plate_hue", 0.025)
			door_shader.set_shader_parameter("touch_center", Vector3(1.3, 1.25, 0.0))
			door_shader.set_shader_parameter("touch_radius", 0.3)
			door_shader.set_shader_parameter("touch_strength", 0.7)
			if GAIA_STEEL.has(gaia_steel):
				var p: Dictionary = GAIA_STEEL[gaia_steel]
				var base_k: float = p.base_k
				for m in [brushed_shader, trim_shader, door_shader]:
					m.set_shader_parameter("roughness_scale", p.trim_rough if m == trim_shader else p.rough)
					m.set_shader_parameter("anisotropy_amount", p.aniso)
					m.set_shader_parameter("stain_strength", p.stain)
					m.set_shader_parameter("streak_strength", p.streak)
					# Unset (null) on the plates and the door: the shader's default.
					var set_c: Variant = m.get_shader_parameter("base_color")
					var c: Color = set_c if set_c is Color else Color(0.76, 0.75, 0.73)
					m.set_shader_parameter("base_color", Color(c.r * base_k, c.g * base_k, c.b * base_k))
				for m in [brushed_shader, door_shader]:
					m.set_shader_parameter("oil_can", p.oil_can)
				brushed_shader.set_shader_parameter("run_strength", p.run)
				brushed_shader.set_shader_parameter("dust_strength", p.dust)
				brushed_shader.set_shader_parameter("plate_variation", p.plate)
		# Plinth: dark painted steel rather than a black mirror (box realism pass).
		gunmetal = _mat(Color(0.22, 0.22, 0.23), 0.55, 0.5)
		# The Compatibility renderer (the web build) has no SSR or GI, so a fully metallic shell shows
		# little but the probe; some diffuse keeps its lower half out of black (artpass/web/NOTES.md).
		if RenderingServer.get_current_rendering_method() == "gl_compatibility":
			# It also lights with the cool keys and a blue ambient only, without the warm bounce SDFGI
			# brings from the shelves, so a warmer albedo keeps the steel grey rather than blue.
			for m in [brushed_shader, trim_shader, door_shader]:
				m.set_shader_parameter("metallic", 0.8)
				m.set_shader_parameter("tint", Vector3(1.06, 1.0, 0.9))
			gunmetal.metallic = 0.4
	_hinge = null
	if use_blender_shell:
		var packed: PackedScene = shell_scene if shell_scene else load(SHELL_GAIA_PATH if gaia_geometry else SHELL_PATH) as PackedScene
		if packed:
			var shell := packed.instantiate() as Node3D
			shell.name = "BlenderShell"
			g.add_child(shell)
			_hinge = shell.find_child("DoorHinge", true, false) as Node3D
			var shell_parts := shell.find_children("*", "MeshInstance3D", true, false)
			shell_meshes = shell_parts.size()
			# Finish pass: render layer 2 sits outside HallProbe's reflection_mask, so the
			# steel reflects the dark environment and the cool keys instead of the warm hall.
			for mi in shell_parts:
				(mi as MeshInstance3D).layers = 2
				# Art pass 2: count the GLB materials that really carry the baked brushed-steel maps.
				var mesh := (mi as MeshInstance3D).mesh
				for si in mesh.get_surface_count():
					var sm := mesh.surface_get_material(si) as BaseMaterial3D
					if sm and sm.roughness_texture and sm.normal_enabled and sm.normal_texture:
						brushed_surfaces += 1
						if brushed_shader:
							if brushed_shader.get_shader_parameter("metal_rough") == null:
								for m in [brushed_shader, trim_shader, door_shader]:
									m.set_shader_parameter("metal_rough", sm.roughness_texture)
									m.set_shader_parameter("normal_map", sm.normal_texture)
							var target := brushed_shader
							if sm.resource_name == "SP_SteelTrim":
								target = trim_shader
							elif _hinge and _hinge.is_ancestor_of(mi):
								target = door_shader
							(mi as MeshInstance3D).set_surface_override_material(si, target)
							detailed_surfaces += 1
					elif sm and gunmetal and sm.resource_name == "SP_SteelDark":
						(mi as MeshInstance3D).set_surface_override_material(si, gunmetal)
						detailed_surfaces += 1
	var shell_kind := "blender_glb"
	if _hinge:
		_hinge.rotation.y = -deg_to_rad(door_open_degrees)
	else:
		shell_kind = "procedural"
		rivet_count = _build_procedural_shell(g, steel, dark, brass)

	# Warm glow on the door jambs, in front of either shell.
	var jamb_glow := _mat(warm_color, 0.5, 0.0, warm_color, 2.5 * jamb_k)
	_add(g, "JambGlowL", _box(Vector3(0.03, DOOR_H, WALL)), jamb_glow, _at(-DOOR_W * 0.5 + 0.015, DOOR_H * 0.5, hz - WALL * 0.5), false)
	_add(g, "JambGlowR", _box(Vector3(0.03, DOOR_H, WALL)), jamb_glow, _at(DOOR_W * 0.5 - 0.015, DOOR_H * 0.5, hz - WALL * 0.5), false)

	# Interior: a cream corridor of doorways that shrink towards a bright far door.
	var inner := Node3D.new()
	inner.name = "Interior"
	g.add_child(inner)
	var length := sz - 2.0 * WALL
	_add(inner, "Floor", _box(Vector3(2.4, 0.02, length)), cream, _at(0, 0.15, 0))
	_add(inner, "CorridorWallL", _box(Vector3(0.05, DOOR_H + 0.1, length)), cream, _at(-DOOR_W * 0.5 - 0.05, (DOOR_H + 0.1) * 0.5, 0))
	_add(inner, "CorridorWallR", _box(Vector3(0.05, DOOR_H + 0.1, length)), cream, _at(DOOR_W * 0.5 + 0.05, (DOOR_H + 0.1) * 0.5, 0))
	_add(inner, "CorridorCeiling", _box(Vector3(DOOR_W + 0.15, 0.05, length)), cream, _at(0, DOOR_H + 0.12, 0))
	var s := 1.0
	for k in corridor_doors:
		s = pow(0.9, k + 1)
		var z := hz - WALL - 0.25 - k * (length - 0.4) / corridor_doors
		var w := (DOOR_W - 0.1) * s
		var h := (DOOR_H - 0.15) * s
		var frame := _mat(warm_color, 0.5, 0.0, warm_color, (1.2 + k * 0.5) * door_k)
		var t := 0.06 * s + 0.02
		_add(inner, "Frame%d_L" % k, _box(Vector3(t, h, 0.05)), frame, _at(-w * 0.5, VANISH_Y, z), false)
		_add(inner, "Frame%d_R" % k, _box(Vector3(t, h, 0.05)), frame, _at(w * 0.5, VANISH_Y, z), false)
		_add(inner, "Frame%d_Top" % k, _box(Vector3(w + t, t, 0.05)), frame, _at(0, VANISH_Y + h * 0.5, z), false)
		if k % 2 == 1:
			_add(inner, "Leaf%d" % k, _box(Vector3(w * 0.5, h * 0.98, 0.03)), cream,
				Transform3D(Basis(Vector3.UP, deg_to_rad(70.0)), Vector3(w * 0.5, VANISH_Y, z)) * _at(-w * 0.25, 0, 0))
	_add(inner, "FarDoor", _box(Vector3((DOOR_W - 0.1) * s, (DOOR_H - 0.15) * s, 0.02)), _mat(warm_color, 0.5, 0.0, warm_color, 7.0 * door_k), _at(0, VANISH_Y, -hz + WALL + 0.05), false)

	# Lights: interior glow, the spill through the door, and the green receiver on the roof.
	var glow := OmniLight3D.new()
	glow.name = "InteriorGlow"
	glow.position = Vector3(0, 2.2, glow_z)
	glow.light_color = warm_color
	glow.light_energy = warm_energy * glow_k
	glow.omni_range = 5.0
	glow.shadow_enabled = true
	g.add_child(glow)
	var spill := SpotLight3D.new()
	spill.name = "DoorSpill"
	spill.position = Vector3(0, 2.6, hz - 0.4)
	var dir := Vector3(0, -0.45, 1.0).normalized()
	var bz := -dir
	var bx := Vector3.UP.cross(bz).normalized()
	spill.basis = Basis(bx, bz.cross(bx), bz)
	spill.light_color = warm_color
	spill.light_energy = warm_energy * spill_ratio
	spill.light_specular = spill_specular
	spill.spot_range = 14.0
	spill.spot_angle = 38.0
	spill.shadow_enabled = true
	spill.light_volumetric_fog_energy = 2.0
	g.add_child(spill)
	var receiver := CylinderMesh.new()
	receiver.top_radius = 1.15
	receiver.bottom_radius = 1.15
	receiver.height = 0.02
	# Gaia art pass: the green receiver and its glow at 0.6 and 0.67.
	_add(g, "BeamReceiver", receiver, _mat(Color(0.2, 0.9, 0.5), 0.5, 0.0, Color(0.3, 1.0, 0.55), 0.9 if gaia_art else 1.5), _at(0, sy + 0.23, 0), false)
	var roof_light := OmniLight3D.new()
	roof_light.name = "ReceiverGlow"
	roof_light.position = Vector3(0, sy + 0.8, 0)
	roof_light.light_color = Color(0.35, 1.0, 0.6)
	roof_light.light_energy = 1.0 if gaia_art else 1.5
	roof_light.omni_range = 4.5
	g.add_child(roof_light)
	var keys_k := 1.0
	if gaia_art and brushed_shader and GAIA_STEEL.has(gaia_steel):
		keys_k = (GAIA_STEEL[gaia_steel] as Dictionary).keys_k
	for side in [-1, 1]:
		var key := SpotLight3D.new()
		key.name = "KeyLight%s" % ("L" if side < 0 else "R")
		key.position = Vector3(side * 5.5, 7.5, 7.0)
		var kd := (Vector3(0, 2.2, 0.5) - key.position).normalized()
		var kz := -kd
		var kx := Vector3.UP.cross(kz).normalized()
		key.basis = Basis(kx, kz.cross(kx), kz)
		key.light_color = Color(0.82, 0.88, 1.0)
		key.light_energy = key_light_energy * keys_k
		key.spot_angle = 24.0
		key.spot_range = 18.0
		key.light_volumetric_fog_energy = 0.3
		g.add_child(key)

	# Detail pass: fully metallic steel needs something to reflect, and HallProbe's reflection_mask
	# leaves the shell out. SteelProbe captures the hall alone (layer 1) from the box's centre and
	# lights only the shell (layer 8); the interior and the glows move to layer 16 so the probe does
	# not capture the cream corridor from inside, and the floor (layer 2) stays out of it.
	var probe_count := 0
	if brushed_shader and _hinge:
		for mi in g.get_node("BlenderShell").find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).layers = 2 | 8
		for vi in g.find_children("*", "MeshInstance3D", true, false):
			if not g.get_node("BlenderShell").is_ancestor_of(vi):
				(vi as MeshInstance3D).layers = 16
		var probe := ReflectionProbe.new()
		probe.name = "SteelProbe"
		probe.position = Vector3(0, 10.5, 0)
		probe.size = Vector3(37.0, 25.0, 37.0)
		probe.origin_offset = Vector3(0, -8.3, 0)
		probe.box_projection = true
		probe.interior = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.intensity = 0.8
		probe.cull_mask = 1
		probe.reflection_mask = 8
		probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
		g.add_child(probe)
		probe_count = 1

	stats = {
		"shell": shell_kind,
		"shell_meshes": shell_meshes,
		"brushed_steel_surfaces": brushed_surfaces,
		"steel_detail_surfaces": detailed_surfaces,
		"steel_probe": probe_count,
		"procedural_rivets": rivet_count,
		"key_lights": 2,
		"corridor_doors": corridor_doors,
		"lights": 3,
		"door_open_degrees": door_open_degrees,
		"gaia_art": {"on": gaia_art, "joints_m": 0.96 if gaia_art and brushed_shader else 0.0,
			"edge_roll_m": (0.0 if gaia_geometry else 0.03) if gaia_art and brushed_shader else 0.0, "door_glow_k": door_k,
			"shell_glb": SHELL_GAIA_PATH if gaia_geometry else SHELL_PATH,
			"interior_glow": glow.light_energy, "receiver_glow": roof_light.light_energy,
			"steel_preset": gaia_steel if gaia_art and brushed_shader else 0, "key_energy": key_light_energy * keys_k},
	}


## The original v1 shell: four steel walls, chamfered corner posts, seams, rivets and a door.
func _build_procedural_shell(g: Node3D, steel: Material, dark: Material, brass: Material) -> int:
	var sx := box_size.x
	var sy := box_size.y
	var sz := box_size.z
	var hx := sx * 0.5
	var hz := sz * 0.5
	# Shell: four walls, the front one pierced by the doorway.
	_add(g, "WallBack", _box(Vector3(sx, sy, WALL)), steel, _at(0, sy * 0.5, -hz + WALL * 0.5))
	_add(g, "WallLeft", _box(Vector3(WALL, sy, sz)), steel, _at(-hx + WALL * 0.5, sy * 0.5, 0))
	_add(g, "WallRight", _box(Vector3(WALL, sy, sz)), steel, _at(hx - WALL * 0.5, sy * 0.5, 0))
	var seg := (sx - DOOR_W) * 0.5
	_add(g, "WallFrontLeft", _box(Vector3(seg, sy, WALL)), steel, _at(-(DOOR_W + seg) * 0.5, sy * 0.5, hz - WALL * 0.5))
	_add(g, "WallFrontRight", _box(Vector3(seg, sy, WALL)), steel, _at((DOOR_W + seg) * 0.5, sy * 0.5, hz - WALL * 0.5))
	_add(g, "Lintel", _box(Vector3(DOOR_W, sy - DOOR_H, WALL)), steel, _at(0, DOOR_H + (sy - DOOR_H) * 0.5, hz - WALL * 0.5))
	_add(g, "Roof", _box(Vector3(sx + 0.24, 0.22, sz + 0.24)), steel, _at(0, sy + 0.11, 0))
	_add(g, "Plinth", _box(Vector3(sx + 0.36, 0.14, sz + 0.36)), dark, _at(0, 0.07, 0))
	for cx in [-1, 1]:
		for cz in [-1, 1]:
			_add(g, "Corner_%d_%d" % [cx, cz], _box(Vector3(0.42, sy + 0.1, 0.42)), steel,
				Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(cx * hx, (sy + 0.1) * 0.5, cz * hz)))

	# Seams and rivets on every face.
	var faces := [
		[Vector3(0, 0, 1), Vector3(1, 0, 0), hx, hz, true],
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), hx, hz, false],
		[Vector3(1, 0, 0), Vector3(0, 0, -1), hz, hx, false],
		[Vector3(-1, 0, 0), Vector3(0, 0, 1), hz, hx, false],
	]
	var rivet_xf: Array[Transform3D] = []
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var hw: float = f[2]
		var depth: float = f[3]
		var spans := [[-hw + 0.15, -DOOR_W * 0.5 - 0.05], [DOOR_W * 0.5 + 0.05, hw - 0.15]] if f[4] else [[-hw + 0.15, hw - 0.15]]
		var origin := n * (depth + 0.01)
		for y in [1.45, 2.95]:
			for s in spans:
				var length: float = s[1] - s[0]
				var mid: float = (s[0] + s[1]) * 0.5
				_add(g, "Seam", _box(Vector3(length, 0.035, 0.02)), dark, Transform3D(Basis(u, Vector3.UP, n), origin + u * mid + Vector3(0, y, 0)), false)
				var k := s[0] as float
				while k <= s[1]:
					rivet_xf.append(_at_v(origin + n * 0.01 + u * k + Vector3(0, y + 0.07, 0)))
					rivet_xf.append(_at_v(origin + n * 0.01 + u * k + Vector3(0, y - 0.07, 0)))
					k += 0.28
		for edge in [-hw + 0.22, hw - 0.22]:
			var y := 0.3
			while y < sy - 0.15:
				rivet_xf.append(_at_v(origin + n * 0.01 + u * edge + Vector3(0, y, 0)))
				y += 0.3
	var rivet := SphereMesh.new()
	rivet.radius = 0.028
	rivet.height = 0.056
	rivet.radial_segments = 8
	rivet.rings = 4
	_multi(g, "Rivets", rivet, steel, rivet_xf)

	# Plaque, vents and a green status lamp.
	_add(g, "Plaque", _box(Vector3(0.5, 0.36, 0.03)), dark, _at((DOOR_W + seg) * 0.5, 1.9, hz + 0.015))
	for i in 5:
		_add(g, "Vent%d" % i, _box(Vector3(0.5, 0.03, 0.04)), dark, _at(-(DOOR_W + seg) * 0.5, 3.3 + i * 0.1, hz + 0.02))
	var lamp := SphereMesh.new()
	lamp.radius = 0.05
	lamp.height = 0.1
	_add(g, "StatusLamp", lamp, _mat(Color(0.2, 1.0, 0.5), 0.4, 0.0, Color(0.3, 1.0, 0.55), 6.0), _at(-hx - 0.02, 1.2, 1.2), false)

	var hinge := Node3D.new()
	hinge.name = "DoorHinge"
	hinge.position = Vector3(-DOOR_W * 0.5, 0.0, hz)
	hinge.rotation.y = -deg_to_rad(door_open_degrees)
	g.add_child(hinge)
	var leaf_w := DOOR_W - 0.04
	_add(hinge, "DoorLeaf", _box(Vector3(leaf_w, DOOR_H - 0.03, 0.09)), steel, _at(leaf_w * 0.5 + 0.02, (DOOR_H - 0.03) * 0.5 + 0.01, 0.045))
	_add(hinge, "PanelTop", _box(Vector3(leaf_w - 0.36, 0.9, 0.02)), dark, _at(leaf_w * 0.5 + 0.02, 2.05, 0.1))
	_add(hinge, "PanelBottom", _box(Vector3(leaf_w - 0.36, 0.9, 0.02)), dark, _at(leaf_w * 0.5 + 0.02, 0.8, 0.1))
	_add(hinge, "Handle", _box(Vector3(0.05, 0.28, 0.06)), brass, _at(leaf_w - 0.18, 1.3, 0.13))
	_hinge = hinge
	return rivet_xf.size()


func _steel_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.56, 0.58, 0.62)
	m.metallic = 0.92
	m.roughness = 0.42
	var noise := FastNoiseLite.new()
	noise.seed = 20260927
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.55, 0.55, 0.55))
	ramp.set_color(1, Color(1, 1, 1))
	var albedo := NoiseTexture2D.new()
	albedo.width = 512
	albedo.height = 512
	albedo.seamless = true
	albedo.noise = noise
	albedo.color_ramp = ramp
	m.albedo_texture = albedo
	var rough_noise := FastNoiseLite.new()
	rough_noise.seed = 7
	rough_noise.frequency = 0.08
	var rough := NoiseTexture2D.new()
	rough.width = 256
	rough.height = 256
	rough.seamless = true
	rough.noise = rough_noise
	m.roughness_texture = rough
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.6, 0.6, 0.6)
	return m


static func _mat(albedo: Color, rough := 0.8, metal := 0.0, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metal
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _add(parent: Node, node_name: String, mesh: Mesh, mat: Material, xf: Transform3D, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _multi(parent: Node, node_name: String, mesh: Mesh, mat: Material, xforms: Array) -> MultiMeshInstance3D:
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
	parent.add_child(mmi)
	return mmi


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func _at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


static func _at_v(p: Vector3) -> Transform3D:
	return Transform3D(Basis(), p)
