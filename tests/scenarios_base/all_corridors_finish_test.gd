extends SceneTree
const Art=preload("res://scripts/scenarios/corridor_art.gd")
const Scenery=preload("res://scripts/dock_scenery.gd")
var failures:=0
var checked:=0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	var saved_hash:=FileAccess.get_sha256("user://expedition.save")
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(42)
	var scenery:=Scenery.new()
	for room in sim.rooms: sim.visited.append(room.id); room.locked=false
	sim.refresh_gate_blocks()
	for gate in sim.tentacle_gates: gate.sealed=true
	check(not Art.routes(sim).has(sim.run_secret_floors[0]),"secret backdrop must stay hidden before opening")
	sim.open_secret()
	for i in range(sim.obstacles.size()-1,-1,-1):
		if sim.obstacle_kinds[i].begins_with("wall_crack_"): sim.open_shortcut(i)
	var visible:=scenery.visible_floors(sim,scenery.discovered_rooms(sim))
	var surfaces:=Art.visible_surfaces(sim,visible)
	var transitions:=Art.transition_surfaces(sim,visible)
	var routes: Array=sim.run_corridors.duplicate(); routes.append_array(sim.run_secret_floors)
	for shortcut in sim.DOCKS.SHORTCUTS: routes.append(shortcut.r)
	for route in routes:
		check(transitions.any(func(part):return route.intersects(part)),"new transition covers route, including baked connectors: %s"%route)
		var pieces: Array=[]
		for floor_rect in sim.floors:
			if route.encloses(floor_rect) and not Art.is_authored(sim,floor_rect): pieces.append(floor_rect)
		# Movement checks for free corridor fragments; transitions also cover baked links.
		for piece: Rect2 in pieces:
			checked+=1
			check(Scenery.is_corridor(piece,sim),"corridor fragment classified: %s"%piece)
			check(piece in surfaces,"corridor receives floor and backdrop: %s"%piece)
			for radius in [11.0,23.0]:
				if minf(piece.size.x,piece.size.y)<=radius*2: continue
				var first:=piece.get_center(); var last:=first
				if piece.size.x>piece.size.y:
					first.x=piece.position.x+radius+1; last.x=piece.end.x-radius-1
				else:
					first.y=piece.position.y+radius+1; last.y=piece.end.y-radius-1
				for reverse in [false,true]:
					var p: Vector2=last if reverse else first
					var target: Vector2=first if reverse else last
					for step in ceili(p.distance_to(target)/4): p=sim.move_body(p,(target-p).limit_length(4),radius)
					check(p.distance_to(target)<0.1,"passage r%s %s -> %s"%[radius,p,target])
	check(checked>=15,"coverage must include the full map, not four junctions")
	check(FileAccess.get_sha256("user://expedition.save")==saved_hash,"save unchanged")
	print("ALL_CORRIDORS_FINISH fragments=",checked," routes=",routes.size()," failures=",failures)
	quit(1 if failures else 0)
