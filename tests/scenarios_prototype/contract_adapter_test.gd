extends SceneTree
const Adapter = preload("res://tools/scenarios/prototype/contract_adapter.gd")
const Generator = preload("res://tools/scenarios/prototype/graph_generator.gd")
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
var failures: Array[String] = []
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func fixture(role: String) -> Dictionary:
	var ports: Array = []
	for index in 16:
		for side in ["left", "right"]:
			ports.append({"id":"%s-%02d" % [side,index],"position":Vector2(0 if side == "left" else 4000, 200+240*index),"normal":Vector2.LEFT if side == "left" else Vector2.RIGHT,"width":200,"height":0,"type":"walk"})
	return {"template_id":"test.rail."+role,"version":1,"era_id":"1941","biome_id":"rail_test","room_role":role,
		"eligibility":"test_only","allowed_transforms":["translate"],"footprint":[Rect2(0,0,4000,4000)],"connectors":ports,
		"layers":[],"obstacles":[],"spawns":[{"id":"player","position":Vector2(2000,2000),"radius":11}],"points_of_interest":[],"gaps":[],"raised":[],"ramps":[]}

func _initialize() -> void:
	var catalog: Array = []
	for role in ["entry","transit","optional","clue","miniboss","boss"]: catalog.append(fixture(role))
	var profiles: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/scenarios/prototype/profiles.json"))
	var mapping: Dictionary = {"ferroviario":{"biome_id":"rail_test","era_id":"1941","minimum_width":160,"connector_types":["walk"]}}
	var corpus: Array = []
	var graph: Dictionary = {}
	var result: Dictionary = {}
	for seed_value in range(50):
		graph = Generator.generate(Seeds.derive(seed_value,"rail_test",0,"topology",Generator.VERSION), profiles[1])
		result = Adapter.adapt(graph,catalog,mapping,seed_value,0,{"r0000":Vector2(100,200)})
		check(result.get("ok",false),"Fixture binding rejected")
		if not result.get("ok",false): continue
		check(result.rooms.size() == graph.rooms.size() and result.connections.size() == graph.edges.size(),"Graph identity lost")
		check(result.rooms[0].instance_id == "r0000" and result.rooms[0].connectors[0].position == Vector2(100,400),"Real port translation/identity wrong")
		check(not result.physical_layout_validated,"False physical validity claim")
		var assigned: Dictionary = {}
		for connection in result.connections:
			for key in ["from","to"]:
				var identity: String = connection[key] + ":" + connection[key+"_connector"]
				check(not assigned.has(identity),"Connector reused")
				assigned[identity] = true
		var reverse: Array = catalog.duplicate(true)
		reverse.reverse()
		for template in reverse: template.connectors.reverse()
		check(Seeds.canonical(result) == Seeds.canonical(Adapter.adapt(graph,reverse,mapping,seed_value,0,{"r0000":Vector2(100,200)})),"Catalog order affected binding")
		var reverse_graph: Dictionary = graph.duplicate(true)
		reverse_graph.rooms.reverse()
		reverse_graph.edges.reverse()
		check(Seeds.canonical(result) == Seeds.canonical(Adapter.adapt(reverse_graph,catalog,mapping,seed_value,0,{"r0000":Vector2(100,200)})),"Graph collection order affected binding")
		corpus.append(Seeds.canonical(result).sha256_text())
	check(not Adapter.adapt(graph,catalog,{},0,0).ok,"Missing profile mapping accepted")
	for mutation in [{"minimum_width":"wide"},{"minimum_width":INF},{"biome_id":123},{"connector_types":null},{"connector_types":[42]}]:
		var bad_mapping: Dictionary = mapping.duplicate(true)
		bad_mapping.ferroviario.merge(mutation,true)
		check(not Adapter.adapt(graph,catalog,bad_mapping,0,0).ok,"Malformed binding rules accepted")
	check(not Adapter.adapt(graph,catalog,mapping,0,0,{"r0000":"bad"}).ok,"Malformed origin accepted")
	var malformed: Dictionary = graph.duplicate(true)
	malformed.edges[0].erase("id")
	check(not Adapter.adapt(malformed,catalog,mapping,0,0).ok,"Malformed edge accepted")
	malformed = graph.duplicate(true)
	malformed.edges[0].id = ""
	check(not Adapter.adapt(malformed,catalog,mapping,0,0).ok,"Empty edge ID accepted")
	malformed = graph.duplicate(true)
	malformed.edges[1].id = malformed.edges[0].id
	check(not Adapter.adapt(malformed,catalog,mapping,0,0).ok,"Duplicate edge ID accepted")
	var exhausted: Array = catalog.duplicate(true)
	for template in exhausted: template.connectors = template.connectors.slice(0,2)
	check(not Adapter.adapt(graph,exhausted,mapping,0,0).ok,"Exhausted connector pool accepted")
	for mutation in ["height","normal","width","type","boundary","biome","era","eligibility","role"]:
		var invalid: Array = catalog.duplicate(true)
		for template in invalid:
			match mutation:
				"biome": template.biome_id = "docks"
				"era": template.era_id = "other"
				"eligibility": template.eligibility = "published"
				"role": template.room_role = "fight"
			for port in template.connectors:
				match mutation:
					"height": port.height = 100 if port.normal == Vector2.LEFT else 0
					"normal": port.normal = Vector2.RIGHT
					"width": port.width = 80
					"type": port.type = "jump"
					"boundary": port.position = Vector2(2000,2000)
		var rejected: Dictionary = Adapter.adapt(graph,invalid,mapping,0,0)
		check(not rejected.ok and not rejected.has("rooms") and rejected.has("errors"),"Incompatible accepted: "+mutation)
	var changed: Array = catalog.duplicate(true)
	changed[0].spawns[0].position += Vector2(1,0)
	var changed_result: Dictionary = Adapter.adapt(graph,changed,mapping,49,0)
	check(changed_result.ok and changed_result.catalog_fingerprint != result.catalog_fingerprint,"Content omitted from fingerprint")
	var report: Dictionary = {"engine":Engine.get_version_info().string,"adapter":Adapter.VERSION,"contract":Adapter.Rooms.VERSION,"seeds":50,"corpus_hash":Seeds.canonical(corpus).sha256_text(),"failures":failures,"physical_layout_validated":false}
	var destination := "res://_bmad-output/implementation-artifacts/cenarios-gerador/contract-adapter-tests.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): destination = arg.trim_prefix("--report=")
	var output = FileAccess.open(destination,FileAccess.WRITE)
	if output: output.store_string(Seeds.canonical(report))
	else: check(false,"Cannot write report")
	var sample = FileAccess.open("res://_bmad-output/implementation-artifacts/cenarios-gerador/contract-binding-sample.json",FileAccess.WRITE)
	if sample: sample.store_string(Seeds.canonical(result))
	print(Seeds.canonical(report))
	quit(0 if failures.is_empty() else 1)
