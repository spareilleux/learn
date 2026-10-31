@tool
extends Node3D
## Course shelves: every course of the site is a book on the ground-floor shelves, all at once, one bay
## per area of the site's sidebar. A series starts on the row at eye height and fills the rows under
## it, then those over the sign (either side of the banner); a series longer than its bay runs on to
## the free course bays (_plan). Each area is a series bound in its own cloth,
## standing between two brass bookends, with the area's name on a card in a brass holder on the
## shelf edge. The rest of that row, and the same row in the other bays, holds ordinary books. The
## spines carry the real titles; the other books' lettering is decorative.
## So that a course bay reads as one from across the hall, a sign over its ground-level shelves
## names the area in gilt on black lacquer, with its number of courses, and its course row is lit
## like a display: bare shelf either side of the series, a lining in the area's cloth behind it and
## a brass lamp over it.
## The books share observatory.gd's hardback mesh, bindings shader and board filler, and each bay's
## row is one MultiMesh, so the course row costs about what any other row does.
## The catalogue is assets/courses.json, a copy of the site's demos/observatory/courses.json
## (src/pages/demos/observatory/courses.json.ts in the learn repository). The web build fetches the
## site's own copy at start-up, so a new course reaches the shelves without a re-export.
## Aim at a spine (with the crosshair while the mouse is captured, with the pointer otherwise): the
## book slides out and a card shows the course; a click or Enter opens it in a new tab. L opens a
## catalogue of every course. Leaning the way the title reads, the walker's head tilts to read it
## (scripts/walk_physics.gd, aimed_spine and hold_aim).
## Language: English unless the page's address says otherwise (?lang=fr) or the reader came from
## a French or Spanish page of the site. A selector at the top right, in the catalogue too, and the
## T key switch it; the shelves, signs, cards, catalogue and course links follow, and the web build
## writes the choice into the page's address so that a reload keeps it.
## observatory.gd creates this node and calls configure() with the shelf geometry first.

const CATALOGUE_PATH := "res://assets/courses.json"
const CatalogueRequest := preload("res://scripts/catalogue_request.gd")
signal catalogue_updated(count: int, cpu_usec: int)
## The library wings off two bays (scripts/library_wing.gd): the areas step over their bays, which have no
## shelves at the floor's level any more.
const WING_SCRIPT_PATH := "res://scripts/library_wing.gd"
## An opened course's panels: the courses pedestal's tree (scripts/glassworks.gd TERMINALS[1]), opened on the course.
const READER_SCRIPT_PATH := "res://scripts/holo_tree.gd"
const READER_TREE := "res://assets/course_tree.json"
## Metres from the reader's eyes to the panels, at most: short of the book, towards it.
const READER_AT := 1.4
## The gardens' glazed bays (palace_gardens.gd BAYS): no shelves at the floor's level there either.
const GARDENS_SCRIPT_PATH := "res://scripts/palace_gardens.gd"
## Book cloth per area, in the sidebar's order (sRGB).
const CLOTHS := [Color(0.36, 0.09, 0.08), Color(0.09, 0.14, 0.3), Color(0.12, 0.26, 0.16), Color(0.35, 0.21, 0.09),
	Color(0.07, 0.25, 0.27), Color(0.25, 0.1, 0.3), Color(0.42, 0.2, 0.06), Color(0.32, 0.06, 0.16),
	Color(0.55, 0.49, 0.36), Color(0.16, 0.16, 0.18)]
const GILT := Color(0.86, 0.7, 0.4)
const INK := Color(0.09, 0.07, 0.05)
const CARD := Color(0.64, 0.58, 0.46)
## INSTANCE_CUSTOM.x of a course book: cloth (0.7) plus 1, which tells assets/book_spines.gdshader
## to leave out its decorative title, since a Label3D carries the real one.
const REAL_TITLE_CLOTH := 1.7
## Metres: aiming farther than this picks nothing.
const REACH := 6.0
const AIM_GLOW := preload("res://scripts/aim_glow.gd")
## How far an aimed book slides out of the row, in metres.
const SLIDE := 0.05
## Metres: the aimed book stays aimed while the ray passes this close to it; a ray that meets no
## book takes the one it passes within AIM_NEAR of (the spines stand 3 mm apart).
const AIM_KEEP := 0.008
const AIM_NEAR := 0.015
## The languages of the selector, in its order.
const LANGS := ["en", "fr", "es"]
## Metres of bare shelf between a course series and the ordinary books either side of it.
const GAP := 0.3
## Metres of shelf between two departments of a series (Streeling University), a brass bookend in
## the middle of it.
const DEPT_GAP := 0.07
## The bay sign, standing on the board over the course row: its height, and its gap over the board.
const SIGN_H := 0.5
const SIGN_GAP := 0.035
## The banner over a course bay: width and height, and its clearance over the bay sign.
const BANNER_W := 1.3
const BANNER_H := 2.5
const BANNER_GAP := 0.9
## Metres of bare shelf between the banner's edge and the books on the rows behind it.
const BANNER_CLEAR := 0.06
## The banner's cloth: the area's colour with vertical folds, a darker hem and a faint glow of its
## own colour. The instance colour is sRGB; Forward+ shades in linear light, Compatibility in sRGB.
const BANNER_SHADER := """shader_type spatial;
render_mode cull_disabled;
uniform bool linear_light = true;
uniform float glow = 0.3;
void fragment() {
	vec3 c = COLOR.rgb;
	if (linear_light) {
		c = pow(c, vec3(2.2));
	}
	float fold = 0.8 + 0.2 * sin(UV.x * 31.4) * sin(UV.x * 12.6 + 1.3);
	float hem = mix(0.7, 1.0, 1.0 - smoothstep(0.9, 0.98, UV.y));
	ALBEDO = c * fold * hem;
	ROUGHNESS = 0.92;
	EMISSION = c * glow * fold;
}
"""
## The display lamp's light (sRGB).
const LAMP := Color(1.0, 0.8, 0.55)
## How much lighter a course book's cloth is than the area's colour: the lamp lights it.
const LIT := 1.25
const TEXT := {
	"en": {"lessons": "%d lessons", "lesson": "1 lesson", "pages": "%d pages", "page": "1 page", "hint": "L: all %d courses",
		"open": "Click or Enter: open the course in a new tab  ·  L: every course",
		"read": "Hold E: lean right and read the spine; the mouse or A/D: the next ones",
		"touch_read": "Hold the figure leaning right: read the spine; drag or tap: the next ones",
		"title": "Courses", "close": "Click a course to open it in a new tab  ·  L or Esc: close",
		"touch_hint": "Tap a book for its card, again to open it",
		"touch_open": "Tap the book again: open the course in a new tab",
		"touch_close": "Tap a course to open it in a new tab  ·  Close: top right",
		"courses": "%d courses", "course": "1 course", "language": "Language (T)",
		"age": "age", "dev": "development build",
		"web": "Web version · WebGL 2", "native": "Native version · %s", "rtx": "Native RTX version · %s",
		"quality": "quality %d/5 (%s)", "auto": "auto", "fixed": "fixed",
		"continued": "continued"},
	"fr": {"lessons": "%d leçons", "lesson": "1 leçon", "pages": "%d pages", "page": "1 page", "hint": "L : les %d cours",
		"open": "Clic ou Entrée : ouvrir le cours dans un nouvel onglet  ·  L : tous les cours",
		"read": "Maintiens A (Q en QWERTY) : te pencher à gauche et lire le dos ; la souris ou Q/D (A/D en QWERTY) : les suivants",
		"touch_read": "Maintiens la silhouette penchée à gauche : lire le dos ; glisse ou touche : les suivants",
		"title": "Cours", "close": "Clique sur un cours pour l'ouvrir dans un nouvel onglet  ·  L ou Échap : fermer",
		"touch_hint": "Touche un livre pour sa fiche, encore pour l'ouvrir",
		"touch_open": "Touche encore le livre : ouvrir le cours dans un nouvel onglet",
		"touch_close": "Touche un cours pour l'ouvrir dans un nouvel onglet  ·  Fermer : en haut à droite",
		"courses": "%d cours", "course": "1 cours", "language": "Langue (T)",
		"age": "âge", "dev": "version de développement",
		"web": "Version web · WebGL 2", "native": "Version native · %s", "rtx": "Version native RTX · %s",
		"quality": "qualité %d/5 (%s)", "auto": "auto", "fixed": "fixée",
		"continued": "suite"},
	"es": {"lessons": "%d lecciones", "lesson": "1 lección", "pages": "%d páginas", "page": "1 página", "hint": "L: los %d cursos",
		"open": "Clic o Intro: abrir el curso en una pestaña nueva  ·  L: todos los cursos",
		"read": "Mantén E: inclínate a la derecha y lee el lomo; el ratón o A/D: los siguientes",
		"touch_read": "Mantén la silueta inclinada a la derecha: leer el lomo; desliza o toca: los siguientes",
		"title": "Cursos", "close": "Haz clic en un curso para abrirlo en una pestaña nueva  ·  L o Esc: cerrar",
		"touch_hint": "Toca un libro para ver su ficha y otra vez para abrirlo",
		"touch_open": "Toca otra vez el libro: abrir el curso en una pestaña nueva",
		"touch_close": "Toca un curso para abrirlo en una pestaña nueva  ·  Cerrar: arriba a la derecha",
		"courses": "%d cursos", "course": "1 curso", "language": "Idioma (T)",
		"age": "edad", "dev": "versión de desarrollo",
		"web": "Versión web · WebGL 2", "native": "Versión nativa · %s", "rtx": "Versión nativa RTX · %s",
		"quality": "calidad %d/5 (%s)", "auto": "auto", "fixed": "fija",
		"continued": "continuación"},
}

