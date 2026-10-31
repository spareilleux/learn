extends Node
## The pocket drone, the curio wheel's eighth curio (scripts/curio_wheel.gd). The author asked for the
## drone of the "Banc de Placement" artifact (2026-10-02): a nine-centimetre quadcopter that takes
## off and tours its rooms, the camera following it or on board. Used, it rises from the hand and the
## view cuts to it, touring the observatory: low round the steel box, up to Seldon's face, through a
## bay into each gallery along the books, up round the drum past the stained glass and out through
## the oculus, wide over the domes of Trantor, along the lit lancets outside, back in and down round
## the drum, and across the hall, again and again. V or the button switches between the chase view
## and the view on board; Escape or the button lands it back in the hand.
## The flight is the artifact's, in metres. The speed is not chosen but limited: ahead of each bend,
## to what the lateral acceleration the craft allows itself can hold there, braking before the bend
## with a bounded jerk. A PD follower holds the reference, its acceleration fed forward, bounded at
## 25 degrees of tilt, and the reference waits for the craft when it lags, so the craft keeps to the
## corridor planned for it. The attitude follows the acceleration through a second-order loop, the
## nose turns at a bounded rate, and slow air stirs it. On board, the view is a stabilised gimbal's:
## the horizon level, the pitch following the climb late. Model and tour are built here; nothing is
## copied. The hum is a take the author chose by ear (assets/sfx/drone-hum.wav), with the hum built
## here as its fallback. Added by scripts/observatory.gd.

const TEXT := {
	"en": {"title": "DRONE", "chase": "Chase view", "board": "On board", "land": "Land", "voltige": "STUNTS",
		"manual": "BY HAND", "auto": "AUTOPILOT",
		"hand": "W A S D: fly  ·  Space / C: up, down  ·  Q E or ← →: turn  ·  let go: autopilot",
		"keys": "V: view  ·  Shift held: stunts  ·  Esc: land", "no_sky": "No sky in here: the drone stays in your hand."},
	"fr": {"title": "DRONE", "chase": "Vue de poursuite", "board": "À bord", "land": "Atterrir", "voltige": "VOLTIGE",
		"manual": "AUX COMMANDES", "auto": "PILOTE AUTO",
		"hand": "Z Q S D : piloter  ·  Espace / C : monter, descendre  ·  A E ou ← → : tourner  ·  lâcher : pilote auto",
		"keys": "V : vue  ·  Maj maintenue : voltige  ·  Échap : atterrir", "no_sky": "Pas de ciel ici : le drone reste dans ta main."},
	"es": {"title": "DRON", "chase": "Vista de persecución", "board": "A bordo", "land": "Aterrizar", "voltige": "ACROBACIAS",
		"manual": "A LOS MANDOS", "auto": "PILOTO AUTOMÁTICO",
		"hand": "W A S D: pilotar  ·  Espacio / C: subir, bajar  ·  Q E o ← →: girar  ·  soltar: piloto automático",
		"keys": "V: vista  ·  Mayús pulsada: acrobacias  ·  Esc: aterrizar", "no_sky": "Aquí no hay cielo: el dron se queda en tu mano."},
}
const SFX_PATH := "res://scripts/sfx_takes.gd"
const WEB_LOOP_PATH := "res://scripts/web_loop.gd"
## The tour: [degrees round the hall (0 along +x, 90 along +z, the entrance), metres from its axis,
## height, speed factor], a closed Catmull-Rom curve through the points. 0.45 is a pass to look at,
## 1.45 the long turn over Trantor. The hall: piers at 13 m, every 22.5 degrees; the galleries'
## floors at 6.2 and 12.6 m, their rails 1.07 m up at 13.78 m, the shelves' fronts at 17.15 m; the
## oculus 10 m wide up to the drum's top at 24.9 m, the orrery's rings inside it from 2.2 to 8.2 m;
## outside, the lead from 21.75 m at the drum to 21.15 m at the eave, 19.3 m out; the lift at 78.75
## degrees, 16.1 m out, which the tour keeps away from.
const TOUR := [
	[90.0, 7.0, 2.2, 0.8],      # in front of the steel box's door
	[55.0, 5.4, 1.2, 0.55],     # low over the gilt rings
	[15.0, 5.2, 1.0, 0.5],
	[355.0, 3.8, 2.0, 0.5],     # turns out towards Seldon
	[348.75, 6.2, 3.3, 0.4],    # level with his face
	[320.0, 7.6, 4.6, 0.7],
	[300.0, 8.6, 5.6, 0.85],
	[262.0, 10.0, 7.6, 0.9],
	[236.25, 11.2, 8.7, 0.6],   # lined up with a bay of the first gallery
	[236.25, 14.4, 8.9, 0.45],  # through it, over the rail
	[220.0, 15.5, 9.0, 0.45],   # along the books
	[202.5, 15.6, 9.0, 0.45],
	[180.0, 15.4, 8.9, 0.45],
	[168.75, 14.5, 8.8, 0.5],   # out through another bay
	[168.75, 11.0, 8.6, 0.7],
	[140.0, 8.0, 10.5, 0.9],
	[100.0, 8.5, 12.4, 0.9],
	[56.25, 11.2, 14.6, 0.6],   # lined up with a bay of the second gallery
	[56.25, 14.4, 14.9, 0.45],
	[40.0, 15.5, 15.0, 0.45],
	[22.5, 15.6, 15.0, 0.45],
	[5.0, 15.4, 15.0, 0.45],
	[348.75, 14.4, 14.9, 0.5],
	[348.75, 11.0, 15.2, 0.7],
	[320.0, 9.1, 17.5, 0.8],    # up round the drum, past the stained glass
	[290.0, 9.1, 19.5, 0.6],
	[255.0, 9.1, 21.6, 0.5],
	[220.0, 9.1, 23.4, 0.5],
	[185.0, 9.0, 25.2, 0.6],
	[150.0, 8.6, 26.8, 0.8],    # out through the oculus
	[120.0, 14.0, 29.5, 1.1],
	[80.0, 24.0, 32.0, 1.35],
	[30.0, 34.0, 33.0, 1.45],   # wide over the domes of Trantor
	[330.0, 38.0, 31.0, 1.45],
	[270.0, 34.0, 29.0, 1.4],
	[225.0, 25.0, 26.5, 1.2],
	[195.0, 16.5, 23.6, 0.7],   # down over the lead
	[165.0, 12.6, 23.2, 0.55],  # along the lit lancets
	[135.0, 12.6, 23.4, 0.55],
	[110.0, 12.0, 25.6, 0.7],
	[85.0, 9.3, 27.0, 0.7],     # over the cornice and in
	[55.0, 9.15, 25.0, 0.55],
	[20.0, 9.15, 22.8, 0.5],    # down round the drum
	[345.0, 9.15, 20.6, 0.55],
	[310.0, 8.6, 18.6, 0.7],
	[270.0, 7.5, 13.0, 1.0],    # down across the hall
	[200.0, 7.0, 7.0, 1.0],
	[140.0, 7.5, 3.6, 0.9],
]
# The artifact's flight model, from centimetres to metres.
const CRUISE := 2.2          # m/s
const A_LAT := 3.0           # m/s², the lateral acceleration it allows itself in a bend
const A_GO := 1.5            # m/s², to speed up
const A_BRAKE := 2.0         # m/s², to brake
const JERK := 5.2            # m/s³: no hand pushes a stick in steps
const A_MAX := 4.6           # m/s²: atan(4.6 / 9.81) is 25 degrees, what a camera drone allows itself
const KP := 26.0             # 1/s², the follower's stiffness
const KD := 9.5              # 1/s, its damping, nearly critical
const W_ATT := 11.0          # rad/s, the attitude loop's stiffness
const Z_ATT := 0.82          # a little under critical: the slight overshoot as it settles out of a bend
const YAW_K := 3.4           # 1/s, the nose's gain
const YAW_MAX := 2.2         # rad/s, 126 degrees a second at most
const G := 9.81
const LOOK := 6.0            # m looked ahead for bends: from 3.2 m/s, stopping at 1 m/s² takes 5 m
const CHASE_BACK := 0.4      # m behind it
const CHASE_UP := 0.11       # m above
const CHASE_FOV := 50.0      # degrees, vertical, at most
const SUB := 1.0 / 120.0     # s: the follower is integrated in steps no longer than this
const RISE := 1.4            # s from the hand, watched from where you stand, before the cut
const FADE := 0.22           # s each way of a cut
const HUSH := -60.0
# Stunts (the author, 2026-10-15: « rajoute un mode voltige au drone (haute vitesse, acrobaties) - ON quand
# Maj est appuyée, OFF quand relâchée »): a racing quad's flight on the same tour, blended in and out over
# BLEND seconds. Its speed is still planned ahead of every bend, with a racer's braking, and the racer's
# authority stays while the craft is faster than its cruise, so letting go of Shift before a bend never
# leaves it too fast for the camera drone's limits. On straights it rolls or flips; on board the view is
# an FPV camera's, fixed to the frame and tilted up, the horizon turning with it.
const V_CRUISE := 9.0        # m/s, 32 km/h
const V_A_LAT := 18.0        # m/s², nearly 2 g in a bend
const V_A_GO := 9.0
const V_A_BRAKE := 14.0
const V_JERK := 60.0
const V_A_MAX := 24.0        # m/s²: atan(24 / 9.81) is 68 degrees of tilt
const V_KP := 70.0
const V_KD := 16.0           # nearly critical again
const V_W_ATT := 20.0
const V_YAW_K := 6.0
const V_YAW_MAX := 7.0
const V_LOOK := 14.0         # m: from 9 m/s, stopping at 7 m/s² takes 5.8 m
const V_CHASE_FOV := 68.0
const V_UPTILT := 0.35       # rad, the FPV camera's tilt up from the frame
const BLEND := 0.35          # s
const TRICK_TIME := 0.62     # s for a roll or a flip
const TRICK_GAP := 1.4       # s at least between two
const TRICK_CLEAR := 0.2     # 1/m: no bend tighter than 5 m within the trick's flight
# By hand (the author, 2026-10-16: « je voudrais pouvoir euh, contrôler le drone quand ça me chante. Et
# ensuite, quand je lâche les commandes, ça reprend euh, le contrôle normal, le pilote automatique. »):
# a stick touched takes the craft off the tour, its speed asked in the nose's frame; let go for M_LET_GO,
# the autopilot takes it back from the tour's nearest place in sight, and the reference waits for it.
const M_FWD := 3.2           # m/s forward and back
const M_SIDE := 2.4          # m/s sideways
const M_UP := 1.8            # m/s up and down
const M_YAW := 1.5           # rad/s
const M_RESP := 2.4          # 1/s: how fast the craft takes up the speed asked
const M_TURBO := 3.0         # times those speeds, stunts held
const M_LET_GO := 1.2        # s without a stick before the autopilot takes back
const M_BODY := 0.14         # m kept from walls, floors and ceilings
const SHELF_FRONT := 17.15   # m, the shelves' fronts
const REJOIN_MAX := 25.0     # s for the autopilot to bring the craft back to the tour, or it cuts there

