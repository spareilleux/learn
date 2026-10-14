@tool
extends Node3D
## Procedural circular observatory: floor inlays, engraved colonnade and arches,
## gallery tiers with stylised bookshelves, ceiling rings with an orrery, and
## green "data rain". Change the exported values in the Inspector and the scene
## rebuilds live in the editor. Everything generated lives under the "Generated"
## child, which has no owner and is therefore never saved into main.tscn.

const SEED := 20260927
## Art pass 2: ComfyUI marble (SDXL output made tileable), see artpass/blender/comfyui/.
const MARBLE_PATH := "res://assets/stone_marble.png"
## Book pass: hardback mesh, spine shader and ComfyUI grain (R leather, G cloth), see artpass/books/.
const BOOK_SHADER_PATH := "res://assets/book_spines.gdshader"
const BOOK_GRAIN_PATH := "res://assets/book_grain.png"
## Bindings in sRGB (the shader linearises): tanned, dyed and aged calf; publishers' cloth; vellum.
const LEATHER := [Color(0.42, 0.13, 0.09), Color(0.3, 0.18, 0.1), Color(0.52, 0.34, 0.19), Color(0.36, 0.09, 0.13),
	Color(0.13, 0.24, 0.15), Color(0.1, 0.09, 0.08), Color(0.24, 0.14, 0.08)]
const CLOTH := [Color(0.13, 0.17, 0.31), Color(0.3, 0.35, 0.42), Color(0.36, 0.34, 0.19), Color(0.42, 0.15, 0.14),
	Color(0.12, 0.3, 0.32), Color(0.58, 0.44, 0.2), Color(0.36, 0.35, 0.33), Color(0.2, 0.32, 0.22)]
const VELLUM := [Color(0.68, 0.6, 0.45), Color(0.6, 0.53, 0.4)]
## Detail pass: dressed stone (procedural joints and ComfyUI tooled limestone), a normal map for the
## engraved panels, and turned bronze balusters under a walnut handrail.
const STONE_SHADER_PATH := "res://assets/stone_relief.gdshader"
const STONE_RELIEF_PATH := "res://assets/stone_relief.png"
const ORNAMENT_NORMAL_PATH := "res://assets/pier_ornament_normal.png"
## Stained glass on the oculus drum: three ComfyUI panels (alchemical and elven, not religious),
## and for each an accent colour for the light it throws into the fog. The accents are an art
## choice: the panels' measured mean colour is a warm near-white (artpass/books/logs).
const GLASS_SHADER_PATH := "res://assets/stained_glass.gdshader"
const NIGHT_SKY_SHADER_PATH := "res://assets/night_sky.gdshader"
## ESO's GigaGalaxy panorama (ESO/S. Brunier, CC BY 4.0), 4096 x 2048, from GA's Prime Radiant
## textures (artpass/sky/NOTES.md). Without it the sky draws its Galaxy in noise.
const MILKY_WAY_PATH := "res://assets/sky_milky_way_eso.jpg"
## The core seen from near the centre, drawn by Z-Image-Turbo (artpass/sky2/).
const CORE_CAP_PATH := "res://assets/sky_core_cap.png"
const PAVING_SHADER_PATH := "res://assets/floor_paving.gdshader"
const STATUE_SCRIPT_PATH := "res://scripts/seldon_statue.gd"
const DANEEL_SCRIPT_PATH := "res://scripts/daneel_statue.gd"
const TOUCH_SCRIPT_PATH := "res://scripts/touch_controls.gd"
const WALK_SCRIPT_PATH := "res://scripts/walk_physics.gd"
const FOLLOW_SCRIPT_PATH := "res://scripts/camera_follow.gd"
const FIT_SCRIPT_PATH := "res://scripts/view_fit.gd"
const MOVE_SCRIPT_PATH := "res://scripts/view_move.gd"
const MULTIVERSE_SCRIPT_PATH := "res://scripts/multiverse.gd"
const VIEWS_SCRIPT_PATH := "res://scripts/extra_views.gd"
const LIFT_SCRIPT_PATH := "res://scripts/lift.gd"
const CURIO_SCRIPT_PATH := "res://scripts/curio_wheel.gd"
const DRONE_SCRIPT_PATH := "res://scripts/drone.gd"
## IX pipelines as holograms over Seldon's statue (artpass/holo/).
const HOLO_SCRIPT_PATH := "res://scripts/hologram_ix.gd"
## Seldon's recording: his figure in points of light, from the statue's own mesh (artpass/recording/).
const RECORDING_SCRIPT_PATH := "res://scripts/seldon_recording.gd"
## The particle frieze: a mosaic over each bay that gathers out of drifting dust (artpass/fresco/).
const FRESCO_SCRIPT_PATH := "res://scripts/fresco_frieze.gd"
## Adaptive quality: steps down while frames come slow (artpass/perf/).
const QUALITY_SCRIPT_PATH := "res://scripts/quality.gd"
const GILT_SHADER_PATH := "res://assets/gilt.gdshader"
const RADIANT_SCRIPT_PATH := "res://scripts/prime_radiant.gd"
## Where the Prime Radiant floats: its centre, above the steel box (whose top is at 4.75 m), and
## its height, apex to apex. At 1.5 m it was a speck from the start view (artpass/radiant/r2).
const RADIANT_Y := 7.0
const RADIANT_HEIGHT := 2.4
## How dark the painted contact shadows get at an object's foot (assets/floor_paving.gdshader).
const CONTACT_STRENGTH := 0.7
const GLASS_PANELS := [
	["res://assets/glass_sun_moon.png", Color(0.45, 0.7, 1.0)],
	["res://assets/glass_elven_tree.png", Color(0.75, 1.0, 0.45)],
	["res://assets/glass_alembic.png", Color(0.8, 0.5, 1.0)],
]
## Vase baluster, 0.9 m, (radius, height) from its foot to its top: a base, a bulb low down,
## a slender neck, a collar and a cap.
const BALUSTER_PROFILE := [Vector2(0, 0), Vector2(0.036, 0), Vector2(0.036, 0.05), Vector2(0.028, 0.065),
	Vector2(0.031, 0.085), Vector2(0.021, 0.11), Vector2(0.017, 0.17), Vector2(0.022, 0.24), Vector2(0.035, 0.34),
	Vector2(0.041, 0.42), Vector2(0.037, 0.5), Vector2(0.025, 0.58), Vector2(0.016, 0.64), Vector2(0.016, 0.71),
	Vector2(0.024, 0.75), Vector2(0.029, 0.79), Vector2(0.021, 0.815), Vector2(0.031, 0.835), Vector2(0.031, 0.9),
	Vector2(0, 0.9)]

@export_group("Colonnade")
@export_range(8, 32, 1) var bay_count := 16:
	set(value):
		bay_count = value
		_queue_rebuild()
@export_range(8.0, 16.0, 0.1) var colonnade_radius := 13.0:
	set(value):
		colonnade_radius = value
		_queue_rebuild()
@export_range(12.0, 24.0, 0.1) var column_height := 19.0:
	set(value):
		column_height = value
		_queue_rebuild()

@export_group("Galleries")
@export_range(15.0, 26.0, 0.1) var outer_radius := 18.0:
	set(value):
		outer_radius = value
		_queue_rebuild()
@export var gallery_levels := PackedFloat32Array([6.2, 12.6]):
	set(value):
		gallery_levels = value
		_queue_rebuild()

@export_group("Ceiling")
@export_range(4.0, 12.0, 0.1) var oculus_radius := 10.0:
	set(value):
		oculus_radius = value
		_queue_rebuild()
@export_range(0, 8, 1) var orrery_rings := 5:
	set(value):
		orrery_rings = value
		_queue_rebuild()
@export_range(0.0, 1.0, 0.01) var orrery_speed := 0.05

@export_group("Data rain")
@export_range(0, 6, 1) var beams_per_bay := 1:
	set(value):
		beams_per_bay = value
		_queue_rebuild()
@export_range(0, 80, 1) var central_beams := 36:
	set(value):
		central_beams = value
		_queue_rebuild()
@export_range(0.0, 30.0, 0.5) var rain_speed := 7.0
@export_range(0.0, 20.0, 0.1) var beam_energy := 0.6:
	set(value):
		beam_energy = value
		_queue_rebuild()
@export_range(0.0, 20.0, 0.1) var drop_energy := 3.5:
	set(value):
		drop_energy = value
		_queue_rebuild()
## Light shafts and drops fade out closer than this to the camera (0 = off), so a beam
## a metre away does not become a wide green bar (art pass gallery review).
@export_range(0.0, 10.0, 0.1) var near_beam_fade := 6.0:
	set(value):
		near_beam_fade = value
		_queue_rebuild()
## Bay rain sits this far inside the colonnade (v1: 1.4 m). 2.4 m keeps it further from
## gallery viewpoints (finish pass).
@export_range(0.5, 5.0, 0.1) var rain_inset := 2.4:
	set(value):
		rain_inset = value
		_queue_rebuild()

@export_group("Art pass")
## Engraved stone panel (ComfyUI output) on each pier's inner face. Empty: procedural orbits.
@export var pier_ornament: Texture2D:
	set(value):
		pier_ornament = value
		_queue_rebuild()
@export_range(0.0, 3.0, 0.05) var ornament_glow := 0.12:
	set(value):
		ornament_glow = value
		_queue_rebuild()
## Box-projected probe so the steel and the polished floor reflect the hall, not the black background.
@export var use_reflection_probe := true:
	set(value):
		use_reflection_probe = value
		_queue_rebuild()
## Marble on the floor and the stone, world-triplanar (the procedural meshes have no UVs).
## Only while pier_ornament is set, so capture.gd's v1 profile (which clears it) stays v1.
@export var use_marble := true:
	set(value):
		use_marble = value
		_queue_rebuild()

@export_group("Books")
## Hardbacks with rounded spines, raised bands, labels and gilt, flush to the shelf edge, in
## series, some leaning or lying flat. Off: the v1 coloured boxes. Like use_marble, only while
## pier_ornament is set, so capture.gd's v1 profile stays v1.
@export var realistic_books := true:
	set(value):
		realistic_books = value
		_queue_rebuild()
## Distance between shelf boards (realistic books only); v1 spaces them about 1.1 m apart.
@export_range(0.4, 1.2, 0.01) var shelf_pitch := 0.62:
	set(value):
		shelf_pitch = value
		_queue_rebuild()
## Coursed piers, voussoirs, coffered ceiling and bump-mapped engraved panels (art pass only).
@export var stone_relief := true:
	set(value):
		stone_relief = value
		_queue_rebuild()
## Turned bronze balusters, bottom rail and walnut handrail instead of v1's square posts (art pass only).
@export var turned_balusters := true:
	set(value):
		turned_balusters = value
		_queue_rebuild()
## Backlit stained-glass lancets around the oculus drum, each throwing a tinted shaft into the
## volumetric fog (art pass only). 0 = none.
@export_range(0, 32, 1) var stained_glass_windows := 24:
	set(value):
		stained_glass_windows = value
		_queue_rebuild()
@export_range(0.0, 16.0, 0.1) var glass_energy := 2.8:
	set(value):
		glass_energy = value
		_queue_rebuild()
@export_range(0.0, 16.0, 0.1) var glass_light_energy := 2.0:
	set(value):
		glass_light_energy = value
		_queue_rebuild()
## Every course of the site as a book on the ground-floor shelves, at eye level: one bay per area,
## each area a series in its own cloth between brass bookends, with a card and a catalogue to open
## them (scripts/course_library.gd). Realistic books only.
@export var course_shelves := true:
	set(value):
		course_shelves = value
		_queue_rebuild()
## Gilt mouldings on the capitals, pier bases and panels, gilt arch bands, entablature and drum
## bands and ceiling ribs, and a paved floor with a compass rose (art pass only).
@export var gilding := true:
	set(value):
		gilding = value
		_queue_rebuild()
## Hari Seldon in marble on a gilt-lettered pedestal, in the hall in front of the last bay, the
## Streeling University shelves (scripts/seldon_statue.gd). Art pass only.
@export var seldon_statue := true:
	set(value):
		seldon_statue = value
		_queue_rebuild()
## R. Daneel Olivaw in marble, Seldon's counterpart across the hall (scripts/daneel_statue.gd), his
## raised palm broken over metal. Off until the user accepts it: --daneel on the command line, or
## ?daneel=1 in the web page's address, turns it on; --daneel=plain (?daneel=plain) without the break.
@export var daneel_statue := false:
	set(value):
		daneel_statue = value
		_queue_rebuild()
@export var daneel_reveal := true:
	set(value):
		daneel_reveal = value
		_queue_rebuild()
## The sky over the oculus: stars, the Galaxy and the moon at infinity (assets/night_sky.gdshader).
## Off, the painted cap and its sphere stars come back: --sky=cap, or ?sky=cap on the web.
@export var night_sky := true:
	set(value):
		night_sky = value
		_queue_rebuild()
## How bright the drawn core shows over the sky (artpass/sky2/).
@export_range(0.0, 4.0, 0.01) var core_cap_energy := 0.8:
	set(value):
		core_cap_energy = value
		_queue_rebuild()
## The orrery's rings as glowing white lines, as before the night sky; off, they are brass and
## its bodies ivory, an instrument seen against the sky. --orrery=glow (?orrery=glow) turns it on.
@export var orrery_glow := false:
	set(value):
		orrery_glow = value
		_queue_rebuild()
## Moonlight through the oculus: a spot light under the sky cap that throws the box's, the
## statue's and the piers' shadows across the floor, and contact shadows painted into the paving
## (assets/floor_paving.gdshader). Positional shadows stay cached while nothing in the light's
## range moves, so the web build pays for one more lighting pass, not a shadow render per frame
## (artpass/shadows/NOTES.md). Off, the hall is lit as before.
@export var moon_shadows := true:
	set(value):
		moon_shadows = value
		_queue_rebuild()
@export_range(0.0, 60.0, 0.5) var moon_energy := 12.0:
	set(value):
		moon_energy = value
		_queue_rebuild()
