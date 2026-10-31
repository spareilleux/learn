extends Node3D
## A ride in the palace gardens, made by scripts/palace_gardens.gd: first on a self-balancing scooter (the
## author, 2026-10-04: "on doit pouvoir se balader dans les jardins en Segway"), since 2026-10-15 on an
## electric kick scooter (« Tu remplaceras le Segway par une trottinette électrique qui autorise des mouvements
## plus fluides »; the node and this file keep their name, which the scene's other scripts and the tests call).
## G gets on, on the terrace before the ramp's head, facing down the garden; out over the gardens or the Place
## du Capitole (a view, the live view's pose), G rides and F walks from the ground under the camera (land).
## Riding (_drive):
##   - W, Z or the up arrow open the throttle, S or the down arrow brake, and at a stand walk the scooter
##     backwards; Shift rides faster, up to 25 km/h; with no key it glides. The acceleration changes at most
##     JERK a second: no jolt starting, braking or coming to a stand;
##   - A, Q or the left arrow and D or the right arrow turn the handlebar, and the view goes round with the
##     scooter; it turns as a bicycle does, about its rear wheel, the handlebar's lock narrowing with the
##     speed, so that a turn at speed is wide and smooth; at a stand they walk it round;
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
##   - the scooter and its rider lean into a turn as a bicycle does, the view's horizon with a share of it,
##     and the view dips a little speeding up and slowing down; not with --reduced-motion or the browser's
##     reduced-motion setting.
## G riding gets off beside the scooter, which stays where it is (the author: "on devrait pouvoir
## descendre et remonter sur le segway"); on foot, the same keys walk, stopped as the scooter is, and G
## gets back on: beside it, or from further than REACH, the scooter comes under the feet (get_on). A
## preset (keys 1 to 9), or anything else that moves the
## camera, ends the ride or the walk where it put the camera, and the scooter goes back to the terrace.
## The scooter is a kit made in Blender (artpass/gardens/blender/escooter_kit.py), generic, with no
## maker's name: its handlebar and display show looking down, the handlebar turns with the fork and the
## front wheel, its wheels turn as it rolls, its headlamp lights the ground ahead. While riding or walking here, the fly camera's own moves and the walking body
## stop, as the drone stops them (scripts/drone.gd); the camera's look and its presets stay.
## --segway (?segway=1) starts on the scooter. dismount() leaves the gardens, back where the visitor
## stood when they got on (on the roof view, if G was pressed there).