var lang := "en"
var touch := false
var reduced_motion := false
var view := "chase"          # or "board"
## Stunts: whether Shift holds them; voltige_hold holds them for tests.
var voltige := false
var voltige_hold := false
## Counts for tests.
var stats := {"launches": 0, "refused": 0, "landings": 0, "views": 0, "laps": 0, "frames": 0,
	"max_tilt_deg": 0.0, "max_speed": 0.0, "tricks": 0, "takeovers": 0, "handovers": 0, "manual_frames": 0,
	"kept": 0, "rejoin_cuts": 0}
## By hand: whether the visitor holds the sticks; manual_hold holds them for tests (forward, right, up,
## turn right, each -1 to 1).
var manual := false
var manual_hold := Vector4.ZERO

var _obs: Node3D
var _camera: Camera3D        # the visitor's (fly_camera.gd)
var _cam: Camera3D           # the drone's
var _craft: Node3D
var _rotors: Array[Node3D] = []
var _blurs: Array[MeshInstance3D] = []
var _blades: Array[Node3D] = []
var _phase := "idle"         # idle, rise, fly; a cut runs under any of them
var _busy := false           # a cut is fading
var _t := 0.0
var _rise_t := 0.0
var _rise_from := Transform3D()
var _spin := 0.0             # 0 still .. 1 flying
var _tour := {}
# The flight's state, as the artifact's.
var _s := 0.0                # metres along the tour
var _vit := 0.0              # the reference's speed along it
var _acc := 0.0              # and its rate
var _p := Vector3.ZERO
var _v := Vector3.ZERO
var _a := Vector3.ZERO
var _yaw := 0.0
var _yaw_v := 0.0
var _pitch := 0.0
var _pitch_v := 0.0
var _roll := 0.0
var _roll_v := 0.0
var _site := 0.0             # the gimbal's pitch, on board
var _eye := Vector3.INF      # the chase camera, late on the craft
var _ref_prev := Vector3.INF
var _vb := 0.0               # 0 the camera drone .. 1 the racer, eased over BLEND
var _auth := 0.0             # the racer's limits: _vb, or more while the craft is faster than CRUISE
var _trick := ""             # "roll", "flip" or none
var _trick_t := 0.0
var _trick_gap := 0.0
var _trick_dir := 1.0
var _stick := Vector4.ZERO   # this frame's sticks
var _idle_hand := 0.0        # s since a stick was last held
var _rejoin := false         # the autopilot taking back: the craft kept in bounds until it is on the tour
var _rejoin_t := 0.0
var _auto_t := 0.0           # s left showing that the autopilot took back
var _obstacles: Array = []   # [centre, unit u, unit v, half sizes, y0, y1]: piers, pedestals, the steel box
var _lift_at := Vector2.INF  # the lift's shaft, its axis on the floor (lift.gd LIFT_BAY, AXIS_R)
var _spring := 16.1          # the colonnade's arches spring here (observatory.gd column_height - 2.9)
var _orrery: Array = []      # [centre, axis, radius, body's radius]: each orbit's ring, its body going round it
# What the flight puts aside and gives back on landing.
var _hidden_layers: Array[CanvasLayer] = []
var _paused: Array[Node] = []
var _mouse_mode := Input.MOUSE_MODE_VISIBLE
var _layer: CanvasLayer
var _ui: Control
var _fade: ColorRect
var _note := ""              # a refusal, shown a moment
var _note_t := 0.0
var _hum: AudioStreamPlayer3D
var _hum_loop: Node           # web_loop.gd: the hum kept going on the web


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	# After the curio wheel (860); before extra_views.gd (870), which shows Upperside to the camera
	# that looks, from where this node has just put it.
	process_priority = 865
	reduced_motion = OS.get_cmdline_user_args().has("--reduced-motion")
	if OS.has_feature("web") and not Engine.is_editor_hint():
		reduced_motion = reduced_motion or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	touch = _obs != null and _obs.get_node_or_null("TouchControls") != null
	_tour = make_path(_tour_points(), true)
	_craft = build_model()
	_craft.name = "DroneCraft"
	_craft.visible = false
	add_child(_craft)
	for i in 4:
		_rotors.append(_craft.get_node("Rotor%d" % i) as Node3D)
		_blurs.append(_craft.get_node("Rotor%d/Blur" % i) as MeshInstance3D)
		_blades.append(_craft.get_node("Rotor%d/Blades" % i) as Node3D)
	_cam = Camera3D.new()
	_cam.name = "DroneCamera"
	add_child(_cam)
	_hum = AudioStreamPlayer3D.new()
	_hum.name = "Hum"
	# The take's timbre made steady (artpass/foundation/audio/make_hum.py: the author, 2026-10-12, asked
	# for it far quieter and even, with no loop heard), looping over its whole file; the hum built here
	# where that file is not in the build (scripts/sfx_takes.gd).
	var sfx: Script = load(SFX_PATH)
	_hum.stream = sfx.call("pick_loop", "drone-hum", _hum_stream())
	_hum.volume_db = HUSH
	_hum.unit_size = 1.2
	_hum.max_db = -14.0
	_craft.add_child(_hum)
	# web_loop.gd: in the web build a looping sample plays once; two players take turns there.
	_hum_loop = load(WEB_LOOP_PATH).new()
	_hum_loop.name = "HumLoop"
	add_child(_hum_loop)
	_hum_loop.call("configure", _hum)
	_make_ui()


func _t_(key: String) -> String:
	return str(TEXT.get(lang, TEXT.en).get(key, TEXT.en[key]))


## Whether the drone has the view or is on its way to it: from the hand to the hand.
func is_flying() -> bool:
	return _phase != "idle"


# --- The tour ---------------------------------------------------------------------------------

func _tour_points() -> Array:
	var pts := []
	for w: Array in TOUR:
		var a := deg_to_rad(float(w[0]))
		pts.append([Vector3(cos(a) * float(w[1]), float(w[2]), sin(a) * float(w[1])), float(w[3])])
	return pts