## Where the moon stands, seen from above, in degrees from +x towards +z: 200 is on the left of
## the start view, so the shadows fall to the right, into view.
@export_range(0.0, 360.0, 1.0) var moon_azimuth := 200.0:
	set(value):
		moon_azimuth = value
		_queue_rebuild()
## Gilding as metal (assets/gilt.gdshader): gold leaf that reflects the lamplit shelves, the dome
## and the floor, instead of an orange emission. Compatibility has nothing for a metal to reflect,
## so the shader computes that surround itself (artpass/materials/NOTES.md). Off, the gilt is the
## emissive StandardMaterial3D it was before. Off until the user accepts it: --gilt=metal on the
## command line, or ?gilt=metal in the web page's address, turns it on.
@export var gilt_metal := false:
	set(value):
		gilt_metal = value
		_queue_rebuild()
## The Prime Radiant above the steel box (scripts/prime_radiant.gd): a faceted crystal on a
## titanium frame, with a jewelled girdle and a light that reaches the box. Off, the box is as it
## was. radiant_particles adds its mathematics, points of light on curves around it: one draw call,
## animated in the shader (artpass/radiant/NOTES.md). Off until the user chooses a style: picking
## one with --radiant=<style> or ?radiant=<style> turns it on.
@export var prime_radiant := false:
	set(value):
		prime_radiant = value
		_queue_rebuild()
@export var radiant_particles := true:
	set(value):
		radiant_particles = value
		_queue_rebuild()
## The Prime Radiant's composition, for the user to choose (artpass/radiant/NOTES.md): "jewel", the
## first version; "a", the crystal alone against a third of the central rain; "b", half the rain
## parting around the crystal and going on down to the box; "c", a smaller dark artifact projecting
## equations around it, under a quarter of the rain that ends above it. --radiant=<style> on the command line, or
## ?radiant=<style> in the web page's address, overrides it.
@export_enum("jewel", "a", "b", "c") var radiant_style := "c":
	set(value):
		radiant_style = value
		_queue_rebuild()
## Walk mode as a body (scripts/walk_physics.gd): Space jumps, C crouches, C while sprinting
## slides, and the steel box, the piers, the statue and the shelves stop the walker. Off: the
## camera walks as it did, through everything. Read when the scene starts.
@export var walk_physics := true

## Counts of what the last rebuild produced; capture.gd --selftest prints them.
var stats := {}

var _rebuild_pending := false
var _m := {}
var _ceiling_y := 0.0
var _dome_y := 0.0
var _drops: MultiMesh
var _drop_data: Array = []
var _orrery_pivots: Array[Node3D] = []
var _time := 0.0
var _ground_shelves := {}  # radius, inner width and board spacing of the ground-level units
## The ground-level row at eye height (1.27 to 1.83 m) that scripts/course_library.gd fills.
const COURSE_ROW := 2


func _ready() -> void:
	if not Engine.is_editor_hint():
		var pick := ""
		var gilt := ""
		var daneel := ""
		var sky := ""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--radiant="):
				pick = arg.trim_prefix("--radiant=")
			elif arg.begins_with("--gilt="):
				gilt = arg.trim_prefix("--gilt=")
			elif arg.begins_with("--sky="):
				sky = arg.trim_prefix("--sky=")
			elif arg == "--orrery=glow":
				orrery_glow = true
			elif arg == "--daneel" or arg.begins_with("--daneel="):
				daneel = arg.trim_prefix("--daneel").trim_prefix("=")
				daneel = daneel if daneel != "" else "1"
		if OS.has_feature("web"):
			pick = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('radiant') || ''", true))
			gilt = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('gilt') || ''", true))
			daneel = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('daneel') || ''", true))
			sky = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('sky') || ''", true))
		if sky == "cap":
			night_sky = false
		if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('orrery') || ''", true)) == "glow":
			orrery_glow = true
		if daneel in ["1", "plain"]:
			daneel_statue = true
			daneel_reveal = daneel == "1"
		# Both stay experiments: the published export leaves out their files, so there they fall back.
		if pick in ["jewel", "a", "b", "c"]:
			radiant_style = pick
			prime_radiant = true
		if gilt == "metal":
			gilt_metal = true
	_rebuild()
	if OS.has_feature("web") and not Engine.is_editor_hint():
		# On a computer MSAA costs the web build ten times its frame: 29 ms instead of 2.9 ms full
		# screen (3819 x 1959) in Chrome on an RTX 5080, and 36 ms at 2x (artpass/perf/NOTES.md).
		# Touch screens get 4x from _web_ss() below, which the page may step down
		# (artpass/motion/NOTES.md). FXAA stays set, but under Compatibility it changes no pixel.
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		# FXAA barely touches the thin gilt and lamp strips. The page's head script (the export
		# preset's head_include) makes the canvas render 1.5 times finer than the screen on
		# computers and lets the browser filter it down: supersampling without Godot's own MSAA
		# or 3D scaling, which leave ANGLE's fast path. The 2D interface is scaled back up by the
		# same factor so the HUD keeps its size (artpass/aa/NOTES.md). ?aa=none|fxaa|smaa and
		# ?ss=<factor> in the page's address override both, for comparisons.
		_web_ss()
		JavaScriptBridge.eval("window.__obsRunning = true", true)
		var aa := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('aa') || ''", true))
		if aa == "none":
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		elif aa == "smaa":
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA
	if walk_physics and not Engine.is_editor_hint() and ResourceLoader.exists(WALK_SCRIPT_PATH):
		# Jump, crouch, slide, inertia and collisions in walk mode, around the camera's own moves.
		var walk: Node = load(WALK_SCRIPT_PATH).new()
		walk.name = "WalkBody"
		walk.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(walk)
	if not Engine.is_editor_hint() and ResourceLoader.exists(FIT_SCRIPT_PATH):
		# A phone held upright would see 32 degrees across: widen its field (artpass/motion/).
		var fit: Node = load(FIT_SCRIPT_PATH).new()
		fit.name = "ViewFit"
		fit.configure(get_node_or_null("FlyCamera") as Camera3D)
		add_child(fit)
	if not Engine.is_editor_hint() and ResourceLoader.exists(MOVE_SCRIPT_PATH):
		# A preset view is a short flight rather than a cut, unless the player asks for less motion.
		var move: Node = load(MOVE_SCRIPT_PATH).new()
		move.name = "ViewMove"
		move.configure(get_node_or_null("FlyCamera") as Camera3D, _ceiling_y)
		add_child(move)
	var touch_screen := DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")
	if touch_screen and not Engine.is_editor_hint() and ResourceLoader.exists(TOUCH_SCRIPT_PATH):
		# Phones and tablets have no keys to walk or fly with: a stick, look drags and buttons.
		var touch: CanvasLayer = load(TOUCH_SCRIPT_PATH).new()
		touch.name = "TouchControls"
		touch.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(touch)
	if not Engine.is_editor_hint() and ResourceLoader.exists(MULTIVERSE_SCRIPT_PATH):
		# A double-click on the box (a double tap): the corridor of doors behind it.
		var mv: Node = load(MULTIVERSE_SCRIPT_PATH).new()
		mv.name = "Multiverse"
		mv.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(mv)
	if not Engine.is_editor_hint() and ResourceLoader.exists(VIEWS_SCRIPT_PATH):
		# Keys 8 and 9: the stained glass, and the roof over Trantor (scripts/upperside.gd).
		var views: Node = load(VIEWS_SCRIPT_PATH).new()
		views.name = "ExtraViews"
		views.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(views)
	if not Engine.is_editor_hint() and ResourceLoader.exists(LIFT_SCRIPT_PATH):
		# The lift to the galleries, which the walking body walks (artpass/floors/).
		var lift: Node = load(LIFT_SCRIPT_PATH).new()
		lift.name = "Lift"
		lift.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(lift)
	if not Engine.is_editor_hint() and ResourceLoader.exists(CURIO_SCRIPT_PATH):
		# Tab: the curio wheel, a library's pastiche of a shooter's weapon wheel (artpass/curios/).
		var curio: Node = load(CURIO_SCRIPT_PATH).new()
		curio.name = "CurioWheel"
		curio.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(curio)
	if not Engine.is_editor_hint() and _statue_on() and ResourceLoader.exists(HOLO_SCRIPT_PATH):
		# Look at the sphere in Seldon's hands, press H, click or tap it: a real IX run replays round
		# the statue (artpass/holo/NOTES.md).
		var holo: Node3D = load(HOLO_SCRIPT_PATH).new()
		holo.name = "Hologram"
		holo.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(holo)
		stats.holo_pipelines = holo.stats.get("pipelines", 0)
		stats.holo_steps = holo.stats.get("steps", 0)
	if not Engine.is_editor_hint() and _statue_on() and ResourceLoader.exists(RECORDING_SCRIPT_PATH):
		# Look at the inscription on Seldon's pedestal, press R, click or tap it: he forms beside it in
		# points of light, speaks three lines and lifts away (artpass/recording/NOTES.md).
		var recording: Node3D = load(RECORDING_SCRIPT_PATH).new()
		recording.name = "SeldonRecording"
		recording.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(recording)
		stats.recording = true
	if not Engine.is_editor_hint() and ResourceLoader.exists(FRESCO_SCRIPT_PATH):
		# Look at a panel of the frieze over a bay for a second, click or tap it: its dust gathers into
		# the mosaic, tessera by tessera (artpass/fresco/NOTES.md).
		var frieze: Node3D = load(FRESCO_SCRIPT_PATH).new()
		frieze.name = "FrescoFrieze"
		frieze.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(frieze)
		stats.frieze = true
	if not Engine.is_editor_hint() and ResourceLoader.exists(QUALITY_SCRIPT_PATH):
		# A weak GPU as well as the RTX: frames timed, a ladder of losses, shadows late (scripts/quality.gd).
		var quality: Node = load(QUALITY_SCRIPT_PATH).new()
		quality.name = "Quality"
		quality.configure(self)
		add_child(quality)
		stats.quality_auto = quality.stats.get("auto", true)
	if not Engine.is_editor_hint() and ResourceLoader.exists(DRONE_SCRIPT_PATH):
		# The curio wheel's pocket drone, which tours the hall (artpass/drone/). Last: while it flies,
		# its _input, called first, takes every key, click and touch.
		var drone: Node = load(DRONE_SCRIPT_PATH).new()
		drone.name = "Drone"
		drone.configure(self, get_node_or_null("FlyCamera") as Camera3D)
		add_child(drone)
	if not Engine.is_editor_hint():
		var view := ""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--view="):
				view = arg.trim_prefix("--view=")
		if OS.has_feature("web"):
			view = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('view') || ''", true))
		if view != "":
			_apply_view.call_deferred(view)
		if OS.has_feature("web") and ResourceLoader.exists(FOLLOW_SCRIPT_PATH) \
				and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('follow') || ''", true)) == "1":
			# Moving captures: a harness drives the camera frame by frame (artpass/motion/).
			var follow: Node = load(FOLLOW_SCRIPT_PATH).new()
			follow.name = "CameraFollow"
			follow.configure(get_node_or_null("FlyCamera") as Camera3D, get_node_or_null("WalkBody"))
			add_child(follow)
	if moon_shadows and not Engine.is_editor_hint():
		# In 16 bits, depth over the moon's 40 m range stripes the whole floor with self-shadowing
		# bands under Compatibility, whatever the bias (artpass/shadows/NOTES.md).
		get_viewport().positional_shadow_atlas_16_bits = false


