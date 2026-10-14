extends Node
## A telescope view beside the curio wheel's monocle (the author, 2026-10-12: « Tu rajoutera une vue
## télescope en plus du monocle »). O puts the eye to it from wherever the camera is, and O again or
## Escape takes it away: the view closes in twelve times inside a round eyepiece with a fine reticle; the
## wheel, or + and -, sets the power from 6 to 100 times (the author: « Le télescope doit pouvoir faire
## du x100 »), and the mouse turns it as much more slowly. Made for Trantor: at twelve times the
## downtown's landmarks and the towers' facades (scripts/night_city.gd) fill the eyepiece, at a hundred
## a few floors of one. Below a degree of field view_fit.gd sets the camera through set_perspective.
## It goes through view_fit.gd's zoom as the monocle does (scripts/curio_wheel.gd, which sets it every
## frame at priority 860): after it, before view_fit reads it (900), multiplying it, so that the two
## combine. Added by scripts/extra_views.gd. Not on the drone's camera, nor during the cinematic.

const KEY := KEY_O
const POWERS := Vector2(6.0, 100.0)
const START := 12.0
const STEP := 1.25  ## the power's factor per notch of the wheel or press of + and -: 12 to 100 in 10
const TEXT := {
	"en": "Telescope  ×%d   ·   wheel or + −: power   ·   O: put it down",
	"fr": "Télescope  ×%d   ·   molette ou + − : grossissement   ·   O : le poser",
	"es": "Telescopio  ×%d   ·   rueda o + −: aumento   ·   O: dejarlo",
}

var on := false
var power := START
var lang := "en"
## For tests: times put to the eye, the zoom written last.
var stats := {"opened": 0, "zoom": 1.0}

var _obs: Node
var _cam: Camera3D
var _scope := 1.0           # eased: 1 / power while on, 1 off
var _base := 1.0            # the zoom found before this node multiplied it
var _wrote := -1.0          # the zoom it wrote
var _sens := -1.0           # the camera's own mouse sensitivity
var _layer: CanvasLayer
var _eye: ColorRect
var _label: Label


func configure(obs: Node, camera: Camera3D) -> void:
	_obs = obs
	_cam = camera


func _ready() -> void:
	process_priority = 890
	var lib := _obs.get_node_or_null("Generated/CourseShelves") if _obs != null else null
	if lib != null:
		lang = str(lib.get("lang"))
		if lib.has_signal("lang_changed"):
			lib.connect("lang_changed", func(l: String) -> void: lang = l)
	_build_ui()


func _usable() -> bool:
	if _cam == null or not _cam.current:
		return false
	var film := _obs.get_node_or_null("Cinematic") if _obs != null else null
	return film == null or not bool(film.get("playing"))


func set_on(v: bool) -> void:
	v = v and _usable()
	if v == on:
		return
	on = v
	if on:
		stats.opened += 1
		_sens = float(_cam.get("mouse_sensitivity"))
	elif _sens > 0.0:
		_cam.set("mouse_sensitivity", _sens)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		var code := k.physical_keycode if k.physical_keycode != 0 else k.keycode
		if code == KEY:
			set_on(not on)
			get_viewport().set_input_as_handled()
		elif on and code == KEY_ESCAPE:
			set_on(false)  # not handled: the fly camera lets the mouse go too
		elif on and (code == KEY_EQUAL or code == KEY_KP_ADD):
			power = minf(power * STEP, POWERS.y)
			get_viewport().set_input_as_handled()
		elif on and (code == KEY_MINUS or code == KEY_KP_SUBTRACT):
			power = maxf(power / STEP, POWERS.x)
			get_viewport().set_input_as_handled()
	elif on and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var b := (event as InputEventMouseButton).button_index
		if b == MOUSE_BUTTON_WHEEL_UP or b == MOUSE_BUTTON_WHEEL_DOWN:
			# The power, rather than the fly camera's speed.
			power = clampf(power * (STEP if b == MOUSE_BUTTON_WHEEL_UP else 1.0 / STEP), POWERS.x, POWERS.y)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if on and not _usable():
		set_on(false)
	var to := 1.0 / power if on else 1.0
	# Eased on a log scale, so that 12 to 100 times takes as long as 1 to 8 and neither jumps.
	_scope = exp(lerpf(log(_scope), log(to), 1.0 - exp(-12.0 * delta)))
	if absf(log(_scope / to)) < 0.002:
		_scope = to
	var fit := _obs.get_node_or_null("ViewFit") if _obs != null else null
	if fit != null:
		var z := float(fit.get("zoom"))
		if _wrote > 0.0 and is_equal_approx(z, _wrote):
			z = _base  # nobody set it since this node did: start again from what it found
		_base = z
		_wrote = z * _scope
		fit.set("zoom", _wrote)
		stats.zoom = _wrote
	if on and _sens > 0.0:
		_cam.set("mouse_sensitivity", _sens * clampf(_scope * 1.5, 0.005, 1.0))
	var amount := clampf((1.0 - _scope) / (1.0 - 1.0 / POWERS.x), 0.0, 1.0)
	_eye.visible = amount > 0.01
	(_eye.material as ShaderMaterial).set_shader_parameter("amount", amount)
	_label.visible = on
	_label.text = str(TEXT.get(lang, TEXT.en)) % int(round(power))


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 4  # under the course UI (5), the touch controls (6) and the curio wheel (40)
	add_child(_layer)
	_eye = ColorRect.new()
	_eye.set_anchors_preset(Control.PRESET_FULL_RECT)
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
// The eyepiece: dark round its field, the field's edge soft with a warm glint of its brass, a fine
// reticle (a broken cross and its ticks), the field a little darker towards its edge.
uniform float amount = 0.0;
uniform vec2 size = vec2(1600.0, 900.0);
void fragment() {
	vec2 p = (UV - 0.5) * size;
	float R = 0.47 * min(size.x, size.y);
	float r = length(p) / R;
	float px = 1.0 / R;
	float outside = smoothstep(1.0 - 2.0 * px, 1.0 + 2.0 * px, r);
	float rim = exp(-pow((r - 1.0) / (5.0 * px), 2.0));
	vec2 q = abs(p) / R;
	float w = 1.2 * px;
	float arms = (1.0 - smoothstep(w * 0.5, w, q.y)) * step(0.05, q.x) + (1.0 - smoothstep(w * 0.5, w, q.x)) * step(0.05, q.y);
	float along = max(q.x, q.y);
	float off_arm = min(q.x, q.y);
	float tick = (1.0 - smoothstep(0.0, 1.5 * px, abs(fract(along * 10.0 + 0.5) - 0.5) / 10.0))
		* (1.0 - smoothstep(5.0 * px, 6.0 * px, off_arm)) * step(0.05, along);
	float ret = clamp(max(arms, tick * 0.8), 0.0, 1.0) * (1.0 - outside) * step(r, 0.92);
	vec3 col = mix(vec3(0.0), vec3(0.55, 0.4, 0.18), rim * 0.8);
	col = mix(col, vec3(0.9, 0.86, 0.72), ret);
	float a = max(outside, max(rim * 0.8, smoothstep(0.6, 1.0, r) * 0.45));
	a = max(a, ret * 0.6);
	COLOR = vec4(col, a * amount);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_eye.material = mat
	_eye.visible = false
	_eye.resized.connect(func() -> void:
		mat.set_shader_parameter("size", _eye.size))
	_layer.add_child(_eye)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.offset_bottom = -18.0
	_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.7))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	_layer.add_child(_label)
