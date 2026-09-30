extends SceneTree

var failures := 0
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func key_event(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode; event.keycode = keycode; event.pressed = pressed
	Input.parse_input_event(event); Input.flush_buffered_events()

func press_key(keycode: Key) -> void:
	key_event(keycode, true)
	for _i in 3: await physics_frame
	key_event(keycode, false)
	for _i in 2: await physics_frame

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app); await process_frame
	app.sim.set_unlocks(["padrao", "titan", "spectre", "omega"])
	app.sim.materials = 5
	app.menu.open("equipment"); await process_frame
	check(app.menu.screen == "equipment" and app.menu.equipment != null and not app.menu.equipment.mission_mode, "equipamento pré-missão mantém a preparação existente")
	app.menu.close(); await process_frame
	app.start_single(); app.sim.start_run(1941)
	var marty: Dictionary = app.sim.actors[0]
	marty.p = app.sim.pickups.filter(func(p): return p.kind == "weapon")[0].p
	app.sim.collect_pickups()
	app.sim.keys = 3; app.sim.money = 47; app.sim.materials = 8
	app.sim.mech.fuel = app.sim.FUEL_MAX * 0.62; app.sim.spectres[0].hp = 71
	app.sim.actors[0].selected_robot = "titan"; app.menu.robot_choice = "spectre"
	var persistent_before: Dictionary = app.sim.inventory_state.duplicate(true)
	await press_key(KEY_B); await process_frame
	check(app.menu.screen == "mission_inventory" and app.menu.visible and app.paused, "B abre diretamente o inventário e mantém a simulação offline pausada")
	check(app.menu.robot_choice == "titan", "atalho direto atualiza o loadout vivo antes de abrir")
	await press_key(KEY_B); await process_frame
	check(app.menu.screen == "pause" and app.menu.visible and app.paused, "B no inventário retorna à pausa sem retomar")
	var open_button: Button = app.menu.content.find_child("MissionInventory", true, false)
	var resume_button: Button = app.menu.content.find_child("ResumeGame", true, false)
	var accent := open_button.get_theme_stylebox("normal") as StyleBoxFlat if open_button != null else null
	check(open_button != null and resume_button != null and open_button.position.y < resume_button.position.y, "inventário é uma ação principal no topo da pausa")
	check(accent != null and accent.border_width_top >= 3 and "[B]" in open_button.text, "ação do inventário possui destaque visual e informa o atalho")
	check(open_button.has_focus(), "ação destacada do inventário recebe o foco inicial da pausa")
	check(open_button.focus_neighbor_bottom == open_button.get_path_to(resume_button) and resume_button.focus_neighbor_top == resume_button.get_path_to(open_button), "ação destacada permanece navegável por teclado e controle")
	var encyclopedia_button: Button = app.menu.content.find_child("PauseEncyclopedia", true, false)
	check(encyclopedia_button.focus_neighbor_bottom == encyclopedia_button.get_path_to(open_button) and open_button.focus_neighbor_top == open_button.get_path_to(encyclopedia_button), "navegação da pausa forma um ciclo entre a última e a primeira ação")
	await press_key(KEY_B); await process_frame
	check(app.menu.screen == "mission_inventory" and app.menu.visible and app.paused, "B na pausa abre o inventário sem retomar a partida")
	var eq = app.menu.equipment
	check(app.menu.screen == "mission_inventory" and eq != null and eq.mission_mode, "abre shell no modo missão")
	check(eq.find_child("InventorySlot_missao_chaves", true, false) is Button, "chaves coletadas aparecem na grade")
	check(eq.find_child("InventorySlot_missao_moedas", true, false) is Button, "moedas coletadas aparecem na grade")
	check(eq.find_child("InventorySlot_missao_bazuca", true, false) is Button, "bazuca aparece no inventário da missão")
	check(eq.find_child("InventorySlot_missao_foguetes", true, false) is Button and eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_foguetes")) == 6, "foguetes aparecem com munição real")
	check(eq.find_child("InventorySlot_modulo_titan", true, false) is Button and eq.find_child("InventorySlot_nucleo_spectre", true, false) is Button, "módulos Titan e Spectre possuídos ficam disponíveis durante a missão")
	check(load("res://assets/weapons/bazooka_v2.png") is Texture2D and load("res://assets/ui/equipamento/icones/icon_foguete_v1.png") is Texture2D, "inventário carrega arte final da bazuca e da munição")
	check(eq.find_child("InventorySlot_prototipo_reparo", true, false) == null, "item persistente não levado fica fora da missão")
	check(eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_fragmentos")) == 3, "fragmentos contam somente o ganho desta missão")
	check(eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_combustivel")) == 62, "combustível usa valor vivo quando Titan foi levado")
	check(eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_energia")) == 0, "energia só aparece quando Spectre foi levado")
	check(eq.find_child("InventorySlot_missao_combustivel", true, false) == null and eq.find_child("InventorySlot_missao_energia", true, false) == null, "reservas do robô não são consumíveis na mochila")
	check(app.sim.inventory_state == persistent_before, "recursos da tentativa não entram no inventário persistente")
	var transient_button: Button = eq.find_child("InventorySlot_missao_chaves", true, false); transient_button.grab_focus(); await process_frame
	check(transient_button.has_focus() and transient_button.get_theme_stylebox("focus") is StyleBoxFlat, "recurso da missão possui foco visível")
	eq.select_inventory("missao_chaves")
	check(eq.detail_action.disabled and "temporário" in eq.detail_reason.text and not eq.detail_action.visible, "recurso temporário não oferece ação falsa")
	eq.find_child("InventorySlot_missao_bazuca", true, false).grab_focus()
	check(not eq.detail_action.disabled and "FOGUETES  6" in eq.detail_stats.text and "EM USO" in eq.detail_stats.text, "detalhe da bazuca mostra munição e estado")
	var live_before_compare: Dictionary = app.sim.actors[0].duplicate(true)
	eq.show_comparison()
	var comparison_scroll: ScrollContainer = eq.find_child("InventoryComparisonScroll", true, false)
	var comparison: RichTextLabel = eq.find_child("InventoryComparisonText", true, false)
	check(comparison_scroll.visible and "ARMA BÁSICA → BAZUCA" in comparison.get_parsed_text(), "comparação especial da bazuca usa a área rolável")
	check("#%s" % eq.bbcode_color(eq.IMPROVEMENT) in comparison.text and "#%s" % eq.bbcode_color(eq.REGRESSION) in comparison.text and "#%s" % eq.bbcode_color(eq.TEAL) in comparison.text, "bazuca distingue melhoria, regressão e mudança textual")
	check(app.sim.actors[0] == live_before_compare and app.sim.inventory_state == persistent_before, "comparar não altera equipamento nem estado vivo da missão")
	eq.detail_action.grab_focus(); check(eq.detail_action.has_focus(), "ações continuam navegáveis por teclado após comparar")
	eq.select_inventory("missao_chaves")
	check(not comparison_scroll.visible and eq.detail_text.visible and eq.detail_stats.visible, "seleção de outro item encerra comparação sem conteúdo residual")
	eq.find_child("InventorySlot_missao_bazuca", true, false).grab_focus()
	marty.armor = true; await process_frame; await process_frame
	check(eq.detail_action.disabled, "inventário atualiza bloqueio durante armadura")
	marty.armor = false; await process_frame; await process_frame
	check(not eq.detail_action.disabled, "fim da armadura reativa ação sem reabrir inventário")
	marty.run_weapons.bazooka = 4; marty.run_weapon = ""
	await process_frame; await process_frame
	check(eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_foguetes")) == 4 and "GUARDADA" in eq.detail_stats.text, "inventário acompanha munição e troca ao vivo")
	app.sim.keys = 9; await process_frame; await process_frame
	check(eq.find_child("InventorySlot_missao_chaves", true, false) != null and eq.quantity_for(load("res://scripts/inventory_data.gd").item("missao_chaves")) == 9, "quantidades mudam ao vivo sem reabrir a tela")
	marty.run_weapons.bazooka = 0; await process_frame; await process_frame
	check(eq.find_child("InventorySlot_missao_bazuca", true, false) != null and eq.find_child("InventorySlot_missao_foguetes", true, false) == null, "bazuca vazia continua visível, foguetes zerados somem")
	eq.detail_action.grab_focus(); await press_key(KEY_ENTER)
	check(marty.run_weapon == "bazooka" and marty.run_weapons.bazooka == 0, "Enter equipa bazuca vazia sem criar foguetes")
	eq.detail_action.grab_focus(); await press_key(KEY_ENTER)
	check(marty.run_weapon == "", "Enter volta à arma básica pelo inventário")
	eq.show_tab(4)
	var stable_health: Label = eq.find_child("MissionHealth", true, false)
	marty.hp = 15; marty.shield = 12; marty.armor = true; marty.armor_time = 85
	app.sim.mech.hp = 123; app.sim.mech.fuel = 41; app.sim.mech.deployed = false
	await process_frame; await process_frame
	# Armor activation rebuilds once; subsequent health/fuel/timer updates preserve nodes.
	stable_health = eq.find_child("MissionHealth", true, false)
	marty.hp = 14; marty.armor_time = 84.9; app.sim.mech.fuel = 40.9
	await process_frame; await process_frame
	check(stable_health == eq.find_child("MissionHealth", true, false), "alterações contínuas atualizam labels sem destruir controles")
	marty.hp = 15
	await process_frame
	check("1.5 / 3" in eq.find_child("MissionHealth", true, false).text, "vida atual atualiza sem reabrir")
	check("1.2 / 3" in eq.find_child("MissionShield", true, false).text and "85s" in eq.find_child("MissionShield", true, false).text, "escudo e duração atuais separados da referência")
	check("123 / 240" in eq.find_child("MissionRobot", true, false).text and "41%" in eq.find_child("MissionRobot", true, false).text and "RECOLHIDO" in eq.find_child("MissionRobot", true, false).text, "integridade combustível e estado reais do Titan")
	marty.armor = false; marty.shield = 0; marty.armor_cd = 22
	app.menu.robot_choice = "spectre"; marty.selected_robot = "spectre"; app.sim.spectres[0].state = "following"; app.sim.spectres[0].hp = 33
	await process_frame; await process_frame
	check("RECARREGANDO" in eq.find_child("MissionShield", true, false).text and "22s" in eq.find_child("MissionShield", true, false).text, "recarga Ômega acompanha estado atual")
	check("ACOMPANHANDO" in eq.find_child("MissionRobot", true, false).text and "33 / 100" in eq.find_child("MissionRobot", true, false).text, "energia e estado Spectre atualizam ao vivo")
	check(eq.find_child("MartyReference_0", true, false).text == "3", "ferimentos não alteram referência de vida")
	eq.show_tab(0)
	check(eq.find_child("EquippedBadge_nucleo_spectre", true, false) != null and eq.find_child("EquippedBadge_modulo_titan", true, false) == null, "marcador equipado acompanha robô selecionado sem usar inventário antigo")
	app.sim.start_run(1942); await process_frame; await process_frame
	check(eq.find_child("InventorySlot_missao_bazuca", true, false) == null, "nova RUN não herda a arma encontrada")
	await press_key(KEY_ESCAPE); await process_frame
	check(app.menu.screen == "pause" and app.menu.visible and app.paused, "Esc no inventário retorna à pausa sem retomar")
	open_button = app.menu.content.find_child("MissionInventory", true, false)
	open_button.pressed.emit(); await process_frame; await process_frame
	eq = app.menu.equipment
	eq.go_back(); await process_frame
	check(app.menu.screen == "pause" and app.menu.visible and app.paused, "Voltar no inventário retorna à pausa sem retomar")
	open_button = app.menu.content.find_child("MissionInventory", true, false)
	open_button.pressed.emit(); await process_frame; await process_frame
	key_event(KEY_ESCAPE, true); key_event(KEY_B, true)
	for _i in 3: await physics_frame
	key_event(KEY_ESCAPE, false); key_event(KEY_B, false)
	for _i in 2: await physics_frame
	check(app.menu.screen == "pause" and app.menu.visible and app.paused, "Esc tem precedência quando Esc e B chegam no mesmo quadro")
	check(app.sim.inventory_state == persistent_before, "atalhos e retornos não alteram o inventário persistente")
	app.queue_free(); await process_frame
	print("MISSION_INVENTORY_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)

