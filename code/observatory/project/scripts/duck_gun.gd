extends Node
## The rubber duck's two other modes, on its place on the curio wheel (scripts/curio_wheel.gd). The
## author, 2026-10-15: « les canards, je veux un mode mitraillette à canards et double mitraillette à
## canards sur la même position de la roue (utilise Shift pour toggle tri-state) », « je veux le
## chargement d'une arme en plastique (ou 2) façon Wolfenstein pour la mitrailleuse à canards », and
## « on ne peut pas jeter des canards à l'extérieur de l'observatoire!!! ».
## With the duck held, a tap of Shift steps through the duck thrown by hand (the wheel's own), the duck
## gun and two duck guns, and back; held longer, Shift is the sprint it always was. A gun is a toy:
## moulded plastic, three white barrels that spin, an orange tip, and on top a clear hopper of ducks.
## Picked, it comes up from under the view as an old shooter's gun does, the hopper is clipped on and
## the pump racked; then a button held fires ducks, RATE a second, at the centre of the view: either
## button the one gun, the left button the left gun and the right button the right one. Firing, the
## hopper's drum turns with the barrels and the ducks in it jostle. Back to the duck, the guns go down
## and the duck comes up.
## The author, 2026-10-16: « les barillets ... devraient tourner en même temps. Et on devrait voir les
## canards qui ballottent dans la barillette à canards ... des armes un petit peu plus grosses et un
## petit peu plus puissantes ... mitraillettes à canard indépendantes gauche-droite pour les boutons
## souris »: SCALE, SPEED (was 15 m/s), DRUM_GEAR, _jostle, _buttons.
## The same day: « mitraillette double en plastique, mais celle-là qui lance des dés ... en balancer plein
## et les voir rouler », and « avec le gun, créer des genres de trucs de dominos ... des trucs géants ... avec
## la physique des dominos qui tombent ». Two more steps of Shift: two dice guns (3), red and white, their
## hoppers full of small dice, each button its gun, DICE_RATE dice a second (d6, d8, d12, d20); and the
## domino layer (4), black and ivory: held, the left button lays a line where the centre of the view meets
## the ground, a domino every GAP of its height, the ghost of the next one shown there; the right button
## pushes the domino looked at; the wheel steps the size through SIZES (0.25 m to 4 m, or a line growing
## from GROW_FROM to 8 m); Backspace takes the last line away (with the dice guns, picks the dice up) and
## Delete every toy. The dice and dominoes are rigid bodies (scripts/toy_physics.gd, made the first time
## either is picked).
## On a touch screen (scripts/touch_controls.gd), which has no Shift and no mouse buttons, the duck held puts buttons
## of its own beside the touch controls (_touch_layout): the mode, over the curio wheel's button; in a gun mode, fire
## (held), over the right-hand column; with the dice guns or the domino layer, pick up or undo beside the mode (held
## HOLD_ALL, every toy); with the domino layer, lay (held) instead of fire, push, and the size.
## Every thrown duck that leaves the hall is flown here: the wheel kept its ducks within the shelves'
## front, wherever they were thrown from, so a duck thrown on the terrace landed back in the hall.
## Here a duck flies in the hall within the shelves' front (as the wheel's), in the library wing
## within its walls and vaults, and outside onto the terrace's paving and the gardens' ground, kept
## off the hall's wall and out of the gardens' solids. At rest in the hall it is handed back to the
## wheel (the Index names it); the ankh brings every duck home, waddling. MAX ducks at most, the
## oldest at rest going first. The gun's shapes, its sounds (synthesized here) and its moves are made
## here: nothing is taken from any game. Added by scripts/observatory.gd, after the wheel.

const TEXT := {
	"en": {"0": "RUBBER DUCK", "1": "DUCK GUN", "2": "TWIN DUCK GUNS", "3": "TWIN DICE GUNS", "4": "DOMINO LAYER",
		"hint": "Shift: duck  ·  gun  ·  two guns  ·  dice  ·  dominoes",
		"fire1": "Either mouse button: fire", "fire2": "Left button: left gun  ·  right button: right gun",
		"fire3": "Left button: left gun  ·  right button: right gun\nBackspace: pick the dice up  ·  Delete: every toy",
		"fire4": "Left button held: lay a line  ·  right button: push\nWheel: size  ·  Backspace: undo the line  ·  Delete: every toy",
		"size": "Dominoes %s m", "growing": "Dominoes growing from %s m to %s m", "laid": "%d laid  ·  %d down",
		"dice": "%d dice",
		"b0": "DUCK", "b1": "GUN", "b2": "2 GUNS", "b3": "DICE", "b4": "DOMINOES", "b_mode": "mode", "b_fire": "FIRE",
		"b_lay": "LAY", "b_push": "PUSH", "b_size": "size", "b_undo": "UNDO", "b_pick": "PICK UP", "b_all": "hold: all"},
	"fr": {"0": "CANARD EN CAOUTCHOUC", "1": "MITRAILLETTE À CANARDS", "2": "DOUBLE MITRAILLETTE À CANARDS",
		"3": "DOUBLE MITRAILLETTE À DÉS", "4": "POSEUR DE DOMINOS",
		"hint": "Maj : canard  ·  mitraillette  ·  double  ·  dés  ·  dominos",
		"fire1": "Clic gauche ou droit : tirer", "fire2": "Clic gauche : arme gauche  ·  clic droit : arme droite",
		"fire3": "Clic gauche : arme gauche  ·  clic droit : arme droite\nRetour arrière : ramasser les dés  ·  Suppr : tout enlever",
		"fire4": "Clic gauche maintenu : poser une ligne  ·  clic droit : pousser\nMolette : taille  ·  Retour arrière : annuler la ligne  ·  Suppr : tout enlever",
		"size": "Dominos de %s m", "growing": "Dominos croissants de %s m à %s m", "laid": "%d posés  ·  %d tombés",
		"dice": "%d dés",
		"b0": "CANARD", "b1": "ARME", "b2": "2 ARMES", "b3": "DÉS", "b4": "DOMINOS", "b_mode": "mode", "b_fire": "TIRER",
		"b_lay": "POSER", "b_push": "POUSSER", "b_size": "taille", "b_undo": "ANNULER", "b_pick": "RAMASSER",
		"b_all": "maintenu : tout"},
	"es": {"0": "PATO DE GOMA", "1": "AMETRALLADORA DE PATOS", "2": "DOBLE AMETRALLADORA DE PATOS",
		"3": "DOBLE AMETRALLADORA DE DADOS", "4": "PONEDOR DE DOMINÓS",
		"hint": "Mayús: pato  ·  ametralladora  ·  doble  ·  dados  ·  dominós",
		"fire1": "Clic izquierdo o derecho: disparar", "fire2": "Clic izquierdo: arma izquierda  ·  clic derecho: arma derecha",
		"fire3": "Clic izquierdo: arma izquierda  ·  clic derecho: arma derecha\nRetroceso: recoger los dados  ·  Supr: quitarlo todo",
		"fire4": "Clic izquierdo mantenido: poner una fila  ·  clic derecho: empujar\nRueda: tamaño  ·  Retroceso: deshacer la fila  ·  Supr: quitarlo todo",
		"size": "Dominós de %s m", "growing": "Dominós crecientes de %s m a %s m", "laid": "%d puestos  ·  %d caídos",
		"dice": "%d dados",
		"b0": "PATO", "b1": "ARMA", "b2": "2 ARMAS", "b3": "DADOS", "b4": "DOMINÓS", "b_mode": "modo", "b_fire": "DISPARAR",
		"b_lay": "PONER", "b_push": "EMPUJAR", "b_size": "tamaño", "b_undo": "DESHACER", "b_pick": "RECOGER",
		"b_all": "mantenido: todo"},
}
const GILT := Color(0.86, 0.7, 0.42)
const RATE := 10.0           # ducks a second, each gun
const SPEED := 21.0          # m/s out of the barrels
const SCALE := 1.3           # the toy, held: 48 cm from its grip's back to its tip
const DRUM_GEAR := 0.25      # turns of the hopper's drum to a turn of the barrels
const SPIN_V := 34.0         # rad/s of the barrels, firing
const SPREAD := 0.025        # rad either way
const MAX := 160             # ducks in all, the oldest at rest going first
const QUOTA := 23            # at rest in the wheel's own list: under its MAX_DUCKS (24), to which a throw trims it
const SHELF_R := 17.14       # the shelves' front, as the wheel's
const FACADE := 0.65         # m the hall's outside stands out of outer_radius (palace_gardens.gd FACADE_SKIN + OUT)
const TAP := 0.35            # s: a press of Shift shorter than this steps the mode
const RAISE := 0.34          # s to come up into view
const DROP := 0.2            # s to go down out of it
const LOAD := 0.72           # s: the hopper clipped on, the pump racked
const SQUEAK_GAP := 0.07     # s at least between two squeaks of the ducks flown here
const MUZZLE := Vector3(0.0, 0.03, -0.315)
const HOPPER_Y := 0.098
const SIDE_X := 0.2          # m either side of the view's axis, two guns
const MODES := 5             # the duck, one gun, two, the dice guns, the domino layer
const DICE_RATE := 12.0      # dice a second, each dice gun
const DICE_SPEED := 12.0     # m/s out of the barrels
const DICE_SPREAD := 0.05    # rad either way
const SIZES := [0.25, 0.5, 1.0, 2.0, 4.0, 0.0]  # m, the domino layer's heights; 0 a growing line
const GROW_FROM := 0.25      # m, a growing line's first domino
const REACH := 120.0         # m the domino layer reaches
const LAY_MAX := 40          # dominoes laid in a frame at most
const HOLD_ALL := 0.8        # s: the touch screen's pick-up or undo button held this long takes every toy away

