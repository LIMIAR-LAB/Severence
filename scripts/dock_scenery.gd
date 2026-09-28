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
	"wall_corner_0", "wall_corner_1", "side_cap", "grate", "manhole", "symbol_0", "symbol_1", "symbol_2", "piling",
	"wall_crack_a", "wall_crack_b", "wall_crack_c", "wall_crack_a_open", "wall_crack_b_open", "wall_crack_c_open"]   # 0.16: tools/prepare_cracked_walls.py
const PROP_NAMES := ["crate", "crate_2", "crate_3", "crate_broken", "crate_net", "crate_barnacles", "barrel", "barrel_oil", "barrel_toxic",
	"barrel_explosive", "barrel_tipped", "sandbags", "sandbags_corner", "sandbags_damaged", "bollard", "bollard_rope", "rope",
	"fish_basket", "lobster_trap", "wheelbarrow", "anchor", "bench", "lamp_post", "ship_lantern", "wall_lamp", "brazier",
	"brazier_f1", "brazier_f2", "brazier_f3", "container", "container_open", "rowboat", "crane", "hook", "phone_booth", "poster",
	"radio", "jerrycans", "medkit", "iron_door", "tentacle_pool_1", "tentacle_pool_2", "ritual_circle", "tentacle_planks",
	"debris_crate", "debris_barrel", "debris_sandbags", "container_red", "container_olive", "container_open_red", "container_open_olive",
	"tentacle_gate_active", "tentacle_gate_sealed", "npc_fisherman"]   # 0.16: tools/prepare_tentacle_gate.py • 0.17: NPC da sala de história
# 0.16: microbiomas — props e pisos por sala (tools/prepare_workshop.py, prepare_market.py, prepare_chapel.py)
# 0.17: +depot, lighthouse, drydock, cellar, boss (tools/make_scenery_017.py)
const SET_PROPS := {
	"workshop": ["workshop_bench", "workshop_tool_rack", "workshop_hoist", "workshop_oil_puddle", "workshop_welder", "workshop_parts"],
	"market": ["market_stall", "market_net", "market_baskets", "market_ice_barrel", "market_rowboat", "market_lanterns"],
	"chapel": ["chapel_stained_glass", "chapel_candles", "chapel_banner", "chapel_offering_bowl"],
	"depot": ["depot_shells", "depot_sign"],
	"drydock": ["dock_scaffold", "dock_chain"],
	"cellar": ["cellar_float"],
	"boss": ["boss_skull_pile"],
	"lighthouse": ["light_gear"]}
# piso de cada conjunto: [nome, peso] (64x64, 1 px da arte = 1 px de mundo)
const FLOOR_SETS := {
	"workshop": [["workshop_floor_riveted", 14], ["workshop_floor_worn", 5], ["workshop_floor_oil", 2], ["workshop_floor_grate", 1]],
	"market": [["market_floor_scales", 6], ["market_floor_puddle", 2], ["market_floor_seaweed", 2]],
	"chapel": [["chapel_floor_eye", 1], ["chapel_floor_spiral", 1]],
	"depot": [["depot_floor_a", 12], ["depot_floor_b", 5], ["depot_floor_oil", 2], ["depot_floor_stripe", 1]],
	"lighthouse": [["light_floor_a", 10], ["light_floor_rail", 2], ["light_floor_gear", 1]],
	"drydock": [["dock_floor_steel", 8], ["dock_floor_rust", 4], ["dock_floor_rib", 1]],
	"cellar": [["cellar_floor_wet", 10], ["cellar_floor_moss", 4], ["cellar_floor_broken", 1]],
	"boss": [["boss_floor_stone", 10], ["boss_floor_glyph", 2], ["boss_floor_crack", 2]]}
# 0.17: peles de fachada por ambiente (tools/make_scenery_017.py → docks12/walls/<set>/)
const WALL_SETS := ["cult", "abyssal", "rail"]
const WALL_TILE_NAMES := ["wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4",
	"brick_base", "brick_base2", "brick_damaged", "brick_hole", "brick_pipe", "brick_window",
	"wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4",
	"wall_corner_0", "wall_corner_1", "side_cap"]