## A camera placed by the page's address or the command line: "x,y,z,yaw,pitch", metres and
## degrees (yaw 0 looks towards -z, pitch up is positive). For captures that must frame the same
## thing on every screen; the walking body takes it as a teleport.
func _apply_view(view: String) -> void:
	var v := view.split_floats(",")
	var cam := get_node_or_null("FlyCamera") as Camera3D
	if v.size() != 5 or cam == null:
		return
	cam.global_position = Vector3(v[0], v[1], v[2])
	cam.set("_yaw", deg_to_rad(v[3]))
	cam.set("_pitch", deg_to_rad(v[4]))
	cam.rotation = Vector3(deg_to_rad(v[4]), deg_to_rad(v[3]), 0.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_update_drops(_time)
	for k in _orrery_pivots.size():
		_orrery_pivots[k].rotate_object_local(Vector3.UP, orrery_speed * delta * (1.0 + k * 0.35))
	if OS.has_feature("web") and int(_time) != int(_time - delta):
		_web_ss()  # once a second: the page may have dropped its supersampling


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
	stats = {}
	_drop_data.clear()
	_orrery_pivots.clear()
	_drops = null
	_ceiling_y = column_height + 1.5
	_dome_y = _ceiling_y + 0.6 + 3.5
	_make_materials()

	var root := Node3D.new()
	root.name = "Generated"
	add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_build_floor(_group(root, "Floor"), rng)
	_build_colonnade(_group(root, "Colonnade"))
	_build_galleries(_group(root, "Galleries"))
	_build_shelves(_group(root, "Shelves"), rng)
	_build_ceiling(_group(root, "Ceiling"), rng)
	_build_rain(_group(root, "Rain"), rng)
	_build_lights(_group(root, "Lights"))
	var lang := "en"
	if course_shelves and _ground_shelves.get("reserved", false):
		lang = _build_courses(root)
	if _statue_on():
		_build_statue(root, lang)
	stats.daneel = 0
	if _daneel_on():
		_build_daneel(root, lang)
	stats.radiant = 0
	if _radiant_on():
		_build_radiant(root)


# --- Sections -----------------------------------------------------------------

func _build_floor(g: Node3D, rng: RandomNumberGenerator) -> void:
	var inlays := [[2.9, 0.1, "gold"], [3.7, 0.05, "silver"], [5.6, 0.08, "gold"], [8.1, 0.05, "silver"], [11.2, 0.12, "gold"]]
	var floor_mat: Material = _m.floor
	stats.floor_paving = 0
	if _gilding_on() and _m.floor.albedo_texture and ResourceLoader.exists(PAVING_SHADER_PATH):
		# Rings of slabs between the inlays, their joints under the brass: 1, 2, 3 and 3 rings, then
		# rings of about 0.9 m out to the wall.
		var bounds := PackedFloat32Array()
		var edges := [2.9, 3.7, 5.6, 8.1, 11.2]
		var splits := [1, 2, 3, 3]
		for k in splits.size():
			for j in splits[k]:
				bounds.append(lerpf(edges[k], edges[k + 1], float(j) / splits[k]))
		var r := 11.2
		while r < outer_radius + 0.6:
			bounds.append(r)
			r += 0.9
		bounds.append(outer_radius + 0.6)
		var paving := ShaderMaterial.new()
		paving.shader = load(PAVING_SHADER_PATH)
		paving.set_shader_parameter("marble", _m.floor.albedo_texture)
		paving.set_shader_parameter("ring_bounds", bounds)
		paving.set_shader_parameter("ring_count", bounds.size())
		paving.set_shader_parameter("gilt_emission", _m.gold_flat.emission_energy_multiplier)
		if _compatibility():
			# Stand-ins, set by eye as for the bronze and walnut below: with the Forward+ tints the
			# paving came out two to three times brighter here, and blue (artpass/statue/NOTES.md).
			paving.set_shader_parameter("pale", Color(0.38, 0.39, 0.38))
			paving.set_shader_parameter("dark", Color(0.08, 0.085, 0.09))
			paving.set_shader_parameter("rose_pale", Color(0.62, 0.61, 0.57))
			paving.set_shader_parameter("rose_dark", Color(0.04, 0.04, 0.045))
		stats.contact_shadows = 0
		if moon_shadows:
			paving.set_shader_parameter("contact_strength", CONTACT_STRENGTH)
			paving.set_shader_parameter("pier_count", bay_count)
			paving.set_shader_parameter("pier_radius", colonnade_radius)
			paving.set_shader_parameter("shelf_radius", outer_radius - 0.55 - 0.31)
			if _statue_on():
				var xf := _radial(TAU * (_statue_bay() + 0.5) / bay_count, colonnade_radius - 3.8, 0.0)
				paving.set_shader_parameter("pedestal", Vector3(xf.origin.x, xf.origin.z, 0.75))
				paving.set_shader_parameter("pedestal_angle", -xf.basis.get_euler().y)
			stats.contact_shadows = 1
		floor_mat = paving
		stats.floor_paving = bounds.size() - 1
	_add(g, "FloorDisc", ring_sector(0.0, outer_radius + 0.6, 0.3, 0.0, TAU, 96), floor_mat, _at(0, -0.3, 0))
	for i in inlays.size():
		var r: float = inlays[i][0]
		var w: float = inlays[i][1]
		_add(g, "Inlay%d" % i, ring_sector(r, r + w, 0.012, 0.0, TAU, 160), _m[inlays[i][2]], _at(0, 0, 0), false)
	# Orbit glyphs between the inlays: a circle and a crescent each.
	var glyph := ring_sector(0.26, 0.3, 0.012, 0.0, TAU, 32)
	var crescent := ring_sector(0.16, 0.2, 0.012, 0.0, PI, 16)
	var glyphs := 12
	for i in glyphs:
		var a := TAU * i / glyphs + 0.13
		var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(cos(a) * 6.85, 0.0, sin(a) * 6.85))
		_add(g, "Glyph%d" % i, glyph, _m.silver, t, false)
		_add(g, "Crescent%d" % i, crescent, _m.gold, t, false)
	var spoke := _box(Vector3(0.03, 0.012, 7.5))
	for i in bay_count:
		_add(g, "Spoke%d" % i, spoke, _m.silver, _radial(TAU * i / bay_count, 7.45, 0.006), false)
	# Finish pass: layer 2 is outside HallProbe's reflection_mask; the polished floor
	# reflected the probe's warm capture and turned orange-gold (art pass review).
	for c in g.get_children():
		(c as VisualInstance3D).layers = 2
	stats.floor_inlays = inlays.size()
	stats.floor_glyphs = glyphs * 2


func _build_colonnade(g: Node3D) -> void:
	var pier := _box(Vector3(1.1, column_height, 1.4))
	var plinth := _box(Vector3(1.5, 0.8, 1.8))
	var capital := _box(Vector3(1.45, 0.5, 1.75))
	var stem := _box(Vector3(0.05, column_height - 4.0, 0.02))
	var spring := column_height - 2.9
	var torus_xf: Array[Transform3D] = []
	var bead_xf: Array[Transform3D] = []
	# Art pass: one textured panel per pier face instead of the procedural orbits.
	var panel_h := spring - 0.6 - 1.0
	var panel := QuadMesh.new()
	panel.size = Vector2(1.1, panel_h)
	var panel_mat: StandardMaterial3D
	if pier_ornament:
		panel_mat = StandardMaterial3D.new()
		panel_mat.albedo_texture = pier_ornament
		panel_mat.albedo_color = Color(0.14, 0.16, 0.2)
		panel_mat.metallic = 0.1
		panel_mat.roughness = 0.6
		panel_mat.emission_enabled = true
		panel_mat.emission_texture = pier_ornament
		panel_mat.emission = Color(0.55, 0.65, 0.85)
		panel_mat.emission_energy_multiplier = ornament_glow
		# Keep the texture's 640 x 1536 aspect: 1.1 m wide tiles, repeated up the pier.
		panel_mat.uv1_scale = Vector3(1.0, panel_h / (1.1 * 1536.0 / 640.0), 1.0)
		panel_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if stone_relief and ResourceLoader.exists(ORNAMENT_NORMAL_PATH):
			# Detail pass: the carving catches the light (normal map derived from the panel itself).
			panel_mat.normal_enabled = true
			panel_mat.normal_texture = load(ORNAMENT_NORMAL_PATH)
			panel_mat.normal_scale = 1.0
			stats.ornament_normal_map = true
	for i in bay_count:
		var base := _radial(TAU * i / bay_count, colonnade_radius, 0.0)
		_add(g, "Pier%d" % i, pier, _m.get("stone_piers", _m.stone), base * _at(0, column_height * 0.5, 0))
		_add(g, "Plinth%d" % i, plinth, _m.get("stone_blocks", _m.stone_dark), base * _at(0, 0.4, 0))
		_add(g, "Capital%d" % i, capital, _m.get("stone_blocks", _m.stone_dark), base * _at(0, spring - 0.25, 0))
		if panel_mat:
			_add(g, "OrnamentPanel%d" % i, panel, panel_mat, base * _at(0, 1.0 + panel_h * 0.5, 0.705), false)
			continue
		_add(g, "Engraving%d" % i, stem, _m.silver, base * _at(0, 1.2 + (column_height - 4.0) * 0.5, 0.71), false)
		# Vine-like engraving: a stem with orbits and beads, never lettering.
		for k in 7:
			var y := 2.0 + k * 2.0
			var side := -0.2 if k % 2 == 0 else 0.2
			var r := 0.22 if k % 3 == 0 else 0.15
			torus_xf.append(base * Transform3D(Basis(Vector3.RIGHT, PI * 0.5).scaled(Vector3.ONE * r), Vector3(side, y, 0.72)))
			bead_xf.append(base * _at(-side, y + 0.35, 0.72))
	stats.gilt_mouldings = 0
	if _gilding_on():
		# A gilt bead round each capital's top, an astragal under it, a bead on each base, and a
		# beaded frame round each carved panel: half-rounds swept round the stone (moulding), whose
		# highlight rolls along them, where the flat strips they replace read as painted lines. Each
		# meets its face at a right angle, so no gilt face lies in a stone one (artpass/shadows/).
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count := 0
		# A bead's centre line runs 12 mm outside its core, so its corners are round, not pinched.
		var beads := [
			[Vector2(0.55, 0.7), spring - 0.54, 0.012],  # the shaft, 1.1 x 1.4: the astragal's rod
			[Vector2(0.75, 0.9), 0.769, 0.025],  # the plinth, 1.5 x 1.8
		]
		# The capital's ovolo, 10 cm high and 5 cm proud under a fillet, carved with eggs and darts.
		var cap_core := Vector2(0.725 - 0.012, 0.875 - 0.012)
		var ovolo := []
		profile_arc(ovolo, Vector2(0.012, spring - 0.03), 0.05, 0.1, -PI / 2, 0.0, 10, [cap_core])
		ovolo += [[Vector2(0.062, spring - 0.006), Vector2(1, 0), cap_core], [Vector2(0.062, spring - 0.006), Vector2(0, 1), cap_core],
			[Vector2(0.012, spring - 0.006), Vector2(0, 1), cap_core]]
		# On each face's flat run, in the pier's frame: the eggs where the ovolo leans out at 45
		# degrees, the beads and reels along the astragal's rod.
		var egg_runs := []
		var bead_runs := []
		for face in [[Vector3(0, 0, 1), Vector3(1, 0, 0), cap_core.y, cap_core.x, 0.688, 0.538],
				[Vector3(0, 0, -1), Vector3(1, 0, 0), cap_core.y, cap_core.x, 0.688, 0.538],
				[Vector3(1, 0, 0), Vector3(0, 0, 1), cap_core.x, cap_core.y, 0.538, 0.688],
				[Vector3(-1, 0, 0), Vector3(0, 0, 1), cap_core.x, cap_core.y, 0.538, 0.688]]:
			var nf: Vector3 = face[0]
			var tf: Vector3 = face[1]
			var at: Vector3 = nf * (face[2] + 0.012 + 0.05 * cos(PI / 4)) + Vector3(0, spring - 0.03 - 0.1 * sin(PI / 4), 0)
			egg_runs.append([at - tf * face[3], at + tf * face[3], (nf * 0.894 + Vector3(0, -0.447, 0)).normalized()])
			var rod: Vector3 = nf * (face[4] + 0.012) + Vector3(0, spring - 0.54, 0)
			bead_runs.append([rod - tf * face[5], rod + tf * face[5], nf])
		var ornament := {"eggs": [], "darts": [], "beads": [], "reels": []}
		# The panel's frame stands on the pier's face: the moulding's y turned to the face's normal.
		var on_face := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)), Vector3(0, 1.0 + panel_h * 0.5, 0.7))
		# Its centre line where the flat frame's was, at x = +-0.5325 and on the panel's top and bottom.
		var frame := profile_bead(Vector2(0.0315, 0.0), 0.0175, Vector2(0, 1), 8, [Vector2(0.5325 - 0.0315, panel_h * 0.5 - 0.0315)])
		for i in bay_count:
			var base := _radial(TAU * i / bay_count, colonnade_radius, 0.0)
			for b in beads:
				moulding(st, profile_bead(Vector2(0.012, b[1]), b[2], Vector2(1, 0), 10, [b[0] - Vector2(0.012, 0.012)]), base)
				count += 1
			moulding(st, ovolo, base)
			count += 1
			for run in egg_runs:
				_along(ornament.eggs, run[0], run[1], run[2], 0.06, 0.5, base)
				_along(ornament.darts, run[0], run[1], run[2], 0.06, 0.0, base)
			for run in bead_runs:
				_along(ornament.beads, run[0], run[1], run[2], 0.06, 0.5, base)
				_along(ornament.reels, run[0], run[1], run[2], 0.06, 0.0, base)
			if panel_mat:
				moulding(st, frame, base * on_face)
				count += 4
		_add(g, "GiltMouldings", st.commit(), _m.gold, Transform3D(), false)
		stats.gilt_mouldings = count
		_gilt_ornament(g, "Capital", ornament, Vector3(0.017, 0.03, 0.009), Vector3(0.004, 0.026, 0.007))
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 8
	_multi(g, "EngravedOrbits", torus, _m.silver, torus_xf, [], false)
	var bead := SphereMesh.new()
	bead.radius = 0.05
	bead.height = 0.1
	_multi(g, "EngravedBeads", bead, _m.silver, bead_xf, [], false)

	var half_span := colonnade_radius * sin(PI / bay_count)
	var mid_r := colonnade_radius * cos(PI / bay_count)
	var inner := half_span - 0.55
	var arch := ring_sector(inner, half_span + 0.3, 1.2, 0.0, PI, 32)
	var band := ring_sector(inner + 0.08, inner + 0.14, 0.03, 0.0, PI, 32)
	var upright := Basis(Vector3.RIGHT, -PI * 0.5)
	# Two half-round beads on each arch's face (its plane is the profile's y = 0, the hall side -y).
	var arch_beads := SurfaceTool.new()
	arch_beads.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_arch_beads := false
	for i in bay_count:
		var base := _radial(TAU * (i + 0.5) / bay_count, mid_r, spring)
		_add(g, "Arch%d" % i, arch, _m.get("stone_arches", _m.stone), base * Transform3D(upright, Vector3(0, 0, 0.6)))
		if _gilding_on():
			for r in [inner + 0.11, half_span + 0.23]:
				revolve(arch_beads, profile_bead(Vector2(r, 0.0), 0.03, Vector2(0, -1), 10), 32, 0.0, PI, base * Transform3D(upright, Vector3(0, 0, 0.6)))
			has_arch_beads = true
		else:
			_add(g, "ArchBand%d" % i, band, _m.silver, base * Transform3D(upright, Vector3(0, 0, 0.63)), false)
	if has_arch_beads:
		_add(g, "GiltArchBands", arch_beads.commit(), _m.gold, Transform3D(), false)

	var ent_y := column_height - 0.8
	_add(g, "Entablature", ring_sector(colonnade_radius - 0.7, colonnade_radius + 0.7, _ceiling_y - ent_y, 0.0, TAU, 128), _m.get("stone_courses", _m.stone), _at(0, ent_y, 0))
	for k in 2:
		var y := ent_y + 0.4 + k * 1.3
		if _gilding_on():
			# A bead on the entablature's inner face, towards the hall.
			_add(g, "EntablatureBand%d" % k, _bead_ring(colonnade_radius - 0.7, 0.03), _m.gold, _at(0, y + 0.03, 0), false)
		else:
			_add(g, "EntablatureBand%d" % k, ring_sector(colonnade_radius - 0.72, colonnade_radius - 0.7, 0.06, 0.0, TAU, 128), _m.silver, _at(0, y, 0), false)
	stats.piers = bay_count
	stats.arches = bay_count
	stats.engraved_orbits = torus_xf.size()
	stats.ornament_panels = bay_count if panel_mat else 0


