extends Node3D
## The lift: a bronze cage on steel rails that climbs from the hall to the two galleries, so a walker
## can reach the upper shelves and walk round them (scripts/walk_physics.gd walks the galleries).
## It stands in bay LIFT_BAY, between the colonnade and the shelves, its opening towards the hall; each
## gallery's walkway is cut round its shaft (observatory.gd, _build_galleries) and a brass collar
## covers the cut. A gate closes each landing while the cage is elsewhere, and the cage's own gate
## while it moves.
##   - In the cage: Space (the touch ▲) goes up a floor, Ctrl or C (the touch ▼) down a floor, E up,
##     or down from the top.
##   - At a landing: E calls the cage; so does walking against the closed gate.
##   - On a touch screen, the touch controls (scripts/touch_controls.gd) also show the lift's own
##     buttons (touch_panel, touch_press): in the cage one per landing, at a landing one to call it.
## When Upperside is there (scripts/upperside.gd), the lift goes on to the roof: through the ceiling,
## cut round the shaft and lined with a bronze throat, where the view dips to black, and up into a
## small kiosk of bronze and glass on the lead. Its door faces the drum; the walker steps out onto
## the roof, between the drum and a balustrade at the eave (artpass/roof/).
## walk_physics.gd asks this node where the cage's floor is (support), whether a point is in the
## shaft (in_shaft), and to keep a walker on its side of the shaft's wall (constrain); on the roof,
## where the lead is (roof_floor) and how far a walker may go (roof_limits).

const LIFT_BAY := 3
const AXIS_R := 16.1        # the shaft's axis, from the hall's centre
const WALL_R := 1.0         # the shaft's wall, between the cage's bars and the landing gates
const CAGE_R := 0.93        # the cage's bars
const OPEN_HALF := deg_to_rad(50.0)  # half the opening, towards the hall
const CAGE_H := 2.4
const SPEED := 2.4          # m/s at most
const GATE_TIME := 0.45     # s to close or open
const NEAR := 2.8           # a walker this close to the axis gets the lift's hint
const CALL_PUSH := 0.25     # s against a closed gate calls the cage
const UPPERSIDE_PATH := "res://scripts/upperside.gd"
const ROOF_SHADER_PATH := "res://assets/upperside.gdshader"
const GLASS_SHADER_PATH := "res://assets/kiosk_glass.gdshader"
const KIOSK_R := 1.14       # the kiosk's glass, round the shaft on the roof
const THROAT_R := 1.2       # the bronze throat through the ceiling, outside; the hole in the lead
const ROOF_TOL := 0.25      # m: the lead slopes; a walker this near the roof landing's height is at it
const DOME_H := 0.15        # the cage's dome, over its roof
const CAGE_LAYER := 1 << 19  # render layer: the cage's meshes, which alone its ceiling lamp lights
const SHEAVE_R := 0.54      # the sheave's groove: it turns a cable's length per radian
const SOUNDS_PATH := "res://scripts/lift_sounds.gd"
const SFX_PATH := "res://scripts/sfx_takes.gd"
const WEB_LOOP_PATH := "res://scripts/web_loop.gd"
const GATE_BARS := 9        # the cage's folding gate
const LANDING_BARS := 11    # a landing's
const GATE_ROWS := 3        # lozenges of crossed straps, one over another, between two bars
const FOLD := 0.035         # m between two bars of a folded gate
const HUM_DB := -13.0
const TEXT := {
	"en": {"levels": ["Hall", "Gallery 1", "Gallery 2", "Roof"], "up": "Space ▲ %s", "down": "Ctrl ▼ %s", "use": "E: %s",
		"call": "Lift  ·  E or walk to the gate: call it", "call_touch": "Lift  ·  walk to the gate to call it",
		"coming": "Lift coming…", "going": "Lift  ·  %s…", "title": "Lift  ·  %s", "call_button": "Call"},
	"fr": {"levels": ["Salle", "Galerie 1", "Galerie 2", "Toit"], "up": "Espace ▲ %s", "down": "Ctrl ▼ %s", "use": "E : %s",
		"call": "Ascenseur  ·  E ou marcher vers la grille : l'appeler", "call_touch": "Ascenseur  ·  marche vers la grille pour l'appeler",
		"coming": "L'ascenseur arrive…", "going": "Ascenseur  ·  %s…", "title": "Ascenseur  ·  %s", "call_button": "Appeler"},
	"es": {"levels": ["Sala", "Galería 1", "Galería 2", "Azotea"], "up": "Espacio ▲ %s", "down": "Ctrl ▼ %s", "use": "E: %s",
		"call": "Ascensor  ·  E o camina hacia la reja: llamarlo", "call_touch": "Ascensor  ·  camina hacia la reja para llamarlo",
		"coming": "El ascensor viene…", "going": "Ascensor  ·  %s…", "title": "Ascensor  ·  %s", "call_button": "Llamar"},
}

enum State { IDLE, CLOSING, MOVING, OPENING }

## Floor heights: the hall, then the galleries (observatory.gd's gallery_levels).
var levels: Array[float] = [0.0]
var state := State.IDLE
var at := 0                 # the landing the cage is at, or is heading for
var y := 0.0                # the cage's floor
var gate := 1.0             # 1 open, 0 closed: the cage's and its landing's
var lang := "en"
var touch := false
## Whether the last landing is the roof's.
var roof := false
## Counts for tests; fade is the darkest the view has dipped, 1 black.
var stats := {"calls": 0, "rides": 0, "arrivals": 0, "pushes": 0, "touch": 0, "fade": 0.0,
	"sounds": {"hum": 0, "bell": 0, "gate": 0}, "sound_ms": 0.0}