## The curve sampled: positions, speed factors and the length run at each, so that the craft goes a
## length a second and not a parameter, which would slow it in every bend. pts: [Vector3, factor].
static func make_path(pts: Array, closed: bool) -> Dictionary:
	var n := pts.size()
	var per := 20
	var P := PackedVector3Array()
	var F := PackedFloat32Array()
	var at := func(i: int) -> Array:
		return pts[posmod(i, n)] if closed else pts[clampi(i, 0, n - 1)]
	for i in (n if closed else n - 1):
		var a: Vector3 = at.call(i - 1)[0]
		var b: Vector3 = at.call(i)[0]
		var c: Vector3 = at.call(i + 1)[0]
		var d: Vector3 = at.call(i + 2)[0]
		var fb: float = at.call(i)[1]
		var fc: float = at.call(i + 1)[1]
		for j in per:
			var t := float(j) / per
			var t2 := t * t
			var t3 := t2 * t
			P.append(0.5 * (2.0 * b + (c - a) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t2 + (3.0 * b - a - 3.0 * c + d) * t3))
			F.append(lerpf(fb, fc, t))
	if closed:
		P.append(P[0])
		F.append(F[0])
	else:
		P.append(pts[n - 1][0])
		F.append(pts[n - 1][1])
	var S := PackedFloat32Array([0.0])
	for i in range(1, P.size()):
		S.append(S[i - 1] + P[i].distance_to(P[i - 1]))
	var L := S[S.size() - 1]
	return {"P": P, "F": F, "S": S, "L": L, "closed": closed, "step": L / maxf(1.0, P.size() - 1)}


## Where the curve is, and its speed factor, s metres along it.
static func path_at(V: Dictionary, s: float) -> Array:
	var S: PackedFloat32Array = V.S
	var L: float = V.L
	s = fposmod(s, L) if V.closed else clampf(s, 0.0, L - 0.001)
	var lo := 0
	var hi := S.size() - 1
	while hi - lo > 1:
		var m := (lo + hi) >> 1
		if S[m] <= s:
			lo = m
		else:
			hi = m
	var t := (s - S[lo]) / maxf(1e-6, S[hi] - S[lo])
	var P: PackedVector3Array = V.P
	var F: PackedFloat32Array = V.F
	return [P[lo].lerp(P[hi], t), lerpf(F[lo], F[hi], t)]


## A stencil's half width on the curve: four samples at least, or it reads the sampling's kinks
## rather than the curve, and never past an open curve's end.
static func _stencil(V: Dictionary, s: float, h: float) -> float:
	var H := maxf(h, 4.0 * float(V.step))
	return H if V.closed else minf(H, minf(s, float(V.L) - s))


## The tangents either side of s, and the stencil between: the curvature is their difference over
## it; a body passing at v accelerates by v² times that. Tangents keep their length at any angle,
## where second differences of positions shorten in tight bends and read as braking.
static func _tangents(V: Dictionary, s: float, h: float) -> Array:
	var H := _stencil(V, s, h)
	if not (H > 0.02):
		return []
	var p0: Vector3 = path_at(V, s - H)[0]
	var p1: Vector3 = path_at(V, s)[0]
	var p2: Vector3 = path_at(V, s + H)[0]
	return [H, (p2 - p1).normalized(), (p1 - p0).normalized()]


static func curvature(V: Dictionary, s: float, h := 0.22) -> float:
	var T := _tangents(V, s, h)
	return 0.0 if T.is_empty() else ((T[1] as Vector3) - (T[2] as Vector3)).length() / float(T[0])


## The acceleration of a body running the curve at v and speeding up by acc: centripetal plus
## along the curve.
static func path_accel(V: Dictionary, s: float, v: float, acc: float, h: float) -> Vector3:
	var T := _tangents(V, s, h)
	if T.is_empty():
		return Vector3.ZERO
	var ahead: Vector3 = T[1]
	var behind: Vector3 = T[2]
	return (ahead - behind) * (v * v / float(T[0])) + (ahead + behind).normalized() * acc


## The speed that can be held here: below sqrt(a_lat / k) in every bend met within far metres, less
## what braking at half its rate can shed on the way (the deceleration's own rate is bounded, so
## counting on all of it from the first metre announced the braking too late).
static func holdable(V: Dictionary, s: float, vmax: float, a_lat: float, brake: float, far: float) -> float:
	var vc := vmax
	var step := maxf(minf(float(V.step), 0.25), far / 32.0)
	var f := brake * 0.5
	var d := 0.0
	while d <= far:
		var k := curvature(V, s + d)
		var lim := sqrt(a_lat / maxf(k, 1e-9))
		vc = minf(vc, sqrt(lim * lim + 2.0 * f * d))
		d += step
	return vc


static func air(t: float, ampl: float) -> Vector3:
	# Three sines of incommensurate periods rather than noise: the flight stays reproducible. A
	# multirotor is much stiffer vertically than sideways.
	return Vector3(ampl * (sin(t * 0.71) * 0.6 + sin(t * 1.83 + 2.1) * 0.3 + sin(t * 3.29 + 4.4) * 0.1),
		ampl * 0.5 * (sin(t * 0.89 + 2.6) * 0.6 + sin(t * 1.61 + 0.4) * 0.4),
		ampl * (sin(t * 0.63 + 1.7) * 0.6 + sin(t * 1.97 + 3.9) * 0.3 + sin(t * 3.11 + 0.8) * 0.1))


## The tour's length, and its samples, for tests.
func tour_length() -> float:
	return float(_tour.L)


func tour_samples() -> PackedVector3Array:
	return _tour.P


static func outside(p: Vector3) -> bool:
	return p.y > 24.9 or Vector2(p.x, p.z).length() > 18.6


# --- Flying ---------------------------------------------------------------------------------------

## One step of the flight, dt seconds: the reference's speed, its place, the follower, the nose and
## the attitude.
func _fly(dt: float) -> void:
	var V := _tour
	var q := path_at(V, _s)
	# The racer's limits while stunts are held, and while the craft is still faster than the camera
	# drone's cruise once they are let go.
	# (The tour's fastest stretch asks 1.45 times CRUISE: the camera drone never reaches 1.6.) The
	# craft's own speed counts too: the reference brakes first, and on the reference's speed alone the
	# craft, still at 8 m/s, was left a camera drone's 4.6 m/s² and ran 1.5 m wide (--voltige-toggle).
	var fast := maxf(_vit, _v.length())
	_auth = maxf(_vb, clampf((fast - CRUISE * 1.6) / (V_CRUISE - CRUISE * 1.6), 0.0, 1.0))
	var b := _auth
	var vmax := lerpf(CRUISE * float(q[1]), V_CRUISE * (0.55 + 0.45 * float(q[1])), _vb)
	var brake := lerpf(A_BRAKE, V_A_BRAKE, b)
	var vc := holdable(V, _s, vmax, lerpf(A_LAT, V_A_LAT, b), brake, lerpf(LOOK, V_LOOK, b))
	var want := clampf((vc - _vit) * 3.2, -brake, lerpf(A_GO, V_A_GO, b))
	var jerk := lerpf(JERK, V_JERK, b)
	_acc += clampf(want - _acc, -jerk * dt, jerk * dt)
	_vit = maxf(0.0, _vit + _acc * dt)
	# The reference waits for the craft: a follower that falls behind and keeps going cuts corners.
	var lag := 0.0 if _ref_prev == Vector3.INF else _ref_prev.distance_to(_p)
	var s0 := _s
	if lag > 0.0:
		# Only what is behind the reference or beside it counts: a craft ahead of it, counted as lag,
		# held the reference back and the craft further ahead, 1.8 m at 9 m/s (dronetest --voltige),
		# and let go of stunts there, the reference crawled to it at a tenth of its speed.
		var h0 := _stencil(V, s0, 0.22)
		var tg0 := ((path_at(V, s0 + h0)[0] as Vector3) - (path_at(V, s0 - h0)[0] as Vector3)).normalized()
		var off := _ref_prev - _p
		var along := off.dot(tg0)
		lag = sqrt(maxf(along, 0.0) * maxf(along, 0.0) + (off - tg0 * along).length_squared())
	_s = fposmod(_s + _vit * dt / (1.0 + maxf(0.0, lag - 0.08) / 0.2), float(V.L))
	if _s < s0 - 1.0:
		stats.laps += 1
	var p_ref: Vector3 = path_at(V, _s)[0]
	var H := _stencil(V, _s, 0.22)
	var tg := ((path_at(V, _s + H)[0] as Vector3) - (path_at(V, _s - H)[0] as Vector3)).normalized()
	var v_ref := tg * _vit
	var a_ref := path_accel(V, _s, _vit, _acc, 0.22)
	_ref_prev = p_ref
	var a := a_ref + (p_ref - _p) * lerpf(KP, V_KP, b) + (v_ref - _v) * lerpf(KD, V_KD, b)
	if not reduced_motion:
		a += air(_t, 0.42 if outside(_p) else 0.16)
	# The bound is not cosmetic: it forbids what the thrust could not do, and so makes the gap to
	# the planned path.
	var a_max := lerpf(A_MAX, V_A_MAX, b)
	if a.length() > a_max:
		a = a.normalized() * a_max
	_a = a
	_v += a * dt
	if _rejoin:
		# Taken back from the hand: kept in bounds until it is on the tour again; if it has not got
		# there in REJOIN_MAX seconds, the view cuts to it on the tour.
		_move_kept(dt)
		_rejoin_t += dt
		if (p_ref - _p).length() < 0.3:
			_rejoin = false
		elif _rejoin_t > REJOIN_MAX and not _busy:
			_rejoin = false
			stats.rejoin_cuts += 1
			_cut(func() -> void: place_at(_s, _vit))
	else:
		_p += _v * dt
	# The nose: free on a multirotor, so a camera drone turns it at a bounded rate, and not at all
	# when stopped.
	var vh := Vector2(_v.x, _v.z).length()
	var w := 0.0
	if vh > 0.12:
		var yaw_max := lerpf(YAW_MAX, V_YAW_MAX, b)
		w = clampf(wrapf(atan2(-_v.x, -_v.z) - _yaw, -PI, PI) * lerpf(YAW_K, V_YAW_K, b), -yaw_max, yaw_max)
	_yaw_v += (w - _yaw_v) * (1.0 - exp(-dt * 9.0))
	_yaw += _yaw_v * dt
	_attitude(a, dt)


