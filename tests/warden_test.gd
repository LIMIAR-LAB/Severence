extends SceneTree

# Warden — mini-boss das Docas: 420 HP, telegrafa uma carga e arremete.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.bullets.clear()
	var a: Dictionary = s.actors[0]
	a.hp = s.max_hp(); a.p = Vector2(400, 500)

	s.spawn_enemy(Vector2(700, 500), "warden")
	var w: Dictionary = s.enemies[0]
	check(w.hp == 420.0 and w.max == 420.0, "Warden nasce com 420 de vida")

	w.cd = 0
	s.step_enemies(0.016)
	check(w.get("attack_state", "hunt") == "warning", "perto do alvo o Warden telegrafa a carga")
	check(w.get("charge_dir", Vector2.ZERO).x < -0.9, "carga mira na direção do jogador")

	var hp0: float = a.hp
	for i in range(42): s.step_enemies(0.016)  # ~0.67s: warning (0.55s) acaba, charge começa
	check(w.attack_state == "charge", "após o aviso o Warden arremete")
	for i in range(60):
		s.step_enemies(0.016)
		a.hp = s.max_hp(); a.dead = false     # não deixa o ator morrer no teste
	check(w.attack_state in ["recover", "hunt"], "carga termina em recuperação")
	check(w.p.distance_to(Vector2(700, 500)) > 150, "a carga desloca o Warden")

	# Hitbox maior do warden: projétil acerta a 48px+raio
	s.bullets.clear()
	s.add_bullet(w.p + Vector2(55, 0), Vector2.LEFT, 0, 10, 300, 4, 0)
	var hp1: float = w.hp
	s.step_bullets(0.05)
	check(w.hp < hp1, "projétil acerta o Warden no raio ampliado")

	print("WARDEN_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
