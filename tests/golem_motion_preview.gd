extends SceneTree

## Contact sheet: GOLEM-9 — dormant wake, heavy burst cycle, walk, ally summon.
class FakeSim extends Expedition:
	func _init() -> void:
		pass  # skip make_hub — the preview only needs tick_time

class Preview extends DockView:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1400, 1000), Color("141c26"))
		text_at(Vector2(32, 38), "GOLEM-9 / DORMANT + BURST + WALK + DEATH + ALLY", Color.WHITE, 24)
		# linha 1: dormente -> acorda -> telegraph -> rajada -> recupera
		var stages := [["dormant", "ready", 0.0], ["dormant", "ready", 0.0], ["wake", "warning", 0.45],
			["wake", "warning", 0.12], ["wake", "attack", 0.38], ["wake", "attack", 0.18],
			["wake", "recover", 0.8], ["wake", "ready", 0.0]]
		for i in range(8):
			var p := Vector2(110 + i * 170, 260)
			var e := {"kind": "golem", "face": Vector2.DOWN, "p": p,
				"combat": stages[i][1], "combat_t": stages[i][2],
				"step": 0.0, "moving": false, "hurt": 0.0, "shot": 0.0,
				"hp": 520.0, "max": 520.0, "dormant": stages[i][0] == "dormant"}
			visual_origin = p; visual_scale = 1.6
			draw_enemy(e)
			visual_origin = Vector2.ZERO; visual_scale = 1.0
			visual_transform(Vector2.ZERO)
		# linha 2: passos do walk (4) + queda da morte (4)
		for i in range(8):
			var p := Vector2(110 + i * 170, 560)
			if i < 4:
				var e := {"kind": "golem", "face": Vector2(1, 0.35).normalized(), "p": p,
					"combat": "ready", "combat_t": 0.0,
					"step": 0.9 * 8.0 * i / 4.0, "moving": true, "hurt": 0.0, "shot": 0.0,
					"hp": 520.0, "max": 520.0}
				visual_origin = p; visual_scale = 1.6
				draw_enemy(e)
			else:
				var e := {"kind": "golem", "face": Vector2(1, 0.35).normalized(), "p": p,
					"hp": 520.0, "max": 520.0}
				visual_origin = p; visual_scale = 1.6
				draw_enemy_body(e, p, Color.WHITE, 0.28 * (i - 4))
			visual_origin = Vector2.ZERO; visual_scale = 1.0
			visual_transform(Vector2.ZERO)
		# linha 3: aliado em 3 estados
		for i in range(3):
			var p := Vector2(110 + i * 170, 860)
			var s := {"kind": "golem", "p": p, "hp": 520.0,
				"aim": Vector2(0.7, 0.7).normalized(), "moving": i == 1,
				"move_dir": Vector2(-0.6, 0.8).normalized(), "step": i * 2.0,
				"shot": 0.3 if i == 2 else 0.0}
			visual_origin = p; visual_scale = 1.6
			draw_spectre(s)
			visual_origin = Vector2.ZERO; visual_scale = 1.0
			visual_transform(Vector2.ZERO)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	var view := Preview.new()
	view.sim = FakeSim.new()
	root.add_child(view)
	DirAccess.make_dir_recursive_absolute("res://output/enemy-motion-v3/engine")
	root.size = Vector2i(1400, 1000)
	root.content_scale_size = Vector2i(1400, 1000)
	view.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://output/enemy-motion-v3/engine/golem-motion.png")
	print("GOLEM_PREVIEW_DONE")
	quit()
