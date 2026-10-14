extends Node
## The multiverse corridor behind the steel box's door, after Blake Crouch's Dark Matter but our own:
## a double-click on the box (a double tap on a touch screen) fades into a corridor of identical
## steel doors that never ends, lit only by the lantern one carries. Each door lets out the light of
## another world, through its small window and under its leaf (assets/world_glimpse.gdshader), and
## each has its number. The way back is always obvious: the Leave button (bottom centre on a
## computer, under the Courses button on a touch screen), Esc, or the lit doorway one came in by,
## which stays behind the visitor.
##
## The corridor stands far outside the hall, on the same floor level, so the walking body walks it
## as it walks the hall (walk_physics.gd takes this node as its region: walls instead of shelves).
## Only a stretch of SPAN metres exists; it slides along with the visitor by whole door pitches,
## and the dark does the rest. The hall is hidden meanwhile, and the environment turned to black
## fog; both come back on leaving. ?corridor=1 or --corridor enters at start-up, for captures.

signal entered
signal left

const ORIGIN := Vector3(0.0, 0.0, 1000.0)  ## the exit wall's centre, on the floor
const WIDTH := 2.4
const HEIGHT := 3.1
const PITCH := 3.2          ## metres between two doors on the same side
const SPAN := 64.0          ## metres of corridor that exist at a time, centred on the visitor
const LEFT_Z := -1.0        ## a left door every PITCH from here (the exit wall is at 0)
const RIGHT_Z := -2.6
const DOOR := Vector2(1.0, 2.2)
const EXIT := Vector2(1.4, 2.5)
const START := Vector3(0.0, 1.7, -2.2)
const RADIUS := 0.3         ## the walking body's radius (walk_physics.gd)
const DOUBLE := 0.4         ## seconds between the two clicks or taps of a double
const HOVER_REACH := 16.0   ## metres within which aiming at the box shows the hint
const FADE_OUT := 0.3
const FADE_IN := 0.55
const GLIMPSE_SHADER := "res://assets/world_glimpse.gdshader"

const TEXT := {
	"en": {"leave": "Leave the corridor", "inside": "Every door opens on another world  ·  Esc or the lit door behind you: back to the Observatory",
		"hover": "Double-click the box to step inside", "hover_touch": "Double-tap the box to step inside", "exit": "OBSERVATORY"},
	"fr": {"leave": "Quitter le couloir", "inside": "Chaque porte ouvre sur un autre monde  ·  Échap ou la porte éclairée derrière toi : retour à l’Observatoire",
		"hover": "Double-clique sur la boîte pour y entrer", "hover_touch": "Touche deux fois la boîte pour y entrer", "exit": "OBSERVATOIRE"},
	"es": {"leave": "Salir del pasillo", "inside": "Cada puerta da a otro mundo  ·  Esc o la puerta iluminada a tu espalda: vuelta al Observatorio",
		"hover": "Haz doble clic en la caja para entrar", "hover_touch": "Toca dos veces la caja para entrar", "exit": "OBSERVATORIO"},
}

var inside := false
var reduced := false
var touch := false
var lang := "en"
var stats := {"entries": 0, "exits": 0, "slides": 0, "doors": 0, "hover": false}

var _obs: Node3D
var _camera: Camera3D
var _cube: Node3D
var _walk: Node
var _move: Node
var _root: Node3D
var _slide: Node3D
var _lantern: OmniLight3D
var _plates: Array[Label3D] = []
var _exit_label: Label3D
var _hidden: Array[Node3D] = []
var _env_saved := {}
var _radius_saved := -1.0
var _ui: CanvasLayer
var _fade: ColorRect
var _bar: VBoxContainer
var _leave: Button
var _inside_label: Label
var _hover_label: Label
var _busy := false
var _last_press := -10.0
var _last_press_hit := false
var _last_tap := -10.0
var _last_tap_pos := Vector2.INF
var _slide_k := 0


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	process_priority = 150  # after the camera (0) and the walking body (100), before the flights (880)
	_cube = _obs.get_node_or_null("SteelCube") as Node3D
	_walk = _obs.get_node_or_null("WalkBody")
	_move = _obs.get_node_or_null("ViewMove")
	var args := OS.get_cmdline_user_args()
	reduced = args.has("--reduced-motion")
	var start := args.has("--corridor")
	if OS.has_feature("web"):
		reduced = reduced or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true)) \
			or str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('motion') || ''", true)) == "reduce"
		start = start or str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('corridor') || ''", true)) == "1"
	touch = _obs.get_node_or_null("TouchControls") != null
	var lib := _obs.get_node_or_null("Generated/CourseShelves")
	if lib != null:
		lang = str(lib.get("lang"))
		if lib.has_signal("lang_changed"):
			lib.connect("lang_changed", set_lang)
	_build_ui()
	_publish()
	if start:
		get_tree().create_timer(0.5).timeout.connect(func() -> void: enter(true))


