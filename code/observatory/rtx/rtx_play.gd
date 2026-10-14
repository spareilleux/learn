class_name ObservatoryRtx
extends "res://rtx/dlss_play.gd"
## The Observatory's native package for readers elsewhere (artpass/publish/rtx/NOTES.md): dlss_play.gd as
## the author runs it, and over it:
##   - what the path tracer needs of the scene beyond its F9 (pt_scene.gd: the night sky as a sky shader,
##     the gardens' trees as meshes at every distance), applied when the path tracer comes on and undone
##     when it goes off; and the scene's own quality ladder (scripts/quality.gd) held at its level 0
##     meanwhile: it answers slow frames by drawing the books as boxes and fading the lamps out, which
##     path traced darkens the hall. Slow frames are answered here by DLSS's setting instead;
##   - "On devrait être en photorealistic si la carte le permet" (the author, 2026-10-13): where DLSS
##     runs, it starts path traced, with Ray Reconstruction. -- --rtx-raster starts rasterized;
##   - "on vise 60 images par seconde", "Sur une 5080", "Vérifie si on a de l'anti alias au max que la
##     carte permet" (the same day): the DLSS setting is this script's to choose until the reader chooses
##     one (F7 or its button). Path traced it starts at DLSS Quality; every five seconds, under slow_fps
##     rendered frames a second it goes one setting down (Balanced, Performance; never Ultra Performance,
##     for which the fork finds no DLSS mode: F7 and the button step over it too), and
##     where the GPU's time says the next one up would still hold 60, one up (to DLAA at most), never
##     back to a setting that was too slow. Under off_fps at the last setting, the path tracer goes
##     off, with a line that says so, unless the reader switched it on. Rasterized, it starts at DLAA,
##     the most anti-aliasing DLSS has, and steps down the same way;
##   - "La bibliothèque paraît sombre" (the same day, of the path traced hall): the scene's three soft
##     fill lights (observatory.gd soft_fill_lights, made for the path tracer and never switched on in
##     this copy) are built, shown only while the path tracer runs, at fill times their energy: the
##     rasterized hall has its ambient light everywhere, the path tracer only where rays reach the sky.
##     At 20 the start view's mean luma is 0.158 and 26 % of it nearly black, against 0.091 and 61 % at
##     1, and 0.176 and 10 % rasterized (logs/sweep1 to sweep3); twice the exposure reached 0.151 by
##     blooming the lamps and left the books dark;
##   - "Rajoute des sources de lumière au besoin" (the same day): lamps on the wing's gallery while the
##     path tracer runs (_find_gallery), which the rasterizer lights through its floor; and the hall's
##     reading lamps at shelf times their energy (_set_shelf_lamps): the fill lights hang above the
##     first gallery, and below it only the reading lamps reach the shelves in the rays. With the fork
##     tracing 256 lights instead of 64 (raise_rt_lights.py), at 3 the start view's mean luma is 0.186
##     and 17 % of it nearly black, against 0.158 and 27 % before, for 14.97 ms of GPU against 14.6
##     (logs/ab-lights64, ab-lights256, shelf-b5); at 5 the middle shelves begin to burn;
##   - "Va y au meilleur rapport qualité/fps" (the same day): the rays stop at 2 bounces, not the fork's
##     3. On the RTX 5080 at 3840 x 2054, DLSS Quality takes 14.6 ms of GPU a frame at 2 and 18.3 ms at
##     3 (55 frames a second), for a mean luma that moves by under 1 %: at 2 it holds 60 where 3 needed
##     Balanced, which is the softer picture (logs/sweep3: sharp 0.0241 against 0.0232);
##   - "Les Buttons toggle devraient être évident sur version Desktop avec rtx" (the same day), then "des
##     boutons qui affichent de manière séparée, comme une colonne verticale, tous les features […] qu'on
##     puisse comprendre tous les toggles" (2026-10-14): a column of buttons on the left, one a feature,
##     each with its state, its key and a line that says what it does;
##   - "un genre de bouton qui fait un max out […] tous les effets au top" (2026-10-14): Max out (F6) puts
##     every setting at its best for the picture, path traced DLAA with 3 bounces and frame generation,
##     not held at 60 frames a second; again, back to the steered start;
##   - "si c'est tout le temps à on, tu peux supprimer l'option" (2026-10-14, of the gold metal): the gilt
##     stays metal and F6 is Max out's;
##   - "des effets de moirée bizarres […] des clignotements" (2026-10-14): without DLSS, MSAA 4x + TAA in
##     place of MSAA 2x: MSAA alone crawls ten times more while the eye turns (NOTES.md, Flicker);
##   - "un voile" (2026-10-14): rasterized, the volumetric fog lights the hall and veils it in blue; a
##     warmer, thinner fog (veil.py: black level 0.027 to 0.023, no blue cast). The path tracer has none;
##   - "faire bouger des trucs dans la scène" (2026-10-14): rtx_life.gd's moving things, one row each.
## The fork compiles each custom material's hit group in the background and leaves its surfaces out of
## the rays until it is ready (ptviews.gd waits 30 s before its first view): a third line says so for
## that half minute. Without DLSS, that line says what is missing.
##
## A release template takes no --script (main.cpp clears it without OVERRIDE_PATH_ENABLED), so the package's
## project names this class as its main loop (application/run/main_loop_type) and an empty scene,
## rtx/stage.tscn, as its main scene: dlss_play.gd instantiates main.tscn itself. The program then needs no
## argument at all. -- --rtx-probe=<dir> hands the run to rtx_probe.gd, which writes down what it shows.

