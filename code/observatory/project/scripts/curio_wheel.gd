extends Node
## The curio wheel: a pastiche of Wolfenstein's weapon wheel (The New Order, The New Colossus), for
## a library. Hold Tab and time slows to a quarter, the wheel opens round the screen's centre and the
## pointer (or the mouse, captured) picks a curio; let go of Tab to hold it. A click picks too. A tap
## of Tab, or a click on the wheel's button at the bottom left, leaves it open until a pick, Tab
## again or Escape. On a touch screen the wheel button opens it and a tap picks
## (scripts/touch_controls.gd).
## Held curios, used with the left button (the use button on a touch screen):
##   - bare hands: nothing; a click opens the aimed book as before;
##   - the Index, a white glove pointing: a gilt label names what it points at;
##   - a monocle: held down, the view closes in two and a half times inside its brass rim;
##   - a banker's lamp, its cord plugged into nothing: a beam that lights the way, on or off;
##   - a wooden wand that knows one spell: a puff of gilt where it points, and out of it a small
##     TARS, which lands and walks off on its own (scripts/tars.gd; 8 at most);
##   - a rubber duck: thrown, it bounces, squeaks, and stays where it lands (24 at most);
##   - an ankh: the ducks come back to life, get up and waddle home to you, the TARS walk back to
##     you, and all are gone at your feet;
##   - a pocket drone: it takes off from the hand and tours the observatory, outside too, the view
##     behind it or on board, until it lands back in the hand (scripts/drone.gd);
##   - a whistle: seven small TARS step out where it points and dance for you for seventeen seconds,
##     then bow out (scripts/tars_ensemble.gd; one troupe at a time; two numbers by turns, the
##     second a jig).
## The author asked for a wooden wand, an ankh, a pointing finger, then a monocle, a magnifier or a
## lamp, "surprising and hilarious" (2026-10-01), then the drone of a Claude artifact, and that the
## wand make small TARS, after Interstellar's, "qui marchent vraiment" (2026-10-02), then their group
## dance in the scene, out of a new curio (2026-10-03). Every model is built here from Godot's own
## meshes, every sound synthesized here; nothing is copied. The magnification goes through
## scripts/view_fit.gd (zoom), which sets the fov last. Added by scripts/observatory.gd.

const ITEMS := ["hands", "index", "monocle", "lamp", "wand", "duck", "ankh", "drone", "whistle"]
const DRONE_SCRIPT_PATH := "res://scripts/drone.gd"
const TARS_SCRIPT_PATH := "res://scripts/tars.gd"
const TROUPE_SCRIPT_PATH := "res://scripts/tars_ensemble.gd"
const WARM_LAYER := 1 << 18  # render layer: the troupe's warm-up (_warm_troupe), which the view leaves out meanwhile
const SFX_PATH := "res://scripts/sfx_takes.gd"
const MAX_TARS := 8
const TEXT := {
	"en": {"title": "CURIOS", "button": "Curios",
		"hands": ["Bare hands", "10 fingers", "Click a book to open it.", "Tap a book for its card."],
		"lamp": ["Banker's lamp", "Cord: plugged into nothing", "Lights the way. Nobody knows how."],
		"monocle": ["Monocle", "1 eye", "Hold to look closer. Makes everything more distinguished.",
			"Tap to look closer, again to stop. Makes everything more distinguished."],
		"index": ["The Index", "1 finger, extended", "Points at things. Rude, but informative."],
		"duck": ["Rubber duck", "∞ quacks", "Explain your code to it. Throw it if it disagrees."],
		"wand": ["Wooden wand", "1 spell: a small TARS", "Casts it on whatever you point at: out of the puff steps a small TARS, and walks off."],
		"ankh": ["Ankh", "∞ lives (not yours)", "Brings the ducks back to life and calls the TARS in. They come home to you."],
		"drone": ["Pocket drone", "4 rotors, 9 cm", "Tours the observatory, outside too. No licence needed: it is a curio."],
		"whistle": ["Whistle", "7 TARS, 17 seconds", "Blow it where you point: seven TARS dance for you, a jig every other time, then bow out. Applause optional."],
		"names": {"pier": "A pier. Load-bearing, opinion-bearing.",
			"statue": "Hari Seldon, 11988–12069 G.E. He predicted you would point.",
			"pedestal": "The pedestal. Seldon's, not yours.",
			"steel": "The steel box. Double-click it. Or don't: it knows.",
			"door": "A door. It opens; you don't.",
			"lift": "The lift. Not a weapon.",
			"shelves": "Decorative books. Nobody has read them, not even the author.",
			"floor": "Marble, in rings. Slippery when Seldon.",
			"gallery": "A gallery. Further up, more books.",
			"dome": "The dome. Pointing at it does not make it higher.",
			"duck": "A duck. It has heard everything.",
			"tars": "TARS, small. Humour setting: 75 %.",
			"troupe": "A troupe of TARS. Rehearsals: none. Humour setting: 75 %, times seven."}},
	"fr": {"title": "CURIOSITÉS", "button": "Curiosités",
		"hands": ["Mains nues", "10 doigts", "Clique sur un livre pour l'ouvrir.", "Touche un livre pour sa fiche."],
		"lamp": ["Lampe de banquier", "Fil : branché nulle part", "Éclaire le chemin. Personne ne sait comment."],
		"monocle": ["Monocle", "1 œil", "Maintiens pour voir de plus près. Rend tout plus distingué.",
			"Touche pour voir de plus près, encore pour arrêter. Rend tout plus distingué."],
		"index": ["L'Index", "1 doigt, tendu", "Montre les choses du doigt. Malpoli, mais instructif."],
		"duck": ["Canard en caoutchouc", "∞ coin-coin", "Explique-lui ton code. Lance-le s'il n'est pas d'accord."],
		"wand": ["Baguette de bois", "1 sort : un petit TARS", "Le lance sur ce que tu vises : du nuage sort un petit TARS, qui part marcher."],
		"ankh": ["Ânkh", "∞ vies (pas les tiennes)", "Ramène les canards à la vie et rappelle les TARS. Ils reviennent vers toi."],
		"drone": ["Drone de poche", "4 rotors, 9 cm", "Fait le tour de l'observatoire, dehors aussi. Sans permis : c'est une curiosité."],
		"whistle": ["Sifflet", "7 TARS, 17 secondes", "Siffle là où tu vises : sept TARS dansent pour toi, une gigue une fois sur deux, puis saluent. Applaudissements facultatifs."],
		"names": {"pier": "Un pilier. Porte la voûte, et des opinions.",
			"statue": "Hari Seldon, 11988–12069 È.G. Il avait prédit que tu le montrerais du doigt.",
			"pedestal": "Le socle. Celui de Seldon, pas le tien.",
			"steel": "Le coffre d'acier. Double-clique dessus. Ou pas : il le sait.",
			"door": "Une porte. Elle s'ouvre ; toi, non.",
			"lift": "L'ascenseur. Pas une arme.",
			"shelves": "Des livres décoratifs. Personne ne les a lus, pas même l'auteur.",
			"floor": "Du marbre, en anneaux. Glissant quand il y a du Seldon.",
			"gallery": "Une galerie. Plus haut, plus de livres.",
			"dome": "La coupole. La montrer du doigt ne la rend pas plus haute.",
			"duck": "Un canard. Il a tout entendu.",
			"tars": "Un petit TARS. Réglage d'humour : 75 %.",
			"troupe": "Une troupe de TARS. Répétitions : aucune. Réglage d'humour : 75 %, fois sept."}},
	"es": {"title": "CURIOSIDADES", "button": "Curiosidades",
		"hands": ["Manos vacías", "10 dedos", "Haz clic en un libro para abrirlo.", "Toca un libro para ver su ficha."],
		"lamp": ["Lámpara de banquero", "Cable: enchufado a nada", "Ilumina el camino. Nadie sabe cómo."],
		"monocle": ["Monóculo", "1 ojo", "Mantén para ver de cerca. Todo parece más distinguido.",
			"Toca para ver de cerca, otra vez para parar. Todo parece más distinguido."],
		"index": ["El Índice", "1 dedo, estirado", "Señala las cosas. De mala educación, pero instructivo."],
		"duck": ["Pato de goma", "∞ cuacs", "Explícale tu código. Lánzalo si no está de acuerdo."],
		"wand": ["Varita de madera", "1 hechizo: un pequeño TARS", "Lo lanza a lo que apuntes: de la nube sale un pequeño TARS, que se va andando."],
		"ankh": ["Anj", "∞ vidas (no las tuyas)", "Devuelve la vida a los patos y llama a los TARS. Vuelven hacia ti."],
		"drone": ["Dron de bolsillo", "4 rotores, 9 cm", "Recorre el observatorio, también por fuera. Sin licencia: es una curiosidad."],
		"whistle": ["Silbato", "7 TARS, 17 segundos", "Sopla donde apuntes: siete TARS bailan para ti, una giga una vez de cada dos, y se despiden. Aplausos opcionales."],
		"names": {"pier": "Un pilar. Sostiene la bóveda, y opiniones.",
			"statue": "Hari Seldon, 11988–12069 E.G. Predijo que lo señalarías.",
			"pedestal": "El pedestal. El de Seldon, no el tuyo.",
			"steel": "La caja de acero. Haz doble clic. O no: ella lo sabe.",
			"door": "Una puerta. Ella se abre; tú no.",
			"lift": "El ascensor. No es un arma.",
			"shelves": "Libros decorativos. Nadie los ha leído, ni siquiera el autor.",
			"floor": "Mármol, en anillos. Resbala cuando hay Seldon.",
			"gallery": "Una galería. Más arriba, más libros.",
			"dome": "La cúpula. Señalarla no la hace más alta.",
			"duck": "Un pato. Lo ha oído todo.",
			"tars": "Un pequeño TARS. Nivel de humor: 75 %.",
			"troupe": "Una compañía de TARS. Ensayos: ninguno. Nivel de humor: 75 %, por siete."}},
}
const GILT := Color(0.86, 0.7, 0.42)
const LACQUER := Color(0.035, 0.03, 0.028, 0.92)
const SLOW := 0.25          # Engine.time_scale while the wheel is open
const MONOCLE_ZOOM := 0.4   # view_fit.gd zoom held down: 2.5 times closer
const MAX_DUCKS := 24
const LABEL_TIME := 3.5     # seconds a label stays
const HELD_SCALE := 0.6      # held models, of their size in the wheel's icons
const SHELF_R := 17.14      # the shelves' front, from the hall's centre
## A press of Tab shorter than this, in seconds, leaves the wheel open: held, it shuts on release as in the game.
## The author, who pressed Tab, did not see the wheel (2026-10-02): it had opened and shut at once.
const TAP := 0.3

var lang := "en"
## Counts for tests.
var stats := {"opens": 0, "equips": 0, "uses": 0, "ducks": 0, "labels": 0, "squeaks": 0, "spells": 0,
	"revivals": 0, "quacks": 0, "home": 0, "tars": 0, "tars_home": 0, "clanks": 0, "whistles": 0, "troupes": 0,
	"troupes_done": 0, "troupe_refused": 0}
var equipped := "hands"
var reduced_motion := false

