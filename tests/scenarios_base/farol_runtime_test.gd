extends SceneTree
const Catalog = preload("res://scripts/scenarios/module_catalog.gd")
var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _init() -> void:
	var sim := Expedition.new(); sim.start_run(1941)
	check(sim.scenario_modules.has("stairs"),"published module active in expedition")
	if sim.scenario_modules.has("stairs"):
		var module: Dictionary = sim.scenario_modules.stairs
		check(module.layers.size() == 19,"16 room layers plus 3 thresholds")
		check(module.connectors.size()==4,"three doors and southern shortcut persisted")
		var area: Rect2 = module.footprint[0]
		var indices := []
		for i in sim.obstacles.size():
			if area.has_point(sim.obstacles[i].get_center()): indices.append(i)
		check(indices.size()==module.obstacles.size(),"no duplicate legacy obstacles")
		for i in indices: check(sim.obstacle_kinds[i] not in ["pillar","stone_pillar","wall_block"],"legacy pillar removed")
		check(sim.doors.filter(func(door): return door.room=="stairs").size()==3,"three functional doors retained")
		check(sim.height_at(Vector2(2650,4180))==44,"runtime platform44")
		for join in module.joins:
			for actor_id in [0,1]:
				var actor: Dictionary = sim.actors[actor_id]
				actor.active = true; actor.dead = false; actor.mech = actor_id==0
				actor.p = join.position+join.normal*140
				sim.mech.p = actor.p; sim.mech.occupant = actor_id if actor.mech else -1; sim.mech.cockpit_t = 0; sim.mech.fuel = sim.FUEL_MAX
				for step in 100: sim.step_actor(actor,{"move":-join.normal},0.016)
				check((actor.p-join.position).dot(join.normal)<-100,"actual Titan/partner crosses "+join.side)
				for step in 100: sim.step_actor(actor,{"move":join.normal},0.016)
				check((actor.p-join.position).dot(join.normal)>100,"actual Titan/partner returns "+join.side)
				actor.mech = false
	var replica := Expedition.new(); replica.apply_snapshot(sim.snapshot())
	check(replica.scenario_modules.has("stairs"),"replica rehydrates module from catalog")
	check(replica.obstacles==sim.obstacles,"replica keeps host collision")
	var legacy := sim.snapshot(); legacy.erase("scenario_module_ids")
	replica.apply_snapshot(legacy)
	check(replica.scenario_modules.is_empty(),"legacy snapshot retains legacy rendering")
	print("FAROL_RUNTIME_TESTS_DONE failures=",failures)
	quit(1 if failures else 0)
