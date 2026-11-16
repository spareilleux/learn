extends Node
## Adaptive quality: the Observatory should run on a weak GPU as well as on the author's RTX
## ("Assure toi que ca marche quand meme avec un GPU pourri comme avec mon RTX, de maniere
## adaptative"). It times frames and, while they come slower than about 36 a second, steps down a
## ladder, cheapest losses first. The author likes the shadows, so they go late.
##
##   0  as built
##   1  no anti-aliasing: MSAA off, and on the web the page's 1.5x supersampling back to 1x
##   2  no glow; the gilt ornament (eggs, darts, beads, reels: about 670,000 triangles) hidden
##   3  3D drawn at 0.75 of the screen's resolution; the shelved books as boxes and the balusters
##      turned on 6 sides (observatory.gd low_poly: 1.7 million triangles fewer)
##   4  0.6; no shadows; lamps further than 16 m fade out (fewer lights per pixel)
##   5  0.5
##
## On the web the resolution is the canvas's: the page reports a smaller devicePixelRatio
## (artpass/aa/head_include.html reads window.__obsSS) and the browser scales the canvas up, which
## keeps ANGLE's fast path; Godot's own 3D scaling there was slower than none (artpass/perf/NOTES.md).
## Natively it is the viewport's 3D scale. ?quality=0..5 in the page's address (--quality=N on the
## command line) fixes a level; auto is the default. It steps back up only once, and only after a
## step taken at the first measurement or in the RETRY_WITHIN_S seconds after it: a first visit
## compiles its shaders then, and headless Chrome on the RTX, its cache empty, lost its anti-aliasing
## that way although its frames then took 16.7 ms (artpass/publish/recording-web-v27). The window
## runs from the first measurement, not from the scene's start: on that first visit the first frames
## came so slowly that the first measurement ended after 12 s (artpass/publish/frieze-web-v28). If
## frames then come at 50 a second or better twice, the level before that step comes back; otherwise
## a level that was too slow once would be again.
##
## A measurement is the median of 45 frame intervals, or of those that came in 2.5 s if fewer (at
## least 6): Chrome's CPU renderer (SwiftShader) took 1.5 s a frame, and 45 of them came a minute
## late. Under 5 frames a second, it goes straight to the last level. Its waits are timed by the
## clock, not by delta: under 7.5 frames a second Godot cuts a frame's delta to 8 physics steps,
## 0.133 s (main/main.cpp, max_physics_steps_per_frame), and a 3 s warm-up lasted 34 s there.

const LEVELS := 5
const SLOW_MS := 28.0        # median frame interval over which a level is too slow (about 36 a second)
const VERY_SLOW_MS := 70.0   # under about 14 a second: two levels at once
const CRAWL_MS := 200.0      # under 5 a second: straight to the last level
const FIRST_WARMUP_S := 3.0  # shader compiles as the hall first shows
const WARMUP_S := 2.0        # and after each change
const WINDOW := 45           # frames per measurement...
const WINDOW_S := 2.5        # ...or as many as came in that many seconds,
const MIN_FRAMES := 6        # but never fewer
const RECHECK_S := 8.0       # then a measurement every so often, for heavier views
const LIGHT_FADE_M := 16.0   # level 4: a lamp further than this fades out over 4 m
const RETRY_WITHIN_S := 12.0 # a step down this soon after the first measurement may come of shaders
                             # compiling, and is retried...
const FAST_MS := 20.0        # ...once, if two measurements then come under this
const NOTICES := {
	"en": "Quality lowered for smoothness (level %d of 5) · add ?quality=0 to the address for all of it",
	"fr": "Qualité réduite pour la fluidité (niveau %d sur 5) · ajoutez ?quality=0 à l'adresse pour tout",
	"es": "Calidad reducida para la fluidez (nivel %d de 5) · añada ?quality=0 a la dirección para todo",
}

var stats := {"level": 0, "auto": true, "median_ms": 0.0, "steps": 0}
var level := 0
var _obs: Node3D
var _auto := true
var _web := false
var _changed_us := 0         # when the level last changed (or the scene started)
var _last_us := 0
var _intervals := PackedFloat32Array()
var _window_ms := 0.0
var _next_check := FIRST_WARMUP_S
var _glow_was := {}          # Environment -> its glow, to put back
var _mesh_was := {}          # MultiMesh -> its full mesh, while level 3's stand-in is drawn
var _shadows: Array[Light3D] = []
var _faded: Array[Light3D] = []
var _notice: Label
var _notice_until_us := 0
var _start_us := 0           # the first measurement's end, once there is one
var _measured := false
var _early_from := -1        # the level before a step taken in the first RETRY_WITHIN_S seconds
var _fast := 0
var _retried := false
var _aa_was := {}            # anti-aliasing as level 1 found it, for that retry


