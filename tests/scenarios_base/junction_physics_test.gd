extends SceneTree
var failures := 0
var records := []
func check(ok: bool, label: String) -> void:
	records.append({"ok":ok,"label":label})
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	var save_path := "user://expedition.save"
	var original_hash := FileAccess.get_sha256(save_path)
	var data: Dictionary = FileAccess.open(save_path,FileAccess.READ).get_var(false)
	var sim := Expedition.new(); sim.apply_snapshot(data.state.duplicate(true))
	for room in sim.rooms: room["locked"]=false
	sim.refresh_gate_blocks(); sim.ob_grid_count=-1; sim.build_navigation()
	var farol: Rect2 = sim.room_by_id("stairs").r
	var chapel: Rect2 = sim.room_by_id("chapel").r
	for radius in [11.0,23.0]:
		for door in sim.doors:
			if door.room not in ["chapel","stairs"]: continue
			var normal: Vector2 = {"left":Vector2.LEFT,"right":Vector2.RIGHT,"top":Vector2.UP,"bottom":Vector2.DOWN}[door.side]
			var center: Vector2 = door.r.get_center()
			for direction in [-1.0,1.0]:
				var position: Vector2 = center-normal*110*direction
				var finish: Vector2 = center+normal*110*direction
				for frame in 55: position=sim.move_body(position,normal*4*direction,radius)
				check(position.distance_to(finish)<0.1,"%s %s radius%d direction%d"%[door.room,door.side,radius,direction])
		check(not sim.clear_at(chapel.position+Vector2(-80,700),radius),"outside chapel has no invisible floor radius%d"%radius)
		var altar: Rect2 = sim.obstacles[sim.obstacle_kinds.find("altar")]
		var position: Vector2 = Vector2(altar.get_center().x,altar.end.y+50)
		for frame in 30: position=sim.move_body(position,Vector2(0,-4),radius)
		check(position.y>=altar.end.y+radius,"altar blocks physical approach radius%d"%radius)
	for x in range(200,1501,100):
		for y in range(200,1001,100): check(is_zero_approx(sim.height_at(farol.position+Vector2(x,y))),"flat Farol terrain %d,%d"%[x,y])
	check(sim.clear_at(sim.story_npc_position(),11),"story NPC stands on supported accessible floor")
	check(sim.clear_at(sim.chests.filter(func(c):return chapel.has_point(c.p))[0].p,11),"chapel reward remains accessible")
	check(FileAccess.get_sha256(save_path)==original_hash,"user save remains byte-identical")
	var out := "res://_bmad-output/implementation-artifacts/cenarios-base/junction-physics.json"
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"seed":sim.seed_value,"failures":failures,"save_sha256":original_hash,"farol_origin":str(farol.position),"chapel_origin":str(chapel.position),"checks":records},"  "))
	print("JUNCTION_PHYSICS_TESTS_DONE failures=",failures," checks=",records.size())
	quit(1 if failures else 0)
