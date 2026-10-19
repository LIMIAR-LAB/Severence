extends SceneTree
const Sanctuary=preload("res://scripts/scenarios/sanctuary_fixed.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	var sim:=Expedition.new(); sim.start_run(1941)
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks()
	var opening:=Sanctuary.rect(sim,Rect2(1200,738,161,202))
	for y in [opening.position.y+25,opening.get_center().y,opening.end.y-25]:
		for reverse in [false,true]:
			var p:=Vector2(1460 if not reverse else 1880,y)
			var target:=Vector2(1880 if not reverse else 1460,y)
			for frame in 110: p=sim.move_body(p,(target-p).limit_length(4),23)
			check(p.distance_to(target)<1,"whole east opening traversable both ways")
	var before: Array=sim.floors.duplicate()
	Sanctuary.align_east_passage(sim)
	check(sim.floors==before,"alignment idempotent")
	var old:=Rect2(1500,4200,300,200)
	for i in sim.run_corridors.size():
		if sim.run_corridors[i].position.x==1500:
			sim.run_corridors[i]=old
	sim.actors[0].p=Vector2(1750,4225)
	Sanctuary.align_east_passage(sim)
	check(sim.clear_at(sim.actors[0].p,23),"legacy actor on old corridor relocated onto safe floor")
	print("SANCTUARY_PASSAGE_ALIGNMENT failures=",failures)
	quit(1 if failures else 0)
