extends RefCounted
## SCN room contract v1: world units, local authored geometry, translation only.
const VERSION := 1
const Baseline = preload("res://scripts/scenarios/baseline.gd")
const Metrics = preload("res://scripts/scenarios/inspection_metrics.gd")

static func texture_resource(path: String) -> Texture2D:
	if ResourceLoader.exists(path): return load(path) as Texture2D
	# Authoring benches accept native PNGs before the editor imports them.
	if not path.begins_with("res://art/") or path.get_extension().to_lower() != "png" or not FileAccess.file_exists(path): return null
	var source := Image.new()
	if source.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK: return null
	return ImageTexture.create_from_image(source)

static func contains(room: Dictionary, point: Vector2) -> bool:
	for rect in room.get("footprint", []):
		if rect.has_point(point): return true
	return false

static func clear_at(room: Dictionary, point: Vector2, radius: float) -> bool:
	# Full circle sampling across union permits seams between adjoining footprint pieces.
	if not contains(room, point): return false
	for i in 16:
		if not contains(room, point + Vector2.from_angle(TAU * i / 16.0) * radius): return false
	for obstacle in room.get("obstacles", []):
		if obstacle.rect.grow(radius).has_point(point): return false
	for gap in room.get("gaps", []):
		if gap.grow(radius).has_point(point): return false
	return true

static func validate(t: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var path := "templates/" + str(t.get("template_id", "?"))
	for field in ["template_id", "version", "era_id", "biome_id", "room_role", "footprint", "connectors", "layers", "obstacles", "spawns", "allowed_transforms"]:
		if not t.has(field): errors.append(path + "/" + field + ": required")
	if not errors.is_empty(): return errors
	if t.allowed_transforms != ["translate"]: errors.append(path + "/allowed_transforms: v1 supports translate only")
	errors.append_array(shape_errors(t, path))
	if not errors.is_empty(): return errors
	if t.version != VERSION: errors.append(path + "/version: unsupported")
	if t.footprint.is_empty(): errors.append(path + "/footprint: empty")
	for rect in t.footprint:
		if not rect is Rect2 or not rect.has_area(): errors.append(path + "/footprint: invalid rect")
	if not errors.is_empty(): return errors
	var ids := {}
	for c in t.connectors:
		var cp := path + "/connectors/" + str(c.get("id", "?"))
		if not c.has_all(["id", "position", "normal", "width", "height", "type"]): errors.append(cp + ": incomplete"); continue
		if ids.has(c.id): errors.append(cp + ": duplicate")
		ids[c.id] = true
		if c.normal not in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN] or c.width <= 0:
			errors.append(cp + ": invalid normal/width"); continue
		var tangent: Vector2 = Vector2(-c.normal.y, c.normal.x)
		for offset in [-0.49, 0.0, 0.49]:
			var p: Vector2 = c.position + tangent * c.width * offset
			if not contains(t, p - c.normal * 0.1) or contains(t, p + c.normal * 0.1):
				errors.append(cp + ": aperture outside footprint boundary"); break
	for spawn in t.spawns:
		if not clear_at(t, spawn.position, spawn.get("radius", 11)):
			errors.append(path + "/spawns/" + str(spawn.id) + ": blocked or outside")
	var layer_ids := {}
	for layer in t.layers:
		if not layer.has_all(["id", "rect", "texture", "mode", "depth"]): errors.append(path + "/layers: incomplete"); continue
		if layer_ids.has(layer.id): errors.append(path + "/layers: duplicate " + str(layer.id))
		layer_ids[layer.id] = true
		var texture := texture_resource(layer.texture)
		if layer.mode not in ["tile", "plate"] or texture == null: errors.append(path + "/layers/" + str(layer.id) + ": invalid mode/resource")
		elif layer.mode == "plate":
			if not texture is Texture2D or not Metrics.density(texture.get_size(), layer.rect.size, layer.get("world_units_per_pixel", 1.0)).ok:
				errors.append(path + "/layers/" + str(layer.id) + ": density mismatch; no automatic stretching")
		if not layer.rect.has_area(): errors.append(path + "/layers/" + str(layer.id) + ": empty rect")
	for obstacle in t.obstacles:
		if obstacle.get("baked", false) and not layer_ids.has(obstacle.get("layer_id", "")):
			errors.append(path + "/obstacles: baked geometry needs an existing layer_id")
	return errors

