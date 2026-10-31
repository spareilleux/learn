extends Node3D
## A terminal of light over one of the glassworks' pedestals (scripts/glassworks.gd), the author's asks on
## 2026-10-18: one pedestal walks through every course of the site, Streeling's included (« arborescence avec
## système de navigation 3d »), another through their Claude artifacts (« la liste, et drill down vers détail avec
## breadcrumb »).
##
## A tree walked in 3D. The current level's items turn on a drum that the wheel scrolls; a click goes down into one,
## and the level left behind stays as a glass card stacked behind and above the new one, its title showing over it:
## a click on it goes back up, as do the breadcrumb's chips and Backspace. A leaf opens as a card with its page's
## link, which the system's browser opens.
##
## Aimed like Seldon's hologram (scripts/hologram_ix.gd): the screen's centre while the mouse is captured, the
## pointer otherwise; the clicks and the wheel it takes are not passed on to the flying camera. One terminal is open
## at a time. A private one (the artifacts) shows nothing while the live view casts in public (_cast_public of
## artpass/foundation/live/live_rtx.gd, the tree's main loop there).

## The card's size; its back plate stands BACK behind the text, the drum's rows between the two.
const PANEL := Vector2(1.0, 0.68)
const BACK := -0.1
const PIXEL := 0.0006
const ROW := Vector2(0.92, 0.058)
const DRUM_R := 0.5
const DRUM_Y := -0.04
const ROW_PITCH := 0.072
const STEP_A := ROW_PITCH / DRUM_R
## Each level left behind: up, back and smaller, so that its title shows over the next card, all of them up to the
## root (the author: « ne pas perdre la trace des parents jusqu'au root »).
const STACK := Vector3(0.0, 0.1, -0.2)
const STACK_ALPHA := [1.0, 0.62, 0.48, 0.4, 0.34, 0.3]
## A page to read: a taller card, its text in lines between VIEW_TOP and VIEW_BOTTOM, scrolled by the wheel.
## The top band of a card, its title and path, which stays see-through.
const BAND := 0.135
const READER := Vector2(1.0, 0.8)
const READER_Y := -0.06
const VIEW_TOP := 0.195
const VIEW_BOTTOM := -0.35
const TEXT_X := -0.43
const TEXT_W := 0.8
const WHEEL_M := 0.075
const TEXT_DIR := "res://assets/course_text"
const AIM_GLOW := preload("res://scripts/aim_glow.gd")
## Each kind of block: its size in pixels, the space before it and after it (metres).
const STYLE := {
	"h1": [36, 0.03, 0.012], "h2": [32, 0.026, 0.01], "h3": [28, 0.02, 0.008], "p": [25, 0.0, 0.014],
	"li": [25, 0.0, 0.008], "quote": [24, 0.004, 0.014], "code": [21, 0.006, 0.016], "table": [20, 0.006, 0.016],
	"diagram": [23, 0.006, 0.016], "tab": [25, 0.016, 0.008], "meta": [20, 0.0, 0.012],
}
## The card's middle this high over the projector, which stands at the piece's top (`apex` over the cap).
const LIFT := 0.57
const REACH := 6.0
const CLOSE_AT := 7.5
const TAG_AT := 5.0
const UI := {
	"click": {"en": "click to open", "fr": "cliquer pour ouvrir", "es": "clic para abrir"},
	"overview": {"en": "Course overview", "fr": "Présentation du cours", "es": "Presentación del curso"},
	"about": {"en": "The issue itself", "fr": "L'issue elle-même", "es": "La issue en sí"},
	"open": {"en": "Open the page ›", "fr": "Ouvrir la page ›", "es": "Abrir la página ›"},
	"back": {"en": "‹ Back", "fr": "‹ Retour", "es": "‹ Volver"},
	"hint": {"en": "wheel: scroll · click: open · Backspace: up", "fr": "molette : défiler · clic : ouvrir · retour arrière : remonter",
			"es": "rueda: desplazar · clic: abrir · retroceso: subir"},
	"missing": {"en": "Nothing to show yet", "fr": "Rien à montrer pour l'instant", "es": "Nada que mostrar todavía"},
	"prev": {"en": "‹ Previous", "fr": "‹ Précédente", "es": "‹ Anterior"},
	"next": {"en": "Next ›", "fr": "Suivante ›", "es": "Siguiente ›"},
	"cited": {"en": "Cited code (%d) ›", "fr": "Code cité (%d) ›", "es": "Código citado (%d) ›"},
	"cited_title": {"en": "Code cited by the page", "fr": "Code cité par la page", "es": "Código citado por la página"},
	"diagram": {"en": "Diagram", "fr": "Schéma", "es": "Diagrama"},
	"no_text": {"en": "This page's text is not in the scene yet.", "fr": "Le texte de cette page n'est pas encore dans la scène.",
			"es": "El texto de esta página aún no está en la escena."},
}
## A voice's commands (the author: « Retour doit aussi pouvoir se faire au clavier et à la voix »): what IX's listener
## heard while the Observatory had the focus, {"t": unix ms, "text": …} in %LOCALAPPDATA%/VOICE_FILE (asked of IX's
## session on 2026-10-18; read here, never written). Only a short utterance counts, and only for the open terminal.
const VOICE_FILE := "voice-listen/observatory.json"
const VOICE_EVERY := 0.25
const VOICE_WORDS := 4
const VOICE := {
	"back": ["retour", "reviens", "remonte", "en arrière", "back", "go back", "volver", "atrás", "atras"],
	"next": ["suivant", "suivante", "page suivante", "next", "siguiente"],
	"prev": ["précédent", "précédente", "precedent", "precedente", "previous", "anterior"],
	"down": ["descends", "descend", "plus bas", "défile", "down", "scroll down", "abajo", "baja"],
	"up": ["monte", "plus haut", "up", "scroll up", "arriba", "sube"],
	"close": ["ferme", "fermer", "close", "cierra", "cerrar"],
}
const PANEL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 tint = vec3(0.55, 0.75, 1.0);
uniform vec2 size = vec2(1.0, 0.68);
uniform float alpha = 1.0;
uniform float fill = 0.5;
uniform float hover = 0.0;
uniform float radius = 0.022;
// The card's top band (its title and the path), this many metres, stays see-through: the author, 2026-10-18,
// « les panneaux devraient être plus opaques sauf pour la barre du haut ».
uniform float band = 0.0;
uniform float band_fill = 0.4;
// Frosted glass, the author's « comme du verre », « super high tech », a sci-fi interface (relayed by IX's session):
// what is behind, blurred (a mip of the screen) and darkened under the tint; thin lit edges with brighter corner
// brackets and a halo; a line under the top band; faint scanlines and grid, which fade out before they would shimmer;
// a slow sheen. `frosted` 0 for the small plates on a card, plain tint.
uniform float frost = 4.5;
uniform float frosted = 1.0;
void fragment() {
	vec2 p = (UV - 0.5) * size;
	vec2 hs = size * 0.5;
	vec2 q = abs(p) - hs + radius;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	float aa = fwidth(d) + 1e-5;
	float inside = 1.0 - smoothstep(-aa, aa, d);
	float rim = 1.0 - smoothstep(0.0, 0.0018 + aa, abs(d + 0.0015));
	vec2 c = hs - abs(p);
	float corner = step(c.x, 0.06) * step(c.y, 0.06);
	float bracket = corner * (1.0 - smoothstep(0.0, 0.0035 + aa, abs(d + 0.004)));
	float glow = (1.0 - smoothstep(0.0, 0.012, d)) * step(0.0, d);
	float top = band > 0.0 ? smoothstep(-0.003, 0.003, p.y - (hs.y - band)) : 0.0;
	float sep = band > 0.0 ? 1.0 - smoothstep(0.0, 0.0012 + fwidth(p.y), abs(p.y - (hs.y - band))) : 0.0;
	sep *= step(abs(p.x), hs.x - 0.03);
	float scan = (0.5 + 0.5 * sin(p.y * 6.2832 / 0.004)) * (1.0 - smoothstep(0.0005, 0.001, fwidth(p.y)));
	vec2 g = abs(fract(p / 0.04 + 0.5) - 0.5) * 0.04;
	float grid = (1.0 - smoothstep(0.0, 0.0006 + fwidth(p.x), min(g.x, g.y))) * (1.0 - smoothstep(0.0015, 0.003, fwidth(p.x)));
	float sheen = (1.0 - smoothstep(0.0, 0.12, abs(fract((p.x + p.y * 0.6) * 0.7 - TIME * 0.04) - 0.5))) * 0.5;
	vec3 back = min(textureLod(screen_tex, SCREEN_UV, frost).rgb, vec3(1.0));
	vec3 glass = mix(tint * (0.05 + 0.16 * hover), back * 0.25 + tint * (0.05 + 0.12 * hover), frosted);
	glass += tint * (0.025 * scan + 0.045 * grid + 0.035 * sheen) * frosted;
	float body = mix(fill, band_fill, top);
	ALBEDO = mix(glass, tint * 1.4, clamp(rim * 0.8 + bracket + sep * 0.6, 0.0, 1.0)) + tint * glow * 0.6;
	ALPHA = clamp((inside * body * (0.85 + 0.4 * hover) + rim * (0.7 + 0.3 * hover) + bracket + sep * 0.5 + glow * 0.25) * alpha, 0.0, 1.0);
}
"""
const FAN_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 tint = vec3(0.55, 0.75, 1.0);
uniform float alpha = 1.0;
void fragment() {
	float edge = 1.0 - abs(UV.x - 0.5) * 2.0;
	ALBEDO = tint * pow(UV.y, 1.6) * (0.35 + 0.65 * edge) * 0.32 * alpha * (0.9 + 0.1 * sin(TIME * 3.0 + UV.y * 9.0));
}
"""