## The electric kick scooter (artpass/gardens/blender/escooter_kit.py; the author, 2026-10-15: « Tu remplaceras
## le Segway par une trottinette électrique qui autorise des mouvements plus fluides »): its frame, its steering
## (turned about the head tube's axis, the front wheel with it) and one wheel, drawn twice.
const KIT := "res://assets/garden_escooter_%s.obj"
const PARTS := ["body", "trim", "metal", "tail", "steer_metal", "steer_body", "steer_trim", "steer_light", "steer_screen", "tyre", "dish", "spokes"]
const SPEED := 5.6           # m/s, about 20 km/h
const FAST := 1.24           # times SPEED with Shift: 25 km/h, an electric scooter's legal top speed in France
const BACK := 0.9            # m/s: at a stand, S walks it backwards
const ACCEL := 2.2           # m/s² at full throttle from a stand, fading towards the top speed
const THROTTLE := 2.5        # per second: how fast the throttle and the brake open and close
const JERK := 8.0            # m/s³: the most the acceleration changes in a second (no jolt)
const BRAKE := 3.5           # m/s², the brake full on
const COAST := 0.35          # m/s², rolling with no key: it glides
const WHEELBASE := 0.98      # m, from axle to axle: the front wheel turns the scooter as a bicycle's does
const STEER_MAX := 0.55      # rad: the handlebar's lock at a walk
const STEER_FAST := 0.12     # rad: its lock at the top speed, so that a turn at speed is wide and smooth
const STEER_RATE := 1.6      # rad/s: the most the handlebar turns in a second
const A_LAT := 3.8           # m/s²: the most a turn pulls sideways; past it the handlebar holds
const PIVOT_TURN := 1.4      # rad/s: at a stand, A or D walk the scooter round (eased in and out at 6 rad/s²)
const FOLLOW := 2.6          # per second: how fast a moving scooter turns to where the view looks
const LOOK_BACK := 1.6       # radians: a view further round than this looks, and does not steer
const RADIUS := 0.4          # the rider on the scooter, against what stands round them
const FRONT := 0.5           # m: the front wheel ahead of the rider, kept out of what stands there too
const FRONT_R := 0.16
const STEP := 0.35           # m: a rise or a drop up to this, in one step, is ridden over
const SUB := 0.25            # m: the longest step, so that a slow frame cannot jump a hedge
const DECK := 0.165          # the deck above the ground (escooter_kit.py)
const EYE := 1.62            # the eye above the deck
const WHEEL_R := 0.127       # 10-inch tyres
const AXLE_FRONT := -0.52    # the axles' z on the scooter (it faces -Z), its origin under the rider
const AXLE_REAR := 0.46
const STEER_PIVOT := Vector3(0.0, 0.127, -0.52)   # the steering's axis: through the front axle,
const STEER_AXIS := Vector3(0.0, 0.9781, 0.2079)  # raked back 12 degrees
const MOUNT := Vector2(0.0, 21.0)  # (x, z): on the terrace, before the ramp's head
const LEAN := 0.012          # radians of pitch per m/s² of acceleration
const LEAN_MAX := 0.05
const ROLL_MAX := 0.28       # radians: the scooter and its rider leaning into a turn, as a bicycle does
const ROLL_VIEW := 0.4       # the share of that lean the view's horizon takes
const ROLL_EYE := 0.5        # and the eye's place: the body leans, the head stays nearer upright
const EYE_EASE := 12.0       # per second: the eye's height after the ground's
const HEADLAMP_AT := Vector3(0.0, 0.93, -0.42)  # the lamp's lens on the stem (escooter_kit.py lamp_at)
const HEADLAMP_DIP := 0.16   # radians below level: its beam meets the ground about 6 m ahead
const HEADLAMP_ENERGY := 2.0
const POOL_XF := Transform3D(Basis(Vector3(3.2, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, 8.0)), Vector3(0.0, 0.05, -5.5))
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
## On foot this near the scooter, it lights up (a golden ring on the ground round it, pulsing, its display and
## headlamp brighter) and a tag over it says the key: E or G gets on (the author, 2026-10-16: « j'ai extrêmement
## de mal à interagir avec les trottinettes. Donc, idéalement, quand on est à côté, il faudrait que, euh, genre,
## qu'elles s'illuminent et puis qu'on ait un petit, euh, petit truc à l'écran qui s'affiche pour pouvoir monter
## dessus »).
const BECKON_R := 4.0
const BECKON_TEXT := {"en": "Ride the scooter", "fr": "Monter sur la trottinette", "es": "Subir al patinete"}
const REACH := 2.5           # m from the scooter within which G gets back on where it stands; further, it comes
const FOOT_RADIUS := 0.3
const FOOT_SPRINT := 1.6
const SCOOTER_R := 0.3       # the parked scooter's deck, for the visitor on foot (its wheels: _foot_push)
const LAND_R := 6.0          # m: how far from under the camera the free ground to land on may be (land)
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
const HUD := "E-SCOOTER  |  W/Z: throttle  ·  S: brake, back at a stand  ·  A/Q, D: steer  ·  Shift: faster  ·  G: get off\nMouse: look and steer  ·  Hands off 3 s: autopilot  ·  Esc: release  ·  1–9: back inside  ·  %d km/h"
const HUD_AUTO := "E-SCOOTER, AUTOPILOT  |  a tour of the gardens  ·  W/Z, S, A/Q, D: take over  ·  G: get off\nMouse: look round  ·  Esc: release  ·  1–9: back inside  ·  %d km/h"
const HUD_FOOT := "ON FOOT IN THE GARDENS  |  WASD/ZQSD: walk  ·  Shift: faster  ·  G: ride (the scooter comes, %d m)\nClick: look  ·  Esc: release  ·  1–9: back inside"
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
var _turn := 0.0                # rad/s, the autopilot's turn, eased
var _thr := 0.0                 # the throttle, 0 to 1, eased
var _brk := 0.0                 # the brake, 0 to 1, eased
var _acc := 0.0                 # m/s², the acceleration, changing at most JERK a second
var _pivot := 0.0               # rad/s, the scooter walked round at a stand
var _steer := 0.0               # rad, the handlebar: left positive
var _lean := 0.0
var _roll := 0.0
var _slope := 0.0
var _eye_y := NAN               # the eye's height, eased after the ground's
var _spin := Vector2.ZERO       # the front and the rear wheel's angles
var _last := Vector3.INF        # where this node left the camera
var _model: Node3D
var _steering: Node3D           # the fork, the stem and the handlebar, with the front wheel
var _lamp: SpotLight3D          # natively, the headlamp's light
var _pool: MeshInstance3D       # on the web, its pool on the ground
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
# The scooter beckoning, on foot near it (BECKON_R).
var _beckon := 0.0              # 0 .. 1, eased
var _beckon_t := 0.0
var _ring: MeshInstance3D
var _ring_mat: ShaderMaterial
var _screen_mat: ShaderMaterial
var _light_mat: ShaderMaterial
var _tag: Control
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
	_steer = 0.0
	_y = float(_gardens.call("ground_at", _p))
	_heading = PI
	_v = 0.0
	_turn = 0.0
	_lean = 0.0
	_roll = 0.0
	_thr = 0.0
	_acc = 0.0
	_pivot = 0.0
	_brk = 0.0
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


