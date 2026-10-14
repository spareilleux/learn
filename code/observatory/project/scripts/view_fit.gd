extends Node
## Portrait screens. The camera keeps its height (Camera3D.KEEP_HEIGHT): its fov is vertical, the
## same 64 degrees at the overview on every screen, and the screen's width decides the rest. A
## computer or a phone held sideways then sees 96 to 107 degrees across, but a phone held upright
## 32 and a tablet 47: a slot of shelf and no room to turn in (artpass/motion/NOTES.md). This node
## widens the vertical field on narrow screens until the horizontal one reaches MIN_H, and stops at
## MAX_V, past which the top and bottom of the picture stretch. Screens wider than about 0.92:1
## keep the fov they are given.
##
## Everything else goes on reading and writing the camera's fov as before (the presets in
## fly_camera.gd, the sprint kick in walk_physics.gd): the fitted value is set after every node has
## processed, and the one they set comes back before any of them runs, unless one of them set a new
## one meanwhile, which then counts. ?fit=off in the page's address, or --fit=off, turns it off.
## While the walking body reads a book's spine, it sets the fov the screen shows itself, from and
## back to the fitted one (walk_physics.gd holds_fov, fitted), and this node leaves it.
## `zoom` magnifies whatever the screen would show by its inverse (the curio wheel's monocle,
## scripts/curio_wheel.gd, eases it between 1 and 0.4; the telescope, scripts/telescope.gd, down to
## 0.01); it applies with ?fit=off too.

const MIN_H := 60.0  ## degrees across that a narrow screen is widened to
const MAX_V := 90.0  ## but never more than this many degrees from top to bottom

var enabled := true
## Tests set the screen's width over height here instead of resizing the window.
var aspect_override := 0.0
## 1: the field as fitted; below 1, magnified by 1 / zoom (tan of the half angle).
var zoom := 1.0
var _camera: Camera3D
var _given := -1.0   # the fov the others set, which this node restores before they run
var _fitted := -1.0  # the one it set for the frame


func configure(camera: Camera3D) -> void:
	_camera = camera


## The vertical fov a camera that keeps its height should use on a screen of this aspect (width
## over height) when it was given `given`.
static func fit(given: float, aspect: float) -> float:
	if aspect <= 0.0:
		return given
	var h := rad_to_deg(2.0 * atan(tan(deg_to_rad(given) * 0.5) * aspect))
	if h >= MIN_H:
		return given
	var v := rad_to_deg(2.0 * atan(tan(deg_to_rad(MIN_H) * 0.5) / aspect))
	return clampf(v, given, maxf(given, MAX_V))


func _ready() -> void:
	process_priority = 900  # after the camera, the walking body and the touch controls
	for arg in OS.get_cmdline_user_args():
		if arg == "--fit=off":
			enabled = false
	if OS.has_feature("web"):
		enabled = enabled and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('fit') || ''", true)) != "off"
	get_tree().process_frame.connect(_restore)


func _restore() -> void:
	if _camera != null and _fitted > 0.0 and is_equal_approx(_camera.fov, _fitted):
		_camera.fov = _given
	_fitted = -1.0


func _process(_delta: float) -> void:
	if _camera == null:
		return
	var walker := get_parent().get_node_or_null("WalkBody") if get_parent() != null else null
	var held := walker != null and walker.has_method("holds_fov") and bool(walker.call("holds_fov"))
	_given = _camera.fov
	var f := _given if held else fitted(_given)
	if zoom < 0.999:
		f = rad_to_deg(2.0 * atan(tan(deg_to_rad(f) * 0.5) * zoom))
	if not is_equal_approx(f, _given):
		if f < 1.0:
			# Camera3D.fov refuses less than a degree (set_fov's check), set_perspective does not: the
			# telescope's x100 (scripts/telescope.gd) is 0.66 degrees.
			_camera.set_perspective(f, _camera.near, _camera.far)
		else:
			_camera.fov = f
		_fitted = f


## The fov the screen shows when the others set `given`.
func fitted(given: float) -> float:
	if _camera == null or not enabled or _camera.keep_aspect != Camera3D.KEEP_HEIGHT:
		return given
	return fit(given, _aspect())


func _aspect() -> float:
	if aspect_override > 0.0:
		return aspect_override
	var size := get_viewport().get_visible_rect().size
	return size.x / maxf(1.0, size.y)


## Degrees across and from top to bottom that the camera shows now, for tests and captures.
func field() -> Vector2:
	if _camera == null:
		return Vector2.ZERO
	var size := get_viewport().get_visible_rect().size
	var aspect := aspect_override if aspect_override > 0.0 else size.x / maxf(1.0, size.y)
	return Vector2(rad_to_deg(2.0 * atan(tan(deg_to_rad(_camera.fov) * 0.5) * aspect)), _camera.fov)
