extends SceneTree

# 0.16: tela inicial em vídeo — placas normal/acesa por botão, CONTINUAR só com expedição, atalhos certos.
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
	var buttons: Array = []
	for i in 7: buttons.append(ui.content.find_child("Title_%d" % i, true, false))
	check(buttons.all(func(b): return b is Button), "7 botões do menu desenhado no vídeo")
	check(buttons[0].disabled and not app.playing, "CONTINUAR desativado sem expedição")
	var focus: Control = root.get_viewport().gui_get_focus_owner()
	check(focus == buttons[1], "foco inicial em NOVA EXPEDIÇÃO")
	var lit := 0
	for n in ui.content.find_children("*", "TextureRect", true, false):
		if n.texture and n.texture.resource_path.ends_with("_sel.png") and n.visible: lit += 1
	check(lit == 1, "só a placa do botão focado fica acesa")
	check(ui.content.find_child("CoopLocal", true, false) is Button, "coop local continua acessível")
	var targets := {1: "play", 2: "online", 3: "seed", 5: "options"}
	for i in targets:
		ui.show_screen("main"); await process_frame
		(ui.content.find_child("Title_%d" % i, true, false) as Button).pressed.emit()
		check(ui.screen == targets[i], "botão %d abre %s" % [i, targets[i]])
	ui.show_screen("main"); await process_frame
	(ui.content.find_child("Title_4", true, false) as Button).pressed.emit()
	check(ui.screen == "equipment", "EQUIPAMENTO abre a tela de equipamento")
	print("TITLE_SCREEN_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