## Emitted with the course's URL, relative to the site root, when a course is opened.
signal course_opened(url: String)
## Emitted when the reader picks another language (observatory.gd passes it to the statue).
signal lang_changed(code: String)

var catalogue := {}
var lang := "en"
## Counts of the last build, for observatory.gd's stats.
var stats := {}
## The last course opened (relative URL), for tests.
var last_opened := ""

var _radius := 17.45
var _bay_count := 16
var _width := 6.2
var _row_pitch := 0.62
var _first_bay := 7
var _row := 2
var _obs: Node  # observatory.gd: the book mesh, the bindings and the board filler come from it
var _books: Array = []  # {course, area, k, bay, mm, index, xf, col, slide, label, label_xf}
## The hall's own books the course rows stand in place of: [multimesh, index, transform] (_hide_hall_rows).
var _hidden: Array = []
var _hall_rows := {}  # bay -> {row: true}: the rows of the hall's books the last build took over
var _area_at := {}  # bay -> area index, from the last build
var _unsupported := false  # the last catalogue fetched had more areas than course bays
var _hovered := -1
var _shell: MeshInstance3D  # the aimed book's glow (_glow_frame)
var _reader: Node3D  # an opened course's panels (scripts/holo_tree.gd), between the reader and its book
var _shell_amount := 0.0
var _aim_held := false  # the walker reads the aimed book's spine: it stays aimed (hold_aim)
var _active := false  # set by the first real input, so scripted captures never show a card
## Set by scripts/touch_controls.gd: books are aimed at by taps, not by the mouse.
var _touch := false
var _touch_point := Vector2.INF
## Phones: their canvas has two to three pixels per point, so the text grows with the screen.
var _ui_scale := 1.0
var _ignore_escape_until := -1
var _hud: Node  # the scene's ControlsHud: captures hide it, and the course UI with it
var _ui: CanvasLayer
var _card: PanelContainer
var _card_area: Label
var _card_title: Label
var _card_meta: Label
var _card_text: Label
var _card_hint: Label
var _crosshair: Control
var _hint: Label
var _hint_panel: PanelContainer
var _overlay: Control
var _overlay_title: Label
var _overlay_hint: Label
var _list: VBoxContainer
var _http: CatalogueRequest
var _pending_catalogue := {}
var _refresh_button: Button
var last_refresh_status := "embedded"
var last_rebuild_usec := 0
var _lang_chosen := false  # by the reader: a catalogue fetched later keeps it
var _lang_panel: PanelContainer
var _lang_label: Label
var _version_label: Label
const BuildInfo := preload("res://scripts/build_info.gd")
var _version_minute := -1
var _kind_label: Label        # under the version line: web or native, RTX, and the quality level
var _kind_key := ""           # what _kind_label was last drawn for
var _lang_buttons: Array = []  # {code, button, hud}


## radius: the shelf units' distance from the centre; width: a unit's inner width; row_pitch: the
## ground level's board spacing; first_bay: the bay of the first area (the rest follow); row: the
## row this node fills in every ground-level bay; observatory: the node that built the shelves.
func configure(radius: float, bay_count: int, width: float, row_pitch: float, first_bay: int, row: int, observatory: Node) -> void:
	_radius = radius
	_bay_count = bay_count
	_width = width
	_row_pitch = row_pitch
	_first_bay = first_bay
	_row = row
	_obs = observatory


func _ready() -> void:
	catalogue = _load_catalogue()
	if not _supported(catalogue):
		catalogue = _embedded_catalogue()
	lang = _detect_lang()
	_build()
	if Engine.is_editor_hint():
		return
	# Aims after everything that moves the camera has: the walking body (100) puts back the step the
	# fly camera (0) takes left with Q, which leans; aimed before, a book's neighbour was aimed.
	process_priority = 900
	_make_ui()
	_fill_list()
	_fetch_live()


# --- Catalogue ------------------------------------------------------------------

static func _load_catalogue() -> Dictionary:
	if not OS.has_feature("web"):
		var cached := CatalogueRequest.load_cache()
		if not cached.is_empty():
			return cached
	return _embedded_catalogue()


static func _embedded_catalogue() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE_PATH))
	return data if data is Dictionary else {}


## Whether every area of a catalogue has a course bay of its own, and every course a place on the rows
## of its area's bay or of the free bays its series runs on to. One that has not is refused whole: no
## course is left out, nor an area put in a bay with another.
func _supported(data: Dictionary) -> bool:
	return not _plan(data.get("areas", [])).is_empty()


## ?lang= on the page, else the site's language when the reader came from one of its French or
## Spanish pages (/learn/fr/…), else English; --lang= on the command line on the desktop. Neither
## the browser's nor the system's language: English is the default.
func _detect_lang() -> String:
	var code := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			code = arg.trim_prefix("--lang=")
	if code == "" and OS.has_feature("web"):
		code = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('lang') || "
			+ "((document.referrer.match(/\\/learn\\/(fr|es)\\//) || [])[1]) || 'en'", true))
	code = code.substr(0, 2).to_lower()
	return code if code in _langs() else "en"


## The selector's languages that the catalogue has.
func _langs() -> Array:
	var out := []
	for code: String in LANGS:
		if code in catalogue.get("locales", ["en"]) and TEXT.has(code):
			out.append(code)
	return out


## Switches the shelves, signs, cards, catalogue and course links to another language. The web
## build also writes it into the page's address, so a reload keeps it.
func set_lang(code: String) -> void:
	if not code in _langs():
		return
	_lang_chosen = true
	if code != lang:
		lang = code
		_rebuild()
		_fill_list()
		if OS.has_feature("web"):
			JavaScriptBridge.eval("(() => { const u = new URL(location.href); u.searchParams.set('lang', %s); "
				% JSON.stringify(code) + "history.replaceState(history.state, '', u); })()", true)
		lang_changed.emit(code)
	_sync_lang_buttons()


## The next language of the selector (the T key).
func cycle_lang() -> void:
	var langs := _langs()
	set_lang(langs[(langs.find(lang) + 1) % langs.size()])


## The language whose selector button (the one on screen, not the catalogue's) is under pos, or
## "": scripts/touch_controls.gd asks, since touches do not reach the controls as clicks.
func lang_at(pos: Vector2) -> String:
	if _lang_panel == null or not _lang_panel.is_visible_in_tree():
		return ""
	for b: Dictionary in _lang_buttons:
		if b.hud and (b.button as Control).get_global_rect().has_point(pos):
			return b.code
	return ""


func _fetch_live() -> void:
	if _http == null:
		_http = CatalogueRequest.new()
		_http.name = "LiveCatalogue"
		add_child(_http)
		_http.catalogue_ready.connect(_apply_catalogue)
		_http.refresh_finished.connect(_refresh_finished)
	var url: String = CatalogueRequest.PUBLIC_URL
	if OS.has_feature("web"):
		url = str(JavaScriptBridge.eval("new URL('courses.json', location.href).href", true))
	if _http.refresh(url, OS.has_feature("web")) == OK:
		_unsupported = false
		last_refresh_status = "loading"
		if _refresh_button != null:
			_refresh_button.disabled = true


func _refresh_finished(status: String) -> void:
	last_refresh_status = "unsupported" if _unsupported and status == "current" else status
	if _refresh_button != null:
		_refresh_button.disabled = false
		_refresh_button.tooltip_text = status


func _apply_catalogue(data: Dictionary) -> void:
	if not CatalogueRequest.valid(data):
		return
	if _aim_held:
		_pending_catalogue = data  # do not remove a book while the walker is reading it
		return
	if data == catalogue:
		return
	if not _supported(data):
		_unsupported = true
		last_refresh_status = "unsupported"
		push_warning("Course catalogue refused: %d areas for %d course bays" % [(data.areas as Array).size(), _course_bays().size()])
		return
	var scroll := _list.get_parent() as ScrollContainer if _list != null else null
	var previous_scroll := scroll.scroll_vertical if scroll != null else 0
	catalogue = data
	if not _lang_chosen:
		lang = _detect_lang()
	var started := Time.get_ticks_usec()
	_rebuild()
	_fill_list()
	last_rebuild_usec = Time.get_ticks_usec() - started
	if scroll != null:
		scroll.set_deferred("scroll_vertical", previous_scroll)
	var total := 0
	for area: Dictionary in data.areas:
		total += area.courses.size()
	catalogue_updated.emit(total, last_rebuild_usec)


func _t(key: String) -> String:
	return TEXT[lang][key]


func _in_lang(values: Variant) -> String:
	if values is Dictionary:
		return str(values.get(lang, values.get("en", "")))
	return str(values)


func _count_text(course: Dictionary) -> String:
	var n := int(_in_lang(course.get("lessons", {})))
	if course.get("unit", "lessons") == "pages":
		return _t("page") if n == 1 else _t("pages") % n
	return _t("lesson") if n == 1 else _t("lessons") % n


## The title on a book's spine: its short spine title when the catalogue gives one.
func _spine_text(course: Dictionary) -> String:
	var spine := _in_lang(course.get("spine", ""))
	return spine if spine != "" else _in_lang(course.get("title", ""))


## The department a course belongs to, in the current language, or "".
func _group(course: Dictionary) -> String:
	return _in_lang(course.get("group", ""))


## A department's short name on the card under its books: its courses' code before the dash (AUD
## for AUD-001), else the department's initials.
func _group_code(course: Dictionary) -> String:
	var code := str(course.get("code", ""))
	if code.contains("-"):
		return code.get_slice("-", 0)
	var initials := ""
	for word in _group(course).split(" ", false):
		if word[0] == word[0].to_upper() and word[0] != "&":
			initials += word[0]
	return initials