var _obs: Node3D
var _camera: Camera3D
var _walk: Node
var _centre := Vector2.ZERO
var _in := Vector2.ZERO     # from the axis towards the hall
var _pending := -1
var _from := 0.0
var _t := 0.0
var _dur := 1.0
var _push := 0.0
var _cage: Node3D
var _cage_gate: Node3D
var _landing_gates: Array[Node3D] = []
var _cables: Array[MeshInstance3D] = []
var _sheave: Node3D
## The folding gates: the cage's first, then each landing's; each {node, r, n, y0, h, bars, straps,
## drawn}, drawn the openness it was last drawn at.
var _gates: Array[Dictionary] = []
var _hum: AudioStreamPlayer3D
var _hum_loop: Node           # web_loop.gd: the hum kept going on the web
var _bell: AudioStreamPlayer3D
var _rattle: AudioStreamPlayer3D
var _last_state := State.IDLE
var _last_y := 0.0
var _y_before := 0.0        # the cage's floor before its last move
var _needles: Array[Node3D] = []
var _top := 16.0
var _ui: CanvasLayer
var _label: Label
var _fade: ColorRect
var _kiosk: Node3D          # on the roof; hidden while the camera is well below the ceiling
var _web := false
var _up: Script             # scripts/upperside.gd, for the roof's measures
var _prof := {}


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	# After the walking body (100), before the views and flights (870+).
	process_priority = 120
	var a := TAU * (LIFT_BAY + 0.5) / float(_obs.get("bay_count"))
	_centre = Vector2(cos(a), sin(a)) * AXIS_R
	_in = -_centre.normalized()
	for g in (_obs.get("gallery_levels") as PackedFloat32Array):
		levels.append(g)
	if goes_to_roof():
		_up = load(UPPERSIDE_PATH)
		_prof = _up.call("profile", _obs)
		roof = true
		# The roof's landing, level with the lead at the kiosk's door, which faces the drum.
		levels.append(roof_height(AXIS_R - WALL_R) + 0.005)
	# Over the top landing, room for the cables; on the roof, the kiosk's cornice.
	_top = levels[-1] + CAGE_H + (0.35 if roof else 1.1)
	_walk = _obs.get_node_or_null("WalkBody")
	touch = _obs.get_node_or_null("TouchControls") != null
	_web = OS.has_feature("web")
	_build()
	_build_ui()
	var lib := _obs.get_node_or_null("Generated/CourseShelves")
	if lib != null:
		set_lang(str(lib.get("lang")))
		if lib.has_signal("lang_changed"):
			lib.connect("lang_changed", set_lang)
	_sync()


func set_lang(code: String) -> void:
	lang = code if TEXT.has(code) else "en"


## The shaft's axis on the floor plane, and the direction of its opening.
func centre() -> Vector2:
	return _centre


## Whether the lift goes on to the roof: when Upperside, which the roof belongs to, is there.
static func goes_to_roof() -> bool:
	return ResourceLoader.exists(UPPERSIDE_PATH)


## The lead's height at r metres from the hall's centre (scripts/upperside.gd builds the roof).
func roof_height(r: float) -> float:
	return float(_up.call("roof_height", _prof, r))


## The lead under p, between the drum and the eave and outside the shaft; -INF elsewhere, or
## without the roof.
func roof_floor(p: Vector2) -> float:
	if not roof:
		return -INF
	var r := p.length()
	if r < float(_prof.drum_out) or r > float(_prof.eave) or in_shaft(p):
		return -INF
	return roof_height(r)


## Whether a body whose floor is at floor_y is up on the roof, the cage's roof landing included.
func on_roof(floor_y: float) -> bool:
	return roof and floor_y > float(_prof.slab_top) - 0.5


## How far from the hall's centre a walker's middle may go on the roof: x the drum's face, y the
## balustrade.
func roof_limits() -> Vector2:
	return Vector2(float(_prof.drum_out), float(_prof.rail_r)) if roof else Vector2.ZERO


## The hole in the lead round the shaft, for scripts/upperside.gd: x, z and radius; 0 without the
## roof.
func roof_hole() -> Vector3:
	return Vector3(_centre.x, _centre.y, THROAT_R) if roof else Vector3.ZERO


## The cage's floor under p, if p is on it and it is no higher than top; -INF otherwise. A body
## that stood on the floor where it was before its last move rides with it, however far it moved:
## in one slow frame (a phone, or the first climb building Upperside) it rises more than a step.
func support(p: Vector2, top: float) -> float:
	if (p - _centre).length() < WALL_R and (y <= top or _y_before <= top):
		return y
	return -INF


## Whether p is inside the shaft, where no walkway is.
func in_shaft(p: Vector2) -> bool:
	return (p - _centre).length() < WALL_R


## Keeps a walker of the given radius, going from prev to p on a floor at floor_y, on its side of the
## shaft's wall, except through the opening while the cage waits open at that floor.
func constrain(prev: Vector2, p: Vector2, floor_y: float, radius: float) -> Vector2:
	var d := p - _centre
	var dist := d.length()
	if dist > WALL_R + radius + 0.2:
		return p
	var inside := (prev - _centre).length() < WALL_R
	var open := state == State.IDLE and gate >= 1.0 and _at_level(floor_y) == at
	if open and dist > 1e-4 and absf(d.normalized().angle_to(_in)) < OPEN_HALF - radius / WALL_R:
		return p
	if inside:
		var r := WALL_R - radius - 0.05
		if dist > r:
			return _centre + d / dist * r
		return p
	var r_out := WALL_R + radius
	if dist < r_out:
		if dist < 1e-4:
			d = _in
			dist = 1.0
		if absf(d.normalized().angle_to(_in)) < OPEN_HALF:
			_push += get_process_delta_time()
		return _centre + d / dist * r_out
	return p


## Sends the cage to a landing: at once if it waits, after its ride otherwise.
func go_to(level: int) -> void:
	level = clampi(level, 0, levels.size() - 1)
	if state == State.IDLE:
		if level == at:
			return
		at = level
		state = State.CLOSING
		stats.rides += 1
	elif level != at:
		_pending = level


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _walking():
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	var p := _feet_flat()
	var floor_y := _floor()
	if _riding(p, floor_y):
		if state != State.IDLE:
			if code in [KEY_SPACE, KEY_C, KEY_CTRL, KEY_E]:
				get_viewport().set_input_as_handled()
			return
		var up := at + 1 if at + 1 < levels.size() else -1
		var down := at - 1 if at > 0 else -1
		if code == KEY_SPACE and up >= 0:
			go_to(up)
		elif (code == KEY_C or code == KEY_CTRL) and down >= 0:
			go_to(down)
		elif code == KEY_E:
			go_to(up if up >= 0 else 0)
		else:
			return
		get_viewport().set_input_as_handled()
	elif code == KEY_E and (p - _centre).length() < NEAR and _at_level(floor_y) >= 0:
		_call(_at_level(floor_y))
		get_viewport().set_input_as_handled()


func _call(level: int) -> void:
	# Already there, or already on its way: `at` is where the cage waits or heads.
	if at == level or _pending == level:
		return
	stats.calls += 1
	go_to(level)


func _process(delta: float) -> void:
	_y_before = y
	match state:
		State.CLOSING:
			gate = maxf(0.0, gate - delta / GATE_TIME)
			if gate <= 0.0:
				state = State.MOVING
				_from = y
				_t = 0.0
				_dur = maxf(1.2, absf(levels[at] - y) / SPEED + 0.8)
		State.MOVING:
			_t = minf(1.0, _t + delta / _dur)
			y = lerpf(_from, levels[at], smoothstep(0.0, 1.0, _t))
			if _t >= 1.0:
				y = levels[at]
				state = State.OPENING
				stats.arrivals += 1
		State.OPENING:
			gate = minf(1.0, gate + delta / GATE_TIME)
			if gate >= 1.0:
				state = State.IDLE
				if _pending >= 0:
					var next := _pending
					_pending = -1
					go_to(next)
	# Walking against a closed gate calls the cage to that landing.
	if _push > 0.0:
		stats.pushes += 1
		var here := _at_level(_floor())
		if _push >= CALL_PUSH and here >= 0 and not (state == State.IDLE and at == here):
			_call(here)
			_push = 0.0
		_push = maxf(0.0, _push - delta * 0.5)
	_sync()
	_hint()
	_dip()
	_sound(delta)


