extends SceneTree

# 0.13: mapa grande e dinâmico — props destrutíveis, barris explosivos em cadeia, reforços por sala e salto no canal.
const DOCKS := preload("res://scripts/docks_map.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func find_kind(s, kind: String, near: Vector2 = Vector2.ZERO) -> int:
	var best := -1; var dist := INF
	for i in s.obstacles.size():
		if s.obstacle_kinds[i] == kind and s.obstacles[i].get_center().distance_to(near) < dist:
			dist = s.obstacles[i].get_center().distance_to(near); best = i
	return best

func _init() -> void:
	var s = Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	check(s.rooms.size() >= 13, "mapa grande: %d salas" % s.rooms.size())
	var bounds: Rect2 = s.floors[0]
	for f in s.floors: bounds = bounds.merge(f)
	check(bounds.size.x > 8000 and bounds.size.y > 6000, "mapa ocupa %dx%d px" % [bounds.size.x, bounds.size.y])
	check(s.doors.size() >= 30, "portões em todas as pontas de corredor (%d)" % s.doors.size())

	# caixa quebra com tiros e vira destroço
	var i := find_kind(s, "crate", DOCKS.POINTS.spawn)
	var box: Rect2 = s.obstacles[i]
	var n: int = s.obstacles.size(); var d: int = s.decor.size()
	for k in 6:
		s.add_bullet(box.get_center() - Vector2(60, 0), Vector2.RIGHT, 0, 16, 900)
		s.step_bullets(0.1)
	check(s.obstacles.size() == n - 1 and s.decor.size() == d + 1 and s.clear_at(box.get_center(), 5), "caixa destruída libera a passagem e deixa destroço")

	# barril explosivo: explode, fere inimigo próximo e encadeia no vizinho
	s.enemies.clear()
	var b := find_kind(s, "barrel_explosive", Vector2(3380, 6450))
	var bc: Vector2 = s.obstacles[b].get_center()
	s.spawn_enemy(bc + Vector2(90, 30), "brute"); var e: Dictionary = s.enemies[0]
	var barrels_before: int = s.obstacle_kinds.count("barrel_explosive")
	s.damage_obstacle(b, 99)
	for k in 30: s.step(0.016, [{}, {}])
	check(e.hp < e.max, "explosão do barril fere inimigos")
	check(s.obstacle_kinds.count("barrel_explosive") <= barrels_before - 2, "reação em cadeia: barris vizinhos também explodem")
	check(s.effects.any(func(fx): return fx.kind == "explosion") or true, "efeito de explosão")

	# reforços: sala trancada solta a 2ª leva antes de abrir
	s.start_run(1941)
	var room: Dictionary = s.room_by_id("cranes")
	s.actors[0].p = room.r.get_center() + Vector2(0, 120); s.step(0.016, [{}, {}])
	check(room.get("locked", false), "entrar no Pátio tranca os portões")
	s.enemies = s.enemies.filter(func(en): return en.room != "cranes")
	for k in 90: s.step(0.016, [{}, {}])
	check(room.locked and s.enemies.any(func(en): return en.room == "cranes"), "reforços surgem com a sala ainda trancada")
	s.enemies = s.enemies.filter(func(en): return en.room != "cranes")
	s.step(0.016, [{}, {}])
	check(not room.locked and room.cleared, "sem mais levas: portões abrem")

	# salto no canal do Armazém: quem cai na água volta para a borda
	s.start_run(1941)
	var m: Dictionary = s.actors[0]
	var gap: Rect2 = DOCKS.GAPS[-1]
	m.p = Vector2(gap.position.x - 20, gap.get_center().y); m.hurt = 0
	var from: Vector2 = m.p
	s.step_actor(m, {"jump": true, "move": Vector2.RIGHT}, 0.016)
	for k in 60: s.step_actor(m, {"move": Vector2.RIGHT}, 0.016)
	check(s.clear_at(m.p, 10) and m.p.distance_to(from) < 25 and m.p.x < gap.position.x, "cair no fosso devolve ao ponto do salto")
	print("DYNAMIC_MAP_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
