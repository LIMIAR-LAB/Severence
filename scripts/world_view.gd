class_name DockView
extends Node2D
const DocksMap = preload("res://scripts/docks_map.gd")
const SummonFX = preload("res://scripts/summon_fx.gd")
const ArrivalArt = preload("res://scripts/arrival_art.gd")
var arrival_art := ArrivalArt.new()
const Scenery = preload("res://scripts/dock_scenery.gd")

# Camada de luz (modo aditivo) desenhada por cima do mundo: postes, janelas, braseiros, explosões.
class LightLayer extends Node2D:
	var host
	func _draw() -> void:
		if host and host.sim and host.sim.mode != "hub": host.scenery.draw_lights(self, host.sim.tick_time)

var scenery
var light_layer: LightLayer
var vis_floors: Array = []     # pisos descobertos neste quadro (névoa)
var vis_rooms: Array = []
const NIGHT := Color(0.74, 0.78, 0.96)

var sim: Expedition
var marty_texture: Texture2D
var mech_texture: Texture2D
var action_texture: Texture2D
var floor_texture: Texture2D
var spectre_texture: Texture2D
var fusion_texture: Texture2D
var spectre_actions: Dictionary = {}
var fusion_actions: Dictionary = {}
var warden_texture: Texture2D
var dock_art: Dictionary = {}
var font: Font
var outfit_texture: Texture2D
var marty_anim: Texture2D
var marty_padrao_actions: Dictionary = {}
var marty_omega_actions: Dictionary = {}
var omega_assembly_texture: Texture2D
var marty_roll: Dictionary = {}
var marty_teleport: Dictionary = {}
var enemy_anim: Texture2D
var special_enemy_art: Dictionary = {}
var pixellab_enemy_art: Dictionary = {}
var pixellab_enemy_actions: Dictionary = {}
var weapon_art: Dictionary = {}
var cockpit_texture: Texture2D
var titan_v2: Texture2D
var docks_art: Dictionary = {}
var cobble_texture: Texture2D
var enemy_texture: Texture2D
var boss_art: Dictionary = {}
var projectile_art: Dictionary = {}
const OUTFIT_ROW := {"padrao": 0, "espiao": 1, "mecanico": 2, "omega": 3}
const MARTY_ATLAS_PATH := "res://assets/marty/marty_anim_v3.png"
const MARTY_PADRAO_ROOT := "res://assets/characters/marty/padrao/pixellab/"
const MARTY_PADRAO_FRAMES := {
	"idle": 4, "run": 8, "jump": 9, "evade": 6,
	"shoot": 3, "melee": 6, "hurt": 6, "defeat": 7,
}
const MARTY_OMEGA_ROOT := "res://assets/characters/marty/omega/pixellab/"
const MARTY_OMEGA_CELL := 112
const MARTY_OMEGA_DRAW_SIZE := 124.0
const MARTY_OMEGA_FRAMES := {
	"idle": 4, "run": 8, "jump": 8, "evade": 7,
	"melee": 6, "hurt": 6, "defeat": 8,
}
const TITAN_ATLAS_PATH := "res://assets/mech/titan_v5.png"
const SPECTRE_ATLAS_PATH := "res://assets/mech/spectre_octopus_v2.png"
const FUSION_ATLAS_PATH := "res://assets/marty/spectre_fusion_v3.png"
const SPECTRE_ACTION_ROOT := "res://assets/characters/spectre/pixellab/"
const FUSION_ACTION_ROOT := "res://assets/characters/marty/spectre_fusion/pixellab/"
const SPECTRE_ACTION_CELL := 128
const FUSION_ACTION_CELL := 128
const ENEMY_ROW := {"cult": 0, "fish": 1, "crawler": 2, "crawler_small": 2, "brute": 3}
const PIXELLAB_ENEMY_VERSION := {"guard": "v1", "bomber": "v1", "cult": "v2", "fish": "v2", "crawler": "v2", "brute": "v2"}
const PIXELLAB_ENEMY_SIZE := {"guard": 84.0, "bomber": 72.0, "cult": 88.0, "fish": 88.0, "crawler": 96.0, "brute": 112.0}
var refuge_bg: Texture2D
var refuge_core: Texture2D
const CORE_OFFSET := Vector2(548, 232)
const CYAN := Color("66e5ed")
const GOLD := Color("e9bc77")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["bomber", "guard"]: special_enemy_art[kind] = load("res://assets/enemies/" + kind + ".png")
	# 0.20: oito direções e quatro passadas por inimigo, pivô nos pés.
	for kind in PIXELLAB_ENEMY_VERSION:
		var path := "res://assets/enemies/%s_pixellab_%s.png" % [kind, PIXELLAB_ENEMY_VERSION[kind]]
		if ResourceLoader.exists(path): pixellab_enemy_art[kind] = load(path)
		var action_path := "res://assets/enemies/%s_actions_v2.png" % kind
		if ResourceLoader.exists(action_path): pixellab_enemy_actions[kind] = load(action_path)
	marty_texture = load("res://assets/marty/marty-v2.png")
	mech_texture = load("res://assets/mech/titan.png")
	action_texture = load("res://assets/marty/actions-v2.png")
	floor_texture = load("res://assets/environment/reference/floor.png")
	for key in ["water", "wall", "crate", "lamp", "chest", "barrel", "sandbags", "rope", "coin", "key"]:
		dock_art[key] = load("res://assets/environment/reference/" + key + ".png")
	# 0.15: Spectre é um pequeno polvo mecânico; a fusão preserva Marty visível.
	spectre_texture = load(SPECTRE_ATLAS_PATH)
	fusion_texture = load(FUSION_ATLAS_PATH)
	for action in ["idle", "run", "shoot", "evade", "hurt", "defeat"]:
		var path: String = SPECTRE_ACTION_ROOT + action + ".png"
		if ResourceLoader.exists(path): spectre_actions[action] = load(path)
	for action in ["idle", "run", "jump", "evade", "shoot", "melee", "hurt", "defeat"]:
		var path: String = FUSION_ACTION_ROOT + action + ".png"
		if ResourceLoader.exists(path): fusion_actions[action] = load(path)
	warden_texture = load("res://assets/enemies/warden.png")
	outfit_texture = load("res://assets/marty/outfits.png")
	# 0.15: atlas normalizado; todas as skins compartilham a mesma grade e pivô.
	marty_anim = load(MARTY_ATLAS_PATH)
	# Marty Padrao usa arte propria em oito direcoes, sem espelhar detalhes assimetricos.
	for action in MARTY_PADRAO_FRAMES:
		marty_padrao_actions[action] = load(MARTY_PADRAO_ROOT + action + ".png")
	# A Armadura Omega tem celula e escala proprias para preservar seu volume.
	for action in MARTY_OMEGA_FRAMES:
		marty_omega_actions[action] = load(MARTY_OMEGA_ROOT + action + ".png")
	omega_assembly_texture = load("res://assets/characters/marty/omega/assembly/omega_assembly_overlay_v1.png")
	# 0.19: ações novas usam quadros e pivô idênticos, sem arma incorporada.
	for direction in ["side", "front_diag", "back_diag"]:
		marty_roll[direction] = load("res://assets/marty/marty_roll_%s_v1.png" % direction)
	marty_teleport["side"] = load("res://assets/marty/marty_teleport_side_v1.png")
	marty_teleport["front_diag"] = load("res://assets/marty/marty_teleport_diagonal_v1.png")
	marty_teleport["back_diag"] = marty_teleport["front_diag"]
	# 0.15: Titan fechado, sem piloto exposto, com olhos ciano no visor blindado.
	titan_v2 = load(TITAN_ATLAS_PATH)
	cockpit_texture = load("res://assets/mech/titan_cockpit.png")
	for key in ["planks", "wall_side", "container_red", "container_blue", "container_olive", "pillar", "bollard", "generator", "altar", "pew", "ammo", "fishbox", "candles", "puddle", "anchor", "capsule", "crack", "key", "coin", "rug", "stairs"]:   # 0.15: props HD (tools/make_props_hd.py)
		docks_art[key] = load("res://assets/environment/docks/" + key + ".png")
	cobble_texture = load("res://assets/environment/cobble.png")
	enemy_anim = load("res://assets/enemies/docas_anim.png")
	for key in ["pistol", "shotgun", "smg", "bazooka", "omega", "omega_sword", "knife", "wrench", "sword_smear", "flash", "flash_cyan"]:
		weapon_art[key] = load("res://assets/weapons/" + ("bazooka_v2" if key == "bazooka" else key) + ".png")
	weapon_art["foguete"] = load("res://assets/ui/equipamento/icones/icon_foguete_v1.png")
	for key in ["pistol", "smg", "pellet", "omega", "wave"]:
		projectile_art["p_" + key] = load("res://assets/weapons/b_" + key + ".png")
	enemy_texture = load("res://assets/enemies/docas.png")
	for key in ["idle", "ring", "spiral", "charge", "hurt", "fury", "defeat"]:
		boss_art[key] = load("res://assets/boss/almirante_" + key + ".png")
	for key in ["magenta", "harpoon", "acid", "violet"]:
		projectile_art[key] = load("res://assets/enemies/proj_" + key + ".png")
	for key in ["orb", "cannon", "ink", "flame"]:
		projectile_art[key] = load("res://assets/boss/proj_" + key + ".png")
	projectile_art["boss_harpoon"] = load("res://assets/boss/proj_harpoon.png")
	refuge_bg = load("res://assets/environment/refuge/refuge_bg.png")
	refuge_core = load("res://assets/environment/refuge/core_front.png")
	font = ThemeDB.fallback_font
	scenery = Scenery.new()
	light_layer = LightLayer.new(); light_layer.host = self
	var mat := CanvasItemMaterial.new(); mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light_layer.material = mat; light_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(light_layer)

func text_at(p: Vector2, text: String, color: Color = GOLD, size: int = 14) -> void:
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if sim == null: return
	scenery.lights.clear()
	modulate = Color.WHITE if sim.mode == "hub" else NIGHT
	if light_layer: light_layer.queue_redraw()
	if sim.mode == "hub": draw_refuge_back()
	else: draw_expedition_ground()
	draw_entities()
	if sim.mode == "hub": draw_refuge_front()
	draw_screen_flash()

func view_rect() -> Rect2:
	var inv := get_canvas_transform().affine_inverse()
	var size := get_viewport_rect().size
	return Rect2(inv * Vector2.ZERO, inv.basis_xform(size)).abs().grow(160)

func floor_kind(rect: Rect2) -> String:
	for room in sim.rooms:
		if room.r.encloses(rect) or room.r.has_point(rect.get_center()): return room.get("floor", "stone")
		for ex in room.get("extra", []):
			if ex.encloses(rect) or ex.has_point(rect.get_center()): return room.get("floor", "stone")
	return "stone"

func tile_floor(rect: Rect2, view: Rect2, kind: String) -> void:
	var tex: Texture2D = floor_texture
	var size := 128
	if kind == "planks": tex = docks_art.planks
	elif kind == "cobble": tex = cobble_texture; size = 64
	var area := rect.intersection(view)
	if area.size.x <= 0 or area.size.y <= 0: return
	var x0 := int(rect.position.x + floorf((area.position.x - rect.position.x) / size) * size)
	var y0 := int(rect.position.y + floorf((area.position.y - rect.position.y) / size) * size)
	for y in range(y0, int(minf(rect.end.y, area.end.y)), size):
		for x in range(x0, int(minf(rect.end.x, area.end.x)), size):
			var cell := Rect2(x, y, minf(size, rect.end.x - x), minf(size, rect.end.y - y))
			draw_texture_rect_region(tex, cell, Rect2(Vector2.ZERO, cell.size))

func seen(p: Vector2, margin: float = 30.0) -> bool:
	# névoa: só o que está em piso já descoberto aparece
	return sim.mode != "run" or Scenery.inside(vis_floors, p, margin)

func draw_expedition_ground() -> void:
	var view := view_rect()
	var t: float = sim.tick_time
	draw_rect(view, Scenery.VOID)
	vis_rooms = scenery.discovered_rooms(sim)
	vis_floors = scenery.visible_floors(sim, vis_rooms)
	scenery.draw_water(self, sim, vis_rooms, view)
	arrival_art.draw_ground(self, sim, vis_rooms, view, scenery.lights)
	scenery.draw_floors(self, sim, vis_floors, vis_rooms, view)
	scenery.draw_floor_grunge(self, sim, vis_floors, view)
	# balcão elevado e rampas
	for area in sim.raised:
		if not seen(area.get_center()): continue
		draw_rect(area, Color(1, 0.95, 0.85, 0.07))
		draw_rect(Rect2(area.position.x, area.end.y, area.size.x, 44), Color("2c2a33"))
		scenery.strip(self, ["wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4"], area.position.x, area.end.x, area.end.y - 14, 58, int(area.end.y))
		draw_line(Vector2(area.position.x, area.end.y), Vector2(area.end.x, area.end.y), Color("c9bfae"), 3)
	for ramp in sim.ramps:
		var r: Rect2 = ramp.r
		if not seen(r.get_center()): continue
		# 0.15: degraus de pedra (azulejo 64×64); o lado alto fica mais claro
		var y := r.position.y
		while y < r.end.y:
			var h := minf(64.0, r.end.y - y)
			var x := r.position.x
			while x < r.end.x:
				var w := minf(64.0, r.end.x - x)
				draw_texture_rect_region(docks_art.stairs, Rect2(x, y, w, h), Rect2(0, 0, w, h))
				x += 64.0
			y += 64.0
		var high_left: bool = ramp.high < ramp.low
		draw_rect(Rect2(r.position.x if high_left else r.end.x - 24, r.position.y, 24, r.size.y), Color(1, 0.95, 0.85, 0.08))
		draw_rect(Rect2(r.end.x - 24 if high_left else r.position.x, r.position.y, 24, r.size.y), Color(0, 0, 0, 0.18))
	for gap in sim.gaps:
		if gap.intersects(view) and seen(gap.get_center(), gap.size.length()): scenery.draw_gap(self, sim, gap)
	scenery.draw_walls(self, sim, vis_floors, vis_rooms, view)
	# Placa animada acima das paredes procedurais antigas e abaixo do gameplay.
	scenery.draw_chapel_plate(self, sim, vis_rooms, view)
	arrival_art.draw_rift(self, sim, scenery.lights)
	# decoração do chão (sob as entidades)
	for h in sim.hazards:
		if h.has("trap") and seen(h.p): scenery.draw_trap(self,sim,h,t)
		var alert := false
		for a in sim.actors:
			if a.active and not a.dead and a.p.distance_to(h.p) < h.r + 90: alert = true
		h["alert"] = alert
	for d in sim.decor:
		if not view.has_point(d.p) or not seen(d.p, 120): continue
		if scenery.chapel_hides_legacy(d.kind, d.p): continue
		if scenery.is_flat(d.kind):
			if d.kind == "tentacle_pool":
				for h in sim.hazards:
					if h.p.distance_to(d.p) < 5: d["alert"] = h.get("alert", false)
			scenery.draw_decor(self, d, t)
		elif not scenery.handles(d.kind): draw_decor(d)
	for g in sim.tentacle_gates:   # 0.16
		if view.grow(200).has_point(g.p) and seen(g.p, 160): scenery.draw_tentacle_gate(self, g, t)
	for room in vis_rooms:
		var rect: Rect2 = room.r
		if not rect.grow(300).intersects(view) or not room.has("id"): continue
		text_at(rect.position + Vector2(40, -228 if scenery.style_of(room).get("top", "facade") == "facade" else -20), room.name, Color("e8d9b8"), 18)
	# portões
	for d in sim.doors:
		var room: Dictionary = sim.room_by_id(d.room)
		if room.is_empty() or not d.r.grow(200).intersects(view) or not seen(d.r.get_center(), 60): continue
		if scenery.chapel_hides_gate(d.room, d.r): continue
		scenery.draw_gate(self, d, room.get("locked", false), t, room.r)
	if sim.mode == "run": draw_docks()
	else:
		text_at(Vector2(135, 865), "ONDA %d  •  SHIFT = DASH  •  R = ARMADURA  •  E = PILOTAR" % sim.arena_wave, CYAN, 18)
	for chest in sim.chests:
		if chest.secret and not sim.secret_open: continue
		var p: Vector2 = chest.p
		if not view.has_point(p) or not seen(p): continue
		draw_chest(chest)
		if not chest.open:
			draw_rect(Rect2(p - Vector2(4, 9), Vector2(8, 10)), CYAN if chest.secret else GOLD)
			text_at(p + Vector2(-30, 25), "E • grátis" if chest.get("reward",false) else "E • 1 chave", Color("c9b99c"), 12)
			scenery.lights.append({"p": p - Vector2(0, 20), "kind": "cyan" if chest.secret else "bulb"})
	scenery.draw_reveal(self, sim, vis_rooms)

