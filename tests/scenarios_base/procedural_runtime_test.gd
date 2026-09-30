extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if not value: failures += 1; push_error(label)
func _init() -> void:
	var sim := Expedition.new(); sim.procedural_enabled = true; sim.coop = "solo"
	var seed_value := 1941
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): seed_value = int(arg.trim_prefix("--seed="))
	var before := Time.get_ticks_msec(); sim.start_run(seed_value)
	check(not sim.layout_manifest.has("fallback") and not sim.layout_manifest.is_empty(),"real layout generated, not fallback")
	if sim.layout_manifest.has("fallback"): print(sim.layout_manifest); quit(1); return
	check(sim.rooms.size()==14,"all authored room roles retained")
	if sim.layout_manifest.get("version","")=="fixed-art-pilot-v1":
		check(sim.room_by_id("cranes").r.position==Vector2(2500,5800),"approved fixed pilot placement")
		check(sim.scenario_geometry_revision==5,"fixed room geometry installed")
		var replica:=Expedition.new(); replica.apply_snapshot(sim.snapshot().duplicate(true))
		check(replica.floors==sim.floors,"fixed pilot snapshot")
		print("FIXED_ART_PILOT_RUNTIME_TEST failures=",failures)
		quit(1 if failures else 0); return
	var chapel_node: Dictionary = sim.layout_manifest.rooms.filter(func(room): return room.id=="chapel")[0]
	check(sim.room_offsets.get("chapel",Vector2.INF)==Vector2.ZERO,"sanctuary pilot retains fixed position")
	check(sim.room_offsets.get("cranes",Vector2.INF)==Vector2.ZERO,"right-of-dock pilot retains fixed position")
	check(sim.clear_at(sim.story_npc_position(),11),"relocated story NPC stands on usable floor")
	var altar: Rect2 = sim.obstacles[sim.obstacle_kinds.find("altar")]
	check(sim.room_by_id("chapel").r.has_point(altar.get_center()),"altar follows its procedural chapel")
	check(sim.layout_manifest.get("topology","")=="seeded-walk-tree-with-loops","normal runtime varies its connection graph")
	check(not sim.layout_manifest.get("dropped_edges",[]).is_empty(),"at least one original connection changes")
	for cap in sim.layout_manifest.get("caps_needed",[]):
		check(not sim.clear_at(cap.position,11),"unused doorway is physically closed")
	var active_farol_ports := []
	for edge in sim.layout_manifest.edges:
		if edge.from=="stairs": active_farol_ports.append(edge.from_connector)
		if edge.to=="stairs": active_farol_ports.append(edge.to_connector)
	check(sim.scenario_modules.stairs.joins.size()==active_farol_ports.size(),"Farol draws only connected passages")
	check(sim.room_offsets.values().filter(func(v): return v!=Vector2.ZERO).size()>=8,"rooms actually relocated")
	for point in ["spawn","shop","side","extraction","mech"]: check(sim.clear_at(sim.run_points[point],11),"safe point "+point)
	var start: int = sim.nav.get_closest_point(sim.actors[0].p)
	for room in sim.rooms:
		if room.kind=="secret": continue
		var destination: int = sim.nav.get_closest_point(room.r.get_center())
		check(sim.nav.get_id_path(start,destination).size()>0,"reachable room "+room.id)
	var replica := Expedition.new(); replica.apply_snapshot(bytes_to_var(var_to_bytes(sim.snapshot())))
	check(replica.floors==sim.floors and replica.run_points==sim.run_points,"snapshot preserves generated geometry and objectives")
	check(replica.layout_manifest==sim.layout_manifest,"snapshot preserves materialized layout")
	check(var_to_bytes(sim.snapshot()).size()<1048576,"snapshot fits online decompression limit")
	check(replica.scenario_modules.stairs.origin==sim.room_by_id("stairs").r.position,"Farol follows generated origin")
	var cracked := []
	for i in sim.obstacles.size():
		if sim.obstacle_kinds[i].begins_with("wall_crack_"): cracked.append(sim.obstacles[i].get_center())
	check(cracked.size()==2,"both shortcuts retain their destructible barriers")
	for point in cracked: check(not sim.clear_at(point,11),"shortcut initially closed")
	for i in range(sim.obstacles.size()-1,-1,-1):
		if sim.obstacle_kinds[i].begins_with("wall_crack_"): sim.open_shortcut(i)
	for point in cracked: check(sim.clear_at(point,11),"shortcut opens after explosion")
	for route in sim.layout_manifest.edges:
		if not route.get("shortcut",false): continue
		check(sim.clear_at(route.to_position+Vector2(0,65),23),"shortcut entrance clear for robot "+route.id)
	sim.open_secret()
	var secret: int = sim.nav.get_closest_point(sim.room_by_id("secret").r.get_center())
	check(sim.nav.get_id_path(sim.nav.get_closest_point(sim.actors[0].p),secret).size()>0,"revealed secret reachable")
	var fight: Dictionary = sim.room_by_id("cranes")
	sim.actors[0].p = fight.r.get_center()+Vector2(0,120)
	sim.hitstop = 0
	sim.step(0.016,[{},{}])
	check(fight.locked,"generated room activates encounter")
	for door in sim.doors:
		if door.room=="cranes": check(sim.gate_blocks.has(door.r),"every generated exit seals during combat")
	sim.enemies = sim.enemies.filter(func(enemy): return enemy.room!="cranes")
	sim.step(0.016,[{},{}])
	check(fight.cleared and not fight.locked,"generated room opens after encounter")
	print("PROCEDURAL_RUNTIME_TESTS_DONE failures=",failures," seed=",seed_value," elapsed_ms=",Time.get_ticks_msec()-before," corridors=",sim.run_corridors.size())
	quit(1 if failures else 0)
