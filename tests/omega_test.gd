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
	s.spawn_enemy(a.p + Vector2(120, 0), "cult")
	s.add_bullet(a.p + Vector2(150, 0), Vector2.LEFT, 1, 10, 10, 5)
	s.step_actor(a, {"armor": true}, 0.016)
	check(a.armor and a.transform > 0 and s.effects.any(func(fx): return fx.kind == "transform"), "ligar a Ômega dispara a transformação")
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
	check(s.weapon_of(a) == "omega_sword", "Ômega troca a arma pela Lâmina Ômega")
	check(not s.equip(0, "espiao", "titan") and a.outfit == "padrao", "com armadura ativa não troca uniforme/arma")
	check(s.ARMORS.omega.speed > s.UNIFORMS.espiao.speed, "Ômega é mais rápida até que o Espião")
	# combo de espada: 3 cortes, o 3º solta a onda
	s.enemies.clear(); s.bullets.clear()
	s.spawn_enemy(a.p + Vector2(60, 0), "brute"); var e: Dictionary = s.enemies[0]
	a.aim = Vector2.RIGHT; a.shot = 0
	s.step_actor(a, {"fire": true, "aim": Vector2.RIGHT}, 0.016)
	check(e.hp == e.max - 38 and s.effects.any(func(fx): return fx.kind == "sword"), "1º corte da espada: 38 e rastro")
	e.hp = 999; e.max = 999
	for n in range(2):
		a.shot = 0; s.step_actor(a, {"fire": true, "aim": Vector2.RIGHT}, 0.016)
	check(s.bullets.any(func(b): return b.kind == "p_wave" and b.pierce == 5), "3º corte solta onda perfurante")
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
	a.outfit = "mecanico"; check(s.weapon_of(a) == "shotgun", "Mecânico usa escopeta")
	a.outfit = "espiao"; check(s.weapon_of(a) == "smg", "Espião usa submetralhadora")
	check(s.UNIFORMS.espiao.speed > s.UNIFORMS.padrao.speed and s.UNIFORMS.mecanico.melee > s.UNIFORMS.padrao.melee, "Espião mais rápido, Mecânico mais forte")
	# Baú
	s = Expedition.new(); s.coop = "solo"; s.start_run(1941)
	a = s.actors[0]; a.p = s.chests[0].p; s.keys = 1
	s.interact(a)
	check(s.chests[0].open and s.chests[0].has("t") and s.effects.any(func(fx): return fx.kind == "chest_burst"), "baú abre com animação e explosão de itens")
	check(a.armor_cd == 0 and not a.armor, "baú recarrega a armadura (sem vestir sozinho)")
	# Titan: turbo segurando Shift e pisadas
	s = Expedition.new(); s.coop = "solo"; s.start_arena(); s.enemies.clear()
	a = s.actors[0]; a.p = s.mech.p - Vector2(40, 0); s.interact(a)
	var p0: Vector2 = a.p
	s.step_actor(a, {"move": Vector2.RIGHT}, 0.1)
	var normal: float = a.p.x - p0.x
	p0 = a.p
	s.step_actor(a, {"move": Vector2.RIGHT, "boost": true}, 0.1)
	check(a.p.x - p0.x > normal * 1.8 and a.boost < 1.0 and s.mech.boosting, "Titan: Shift segurado ativa o turbo e gasta energia")
	for n in range(40): s.step_actor(a, {"move": Vector2.UP}, 0.05)
	check(s.effects.any(func(fx): return fx.kind == "stomp"), "Titan: pisadas pesadas geram poeira/tremor")
	print("OMEGA_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
