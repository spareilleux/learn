extends CanvasLayer
## On-screen controls for touch screens, added by scripts/observatory.gd when the screen has one:
## a stick bottom left to walk (dragged past its rim: sprint), a drag anywhere else to look,
## buttons bottom right to fly, jump and crouch (walking) or rise and descend (flying), and change
## view, one top right for the course catalogue (with the language selector under it), and a tap
## on a book for its card, a second tap to open it; near the lift or in its cage, the lift's own
## buttons (scripts/lift.gd, touch_panel): one per landing in the cage, one to call it at a
## landing; at a tapped book, two figures leaning left and right, held to lean and read its spine,
## between the stick and the arrows, or over the arrows where that row is too narrow (a phone held
## upright). The controls panel of main.tscn becomes this help, beside the language selector,
## wrapped, or under it where that would be a narrow column; it goes 6 seconds after the first
## touch, and the ? button top left
## brings it back; a book's card takes its place while it shows (the author found the phone's
## screen too full, 2026-10-01). The fly camera
## (scripts/fly_camera.gd) is driven through the
## keys it already reads, and so is the walking body (scripts/walk_physics.gd): Space, C and Shift;
## its lean through touch_lean. A look drag turns the camera itself. The course shelves
## (scripts/course_library.gd) are driven through their touch methods.
##
## Touches do not also reach the scene as mouse clicks: mouse emulation is off, except while the
## catalogue is open, whose list and scrolling are ordinary controls.

const STICK_DEAD := 0.3      # stick deflection below which no key is held
const STICK_SPRINT := 1.3    # drag past the rim, in radii, from which Shift is held too, walking
const LOOK_GAIN := 1.2       # times the camera's own mouse sensitivity, per pixel of drag
const PITCH_LIMIT := 1.5     # radians, as the camera's own mouse look
const NO_TOUCH := -2147483648  # not a touch index: the web passes browser identifiers, maybe negative
const TAP_TIME := 0.35       # seconds: a longer touch is a drag, not a tap
const TAP_MOVE := 0.03       # of the screen's shorter side: a longer move is a drag
const KEYS := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "up": KEY_E, "down": KEY_C}
## fly_camera.gd's seven views, then the glass and the roof (extra_views.gd).
const PRESET_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9]
const TEXT := {
	"en": {"fly": "Fly", "walk": "Walk", "views": "Views", "courses": "Courses", "close": "Close", "curios": "Curios",
		"ride": "Ride", "get_off": "Get off",
		"ride_help": "Stick: ride and turn  ·  Drag: look; moving, the scooter follows\nHands off: autopilot  ·  Get off: walk here  ·  ?: this help",
		"foot_help": "Stick: walk  ·  Drag: look  ·  Views: back inside\nRide: back on the scooter, beside it  ·  ?: this help",
		"hint": "Stick: walk, past its rim: sprint  ·  Drag: look  ·  Hand: curios\nArrows: jump and crouch (in flight, rise and descend)  ·  Views: the nine viewpoints\nAt a tapped book, the leaning figures read its spine  ·  ?: this help"},
	"fr": {"fly": "Voler", "walk": "Marcher", "views": "Vues", "courses": "Cours", "close": "Fermer", "curios": "Curiosités",
		"ride": "Balade", "get_off": "Descendre",
		"ride_help": "Joystick : rouler et tourner  ·  Glisser : regarder ; en marche, le gyropode suit\nSans toucher : pilote auto  ·  Descendre : marcher ici  ·  ? : cette aide",
		"foot_help": "Joystick : marcher  ·  Glisser : regarder  ·  Vues : rentrer\nBalade : remonter sur le gyropode, à côté  ·  ? : cette aide",
		"hint": "Joystick : marcher, au-delà du bord : courir  ·  Glisser : regarder  ·  Main : curiosités\nFlèches : sauter et s'accroupir (en vol, monter et descendre)  ·  Vues : les neuf points de vue\nDevant un livre touché, les silhouettes penchées lisent son dos  ·  ? : cette aide"},
	"es": {"fly": "Volar", "walk": "Andar", "views": "Vistas", "courses": "Cursos", "close": "Cerrar", "curios": "Curiosidades",
		"ride": "Paseo", "get_off": "Bajar",
		"ride_help": "Joystick: avanzar y girar  ·  Arrastrar: mirar; en marcha, el patinete sigue\nSin tocar: piloto automático  ·  Bajar: andar aquí  ·  ?: esta ayuda",
		"foot_help": "Joystick: andar  ·  Arrastrar: mirar  ·  Vistas: volver dentro\nPaseo: subir al patinete, a su lado  ·  ?: esta ayuda",
		"hint": "Joystick: andar, más allá del borde: correr  ·  Arrastrar: mirar  ·  Mano: curiosidades\nFlechas: saltar y agacharse (en vuelo, subir y bajar)  ·  Vistas: los nueve puntos de vista\nAnte un libro tocado, las siluetas inclinadas leen su lomo  ·  ?: esta ayuda"},
}
const GILT := Color(0.86, 0.7, 0.42)

