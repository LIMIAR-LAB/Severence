extends SceneTree

const Inventory := preload("res://scripts/inventory_state.gd")
var failures := 0
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var sim := Expedition.new()
	var inv := Inventory.new(); inv.add("fragmento_cronal", 6); inv.equip("arma_blaster", {"padrao": true})
	sim.inventory_state = inv.to_dict()
	var snapshot := sim.snapshot()
	var loaded := Expedition.new(); loaded.apply_snapshot(snapshot)
	check(loaded.inventory_state.stacks.get("fragmento_cronal", 0) == 6, "inventário persiste no snapshot")
	check(loaded.inventory_state.equipped.uniforme == "arma_blaster", "loadout do inventário persiste")
	var legacy := snapshot.duplicate(); legacy.erase("inventory_state"); legacy["campo_futuro"] = "ignorar"; legacy.unlocked = {"padrao": true}
	loaded.apply_snapshot(legacy)
	check(loaded.inventory_state is Dictionary and loaded.inventory_state.has("stacks"), "snapshot antigo recebe default seguro")
	check(loaded.is_unlocked("omega"), "snapshot antigo recebe a Ômega como desbloqueio inicial")
	check(not loaded.is_unlocked("titan") and not loaded.is_unlocked("spectre"), "migração da Ômega preserva os outros bloqueios do snapshot")
	var bad := snapshot.duplicate(); bad.inventory_state = {"capacity": 2, "stacks": {"desconhecido": 4, "kit_reparo": 999}}
	loaded.apply_snapshot(bad)
	check(not loaded.inventory_state.stacks.has("desconhecido") and loaded.inventory_state.stacks.kit_reparo == 8, "save inválido é sanitizado")
	var locked := Expedition.new(); locked.set_unlocks(["padrao"])
	check(locked.equip(0, "padrao", "", "omega") and locked.inventory_state.equipped.armadura == "", "loadout não registra armadura bloqueada como equipada")
	var full := Expedition.new(); full.set_unlocks(["padrao", "mecanico"])
	full.inventory_state = {"version": 1, "capacity": 1, "stacks": {"kit_reparo": 1}, "selected_id": "kit_reparo", "filter": "todos", "equipped": {}}
	var previous_outfit: String = full.actors[0].outfit
	check(not full.equip(0, "mecanico", "") and full.actors[0].outfit == previous_outfit, "inventário cheio rejeita loadout atomicamente")
	var team := Expedition.new(); team.set_unlocks(["padrao", "mecanico", "titan", "spectre"])
	var host_equipped: Dictionary = team.inventory_state.duplicate(true)
	check(team.equip(1, "mecanico", "spectre") and team.inventory_state == host_equipped, "loadout do P2 não sobrescreve inventário persistente do host")
	# Migração pelo arquivo real: versão 1 sem inventário e sem a cópia redundante de Spectres no topo.
	var path := "user://expedition.save"; var had_save := FileAccess.file_exists(path)
	var original := FileAccess.get_file_as_bytes(path) if had_save else PackedByteArray()
	var legacy_state := sim.snapshot(); legacy_state.erase("inventory_state")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var({"version": 1, "state": legacy_state, "rng_state": sim.rng.state, "coop": "solo"}); file.close()
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app); await process_frame
	check(app.load_game() and app.sim.spectres.size() == 2, "arquivo v1 real migra sem apagar Spectres")
	check(app.sim.inventory_state.has("stacks") and app.sim.inventory_state.stacks.has("arma_blaster"), "arquivo v1 recebe inventário padrão")
	var invalid_state := legacy_state.duplicate(true); invalid_state.actors = [{}, {}]
	file = FileAccess.open(path, FileAccess.WRITE); file.store_var({"version": 2, "state": invalid_state}); file.close()
	check(not app.load_game(), "save com atores malformados é rejeitado antes de aplicar")
	app.queue_free(); await process_frame
	if had_save:
		var restore := FileAccess.open(path, FileAccess.WRITE); restore.store_buffer(original); restore.close()
	else: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("INVENTORY_PERSISTENCE_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)

