extends SceneTree

class Preview extends DockView:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 720, 340), Color("202b39"))
		text_at(Vector2(30, 40), "MOTO TEMPORAL", Color("88ebff"), 24)
		text_at(Vector2(56, 280), "ESTACIONADA", Color.WHITE, 16)
		text_at(Vector2(294, 280), "PILOTANDO", Color.WHITE, 16)
		text_at(Vector2(526, 280), "ESQUERDA", Color.WHITE, 16)
		draw_bike_at(Vector2(120, 210))
		var a: Dictionary = sim.actors[0]
		a.p = Vector2(360, 210); a["bike"] = true
		a.facing = Vector2.RIGHT; a.aim = Vector2.RIGHT; a.move = Vector2.RIGHT
		draw_actor(a)
		a.p = Vector2(600, 210); a.facing = Vector2.LEFT; a.aim = Vector2.LEFT; a.move = Vector2.LEFT
		draw_actor(a)

func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	root.size = Vector2i(720, 340)
	root.content_scale_size = Vector2i(720, 340)
	var view := Preview.new()
	view.sim = Expedition.new(); view.sim.start_run(1941)
	view.sim.set_armor(view.sim.actors[0], true)
	view.sim.actors[0].transform = 0.0
	root.add_child(view)
	await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/bike-preview")
	root.get_texture().get_image().save_png("res://output/bike-preview/moto-temporal.png")
	print("BIKE_PREVIEW_OK sprite=", view.bike_visuals.region)
	quit()
