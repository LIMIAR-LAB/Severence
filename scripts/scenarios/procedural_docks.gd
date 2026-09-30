extends RefCounted
## Reuses authored room interiors. Generation changes placement and connections.
const Docks = preload("res://scripts/docks_map.gd")
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const Catalog = preload("res://scripts/scenarios/module_catalog.gd")
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
const Layout = preload("res://tools/scenarios/prototype/layout_generator.gd")
const Farol = preload("res://scripts/scenarios/farol_runtime.gd")

static func owner(point: Vector2) -> String:
	var chosen := ""; var distance := INF
	for room in Docks.ROOMS:
		for area in [room.r]+room.get("extra",[]):
			var nearest: Vector2 = point.clamp(area.position,area.end)
			var candidate := point.distance_squared_to(nearest)
			if candidate<distance: distance=candidate; chosen=room.id
	return chosen

static func translated(point: Vector2, offsets: Dictionary) -> Vector2:
	return point+offsets.get(owner(point),Vector2.ZERO)

static func generate(sim) -> Dictionary:
	var source := inputs(sim)
	if not source.ok: return source
	var layout := Layout.generate_layout(sim.seed_value,source.rooms,source.edges,{"variable_topology":true})
	if not layout.ok: return layout
	var offsets := {}
	for room in Docks.ROOMS: offsets[room.id] = layout.origins[room.id]-room.r.position
	var state: Dictionary = sim.snapshot().duplicate(true)
	state["room_offsets"] = offsets
	state["layout_manifest"] = layout.manifest
	state["run_points"] = {}
	for key in Docks.POINTS: state.run_points[key] = translated(Docks.POINTS[key],offsets)
	for room in state.rooms:
		var shift: Vector2 = offsets[room.id]
		room.r = Rect2(room.r.position+shift,room.r.size)
		var wings := []
		for area in room.get("extra",[]): wings.append(Rect2(area.position+shift,area.size))
		room["extra"] = wings
	for field in ["actors","enemies","pickups","chests","decor","hazards"]:
		for item in state[field]: item.p = translated(item.p,offsets)
	state.mech.p = translated(state.mech.p,offsets)
	for robot in state.spectres: robot.p = translated(robot.p,offsets)
	for field in ["obstacles","raised","gaps"]:
		var items := []
		for rect in state[field]: items.append(Rect2(rect.position+offsets[owner(rect.get_center())],rect.size))
		state[field] = items
	for ramp in state.ramps:
		var offset: Vector2 = offsets[owner(ramp.r.get_center())]
		ramp.r = Rect2(ramp.r.position+offset,ramp.r.size)
		var shift: float = offset.x if ramp.axis=="x" else offset.y
		ramp.low += shift; ramp.high += shift
	# Legacy maze walls crossing a declared shortcut throat must not seal it
	# after the independently preserved cracked wall has been destroyed.
	for gate in layout.manifest.get("gates_needed",[]):
		if str(gate.kind).begins_with("wall_crack_"): continue
		for i in range(state.obstacles.size()-1,-1,-1):
			if state.obstacles[i]==gate.rect and state.obstacle_kinds[i]==gate.kind:
				state.obstacles.remove_at(i)
				state.obstacle_kinds.remove_at(i)
				state.obstacle_hp.remove_at(i)
	state.floors = []; state.run_corridors = []; state.run_secret_floors = []; state["run_corridor_groups"] = []
	for room in state.rooms:
		if room.kind=="secret": continue
		state.floors.append(room.r); state.floors.append_array(room.extra)
	for route in layout.manifest.edges:
		var pieces: Array = layout.corridors.slice(route.corridor_start,route.corridor_start+route.corridor_count)
		state.run_corridor_groups.append({"id":route.id,"from":route.from,"to":route.to,"hidden":route.id=="secret","rects":pieces})
		if route.id=="secret": state.run_secret_floors.append_array(pieces)
		else: state.run_corridors.append_array(pieces)
	state.floors.append_array(state.run_corridors)
	state.doors = []
	for port in layout.doors:
		if port.edge_id=="secret": continue
		var normal: Vector2 = port.normal
		var size := Vector2(24,port.width) if normal.x else Vector2(port.width,24)
		var start: Vector2 = port.position-size/2+normal*12
		var side: String = "right" if normal.x>0 else ("left" if normal.x<0 else ("bottom" if normal.y>0 else "top"))
		state.doors.append({"room":port.room,"r":Rect2(start,size),"side":side,"edge_id":port.edge_id})
	for gate in state.tentacle_gates:
		var edge_id: String = "corridor-08" if gate.event=="warden" else "corridor-07"
		for route in layout.manifest.edges:
			if route.id!=edge_id: continue
			var corridor: Rect2 = layout.corridors[route.corridor_start+route.corridor_count/2]
			gate.p = corridor.get_center()
			gate.block = Rect2(gate.p-Vector2(100,100),Vector2(200,200))
	state.gate_blocks.clear()
	for cap in layout.manifest.get("caps_needed",[]):
		var size := Vector2(32,cap.width) if cap.normal.x else Vector2(cap.width,32)
		state.obstacles.append(Rect2(cap.position-size/2,size))
		state.obstacle_kinds.append("wall_block")
		state.obstacle_hp.append(-1.0)
	var candidate = sim.get_script().new()
	candidate.apply_snapshot(state.duplicate(true))
	candidate.ob_grid_count = -1
	candidate.build_navigation()
	var errors := validate_progression(candidate)
	if not errors.is_empty(): return {"ok":false,"errors":errors,"seed":str(sim.seed_value)}
	# No partial generated state is exposed before all fields have been assembled.
	sim.scenario_modules.clear()
	sim.ob_grid_count = -1
	sim.apply_snapshot(state)
	sim.build_navigation()
	return {"ok":true,"manifest":layout.manifest}

