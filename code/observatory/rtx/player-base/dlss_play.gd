extends SceneTree
## The Observatory to walk in with DLSS, natively, on NVIDIA's Godot fork (artpass/dlss/NOTES.md):
## the scene as it starts, in DLAA. F7 steps through the settings: DLAA, DLSS Quality, Balanced,
## Performance, Ultra Performance, then the project's own MSAA 2x without DLSS. F8 switches frame
## generation (DLSS-G) on and off. F9 switches to the fork's path tracer, denoised by DLSS Ray
## Reconstruction (which also upscales: F7 then steps through the DLSS settings only); the night
## sky's dome, a sphere its vertex shader pushes to infinity, would stand in the hall as a ball for
## the rays, so it is hidden meanwhile. A line at the top says the setting, the frames a second the
## engine renders (frame generation shows twice as many on the screen) and the GPU's time. A badge
## at the bottom right says whether DLSS really runs: green while the fork counts successful DLSS
## evaluations (Streamline.get_status, patched in by dlss_status.py), with the sizes it scales
## between; amber if DLSS is chosen but nothing is evaluated; grey when it is off. F10 shows the line
## and the badge, the badge alone, or nothing. The gilt starts as metal (assets/gilt.gdshader, the
## egg-and-dart and beads catch the light); F6 swaps it for the flat emissive gold the hall has by
## default and back, to compare. Path traced, the metal's own reflection of the hall is turned off:
## the rays reflect the real one.
##   godot --path <copy of the project> --rendering-method forward_plus --rendering-driver vulkan \
##     --maximized --script res://artpass/dlss/dlss_play.gd

const DLSS_MODE := 6  # Viewport.SCALING_3D_MODE_DLSS in the fork
const SETTINGS := [
	["DLAA", true, 1.0],
	["DLSS Quality", true, 0.667],
	["DLSS Balanced", true, 0.58],
	["DLSS Performance", true, 0.5],
	["DLSS Ultra Performance", true, 0.333],
	["MSAA 2x, no DLSS", false, 1.0],
]

var _i := 0
var _fg := false
var _f7 := false  # the keys held at the last frame: a press switches once
var _f8 := false
var _f9 := false
var _f10 := false
var _f6 := false
var _gold_metal: Material  # the two gilt materials F6 swaps (observatory.gd's _m.gold, _m.gold_flat)
var _gold_flat: Material
var _metal := true
var _hud := 0  # 0: the line and the badge, 1: the badge alone, 2: nothing
var _badge: Label
var _badge_box: PanelContainer
var _evals := -1  # DLSS evaluations at the last badge update (-1: none yet)
var _evals_rr := 0  # and DLSS-RR's
var _pt := false
var _env: Environment
var _sky: Node3D
var _scene: Node
var _env_tries := 0
# The dressed stone's materials: path traced, their relief comes from its slope map, since the
# rays have no screen-space derivatives (artpass/stone/relief_slope.py); rasterized, as before.
var _stones: Array[ShaderMaterial] = []
const STONE_SHADER := "res://assets/stone_relief.gdshader"
const STONE_SLOPE := "res://assets/stone_relief_slope.png"
var _label: Label
var _vp: Viewport
var _dlss := false
var _t := 0.0
var _frames := 0
var _gpu := 0.0


func _initialize() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	scene.set("gilt_metal", true)
	root.add_child(scene)
	_vp = root  # the window is the viewport (its get_viewport() is null until the tree runs)
	RenderingServer.viewport_set_measure_render_time(_vp.get_viewport_rid(), true)
	var sl: Object = Engine.get_singleton("Streamline") if Engine.has_singleton("Streamline") else null
	_dlss = sl != null and bool(sl.call("get_capability", 0))
	_scene = scene
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 6)
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.offset_top = 8
	layer.add_child(_label)
	_badge_box = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.025, 0.035, 0.72)
	box.set_corner_radius_all(6)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	_badge_box.add_theme_stylebox_override("panel", box)
	_badge_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_badge_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_badge_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_badge_box.offset_right = -12
	_badge_box.offset_bottom = -12
	layer.add_child(_badge_box)
	_badge = Label.new()
	_badge.add_theme_font_size_override("font_size", 15)
	_badge_box.add_child(_badge)
	if not _dlss:
		_i = SETTINGS.size() - 1  # no DLSS here: the project's own setting only
	_apply()
	process_frame.connect(_on_frame)


func _apply() -> void:
	var s: Array = SETTINGS[_i]
	_vp.use_taa = false
	if s[1]:
		_vp.msaa_3d = Viewport.MSAA_DISABLED
		_vp.scaling_3d_mode = DLSS_MODE
	else:
		_vp.msaa_3d = Viewport.MSAA_2X
		_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_vp.scaling_3d_scale = s[2]
	if "frame_generation" in _vp:
		_vp.set("frame_generation", _fg and bool(s[1]))
	if _env != null:
		_env.set("pathtracing_enabled", _pt)
		_env.set("pathtracing_denoiser", 1)  # DLSS Ray Reconstruction
		if _sky != null:
			_sky.visible = not _pt
		for sm in _stones:
			sm.set_shader_parameter("use_slope", 1.0 if _pt else 0.0)
	if _gold_metal is ShaderMaterial:
		(_gold_metal as ShaderMaterial).set_shader_parameter("output_energy", 0.0 if _pt else 0.7)


