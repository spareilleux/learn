extends Node3D
## A ride in the palace gardens on a self-balancing scooter (the author, 2026-10-04: "on doit pouvoir se
## balader dans les jardins en Segway"), made by scripts/palace_gardens.gd. G gets on, on the terrace
## before the ramp's head, facing down the garden. Riding:
##   - W, Z or the up arrow go forward, S or the down arrow back; Shift rides faster;
##   - A, Q or the left arrow and D or the right arrow turn the scooter, and the view with it;
##   - the mouse (a drag on a touch screen) looks round, and once the scooter moves it steers where the
##     view looks, unless the view looks back: standing still, a look round turns the head alone;
##   - hands off (no key and no look) for AUTO_AFTER seconds, the autopilot rides a tour of the gardens
##     (the author, 2026-10-04: "la balade en segway devrait etre automatique quand l'utiliseur touche a
##     rien"): down the ramp, along the parterre's walks, round it, beside the canal to its far end and
##     back up the other side. Away from the tour, it goes back the way the scooter came, or straight to
##     the tour when nothing stands between. A ride key takes over at once; the mouse only looks round;
##   - the ground is followed: the terrace, the ramp down the garden's axis, the parterre and the
##     grounds; hedges, trees, lamp posts, the water, the balustrade, the walls and people stop the
##     scooter (palace_gardens.gd ground_at and push_out), and it goes no further than RIDE_R from the
##     hall;
##   - the rider leans forward speeding up, back slowing down, and into a turn, as on a
##     self-balancing scooter; not with --reduced-motion or the browser's reduced-motion setting.
## G riding gets off beside the scooter, which stays where it is (the author: "on devrait pouvoir
## descendre et remonter sur le segway"); on foot, the same keys walk, stopped as the scooter is, and G
## within REACH of the scooter gets back on. A preset (keys 1 to 9), or anything else that moves the
## camera, ends the ride or the walk where it put the camera, and the scooter goes back to the terrace.
## The scooter is a kit made in Blender (artpass/gardens/blender/segway_kit.py), generic, with no
## maker's name: its handlebar shows looking down, its wheels turn as it rolls, its headlamp lights
## the ground ahead. While riding or walking here, the fly camera's own moves and the walking body
## stop, as the drone stops them (scripts/drone.gd); the camera's look and its presets stay.
## --segway (?segway=1) starts on the scooter. dismount() leaves the gardens, back where the visitor
## stood when they got on (on the roof view, if G was pressed there).

const KIT := "res://assets/garden_segway_%s.obj"
const PARTS := ["body", "metal", "trim", "light", "tyre", "dish", "spokes"]
const SPEED := 5.5           # m/s, about 20 km/h: a self-balancing scooter's usual top speed
const FAST := 1.6            # times SPEED, with Shift
const BACK := 1.8            # m/s, backwards
const ACCEL := 2.4           # m/s²
const BRAKE := 4.5           # m/s², slowing with the other key
const COAST := 2.0           # m/s², with no key: it slows to a stand, balancing
const TURN := 1.7            # rad/s, with A or D
const FOLLOW := 2.6          # per second: how fast a moving scooter turns to where the view looks
const LOOK_BACK := 1.6       # radians: a view further round than this looks, and does not steer
const RADIUS := 0.4          # the rider on the scooter, against what stands round them
const STEP := 0.35           # m: a rise or a drop up to this, in one step, is ridden over
const SUB := 0.25            # m: the longest step, so that a slow frame cannot jump a hedge
const DECK := 0.18           # the platform above the ground (segway_kit.py)
const EYE := 1.66            # the eye above the platform
const WHEEL_R := 0.24
const TRACK := 0.3           # from the middle to each wheel
const MOUNT := Vector2(0.0, 21.0)  # (x, z): on the terrace, before the ramp's head
const LEAN := 0.012          # radians of pitch per m/s² of acceleration
const LEAN_MAX := 0.05
const ROLL := 0.01           # radians of roll per rad/s of turn and m/s of speed
const ROLL_MAX := 0.06
# The autopilot.
const AUTO_AFTER := 3.0      # s with no ride key and no look before it takes over
const AUTO_SPEED := 3.2      # m/s on the tour, about 11.5 km/h
const AUTO_SLOW := 1.2       # m/s with people close ahead
const AUTO_TURN := 1.3       # rad/s at most
const AUTO_LOOK := 2.0       # m ahead on the tour, plus 0.4 s of the speed
const AUTO_PITCH := -0.1     # the view's pitch, riding on the tour
const LOOK_HOLD := 3.0       # s after a look round before the view turns back ahead
const JOIN_R := 30.0         # m: how far the tour is looked for in a straight line
const FILLET := 2.5          # m: the tour's corners rounded to this radius at most
# On foot.
const REACH := 2.5           # m from the scooter within which G gets back on
const FOOT_RADIUS := 0.3
const FOOT_SPRINT := 1.6
const SCOOTER_R := 0.45      # the parked scooter, for the visitor on foot
const TOUR_CELL := 8.0       # m: the tour's index, to find it near a place
## The ride's views drawn once, at the first mount, where the web build's renderer is. There the shaders
## of what the tour comes to compiled as it came to it: in a fresh browser, with the quality level fixed,
## a frame of 667 ms at the autopilot's first turn or on the ramp (artpass/gardens/NOTES.md, "Where the
## slow web frames fall"). A small camera of its own, in a viewport of the gardens' world, looks from
## each pose ((x, z) of the eye, then of what it looks at) for one frame in WARM_EVERY, the scooter at a
## stand and the autopilot waiting: the frames between keep the median frame time, which
## scripts/quality.gd reads, the scene's own. As scripts/curio_wheel.gd warms the troupe. Natively the
## drivers keep their own shaders and without a screen nothing is drawn: --warm-ride runs it there, for
## tests.
const WARM_POSES := [
	[Vector2(0.0, 21.0), Vector2(0.0, 120.0)], [Vector2(0.0, 21.0), Vector2(-24.0, 14.0)],
	[Vector2(0.0, 21.0), Vector2(24.0, 14.0)], [Vector2(0.0, 23.0), Vector2(0.0, 0.0)],
	[Vector2(-0.6, 45.0), Vector2(0.0, 120.0)], [Vector2(-0.6, 63.5), Vector2(-65.0, 60.0)],
	[Vector2(0.6, 63.5), Vector2(65.0, 60.0)], [Vector2(0.0, 66.0), Vector2(0.0, 20.0)],
	[Vector2(-65.5, 60.0), Vector2(-65.5, 124.0)], [Vector2(65.5, 60.0), Vector2(65.5, 124.0)],
	[Vector2(-65.5, 124.0), Vector2(0.0, 124.0)], [Vector2(-1.0, 164.5), Vector2(-16.8, 326.0)],
	[Vector2(-16.8, 250.0), Vector2(0.0, 430.0)], [Vector2(16.8, 250.0), Vector2(16.8, 172.0)],
]
const WARM_EVERY := 4
const WARM_SIZE := Vector2i(160, 90)
## Not while scripts/quality.gd may still take back a step down made at a first visit's compiles, nor
## this soon after a level change, when it measures: there the warm-up's compiles read as slowness. In a
## fresh browser with ?segway=1 they fell in the window after the step to level 5 (a median of 489 ms),
## and the step back up never came. Then the warm-up waits for the scooter to stand with the autopilot
## off, or for the next mount, and the ride compiles as it goes, as before.
const WARM_AFTER_CHANGE_S := 5.0
## Nor above this quality level: there the frames are slow of themselves, not of compiles. Under
## SwiftShader at level 5 the warm-up kept the scooter standing 13.3 s instead of 6.6, and the ride
## still had 19 frames over 500 ms in 77 s (22 in 83 s without it).
const WARM_MAX_LEVEL := 3
## The tour, (x, z), closed, on the walks' middle lines where the people keep to the sides: from the
## terrace down the ramp (x -0.6), round by the parterre's cross walk at z 60 and its west edge
## (x -65.5), back in at z 124, down the far middle (x -1), across before the canal's head (z 165),
## beside the canal (x -16.8) to its far end, and back up the other side to the ramp (x 0.6). The basin's rim meets the parterre's hedges: the
## axis is cut there (artpass/gardens/ride2/map1). Checked by artpass/gardens/ride2/tourmap.gd.
const TOUR := [
	Vector2(0.0, 20.8), Vector2(-2.2, 21.6), Vector2(-0.6, 25.0), Vector2(-0.6, 63.5), Vector2(-3.5, 66.5),
	Vector2(-8.75, 66.5), Vector2(-8.75, 60.0), Vector2(-65.5, 60.0), Vector2(-65.5, 124.0), Vector2(-8.75, 124.0),
	Vector2(-1.0, 126.0), Vector2(-1.0, 164.5), Vector2(-15.5, 165.5), Vector2(-16.8, 172.0), Vector2(-16.8, 326.0),
	Vector2(-12.0, 336.0), Vector2(0.0, 338.0), Vector2(12.0, 336.0), Vector2(16.8, 326.0), Vector2(16.8, 172.0),
	Vector2(15.5, 165.5), Vector2(1.0, 164.5), Vector2(1.0, 126.0), Vector2(8.75, 124.0), Vector2(65.5, 124.0), Vector2(65.5, 60.0), Vector2(8.75, 60.0),
	Vector2(8.75, 66.5), Vector2(3.5, 66.5), Vector2(0.6, 63.5), Vector2(0.6, 25.0), Vector2(2.2, 21.6),
]
const HUD := "SEGWAY  |  W/Z: forward  ·  S: back  ·  A/Q, D: turn  ·  Shift: faster  ·  G: get off\nMouse: look and steer  ·  Hands off 3 s: autopilot  ·  Esc: release  ·  1–9: back inside  ·  %d km/h"
const HUD_AUTO := "SEGWAY, AUTOPILOT  |  a tour of the gardens  ·  W/Z, S, A/Q, D: take over  ·  G: get off\nMouse: look round  ·  Esc: release  ·  1–9: back inside  ·  %d km/h"
const HUD_FOOT := "ON FOOT IN THE GARDENS  |  WASD/ZQSD: walk  ·  Shift: faster  ·  G by the scooter: ride (%d m away)\nClick: look  ·  Esc: release  ·  1–9: back inside"
const HINT := "G: ride in the gardens"

