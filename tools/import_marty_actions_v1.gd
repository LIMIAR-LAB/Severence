extends SceneTree
# 0.19: normaliza as folhas aprovadas em quadros 96x96 com pé em y=92.
# A fonte de cada ação permanece intacta em art/source.
const CELL := 96
const MAX_ART := 88
const SOURCES := [
	["marty-roll-v1.png", "marty_roll_side_v1.png", 4, 4],
	["marty-roll-forward-diagonal-v1.png", "marty_roll_front_diag_v1.png", 4, 4],
	["marty-roll-back-diagonal-v1.png", "marty_roll_back_diag_v1.png", 4, 4],
	["marty-omega-teleport-side-v1.png", "marty_teleport_side_v1.png", 4, 1],
	["marty-omega-teleport-diagonal-v1.png", "marty_teleport_diagonal_v1.png", 4, 2],
]

func _init() -> void:
	for source in SOURCES:
		var input_path: String = "res://art/source/" + source[0]
		var image := Image.load_from_file(ProjectSettings.globalize_path(input_path))
		if image == null or image.is_empty():
			push_error("Falha ao abrir " + input_path); quit(1); return
		var columns: int = source[2]; var rows: int = source[3]
		var atlas := Image.create(columns * CELL, rows * CELL, false, Image.FORMAT_RGBA8)
		for row in range(rows):
			for col in range(columns):
				var left := roundi(col * image.get_width() / float(columns))
				var top := roundi(row * image.get_height() / float(rows))
				var right := roundi((col + 1) * image.get_width() / float(columns))
				var bottom := roundi((row + 1) * image.get_height() / float(rows))
				var tile := image.get_region(Rect2i(left, top, right - left, bottom - top))
				# A geração da Ômega deixou um resíduo da primeira linha no topo da segunda.
				if source[0] == "marty-omega-teleport-diagonal-v1.png" and row == 1:
					tile.fill_rect(Rect2i(0, 0, tile.get_width(), 36), Color.TRANSPARENT)
				var used := tile.get_used_rect()
				if used.size == Vector2i.ZERO: continue
				tile = tile.get_region(used)
				var scale: float = minf(float(MAX_ART) / tile.get_width(), float(MAX_ART) / tile.get_height())
				var size := Vector2i(maxi(1, roundi(tile.get_width() * scale)), maxi(1, roundi(tile.get_height() * scale)))
				tile.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
				var destination := Vector2i(col * CELL + (CELL - size.x) / 2, row * CELL + 92 - size.y)
				atlas.blit_rect(tile, Rect2i(Vector2i.ZERO, size), destination)
		var output_path: String = "res://assets/marty/" + source[1]
		var err := atlas.save_png(ProjectSettings.globalize_path(output_path))
		if err != OK:
			push_error("Falha ao salvar " + output_path); quit(1); return
		print("ATLAS ", output_path, " ", atlas.get_size())
	quit()
