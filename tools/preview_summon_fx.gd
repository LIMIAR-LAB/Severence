extends SceneTree

# Gera quadros de prévia do efeito de invocar/recolher (sem depender do resto do jogo).
# Uso: godot --path . --rendering-driver opengl3 --resolution 640x360 -s tools/preview_summon_fx.gd
const FX = preload("res://scripts/summon_fx.gd")

class Stage extends Node2D:
	var fxs: Array = []
	var titan: Texture2D
	var spectre: Texture2D
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color("26222e"))
		for y in range(0, 360, 32):
			for x in range(0, 640, 32): draw_rect(Rect2(x + 1, y + 1, 30, 30), Color("2e2a38"))
		# Marty (marcador)
		for hand in [Vector2(90, 250), Vector2(390, 250)]:
			draw_circle(hand + Vector2(0, 30), 12, Color(0, 0, 0, 0.3))
			draw_rect(Rect2(hand + Vector2(-10, -30), Vector2(20, 58)), Color("7a5a44"))
			draw_circle(hand + Vector2(0, -36), 10, Color("e0b890"))
		for fx in fxs: FX.draw_auto(self, fx)

func _initialize() -> void:
	root.content_scale_size = Vector2i(640, 360)
	var stage := Stage.new()
	stage.titan = load("res://assets/mech/titan_v2.png")
	stage.spectre = load("res://assets/mech/spectre.png")
	root.add_child(stage)
	var frames := 24
	for mode in ["summon", "recall"]:
		for i in range(frames):
			var a := FX.summon_effect(0, Vector2(90, 220), Vector2(250, 300), "titan") if mode == "summon" else FX.recall_effect(0, Vector2(90, 220), Vector2(250, 300), "titan")
			var b := FX.summon_effect(0, Vector2(390, 220), Vector2(540, 300), "spectre") if mode == "summon" else FX.recall_effect(0, Vector2(390, 220), Vector2(540, 300), "spectre")
			for fx in [a, b]: fx.life = fx.max * (1.0 - float(i) / (frames - 1))
			stage.fxs = [a, b]
			stage.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_viewport().get_texture().get_image()
			DirAccess.make_dir_recursive_absolute("res://test-output/summon_fx")
			img.save_png("res://test-output/summon_fx/%s_%02d.png" % [mode, i])
	print("PREVIEW_DONE")
	quit()