## The attitude, from the acceleration: the thrust points along a + g, read in the nose's frame,
## reached through a second-order loop.
func _attitude(a: Vector3, dt: float) -> void:
	var up := (a + Vector3(0.0, G, 0.0)).normalized()
	var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var pitch_to := -atan2(up.dot(fwd), maxf(up.y, 0.05))
	var roll_to := -asin(clampf(up.dot(right), -1.0, 1.0))
	var w_att := lerpf(W_ATT, V_W_ATT, _auth)
	_pitch_v += (w_att * w_att * (pitch_to - _pitch) - 2.0 * Z_ATT * w_att * _pitch_v) * dt
	_pitch += _pitch_v * dt
	_roll_v += (w_att * w_att * (roll_to - _roll) - 2.0 * Z_ATT * w_att * _roll_v) * dt
	_roll += _roll_v * dt


# --- By hand ----------------------------------------------------------------------------------

## The sticks: W/S or the arrows forward and back, A/D sideways (by their place on the keyboard: Z/S and
## Q/D on an AZERTY one), Space up, C or Ctrl down, Q/E or the arrows to turn; a gamepad's sticks and
## triggers too. Forward, right, up, turn right; nothing on a touch screen yet.
func _sticks() -> Vector4:
	if manual_hold != Vector4.ZERO:
		return manual_hold
	if touch or _busy:
		return Vector4.ZERO
	var s := Vector4(_keys(KEY_W, KEY_S) + _keys(KEY_UP, KEY_DOWN), _keys(KEY_D, KEY_A),
		_keys(KEY_SPACE, KEY_C) - float(Input.is_physical_key_pressed(KEY_CTRL)), _keys(KEY_E, KEY_Q) + _keys(KEY_RIGHT, KEY_LEFT))
	for pad in Input.get_connected_joypads():
		var dz := func(x: float) -> float: return 0.0 if absf(x) < 0.2 else (x - signf(x) * 0.2) / 0.8
		s += Vector4(-dz.call(Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)), dz.call(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)),
			Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT),
			dz.call(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X)))
	return s.clamp(-Vector4.ONE, Vector4.ONE)


func _keys(plus: Key, minus: Key) -> float:
	return float(Input.is_physical_key_pressed(plus)) - float(Input.is_physical_key_pressed(minus))


## Who flies this frame: a stick held takes the craft; let go for M_LET_GO, the autopilot takes it back.
func _hands(delta: float) -> void:
	_stick = _sticks()
	_auto_t = maxf(0.0, _auto_t - delta)
	if _stick.length_squared() > 1e-4:
		if not manual:
			manual = true
			_rejoin = false
			_trick = ""
			stats.takeovers += 1
			_gather_obstacles()
		_idle_hand = 0.0
	elif manual:
		_idle_hand += delta
		if _idle_hand >= M_LET_GO:
			_hand_back()


## The autopilot takes back: from the tour's nearest place that the craft can fly to straight, its
## reference starting at the craft's speed along the tour, and waiting while the craft comes.
func _hand_back() -> void:
	manual = false
	_rejoin = true
	_rejoin_t = 0.0
	_auto_t = 2.5
	stats.handovers += 1
	_s = rejoin_at(_p)
	var p_ref: Vector3 = path_at(_tour, _s)[0]
	var tg := ((path_at(_tour, _s + 0.3)[0] as Vector3) - p_ref).normalized()
	_vit = clampf(_v.dot(tg), 0.0, CRUISE)
	_acc = 0.0
	_ref_prev = p_ref
	_trick_gap = TRICK_GAP


## The tour's place nearest p that a straight flight from p reaches without meeting anything; the
## nearest at all if none does.
func rejoin_at(p: Vector3) -> float:
	var P: PackedVector3Array = _tour.P
	var S: PackedFloat32Array = _tour.S
	var order: Array = []
	for i in P.size():
		order.append([P[i].distance_squared_to(p), i])
	order.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for k in mini(order.size(), 60):
		var i: int = order[k][1]
		if _clear(p, P[i]):
			return S[i]
	return S[int(order[0][1])] if not order.is_empty() else 0.0


func _clear(a: Vector3, b: Vector3) -> bool:
	var n := maxi(1, ceili(a.distance_to(b) / 0.3))
	var q := a
	for k in n:
		var to := a.lerp(b, float(k + 1) / n)
		if keep_in(q, to).distance_to(to) > 0.01:
			return false
		q = to
	return true


## One step by hand, dt seconds: the speed asked in the nose's frame, reached at a bounded tilt, kept in
## bounds; the nose turned by the stick.
func _fly_manual(dt: float) -> void:
	var turbo := lerpf(1.0, M_TURBO, _vb)
	var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var want := (fwd * _stick.x * M_FWD + right * _stick.y * M_SIDE) * turbo + Vector3.UP * _stick.z * M_UP * lerpf(1.0, 2.0, _vb)
	var a := (want - _v) * M_RESP * lerpf(1.0, 2.5, _vb)
	if not reduced_motion:
		a += air(_t, 0.42 if outside(_p) else 0.16)
	var a_max := lerpf(A_MAX, V_A_MAX, _vb)
	if a.length() > a_max:
		a = a.normalized() * a_max
	_a = a
	_v += a * dt
	_move_kept(dt)
	_yaw_v += (-_stick.w * M_YAW * lerpf(1.0, 2.2, _vb) - _yaw_v) * (1.0 - exp(-dt * 9.0))
	_yaw += _yaw_v * dt
	_vit = _v.length()
	_acc = 0.0
	_attitude(a, dt)
	stats.manual_frames += 1


## The craft moved by its velocity, kept in bounds: what of its velocity ran into a bound is lost.
func _move_kept(dt: float) -> void:
	var to := _p + _v * dt
	var kept := keep_in(_p, to)
	var push := kept - to
	if push.length() > 1e-5:
		var nrm := push.normalized()
		var vn := _v.dot(nrm)
		if vn < 0.0:
			_v -= nrm * vn
		stats.kept += 1
	_p = kept


func _wing() -> Node:
	var wing := _obs.get_node_or_null("LibraryWing") if _obs != null else null
	return wing if wing != null and wing.has_method("fly") else null


func _gardens() -> Node:
	var g := _obs.get_node_or_null("PalaceGardens") if _obs != null else null
	return g if g != null and g.has_method("ground_at") else null


func _hall(key: String, fallback: float) -> float:
	var v: Variant = _obs.get(key) if _obs != null else null
	return float(v) if v != null else fallback


