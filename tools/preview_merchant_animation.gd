extends SceneTree
const View=preload("res://scripts/world_view.gd")
const Merchant=preload("res://scripts/merchant_visuals.gd")
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(640,520); root.content_scale_size=Vector2i(640,520)
	var sim:=Expedition.new(); sim.start_run(1941); sim.enemies.clear(); sim.actors[1].active=false
	sim.actors[0].p=sim.run_points.shop+Vector2(0,100)
	var view:=View.new(); view.sim=sim; root.add_child(view)
	for room in sim.rooms: sim.visited.append(room.id); view.scenery.reveal_at[room.id]=-1.0
	var camera:=Camera2D.new(); root.add_child(camera); camera.zoom=Vector2.ONE*1.3
	camera.position=sim.run_points.shop+Vector2(0,-65); camera.force_update_scroll()
	var frames: Dictionary={}
	DirAccess.make_dir_recursive_absolute("res://output/merchant-animation")
	for i in 64:
		sim.tick_time=float(i)/20.0
		frames[Merchant.motion(Vector2(0.25,0.31),sim.tick_time)]=true
		view.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/merchant-animation/frame-%02d.png"%i)
	print("MERCHANT_ANIMATION motion_samples=",frames.size()," loaded=",view.merchant_visuals.texture!=null)
	quit(0 if frames.size()>50 and view.merchant_visuals.texture!=null else 1)