var lang := "en"
## Counts for tests: taps, drags, button presses, keys sent.
var stats := {"taps": 0, "looks": 0, "buttons": 0, "keys": 0}

var _obs: Node
var _camera: Camera3D
var _canvas := Control.new()
var _touches := {}  # touch index -> {role, start, pos, time, moved, button}
var _held := {}     # Key -> bool, the keys this node holds down
var _preset := 0
var _library_id := 0
var _hint_text := ""
var _u := 100.0     # the screen's shorter side, pixels
var _stick_centre := Vector2.ZERO
var _stick_radius := 60.0
var _stick := Vector2.ZERO
var _buttons := {}  # name -> Rect2
## Phones and tablets show the controls at once; a computer that merely has a touch screen shows
## them at the first touch, and keeps its keyboard hints until then.
var _shown := OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile") \
		or OS.get_cmdline_user_args().has("--touch")
var _hud_visible := true
var _hud_avail := -1.0  # the width the controls panel may take, left of the Courses button
var _lift_panel := {}   # scripts/lift.gd's touch_panel(), as last laid out
var _lift_box := Rect2()  # round the lift's buttons
var _help := true         # the help (the controls panel) shown
var _help_auto := true    # and it goes by itself after the first touch, until ? is used
var _help_left := -1.0    # seconds of help left, once the first touch set it
var _panel_top := NAN     # the controls panel's own offset_top in main.tscn
const HELP_TIME := 6.0    # seconds the help stays after the first touch


func configure(observatory: Node, camera: Camera3D) -> void:
	_obs = observatory
	_camera = camera


func _ready() -> void:
	layer = 6  # over the course UI (5), so the close button stays above the catalogue
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	Input.emulate_mouse_from_touch = false


func _exit_tree() -> void:
	for key: Key in _held.keys():
		_key(key, false)
	_touches.clear()
	_sync_lean()
	Input.emulate_mouse_from_touch = true


func _library() -> Node:
	return _obs.get_node_or_null("Generated/CourseShelves") if _obs != null else null


func _process(_delta: float) -> void:
	var lib := _library()
	if lib != null and lib.get_instance_id() != _library_id and lib.has_method("set_touch"):
		_library_id = lib.get_instance_id()
		lib.call("set_touch", true)
		lang = str(lib.get("lang"))
		_hint_text = ""
	elif lib != null and str(lib.get("lang")) != lang:
		lang = str(lib.get("lang"))  # the reader picked another language
	var open := _catalogue_open()
	# The catalogue's list is made of ordinary controls, which only hear mouse clicks.
	Input.emulate_mouse_from_touch = open
	if _help_auto and _help_left > 0.0:
		_help_left -= _delta
		if _help_left <= 0.0:
			_help = false
			_help_auto = false
	_layout()
	_update_hud()
	_canvas.queue_redraw()


func _catalogue_open() -> bool:
	var lib := _library()
	return lib != null and lib.has_method("is_catalogue_open") and bool(lib.call("is_catalogue_open"))


func _t(key: String) -> String:
	return TEXT.get(lang, TEXT.en).get(key, TEXT.en[key])