## What it walks: a tree of {label, children, description, url, note, kind} (assets/course_tree.json, made by
## artpass/pedestals/course_tree.py), or the artifacts' catalogue {artifacts: [...]}
## (artpass/pedestals/artifacts_catalogue.py), read when it first opens.
@export var data_path := "res://assets/course_tree.json"
## Where its nodes' texts are ("text": "<file>|<slug>"): the courses', or the Wayfinder issues' (wayfinder_tree.py).
@export var text_dir := TEXT_DIR
@export var title := {"en": "Courses", "fr": "Cours", "es": "Cursos"}
@export var tint := Color(0.55, 0.75, 1.0)
@export var private := false
## The pedestal's cap, where the piece stands, and the piece's top over it (it floats: scripts/glassworks.gd).
@export var top := 0.95
@export var apex := 0.14
## The glass piece it opens from, lit while aimed at (scripts/aim_glow.gd); glassworks.gd sets it.
var piece: Node3D

var stats := {"loaded": false, "nodes": 0, "open": false, "depth": 0}

class Layer:
	var data: Dictionary
	var items: Array = []
	var node: Node3D
	var plate: MeshInstance3D
	var plate_mat: ShaderMaterial
	var title: Label3D
	var title_at := Vector3.ZERO
	var count: Label3D
	var body: Node3D
	var rows: Array = []      # [Node3D, ShaderMaterial, Label3D, Label3D]
	var mats: Array = []      # the body's other plates
	var labels: Array = []    # the body's other words
	var hits: Array = []      # [Node3D, Vector2 size, Callable, ShaderMaterial or null]
	var card := false
	var reader := false
	var size := PANEL
	var index := -1           # its place among its parent's items
	var cites: Array = []     # a page's cited code, by id
	var file := ""            # its texts' file
	var lines: Array = []     # [top, height, text, px, mono, x, kind, plate: 0 none, 1 code, 2 cited lines]
	var content_h := 0.0
	var scroll_m := 0.0
	var scroll_m_to := 0.0
	var pool: Array = []      # Label3D, one per line on view
	var pool_line: Array = [] # the line each one shows
	var plates: Array = []    # [MeshInstance3D, StandardMaterial3D]
	var thumb: MeshInstance3D
	var thumb_mat: StandardMaterial3D
	var scroll := 0.0
	var scroll_to := 0.0
	var alpha := 0.0
	var alpha_to := 1.0
	var body_alpha := 1.0
	var body_to := 1.0
	var pos_to := Vector3.ZERO
	var scale_to := 1.0
	var depth := 0

var _root_data: Dictionary = {}
var _data_mtime := 0
var _lang := "fr"
var _shelves: Node
var _holo: Node3D
var _stack: Node3D
var _fan_mat: ShaderMaterial
var _tag: Label3D
var _tag_sub: Label3D
var _tag_a := 0.0
var _is_open := false
var _open_t := 0.0
var _path: Array = []
var _layers: Array = []
var _leaving: Array = []
var _hits: Array = []
var _hovered: ShaderMaterial
var _player: AudioStreamPlayer3D
var _hidden := false
var _look_for_shelves := 0.0
var _text_cache := {}
var _voice_path := ""
var _voice_t := 0.0
var _voice_seen := 0.0
var _glow := 0.0
static var _shaders := {}
static var _tick: AudioStreamWAV
static var _mono: Font


func _ready() -> void:
	add_to_group("glass_terminals")
	_holo = Node3D.new()
	_holo.name = "Holo"
	_holo.position = Vector3(0.0, top + apex, 0.0)
	_holo.visible = false
	add_child(_holo)
	_stack = Node3D.new()
	_stack.name = "Stack"
	_stack.position = Vector3(0.0, LIFT, 0.0)
	_holo.add_child(_stack)
	_holo.add_child(_make_fan())
	_tag = _text(self, "", Vector3(0.0, top + 0.52, 0.0), 40, HORIZONTAL_ALIGNMENT_CENTER, 0.6)
	_tag.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_tag_sub = _text(self, "", Vector3(0.0, top + 0.47, 0.0), 22, HORIZONTAL_ALIGNMENT_CENTER, 0.6)
	_tag_sub.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_front()
	_player = AudioStreamPlayer3D.new()
	_player.volume_db = -16.0
	_player.unit_size = 3.0
	_holo.add_child(_player)
	_find_shelves()
	_name_tag()
	var local := OS.get_environment("LOCALAPPDATA")
	if local != "" and not OS.has_feature("web"):
		_voice_path = local.path_join(VOICE_FILE)
		_voice_seen = _voice_stamp()


## The language of the course shelves (scripts/course_library.gd), followed when the reader changes it.
func _find_shelves() -> void:
	if _shelves != null and is_instance_valid(_shelves):
		return
	_shelves = get_tree().root.find_child("CourseShelves", true, false)
	if _shelves == null:
		return
	_lang = str(_shelves.get("lang"))
	if _shelves.has_signal("lang_changed") and not _shelves.is_connected("lang_changed", _on_lang):
		_shelves.connect("lang_changed", _on_lang)


func _on_lang(code: String) -> void:
	if code == _lang:
		return
	_lang = code
	_name_tag()
	if _is_open:
		_rebuild()


func _name_tag() -> void:
	_tag.text = _t(title)
	_tag_sub.text = _t(UI.click)


func _t(v: Variant) -> String:
	if v is Dictionary:
		var d: Dictionary = v
		return str(d.get(_lang, d.get("en", "")))
	return "" if v == null else str(v)


# --- Data ----------------------------------------------------------------------------------------

func _load() -> void:
	var mtime := FileAccess.get_modified_time(data_path) if FileAccess.file_exists(data_path) else 0
	if stats.loaded and mtime == _data_mtime:
		return
	_data_mtime = mtime
	_root_data = {"label": title, "kind": "root", "children": []}
	var f := FileAccess.open(data_path, FileAccess.READ)
	if f == null:
		stats.error = "cannot read %s" % data_path
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		stats.error = "not a tree: %s" % data_path
		return
	var d: Dictionary = parsed
	if d.get("root") is Dictionary:
		_root_data = d.root
	elif d.get("artifacts") is Array:
		_root_data = _from_artifacts(d.artifacts)
	stats.loaded = true
	stats.nodes = _size(_root_data)


func _size(node: Dictionary) -> int:
	var n := 1
	for c: Variant in node.get("children", []):
		if c is Dictionary:
			n += _size(c)
	return n


