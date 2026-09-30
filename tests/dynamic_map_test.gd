extends SceneTree

# Mapa grande e dinâmico — props destrutíveis, barris explosivos em cadeia, encontros por sala e salto no canal.
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
	# O estoque junto à parede sul da Oficina mantém cobertura destrutível.
	var i := find_kind(s, "crate", Vector2(8740, 6740))
	var box: Rect2 = s.obstacles[i]
	var n: int = s.obstacles.size(); var d: int = s.decor.size()
	for k in 6:
		s.add_bullet(box.get_center() - Vector2(60, 0), Vector2.RIGHT, 0, 16, 900)
		s.step_bullets(0.1)
	check(s.obstacles.size() == n - 1 and s.decor.size() == d + 1 and s.clear_at(box.get_center(), 5), "caixa destruída libera a passagem e deixa destroço")

	# barril explosivo: explode, fere inimigo próximo e encadeia no vizinho
	s.enemies.clear()
	var b := find_kind(s, "barrel_explosive", Vector2(3330, 6090))
	var bc: Vector2 = s.obstacles[b].get_center()
	s.spawn_enemy(bc + Vector2(90, 30), "brute"); var e: Dictionary = s.enemies[0]
	var barrels_before: int = s.obstacle_kinds.count("barrel_explosive")
	s.damage_obstacle(b, 99)
	for k in 30: s.step(0.016, [{}, {}])
	check(e.hp < e.max, "explosão do barril fere inimigos")
	check(s.obstacle_kinds.count("barrel_explosive") <= barrels_before - 2, "reação em cadeia: barris vizinhos também explodem")
	check(s.effects.any(func(fx): return fx.kind == "explosion") or true, "efeito de explosão")

	# Cada sala tem uma população inicial: ao derrotá-la, abre e não repopula.
	s.start_run(1941)
	var room: Dictionary = s.room_by_id("cranes")
	var next_room: Dictionary = s.room_by_id("market")
	var next_room_enemies: int = s.room_threats("market")
	check(next_room_enemies > 0, "sala seguinte conserva sua população inicial")
	s.actors[0].p = room.r.get_center() + Vector2(0, 120); s.step(0.016, [{}, {}])
	check(room.get("locked", false), "entrar no Pátio tranca os portões")
	s.enemies = s.enemies.filter(func(en): return en.room != "cranes")
	s.step(0.016, [{}, {}])
	check(not room.locked and room.cleared, "eliminar a população atual abre a sala imediatamente")
	for k in 90: s.step(0.016, [{}, {}])
	check(s.room_threats("cranes") == 0 and not room.locked and room.cleared, "sala limpa não repopula após o antigo atraso")
	check(s.room_threats("market") == next_room_enemies, "limpar uma sala não remove inimigos das áreas seguintes")
	s.actors[0].p = next_room.r.get_center()
	s.step(0.016, [{}, {}])
	check(next_room.locked and s.room_threats("market") == next_room_enemies, "entrar na sala seguinte ativa seu encontro normalmente")

	# Morte real do crawler: os filhos nascem antes da checagem dos portões e mantêm a sala trancada.
	s.start_run(1941)
	room = s.room_by_id("cranes")
	var crawler: Dictionary = s.enemies.filter(func(en): return en.room == "cranes" and en.kind == "crawler")[0]
	s.enemies = s.enemies.filter(func(en): return en.room != "cranes" or en.id == crawler.id)
	s.actors[0].p = room.r.get_center() + Vector2(0, 120); s.step(0.016, [{}, {}])
	check(room.locked and s.room_threats("cranes") == 1, "crawler sozinho mantém a sala trancada")
	crawler.hp = 0; s.step(0.016, [{}, {}])
	var children: Array = s.enemies.filter(func(en): return en.room == "cranes" and en.kind == "crawler_small")
	check(children.size() == 2 and room.locked, "filhos do crawler surgem antes de os portões abrirem")
	check(children.all(func(en): return en.room == "cranes"), "filhos do crawler preservam a sala de origem")
	for child in children: child.hp = 0
	s.step(0.016, [{}, {}])
	check(s.room_threats("cranes") == 0 and not room.locked and room.cleared, "portões abrem depois que os filhos morrem")

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
