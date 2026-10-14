extends Node3D
## The particle frieze, after the nanoparticle murals of Apple TV+'s Foundation, which assemble
## themselves out of drifting dust: one mosaic panel over each bay, on the entablature's inner face
## between its two gilt beads, made of light that gathers when looked at. The author asked for "des
## effets de nano-particules pour des fresques comme dans la série TV Foundation". The sixteen panels
## are our own (artpass/fresco/comfyui/make_panels.py): galactic and bookish motifs in the manner of a
## Byzantine gold-leaf mosaic, no people, no lettering, nothing taken from the series.
##
## Idle, a faint gold dust drifts in front of the frieze. Look at a panel for a second (its dust
## gathers as you look), click it or tap it on a phone: the dust flies to it, one particle per tessera,
## and the mosaic lights tessera by tessera from its centre outwards. It stays while looked at, then
## for half a minute, and goes back to dust.
##
## Each panel is a curved strip whose shader cuts the mosaic out tessera by tessera
## (assets/fresco_panel.gdshader); its particles are one MultiMesh moved by its shader
## (assets/fresco_dust.gdshader), both timed by the one reveal value per panel. On a weak GPU
## (scripts/quality.gd at level 3 and over) the idle dust goes and one tessera in two, or in four,
## has a particle. The sound is synthesised here, a few frames at a time once the viewer looks up.

const ATLAS_PATH := "res://assets/fresco_atlas.png"
const PANEL_SHADER_PATH := "res://assets/fresco_panel.gdshader"
const DUST_SHADER_PATH := "res://assets/fresco_dust.gdshader"
const SFX_PATH := "res://scripts/sfx_takes.gd"
## The atlas: 2 columns of 8 panels, each 512 x 128 (4:1), panel b at column b % 2, row b / 2.
const CELL := Vector2(0.5, 0.125)
const GRID := Vector2(128, 32)       # tesserae across and down a panel, one particle each
const SEGMENTS := 32                 # a panel's curve
const ASPECT := 4.0
const SET_BACK := 0.04               # metres in front of the entablature's face, and clear of the arches
const IDLE_SHARE := 0.25             # the share of a panel's particles in the idle dust
const PARTICLE_M := 0.035            # metres across a particle, when every tessera has one
const GAZE_REACH := 34.0             # metres: from the floor across the hall
const GAZE_TIME := 0.9
const GATHER := 0.22                 # how far a looked-at panel's dust goes before it comes
const CLICK_REACH := 34.0
const REVEAL_S := 3.5
const HOLD_S := 30.0                 # after it was last looked at
const DISSOLVE_S := 3.0
const RATE := 22050
const SOUND_S := 2.8
const CHORD := [659.25, 987.77, 1318.51]  # E, B, E: open, glassy
const PINGS := 72
## The moving frescoes (artpass/frescovideo/): each panel's clip, Wan 2.2 TI2V-5B image-to-video from
## the panel's own image, reduced to one texel per tessera, 13 frames at 6 a second (the shader blends
## between them), 8 cells across. A shown panel plays its clip back and forth; the still stays where
## nothing moves.
const MOTION_PATH := "res://assets/fresco_motion.png"
const MOTION_FRAMES := 13
const MOTION_FPS := 6.0
const MOTION_COLS := 8
const MOTION_IN_S := 1.0             # the clip's share rising once the mosaic is whole
const MOTION_OUT_S := 0.6            # and falling before it goes back to dust


## One panel: its strip, its particles and where it is in its coming and going.
class FriezePanel:
	var bay := 0
	var stride := 1
	var a0 := 0.0
	var strip: MeshInstance3D
	var dust: MultiMeshInstance3D
	var strip_mat: ShaderMaterial
	var dust_mat: ShaderMaterial
	var voice: AudioStreamPlayer3D
	var state := 0       # 0 idle, 1 coming, 2 shown, 3 going
	var reveal := 0.0
	var gaze := 0.0
	var hold := 0.0
	var share := IDLE_SHARE  # of its particles shown, eased so none vanish all at once
	var set_reveal := -1.0
	var set_share := -1.0
	var set_count := -1
	var motion := 0.0    # the clip's share, 0 to 1
	var clock := 0.0     # seconds of the clip played
	var set_motion := -1.0
	var set_frame := -1.0