var _obs: Node
var _camera: Camera3D
var _open := false
var _sticky := false        # opened by a tap of Tab or by the button: stays open until a pick
var _tab_at := 0.0          # _time when Tab went down: unscaled scene time, as tests step it
var _open_t := 0.0          # 0 shut .. 1 open, eased in real time
var _button: Control        # on a computer: the wheel's button, bottom left
var _button_hover := false
var _pick := 0
var _aim := Vector2.ZERO    # the captured mouse's motion since the wheel opened
var _layer: CanvasLayer
var _wheel: Control
var _monocle_rim: ColorRect
var _hold: Node3D           # the held curio, a child of the camera
var _models := {}           # id -> Node3D, held
var _icons := {}            # id -> Texture2D
var _raise := 0.0           # 0 lowered out of sight .. 1 held up
var _use_kick := 0.0        # the jab of a use, decaying
var _blown := 0.0           # seconds the whistle stays up after a blow, then lowered while its troupe dances
var _sway := Vector2.ZERO
var _last_look := Vector2.INF
var _time := 0.0
var _lamp_on := false
var _lamp_light: SpotLight3D
var _zoom := 1.0
var _zoom_held := false
var _ducks: Array = []      # {node, v, spin, resting, waddle, t}
var _robots: Array = []     # the wand's TARS (scripts/tars.gd), oldest first
var _tars_script: Script
var _troupe: Node3D         # the whistle's troupe while it dances (scripts/tars_ensemble.gd)
var _troupe_script: Script
var _troupe_number := 0     # the whistle's next number: 0 the first dance, 1 the jig, by turns
var _troupe_keep: Array = []  # both baked dances, and the warmed troupe's materials and puff's (_warm_troupe)
var _warm_in := 5           # frames before the troupe is warmed up, or -1 once it is (or never is)
var _warm := {}             # the warm-up's troupe, puff and viewport while they are drawn, and its frames left
var _framing := {}          # the view's tilt towards a troupe that has just come: from, to, t, set
var _ankh_glow := 0.0       # 1 at a use, fading
var _aim_at := Vector2.INF  # a tap on a touch screen, which the use aims at
var _labels: Array = []     # {node, t}
var _rng := RandomNumberGenerator.new()
var _sounds := {}           # name -> AudioStreamWAV
var _sfx: Script            # scripts/sfx_takes.gd, once _make_sounds has run
var _player: AudioStreamPlayer
var _mats := {}


func configure(observatory: Node, camera: Camera3D) -> void:
	_obs = observatory
	_camera = camera


func _ready() -> void:
	process_priority = 860  # after the walking body, before view_fit.gd (900), which reads zoom
	_rng.seed = 1789
	reduced_motion = OS.get_cmdline_user_args().has("--reduced-motion")
	if OS.has_feature("web") and not Engine.is_editor_hint():
		reduced_motion = reduced_motion or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	_make_materials()
	_make_sounds()
	_hold = Node3D.new()
	_hold.name = "HeldCurio"
	if _camera != null:
		_camera.add_child(_hold)
	for id: String in ITEMS:
		var m := _build(id)
		m.scale = Vector3.ONE * float(m.get_meta("held_scale", HELD_SCALE))
		m.visible = false
		_hold.add_child(m)
		_models[id] = m
	_make_ui()
	_make_icons()


func _exit_tree() -> void:
	if _open:
		Engine.time_scale = 1.0
	_set_zoom(1.0)


## Whether a curio other than bare hands is held: a click uses it rather than opening a book
## (scripts/course_library.gd asks).
func holds_curio() -> bool:
	return equipped != "hands"


func is_open() -> bool:
	return _open


func _t(key: String) -> Variant:
	return TEXT.get(lang, TEXT.en).get(key, TEXT.en[key])


func _library() -> Node:
	return _obs.get_node_or_null("Generated/CourseShelves") if _obs != null else null


func _walker() -> Node:
	return _obs.get_node_or_null("WalkBody") if _obs != null else null


# --- Wheel ----------------------------------------------------------------------

func open_wheel() -> void:
	if _open:
		return
	_open = true
	_aim = Vector2.ZERO
	_pick = ITEMS.find(equipped)
	Engine.time_scale = SLOW
	stats.opens += 1
	_play("whoosh", 0.0)


## Closes the wheel and holds the curio it points at.
func close_wheel() -> void:
	if not _open:
		return
	_open = false
	_sticky = false
	Engine.time_scale = 1.0
	equip(ITEMS[_pick])


## Opens the wheel to stay open (a tap of Tab, the button), or shuts it holding what it points at.
func toggle_wheel() -> void:
	if _open:
		close_wheel()
	else:
		open_wheel()
		_sticky = true


func equip(id: String) -> void:
	if not id in ITEMS:
		return
	if id != equipped:
		stats.equips += 1
		_use(false)
		if equipped == "lamp":
			_lamp_switch(false)
		equipped = id
		_raise = 0.0
		_play("tock", -6.0)


## A touch on the open wheel (scripts/touch_controls.gd): on a slot, it holds that curio; anywhere
## else, the wheel shuts on the one held. Returns whether the wheel was open.
func touch_at(pos: Vector2) -> bool:
	if not _open:
		return false
	var v := pos - _centre()
	if v.length() > _inner() and v.length() < _outer() * 1.15:
		_pick = _slot(v)
	else:
		_pick = ITEMS.find(equipped)
	close_wheel()
	return true


func _centre() -> Vector2:
	return _wheel.get_viewport_rect().size * 0.5 if _wheel != null else Vector2.ZERO


func _outer() -> float:
	var size := _wheel.get_viewport_rect().size if _wheel != null else Vector2(800, 600)
	return (0.44 if size.x < size.y else 0.36) * minf(size.x, size.y)  # larger on a phone held upright


func _inner() -> float:
	return _outer() * 0.44


func _slot(v: Vector2) -> int:
	var n := ITEMS.size()
	var a := atan2(v.y, v.x) + PI * 0.5
	return posmod(roundi(a / (TAU / n)), n)


func _input(event: InputEvent) -> void:
	if not _hud_visible():
		return
	var key := event as InputEventKey
	if key != null and not key.echo:
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_TAB:
			if key.pressed:
				if _open and _sticky:
					close_wheel()
				elif not _open:
					open_wheel()
					_tab_at = _time
			elif _open and not _sticky:
				if _time - _tab_at < TAP:
					_sticky = true
				else:
					close_wheel()
			get_viewport().set_input_as_handled()
			return
		if code == KEY_ESCAPE and key.pressed and _open:
			# Shut, holding what was held.
			_pick = ITEMS.find(equipped)
			close_wheel()
			get_viewport().set_input_as_handled()
			return
	# The button, on a computer, while the pointer is free.
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT and _button_shown() \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and _button_rect().has_point(press.position):
		if _open:
			_pick = ITEMS.find(equipped)
		toggle_wheel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _button_shown():
		var over := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and _button_rect().has_point((event as InputEventMouseMotion).position)
		if over != _button_hover:
			_button_hover = over
			_button.queue_redraw()
	if _open:
		if event is InputEventMouseMotion:
			var mm := event as InputEventMouseMotion
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_aim = (_aim + mm.relative).limit_length(_outer())
				if _aim.length() > _inner() * 0.6:
					_pick = _slot(_aim)
			else:
				var v := mm.position - _centre()
				if v.length() > _inner() * 0.6:
					_pick = _slot(v)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				var v := (event as InputEventMouseButton).position - _centre()
				if v.length() > _inner() * 0.6:
					_pick = _slot(v)
			close_wheel()
			get_viewport().set_input_as_handled()
		return
	# The left button uses the held curio, once the mouse looks (the first click captures it).
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and holds_curio() \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		use(mb.pressed)
		get_viewport().set_input_as_handled()


func _hud_visible() -> bool:
	var hud := _camera.get_parent().get_node_or_null("ControlsHud") if _camera != null else null
	return hud == null or bool(hud.get("visible"))


# --- Using ----------------------------------------------------------------------

## The held curio, used (down) or let go: the lamp switches, the monocle closes in while held, the
## Index names what it points at, the duck is thrown.
func use(down: bool) -> void:
	if _open or not holds_curio():
		return
	if down:
		stats.uses += 1
		_use_kick = 1.0
	match equipped:
		"lamp":
			if down:
				_lamp_switch(not _lamp_on)
		"monocle":
			_zoom_held = down
			if down:
				_play("tock", -14.0)
		"index":
			if down:
				_point()
		"duck":
			if down:
				_throw()
		"wand":
			if down:
				_cast()
		"ankh":
			if down:
				_revive()
		"drone":
			if down:
				_launch()
		"whistle":
			if down:
				_whistle()


## The drone takes off from the hand (scripts/drone.gd), which refuses in the corridor and says why.
func _launch() -> void:
	var drone := _drone()
	if drone != null:
		drone.call("launch", (_models.drone as Node3D).global_transform)


func _drone() -> Node:
	return _obs.get_node_or_null("Drone") if _obs != null else null


func _use(down: bool) -> void:
	_zoom_held = down and _zoom_held


## A tap with a curio held, on a touch screen (scripts/touch_controls.gd): used there; the monocle
## and the lamp switch on and off.
func tap_use(pos: Vector2) -> void:
	if _open or not holds_curio():
		return
	_aim_at = pos
	if equipped == "monocle":
		use(not _zoom_held)
	else:
		use(true)
		use(false)
	_aim_at = Vector2.INF


## Where the held curio aims: a touch's tap, the screen's centre when the mouse looks, else the
## pointer.
func _ray() -> Array:
	var vp := _camera.get_viewport()
	var at := vp.get_visible_rect().size * 0.5
	if _aim_at != Vector2.INF:
		at = _aim_at
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not _touch():
		at = vp.get_mouse_position()
	return [_camera.project_ray_origin(at), _camera.project_ray_normal(at)]


## Each curio's picture, for the touch controls' button.
func icon(id: String) -> Texture2D:
	return _icons.get(id)


func _touch() -> bool:
	return _obs != null and _obs.get_node_or_null("TouchControls") != null


func _lamp_switch(on: bool) -> void:
	_lamp_on = on
	if _lamp_light != null:
		_lamp_light.visible = on
	var shade: MeshInstance3D = _models.lamp.get_node_or_null("Shade") if _models.has("lamp") else null
	if shade != null:
		(shade.material_override as StandardMaterial3D).emission_energy_multiplier = 1.4 if on else 0.0
	var bulb: MeshInstance3D = _models.lamp.get_node_or_null("Bulb") if _models.has("lamp") else null
	if bulb != null:
		(bulb.material_override as StandardMaterial3D).emission_energy_multiplier = 4.0 if on else 0.0
	_play("click", -4.0)


func _set_zoom(z: float) -> void:
	var fit := _obs.get_node_or_null("ViewFit") if _obs != null else null
	if fit != null:
		fit.set("zoom", z)


# --- The Index ------------------------------------------------------------------

## Names what the ray from the screen meets first and pins a gilt label there.
func _point() -> void:
	var r := _ray()
	var hit := what_is(r[0], r[1])
	_play("tock", -2.0)
	if hit.is_empty():
		return
	stats.labels += 1
	var label := Label3D.new()
	label.text = "☞ " + str(hit.text)
	label.font_size = 40
	label.pixel_size = 0.0009  # the same size on the screen near and far
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.modulate = GILT
	label.outline_modulate = Color(0.04, 0.03, 0.02, 0.9)
	label.outline_size = 10
	label.width = 900.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.render_priority = 10
	_obs.add_child(label)
	label.global_position = (hit.point as Vector3) - (r[1] as Vector3) * 0.05
	_labels.append({"node": label, "t": LABEL_TIME})
	while _labels.size() > 6:
		(_labels.pop_front().node as Node).queue_free()