const PT_SCENE := "res://rtx/pt_scene.gd"
const PROBE := "res://rtx/rtx_probe.gd"
const BRIDGE := "res://rtx/rtx_bridge.gd"
const LIFE := "res://rtx/rtx_life.gd"
const WARM_MS := 30000      # the path tracer's first half minute: hit groups compile, nothing is judged
const SETTLE_MS := 4000     # after any other change
const START_SETTING := 1    # DLSS Quality: what the path tracer starts at
const LAST_SETTING := 3     # Performance: the last step down
const ULTRA := 4            # Ultra Performance, never chosen: the fork finds no DLSS mode for it ("Couldn't
                            # find an appropriate DLSS mode"), path traced or not, and DLSS stops while the
                            # badge still names it. At 3840 x 2054, every 3D scale under 0.5 failed, from
                            # 0.3336 to 0.42, and 0.5 ran (logs/ultra-scale-b5): Performance is the least
const SLOW_UPDATES := 10    # half-second updates in a row before a step (5 s)
const STEP_UP_MS := 14.0    # GPU time a frame the next setting up must be expected to stay under (60 a second: 16.7)
const NOTE_MS := 12000
# Anti-aliasing without DLSS: [its name, MSAA, SMAA after it, TAA, FSR 2 at the window's resolution].
# While the eye turns a quarter pixel a frame, the start view's mean worst second difference of luma is
# 0.00020 with MSAA 4x + TAA, 0.00039 with 8x + TAA, 0.0058 to 0.0080 with MSAA alone at 8x to 2x; SMAA
# adds nothing; FSR 2 at 1.0 is broken in this fork (NOTES.md, Flicker). PLAIN_CYCLE is what the button
# steps through; the others stay for the probe (--rtx-plain-aa=).
const PLAIN := {
	"msaa4taa": ["MSAA 4x + TAA", Viewport.MSAA_4X, false, true, false],
	"msaa8taa": ["MSAA 8x + TAA", Viewport.MSAA_8X, false, true, false],
	"msaa2": ["MSAA 2x", Viewport.MSAA_2X, false, false, false],
	"msaa4": ["MSAA 4x", Viewport.MSAA_4X, false, false, false],
	"msaa8": ["MSAA 8x", Viewport.MSAA_8X, false, false, false],
	"msaa8smaa": ["MSAA 8x + SMAA", Viewport.MSAA_8X, true, false, false],
	"msaa4smaa": ["MSAA 4x + SMAA", Viewport.MSAA_4X, true, false, false],
	"taa": ["TAA", Viewport.MSAA_DISABLED, false, true, false],
	"fsr2": ["FSR 2 anti-aliasing", Viewport.MSAA_DISABLED, false, false, true],
}
const PLAIN_CYCLE := ["msaa4taa", "msaa8taa", "taa", "msaa8", "msaa4", "msaa2"]
const MAX_BOUNCES := 3      # Max out's: 4 moved the start view's mean luma by under 1 % for 3.6 ms more (NOTES.md)
const RASTER_FOG_ALBEDO := Color(0.82, 0.78, 0.72)  # the scene's (0.6, 0.7, 0.9) veiled the hall in blue
const RASTER_FOG_DENSITY := 0.007                   # the scene's 0.012 raised its black level to 0.027
const ON := Color(0.45, 1.0, 0.55)
const OFF := Color(0.86, 0.88, 0.92)
const MAX_ON := Color(1.0, 0.82, 0.4)
const NOTE := Color(0.68, 0.71, 0.76)
# The column: [key, what it says it does]. The buttons' own text, with its state, is _refresh's.
const ROWS := [
	["max", "Every setting at its best for the picture: path traced DLAA, 3 bounces, frame generation, everything that moves. Not held at 60 frames a second."],
	["pt", "Light computed by rays: soft shadows, true reflections, light bouncing from surface to surface. Denoised by DLSS Ray Reconstruction, always on with it."],
	["dlss", "Renders fewer pixels and rebuilds the picture with AI. DLAA: every pixel; Quality, Balanced, Performance: 67, 58, 50 % of each side. Auto: steered to 60 frames a second."],
	["fg", "An AI frame between each two rendered: twice the frames on the screen, a little more latency. Shows on a screen faster than 60 Hz."],
	["bounces", "How many times a ray bounces: each one more lights the shade a little more and costs 2 to 4 ms."],
	["plain", "Without DLSS. MSAA smooths the shapes' edges only; TAA also steadies glints and thin lines (ten times less flicker), a little softer."],
	["glyphs", "Glyphs falling down the green rain, drawn by a shader: no font, no image."],
	["cloth", "The departments' banners as cloth that the air moves, and their letters with it."],
	["dust", "A little dust that drifts in the lamps' light."],
	["hide", "This column, the line at the top and the badge: all, the badge alone, nothing."],
]

