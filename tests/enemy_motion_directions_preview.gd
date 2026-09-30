extends SceneTree

class Preview extends DockView:
	const FACES := [Vector2.DOWN, Vector2(1, 1), Vector2.RIGHT, Vector2(1, -1),
		Vector2.UP, Vector2(-1, -1), Vector2.LEFT, Vector2(-1, 1)]
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1440, 580), Color("18232e"))
		for row in range(3):
			text_at(Vector2(12, 115 + row * 170), ["ANDA", "ATACA", "CAI"][row], Color.WHITE, 15)
			for col in range(8):
				var p := Vector2(145 + col * 160, 130 + row * 170)
				var e := {"kind": "crawler", "p": p, "face": FACES[col], "moving": row == 0,
					"step": 4.0, "combat": "attack" if row == 1 else "ready",
					"combat_t": 0.3, "shot": 0.0, "hurt": 0.0,
					"hp": 45.0, "max": 45.0}
				var sample: Dictionary = enemy_motion.sample(e, 0.5 if row == 2 else -1.0)
				text_at(p + Vector2(-48, -98), "NOVA" if not sample.is_empty() else "PENDENTE",
					Color("62d1a3") if not sample.is_empty() else Color("e3a667"), 11)
				if row == 2: draw_enemy_body(e, p, Color.WHITE, 0.5)
				else: draw_enemy(e)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1440, 580)
	root.content_scale_size = root.size
	var view := Preview.new()
	view.sim = Expedition.new()
	root.add_child(view)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/enemy-motion-v3/coverage.png")
	quit()