## The cloth of the i-th department of a series: never the area's own, which lines the display
## behind them, and never the same as the department before it.
func _dept_cloth(area_k: int, i: int) -> Color:
	var others: Array = []
	for c in CLOTHS.size():
		if c != area_k % CLOTHS.size():
			others.append(CLOTHS[c])
	return others[(i * 4) % others.size()]


# --- Shelves --------------------------------------------------------------------

func _build() -> void:
	for child in get_children():
		# The aimed book's glow stays, as the UI and the request do: _glow_frame moves it to the new book.
		if child != _ui and child != _http and child != _shell and child != _reader:
			remove_child(child)
			child.queue_free()
	_books.clear()
	_hovered = -1
	_area_at.clear()
	_show_hall_rows()
	_hall_rows.clear()
	if _card != null:
		_card.visible = false
	stats = {"areas": 0, "volumes": 0, "courses": 0, "shelves": 0, "row_books": 0, "lang": lang}
	if _obs == null or not (_obs.get("_m") as Dictionary).has("book_bindings"):
		return
	var m: Dictionary = _obs.get("_m")
	var areas: Array = catalogue.get("areas", [])
	var book_mesh: Mesh = _obs.call("_book_mesh")
	var font := ThemeDB.fallback_font
	# Its own stream: the course rows never move the books of the other rows.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000003
	var clear := _row_pitch - 0.06
	var x0 := -_width * 0.5 + 0.08
	var x1 := _width * 0.5 - 0.08
	var plan := _plan(areas)
	if plan.is_empty():
		# _supported() keeps such a catalogue out: never a course left off, nor two areas in a bay.
		push_error("Course areas: %d, with their series, do not fit %d course bays" % [areas.size(), _course_bays().size()])
		return
	var owner: Dictionary = plan.owner  # bay -> area index: its own bay, and the free bays its series runs on to
	var home: Dictionary = plan.home  # area index -> its own bay
	for k: int in home:
		_area_at[home[k]] = k
	var segs_at := {}  # bay -> the runs of its series on its rows
	for seg: Dictionary in plan.segs:
		if not segs_at.has(seg.bay):
			segs_at[seg.bay] = []
		segs_at[seg.bay].append(seg)
	var catalogue_courses := 0
	for area: Dictionary in areas:
		catalogue_courses += (area.get("courses", []) as Array).size()
	var brass_xf: Array = []
	var card_xf: Array = []
	var lining_xf: Array = []
	var lining_col: Array = []
	var lamp_xf: Array = []
	var lamp_at: Array = []  # the eye-level lamps' centres, for the Forward+ spots
	var sign_xf: Array = []
	var banner_xf: Array = []
	var banner_col: Array = []
	var crystals: Array = []
	var row_books := 0
	var departments := 0  # cards under the departments of a series
	# The bays the gardens opened (palace_gardens.gd _open_bays): their doors and the library wing's
	# portal. The gardens hid this row there, but a later _build (the web's live catalogue, a language
	# change) put it back, floating across the wing's portal (the author, 2026-10-14: « il nous barre
	# la route », web v43). Filled into nothing, so the rows after it keep their books.
	var open: Array = _obs.get_meta("open_bays", []) if _obs.has_meta("open_bays") else []
	for bay in _bay_count:
		var base := _radial(TAU * (bay + 0.5) / _bay_count, _radius, 0.0)
		var out := {"xf": [], "col": [], "cus": [], "crystals": [], "series": 0, "leaning": 0, "lying": 0}
		var placed: Array = []
		if open.has(bay) and not owner.has(bay):
			_obs.call("_fill_board", rng, base, x0, x1, _row_y(_row), clear, out)
			continue
		if not owner.has(bay):
			_obs.call("_fill_board", rng, base, x0, x1, _row_y(_row), clear, out)
		else:
			var k: int = owner[bay]
			var area: Dictionary = areas[k]
			var courses: Array = area.get("courses", [])
			var cloth: Color = CLOTHS[k % CLOTHS.size()]
			# Each course's department, counted along the whole series, so that a department keeps its
			# cloth from one row to the next.
			var dept_of: Array[int] = []
			for j in courses.size():
				dept_of.append(0 if j == 0 else dept_of[j - 1] + int(_group(courses[j]) != _group(courses[j - 1])))
			var depts := dept_of.size() > 0 and dept_of[-1] > 0
			var taken := {}  # row -> [[from, to]] of the runs on it, for the hall's books round them
			for seg: Dictionary in segs_at.get(bay, []):
				var r: int = seg.row
				var y := _row_y(r)
				# The series: the same height, depth and cloth; each spine as wide as its title needs.
				var h := clear * 0.9
				var d := minf(h * 0.7, 0.36)
				# A series in departments: [first x, last x, code] of each on this row, for its card.
				var spans: Array = []
				var left: float = seg.xa
				var x := left
				for j in range(seg.start, seg.end):
					var w := _spine_width(courses[j])
					if j > seg.start and dept_of[j] != dept_of[j - 1]:
						# A brass bookend between two departments, in a gap of its own.
						var dh := h * 0.7
						brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(0.006, dh, d * 0.85)),
							Vector3(x + (DEPT_GAP - 0.003) * 0.5, y + dh * 0.5, 0.272 - d * 0.5)))
						x += DEPT_GAP
					if depts and (j == seg.start or dept_of[j] != dept_of[j - 1]):
						spans.append([x, x, _group_code(courses[j])])
					var book_cloth: Color = _dept_cloth(k, dept_of[j]) if depts else cloth
					var tone := (0.94 + 0.12 * rng.randf()) * LIT
					var col := Color(book_cloth.r * tone, book_cloth.g * tone, book_cloth.b * tone, rng.randf())
					var centre := Vector3(x + w * 0.5, y + h * 0.5, 0.272 - d * 0.5)
					placed.append({"course": courses[j], "area": area, "k": k, "bay": bay, "index": out.xf.size(), "col": col,
						"xf": base * Transform3D(Basis.from_scale(Vector3(w, h, d)), centre),
						"at": base * Transform3D(Basis(), centre), "size": Vector3(w, h, d), "slide": base.basis.z * SLIDE})
					out.xf.append(placed[-1].xf)
					out.col.append(col)
					out.cus.append(Color(REAL_TITLE_CLOTH, 0.0, 0.8, 0.04 + 0.08 * rng.randf()))
					x += w + 0.003
					if depts:
						spans[-1][1] = x - 0.003
				# Brass bookends against both ends of the run.
				var end_h := h * 0.62
				for ex: float in [left - 0.012, x + 0.009]:
					brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(0.006, end_h, d * 0.8)), Vector3(ex, y + end_h * 0.5, 0.272 - d * 0.45)))
				if not taken.has(r):
					taken[r] = []
				taken[r].append([left, x])
				# The display: a lining in the area's cloth behind the run and its bare shelf, and a
				# brass lamp under the board above, its tube facing down.
				var span := x - left + 2.0 * GAP - 0.04
				var cx := (left + x) * 0.5
				lining_xf.append(base * Transform3D(Basis.from_scale(Vector3(span, clear, 1.0)), Vector3(cx, y + clear * 0.5, -0.255)))
				lining_col.append(Color(minf(cloth.r * 1.3, 1.0), minf(cloth.g * 1.3, 1.0), minf(cloth.b * 1.3, 1.0)))
				var lamp_y := y + clear  # the underside of the board above
				brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(span, 0.022, 0.035)), Vector3(cx, lamp_y - 0.011, 0.24)))
				lamp_xf.append(base * Transform3D(Basis.from_scale(Vector3(span - 0.03, 0.008, 0.014)), Vector3(cx, lamp_y - 0.026, 0.236)))
				if r == _row:
					lamp_at.append([base * Transform3D(Basis(), Vector3(cx, lamp_y - 0.03, 0.2)), span])
				# Cards in brass holders on the front edge of the board under the run: one under each
				# department with its code; in a series without departments, the area's, under its first run.
				var cy := r * _row_pitch
				if depts:
					for sp: Array in spans:
						var dw: float = maxf(float(sp[1]) - float(sp[0]) - 0.006, 0.036)
						var dx: float = (float(sp[0]) + float(sp[1])) * 0.5
						brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(dw + 0.012, 0.052, 0.004)), Vector3(dx, cy, 0.302)))
						card_xf.append(base * Transform3D(Basis.from_scale(Vector3(dw, 0.042, 0.002)), Vector3(dx, cy, 0.3045)))
						_card_lines(base * Transform3D(Basis(), Vector3(dx, cy, 0.3058)), str(sp[2]), dw - 0.008, font)
					departments += spans.size()
				elif seg.start == 0:
					var cw := clampf(x - left + 0.04, 0.24, 0.9)
					brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(cw + 0.012, 0.052, 0.004)), Vector3(cx, cy, 0.302)))
					card_xf.append(base * Transform3D(Basis.from_scale(Vector3(cw, 0.042, 0.002)), Vector3(cx, cy, 0.3045)))
					_card_lines(base * Transform3D(Basis(), Vector3(cx, cy, 0.3058)), _in_lang(area.get("label", "")), cw - 0.024, font)
			# The rest of each row the series takes: the hall's own books, which go from those rows, here
			# drawn round its runs; the eye-level row is the library's in every course bay.
			if not taken.has(_row):
				taken[_row] = []
			var hall_rows := {}
			for r: int in taken:
				if r != _row:
					hall_rows[r] = true
				var runs: Array = taken[r]
				runs.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
				var from := x0
				for run: Array in runs:
					if float(run[0]) - GAP - from > 0.05:
						_obs.call("_fill_board", rng, base, from, float(run[0]) - GAP, _row_y(r), clear, out)
					from = float(run[1]) + GAP
				if x1 - from > 0.05:
					_obs.call("_fill_board", rng, base, from, x1, _row_y(r), clear, out)
			_hide_hall_rows(bay, hall_rows)
			# The sign over the eye-level row, on the board above it, just over a walker's eyes: black
			# lacquer in a brass frame, the area in gilt; on a bay the series runs on to, "continued".
			var own: bool = home[k] == bay
			var sw := _width - 0.9
			var sy := (_row + 1) * _row_pitch + 0.03 + SIGN_GAP + SIGN_H * 0.5
			sign_xf.append(base * Transform3D(Basis.from_scale(Vector3(sw, SIGN_H, 0.03)), Vector3(0, sy, 0.33)))
			for fy: float in [sy - SIGN_H * 0.5, sy + SIGN_H * 0.5]:
				brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(sw + 0.05, 0.028, 0.045)), Vector3(0, fy, 0.335)))
			for fx: float in [-sw * 0.5, sw * 0.5]:
				brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(0.028, SIGN_H + 0.028, 0.045)), Vector3(fx, sy, 0.335)))
			var n := courses.size()
			_sign_lines(base * Transform3D(Basis(), Vector3(0, sy, 0.3465)), _in_lang(area.get("label", "")),
				(_t("course") if n == 1 else _t("courses") % n) if own else _t("continued"), sw - 0.3, font)
			if own:
				# The banner: the area's cloth under a brass rod, with a gilt hem, over the sign.
				var by := sy + SIGN_H * 0.5 + BANNER_GAP + BANNER_H * 0.5
				banner_xf.append(base * Transform3D(Basis.from_scale(Vector3(BANNER_W, BANNER_H, 1.0)), Vector3(0, by, 0.42)))
				banner_col.append(Color(minf(cloth.r * 1.5, 1.0), minf(cloth.g * 1.5, 1.0), minf(cloth.b * 1.5, 1.0)))
				brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(BANNER_W + 0.14, 0.035, 0.035)), Vector3(0, by + BANNER_H * 0.5 + 0.018, 0.42)))
				brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(BANNER_W, 0.025, 0.008)), Vector3(0, by - BANNER_H * 0.5 + 0.0125, 0.4245)))
				for gx: float in [-BANNER_W * 0.5 + 0.05, BANNER_W * 0.5 - 0.05]:
					brass_xf.append(base * Transform3D(Basis.from_scale(Vector3(0.018, BANNER_H - 0.06, 0.006)), Vector3(gx, by, 0.4235)))
				_banner_lines(base * Transform3D(Basis(), Vector3(0, by, 0.4215)), _in_lang(area.get("label", "")), BANNER_W - 0.2, font)
		var mmi: MultiMeshInstance3D = _obs.call("_multi", self, "CourseRow_B%02d" % bay, book_mesh, m.book_bindings, out.xf, out.col, true, out.cus)
		crystals.append_array(out.crystals)
		row_books += out.xf.size() - placed.size()
		for p: Dictionary in placed:
			var label := _spine_title(_spine_text(p.course), p.at, p.size, font)
			_books.append({"course": p.course, "area": p.area, "k": p.k, "bay": p.bay, "mm": mmi.multimesh, "index": p.index, "xf": p.xf,
				"col": p.col, "slide": p.slide, "label": label, "label_xf": label.transform})
	var unit := BoxMesh.new()
	unit.size = Vector3.ONE
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = CARD
	card_mat.roughness = 0.92
	_obs.call("_multi", self, "CourseBrass", unit, m.bronze, brass_xf)
	_obs.call("_multi", self, "CourseCards", unit, card_mat, card_xf, [], false)
	if not sign_xf.is_empty():
		var lacquer := StandardMaterial3D.new()
		lacquer.albedo_color = Color(0.03, 0.026, 0.024)
		lacquer.roughness = 0.3
		_obs.call("_multi", self, "CourseSigns", unit, lacquer, sign_xf, [], false)
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		_obs.call("_multi", self, "CourseLinings", quad, _lining_material(), lining_xf, lining_col, false)
		var banner_shader := Shader.new()
		banner_shader.code = BANNER_SHADER
		var banner_mat := ShaderMaterial.new()
		banner_mat.shader = banner_shader
		banner_mat.set_shader_parameter("linear_light", not _compatibility())
		banner_mat.set_shader_parameter("glow", 0.22 if _compatibility() else 0.5)
		_obs.call("_multi", self, "CourseBanners", quad, banner_mat, banner_xf, banner_col, false)
		var tube := StandardMaterial3D.new()
		tube.albedo_color = LAMP
		tube.emission_enabled = true
		tube.emission = LAMP
		tube.emission_energy_multiplier = 3.0
		_obs.call("_multi", self, "CourseLamps", unit, tube, lamp_xf, [], false)
		if not _compatibility():
			for la: Array in lamp_at:
				_display_light(la[0], la[1])
	if not crystals.is_empty():
		var prism := CylinderMesh.new()
		prism.top_radius = 0.5
		prism.bottom_radius = 0.5
		prism.height = 1.0
		prism.radial_segments = 6
		_obs.call("_multi", self, "CourseRowCrystals", prism, m.crystal, crystals, [], false)
	# volumes: the course books on the shelves, every course of the catalogue; shelves: the runs.
	stats = {"areas": home.size(), "volumes": _books.size(), "courses": catalogue_courses, "shelves": plan.segs.size(),
		"row_books": row_books, "lang": lang, "departments": departments,
		"signs": sign_xf.size(), "lamps": lamp_xf.size(), "banners": banner_xf.size()}
	if _obs.get("stats") is Dictionary:
		_obs.stats.course_areas = stats.areas
		_obs.stats.course_volumes = stats.volumes
		_obs.stats.course_count = stats.courses


