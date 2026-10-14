extends Node
## A walking body for the fly camera (scripts/fly_camera.gd), added by scripts/observatory.gd.
## The camera moves itself; this node runs just before it and just after it every frame and, in
## walk mode only, turns that move into a body's:
##   - inertia, and a sprint (Shift) at 1.6 times the walk instead of the camera's 3;
##   - Space: a jump, 0.85 m high;
##   - C: crouch or stand up; C while sprinting: a slide, which ends crouched;
##   - a dip on landing, a wider field of view while sprinting, a slight roll in a slide; no head
##     bob: at the camera's 6 m/s it bounced the eye seven times a second (artpass/walk/NOTES.md);
##   - collisions with the steel box and its door leaf, the piers, the statue's pedestal and the
##     shelves;
##   - floors: the hall, the two galleries, which their rail and the shelves bound, and the lift's
##     cage (scripts/lift.gd), which carries the body (artpass/floors/NOTES.md); the roof's lead,
##     between the drum and the balustrade at the eave, where the lift goes on to it
##     (artpass/roof/);
##   - Wolfenstein's keys (The New Order, The New Colossus): Ctrl crouches as C does; Alt with A or
##     D (Q on AZERTY) leans left or right and Alt with W or S rises or ducks to peek, the body
##     standing still; Caps Lock walks at half speed; E is the lift's near it (lift.gd uses_e);
##   - Return to Castle Wolfenstein's lean: Q and E (A and E on AZERTY: the same keys) lean left and
##     right, the body standing still; on a touch screen, two buttons (touch_controls.gd);
##   - leaning the way an aimed course book's title reads (scripts/course_library.gd: right in
##     English and Spanish, left in French): the head turns to the spine, tilts until the title is
##     level and the view closes in on it; it comes back when the lean is let go.
## Free flight (F) is left as it was. The camera stays the only writer of the look and the presets:
## when anything else moves it (a preset, a test), the body lets go, and takes it back at the next
## step, or at a jump or crouch near a floor. --reduced-motion, or the browser's reduced-motion
## setting, turns off the dip, the rolls and the field-of-view change, except the tilt and the zoom
## that read a spine, which the reader asks for and holds.

const SPRINT := 1.6          # times the walking speed
const CROUCH := 0.5          # times the walking speed
const CROUCH_EYE := 1.05     # metres; standing is the camera's walking_eye_height (1.7)
const SLIDE_EYE := 0.85
const RADIUS := 0.3          # the body's, against walls
const REACH := 16.75         # the walkable radius: the shelves' front is at 17.14 m
const GRAVITY := 16.0        # m/s²: with JUMP_SPEED, 0.85 m high and 0.65 s in the air
const JUMP_SPEED := 5.2
const JUMP_BUFFER := 0.12    # s: a jump pressed this long before landing still happens
const ACCEL := 45.0          # m/s² on the floor: walking speed in 0.13 s
const AIR_ACCEL := 10.0
const SLIDE_BOOST := 1.15    # times the sprint speed, at the start of a slide
const SLIDE_FRICTION := 6.0  # m/s²
const SLIDE_TIME := 1.0      # s, at most; a slide also ends below the walking speed
const FOV_KICK := 6.0        # degrees, sprinting; 1.4 times that sliding
const SLIDE_ROLL := 0.045    # radians
const STEP_UP := 0.3         # m: a floor this much above the feet is stepped onto
const SNAP := 0.3            # m: a floor this much below the feet is followed, not fallen to
const LEAN := 0.38           # m sideways, leaning with Alt
const LEAN_ROLL := 0.12      # radians, leaning
const PEEK_UP := 0.18        # m, Alt with W; Alt with S ducks to the crouch's eye
const WALK_SLOW := 0.5       # times the walking speed, with Caps Lock
const VAULT_SPEED := 6.4     # m/s up: the feet rise 1.28 m, over the galleries' handrail (1.07 m)
const VAULT_PUSH := 2.4      # m/s towards the hall, over the rail
const LAND_CAP := 7.0        # m/s: a landing dips the eye as if from no faster than this
const READ_SPAN := 0.65      # of the screen's width: a spine's length, read
const READ_FOV_MIN := 6.0    # degrees: reading from afar zooms no further
const READ_TURN := 8.0       # per second: how fast the head turns to a spine (exponential)
const BROWSE_EDGE := 0.012   # m: how far past the read spine's edge the gaze goes where no spine follows
const BROWSE_SETTLE := 0.4   # s without browsing before the gaze settles back on the spine read
const HUD := "WALK MODE  |  WASD/ZQSD: move  ·  Shift: sprint  ·  Space: jump  ·  Ctrl/C: crouch  ·  Q/E (AZERTY: A/E): lean  ·  F: fly\nClick: look  ·  Esc: release  ·  1–9: views  ·  Ctrl while sprinting: slide  ·  Caps Lock: walk  ·  E: lift"

## Counts for tests.
var stats := {"jumps": 0, "slides": 0, "crouches": 0, "blocked": 0, "colliders": 0, "leans": 0, "falls": 0, "vaults": 0, "reads": 0, "browsed": 0}
var reduced_motion := false

