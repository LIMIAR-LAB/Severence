extends SceneTree

# Normaliza as fontes geradas para as grades usadas pelo renderer. Os limites
# ficam nos espaços transparentes entre quadros, sem cortar peças do robô.
const WALK_X := [0, 285, 524, 756, 1002, 1262]
const WALK_Y := [0, 256, 501, 740, 974, 1246]
const BOARD_X := [0, 386, 784, 1170, 1568, 1983]

func _init() -> void:
	var walk := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/titan-mk2/walk-source.png"))
	var cockpit := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/titan-mk2/cockpit-source.png"))
	var board := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/titan-mk2/marty-board-source.png"))
	assert(walk.get_size() == Vector2i(1262, 1246))
	assert(cockpit.get_size() == Vector2i(2172, 724))
	assert(board.get_size() == Vector2i(1983, 793))
	var walk_atlas := Image.create(1760, 880, false, Image.FORMAT_RGBA8)
	for row in range(5):
		for column in range(10):
			var source_column: int = mini(column, 4)
			var region := Rect2i(WALK_X[source_column], WALK_Y[row], WALK_X[source_column + 1] - WALK_X[source_column], WALK_Y[row + 1] - WALK_Y[row])
			place_sprite(walk_atlas, walk.get_region(region), Vector2i(column * 176, row * 176), Vector2i(176, 176), Vector2i(148, 146), 164)
	var cockpit_atlas := Image.create(1056, 176, false, Image.FORMAT_RGBA8)
	for column in range(6):
		place_sprite(cockpit_atlas, cockpit.get_region(Rect2i(column * 362, 0, 362, 724)), Vector2i(column * 176, 0), Vector2i(176, 176), Vector2i(148, 146), 164)
	var board_atlas := Image.create(480, 96, false, Image.FORMAT_RGBA8)
	for column in range(5):
		place_sprite(board_atlas, board.get_region(Rect2i(BOARD_X[column], 0, BOARD_X[column + 1] - BOARD_X[column], 793)), Vector2i(column * 96, 0), Vector2i(96, 96), Vector2i(82, 86), 91)
	var error := walk_atlas.save_png("res://assets/mech/titan_mk2_walk.png")
	if error == OK: error = cockpit_atlas.save_png("res://assets/mech/titan_mk2_cockpit.png")
	if error == OK: error = board_atlas.save_png("res://assets/mech/marty_board_titan.png")
	quit(error)

func place_sprite(target: Image, source: Image, origin: Vector2i, cell: Vector2i, maximum: Vector2i, feet_y: int) -> void:
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			if source.get_pixel(x, y).a < 0.1:
				source.set_pixel(x, y, Color.TRANSPARENT)
	var used := source.get_used_rect()
	assert(used.size.x > 0 and used.size.y > 0)
	var crop := source.get_region(used)
	var scale: float = minf(float(maximum.x) / crop.get_width(), float(maximum.y) / crop.get_height())
	crop.resize(roundi(crop.get_width() * scale), roundi(crop.get_height() * scale), Image.INTERPOLATE_NEAREST)
	var position := origin + Vector2i((cell.x - crop.get_width()) / 2, feet_y - crop.get_height())
	assert(position.x >= origin.x + 4 and position.x + crop.get_width() <= origin.x + cell.x - 4)
	assert(position.y >= origin.y + 4 and position.y + crop.get_height() <= origin.y + cell.y - 4)
	target.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), position)