func set_lang(code: String) -> void:
	lang = code if TEXT.has(code) else "en"
	var t: Dictionary = TEXT[lang]
	_leave.text = "×  " + str(t.leave)
	_inside_label.text = str(t.inside)
	_hover_label.text = str(t.hover_touch if touch else t.hover)
	if _exit_label != null:
		_exit_label.text = str(t.exit)
	_layout()
	_publish.call_deferred()


func set_touch(on: bool) -> void:
	touch = on
	set_lang(lang)
	_layout()


# --- In and out -------------------------------------------------------------------------------

## Fades into the corridor. instant: no fade (start-up, tests).
func enter(instant := false) -> void:
	if inside or _busy or _camera == null:
		return
	if instant:
		_swap_in()
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_OUT * (0.5 if reduced else 1.0))
	tw.tween_callback(_swap_in)
	tw.tween_property(_fade, "color:a", 0.0, FADE_IN)
	tw.tween_callback(func() -> void: _busy = false)


func leave(instant := false) -> void:
	if not inside or _busy:
		return
	if instant:
		_swap_out()
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_OUT * (0.5 if reduced else 1.0))
	tw.tween_callback(_swap_out)
	tw.tween_property(_fade, "color:a", 0.0, FADE_IN)
	tw.tween_callback(func() -> void: _busy = false)


func _swap_in() -> void:
	if _root == null:
		_build()
	_hidden.clear()
	for c in _obs.get_children():
		var n := c as Node3D
		if n != null and n != _camera and n != _root and n.visible:
			n.visible = false
			_hidden.append(n)
	_root.visible = true
	_set_environment(true)
	# fly_camera.gd keeps its own moves within the hall's radius; the corridor is far outside it.
	if _radius_saved < 0.0:
		_radius_saved = float(_camera.get("max_radius"))
	_camera.set("max_radius", 1.0e6)
	_place(Transform3D(Basis(), ORIGIN + START))
	if _walk != null:
		_walk.set("region", self)
	inside = true
	stats.entries += 1
	_slide_to(0)
	_layout()
	_publish()
	entered.emit()


func _swap_out() -> void:
	for n in _hidden:
		if is_instance_valid(n):
			n.visible = true
	_hidden.clear()
	_root.visible = false
	_set_environment(false)
	if _radius_saved >= 0.0:
		_camera.set("max_radius", _radius_saved)
		_radius_saved = -1.0
	if _walk != null:
		_walk.set("region", null)
	# Out of the box's door, facing the hall.
	var at := Vector3(0.0, 1.7, 4.2)
	var basis := Basis(Vector3.UP, PI)
	if _cube != null:
		var size: Vector3 = _cube.get("box_size")
		at = _cube.global_transform * Vector3(0.0, 1.7, size.z * 0.5 + 1.6)
		basis = _cube.global_basis * Basis(Vector3.UP, PI)
	inside = false
	stats.exits += 1
	_place(Transform3D(basis, at))
	_layout()
	_publish()
	left.emit()


## Puts the camera there as a cut: no flight (view_move.gd), and the fly camera's own angles follow.
func _place(xf: Transform3D) -> void:
	if _move != null and _move.has_method("cut"):
		_move.call("cut")
	_camera.global_transform = xf
	var e := _camera.basis.get_euler()
	_camera.set("_yaw", e.y)
	_camera.set("_pitch", e.x)
	_camera.rotation = Vector3(e.x, e.y, 0.0)