var slow_fps := 56.0        # rendered frames a second under which the setting steps down (--rtx-slow-fps=)
var off_fps := 20.0         # and under which, at the last setting, the path tracer goes off
var fill := 20.0            # the soft fill lights' energy, times observatory.gd's own (--rtx-fill=)
var exposure := 1.0         # the path traced picture's exposure, times the scene's own (--rtx-exposure=)
var bounces := 2            # the path tracer's bounces (--rtx-bounces=); the fork's own are 3
var gallery := 4.0          # the wing's gallery lamps' energy while path tracing (--rtx-gallery=)
var shelf := 3.0            # the hall's reading lamps' energy while path tracing, times their own (--rtx-shelf=)
var plain_aa := "msaa4taa"  # the anti-aliasing without DLSS, one of PLAIN's keys (--rtx-plain-aa=)
var _exposure_was := 1.0
var _bounces_was := 3
var _dress: RefCounted      # pt_scene.gd's object while path tracing, null otherwise
var _judge_from := 0        # frames are judged from then on (Time.get_ticks_msec)
var _warm_until := 0        # the path tracer's materials are coming in until then
var _probe: RefCounted
var _bridge: RefCounted
var _started := false
var _auto := true           # the DLSS setting is this script's to choose
var _pt_chosen := false     # the reader switched the path tracer: it stays as chosen
var _mine := [-1, false]    # the setting and the path tracer as this script last knew them
var _slow := 0
var _fast := 0
var _ceiling := -1          # the best setting that proved too slow: no step up to it or past it
var _note := ""
var _note_until := 0
var _quality: Node          # scripts/quality.gd in the scene
var _quality_auto := true
var _fill: Node3D           # the scene's SoftFill group
var _gallery: Node3D        # this script's lamps on the wing's gallery
var _shelf_lamps: Array[Node] = []  # observatory.gd's ShelfLamp lights, one before each shelf unit
var _life: RefCounted       # rtx_life.gd: what moves
var _max := false           # Max out is on
var _max_was := {}          # what it changed, as it was
var _max_sig := []          # the settings as Max out left them: any change turns it off
var _bar: PanelContainer    # the column
var _show: Button           # brings the column back when F10 has hidden everything
var _buttons := {}
var _notes: Array[Label] = []
var _px := 0                # the letters' size the column was last laid out for
var _f6_held := false       # F6 and F5 held at the last frame
var _f5_held := false


