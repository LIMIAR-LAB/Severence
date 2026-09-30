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
	check(sim.weapon_of(marty) == "bazooka" and marty.run_weapons.bazooka == 6, "encontra bazuca com seis foguetes")
	sim.toggle_run_weapon(marty)
	check(sim.weapon_of(marty) == "pistol" and marty.run_weapons.bazooka == 6, "troca preserva munição")
	sim.toggle_run_weapon(marty)
	check(sim.weapon_of(marty) == "bazooka", "troca reequipa arma da RUN")
	for _i in range(6):
		marty.shot = 0; sim.fire_actor(marty)
	check(sim.weapon_of(marty) == "pistol" and marty.run_weapons.bazooka == 0, "munição acaba e arma básica volta")
	var shots: int = sim.bullets.size()
	marty.shot = 0; sim.fire_actor(marty)
	check(sim.bullets.size() == shots + 1, "arma básica continua disparando sem munição")
	var blast := Expedition.new()
	blast.coop = "solo"; blast.start_arena(); blast.enemies.clear(); blast.bullets.clear(); blast.effects.clear(); blast.pending_spawns.clear()
	blast.spawn_enemy(Vector2(500, 500), "brute")
	blast.spawn_enemy(Vector2(550, 500), "brute")
	blast.add_bullet(Vector2(440, 500), Vector2.RIGHT, 0, 48, 390, 10, 0, "p_rocket")
	blast.step_bullets(0.15)
	check(blast.enemies[0].hp < blast.enemies[0].max and blast.enemies[1].hp < blast.enemies[1].max, "foguete atinge alvo e inimigo vizinho")
	check(blast.effects.any(func(fx): return fx.kind == "explosion"), "foguete cria explosão visível")
	sim.pickups.append({"p": marty.p, "kind": "ammo", "weapon": "bazooka", "ammo": 2})
	sim.collect_pickups(); sim.toggle_run_weapon(marty)
	check(sim.weapon_of(marty) == "bazooka" and marty.run_weapons.bazooka == 2, "munição rara reativa bazuca")
	var restored := Expedition.new()
	restored.apply_snapshot(sim.snapshot().duplicate(true))
	check(restored.weapon_of(restored.actors[0]) == "bazooka" and restored.actors[0].run_weapons.bazooka == 2, "salvar a RUN preserva arma e munição")
	sim.money = 99; sim.keys = 5; sim.materials = 7; sim.make_hub()
	check(sim.money == 0 and sim.keys == 0 and sim.materials == 7, "ouro e chaves ficam na época; fragmentos retornam")
	sim.start_run(1942)
	check(sim.weapon_of(sim.actors[0]) == "pistol" and sim.actors[0].run_weapons.is_empty(), "nova RUN reinicia o arsenal temporário")
	check(sim.KEY_DROP_CHANCE < sim.AMMO_DROP_CHANCE and sim.KEY_DROP_CHANCE <= 0.05, "chaves são mais raras que munição")
	print("failures=", failures)
	quit(failures)