## What a ray meets first in the hall: {kind, text, point, distance}, or {}. The course books by
## their boxes (course_library.gd), the steel box, the door leaf, the piers, the pedestal and the
## statue by their meshes' boxes, the lift's shaft as a cylinder, a thrown duck as a ball, then the
## shelves' front, the galleries' and the hall's floors, and the dome.
func what_is(from: Vector3, dir: Vector3) -> Dictionary:
	var names: Dictionary = _t("names")
	var best := {}
	var best_t := 60.0
	var lib := _library()
	if lib != null:
		var books: Array = lib.get("_books")
		for i in books.size():
			var inv: Transform3D = (books[i].xf as Transform3D).affine_inverse()
			var t := _ray_box(inv * from, inv.basis * dir, Vector3(0.5, 0.5, 0.5))
			if t >= 0.0 and t < best_t:
				best_t = t
				best = {"kind": "book", "text": str(lib.call("_in_lang", books[i].course.get("title", "")))}
	if _obs != null:
		for n in _obs.find_children("*", "MeshInstance3D", true, false):
			var m := n as MeshInstance3D
			var kind := _kind_of(m)
			if kind == "" or m.mesh == null or not m.is_visible_in_tree():
				continue
			var inv := m.global_transform.affine_inverse()
			var aabb := m.mesh.get_aabb()
			var t := _ray_box(inv * from - aabb.get_center(), inv.basis * dir, aabb.size * 0.5)
			if t >= 0.0:
				t = ((m.global_transform * (inv * from + inv.basis * dir * t)) - from).length()
				if t < best_t:
					best_t = t
					best = {"kind": kind, "text": names.get(kind, kind)}
		var lift := _obs.get_node_or_null("Lift")
		if lift != null:
			var c: Vector2 = lift.call("centre")
			var t := _ray_cylinder(Vector2(from.x, from.z) - c, Vector2(dir.x, dir.z), 1.0)
			if t >= 0.0 and t < best_t:
				best_t = t
				best = {"kind": "lift", "text": names.lift}
	for d: Dictionary in _ducks:
		var p: Vector3 = (d.node as Node3D).global_position
		var along := (p - from).dot(dir)
		if along > 0.0 and along < best_t and (from + dir * along).distance_to(p) < 0.07:
			best_t = along
			best = {"kind": "duck", "text": names.duck}
	for robot: Node in _robots:
		if not is_instance_valid(robot):
			continue
		var b: Array = robot.call("bounds")
		var inv := (b[0] as Transform3D).affine_inverse()
		var t := _ray_box(inv * from, inv.basis * dir, b[1])
		if t >= 0.0 and t < best_t:
			best_t = t
			best = {"kind": "tars", "text": names.tars}
	if _troupe != null and is_instance_valid(_troupe):
		for b: Array in _troupe.call("bounds_list"):
			var inv := (b[0] as Transform3D).affine_inverse()
			var t := _ray_box(inv * from, inv.basis * dir, b[1])
			if t >= 0.0 and t < best_t:
				best_t = t
				best = {"kind": "troupe", "text": names.get("troupe", names.tars)}
	# The room itself: the shelves' front, the floors, the dome.
	var flat := Vector2(dir.x, dir.z)
	var t_wall := _ray_cylinder_inside(Vector2(from.x, from.z), flat, SHELF_R)
	if t_wall > 0.0 and t_wall < best_t:
		best_t = t_wall
		best = {"kind": "shelves", "text": names.shelves}
	if dir.y < -1e-4:
		var floors: Array[float] = [0.0]
		var levels = _obs.get("gallery_levels") if _obs != null else null
		if levels is PackedFloat32Array:
			for g in levels:
				if g < from.y:
					floors.append(g)
		for f in floors:
			var t := (f - from.y) / dir.y
			var at := from + dir * t
			var r := Vector2(at.x, at.z).length()
			var on_gallery := f > 0.0 and r > SHELF_R - 3.4 and r < SHELF_R
			if t > 0.0 and t < best_t and (f == 0.0 or on_gallery):
				best_t = t
				best = {"kind": "floor" if f == 0.0 else "gallery", "text": names.floor if f == 0.0 else names.gallery}
	if best.is_empty() and dir.y > 0.2:
		best_t = 20.0
		best = {"kind": "dome", "text": names.dome}
	if best.is_empty():
		return {}
	best.point = from + dir * best_t
	best.distance = best_t
	return best


## The Index's name for a mesh of the hall, by its node's name or its parents', or "".
func _kind_of(m: MeshInstance3D) -> String:
	var id := String(m.name)
	if id.begins_with("Pier") and id.trim_prefix("Pier").is_valid_int():
		return "pier"
	if id == "Pedestal":
		return "pedestal"
	if id == "DoorLeaf":
		return "door"
	var p := m.get_parent()
	while p != null and p != _obs:
		var pid := String(p.name)
		if pid == "SeldonStatue":
			return "statue"
		if pid == "SteelCube":
			return "steel"
		p = p.get_parent()
	return ""


static func _ray_box(o: Vector3, d: Vector3, half: Vector3) -> float:
	var t0 := -INF
	var t1 := INF
	for axis in 3:
		if absf(d[axis]) < 1e-8:
			if absf(o[axis]) > half[axis]:
				return -1.0
			continue
		var a := (-half[axis] - o[axis]) / d[axis]
		var b := (half[axis] - o[axis]) / d[axis]
		t0 = maxf(t0, minf(a, b))
		t1 = minf(t1, maxf(a, b))
	if t1 < maxf(t0, 0.0):
		return -1.0
	return maxf(t0, 0.0)


## A ray (flat origin o, flat direction d of a unit 3D direction) into a vertical cylinder of radius
## r round the origin, from outside: the 3D distance to it, or -1.
static func _ray_cylinder(o: Vector2, d: Vector2, r: float) -> float:
	var a := d.length_squared()
	if a < 1e-8:
		return -1.0
	var b := o.dot(d)
	var c := o.length_squared() - r * r
	var disc := b * b - a * c
	if disc < 0.0 or c < 0.0:
		return -1.0
	var t := (-b - sqrt(disc)) / a
	return t if t > 0.0 else -1.0


## The same from inside: where the ray leaves the cylinder.
static func _ray_cylinder_inside(o: Vector2, d: Vector2, r: float) -> float:
	var a := d.length_squared()
	if a < 1e-8:
		return -1.0
	var b := o.dot(d)
	var c := o.length_squared() - r * r
	var disc := b * b - a * c
	if disc < 0.0:
		return -1.0
	return (-b + sqrt(disc)) / a


# --- The duck -------------------------------------------------------------------

func _throw() -> void:
	var r := _ray()
	var dir: Vector3 = r[1]
	_add_duck(_camera.global_position + dir * 0.35 + Vector3(0, -0.12, 0), dir * 7.5 + Vector3(0, 2.2, 0), dir)
	_play("whoosh", -10.0)


## `size` scales the duck, 1 for a rubber duck about 11 cm long.
func _add_duck(at: Vector3, v: Vector3, facing: Vector3, size := 1.0) -> void:
	var duck := _build_duck()
	_obs.add_child(duck)
	duck.global_position = at
	duck.look_at(at + Vector3(facing.x, 0.0, facing.z) + Vector3(0, 0.0001, 0), Vector3.UP)
	duck.scale = Vector3.ONE * size
	_ducks.append({"node": duck, "v": v, "spin": _rng.randf_range(-6.0, 6.0), "resting": false, "waddle": false, "t": 0.0,
		"size": size})
	stats.ducks += 1
	while _ducks.size() > MAX_DUCKS:
		(_ducks.pop_front().node as Node).queue_free()


## The wand's one spell: a puff of gilt where it points (within 12 m, else 4 m ahead), and out of
## it, facing you, a small TARS (scripts/tars.gd), which drops to the floor and walks off. Both grow
## a little with the distance: on a phone, a rubber duck's 11 cm at the steel box, 7.7 m from the
## hall's entrance, were 5 pixels (artpass/publish/curio-web.mjs); a TARS, 36 cm tall, is up to
## twice that. The oldest goes when there are more than MAX_TARS.
func _cast() -> void:
	var r := _ray()
	var from: Vector3 = r[0]
	var dir: Vector3 = r[1]
	var hit := what_is(from, dir)
	var reach := 4.0
	if not hit.is_empty() and float(hit.distance) <= 12.0:
		reach = maxf(float(hit.distance), 0.6)
	var at := from + dir * (reach - 0.15)
	var far := (at - from).length()
	stats.spells += 1
	_sparkle(at, GILT, maxf(1.0, far / 1.5))
	_play("spell", -3.0)
	_add_tars(at, -dir, clampf(far / 5.0, 1.0, 2.0))


func _add_tars(at: Vector3, facing: Vector3, size: float) -> Node3D:
	if _tars_script == null:
		_tars_script = load(TARS_SCRIPT_PATH)
	var robot: Node3D = _tars_script.new()
	robot.call("configure", self, at, facing, size, _rng.randi())
	_obs.add_child(robot)
	_robots.append(robot)
	stats.tars += 1
	while _robots.size() > MAX_TARS:
		var old: Node = _robots.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	return robot


## A TARS called home has reached you (scripts/tars.gd): a green sparkle, two beeps, and it is gone.
func _tars_home(robot: Node3D) -> void:
	if not _robots.has(robot):
		return
	_robots.erase(robot)
	stats.tars_home += 1
	var feet: Array = robot.call("feet")
	var at: Vector3 = (feet[0] as Vector3).lerp(feet[3] as Vector3, 0.5) + Vector3(0, 0.15 * float(robot.get("size")), 0)
	# How far from you the furthest arrived: one that gave up on the way (scripts/tars.gd, 20 s) shows.
	var h := _home()
	stats.tars_home_far = maxf(float(stats.get("tars_home_far", 0.0)), Vector2(at.x - h.x, at.z - h.z).length())
	_sparkle(at, Color(0.55, 0.95, 1.0))
	_sound_at("beep", at, 0.8)
	robot.queue_free()