func _initialize() -> void:
	super()
	# Before the scene is ready (the root enters the tree after this function): built once, with the hall.
	_scene.set("soft_fill_lights", true)
	_build_bar()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rtx-slow-fps="):
			slow_fps = float(arg.trim_prefix("--rtx-slow-fps="))
			off_fps = slow_fps
		elif arg.begins_with("--rtx-fill="):
			fill = float(arg.trim_prefix("--rtx-fill="))
		elif arg.begins_with("--rtx-exposure="):
			exposure = float(arg.trim_prefix("--rtx-exposure="))
		elif arg.begins_with("--rtx-bounces="):
			bounces = int(arg.trim_prefix("--rtx-bounces="))
		elif arg.begins_with("--rtx-gallery="):
			gallery = float(arg.trim_prefix("--rtx-gallery="))
		elif arg.begins_with("--rtx-shelf="):
			shelf = float(arg.trim_prefix("--rtx-shelf="))
		elif arg.begins_with("--rtx-plain-aa=") and PLAIN.has(arg.trim_prefix("--rtx-plain-aa=")):
			plain_aa = arg.trim_prefix("--rtx-plain-aa=")
		elif arg.begins_with("--rtx-probe="):
			_probe = (load(PROBE) as Script).new()
			_probe.call("start", self, arg.trim_prefix("--rtx-probe="))
		elif arg == "--rtx-bridge" or arg.begins_with("--rtx-bridge="):
			# The scene agent's bridge (rtx_bridge.gd): 127.0.0.1 only, and only when asked for.
			var shots := ProjectSettings.globalize_path("user://bridge-shots")
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--rtx-shots="):
					shots = a.trim_prefix("--rtx-shots=")
			_bridge = (load(BRIDGE) as Script).new()
			_bridge.call("start", self, int(arg.trim_prefix("--rtx-bridge=")) if "=" in arg else 8798, shots)
	_plain()  # dlss_play.gd applied its setting before the arguments were read
	process_frame.connect(_sync)


## The scene's Environment is there: path traced from the start where DLSS runs.
func _find_env() -> void:
	super()
	if _started or _env == null:
		return
	_started = true
	# The project asks for a maximised window (window/size/mode=2), and in 3 runs of 7 on 2026-10-14 the
	# window stayed at 1600 x 900 (logs/plain-*): asked again once the scene is there.
	if root.mode == Window.MODE_WINDOWED:
		root.mode = Window.MODE_MAXIMIZED
	_quality = _scene.find_child("Quality", true, false)
	_gold_flat = _gold_metal  # the gilt stays metal: dlss_play.gd's F6 finds nothing to swap
	_env.volumetric_fog_albedo = RASTER_FOG_ALBEDO
	_env.volumetric_fog_density = RASTER_FOG_DENSITY
	if ResourceLoader.exists(LIFE):
		_life = (load(LIFE) as Script).new()
		_life.call("start", self, _scene)
	_find_fill()
	if _dlss:
		if OS.get_cmdline_user_args().has("--rtx-raster"):
			_i = 0
		else:
			_pt = true
		_apply()
	_mine = [_i, _pt]
	_refresh()


## The soft fill lights, at their energy times fill, lit while the path tracer runs. The scene rebuilds
## itself when one of its settings changes, and the group with it: looked for again when it is gone.
func _find_fill() -> void:
	_find_gallery()
	_set_shelf_lamps()
	if not is_instance_valid(_fill):
		_fill = _scene.find_child("SoftFill", true, false) as Node3D
		if _fill == null:
			return
		for l in _fill.get_children():
			var light := l as Light3D
			if light != null and not light.has_meta("rtx_energy"):
				light.set_meta("rtx_energy", light.light_energy)
				light.light_energy *= fill
	_fill.visible = _pt


