extends SceneTree
const Geometry=preload("res://scripts/scenarios/cranes_fixed.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func inspect(sim, label: String) -> void:
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks(); sim.ob_grid_count=-1; sim.build_navigation()
	print(label," cranes=",sim.room_by_id("cranes").r.position," offset=",sim.room_offsets.get("cranes")," fallback=",sim.layout_manifest.get("fallback","none"))
	var start: int=sim.nav.get_closest_point(sim.actors[0].p)
	for id in ["cranes","warehouse","rails","boss"]:
		var end: int=sim.nav.get_closest_point(sim.room_by_id(id).r.get_center())
		check(not sim.nav.get_id_path(start,end).is_empty(),label+" objective route "+id)
	for radius in [11.0,23.0]:
		for door in sim.doors:
			if door.room!="cranes" or (door.side=="top" and door.r.get_center().x<Geometry.bounds(sim).position.x+1000): continue
			var normal: Vector2={"left":Vector2.LEFT,"right":Vector2.RIGHT,"top":Vector2.UP}[door.side]
			for direction in [-1.0,1.0]:
				var begin: Vector2=door.r.get_center()-normal*80*direction
				var target: Vector2=begin+normal*160*direction
				var current: Vector2=begin
				for frame in 40: current=sim.move_body(current,normal*4*direction,radius)
				check(current.distance_to(target)<0.1,label+" pass "+door.side+" r"+str(radius))
		var offset: Vector2=sim.room_offsets.get("cranes",Vector2.ZERO)
		var position:=Vector2(2150,6500)+offset
		for frame in 120: position=sim.move_body(position,Vector2(4,0),radius)
		check(position.x>2600+offset.x,label+" Doca corridor r"+str(radius))
	for box in Geometry.BLOCKS: check(not sim.clear_at(Geometry.rect(sim,box).get_center(),11),label+" painted cover blocks")
	for enemy in sim.enemies:
		if enemy.get("room","")=="cranes": check(sim.clear_at(enemy.p,16),label+" safe enemy spawn")
	var copy:=Expedition.new(); copy.apply_snapshot(sim.snapshot().duplicate(true))
	check(copy.floors==sim.floors and copy.obstacles==sim.obstacles,label+" snapshot preserves geometry")
	var fight: Dictionary=sim.room_by_id("cranes")
	sim.actors[0].p=Vector2(3450,6500); sim.hitstop=0; sim.step(0.016,[{},{}])
	check(fight.get("locked",false),label+" combat begins")
	for door in sim.doors:
		if door.room=="cranes": check(sim.gate_blocks.has(door.r),label+" passage seals during combat")
	sim.enemies=sim.enemies.filter(func(e):return e.room!="cranes")
	sim.step(0.016,[{},{}]); check(fight.get("cleared",false) and not fight.get("locked",false),label+" combat completion opens gates")
	var shortcut:=Vector2(2804,5790)
	check(not sim.clear_at(shortcut,11),label+" shortcut initially blocked")
	for i in range(sim.obstacles.size()-1,-1,-1):
		if sim.obstacle_kinds[i].begins_with("wall_crack_") and sim.obstacles[i].grow(20).has_point(shortcut): sim.open_shortcut(i)
	check(sim.clear_at(shortcut,23),label+" destroyed shortcut traversable by Titan")
func _init() -> void:
	var before:=FileAccess.get_sha256("user://expedition.save")
	var saved: Dictionary=FileAccess.open("user://expedition.save",FileAccess.READ).get_var(false)
	var sim:=Expedition.new(); sim.apply_snapshot(saved.state.duplicate(true))
	if Geometry.active(sim): inspect(sim,"saved")
	else: check(sim.room_offsets==saved.state.get("room_offsets",{}),"old expedition placement preserved")
	sim=Expedition.new(); sim.coop="solo"; sim.procedural_enabled=true; sim.start_run(42); inspect(sim,"new42")
	check(not sim.layout_manifest.has("fallback"),"new layout accepted")
	check(sim.room_by_id("cranes").r.position==Vector2(2500,5800),"fixed cranes position")
	check(FileAccess.get_sha256("user://expedition.save")==before,"original save unchanged")
	print("CRANES_FIXED_TEST failures=",failures); quit(1 if failures else 0)