var stats := {}
var reduced_motion := false
var _obs: Node3D
var _camera: Camera3D
var _atlas: Texture2D
var _motion: Texture2D
var _panels: Array[FriezePanel] = []
var _key := []
var _bays := 16
var _r := 12.26
var _ys := Vector2(18.98, 19.86)
var _span := 0.287
var _stride := 1
var _idle_on := true
var _level := -1
var _last_us := 0
var _synth := PackedFloat32Array()
var _synth_i := 0
var _sound: AudioStreamWAV
var _take_tried := false    # whether the author's chosen take was looked for (scripts/sfx_takes.gd)


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	stats = {"panels": 0, "tesserae": int(GRID.x * GRID.y), "stride": 1, "idle": true, "gazed": -1, "gaze": 0.0,
			"opened": 0, "coming": 0, "shown": 0, "going": 0, "drawn": 0, "sound": false, "y": [0.0, 0.0], "width": 0.0,
			"motion": false, "moving": 0}
	reduced_motion = OS.get_cmdline_user_args().has("--reduced-motion")
	if OS.has_feature("web"):
		reduced_motion = reduced_motion or bool(JavaScriptBridge.eval("matchMedia('(prefers-reduced-motion: reduce)').matches", true))


# --- The panels ----------------------------------------------------------------------------------