func _build_galleries(g: Node3D) -> void:
	var r_in := colonnade_radius + 0.7
	var r_out := outer_radius - 0.2
	var xf: Array[Transform3D] = []
	var turned := turned_balusters and pier_ornament != null
	var rail_r := r_in + 0.08
	var per_bay := []  # turned balusters, one MultiMesh per bay so the frustum can cull them
	# The lift's shaft (scripts/lift.gd), cut out of every walkway.
	var shaft := _lift_shaft()
	if not shaft.is_empty():
		stats.lift_cut = true
	for i in bay_count:
		per_bay.append([])
	# The gilt edge under each walkway's inner edge: an ovolo 12 cm high and 4 cm proud, an astragal
	# under it, closed underneath; seen from the floor, it is the hall's longest moulding.
	var edge_profile := []
	profile_arc(edge_profile, Vector2(r_in, -0.06), 0.04, 0.06, PI / 2, PI * 1.5, 14)
	edge_profile += profile_bead(Vector2(r_in, -0.135), 0.015, Vector2(-1, 0), 8)
	edge_profile += [[Vector2(r_in, -0.15), Vector2(0, -1)], [Vector2(r_in + 0.1, -0.15), Vector2(0, -1)]]
	var est := SurfaceTool.new()
	est.begin(Mesh.PRIMITIVE_TRIANGLES)
	revolve(est, edge_profile, 128)
	var edge := est.commit()
	for li in gallery_levels.size():
		var y := gallery_levels[li]
		if shaft.is_empty():
			_add(g, "Walkway%d" % li, ring_sector(r_in, r_out, 0.35, 0.0, TAU, 128), _m.stone_dark, _at(0, y - 0.35, 0))
		else:
			# Cut round the lift's shaft: the ring less the sector, and the sector's inner and outer strips.
			var a0: float = shaft.a - shaft.half
			var a1: float = shaft.a + shaft.half
			_add(g, "Walkway%d" % li, ring_sector(r_in, r_out, 0.35, a1, a0 + TAU, 126), _m.stone_dark, _at(0, y - 0.35, 0))
			_add(g, "WalkwayIn%d" % li, ring_sector(r_in, shaft.r0, 0.35, a0, a1, 2), _m.stone_dark, _at(0, y - 0.35, 0))
			_add(g, "WalkwayOut%d" % li, ring_sector(shaft.r1, r_out, 0.35, a0, a1, 2), _m.stone_dark, _at(0, y - 0.35, 0))
		_add(g, "GildedEdge%d" % li, edge, _m.gold, _at(0, y - 0.35, 0), false)
		# Eggs and darts round the ovolo's belly, facing the hall.
		var edge_ornament := {"eggs": [], "darts": []}
		_round(edge_ornament.eggs, r_in - 0.04, y - 0.41, 0.0, TAU, 0.085, 0.5, 0.0)
		_round(edge_ornament.darts, r_in - 0.04, y - 0.41, 0.0, TAU, 0.085, 0.0, 0.0)
		_gilt_ornament(g, "Edge%d" % li, edge_ornament, Vector3(0.024, 0.04, 0.012), Vector3(0.005, 0.034, 0.008))
		if not turned:
			_add(g, "Rail%d" % li, ring_sector(r_in + 0.02, r_in + 0.14, 0.07, 0.0, TAU, 128), _m.silver, _at(0, y + 1.05, 0), false)
			var n := int(TAU * r_in / 0.42)
			for k in n:
				var a := TAU * k / n
				xf.append(_at(cos(a) * rail_r, y + 0.52, sin(a) * rail_r))
			continue
		# A walnut handrail on turned bronze balusters standing on a bronze bottom rail.
		_add(g, "BottomRail%d" % li, ring_sector(rail_r - 0.05, rail_r + 0.05, 0.07, 0.0, TAU, 160), _m.bronze, _at(0, y, 0))
		var section := PackedVector2Array()
		for k in 16:
			var phi := TAU * k / 16.0
			var c := cos(phi)
			var s := sin(phi)
			section.append(Vector2(rail_r + 0.065 * signf(c) * pow(absf(c), 0.6), y + 1.02 + 0.05 * signf(s) * pow(absf(s), 0.6)))
		_add(g, "Handrail%d" % li, _lathe(section, 192, true), _m.walnut, Transform3D())
		var n := int(TAU * rail_r / 0.3)
		for k in n:
			var a := TAU * (k + 0.5) / n
			var t := _at(cos(a) * rail_r, y + 0.07, sin(a) * rail_r)
			xf.append(t)
			per_bay[mini(int(a / TAU * bay_count), bay_count - 1)].append(t)
	if turned:
		var mesh := _lathe(PackedVector2Array(BALUSTER_PROFILE), 10)
		for i in bay_count:
			_multi(g, "Balusters_B%02d" % i, mesh, _m.bronze, per_bay[i], [], false)
		stats.turned_balusters = true
	else:
		_multi(g, "Balusters", _box(Vector3(0.05, 1.04, 0.05)), _m.silver_dim, xf, [], false)
	stats.gallery_levels = gallery_levels.size()
	stats.balusters = xf.size()


func _build_shelves(g: Node3D, rng: RandomNumberGenerator) -> void:
	var r := outer_radius - 0.55
	var width := 2.0 * r * sin(PI / bay_count) - 0.3
	var bottoms: Array[float] = [0.0]
	for y in gallery_levels:
		bottoms.append(y)
	var palette := [Color(0.08, 0.22, 0.24), Color(0.32, 0.07, 0.06), Color(0.07, 0.1, 0.25),
		Color(0.55, 0.38, 0.12), Color(0.72, 0.66, 0.52), Color(0.2, 0.24, 0.1), Color(0.12, 0.12, 0.14)]
	var book_xf: Array[Transform3D] = []
	var book_col: Array[Color] = []
	var strip_xf: Array[Transform3D] = []
	var crystal_xf: Array[Transform3D] = []
	var board := _box(Vector3(width, 0.06, 0.6))
	# Every board, side and back of a bay, all levels, becomes one mesh: one draw call per bay
	# instead of about forty, which is what the web build's frame time was going on.
	var wood := []
	for i in bay_count:
		wood.append([])
	var reserve := realistic_books and pier_ornament != null and _m.has("book_bindings") and course_shelves
	var units := 0
	var lights := 0
	# Realistic books draw from their own stream; the v1 loop below still runs and draws from rng
	# exactly as before, so the ceiling, orrery and rain built after the shelves do not move.
	var real := realistic_books and pier_ornament != null and _m.has("book_bindings")
	var brng := RandomNumberGenerator.new()
	brng.seed = SEED + 1
	# One book MultiMesh per bay, so the frustum culls the walls behind the camera.
	var shelves := []
	for i in bay_count:
		shelves.append({"xf": [], "col": [], "cus": [], "crystals": [], "series": 0, "leaning": 0, "lying": 0})
	for li in bottoms.size():
		var y0 := bottoms[li]
		var y1 := (bottoms[li + 1] - 0.6) if li + 1 < bottoms.size() else column_height - 0.9
		var h := y1 - y0
		var boards := maxi(2, int(h / 1.05))
		var pitch := h / boards
		var rows := maxi(2, roundi(h / shelf_pitch)) if real else boards
		var row_pitch := h / rows
		var back := _box(Vector3(width, h, 0.08))
		var side := _box(Vector3(0.12, h, 0.62))
		if li == 0:
			_ground_shelves = {"radius": r, "width": width, "row_pitch": row_pitch, "reserved": reserve}
		for i in bay_count:
			var base := _radial(TAU * (i + 0.5) / bay_count, r, y0)
			var unit := _group(g, "Unit_L%d_B%02d" % [li, i])
			unit.transform = base
			wood[i].append([back, base * _at(0, h * 0.5, -0.3)])
			wood[i].append([side, base * _at(-width * 0.5, h * 0.5, 0)])
			wood[i].append([side, base * _at(width * 0.5, h * 0.5, 0)])
			for b in rows + 1:
				wood[i].append([board, base * _at(0, b * row_pitch, 0)])
				if b == rows:
					break
				if not real or b % 2 == 1:
					strip_xf.append(base * _at(0, (b + 1) * row_pitch - 0.06, 0.27))
				if real:
					# The course library fills the eye-level row; drawing it here anyway into a
					# discarded list keeps the stream, so every other row keeps its books.
					var row_out: Dictionary = shelves[i]
					if reserve and li == 0 and b == COURSE_ROW:
						row_out = {"xf": [], "col": [], "cus": [], "crystals": [], "series": 0, "leaning": 0, "lying": 0}
					_fill_board(brng, base, -width * 0.5 + 0.08, width * 0.5 - 0.08, b * row_pitch + 0.03, row_pitch - 0.06, row_out)
			for b in boards:
				var by := b * pitch
				var x := -width * 0.5 + 0.12
				while x < width * 0.5 - 0.2:
					var bw := rng.randf_range(0.05, 0.11)
					if rng.randf() < 0.05:
						x += rng.randf_range(0.1, 0.3)
						continue
					var bh := rng.randf_range(0.5, 0.82) * minf(1.0, (pitch - 0.12) / 0.85)
					var bd := rng.randf_range(0.32, 0.44)
					var pos := Vector3(x + bw * 0.5, by + 0.03 + bh * 0.5, -0.02)
					if rng.randf() < 0.035:
						crystal_xf.append(base * Transform3D(Basis.from_scale(Vector3(0.09, bh * 0.9, 0.09)), pos))
					else:
						var tilt := rng.randf_range(-0.12, 0.12) if rng.randf() < 0.08 else 0.0
						book_xf.append(base * Transform3D(Basis(Vector3.BACK, tilt) * Basis.from_scale(Vector3(bw, bh, bd)), pos))
						var c: Color = palette[rng.randi() % palette.size()]
						var f := rng.randf_range(0.7, 1.15)
						book_col.append(Color(c.r * f, c.g * f, c.b * f))
					x += bw + 0.008
			# Warm reading light in front of each unit.
			var lamp := OmniLight3D.new()
			lamp.name = "ShelfLamp"
			lamp.position = Vector3(0, h * 0.55, 1.5)
			lamp.light_color = Color(1.0, 0.74, 0.46)
			lamp.light_energy = 0.7
			lamp.omni_range = 5.5
			lamp.light_volumetric_fog_energy = 0.3
			unit.add_child(lamp)
			units += 1
			lights += 1
	for i in bay_count:
		_add(g, "Wood_B%02d" % i, _merge(wood[i]), _m.wood, Transform3D())
	stats.wood_meshes = bay_count
	if real:
		var mesh := _book_mesh()
		var counts := {"series": 0, "leaning": 0, "lying": 0}
		book_xf.clear()  # the v1 loop's books and crystals were drawn only to keep rng's stream
		crystal_xf.clear()
		for i in bay_count:
			var shelf: Dictionary = shelves[i]
			_multi(g, "Books_B%02d" % i, mesh, _m.book_bindings, shelf.xf, shelf.col, true, shelf.cus)
			book_xf.append_array(shelf.xf)
			crystal_xf.append_array(shelf.crystals)
			for key in counts:
				counts[key] += shelf[key]
		stats.book_multimeshes = bay_count
		stats.book_series = counts.series
		stats.leaning_books = counts.leaning
		stats.lying_books = counts.lying
	else:
		_multi(g, "Books", BoxMesh.new(), _m.books, book_xf, book_col)
	_multi(g, "ShelfLightStrips", _box(Vector3(width - 0.3, 0.02, 0.03)), _m.shelf_light, strip_xf, [], false)
	var prism := CylinderMesh.new()
	prism.top_radius = 0.5
	prism.bottom_radius = 0.5
	prism.height = 1.0
	prism.radial_segments = 6
	_multi(g, "CrystalArchives", prism, _m.crystal, crystal_xf, [], false)
	_add(g, "OuterWall", ring_sector(outer_radius, outer_radius + 0.4, _ceiling_y + 0.6, 0.0, TAU, 128), _m.stone_dark, _at(0, 0, 0))
	stats.shelf_units = units
	stats.books = book_xf.size()
	stats.crystals = crystal_xf.size()
	stats.shelf_lamps = lights
	stats.realistic_books = real