## Builds the shelves again, the aimed course still aimed when it remains.
func _rebuild() -> void:
	var previous_id := str(_books[_hovered].course.id) if _hovered >= 0 and _hovered < _books.size() else ""
	_build()
	if previous_id == "" or _card == null:
		return
	for i in _books.size():
		if str(_books[i].course.id) == previous_id:
			_set_hover(i)
			break


# --- Rows of a series -----------------------------------------------------------

## A course book's spine width: as wide as its title needs, between bounds.
func _spine_width(course: Dictionary) -> float:
	return clampf(0.036 + 0.0008 * _spine_text(course).length(), 0.042, 0.068)


## The top of row r's board, where its books stand.
func _row_y(r: int) -> float:
	return r * _row_pitch + 0.03


## The ground-level units' rows (observatory.gd: up to the first gallery's floor less 0.6 m, at the row
## pitch): nine in the hall.
func _ground_rows() -> int:
	var levels: Variant = _obs.get("gallery_levels") if _obs != null else null
	if levels is PackedFloat32Array and not (levels as PackedFloat32Array).is_empty():
		return maxi(_row + 2, roundi(((levels as PackedFloat32Array)[0] - 0.6) / _row_pitch))
	return 9


## The banner's foot and head over an area's own bay, from the sign under it (_build).
func _banner_span() -> Array:
	var foot := (_row + 1) * _row_pitch + 0.03 + SIGN_GAP + SIGN_H + BANNER_GAP
	return [foot, foot + BANNER_H]


## The shelves a series takes in a bay, in the order it fills them: the eye-level row, the rows under it
## down to the floor, then those over the sign upwards (the author, 2026-10-31: « tout dans la même
## section ou sections si ça déborde »). On an area's own bay the banner hangs over the middle of the
## high rows: a run on each side of it there. Each {bay, row, xa, xb}: the span its books may take,
## within the bare shelf either side, where the bookends stand.
func _slots(bay: int, banner: bool) -> Array:
	var xa := -_width * 0.5 + 0.08 + GAP
	var xb := _width * 0.5 - 0.08 - GAP
	var hung := _banner_span()
	var order: Array[int] = []
	for r in range(_row, -1, -1):
		order.append(r)
	for r in range(_row + 2, _ground_rows()):
		order.append(r)
	var out: Array = []
	for r in order:
		var lo := r * _row_pitch
		if banner and lo + _row_pitch > hung[0] and lo < hung[1]:
			out.append({"bay": bay, "row": r, "xa": xa, "xb": -BANNER_W * 0.5 - BANNER_CLEAR})
			out.append({"bay": bay, "row": r, "xa": BANNER_W * 0.5 + BANNER_CLEAR, "xb": xb})
		else:
			out.append({"bay": bay, "row": r, "xa": xa, "xb": xb})
	return out


## The end of the run of courses from `start` whose spines, the 3 mm between them and their departments'
## bookend gaps fit `width`: one course at least. The cut follows the spines' widths in the current language.
func _cut(courses: Array, start: int, width: float) -> int:
	var used := 0.0
	for j in range(start, courses.size()):
		var w := _spine_width(courses[j]) + 0.003
		var gap := DEPT_GAP if j > start and _group(courses[j]) != _group(courses[j - 1]) else 0.0
		if j > start and used + gap + w > width:
			return j
		used += gap + w
	return courses.size()


