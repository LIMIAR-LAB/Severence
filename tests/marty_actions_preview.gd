extends SceneTree
# 0.19: capturas ampliadas do dash real, sem mover a simulação entre quadros.
func _init() -> void: call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(960,640)
	var view := DockView.new(); view.sim = Expedition.new(); view.sim.coop="solo"; view.sim.start_run(1941)
	view.sim.enemies.clear(); view.sim.actors[1].active=false
	root.add_child(view)
	var camera := Camera2D.new(); camera.zoom = Vector2(2.7,2.7); root.add_child(camera)
	var a: Dictionary = view.sim.actors[0]
	camera.position = a.p; camera.reset_smoothing()
	for shot in [
		{"name":"marty-roll-diagonal","armor":false,"direction":Vector2(1,1),"remaining":0.10},
		{"name":"marty-roll-back-diagonal","armor":false,"direction":Vector2(-1,-1),"remaining":0.10},
		{"name":"marty-omega-teleport-diagonal","armor":true,"direction":Vector2(1,1),"remaining":0.10},
		{"name":"marty-omega-teleport-back","armor":true,"direction":Vector2(-1,-1),"remaining":0.10},
	]:
		a.armor=shot.armor; a.dodge=shot.remaining; a.dash_dir=shot.direction.normalized()
		view.sim.tick_time=3.0; view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-output/" + shot.name + ".png")
	quit()
