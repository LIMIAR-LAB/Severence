extends SceneTree

# Titan 0.12: canhão pesado (bala grande, lenta, explode em área) e bomba em arco (R / LB).
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func pilot(s) -> Dictionary:
	var a: Dictionary = s.actors[0]
	s.mech.deployed = true; s.mech.p = a.p + Vector2(40, 0)
	a.p = s.mech.p - Vector2(30, 0); s.interact(a)
	s.step_actor(a, {}, 1.3) # aguarda a escotilha
	return a

func _init() -> void:
	var s = Expedition.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear()
	var a := pilot(s)
	check(a.mech, "Marty entra no Titan")
	a.aim = Vector2.RIGHT
	s.fire_actor(a)
	var shell: Dictionary = s.bullets[-1]
	check(shell.kind == "p_heavy" and shell.r >= 12 and shell.v.length() < 400, "canhão: bala grande e lenta")
	check(a.shot >= 0.8, "canhão: cadência pesada")
	# acerto direto + respingo
	s.bullets.clear()
	s.spawn_enemy(a.p + Vector2(200, 0), "brute"); s.spawn_enemy(a.p + Vector2(230, 50), "brute")
	var hp0: float = s.enemies[0].hp; var hp1: float = s.enemies[1].hp
	a.shot = 0; s.fire_actor(a)
	for n in range(90): s.step_bullets(1.0 / 60)
	check(s.enemies[0].hp <= hp0 - 70, "canhão: dano direto forte")
	check(s.enemies[1].hp < hp1, "canhão: explosão atinge quem está perto")
	check(s.effects.any(func(fx): return fx.kind == "explosion"), "canhão: efeito de explosão")
	# bomba
	s.enemies.clear(); s.bullets.clear(); s.effects.clear()
	s.spawn_enemy(a.p + a.aim * s.MECH_BOMB.range + Vector2(0, 40), "fish")
	var hp2: float = s.enemies[0].hp
	s.step_actor(a, {"armor": true, "aim": Vector2.RIGHT}, 1.0 / 60)
	check(s.bullets.size() == 1 and s.bullets[0].kind == "bomb", "R no Titan lança bomba (não veste armadura)")
	check(not a.armor, "armadura não é vestida dentro do Titan")
	s.step_actor(a, {"armor": true, "aim": Vector2.RIGHT}, 1.0 / 60)
	check(s.bullets.size() == 1, "bomba respeita a recarga")
	for n in range(70): s.step_bullets(1.0 / 60)
	check(s.bullets.is_empty(), "bomba explode ao cair")
	check(s.enemies[0].hp < hp2 - 40, "bomba causa dano em área")
	# parede entre a explosão e o inimigo bloqueia o respingo (canhão e bomba não atravessam obstáculos)
	s.enemies.clear(); s.bullets.clear(); s.effects.clear()
	var origin: Vector2 = a.p
	s.obstacles.append(Rect2(origin.x + 40, origin.y - 100, 20, 200))
	s.spawn_enemy(origin + Vector2(150, 0), "brute")
	var hp3: float = s.enemies[0].hp
	s.explode(origin, s.MECH_BOMB.radius, s.MECH_BOMB.damage, true)
	check(s.enemies[0].hp == hp3, "explosão não atravessa paredes")
	print("TITAN_WEAPONS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