var _obs: Node
var _camera: Camera3D
var _colliders: Array[MeshInstance3D] = []
## A place with its own walls (scripts/multiverse.gd): while set, its walk_collide(p) replaces the
## hall's obstacles and shelves.
var region: Object = null
var _garden_node: Node          # scripts/palace_gardens.gd, for the bays' doors (_gardens)
var _in_bay := false            # the body beyond the shelves' front on the hall's floor: a bay's recess or doorway
var _steel: Node3D
var _attached := false
var _last := Vector3.INF    # where this node left the camera
var _p0 := Vector3.ZERO     # the camera before its own move this frame
var _vel := Vector2.ZERO
var _feet := 0.0            # above the floor
var _vy := 0.0
var _eye := 1.7
var _crouched := false
var _slide := 0.0           # seconds left
var _dip := 0.0
var _dip_v := 0.0
var _kick := 0.0
var _fov_set := -1.0
var _roll := 0.0
var _jump_req := 0.0        # seconds left on a buffered jump
var _crouch_req := false
var _floor := 0.0           # the floor under the body: the hall's, a gallery's or the cage's
var _galleries: Array[float] = []
var _gallery_in := 13.78    # the galleries' rail
var _gallery_out := 17.8
var _lift: Node = null
var _lean := 0.0            # -1 left, 1 right, eased
var _peek := 0.0            # 1 risen, -1 ducked, eased
var _lean_off := Vector2.ZERO  # how far the lean put the eye off the body, last frame
var _lean_was := 0.0        # the lean asked for last frame
var _touch_lean := 0.0      # -1, 0 or 1: the touch controls' lean buttons
var _reading := {}          # the spine being read (course_library.gd aimed_spine), while the lean holds
var _browse := Vector2.ZERO    # yaw and pitch of the gaze off the spine read, browsing the shelf
var _browse_in := Vector2.ZERO # browsing asked for since the last frame (browse)
var _browse_idle := 0.0     # seconds since the last browsing
var _read_fov := false      # reading, or back from it: this node sets the fov the screen shows
var _slow := false          # Caps Lock
var _vaulting := false      # over a gallery's rail, until the body lands
var _cam_radius := -1.0     # the camera's max_radius before the roof widened it; -1 while not
## Web tests only: a page that sets window.__obsWalkDebug before the scene starts gets the body's
## state in window.__obsWalk every frame (artpass/walk/NOTES.md).
var _web_debug := false
var _frame := 0
var _last_step := 0.0


func configure(observatory: Node, camera: Camera3D) -> void:
	_obs = observatory
	_camera = camera


## Runs _before() ahead of every other node's _process. Not SceneTree.process_frame: coroutines
## that await that signal (tests, captures) may move the camera after its first handler.
class _Early extends Node:
	var body: Node

	func _process(_delta: float) -> void:
		body.call("_before")


func _ready() -> void:
	process_priority = 100  # after the camera (0)
	reduced_motion = _prefers_reduced_motion()
	if _camera != null:
		_eye = _stand()
	var early := _Early.new()
	early.name = "Early"
	early.body = self
	early.process_priority = -1000
	add_child(early)
	_gather()
	if OS.has_feature("web"):
		_web_debug = bool(JavaScriptBridge.eval("!!window.__obsWalkDebug", true))


func is_crouched() -> bool:
	return _attached and (_crouched or _slide > 0.0)


func is_airborne() -> bool:
	return _attached and _feet > 0.0


## Whether the body holds the camera: walking, not flying, not moved away by a preset.
func is_walking() -> bool:
	return _attached and not _flying()


## The height of the floor under the body (0 in the hall).
func floor_height() -> float:
	return _floor


## The touch controls' lean buttons (scripts/touch_controls.gd): -1 left, 1 right, 0 let go.
func touch_lean(dir: float) -> void:
	_touch_lean = signf(dir)


## Whether the head is tilted to read a spine.
func is_reading() -> bool:
	return not _reading.is_empty()


## For view_fit.gd, which widens a narrow screen's fov: reading and back from it, this node sets the
## fov the screen shows, starting from the widened one and ending on it.
func holds_fov() -> bool:
	return _read_fov


func _stand() -> float:
	return float(_camera.get("walking_eye_height"))


func _flying() -> bool:
	return bool(_camera.get("_free_fly"))


## Reading a spine, the mouse goes along the shelf instead of turning the camera, which would fight
## the head turned to the spine and drop its tilt; the wheel and A and D (the arrows too) step to
## the next spine, right or left.
func _input(event: InputEvent) -> void:
	if _reading.is_empty() or _camera == null:
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or bool(_camera.get("_looking")):
			browse(mm.relative * float(_camera.get("mouse_sensitivity")))
			get_viewport().set_input_as_handled()
		return
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_step_book(1 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1)
			get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or Input.is_physical_key_pressed(KEY_ALT):
		return  # with Alt, A and D and the arrows lean
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code == KEY_D or code == KEY_RIGHT or code == KEY_A or code == KEY_LEFT:
		_step_book(1 if code == KEY_D or code == KEY_RIGHT else -1)
		get_viewport().set_input_as_handled()


## Reading: a look step, as the camera would turn for the mouse or a drag (touch_controls.gd), moves
## the gaze along the shelf instead, in the tilted screen's own directions: towards the spines the
## pointer moves towards on screen.
func browse(step: Vector2) -> void:
	if _reading.is_empty() or _camera == null or not step.is_finite():
		return
	var b := _camera.global_transform.basis
	var v := b.x * step.x - b.y * step.y
	var yaw := float(_camera.get("_yaw"))
	_browse_in += Vector2(-v.dot(Vector3(cos(yaw), 0.0, -sin(yaw))), v.dot(Vector3.UP))
	_browse_idle = 0.0


## Reading: on to the next spine of the series, right (1) or left (-1) as the shelf is faced.
func _step_book(dir: int) -> void:
	var lib := _library()
	if lib == null or not lib.has_method("neighbour"):
		return
	var yaw := float(_camera.get("_yaw"))
	var j := int(lib.call("neighbour", int(_reading.index), Vector3(cos(yaw), 0.0, -sin(yaw)) * dir))
	if j < 0:
		return
	var spine: Dictionary = lib.call("aim_book", j)
	if not spine.is_empty():
		_reading = spine
		_browse = Vector2.ZERO
		_browse_in = Vector2.ZERO
		stats.browsed += 1


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code == KEY_SPACE:
		_jump_req = JUMP_BUFFER
	elif code == KEY_C or code == KEY_CTRL:
		_crouch_req = true
	elif code == KEY_CAPSLOCK:
		_slow = not _slow


