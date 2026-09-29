extends RefCounted

const Catalog := preload("res://scripts/inventory_data.gd")
const VERSION := 1

var capacity := Catalog.capacity()
var stacks: Dictionary = {}
var selected_id := ""
var filter := "todos"
var equipped: Dictionary = {"uniforme": "arma_blaster", "robo": "", "armadura": ""}
var last_error := ""

func _init(raw: Dictionary = {}) -> void:
	from_dict(raw)

static func defaults() -> Dictionary:
	return {"version": VERSION, "capacity": Catalog.capacity(), "stacks": {"arma_blaster": 1, "kit_reparo": 2, "sucata_temporal": 5, "chave_fenda_do_marty": 1}, "selected_id": "arma_blaster", "filter": "todos", "equipped": {"uniforme": "arma_blaster", "robo": "", "armadura": ""}}

func from_dict(raw: Dictionary) -> void:
	var source := raw if not raw.is_empty() else defaults()
	var raw_capacity = source.get("capacity", Catalog.capacity())
	capacity = clampi(int(raw_capacity), 1, 120) if raw_capacity is int or raw_capacity is float else Catalog.capacity()
	stacks.clear()
	var incoming = source.get("stacks", {})
	if incoming is Dictionary:
		for raw_id in incoming:
			var id := str(raw_id); var entry := Catalog.item(id)
			if entry.is_empty() or not Catalog.is_valid(entry): continue
			var raw_amount = incoming[raw_id]
			if not raw_amount is int and not raw_amount is float: continue
			var amount := clampi(int(raw_amount), 0, int(entry.max_pilha))
			if amount > 0 and stacks.size() < capacity: stacks[id] = amount
	filter = str(source.get("filter", "todos"))
	if filter not in Catalog.CATEGORIES: filter = "todos"
	selected_id = str(source.get("selected_id", ""))
	if not stacks.has(selected_id): selected_id = first_id()
	equipped = {"uniforme": "", "robo": "", "armadura": ""}
	var raw_equipped = source.get("equipped", {})
	if raw_equipped is Dictionary:
		for slot in equipped:
			var id := str(raw_equipped.get(slot, ""))
			var entry := Catalog.item(id)
			if id != "" and stacks.has(id) and entry.get("slot", "") == slot: equipped[slot] = id
	last_error = ""

func to_dict() -> Dictionary:
	return {"version": VERSION, "capacity": capacity, "stacks": stacks.duplicate(), "selected_id": selected_id, "filter": filter, "equipped": equipped.duplicate()}

func first_id() -> String:
	var list := visible_items({})
	return str(list[0].id) if not list.is_empty() else ""

func quantity(id: String) -> int:
	return int(stacks.get(id, 0))

func used_slots() -> int:
	return stacks.size()

func add(id: String, amount: int = 1) -> bool:
	last_error = ""
	var entry := Catalog.item(id)
	if entry.is_empty() or not Catalog.is_valid(entry): last_error = "Item desconhecido."; return false
	if amount <= 0: last_error = "Quantidade inválida."; return false
	var current := quantity(id); var limit := int(entry.max_pilha)
	if current == 0 and used_slots() >= capacity: last_error = "Inventário cheio."; return false
	if current + amount > limit: last_error = "Pilha no limite."; return false
	stacks[id] = current + amount
	if selected_id == "": selected_id = id
	return true

func remove(id: String, amount: int = 1) -> bool:
	last_error = ""
	if amount <= 0 or quantity(id) < amount: last_error = "Quantidade indisponível."; return false
	stacks[id] = quantity(id) - amount
	if stacks[id] <= 0:
		stacks.erase(id)
		for slot in equipped:
			if equipped[slot] == id: equipped[slot] = ""
		if selected_id == id: selected_id = first_id()
	return true

func set_filter(value: String) -> bool:
	if value not in Catalog.CATEGORIES: last_error = "Filtro inválido."; return false
	filter = value; last_error = ""
	var list := visible_items({})
	if not list.any(func(entry): return entry.id == selected_id): selected_id = str(list[0].id) if not list.is_empty() else ""
	return true

func visible_items(unlocks: Dictionary) -> Array:
	var list: Array = []
	for id in stacks:
		var entry := Catalog.item(str(id))
		if entry.is_empty(): continue
		if filter == "todos" or entry.categoria == filter: list.append(entry)
	list.sort_custom(Catalog.compare)
	return list

func equip(id: String, unlocks: Dictionary) -> bool:
	last_error = ""
	var entry := Catalog.item(id)
	if entry.is_empty() or not stacks.has(id): last_error = "Item não possuído."; return false
	if entry.get("prototipo", false) == true or entry.get("equipavel", false) != true: last_error = "Item ainda não utilizável."; return false
	if not Catalog.unlocked(entry, unlocks): last_error = "Item bloqueado."; return false
	var slot := str(entry.get("slot", ""))
	if slot not in equipped: last_error = "Slot incompatível."; return false
	equipped[slot] = id; selected_id = id
	return true

func unequip(slot: String) -> bool:
	if slot not in equipped: last_error = "Slot inválido."; return false
	equipped[slot] = ""; last_error = ""; return true

func equipped_in(slot: String) -> String:
	return str(equipped.get(slot, ""))

