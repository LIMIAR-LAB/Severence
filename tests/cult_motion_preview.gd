extends SceneTree

## Contact sheet: cult v2 — new walk stride, aim+fire with recoil, collapse death.
class FakeSim extends Expedition:
	func _init() -> void:
		pass  # skip make_hub — the preview only needs tick_time

class Preview extends DockView:
	var clock := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1400, 640), Color("18232e"))
		text_at(Vector2(32, 38), "CULT / WALK + FIRE + DEATH V3", Color.WHITE, 24)
		# linha 1: ciclo de ataque (warning -> attack -> recover)
		var stages := [["warning", 0.42], ["warning", 0.10], ["attack", 0.40], ["attack", 0.28],
			["attack", 0.12], ["recover", 0.82], ["recover", 0.70], ["ready", 0.0]]
		for i in range(8):
			var p := Vector2(100 + i * 170, 240)
			var e := {"kind": "cult", "face": Vector2.DOWN, "p": p,
				"combat": stages[i][0], "combat_t": stages[i][1],
				"step": 0.0, "moving": false, "hurt": 0.0, "shot": 0.0, "hp": 40.0, "max": 40.0}
			visual_origin = p; visual_scale = 2.2
			draw_enemy(e)
			visual_origin = Vector2.ZERO; visual_scale = 1.0
			visual_transform(Vector2.ZERO)
		# linha 2: passos do novo walk + queda da morte
		for i in range(8):
			var p := Vector2(100 + i * 170, 520)
			var e: Dictionary
			if i < 5:
				e = {"kind": "cult", "face": Vector2(1, 0.35).normalized(), "p": p,
					"combat": "ready", "combat_t": 0.0,
					"step": 0.9 * 8.0 * i / 4.0, "moving": true, "hurt": 0.0, "shot": 0.0, "hp": 40.0, "max": 40.0}
				visual_origin = p; visual_scale = 2.2
				draw_enemy(e)
			else:
				var fall := 0.35 * (i - 5)
				e = {"kind": "cult", "face": Vector2(1, 0.35).normalized(), "p": p}
				visual_origin = p; visual_scale = 2.2
				draw_enemy_body(e, p, Color.WHITE, fall)
			visual_origin = Vector2.ZERO; visual_scale = 1.0
			visual_transform(Vector2.ZERO)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	print("mark: before view")
	var view := Preview.new()
	view.sim = FakeSim.new()
	print("mark: before add_child")
	root.add_child(view)
	print("mark: added")
	DirAccess.make_dir_recursive_absolute("res://output/enemy-motion-v3/engine")
	root.size = Vector2i(1400, 640)
	root.content_scale_size = Vector2i(1400, 640)
	view.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://output/enemy-motion-v3/engine/cult-motion.png")
	print("CULT_PREVIEW_DONE")
	quit()
