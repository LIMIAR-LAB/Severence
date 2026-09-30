extends SceneTree

class RecordingHUD extends "res://scripts/combat_hud.gd":
	var captions: Array[String] = []
	func text(_p: Vector2, value: String, _size: int = 15, _color: Color = Color("e8dfba")) -> void:
		captions.append(value)

var failures := 0

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var backups: Dictionary = {}
	for path in ["user://settings.json", "user://progress.json"]:
		backups[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	app.set_physics_process(false)
	app.sim.set_unlocks(["padrao", "omega", "azul"])
	app.menu.read_equipment(); app.menu.show_screen("equipment")
	var eq = app.menu.equipment
	eq.show_tab(2)
	var blue_card = eq.find_child("ArmadurasCard_azul", true, false)
	check(blue_card != null, "segunda transformação tem card selecionável")
	blue_card.pressed.emit()
	check(app.selected_armor() == "azul", "seleção pelo card equipa a Forma Azul")
	app.save_progress()
	app.sim.inventory_state = app.InventoryState.defaults()
	app.load_progress()
	app.menu.read_equipment()
	check(app.menu.armor_choice == "azul", "seleção salva retorna ao reabrir equipamento no título")
	app.start_single()
	check(app.sim.actors[0].armor_type == "azul", "iniciar partida respeita a transformação selecionada")
	app.sim.start_run(1941); app.apply_preferences(0)
	app.menu.read_equipment(); app.menu.show_screen("mission_inventory")
	check(app.menu.armor_choice == "azul", "inventário da missão mostra a forma do ator")
	app.menu.equipment.show_tab(4)
	check(app.menu.equipment.find_child("OmegaReference_2", true, false).text == "64 de dano", "atributos descrevem a garra equipada")
	app.sim.set_armor(app.sim.actors[0], true)
	app.sim.actors[0].claw_cd = 0.8
	var hud := RecordingHUD.new(); hud.app = app; root.add_child(hud)
	hud.queue_redraw()
	await process_frame; await process_frame
	check(hud.captions.has("FORMA AZUL") and hud.captions.has("GARRA • 0.8s"), "HUD mostra a forma e recarga real da garra")
	check(not hud.captions.has("ARMADURA ÔMEGA"), "HUD não confunde as duas transformações")
	app.menu.equipment.pick("omega")
	check(app.sim.actors[0].armor_type == "azul" and app.selected_armor() == "azul", "troca recusada durante forma ativa preserva ator e seleção salva")
	app.sim.inventory_state = {"version": 1, "capacity": 1, "stacks": {"kit_reparo": 1}, "equipped": {}}
	app.save_progress(); app.load_progress()
	var migrated = app.InventoryState.new(app.sim.inventory_state)
	check(migrated.quantity("forma_azul") == 1 and migrated.quantity("kit_reparo") == 1, "perfil antigo cheio recebe a forma sem perder seus itens")
	await preload("res://tests/support/scene_cleanup.gd").finish(self)
	for path in backups:
		if backups[path] == null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE); file.store_buffer(backups[path]); file.close()
	print("BLUE_FORM_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