## The hall's reading lamps (observatory.gd's ShelfLamp, energy 0.7 and range 5.5 before each shelf unit) at
## shelf times their energy while the path tracer runs, and at their own otherwise: rasterized, the
## ambient light lights the shelves with them; in the rays, only they do below the first gallery.
func _set_shelf_lamps() -> void:
	if _shelf_lamps.is_empty() or not is_instance_valid(_shelf_lamps[0]):
		_shelf_lamps = _scene.find_children("ShelfLamp*", "OmniLight3D", true, false)
		for l in _shelf_lamps:
			if not l.has_meta("rtx_energy"):
				l.set_meta("rtx_energy", (l as Light3D).light_energy)
		if not _shelf_lamps.is_empty():
			print("RTXPLAY reading lamps: %d, at %.1f times their energy while path tracing" % [_shelf_lamps.size(), shelf])
	for l in _shelf_lamps:
		var e := float(l.get_meta("rtx_energy")) * (shelf if _pt else 1.0)
		if not is_equal_approx((l as Light3D).light_energy, e):
			(l as Light3D).light_energy = e


## The wing's gallery (scripts/library_wing.gd), lit while the path tracer runs: a warm lamp under the
## side ceiling in each bay, either side, in the wing's own frame and on its layers as its other lamps.
## Rasterized, the alcoves' lamps under the gallery's floor light it from below, having no shadows; in the
## rays they have, and the gallery had no light of its own.
func _find_gallery() -> void:
	if not is_instance_valid(_gallery):
		var wing: Node = null
		for n in _scene.find_children("*", "Node3D", true, false):
			var s := n.get_script() as Script
			if s != null and s.resource_path.ends_with("library_wing.gd"):
				wing = n
				break
		var inside: Node3D = wing.get("_interior") as Node3D if wing != null else null
		if inside == null:
			return
		var c: Dictionary = (wing.get_script() as Script).get_script_constant_map()
		_gallery = Node3D.new()
		_gallery.name = "RtxGallery"
		inside.add_child(_gallery)
		for j in int(c.BAYS):
			var zc := float(wing.call("_line_z", j)) + float(c.PITCH) * 0.5
			for side: float in [-1.0, 1.0]:
				var l := OmniLight3D.new()
				l.position = Vector3(side * 5.25, float(c.SIDE_CEILING) - 0.6, zc)
				l.light_color = c.get("WARM", Color(1.0, 0.82, 0.58))
				l.light_energy = gallery
				l.omni_range = 4.5
				l.omni_attenuation = 1.0
				l.light_specular = 0.35
				l.light_cull_mask = int(c.LAYER) | int(c.MIRROR_LAYER)
				l.shadow_enabled = false
				l.distance_fade_enabled = true
				l.distance_fade_begin = 30.0
				l.distance_fade_length = 8.0
				_gallery.add_child(l)
	_gallery.visible = _pt


func _apply() -> void:
	if _i == ULTRA:  # F7 or the button stepping past Performance: on to what follows it
		_i = 0 if _pt else ULTRA + 1
	var now := Time.get_ticks_msec()
	if _env != null and _pt != (_dress != null):
		if _pt:
			_hold_quality(true)
			_dress = (load(PT_SCENE) as Script).new()
			print("RTXPLAY path-traced scene: ", JSON.stringify(_dress.call("apply", _scene, _env, _sky)))
			_exposure_was = _env.tonemap_exposure
			_env.tonemap_exposure = _exposure_was * exposure
			_bounces_was = int(_env.get("pathtracing_max_bounces"))
			_env.set("pathtracing_max_bounces", bounces)
			_warm_until = now + WARM_MS
		else:
			_env.tonemap_exposure = _exposure_was
			_env.set("pathtracing_max_bounces", _bounces_was)
			_dress.call("restore")
			_dress = null
			_hold_quality(false)
			_warm_until = 0
			print("RTXPLAY path-traced scene: restored")
		if _auto and _dlss:
			# Its own start for each: what the path tracer costs says nothing of the rasterizer.
			_i = START_SETTING if _pt else 0
			_mine[0] = _i
		_ceiling = -1
	_judge_from = maxi(_warm_until, now + SETTLE_MS)
	_slow = 0
	_fast = 0
	if _started:
		_find_fill()
	super()
	_plain()
	_refresh()


