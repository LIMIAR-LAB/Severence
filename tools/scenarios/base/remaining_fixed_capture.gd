extends SceneTree
const View=preload("res://scripts/world_view.gd")
const Fixed=preload("res://scripts/scenarios/remaining_fixed.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,800)
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(42); sim.open_secret()
	sim.enemies.clear(); sim.effects.clear(); sim.bullets.clear(); sim.actors[1].active=false
	var view:=View.new(); view.sim=sim; root.add_child(view)
	var camera:=Camera2D.new(); root.add_child(camera)
	for room in sim.rooms: sim.visited.append(room.id); view.scenery.reveal_at[room.id]=-1.0; room.locked=false
	var output:="res://test-output/remaining-fixed-v01/"
	DirAccess.make_dir_recursive_absolute(output)
	var sheet:=Image.create(1280,1600,false,Image.FORMAT_RGB8)
	var i:=0
	for id in Fixed.DATA.keys()+["forest","bridge"]:
		var room: Rect2=sim.room_by_id(id).r
		camera.zoom=Vector2.ONE*(0.5 if id not in ["forest","bridge"] else 0.8)
		var p:=room.get_center()
		if id=="cellar": p=room.position+Vector2(1100,995)
		if id in ["forest","bridge"]: p=room.position+Vector2(650,room.size.y*0.5)
		sim.actors[0].p=Fixed.safe_point(sim,room,p,11); sim.actors[0].mech=false; sim.mech.deployed=false
		camera.position=room.get_center() if id not in ["forest","bridge"] else p; camera.force_update_scroll()
		await process_frame; view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		var shot:=root.get_texture().get_image(); shot.save_png(output+id+".png")
		shot.resize(426,266); shot.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(shot,Rect2i(0,0,426,266),Vector2i((i%3)*426,(i/3)*266)); i+=1
	for probe in [{"id":"market-detail","room":"market","offset":Vector2(750,550)},{"id":"generator-detail","room":"generator","offset":Vector2(650,550)},{"id":"cellar-detail","room":"cellar","offset":Vector2(1050,700)},{"id":"bridge-collapse","room":"bridge","offset":Vector2(700,200)}]:
		var room: Rect2=sim.room_by_id(probe.room).r
		var p: Vector2=room.position+probe.offset
		if probe.id=="bridge-collapse":
			sim.bridge_broken=[sim.bridge_segments()[0]]; sim.gaps.append_array(sim.bridge_broken)
		camera.zoom=Vector2.ONE*1.05
		sim.actors[0].p=Fixed.safe_point(sim,room,p,11)
		camera.position=p; camera.force_update_scroll()
		await process_frame; view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		var shot:=root.get_texture().get_image(); shot.save_png(output+probe.id+".png")
		shot.resize(426,266); shot.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(shot,Rect2i(0,0,426,266),Vector2i((i%3)*426,(i/3)*266)); i+=1
	sheet.save_png(output+"overview.png")
	print("REMAINING_CAPTURE_DONE rooms=",i); quit()
