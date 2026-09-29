extends RefCounted

const PATH := "res://data/inventario.json"
const CATEGORIES := ["todos", "armas", "pecas", "consumiveis", "recursos"]
const RARITY_ORDER := {"lendario": 0, "especial": 1, "raro": 2, "incomum": 3, "comum": 4}
static var _cache: Dictionary = {}

static func data() -> Dictionary:
	if _cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary and parsed.get("itens") is Array and (parsed.get("capacidade_padrao") is int or parsed.get("capacidade_padrao") is float): _cache = parsed
		else: _cache = {"versao": 1, "capacidade_padrao": 24, "itens": []}
	return _cache

static func items() -> Array:
	var value = data().get("itens", [])
	return value if value is Array else []

static func item(id: String) -> Dictionary:
	for entry in items():
		if entry is Dictionary and str(entry.get("id", "")) == id: return entry
	return {}

static func capacity() -> int:
	return maxi(1, int(data().get("capacidade_padrao", 24)))

static func is_valid(entry: Dictionary) -> bool:
	if str(entry.get("id", "")).is_empty() or str(entry.get("nome", "")).is_empty(): return false
	if str(entry.get("categoria", "")) not in CATEGORIES or entry.get("categoria") == "todos": return false
	var raw_max = entry.get("max_pilha", 0)
	if not raw_max is int and not raw_max is float: return false
	var max_stack := int(raw_max)
	return max_stack > 0 and (entry.get("empilhavel", false) == true or max_stack == 1)

static func valid_items() -> Array:
	return items().filter(func(entry): return entry is Dictionary and is_valid(entry))

static func unlocked(entry: Dictionary, unlocks: Dictionary) -> bool:
	if entry.get("desbloqueado", false) == true: return true
	var requirement := str(entry.get("desbloqueio_id", ""))
	return not requirement.is_empty() and unlocks.get(requirement, false) == true

static func compare(a: Dictionary, b: Dictionary) -> bool:
	var ar := int(RARITY_ORDER.get(a.get("raridade", "comum"), 9))
	var br := int(RARITY_ORDER.get(b.get("raridade", "comum"), 9))
	if ar != br: return ar < br
	var an := str(a.get("nome", "")).naturalnocasecmp_to(str(b.get("nome", "")))
	return an < 0 if an != 0 else str(a.get("id", "")) < str(b.get("id", ""))

