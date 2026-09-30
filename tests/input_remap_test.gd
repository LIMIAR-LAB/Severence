extends SceneTree

var app: Node
var failures := 0
var settings_path := "user://settings.json"
var settings_backup := ""

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok: print("PASS REMAP: ", label)
	else: failures += 1; push_error(label)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = pressed
	Input.parse_input_event(event)

func frames(n: int) -> void:
	for i in range(n): await physics_frame

func run() -> void:
	if FileAccess.file_exists(settings_path): settings_backup = FileAccess.get_file_as_string(settings_path)
	app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await frames(3)

	check(int(app.key_binds["up"]) == KEY_W and int(app.key_binds["right"]) == KEY_D and int(app.key_binds["fusion"]) == KEY_G, "default binds match WASD/F/G layout")
	check(int(app.key_binds["robot_switch"]) == KEY_V, "robot switch defaults to V")
	check(app.rebind_key("up", KEY_I) and int(app.key_binds["up"]) == KEY_I, "rebind up to I applies")
	check(not app.rebind_key("down", KEY_I), "rebind to a key already in use is rejected")
	check(not app.rebind_key("jump", KEY_TAB) and int(app.key_binds["jump"]) == KEY_SPACE, "reserved keys are rejected")
	check(not app.rebind_key("bogus", KEY_Z), "unknown action is rejected")

	app.start_solo()
	await frames(60)
	app.sim.set_unlocks(["padrao", "titan", "spectre"]); app.sim.actors[0].selected_robot = "titan"
	key(KEY_V, true); await frames(2); key(KEY_V, false); await frames(2)
	check(app.sim.actors[0].selected_robot == "spectre", "mapped V cycles the live owned robot")
	var before: Vector2 = app.sim.actors[0].p
	key(KEY_I, true); await frames(12); key(KEY_I, false)
	check(app.sim.actors[0].p.y < before.y - 40, "rebound key drives movement in game")

	# persistência: arquivo corrompido deve cair nos defaults, válido deve aplicar
	app.key_binds = app.KEY_BIND_DEFAULTS.duplicate()
	var f := FileAccess.open(settings_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"armor": false, "outfit": "padrao", "gun": 0, "robot": "titan", "volume": 70,
		"key_binds": {"up": "lixo", "down": -5, "left": KEY_TAB, "jump": KEY_J, "summon": KEY_J}}))
	f.close()
	app.load_settings()
	check(int(app.key_binds["up"]) == KEY_W, "non-numeric saved bind falls back to default")
	check(int(app.key_binds["down"]) == KEY_S, "negative saved bind falls back to default")
	check(int(app.key_binds["left"]) == KEY_A, "reserved saved bind falls back to default")
	check(int(app.key_binds["jump"]) == KEY_J, "valid saved bind loads")
	check(int(app.key_binds["summon"]) == KEY_C, "duplicate saved bind falls back to default")

	app.key_binds = app.KEY_BIND_DEFAULTS.duplicate(); app.save_settings()
	check(int(app.key_binds["melee"]) == KEY_F and int(app.key_binds["dash"]) == KEY_SHIFT, "reset restores defaults")

	if settings_backup != "":
		f = FileAccess.open(settings_path, FileAccess.WRITE); f.store_string(settings_backup); f.close()
		app.load_settings()
	print("INPUT REMAP TEST: ", failures, " failures")
	app.queue_free()
	await process_frame
	await process_frame
	await preload("res://tests/support/scene_cleanup.gd").finish(self)
	quit(1 if failures else 0)