## Riding through the ceiling, the view dips to black and back: the eye goes up a bronze throat
## and comes out under the kiosk's glass, the domes of Upperside all round. The first climb
## builds Upperside (scripts/extra_views.gd) while the view is black.
func _dip() -> void:
	if _fade == null:
		return
	var a := 0.0
	if roof and state == State.MOVING and _walking() and not _flying() and _riding(_feet_flat(), _floor()):
		var mid := (float(_obs.get("_ceiling_y")) + levels[-1]) * 0.5
		a = 1.0 - smoothstep(0.35, 1.1, absf(_camera.position.y - mid))
	_fade.color.a = a
	_fade.visible = a > 0.0
	stats.fade = maxf(float(stats.fade), snappedf(a, 0.01))


## The cage, its gates and the landing gates where the state puts them.
func _sync() -> void:
	if _cage == null:
		return
	if _kiosk != null and _camera != null:
		_kiosk.visible = _camera.global_position.y > float(_obs.get("_ceiling_y")) - 1.0
	_cage.position.y = y
	# The gates fold to the right of the opening: the cage's, and the landing's the cage stands at
	# (not `at`, which is already the next landing while the gates close).
	for i in _gates.size():
		var here := i == 0 or (state != State.MOVING and absf(levels[i - 1] - y) < 0.01)
		var open := gate if here else 0.0
		var drawn := float(_gates[i].drawn)
		if open != drawn and (absf(open - drawn) > 0.0005 or open == 0.0 or open == 1.0):
			_draw_gate(_gates[i], open)
	for c in _cables:
		var low := y + CAGE_H + DOME_H + 0.05
		var h := _top - low
		c.scale.y = maxf(h, 0.01)
		c.position.y = low + h * 0.5
	# The sheave turns with the cable; every dial's needle points at the cage.
	_sheave.rotation.z = -y / SHEAVE_R
	var phi := _dial_angle(y)
	for n in _needles:
		n.rotation.z = phi
	if _web:
		JavaScriptBridge.eval("window.__obsLift = " + JSON.stringify({"state": state, "at": at, "y": snappedf(y, 0.001),
			"gate": snappedf(gate, 0.01), "stats": stats}), true)


func _hint() -> void:
	if _label == null:
		return
	var t: Dictionary = TEXT[lang]
	var names: Array = t.levels
	var text := ""
	if _walking() and not _flying():
		var p := _feet_flat()
		var floor_y := _floor()
		if _riding(p, floor_y):
			if state != State.IDLE:
				text = str(t.going) % names[at]
			else:
				var parts: Array[String] = [str(t.title) % names[at]]
				if at + 1 < levels.size():
					parts.append((str(t.up) % names[at + 1]).replace("Space", "Space") if not touch else "▲ " + str(names[at + 1]))
				if at > 0:
					parts.append(str(t.down) % names[at - 1] if not touch else "▼ " + str(names[at - 1]))
				text = "  ·  ".join(parts)
		elif (p - _centre).length() < NEAR and _at_level(floor_y) >= 0:
			if state == State.IDLE and at == _at_level(floor_y):
				text = str(t.title) % names[at]
			elif state != State.IDLE and at == _at_level(floor_y):
				text = str(t.coming)
			else:
				text = str(t.call_touch if touch else t.call)
	# On a phone the hint grows with the screen; over the lift's touch buttons, the touch controls
	# show it themselves.
	var tc := _obs.get_node_or_null("TouchControls") if touch else null
	if tc != null and tc.has_method("ui_scale"):
		var size := roundi(26.0 * float(tc.call("ui_scale")))
		if _label.get_theme_font_size("font_size") != size:
			_label.add_theme_font_size_override("font_size", size)
		if bool(tc.call("shows_lift")):
			text = ""
	_label.text = text
	_label.get_parent().visible = text != ""


## For the touch controls (scripts/touch_controls.gd), which draw the lift's own buttons under its
## hint: in the cage one per landing, lit for the landing it heads for and the one it goes to next;
## at a landing the cage is not at, one to call it, lit while it comes. Each button is {id, label,
## lit, here}: id a landing, or -1 for the call; here, the landing the cage waits at.
func touch_panel() -> Dictionary:
	var out := {"title": "", "buttons": []}
	if not _walking() or _flying():
		return out
	var t: Dictionary = TEXT[lang]
	var names: Array = t.levels
	var p := _feet_flat()
	var floor_y := _floor()
	var buttons: Array[Dictionary] = []
	if _riding(p, floor_y):
		out.title = str(t.title if state == State.IDLE else t.going) % names[at]
		for i in levels.size():
			buttons.append({"id": i, "label": str(names[i]), "lit": (state != State.IDLE and i == at) or i == _pending,
				"here": state == State.IDLE and i == at})
	else:
		var here := _at_level(floor_y)
		if (p - _centre).length() < NEAR and here >= 0 and not (state == State.IDLE and at == here):
			var coming := at == here or _pending == here
			out.title = str(t.coming) if coming else str(t.title) % names[here]
			buttons.append({"id": -1, "label": str(t.call_button), "lit": coming, "here": false})
	out.buttons = buttons
	return out


## A touch on one of those buttons: in the cage, a landing to go to (after the ride, if it rides);
## at a landing, -1 calls the cage.
func touch_press(id: int) -> void:
	if not _walking() or _flying():
		return
	var p := _feet_flat()
	var floor_y := _floor()
	if id >= 0 and _riding(p, floor_y):
		stats.touch += 1
		go_to(id)
	elif id < 0 and (p - _centre).length() < NEAR and _at_level(floor_y) >= 0:
		stats.touch += 1
		_call(_at_level(floor_y))


## Whether E is the lift's key where the walker stands (_unhandled_input): in the cage, or near it
## at a landing. Elsewhere the walking body leans right with E (scripts/walk_physics.gd).
func uses_e() -> bool:
	if not _walking() or _flying():
		return false
	var p := _feet_flat()
	var floor_y := _floor()
	return _riding(p, floor_y) or ((p - _centre).length() < NEAR and _at_level(floor_y) >= 0)


func _walking() -> bool:
	return _walk != null and bool(_walk.call("is_walking"))


func _flying() -> bool:
	return _camera != null and bool(_camera.get("_free_fly"))


func _floor() -> float:
	return float(_walk.call("floor_height")) if _walk != null else 0.0


func _feet_flat() -> Vector2:
	var p := _camera.position if _camera != null else Vector3.ZERO
	return Vector2(p.x, p.z)