func _set_environment(dark: bool) -> void:
	var we := _obs.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null or we.environment == null:
		return
	var env := we.environment
	var keys := ["background_mode", "background_color", "ambient_light_source", "ambient_light_color",
		"ambient_light_energy", "reflected_light_source", "fog_enabled", "fog_mode", "fog_light_color",
		"fog_light_energy", "fog_density", "fog_sky_affect", "fog_height_density", "fog_aerial_perspective",
		"volumetric_fog_enabled", "sdfgi_enabled", "ssr_enabled"]
	if dark:
		for k in keys:
			_env_saved[k] = env.get(k)
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.BLACK
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.1, 0.105, 0.12)
		env.ambient_light_energy = 1.0
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_height_density = 0.0
		env.fog_aerial_perspective = 0.0
		env.fog_light_color = Color.BLACK
		env.fog_light_energy = 1.0
		env.fog_density = 0.075
		env.fog_sky_affect = 1.0
		env.volumetric_fog_enabled = false
		env.sdfgi_enabled = false
		env.ssr_enabled = false
	else:
		for k in _env_saved:
			env.set(k, _env_saved[k])


# --- Every frame ------------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _camera == null:
		return
	if not inside:
		# Aimed at with the crosshair on a computer; on a touch screen, where nothing is aimed,
		# as soon as the box is in view and near.
		var hit := not _busy and (_box_in_view(HOVER_REACH) if touch else _aim_hits_box(get_viewport().get_visible_rect().size * 0.5, HOVER_REACH))
		stats.hover = hit
		_hover_label.visible = hit
		return
	_hover_label.visible = false
	if Engine.get_process_frames() % 30 == 0:
		_publish()  # the Leave button settles its size a frame or two after entering
	# Fly mode too stays inside: the walls, the floor and the ceiling hold.
	var local := _camera.global_position - ORIGIN
	var in_door := absf(local.x) < EXIT.x * 0.5 - 0.1
	local.x = clampf(local.x, -WIDTH * 0.5 + RADIUS, WIDTH * 0.5 - RADIUS)
	local.y = clampf(local.y, 0.4, HEIGHT - 0.25)
	local.z = minf(local.z, 0.9 if in_door else -RADIUS)
	if not (ORIGIN + local).is_equal_approx(_camera.global_position):
		_camera.global_position = ORIGIN + local
	if in_door and local.z > 0.35 and not _busy:
		leave()
	_slide_to(roundi(local.z / PITCH))
	_lantern.global_position = _camera.global_position + _camera.global_basis * Vector3(0.25, -0.35, -0.3)


## The walking body's collisions in the corridor (walk_physics.gd): p is the camera's floor-plane
## position, x and z; returns it pushed back inside the walls.
func walk_collide(p: Vector2) -> Vector2:
	var x := p.x - ORIGIN.x
	var z := p.y - ORIGIN.z
	var in_door := absf(x) < EXIT.x * 0.5 - 0.1
	x = clampf(x, -WIDTH * 0.5 + RADIUS, WIDTH * 0.5 - RADIUS)
	z = minf(z, 0.9 if in_door else -RADIUS)
	return Vector2(x + ORIGIN.x, z + ORIGIN.z)


func _slide_to(k: int) -> void:
	k = mini(k, 0)
	if k == _slide_k and _slide.position.z == k * PITCH:
		return
	if k != _slide_k:
		stats.slides += 1
	_slide_k = k
	_slide.position.z = k * PITCH
	_publish.call_deferred()
	for plate in _plates:
		plate.text = "Nº %04d" % door_number(plate.global_position.z - ORIGIN.z, plate.global_position.x > ORIGIN.x)


## A door's number from its place: the same index the shader takes its world from.
static func door_number(z: float, right: bool) -> int:
	var k := floori(z / PITCH + 0.5)
	return absi(2 * k + (1 if right else 0)) + 1


# --- The way in -------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _camera == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and inside:
		var key := event as InputEventKey
		if (key.physical_keycode if key.physical_keycode != 0 else key.keycode) == KEY_ESCAPE:
			leave()  # not handled: the fly camera also releases the mouse
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or inside or _busy:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var at := get_viewport().get_visible_rect().size * 0.5 if captured else mb.position
	var hit := _aim_hits_box(at, 60.0)
	var now := Time.get_ticks_msec() / 1000.0
	if (mb.double_click or now - _last_press < DOUBLE) and (hit or _last_press_hit):
		_last_press = -10.0
		enter()
		get_viewport().set_input_as_handled()
		return
	_last_press = now
	_last_press_hit = hit