var riding := false
var on_foot := false
## On the tour by itself.
var auto := false
## False: no autopilot (captures that hold a view still).
var autopilot := true
var reduced_motion := false
## Counts for tests.
var stats := {"rides": 0, "ended": 0, "blocked": 0, "metres": 0.0, "kit": false, "auto_starts": 0,
	"auto_m": 0.0, "takeovers": 0, "joins_straight": 0, "joins_back": 0, "lost": 0, "replans": 0,
	"offs": 0, "ons": 0, "foot_m": 0.0, "tour_m": 0.0, "stuck_at": []}

var _obs: Node3D
var _gardens: Node
var _camera: Camera3D
var _views: Node
var _move: Node
var _paused: Array[Node] = []
var _camera_paused := false
var _back := Transform3D()
var _back_look := Vector2.ZERO  # the camera's yaw and pitch
var _from_roof := false
var _p := Vector2.ZERO          # (x, z)
var _y := 0.0                   # the ground under the scooter
var _heading := PI              # as the camera's yaw: 0 faces -Z
var _v := 0.0
var _turn := 0.0                # rad/s asked for with A or D, eased
var _lean := 0.0
var _roll := 0.0
var _slope := 0.0
var _spin := Vector2.ZERO       # the left and the right wheel's angles
var _last := Vector3.INF        # where this node left the camera
var _model: Node3D
var _wheels: Array[Node3D] = []
var _kmh := -1
var _frame := 0
# The autopilot.
var _tour := PackedVector2Array()   # TOUR with its corners rounded, every metre or so
var _tour_at := PackedFloat32Array()  # each point's distance along the tour
var _tour_len := 0.0
var _tour_cells := {}           # Vector2i -> [segment indices] in TOUR_CELL squares
var _s := 0.0                   # where on the tour
var _join := PackedVector2Array()   # the way to the tour first, if any
var _join_i := 0
var _join_s := 0.0              # where the way joins the tour
var _join_trail := false        # the way is the trail back, followed closely
var _trail := PackedVector2Array()  # where the scooter went by hand since it left the tour, every metre
var _trail_s := -1.0            # where on the tour the trail starts; -1: not from the tour
var _idle := 0.0
var _looked := 99.0             # s since the view was last turned by hand
var _set_look := Vector2(NAN, NAN)  # the yaw and pitch this node last gave the camera
var _progress := 0.0            # s with no progress on the autopilot's way
var _best := INF                # the nearest the scooter came to its next point
var _stuck := 0                 # new ways tried with no progress since
var _stuck_mark := 0.0          # stats.tour_m at the last new way
var _mark_s := 0.0              # where on the tour the last metre of progress was
# On foot.
var _foot := Vector2.ZERO
var _foot_y := 0.0
var _foot_v := Vector2.ZERO
var _say := ""                  # a line in the hint for a few seconds
var _say_left := 0.0
# The ride's views drawn once (WARM_POSES).
var _warm := {}                 # its viewport, camera, next pose and frame, while it runs
var _warmed := false
var _warm_pending := false      # mounted, but the quality was measuring (WARM_AFTER_CHANGE_S)
var _warm_native := false       # --warm-ride