## One shelf of realistic books in a unit's frame (local +Z towards the hall): spines nearly flush
## with the board's front edge, sizes and bindings drawn per book or shared by a series, a book
## leaning into each gap, a few stacks lying flat, and the odd crystal archive. Appends to out.
func _fill_board(rng: RandomNumberGenerator, base: Transform3D, x0: float, x1: float, y: float, clear: float, out: Dictionary) -> void:
	var x := x0
	var run := 0  # books left in the current series
	var run_h := 0.0
	var run_w := 0.0
	var run_d := 0.0
	var run_binding := []
	var last := -1  # the last upright book, which leans into a following gap
	var last_right := 0.0
	var last_size := Vector3.ZERO
	var last_z := 0.0
	while x < x1 - 0.03:
		var z_front := 0.27 - rng.randf() * 0.012
		if run == 0:
			var roll := rng.randf()
			if roll < 0.04 and last >= 0:
				# A gap: the book before it tips over its foot until its head rests on the next book.
				var gap := rng.randf_range(0.04, 0.12)
				var a := -asin(minf(gap / last_size.y, 0.8))
				var tip := Basis(Vector3.BACK, a)
				var c := Vector3(last_right, y, 0) + tip * Vector3(-last_size.x * 0.5, last_size.y * 0.5, 0)
				c.z = last_z
				out.xf[last] = base * Transform3D(tip * Basis.from_scale(last_size), c)
				out.leaning += 1
				last = -1
				x += gap
				continue
			if roll < 0.065:
				# Two to five books lying flat, spines out, the longest at the bottom.
				var n := rng.randi_range(2, 5)
				var lens: Array[float] = []
				for k in n:
					lens.append(clear * rng.randf_range(0.5, 0.78))
				lens.sort()
				lens.reverse()
				if x + lens[0] > x1:
					continue
				var sy := y
				for k in n:
					var t := lens[k] * rng.randf_range(0.08, 0.15)
					if sy + t > y + clear - 0.02:
						break
					var d := minf(lens[k] * rng.randf_range(0.68, 0.8), 0.46)
					var bind := _binding(rng)
					var twist := Basis(Vector3.UP, rng.randf_range(-0.05, 0.05))
					var cx := x + lens[0] * 0.5 + rng.randf_range(-0.01, 0.01)
					out.xf.append(base * Transform3D(twist * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3(t, lens[k], d)),
						Vector3(cx, sy + t * 0.5, z_front - d * 0.5)))
					out.col.append(bind[0])
					out.cus.append(bind[1])
					sy += t
				out.lying += 1
				last = -1
				x += lens[0] + rng.randf_range(0.01, 0.03)
				continue
			if roll < 0.077 and x + 0.09 < x1:
				var ch := clear * rng.randf_range(0.6, 0.85)
				out.crystals.append(base * Transform3D(Basis.from_scale(Vector3(0.06, ch, 0.06)), Vector3(x + 0.04, y + ch * 0.5, 0.12)))
				last = -1
				x += 0.09
				continue
			if roll < 0.24:
				run = rng.randi_range(4, 9)
				run_h = clear * rng.randf_range(0.6, 0.9)
				run_w = run_h * rng.randf_range(0.1, 0.17)
				run_d = minf(run_h * rng.randf_range(0.68, 0.78), 0.46)
				run_binding = _binding(rng)
				out.series += 1
		var size: Vector3
		var col: Color
		var cus: Color
		if run > 0:
			run -= 1
			size = Vector3(run_w * rng.randf_range(0.92, 1.08), run_h, run_d)
			col = run_binding[0]
			cus = run_binding[1]
			# Same binding, own title and own wear.
			col.a = rng.randf()
			cus.a = rng.randf() * rng.randf()
		else:
			var bh := clear * rng.randf_range(0.55, 0.9)
			size = Vector3(bh * rng.randf_range(0.1, 0.2), bh, minf(bh * rng.randf_range(0.68, 0.8), 0.46))
			var bind := _binding(rng)
			col = bind[0]
			cus = bind[1]
		if x + size.x > x1:
			break
		last_z = z_front - size.z * 0.5
		out.xf.append(base * Transform3D(Basis.from_scale(size), Vector3(x + size.x * 0.5, y + size.y * 0.5, last_z)))
		out.col.append(col)
		out.cus.append(cus)
		last = out.xf.size() - 1
		last_right = x + size.x
		last_size = size
		x += size.x + rng.randf_range(0.002, 0.006)


## [colour, custom] for one book: COLOR = binding (sRGB) + title seed,
## INSTANCE_CUSTOM = style, raised bands / 8, gilt, wear (see assets/book_spines.gdshader).
static func _binding(rng: RandomNumberGenerator) -> Array:
	var kind := rng.randf()
	var col: Color
	var cus: Color
	if kind < 0.5:
		col = LEATHER[rng.randi() % LEATHER.size()]
		cus = Color(rng.randf_range(0.1, 0.4), rng.randi_range(3, 5) / 8.0, rng.randf_range(0.35, 1.0), 0.0)
	elif kind < 0.9:
		col = CLOTH[rng.randi() % CLOTH.size()]
		cus = Color(rng.randf_range(0.55, 0.85), 0.0, rng.randf(), 0.0)
	else:
		col = VELLUM[rng.randi() % VELLUM.size()]
		cus = Color(rng.randf_range(0.9, 1.0), 0.0, 0.0, 0.0)
	var f := rng.randf_range(0.82, 1.12)
	col = Color(col.r * f, col.g * f, col.b * f, rng.randf())
	cus.a = rng.randf() * rng.randf()
	return [col, cus]


## Unit hardback (1 x 1 x 1, spine towards +Z) for the Books MultiMeshes: two boards, a page block
## set back from the head, tail and fore-edge, and a rounded spine with its head and tail caps;
## 44 triangles. The faces only the back of the shelf would show (fore-edges, the inside of the
## spine) are left out. UV.x tells assets/book_spines.gdshader the part: 0 boards, 1 spine, 2 pages.
static func _book_mesh() -> ArrayMesh:
	const C := 0.1  # board thickness, fraction of the width
	const SP := 0.035  # spine rounding, fraction of the depth
	const E := 0.012  # squares: how far the boards overhang the page block
	const SEG := 6
	var z0 := 0.5 - SP
	var pw := 0.5 - C
	var py := 0.5 - E
	var pz := -0.5 + E
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_uv(Vector2(0, 0))
	for s: float in [-1.0, 1.0]:
		var xo := 0.5 * s
		var xi := pw * s
		_face(st, Vector3(xo, -0.5, -0.5), Vector3(xo, 0.5, -0.5), Vector3(xo, 0.5, z0), Vector3(xo, -0.5, z0), Vector3(s, 0, 0))
		_face(st, Vector3(xi, -0.5, -0.5), Vector3(xi, 0.5, -0.5), Vector3(xi, 0.5, z0), Vector3(xi, -0.5, z0), Vector3(-s, 0, 0))
		for e: float in [-1.0, 1.0]:
			_face(st, Vector3(xo, 0.5 * e, -0.5), Vector3(xi, 0.5 * e, -0.5), Vector3(xi, 0.5 * e, z0), Vector3(xo, 0.5 * e, z0), Vector3(0, e, 0))
	st.set_uv(Vector2(2, 0))
	for e: float in [-1.0, 1.0]:
		_face(st, Vector3(-pw, py * e, pz), Vector3(pw, py * e, pz), Vector3(pw, py * e, z0), Vector3(-pw, py * e, z0), Vector3(0, e, 0))
	st.set_uv(Vector2(1, 0))
	for i in SEG:
		var xa := -0.5 + float(i) / SEG
		var xb := -0.5 + float(i + 1) / SEG
		var za := 0.5 - SP * 4.0 * xa * xa
		var zb := 0.5 - SP * 4.0 * xb * xb
		var na := Vector3(8.0 * SP * xa, 0, 1).normalized()
		var nb := Vector3(8.0 * SP * xb, 0, 1).normalized()
		_poly(st, [Vector3(xa, -0.5, za), Vector3(xb, -0.5, zb), Vector3(xb, 0.5, zb), Vector3(xa, 0.5, za)], [na, nb, nb, na])
		for e: float in [-1.0, 1.0]:
			var up := Vector3(0, e, 0)
			_poly(st, [Vector3(0, 0.5 * e, z0), Vector3(xa, 0.5 * e, za), Vector3(xb, 0.5 * e, zb)], [up, up, up])
	return st.commit()


## Cheaper stand-ins for scripts/quality.gd's level 3, on a weak GPU. "book": the hardback as a box,
## 10 triangles instead of 44 (the spine, the two boards, head and tail; the same UV.x parts), so the
## 38,758 shelved books go from 1.7 million triangles to 0.39. "baluster": turned on 6 sides from 9
## points of the profile, 96 triangles instead of 380.
func low_poly(kind: String) -> Mesh:
	if kind == "baluster":
		return _lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.036, 0), Vector2(0.036, 0.05),
			Vector2(0.019, 0.12), Vector2(0.041, 0.42), Vector2(0.016, 0.66), Vector2(0.029, 0.79),
			Vector2(0.031, 0.9), Vector2(0, 0.9)]), 6)
	if kind != "book":
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_uv(Vector2(1, 0))
	_face(st, Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5), Vector3(0, 0, 1))
	st.set_uv(Vector2(0, 0))
	for s: float in [-1.0, 1.0]:
		_face(st, Vector3(0.5 * s, -0.5, -0.5), Vector3(0.5 * s, 0.5, -0.5), Vector3(0.5 * s, 0.5, 0.5), Vector3(0.5 * s, -0.5, 0.5), Vector3(s, 0, 0))
	st.set_uv(Vector2(2, 0))
	for e: float in [-1.0, 1.0]:
		_face(st, Vector3(-0.5, 0.5 * e, -0.5), Vector3(0.5, 0.5 * e, -0.5), Vector3(0.5, 0.5 * e, 0.5), Vector3(-0.5, 0.5 * e, 0.5), Vector3(0, e, 0))
	return st.commit()


## The course shelves take the bays from the one left of the far wall onwards (bay 7 of 16), so the
## areas read left to right from the entrance. They draw nothing from the rng streams.
## Returns the language the course shelves chose, for the statue's inscription.
func _build_courses(root: Node3D) -> String:
	var lib: Node3D = load("res://scripts/course_library.gd").new()
	lib.name = "CourseShelves"
	lib.configure(_ground_shelves.radius, bay_count, _ground_shelves.width, _ground_shelves.row_pitch, bay_count * 7 / 16, COURSE_ROW, self)
	root.add_child(lib)
	stats.course_areas = lib.stats.get("areas", 0)
	stats.course_volumes = lib.stats.get("volumes", 0)
	return str(lib.get("lang"))


func _statue_on() -> bool:
	return seldon_statue and pier_ornament != null and ResourceLoader.exists(STATUE_SCRIPT_PATH)


func _gilding_on() -> bool:
	return gilding and pier_ornament != null


## In the hall on the last bay's axis, 3.8 m in from the piers, facing the centre. That bay's
## data-rain beam is left out (_build_rain), so it does not fall through the statue.
func _statue_bay() -> int:
	return bay_count - 1 if _statue_on() else -1


func _daneel_on() -> bool:
	return daneel_statue and pier_ornament != null and ResourceLoader.exists(DANEEL_SCRIPT_PATH)


## Across the hall from Seldon's bay, mirrored in the start view's axis: bay_count - 1 mirrors to
## bay_count / 2, left of the box as Seldon stands right of it. Its rain beam is left out too.
func _daneel_bay() -> int:
	return bay_count / 2 if _daneel_on() else -1


func _build_daneel(root: Node3D, lang: String) -> void:
	var statue: Node3D = load(DANEEL_SCRIPT_PATH).new()
	statue.name = "DaneelStatue"
	statue.configure(self, daneel_reveal)
	statue.transform = _radial(TAU * (_daneel_bay() + 0.5) / bay_count, colonnade_radius - 3.8, 0.0)
	root.add_child(statue)
	statue.set_lang(lang)
	stats.daneel = 1 if statue.stats.get("figure", false) else 0
	stats.daneel_faces = statue.stats.get("figure_faces", 0)
	stats.daneel_reveal = 1 if statue.stats.get("reveal", false) else 0


func _radiant_on() -> bool:
	return prime_radiant and ResourceLoader.exists(RADIANT_SCRIPT_PATH)


## Style "c"'s artifact is smaller: the equations around it are the spectacle, not the glass.
func _radiant_height() -> float:
	return 1.3 if radiant_style == "c" else RADIANT_HEIGHT


func _build_radiant(root: Node3D) -> void:
	var radiant: Node3D = load(RADIANT_SCRIPT_PATH).new()
	radiant.name = "PrimeRadiant"
	radiant.configure(self, radiant_particles, _radiant_height(), radiant_style)
	radiant.position = Vector3(0, RADIANT_Y, 0)
	root.add_child(radiant)
	stats.radiant = 1 if radiant.stats.get("crystal", false) else 0
	stats.radiant_tris = radiant.stats.get("tris", 0)
	stats.radiant_particles = radiant.stats.get("particles", 0)


func _build_statue(root: Node3D, lang: String) -> void:
	var statue: Node3D = load(STATUE_SCRIPT_PATH).new()
	statue.name = "SeldonStatue"
	statue.configure(self)
	statue.transform = _radial(TAU * (_statue_bay() + 0.5) / bay_count, colonnade_radius - 3.8, 0.0)
	root.add_child(statue)
	statue.set_lang(lang)
	# The reader's language picks (scripts/course_library.gd's selector) reach the inscription too.
	var lib := root.get_node_or_null("CourseShelves")
	if lib != null and lib.has_signal("lang_changed"):
		lib.connect("lang_changed", statue.set_lang)
	stats.statue = 1 if statue.stats.get("figure", false) else 0
	stats.statue_faces = statue.stats.get("figure_faces", 0)
	stats.statue_lang = statue.stats.get("lang", "")


## The lift's shaft (scripts/lift.gd) on the floor plane: the sector a ± half between the radii r0
## and r1. Empty without the lift.
func _lift_shaft() -> Dictionary:
	if Engine.is_editor_hint() or not ResourceLoader.exists(LIFT_SCRIPT_PATH):
		return {}
	var k: Dictionary = load(LIFT_SCRIPT_PATH).get_script_constant_map()
	var axis: float = k.AXIS_R
	return {"a": TAU * (int(k.LIFT_BAY) + 0.5) / bay_count, "half": asin(1.12 / axis), "r0": axis - 1.12, "r1": axis + 1.12}


