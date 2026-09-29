extends SceneTree

const Sim := preload("res://scripts/simulation.gd")
var failures := 0

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	var sim = Sim.new()
	sim.coop = "solo"; sim.start_run(1941)
	sim.tick_time = 82.0; sim.money = 77; sim.visited = [sim.rooms[0].id, sim.rooms[1].id]
	sim.run_stats.kills = 12; sim.run_stats.damage_dealt = 987.0; sim.run_stats.max_streak = 6
	sim.actors[0].hurt = 0.0; sim.actors[0].hp = 10.0
	sim.damage_actor(sim.actors[0], 9999.0, "fish", "harpoon")
	check(sim.actors[0].dead and sim.run_stats.fatal_source == "fish", "fatal fish hit is attributed")
	sim.step(0.016, [{}, {}])
	var result: Dictionary = sim.last_run_summary
	check(sim.mode == "hub" and sim.summary_seq == 1, "defeat captures summary before refuge")
	check(result.time >= 82.0 and result.kills == 12 and result.damage_dealt == 987, "captured telemetry survives hub reset")
	check(result.fatal_source == "fish" and "peixe" in result.obituary.to_lower(), "fish obituary is contextual")
	var first_line: String = result.obituary
	var repeat = Sim.new(); repeat.coop = "solo"; repeat.start_run(1941)
	check(repeat.obituary_for("fish", "harpoon") == first_line, "obituary variation is seed deterministic")

	var victory = Sim.new(); victory.coop = "solo"; victory.start_run(77)
	var before_materials: int = victory.materials
	victory.boss_dead = true; victory.actors[0].p = victory.DOCKS.POINTS.extraction
	victory.interact(victory.actors[0])
	check(victory.last_run_summary.outcome == "victory" and victory.last_run_summary.progress == 100, "extraction creates victory summary")
	check(victory.materials == before_materials + 3 and victory.last_run_summary.fragments == 3, "victory reward granted and reported once")
	check(victory.last_run_summary.nucleus == 1 and victory.last_run_summary.clears == 1, "nucleus and clear count are captured accurately")
	var rewarded: int = victory.materials
	victory.interact(victory.actors[0])
	check(victory.materials == rewarded, "refuge interaction cannot duplicate victory reward")

	var copy = Sim.new(); copy.apply_snapshot(victory.snapshot())
	check(copy.summary_seq == victory.summary_seq and copy.last_run_summary == victory.last_run_summary, "summary round-trips through network/save snapshot")
	var legacy = Sim.new(); legacy.apply_snapshot({"mode": "hub"})
	check(not legacy.run_stats.is_empty(), "legacy snapshot initializes summary telemetry safely")

	var edge = Sim.new(); edge.coop = "solo"; edge.start_run(99)
	var secret = edge.rooms.filter(func(room): return room.get("kind", "") == "secret")
	edge.visited = [secret[0].id] if not secret.is_empty() else []
	check(edge.run_progress_percent("death") == 0, "secret room does not inflate ordinary exploration progress")
	edge.streak = 9; edge.streak_t = 1.0; edge.start_run(100)
	check(edge.streak == 0 and edge.streak_t == 0.0, "new expedition resets combo state")
	edge.tick_time = 0.0
	var fast_grade := edge.run_grade("death", 70)
	edge.tick_time = 3000.0
	var slow_grade := edge.run_grade("death", 70)
	check(fast_grade != slow_grade, "grade deterministically accounts for run time")
	edge.run_stats.damage_dealt = 0.0
	edge.hurt_enemy({"hp": 20.0}, 10.0, false)
	check(edge.run_stats.damage_dealt == 0.0, "enemy-owned damage is not credited to the player")
	print("RUN_SUMMARY_TEST failures=", failures)
	quit(1 if failures else 0)
