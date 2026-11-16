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
## The eyepiece's marks (the author, 2026-10-15: « La cross-hair du télescope n'a pas l'air assez hi
## tech - fait moi un truc à la Dune (le film récent) »): hairlines the colour of sand on the dark, in
## the spirit of that film's instruments and drawn here, not copied from it. They measure: a bezel
## of 5-degree ticks turning with the bearing, tapes of bearing (top) and elevation (right) fixed to
## the sky, the cross's stadia ticks at a step of true angle chosen for the power, and the readings
## of all of them (AZ, EL, the field's height, the step). The rings draw in clockwise as the eye goes
## to it; a faint sweep runs down the field.

const KEY := KEY_O
const POWERS := Vector2(6.0, 100.0)
const START := 12.0
const STEP := 1.25  ## the power's factor per notch of the wheel or press of + and -: 12 to 100 in 10
const TEXT := {
	"en": "Telescope  ×%d   ·   wheel or + −: power   ·   O: put it down",
	"fr": "Télescope  ×%d   ·   molette ou + − : grossissement   ·   O : le poser",
	"es": "Telescopio  ×%d   ·   rueda o + −: aumento   ·   O: dejarlo",
}
## The jump (scripts/teleport.gd): Enter goes to the ground in the sights.
const TELEPORT_SCRIPT_PATH := "res://scripts/teleport.gd"
const JUMP := {
	"en": ["Enter: go there, %d m", "No ground in the sights"],
	"fr": ["Entrée : y aller, %d m", "Aucun sol dans le viseur"],
	"es": ["Intro: ir allí, %d m", "Ningún suelo en el visor"],
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
var _hud: Control           # the readings, over the eyepiece's marks
var _label: Label
var _boot := 0.0            # seconds since the eye was put to it
var _read := {}             # what the marks measure this frame: az, el, fov, tick (degrees)
var _jump: Node             # scripts/teleport.gd


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
	if ResourceLoader.exists(TELEPORT_SCRIPT_PATH):
		_jump = load(TELEPORT_SCRIPT_PATH).new()
		_jump.name = "Teleport"
		_jump.call("configure", _obs, _cam)
		add_child(_jump)


func _usable() -> bool:
	if _cam == null or not _cam.current:
		return false
	if _jump != null and bool(_jump.get("flying")):
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
		_boot = 0.0
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
		elif on and (code == KEY_ENTER or code == KEY_KP_ENTER) and _jump != null:
			_jump.call("go")
			get_viewport().set_input_as_handled()
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
	var mat := _eye.material as ShaderMaterial
	mat.set_shader_parameter("amount", amount)
	_label.visible = on
	_label.text = str(TEXT.get(lang, TEXT.en)) % int(round(power))
	if on and _jump != null:
		var a: Dictionary = _jump.call("aim")
		var j: Array = JUMP.get(lang, JUMP.en)
		_label.text += "\n" + (str(j[0]) % int(round(float(a.m))) if bool(a.ok) else str(j[1]))
	_hud.visible = _eye.visible
	if not _eye.visible or _cam == null:
		return
	_boot += delta
	# What the marks measure: the bearing (0 along -z, clockwise seen from above), the elevation, the
	# field's height, and the stadia's step, the first of a 1-2-5 ladder at least 4.5 % of the field's
	# radius apart.
	var f := -_cam.global_basis.z.normalized()
	var size := _eye.size
	var R := 0.47 * minf(size.x, size.y)
	var fov := maxf(_cam.fov, 1e-4)
	var upd := size.y / (fov * R)  # the field's radius units a degree
	var tick := 5.0
	for s: float in [0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0]:
		if s * upd >= 0.045:
			tick = s
			break
	_read = {"az": fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0), "el": rad_to_deg(asin(clampf(f.y, -1.0, 1.0))),
		"fov": fov, "tick": tick, "boot": smoothstep(0.0, 0.55, _boot) if on else 1.0}
	mat.set_shader_parameter("az", float(_read.az))
	mat.set_shader_parameter("el", float(_read.el))
	mat.set_shader_parameter("upd", upd)
	mat.set_shader_parameter("tick", tick)
	mat.set_shader_parameter("boot", float(_read.boot))
	_hud.modulate.a = amount * smoothstep(0.45, 0.85, _boot if on else 1.0)
	_hud.queue_redraw()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 4  # under the course UI (5), the touch controls (6) and the curio wheel (40)
	add_child(_layer)
	_eye = ColorRect.new()
	_eye.set_anchors_preset(Control.PRESET_FULL_RECT)
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
// The eyepiece: dark round its field; on the field, hairlines the colour of sand that measure
// (scripts/telescope.gd): its edge and a ring of sixty segments broken at the quarters, a bezel of
// bearing ticks turning with the view, tapes of bearing and elevation fixed to the sky, corner
// brackets, a broken cross with stadia ticks at a step of true angle, an open diamond at its middle,
// a ping out from it and a faint sweep down the field.
uniform float amount = 0.0;
uniform vec2 size = vec2(1600.0, 900.0);
uniform float az = 0.0;      // degrees, the bearing at the centre
uniform float el = 0.0;      // degrees, the elevation at the centre
uniform float upd = 0.2;     // the field's radius units a degree
uniform float tick = 1.0;    // degrees between two stadia ticks
uniform float boot = 1.0;    // 0..1: the rings drawn in clockwise from the top