## The obstacles at walking height, found by name: rebuilt scenes free them, so look again then.
## Also the galleries' floors and the lift.
func _gather() -> void:
	_colliders.clear()
	_steel = _obs.get_node_or_null("SteelCube") as Node3D if _obs != null else null
	if _obs == null:
		return
	for n in _obs.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		var id := String(m.name)
		if m.mesh != null and (id == "Pedestal" or id == "DoorLeaf" or (id.begins_with("Pier") and id.trim_prefix("Pier").is_valid_int())):
			_colliders.append(m)
	stats.colliders = _colliders.size() + (1 if _steel != null else 0)
	_galleries.clear()
	var levels = _obs.get("gallery_levels")
	if levels is PackedFloat32Array:
		for g in levels:
			_galleries.append(g)
	if _obs.get("colonnade_radius") != null:
		_gallery_in = float(_obs.get("colonnade_radius")) + 0.78
		_gallery_out = float(_obs.get("outer_radius")) - 0.2
	_lift = _obs.get_node_or_null("Lift")


## Before the camera moves.
func _before() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	var p := _camera.position
	if not p.is_equal_approx(_last):
		# Moved by something else: the start, a preset, a test. The body keeps the camera only
		# if it was left at walking height over a floor.
		var f := _eye_floor(p)
		_attached = not _flying() and f >= 0.0
		_reset()
		_floor = maxf(f, 0.0)
	_p0 = p
	# The camera keeps itself within its max_radius of the centre as it moves (fly_camera.gd, 17 m,
	# inside the shelves); on the roof, a walker goes on to the balustrade, and on the floor into a
	# bay's recess and out through its doors (palace_gardens.gd bay_walk). Only the radius this node
	# widened is put back: the multiverse's corridor sets its own (scripts/multiverse.gd).
	var roof := _on_roof()
	var wide := _attached and not _flying() and (roof or _in_bay)
	# Put past the shelves where a walker may be (F after a flight there, a view, a test), or flying in the
	# library wing or its portal: the bound let out before the camera's first move, which would pull it
	# back to the shelves (2026-10-13: from 20 m down the wing, 21 m back into the hall).
	if not wide and not roof and region == null and _beyond(p):
		wide = true
	if region != null:
		pass  # the corridor sets the camera's bound and puts it back itself; ours waits for its end
	elif wide and _cam_radius < 0.0:
		_cam_radius = float(_camera.get("max_radius"))
		var to := _reach().y + LEAN if roof else _bay_radius()
		_camera.set("max_radius", maxf(_cam_radius, to))
	elif not wide and _cam_radius >= 0.0:
		_camera.set("max_radius", _cam_radius)
		_cam_radius = -1.0


func _reset() -> void:
	_vel = Vector2.ZERO
	_feet = 0.0
	_vy = 0.0
	_eye = _stand()
	_crouched = false
	_slide = 0.0
	_dip = 0.0
	_dip_v = 0.0
	_lean = 0.0
	_peek = 0.0
	_lean_off = Vector2.ZERO
	_vaulting = false
	_stop_reading()
	_read_fov = false


func _process(delta: float) -> void:
	_step(delta)
	if _web_debug and _camera != null:
		_frame += 1
		var p := _camera.position
		var state := {"f": _frame, "dt": snappedf(delta, 0.0001), "x": snappedf(p.x, 0.001), "y": snappedf(p.y, 0.001),
			"z": snappedf(p.z, 0.001), "fov": snappedf(_camera.fov, 0.01), "attached": _attached, "fly": _flying(),
			"crouched": _crouched, "slide": _slide > 0.0, "feet": snappedf(_feet, 0.001), "v": snappedf(_vel.length(), 0.01),
			"floor": snappedf(_floor, 0.001), "lean": snappedf(_lean, 0.01), "read": is_reading(),
			"step": snappedf(_last_step, 0.0001), "w": Input.is_physical_key_pressed(KEY_W),
			"shift": Input.is_physical_key_pressed(KEY_SHIFT), "stats": stats}
		JavaScriptBridge.eval("window.__obsWalk = " + JSON.stringify(state), true)


