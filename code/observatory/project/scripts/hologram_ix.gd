extends Node3D
## IX pipelines as holograms over Seldon's statue. The author asked for holograms one can trigger, and
## for IX's pipelines in 3D. Look at the Prime Radiant in Seldon's hands for a second (a gold ring
## fills round it), press H, click it, or tap it on a phone: a real run of one of IX's showcase
## pipelines unfolds in a spiral round the statue, one panel per step, climbing a turn step per
## dependency level, and replays in the order IX ran it, each panel lighting with the step's own
## result. Each opening plays the next pipeline; H again closes it.
##
## The runs are real: artpass/holo/run_ix_pipelines.py drove the local ix-mcp server over the five
## pipelines of IX's examples/canonical-showcase, and bake_ix_holo.py kept each step's dependency
## level, measured duration, a headline of its result and a small chart of it
## (assets/ix_pipelines.json). Nothing is fetched at run time.
##
## It sounds, too, synthesised here: a glide up as it opens and down as it closes, and a glassy
## chime from each panel as its step lights, pitched on a pentatonic scale by dependency level.

const DATA_PATH := "res://assets/ix_pipelines.json"
const SFX_PATH := "res://scripts/sfx_takes.gd"
const PANEL_SHADER_PATH := "res://assets/holo_panel.gdshader"
const EDGE_SHADER_PATH := "res://assets/holo_edge.gdshader"
const RING_SHADER_PATH := "res://assets/holo_ring.gdshader"
## seldon_statue.gd's sphere, in the statue's frame: its SPHERE_CENTRE times FIGURE_HEIGHT, on the
## 1.32 m pedestal.
const SPHERE := Vector3(0.0594, 2.7324, 0.2464)
const PANEL := Vector2(0.62, 0.38)
const RADIUS := 1.55         # metres from the statue's axis to the panels
## Neighbouring levels sit side by side round the spiral, so a level need only climb enough for a
## turn (about 12 panels) to clear the one under it: the 16 steps of the longest pipeline take 1.9 m.
const RISE := 0.16
const BASE_Y := 3.75         # the first level, over Seldon's head (his figure ends at 3.52 m)
const NODE_ANGLE := 0.5      # radians a panel takes round the spiral
const GAZE_REACH := 6.0      # metres: the ring shows, and a held look opens it
const GAZE_COS := 0.9965     # within about 4.8 degrees of the sphere's centre
const GAZE_TIME := 1.0       # seconds of looking
const CLICK_REACH := 16.0
const HOLD := 40.0           # seconds the finished run stays before it fades
const RATE := 22050
const STEP_NOTES := [0, 2, 4, 7, 9, 12, 14, 16]  # semitones over A5, a major pentatonic, by level
const HINTS := {
	"en": ["Look at the sphere, or press H: an IX pipeline", "Tap the sphere: an IX pipeline"],
	"fr": ["Regardez la sphère, ou H : un pipeline IX", "Touchez la sphère : un pipeline IX"],
	"es": ["Mire la esfera, o pulse H: un pipeline IX", "Toque la esfera: un pipeline IX"],
}

var stats := {}
var _obs: Node3D
var _camera: Camera3D
var _data: Array = []
var _next := 0
var _statue: Node3D
var _root: Node3D            # the shown hologram, rebuilt per opening
var _nodes: Array[Node3D] = []
var _panels: Array[ShaderMaterial] = []
var _heads: Array[Label3D] = []
var _edges: Array[Dictionary] = []  # {material, from, to}
var _title: Label3D
var _subtitle: Label3D
var _steps: Array = []
var _times: PackedFloat32Array = PackedFloat32Array()  # when each step (in run order) starts
var _t := 0.0
var _state := 0              # 0 closed, 1 playing, 2 holding, 3 fading
var _fade := 0.0
var _gaze := 0.0
var _latched := false        # a look opened it: the next look waits for the eyes to leave
var _auto_done := false      # the one opening by itself, on the first approach, has had its turn
var _ring: MeshInstance3D
var _ring_mat: ShaderMaterial
var _hint: Label3D
var _lang := "en"
var _panel_shader: Shader
var _edge_shader: Shader
var _sounds := {}           # open, close, step: made when the viewer first comes near
var _sfx: Script            # scripts/sfx_takes.gd, loaded with the sounds
var _next_chime := 0


