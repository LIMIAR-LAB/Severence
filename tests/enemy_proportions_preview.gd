extends SceneTree

class Preview extends DockView:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 980), Color("17202e"))
		var kinds := ["crawler", "cult", "fish", "brute", "guard", "bomber", "crawler_small"]
		var labels := ["PARADO", "MOVENDO", "ATIRANDO", "CAINDO", "MORTO"]
		for col in range(5): text_at(Vector2(170 + col * 230, 30), labels[col], Color.WHITE, 16)
		for row in range(kinds.size()):
			text_at(Vector2(12, 115 + row * 125), kinds[row], Color.WHITE, 16)
			for col in range(5):
				var p := Vector2(200 + col * 230, 145 + row * 125)
				draw_line(p - Vector2(60, 0), p + Vector2(100, 0), Color("425267"))
				var e := {"kind": kinds[row], "face": Vector2.DOWN, "moving": col == 1, "step": 0.5, "shot": 0.2 if col == 2 else 0.0, "p": p, "hurt": 0.0, "combat": "attack" if col == 2 else "ready", "hp": 100, "max": 100}
				if col < 3: draw_enemy(e)
				else: draw_corpse({"enemy": kinds[row], "p": p, "face": Vector2.DOWN, "max": 1.2, "life": 1.08 if col == 3 else 0.96})

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 980)
	var view := Preview.new()
	view.sim = Expedition.new()
	root.add_child(view)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/enemy-proportions/after.png")
	quit()
