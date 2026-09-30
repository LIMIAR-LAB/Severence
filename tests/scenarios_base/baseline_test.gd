extends SceneTree
const Bench = preload("res://scripts/scenarios/baseline.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _init() -> void:
	var sim := Expedition.new()
	sim.start_run(1941)
	var before := var_to_bytes(sim.snapshot())
	var room := Bench.select_room(sim, "chapel")
	check(room.error == "", "existing room")
	for wing in room.room.get("extra", []):
		check(room.bounds.encloses(wing), "wings included")
	check(Bench.select_room(sim, "missing").error.contains("missing"), "diagnostic includes id")
	check(Bench.select_room(sim, "missing").room.id == "stairs", "baseline fallback")
	check(Bench.capture_path("missing").error.contains("missing"), "missing capture diagnostic")
	check(before == var_to_bytes(sim.snapshot()), "inspection does not mutate simulation")
	check(Bench.fingerprint(sim) == Bench.fingerprint(sim), "stable baseline")
	var recorded_path: String = Bench.OUTPUT + "baseline.json"
	if FileAccess.file_exists(recorded_path):
		var recorded = JSON.parse_string(FileAccess.get_file_as_string(recorded_path))
		check(recorded.geometry_sha256 == Bench.fingerprint(sim), "effective geometry matches captured baseline; recapture explicitly after upstream changes")
	print("BASELINE_TESTS_DONE failures=", failures)
	quit(1 if failures else 0)