# 0.17: decals planos de chão (alpha) — sujeira estilo Gungeon, espalhada por seed
const DECAL_NAMES := ["stain_oil", "stain_water", "crack_a", "crack_b", "scorch", "algae", "fishbones", "glyph_chalk", "planks_loose", "rust_stain"]
const DECAL_POOL := {
	"planks": ["planks_loose", "stain_water", "crack_a", "fishbones", "algae", "planks_loose"],
	"stone": ["crack_a", "crack_b", "stain_oil", "scorch", "rust_stain", "algae", "crack_a"],
	"cobble": ["crack_a", "stain_water", "algae", "rust_stain", "crack_b"]}
const DECAL_POOL_SET := {   # reforços por microbioma (somam no pool do piso)
	"depot": ["stain_oil", "rust_stain", "scorch"], "cellar": ["stain_water", "algae", "algae", "fishbones"],
	"boss": ["glyph_chalk", "scorch", "crack_b"], "chapel": ["glyph_chalk", "stain_water"],
	"lighthouse": ["rust_stain", "stain_oil"], "drydock": ["rust_stain", "stain_water", "algae"]}
# tinte ambiente por pele de parede / tipo de sala (bem sutil, por cima do piso)
const AMBIENT := {"cult": Color(0.55, 0.3, 0.8, 0.07), "abyssal": Color(0.2, 0.5, 0.65, 0.09), "rail": Color(0.75, 0.72, 0.6, 0.05)}

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
var decals := {}
var wall_tiles := {}   # "set/nome" -> textura (0.17)
var reveal_at := {}     # id da sala -> tick_time em que apareceu
var lights: Array = []  # poças de luz do quadro atual (desenhadas no LightLayer, modo aditivo)

func _init() -> void:
	for n in TILE_NAMES: tiles[n] = load(BASE + "tiles/" + n + ".png")
	for n in PROP_NAMES: props[n] = load(BASE + "props/" + n + ".png")
	for set_name in SET_PROPS:
		for n in SET_PROPS[set_name]: props[n] = load(BASE + set_name + "/" + n + ".png")
	for set_name in FLOOR_SETS:
		for e in FLOOR_SETS[set_name]: tiles[e[0]] = load(BASE + set_name + "/" + e[0] + ".png")
	for n in ["light_amber", "light_green", "soft_circle"]: fx[n] = load(BASE + "fx/" + n + ".png")
	for n in DECAL_NAMES: decals[n] = load(BASE + "decals/" + n + ".png")
	for s in WALL_SETS:
		for n in WALL_TILE_NAMES: wall_tiles[s + "/" + n] = load(BASE + "walls/" + s + "/" + n + ".png")