## The whistle: seven small TARS on your floor where it points, facing you, dance for seventeen
## seconds and bow out (scripts/tars_ensemble.gd). Their stage is 3 to 6 m ahead along the aim, the
## troupe bigger further off: 1.5 to 2 times the wand's TARS (54 to 72 cm), as the author asked for
## them a little bigger (2026-10-03); where the whole dance would not fit (an edge, a step, the steel
## box, the lift, the shelves, the corridor), nearer, then smaller; nowhere, a grey puff and nobody
## comes. One troupe at a time: blown during a dance, it is only a whistle. While its troupe dances,
## the whistle is lowered out of sight after each blow (_hold_pose): held up, it stood over the
## framed troupe's rightmost robot on a computer. The first dance and the jig come by turns; a number
## with no room is asked for again next time.
func _whistle() -> void:
	stats.whistles += 1
	_blown = 0.6
	_play("whistle", -4.0)
	if _troupe != null and is_instance_valid(_troupe):
		return
	if _troupe_script == null:
		_troupe_script = load(TROUPE_SCRIPT_PATH)
	var r := _ray()
	var from: Vector3 = r[0]
	var dir: Vector3 = r[1]
	var ahead := Vector3(dir.x, 0.0, dir.z)
	if ahead.length() < 0.05:
		ahead = -_camera.global_basis.z  # looking straight down: ahead of the view
		ahead.y = 0.0
	ahead = ahead.normalized()
	var hit := what_is(from, dir)
	var d := 3.5
	if not hit.is_empty() and float(hit.distance) <= 12.0:
		var p: Vector3 = hit.point
		d = Vector2(p.x - from.x, p.z - from.z).length()
	var walker := _walker()
	var yours := 0.0  # the floor you stand on
	if walker != null and walker.has_method("_support"):
		yours = float(walker.call("_support", Vector2(from.x, from.z), from.y - 0.3))
	var reach := float(_troupe_script.call("reach", _troupe_number))
	for s: float in [clampf(d / 2.2, 1.5, 2.0), 1.4, 1.0]:
		var near := reach * s + 0.6
		var dd := clampf(d, near, 6.0)
		while dd >= near - 1e-3:
			var c := from + ahead * dd
			var y := yours
			if walker != null and walker.has_method("_support"):
				y = float(walker.call("_support", Vector2(c.x, c.z), from.y - 0.3))
			if absf(y - yours) < 0.05:
				var troupe: Node3D = _troupe_script.new()
				troupe.call("configure", self, Vector3(c.x, y, c.z), from, s, _troupe_number)
				if bool(troupe.call("fits")):
					_obs.add_child(troupe)
					_troupe = troupe
					stats.troupes += 1
					_troupe_number = (_troupe_number + 1) % 2
					_sparkle(Vector3(c.x, y + 0.3 * s, c.z), GILT, 2.0 * s)
					_frame_troupe(troupe)
					return
				troupe.free()
			dd -= 0.6
	stats.troupe_refused += 1
	_sparkle(from + dir * 2.0, Color(0.55, 0.55, 0.58), 0.8)


## A troupe that has just come is framed. The start view looks up at the oculus: from it, a troupe on the
## floor ahead stood under the screen's foot, or a phone's stick and buttons hid half of it (artpass/
## tarsdance/NOTES.md, "Version 36"). Unless every ground its dance covers, from the floor to a robot's
## hop, is already between the screen's top and the controls under it (the screen's foot without them),
## and inside its sides, the view turns onto the dance's middle and tilts until its near edge stands just
## above the controls under it (on a phone held sideways, with the dance in the middle, none are: the
## screen's foot), above the screen's foot where there is no room above them, in the screen's middle
## where the dance is taller than the screen. It takes 0.9 s, a look of the visitor's own stops it, and
## with less motion it is a cut.
func _frame_troupe(troupe: Node3D) -> void:
	if troupe == null or not troupe.has_method("extent"):
		return
	var screen := _camera.get_viewport().get_visible_rect().size
	if screen.y < 2.0:
		return
	var fit := _obs.get_node_or_null("ViewFit")
	var fov := _camera.fov
	if fit != null and fit.has_method("fitted"):
		fov = float(fit.call("fitted", fov))
	var t := tan(deg_to_rad(fov) * 0.5)
	var points: PackedVector3Array = troupe.call("extent")
	var pitch := float(_camera.get("_pitch"))
	var yaw := float(_camera.get("_yaw"))
	var roll := _camera.rotation.z
	var top := 0.08 * screen.y
	var left := 0.03 * screen.x
	var right := 0.97 * screen.x
	var box := _box_at(points, pitch, yaw, roll, t, screen)
	var bottom := _controls_top(box, screen)
	if box.position.y >= top and box.end.y <= bottom and box.position.x >= left and box.end.x <= right:
		return
	var p := pitch
	var y := yaw
	for _i in 2:
		y = _yaw_for(points, p, y, roll, t, screen, 0.5 * screen.x)
		box = _box_at(points, p, y, roll, t, screen)
		bottom = _controls_top(box, screen)
		p = _pitch_for(points, y, roll, t, screen, bottom - 0.02 * screen.y, false)
		box = _box_at(points, p, y, roll, t, screen)
		if box.position.y < top:  # no room above the controls: above the screen's foot
			bottom = 0.92 * screen.y
			p = _pitch_for(points, y, roll, t, screen, bottom - 0.02 * screen.y, false)
			box = _box_at(points, p, y, roll, t, screen)
			if box.position.y < top:  # taller than the screen: in its middle
				p = _pitch_for(points, y, roll, t, screen, 0.5 * (top + bottom), true)
	if absf(p - pitch) < 0.01 and absf(angle_difference(yaw, y)) < 0.01:
		return
	_framing = {"from": Vector2(pitch, yaw), "to": Vector2(p, y), "t": 1.0 if reduced_motion else 0.0,
		"set": Vector2(pitch, yaw)}
	_tilt(0.0)


## The screen box of these points, with the camera here turned to (pitch, yaw, roll); a point behind it
## stands far under the screen.
func _box_at(points: PackedVector3Array, pitch: float, yaw: float, roll: float, t: float, screen: Vector2) -> Rect2:
	var inv := Basis.from_euler(Vector3(pitch, yaw, roll)).inverse()
	var at := _camera.global_position
	var aspect := screen.x / screen.y
	var box := Rect2()
	for k in points.size():
		var c := inv * (points[k] - at)
		var q := Vector2(0.5 * screen.x, 10.0 * screen.y)
		if c.z < -0.05:
			q = Vector2((0.5 + 0.5 * c.x / (-c.z * t * aspect)) * screen.x, (0.5 - 0.5 * c.y / (-c.z * t)) * screen.y)
		box = Rect2(q, Vector2.ZERO) if k == 0 else box.expand(q)
	return box


## The pitch that puts the box's foot (or, middle, its centre) at this height on the screen: the higher
## the view looks, the lower everything stands on it.
func _pitch_for(points: PackedVector3Array, yaw: float, roll: float, t: float, screen: Vector2, y: float, middle: bool) -> float:
	var lo := -1.45
	var hi := 1.45
	for i in 24:
		var mid := 0.5 * (lo + hi)
		var box := _box_at(points, mid, yaw, roll, t, screen)
		if (box.get_center().y if middle else box.end.y) > y:
			hi = mid
		else:
			lo = mid
	return 0.5 * (lo + hi)


## The yaw that puts the box's centre at x on the screen: the further left the view turns, the further
## right everything stands on it.
func _yaw_for(points: PackedVector3Array, pitch: float, yaw: float, roll: float, t: float, screen: Vector2, x: float) -> float:
	var lo := yaw - 1.0
	var hi := yaw + 1.0
	for i in 24:
		var mid := 0.5 * (lo + hi)
		var box := _box_at(points, pitch, mid, roll, t, screen)
		if box.get_center().x > x:
			hi = mid
		else:
			lo = mid
	return 0.5 * (lo + hi)


## How far down the screen the box may reach: the top of the highest touch control under it
## (scripts/touch_controls.gd, the stick's square, the curio button with its name), else near the foot.
func _controls_top(box: Rect2, screen: Vector2) -> float:
	var out := 0.92 * screen.y
	var tc := _obs.get_node_or_null("TouchControls")
	if tc == null:
		return out
	var rects: Array = []
	var buttons = tc.get("_buttons")
	if buttons is Dictionary:
		for name: String in buttons:
			if name == "help" or name == "courses":
				continue  # the help goes by itself; the catalogue's is at the top
			var r: Rect2 = buttons[name]
			if name == "curios":
				r = r.merge(Rect2(r.end.x, r.position.y, r.size.x * 1.4, r.size.y))
			rects.append(r)
	var c = tc.get("_stick_centre")
	var rr = tc.get("_stick_radius")
	if c is Vector2 and rr is float:
		rects.append(Rect2(c - Vector2(rr, rr), Vector2(2.0 * rr, 2.0 * rr)))
	for r: Rect2 in rects:
		if r.position.y > 0.4 * screen.y and r.position.x < box.end.x and r.end.x > box.position.x:
			out = minf(out, r.position.y)
	return out


## The framing's tilt and turn, eased; the visitor's own look (a drag, the mouse, the walking body reading a spine)
## takes the view back.
func _tilt(real: float) -> void:
	if _framing.is_empty():
		return
	var now := Vector2(float(_camera.get("_pitch")), float(_camera.get("_yaw")))
	if now.distance_to(_framing.set) > 1e-4 or _open:
		_framing = {}
		return
	_framing.t = minf(1.0, float(_framing.t) + real / 0.9)
	var k := smoothstep(0.0, 1.0, float(_framing.t))
	var from: Vector2 = _framing.from
	var to: Vector2 = _framing.to
	var p := lerpf(from.x, to.x, k)
	var y := lerp_angle(from.y, to.y, k)
	_camera.set("_pitch", p)
	_camera.set("_yaw", y)
	_camera.rotation = Vector3(p, y, _camera.rotation.z)
	_framing.set = Vector2(p, y)
	if float(_framing.t) >= 1.0:
		_framing = {}


## The whistle's first call compiled, in its first frame, the troupe's shaders, the beam's and the puff's,
## and the spot's light on the floor: a stop of 350 to 534 ms in a fresh browser at the call, and of 67
## to 117 ms at later calls, which loaded both baked dances anew and compiled a new beam shader
## (scripts/tars_ensemble.gd keeps one now). With this, about 100 ms at the first call and at most 50 at
## later ones (artpass/tarsdance/NOTES.md, "Version 36"). Here, a few frames after the start, both dances
## are loaded and kept; under the web build's renderer, a troupe as big as the whistle's stands 5 m ahead
## of the view with a puff, on a render layer of its own (WARM_LAYER) which the view leaves out for those
## frames, its spot open onto all but too faint to be seen, and a small camera of its own draws it in a
## viewport of the hall's world, first without the spot (a troupe comes with its spot off, which fades
## in), then with it: the view draws the floor under the faint spot, that camera the robots, the beam and
## the puff. Then it is sent off and its materials kept, so that later troupes find their shaders
## compiled. Natively the drivers keep their own shaders, and without a screen (--headless) nothing is
## drawn.
func _warm_troupe() -> void:
	if _troupe_script == null:
		_troupe_script = load(TROUPE_SCRIPT_PATH)
	if _troupe_keep.is_empty():
		_troupe_keep = [_troupe_script.call("data", 0), _troupe_script.call("data", 1)]
	_warm_in = -1
	if RenderingServer.get_current_rendering_method() != "gl_compatibility" or DisplayServer.get_name() == "headless":
		return
	var vp := _camera.get_viewport()
	if vp.get_camera_3d() != _camera:
		_warm_in = 60  # a cinematic films with its own camera: later
		return
	var from := _camera.global_position
	var ahead := -_camera.global_basis.z
	ahead.y = 0.0
	if ahead.length() < 0.05:
		ahead = _camera.global_basis.y  # looking straight down: the screen's top
		ahead.y = 0.0
	var at := from + ahead.normalized() * 5.0
	at.y = from.y - 1.7
	var walker := _walker()
	if walker != null and walker.has_method("_support"):
		at.y = float(walker.call("_support", Vector2(at.x, at.z), from.y - 0.3))
	var troupe: Node3D = _troupe_script.new()
	troupe.call("configure", self, at, from, 2.0, 0)
	troupe.process_mode = Node.PROCESS_MODE_DISABLED  # posed, lit and drawn; it does not dance
	_obs.add_child(troupe)
	troupe.call("_light", 4.0)
	var spot := troupe.get("_spot") as SpotLight3D
	if spot != null:
		spot.light_energy = 0.001
		spot.visible = false
	_sparkle(at + Vector3(0.0, 0.6, 0.0), GILT, 2.0)
	var puff := _obs.get_child(_obs.get_child_count() - 1) as CPUParticles3D
	for g: VisualInstance3D in troupe.find_children("*", "GeometryInstance3D", true, false):
		g.layers = WARM_LAYER
	if puff != null:
		puff.layers = WARM_LAYER
	var mask := _camera.cull_mask
	_camera.cull_mask = mask & ~WARM_LAYER
	var view := SubViewport.new()
	view.size = Vector2i(96, 96)
	view.msaa_3d = vp.msaa_3d
	view.screen_space_aa = vp.screen_space_aa
	view.scaling_3d_mode = vp.scaling_3d_mode
	view.scaling_3d_scale = vp.scaling_3d_scale
	view.use_hdr_2d = vp.use_hdr_2d
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS  # five frames: without the spot, then with it
	add_child(view)
	var cam := Camera3D.new()
	cam.fov = 70.0
	view.add_child(cam)
	var back := Vector3(from.x - at.x, 0.0, from.z - at.z).normalized()
	cam.look_at_from_position(at + back * 4.5 + Vector3(0.0, 2.4, 0.0), at + Vector3(0.0, 0.3, 0.0), Vector3.UP)
	_warm = {"troupe": troupe, "puff": puff, "spot": spot, "view": view, "mask": mask, "frames": 5}