func draw_decor(d: Dictionary) -> void:
	var p: Vector2 = d.p
	match d.kind:
		"puddle": draw_texture(docks_art.puddle, p - Vector2(60, 25), Color(1, 1, 1, 0.85 + 0.15 * sin(sim.tick_time + p.x)))
		"oil":
			visual_transform(p, 0, Vector2(1, 0.45)); draw_circle(Vector2.ZERO, 34, Color(0.04, 0.04, 0.06, 0.55)); draw_circle(Vector2(-8, -6), 10, Color(0.3, 0.2, 0.4, 0.25)); visual_transform(Vector2.ZERO)
		"rope": draw_texture_rect(dock_art.rope, Rect2(p - Vector2(29, 23), Vector2(58, 46)), false)
		"anchor": draw_texture(docks_art.anchor, p - Vector2(30, 35))
		"candles":
			draw_texture(docks_art.candles, p - Vector2(20, 38))
			for k in range(3): draw_circle(p - Vector2(0, 26), 26 + k * 14, Color(1, 0.7, 0.3, 0.05 * (0.8 + 0.2 * sin(sim.tick_time * 9 + k))))
		"rails":
			draw_rect(Rect2(p.x - 260, p.y - 10, 520, 4), Color("5d5f68")); draw_rect(Rect2(p.x - 260, p.y + 10, 520, 4), Color("5d5f68"))
			for x in range(-250, 260, 26): draw_rect(Rect2(p.x + x, p.y - 14, 8, 30), Color("4a3a2c"))
		"net":
			for k in range(6):
				draw_line(p + Vector2(k * 12 - 36, -20), p + Vector2(k * 12 - 26, 24), Color(0.55, 0.5, 0.4, 0.6), 1)
				draw_line(p + Vector2(-40, k * 8 - 20), p + Vector2(36, k * 8 - 16), Color(0.55, 0.5, 0.4, 0.6), 1)
		"rug": draw_texture(docks_art.rug, p - Vector2(70, 160))

func draw_obstacle(box: Rect2, kind: String) -> void:
	if scenery.has_prop(kind) or kind == "crate_row":
		scenery.draw_obstacle(self, box, kind, sim.tick_time); return
	visual_transform(Vector2(box.position.x + box.size.x * 0.5, box.end.y + 4), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, box.size.x * 0.55, Color(0, 0, 0, 0.3)); visual_transform(Vector2.ZERO)
	match kind:
		"container_red", "container_blue", "container_olive":
			draw_texture_rect(docks_art[kind], Rect2(box.position - Vector2(0, 34), Vector2(box.size.x, box.size.y + 34)), false)
		"pillar": draw_texture_rect(docks_art.pillar, Rect2(box.position - Vector2(3, 52), Vector2(box.size.x + 6, box.size.y + 52)), false)
		"bollard": draw_texture_rect(docks_art.bollard, Rect2(box.position - Vector2(2, 12), Vector2(34, 42)), false)
		"generator":
			draw_texture_rect(docks_art.generator, Rect2(box.position - Vector2(5, 32), Vector2(box.size.x + 10, box.size.y + 32)), false)
			draw_circle(box.get_center() - Vector2(0, 40), 30 + sin(sim.tick_time * 6) * 4, Color(0.3, 0.9, 1, 0.12))
		"altar": draw_texture_rect(docks_art.altar, Rect2(box.position - Vector2(5, 32), Vector2(box.size.x + 10, box.size.y + 32)), false)
		"pew": draw_texture_rect(docks_art.pew, Rect2(box.position - Vector2(0, 6), Vector2(box.size.x, box.size.y + 6)), false)
		"ammo": draw_texture_rect(docks_art.ammo, Rect2(box.position - Vector2(0, 4), Vector2(box.size.x, box.size.y + 4)), false)
		"fishbox": draw_texture_rect(docks_art.fishbox, Rect2(box.position - Vector2(2, 2), Vector2(box.size.x + 4, box.size.y + 2)), false)
		"barrel": draw_texture_rect(dock_art.barrel, Rect2(box.position - Vector2(0, 30), box.size + Vector2(0, 30)), false)
		"sandbags": draw_texture_rect(dock_art.sandbags, Rect2(box.position - Vector2(0, 20), box.size + Vector2(0, 20)), false)
		"crate_row":
			var x := box.position.x
			while x < box.end.x - 4:
				crate(Rect2(x, box.position.y, minf(60, box.end.x - x), box.size.y)); x += 60
		_: crate(box)