## Where on the ground under the camera a visitor would stand, when the camera is out over the gardens or the
## Place du Capitole (a view, the live view's pose; the author, 2026-10-15: « On ne peut pas se promener dans la
## place du Capitole »: G took them back to the terrace, 360 m away, and F to the hall): past the hall's wall,
## neither in the library wing nor on the roof's view, above the ground, the free ground within LAND_R of the
## point under it (palace_gardens.gd push_out keeps it within RIDE_R or on the square). Vector2.INF elsewhere.
func spot_below() -> Vector2:
	if _camera == null or _gardens == null or _obs == null:
		return Vector2.INF
	if _views != null and bool(_views.get("on_roof")):
		return Vector2.INF
	var c := _camera.global_position
	var wing := _obs.get_node_or_null("LibraryWing")
	if wing != null and wing.has_method("contains") and bool(wing.call("contains", c)):
		return Vector2.INF
	var p := Vector2(c.x, c.z)
	if c.y < float(_gardens.call("ground_at", p)) + 0.5:
		return Vector2.INF
	return spot_at(p)


## Where a visitor would stand on the ground at p (x, z): past the hall's wall, not in the library wing, the free
## ground within LAND_R of p. Vector2.INF elsewhere. The telescope's jump aims with it too (scripts/teleport.gd).
func spot_at(p: Vector2) -> Vector2:
	if _gardens == null or _obs == null:
		return Vector2.INF
	if p.length() < float(_obs.get("outer_radius")) + 2.0:
		return Vector2.INF
	var y := float(_gardens.call("ground_at", p))
	var wing := _obs.get_node_or_null("LibraryWing")
	if wing != null and wing.has_method("contains") and bool(wing.call("contains", Vector3(p.x, y + 1.0, p.y))):
		return Vector2.INF
	var q: Vector2 = _gardens.call("push_out", p, FOOT_RADIUS, y, true)
	if q.distance_to(p) > LAND_R or absf(float(_gardens.call("ground_at", q)) - y) > STEP:
		return Vector2.INF
	return q


## G (`ride`) or F with the camera out over the gardens (spot_below): down on the ground under it, riding or
## on foot with the scooter parked beside, facing where the camera faced. dismount() takes the camera back up
## there. False where there is no such ground: G then gets on at MOUNT, and F is the camera's own.
func land(ride: bool) -> bool:
	if riding or on_foot:
		return false
	return land_at(spot_below(), ride)