func _step(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera) or delta <= 0.0:
		return
	for m in _colliders:
		if not is_instance_valid(m):
			_gather()
			break
	if _lift == null or not is_instance_valid(_lift):
		_lift = _obs.get_node_or_null("Lift") if _obs != null else null
	_jump_req = maxf(0.0, _jump_req - delta)
	var cam := _camera
	if _flying():
		_attached = false
		_jump_req = 0.0
		_crouch_req = false
		_lean_off = Vector2.ZERO
		_stop_reading()
		_read_fov = false
		_ease_effects(0.0, 0.0, delta)
		if _cam_radius >= 0.0 and region == null:
			cam.position = _fly_bound(cam.position)
		_last = cam.position
		return
	var p1 := cam.position
	var step := Vector2(p1.x - _p0.x, p1.z - _p0.z)
	_last_step = step.length()
	var walk := maxf(float(cam.get("move_speed")), 0.01)
	if step.length() > walk * float(cam.get("fast_multiplier")) * delta * 1.5 + 0.01:
		# Further than the camera walks in a frame: something else moved it since _before().
		var f := _eye_floor(p1)
		_attached = f >= 0.0
		_reset()
		_floor = maxf(f, 0.0)
		_last = p1
		return
	var intent := step / (delta * walk)  # length 1 walking, 3 with Shift, 0 standing still
	var crouch_tap := _crouch_req
	_crouch_req = false
	_hud()
	if not _attached:
		# A step: the camera has already put itself at walking height, on the floor under the pose.
		# A jump or a crouch: only near the hall's floor, not from a gallery view in the air.
		var here := Vector2(p1.x, p1.z)
		var level := _pose_floor(here, _p0.y)
		var near := level == 0.0 and _p0.y < _stand() + 0.9
		if step != Vector2.ZERO or (near and (_jump_req > 0.0 or crouch_tap)):
			_attached = true
			_reset()
			_floor = level
			_feet = 0.0 if step != Vector2.ZERO else maxf(0.0, p1.y - _stand() - level)
		else:
			_stop_reading()
			_read_fov = false
			_ease_effects(0.0, 0.0, delta)
			_last = p1
			return

	# Alt: the movement keys lean and peek. Q and E lean (E is the lift's near it), and so do the
	# touch buttons. Leaning or peeking, the body stands: the camera's own step (Q also moves it left)
	# is dropped.
	var lean_to := 0.0
	var peek_to := 0.0
	if Input.is_physical_key_pressed(KEY_ALT):
		lean_to = (1.0 if _held(KEY_D) or _held(KEY_RIGHT) else 0.0) - (1.0 if _held(KEY_A) or _held(KEY_Q) or _held(KEY_LEFT) else 0.0)
		peek_to = (1.0 if _held(KEY_W) or _held(KEY_Z) or _held(KEY_UP) else 0.0) - (1.0 if _held(KEY_S) or _held(KEY_DOWN) else 0.0)
		intent = Vector2.ZERO
	else:
		lean_to = (1.0 if _held(KEY_E) and not _lift_uses_e() else 0.0) - (1.0 if _held(KEY_Q) else 0.0)
	if lean_to == 0.0:
		lean_to = _touch_lean
	if lean_to != 0.0:
		intent = Vector2.ZERO
		if lean_to != _lean_was:
			stats.leans += 1
	_lean_was = lean_to

	var sprinting := intent.length() > 1.5
	var speed := _vel.length()
	var grounded := _feet <= 0.0 and _vy <= 0.0
	if crouch_tap:
		if not _crouched and sprinting and grounded and speed > walk * 1.2:
			_slide = SLIDE_TIME
			_vel = _vel.normalized() * maxf(speed, walk * SPRINT) * SLIDE_BOOST
			stats.slides += 1
		else:
			_slide = 0.0
		_crouched = not _crouched
		stats.crouches += 1
	elif sprinting and _crouched and _slide <= 0.0:
		_crouched = false  # sprinting stands up
	# At a gallery's rail, facing the hall, a jump vaults it: up over the handrail and on towards
	# the hall, keeping its speed along the rail.
	var vault_at := Vector2(_p0.x, _p0.z) - _lean_off
	if _jump_req > 0.0 and grounded and _floor >= 1.0 and not _on_roof() and _at_rail(vault_at, intent):
		_jump_req = 0.0
		var inward := -vault_at.normalized()
		_vel = _vel - inward * _vel.dot(inward) + inward * VAULT_PUSH
		_vy = VAULT_SPEED
		_feet = maxf(_feet, 0.001)
		_crouched = false
		_slide = 0.0
		_vaulting = true
		stats.vaults += 1
		grounded = false
	if _jump_req > 0.0 and grounded:
		_jump_req = 0.0
		_vy = JUMP_SPEED
		_feet = maxf(_feet, 0.001)
		_crouched = false  # a jump out of a slide keeps its speed
		_slide = 0.0
		stats.jumps += 1
		grounded = false

	# Horizontal: the camera's move says where to go; the body decides how fast.
	var wish := intent.normalized() if intent.length() > 0.01 else Vector2.ZERO
	var pace := SPRINT if sprinting else (WALK_SLOW if _slow else 1.0)
	var target := wish * walk * pace * (CROUCH if _crouched else 1.0)
	if _slide > 0.0:
		_slide -= delta
		speed = maxf(0.0, _vel.length() - SLIDE_FRICTION * delta)
		_vel = _vel.normalized() * speed
		if speed < walk or _slide <= 0.0:
			_slide = 0.0
	elif grounded:
		_vel = _vel.move_toward(target, ACCEL * delta)
	elif wish != Vector2.ZERO:
		_vel = _vel.move_toward(target, AIR_ACCEL * delta)
	var body := Vector2(_p0.x, _p0.z) - _lean_off
	var flat := _collide(body, body + _vel * delta)
	# Past the shelves on the hall's floor is a bay's recess or doorway; the corridor (a region, far
	# outside the hall) and the roof keep their own bounds.
	_in_bay = region == null and _floor < 1.0 and not _on_roof() and flat.length() > REACH + 0.01

	# The floor under the new position: stepped onto, followed (the cage carries the body), or
	# fallen to.
	var world := _floor + _feet
	var under := _support(flat, world + STEP_UP)
	if grounded and world - under <= SNAP:
		_floor = under
		_feet = 0.0
	else:
		if grounded and world - under > SNAP:
			stats.falls += 1
		_feet = world - under
		_floor = under
		grounded = _feet <= 0.0 and _vy <= 0.0

	# Vertical: a jump or a fall, then gravity; the eye lowers for a crouch or a slide.
	if not grounded:
		_vy -= GRAVITY * delta
		_feet += _vy * delta
		if _feet <= 0.0:
			_feet = 0.0
			if not reduced_motion:
				_dip_v -= minf(absf(_vy), LAND_CAP) * 0.5
			_vaulting = false
			_vy = 0.0
	var eye_target := SLIDE_EYE if _slide > 0.0 else (CROUCH_EYE if _crouched else _stand())
	_eye = lerpf(_eye, eye_target, 1.0 - exp(-14.0 * delta))
	# The landing dip is a critically damped spring back to 0.
	_dip_v += (-120.0 * _dip - 22.0 * _dip_v) * delta
	_dip += _dip_v * delta
	# The lean and the peek, eased; the eye leans off the body, never through the shelves. Reading a
	# spine, the eye stays over the body, so that the aimed book stays aimed.
	var reading := _read_start(lean_to)
	_lean = lerpf(_lean, 0.0 if reading else lean_to, 1.0 - exp(-12.0 * delta))
	_peek = lerpf(_peek, peek_to, 1.0 - exp(-12.0 * delta))
	if absf(_lean) < 0.001 and lean_to == 0.0:
		_lean = 0.0
	if absf(_peek) < 0.001 and peek_to == 0.0:
		_peek = 0.0
	var right := Vector2(cam.basis.x.x, cam.basis.x.z)
	right = right.normalized() if right.length() > 1e-4 else Vector2.RIGHT
	var off := right * LEAN * _lean
	if region == null and off != Vector2.ZERO:
		var lim := _reach()
		var e := (flat + off).length()
		if flat.length() > lim.y + 0.01:
			off = Vector2.ZERO  # in a bay's recess or doorway: no lean
		elif e > lim.y:
			off = (flat + off).normalized() * lim.y - flat
		elif e < lim.x:
			off = (flat + off).normalized() * lim.x - flat
	_lean_off = off
	var peek := PEEK_UP * _peek if _peek > 0.0 else (_stand() - CROUCH_EYE) * _peek
	var hs := _vel.length()
	var y := _floor + _feet + _eye + _dip + peek
	cam.position = Vector3(flat.x + off.x, y, flat.y + off.y)

	var kick := 0.0
	var roll := -LEAN_ROLL * _lean
	if _slide > 0.0:
		kick = FOV_KICK * 1.4
		roll += SLIDE_ROLL
	elif sprinting and hs > walk * 1.1:
		kick = FOV_KICK
	if reading:
		var aim := _read_aim(delta)
		_ease_effects(aim.y, aim.x, delta, true)
	elif _read_fov:
		_read_back(roll, delta)
	else:
		_ease_effects(kick, roll, delta)
	_last = cam.position
	# Out past a bay's glass, its doors open: the gardens' walk on foot takes the visitor on
	# (segway.gd walk_out) and stops this node until they come back in.
	var gardens := _gardens()
	if _floor < 1.0 and region == null and gardens != null and bool(gardens.call("bay_out", flat)):
		var seg := _obs.get_node_or_null("Segway")
		if seg != null and seg.has_method("walk_out") and bool(seg.call("walk_out", flat, _vel)):
			stats.walk_outs = int(stats.get("walk_outs", 0)) + 1
			_attached = false
			_vel = Vector2.ZERO


