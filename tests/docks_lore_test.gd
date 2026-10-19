extends SceneTree

# Lore das Docas (Passo 1): Guardião da Maré, altar da Ordem, 1ª vitória garantida.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_run(7)
	var a: Dictionary = s.actors[0]

	check(s.obituary_for("warden").contains("Guardião da Maré"), "obituário do Warden usa o nome Guardião da Maré")

	var wardens := s.enemies.filter(func(e): return e.kind == "warden")
	check(wardens.size() == 1, "expedição nasce com um Guardião da Maré")
	var w: Dictionary = wardens[0]
	a.p = w.p + Vector2(300, 0)
	s.step(0.016, [])
	check(s.warden_intro_seen, "chegar perto do Guardião dispara o reveal")
	check(str(s.message).contains("GUARDIÃO DA MARÉ"), "reveal nomeia o Guardião da Maré")

	var altar: Vector2 = s.altar_position()
	check(altar != Vector2.INF, "a capela tem um altar interativo")
	var materials0: int = s.materials
	a.p = altar
	s.interact(a)
	check(s.story_flags.get("ordem_pista", false), "ler o altar entrega a pista da Ordem da Maré Negra")
	check(s.materials == materials0 + 1, "a pista do altar rende +1 fragmento na primeira leitura")
	check(str(s.message).contains("ORDEM DA MARÉ NEGRA"), "a pista nomeia a Ordem da Maré Negra")
	s.interact(a)
	check(s.materials == materials0 + 1, "reler o altar não repete a recompensa")

	s.boss_dead = true
	s.enemies = s.enemies.filter(func(e): return e.kind != "boss")
	a.p = s.run_points.extraction
	s.interact(a)
	for _i in range(30): s.step(0.1, [{}])   # P10: a cápsula embarca antes do relatório
	check(s.story_flags.get("peca_titan", false), "1ª vitória garante a peça TITAN-01")
	check(s.story_flags.get("simbolo_ordem", false), "1ª vitória garante o selo da Ordem")
	check(bool(s.last_run_summary.get("story_beat", false)), "relatório da 1ª vitória marca o story beat")
	check(str(s.last_run_summary.get("obituary", "")).contains("TITAN-01"), "nota de extração revela a peça TITAN-01")
	check(str(s.last_run_summary.get("obituary", "")).contains("ORDEM DA MARÉ NEGRA"), "nota de extração revela a Ordem")

	# Segunda expedição: flags persistem, mas o beat não se repete.
	s.start_run(8)
	a = s.actors[0]
	check(not s.warden_intro_seen and not s.first_victory_beat, "reveals de expedição reiniciam a cada run")
	check(s.story_flags.get("peca_titan", false), "story_flags sobrevivem entre expedições")
	s.boss_dead = true
	a.p = s.run_points.extraction
	s.interact(a)
	for _i in range(30): s.step(0.1, [{}])
	check(not bool(s.last_run_summary.get("story_beat", false)), "vitórias seguintes não repetem o story beat")
	check(not str(s.last_run_summary.get("obituary", "")).contains("TITAN-01"), "relatório comum não repete a revelação")

	# Snapshot preserva as meta flags (sync co-op e save de expedição).
	var snap: Dictionary = s.snapshot()
	var s2 := Expedition.new()
	s2.apply_snapshot(snap)
	check(s2.story_flags.get("peca_titan", false) and s2.story_flags.get("ordem_pista", false), "snapshot preserva as flags de lore")

	print("DOCKS_LORE_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
