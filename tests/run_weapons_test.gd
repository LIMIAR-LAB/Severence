extends SceneTree

# 0.21: arma local à expedição, munição finita e economia temporal.
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func _init() -> void:
	var sim := Expedition.new()
	sim.coop = "solo"; sim.materials = 4; sim.start_run(1941)
	var marty: Dictionary = sim.actors[0]
	check(sim.weapon_of(marty) == "pistol", "arma inicial é infinita e equipada")
	var bazooka: Dictionary = sim.pickups.filter(func(p): return p.kind == "weapon" and p.weapon == "bazooka")[0]
	check(sim.clear_at(bazooka.p, 11), "bazuca está em piso acessível na chegada")
	marty.p = bazooka.p; sim.collect_pickups()
	check(sim.weapon_of(marty) == "bazooka" and marty.run_weapons.bazooka == 30, "encontra bazuca com trinta foguetes")
	sim.toggle_run_weapon(marty)
	check(sim.weapon_of(marty) == "pistol" and marty.run_weapons.bazooka == 30, "troca preserva munição")
	for _i in range(sim.available_weapons(marty).size() - 1): sim.toggle_run_weapon(marty)
	check(sim.weapon_of(marty) == "bazooka", "troca reequipa arma da RUN")
	for _i in range(30):
		marty.shot = 0; sim.fire_actor(marty)
	check(sim.weapon_of(marty) == "bazooka" and marty.run_weapons.bazooka == 0, "arma vazia permanece equipada")
	var shots: int = sim.bullets.size()
	marty.shot = 0; sim.fire_actor(marty)
	check(sim.bullets.size() == shots, "arma vazia não dispara")
	var empty_restore := Expedition.new(); empty_restore.apply_snapshot(sim.snapshot().duplicate(true))
	check(empty_restore.weapon_of(empty_restore.actors[0]) == "bazooka" and empty_restore.actors[0].run_weapons.bazooka == 0, "save preserva seleção vazia sem gerar munição")
	for _i in range(sim.available_weapons(marty).size()): sim.toggle_run_weapon(marty)
	check(sim.weapon_of(marty) == "bazooka", "Q reequipa arma vazia")
	check(not sim.select_run_weapon(0, "invalid"), "seleção recusa arma não possuída")
	var blast := Expedition.new()
	blast.coop = "solo"; blast.start_arena(); blast.enemies.clear(); blast.bullets.clear(); blast.effects.clear(); blast.pending_spawns.clear()
	blast.spawn_enemy(Vector2(500, 500), "brute")
	blast.spawn_enemy(Vector2(550, 500), "brute")
	blast.add_bullet(Vector2(440, 500), Vector2.RIGHT, 0, 48, 390, 10, 0, "p_rocket")
	blast.step_bullets(0.15)
	check(blast.enemies[0].hp < blast.enemies[0].max and blast.enemies[1].hp < blast.enemies[1].max, "foguete atinge alvo e inimigo vizinho")
	check(blast.effects.any(func(fx): return fx.kind == "explosion"), "foguete cria explosão visível")
	sim.pickups.append({"p": marty.p, "kind": "ammo", "weapon": "bazooka", "ammo": 2})
	sim.collect_pickups()
	check(sim.weapon_of(marty) == "bazooka" and marty.run_weapons.bazooka == 2, "munição rara reativa bazuca")
	var restored := Expedition.new()
	restored.apply_snapshot(sim.snapshot().duplicate(true))
	check(restored.weapon_of(restored.actors[0]) == "bazooka" and restored.actors[0].run_weapons.bazooka == 2, "salvar a RUN preserva arma e munição")
	sim.money = 99; sim.keys = 5; sim.materials = 7; sim.make_hub()
	check(sim.money == 0 and sim.keys == 0 and sim.materials == 7, "ouro e chaves ficam na época; fragmentos retornam")
	sim.start_run(1942)
	check(sim.weapon_of(sim.actors[0]) == "pistol" and sim.actors[0].run_weapons.is_empty(), "nova RUN reinicia o arsenal temporário")
	check(sim.KEY_DROP_CHANCE < sim.AMMO_DROP_CHANCE and sim.KEY_DROP_CHANCE <= 0.05, "chaves são mais raras que munição")
	var close := Expedition.new(); close.coop = "solo"; close.start_arena(); close.enemies.clear(); close.obstacles.clear()
	var shooter: Dictionary = close.actors[0]; shooter.p = Vector2(500, 500); shooter.aim = Vector2.RIGHT; shooter.facing = Vector2.RIGHT
	close.grant_run_weapon(shooter, "bazooka", 2)
	close.spawn_enemy(Vector2(545,500), "brute"); var target: Dictionary = close.enemies[-1]
	close.fire_actor(shooter)
	check(target.hp < target.max and close.effects.any(func(fx): return fx.kind == "explosion"), "bazuca acerta e explode no inimigo entre ator e cano")
	close.enemies.clear(); close.bullets.clear(); close.effects.clear(); close.obstacles = [Rect2(520,450,3,100)]
	close.spawn_enemy(Vector2(545,500), "brute"); target = close.enemies[-1]
	close.fire_actor(shooter)
	check(target.hp == target.max, "varredura do cano não acerta inimigo atrás de parede fina")
	print("failures=", failures)
	quit(failures)