func configure(observatory: Node3D, gardens: Node) -> void:
	_obs = observatory
	_gardens = gardens


func _ready() -> void:
	# Ahead of every other mover after the camera (0): the walking body (100, stopped while riding), the
	# roof view and Upperside (870), the flights (880) and the gardens (900) see where the rider is.
	process_priority = 10
	_camera = _obs.get_node_or_null("FlyCamera") as Camera3D
	_views = _obs.get_node_or_null("ExtraViews")
	_move = _obs.get_node_or_null("ViewMove")
	var args := OS.get_cmdline_user_args()
	reduced_motion = args.has("--reduced-motion")
	autopilot = not args.has("--no-autopilot")
	_warm_native = args.has("--warm-ride")
	var start := args.has("--segway")
	if OS.has_feature("web"):
		var q := "new URLSearchParams(location.search)"
		reduced_motion = reduced_motion or str(JavaScriptBridge.eval(q + ".get('motion') || ''", true)) == "reduce" \
			or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))
		start = start or str(JavaScriptBridge.eval(q + ".get('segway') || ''", true)) == "1"
	_tour = tour_points()
	_tour_at.resize(_tour.size() + 1)
	_tour_at[0] = 0.0
	for i in _tour.size():
		_tour_at[i + 1] = _tour_at[i] + _tour[i].distance_to(_tour[(i + 1) % _tour.size()])
	_tour_len = _tour_at[_tour.size()]
	for i in _tour.size():
		var a := _tour[i]
		var b := _tour[(i + 1) % _tour.size()]
		for cx in range(floori(minf(a.x, b.x) / TOUR_CELL), floori(maxf(a.x, b.x) / TOUR_CELL) + 1):
			for cz in range(floori(minf(a.y, b.y) / TOUR_CELL), floori(maxf(a.y, b.y) / TOUR_CELL) + 1):
				var k := Vector2i(cx, cz)
				if not _tour_cells.has(k):
					_tour_cells[k] = []
				(_tour_cells[k] as Array).append(i)
	_build()
	if start:
		_mount_at_start.call_deferred()


## TOUR with each corner rounded (a quadratic curve over at most FILLET's reach, and no more than 45 %
## of either side), then cut every metre or so.
static func tour_points() -> PackedVector2Array:
	var pts := PackedVector2Array(TOUR)
	var n := pts.size()
	var curved := PackedVector2Array()
	for i in n:
		var a := pts[(i - 1 + n) % n]
		var b := pts[i]
		var c := pts[(i + 1) % n]
		var d1 := (b - a).normalized()
		var d2 := (c - b).normalized()
		var bend := absf(d1.angle_to(d2))
		if bend < 0.05:
			curved.append(b)
			continue
		var t := minf(FILLET * tan(bend * 0.5), 0.45 * minf(a.distance_to(b), b.distance_to(c)))
		var p0 := b - d1 * t
		var p2 := b + d2 * t
		var k := maxi(3, ceili(bend * 6.0))
		for j in k + 1:
			var u := float(j) / k
			curved.append(p0.lerp(b, u).lerp(b.lerp(p2, u), u))
	var out := PackedVector2Array()
	var m := curved.size()
	for i in m:
		var a := curved[i]
		var b := curved[(i + 1) % m]
		var cuts := maxi(1, ceili(a.distance_to(b)))
		for j in cuts:
			out.append(a.lerp(b, float(j) / cuts))
	return out


func _mount_at_start() -> void:
	await get_tree().create_timer(0.5).timeout
	mount()


## Gets on the scooter on the terrace; false when it cannot be ridden now (no camera, in the corridor,
## the catalogue open, a film playing). In the gardens on foot, see get_on().
func mount() -> bool:
	if riding or on_foot or not _can_ride():
		return false
	_from_roof = _views != null and bool(_views.get("on_roof"))
	if _from_roof:
		_views.call("_leave_roof", false)
	_back = _camera.global_transform
	_back_look = Vector2(float(_camera.get("_yaw")), float(_camera.get("_pitch")))
	_pause()
	_p = MOUNT
	_y = float(_gardens.call("ground_at", _p))
	_heading = PI
	_v = 0.0
	_turn = 0.0
	_lean = 0.0
	_roll = 0.0
	_look(_heading, -0.12)
	_cut()
	riding = true
	stats.rides += 1
	_model.visible = true
	_set_trail()
	_place(0.0)
	if not _warmed:
		_warm_pending = true
		_warm_try()
	_publish()
	return true


## Starts the warm-up if it is wanted and the quality is not measuring; the scooter stands then.
func _warm_try() -> void:
	if not _warm_pending or not riding or auto or absf(_v) > 0.05:
		return
	if DisplayServer.get_name() == "headless" or not (OS.has_feature("web") or _warm_native):
		_warm_pending = false
		_warmed = true
		return
	var q := _obs.get_node_or_null("Quality")
	if q != null and bool(q.get("_auto")):
		var since := float(Time.get_ticks_usec() - int(q.get("_changed_us"))) / 1e6
		if not bool(q.get("_measured")) or int(q.get("_early_from")) >= 0 or since < WARM_AFTER_CHANGE_S:
			stats.warm_deferred = int(stats.get("warm_deferred", 0)) + 1
			return
	_warm_pending = false
	if q != null and int(q.get("level")) > WARM_MAX_LEVEL:
		_warmed = true
		stats.warm_skipped_level = int(q.get("level"))
		return
	_warm_start()


## The ride's views, from WARM_POSES: a viewport and its camera, drawn from _warm_step.
func _warm_start() -> void:
	_warmed = true
	var vp := _camera.get_viewport()
	var view := SubViewport.new()
	view.size = WARM_SIZE
	view.msaa_3d = vp.msaa_3d
	view.screen_space_aa = vp.screen_space_aa
	view.scaling_3d_mode = vp.scaling_3d_mode
	view.scaling_3d_scale = vp.scaling_3d_scale
	view.use_hdr_2d = vp.use_hdr_2d
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(view)
	var cam := Camera3D.new()
	cam.fov = _camera.fov
	cam.near = _camera.near
	cam.far = _camera.far
	cam.cull_mask = _camera.cull_mask
	cam.environment = _camera.environment
	cam.attributes = _camera.attributes
	view.add_child(cam)
	cam.current = true
	_warm = {"view": view, "camera": cam, "i": 0, "frame": 0, "t0": Time.get_ticks_msec()}
	stats.warm_poses = 0


