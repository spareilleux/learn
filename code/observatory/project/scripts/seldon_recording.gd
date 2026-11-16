extends Node3D
## Seldon's recording, after the Time Vault of Asimov's Foundation, where Hari Seldon, dead for
## centuries, appears at the appointed hour to speak to the Foundation. Here he is made of light, and
## his shape is the statue's own: every vertex of the figure's mesh (assets/seldon_statue.glb, the
## TRELLIS.2 figure) becomes a point, so no actor's face enters the scene. The author asked for "un
## Seldon en particules, tiré de notre propre statue pour éviter tout visage d'acteur".
##
## Look at the gilt inscription on the pedestal for a second (a gold frame traces itself round it),
## press R, click it, or tap it on a phone: dust gathers beside the pedestal and climbs into a
## life-size Seldon, who turns to the viewer while three lines of his (written for this scene, not
## quoted) show over his head, then lifts away as dust. R again sends him away early.
##
## The points are drawn by one MultiMesh and moved by its shader (assets/seldon_points.gdshader); on
## a weak GPU (scripts/quality.gd at level 3 and over) every second or third point is drawn. The
## sound is synthesised here, a few frames at a time while the viewer is near.

const MESH_PATH := "res://assets/seldon_statue.glb"
const POINTS_SHADER_PATH := "res://assets/seldon_points.gdshader"
const FRAME_SHADER_PATH := "res://assets/recording_frame.gdshader"
const SFX_PATH := "res://scripts/sfx_takes.gd"
## The statue mesh's own square base, in its units (1 is the figure's height with it): left out.
const BASE_CUT := 0.065
const HEIGHT := 1.8          # metres, the figure without its base: life size
## Where he stands, in the statue's frame (+z towards the hall's centre): on the hall side of the
## pedestal, clear of its base (0.75 m from the axis), to the right of a viewer facing the statue.
const STAND := Vector3(1.55, 0.0, 0.5)
## The inscription's two lines (seldon_statue.gd) and the plate the frame goes round.
const INSCRIPTION := Vector3(0.0, 0.69, 0.603)
const PLATE := Vector2(0.9, 0.42)
const COLUMNS := 256         # points per row of the targets texture
const POINT_M := 0.012       # metres across a point, when all of them are drawn
const GAZE_REACH := 5.0      # metres: the frame shows, and a held look plays the recording
const GAZE_COS := 0.995      # within about 5.7 degrees of the inscription's centre
const GAZE_TIME := 1.0
const CLICK_REACH := 12.0
const FORM_S := 6.0          # dust to figure
const LINE_S := 5.5          # each line he speaks
const HOLD_S := 3.0          # after the last
const SCATTER_S := 3.0
const RATE := 22050
const SOUND_S := 3.4
const PARTIALS := [261.63, 392.0, 523.25, 659.25, 783.99]  # C, G, C, E, G: a major chord's shimmer
const PINGS := 32
## Written for this scene: the books' Seldon speaks to the Foundation, never to one reader.
const LINES := {
	"en": ["I am Hari Seldon, or the light that kept my shape.", "Psychohistory never foresaw any one reader.",
			"It foresaw that, together, you would keep the books open."],
	"fr": ["Je suis Hari Seldon, ou la lumière qui a gardé ma forme.", "La psychohistoire n'a jamais prévu aucun lecteur en particulier.",
			"Elle a prévu qu'ensemble, vous garderiez les livres ouverts."],
	"es": ["Soy Hari Seldon, o la luz que guardó mi forma.", "La psicohistoria nunca previó a ningún lector en particular.",
			"Previó que, juntos, mantendrían abiertos los libros."],
}
const HINTS := {
	"en": ["Look at the inscription, or press R: Seldon's recording", "Tap the inscription: Seldon's recording"],
	"fr": ["Regardez l'inscription, ou R : l'enregistrement de Seldon", "Touchez l'inscription : l'enregistrement de Seldon"],
	"es": ["Mire la inscripción, o pulse R: la grabación de Seldon", "Toque la inscripción: la grabación de Seldon"],
}