var mode := 0
var lang := "en"
## Counts for tests.
var stats := {"modes": 0, "shots": 0, "loads": 0, "taken": 0, "home": 0, "parked": 0, "dice": 0, "laid": 0, "pushes": 0}

var _obs: Node
var _camera: Camera3D
var _curio: Node
var _touch := false
var _rig: Node3D
var _guns: Array[Node3D] = []
var _gun: Array = []          # each gun's {up, load, ready, loaded, kick, spin, spin_v, cool, x, firing, drum}
var _firing := false          # a button held
var _buttons := [false, false]  # the left button held, the right one
var _flying: Array = []       # ducks moving here: the wheel's {node, v, spin, resting, waddle, t, size} and a zone
var _parked: Array = []       # at rest here: outside the hall, or beyond the wheel's QUOTA
var _seen := {}               # the wheel's ducks already seen, by node id: only a new one is taken as thrown
var _template: Node3D         # a duck of the wheel's, duplicated: its meshes and materials shared
var _shift_at := -1.0
var _time := 0.0
var _revivals := 0
var _squeak_t := 0.0
var _note_t := 0.0
var _held_before := ""
var _duck_shown := true
var _bob := 0.0
var _walk := 0.0
var _last_cam := Vector3.INF
var _rng := RandomNumberGenerator.new()
var _layer: CanvasLayer
var _ui: Control
var _pop: AudioStreamPlayer
var _mech: AudioStreamPlayer
var _sounds := {}
var _mats := {}
var _toys: Node3D             # scripts/toy_physics.gd: the dice and the dominoes
var _size := 2                # in SIZES
var _line := false            # a line of dominoes being laid
var _line_n := 0              # laid in it
var _line_at := Vector2.ZERO  # its last domino: where it stands, its ground, its height
var _line_y := 0.0
var _line_h := 0.0
var _line_first: RigidBody3D  # turned along the line once the second is laid
var _click_t := 0.0
var _layer_tip: StandardMaterial3D  # the domino layer's tip: the next domino's colour
var _js_test: JavaScriptObject  # on the web, window.__obsToyTest (_toy_test), kept while the page lives
var _js_t := 0.0                # until window.__obsToys is written again
var _tbuttons := {}             # a touch screen's buttons, by name: their rectangles this frame (_touch_layout)
var _tdown := {}                # the touches on them: the button, by touch index
var _clear_at := -1.0           # since when the pick-up or undo button is held (_time), -1 none
var _tu := 1.0                  # the screen's shorter side, for the buttons


func configure(obs: Node, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	# Before the wheel (860): a duck it has just thrown outside is taken here before it moves it.
	process_priority = 855
	_rng.seed = 1944
	_curio = _obs.get_node_or_null("CurioWheel") if _obs != null else null
	_touch = _obs != null and _obs.get_node_or_null("TouchControls") != null
	if _curio != null:
		_revivals = int((_curio.get("stats") as Dictionary).get("revivals", 0))
		_held_before = str(_curio.get("equipped"))
	_mats = make_materials()
	var dice_mats := make_materials("dice")
	var layer_mats := make_materials("domino")
	_layer_tip = layer_mats.tip
	_rig = Node3D.new()
	_rig.name = "DuckGuns"
	if _camera != null:
		_camera.add_child(_rig)
	# Guns 0 and 1 the ducks', 2 and 3 the dice's (right, left), 4 the domino layer.
	for i in 5:
		var g := build_gun(_mats if i < 2 else (dice_mats if i < 4 else layer_mats), "duck" if i < 2 else ("dice" if i < 4 else "domino"))
		g.name = "Gun%d" % i
		g.visible = false
		_rig.add_child(g)
		_guns.append(g)
		_gun.append({"up": 0.0, "load": -1.0, "ready": false, "loaded": false, "kick": 0.0, "spin": 0.0, "spin_v": 0.0,
			"cool": 0.0, "x": _x_to(i), "firing": false, "drum": 0.0})
	_make_sounds()
	_make_ui()
	if OS.has_feature("web"):
		_js_test = JavaScriptBridge.create_callback(_toy_test)
		JavaScriptBridge.get_interface("window").set("__obsToyTest", _js_test)


func _exit_tree() -> void:
	if _template != null and is_instance_valid(_template):
		_template.free()  # never in the tree: freed by hand


func _t(key: String) -> String:
	return str(TEXT.get(lang, TEXT.en).get(key, TEXT.en[key]))


func _hud_shown() -> bool:
	var hud := _camera.get_parent().get_node_or_null("ControlsHud") if _camera != null else null
	return hud == null or bool(hud.get("visible"))


func _drone_away() -> bool:
	var drone := _obs.get_node_or_null("Drone") if _obs != null else null
	return drone != null and bool(drone.call("is_flying"))


func _holds_duck() -> bool:
	return _curio != null and str(_curio.get("equipped")) == "duck"


## Whether the left button is the guns': a gun mode, the duck held, the wheel shut, the interface
## shown, the drone in the hand.
func _armed() -> bool:
	return mode > 0 and _holds_duck() and not bool(_curio.call("is_open")) and _hud_shown() and not _drone_away()


## Steps to a mode: 0 the duck thrown by hand, 1 one gun, 2 two, 3 the dice guns, 4 the domino layer.
func set_mode(m: int) -> void:
	m = clampi(m, 0, MODES - 1)
	if m == mode:
		return
	mode = m
	stats.modes += 1
	_note_t = 2.4
	set_firing(false)  # a button held meant another thing
	if m >= 3:
		_toys_now()
	_mech.stream = _sounds.tick
	_mech.play()


## A button held or let go: 0 the left, 1 the right, -1 both. One gun fires while either is held; of two,
## the left button fires the left gun and the right button the right one. The domino layer lays while the
## left one is held.
func set_firing(on: bool, button := -1) -> void:
	for b in 2:
		if button < 0 or button == b:
			_buttons[b] = on and mode > 0
	_firing = bool(_buttons[0]) or bool(_buttons[1])


## Whether gun i is wanted up in this mode.
func _wanted(i: int) -> bool:
	match mode:
		1:
			return i == 0
		2:
			return i <= 1
		3:
			return i == 2 or i == 3
		4:
			return i == 4
	return false


## Where gun i is held across the view: one at the middle, two either side, the domino layer on the right
## (at the middle its hopper hid the ground the line is laid on).
func _x_to(i: int) -> float:
	match i:
		0:
			return SIDE_X if mode == 2 else 0.0
		1, 3:
			return -SIDE_X
	return SIDE_X


## Whether gun i's trigger is held.
func _trigger(i: int) -> bool:
	match mode:
		1:
			return i == 0 and _firing
		2:
			return i <= 1 and bool(_buttons[1 - i])
		3:
			return (i == 2 or i == 3) and bool(_buttons[3 - i])
		4:
			return i == 4 and bool(_buttons[0])
	return false


## The dice and dominoes' physics, made the first time they are wanted: the static shapes of the hall and the
## gardens are many (scripts/toy_physics.gd).
func _toys_now() -> Node3D:
	if _toys == null or not is_instance_valid(_toys):
		var t0 := Time.get_ticks_usec()
		_toys = (load("res://scripts/toy_physics.gd") as GDScript).new()
		_toys.name = "ToyPhysics"
		add_child(_toys)
		_toys.call("setup", _obs)
		_fill_dice()
		stats.toys_ms = snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.1)
	return _toys


## For the web tests (artpass/curios/toys-web.mjs), which can run no probe script: window.__obsToyTest(name)
## stages the toys as artpass/curios/toytest.gd does natively, and window.__obsToys reports them twice a second.
##   "dice": 30 dice of each kind thrown onto the hall's floor, off the steel box;
##   "line": 40 dominoes 0.4 m tall in a line on the hall's floor, the first pushed half a second later;
##   "load": 936 dominoes standing in six rings round the box and 300 dice at rest among them, the load whose
##           cost was measured natively (artpass/curios/NOTES.md);
##   "clear": every toy taken away.
func _toy_test(args: Array) -> void:
	var toys := _toys_now()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	toys.call("clear")
	match str(args[0]) if args.size() > 0 else "":
		"dice":
			for kind: String in ["d6", "d8", "d12", "d20"]:
				for i in 30:
					var a := rng.randf() * TAU
					var r := rng.randf_range(3.5, 9.0)
					toys.call("throw_die", Vector3(cos(a) * r, rng.randf_range(0.8, 2.2), sin(a) * r),
						Vector3(rng.randf_range(-3, 3), rng.randf_range(0, 2), rng.randf_range(-3, 3)), kind)
		"line":
			var gap := float((toys.get_script() as Script).get_script_constant_map().GAP)
			toys.call("begin_line")
			var at := Vector2(-4.5, -6.0)
			var first: RigidBody3D = null
			for i in 40:
				var g := float(toys.call("support", at, 3.0, 0.4))
				if is_nan(g):
					break
				var d: RigidBody3D = toys.call("lay", toys.call("domino_transform", at, g, Vector2.RIGHT, 0.4), 0.4)
				if first == null:
					first = d
				at += Vector2.RIGHT * gap * 0.4
			if first != null:
				await get_tree().create_timer(0.5).timeout
				if is_instance_valid(first):
					toys.call("push", first.global_position - Vector3.RIGHT + Vector3(0.0, 0.15, 0.0), Vector3.RIGHT)
		"load":
			for ring in 6:
				var r := 4.0 + ring * 1.6
				var count := int(TAU * r / 0.3)
				toys.call("begin_line")
				for k in count:
					var a := TAU * k / count
					toys.call("lay", toys.call("domino_transform", Vector2(cos(a), sin(a)) * r, 0.0, Vector2(-sin(a), cos(a)), 0.5), 0.5)
			for i in 300:
				toys.call("throw_die", Vector3(rng.randf_range(-3, 3), 1.0, rng.randf_range(-3, 3)), Vector3.ZERO)


