extends SceneTree
const Sanctuary = preload("res://scripts/scenarios/sanctuary_fixed.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	var hash_before := FileAccess.get_sha256("user://expedition.save")
	var saved: Dictionary=FileAccess.open("user://expedition.save",FileAccess.READ).get_var(false)
	var sim:=Expedition.new(); sim.apply_snapshot(saved.state.duplicate(true))
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks(); sim.ob_grid_count=-1; sim.build_navigation()
	for p in [Vector2(800,3450),Vector2(800,4050),Vector2(1430,4350),Vector2(1740,4350),Vector2(1030,5500)]:
		check(sim.clear_at(p,23),"clear pilot passage at "+str(p))
	for source in Sanctuary.BLOCKS:
		check(not sim.clear_at(Sanctuary.rect(sim,source).get_center(),11),"baked furniture blocks player")
	for source in [Vector2(50,700),Vector2(800,200),Vector2(1100,1750)]:
		check(not sim.clear_at(Sanctuary.bounds(sim).position+source*Sanctuary.SCALE,11),"stone perimeter blocks player")
	var replica:=Expedition.new(); replica.apply_snapshot(sim.snapshot().duplicate(true))
	check(replica.floors==sim.floors and replica.obstacles==sim.obstacles,"snapshot keeps traced geometry")
	check(FileAccess.get_sha256("user://expedition.save")==hash_before,"save unchanged")
	print("SANCTUARY_FIXED_TEST failures=",failures)
	quit(1 if failures else 0)
