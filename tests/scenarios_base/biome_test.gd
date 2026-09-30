extends SceneTree
const Catalog = preload("res://scripts/scenarios/biome_catalog.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _init() -> void:
	var records := Catalog.load_records()
	check(Catalog.validate(records).is_empty(), "two valid data profiles")
	check(records.size() >= 2 and records[0].materials != records[1].materials, "distinct materials")
	var duplicate := records.duplicate(true); duplicate.append(records[0])
	check(not Catalog.validate(duplicate).is_empty(), "duplicate ids rejected")
	var missing := records.duplicate(true); missing[0].materials.floor = "res://missing.png"
	check(str(Catalog.validate(missing)).contains("materials/floor"), "missing material path")
	var cycle := records.duplicate(true); cycle[0].fallback_profile = cycle[1].biome_id; cycle[1].fallback_profile = cycle[0].biome_id
	check(str(Catalog.validate(cycle)).contains("cycle"), "circular fallback rejected")
	check(Catalog.profile("rail_test").publication == "test_only", "no empty era published")
	print("BIOME_TESTS_DONE failures=", failures)
	quit(1 if failures else 0)