func _publish_toys() -> void:
	var out := {"mode": mode, "engine": str(ProjectSettings.get_setting("physics/3d/physics_engine")), "guns": stats,
		"made": _toys != null, "touch": _touch, "size": _size, "buttons": {}}
	# The touch screen's buttons, in the canvas's pixels, with the canvas's size: a test taps their middles.
	for name: String in _tbuttons:
		var r: Rect2 = _tbuttons[name]
		out.buttons[name] = [r.position.x, r.position.y, r.size.x, r.size.y]
	if _ui != null:
		out.canvas = [_ui.get_viewport_rect().size.x, _ui.get_viewport_rect().size.y]
		out.clear = _tbuttons.is_empty() or _clear_of(_ui.get_viewport_rect().size, _others(), _tbuttons.values())
	if _toys != null:
		var on_floor := 0
		for d: Variant in _toys.call("dice"):
			if is_instance_valid(d):
				var p: Vector3 = (d as Node3D).global_position
				if p.y > 0.0 and p.y < 0.12 and Vector2(p.x, p.z).length() < 17.15:
					on_floor += 1
		out.toys = _toys.get("stats")
		out.on_floor = on_floor
	JavaScriptBridge.eval("window.__obsToys = %s" % JSON.stringify(out), true)


func _input(event: InputEvent) -> void:
	if _curio == null or _drone_away():
		return
	# A touch on one of the touch screen's buttons is theirs: the touch controls (earlier in the tree, so after
	# this node) never see it, and do not turn the view with it.
	if _touch and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		if _touch_input(event):
			get_viewport().set_input_as_handled()
		return
	# Shift, tapped with the duck held: the next mode. A touch screen's stick sends Shift to walk faster.
	var key := event as InputEventKey
	if key != null and not key.echo and not _touch:
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_SHIFT:
			if key.pressed:
				_shift_at = _time
			else:
				if _shift_at >= 0.0 and _time - _shift_at < TAP and _holds_duck() and _hud_shown() \
						and not bool(_curio.call("is_open")):
					set_mode((mode + 1) % MODES)
				_shift_at = -1.0
		elif key.pressed and mode >= 3 and _armed() and (code == KEY_BACKSPACE or code == KEY_DELETE):
			# Backspace: the last line taken away, or the dice picked up; Delete: every toy.
			if code == KEY_DELETE:
				clear_toys()
			elif mode == 4:
				undo_line()
			else:
				clear_dice()
			get_viewport().set_input_as_handled()
	# The buttons, while a gun mode is on: the wheel throws nothing, the guns fire while they are held. The
	# right button's drag-look (fly_camera.gd) is not wanted then: the view is already held by the mouse.
	var mb := event as InputEventMouseButton
	if mb == null or not _armed() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
		var b := 0 if mb.button_index == MOUSE_BUTTON_LEFT else 1
		if mode == 4 and b == 1:
			if mb.pressed:
				push_domino()
		else:
			set_firing(mb.pressed, b)
		get_viewport().set_input_as_handled()
	elif mode == 4 and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		# The domino layer's size; the wheel's other uses (the fly speed, the telescope) wait.
		if mb.pressed:
			set_size(_size + (1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1))
		get_viewport().set_input_as_handled()


## A touch on the touch screen's buttons, or a drag of one: whether it was theirs.
func _touch_input(event: InputEvent) -> bool:
	var t := event as InputEventScreenTouch
	if t != null:
		if t.pressed:
			var name := _tbutton_at(t.position)
			if name == "":
				return false
			_tdown[t.index] = name
			_tpress(name)
			return true
		if not _tdown.has(t.index):
			return false
		var was: String = _tdown[t.index]
		_tdown.erase(t.index)
		_trelease(was, (_tbuttons.get(was, Rect2()) as Rect2).grow(0.03 * _tu).has_point(t.position))
		return true
	var d := event as InputEventScreenDrag
	return d != null and _tdown.has(d.index)


func _tbutton_at(pos: Vector2) -> String:
	for name: String in _tbuttons:
		if (_tbuttons[name] as Rect2).grow(0.01 * _tu).has_point(pos):
			return name
	return ""


func _tpress(name: String) -> void:
	match name:
		"fire":
			set_firing(true, 0 if mode == 4 else -1)
		"push":
			push_domino()
		"clear":
			_clear_at = _time


## A touch let go of a button; `inside`: still on it (a tap's buttons act only then).
func _trelease(name: String, inside: bool) -> void:
	match name:
		"mode":
			if inside:
				set_mode((mode + 1) % MODES)
		"fire":
			set_firing(false)
		"size":
			if inside:
				set_size((_size + 1) % SIZES.size())
		"clear":
			if _clear_at >= 0.0 and inside:
				if mode == 4:
					undo_line()
				else:
					clear_dice()
			_clear_at = -1.0


## The touch screen's buttons this frame, with the duck held, the wheel shut, the interface shown and the drone in
## the hand; none otherwise. As large as the touch controls' (0.15 of the screen's shorter side, 0.03 apart), clear
## of them: the mode over the curio wheel's button, pick up or undo beside it; fire (or lay), over the right-hand
## column's highest button; push to its left and the size over it, or, where those would meet the language
## selector, the three in a row left of that button.
func _touch_layout() -> void:
	_tbuttons = {}
	if not _touch or _ui == null or not _holds_duck() or bool(_curio.call("is_open")) or not _hud_shown() or _drone_away():
		for i: int in _tdown:
			_trelease(str(_tdown[i]), false)
		_tdown.clear()
		return
	var size := _ui.get_viewport_rect().size
	var u := minf(size.x, size.y)
	_tu = u
	var m := 0.05 * u
	var b := 0.15 * u
	var g := 0.03 * u
	var others := _others()
	var curios: Rect2 = others.get("curios", Rect2(m, size.y - 0.57 * u, b, b))
	var left := Rect2(curios.position.x, curios.position.y - g - b, b, b)
	_tbuttons["mode"] = left
	if mode >= 3:
		_tbuttons["clear"] = Rect2(left.end.x + g, left.position.y, b, b)
	if mode > 0:
		var top := size.y - m - b
		var column := Rect2()
		for name: String in ["fly", "views", "ride"]:
			if others.has(name) and (others[name] as Rect2).position.y < top:
				top = (others[name] as Rect2).position.y
				column = others[name]
		var fire := Rect2(size.x - m - b, top - g - b, b, b)
		var push := Rect2(fire.position.x - g - b, fire.position.y, b, b)
		var step := Rect2(fire.position.x, fire.position.y - g - b * 0.6, b, b * 0.6)
		# Over the right-hand column; where that runs into the language selector (a phone held sideways, the
		# column high on a short screen: push lay over the build's line), a row left of the column's top button.
		# Chosen for the domino layer's three in every gun mode, so that fire does not move between modes.
		if column.has_area() and not _clear_of(size, others, [fire, push, step]):
			var row := Rect2(column.position.x - g - b, column.position.y, b, b)
			var row_push := Rect2(row.position.x - g - b, row.position.y, b, b)
			var row_step := Rect2(row_push.position.x - g - b, row.position.y + b * 0.2, b, b * 0.6)
			if _clear_of(size, others, [row, row_push, row_step]):
				fire = row
				push = row_push
				step = row_step
		_tbuttons["fire"] = fire
		if mode == 4:
			_tbuttons["push"] = push
			_tbuttons["size"] = step


## The touch controls' buttons (scripts/touch_controls.gd), by name.
func _others() -> Dictionary:
	var tc := _obs.get_node_or_null("TouchControls") if _obs != null else null
	var given: Variant = tc.get("_buttons") if tc != null else null
	return given if given is Dictionary else {}


