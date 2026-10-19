extends SceneTree

const Scenery = preload("res://scripts/dock_scenery.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)

func _init() -> void:
	var sim := Expedition.new()
	sim.procedural_enabled = true; sim.coop = "solo"; sim.start_run(1941)
	var scenery := Scenery.new()
	var revealed: Array = []
	for y in range(6500, 4400, -20):
		sim.actors[0].p = Vector2(1000, y)
		var room := sim.room_at(sim.actors[0].p)
		if not room.is_empty() and room.id not in sim.visited: sim.visited.append(room.id)
		var floors := scenery.visible_floors(sim, scenery.discovered_rooms(sim))
		for floor_rect in floors:
			check(floor_rect in sim.floors, "visible floor must belong to materialized walkable geometry")
		for floor_rect in revealed:
			check(floor_rect in floors, "discovered floor disappeared north of entry at y=%s: %s" % [y, floor_rect])
		for floor_rect in floors:
			if floor_rect not in revealed: revealed.append(floor_rect)
	var fresh := Expedition.new(); fresh.procedural_enabled = true; fresh.coop = "solo"; fresh.start_run(1941)
	fresh.visited = ["entry"]
	var initial := scenery.visible_floors(fresh, scenery.discovered_rooms(fresh))
	check(fresh.room_by_id("boss").r not in initial, "boss arena remains hidden on a fresh expedition")
	print("CORRIDOR_VISIBILITY_TEST failures=", failures)
	quit(1 if failures else 0)