## The frieze's place from the hall's own measures (observatory.gd): the entablature's inner face, from
## just over the arches' crowns to just under its upper bead; built again if the hall changed.
func _ensure_built() -> bool:
	if _obs == null or not ResourceLoader.exists(ATLAS_PATH):
		return false
	var bays := int(_obs.get("bay_count"))
	var radius := float(_obs.get("colonnade_radius"))
	var height := float(_obs.get("column_height"))
	var key: Array = [bays, radius, height]
	if key == _key and not _panels.is_empty():
		return true
	for p in _panels:
		p.strip.queue_free()
		p.dust.queue_free()
		p.voice.queue_free()
	_panels.clear()
	_key = key
	_bays = bays
	# observatory.gd: the entablature's face at radius - 0.7, its beads at ent_y + 0.4 and + 1.7 (ent_y
	# = height - 0.8); the arches spring at height - 2.9 and rise half a bay's chord and 0.3 over it.
	_r = radius - 0.7 - SET_BACK
	var crown := height - 2.9 + radius * sin(PI / bays) + 0.3
	_ys = Vector2(crown + SET_BACK, height - 0.8 + 1.7 - SET_BACK)
	_span = (_ys.y - _ys.x) * ASPECT / _r
	if _atlas == null:
		_atlas = load(ATLAS_PATH) as Texture2D
	if _motion == null and ResourceLoader.exists(MOTION_PATH):
		_motion = load(MOTION_PATH) as Texture2D
	stats.motion = _motion != null
	var motion_rows := ceilf(16.0 * MOTION_FRAMES / MOTION_COLS)
	var strip_mesh := _strip_mesh()
	var linear := not bool(_obs.call("_compatibility"))
	var panel_shader := load(PANEL_SHADER_PATH) as Shader
	var dust_shader := load(DUST_SHADER_PATH) as Shader
	for b in bays:
		var p := FriezePanel.new()
		p.bay = b
		p.a0 = TAU * (b + 0.5) / bays
		var cell := Vector4(float(b % 2) * CELL.x, float((b / 2) % 8) * CELL.y, CELL.x, CELL.y)
		p.strip_mat = ShaderMaterial.new()
		p.strip_mat.shader = panel_shader
		p.strip_mat.set_shader_parameter("atlas", _atlas)
		p.strip_mat.set_shader_parameter("cell", cell)
		p.strip_mat.set_shader_parameter("grid", GRID)
		p.strip_mat.set_shader_parameter("linear_output", linear)
		p.strip_mat.set_shader_parameter("glint", 0.0 if reduced_motion else 1.0)
		if _motion != null:
			p.strip_mat.set_shader_parameter("motion_atlas", _motion)
			p.strip_mat.set_shader_parameter("motion_cells", Vector2(MOTION_COLS, motion_rows))
			p.strip_mat.set_shader_parameter("motion_base", float((b % 16) * MOTION_FRAMES))
			p.strip_mat.set_shader_parameter("motion_frames", float(MOTION_FRAMES))
		p.strip = MeshInstance3D.new()
		p.strip.name = "FriezePanel%d" % b
		p.strip.mesh = strip_mesh
		p.strip.material_override = p.strip_mat
		p.strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# The strip is built round angle 0; turning it by -a0 about the vertical puts it at a0.
		p.strip.rotation.y = -p.a0
		p.strip.visible = false
		add_child(p.strip)
		p.dust_mat = ShaderMaterial.new()
		p.dust_mat.shader = dust_shader
		p.dust_mat.set_shader_parameter("atlas", _atlas)
		p.dust_mat.set_shader_parameter("cell", cell)
		p.dust_mat.set_shader_parameter("grid", GRID)
		p.dust_mat.set_shader_parameter("a0", p.a0)
		p.dust_mat.set_shader_parameter("span", _span)
		p.dust_mat.set_shader_parameter("radius", _r)
		p.dust_mat.set_shader_parameter("ys", _ys)
		p.dust_mat.set_shader_parameter("speed", 0.0 if reduced_motion else 1.0)
		p.dust_mat.set_shader_parameter("travel", 0.0 if reduced_motion else 1.0)
		p.dust_mat.set_shader_parameter("linear_output", linear)
		p.dust = MultiMeshInstance3D.new()
		p.dust.name = "FriezeDust%d" % b
		p.dust.multimesh = _dust_multimesh()
		p.dust.material_override = p.dust_mat
		p.dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Every instance sits at the origin: the bounds are the panel's, its dust's and their flight's,
		# from the face out to about 4 m from it.
		var mid := Vector3(cos(p.a0), 0.0, sin(p.a0)) * (_r - 1.9)
		p.dust.custom_aabb = AABB(mid - Vector3(3.6, 0.0, 3.6) + Vector3(0, _ys.x - 0.9, 0), Vector3(7.2, _ys.y - _ys.x + 1.8, 7.2))
		add_child(p.dust)
		p.voice = AudioStreamPlayer3D.new()
		p.voice.name = "FriezeSound%d" % b
		p.voice.position = Vector3(cos(p.a0), 0.0, sin(p.a0)) * (_r - 0.5) + Vector3(0, (_ys.x + _ys.y) * 0.5, 0)
		p.voice.unit_size = 10.0
		add_child(p.voice)
		_panels.append(p)
	stats.panels = _panels.size()
	stats.y = [snappedf(_ys.x, 0.01), snappedf(_ys.y, 0.01)]
	stats.width = snappedf(_span * _r, 0.01)
	_level = -1
	return true