## A tap from touch_controls.gd: true when it was the second of a double tap on the box.
func tap(pos: Vector2) -> bool:
	if inside or _busy:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var near := pos.distance_to(_last_tap_pos) < 0.08 * minf(get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y)
	if now - _last_tap < DOUBLE and near and _aim_hits_box(pos, 60.0):
		_last_tap = -10.0
		enter()
		return true
	_last_tap = now
	_last_tap_pos = pos
	return false


## The Leave button's area, for touch_controls.gd (buttons get no touches there).
func leave_at(pos: Vector2) -> bool:
	return inside and _leave.visible and _leave.get_global_rect().has_point(pos)


func _aim_hits_box(at: Vector2, reach: float) -> bool:
	if _cube == null or not _cube.is_visible_in_tree():
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var size: Vector3 = _cube.get("box_size")
	var inv := _cube.global_transform.affine_inverse()
	var o := inv * cam.project_ray_origin(at) - Vector3(0.0, size.y * 0.5, 0.0)
	var d := inv.basis * cam.project_ray_normal(at)
	var t := _ray_box(o, d, size * 0.5)
	return t >= 0.0 and t < reach


func _box_in_view(reach: float) -> bool:
	if _cube == null or not _cube.is_visible_in_tree():
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var size: Vector3 = _cube.get("box_size")
	var c := _cube.global_transform * Vector3(0.0, size.y * 0.5, 0.0)
	return cam.global_position.distance_to(c) < reach and cam.is_position_in_frustum(c) 		and not cam.is_position_behind(c)


static func _ray_box(o: Vector3, d: Vector3, half: Vector3) -> float:
	var t0 := -INF
	var t1 := INF
	for axis in 3:
		if absf(d[axis]) < 1e-8:
			if absf(o[axis]) > half[axis]:
				return -1.0
			continue
		var a := (-half[axis] - o[axis]) / d[axis]
		var b := (half[axis] - o[axis]) / d[axis]
		t0 = maxf(t0, minf(a, b))
		t1 = minf(t1, maxf(a, b))
	if t1 < maxf(t0, 0.0):
		return -1.0
	return maxf(t0, 0.0)


# --- Building ---------------------------------------------------------------------------------