## One pose of the warm-up every WARM_EVERY frames; gone when the last is drawn, or when the ride ends
## first (the next mount warms up again).
func _warm_step() -> void:
	var view := _warm.view as SubViewport
	var done := int(_warm.i) >= WARM_POSES.size()
	if done or (not riding and not on_foot):
		if done:
			stats.warm_ms = Time.get_ticks_msec() - int(_warm.t0)
		else:
			_warmed = false
		view.queue_free()
		_warm = {}
		_publish()
		return
	_warm.frame = int(_warm.frame) + 1
	if int(_warm.frame) % WARM_EVERY != 1:
		return
	var pose: Array = WARM_POSES[int(_warm.i)]
	var eye: Vector2 = pose[0]
	var at: Vector2 = pose[1]
	var from := Vector3(eye.x, float(_gardens.call("ground_at", eye)) + DECK + EYE, eye.y)
	var to := Vector3(at.x, float(_gardens.call("ground_at", at)) + 1.0, at.y)
	(_warm.camera as Camera3D).look_at_from_position(from, to, Vector3.UP)
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	_warm.i = int(_warm.i) + 1
	stats.warm_poses = int(_warm.i)


## Leaves the gardens: back where the visitor stood when they got on, the scooter back to the terrace.
func dismount() -> void:
	if not riding and not on_foot:
		return
	_end()
	_cut()
	if _from_roof and _views != null:
		_views.call("go", "roof")
	else:
		_camera.global_transform = _back
		_camera.set("_yaw", _back_look.x)
		_camera.set("_pitch", _back_look.y)
	_publish()


## Out of the hall on foot through a bay's open doors (walk_physics.gd, when palace_gardens.gd bay_out):
## on the terrace at `at`, going on at `vel`, the scooter parked at MOUNT for G. Back in through the
## doors, the walking body takes the visitor on (_walk_in).
func walk_out(at: Vector2, vel := Vector2.ZERO) -> bool:
	if riding or on_foot or not _can_ride():
		return false
	_from_roof = false
	_back = _camera.global_transform
	_back_look = Vector2(float(_camera.get("_yaw")), float(_camera.get("_pitch")))
	_pause()
	_p = MOUNT
	_y = float(_gardens.call("ground_at", _p))
	_heading = PI
	_v = 0.0
	_turn = 0.0
	_lean = 0.0
	_roll = 0.0
	auto = false
	on_foot = true
	_foot = at
	_foot_y = float(_gardens.call("ground_at", at))
	_foot_v = vel
	stats.walk_outs = int(stats.get("walk_outs", 0)) + 1
	_model.visible = true
	_place_model(0.0)
	_place_foot()
	_kmh = -1
	_hint()
	_publish()
	return true


## Back into the hall past a bay's glass: the walking body takes the visitor on from where they stand.
func _walk_in() -> void:
	stats.walk_ins = int(stats.get("walk_ins", 0)) + 1
	_end()
	_publish()


## Gets off beside the scooter, which stays where it is.
func get_off() -> bool:
	if not riding:
		return false
	var dir := Vector2(-sin(_heading), -cos(_heading))
	var right := Vector2(cos(_heading), -sin(_heading))
	var at := _p
	for c: Vector2 in [_p + right * 0.9, _p - right * 0.9, _p - dir * 1.0, _p + dir * 1.0]:
		var q := _foot_push(c, _y, false)
		if q.distance_to(c) < 0.05 and absf(float(_gardens.call("ground_at", q)) - _y) <= STEP:
			at = q
			break
	riding = false
	auto = false
	on_foot = true
	_v = 0.0
	_turn = 0.0
	_lean = 0.0
	_roll = 0.0
	_foot = at
	_foot_y = float(_gardens.call("ground_at", at))
	_foot_v = Vector2.ZERO
	stats.offs += 1
	_cut()
	_place_model(0.0)
	_place_foot()
	_kmh = -1
	_hint()
	_publish()
	return true


## On foot within REACH of the scooter, gets back on; false further.
func get_on() -> bool:
	if not on_foot:
		return false
	var d := _foot.distance_to(_p)
	if d > REACH:
		_tell("The scooter is %d m away: G beside it" % roundi(d))
		return false
	on_foot = false
	riding = true
	_v = 0.0
	_idle = 0.0
	stats.ons += 1
	_look(float(_camera.get("_yaw")), float(_camera.get("_pitch")))
	_cut()
	_place(0.0)
	_hint()
	_publish()
	return true


## Puts the rider at p (x, z), facing heading, for probes and captures.
func ride_to(p: Vector2, heading: float) -> void:
	if on_foot:
		_foot = _p
		get_on()
	if not riding and not mount():
		return
	_p = p
	_y = float(_gardens.call("ground_at", _p))
	_heading = heading
	_v = 0.0
	auto = false
	_idle = 0.0
	_look(heading, float(_camera.get("_pitch")))
	_set_trail()
	_cut()
	_place(0.0)


func _can_ride() -> bool:
	if _camera == null or _gardens == null or not bool(_gardens.get("enabled")) or _model == null:
		return false
	var mv := _obs.get_node_or_null("Multiverse")
	if mv != null and bool(mv.get("inside")):
		return false
	var lib := _obs.get_node_or_null("Generated/CourseShelves")
	if lib != null and lib.has_method("is_catalogue_open") and bool(lib.call("is_catalogue_open")):
		return false
	var film := _obs.get_node_or_null("Cinematic")
	return film == null or not bool(film.get("playing"))


func _cut() -> void:
	if _move != null and _move.has_method("cut"):
		_move.call("cut")


## The walking body and the fly camera's own moves stop; the camera's look (its input) stays.
func _pause() -> void:
	_paused.clear()
	var walker := _obs.get_node_or_null("WalkBody")
	for n: Node in [walker, walker.get_node_or_null("Early") if walker != null else null]:
		if n != null and n.is_processing():
			n.set_process(false)
			n.set_process_input(false)
			n.set_process_unhandled_input(false)
			_paused.append(n)
	_camera_paused = _camera.is_processing()
	_camera.set_process(false)