## Starts reading the aimed course book's spine when the lean goes the way its title reads, and
## stops when the lean is let go. Returns whether the head reads.
func _read_start(lean_to: float) -> bool:
	if lean_to == 0.0 or region != null:
		_stop_reading()
		return false
	var lib := _library()
	if not _reading.is_empty():
		# A tap on another spine (course_library.gd tap) moves the reading on to it.
		var now: Dictionary = lib.call("aimed_spine") if lib != null else {}
		if not now.is_empty() and int(now.index) != int(_reading.index):
			_reading = now
			_browse = Vector2.ZERO
			stats.browsed += 1
		return true
	if lib == null or not lib.has_method("aimed_spine"):
		return false
	var spine: Dictionary = lib.call("aimed_spine")
	if spine.is_empty():
		return false
	# The roll that levels the title: negative, a tilt to the right, for a title that reads down.
	var level := _level_roll(spine.along, float(_camera.get("_pitch")), float(_camera.get("_yaw")))
	if signf(lean_to) != (1.0 if level < 0.0 else -1.0):
		return false
	_reading = spine
	_browse = Vector2.ZERO
	_browse_in = Vector2.ZERO
	lib.call("hold_aim", true)
	stats.reads += 1
	if not _read_fov:
		# From the fov the screen shows: view_fit.gd may have widened it.
		var base := _base_fov()
		var shown := _shown_fov(base)
		_kick = shown - base
		_camera.fov = shown
		_fov_set = shown
		_read_fov = true
	return true


## Turns the head towards the spine being read; returns the roll that levels its title and the
## change of field of view that puts its length across READ_SPAN of the screen's width.
func _read_aim(delta: float) -> Vector2:
	var cam := _camera
	var to: Vector3 = (_reading.centre as Vector3) - cam.global_position
	var yaw_to := atan2(-to.x, -to.z)
	var pitch_to := atan2(to.y, Vector2(to.x, to.z).length())
	if _browse_in != Vector2.ZERO:
		_browse_on(yaw_to, pitch_to, to.length())
		to = (_reading.centre as Vector3) - cam.global_position
		yaw_to = atan2(-to.x, -to.z)
		pitch_to = atan2(to.y, Vector2(to.x, to.z).length())
	else:
		_browse_idle += delta
		if _browse_idle > BROWSE_SETTLE:
			_browse = _browse.lerp(Vector2.ZERO, 1.0 - exp(-3.0 * delta))
	yaw_to += _browse.x
	pitch_to += _browse.y
	var k := 1.0 - exp(-READ_TURN * delta)
	var yaw := lerp_angle(float(cam.get("_yaw")), yaw_to, k)
	var pitch := lerpf(float(cam.get("_pitch")), pitch_to, k)
	cam.set("_yaw", yaw)
	cam.set("_pitch", pitch)
	cam.rotation = Vector3(pitch, yaw, cam.rotation.z)
	# The field of view is vertical; once rolled, the spine runs across the screen's width.
	var screen := cam.get_viewport().get_visible_rect().size
	var aspect := screen.x / maxf(screen.y, 1.0)
	var half_w := float(_reading.length) / (2.0 * READ_SPAN * maxf(to.length(), 0.1))
	var base := _base_fov()
	var fov := clampf(rad_to_deg(2.0 * atan(half_w / aspect)), READ_FOV_MIN, _shown_fov(base))
	return Vector2(_level_roll(_reading.along, pitch_to, yaw_to), fov - base)


