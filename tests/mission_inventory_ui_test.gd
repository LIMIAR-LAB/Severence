extends SceneTree

var failures := 0
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app); await process_frame
	app.sim.set_unlocks(["padrao", "titan", "spectre", "omega"])
	app.sim.materials = 5
	app.start_single(); app.sim.start_run(1941)
	app.sim.keys = 3; app.sim.money = 47; app.sim.materials = 8
	app.sim.mech.fuel = app.sim.FUEL_MAX * 0.62; app.sim.spectres[0].hp = 71
	var persistent_before: Dictionary = app.sim.inventory_state.duplicate(true)
	app.menu.open("pause"); await process_frame
	var open_button: Button = app.menu.content.find_child("MissionInventory", true, false)
	check(open_button != null and app.menu.screen == "pause" and app.paused, "pausa oferece inventário sem retomar a missão")
	open_button.pressed.emit(); await process_frame; await process_frame
	var eq = app.menu.equipment
	check(app.menu.screen == "mission_inventory" and eq != null and eq.mission_mode, "abre shell no modo missão")
	check(eq.find_child("InventorySlot_missao_chaves", true, false) is Button, "chaves coletadas aparecem na grade")
	check(eq.find_child("InventorySlot_missao_moedas", true, false) is Button, "moedas coletadas aparecem na grade")
	check(eq.find_child("InventorySlot_prototipo_reparo", true, false) == null, "item persistente não levado fica fora da missão")
	check(eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_fragmentos")) == 3, "fragmentos contam somente o ganho desta missão")
	check(eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_combustivel")) == 62, "combustível usa valor vivo quando Titan foi levado")
	check(eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_energia")) == 0, "energia só aparece quando Spectre foi levado")
	check(app.sim.inventory_state == persistent_before, "recursos da tentativa não entram no inventário persistente")
	var transient_button: Button = eq.find_child("InventorySlot_missao_chaves", true, false); transient_button.grab_focus(); await process_frame
	check(transient_button.has_focus() and transient_button.get_theme_stylebox("focus") is StyleBoxFlat, "recurso da missão possui foco visível")
	eq.select_inventory("missao_chaves")
	check(eq.detail_action.disabled and "temporário" in eq.detail_reason.text and "provisório" in eq.detail_reason.text, "recurso temporário identifica ícone provisório e não oferece ação falsa")
	app.sim.keys = 9; await process_frame; await process_frame
	check(eq.find_child("InventorySlot_missao_chaves", true, false) != null and eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_chaves")) == 9, "quantidades mudam ao vivo sem reabrir a tela")
	eq.go_back(); await process_frame
	check(app.menu.screen == "pause" and app.menu.visible and app.paused, "voltar retorna à pausa sem retomar")
	app.queue_free(); await process_frame
	print("MISSION_INVENTORY_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)

