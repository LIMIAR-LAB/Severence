extends SceneTree

# P10 — baús (abertura animada) e cápsula de retorno (entrar → fechar → partir).
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	var a: Dictionary = s.actors[0]

	# ── Baú: abertura registra o instante pra animar a tampa ──
	var chest := {}
	for c in s.chests:
		if not c.get("secret", false): chest = c; break
	check(not chest.is_empty(), "existe baú comum na run")
	s.keys = 1
	a.p = chest.p + Vector2(40, 0)
	s.interact(a)
	check(chest.open and chest.has("t"), "baú abre e guarda o instante da abertura")
	check(s.effects.any(func(fx): return fx.kind == "chest_burst"), "abertura dispara a explosão de loot")
	check(s.pickups.any(func(p): return p.kind == "fuel"), "baú solta o galão")
	check(s.keys == 0, "abrir consome a chave")

	# ── Cápsula selada sem o chefe morto ──
	var ext: Vector2 = s.run_points.extraction
	a.p = ext + Vector2(80, 0)
	s.boss_dead = false
	s.interact(a)
	check(s.extract_state == "", "sem chefe morto a cápsula não arma")

	# ── Embarque: entra → fecha → parte → relatório ──
	s.boss_dead = true
	s.interact(a)
	check(s.extract_state == "enter" and s.extract_actor == 0, "interação inicia o embarque")
	check(a.get("extracting", false), "herói embarcando não responde a comandos")
	check(s.summary_seq == 0, "relatório espera a sequência")

	var p0: Vector2 = a.p
	for _i in range(8): s.step(0.1, [{}])
	check(s.extract_state in ["close", "launch"], "sequência avança após a entrada")
	check(a.p.distance_to(ext + s.EXTRACT_INSIDE) < p0.distance_to(ext + s.EXTRACT_INSIDE) or s.extract_state != "enter", "herói anda até dentro da cápsula")

	for _i in range(8): s.step(0.1, [{}])
	check(s.extract_state in ["launch", ""], "porta fecha e a cápsula parte")
	if s.extract_state == "launch": check(a.get("hidden", false), "herói some dentro da cápsula na partida")

	for _i in range(12): s.step(0.1, [{}])
	check(s.extract_state == "" and s.mode == "hub", "partida conclui o retorno ao Refúgio")
	check(s.summary_seq == 1 and str(s.last_run_summary.get("outcome", "")) == "victory", "relatório de vitória abre uma vez")
	check(s.last_run_summary.get("nucleus", 0) == 1, "núcleo contabilizado")

	# ── Snapshot durante o embarque preserva a fase ──
	var s2 := Expedition.new()
	s2.coop = "solo"; s2.start_run(1941)
	s2.boss_dead = true
	s2.actors[0].p = s2.run_points.extraction + Vector2(60, 0)
	s2.interact(s2.actors[0])
	for _i in range(4): s2.step(0.1, [{}])
	var snap := s2.snapshot()
	var s3 := Expedition.new(); s3.apply_snapshot(snap)
	check(s3.extract_state == s2.extract_state and s3.extract_actor == 0, "snapshot carrega a sequência de extração")
	for _i in range(30): s3.step(0.1, [{}])
	check(s3.mode == "hub" and str(s3.last_run_summary.get("outcome", "")) == "victory", "sequência restaurada conclui a vitória")

	print("CAPSULE_P10_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
