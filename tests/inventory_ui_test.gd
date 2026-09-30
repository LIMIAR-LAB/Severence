extends SceneTree

var failures := 0
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func click_control(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	root.push_input(motion, true); await process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new(); event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		root.push_input(event, true); await process_frame

func press_key(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new(); event.keycode = keycode; event.physical_keycode = keycode; event.pressed = pressed
		Input.parse_input_event(event); Input.flush_buffered_events(); await process_frame

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
	for id in ["kit_reparo", "sucata_temporal", "fragmento_cronal", "chave_fenda_do_marty"]:
		eq.inventory.add(id, 1)
		eq.refresh()
		check(eq.find_child("InventorySlot_" + id, true, false) == null and eq.inventory.quantity(id) > 0, "protótipo preservado e oculto: " + id)
	check(eq.capacity_label.text == "6 ITENS", "contador mostra somente os seis equipamentos disponíveis ou bloqueados")
	await process_frame; await process_frame
	var blaster_slot: Button = eq.find_child("InventorySlot_arma_blaster", true, false)
	blaster_slot.grab_focus(); await process_frame
	check(blaster_slot.has_focus() and blaster_slot.get_theme_stylebox("focus") is StyleBoxFlat, "slot possui foco visível para teclado/controle")
	check(eq.detail_title.text == "UNIFORME PADRÃO" and not eq.detail_action.disabled, "seleção alimenta detalhes e ação")
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
	for i in [1, 2, 3, 4, 0]:
		await click_control(eq.find_child("MenuTab_%d" % i, true, false))
		check(eq.active_tab == i, "clique real troca aba %d" % i)
	await click_control(eq.find_child("Filter_armas", true, false))
	check(eq.inventory.filter == "armas", "clique real aplica filtro")
	await click_control(eq.find_child("InventorySlot_arma_blaster", true, false))
	check(eq.inventory.selected_id == "arma_blaster", "clique real seleciona item")
	await click_control(eq.find_child("InventoryCompare", true, false))
	var comparison: RichTextLabel = eq.find_child("InventoryComparisonText", true, false)
	var comparison_scroll: ScrollContainer = eq.find_child("InventoryComparisonScroll", true, false)
	check(comparison_scroll.visible and "→" in comparison.get_parsed_text() and "DANO" in comparison.get_parsed_text(), "comparação exibe valores reais em área própria")
	check("#%s" % eq.bbcode_color(eq.TEXT) in comparison.text, "valores iguais permanecem neutros")
	check(eq.comparison_tone({"display":"A", "score":null}, {"display":"B", "score":null}) == "changed", "mudança textual sem escore usa estado teal sem inferir qualidade")
	app.sim.set_unlocks(["padrao", "mecanico", "espiao", "titan", "spectre"])
	eq.select_inventory("arma_rebite"); eq.show_comparison()
	check("#%s" % eq.bbcode_color(eq.IMPROVEMENT) in comparison.text and "#%s" % eq.bbcode_color(eq.REGRESSION) in comparison.text, "melhorias e regressões recebem cores semânticas pelos escores")
	check(comparison_scroll.position.y + comparison_scroll.size.y < eq.detail_action.position.y, "comparação fica contida acima das ações")
	eq.select_inventory("arma_smg")
	check(not comparison_scroll.visible and eq.detail_text.visible and eq.detail_stats.visible and eq.detail_stats.position.y == 276, "nova seleção restaura geometria e conteúdo normais")
	# Robôs têm conjuntos diferentes e forçam conteúdo maior que a janela rolável.
	eq.host.robot_choice = "titan"; eq.select_inventory("nucleo_spectre"); eq.show_comparison()
	await process_frame
	check(comparison_scroll.visible and comparison.custom_minimum_size.x <= comparison_scroll.size.x and comparison.get_content_height() > comparison_scroll.size.y, "comparação longa de robôs permanece rolável e sem largura excedente")
	var scroll_before := comparison_scroll.scroll_vertical
	await press_key(KEY_DOWN)
	check(comparison_scroll.scroll_vertical > scroll_before and comparison_scroll.has_focus(), "teclado/controle rola a comparação sem perder o foco")
	await click_control(eq.find_child("InventoryAction", true, false))
	check("equipado" in eq.status.text, "clique real executa equipamento")
	app.queue_free(); await process_frame
	print("INVENTORY_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)