## Whether these buttons lie on the screen, clear of the touch controls' (the help aside, which goes by
## itself) and of the language selector (scripts/course_library.gd).
func _clear_of(size: Vector2, others: Dictionary, mine: Array) -> bool:
	var lib := _obs.get_node_or_null("Generated/CourseShelves") if _obs != null else null
	var langs := lib.get("_lang_panel") as Control if lib != null else null
	var taken: Array = []
	for name: String in others:
		if name != "help":
			taken.append(others[name])
	if langs != null and langs.is_visible_in_tree():
		taken.append(langs.get_global_rect())
	for r: Rect2 in mine:
		if not Rect2(Vector2.ZERO, size).encloses(r):
			return false
		for t: Rect2 in taken:
			if r.intersects(t):
				return false
	return true


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.01)
	_time += real
	var lib := _obs.get_node_or_null("Generated/CourseShelves") if _obs != null else null
	if lib != null:
		lang = str(lib.get("lang"))
	_squeak_t = maxf(0.0, _squeak_t - delta)
	_note_t = maxf(0.0, _note_t - real)
	_click_t = maxf(0.0, _click_t - real)
	if _js_test != null:
		_js_t -= real
		if _js_t <= 0.0:
			_js_t = 0.5
			_publish_toys()
	if _curio == null or _camera == null:
		return
	var held := str(_curio.get("equipped"))
	if held == "duck" and _held_before != "duck":
		_note_t = 2.4  # the mode, and how to change it, each time the duck is picked
	_held_before = held
	if not _armed():
		set_firing(false)
	_take_ducks()
	_watch_ankh()
	_move(delta)
	_trim()
	_pose(real)
	_fire(delta)
	_lay()
	if _toys != null:
		var next: Color = _toys.call("next_colour")
		_layer_tip.albedo_color = next
		_layer_tip.emission = next
	_touch_layout()
	if _clear_at >= 0.0 and _time - _clear_at >= HOLD_ALL:
		_clear_at = -1.0  # held: every toy, and the release then does nothing more
		clear_toys()
	_ui.visible = (_note_t > 0.0 or _label() != "" or not _tbuttons.is_empty()) and _hud_shown()
	_ui.queue_redraw()


# --- Ducks ------------------------------------------------------------------------------------

## The wheel's ducks outside the hall, a new one just thrown or one waddling home, are flown here.
func _take_ducks() -> void:
	var list: Array = _curio.get("_ducks")
	var seen := {}
	for d: Dictionary in list.duplicate():
		var n := d.node as Node3D
		if not is_instance_valid(n):
			continue
		var id := n.get_instance_id()
		var fresh := not _seen.has(id)
		seen[id] = true
		if bool(d.resting):
			continue
		var p := n.global_position
		if Vector2(p.x, p.z).length() <= SHELF_R - 0.15 or not (fresh or bool(d.waddle)):
			continue
		list.erase(d)
		seen.erase(id)
		d.zone = "free" if bool(d.waddle) else _zone(p)
		_flying.append(d)
		stats.taken += 1
	_seen = seen


## Where a duck flies: "hall" within the shelves' front, "wing" in the library wing, "out" outside;
## "free" for one waddling home, which keeps only to the ground.
func _zone(p: Vector3) -> String:
	if Vector2(p.x, p.z).length() <= SHELF_R:
		return "hall"
	var wing := _wing()
	if wing != null:
		var q: Vector3 = wing.call("fly", p, 0.05)
		if q != Vector3.INF and q.distance_to(p) < 0.05:
			return "wing"
	return "out"


func _wing() -> Node:
	var wing := _obs.get_node_or_null("LibraryWing")
	return wing if wing != null and wing.has_method("fly") else null


func _gardens() -> Node:
	var g := _obs.get_node_or_null("PalaceGardens")
	return g if g != null and g.has_method("ground_at") else null


## The floor under p, no higher than p: the hall's and its galleries' (the walking body's), the
## wing's, the terrace's and the gardens' ground.
func _ground(p: Vector3, top: float) -> float:
	var flat := Vector2(p.x, p.z)
	var r := flat.length()
	if r <= SHELF_R + 0.5:
		var walker := _obs.get_node_or_null("WalkBody")
		if walker != null and walker.has_method("_support"):
			return maxf(0.0, float(walker.call("_support", flat, top)))
		return 0.0
	if r <= float(_obs.get("outer_radius")) + FACADE:
		return 0.0  # the bays' recesses, in the wall's thickness
	var wing := _wing()
	if wing != null:
		var q: Vector3 = wing.call("fly", Vector3(p.x, 1.0, p.z), 0.05)
		if q != Vector3.INF and Vector2(q.x - p.x, q.z - p.z).length() < 0.3:
			return 0.0
	var gardens := _gardens()
	return float(gardens.call("ground_at", flat)) if gardens != null else 0.0


## Gravity, the walls of the duck's zone, the floor under it; a bounce hard enough squeaks. As the
## wheel's own (curio_wheel.gd _move_ducks), whose rest rule and bounce this keeps.
func _move(delta: float) -> void:
	for d: Dictionary in _flying.duplicate():
		var n := d.node as Node3D
		if not is_instance_valid(n):
			_flying.erase(d)
			continue
		var v: Vector3 = d.v
		var size := float(d.get("size", 1.0))
		if bool(d.waddle):
			d.t = float(d.t) + delta
			if float(d.t) < 0.0:
				continue
			var to := _camera.global_position - n.global_position
			var flat_to := Vector2(to.x, to.z)
			if flat_to.length() < 0.5 or float(d.t) > 9.0:
				_curio.call("_sparkle", n.global_position + Vector3(0, 0.05, 0), Color(0.55, 1.0, 0.65))
				_curio.call("_sound_at", "quack", n.global_position, 1.0)
				var cs: Dictionary = _curio.get("stats")
				cs.home = int(cs.home) + 1
				stats.home += 1
				_flying.erase(d)
				n.queue_free()
				continue
			var walk := flat_to.normalized() * 1.1
			v.x = walk.x
			v.z = walk.y
			n.look_at(n.global_position + Vector3(walk.x, 0.0, walk.y) + Vector3(0, 0.0001, 0), Vector3.UP)
			n.rotate_object_local(Vector3.FORWARD, sin(float(d.t) * 13.0) * 0.28)
			if fmod(float(d.t), 1.3) < delta and _rng.randf() < 0.6:
				_curio.call("_sound_at", "quack", n.global_position, 0.6)
		v.y -= 9.8 * delta
		var from := n.global_position
		var p := from + v * delta
		var half := 0.045 * size
		var zone := str(d.get("zone", "hall"))
		if zone == "hall":
			var flat := Vector2(p.x, p.z)
			if flat.length() > SHELF_R - 0.08 * size:
				var out := flat.normalized()
				flat = out * (SHELF_R - 0.08 * size)
				var vr := Vector2(v.x, v.z).dot(out)
				if vr > 0.0:
					v.x -= out.x * vr * 1.5
					v.z -= out.y * vr * 1.5
				p = Vector3(flat.x, p.y, flat.y)
		elif zone == "wing":
			# Its walls and vaults (library_wing.gd fly); its floor, below, is the hall's.
			var wing := _wing()
			var probe := Vector3(p.x, maxf(p.y, half), p.z)
			var q: Vector3 = wing.call("fly", probe, half) if wing != null else Vector3.INF
			if q == Vector3.INF:
				d.zone = _zone(p)  # out through the portal, into the hall
			elif q.distance_to(probe) > 1e-4:
				var nrm := (q - probe).normalized()
				var vn := v.dot(nrm)
				if vn < 0.0:
					v -= nrm * vn * 1.5
				p = Vector3(q.x, q.y if q.y < probe.y - 1e-4 else p.y, q.z)
		elif zone == "out" and p.y < 24.0:
			# Off the hall's wall, and out of the gardens' solids near the ground.
			var flat := Vector2(p.x, p.z)
			var wall := float(_obs.get("outer_radius")) + FACADE + half
			if flat.length() < wall and _wing_free(p):
				var out := flat.normalized() if flat.length() > 1e-4 else Vector2.RIGHT
				var vr := Vector2(v.x, v.z).dot(out)
				if vr < 0.0:
					v.x -= out.x * vr * 1.5
					v.z -= out.y * vr * 1.5
				flat = out * wall
				p = Vector3(flat.x, p.y, flat.y)
			var gardens := _gardens()
			if gardens != null and gardens.has_method("push_out"):
				var g0 := float(gardens.call("ground_at", flat))
				if p.y < g0 + 1.2:
					var pushed: Vector2 = gardens.call("push_out", flat, half, g0)
					if pushed.distance_to(flat) > 1e-4:
						var out := (pushed - flat).normalized()
						var vr := Vector2(v.x, v.z).dot(out)
						if vr < 0.0:
							v.x -= out.x * vr * 1.5
							v.z -= out.y * vr * 1.5
						p = Vector3(pushed.x, p.y, pushed.y)
		var floor_y := _ground(p, from.y + 0.05)
		if p.y < floor_y + half:
			p.y = floor_y + half
			if v.y < -0.6:
				_squeak(from, minf(1.0, -v.y / 6.0))
			if bool(d.waddle):
				v.y = 0.0
			else:
				v.y = -v.y * 0.42
				v.x *= 0.72
				v.z *= 0.72
				d.spin = float(d.spin) * 0.6
				if Vector2(v.x, v.z).length() < 0.25 and v.y < 0.25 + 9.8 * delta:
					v = Vector3.ZERO
					d.resting = true
		n.global_position = p
		if not bool(d.waddle):
			n.rotate_y(float(d.spin) * delta)
		d.v = v
		if bool(d.resting):
			_flying.erase(d)
			_rest(d)


## Whether p, outside the hall, is clear of the library wing's own walls (its portal opens in the
## hall's wall: a duck flown out of the wing there is not stopped by that wall).
func _wing_free(p: Vector3) -> bool:
	var wing := _wing()
	return wing == null or wing.call("fly", p, 0.05) == Vector3.INF


func _squeak(at: Vector3, strength: float) -> void:
	if _squeak_t > 0.0:
		return
	_squeak_t = SQUEAK_GAP
	_curio.call("_squeak", at, strength)


