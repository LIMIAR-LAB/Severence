extends SceneTree

## Contact sheet: baú fechado (idle) e sequência completa de abertura.
class Preview extends DockView:
	var clock := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1400, 340), Color("18232e"))
		text_at(Vector2(32, 40), "BAÚ / IDLE + ABERTURA", Color.WHITE, 24)
		# -1 = fechado (idle); >= 0 = segundos desde a abertura
		var stages := [-1.0, -1.0, 0.08, 0.24, 0.36, 0.55, 0.72, 1.8]
		for i in range(stages.size()):
			var p := Vector2(90 + i * 170, 280)
			var chest := {"p": p, "open": stages[i] >= 0.0, "secret": false}
			if chest.open: chest["t"] = sim.tick_time - stages[i]
			draw_chest(chest)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1400, 340)
	root.content_scale_size = Vector2i(1400, 340)
	var view := Preview.new()
	view.sim = Expedition.new()
	root.add_child(view)
	DirAccess.make_dir_recursive_absolute("res://output/chest-preview")
	for i in range(8):
		view.clock = i * 0.31
		view.sim.tick_time = 10.0 + i * 0.31
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/chest-preview/chest-%03d.png" % i)
	print("CHEST_PREVIEW_DONE")
	quit()