## The hall's obstacles as boxes, as the walking body finds them (walk_physics.gd _gather, _boxes): the
## piers, the pedestals, the door leaves, and the steel box with its roof's statues.
func _gather_obstacles() -> void:
	_obstacles.clear()
	if _obs == null:
		return
	for n in _obs.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		var id := String(m.name)
		if m.mesh == null or not (id == "Pedestal" or id == "DoorLeaf" or (id.begins_with("Pier") and id.trim_prefix("Pier").is_valid_int())
				or (id.begins_with("Plinth") and id.trim_prefix("Plinth").is_valid_int())):
			continue
		var xf := m.global_transform
		var bb := m.mesh.get_aabb()
		var c := xf * bb.get_center()
		var ax := xf.basis.x * bb.size.x * 0.5
		var az := xf.basis.z * bb.size.z * 0.5
		var h := Vector2(Vector2(ax.x, ax.z).length(), Vector2(az.x, az.z).length())
		if h.x > 1e-4 and h.y > 1e-4:
			var hy := absf((xf.basis.y * bb.size.y * 0.5).y)
			_obstacles.append([Vector2(c.x, c.z), Vector2(ax.x, ax.z) / h.x, Vector2(az.x, az.z) / h.y, h, c.y - hy, c.y + hy])
	var steel := _obs.get_node_or_null("SteelCube") as Node3D
	if steel != null:
		var size: Vector3 = steel.get("box_size")
		var o := steel.global_position
		_obstacles.append([Vector2(o.x, o.z), Vector2.RIGHT, Vector2.DOWN, Vector2(size.x, size.z) * 0.5 + Vector2(0.2, 0.2), o.y - 0.1, o.y + size.y + 1.2])
	_spring = _hall("column_height", 19.0) - 2.9
	_orrery.clear()
	for pivot in _obs.find_children("Orbit*", "Node3D", true, false):
		var body := (pivot as Node3D).get_node_or_null("Body") as MeshInstance3D
		if body != null:
			var sphere := body.mesh as SphereMesh
			_orrery.append([(pivot as Node3D).global_position, (pivot as Node3D).global_basis.y.normalized(), body.position.length(),
				sphere.radius if sphere != null else 0.3])
	_lift_at = Vector2.INF
	var lift := _obs.get_node_or_null("Lift")
	if lift != null and lift.get_script() != null:
		var c: Dictionary = (lift.get_script() as Script).get_script_constant_map()
		var a := TAU * (float(c.get("LIFT_BAY", 3)) + 0.5) / _hall("bay_count", 16.0)
		_lift_at = Vector2(cos(a), sin(a)) * float(c.get("AXIS_R", 16.1))


## Where p is: "hall" inside the drum, its oculus included; "wing" in a library wing; "out" outside.
func zone_of(p: Vector3) -> String:
	var rf := Vector2(p.x, p.z).length()
	if rf <= SHELF_FRONT + 0.05 and p.y < _hall("_ceiling_y", 20.8) + 4.1:
		return "hall"
	var wing := _wing()
	if wing != null:
		var q: Vector3 = wing.call("fly", p, 0.05)
		if q != Vector3.INF and q.distance_to(p) < 0.05:
			return "wing"
	return "out"


## Where the craft may go by hand, from `from` towards p, a body of M_BODY: in the hall within the
## shelves' fronts, over the floor and under the ceiling, off the galleries' walkways and rails, the
## piers and the steel box, and up through the oculus; in a library wing within its walls and vaults
## (library_wing.gd fly), entered and left through its portal; outside over the hall's roof and the
## gardens' ground, off its facade and the gardens' solids, back in through the oculus only.
func keep_in(from: Vector3, p: Vector3, r := M_BODY) -> Vector3:
	var ocu := _hall("oculus_radius", 5.0)
	var ceil_y := _hall("_ceiling_y", 20.8)
	var drum_top := ceil_y + 4.1
	var outer := _hall("outer_radius", 18.0)
	var wing := _wing()
	var where := zone_of(from)
	var flat := Vector2(p.x, p.z)
	var rf := flat.length()
	var y := p.y
	if where == "wing":
		var q: Vector3 = wing.call("fly", p, r) if wing != null else Vector3.INF
		if q != Vector3.INF:
			return Vector3(q.x, maxf(q.y, r + 0.05), q.z)
		return p if rf <= SHELF_FRONT - r else from  # out through its portal only
	if where == "hall":
		if rf > SHELF_FRONT - r:
			var q: Vector3 = wing.call("fly", p, r) if wing != null else Vector3.INF
			if q != Vector3.INF and y < ceil_y:
				return q  # into a wing, through its portal
			flat = flat.normalized() * (SHELF_FRONT - r)
			rf = SHELF_FRONT - r
		y = maxf(y, r + 0.05)
		if rf > ocu - r:
			y = minf(y, ceil_y - r)
		var g_in := _hall("colonnade_radius", 13.0) + 0.78
		var levels: Variant = _obs.get("gallery_levels") if _obs != null else null
		var rf0 := Vector2(from.x, from.z).length()
		if levels is PackedFloat32Array:
			for g: float in (levels as PackedFloat32Array):
				# The walkway from g_in - 0.3 to the shelves, its slab and gilded edge 0.62 m deep: out by the
				# least way.
				if rf > g_in - 0.3 - r and y > g - 0.62 - r and y < g + r:
					var up := g + r - y
					var down := y - (g - 0.62 - r)
					var inward := rf - (g_in - 0.3 - r)
					if inward < up and inward < down:
						flat = flat.normalized() * (g_in - 0.3 - r)
						rf = g_in - 0.3 - r
					elif up <= down:
						y = g + r
					else:
						y = g - 0.62 - r
				# The rail, 1.07 m high on its edge: a thin wall, crossed over its top.
				if y > g - 0.35 and y < g + 1.07 + r and absf(rf - g_in) < r + 0.03:
					rf = g_in - r - 0.03 if rf0 < g_in else g_in + r + 0.03
					flat = flat.normalized() * rf
		# The colonnade's capitals, arches and entablature: a ring 2 m thick from under the capitals up
		# to the ceiling, kept to the side the craft came from, or passed under.
		var col := _hall("colonnade_radius", 13.0)
		if y > _spring - 0.75 - r and absf(rf - col) < 1.0 + r:
			if y - (_spring - 0.75 - r) < 1.0 + r - absf(rf - col):
				y = _spring - 0.75 - r
			else:
				rf = col + (1.0 + r) * (1.0 if rf0 >= col else -1.0)
				flat = flat.normalized() * rf
		# The orrery in the oculus: each orbit's ring, with its body going round it, kept clear of.
		for o: Array in _orrery:
			var at := Vector3(flat.x, y, flat.y)
			var ax: Vector3 = o[1]
			var rel: Vector3 = at - (o[0] as Vector3)
			var q := rel - ax * rel.dot(ax)
			var on := q.normalized() if q.length() > 1e-4 else ax.cross(Vector3.RIGHT if absf(ax.x) < 0.9 else Vector3.UP).normalized()
			var ring: Vector3 = (o[0] as Vector3) + on * float(o[2])
			var keep := float(o[3]) + 0.05 + r
			var off := at - ring
			if off.length() < keep:
				at = ring + (off.normalized() if off.length() > 1e-4 else ax) * keep
				flat = Vector2(at.x, at.z)
				y = at.y
		# The lift's shaft, floor to ceiling.
		if _lift_at != Vector2.INF and flat.distance_to(_lift_at) < 1.25 + r:
			var away := flat - _lift_at
			flat = _lift_at + (away.normalized() if away.length() > 1e-4 else Vector2.RIGHT) * (1.25 + r)
			if flat.length() > SHELF_FRONT - r:
				flat = flat.normalized() * (SHELF_FRONT - r)
		for b: Array in _obstacles:
			var d: Vector2 = flat - (b[0] as Vector2)
			var u: Vector2 = b[1]
			var v: Vector2 = b[2]
			var h: Vector2 = b[3]
			var lu := d.dot(u)
			var lv := d.dot(v)
			if absf(lu) >= h.x + r or absf(lv) >= h.y + r or y <= float(b[4]) - r or y >= float(b[5]) + r:
				continue
			var outs := [h.x + r - absf(lu), h.y + r - absf(lv), float(b[5]) + r - y]
			var k := outs.find(outs.min())
			if k == 0:
				flat += u * signf(lu) * float(outs[0])
			elif k == 1:
				flat += v * signf(lv) * float(outs[1])
			else:
				y = float(b[5]) + r
		return Vector3(flat.x, y, flat.y)
	# Outside: down into the hall through the oculus only; elsewhere the hall's mass, a solid of turning
	# from its facade (outer + 0.65) up to the roof's lead (21.75 m at the oculus' drum, 21.15 at the eave,
	# 19.3 m out) and the drum round the oculus up to its top.
	if wing != null:
		var q: Vector3 = wing.call("fly", p, 0.05)
		if q != Vector3.INF and q.distance_to(p) < 0.05:
			return from  # not into a wing through its roof or walls
	if rf < 19.3 + r and not (rf < ocu - r):
		# The drum round the oculus with its cornice, then the lead.
		var top := drum_top + 0.6 if rf < ocu + 1.2 + r else lerpf(21.75, 21.15, clampf((rf - ocu - 1.2) / maxf(19.3 - ocu - 1.2, 0.1), 0.0, 1.0))
		var face := outer + 0.65
		var dir := flat.normalized() if rf > 1e-4 else Vector2.RIGHT
		if rf < face + r:
			# The facade and the roof: up over it, or off the facade, by the least.
			if y < top + r:
				if face + r - rf < top + r - y:
					flat = dir * (face + r)
				else:
					y = top + r
		elif y < top + r and y > top - 0.35 - r:
			# The eave's overhang, 0.35 m deep: over it, under it, or off its edge.
			var up := top + r - y
			var down := y - (top - 0.35 - r)
			var side := 19.3 + r - rf
			if side < up and side < down:
				flat = dir * (19.3 + r)
			elif up <= down:
				y = top + r
			else:
				y = top - 0.35 - r
	var gardens := _gardens()
	if gardens != null and rf > outer:
		var g0 := float(gardens.call("ground_at", flat))
		y = maxf(y, g0 + r + 0.05)
		if gardens.has_method("push_out") and y < g0 + 3.0:
			flat = gardens.call("push_out", flat, r, g0)
	flat = flat.limit_length(900.0)
	return Vector3(flat.x, minf(y, 160.0), flat.y)


func _craft_basis() -> Basis:
	return Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch) * Basis(Vector3.BACK, _roll)


## The craft as shown: its attitude, turned through a roll or a flip while one runs.
func _shown_basis() -> Basis:
	if _trick == "":
		return _craft_basis()
	var turn := TAU * smoothstep(0.0, 1.0, _trick_t / TRICK_TIME) * _trick_dir
	return _craft_basis() * Basis(Vector3.BACK if _trick == "roll" else Vector3.RIGHT, turn)


## A roll or a flip, on a straight only: none starts while a bend sharper than TRICK_CLEAR lies within
## the trick's flight and a little more. Only the craft as shown turns; its flight is the planned one.
func _tricks(dt: float) -> void:
	_trick_gap = maxf(0.0, _trick_gap - dt)
	if _trick != "":
		_trick_t += dt
		if _trick_t >= TRICK_TIME:
			_trick = ""
		return
	var sp := _v.length()
	if _vb < 0.9 or _trick_gap > 0.0 or sp < 4.0 or manual or _rejoin:
		return
	var ahead := sp * (TRICK_TIME + 0.3)
	var d := 0.0
	while d <= ahead:
		if curvature(_tour, _s + d) > TRICK_CLEAR:
			return
		d += 0.5
	var n := int(stats.tricks)
	_trick = "flip" if n % 3 == 2 else "roll"
	_trick_dir = 1.0 if n % 2 == 0 else -1.0
	_trick_t = 0.0
	_trick_gap = TRICK_GAP + 0.4 * float(n % 3)
	stats.tricks += 1


## The view: behind the craft and late on it, or on board on a gimbal.
func _aim(dt: float) -> void:
	var vh := Vector2(_v.x, _v.z).length()
	if view == "board":
		# A stabilised gimbal: the horizon stays level, which is what a gimbal is for, and the
		# pitch follows the climb late, as an operator's hand would. The craft's roll never reaches
		# it: that is why a drone's picture does not lean in bends while the drone does.
		var slope := atan2(_v.y, maxf(vh, 0.01))
		_site += (slope * 0.55 - _site) * (1.0 - exp(-dt * 2.2))
		var b := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _site)
		# Stunts: an FPV camera, fixed to the frame and tilted up, rolls and flips with the craft.
		if _vb > 0.0 and not reduced_motion:
			var fpv := _shown_basis() * Basis(Vector3.RIGHT, V_UPTILT)
			b = Basis(b.get_rotation_quaternion().slerp(fpv.get_rotation_quaternion(), _vb))
		_cam.global_transform = Transform3D(b, _p + _craft_basis() * Vector3(0.0, 0.011, -0.03))
		return
	# The chase: the eye aims at a place behind the craft's velocity, not its plan, and reaches it
	# late; that lag lets the craft slide across the frame in a bend. Faster behind the racer, or it
	# would trail metres behind.
	# By hand, behind the nose: sliding sideways or backing off, the view stays the pilot's.
	var nose := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var along := _v.normalized() if not manual and (vh > 0.08 or absf(_v.y) > 0.08) else nose
	if manual and absf(_v.y) > 0.3:
		along = (nose + Vector3(0.0, _v.y * 0.15, 0.0)).normalized()
	var back := Vector3(-along.x, -along.y * 0.3, -along.z).normalized()
	var to := _p + back * lerpf(CHASE_BACK, 0.6, _vb) + Vector3(0.0, CHASE_UP, 0.0)
	if _eye == Vector3.INF:
		_eye = to
	_eye = _eye.lerp(to, 1.0 - exp(-dt * lerpf(4.2, 11.0, _auth)))
	var look := _p + along * 0.22 - _eye
	var up := Vector3.UP if absf(look.normalized().y) < 0.97 else Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	_cam.global_transform = Transform3D(Basis.looking_at(look, up), _eye)


## Puts the craft flying s metres along the tour, steady, the view behind it: the cut from the hand,
## and tests.
func place_at(s: float, speed := 1.0) -> void:
	_s = fposmod(s, float(_tour.L))
	var p: Vector3 = path_at(_tour, _s)[0]
	var tg := ((path_at(_tour, _s + 0.3)[0] as Vector3) - p).normalized()
	_p = p
	_v = tg * speed
	_a = Vector3.ZERO
	_vit = speed
	_acc = 0.0
	_ref_prev = Vector3.INF
	_yaw = atan2(-tg.x, -tg.z)
	_yaw_v = 0.0
	_pitch = 0.0
	_pitch_v = 0.0
	_roll = 0.0
	_roll_v = 0.0
	_site = 0.0
	_eye = Vector3.INF
	_trick = ""
	_trick_gap = 0.0
	manual = false
	_rejoin = false


## A frame of flight and view, dt seconds, in steps the follower stays stable at.
func step(dt: float) -> void:
	var n := maxi(1, ceili(dt / SUB))
	for i in n:
		_t += dt / n
		if manual:
			_fly_manual(dt / n)
		else:
			_fly(dt / n)
	_tricks(dt)
	_aim(dt)
	_craft.global_transform = Transform3D(_shown_basis(), _p)
	stats.frames += 1
	stats.max_speed = maxf(float(stats.max_speed), _v.length())
	var tilt := rad_to_deg(acos(clampf((_craft_basis() * Vector3.UP).y, -1.0, 1.0)))
	stats.max_tilt_deg = maxf(float(stats.max_tilt_deg), tilt)


## The drone's state, for tests.
func state() -> Dictionary:
	return {"phase": _phase, "view": view, "s": _s, "p": _p, "v": _v, "eye": _cam.global_position if _cam != null else Vector3.ZERO,
		"tilt_deg": rad_to_deg(acos(clampf((_craft_basis() * Vector3.UP).y, -1.0, 1.0))), "busy": _busy}


# --- From the hand and back -------------------------------------------------------------------

## Takes off from where the held drone is (its transform in the world). In the corridor behind the
## steel box there is no sky: it stays in the hand. Returns whether it took off.
func launch(from: Transform3D) -> bool:
	if _phase != "idle" or _busy or _camera == null:
		return false
	var corridor := _obs.get_node_or_null("Multiverse")
	if corridor != null and bool(corridor.get("inside")):
		stats.refused += 1
		_note = _t_("no_sky")
		_note_t = 3.0
		return false
	stats.launches += 1
	_phase = "rise"
	_rise_t = 0.0
	_rise_from = Transform3D(Basis(Vector3.UP, _camera.global_basis.get_euler().y), from.origin)
	_craft.global_transform = _rise_from
	_craft.visible = true
	_spin = 0.0
	_put_aside()
	return true


## Lands it: the view cuts back to where you stood, the drone back in your hand.
func land() -> void:
	if _phase == "idle" or _busy:
		return
	_cut(_landed)


func _landed() -> void:
	_phase = "idle"
	voltige = false
	_vb = 0.0
	_trick = ""
	manual = false
	_rejoin = false
	_craft.visible = false
	_camera.make_current()
	_give_back()
	stats.landings += 1


func toggle_view() -> void:
	if _phase != "fly":
		return
	view = "board" if view == "chase" else "chase"
	_eye = Vector3.INF
	stats.views += 1
	_craft.visible = view == "chase"


## Through black: out, the change, back in.
func _cut(change: Callable) -> void:
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE)
	tw.tween_callback(change)
	tw.tween_property(_fade, "color:a", 0.0, FADE)
	tw.tween_callback(_cut_done)


func _cut_done() -> void:
	_busy = false