## main.tscn's controls panel describes the keyboard; on a touch screen it describes the touch
## controls, in the page's language, and shrinks to that text.
func _update_hud() -> void:
	var hud := _camera.get_parent().get_node_or_null("ControlsHud") if _camera != null else null
	if hud == null:
		return
	_hud_visible = bool(hud.get("visible"))
	_canvas.visible = _hud_visible and _shown
	var hint := hud.get_node_or_null("Panel/Hint") as Label
	var panel := hud.get_node_or_null("Panel") as Control
	var font_size := roundi(15.0 * _scale())
	# The panel stops short of the Courses button and the language selector under it: on a phone
	# held upright its second line ran under both.
	var courses: Rect2 = _buttons.get("courses", Rect2())
	var right := courses.position.x if courses.size.x > 0.0 else 0.0
	var lib := _library()
	var langs := lib.get("_lang_panel") as Control if lib != null else null
	if langs != null and langs.is_visible_in_tree() and langs.size.x > 0.0 and langs.global_position.x > 0.0:
		right = minf(right, langs.global_position.x) if right > 0.0 else langs.global_position.x
	var avail := right - 0.02 * _u - panel.offset_left if panel != null and right > 0.0 else 0.0
	if not _shown or hint == null or panel == null:
		return
	if is_nan(_panel_top):
		_panel_top = panel.offset_top
	panel.visible = _help_visible()
	if hint.text != _help_text() or hint.get_theme_font_size("font_size") != font_size or not is_equal_approx(avail, _hud_avail):
		_hud_avail = avail
		hint.text = _help_text()
		hint.add_theme_font_size_override("font_size", font_size)
	var text_w := hint.get_theme_font("font").get_multiline_string_size(hint.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var style := panel.get_theme_stylebox("panel")
	var pad := style.get_margin(SIDE_LEFT) + style.get_margin(SIDE_RIGHT) if style != null else 0.0
	if avail > 0.0 and text_w + pad > avail and avail >= 0.6 * (text_w + pad):
		# A little too wide beside the Courses button and the language selector (a phone held
		# sideways): a line more, still at the top, clear of the middle of a short screen.
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.offset_top = _panel_top
		panel.offset_right = panel.offset_left + avail
	elif avail > 0.0 and text_w + pad > avail:
		# Far too wide beside them (a phone held upright): under them, across the screen, rather
		# than a narrow column down it.
		var below := courses.end.y
		if langs != null and langs.is_visible_in_tree():
			below = maxf(below, langs.get_global_rect().end.y)
		var width := _canvas.get_viewport_rect().size.x - 2.0 * panel.offset_left
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if text_w + pad > width else TextServer.AUTOWRAP_OFF
		panel.offset_top = below + 0.02 * _u
		panel.offset_right = panel.offset_left + minf(width, text_w + pad)
	else:
		hint.autowrap_mode = TextServer.AUTOWRAP_OFF
		panel.offset_top = _panel_top
		panel.offset_right = panel.offset_left  # the container grows back to its text
	panel.offset_bottom = panel.offset_top  # and its height to its lines


## For the course shelves' book hint, which shows with this help.
func help_shown() -> bool:
	return not _shown or _help_visible()


func _toggle_help() -> void:
	_help = not _help
	_help_auto = false
	_help_left = -1.0


## Text and controls grow with the screen on phones, whose canvas has many pixels per point.
func _scale() -> float:
	return clampf(_u / 700.0, 1.0, 2.5) if OS.has_feature("web_android") or OS.has_feature("web_ios") else 1.0


func _layout() -> void:
	var size := _canvas.get_viewport_rect().size
	_u = minf(size.x, size.y)
	var m := 0.05 * _u
	_stick_radius = 0.13 * _u
	_stick_centre = Vector2(m + _stick_radius, size.y - m - _stick_radius)
	var b := 0.15 * _u
	var g := 0.03 * _u
	var fly := Rect2(size.x - m - b, size.y - m - b, b, b)
	_buttons = {"fly": fly, "views": Rect2(fly.position - Vector2(0, b + g), fly.size), "courses": Rect2(size.x - m - b * 1.3, m, b * 1.3, b * 0.55)}
	# The same two places: rise and descend in flight; jump and crouch on foot, if the walking
	# body is there to do them.
	var top := Rect2(fly.position - Vector2(b + g, b + g), fly.size)
	var bottom := Rect2(fly.position - Vector2(b + g, 0), fly.size)
	if _flying():
		_buttons["up"] = top
		_buttons["down"] = bottom
	elif _walker() != null and not _riding() and not _on_foot():
		_buttons["jump"] = top
		_buttons["crouch"] = bottom
	_layout_lift(size, m, g, top)
	if not _flying() and _walker() != null and _lift_box.size == Vector2.ZERO and _lean_wanted():
		_layout_lean(size, m, g, top, bottom, b)
	# The ride in the gardens, over the views button, where neither the lift's buttons nor the lean
	# figures stand.
	if _segway() != null and _lift_box.size == Vector2.ZERO and not _buttons.has("lean_r") and not _in_corridor():
		_buttons["ride"] = Rect2(fly.position - Vector2(0, 2.0 * (b + g)), fly.size)
	# The curio wheel's button, above the stick's reach (scripts/curio_wheel.gd): with a curio held, a
	# tap uses it there. As large as the others, and named beside it: smaller and unnamed, the author
	# did not find the wheel (2026-10-02).
	if _curio() != null:
		var cb := 0.15 * _u
		_buttons["curios"] = Rect2(m, _stick_centre.y - _stick_radius * 1.6 - g - cb, cb, cb)
	# The help: a tap on it puts it away, and the ? that takes its corner brings it back. While a
	# book's card shows, it has the screen (and its own hint): no help, and no ? either.
	var panel := _hud_panel()
	if _shown and _help_visible() and panel != null and panel.is_visible_in_tree():
		_buttons["help"] = panel.get_global_rect()
	elif _shown and not _help and not _in_corridor():
		_buttons["help"] = Rect2(m, m, 0.09 * _u, 0.09 * _u)


## The lean figures show only where they do something: at an aimed book, while the walker reads its
## spine, or while a finger still holds one.
func _lean_wanted() -> bool:
	for t: Dictionary in _touches.values():
		if str(t.button).begins_with("lean_"):
			return true
	var walker := _walker()
	if walker != null and walker.has_method("is_reading") and bool(walker.call("is_reading")):
		return true
	return _book_aimed()


func _book_aimed() -> bool:
	var lib := _library()
	return lib != null and int(lib.get("_hovered")) >= 0


## The help on screen: asked for, or not yet gone; not in the corridor, whose bar explains it, nor
## over a book's card or the curio wheel.
func _help_visible() -> bool:
	var curio := _curio()
	return _help and not _in_corridor() and not _book_aimed() and not (curio != null and bool(curio.call("is_open")))


func _curio() -> Node:
	return _obs.get_node_or_null("CurioWheel") if _obs != null else null


## The help's text; riding, the ride's own, and on foot in the gardens theirs. A line for the ride under
## the walking help pushed it down over the curio wheel's button on a phone held sideways
## (artpass/publish/regress-pub29, curio_touch_land_es); the Ride button names itself.
func _help_text() -> String:
	if _riding():
		return _t("ride_help")
	return _t("foot_help") if _on_foot() else _t("hint")


## The ride in the gardens (scripts/segway.gd), when the scene has it.
func _segway() -> Node:
	return _obs.get_node_or_null("Segway") if _obs != null else null


func _riding() -> bool:
	var seg := _segway()
	return seg != null and bool(seg.get("riding"))


## Off the scooter, walking in the gardens (scripts/segway.gd).
func _on_foot() -> bool:
	var seg := _segway()
	return seg != null and bool(seg.get("on_foot"))


func _hud_panel() -> Control:
	return _camera.get_parent().get_node_or_null("ControlsHud/Panel") as Control if _camera != null else null


func _in_corridor() -> bool:
	var mv := _obs.get_node_or_null("Multiverse") if _obs != null else null
	return mv != null and bool(mv.get("inside"))


## The lean buttons: left of the crouch arrow, beyond the stick's reach, where they fit (a phone
## held sideways); otherwise over the jump arrow and the views button.
func _layout_lean(size: Vector2, m: float, g: float, top: Rect2, bottom: Rect2, b: float) -> void:
	var w := 0.13 * _u
	var left := _stick_centre.x + _stick_radius * 1.6 + g
	var x := bottom.position.x - 2.0 * (w + g)
	if x >= left:
		_buttons["lean_l"] = Rect2(x, bottom.position.y, w, b)
		_buttons["lean_r"] = Rect2(x + w + g, bottom.position.y, w, b)
	else:
		var h := 0.11 * _u
		var y := top.position.y - g - h
		_buttons["lean_l"] = Rect2(top.position.x, y, b, h)
		_buttons["lean_r"] = Rect2(size.x - m - b, y, b, h)


## For the course card (scripts/course_library.gd), which stands above them: the top of the controls
## at the bottom of the screen.
func controls_top() -> float:
	var size := _canvas.get_viewport_rect().size
	var top := _stick_centre.y - _stick_radius
	if not _canvas.visible:
		return size.y
	for name: String in _buttons:
		if name != "courses" and name != "help":
			top = minf(top, (_buttons[name] as Rect2).position.y)
	return top


## The lift's buttons: a row between the stick and the arrows where it fits, the lowest landing at
## its left (a phone held sideways); otherwise a column over the arrows, the highest at its top.
func _layout_lift(size: Vector2, m: float, g: float, arrows: Rect2) -> void:
	var lift := _lift()
	_lift_panel = lift.call("touch_panel") if lift != null and lift.has_method("touch_panel") and not _flying() else {}
	_lift_box = Rect2()
	var items: Array = _lift_panel.get("buttons", [])
	var n := items.size()
	if n == 0:
		return
	var h := 0.11 * _u
	var left := _stick_centre.x + _stick_radius * 1.6 + g
	var right := arrows.position.x - g
	var w := minf(0.28 * _u, (right - left - (n - 1) * g) / n)
	for k in n:
		var r: Rect2
		if w >= 0.2 * _u:
			r = Rect2((left + right - n * w - (n - 1) * g) * 0.5 + k * (w + g), size.y - m - h, w, h)
		else:
			r = Rect2(size.x - m - 0.28 * _u, arrows.position.y - 2.0 * g - (k + 1) * h - k * g, 0.28 * _u, h)
		_buttons["lift_%d" % int(items[k].id)] = r
		_lift_box = r if k == 0 else _lift_box.merge(r)


func _lift() -> Node:
	return _obs.get_node_or_null("Lift") if _obs != null else null


## For the lift (scripts/lift.gd): the scale of text on this screen, and whether its buttons are on
## screen with its hint over them, so that it need not show the hint itself.
func ui_scale() -> float:
	return _scale()


func shows_lift() -> bool:
	return _canvas.visible and not _catalogue_open() and not (_lift_panel.get("buttons", []) as Array).is_empty()


func _flying() -> bool:
	return _camera != null and bool(_camera.get("_free_fly"))


func _walker() -> Node:
	return _obs.get_node_or_null("WalkBody") if _obs != null else null


func _input(event: InputEvent) -> void:
	if not _hud_visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		_shown = true
		if t.pressed:
			_press(t.index, t.position)
		else:
			_release(t.index, t.position)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_drag(d.index, d.position, d.relative)


func _press(index: int, pos: Vector2) -> void:
	var button := ""
	for name: String in _buttons:
		if name != "help" and (_buttons[name] as Rect2).grow(0.01 * _u).has_point(pos):
			button = name
	# The help after the buttons and the stick. For a moment after scripts/quality.gd scales the
	# canvas, the screen is laid out at half its size, and the help, a narrow column then, lay over
	# the curio wheel's button: a tap there put the help away, and the wheel did not open.
	var on_help: bool = _buttons.has("help") and (_buttons["help"] as Rect2).grow(0.01 * _u).has_point(pos)
	if button == "" and on_help and pos.distance_to(_stick_centre) >= _stick_radius * 1.6:
		button = "help"
	if _catalogue_open():
		# Only the close button is ours; the rest of the screen is the catalogue's.
		if button != "courses":
			return
	var curio := _curio()
	if curio != null and bool(curio.call("is_open")):
		# The wheel takes the touch: a slot holds that curio, anywhere else shuts it.
		curio.call("touch_at", pos)
		stats.buttons += 1
		get_viewport().set_input_as_handled()
		return
	var role := "look"
	var lib := _library()
	var code := str(lib.call("lang_at", pos)) if button == "" and lib != null and lib.has_method("lang_at") else ""
	var mv := _obs.get_node_or_null("Multiverse") if _obs != null else null
	if button == "" and mv != null and bool(mv.call("leave_at", pos)):
		role = "leave"
		button = "leave"
	elif code != "":
		role = "lang"
		button = code
	elif button == "help" and _help:
		pass  # a look: a drag that begins on the help still turns the view, and a tap puts it away
	elif button != "":
		role = "button"
		if button in ["up", "down"]:
			_key(KEYS[button], true)
		elif button == "jump":
			_key(KEY_SPACE, true)
		elif button == "crouch":
			_tap_key(KEY_C)
			stats.buttons += 1
	elif pos.distance_to(_stick_centre) < _stick_radius * 1.6:
		role = "stick"
	_touches[index] = {"role": role, "start": pos, "last": pos, "time": Time.get_ticks_msec(), "moved": 0.0, "button": button}
	if _help_auto and _help_left < 0.0 and button != "help":
		_help_left = HELP_TIME  # the first touch: the help goes a few seconds later
	if role == "stick":
		_steer(pos)
	elif button.begins_with("lean_"):
		stats.buttons += 1
		_sync_lean()
	get_viewport().set_input_as_handled()


func _drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if not _touches.has(index):
		index = _nearest_touch(pos)
		if index == NO_TOUCH:
			return
	var t: Dictionary = _touches[index]
	# From this touch's own last position, not the event's relative: the web platform computes that
	# from the n-th touch that changed, which is another finger's when two are down.
	var step: Vector2 = pos - t.last
	t.last = pos
	t.moved = float(t.moved) + step.length()
	match t.role:
		"stick":
			_steer(pos)
		"look":
			# Reading a spine, a drag goes along the shelf (walk_physics.gd browse); past a quarter of a
			# tap's move, its release is no tap, which would read or open the spine under the finger.
			var walker := _walker()
			if walker != null and walker.has_method("browse") and bool(walker.call("is_reading")):
				walker.call("browse", step * float(_camera.get("mouse_sensitivity")) * LOOK_GAIN)
				if float(t.moved) > TAP_MOVE * _u * 0.25:
					t.browsed = true
			else:
				var lib := _library()
				if lib != null and float(t.moved) > TAP_MOVE * _u and lib.has_method("release_aim"):
					lib.call("release_aim")
				_look(step)
	get_viewport().set_input_as_handled()


## The touch whose last position is nearest pos, within a fifth of the screen's shorter side, or
## NO_TOUCH. Only for a drag whose index is unknown: Godot's web platform passes the browser's
## touch identifiers through, and nothing here has seen them differ between press and drag, but
## an iPhone could not be tested.
func _nearest_touch(pos: Vector2) -> int:
	var best := NO_TOUCH
	var best_d := 0.2 * _u
	for i: int in _touches:
		var d := pos.distance_to(_touches[i].last)
		if d < best_d:
			best = i
			best_d = d
	return best


func _release(index: int, pos: Vector2) -> void:
	if not _touches.has(index):
		return
	var t: Dictionary = _touches[index]
	_touches.erase(index)
	match t.role:
		"stick":
			_steer(_stick_centre)
		"look":
			var quick := Time.get_ticks_msec() - int(t.time) < TAP_TIME * 1000.0
			if quick and float(t.moved) < TAP_MOVE * _u and t.button == "help":
				stats.buttons += 1
				_toggle_help()
			elif quick and float(t.moved) < TAP_MOVE * _u and not bool(t.get("browsed", false)):
				stats.taps += 1
				var mv := _obs.get_node_or_null("Multiverse") if _obs != null else null
				var lib := _library()
				var curio := _curio()
				if curio != null and bool(curio.call("holds_curio")):
					curio.call("tap_use", pos)  # a curio in hand: no book is aimed, as with a mouse
				elif mv != null and bool(mv.call("tap", pos)):
					stats.buttons += 1  # the second tap of a double tap on the box
				elif _obs != null and _obs.get_node_or_null("Hologram") != null and bool(_obs.get_node("Hologram").call("tap", pos)):
					stats.buttons += 1  # the sphere in Seldon's hands: an IX hologram
				elif _obs != null and _obs.get_node_or_null("SeldonRecording") != null and bool(_obs.get_node("SeldonRecording").call("tap", pos)):
					stats.buttons += 1  # the inscription on his pedestal: Seldon's recording
				elif _obs != null and _obs.get_node_or_null("FrescoFrieze") != null and bool(_obs.get_node("FrescoFrieze").call("tap", pos)):
					stats.buttons += 1  # a panel of the frieze: its mosaic gathers
				elif lib != null and lib.has_method("tap"):
					lib.call("tap", pos)
			else:
				stats.looks += 1
		"leave":
			var mv := _obs.get_node_or_null("Multiverse") if _obs != null else null
			if mv != null and bool(mv.call("leave_at", pos)):
				stats.buttons += 1
				mv.call("leave")
		"lang":
			# The selector's button, if the touch ends on the one it began on.
			var lib := _library()
			if lib != null and str(lib.call("lang_at", pos)) == t.button:
				stats.buttons += 1
				lib.call("set_lang", t.button)
		"button":
			var name: String = t.button
			if name in ["up", "down", "crouch"]:
				if name != "crouch":
					_key(KEYS[name], false)
			elif name == "jump":
				_key(KEY_SPACE, false)
				stats.buttons += 1
			elif name.begins_with("lean_"):
				_sync_lean()
			elif (_buttons.get(name, Rect2()) as Rect2).grow(0.03 * _u).has_point(pos):
				_activate(name)
	get_viewport().set_input_as_handled()


func _activate(name: String) -> void:
	stats.buttons += 1
	match name:
		"fly":
			_tap_key(KEY_F)
			for key in [KEY_E, KEY_C, KEY_SPACE, KEY_SHIFT]:
				_key(key, false)
		"views":
			_preset = (_preset + 1) % PRESET_KEYS.size()
			_tap_key(PRESET_KEYS[_preset])
		"ride":
			_tap_key(KEY_G)  # scripts/segway.gd gets on, or off
		"help":
			_toggle_help()
		"curios":
			var curio := _curio()
			if curio != null:
				curio.call("open_wheel")
		"courses":
			var lib := _library()
			if lib != null and lib.has_method("toggle_catalogue"):
				lib.call("toggle_catalogue")
		_:
			var lift := _lift()
			if name.begins_with("lift_") and lift != null and lift.has_method("touch_press"):
				lift.call("touch_press", int(name.trim_prefix("lift_")))


## The stick holds W, A, S and D like a keyboard: eight directions at the camera's walking speed,
## and Shift as well when the finger goes on past its rim, on foot: a thumb pushes to the rim
## anyway, so the rim itself only walks.
func _steer(pos: Vector2) -> void:
	var v := (pos - _stick_centre) / _stick_radius
	_stick = v.limit_length(1.0)
	_key(KEY_W, _stick.y < -STICK_DEAD)
	_key(KEY_S, _stick.y > STICK_DEAD)
	_key(KEY_A, _stick.x < -STICK_DEAD)
	_key(KEY_D, _stick.x > STICK_DEAD)
	_key(KEY_SHIFT, not _flying() and _walker() != null and v.length() >= STICK_SPRINT)


func _key(key: Key, down: bool) -> void:
	if bool(_held.get(key, false)) == down:
		return
	_held[key] = down
	stats.keys += 1
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = down
	Input.parse_input_event(ev)


func _tap_key(key: Key) -> void:
	_key(key, true)
	_key(key, false)


## The walking body leans the way the held lean button says; with both held, the right one.
func _sync_lean() -> void:
	var dir := 0.0
	for t: Dictionary in _touches.values():
		if t.button == "lean_r":
			dir = 1.0
		elif t.button == "lean_l" and dir == 0.0:
			dir = -1.0
	var walker := _walker()
	if walker != null and walker.has_method("touch_lean"):
		walker.call("touch_lean", dir)


## Turns the camera as its mouse look does, but directly. The first version sent a right-button
## press and mouse motions instead: that asks the browser for a pointer lock, and went through the
## camera's _unhandled_input, and on an iPhone in Safari the view did not turn at all (the user's
## report, 2026-09-29). This path uses no mouse event, no pointer lock and no GUI hit test.
func _look(step: Vector2) -> void:
	if _camera == null or step == Vector2.ZERO or not step.is_finite():
		return
	var k := float(_camera.get("mouse_sensitivity")) * LOOK_GAIN
	var yaw := float(_camera.get("_yaw")) - step.x * k
	var pitch := clampf(float(_camera.get("_pitch")) - step.y * k, -PITCH_LIMIT, PITCH_LIMIT)
	_camera.set("_yaw", yaw)
	_camera.set("_pitch", pitch)
	_camera.rotation = Vector3(pitch, yaw, 0.0)


func _draw_controls() -> void:
	var font := ThemeDB.fallback_font
	var fs := roundi(0.042 * _u)
	var open := _catalogue_open()
	if not open:
		_canvas.draw_circle(_stick_centre, _stick_radius, Color(0.05, 0.06, 0.09, 0.35))
		_canvas.draw_arc(_stick_centre, _stick_radius, 0.0, TAU, 64, Color(GILT, 0.7), maxf(2.0, 0.006 * _u), true)
		_canvas.draw_circle(_stick_centre + _stick * _stick_radius * 0.6, _stick_radius * 0.38, Color(GILT, 0.55))
	for name: String in _buttons:
		if (open and name != "courses") or name.begins_with("lift_") or (name == "help" and _help):
			continue  # the lift's buttons are drawn below, and the help panel is its own button
		var r: Rect2 = _buttons[name]
		var down := false
		for t: Dictionary in _touches.values():
			down = down or t.button == name
		var walker := _walker()
		var lit := (name == "fly" and _flying()) or (name == "crouch" and walker != null and bool(walker.call("is_crouched"))) \
			or (name == "ride" and _riding())
		var fill := Color(GILT, 0.45) if down or lit else Color(0.05, 0.06, 0.09, 0.55)
		_canvas.draw_rect(r, fill)
		_canvas.draw_rect(r, Color(GILT, 0.8), false, maxf(2.0, 0.005 * _u))
		var c := r.get_center()
		var s := r.size.y * 0.22
		match name:
			"up", "jump":
				_canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, s * 0.7), c + Vector2(-s, s * 0.7)]), GILT)
				if name == "jump":  # a bar under the arrow: off the floor
					_canvas.draw_rect(Rect2(c + Vector2(-s, s * 1.05), Vector2(2.0 * s, s * 0.22)), GILT)
			"down", "crouch":
				_canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, s), c + Vector2(s, -s * 0.7), c + Vector2(-s, -s * 0.7)]), GILT)
				if name == "crouch":  # a bar over the arrow: under a lintel
					_canvas.draw_rect(Rect2(c + Vector2(-s, -s * 1.27), Vector2(2.0 * s, s * 0.22)), GILT)
			"lean_l", "lean_r":
				_draw_lean(c, minf(r.size.x, r.size.y) * 0.24, -1.0 if name == "lean_l" else 1.0)
			"curios":
				var curio := _curio()
				var tex: Texture2D = curio.call("icon", str(curio.get("equipped"))) if curio != null else null
				if tex != null:
					_canvas.draw_texture_rect(tex, r.grow(-0.08 * r.size.x), false)
				var label := _t("curios")
				var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var at := Vector2(r.end.x + 0.02 * _u, c.y)
				_canvas.draw_rect(Rect2(at.x, at.y - fs * 0.85, w + fs * 0.8, fs * 1.7), Color(0.05, 0.06, 0.09, 0.55))
				_canvas.draw_string(font, Vector2(at.x + fs * 0.4, at.y + fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GILT)
			"help":
				var q := roundi(r.size.y * 0.6)
				var qw := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, q).x
				_canvas.draw_string(font, Vector2(c.x - qw * 0.5, c.y + q * 0.35), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, q, GILT)
			_:
				var label := _t("close" if open else "courses") if name == "courses" else _t(("walk" if _flying() else "fly") if name == "fly" else name)
				if name == "ride":
					label = _t("get_off" if _riding() else "ride")
				var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				_canvas.draw_string(font, Vector2(c.x - w * 0.5, c.y + fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.96, 0.93, 0.86))
	if not open:
		_draw_lift(font)