## Where every course stands: each area on its own course bay's shelves (_slots), and a series longer than
## they hold on to the free course bays, in order. {segs: [{bay, row, xa, xb, start, end}], owner:
## {bay: area}, home: {area: bay}}; {} when the areas or their series do not fit.
func _plan(areas: Array) -> Dictionary:
	var bays := _course_bays()
	if areas.size() > bays.size():
		return {}
	var free := bays.slice(areas.size())
	var segs: Array = []
	var owner := {}
	var home := {}
	for k in areas.size():
		var courses: Array = (areas[k] as Dictionary).get("courses", [])
		home[k] = bays[k]
		owner[bays[k]] = k
		var slots := _slots(bays[k], true)
		var start := 0
		while start < courses.size():
			if slots.is_empty():
				if free.is_empty():
					return {}
				var more: int = free.pop_front()
				owner[more] = k
				slots = _slots(more, false)
			var slot: Dictionary = slots.pop_front()
			var end := _cut(courses, start, float(slot.xb) - float(slot.xa))
			segs.append({"bay": slot.bay, "row": slot.row, "xa": slot.xa, "xb": slot.xb, "start": start, "end": end})
			start = end
	return {"segs": segs, "owner": owner, "home": home}


## The hall's own books and crystals (observatory.gd Generated/Shelves) on the rows of a bay a series
## takes: shrunk to nothing, as palace_gardens.gd _cut_shelves does, and kept to be put back.
func _hide_hall_rows(bay: int, rows: Dictionary) -> void:
	_hall_rows[bay] = rows
	var shelves := _obs.get_node_or_null("Generated/Shelves") if _obs != null else null
	if shelves == null or rows.is_empty():
		return
	for node_name: String in ["Books_B%02d" % bay, "CrystalArchives"]:
		var mmi := shelves.get_node_or_null(node_name) as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		var mm := mmi.multimesh
		var xfs: Array = []
		for j in mm.instance_count:
			xfs.append(mmi.transform * mm.get_instance_transform(j))
		var row_of := _hall_rows_of(bay, xfs)
		for j in row_of.size():
			if rows.has(row_of[j]):
				var xf := mm.get_instance_transform(j)
				_hidden.append([mm, j, xf])
				mm.set_instance_transform(j, Transform3D(Basis.from_scale(Vector3.ZERO), xf.origin))


## The ground-level row of a bay each of the hall's books stands on, from its transform in the hall; -1
## for a book elsewhere (another bay, a gallery) or already shrunk away.
func _hall_rows_of(bay: int, xfs: Array) -> Array[int]:
	var to_bay := _radial(TAU * (bay + 0.5) / _bay_count, _radius, 0.0).affine_inverse()
	var top := _ground_rows() * _row_pitch
	var out: Array[int] = []
	for xf: Transform3D in xfs:
		var p := to_bay * xf.origin
		var gone := xf.basis.get_scale().length() < 1e-6
		out.append(-1 if gone or absf(p.x) > _width * 0.5 or absf(p.z) > 1.0 or p.y < 0.0 or p.y >= top else int(floor(p.y / _row_pitch)))
	return out


## The hall's books the last build shrank, back.
func _show_hall_rows() -> void:
	for h: Array in _hidden:
		if is_instance_valid(h[0]):
			(h[0] as MultiMesh).set_instance_transform(h[1], h[2])
	_hidden.clear()


## Forward+: the display lamp's light, a warm spot from the tube down over the series and its
## lining. No shadow: the series stands in the open under it.
func _display_light(at: Transform3D, span: float) -> void:
	var spot := SpotLight3D.new()
	spot.light_color = LAMP
	spot.light_energy = 2.5
	spot.spot_range = 0.9
	spot.spot_angle = clampf(rad_to_deg(atan(span * 0.5 / 0.45)), 40.0, 75.0)
	spot.spot_attenuation = 0.6
	spot.shadow_enabled = false
	spot.light_specular = 0.3
	# Pointing down (the spot's -Z) and a little back, towards the lining.
	spot.transform = at * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.35), Vector3.ZERO)
	add_child(spot)


static func _compatibility() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


## The display's lining: the area's cloth (the instance colour), washed with the lamp's light from
## the top, as if lit from the tube above: a glow under Compatibility, a trace under Forward+ where
## a real lamp lights it (_display_light).
static func _lining_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.95
	mat.emission_enabled = true
	mat.emission = LAMP
	mat.emission_energy_multiplier = 0.12 if _compatibility() else 0.01
	var wash := Gradient.new()
	wash.set_color(0, Color(1, 1, 1))
	wash.set_color(1, Color(0.08, 0.08, 0.08))
	var tex := GradientTexture2D.new()
	tex.gradient = wash
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 64
	mat.emission_texture = tex
	return mat


## The title in gilt along the spine, as large as the spine's width and length allow. Spines read
## top to bottom (ISO 6357, and English-language practice), except in French, where publishers
## print them bottom to top.
func _spine_title(text: String, at: Transform3D, size: Vector3, font: Font) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	var px := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x
	var usable := size.y - 0.08  # clear of the gilt rules at head and tail
	label.pixel_size = minf(size.x * 0.38 / label.font_size, usable / maxf(px, 1.0))
	label.modulate = GILT
	label.shaded = true
	label.outline_size = 0
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var spin := PI * 0.5 if lang == "fr" else -PI * 0.5
	label.transform = at * Transform3D(Basis(Vector3.BACK, spin), Vector3(0, 0, size.z * 0.5 + 0.0012))
	add_child(label)
	return label


## The area on its shelf card in ink: one line, or the parent area small above the sub-area.
func _card_lines(at: Transform3D, text: String, width_m: float, font: Font) -> void:
	var parts := text.split(" › ")
	var lines: Array = [[parts[-1], 0.0, 0.022]]
	if parts.size() > 1:
		lines = [[" › ".join(parts.slice(0, parts.size() - 1)), 0.0115, 0.0095], [parts[-1], -0.0055, 0.017]]
	for line: Array in lines:
		var label := Label3D.new()
		label.text = line[0]
		label.font_size = 48
		var px := font.get_string_size(line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x
		label.pixel_size = minf(float(line[2]) / label.font_size, width_m / maxf(px, 1.0))
		label.modulate = INK
		label.shaded = true
		label.double_sided = false
		label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		label.transform = at * Transform3D(Basis(), Vector3(0, line[1], 0))
		add_child(label)


## The bay sign's lettering in gilt: the parent area small above (when there is one), the area
## large, and its number of courses small below. Unshaded, so it reads across the dim hall.
func _sign_lines(at: Transform3D, text: String, count: String, width_m: float, font: Font) -> void:
	var parts := text.split(" › ")
	var lines: Array = [[parts[-1], 0.045, 0.2], [count, -0.155, 0.07]]
	if parts.size() > 1:
		lines = [[" › ".join(parts.slice(0, parts.size() - 1)).to_upper(), 0.15, 0.072], [parts[-1], -0.01, 0.18], [count, -0.17, 0.064]]
	for line: Array in lines:
		var label := Label3D.new()
		label.text = line[0]
		label.font_size = 96
		var px := font.get_string_size(line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x
		label.pixel_size = minf(float(line[2]) / label.font_size, width_m / maxf(px, 1.0))
		label.modulate = GILT
		label.shaded = false
		label.double_sided = false
		label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		label.transform = at * Transform3D(Basis(), Vector3(0, line[1], 0))
		add_child(label)


## The banner's lettering in gilt: the parent area small near the top (when there is one), the
## area in capitals, as large as the banner's width allows, wrapped over lines.
func _banner_lines(at: Transform3D, text: String, width_m: float, font: Font) -> void:
	var parts := text.split(" › ")
	var lines: Array = [[parts[-1].to_upper(), 0.25, 0.17]]
	if parts.size() > 1:
		lines.append([" › ".join(parts.slice(0, parts.size() - 1)).to_upper(), BANNER_H * 0.5 - 0.3, 0.07])
	for line: Array in lines:
		var label := Label3D.new()
		label.text = line[0]
		label.font_size = 96
		label.pixel_size = float(line[2]) / label.font_size
		# Wrapped at the banner's width, and smaller when one word alone is wider than that.
		var widest := 0.0
		for word: String in str(line[0]).split(" "):
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x)
		# With a margin: fitted exactly, the widest word wrapped inside itself ("INFRASTRUCTUR / E").
		label.pixel_size = minf(label.pixel_size, 0.92 * width_m / maxf(widest, 1.0))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.width = width_m / label.pixel_size
		label.line_spacing = 4.0
		label.modulate = GILT
		label.shaded = false
		label.double_sided = false
		label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		label.transform = at * Transform3D(Basis(), Vector3(0, line[1], 0))
		add_child(label)


## The library wings' bays, when they are wanted (library_wing.gd bays(): 10 and 13); none otherwise.
static func _wing_bays() -> Array[int]:
	var out: Array[int] = []
	if not ResourceLoader.exists(WING_SCRIPT_PATH):
		return out
	var script: GDScript = load(WING_SCRIPT_PATH)
	for i: int in script.call("bays"):
		out.append(i)
	return out


## Area k's bay: from first_bay on; with the wings, from the bay before first_bay, stepping over theirs.
## With bay 10's alone the last area stayed where it was; with the twin's (13) too, the last three move one
## bay on, the last to bay 0.
## Past the bays there are, -1: _supported() refuses such a catalogue.
func _area_bay(k: int) -> int:
	var bays := _course_bays()
	return bays[k] if k >= 0 and k < bays.size() else -1


## The bays the areas take, in order: Area k's is the k-th. They step over the wings' bays and the
## gardens' (palace_gardens.gd BAYS, and any other the hall opened: the observatory's open_bays), where
## the floor has no shelves. The gardens' come after the ninth area, so the current nine stay put.
func _course_bays() -> Array[int]:
	var skip: Array = []
	skip.append_array(_wing_bays())
	var start := _first_bay if skip.is_empty() else _first_bay - 1
	if ResourceLoader.exists(GARDENS_SCRIPT_PATH):
		skip.append_array((load(GARDENS_SCRIPT_PATH) as GDScript).get_script_constant_map().get("BAYS", []))
	if _obs != null and _obs.has_meta("open_bays"):
		skip.append_array(_obs.get_meta("open_bays"))
	var out: Array[int] = []
	for i in _bay_count:
		var bay := posmod(start + i, _bay_count)
		if not skip.has(bay):
			out.append(bay)
	return out

## Same frame as observatory.gd's shelf units: local +Z towards the centre of the hall.
static func _radial(angle: float, radius: float, y: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(-cos(angle), -sin(angle))), Vector3(cos(angle) * radius, y, sin(angle) * radius))


