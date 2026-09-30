extends SceneTree

const Scenery := preload("res://scripts/dock_scenery.gd")
const DOCKS := preload("res://scripts/docks_map.gd")
const Sim := preload("res://scripts/simulation.gd")

var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _init() -> void:
	var scenery := Scenery.new()
	check(scenery.boss_arena != null, "placa dedicada da arena carrega")
	if scenery.boss_arena != null:
		var size := scenery.boss_arena.get_size()
		check(size == Vector2(1200, 900), "placa tem resolução 4:3 preparada para escala inteira 2x")
		check(is_equal_approx(size.x / size.y, 4.0 / 3.0), "placa preserva proporção 4:3")

	var boss_rooms := DOCKS.ROOMS.filter(func(room): return room.id == "boss")
	check(boss_rooms.size() == 1, "existe exatamente uma sala do Almirante")
	var room: Dictionary = boss_rooms[0]
	check(room.r == Rect2(3000, 400, 2400, 1800), "geometria física da sala permanece 2400x1800")
	check(room.extra == [Rect2(2600, 700, 400, 500), Rect2(5400, 800, 300, 600)], "as duas alas de entrada permanecem intactas")
	check(DOCKS.POINTS.boss == Vector2(4200, 1200), "spawn do chefe permanece intacto")
	check(DOCKS.POINTS.extraction == Vector2(4200, 720), "extração permanece intacta")
	var boss_water := DOCKS.WATER.filter(func(area): return area.room == "boss")
	check(boss_water.size() == 4, "moldura aquática cobre os quatro lados sem alterar o piso")
	for edge_point in [Vector2(1000, -200), Vector2(1000, 3000), Vector2(7400, 1000), Vector2(7400, 3000)]:
		check(boss_water.any(func(area): return area.r.has_point(edge_point)), "água cobre câmera ampla em %s" % edge_point)

	var expected_obstacles := [
		[3355, 710, 90, 90, "pillar"], [4955, 710, 90, 90, "pillar"],
		[3355, 1710, 90, 90, "pillar"], [4955, 1710, 90, 90, "pillar"],
		[3232, 574, 36, 26, "brazier"], [5132, 574, 36, 26, "brazier"],
		[3232, 2024, 36, 26, "brazier"], [5132, 2024, 36, 26, "brazier"],
		[3782, 1124, 36, 26, "brazier"], [4582, 1124, 36, 26, "brazier"],
		[3129, 1270, 42, 30, "barrel_explosive"], [3177, 1276, 42, 30, "barrel_oil"],
		[3147, 1308, 42, 30, "barrel_explosive"], [5179, 1270, 42, 30, "barrel_explosive"],
		[5227, 1276, 42, 30, "barrel_oil"], [5197, 1308, 42, 30, "barrel_explosive"],
		[3589, 982, 22, 18, "lamp_post"], [4789, 982, 22, 18, "lamp_post"]]
	var boss_obstacles := DOCKS.OBSTACLES.filter(func(item): return room.r.has_point(Vector2(item[0], item[1])))
	check(boss_obstacles == expected_obstacles, "obstáculos físicos do chefe permanecem idênticos")
	var boss_hazards := DOCKS.HAZARDS.filter(func(item): return room.r.has_point(item.p))
	check(boss_hazards == [
		{"p": Vector2(3350, 1300), "r": 64, "damage": 12},
		{"p": Vector2(5050, 1300), "r": 64, "damage": 12}], "perigos do chefe permanecem idênticos")

	var sim := Sim.new()
	sim.coop = "solo"
	sim.start_run(1941)
	check(sim.clear_at(Vector2(2800, 950), 15), "entrada oeste continua livre")
	check(sim.clear_at(Vector2(5550, 1100), 15), "entrada leste continua livre")
	check(sim.clear_at(DOCKS.POINTS.extraction, 15), "ponto de extração continua navegável")

	var safe := true
	for radius in [0.0, 120.0, 240.0, 359.0]:
		for i in 16:
			var p: Vector2 = DOCKS.POINTS.boss + Vector2.RIGHT.rotated(TAU * float(i) / 16.0) * float(radius)
			if not sim.clear_at(p, 15): safe = false
	check(safe, "disco central de esquiva de 360 px permanece livre")

	var west_id := sim.nav.get_closest_point(Vector2(2800, 950))
	var east_id := sim.nav.get_closest_point(Vector2(5550, 1100))
	var boss_id := sim.nav.get_closest_point(DOCKS.POINTS.boss)
	check(sim.nav.get_point_position(west_id).distance_to(Vector2(2800, 950)) <= 36.0, "entrada oeste tem nó de navegação local")
	check(sim.nav.get_point_position(east_id).distance_to(Vector2(5550, 1100)) <= 36.0, "entrada leste tem nó de navegação local")
	check(sim.nav.get_point_path(west_id, boss_id).size() > 1, "navegação liga entrada oeste ao centro")
	check(sim.nav.get_point_path(east_id, boss_id).size() > 1, "navegação liga entrada leste ao centro")
	check(sim.nav.get_point_path(boss_id, sim.nav.get_closest_point(DOCKS.POINTS.extraction)).size() > 1, "navegação liga centro à extração")

	print("BOSS_ARENA_SCENERY_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