func _build_ceiling(g: Node3D, rng: RandomNumberGenerator) -> void:
	var slab_mat: Material = _m.get("stone_vault", _m.stone_dark)
	var shaft := _lift_shaft()
	if shaft.is_empty() or not bool(load(LIFT_SCRIPT_PATH).call("goes_to_roof")):
		_add(g, "CeilingSlab", ring_sector(oculus_radius, outer_radius + 0.6, 0.6, 0.0, TAU, 128), slab_mat, _at(0, _ceiling_y, 0))
	else:
		# The lift goes on to the roof: the slab is cut round its shaft, as the walkways are, and the
		# lift lines the cut with a bronze throat (scripts/lift.gd, _build_kiosk).
		var a0: float = shaft.a - shaft.half
		var a1: float = shaft.a + shaft.half
		_add(g, "CeilingSlab", ring_sector(oculus_radius, outer_radius + 0.6, 0.6, a1, a0 + TAU, 126), slab_mat, _at(0, _ceiling_y, 0))
		_add(g, "CeilingSlabIn", ring_sector(oculus_radius, shaft.r0, 0.6, a0, a1, 2), slab_mat, _at(0, _ceiling_y, 0))
		_add(g, "CeilingSlabOut", ring_sector(shaft.r1, outer_radius + 0.6, 0.6, a0, a1, 2), slab_mat, _at(0, _ceiling_y, 0))
		stats.roof_cut = true
	var drum_y := _ceiling_y + 0.6
	_add(g, "OculusDrum", ring_sector(oculus_radius, oculus_radius + 0.5, 3.5, 0.0, TAU, 128), _m.get("stone_courses", _m.stone), _at(0, drum_y, 0))
	for k in 2:
		var y := drum_y + 0.4 + k * 2.6
		if _gilding_on():
			_add(g, "DrumBand%d" % k, _bead_ring(oculus_radius, 0.03), _m.gold, _at(0, y + 0.03, 0), false)
		else:
			_add(g, "DrumBand%d" % k, ring_sector(oculus_radius - 0.02, oculus_radius, 0.06, 0.0, TAU, 128), _m.silver, _at(0, y, 0), false)
	stats.gilt_ribs = 0
	if _gilding_on():
		# Gilt ribs under the coffered ceiling, one over each pier on a joint of the coffers, and a
		# gilt ring round the oculus: a half-round between two fillets, hanging from the slab.
		var span := outer_radius + 0.6 - oculus_radius - 0.1
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		revolve(st, profile_bead(Vector2(oculus_radius + 0.07, _ceiling_y), 0.06, Vector2(0, -1), 12), 128)
		var rib := [[Vector2(-0.07, 0.0), Vector2(-1, 0)], [Vector2(-0.07, -0.015), Vector2(-1, 0)],
			[Vector2(-0.07, -0.015), Vector2(0, -1)], [Vector2(-0.05, -0.015), Vector2(0, -1)]]
		profile_arc(rib, Vector2(0, -0.015), 0.05, 0.05, PI, TAU, 12)
		rib += [[Vector2(0.05, -0.015), Vector2(0, -1)], [Vector2(0.07, -0.015), Vector2(0, -1)],
			[Vector2(0.07, -0.015), Vector2(1, 0)], [Vector2(0.07, 0.0), Vector2(1, 0)]]
		for i in bay_count:
			extrude(st, rib, span, Vector2(0, -0.015), _radial(TAU * i / bay_count, oculus_radius + 0.05 + span * 0.5, _ceiling_y))
		_add(g, "GiltRibs", st.commit(), _m.gold, Transform3D(), false)
		stats.gilt_ribs = bay_count
	if _night_sky_on():
		_build_sky(g)
	else:
		_add(g, "SkyCap", ring_sector(0.0, oculus_radius + 0.5, 0.3, 0.0, TAU, 96), _m.sky, _at(0, _dome_y, 0))
		stats.sky = "cap"
	_build_windows(g, drum_y)

	var star_xf: Array[Transform3D] = []
	for i in 220:
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * oculus_radius * 0.98
		star_xf.append(Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(0.4, 1.4)), Vector3(cos(a) * rr, _dome_y - 0.02, sin(a) * rr)))
	var star := SphereMesh.new()
	star.radius = 0.04
	star.height = 0.08
	star.radial_segments = 8
	star.rings = 4
	# Drawn only on the painted cap; their random draws happen either way, for the orrery's sake.
	if not _night_sky_on():
		_multi(g, "Stars", star, _m.star, star_xf, [], false)

	var lamp_xf: Array[Transform3D] = []
	for i in 32:
		var a := TAU * i / 32.0
		lamp_xf.append(_at(cos(a) * (oculus_radius + 0.25), _ceiling_y - 0.06, sin(a) * (oculus_radius + 0.25)))
	var lamp := SphereMesh.new()
	lamp.radius = 0.08
	lamp.height = 0.16
	# 16 cm across, under the dome's rim: about 8 pixels on a 1440p screen, where 12 sides are as
	# round as the default 64, for 168 triangles each instead of 4,224 (artpass/perf/).
	lamp.radial_segments = 12
	lamp.rings = 6
	_multi(g, "RimLamps", lamp, _m.planet, lamp_xf, [], false)

	# Orrery: tilted orbits, each carrying one glowing body, turning slowly at runtime.
	var orrery := _group(g, "Orrery")
	for k in orrery_rings:
		var radius := 2.2 + k * 1.5
		var pivot := Node3D.new()
		pivot.name = "Orbit%d" % k
		pivot.position = Vector3(0, _dome_y - 0.9 - k * 0.35, 0)
		pivot.rotation = Vector3(rng.randf_range(-0.12, 0.12), rng.randf() * TAU, rng.randf_range(-0.12, 0.12))
		orrery.add_child(pivot)
		var ring := TorusMesh.new()
		ring.inner_radius = radius - 0.03
		ring.outer_radius = radius + 0.03
		ring.rings = 128
		ring.ring_segments = 8
		_add(pivot, "Ring", ring, _m.orbit if orrery_glow else _m.orbit_brass, Transform3D(), false)
		var body := SphereMesh.new()
		body.radius = 0.16 + 0.06 * (k % 3)
		body.height = body.radius * 2.0
		var body_mat: Material = _m.planet if orrery_glow else _m.body_ivory
		_add(pivot, "Body", body, _m.green_glow if k == 2 else body_mat, _at(radius, 0, 0), false)
		_orrery_pivots.append(pivot)
	for k in 4:
		var rr := 0.3 + k * 0.28
		_add(orrery, "Rosette%d" % k, ring_sector(rr, rr + 0.04, 0.02, 0.0, TAU, 64), _m.orbit if orrery_glow else _m.orbit_brass, _at(0, _dome_y - 0.12, 0), false)
	stats.ceiling_rings = orrery_rings + 4 + 2
	stats.stars = star_xf.size()


func _night_sky_on() -> bool:
	return night_sky and ResourceLoader.exists(NIGHT_SKY_SHADER_PATH)


## Trantor's night sky at infinity over the oculus (assets/night_sky.gdshader): a sphere that its
## shader keeps round the camera, lit by nothing and casting nothing, so the hall's light,
## reflections and shadows stay as they were. Trantor lies near the Galaxy's centre: the core stands
## where the oculus light (_build_lights) comes from, and the Galaxy's plane passes near the zenith,
## across the oculus.
func _build_sky(g: Node3D) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	var mat := ShaderMaterial.new()
	mat.shader = load(NIGHT_SKY_SHADER_PATH)
	# The oculus light's spot: from inside the drum rim, aimed at 0.3 of the way across the floor.
	var az := deg_to_rad(moon_azimuth)
	var rim := Vector3(cos(az), 0.0, sin(az)) * (oculus_radius - 0.5)
	var core := Vector3(rim.x * 1.3, _ceiling_y + 1.0, rim.z * 1.3).normalized()
	mat.set_shader_parameter("core_dir", core)
	mat.set_shader_parameter("galaxy_normal", core.cross(Vector3(0.25, 1.0, 0.1).normalized()).normalized())
	stats.sky_photo = 0
	if ResourceLoader.exists(MILKY_WAY_PATH):
		mat.set_shader_parameter("milky_way", load(MILKY_WAY_PATH))
		mat.set_shader_parameter("photo_energy", 0.45)
		stats.sky_photo = 1
	stats.sky_cap = 0
	if ResourceLoader.exists(CORE_CAP_PATH):
		var cap: Texture2D = load(CORE_CAP_PATH)
		mat.set_shader_parameter("core_cap", cap)
		mat.set_shader_parameter("cap_energy", core_cap_energy)
		mat.set_shader_parameter("cap_width", float(cap.get_width()))
		mat.set_shader_parameter("core_zoom", 2.0)
		stats.sky_cap = 1
	var sky := MeshInstance3D.new()
	sky.name = "NightSky"
	sky.mesh = sphere
	sky.material_override = mat
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Its vertices follow the camera: a box round the origin would cull it.
	sky.custom_aabb = AABB(Vector3(-1000.0, -1000.0, -1000.0), Vector3(2000.0, 2000.0, 2000.0))
	g.add_child(sky)
	stats.sky = "night"


## Stained-glass lancets on the drum's inner face, in front of its two bands, with the three
## panels in turn. Each throws a narrow tinted spot down into the fog.
func _build_windows(g: Node3D, drum_y: float) -> void:
	stats.stained_glass = 0
	if stained_glass_windows <= 0 or pier_ornament == null or not ResourceLoader.exists(GLASS_SHADER_PATH):
		return
	var w := 1.3
	var h := w * 2.4
	var cy := drum_y + 1.75
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	var mats := []
	for k in GLASS_PANELS.size():
		if not ResourceLoader.exists(GLASS_PANELS[k][0]):
			return
		var m := ShaderMaterial.new()
		m.shader = load(GLASS_SHADER_PATH)
		m.set_shader_parameter("glass", load(GLASS_PANELS[k][0]))
		m.set_shader_parameter("energy", glass_energy)
		m.set_shader_parameter("aspect", h / w)
		m.set_shader_parameter("seed", float(k))
		mats.append(m)
	var windows := _group(g, "StainedGlass")
	for i in stained_glass_windows:
		var a := TAU * (i + 0.5) / stained_glass_windows
		var k := i % GLASS_PANELS.size()
		var base := _radial(a, oculus_radius - 0.035, cy)
		_add(windows, "Window%02d" % i, quad, mats[k], base, false)
		# Compatibility has no volumetric fog to show the shafts in, and 24 more lights would crowd
		# its per-object and per-frame light limits.
		if glass_light_energy <= 0.0 or _compatibility():
			continue
		var spot := SpotLight3D.new()
		spot.name = "WindowLight%02d" % i
		# From just inside the glass, pointing inwards and steeply down towards the floor.
		var from := Vector3(cos(a) * (oculus_radius - 0.3), cy, sin(a) * (oculus_radius - 0.3))
		var to := Vector3(cos(a) * 3.5, 0.0, sin(a) * 3.5)
		spot.transform = Transform3D(Basis(), from).looking_at(to, Vector3.UP)
		spot.light_color = GLASS_PANELS[k][1]
		spot.light_energy = glass_light_energy
		spot.light_specular = 0.1
		spot.spot_range = 28.0
		spot.spot_angle = 9.0
		spot.spot_attenuation = 0.6
		spot.light_volumetric_fog_energy = 1.2
		windows.add_child(spot)
	stats.stained_glass = stained_glass_windows


func _build_rain(g: Node3D, rng: RandomNumberGenerator) -> void:
	var beam := CylinderMesh.new()
	beam.top_radius = 0.02
	beam.bottom_radius = 0.02
	beam.height = 1.0
	beam.radial_segments = 6
	beam.rings = 1
	beam.cap_top = false
	beam.cap_bottom = false
	var beam_xf: Array[Transform3D] = []
	var core_xf: Array[Transform3D] = []
	var spot_xf: Array[Transform3D] = []
	var top := _ceiling_y - 0.1
	var r0 := colonnade_radius - rain_inset
	for i in bay_count:
		for k in beams_per_bay:
			var a := TAU * (i + 0.5) / bay_count + rng.randf_range(-0.12, 0.12)
			var rr := r0 + rng.randf_range(-0.6, 0.4)
			var p := Vector3(cos(a) * rr, 0.0, sin(a) * rr)
			var t := rng.randf_range(top - 3.0, top)
			var b := 0.0 if rng.randf() < 0.7 else rng.randf_range(0.5, 2.0)
			if i == _statue_bay():
				continue  # drawn anyway, so the other beams keep their places
			if i == _daneel_bay():
				rng.randf()  # its drop's phase too: the beams after it keep their places
				continue
			beam_xf.append(Transform3D(Basis.from_scale(Vector3(1, t - b, 1)), p + Vector3(0, (t + b) * 0.5, 0)))
			_drop_data.append([p.x, p.z, t, b, rng.randf()])
			if b == 0.0:
				spot_xf.append(_at(p.x, 0.004, p.z))
	# Central bundle, from the sky cap down onto the steel box, or, with the Prime Radiant, onto
	# the top of its crystal: a narrower bundle that it seems to draw in, and clear air below it.
	var cube_top := 4.75
	var bundle := 1.1
	# Compositions (radiant_style): "a" keeps one central beam in three and "c" one in four, so the
	# shaft no longer outshines the Radiant; "b" moves the beams onto a ring around the crystal,
	# down to the box. Every beam still draws its random numbers, so the rest keep their places.
	var keep := 1
	var ring := 0.0
	var core_mat: Material = _m.core_beam
	if _radiant_on():
		cube_top = RADIANT_Y + _radiant_height() * 0.48
		bundle = _radiant_height() * 0.2
		match radiant_style:
			"a":
				keep = 3
				core_mat = _dimmed(_m.core_beam, 0.7)
			"b":
				# Half the beams at half their energy: all 36 at full made a wall of light that
				# hid the crystal (artpass/radiant/s3).
				ring = _radiant_height() * 0.5
				cube_top = 4.75
				keep = 2
				core_mat = _dimmed(_m.core_beam, 0.5)
			"c":
				# Nine beams, ending where the projection's top shell begins: the rain seems to
				# turn into the equations, and the artifact floats clear of it.
				keep = 4
				bundle = 0.45  # nine beams within 0.26 m made one white bar
				core_mat = _dimmed(_m.core_beam, 0.5)
				cube_top = RADIANT_Y + 2.6
	for k in central_beams:
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * bundle
		if ring > 0.0:
			rr = ring + rr / bundle * 0.35
		var p := Vector3(cos(a) * rr, 0.0, sin(a) * rr)
		var t := _dome_y - 0.05
		var phase := rng.randf()
		if k % keep != 0:
			continue
		core_xf.append(Transform3D(Basis.from_scale(Vector3(1, t - cube_top, 1)), p + Vector3(0, (t + cube_top) * 0.5, 0)))
		_drop_data.append([p.x, p.z, t, cube_top, phase])
	_multi(g, "RainBeams", beam, _m.beam, beam_xf, [], false)
	_multi(g, "CoreBeams", beam, core_mat, core_xf, [], false)
	var splash := CylinderMesh.new()
	splash.top_radius = 0.14
	splash.bottom_radius = 0.14
	splash.height = 0.008
	_multi(g, "FloorSplashes", splash, _m.green_glow, spot_xf, [], false)

	var drop := CylinderMesh.new()
	drop.top_radius = 0.035
	drop.bottom_radius = 0.035
	drop.height = 0.7
	drop.radial_segments = 6
	_drops = MultiMesh.new()
	_drops.transform_format = MultiMesh.TRANSFORM_3D
	_drops.mesh = drop
	_drops.instance_count = _drop_data.size() * 2
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "FallingDrops"
	mmi.multimesh = _drops
	mmi.material_override = _m.drop
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(mmi)
	_update_drops(0.0)
	stats.beams = beam_xf.size() + core_xf.size()
	stats.drops = _drops.instance_count