func draw_entities() -> void:
	for fx in sim.effects:
		if fx.kind == "corpse": draw_corpse(fx)
	for pickup in sim.pickups:
		if not seen(pickup.p): continue
		var p: Vector2 = pickup.p + Vector2(0, sin(sim.tick_time * 4) * 3)
		visual_transform(pickup.p + Vector2(0, 6), 0, Vector2(1, 0.4)); draw_circle(Vector2.ZERO, 10, Color(0, 0, 0, 0.35)); visual_transform(Vector2.ZERO)
		if pickup.kind == "key":
			draw_circle(p - Vector2(0, 10), 16, Color(1, 0.85, 0.4, 0.15))
			draw_texture_rect(docks_art.key, Rect2(p - Vector2(12, 26), Vector2(24, 27)), false)
		elif pickup.kind == "weapon":
			draw_circle(p - Vector2(0, 13), 34, Color(0.35, 0.9, 1, 0.15))
			draw_texture_rect(weapon_art.bazooka, Rect2(p - Vector2(42, 38), Vector2(84, 56)), false)
		elif pickup.kind == "ammo":
			draw_circle(p - Vector2(0, 9), 17, Color(1, 0.65, 0.3, 0.18))
			draw_texture_rect(weapon_art.foguete, Rect2(p - Vector2(18, 29), Vector2(36, 36)), false)
		elif pickup.kind == "fuel":
			# Galão de gasolina (0.14): corpo vermelho com alça escura
			draw_circle(p - Vector2(0, 10), 17, Color(1, 0.5, 0.25, 0.15))
			draw_rect(Rect2(p - Vector2(7, 26), Vector2(14, 19)), Color(0.75, 0.16, 0.12))
			draw_rect(Rect2(p - Vector2(7, 26), Vector2(14, 4)), Color(0.9, 0.3, 0.2))
			draw_rect(Rect2(p - Vector2(4, 31), Vector2(8, 4)), Color(0.35, 0.2, 0.16))
		elif pickup.kind == "battery":
			# Bateria (0.14): célula ciano com polo positivo
			draw_circle(p - Vector2(0, 10), 17, Color(0.4, 0.9, 1, 0.15))
			draw_rect(Rect2(p - Vector2(6, 24), Vector2(12, 18)), Color(0.15, 0.55, 0.65))
			draw_rect(Rect2(p - Vector2(2, 28), Vector2(4, 4)), Color(0.7, 0.95, 1))
			draw_rect(Rect2(p - Vector2(6, 24), Vector2(12, 3)), Color(0.85, 0.75, 0.3))
		else: draw_texture_rect(docks_art.coin, Rect2(p - Vector2(8, 18), Vector2(16, 18)), false)
	var drawable: Array = []
	if sim.mode == "run":
		var view := view_rect()
		for i in range(sim.obstacles.size()):
			var box: Rect2 = sim.obstacles[i]
			var kind: String = sim.obstacle_kinds[i] if i < sim.obstacle_kinds.size() else "crate"
			if box.intersects(view) and seen(box.get_center(), 60) and not scenery.chapel_hides_legacy(kind, box.get_center()):
				drawable.append({"type": "obstacle", "data": {"r": box, "k": kind}, "y": box.end.y})
		for d in sim.decor:   # props de decoração em pé entram na ordenação por Y
			if scenery.handles(d.kind) and not scenery.is_flat(d.kind) and view.has_point(d.p) and seen(d.p, 60) and not scenery.chapel_hides_legacy(d.kind, d.p):
				drawable.append({"type": "decor", "data": d, "y": d.p.y})
		if seen(DocksMap.POINTS.extraction): drawable.append({"type": "capsule", "data": {}, "y": DocksMap.POINTS.extraction.y + 20})
		if seen(sim.STORY_NPC): drawable.append({"type": "chapel_npc", "data": {"p": sim.STORY_NPC}, "y": sim.STORY_NPC.y})
	else:
		for box in sim.obstacles: drawable.append({"type": "obstacle", "data": {"r": box, "k": "crate"}, "y": box.end.y})
	for a in sim.actors:
		if a.active and not a.mech and not (sim.mech.get("cockpit_t", 0.0) > 0 and sim.mech.get("cockpit_actor", -1) == a.id): drawable.append({"type": "actor", "data": a, "y": a.p.y})
	for e in sim.enemies:
		if seen(e.p): drawable.append({"type": "enemy", "data": e, "y": e.p.y})
	# Cápsula Temporal: o robô só aparece quando a cápsula termina de materializá-lo.
	if sim.mech.deployed and not SummonFX.robot_hidden(sim.effects, "titan"): drawable.append({"type": "mech", "data": sim.mech, "y": sim.mech.p.y})
	for s in sim.spectres:
		if s.state == "following" and not SummonFX.robot_hidden(sim.effects, "spectre", s.owner): drawable.append({"type": "spectre", "data": s, "y": s.p.y})
	if sim.mode == "hub": drawable.append({"type": "core", "data": {}, "y": 436.0})
	drawable.sort_custom(func(a, b): return a.y < b.y)
	draw_combat_warnings()
	for thing in drawable:
		visual_scale = sim.ACTOR_VISUAL_SCALE if thing.type in ["actor", "enemy", "mech", "spectre"] else 1.0
		visual_origin = thing.data.get("p", Vector2.ZERO)
		visual_transform(Vector2.ZERO)
		match thing.type:
			"actor": draw_actor(thing.data)
			"enemy": draw_enemy(thing.data)
			"mech": draw_mech(thing.data)
			"obstacle": draw_obstacle(thing.data.r, thing.data.k)
			"decor": scenery.draw_prop(self, thing.data.kind, thing.data.p, sim.tick_time)
			"capsule": draw_capsule()
			"chapel_npc":
				var npc_texture: Texture2D = scenery.chapel_fisherman_texture(sim.tick_time)
				if npc_texture != null:
					draw_texture_rect(npc_texture, Rect2(thing.data.p - Vector2(40, 112), Vector2(80, 112)), false)
				else:
					scenery.draw_prop(self, "npc_fisherman", thing.data.p, sim.tick_time)
			"spectre": draw_spectre(thing.data)
			"core": draw_texture(refuge_core, CORE_OFFSET, Color(1, 1, 1, core_alpha()))
	visual_scale = 1.0; visual_origin = Vector2.ZERO; visual_transform(Vector2.ZERO)
	if sim.mode == "run" and seen(sim.STORY_NPC):
		var nearest_actor: float = 99999.0
		for actor in sim.actors:
			if actor.active: nearest_actor = minf(nearest_actor, actor.p.distance_to(sim.STORY_NPC))
		if sim.story_quest < 2 or nearest_actor < 145.0:
			var npc_label := chapel_npc_label(sim.story_quest)
			# O rótulo usa coordenadas mundiais, fora de qualquer transform de sprite.
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			text_at(sim.STORY_NPC + Vector2(-82, -112), npc_label, GOLD if sim.story_quest < 2 else Color("c9b99c"), 14)
	for b in sim.bullets:
		if not seen(b.p): continue
		var bullet_pos: Vector2 = b.p - Vector2(0, b.get("height", 28.0))
		var kind: String = b.get("kind", "")
		if kind == "bomb":
			# 0.15: telegraph da zona de impacto — anel vermelho no ponto de queda
			var landing: Vector2 = b.get("to", b.p)
			draw_arc(landing + Vector2(0, 4), sim.MECH_BOMB.radius * 0.55, 0, TAU, 40, Color(1, 0.4, 0.3, 0.55), 2.5)
			draw_circle(landing + Vector2(0, 4), sim.MECH_BOMB.radius * 0.55, Color(1, 0.3, 0.25, 0.08))
			draw_bomb(b); continue
		if kind == "p_heavy":
			draw_circle(bullet_pos, b.r * 1.15 + 6, Color(1, 0.6, 0.2, 0.25)); draw_circle(bullet_pos, b.r * 1.15, Color("2a2a30")); draw_circle(bullet_pos - Vector2(3, 3), b.r * 0.45, Color("ffcf7a"))
			draw_line(bullet_pos, bullet_pos - b.v.normalized() * 34, Color(0.7, 0.7, 0.75, 0.35), b.r)
			scenery.lights.append({"p": b.p, "kind": "bulb"}); continue
		if kind == "p_rocket":
			var tail: Vector2 = b.v.normalized()
			draw_line(bullet_pos - tail * 29, bullet_pos - tail * 7, Color("ff883e"), 9)
			draw_line(bullet_pos - tail * 21, bullet_pos - tail * 7, Color("ffe5a1"), 4)
			draw_circle(bullet_pos, 10, Color("222b29")); draw_circle(bullet_pos + tail * 3, 5, Color("74dce5"))
			continue
		var visual_radius: float = b.get("visual_r",b.r) * 1.15
		if b.get("arc", false):
			draw_arc(b.to, 62, 0, TAU, 36, Color("ffe281"), 3)
			bullet_pos -= Vector2(0, sin(clampf(b.get("age", 0.0) / b.flight, 0, 1) * PI) * 90)
		if b.team == 1:
			draw_circle(bullet_pos,visual_radius+2,Color("11101c"))
			draw_circle(bullet_pos,visual_radius,Color("f965ae"))
			draw_circle(bullet_pos,visual_radius*0.45,Color("fff4db"))
			continue
		if projectile_art.has(kind):
			var tex: Texture2D = projectile_art[kind]
			visual_transform(bullet_pos, b.v.angle() if kind != "orb" and kind != "magenta" and kind != "violet" else 0.0)
			draw_texture_rect(tex, Rect2(-tex.get_size()*0.8625,tex.get_size()*1.725),false)
			visual_transform(Vector2.ZERO)
			continue
		var c := CYAN if b.team == 0 else Color("fa6dbc")
		draw_line(bullet_pos - b.v.normalized() * 14, bullet_pos, Color(c, 0.55), b.r)
		draw_circle(bullet_pos, b.r + 3, Color("191126")); draw_circle(bullet_pos, b.r, c)
		draw_circle(bullet_pos - Vector2(1, 1), b.r * 0.4, Color("fff1d7"))
	for fx in sim.effects:
		if fx.kind == "recall_light":
			var alpha: float = clampf(fx.life / fx.max, 0.0, 1.0)
			var origin: Vector2 = fx.p - Vector2(0, 38)
			var destination: Vector2 = fx.to - Vector2(0, 32)
			draw_line(origin, destination, Color(0.2, 0.9, 1.0, alpha * 0.35), 16)
			draw_line(origin, destination, Color(0.9, 1.0, 1.0, alpha), 5)
			draw_circle(destination, 11 * alpha, Color(0.8, 1.0, 1.0, alpha * 0.7))
		elif fx.kind == "robot_summon" or fx.kind == "robot_recall": SummonFX.draw_auto(self, fx)
		elif fx.kind == "summon":
			draw_arc(fx.p, 70 * (1 - fx.life / 0.6), 0, TAU, 40, CYAN, 3)
			draw_line(fx.p, fx.p - Vector2(0, 140 * fx.life / 0.6), Color(0.3, 0.95, 1, fx.life), 12)
		elif fx.kind == "dash":
			draw_line(fx.p - fx.dir * 18 - Vector2(0, 20), fx.p - Vector2(0, 20), Color(0.3, 0.9, 1, fx.life * 1.5), 3)
		elif fx.kind == "slash":
			var t: float = clampf(1.0 - fx.life / 0.18, 0, 1)
			var frame := 0 if t < 0.3 else (1 if t < 0.7 else 2)
			visual_transform(fx.p - Vector2(0, 32), fx.dir.angle(), Vector2(0.85, 0.85) * fx.reach / 78.0)
			draw_texture_rect_region(weapon_art.sword_smear, Rect2(-56, -56, 112, 112), Rect2(frame * 112, 0, 112, 112), Color(1.0, 0.85, 0.55, 1.0 - t * 0.5))
			visual_transform(Vector2.ZERO)
		elif fx.kind == "corpse": pass  # desenhado antes dos vivos
		elif fx.kind == "casing":
			var t: float = 1.0 - fx.life / fx.max
			var cp: Vector2 = fx.p + fx.dir * t * 26 + Vector2(0, -30 - sin(t * PI) * 22 + t * 26)
			visual_transform(cp, t * 18.0)
			draw_rect(Rect2(-2, -1, 4, 2), Color("e0b050")); visual_transform(Vector2.ZERO)
		elif fx.kind == "impact":
			var t: float = 1.0 - fx.life / fx.max
			var c := Color(0.5, 1, 1, 1 - t) if fx.omega else Color(1, 0.75, 0.35, 1 - t)
			for n in range(6):
				var d := Vector2.RIGHT.rotated(n * TAU / 6 + fx.p.x)
				draw_line(fx.p - Vector2(0, 28) + d * (3 + t * 12), fx.p - Vector2(0, 28) + d * (6 + t * (22 if fx.omega else 14)), c, 2)
			if fx.omega: draw_circle(fx.p - Vector2(0, 28), 10 * (1 - t) + 3, Color(0.6, 1, 1, 0.4 * (1 - t)))
		elif fx.kind == "chest_burst": draw_chest_burst(fx)
		elif fx.kind == "dmg_num":
			# 0.15: número de dano flutuante (sobe, espalha em x e some)
			var t: float = 1.0 - fx.life / fx.max
			var np: Vector2 = fx.p - Vector2(0, 44 + t * 30) + Vector2(fx.get("vx", 0.0) * t, 0)
			var size := 15 if fx.get("heavy", false) else 12
			var col := Color("ffe08a") if fx.get("heavy", false) else Color("ffffff")
			col.a = clampf(fx.life / fx.max * 1.6, 0, 1)
			var txt := str(fx.get("value", 0))
			draw_string(ThemeDB.fallback_font, np + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_CENTER, 40, size, Color(0, 0, 0, col.a))
			draw_string(ThemeDB.fallback_font, np, txt, HORIZONTAL_ALIGNMENT_CENTER, 40, size, col)
		elif fx.kind == "clutch":
			var t: float = 1.0 - fx.life / fx.max
			draw_arc(fx.p, 30 + t * 60, 0, TAU, 24, Color(1, 0.25, 0.2, 0.7 * (1 - t)), 3)
		elif fx.kind == "stomp":
			var t: float = 1.0 - fx.life / fx.max
			for n in range(8):
				var d := Vector2.RIGHT.rotated(n * TAU / 8 + 0.4)
				draw_circle(fx.p + d * Vector2(1, 0.45) * (18 + t * 40), 7 * (1 - t) + 2, Color(0.62, 0.58, 0.5, 0.5 * (1 - t)))
		elif fx.kind == "thrust":
			var t: float = 1.0 - fx.life / fx.max
			draw_circle(fx.p + fx.dir * t * 30 - Vector2(0, 20), 10 * (1 - t) + 3, Color(0.7, 0.7, 0.75, 0.35 * (1 - t)))
		elif fx.kind == "sword":
			var owner: Dictionary = sim.actors[fx.get("owner", 0)]
			var t: float = 1.0 - fx.life / fx.max
			var frame := 0 if t < 0.3 else (1 if t < 0.7 else 2)
			var big := 1.4 if fx.combo == 2 else 1.05
			var flip_y := -1.0 if (fx.combo == 1) != (fx.dir.x < 0) else 1.0
			visual_transform(owner.p - Vector2(0, 38), fx.dir.angle(), Vector2(big, big * flip_y))
			draw_texture_rect_region(weapon_art.sword_smear, Rect2(-56, -56, 112, 112), Rect2(frame * 112, 0, 112, 112), Color(1, 1, 1, 1.0 - t * 0.5))
			visual_transform(Vector2.ZERO)
		elif fx.kind == "transform": draw_transform_fx(fx)
		elif fx.kind == "shockwave":
			var t: float = 1.0 - fx.life / fx.max
			visual_transform(fx.p, 0, Vector2(1, 0.5))
			for k in range(3):
				var r := t * (190 + k * 40)
				draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.55, 1, 1, (1 - t) * (0.9 - k * 0.25)), 6 - k * 1.5)
			visual_transform(Vector2.ZERO)
			for n in range(14):
				var d := Vector2.RIGHT.rotated(n * TAU / 14)
				draw_rect(Rect2(fx.p + d * t * 170 * Vector2(1, 0.5) - Vector2(2, 6 + sin(t * PI) * 26), Vector2(4, 4)), Color(0.75, 0.7, 0.6, 1 - t))
		elif fx.kind == "power_down":
			var t: float = 1.0 - fx.life / fx.max
			for n in range(10):
				var d := Vector2.RIGHT.rotated(n * TAU / 10)
				draw_circle(fx.p - Vector2(0, 40) + d * t * 40, 3 * (1 - t), Color(0.5, 1, 1, 1 - t))
		elif fx.kind == "weapon_drop":
			var k: float = 1.0 - fx.life / fx.max
			var tex: Texture2D = projectile_art.boss_harpoon
			visual_transform(fx.p + Vector2(k * 40, -40 + k * k * 120), k * 5.0)
			draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, fx.life / fx.max))
			visual_transform(Vector2.ZERO)
		elif fx.kind in ["explosion", "tentacle_strike", "gate_open", "gate_slam", "shield_hit", "spawn_portal", "prop_break", "splinter", "splash", "flash", "recoil"]: draw_fx_013(fx)
		else: draw_circle(fx.p, 8, GOLD)
	for a in sim.actors:
		if a.get("beam_time", 0.0) <= 0 or not a.armor: continue
		var origin: Vector2 = a.p - Vector2(0, 38)
		var destination: Vector2 = a.get("beam_end", a.p) - Vector2(0, 38)
		draw_line(origin, destination, Color(0.15, 0.8, 1.0, 0.32), 30)
		draw_line(origin, destination, Color(0.45, 0.95, 1.0, 0.8), 14)
		draw_line(origin, destination, Color.WHITE, 5)
		draw_circle(destination, 12, Color(0.8, 1.0, 1.0, 0.75))

func lamp(p: Vector2) -> void:
	for radius in [100, 75, 50, 30]: draw_circle(p, radius, Color(0.98, 0.57, 0.17, 0.025))
	for n in range(9):
		var width := 4 + (n * 17) % 19
		draw_rect(Rect2(p.x - width * 0.5, p.y + 26 + n * 7, width, 3), Color(1, 0.64, 0.24, 0.13 - n * 0.01))
	draw_texture_rect(dock_art.lamp, Rect2(p - Vector2(13, 34), Vector2(26, 42)), false)

func crate(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(5, 8), rect.size), Color(0, 0, 0, 0.3))
	draw_texture_rect(dock_art.crate, Rect2(rect.position - Vector2(0, 15), rect.size + Vector2(0, 15)), false)

func floor_contains(p: Vector2) -> bool:
	for floor_rect in sim.floors:
		if floor_rect.has_point(p): return true
	return false

func draw_quay_edges(rect: Rect2) -> void:
	# Edges are outside walkable geometry. Shared room/corridor edges stay open.
	for x in range(int(rect.position.x), int(rect.end.x), 32):
		var width := minf(32, rect.end.x - x)
		for side in [-1, 1]:
			var y: float = rect.position.y if side == -1 else rect.end.y
			if floor_contains(Vector2(x + width * 0.5, y + side * 2)): continue
			var height := 53.0 if side == -1 else 38.0
			var target := Rect2(x, y - height if side == -1 else y, width, height)
			draw_texture_rect_region(dock_art.wall, target, Rect2((x % 4) * 24, 0, width, 81))
			if side == 1 and x % 128 == 0:
				draw_rect(Rect2(x, y + 30, 14, 28), Color("242532")); draw_rect(Rect2(x, y + 29, 14, 5), Color("60616a"))
	for y in range(int(rect.position.y), int(rect.end.y), 32):
		for side in [-1, 1]:
			var x: float = rect.position.x if side == -1 else rect.end.x
			if floor_contains(Vector2(x + side * 2, y + 16)): continue
			var h := minf(32, rect.end.y - y)
			var target := Rect2(x - 24 if side == -1 else x, y, 24, h)
			draw_texture_rect_region(docks_art.wall_side, target, Rect2(0, fposmod(y, 64.0) if fposmod(y, 64.0) + h <= 64 else 0, 24, h))

func portal(p: Vector2, label: String, active: bool = true) -> void:
	var c := CYAN if active else Color("51475e")
	draw_circle(p, 47, Color(0.2, 0.7, 0.8, 0.06) if active else Color(0, 0, 0, 0.1))
	draw_arc(p, 32, 0, TAU, 32, c, 3)
	draw_arc(p, 23 + sin(sim.tick_time * 3) * 2, 0, TAU, 32, c, 2)
	for n in range(6):
		var q := p + Vector2.RIGHT.rotated(n * TAU / 6 + sim.tick_time * 0.3) * 39
		draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), c)
	text_at(p + Vector2(-65, 63), label, c, 14)

func draw_docks() -> void:
	var P: Dictionary = DocksMap.POINTS
	# Oficina: comerciante atrás do balcão
	var shop: Vector2 = P.shop
	draw_circle(shop - Vector2(0, 58), 12, Color("d2a077")); draw_rect(Rect2(shop - Vector2(16, 48), Vector2(32, 30)), Color("465860"))
	draw_rect(Rect2(shop - Vector2(18, 72), Vector2(36, 8)), Color("3a2a22"))
	text_at(shop + Vector2(-95, 44), "E • CHAVE + CURA / 15 moedas" if not sim.shop_bought else "ESTOQUE ESGOTADO", GOLD, 13)
	# Gerador do desafio opcional
	if not sim.side_complete: text_at(P.side + Vector2(-95, 46), "E • DESAFIO OPCIONAL / 55s" if not sim.side_active else "DEFENDA O GERADOR  %ds" % int(sim.side_time), GOLD, 14)
	# Parede rachada (sala secreta)
	if not sim.secret_open:
		draw_texture(docks_art.crack, P.secret_wall - Vector2(40, 60))
		text_at(P.secret_wall + Vector2(-60, 40), "Parede rachada...", Color("978989"), 12)
	for gap in sim.gaps:
		if minf(gap.size.x, gap.size.y) <= 120 and seen(gap.get_center(), gap.size.length()): text_at(Vector2(gap.position.x - 70, gap.end.y + 30), "CANAL • ESPAÇO PARA SALTAR", GOLD, 12)
	for ramp in sim.ramps: text_at(ramp.r.position + Vector2(10, ramp.r.size.y + 22), "RAMPA", Color("c9bfae"), 11)

