extends RefCounted
## Fixed-map adapter for the published reusable module; no authoring writes.
const Catalog = preload("res://scripts/scenarios/module_catalog.gd")
const Connections = preload("res://scripts/scenarios/farol_connections.gd")
const Painter = preload("res://scripts/scenarios/layer_painter.gd")
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
var painter := Painter.new()

static func flat_template() -> Dictionary:
	var data := Catalog.template("docks.farol.pilot")
	if data.get("ok")==false: return data
	data.layers = data.layers.filter(func(layer): return layer.id not in ["landing-top","landing-face","west-flight","east-flight"])
	data.layers[0].texture = "res://assets/environment/docks12/pixellab/floor_0.png"
	data.raised = []; data.ramps = []
	data.obstacles = []
	for p in [Vector2(380,350),Vector2(490,350),Vector2(1090,830),Vector2(1200,830)]:
		data.obstacles.append({"rect":Rect2(p,Vector2(110,40)),"kind":"sandbags","baked":false})
	for p in [Vector2(780,170),Vector2(840,170)]:
		data.obstacles.append({"rect":Rect2(p,Vector2(56,40)),"kind":"crate","baked":false})
	data.obstacles.append({"rect":Rect2(850,220,70,40),"kind":"radio","baked":false})
	return data

static func instance_for(sim) -> Dictionary:
	if sim.mode != "run" or not FileAccess.file_exists(Catalog.INDEX_PATH): return {}
	var room: Dictionary = sim.room_by_id("stairs")
	if room.is_empty(): return {}
	var instance := Rooms.instantiate(flat_template(),"docks.farol.pilot",room.r.position)
	var used: Variant = null
	if sim.layout_manifest.has("edges"):
		used = []
		for edge in sim.layout_manifest.edges:
			if edge.from=="stairs": used.append(edge.from_connector)
			if edge.to=="stairs": used.append(edge.to_connector)
	if not instance.get("ok",false): return {}
	instance = Connections.attach(instance,used)
	instance.layers = instance.layers.filter(func(layer): return not layer.id.begins_with("threshold-"))
	return instance

static func install_geometry(sim) -> void:
	sim.room_by_id("stairs")["name"] = "09 • POSTO DO FAROL"
	sim.scenario_modules.clear()
	sim.scenario_module_ids.clear()
	var instance := instance_for(sim)
	if instance.is_empty(): return
	var area: Rect2 = instance.footprint[0]
	sim.raised = sim.raised.filter(func(rect): return not area.has_point(rect.get_center()))
	sim.ramps = sim.ramps.filter(func(ramp): return not area.has_point(ramp.r.get_center()))
	for i in range(sim.obstacles.size()-1,-1,-1):
		var is_cap: bool = sim.layout_manifest.get("caps_needed",[]).any(func(cap): return cap.room=="stairs" and cap.position==sim.obstacles[i].get_center())
		if is_cap: continue
		if area.has_point(sim.obstacles[i].get_center()):
			sim.obstacles.remove_at(i); sim.obstacle_kinds.remove_at(i); sim.obstacle_hp.remove_at(i)
	for item in instance.obstacles:
		sim.obstacles.append(item.rect); sim.obstacle_kinds.append(item.kind); sim.obstacle_hp.append(sim.DESTRUCTIBLE.get(item.kind,-1.0))
	sim.decor = sim.decor.filter(func(item): return not area.has_point(item.p))
	sim.scenario_modules["stairs"] = instance
	sim.scenario_module_ids.append("docks.farol.pilot")
	sim.rebuild_ob_grid()

static func owns(sim, point: Vector2) -> bool:
	return sim.mode == "run" and sim.scenario_modules.has("stairs") and sim.scenario_modules.stairs.footprint[0].has_point(point)

func ground(ci: CanvasItem, sim, bounds: Rect2) -> void:
	if sim.mode != "run": return
	for instance in sim.scenario_modules.values():
		if ci.seen(instance.footprint[0].get_center(),1000):
			var visual: Dictionary=instance.duplicate()
			visual["footprint"]=[instance.footprint[0]]
			painter.ground(ci,visual,bounds)

func foreground(sim, drawable: Array) -> void:
	if sim.mode != "run": return
	for instance in sim.scenario_modules.values():
		for layer in instance.layers:
			if layer.depth == "foreground": drawable.append({"type":"scenario_layer","data":layer,"y":layer.get("sort_y",layer.rect.end.y)})
