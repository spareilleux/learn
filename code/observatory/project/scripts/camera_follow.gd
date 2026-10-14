extends Node
## Moving captures (artpass/motion/): with ?follow=1 in the page's address, the camera takes the
## pose a capture harness writes into window.__obsCam each frame, [seq, x, y, z, yaw, pitch] in
## metres and degrees, and this node answers window.__obsCamShown = seq once the camera is there.
## The harness then waits for the frame to reach the screen and captures it: every frame of a
## path is rendered from exactly the pose asked for, however slow the capture. The walking body
## pauses meanwhile, so neither its bob nor its collisions move the camera. It also publishes the
## camera's field of view and aspect mode in window.__obsCamInfo. With ?freeze=1 as well, the
## scene's time stops at the first pose (Engine.time_scale 0: the rain, the orrery and the shaders'
## TIME), so what changes between two frames is the camera alone. observatory.gd adds this node
## only when asked; it costs nothing otherwise.

var _camera: Camera3D
var _walk: Node
var _seq := -INF
var _freeze := false


func configure(camera: Camera3D, walk: Node) -> void:
	_camera = camera
	_walk = walk


func _ready() -> void:
	process_priority = 1000  # after the camera's own moves and the walking body
	if _walk != null:
		_walk.process_mode = Node.PROCESS_MODE_DISABLED
	var move := get_parent().get_node_or_null("ViewMove")
	if move != null:
		move.set("enabled", false)  # a path's first pose is a jump, not a preset
	if OS.has_feature("web"):
		_freeze = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('freeze') || ''", true)) == "1"


func _process(_delta: float) -> void:
	if _camera == null or not OS.has_feature("web"):
		return
	var raw := str(JavaScriptBridge.eval("JSON.stringify(window.__obsCam || null)", true))
	var pose: Variant = JSON.parse_string(raw)
	if not pose is Array or (pose as Array).size() != 6:
		return
	var p: Array = pose
	if float(p[0]) == _seq:
		return
	_seq = float(p[0])
	if _freeze:
		Engine.time_scale = 0.0
	_camera.global_position = Vector3(float(p[1]), float(p[2]), float(p[3]))
	_camera.set("_yaw", deg_to_rad(float(p[4])))
	_camera.set("_pitch", deg_to_rad(float(p[5])))
	_camera.rotation = Vector3(deg_to_rad(float(p[5])), deg_to_rad(float(p[4])), 0.0)
	var size := get_viewport().get_visible_rect().size
	JavaScriptBridge.eval("window.__obsCamInfo = %s; window.__obsCamShown = %s" % [JSON.stringify({
		"fov": _camera.fov, "keep_aspect": "height" if _camera.keep_aspect == Camera3D.KEEP_HEIGHT else "width",
		"viewport": [size.x, size.y], "frozen": Engine.time_scale == 0.0}), JSON.stringify(_seq)], true)
