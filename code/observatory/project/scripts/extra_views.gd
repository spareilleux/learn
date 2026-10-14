extends Node
## Two preset views after fly_camera.gd's seven (keys 1 to 7, which that script owns):
##   8: the stained glass, up in the drum, facing a lancet at its own height;
##   9: the roof, outside on the drum's rim, over the roof and Trantor's domes to the horizon,
##      under the galactic core (scripts/upperside.gd, built the first time the camera is outside).
## The Views button on touch screens goes through them too (touch_controls.gd). The glass view is a
## flight like the other presets (view_move.gd). The roof is a cut in and out, since a flight would
## pass through the roof. It is a vantage point: the view turns, and flying does not move it, since
## fly_camera.gd would drop the camera to walking height inside the hall; walking, the first step
## goes down onto the terrace at the drum's foot, under the view, where the walker goes on round the
## roof to the lift's kiosk (scripts/lift.gd). Keys 1 to 8, the Views button and the button on
## screen go back in; from the terrace too, as a cut rather than a flight through the roof. --preset=glass|roof (?preset=glass|roof) starts
## there.

const UPPERSIDE_SCRIPT_PATH := "res://scripts/upperside.gd"
## Key 0: the cinematic (scripts/cinematic.gd), here since observatory.gd stays version 28's in builds.
const CINEMATIC_SCRIPT_PATH := "res://scripts/cinematic.gd"
## The glazed bays and the palace gardens (scripts/palace_gardens.gd), here for the same reason.
const GARDENS_SCRIPT_PATH := "res://scripts/palace_gardens.gd"
## The library wing off bay 10 (scripts/library_wing.gd), beside the gardens, which open its bay.
const WING_SCRIPT_PATH := "res://scripts/library_wing.gd"
## The telescope view, O (scripts/telescope.gd), beside the curio wheel's monocle.
const TELESCOPE_SCRIPT_PATH := "res://scripts/telescope.gd"
## [position, target, vertical fov], as fly_camera.gd's PRESETS.
const VIEWS := {
	"glass": [Vector3(0.0, 23.9, 4.5), Vector3(0.0, 23.0, 9.96), 62.0],
	"roof": [Vector3(10.15, 26.0, 3.69), Vector3(-8.65, 33.3, -3.15), 72.0],
}
const TEXT := {
	"en": {"back": "Back inside", "roof": "On the observatory's roof, above the palace gardens of Trantor",
		"keys": "Click: look  ·  WASD: walk down onto the terrace  ·  1–8: back inside",
		"touch": "Drag: look  ·  Stick: walk down onto the terrace  ·  Views: back inside"},
	"fr": {"back": "Rentrer", "roof": "Sur le toit de l'observatoire, au-dessus des jardins du palais de Trantor",
		"keys": "Clic : regarder  ·  ZQSD : descendre sur la terrasse  ·  1 à 8 : rentrer",
		"touch": "Glisser : regarder  ·  Joystick : descendre sur la terrasse  ·  Vues : rentrer"},
	"es": {"back": "Volver adentro", "roof": "En el tejado del observatorio, sobre los jardines del palacio de Trantor",
		"keys": "Clic: mirar  ·  WASD: bajar a la terraza  ·  1 a 8: volver adentro",
		"touch": "Arrastrar: mirar  ·  Joystick: bajar a la terraza  ·  Vistas: volver adentro"},
}
const FLY_HUD_OLD := "1–7: views"
const FLY_HUD_NEW := "1–9: views"

var on_roof := false
var touch := false
var lang := "en"
## Counts for tests: views taken, frames the roof held the camera back, Upperside builds.
var stats := {"glass": 0, "roof": 0, "held": 0, "left_roof": 0, "builds": 0, "terrace": 0, "cuts_in": 0}

