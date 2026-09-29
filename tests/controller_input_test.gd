extends SceneTree

var app: Node
var failures := 0
const PAD := 12
class TestApp extends "res://scripts/main.gd":
	func connected_gamepads() -> Array: return [12]

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: print("PASS CONTROLE: ", label)
	else: failures += 1; push_error(label)
func axis(id: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new(); e.device = PAD; e.axis = id; e.axis_value = value
	Input.parse_input_event(e)
func button(id: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new(); e.device = PAD; e.button_index = id; e.pressed = pressed
	Input.parse_input_event(e); Input.flush_buffered_events()
func frames(n: int) -> void:
	for i in range(n): await physics_frame

func run() -> void:
	app = TestApp.new(); root.add_child(app)
	await frames(2)
	app.start_single(); app.sim.make_hub(); app.ui_input_block = 0
	check(app.gameplay_joypad(true, [PAD]) == PAD, "solo usa primeiro controle")
	app.sim.coop = "local"
	check(app.gameplay_joypad(true, [PAD]) == -1 and app.gameplay_joypad(false, [PAD]) == PAD, "coop teclado + controle preservado")
	check(app.gameplay_joypad(true, [12, 15]) == 12 and app.gameplay_joypad(false, [12, 15]) == 15, "coop dois controles separados")
	app.sim.coop = "solo"
	await frames(60)
	var before: Vector2 = app.sim.actors[0].p
	axis(JOY_AXIS_LEFT_X, 1.0); await frames(8); axis(JOY_AXIS_LEFT_X, 0.0)
	check(app.sim.actors[0].p.x > before.x + 15, "analógico desloca Marty na cena real")
	axis(JOY_AXIS_RIGHT_Y, -1.0); await frames(3); axis(JOY_AXIS_RIGHT_Y, 0.0); await frames(3)
	check(app.sim.actors[0].aim.dot(Vector2.UP) > 0.95, "mira permanece ao soltar analógico")
	axis(JOY_AXIS_TRIGGER_RIGHT, 1.0); await frames(3); axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	check(app.sim.bullets.any(func(b): return b.owner == 0), "gatilho dispara")
	button(JOY_BUTTON_A, true); await frames(2); button(JOY_BUTTON_A, false)
	check(app.sim.actors[0].jump > 0, "botão inferior salta")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(app.paused and app.menu.visible, "perder foco pausa")
	button(JOY_BUTTON_START, true); await frames(2); button(JOY_BUTTON_START, false); await frames(2)
	check(not app.paused and not app.menu.visible, "Options/Start retoma sem teclado")
	button(JOY_BUTTON_START, true); await frames(2); button(JOY_BUTTON_START, false); await frames(2)
	check(app.paused and app.menu.visible, "Options/Start abre pausa")
	var resume: Button = app.menu.content.find_child("ResumeGame", true, false)
	var save: Button = app.menu.content.find_child("SaveGame", true, false)
	var leave: Button = app.menu.content.find_child("ReturnToMenu", true, false)
	check(resume.has_focus(), "primeira ação da pausa recebe foco")
	check(resume.focus_neighbor_bottom == resume.get_path_to(save) and save.focus_neighbor_bottom == save.get_path_to(leave), "controle alcança as três ações")
	app.menu.close()
	var mouse := InputEventMouseMotion.new(); mouse.relative = Vector2(5, 0); Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	check(app.joy_aim.is_empty(), "mover mouse devolve mira ao mouse")
	check(app.gameplay_joypad(true, []) == -1, "sem controle mantém teclado")
	print("CONTROLLER INPUT TEST failures=", failures)
	app.queue_free(); await process_frame; await process_frame
	quit(1 if failures else 0)