## The artifacts' catalogue as a tree: one leaf each, newest first as listed, its card giving its type, its date,
## its size, its description and its headings.
func _from_artifacts(list: Array) -> Dictionary:
	var kids: Array = []
	for a: Variant in list:
		if not a is Dictionary:
			continue
		var item: Dictionary = a
		var meta := "%s · %s" % [str(item.get("type", "Page")), str(item.get("updated", ""))]
		if int(item.get("words", 0)) > 0:
			meta += " · %d %s" % [int(item.words), {"en": "words", "fr": "mots", "es": "palabras"}.get(_lang, "words")]
		var outline: Array = []
		for h: Variant in item.get("outline", []):
			if h is Dictionary:
				outline.append(("    " if int((h as Dictionary).get("level", 1)) > 2 else "") + "· " + str((h as Dictionary).get("text", "")))
		kids.append({"label": str(item.get("title", "")), "kind": "artifact", "note": str(item.get("updated", "")),
				"description": str(item.get("description", "")), "url": str(item.get("url", "")), "meta": meta,
				"outline": outline})
	return {"label": title, "kind": "root", "children": kids}


## The rows of a node: its children, a course's overview first, or an issue's own text before its sub-issues.
func _items(data: Dictionary) -> Array:
	var kids: Array = data.get("children", []) if data.get("children") is Array else []
	if kids.is_empty():
		return []
	var out: Array = []
	var kind := str(data.get("kind", ""))
	if (data.get("url") != null and kind == "course") or (kind == "issue" and str(data.get("text", "")) != ""):
		out.append({"label": UI.overview if kind == "course" else UI.about, "of": data.get("label"),
				"description": data.get("description", ""), "url": data.get("url"), "kind": "overview", "note": "›",
				"text": data.get("text", "")})
	out.append_array(kids)
	return out


# --- Opening and walking -------------------------------------------------------------------------

func open() -> void:
	if _is_open or _hidden:
		return
	get_tree().call_group("glass_terminals", "close_other", self)
	_leave_telescope()
	_find_shelves()
	_load()
	_is_open = true
	stats.open = true
	if _layers.is_empty():
		_path = [_root_data]
		var L := _make_layer(_root_data)
		L.node.position = Vector3(0.0, -0.25, 0.0)
		L.node.scale = Vector3.ONE * 0.4
		_layers.append(L)
		_restack()
		_rehit()
	_sound(1.2)


## Opens on the node `pick` accepts (course_library.gd: the course whose book was opened), each level from the root
## down to it stacked behind it, as if walked down to: its area, sub-area and department stay one click away. False,
## and nothing opened, when the tree has no such node.
func open_on(pick: Callable) -> bool:
	if _hidden:
		return false
	_load()
	var path := _find(_root_data, pick)
	if path.is_empty():
		return false
	for L: Layer in _layers:
		L.node.queue_free()
	_layers.clear()
	_path.clear()
	_is_open = false
	open()
	for i in range(1, path.size()):
		_down(path[i], Vector3(0.0, -0.1, 0.1), (_layers.back() as Layer).items.find(path[i]))
	return true


## The nodes from `node` down to the first one `pick` accepts, or [] when there is none under it.
func _find(node: Dictionary, pick: Callable) -> Array:
	if pick.call(node):
		return [node]
	for c: Variant in node.get("children", []):
		if c is Dictionary:
			var below := _find(c, pick)
			if not below.is_empty():
				below.push_front(node)
				return below
	return []


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	stats.open = false
	_sound(0.7)


func close_other(other: Node) -> void:
	if other != self:
		close()


## Out of the telescope before a terminal shows (the author, relayed by IX's session, 2026-10-18: « quand on affiche
## les cours, des fois on est en vue de télescope donc on devrait faire un reset du télescope complet »). The eyepiece
## (scripts/telescope.gd) goes off at its starting power; in the RTX build, rtx/rtx_zoom.gd's spyglass goes back to
## the naked eye. Each eases the view's zoom and the mouse's sensitivity back itself.
func _leave_telescope() -> void:
	var scope := get_tree().root.find_child("Telescope", true, false)
	if scope != null and scope.has_method("set_on"):
		var was := bool(scope.get("on"))
		scope.call("set_on", false)
		var s: Script = scope.get_script()
		if s != null and s.get_script_constant_map().has("START"):
			scope.set("power", s.get_script_constant_map().START)
		if was:
			stats.telescope_reset = int(stats.get("telescope_reset", 0)) + 1
	var zoom := get_tree().root.get_node_or_null("RtxZoom")
	if zoom != null:
		if float(zoom.get("power")) > 1.0:
			stats.telescope_reset = int(stats.get("telescope_reset", 0)) + 1
		zoom.set("power", 1.0)
		zoom.set("_scoped", false)


func _down(item: Dictionary, from: Vector3, index := -1) -> void:
	_path.append(item)
	var L := _make_layer(item)
	L.index = index
	L.node.position = from
	L.node.scale = Vector3.ONE * 0.3
	_layers.append(L)
	_restack()
	_rehit()
	_sound(1.0 + 0.06 * _path.size())


## Back to the level at index i of the path (0 the root); below 0, the terminal closes.
func _up_to(i: int) -> void:
	if i < 0:
		close()
		return
	while _layers.size() > i + 1:
		var L: Layer = _layers.pop_back()
		_path.pop_back()
		L.pos_to = Vector3(0.0, -0.1, 0.32)
		L.alpha_to = 0.0
		L.scale_to = 1.05
		_leaving.append(L)
	_restack()
	_rehit()
	_sound(0.85)


func _restack() -> void:
	var n := _layers.size()
	for k in n:
		var L: Layer = _layers[k]
		var d := n - 1 - k
		L.depth = d
		L.pos_to = STACK * float(d)
		L.scale_to = pow(0.95, d)
		L.alpha_to = float(STACK_ALPHA[mini(d, STACK_ALPHA.size() - 1)])
		L.body_to = 1.0 if d == 0 else 0.0
		# A level left behind shows its title on the strip that stays above the next card.
		L.title_at = Vector3(-0.44, PANEL.y * 0.5 - 0.045, 0.0) if d > 0 else Vector3(-0.44, 0.232, 0.0)
	stats.depth = n - 1


func _rehit() -> void:
	_hits.clear()
	var n := _layers.size()
	for k in n:
		var L: Layer = _layers[k]
		if L.depth == 0:
			_hits.append_array(L.hits)
		elif L.alpha_to > 0.0:
			_hits.append([L.plate, L.size, _up_to.bind(k), L.plate_mat])


func _rebuild() -> void:
	var path := _path.duplicate()
	var kept: Array = []
	for L: Layer in _layers:
		kept.append([L.scroll_to, L.index, L.scroll_m_to])
		L.node.queue_free()
	_layers.clear()
	_path.clear()
	for i in path.size():
		_path.append(path[i])
		var L := _make_layer(path[i])
		var k: Array = kept[i]
		L.scroll_to = float(k[0])
		L.scroll = L.scroll_to
		L.index = int(k[1])
		L.scroll_m_to = minf(float(k[2]), _scroll_max(L))
		L.scroll_m = L.scroll_m_to
		_layers.append(L)
	_restack()
	for L: Layer in _layers:
		L.node.position = L.pos_to
		L.node.scale = Vector3.ONE * L.scale_to
	_rehit()


func _choose(i: int) -> void:
	var L: Layer = _layers.back()
	if i < 0 or i >= L.items.size():
		return
	var row: Node3D = L.rows[i][0]
	_down(L.items[i], _stack.to_local(row.global_position), i)


## The wheel, or Page Up and Page Down (`page`): the drum turned a row a step, a page's text scrolled.
func _wheel(steps: float, page := false) -> void:
	var L: Layer = _layers.back()
	if L.reader:
		var by := steps * ((VIEW_TOP - VIEW_BOTTOM) * 0.9 if page else WHEEL_M)
		var m := clampf(L.scroll_m_to + by, 0.0, _scroll_max(L))
		if m != L.scroll_m_to:
			L.scroll_m_to = m
		return
	if L.card or L.items.is_empty():
		return
	var to := clampf(L.scroll_to + steps * (3.0 if page else 1.0), 0.0, float(L.items.size() - 1))
	if to != L.scroll_to:
		L.scroll_to = to
		_sound(1.5)


