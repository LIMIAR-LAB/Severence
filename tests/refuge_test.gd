extends SceneTree

# Refúgio • Fora do Tempo: todos os pontos de interesse precisam ser alcançáveis a pé
# a partir do ponto inicial, e cada interação precisa responder.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s = Expedition.new()
	s.coop = "solo"; s.make_hub()
	var start: Vector2 = s.actors[0].p
	check(s.clear_at(start, 11), "spawn do refúgio está em piso livre")
	# Flood fill com o mesmo raio de colisão do Marty (11px) numa grade de 8px.
	var seen := {}
	var queue: Array = [Vector2i(roundi(start.x / 8), roundi(start.y / 8))]
	seen[queue[0]] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + off
			if not seen.has(n) and s.clear_at(Vector2(n) * 8, 11): seen[n] = true; queue.append(n)
	for point in s.HUB_POINTS:
		var ok := false
		for c in seen:
			if (Vector2(c) * 8).distance_to(point.p) < point.r * 0.8: ok = true; break
		check(ok, "alcançável a pé: " + point.id)
	var mech_cell := false
	for c in seen:
		if (Vector2(c) * 8).distance_to(s.mech.p) < 90: mech_cell = true; break
	check(mech_cell, "Marty alcança o Titan na baia")
	check(s.clear_at(s.mech.p, 23), "Titan estaciona dentro da baia do hangar")
	check(not s.clear_at(Vector2(640, 390), 11), "pedestal do núcleo bloqueia passagem")
	check(not s.clear_at(Vector2(60, 400), 11), "vazio cósmico não é caminhável")
	var a: Dictionary = s.actors[0]
	for id in ["lost", "core", "mural", "hangar", "bench"]:
		for point in s.HUB_POINTS:
			if point.id == id: a.p = point.p
		s.message = ""; s.interact(a)
		check(s.message != "" and s.mode == "hub", "interação responde: " + id)
	for point in s.HUB_POINTS:
		if point.id == "armor": a.p = point.p
	var seen_outfits := []
	a.armor = false; a.outfit = "padrao"
	for n in range(3):
		s.interact(a); seen_outfits.append(a.outfit)
	check(seen_outfits == ["mecanico", "espiao", "padrao"], "vitrine troca o uniforme: Mecânico → Espião → Padrão")
	check(not a.armor, "vitrine não veste a armadura (armadura é o R)")
	check(s.outfit_of({"armor": true, "outfit": "espiao"}) == "omega", "armadura ativa usa o visual Ômega")
	for point in s.HUB_POINTS:
		if point.id == "portal": a.p = point.p
	s.interact(a)
	check(s.mode == "run", "portal DOCAS / 1941 inicia a expedição")
	print("REFUGE_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