## A duck come to rest: in the hall, back to the wheel, whose Index names it and whose ankh lifts it
## (QUOTA at most there, the oldest parked here); elsewhere parked here.
func _rest(d: Dictionary) -> void:
	var n := d.node as Node3D
	if Vector2(n.global_position.x, n.global_position.z).length() > SHELF_R - 0.05:
		_parked.append(d)
		stats.parked += 1
		return
	d.erase("zone")
	var list: Array = _curio.get("_ducks")
	list.append(d)
	_seen[n.get_instance_id()] = true
	while list.size() > QUOTA:
		var i := 0
		while i < list.size() and not bool((list[i] as Dictionary).resting):
			i += 1
		if i >= list.size():
			break
		var old: Dictionary = list[i]
		list.remove_at(i)
		_parked.append(old)


## The ankh, used: the ducks flown or parked here get up and waddle home too.
func _watch_ankh() -> void:
	var r := int((_curio.get("stats") as Dictionary).get("revivals", 0))
	if r == _revivals:
		return
	_revivals = r
	var k := 0
	for d: Dictionary in _parked + _flying:
		d.waddle = true
		d.resting = false
		d.t = -0.04 * k  # one after the other, quickly: there may be a hundred
		d.v = Vector3(0, 1.2, 0)
		d.zone = "free"
		k += 1
	_flying.append_array(_parked)
	_parked.clear()


## MAX ducks in all: the oldest parked go first, then the wheel's oldest at rest, then the oldest
## flying.
func _trim() -> void:
	var list: Array = _curio.get("_ducks")
	while list.size() + _parked.size() + _flying.size() > MAX:
		var d: Dictionary
		if not _parked.is_empty():
			d = _parked.pop_front()
		elif not list.is_empty() and bool((list[0] as Dictionary).resting):
			d = list.pop_front()
		elif not _flying.is_empty():
			d = _flying.pop_front()
		else:
			break
		if is_instance_valid(d.node):
			(d.node as Node).queue_free()


# --- The guns ---------------------------------------------------------------------------------

func _fire(delta: float) -> void:
	for i in _guns.size():
		var g: Dictionary = _gun[i]
		var shooting := _trigger(i) and bool(g.ready) and _wanted(i)
		var period := 1.0 / (RATE if i < 2 else DICE_RATE)
		if shooting and not bool(g.firing) and i < 4:
			# Fires at once; the other gun firing already, between its shots.
			var o: Dictionary = _gun[i ^ 1]
			g.cool = fposmod(float(o.cool) + 0.5 * period, period) if bool(o.firing) else 0.0
		g.firing = shooting
		g.spin_v = move_toward(float(g.spin_v), SPIN_V if shooting else 0.0, delta * (70.0 if shooting else 22.0))
		g.spin = fmod(float(g.spin) + float(g.spin_v) * delta, TAU)
		# The hopper's drum, geared to the barrels: it turns as they do, feeding them.
		g.drum = fmod(float(g.drum) + float(g.spin_v) * DRUM_GEAR * delta, TAU)
		if not shooting or i == 4:
			continue  # the domino layer lays (_lay), it does not shoot
		g.cool = float(g.cool) - delta
		while float(g.cool) <= 0.0:
			if i < 2:
				_shoot(i)
			else:
				_shoot_die(i)
			g.cool = float(g.cool) + period


## From the muzzle to the centre of the view, scattered by up to `spread` either way.
func _aim_from(muzzle: Vector3, spread: float) -> Vector3:
	var c := _camera.get_viewport().get_visible_rect().size * 0.5
	var aim := _camera.project_ray_origin(c) + _camera.project_ray_normal(c) * 30.0
	var dir := (aim - muzzle).normalized()
	var cb := _camera.global_basis
	return (Basis(cb.x.normalized(), _rng.randf_range(-spread, spread)) * Basis(cb.y.normalized(), _rng.randf_range(-spread, spread)) * dir).normalized()


## A die out of dice gun i, at the centre of the view, more scattered than a duck and turning
## (toy_physics.gd throw_die: a d6, d8, d12 or d20 of a colour at random).
func _shoot_die(i: int) -> void:
	if _toys == null:
		return
	var muzzle := _guns[i].global_transform * MUZZLE
	_toys.call("throw_die", muzzle, _aim_from(muzzle, DICE_SPREAD) * DICE_SPEED + Vector3(0, 0.6, 0))
	var g: Dictionary = _gun[i]
	g.kick = 1.0
	stats.dice += 1
	_pop.pitch_scale = _rng.randf_range(0.62, 0.74)
	_pop.play()


## A duck out of gun i's barrels, at the centre of the view, a little scattered.
func _shoot(i: int) -> void:
	var gun := _guns[i]
	var muzzle := gun.global_transform * MUZZLE
	var dir := _aim_from(muzzle, SPREAD)
	var cb := _camera.global_basis
	if _template == null or not is_instance_valid(_template):
		_template = _curio.call("_build_duck")
	var duck := _template.duplicate() as Node3D
	_obs.add_child(duck)
	duck.global_position = muzzle
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() < 0.01:
		flat = Vector3(-cb.z.x, 0.0, -cb.z.z)
	duck.look_at(muzzle + flat.normalized() + Vector3(0, 0.0001, 0), Vector3.UP)
	_flying.append({"node": duck, "v": dir * SPEED + Vector3(0, 0.8, 0), "spin": _rng.randf_range(-3.0, 3.0),
		"resting": false, "waddle": false, "t": 0.0, "size": 1.0, "zone": _zone(_camera.global_position)})
	var g: Dictionary = _gun[i]
	g.kick = 1.0
	stats.shots += 1
	var cs: Dictionary = _curio.get("stats")
	cs.ducks = int(cs.ducks) + 1
	_pop.pitch_scale = _rng.randf_range(0.9, 1.12)
	_pop.play()


## The guns' places: up or down, the hopper clipped on and the pump racked as each comes up, the
## kick of each shot, the sway of the look (the wheel's) and the bob of the walk.
func _pose(real: float) -> void:
	var walker := _obs.get_node_or_null("WalkBody")
	var reading := walker != null and walker.has_method("is_reading") and bool(walker.call("is_reading"))
	var shown := _hud_shown()
	var hold := _holds_duck() and shown and not reading and not _drone_away()
	var calm := bool(_curio.get("reduced_motion"))
	# The walk's bob, from how fast the camera goes over the ground.
	var cp := _camera.global_position
	var speed := 0.0
	if _last_cam != Vector3.INF and real > 0.0:
		speed = minf(Vector2(cp.x - _last_cam.x, cp.z - _last_cam.z).length() / real, 8.0)
	_last_cam = cp
	_walk = lerpf(_walk, clampf(speed / 3.0, 0.0, 1.0), 1.0 - exp(-8.0 * real))
	_bob += real * (3.0 + speed * 1.6)
	var bob := Vector2(sin(_bob) * 0.011, -absf(cos(_bob)) * 0.009) * (0.0 if calm else _walk)
	var sway: Vector2 = _curio.get("_sway") if not calm else Vector2.ZERO
	var any := false
	for i in _guns.size():
		var g: Dictionary = _gun[i]
		var want := hold and _wanted(i)
		var was := float(g.up)
		g.up = move_toward(was, 1.0 if want else 0.0, real / (RAISE if want else DROP))
		if want and was < 1.0 and float(g.up) >= 1.0 and not bool(g.ready):
			g.load = 0.0
			stats.loads += 1
		if float(g.up) <= 0.0:
			g.ready = false
			g.loaded = false
			g.load = -1.0
		if float(g.load) >= 0.0:
			var l0 := float(g.load)
			g.load = l0 + real
			_load_sounds(l0, float(g.load))
			if float(g.load) >= LOAD:
				g.load = -1.0
				g.ready = true
				g.loaded = true
		g.kick = move_toward(float(g.kick), 0.0, real * 9.0)
		g.x = lerpf(float(g.x), _x_to(i), 1.0 - exp(-10.0 * real))
		any = any or float(g.up) > 0.0
		var gun := _guns[i]
		gun.visible = float(g.up) > 0.0 and shown
		if not gun.visible:
			continue
		var e := 1.0 - pow(1.0 - float(g.up), 3.0)
		var side := -1.0 if i == 1 or i == 3 else 1.0
		# Held low enough that the hopper's top stays under the centre of the view, held bigger (SCALE): at -0.25 m
		# it rose to the centre and hid what the single gun aimed at (artpass/curios/gun_shots.gd, 2026-10-16).
		var pos := Vector3(float(g.x), -0.3, -0.42) + Vector3(sway.x * 0.5 + bob.x * side, sway.y * 0.5 + bob.y - (1.0 - e) * 0.42, 0.0)
		pos.z += 0.022 * float(g.kick)
		var b := Basis.looking_at(Vector3(0.0, 0.0, -8.0) - pos, Vector3.UP)
		b = b * Basis(Vector3.RIGHT, -(1.0 - e) * 0.9 + 0.07 * float(g.kick))  # tipped down coming up; the kick lifts it
		b = b * Basis(Vector3.BACK, (1.0 - e) * 0.45 * side)
		var lt := float(g.load)
		if lt >= 0.0:
			b = b * Basis(Vector3.BACK, sin(PI * clampf(lt / LOAD, 0.0, 1.0)) * 0.2 * side)  # turned to the hand that racks it
		gun.transform = Transform3D(b.scaled(Vector3.ONE * SCALE), pos)
		var hopper := gun.get_node("Hopper") as Node3D
		hopper.visible = bool(g.loaded) or lt >= 0.0
		var drop := 0.0 if lt < 0.0 else 0.13 * pow(1.0 - smoothstep(0.0, 0.26, lt), 2.0)
		var jiggle := (float(g.spin_v) / SPIN_V) * sin(_time * 41.0 + i) * 0.04
		hopper.position = Vector3(0.0, HOPPER_Y + drop, -0.06)
		hopper.rotation = Vector3(0.0, 0.0, jiggle)
		if hopper.visible:
			_jostle(hopper.get_node("Drum") as Node3D, g, i, lt, calm)
		var rack := 0.0
		if lt >= 0.32:
			rack = smoothstep(0.32, 0.46, lt) * (1.0 - smoothstep(0.5, 0.64, lt))
		(gun.get_node("Slide") as Node3D).position = Vector3(0.0, 0.0, 0.045 * rack)
		(gun.get_node("Barrels") as Node3D).rotation = Vector3(0.0, 0.0, float(g.spin))
	# The wheel's own duck: hidden while a gun is up or on its way, and raised from below once both are
	# down.
	var duck_on := not (_holds_duck() and (mode > 0 or any))
	if duck_on != _duck_shown:
		_duck_shown = duck_on
		var held := (_curio.get("_models") as Dictionary).get("duck") as Node3D
		if held != null:
			for c in held.get_children():
				(c as Node3D).visible = duck_on
		if duck_on and _holds_duck():
			_curio.set("_raise", 0.0)


