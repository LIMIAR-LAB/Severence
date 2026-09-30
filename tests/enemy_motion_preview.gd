extends SceneTree

class Preview extends DockView:
	var clock := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 420), Color("18232e"))
		text_at(Vector2(32, 38), "POLVO / SEQUENCIAS PIXELLAB", Color.WHITE, 24)
		for col in range(3):
			var p := Vector2(180 + col * 300, 320)
			text_at(Vector2(95 + col * 300, 390), ["MOVIMENTO", "ATAQUE", "QUEDA"][col], Color.WHITE, 18)
			var e := {"kind": "crawler", "face": Vector2.DOWN, "p": p, "step": clock * 8.0,
				"moving": col == 0, "combat": "ready", "combat_t": 0.0,
				"hurt": 0.0, "shot": 0.0, "hp": 45.0, "max": 45.0}
			visual_origin = p
			visual_scale = 2.5
			if col == 1:
				var phase := fposmod(clock, 1.35)
				if phase < 0.5:
					e.combat = "warning"; e.combat_t = 0.5 - phase
				elif phase < 1.1:
					e.combat = "attack"; e.combat_t = 1.1 - phase
				else:
					e.combat = "recover"; e.combat_t = 0.9 - (phase - 1.1)
			if col == 2:
				draw_enemy_body(e, p, Color.WHITE, minf(clock, 1.0))
			else: draw_enemy(e)
			visual_origin = Vector2.ZERO
			visual_scale = 1.0
			visual_transform(Vector2.ZERO)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(960, 420)
	root.content_scale_size = Vector2i(960, 420)
	var view := Preview.new()
	view.sim = Expedition.new()
	root.add_child(view)
	DirAccess.make_dir_recursive_absolute("res://output/enemy-motion-v3/engine")
	for i in range(48):
		view.clock = i / 30.0
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/enemy-motion-v3/engine/%03d.png" % i)
	quit()