func _riding(p: Vector2, floor_y: float) -> bool:
	return (p - _centre).length() < WALL_R and absf(floor_y - y) < 0.3


## The landing whose floor is floor_y, or -1. The roof's slopes: near the kiosk, the lead is within
## ROOF_TOL of its landing.
func _at_level(floor_y: float) -> int:
	for i in levels.size():
		if absf(levels[i] - floor_y) < (ROOF_TOL if _is_roof(i) else 0.05):
			return i
	return -1


func _is_roof(level: int) -> bool:
	return roof and level == levels.size() - 1


func _build() -> void:
	var m: Dictionary = _obs.get("_m")
	var steel: Material = m.silver
	var iron: Material = m.bronze  # dark bronze: the columns, the cap, the needles
	var brass: Material = m.get("orbit_brass", m.bronze)
	var gilt: Material = m.gold
	var halo := (m.green_glow as Material).duplicate() as Material
	if halo is StandardMaterial3D:
		(halo as StandardMaterial3D).emission_energy_multiplier = 1.1  # a glow, not a glare
	var root := Node3D.new()
	root.name = "Shaft"
	add_child(root)
	var basis := _frame_basis()
	var origin := Vector3(_centre.x, 0.0, _centre.y)
	root.transform = Transform3D(basis, origin)
	var arc0 := OPEN_HALF + PI * 0.5
	var arc1 := TAU - OPEN_HALF + PI * 0.5
	var sector := func(r0: float, r1: float, h: float, a0: float, a1: float, seg: int) -> Mesh:
		return _obs.call("ring_sector", r0, r1, h, a0, a1, seg)
	var box := func(size: Vector3) -> Mesh:
		return _obs.call("_box", size)
	# The frame: four round columns of dark bronze, two flanking the opening, on gilt bases, with a
	# gilt collar at every ring; brass rings round the shaft over every landing and at the top.
	var ring_levels: Array[float] = []
	for i in levels.size():
		if not _is_roof(i):  # the kiosk's frieze is there
			ring_levels.append(levels[i] + 2.45)
	ring_levels.append(_top - 0.15)
	var column := CylinderMesh.new()
	column.top_radius = 0.05
	column.bottom_radius = 0.05
	column.height = _top
	column.radial_segments = 12
	column.rings = 1
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.065
	base_mesh.bottom_radius = 0.08
	base_mesh.height = 0.2
	base_mesh.radial_segments = 12
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = 0.066
	collar_mesh.bottom_radius = 0.066
	collar_mesh.height = 0.05
	collar_mesh.radial_segments = 12
	var columns := []
	var column_gilt := []
	for ang: float in [OPEN_HALF + 0.12, -(OPEN_HALF + 0.12), PI * 0.78, -PI * 0.78]:
		var at_ := Vector3(sin(ang), 0.0, cos(ang)) * (WALL_R + 0.06)
		columns.append([column, Transform3D(Basis(), at_ + Vector3(0.0, _top * 0.5, 0.0))])
		column_gilt.append([base_mesh, Transform3D(Basis(), at_ + Vector3(0.0, 0.1, 0.0))])
		for ry in ring_levels:
			column_gilt.append([collar_mesh, Transform3D(Basis(), at_ + Vector3(0.0, ry + 0.035, 0.0))])
	_obs.call("_add", root, "Columns", _obs.call("_merge", columns), iron, Transform3D())
	_obs.call("_add", root, "ColumnGilt", _obs.call("_merge", column_gilt), gilt, Transform3D(), false)
	var rings := []
	for ry in ring_levels:
		rings.append([sector.call(WALL_R + 0.02, WALL_R + 0.1, 0.07, arc0, arc1, 48), Transform3D(Basis(), Vector3(0.0, ry, 0.0))])
	# Over the opening, outside the gates' path, a lintel from column to column for the dial.
	for i in levels.size():
		if not _is_roof(i):
			rings.append([sector.call(WALL_R + 0.08, WALL_R + 0.14, 0.07, PI * 0.5 - OPEN_HALF - 0.08, PI * 0.5 + OPEN_HALF + 0.08, 16), Transform3D(Basis(), Vector3(0.0, levels[i] + 2.45, 0.0))])
	_obs.call("_add", root, "Rings", _obs.call("_merge", rings), brass, Transform3D(), false)
	# The machine on top: a cap, and a brass sheave with six spokes, which turns as the cage moves.
	_obs.call("_add", root, "Cap", sector.call(0.0, WALL_R + 0.14, 0.14, 0.0, TAU, 48), iron, Transform3D(Basis(), Vector3(0.0, _top, 0.0)))
	_sheave = Node3D.new()
	_sheave.name = "Sheave"
	_sheave.position = Vector3(0.0, _top + 0.72, 0.0)
	root.add_child(_sheave)
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.5
	wheel.outer_radius = 0.58
	wheel.rings = 48
	wheel.ring_segments = 8
	var sheave := [[wheel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)]]
	for k in 6:
		sheave.append([box.call(Vector3(0.5, 0.035, 0.035)), Transform3D(Basis(Vector3.BACK, TAU * k / 6.0), Vector3.ZERO) * Transform3D(Basis(), Vector3(0.27, 0.0, 0.0))])
	_obs.call("_add", _sheave, "Wheel", _obs.call("_merge", sheave), brass, Transform3D(), false)
	var hub := CylinderMesh.new()
	hub.top_radius = 0.09
	hub.bottom_radius = 0.09
	hub.height = 0.3
	_obs.call("_add", _sheave, "Hub", hub, iron, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), false)

	# The cage: a walnut floor with a brass inlay; a walnut wainscot with brass mouldings and panel
	# frames; brass bars above it with a middle ring; a frieze of gilt rosettes; a brass dome with a
	# gilt cresting and finial, the lift's green lamp on top. Inside, a green ring of light under the
	# roof, a warm ceiling lamp, and a control column with a lever.
	_cage = Node3D.new()
	_cage.name = "Cage"
	root.add_child(_cage)
	var wood := [
		[sector.call(0.0, CAGE_R + 0.03, 0.08, 0.0, TAU, 48), Transform3D(Basis(), Vector3(0.0, -0.08, 0.0))],
		[sector.call(CAGE_R - 0.02, CAGE_R + 0.02, 0.9, arc0, arc1, 48), Transform3D(Basis(), Vector3(0.0, 0.04, 0.0))],
	]
	_obs.call("_add", _cage, "Wood", _obs.call("_merge", wood), m.walnut, Transform3D())
	var trim := [
		[sector.call(CAGE_R - 0.14, CAGE_R - 0.11, 0.004, 0.0, TAU, 48), Transform3D()],
		[sector.call(CAGE_R - 0.025, CAGE_R + 0.03, 0.05, arc0, arc1, 48), Transform3D()],
		[sector.call(CAGE_R - 0.05, CAGE_R + 0.035, 0.04, arc0, arc1, 48), Transform3D(Basis(), Vector3(0.0, 0.94, 0.0))],
		[sector.call(CAGE_R - 0.015, CAGE_R + 0.015, 0.025, arc0, arc1, 48), Transform3D(Basis(), Vector3(0.0, 1.56, 0.0))],
		[sector.call(CAGE_R - 0.02, CAGE_R + 0.03, 0.28, 0.0, TAU, 48), Transform3D(Basis(), Vector3(0.0, CAGE_H - 0.28, 0.0))],
		[sector.call(0.0, CAGE_R + 0.05, 0.06, 0.0, TAU, 48), Transform3D(Basis(), Vector3(0.0, CAGE_H, 0.0))],
		[box.call(Vector3(0.12, 1.0, 0.1)), Transform3D(Basis(), Vector3(0.0, 0.5, -CAGE_R + 0.12))],
		[box.call(Vector3(0.02, 0.2, 0.02)), Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(0.0, 1.08, -CAGE_R + 0.15))],
	]
	# Seven panels on the wainscot, each a brass frame: arcs top and bottom, uprights at its ends.
	var panels := 7
	for k in panels:
		var a0 := arc0 + (arc1 - arc0) * (k + 0.1) / panels
		var a1 := arc0 + (arc1 - arc0) * (k + 0.9) / panels
		for fy: float in [0.2, 0.74]:
			trim.append([sector.call(CAGE_R + 0.02, CAGE_R + 0.034, 0.018, a0, a1, 6), Transform3D(Basis(), Vector3(0.0, fy, 0.0))])
		for t: float in [a0, a1]:
			trim.append([box.call(Vector3(0.018, 0.54, 0.014)), Transform3D(Basis(Vector3.UP, -(t + PI * 0.5)), Vector3(cos(t), 0.0, sin(t)) * (CAGE_R + 0.027) + Vector3(0.0, 0.47, 0.0))])
	_obs.call("_add", _cage, "Brass", _obs.call("_merge", trim), brass, Transform3D())
	# Low, so that at the roof's landing the lamp on top clears the shaft's cap by 2 cm; its own
	# instance, since a merged mesh would keep the sphere's normals.
	var dome := SphereMesh.new()
	dome.radius = 1.0
	dome.height = 1.0
	dome.is_hemisphere = true
	dome.radial_segments = 32
	dome.rings = 8
	_obs.call("_add", _cage, "Dome", dome, brass, Transform3D(Basis.from_scale(Vector3(CAGE_R + 0.05, DOME_H, CAGE_R + 0.05)), Vector3(0.0, CAGE_H + 0.06, 0.0)), false)
	var knob := SphereMesh.new()
	knob.radius = 0.03
	knob.height = 0.06
	knob.radial_segments = 12
	knob.rings = 6
	var gilded := [
		[sector.call(CAGE_R + 0.02, CAGE_R + 0.08, 0.04, 0.0, TAU, 48), Transform3D(Basis(), Vector3(0.0, CAGE_H + 0.03, 0.0))],
		[knob, Transform3D(Basis(), Vector3(0.0, CAGE_H + 0.06 + DOME_H + 0.02, 0.0))],
		[knob, Transform3D(Basis(), Vector3(0.0, 1.17, -CAGE_R + 0.2))],
	]
	_obs.call("_add", _cage, "Gilt", _obs.call("_merge", gilded), gilt, Transform3D(), false)
	var bar := CylinderMesh.new()
	bar.top_radius = 0.014
	bar.bottom_radius = 0.014
	bar.height = 1.0
	bar.radial_segments = 6
	var bars: Array[Transform3D] = []
	var n := 22
	var bar_h := CAGE_H - 0.28 - 0.98
	for k in n:
		var ang := TAU * (k + 0.5) / n
		if absf(wrapf(ang, -PI, PI)) < OPEN_HALF:
			continue
		bars.append(Transform3D(Basis.from_scale(Vector3(1.0, bar_h, 1.0)), Vector3(sin(ang), 0.0, cos(ang)) * CAGE_R + Vector3(0.0, 0.98 + bar_h * 0.5, 0.0)))
	_obs.call("_multi", _cage, "Bars", bar, brass, bars, [], false)
	# Rosettes round the frieze, facing out; fleurons standing round the dome's rim.
	var rosette := TorusMesh.new()
	rosette.inner_radius = 0.012
	rosette.outer_radius = 0.024
	rosette.rings = 12
	rosette.ring_segments = 6
	var rosettes: Array[Transform3D] = []
	var fleurons: Array[Transform3D] = []
	for k in 24:
		var t := TAU * (k + 0.5) / 24.0
		var d := Vector3(cos(t), 0.0, sin(t))
		var tangent := Vector3(-sin(t), 0.0, cos(t))
		rosettes.append(Transform3D(Basis(tangent, d, tangent.cross(d)), d * (CAGE_R + 0.035) + Vector3(0.0, CAGE_H - 0.14, 0.0)))
		if k % 2 == 0:
			fleurons.append(Transform3D(Basis(), d * (CAGE_R + 0.05) + Vector3(0.0, CAGE_H + 0.12, 0.0)))
	_obs.call("_multi", _cage, "Rosettes", rosette, gilt, rosettes, [], false)
	var fleuron := CylinderMesh.new()
	fleuron.top_radius = 0.0
	fleuron.bottom_radius = 0.022
	fleuron.height = 0.1
	fleuron.radial_segments = 6
	fleuron.rings = 1
	_obs.call("_multi", _cage, "Fleurons", fleuron, gilt, fleurons, [], false)
	_obs.call("_add", _cage, "Halo", sector.call(CAGE_R - 0.12, CAGE_R - 0.05, 0.025, 0.0, TAU, 48), halo, Transform3D(Basis(), Vector3(0.0, CAGE_H - 0.05, 0.0)), false)
	var lamp := SphereMesh.new()
	lamp.radius = 0.035
	lamp.height = 0.07
	var greens := [
		[lamp, Transform3D(Basis(), Vector3(0.0, 1.05, -CAGE_R + 0.07))],
		[lamp, Transform3D(Basis.from_scale(Vector3.ONE * 1.2), Vector3(0.0, CAGE_H + 0.06 + DOME_H + 0.075, 0.0))],
	]
	_obs.call("_add", _cage, "Lamps", _obs.call("_merge", greens), m.green_glow, Transform3D(), false)
	var bowl := SphereMesh.new()
	bowl.radius = 0.1
	bowl.height = 0.1
	bowl.is_hemisphere = true
	_obs.call("_add", _cage, "CeilingLamp", bowl, m.get("shelf_light", m.green_glow), Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0.0, CAGE_H - 0.005, 0.0)), false)
	# The ceiling lamp's light, on the cage only (its own render layer): the hall's light budget
	# stays as it was.
	var light := OmniLight3D.new()
	light.name = "CageLight"
	light.light_color = Color(1.0, 0.8, 0.58)
	light.light_energy = 0.9
	light.omni_range = 2.2
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 0.0
	light.light_cull_mask = CAGE_LAYER
	light.position = Vector3(0.0, CAGE_H - 0.3, 0.0)
	_cage.add_child(light)
	# The cage's gate: a folding lattice across the opening, under the frieze.
	_gates.append(_make_gate(_cage, "CageGate", CAGE_R + 0.03, GATE_BARS, 0.03, CAGE_H - 0.34, brass))
	_cage_gate = _gates[0].node
	for g in _cage.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).layers |= CAGE_LAYER

	# A folding gate at every landing, across the opening, hung from a brass track.
	for i in levels.size():
		var g := _make_gate(root, "LandingGate%d" % i, WALL_R + 0.04, LANDING_BARS, 0.03, 2.12, brass)
		var lg: Node3D = g.node
		lg.position.y = levels[i]
		_obs.call("_add", lg, "Track", sector.call(WALL_R + 0.02, WALL_R + 0.07, 0.04, PI * 0.5 - OPEN_HALF, PI * 0.5 + OPEN_HALF, 16), brass, Transform3D(Basis(), Vector3(0.0, 2.16, 0.0)), false)
		_gates.append(g)
		_landing_gates.append(lg)
		# The collar over the walkway's cut round the shaft, at each gallery.
		if i > 0 and not _is_roof(i):
			# 1 cm proud of the walkway, so the two tops do not fight.
			_obs.call("_add", root, "Collar%d" % i, _collar(1.22, WALL_R + 0.02, 0.05), m.bronze, Transform3D(Basis(), Vector3(0.0, levels[i] - 0.04, 0.0)))
	_build_dials(root, m, brass, gilt, iron)
	# Two cables from the shaft's cap to the cage's dome, stretched to fit every frame.
	var cable := CylinderMesh.new()
	cable.top_radius = 0.008
	cable.bottom_radius = 0.008
	cable.height = 1.0
	cable.radial_segments = 4
	for side: float in [-0.3, 0.3]:
		var c := _obs.call("_add", root, "Cable", cable, steel, Transform3D(Basis(), Vector3(side, 0.0, 0.0)), false) as MeshInstance3D
		_cables.append(c)
	if roof:
		_build_kiosk(root, m)
	_build_sounds(root)