static func hash01(ix: int, iy: int, salt: int = 0) -> float:
	var n: int = (ix * 73856093) ^ (iy * 19349663) ^ (salt * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0

func has_prop(kind: String) -> bool:
	return kind in ["maze_wall", "wall_block"] or props.has(LEGACY.get(kind, kind))

# ------------------------------------------------------------------ descoberta (névoa)
func discovered_rooms(sim) -> Array:
	var out: Array = []
	for room in sim.rooms:
		if not room.has("id"): out.append(room); continue          # arena de teste: sempre visível
		if room.kind == "secret" and not sim.secret_open: continue
		if sim.mode != "run" or sim.visited.has(room.id):
			out.append(room)
			# 0.15: tick_time recomeça em cada expedição; um registro antigo (de uma run anterior)
			# ficava "no futuro" e a sala permanecia apagada até o relógio alcançá-lo.
			if not reveal_at.has(room.id) or float(reveal_at[room.id]) > sim.tick_time: reveal_at[room.id] = sim.tick_time
	# esquece salas que não estão mais descobertas (nova expedição, volta ao refúgio)
	var ids := out.map(func(r): return r.get("id", ""))
	for id in reveal_at.keys():
		if not ids.has(id): reveal_at.erase(id)
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
		var age: float = sim.tick_time - float(reveal_at.get(room.id, -9.0))
		if age >= 0.0 and age < 0.5:
			for rr in [room.r] + room.get("extra", []):
				ci.draw_rect(rr.grow(40), Color(VOID, 1.0 - age / 0.5))

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
	return "granite_moss" if r < 0.5 else "granite_cracked"   # 0.15: sem a poça quadrada (destoava)

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

func style_of_rect(sim, rect: Rect2) -> Dictionary:
	for room in sim.rooms:
		if room.r == rect: return style_of(room)
		for ex in room.get("extra", []):
			if ex == rect: return style_of(room)
	return {}

# 0.16: piso de um microbioma — azulejos 64x64 sorteados pelos pesos de FLOOR_SETS (fixo por célula).
func set_area(ci: CanvasItem, rect: Rect2, view: Rect2, set_name: String) -> void:
	var area := rect.intersection(view)
	if area.size.x <= 0 or area.size.y <= 0: return
	var entries: Array = FLOOR_SETS[set_name]
	var total := 0.0
	for e in entries: total += float(e[1])
	for iy in range(int(floorf((area.position.y - rect.position.y) / 64.0)), int(floorf((area.end.y - rect.position.y - 0.01) / 64.0)) + 1):
		for ix in range(int(floorf((area.position.x - rect.position.x) / 64.0)), int(floorf((area.end.x - rect.position.x - 0.01) / 64.0)) + 1):
			var cell := Rect2(rect.position + Vector2(ix, iy) * 64.0, Vector2(64, 64))
			var clip := cell.intersection(rect)
			if clip.size.x <= 0 or clip.size.y <= 0: continue
			var roll := hash01(int(cell.position.x / 64.0), int(cell.position.y / 64.0), 11) * total
			var name: String = entries[0][0]
			for e in entries:
				roll -= float(e[1])
				if roll <= 0: name = e[0]; break
			ci.draw_texture_rect_region(tiles[name], clip, Rect2(clip.position - cell.position, clip.size))

func room_of_rect(sim, rect: Rect2) -> Dictionary:
	# 0.17: salas podem ter alas extras — o piso extra usa o chão e o estilo da sala dona.
	for room in sim.rooms:
		if room.r.encloses(rect) or room.r.has_point(rect.get_center()): return room
		for ex in room.get("extra", []):
			if ex == rect or ex.encloses(rect) or ex.has_point(rect.get_center()): return room
	return {}

func floor_kind(sim, rect: Rect2) -> String:
	var room := room_of_rect(sim, rect)
	return room.get("floor", "planks" if room.is_empty() else "stone")   # corredores: passarelas de madeira

func draw_floors(ci: CanvasItem, sim, floors: Array, rooms: Array, view: Rect2) -> void:
	for rect in floors:
		if not rect.intersects(view): continue
		var kind := floor_kind(sim, rect)
		var st := style_of_rect(sim, rect)
		if st.has("floor_set") and not st.has("floor_patch"):
			set_area(ci, rect, view, st.floor_set)
		else:
			var tint := Color(1.0, 0.93, 0.86) if kind == "cobble" else Color.WHITE
			tile_area(ci, rect, view, "planks" if kind == "planks" else "granite", Vector2.ZERO, tint)
			if st.has("floor_patch"): set_area(ci, st.floor_patch, view, st.floor_set)
		scatter_decals(ci, rect, view, kind, st.get("floor_set", ""))   # 0.17: chão "sujo"
		var amb: Color = AMBIENT.get(st.get("wall_set", ""), Color(0, 0, 0, 0))
		if amb.a > 0: ci.draw_rect(rect.intersection(view), amb)       # 0.17: tinte ambiente da sala
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
		# 0.17: espuma na beirada do cais (tiles foam_0 já existiam sem uso)
		var foam: Texture2D = tiles.foam_0
		var fx0 := zone.position.x
		while fx0 < zone.end.x:
			var bob := sin(t * 1.7 + fx0 * 0.05) * 3.0
			var w := minf(foam.get_width(), zone.end.x - fx0)
			ci.draw_texture_rect_region(foam, Rect2(fx0, zone.position.y - 8 + bob, w, minf(foam.get_height(), 40)), Rect2(0, 0, w, minf(foam.get_height(), 40)), Color(0.9, 0.95, 1, 0.75))
			fx0 += w
		# névoa rasteira sobre a água
		for i in range(3):
			var mp := Vector2(zone.position.x + fposmod(t * 0.03 + i * 0.37, 1.0) * zone.size.x, zone.position.y + 20 + i * zone.size.y * 0.3)
			if not area.grow(60).has_point(mp): continue
			ci.draw_set_transform(mp, 0, Vector2(1, 0.35))
			ci.draw_circle(Vector2.ZERO, 60 + i * 20, Color(0.7, 0.8, 0.95, 0.06 + 0.03 * sin(t + i)))
			ci.draw_set_transform(Vector2.ZERO)

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

func wall_tex(wset: String, name: String) -> Texture2D:
	# 0.17: pele da fachada; cai no tile padrão se a pele não tiver a peça.
	return wall_tiles.get(wset + "/" + name, tiles[name])

func strip(ci: CanvasItem, names: Array, x0: float, x1: float, y: float, h: float, salt: int, tint: Color = Color.WHITE, wset: String = "") -> Array:
	# Faixa horizontal com tiles de larguras diferentes; devolve [x, nome] de cada tile (para luzes).
	var placed: Array = []
	var x := x0
	var i := int(x0 / 50.0)
	while x < x1 - 0.5:
		var name: String = names[int(hash01(i, salt, 5) * names.size()) % names.size()]
		var tex: Texture2D = wall_tex(wset, name)
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
		var wset: String = style.get("wall_set", "")
		# topo: fachada de armazém
		if style.get("top", "facade") == "facade":
			for run in wall_runs(all_floors, tl, Vector2(br.x, tl.y), Vector2.UP):
				var x0: float = tl.x + run.x; var x1: float = tl.x + run.y
				var y_base := tl.y - 58.0; var y_brick := y_base - 107.0; var y_cap := y_brick - 51.0
				strip(ci, ["wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4"], x0, x1, y_cap, 51, int(tl.y), Color.WHITE, wset)
				var bricks := strip(ci, BRICK_POOL + ["brick_window"], x0, x1, y_brick, 107, int(tl.y) + 1, Color(0.92, 0.9, 0.9), wset)
				strip(ci, ["wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4"], x0, x1, y_base, 58, int(tl.y) + 2, Color.WHITE, wset)
				for b in bricks:
					if b[1] == "brick_window": lights.append({"p": Vector2(b[0], y_brick + 60), "kind": "window"})
				ci.draw_rect(Rect2(x0, tl.y - 4, x1 - x0, 4), Color(0, 0, 0, 0.45))
				wall_wear(ci, x0, x1, tl.y, wset)   # 0.17: infiltração, fuligem e pichações na fachada
				# pilares emolduram as aberturas (portas de corredor)
				for end in [x0, x1]:
					if end > tl.x + 2 and end < br.x - 2:
						var pil: Texture2D = wall_tex(wset, "wall_corner_0")
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
				strip(ci, ["wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4"], x0, x1, br.y, 51, int(br.y), Color(0.85, 0.85, 0.9), wset)
				strip(ci, ["wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4"], x0, x1, br.y + 51, 58, int(br.y) + 3, Color(0.7, 0.7, 0.78), wset)
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
				var tex: Texture2D = wall_tex(wset, "side_cap")
				var y := y0
				while y < y1:
					var h := minf(tex.get_height(), y1 - y)
					ci.draw_texture_rect_region(tex, Rect2(sx, y, SIDE_W, h), Rect2(0, 0, SIDE_W, h), Color(0.9, 0.9, 0.95))
					y += h
				ci.draw_rect(Rect2(sx + (SIDE_W - 3 if side < 0 else 0), y0, 3, y1 - y0), Color(0, 0, 0, 0.5))
				ci.draw_rect(Rect2(x + (0 if side < 0 else -14), y0 + WALL_H * (1 if run.x <= 0.5 else 0), 14, maxf(0, y1 - y0 - WALL_H)), Color(0, 0, 0, 0.18))

# ------------------------------------------------------------------ decals e desgaste (0.17)
func scatter_decals(ci: CanvasItem, rect: Rect2, view: Rect2, kind: String, set_name: String) -> void:
	# Manchas, rachaduras e restos no chão — sorteados por célula (estável entre quadros).
	var pool: Array = DECAL_POOL.get(kind, DECAL_POOL.stone).duplicate()
	pool.append_array(DECAL_POOL_SET.get(set_name, []))
	var cell := 220.0
	var area := rect.intersection(view.grow(140))
	if area.size.x <= 0 or area.size.y <= 0: return
	var density := 0.24 if set_name != "" else 0.16
	for gy in range(int(floorf(area.position.y / cell)), int(floorf(area.end.y / cell)) + 1):
		for gx in range(int(floorf(area.position.x / cell)), int(floorf(area.end.x / cell)) + 1):
			if hash01(gx, gy, 21) > density: continue
			var p := Vector2(gx * cell + 30 + hash01(gx, gy, 22) * (cell - 60), gy * cell + 30 + hash01(gx, gy, 23) * (cell - 60))
			if not rect.has_point(p): continue
			var name: String = pool[int(hash01(gx, gy, 24) * pool.size()) % pool.size()]
			var tex: Texture2D = decals[name]
			var s := 0.8 + hash01(gx, gy, 25) * 0.7
			ci.draw_set_transform(p, (hash01(gx, gy, 26) - 0.5) * 0.9, Vector2.ONE * s)
			ci.draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, 0.75 + 0.2 * hash01(gx, gy, 27)))
			ci.draw_set_transform(Vector2.ZERO)