func configure(obs: Node3D) -> void:
	_obs = obs


func _ready() -> void:
	_web = OS.has_feature("web")
	_changed_us = Time.get_ticks_usec()
	_start_us = _changed_us
	var forced := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--quality="):
			forced = arg.trim_prefix("--quality=")
	if _web:
		forced = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('quality') || ''", true))
	if forced.is_valid_int():
		_auto = false
		set_level(clampi(int(forced), 0, LEVELS))
	stats.auto = _auto
	_publish()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _notice != null and _notice.visible:
		var left := float(_notice_until_us - now) / 1e6
		_notice.modulate.a = clampf(left, 0.0, 1.0)
		if left <= 0.0:
			_notice.visible = false
	if not _auto or (level >= LEVELS and _early_from < 0):
		return
	var dt := float(now - _last_us) / 1000.0 if _last_us > 0 else 0.0
	_last_us = now
	var since := float(now - _changed_us) / 1e6
	if since < _next_check or dt <= 0.0:
		return
	if _web and bool(JavaScriptBridge.eval("document.hidden", true)):
		_intervals.clear()  # a hidden tab gets no frames: its intervals say nothing
		_window_ms = 0.0
		return
	_intervals.append(dt)
	_window_ms += dt
	if _intervals.size() < WINDOW and (_window_ms < WINDOW_S * 1000.0 or _intervals.size() < MIN_FRAMES):
		return
	var sorted := _intervals.duplicate()
	sorted.sort()
	var median := sorted[sorted.size() / 2]
	stats.frames = _intervals.size()
	_intervals.clear()
	_window_ms = 0.0
	stats.median_ms = snappedf(median, 0.1)
	if not _measured:
		_measured = true
		_start_us = now
	if median > SLOW_MS:
		_fast = 0
		if not _retried and float(now - _start_us) / 1e6 < RETRY_WITHIN_S:
			if _early_from < 0:
				_early_from = level
		else:
			_early_from = -1  # slow after the first seconds too: the steps were right
		if level >= LEVELS:
			_early_from = -1
			_publish()
			return
		var step := LEVELS if median > CRAWL_MS else (2 if median > VERY_SLOW_MS else 1)
		set_level(mini(level + step, LEVELS))
		_show_notice()
		_next_check = WARMUP_S
	elif _early_from >= 0 and median < FAST_MS:
		_fast += 1
		_next_check = since + RECHECK_S
		if _fast >= 2:
			# The early step came of a first visit's compiles, not of the GPU: once, back up.
			var back := _early_from
			_early_from = -1
			_retried = true
			stats.retried = true
			set_level(back)
			_next_check = WARMUP_S
			if _notice != null:
				_notice.visible = false
	else:
		_next_check = since + RECHECK_S
	_publish()


## Applies a level from scratch: everything a lower level turned off comes back first.
func set_level(n: int) -> void:
	level = clampi(n, 0, LEVELS)
	stats.level = level
	stats.steps += 1
	_changed_us = Time.get_ticks_usec()
	_last_us = 0
	_intervals.clear()
	_window_ms = 0.0
	_apply_aa(level >= 1)
	_apply_effects(level >= 2)
	_apply_geometry(level >= 3)
	_apply_scale(1.0 if level < 3 else (0.75 if level == 3 else (0.6 if level == 4 else 0.5)))
	_apply_shadows(level >= 4)
	_apply_lights(level >= 4)
	_publish()


func _apply_aa(off: bool) -> void:
	var vp := get_viewport()
	if not off:
		# The page's own choice (or the project's) stays as it was, unless a retried step had taken it.
		if _aa_was.is_empty():
			return
		vp.msaa_3d = _aa_was.msaa
		vp.screen_space_aa = _aa_was.ssaa
		if _web:
			JavaScriptBridge.eval("window.__obsMSAA = %d; window.__obsSS = %s; window.dispatchEvent(new Event('resize'));"
					% [int(_aa_was.web_msaa), str(_aa_was.web_ss)], true)
		_aa_was.clear()
		return
	if _aa_was.is_empty():
		_aa_was = {"msaa": vp.msaa_3d, "ssaa": vp.screen_space_aa, "web_msaa": 0, "web_ss": 1.0}
		if _web:
			_aa_was.web_msaa = int(str(JavaScriptBridge.eval("window.__obsMSAA || 0", true)))
			_aa_was.web_ss = float(str(JavaScriptBridge.eval("window.__obsSS || 1", true)))
	if _web:
		JavaScriptBridge.eval("window.__obsMSAA = 0; if (window.__obsSS > 1) { window.__obsSS = 1; window.dispatchEvent(new Event('resize')); }", true)
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED


