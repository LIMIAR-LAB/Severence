extends SceneTree

const Simulation := preload("res://scripts/simulation.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func count_key(sim: RefCounted, key: String) -> int:
	return sim.audio_events.filter(func(e): return e.key == key).size()

func _init() -> void:
	var sim := Simulation.new()
	sim.coop = "solo"; sim.start_arena()
	sim.enemies.clear(); sim.pending_spawns.clear()
	var a: Dictionary = sim.actors[0]
	a.p = Vector2(300, 500)
	sim.step_actor(a, {"fire": true}, 0.01)
	check(count_key(sim, "pistol") == 1, "successful shot emits one pistol cue")
	sim.step_actor(a, {"fire": true}, 0.01)
	check(count_key(sim, "pistol") == 1, "cooldown does not emit another cue")
	a.outfit = "mecanico"; a.shot = 0
	sim.step_actor(a, {"fire": true}, 0.01)
	check(count_key(sim, "shotgun") == 1, "shotgun emits once for all pellets")
	sim.grant_run_weapon(a, "bazooka", 1); a.run_weapon = "bazooka"; a.shot = 0
	sim.step_actor(a, {"fire": true}, 0.01)
	a.shot = 0
	var bullet_count: int = sim.bullets.size()
	sim.step_actor(a, {"fire": true}, 0.01)
	check(count_key(sim, "bazooka") == 1 and count_key(sim, "dry_fire") == 1 and sim.bullets.size() == bullet_count, "empty bazooka clicks without shot")
	sim.audio_events.clear(); a.armor = true; a.armor_time = 10; a.shot = 0
	sim.step_actor(a, {"fire": true}, 0.01)
	check(sim.audio_events.size() == 1 and count_key(sim, "sword") == 1, "sword input emits only sword cue")
	sim.audio_events.clear(); a.armor = false; a.hurt = 0
	sim.damage_actor(a, 10)
	sim.damage_actor(a, 10)
	check(count_key(sim, "hit") == 1, "invulnerable damage does not repeat hit cue")
	sim.spawn_enemy(Vector2(500, 500), "guard")
	var guard: Dictionary = sim.enemies[0]
	guard.cd = 0; guard.alerted = true
	for _i in range(365): sim.step_enemies(0.01)
	check(count_key(sim, "enemy_guard") == Simulation.GUARD_SHOTS, "guard emits one cue per discrete shot")
	sim.audio_events.clear()
	var rng_before: int = sim.rng.state
	for _i in range(100): sim.emit_audio("pistol", a.p)
	check(sim.rng.state == rng_before, "audio does not consume gameplay RNG")
	check(sim.audio_events.size() == 64 and sim.audio_events[-1].id == sim.audio_sequence, "event ring bounded at 64")
	var saved: Dictionary = sim.snapshot().duplicate(true)
	var clone := Simulation.new()
	clone.apply_snapshot(saved)
	check(clone.audio_events == sim.audio_events and clone.audio_sequence == sim.audio_sequence, "snapshot carries cue IDs and positions")
	clone.apply_snapshot({"audio_sequence": 2, "audio_events": [{"id": 2, "key": "pistol", "p": Vector2.ZERO, "time": 0.0}]})
	check(clone.audio_sequence == 2 and clone.audio_events[0].id == 2, "new host replaces higher local sequence")
	var sequence: int = sim.audio_sequence
	sim.make_hub()
	check(sim.audio_events.is_empty() and sim.audio_sequence == sequence, "scene change clears ring without resetting IDs")
	sim.emit_audio("jump", Vector2.ZERO)
	saved.erase("audio_events"); saved.erase("audio_sequence")
	sim.apply_snapshot(saved)
	check(sim.audio_events.is_empty() and sim.audio_sequence == sequence + 1, "legacy save clears stale cues and preserves IDs")
	clone.apply_snapshot({"audio_events": [null, {"id": "bad"}], "audio_sequence": "bad"})
	check(clone.audio_events.is_empty(), "malformed audio snapshot ignored")
	print("failures=", failures)
	quit(failures)