static func shape_errors(t: Dictionary, path: String) -> Array[String]:
	var errors: Array[String] = []
	for field in ["template_id", "era_id", "biome_id", "room_role"]:
		if not t[field] is String or str(t[field]).is_empty(): errors.append(path + "/" + field + ": expected nonempty string")
	for field in ["footprint", "connectors", "layers", "obstacles", "spawns", "allowed_transforms", "points_of_interest", "gaps", "raised", "ramps"]:
		if not t.get(field, []) is Array: errors.append(path + "/" + field + ": expected array")
	if not errors.is_empty(): return errors
	for field in ["footprint", "gaps", "raised"]:
		for rect in t.get(field, []):
			if not rect is Rect2 or not rect.position.is_finite() or not rect.size.is_finite() or not rect.has_area(): errors.append(path + "/" + field + ": invalid rectangle")
	var specs := {
		"connectors": {"id": TYPE_STRING, "position": TYPE_VECTOR2, "normal": TYPE_VECTOR2, "type": TYPE_STRING},
		"layers": {"id": TYPE_STRING, "rect": TYPE_RECT2, "texture": TYPE_STRING, "mode": TYPE_STRING, "depth": TYPE_STRING},
		"obstacles": {"rect": TYPE_RECT2, "kind": TYPE_STRING},
		"spawns": {"id": TYPE_STRING, "position": TYPE_VECTOR2},
		"points_of_interest": {"id": TYPE_STRING, "position": TYPE_VECTOR2},
		"ramps": {"rect": TYPE_RECT2, "axis": TYPE_STRING}}
	for field in specs:
		for i in t.get(field, []).size():
			var item = t[field][i]
			var item_path: String = path + "/" + str(field) + "/" + str(i)
			if not item is Dictionary: errors.append(item_path + ": expected object"); continue
			for key in specs[field]:
				if not item.has(key) or typeof(item[key]) != specs[field][key]: errors.append(item_path + "/" + key + ": missing or invalid type"); continue
				if item[key] is String and item[key].is_empty(): errors.append(item_path + "/" + key + ": empty string")
				if item[key] is Vector2 and not item[key].is_finite(): errors.append(item_path + "/" + key + ": non-finite")
				if item[key] is Rect2 and (not item[key].position.is_finite() or not item[key].size.is_finite() or not item[key].has_area()): errors.append(item_path + "/" + key + ": invalid rect")
			var numbers: Array = {"connectors": ["width", "height"], "ramps": ["low", "high"]}.get(field, [])
			if field == "spawns" and item.has("radius"): numbers = ["radius"]
			if field == "layers" and item.has("world_units_per_pixel"): numbers = ["world_units_per_pixel"]
			for key in numbers:
				if typeof(item.get(key)) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(item[key])): errors.append(item_path + "/" + key + ": expected finite number")
				elif key in ["radius", "world_units_per_pixel", "width"] and float(item[key]) <= 0: errors.append(item_path + "/" + key + ": must be positive")
			if field == "layers" and item.get("depth") not in ["ground", "foreground"]: errors.append(item_path + "/depth: unsupported")
			if field == "ramps" and item.get("axis") not in ["x", "y"]: errors.append(item_path + "/axis: unsupported")
			if field == "obstacles" and typeof(item.get("baked", false)) != TYPE_BOOL: errors.append(item_path + "/baked: expected boolean")
	return errors

static func instantiate(t: Dictionary, instance_id: String, origin: Vector2, transform_id: String = "translate") -> Dictionary:
	var errors := validate(t)
	if not origin.is_finite(): errors.append("origin: expected finite coordinates")
	if transform_id != "translate" or transform_id not in t.get("allowed_transforms", []): errors.append("transform: only translation supported in v1")
	if instance_id.is_empty(): errors.append("instance_id: required")
	if not errors.is_empty(): return {"ok": false, "errors": errors}
	var result := t.duplicate(true)
	result.merge({"ok": true, "instance_id": instance_id, "origin": origin, "transform_id": transform_id}, true)
	for field in ["footprint", "gaps", "raised"]:
		var translated := []
		for rect in result.get(field, []): translated.append(Rect2(rect.position + origin, rect.size))
		result[field] = translated
	for field in ["connectors", "spawns", "points_of_interest"]:
		for item in result.get(field, []): item.position += origin
	for field in ["layers", "obstacles", "ramps"]:
		for item in result.get(field, []):
			item.rect = Rect2(item.rect.position + origin, item.rect.size)
			if field == "layers" and item.has("sort_y"): item.sort_y += origin.y
			if field == "ramps":
				var shift: float = origin.x if item.axis == "x" else origin.y
				item.low += shift; item.high += shift
	return result