func _build() -> void:
	_root = Node3D.new()
	_root.name = "Corridor"
	_root.position = ORIGIN
	_obs.add_child(_root)
	var compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var steel := _mat(Color(0.34, 0.35, 0.36), 0.5, 0.25)
	var seam := _mat(Color(0.1, 0.105, 0.11), 0.55, 0.3)
	var floor_m := _mat(Color(0.2, 0.2, 0.21), 0.3, 0.05)
	var door_m := _mat(Color(0.46, 0.47, 0.48), 0.38, 0.35)
	var frame_m := _mat(Color(0.14, 0.145, 0.15), 0.5, 0.35)
	var brass := _mat(Color(0.78, 0.6, 0.34), 0.35, 0.45)
	var lamp := _mat(Color(0.8, 0.85, 0.9), 0.5, 0.0, Color(0.75, 0.82, 0.95), 0.9 if compat else 2.0)
	var warm := Color(1.0, 0.76, 0.48)

	# The exit wall with its lit doorway, which stays where it is.
	var ex := EXIT
	var side_w := (WIDTH - ex.x) * 0.5
	_add(_root, "ExitWallL", _box(Vector3(side_w, HEIGHT, 0.2)), steel, Vector3(-(ex.x + side_w) * 0.5, HEIGHT * 0.5, 0.1))
	_add(_root, "ExitWallR", _box(Vector3(side_w, HEIGHT, 0.2)), steel, Vector3((ex.x + side_w) * 0.5, HEIGHT * 0.5, 0.1))
	_add(_root, "ExitWallTop", _box(Vector3(ex.x, HEIGHT - ex.y, 0.2)), steel, Vector3(0.0, (HEIGHT + ex.y) * 0.5, 0.1))
	_add(_root, "ExitFrameL", _box(Vector3(0.06, ex.y, 0.24)), brass, Vector3(-ex.x * 0.5, ex.y * 0.5, 0.1))
	_add(_root, "ExitFrameR", _box(Vector3(0.06, ex.y, 0.24)), brass, Vector3(ex.x * 0.5, ex.y * 0.5, 0.1))
	_add(_root, "ExitFrameTop", _box(Vector3(ex.x + 0.06, 0.06, 0.24)), brass, Vector3(0.0, ex.y, 0.1))
	var glow := _mat(warm, 0.5, 0.0, warm, 1.4 if compat else 4.0)
	_add(_root, "ExitLight", _box(Vector3(ex.x + 0.4, ex.y + 0.4, 0.05)), glow, Vector3(0.0, ex.y * 0.5, 1.4))
	_add(_root, "ExitFloor", _box(Vector3(ex.x + 0.4, 0.1, 1.4)), floor_m, Vector3(0.0, -0.05, 0.75))
	_add(_root, "ExitSideL", _box(Vector3(0.1, ex.y + 0.4, 1.4)), steel, Vector3(-(ex.x + 0.4) * 0.5, ex.y * 0.5, 0.75))
	_add(_root, "ExitSideR", _box(Vector3(0.1, ex.y + 0.4, 1.4)), steel, Vector3((ex.x + 0.4) * 0.5, ex.y * 0.5, 0.75))
	_add(_root, "ExitTop", _box(Vector3(ex.x + 0.4, 0.1, 1.4)), steel, Vector3(0.0, ex.y + 0.2, 0.75))
	var spill := OmniLight3D.new()
	spill.name = "ExitSpill"
	spill.light_color = warm
	spill.light_energy = 1.2
	spill.omni_range = 5.5
	spill.position = Vector3(0.0, 1.8, 0.4)
	_root.add_child(spill)
	_exit_label = Label3D.new()
	_exit_label.name = "ExitSign"
	_exit_label.pixel_size = 0.0022
	_exit_label.font_size = 64
	_exit_label.outline_size = 0
	_exit_label.modulate = Color(1.0, 0.85, 0.55)
	_exit_label.position = Vector3(0.0, ex.y + 0.3, -0.02)
	_exit_label.rotation.y = PI  # read from the corridor
	_root.add_child(_exit_label)

	# The stretch that slides: floor, ceiling, walls, seams, lamps and doors.
	_slide = Node3D.new()
	_slide.name = "Stretch"
	_root.add_child(_slide)
	var cz := 0.0
	_add(_slide, "Floor", _box(Vector3(WIDTH, 0.1, SPAN)), floor_m, Vector3(0.0, -0.05, cz))
	_add(_slide, "Ceiling", _box(Vector3(WIDTH, 0.1, SPAN)), steel, Vector3(0.0, HEIGHT + 0.05, cz))
	_add(_slide, "WallL", _box(Vector3(0.1, HEIGHT, SPAN)), steel, Vector3(-WIDTH * 0.5 - 0.05, HEIGHT * 0.5, cz))
	_add(_slide, "WallR", _box(Vector3(0.1, HEIGHT, SPAN)), steel, Vector3(WIDTH * 0.5 + 0.05, HEIGHT * 0.5, cz))
	var ribs := []
	var lamps := []
	var n := int(SPAN / PITCH / 2.0)
	for j in range(-n, n + 1):
		var z := -1.8 - j * PITCH  # between a left door and the next right one
		for s in [-1.0, 1.0]:
			ribs.append(Transform3D(Basis(), Vector3(s * (WIDTH * 0.5 - 0.02), HEIGHT * 0.5, z)))
		ribs.append(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.0, HEIGHT - 0.02, z)))
		lamps.append(Transform3D(Basis(), Vector3(0.0, HEIGHT - 0.03, z - PITCH * 0.5)))
	_multi(_slide, "Seams", _box(Vector3(0.05, HEIGHT, 0.08)), seam, ribs)
	_multi(_slide, "Lamps", _box(Vector3(0.5, 0.03, 0.18)), lamp, lamps)

	var slabs := []
	var posts := []
	var lintels := []
	var plates := []
	var glimpse_mesh := _glimpse_mesh()
	var glimpse_mat := ShaderMaterial.new()
	glimpse_mat.shader = load(GLIMPSE_SHADER)
	glimpse_mat.set_shader_parameter("pitch", PITCH)
	glimpse_mat.set_shader_parameter("corridor_z", ORIGIN.z)
	for j in range(-n, n):
		for right in [false, true]:
			var z := (RIGHT_Z if right else LEFT_Z) - j * PITCH
			var s := 1.0 if right else -1.0
			# The door's frame: local -z goes into the wall.
			var basis := Basis(Vector3.UP, -PI * 0.5 if right else PI * 0.5)
			var face := Vector3(s * (WIDTH * 0.5 - 0.05), 0.0, z)
			var xf := Transform3D(basis, face)
			slabs.append(xf * Transform3D(Basis(), Vector3(0.0, DOOR.y * 0.5, 0.0)))
			posts.append(xf * Transform3D(Basis(), Vector3(-DOOR.x * 0.5 - 0.05, DOOR.y * 0.5, 0.02)))
			posts.append(xf * Transform3D(Basis(), Vector3(DOOR.x * 0.5 + 0.05, DOOR.y * 0.5, 0.02)))
			lintels.append(xf * Transform3D(Basis(), Vector3(0.0, DOOR.y + 0.05, 0.02)))
			plates.append(xf * Transform3D(Basis(), Vector3(0.0, 1.95, 0.045)))
			var g := MeshInstance3D.new()
			g.name = "Glimpse"
			g.mesh = glimpse_mesh
			g.material_override = glimpse_mat
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			g.transform = xf
			_slide.add_child(g)
			var label := Label3D.new()
			label.name = "Number"
			label.pixel_size = 0.0011
			label.font_size = 48
			label.outline_size = 0
			label.modulate = Color(0.95, 0.78, 0.48)
			label.transform = xf * Transform3D(Basis(), Vector3(0.0, 1.95, 0.052))
			_slide.add_child(label)
			_plates.append(label)
			stats.doors += 1
	_multi(_slide, "Doors", _box(Vector3(DOOR.x, DOOR.y, 0.06)), door_m, slabs)
	_multi(_slide, "DoorPosts", _box(Vector3(0.1, DOOR.y + 0.1, 0.08)), frame_m, posts)
	_multi(_slide, "DoorLintels", _box(Vector3(DOOR.x + 0.2, 0.1, 0.08)), frame_m, lintels)
	_multi(_slide, "Plates", _box(Vector3(0.22, 0.08, 0.01)), brass, plates)

	# The lantern, carried a little ahead and to the right of the eye.
	_lantern = OmniLight3D.new()
	_lantern.name = "Lantern"
	_lantern.light_color = Color(1.0, 0.8, 0.55)
	_lantern.light_energy = 2.4
	_lantern.omni_range = 12.0
	_lantern.omni_attenuation = 1.1
	_root.add_child(_lantern)
	_root.visible = false
	set_lang(lang)


