extends SceneTree

# Cenário 0.12: névoa das salas não descobertas, arte nova carregando e a Sala 01 continua jogável
# (spawn → chave → saída para o Pátio dos Guindastes a pé, sem obstáculo bloqueando).
const Scenery := preload("res://scripts/dock_scenery.gd")
const DOCKS := preload("res://scripts/docks_map.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func ids(rooms: Array) -> Array:
	return rooms.map(func(r): return r.get("id", ""))

func _init() -> void:
	var sc = Scenery.new()
	var missing := 0
	for n in sc.tiles: if sc.tiles[n] == null: missing += 1
	for n in sc.props: if sc.props[n] == null: missing += 1
	check(missing == 0, "tiles e props da arte 0.12 carregam (%d tiles, %d props)" % [sc.tiles.size(), sc.props.size()])
	for o in DOCKS.OBSTACLES:
		if not sc.has_prop(o[4]) and o[4] not in ["pillar", "container_red", "container_olive", "generator", "altar", "pew", "ammo", "crate_row"]:
			check(false, "obstáculo sem arte: " + o[4])

	var s = Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	s.step(0.016, [{}, {}])
	var rooms: Array = sc.discovered_rooms(s)
	check(ids(rooms) == ["entry"], "no início só o Desembarque está descoberto")
	var floors: Array = sc.visible_floors(s, rooms)
	check(floors.has(DOCKS.CORRIDORS[0]), "corredor que sai do Desembarque aparece")
	check(not Scenery.inside(floors, Vector2(3450, 6450)), "Pátio dos Guindastes fica no escuro")
	s.actors[0].p = Vector2(3450, 6450); s.step(0.016, [{}, {}])
	check(ids(sc.discovered_rooms(s)).has("cranes"), "entrar no Pátio revela a sala")

	# Sala 01 continua atravessável (raio de colisão do Marty, grade de 8px)
	s.start_run(1941)
	var start: Vector2 = DOCKS.POINTS.spawn
	var seen := {}
	var queue: Array = [Vector2i(roundi(start.x / 8), roundi(start.y / 8))]
	seen[queue[0]] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + off
			var p := Vector2(n) * 8
			if p.x < 560 or p.x > 2240 or p.y < 5960 or p.y > 7040: continue
			if not seen.has(n) and s.clear_at(p, 11): seen[n] = true; queue.append(n)
	for target in [["chave", DOCKS.POINTS.key], ["saída para o corredor", Vector2(2185, 6500)], ["cais de granito", Vector2(920, 6975)]]:
		var ok := false
		for c in seen:
			if (Vector2(c) * 8).distance_to(target[1]) < 24: ok = true; break
		check(ok, "Sala 01 alcançável a pé: " + target[0])
	# Portões: sala com inimigos tranca; limpa, abre.
	s.start_run(1941); s.step(0.016, [{}, {}])
	var entry: Dictionary = s.room_by_id("entry")
	check(entry.get("locked", false), "Desembarque com inimigos: portões fechados")
	check(not s.clear_at(Vector2(2218, 6500), 11), "portão fechado bloqueia a passagem")
	s.enemies = s.enemies.filter(func(e): return e.room != "entry")
	s.step(0.016, [{}, {}])
	check(not entry.locked and entry.cleared and s.clear_at(Vector2(2218, 6500), 11), "sala limpa: portões abrem")
	# Tentáculo do Desembarque causa dano
	var m: Dictionary = s.actors[0]
	m.p = DOCKS.HAZARDS[0].p; m.hurt = 0; var before: float = m.hp
	s.step(0.016, [{}, {}])
	check(m.hp < before, "poça com tentáculo causa dano")
	# 0.15: sala não pode ficar apagada ao entrar numa segunda expedição (tick_time recomeça do zero)
	var sc2 = Scenery.new()
	var s2 = Expedition.new(); s2.coop = "solo"; s2.start_run(1941)
	s2.tick_time = 300.0; s2.step(0.016, [{}, {}]); sc2.discovered_rooms(s2)
	s2.start_run(1942); s2.step(0.016, [{}, {}])
	sc2.discovered_rooms(s2)
	check(float(sc2.reveal_at.get("entry", 999.0)) <= s2.tick_time, "nova expedição: sala acende de novo (sem registro no futuro)")
	s2.tick_time += 0.6
	var dark := false
	for room in sc2.discovered_rooms(s2):
		var age: float = s2.tick_time - float(sc2.reveal_at.get(room.get("id", ""), -9.0))
		if room.has("id") and age >= 0.0 and age < 0.5: dark = true
	check(not dark, "depois de 0,5s nenhuma sala descoberta continua escurecida")
	print("SCENERY_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
