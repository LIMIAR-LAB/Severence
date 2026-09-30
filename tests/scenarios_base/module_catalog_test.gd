extends SceneTree
const Catalog = preload("res://scripts/scenarios/module_catalog.gd")
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const Farol = preload("res://scripts/scenarios/farol_module.gd")
var failures := 0
func check(condition: bool, label: String) -> void:
	if not condition: failures += 1; push_error(label)
func _initialize() -> void:
	var data := Rooms.fixture()
	data.template_id = Catalog.ID
	data["repeat_limit"] = 1
	data["neighbor_rules"] = {"material_family":"docks-stone","height":0}
	var encoded := Catalog.serialize(data)
	check(encoded.ok,"fixture encodes")
	var loaded := Catalog.read_template(encoded.text)
	check(loaded.ok,"roundtrip validates: " + str(loaded.get("errors",[])))
	if loaded.ok:
		check(loaded.data == data,"all fields and geometry survive JSON roundtrip")
		var a := Rooms.instantiate(loaded.data,"a",Vector2(20,30))
		var b := Rooms.instantiate(loaded.data,"b",Vector2(520,630))
		check(a.ok and b.ok,"reloaded template instantiates without simulation")
		check(b.connectors[0].position-a.connectors[0].position == Vector2(500,600),"ports translate at two positions")
		check(b.layers[0].rect.position-a.layers[0].rect.position == Vector2(500,600),"art translates equally")
		check(b.footprint[1].position-a.footprint[1].position == Vector2(500,600),"wing translates equally")
	check(not Catalog.template("../unknown").ok,"unknown ID rejected")
	check(not Catalog.instantiate("unknown",Vector2.ZERO).ok,"unknown instance rejected")
	check(not Catalog.publish(data).ok,"runtime cannot write without authoring flag")
	for text in ['{', '[]', '{"x":{"$type":"Object","values":[]}}', '{"x":{"$type":"Vector2","values":[1]}}', '{"x":{"$type":"Rect2","values":[0,0,"x",4]}}']:
		check(not Catalog.deserialize(text).ok,"malformed codec rejected")
	check(not Catalog.read_template('{}').ok,"missing template rejected")
	check(not Catalog.deserialize('{"x":{"$type":"Vector2","values":[1e100,0]}}').ok,"Vector2 float32 overflow rejected")
	check(not Catalog.deserialize('{"x":{"$type":"Rect2","values":[0,0,1e100,1]}}').ok,"Rect2 float32 overflow rejected")
	check(not Catalog.serialize({"x":Vector2(INF,0)}).ok,"nonfinite vector rejected")
	check(not Catalog.serialize({"x":RefCounted.new()}).ok,"objects never serialized")
	check(not Catalog.serialize({"$type":"Vector2","values":[1,2]}).ok,"reserved tags rejected on encode")
	var invalid := data.duplicate(true)
	invalid.connectors[0].position = Vector2(50,50)
	check(not Catalog.read_template(Catalog.serialize(invalid).text).ok,"invalid door rejected after decode")
	invalid = data.duplicate(true)
	invalid.layers[0]["sort_y"] = "oops"
	check(not Catalog.read_template(Catalog.serialize(invalid).text).ok,"invalid translation field rejected")
	var sim := Expedition.new()
	sim.start_run(1941)
	var authored := Farol.template(sim)
	var authored_json := Catalog.serialize(authored)
	check(authored_json.ok,"current authored Farol encodes")
	if authored_json.ok:
		var reloaded := Catalog.read_template(authored_json.text)
		check(reloaded.ok,"current authored Farol reloads: "+str(reloaded.get("errors",[])))
		if reloaded.ok:
			check(reloaded.data == authored,"all authored plates survive roundtrip")
			for origin in [Vector2.ZERO,Vector2(-350,900)]:
				check(Rooms.instantiate(reloaded.data,"reloaded",origin).ok,"authored reload instantiates without simulation")
	if FileAccess.file_exists(Catalog.INDEX_PATH):
		check(Catalog.instantiate(Catalog.ID,Vector2(200,300)).get("ok",false),"published loader works")
	print("MODULE_CATALOG_TESTS_DONE failures=",failures," publication_performed=false")
	quit(1 if failures else 0)