## Without DLSS (no NVIDIA files, or F7 past Performance): plain_aa in place of dlss_play.gd's MSAA 2x.
## With DLSS, SMAA is off again (dlss_play.gd leaves screen_space_aa alone).
func _plain() -> void:
	if bool(SETTINGS[_i][1]):
		_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		return
	var p: Array = PLAIN[plain_aa]
	_vp.msaa_3d = p[1]
	_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA if p[2] else Viewport.SCREEN_SPACE_AA_DISABLED
	_vp.use_taa = p[3]
	if p[4]:  # FSR 2 at the window's own resolution: its temporal anti-aliasing alone, as DLAA is DLSS's
		_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		_vp.scaling_3d_scale = 1.0


func _setting_name(i: int) -> String:
	return str(SETTINGS[i][0]) if bool(SETTINGS[i][1]) else "%s, no DLSS" % PLAIN[plain_aa][0]


## The scene's quality ladder at its level 0 and no longer stepping, or as it was. Before dlss_play.gd's
## own _apply: level 0 puts the project's anti-aliasing and 3D scale back, which DLSS then sets its way.
func _hold_quality(hold: bool) -> void:
	if _quality == null:
		return
	if hold:
		_quality_auto = bool(_quality.get("_auto"))
		_quality.set("_auto", false)
		_quality.call("set_level", 0)
	else:
		_quality.set("_auto", _quality_auto)


func _say(text: String) -> void:
	_note = text
	_note_until = Time.get_ticks_msec() + NOTE_MS
	print("RTXPLAY ", text)


func _update_badge(s: Array) -> void:
	super(s)
	var now := Time.get_ticks_msec()
	if _started:
		if _i != _mine[0]:
			_auto = false  # F7 or its button: the reader's setting stays
		if _pt != _mine[1]:
			_pt_chosen = true
		_mine = [_i, _pt]
	_find_fill()
	if not bool(SETTINGS[_i][1]):
		_label.text = _label.text.replace(str(SETTINGS[_i][0]), _setting_name(_i))
	_label.text = _label.text.replace("F6: gold metal", "F6: max out").replace("F6: gold flat", "F6: max out")
	if _started and _dlss and bool(SETTINGS[_i][1]) and now > _judge_from:
		_steer(_frames / maxf(_t, 0.001), _gpu / maxi(_frames, 1))
	if not _dlss:
		_label.text += "\nDLSS and path tracing need NVIDIA's files and a GeForce RTX card: close this window, start Setup-DLSS.cmd"
	elif now < _note_until:
		_label.text += "\n" + _note
	elif _pt and now < _warm_until:
		_label.text += "\nPath tracing: materials come in over the first half minute"
	_refresh()


## One half second's frames, judged: after five seconds too slow, a setting down or the path tracer off;
## after five seconds with room for it, a setting up.
func _steer(fps: float, gpu_ms: float) -> void:
	_slow = _slow + 1 if fps < slow_fps else 0
	var up := false
	if _auto and fps >= slow_fps and _i > 0 and _i - 1 > _ceiling:
		var more := pow(float(SETTINGS[_i - 1][2]) / float(SETTINGS[_i][2]), 2.0)  # as many times the pixels
		up = gpu_ms * more < STEP_UP_MS
	_fast = _fast + 1 if up else 0
	var last := LAST_SETTING
	if _slow >= SLOW_UPDATES:
		if _auto and _i < last:
			_ceiling = _i
			_i += 1
			_say("Under %d frames a second: %s now (F7 chooses)" % [roundi(slow_fps), SETTINGS[_i][0]])
		elif _pt and not _pt_chosen and fps < off_fps and (_i >= last or not _auto):
			_pt = false
			_say("Path tracing is too slow on this card: switched off (F9 switches it back on)")
		else:
			_slow = 0
			return
		_apply()
		_mine = [_i, _pt]
	elif _fast >= SLOW_UPDATES:
		_i -= 1
		_say("Room to spare at 60 frames a second: %s now (F7 chooses)" % SETTINGS[_i][0])
		_apply()
		_mine = [_i, _pt]


# The column.