## Moves the gaze by the browsing asked for, from the spine read seen at yaw_to and pitch_to, `dist`
## away: up and down its length, and along the shelf to the spine the gaze then meets, which is read
## in turn. Off the spine read where none follows, it goes on to the next one along, across the gap
## between two departments; at the series' end it stops.
func _browse_on(yaw_to: float, pitch_to: float, dist: float) -> void:
	var want := _browse + _browse_in
	_browse_in = Vector2.ZERO
	var half_len := atan2(float(_reading.length) * 0.5, dist)
	want.y = clampf(want.y, -half_len, half_len)
	var lib := _library()
	if lib == null or not lib.has_method("book_on_ray"):
		_browse = want
		return
	var read := int(_reading.index)
	var from := _camera.global_position
	var dir := Basis.from_euler(Vector3(pitch_to + want.y, yaw_to + want.x, 0.0)) * Vector3.FORWARD
	var hit := int(lib.call("book_on_ray", from, dir))
	var jump := false
	if hit < 0 and not bool(lib.call("ray_near_book", read, from, dir, BROWSE_EDGE)):
		if not is_equal_approx(want.x, _browse.x):
			# Yaw grows to the left.
			var yaw := yaw_to + want.x
			var side := Vector3(cos(yaw), 0.0, -sin(yaw)) * (1.0 if want.x < _browse.x else -1.0)
			hit = int(lib.call("neighbour", read, side))
			jump = hit >= 0
		if hit < 0:
			return  # the series' end: the gaze stays
	if hit >= 0 and hit != read:
		var spine: Dictionary = lib.call("aim_book", hit)
		if not spine.is_empty():
			# The gaze stays where it went, its offset now from the new spine; or, across a gap, on it.
			var to: Vector3 = (spine.centre as Vector3) - from
			var yaw_new := atan2(-to.x, -to.z)
			var pitch_new := atan2(to.y, Vector2(to.x, to.z).length())
			_reading = spine
			_browse = Vector2(0.0 if jump else wrapf(yaw_to + want.x - yaw_new, -PI, PI), pitch_to + want.y - pitch_new)
			stats.browsed += 1
			return
	_browse = want


## Back from reading: the fov eases to the one the screen shows unread, and view_fit.gd then has it
## again; the roll goes back to the lean's.
func _read_back(roll: float, delta: float) -> void:
	var base := _base_fov()
	var back := _shown_fov(base) - base
	_ease_effects(back, 0.0 if reduced_motion else roll, delta, true)
	if is_equal_approx(_kick, back):
		_read_fov = false
		_kick = 0.0
		_camera.fov = base
		_fov_set = base


## The fov the others set, without this node's kick.
func _base_fov() -> float:
	return _camera.fov - _kick if is_equal_approx(_camera.fov, _fov_set) else _camera.fov


## The fov the screen shows when the others set `given`: view_fit.gd widens it on narrow screens.
func _shown_fov(given: float) -> float:
	var fit := _obs.get_node_or_null("ViewFit") if _obs != null else null
	return float(fit.call("fitted", given)) if fit != null and fit.has_method("fitted") else given


## The camera roll that shows a line running along `along` level and left to right, looking with
## that pitch and yaw.
static func _level_roll(along: Vector3, pitch: float, yaw: float) -> float:
	var t := Basis.from_euler(Vector3(pitch, yaw, 0.0)).inverse() * along
	return atan2(t.y, t.x)


func _stop_reading() -> void:
	if _reading.is_empty():
		return
	_reading = {}
	_browse = Vector2.ZERO
	_browse_in = Vector2.ZERO
	var lib := _library()
	if lib != null and lib.has_method("hold_aim"):
		lib.call("hold_aim", false)


func _library() -> Node:
	return _obs.get_node_or_null("Generated/CourseShelves") if _obs != null else null


func _lift_uses_e() -> bool:
	return _lift != null and _lift.has_method("uses_e") and bool(_lift.call("uses_e"))


## Whether a body at p stands at a gallery's rail, going or (standing still) looking towards the
## hall, out of the lift's cage.
func _at_rail(p: Vector2, intent: Vector2) -> bool:
	if p.length() > _gallery_in + RADIUS + 0.15 or (_lift != null and bool(_lift.call("in_shaft", p))):
		return false
	var dir := intent
	if dir.length() < 0.1 and _camera != null:
		dir = Vector2(-_camera.basis.z.x, -_camera.basis.z.z)
	return dir.length() > 1e-4 and dir.normalized().dot(-p.normalized()) > 0.5


## The floor the body finds at p no higher than top: the hall's, a gallery's walkway (not over the
## lift's shaft), or the lift's cage.
func _support(p: Vector2, top: float) -> float:
	if region != null and is_instance_valid(region):
		return 0.0
	var best := 0.0
	var shaft := _lift != null and bool(_lift.call("in_shaft", p))
	var r := p.length()
	if not shaft and r >= _gallery_in - 0.3 and r <= _gallery_out:
		for g in _galleries:
			if g <= top:
				best = maxf(best, g)
	if _lift != null:
		best = maxf(best, float(_lift.call("support", p, top)))
		var lead := float(_lift.call("roof_floor", p))
		if lead <= top:
			best = maxf(best, lead)
	return best


