extends SceneTree

const Sim = preload("res://scripts/simulation.gd")
const HUD = preload("res://scripts/combat_hud.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
	else: print("PASS: ", label)

func _init() -> void:
	var sim := Sim.new()
	sim.start_run(42)
	var hud := HUD.new()
	var room: Dictionary = sim.room_by_id("cranes")
	var center: Vector2 = room.r.get_center()
	var project := func(p: Vector2) -> Vector2: return Vector2(50, 50) + (p - center) * 0.05
	var clip := Rect2(0, 0, 100, 100)
	sim.enemies = [{"p": center, "hp": 10.0}]
	sim.visited.erase(room.id)
	check(hud.minimap_enemy_positions(sim, project, clip).is_empty(), "Unexplored rooms stay hidden")
	sim.visited.append(room.id)
	check(hud.minimap_enemy_positions(sim, project, clip) == [Vector2(50, 50)], "Living enemy appears at projected position")
	sim.enemies[0].p += Vector2(100, 0)
	check(hud.minimap_enemy_positions(sim, project, clip) == [Vector2(55, 50)], "Marker follows enemy movement")
	sim.enemies[0].hp = 0
	check(hud.minimap_enemy_positions(sim, project, clip).is_empty(), "Defeated enemy disappears")
	sim.enemies[0].hp = 10
	check(hud.minimap_enemy_positions(sim, project, Rect2(0, 0, 20, 20)).is_empty(), "Markers stay inside minimap")
	hud.free()
	print("MINIMAP_ENEMIES failures=", failures)
	quit(1 if failures else 0)