## The warm-up drawn: its materials kept, its troupe, puff and viewport gone, the view's layers back.
func _warm_done() -> void:
	var troupe = _warm.troupe  # untyped: a freed node cannot be cast
	var puff = _warm.puff
	if is_instance_valid(troupe):
		for mi: MeshInstance3D in (troupe as Node).find_children("*", "MeshInstance3D", true, false):
			if mi.material_override != null and not _troupe_keep.has(mi.material_override):
				_troupe_keep.append(mi.material_override)
		troupe.free()
	if is_instance_valid(puff):
		var quad: Mesh = (puff as CPUParticles3D).mesh
		if quad != null:
			_troupe_keep.append(quad.surface_get_material(0))
		puff.free()
	if is_instance_valid(_warm.view):
		(_warm.view as Node).free()
	_camera.cull_mask = int(_warm.mask) | (_camera.cull_mask & WARM_LAYER)
	_warm = {}


## The troupe has bowed out (scripts/tars_ensemble.gd): the whistle may call another.
func _troupe_done(troupe: Node3D) -> void:
	if _troupe == troupe:
		_troupe = null
	stats.troupes_done += 1


## The ankh: every duck gets up and waddles back to you; every TARS walks back.
func _revive() -> void:
	stats.revivals += 1
	_ankh_glow = 1.0
	_play("chime", -3.0)
	var k := 0
	for d: Dictionary in _ducks:
		d.waddle = true
		d.resting = false
		d.t = -0.25 * k  # one after the other
		d.v = Vector3(0, 1.2, 0)
		k += 1
	for robot: Node in _robots:
		if is_instance_valid(robot):
			robot.call("call_home")
	if _troupe != null and is_instance_valid(_troupe):
		_troupe.call("stop")


## Where the ducks waddle to: the walker's feet, or under the camera.
func _home() -> Vector3:
	return _camera.global_position if _camera != null else Vector3.ZERO


## Gravity, the floor under each duck (the walking body's floors), the shelves' front; a bounce
## that is hard enough squeaks. A revived duck waddles home, rocking, and is gone at your feet.
func _move_ducks(delta: float) -> void:
	var walker := _walker()
	for d: Dictionary in _ducks.duplicate():
		if d.resting:
			continue
		var n := d.node as Node3D
		var v: Vector3 = d.v
		if d.waddle:
			d.t = float(d.t) + delta
			if float(d.t) < 0.0:
				continue
			var to := _home() - n.global_position
			var flat_to := Vector2(to.x, to.z)
			if flat_to.length() < 0.5 or float(d.t) > 9.0:
				_sparkle(n.global_position + Vector3(0, 0.05, 0), Color(0.55, 1.0, 0.65))
				_sound_at("quack", n.global_position, 1.0)
				stats.home += 1
				_ducks.erase(d)
				n.queue_free()
				continue
			var walk := flat_to.normalized() * 1.1
			v.x = walk.x
			v.z = walk.y
			n.look_at(n.global_position + Vector3(walk.x, 0.0, walk.y) + Vector3(0, 0.0001, 0), Vector3.UP)
			n.rotate_object_local(Vector3.FORWARD, sin(float(d.t) * 13.0) * 0.28)
			if fmod(float(d.t), 1.3) < delta and _rng.randf() < 0.6:
				_sound_at("quack", n.global_position, 0.6)
		v.y -= 9.8 * delta
		var size := float(d.get("size", 1.0))
		var p := n.global_position + v * delta
		var flat := Vector2(p.x, p.z)
		if flat.length() > SHELF_R - 0.08 * size:
			var out := flat.normalized()
			flat = out * (SHELF_R - 0.08 * size)
			var vr := Vector2(v.x, v.z).dot(out)
			if vr > 0.0:
				v.x -= out.x * vr * 1.5
				v.z -= out.y * vr * 1.5
			p = Vector3(flat.x, p.y, flat.y)
		var floor_y := 0.0
		if walker != null and walker.has_method("_support"):
			floor_y = maxf(0.0, float(walker.call("_support", flat, n.global_position.y + 0.05)))
		var half := 0.045 * size
		if p.y < floor_y + half:
			p.y = floor_y + half
			if v.y < -0.6:
				_squeak(n.global_position, minf(1.0, -v.y / 6.0))
			if d.waddle:
				v.y = 0.0
			else:
				v.y = -v.y * 0.42
				v.x *= 0.72
				v.z *= 0.72
				d.spin = float(d.spin) * 0.6
				# At rest once the rebound would barely lift it, allowing what gravity takes in a frame:
				# at 10 frames a second each frame's 0.98 m/s, bounced back, kept a duck hopping on the
				# floor for ever (artpass/curios/curiotest.gd, --fps=10).
				if Vector2(v.x, v.z).length() < 0.25 and v.y < 0.25 + 9.8 * delta:
					v = Vector3.ZERO
					d.resting = true
		n.global_position = p
		if not d.waddle:
			n.rotate_y(float(d.spin) * delta)
		d.v = v


func _squeak(at: Vector3, strength: float) -> void:
	stats.squeaks += 1
	_sound_at("squeak", at, 0.25 + 0.75 * strength)


func _sound_at(sound: String, at: Vector3, gain: float) -> void:
	if sound == "quack":
		stats.quacks += 1
	elif sound == "clank":
		stats.clanks += 1
	var p := AudioStreamPlayer3D.new()
	p.stream = _sounds[sound]
	p.volume_db = linear_to_db(gain)
	if _sfx != null:
		p.volume_db += float(_sfx.call("gain_db", "curio_wheel-" + sound, p.stream))
	p.pitch_scale = _rng.randf_range(0.9, 1.15)
	p.unit_size = 4.0
	_obs.add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


var _speck_tex: GradientTexture2D


## A soft round speck: white in the middle, clear at the rim.
func _speck() -> GradientTexture2D:
	if _speck_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.3, Color(1, 1, 1, 0.8))
		_speck_tex = GradientTexture2D.new()
		_speck_tex.gradient = g
		_speck_tex.fill = GradientTexture2D.FILL_RADIAL
		_speck_tex.fill_from = Vector2(0.5, 0.5)
		_speck_tex.fill_to = Vector2(1.0, 0.5)
		_speck_tex.width = 32
		_speck_tex.height = 32
	return _speck_tex


## A puff of sparks: forty specks flung out and falling, fading in under a second; `size` scales it
## up to be seen from afar.
func _sparkle(at: Vector3, color: Color, size := 1.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 40
	p.lifetime = 0.9
	p.explosiveness = 0.92
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.5 * size
	p.initial_velocity_max = 1.7 * size
	p.gravity = Vector3(0, -1.6, 0) * size
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.lightened(0.2), 1.0))
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.035) * size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _speck()  # round and soft, not square
	quad.material = m
	p.mesh = quad
	_obs.add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)


# --- Per frame ------------------------------------------------------------------

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.01)
	_time += real
	var lib := _library()
	if lib != null:
		lang = str(lib.get("lang"))
	var shown := _hud_visible()
	if not shown and _open:
		_open = false
		Engine.time_scale = 1.0
	_open_t = move_toward(_open_t, 1.0 if _open else 0.0, real * 6.0)
	_wheel.visible = _open_t > 0.0
	_wheel.queue_redraw()
	_button.visible = _button_shown()
	_button.queue_redraw()
	# The monocle: view_fit.gd closes the view in, eased; its rim darkens round it.
	var zoom_to := MONOCLE_ZOOM if _zoom_held and equipped == "monocle" else 1.0
	_zoom = zoom_to if reduced_motion else lerpf(_zoom, zoom_to, 1.0 - exp(-10.0 * real))
	if absf(_zoom - zoom_to) < 0.002:
		_zoom = zoom_to
	_set_zoom(_zoom)
	var rim := (1.0 - _zoom) / (1.0 - MONOCLE_ZOOM)
	_monocle_rim.visible = rim > 0.01 and shown
	(_monocle_rim.material as ShaderMaterial).set_shader_parameter("amount", rim)
	_hold_pose(real, shown, rim)
	_move_ducks(delta)
	for l: Dictionary in _labels.duplicate():
		l.t = float(l.t) - real
		var node := l.node as Label3D
		node.modulate.a = clampf(float(l.t) / 0.6, 0.0, 1.0)
		if float(l.t) <= 0.0:
			node.queue_free()
			_labels.erase(l)
	if _ankh_glow > 0.0:
		_ankh_glow = move_toward(_ankh_glow, 0.0, real * 0.7)
		(_mats.ankh as StandardMaterial3D).emission_energy_multiplier = 3.0 * _ankh_glow
	if _warm_in > 0:
		_warm_in -= 1
		if _warm_in == 0:
			_warm_troupe()
	elif not _warm.is_empty():
		_warm.frames = int(_warm.frames) - 1
		if int(_warm.frames) == 2 and is_instance_valid(_warm.spot):
			(_warm.spot as Node3D).visible = true  # drawn first without its spot, as a troupe comes, then with it
		if int(_warm.frames) <= 0:
			_warm_done()
	_tilt(real)
	_fly_hint()


## The keyboard help names the wheel: walk_physics.gd writes it into its walking hint, and the
## flying one, which fly_camera.gd writes, gets it here.
func _fly_hint() -> void:
	var hint := _camera.get_parent().get_node_or_null("ControlsHud/Panel/Hint") as Label if _camera != null else null
	if hint != null and hint.text.begins_with("FLY MODE") and not hint.text.contains("Tab:"):
		hint.text += "  ·  Tab: curios"