## Down on the ground at q (spot_at's), riding or on foot with the scooter parked beside, facing `yaw` (the
## camera's when NAN). Already out, the visitor and the scooter are moved there, and dismount() still takes the
## camera back to where the outing began; else back to `back` (the camera's transform and look, by default where
## it is now), or to the roof's view (`from_roof`). The telescope's jump lands with it (scripts/teleport.gd).
func land_at(q: Vector2, ride: bool, yaw := NAN, from_roof := false, back := Transform3D(), back_look := Vector2.INF) -> bool:
	if q == Vector2.INF or not _can_ride():
		return false
	if not (riding or on_foot):
		_from_roof = from_roof
		_back = _camera.global_transform if back_look == Vector2.INF else back
		_back_look = Vector2(float(_camera.get("_yaw")), float(_camera.get("_pitch"))) if back_look == Vector2.INF else back_look
		_pause()
	riding = false
	on_foot = false
	if is_nan(yaw):
		yaw = float(_camera.get("_yaw"))
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	_y = float(_gardens.call("ground_at", q))
	_heading = yaw
	_v = 0.0
	_turn = 0.0
	_lean = 0.0
	_roll = 0.0
	_thr = 0.0
	_acc = 0.0
	_pivot = 0.0
	_brk = 0.0
	auto = false
	_look(yaw, clampf(float(_camera.get("_pitch")), -0.3, 0.15))
	_p = _gardens.call("push_out", q, RADIUS, _y)
	if not ride:
		for s: Vector2 in [q + right * 1.0, q - right * 1.0, q + fwd * 1.2, q - fwd * 1.2]:
			var at: Vector2 = _gardens.call("push_out", s, RADIUS, _y)
			if at.distance_to(s) < 0.05 and absf(float(_gardens.call("ground_at", at)) - _y) <= STEP:
				_p = at
				break
	_model.visible = true
	_set_trail()
	_cut()
	stats.lands = int(stats.get("lands", 0)) + 1
	if ride:
		riding = true
		stats.rides += 1
		_place(0.0)
		if not _warmed:
			_warm_pending = true
			_warm_try()
	else:
		on_foot = true
		_foot = q
		_foot_y = _y
		_foot_v = Vector2.ZERO
		_place_model(0.0)
		_place_foot()
	_kmh = -1
	_hint()
	_publish()
	return true


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
	_steer = 0.0
	_y = float(_gardens.call("ground_at", _p))
	_heading = PI
	_v = 0.0
	_turn = 0.0
	_lean = 0.0
	_roll = 0.0
	_thr = 0.0
	_acc = 0.0
	_pivot = 0.0
	_brk = 0.0
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
	_thr = 0.0
	_acc = 0.0
	_pivot = 0.0
	_brk = 0.0
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


## On foot, gets back on. Further than REACH from the scooter, the scooter comes under the visitor's feet
## (the author, 2026-10-16: « Embarquer dans la trottinette devrait être facile »; until then G was refused
## there, "The scooter is 11 m away: G beside it"), facing where they look, where the ground lets it stand:
## the rider's RADIUS clear, within a metre of the feet and STEP of their ground. False there only.
func get_on() -> bool:
	if not on_foot:
		return false
	var d := _foot.distance_to(_p)
	if d > REACH:
		var q: Vector2 = _gardens.call("push_out", _foot, RADIUS, _foot_y)
		var qy := float(_gardens.call("ground_at", q))
		if q.distance_to(_foot) > 1.0 or absf(qy - _foot_y) > STEP:
			_tell("No room for the scooter here: G a step away")
			return false
		_p = q
		_y = qy
		_heading = float(_camera.get("_yaw"))
		_steer = 0.0
		_set_trail()
		stats.called = int(stats.get("called", 0)) + 1
		_tell("The scooter came to you, from %d m" % roundi(d))
	on_foot = false
	riding = true
	_v = 0.0
	_thr = 0.0
	_acc = 0.0
	_pivot = 0.0
	_brk = 0.0
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
		elif not land(true):
			mount()
		get_viewport().set_input_as_handled()
	elif code == KEY_E and on_foot and _foot.distance_to(_p) <= BECKON_R:
		get_on()  # the key its tag shows (_draw_tag)
		get_viewport().set_input_as_handled()
	elif (riding or on_foot) and code == KEY_F:
		get_viewport().set_input_as_handled()  # no free flight from the gardens
	elif code == KEY_F and bool(_camera.get("_free_fly")) and land(false):
		# Flying out over the gardens, F walks there: the camera's own walk would take it back to the hall.
		get_viewport().set_input_as_handled()


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
	_beckon_step(minf(delta, 0.1))
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
		_drive(dt, ahead, back, left, right, yaw)
		# The keys turn the view with the scooter (and so does its walk round at a stand, easing out after the key);
		# moving, the scooter steers to where the view looks.
		if left != right or absf(_pivot) > 1e-4:
			yaw += wrapf(_heading - h0, -PI, PI)
	var rate := wrapf(_heading - h0, -PI, PI) / dt
	if auto:
		# The autopilot turns the scooter itself: the handlebar shows the turn it makes.
		var bar := clampf(atan(rate * WHEELBASE / maxf(absf(_v), 0.5)), -STEER_MAX, STEER_MAX)
		_steer = move_toward(_steer, bar, STEER_RATE * dt)
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
	# Into a turn as a bicycle leans: the angle whose tangent is the sideways pull over gravity.
	var roll_to := 0.0 if reduced_motion else clampf(atan(rate * _v / 9.81), -ROLL_MAX, ROLL_MAX)
	_lean = lerpf(_lean, lean_to, 1.0 - exp(-6.0 * dt))
	_roll = lerpf(_roll, roll_to, 1.0 - exp(-3.0 * dt))
	_camera.set("_yaw", yaw)
	_spin.x -= _v / cos(_steer) / WHEEL_R * dt
	_spin.y -= _v / WHEEL_R * dt
	_place(dt)
	var kmh := roundi(absf(_v) * 3.6)
	if kmh != _kmh or _frame % 30 == 0:
		_kmh = kmh
		_hint()
	if _frame % 10 == 0:
		_publish()


