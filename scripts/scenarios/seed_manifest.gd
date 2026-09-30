extends RefCounted
## Versioned deterministic selection. Does not own a run or consume gameplay RNG.
const GENERATOR_VERSION := "scn-selection-1"
const SCHEMA_VERSION := 1

static func canonical(value: Variant) -> String:
	if value is Dictionary:
		var keys: Array = value.keys(); keys.sort()
		var pairs: Array[String] = []
		for key in keys: pairs.append(JSON.stringify(str(key)) + ":" + canonical(value[key]))
		return "{" + ",".join(pairs) + "}"
	if value is Array:
		var items: Array[String] = []
		for item in value: items.append(canonical(item))
		return "[" + ",".join(items) + "]"
	if value is Vector2: return canonical([value.x, value.y])
	if value is Rect2: return canonical([value.position.x, value.position.y, value.size.x, value.size.y])
	return JSON.stringify(value)

static func derive(run_seed: int, biome_id: String, floor_index: int, room_id: String, version: String = GENERATOR_VERSION) -> int:
	# 60 bits avoid signed overflow. Tuple encoding prevents ambiguous separators.
	return canonical([str(run_seed), biome_id, floor_index, room_id, version, "map"]).sha256_text().substr(0, 15).hex_to_int()

static func select(sim, biome_id: String, floor_index: int, catalog: Array) -> Dictionary:
	var ordered := catalog.duplicate(true)
	for item in ordered:
		if not item is Dictionary or not item.get("id") is String or not item.get("variants") is Array:
			return {"error": "catalog: expected objects with string id and variants array"}
		for variant in item.variants:
			if not variant is String or variant.is_empty(): return {"error": "catalog: expected nonempty variant ids"}
	ordered.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	var rooms := []; var ids := {}
	for entry in ordered:
		var id := str(entry.get("id", ""))
		if id.is_empty() or ids.has(id) or entry.get("variants", []).is_empty():
			return {"error": "catalog/%s: missing/duplicate id or empty variants" % id}
		ids[id] = true
		entry.variants.sort()
		var local_seed := derive(sim.seed_value, biome_id, floor_index, id)
		var rng := RandomNumberGenerator.new(); rng.seed = local_seed
		rooms.append({"id": id, "template_id": id, "variant_id": entry.variants[rng.randi_range(0, entry.variants.size() - 1)], "map_seed": str(local_seed)})
	return {"schema_version": SCHEMA_VERSION, "generator_version": GENERATOR_VERSION,
		"run_seed": str(sim.seed_value), "seed_source": "legacy_simulation_adapter",
		"limitation": "RunDirector absent; selection bench only, no spatial generation",
		"biome_id": biome_id, "floor_index": floor_index, "catalog_fingerprint": canonical(ordered).sha256_text(),
		"rooms": rooms, "connections": []}