func draw_capsule() -> void:
	# Cápsula de extração no estilo das câmaras de upgrade: selada até o chefe cair; depois acende.
	var P: Vector2 = DocksMap.POINTS.extraction
	var t: float = sim.tick_time
	var active: bool = sim.boss_dead
	var tex: Texture2D = docks_art.capsule
	var origin := P + Vector2(-75, 40 - 240)
	if active:
		for k in range(4): draw_circle(P - Vector2(0, 70), 90 + k * 26 + sin(t * 2 + k) * 6, Color(0.35, 0.9, 1, 0.05))
		draw_rect(Rect2(P.x - 30, P.y - 1400, 60, 1260), Color(0.5, 1, 1, 0.08 + 0.04 * sin(t * 3)))
	draw_texture(tex, origin, Color.WHITE if active else Color(0.62, 0.62, 0.7))
	var glass := Rect2(origin + Vector2(32, 62), Vector2(86, 128))
	if active:
		var pulse := 0.5 + 0.5 * sin(t * 4)
		draw_rect(glass, Color(0.45, 0.95, 1, 0.25 + 0.2 * pulse))
		draw_rect(Rect2(glass.position.x + 30, glass.position.y, 18, glass.size.y), Color(1, 1, 1, 0.35 + 0.3 * pulse))
		for n in range(10):
			var h := fposmod(t * 60 + n * 23, glass.size.y)
			draw_rect(Rect2(glass.position.x + 8 + (n * 17) % 60, glass.end.y - h, 3, 3), Color(0.8, 1, 1, 1 - h / glass.size.y))
		for k in range(3):
			var ry := fposmod(t * 40 + k * 45, 150.0)
			visual_transform(P - Vector2(0, 20 + ry), 0, Vector2(1, 0.3))
			draw_arc(Vector2.ZERO, 58, 0, TAU, 32, Color(0.5, 1, 1, 0.8 - ry / 190.0), 3)
			visual_transform(Vector2.ZERO)
		text_at(P + Vector2(-68, 70), "E • EXTRAÇÃO", CYAN, 16)
	else:
		draw_rect(glass, Color(0.05, 0.1, 0.15, 0.5))
		text_at(P + Vector2(-80, 70), "CÁPSULA SELADA • DERROTE O CHEFE", Color("8a8a9a"), 12)

func direction_row(aim: Vector2) -> int:
	if absf(aim.x) > absf(aim.y): return 1 if aim.x < 0 else 2
	return 3 if aim.y < 0 else 0

func enemy_octant(face: Vector2) -> int:
	if face.length_squared() < 0.01: return 0
	return posmod(roundi((PI * 0.5 - face.angle()) / (PI * 0.25)), 8)

# 0.19: três vistas de esquiva, espelhadas para cobrir as oito direções.
func marty_dash_view(direction: Vector2) -> String:
	if absf(direction.y) < absf(direction.x) * 0.45: return "side"
	return "front_diag" if direction.y >= 0 else "back_diag"

func draw_marty_dodge(a: Dictionary, pos: Vector2, outfit: String, tint: Color) -> void:
	var direction: Vector2 = a.dash_dir
	var view_key := marty_dash_view(direction)
	var frame := clampi(int((1.0 - a.get("roll_visual", a.dodge) / 0.36) * 4.0), 0, 3)
	var omega := outfit == "omega"
	var texture: Texture2D = marty_teleport[view_key] if omega else marty_roll[view_key]
	var row: int = (1 if view_key == "back_diag" else 0) if omega else OUTFIT_ROW[outfit]
	var mirror: bool = direction.x < -0.1 or (absf(direction.x) <= 0.1 and a.facing.x < 0)
	visual_transform(pos, 0, Vector2(-1 if mirror else 1, 1))
	draw_texture_rect_region(texture, Rect2(-48, -92, 96, 96), Rect2(frame * 96, row * 96, 96, 96), tint)
	visual_transform(Vector2.ZERO)

func draw_actor(a: Dictionary) -> void:
	var foot: Vector2 = a.p
	var player_color := CYAN if a.id == 0 else GOLD
	visual_transform(foot, 0, Vector2(1, 0.42)); draw_circle(Vector2.ZERO, 17, Color(0, 0, 0, 0.4)); visual_transform(Vector2.ZERO)
	draw_arc(foot, 16, 0, TAU, 20, player_color, 2)
	if a.dead:
		if a.fused and fusion_actions.has("defeat"):
			var defeat_texture: Texture2D = fusion_actions["defeat"]
			draw_character_action(defeat_texture, FUSION_ACTION_CELL, 128.0, foot, a.facing, maxi(0, int(defeat_texture.get_width() / FUSION_ACTION_CELL) - 1))
		elif sim.outfit_of(a) == "padrao":
			draw_marty_padrao_frame("defeat", a.facing, MARTY_PADRAO_FRAMES.defeat - 1, foot, Color.WHITE)
		elif sim.outfit_of(a) == "omega":
			draw_marty_omega_frame("defeat", a.facing, MARTY_OMEGA_FRAMES.defeat - 1, foot, Color.WHITE)
		else:
			draw_line(foot - Vector2(9, 9), foot + Vector2(9, 9), Color("f77c89"), 5)
			draw_line(foot + Vector2(9, -9), foot + Vector2(-9, 9), Color("f77c89"), 5)
		text_at(foot + Vector2(-35, -25), "E • REANIMAR", Color("f77c89"), 12)
		return
	var jump_height := sin((1.0 - a.jump / 0.65) * PI) * 68 if a.jump > 0 else 0.0
	var elevation := sim.height_at(foot)
	var draw_pos := foot - Vector2(0, jump_height + elevation)
	if a.fused:
		var col := 3 if a.slash > 0 or a.get("fire_flash", 0.0) > 0 else (1 + int(a.step) % 2 if a.move.length() > 0.1 else 0)
		var tint := Color(1.5, 1.5, 1.5, 0.65) if a.hurt > 0 else Color.WHITE
		var fusion_action := fusion_sprite_action(a)
		if fusion_actions.has(fusion_action):
			var direction: Vector2 = a.dash_dir if fusion_action == "evade" else (a.move if fusion_action == "run" else fusion_visual_direction(a))
			var frame := character_action_frame(fusion_actions[fusion_action], FUSION_ACTION_CELL, fusion_action, a)
			draw_character_action(fusion_actions[fusion_action], FUSION_ACTION_CELL, 128.0, draw_pos, direction, frame, tint)
		else:
			draw_feral(fusion_texture, draw_pos, fusion_visual_direction(a), col, 160, 144, tint)
		text_at(draw_pos + Vector2(-36, -115), "MARTY • FUSÃO", CYAN, 11)
		return
	# Roupa atual: COM armadura = Ômega; SEM armadura = Padrão / Londres / Mecânico.
	# marty_anim.png: linha = roupa*5 + vista; colunas = parado, passo 1-4, tiro, salto.
	var pose := marty_pose(a.facing)
	var view: int = pose[0]; var flip: bool = pose[1]
	var outfit_key: String = sim.outfit_of(a)
	var transforming: float = a.get("transform", 0.0)
	var charge_t: float = sim.TRANSFORM_TIME - transforming
	if transforming > 0:
		outfit_key = a.get("outfit", "padrao")  # a armadura nova entra como camada progressiva sobre a roupa
	var row: int = OUTFIT_ROW[outfit_key] * 5 + view
	var walking: bool = a.move.length() > 0.1
	var firing: bool = a.get("fire_flash", 0.0) > 0
	var column := 0; var bob := 0.0
	var slash_dur := 0.32 if a.armor else 0.45
	if a.slash > 0 and not a.mech:
		var sp: float = 1.0 - a.slash / slash_dur
		column = 7 if sp < 0.2 else (8 if sp < 0.6 else 9)
	elif a.jump > 0 or a.dodge > 0:
		column = 6
		if a.dodge > 0 and view != 2: row = OUTFIT_ROW[sim.outfit_of(a)] * 5 + 2; flip = a.dash_dir.x < 0
	elif walking:
		var phase := int(a.step) % 4
		column = 1 + phase
		bob = -2.0 if phase % 2 == 0 else 0.0
	elif firing: column = 5
	else: bob = -1.0 if fmod(sim.tick_time + a.id * 0.7, 1.6) < 0.8 else 0.0  # respiração
	var tint := Color.WHITE
	if a.get("roll_visual", a.dodge) <= 0 and a.hurt > 0 and int(a.hurt * 20) % 2 == 0: tint.a = 0.45
	if a.slash > 0.24: tint = tint.lightened(0.25)
	if transforming > 0:
		bob -= sin(clampf(charge_t / 0.8, 0, 1) * PI) * 8.0   # flutua enquanto carrega
		tint = Color(1.4, 1.4, 1.25) if charge_t < 0.75 else Color.WHITE
		draw_power_aura(draw_pos, clampf(1.0 - absf(charge_t - 0.6) / 0.8, 0.25, 1.0), true)
	elif a.armor and not a.mech:
		draw_power_aura(draw_pos, 0.28, false)
	if outfit_key == "padrao":
		var padrao_action := marty_padrao_action(a, walking, firing)
		var padrao_direction: Vector2 = a.dash_dir if padrao_action == "evade" else (a.move if padrao_action == "run" else a.facing)
		var padrao_frame := marty_padrao_frame(a, padrao_action, slash_dur)
		draw_marty_padrao_frame(padrao_action, padrao_direction, padrao_frame, draw_pos + Vector2(0, bob), tint)
		# A arma aparece somente enquanto Marty dispara.
		if marty_padrao_shows_weapon(padrao_action, transforming): draw_weapon(a, draw_pos)
	elif outfit_key == "omega":
		var omega_action := marty_omega_action(a, walking)
		var omega_direction: Vector2 = a.dash_dir if omega_action == "evade" else (a.move if omega_action == "run" else a.facing)
		var omega_frame := marty_omega_frame(a, omega_action, slash_dur)
		draw_marty_omega_frame(omega_action, omega_direction, omega_frame, draw_pos + Vector2(0, bob), tint)
		# A espada materializa apenas durante o combo; repouso e movimento ficam livres.
		if omega_action == "melee": draw_weapon(a, draw_pos)
	elif a.get("roll_visual", a.dodge) > 0 and not a.mech:
		draw_marty_dodge(a, draw_pos + Vector2(0, bob), outfit_key, tint)
	else:
		visual_transform(draw_pos + Vector2(0, bob), 0, Vector2(-1 if flip else 1, 1))
		draw_texture_rect_region(marty_anim, Rect2(-48, -92, 96, 96), Rect2(column * 96, row * 96, 96, 96), tint)
		visual_transform(Vector2.ZERO)
		# A arma é uma camada separada; durante a esquiva as mãos ficam livres.
		draw_weapon(a, draw_pos)
	if transforming > 0:
		draw_omega_assembly_overlay(draw_pos + Vector2(0, bob), 1.0 - transforming / sim.TRANSFORM_TIME)
	if a.jump > 0 and a.armor: draw_circle(draw_pos + Vector2(0, -13), 5, CYAN)
	if a.get("shield", 0.0) > 0: draw_shield_hex(draw_pos - Vector2(0, 40), a.shield / (sim.OMEGA_SHIELD_HEARTS * sim.HEART))
	if a.fused: text_at(draw_pos + Vector2(-30, 24), "FUSÃO • G", CYAN, 12)
	text_at(draw_pos + Vector2(-25, -112 if a.armor else -86), "MARTY" if a.id == 0 else ("ECHO • IA" if sim.coop == "ai" else "ECHO • P2"), player_color, 11)

func draw_mech(m: Dictionary) -> void:
	var p: Vector2 = m.p
	visual_transform(p, 0, Vector2(1, 0.45)); draw_circle(Vector2.ZERO, 43, Color(0, 0, 0, 0.5)); visual_transform(Vector2.ZERO)
	if m.hp <= 0:
		crate(Rect2(p - Vector2(40, 25), Vector2(80, 30))); text_at(p + Vector2(-40, -35), "INUTILIZADO", Color("b78c84"), 12); return
	# Titan v2: 8 direções (5 vistas + espelho), viseira acesa quando pilotado, passada pesada.
	if m.get("cockpit_t", 0.0) > 0:
		draw_cockpit(m); return
	var facing: Vector2 = titan_visual_direction(m)
	var pose := titan_pose(facing)
	var piloted: bool = m.occupant >= 0
	var column := 0; var bob := 0.0; var squash := 1.0
	var pilot: Dictionary = sim.actors[m.occupant] if piloted else {}
	var attacking: bool = piloted and (pilot.get("fire_flash", 0.0) > 0 or pilot.get("slash", 0.0) > 0)
	# 0.18: disparar não interrompe o ciclo dos pés.
	if piloted and m.get("moving", false):
		var phase := int(m.step) % 4
		column = 1 + phase
		# peso: afunda e achata quando o pé bate (quadros 1 e 3)
		var sub: float = fposmod(m.step, 1.0)
		if phase % 2 == 1: bob = 5.0 * (1.0 - sub); squash = 1.0 - 0.05 * (1.0 - sub)
		else: bob = -2.0 * sin(sub * PI)
	elif not piloted: bob = 0.0
	else:
		column = 0
		bob = sin(sim.tick_time * 2.0) * 1.0  # motor ligado
	var base: Vector2 = p - Vector2(0, sim.height_at(p) - bob)
	if m.get("boosting", false):
		var back := -facing.normalized()
		for k in range(3):
			var jet := base + Vector2(0, -60) + back * (40 + k * 10) + Vector2(sin(sim.tick_time * 50 + k) * 3, 0)
			draw_circle(jet, 14 - k * 3, Color(0.4, 0.9, 1, 0.45 - k * 0.1))
	visual_transform(base, 0, Vector2(-1.0 if pose[1] else 1.0, squash))
	# O atlas limpo mantém uma margem transparente entre todas as poses.
	draw_texture_rect_region(titan_v2, Rect2(-88, -164, 176, 176), Rect2(column * 176, pose[0] * 176, 176, 176))
	visual_transform(Vector2.ZERO)
	if not piloted: text_at(p + Vector2(-50, 27), "E • PILOTAR TITAN", CYAN, 13)
	else:
		draw_rect(Rect2(p + Vector2(-35, 16), Vector2(70, 3)), Color("161824"))
		draw_rect(Rect2(p + Vector2(-35, 16), Vector2(70 * pilot.get("boost", 1.0), 3)), Color(1, 0.8, 0.35))
	draw_rect(Rect2(p + Vector2(-35, 10), Vector2(70, 4)), Color("161824"))
	draw_rect(Rect2(p + Vector2(-35, 10), Vector2(70 * m.hp / 240, 4)), CYAN)

func draw_cockpit(m: Dictionary) -> void:
	var progress: float = clampf(1.0 - m.cockpit_t / 1.2, 0, 1)
	var frame := 0
	if progress < 0.25: frame = mini(3, int(progress / 0.25 * 4))
	elif progress < 0.75: frame = 3
	else: frame = maxi(0, 3 - int((progress - 0.75) / 0.25 * 4))
	var base: Vector2 = m.p - Vector2(0, sim.height_at(m.p))
	draw_texture_rect_region(cockpit_texture, Rect2(base + Vector2(-88,-164),Vector2(176,176)),Rect2(frame*176,0,176,176))
	var actor: Dictionary = sim.actors[m.cockpit_actor]
	if actor.dead: return
	var travel := smoothstep(0.25, 0.75, progress)
	var inside := travel if m.cockpit_entering else 1.0 - travel
	if inside >= 0.98: return
	var position: Vector2 = (m.cockpit_outside - Vector2(0, sim.height_at(m.cockpit_outside))).lerp(base + Vector2(0,-48),inside)
	var size := lerpf(96.0, 42.0, inside)
	var row: int = OUTFIT_ROW[sim.outfit_of(actor)] * 5 + (4 if m.cockpit_entering else 0)
	draw_texture_rect_region(marty_anim,Rect2(position-Vector2(size*0.5,size*92.0/96.0),Vector2.ONE*size),Rect2(0,row*96,96,96),Color(1,1,1,1.0-inside*0.8))

