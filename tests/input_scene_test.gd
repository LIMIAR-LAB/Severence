extends SceneTree

var app: Node
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok: print("PASS INPUT: ", label)
	else: failures += 1; push_error(label)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = pressed
	Input.parse_input_event(event)

func frames(n: int) -> void:
	for i in range(n): await physics_frame

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await frames(3)
	app.start_solo()
	await frames(60) # Aguarda o portal de 0,8s e a supressão do clique do menu.
	check(app.sim.mode == "arena" and app.sim.enemies.size() >= 5 and not app.menu.visible, "main play button enters live combat")
	var center: Vector2 = root.get_visible_rect().size / 2
	Input.warp_mouse(center + Vector2(400, 0))
	key(KEY_D, true)
	var before: Vector2 = app.sim.actors[0].p
	await frames(12)
	check(app.sim.actors[0].p.x > before.x + 40 and app.sim.actors[0].facing.dot(app.sim.actors[0].aim) > 0.9, "D input moves Marty; body faces the aim")
	key(KEY_D, false); key(KEY_W, true)
	Input.warp_mouse(center + Vector2(0, -400))
	await frames(12)
	check(app.sim.actors[0].facing.dot(app.sim.actors[0].aim) > 0.9, "body turns to follow the mouse aim (up) even while walking, so the weapon never crosses the character")
	key(KEY_W, false)
	before = app.sim.actors[0].p
	key(KEY_SHIFT, true)
	await frames(2)
	key(KEY_SHIFT, false)
	await frames(10)
	check(app.sim.actors[0].p.y < before.y - 120, "Shift input dashes from standstill")
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; Input.parse_input_event(click)
	await frames(2)
	var shots: Array = app.sim.bullets.filter(func(b): return b.owner == 0)
	check(not shots.is_empty(), "left mouse input fires Marty weapon")
	click = InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = false; Input.parse_input_event(click)
	app.sim.actors[0].hurt = 0
	key(KEY_SPACE, true); await frames(2); key(KEY_SPACE, false)
	check(app.sim.actors[0].jump > 0, "Space input starts a jump")
	await frames(60)
	check(app.sim.actors[1].shot > 0 or app.sim.bullets.any(func(b): return b.owner == 1), "AI actively attacks in the complete game scene")
	print("INPUT SCENE TEST: ", failures, " failures")
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
