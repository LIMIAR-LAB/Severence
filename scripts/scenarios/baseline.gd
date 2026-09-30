extends RefCounted
## Read-only adapter over the effective legacy simulation, including composed geometry.
const OUTPUT := "res://_bmad-output/implementation-artifacts/cenarios-base/captures/"
const SOURCES := ["res://scripts/docks_map.gd", "res://scripts/scenario_layout.gd", "res://scripts/simulation.gd", "res://scripts/world_view.gd", "res://scripts/dock_scenery.gd"]

static func select_room(sim, id: String) -> Dictionary:
	var chosen: Dictionary = sim.room_by_id(id)
	var error := ""
	if chosen.is_empty():
		error = "Sala '%s' inexistente; baseline 'stairs' disponível." % id
		chosen = sim.room_by_id("stairs")
	var bounds: Rect2 = chosen.r
	for wing in chosen.get("extra", []): bounds = bounds.merge(wing)
	return {"room": chosen.duplicate(true), "bounds": bounds, "error": error}

static func capture_path(id: String) -> Dictionary:
	# Never accept paths or write to user://.
	if id not in ["stairs", "cranes", "chapel"]:
		return {"path": OUTPUT + "stairs.png", "error": "Captura '%s' inexistente; use baseline stairs." % id}
	var path := OUTPUT + id + ".png"
	return {"path": path, "error": "" if FileAccess.file_exists(path) else "Captura '%s' ainda não registrada; use bancada baseline." % id}

static func geometry(sim) -> Dictionary:
	var result := {}
	for key in ["rooms", "floors", "obstacles", "obstacle_kinds", "decor", "raised", "ramps", "gaps", "doors", "hazards", "chests"]:
		result[key] = sim.get(key).duplicate(true)
	for key in ["hazards", "decor"]:
		for item in result[key]:
			item.erase("alert"); item.erase("cd")
	return result

static func fingerprint(sim) -> String:
	return var_to_bytes(geometry(sim)).hex_encode().sha256_text()

static func source_hashes() -> Dictionary:
	var hashes := {}
	for path in SOURCES: hashes[path] = FileAccess.get_sha256(path)
	return hashes

static func reference_position(sim, bounds: Rect2) -> Vector2:
	for y in range(int(bounds.position.y + 160), int(bounds.end.y - 80), 40):
		for x in range(int(bounds.position.x + 120), int(bounds.end.x - 80), 40):
			var point := Vector2(x, y)
			if sim.clear_at(point, 24): return point
	return bounds.get_center()
