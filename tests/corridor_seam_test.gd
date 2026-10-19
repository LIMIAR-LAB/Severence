extends SceneTree
var failures:=0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	run.call_deferred()
func run() -> void:
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(1941)
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks()
	for radius in [11.0,23.0]:
		var x: float=900+radius+1
		for y in range(5410,5800,8):
			check(sim.clear_at(Vector2(x,y),radius),"straight west side remains walkable at %s radius %s"%[y,radius])
	check(not sim.clear_at(Vector2(870,5700),11),"water outside unchanged deck remains blocked")
	var original:=sim.floors.duplicate()
	sim.SanctuaryFixed.align_south_passage(sim)
	sim.SanctuaryFixed.align_south_passage(sim)
	check(sim.floors==original,"loading repair is idempotent")
	sim.room_by_id("chapel").locked=true; sim.refresh_gate_blocks()
	for door in sim.doors:
		if door.room=="chapel" and door.side=="bottom":
			check(not sim.clear_at(Vector2(912,door.r.get_center().y),11),"repaired strip cannot bypass closed chapel gate")
	print("CORRIDOR_SEAM_TEST failures=",failures)
	quit(1 if failures else 0)
