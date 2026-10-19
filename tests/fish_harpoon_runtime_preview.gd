extends SceneTree
## Real DockView + simulation attack, without the application/save lifecycle.
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1100,700); root.content_scale_size = root.size
	var sim := Expedition.new(); sim.start_arena(); sim.coop = "solo"
	sim.enemies.clear(); sim.bullets.clear(); sim.actors[1].active = false
	var view := DockView.new(); view.sim = sim; root.add_child(view)
	var camera := Camera2D.new(); camera.position = Vector2(650,500); camera.zoom = Vector2(1.7,1.7); root.add_child(camera)
	DirAccess.make_dir_recursive_absolute("res://output/fish-harpoon-v2")
	for pair in [["east",Vector2.RIGHT],["south",Vector2.DOWN],["north-west",Vector2(-1,-1).normalized()]]:
		sim.enemies.clear(); sim.bullets.clear()
		sim.actors[0].p = Vector2(650,500)+pair[1]*220
		sim.spawn_enemy(Vector2(650,500),"fish")
		var fish: Dictionary = sim.enemies[0]
		fish.merge({"combat":"attack","combat_t":0.45,"target_id":0,"locked":sim.actors[0].p,"burst":0,"burst_t":0.0},true)
		sim.step_common_enemy(fish,sim.actors[0],0.001)
		view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/fish-harpoon-v2/runtime-"+pair[0]+".png")
		for bullet in sim.bullets: bullet.p += bullet.v * 0.07
		view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/fish-harpoon-v2/runtime-flight-"+pair[0]+".png")
	view.queue_free(); camera.queue_free(); await process_frame
	print("FISH_HARPOON_RUNTIME_DONE"); quit()