func configure(obs: Node3D, camera: Camera3D) -> void:
	_obs = obs
	_camera = camera


func _ready() -> void:
	stats = {"pipelines": 0, "steps": 0, "opened": 0, "shown": "", "ring": false}
	if FileAccess.file_exists(DATA_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = (parsed as Dictionary).get("pipelines", [])
	stats.pipelines = _data.size()
	for p: Dictionary in _data:
		stats.steps += (p.get("steps", []) as Array).size()
	_panel_shader = load(PANEL_SHADER_PATH) as Shader
	_edge_shader = load(EDGE_SHADER_PATH) as Shader


## The statue, found again whenever observatory.gd rebuilt the hall.
func _find_statue() -> Node3D:
	if _statue != null and is_instance_valid(_statue) and _statue.is_inside_tree():
		return _statue
	_statue = _obs.find_child("SeldonStatue", true, false) as Node3D if _obs != null else null
	_ring = null
	return _statue


func _sphere_world() -> Vector3:
	var s := _find_statue()
	return s.global_transform * SPHERE if s != null else Vector3.INF


func is_open() -> bool:
	return _state != 0


## The reader's language, from the course shelves' choice (observatory.gd passes it on).
func set_lang(lang: String) -> void:
	_lang = lang if HINTS.has(lang) else "en"
	if _hint != null:
		_hint.text = _hint_text()


func _hint_text() -> String:
	var touch := DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")
	var pair: Array = HINTS.get(_lang, HINTS.en)
	return str(pair[1] if touch else pair[0])


# --- Opening and closing -----------------------------------------------------------------------

## Opens the next pipeline, or closes the one shown.
func toggle() -> void:
	if _state == 1 or _state == 2:
		close()
	else:
		open()


func open(index := -1) -> void:
	if _data.is_empty() or _find_statue() == null:
		return
	if index >= 0:
		_next = index % _data.size()
	var p: Dictionary = _data[_next]
	_next = (_next + 1) % _data.size()
	_build(p)
	_state = 1
	_t = 0.0
	stats.opened += 1
	stats.shown = str(p.get("name", ""))
	_play("open", _sphere_world(), 1.0, -6.0)


func close() -> void:
	if _state == 1 or _state == 2:
		_state = 3
		_fade = 1.0
		_play("close", _sphere_world(), 1.0, -9.0)


func _clear() -> void:
	if _root != null:
		_root.queue_free()
	_root = null
	_nodes.clear()
	_panels.clear()
	_heads.clear()
	_edges.clear()
	_steps = []
	_times = PackedFloat32Array()


# --- Building one pipeline ---------------------------------------------------------------------

func _build(p: Dictionary) -> void:
	_clear()
	_root = Node3D.new()
	_root.name = "IXHologram"
	_statue.add_child(_root)
	_steps = p.get("steps", [])
	var levels: int = int(p.get("levels", 1))
	# Each level takes as much of the spiral as it has steps, so that parallel steps sit side by
	# side and nothing overlaps within a turn; each level climbs RISE.
	var by_level: Array = []
	by_level.resize(levels)
	for l in levels:
		by_level[l] = []
	for i in _steps.size():
		var s: Dictionary = _steps[i]
		(by_level[int(s.level)] as Array).append(i)
	var where := PackedVector3Array()
	where.resize(_steps.size())
	var angle := 0.0
	var prev_width := 0.0
	for l in levels:
		var members: Array = by_level[l]
		var width := NODE_ANGLE * members.size()
		angle += (prev_width + width) * 0.5 if l > 0 else 0.0
		prev_width = width
		for k in members.size():
			var a := angle + (float(k) - (members.size() - 1) * 0.5) * NODE_ANGLE
			# Angle 0 is the statue's front (+z, towards the hall's centre); the spiral climbs anticlockwise.
			where[int(members[k])] = Vector3(sin(a) * RADIUS, BASE_Y + l * RISE, cos(a) * RADIUS)
	for i in _steps.size():
		_nodes.append(_make_node(_steps[i], where[i]))
	for i in _steps.size():
		var s: Dictionary = _steps[i]
		for dep: String in s.get("depends_on", []):
			var j := _index_of(dep)
			if j >= 0:
				_edges.append(_make_edge(where[j], where[i], j, i))
	# The title over the top level, then the pace: a step lasts longer the longer IX took on it.
	var top := Vector3(0, BASE_Y + levels * RISE + 0.35, 0)
	_title = _label("IX · %s" % str(p.get("title", "")), top, 0.0026, 56, true)
	_subtitle = _label("%d steps · %d levels · ix-mcp, run locally" % [_steps.size(), levels], top + Vector3(0, -0.2, 0), 0.0016, 40, true)
	var max_ms := 1.0
	for s: Dictionary in _steps:
		max_ms = maxf(max_ms, float(s.get("ms", 0)))
	var unfold := 0.6 + 0.08 * levels
	var t := unfold
	_times.resize(_steps.size() + 1)
	for i in _steps.size():
		_times[i] = t
		t += 0.55 + 0.95 * float((_steps[i] as Dictionary).get("ms", 0)) / max_ms
	_times[_steps.size()] = t
	_set_title_progress(-1)
	_next_chime = 0


func _index_of(id: String) -> int:
	for i in _steps.size():
		if str((_steps[i] as Dictionary).get("id", "")) == id:
			return i
	return -1


func _make_node(s: Dictionary, at: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = at
	_root.add_child(n)
	var quad := QuadMesh.new()
	quad.size = PANEL
	var mat := ShaderMaterial.new()
	mat.shader = _panel_shader
	var chart: Dictionary = s.get("chart", {})
	var kinds := {"none": 0, "bars": 1, "dots": 2, "range": 3, "line": 4, "pairs": 5, "gauge": 6, "verdict": 7}
	var kind: int = int(kinds.get(str(chart.get("kind", "none")), 0))
	var values := PackedFloat32Array()
	values.resize(96)
	var aux := PackedFloat32Array()
	aux.resize(48)
	var count := 0
	match kind:
		2:
			var cls: Array = chart.get("classes", [])
			count = mini(cls.size(), 96)
			for i in count:
				values[i] = float(cls[i])
		5:
			var pts: Array = chart.get("values", [])
			var dims: Array = chart.get("classes", [])
			count = mini(pts.size() / 2, 48)
			for i in count * 2:
				values[i] = float(pts[i])
			for i in mini(dims.size(), 48):
				aux[i] = float(dims[i])
		7:
			var v := str(chart.get("verdict", "U"))
			values[0] = 1.0 if v in ["T", "P"] else (0.5 if v == "U" else 0.0)
			count = 1
		_:
			var vals: Array = chart.get("values", [])
			count = mini(vals.size(), 96)
			for i in count:
				values[i] = float(vals[i])
	mat.set_shader_parameter("kind", kind)
	mat.set_shader_parameter("count", count)
	mat.set_shader_parameter("values", values)
	mat.set_shader_parameter("aux", aux)
	mat.set_shader_parameter("size", PANEL)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	_panels.append(mat)
	# The step's name over the chart, its tool and result under it.
	var name_label := _label(str(s.get("label", "")), Vector3(0, PANEL.y * 0.36, 0.004), 0.0013, 34, false, n)
	name_label.width = PANEL.x * 0.92 / 0.0013
	var ms := int(s.get("ms", 0))
	var head := _label("%s\n%s · %s" % [str(s.get("headline", "")), str(s.get("tool", "")), ("%d ms" % ms) if ms > 0 else "< 1 ms"],
			Vector3(0, -PANEL.y * 0.33, 0.004), 0.001, 32, false, n)
	head.width = PANEL.x * 0.94 / 0.001
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	head.modulate.a = 0.0
	_heads.append(head)
	return n


func _label(text: String, at: Vector3, pixel: float, font_size: int, billboard: bool, parent: Node3D = null) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = at
	l.pixel_size = pixel
	l.font_size = font_size
	l.outline_size = 0
	l.shaded = false
	l.double_sided = true
	l.no_depth_test = false
	l.modulate = Color(0.75, 1.0, 0.9, 0.0)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent != null else _root).add_child(l)
	return l


## A ribbon from the top of the upstream panel to the bottom of the downstream one, bowed outwards.
func _make_edge(a: Vector3, b: Vector3, from: int, to: int) -> Dictionary:
	var p0 := a + Vector3(0, PANEL.y * 0.5, 0)
	var p3 := b - Vector3(0, PANEL.y * 0.5, 0)
	var out_a := Vector3(a.x, 0, a.z).normalized() * 0.3
	var out_b := Vector3(b.x, 0, b.z).normalized() * 0.3
	var p1 := p0 + out_a + Vector3(0, 0.08, 0)
	var p2 := p3 + out_b - Vector3(0, 0.08, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 24
	var pts := PackedVector3Array()
	for i in n + 1:
		var t := float(i) / n
		var u := 1.0 - t
		pts.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	for i in n:
		var tan_a := (pts[mini(i + 1, n)] - pts[maxi(i - 1, 0)]).normalized()
		var tan_b := (pts[mini(i + 2, n)] - pts[i]).normalized()
		var ua := float(i) / n
		var ub := float(i + 1) / n
		for v: Array in [[pts[i], tan_a, Vector2(ua, 0)], [pts[i + 1], tan_b, Vector2(ub, 0)], [pts[i + 1], tan_b, Vector2(ub, 1)],
				[pts[i], tan_a, Vector2(ua, 0)], [pts[i + 1], tan_b, Vector2(ub, 1)], [pts[i], tan_a, Vector2(ua, 1)]]:
			st.set_normal(v[1])
			st.set_uv(v[2])
			st.add_vertex(v[0])
	var mat := ShaderMaterial.new()
	mat.shader = _edge_shader
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The ribbon widens in the vertex shader: keep it from being culled at its centre line's bounds.
	mi.extra_cull_margin = 0.1
	_root.add_child(mi)
	return {"material": mat, "from": from, "to": to}


func _set_title_progress(done: int) -> void:
	if _subtitle == null:
		return
	var levels := 0
	var total_ms := 0
	for s: Dictionary in _steps:
		levels = maxi(levels, int(s.get("level", 0)) + 1)
		total_ms += int(s.get("ms", 0))
	if done < 0:
		_subtitle.text = "%d steps · %d levels · ix-mcp, run locally" % [_steps.size(), levels]
	elif done < _steps.size():
		_subtitle.text = "step %d of %d · %s" % [done + 1, _steps.size(), str((_steps[done] as Dictionary).get("tool", ""))]
	else:
		_subtitle.text = "%d steps · %d ms in all · ix-mcp, run locally" % [_steps.size(), total_ms]


# --- Every frame -------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _obs == null or _find_statue() == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_update_trigger(cam, delta)
	if _state == 0 or _root == null:
		return
	_t += delta
	var playing_until := _times[_times.size() - 1] if _times.size() > 0 else 0.0
	if _state == 1 and _t > playing_until:
		_state = 2
		_set_title_progress(_steps.size())
	if _state == 2 and _t > playing_until + HOLD:
		_state = 3
		_fade = 1.0
	var global_fade := 1.0
	if _state == 3:
		_fade -= delta / 1.5
		global_fade = maxf(_fade, 0.0)
		if _fade <= 0.0:
			_clear()
			_state = 0
			return
	# A chime as each step lights, from its panel, pitched by its dependency level.
	while _state != 3 and _next_chime < _steps.size() and _t >= _times[_next_chime + 1] - 0.25:
		var lvl := int((_steps[_next_chime] as Dictionary).get("level", 0))
		_play("step", _nodes[_next_chime].global_position, pow(2.0, float(STEP_NOTES[lvl % STEP_NOTES.size()]) / 12.0), -12.0)
		_next_chime += 1
	var unfold := _times[0] if _times.size() > 0 else 0.6
	var running := -1
	for i in _steps.size():
		var s: Dictionary = _steps[i]
		var lvl := int(s.get("level", 0))
		var appear := clampf((_t - lvl * 0.08) / maxf(unfold - 0.3, 0.2), 0.0, 1.0) * global_fade
		var start := _times[i]
		var end := _times[i + 1]
		var lit := 1.0 if _t >= end - 0.25 else 0.0
		if _t >= start and _t < end:
			running = i
		var flash := clampf(1.0 - (_t - (end - 0.25)) / 0.6, 0.0, 1.0) if _t >= end - 0.25 else 0.0
		var mat: ShaderMaterial = _panels[i]
		mat.set_shader_parameter("appear", appear)
		mat.set_shader_parameter("lit", lit)
		mat.set_shader_parameter("flash", flash)
		var head: Label3D = _heads[i]
		head.modulate.a = clampf((_t - (end - 0.25)) / 0.4, 0.0, 1.0) * global_fade
		var name_label := _nodes[i].get_child(1) as Label3D
		if name_label != null:
			name_label.modulate.a = appear * (0.55 + 0.45 * lit)
		# Each panel turns round the vertical to face the viewer.
		var n := _nodes[i]
		var to_cam := cam.global_position - n.global_position
		to_cam.y = 0.0
		if to_cam.length_squared() > 1e-4:
			n.global_basis = Basis.looking_at(-to_cam.normalized(), Vector3.UP)
	for e: Dictionary in _edges:
		var mat: ShaderMaterial = e.material
		var to: int = e.to
		var from: int = e.from
		var start := _times[to]
		var end := _times[to + 1]
		var appear := clampf((_t - 0.2) / maxf(unfold, 0.3), 0.0, 1.0) * global_fade
		mat.set_shader_parameter("appear", appear if _t >= _times[from + 1] - 0.25 else appear * 0.4)
		mat.set_shader_parameter("flow", clampf((_t - start) / maxf((end - start) * 0.6, 0.05), 0.0, 1.0))
		mat.set_shader_parameter("done", 1.0 if _t >= end - 0.25 else 0.0)
	var title_a := clampf(_t / 0.6, 0.0, 1.0) * global_fade
	_title.modulate.a = title_a
	_subtitle.modulate.a = title_a * 0.8
	if _state == 1:
		_set_title_progress(running)


## The first time the viewer comes within GAZE_REACH with the sphere on screen, the hologram opens
## by itself, once a session: the author did not find it behind its key (2026-10-03). Not under a
## probe (a --script main loop), a capture or the selftest, unless --auto-holo asks for it.
func _auto_allowed() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--auto-holo"):
		return true
	if get_tree().get_script() != null:
		return false
	for a: String in args:
		if a == "--selftest" or a == "--flytest" or a.begins_with("--capture="):
			return false
	return true


## The gold ring and the hint round the sphere, and the held look that opens the hologram.
func _update_trigger(cam: Camera3D, delta: float) -> void:
	var c := _sphere_world()
	if c == Vector3.INF:
		return
	if _ring == null:
		_make_ring()
	var dist := cam.global_position.distance_to(c)
	var near := clampf((GAZE_REACH + 1.0 - dist) / 1.5, 0.0, 1.0) if _state == 0 else 0.0
	var forward := -cam.global_basis.z
	var looking := dist < GAZE_REACH and dist > 0.3 and forward.dot((c - cam.global_position).normalized()) > GAZE_COS
	if not _auto_done and _state == 0 and dist < GAZE_REACH and cam.is_position_in_frustum(c):
		_auto_done = true
		if int(stats.opened) == 0 and _auto_allowed():
			open()
			stats.auto_opened = true
	if not looking:
		_latched = false
	if _state == 0 and looking and not _latched:
		_gaze += delta
		if _gaze >= GAZE_TIME:
			_gaze = 0.0
			_latched = true
			open()
	else:
		_gaze = maxf(0.0, _gaze - delta * 2.0)
	_ring_mat.set_shader_parameter("near", near)
	_ring_mat.set_shader_parameter("fill", _gaze / GAZE_TIME)
	_ring.visible = near > 0.0
	_hint.visible = near > 0.0
	if near > 0.0:
		_make_sounds()
		# The hint in the inscription's language, which the course shelves' selector sets.
		var statue_stats: Variant = _statue.get("stats")
		var lang := str((statue_stats as Dictionary).get("lang", "en")) if statue_stats is Dictionary else "en"
		if lang != _lang:
			set_lang(lang)
	_hint.modulate.a = near * 0.85
	stats.ring = _ring.visible


func _make_ring() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.62, 0.62)
	_ring_mat = ShaderMaterial.new()
	_ring_mat.shader = load(RING_SHADER_PATH) as Shader
	_ring = MeshInstance3D.new()
	_ring.name = "IXRing"
	_ring.mesh = quad
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = SPHERE
	_ring.visible = false
	_statue.add_child(_ring)
	_hint = Label3D.new()
	_hint.name = "IXHint"
	_hint.text = _hint_text()
	# Over his head, not across his face; letters about 6 cm high, legible from the ring's reach.
	_hint.position = Vector3(0, SPHERE.y + 1.05, SPHERE.z)
	_hint.pixel_size = 0.0012
	_hint.font_size = 48
	_hint.outline_size = 8
	_hint.outline_modulate = Color(0, 0, 0, 0.6)
	_hint.shaded = false
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.modulate = Color(1.0, 0.86, 0.58, 0.0)
	_hint.visible = false
	_hint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_statue.add_child(_hint)


# --- Sound ---------------------------------------------------------------------------------------

## The three sounds, about 25,000 samples in all: made once, when the viewer first comes near.
func _make_sounds() -> void:
	if not _sounds.is_empty():
		return
	# Opening: a glide from A3 up an octave and a half, its second and third partials faint.
	var n := int(RATE * 0.9)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * 220.0 * pow(2.0, t / 0.9 * 1.5) / RATE
		var env := smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.5, 0.9, t))
		s[i] = (sin(phase) * 0.6 + sin(phase * 2.0) * 0.25 + sin(phase * 3.01) * 0.1) * env * 0.35
	_sounds.open = _wav(s, RATE)
	# Closing: the same, backwards.
	var back := s.duplicate()
	back.reverse()
	_sounds.close = _wav(back, RATE)
	# A step: a glassy pluck on A5, its upper partials dying first.
	n = int(RATE * 0.35)
	s = PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = (sin(TAU * 880.0 * t) + 0.35 * sin(TAU * 1760.0 * t) * exp(-t * 18.0)
				+ 0.2 * sin(TAU * 2643.0 * t) * exp(-t * 25.0)) * exp(-t * 9.0) * 0.3
	_sounds.step = _wav(s, RATE)
	# The takes the author chose by ear replace these where their files are in the build
	# (scripts/sfx_takes.gd); the step's take is tuned to sit where the pluck on A5 did.
	_sfx = load(SFX_PATH)
	stats.sound_takes = _sfx.call("pick_all", _sounds, "hologram_ix-")
	stats.sounds = _sounds.size()