func _scroll_max(L: Layer) -> float:
	return maxf(0.0, L.content_h - (VIEW_TOP - VIEW_BOTTOM) + 0.02)


## The page before or after this one among its parent's items, in place of it, sliding in from that side.
func _sibling(dir: int) -> void:
	if _layers.size() < 2:
		return
	var parent: Layer = _layers[_layers.size() - 2]
	var L: Layer = _layers.back()
	var i := L.index + dir
	if L.index < 0 or i < 0 or i >= parent.items.size():
		return
	_layers.pop_back()
	_path.pop_back()
	L.pos_to = Vector3(-0.8 * dir, 0.0, 0.12)
	L.alpha_to = 0.0
	_leaving.append(L)
	parent.scroll_to = float(i)
	parent.scroll = parent.scroll_to
	_path.append(parent.items[i])
	var N := _make_layer(parent.items[i])
	N.index = i
	N.node.position = Vector3(0.8 * dir, 0.0, 0.12)
	_layers.append(N)
	_restack()
	_rehit()
	_sound(1.1 + 0.1 * dir)


## The code a page cites, as a level of its own: one row per permalink, in the order the page cites them.
func _cited() -> void:
	var L: Layer = _layers.back()
	if L.cites.is_empty():
		return
	var code: Dictionary = _gz("%s/%s.code.json.gz" % [text_dir, L.file])
	var known: Dictionary = code.get("cites", {}) if code.get("cites") is Dictionary else {}
	var kids: Array = []
	for k in L.cites.size():
		var cid := str(L.cites[k])
		var c: Dictionary = known.get(cid, {}) if known.get(cid) is Dictionary else {}
		if c.is_empty():
			continue
		kids.append({"label": str(c.get("label", cid)), "kind": "cite", "note": "[%d]" % (k + 1),
				"text": "%s|@cite/%s" % [L.file, cid]})
	if kids.is_empty():
		return
	_down({"label": UI.cited_title, "kind": "cites", "children": kids}, Vector3(0.0, -0.3, 0.05))


func _open_url(url: Variant) -> void:
	var u := _t(url)
	if u.begins_with("https://"):
		OS.shell_open(u)
		_sound(1.3)


# --- Building a level ----------------------------------------------------------------------------

func _make_layer(data: Dictionary) -> Layer:
	var L := Layer.new()
	L.data = data
	L.node = Node3D.new()
	_stack.add_child(L.node)
	L.plate_mat = _panel_mat(PANEL, 1.1)
	L.plate_mat.set_shader_parameter("band", BAND)
	L.plate = _quad(L.node, PANEL, L.plate_mat, Vector3(0.0, 0.0, BACK))
	L.title = _text(L.node, _fit(_t(data.get("label", "")), 46, 0.7), Vector3(-0.44 + 0.36, 0.232, 0.0), 46, HORIZONTAL_ALIGNMENT_LEFT, 0.72)
	L.title_at = L.title.position
	L.body = Node3D.new()
	L.body.name = "Body"
	L.node.add_child(L.body)
	# A click on the card between its rows does nothing, rather than reaching the cards behind it.
	L.hits.append([L.plate, PANEL, Callable(), null])
	L.items = _items(data)
	_chips(L)
	if L.items.is_empty() and str(data.get("kind", "")) != "root":
		if str(data.get("text", "")) != "":
			_build_reader(L)
		else:
			_build_card(L)
	else:
		_build_rows(L)
	return L


func _build_rows(L: Layer) -> void:
	var n := L.items.size()
	L.count = _text(L.body, "", Vector3(0.38, 0.232, 0.0), 26, HORIZONTAL_ALIGNMENT_RIGHT, 0.16)
	L.labels.append(L.count)
	if n == 0:
		L.labels.append(_text(L.body, _t(UI.missing), Vector3(0.0, DRUM_Y, 0.0), 32, HORIZONTAL_ALIGNMENT_CENTER, 0.9))
	# Opened on its first rows, which then fill the drum's upper half.
	L.scroll_to = minf(3.0, float(n - 1) * 0.5) if n > 0 else 0.0
	L.scroll = L.scroll_to
	for i in n:
		var item: Dictionary = L.items[i]
		var row := Node3D.new()
		row.name = "Row%d" % i
		L.body.add_child(row)
		var mat := _panel_mat(ROW, 0.4)
		mat.set_shader_parameter("frosted", 0.0)
		_quad(row, ROW, mat, Vector3.ZERO)
		var left := _text(row, _fit(_t(item.get("label", "")), 34, 0.7), Vector3(-0.09, 0.0, 0.002), 34,
				HORIZONTAL_ALIGNMENT_LEFT, 0.72)
		var note := _t(item.get("note", ""))
		if note == "" and item.get("children") is Array and not (item.children as Array).is_empty():
			note = "%d ›" % (item.children as Array).size()
		var right := _text(row, _fit(note, 24, 0.17), Vector3(0.355, 0.0, 0.002), 24, HORIZONTAL_ALIGNMENT_RIGHT, 0.18)
		L.rows.append([row, mat, left, right])
		# The pitch, not the plate: a click between two rows takes the nearer one.
		L.hits.append([row, Vector2(ROW.x, ROW_PITCH), _choose.bind(i), mat])
	var hint := _text(L.body, _t(UI.hint), Vector3(0.0, -PANEL.y * 0.5 + 0.026, 0.0), 20, HORIZONTAL_ALIGNMENT_CENTER, 0.9)
	L.labels.append(hint)


## A leaf: its title in full, a line about it, its description, its headings for an artifact, and its link.
func _build_card(L: Layer) -> void:
	L.card = true
	var d := L.data
	L.title.visible = false
	var name_s := _t(d.get("of")) if str(d.get("kind", "")) == "overview" else _t(d.get("label", ""))
	var y := 0.262
	var w := 0.9
	var x := -0.45 + w * 0.5
	var head := _text(L.body, name_s, Vector3(x, y, 0.0), 40, HORIZONTAL_ALIGNMENT_LEFT, w, true)
	L.labels.append(head)
	y -= _block(name_s, 40, w) + 0.022
	var meta := _t(d.get("meta")) if d.has("meta") else _t(d.get("url", "")).trim_prefix("https://")
	if meta != "":
		var m := _text(L.body, meta, Vector3(x, y, 0.0), 22, HORIZONTAL_ALIGNMENT_LEFT, w, true)
		m.modulate = Color(tint.lightened(0.2), 1.0)
		L.labels.append(m)
		y -= _block(meta, 22, w) + 0.026
	var floor_y := -0.2
	var outline: Array = d.get("outline", []) if d.get("outline") is Array else []
	var desc := _t(d.get("description", ""))
	if desc != "":
		var room := (y - floor_y) * (0.55 if not outline.is_empty() else 1.0)
		desc = _cut(desc, 28, w, room)
		L.labels.append(_text(L.body, desc, Vector3(x, y, 0.0), 28, HORIZONTAL_ALIGNMENT_LEFT, w, true))
		y -= _block(desc, 28, w) + 0.022
	if not outline.is_empty():
		var lines := "\n".join(outline)
		lines = _cut(lines, 22, w, y - floor_y)
		L.labels.append(_text(L.body, lines, Vector3(x, y, 0.0), 22, HORIZONTAL_ALIGNMENT_LEFT, w, true))
	var bottom := -PANEL.y * 0.5 + 0.06
	if _t(d.get("url", "")) != "":
		_button(L, _t(UI.open), Vector3(-0.2, bottom, 0.0), 0.42, _open_url.bind(d.get("url")))
	_button(L, _t(UI.back), Vector3(0.27, bottom, 0.0), 0.26, _up_to.bind(_path.size() - 2))


