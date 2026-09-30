extends RefCounted
const PATH := "res://scripts/scenarios/biomes.json"
const KNOWN_TEMPLATES := ["legacy.stairs", "legacy.cranes", "legacy.chapel", "fixture.rail"]

static func load_records() -> Array:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Array else []

static func validate(records: Array, templates: Array = KNOWN_TEMPLATES) -> Array[String]:
	var errors: Array[String] = []; var ids := {}
	if records.is_empty(): errors.append("profiles: empty catalog")
	for i in records.size():
		var row = records[i]
		var path := "profiles/%d" % i
		if not row is Dictionary:
			errors.append(path + ": expected object"); continue
		var shape := shape_errors(row, path)
		if not shape.is_empty(): errors.append_array(shape); continue
		var id := str(row.get("biome_id", ""))
		if id.is_empty() or ids.has(id): errors.append(path + "/biome_id: missing or duplicate " + id)
		ids[id] = row
		for field in ["era_id", "version", "publication", "materials", "atmosphere", "room_roles", "template_pool", "connector_rules", "fallback_templates"]:
			if not row.has(field): errors.append(path + "/" + field + ": required")
		for material in ["floor", "wall"]:
			var resource := str(row.get("materials", {}).get(material, ""))
			if not resource.begins_with("res://") or not ResourceLoader.exists(resource): errors.append(path + "/materials/" + material + ": missing " + resource)
		if row.get("publication", "") not in ["baseline_only", "test_only", "candidate", "future", "published"]: errors.append(path + "/publication: unknown")
		for template in row.get("template_pool", []) + row.get("fallback_templates", []):
			if template not in templates: errors.append(path + "/templates: unknown " + str(template))
		if row.get("fallback_templates", []).is_empty(): errors.append(path + "/fallback_templates: empty")
		for fallback in row.get("fallback_templates", []):
			if fallback not in row.get("template_pool", []): errors.append(path + "/fallback_templates: outside biome pool")
	for id in ids:
		var seen := {}; var current: String = id
		while not current.is_empty():
			if seen.has(current): errors.append("profiles/" + id + "/fallback_profile: cycle"); break
			if not ids.has(current): errors.append("profiles/" + id + "/fallback_profile: missing " + current); break
			seen[current] = true; current = str(ids[current].get("fallback_profile", ""))
	return errors

static func shape_errors(row: Dictionary, path: String) -> Array[String]:
	var errors: Array[String] = []
	for field in ["biome_id", "era_id", "publication", "fallback_profile"]:
		if not row.get(field) is String: errors.append(path + "/" + field + ": expected string")
		elif field != "fallback_profile" and row[field].is_empty(): errors.append(path + "/" + field + ": empty string")
	for field in ["materials", "atmosphere", "connector_rules"]:
		if not row.get(field) is Dictionary: errors.append(path + "/" + field + ": expected object")
	for field in ["room_roles", "template_pool", "fallback_templates"]:
		if not row.get(field) is Array: errors.append(path + "/" + field + ": expected array")
		else:
			if row[field].is_empty(): errors.append(path + "/" + field + ": empty pool")
			for item in row[field]:
				if not item is String or item.is_empty(): errors.append(path + "/" + field + ": expected nonempty string IDs")
	if typeof(row.get("version")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(row.version)) or float(row.version) < 1 or floor(float(row.version)) != float(row.version): errors.append(path + "/version: positive integer required")
	if not errors.is_empty(): return errors
	if not row.atmosphere.get("tint") is String or not Color.html_is_valid(row.atmosphere.get("tint", "")): errors.append(path + "/atmosphere/tint: invalid color")
	var rules: Dictionary = row.connector_rules
	if not rules.get("types") is Array or rules.get("types", []).is_empty(): errors.append(path + "/connector_rules/types: nonempty array required")
	else:
		for connector_type in rules.types:
			if not connector_type is String or connector_type.is_empty(): errors.append(path + "/connector_rules/types: expected nonempty strings")
	for field in ["minimum_width", "height_step"]:
		if typeof(rules.get(field)) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(rules[field])) or float(rules[field]) < 0:
			errors.append(path + "/connector_rules/" + field + ": nonnegative finite number required")
	return errors

static func profile(id: String) -> Dictionary:
	var records := load_records()
	var errors := validate(records)
	if not errors.is_empty(): return {"error": errors}
	for row in records:
		if row.biome_id == id: return row.duplicate(true)
	return {"error": "Unknown biome_id '%s'; no cross-biome fallback" % id}