var stats := {}
var reduced_motion := false
var _obs: Node3D
var _camera: Camera3D
var _statue: Node3D
var _targets: ImageTexture
var _count := 0
var _pivot: Node3D           # at STAND, turned to the viewer
var _points: MultiMeshInstance3D
var _mat: ShaderMaterial
var _caption: Label3D
var _voice: AudioStreamPlayer3D
var _frame: MeshInstance3D
var _frame_mat: ShaderMaterial
var _hint: Label3D
var _state := 0              # 0 closed, 1 forming, 2 speaking, 3 scattering
var _t := 0.0
var _scatter_t := 0.0
var _gaze := 0.0
var _latched := false
var _lang := "en"
var _last_us := 0
var _synth := PackedFloat32Array()
var _synth_i := 0
var _pcm := PackedByteArray()  # the shimmer as 16-bit PCM, filled a few thousand samples a frame
var _pcm_i := 0
var _sound: AudioStreamWAV
var _take_tried := false    # whether the author's chosen take was looked for (scripts/sfx_takes.gd)
var _pending_open_sound := false


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	stats = {"points": 0, "drawn": 0, "stride": 1, "opened": 0, "state": 0, "frame": false, "line": -1, "sound": false}
	reduced_motion = OS.get_cmdline_user_args().has("--reduced-motion")
	if OS.has_feature("web"):
		reduced_motion = reduced_motion or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))


## The statue, found again whenever observatory.gd rebuilt the hall; what hung from the old one went
## with it.
func _find_statue() -> Node3D:
	if _statue != null and is_instance_valid(_statue) and _statue.is_inside_tree():
		return _statue
	_statue = _obs.find_child("SeldonStatue", true, false) as Node3D if _obs != null else null
	_pivot = null
	_frame = null
	_state = 0
	_pending_open_sound = false
	return _statue


func is_open() -> bool:
	return _state != 0


func _statue_lang() -> String:
	var statue_stats: Variant = _statue.get("stats") if _statue != null else null
	var lang := str((statue_stats as Dictionary).get("lang", "en")) if statue_stats is Dictionary else "en"
	return lang if LINES.has(lang) else "en"


func _hint_text() -> String:
	var touch := DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")
	var pair: Array = HINTS.get(_lang, HINTS.en)
	return str(pair[1] if touch else pair[0])


# --- The points ----------------------------------------------------------------------------------

## The figure's vertices above its base, one per texel of a float texture the shader reads.
func _load_targets() -> bool:
	if _targets != null:
		return true
	if not ResourceLoader.exists(MESH_PATH):
		return false
	var scene: Node = (load(MESH_PATH) as PackedScene).instantiate()
	var found := scene.find_children("*", "MeshInstance3D", true, false)
	var mesh: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
	scene.free()
	if mesh == null:
		return false
	var all: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var kept := PackedVector3Array()
	for v in all:
		if v.y >= BASE_CUT:
			kept.append(v)
	_count = kept.size()
	var rows := (_count + COLUMNS - 1) / COLUMNS
	kept.resize(rows * COLUMNS)
	var image := Image.create_from_data(COLUMNS, rows, false, Image.FORMAT_RGBF, kept.to_byte_array())
	_targets = ImageTexture.create_from_image(image)
	stats.points = _count
	return true


