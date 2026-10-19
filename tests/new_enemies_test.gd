extends SceneTree

# 0.15: Bomber, Guard e ondas temáticas com portal atrasado.
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)

func arena() -> Expedition:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.bullets.clear(); s.effects.clear(); s.pending_spawns.clear()
	s.actors[0].p = Vector2(300, 500)
	return s

func _init() -> void:
	# Bomber morto explode e a explosão acende o fusível de um barril próximo.
	var s := arena()
	s.obstacles = [Rect2(485, 485, 30, 30)]
	s.obstacle_kinds = ["barrel_explosive"]
	s.obstacle_hp = [16.0]
	s.spawn_enemy(Vector2(470, 500), "bomber")
	s.enemies[0].hp = 0
	s.step_enemies(0.016)
	check(s.combat_zones.size() == 1 and s.effects.all(func(fx): return fx.kind != "explosion"), "Bomber morto anuncia antes de explodir")
	s.step_enemies(0.66); s.step_enemies(0.016)
	check(s.effects.any(func(fx): return fx.kind == "explosion"), "Bomber morto cria explosão após aviso")
	check(not s.fuses.is_empty(), "explosão do Bomber acende barril explosivo")

	# Guard rebate tiro frontal, mas um tiro pelas costas causa dano.
	s = arena(); s.spawn_enemy(Vector2(500, 500), "guard")
	var guard: Dictionary = s.enemies[0]
	guard.face = Vector2.LEFT; guard["alerted"] = true
	var hp_before: float = guard.hp
	s.add_bullet(Vector2(475, 500), Vector2.RIGHT, 0, 30, 200, 4, 0, "p_pistol")
	s.step_enemies(0.016); s.step_bullets(0.05)
	check(guard.hp == hp_before and s.effects.any(func(fx): return fx.kind == "impact"), "Guard rebate tiro frontal sem perder vida")
	s.bullets.clear(); guard.face = Vector2.LEFT
	s.add_bullet(Vector2(525, 500), Vector2.LEFT, 0, 100, 200, 4, 0, "p_pistol")
	s.step_enemies(0.016); s.step_bullets(0.05)
	check(is_equal_approx(guard.hp, hp_before - 100), "Guard recebe todo o dano do tiro pelas costas")

	# A primeira onda de elite (5) mostra portais e materializa um Warden após 0,8s.
	s = arena(); s.arena_wave = 4; s.spawn_arena_wave()
	check(s.enemies.is_empty() and not s.pending_spawns.is_empty(), "onda aguarda portais antes do spawn")
	check(s.effects.any(func(fx): return fx.kind == "spawn_portal"), "onda cria telegraph de portal")
	s.step_enemies(0.79)
	check(s.enemies.is_empty(), "inimigos não surgem antes de 0,8s")
	s.step_enemies(0.02)
	check(s.enemies.any(func(e): return e.kind == "warden"), "onda 5 inclui Warden elite")
	check(s.enemies.all(func(e): return e.max > 0 and e.damage_scale > 1.0), "onda aplica escala de vida e dano")

	# Trocar de modo cancela qualquer materialização ainda pendente.
	s = arena(); s.arena_wave = 3; s.spawn_arena_wave()
	check(not s.pending_spawns.is_empty(), "arena possui spawns aguardando portal")
	s.make_hub(); s.step_enemies(1.0)
	check(s.pending_spawns.is_empty() and s.enemies.is_empty(), "spawns da arena não vazam para o Refúgio")

	print("NEW_ENEMIES_TESTS failures=", failures)
	quit(1 if failures else 0)
