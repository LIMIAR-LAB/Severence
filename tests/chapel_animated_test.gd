extends SceneTree

const Scenery := preload("res://scripts/dock_scenery.gd")
const DOCKS := preload("res://scripts/docks_map.gd")

var failures := 0

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS CAPELA: ", label)
	else:
		failures += 1
		push_error("FAIL CAPELA: " + label)

func _init() -> void:
	var scenery = Scenery.new()
	check(scenery.chapel_frames.size() == 12, "carrega 12 overlays uma única vez")
	for i in scenery.chapel_frames.size():
		var texture: Texture2D = scenery.chapel_frames[i]
		check(texture != null and texture.get_size() == Vector2(800, 900), "overlay %02d mede 800x900" % i)
	check(scenery.chapel_fallback != null and scenery.chapel_fallback.get_size() == Vector2(1600, 3300), "fallback estático disponível")
	check(Scenery.chapel_frame_index(0.109) == 0, "quadro dura 110 ms")
	check(Scenery.chapel_frame_index(0.110) == 1, "troca no limite de 110 ms")
	check(Scenery.chapel_frame_index(1.320) == 0, "animação fecha o loop em 1,32 s")

	var chapel: Dictionary = DOCKS.ROOMS.filter(func(room): return room.id == "chapel")[0]
	check(chapel.r == Rect2(200, 3600, 1300, 1400), "geometria externa da sala foi preservada")
	check(Scenery.CHAPEL_PLATE_RECT == Rect2(200, 2700, 1600, 3300), "placa unifica sala e corredores em resolução nativa")
	check(scenery.chapel_is_visible([chapel], Rect2(0, 3400, 1800, 1200)), "sala descoberta exibe a placa")
	check(not scenery.chapel_is_visible([], Rect2(0, 3400, 1800, 1200)), "sala oculta não revela a arte")
	scenery.chapel_room_active = true
	check(not scenery.chapel_hides_legacy("iron_door", Vector2(850, 3602)), "porta de estado permanece acima da placa")
	check(scenery.chapel_hides_legacy("altar", Vector2(850, 3905)), "altar procedural duplicado é ocultado")
	check(scenery.chapel_hides_legacy("chapel_banner", Vector2(560, 3590)), "banner sobreposto é ocultado")

	var pews: Array[Rect2] = []
	for obstacle in DOCKS.OBSTACLES:
		if obstacle[4] == "pew":
			pews.append(Rect2(obstacle[0], obstacle[1], obstacle[2], obstacle[3]))
	check(pews.size() == 6, "seis bancos pintados possuem colisão")
	check(pews.all(func(box): return box.position.y >= 4138 and box.end.y <= 4358), "colisões acompanham os bancos visíveis")
	check(pews.all(func(box): return not Rect2(750, 3970, 180, 960).intersects(box)), "corredor central continua livre")

	var sim = Expedition.new()
	sim.coop = "solo"
	sim.start_run(1941)
	var start := Vector2i(roundi(1000.0 / 12.0), roundi(4800.0 / 12.0))
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			var point := Vector2(next) * 12.0
			if point.x < 100.0 or point.x > 1850.0 or point.y < 2600.0 or point.y > 5400.0:
				continue
			if not reached.has(next) and sim.clear_at(point, 11):
				reached[next] = true
				queue.append(next)
	for target in [["norte", Vector2(800, 3500)], ["leste", Vector2(1650, 4300)], ["sul", Vector2(1000, 5150)]]:
		var accessible := false
		for cell: Vector2i in reached:
			if (Vector2(cell) * 12.0).distance_to(target[1]) < 30.0:
				accessible = true
				break
		check(accessible, "abordagem %s permanece transitável" % target[0])

	var saved_frames: Array[Texture2D] = []
	saved_frames.assign(scenery.chapel_frames)
	var saved_fallback: Texture2D = scenery.chapel_fallback
	scenery.chapel_frames.clear()
	scenery.chapel_fallback = null
	check(not scenery.chapel_hides_legacy("altar", Vector2(850, 3905)), "sem arte, visuais antigos continuam disponíveis")
	scenery.chapel_frames.assign(saved_frames)
	scenery.chapel_fallback = saved_fallback

	print("CHAPEL_ANIMATED_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
