extends SceneTree
const Adapter = preload("res://scripts/scenarios/procedural_docks.gd")
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
func _init() -> void:
	var sim := Expedition.new(); sim.start_run(1941)
	var data := Adapter.inputs(sim)
	if not data.ok: push_error(str(data)); quit(1); return
	for row in data.rooms:
		var errors := Rooms.validate(row.template)
		if not errors.is_empty(): push_error(str(errors)); quit(1); return
	print("PROCEDURAL_INPUT_TESTS_DONE failures=0 rooms=",data.rooms.size()," edges=",data.edges.size())
	quit()