func draw_spectre(s: Dictionary) -> void:
	var p: Vector2 = s.p
	draw_arc(p, 17, 0, TAU, 18, Color(0.3, 0.9, 1, 0.6), 2)
	var col := 3 if s.shot > 0.38 else (1 + int(s.get("step", 0.0)) % 2 if s.get("moving", false) else 0)
	var action := "shoot" if s.shot > 0.38 else ("run" if s.get("moving", false) else "idle")
	var draw_pos := p - Vector2(0, sim.height_at(p))
	if spectre_actions.has(action):
		var texture: Texture2D = spectre_actions[action]
		var count := maxi(1, texture.get_width() / SPECTRE_ACTION_CELL)
		var frame := int(s.get("step", 0.0)) % count if action == "run" else (int(sim.tick_time * 4.0) % count if action == "idle" else clampi(int((sim.SPECTRE_SHOT.cooldown - s.shot) / 0.17 * count), 0, count - 1))
		draw_character_action(texture, SPECTRE_ACTION_CELL, 112.0, draw_pos, spectre_visual_direction(s), frame)
	else:
		draw_feral(spectre_texture, draw_pos, spectre_visual_direction(s), col, 128, 112)
	draw_rect(Rect2(p + Vector2(-20, 8), Vector2(40, 3)), Color("1a3541"))
	draw_rect(Rect2(p + Vector2(-20, 8), Vector2(40 * s.hp / 100, 3)), CYAN)
	text_at(p + Vector2(-30, -112), "SPECTRE", CYAN, 10)

func feral_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y): return 1 if direction.x < 0 else 2
	return 3 if direction.y < 0 else 0

func fusion_visual_direction(a: Dictionary) -> Vector2:
	# Como no atlas básico do Marty: os pés comandam a vista durante a caminhada;
	# ao atacar, a silhueta volta a acompanhar a mira.
	if a.get("slash", 0.0) <= 0 and a.get("fire_flash", 0.0) <= 0:
		var movement: Vector2 = a.get("move", Vector2.ZERO)
		if movement.length() > 0.1: return movement.normalized()
	return a.get("aim", a.get("facing", Vector2.DOWN)).normalized()

func spectre_visual_direction(s: Dictionary) -> Vector2:
	if s.get("moving", false) and s.get("shot", 0.0) <= 0:
		return s.get("move_dir", s.get("aim", Vector2.DOWN)).normalized()
	return s.get("aim", Vector2.DOWN).normalized()

func titan_visual_direction(m: Dictionary) -> Vector2:
	var piloted: bool = m.get("occupant", -1) >= 0
	if piloted:
		var pilot: Dictionary = sim.actors[m.occupant]
		if pilot.get("fire_flash", 0.0) > 0 or pilot.get("slash", 0.0) > 0:
			return m.get("aim", Vector2.DOWN).normalized()
	if m.get("moving", false): return m.get("move_dir", m.get("facing", Vector2.DOWN)).normalized()
	return m.get("aim", m.get("facing", Vector2.DOWN)).normalized()

func draw_feral(tex: Texture2D, foot: Vector2, direction: Vector2, col: int, cell: int, size: float, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(tex, Rect2(foot - Vector2(size * 0.5, size * (1.0 - 6.0 / cell)), Vector2.ONE * size), Rect2(col * cell, feral_row(direction) * cell, cell, cell), tint)

func draw_warden(e: Dictionary) -> void:
	var p: Vector2 = e.p
	var state: String = e.get("attack_state", "hunt")
	if state in ["warning", "charge"]:
		var dir: Vector2 = e.get("charge_dir", e.face)
		var endpoint := p
		for distance in range(10, 350, 10):
			var next := p + dir * distance
			if not sim.clear_at(next, 48): break
			endpoint = next
		draw_line(p, endpoint, Color(1, 0.15, 0.12, 0.2), 96)
		draw_line(p, endpoint, Color(1, 0.65, 0.2, 0.9), 3)
		text_at(p + Vector2(-62, 34), "INVESTIDA!" if state == "charge" else "! PREPARE O DASH !", Color("ffb451"), 13)
	visual_transform(p, 0, Vector2(1, 0.42)); draw_circle(Vector2.ZERO, 50, Color(0, 0, 0, 0.5)); visual_transform(Vector2.ZERO)
	var col := 3 if state == "charge" else (1 + int(e.step) % 2 if e.moving else 0)
	var tint := Color(1.7, 1.5, 1.5) if e.hurt > 0 else (Color(1.3, 0.8, 0.8) if state == "warning" else Color.WHITE)
	draw_feral(warden_texture, p, e.face, col, 256, 288, tint)
	draw_rect(Rect2(p + Vector2(-65, -285), Vector2(130, 6)), Color("201824"))
	draw_rect(Rect2(p + Vector2(-65, -285), Vector2(130 * e.hp / e.max, 6)), Color("dc547b"))
	text_at(p + Vector2(-72, -293), "CÃO DE GUERRA", Color("ffb451"), 15)

func weapon_hand_anchor(a: Dictionary) -> Vector2:
	return sim.weapon_hand_anchor(a)

func marty_uses_legacy_weapon_hand(a: Dictionary) -> bool:
	return sim.outfit_of(a) not in ["padrao", "omega"]

func draw_weapon_hand(a: Dictionary, wrist: Vector2, _grip: Vector2) -> void:
	# 0.18: dedos da própria arte cobrem a empunhadura, sem braços geométricos.
	# Padrao e Omega possuem maos completas; nao colar recortes do atlas antigo.
	if not marty_uses_legacy_weapon_hand(a): return
	var pose := marty_pose(a.facing)
	var row: int = OUTFIT_ROW[sim.outfit_of(a)] * 5 + int(pose[0])
	var anchor := weapon_hand_anchor(a)
	if pose[1]: anchor.x = -anchor.x
	var patch := Rect2(anchor + Vector2(48, 92) - Vector2(4, 4), Vector2(8, 8))
	visual_transform(wrist, 0, Vector2(-1 if pose[1] else 1, 1))
	draw_texture_rect_region(marty_anim, Rect2(-4, -4, 8, 8), Rect2(patch.position + Vector2(0, row * 96), patch.size))
	visual_transform(Vector2.ZERO)

func draw_weapon(a: Dictionary, base: Vector2, body_direction: Vector2 = Vector2.ZERO) -> void:
	# Arma e cano compartilham a mira (360°) e o espelhamento com a simulação,
	# e o clarão passa por 3 estágios (estrela → brilho → fumaça).
	var weapon: String = sim.weapon_of(a)
	var aim: Vector2 = a.aim.normalized()
	if weapon == "omega_sword": draw_blade(a, base, weapon_art.omega_sword, 0.32, true); return
	if a.slash > 0:
		# golpe corpo a corpo do uniforme: chave inglesa (Mecânico), faca (Espião) ou coronhada (Padrão)
		var tool: Texture2D = {"mecanico": weapon_art.wrench, "espiao": weapon_art.knife}.get(a.outfit, weapon_art[weapon])
		draw_blade(a, base, tool, 0.45, false); return
	var tex: Texture2D = weapon_art[weapon]
	var k: float = clampf(a.get("fire_flash", 0.0) / 0.09, 0, 1)
	var geometry: Dictionary = sim.weapon_geometry(a, body_direction)
	var mirrored: bool = geometry.mirror < 0
	var angle: float = geometry.angle
	var wrist: Vector2 = base + geometry.hand
	var grip: Vector2 = wrist
	var handle: Vector2 = geometry.handle
	visual_transform(grip, angle, Vector2(1, -1 if mirrored else 1))
	draw_texture(tex, -handle)
	visual_transform(Vector2.ZERO)
	draw_weapon_hand(a, wrist, grip)
	if k <= 0: return
	var dir := Vector2.RIGHT.rotated(angle)
	var muzzle: Vector2 = geometry.muzzle
	var cyan: bool = weapon in ["pistol", "omega"]
	var fx: Texture2D = weapon_art.flash_cyan if cyan else weapon_art.flash
	var big: float = {"pistol": 1.1, "shotgun": 1.9, "smg": 1.0, "bazooka": 2.2, "omega": 2.2}[weapon]
	if k > 0.55:
		visual_transform(muzzle + dir * 6 * big, angle, Vector2(1.6, 1.0) * big)
		draw_texture(fx, -fx.get_size() * 0.5)
		visual_transform(Vector2.ZERO)
		draw_circle(muzzle, 10 * big, Color(1, 0.95, 0.7, 0.25) if not cyan else Color(0.6, 1, 1, 0.3))
	elif k > 0.2:
		draw_circle(muzzle + dir * 4, 5 * big, Color(1, 0.9, 0.6, 0.55) if not cyan else Color(0.6, 1, 1, 0.55))
	else:
		draw_circle(muzzle + dir * 6 + Vector2(0, -4), 5 * big, Color(0.7, 0.7, 0.75, 0.35))
	if weapon == "omega" and k > 0.4:
		draw_arc(muzzle, 14 * (1.4 - k), 0, TAU, 20, Color(0.5, 1, 1, k), 2)

func swing_angle(a: Dictionary, duration: float) -> float:
	# Varredura do golpe: começa atrás, corta pela frente e termina do outro lado (alterna a cada golpe).
	var aim: Vector2 = a.aim.normalized()
	var p: float = clampf(1.0 - a.slash / duration, 0, 1)
	var e := 1.0 - pow(1.0 - p, 3)
	var combo: int = a.get("swing", 0)
	var width := 2.1 if combo == 2 else 1.5
	var dir := -1.0 if combo == 1 else 1.0
	if aim.x < 0: dir = -dir
	return aim.angle() + dir * lerpf(-width, width, e)

func draw_blade(a: Dictionary, base: Vector2, tex: Texture2D, duration: float, energy: bool) -> void:
	var aim: Vector2 = a.aim.normalized()
	var mirrored: bool = aim.x < 0
	var angle: float
	if a.slash > 0: angle = swing_angle(a, duration)
	else: angle = aim.angle() + (-1.0 if mirrored else 1.0) * 1.05  # em guarda, lâmina baixa à frente
	var wrist := base + weapon_hand_anchor(a)
	var grip: Vector2 = wrist
	var size := tex.get_size()
	if energy:
		var pulse := 0.5 + 0.5 * sin(sim.tick_time * 8)
		var tip := grip + Vector2.RIGHT.rotated(angle) * size.x
		draw_line(grip, tip, Color(0.4, 0.95, 1, 0.18 + 0.1 * pulse), 12)
	visual_transform(grip, angle, Vector2(1, -1 if mirrored else 1))
	draw_texture(tex, Vector2(-6, -size.y * 0.5))
	visual_transform(Vector2.ZERO)
	draw_weapon_hand(a, wrist, grip)

func draw_chest(chest: Dictionary) -> void:
	if chest.get("reward",false):
		draw_circle(chest.p,44,Color(1,0.75,0.15,0.18))
		draw_arc(chest.p,34,0,TAU,32,GOLD,3)
		text_at(chest.p+Vector2(-65,-70),"ARSENAL • SEM CHAVE" if not chest.open else "RECUPERADO",GOLD,12)
	# 0.15: baú da folha docks12 (fechado / aberto) com tremida e brilho ao abrir
	if scenery and scenery.props.has("chest"):
		draw_chest_hd(chest); return
	var p: Vector2 = chest.p
	var tex: Texture2D = dock_art.chest
	var ts := tex.get_size()
	var lid_h := ts.y * 0.44
	var scale := Vector2(58.0 / ts.x, 60.0 / ts.y)
	var origin := p - Vector2(29, 50)
	if not chest.open:
		var glint := fposmod(sim.tick_time * 0.7 + p.x * 0.01, 3.0)
		draw_texture_rect(tex, Rect2(origin, Vector2(58, 60)), false)
		if glint < 0.25: draw_circle(origin + Vector2(10 + glint * 150, 12), 3, Color(1, 1, 0.85, 0.7))
		return
	var t: float = sim.tick_time - chest.get("t", -99.0)
	var shake := Vector2(sin(t * 90) * 2.5, 0) if t < 0.22 else Vector2.ZERO
	var open_k := clampf((t - 0.22) / 0.25, 0, 1)
	open_k = 1.0 - pow(1.0 - open_k, 3)  # ease-out
	# base
	draw_texture_rect_region(tex, Rect2(origin + shake + Vector2(0, lid_h * scale.y), Vector2(58, (ts.y - lid_h) * scale.y)), Rect2(0, lid_h, ts.x, ts.y - lid_h))
	# interior brilhando
	if open_k > 0:
		var inner := Rect2(origin + Vector2(8, lid_h * scale.y - 4), Vector2(42, 10))
		draw_rect(inner, Color("1a1020"))
		var glow := (0.6 + 0.4 * sin(sim.tick_time * 5)) if t > 1.2 else 1.0
		draw_rect(inner.grow(-2), Color(1, 0.8, 0.35, 0.8 * glow * open_k))
	# tampa: sobe, inclina para trás e escurece
	var lid_pos := origin + shake - Vector2(0, 16 * open_k)
	var lid_scale := 1.0 - 0.55 * open_k
	draw_texture_rect_region(tex, Rect2(lid_pos + Vector2(0, lid_h * scale.y * (1 - lid_scale)), Vector2(58, lid_h * scale.y * lid_scale)), Rect2(0, 0, ts.x, lid_h), Color(1, 1, 1, 1).darkened(0.35 * open_k))

func marty_pose(f: Vector2) -> Array:
	# 8 direções com 5 vistas: frente, frente-3/4, lado, costas-3/4, costas (espelhadas para a esquerda).
	var octant := int(round(fposmod(f.angle(), TAU) / (TAU / 8))) % 8
	match octant:
		0: return [2, false]   # direita
		1: return [1, false]   # baixo-direita
		2: return [0, false]   # baixo
		3: return [1, true]    # baixo-esquerda
		4: return [2, true]    # esquerda
		5: return [3, true]    # cima-esquerda
		6: return [4, false]   # cima
		_: return [3, false]   # cima-direita

func marty_direction_row(direction: Vector2) -> int:
	# Ordem do export PixelLab: sul, sudeste, leste, nordeste, norte,
	# noroeste, oeste, sudoeste.
	var f := direction.normalized() if direction.length() > 0.01 else Vector2.DOWN
	var octant := int(round(fposmod(f.angle(), TAU) / (TAU / 8))) % 8
	return [2, 1, 0, 7, 6, 5, 4, 3][octant]

func marty_padrao_action(a: Dictionary, walking: bool, firing: bool) -> String:
	if a.get("roll_visual", a.dodge) > 0: return "evade"
	if a.slash > 0 and not a.mech: return "melee"
	if a.jump > 0: return "jump"
	if a.hurt > 0: return "hurt"
	if firing: return "shoot"
	if walking: return "run"
	return "idle"

func marty_padrao_shows_weapon(action: String, transforming: float = 0.0) -> bool:
	# Durante a transformação, o visual pisca entre Padrão e Ômega; ocultar a
	# camada evita misturar o corpo de uma roupa com a arma da outra.
	return action == "shoot" and transforming <= 0.0

func marty_padrao_frame(a: Dictionary, action: String, slash_dur: float) -> int:
	var count: int = MARTY_PADRAO_FRAMES[action]
	match action:
		"evade": return clampi(int((1.0 - a.get("roll_visual", a.dodge) / 0.36) * count), 0, count - 1)
		"melee": return clampi(int((1.0 - a.slash / slash_dur) * count), 0, count - 1)
		"jump": return clampi(int((1.0 - a.jump / 0.65) * count), 0, count - 1)
		"shoot": return clampi(int((1.0 - a.get("fire_flash", 0.0) / 0.09) * count), 0, count - 1)
		"run": return int(a.step) % count
		"hurt": return int(sim.tick_time * 14.0) % count
		_: return int(sim.tick_time * 4.0 + a.id) % count

func draw_marty_padrao_frame(action: String, direction: Vector2, frame: int, foot: Vector2, tint: Color) -> void:
	var texture: Texture2D = marty_padrao_actions[action]
	var row := marty_direction_row(direction)
	draw_texture_rect_region(texture, Rect2(foot - Vector2(48, 94), Vector2(96, 96)), Rect2(frame * 96, row * 96, 96, 96), tint)

func fusion_sprite_action(a: Dictionary) -> String:
	if a.get("roll_visual", a.dodge) > 0: return "evade"
	if a.slash > 0: return "melee"
	if a.jump > 0: return "jump"
	if a.hurt > 0: return "hurt"
	if a.get("fire_flash", 0.0) > 0: return "shoot"
	if a.move.length() > 0.1: return "run"
	return "idle"

func character_action_frame(texture: Texture2D, cell: int, action: String, a: Dictionary) -> int:
	var count := maxi(1, int(texture.get_width() / cell))
	match action:
		"evade": return clampi(int((1.0 - a.get("roll_visual", a.dodge) / 0.36) * count), 0, count - 1)
		"melee": return clampi(int((1.0 - a.slash / 0.32) * count), 0, count - 1)
		"jump": return clampi(int((1.0 - a.jump / 0.65) * count), 0, count - 1)
		"shoot": return clampi(int((1.0 - a.get("fire_flash", 0.0) / 0.09) * count), 0, count - 1)
		"run": return int(a.step) % count
		"hurt": return int(sim.tick_time * 14.0) % count
		_: return int(sim.tick_time * 4.0 + a.id) % count

func draw_character_action(texture: Texture2D, cell: int, size: float, foot: Vector2,
		direction: Vector2, frame: int, tint: Color = Color.WHITE) -> void:
	var row := marty_direction_row(direction)
	var draw_size := Vector2.ONE * size
	var top_left := foot - Vector2(size * 0.5, size * (1.0 - 6.0 / cell))
	draw_texture_rect_region(texture, Rect2(top_left, draw_size), Rect2(frame * cell, row * cell, cell, cell), tint)

func marty_omega_action(a: Dictionary, walking: bool) -> String:
	if a.get("roll_visual", a.dodge) > 0: return "evade"
	if a.slash > 0 and not a.mech: return "melee"
	if a.jump > 0: return "jump"
	if a.hurt > 0: return "hurt"
	if walking: return "run"
	return "idle"

func marty_omega_frame(a: Dictionary, action: String, slash_dur: float) -> int:
	var count: int = MARTY_OMEGA_FRAMES[action]
	match action:
		"evade": return clampi(int((1.0 - a.get("roll_visual", a.dodge) / 0.36) * count), 0, count - 1)
		"melee": return clampi(int((1.0 - a.slash / slash_dur) * count), 0, count - 1)
		"jump": return clampi(int((1.0 - a.jump / 0.65) * count), 0, count - 1)
		"run": return int(a.step) % count
		"hurt": return int(sim.tick_time * 14.0) % count
		_: return int(sim.tick_time * 4.0 + a.id) % count

func draw_marty_omega_frame(action: String, direction: Vector2, frame: int, foot: Vector2, tint: Color) -> void:
	var texture: Texture2D = marty_omega_actions[action]
	var row := marty_direction_row(direction)
	var draw_size := Vector2.ONE * MARTY_OMEGA_DRAW_SIZE
	var top_left := foot - Vector2(draw_size.x * 0.5, draw_size.y - 2.0)
	draw_texture_rect_region(texture, Rect2(top_left, draw_size), Rect2(frame * MARTY_OMEGA_CELL, row * MARTY_OMEGA_CELL, MARTY_OMEGA_CELL, MARTY_OMEGA_CELL), tint)

func draw_guard_shield_icon(p: Vector2, broken: bool) -> void:
	# 0.20: estado do escudo sem texto, legível mesmo com vários inimigos na sala.
	visual_transform(p)
	draw_circle(Vector2.ZERO, 16, Color("101b25"))
	if broken:
		var edge := Color("ffd092")
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -10), Vector2(-2, -12), Vector2(-3, -3), Vector2(0, 1), Vector2(-2, 10), Vector2(-8, 5)]), Color("a7553e"))
		draw_colored_polygon(PackedVector2Array([Vector2(2, -12), Vector2(10, -10), Vector2(8, 5), Vector2(3, 10), Vector2(1, 3), Vector2(4, -2)]), Color("df7c4a"))
		draw_polyline(PackedVector2Array([Vector2(-10, -10), Vector2(-2, -12), Vector2(-3, -3), Vector2(0, 1), Vector2(-2, 10), Vector2(-8, 5), Vector2(-10, -10)]), edge, 2)
		draw_polyline(PackedVector2Array([Vector2(2, -12), Vector2(10, -10), Vector2(8, 5), Vector2(3, 10), Vector2(1, 3), Vector2(4, -2), Vector2(2, -12)]), edge, 2)
	else:
		var outline := PackedVector2Array([Vector2(0, -12), Vector2(10, -9), Vector2(9, 4), Vector2(0, 11), Vector2(-9, 4), Vector2(-10, -9), Vector2(0, -12)])
		draw_colored_polygon(outline, Color("348b9b"))
		draw_polyline(outline, Color("b8f6fa"), 2)
		draw_line(Vector2(0, -8), Vector2(0, 6), Color("d5ffff"), 2)
	visual_transform(Vector2.ZERO)