func _build() -> void:
	_pivot = Node3D.new()
	_pivot.name = "SeldonRecording"
	_pivot.position = STAND
	_statue.add_child(_pivot)
	var units := HEIGHT / (1.0 - BASE_CUT)  # metres per unit of the mesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mm.mesh = quad
	mm.instance_count = _count
	# Every point at the origin, unturned: the shader places it. An identity per instance, doubled
	# up to the count rather than set one by one.
	var buffer := PackedFloat32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0])
	while buffer.size() < _count * 12:
		buffer.append_array(buffer)
	buffer.resize(_count * 12)
	mm.buffer = buffer
	_mat = ShaderMaterial.new()
	_mat.shader = load(POINTS_SHADER_PATH) as Shader
	_mat.set_shader_parameter("targets", _targets)
	_mat.set_shader_parameter("columns", COLUMNS)
	_mat.set_shader_parameter("count", _count)
	_mat.set_shader_parameter("base_cut", BASE_CUT)
	_mat.set_shader_parameter("speed", 0.0 if reduced_motion else 1.0)
	_mat.set_shader_parameter("travel", 0.0 if reduced_motion else 1.0)
	_mat.set_shader_parameter("linear_output", not bool(_obs.call("_compatibility")))
	_points = MultiMeshInstance3D.new()
	_points.name = "Points"
	_points.multimesh = mm
	_points.material_override = _mat
	_points.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_points.scale = Vector3.ONE * units
	_points.position = Vector3(0, -BASE_CUT * units, 0)
	# All the instances sit at the origin: the bounds are the figure's, its dust and its flight.
	_points.custom_aabb = AABB(Vector3(-0.8, 0.0, -0.8), Vector3(1.6, 2.0, 1.6))
	_pivot.add_child(_points)
	_caption = Label3D.new()
	_caption.name = "Caption"
	_caption.position = Vector3(0, HEIGHT + 0.3, 0)
	_caption.pixel_size = 0.002  # letters about 6 cm high
	_caption.font_size = 44
	_caption.width = 1.9 / 0.002
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.outline_size = 8
	_caption.outline_modulate = Color(0, 0, 0, 0.55)
	_caption.shaded = false
	_caption.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_caption.modulate = Color(0.78, 0.94, 1.0, 0.0)
	_caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivot.add_child(_caption)
	_voice = AudioStreamPlayer3D.new()
	_voice.name = "Shimmer"
	_voice.position = Vector3(0, 1.2, 0)
	_voice.unit_size = 4.0
	_voice.volume_db = -4.0
	_pivot.add_child(_voice)


# --- Opening and closing -------------------------------------------------------------------------

func toggle() -> void:
	if _state == 1 or _state == 2:
		close()
	elif _state == 0:
		open()


func open() -> void:
	if _find_statue() == null or not _load_targets():
		return
	if _pivot == null:
		_build()
	_lang = _statue_lang()
	# Every second or third point on a weak GPU.
	var quality := _obs.get_node_or_null("Quality")
	var level := int(quality.get("level")) if quality != null else 0
	var stride := 1 if level < 3 else (2 if level < 5 else 3)
	_mat.set_shader_parameter("stride", stride)
	# Fewer points, each larger: about the same light on the figure.
	_mat.set_shader_parameter("size", POINT_M * sqrt(float(stride)))
	_points.multimesh.visible_instance_count = (_count + stride - 1) / stride
	stats.stride = stride
	stats.drawn = _points.multimesh.visible_instance_count
	_face(1.0)
	_pivot.visible = true
	_state = 1
	_t = 0.0
	_scatter_t = 0.0
	stats.opened += 1
	_pending_open_sound = _sound == null
	_play(1.0, -4.0)


func close() -> void:
	if _state == 1 or _state == 2:
		_state = 3
		_scatter_t = 0.0
		_pending_open_sound = false
		_play(0.8, -8.0)


func _play(pitch: float, db: float) -> void:
	if _sound == null or _voice == null:
		return
	_voice.stream = _sound
	_voice.pitch_scale = pitch
	_voice.volume_db = db
	_voice.play()


