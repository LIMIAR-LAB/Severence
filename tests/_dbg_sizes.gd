extends SceneTree

const CellarPlatforms = preload("res://scripts/scenarios/cellar_platforms.gd")
var app: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in range(n): await physics_frame

func bench(label: String, times: int, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	for i in times: f.call()
	var total := (Time.get_ticks_usec() - t0) / 1000.0
	print("%-34s x%-4d total=%7.2fms  cada=%.3fms" % [label, times, total, total / times])

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await frames(3)
	app.start_single()
	app.sim.start_run(1941)
	await frames(10)
	var sim = app.sim
	app.playing = false
	var dt := 1.0 / 60.0
	var a0: Dictionary = sim.actors[0]
	var cmd := {"move": Vector2.ZERO, "aim": Vector2.RIGHT, "fire": false}

	bench("step_actor idle", 600, func(): sim.step_actor(a0, cmd, dt))
	bench("ai_input", 300, func(): sim.ai_input())
	bench("step_spectres", 600, func(): sim.step_spectres(dt))
	bench("step_dog", 600, func(): sim.step_dog(dt))
	bench("step_hazards", 600, func(): sim.step_hazards(dt))
	bench("step_gates", 600, func(): sim.step_gates(dt))
	bench("step_fuses", 600, func(): sim.step_fuses(dt))
	bench("step_extraction", 600, func(): sim.step_extraction(dt))
	bench("step_bridge", 600, func(): sim.step_bridge(dt))
	bench("collect_pickups", 600, func(): sim.collect_pickups())
	bench("step_bullets (vazio)", 600, func(): sim.step_bullets(dt))
	bench("recover_enemy_room (1 inimigo)", 300, func(): if not sim.enemies.is_empty(): sim.recover_enemy_room(sim.enemies[0]))
	bench("water_at", 2000, func(): CellarPlatforms.water_at(sim, a0.p, 10))
	bench("room_at", 2000, func(): sim.room_at(a0.p))
	print("SIZES DONE")
	app.queue_free()
	await process_frame
	quit(0)