## Ridden by hand: the throttle (W) and the brake (S) open and close over a fraction of a second and the
## acceleration changes at most JERK a second, the motor's pull fading towards the top speed and the scooter
## gliding with no key; the handlebar turns at most
## STEER_RATE, its lock narrowing with the speed and with the sideways pull, and the scooter turns about its
## rear wheel as a bicycle does, at its speed times the handlebar's tangent over the wheelbase. A or D hold the
## handlebar over; with neither, moving, it steers to where the view `yaw` looks. At a stand, S walks the
## scooter backwards and A or D walk it round.
func _drive(dt: float, ahead: bool, back: bool, left: bool, right: bool, yaw: float) -> void:
	var top := SPEED * (FAST if _held(KEY_SHIFT) else 1.0)
	var walk_back := back and not ahead
	_thr = move_toward(_thr, 1.0 if ahead and not back else 0.0, THROTTLE * dt)
	_brk = move_toward(_brk, 1.0 if walk_back else 0.0, THROTTLE * 2.0 * dt)
	var a := 0.0
	if _v >= 0.0 and not (walk_back and _v < 0.25):
		# The motor's full pull up to 70 % of the top speed, fading to nothing at it; the brake and the
		# rolling's drag fading over the last 0.6 m/s, so that the scooter comes to a stand without a jolt.
		a = ACCEL * _thr * smoothstep(0.0, 1.0, (top - _v) / (0.3 * top))
		a -= (COAST + BRAKE * _brk) * clampf(_v / 0.6, 0.0, 1.0)
	else:
		# At a stand S walks the scooter backwards; let go, it comes back to a stand.
		a = clampf(((-BACK if walk_back else 0.0) - _v) * 2.0, -1.2, 1.2)
	_acc = move_toward(_acc, a, JERK * dt)
	_v += _acc * dt
	if absf(_v) < 0.02 and absf(a) < 0.05:
		_v = 0.0
		_acc = 0.0
	var speed := absf(_v)
	var lock := lerpf(STEER_MAX, STEER_FAST, smoothstep(0.0, SPEED * FAST, speed))
	if speed > 0.05:
		lock = minf(lock, atan(A_LAT * WHEELBASE / (speed * speed)))
	var keys := (1.0 if left else 0.0) - (1.0 if right else 0.0)
	var want := 0.0
	if keys != 0.0:
		want = keys * lock
	else:
		var off := wrapf(yaw - _heading, -PI, PI)
		if speed > 0.2 and absf(off) < LOOK_BACK:
			var rate_want := off * FOLLOW * minf(speed / 2.0, 1.0)
			want = clampf(atan(rate_want * WHEELBASE / maxf(speed, 0.3)), -lock, lock)
	_steer = clampf(move_toward(_steer, want, STEER_RATE * dt), -lock, lock)
	var rate := _v * tan(_steer) / WHEELBASE
	_pivot = move_toward(_pivot, keys * PIVOT_TURN * maxf(1.0 - speed / 0.3, 0.0), 6.0 * dt)
	rate += _pivot
	_heading = wrapf(_heading + rate * dt, -PI, PI)


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
		# The parked scooter: its deck, and its wheels at either end.
		var dir := Vector2(-sin(_heading), -cos(_heading))
		for s: Vector2 in [Vector2(0.0, SCOOTER_R), Vector2(-AXLE_FRONT, 0.2), Vector2(-AXLE_REAR, 0.2)]:
			var c := _p + dir * s.x
			var d := q - c
			var reach := s.y + FOOT_RADIUS
			if d.length_squared() < reach * reach:
				q = c + (d.normalized() if d.length_squared() > 1e-8 else Vector2.RIGHT) * reach
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
	var ahead := Vector2(-sin(_heading), -cos(_heading)) * FRONT
	for c: Vector2 in [to, Vector2(to.x, _p.y), Vector2(_p.x, to.y)]:
		var q: Vector2 = _gardens.call("push_out", c, RADIUS, _y)
		# The front wheel too, FRONT ahead: the scooter moved back as far as it is pushed.
		var f := q + ahead
		q += (_gardens.call("push_out", f, FRONT_R, _y) as Vector2) - f
		var gy := float(_gardens.call("ground_at", q))
		# 1 µm: the electric scooter's first steps from a stand, its acceleration eased in, are shorter than 0.1 mm.
		if absf(gy - _y) <= STEP and q.distance_squared_to(_p) > 1e-12:
			_p = q
			_y = gy
			return true
	return false


