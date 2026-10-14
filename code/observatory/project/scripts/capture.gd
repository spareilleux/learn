extends Node
## Non-interactive command-line hooks (arguments after "--"):
##   godot --headless --path . -- --selftest
##       prints the generated scene's statistics as one JSON line, exits 0 or 1
##   godot --headless --path . -- --flytest
##       drives FlyCamera with synthetic input events (keys, mouse), exits 0 or 1
##   godot --path . --resolution 1600x900 -- --capture=renders/artpass [--profiles=v1,artpass,low]
##       for each quality profile: renders the camera presets to PNG and measures
##       frame time and memory with vsync off, then writes bench.json and quits

const PRESETS := ["overview", "door", "gallery", "dome", "hero_a", "hero_b", "hero_c"]
## "v1": the art pass switched off (procedural shell and orbits, no probe, v1 beam
##       energies), for comparison at the same camera framing.
## "artpass": the default scene.
## "low": the explicit fallback for weaker GPUs: no volumetric fog, SSR or SSAO,
##       shelf lamps off, no MSAA, 3D rendered at 75 % and upscaled with FSR 1.
const PROFILE_PRESETS := {"v1": ["overview", "door"], "artpass": PRESETS, "low": ["overview", "door"], "comparison": ["overview", "door"], "ultra": ["overview", "door"]}

## Frames rendered before each capture, so volumetric fog, SSR and the probe settle.
@export var settle_frames := 90
## Frames measured for the benchmark, after settling.
@export var bench_frames := 240


func _ready() -> void:
	var profiles := ["artpass"]
	var capture_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profiles="):
			profiles = Array(arg.trim_prefix("--profiles=").split(","))
	for arg in OS.get_cmdline_user_args():
		if arg == "--selftest":
			_selftest.call_deferred()
		elif arg == "--flytest":
			_flytest.call_deferred()
		elif arg.begins_with("--capture="):
			capture_dir = arg.trim_prefix("--capture=")
	if capture_dir != "":
		_capture.call_deferred(capture_dir, profiles)


func _selftest() -> void:
	await get_tree().process_frame
	var obs: Dictionary = get_parent().get("stats")
	var cube: Dictionary = get_parent().get_node("SteelCube").get("stats")
	var missing := []
	for key in ["piers", "arches", "gallery_levels", "shelf_units", "books", "ceiling_rings", "beams", "drops", "ornament_panels", "reflection_probe"]:
		if int(obs.get(key, 0)) <= 0:
			missing.append(key)
	if int(cube.get("corridor_doors", 0)) <= 0 or float(cube.get("door_open_degrees", 0.0)) <= 0.0:
		missing.append("steel_cube")
	if cube.get("shell", "") != "blender_glb" or int(cube.get("shell_meshes", 0)) <= 0:
		missing.append("blender_shell")
	var report := {
		"godot": Engine.get_version_info().string,
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"observatory": obs,
		"steel_cube": cube,
		"nodes": _count(get_parent()),
		"missing": missing,
	}
	print("SELFTEST ", JSON.stringify(report))
	get_tree().quit(0 if missing.is_empty() else 1)


func _flytest() -> void:
	var cam = get_parent().get_node("FlyCamera")
	await get_tree().process_frame
	var results := {}
	var start: Vector3 = cam.position
	var fwd: Vector3 = -cam.basis.z
	_key(KEY_W, true)
	await get_tree().create_timer(0.5).timeout
	_key(KEY_W, false)
	var moved: Vector3 = cam.position - start
	results["w_moves_forward"] = moved.length() > 0.5 and moved.normalized().dot(fwd) > 0.9
	_key(KEY_F, true)
	await get_tree().process_frame
	_key(KEY_F, false)
	var hint: Label = get_parent().get_node("ControlsHud/Panel/Hint")
	results["f_shows_fly_mode"] = cam.get("_free_fly") and hint.text.contains("FLY MODE")
	var y0: float = cam.position.y
	_key(KEY_E, true)
	await get_tree().create_timer(0.3).timeout
	_key(KEY_E, false)
	results["e_moves_up"] = cam.position.y > y0 + 0.2
	_key(KEY_F, true)
	await get_tree().process_frame
	_key(KEY_F, false)
	results["f_returns_to_walk_mode"] = not cam.get("_free_fly") and hint.text.contains("WALK MODE")
	var logical_f := InputEventKey.new()
	logical_f.keycode = KEY_F
	logical_f.pressed = true
	Input.parse_input_event(logical_f)
	await get_tree().process_frame
	results["f_logical_key_toggles"] = cam.get("_free_fly")
	_key(KEY_F, true)
	await get_tree().process_frame
	_key(KEY_F, false)
	var alternate_start: Vector3 = cam.position
	_key(KEY_Z, true)
	await get_tree().create_timer(0.3).timeout
	_key(KEY_Z, false)
	results["z_moves_forward"] = cam.position.distance_to(alternate_start) > 0.2
	var yaw0: float = cam.rotation.y
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	Input.parse_input_event(press)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(-200, 0)
	Input.parse_input_event(motion)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	Input.parse_input_event(release)
	await get_tree().process_frame
	results["right_drag_turns"] = absf(cam.rotation.y - yaw0) > 0.3
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await get_tree().process_frame
	results["click_captures_look"] = cam.get("_looking") and (DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await get_tree().process_frame
	results["escape_releases_look"] = Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	results["controls_hud_exists"] = get_parent().get_node_or_null("ControlsHud/Panel/Hint") != null
	_key(KEY_2, true)
	await get_tree().process_frame
	_key(KEY_2, false)
	results["key_2_door_preset"] = cam.position.distance_to(Vector3(2.6, 1.8, 8.5)) < 0.01
	var ok := not results.values().has(false)
	print("FLYTEST ", JSON.stringify(results))
	get_tree().quit(0 if ok else 1)


func _key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)


