extends SceneTree

# P6 — robobolas, LOBO-9, robô capturável dos Guindastes, aliado e missão.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	var a: Dictionary = s.actors[0]

	var lobo_list := s.enemies.filter(func(e): return e.kind == "lobo")
	var sent_list := s.enemies.filter(func(e): return e.kind == "golem")
	check(lobo_list.size() == 1, "LOBO-9 spawnado no Mercado")
	check(sent_list.size() == 1, "Golem spawnado nos Guindastes")
	var sent: Dictionary = sent_list[0]
	check(sent.get("dormant", false) and sent.get("capturable", false), "Golem dorme até o jogador chegar")

	var p0: Vector2 = sent.p
	s.step_enemies(0.5)
	check(sent.p == p0, "dormente não se move com jogador longe")

	a.p = sent.p + Vector2(120, 0)
	s.step_enemies(0.016)
	check(not sent.get("dormant", false) and sent.get("alerted", false), "Golem acorda quando o jogador se aproxima")
	# isola a sala para provar que só o Golem segura os portões
	s.enemies = s.enemies.filter(func(e): return e.room != "cranes" or e == sent)
	check(s.room_threats("cranes") == 1, "Golem acordado conta como ameaça (portões fecham)")

	sent.hp = 0
	s.step_enemies(0.016)
	check(s.enemies.has(sent) and sent.get("stunned", false) and sent.hp > 0, "derrotado fica atordoado em vez de morrer")
	check(s.room_threats("cranes") == 0, "atordoado não tranca os portões")
	var stunned_pos: Vector2 = sent.p
	s.step_enemies(0.5)
	check(sent.p == stunned_pos, "atordoado não se move")

	s.robobolas = 0; a.p = sent.p + Vector2(40, 0); s.interact(a)
	check(s.enemies.has(sent) and s.captured_robots.is_empty(), "sem robobola a captura falha")

	var lobo: Dictionary = lobo_list[0]
	lobo.hp = 0
	s.step_enemies(0.016)
	check(s.robobolas == 2, "LOBO-9 entrega as 2 robobolas")
	check(s.message.contains("bolas do LOBO"), "Marty faz a piada das bolas do LOBO")

	s.interact(a)
	check(not s.enemies.has(sent) and "golem" in s.captured_robots and s.robobolas == 1, "robobola captura o Golem")
	check(s.story_flags.get("missao_robo") == "invocar", "missão avança: invocar o robô capturado")

	check("golem" in s.owned_robot_ids(0), "robô capturado entra no arsenal")
	a.selected_robot = "golem"
	check(s.summon_robot(a), "C invoca o Golem capturado")
	check(s.spectres[0].get("kind") == "golem" and s.spectres[0].hp == s.GOLEM_HP, "aliado usa stats do Golem")
	check(s.story_flags.get("missao_robo") == "concluida", "invocar conclui a missão seguinte")
	s.spawn_enemy(a.p + Vector2(200, 0), "cult")
	s.spectres[0].shot = 0
	s.step_spectres(0.016)
	check(s.bullets.any(func(b): return b.team == 0 and b.damage == s.GOLEM_SHOT.damage), "Golem aliado dispara tiro pesado")
	check(not s.toggle_fusion(a), "Golem não funde (fusão é do Spectre)")

	var snap := s.snapshot()
	var s2 := Expedition.new(); s2.apply_snapshot(snap)
	check(s2.robobolas == 1 and s2.captured_robots == ["golem"], "snapshot preserva robobolas e capturados")
	print("ROBOBOLA_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