## Turns him towards the viewer, round the vertical; amount 1 at once, less to ease.
func _face(amount: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _pivot == null:
		return
	var local := _statue.global_transform.affine_inverse() * cam.global_position - _pivot.position
	if Vector2(local.x, local.z).length() < 0.2:
		return
	var yaw := atan2(local.x, local.z)
	_pivot.rotation.y = lerp_angle(_pivot.rotation.y, yaw, amount)


# --- Every frame ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _obs == null or _find_statue() == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# Time by the clock when frames are slow: Godot cuts delta to 0.133 s under 7.5 frames a second
	# (scripts/quality.gd), and a 27 s recording would last a minute on a weak GPU.
	var now := Time.get_ticks_usec()
	var real := float(now - _last_us) / 1e6 if _last_us > 0 else delta
	_last_us = now
	var step := delta if delta < 0.12 else maxf(delta, minf(real, 0.5))
	_update_trigger(cam, step)
	stats.state = _state
	if _state == 0:
		return
	_t += step
	var lines: Array = LINES.get(_lang, LINES.en)
	var speak_from := FORM_S + 0.4
	var speak_to := speak_from + lines.size() * LINE_S
	if _state == 1 and _t >= FORM_S:
		_state = 2
	if _state == 2 and _t >= speak_to + HOLD_S:
		close()
	if _state == 3:
		_scatter_t += step
		if _scatter_t >= SCATTER_S:
			_state = 0
			_pivot.visible = false
			_mat.set_shader_parameter("form", 0.0)
			_mat.set_shader_parameter("scatter", 0.0)
			stats.state = 0
			return
	var form := clampf(_t / FORM_S, 0.0, 1.0)
	_mat.set_shader_parameter("form", form if reduced_motion else 1.0 - pow(1.0 - form, 1.6))
	_mat.set_shader_parameter("scatter", clampf(_scatter_t / SCATTER_S, 0.0, 1.0))
	if not reduced_motion:
		_face(1.0 - exp(-1.2 * step))
	# One line at a time, each fading in and out.
	var line := int(floor((_t - speak_from) / LINE_S)) if _t >= speak_from else -1
	var a := 0.0
	if line >= 0 and line < lines.size():
		var in_line := _t - speak_from - line * LINE_S
		a = clampf(in_line / 0.6, 0.0, 1.0) * clampf((LINE_S - in_line) / 0.6, 0.0, 1.0)
		_caption.text = str(lines[line])
	if _state == 3:
		a *= clampf(1.0 - _scatter_t / 0.6, 0.0, 1.0)
	_caption.modulate.a = a
	stats.line = line if a > 0.0 else -1


## The gold frame round the inscription, the hint, and the held look that plays the recording.
func _update_trigger(cam: Camera3D, step: float) -> void:
	if _frame == null:
		_make_frame()
	var c := _statue.global_transform * INSCRIPTION
	var dist := cam.global_position.distance_to(c)
	var near := clampf((GAZE_REACH + 1.0 - dist) / 1.5, 0.0, 1.0) if _state == 0 else 0.0
	# Only from the front: the name faces the hall.
	var facing := (_statue.global_basis.z).dot(cam.global_position - c) > 0.0
	near *= 1.0 if facing else 0.0
	var forward := -cam.global_basis.z
	var looking := facing and dist < GAZE_REACH and dist > 0.4 and forward.dot((c - cam.global_position).normalized()) > GAZE_COS
	if not looking:
		_latched = false
	if _state == 0 and looking and not _latched:
		_gaze += step
		if _gaze >= GAZE_TIME:
			_gaze = 0.0
			_latched = true
			open()
	else:
		_gaze = maxf(0.0, _gaze - step * 2.0)
	_frame_mat.set_shader_parameter("near", near)
	_frame_mat.set_shader_parameter("fill", _gaze / GAZE_TIME)
	_frame.visible = near > 0.0
	_hint.visible = near > 0.0
	if near > 0.0:
		var lang := _statue_lang()
		if lang != _lang or _hint.text == "":
			_lang = lang
			_hint.text = _hint_text()
	# Finish synthesis even when the recording opens from outside gaze range.
	if near > 0.0 or _pending_open_sound:
		_synth_step()
	_hint.modulate.a = near * 0.85
	stats.frame = _frame.visible


func _make_frame() -> void:
	var quad := QuadMesh.new()
	quad.size = PLATE
	_frame_mat = ShaderMaterial.new()
	_frame_mat.shader = load(FRAME_SHADER_PATH) as Shader
	_frame_mat.set_shader_parameter("size", PLATE)
	_frame = MeshInstance3D.new()
	_frame.name = "InscriptionFrame"
	_frame.mesh = quad
	_frame.material_override = _frame_mat
	_frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 4 mm in front of the letters, which stand 3 mm off the die.
	_frame.position = INSCRIPTION + Vector3(0, 0, 0.004)
	_frame.visible = false
	_statue.add_child(_frame)
	# The hint where he will stand, at eye height.
	_hint = Label3D.new()
	_hint.name = "RecordingHint"
	_hint.position = STAND + Vector3(0, 1.45, 0)
	_hint.pixel_size = 0.0012
	_hint.font_size = 48
	_hint.width = 1.3 / 0.0012
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.outline_size = 8
	_hint.outline_modulate = Color(0, 0, 0, 0.6)
	_hint.shaded = false
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.modulate = Color(1.0, 0.86, 0.58, 0.0)
	_hint.visible = false
	_hint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_statue.add_child(_hint)


# --- Sound ---------------------------------------------------------------------------------------

## A shimmer, made a few thousand samples a frame: a major chord swelling and gliding up a little,
## with high pings scattered over it like the points arriving.
func _synth_step() -> void:
	if _sound == null and not _take_tried:
		# The take the author chose by ear, when its file is in the build: nothing to synthesize.
		_take_tried = true
		var sfx: Script = load(SFX_PATH)
		_sound = sfx.call("take", "seldon_recording-shimmer")
		if _sound != null:
			_sound_ready()
	if _sound != null:
		return
	var n := int(RATE * SOUND_S)
	if _synth.is_empty():
		_synth.resize(n)
	if _synth_i < n:
		var end := mini(_synth_i + 4096, n)
		for i in range(_synth_i, end):
			var t := float(i) / RATE
			var env := smoothstep(0.0, 1.1, t) * (1.0 - smoothstep(2.2, SOUND_S, t))
			var glide := 1.0 + 0.02 * t
			var s := 0.0
			for k in PARTIALS.size():
				var f: float = PARTIALS[k]
				s += sin(TAU * f * glide * t + k * 1.3) * (0.75 + 0.25 * sin(TAU * (2.0 + k * 0.7) * t)) / (k + 1.5)
			_synth[i] = s * env * 0.3
		_synth_i = end
		return
	# Then the pings, four a frame, each from its own seed.
	if _synth_i - n >= PINGS:
		_to_pcm(n)
		return
	var rng := RandomNumberGenerator.new()
	for p in range(_synth_i - n, mini(_synth_i - n + 4, PINGS)):
		rng.seed = 1950 + p
		var at := int(rng.randf_range(0.15, SOUND_S - 0.7) * RATE)
		var f := rng.randf_range(2200.0, 4800.0)
		var amp := rng.randf_range(0.03, 0.07)
		for j in int(0.12 * RATE):
			if at + j >= n:
				break
			var tt := float(j) / RATE
			_synth[at + j] += sin(TAU * f * tt) * amp * exp(-tt * 30.0)
	_synth_i += 4


## Last, into 16-bit PCM, 8192 samples a frame as well: all 74,970 at once took 2.1 ms of one frame
## natively, several times that in WebAssembly (artpass/audio/wavcost.gd, 2026-10-04).
func _to_pcm(n: int) -> void:
	if _pcm.is_empty():
		_pcm.resize(n * 2)
	var end := mini(_pcm_i + 8192, n)
	for i in range(_pcm_i, end):
		_pcm.encode_s16(i * 2, int(clampf(_synth[i], -1.0, 1.0) * 32000.0))
	_pcm_i = end
	if _pcm_i < n:
		return
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = _pcm
	_sound = w
	_synth = PackedFloat32Array()
	_pcm = PackedByteArray()
	_sound_ready()


## The sound is there: an opening that came before it now gets its shimmer.
func _sound_ready() -> void:
	stats.sound = true
	if _pending_open_sound:
		_pending_open_sound = false
		if _state == 1 or _state == 2:
			_play(1.0, -4.0)


static func _wav(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


# --- Input ---------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if (key.physical_keycode if key.physical_keycode != 0 else key.keycode) == KEY_R:
		toggle()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _state != 0:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var at := get_viewport().get_visible_rect().size * 0.5 if captured else mb.position
	if _aim_hits_inscription(at):
		open()
		get_viewport().set_input_as_handled()


## A tap from touch_controls.gd: true when it hit the inscription (and played the recording).
func tap(pos: Vector2) -> bool:
	if _state != 0 or not _aim_hits_inscription(pos):
		return false
	open()
	return true


func _aim_hits_inscription(at: Vector2) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _find_statue() == null:
		return false
	var inv := _statue.global_transform.affine_inverse()
	var o := inv * cam.project_ray_origin(at)
	var d := (inv.basis * cam.project_ray_normal(at)).normalized()
	if d.z > -0.05:
		return false  # from behind, or along the face
	var t := (INSCRIPTION.z - o.z) / d.z
	if t < 0.0 or t > CLICK_REACH:
		return false
	var hit := o + d * t
	# Generous, wider far off, so a phone's thumb finds it.
	var margin := maxf(0.06, t * 0.02)
	return absf(hit.x - INSCRIPTION.x) < PLATE.x * 0.5 + margin and absf(hit.y - INSCRIPTION.y) < PLATE.y * 0.5 + margin
