extends SceneTree

# P7 — missões, diálogos, culto, NPCs resgatados e as três armas novas.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	var a: Dictionary = s.actors[0]

	# ── Três armas novas na tabela central ──
	for w in ["mosquete", "tesla", "arpoador"]:
		check(s.WEAPONS.has(w), "arma nova registrada: " + w)
	check(s.WEAPON_NAMES.get("tesla", "") != "", "armas novas têm nome de UI")

	# ── Munição genérica de run ──
	s.grant_run_weapon(a, "tesla", 9)
	check("tesla" in s.available_weapons(a), "arma nova entra no ciclo Q/RB")
	check(s.select_run_weapon(0, "tesla"), "select_run_weapon aceita arma nova")
	a.shot = 0; s.fire_actor(a)
	check(int(a.run_weapons.tesla) == 8, "arma nova consome carga genérica")
	check(s.bullets.any(func(b): return b.team == 0 and b.get("kind") == "p_wave"), "tesla dispara arco elétrico")
	for _i in range(8): a.shot = 0; s.fire_actor(a)
	var shots: int = s.bullets.size()
	a.shot = 0; s.fire_actor(a)
	check(s.bullets.size() == shots and s.message.contains("SEM CARGAS"), "arma vazia avisa e não dispara")

	# ── Sobrevivente aparece ao limpar a sala ──
	var warehouse := s.room_by_id("warehouse")
	check(not warehouse.is_empty(), "sala Armazém existe no mapa")
	var spawned := false
	if s.enemies.filter(func(e): return e.room == "warehouse").is_empty():
		s.spawn_enemy(warehouse.r.get_center(), "cult"); s.enemies[-1].room = "warehouse"; spawned = true
	warehouse.locked = true
	for e in s.enemies:
		if e.room == "warehouse": e.hp = 0
	s.step_enemies(0.016)
	s.step_gates(0.016)
	check(warehouse.get("cleared", false), "sala trancada limpa destrava os portões")
	var npcs := s.rescue_npcs.filter(func(n): return n.room == "warehouse")
	check(npcs.size() == 1, "sobrevivente surge após sala limpa" + (" (spawn forçado)" if spawned else ""))
	var npc: Dictionary = npcs[0]

	# Sala sem inimigos nesta seed: o sobrevivente aparece mesmo sem luta.
	var s_empty := Expedition.new(); s_empty.coop = "solo"; s_empty.start_run(1941)
	var empty_room := ""
	for npc_def in s_empty.RESCUE_NPCS:
		if s_empty.enemies.filter(func(e): return e.room == npc_def.room).is_empty(): empty_room = npc_def.room; break
	if empty_room != "":
		s_empty.actors[0].p = s_empty.room_by_id(empty_room).r.get_center()
		s_empty.step_gates(0.016)
		check(s_empty.rescue_npcs.any(func(n): return n.room == empty_room), "sala sem ameaças libera o sobrevivente ao entrar")

	# ── Interação: agradecimento, arma e missão do cachorro ──
	var pickups_before: int = s.pickups.size()
	a.p = npc.p + Vector2(30, 0)
	s.interact(a)
	check(npc.thanked, "primeira interação marca agradecimento")
	check(s.pickups.size() == pickups_before + 1 and s.pickups[-1].get("weapon") == "mosquete", "NPC entrega MOSQUETE 1901")
	check(s.story_flags.get("missao_cachorro") == "procurar", "NPC apresenta a missão do cachorro")
	s.interact(a)
	check(s.pickups.size() == pickups_before + 1, "recompensa não se repete")

	# ── Arma entregue funciona ──
	a.p = s.pickups[-1].p; s.collect_pickups()
	check("mosquete" in s.available_weapons(a), "mosquete coletado entra no arsenal da run")

	# ── Mestre Coral / culto ──
	check(s.story_quest == 0, "missão do culto começa zerada")
	a.p = s.story_npc_position()
	s.interact(a)
	check(s.story_quest == 1 and s.message.contains("Mestre Coral"), "Mestre Coral apresenta a Ordem")
	check(s.dialogue_queue.any(func(d): return String(d).contains("Adega")), "fila de diálogo pede a purificação da Adega")

	# ── Diário de missões ──
	var missions := s.missions_list()
	check(missions.any(func(m): return m.title == "O NÚCLEO DO ALMIRANTE"), "missão principal listada")
	check(missions.any(func(m): return m.title == "O RITUAL DA ORDEM" and not m.done), "missão do culto em andamento")
	check(missions.any(func(m): return m.title == "O BOM GAROTO"), "missão do cachorro listada")
	var ritual: Dictionary = missions.filter(func(m): return m.title == "O RITUAL DA ORDEM")[0]
	s.story_quest = 2
	check(s.missions_list().filter(func(m): return m.title == "O RITUAL DA ORDEM")[0].done, "missão concluída marca done")

	# ── Snapshot preserva os NPCs ──
	var snap := s.snapshot()
	var s2 := Expedition.new(); s2.apply_snapshot(snap)
	check(s2.rescue_npcs.size() == s.rescue_npcs.size() and s2.rescue_npcs[0].get("thanked", false), "snapshot preserva sobreviventes e agradecimentos")

	print("MISSIONS_P7_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