func _build_bar() -> void:
	var px := 16
	var layer := CanvasLayer.new()
	layer.layer = 101
	root.add_child(layer)
	_bar = PanelContainer.new()
	_bar.add_theme_stylebox_override("panel", _box(Color(0.02, 0.025, 0.035, 0.84), px / 2))
	_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_bar.grow_horizontal = Control.GROW_DIRECTION_END
	_bar.grow_vertical = Control.GROW_DIRECTION_BOTH
	_bar.offset_left = px
	layer.add_child(_bar)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", px / 4)
	_bar.add_child(column)
	var press := {"max": _press_max, "pt": _press_pt, "dlss": _press_dlss, "fg": _press_fg, "bounces": _press_bounces,
		"plain": _press_plain, "glyphs": _press_life.bind("glyphs"), "cloth": _press_life.bind("cloth"),
		"dust": _press_life.bind("dust"), "hide": _press_hud}
	for spec: Array in ROWS:
		var b := _button(px)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(press[spec[0]])
		column.add_child(b)
		_buttons[spec[0]] = b
		var note := Label.new()
		note.text = spec[1]
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_color_override("font_color", NOTE)
		column.add_child(note)
		_notes.append(note)
	_show = _button(px)
	_show.text = "RTX  ·  F10"
	_show.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_show.grow_horizontal = Control.GROW_DIRECTION_END
	_show.grow_vertical = Control.GROW_DIRECTION_BOTH
	_show.offset_left = px
	_show.modulate.a = 0.55
	_show.visible = false
	_show.pressed.connect(_press_hud)
	layer.add_child(_show)
	_refresh()


func _box(colour: Color, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(8)
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin / 2.0
	box.content_margin_bottom = margin / 2.0
	return box


## A button that takes clicks and never the keyboard: Space and Enter stay the scene's.
func _button(px: int) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", px)
	b.add_theme_stylebox_override("normal", _box(Color(0.10, 0.12, 0.16, 0.95), px / 2))
	b.add_theme_stylebox_override("hover", _box(Color(0.18, 0.21, 0.27, 0.95), px / 2))
	b.add_theme_stylebox_override("pressed", _box(Color(0.26, 0.30, 0.38, 0.95), px / 2))
	b.add_theme_stylebox_override("disabled", _box(Color(0.07, 0.08, 0.10, 0.80), px / 2))
	return b


func _paint(key: String, text: String, on: bool, enabled := true, colour := ON) -> void:
	var b: Button = _buttons[key]
	b.text = text
	b.disabled = not enabled
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, colour if on else OFF)


func _refresh() -> void:
	if _buttons.is_empty():
		return
	var s: Array = SETTINGS[_i]
	var can_pt := _dlss and _env != null
	if _max and _max_sig != _signature():
		_max = false  # a setting changed since: no longer everything at its best
	_paint("max", "Max out  %s  ·  F6" % ("ON" if _max else "off"), _max, true, MAX_ON)
	_paint("pt", "Path tracing  %s  ·  F9" % ("ON" if _pt else "off"), _pt, can_pt)
	_paint("dlss", "%s%s  ·  F7" % [_setting_name(_i) if _dlss else "DLSS unavailable", "  (auto)" if _auto and _dlss else ""], bool(s[1]) and _dlss, _dlss)
	_paint("fg", "Frame generation  %s  ·  F8" % ("ON" if _fg and bool(s[1]) else "off"), _fg and bool(s[1]), _dlss)
	_paint("bounces", "Light bounces  %d  ·  F5" % bounces, _pt, _pt)
	_paint("plain", "Without DLSS: %s" % PLAIN[plain_aa][0], not bool(s[1]), not bool(s[1]))
	for key: String in ["glyphs", "cloth", "dust"]:
		var there := _life != null and bool(_life.call("has", key))
		var on := there and bool(_life.call("is_on", key))
		var title: String = {"glyphs": "Glyph rain", "cloth": "Banners in the draught", "dust": "Dust in the light"}[key]
		_paint(key, "%s  %s" % [title, "ON" if on else "off"], on, there)
	_paint("hide", "Hide  ·  F10", false)


## What Max out sets, as it stands now.
func _signature() -> Array:
	return [_i, _pt, _fg, bounces, plain_aa]


