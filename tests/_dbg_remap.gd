extends SceneTree

var app: Node

func _initialize() -> void:
	run.call_deferred()

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = pressed
	Input.parse_input_event(event)

func frames(n: int) -> void:
	for i in range(n): await physics_frame

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await frames(3)
	app.rebind_key("up", KEY_I)
	app.start_solo()
	await frames(60)
	var a: Dictionary = app.sim.actors[0]
	print("mode=", app.sim.mode, " floors=", app.sim.floors, " p=", a.p, " hint=", app.sim.floor_hint)
	print("clear_at(p,11)=", app.sim.clear_at(a.p, 11), " clear up=", app.sim.clear_at(a.p + Vector2(0, -6), 11))
	var before: Vector2 = a.p
	key(KEY_I, true)
	for i in 12:
		await physics_frame
		print("f", i, " p=", a.p, " move=", a.get("move"), " dead=", a.dead, " jump=", a.jump, " menu=", app.menu.visible)
	key(KEY_I, false)
	print("delta=", a.p - before)
	app.queue_free()
	await process_frame
	quit(0)