## While it flies, the visitor stands still and the interface steps aside: the walking body and the
## fly camera stop, every other layer hides, the pointer is freed for the buttons.
func _put_aside() -> void:
	_hidden_layers.clear()
	for n in _obs.find_children("*", "CanvasLayer", true, false):
		var l := n as CanvasLayer
		if l != _layer and l.visible:
			l.visible = false
			_hidden_layers.append(l)
	_paused.clear()
	var walker := _obs.get_node_or_null("WalkBody")
	for n: Node in [_camera, walker, walker.get_node_or_null("Early") if walker != null else null]:
		if n != null and n.is_processing():
			n.set_process(false)
			n.set_process_input(false)
			n.set_process_unhandled_input(false)
			_paused.append(n)
	_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _give_back() -> void:
	for l in _hidden_layers:
		if is_instance_valid(l):
			l.visible = true
	_hidden_layers.clear()
	for n in _paused:
		if is_instance_valid(n):
			n.set_process(true)
			n.set_process_input(true)
			n.set_process_unhandled_input(true)
	_paused.clear()
	Input.mouse_mode = _mouse_mode
	var curio := _obs.get_node_or_null("CurioWheel")
	if curio != null:
		curio.set("_raise", 0.0)  # back in the hand, raised into view


func _input(event: InputEvent) -> void:
	if _phase == "idle":
		return
	# Every key, click and touch is the drone's while it flies: nothing reaches the visitor.
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_ESCAPE:
			land()
		elif code == KEY_V:
			toggle_view()
	# A touch screen's tap also comes as an emulated click: one of the two, or a button toggles twice.
	var mb := event as InputEventMouseButton
	if not touch and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_press(mb.position)
	var tt := event as InputEventScreenTouch
	if touch and tt != null and tt.pressed:
		_press(tt.position)
	get_viewport().set_input_as_handled()


func _press(pos: Vector2) -> void:
	var b := _buttons()
	if (b.view as Rect2).has_point(pos):
		toggle_view()
	elif (b.land as Rect2).has_point(pos):
		land()


# --- Every frame ------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var lib := _obs.get_node_or_null("Generated/CourseShelves") if _obs != null else null
	if lib != null:
		lang = str(lib.get("lang"))
	if _note_t > 0.0:
		_note_t -= delta
	_ui.visible = _phase != "idle" or _note_t > 0.0
	_ui.queue_redraw()
	if _phase == "rise":
		_rise(delta)
	elif _phase == "fly":
		# Stunts while Shift is held (a key only: a touch screen's stick sends Shift to walk faster).
		voltige = voltige_hold or (not touch and not _busy and Input.is_physical_key_pressed(KEY_SHIFT))
		_vb = move_toward(_vb, 1.0 if voltige else 0.0, delta / BLEND)
		_hands(delta)
		step(delta)
		# Behind it, a narrower field than the visitor's, so that nine centimetres read at 40; wider
		# behind the racer, for the speed.
		_cam.fov = minf(_camera.fov, lerpf(CHASE_FOV, V_CHASE_FOV, _vb)) if view == "chase" else _camera.fov
		_cam.near = _camera.near
		_cam.far = _camera.far
	_spin = move_toward(_spin, 1.0 if _phase != "idle" else 0.0, delta / RISE)
	_spin_rotors(delta)
	_sound()


## From the hand: the rotors spin up, it lifts a third of a metre and drifts forward, watched from
## where you stand, in sight; then the view cuts to it on its tour, at the tour's nearest place.
func _rise(delta: float) -> void:
	_rise_t += delta
	var k := smoothstep(0.0, 1.0, _rise_t / RISE)
	var lift := smoothstep(0.25, 1.0, _rise_t / RISE)
	var fwd := -_rise_from.basis.z
	var wobble := Vector3(sin(_rise_t * 7.0), 0.0, cos(_rise_t * 5.0)) * 0.006 * lift
	var at := _rise_from.origin + Vector3.UP * 0.35 * lift + fwd * 0.6 * k + wobble
	_craft.global_transform = Transform3D(_rise_from.basis * Basis(Vector3.RIGHT, -0.12 * k * (1.0 - k) * 4.0), at)
	if _rise_t >= RISE and not _busy:
		_cut(_flying)


func _flying() -> void:
	place_at(_nearest(_camera.global_position), 1.0)
	_phase = "fly"
	view = "chase"
	_craft.visible = true
	_cam.make_current()
	step(1.0 / 60.0)


## The tour's place nearest p, inside if p is inside.
func _nearest(p: Vector3) -> float:
	var P: PackedVector3Array = _tour.P
	var S: PackedFloat32Array = _tour.S
	var best := 0.0
	var dist := INF
	var inside := not outside(p)
	for i in P.size():
		if inside and outside(P[i]):
			continue
		var d := P[i].distance_squared_to(p)
		if d < dist:
			dist = d
			best = S[i]
	return best


func _spin_rotors(delta: float) -> void:
	if not _craft.visible:
		return
	for i in 4:
		var dir := 1.0 if i % 3 == 0 else -1.0  # diagonal pairs turn the same way
		_rotors[i].rotate_y(dir * delta * TAU * lerpf(0.0, 9.0, _spin))
		_blades[i].visible = _spin < 0.5
		_blurs[i].visible = _spin > 0.2
		(_blurs[i].material_override as StandardMaterial3D).albedo_color.a = 0.32 * smoothstep(0.2, 0.8, _spin)


func _sound() -> void:
	if _hum == null:
		return
	var thrust := (_a + Vector3(0.0, G, 0.0)).length() / G if _phase == "fly" else 1.0
	# 12 dB under what it was (-9), and its pitch following thrust and speed half as far, so that it
	# stays even in flight (the author, 2026-10-12).
	_hum_loop.call("run", _spin > 0.01,
		clampf((0.35 + 0.65 * _spin) * (0.97 + 0.06 * (thrust - 1.0) * 4.0 + 0.025 * _vit / CRUISE), 0.3, 1.3),
		lerpf(HUSH, -21.0 + 6.0 * _vb, minf(1.0, _spin * 1.5)))


# --- On screen --------------------------------------------------------------------------------

func _make_ui() -> void:
	# Over the curio wheel (40): the flight has the screen.
	_layer = CanvasLayer.new()
	_layer.layer = 45
	add_child(_layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.visible = false
	_ui.draw.connect(_draw_ui)
	_layer.add_child(_ui)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0, 0, 0, 0)
	_layer.add_child(_fade)