## The hopper's drum turned with the barrels (g.drum), and each duck in it jostling on its own: hopping,
## rocking and slewing, the more as the barrels spin, a shot kicks, the walk bobs, or the hopper is clipped on.
func _jostle(drum: Node3D, g: Dictionary, i: int, lt: float, calm: bool) -> void:
	drum.rotation = Vector3(0.0, float(g.drum), 0.0)
	var shake := float(g.spin_v) / SPIN_V + float(g.kick) * 0.7 + _walk * 0.35
	if lt >= 0.0:
		shake += 1.2 * (1.0 - smoothstep(0.2, 0.7, lt))  # clipped on: they settle
	shake = clampf(shake, 0.0, 1.2) * (0.3 if calm else 1.0)  # at 1.2 the highest head clears the lid
	var k := 0
	for duck in drum.get_children():
		if not duck.has_meta("rest"):
			continue
		var rest: Transform3D = duck.get_meta("rest")
		var ph := float(k) * 1.93 + float(i) * 0.71
		var hop := absf(sin(_time * (15.0 + 2.3 * k) + ph)) * (0.003 if k == 6 else 0.009) * shake
		var slosh := Vector3(sin(_time * (9.0 + 1.7 * k) + ph), 0.0, cos(_time * (8.0 + 1.3 * k) + ph * 1.3)) * 0.004 * shake
		var rock := Basis.from_euler(Vector3(sin(_time * (11.0 + k) + ph) * 0.45, sin(_time * (6.0 + 0.9 * k) + ph * 2.0) * 0.5,
			sin(_time * (13.0 + 1.1 * k) + ph * 0.6) * 0.45) * shake)
		(duck as Node3D).transform = Transform3D(rest.basis * rock, rest.origin + slosh + Vector3(0.0, hop, 0.0))
		k += 1


func _load_sounds(l0: float, l1: float) -> void:
	for at: Array in [[0.26, "clack"], [0.32, "ratchet"], [0.5, "clack"]]:
		if l0 < float(at[0]) and l1 >= float(at[0]):
			_mech.stream = _sounds[at[1]]
			_mech.pitch_scale = 1.0 if at[0] != 0.5 else 1.18
			_mech.play()


# --- Dice and dominoes ------------------------------------------------------------------------

## The dice guns' hoppers, filled with small dice of every kind once the dice are made.
func _fill_dice() -> void:
	var tk: Dictionary = (_toys.get_script() as Script).get_script_constant_map()
	var kinds: Array = tk.KINDS
	var small := 0.012 / float(tk.DIE_R)  # 12 mm from its centre to its corners
	for i in [2, 3]:
		var drum := _guns[i].get_node("Hopper/Drum") as Node3D
		for k in 7:
			var a := TAU * k / 6.0 + 0.4
			var r := 0.024 if k < 6 else 0.0
			var holder := Node3D.new()
			holder.position = Vector3(cos(a) * r, 0.018 + 0.022 * float(k % 2) + (0.036 if k == 6 else 0.0), sin(a) * r)
			holder.rotation = Vector3(float(k) * 1.1 + float(i), a * 1.7, float(k) * 0.7)
			holder.set_meta("rest", Transform3D(Basis.from_euler(holder.rotation), holder.position))
			drum.add_child(holder)
			var mi := MeshInstance3D.new()
			mi.mesh = _toys.call("die_mesh", kinds[(k + i) % kinds.size()], (k * 3 + i) % 8)
			mi.scale = Vector3.ONE * small
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(mi)


## The domino layer's size: an index in SIZES, kept within it.
func set_size(i: int) -> void:
	i = clampi(i, 0, SIZES.size() - 1)
	if i == _size:
		return
	_size = i
	_mech.stream = _sounds.tick
	_mech.pitch_scale = 0.8 + 0.12 * float(i)
	_mech.play()


## The next domino's height: the size picked, or, in a growing line, GROW times the last one's.
func _next_h() -> float:
	var h := float(SIZES[_size])
	if h > 0.0:
		return h
	if not _line or _line_n == 0:
		return GROW_FROM
	var k: Dictionary = (_toys.get_script() as Script).get_script_constant_map()
	return minf(_line_h * float(k.GROW), float(k.GROW_MAX))


## The view's ray from the middle of the screen: [origin, direction].
func _view_ray() -> Array:
	var c := _camera.get_viewport().get_visible_rect().size * 0.5
	return [_camera.project_ray_origin(c), _camera.project_ray_normal(c)]


## The domino layer, each frame: the ghost of the next domino where the middle of the view meets the ground,
## and, while the left button is held, a line laid towards it, a domino every GAP of the last one's height
## (more if the next is much thicker), LAY_MAX at most a frame. The first stands across the view, then is
## turned along the line once the second is down.
func _lay() -> void:
	var g4: Dictionary = _gun[4]
	var on := mode == 4 and _toys != null and _armed() and bool(g4.ready)
	if not on:
		if _toys != null:
			_toys.call("show_ghost", false)
		_line = false
		return
	var ray := _view_ray()
	var hit: Dictionary = _toys.call("aim", ray[0], ray[1], REACH)
	var ok := not hit.is_empty() and (hit.normal as Vector3).y >= 0.85
	var at: Vector3 = hit.get("at", Vector3.ZERO)
	var xz := Vector2(at.x, at.z)
	var fwd := Vector2(-_camera.global_basis.z.x, -_camera.global_basis.z.z)
	fwd = fwd.normalized() if fwd.length() > 1e-3 else Vector2(0.0, -1.0)
	var held := bool(_buttons[0])
	if held and not _line:
		_line = true
		_line_n = 0
		_line_first = null
		_toys.call("begin_line")
	elif not held:
		_line = false
	var k: Dictionary = (_toys.get_script() as Script).get_script_constant_map()
	var gap := float(k.GAP)
	var thick := float((k.DOMINO as Vector3).z)
	if ok and _line:
		if _line_n == 0:
			var h0 := _next_h()
			var y0 := float(_toys.call("support", xz, at.y, h0))
			if not is_nan(y0):
				var d0: RigidBody3D = _toys.call("lay", _toys.call("domino_transform", xz, y0, fwd, h0), h0)
				if d0 != null:
					_laid(d0, xz, y0, h0)
					_line_first = d0
		else:
			for n in LAY_MAX:
				var hn := _next_h()
				var s := maxf(gap * _line_h, 0.5 * thick * (_line_h + hn) + 0.02)
				var to := xz - _line_at
				if to.length() < s:
					break
				var along := to.normalized()
				var p := _line_at + along * s
				var y := float(_toys.call("support", p, _line_y, hn))
				var d: RigidBody3D = null
				if not is_nan(y):
					d = _toys.call("lay", _toys.call("domino_transform", p, y, along, hn), hn)
				if d == null:
					_line_at = p  # no ground, or in the way: the line goes on past it
					continue
				_laid(d, p, y, hn)
				if _line_n == 2 and is_instance_valid(_line_first):
					var xf := _line_first.global_transform
					xf.basis = Basis.looking_at(Vector3(along.x, 0.0, along.y), Vector3.UP)
					_line_first.global_transform = xf
	# The ghost: where the next would stand, turned along the line (across the view before it starts).
	var h := _next_h()
	var gy := float(_toys.call("support", xz, at.y, h)) if ok else NAN
	if is_nan(gy):
		_toys.call("show_ghost", false)
		return
	var face := fwd
	if _line and _line_n > 0 and xz.distance_to(_line_at) > 1e-3:
		face = (xz - _line_at).normalized()
	_toys.call("show_ghost", true, _toys.call("domino_transform", xz, gy, face, h), h)


func _laid(d: RigidBody3D, xz: Vector2, y: float, h: float) -> void:
	_line_at = xz
	_line_y = y
	_line_h = h
	_line_n += 1
	stats.laid += 1
	(_gun[4] as Dictionary).kick = 0.5
	if _click_t <= 0.0:
		_click_t = 0.06
		_mech.stream = _sounds.clack
		_mech.pitch_scale = clampf(1.5 / sqrt(maxf(h, 0.1)), 0.6, 2.4)
		_mech.play()