## A page to read in the scene (the author: « pouvoir lire le cours (pas besoin de "ouvrir la page") »): its text
## laid out in lines on a taller card, scrolled by the wheel (« je veux pouvoir scroller dans les panneaux 3d »), with
## a bar to show where; under it, back, the pages before and after it, and the code it cites.
func _build_reader(L: Layer) -> void:
	L.reader = true
	L.size = READER
	var page := _load_text(str(L.data.get("text", "")))
	L.file = str(page.get("file", ""))
	L.cites = page.get("cites", []) if page.get("cites") is Array else []
	(L.plate.mesh as QuadMesh).size = READER
	L.plate.position = Vector3(0.0, READER_Y, BACK)
	L.plate_mat.set_shader_parameter("size", READER)
	L.plate_mat.set_shader_parameter("fill", 1.1)
	L.hits[0] = [L.plate, READER, Callable(), null]
	var blocks: Array = page.get("blocks", []) if page.get("blocks") is Array else []
	if blocks.is_empty():
		blocks = [["p", _t(UI.no_text)]]
	if str(L.data.get("kind", "")) == "overview":
		blocks.insert(0, ["h1", _t(L.data.get("of"))])
	_layout(L, blocks)
	# The bar: its track the view's height, its thumb the view's share of the text.
	var track_mat := StandardMaterial3D.new()
	track_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	track_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	track_mat.albedo_color = Color(tint, 0.18)
	var bar_x := TEXT_X + TEXT_W + 0.045
	var track := _quad(L.body, Vector2(0.006, VIEW_TOP - VIEW_BOTTOM), track_mat, Vector3(bar_x, (VIEW_TOP + VIEW_BOTTOM) * 0.5, 0.0))
	track.visible = _scroll_max(L) > 0.0
	L.thumb_mat = StandardMaterial3D.new()
	L.thumb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	L.thumb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	L.thumb_mat.albedo_color = Color(tint.lightened(0.4), 0.8)
	L.thumb = _quad(L.body, Vector2(0.012, 1.0), L.thumb_mat, Vector3(bar_x, VIEW_TOP, 0.001))
	L.thumb.visible = track.visible
	var bottom := READER_Y - READER.y * 0.5 + 0.042
	_button(L, _t(UI.back), Vector3(-0.38, bottom, 0.0), 0.2, _up_to.bind(_path.size() - 2))
	var parent: Layer = _layers.back() if not _layers.is_empty() else null
	var siblings: int = parent.items.size() if parent != null else 0
	if siblings > 1:
		_button(L, _t(UI.prev), Vector3(-0.14, bottom, 0.0), 0.24, _sibling.bind(-1))
		_button(L, _t(UI.next), Vector3(0.38, bottom, 0.0), 0.2, _sibling.bind(1))
	if not L.cites.is_empty():
		_button(L, _t(UI.cited) % L.cites.size(), Vector3(0.13, bottom, 0.0), 0.26, _cited)


## The blocks as lines of text, each with its place from the text's top: [top, height, text, px, mono, x, kind,
## plate]; a code block's lines numbered when it has a first line, the cited ones on a brighter plate.
func _layout(L: Layer, blocks: Array) -> void:
	var y := 0.0
	var lines: Array = []
	var sans: Font = ThemeDB.fallback_font
	for b: Variant in blocks:
		if not b is Array or (b as Array).size() < 2:
			continue
		var blk: Array = b
		var kind := str(blk[0])
		var st: Array = STYLE.get(kind, STYLE.p)
		var px := int(st[0])
		var mono := kind == "code" or kind == "table"
		var font: Font = _mono_font() if mono else sans
		var h := font.get_height(px) * PIXEL * (1.0 if mono else 1.08)
		y += float(st[1]) if not lines.is_empty() else 0.0
		var text := str(blk[1]).replace("\t", "    ")
		var x0 := 0.0
		var x1 := 0.0
		if kind == "li":
			var lead := text.length() - text.lstrip(" ").length()
			x0 = 0.012 + 0.03 * float(lead / 4)
			text = text.strip_edges()
			x1 = x0 + sans.get_string_size(text.get_slice(" ", 0) + " ", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * PIXEL
		elif kind == "quote" or kind == "diagram":
			x0 = 0.025
			x1 = x0
		elif mono:
			x0 = 0.014
			x1 = x0 + 0.02
		if kind == "diagram":
			lines.append([y, h * 0.9, _t(UI.diagram), 20, false, x0, "meta", 0])
			y += h * 0.9
		if kind == "code" and blk.size() > 3 and str(blk[3]) != "":
			var th := _mono_font().get_height(18) * PIXEL
			lines.append([y, th, str(blk[3]), 18, true, x0, "meta", 1])
			y += th
		var first := int(blk[4]) if kind == "code" and blk.size() > 4 else 0
		var focus: Array = blk[5] if kind == "code" and blk.size() > 5 and blk[5] is Array else [0, 0]
		var src: PackedStringArray = text.split("\n") if mono or kind == "diagram" else PackedStringArray([text])
		var digits := str(first + src.size()).length() if first > 0 else 0
		for k in src.size():
			var s := src[k]
			var n := first + k
			if first > 0:
				s = str(n).lpad(digits) + "  " + s
			var plate := 0
			if mono:
				plate = 2 if first > 0 and n >= int(focus[0]) and n <= int(focus[1]) and int(focus[0]) > 0 else 1
			var parts := _wrap(s, font, px, (TEXT_W - x1) / PIXEL, mono)
			for j in parts.size():
				lines.append([y, h, parts[j], px, mono, x0 if j == 0 else x1, kind, plate])
				y += h
		y += float(st[2])
	L.lines = lines
	L.content_h = y


## A line of text cut where it would pass `width_px`, at words (a code line anywhere, when it must).
func _wrap(s: String, font: Font, px: int, width_px: float, keep_spaces: bool) -> PackedStringArray:
	var out := PackedStringArray()
	if s.strip_edges() == "" or font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= width_px:
		out.append(s if keep_spaces else s.strip_edges())
		return out
	var p := TextParagraph.new()
	p.add_string(s, font, px)
	p.width = width_px
	p.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	for i in p.get_line_count():
		var r := p.get_line_range(i)
		var part := s.substr(r.x, r.y - r.x)
		out.append(part.rstrip(" ") if keep_spaces else part.strip_edges())
	return out


## The lines on view: each one given a label from the pool, faded at the view's top and foot.
func _reader_frame(L: Layer, b: float, delta: float) -> void:
	L.scroll_m = lerpf(L.scroll_m, L.scroll_m_to, 1.0 - exp(-delta * 12.0))
	var view := VIEW_TOP - VIEW_BOTTOM
	var used := 0
	var used_p := 0
	var i := _first_line(L, L.scroll_m - 0.06)
	while i < L.lines.size():
		var ln: Array = L.lines[i]
		var from_top := float(ln[0]) - L.scroll_m
		if from_top > view + 0.01:
			break
		var hgt := float(ln[1])
		var cy := VIEW_TOP - from_top - hgt * 0.5
		var fade := smoothstep(VIEW_BOTTOM, VIEW_BOTTOM + 0.025, cy) * (1.0 - smoothstep(VIEW_TOP - 0.025, VIEW_TOP, cy))
		if fade > 0.0:
			var l := _pool_label(L, used)
			if int(L.pool_line[used]) != i:
				L.pool_line[used] = i
				l.text = str(ln[2])
				l.font_size = int(ln[3])
				l.font = _mono_font() if bool(ln[4]) else null
			l.position = Vector3(TEXT_X + float(ln[5]), cy, 0.0)
			l.modulate = Color(_ink(str(ln[6])), b * fade)
			l.visible = true
			used += 1
			if int(ln[7]) > 0:
				var q: Array = _pool_plate(L, used_p)
				var qm: MeshInstance3D = q[0]
				qm.position = Vector3(TEXT_X + TEXT_W * 0.5, cy, -0.002)
				qm.scale = Vector3(1.0, hgt, 1.0)
				(q[1] as StandardMaterial3D).albedo_color = Color(tint.darkened(0.55), 0.55 * b * fade) if int(ln[7]) == 1 \
						else Color(tint.darkened(0.15), 0.6 * b * fade)
				qm.visible = true
				used_p += 1
		i += 1
	for k in range(used, L.pool.size()):
		(L.pool[k] as Label3D).visible = false
	for k in range(used_p, L.plates.size()):
		(L.plates[k][0] as MeshInstance3D).visible = false
	if L.thumb != null and L.thumb.visible:
		var share := clampf(view / maxf(L.content_h, view), 0.06, 1.0)
		var t := L.scroll_m / maxf(_scroll_max(L), 0.001)
		var th := view * share
		L.thumb.scale = Vector3(1.0, th, 1.0)
		L.thumb.position.y = VIEW_TOP - th * 0.5 - (view - th) * t
		L.thumb_mat.albedo_color.a = 0.8 * b


func _first_line(L: Layer, y: float) -> int:
	var lo := 0
	var hi := L.lines.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		if float(L.lines[mid][0]) + float(L.lines[mid][1]) < y:
			lo = mid + 1
		else:
			hi = mid
	return lo


func _ink(kind: String) -> Color:
	match kind:
		"h1", "h2":
			return tint.lightened(0.78)
		"h3", "tab":
			return tint.lightened(0.5)
		"code", "table":
			return Color(0.86, 0.93, 1.0).lerp(tint, 0.15)
		"meta", "diagram", "quote":
			return tint.lightened(0.3)
	return Color(0.9, 0.94, 1.0).lerp(tint.lightened(0.6), 0.3)


func _pool_label(L: Layer, k: int) -> Label3D:
	while L.pool.size() <= k:
		var l := _text(L.body, "", Vector3.ZERO, 25, HORIZONTAL_ALIGNMENT_LEFT, TEXT_W)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.outline_size = 3
		L.pool.append(l)
		L.pool_line.append(-1)
	return L.pool[k]


func _pool_plate(L: Layer, k: int) -> Array:
	while L.plates.size() <= k:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.render_priority = 0
		var q := _quad(L.body, Vector2(TEXT_W + 0.016, 1.0), m, Vector3.ZERO)
		L.plates.append([q, m])
	return L.plates[k]


## A page's text: its blocks and the code it cites ("<file>|<slug>"), a cited excerpt ("<file>|@cite/<id>") or one of
## the course's code files ("<file>|@code/<path>"), from assets/course_text (artpass/pedestals/course_tree.py), in
## the reader's language, else in English.
func _load_text(ref: String) -> Dictionary:
	var bar := ref.find("|")
	if bar < 0:
		return {}
	var file := ref.substr(0, bar)
	var slug := ref.substr(bar + 1)
	if slug.begins_with("@"):
		var code := _gz("%s/%s.code.json.gz" % [text_dir, file])
		if slug.begins_with("@cite/"):
			var cites: Dictionary = code.get("cites", {}) if code.get("cites") is Dictionary else {}
			var c: Dictionary = cites.get(slug.trim_prefix("@cite/"), {}) if cites.get(slug.trim_prefix("@cite/")) is Dictionary else {}
			if c.is_empty():
				return {}
			return {"file": file, "blocks": [["meta", "%s · %s" % [str(c.get("sha", "")), str(c.get("url", "")).trim_prefix("https://")]],
					["code", str(c.get("text", "")), str(c.get("lang", "")), "", int(c.get("start", 1)), c.get("focus", [0, 0])]]}
		var files: Dictionary = code.get("files", {}) if code.get("files") is Dictionary else {}
		var f: Dictionary = files.get(slug.trim_prefix("@code/"), {}) if files.get(slug.trim_prefix("@code/")) is Dictionary else {}
		if f.is_empty():
			return {}
		var shown := "code/%s/%s" % [file, slug.trim_prefix("@code/")]
		if int(f.get("lines", 0)) > str(f.get("text", "")).count("\n") + 1:
			shown += " · %d / %d" % [str(f.get("text", "")).count("\n") + 1, int(f.get("lines", 0))]
		return {"file": file, "blocks": [["meta", shown], ["code", str(f.get("text", "")), str(f.get("lang", "")), "", 1, [0, 0]]]}
	for lang: String in [_lang, "en"]:
		var doc := _gz("%s/%s.%s.json.gz" % [text_dir, file, lang])
		var pages: Dictionary = doc.get("pages", {}) if doc.get("pages") is Dictionary else {}
		if pages.get(slug) is Dictionary:
			var pg: Dictionary = (pages[slug] as Dictionary).duplicate()
			pg.file = file
			return pg
	return {}


func _gz(path: String) -> Dictionary:
	if _text_cache.has(path):
		return _text_cache[path]
	var out: Dictionary = {}
	if FileAccess.file_exists(path):
		var raw := FileAccess.get_file_as_bytes(path).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		var v: Variant = JSON.parse_string(raw.get_string_from_utf8())
		if v is Dictionary:
			out = v
	if _text_cache.size() > 6:
		_text_cache.clear()
	_text_cache[path] = out
	return out


func _mono_font() -> Font:
	if _mono == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "DejaVu Sans Mono", "Menlo", "Courier New", "monospace"])
		_mono = f
	return _mono