## A folding gate across the opening, r from the axis, its bars h tall from y0, and between two
## neighbours straps crossed in rows of lozenges; folded, its bars stand FOLD apart at the right of
## the opening (+X). Drawn again whenever its openness changes (_sync).
func _make_gate(parent: Node3D, node_name: String, r: float, bars: int, y0: float, h: float, mat: Material) -> Dictionary:
	var node := Node3D.new()
	node.name = node_name
	parent.add_child(node)
	var bar := CylinderMesh.new()
	bar.top_radius = 0.011
	bar.bottom_radius = 0.011
	bar.height = 1.0
	bar.radial_segments = 6
	bar.rings = 1
	var strap := _obs.call("_box", Vector3(0.014, 1.0, 0.004)) as Mesh
	var bar_xf: Array[Transform3D] = []
	bar_xf.resize(bars)
	var strap_xf: Array[Transform3D] = []
	strap_xf.resize((bars - 1) * GATE_ROWS * 2)
	var bm := _obs.call("_multi", node, "Bars", bar, mat, bar_xf, [], false) as MultiMeshInstance3D
	var sm := _obs.call("_multi", node, "Straps", strap, mat, strap_xf, [], false) as MultiMeshInstance3D
	var g := {"node": node, "r": r, "n": bars, "y0": y0, "h": h, "bars": bm.multimesh, "straps": sm.multimesh, "drawn": -1.0}
	_draw_gate(g, 0.0)
	return g


