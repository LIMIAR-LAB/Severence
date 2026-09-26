extends RefCounted
# Cenário 0.12 das Docas (arte: assets/environment/docks12, recortada por tools/prepare_docks_v12.py).
# Desenha piso com variações, paredes de armazém, água/cais, props e a névoa das salas não descobertas.
# Tudo é desenhado no CanvasItem recebido (world_view), em coordenadas de mundo.

const DOCKS := preload("res://scripts/docks_map.gd")
const BASE := "res://assets/environment/docks12/"

const TILE_NAMES := ["planks_base", "planks_knot", "planks_nails", "planks_crack", "planks_light", "planks_wet", "planks_oil", "planks_hole",
	"granite_base", "granite_moss", "granite_cracked", "granite_puddle", "granite_yellow",
	"quay_edge_0", "quay_edge_1", "quay_edge_2", "quay_edge_3", "water_0", "water_1", "water_2", "water_3", "foam_0",
	"wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4",
	"brick_base", "brick_base2", "brick_damaged", "brick_hole", "brick_pipe", "brick_window",
	"wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4",
	"wall_corner_0", "wall_corner_1", "side_cap", "grate", "manhole", "symbol_0", "symbol_1", "symbol_2", "piling"]
const PROP_NAMES := ["crate", "crate_2", "crate_3", "crate_broken", "crate_net", "crate_barnacles", "barrel", "barrel_oil", "barrel_toxic",
	"barrel_explosive", "barrel_tipped", "sandbags", "sandbags_corner", "sandbags_damaged", "bollard", "bollard_rope", "rope",
	"fish_basket", "lobster_trap", "wheelbarrow", "anchor", "bench", "lamp_post", "ship_lantern", "wall_lamp", "brazier",
	"brazier_f1", "brazier_f2", "brazier_f3", "container", "container_open", "rowboat", "crane", "hook", "phone_booth", "poster",
	"radio", "jerrycans", "medkit", "iron_door", "tentacle_pool_1", "tentacle_pool_2", "ritual_circle", "tentacle_planks",
	"debris_crate", "debris_barrel", "debris_sandbags", "container_red", "container_olive", "container_open_red", "container_open_olive"]

# Escala de mundo de cada prop (1.0 = tamanho nativo da folha). Marty tem ~72 px.
const PROP_SCALE := {"crate": 0.8, "crate_2": 0.8, "crate_3": 0.8, "crate_broken": 0.8, "crate_net": 0.8, "crate_barnacles": 0.8,
	"barrel": 0.75, "barrel_oil": 0.75, "barrel_toxic": 0.75, "barrel_explosive": 0.75, "barrel_tipped": 0.75,
	"bollard": 0.6, "bollard_rope": 0.6, "fish_basket": 0.75, "lobster_trap": 0.8, "wheelbarrow": 0.8, "bench": 0.9,
	"brazier": 0.75, "container": 1.15, "container_open": 1.15, "container_red": 1.15, "container_olive": 1.15, "container_open_red": 1.15, "container_open_olive": 1.15, "crane": 1.3, "phone_booth": 0.95, "radio": 0.8,
	"jerrycans": 0.75, "medkit": 0.75, "rope": 0.8, "anchor": 0.9}
# Tipos antigos de obstáculo que passam a usar a arte nova.
const LEGACY := {"fishbox": "fish_basket", "container_blue": "container"}
const PLANK_VARIANTS := ["planks_knot", "planks_nails", "planks_crack", "planks_light", "planks_wet", "planks_oil", "planks_hole"]
const PLANK_WEIGHTS := [5, 6, 3, 2, 2, 2, 1]
const GRANITE_VARIANTS := ["granite_moss", "granite_cracked", "granite_puddle"]
const BRICK_POOL := ["brick_base", "brick_base", "brick_base2", "brick_base", "brick_base2", "brick_damaged", "brick_pipe", "brick_hole"]
const WALL_H := 51 + 107 + 58          # topo + tijolos + base da fachada
const SIDE_W := 30
const VOID := Color("06080d")

var tiles := {}
var props := {}
var fx := {}
var reveal_at := {}     # id da sala -> tick_time em que apareceu
var lights: Array = []  # poças de luz do quadro atual (desenhadas no LightLayer, modo aditivo)