## A door's window (UV.y 0.5 to 1) and the strip of light under its leaf, on the floor (UV.y 0 to
## 0.5), in the door's frame: z towards the corridor, y up from the floor.
static func _glimpse_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quads := [
		[Vector3(-0.13, 1.45, 0.034), Vector3(0.13, 1.45, 0.034), Vector3(0.13, 1.8, 0.034), Vector3(-0.13, 1.8, 0.034), 0.5, 1.0],
		[Vector3(-0.48, 0.004, 0.0), Vector3(0.48, 0.004, 0.0), Vector3(0.48, 0.004, 0.22), Vector3(-0.48, 0.004, 0.22), 0.0, 0.5],
	]
	for q in quads:
		var uv0 := Vector2(0.0, float(q[4]))
		var uv1 := Vector2(1.0, float(q[4]))
		var uv2 := Vector2(1.0, float(q[5]))
		var uv3 := Vector2(0.0, float(q[5]))
		for v in [[q[0], uv0], [q[1], uv1], [q[2], uv2], [q[0], uv0], [q[2], uv2], [q[3], uv3]]:
			st.set_uv(v[1])
			st.add_vertex(v[0])
	st.generate_normals()
	return st.commit()


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "CorridorUI"
	_ui.layer = 30
	add_child(_ui)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_fade)
	_bar = VBoxContainer.new()
	_bar.name = "LeaveBar"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_bar)
	_leave = Button.new()
	_leave.name = "Leave"
	_leave.focus_mode = Control.FOCUS_ALL
	_leave.pressed.connect(func() -> void: leave())
	_leave.add_theme_stylebox_override("normal", _style(Color(0.08, 0.07, 0.06, 0.85), Color(0.95, 0.75, 0.42)))
	_leave.add_theme_stylebox_override("hover", _style(Color(0.2, 0.15, 0.08, 0.92), Color(1.0, 0.85, 0.5)))
	_leave.add_theme_stylebox_override("focus", _style(Color(0.2, 0.15, 0.08, 0.92), Color(1.0, 0.9, 0.6)))
	_leave.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.2, 0.1, 0.95), Color(1.0, 0.9, 0.6)))
	_leave.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	_bar.add_child(_leave)
	_inside_label = Label.new()
	_inside_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inside_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inside_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	_inside_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_inside_label.add_theme_constant_override("outline_size", 4)
	_bar.add_child(_inside_label)
	_hover_label = Label.new()
	_hover_label.name = "BoxHint"
	_hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hover_label.set_anchors_preset(Control.PRESET_CENTER)
	_hover_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.68))
	_hover_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hover_label.add_theme_constant_override("outline_size", 5)
	_hover_label.visible = false
	_ui.add_child(_hover_label)
	get_viewport().size_changed.connect(_layout)
	set_lang(lang)
	_layout()


