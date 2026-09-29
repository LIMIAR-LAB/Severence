extends SceneTree

var failures := 0
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	app.sim.set_unlocks(["padrao"]); app.menu.read_equipment(); app.menu.show_screen("equipment")
	await process_frame; await process_frame
	var eq = app.menu.equipment
	check(eq.active_tab == 0 and eq.tabs.size() == 5, "Inventário abre por padrão com cinco abas")
	for i in 5: check(eq.find_child("MenuTab_%d" % i, true, false) is Button, "aba %d é interativa" % i)
	check(eq.find_child("Filter_todos", true, false) is Button and eq.find_child("Filter_recursos", true, false) is Button, "filtros completos")
	check(eq.find_child("InventorySlot_arma_blaster", true, false) is Button, "grade possui item real")
	var blaster_slot: Button = eq.find_child("InventorySlot_arma_blaster", true, false)
	blaster_slot.grab_focus(); await process_frame
	check(blaster_slot.has_focus() and blaster_slot.get_theme_stylebox("focus") is StyleBoxFlat, "slot possui foco visível para teclado/controle")
	check(eq.detail_title.text == "BLASTER" and not eq.detail_action.disabled, "seleção alimenta detalhes e ação")
	eq.select_inventory("arma_rebite")
	check(eq.detail_action.disabled and "bloqueado" in eq.detail_reason.text.to_lower(), "item bloqueado explica a ação indisponível")
	eq.show_tab(1); check(eq.active_tab == 1 and eq.find_child("RobôsCard_titan", true, false) is Button, "aba Robôs lista estado real")
	var titan_card: Button = eq.find_child("RobôsCard_titan", true, false); titan_card.grab_focus(); await process_frame
	check(titan_card.has_focus() and titan_card.get_theme_stylebox("focus") is StyleBoxFlat, "cards de equipamento possuem foco visível")
	eq.show_tab(2); check(eq.find_child("ArmadurasCard_omega", true, false) is Button, "aba Armaduras lista Ômega")
	eq.show_tab(3); check(eq.find_child("Unequip_robo", true, false) is Button, "aba Equipados possui slots funcionais")
	eq.show_tab(4); check(eq.active_tab == 4 and eq.page.find_children("*", "Label", true, false).size() >= 10, "aba Status usa linhas calculadas")
	var before: int = eq.active_tab; eq.cycle(1)
	check(eq.active_tab != before and eq.tabs[eq.active_tab].has_focus() and eq.find_child("InventorySlot_arma_blaster", true, false) is Button, "controle alterna aba e conteúdo com foco visível")
	app.queue_free(); await process_frame
	print("INVENTORY_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)