func _build_lights(g: Node3D) -> void:
	var fill := OmniLight3D.new()
	fill.name = "MoonFill"
	fill.position = Vector3(0, 16.0, 0)
	fill.light_color = Color(0.45, 0.6, 1.0)
	fill.light_energy = 2.0
	fill.omni_range = 32.0
	fill.light_volumetric_fog_energy = 0.5
	g.add_child(fill)
	var shaft := SpotLight3D.new()
	shaft.name = "OculusShaft"
	shaft.position = Vector3(0, _dome_y - 0.2, 0)
	shaft.rotation = Vector3(-PI * 0.5, 0, 0)
	shaft.light_color = Color(0.35, 1.0, 0.6)
	shaft.light_energy = 14.0
	shaft.spot_range = 26.0
	shaft.spot_angle = 5.5
	shaft.light_volumetric_fog_energy = 4.0
	if _radiant_on() and radiant_style in ["a", "c"]:
		shaft.light_volumetric_fog_energy = 1.5  # Forward+ only: the fog glow went with the beams
	g.add_child(shaft)
	stats.lights = 2 + int(stats.get("shelf_lamps", 0))
	stats.moon = 0
	if moon_shadows and moon_energy > 0.0:
		# Inside the drum, just above the ceiling and 0.5 m in from the oculus rim, aimed a little
		# past the centre: 24 degrees off the vertical at the box, whose shadow reaches 2 m out.
		var az := deg_to_rad(moon_azimuth)
		var from := Vector3(cos(az), 0.0, sin(az)) * (oculus_radius - 0.5) + Vector3(0.0, _ceiling_y + 1.0, 0.0)
		var moon := SpotLight3D.new()
		moon.name = "OculusMoon"
		moon.transform = Transform3D(Basis(), from).looking_at(Vector3(-from.x, 0.0, -from.z) * 0.3, Vector3.UP)
		moon.light_color = Color(0.72, 0.8, 1.0)
		moon.light_energy = moon_energy
		# Full specular put a hot moon on the polished floor in front of the box.
		moon.light_specular = 0.3
		moon.spot_range = 40.0
		moon.spot_angle = 55.0
		moon.spot_angle_attenuation = 0.5
		moon.shadow_enabled = true
		# Only the floor and the steel shell (layer 2) and the statue (layer 4) receive it; the
		# piers and shelves still cast their shadows onto the floor. Lighting the walls too cost the
		# web build up to 1.7 ms more a frame full screen, for the extra pass over the shelves.
		moon.light_cull_mask = 2 | 8
		moon.light_volumetric_fog_energy = 0.5
		g.add_child(moon)
		stats.moon = 1
		stats.lights += 1
	stats.reflection_probe = 0
	if use_reflection_probe:
		var probe := ReflectionProbe.new()
		probe.name = "HallProbe"
		probe.position = Vector3(0, 10.5, 0)
		probe.size = Vector3(outer_radius * 2.0 + 1.0, 25.0, outer_radius * 2.0 + 1.0)
		probe.origin_offset = Vector3(0, -8.5, 0)  # captured from 2 m above the floor
		probe.box_projection = true
		probe.interior = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.intensity = 0.35
		probe.reflection_mask = 1  # the floor and the Blender steel shell are on layer 2
		# The captured hall is full of warm emitters; as ambient light it floods the scene
		# orange (art pass attempt 1). Keep the environment's own ambient inside the box.
		probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
		probe.ambient_color = Color(0.32, 0.42, 0.62)
		probe.ambient_color_energy = 0.45
		g.add_child(probe)
		stats.reflection_probe = 1


func _update_drops(t: float) -> void:
	if _drops == null:
		return
	var idx := 0
	for d in _drop_data:
		var span: float = d[2] - d[3]
		for j in 2:
			var f := fposmod(d[4] + j * 0.5 + t * rain_speed / maxf(span, 0.1), 1.0)
			_drops.set_instance_transform(idx, _at(d[0], d[2] - f * span, d[1]))
			idx += 1


# --- Helpers ------------------------------------------------------------------

func _make_materials() -> void:
	var books := StandardMaterial3D.new()
	books.vertex_color_use_as_albedo = true
	books.roughness = 0.8
	_m = {
		"floor": _mat(Color(0.045, 0.055, 0.075), 0.2, 0.3),
		"stone": _mat(Color(0.1, 0.12, 0.155), 0.85),
		"stone_dark": _mat(Color(0.06, 0.075, 0.1), 0.9),
		"silver": _mat(Color(0.75, 0.8, 0.88), 0.3, 1.0, Color(0.55, 0.68, 0.9), 0.9),
		"silver_dim": _mat(Color(0.6, 0.65, 0.72), 0.35, 1.0, Color(0.4, 0.5, 0.7), 0.3),
		"gold": _mat(Color(0.85, 0.65, 0.32), 0.35, 1.0, Color(1.0, 0.68, 0.3), 1.4),
		"wood": _mat(Color(0.16, 0.1, 0.065), 0.75),
		"bronze": _mat(Color(0.24, 0.2, 0.15), 0.42, 1.0),
		"walnut": _mat(Color(0.2, 0.11, 0.06), 0.32),
		"books": books,
		"shelf_light": _mat(Color(1.0, 0.8, 0.55), 0.5, 0.0, Color(1.0, 0.7, 0.4), 3.0),
		"crystal": _mat(Color(0.4, 0.9, 1.0), 0.1, 0.0, Color(0.35, 0.95, 1.0), 3.5),
		"sky": _mat(Color(0.01, 0.02, 0.05), 1.0, 0.0, Color(0.02, 0.06, 0.16), 1.0),
		"star": _mat(Color.WHITE, 1.0, 0.0, Color(0.9, 0.95, 1.0), 5.0),
		"orbit": _mat(Color(0.85, 0.9, 1.0), 0.3, 0.6, Color(0.8, 0.88, 1.0), 2.2),
		# Brass that catches a little lamplight, and ivory: the orrery against the night sky.
		"orbit_brass": _mat(Color(0.72, 0.55, 0.3), 0.35, 1.0, Color(0.55, 0.38, 0.16), 0.35),
		"body_ivory": _mat(Color(0.86, 0.82, 0.72), 0.5, 0.0, Color(0.9, 0.82, 0.66), 0.6),
		"planet": _mat(Color(1.0, 0.92, 0.8), 0.4, 0.0, Color(1.0, 0.88, 0.7), 5.0),
		"green_glow": _mat(Color(0.2, 0.9, 0.5), 0.5, 0.0, Color(0.3, 1.0, 0.55), 3.0),
		"beam": _glow(Color(0.3, 1.0, 0.55), beam_energy),
		"core_beam": _glow(Color(0.35, 1.0, 0.6), 2.4),
		"drop": _glow(Color(0.5, 1.0, 0.7), drop_energy),
	}
	if realistic_books and ResourceLoader.exists(BOOK_SHADER_PATH):
		var bindings := ShaderMaterial.new()
		bindings.shader = load(BOOK_SHADER_PATH)
		if ResourceLoader.exists(BOOK_GRAIN_PATH):
			bindings.set_shader_parameter("grain_map", load(BOOK_GRAIN_PATH))
		else:
			bindings.set_shader_parameter("grain_strength", 0.0)
		_m.book_bindings = bindings
	stats.marble_surfaces = 0
	if use_marble and pier_ornament and ResourceLoader.exists(MARBLE_PATH):
		var marble: Texture2D = load(MARBLE_PATH)
		# Polished dielectric floor: veins and cloudy variation instead of a flat black disc.
		_marble(_m.floor, marble, Color(0.6, 0.66, 0.76), 3.5)
		_m.floor.metallic = 0.0
		_m.floor.roughness = 0.22
		_marble(_m.stone, marble, Color(0.5, 0.55, 0.64), 2.5)
		_marble(_m.stone_dark, marble, Color(0.3, 0.33, 0.4), 2.5)
		stats.marble_surfaces = 3
		if stone_relief and ResourceLoader.exists(STONE_SHADER_PATH) and ResourceLoader.exists(STONE_RELIEF_PATH):
			var relief: Texture2D = load(STONE_RELIEF_PATH)
			var light := Color(0.5, 0.55, 0.64)
			var dark := Color(0.3, 0.33, 0.4)
			_m.stone_piers = _stone(marble, relief, light, 1, {"course": 0.62, "block": 0.7, "roughness": 0.8})
			_m.stone_blocks = _stone(marble, relief, dark, 0, {"roughness": 0.85})
			_m.stone_arches = _stone(marble, relief, light, 2, {"sectors": 26.0, "course": 50.0, "roughness": 0.8})
			_m.stone_courses = _stone(marble, relief, light, 3, {"course": 0.55, "sectors": 96.0, "roughness": 0.8})
			_m.stone_vault = _stone(marble, relief, dark, 2, {"sectors": 64.0, "course": (outer_radius - oculus_radius) / 6.0,
				"radial_offset": oculus_radius, "coffer_depth": 0.09, "coffer_rib": 0.16, "roughness": 0.85})
			stats.stone_relief_materials = 5
		# Metal inlays, rails and bands read as metal catching light, not as neon lines.
		_m.silver.emission_energy_multiplier = 0.3
		_m.gold.emission_energy_multiplier = 0.6
	if near_beam_fade > 0.0:
		for key in ["beam", "core_beam", "drop"]:
			var m: StandardMaterial3D = _m[key]
			m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
			m.distance_fade_min_distance = near_beam_fade * 0.3
			m.distance_fade_max_distance = near_beam_fade
	# The Compatibility renderer (the web build) has no SDFGI, SSIL or SSR. There a fully metallic
	# balustrade has nothing to reflect and goes black, and the books miss the warm light the shelf
	# strips bounce onto them. Stand-ins, set by eye against Forward+ (artpass/web/NOTES.md).
	stats.compatibility_standins = _compatibility()
	if _compatibility():
		_m.bronze.albedo_color = Color(0.5, 0.37, 0.21)
		_m.bronze.metallic = 0.3
		_m.walnut.albedo_color = Color(0.36, 0.21, 0.11)
		if _m.has("book_bindings"):
			_m.book_bindings.set_shader_parameter("bounce_fill", Vector3(1.0, 0.7, 0.4) * 0.3)
	# The paving draws its own gilt lines from the flat gold's settings; everything else takes the
	# metal. Under Forward+, SSR and SDFGI already give the leaf something to reflect.
	_m.gold_flat = _m.gold
	stats.gilt_metal = 0
	if gilt_metal and ResourceLoader.exists(GILT_SHADER_PATH):
		var gilt := ShaderMaterial.new()
		gilt.shader = load(GILT_SHADER_PATH)
		gilt.set_shader_parameter("linear_output", not _compatibility())
		gilt.set_shader_parameter("output_energy", 1.0 if _compatibility() else 0.7)
		# Under Forward+ the lights' own highlights on the round mouldings bloomed into suns at the
		# burnish the web build was set at; a little less polish keeps the eggs and darts drawn
		# (artpass/gilt/gilt_probe.gd, 0.1 / 0.22 / 0.32).
		if not _compatibility():
			gilt.set_shader_parameter("roughness_base", 0.22)
		_hall_params(gilt)
		_m.gold = gilt
		stats.gilt_metal = 1


## The page's supersampling factor (artpass/aa/head_include.html), which it may lower once it has
## timed a few frames: the 2D interface is scaled by the same factor, so the HUD keeps its size.
func _web_ss() -> void:
	var ss := maxf(0.5, float(str(JavaScriptBridge.eval("window.__obsSS || 1", true))))
	if not is_equal_approx(get_window().content_scale_factor, ss):
		get_window().content_scale_factor = ss
	stats.web_ss = ss
	# MSAA, which the page picks and may step down: under the Compatibility renderer FXAA and
	# SMAA leave every pixel as it was (artpass/motion/fxaacheck.gd), so it is the only AA there.
	var m := int(str(JavaScriptBridge.eval("window.__obsMSAA || 0", true)))
	var want := Viewport.MSAA_4X if m >= 4 else (Viewport.MSAA_2X if m >= 2 else Viewport.MSAA_DISABLED)
	if get_viewport().msaa_3d != want:
		get_viewport().msaa_3d = want
	stats.web_msaa = m


## The hall's dimensions, for the materials that reflect it (assets/hall_env.gdshaderinc): the
## shelves' front, their levels and lamp strips, the ceiling and the oculus (_build_shelves,
## _build_ceiling). prime_radiant.gd calls it too.
func _hall_params(mat: ShaderMaterial) -> void:
	var r := outer_radius - 0.55
	var levels := Vector3(0.0, 6.2, 12.6)
	for k in mini(gallery_levels.size(), 2):
		levels[k + 1] = gallery_levels[k]
	var h := (gallery_levels[0] - 0.6) if gallery_levels.size() > 0 else column_height - 0.9
	mat.set_shader_parameter("wall_radius", r - 0.31)
	mat.set_shader_parameter("wall_top", column_height - 0.9)
	mat.set_shader_parameter("ceiling_y", column_height + 1.5)
	mat.set_shader_parameter("oculus_radius", oculus_radius)
	mat.set_shader_parameter("level_y", levels)
	mat.set_shader_parameter("strip_pitch", 2.0 * h / maxi(2, roundi(h / shelf_pitch)))
	mat.set_shader_parameter("bay_count", float(bay_count))
	mat.set_shader_parameter("unit_frac", 1.0 - 0.3 / (2.0 * r * sin(PI / bay_count)))


static func _compatibility() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


static func _stone(marble: Texture2D, relief: Texture2D, tint: Color, pattern: int, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(STONE_SHADER_PATH)
	m.set_shader_parameter("marble", marble)
	m.set_shader_parameter("relief", relief)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("pattern", pattern)
	for key in params:
		m.set_shader_parameter(key, params[key])
	return m


static func _marble(m: StandardMaterial3D, tex: Texture2D, tint: Color, tile_m: float) -> void:
	m.albedo_texture = tex
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile_m
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


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


## Additive emissive material for light that falls through the air.
## A copy of a glow material at a fraction of its energy.
static func _dimmed(m: StandardMaterial3D, k: float) -> StandardMaterial3D:
	var d := m.duplicate() as StandardMaterial3D
	d.emission_energy_multiplier = m.emission_energy_multiplier * k
	return d


static func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0, 0, 0, 1)
	m.metallic_specular = 0.0
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_receive_shadows = true
	return m