var _obs: Node3D
var _camera: Camera3D
var _move: Node
var _corridor: Node
var _upperside: Node3D
var _roof_at := Vector3.ZERO
var _was_outside := false
var _prev_at := Vector3.ZERO
var _presets: Array[Vector3] = []  # where the other presets put the camera
var _outer := 18.0
var _oculus := 10.0
var _slab_top := 21.1
var _dome_y := 24.6
var _ui: CanvasLayer
var _bar: VBoxContainer
var _back: Button
var _label: Label
var _cinematic: Node
var _gardens: Node
var _wing: Node3D


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	# After the camera (0), the walking body (100) and the corridor (150); before the flights (880),
	# which must see a way out of the roof as a cut.
	process_priority = 870
	_move = _obs.get_node_or_null("ViewMove")
	_corridor = _obs.get_node_or_null("Multiverse")
	_outer = float(_obs.get("outer_radius"))
	_oculus = float(_obs.get("oculus_radius"))
	_slab_top = float(_obs.get("_ceiling_y")) + 0.6
	_dome_y = float(_obs.get("_dome_y"))
	var fly_presets: Dictionary = _camera.get_script().get_script_constant_map().get("PRESETS", {})
	for p in fly_presets.values():
		_presets.append(p[0])
	_presets.append(VIEWS.glass[0])
	touch = _obs.get_node_or_null("TouchControls") != null
	var lib := _obs.get_node_or_null("Generated/CourseShelves")
	if lib != null:
		lang = str(lib.get("lang"))
		if lib.has_signal("lang_changed"):
			lib.connect("lang_changed", set_lang)
	_build_ui()
	_make_cinematic()
	_make_gardens()
	_make_wing()
	_make_telescope()
	var start := ""
	var film := OS.get_cmdline_user_args().has("--cinematic")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			start = arg.trim_prefix("--preset=")
	if OS.has_feature("web"):
		var q := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('preset') || ''", true))
		if q != "":
			start = q
		film = film or str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('cinematic') || ''", true)) == "1"
	if VIEWS.has(start):
		go.call_deferred(start)
	if film:
		_cinematic_at_start.call_deferred()


func set_lang(code: String) -> void:
	lang = code if TEXT.has(code) else "en"
	var t: Dictionary = TEXT[lang]
	_back.text = "×  " + str(t.back)
	_label.text = str(t.roof) + "\n" + str(t.touch if touch else t.keys)
	_layout()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code == KEY_8:
		go("glass")
	elif code == KEY_9:
		go("roof")
	elif code == KEY_0:
		cinematic()


## Plays the cinematic (key 0); false when it is missing from the build or refused.
func cinematic(from := 0) -> bool:
	return _cinematic != null and bool(_cinematic.call("play", from))


## Made here, added after every other node (the drone included) so that its _input, called first,
## takes every key, click and touch while it plays.
func _make_cinematic() -> void:
	if not ResourceLoader.exists(CINEMATIC_SCRIPT_PATH):
		return
	_cinematic = load(CINEMATIC_SCRIPT_PATH).new()
	_cinematic.name = "Cinematic"
	_cinematic.call("configure", _obs, _camera)
	_obs.add_child.call_deferred(_cinematic)


## The two glazed bays either side of the lift and the palace gardens through them
## (scripts/palace_gardens.gd), lit by the same galactic core as Upperside.
func _make_gardens() -> void:
	if not ResourceLoader.exists(GARDENS_SCRIPT_PATH):
		return
	var sky := _obs.get_node_or_null("Generated/Ceiling/NightSky") as GeometryInstance3D
	var core := Vector3(-0.468, 0.867, -0.170)
	if sky != null and sky.material_override is ShaderMaterial:
		core = (sky.material_override as ShaderMaterial).get_shader_parameter("core_dir")
	_gardens = load(GARDENS_SCRIPT_PATH).new()
	_gardens.name = "PalaceGardens"
	_gardens.call("configure", _obs, core)
	_obs.add_child.call_deferred(_gardens)


## The library wing, after the gardens, so that they have cut its bay when it is built.
func _make_wing() -> void:
	if _gardens == null or not ResourceLoader.exists(WING_SCRIPT_PATH):
		return
	var script: GDScript = load(WING_SCRIPT_PATH)
	if not bool(script.call("wanted")):
		return
	var sky := _obs.get_node_or_null("Generated/Ceiling/NightSky") as GeometryInstance3D
	var core := Vector3(-0.468, 0.867, -0.170)
	if sky != null and sky.material_override is ShaderMaterial:
		core = (sky.material_override as ShaderMaterial).get_shader_parameter("core_dir")
	_wing = script.new()
	_wing.name = "LibraryWing"
	_wing.call("configure", _obs, core)
	_obs.add_child.call_deferred(_wing)


func _make_telescope() -> void:
	if not ResourceLoader.exists(TELESCOPE_SCRIPT_PATH):
		return
	var scope: Node = load(TELESCOPE_SCRIPT_PATH).new()
	scope.name = "Telescope"
	scope.call("configure", _obs, _camera)
	_obs.add_child.call_deferred(scope)


## --cinematic (?cinematic=1) plays it once the hall has had a moment to settle.
func _cinematic_at_start() -> void:
	await get_tree().create_timer(1.5).timeout
	cinematic()


