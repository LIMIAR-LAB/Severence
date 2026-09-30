extends RefCounted
## Authored lighthouse pilot. All coordinates local to the room's top-left.
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const ID := "docks.farol.pilot"
const ART_ROOT := "res://art/scenarios/scn-production/farol-docas-v01/stairs/"
const TREAD_HEIGHTS := [0,6,11,17,22,28,33,39]

static func projected_foot(point: Vector2, height: float) -> Vector2:
	return point - Vector2(0,height)

static func visual_height(local: Vector2) -> float:
	if local.y < 300 or local.y >= 660: return 0
	if local.x >= 450 and local.x < 1250: return 44
	if local.x >= 250 and local.x < 450: return TREAD_HEIGHTS[clampi(int((local.x-250)/25),0,7)]
	if local.x >= 1250 and local.x < 1450: return TREAD_HEIGHTS[clampi(int((1450-local.x-0.001)/25),0,7)]
	return 0

static func template(sim, include_art: bool = true) -> Dictionary:
	var data := Rooms.from_legacy(sim, "stairs")
	data.template_id = ID
	data["publication"] = "candidate"
	# Structural props are replaced by authored elevation, not stacked onto it.
	data.obstacles = data.obstacles.filter(func(o): return o.kind not in ["pillar","stone_pillar","wall_block"] and not Rect2(250,300,1200,360).intersects(o.rect))
	data.spawns = [{"id":"player","position":Vector2(190,480),"radius":23}]
	data["repeat_limit"] = 1
	data["neighbor_rules"] = {"material_family":"docks-stone","height":0}
	for connector in data.connectors: connector["material_family"] = "docks-stone"
	# The baseline also has a southern shortcut, gated at its remote end.
	data.connectors.append({"id":"shortcut-south","position":Vector2(1004,1300),"normal":Vector2.DOWN,"width":128,"height":0,"type":"shortcut","material_family":"docks-stone"})
	if include_art:
		# Paths are supplied by the art manifest; incomplete art is rejected by validate.
		var manifest_path := ART_ROOT + "manifest.json"
		if not FileAccess.file_exists(manifest_path): return {"error":"Missing authored stair manifest: " + manifest_path}
		var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if not manifest is Dictionary or not manifest.get("composed_previews") is Dictionary: return {"error":"Stair manifest requires composed_previews"}
		for layer in data.layers:
			layer.texture = manifest.textures.floor; layer.erase("material")
		var authored := [
			{"id":"landing-top","rect":[200,-44,800,360],"texture":manifest.composed_previews.landing_top},
			{"id":"west-flight","rect":[0,-44,200,404],"texture":manifest.composed_previews.west},
			{"id":"east-flight","rect":[1000,-44,200,404],"texture":manifest.composed_previews.east},
			{"id":"landing-face","rect":[200,316,800,44],"texture":manifest.composed_previews.landing_face,"depth":"foreground"}]
		for source in authored:
			var rect: Array = source.rect
			var layer := {"id":source.id, "rect":Rect2(rect[0]+250,rect[1]+300,rect[2],rect[3]), "texture":source.texture,
				"mode":"plate", "depth":source.get("depth","ground"), "projected":true}
			if layer.depth == "foreground": layer["sort_y"] = 660.0
			data.layers.append(layer)
		var walls = JSON.parse_string(FileAccess.get_file_as_string(ART_ROOT+"../walls/manifest.json"))
		if not walls is Dictionary or not walls.get("layers") is Array: return {"error":"Missing wall layers"}
		for authored_wall in walls.layers:
			var wall: Dictionary = authored_wall.duplicate(true)
			var rect: Array = wall.rect
			wall.rect = Rect2(rect[0],rect[1],rect[2],rect[3])
			wall["projected"] = true # Exterior shell intentionally lies outside walkable footprint.
			wall.id = "wall-"+wall.id
			data.layers.append(wall)
	return data

static func instantiate(sim, origin: Vector2, include_art: bool = true) -> Dictionary:
	var data := template(sim, include_art)
	if data.has("error"): return {"ok":false,"errors":[data.error]}
	return Rooms.instantiate(data, ID + "@" + str(origin), origin)

static func install(sim, instance: Dictionary) -> void:
	assert(instance.get("ok",false))
	var first: Rect2 = instance.footprint[0]
	sim.rooms = [{"id":"stairs","r":first,"extra":instance.footprint.slice(1),"kind":"stairs","name":"Farol piloto","floor":"stone"}]
	sim.floors = instance.footprint.duplicate()
	sim.obstacles.clear(); sim.obstacle_kinds.clear(); sim.obstacle_hp.clear()
	for obstacle in instance.obstacles:
		sim.obstacles.append(obstacle.rect); sim.obstacle_kinds.append(obstacle.kind); sim.obstacle_hp.append(-1)
	sim.raised = instance.raised.duplicate(); sim.gaps = instance.gaps.duplicate(); sim.ramps.clear()
	for ramp in instance.ramps: sim.ramps.append({"r":ramp.rect,"axis":ramp.axis,"low":ramp.low,"high":ramp.high})
	sim.gate_blocks.clear(); sim.tentacle_gates.clear(); sim.harpoons.clear()
	sim.decor.clear(); sim.enemies.clear(); sim.effects.clear(); sim.pickups.clear(); sim.chests.clear()
	sim.actors[0].p = instance.spawns[0].position; sim.actors[1].active = false
	sim.mech.p = instance.origin + Vector2(850,720); sim.mech.deployed = false
	sim.rebuild_ob_grid(); sim.build_navigation()

static func connection_error(a: Dictionary, b: Dictionary) -> String:
	for index in 2:
		var endpoint: Dictionary = [a,b][index]
		var path := "connector/" + ("a" if index == 0 else "b") + "/"
		for field in ["width","height"]:
			if typeof(endpoint.get(field)) not in [TYPE_INT,TYPE_FLOAT]: return path+field+": expected number"
			if not is_finite(float(endpoint[field])): return path+field+": expected finite number"
		if endpoint.width <= 0: return path+"width: must be positive"
		for field in ["type","material_family"]:
			if not endpoint.get(field) is String or endpoint[field].strip_edges().is_empty(): return path+field+": expected nonempty string"
		if not endpoint.get("normal") is Vector2: return path+"normal: expected Vector2"
		if endpoint.normal not in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]: return path+"normal: expected cardinal direction"
	for field in ["width","height","type","material_family"]:
		if not a.has(field) or not b.has(field) or a[field] != b[field]: return "connector/"+field+": incompatible"
	if a.normal != -b.normal: return "connector/normal: must face opposite directions"
	return ""