func _init() -> void:
	for n in TILE_NAMES: tiles[n] = load(BASE + "tiles/" + n + ".png")
	for n in PROP_NAMES: props[n] = load(BASE + "props/" + n + ".png")
	for n in ["light_amber", "light_green", "soft_circle"]: fx[n] = load(BASE + "fx/" + n + ".png")

static func hash01(ix: int, iy: int, salt: int = 0) -> float:
	var n: int = (ix * 73856093) ^ (iy * 19349663) ^ (salt * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0

func has_prop(kind: String) -> bool:
	return props.has(LEGACY.get(kind, kind))

# ------------------------------------------------------------------ descoberta (névoa)
func discovered_rooms(sim) -> Array:
	var out: Array = []
	for room in sim.rooms:
		if not room.has("id"): out.append(room); continue          # arena de teste: sempre visível
		if room.kind == "secret" and not sim.secret_open: continue
		if sim.mode != "run" or sim.visited.has(room.id):
			out.append(room)
			if not reveal_at.has(room.id): reveal_at[room.id] = sim.tick_time
	return out

func visible_floors(sim, rooms: Array) -> Array:
	# Pisos cuja área toca uma sala descoberta (corredores e alas aparecem junto com a sala).
	var out: Array = []
	for f in sim.floors:
		var seen := false
		for room in rooms:
			if f.grow(6).intersects(room.r): seen = true; break
		for a in sim.actors:
			if a.active and f.has_point(a.p): seen = true
		if seen: out.append(f)
	return out

static func inside(rects: Array, p: Vector2, margin: float = 0.0) -> bool:
	for r in rects:
		if r.grow(margin).has_point(p): return true
	return false

func draw_reveal(ci: CanvasItem, sim, rooms: Array) -> void:
	# A sala recém-descoberta "acende" em 0,5s.
	for room in rooms:
		if not room.has("id"): continue
		var age: float = sim.tick_time - reveal_at.get(room.id, -9.0)
		if age < 0.5: ci.draw_rect(room.r.grow(40), Color(VOID, 1.0 - age / 0.5))

# ------------------------------------------------------------------ piso
func style_of(room: Dictionary) -> Dictionary:
	return DOCKS.ROOM_STYLE.get(room.get("id", ""), {})

func pick_plank(ix: int, iy: int) -> String:
	if hash01(ix, iy, 1) < 0.8: return "planks_base"
	var roll := hash01(ix, iy, 2) * 21.0
	for i in PLANK_VARIANTS.size():
		roll -= PLANK_WEIGHTS[i]
		if roll <= 0: return PLANK_VARIANTS[i]
	return "planks_base"

func pick_granite(ix: int, iy: int) -> String:
	if hash01(ix, iy, 3) < 0.8: return "granite_base"
	var r := hash01(ix, iy, 4)
	return "granite_moss" if r < 0.5 else ("granite_cracked" if r < 0.96 else "granite_puddle")

func tile_area(ci: CanvasItem, rect: Rect2, view: Rect2, kind: String, origin: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE, yellow_row: int = -99) -> void:
	var area := rect.intersection(view)
	if area.size.x <= 0 or area.size.y <= 0: return
	var planks := kind == "planks"
	var base: Texture2D = tiles.planks_base if planks else tiles.granite_base
	var tw: float = base.get_width(); var th: float = base.get_height()
	var iy0 := int(floorf((area.position.y - origin.y) / th))
	var iy1 := int(floorf((area.end.y - origin.y - 0.01) / th))
	for iy in range(iy0, iy1 + 1):
		var off: float = origin.x + (tw * 0.5 if planks and iy % 2 != 0 else 0.0)   # tábuas desencontradas
		var ix0 := int(floorf((area.position.x - off) / tw))
		var ix1 := int(floorf((area.end.x - off - 0.01) / tw))
		for ix in range(ix0, ix1 + 1):
			var cell := Rect2(off + ix * tw, origin.y + iy * th, tw, th)
			var clip := cell.intersection(rect)
			if clip.size.x <= 0 or clip.size.y <= 0: continue
			var name: String
			if planks: name = pick_plank(ix, iy)
			elif iy == yellow_row: name = "granite_yellow"
			else: name = pick_granite(ix, iy)
			ci.draw_texture_rect_region(tiles[name], clip, Rect2(clip.position - cell.position, clip.size), tint)

func floor_kind(sim, rect: Rect2) -> String:
	for room in sim.rooms:
		if room.r.encloses(rect) or room.r.has_point(rect.get_center()): return room.get("floor", "stone")
	return "planks"   # corredores: passarelas de madeira

func draw_floors(ci: CanvasItem, sim, floors: Array, rooms: Array, view: Rect2) -> void:
	for rect in floors:
		if not rect.intersects(view): continue
		var kind := floor_kind(sim, rect)
		var tint := Color(1.0, 0.93, 0.86) if kind == "cobble" else Color.WHITE
		tile_area(ci, rect, view, "planks" if kind == "planks" else "granite", Vector2.ZERO, tint)
	for room in rooms:
		var band: float = style_of(room).get("quay_band", 0.0)
		if band <= 0: continue
		var r: Rect2 = room.r
		var quay := Rect2(r.position.x, r.end.y - band, r.size.x, band)
		var th: float = tiles.granite_base.get_height()
		var rows := int(ceilf(band / th))
		tile_area(ci, quay, view, "granite", Vector2(r.position.x, r.end.y - rows * th), Color.WHITE, rows - 1)
		ci.draw_rect(Rect2(quay.position.x, quay.position.y - 3, quay.size.x, 6), Color("2a1b12"))
		ci.draw_rect(Rect2(quay.position.x, quay.position.y + 3, quay.size.x, 2), Color(0, 0, 0, 0.35))

# ------------------------------------------------------------------ água
func draw_water(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	var zones: Array = []
	for z in DOCKS.WATER:
		for room in rooms:
			if room.get("id", "") == z.room: zones.append(z.r)
	for zone in zones: water_rect(ci, sim, zone, view)

func draw_gap(ci: CanvasItem, sim, gap: Rect2) -> void:
	water_rect(ci, sim, gap, gap)
	ci.draw_rect(Rect2(gap.position.x, gap.position.y, gap.size.x, 10), Color(0, 0, 0, 0.45))

func water_rect(ci: CanvasItem, sim, zone: Rect2, view: Rect2) -> void:
	var t: float = sim.tick_time
	var tex: Texture2D = tiles.water_0
	var tw: float = tex.get_width(); var th: float = tex.get_height()
	if true:
		var area: Rect2 = zone.intersection(view)
		if area.size.x <= 0 or area.size.y <= 0: return
		ci.draw_rect(area, Color("0a1a33"))
		var drift := Vector2(fposmod(t * 9.0, tw), sin(t * 0.8) * 3.0)
		for y in range(int(floorf((area.position.y) / th) * th) - int(th), int(area.end.y) + 1, int(th)):
			for x in range(int(floorf((area.position.x) / tw) * tw) - int(tw), int(area.end.x) + 1, int(tw)):
				var cell := Rect2(Vector2(x, y) + drift, Vector2(tw, th))
				var clip := cell.intersection(zone)
				if clip.size.x <= 0 or clip.size.y <= 0: continue
				ci.draw_texture_rect_region(tex, clip, Rect2(clip.position - cell.position, clip.size), Color(0.9, 0.95, 1.0))
		# brilhos na água
		for gy in range(int(area.position.y / 90), int(area.end.y / 90) + 1):
			for gx in range(int(area.position.x / 90) - 1, int(area.end.x / 90) + 1):
				var p := Vector2(gx * 90 + hash01(gx, gy, 7) * 80, gy * 90 + hash01(gx, gy, 9) * 80)
				if not area.has_point(p): continue
				var k := 0.5 + 0.5 * sin(t * 2.3 + gx * 1.7 + gy)
				ci.draw_rect(Rect2(p + Vector2(sin(t + gx) * 4, 0), Vector2(6, 2)), Color(0.75, 0.88, 1.0, 0.4 * k))

# ------------------------------------------------------------------ paredes
static func floor_has(floors: Array, p: Vector2) -> bool:
	for f in floors:
		if f.has_point(p): return true
	return false

func wall_runs(floors: Array, a: Vector2, b: Vector2, outward: Vector2) -> Array:
	# Trechos da borda a→b cujo lado de fora NÃO é piso (ali entra parede). Aberturas = corredores.
	var runs: Array = []
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 1.0)
	var start := -1.0
	var t := 0.0
	while t <= length:
		var open := floor_has(floors, a + dir * minf(t + 4.0, length - 1.0) + outward * 4.0)
		if not open and start < 0: start = t
		if open and start >= 0: runs.append(Vector2(start, t)); start = -1.0
		t += 8.0
	if start >= 0: runs.append(Vector2(start, length))
	return runs

func strip(ci: CanvasItem, names: Array, x0: float, x1: float, y: float, h: float, salt: int, tint: Color = Color.WHITE) -> Array:
	# Faixa horizontal com tiles de larguras diferentes; devolve [x, nome] de cada tile (para luzes).
	var placed: Array = []
	var x := x0
	var i := int(x0 / 50.0)
	while x < x1 - 0.5:
		var name: String = names[int(hash01(i, salt, 5) * names.size()) % names.size()]
		var tex: Texture2D = tiles[name]
		var w := minf(tex.get_width(), x1 - x)
		ci.draw_texture_rect_region(tex, Rect2(x, y, w, h), Rect2(0, 0, w, minf(h, tex.get_height())), tint)
		placed.append([x + w * 0.5, name])
		x += w; i += 1
	return placed

func draw_walls(ci: CanvasItem, sim, floors: Array, rooms: Array, view: Rect2) -> void:
	var all_floors: Array = sim.floors
	for rect in floors:
		if not rect.grow(WALL_H + 60).intersects(view): continue
		var style: Dictionary = {}
		for room in rooms:
			if room.r == rect: style = style_of(room)
		var tl: Vector2 = rect.position; var br: Vector2 = rect.end
		# sombra de contato por dentro das paredes
		ci.draw_rect(Rect2(tl.x, tl.y, rect.size.x, 18), Color(0, 0, 0, 0.28))
		ci.draw_rect(Rect2(tl.x, tl.y + 18, rect.size.x, 10), Color(0, 0, 0, 0.12))
		# topo: fachada de armazém
		if style.get("top", "facade") == "facade":
			for run in wall_runs(all_floors, tl, Vector2(br.x, tl.y), Vector2.UP):
				var x0: float = tl.x + run.x; var x1: float = tl.x + run.y
				var y_base := tl.y - 58.0; var y_brick := y_base - 107.0; var y_cap := y_brick - 51.0
				strip(ci, ["wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4"], x0, x1, y_cap, 51, int(tl.y))
				var bricks := strip(ci, BRICK_POOL + ["brick_window"], x0, x1, y_brick, 107, int(tl.y) + 1, Color(0.92, 0.9, 0.9))
				strip(ci, ["wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4"], x0, x1, y_base, 58, int(tl.y) + 2)
				for b in bricks:
					if b[1] == "brick_window": lights.append({"p": Vector2(b[0], y_brick + 60), "kind": "window"})
				ci.draw_rect(Rect2(x0, tl.y - 4, x1 - x0, 4), Color(0, 0, 0, 0.45))
				# pilares emolduram as aberturas (portas de corredor)
				for end in [x0, x1]:
					if end > tl.x + 2 and end < br.x - 2:
						var pil: Texture2D = tiles.wall_corner_0
						ci.draw_texture(pil, Vector2(end - pil.get_width() * 0.5, tl.y - pil.get_height()))
		# base: muro baixo visto por fora, ou beira do cais
		var bottom: String = style.get("bottom", "wall")
		if bottom == "quay":
			var x := tl.x; var i := 0
			while x < br.x:
				var tex: Texture2D = tiles["quay_edge_%d" % (i % 4)]
				var w := minf(tex.get_width(), br.x - x)
				ci.draw_texture_rect_region(tex, Rect2(x, br.y - 8, w, tex.get_height()), Rect2(0, 0, w, tex.get_height()))
				x += w; i += 1
		elif bottom == "wall":
			for run in wall_runs(all_floors, Vector2(tl.x, br.y), br, Vector2.DOWN):
				var x0: float = tl.x + run.x; var x1: float = tl.x + run.y
				strip(ci, ["wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4"], x0, x1, br.y, 51, int(br.y), Color(0.85, 0.85, 0.9))
				strip(ci, ["wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4"], x0, x1, br.y + 51, 58, int(br.y) + 3, Color(0.7, 0.7, 0.78))
		# laterais: topo da parede visto de cima
		for side in [-1, 1]:
			var key := "left" if side < 0 else "right"
			var x: float = tl.x if side < 0 else br.x
			if style.get(key, "wall") == "pier":
				draw_pier_edge(ci, sim, rect, side)
				continue
			for run in wall_runs(all_floors, Vector2(x, tl.y), Vector2(x, br.y), Vector2(side, 0)):
				var y0: float = tl.y + run.x; var y1: float = tl.y + run.y
				if run.x <= 0.5 and style.get("top", "facade") == "facade": y0 -= WALL_H
				if run.y >= rect.size.y - 0.5 and bottom == "wall": y1 += 51
				var sx: float = x - SIDE_W if side < 0 else x
				var tex: Texture2D = tiles.side_cap
				var y := y0
				while y < y1:
					var h := minf(tex.get_height(), y1 - y)
					ci.draw_texture_rect_region(tex, Rect2(sx, y, SIDE_W, h), Rect2(0, 0, SIDE_W, h), Color(0.9, 0.9, 0.95))
					y += h
				ci.draw_rect(Rect2(sx + (SIDE_W - 3 if side < 0 else 0), y0, 3, y1 - y0), Color(0, 0, 0, 0.5))
				ci.draw_rect(Rect2(x + (0 if side < 0 else -14), y0 + WALL_H * (1 if run.x <= 0.5 else 0), 14, maxf(0, y1 - y0 - WALL_H)), Color(0, 0, 0, 0.18))

func draw_pier_edge(ci: CanvasItem, sim, rect: Rect2, side: int) -> void:
	var x: float = rect.position.x if side < 0 else rect.end.x
	ci.draw_rect(Rect2(x - (10 if side < 0 else 0), rect.position.y, 10, rect.size.y), Color("3b2415"))
	ci.draw_rect(Rect2(x - (10 if side < 0 else 0), rect.position.y, 3, rect.size.y), Color("7a5232"))
	var pil: Texture2D = tiles.piling
	var y := rect.position.y + 40.0
	while y < rect.end.y - 20:
		var bob := sin(sim.tick_time * 1.4 + y) * 1.5
		ci.draw_texture(pil, Vector2(x - pil.get_width() * 0.5 - 18 * side, y - 40 + bob))
		# espuma ao redor da estaca
		ci.draw_arc(Vector2(x - 18 * side, y + 66), 12 + sin(sim.tick_time * 2 + y) * 2, PI * 0.1, PI * 0.9, 8, Color(0.8, 0.9, 1, 0.5), 2)
		y += 118.0

# ------------------------------------------------------------------ props
func prop_size(kind: String) -> Vector2:
	var k: String = LEGACY.get(kind, kind)
	return props[k].get_size() * float(PROP_SCALE.get(k, 1.0))

func draw_prop(ci: CanvasItem, kind: String, foot: Vector2, t: float = 0.0, tint: Color = Color.WHITE) -> void:
	var k: String = LEGACY.get(kind, kind)
	if k == "brazier": k = ["brazier_f1", "brazier_f2", "brazier_f3"][int(t * 8.0) % 3]
	var tex: Texture2D = props[k]
	var size := tex.get_size() * float(PROP_SCALE.get(kind, PROP_SCALE.get(k, 1.0)))
	ci.draw_texture_rect(tex, Rect2(foot - Vector2(size.x * 0.5, size.y), size), false, tint)

func draw_obstacle(ci: CanvasItem, box: Rect2, kind: String, t: float) -> void:
	var size := prop_size("crate" if kind == "crate_row" else kind)
	var foot := Vector2(box.get_center().x, box.end.y + 4)
	ci.draw_set_transform(foot + Vector2(0, -2), 0, Vector2(1, 0.32))
	ci.draw_circle(Vector2.ZERO, maxf(box.size.x, size.x * 0.8) * 0.55, Color(0, 0, 0, 0.32)); ci.draw_set_transform(Vector2.ZERO)
	if kind == "crate_row":
		var x := box.position.x
		while x < box.end.x - 4:
			draw_prop(ci, "crate", Vector2(x + 30, box.end.y + 4), t); x += 60
		return
	if kind.begins_with("container") and box.size.x > 180:
		var s: float = (box.size.x * 0.5 + 8) / props.container.get_width()
		for k in [-1, 1]:
			var tex: Texture2D = props[LEGACY.get(kind, kind)]
			var sz := tex.get_size() * s
			var f := foot + Vector2(k * box.size.x * 0.25, -4 if k < 0 else 4)
			ci.draw_texture_rect(tex, Rect2(f - Vector2(sz.x * 0.5, sz.y), sz), false)
		return
	draw_prop(ci, kind, foot, t)
	match kind:
		"lamp_post": lights.append({"p": foot + Vector2(0, -6), "kind": "amber", "s": 1.2}); lights.append({"p": foot - Vector2(0, size.y - 22), "kind": "bulb"})
		"brazier": lights.append({"p": foot - Vector2(0, 40), "kind": "fire"})

# Decoração: plana (chão), na parede (fachada) ou em pé (ordenada por Y junto com as entidades).
const FLAT_DECOR := ["grate", "manhole", "symbol_0", "symbol_1", "symbol_2", "tentacle_pool", "ritual_circle", "tentacle_planks", "rails_diag", "rails", "rowboat", "debris_crate", "debris_barrel", "debris_sandbags", "rope", "anchor"]
const WALL_DECOR := ["poster", "iron_door", "wall_lamp", "phone_booth_wall"]

func is_flat(kind: String) -> bool: return kind in FLAT_DECOR or kind in WALL_DECOR
func handles(kind: String) -> bool: return is_flat(kind) or props.has(kind)

func draw_decor(ci: CanvasItem, d: Dictionary, t: float) -> void:
	var p: Vector2 = d.p
	match d.kind:
		"grate", "manhole":
			ci.draw_texture_rect(tiles[d.kind], Rect2(p - Vector2(28, 28), Vector2(56, 56)), false, Color(0.9, 0.9, 0.95, 0.95))
		"symbol_0", "symbol_1", "symbol_2":
			var tex: Texture2D = tiles[d.kind]
			var k := 0.55 + 0.25 * sin(t * 2.0 + p.x)
			ci.draw_set_transform(p, 0, Vector2(1.0, 0.62))
			ci.draw_texture(tex, -tex.get_size() * 0.5, Color(0.7, 1, 0.75, k))
			ci.draw_set_transform(Vector2.ZERO)
			lights.append({"p": p, "kind": "green", "s": 0.8})
		"tentacle_pool":
			# Perigo: com alguém perto, os tentáculos se erguem e o chão pulsa em vermelho.
			var alert: bool = d.get("alert", false)
			if alert:
				var k := 0.5 + 0.5 * sin(t * 10)
				ci.draw_set_transform(p + Vector2(0, -8), 0, Vector2(1, 0.62))
				ci.draw_circle(Vector2.ZERO, 70, Color(0.8, 0.05, 0.2, 0.18 + 0.12 * k))
				ci.draw_arc(Vector2.ZERO, 66 + 4 * k, 0, TAU, 40, Color(1, 0.2, 0.35, 0.7), 3)
				ci.draw_set_transform(Vector2.ZERO)
				lights.append({"p": p, "kind": "danger"})
			var name := "tentacle_pool_2" if alert or int(t * 1.6) % 2 == 1 else "tentacle_pool_1"
			var tex: Texture2D = props[name]
			var sway := Vector2(sin(t * 6) * 3, 0) if alert else Vector2.ZERO
			ci.draw_texture(tex, p - Vector2(tex.get_width() * 0.5, tex.get_height() * 0.6) + sway)
		"rowboat":
			var tex: Texture2D = props.rowboat
			ci.draw_set_transform(p + Vector2(0, sin(t * 1.3) * 3), sin(t * 0.9) * 0.03)
			ci.draw_texture(tex, -tex.get_size() * 0.5)
			ci.draw_set_transform(Vector2.ZERO)
		"rails_diag": draw_rails(ci, p, d.get("to", p + Vector2(600, 200)))
		"rails": draw_rails(ci, p - Vector2(260, 0), p + Vector2(260, 0))
		"poster", "iron_door", "wall_lamp":
			var tex: Texture2D = props[d.kind]
			var s := 0.75 if d.kind == "poster" else (0.95 if d.kind == "iron_door" else 0.9)
			var size := tex.get_size() * s
			ci.draw_texture_rect(tex, Rect2(p - Vector2(size.x * 0.5, size.y), size), false)
			if d.kind == "wall_lamp": lights.append({"p": p + Vector2(8, 40), "kind": "amber", "s": 0.8}); lights.append({"p": p - Vector2(-12, 22), "kind": "bulb"})
		_:
			if props.has(d.kind): draw_prop(ci, d.kind, p, t)

func draw_rails(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	var dir := (b - a).normalized(); var n := Vector2(-dir.y, dir.x)
	var length := a.distance_to(b)
	var d := 0.0
	while d < length:   # dormentes
		var c := a + dir * d
		ci.draw_colored_polygon(PackedVector2Array([c + n * 22 - dir * 5, c + n * 22 + dir * 5, c - n * 22 + dir * 5, c - n * 22 - dir * 5]), Color("4a3322"))
		ci.draw_line(c + n * 22 - dir * 5, c - n * 22 - dir * 5, Color("6b4a30"), 1)
		d += 24.0
	for off in [-13.0, 13.0]:
		ci.draw_line(a + n * off + Vector2(0, 2), b + n * off + Vector2(0, 2), Color(0, 0, 0, 0.45), 4)
		ci.draw_line(a + n * off, b + n * off, Color("6e7382"), 4)
		ci.draw_line(a + n * off - Vector2(0, 1), b + n * off - Vector2(0, 1), Color("b9bfcc"), 1)

# ------------------------------------------------------------------ luz (LightLayer, modo aditivo)
func draw_lights(ci: CanvasItem, t: float) -> void:
	for l in lights:
		var p: Vector2 = l.p
		match l.kind:
			"amber":
				var s: float = l.get("s", 1.0) * (1.0 + 0.03 * sin(t * 7 + p.x))
				var tex: Texture2D = fx.light_amber
				ci.draw_texture_rect(tex, Rect2(p - tex.get_size() * s * 0.5, tex.get_size() * s), false, Color(1, 1, 1, 0.55))
			"bulb":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(34, 34), Vector2(68, 68)), false, Color(1.0, 0.7, 0.35, 0.8))
			"bulb_red":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(40, 40), Vector2(80, 80)), false, Color(1.0, 0.15, 0.1, 0.5 + 0.4 * sin(t * 12)))
			"window":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(45, 50), Vector2(90, 100)), false, Color(1.0, 0.6, 0.25, 0.35))
			"fire":
				var k := 0.8 + 0.2 * sin(t * 13 + p.x)
				ci.draw_texture_rect(fx.light_amber, Rect2(p - Vector2(110, 70) * k, Vector2(220, 140) * k), false, Color(1, 0.8, 0.6, 0.7))
			"green":
				var s: float = l.get("s", 1.0)
				ci.draw_texture_rect(fx.light_green, Rect2(p - Vector2(80, 60) * s, Vector2(160, 120) * s), false, Color(1, 1, 1, 0.35 + 0.15 * sin(t * 2 + p.x)))
			"danger":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(110, 70), Vector2(220, 140)), false, Color(1.0, 0.15, 0.3, 0.35 + 0.15 * sin(t * 10)))
			"gate_open":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(130, 110), Vector2(260, 220)), false, Color(1.0, 0.78, 0.3, 0.55))
			"gate_locked":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(110, 90), Vector2(220, 180)), false, Color(1.0, 0.12, 0.1, 0.4 + 0.15 * sin(t * 6)))
			"blast":
				var r: float = l.get("r", 200.0)
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(r, r * 0.7), Vector2(r * 2, r * 1.4)), false, Color(1.0, 0.55, 0.2, 0.45))
			"cyan":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(120, 120), Vector2(240, 240)), false, Color(0.4, 0.9, 1.0, 0.35))