## The path as chips over the card: each one a way back to its level; the close cross at the right.
func _chips(L: Layer) -> void:
	var names: Array = []
	for p: Variant in _path:
		names.append(_t((p as Dictionary).get("label", "")) if p is Dictionary else "")
	var f := ThemeDB.fallback_font
	var px := 22
	var avail := PANEL.x - 0.2
	var shown: Array = []  # [text, path index or -1]
	for i in names.size():
		shown.append([_fit(str(names[i]), px, 0.24), i])
	var sep_w := f.get_string_size(" › ", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * PIXEL
	# Too long for a line: smaller, on two; past two lines, the middle ones give way to an ellipsis.
	var two := _chips_w(shown, px, sep_w) > avail
	if two:
		px = 19
		sep_w = f.get_string_size(" › ", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * PIXEL
		shown.clear()
		for i in names.size():
			shown.append([_fit(str(names[i]), px, 0.22), i])
		while shown.size() > 3 and _chips_w(shown, px, sep_w) > avail * 1.9:
			shown.remove_at(1 if str(shown[1][0]) != "…" else 2)
			if str(shown[1][0]) != "…":
				shown.insert(1, ["…", -1])
	var x0 := -PANEL.x * 0.5 + 0.055
	var x := x0
	var y := PANEL.y * 0.5 - (0.03 if two else 0.045)
	for k in shown.size():
		var s := str(shown[k][0])
		var idx := int(shown[k][1])
		var cw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * PIXEL
		if two and x > x0 and x + cw > x0 + avail:
			x = x0
			y -= 0.03
		var chip := _text(L.body, s, Vector3(x + cw * 0.5, y, 0.0), px, HORIZONTAL_ALIGNMENT_CENTER, cw + 0.004)
		L.labels.append(chip)
		var last := k == shown.size() - 1
		chip.modulate = Color(tint.lightened(0.6 if last else 0.15), 1.0)
		if idx >= 0 and not last:
			L.hits.append([chip, Vector2(cw + 0.02, 0.045), _up_to.bind(idx), null])
		x += cw
		if not last:
			var sep := _text(L.body, "›", Vector3(x + sep_w * 0.5, y, 0.0), px, HORIZONTAL_ALIGNMENT_CENTER, sep_w)
			sep.modulate = Color(tint, 1.0)
			L.labels.append(sep)
			x += sep_w
	var cross := _text(L.body, "×", Vector3(PANEL.x * 0.5 - 0.05, PANEL.y * 0.5 - 0.045, 0.0), 34, HORIZONTAL_ALIGNMENT_CENTER, 0.04)
	L.labels.append(cross)
	L.hits.append([cross, Vector2(0.06, 0.06), close, null])


func _chips_w(shown: Array, px: int, sep_w: float) -> float:
	var f := ThemeDB.fallback_font
	var w := 0.0
	for c: Array in shown:
		w += f.get_string_size(str(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * PIXEL + sep_w
	return w


func _button(L: Layer, s: String, at: Vector3, w: float, action: Callable) -> void:
	var n := Node3D.new()
	n.position = at
	L.body.add_child(n)
	var size := Vector2(w, 0.066)
	var mat := _panel_mat(size, 0.75)
	mat.set_shader_parameter("radius", 0.03)
	mat.set_shader_parameter("frosted", 0.0)
	_quad(n, size, mat, Vector3.ZERO)
	L.mats.append(mat)
	L.labels.append(_text(n, s, Vector3(0.0, 0.0, 0.002), 28, HORIZONTAL_ALIGNMENT_CENTER, w))
	L.hits.append([n, size, action, mat])


# --- Each frame ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var cast_public: Variant = get_tree().get("_cast_public")
	_hidden = private and cast_public is bool and bool(cast_public)
	var near := global_position.distance_to(cam.global_position)
	if _is_open and (_hidden or near > CLOSE_AT):
		close()
	_look_for_shelves -= delta
	if _shelves == null and _look_for_shelves <= 0.0:
		_look_for_shelves = 2.0
		_find_shelves()
		_name_tag()
	_tag_a = move_toward(_tag_a, 0.0 if (_hidden or _is_open or near > TAG_AT) else 1.0, delta * 2.5)
	# Closed and aimed at, the piece lights up, as everything clickable does.
	var aimed := not _is_open and not _hidden and near <= REACH and _hits_piece(_aim_point(get_viewport().get_mouse_position()))
	var glow := move_toward(_glow, 1.0 if aimed else 0.0, delta * 5.0)
	if glow != _glow:
		_glow = glow
		AIM_GLOW.light(piece, _glow)
	_tag.visible = _tag_a > 0.0
	_tag_sub.visible = _tag.visible
	_tag.modulate = Color(tint.lightened(0.55), _tag_a)
	_tag_sub.modulate = Color(tint.lightened(0.3), _tag_a * 0.8)
	_open_t = move_toward(_open_t, 1.0 if _is_open else 0.0, delta / 0.45)
	_holo.visible = _open_t > 0.0
	if not _holo.visible:
		return
	var e := ease(_open_t, -2.2)
	_holo.scale = Vector3.ONE * lerpf(0.04, 1.0, e)
	_fan_mat.set_shader_parameter("alpha", e)
	# Turned to the viewer round the pedestal's axis.
	var to_cam := to_local(cam.global_position)
	var yaw := clampf(atan2(to_cam.x, to_cam.z), -1.25, 1.25)
	_holo.rotation.y = lerp_angle(_holo.rotation.y, yaw, 1.0 - exp(-delta * 4.0))
	var k := 1.0 - exp(-delta * 9.0)
	for L: Layer in _layers:
		_layer_frame(L, k, e, delta)
	for L: Layer in _leaving.duplicate():
		_layer_frame(L, k, e, delta)
		if L.alpha < 0.02:
			_leaving.erase(L)
			L.node.queue_free()
	_hover_frame()
	_voice_t -= delta
	if _is_open and _voice_path != "" and _voice_t <= 0.0:
		_voice_t = VOICE_EVERY
		_voice_frame()


## The last utterance's time, 0 when there is none to read.
func _voice_stamp() -> float:
	if not FileAccess.file_exists(_voice_path):
		return 0.0
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(_voice_path))
	return float((v as Dictionary).get("t", 0)) if v is Dictionary else 0.0


func _voice_frame() -> void:
	var t := _voice_stamp()
	if t <= _voice_seen:
		return
	_voice_seen = t
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(_voice_path))
	if v is Dictionary:
		voice_command(str((v as Dictionary).get("text", "")))


## A short utterance as a command for the open terminal: true when it was one.
func voice_command(text: String) -> bool:
	var said := text.to_lower()
	for mark: String in [",", ".", "!", "?", ";", ":", "«", "»", "\""]:
		said = said.replace(mark, " ")
	said = " " + " ".join(said.split(" ", false)) + " "
	if not _is_open or said.strip_edges() == "" or said.strip_edges().split(" ", false).size() > VOICE_WORDS:
		return false
	for command: String in VOICE:
		for phrase: String in VOICE[command]:
			if not said.contains(" " + phrase + " "):
				continue
			stats.voice = command
			var L: Layer = _layers.back()
			match command:
				"back":
					back()
				"close":
					close()
				"next":
					if L.reader:
						_sibling(1)
					else:
						_wheel(1.0)
				"prev":
					if L.reader:
						_sibling(-1)
					else:
						_wheel(-1.0)
				"down":
					_wheel(1.0, true)
				"up":
					_wheel(-1.0, true)
			return true
	return false


func _layer_frame(L: Layer, k: float, open_e: float, delta: float) -> void:
	L.node.position = L.node.position.lerp(L.pos_to, k)
	L.node.scale = Vector3.ONE * lerpf(L.node.scale.x, L.scale_to, k)
	L.alpha = lerpf(L.alpha, L.alpha_to, k)
	L.body_alpha = move_toward(L.body_alpha, L.body_to, delta * 5.0)
	L.title.position = L.title.position.lerp(L.title_at, k)
	var a := L.alpha * open_e
	L.node.visible = a > 0.01
	if not L.node.visible:
		return
	L.plate_mat.set_shader_parameter("alpha", a)
	L.title.modulate = Color(tint.lightened(0.62), a)
	L.plate.set_meta("a", a)
	L.body.visible = L.body_alpha > 0.01
	if not L.body.visible:
		return
	var b := a * L.body_alpha
	for m: ShaderMaterial in L.mats:
		m.set_shader_parameter("alpha", b)
	for l: Label3D in L.labels:
		l.modulate.a = b
	for n: Node3D in L.body.get_children():
		n.set_meta("a", b)
	if L.reader:
		_reader_frame(L, b, delta)
		return
	if L.rows.is_empty():
		return
	L.scroll = lerpf(L.scroll, L.scroll_to, 1.0 - exp(-delta * 10.0))
	for i in L.rows.size():
		var r: Array = L.rows[i]
		var row: Node3D = r[0]
		var ang := (float(i) - L.scroll) * STEP_A
		var fade := 1.0 - smoothstep(2.2 * STEP_A, 3.2 * STEP_A, absf(ang))
		row.visible = fade > 0.01
		if not row.visible:
			continue
		row.position = Vector3(0.0, DRUM_Y - DRUM_R * sin(ang), DRUM_R * (cos(ang) - 1.0))
		row.rotation.x = ang
		var ra := b * fade
		row.set_meta("a", ra)
		(r[1] as ShaderMaterial).set_shader_parameter("alpha", ra)
		(r[2] as Label3D).modulate = Color(tint.lightened(0.7), ra)
		(r[3] as Label3D).modulate = Color(tint.lightened(0.25), ra * 0.9)
	if L.count != null:
		L.count.text = "%d / %d" % [roundi(L.scroll_to) + 1, L.rows.size()]


func _hover_frame() -> void:
	var hit := _pick(_aim_point(get_viewport().get_mouse_position())) if _is_open else []
	var mat: ShaderMaterial = hit[3] if hit.size() > 3 and hit[3] is ShaderMaterial else null
	if mat != _hovered:
		if _hovered != null:
			_hovered.set_shader_parameter("hover", 0.0)
		_hovered = mat
		if _hovered != null:
			_hovered.set_shader_parameter("hover", 1.0)


# --- Input ---------------------------------------------------------------------------------------

## The node that hands the terminals their input first. A node's _input comes in the tree's reverse order: under the
## hall, a terminal heard the wheel after the RTX build's spyglass (rtx/rtx_zoom.gd), which took it (the author,
## 2026-10-18: « le scroller ne marche pas pour les cours, le télescope prend la précédence »). This one keeps itself
## the root's last child.
const FRONT_NAME := "GlassTerminalInput"
const FRONT_SOURCE := """extends Node
func _input(event: InputEvent) -> void:
	for t: Node in get_tree().get_nodes_in_group("glass_terminals"):
		if t.has_method("front_input") and bool(t.call("front_input", event)):
			get_viewport().set_input_as_handled()
			return
func _process(_delta: float) -> void:
	var p := get_parent()
	if p != null and p.get_child(p.get_child_count() - 1) != self:
		p.move_child.call_deferred(self, -1)
"""


func _front() -> void:
	var root := get_tree().root
	if root.has_node(FRONT_NAME):
		return
	var script := GDScript.new()
	script.source_code = FRONT_SOURCE
	if script.reload() != OK:
		return
	var n := Node.new()
	n.name = FRONT_NAME
	n.set_script(script)
	root.add_child.call_deferred(n)


## An event for this terminal: true when it took it.
func front_input(event: InputEvent) -> bool:
	if not is_visible_in_tree() or _hidden:
		return false
	var mb := event as InputEventMouseButton
	if mb != null:
		if not mb.pressed:
			return false
		var at := _aim_point(mb.position)
		if mb.button_index == MOUSE_BUTTON_LEFT:
			return _click(at)
		if _is_open and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if _pick(at).is_empty():
				return false
			var notch := mb.factor if mb.factor > 0.0 else 1.0
			_wheel((-1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0) * notch)
			return true
		if _is_open and mb.button_index == MOUSE_BUTTON_XBUTTON1:
			back()
			return true
		return false
	var key := event as InputEventKey
	if key == null or not key.pressed or not _is_open:
		return false
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	# Escape too (the author, 2026-10-18: « on devrait pouvoir revenir au panneau parent avec la touche escape »): while
	# a terminal is open, it is the terminal's, not the camera's release of the mouse; at the root it closes it.
	if (code == KEY_BACKSPACE or code == KEY_ESCAPE) and not key.echo:
		back()
		return true
	if code == KEY_PAGEUP or code == KEY_PAGEDOWN:
		_wheel(-1.0 if code == KEY_PAGEUP else 1.0, true)
		return true
	if (code == KEY_HOME or code == KEY_END) and not key.echo:
		_wheel(-1e6 if code == KEY_HOME else 1e6)
		return true
	return false


## One level up (Backspace, the mouse's back button, a voice's « retour »); at the root, the terminal closes.
func back() -> void:
	if _is_open:
		_up_to(_path.size() - 2)


## A tap from touch_controls.gd, as a click: true when it was taken.
func tap(pos: Vector2) -> bool:
	return not _hidden and _click(pos)


func _click(at: Vector2) -> bool:
	if not _is_open:
		if _hits_piece(at):
			open()
			return true
		return false
	var hit := _pick(at)
	if not hit.is_empty():
		var action: Callable = hit[2]
		if action.is_valid():
			action.call()
		return true
	if _hits_piece(at):
		close()
		return true
	# Anywhere else, it closes as « ferme » does (the author, relayed by IX's session, 2026-10-18), and the click goes
	# on to the scene: the camera's look, another terminal's piece.
	close()
	return false


func _aim_point(mouse: Vector2) -> Vector2:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return get_viewport().get_visible_rect().size * 0.5
	return mouse


## The glass piece on the cap, or the name over it.
func _hits_piece(at: Vector2) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var c := to_global(Vector3(0.0, top + apex * 0.6, 0.0))
	var o := cam.project_ray_origin(at)
	var d := cam.project_ray_normal(at)
	var t := (c - o).dot(d)
	if t < 0.0 or t > REACH:
		return false
	return (o + d * t).distance_to(c) < maxf(0.3, t * 0.03)


## The nearest of the hits that the ray through a screen point crosses: [node, size, action, plate].
func _pick(at: Vector2) -> Array:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return []
	var o := cam.project_ray_origin(at)
	var d := cam.project_ray_normal(at)
	var best: Array = []
	var best_t := REACH
	for h: Array in _hits:
		var n: Node3D = h[0]
		if not is_instance_valid(n) or not n.is_visible_in_tree() or float(n.get_meta("a", 1.0)) < 0.2:
			continue
		var g := n.global_transform
		var normal := g.basis.z.normalized()
		var den := d.dot(normal)
		if absf(den) < 1e-4:
			continue
		var t := (g.origin - o).dot(normal) / den
		if t <= 0.0 or t >= best_t:
			continue
		var p := g.affine_inverse() * (o + d * t)
		var size: Vector2 = h[1]
		if absf(p.x) <= size.x * 0.5 and absf(p.y) <= size.y * 0.5:
			best = h
			best_t = t
	return best


# --- Pieces --------------------------------------------------------------------------------------

func _shader(code: String) -> Shader:
	if not _shaders.has(code):
		var s := Shader.new()
		s.code = code
		_shaders[code] = s
	return _shaders[code]


func _panel_mat(size: Vector2, fill: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(PANEL_SHADER)
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	m.set_shader_parameter("size", size)
	m.set_shader_parameter("fill", fill)
	m.set_shader_parameter("alpha", 0.0)
	m.render_priority = -1
	return m


func _quad(parent: Node3D, size: Vector2, mat: Material, at: Vector3) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## The light from the piece to the card's foot.
func _make_fan() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foot := LIFT - PANEL.y * 0.5
	var pts := [Vector3(0.0, 0.0, BACK * 0.5), Vector3(-PANEL.x * 0.5, foot, BACK), Vector3(PANEL.x * 0.5, foot, BACK)]
	var uvs := [Vector2(0.5, 1.0), Vector2(0.0, 0.0), Vector2(1.0, 0.0)]
	for i in 3:
		st.set_uv(uvs[i])
		st.add_vertex(pts[i])
	_fan_mat = ShaderMaterial.new()
	_fan_mat.shader = _shader(FAN_SHADER)
	_fan_mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	var mi := MeshInstance3D.new()
	mi.name = "Fan"
	mi.mesh = st.commit()
	mi.material_override = _fan_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Words on the card, in a box `width` wide centred on `at` (its top on `at` when `top_aligned`).
func _text(parent: Node3D, s: String, at: Vector3, px: int, align: HorizontalAlignment, width: float,
		top_aligned := false) -> Label3D:
	var l := Label3D.new()
	l.text = s
	# Label3D starts a left-aligned line at its origin and ends a right-aligned one there; the box is centred on `at`.
	l.position = at + Vector3(-width * 0.5 if align == HORIZONTAL_ALIGNMENT_LEFT else (width * 0.5 if align == HORIZONTAL_ALIGNMENT_RIGHT else 0.0), 0.0, 0.0)
	l.pixel_size = PIXEL
	l.font_size = px
	l.outline_size = 5
	l.outline_modulate = Color(0.0, 0.02, 0.06, 0.65)
	l.width = width / PIXEL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP if top_aligned else VERTICAL_ALIGNMENT_CENTER
	l.shaded = false
	l.double_sided = true
	l.render_priority = 2
	l.outline_render_priority = 1
	l.modulate = Color(tint.lightened(0.6), 0.0)
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(l)
	return l


## A line cut to `width` metres, with an ellipsis.
func _fit(s: String, px: int, width: float) -> String:
	var f := ThemeDB.fallback_font
	if f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * PIXEL <= width:
		return s
	var lo := 0
	var hi := s.length()
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if f.get_string_size(s.substr(0, mid) + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x * PIXEL <= width:
			lo = mid
		else:
			hi = mid - 1
	return s.substr(0, lo).strip_edges() + "…"


## The height of words wrapped to `width` metres.
func _block(s: String, px: int, width: float) -> float:
	var f := ThemeDB.fallback_font
	return f.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, width / PIXEL, px).y * PIXEL


## Words cut at a word so that, wrapped, they stand no taller than `height` metres.
func _cut(s: String, px: int, width: float, height: float) -> String:
	if _block(s, px, width) <= height:
		return s
	var words := s.split(" ")
	var lo := 0
	var hi := words.size()
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if _block(" ".join(words.slice(0, mid)) + " …", px, width) <= height:
			lo = mid
		else:
			hi = mid - 1
	return " ".join(words.slice(0, lo)) + " …"


func _sound(pitch: float) -> void:
	if _tick == null:
		var rate := 22050
		var n := int(rate * 0.14)
		var data := PackedByteArray()
		data.resize(n * 2)
		for i in n:
			var t := float(i) / rate
			var s := (sin(TAU * 1568.0 * t) + 0.3 * sin(TAU * 3136.0 * t) * exp(-t * 40.0)) * exp(-t * 30.0) * 0.3
			data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32000.0))
		_tick = AudioStreamWAV.new()
		_tick.format = AudioStreamWAV.FORMAT_16_BITS
		_tick.mix_rate = rate
		_tick.data = data
	_player.stream = _tick
	_player.pitch_scale = pitch
	_player.play()
