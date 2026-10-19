extends SceneTree

# P9 — morte dramática, aparência machucada e falas contextuais do Marty.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	var a: Dictionary = s.actors[0]

	# ── Bark de pouca vida (cruzando 1 coração) ──
	a.hp = s.HEART * 1.5
	s.damage_actor(a, 1.0, "cult", "orb")
	check(a.hp <= s.HEART, "dano deixa Marty no limite")
	check(s.message.contains("Marty:"), "vida baixa dispara fala do Marty")

	# ── Morte: fonte fatal registrada + cinemática abre, relatório espera ──
	a.hurt = 0.0   # limpa os i-frames do golpe anterior
	s.bark_cd = 0.0
	s.damage_actor(a, 999.0, "cult", "orb")
	check(a.dead and a.get("dead_t", -1.0) == 0.0, "morte zera dead_t")
	check(s.run_stats.fatal_source == "cult", "fonte fatal registrada")
	check(s.hitstop > 0.0, "morte causa micro-pausa de impacto")
	s.actors[1].hp = 0.0; s.actors[1].dead = true; s.actors[1]["dead_t"] = 0.0
	var seq_before: int = s.summary_seq
	s.step(0.016, [{}])
	check(s.death_seq_started and s.death_cine > 0.0, "morte total abre a cinemática")
	check(s.summary_seq == seq_before, "relatório NÃO abre durante a queda")
	check(s.mode == "run", "mundo da run continua vivo na cinemática")
	check(s.message.contains("Marty:"), "fala fatal contextual aparece")

	# ── A queda anima: dead_t avança com o tempo ──
	var t0: float = a.get("dead_t", 0.0)
	for _i in range(5): s.step(0.1, [{}])
	check(a.get("dead_t", 0.0) > t0 + 0.4, "dead_t avança durante a cinemática")
	check(s.mode == "run" and s.summary_seq == seq_before, "ainda sem relatório no meio da queda")

	# ── Fim da cinemática: relatório abre uma vez e volta ao Refúgio ──
	for _i in range(15): s.step(0.1, [{}])
	check(s.summary_seq == seq_before + 1, "relatório abre exatamente uma vez")
	check(s.mode == "hub", "depois da queda volta ao Refúgio")
	check(not s.death_seq_started and s.death_cine == 0.0, "cinemática encerrada limpa")
	check(str(s.last_run_summary.get("outcome", "")) == "death", "sumário marca morte")
	check(str(s.last_run_summary.get("fatal_source", "")) == "cult", "sumário guarda a fonte fatal")
	check(not s.actors[0].dead, "Marty ressurge no Refúgio")

	# ── Reanimar durante a queda cancela o fim da run ──
	var s7 := Expedition.new()
	s7.coop = "solo"; s7.start_run(1941)
	s7.actors[0].hp = 5.0   # dano quantizado: 999 só tira 1 coração — começa no limite
	s7.damage_actor(s7.actors[0], 999.0, "cult", "orb")
	s7.actors[1].hp = 0.0; s7.actors[1].dead = true
	s7.step(0.016, [{}])
	check(s7.death_seq_started, "segunda queda abre cinemática")
	s7.actors[0].dead = false; s7.actors[0].hp = s7.HEART
	s7.step(0.016, [{}])
	check(not s7.death_seq_started and s7.death_cine == 0.0, "reanimar a tempo cancela a queda")
	check(s7.mode == "run" and s7.summary_seq == 0, "run continua após a reanimação")

	# ── Snapshot durante a queda preserva a cinemática ──
	var s4 := Expedition.new()
	s4.coop = "solo"; s4.start_run(1941)
	s4.actors[0].hp = 5.0
	s4.damage_actor(s4.actors[0], 999.0, "warden", "charge")
	s4.actors[1].hp = 0.0; s4.actors[1].dead = true
	s4.step(0.016, [{}])
	var snap := s4.snapshot()
	var s5 := Expedition.new(); s5.apply_snapshot(snap)
	check(s5.death_seq_started and s5.death_cine > 0.0, "snapshot carrega a cinemática")
	for _i in range(40): s5.step(0.1, [{}])
	check(s5.mode == "hub" and str(s5.last_run_summary.get("outcome", "")) == "death", "cinemática restaurada termina no Refúgio")

	# ── bark() conecta o prefixo do retrato ──
	var s6 := Expedition.new()
	s6.coop = "solo"; s6.start_run(1941)
	s6.bark("Agora simmm!", 1.0)
	check(s6.message.begins_with("Marty:"), "bark usa o prefixo do retrato do Marty")

	print("DEATH_P9_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