## Out of the gardens, wherever the camera is: the paused nodes go on, the camera writes its own hint
## (the walking body then writes its fuller one), the scooter goes back to the terrace.
func _end() -> void:
	riding = false
	on_foot = false
	auto = false
	stats.ended += 1
	_model.visible = false
	for n in _paused:
		if is_instance_valid(n):
			n.set_process(true)
			n.set_process_input(true)
			n.set_process_unhandled_input(true)
	_paused.clear()
	if _camera_paused and is_instance_valid(_camera):
		_camera.set_process(true)
	_camera_paused = false
	_kmh = -1
	_say_left = 0.0
	if _camera != null and _camera.has_method("_update_hud"):
		_camera.call("_update_hud")


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code == KEY_G:
		if riding:
			get_off()
		elif on_foot:
			get_on()
		else:
			mount()
		get_viewport().set_input_as_handled()
	elif (riding or on_foot) and code == KEY_F:
		get_viewport().set_input_as_handled()  # no free flight from the gardens


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	if not _warm.is_empty():
		_warm_step()
	elif _warm_pending:
		_warm_try()
	_run(delta)
	if riding or on_foot:
		stats.process_us = lerpf(float(stats.get("process_us", 0.0)), float(Time.get_ticks_usec() - t0), 0.05)


func _run(delta: float) -> void:
	_frame += 1
	if not riding and not on_foot:
		_hint()
		return
	if not is_instance_valid(_camera) or _camera.global_position.distance_to(_last) > 0.01:
		# A preset, the roof view, a test: the ride ends where that put the camera.
		_end()
		_publish()
		return
	var dt := minf(delta, 0.1)
	# A look round by hand: the mouse or a drag moved the view since this node last set it.
	var looked := absf(wrapf(float(_camera.get("_yaw")) - _set_look.x, -PI, PI)) > 1e-5 \
		or absf(float(_camera.get("_pitch")) - _set_look.y) > 1e-5
	_looked = 0.0 if looked else _looked + dt
	if _say_left > 0.0:
		_say_left -= dt
		if _say_left <= 0.0:
			_kmh = -1
	if on_foot:
		_walk(dt)
		if _frame % 10 == 0:
			_publish()
		return
	var ahead := _held(KEY_W) or _held(KEY_Z) or _held(KEY_UP)
	var back := _held(KEY_S) or _held(KEY_DOWN)
	var left := _held(KEY_A) or _held(KEY_Q) or _held(KEY_LEFT)
	var right := _held(KEY_D) or _held(KEY_RIGHT)
	var hands := ahead or back or left or right
	if hands:
		_idle = 0.0
		if auto:
			auto = false
			stats.takeovers += 1
			_set_trail()
	elif not auto:
		_idle = 0.0 if looked else _idle + dt
		if autopilot and _idle >= AUTO_AFTER and _warm.is_empty():
			_start_auto()
	var v0 := _v
	var h0 := _heading
	var yaw := float(_camera.get("_yaw"))
	var dir: Vector2
	if auto:
		var want := _auto_steer(dt)
		var ease := 1.0 - exp(-4.0 * dt)
		var turn := clampf(wrapf(want.x - _heading, -PI, PI) * 4.0, -AUTO_TURN, AUTO_TURN)
		_turn = lerpf(_turn, turn, ease * 2.0)
		_heading = wrapf(_heading + _turn * dt, -PI, PI)
		_v = move_toward(_v, want.y, (ACCEL if want.y > _v else BRAKE) * dt)
		# The view turns with the scooter, and back ahead once the hands have left it a while.
		yaw += wrapf(_heading - h0, -PI, PI)
		if _looked > LOOK_HOLD:
			yaw += wrapf(_heading - yaw, -PI, PI) * (1.0 - exp(-1.5 * dt))
			_camera.set("_pitch", lerpf(float(_camera.get("_pitch")), AUTO_PITCH, 1.0 - exp(-1.5 * dt)))
	else:
		var top := SPEED * (FAST if _held(KEY_SHIFT) else 1.0)
		if ahead and not back:
			_v = move_toward(_v, top, (ACCEL if _v >= 0.0 else BRAKE) * dt)
		elif back and not ahead:
			_v = move_toward(_v, -BACK, (BRAKE if _v > 0.0 else ACCEL) * dt)
		else:
			_v = move_toward(_v, 0.0, COAST * dt)
		# Turning: the keys turn the scooter and the view together; moving, the scooter turns to the view.
		var want := (TURN if left else 0.0) - (TURN if right else 0.0)
		_turn = lerpf(_turn, want, 1.0 - exp(-8.0 * dt))
		yaw += _turn * dt
		_heading += _turn * dt
		var off := wrapf(yaw - _heading, -PI, PI)
		if absf(_v) > 0.2 and absf(off) < LOOK_BACK:
			_heading += off * (1.0 - exp(-FOLLOW * minf(absf(_v) / 2.0, 1.0) * dt))
		_heading = wrapf(_heading, -PI, PI)
	var rate := wrapf(_heading - h0, -PI, PI) / dt
	# Forward in steps no longer than SUB, each stopped or turned aside by what stands there.
	dir = Vector2(-sin(_heading), -cos(_heading))
	var start := _p
	var go := _v * dt
	var n := maxi(1, ceili(absf(go) / SUB))
	for i in n:
		if not _step(_p + dir * (go / n)):
			break
	var along := (_p - start).dot(dir)
	if absf(go) > 1e-5 and along * signf(go) < absf(go) * 0.9:
		_v = signf(go) * maxf(along * signf(go), 0.0) / dt
		stats.blocked += 1
	var moved := start.distance_to(_p)
	stats.metres = float(stats.metres) + moved
	if auto:
		stats.auto_m = float(stats.auto_m) + moved
	else:
		_grow_trail()
	var accel := (_v - v0) / dt
	var lean_to := 0.0 if reduced_motion else clampf(accel * LEAN, -LEAN_MAX, LEAN_MAX)
	var roll_to := 0.0 if reduced_motion else clampf(rate * _v * ROLL, -ROLL_MAX, ROLL_MAX)
	_lean = lerpf(_lean, lean_to, 1.0 - exp(-6.0 * dt))
	_roll = lerpf(_roll, roll_to, 1.0 - exp(-6.0 * dt))
	_camera.set("_yaw", yaw)
	_spin.x -= (_v - rate * TRACK) / WHEEL_R * dt
	_spin.y -= (_v + rate * TRACK) / WHEEL_R * dt
	_place(dt)
	var kmh := roundi(absf(_v) * 3.6)
	if kmh != _kmh or _frame % 30 == 0:
		_kmh = kmh
		_hint()
	if _frame % 10 == 0:
		_publish()


# --- The autopilot ---------------------------------------------------------------------------------

## The tour's point at s metres along it.
func _tour_point(s: float) -> Vector2:
	s = fposmod(s, _tour_len)
	var lo := 0
	var hi := _tour.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if _tour_at[mid] <= s:
			lo = mid
		else:
			hi = mid - 1
	var a := _tour[lo]
	var b := _tour[(lo + 1) % _tour.size()]
	var span := _tour_at[lo + 1] - _tour_at[lo]
	return a.lerp(b, (s - _tour_at[lo]) / span if span > 1e-6 else 0.0)