## A figure standing on its two legs and leaning its body and head to one side (dir -1 left, 1
## right), under an arrow curving that way.
func _draw_lean(c: Vector2, s: float, dir: float) -> void:
	var width := maxf(2.0, 0.24 * s)
	var hip := c + Vector2(-0.1 * s * dir, 0.75 * s)
	var neck := hip + Vector2(0.5 * s * dir, -0.9 * s)
	_canvas.draw_line(hip, c + Vector2(-0.45 * s, 1.55 * s), GILT, width, true)
	_canvas.draw_line(hip, c + Vector2(0.35 * s, 1.55 * s), GILT, width, true)
	_canvas.draw_line(hip, neck, GILT, width, true)
	_canvas.draw_circle(neck + (neck - hip).normalized() * 0.4 * s, 0.32 * s, GILT)
	# The arrow: an arc round the hip, from overhead towards the lean, clear of the head.
	var r := 2.35 * s
	var a0 := -PI * 0.5 - 0.1 * dir
	var a1 := -PI * 0.5 + 0.75 * dir
	_canvas.draw_arc(hip, r, minf(a0, a1), maxf(a0, a1), 12, GILT, width * 0.8, true)
	var tip := hip + Vector2(cos(a1), sin(a1)) * r
	var along := Vector2(-sin(a1), cos(a1)) * dir  # the arc's direction at its end
	var side := Vector2(-along.y, along.x)
	_canvas.draw_colored_polygon(PackedVector2Array([tip + along * 0.45 * s, tip - along * 0.15 * s + side * 0.32 * s,
		tip - along * 0.15 * s - side * 0.32 * s]), GILT)