func enemy_art_kind(kind: String) -> String:
	return "crawler" if kind == "crawler_small" else kind

func enemy_art_scale(kind: String, crouched: bool = false) -> Vector2:
	var size_scale := 0.6 if kind == "crawler_small" else 1.0
	return Vector2(size_scale, size_scale * (0.78 if crouched else 1.0))

func enemy_action_scale(kind: String) -> float:
	return 0.6 if kind == "crawler_small" else 1.0

func draw_enemy(e: Dictionary) -> void:
	var p: Vector2 = e.p
	if e.kind == "warden": draw_warden(e); return
	if e.kind == "boss": draw_boss(e); return
	var small: bool = e.kind == "crawler_small"
	p -= Vector2(0, e.get("jump_height", 0.0))
	if e.get("elite", "") != "":
		var elite_color: Color = {"shield": Color("6cddff"), "trail": Color("a4ec63"), "explosive": Color("ff9169")}[e.elite]
		draw_arc(p, 25, 0, TAU, 24, elite_color, 3)
		text_at(p + Vector2(-30, -108), {"shield": "ESCUDO", "trail": "RASTRO", "explosive": "BOMBA"}[e.elite], elite_color, 10)
	var scale := 0.6 if small else 1.0
	visual_transform(p, 0, Vector2(1, 0.42)); draw_circle(Vector2.ZERO, 16 * scale, Color(0, 0, 0, 0.35)); visual_transform(Vector2.ZERO)
	var face: Vector2 = e.get("face", Vector2.DOWN)
	var column := 0; var flip := false; var bob := 0.0
	if e.get("shot", 0.0) > 0: column = 6; flip = face.x < 0
	elif e.get("moving", false):
		var phase := int(e.get("step", 0.0)) % 4
		column = 2 + phase; flip = face.x < 0
		bob = -1.0 if phase % 2 == 0 else 0.0
	elif face.y < -0.6: column = 1
	var tint := Color(1.6, 1.6, 1.6) if e.hurt > 0 else Color.WHITE
	visual_transform(p + Vector2(0, bob), 0, Vector2(-scale if flip else scale, scale * (0.78 if e.get("crouched", false) else 1.0)))
	var art_kind := enemy_art_kind(e.kind)
	if pixellab_enemy_art.has(art_kind):
		var new_art: Texture2D = pixellab_enemy_art[art_kind]
		var octant := enemy_octant(face)
		var frame := 1 + int(e.step) % 4 if e.moving else 0
		var size: float = PIXELLAB_ENEMY_SIZE[art_kind]
		# Let the walking pose settle briefly before the windup. Swapping atlases
		# the instant movement stops reads as a dodge instead of an attack.
		var windup_started: bool = e.combat == "warning" and e.combat_t <= (0.65 if art_kind == "guard" else 0.36)
		var attacking: bool = e.combat == "attack" or windup_started
		if e.combat == "warning" and e.kind == "bomber" and int(sim.tick_time * 12) % 2 == 0:
			tint = Color(1.5, 0.8, 0.55)
		if attacking and pixellab_enemy_actions.has(art_kind):
			var action_frame := 0
			if e.combat == "attack":
				action_frame = 1 if e.shot > 0.11 else (0 if e.shot <= 0 and art_kind in ["guard", "brute"] else 2)
			visual_transform(p, 0, Vector2.ONE * enemy_action_scale(e.kind))
			draw_texture_rect_region(pixellab_enemy_actions[art_kind], Rect2(-128, -145, 256, 160), Rect2(action_frame * 256, octant * 160, 256, 160), tint)
		else:
			visual_transform(p + Vector2(0, bob), 0, enemy_art_scale(e.kind, e.get("crouched", false)))
			draw_texture_rect_region(new_art, Rect2(-size * 0.5, -size * 92.0 / 96.0, size, size), Rect2(frame * 96, octant * 96, 96, 96), tint)
	elif special_enemy_art.has(e.kind):
		var special: Texture2D = special_enemy_art[e.kind]
		var cell_size := special.get_size() / 4.0
		var special_row := 3 if face.y < -0.6 else (1 if absf(face.x) > 0.6 else 0)
		var special_col := 3 if e.combat == "warning" else (int(e.step) % 3 if e.moving else 0)
		draw_texture_rect_region(special, Rect2(-40, -80, 80, 80), Rect2(Vector2(special_col, special_row) * cell_size, cell_size), tint)
	else:
		draw_texture_rect_region(enemy_anim, Rect2(-56, -92, 144, 96), Rect2(column * 144, ENEMY_ROW[e.kind] * 96, 144, 96), tint)
	visual_transform(Vector2.ZERO)
	if e.kind == "guard": draw_guard_shield_icon(p + Vector2(0, -101), e.combat == "attack")
	if e.hp < e.max:
		var w := 30.0 * scale
		draw_rect(Rect2(p + Vector2(-w * 0.5, 6), Vector2(w, 3)), Color("1c1522"))
		draw_rect(Rect2(p + Vector2(-w * 0.5, 6), Vector2(w * e.hp / e.max, 3)), Color("df729f"))

func boss_pose(e: Dictionary) -> String:
	if e.hurt > 0 and int(sim.tick_time * 24) % 3 == 0: return "hurt"
	if e.get("charge", 0.0) > 0: return "charge"
	if e.get("spin", 0.0) > 0: return "spiral"
	if e.get("stage", 1) >= 3: return "fury"
	if e.get("shot", 0.0) > 0: return "ring"
	return "idle"

func draw_boss(e: Dictionary) -> void:
	const BOSS_VISUAL_SCALE := 1.3
	if e.get("motion", "idle") == "warning":
		draw_arc(e.motion_to,95,0,TAU,48,Color("ffb451"),5)
		draw_line(e.p,e.motion_to,Color(1,0.4,0.2,0.6),4)
		text_at(e.motion_to-Vector2(50,85),"! MERGULHO" if e.motion_kind == "dive" else "! AVANÇO",GOLD,16)
	if e.get("motion", "idle") == "moving" and e.get("motion_kind", "") == "dive":
		draw_arc(e.p,78,0,TAU,32,CYAN,3); return
	var p: Vector2 = e.p
	var pose := boss_pose(e)
	var tex: Texture2D = boss_art[pose]
	var size := tex.get_size() * BOSS_VISUAL_SCALE
	if pose == "spiral":
		visual_transform(p - Vector2(0, 40), e.get("spin_angle", 0.0) * 0.35)
		draw_texture_rect(tex, Rect2(-size * 0.5, size), false)
		visual_transform(Vector2.ZERO)
	else:
		var sway := sin(sim.tick_time * 1.6) * 2.0
		draw_texture_rect(tex, Rect2(p + Vector2(-size.x * 0.5, 92 - size.y + sway), size), false)
	if pose == "charge":
		var k: float = 1.0 - e.charge / 0.9
		draw_circle(p - Vector2(0, 20), 10 + k * 26, Color(0.65, 0.3, 1, 0.12 + k * 0.2))
	draw_rect(Rect2(p - Vector2(91, 212), Vector2(182, 7)), Color("181625"))
	draw_rect(Rect2(p - Vector2(91, 212), Vector2(182 * e.hp / e.max, 7)), Color("df729f"))
	text_at(p + Vector2(-96, -220), "O ALMIRANTE DAS PROFUNDEZAS", Color("d1b3c5"), 12)