func _play(sound: String, at: Vector3, pitch: float, db: float) -> void:
	if at == Vector3.INF or _statue == null:
		return
	_make_sounds()
	var p := AudioStreamPlayer3D.new()
	p.stream = _sounds[sound]
	p.pitch_scale = pitch * float(_sfx.call("tune", "hologram_ix-" + sound, p.stream))
	p.volume_db = db
	p.unit_size = 4.0
	_statue.add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


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
	if (key.physical_keycode if key.physical_keycode != 0 else key.keycode) == KEY_H:
		toggle()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _state != 0:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var at := get_viewport().get_visible_rect().size * 0.5 if captured else mb.position
	if _aim_hits_sphere(at):
		open()
		get_viewport().set_input_as_handled()


## A tap from touch_controls.gd: true when it hit the sphere (and opened the hologram).
func tap(pos: Vector2) -> bool:
	if _state != 0 or not _aim_hits_sphere(pos):
		return false
	open()
	return true


func _aim_hits_sphere(at: Vector2) -> bool:
	var c := _sphere_world()
	var cam := get_viewport().get_camera_3d()
	if c == Vector3.INF or cam == null:
		return false
	var o := cam.project_ray_origin(at)
	var d := cam.project_ray_normal(at)
	var t := (c - o).dot(d)
	if t < 0.0 or t > CLICK_REACH:
		return false
	# Generous: 30 cm round the 11 cm sphere, wider still far off, so a phone's thumb finds it.
	var r := maxf(0.3, t * 0.03)
	return (o + d * t).distance_to(c) < r