func _strip_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in SEGMENTS + 1:
		var u := float(i) / SEGMENTS
		var a := (u - 0.5) * _span
		var out := Vector3(cos(a), 0.0, sin(a))
		for row in 2:
			verts.append(out * _r + Vector3(0, _ys.y if row == 0 else _ys.x, 0))
			normals.append(-out)
			uvs.append(Vector2(u, float(row)))
		if i > 0:
			var k := (i - 1) * 2
			indices.append_array(PackedInt32Array([k, k + 2, k + 1, k + 1, k + 2, k + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _dust_multimesh() -> MultiMesh:
	var count := int(GRID.x * GRID.y)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mm.mesh = quad
	mm.instance_count = count
	# Every particle at the origin, unturned: the shader places it (as in seldon_recording.gd).
	var buffer := PackedFloat32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0])
	while buffer.size() < count * 12:
		buffer.append_array(buffer)
	buffer.resize(count * 12)
	mm.buffer = buffer
	mm.visible_instance_count = 0
	return mm


# --- Coming and going ----------------------------------------------------------------------------

## Brings a panel's mosaic, or keeps it if it is there; false when there is no such panel.
func summon(bay: int) -> bool:
	if bay < 0 or bay >= _panels.size():
		return false
	var p: FriezePanel = _panels[bay]
	p.hold = HOLD_S
	if p.state == 0 or p.state == 3:
		p.state = 1
		stats.opened += 1
		_play(p, 1.0 + 0.03 * float(bay % 5 - 2), -4.0)
	return true


func _play(p: FriezePanel, pitch: float, db: float) -> void:
	if _sound == null:
		return
	p.voice.stream = _sound
	p.voice.pitch_scale = pitch
	p.voice.volume_db = db
	p.voice.play()


# --- Every frame ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _ensure_built():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# Time by the clock when frames are slow, as seldon_recording.gd does: Godot cuts delta to 0.133 s
	# under 7.5 frames a second.
	var now := Time.get_ticks_usec()
	var real := float(now - _last_us) / 1e6 if _last_us > 0 else delta
	_last_us = now
	var step := delta if delta < 0.12 else maxf(delta, minf(real, 0.5))
	_apply_quality()
	var inv := global_transform.affine_inverse()
	var origin := inv * cam.global_position
	var forward := (inv.basis * -cam.global_basis.z).normalized()
	var gazed := _panel_on_ray(origin, forward, GAZE_REACH)
	# Looking up at the frieze: time to make the sound, a little each frame.
	if forward.y > 0.25:
		_synth_step()
	stats.gazed = gazed
	stats.gaze = 0.0
	var counts: Array[int] = [0, 0, 0, 0]
	var drawn := 0
	var moving := 0
	for p in _panels:
		var looked := p.bay == gazed
		match p.state:
			0:
				p.gaze = minf(p.gaze + step, GAZE_TIME) if looked else maxf(0.0, p.gaze - step * 2.0)
				if p.gaze >= GAZE_TIME:
					p.gaze = 0.0
					summon(p.bay)
				else:
					# The dust gathers as the look holds, and settles back if it goes.
					var f := p.gaze / GAZE_TIME
					p.reveal = GATHER * f * f * (3.0 - 2.0 * f)
			1:
				p.reveal = minf(1.0, p.reveal + step / REVEAL_S)
				if p.reveal >= 1.0:
					p.state = 2
					p.hold = HOLD_S
			2:
				p.hold = HOLD_S if looked else p.hold - step
				if p.hold <= 0.0:
					p.state = 3
					_play(p, 0.82, -9.0)
			3:
				if looked:
					summon(p.bay)
				else:
					p.reveal = maxf(0.0, p.reveal - step / DISSOLVE_S)
					if p.reveal <= 0.0:
						p.state = 0
		if looked:
			stats.gaze = snappedf(p.gaze / GAZE_TIME if p.state == 0 else 1.0, 0.01)
		counts[p.state] += 1
		drawn += _show(p, step)
		if p.motion > 0.0:
			moving += 1
	stats.moving = moving
	stats.coming = counts[1]
	stats.shown = counts[2]
	stats.going = counts[3]
	stats.drawn = drawn


## Sets what changed on a panel's materials and particles; returns the particles drawn.
func _show(p: FriezePanel, step: float) -> int:
	if p.stride != _stride and p.state == 0 and p.gaze <= 0.0 and p.reveal <= 0.0:
		_set_stride(p, _stride)
	var all := int(GRID.x * GRID.y) / p.stride
	# The share of the particles in the dust: the idle quarter (none on a weak GPU), all of them as a
	# look gathers them or the mosaic comes and goes. Down slowly, so that once a mosaic has gone back
	# to dust the extra particles fade out over a few seconds rather than vanish together.
	var base := IDLE_SHARE if _idle_on else 0.0
	var target := 1.0 if p.state != 0 else base + (1.0 - base) * clampf(p.reveal / GATHER, 0.0, 1.0)
	p.share = move_toward(p.share, target, step * (2.0 if target > p.share else 0.25))
	var share := p.share
	var count := 0
	if p.state != 2 and share > 0.0:
		count = mini(all, int(ceil(all * (share + 0.08))))  # none while the mosaic is whole: each is a lit tessera
	if p.reveal != p.set_reveal:
		p.set_reveal = p.reveal
		p.strip_mat.set_shader_parameter("reveal", p.reveal)
		p.dust_mat.set_shader_parameter("reveal", p.reveal)
		# No tessera lights before 0.27 (fresco_panel.gdshader).
		p.strip.visible = p.reveal > 0.26
	if share != p.set_share:
		p.set_share = share
		p.dust_mat.set_shader_parameter("idle_share", share)
	if count != p.set_count:
		p.set_count = count
		p.dust.multimesh.visible_instance_count = count
		p.dust.visible = count > 0
	# The clip: once the mosaic is whole it comes in over a second and plays back and forth; it goes
	# before the mosaic goes back to dust, and starts again from its first frame the next time.
	var moving := p.state == 2 and _motion != null and not reduced_motion
	p.motion = move_toward(p.motion, 1.0 if moving else 0.0, step / (MOTION_IN_S if moving else MOTION_OUT_S))
	p.clock = p.clock + step if p.motion > 0.0 else 0.0
	if p.motion != p.set_motion:
		p.set_motion = p.motion
		p.strip_mat.set_shader_parameter("motion_mix", p.motion)
	if p.motion > 0.0:
		var frame := _motion_frame(p.clock)
		if frame != p.set_frame:
			p.set_frame = frame
			p.strip_mat.set_shader_parameter("motion_frame", frame)
	return count


## Where a clip is after t seconds, between frames: forwards, then backwards, then again.
func _motion_frame(t: float) -> float:
	var last := float(MOTION_FRAMES - 1)
	var pos := fmod(t * MOTION_FPS, 2.0 * last)
	return pos if pos <= last else 2.0 * last - pos


## On a weak GPU: no idle dust, and fewer particles in each flight. A panel takes the new stride only
## while it rests (_show), so no particle jumps in the middle of its flight.
func _apply_quality() -> void:
	var quality := _obs.get_node_or_null("Quality")
	var level := int(quality.get("level")) if quality != null else 0
	if level == _level:
		return
	_level = level
	_idle_on = level < 3 and not reduced_motion
	_stride = 1 if level < 3 else (2 if level < 5 else 4)
	stats.idle = _idle_on
	stats.stride = _stride
	for p in _panels:
		p.set_count = -1


func _set_stride(p: FriezePanel, stride: int) -> void:
	p.stride = stride
	p.dust_mat.set_shader_parameter("stride", stride)
	p.dust_mat.set_shader_parameter("drawn", int(GRID.x * GRID.y) / stride)
	# Fewer particles, each larger: about the same light in the flight.
	p.dust_mat.set_shader_parameter("size", PARTICLE_M * sqrt(float(stride)))
	p.set_count = -1


## The panel a ray meets, in the frieze's frame, or -1: where it leaves the cylinder of the panels'
## faces (from inside the hall the only crossing ahead; from a gallery outside it, the far one).
func _panel_on_ray(o: Vector3, d: Vector3, reach: float) -> int:
	var a := d.x * d.x + d.z * d.z
	if a < 1e-6 or _panels.is_empty():
		return -1
	var b := 2.0 * (o.x * d.x + o.z * d.z)
	var c := o.x * o.x + o.z * o.z - _r * _r
	var disc := b * b - 4.0 * a * c
	if disc < 0.0:
		return -1
	var t := (-b + sqrt(disc)) / (2.0 * a)
	if t <= 0.0 or t > reach:
		return -1
	var hit := o + d * t
	# Generous, wider far off, so a phone's thumb finds it.
	var margin := maxf(0.15, t * 0.012)
	if hit.y < _ys.x - margin or hit.y > _ys.y + margin:
		return -1
	var bay_angle := TAU / _bays
	var angle := fposmod(atan2(hit.z, hit.x), TAU)
	var bay := mini(int(angle / bay_angle), _bays - 1)
	var off := (angle - (bay + 0.5) * bay_angle) * _r
	return bay if absf(off) < _span * _r * 0.5 + margin else -1


# --- Sound ---------------------------------------------------------------------------------------

## Glass settling: an open fifth swelling under a rain of tiny high pings, timed like the tesserae's
## arrivals, made a few thousand samples a frame.
func _synth_step() -> void:
	if _sound == null and not _take_tried:
		# The take the author chose by ear, when its file is in the build: nothing to synthesize.
		_take_tried = true
		var sfx: Script = load(SFX_PATH)
		_sound = sfx.call("take", "fresco_frieze-settle")
		if _sound != null:
			stats.sound = true
	if _sound != null:
		return
	var n := int(RATE * SOUND_S)
	if _synth.is_empty():
		_synth.resize(n)
	if _synth_i < n:
		var end := mini(_synth_i + 4096, n)
		for i in range(_synth_i, end):
			var t := float(i) / RATE
			var env := smoothstep(0.0, 0.8, t) * (1.0 - smoothstep(1.7, SOUND_S, t))
			var s := 0.0
			for k in CHORD.size():
				var f: float = CHORD[k]
				s += sin(TAU * f * t + k * 1.1) * (0.7 + 0.3 * sin(TAU * (3.0 + k * 1.3) * t)) / (k + 2.0)
			_synth[i] = s * env * 0.2
		_synth_i = end
		return
	# Then the pings, six a frame, each from its own seed, densest in the middle of the arrivals.
	var rng := RandomNumberGenerator.new()
	for q in range(_synth_i - n, mini(_synth_i - n + 6, PINGS)):
		rng.seed = 3100 + q
		var at := int((0.15 + 1.95 * (rng.randf() + rng.randf()) * 0.5) * RATE)
		var f := rng.randf_range(2000.0, 5600.0)
		var amp := rng.randf_range(0.02, 0.055)
		for j in int(0.1 * RATE):
			if at + j >= n:
				break
			var tt := float(j) / RATE
			_synth[at + j] += sin(TAU * f * tt) * amp * exp(-tt * 45.0)
	_synth_i += 6
	if _synth_i - n >= PINGS:
		_sound = _wav(_synth, RATE)
		_synth = PackedFloat32Array()
		stats.sound = true


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

func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var at := get_viewport().get_visible_rect().size * 0.5 if captured else mb.position
	var bay := _aim(at)
	if bay >= 0 and _panels[bay].state != 2:
		summon(bay)
		get_viewport().set_input_as_handled()


## A tap from touch_controls.gd: true when it hit a panel (and brought or kept its mosaic).
func tap(pos: Vector2) -> bool:
	return summon(_aim(pos))


func _aim(at: Vector2) -> int:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _panels.is_empty():
		return -1
	var inv := global_transform.affine_inverse()
	return _panel_on_ray(inv * cam.project_ray_origin(at), (inv.basis * cam.project_ray_normal(at)).normalized(), CLICK_REACH)