const vec3 SAND = vec3(1.0, 0.72, 0.4);
const vec3 PALE = vec3(1.0, 0.94, 0.84);

float hair(float d, float w) {
	return 1.0 - smoothstep(w * 0.5, w, abs(d));
}

// 1 on a tape's tick: t is the angle (degrees) under the point, c how far it is from the tape's
// base towards its ticks; every fifth tick is longer.
float tape(float t, float c, float w) {
	float k = floor(t / tick + 0.5);
	float d = (t - k * tick) * upd;
	float h = (1.0 - step(0.5, mod(k, 5.0))) > 0.5 ? 0.034 : 0.018;
	return hair(d, w) * step(0.0, c) * step(c, h);
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float R = 0.47 * min(size.x, size.y);
	float px = 1.0 / R;
	vec2 q = p / R;
	vec2 a = abs(q);
	float r = length(q);
	float th = fract(atan(q.x, -q.y) / 6.2831853 + 1.0);
	float inside = 1.0 - smoothstep(1.0 - 1.5 * px, 1.0 + 1.5 * px, r);
	float drawn = step(th, boot);
	float w = 1.3 * px;
	float sand = 0.0;
	float pale = 0.0;
	// The field's edge, and sixty segments inside it, broken at the four quarters.
	sand = max(sand, hair(r - 1.0, 2.0 * px) * drawn);
	float seg = step(fract(th * 60.0), 0.72) * step(0.018, abs(fract(th * 4.0 + 0.5) - 0.5));
	sand = max(sand, hair(r - 0.955, 3.0 * px) * seg * drawn * 0.9);
	// The bezel: a tick every 5 degrees of bearing, longer every 30, bearing 0 pale.
	float tb = fract(th + az / 360.0);
	float bi = floor(tb * 72.0 + 0.5);
	float tk = (tb * 72.0 - bi) / 72.0 * 6.2831853 * r;
	float bmaj = 1.0 - step(0.5, mod(bi, 6.0));
	float bn = 1.0 - step(0.5, mod(bi, 72.0));
	sand = max(sand, hair(tk, w) * step(mix(0.905, 0.875, bmaj), r) * step(r, 0.925) * drawn * 0.85);
	pale = max(pale, hair(tk, 1.8 * w) * step(0.85, r) * step(r, 0.925) * bn * drawn);
	float later = step(0.55, boot);
	// The bearing's tape, at the top, its ticks fixed to the sky, and its caret.
	float ta = tape(az + q.x / upd, q.y + 0.76, w) + hair(q.y + 0.76, w) * 0.6;
	sand = max(sand, ta * step(a.x, 0.42) * (1.0 - smoothstep(0.3, 0.42, a.x)) * later);
	pale = max(pale, hair(a.x - (-0.775 - q.y) * 0.6, w) * step(-0.805, q.y) * step(q.y, -0.775) * later);
	// The elevation's tape, at the right, and its caret.
	float te = tape(el - q.y / upd, 0.8 - q.x, w) + hair(q.x - 0.8, w) * 0.6;
	sand = max(sand, te * step(a.y, 0.4) * (1.0 - smoothstep(0.28, 0.4, a.y)) * later);
	pale = max(pale, hair(a.y - (q.x - 0.815) * 0.6, w) * step(0.815, q.x) * step(q.x, 0.845) * later);
	// Corner brackets, breathing a little.
	float b = 0.2 + 0.006 * sin(TIME * 1.7);
	float br = hair(a.x - b, 1.4 * w) * step(b - 0.05, a.y) * step(a.y, b) + hair(a.y - b, 1.4 * w) * step(b - 0.05, a.x) * step(a.x, b);
	sand = max(sand, br * step(0.3, boot));
	// The cross, broken at its middle, its stadia ticks every `tick` degrees, every fifth longer.
	float arm = hair(q.y, w) * step(0.06, a.x) * step(a.x, 0.36) + hair(q.x, w) * step(0.06, a.y) * step(a.y, 0.36);
	float sp = tick * upd;
	float kx = floor(a.x / sp + 0.5);
	float ky = floor(a.y / sp + 0.5);
	float sx = hair(a.x - kx * sp, w) * step(0.06, a.x) * step(a.x, 0.36) * (1.0 - step((1.0 - step(0.5, mod(kx, 5.0))) > 0.5 ? 0.022 : 0.011, a.y));
	float sy = hair(a.y - ky * sp, w) * step(0.06, a.y) * step(a.y, 0.36) * (1.0 - step((1.0 - step(0.5, mod(ky, 5.0))) > 0.5 ? 0.022 : 0.011, a.x));
	pale = max(pale, max(arm, max(sx, sy)) * 0.95);
	pale = max(pale, hair(a.x + a.y - 0.024, w));
	pale = max(pale, 1.0 - smoothstep(1.0 * px, 2.2 * px, r));
	// A ping out from the middle, and a sweep down the field.
	float ph = fract(TIME / 2.6);
	sand = max(sand, hair(r - 0.03 - ph * 0.28, 1.5 * w) * (1.0 - ph) * 0.4 * later);
	float sweep_y = fract(TIME / 3.4) * 2.4 - 1.2;
	sand = max(sand, exp(-pow((q.y - sweep_y) / 0.012, 2.0)) * 0.1 * later);
	sand = clamp(sand, 0.0, 1.0) * max(inside, hair(r - 1.0, 2.0 * px));
	pale = clamp(pale, 0.0, 1.0) * inside;
	vec3 col = vec3(0.0);
	float alpha = max(1.0 - inside, smoothstep(0.55, 1.0, r) * 0.42);
	col = mix(col, SAND, sand);
	alpha = max(alpha, sand * 0.9);
	col = mix(col, PALE, pale);
	alpha = max(alpha, pale * 0.85);
	COLOR = vec4(col, alpha * amount);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_eye.material = mat
	_eye.visible = false
	_eye.resized.connect(func() -> void:
		mat.set_shader_parameter("size", _eye.size))
	_layer.add_child(_eye)
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
	_hud.draw.connect(_draw_hud)
	_layer.add_child(_hud)
	_label = Label.new()
	# Bottom left, clear of the eyepiece's ring.
	_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.grow_horizontal = Control.GROW_DIRECTION_END
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.offset_left = 22.0
	_label.offset_bottom = -18.0
	_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.56))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	_layer.add_child(_label)


