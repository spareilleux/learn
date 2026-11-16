extends Node
## Preset views (keys 1 to 7, the Views button on touch screens): fly_camera.gd cuts to the new
## view in one frame. This node turns the cut into a short flight, after the character switch in
## Grand Theft Auto V: the camera lifts off, tilts down over the hall and settles on the new view,
## widening its field on the way. 1.4 to 2.4 s, by distance, paced along the path's length so
## that it gathers speed and slows evenly, the view turning over nearly all of it; a slow frame
## (a phone) slows the flight rather than skipping part of it. Only the picture moves: between two
## frames the camera holds the new view again, so the walking body, the controls, the catalogue and
## the tests see exactly what they saw before (the same trick as view_fit.gd).
##
## A cut is any move of more than MIN_JUMP metres in one frame: walking or flying never goes that
## far. A player who asks for less motion (prefers-reduced-motion, --reduced-motion, ?motion=reduce)
## keeps the cut. On by default in the web build; --moves turns it on natively (tests and captures
## otherwise stay as they were), ?moves=off or --moves=off turns it off, and ?moveslow=<n> makes a
## flight last n times longer, for captures (artpass/motion/moves-web.mjs).

const MIN_JUMP := 2.5    ## metres in one frame
const TILT := 26.0       ## degrees the camera looks down at the top of the flight
const WIDEN := 9.0       ## degrees the field opens at the top of the flight
const LIFT_MAX := 6.0    ## metres above the straight line, at most
const CEILING_GAP := 3.5 ## metres the flight stays under the vault
const GRACE := 1.0       ## seconds after start-up when a jump is the page placing the camera
const MAX_STEP := 0.1    ## seconds a flight advances in one frame, at most
const ARC_SAMPLES := 48  ## points along the path to measure its length

var enabled := false
var reduced := false
var slow := 1.0
var moves := 0  ## flights started, for tests
var _camera: Camera3D
var _top := 16.0
var _age := 0.0
var _have := false
var _last := Transform3D()
var _last_fov := 0.0
var _t := -1.0           # seconds into the flight, below zero when there is none
var _dur := 1.0
var _from := Transform3D()
var _from_fov := 0.0
var _drawn := Transform3D()
var _drawn_fov := 0.0
var _true := Transform3D()
var _true_fov := 0.0
var _cut := false


## The next jump is a cut, not a flight: a teleport that is not a preset (scripts/multiverse.gd).
func cut() -> void:
	_cut = true
	_t = -1.0


func configure(camera: Camera3D, ceiling_y: float) -> void:
	_camera = camera
	_top = ceiling_y - CEILING_GAP


func _ready() -> void:
	# After the camera, the walking body and the touch controls, before view_fit.gd (900), which
	# must fit the field this node draws with; created after it too, so that its restore runs first.
	process_priority = 880
	var args := OS.get_cmdline_user_args()
	enabled = OS.has_feature("web") or args.has("--moves")
	if args.has("--moves=off"):
		enabled = false
	reduced = args.has("--reduced-motion")
	if OS.has_feature("web"):
		var q := "new URLSearchParams(location.search)"
		if str(JavaScriptBridge.eval(q + ".get('moves') || ''", true)) == "off":
			enabled = false
		slow = clampf(float(str(JavaScriptBridge.eval(q + ".get('moveslow') || '1'", true))), 1.0, 50.0)
		reduced = reduced or str(JavaScriptBridge.eval(q + ".get('motion') || ''", true)) == "reduce" \
			or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	get_tree().process_frame.connect(_restore)


func is_moving() -> bool:
	return _t >= 0.0


## Before any node processes: the camera takes back its own pose, component by component, unless
## something (a look drag, a key) changed that component since this node drew.
func _restore() -> void:
	if _camera == null or not is_moving():
		return
	if _camera.position.is_equal_approx(_drawn.origin):
		_camera.position = _true.origin
	if _camera.basis.is_equal_approx(_drawn.basis):
		_camera.basis = _true.basis
	if is_equal_approx(_camera.fov, _drawn_fov):
		_camera.fov = _true_fov


