extends RefCounted
## Isolated contract binding only. Does not place a floor or route corridors.
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
const VERSION := "scn-contract-adapter-1"

static func reject(message: String) -> Dictionary:
	return {"ok": false, "errors": [message]}

static func compatible(a: Dictionary, b: Dictionary, rules: Dictionary) -> bool:
	return a.normal == -b.normal and a.type == b.type and a.type in rules.connector_types and a.height == b.height and min(a.width, b.width) >= rules.minimum_width

static func adapt(graph: Dictionary, catalog: Array, mapping: Dictionary, run_seed: int, floor_index: int, origins: Dictionary = {}) -> Dictionary:
	if not graph.get("ok", false) or not graph.has_all(["profile_id", "rooms", "edges"]): return reject("graph: invalid")
	if not graph.rooms is Array or not graph.edges is Array or graph.rooms.is_empty(): return reject("graph: empty/invalid collections")
	for node in graph.rooms:
		if not node is Dictionary or not node.has_all(["id", "role"]) or not node.id is String or not node.role is String: return reject("graph: malformed node")
	for edge in graph.edges:
		if not edge is Dictionary or not edge.has_all(["id", "from", "to"]) or not edge.id is String or edge.id.is_empty(): return reject("graph: malformed edge")
		if not edge.from is String or not edge.to is String: return reject("graph: malformed endpoint")
	if not mapping.has(graph.profile_id): return reject("profile: explicit biome mapping required")
	if not mapping[graph.profile_id] is Dictionary: return reject("profile: malformed rules")
	var rules: Dictionary = mapping[graph.profile_id]
	if not rules.has_all(["biome_id", "era_id", "minimum_width", "connector_types"]): return reject("profile: missing connector/era rules")
	if not rules.biome_id is String or rules.biome_id.is_empty() or not rules.era_id is String or rules.era_id.is_empty(): return reject("profile: invalid biome/era ID")
	if not (rules.minimum_width is int or rules.minimum_width is float): return reject("profile: width must be numeric")
	if not is_finite(float(rules.minimum_width)) or rules.minimum_width <= 0: return reject("profile: invalid width")
	if not rules.connector_types is Array or rules.connector_types.is_empty(): return reject("profile: connector types required")
	for type_id in rules.connector_types:
		if not type_id is String or type_id.is_empty(): return reject("profile: invalid connector type")
	for origin in origins.values():
		if not origin is Vector2 or not origin.is_finite(): return reject("origin: finite Vector2 required")
	var biome_id: String = rules.biome_id
	var ordered: Array = catalog.duplicate(true)
	for template in ordered:
		if not template is Dictionary: return reject("catalog: malformed entry")
	ordered.sort_custom(func(a, b): return str(a.get("template_id", "")) < str(b.get("template_id", "")))
	var template_ids: Dictionary = {}
	for template in ordered:
		var errors: Array[String] = Rooms.validate(template)
		if not errors.is_empty(): return {"ok": false, "errors": errors}
		if template_ids.has(template.template_id): return reject("catalog: duplicate template_id")
		template_ids[template.template_id] = true
		# Connector order is semantic-free; normalize before selection/fingerprinting.
		template.connectors.sort_custom(func(a, b): return a.id < b.id)
	var nodes: Array = graph.rooms.duplicate(true)
	nodes.sort_custom(func(a, b): return a.id < b.id)
	var instances: Array = []
	var by_id: Dictionary = {}
	var used: Dictionary = {}
	for node in nodes:
		if str(node.id).is_empty() or by_id.has(node.id): return reject("graph: missing/duplicate room ID")
		var eligible: Array = ordered.filter(func(t): return t.biome_id == biome_id and t.era_id == rules.era_id and t.room_role == node.role and t.get("eligibility", "") == "test_only")
		if eligible.is_empty(): return reject("catalog: no eligible template for " + str(node.role))
		var local_seed: int = Seeds.derive(run_seed, biome_id, floor_index, node.id, VERSION)
		var rng := RandomNumberGenerator.new()
		rng.seed = local_seed
		var template: Dictionary = eligible[rng.randi_range(0, eligible.size()-1)]
		var instance: Dictionary = Rooms.instantiate(template, node.id, origins.get(node.id, Vector2.ZERO))
		if not instance.ok: return instance
		instance["selection_seed"] = str(local_seed)
		instances.append(instance)
		by_id[node.id] = instance
		used[node.id] = []
	var edges: Array = graph.edges.duplicate(true)
	edges.sort_custom(func(a, b): return a.id < b.id)
	var connections: Array = []
	var edge_ids: Dictionary = {}
	var pairs: Dictionary = {}
	for edge in edges:
		if edge_ids.has(edge.id) or not by_id.has(edge.from) or not by_id.has(edge.to) or edge.from == edge.to: return reject("graph: invalid edge")
		edge_ids[edge.id] = true
		var endpoints: Array = [edge.from, edge.to]
		endpoints.sort()
		var pair: String = Seeds.canonical(endpoints)
		if pairs.has(pair): return reject("graph: duplicate endpoints")
		pairs[pair] = true
		var selected: Dictionary = {}
		for a in by_id[edge.from].connectors:
			if used[edge.from].has(a.id): continue
			for b in by_id[edge.to].connectors:
				if used[edge.to].has(b.id) or not compatible(a,b,rules): continue
				selected = {"id":edge.id,"from":edge.from,"to":edge.to,"from_connector":a.id,"to_connector":b.id,"physical_connection_validated":false}
				break
			if not selected.is_empty(): break
		if selected.is_empty(): return reject("connectors: incompatible or exhausted for " + str(edge.id))
		used[edge.from].append(selected.from_connector)
		used[edge.to].append(selected.to_connector)
		connections.append(selected)
	var ordered_graph: Dictionary = graph.duplicate(true)
	ordered_graph.rooms = nodes
	ordered_graph.edges = edges
	return {"ok":true,"schema":"prototype-contract-binding-v1","adapter_version":VERSION,"contract_version":Rooms.VERSION,
		"generator_version":graph.get("version", "unknown"),"run_seed":str(run_seed),"floor_index":floor_index,"biome_id":biome_id,
		"profile_id":graph.profile_id,"binding_rules":rules.duplicate(true),"catalog_fingerprint":Seeds.canonical(ordered).sha256_text(),"graph":ordered_graph,
		"rooms":instances,"connections":connections,"physical_layout_validated":false,"eligibility":"test_only"}