func _look(yaw: float, pitch: float) -> void:
	_camera.set("_yaw", yaw)
	_camera.set("_pitch", pitch)


## The scooter on the ground, tilted with its slope and leaning into its turn; riding, the camera above its
## deck: the eye goes with ROLL_EYE of the lean, the horizon with ROLL_VIEW of it, and the eye's height eases after the
## ground's (dt 0: at once).
func _place(dt: float) -> void:
	_place_model(dt)
	var eye := Basis(Vector3.UP, _heading) * Basis(Vector3.BACK, _roll * ROLL_EYE) * Vector3(0.0, DECK + EYE, 0.0)
	var want_y := _y + eye.y
	_eye_y = want_y if dt <= 0.0 or is_nan(_eye_y) else lerpf(_eye_y, want_y, 1.0 - exp(-EYE_EASE * dt))
	_camera.global_position = Vector3(_p.x + eye.x, _eye_y, _p.y + eye.z)
	_camera.rotation = Vector3(float(_camera.get("_pitch")) - _lean, float(_camera.get("_yaw")), _roll * ROLL_VIEW)
	_last = _camera.global_position
	_set_look = Vector2(float(_camera.get("_yaw")), float(_camera.get("_pitch")))


func _place_model(dt: float) -> void:
	var dir := Vector2(-sin(_heading), -cos(_heading))
	var rise := float(_gardens.call("ground_at", _p - dir * AXLE_FRONT)) - float(_gardens.call("ground_at", _p - dir * AXLE_REAR))
	var slope := clampf(atan2(rise, WHEELBASE), -0.3, 0.3)
	_slope = slope if dt <= 0.0 else lerpf(_slope, slope, 1.0 - exp(-12.0 * dt))
	_model.global_transform = Transform3D(Basis(Vector3.UP, _heading) * Basis(Vector3.RIGHT, _slope) * Basis(Vector3.BACK, _roll),
		Vector3(_p.x, _y, _p.y))
	if _steering != null:
		var turn := Basis(STEER_AXIS.normalized(), _steer)
		_steering.transform = Transform3D(turn, STEER_PIVOT - turn * STEER_PIVOT)
	if _pool != null:
		_pool.visible = riding
		var flat := Transform3D(Basis(Vector3.UP, _heading) * Basis(Vector3.RIGHT, _slope), Vector3(_p.x, _y, _p.y)) * POOL_XF
		_pool.transform = _model.global_transform.affine_inverse() * flat
	if _lamp != null:
		_lamp.visible = riding
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
	var graphite: Material = g.call("_gmat", 0, Color(0.13, 0.14, 0.15), {"sheen": 0.35})
	var rubber: Material = g.call("_gmat", 0, Color(0.05, 0.05, 0.05), {"sheen": 0.05})
	var mats := {
		"body": graphite,
		"trim": rubber,
		"metal": metal,
		"tail": g.call("_gmat", 5, Color.WHITE, {"lamp_colour": Color(1.0, 0.12, 0.07), "lamp_energy": 0.8}),
		"steer_metal": metal,
		"steer_body": graphite,
		"steer_trim": rubber,
		"steer_light": g.call("_gmat", 5, Color.WHITE, {"lamp_colour": Color(0.8, 0.92, 1.0), "lamp_energy": 0.6}),
		# The display's glass, dim: at the headlamp's energy it was a white blot under the rider's eyes.
		"steer_screen": g.call("_gmat", 5, Color.WHITE, {"lamp_colour": Color(0.2, 0.55, 0.65), "lamp_energy": 0.08}),
		"tyre": g.call("_gmat", 0, Color(0.045, 0.045, 0.045), {"sheen": 0.08}),
		"dish": g.call("_gmat", 0, Color(0.2, 0.21, 0.22), {"sheen": 0.3}),
		"spokes": metal,
	}
	for part: String in ["body", "trim", "metal", "tail"]:
		_part(_model, part, mats[part])
	# The steering, turned about the head tube's axis (_place_model); its parts are in the scooter's frame.
	_steering = Node3D.new()
	_steering.name = "Steering"
	_model.add_child(_steering)
	for part: String in ["steer_metal", "steer_body", "steer_trim", "steer_light", "steer_screen"]:
		_part(_steering, part, mats[part])
	# The front wheel turns with the steering; the rear one is the frame's.
	for front: bool in [true, false]:
		var wheel := Node3D.new()
		wheel.name = "WheelFront" if front else "WheelRear"
		wheel.position = Vector3(0.0, WHEEL_R, AXLE_FRONT if front else AXLE_REAR)
		(_steering if front else _model).add_child(wheel)
		for part: String in ["tyre", "dish", "spokes"]:
			_part(wheel, part, mats[part])
		_wheels.append(wheel)
	# Beckoning (BECKON_R): a golden ring lying round it, a lamp's material, so that it glows in the rays as
	# rasterized; its display and headlamp brighter.
	_screen_mat = mats.steer_screen
	_light_mat = mats.steer_light
	var torus := TorusMesh.new()
	torus.inner_radius = 0.93
	torus.outer_radius = 1.0
	torus.rings = 64
	torus.ring_segments = 6
	_ring_mat = g.call("_gmat", 5, Color.WHITE, {"lamp_colour": Color(1.0, 0.74, 0.3), "lamp_energy": 0.0})
	_ring = MeshInstance3D.new()
	_ring.name = "Beckon"
	_ring.mesh = torus
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_ring.transform = Transform3D(Basis.from_scale(Vector3(0.62, 0.25, 0.85)), Vector3(0.0, 0.03, (AXLE_FRONT + AXLE_REAR) * 0.5))
	_ring.visible = false
	_model.add_child(_ring)
	var layer := CanvasLayer.new()
	layer.name = "BeckonTag"
	layer.layer = 36
	add_child(layer)
	_tag = Control.new()
	_tag.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.visible = false
	_tag.draw.connect(_draw_tag)
	layer.add_child(_tag)
	# The headlamp's light, while riding: its pool on the ground ahead, added over it (assets/palace_glow.gdshader),
	# for the raster views, where the gardens and the Place du Capitole's paving are unshaded and no light reaches
	# them (a spot light at 8 times its energy changed nothing there, artpass/gardens/escooter/lamp_probe.gd). It
	# keeps to the scooter's heading and slope but not its lean: leaning, half of it went under the square's
	# paving, cut straight down the middle of the view (2026-10-16). Natively also a spot light from the lamp on
	# the stem, turning with the handlebar, for the path tracer: its rays light the gardens (palace_garden.gdshader's
	# RT variant), and they leave out the pool, a blended surface.
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	_pool = MeshInstance3D.new()
	_pool.name = "Headlight"
	_pool.mesh = plane
	# At 0.22, 3.6 m ahead, it was a white blot at the foot of the view (artpass/gardens/ride1-fwd).
	_pool.material_override = g.call("_glow", Color(0.85, 0.9, 0.95), 0.09, {"fade_top": 0.6, "fade_foot": 0.45, "edge": 1.0})
	_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pool.visible = false
	_model.add_child(_pool)
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		_lamp = SpotLight3D.new()
		_lamp.name = "Headlamp"
		_lamp.light_color = Color(0.85, 0.92, 1.0)
		_lamp.light_energy = HEADLAMP_ENERGY
		_lamp.light_specular = 0.3
		_lamp.spot_range = 16.0
		_lamp.spot_angle = 26.0
		_lamp.spot_angle_attenuation = 1.4
		_lamp.shadow_enabled = false
		_lamp.transform = Transform3D(Basis(Vector3.RIGHT, -HEADLAMP_DIP), HEADLAMP_AT)
		_steering.add_child(_lamp)
	stats.kit = true


