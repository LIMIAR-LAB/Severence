extends SceneTree
const Module = preload("res://scripts/scenarios/farol_module.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _init() -> void:
	for origin in [Vector2(1800,3700), Vector2(400,-500)]:
		var sim := Expedition.new(); sim.start_run(1941)
		var instance := Module.instantiate(sim, origin, false)
		var authored := Module.instantiate(sim,origin,true)
		check(instance.ok, "valid module")
		Module.install(sim, instance)
		check(instance.connectors.filter(func(c): return c.type=="walk").size() == 3, "west east north preserved")
		check(instance.connectors.filter(func(c): return c.type=="shortcut").size() == 1, "southern legacy shortcut declared")
		check(authored.ok, "native art dimensions and resources validate")
		if authored.ok:
			check(authored.layers.size() == instance.layers.size()+15, "four elevation and eleven exterior wall plates")
			for layer in authored.layers:
				if layer.id.begins_with("wall-"):
					for area in authored.footprint: check(not layer.rect.intersects(area), "exterior walls leave walking footprint clear")
			for layer in authored.layers:
				if layer.id == "landing-face": check(layer.sort_y == origin.y+660, "face sorting translates with geometry")
		var endpoint: Dictionary = instance.connectors[0].duplicate(true)
		var neighbor := endpoint.duplicate(true); neighbor.normal = -endpoint.normal
		check(Module.connection_error(endpoint,neighbor).is_empty(), "matching connector accepted")
		for mutation in [{"normal":null},{"normal":"left"},{"normal":Vector2.ZERO},{"normal":Vector2(1,1)},{"width":0},{"width":-1},{"width":"wide"},{"height":INF},{"height":"high"},{"type":""},{"material_family":" "}]:
			var malformed_a := endpoint.duplicate(true); malformed_a.merge(mutation,true)
			var malformed_b := neighbor.duplicate(true); malformed_b.merge(mutation,true)
			check(not Module.connection_error(malformed_a,malformed_b).is_empty(), "malformed equal endpoints rejected")
		var missing := endpoint.duplicate(true); missing.erase("normal")
		check(not Module.connection_error(missing,neighbor).is_empty(), "missing normal rejected safely")
		for field in ["width","height","type","material_family","normal"]:
			var invalid := neighbor.duplicate(true)
			if field in ["width","height"]: invalid[field] += 1
			elif field == "normal": invalid.normal = endpoint.normal
			else: invalid[field] = "incompatible"
			check(not Module.connection_error(endpoint,invalid).is_empty(), "connector rejects mismatch: "+field)
		for radius in [11, 23]:
			var p: Vector2 = origin + Vector2(190,480)
			for i in 220:
				p = sim.move_body(p, Vector2(6,0), radius)
			check(p.x > origin.x + 1450, "walk across both flights radius%d" % radius)
			for i in 220: p = sim.move_body(p, Vector2(-6,0), radius)
			check(p.x < origin.x + 210, "walk back radius%d" % radius)
			p = origin + Vector2(850,720)
			check(sim.move_body(p, Vector2(0,-100), radius).y >= origin.y+660, "front face blocks walking")
			check(sim.move_body(p, Vector2(0,-100), radius, true).y < origin.y+660, "airborne can cross elevation")
			p = sim.move_body(origin + Vector2(190,480), Vector2(1320,0), radius)
			check(p.x > origin.x+1450, "dash swept through ramp")
		var max_error := 0.0
		for x in range(250,1450):
			var p: Vector2 = origin + Vector2(x,480)
			check(is_equal_approx(Module.projected_foot(p, sim.height_at(p)).y, p.y-sim.height_at(p)), "projection unchanged by actor scale")
			max_error = maxf(max_error, absf(sim.height_at(p)-Module.visual_height(p-origin)))
		check(max_error < 6.0, "quantified physical/visual tread discrepancy")
		for local in [Vector2(340,480),Vector2(850,480),Vector2(1360,480)]:
			var pilot: Dictionary = sim.actors[0]
			pilot.p = origin+local; pilot.mech = true
			sim.mech.p = pilot.p; sim.mech.deployed = true; sim.mech.occupant = 0; sim.mech.cockpit_t = 0
			sim.interact(pilot)
			check(not pilot.mech and sim.clear_at(pilot.p,12), "real Titan exit is clear")
			sim.mech.cockpit_t = 0
		var a: Dictionary = sim.actors[0]
		a.p = origin+Vector2(850,710); a.jump = 0; a.jump_cd = 0
		for frame in 40: sim.step_actor(a,{"move":Vector2.UP,"jump":frame==0},0.016)
		check(a.p.y < origin.y+660 and a.hp > 0, "real jump crosses face and lands on platform")
		a.p = origin+Vector2(240,480); a.dodge = 0; a.dodge_cd = 0; a.jump = 0
		for frame in 18: sim.step_actor(a,{"move":Vector2.RIGHT,"dodge":frame==0},0.016)
		check(a.p.x > origin.x+450, "real dash climbs west flight")
	print("FAROL_TESTS_DONE failures=", failures)
	quit(1 if failures else 0)
