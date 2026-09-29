extends RefCounted
# 0.19: cenário pintado do Desembarque e cicatriz temporal animada.
const MAP = preload("res://scripts/docks_map.gd")
const PAINTING = preload("res://assets/environment/docks12/entry/desembarque_painted_v1.png")

func draw_ground(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	if sim.mode != "run" or not rooms.any(func(r): return r.get("id", "") == "entry"): return
	if MAP.ENTRY_ART_BOUNDS.intersects(view):
		ci.draw_texture_rect(PAINTING, MAP.ENTRY_ART_BOUNDS, false)

func draw_rift(ci: CanvasItem, sim) -> void:
	if sim.mode != "run" or not sim.visited.has("entry"): return
	# tick_time começa em zero na expedição e é replicado nos snapshots coop.
	var t: float = sim.tick_time
	var opening := smoothstep(0.0, 1.6, t)
	if opening < 0.01: return
	var p: Vector2 = MAP.POINTS.spawn + Vector2(-65, -30)
	var pulse := 1.0 + sin(t * 3.0) * 0.07
	# Reflexo suave permanece no chão; a abertura fica atrás do ponto de chegada.
	ci.draw_set_transform(p, 0, Vector2(1.0, 0.32))
	for i in range(5, 0, -1):
		ci.draw_circle(Vector2.ZERO, (35 + i * 11) * opening, Color(0.05, 0.75, 1.0, 0.025))
	ci.draw_set_transform(Vector2.ZERO)
	var center := p - Vector2(0, 62)
	var edge := PackedVector2Array()
	for i in range(64):
		var a := TAU * i / 64.0
		var wobble := 1.0 + 0.07 * sin(a * 7.0 + t * 5.0)
		edge.append(center + Vector2(cos(a) * 27 * opening, sin(a) * 68 * opening) * wobble * pulse)
	ci.draw_colored_polygon(edge, Color(0.06, 0.025, 0.18, 0.65))
	edge.append(edge[0])
	ci.draw_polyline(edge, Color(0.38, 0.15, 1.0, 0.20), 12, true)
	ci.draw_polyline(edge, Color(0.1, 0.9, 1.0, 0.85), 3, true)
	for i in range(12):
		var phase := fposmod(t * 0.42 + i / 12.0, 1.0)
		var a := i * 2.4 + t * 0.2
		var q := center + Vector2(cos(a) * (27 + phase * 35), sin(a) * (65 + phase * 30)) * opening
		ci.draw_circle(q, 1.5 + (1-phase), Color(0.4, 0.8, 1, (1-phase)*0.65))
	if t < 1.6:
		ci.draw_arc(p, 20 + opening * 100, 0, TAU, 48, Color(0.35, 0.8, 1, (1-opening)*0.5), 2, true)