## A push on the domino (or die) in the middle of the view, or on the domino nearest where it meets the
## ground: true if one was pushed.
func push_domino() -> bool:
	if _toys == null:
		return false
	var ray := _view_ray()
	var pushed := bool(_toys.call("push", ray[0], ray[1], REACH))
	(_gun[4] as Dictionary).kick = 1.0
	stats.pushes += 1
	_mech.stream = _sounds.ratchet if pushed else _sounds.tick
	_mech.pitch_scale = 1.3
	_mech.play()
	return pushed


## The last line laid, taken away: how many dominoes.
func undo_line() -> int:
	if _toys == null:
		return 0
	_line = false
	var n := int(_toys.call("undo"))
	if n > 0:
		_mech.stream = _sounds.ratchet
		_mech.pitch_scale = 0.8
		_mech.play()
	return n


func clear_dice() -> void:
	if _toys != null:
		_toys.call("clear_dice")
		_mech.stream = _sounds.ratchet
		_mech.pitch_scale = 0.9
		_mech.play()


func clear_toys() -> void:
	if _toys != null:
		_line = false
		_toys.call("clear")
		_mech.stream = _sounds.ratchet
		_mech.pitch_scale = 0.7
		_mech.play()


## A height in metres as the reader writes it: 0.25 in English, 0,25 in French and Spanish.
func _metres(h: float) -> String:
	var s := ("%.2f" % h).rstrip("0").rstrip(".")
	return s if lang == "en" else s.replace(".", ",")


## The count under the view while the dice guns or the domino layer are up: the dice; the size and the
## dominoes laid and fallen.
func _label() -> String:
	if _toys == null or not _armed() or mode < 3 or _touch:
		return ""
	var st: Dictionary = _toys.get("stats")
	if mode == 3:
		return _t("dice") % int(st.dice)
	var h := float(SIZES[_size])
	var k: Dictionary = (_toys.get_script() as Script).get_script_constant_map()
	var size := _t("size") % _metres(h) if h > 0.0 else _t("growing") % [_metres(GROW_FROM), _metres(float(k.GROW_MAX))]
	return "%s  ·  %s" % [size, _t("laid") % [int(st.dominoes), int(st.fallen)]]


# --- On screen --------------------------------------------------------------------------------