func wall_wear(ci: CanvasItem, x0: float, x1: float, y_base: float, wset: String) -> void:
	# Desgaste seedado na fachada: infiltração desce do tijolo, fuligem, pichação do culto.
	var y_brick := y_base - 107.0
	var x := x0 + 24.0
	var i := int(x0 / 96.0)
	while x < x1 - 30:
		var roll := hash01(i, int(y_base), 31)
		if roll < 0.30:   # infiltração
			var h := 30 + hash01(i, 2, 32) * 60
			var w := 8 + hash01(i, 3, 33) * 18
			ci.draw_rect(Rect2(x, y_brick + 8, w, h), Color(0.1, 0.12, 0.14, 0.16))
			ci.draw_rect(Rect2(x + w - 3, y_brick + 8, 3, h * 0.7), Color(0.1, 0.12, 0.14, 0.22))
		elif roll < 0.42:   # fuligem/musgo na base
			ci.draw_set_transform(Vector2(x, y_base - 8), 0, Vector2(1, 0.45))
			ci.draw_circle(Vector2.ZERO, 16 + hash01(i, 4, 34) * 10, Color(0.05, 0.08, 0.06, 0.3))
			ci.draw_set_transform(Vector2.ZERO)
		elif roll < 0.52 and wset in ["cult", "abyssal"]:   # runa de giz na parede
			var tex: Texture2D = decals.glyph_chalk
			var k := 0.4 + 0.25 * sin(float(y_base) * 0.01)
			ci.draw_set_transform(Vector2(x, y_brick + 46), 0, Vector2.ONE * 0.45)
			ci.draw_texture(tex, -tex.get_size() * 0.5, Color(0.7, 1, 0.8, 0.4 + 0.2 * k))
			ci.draw_set_transform(Vector2.ZERO)
		x += 96.0; i += 1

