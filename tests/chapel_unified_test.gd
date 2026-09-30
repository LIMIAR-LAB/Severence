extends SceneTree

const Scenery := preload("res://scripts/dock_scenery.gd")
const Docks := preload("res://scripts/docks_map.gd")
const World := preload("res://scripts/world_view.gd")
const HUD := preload("res://scripts/combat_hud.gd")

var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS CAPELA V2: ", label)
	else:
		failures += 1
		push_error("FAIL CAPELA V2: " + label)

func route_exists(sim, radius: float, start: Vector2, target: Vector2) -> bool:
	var step := 16.0
	var origin := Vector2(180, 2680)
	var bounds := Rect2(origin, Vector2(1640, 3340))
	var first := Vector2i(roundi((start.x-origin.x)/step), roundi((start.y-origin.y)/step))
	var goal := Vector2i(roundi((target.x-origin.x)/step), roundi((target.y-origin.y)/step))
	if not sim.clear_at(start, radius) or not sim.clear_at(target, radius): return false
	var queue: Array[Vector2i] = [first]
	var reached := {first: true}
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var point := origin + Vector2(cell) * step
		if cell == goal and point.distance_to(target) <= step and sim.clear_at(point, radius): return true
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			var candidate := origin + Vector2(next) * step
			if bounds.has_point(candidate) and not reached.has(next) and sim.clear_at(candidate, radius):
				reached[next] = true; queue.append(next)
	return false

func _init() -> void:
	var scenery = Scenery.new()
	check(Scenery.CHAPEL_PLATE_RECT == Rect2(200,2700,1600,3300), "placa cobre a capela e os três corredores")
	check(scenery.chapel_frames.size() == 12, "doze overlays carregados")
	for frame in scenery.chapel_frames:
		check(frame != null and frame.get_size() == Vector2(800,900), "overlay recortado mantém geometria 800x900")
	check(scenery.chapel_fallback != null and scenery.chapel_fallback.get_size() == Vector2(1600,3300), "master estático disponível")
	check(scenery.chapel_fisherman_frames.size() == 4 and scenery.chapel_fisherman_frames.all(func(f): return f != null and f.get_size() == Vector2(80,112)), "Pescador dedicado tem quatro quadros")
	check(scenery.chapel_hides_gate("chapel") and scenery.chapel_hides_gate("rails", Rect2(1800,4200,36,200)) and not scenery.chapel_hides_gate("market", Rect2(6000,6000,36,200)), "soleiras integradas substituem os dois lados dos portões genéricos da capela")
	var npc_hashes: Array = scenery.chapel_fisherman_frames.map(func(f): return hash(f.get_image().get_data()))
	check(npc_hashes.duplicate().all(func(h): return npc_hashes.count(h) == 1), "quadros do Pescador têm animação localizada distinta")
	check(Scenery.chapel_frame_index(1.320) == 0, "loop ambiental determinístico")

	var expected_furniture := [
		Rect2(680,3888,340,62), Rect2(575,4138,165,36), Rect2(950,4138,165,36),
		Rect2(565,4228,175,38), Rect2(940,4228,175,38), Rect2(565,4318,180,40),
		Rect2(935,4318,185,40), Rect2(365,4510,275,112), Rect2(1055,4510,285,112)]
	var expected_walls := [Rect2(200,3600,400,300),Rect2(1000,3600,500,300),Rect2(200,3600,105,1400),Rect2(1395,3600,105,530),Rect2(1395,4470,105,530),Rect2(200,4622,250,378),Rect2(1350,4622,150,378)]
	var actual: Array[Rect2] = []; var actual_walls: Array[Rect2] = []
	for item in Docks.OBSTACLES:
		if item[4] in ["altar","pew","chapel_reliquary"] and Rect2(200,3600,1300,1400).has_point(Vector2(item[0],item[1])):
			actual.append(Rect2(item[0],item[1],item[2],item[3]))
		elif item[4] == "chapel_wall": actual_walls.append(Rect2(item[0],item[1],item[2],item[3]))
	check(actual.size() == expected_furniture.size() and expected_furniture.all(func(box): return actual.has(box)), "móveis coincidem com o contrato autoral")
	check(actual_walls.size() == expected_walls.size() and expected_walls.all(func(box): return actual_walls.has(box)), "paredes/void coincidem com o contrato autoral")
	check(actual.all(func(box): return not box.intersects(Rect2(750,3970,180,960))), "procissão central livre")
	check(Docks.CORRIDORS.has(Rect2(700,2700,200,900)) and Docks.CORRIDORS.has(Rect2(1500,4200,300,200)) and Docks.CORRIDORS.has(Rect2(900,5000,200,1000)), "retângulos dos três corredores preservados")

	var sim = Expedition.new(); sim.coop="solo"; sim.start_run(1941)
	check(not sim.clear_at(Vector2(370,3740),11), "void visível em 370,3740 bloqueado")
	check(sim.STORY_NPC == Vector2(1160,4740) and sim.clear_at(sim.STORY_NPC,23), "âncora autoral do Pescador segura até para o Titan")
	var chapel_chests: Array = sim.chests.filter(func(c): return Rect2(200,3600,1300,1400).has_point(c.p))
	check(chapel_chests.size()==1 and chapel_chests[0].p==Vector2(700,4470) and sim.clear_at(chapel_chests[0].p,15), "âncora autoral do baú em piso verificado")
	for radius in [11.0,14.0,15.0,23.0]:
		for portal in [["norte",Vector2(800,2750)],["leste",Vector2(1750,4300)],["sul",Vector2(1000,5950)]]:
			check(route_exists(sim,radius,Vector2(850,4600),portal[1]),"raio %.0f alcança %s" % [radius,portal[0]])

	check(World.chapel_npc_label(0).contains("INTERAGIR") and World.chapel_npc_label(1).contains("RETORNAR") and World.chapel_npc_label(2)=="PESCADOR", "prompt não fixa tecla e acompanha a missão")
	check(HUD.show_story_marker(0) and HUD.show_story_marker(1) and not HUD.show_story_marker(2), "marcador desaparece após concluir a missão")
	var saved_frames: Array[Texture2D] = []; saved_frames.assign(scenery.chapel_frames)
	var saved_fallback: Texture2D = scenery.chapel_fallback
	scenery.chapel_frames[3] = null
	check(scenery.chapel_overlay_at(3.0 * Scenery.CHAPEL_FRAME_SECONDS) == null and scenery.chapel_texture_at(0.0) == saved_fallback, "overlay individual ausente preserva master estático")
	var npc_saved: Texture2D = scenery.chapel_fisherman_frames[2]; scenery.chapel_fisherman_frames[2] = null
	check(scenery.chapel_fisherman_texture(0.56) != null, "quadro nulo do Pescador usa fallback estável")
	scenery.chapel_fisherman_frames[2] = npc_saved
	scenery.chapel_room_active = true; scenery.chapel_fallback=null
	check(not scenery.chapel_hides_legacy("altar",Vector2(850,3900)), "static ausente mantém o cenário legacy")
	scenery.chapel_frames.assign(saved_frames); scenery.chapel_fallback=saved_fallback
	print("CHAPEL_UNIFIED_TESTS_DONE failures=%d" % failures)
	quit(1 if failures else 0)
