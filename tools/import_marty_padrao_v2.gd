extends SceneTree

# Normaliza as novas folhas do Marty Padrao em celulas 96x96.
# As fontes geradas permanecem intactas em art/source/characters.

const CELL := 96
const FOOT_Y := 92
const MAX_ART_WIDTH := 90
const MAX_ART_HEIGHT := 80
const ALPHA_CUTOFF := 24

const SHEETS := [
	["idle-generated-v1.png", "idle.png", 2, 5],
	["run/run-five-views-generated-v1.png", "run.png", 8, 5],
	["jump/jump-five-views-generated-v1.png", "jump.png", 4, 5],
	["evade/roll-five-views-generated-v1.png", "evade.png", 4, 5],
	["shoot/shoot-five-views-generated-v1.png", "shoot.png", 2, 5],
	["melee/melee-five-views-generated-v1.png", "melee.png", 3, 5],
	["hurt/hurt-five-views-generated-v1.png", "hurt.png", 2, 5],
	["defeat/defeat-five-views-generated-v1.png", "defeat.png", 4, 5],
]

const SOURCE_ROOT := "res://art/source/characters/marty/padrao/"
const OUTPUT_ROOT := "res://assets/characters/marty/padrao/"


func _init() -> void:
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_ROOT)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_absolute)
	if mkdir_error != OK:
		push_error("Falha ao criar pasta de saida: " + output_absolute)
		quit(1)
		return

	for spec in SHEETS:
		if not _import_sheet(spec[0], spec[1], spec[2], spec[3]):
			quit(1)
			return

	quit()


func _import_sheet(source_name: String, output_name: String, columns: int, rows: int) -> bool:
	var source_path := SOURCE_ROOT + source_name
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if source == null or source.is_empty():
		push_error("Falha ao abrir " + source_path)
		return false

	var atlas := Image.create(columns * CELL, rows * CELL, false, Image.FORMAT_RGBA8)

	for row in range(rows):
		for column in range(columns):
			var cell := _source_cell(source, column, row, columns, rows)
			var used := cell.get_used_rect()
			if used.size == Vector2i.ZERO:
				continue

			var sprite := cell.get_region(used)
			var scale := minf(
				float(MAX_ART_WIDTH) / sprite.get_width(),
				float(MAX_ART_HEIGHT) / sprite.get_height()
			)
			var target_size := Vector2i(
				maxi(1, roundi(sprite.get_width() * scale)),
				maxi(1, roundi(sprite.get_height() * scale))
			)
			sprite.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
			var destination := Vector2i(
				column * CELL + (CELL - target_size.x) / 2,
				row * CELL + FOOT_Y - target_size.y
			)
			atlas.blit_rect(sprite, Rect2i(Vector2i.ZERO, target_size), destination)

	var output_path := OUTPUT_ROOT + output_name
	var save_error := atlas.save_png(ProjectSettings.globalize_path(output_path))
	if save_error != OK:
		push_error("Falha ao salvar " + output_path)
		return false

	print("ATLAS ", output_path, " ", atlas.get_size())
	return true


func _source_cell(source: Image, column: int, row: int, columns: int, rows: int) -> Image:
	var left := roundi(column * source.get_width() / float(columns))
	var top := roundi(row * source.get_height() / float(rows))
	var right := roundi((column + 1) * source.get_width() / float(columns))
	var bottom := roundi((row + 1) * source.get_height() / float(rows))
	var cell := source.get_region(Rect2i(left, top, right - left, bottom - top))
	# Remove residuos quase transparentes deixados pela geracao. Sem isso, um halo
	# invisivel pode ser interpretado como parte do sprite e reduzir demais o quadro.
	for y in range(cell.get_height()):
		for x in range(cell.get_width()):
			var color := cell.get_pixel(x, y)
			if color.a < float(ALPHA_CUTOFF) / 255.0:
				cell.set_pixel(x, y, Color.TRANSPARENT)
	return cell