## The nearest place on the tour to p, within TOUR_CELL or so: [distance along, distance off]; off is
## INF further.
func _tour_near(p: Vector2) -> Vector2:
	var best := Vector2(0.0, INF)
	var cell := Vector2i(floori(p.x / TOUR_CELL), floori(p.y / TOUR_CELL))
	var seen := {}
	for cx in range(cell.x - 1, cell.x + 2):
		for cz in range(cell.y - 1, cell.y + 2):
			for i: int in _tour_cells.get(Vector2i(cx, cz), []):
				if seen.has(i):
					continue
				seen[i] = true
				best = _nearer(p, i, best)
	return best


## As _tour_near, along the tour from `from` for `ahead` metres.
func _tour_near_ahead(p: Vector2, from: float, ahead: float) -> Vector2:
	var best := Vector2(0.0, INF)
	var i0 := _tour_index(from)
	for k in mini(_tour.size(), ceili(ahead) + 2):
		best = _nearer(p, (i0 + k) % _tour.size(), best)
	return best


func _nearer(p: Vector2, i: int, best: Vector2) -> Vector2:
	var a := _tour[i]
	var ab := _tour[(i + 1) % _tour.size()] - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	var d := p.distance_to(a + ab * t)
	return Vector2(_tour_at[i] + t * (_tour_at[i + 1] - _tour_at[i]), d) if d < best.y else best


func _tour_index(s: float) -> int:
	s = fposmod(s, _tour_len)
	var lo := 0
	var hi := _tour.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if _tour_at[mid] <= s:
			lo = mid
		else:
			hi = mid - 1
	return lo


## The trail starts here: on the tour if near it, else nowhere the autopilot knows.
func _set_trail() -> void:
	_trail = PackedVector2Array([_p])
	var near := _tour_near(_p)
	_trail_s = near.x if near.y < 1.5 else -1.0


## Riding by hand: a point every metre; a loop ridden is cut out; back on the tour, the trail starts over.
func _grow_trail() -> void:
	if _trail.is_empty():
		_set_trail()
		return
	if _p.distance_to(_trail[_trail.size() - 1]) < 1.0:
		return
	var near := _tour_near(_p)
	if near.y < 1.2:
		_trail = PackedVector2Array([_p])
		_trail_s = near.x
		return
	for i in _trail.size() - 3:
		if _trail[i].distance_to(_p) < 1.0:
			_trail.resize(i + 1)
			break
	if _trail.size() < 5000:
		_trail.append(_p)


## Nothing stands on the straight line from a to b for the scooter, and its ground never steps more
## than STEP. People count: the line is tried again later.
func _clear(a: Vector2, b: Vector2) -> bool:
	var n := maxi(1, ceili(a.distance_to(b) / 0.5))
	var y := float(_gardens.call("ground_at", a))
	for k in range(1, n + 1):
		var p := a.lerp(b, float(k) / n)
		var gy := float(_gardens.call("ground_at", p))
		if absf(gy - y) > STEP:
			return false
		y = gy
		var q: Vector2 = _gardens.call("push_out", p, RADIUS + 0.1, gy)
		if q.distance_to(p) > 0.02:
			return false
	return true


## The tour's nearest points in a straight line from p, nearest first, up to `tries` of them, each 4 m
## apart along the tour: the first one clear, as [distance along, 1], or [0, -1].
func _straight_join(p: Vector2, tries: int) -> Vector2:
	var cands := []
	var last := -INF
	for i in _tour.size():
		var d := _tour[i].distance_to(p)
		if d < JOIN_R:
			cands.append(Vector2(d, _tour_at[i]))
	cands.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var tried := []
	for c: Vector2 in cands:
		var far := true
		for t: float in tried:
			if absf(wrapf(c.y - t, -_tour_len * 0.5, _tour_len * 0.5)) < 4.0:
				far = false
				break
		if not far:
			continue
		tried.append(c.y)
		# A little ahead of the nearest point, so as not to turn back to it.
		var s := c.y + 2.0
		if _clear(p, _tour_point(s)):
			return Vector2(s, 1.0)
		if tried.size() >= tries:
			break
	return Vector2(0.0, -1.0)


## The way to the tour: straight when clear, else back along the trail to where it left the tour.
func _start_auto() -> void:
	_idle = 0.0
	_progress = 0.0
	_best = INF
	_stuck = 0
	_stuck_mark = float(stats.tour_m)
	var near := _tour_near(_p)
	if near.y < 1.5:
		_join = PackedVector2Array()
		_s = near.x
		_mark_s = _s
		auto = true
		stats.auto_starts += 1
		return
	var straight := _straight_join(_p, 6)
	if straight.y > 0.0:
		_join = PackedVector2Array([_tour_point(straight.x)])
		_join_s = straight.x
		_join_trail = false
		stats.joins_straight += 1
	elif _trail_s >= 0.0 and _trail.size() > 0:
		_join = PackedVector2Array()
		for i in range(_trail.size() - 1, -1, -1):
			if _trail[i].distance_to(_p) > 1.0 or not _join.is_empty():
				_join.append(_trail[i])
		_join.append(_tour_point(_trail_s))
		_join_s = _trail_s
		_join_trail = true
		stats.joins_back += 1
	else:
		stats.lost += 1
		_tell("Autopilot: no way back to the tour from here")
		_idle = -10.0  # tries again later
		return
	_join_i = 0
	auto = true
	stats.auto_starts += 1


