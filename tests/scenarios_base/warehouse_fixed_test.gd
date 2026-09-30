extends SceneTree
const Geometry=preload("res://scripts/scenarios/warehouse_fixed.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	var hash_before:=FileAccess.get_sha256("user://expedition.save")
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(42)
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks(); sim.build_navigation()
	for radius in [11.0,23.0]:
		for pair in [[Vector2(4480,6500),Vector2(4980,6500)],[Vector2(6090,6510),Vector2(6700,6510)]]:
			for reverse in [false,true]:
				var start: Vector2=pair[1] if reverse else pair[0]
				var target: Vector2=pair[0] if reverse else pair[1]
				var p:=start
				for frame in ceili(start.distance_to(target)/4): p=sim.move_body(p,(target-p).limit_length(4),radius)
				check(p.distance_to(target)<0.1,"passage r%s %s→%s"%[radius,start,target])
	var start: int=sim.nav.get_closest_point(sim.actors[0].p)
	for target in [Vector2(5100,7070),Vector2(5500,6450),Vector2(6040,6320),sim.run_points.boss]:
		check(sim.clear_at(target,23),"supported destination "+str(target))
		check(not sim.nav.get_id_path(start,sim.nav.get_closest_point(target)).is_empty(),"reachable destination "+str(target))
	for box in Geometry.BLOCKS: check(not sim.clear_at(Geometry.rect(box).get_center(),11),"painted cargo blocks")
	check(not sim.clear_at(Vector2(5800,7170),11),"foundation is not walkable")
	var traps:=sim.hazards.filter(func(h):return Geometry.bounds(sim).has_point(h.p))
	check(traps.size()==3,"three existing warehouse traps preserved")
	for h in traps: check(sim.clear_at(h.p,23),"trap is on accessible floor")
	var chest: Dictionary=sim.chests.filter(func(c):return Geometry.bounds(sim).has_point(c.p))[0]
	check(sim.clear_at(chest.p+Vector2(0,35),23),"reward has usable interaction space")
	sim.actors[0].p=chest.p+Vector2(0,35); sim.interact(sim.actors[0])
	check(chest.open,"reward interaction works")
	check(sim.room_threats("warehouse")==0,"exploration room does not acquire invented enemies")
	sim.spawn_enemy(Vector2(5500,6500),"guard")
	sim.actors[0].p=Vector2(5600,6500); sim.step_gates()
	check(sim.room_by_id("warehouse").get("locked",false),"encounter gates seal when threats exist")
	for door in sim.doors:
		if door.room=="warehouse": check(sim.gate_blocks.has(door.r),"painted exit has combat barrier")
	sim.enemies=sim.enemies.filter(func(e):return e.room!="warehouse"); sim.step_gates()
	check(not sim.room_by_id("warehouse").get("locked",true),"encounter gates reopen")
	check(not sim.clear_at(Vector2(5226,5890),11),"northern shortcut starts blocked")
	for i in range(sim.obstacles.size()-1,-1,-1):
		if sim.obstacle_kinds[i].begins_with("wall_crack_") and Geometry.bounds(sim).has_point(sim.obstacles[i].get_center()): sim.open_shortcut(i)
	check(sim.clear_at(Vector2(5226,5890),23),"shortcut opens for Titan")
	for radius in [11.0,23.0]:
		for direction in [-1.0,1.0]:
			var p:=Vector2(5190,5920-240*direction)
			var target:=p+Vector2(0,480*direction)
			for frame in 120: p=sim.move_body(p,Vector2(0,4*direction),radius)
			check(p.distance_to(target)<0.1,"whole shortcut passage r"+str(radius))
	var replica:=Expedition.new(); replica.apply_snapshot(sim.snapshot().duplicate(true))
	check(replica.floors==sim.floors and replica.obstacles==sim.obstacles,"snapshot preserves room")
	check(FileAccess.get_sha256("user://expedition.save")==hash_before,"save untouched")
	print("WAREHOUSE_FIXED_TEST failures=",failures); quit(1 if failures else 0)