## The held curio: raised when picked, lowered while reading a spine or flying a view and, the
## whistle, while its troupe dances but for 0.6 s after a blow; swaying behind the look, jabbing on a
## use; hidden with the interface (captures).
func _hold_pose(real: float, shown: bool, rim: float) -> void:
	var walker := _walker()
	_blown = maxf(_blown - real, 0.0)
	var dancing := equipped == "whistle" and _troupe != null and is_instance_valid(_troupe) and _blown <= 0.0
	var lowered := dancing or (walker != null and walker.has_method("is_reading") and bool(walker.call("is_reading")))
	_raise = move_toward(_raise, 0.0 if lowered else 1.0, real * 4.0)
	_use_kick = move_toward(_use_kick, 0.0, real * 5.0)
	var look := Vector2(float(_camera.get("_yaw")), float(_camera.get("_pitch")))
	if _last_look != Vector2.INF and not reduced_motion:
		var turn := Vector2(wrapf(look.x - _last_look.x, -PI, PI), look.y - _last_look.y)
		_sway = _sway.lerp(Vector2(turn.x, -turn.y) * 2.5, 1.0 - exp(-12.0 * real)).limit_length(0.06)
	_sway = _sway.lerp(Vector2.ZERO, 1.0 - exp(-6.0 * real))
	_last_look = look
	var drone := _drone()
	var away := drone != null and bool(drone.call("is_flying"))  # the drone is out of the hand
	for id: String in ITEMS:
		var m := _models[id] as Node3D
		m.visible = shown and id == equipped and id != "hands" and _raise > 0.01 and not (id == "monocle" and rim > 0.6) \
			and not (id == "drone" and away)
	var m := _models[equipped] as Node3D
	var base: Vector3 = m.get_meta("pose", Vector3(0.16, -0.14, -0.32))
	var breathe := 0.0 if reduced_motion else sin(_time * 1.4) * 0.0025
	var ease := 1.0 - pow(1.0 - _raise, 3.0)
	var pos := base + Vector3(_sway.x * 0.5, _sway.y * 0.5 + breathe - (1.0 - ease) * 0.22, 0.0)
	pos.z -= 0.05 * sin(PI * _use_kick)
	if equipped == "monocle":
		pos = pos.lerp(Vector3(0.0, 0.0, -0.12), clampf(rim * 1.6, 0.0, 1.0))
	_hold.position = pos
	_hold.rotation = Vector3(_sway.y * 0.6 + 0.25 * sin(PI * _use_kick) * (1.0 if equipped == "index" else 0.3), -_sway.x * 0.6, 0.0)
	if _lamp_light != null:
		_lamp_light.visible = _lamp_on and shown and equipped == "lamp"


# --- Interface ------------------------------------------------------------------

func _make_ui() -> void:
	# The wheel over everything, the lift's, the views' and the corridor's texts (28 to 30) too;
	# the monocle's rim under the course UI (5) and the touch controls (6), which stay usable.
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)
	var rim_layer := CanvasLayer.new()
	rim_layer.layer = 4
	add_child(rim_layer)
	_monocle_rim = ColorRect.new()
	_monocle_rim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_monocle_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float amount = 0.0;
uniform vec2 aspect = vec2(1.0);
void fragment() {
	// A brass rim round a round view, dark outside it.
	vec2 p = (UV - 0.5) * aspect;
	float r = length(p) / (0.5 * min(aspect.x, aspect.y));
	float lens = mix(1.6, 0.92, amount);
	float dark = smoothstep(lens, lens + 0.03, r);
	float rim = smoothstep(lens - 0.05, lens - 0.01, r) * (1.0 - smoothstep(lens + 0.01, lens + 0.05, r));
	vec3 brass = vec3(0.78, 0.6, 0.3) * (0.7 + 0.5 * p.y);
	COLOR = vec4(mix(vec3(0.0), brass, rim), max(dark * 0.97, rim) * amount);
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_monocle_rim.material = mat
	_monocle_rim.visible = false
	_monocle_rim.resized.connect(func() -> void:
		var s := _monocle_rim.size
		mat.set_shader_parameter("aspect", Vector2(s.x, s.y) / maxf(1.0, minf(s.x, s.y))))
	rim_layer.add_child(_monocle_rim)
	_wheel = Control.new()
	_wheel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wheel.visible = false
	_wheel.draw.connect(_draw_wheel)
	_layer.add_child(_wheel)
	# Its button on a computer: the HUD's "Tab: curios" was the only sign of the wheel there. A touch
	# screen has its own, among the touch controls.
	_button = Control.new()
	_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.draw.connect(_draw_button)
	_layer.add_child(_button)
	_player = AudioStreamPlayer.new()
	add_child(_player)


func _draw_wheel() -> void:
	var size := _wheel.get_viewport_rect().size
	var c := size * 0.5
	var k := _open_t
	var outer := _outer() * (0.85 + 0.15 * k)
	var inner := _inner() * (0.85 + 0.15 * k)
	var n := ITEMS.size()
	var font := ThemeDB.fallback_font
	_wheel.draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.02, 0.55 * k))
	var gap := 0.025
	for i in n:
		var a0 := -PI * 0.5 + (i - 0.5) * TAU / n + gap
		var a1 := a0 + TAU / n - 2.0 * gap
		var pts := PackedVector2Array()
		for s in 13:
			var a := lerpf(a0, a1, s / 12.0)
			pts.append(c + Vector2(cos(a), sin(a)) * outer)
		for s in 13:
			var a := lerpf(a1, a0, s / 12.0)
			pts.append(c + Vector2(cos(a), sin(a)) * inner)
		var picked := i == _pick
		_wheel.draw_colored_polygon(pts, Color(GILT.darkened(0.35), 0.9 * k) if picked else Color(LACQUER, LACQUER.a * k))
		var edge := pts.duplicate()
		edge.append(pts[0])
		_wheel.draw_polyline(edge, Color(GILT, (0.95 if picked else 0.55) * k), maxf(1.5, outer * (0.012 if picked else 0.006)), true)
		var mid := (a0 + a1) * 0.5
		var at := c + Vector2(cos(mid), sin(mid)) * (inner + outer) * 0.5
		var s := (outer - inner) * 0.78
		var icon: Texture2D = _icons.get(ITEMS[i])
		if icon != null:
			_wheel.draw_texture_rect(icon, Rect2(at - Vector2(s, s) * 0.5, Vector2(s, s)), false, Color(1, 1, 1, k))
		if ITEMS[i] == equipped:
			_wheel.draw_circle(c + Vector2(cos(mid), sin(mid)) * (outer - outer * 0.05), outer * 0.018, Color(GILT, k))
	# The centre: the picked curio's name and its "ammunition"; under the wheel, a line about it.
	var item: Array = _t(ITEMS[_pick])
	var title := str(_t("title"))
	var fs_title := roundi(outer * 0.07)
	var fs_name := roundi(outer * 0.11)
	var fs_ammo := roundi(outer * 0.072)
	var fs_line := roundi(outer * 0.078)
	var w := inner * 1.75
	_wheel.draw_circle(c, inner * 0.96, Color(0.02, 0.018, 0.016, 0.94 * k))
	_draw_centred(font, c + Vector2(0, -outer - fs_title * 1.4), title, fs_title, Color(GILT, k))
	_draw_centred(font, c + Vector2(0, -fs_name * 0.45), str(item[0]), fs_name, Color(0.97, 0.94, 0.87, k), w)
	_draw_centred(font, c + Vector2(0, fs_ammo * 1.0), str(item[1]), fs_ammo, Color(GILT, k), w)
	var lw := minf(size.x - 32.0, outer * 2.6)
	var band := Rect2(c.x - lw * 0.5 - 12.0, c.y + outer + fs_line * 0.5, lw + 24.0, fs_line * 2.9)
	_wheel.draw_rect(band, Color(0.02, 0.018, 0.016, 0.88 * k))
	# A touch screen's own line where it differs (a tap, not a click or a held button).
	var line := str(item[3]) if _touch() and item.size() > 3 else str(item[2])
	_wheel.draw_multiline_string(font, Vector2(c.x - lw * 0.5, band.position.y + fs_line * 1.15), line,
		HORIZONTAL_ALIGNMENT_CENTER, lw, fs_line, 2, Color(0.88, 0.85, 0.78, k))


func _button_shown() -> bool:
	return _button != null and not _touch() and _hud_visible()


## The button's round face, bottom left; its label runs on to the right of it.
func _button_rect() -> Rect2:
	var size := _button.get_viewport_rect().size
	var d := clampf(minf(size.x, size.y) * 0.082, 48.0, 88.0)
	var m := d * 0.3
	return Rect2(m, size.y - m - d, d, d)


func _draw_button() -> void:
	if not _button_shown():
		return
	var r := _button_rect()
	var c := r.get_center()
	var rad := r.size.x * 0.5
	var lit := _button_hover or _open
	_button.draw_circle(c, rad, Color(LACQUER, 0.88))
	_button.draw_arc(c, rad - 1.0, 0.0, TAU, 48, Color(GILT, 0.95 if lit else 0.6), maxf(1.5, rad * (0.07 if lit else 0.045)), true)
	var icon: Texture2D = _icons.get(equipped)
	if icon != null:
		var s := r.size.x * 0.82
		_button.draw_texture_rect(icon, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	var font := ThemeDB.fallback_font
	var fs := roundi(rad * 0.46)
	var key := "Tab"
	var kw := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var kx := r.end.x + rad * 0.3
	var key_box := Rect2(kx, c.y - fs * 0.85, kw + fs * 0.8, fs * 1.6)
	_button.draw_rect(key_box, Color(LACQUER, 0.88))
	_button.draw_rect(key_box, Color(GILT, 0.7), false, 1.5)
	_button.draw_string(font, Vector2(kx + fs * 0.4, c.y + fs * 0.35), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.97, 0.94, 0.87))
	var title := str(_t("button"))
	var tx := key_box.end.x + fs * 0.5
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_button.draw_rect(Rect2(tx - fs * 0.3, c.y - fs * 0.85, tw + fs * 0.6, fs * 1.6), Color(LACQUER, 0.6))
	_button.draw_string(font, Vector2(tx, c.y + fs * 0.35), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(GILT, 0.95 if lit else 0.8))


func _draw_centred(font: Font, at: Vector2, text: String, fs: int, color: Color, width := -1.0) -> void:
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if width > 0.0 and tw > width:
		fs = maxi(8, floori(fs * width / tw))
		tw = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_wheel.draw_string(font, Vector2(at.x - tw * 0.5, at.y + fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


## Each curio's icon: its own model, rendered once in a small viewport of its own world.
func _make_icons() -> void:
	for id: String in ITEMS:
		var vp := SubViewport.new()
		vp.size = Vector2i(160, 160)
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(vp)  # first: the camera below can only look at its model inside the tree
		var model := _build(id)
		vp.add_child(model)
		var cam := Camera3D.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.55, 0.5, 0.45)
		env.ambient_light_energy = 0.9
		cam.environment = env
		var aabb := _bounds(model)
		var r := maxf(aabb.size.length() * 0.5, 0.01)
		cam.fov = 30.0
		var look := aabb.get_center()
		cam.position = look + Vector3(0.55, 0.35, 1.0).normalized() * r / tan(deg_to_rad(15.0)) * 1.05
		vp.add_child(cam)
		cam.look_at(look, Vector3.UP)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-40, 35, 0)
		sun.light_energy = 1.6
		vp.add_child(sun)
		_icons[id] = vp.get_texture()