func draw_wall_block(ci: CanvasItem, box: Rect2, t: float) -> void:
	# Parede interna/columna de labirinto: fachada de tijolo vista pelo topo (como wall_crack).
	var wset := ""
	for room in DOCKS.ROOMS:
		if room.r.has_point(box.get_center()):
			wset = DOCKS.ROOM_STYLE.get(room.get("id", ""), {}).get("wall_set", "")
			break
	var top := box.position.y - 150.0   # face visível sobe acima da base de colisão
	strip(ci, ["wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4"], box.position.x - 8, box.end.x + 8, top, 51, int(top), Color.WHITE, wset)
	var brick: Texture2D = wall_tex(wset, "brick_base")
	var y := top + 51.0
	while y < box.end.y - 24:
		var h := minf(brick.get_height(), box.end.y - 24 - y)
		ci.draw_texture_rect_region(brick, Rect2(box.position.x, y, box.size.x, h), Rect2(0, 0, minf(box.size.x, brick.get_width()), h), Color(0.94, 0.92, 0.92))
		y += brick.get_height()
	strip(ci, ["wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4"], box.position.x - 4, box.end.x + 4, box.end.y - 26, 26, int(box.end.y), Color(0.8, 0.8, 0.86), wset)
	ci.draw_rect(Rect2(box.position.x - 3, top, 3, box.end.y - top), Color(0, 0, 0, 0.5))
	ci.draw_rect(Rect2(box.end.x, top, 3, box.end.y - top), Color(0, 0, 0, 0.35))
	ci.draw_set_transform(Vector2(box.get_center().x, box.end.y + 4), 0, Vector2(1, 0.3))
	ci.draw_circle(Vector2.ZERO, box.size.x * 0.75, Color(0, 0, 0, 0.3)); ci.draw_set_transform(Vector2.ZERO)

