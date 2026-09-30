extends SceneTree

class Preview extends DockView:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 850), Color("111924"))
		text_at(Vector2(70, 44), "MONSTROS / ATAQUE", Color("b9c8dd"), 24)
		text_at(Vector2(760, 44), "MORTE", Color("b9c8dd"), 24)
		for enemy in sim.enemies:
			visual_origin = enemy.p
			visual_scale = 1.0
			visual_transform(Vector2.ZERO)
			draw_enemy(enemy)
		for fx in sim.effects:
			visual_origin = fx.p
			visual_scale = 1.0
			visual_transform(Vector2.ZERO)
			draw_corpse(fx)
		visual_origin = Vector2.ZERO
		visual_transform(Vector2.ZERO)
		for row in range(6):
			text_at(Vector2(70, 140 + row * 125), ["CULTISTA", "RASTEJANTE", "ARPOADOR", "BRUTAMONTES", "GUARDA", "BOMBARDEIRO"][row], Color("b9c8dd"), 14)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 850)
	var view := Preview.new()
	view.sim = Expedition.new()
	view.sim.start_arena()
	view.sim.enemies.clear()
	view.sim.effects.clear()
	for row in range(6):
		var kind: String = ["cult", "crawler", "fish", "brute", "guard", "bomber"][row]
		var pos := Vector2(470, 150 + row * 125)
		view.sim.spawn_enemy(pos, kind)
		var enemy: Dictionary = view.sim.enemies[-1]
		enemy.face = Vector2.RIGHT
		enemy.combat = "warning" if kind == "bomber" else "attack"
		enemy.shot = 0.15
		view.sim.effects.append({"p": Vector2(850, pos.y), "kind": "corpse", "enemy": kind, "life": 0.8, "max": 1.2, "face": Vector2.RIGHT})
	root.add_child(view)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/enemy-actions-preview.png")
	quit()
