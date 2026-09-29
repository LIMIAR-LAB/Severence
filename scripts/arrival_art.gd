extends RefCounted
# 0.19: cenário pintado do Desembarque e cicatriz temporal animada.
const MAP = preload("res://scripts/docks_map.gd")
const PAINTING = preload("res://assets/environment/docks12/entry/desembarque_painted_v1.png")

func draw_ground(ci: CanvasItem, sim, rooms: Array, view: Rect2, lights: Array) -> void:
	if sim.mode != "run" or not rooms.any(func(r): return r.get("id", "") == "entry"): return
	if MAP.ENTRY_ART_BOUNDS.intersects(view):
		ci.draw_texture_rect(PAINTING, MAP.ENTRY_ART_BOUNDS, false)
		draw_environment(ci, sim.tick_time, lights)

# 0.19: coordenadas da pintura; água longe do piso e reflexos discretos nas poças.
const WATER_AREAS = [Rect2(280, 932, 770, 88), Rect2(1370, 610, 165, 125), Rect2(4, 250, 12, 530)]
const LAMPS = [Vector2(364,68), Vector2(535,22), Vector2(932,112), Vector2(1148,116), Vector2(1127,232), Vector2(1490,331), Vector2(307,718), Vector2(1004,736)]
const PUDDLES = [Vector2(369,217), Vector2(539,226), Vector2(935,237), Vector2(1144,289), Vector2(446,476), Vector2(959,517), Vector2(649,661)]

static func to_world(local: Vector2) -> Vector2:
	# Converte um ponto em pixels da pintura (0..1536, 0..1024) para coordenadas de mundo —
	# mesma escala usada no draw_set_transform de draw_environment().
	return MAP.ENTRY_ART_BOUNDS.position + local * (MAP.ENTRY_ART_BOUNDS.size / Vector2(1536, 1024))

func draw_environment(ci: CanvasItem, t: float, lights: Array) -> void:
	ci.draw_set_transform(MAP.ENTRY_ART_BOUNDS.position, 0, MAP.ENTRY_ART_BOUNDS.size / Vector2(1536,1024))
	# Filetes de água avançam e desaparecem antes de reiniciar, sem saltos na borda.
	for area_index in range(WATER_AREAS.size()):
		var area: Rect2 = WATER_AREAS[area_index]
		# Reamostra a própria pintura em faixas: as ondas e reflexos originais também se movem.
		for row in range(12):
			var strip := Rect2(area.position+Vector2(0,row*area.size.y/12),Vector2(area.size.x,area.size.y/12))
			var drift := Vector2(sin(t*1.4+row*0.7)*1.8,cos(t*1.1+row*0.6)*0.8)
			ci.draw_texture_rect_region(PAINTING,strip,Rect2(strip.position+drift,strip.size),Color(1,1,1,sin((row+0.5)/12*PI)*0.72))
		for i in range(48):
			var phase := fposmod(t * 0.19 + i * 0.618, 1.0)
			var p := area.position + Vector2(fposmod(i * 137.3, area.size.x), phase * area.size.y)
			var alpha := sin(phase * PI) * (0.18 + 0.11 * sin(t * 2.2 + i))
			var width := minf(area.size.x - (p.x-area.position.x), 9 + 6 * sin(t * 1.7 + i))
			ci.draw_line(p, p + Vector2(width, -2), Color(0.13,0.63,0.73,alpha), 1.5)
	# Reflexos do poste e do barco ondulam em bandas quebradas sobre o mar.
	for origin in [Vector2(388,946), Vector2(650,947), Vector2(998,947)]:
		for i in range(9):
			var p: Vector2 = origin + Vector2(sin(t*2.1+i*1.7)*7, i*7)
			var width := 5 + i * 1.5 + sin(t*3+i)*3
			ci.draw_line(p-Vector2(width,0),p+Vector2(width,0),Color(1,0.61,0.16,0.12+0.12*sin(t*2+i)),2)
	# Espuma nas estacas abaixo do cais e na margem direita; não cobre o barco.
	for x in [300,345,410,466,515,568,921,970,1030]:
		var p := Vector2(x, 906 + sin(t*1.8+x)*3)
		for j in range(2):
			var a := fposmod(t*0.32+j/2.0+x*0.003,1.0)
			ci.draw_arc(p+Vector2(0,a*15),10+a*15,0.45,2.6,10,Color(0.38,0.78,0.8,sin(a*PI)*0.12),1)
	for i in range(LAMPS.size()):
		var p: Vector2 = LAMPS[i]
		var glow := 0.7 + sin(t*3.2+i*2.1)*0.18 + sin(t*7.1+i)*0.08
		ci.draw_circle(p,2.2,Color(1,0.86,0.43,glow*0.65))   # filamento visível na pintura
		# 0.19: o brilho em volta usa a MESMA camada aditiva (LightLayer) das outras salas —
		# antes eram círculos comuns aqui, mais "achatados" que os lampiões do resto do jogo.
		lights.append({"p": to_world(p), "kind": "amber", "s": 0.55 * glow})
		lights.append({"p": to_world(p), "kind": "bulb"})
	for i in range(PUDDLES.size()):
		for j in range(8):
			var p: Vector2 = PUDDLES[i] + Vector2(sin(t*1.6+j+i)*4,j*5)
			var width := 2.0 + sin(j*2.4+i)*1.5
			ci.draw_line(p-Vector2(width,0),p+Vector2(width,0),Color(1,0.65,0.24,0.12+sin(t*2.3+j)*0.09),1.5)
	# Fumaça leve da chaminé do cargueiro: nascimento e dissipação graduais.
	for i in range(9):
		var phase := fposmod(t*0.13+i/9.0,1.0)
		var p := Vector2(108,175) + Vector2(phase*40+sin(t*0.7+i)*phase*8,-phase*137)
		var alpha := sin(phase*PI)*0.075
		ci.draw_circle(p,9+phase*16,Color(0.48,0.55,0.60,alpha))
		ci.draw_circle(p+Vector2(5,-4),7+phase*11,Color(0.60,0.65,0.69,alpha*0.6))
	ci.draw_set_transform(Vector2.ZERO)

func draw_rift(ci: CanvasItem, sim, lights: Array) -> void:
	if sim.mode != "run" or not sim.visited.has("entry"): return
	# tick_time começa em zero na expedição e é replicado nos snapshots coop.
	var t: float = sim.tick_time
	var opening := smoothstep(0.0, 1.6, t)
	if opening < 0.01: return
	var p: Vector2 = MAP.POINTS.spawn + Vector2(-65, -30)
	# 0.19: a fenda também sangra luz na camada aditiva (mesmo sistema dos postes/braseiros),
	# em vez de só os círculos de baixa opacidade desenhados no chão comum. "cyan"/"violet"
	# têm opacidade fixa em draw_lights(), então só entram quando a abertura já é visível.
	if opening > 0.1:
		lights.append({"p": p - Vector2(0, 62), "kind": "violet"})
		lights.append({"p": p - Vector2(0, 62), "kind": "cyan"})
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
