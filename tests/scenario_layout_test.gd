extends SceneTree

const Layout := preload("res://scripts/scenario_layout.gd")
const DOCKS := preload("res://scripts/docks_map.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _init() -> void:
	var sim := Expedition.new()
	sim.coop = "solo"
	sim.start_run(1941)
	var legacy_pillars: Array = Layout.composed_obstacles(DOCKS.OBSTACLES,sim.rooms).filter(func(o): return o[4]=="stone_pillar")
	check(legacy_pillars.size()>=18,"baseline conserva autoria dos pilares")
	var expected := 0
	for pillar in legacy_pillars:
		var box := Rect2(pillar[0],pillar[1],pillar[2],pillar[3])
		if sim.scenario_modules.has("stairs") and sim.room_by_id("stairs").r.has_point(box.get_center()): continue
		expected += 1
		check(box.size==Vector2(220,160) and sim.obstacles.has(box),"pilar fora do módulo preserva colisão autorada")
	check(sim.obstacle_kinds.count("stone_pillar")==expected,"somente pilares substituídos pelo módulo são retirados")
	check(sim.gaps.size() == 5, "três fossos novos além dos canais existentes")
	for pit in Layout.PITS:
		check(not sim.clear_at(pit.get_center(), 11), "fosso bloqueia o chão em %s" % pit.position)
		var overlapping := false
		for obstacle in sim.obstacles:
			if obstacle.intersects(pit): overlapping = true
		check(not overlapping, "fosso não cruza obstáculo em %s" % pit.position)
	for crossing in [
		[Vector2(3200, 6480), Vector2(3900, 6480)],
		[Vector2(4450, 4530), Vector2(5200, 4530)],
		[Vector2(6550, 4530), Vector2(7500, 4530)],
	]:
		var start: int = sim.nav.get_closest_point(crossing[0])
		var finish: int = sim.nav.get_closest_point(crossing[1])
		check(sim.nav.get_id_path(start, finish).size() > 1, "rota contorna fosso entre %s e %s" % crossing)
	var enemy_in_pit := false
	for enemy in sim.enemies:
		for pit in Layout.PITS:
			if pit.has_point(enemy.p): enemy_in_pit = true
	check(not enemy_in_pit, "inimigos não nascem em fossos")
	for point_name in ["shop", "side", "ammo_center", "warden", "mech"]:
		check(sim.clear_at(DOCKS.POINTS[point_name], 12), "acesso livre ao ponto %s" % point_name)
	var ammo_walls := 0
	for i in sim.obstacles.size():
		if sim.obstacle_kinds[i] == "maze_wall" and Layout.room_id_at(sim.obstacles[i].get_center(), sim.rooms) == "ammo":
			ammo_walls += 1
	check(ammo_walls == 0, "paredes antigas não atravessam os pilares do depósito")
	print("SCENARIO_LAYOUT_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)
