extends SceneTree
const View = preload("res://scripts/world_view.gd")
const OUTPUT := "res://test-output/explosion-v01/"

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size=Vector2i(960,540)
	var saved_hash:=FileAccess.get_sha256("user://expedition.save")
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(42)
	sim.enemies.clear(); sim.bullets.clear(); sim.effects.clear(); sim.actors[1].active=false
	var center: Vector2=sim.room_by_id("cranes").r.get_center()+Vector2(0,130)
	sim.actors[0].p=center+Vector2(0,100)
	sim.spawn_enemy(center+Vector2(220,80),"brute")
	var view:=View.new(); view.sim=sim; root.add_child(view)
	for room in sim.rooms: sim.visited.append(room.id); view.scenery.reveal_at[room.id]=-1.0
	var camera:=Camera2D.new(); root.add_child(camera)
	camera.zoom=Vector2.ONE*1.4; camera.position=center; camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var sheet:=Image.create(1280,360,false,Image.FORMAT_RGB8)
	var selected:=[0,2,5,9,14,19,24,30]
	for frame in 40:
		var elapsed:=float(frame)/60.0
		sim.effects.clear()
		if elapsed<0.4: sim.effects.append({"kind":"explosion","p":center+Vector2(-170,0),"life":0.4-elapsed,"max":0.4,"r":65.0})
		if elapsed<0.55: sim.effects.append({"kind":"explosion","p":center+Vector2(170,0),"life":0.55-elapsed,"max":0.55,"r":125.0})
		sim.tick_time=elapsed
		await process_frame; view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		var shot:=root.get_texture().get_image()
		shot.save_png(OUTPUT+"frame-%02d.png"%frame)
		if frame in selected:
			var i:=selected.find(frame)
			shot.resize(320,180); shot.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(shot,Rect2i(0,0,320,180),Vector2i(i%4*320,i/4*180))
	sheet.save_png(OUTPUT+"sequence.png")
	print("EXPLOSION_CAPTURE_DONE frames=40 save_unchanged=",saved_hash==FileAccess.get_sha256("user://expedition.save"))
	quit()