## Every frame: the column follows F10 (dlss_play.gd's _hud: 0 the line and the badge, 1 the badge,
## 2 nothing), F6 and F5, and the window's height: the window is maximised after this script starts, and
## letters sized for 900 lines are small on 2160.
func _sync() -> void:
	_bar.visible = _hud == 0
	_show.visible = _hud > 0
	var f6 := Input.is_key_pressed(KEY_F6)
	if f6 and not _f6_held:
		_press_max()
	_f6_held = f6
	var f5 := Input.is_key_pressed(KEY_F5)
	if f5 and not _f5_held:
		_press_bounces()
	_f5_held = f5
	if _life != null:
		_life.call("step", root.get_process_delta_time())
	var px := clampi(int(root.size.y / 72.0), 14, 28)
	if px == _px:
		return
	_px = px
	for b: Button in _buttons.values() + [_show]:
		b.add_theme_font_size_override("font_size", px)
	for note in _notes:
		note.add_theme_font_size_override("font_size", maxi(12, px * 7 / 10))
		note.custom_minimum_size.x = px * 19
	_bar.offset_left = px
	_show.offset_left = px
	_label.add_theme_font_size_override("font_size", maxi(18, px * 3 / 4))
	_badge.add_theme_font_size_override("font_size", maxi(15, px * 2 / 3))


func _press_max() -> void:
	if _max:
		_max = false
		bounces = int(_max_was.get("bounces", bounces))
		plain_aa = str(_max_was.get("plain_aa", plain_aa))
		_fg = bool(_max_was.get("fg", false))
		if _life != null:
			for key: String in ["glyphs", "cloth", "dust"]:
				if _max_was.has(key):
					_life.call("set_on", key, bool(_max_was[key]))
		# Back to the start: the path tracer where DLSS runs, its setting steered to 60 frames a second.
		_auto = true
		_pt_chosen = false
		_pt = _dlss and _env != null
		_i = START_SETTING if _pt else (0 if _dlss else _i)
		_say("Max out off: back to the steered start")
	else:
		_max_was = {"bounces": bounces, "plain_aa": plain_aa, "fg": _fg}
		if _life != null:
			for key: String in ["glyphs", "cloth", "dust"]:
				if bool(_life.call("has", key)):
					_max_was[key] = bool(_life.call("is_on", key))
					_life.call("set_on", key, true)
		_max = true
		_auto = false
		plain_aa = "msaa8taa"
		if _dlss and _env != null:
			_pt = true
			_pt_chosen = true
			_i = 0
			_fg = true
			bounces = MAX_BOUNCES
		_say("Max out: every setting at its best for the picture, not held at 60 frames a second (F6 again: back)")
	if _pt and _env != null:
		_env.set("pathtracing_max_bounces", bounces)
	_max_sig = _signature()  # before _apply too, whose _refresh compares with it
	_apply()
	_mine = [_i, _pt]
	_max_sig = _signature()
	_refresh()


func _press_pt() -> void:
	if not (_dlss and _env != null):
		return
	_pt = not _pt
	if _pt and not SETTINGS[_i][1]:
		_i = 0
	_apply()


func _press_dlss() -> void:
	if not _dlss:
		return
	_i = (_i + 1) % SETTINGS.size()
	if _pt and not SETTINGS[_i][1]:
		_i = 0  # Ray Reconstruction runs only with DLSS
	_apply()


func _press_fg() -> void:
	if not _dlss:
		return
	_fg = not _fg
	_apply()


## The path tracer's bounces, 1 to 4: taken at once while it runs, kept for when it comes on otherwise.
func _press_bounces() -> void:
	if not _pt:
		return
	bounces = bounces % 4 + 1
	if _env != null:
		_env.set("pathtracing_max_bounces", bounces)
	_judge_from = Time.get_ticks_msec() + WARM_MS  # a new variant of the hit shaders compiles meanwhile
	_say("Light bounces: %d (the first seconds are cheaper and wrong while the rays' shaders compile)" % bounces)
	_refresh()


func _press_plain() -> void:
	if bool(SETTINGS[_i][1]):
		return
	plain_aa = PLAIN_CYCLE[(PLAIN_CYCLE.find(plain_aa) + 1) % PLAIN_CYCLE.size()]
	_plain()
	_refresh()


func _press_life(key: String) -> void:
	if _life == null or not bool(_life.call("has", key)):
		return
	_life.call("set_on", key, not bool(_life.call("is_on", key)))
	_refresh()


func _press_hud() -> void:
	_hud = (_hud + 1) % 3
	_label.visible = _hud == 0
	_badge_box.visible = _hud < 2