static func _bounds(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var m := c as MeshInstance3D
		var box := (n.global_transform.affine_inverse() * m.global_transform) * m.mesh.get_aabb() if m.is_inside_tree() \
			else _local_xf(n, m) * m.mesh.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


static func _local_xf(root: Node3D, m: Node3D) -> Transform3D:
	var xf := m.transform
	var p := m.get_parent() as Node3D
	while p != null and p != root:
		xf = p.transform * xf
		p = p.get_parent() as Node3D
	return xf


# --- Models ---------------------------------------------------------------------

func _make_materials() -> void:
	_mats.brass = _mat(Color(0.8, 0.62, 0.32), 1.0, 0.32)
	_mats.gilt = _mat(Color(0.88, 0.72, 0.4), 1.0, 0.22)
	_mats.glove = _mat(Color(0.95, 0.94, 0.9), 0.0, 0.62)
	_mats.stitch = _mat(Color(0.12, 0.1, 0.09), 0.0, 0.8)
	_mats.cord = _mat(Color(0.18, 0.1, 0.06), 0.0, 0.85)
	_mats.duck = _mat(Color(1.0, 0.8, 0.08), 0.0, 0.32)
	_mats.duck_wing = _mat(Color(0.95, 0.7, 0.05), 0.0, 0.36)
	_mats.beak = _mat(Color(1.0, 0.42, 0.04), 0.0, 0.35)
	_mats.eye = _mat(Color(0.02, 0.02, 0.02), 0.0, 0.15)
	_mats.wood = _mat(Color(0.3, 0.17, 0.08), 0.0, 0.55)
	_mats.grip = _mat(Color(0.5, 0.33, 0.17), 0.0, 0.7)
	_mats.nickel = _mat(Color(0.78, 0.79, 0.8), 0.7, 0.26)  # not quite metal: the web build draws metal 1 dark
	_mats.lanyard = _mat(Color(0.62, 0.07, 0.05), 0.0, 0.8)
	var ankh := _mat(Color(0.9, 0.74, 0.38), 1.0, 0.2)
	ankh.emission_enabled = true
	ankh.emission = Color(0.5, 1.0, 0.6)
	ankh.emission_energy_multiplier = 0.0
	_mats.ankh = ankh
	var glass := _mat(Color(0.82, 0.9, 0.95, 0.22), 0.0, 0.04)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats.glass = glass


static func _mat(c: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg := Vector3.ZERO, scale := Vector3.ONE, node_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if node_name != "":
		mi.name = node_name
	parent.add_child(mi)
	return mi


static func _cyl(r_top: float, r_bottom: float, h: float, seg := 24) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func _ball(r: float, hemi := false) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * (1.0 if hemi else 2.0)
	m.is_hemisphere = hemi
	m.radial_segments = 24
	m.rings = 12
	return m


static func _caps(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 16
	m.rings = 6
	return m


static func _ring(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 32
	m.ring_segments = 12
	return m


func _build(id: String) -> Node3D:
	match id:
		"lamp":
			return _build_lamp()
		"monocle":
			return _build_monocle()
		"index":
			return _build_glove(true)
		"duck":
			return _build_duck()
		"wand":
			return _build_wand()
		"ankh":
			return _build_ankh()
		"drone":
			return load(DRONE_SCRIPT_PATH).build_model()
		"whistle":
			return _build_whistle()
	return _build_glove(false)


## A nickel pea whistle: a round chamber with a flat mouthpiece along its top, the slot where the
## two meet, a ring at the back and a red lanyard hanging from it.
func _build_whistle() -> Node3D:
	var root := Node3D.new()
	root.name = "Whistle"
	root.set_meta("pose", Vector3(0.14, -0.13, -0.3))
	root.set_meta("held_scale", 1.2)
	var g := Node3D.new()
	g.rotation_degrees = Vector3(18, 32, -6)  # the mouthpiece towards you, a little left, its slot up
	root.add_child(g)
	_part(g, _cyl(0.011, 0.011, 0.016, 24), _mats.nickel, Vector3.ZERO, Vector3(90, 0, 0))
	_part(g, BoxMesh.new(), _mats.nickel, Vector3(0.019, 0.0065, 0), Vector3.ZERO, Vector3(0.032, 0.008, 0.012))
	_part(g, BoxMesh.new(), _mats.stitch, Vector3(0.0045, 0.0105, 0), Vector3.ZERO, Vector3(0.006, 0.0016, 0.009))
	_part(g, _ring(0.0026, 0.0042), _mats.nickel, Vector3(-0.0135, 0.004, 0), Vector3(90, 0, 0))
	_part(g, _cyl(0.0013, 0.0013, 0.05, 6), _mats.lanyard, Vector3(-0.017, -0.02, 0.002), Vector3(0, 0, -12))
	_part(g, _cyl(0.0013, 0.0013, 0.05, 6), _mats.lanyard, Vector3(-0.012, -0.021, -0.002), Vector3(0, 0, 8))
	return root


## A wooden wand: a crooked stick of dark wood tapering to its tip, a lighter grip with a pommel,
## and two knots.
func _build_wand() -> Node3D:
	var root := Node3D.new()
	root.name = "Wand"
	root.set_meta("pose", Vector3(0.15, -0.15, -0.3))
	var g := Node3D.new()
	g.rotation_degrees = Vector3(-64, -12, -6)  # its tip forward, a little up and right of the aim
	root.add_child(g)
	_part(g, _cyl(0.0032, 0.0072, 0.2, 10), _mats.wood, Vector3(0, 0.125, 0))
	_part(g, _cyl(0.0072, 0.0082, 0.06, 10), _mats.wood, Vector3(0, -0.005, 0), Vector3(0, 0, 4))
	_part(g, _cyl(0.0088, 0.0092, 0.07, 12), _mats.grip, Vector3(0, -0.07, 0))
	_part(g, _ball(0.0105), _mats.grip, Vector3(0, -0.108, 0), Vector3.ZERO, Vector3(1, 0.8, 1))
	_part(g, _ball(0.0058), _mats.wood, Vector3(0.003, 0.07, 0.001), Vector3.ZERO, Vector3(1.2, 0.8, 1.0))
	_part(g, _ball(0.0042), _mats.wood, Vector3(-0.002, 0.16, 0.0), Vector3.ZERO, Vector3(1.2, 0.8, 1.0))
	return root


## An ankh of gilt brass, held by its foot: an oval loop over a cross bar, its arms and foot
## flaring. It glows green when it works.
func _build_ankh() -> Node3D:
	var root := Node3D.new()
	root.name = "Ankh"
	root.set_meta("pose", Vector3(0.15, -0.12, -0.33))
	var g := Node3D.new()
	g.rotation_degrees = Vector3(-8, -18, 4)
	root.add_child(g)
	_part(g, _ring(0.017, 0.025), _mats.ankh, Vector3(0, 0.083, 0), Vector3(90, 0, 0), Vector3(1.0, 1.0, 1.4))
	for side in [-1.0, 1.0]:
		# Its top, the wider end, outwards; then turned about its own length, square to the view.
		_part(g, _cyl(0.0105, 0.007, 0.034, 4), _mats.ankh, Vector3(side * 0.02, 0.046, 0), Vector3(45, 0, side * -90))
	_part(g, BoxMesh.new(), _mats.ankh, Vector3(0, 0.046, 0), Vector3.ZERO, Vector3(0.012, 0.014, 0.01))
	_part(g, _cyl(0.0065, 0.011, 0.1, 4), _mats.ankh, Vector3(0, -0.012, 0), Vector3(0, 45, 0))
	return root


## A banker's lamp held by its stem: a brass foot, a green glass shade, a pull chain, and a cord
## hanging to a plug that reaches no socket.
func _build_lamp() -> Node3D:
	var root := Node3D.new()
	root.name = "Lamp"
	root.set_meta("pose", Vector3(0.19, -0.16, -0.4))
	var g := Node3D.new()
	g.position = Vector3(0, -0.09, 0)
	g.rotation_degrees = Vector3(0, -20, 0)
	root.add_child(g)
	_part(g, _cyl(0.055, 0.06, 0.016), _mats.brass, Vector3(0, 0.008, 0))
	_part(g, _cyl(0.006, 0.007, 0.15), _mats.brass, Vector3(0, 0.09, 0.01))
	_part(g, _cyl(0.004, 0.004, 0.06), _mats.brass, Vector3(0, 0.165, -0.01), Vector3(90, 0, 0))
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.04, 0.32, 0.14)
	green.metallic = 0.1
	green.roughness = 0.12
	green.emission_enabled = true
	green.emission = Color(0.1, 0.8, 0.35)
	green.emission_energy_multiplier = 0.0
	green.cull_mode = BaseMaterial3D.CULL_DISABLED
	_part(g, _ball(0.5, true), green, Vector3(0, 0.168, -0.03), Vector3.ZERO, Vector3(0.2, 0.07, 0.085), "Shade")
	var bulb := StandardMaterial3D.new()
	bulb.albedo_color = Color(1.0, 0.95, 0.85)
	bulb.emission_enabled = true
	bulb.emission = Color(1.0, 0.82, 0.55)
	bulb.emission_energy_multiplier = 0.0
	_part(g, _ball(0.014), bulb, Vector3(0, 0.16, -0.03), Vector3.ZERO, Vector3(1.6, 1, 1), "Bulb")
	for i in 4:
		_part(g, _ball(0.0028), _mats.brass, Vector3(0.045, 0.158 - i * 0.008, -0.03))
	_part(g, _ball(0.006), _mats.brass, Vector3(0.045, 0.124, -0.03))
	# The cord, from the back of the foot, swinging down to its plug.
	var pts := [Vector3(0, 0.006, 0.055), Vector3(0.01, -0.03, 0.07), Vector3(0.025, -0.08, 0.06), Vector3(0.03, -0.13, 0.035)]
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg := _part(g, _cyl(0.0035, 0.0035, a.distance_to(b), 8), _mats.cord, (a + b) * 0.5)
		seg.basis = Basis(_perp(b - a), (b - a).normalized(), _perp(b - a).cross((b - a).normalized()))
	_part(g, BoxMesh.new(), _mats.cord, Vector3(0.03, -0.145, 0.035), Vector3.ZERO, Vector3(0.02, 0.026, 0.014))
	for x in [-0.005, 0.005]:
		_part(g, BoxMesh.new(), _mats.brass, Vector3(0.03 + x, -0.165, 0.035), Vector3.ZERO, Vector3(0.0025, 0.016, 0.006))
	if _camera != null and _lamp_light == null:
		_lamp_light = SpotLight3D.new()
		_lamp_light.name = "LampBeam"
		_lamp_light.light_color = Color(1.0, 0.84, 0.6)
		_lamp_light.light_energy = 5.0
		_lamp_light.spot_range = 16.0
		_lamp_light.spot_angle = 24.0
		_lamp_light.spot_attenuation = 0.8
		_lamp_light.shadow_enabled = false
		_lamp_light.visible = false
		_lamp_light.position = Vector3(0, 0.15, -0.05)
		g.add_child(_lamp_light)
		_lamp_light.rotation_degrees = Vector3(0, 20, 0)  # straight ahead of the camera, not the lamp
	return root


static func _perp(v: Vector3) -> Vector3:
	var n := v.normalized()
	var p := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT)
	return p.normalized()


## A monocle: a gilt rim round its glass, on a fine chain.
func _build_monocle() -> Node3D:
	var root := Node3D.new()
	root.name = "Monocle"
	root.set_meta("pose", Vector3(0.12, -0.1, -0.26))
	_part(root, _ring(0.0175, 0.021), _mats.gilt, Vector3.ZERO, Vector3(90, 0, 0))
	_part(root, _cyl(0.018, 0.018, 0.0015, 32), _mats.glass, Vector3.ZERO, Vector3(90, 0, 0))
	for i in 11:
		var t := i / 10.0
		var p := Vector3(0.02 + 0.03 * t, -0.006 - 0.09 * t * t + 0.02 * t, 0.004 * t)
		_part(root, _ring(0.0012, 0.0024), _mats.gilt, p, Vector3(0, 90 * (i % 2), 70))
	return root


## A white cartoon glove with a black-stitched back and a rolled cuff: pointing (the Index), or
## open (bare hands, the icon only).
func _build_glove(pointing: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "Index" if pointing else "Hands"
	root.set_meta("pose", Vector3(0.14, -0.13, -0.3))
	var g := Node3D.new()
	g.rotation_degrees = Vector3(0, 12, 0)
	root.add_child(g)
	_part(g, _ball(0.5), _mats.glove, Vector3(0, 0, 0), Vector3.ZERO, Vector3(0.07, 0.034, 0.08))
	_part(g, _cyl(0.032, 0.036, 0.03), _mats.glove, Vector3(0, 0, 0.05), Vector3(90, 0, 0))
	_part(g, _ring(0.03, 0.037), _mats.glove, Vector3(0, 0, 0.066), Vector3(90, 0, 0))
	for x in [-0.012, 0.0, 0.012]:
		_part(g, BoxMesh.new(), _mats.stitch, Vector3(x, 0.0172, -0.002), Vector3.ZERO, Vector3(0.0018, 0.0006, 0.04))
	var fingers := [-0.024, -0.008, 0.008, 0.024]
	for i in 4:
		var x: float = fingers[i]
		if pointing and i == 3:
			_part(g, _caps(0.0085, 0.07), _mats.glove, Vector3(x * 0.8, 0.004, -0.07), Vector3(-90, 0, 0))
		elif pointing:
			_part(g, _caps(0.0085, 0.032), _mats.glove, Vector3(x * 0.9, -0.008, -0.04), Vector3(-30, 0, 0))
		else:
			_part(g, _caps(0.0085, 0.06), _mats.glove, Vector3(x * 1.05, 0.0, -0.065), Vector3(-90, 0, -8.0 * (i - 1.5)))
	_part(g, _caps(0.009, 0.045), _mats.glove, Vector3(0.036, -0.004, -0.018), Vector3(-90, 0, -50 if pointing else -65))
	return root


## A rubber duck, yellow, with an orange beak and a raised tail.
func _build_duck() -> Node3D:
	var root := Node3D.new()
	root.name = "Duck"
	root.set_meta("pose", Vector3(0.15, -0.13, -0.3))
	_part(root, _ball(0.045), _mats.duck, Vector3(0, 0, 0), Vector3.ZERO, Vector3(1.0, 0.78, 1.2))
	_part(root, _cyl(0.0, 0.022, 0.035, 16), _mats.duck, Vector3(0, 0.018, 0.055), Vector3(-60, 0, 0))
	_part(root, _ball(0.029), _mats.duck, Vector3(0, 0.045, -0.03))
	_part(root, _ball(0.013), _mats.beak, Vector3(0, 0.04, -0.058), Vector3.ZERO, Vector3(1.4, 0.45, 1.5))
	for x in [-0.014, 0.014]:
		_part(root, _ball(0.0045), _mats.eye, Vector3(x, 0.054, -0.05))
		_part(root, _ball(0.02), _mats.duck_wing, Vector3(x * 2.6, 0.006, 0.008), Vector3.ZERO, Vector3(0.35, 0.6, 1.1))
	return root


# --- Sounds ---------------------------------------------------------------------

func _play(sound: String, db: float) -> void:
	if _player == null or not _sounds.has(sound):
		return
	_player.stream = _sounds[sound]
	_player.volume_db = db
	_player.play()


## Short sounds, synthesized: the wheel's whoosh, the lamp's switch, a wooden tock and the duck's
## squeak (two formants sliding up and back, with a flutter).
func _make_sounds() -> void:
	var rate := 22050
	var whoosh := PackedFloat32Array()
	var lp := 0.0
	for i in int(rate * 0.32):
		var t := float(i) / rate
		var cut := 0.02 + 0.25 * t / 0.32
		lp += cut * (_rng.randf_range(-1.0, 1.0) - lp)
		whoosh.append(lp * sin(PI * t / 0.32) * 1.6)
	_sounds.whoosh = _wav(whoosh, rate)
	var click := PackedFloat32Array()
	for i in int(rate * 0.08):
		var t := float(i) / rate
		var v := sin(TAU * 3100.0 * t) * exp(-t * 260.0) * 0.6 + _rng.randf_range(-1.0, 1.0) * exp(-t * 900.0) * 0.5
		if t > 0.035:
			var u := t - 0.035
			v += sin(TAU * 2300.0 * u) * exp(-u * 300.0) * 0.35
		click.append(v)
	_sounds.click = _wav(click, rate)
	var tock := PackedFloat32Array()
	for i in int(rate * 0.12):
		var t := float(i) / rate
		tock.append((sin(TAU * 620.0 * t) + 0.5 * sin(TAU * 1490.0 * t)) * exp(-t * 55.0) * 0.6)
	_sounds.tock = _wav(tock, rate)
	var squeak := PackedFloat32Array()
	var phase := 0.0
	var dur := 0.24
	for i in int(rate * dur):
		var t := float(i) / rate
		var s := t / dur
		var f := 1250.0 + 1100.0 * sin(PI * pow(s, 0.7)) + 60.0 * sin(TAU * 34.0 * t)
		phase += TAU * f / rate
		var tone := tanh(2.5 * sin(phase)) * 0.55 + 0.25 * sin(2.0 * phase + 0.4)
		var env := minf(1.0, t / 0.012) * (1.0 - s) * (1.0 - s)
		squeak.append((tone + _rng.randf_range(-0.08, 0.08)) * env)
	_sounds.squeak = _wav(squeak, rate)
	# The quack: a buzzing saw falling from 520 to 330 Hz through a nasal resonance near 1.1 kHz,
	# cut off short.
	var quack := PackedFloat32Array()
	phase = 0.0
	dur = 0.2
	var bp := [0.0, 0.0]
	for i in int(rate * dur):
		var t := float(i) / rate
		var s := t / dur
		var f := lerpf(520.0, 330.0, s)
		phase = fmod(phase + f / rate, 1.0)
		var saw := 2.0 * phase - 1.0
		var y := _resonate(saw, 1100.0 + 250.0 * (1.0 - s), 6.0, rate, bp)
		var env := minf(1.0, t / 0.008) * (1.0 - pow(s, 3.0))
		quack.append(y * env)
	var peak := 0.0
	for x in quack:
		peak = maxf(peak, absf(x))
	for i in quack.size():
		quack[i] = tanh(2.5 * quack[i] / maxf(peak, 1e-6)) * 0.7  # loud to its peak, then a little fuzz
	_sounds.quack = _wav(quack, rate)
	# The spell: a rising shimmer of bells, with a fizz of sparks.
	var spell := PackedFloat32Array()
	dur = 0.7
	for i in int(rate * dur):
		var t := float(i) / rate
		var v := 0.0
		for k in 5:
			var start := 0.07 * k
			if t >= start:
				var u := t - start
				var f := 880.0 * pow(1.26, k) * (1.0 + 0.04 * u)
				v += (sin(TAU * f * u) + 0.3 * sin(TAU * f * 2.76 * u)) * exp(-u * 7.0) * 0.22
		v += _rng.randf_range(-1.0, 1.0) * exp(-t * 9.0) * 0.12 * (0.5 + 0.5 * sin(TAU * 31.0 * t))
		spell.append(v)
	_sounds.spell = _wav(spell, rate)
	# The ankh's chime: one low bell, its partials inharmonic, fading over a second and a half.
	var chime := PackedFloat32Array()
	dur = 1.5
	for i in int(rate * dur):
		var t := float(i) / rate
		var v := 0.0
		for p: Array in [[1.0, 1.0, 2.0], [2.76, 0.5, 3.2], [5.4, 0.25, 5.0], [8.93, 0.12, 7.0]]:
			v += sin(TAU * 392.0 * float(p[0]) * t) * float(p[1]) * exp(-t * float(p[2]))
		chime.append(v * minf(1.0, t / 0.004) * 0.38)
	_sounds.chime = _wav(chime, rate)
	# A TARS's footfall: a slab of metal set down, a short knock with a few inharmonic rings.
	var clank := PackedFloat32Array()
	dur = 0.16
	for i in int(rate * dur):
		var t := float(i) / rate
		var v := _rng.randf_range(-1.0, 1.0) * exp(-t * 400.0) * 0.5
		for p: Array in [[460.0, 0.5, 38.0], [1270.0, 0.35, 55.0], [2390.0, 0.22, 70.0], [3710.0, 0.12, 90.0]]:
			v += sin(TAU * float(p[0]) * t) * float(p[1]) * exp(-t * float(p[2]))
		clank.append(v * minf(1.0, t / 0.001) * 0.45)
	_sounds.clank = _wav(clank, rate)
	# A TARS gone home: two short square beeps, the second higher.
	var beep := PackedFloat32Array()
	dur = 0.3
	for i in int(rate * dur):
		var t := float(i) / rate
		var f := 880.0 if t < 0.13 else 1320.0
		var u := t if t < 0.13 else t - 0.17
		var on := (t < 0.11) or (t > 0.17 and t < 0.28)
		var v := 0.0
		if on:
			v = (0.6 * signf(sin(TAU * f * t)) + 0.4 * sin(TAU * f * t)) * minf(1.0, u / 0.004) * 0.22
		beep.append(v)
	_sounds.beep = _wav(beep, rate)
	# The whistle: a pea whistle's two blasts, short then long, a high tone that the pea trills, and
	# breath.
	var whistle := PackedFloat32Array()
	var breath := RandomNumberGenerator.new()
	breath.seed = 1903
	phase = 0.0
	dur = 0.62
	for i in int(rate * dur):
		var t := float(i) / rate
		var on := 0.0
		if t < 0.14:
			on = minf(1.0, t / 0.01) * minf(1.0, (0.14 - t) / 0.02)
		elif t > 0.2:
			on = minf(1.0, (t - 0.2) / 0.01) * minf(1.0, (dur - t) / 0.06)
		var trill := 0.5 + 0.5 * sin(TAU * 29.0 * t)
		phase += TAU * (2700.0 + 220.0 * trill) / rate
		var v := (sin(phase) * (0.6 + 0.4 * trill) + 0.12 * sin(2.0 * phase)) * 0.3 + breath.randf_range(-1.0, 1.0) * 0.05
		whistle.append(v * on)
	_sounds.whistle = _wav(whistle, rate)
	# The takes the author chose by ear replace these where their files are in the build; the
	# synthesized cues above stay for the rest (scripts/sfx_takes.gd).
	_sfx = load(SFX_PATH)
	stats.sound_takes = _sfx.call("pick_all", _sounds, "curio_wheel-")


## One sample through a two-pole resonator at f (Hz) with quality q; state holds its last two
## outputs.
static func _resonate(x: float, f: float, q: float, rate: int, state: Array) -> float:
	var w := TAU * f / rate
	var r := 1.0 - w / (2.0 * q)
	var y := (1.0 - r) * x + 2.0 * r * cos(w) * float(state[0]) - r * r * float(state[1])
	state[1] = state[0]
	state[0] = y
	return y


static func _wav(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w