func draw_corpse(fx: Dictionary) -> void:
	var fade: float = clampf(fx.life / (fx.max * 0.4), 0, 1)
	if fx.enemy == "warden":
		draw_feral(warden_texture, fx.p, Vector2.DOWN, 0, 256, 288, Color(0.35, 0.3, 0.35, fade)); return
	if fx.enemy == "boss":
		var tex: Texture2D = boss_art.defeat
		var sink: float = (1.0 - fx.life / fx.max) * 50
		var size := tex.get_size() * 1.3
		draw_texture_rect(tex, Rect2(fx.p + Vector2(-size.x * 0.5, 92 - size.y + sink), size), false, Color(1, 1, 1, fade))
		return
	var art_kind := enemy_art_kind(fx.enemy)
	if pixellab_enemy_actions.has(art_kind):
		var row := enemy_octant(fx.get("face", Vector2.DOWN))
		visual_transform(fx.p, 0, Vector2.ONE * enemy_action_scale(fx.enemy))
		draw_texture_rect_region(pixellab_enemy_actions[art_kind], Rect2(-128, -145, 256, 160), Rect2(768, row * 160, 256, 160), Color(1, 1, 1, fade))
		visual_transform(Vector2.ZERO)
		return
	if fx.enemy == "bomber": return
	if pixellab_enemy_art.has(art_kind):
		var size: float = PIXELLAB_ENEMY_SIZE[art_kind]
		var fall: float = clampf((1.0 - fx.life / fx.max) * 7.0, 0.0, 1.0)
		var corpse_scale := enemy_art_scale(fx.enemy)
		corpse_scale.y *= lerpf(1.0, 0.28, fall)
		visual_transform(fx.p, 0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 23.0 * corpse_scale.x, Color(0.12, 0.03, 0.13, 0.35 * fade))
		visual_transform(fx.p, 0, corpse_scale)
		var row := enemy_octant(fx.get("face", Vector2.DOWN))
		draw_texture_rect_region(pixellab_enemy_art[art_kind], Rect2(-size * 0.5, -size * 92.0 / 96.0, size, size), Rect2(0, row * 96, 96, 96), Color(0.68, 0.62, 0.74, fade))
		visual_transform(Vector2.ZERO)
		return
	var scale := 0.6 if fx.enemy == "crawler_small" else 1.0
	visual_transform(fx.p, 0, Vector2(-scale if fx.get("flip", false) else scale, scale))
	draw_texture_rect_region(enemy_anim, Rect2(-56, -92, 144, 96), Rect2(7 * 144, ENEMY_ROW.get(fx.enemy, 3) * 96, 144, 96), Color(1, 1, 1, fade))
	visual_transform(Vector2.ZERO)

# ───────────────────────── REFÚGIO • FORA DO TEMPO ─────────────────────────
const VOID := Color("0a0536")
const VIOLET := Color("a76bff")
const HUB_LAMPS := [Vector2(225, 150), Vector2(410, 45), Vector2(520, 142), Vector2(370, 168), Vector2(790, 148),
	Vector2(805, 22), Vector2(976, 352), Vector2(1182, 312), Vector2(1330, 362), Vector2(485, 603), Vector2(822, 636)]

func hub_parallax(depth: float) -> Vector2:
	var focus: Vector2 = sim.actors[0].p if sim.actors.size() > 0 else sim.HUB_SIZE * 0.5
	return (sim.HUB_SIZE * 0.5 - focus) * depth

func hash01(n: int) -> float:
	return fposmod(sin(float(n) * 12.9898) * 43758.5453, 1.0)