# --- Aiming, card and catalogue -------------------------------------------------

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _ui == null:
		return
	var hud_visible := _hud == null or bool(_hud.get("visible"))
	# In the multiverse corridor (scripts/multiverse.gd) there are no books to tap or aim at.
	# On a touch screen, it goes and comes back with the controls' help (touch_controls.gd).
	var tc := _obs.get_node_or_null("TouchControls") if _obs != null else null
	var help := not _touch or tc == null or not tc.has_method("help_shown") or bool(tc.call("help_shown"))
	# The live view's stream (artpass/foundation/live/live_rtx.gd _set_stream): the panels go, aiming stays.
	var s: Variant = get_tree().get("_stream")
	var streamed := s is bool and bool(s)
	_hint_panel.visible = hud_visible and not _overlay.visible and not _in_corridor() and help and not streamed
	# Under the controls panel, which grows a line where the touch controls wrap it.
	var hud_panel: Control = _hud.get_node_or_null("Panel") as Control if _hud != null else null
	if hud_panel != null:
		_hint_panel.position.y = maxf(86.0 * _ui_scale, hud_panel.get_global_rect().end.y + 8.0 * _ui_scale)
	_lang_panel.visible = hud_visible and not _overlay.visible and not streamed
	_layout_lang()
	_update_version()
	_update_kind()
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_crosshair.visible = hud_visible and captured and _active and not _overlay.visible
	if _touch:
		# Above the touch stick and buttons (scripts/touch_controls.gd, controls_top), which take
		# the bottom 0.31 of the screen's shorter side, more where the lean buttons stack.
		var screen := get_viewport().get_visible_rect().size
		var u := minf(screen.x, screen.y)
		var top := float(tc.call("controls_top")) if tc != null and tc.has_method("controls_top") else screen.y - 0.31 * u
		_card.offset_bottom = minf(top - screen.y, -0.31 * u) - 0.03 * u
		_card.offset_top = _card.offset_bottom
	var reading := _reading()  # every frame, so that a closed reader hides with the HUD off too
	var pick := -1
	if _aim_held and _hovered >= 0:
		pick = _hovered  # the walker reads its spine
	elif _active and hud_visible and not _overlay.visible and not reading:
		pick = _pick(captured, true)
	if pick != _hovered:
		_set_hover(pick)
	_glow_frame(_delta)


## The aimed book lit, as everything clickable is (scripts/aim_glow.gd): a shell a little larger than the book, round
## it where it slid out. The books are instances of one MultiMesh, which an overlay would light all at once.
func _glow_frame(delta: float) -> void:
	var on := _hovered >= 0 and _hovered < _books.size()
	_shell_amount = move_toward(_shell_amount, 1.0 if on else 0.0, delta * 6.0)
	if _shell == null:
		if not on:
			return
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		_shell = MeshInstance3D.new()
		_shell.name = "AimShell"
		_shell.mesh = box
		_shell.material_override = AIM_GLOW.make(0.0, 0.35)
		_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_shell)
	if on:
		var b: Dictionary = _books[_hovered]
		var xf: Transform3D = b.xf
		var slide: Vector3 = b.slide
		_shell.transform = Transform3D(xf.basis * Basis.from_scale(Vector3(1.08, 1.03, 1.08)), xf.origin + slide)
	_shell.visible = _shell_amount > 0.0
	(_shell.material_override as ShaderMaterial).set_shader_parameter("amount", _shell_amount)


## The book under the screen's centre, the pointer or the last tap. `keep`: the aimed book stays
## aimed while the ray passes within AIM_KEEP of it, so that its edge does not flicker.
func _pick(captured: bool, keep := false) -> int:
	var viewport := get_viewport()
	var cam := viewport.get_camera_3d()
	if cam == null:
		return -1
	var at := viewport.get_visible_rect().size * 0.5 if captured else viewport.get_mouse_position()
	if _touch:
		if _touch_point == Vector2.INF:
			return -1
		at = _touch_point
	return _ray_pick(cam.project_ray_origin(at), cam.project_ray_normal(at), keep)


## The course book a ray meets first within REACH; failing that, the nearest it passes within
## AIM_NEAR of, so that a ray between two spines or just over one still takes a book.
func _ray_pick(from: Vector3, dir: Vector3, keep: bool) -> int:
	if keep and _hovered >= 0 and _hovered < _books.size() and _ray_book(_hovered, from, dir, AIM_KEEP) >= 0.0:
		return _hovered
	var exact := book_on_ray(from, dir)
	if exact >= 0:
		return exact
	var best := -1
	var best_t := REACH
	for i in _books.size():
		var t := _ray_book(i, from, dir, AIM_NEAR)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = i
	return best


## The course book a ray meets first within REACH, exactly; -1 when none. For the walker too, which
## browses the shelf with the head tilted (scripts/walk_physics.gd).
func book_on_ray(from: Vector3, dir: Vector3) -> int:
	var best := -1
	var best_t := REACH
	for i in _books.size():
		var t := _ray_book(i, from, dir, 0.0)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = i
	return best


## Whether a ray passes within `grow` metres of book i (scripts/walk_physics.gd: browsing stays on
## the spines).
func ray_near_book(i: int, from: Vector3, dir: Vector3, grow: float) -> bool:
	return i >= 0 and i < _books.size() and _ray_book(i, from, dir, grow) >= 0.0


## Distance along the ray to book i's box grown by `grow` metres on every side, or -1.
func _ray_book(i: int, from: Vector3, dir: Vector3, grow: float) -> float:
	# The book's own frame, where it is the unit box; t stays in metres along the ray.
	var xf: Transform3D = _books[i].xf
	var inv := xf.affine_inverse()
	var half := Vector3(0.5, 0.5, 0.5)
	if grow > 0.0:
		half += Vector3(grow / xf.basis.x.length(), grow / xf.basis.y.length(), grow / xf.basis.z.length())
	return _ray_box(inv * from, inv.basis * dir, half)


## Distance along the ray to a centred box, or -1 when it misses (slab test).
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


func _set_hover(i: int) -> void:
	if _hovered >= 0 and _hovered < _books.size():
		_pose(_books[_hovered], false)
	_hovered = i
	_card.visible = i >= 0 and not _aim_held
	if i < 0:
		return
	var b: Dictionary = _books[i]
	_pose(b, true)
	var kicker := _in_lang(b.area.get("label", ""))
	if _group(b.course) != "":
		kicker += " › " + _group(b.course)
	_card_area.text = kicker.to_upper()
	_card_title.text = _in_lang(b.course.get("title", ""))
	var code := str(b.course.get("code", ""))
	_card_meta.text = code if code != "" else _count_text(b.course)
	_card_text.text = _in_lang(b.course.get("description", ""))
	_card_hint.text = _t("touch_open" if _touch else "open") + "\n" + _t("touch_read" if _touch else "read")


## For the walking body (scripts/walk_physics.gd), which tilts the head to read the aimed course
## book's spine: the title's centre and the direction it runs, in world space, and the spine's
## length; {} when no course book is aimed.
func aimed_spine() -> Dictionary:
	if _hovered < 0 or _hovered >= _books.size():
		return {}
	var b: Dictionary = _books[_hovered]
	var label := b.label as Label3D
	if label == null or not is_instance_valid(label) or not label.is_inside_tree():
		return {}
	var xf := label.global_transform
	return {"index": _hovered, "centre": xf.origin, "along": xf.basis.x.normalized(),
		"length": (global_transform.basis * (b.xf as Transform3D).basis.y).length(),
		"width": (global_transform.basis * (b.xf as Transform3D).basis.x).length()}


## The walker, reading, moves on to book i: it is aimed and stays so. Returns its spine.
func aim_book(i: int) -> Dictionary:
	if i < 0 or i >= _books.size():
		return {}
	if i != _hovered:
		_set_hover(i)
	return aimed_spine()


## The course book next to book i on its shelf, the side `toward` points to; -1 at the series' end.
func neighbour(i: int, toward: Vector3) -> int:
	if i < 0 or i >= _books.size():
		return -1
	var o: Vector3 = (_books[i].xf as Transform3D).origin
	var best := -1
	var best_d := INF
	for j in _books.size():
		if j == i or _books[j].mm != _books[i].mm:
			continue  # another bay: another series
		var d := ((_books[j].xf as Transform3D).origin - o).dot(toward)
		if d > 0.001 and d < best_d:
			best_d = d
			best = j
	return best


## While the walker reads the aimed book's spine, the book stays aimed whatever the pointer or the
## view does, and its card steps aside. Afterwards, on a touch screen, the aim is the screen's
## centre, where the view turned to the book.
func hold_aim(on: bool) -> void:
	_aim_held = on
	if _card != null:
		_card.visible = _hovered >= 0 and not on
	if not on and _touch and _hovered >= 0:
		_touch_point = get_viewport().get_visible_rect().size * 0.5
	if not on and not _pending_catalogue.is_empty():
		var pending := _pending_catalogue
		_pending_catalogue = {}
		_apply_catalogue(pending)


## An aimed book slides out of the row, its cloth a little lighter; back in place otherwise.
static func _pose(b: Dictionary, out: bool) -> void:
	var mm: MultiMesh = b.mm
	var xf: Transform3D = b.xf
	var label_xf: Transform3D = b.label_xf
	var offset: Vector3 = b.slide if out else Vector3.ZERO
	mm.set_instance_transform(b.index, Transform3D(xf.basis, xf.origin + offset))
	var col: Color = b.col
	var lift := 1.3 if out else 1.0
	mm.set_instance_color(b.index, Color(col.r * lift, col.g * lift, col.b * lift, col.a))
	(b.label as Label3D).transform = Transform3D(label_xf.basis, label_xf.origin + offset)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or _ui == null:
		return
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed):
		_active = true
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_L:
			_show_catalogue(not _overlay.visible)
			get_viewport().set_input_as_handled()
		elif code == KEY_T:
			cycle_lang()
			get_viewport().set_input_as_handled()
		elif code == KEY_F5:
			_fetch_live()
			get_viewport().set_input_as_handled()
		elif code == KEY_ESCAPE and _overlay.visible and Engine.get_process_frames() > _ignore_escape_until:
			_show_catalogue(false)  # not handled: the fly camera also releases the mouse
		elif (code == KEY_ENTER or code == KEY_KP_ENTER) and _hovered >= 0 and not _overlay.visible:
			open_course(_books[_hovered].course)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if lang_at((event as InputEventMouseButton).position) != "":
			return  # the selector's own click
		if _hovered >= 0 and not _overlay.visible:
			open_course(_books[_hovered].course)
			get_viewport().set_input_as_handled()


## Touch screens (scripts/touch_controls.gd): taps aim at books instead of the mouse, and the
## hints say so.
func set_touch(on: bool) -> void:
	_touch = on
	_touch_point = Vector2.INF
	if _ui != null:
		_fill_list()
		_layout_lang()


## A tap: on a book, it slides out and shows its card; on the same book again, it opens the
## course; anywhere else, the book goes back.
func tap(pos: Vector2) -> void:
	if _ui == null or _overlay.visible:
		return
	_active = true
	_touch_point = pos
	var pick := _pick(false)
	if pick >= 0 and pick == _hovered:
		open_course(_books[pick].course)
		_touch_point = Vector2.INF
	elif pick < 0:
		_touch_point = Vector2.INF
	elif _aim_held:
		_set_hover(pick)  # the walker reads its spine now (scripts/walk_physics.gd)


## A look drag puts the aimed book back: the tap that aimed it no longer points at it.
func release_aim() -> void:
	_touch_point = Vector2.INF


func toggle_catalogue() -> void:
	_show_catalogue(_overlay != null and not _overlay.visible)


func is_catalogue_open() -> bool:
	return _overlay != null and _overlay.visible


## Opens a course of the catalogue in the scene, as the courses pedestal's panels: the course's own, its area's and
## department's stacked behind it (the author, 2026-10-31: « un cours ouvert (un livre) je le veux dans la scène …
## de manière hiérarchique (panneaux décalés) »). A course the tree has not got yet opens in a new tab (the web
## build) or the browser (the desktop), as before.
func open_course(course: Dictionary) -> void:
	var url := _in_lang(course.get("url", {}))
	if not CatalogueRequest.relative_url(url):
		return
	last_opened = url
	_release_mouse()
	_show_catalogue(false)
	if _read_in_scene(course):
		course_opened.emit(url)
		return
	if OS.has_feature("web"):
		# The scene is served at <site>/demos/observatory/, so the course is two levels up.
		JavaScriptBridge.eval("window.open(new URL(%s, location.href).href, '_blank', 'noopener')" % JSON.stringify("../../" + url), true)
	elif not OS.get_cmdline_user_args().has("--no-open"):
		OS.shell_open(str(catalogue.get("site", "https://spareilleux.github.io/learn/")) + url)
	course_opened.emit(url)


## The panels of a course, opened on it between the camera and its book (or before the camera, from the catalogue).
## False when there is no tree, or no such course in it.
func _read_in_scene(course: Dictionary) -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null or not ResourceLoader.exists(READER_SCRIPT_PATH) or not FileAccess.file_exists(READER_TREE):
		return false
	if _reader == null or not is_instance_valid(_reader):
		_reader = load(READER_SCRIPT_PATH).new()
		_reader.name = "CourseReader"
		_reader.set("data_path", READER_TREE)
		add_child(_reader)
	var page := str(catalogue.get("site", "https://spareilleux.github.io/learn/")) + str(course.get("url", {}).get("en", ""))
	# Where it stands: towards the aimed book, else straight ahead; its panels at the camera's height.
	var ahead := -cam.global_basis.z
	for b: Dictionary in _books:
		if b.course == course:
			ahead = (b.xf as Transform3D).origin - cam.global_position
			break
	ahead.y = 0.0
	var far := ahead.length()
	if far < 0.01:
		ahead = Vector3.FORWARD
		far = READER_AT
	ahead /= far
	var foot := cam.global_position + ahead * clampf(far - 0.35, 0.6, READER_AT)
	foot.y = 0.0
	_reader.global_transform = Transform3D(Basis.looking_at(ahead), foot)
	_reader.set("top", cam.global_position.y - float(_reader.get("apex")) - float(_reader.get_script().get_script_constant_map().LIFT))
	_reader.visible = true
	var opened := bool(_reader.call("open_on", func(n: Dictionary) -> bool:
		return n.get("url") is Dictionary and str((n.url as Dictionary).get("en", "")) == page))
	if not opened:
		_reader.visible = false
	return opened


## An opened course's panels are showing: the books are not aimed at through them.
func _reading() -> bool:
	if _reader == null or not is_instance_valid(_reader):
		return false
	var shown := bool(_reader.get("_is_open")) or float(_reader.get("_open_t")) > 0.0
	# Closed, it hides, so that its pedestal's name and its click target go with it.
	_reader.visible = shown
	return shown


func _show_catalogue(show: bool) -> void:
	if _overlay == null or _overlay.visible == show:
		return
	if show:
		_release_mouse()
		_set_hover(-1)
	_overlay.visible = show


## Hands the mouse back the way Escape does, so the fly camera stops mouse look too.
func _release_mouse() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	_ignore_escape_until = Engine.get_process_frames() + 3
	for pressed in [true, false]:
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = pressed
		Input.parse_input_event(escape)


## Whether the visitor is in the multiverse corridor, which the scene adds next to its shelves.
func _in_corridor() -> bool:
	var n := get_parent()
	while n != null:
		var mv := n.get_node_or_null("Multiverse")
		if mv != null:
			return bool(mv.get("inside"))
		n = n.get_parent()
	return false


func _make_ui() -> void:
	var n: Node = get_parent()
	while n != null and n.get_node_or_null("ControlsHud") == null:
		n = n.get_parent()
	_hud = n.get_node_or_null("ControlsHud") if n != null else null
	if OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile"):
		var screen := get_viewport().get_visible_rect().size
		_ui_scale = clampf(minf(screen.x, screen.y) / 700.0, 1.0, 2.5)
	_ui = CanvasLayer.new()
	_ui.name = "CourseUI"
	_ui.layer = 5
	add_child(_ui)

	# Under the scene's controls panel (main.tscn's ControlsHud ends at y = 78).
	_hint_panel = PanelContainer.new()
	var hint_style := _panel_style(0.72)
	hint_style.set_content_margin_all(8)
	hint_style.content_margin_left = 12
	hint_style.content_margin_right = 12
	_hint_panel.add_theme_stylebox_override("panel", hint_style)
	_hint_panel.position = Vector2(16, 86 * _ui_scale)
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_hint_panel)
	_hint = _ui_label(_hint_panel, 15, GILT)
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF

	# The language selector, top right (under the touch controls' Courses button on a touch screen).
	_lang_panel = PanelContainer.new()
	_lang_panel.name = "LanguageSelector"
	var lang_style := _panel_style(0.72)
	lang_style.set_content_margin_all(6)
	_lang_panel.add_theme_stylebox_override("panel", lang_style)
	_lang_panel.anchor_left = 1.0
	_lang_panel.anchor_right = 1.0
	_lang_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_lang_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_lang_panel)
	var lang_col := VBoxContainer.new()
	lang_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lang_col.add_theme_constant_override("separation", 2)
	_lang_panel.add_child(lang_col)
	var lang_row := HBoxContainer.new()
	lang_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lang_row.add_theme_constant_override("separation", 4)
	lang_col.add_child(lang_row)
	_lang_label = _ui_label(lang_row, 13, Color(0.75, 0.72, 0.66))
	_lang_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_lang_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_lang_buttons(lang_row, true)
	# Under it, which version of the scene this is, when it was built and how old it is.
	_version_label = _ui_label(lang_col, 11, Color(0.62, 0.6, 0.54))
	_version_label.name = "Version"
	_version_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# And under that, which build: web or native, RTX, and the quality level (_update_kind).
	_kind_label = _ui_label(lang_col, 11, Color(0.86, 0.74, 0.46))
	_kind_label.name = "BuildKind"
	# Wrapped within the panel's width, never widening it: the touch help stops at this panel's left
	# edge, and a wider panel ("Versión nativa · Compatibility · calidad 0/5 (auto)") made it a line
	# taller, over the curio wheel's button on a phone held sideways (artpass/curios/curiotest.gd).
	_kind_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__obsBuild = %s" % JSON.stringify({"version": BuildInfo.VERSION, "built": BuildInfo.BUILT_UNIX}), true)

	_crosshair = ColorRect.new()
	(_crosshair as ColorRect).color = Color(1, 1, 1, 0.75)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -2
	_crosshair.offset_top = -2
	_crosshair.offset_right = 2
	_crosshair.offset_bottom = 2
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_crosshair)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", _panel_style(0.9))
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 1.0
	_card.anchor_bottom = 1.0
	var half_width := minf(340.0 * _ui_scale, get_viewport().get_visible_rect().size.x * 0.5 - 16.0)
	_card.offset_left = -half_width
	_card.offset_right = half_width
	_card.offset_top = -24
	_card.offset_bottom = -24
	_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	_ui.add_child(_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(box)
	_card_area = _ui_label(box, 12, GILT)
	_card_title = _ui_label(box, 22, Color(0.96, 0.93, 0.86))
	_card_meta = _ui_label(box, 14, Color(0.75, 0.72, 0.66))
	_card_text = _ui_label(box, 15, Color(0.88, 0.86, 0.8))
	_card_text.max_lines_visible = 4
	_card_hint = _ui_label(box, 13, GILT.darkened(0.15))

	_overlay = Control.new()
	_overlay.name = "Catalogue"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # the fly camera gets no clicks or motion behind it
	_overlay.visible = false
	_ui.add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(0.94))
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.07
	panel.anchor_bottom = 0.93
	_overlay.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	col.add_child(head)
	_overlay_title = _ui_label(head, 24, GILT)
	_overlay_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_lang_buttons(head, false)
	_refresh_button = Button.new()
	_refresh_button.name = "RefreshCatalogue"
	_refresh_button.focus_mode = Control.FOCUS_NONE
	_refresh_button.pressed.connect(_fetch_live)
	head.add_child(_refresh_button)
	_overlay_hint = _ui_label(col, 13, Color(0.75, 0.72, 0.66))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)


