extends SceneTree

# Transformação Ômega, canhão de plasma e abertura de baú.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena(); s.enemies.clear(); s.bullets.clear()
	var a: Dictionary = s.actors[0]
	a.p = Vector2(400, 500); a.armor = false
	check(is_equal_approx(s.ARMORS.omega.duration, 300.0), "Ômega permanece ativa por 5 minutos")
	s.spawn_enemy(a.p + Vector2(120, 0), "cult")
	s.add_bullet(a.p + Vector2(150, 0), Vector2.LEFT, 1, 10, 10, 5)
	s.step_actor(a, {"armor": true}, 0.016)
	check(a.armor and a.transform > 0 and s.effects.any(func(fx): return fx.kind == "transform"), "ligar a Ômega dispara a transformação")
	check(is_equal_approx(a.armor_time, 300.0), "ativação carrega 5 minutos completos de uso")
	var hp: float = a.hp
	s.damage_actor(a, 50)
	check(a.hp == hp, "invulnerável durante a transformação")
	var start: Vector2 = a.p
	s.step_actor(a, {"move": Vector2.RIGHT}, 0.1)
	check(a.p == start, "fica parado enquanto carrega")
	for n in range(60): s.step_actor(a, {}, 0.016)
	check(s.effects.any(func(fx): return fx.kind == "shockwave"), "onda de choque sai no meio da transformação")
	check(s.enemies[0].hp < s.enemies[0].max, "onda de choque fere inimigos próximos")
	check(s.bullets.all(func(b): return b.team == 0 or b.life <= 0), "onda de choque apaga projéteis inimigos")
	for n in range(60): s.step_actor(a, {}, 0.016)
	check(a.transform == 0, "transformação termina")
	check(s.weapon_of(a) == "omega_orb", "Ômega equipa esferas temporárias")
	check(not s.equip(0, "espiao", "titan") and a.outfit == "padrao", "com armadura ativa não troca uniforme/arma")
	check(s.ARMORS.omega.speed > s.UNIFORMS.espiao.speed, "Ômega é mais rápida até que o Espião")
	# combo de espada: 3 cortes, o 3º solta a onda
	s.enemies.clear(); s.bullets.clear()
	s.spawn_enemy(a.p + Vector2(60, 0), "brute"); var e: Dictionary = s.enemies[0]
	a.aim = Vector2.RIGHT; a.shot = 0
	s.step_actor(a, {"fire": true, "aim": Vector2.RIGHT}, 0.016)
	check(e.hp == e.max - 38 and s.bullets.any(func(b): return b.kind == "p_omega"), "1º corte da espada: 38 e rastro")
	e.hp = 999; e.max = 999
	for n in range(2):
		a.shot = 0; s.step_actor(a, {"fire": true, "aim": Vector2.RIGHT}, 0.016)
	check(s.bullets.any(func(b): return b.kind == "p_omega" and b.pierce == 5), "3º corte solta onda perfurante")
	check(e.hp == 999 - 38 - 64, "combo: 38 + 64 no finalizador")
	hp = a.hp; a.hurt = 0
	s.damage_actor(a, 20)
	check(is_equal_approx(a.hp, hp) and a.shield < 30, "Ômega: o escudo absorve o golpe")
	# duração e recarga
	a.armor_time = 0.01; s.step_actor(a, {}, 0.05)
	check(not a.armor and a.armor_cd > 59, "armadura acaba sozinha e entra em recarga de 60s")
	s.message = ""; s.step_actor(a, {"armor": true}, 0.016)
	check(not a.armor and s.message.contains("recarregando"), "não veste de novo durante a recarga")
	check(s.weapon_of(a) == "pistol", "Padrão volta ao blaster")
	# Especial contínuo e descarga ao recolher a armadura.
	s = Expedition.new(); s.coop = "solo"; s.start_arena(); s.enemies.clear(); s.obstacles.clear()
	a = s.actors[0]; a.p = Vector2(400, 500); s.set_armor(a, true); a.transform = 0.0; a.armor_time = 300.0
	s.spawn_enemy(a.p + Vector2(150, 0), "brute")
	var beam_target: Dictionary = s.enemies[0]
	var beam_hp: float = beam_target.hp
	s.step_actor(a, {"special": true, "aim": Vector2.RIGHT, "fire": true}, 0.5)
	check(a.beam_time > 0 and beam_target.hp < beam_hp and a.shot == 0, "raio segurado causa dano sem disparar a espada")
	s.step_actor(a, {}, 0.016)
	check(a.beam_time == 0 and a.beam_cd > 29, "soltar o raio inicia recarga de 30s")
	beam_hp = beam_target.hp
	s.step_actor(a, {"special": true}, 0.016)
	check(a.beam_time == 0 and beam_target.hp == beam_hp, "raio não reinicia durante a recarga")
	s.visible_world_rect = Rect2(Vector2(200, 300), Vector2(400, 400))
	s.spawn_enemy(a.p + Vector2(150, 40), "brute")
	s.spawn_enemy(a.p + Vector2(0, 250), "brute")
	var visible_enemy: Dictionary = s.enemies[1]
	var outside_enemy: Dictionary = s.enemies[2]
	var visible_hp: float = visible_enemy.hp
	var outside_hp: float = outside_enemy.hp
	s.set_armor(a, false)
	check(visible_enemy.hp < visible_hp and outside_enemy.hp == outside_hp, "recolher Ômega atinge somente inimigos próximos na tela")
	check(s.effects.any(func(fx): return fx.kind == "recall_light"), "descarga de luz desenha feixes até os alvos")
	a.outfit = "mecanico"; check(s.weapon_of(a) == "pistol", "Mecânico conserva arma equipada")
	a.outfit = "espiao"; check(s.weapon_of(a) == "pistol", "Espião conserva arma equipada")
	check(s.UNIFORMS.espiao.speed > s.UNIFORMS.padrao.speed and s.UNIFORMS.mecanico.melee > s.UNIFORMS.padrao.melee, "Espião mais rápido, Mecânico mais forte")
	# Baú
	s = Expedition.new(); s.coop = "solo"; s.start_run(1941)
	a = s.actors[0]
	check(a.armor_cd == 0 and not a.armor, "expedição começa com a Ômega carregada")
	a.p = s.chests[0].p; s.keys = 1
	s.interact(a); wait_cockpit(s, a)
	check(s.chests[0].open and s.chests[0].has("t") and s.effects.any(func(fx): return fx.kind == "chest_burst"), "baú abre com animação e explosão de itens")
	check(a.armor_cd == 0 and not a.armor, "baú recarrega a armadura (sem vestir sozinho)")
	# Titan: turbo segurando Shift e pisadas
	s = Expedition.new(); s.coop = "solo"; s.start_arena(); s.enemies.clear()
	a = s.actors[0]; a.p = s.mech.p - Vector2(40, 0); s.interact(a); wait_cockpit(s, a)
	var p0: Vector2 = a.p
	s.step_actor(a, {"move": Vector2.RIGHT}, 0.1)
	var normal: float = a.p.x - p0.x
	p0 = a.p
	s.step_actor(a, {"move": Vector2.RIGHT, "boost": true}, 0.1)
	check(a.p.x - p0.x > normal * 1.8 and a.boost < 1.0 and s.mech.boosting, "Titan: Shift segurado ativa o turbo e gasta energia")
	for n in range(40): s.step_actor(a, {"move": Vector2.UP}, 0.05)
	check(s.effects.any(func(fx): return fx.kind == "stomp"), "Titan: pisadas pesadas geram poeira/tremor")
	# Teleporte Ômega: Shift+direção pisca e deixa sombra; Shift parado volta.
	s = Expedition.new(); s.coop = "solo"; s.start_arena(); s.enemies.clear(); s.obstacles.clear()
	a = s.actors[0]; a.p = Vector2(600, 500); s.set_armor(a, true); a.transform = 0.0; a.armor_time = 300.0
	var origin: Vector2 = a.p
	s.step_actor(a, {"dodge": true, "move": Vector2.RIGHT}, 0.016)
	check(a.p.x > origin.x + 200 and a.shadows.size() == 1, "Ômega: Shift+direção teleporta ~320px e deixa sombra na origem")
	check(a.invuln > 0 and a.dodge_cd > 0.4, "teleporte dá i-frames e entra em recarga de 0.55s")
	var land: Vector2 = a.p
	s.step_actor(a, {}, 0.016)
	check(a.p == land, "teleporte não desliza depois de chegar")
	check(a.shadows[0].p == origin, "sombra fica exatamente no ponto de origem")
	for n in range(3): # esgota: máximo 3 sombras vivas
		a.invuln = 0; a.dodge_cd = 0; s.step_actor(a, {"dodge": true, "move": Vector2.RIGHT}, 0.016)
	check(a.shadows.size() == 3, "no máximo 3 sombras acumuladas")
	# volta em cadeia: cada Shift parado retorna à próxima sombra, até esgotar todas
	var back_chain: Array = [a.shadows[2].p, a.shadows[1].p, a.shadows[0].p]
	for i in range(3):
		a.invuln = 0; a.dodge_cd = 0
		s.step_actor(a, {"dodge": true, "move": Vector2.ZERO}, 0.016)
		check(a.p == back_chain[i] and a.shadows.size() == 2 - i, "Shift parado volta pelas sombras em cadeia (%d/3)" % (i + 1))
		s.step_actor(a, {}, 0.016)
		check(a.p == back_chain[i], "retorno não desliza: fica parado exatamente na sombra")
	check(a.shadows.is_empty(), "as 3 sombras foram consumidas na volta")
	# sombra expira depois de 4s
	a.shadows = [{"p": a.p, "t": s.tick_time}, {"p": a.p, "t": s.tick_time - 5.0}]
	check(s.live_shadows(a).size() == 1, "sombra desaparece após 4 segundos")
	a.shadows = []; a.dodge = 0; a.dodge_cd = 0
	var before_return: Vector2 = a.p
	s.step_actor(a, {"dodge": true, "move": Vector2.ZERO}, 0.016)
	check(a.p == before_return and a.shadows.is_empty(), "sem sombra viva, Shift parado não move")
	# sem armadura: esquiva comum, sem sombra
	s.set_armor(a, false); a.dodge = 0; a.dodge_cd = 0; a.p = Vector2(600, 500)
	s.step_actor(a, {"dodge": true, "move": Vector2.RIGHT}, 0.016)
	check(a.shadows.is_empty() and a.dodge > 0, "sem Ômega, esquiva normal não cria sombra")
	check(a.p == Vector2(600, 500) + Vector2.RIGHT * 900 * 0.016 or a.p.x > 600, "esquiva normal desliza em vez de teleportar")
	print("OMEGA_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)

func wait_cockpit(s, a: Dictionary) -> void:
	if s.mech.get("cockpit_t", 0.0) > 0: s.step_actor(a, {}, 1.3)