## The scene's Environment, once the scene has built it (not yet when _initialize runs), if this
## Godot has the path tracer. Looked for over the first frames.
func _find_env() -> void:
	if _env != null or _env_tries > 600:
		return
	_env_tries += 1
	var cam := _scene.get_node_or_null("FlyCamera") as Camera3D
	var env: Environment = cam.environment if cam != null and cam.environment != null else root.find_world_3d().environment
	if env == null:
		return
	_env_tries = 1000
	if not "pathtracing_enabled" in env:
		print("DLSSPLAY path tracing: unavailable in this Godot")
		return
	_env = env
	_sky = _scene.find_child("NightSky", true, false) as Node3D
	if ResourceLoader.exists(STONE_SLOPE):
		var slope: Texture2D = load(STONE_SLOPE)
		for n in _scene.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			var mats: Array = [mi.material_override]
			for i in mi.get_surface_override_material_count():
				mats.append(mi.get_surface_override_material(i))
			for m in mats:
				var sm := m as ShaderMaterial
				if sm != null and sm.shader != null and sm.shader.resource_path == STONE_SHADER and not _stones.has(sm):
					sm.set_shader_parameter("relief_slope", slope)
					_stones.append(sm)
	var m: Dictionary = _scene.get("_m")
	_gold_metal = m.get("gold")
	_gold_flat = m.get("gold_flat")
	_apply()
	print("DLSSPLAY path tracing: available (F9), %d stone materials" % _stones.size())


func _on_frame() -> void:
	_find_env()
	var f7 := Input.is_key_pressed(KEY_F7)
	if f7 and not _f7 and _dlss:
		_i = (_i + 1) % SETTINGS.size()
		if _pt and not SETTINGS[_i][1]:
			_i = 0  # Ray Reconstruction runs only with DLSS
		_apply()
	_f7 = f7
	var f9 := Input.is_key_pressed(KEY_F9)
	if f9 and not _f9 and _dlss and _env != null:
		_pt = not _pt
		if _pt and not SETTINGS[_i][1]:
			_i = 0
		_apply()
	_f9 = f9
	var f8 := Input.is_key_pressed(KEY_F8)
	if f8 and not _f8 and _dlss:
		_fg = not _fg
		_apply()
	_f8 = f8
	var f10 := Input.is_key_pressed(KEY_F10)
	if f10 and not _f10:
		_hud = (_hud + 1) % 3
		_label.visible = _hud == 0
		_badge_box.visible = _hud < 2
	_f10 = f10
	var f6 := Input.is_key_pressed(KEY_F6)
	if f6 and not _f6 and _gold_metal != null and _gold_flat != null and _gold_metal != _gold_flat:
		_metal = not _metal
		_swap_gold(_gold_flat if _metal else _gold_metal, _gold_metal if _metal else _gold_flat)
	_f6 = f6
	_frames += 1
	_gpu += RenderingServer.viewport_get_measured_render_time_gpu(_vp.get_viewport_rid())
	_t += root.get_process_delta_time()
	if _t >= 0.5:
		var s: Array = SETTINGS[_i]
		var fg := "  ·  frame generation on" if _fg and bool(s[1]) else ""
		var pt := "Path tracing + Ray Reconstruction  ·  " if _pt else ""
		var keys := "F7: next setting  ·  F8: frame generation" if _dlss else "DLSS unavailable (Streamline not loaded)"
		if _dlss and _env != null:
			keys += "  ·  F9: path tracing"
		keys += "  ·  F6: gold %s  ·  F10: indicator" % ("metal" if _metal else "flat")
		_label.text = "%s%s%s  ·  %d fps rendered  ·  GPU %.2f ms\n%s" % [pt, s[0], fg, roundi(_frames / _t), _gpu / _frames, keys]
		_update_badge(s)
		_t = 0.0
		_frames = 0
		_gpu = 0.0


## The badge: what the fork says it evaluated since the last update, not what was asked for.
func _update_badge(s: Array) -> void:
	var sl: Object = Engine.get_singleton("Streamline") if Engine.has_singleton("Streamline") else null
	var green := Color(0.45, 1.0, 0.55)
	var amber := Color(1.0, 0.75, 0.3)
	var grey := Color(0.65, 0.68, 0.72)
	var text := ""
	var colour := grey
	if not _dlss:
		text = "○ DLSS unavailable"
	elif not s[1]:
		text = "○ DLSS off  ·  %s" % s[0]
	elif not sl.has_method("get_status"):
		# An older build of the fork: only what was asked for is known.
		text = "● DLSS requested  ·  %s  (this build cannot confirm it runs)" % s[0]
		colour = amber
	else:
		var st: Dictionary = sl.call("get_status")
		var sr := int(st.get("dlss_evaluations", 0))
		var rr := int(st.get("dlss_rr_evaluations", 0))
		var first := _evals < 0
		var sr_rate := (sr - _evals) / maxf(_t, 0.001)
		var rr_rate := (rr - _evals_rr) / maxf(_t, 0.001)
		_evals = sr
		_evals_rr = rr
		if first:
			text = "● DLSS: checking…"
			colour = amber
		elif sr_rate + rr_rate > 0.0:
			var rin: Vector2i = st.get("render_size", Vector2i.ZERO)
			var rout: Vector2i = st.get("output_size", Vector2i.ZERO)
			var kind := "DLSS Ray Reconstruction" if rr_rate > sr_rate else ("DLAA" if rin == rout else "DLSS Super Resolution")
			text = "● %s running  ·  %d×%d → %d×%d  ·  %d evaluations/s" % [kind, rin.x, rin.y, rout.x, rout.y, roundi(sr_rate + rr_rate)]
			if bool(st.get("frame_generation", false)):
				text += "  ·  + frame generation"
			colour = green
		else:
			text = "● DLSS selected, not evaluating  ·  %s" % s[0]
			colour = amber
	_badge.text = text
	_badge.add_theme_color_override("font_color", colour)


## Every gilt mesh and MultiMesh wearing one gold, made to wear the other.
func _swap_gold(from: Material, to: Material) -> void:
	for n in _scene.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if gi.material_override == from:
			gi.material_override = to
