extends SceneTree

# Inimigos das Docas, o Almirante das Profundezas e as roupas do Marty.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func arena() -> Expedition:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.bullets.clear()
	s.actors[0].p = Vector2(300, 500)
	return s

func fired_kinds(s: Expedition) -> Array:
	var kinds := []
	for b in s.bullets:
		if b.team == 1 and not kinds.has(b.kind): kinds.append(b.kind)
	return kinds

func _init() -> void:
	for pair in [["cult", "magenta"], ["fish", "harpoon"], ["brute", "violet"], ["crawler", "acid"]]:
		var s := arena()
		s.spawn_enemy(Vector2(460, 500), pair[0]); s.enemies[0].cd = 0
		s.step_enemies(0.016)
		check(fired_kinds(s).has(pair[1]), pair[0] + " dispara " + pair[1])
	var s := arena()
	s.spawn_enemy(Vector2(700, 500), "brute"); s.enemies[0].cd = 0; s.step_enemies(0.016)
	check(s.bullets.size() == 6, "Soldado Possuído dispara leque de 6")
	# Rastejante se divide ao morrer
	s = arena(); s.spawn_enemy(Vector2(700, 500), "crawler"); s.enemies[0].hp = 0
	s.step_enemies(0.016)
	check(s.enemies.size() == 2 and s.enemies.all(func(e): return e.kind == "crawler_small"), "Rastejante vira duas bolhas menores")
	check(s.effects.any(func(fx): return fx.kind == "corpse"), "morte deixa pose de queda")
	# Arpão prende
	s = arena(); var a: Dictionary = s.actors[0]
	s.add_bullet(a.p - Vector2(40, 0), Vector2.RIGHT, 1, 18, 600, 6, -1, "harpoon")
	s.step_bullets(0.1)
	check(a.snare > 0, "arpão prende o Marty")
	var start: Vector2 = a.p
	s.step_actor(a, {"move": Vector2.RIGHT}, 0.1)
	check(a.p.x - start.x < 15, "preso pelo arpão anda devagar")
	# Disfarce de Londres reduz a percepção
	s = arena(); a = s.actors[0]
	s.spawn_enemy(a.p + Vector2(450, 0), "cult"); s.enemies[0].cd = 0
	a.outfit = "espiao"; s.step_enemies(0.016)
	check(s.bullets.is_empty(), "Espião: cultista a 450px não percebe")
	a.outfit = "padrao"; s.enemies[0].cd = 0; s.enemies[0]["los_t"] = 0.0; s.step_enemies(0.016)
	check(not s.bullets.is_empty(), "roupa Padrão: cultista a 450px ataca")
	# Mecânico bate mais forte
	s = arena(); a = s.actors[0]; a.outfit = "mecanico"; a.aim = Vector2.RIGHT
	s.spawn_enemy(a.p + Vector2(40, 0), "brute"); s.melee(a)
	check(s.enemies[0].hp == 118.75 - 46, "Mecânico: golpe corpo a corpo mais forte")
	# O Almirante das Profundezas
	s = arena(); s.actors[0].p = Vector2(600, 600)
	s.spawn_enemy(Vector2(600, 300), "boss"); var boss: Dictionary = s.enemies[0]
	check(boss.max == 600, "Almirante tem 600 de vida")
	boss.cd = 0; s.step_enemies(0.016)
	check(fired_kinds(s) == ["orb"] and s.bullets.size() == 16, "fase 1: anel radial de 16 orbes")
	boss.hp = 300; boss.cd = 0; s.bullets.clear(); s.step_enemies(0.016)
	check(boss.stage == 2 and s.effects.any(func(fx): return fx.kind == "weapon_drop"), "fase 2: larga uma arma")
	var saw_cannon := false; var saw_spin := false
	for n in range(900):
		s.step_enemies(0.016); s.step_bullets(0.016)
		if boss.spin > 0: saw_spin = true
		if fired_kinds(s).has("cannon"): saw_cannon = true
		s.actors[0].hp = 100; s.actors[0].dead = false
	check(saw_spin and saw_cannon, "fase 2: espiral e bala de canhão carregada")
	boss.hp = 100; boss.cd = 0; s.bullets.clear(); s.actors[0].p = Vector2(600, 520)
	var seen := {}
	for n in range(400):
		s.step_enemies(0.016)
		for k in fired_kinds(s): seen[k] = true
		s.actors[0].hp = 100; s.actors[0].dead = false
	check(boss.stage == 3 and seen.has("ink") and seen.has("harpoon") and seen.has("flame"), "fúria: tinta, arpão e chamas")
	boss.hp = 0; s.step_enemies(0.016)
	check(s.boss_dead and s.effects.any(func(fx): return fx.kind == "corpse" and fx.enemy == "boss"), "derrota: afunda e libera a extração")
	# Enrage: uma luta longa e passiva não pode travar para sempre.
	s = arena(); s.actors[0].p = Vector2(600, 600)
	s.spawn_enemy(Vector2(600, 300), "boss"); boss = s.enemies[0]
	boss.fight_time = s.BOSS_ENRAGE_TIME - 0.05; boss.cd = 0
	check(not boss.enraged, "Almirante começa sem furor")
	s.step_enemies(0.1)
	check(boss.enraged, "furor ativa após BOSS_ENRAGE_TIME de combate")
	var normal_cd: float = 1.1
	check(boss.cd < normal_cd * s.BOSS_ENRAGE_SCALE + 0.001, "furor encolhe a cadência de ataque da fase 1")
	print("ENEMY_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
