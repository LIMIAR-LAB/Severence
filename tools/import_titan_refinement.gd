extends SceneTree

# Integra o acabamento gerado à grade original sem alterar frente/lateral.
func _init() -> void:
	var base := Image.load_from_file("res://assets/mech/titan_v3_clean.png")
	var art := Image.load_from_file("res://art/source/titan-rear-refined.png")
	art.resize(base.get_width(), base.get_height(), Image.INTERPOLATE_LANCZOS)
	for y in range(528, 880):
		for x in range(1760):
			var color := art.get_pixel(x, y)
			# Mantém as margens transparentes obrigatórias do atlas.
			if x % 176 < 6 or x % 176 >= 170 or y % 176 < 6 or y % 176 >= 170:
				color = Color(0, 0, 0, 0)
			base.set_pixel(x, y, color)
	var error := base.save_png("res://assets/mech/titan_v4.png")
	quit(error)