## The ornament's pieces as gilt MultiMeshes, one per kind present: eggs and darts of the given
## radii (x along the moulding, y up it, z out of it), beads and reels of an astragal's.
func _gilt_ornament(parent: Node, prefix: String, pieces: Dictionary, egg: Vector3, dart: Vector3) -> void:
	var meshes := {
		"eggs": _ellipsoid(egg, 8, 5),
		"darts": _ellipsoid(dart, 5, 3),
		"beads": _ellipsoid(Vector3(0.02, 0.014, 0.014), 8, 5),
		"reels": _ellipsoid(Vector3(0.005, 0.017, 0.017), 8, 3),
	}
	for kind in pieces:
		if not (pieces[kind] as Array).is_empty():
			_multi(parent, "Gilt%s%s" % [prefix, String(kind).capitalize()], meshes[kind], _m.gold, pieces[kind], [], false)
			stats.gilt_ornaments = int(stats.get("gilt_ornaments", 0)) + (pieces[kind] as Array).size()


func _group(parent: Node, node_name: String) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	parent.add_child(n)
	return n


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


func _multi(parent: Node, node_name: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array = [], shadows := true, customs: Array = []) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.use_custom_data = not customs.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
		if mm.use_custom_data:
			mm.set_instance_custom_data(i, customs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	if not shadows:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


## One mesh from [mesh, transform] pairs (single-surface meshes, unscaled transforms). Every part is
## deindexed first: once one part is indexed (a BoxMesh), SurfaceTool.append_from keeps an index
## array that names only the indexed parts, and the others are not drawn.
static func _merge(parts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	for part in parts:
		var one := SurfaceTool.new()
		one.create_from(part[0], 0)
		one.deindex()
		st.append_from(one.commit(), 0, part[1])
	return st.commit()


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func _at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))


## Transform on a circle of the given radius; local +Z faces the centre, local +X is tangent.
static func _radial(angle: float, radius: float, y: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(-cos(angle), -sin(angle))), Vector3(cos(angle) * radius, y, sin(angle) * radius))


## Solid of revolution: the annulus sector [r_in, r_out] x [a0, a1], extruded from y = 0 to y = h.
## Faces wind clockwise seen from outside (Godot's front face), so back-face culling stays on.
static func ring_sector(r_in: float, r_out: float, h: float, a0: float, a1: float, seg: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := Vector3(0, h, 0)
	for i in seg:
		var t0 := a0 + (a1 - a0) * i / seg
		var t1 := a0 + (a1 - a0) * (i + 1) / seg
		var c0 := Vector3(cos(t0), 0, sin(t0))
		var c1 := Vector3(cos(t1), 0, sin(t1))
		var n := (c0 + c1).normalized()
		_quad(st, c0 * r_in + up, c0 * r_out + up, c1 * r_out + up, c1 * r_in + up, Vector3.UP)
		_quad(st, c0 * r_in, c1 * r_in, c1 * r_out, c0 * r_out, Vector3.DOWN)
		_quad(st, c0 * r_out, c1 * r_out, c1 * r_out + up, c0 * r_out + up, n)
		if r_in > 0.001:
			_quad(st, c0 * r_in, c0 * r_in + up, c1 * r_in + up, c1 * r_in, -n)
	if not is_equal_approx(a1 - a0, TAU):
		var s0 := Vector3(cos(a0), 0, sin(a0))
		var s1 := Vector3(cos(a1), 0, sin(a1))
		_quad(st, s0 * r_in, s0 * r_out, s0 * r_out + up, s0 * r_in + up, Vector3(sin(a0), 0, -cos(a0)))
		_quad(st, s1 * r_in, s1 * r_in + up, s1 * r_out + up, s1 * r_out, Vector3(-sin(a1), 0, cos(a1)))
	return st.commit()


## Flat quad a-b-c-d facing n, wound for Godot's front face whichever way the corners are listed.
static func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	_poly(st, [a, b, c, d], [n, n, n, n])


## Convex polygon with a normal per corner, emitted clockwise as seen from the side the normals
## point to (Godot's front face) whichever way the corners are listed.
static func _poly(st: SurfaceTool, v: Array, n: Array) -> void:
	var avg := Vector3.ZERO
	for x: Vector3 in n:
		avg += x
	# Newell's normal: robust when two corners coincide, as on a lathe's axis.
	var pn := Vector3.ZERO
	for i in v.size():
		var a: Vector3 = v[i]
		var b: Vector3 = v[(i + 1) % v.size()]
		pn += Vector3((a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y))
	if pn.dot(avg) > 0.0:
		v = v.duplicate()
		v.reverse()
		n = n.duplicate()
		n.reverse()
	for i in range(1, v.size() - 1):
		for k in [0, i, i + 1]:
			st.set_normal(n[k])
			st.add_vertex(v[k])


## Surface of revolution around Y: profile points (radius, height) swept over seg steps of a full
## turn, smooth along the profile. Normals face the left of the profile's direction: run a solid's
## profile bottom to top, and a closed cross-section (closed = true) counter-clockwise.
static func _lathe(profile: PackedVector2Array, seg: int, closed := false) -> ArrayMesh:
	var n := profile.size()
	var norms: Array[Vector2] = []
	for i in n:
		var prev := profile[(i - 1 + n) % n] if (i > 0 or closed) else profile[i]
		var next := profile[(i + 1) % n] if (i < n - 1 or closed) else profile[i]
		var t := (next - prev).normalized()
		norms.append(Vector2(t.y, -t.x))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in seg:
		var c0 := Vector3(cos(TAU * j / seg), 0, sin(TAU * j / seg))
		var c1 := Vector3(cos(TAU * (j + 1) / seg), 0, sin(TAU * (j + 1) / seg))
		for i in (n if closed else n - 1):
			var k := (i + 1) % n
			var p := profile[i]
			var q := profile[k]
			_poly(st, [c0 * p.x + Vector3.UP * p.y, c1 * p.x + Vector3.UP * p.y, c1 * q.x + Vector3.UP * q.y, c0 * q.x + Vector3.UP * q.y],
				[c0 * norms[i].x + Vector3.UP * norms[i].y, c1 * norms[i].x + Vector3.UP * norms[i].y,
				c1 * norms[k].x + Vector3.UP * norms[k].y, c0 * norms[k].x + Vector3.UP * norms[k].y])
	return st.commit()


## Mouldings: a profile swept along a path, so a gilt bead or a stone ovolo has a section the light
## rolls across instead of being a flat strip. A profile is a list of [Vector2(across, up), its
## outward normal in that plane, ...]; two consecutive points at the same place with different
## normals are a crease, and the strip between them is skipped. Normals are written as given (arcs
## from profile_arc carry their exact ones), so a bead's highlight does not depend on its steps.

## Sweeps a profile round a rectangle in the xz plane: each point is [Vector2(d, h), normal, core],
## the section there the rectangle of half-size core (x, z) grown by d, its corners quarter circles
## of radius d, at height h. Points on one core are true offsets of each other round the corners.
## xf places the result (its basis may mirror: _poly winds by the normals).
static func moulding(st: SurfaceTool, profile: Array, xf := Transform3D(), corner_steps := 6) -> void:
	var rings := []
	for pt in profile:
		var d: float = pt[0].x
		var h: float = pt[0].y
		var n: Vector2 = pt[1]
		var core: Vector2 = pt[2]
		var ring := []
		for c in 4:
			var centre := Vector3(core.x if c == 0 or c == 3 else -core.x, h, core.y if c < 2 else -core.y)
			for i in corner_steps + 1:
				var phi := (c + float(i) / corner_steps) * PI / 2
				var dir := Vector3(cos(phi), 0, sin(phi))
				ring.append([xf * (centre + dir * d), (xf.basis * (dir * n.x + Vector3(0, n.y, 0))).normalized()])
		rings.append(ring)
	_sweep_rings(st, profile, rings, true)


## Sweeps a profile of [Vector2(r, h), normal] round the y axis, from angle a0 to a1 in seg steps
## (the same angles as ring_sector's, so a bead's edge lies on a ring_sector's face).
static func revolve(st: SurfaceTool, profile: Array, seg: int, a0 := 0.0, a1 := TAU, xf := Transform3D()) -> void:
	var full := is_equal_approx(a1 - a0, TAU)
	var rings := []
	for pt in profile:
		var p: Vector2 = pt[0]
		var n: Vector2 = pt[1]
		var ring := []
		for j in (seg if full else seg + 1):
			var a := a0 + (a1 - a0) * j / seg
			var dir := Vector3(cos(a), 0, sin(a))
			ring.append([xf * (dir * p.x + Vector3(0, p.y, 0)), (xf.basis * (dir * n.x + Vector3(0, n.y, 0))).normalized()])
		rings.append(ring)
	_sweep_rings(st, profile, rings, full)


## Extrudes a profile of [Vector2(x, y), normal] along z over length, both ends closed by a fan from
## cap_centre (the profile must be star-shaped from it).
static func extrude(st: SurfaceTool, profile: Array, length: float, cap_centre: Vector2, xf := Transform3D()) -> void:
	var rings := []
	for pt in profile:
		var p: Vector2 = pt[0]
		var n: Vector2 = pt[1]
		var nn := (xf.basis * Vector3(n.x, n.y, 0)).normalized()
		rings.append([[xf * Vector3(p.x, p.y, -length * 0.5), nn], [xf * Vector3(p.x, p.y, length * 0.5), nn]])
	_sweep_rings(st, profile, rings, false)
	for z in [-length * 0.5, length * 0.5]:
		var en := (xf.basis * Vector3(0, 0, signf(z))).normalized()
		var c := xf * Vector3(cap_centre.x, cap_centre.y, z)
		for k in profile.size() - 1:
			var p: Vector2 = profile[k][0]
			var q: Vector2 = profile[k + 1][0]
			if not p.is_equal_approx(q):
				_poly(st, [c, xf * Vector3(p.x, p.y, z), xf * Vector3(q.x, q.y, z)], [en, en, en])


static func _sweep_rings(st: SurfaceTool, profile: Array, rings: Array, closed: bool) -> void:
	for k in profile.size() - 1:
		if (profile[k][0] as Vector2).is_equal_approx(profile[k + 1][0]):
			continue
		var r0: Array = rings[k]
		var r1: Array = rings[k + 1]
		for i in (r0.size() if closed else r0.size() - 1):
			var j := (i + 1) % r0.size()
			_poly(st, [r0[i][0], r0[j][0], r1[j][0], r1[i][0]], [r0[i][1], r0[j][1], r1[j][1], r1[i][1]])


## Appends an elliptic arc to a profile: centre c, radii ra across and ry up, from angle t0 to t1
## (0 points across, PI / 2 up) in n steps, each point with its normal, away from the centre or,
## concave, towards it; extra is appended to each point (a moulding's core).
static func profile_arc(out: Array, c: Vector2, ra: float, ry: float, t0: float, t1: float, n: int, extra := [], concave := false) -> void:
	for i in n + 1:
		var t := lerpf(t0, t1, float(i) / n)
		var nn := Vector2(cos(t) / ra, sin(t) / ry).normalized()
		out.append([c + Vector2(ra * cos(t), ry * sin(t)), -nn if concave else nn] + extra)


## A half-round bead standing on a face: centred at c in the profile's plane, its flat side on the
## face, bulging towards the face's normal (a unit axis of the profile's plane).
static func profile_bead(c: Vector2, r: float, normal: Vector2, steps := 10, extra := []) -> Array:
	var out := []
	var t := normal.angle()
	profile_arc(out, c, r, r, t - PI / 2, t + PI / 2, steps, extra)
	return out


## Classical gilt ornament as instances: egg-and-dart on the capitals' ovolos and under the
## galleries, bead-and-reel on the astragals. Each piece is a small ellipsoid baked to its own
## radii, so its normals hold under any instance transform.
static func _ellipsoid(r: Vector3, segs: int, rings: int) -> ArrayMesh:
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = segs
	s.rings = rings
	var arrays := s.get_mesh_arrays()
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in v.size():
		v[i] *= r
		n[i] = (n[i] / r).normalized()
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_TANGENT] = null
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## Transforms spaced evenly from a to b (count of them, about pitch apart): at the middles of the
## steps with offset 0.5, on the steps between them with offset 0. Each piece's x runs along the
## line, its z along n (the surface's outward normal there), its y up the surface.
static func _along(out: Array, a: Vector3, b: Vector3, n: Vector3, pitch: float, offset: float, xf: Transform3D) -> void:
	var run := b - a
	var count := maxi(1, roundi(run.length() / pitch))
	var x := run.normalized()
	var z := (n - x * n.dot(x)).normalized()
	var basis := Basis(x, z.cross(x), z)
	for i in count:
		var t := (i + offset) / count
		if t > 0.0 and t < 1.0:
			out.append(xf * Transform3D(basis, a + run * t))


## The same round a circle of radius r at height y, from angle a0 to a1, facing the centre and
## tilted by tilt (radians, positive up). With offset 0 the first step is on a0, so arcs laid end
## to end keep the spacing across their joins.
static func _round(out: Array, r: float, y: float, a0: float, a1: float, pitch: float, offset: float, tilt: float) -> void:
	var count := maxi(1, roundi(r * (a1 - a0) / pitch))
	for i in count:
		var t := (i + offset) / count
		var a := lerpf(a0, a1, t)
		var x := Vector3(-sin(a), 0, cos(a))
		var z := Vector3(-cos(a) * cos(tilt), sin(tilt), -sin(a) * cos(tilt))
		out.append(Transform3D(Basis(x, z.cross(x), z), Vector3(cos(a) * r, y, sin(a) * r)))


## A half-round bead of radius r round the inside of a cylinder of radius radius, centred at y = 0.
static func _bead_ring(radius: float, r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	revolve(st, profile_bead(Vector2(radius, 0.0), r, Vector2(-1, 0), 10), 128)
	return st.commit()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)