func _process(delta: float) -> void:
	if _camera == null:
		return
	_age += delta
	var pose := _camera.transform
	var fov := _camera.fov
	if not _have:
		_have = true
		_last = pose
		_last_fov = fov
		return
	var jump := pose.origin.distance_to(_last.origin)
	if jump > MIN_JUMP and _cut:
		_cut = false
	elif jump > MIN_JUMP and enabled and not reduced and _age > GRACE:
		# From wherever the picture is now: the last view, or the middle of a flight.
		_from = _drawn if is_moving() else _last
		_from_fov = _drawn_fov if is_moving() else _last_fov
		_t = 0.0
		_dur = clampf(1.1 + 0.045 * _from.origin.distance_to(pose.origin), 1.4, 2.4) * slow
		moves += 1
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__obsMoves = %d; window.__obsMoveSeconds = %f" % [moves, _dur / slow], true)
	_last = pose
	_last_fov = fov
	if not is_moving():
		return
	_t += minf(delta, MAX_STEP)
	var s := _t / _dur
	if s >= 1.0:
		_t = -1.0
		return
	_true = pose
	_true_fov = fov
	_drawn = _flight(_from, pose, s)
	_drawn_fov = lerpf(_from_fov, fov, _ease(s)) + WIDEN * pow(sin(PI * s), 2.0)
	_camera.transform = _drawn
	_camera.fov = _drawn_fov


## The pose s of the way (0 to 1, in time) from a to b: a cubic lifted above the straight line,
## eased along its length, the view turning from one to the other and looking down most at the top.
func _flight(a: Transform3D, b: Transform3D, s: float) -> Transform3D:
	var d := a.origin.distance_to(b.origin)
	var lift := clampf(0.3 * d, 1.5, LIFT_MAX)
	var c0 := a.origin + Vector3.UP * lift
	var c1 := b.origin + Vector3.UP * lift
	c0.y = minf(c0.y, maxf(a.origin.y, _top))
	c1.y = minf(c1.y, maxf(b.origin.y, _top))
	var p := _bezier(a.origin, c0, c1, b.origin, _along(a.origin, c0, c1, b.origin, _ease(s)))
	var turn := _ease(clampf((s - 0.04) / 0.92, 0.0, 1.0))
	var q := a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(), turn)
	var tilt := -deg_to_rad(TILT) * pow(sin(PI * s), 2.0)
	var basis := Basis(q) * Basis(Vector3.RIGHT, tilt)
	return Transform3D(basis.orthonormalized(), p)


static func _bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var v := 1.0 - u
	return p0 * v * v * v + p1 * 3.0 * v * v * u + p2 * 3.0 * v * u * u + p3 * u * u * u


## The cubic's parameter at the fraction f of its length, from ARC_SAMPLES chords: its parameter
## runs fastest where its control points pull it, and paced by the parameter alone the flight
## raced through its middle.
static func _along(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, f: float) -> float:
	var lengths := PackedFloat32Array()
	lengths.resize(ARC_SAMPLES + 1)
	var prev := p0
	var total := 0.0
	for k in range(1, ARC_SAMPLES + 1):
		var q := _bezier(p0, p1, p2, p3, float(k) / ARC_SAMPLES)
		total += prev.distance_to(q)
		lengths[k] = total
		prev = q
	if total <= 0.0:
		return f
	var want := clampf(f, 0.0, 1.0) * total
	for k in range(1, ARC_SAMPLES + 1):
		if lengths[k] >= want:
			var span := lengths[k] - lengths[k - 1]
			var w := (want - lengths[k - 1]) / span if span > 0.0 else 0.0
			return (float(k - 1) + w) / ARC_SAMPLES
	return 1.0


static func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * x * (x * (6.0 * x - 15.0) + 10.0)
