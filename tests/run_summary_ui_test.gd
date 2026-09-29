extends SceneTree

var failures := 0

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	app.start_single(); app.sim.start_run(1941)
	app.sim.last_run_summary = {"outcome": "death", "seed": 1941, "time": 1122.0, "progress": 73,
		"kills": 247, "damage_dealt": 48320, "damage_received": 2840, "max_streak": 36, "chests": 3,
		"scrap": 1240, "fragments": 38, "nucleus": 0, "clears": 2, "grade": "A", "fatal_source": "fish",
		"obituary": "O peixe mutante arrancou os seus olhos e comeu igual jujuba.", "side_complete": true, "secret_open": false}
	app.sim.summary_seq = 1; app.present_summary_if_needed()
	await process_frame; await process_frame
	check(app.menu.visible and app.menu.screen == "summary", "new result opens summary screen")
	var retry: Button = app.menu.content.find_child("SummaryNewRun", true, false)
	var refuge: Button = app.menu.content.find_child("SummaryRefuge", true, false)
	check(retry is Button and refuge is Button, "summary exposes both actions")
	check(app.menu.summary_texture("res://assets/ui/run_summary/definitely_missing.png") == null, "missing ornamental asset uses functional fallback")
	check(root.get_viewport().gui_get_focus_owner() == retry, "primary action receives controller focus")
	refuge.pressed.emit()
	check(not app.menu.visible and app.sim.mode == "run", "return action closes report without mutating captured state")
	app.menu.open("summary"); await process_frame
	retry = app.menu.content.find_child("SummaryNewRun", true, false)
	retry.pressed.emit()
	check(app.sim.mode == "run" and app.sim.last_run_summary.is_empty() and not app.menu.visible, "new expedition starts a fresh run")

	app.sim.last_run_summary = {"outcome": "death", "grade": "D", "fatal_source": "unknown", "obituary": "fallback"}
	app.playing = false; app.online = true; app.hosting = false; app.menu.open("summary"); await process_frame
	retry = app.menu.content.find_child("SummaryNewRun", true, false)
	check(retry.disabled and retry.text == "AGUARDANDO ANFITRIÃO", "online guest cannot restart run")
	var fresh_state: Dictionary = app.sim.snapshot(); fresh_state.mode = "run"; fresh_state.last_run_summary = {}
	app.receive_state(var_to_bytes(fresh_state).compress(FileAccess.COMPRESSION_DEFLATE))
	check(not app.menu.visible, "guest summary closes when host starts the next run")
	app.sim.last_run_summary = {"outcome": "death", "grade": "D", "fatal_source": "unknown", "obituary": "fallback"}
	app.menu.open("summary"); await process_frame
	var back := InputEventJoypadButton.new(); back.button_index = JOY_BUTTON_B; back.pressed = true
	app.menu._unhandled_input(back)
	check(not app.menu.visible, "controller back returns from summary to refuge")
	app.queue_free(); await process_frame
	print("RUN_SUMMARY_UI_TEST failures=", failures)
	quit(1 if failures else 0)
