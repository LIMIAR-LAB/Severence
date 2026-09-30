extends SceneTree

const Sim := preload("res://scripts/simulation.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else: print("PASS: ", label)

func fresh():
	var s := Sim.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.bullets.clear(); s.effects.clear(); s.obstacles.clear(); s.gate_blocks.clear()
	s.floors = [Rect2(-2000, -2000, 5000, 5000)]
	s.ob_grid_count = -1
	var a: Dictionary = s.actors[0]
	a.p = Vector2(400, 500); a.armor_type = "azul"
	s.toggle_armor(a)
	a.transform = 0.0
	return s

func enemy(s, offset: Vector2, hp: float = 300.0) -> Dictionary:
	s.spawn_enemy(s.actors[0].p + offset, "brute")
	var e: Dictionary = s.enemies[-1]
	e.hp = hp; e.max = hp
	return e

func _init() -> void:
	var s = fresh()
	var a: Dictionary = s.actors[0]
	check(s.is_blue_form(a) and s.outfit_of(a) == "azul" and a.shield == 30 and a.armor_time == 300, "Azul ativa por 300s com escudo e aparência próprios")
	check(s.message.contains("FORMA AZUL") and s.ARMORS.azul.speed == 430, "nome de ativação e velocidade da Forma Azul")
	var far := enemy(s, Vector2(300, 0))
	var near := enemy(s, Vector2(80, 0))
	var middle := enemy(s, Vector2(180, 0))
	s.step_actor(a, {"melee": true, "special": true}, 0.016)
	check(near.hp == 236 and far.hp == 300 and middle.hp == 300, "seleção do mais próximo em lista não ordenada; entradas simultâneas acertam uma vez")
	var claws: Array = s.effects.filter(func(fx): return fx.kind == "ground_claw")
	check(claws.size() == 1 and claws[0].p == near.p and claws[0].owner == a.id and claws[0].life == 0.65, "efeito imediato nasce nos pés do alvo e informa dono e duração")
	s.ground_claw(a); s.melee(a); s.sword_attack(a)
	check(near.hp == 236 and not s.effects.any(func(fx): return fx.kind in ["sword", "slash"]) and a.beam_time == 0, "recarga compartilhada bloqueia repetição, espada e raio não aparecem")
	s.step_actor(a, {"special": true}, 1.21)
	check(near.hp == 172, "garra volta a atacar após 1,2s")

	s = fresh(); a = s.actors[0]
	var dead := enemy(s, Vector2(10, 0), 0)
	var outside_range := enemy(s, Vector2(521, 0))
	var hidden := enemy(s, Vector2(0, -100))
	var blocked := enemy(s, Vector2(100, 0))
	var valid := enemy(s, Vector2(0, 200))
	s.visible_world_rect = Rect2(a.p - Vector2(20, 20), Vector2(600, 400))
	s.obstacles = [Rect2(a.p + Vector2(40, -15), Vector2(20, 30))]; s.ob_grid_count = -1
	s.ground_claw(a)
	check(valid.hp == 236 and dead.hp == 0 and outside_range.hp == 300 and hidden.hp == 300 and blocked.hp == 300, "ignora mortos, fora de alcance, fora da tela e atrás de obstáculos")
	valid.hp = 0; a.claw_cd = 0
	s.ground_claw(a)
	check(a.claw_cd == 0, "sem alvo elegível não consome recarga")
	s.visible_world_rect = Rect2(); s.obstacles.clear(); s.ob_grid_count = -1; s.enemies.clear()
	var below := enemy(s, Vector2(0, 450))
	s.ground_claw(a)
	check(below.hp == 300 and a.claw_cd == 0, "retângulo padrão exclui alvo fora da tela mesmo dentro do alcance")

	s = fresh(); a = s.actors[0]; near = enemy(s, Vector2(60, 0))
	for state in ["dead", "mech", "fused"]:
		a[state] = true; s.ground_claw(a); a[state] = false
	a.transform = 0.2; s.step_actor(a, {"melee": true, "special": true}, 0.01)
	check(near.hp == 300 and a.claw_cd == 0, "morte, robô, fusão e transformação em curso bloqueiam a garra")
	a.transform = 0
	var inventory_before: Dictionary = s.inventory_state.duplicate(true)
	check(not s.equip(0, a.outfit, a.selected_robot, "omega") and a.armor_type == "azul" and s.inventory_state == inventory_before, "troca da transformação ativa recusa antes de alterar inventário")
	s.step_actor(a, {"fire": true}, 0.01)
	check(a.shot > 0 and s.weapon_of(a) == "pistol", "arma de fogo independente continua disponível")
	near.hp = 300; a.armor_time = 0.01
	s.step_actor(a, {}, 0.02)
	check(not a.armor and a.armor_cd == 60 and near.hp == 300 and not s.effects.any(func(fx): return fx.kind == "recall_light"), "expiração da Azul inicia 60s de recarga sem descarga Ômega")
	check(s.message.contains("FORMA AZUL"), "mensagem de expiração identifica a forma correta")

	s = fresh(); a = s.actors[0]; near = enemy(s, Vector2(120, 0)); s.ground_claw(a)
	var saved: Dictionary = s.snapshot().duplicate(true)
	var restored := Sim.new(); restored.apply_snapshot(saved)
	check(restored.is_blue_form(restored.actors[0]) and restored.actors[0].claw_cd == 1.2 and restored.effects.any(func(fx): return fx.kind == "ground_claw"), "snapshot preserva forma, recarga e efeito da garra")
	saved.unlocked.erase("azul")
	for actor_state in saved.actors: actor_state.erase("claw_cd")
	restored.apply_snapshot(saved)
	check(restored.unlocked.get("azul", false) and restored.actors[0].claw_cd == 0, "save antigo recebe desbloqueio e recarga padrão da Azul")
	check(restored.inventory_state.stacks.get("forma_azul", 0) == 1, "save antigo também recebe o item selecionável da Forma Azul")
	saved.inventory_state.stacks.erase("forma_azul")
	saved.inventory_state.capacity = saved.inventory_state.stacks.size()
	var old_items: Dictionary = saved.inventory_state.stacks.duplicate()
	restored.apply_snapshot(saved)
	check(restored.inventory_state.stacks.size() == old_items.size() + 1 and old_items.keys().all(func(id): return restored.inventory_state.stacks.get(id) == old_items[id]), "migração com inventário cheio preserva todas as pilhas antigas")
	restored.start_run(1941)
	check(restored.actors[0].armor_type == "azul" and not restored.actors[0].armor, "iniciar expedição preserva a forma selecionada e a deixa pronta")
	check(s.loadout_stats("azul").any(func(row): return row[0] == "GARRA"), "estatísticas da seleção mostram a garra")
	for outcome in ["death", "victory"]:
		restored.finish_run(outcome)
		check(restored.mode == "hub" and restored.actors[0].armor_type == "azul", "retorno ao refúgio preserva seleção após " + outcome)
		restored.actors[0].p = Vector2(655, 215)
		restored.interact(restored.actors[0])
		check(restored.mode == "run" and restored.actors[0].armor_type == "azul", "portal do refúgio preserva Azul após " + outcome)

	s = fresh(); a = s.actors[0]; a.mech = true; a.aim = Vector2.RIGHT
	near = enemy(s, Vector2(60, 0))
	s.step_actor(a, {"melee": true}, 0.016)
	check(near.hp == 300 - s.MECH_PUNCH and a.claw_cd == 0, "Titan mantém seu soco quando piloto está na Forma Azul")

	s = fresh(); s.coop = "online"
	s.visible_world_rect = Rect2(0, 0, 800, 600)
	var guest: Dictionary = s.actors[1]
	guest.active = true; guest.dead = false; guest.p = Vector2(1800, 1000)
	guest.armor_type = "azul"; guest.armor = true; guest.armor_time = 300; guest.transform = 0
	s.spawn_enemy(guest.p + Vector2(70, 0), "brute")
	var guest_target: Dictionary = s.enemies[-1]
	guest_target.hp = 300
	s.step_actor(guest, {"special": true}, 0.016)
	check(guest_target.hp == 236 and guest.claw_cd > 0, "garra online do convidado independe da câmera do anfitrião")

	s = fresh(); a = s.actors[0]; a.armor_type = "omega"
	near = enemy(s, Vector2(60, 0)); a.aim = Vector2.RIGHT
	s.step_actor(a, {"melee": true}, 0.016)
	check(near.hp == 262 and s.effects.any(func(fx): return fx.kind == "sword"), "Ômega mantém espada de 38 de dano")
	near.hp = 300; s.step_actor(a, {"special": true, "aim": Vector2.RIGHT}, 0.1)
	check(a.beam_time > 0 and near.hp < 300, "Ômega mantém raio contínuo")
	var previous_hp: float = near.hp
	s.set_armor(a, false)
	check(near.hp == previous_hp - 40 and s.effects.any(func(fx): return fx.kind == "recall_light"), "Ômega mantém descarga ao guardar")
	print("BLUE_FORM_TESTS_DONE failures=", failures)
	quit(1 if failures else 0)