static func validate_progression(sim) -> Array:
	var errors := []
	var start: int = sim.nav.get_closest_point(sim.actors[0].p)
	# Unlock only conditions that can already be reached. This detects a
	# generator or warden hidden behind the very gate it must release.
	for stage in sim.tentacle_gates.size():
		for gate in sim.tentacle_gates:
			if gate.sealed: continue
			var prerequisite: Vector2 = sim.run_points.warden if gate.event=="warden" else sim.run_points.side
			var destination: int = sim.nav.get_closest_point(prerequisite)
			if start>=0 and destination>=0 and not sim.nav.get_id_path(start,destination).is_empty():
				gate.sealed = true
				sim.build_navigation()
				start = sim.nav.get_closest_point(sim.actors[0].p)
	for key in ["spawn","shop","side","extraction","mech"]:
		var point: Vector2 = sim.run_points[key]
		var end: int = sim.nav.get_closest_point(point)
		if not sim.clear_at(point,11) or end<0 or start<0 or sim.nav.get_id_path(start,end).is_empty():
			errors.append("seed %s: unsafe/unreachable %s at %s" % [sim.seed_value,key,point])
	for room in sim.rooms:
		if room.kind=="secret": continue
		var end: int = sim.nav.get_closest_point(room.r.get_center())
		if end<0 or start<0 or not sim.room_contains(room,sim.nav.get_point_position(end)) or sim.nav.get_id_path(start,end).is_empty():
			errors.append("seed %s: unreachable room %s" % [sim.seed_value,room.id])
	sim.open_secret()
	var secret: Dictionary = sim.room_by_id("secret")
	var secret_end: int = sim.nav.get_closest_point(secret.r.get_center())
	start = sim.nav.get_closest_point(sim.actors[0].p)
	if secret_end<0 or start<0 or sim.nav.get_id_path(start,secret_end).is_empty():
		errors.append("seed %s: unreachable revealed secret" % sim.seed_value)
	return errors

static func inputs(sim) -> Dictionary:
	var rows := []; var by_id := {}; var edges := []
	for legacy in Docks.ROOMS:
		var data := Farol.flat_template() if legacy.id=="stairs" else Rooms.from_legacy(sim,legacy.id)
		if data.get("ok") == false: return data
		data = data.duplicate(true)
		for connector in data.connectors: connector["material_family"] = "docks-stone"
		data["art_bounds"] = []
		if legacy.id=="entry": data.art_bounds.append(Rect2(Docks.ENTRY_ART_BOUNDS.position-legacy.r.position,Docks.ENTRY_ART_BOUNDS.size))
		elif legacy.id=="chapel": data.art_bounds.append(Rect2(-100,-200,1600,2336.0*1600.0/1744.0))
		else:
			for area in data.footprint: data.art_bounds.append(Rect2(area.position-Vector2(48,230),area.size+Vector2(96,298)))
		var row := {"id":legacy.id,"role":legacy.kind,"template":data}
		if legacy.id in ["entry","boss","chapel","cranes"]: row["fixed_origin"] = legacy.r.position
		rows.append(row); by_id[legacy.id] = row
	for i in Docks.CORRIDORS.size():
		var corridor: Rect2 = Docks.CORRIDORS[i]
		var ends := []
		for legacy in Docks.ROOMS:
			for connector in by_id[legacy.id].template.connectors:
				if connector.type != "walk": continue
				var position: Vector2 = legacy.r.position+connector.position
				if corridor.grow(1).has_point(position) and connector.normal.dot(corridor.get_center()-position)>0:
					ends.append({"room":legacy.id,"connector":connector.id})
		if ends.size()!=2: return {"ok":false,"errors":["Legacy corridor %d has %d endpoints" % [i,ends.size()]]}
		edges.append({"id":"corridor-%02d"%i,"from":ends[0].room,"to":ends[1].room,"from_connector":ends[0].connector,"to_connector":ends[1].connector,"required":ends[0].room=="chapel" or ends[1].room=="chapel"})
	add_connector(by_id,"ammo","secret-exit",Vector2(340,0),Vector2.UP,200,"walk")
	add_connector(by_id,"secret","secret-entry",Vector2(640,700),Vector2.DOWN,200,"walk")
	edges.append({"id":"secret","from":"ammo","to":"secret","from_connector":"secret-exit","to_connector":"secret-entry","hidden":true})
	add_connector(by_id,"cranes","shortcut-north",Vector2(304,0),Vector2.UP,128,"shortcut")
	add_connector(by_id,"rails","shortcut-south",Vector2(1264,1300),Vector2.DOWN,128,"shortcut")
	add_connector(by_id,"warehouse","shortcut-north",Vector2(464,0),Vector2.UP,128,"shortcut")
	edges.append({"id":"shortcut-cranes","from":"stairs","to":"cranes","from_connector":"shortcut-south","to_connector":"shortcut-north","shortcut":true})
	edges.append({"id":"shortcut-warehouse","from":"rails","to":"warehouse","from_connector":"shortcut-south","to_connector":"shortcut-north","shortcut":true})
	return {"ok":true,"rooms":rows,"edges":edges}

static func add_connector(by_id: Dictionary, room: String, id: String, position: Vector2, normal: Vector2, width: float, type: String) -> void:
	by_id[room].template.connectors.append({"id":id,"position":position,"normal":normal,"width":width,"height":0,"type":type,"material_family":"docks-stone"})
