extends SceneTree

# Tela inicial unificada — cenário em vídeo, console vivo, estados e atalhos corretos.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _initialize() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	var ui = app.menu
	ui.show_screen("main"); await process_frame; await process_frame
	check(ResourceLoader.exists("res://assets/ui/title/title_loop.ogv"), "vídeo da tela inicial no projeto (Theora)")
	check(ui.content.find_child("TitleConsole", true, false) is Panel, "console único cobre os controles pintados no vídeo")
	check(ui.content.find_child("TitleControlMask", true, false) is ColorRect, "máscara opaca impede vazamento das placas antigas")
	var buttons: Array = []
	for i in 7: buttons.append(ui.content.find_child("Title_%d" % i, true, false))
	check(buttons.all(func(b): return b is Button), "7 ações são controles vivos")
	check(buttons[0].disabled and not app.playing, "CONTINUAR desativado sem expedição")
	var focus: Control = root.get_viewport().gui_get_focus_owner()
	check(focus == buttons[1], "foco inicial em NOVA EXPEDIÇÃO")
	check(not buttons[1].disabled and buttons[1].has_focus(), "somente uma ação habilitada inicia em foco")
	check(ui.content.find_children("Plate_*", "TextureRect", true, false).is_empty(), "não usa placas recortadas sobre o cenário")
	check(ui.content.find_child("Title_4", true, false).disabled == not app.has_saved_game(), "carregar habilitado apenas com save")
	check(ui.content.find_child("TitleNetworkStatus", true, false) is Label, "estado da rede ocupa área própria no rodapé")
	app.playing = true; ui.show_screen("main"); await process_frame; await process_frame
	check(not ui.content.find_child("Title_0", true, false).disabled, "CONTINUAR habilitado durante expedição ativa")
	check(root.get_viewport().gui_get_focus_owner() == ui.content.find_child("Title_0", true, false), "expedição ativa prioriza CONTINUAR no foco")
	app.playing = false; ui.show_screen("main"); await process_frame
	var targets := {1: "characters", 2: "online", 3: "seed", 5: "options"}
	for i in targets:
		ui.show_screen("main"); await process_frame
		(ui.content.find_child("Title_%d" % i, true, false) as Button).pressed.emit()
		check(ui.screen == targets[i], "botão %d abre %s" % [i, targets[i]])
	ui.show_screen("characters"); await process_frame
	check(ui.content.find_child("CharacterMarty", true, false) is Button, "Marty selecionável")
	for i in range(1, 6):
		check(ui.content.find_child("CharacterLocked%d" % i, true, false).disabled, "personagem futuro %d bloqueado" % i)
	ui.content.find_child("CharacterMarty", true, false).pressed.emit()
	check(ui.screen == "play" and ui.content.find_child("LocalChoice", true, false) is Button, "escolha de Marty abre os três modos")
	ui.content.find_child("LocalChoice", true, false).pressed.emit()
	check(ui.screen == "equipment" and ui.pending_mode == "local", "coop local leva à configuração de equipamento")
	ui.content.find_child("Back", true, false).pressed.emit()
	check(ui.screen == "play", "equipamento volta à escolha do modo")
	ui.content.find_child("LocalChoice", true, false).pressed.emit()
	ui.content.find_child("Refuge", true, false).pressed.emit()
	check(app.playing and app.sim.coop == "local" and app.sim.mode == "hub", "coop local inicia no refúgio")
	print("TITLE_SCREEN_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
