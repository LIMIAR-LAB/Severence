extends SceneTree

## Contact sheet: fish walking south and east through the full clip.
class Preview extends DockView:
	var clock := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1400, 320), Color("18232e"))
		text_at(Vector2(32, 38), "FISH / WALK V3", Color.WHITE, 24)
		for i in range(8):
			var p := Vector2(100 + i * 170, 240)
			var e := {"kind": "fish", "face": Vector2.DOWN, "p": p,
				"step": clock + i * 0.75, "moving": true, "combat": "ready",
				"combat_t": 0.0, "hurt": 0.0, "shot": 0.0, "hp": 60.0, "max": 60.0}
			visual_origin = p
			visual_scale = 2.2
			draw_enemy(e)
			visual_origin = Vector2.ZERO
			visual_scale = 1.0
			visual_transform(Vector2.ZERO)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1400, 320)
	root.content_scale_size = Vector2i(1400, 320)
	var view := Preview.new()
	view.sim = Expedition.new()
	root.add_child(view)
	DirAccess.make_dir_recursive_absolute("res://output/enemy-motion-v3/engine")
	for i in range(16):
		view.clock = i * 0.45
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/enemy-motion-v3/engine/fish-%03d.png" % i)
	print("FISH_PREVIEW_DONE")
	quit()
