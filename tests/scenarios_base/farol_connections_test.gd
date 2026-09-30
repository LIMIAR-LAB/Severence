extends SceneTree
const Assembly = preload("res://scripts/scenarios/farol_connections.gd")
const Module = preload("res://scripts/scenarios/farol_module.gd")
const Contract = preload("res://scripts/scenarios/room_contract.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func _init() -> void:
	for origin in [Vector2(1800,3700),Vector2(400,-500)]:
		var sim := Expedition.new(); sim.start_run(1941)
		var assembled := Assembly.assemble(sim,origin)
		check(assembled.ok,"connector manifest binds actual doors")
		if not assembled.ok: continue
		Module.install(sim,assembled)
		for join in assembled.joins:
			for radius in [11,23]:
				var outside: Vector2 = join.position+join.normal*150
				var inside: Vector2 = join.position-join.normal*150
				var point := outside
				for step in 50: point = sim.move_body(point,-join.normal*6,radius)
				check(point.distance_to(inside)<0.1,"inward seam continuous "+join.side)
				for step in 50: point = sim.move_body(point,join.normal*6,radius)
				check(point.distance_to(outside)<0.1,"outward seam continuous "+join.side)
				check(Contract.clear_at(assembled,join.position,radius),"aperture preserves actor clearance")
	print("FAROL_CONNECTIONS_TESTS_DONE failures=",failures)
	quit(1 if failures else 0)