static func visible_obstacles(room: Dictionary) -> Array:
	return room.get("obstacles", []).filter(func(o): return not o.get("baked", false))

static func fixture() -> Dictionary:
	return {"template_id": "fixture.wing", "version": VERSION, "era_id": "1941", "biome_id": "rail_test", "room_role": "fight",
		"allowed_transforms": ["translate"], "footprint": [Rect2(0, 0, 300, 240), Rect2(300, 40, 100, 120)],
		"connectors": [{"id": "east", "position": Vector2(400, 100), "normal": Vector2.RIGHT, "width": 80, "height": 0, "type": "walk"}],
		"layers": [{"id": "floor", "rect": Rect2(0, 0, 400, 240), "texture": "res://assets/environment/cobble.png", "mode": "tile", "depth": "ground"}],
		"obstacles": [{"rect": Rect2(40, 40, 60, 40), "kind": "fixture", "baked": true, "layer_id": "floor"}],
		"spawns": [{"id": "player", "position": Vector2(150, 150), "radius": 11}],
		"points_of_interest": [{"id": "goal", "position": Vector2(350, 100)}], "gaps": [], "raised": [], "ramps": []}

static func from_legacy(sim, id: String) -> Dictionary:
	var source: Dictionary = sim.room_by_id(id)
	if source.is_empty(): return {}
	var origin: Vector2 = source.r.position
	var footprint := [Rect2(Vector2.ZERO, source.r.size)]
	for wing in source.get("extra", []): footprint.append(Rect2(wing.position - origin, wing.size))
	var t := {"template_id": "legacy." + id, "version": VERSION, "era_id": "1941", "biome_id": "docks", "room_role": source.kind,
		"allowed_transforms": ["translate"], "footprint": footprint, "connectors": [], "layers": [], "obstacles": [], "spawns": [],
		"points_of_interest": [], "gaps": [], "raised": [], "ramps": [], "provenance": "effective simulation baseline"}
	for i in footprint.size():
		t.layers.append({"id": "floor-%d" % i, "rect": footprint[i], "texture": "res://assets/environment/cobble.png", "material": "floor", "mode": "tile", "depth": "ground"})
	for d in sim.doors:
		if d.room != id: continue
		var normals := {"left": Vector2.LEFT, "right": Vector2.RIGHT, "top": Vector2.UP, "bottom": Vector2.DOWN}
		var normal: Vector2 = normals[d.side]
		var p: Vector2 = d.r.get_center() - normal * (d.r.size.x if normal.x else d.r.size.y) * 0.5 - origin
		t.connectors.append({"id": "door-%d" % t.connectors.size(), "position": p, "normal": normal, "width": d.r.size.y if normal.x else d.r.size.x, "height": 0, "type": "walk"})
	for i in sim.obstacles.size():
		var box: Rect2 = sim.obstacles[i]
		if sim.room_contains(source, box.get_center()): t.obstacles.append({"rect": Rect2(box.position - origin, box.size), "kind": sim.obstacle_kinds[i], "baked": false})
	for field in ["gaps", "raised"]:
		for box in sim.get(field):
			if sim.room_contains(source, box.get_center()): t[field].append(Rect2(box.position - origin, box.size))
	for ramp in sim.ramps:
		if not sim.room_contains(source, ramp.r.get_center()): continue
		var shift: float = origin.x if ramp.axis == "x" else origin.y
		t.ramps.append({"rect": Rect2(ramp.r.position - origin, ramp.r.size), "axis": ramp.axis, "low": ramp.low - shift, "high": ramp.high - shift})
	var bounds: Rect2 = Baseline.select_room(sim, id).bounds
	t.spawns.append({"id": "player", "position": Baseline.reference_position(sim, bounds) - origin, "radius": 11})
	return t