## The lift's buttons, the landing the cage waits at outlined in gold, and the lift's hint over them
## in its own green.
func _draw_lift(font: Font) -> void:
	var items: Array = _lift_panel.get("buttons", [])
	if items.is_empty():
		return
	var fs := roundi(0.036 * _u)
	for item: Dictionary in items:
		var name := "lift_%d" % int(item.id)
		var r: Rect2 = _buttons.get(name, Rect2())
		var down := false
		for t: Dictionary in _touches.values():
			down = down or t.button == name
		var here := bool(item.here)
		_canvas.draw_rect(r, Color(GILT, 0.45) if down or bool(item.lit) else Color(0.05, 0.06, 0.09, 0.55))
		_canvas.draw_rect(r, Color(GILT, 0.95 if here else 0.8), false, maxf(2.0, (0.012 if here else 0.005) * _u))
		var label := str(item.label)
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var c := r.get_center()
		_canvas.draw_string(font, Vector2(c.x - w * 0.5, c.y + fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			GILT if here else Color(0.96, 0.93, 0.86))
	var title := str(_lift_panel.get("title", ""))
	if title == "":
		return
	var size := _canvas.get_viewport_rect().size
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pad := 0.02 * _u
	var x := clampf(_lift_box.get_center().x - tw * 0.5, pad + 0.05 * _u, size.x - 0.05 * _u - pad - tw)
	var band := Rect2(x - pad, _lift_box.position.y - 0.03 * _u - fs - pad, tw + 2.0 * pad, fs + pad)
	_canvas.draw_rect(band, Color(0.02, 0.03, 0.04, 0.72))
	_canvas.draw_rect(band, Color(0.42, 0.9, 0.55, 0.7), false, maxf(1.0, 0.002 * _u))
	_canvas.draw_string(font, Vector2(x, band.position.y + pad * 0.5 + fs * 0.85), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		Color(0.88, 1.0, 0.9))
