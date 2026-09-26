extends SceneTree

const Sim = preload("res://scripts/simulation.gd")
var failures := 0
var count := 0

func check(ok: bool, label: String) -> void:
	count += 1
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func _init() -> void:
	var s = Sim.new(); s.coop = "local"
	s.step(0.016, [{"fire": true, "aim": Vector2.RIGHT}, {}])
	check(s.bullets.size() == 1, "shooting in refuge creates a projectile")
	var origin: Vector2 = s.bullets[0].p
	s.step(0.1, [{}, {}])
	check(s.bullets.size() == 1 and s.bullets[0].p.x > origin.x + 60, "refuge projectile advances through main step (reported freeze)")
	for i in range(300): s.step(1.0 / 60, [{}, {}])
	check(s.bullets.is_empty(), "refuge bullets expire or collide, no permanent frozen bullets")
	var a: Dictionary = s.actors[0]
	a.p = Vector2(450, 450); a.facing = Vector2.RIGHT
	s.step_actor(a, {"dodge": true}, 1.0 / 60)
	for i in range(10): s.step_actor(a, {}, 1.0 / 60)
	check(a.p.x > 600, "dash moves more than 150px without holding a direction")
	check(a.dodge_cd > 0, "dash has a cooldown")
	a.dodge = 0; a.dodge_cd = 0; a.p = Vector2(450, 450)
	s.step_actor(a, {"dodge": true, "move": Vector2(-1, -1).normalized()}, 0.016)
	s.step_actor(a, {"move": Vector2.RIGHT}, 0.05)
	check(a.p.x < 450 and a.p.y < 450, "diagonal dash keeps launch direction when keys change")
	a.dodge = 0; a.p = Vector2(450, 450); a.aim = Vector2.RIGHT
	var frame_before: float = a.step
	s.step_actor(a, {"move": Vector2.UP, "aim": Vector2.RIGHT}, 0.1)
	check(a.facing == Vector2.RIGHT, "body faces the mouse aim while walking (no weapon crossing the character)")
	check(a.step > frame_before + 1, "walking advances the step animation")
	s.step_actor(a, {"move": Vector2.UP, "aim": Vector2.LEFT, "fire": true}, 0.016)
	check(a.facing == Vector2.LEFT, "body always faces the aim direction, so the weapon never crosses through the character")
	a.p = Vector2(450, 450); a.dodge = 0; a.armor = false
	s.step_actor(a, {"move": Vector2.RIGHT}, 0.5)
	check(is_equal_approx(a.p.x, 610), "unarmored movement increased to 320px/s")
	s.start_arena()
	s.step_enemies(0.81)
	check(s.mode == "arena" and s.enemies.size() >= 5, "test arena materializes enemies after portal")
	s.coop = "ai"
	var initial_enemy_count: int = s.enemies.size()
	var ai_shot_seen := false
	var enemy_damage_seen := false
	var enemy_shot_seen := false
	for i in range(360):
		s.step(1.0 / 60, [{}, {}])
		for bullet in s.bullets:
			if bullet.owner == 1: ai_shot_seen = true
			if bullet.team == 1: enemy_shot_seen = true
		for enemy in s.enemies:
			if enemy.hp < enemy.max: enemy_damage_seen = true
	check(ai_shot_seen, "companion AI fires without player attacking")
	check(enemy_damage_seen or s.enemies.size() < initial_enemy_count, "companion projectiles damage enemies in actual simulation")
	check(enemy_shot_seen, "arena enemies retaliate with moving bullets")
	s.coop = "local"; s.enemies.clear(); var wave: int = s.arena_wave
	for i in range(190): s.step(1.0 / 60, [{}, {}])
	check(s.arena_wave == wave + 1 and not s.enemies.is_empty(), "arena replenishes enemies after wave clear")
	print("COMBAT REGRESSION: ", count, " checks, ", failures, " failures")
	quit(1 if failures else 0)
