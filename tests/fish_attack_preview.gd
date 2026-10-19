extends SceneTree

## Contact sheet: fish firing — warning windup, harpoon throw, recover.
class Preview extends DockView:
	var clock := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1400, 640), Color("18232e"))
		text_at(Vector2(32, 38), "FISH / HARPOON THROW V3", Color.WHITE, 24)
		# ciclo completo: warning (0-25%) + attack (25-75%) + recover (75-100%)
		var stages := [["warning", 0.42], ["warning", 0.10], ["attack", 0.40], ["attack", 0.28],
			["attack", 0.12], ["recover", 0.82], ["recover", 0.70], ["ready", 0.0]]
		for i in range(8):
			var p := Vector2(100 + i * 170, 240)
			var e := {"kind": "fish", "face": Vector2.DOWN, "p": p,
				"combat": stages[i][0], "combat_t": stages[i][1],
				"step": 0.0, "moving": false, "hurt": 0.0, "shot": 0.0, "hp": 66.0, "max": 66.0}
			visual_origin = p
			visual_scale = 2.2
			draw_enemy(e)
			visual_origin = Vector2.ZERO
			visual_scale = 1.0
			visual_transform(Vector2.ZERO)
		for i in range(8):
			var p := Vector2(100 + i * 170, 520)
			var e := {"kind": "fish", "face": Vector2.RIGHT, "p": p,
				"combat": stages[i][0], "combat_t": stages[i][1],
				"step": 0.0, "moving": false, "hurt": 0.0, "shot": 0.0, "hp": 66.0, "max": 66.0}
			visual_origin = p
			visual_scale = 2.2
			draw_enemy(e)
			visual_origin = Vector2.ZERO
			visual_scale = 1.0
			visual_transform(Vector2.ZERO)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1400, 640)
	root.content_scale_size = Vector2i(1400, 640)
	var view := Preview.new()
	view.sim = Expedition.new()
	root.add_child(view)
	DirAccess.make_dir_recursive_absolute("res://output/enemy-motion-v3/engine")
	for i in range(6):
		view.clock = i * 0.45
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/enemy-motion-v3/engine/fish-attack-%03d.png" % i)
	print("FISH_ATTACK_PREVIEW_DONE")
	quit()
