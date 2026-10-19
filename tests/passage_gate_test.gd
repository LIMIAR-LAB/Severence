extends SceneTree
const Preview=preload("res://scripts/scenarios/passage_preview.gd")
const Gate=preload("res://scripts/scenarios/iron_gate_art.gd")
const Scenery=preload("res://scripts/dock_scenery.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate(); run.call_deferred()
func run() -> void:
	var sim:=Expedition.new(); sim.procedural_enabled=true; sim.coop="solo"; sim.start_run(1941)
	sim.visited=["chapel"]; sim.actors[0].p=Vector2(1660,4370)
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks()
	var scenery:=Scenery.new()
	var visible:=scenery.visible_floors(sim,scenery.discovered_rooms(sim))
	var original:=visible.duplicate()
	var pieces:=Preview.pieces(sim,visible)
	check(Preview.pieces(sim,[]).is_empty(),"no floor preview without visible route")
	check(not Preview.pieces(sim,[Rect2(1700,4200,30,200)]).any(func(piece):return piece.id=="stairs"),"remote end cannot preview stairs before visible geometry reaches it")
	check(pieces.any(func(piece):return piece.id=="stairs" and piece.rect.has_point(Vector2(1850,4370))),"stairs floor continues beyond east corridor")
	for piece in pieces:
		check(piece.id!="secret","secret never previewed")
		check(sim.floors.any(func(rect):return rect.encloses(piece.rect)),"preview stays on real floor")
		check(not sim.obstacles.any(func(rect):return rect.intersects(piece.rect)),"preview excludes obstacles")
		check(not sim.gaps.any(func(rect):return rect.intersects(piece.rect)),"preview excludes gaps")
		var far_edge: float=piece.rect.end.x if piece.horizontal and piece.sign>0 else (piece.rect.position.x if piece.horizontal else (piece.rect.end.y if piece.sign>0 else piece.rect.position.y))
		check(absf(far_edge-(piece.end.x if piece.horizontal else piece.end.y))<=Preview.DEPTH+0.01,"preview depth bounded")
	check(sim.visited==["chapel"] and visible==original,"preview never changes discovery")
	for radius in [11.0,23.0]:
		for reverse in [false,true]:
			var position:=Vector2(1660,4370) if not reverse else Vector2(1900,4370)
			var target:=Vector2(1900,4370) if not reverse else Vector2(1660,4370)
			for i in 100: position=sim.move_body(position,(target-position).limit_length(4),radius)
			check(position.distance_to(target)<1,"open passage traversable both directions/radii")
	sim.room_by_id("stairs").locked=true; sim.refresh_gate_blocks()
	var position:=Vector2(1660,4370)
	for i in 100: position=sim.move_body(position,Vector2(4,0),11)
	check(position.x<1800,"closed stairs gate blocks actual entrance")
	var gate:=Gate.new()
	check(gate.texture()!=null and gate.texture().atlas!=null,"gate has a real underlying texture")
	check(not gate.texture().atlas.get_image().is_empty(),"gate image pixels available")
	check(Rect2(Vector2.ZERO,gate.texture().atlas.get_size()).encloses(Gate.SOURCE),"gate crop lies within actual image")
	check(gate.texture().get_width()>2000,"HD gate atlas integrated")
	check(gate.texture().region==Gate.SOURCE,"gate uses meaningful alpha crop")
	for rect in [Rect2(0,0,200,30),Rect2(0,0,30,200)]:
		var shape:=Gate.geometry(rect)
		check(shape.center==rect.get_center() and shape.size.x==212,"gate spans collision footprint")
		check(shape.size.y>=24 and shape.size.y<=72,"gate art height bounded")
	sim.visited.append("stairs")
	check(not Preview.pieces(sim,visible).any(func(piece):return piece.id=="stairs"),"known room no longer needs preview")
	print("PASSAGE_GATE_TEST failures=",failures); quit(1 if failures else 0)
