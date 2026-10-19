extends SceneTree

## DOOM-style portrait tiers: renders the 82px HUD cell for each HP state.
class Preview extends Control:
	var sheet: Texture2D = ImageTexture.create_from_image(Image.load_from_file("res://assets/ui/hud/marty_omega_portraits_v2.png"))
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 460, 130), Color("141c26"))
		var cell := Vector2(sheet.get_width() / 6.0, sheet.get_height())
		var labels := ["FULL", "2 CORACOES", "1 CORACAO", "MEIO"]
		for i in range(4):
			var x := 12 + i * 112
			draw_texture_rect_region(sheet, Rect2(x, 14, 82, 82), Rect2(i * cell.x, 0, cell.x, cell.y))
		var font := ThemeDB.fallback_font
		for i in range(4):
			draw_string(font, Vector2(14 + i * 112, 116), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8fb8c8"))
		# ômega trincada ao lado
		draw_texture_rect_region(sheet, Rect2(460 + 8, 14, 82, 82), Rect2(4 * cell.x, 0, cell.x, cell.y))
		draw_texture_rect_region(sheet, Rect2(460 + 8, 14, 82, 82), Rect2(5 * cell.x, 0, cell.x, cell.y), Color(1, 1, 1, 0.85))

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	var view := Preview.new()
	root.add_child(view)
	DirAccess.make_dir_recursive_absolute("res://output")
	root.size = Vector2i(560, 130)
	root.content_scale_size = Vector2i(560, 130)
	view.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://output/portrait-damage-hud.png")
	print("PORTRAIT_PREVIEW_DONE")
	quit()