func _layout() -> void:
	if _bar == null:
		return
	var size := get_viewport().get_visible_rect().size
	var u := minf(size.x, size.y)
	var big := touch
	var fs := int(clampf(u * (0.034 if big else 0.024), 14.0, 40.0))
	_leave.add_theme_font_size_override("font_size", fs + 2)
	_inside_label.add_theme_font_size_override("font_size", maxi(12, fs - 3))
	_hover_label.add_theme_font_size_override("font_size", fs)
	var w := minf(size.x - 32.0, 760.0 if not big else size.x * 0.9)
	# Touch screens: under the Courses button and the language selector (course_library.gd puts
	# its bottom near 0.25 of the short side). Computers: at the bottom, clear of the keyboard help
	# and the language selector at the top; the bar grows up from there as its text wraps.
	var bottom := not big
	_bar.anchor_left = 0.5
	_bar.anchor_right = 0.5
	_bar.anchor_top = 1.0 if bottom else 0.0
	_bar.anchor_bottom = _bar.anchor_top
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	_bar.offset_left = -w * 0.5
	_bar.offset_right = w * 0.5
	if bottom:
		_bar.offset_bottom = -u * 0.05
		_bar.offset_top = _bar.offset_bottom
	else:
		_bar.offset_top = u * 0.27
		_bar.offset_bottom = _bar.offset_top
	_bar.alignment = BoxContainer.ALIGNMENT_END if bottom else BoxContainer.ALIGNMENT_BEGIN
	if bottom:
		_bar.move_child(_leave, _bar.get_child_count() - 1)  # the button under its explanation
	else:
		_bar.move_child(_leave, 0)
	_leave.custom_minimum_size = Vector2(0.0, fs * 2.2)
	_bar.visible = inside
	_hover_label.size = Vector2.ZERO
	var hs := _hover_label.get_combined_minimum_size()
	_hover_label.size = hs
	_hover_label.position = Vector2((size.x - hs.x) * 0.5, size.y * 0.5 + u * 0.08)


## Web tests: the corridor's state and the Leave button's centre, as fractions of the screen.
func _publish() -> void:
	if not OS.has_feature("web"):
		return
	var size := get_viewport().get_visible_rect().size
	var c := _leave.get_global_rect().get_center() / size if inside else Vector2(-1, -1)
	JavaScriptBridge.eval("window.__obsCorridor = %s" % JSON.stringify({"inside": inside, "entries": stats.entries,
		"exits": stats.exits, "doors": stats.doors, "slides": stats.slides, "leave": [c.x, c.y], "lang": lang}), true)


static func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func _mat(albedo: Color, rough := 0.8, metal := 0.0, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metal
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _add(parent: Node, node_name: String, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	return mi


func _multi(parent: Node, node_name: String, mesh: Mesh, mat: Material, xforms: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	parent.add_child(mmi)
	return mmi
