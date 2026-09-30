extends SceneTree
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const Biomes = preload("res://scripts/scenarios/biome_catalog.gd")

func _initialize() -> void:
	var case_id := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "room_valid"
	var room: Dictionary = Rooms.fixture()
	var records: Array = Biomes.load_records()
	var origin := Vector2.ZERO
	match case_id:
		"room_footprint_null": room.footprint = null
		"room_connector_scalar": room.connectors = [7]
		"room_width_string": room.connectors[0].width = "wide"
		"room_spawn_missing_position": room.spawns = [{"id":"bad"}]
		"room_layer_null": room.layers = [null]
		"room_obstacle_missing_rect": room.obstacles = [{"kind":"wall","baked":false}]
		"room_connector_empty_id": room.connectors[0].id = ""
		"room_connector_bad_height": room.connectors[0].height = "high"
		"room_empty_template_id": room.template_id = ""
		"room_negative_radius": room.spawns[0].radius = -11
		"room_bad_depth": room.layers[0].depth = "invalid"
		"room_point_missing_position": room.points_of_interest = [{"id":"bad"}]
		"room_ramp_missing_rect": room.ramps = [{"axis":"x","low":0,"high":10}]
		"room_raised_scalar": room.raised = [7]
		"room_origin_infinite": origin = Vector2(INF,0)
		"room_origin_nan": origin = Vector2(NAN,0)
		"room_pixel_scale_zero": room.layers[0].world_units_per_pixel = 0
		"room_pixel_scale_negative": room.layers[0].world_units_per_pixel = -1
		"room_version_nan": room.version = NAN
		"biome_materials_null": records[0].materials = null
		"biome_pool_string": records[0].template_pool = "legacy.stairs"
		"biome_fallback_null": records[0].fallback_templates = null
		"biome_rules_null": records[0].connector_rules = null
		"biome_roles_scalar": records[0].room_roles = 7
		"biome_version_string": records[0].version = "one"
		"biome_id_numeric": records[0].biome_id = 42
		"biome_era_empty": records[0].era_id = ""
		"biome_atmosphere_null": records[0].atmosphere = null
		"biome_negative_width": records[0].connector_rules.minimum_width = -1
		"biome_version_nan": records[0].version = NAN
		"biome_empty_pool": records[0].template_pool = []
		"biome_empty_id": records[0].biome_id = ""
	print("PROBE_START ",case_id)
	if case_id.begins_with("biome"):
		var errors: Array[String] = Biomes.validate(records)
		print("PROBE_RESULT ",JSON.stringify({"case":case_id,"accepted":errors.is_empty(),"errors":errors}))
	else:
		var errors: Array[String] = Rooms.validate(room)
		print("VALIDATE_RESULT ",JSON.stringify({"accepted":errors.is_empty(),"errors":errors}))
		var result: Dictionary = Rooms.instantiate(room,"probe",origin)
		print("PROBE_RESULT ",JSON.stringify({"case":case_id,"accepted":result.get("ok",false),"errors":result.get("errors",[])}))
	quit()
