extends SceneTree

const EncyclopediaData = preload("res://scripts/encyclopedia_data.gd")
const EncyclopediaScreen = preload("res://scripts/encyclopedia_screen.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func finish() -> void:
	print("ENCYCLOPEDIA_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)

func _initialize() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame; await process_frame
	var ui = app.menu
	ui.show_screen("options"); await process_frame
	var title_entry := ui.content.find_child("EncyclopediaButton", true, false) as Button
	check(title_entry != null, "fluxo da tela inicial oferece o Arquivo em Opções")
	if title_entry == null: finish(); return
	title_entry.pressed.emit(); await process_frame; await process_frame
	check(ui.screen == "encyclopedia" and ui.encyclopedia != null, "Arquivo abre pelo fluxo da tela inicial")
	check(ui.content.find_child("Category_monstros", true, false) is Button, "aba de monstros existe")
	check(ui.content.find_child("Category_itens", true, false) is Button, "aba de itens existe")
	check(ui.content.find_child("Category_robos", true, false) is Button, "aba de robôs existe")
	check(ui.content.find_child("Entry_monstro_almirante", true, false) is Button, "lista é gerada pelos dados")
	check(ui.content.find_child("ArchiveBackdrop", true, false) is TextureRect, "Arquivo reutiliza atmosfera pixel-art do jogo")
	check(ui.content.find_child("ArchiveChassis", true, false) is Panel, "Arquivo possui chassi industrial próprio")
	check(ui.content.find_child("DossierListPanel", true, false) is Panel, "índice assume linguagem de dossiê")
	check(ui.content.find_child("ArchivePortraitFrame", true, false) is NinePatchRect, "moldura ornamentada enquadra o registro")
	check(ui.content.find_child("ArchiveControlLegend", true, false) is Panel, "legenda de controles permanece visível")
	check(ui.content.find_child("FractureAccent", true, false) is ColorRect, "fratura violeta integra a identidade temporal")

	var robot_tab := ui.content.find_child("Category_robos", true, false) as Button
	check(robot_tab != null, "aba de robôs pode receber foco")
	if robot_tab == null: finish(); return
	robot_tab.pressed.emit(); await process_frame
	var titan := ui.content.find_child("Entry_robo_titan", true, false) as Button
	check(titan != null, "troca de categoria reconstrói a lista")
	if titan == null: finish(); return
	titan.pressed.emit(); await process_frame
	check((ui.content.find_child("EntryName", true, false) as Label).text == "TITAN", "seleção atualiza os detalhes")
	check((ui.content.find_child("EntryImage", true, false) as TextureRect).visible, "arte existente aparece no detalhe")

	var item_tab := ui.content.find_child("Category_itens", true, false) as Button
	if item_tab == null: check(false, "aba de itens permanece disponível"); finish(); return
	robot_tab.grab_focus()
	var left := InputEventAction.new(); left.action = "ui_left"; left.pressed = true; Input.parse_input_event(left); await process_frame
	left.pressed = false; Input.parse_input_event(left); await process_frame
	check(root.get_viewport().gui_get_focus_owner() == item_tab, "teclado/controle percorre as abas pelo foco")
	var accept := InputEventAction.new(); accept.action = "ui_accept"; accept.pressed = true; Input.parse_input_event(accept); await process_frame
	accept.pressed = false; Input.parse_input_event(accept); await process_frame
	check(ui.encyclopedia.category == "itens", "aceitar pelo foco troca a categoria")
	await process_frame
	var fragment := ui.content.find_child("Entry_item_fragmento", true, false) as Button
	if fragment == null: check(false, "fragmento aparece na lista"); finish(); return
	fragment.pressed.emit(); await process_frame
	check((ui.content.find_child("EntryFallback", true, false) as Label).visible, "entrada sem arte usa fallback")
	check(ui.content.find_child("MissingArtSeal", true, false) is Panel, "fallback sem arte usa selo intencional")
	var archive_backdrop := ui.content.find_child("ArchiveBackdrop", true, false) as TextureRect
	var portrait_frame := ui.content.find_child("ArchivePortraitFrame", true, false) as NinePatchRect
	check(archive_backdrop != null and archive_backdrop.texture != null and archive_backdrop.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "fundo reutilizado preserva filtragem nearest")
	check(portrait_frame != null and portrait_frame.texture != null and portrait_frame.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "moldura reutilizada preserva filtragem nearest")
	check(root.get_viewport().gui_get_focus_owner() is Button, "navegação mantém um botão em foco")
	(ui.content.find_child("EncyclopediaBack", true, false) as Button).pressed.emit(); await process_frame
	check(ui.screen == "options", "Voltar retorna a Opções")

	var injected = EncyclopediaScreen.new(); injected.host = ui
	var long_traits: Array[String] = []
	for i in 24: long_traits.append("Traço temporal de validação %02d" % i)
	injected.records_override = EncyclopediaData.valid_entries([{"id":"novo_item", "categoria":"itens", "nome":"NOVO ITEM COM NOME EXTENSO PARA VALIDAR O RECORTE DO DOSSIÊ", "subtitulo":"adicionado depois", "descricao":"Entrada incluída sem mudar a tela. ".repeat(24), "ordem":1, "imagem":"res://imagem-ausente.png", "tracos":long_traits}])
	root.add_child(injected); injected.build(); injected.select_category("itens"); await process_frame
	check(injected.find_child("Entry_novo_item", true, false) is Button, "entrada adicionada aparece sem mudança na UI")
	check((injected.find_child("EntryFallback", true, false) as Label).visible, "caminho de imagem indisponível usa fallback")
	check(injected.find_child("DetailScroll", true, false) is ScrollContainer, "detalhes extensos possuem rolagem")
	var detail_scroll := injected.find_child("DetailScroll", true, false) as ScrollContainer
	check(detail_scroll != null and detail_scroll.get_v_scroll_bar().max_value > detail_scroll.get_v_scroll_bar().page, "conteúdo longo ativa rolagem vertical")
	if detail_scroll != null:
		detail_scroll.grab_focus()
		var scroll_down := InputEventAction.new(); scroll_down.action = "ui_down"; scroll_down.pressed = true
		injected._unhandled_input(scroll_down); await process_frame
		check(detail_scroll.scroll_vertical > 0, "teclado/controle percorre o texto longo do dossiê")
		injected.select_entry(injected.records_override[0]); await process_frame
		check(detail_scroll.scroll_vertical == 0, "novo dossiê reinicia a leitura no topo")
	injected.records_override = []; injected.select_category("robos"); await process_frame
	var empty_tab: Button = injected.tabs.robos
	check(empty_tab.focus_neighbor_bottom == empty_tab.get_path_to(injected.back_button), "categoria vazia liga aba diretamente ao Voltar")
	check(injected.name_label.tooltip_text.is_empty() and injected.subtitle_label.tooltip_text.is_empty(), "estado vazio limpa tooltips do dossiê anterior")
	injected.queue_free(); await process_frame

	var empty = EncyclopediaScreen.new(); empty.host = ui; empty.records_override = []
	root.add_child(empty); empty.build(); await process_frame
	check(empty.empty_label.visible and empty.empty_label.text.contains("Nenhum registro"), "categoria vazia mostra estado explícito")
	check(not empty.back_button.disabled, "categoria vazia mantém Voltar utilizável")
	empty.queue_free(); await process_frame

	app.playing = true; ui.show_screen("pause"); await process_frame
	var pause_entry := ui.content.find_child("PauseEncyclopedia", true, false) as Button
	check(pause_entry != null, "pausa oferece o Arquivo")
	if pause_entry == null: finish(); return
	pause_entry.pressed.emit(); await process_frame
	var escape := InputEventKey.new(); escape.physical_keycode = KEY_ESCAPE; escape.pressed = true
	Input.parse_input_event(escape); await physics_frame
	escape.pressed = false; Input.parse_input_event(escape); await physics_frame
	check(ui.screen == "pause", "Esc retorna o Arquivo à pausa sem retomar o jogo")
	pause_entry = ui.content.find_child("PauseEncyclopedia", true, false) as Button
	if pause_entry == null: check(false, "pausa reconstrói acesso ao Arquivo"); finish(); return
	pause_entry.pressed.emit(); await process_frame
	var pause_back := ui.content.find_child("EncyclopediaBack", true, false) as Button
	if pause_back == null: check(false, "Arquivo mantém botão Voltar"); finish(); return
	pause_back.pressed.emit(); await process_frame
	check(ui.screen == "pause", "Voltar retorna à pausa de origem")
	finish()