func _make_ui() -> void:
	# Under the wheel (40) and the drone's flight (45).
	_layer = CanvasLayer.new()
	_layer.layer = 38
	add_child(_layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.visible = false
	_ui.draw.connect(_draw_ui)
	_layer.add_child(_ui)


## The mode's name over the view a moment, the key that changes it and the buttons; with the dice guns or
## the domino layer up, their count under the view.
func _draw_ui() -> void:
	var size := _ui.get_viewport_rect().size
	var u := minf(size.x, size.y)
	var font := ThemeDB.fallback_font
	var fs := roundi(clampf(u * 0.038, 16.0, 34.0))
	var hs := roundi(fs * 0.55)
	_draw_tbuttons()
	var label := _label()
	if label != "":
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x
		var ly := size.y * 0.9
		var lbox := Rect2(size.x * 0.5 - lw * 0.5 - hs, ly - hs * 1.25, lw + hs * 2.0, hs * 1.8)
		_ui.draw_rect(lbox, Color(0.035, 0.03, 0.028, 0.62))
		_ui.draw_string(font, Vector2(size.x * 0.5 - lw * 0.5, ly), label, HORIZONTAL_ALIGNMENT_LEFT, -1, hs, Color(0.9, 0.86, 0.78))
	if _note_t <= 0.0:
		return
	var a := clampf(_note_t / 0.5, 0.0, 1.0)
	var title := _t(str(mode))
	var texts: Array[String] = []
	if not _touch:
		texts.append(_t("hint"))
		if mode > 0:
			for line in _t("fire%d" % mode).split("\n"):
				texts.append(line)
	var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	for text in texts:
		w = maxf(w, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x)
	var y := size.y * 0.18
	var box := Rect2(size.x * 0.5 - w * 0.5 - fs, y - fs * 1.15, w + fs * 2.0, fs * (1.9 + 0.9 * float(texts.size())))
	_ui.draw_rect(box, Color(0.035, 0.03, 0.028, 0.82 * a))
	_ui.draw_rect(box, Color(GILT, 0.7 * a), false, 1.5)
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_ui.draw_string(font, Vector2(size.x * 0.5 - tw * 0.5, y + fs * 0.25), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(GILT, a))
	var line_y := y + fs * 1.15
	for text in texts:
		var hw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x
		_ui.draw_string(font, Vector2(size.x * 0.5 - hw * 0.5, line_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, hs, Color(0.9, 0.86, 0.78, a))
		line_y += fs * 0.9


## The touch screen's buttons, drawn as the touch controls draw theirs: dark, edged in gilt, lit while held; each its
## word, and under it a smaller one (the mode's "mode", the size's "size", pick up's or undo's "hold: all", which
## fills the button as it is held).
func _draw_tbuttons() -> void:
	var held := {}
	for i: int in _tdown:
		held[_tdown[i]] = true
	for name: String in _tbuttons:
		var r: Rect2 = _tbuttons[name]
		var lit: bool = held.has(name) or (name == "fire" and _firing)
		var word := ""
		var small := ""
		match name:
			"mode":
				word = _t("b%d" % mode)
				small = _t("b_mode")
			"fire":
				word = _t("b_lay" if mode == 4 else "b_fire")
			"push":
				word = _t("b_push")
			"size":
				var h := float(SIZES[_size])
				var k: Dictionary = (_toys.get_script() as Script).get_script_constant_map() if _toys != null else {"GROW_MAX": 8.0}
				word = (_metres(h) + " m") if h > 0.0 else "%s-%s m" % [_metres(GROW_FROM), _metres(float(k.GROW_MAX))]
				small = _t("b_size")
			"clear":
				word = _t("b_undo" if mode == 4 else "b_pick")
				small = _t("b_all")
		_ui.draw_rect(r, Color(GILT, 0.45) if lit else Color(0.05, 0.06, 0.09, 0.55))
		if name == "clear" and _clear_at >= 0.0:
			var k := clampf((_time - _clear_at) / HOLD_ALL, 0.0, 1.0)
			_ui.draw_rect(Rect2(r.position.x, r.end.y - r.size.y * k, r.size.x, r.size.y * k), Color(GILT, 0.4))
		_ui.draw_rect(r, Color(GILT, 0.8), false, maxf(2.0, 0.005 * _tu))
		_draw_words(r, word, small)


## A button's word, as large as fits across it, and the smaller one under it.
func _draw_words(r: Rect2, word: String, small: String) -> void:
	var font := ThemeDB.fallback_font
	var fs := roundi(0.036 * _tu)
	while fs > 8 and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x * 0.88:
		fs -= 1
	var ss := roundi(clampf(fs * 0.62, 7.0, 0.024 * _tu))
	while ss > 6 and small != "" and font.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x > r.size.x * 0.9:
		ss -= 1
	var c := r.get_center()
	var y := c.y + fs * 0.35 - (ss * 0.55 if small != "" else 0.0)
	var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_ui.draw_string(font, Vector2(c.x - w * 0.5, y), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.96, 0.93, 0.86))
	if small != "":
		var sw := font.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
		_ui.draw_string(font, Vector2(c.x - sw * 0.5, y + ss * 1.45), small, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, Color(GILT, 0.95))


# --- The model and its sounds -----------------------------------------------------------------

## The toy's plastics: "duck" teal, yellow and purple; "dice" red and white, a black pip on each side;
## "domino" ivory and black, a red grip, the tip the next domino's colour.
static func make_materials(kind := "duck") -> Dictionary:
	var clear := StandardMaterial3D.new()
	clear.albedo_color = Color(0.7, 0.88, 1.0, 0.16)  # at 0.26 the ducks behind it read grey
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.cull_mode = BaseMaterial3D.CULL_DISABLED
	clear.roughness = 0.06
	clear.metallic_specular = 0.7
	if kind == "dice":
		return {"body": _plastic(Color(0.78, 0.07, 0.09)), "trim": _plastic(Color(0.95, 0.95, 0.92)),
			"grip": _plastic(Color(0.13, 0.13, 0.15)), "tip": _plastic(Color(1.0, 0.8, 0.06)),
			"barrel": _plastic(Color(0.95, 0.95, 0.92)), "clear": clear, "duck": _plastic(Color(0.06, 0.06, 0.07)),
			"beak": _plastic(Color(0.06, 0.06, 0.07))}
	if kind == "domino":
		# Ivory with black: in black, the body was lost against the hall's dark marble (toy_shots.gd, 2026-10-16).
		return {"body": _plastic(Color(0.95, 0.92, 0.82)), "trim": _plastic(Color(0.07, 0.07, 0.08)),
			"grip": _plastic(Color(0.74, 0.08, 0.1)), "tip": _plastic(Color(0.1, 0.7, 0.3)),
			"barrel": _plastic(Color(0.07, 0.07, 0.08)), "clear": clear, "duck": _plastic(Color(0.07, 0.07, 0.08)),
			"beak": _plastic(Color(0.07, 0.07, 0.08))}
	return {"body": _plastic(Color(0.07, 0.58, 0.68)), "trim": _plastic(Color(0.98, 0.76, 0.08)),
		"grip": _plastic(Color(0.4, 0.19, 0.58)), "tip": _plastic(Color(1.0, 0.38, 0.03)),
		"barrel": _plastic(Color(0.93, 0.93, 0.89)), "clear": clear, "duck": _plastic(Color(1.0, 0.8, 0.08)),
		"beak": _plastic(Color(1.0, 0.45, 0.05))}


static func _plastic(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.34
	m.metallic = 0.0
	m.metallic_specular = 0.55
	# A glow of its own colour, faint: held on the terrace at night, the toy was a black shape against the gardens.
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.1
	return m


## The toy, about 37 cm from its grip's back to its tip, the muzzle towards -z, the grip's top at the
## origin: a teal shell with a yellow band and a duck's disc on each side, a purple grip and pump rail,
## a yellow pump ("Slide") under three white barrels round a spindle ("Barrels"), an orange ring at
## the tip, and on top a clear hopper full of ducks ("Hopper"). `fill`: "duck", "dice" (filled once the
## dice are made, _fill_dice) or "domino" (small tiles of the rainbow the dominoes are laid in).
static func build_gun(m: Dictionary, fill := "duck") -> Node3D:
	var root := Node3D.new()
	root.name = "DuckGun"
	_p(root, _box(Vector3(0.066, 0.078, 0.2)), m.body, Vector3(0, 0.028, -0.07))
	_p(root, _cyl(0.039, 0.066, 20), m.body, Vector3(0, 0.028, 0.03), Vector3(0, 0, 90))  # the rounded back
	_p(root, _box(Vector3(0.07, 0.014, 0.205)), m.trim, Vector3(0, 0.0, -0.07))
	for sx: float in [-1.0, 1.0]:
		_p(root, _cyl(0.017, 0.004, 24), m.trim, Vector3(sx * 0.034, 0.042, -0.035), Vector3(0, 0, 90))
		_p(root, _cyl(0.009, 0.005, 16), m.duck, Vector3(sx * 0.035, 0.044, -0.03), Vector3(0, 0, 90))
	_p(root, _box(Vector3(0.018, 0.01, 0.15)), m.grip, Vector3(0, 0.072, -0.08))
	_p(root, _box(Vector3(0.032, 0.022, 0.012)), m.grip, Vector3(0, 0.078, 0.022))
	_p(root, _box(Vector3(0.042, 0.11, 0.05)), m.grip, Vector3(0, -0.055, 0.03), Vector3(-16, 0, 0))
	_p(root, _box(Vector3(0.046, 0.012, 0.054)), m.trim, Vector3(0, -0.108, 0.045), Vector3(-16, 0, 0))
	_p(root, _torus(0.014, 0.02), m.grip, Vector3(0, -0.022, -0.035), Vector3(0, 0, 90))
	_p(root, _box(Vector3(0.008, 0.024, 0.008)), m.trim, Vector3(0, -0.017, -0.03), Vector3(-12, 0, 0))
	var slide := Node3D.new()
	slide.name = "Slide"
	root.add_child(slide)
	_p(slide, _box(Vector3(0.052, 0.034, 0.08)), m.trim, Vector3(0, -0.008, -0.205))
	for k in 3:
		_p(slide, _box(Vector3(0.056, 0.006, 0.008)), m.grip, Vector3(0, -0.008, -0.18 - 0.024 * k))
	var barrels := Node3D.new()
	barrels.name = "Barrels"
	barrels.position = Vector3(0, 0.03, -0.17)
	root.add_child(barrels)
	for k in 3:
		var a := TAU * k / 3.0
		_p(barrels, _cyl(0.0095, 0.15, 14), m.barrel, Vector3(cos(a) * 0.0175, sin(a) * 0.0175, -0.075), Vector3(90, 0, 0))
	_p(barrels, _cyl(0.006, 0.154, 8), m.grip, Vector3(0, 0, -0.075), Vector3(90, 0, 0))
	_p(barrels, _cyl(0.031, 0.008, 20), m.body, Vector3(0, 0, -0.035), Vector3(90, 0, 0))
	_p(barrels, _cyl(0.031, 0.008, 20), m.body, Vector3(0, 0, -0.11), Vector3(90, 0, 0))
	_p(root, _torus(0.029, 0.038), m.tip, Vector3(0, 0.03, -0.312), Vector3(90, 0, 0))
	_p(root, _torus(0.03, 0.036), m.body, Vector3(0, 0.03, -0.172), Vector3(90, 0, 0))
	var hopper := Node3D.new()
	hopper.name = "Hopper"
	hopper.position = Vector3(0, HOPPER_Y, -0.06)
	root.add_child(hopper)
	_p(hopper, _cyl(0.046, 0.072, 28), m.clear, Vector3(0, 0.038, 0))
	_p(hopper, _cyl(0.049, 0.008, 28), m.trim, Vector3(0, 0.0, 0))
	_p(hopper, _cyl(0.049, 0.006, 28), m.trim, Vector3(0, 0.077, 0))
	_p(hopper, _cyl(0.012, 0.012, 12), m.grip, Vector3(0, 0.086, 0))
	# The drum inside, that turns with the barrels: a floor with three purple spokes, and the ducks on it.
	var drum := Node3D.new()
	drum.name = "Drum"
	hopper.add_child(drum)
	for k in 3:
		_p(drum, _box(Vector3(0.084, 0.002, 0.007)), m.grip, Vector3(0, 0.005, 0), Vector3(0, 60.0 * k, 0))
	if fill == "domino":
		# Six standing round the drum, their faces to its middle, and one lying across them.
		for k in 7:
			var a := TAU * k / 6.0
			var tile := Node3D.new()
			tile.position = Vector3(cos(a) * 0.027, 0.025, sin(a) * 0.027) if k < 6 else Vector3(0.0, 0.05, 0.0)
			tile.rotation = Vector3(0.0, -a + PI * 0.5, 0.0) if k < 6 else Vector3(PI * 0.5, 0.7, 0.0)
			tile.set_meta("rest", Transform3D(Basis.from_euler(tile.rotation), tile.position))
			drum.add_child(tile)
			_p(tile, _box(Vector3(0.019, 0.038, 0.0065)), _plastic(Color.from_hsv(float(k) / 7.0, 0.82, 0.95)), Vector3.ZERO)
		return root
	if fill != "duck":
		return root
	for k in 7:
		var a := TAU * k / 6.0 + 0.4
		var r := 0.025 if k < 6 else 0.0
		var duck := Node3D.new()
		duck.position = Vector3(cos(a) * r, 0.016 + 0.026 * float(k % 2) + (0.04 if k == 6 else 0.0), sin(a) * r)
		duck.rotation = Vector3(0.0, a * 1.7 + float(k), 0.25 * float(k % 3 - 1))
		duck.set_meta("rest", Transform3D(Basis.from_euler(duck.rotation), duck.position))
		drum.add_child(duck)
		_p(duck, _ball(0.0115), m.duck, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.8, 1.2))
		_p(duck, _ball(0.0075), m.duck, Vector3(0, 0.011, -0.008))
		_p(duck, _box(Vector3(0.006, 0.0025, 0.006)), m.beak, Vector3(0, 0.0105, -0.0155))
	return root


static func _p(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _cyl(r: float, h: float, seg: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func _ball(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


static func _torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 28
	t.ring_segments = 8
	return t


## A toy's sounds, synthesized: the pop of a duck going out, the clack of plastic clipped on, a
## ratchet as the pump goes back, a tick as the mode changes.
func _make_sounds() -> void:
	var noise := RandomNumberGenerator.new()
	noise.seed = 7
	_sounds.pop = _synth(0.1, func(t: float) -> float:
		return noise.randf_range(-1.0, 1.0) * exp(-t / 0.01) * 0.55 \
			+ sin(TAU * (560.0 - 2200.0 * t) * t) * exp(-t / 0.028) * 0.8 + sin(TAU * 2600.0 * t) * exp(-t / 0.004) * 0.35)
	_sounds.clack = _synth(0.07, func(t: float) -> float:
		return noise.randf_range(-1.0, 1.0) * exp(-t / 0.005) * 0.8 + sin(TAU * 1750.0 * t) * exp(-t / 0.012) * 0.55)
	_sounds.ratchet = _synth(0.12, func(t: float) -> float:
		var s := 0.0
		for k in 4:
			var u := t - 0.027 * k
			if u >= 0.0:
				s += (noise.randf_range(-1.0, 1.0) * exp(-u / 0.003) * 0.6 + sin(TAU * 2300.0 * u) * exp(-u / 0.006) * 0.4) * (1.0 - 0.15 * k)
		return s)
	_sounds.tick = _synth(0.05, func(t: float) -> float:
		return sin(TAU * 1320.0 * t) * exp(-t / 0.01) * 0.6 + sin(TAU * 2640.0 * t) * exp(-t / 0.005) * 0.25)
	_pop = AudioStreamPlayer.new()
	_pop.name = "Pop"
	_pop.stream = _sounds.pop
	_pop.volume_db = -11.0
	_pop.max_polyphony = 8
	add_child(_pop)
	_mech = AudioStreamPlayer.new()
	_mech.name = "Mech"
	_mech.volume_db = -7.0
	_mech.max_polyphony = 4
	add_child(_mech)


static func _synth(seconds: float, wave: Callable) -> AudioStreamWAV:
	var rate := 22050
	var n := int(seconds * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var v := clampf(float(wave.call(t)) * 0.6, -1.0, 1.0)
		data.encode_s16(i * 2, roundi(v * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