## Where to go: [heading, speed].
func _auto_steer(dt: float) -> Vector2:
	var look := AUTO_LOOK + absf(_v) * 0.4
	var target: Vector2
	var corner := 0.0
	if _join_i < _join.size():
		# The way to the tour: point after point, a straight line skipping ahead when clear, now and then.
		# The trail back is followed closely: aiming further cut its corners into the maze's hedges and
		# the door's jambs (artpass/gardens/ride2/auto-headless2).
		var reach := 0.7 if _join_trail else maxf(1.2, look * 0.6)
		while _join_i < _join.size() - 1 and _p.distance_to(_join[_join_i]) < reach:
			_join_i += 1
			_best = INF
		if _frame % 45 == 0 and _join.size() - _join_i > 2:
			var straight := _straight_join(_p, 1)
			if straight.y > 0.0:
				_join = PackedVector2Array([_tour_point(straight.x)])
				_join_s = straight.x
				_join_i = 0
				_join_trail = false
		target = _join[_join_i]
		var d := _p.distance_to(target)
		if _join_i == _join.size() - 1 and d < 1.5:
			_join = PackedVector2Array()
			_s = _join_s
			_mark_s = _s
		_progress = 0.0 if d < _best - 0.2 else _progress + dt
		_best = minf(_best, d)
		corner = absf(wrapf(_heading_to(target) - _heading, -PI, PI))
	if _join_i >= _join.size():
		var near := _tour_near_ahead(_p, _s - 2.0, 14.0)
		var gained := wrapf(near.x - _s, -_tour_len * 0.5, _tour_len * 0.5)
		# Progress: a metre along the tour since the last mark (slow behind people is progress).
		if wrapf(_s + maxf(gained, 0.0) - _mark_s, -_tour_len * 0.5, _tour_len * 0.5) > 1.0:
			_mark_s = _s + maxf(gained, 0.0)
			_progress = 0.0
		else:
			_progress += dt
		if gained > 0.0:
			stats.tour_m = float(stats.tour_m) + gained
			_s = fposmod(near.x, _tour_len)
		target = _tour_point(_s + look)
		# Slower before a bend: how far the way turns over the next 6 m.
		var ahead := _tour_point(_s + look + 6.0)
		corner = maxf(absf(wrapf(_heading_to(target) - _heading, -PI, PI)),
			absf((target - _p).angle_to(ahead - target)) * 0.6)
	var speed := AUTO_SPEED * clampf(1.15 - corner, 0.25, 1.0)
	if _join_trail and _join_i < _join.size():
		speed = minf(speed, 1.6)
	if absf(wrapf(_heading_to(target) - _heading, -PI, PI)) > 1.0:
		speed = 0.0  # turns on the spot first
	# People close ahead: slower, and round them.
	var crowd := _gardens.get("_crowd") as Node
	if crowd != null and crowd.has_method("near") and (crowd as Node3D).is_visible_in_tree():
		var dir := Vector2(-sin(_heading), -cos(_heading))
		for q: Vector2 in crowd.call("near", _p, 7.0):
			var rel := q - _p
			var fwd := rel.dot(dir)
			# In the scooter's way: closer to its line than the two of them are wide, and a margin.
			if fwd > 0.0 and absf(rel.cross(dir)) < 1.0:
				speed = minf(speed, maxf(AUTO_SLOW * 0.5, minf(AUTO_SLOW, (fwd - 1.0) * 0.6)))
	# Stuck (people, a corner): a straight way to the tour, else the next point; at last the hands' turn.
	if float(stats.tour_m) - _stuck_mark > 5.0:
		_stuck = 0
	if _progress > 5.0:
		if (stats.stuck_at as Array).size() < 12:
			(stats.stuck_at as Array).append([snappedf(_p.x, 0.1), snappedf(_p.y, 0.1), snappedf(target.x, 0.1),
				snappedf(target.y, 0.1), _join_i, _join.size()])
		stats.replans += 1
		_progress = 0.0
		_best = INF
		_stuck += 1
		_stuck_mark = float(stats.tour_m)
		if _stuck > 3:
			auto = false
			stats.lost += 1
			_idle = -10.0
			_set_trail()
			_tell("Autopilot: stuck here; the keys ride")
			return Vector2(_heading, 0.0)
		var straight := _straight_join(_p, 6)
		if straight.y > 0.0:
			_join = PackedVector2Array([_tour_point(straight.x)])
			_join_s = straight.x
			_join_i = 0
			_join_trail = false
		elif _join_i < _join.size() - 1:
			_join_i += 1
		elif _join.is_empty():
			_s += 3.0
			_mark_s = _s
	return Vector2(_heading_to(target), speed)


func _heading_to(p: Vector2) -> float:
	var d := p - _p
	return atan2(-d.x, -d.y) if d.length_squared() > 1e-8 else _heading


# --- On foot ---------------------------------------------------------------------------------------

## Where a visitor of FOOT_RADIUS at p ends, pushed out of what stands round them and, unless
## `scooter` is false, the parked scooter. On foot, a bay's open doorway lets them through the wall.
func _foot_push(p: Vector2, y: float, scooter := true) -> Vector2:
	var q: Vector2 = _gardens.call("push_out", p, FOOT_RADIUS, y, true)
	if scooter:
		var d := q - _p
		var reach := SCOOTER_R + FOOT_RADIUS
		if d.length_squared() < reach * reach:
			q = _p + (d.normalized() if d.length_squared() > 1e-8 else Vector2.RIGHT) * reach
	return q


func _walk(dt: float) -> void:
	var yaw := float(_camera.get("_yaw"))
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var side := Vector2(cos(yaw), -sin(yaw))
	var want := Vector2.ZERO
	if _held(KEY_W) or _held(KEY_Z) or _held(KEY_UP):
		want += fwd
	if _held(KEY_S) or _held(KEY_DOWN):
		want -= fwd
	if _held(KEY_A) or _held(KEY_Q) or _held(KEY_LEFT):
		want -= side
	if _held(KEY_D) or _held(KEY_RIGHT):
		want += side
	var speed := maxf(float(_camera.get("move_speed")), 0.5) * (FOOT_SPRINT if _held(KEY_SHIFT) else 1.0)
	_foot_v = _foot_v.move_toward(want.normalized() * speed, 30.0 * dt)
	var go := _foot_v * dt
	var start := _foot
	var n := maxi(1, ceili(go.length() / SUB))
	for i in n:
		var to := _foot + go / n
		var moved := false
		for c: Vector2 in [to, Vector2(to.x, _foot.y), Vector2(_foot.x, to.y)]:
			var q := _foot_push(c, _foot_y)
			var gy := float(_gardens.call("ground_at", q))
			if absf(gy - _foot_y) <= STEP and q.distance_squared_to(_foot) > 1e-8:
				_foot = q
				_foot_y = gy
				moved = true
				break
		if not moved:
			_foot_v = Vector2.ZERO
			break
	stats.foot_m = float(stats.foot_m) + start.distance_to(_foot)
	_place_foot()
	if bool(_gardens.call("bay_in", _foot)):
		_walk_in()
		return
	var d := roundi(_foot.distance_to(_p))
	if d != _kmh or _frame % 30 == 0:
		_kmh = d
		_hint()


func _place_foot() -> void:
	_camera.global_position = Vector3(_foot.x, _foot_y + float(_camera.get("walking_eye_height")), _foot.y)
	_camera.rotation = Vector3(float(_camera.get("_pitch")), float(_camera.get("_yaw")), 0.0)
	_last = _camera.global_position
	_set_look = Vector2(float(_camera.get("_yaw")), float(_camera.get("_pitch")))


