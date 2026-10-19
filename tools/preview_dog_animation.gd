extends SceneTree
const View=preload("res://scripts/world_view.gd")
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(640,520); root.content_scale_size=Vector2i(640,520)
	var sim:=Expedition.new(); sim.start_run(1941); sim.enemies.clear(); sim.actors[1].active=false
	sim.story_flags["missao_cachorro"]="encontrado"; sim.make_hub(); sim.step_dog(0.01)
	sim.actors[0].p=Vector2(890,440)
	var view:=View.new(); view.sim=sim; root.add_child(view)
	var camera:=Camera2D.new(); root.add_child(camera); camera.zoom=Vector2.ONE*2
	camera.position=Vector2(810,390); camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute("res://output/dog-animation")
	for i in 80:
		sim.tick_time=float(i)/20.0; sim.step_dog(0.05)
		if i==40:
			sim.actors[0].p=sim.hub_dog.p+Vector2(65,0); sim.interact(sim.actors[0])
		view.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/dog-animation/frame-%02d.png"%i)
	print("DOG_ANIMATION loaded=",view.dog_visuals.texture!=null," hub=",not sim.hub_dog.is_empty())
	quit(0 if view.dog_visuals.texture!=null else 1)