## The floor whose eye height the camera is at (a preset, the start), or -1.
func _eye_floor(p: Vector3) -> float:
	var flat := Vector2(p.x, p.z)
	var floors: Array[float] = [0.0]
	if flat.length() >= _gallery_in - 0.3:
		floors.append_array(_galleries)
	if _lift != null and bool(_lift.call("in_shaft", flat)):
		floors.append(float(_lift.get("y")))
	if _lift != null and float(_lift.call("roof_floor", flat)) > -INF:
		floors.append(float(_lift.call("roof_floor", flat)))
	for f in floors:
		if absf(p.y - (f + _stand())) < 0.05:
			return f
	return -1.0


## The floor a pose in the air stands over: a gallery when the eye is between 1 and 5 m above its
## walkway and over it or its rail (the gallery view leans over the rail), the roof's lead when the
## eye is as high over it, the hall otherwise.
func _pose_floor(p: Vector2, eye_y: float) -> float:
	var best := 0.0
	var r := p.length()
	if r >= _gallery_in - 1.0 and r <= _gallery_out:
		for g in _galleries:
			if eye_y >= g + 1.0 and eye_y <= g + 5.0:
				best = maxf(best, g)
	if _lift != null:
		var lead := float(_lift.call("roof_floor", p))
		if eye_y >= lead + 1.0 and eye_y <= lead + 5.0:
			best = maxf(best, lead)
	return best


## Whether the body is up on the roof, the lift's roof landing included.
func _on_roof() -> bool:
	return _lift != null and region == null and bool(_lift.call("on_roof", _floor))


## The palace gardens (scripts/palace_gardens.gd, made by extra_views.gd), whose bays' doors let the
## body out to the terrace; null without them.
func _gardens() -> Node:
	if _garden_node == null or not is_instance_valid(_garden_node):
		_garden_node = _obs.get_node_or_null("PalaceGardens") if _obs != null else null
	return _garden_node if _garden_node != null and _garden_node.has_method("bay_walk") else null


## How far out the body may go on the floor: through a bay's doorway, or down the library wing
## (palace_gardens.gd walk_radius).
func _bay_radius() -> float:
	var gardens := _gardens()
	if gardens != null and gardens.has_method("walk_radius"):
		return float(gardens.call("walk_radius"))
	return float(_obs.get("outer_radius")) + 1.5


## The library wing (scripts/library_wing.gd, made by extra_views.gd), whose portal and nave the camera
## flies into; null without it.
func _wing() -> Node:
	var wing := _obs.get_node_or_null("LibraryWing") if _obs != null else null
	return wing if wing != null and wing.has_method("fly") else null


## Whether the camera at p, past the shelves' front, is where the body may walk (a bay's recess, the
## library wing: palace_gardens.gd bay_walk keeps it there) or, flying, in the wing or its portal.
func _beyond(p: Vector3) -> bool:
	var flat := Vector2(p.x, p.z)
	if flat.length() <= REACH + 0.01:
		return false
	if _flying():
		var wing := _wing()
		return wing != null and wing.call("fly", p, RADIUS) != Vector3.INF
	var gardens := _gardens()
	return gardens != null and (gardens.call("bay_walk", flat, RADIUS, REACH) as Vector2).distance_to(flat) < 0.05


## A flying camera let past its own bound (_before): kept in the library wing, or brought back to that
## bound where it has left the wing (fly_camera.gd keeps a flight within max_radius of the centre).
func _fly_bound(p: Vector3) -> Vector3:
	var flat := Vector2(p.x, p.z)
	if flat.length() <= _cam_radius:
		return p
	var wing := _wing()
	var q: Vector3 = wing.call("fly", p, RADIUS) if wing != null else Vector3.INF
	if q != Vector3.INF:
		return q
	flat = flat.normalized() * _cam_radius
	return Vector3(flat.x, p.y, flat.y)


## How near to and how far from the hall's centre the body's middle, or the eye leaning, may go: on
## the roof, from the drum to the balustrade; elsewhere, the shelves' front.
func _reach() -> Vector2:
	if _on_roof():
		var lim: Vector2 = _lift.call("roof_limits")
		return Vector2(lim.x + RADIUS, lim.y - RADIUS)
	return Vector2(0.0, REACH)


## Pushes the body, going from prev to p, out of every obstacle of its floor and keeps it inside the
## shelves; a wall stops the part of the velocity that goes into it.
func _collide(prev: Vector2, p: Vector2) -> Vector2:
	if region != null and is_instance_valid(region):
		var q: Vector2 = region.call("walk_collide", p)
		if not q.is_equal_approx(p):
			_block(-(q - p).normalized())
		return q
	if _floor < 1.0:
		var boxes := _boxes(p)
		for pass_i in 2:
			for b: Array in boxes:
				p = _push_box(p, b[0], b[1], b[2], b[3])
	if _lift != null:
		var q: Vector2 = _lift.call("constrain", prev, p, _floor, RADIUS)
		if not q.is_equal_approx(p):
			_block(-(q - p).normalized())
			p = q
	# On a gallery, the rail on its inner edge.
	var in_cage := _lift != null and bool(_lift.call("in_shaft", prev))
	var roof := _on_roof()
	if not roof and _floor >= 1.0 and not in_cage and not _vaulting and p.length() < _gallery_in + RADIUS:
		var n := p.normalized() if p.length() > 1e-4 else Vector2.RIGHT
		p = n * (_gallery_in + RADIUS)
		_block(-n)
	# On the roof, the drum and the balustrade; below it, the shelves, but where a bay opens into its
	# recess and out through its doors (palace_gardens.gd bay_walk).
	var lim := _reach()
	var out := p.normalized() if p.length() > 1e-4 else Vector2.RIGHT
	if p.length() > lim.y:
		var q := out * lim.y
		var gardens := _gardens()
		if not roof and _floor < 1.0 and gardens != null:
			q = gardens.call("bay_walk", p, RADIUS, lim.y)
		if not q.is_equal_approx(p):
			_block((p - q).normalized())
		p = q
	elif p.length() < lim.x:
		p = out * lim.x
		_block(-out)
	return p


