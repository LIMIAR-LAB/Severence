extends RefCounted
# 0.17: dados da tela de EQUIPAMENTO (data/equipamento.json) — nomes, descrições, atributos, raridade,
# ícones, cards e regra de desbloqueio de cada item. A tela e a simulação leem tudo daqui.
# Uso: const EquipmentData := preload("res://scripts/equipment_data.gd")  (sem class_name: não depende do cache)

const PATH := "res://data/equipamento.json"
const SEGMENTS := 12
static var _cache: Dictionary = {}

static func data() -> Dictionary:
	if _cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_cache = parsed if parsed is Dictionary else {"stats": [], "itens": []}
	return _cache

static func items() -> Array:
	return data().get("itens", [])

static func stats() -> Array:
	return data().get("stats", [])

static func item(id: String) -> Dictionary:
	for it in items():
		if it.id == id: return it
	return {}

static func by_category(category: String) -> Array:
	return items().filter(func(it): return it.categoria == category)

static func starting_unlocks() -> Array:
	return items().filter(func(it): return it.get("desbloqueado_no_inicio", false)).map(func(it): return it.id)

# Modificador de armadura/robô: "+N" soma, "=N" substitui, "xN" multiplica. Número puro substitui.
static func apply_mod(value: float, mod) -> float:
	if mod is float or mod is int: return float(mod)
	var s := str(mod).strip_edges()
	if s.is_empty(): return value
	var n := s.substr(1).to_float()
	match s[0]:
		"+": return value + n
		"-": return value - n
		"=": return n
		"x", "*": return value * n
	return s.to_float()

# Valores dos 6 atributos para a combinação uniforme + robô + armadura ("" = nenhum).
# Retorna {"base": {stat: valor do uniforme}, "final": {stat: valor com tudo}}.
static func combine(outfit: String, armor: String, robot: String) -> Dictionary:
	var base: Dictionary = {}
	var uni: Dictionary = item(outfit).get("atributos", {})
	for st in stats(): base[st.id] = float(uni.get(st.id, 0))
	var final := base.duplicate()
	for extra in [robot, armor]:   # ordem: uniforme -> robô -> armadura
		if extra == "": continue
		var mods: Dictionary = item(extra).get("atributos", {})
		for k in mods: final[k] = apply_mod(float(final.get(k, 0)), mods[k])
	return {"base": base, "final": final}

# Quantos dos 12 segmentos da barra acendem para um valor.
static func segments(stat: String, value: float) -> int:
	var f := 0.0
	match stat:
		"vida": f = value / SEGMENTS
		"defesa": f = (value + 20.0) / 60.0
		"dash": f = 0.3 / maxf(value, 0.01)
		_:
			var mx := 100.0
			for st in stats():
				if st.id == stat: mx = float(st.get("max", 100))
			f = value / mx
	return clampi(roundi(f * SEGMENTS), 0, SEGMENTS)

static func format(stat: String, value: float) -> String:
	match stat:
		"defesa": return "%+d%%" % roundi(value)
		"dash": return "%.2fs" % value
	return str(roundi(value))
