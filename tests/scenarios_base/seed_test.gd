extends SceneTree
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _init() -> void:
	var sim := Expedition.new(); sim.start_run(1941)
	var catalog := [{"id": "stairs", "variants": ["baseline", "test"]}, {"id": "chapel", "variants": ["baseline"]}]
	var first := Seeds.select(sim, "docks", 0, catalog)
	for i in 500: sim.rng.randf(); randf()
	check(Seeds.canonical(first) == Seeds.canonical(Seeds.select(sim, "docks", 0, catalog)), "loot/global RNG independence")
	catalog.reverse()
	check(Seeds.canonical(first) == Seeds.canonical(Seeds.select(sim, "docks", 0, catalog)), "catalog order independence")
	check(first.seed_source == "legacy_simulation_adapter", "explicit legacy source")
	check(first.run_seed == "1941", "seed owner is simulation")
	check(Seeds.derive(1941, "docks", 0, "stairs") != Seeds.derive(1941, "docks", 1, "stairs"), "floor separated")
	check(Seeds.select(sim, "docks", 0, [{"id": "x", "variants": []}]).has("error"), "empty variants rejected")
	print("SEED_MANIFEST_TESTS_DONE failures=", failures, " hash=", Seeds.canonical(first).sha256_text())
	quit(1 if failures else 0)