## The angles of a gate's n bars at openness o (0 closed, 1 folded), from the leading bar to the one
## fixed at the right jamb.
func gate_angles(n: int, r: float, o: float) -> PackedFloat32Array:
	var right := OPEN_HALF - 0.03
	var step := lerpf(2.0 * right / (n - 1), FOLD / r, clampf(o, 0.0, 1.0))
	var a := PackedFloat32Array()
	a.resize(n)
	for k in n:
		a[k] = right - (n - 1 - k) * step
	return a


func _draw_gate(g: Dictionary, o: float) -> void:
	var r: float = g.r
	var y0: float = g.y0
	var h: float = g.h
	var n: int = g.n
	var a := gate_angles(n, r, o)
	var bars: MultiMesh = g.bars
	var straps: MultiMesh = g.straps
	for k in n:
		bars.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(1.0, h, 1.0)), Vector3(sin(a[k]) * r, y0 + h * 0.5, cos(a[k]) * r)))
	var row := h / GATE_ROWS
	var i := 0
	for k in n - 1:
		var mid := (a[k] + a[k + 1]) * 0.5
		var out := Vector3(sin(mid), 0.0, cos(mid))
		for j in GATE_ROWS:
			var lo := y0 + row * j
			for d in 2:
				# The two diagonals of a lozenge, the second 4 mm further out so that they never fight.
				var rr := r + 0.013 + 0.004 * d
				var p0 := Vector3(sin(a[k]) * rr, lo + row * d, cos(a[k]) * rr)
				var p1 := Vector3(sin(a[k + 1]) * rr, lo + row * (1 - d), cos(a[k + 1]) * rr)
				var along := p1 - p0
				var x := along.normalized().cross(out).normalized()
				straps.set_instance_transform(i, Transform3D(Basis(x, along, out), (p0 + p1) * 0.5))
				i += 1
	g.drawn = o


## The sounds (scripts/lift_sounds.gd), made once: the hum on the cage, the gates' rattle at its door,
## and the bell, moved to the landing the cage arrives at.
func _build_sounds(root: Node3D) -> void:
	var t0 := Time.get_ticks_usec()
	var snd: Script = load(SOUNDS_PATH)
	# The takes the author chose by ear, where their files are in the build; else the synthesized
	# cues (scripts/sfx_takes.gd).
	var sfx: Script = load(SFX_PATH)
	_hum = _player(_cage, "Hum", sfx.call("pick_loop", "lift-hum", snd.call("hum")), HUM_DB, Vector3(0.0, CAGE_H + 0.3, 0.0))
	# web_loop.gd: in the web build a looping sample plays once; two players take turns there.
	_hum_loop = load(WEB_LOOP_PATH).new()
	_hum_loop.name = "HumLoop"
	add_child(_hum_loop)
	_hum_loop.call("configure", _hum)
	_rattle = _player(_cage, "Rattle", sfx.call("pick", "lift-rattle", snd.call("rattle", GATE_BARS)), -9.0, Vector3(0.0, 1.2, CAGE_R))
	_bell = _player(root, "Bell", sfx.call("pick", "lift-bell", snd.call("bell")), -6.0, _dial_at(0))
	stats.sound_ms = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)


func _player(parent: Node3D, node_name: String, stream: AudioStream, db: float, pos: Vector3) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = node_name
	p.stream = stream
	p.volume_db = db
	p.unit_size = 4.0
	p.max_distance = 30.0
	p.position = pos
	parent.add_child(p)
	return p


## The gates rattle as they start to close or open; the bell rings at the landing on an arrival; the
## motor hums while the cage rides, louder and higher as it goes faster.
func _sound(delta: float) -> void:
	if _hum == null:
		return
	if state != _last_state:
		if state == State.CLOSING or state == State.OPENING:
			_rattle.pitch_scale = 0.94 if state == State.CLOSING else 1.0
			_rattle.play()
			stats.sounds.gate += 1
		if state == State.OPENING and _last_state == State.MOVING:
			_bell.position = _dial_at(at)
			_bell.play()
			stats.sounds.bell += 1
		_last_state = state
	var speed := absf(y - _last_y) / maxf(delta, 0.0001)
	_last_y = y
	var f := clampf(speed / SPEED, 0.0, 1.0)
	if bool(_hum_loop.call("run", state == State.MOVING, 0.85 + 0.35 * f, HUM_DB + linear_to_db(maxf(f, 0.001)))):
		stats.sounds.hum += 1


## Over every landing, facing the hall, a brass dial whose needle follows the cage from the hall (at
## the left) to the top landing (at the right), a gilt dot for each landing. On the roof, on the
## kiosk's frieze.
func _build_dials(root: Node3D, m: Dictionary, brass: Material, gilt: Material, iron: Material) -> void:
	var faces := []
	var rims := []
	var dots := []
	var half := _half_disc(0.0, 0.15, 0.012)
	var rim := _half_disc(0.145, 0.175, 0.022)
	var dot := SphereMesh.new()
	dot.radius = 0.013
	dot.height = 0.026
	dot.radial_segments = 8
	dot.rings = 4
	var needle := _obs.call("_box", Vector3(0.012, 0.12, 0.006)) as Mesh
	for i in levels.size():
		var at_ := _dial_at(i)
		# The half disc stands in the plane facing the hall: its ring_sector's underside is the face.
		var stand := Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), at_)
		faces.append([half, stand])
		rims.append([rim, stand * Transform3D(Basis(), Vector3(0.0, -0.005, 0.0))])
		rims.append([_obs.call("_box", Vector3(0.39, 0.025, 0.03)), Transform3D(Basis(), at_ + Vector3(0.0, -0.012, -0.004))])
		for j in levels.size():
			var phi := _dial_angle(levels[j])
			dots.append([dot, Transform3D(Basis(), at_ + Vector3(-sin(phi) * 0.125, cos(phi) * 0.125, 0.01))])
		dots.append([dot, Transform3D(Basis.from_scale(Vector3.ONE * 1.4), at_ + Vector3(0.0, 0.0, 0.012))])
		var pivot := Node3D.new()
		pivot.name = "Needle%d" % i
		pivot.position = at_ + Vector3(0.0, 0.0, 0.014)
		root.add_child(pivot)
		_obs.call("_add", pivot, "Hand", needle, iron, Transform3D(Basis(), Vector3(0.0, 0.058, 0.0)), false)
		_needles.append(pivot)
	_obs.call("_add", root, "DialFaces", _obs.call("_merge", faces), m.get("body_ivory", m.silver), Transform3D(), false)
	_obs.call("_add", root, "DialRims", _obs.call("_merge", rims), brass, Transform3D(), false)
	_obs.call("_add", root, "DialDots", _obs.call("_merge", dots), gilt, Transform3D(), false)


## Where landing i's dial hangs, in the shaft's frame: on the lintel over the opening, or on the roof
## on the kiosk's frieze.
func _dial_at(i: int) -> Vector3:
	if _is_roof(i):
		return Vector3(0.0, levels[i] + 2.52, KIOSK_R + 0.07)
	return Vector3(0.0, levels[i] + 2.545, WALL_R + 0.14)


## The upper half of a flat disc or ring, lying as ring_sector's do.
func _half_disc(r0: float, r1: float, h: float) -> Mesh:
	return _obs.call("ring_sector", r0, r1, h, 0.0, PI, 16)


## The needle's angle for a cage floor at y: from 70 degrees left of up at the hall to 70 degrees
## right at the top landing.
func _dial_angle(y_: float) -> float:
	var f := clampf((y_ - levels[0]) / maxf(levels[-1] - levels[0], 0.01), 0.0, 1.0)
	return deg_to_rad(lerpf(70.0, -70.0, f))


