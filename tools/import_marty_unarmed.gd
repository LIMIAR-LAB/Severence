extends SceneTree
# 0.18: normaliza poses sem armas e cria passadas por deslocamento dos pés.
func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/marty-todas-skins-sem-armas-v1.png"))
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var c := source.get_pixel(x, y)
			if c.a < 0.1: source.set_pixel(x, y, Color(0,0,0,0))
	var atlas := Image.create(960, 1920, false, Image.FORMAT_RGBA8)
	var ys := [0, 300, 585, 860, 1108]
	for outfit in range(4):
		for view in range(5):
			var x0 := roundi(view * source.get_width() / 5.0)
			var x1 := roundi((view + 1) * source.get_width() / 5.0)
			var tile := source.get_region(Rect2i(x0, ys[outfit], x1 - x0, ys[outfit + 1] - ys[outfit]))
			var cropped := tile.get_region(tile.get_used_rect())
			var height := 76 if outfit != 3 else 80
			cropped.resize(roundi(cropped.get_width() * float(height) / cropped.get_height()), height, Image.INTERPOLATE_NEAREST)
			cropped = cropped.get_region(cropped.get_used_rect())
			var frame := Image.create(96, 96, false, Image.FORMAT_RGBA8)
			frame.blit_rect(cropped, Rect2i(Vector2i.ZERO, cropped.get_size()), Vector2i(48 - cropped.get_width() / 2, 92 - cropped.get_height()))
			for col in range(10):
				var pose := frame.duplicate() as Image
				if col in [1, 2, 3, 4]:
					var shift := 2 if col in [1, 2] else -2
					pose.fill_rect(Rect2i(0, 74, 96, 22), Color(0,0,0,0))
					pose.blit_rect(frame, Rect2i(0, 74, 48, 22), Vector2i(shift, 74))
					pose.blit_rect(frame, Rect2i(48, 74, 48, 22), Vector2i(48 - shift, 74))
				atlas.blit_rect(pose, Rect2i(0,0,96,96), Vector2i(col * 96, (outfit * 5 + view) * 96))
	quit(atlas.save_png("res://assets/marty/marty_anim_v3.png"))

