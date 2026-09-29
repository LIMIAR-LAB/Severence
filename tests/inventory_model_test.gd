extends SceneTree

const Catalog := preload("res://scripts/inventory_data.gd")
const Inventory := preload("res://scripts/inventory_state.gd")
var failures := 0

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _init() -> void:
	var ids: Dictionary = {}
	for item in Catalog.valid_items():
		check(not ids.has(item.id), "id estável e único: " + item.id)
		ids[item.id] = true
	check(Catalog.valid_items().size() >= 9, "catálogo inicial possui categorias e item especial")
	var state := Inventory.new({"capacity": 2, "stacks": {"kit_reparo": 7}, "selected_id": "kit_reparo"})
	check(state.add("kit_reparo") and state.quantity("kit_reparo") == 8, "empilha até o limite")
	check(not state.add("kit_reparo") and state.last_error == "Pilha no limite.", "rejeita pilha acima do limite")
	check(state.add("arma_blaster") and not state.add("sucata_temporal") and state.last_error == "Inventário cheio.", "capacidade conta pilhas sem mutação parcial")
	check(not state.add("desconhecido") and state.quantity("desconhecido") == 0, "item desconhecido degrada com segurança")
	check(state.remove("kit_reparo", 8) and not state.stacks.has("kit_reparo"), "remove pilha completa")
	check(not state.remove("kit_reparo") and state.last_error == "Quantidade indisponível.", "remoção inválida é segura")
	var full := Inventory.new()
	check(full.set_filter("armas") and full.visible_items({}).all(func(item): return item.categoria == "armas"), "filtro de armas")
	check(not full.set_filter("inexistente") and full.filter == "armas", "filtro inválido não altera estado")
	var ordered := full.visible_items({})
	var sorted_again := ordered.duplicate(); sorted_again.sort_custom(Catalog.compare)
	check(ordered.size() >= 1 and ordered == sorted_again, "ordenação determinística")
	check(full.equip("arma_blaster", {"padrao": true}) and full.equipped_in("uniforme") == "arma_blaster", "equipa combinação válida")
	check(not full.equip("kit_reparo", {}) and full.last_error.contains("utilizável"), "protótipo não cria efeito falso")
	check(full.unequip("uniforme") and full.equipped_in("uniforme") == "", "desequipa slot válido")
	var migrated := Inventory.new({"version": 0, "capacity": -5, "stacks": {"desconhecido": 99, "kit_reparo": 999}, "filter": "ruim"})
	check(migrated.capacity == 1 and migrated.quantity("kit_reparo") == 8 and not migrated.stacks.has("desconhecido") and migrated.filter == "todos", "migração sanitiza dados inválidos")
	print("INVENTORY_MODEL_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)