## The obstacles near p as floor-plane boxes [centre, unit axis u, unit axis v, half sizes], read
## from their nodes every frame, since the door leaf can swing (steel_cube.gd door_open_degrees).
func _boxes(p: Vector2) -> Array:
	var out := []
	if _steel != null and is_instance_valid(_steel):
		var size: Vector3 = _steel.get("box_size")
		var o := _steel.global_position
		# The shell with its edge ribs; the 14 cm plinth around it is a step, not a wall.
		out.append([Vector2(o.x, o.z), Vector2.RIGHT, Vector2.DOWN, Vector2(size.x, size.z) * 0.5 + Vector2(0.04, 0.04)])
	for m in _colliders:
		if not is_instance_valid(m):
			continue
		var xf := m.global_transform
		if Vector2(xf.origin.x - p.x, xf.origin.z - p.y).length_squared() > 16.0:
			continue  # nothing here is 4 m from its origin: the door leaf is 1.5 m, a pier 0.9
		var aabb := m.mesh.get_aabb()
		var c := xf * aabb.get_center()
		var ax := xf.basis.x * aabb.size.x * 0.5
		var az := xf.basis.z * aabb.size.z * 0.5
		var u := Vector2(ax.x, ax.z)
		var v := Vector2(az.x, az.z)
		var h := Vector2(u.length(), v.length())
		if h.x > 1e-4 and h.y > 1e-4:
			out.append([Vector2(c.x, c.z), u / h.x, v / h.y, h])
	return out


## The circle of RADIUS at p, out of the box with centre c, unit axes u and v and half sizes h.
func _push_box(p: Vector2, c: Vector2, u: Vector2, v: Vector2, h: Vector2) -> Vector2:
	var d := p - c
	var local := Vector2(d.dot(u), d.dot(v))
	if absf(local.x) > h.x + RADIUS or absf(local.y) > h.y + RADIUS:
		return p
	var q := local.clamp(-h, h)
	var out := local - q
	var dist := out.length()
	if dist >= RADIUS:
		return p
	if dist > 1e-5:
		local = q + out / dist * RADIUS
	else:
		# The centre is inside: leave by the nearest side.
		var pen := h - local.abs()
		if pen.x < pen.y:
			local.x = (h.x + RADIUS) * (1.0 if local.x >= 0.0 else -1.0)
		else:
			local.y = (h.y + RADIUS) * (1.0 if local.y >= 0.0 else -1.0)
	var pushed := c + u * local.x + v * local.y
	_block(-(pushed - p).normalized() if pushed != p else Vector2.ZERO)
	return pushed


## n points into the wall.
func _block(n: Vector2) -> void:
	if n == Vector2.ZERO:
		return
	var into := _vel.dot(n)
	if into > 0.0:
		_vel -= n * into
		stats.blocked += 1


## Field of view and roll, eased towards their targets. A preset sets its own field of view: that
## becomes the base, and whatever was left of the kick is dropped. `asked`: the reader holds them
## (reading a spine), so reduced motion keeps them.
func _ease_effects(kick: float, roll: float, delta: float, asked := false) -> void:
	if reduced_motion and not asked:
		kick = 0.0
		roll = 0.0
	var base := _camera.fov - _kick
	if not is_equal_approx(_camera.fov, _fov_set):
		base = _camera.fov
		_kick = 0.0
	var k := lerpf(_kick, kick, 1.0 - exp(-8.0 * delta))
	if absf(k - kick) < 0.02:
		k = kick
	if k != _kick:
		_kick = k
		_camera.fov = base + k
	_fov_set = _camera.fov
	if roll != 0.0 or _roll != 0.0:
		var r := lerpf(_roll, roll, 1.0 - exp(-10.0 * delta))
		if absf(r - roll) < 0.0005:
			r = roll
		_roll = r
		_camera.rotation.z = r


## fly_camera.gd writes its walk-mode hint when the scene starts and at each F; this one adds the
## jump, crouch, slide, lean and lift. The touch controls write their own text, which does not
## start this way.
func _hud() -> void:
	var root := _camera.get_parent()
	var hint := root.get_node_or_null("ControlsHud/Panel/Hint") as Label
	# And the curio wheel's key, where there is one (scripts/curio_wheel.gd).
	var text := HUD + ("  ·  Tab: curios" if root.get_node_or_null("CurioWheel") != null else "")
	# A third line for what was found only by chance (2026-10-03): the IX hologram, Seldon's
	# recording and the wand's TARS, each where the scene has it.
	var extra := PackedStringArray()
	if root.get_node_or_null("Hologram") != null:
		extra.append("H: IX hologram")
	if root.get_node_or_null("SeldonRecording") != null:
		extra.append("R: Seldon's recording")
	if root.get_node_or_null("CurioWheel") != null:
		extra.append("Tab, then the wand: a TARS")
	# And the ride in the gardens (scripts/segway.gd).
	if root.get_node_or_null("Segway") != null:
		extra.append("G: ride in the gardens")
	if not extra.is_empty():
		text += "\n" + "  ·  ".join(extra)
	if hint != null and hint.text.begins_with("WALK MODE") and hint.text != text:
		hint.text = text


static func _held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)


static func _prefers_reduced_motion() -> bool:
	if OS.get_cmdline_user_args().has("--reduced-motion"):
		return true
	if OS.has_feature("web") and not Engine.is_editor_hint():
		return bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	return false