## The two buttons, centred at the bottom: the other view, and land.
func _buttons() -> Dictionary:
	var size := _ui.get_viewport_rect().size
	var u := minf(size.x, size.y)
	var h := clampf(u * (0.11 if touch else 0.07), 40.0, 96.0)
	var font := ThemeDB.fallback_font
	var fs := roundi(h * 0.36)
	var other := _t_("board" if view == "chase" else "chase")
	var w1 := font.get_string_size(other, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + h * 0.9
	var w2 := font.get_string_size(_t_("land"), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + h * 0.9
	var gap := h * 0.3
	var x := size.x * 0.5 - (w1 + gap + w2) * 0.5
	var y := size.y - h - maxf(16.0, h * 0.4)
	return {"view": Rect2(x, y, w1, h), "land": Rect2(x + w1 + gap, y, w2, h), "fs": fs, "other": other}


func _draw_ui() -> void:
	var gilt := Color(0.86, 0.7, 0.42)
	var lacquer := Color(0.035, 0.03, 0.028, 0.82)
	var font := ThemeDB.fallback_font
	var size := _ui.get_viewport_rect().size
	var u := minf(size.x, size.y)
	if _note_t > 0.0 and _phase == "idle":
		var fs0 := roundi(clampf(u * 0.035, 14.0, 30.0))
		var w0 := font.get_string_size(_note, HORIZONTAL_ALIGNMENT_LEFT, -1, fs0).x
		var a0 := clampf(_note_t / 0.6, 0.0, 1.0)
		var box := Rect2(size.x * 0.5 - w0 * 0.5 - fs0, size.y * 0.72 - fs0, w0 + fs0 * 2.0, fs0 * 2.0)
		_ui.draw_rect(box, Color(lacquer, lacquer.a * a0))
		_ui.draw_string(font, Vector2(box.position.x + fs0, box.get_center().y + fs0 * 0.35), _note, HORIZONTAL_ALIGNMENT_LEFT, -1, fs0, Color(gilt, a0))
		return
	if _phase != "fly":
		return
	# Top left: what it is and which view; bottom: the buttons, and the keys on a computer.
	var fs := roundi(clampf(u * 0.03, 13.0, 26.0))
	var caption := _t_("title") + "  ·  " + _t_(view)
	if manual:
		caption += "  ·  " + _t_("manual")
	elif _auto_t > 0.0:
		caption += "  ·  " + _t_("auto")
	if _vb > 0.0:
		caption += "  ·  " + _t_("voltige") + "  %d km/h" % roundi(_v.length() * 3.6)
	var cw := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var m := maxf(16.0, u * 0.025)
	_ui.draw_rect(Rect2(m, m, cw + fs * 1.4, fs * 2.0), lacquer)
	_ui.draw_string(font, Vector2(m + fs * 0.7, m + fs * 1.35), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		gilt.lerp(Color(1.0, 0.42, 0.2), _vb))
	var b := _buttons()
	var bfs: int = b.fs
	var mouse := _ui.get_viewport().get_mouse_position()
	for k: String in ["view", "land"]:
		var r: Rect2 = b[k]
		var over := not touch and r.has_point(mouse)
		_ui.draw_rect(r, Color(gilt.darkened(0.35), 0.9) if over else lacquer)
		_ui.draw_rect(r, Color(gilt, 0.9), false, maxf(1.5, r.size.y * 0.035))
		var label: String = b.other if k == "view" else _t_("land")
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x
		_ui.draw_string(font, Vector2(r.get_center().x - w * 0.5, r.get_center().y + bfs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs, Color(0.97, 0.94, 0.87))
	if not touch:
		# The sticks' keys over the others: whoever holds the sticks sees how to let go.
		var top := (b.view as Rect2).position.y - fs * 1.9
		for keys: String in [_t_("keys"), _t_("hand")]:
			var kfs := fs
			var kw := font.get_string_size(keys, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs).x
			if kw > size.x - 2.0 * m:
				kfs = maxi(10, floori(kfs * (size.x - 2.0 * m) / kw))
				kw = font.get_string_size(keys, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs).x
			_ui.draw_rect(Rect2(size.x * 0.5 - kw * 0.5 - kfs * 0.6, top - kfs * 0.2, kw + kfs * 1.2, kfs * 1.6), Color(lacquer, 0.6))
			_ui.draw_string(font, Vector2(size.x * 0.5 - kw * 0.5, top + kfs * 1.0), keys, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs, Color(0.88, 0.85, 0.78))
			top -= fs * 1.75


# --- The model and its sound ------------------------------------------------------------------

## The nine-centimetre quadcopter, as the artifact's: a dark chassis and canopy, four arms, four
## motors, four rotors (two blades each, a pale disc when they spin; the front pair gilt-tipped, as a
## drone's front props are marked to tell which way it goes), a lens under the nose, and its
## position lights: green to starboard, red to port, white behind. Nose towards -z, as a camera's.
static func build_model() -> Node3D:
	var root := Node3D.new()
	root.name = "Drone"
	root.set_meta("pose", Vector3(0.15, -0.15, -0.34))
	root.set_meta("held_scale", 1.0)  # its own size in the hand: it takes off from there
	# Graphite rather than black: in the hall's half light a black craft was a hole in the picture.
	var chassis := _mat(Color(0.2, 0.205, 0.22), 0.35, 0.34)
	var canopy := _mat(Color(0.3, 0.31, 0.33), 0.4, 0.22)
	var arm := _mat(Color(0.15, 0.155, 0.165), 0.3, 0.32)
	var motor := _mat(Color(0.3, 0.31, 0.33), 0.8, 0.18)
	var blade := _mat(Color(0.2, 0.21, 0.23), 0.0, 0.3)
	var tip := _mat(Color(0.86, 0.7, 0.42), 1.0, 0.25)
	var lens := _mat(Color(0.1, 0.14, 0.2), 0.5, 0.06)
	var gilt := _mat(Color(0.88, 0.72, 0.4), 1.0, 0.22)
	var body := BoxMesh.new()
	body.size = Vector3(0.038, 0.0115, 0.052)
	_part(root, body, chassis, Vector3(0, 0.00575, 0))
	var shell := SphereMesh.new()
	shell.radius = 0.019
	shell.height = 0.019
	shell.is_hemisphere = true
	shell.radial_segments = 24
	shell.rings = 8
	_part(root, shell, canopy, Vector3(0, 0.0115, -0.002), Vector3.ZERO, Vector3(0.82, 0.42, 1.0))
	var band := TorusMesh.new()
	band.inner_radius = 0.0148
	band.outer_radius = 0.0158
	band.rings = 32
	band.ring_segments = 6
	_part(root, band, gilt, Vector3(0, 0.0117, -0.002), Vector3.ZERO, Vector3(0.82, 1.0, 1.0))
	for i in 4:
		var sx := 1.0 if i % 2 == 0 else -1.0
		var sz := -1.0 if i < 2 else 1.0
		var from := Vector3(sx * 0.012, 0.0055, sz * 0.014)
		var to := Vector3(sx * 0.034, 0.0075, sz * 0.034)
		var tube := CylinderMesh.new()
		tube.top_radius = 0.0034
		tube.bottom_radius = 0.0034
		tube.height = from.distance_to(to)
		tube.radial_segments = 10
		tube.rings = 1
		var mid := (from + to) * 0.5
		var mi := _part(root, tube, arm, mid)
		mi.basis = Basis(Quaternion(Vector3.UP, (to - from).normalized()))
		var can := CylinderMesh.new()
		can.top_radius = 0.0072
		can.bottom_radius = 0.0072
		can.height = 0.0095
		can.radial_segments = 16
		can.rings = 1
		_part(root, can, motor, Vector3(to.x, 0.01025, to.z))
		var rotor := Node3D.new()
		rotor.name = "Rotor%d" % i
		rotor.position = Vector3(to.x, 0.0155, to.z)
		root.add_child(rotor)
		var blades := Node3D.new()
		blades.name = "Blades"
		rotor.add_child(blades)
		for side in [-1.0, 1.0]:
			var vane := BoxMesh.new()
			vane.size = Vector3(0.023, 0.0007, 0.0055)
			_part(blades, vane, blade, Vector3(side * 0.0125, 0, 0), Vector3(side * 8.0, 0, 0))
			if sz < 0.0:
				var mark := BoxMesh.new()
				mark.size = Vector3(0.004, 0.0009, 0.0056)
				_part(blades, mark, tip, Vector3(side * 0.0225, 0, 0))
		var disc := CylinderMesh.new()
		disc.top_radius = 0.025
		disc.bottom_radius = 0.025
		disc.height = 0.0004
		disc.radial_segments = 24
		disc.rings = 1
		var blur := _mat(Color(0.86, 0.7, 0.42, 0.3) if sz < 0.0 else Color(0.55, 0.57, 0.6, 0.3), 0.0, 0.5)
		blur.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		blur.cull_mode = BaseMaterial3D.CULL_DISABLED
		var bm := _part(rotor, disc, blur, Vector3.ZERO)
		bm.name = "Blur"
		bm.visible = false
	var eye := CylinderMesh.new()
	eye.top_radius = 0.0044
	eye.bottom_radius = 0.0044
	eye.height = 0.005
	eye.radial_segments = 16
	eye.rings = 1
	_part(root, eye, lens, Vector3(0, 0.0072, -0.0265), Vector3(90, 0, 0))
	# Position lights: unshaded, so they read in a dark hall without adding a light.
	var bulb := SphereMesh.new()
	bulb.radius = 0.0022
	bulb.height = 0.0044
	bulb.radial_segments = 8
	bulb.rings = 4
	for l: Array in [[Vector3(0.034, 0.0035, -0.034), Color(0.1, 1.0, 0.3)], [Vector3(-0.034, 0.0035, -0.034), Color(1.0, 0.12, 0.12)],
			[Vector3(0.034, 0.0035, 0.034), Color(0.75, 0.75, 0.7)], [Vector3(-0.034, 0.0035, 0.034), Color(0.75, 0.75, 0.7)]]:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = l[1]
		_part(root, bulb, m, l[0])
	return root


static func _mat(c: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m


static func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## The hum where the take is not in the build: the rotors' line and its harmonics, steady (no beating
## between rotors, no tremolo: the author, 2026-10-12, wanted it even), a second's loop whose every
## partial completes whole cycles. Made here.
static func _hum_stream() -> AudioStreamWAV:
	var rate := 22050
	var n := rate
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var f := 188.0  # even, so that its sub-octave too completes whole cycles in the second
		var v := sin(TAU * 0.5 * f * t) * 0.25 + sin(TAU * f * t) + sin(TAU * 2.0 * f * t + 1.1) * 0.56 \
			+ sin(TAU * 3.0 * f * t + 2.3) * 0.28 + sin(TAU * 4.0 * f * t + 0.4) * 0.18 + sin(TAU * 1975.0 * t) * 0.14
		v *= 0.12
		data.encode_s16(i * 2, clampi(roundi(v * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav
