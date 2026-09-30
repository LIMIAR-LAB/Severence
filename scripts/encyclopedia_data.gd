extends RefCounted

const PATH := "res://data/enciclopedia.json"
const CATEGORIES := ["monstros", "itens", "robos"]
const CATEGORY_LABELS := {"monstros": "MONSTROS", "itens": "ITENS", "robos": "ROBÔS"}
static var _cache: Array = []
static var _loaded := false

static func entries() -> Array:
	if not _loaded:
		_loaded = true
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_cache = valid_entries(parsed.get("entradas", []) if parsed is Dictionary else [])
	return _cache

static func reload() -> void:
	_loaded = false
	_cache.clear()

static func valid_entries(raw) -> Array:
	if not raw is Array: return []
	var clean: Array = []
	var ids := {}
	for value in raw:
		if not value is Dictionary: continue
		if not value.get("id", "") is String or not value.get("categoria", "") is String: continue
		if not value.get("nome", "") is String or not value.get("descricao", "") is String: continue
		if not value.get("subtitulo", "") is String: continue
		var id: String = value.get("id", "").strip_edges()
		var category: String = value.get("categoria", "").strip_edges()
		var entry_name: String = value.get("nome", "").strip_edges()
		var description: String = value.get("descricao", "").strip_edges()
		if id.is_empty() or not id.is_valid_identifier() or ids.has(id) or category not in CATEGORIES or entry_name.is_empty() or description.is_empty(): continue
		var image: Variant = value.get("imagem", "")
		var traits: Variant = value.get("tracos", [])
		var order_value: Variant = value.get("ordem", 0)
		if not image is String or not traits is Array or (not order_value is int and not order_value is float): continue
		var normalized_traits: Array[String] = []
		var traits_valid := true
		for feature_text in traits:
			if not feature_text is String or feature_text.strip_edges().is_empty(): traits_valid = false; break
			normalized_traits.append(feature_text.strip_edges())
		if not traits_valid: continue
		ids[id] = true
		clean.append({
			"id": id, "categoria": category, "nome": entry_name,
			"subtitulo": str(value.get("subtitulo", "")).strip_edges(),
			"descricao": description, "imagem": image.strip_edges(),
			"tracos": normalized_traits, "ordem": int(order_value)
		})
	clean.sort_custom(func(a: Dictionary, b: Dictionary):
		if a.categoria != b.categoria: return CATEGORIES.find(a.categoria) < CATEGORIES.find(b.categoria)
		if a.ordem != b.ordem: return a.ordem < b.ordem
		var by_name: int = a.nome.naturalnocasecmp_to(b.nome)
		return by_name < 0 if by_name != 0 else a.id < b.id)
	return clean

static func by_category(category: String) -> Array:
	if category not in CATEGORIES: return []
	return entries().filter(func(entry: Dictionary): return entry.categoria == category)

static func item(id: String) -> Dictionary:
	for entry in entries():
		if entry.id == id: return entry
	return {}

static func image_path(entry: Dictionary) -> String:
	var path := str(entry.get("imagem", ""))
	if path.is_empty() or not ResourceLoader.exists(path): return ""
	var resource = load(path)
	return path if resource is Texture2D else ""