## The readings, by the marks they belong to: the bearing under its tape, the elevation by its own,
## and under the cross the power, the field's height and the stadia's step.
func _draw_hud() -> void:
	if _read.is_empty():
		return
	var size := _hud.size
	var c := size * 0.5
	var R := 0.47 * minf(size.x, size.y)
	var font := ThemeDB.fallback_font
	var fs := roundi(clampf(R * 0.042, 11.0, 24.0))
	var sand := Color(1.0, 0.72, 0.4)
	var pale := Color(1.0, 0.94, 0.84)
	var el := float(_read.el)
	_spaced(font, c + Vector2(0.0, -0.66 * R), "AZ  %05.1f°" % float(_read.az), fs, pale, 0)
	_spaced(font, c + Vector2(0.745 * R, -0.035 * R), "EL  " + ("+" if el >= 0.0 else "−") + "%04.1f°" % absf(el), fs, pale, 1)
	var fov := float(_read.fov)
	var field := ("%.2f°" % fov) if fov >= 0.1 else ("%.1f′" % (fov * 60.0))
	var step_deg := float(_read.tick)
	var stadia := ("%s°" % String.num(step_deg, 3)) if step_deg >= 0.1 else ("%s′" % String.num(step_deg * 60.0, 2))
	_spaced(font, c + Vector2(0.0, 0.62 * R), "×%d" % int(round(power)), roundi(fs * 1.35), sand, 0)
	_spaced(font, c + Vector2(0.0, 0.62 * R + fs * 1.5), "FOV  %s     ◇  %s" % [field, stadia], fs, sand, 0)


## Text with its letters spaced out, as an instrument's: centred on at (align 0) or ending at it (1).
func _spaced(font: Font, at: Vector2, text: String, fs: int, col: Color, align: int) -> void:
	var gap := fs * 0.14
	var w := 0.0
	for ch in text:
		w += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap
	w -= gap
	var x := at.x - (w * 0.5 if align == 0 else w)
	for ch in text:
		_hud.draw_string(font, Vector2(x, at.y + fs * 0.35), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap