extends Camera3D
## First-person walk: click to lock mouse look, Escape to release, WASD/ZQSD
## or arrows to move, Shift to sprint. F toggles free-fly (E/Space up, C down).
## Right-drag remains a temporary mouse-look option. 1 to 7 jump to presets.

## [position, target, vertical fov]. Art pass framing: the overview stands inside the
## colonnade on the door axis (v1 stood under the first walkway, behind a pier), and the
## gallery view leans out through an arch of the upper gallery, in front of the rail.
const PRESETS := {
	"overview": [Vector3(0.0, 1.7, 10.4), Vector3(0.0, 6.0, 0.0), 64.0],
	"door": [Vector3(2.6, 1.8, 8.5), Vector3(0.0, 1.7, 1.8), 60.0],
	"gallery": [Vector3(11.06, 14.0, 7.39), Vector3(0.0, 4.5, 0.0), 64.0],
	"dome": [Vector3(0.0, 1.8, 6.5), Vector3(0.0, 23.0, 0.0), 72.0],
	"hero_a": [Vector3(0.0, 2.0, 12.0), Vector3(0.0, 7.0, 0.0), 90.0],
	"hero_b": [Vector3(0.0, 2.5, 10.4), Vector3(0.0, 7.0, 0.0), 100.0],
	"hero_c": [Vector3(2.0, 2.2, 11.8), Vector3(0.0, 7.5, 0.0), 92.0],
}
const PRESET_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]

@export var move_speed := 6.0
@export var fast_multiplier := 3.0
@export var mouse_sensitivity := 0.0025
@export var max_radius := 17.0
@export var height_limits := Vector2(0.4, 24.0)
@export var walking_eye_height := 1.7

var _yaw := 0.0
var _pitch := 0.0
var _looking := false
var _click_locked := false
var _right_drag := false
var _free_fly := false


func _ready() -> void:
	_sync_angles()
	_update_hud()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			var preset := arg.trim_prefix("--preset=")
			if PRESETS.has(preset):
				go_to_preset(preset)


func go_to_preset(preset: String) -> void:
	var p: Array = PRESETS[preset]
	look_at_from_position(p[0], p[1], Vector3.UP)
	fov = p[2]
	_sync_angles()


func _sync_angles() -> void:
	var e := basis.get_euler()
	_pitch = e.x
	_yaw = e.y


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_click_locked = true
			_set_mouse_look(true)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_right_drag = mb.pressed
			_set_mouse_look(_click_locked or _right_drag)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			move_speed = minf(move_speed * 1.2, 60.0)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move_speed = maxf(move_speed / 1.2, 0.5)
	elif event is InputEventMouseMotion and _looking:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - mm.relative.y * mouse_sensitivity, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		if code == KEY_ESCAPE:
			_click_locked = false
			_right_drag = false
			_set_mouse_look(false)
			return
		if code == KEY_F:
			_free_fly = not _free_fly
			_update_hud()
			return
		var i := PRESET_KEYS.find(code)
		if i >= 0:
			go_to_preset(PRESETS.keys()[i])


func _set_mouse_look(enabled: bool) -> void:
	_looking = enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE


func _update_hud() -> void:
	var hint := get_parent().get_node_or_null("ControlsHud/Panel/Hint") as Label
	if hint == null:
		return
	if _free_fly:
		hint.text = "FLY MODE  |  WASD/ZQSD: move  ·  E/Space: rise  ·  C: descend  ·  F: walk\nClick: look  ·  Esc: release  ·  Shift: sprint  ·  1–7: views"
	else:
		hint.text = "WALK MODE  |  WASD/ZQSD: move  ·  F: fly  ·  Shift: sprint  ·  1–7: views\nClick: look  ·  Esc: release"


func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	var forward := -basis.z if _free_fly else Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
	var right := basis.x if _free_fly else Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	if _held(KEY_W) or _held(KEY_Z) or _held(KEY_UP):
		dir += forward
	if _held(KEY_S) or _held(KEY_DOWN):
		dir -= forward
	if _held(KEY_A) or _held(KEY_Q) or _held(KEY_LEFT):
		dir -= right
	if _held(KEY_D) or _held(KEY_RIGHT):
		dir += right
	if _free_fly and (_held(KEY_E) or _held(KEY_SPACE)):
		dir += Vector3.UP
	if _free_fly and _held(KEY_C):
		dir -= Vector3.UP
	if dir == Vector3.ZERO:
		return
	var speed := move_speed * (fast_multiplier if _held(KEY_SHIFT) else 1.0)
	var p := position + dir.normalized() * speed * delta
	var flat := Vector2(p.x, p.z)
	if flat.length() > max_radius:
		flat = flat.normalized() * max_radius
	position = Vector3(flat.x, clampf(p.y, height_limits.x, height_limits.y) if _free_fly else walking_eye_height, flat.y)


func _held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)
