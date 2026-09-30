extends SceneTree

var app: Node
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok: print("PASS BOSS INTRO: ", label)
	else: failures += 1; push_error(label)

func frames(count: int) -> void:
	for i in count: await physics_frame

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await frames(3)
	app.start_single()
	app.sim.start_run(1941)
	app.sim.actors[0].p = Vector2(3010, 1200)
	await frames(2)
	check(app.boss_intro.visible and app.sim.boss_intro_seen, "entrada da arena inicia a vinheta uma vez")
	var frozen_time: float = app.sim.tick_time
	await frames(4)
	check(is_equal_approx(app.sim.tick_time, frozen_time), "combate fica suspenso durante a vinheta")
	app.boss_intro.finish()
	await frames(3)
	check(not app.boss_intro.visible and app.sim.tick_time > frozen_time, "combate retoma após a vinheta")
	app.sim.start_run(1942)
	check(not app.sim.boss_intro_seen, "nova expedição libera a vinheta novamente")
	print("BOSS_INTRO_TEST failures=", failures)
	await preload("res://tests/support/scene_cleanup.gd").finish(self)
	quit(1 if failures else 0)