# ------------------------------------------------------------------ portões (0.12)
# Portões grandes nas pontas dos corredores: torres de tijolo, luzes, seta dourada no chão quando abertos,
# grade de ferro descida e luzes vermelhas quando a sala está trancada.
func draw_gate(ci: CanvasItem, d: Dictionary, locked: bool, t: float, room_rect: Rect2) -> void:
	var r: Rect2 = d.r
	var horizontal: bool = d.side == "top" or d.side == "bottom"   # a abertura corre no eixo x
	var tower: Texture2D = tiles.wall_corner_0
	var ends: Array = [Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)] if horizontal else [Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y)]
	var gold := Color(1.0, 0.8, 0.35)
	var red := Color(1.0, 0.25, 0.2)
	# seta no chão apontando para fora da sala (só com o portão aberto)
	if not locked:
		var out := {"top": Vector2.UP, "bottom": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}[d.side] as Vector2
		var c: Vector2 = r.get_center() - out * 70
		for k in range(3):
			var ph := fposmod(t * 1.6 - k * 0.33, 1.0)
			var q: Vector2 = c + out * (k * 34 + ph * 10)
			var n := out.orthogonal()
			var a := Color(gold, 0.25 + 0.55 * (1.0 - ph))
			ci.draw_polyline(PackedVector2Array([q - out * 12 + n * 22, q + out * 10, q - out * 12 - n * 22]), a, 7)
		lights.append({"p": r.get_center(), "kind": "gate_open"})
	else:
		lights.append({"p": r.get_center(), "kind": "gate_locked"})
	# grade de ferro (portcullis)
	if locked:
		if horizontal:
			var y1: float = r.end.y if d.side == "top" else r.position.y + 6
			var h := 118.0
			ci.draw_rect(Rect2(r.position.x, y1 - h, r.size.x, h), Color(0.05, 0.03, 0.04, 0.55))
			var x := r.position.x + 8
			while x < r.end.x - 4:
				ci.draw_rect(Rect2(x, y1 - h, 7, h), Color("2a2d36")); ci.draw_rect(Rect2(x + 1, y1 - h, 2, h), Color("6b7080"))
				ci.draw_rect(Rect2(x - 1, y1 - 8, 9, 10), Color("1b1c22"))   # pontas
				x += 22
			for yy in [y1 - h + 18, y1 - h * 0.5]:
				ci.draw_rect(Rect2(r.position.x, yy, r.size.x, 8), Color("33363f")); ci.draw_rect(Rect2(r.position.x, yy, r.size.x, 2), Color("7d8290"))
		else:
			# abertura lateral vista de cima: grade em pé ao longo do eixo y
			var x0: float = r.get_center().x - 4
			var y := r.position.y
			while y < r.end.y:
				ci.draw_rect(Rect2(x0 - 3, y - 96, 8, 100), Color("2a2d36")); ci.draw_rect(Rect2(x0 - 2, y - 96, 2, 100), Color("6b7080"))
				y += 20
			for off in [96.0, 50.0]:
				ci.draw_rect(Rect2(x0 - 6, r.position.y - off, 14, r.size.y), Color(0.2, 0.21, 0.25, 0.9))
			ci.draw_rect(Rect2(x0 - 16, r.position.y, 32, r.size.y), Color(0.9, 0.1, 0.1, 0.12 + 0.08 * sin(t * 6)))
	# torres (sempre) com lanterna: âmbar = aberto, vermelha piscando = trancado
	for e in ends:
		var s := 0.82
		var sz := tower.get_size() * s
		var foot: Vector2 = e + (Vector2(0, 8) if horizontal else Vector2(0, 14))
		ci.draw_texture_rect(tower, Rect2(foot - Vector2(sz.x * 0.5, sz.y), sz), false, Color(1, 0.95, 0.9))
		var lamp: Vector2 = foot - Vector2(0, sz.y + 6)
		var on := locked and int(t * 4) % 2 == 0
		ci.draw_circle(lamp, 9, Color("1b1c22")); ci.draw_circle(lamp, 6, (red if on else Color(0.45, 0.1, 0.1)) if locked else gold)
		lights.append({"p": lamp, "kind": "bulb_red" if locked else "bulb"})
