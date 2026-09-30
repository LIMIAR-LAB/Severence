extends SceneTree

class Preview extends DockView:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 800), Color("111924"))
		text_at(Vector2(36, 40), "DOCAS / NOVOS MONSTROS PIXELLAB", Color("b9c8dd"), 24)
		for enemy in sim.enemies:
			visual_origin = enemy.p
			visual_scale = 1.65
			visual_transform(Vector2.ZERO)
			draw_enemy(enemy)
			visual_scale = 1.0
			visual_origin = Vector2.ZERO
			visual_transform(Vector2.ZERO)
		for row in range(5):
			text_at(Vector2(15, 135 + row * 137), ["POLVO", "CULTISTA", "ARPOADOR", "SOLDADO", "FILHOTE"][row], Color("b9c8dd"), 14)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 800)
	var view := Preview.new()
	view.sim = Expedition.new()
	view.sim.start_arena()
	view.sim.enemies.clear()
	view.sim.pending_spawns.clear()
	var directions := [Vector2.DOWN, Vector2(1, 1), Vector2.RIGHT, Vector2(1, -1), Vector2.UP, Vector2(-1, -1), Vector2.LEFT, Vector2(-1, 1)]
	for row in range(5):
		for col in range(8):
			view.sim.spawn_enemy(Vector2(195 + col * 142, 192 + row * 137), ["crawler", "cult", "fish", "brute", "crawler_small"][row])
			var enemy: Dictionary = view.sim.enemies[-1]
			enemy.face = directions[col]
			enemy.moving = false
	root.add_child(view)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/dock-monsters-v2.png")
	quit()