# ------------------------------------------------------------------ armadilhas da sala-labirinto (0.17)
# Fases vindas de sim.trap_phase(h): "safe" (buracos), "warning" (aviso), "active" (fere).
func draw_trap(ci: CanvasItem, sim, h: Dictionary, t: float) -> void:
	var p: Vector2 = h.p; var r: float = h.r
	var phase: String = sim.trap_phase(h)
	var kind: String = h.get("trap", "spikes")
	match kind:
		"spikes":
			for gy in range(-2, 3):
				for gx in range(-2, 3):
					var hp := p + Vector2(gx, gy) * 32 + Vector2(hash01(gx, gy, 41) * 8, hash01(gx, gy, 42) * 8)
					if hp.distance_to(p) > r: continue
					ci.draw_set_transform(hp, 0, Vector2(1, 0.6))
					ci.draw_circle(Vector2.ZERO, 7, Color(0.04, 0.04, 0.06, 0.85))
					ci.draw_set_transform(Vector2.ZERO)
					if phase == "active":
						ci.draw_colored_polygon(PackedVector2Array([hp + Vector2(-7, 0), hp + Vector2(0, -26), hp + Vector2(7, 0)]), Color("9aa2b4"))
						ci.draw_colored_polygon(PackedVector2Array([hp + Vector2(-3, 0), hp + Vector2(0, -22), hp + Vector2(2, 0)]), Color("d6dbe8"))
			if phase == "warning":
				var k := 0.6 + 0.4 * sin(t * 18)
				ci.draw_arc(p, r * 0.85, 0, TAU, 48, Color(1, 0.75, 0.25, 0.5 * k), 3)
				for gy in range(-2, 3):
					for gx in range(-2, 3):
						var hp := p + Vector2(gx, gy) * 32
						if hp.distance_to(p) > r: continue
						ci.draw_line(hp + Vector2(-4, 0), hp + Vector2(4, 0), Color(1, 0.8, 0.3, 0.5 * k), 2)
		"darts":
			for off in [-r * 0.7, 0.0, r * 0.7]:   # frestas nas laterais
				ci.draw_rect(Rect2(p.x - r - 14, p.y + off - 4, 14, 8), Color(0.03, 0.03, 0.05))
				ci.draw_rect(Rect2(p.x + r, p.y + off - 4, 14, 8), Color(0.03, 0.03, 0.05))
			if phase == "warning":
				var k := 0.6 + 0.4 * sin(t * 16)
				for off in [-r * 0.7, 0.0, r * 0.7]:
					ci.draw_line(Vector2(p.x - r, p.y + off), Vector2(p.x + r, p.y + off), Color(1, 0.6, 0.2, 0.35 * k), 2)
			elif phase == "active":
				for off in [-r * 0.7, 0.0, r * 0.7]:
					var drift := fposmod(t * 3.0 + off, 1.0) * r * 2
					for dx in [-drift, r * 2 - drift]:
						var dp := Vector2(p.x - r + dx, p.y + off)
						ci.draw_line(dp - Vector2(18, 0), dp + Vector2(6, 0), Color(0.85, 0.85, 0.9, 0.9), 3)
						ci.draw_colored_polygon(PackedVector2Array([dp + Vector2(10, 0), dp + Vector2(4, -4), dp + Vector2(4, 4)]), Color("cfd6e4"))
		"steam":
			ci.draw_set_transform(p, 0, Vector2(1, 0.55))
			ci.draw_circle(Vector2.ZERO, r * 0.5, Color(0.06, 0.07, 0.09))
			ci.draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 32, Color("565e6e"), 4)
			for k in range(4):
				var a := k * TAU / 4 + PI / 4
				ci.draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(a) * r * 0.48, Color("454c5c"), 3)
			ci.draw_set_transform(Vector2.ZERO)
			if phase == "warning":
				var k := 0.5 + 0.5 * sin(t * 14)
				for n in range(3):   # fio de vapor subindo
					var wp := p + Vector2(-20 + n * 20, -8 - fposmod(t * 1.4 + n * 0.4, 1.0) * 30)
					ci.draw_rect(Rect2(wp, Vector2(4, 10)), Color(0.8, 0.85, 0.9, 0.3 * k))
			elif phase == "active":
				for n in range(4):   # jato
					var hgt := 70 + sin(t * 20 + n) * 12
					var wpx := p.x - 30 + n * 20
					ci.draw_rect(Rect2(wpx - 6, p.y - hgt, 12, hgt), Color(0.85, 0.9, 0.95, 0.28))
					ci.draw_rect(Rect2(wpx - 2, p.y - hgt, 4, hgt), Color(0.95, 0.98, 1.0, 0.4))
				lights.append({"p": p - Vector2(0, 40), "kind": "cyan"})