## The way through the ceiling and the kiosk on the roof, in the shaft's frame. Outside, they draw
## as Upperside does (assets/upperside.gdshader), lit by the galactic core; inside, a lantern
## under the kiosk's cornice lights the cage and the wheel.
func _build_kiosk(root: Node3D, m: Dictionary) -> void:
	var ceiling: float = _obs.get("_ceiling_y")
	var floor_y: float = levels[-1]
	var core := Vector3(-0.468, 0.867, -0.170)
	var sky := _obs.get_node_or_null("Generated/Ceiling/NightSky") as GeometryInstance3D
	if sky != null and sky.material_override is ShaderMaterial:
		core = (sky.material_override as ShaderMaterial).get_shader_parameter("core_dir")
	var bronze := ShaderMaterial.new()
	bronze.shader = load(ROOF_SHADER_PATH)
	bronze.set_shader_parameter("albedo", Color(0.5, 0.37, 0.2))
	bronze.set_shader_parameter("sheen", 0.9)
	bronze.set_shader_parameter("core_dir", core)
	_kiosk = Node3D.new()
	_kiosk.name = "Kiosk"
	root.add_child(_kiosk)
	var glass := ShaderMaterial.new()
	glass.shader = load(GLASS_SHADER_PATH)
	var arc0 := OPEN_HALF + PI * 0.5
	var arc1 := TAU - OPEN_HALF + PI * 0.5
	# Under the ceiling, a brass plate round the cut, turned face down; through the slab, a brass
	# throat whose top is the kiosk's sill, level with the roof's landing. Both lit as the hall is.
	var base := ceiling - 0.012
	_obs.call("_add", root, "CeilingCollar", _collar(1.24, WALL_R + 0.04, 0.05), m.bronze, Transform3D(Basis.from_scale(Vector3(1.0, -1.0, 1.0)), Vector3(0.0, base, 0.0)), false)
	_obs.call("_add", root, "Throat", _obs.call("ring_sector", WALL_R + 0.04, THROAT_R, floor_y - base, 0.0, TAU, 48), m.bronze, Transform3D(Basis(), Vector3(0.0, base, 0.0)), false)
	# The kiosk: glass round all but the door, a bronze base band, a frieze all round that hides
	# the folded gate, mullions, and a cornice under the dome.
	var h := _top - floor_y
	var r := KIOSK_R
	_obs.call("_add", _kiosk, "KioskGlass", _obs.call("ring_sector", r - 0.01, r + 0.01, h - 0.03, arc0, arc1, 48), glass, Transform3D(Basis(), Vector3(0.0, floor_y + 0.003, 0.0)), false)
	_obs.call("_add", _kiosk, "KioskBase", _obs.call("ring_sector", r + 0.01, r + 0.05, 0.22, arc0, arc1, 48), bronze, Transform3D(Basis(), Vector3(0.0, floor_y, 0.0)), false)
	_obs.call("_add", _kiosk, "KioskFrieze", _obs.call("ring_sector", r + 0.01, r + 0.05, h - 2.36, 0.0, TAU, 48), bronze, Transform3D(Basis(), Vector3(0.0, floor_y + 2.36, 0.0)), false)
	_obs.call("_add", _kiosk, "KioskCornice", _obs.call("ring_sector", WALL_R + 0.06, r + 0.12, 0.18, 0.0, TAU, 48), bronze, Transform3D(Basis(), Vector3(0.0, _top - 0.02, 0.0)), false)
	var post := _obs.call("_box", Vector3(0.05, 2.14, 0.05)) as Mesh
	var posts: Array[Transform3D] = []
	for k in 9:  # from one jamb of the door round to the other
		var t := arc0 + (arc1 - arc0) * k / 8.0
		posts.append(Transform3D(Basis(Vector3.UP, -t), Vector3(cos(t), 0.0, sin(t)) * (r + 0.035) + Vector3(0.0, floor_y + 0.22 + 1.07, 0.0)))
	_obs.call("_multi", _kiosk, "KioskPosts", post, bronze, posts, [], false)
	# The dome: glass over the wheel, on eight bronze ribs, a finial and the lift's green lamp.
	var dome_y := _top + 0.16
	var a := r + 0.09
	var b := 1.37
	var cap := SphereMesh.new()
	cap.radius = 1.0
	cap.height = 1.0
	cap.is_hemisphere = true
	cap.radial_segments = 32
	cap.rings = 8
	_obs.call("_add", _kiosk, "KioskDome", cap, glass, Transform3D(Basis.from_scale(Vector3(a, b, a)), Vector3(0.0, dome_y, 0.0)), false)
	var rib := _obs.call("_box", Vector3(0.05, 1.0, 0.04)) as Mesh
	var parts := []
	for k in 8:
		var ang := TAU * (k + 0.5) / 8.0
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var side := Vector3(-dir.z, 0.0, dir.x)
		for s in 10:
			var p0 := dir * a * cos(PI * 0.5 * s / 10.0) + Vector3.UP * b * sin(PI * 0.5 * s / 10.0)
			var p1 := dir * a * cos(PI * 0.5 * (s + 1) / 10.0) + Vector3.UP * b * sin(PI * 0.5 * (s + 1) / 10.0)
			var along := p1 - p0
			var x := side
			var z := x.cross(along.normalized())
			parts.append([rib, Transform3D(Basis(x, along * 1.04, z), (p0 + p1) * 0.5 + Vector3(0.0, dome_y, 0.0))])
	_obs.call("_add", _kiosk, "KioskRibs", _obs.call("_merge", parts), bronze, Transform3D(), false)
	var knob := SphereMesh.new()
	knob.radius = 0.08
	knob.height = 0.16
	_obs.call("_add", _kiosk, "KioskFinial", knob, bronze, Transform3D(Basis(), Vector3(0.0, dome_y + b + 0.04, 0.0)), false)
	var lamp := SphereMesh.new()
	lamp.radius = 0.05
	lamp.height = 0.1
	_obs.call("_add", _kiosk, "KioskLamp", lamp, m.green_glow, Transform3D(Basis(), Vector3(0.0, dome_y + b + 0.16, 0.0)), false)
	var lantern := OmniLight3D.new()
	lantern.name = "KioskLantern"
	lantern.light_color = Color(1.0, 0.8, 0.58)
	lantern.light_energy = 1.4
	lantern.omni_range = 3.0
	lantern.shadow_enabled = false
	lantern.light_volumetric_fog_energy = 0.0
	lantern.position = Vector3(0.0, _top - 0.2, 0.0)
	_kiosk.add_child(lantern)


## The shaft's frame: local +Z towards the hall, so the opening is round +Z.
func _frame_basis() -> Basis:
	var z := Vector3(_in.x, 0.0, _in.y)
	return Basis(Vector3.UP.cross(z).normalized(), Vector3.UP, z)


## A square plate of half size h, with a round hole of radius r, t thick, its top at t.
func _collar(h: float, r: float, t: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 64
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var i0 := Vector3(cos(a0), 0.0, sin(a0)) * r
		var i1 := Vector3(cos(a1), 0.0, sin(a1)) * r
		var o0 := Vector3(cos(a0), 0.0, sin(a0)) * (h / maxf(absf(cos(a0)), absf(sin(a0))))
		var o1 := Vector3(cos(a1), 0.0, sin(a1)) * (h / maxf(absf(cos(a1)), absf(sin(a1))))
		var up := Vector3(0.0, t, 0.0)
		# Top, then the hole's wall, wound clockwise seen from where each faces.
		st.set_normal(Vector3.UP)
		for v in [i0 + up, o0 + up, o1 + up, i0 + up, o1 + up, i1 + up]:
			st.add_vertex(v)
		var nrm := -(Vector3(cos(a0), 0.0, sin(a0)) + Vector3(cos(a1), 0.0, sin(a1))).normalized()
		st.set_normal(nrm)
		for v in [i0, i0 + up, i1 + up, i0, i1 + up, i1]:
			st.add_vertex(v)
	return st.commit()


func _build_ui() -> void:
	if roof:
		# The dip to black through the ceiling (_dip): under every panel and hint.
		var dark := CanvasLayer.new()
		dark.name = "LiftFade"
		dark.layer = 0
		add_child(dark)
		_fade = ColorRect.new()
		_fade.color = Color(0.0, 0.0, 0.0, 0.0)
		_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade.visible = false
		dark.add_child(_fade)
	_ui = CanvasLayer.new()
	_ui.name = "LiftUI"
	_ui.layer = 28
	add_child(_ui)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.04, 0.72)
	style.border_color = Color(0.42, 0.9, 0.55, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.72 if touch else 0.8
	panel.anchor_bottom = panel.anchor_top
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	_ui.add_child(panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.88, 1.0, 0.9))
	_label.add_theme_font_size_override("font_size", 20 if not touch else 26)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_label)
