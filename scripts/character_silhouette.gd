extends Control

# Retratos provisórios de viajantes futuros. Apenas Marty é jogável.
var variant := 0

func _draw() -> void:
	var fill := Color("263c47")
	var rim := Color("587180")
	var x := 62.0
	var head_y := 49.0
	var shoulder := 37.0 + variant * 2.0
	var body := PackedVector2Array([
		Vector2(x - shoulder, 116), Vector2(x - 24, 87), Vector2(x + 24, 87),
		Vector2(x + shoulder, 116), Vector2(x + 48, 158), Vector2(x - 48, 158)])
	draw_colored_polygon(body, fill)
	draw_polyline(body, rim, 2.0)
	draw_line(body[body.size() - 1], body[0], rim, 2.0)
	draw_circle(Vector2(x, head_y), 29, fill)
	draw_arc(Vector2(x, head_y), 29, 0, TAU, 32, rim, 2.0)
	match variant:
		0: # capuz
			draw_polyline(PackedVector2Array([Vector2(28, 64), Vector2(35, 13), Vector2(62, 3), Vector2(89, 13), Vector2(96, 64)]), rim, 3.0)
		1: # viseira
			draw_rect(Rect2(27, 32, 70, 18), Color("365260"))
			draw_line(Vector2(27, 32), Vector2(97, 32), rim, 2.0)
		2: # cabelo comprido
			draw_colored_polygon(PackedVector2Array([Vector2(37, 22), Vector2(87, 22), Vector2(104, 116), Vector2(79, 100), Vector2(44, 100), Vector2(20, 116)]), fill)
			draw_arc(Vector2(x, head_y), 29, PI, TAU, 20, rim, 2.0)
		3: # antena e ombreiras
			draw_line(Vector2(x, 20), Vector2(x, 0), rim, 3.0)
			draw_circle(Vector2(x, 0), 5, rim)
			draw_line(Vector2(15, 105), Vector2(46, 85), rim, 4.0)
			draw_line(Vector2(78, 85), Vector2(109, 105), rim, 4.0)
		4: # chapéu de aba larga
			draw_colored_polygon(PackedVector2Array([Vector2(20, 33), Vector2(35, 10), Vector2(89, 10), Vector2(104, 33)]), fill)
			draw_line(Vector2(9, 34), Vector2(115, 34), rim, 4.0)