## Takes a view by name: "glass" or "roof".
func go(view: String) -> void:
	if _camera == null or not VIEWS.has(view) or (_corridor != null and bool(_corridor.get("inside"))):
		return
	var roof := view == "roof"
	if roof != on_roof and _move != null and _move.has_method("cut"):
		_move.call("cut")  # in or out through the roof: no flight
	var p: Array = VIEWS[view]
	_camera.look_at_from_position(p[0], p[1], Vector3.UP)
	_camera.fov = p[2]
	var e := _camera.basis.get_euler()
	_camera.set("_yaw", e.y)
	_camera.set("_pitch", e.x)
	on_roof = roof
	_roof_at = p[0]
	stats[view] += 1
	_sync()


func _process(_delta: float) -> void:
	if _camera == null:
		return
	var in_corridor := _corridor != null and bool(_corridor.get("inside"))
	if on_roof:
		var at := _camera.global_position
		if in_corridor:
			_leave_roof(false)  # the corridor placed the camera itself, as a cut
		elif not at.is_equal_approx(_roof_at):
			if _is_preset(at):
				_leave_roof(true)
			elif _can_step_down():
				_step_down()
			else:
				# A flight: the roof holds the camera where it stands, and the view turns.
				_camera.global_position = _roof_at
				stats.held += 1
	elif _was_outside and not in_corridor and _is_preset(_camera.global_position) \
			and _camera.global_position.distance_to(_prev_at) > 2.5 and _move != null and _move.has_method("cut"):
		# From the terrace to a view inside: a cut, as from the roof view.
		_move.call("cut")
		stats.cuts_in += 1
	var outside := not in_corridor and _outside(_camera.global_position)
	# Upperside shows to the camera that looks: the drone's may be out while the visitor is in
	# (scripts/drone.gd).
	var eye := get_viewport().get_camera_3d()
	var shown := outside if eye == null or eye == _camera else not in_corridor and _outside(eye.global_position)
	if shown and _upperside == null and ResourceLoader.exists(UPPERSIDE_SCRIPT_PATH):
		_build_upperside()
	if _upperside != null and _upperside.visible != shown:
		_upperside.visible = shown
	if _gardens != null:
		_gardens.set("show_always", shown)
	_was_outside = outside
	_prev_at = _camera.global_position
	_fly_hud()


## Outside: above the drum, over the roof round it, or beyond the walls, but in the library wing.
func _outside(p: Vector3) -> bool:
	var r := Vector2(p.x, p.z).length()
	if _wing != null and _wing.is_inside_tree() and bool(_wing.call("contains", p)):
		return false
	return p.y > _dome_y - 0.2 or (p.y > _slab_top and r > _oculus + 0.3) or r > _outer + 0.8


## Walking (not flying), with the lift's roof there to stand on.
func _can_step_down() -> bool:
	var lift := _obs.get_node_or_null("Lift")
	return _obs.get_node_or_null("WalkBody") != null and not bool(_camera.get("_free_fly")) \
		and lift != null and bool(lift.get("roof"))


## Down from the roof view onto the lead at the drum's foot, under it, at walking height and facing
## where the view faced: the walking body takes the camera from there (walk_physics.gd, _eye_floor).
func _step_down() -> void:
	var lift := _obs.get_node("Lift")
	var lim: Vector2 = lift.call("roof_limits")
	var dir := Vector2(_roof_at.x, _roof_at.z).normalized()
	var r := lim.x + 0.9
	var eye := float(lift.call("roof_height", r)) + float(_camera.get("walking_eye_height"))
	if _move != null and _move.has_method("cut"):
		_move.call("cut")
	var yaw := float(_camera.get("_yaw"))
	_camera.global_position = Vector3(dir.x * r, eye, dir.y * r)
	_camera.set("_pitch", 0.0)
	_camera.rotation = Vector3(0.0, yaw, 0.0)
	on_roof = false
	stats.terrace += 1
	_sync()


func _is_preset(p: Vector3) -> bool:
	for q in _presets:
		if p.distance_to(q) < 0.01:
			return true
	return false


func _leave_roof(cut: bool) -> void:
	if cut and _move != null and _move.has_method("cut"):
		_move.call("cut")
	on_roof = false
	stats.left_roof += 1
	_sync()


