extends SceneTree

# Navega a tela inicial ate iniciar a expedicao usando SOMENTE
# InputEventJoypadButton — o mesmo caminho de um controle real.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func press(btn: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn; e.pressed = true
	Input.parse_input_event(e)
	await process_frame; await process_frame
	e = InputEventJoypadButton.new()
	e.button_index = btn; e.pressed = false
	Input.parse_input_event(e)
	await process_frame; await process_frame

func action_press(name: String) -> void:
	var e := InputEventAction.new()
	e.action = name; e.pressed = true
	Input.parse_input_event(e)
	await process_frame; await process_frame

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var app: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	for i in 6: await process_frame   # _ready + focus_first diferido

	var menu = app.menu
	check(menu.visible, "menu visivel no boot")
	check(menu.screen == "main", "tela inicial e o menu principal")

	var focus = root.gui_get_focus_owner()
	check(focus != null, "foco inicial em um botao (%s)" % focus)

	# A (cross) confirma o botao focado -> tela de personagens
	await press(JOY_BUTTON_A)
	check(menu.screen == "characters", "A no titulo vai para personagens (tela=%s)" % menu.screen)

	# A no Marty -> escolha de aventura
	await press(JOY_BUTTON_A)
	check(menu.screen == "play", "A no Marty vai para aventura (tela=%s)" % menu.screen)

	# A na escolha focada (solo) -> equipamento
	await press(JOY_BUTTON_A)
	check(menu.screen == "equipment", "A no modo vai para equipamento (tela=%s)" % menu.screen)

	# Do equipamento, navegar com d-pad ate o botao IR AO REFUGIO
	var refuge = menu.content.find_child("Refuge", true, false)
	check(refuge != null and refuge is Button, "botao IR AO REFUGIO existe")
	var guard := 0
	while root.gui_get_focus_owner() != refuge and guard < 40:
		await action_press("ui_down"); guard += 1
		if root.gui_get_focus_owner() == refuge: break
		await action_press("ui_right"); guard += 1
		if root.gui_get_focus_owner() == refuge: break
	check(root.gui_get_focus_owner() == refuge, "d-pad alcanca IR AO REFUGIO (foco=%s, tentativas=%d)" % [root.gui_get_focus_owner(), guard])

	# A confirma -> expedicao inicia
	await press(JOY_BUTTON_A)
	for i in 4: await process_frame
	check(app.playing, "expedicao iniciada so com o controle (playing=%s)" % app.playing)
	check(not menu.visible, "menu escondeu ao iniciar")

	print("CONTROLLER_MENU failures=%d" % failures)
	quit(failures)