# ------------------------------------------------------------------ atmosfera viva (0.17)
func draw_ambience(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	var t: float = sim.tick_time
	for room in rooms:
		if not room.has("id"): continue
		var r: Rect2 = room.r
		var style := style_of(room)
		# partículas de poeira/maresia à deriva — densidade por tamanho da sala
		var n := clampi(int(r.get_area() / 220000), 4, 14)
		for i in range(n):
			var bx := r.position.x + hash01(i, int(r.position.x), 51) * r.size.x
			var by := r.position.y + hash01(i, int(r.position.y), 52) * r.size.y
			var p := Vector2(bx + sin(t * 0.35 + i * 1.7) * 26, by + cos(t * 0.27 + i * 2.3) * 14 - fposmod(t * 0.05 + i * 0.11, 1.0) * 30)
			if not view.has_point(p): continue
			var a := 0.10 + 0.08 * sin(t * 0.9 + i * 3.1)
			var warm: bool = style.get("wall_set", "") != "abyssal"
			ci.draw_rect(Rect2(p, Vector2(3, 3)), Color(0.9, 0.85, 0.7, a) if warm else Color(0.7, 0.85, 0.9, a))
		# goteira nas salas abissais — filetes caindo do alto da sala
		if style.get("wall_set", "") == "abyssal":
			for i in range(5):
				var dx := r.position.x + 60 + hash01(i, int(r.position.y), 53) * (r.size.x - 120)
				var fall := fposmod(t * 0.55 + i * 0.31, 1.0)
				var py := r.position.y + fall * minf(r.size.y - 80, 420.0)
				ci.draw_rect(Rect2(dx, py, 2, 12), Color(0.6, 0.8, 0.95, 0.35 * (1 - fall)))
				if fall > 0.94: ci.draw_circle(Vector2(dx + 1, r.position.y + minf(r.size.y - 80, 420.0)), 6 * (fall - 0.94) / 0.06, Color(0.6, 0.8, 0.95, 0.25))

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
	if kind.begins_with("wall_crack_"):
		# 0.16: segmento de fachada (128x216) com a base na borda da sala (box.end.y - 12)
		ci.draw_texture(tiles[kind], Vector2(box.position.x, box.end.y - 12 - 216))
		return
	if kind == "maze_wall" or kind == "wall_block":
		draw_wall_block(ci, box, t); return   # 0.17: parede interna (labirinto/colunas)
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
		"chapel_offering_bowl": lights.append({"p": foot - Vector2(0, 30), "kind": "violet"})
		"workshop_welder":
			if int(t * 14) % 3 != 0: lights.append({"p": foot + Vector2(18, -34), "kind": "cyan"})
		"lamp_post": lights.append({"p": foot + Vector2(0, -6), "kind": "amber", "s": 1.2}); lights.append({"p": foot - Vector2(0, size.y - 22), "kind": "bulb"})
		"brazier":
			lights.append({"p": foot - Vector2(0, 40), "kind": "fire"})
			for n in range(3):   # 0.17: fagulhas subindo do braseiro
				var ph := fposmod(t * 0.5 + n * 0.33 + foot.x * 0.01, 1.0)
				var ep := foot + Vector2(sin(t * 3 + n * 2.1) * 10, -30 - ph * 70)
				ci.draw_rect(Rect2(ep, Vector2(2.5, 2.5)), Color(1, 0.7 + 0.25 * (1 - ph), 0.25, 0.8 * (1 - ph)))

# Decoração: plana (chão), na parede (fachada) ou em pé (ordenada por Y junto com as entidades).
const FLAT_DECOR := ["workshop_oil_puddle", "grate", "manhole", "symbol_0", "symbol_1", "symbol_2", "tentacle_pool", "ritual_circle", "tentacle_planks", "rails_diag", "rails", "rowboat", "debris_crate", "debris_barrel", "debris_sandbags", "rope", "anchor"]
const WALL_DECOR := ["poster", "iron_door", "wall_lamp", "phone_booth_wall", "market_lanterns", "chapel_banner"]

func is_flat(kind: String) -> bool: return kind in FLAT_DECOR or kind in WALL_DECOR or kind.begins_with("wall_crack_")
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
		"wall_crack_a_open", "wall_crack_b_open", "wall_crack_c_open":
			ci.draw_texture(tiles[d.kind], p - Vector2(0, 216 + 12))
		"workshop_oil_puddle":
			var tex: Texture2D = props[d.kind]
			ci.draw_texture(tex, p - tex.get_size() * 0.5)
		"market_lanterns":
			draw_prop(ci, d.kind, p, t)
			for k in 4: lights.append({"p": p + Vector2(-33 + k * 22, -8), "kind": "bulb"})
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
			"violet":
				ci.draw_texture_rect(fx.soft_circle, Rect2(p - Vector2(90, 70), Vector2(180, 140)), false, Color(0.65, 0.3, 1.0, 0.4 + 0.1 * sin(t * 3 + p.x)))

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

# ------------------------------------------------------------------ portão de tentáculo (0.16)
# Ativo: poça viva em 2x (fecha os 200 px do corredor) com brilho vermelho; selado: grade acorrentada.
func draw_tentacle_gate(ci: CanvasItem, g: Dictionary, t: float) -> void:
	var tex: Texture2D = props.tentacle_gate_sealed if g.sealed else props.tentacle_gate_active
	var size := tex.get_size() * 2.0
	var sway := Vector2.ZERO if g.sealed else Vector2(0, sin(t * 3.0) * 2.0)
	ci.draw_texture_rect(tex, Rect2(g.p - size * 0.5 + sway, size), false)
	if not g.sealed: lights.append({"p": g.p, "kind": "danger"})