func _part(parent: Node3D, part: String, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = part.capitalize()
	mi.mesh = load(KIT % part)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)


## On foot near the scooter: it lights up and its tag shows; elsewhere both fade.
func _beckon_step(dt: float) -> void:
	if _ring == null:
		return
	var near := on_foot and not riding and _model != null and _model.visible and _foot.distance_to(_p) <= BECKON_R
	_beckon = move_toward(_beckon, 1.0 if near else 0.0, dt / (0.25 if near else 0.4))
	_beckon_t += dt
	var pulse := 0.5 + 0.5 * sin(_beckon_t * TAU * 0.8)
	_ring.visible = _beckon > 0.01
	_ring_mat.set_shader_parameter("lamp_energy", _beckon * (0.9 + 0.9 * pulse))
	_screen_mat.set_shader_parameter("lamp_energy", lerpf(0.08, 0.45, _beckon))
	_light_mat.set_shader_parameter("lamp_energy", lerpf(0.6, 1.5, _beckon * pulse))
	_tag.visible = _beckon > 0.01
	if _tag.visible:
		_tag.queue_redraw()


## The tag over the beckoning scooter: the key and what it does, where the scooter is on the screen, or at
## the foot of it when the scooter is behind the view.
func _draw_tag() -> void:
	var size := _tag.get_viewport_rect().size
	var u := minf(size.x, size.y)
	var font := ThemeDB.fallback_font
	var fs := roundi(clampf(u * 0.03, 15.0, 30.0))
	var lib := _obs.get_node_or_null("Generated/CourseShelves")
	var lang := str(lib.get("lang")) if lib != null else "en"
	var text: String = BECKON_TEXT.get(lang, BECKON_TEXT.en)
	var touch := _obs.get_node_or_null("TouchControls") != null
	var key := "" if touch else "E"
	var top := Vector3(_p.x, _y + 1.35, _p.y)
	var at := Vector2(size.x * 0.5, size.y * 0.7)
	if not _camera.is_position_behind(top):
		at = _camera.unproject_position(top)
		at = at.clamp(Vector2(u * 0.2, u * 0.12), size - Vector2(u * 0.2, u * 0.22))
	var a := clampf(_beckon, 0.0, 1.0)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var kw := 0.0 if key == "" else fs * 1.6
	var w := tw + kw + fs * (1.6 if key != "" else 1.0)
	var box := Rect2(at.x - w * 0.5, at.y - fs * 1.9, w, fs * 1.8)
	var gilt := Color(0.86, 0.7, 0.42)
	_tag.draw_rect(box, Color(0.035, 0.03, 0.028, 0.82 * a))
	_tag.draw_rect(box, Color(gilt, 0.85 * a), false, maxf(1.5, fs * 0.08))
	var x := box.position.x + fs * 0.5
	if key != "":
		var cap := Rect2(x, box.position.y + fs * 0.25, kw, fs * 1.3)
		_tag.draw_rect(cap, Color(gilt, 0.95 * a))
		var cw := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_tag.draw_string(font, Vector2(cap.get_center().x - cw * 0.5, cap.get_center().y + fs * 0.36), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(0.06, 0.05, 0.04, a))
		x += kw + fs * 0.6
	_tag.draw_string(font, Vector2(x, box.get_center().y + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.97, 0.94, 0.87, a))
	# A little pointer down to the scooter.
	var tip := Vector2(at.x, box.end.y + fs * 0.5)
	_tag.draw_colored_polygon(PackedVector2Array([Vector2(at.x - fs * 0.35, box.end.y), Vector2(at.x + fs * 0.35, box.end.y), tip]),
		Color(gilt, 0.85 * a))


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
