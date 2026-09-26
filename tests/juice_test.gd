extends SceneTree

# 0.15 — Juice de combate: hitstop, números de dano, knockback, kill streak,
# slow-mo clutch e shockwave de pouso do Titan.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func dmg_nums(s) -> Array:
	return s.effects.filter(func(fx): return fx.kind == "dmg_num")

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.bullets.clear(); s.effects.clear()
	var a: Dictionary = s.actors[0]
	a.p = Vector2(200, 500)

	# Bala acerta: número de dano + knockback leve
	s.spawn_enemy(Vector2(400, 500), "crawler")
	var e: Dictionary = s.enemies[0]
	var x0: float = e.p.x
	s.add_bullet(e.p + Vector2(20, 0), Vector2.LEFT, 0, 10, 300, 4, 0)
	s.step_bullets(0.05)
	check(not dmg_nums(s).is_empty(), "acerto de bala gera número de dano")
	check(e.p.x < x0, "bala empurra o inimigo levemente")

	# Abate: hitstop + streak + moedas com bônus
	e.hp = 1
	s.add_bullet(e.p + Vector2(10, 0), Vector2.LEFT, 0, 10, 300, 4, 0)
	s.step_bullets(0.05)
	var m0: int = s.money
	s.step_enemies(0.016)
	check(s.streak == 1 and s.streak_t > 0, "abate inicia a sequência")
	check(s.money == m0 + 4, "primeiro abate vale 4 moedas")
	check(s.hitstop > 0, "abate dispara hitstop")

	s.spawn_enemy(Vector2(500, 500), "fish")
	var e2: Dictionary = s.enemies[0]
	e2.hp = 1
	s.add_bullet(e2.p + Vector2(10, 0), Vector2.LEFT, 0, 10, 300, 4, 0)
	s.step_bullets(0.05)
	s.step_enemies(0.016)
	check(s.streak == 2, "sequência acumula")
	check(s.money == m0 + 4 + 5, "segundo abate na sequência vale +1")

	# Streak zera quando o timer expira
	s.streak_t = 0.01
	s.step(0.05, [{}, {}])
	check(s.streak == 0, "sequência expira sem abates")

	# Elite: hitstop maior (mata direto — testa o caminho de morte)
	s.enemies.clear(); s.hitstop = 0
	s.spawn_enemy(Vector2(600, 500), "warden")
	s.enemies[0].hp = -1
	s.step_enemies(0.016)
	check(s.hitstop >= 0.08, "abate de elite gera hitstop forte")

	# Clutch: meio coração com inimigo vivo → slow-mo uma vez
	s.enemies.clear(); s.spawn_enemy(Vector2(700, 500), "cult")
	s.enemies[0].cd = 99
	a.hp = s.HEART * 0.5; a.hurt = 0
	s.step(0.016, [{}, {}])
	check(s.clutch_t > 0 and s.clutch_cd > 0, "meio coração dispara slow-mo clutch")

	# Pouso do Titan: shockwave fere inimigos próximos
	var s2 := Expedition.new()
	s2.coop = "solo"; s2.start_arena()
	s2.enemies.clear()
	var a2: Dictionary = s2.actors[0]
	a2.p = s2.mech.p - Vector2(30, 0)
	s2.interact(a2); wait_cockpit(s2, a2)
	check(a2.mech, "embarque no Titan")
	s2.spawn_enemy(a2.p + Vector2(50, 0), "cult")
	var hp0: float = s2.enemies[0].hp
	a2.jump = 0.01
	s2.step_actor(a2, {}, 0.02)
	check(s2.enemies[0].hp < hp0, "pouso do Titan causa dano em área")
	check(s2.hitstop > 0, "pouso do Titan dispara hitstop")

	print("JUICE_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)

func wait_cockpit(s, a: Dictionary) -> void:
	if s.mech.get("cockpit_t", 0.0) > 0: s.step_actor(a, {}, 1.3)