func _capture(dir: String, profiles: Array) -> void:
	var out := ProjectSettings.globalize_path("res://").path_join(dir) if dir.is_relative_path() else dir
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var vp := get_viewport()
	RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	print("ADAPTER %s | %s | %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(), RenderingServer.get_current_rendering_method()])
	var cam = get_parent().get_node("FlyCamera")
	cam.set_process(false)
	get_parent().get_node("ControlsHud").visible = false
	var bench := []
	for profile in profiles:
		_apply_profile(profile)
		for i in 5:
			await get_tree().process_frame  # deferred rebuilds, probe re-capture
		for preset in PROFILE_PRESETS.get(profile, PRESETS):
			cam.go_to_preset(preset)
			for i in settle_frames:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			var path := out.path_join("%s-%s.png" % [profile, preset])
			var err := img.save_png(path)
			print("CAPTURE %s %dx%d err=%d" % [path, img.get_width(), img.get_height(), err])
			var row: Dictionary = await _measure(vp)
			row["profile"] = profile
			row["preset"] = preset
			bench.append(row)
			print("BENCH ", JSON.stringify(row))
	var f := FileAccess.open(out.path_join("bench.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(bench, " "))
	f.close()
	get_tree().quit()


func _measure(vp: Viewport) -> Dictionary:
	var rid := vp.get_viewport_rid()
	var cpu := 0.0
	var gpu := 0.0
	var t := Time.get_ticks_usec()
	for i in bench_frames:
		await get_tree().process_frame
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
	var wall_ms := (Time.get_ticks_usec() - t) / 1000.0 / bench_frames
	return {
		"frame_ms": snappedf(wall_ms, 0.01),
		"gpu_ms": snappedf(gpu / bench_frames, 0.01),
		"render_cpu_ms": snappedf(cpu / bench_frames, 0.01),
		"video_mem_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"texture_mem_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"static_mem_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
	}


func _apply_profile(profile: String) -> void:
	var obs := get_parent()
	var cube := obs.get_node("SteelCube")
	var env: Environment = obs.get_node("WorldEnvironment").environment
	var vp := get_viewport()
	var art := profile != "v1"
	obs.set("use_reflection_probe", art)
	obs.set("pier_ornament", load("res://assets/pier_ornament.png") if art else null)
	obs.set("beam_energy", 0.6 if art else 1.6)
	obs.set("drop_energy", 3.5 if art else 9.0)
	obs.set("near_beam_fade", 6.0 if art else 0.0)
	obs.set("rain_inset", 2.4 if art else 1.4)
	obs.set("beams_per_bay", 1 if art else 3)
	cube.set("warm_energy", 4.5 if art else 6.0)
	cube.set("spill_ratio", 1.2 if art else 2.2)
	cube.set("spill_specular", 0.2 if art else 1.0)
	cube.set("use_blender_shell", art)
	cube.set("key_light_energy", 5.0 if art else 0.0)
	var low := profile == "low"
	env.volumetric_fog_enabled = not low
	env.ssr_enabled = not low
	env.ssao_enabled = not low
	env.ssil_enabled = not low
	env.sdfgi_enabled = profile == "ultra"
	vp.msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if low else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = 0.75 if low else 1.0
	_set_shelf_lamps.call_deferred(not low)
	print("PROFILE ", profile)


func _set_shelf_lamps(on: bool) -> void:
	for lamp in get_parent().find_children("ShelfLamp", "OmniLight3D", true, false):
		lamp.visible = on


func _count(n: Node) -> int:
	var total := 1
	for c in n.get_children():
		total += _count(c)
	return total
