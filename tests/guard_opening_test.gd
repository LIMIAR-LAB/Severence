extends SceneTree

# 0.20: o Guardião anuncia a rajada e pode ser atingido de frente enquanto ataca.
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func _init() -> void:
	var sim := Expedition.new()
	sim.coop = "solo"; sim.start_arena()
	sim.enemies.clear(); sim.bullets.clear(); sim.effects.clear(); sim.pending_spawns.clear()
	sim.actors[0].p = Vector2(300, 500)
	sim.spawn_enemy(Vector2(500, 500), "guard")
	var guard: Dictionary = sim.enemies[0]
	guard.cd = 0; guard["alerted"] = true
	sim.step_enemies(0.01)
	check(guard.combat == "warning" and guard.combat_t > 1.0, "preparação do Guardião é lenta")
	for _i in range(100): sim.step_enemies(0.01)
	check(guard.combat == "warning" and sim.bullets.is_empty(), "a preparação não dispara cedo")
	for _i in range(11): sim.step_enemies(0.01)
	check(guard.combat == "attack", "ataque abre a guarda")
	var enemy_shots := sim.bullets.filter(func(b): return b.team == 1).size()
	for _i in range(100): sim.step_enemies(0.01)
	check(sim.bullets.filter(func(b): return b.team == 1).size() >= enemy_shots + 2, "rajada continua durante a abertura")
	sim.bullets.clear()
	var hp_before: float = guard.hp
	sim.add_bullet(Vector2(475, 500), Vector2.RIGHT, 0, 30, 200, 4, 0, "p_pistol")
	sim.step_bullets(0.05)
	check(guard.hp < hp_before, "Marty básico causa dano frontal durante a rajada")
	for _i in range(140): sim.step_enemies(0.01)
	check(guard.combat == "recover", "escudo volta depois do ataque")
	print("failures=", failures)
	quit(failures)