func _fill_list() -> void:
	if _list == null:
		return
	if _refresh_button != null:
		_refresh_button.text = {"en": "Refresh (F5)", "fr": "Actualiser (F5)", "es": "Actualizar (F5)"}.get(lang, "Refresh (F5)")
	var total := 0
	for area: Dictionary in catalogue.get("areas", []):
		total += (area.get("courses", []) as Array).size()
	_hint.text = _t("touch_hint") if _touch else _t("hint") % total
	_lang_label.text = _t("language")
	_lang_label.visible = not _touch
	_version_minute = -1
	_update_version()
	_sync_lang_buttons()
	_overlay_title.text = _t("title")
	_overlay_hint.text = _t("touch_close" if _touch else "close")
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for area: Dictionary in catalogue.get("areas", []):
		var heading := _ui_label(_list, 15, GILT)
		heading.text = _in_lang(area.get("label", "")).to_upper()
		var grid: GridContainer = null
		var group := ""
		for course: Dictionary in area.get("courses", []):
			if grid == null or _group(course) != group:
				group = _group(course)
				if group != "":
					var sub := _ui_label(_list, 13, GILT.darkened(0.2))
					sub.text = "    " + group
				grid = GridContainer.new()
				grid.columns = 2
				grid.add_theme_constant_override("h_separation", 12)
				grid.add_theme_constant_override("v_separation", 2)
				grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_list.add_child(grid)
			var button := Button.new()
			var code := str(course.get("code", ""))
			if code != "":
				button.text = "%s  ·  %s" % [code, _in_lang(course.get("title", ""))]
			else:
				button.text = "%s  —  %s" % [_in_lang(course.get("title", "")), _count_text(course)]
			button.flat = true
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.tooltip_text = _in_lang(course.get("description", ""))
			button.add_theme_font_size_override("font_size", roundi(15 * _ui_scale))
			button.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
			button.add_theme_color_override("font_hover_color", GILT.lightened(0.2))
			button.pressed.connect(open_course.bind(course))
			grid.add_child(button)


## EN, FR and ES buttons, the current one lit; hud: the on-screen selector, not the catalogue's.
func _add_lang_buttons(parent: Control, hud: bool) -> void:
	for code: String in LANGS:
		var button := Button.new()
		button.name = "Lang_" + code
		button.text = code.to_upper()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE  # Space and Enter stay the scene's
		button.add_theme_font_size_override("font_size", roundi(14 * _ui_scale))
		for state: String in ["font_color", "font_hover_color", "font_focus_color"]:
			button.add_theme_color_override(state, Color(0.8, 0.77, 0.7))
		for state: String in ["font_pressed_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(state, Color(0.08, 0.06, 0.04))
		button.add_theme_stylebox_override("normal", _lang_style(false, false))
		button.add_theme_stylebox_override("hover", _lang_style(false, true))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for state: String in ["pressed", "hover_pressed"]:
			button.add_theme_stylebox_override(state, _lang_style(true, false))
		button.custom_minimum_size = Vector2(40, 30) * _ui_scale
		button.pressed.connect(set_lang.bind(code))
		parent.add_child(button)
		_lang_buttons.append({"code": code, "button": button, "hud": hud})


func _sync_lang_buttons() -> void:
	for b: Dictionary in _lang_buttons:
		var button := b.button as Button
		button.set_pressed_no_signal(b.code == lang)
		button.visible = b.code in _langs()


## The on-screen selector: top right on a computer; on a touch screen under the Courses button of
## scripts/touch_controls.gd (whose layout is in fractions of the screen's shorter side u: margin
## 0.05 u, button 0.195 u by 0.0825 u), with buttons large enough for a thumb.
func _layout_lang() -> void:
	if _lang_panel == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var u := minf(screen.x, screen.y)
	var margin := 0.05 * u if _touch else 16.0
	_lang_panel.offset_right = -margin
	_lang_panel.offset_left = -margin
	_lang_panel.offset_top = 0.155 * u if _touch else 16.0
	_lang_panel.offset_bottom = _lang_panel.offset_top
	var size := Vector2(0.1 * u, 0.07 * u) if _touch else Vector2(40, 30) * _ui_scale
	var font := roundi(0.03 * u) if _touch else roundi(14 * _ui_scale)
	for b: Dictionary in _lang_buttons:
		if b.hud:
			var button := b.button as Button
			button.custom_minimum_size = size
			button.add_theme_font_size_override("font_size", font)


static func _lang_style(on: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GILT if on else Color(0.06, 0.05, 0.04, 0.0 if not hover else 0.6)
	style.border_color = GILT if on or hover else GILT.darkened(0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	return style


## The version line, redrawn when the minute or the language changes: "v17 · 2026-09-30 19:40 UTC-4
## · age 00:02:14", its age in days:hours:minutes by the viewer's clock.
func _update_version() -> void:
	if _version_label == null:
		return
	var now := int(Time.get_unix_time_from_system())
	if now / 60 == _version_minute:
		return
	_version_minute = now / 60
	_version_label.text = version_text(BuildInfo.VERSION, BuildInfo.BUILT_UNIX, now, Time.get_time_zone_from_system().get("bias", 0), _t("age"), _t("dev"))


## Under the version line, which build this is and at what quality: the web one (WebGL 2), which is
## the one the site publishes, or a native one, the author's RTX build with DLSS among them; then the
## level scripts/quality.gd has stepped to ("Peut on rendre ca plus evident dans la scene avec un
## label"). Redrawn only when one of those, or the language, changes.
func _update_kind() -> void:
	if _kind_label == null:
		return
	var q: Node = _obs.get_node_or_null("Quality") if _obs != null else null
	var level := int(q.get("level")) if q != null else -1
	var auto := true
	if q != null:
		auto = bool((q.get("stats") as Dictionary).get("auto", true))
	var dlss := int(get_viewport().scaling_3d_mode) == 6  # Viewport.SCALING_3D_MODE_DLSS in NVIDIA's fork
	var key := "%s|%d|%s|%s" % [lang, level, auto, dlss]
	if key == _kind_key:
		return
	_kind_key = key
	var text := ""
	if OS.has_feature("web"):
		text = _t("web")
	else:
		var method := RenderingServer.get_current_rendering_method()
		var renderer: String = {"forward_plus": "Forward+", "mobile": "Mobile", "gl_compatibility": "Compatibility"}.get(method, method)
		text = (_t("rtx") if Engine.has_singleton("Streamline") else _t("native")) % renderer
		if dlss:
			text += " · DLSS"
	if level >= 0:
		text += " · " + _t("quality") % [level, _t("auto") if auto else _t("fixed")]
	_kind_label.text = text


## The version line for a build (see _update_version); bias is the viewer's offset from UTC in
## minutes, which the build's time is shown in.
static func version_text(version: int, built: int, now: int, bias: int, age_word: String, dev_word: String) -> String:
	if version <= 0 or built <= 0:
		return dev_word
	var d := Time.get_datetime_dict_from_unix_time(built + bias * 60)
	var zone := "UTC"
	if bias != 0:
		zone += ("+" if bias > 0 else "-") + str(absi(bias) / 60)
		if absi(bias) % 60 != 0:
			zone += ":%02d" % (absi(bias) % 60)
	var age := maxi(now - built, 0) / 60
	return "v%d · %04d-%02d-%02d %02d:%02d %s · %s %02d:%02d:%02d" % [version, d.year, d.month, d.day, d.hour, d.minute, zone,
		age_word, age / 1440, (age / 60) % 24, age % 60]


func _ui_label(parent: Control, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", roundi(size * _ui_scale))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


static func _panel_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, alpha)
	style.border_color = GILT.darkened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	return style