func _apply_effects(off: bool) -> void:
	for env in _environments():
		if off:
			if not _glow_was.has(env):
				_glow_was[env] = env.glow_enabled
			env.glow_enabled = false
		elif _glow_was.has(env):
			env.glow_enabled = bool(_glow_was[env])
	if _obs == null:
		return
	for node in _obs.find_children("Gilt*", "MultiMeshInstance3D", true, false):
		var n := String(node.name)
		if n.ends_with("Eggs") or n.ends_with("Darts") or n.ends_with("Beads") or n.ends_with("Reels"):
			(node as Node3D).visible = not off


## The shelved books and the balusters drawn with observatory.gd's cheaper stand-ins; the instances
## (where each book stands, its colour and style) stay as they are.
func _apply_geometry(low: bool) -> void:
	if _obs == null or not _obs.has_method("low_poly"):
		return
	var kinds := {"Books_B*": "book", "Balusters_B*": "baluster"}
	for pattern: String in kinds:
		var stand_in: Mesh = null
		for node in _obs.find_children(pattern, "MultiMeshInstance3D", true, false):
			var mm := (node as MultiMeshInstance3D).multimesh
			if mm == null:
				continue
			if low and not _mesh_was.has(mm):
				if stand_in == null:
					stand_in = _obs.call("low_poly", kinds[pattern])
				if stand_in == null:
					break
				_mesh_was[mm] = mm.mesh
				mm.mesh = stand_in
			elif not low and _mesh_was.has(mm):
				mm.mesh = _mesh_was[mm]
	if not low:
		_mesh_was.clear()
	stats.low_poly = not _mesh_was.is_empty()


func _apply_scale(s: float) -> void:
	stats.scale = s
	if _web:
		# The canvas: devicePixelRatio times __obsSS (head_include.html); observatory.gd's _web_ss
		# scales the HUD back by the same factor once a second.
		# At full resolution the page's own factor (1.5 on computers) stands, unless a lower level
		# had taken it under 1.
		var cur := float(str(JavaScriptBridge.eval("window.__obsSS || 1", true)))
		var want := cur if s >= 1.0 and cur >= 1.0 else s
		if not is_equal_approx(cur, want):
			JavaScriptBridge.eval("window.__obsSS = %s; window.dispatchEvent(new Event('resize'));" % str(want), true)
		return
	var vp := get_viewport()
	vp.scaling_3d_scale = s
	if s < 1.0 and vp.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR


func _apply_shadows(off: bool) -> void:
	if off:
		for light in get_tree().root.find_children("*", "Light3D", true, false):
			var l := light as Light3D
			if l.shadow_enabled:
				l.shadow_enabled = false
				_shadows.append(l)
	else:
		for l in _shadows:
			if is_instance_valid(l):
				l.shadow_enabled = true
		_shadows.clear()


## Lamps and spots far from the camera faded out. The renderers drop a light past its fade
## (drivers/gles3/rasterizer_scene_gles3.cpp, "Out of range, don't draw this light"), so each pixel
## loops over fewer of the hall's 51 lamps. Lights that fade already keep their own settings.
func _apply_lights(fade: bool) -> void:
	if fade:
		for light in get_tree().root.find_children("*", "Light3D", true, false):
			var l := light as Light3D
			if l is DirectionalLight3D or l.distance_fade_enabled:
				continue
			l.distance_fade_enabled = true
			l.distance_fade_begin = LIGHT_FADE_M
			l.distance_fade_length = 4.0
			_faded.append(l)
	else:
		for l in _faded:
			if is_instance_valid(l):
				l.distance_fade_enabled = false
		_faded.clear()
	stats.faded_lights = _faded.size()


func _environments() -> Array[Environment]:
	var out: Array[Environment] = []
	var w := get_viewport().find_world_3d()
	if w != null and w.environment != null:
		out.append(w.environment)
	for we in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		var e := (we as WorldEnvironment).environment
		if e != null and not out.has(e):
			out.append(e)
	for cam in get_tree().root.find_children("*", "Camera3D", true, false):
		var e := (cam as Camera3D).environment
		if e != null and not out.has(e):
			out.append(e)
	return out


func _publish() -> void:
	if _web:
		JavaScriptBridge.eval("window.__obsQuality = %d; window.__obsQualityMedian = %s;" % [level, str(stats.median_ms)], true)


func _show_notice() -> void:
	if _notice == null:
		var layer := CanvasLayer.new()
		layer.layer = 60
		add_child(layer)
		_notice = Label.new()
		_notice.add_theme_font_size_override("font_size", 15)
		_notice.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
		_notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		_notice.add_theme_constant_override("outline_size", 5)
		_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_notice.offset_bottom = -96
		_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_notice)
	var lang := OS.get_locale_language()
	_notice.text = str(NOTICES.get(lang, NOTICES.en)) % level
	_notice.visible = true
	_notice_until_us = Time.get_ticks_usec() + 6_000_000
