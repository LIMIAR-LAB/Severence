extends SceneTree

# 0.15: garante que todas as roupas possam usar o mesmo recorte no renderer.
const CELL := 96
const COLUMNS := 10
const ROWS := 20
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)

func require(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)

func alpha_bounds(image: Image, rect: Rect2i) -> Rect2i:
	var left := rect.end.x; var top := rect.end.y; var right := rect.position.x; var bottom := rect.position.y
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if image.get_pixel(x, y).a > 0.01:
				left = mini(left, x); top = mini(top, y); right = maxi(right, x + 1); bottom = maxi(bottom, y + 1)
	return Rect2i(left, top, right - left, bottom - top)

func _init() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/marty/marty_anim_v3.png"))
	check(not image.is_empty(), "atlas v3 existe")
	check(image.get_size() == Vector2i(CELL * COLUMNS, CELL * ROWS), "atlas usa grade 10x20 de células 96px")
	var frames := 0
	for row in range(ROWS):
		for column in range(COLUMNS):
			var bounds := alpha_bounds(image, Rect2i(column * CELL, row * CELL, CELL, CELL))
			require(bounds.size.x > 0 and bounds.size.y > 0, "linha %d coluna %d contém sprite" % [row, column])
			require(bounds.end.y == row * CELL + 92, "linha %d coluna %d mantém pivô dos pés" % [row, column])
			frames += 1
	check(frames == COLUMNS * ROWS, "os 200 quadros compartilham pivô inferior")
	print("MARTY_SPRITE_ATLAS failures=", failures)
	quit(1 if failures else 0)