# --- Moving, placing, the scooter ------------------------------------------------------------------

## One step to `to`, pushed out of what stands there, onto ground no more than STEP above or below;
## failing that, along x alone or along z alone. False when it cannot move.
func _step(to: Vector2) -> bool:
	for c: Vector2 in [to, Vector2(to.x, _p.y), Vector2(_p.x, to.y)]:
		var q: Vector2 = _gardens.call("push_out", c, RADIUS, _y)
		var gy := float(_gardens.call("ground_at", q))
		if absf(gy - _y) <= STEP and q.distance_squared_to(_p) > 1e-8:
			_p = q
			_y = gy
			return true
	return false


func _look(yaw: float, pitch: float) -> void:
	_camera.set("_yaw", yaw)
	_camera.set("_pitch", pitch)


## The scooter on the ground, tilted with its slope; riding, the camera above its platform, leaning.
func _place(dt: float) -> void:
	_place_model(dt)
	_camera.global_position = Vector3(_p.x, _y + DECK + EYE, _p.y)
	_camera.rotation = Vector3(float(_camera.get("_pitch")) - _lean, float(_camera.get("_yaw")), _roll)
	_last = _camera.global_position
	_set_look = Vector2(float(_camera.get("_yaw")), float(_camera.get("_pitch")))


func _place_model(dt: float) -> void:
	var dir := Vector2(-sin(_heading), -cos(_heading))
	var rise := float(_gardens.call("ground_at", _p + dir * 0.3)) - float(_gardens.call("ground_at", _p - dir * 0.3))
	var slope := clampf(atan2(rise, 0.6), -0.3, 0.3)
	_slope = slope if dt <= 0.0 else lerpf(_slope, slope, 1.0 - exp(-12.0 * dt))
	_model.global_transform = Transform3D(Basis(Vector3.UP, _heading) * Basis(Vector3.RIGHT, _slope), Vector3(_p.x, _y, _p.y))
	for i in _wheels.size():
		_wheels[i].rotation = Vector3(wrapf(_spin[i], -PI, PI), 0.0, 0.0)


func _build() -> void:
	_model = Node3D.new()
	_model.name = "Scooter"
	_model.visible = false
	add_child(_model)
	for part: String in PARTS:
		if not ResourceLoader.exists(KIT % part):
			return
	var g := _gardens
	# Anodised dark grey: bright aluminium came out beige under the terrace's warm lanterns
	# (artpass/gardens/ride1-fwd/handlebar).
	var metal: Material = g.call("_gmat", 0, Color(0.24, 0.255, 0.28), {"sheen": 0.9})
	var mats := {
		"body": g.call("_gmat", 0, Color(0.13, 0.14, 0.15), {"sheen": 0.35}),
		"metal": metal,
		"trim": g.call("_gmat", 0, Color(0.05, 0.05, 0.05), {"sheen": 0.05}),
		"light": g.call("_gmat", 5, Color.WHITE, {"lamp_colour": Color(0.8, 0.92, 1.0), "lamp_energy": 0.6}),
		"tyre": g.call("_gmat", 0, Color(0.045, 0.045, 0.045), {"sheen": 0.08}),
		"dish": g.call("_gmat", 0, Color(0.2, 0.21, 0.22), {"sheen": 0.3}),
		"spokes": metal,
	}
	for part: String in ["body", "metal", "trim", "light"]:
		_part(_model, part, mats[part])
	for sx: float in [-1.0, 1.0]:
		var wheel := Node3D.new()
		wheel.name = "WheelL" if sx < 0.0 else "WheelR"
		wheel.position = Vector3(sx * TRACK, WHEEL_R, 0.0)
		_model.add_child(wheel)
		for part: String in ["tyre", "dish", "spokes"]:
			_part(wheel, part, mats[part])
		_wheels.append(wheel)
	# The headlamp's light on the ground ahead, added over it (assets/palace_glow.gdshader).
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	var pool := MeshInstance3D.new()
	pool.name = "Headlight"
	pool.mesh = plane
	# At 0.22, 3.6 m ahead, it was a white blot at the foot of the view (artpass/gardens/ride1-fwd).
	pool.material_override = g.call("_glow", Color(0.85, 0.9, 0.95), 0.09, {"fade_top": 0.6, "fade_foot": 0.45, "edge": 1.0})
	pool.transform = Transform3D(Basis.from_scale(Vector3(3.2, 1.0, 8.0)), Vector3(0.0, 0.05, -5.5))
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_model.add_child(pool)
	stats.kit = true


func _part(parent: Node3D, part: String, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = part.capitalize()
	mi.mesh = load(KIT % part)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)


## A line in the hint for a few seconds.
func _tell(text: String) -> void:
	_say = text
	_say_left = 3.0
	_kmh = -1
	_hint()


## The controls' hint: riding or on foot here, this node's; elsewhere, G added to the camera's and the
## walking body's (walk_physics.gd adds it to its own).
func _hint() -> void:
	var hint := _obs.get_node_or_null("ControlsHud/Panel/Hint") as Label
	var touch := _obs.get_node_or_null("TouchControls")
	if hint == null or (touch != null and bool(touch.get("_shown"))):
		return  # the touch controls write their own help, the ride's Ride button included
	var text := ""
	if riding:
		text = (HUD_AUTO if auto else HUD) % maxi(roundi(absf(_v) * 3.6), 0)
	elif on_foot:
		text = HUD_FOOT % roundi(_foot.distance_to(_p))
	elif hint.text.begins_with("FLY MODE") and not hint.text.contains(HINT):
		hint.text += "  ·  " + HINT
		return
	else:
		return
	if _say_left > 0.0:
		text = text.split("\n")[0] + "\n" + _say
	if hint.text != text:
		hint.text = text


## Web tests: the ride's state.
func _publish() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__obsSegway = %s" % JSON.stringify({"riding": riding, "on_foot": on_foot,
		"auto": auto, "p": [_p.x, _y, _p.y], "foot": [_foot.x, _foot_y, _foot.y], "v": _v, "heading": _heading,
		"rides": stats.rides, "metres": stats.metres, "auto_m": stats.auto_m, "tour_m": stats.tour_m,
		"foot_m": stats.foot_m, "offs": stats.offs, "ons": stats.ons, "takeovers": stats.takeovers,
		"warm_poses": stats.get("warm_poses", 0), "warm_ms": stats.get("warm_ms", -1),
		"warm_deferred": stats.get("warm_deferred", 0), "warm_skipped_level": stats.get("warm_skipped_level", -1)}), true)


static func _held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)