func gear(c: Vector2, radius: float, teeth: int, angle: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for n in range(teeth * 2):
		var r := radius if n % 2 == 0 else radius * 0.8
		var a0 := angle + n * PI / teeth
		pts.append(c + Vector2.RIGHT.rotated(a0 - 0.12) * r); pts.append(c + Vector2.RIGHT.rotated(a0 + 0.12) * r)
	draw_colored_polygon(pts, color)
	draw_circle(c, radius * 0.45, VOID)
	draw_circle(c, radius * 0.18, color)

func brick(c: Vector2, angle: float, shade: float) -> void:
	visual_transform(c, angle)
	draw_rect(Rect2(-13, -6, 26, 12), Color("2a1420"))
	draw_rect(Rect2(-12, -5, 24, 10), Color(0.52, 0.25, 0.2).darkened(shade))
	draw_rect(Rect2(-12, -5, 24, 3), Color(0.68, 0.38, 0.3).darkened(shade))
	visual_transform(Vector2.ZERO)

func phone_booth(c: Vector2, angle: float) -> void:
	visual_transform(c, angle)
	draw_rect(Rect2(-17, -46, 34, 92), Color("2a0a10"))
	draw_rect(Rect2(-15, -44, 30, 88), Color("b3262c"))
	draw_rect(Rect2(-13, -40, 26, 7), Color("f2e6c9"))
	for y in range(3):
		for x in range(2):
			draw_rect(Rect2(-11 + x * 12, -28 + y * 18, 10, 15), Color("3c5e7a"))
			draw_rect(Rect2(-11 + x * 12, -28 + y * 18, 10, 3), Color("89b4c9"))
	visual_transform(Vector2.ZERO)

func draw_refuge_back() -> void:
	var t: float = sim.tick_time
	# Vazio cósmico: base, nebulosas e estrelas cintilantes (camada mais distante).
	draw_rect(Rect2(-500, -400, 2344, 1552), VOID)
	var far := hub_parallax(0.02)
	for blob in [[Vector2(-120, 780), 320, Color(0.35, 0.1, 0.6, 0.18)], [Vector2(1450, 820), 360, Color(0.15, 0.1, 0.55, 0.2)],
			[Vector2(1480, 60), 280, Color(0.4, 0.1, 0.55, 0.14)], [Vector2(-160, 120), 260, Color(0.2, 0.08, 0.5, 0.16)]]:
		for k in range(4): draw_circle(blob[0] + far, blob[1] * (1.0 - k * 0.2), blob[2])
	for n in range(170):
		var p := Vector2(hash01(n) * 2100 - 380, hash01(n + 500) * 1300 - 280) + far * 1.5
		var twinkle := 0.45 + 0.55 * sin(t * (1.2 + hash01(n + 900) * 2.5) + n)
		draw_rect(Rect2(p, Vector2(2, 2)), Color(0.85, 0.85, 1.0, clampf(twinkle, 0.1, 1.0)))
	# Destroços flutuantes distantes: engrenagens, tijolos, cabine telefônica e ônibus.
	var mid := hub_parallax(0.05)
	gear(Vector2(-90, 300) + mid + Vector2(0, sin(t * 0.4) * 8), 46, 10, t * 0.12, Color("5a3a24"))
	gear(Vector2(1450, 460) + mid + Vector2(0, cos(t * 0.35) * 10), 38, 9, -t * 0.15, Color("4d3524"))
	gear(Vector2(420, 830) + mid, 30, 8, t * 0.2, Color("5a3a24"))
	phone_booth(Vector2(-110, 640) + mid + Vector2(0, sin(t * 0.5) * 12), -0.35 + sin(t * 0.3) * 0.05)
	for n in range(18):
		var p := Vector2(hash01(n + 40) * 1900 - 280, hash01(n + 80) * 1100 - 180)
		if Rect2(-20, -20, 1384, 792).has_point(p): p.y += 830 if p.y > 376 else -260
		brick(p + mid + Vector2(0, sin(t * 0.6 + n) * 6), t * 0.1 * (1 if n % 2 else -1) + n, hash01(n) * 0.4)
	# Cenário pintado (1344x752) e fusão das bordas com o vazio.
	draw_texture(refuge_bg, Vector2.ZERO)
	for n in range(12):
		var alpha := float(n + 1) / 12.0
		draw_rect(Rect2(0, 752 - (12 - n) * 4, 1344, 4), Color(VOID, alpha * 0.9))
		draw_rect(Rect2(-40 + n * 3.4, 0, 3.4, 752), Color(VOID, (1.0 - alpha) * 0.9))
		draw_rect(Rect2(1344 + 40 - (n + 1) * 3.4, 0, 3.4, 752), Color(VOID, (1.0 - alpha) * 0.9))
	# Portal DOCAS / 1941: energia ciano girando dentro do anel.
	var docks_c := Vector2(645, 86)
	visual_transform(docks_c, 0, Vector2(1, 1.25))
	for k in range(4):
		var r := 30.0 + k * 9 + sin(t * 2 + k) * 2
		var start := t * (1.4 + k * 0.3) * (1 if k % 2 == 0 else -1)
		draw_arc(Vector2.ZERO, r, start, start + 2.2, 24, Color(0.45, 0.95, 1.0, 0.28), 3)
	draw_circle(Vector2.ZERO, 58, Color(0.3, 0.85, 1.0, 0.05 + 0.03 * sin(t * 3)))
	visual_transform(Vector2.ZERO)
	# Coordenada perdida: fissuras violeta que mudam de forma.
	var lost_c := Vector2(1022, 166)
	var crack_seed := int(t * 6)
	for k in range(4):
		var p := lost_c
		var dir := Vector2.RIGHT.rotated(hash01(crack_seed * 7 + k) * TAU)
		for step in range(4):
			var q := p + dir.rotated((hash01(crack_seed * 13 + k * 5 + step) - 0.5) * 1.4) * 14
			if q.distance_to(lost_c) > 50: break
			draw_line(p, q, Color(0.8, 0.5, 1.0, 0.5 + 0.3 * hash01(crack_seed + step)), 2)
			p = q
	draw_circle(lost_c, 50, Color(0.55, 0.2, 0.9, 0.05 + 0.04 * sin(t * 5.3)))
	# Scanner da armadura de treino.
	var scan_y := 405 + fposmod(t * 70, 170)
	draw_rect(Rect2(218, scan_y, 72, 2), Color(0.4, 0.95, 1, 0.55))
	draw_rect(Rect2(218, scan_y - 6, 72, 6), Color(0.4, 0.95, 1, 0.1))
	# Luz âmbar das lanternas, com leve cintilação.
	for n in range(HUB_LAMPS.size()):
		var flicker := 0.8 + 0.2 * sin(t * (7.0 + n) + n * 3.1) * sin(t * 2.3 + n)
		for radius in [46, 32, 20]:
			draw_circle(HUB_LAMPS[n], radius * flicker, Color(1.0, 0.66, 0.25, 0.035))
	if not sim.mech.deployed:
		draw_rect(Rect2(1070, 505, 140, 50), Color(0.05, 0.05, 0.09, 0.55))
		text_at(Vector2(1085, 535), "BAIA VAZIA • C", Color("d2a33c"), 13)

func draw_refuge_front() -> void:
	var t: float = sim.tick_time
	# Brilho pulsante do Núcleo Temporal por cima do recorte.
	var core_c := Vector2(645, 312)
	var pulse := 0.5 + 0.5 * sin(t * 2.4)
	for k in range(3): draw_circle(core_c, 22 + k * 10 + pulse * 4, Color(0.4, 0.95, 1.0, 0.05 + 0.03 * pulse))
	# Destroços próximos (parallax mais forte), só sobre o vazio.
	var near := hub_parallax(0.09)
	brick(Vector2(38, 712) + near + Vector2(0, sin(t * 0.8) * 5), t * 0.25, 0.1)
	brick(Vector2(1310, 730) + near + Vector2(0, cos(t * 0.7) * 6), -t * 0.2, 0.2)
	gear(Vector2(1325, 640) + near, 20, 8, t * 0.3, Color("6b4428"))
	# Rótulos de interação só aparecem para quem está perto.
	var shown: Dictionary = {}
	for a in sim.actors:
		if not a.active or a.dead or a.mech: continue
		var point: Dictionary = sim.hub_point_near(a.p)
		if point.is_empty() or shown.has(point.id): continue
		shown[point.id] = true
		var label: String = point.label
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16
		var anchor: Vector2 = a.p + Vector2(-width * 0.5, -118)
		var locked: bool = point.id == "lost"
		draw_rect(Rect2(anchor, Vector2(width, 22)), Color(0.03, 0.03, 0.08, 0.82))
		draw_rect(Rect2(anchor, Vector2(width, 22)), VIOLET if locked else GOLD, false, 1.5)
		text_at(anchor + Vector2(8, 16), label, VIOLET if locked else Color("f3d9a0"), 13)

func core_alpha() -> float:
	# Quem passa atrás do Núcleo continua visível: a gaiola fica translúcida.
	for a in sim.actors:
		if a.active and not a.dead and Rect2(CORE_OFFSET - Vector2(20, 0), Vector2(208, 204)).has_point(a.p): return 0.5
	return 1.0

func draw_power_aura(pos: Vector2, strength: float, charging: bool) -> void:
	# Aura estilo "transformação": línguas de energia dourada/ciano subindo do chão.
	var t: float = sim.tick_time
	var count := 12 if charging else 6
	for n in range(count):
		var ang := float(n) / count * TAU
		var x := cos(ang) * (22 if charging else 16)
		var flick := 0.5 + 0.5 * sin(t * (18 + n * 3) + n * 1.7)
		var height := (80 + flick * 70) * strength if charging else (18 + flick * 14)
		var base := pos + Vector2(x, sin(ang) * 6)
		var col := Color(1.0, 0.85, 0.3, 0.55 * strength) if n % 2 == 0 and charging else Color(0.4, 0.95, 1.0, 0.45 * strength + 0.08)
		var half := 11.0 if charging else 6.0
		draw_colored_polygon(PackedVector2Array([base + Vector2(-half, 0), base + Vector2(half, 0), base + Vector2(x * 0.15 + sin(t * 11 + n) * 5, -height)]), col)
	if charging:
		for k in range(3): draw_circle(pos - Vector2(0, 42), 34 + k * 12 + sin(t * 20) * 3, Color(1, 0.9, 0.45, 0.07 * strength))
	if charging:
		for n in range(3):
			var a0 := t * 7 + n * 2.1
			var p0 := pos - Vector2(0, 40) + Vector2(cos(a0), sin(a0)) * 26
			var p1 := p0 + Vector2(cos(a0 * 3), sin(a0 * 2)) * 14
			var p2 := p1 + Vector2(sin(a0 * 5), cos(a0 * 4)) * 12
			draw_polyline(PackedVector2Array([p0, p1, p2]), Color(0.85, 1, 1, 0.9), 2)

func draw_transform_fx(fx: Dictionary) -> void:
	var owner: Dictionary = sim.actors[fx.get("owner", 0)]
	var p: Vector2 = owner.p
	var t: float = 1.0 - fx.life / fx.max
	# Pilar de luz descendo do céu
	var pillar := clampf(t / 0.35, 0, 1) * (1.0 - clampf((t - 0.55) / 0.45, 0, 1))
	if pillar > 0:
		var w := 26.0 + sin(sim.tick_time * 40) * 3
		draw_rect(Rect2(p.x - w * 1.6, p.y - 900, w * 3.2, 900), Color(1, 0.9, 0.5, 0.12 * pillar))
		draw_rect(Rect2(p.x - w, p.y - 900, w * 2, 900), Color(0.5, 1, 1, 0.28 * pillar))
		draw_rect(Rect2(p.x - w * 0.4, p.y - 900, w * 0.8, 900), Color(1, 1, 1, 0.55 * pillar))
	# Pedrinhas subindo do chão durante a carga
	if t < 0.55:
		for n in range(16):
			var h := fposmod(sim.tick_time * 90 + n * 37, 80.0)
			var x := sin(n * 12.3) * 46
			draw_rect(Rect2(p + Vector2(x, -h), Vector2(3, 3)), Color(0.75, 0.7, 0.6, 1.0 - h / 80.0))
	# Anel de energia se fechando e depois explodindo
	var ring_r := 90.0 * (1.0 - clampf(t / 0.46, 0, 1)) + 12.0 if t < 0.46 else 12.0 + (t - 0.46) * 420.0
	var ring_a := 0.9 if t < 0.46 else maxf(0, 1.0 - (t - 0.46) * 2.2)
	visual_transform(p - Vector2(0, 36), 0, Vector2(1, 0.8))
	draw_arc(Vector2.ZERO, ring_r, 0, TAU, 40, Color(1, 0.9, 0.4, ring_a), 3)
	draw_arc(Vector2.ZERO, ring_r * 0.8, sim.tick_time * 6, sim.tick_time * 6 + 4.0, 24, Color(0.5, 1, 1, ring_a), 2)
	visual_transform(Vector2.ZERO)
	if t > 0.8:
		text_at(p + Vector2(-58, -118 - (t - 0.8) * 60), "ARMADURA ÔMEGA!", Color(1, 0.9, 0.5, (1 - t) * 5), 16)

func draw_omega_assembly_overlay(foot: Vector2, progress: float) -> void:
	if omega_assembly_texture == null: return
	var frames := 8
	var frame := omega_assembly_frame(progress)
	var source_size := Vector2(omega_assembly_texture.get_width() / float(frames), omega_assembly_texture.get_height())
	var draw_size := Vector2(124, 124)
	draw_texture_rect_region(omega_assembly_texture, Rect2(foot - Vector2(draw_size.x * 0.5, draw_size.y), draw_size), Rect2(frame * source_size.x, 0, source_size.x, source_size.y), Color.WHITE)

func omega_assembly_frame(progress: float) -> int:
	return clampi(int(clampf(progress, 0.0, 0.9999) * 8), 0, 7)

func draw_chest_burst(fx: Dictionary) -> void:
	var t: float = 1.0 - fx.life / fx.max
	var p: Vector2 = fx.p - Vector2(0, 30)
	var k := clampf((t - 0.18) / 0.82, 0, 1)
	if k <= 0: return
	var gold := Color(1, 0.8, 0.35) if not fx.get("secret", false) else Color(0.5, 1, 1)
	for n in range(9):
		var ang := -PI / 2 + (n - 4) * 0.28
		var len := 40 + 70 * k
		draw_line(p, p + Vector2.RIGHT.rotated(ang) * len, Color(gold, 0.45 * (1 - k)), 4)
	for n in range(8):
		var v := Vector2((n - 3.5) * 22, -150 - (n % 3) * 30)
		var q := p + v * k * 0.55 + Vector2(0, 260 * k * k * 0.55)
		draw_texture_rect(dock_art.coin if dock_art.has("coin") else dock_art.chest, Rect2(q - Vector2(6, 6), Vector2(12, 12)), false, Color(1, 1, 1, 1 - maxf(0, k - 0.7) / 0.3))
	text_at(p + Vector2(-40, -40 - 30 * k), "+10  ARMA NOVA", Color(gold, 1 - k * 0.8), 14)

func draw_screen_flash() -> void:
	for fx in sim.effects:
		if fx.kind == "transform":
			var t: float = 1.0 - fx.life / fx.max
			if t > 0.44 and t < 0.66:
				var a := 1.0 - absf(t - 0.47) / 0.19
				var owner: Dictionary = sim.actors[fx.get("owner", 0)]
				draw_rect(Rect2(owner.p - Vector2(3000, 3000), Vector2(6000, 6000)), Color(1, 1, 0.95, clampf(a, 0, 1) * 0.85))

# ── 0.13: Titan só usa vistas reais (lado nas diagonais), bomba, explosões e efeitos do cenário ──
func titan_pose(f: Vector2) -> Array:
	# 0.18: utiliza também as duas vistas diagonais da nova folha.
	return marty_pose(f)

func draw_shield_hex(c: Vector2, k: float) -> void:
	var pts := PackedVector2Array()
	for n in range(7): pts.append(c + Vector2.RIGHT.rotated(n * TAU / 6 + PI / 6) * Vector2(46, 58))
	var pulse := 0.5 + 0.5 * sin(sim.tick_time * 5)
	draw_polyline(pts, Color(0.45, 0.95, 1, 0.35 + 0.35 * k + 0.1 * pulse), 3)
	draw_colored_polygon(pts.slice(0, 6), Color(0.4, 0.9, 1, 0.06 + 0.06 * k))
	scenery.lights.append({"p": c + Vector2(0, 40), "kind": "cyan"})

func draw_bomb(b: Dictionary) -> void:
	var k: float = clampf(b.t / sim.MECH_BOMB.flight, 0, 1)
	var to: Vector2 = b.to
	# marcador de alvo no chão
	visual_transform(to, 0, Vector2(1, 0.5))
	draw_arc(Vector2.ZERO, sim.MECH_BOMB.radius * (0.4 + 0.6 * k), 0, TAU, 40, Color(1, 0.35, 0.2, 0.5 + 0.4 * k), 3)
	draw_circle(Vector2.ZERO, 10, Color(1, 0.3, 0.2, 0.6))
	visual_transform(Vector2.ZERO)
	var height := sin(k * PI) * 170.0
	var p: Vector2 = b.p - Vector2(0, 30 + height)
	visual_transform(b.p, 0, Vector2(1, 0.4)); draw_circle(Vector2.ZERO, 12 * (1.0 - height / 250.0), Color(0, 0, 0, 0.35)); visual_transform(Vector2.ZERO)
	draw_circle(p, 11, Color("1d1e24")); draw_circle(p - Vector2(3, 3), 4, Color("7d808c"))
	var spark := p + Vector2(6, -12) + Vector2(sin(sim.tick_time * 40) * 2, 0)
	draw_circle(spark, 4, Color(1, 0.8, 0.3)); scenery.lights.append({"p": spark, "kind": "bulb"})

func draw_fx_013(fx: Dictionary) -> void:
	var t: float = 1.0 - fx.life / maxf(0.01, fx.get("max", fx.life))
	var p: Vector2 = fx.p
	match fx.kind:
		"explosion":
			var r: float = fx.get("r", 100.0)
			visual_transform(p, 0, Vector2(1, 0.62))
			draw_circle(Vector2.ZERO, r * (0.3 + 0.8 * t), Color(1, 0.55, 0.15, 0.45 * (1 - t)))
			draw_circle(Vector2.ZERO, r * (0.2 + 0.5 * t), Color(1, 0.9, 0.5, 0.7 * (1 - t)))
			draw_arc(Vector2.ZERO, r * (0.5 + 0.7 * t), 0, TAU, 40, Color(1, 0.8, 0.5, 1 - t), 4)
			visual_transform(Vector2.ZERO)
			for n in range(12):
				var d := Vector2.RIGHT.rotated(n * TAU / 12 + p.x)
				draw_circle(p + d * r * t * Vector2(1, 0.6) - Vector2(0, sin(t * PI) * 40), 7 * (1 - t) + 2, Color(0.35, 0.3, 0.3, 0.6 * (1 - t)))
			scenery.lights.append({"p": p, "kind": "blast", "r": r * 1.6 * (1 - t * 0.6)})
		"tentacle_strike":
			var dir: Vector2 = fx.get("dir", Vector2.RIGHT)
			var tip: Vector2 = p + dir * 80 * sin(t * PI) - Vector2(0, 30 + 40 * sin(t * PI))
			draw_polyline(PackedVector2Array([p, p.lerp(tip, 0.5) + dir.orthogonal() * 16, tip]), Color("5a2a66"), 12)
			draw_polyline(PackedVector2Array([p, p.lerp(tip, 0.5) + dir.orthogonal() * 16, tip]), Color("a05ab8"), 4)
		"gate_open":
			draw_arc(p, 40 + 120 * t, 0, TAU, 32, Color(1, 0.85, 0.4, 1 - t), 4)
		"gate_slam":
			for n in range(8):
				var d := Vector2.RIGHT.rotated(n * TAU / 8)
				draw_circle(p + d * (20 + 50 * t) * Vector2(1, 0.5), 8 * (1 - t) + 2, Color(0.6, 0.55, 0.5, 0.6 * (1 - t)))
		"shield_hit":
			draw_arc(p - Vector2(0, 40), 50 + 20 * t, 0, TAU, 6, Color(0.5, 1, 1, 1 - t), 5)
		"spawn_portal":
			# reforços surgindo: poça roxa que cresce e tentáculos de luz
			visual_transform(p, 0, Vector2(1, 0.5))
			draw_circle(Vector2.ZERO, 50 * minf(1.0, t * 2), Color(0.35, 0.05, 0.45, 0.6))
			draw_arc(Vector2.ZERO, 55 * minf(1.0, t * 2), 0, TAU, 32, Color(0.8, 0.3, 1, 0.9), 3)
			visual_transform(Vector2.ZERO)
			draw_line(p, p - Vector2(0, 120 * t), Color(0.8, 0.4, 1, 0.5 * (1 - t)), 10)
			scenery.lights.append({"p": p, "kind": "danger"})
		"prop_break":
			for n in range(10):
				var d := Vector2.RIGHT.rotated(n * TAU / 10 + p.y)
				var q: Vector2 = p + d * (10 + 60 * t) * Vector2(1, 0.6) - Vector2(0, 30 + sin(t * PI) * 40 - t * 30)
				visual_transform(q, t * 8 + n)
				draw_rect(Rect2(-5, -3, 10, 6), Color(0.55, 0.36, 0.2, 1 - t) if not fx.get("prop", "").begins_with("sandbags") else Color(0.75, 0.62, 0.4, 1 - t))
				visual_transform(Vector2.ZERO)
		"splinter":
			for n in range(4):
				var d := Vector2.RIGHT.rotated(n * 1.7 + p.x)
				draw_rect(Rect2(p + d * 20 * t - Vector2(0, 20), Vector2(4, 3)), Color(0.7, 0.5, 0.3, 1 - t))
		"splash":
			visual_transform(p, 0, Vector2(1, 0.5))
			draw_arc(Vector2.ZERO, 20 + 40 * t, 0, TAU, 24, Color(0.7, 0.9, 1, 1 - t), 3)
			visual_transform(Vector2.ZERO)
		"flash":
			draw_circle(p - Vector2(0, 30), 18 * (1 - t) + 6, Color(1, 0.85, 0.5, 0.8 * (1 - t)))
			scenery.lights.append({"p": p, "kind": "bulb"})
		"recoil":
			draw_circle(p - Vector2(0, 50) - fx.get("dir", Vector2.RIGHT) * 20 * t, 16 * t + 4, Color(0.7, 0.7, 0.72, 0.4 * (1 - t)))

func draw_chest_hd(chest: Dictionary) -> void:
	var p: Vector2 = chest.p
	var closed: Texture2D = scenery.props.chest
	var opened: Texture2D = scenery.props.chest_open
	visual_transform(p + Vector2(0, 6), 0, Vector2(1, 0.35)); draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.35)); visual_transform(Vector2.ZERO)
	var s := 0.66
	if not chest.open:
		var bob := sin(sim.tick_time * 2.0 + p.x) * 1.0
		var sz := closed.get_size() * s
		draw_texture_rect(closed, Rect2(p - Vector2(sz.x * 0.5, sz.y - 8 + bob), sz), false, Color(1.25,1.1,0.5) if chest.get("reward",false) else Color.WHITE)
		var glint := fposmod(sim.tick_time * 0.7 + p.x * 0.01, 3.0)
		if glint < 0.3: draw_circle(p + Vector2(-sz.x * 0.4 + glint * sz.x * 2.6, -sz.y + 18), 2.5, Color(1, 1, 0.85, 0.85))
		return
	var t: float = sim.tick_time - chest.get("t", -99.0)
	var shake := Vector2(sin(t * 90) * 2.5, 0) if t < 0.22 else Vector2.ZERO
	var tex: Texture2D = closed if t < 0.22 else opened
	var pop := 1.0 + 0.12 * maxf(0, 1.0 - absf(t - 0.3) / 0.15) if t < 0.5 else 1.0
	var sz2 := tex.get_size() * s * pop
	draw_texture_rect(tex, Rect2(p + shake - Vector2(sz2.x * 0.5, sz2.y - 8), sz2), false, Color(1, 1, 1).darkened(0.25 if t > 3.0 else 0.0))
	if t > 0.22 and t < 3.0:
		var glow := 0.6 + 0.4 * sin(sim.tick_time * 5)
		scenery.lights.append({"p": p - Vector2(0, 30), "kind": "bulb"})
		draw_circle(p - Vector2(0, 34), 14 * glow, Color(1, 0.85, 0.4, 0.25 * glow))

# 0.18: transformação única ao redor dos pés; mantém mão, arma e corpo unidos.
var visual_origin := Vector2.ZERO
var visual_scale := 1.0
func visual_transform(offset: Vector2, rotation: float = 0.0, scale_value: Vector2 = Vector2.ONE) -> void:
	draw_set_transform(visual_origin + (offset - visual_origin) * visual_scale, rotation, scale_value * visual_scale)

func draw_combat_warnings() -> void:
	for zone in sim.combat_zones:
		if not seen(zone.p): continue
		var color := Color("ffcf68") if zone.warning > 0 else Color("9fe341")
		if zone.kind == "blast": color = Color("ff785c")
		draw_circle(zone.p, zone.r, Color(color, 0.16 if zone.warning > 0 else 0.35))
		draw_arc(zone.p, zone.r, 0, TAU, 36, color, 3)
		if zone.warning > 0: text_at(zone.p + Vector2(-5, 4), "!", color, 18)
	for stake in sim.harpoons:
		if seen(stake.p):
			draw_line(stake.p + Vector2(-7, 6), stake.p + Vector2(7, -35), Color("1a1525"), 9)
			draw_line(stake.p + Vector2(-7, 6), stake.p + Vector2(7, -35), Color("a7e6ef"), 4)
	for enemy in sim.enemies:
		if not seen(enemy.p) or enemy.get("combat", "") != "warning": continue
		var aim: Vector2 = enemy.get("locked", enemy.p)
		if enemy.kind in ["crawler", "crawler_small"]:
			aim = enemy.p + (aim - enemy.p).limit_length(220 if enemy.kind == "crawler" else 110)
			draw_arc(aim, 58 if enemy.kind == "crawler" else 32, 0, TAU, 32, Color("ffe281"), 4)
		elif enemy.kind == "bomber": draw_arc(enemy.p, 90, 0, TAU, 40, Color("ff9e61"), 4)
		else:
			draw_line(enemy.p - Vector2(0, 28), aim - Vector2(0, 28), Color(1, 0.75, 0.4, 0.65), 2)
		text_at(enemy.p + Vector2(-5, -106), "!", Color("ffe281"), 20)
static func chapel_npc_label(quest_state: int) -> String:
	return "PESCADOR • INTERAGIR" if quest_state == 0 else ("PESCADOR • RETORNAR" if quest_state == 1 else "PESCADOR")
