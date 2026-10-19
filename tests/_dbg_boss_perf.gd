extends SceneTree

var app: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in range(n): await physics_frame

func avg(a: Array) -> float:
	var s := 0.0
	for v in a: s += v
	return s / maxf(1.0, a.size())

func mx(a: Array) -> float:
	var m := 0.0
	for v in a: m = maxf(m, v)
	return m

func sample(sim, seconds: float, label: String, fire: bool = false) -> void:
	var samples: Array = []
	var cmd := {"move": Vector2.ZERO, "aim": Vector2.RIGHT, "fire": fire}
	var idle := {}
	for i in range(int(60 * seconds)):
		sim.actors[0].hp = 999; sim.actors[0].dead = false
		var ts := Time.get_ticks_usec()
		sim.step(1.0 / 60.0, [cmd, idle])
		samples.append((Time.get_ticks_usec() - ts) / 1000.0)
	var alerted: int = sim.enemies.filter(func(e): return e.get("alerted", false)).size()
	print("%-28s enemies=%2d alert=%2d bullets=%3d effects=%3d zones=%2d pending=%2d  avg=%.2fms max=%.2fms" % [
		label, sim.enemies.size(), alerted, sim.bullets.size(), sim.effects.size(),
		sim.combat_zones.size(), sim.pending_spawns.size(), avg(samples), mx(samples)])

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await frames(3)
	app.start_single()
	app.sim.start_run(1941)
	await frames(10)
	var sim = app.sim
	app.playing = false
	var boss_room = sim.room_by_id("boss")

	sample(sim, 3, "A: sala de spawn")

	sim.actors[0].p = boss_room.r.get_center()
	sim.actors[1].p = boss_room.r.get_center() + Vector2(60, 0)
	sim.actors[1].active = true
	sample(sim, 8, "B: boss, mapa todo vivo")

	# deixa só o boss: isola o custo da população do mapa
	for e in sim.enemies:
		if e.kind != "boss": e.hp = 0
	sim.step(1.0 / 60.0, [{}, {}])
	sim.enemies = sim.enemies.filter(func(e): return e.hp > 0)
	sample(sim, 8, "C: só o boss vivo")

	for e in sim.enemies:
		if e.kind == "boss": e.hp = e.max * 0.25
	sample(sim, 10, "D: boss estágio 3 (rajadas)")

	sample(sim, 8, "E: estágio 3 + jogador atirando", true)

	print("BOSS PERF DONE")
	app.queue_free()
	await process_frame
	quit(0)
