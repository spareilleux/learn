extends HTTPRequest
## JSON data only. Neither URLs supplied by the catalogue nor executable resources are fetched.
signal catalogue_ready(data: Dictionary)
signal refresh_finished(status: String)

const SITE := "https://spareilleux.github.io/learn/"
const PUBLIC_URL := SITE + "demos/observatory/courses.json"
const CACHE := "user://observatory-catalogue.json"
const MAX_BYTES := 2097152
const MAX_COURSES := 2048
var busy := false
var last_status := "embedded"
var cache_saved := false

func _init() -> void:
	timeout = 10.0
	body_size_limit = MAX_BYTES
	max_redirects = 0
	request_completed.connect(_completed)

func refresh(url: String = PUBLIC_URL, web: bool = false) -> Error:
	if busy:
		return ERR_BUSY
	# Browser fetch already decompresses; the native HTTPClient must do it itself.
	accept_gzip = not web
	# In the browser, the hall's first frames are built while this runs and can outlast any timeout (version 50
	# in headless Chrome: RESULT_TIMEOUT, the embedded list kept); the browser ends a dead fetch itself.
	if web:
		timeout = 0.0
	busy = true
	last_status = "loading"
	var error := request(url)
	if error != OK:
		busy = false
		last_status = "unavailable"
		refresh_finished.emit(last_status)
	return error

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_finish("unavailable")
		return
	var data := decode(body)
	if data.is_empty():
		_finish("invalid")
		return
	# Keep the current in-memory catalogue if disk is unavailable. The embedded copy remains intact.
	if not OS.has_feature("web"):
		cache_saved = save_cache(data)
	catalogue_ready.emit(data)
	_finish("current")

func _finish(status: String) -> void:
	last_status = status
	refresh_finished.emit(status)

static func relative_url(value: Variant) -> bool:
	if not value is String or value.length() > 300 or not value.ends_with("/"):
		return false
	var pattern := RegEx.new()
	pattern.compile("^[a-z0-9][a-z0-9/_-]*/$")
	return pattern.search(value) != null and not value.contains("//")

static func _localized(value: Variant, limit: int, required: bool = false) -> bool:
	if not value is Dictionary or value.size() > 3:
		return false
	if required and (not value.get("en") is String or value.en.is_empty()):
		return false
	for key: Variant in value:
		if key not in ["en", "fr", "es"] or not value[key] is String or value[key].length() > limit:
			return false
	return true

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("site") != SITE:
		return false
	var locales: Variant = data.get("locales")
	if not locales is Array or locales.is_empty() or locales.size() > 3 or "en" not in locales:
		return false
	var seen_locales := {}
	for locale: Variant in locales:
		if locale not in ["en", "fr", "es"] or seen_locales.has(locale):
			return false
		seen_locales[locale] = true
	var areas: Variant = data.get("areas")
	if not areas is Array or areas.is_empty() or areas.size() > 32:
		return false
	var ids := {}
	for area: Variant in areas:
		if not area is Dictionary or not _localized(area.get("label"), 512, true) or not area.get("courses") is Array:
			return false
		for course: Variant in area.courses:
			if not course is Dictionary or not course.get("id") is String:
				return false
			var id: String = course.id
			if id.is_empty() or id.length() > 200 or ids.has(id):
				return false
			ids[id] = true
			if ids.size() > MAX_COURSES or not _localized(course.get("title"), 512, true):
				return false
			if not _localized(course.get("description", {}), 4096):
				return false
			for field: String in ["spine", "group"]:
				if course.has(field) and not _localized(course[field], 512):
					return false
			if course.get("unit", "lessons") not in ["lessons", "pages"] or not course.get("code", "") is String or str(course.get("code", "")).length() > 80:
				return false
			var urls: Variant = course.get("url")
			if not urls is Dictionary or urls.size() > 3 or not relative_url(urls.get("en")):
				return false
			for locale: Variant in urls:
				if locale not in ["en", "fr", "es"] or not relative_url(urls[locale]):
					return false
			var lessons: Variant = course.get("lessons")
			if not lessons is Dictionary or lessons.size() > 3:
				return false
			for locale: Variant in lessons:
				var count: Variant = lessons[locale]
				if locale not in ["en", "fr", "es"] or not (count is float or count is int):
					return false
				if not is_finite(float(count)) or count < 0 or count > 100000 or float(count) != floor(float(count)):
					return false
	return not ids.is_empty()

static func decode(body: PackedByteArray) -> Dictionary:
	if body.is_empty() or body.size() > MAX_BYTES:
		return {}
	var parser := JSON.new()
	if parser.parse(body.get_string_from_utf8()) != OK or not valid(parser.data):
		return {}
	return parser.data

static func load_cache() -> Dictionary:
	var file := FileAccess.open(CACHE, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {}
	return decode(file.get_buffer(file.get_length()))

static func save_cache(data: Dictionary) -> bool:
	if not valid(data):
		return false
	var body := JSON.stringify(data).to_utf8_buffer()
	if body.size() > MAX_BYTES:
		return false
	var file := FileAccess.open(CACHE + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(body)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(CACHE + ".tmp", CACHE) == OK
