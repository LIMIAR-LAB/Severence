extends SceneTree
const Art=preload("res://scripts/scenarios/corridor_art.gd")
const Scenery=preload("res://scripts/dock_scenery.gd")
var failures:=0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	var saved_hash:=FileAccess.get_sha256("user://expedition.save")
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(42)
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks()
	for radius in [11.0,23.0]:
		for pair in [[Vector2(1000,6100),Vector2(1000,5440)],[Vector2(1430,4350),Vector2(1900,4350)],[Vector2(2150,6500),Vector2(2630,6500)],[Vector2(3930,5850),Vector2(3930,5660)],[Vector2(3930,5660),Vector2(4100,5660)],[Vector2(4100,5660),Vector2(4100,5420)]]:
			for reverse in [false,true]:
				var start: Vector2=pair[1] if reverse else pair[0]
				var target: Vector2=pair[0] if reverse else pair[1]
				var position:=start
				for frame in ceili(start.distance_to(target)/4.0): position=sim.move_body(position,(target-position).limit_length(4),radius)
				check(position.distance_to(target)<0.1,"corridor traversable r%s %s→%s"%[radius,start,target])
	check(Scenery.is_corridor(Rect2(900,5600,200,350),sim),"clipped corridor remains a corridor")
	check(not sim.clear_at(Vector2(870,5700),11),"water beside passage is not walkable")
	check(FileAccess.get_sha256("user://expedition.save")==saved_hash,"save unchanged")
	print("CORRIDOR_FINISH_TEST failures=",failures); quit(1 if failures else 0)
