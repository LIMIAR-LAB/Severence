extends SceneTree
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1600,1000)
	var view := DockView.new(); view.sim = Expedition.new(); view.sim.start_run(1941)
	view.sim.visited.append("entry"); view.sim.enemies.clear()
	view.sim.actors[1].active=false
	root.add_child(view)
	view.scenery.reveal_at["entry"]=-9.0
	var camera := Camera2D.new(); root.add_child(camera)
	for shot in [{"name":"entry-art-general","zoom":0.65,"p":Vector2(1190,6600),"t":3.0},{"name":"entry-art-normal","zoom":1.22,"p":Vector2(850,6550),"t":3.0},{"name":"entry-rift-opening","zoom":1.22,"p":Vector2(850,6550),"t":0.6}]:
		camera.position=shot.p; camera.zoom=Vector2.ONE*shot.zoom; camera.reset_smoothing()
		view.sim.tick_time=shot.t; view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-output/"+shot.name+".png")
	quit()