func _build_upperside() -> void:
	var up: Node3D = load(UPPERSIDE_SCRIPT_PATH).new()
	up.name = "Upperside"
	var sky := _obs.get_node_or_null("Generated/Ceiling/NightSky") as GeometryInstance3D
	var core := Vector3(-0.468, 0.867, -0.170)
	if sky != null and sky.material_override is ShaderMaterial:
		core = (sky.material_override as ShaderMaterial).get_shader_parameter("core_dir")
	if _gardens != null:
		up.set("deck", false)
	up.call("configure", _obs, core)
	_obs.add_child(up)
	_upperside = up
	stats.builds += 1


## fly_camera.gd writes "1–7: views" in its fly-mode hint; walk_physics.gd writes the walking one.
func _fly_hud() -> void:
	var hint := _obs.get_node_or_null("ControlsHud/Panel/Hint") as Label
	if hint != null and hint.text.begins_with("FLY MODE") and hint.text.contains(FLY_HUD_OLD):
		hint.text = hint.text.replace(FLY_HUD_OLD, FLY_HUD_NEW)


func _back_inside() -> void:
	if not on_roof or _camera == null:
		return
	var fly_presets: Dictionary = _camera.get_script().get_script_constant_map().get("PRESETS", {})
	if _camera.has_method("go_to_preset") and fly_presets.has("overview"):
		_camera.call("go_to_preset", "overview")  # _process sees the preset and leaves as a cut


func _sync() -> void:
	if _bar != null:
		_bar.visible = on_roof
	_publish()


# --- On screen --------------------------------------------------------------------------------

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "RoofUI"
	_ui.layer = 29
	add_child(_ui)
	_bar = VBoxContainer.new()
	_bar.name = "RoofBar"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.visible = false
	_ui.add_child(_bar)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 4)
	_bar.add_child(_label)
	_back = Button.new()
	_back.name = "BackInside"
	_back.focus_mode = Control.FOCUS_ALL
	_back.pressed.connect(_back_inside)
	# Its place for the web tests, once the bar is laid out: before, the rect is stale.
	_back.item_rect_changed.connect(_publish)
	# The corridor's Leave button (scripts/multiverse.gd), so that a way back looks the same.
	_back.add_theme_stylebox_override("normal", _style(Color(0.08, 0.07, 0.06, 0.85), Color(0.95, 0.75, 0.42)))
	_back.add_theme_stylebox_override("hover", _style(Color(0.2, 0.15, 0.08, 0.92), Color(1.0, 0.85, 0.5)))
	_back.add_theme_stylebox_override("focus", _style(Color(0.2, 0.15, 0.08, 0.92), Color(1.0, 0.9, 0.6)))
	_back.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.2, 0.1, 0.95), Color(1.0, 0.9, 0.6)))
	_back.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	_bar.add_child(_back)
	get_viewport().size_changed.connect(_layout)
	set_lang(lang)


## As the corridor's bar: at the bottom on a computer, under the Courses button on a touch screen.
func _layout() -> void:
	if _bar == null:
		return
	var size := get_viewport().get_visible_rect().size
	var u := minf(size.x, size.y)
	var fs := int(clampf(u * (0.034 if touch else 0.024), 14.0, 40.0))
	_back.add_theme_font_size_override("font_size", fs + 2)
	_label.add_theme_font_size_override("font_size", maxi(12, fs - 3))
	var w := minf(size.x - 32.0, 760.0 if not touch else size.x * 0.9)
	var bottom := not touch
	_bar.anchor_left = 0.5
	_bar.anchor_right = 0.5
	_bar.anchor_top = 1.0 if bottom else 0.0
	_bar.anchor_bottom = _bar.anchor_top
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	_bar.offset_left = -w * 0.5
	_bar.offset_right = w * 0.5
	_bar.offset_top = -u * 0.05 if bottom else u * 0.27
	_bar.offset_bottom = _bar.offset_top
	_bar.alignment = BoxContainer.ALIGNMENT_END if bottom else BoxContainer.ALIGNMENT_BEGIN
	_bar.move_child(_back, _bar.get_child_count() - 1 if bottom else 0)
	_back.custom_minimum_size = Vector2(0.0, fs * 2.2)
	_publish.call_deferred()


## Web tests: the roof's state and the Back button's centre, as fractions of the screen.
func _publish() -> void:
	if not OS.has_feature("web") or _back == null:
		return
	var size := get_viewport().get_visible_rect().size
	var c := _back.get_global_rect().get_center() / size if on_roof else Vector2(-1, -1)
	JavaScriptBridge.eval("window.__obsViews = %s" % JSON.stringify({"roof": on_roof, "glass": stats.glass,
		"roofs": stats.roof, "held": stats.held, "builds": stats.builds, "back": [c.x, c.y], "lang": lang}), true)


static func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
