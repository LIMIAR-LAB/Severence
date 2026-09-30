class_name CombatHUD
extends Control
const DocksMap = preload("res://scripts/docks_map.gd")

var app: Node
var art: Dictionary = {}
var font: Font
const CYAN := Color("64eef5")
const GOLD := Color("d6b36c")

static func show_story_marker(story_quest: int) -> bool:
	return story_quest < 2

func _ready() -> void:
	var form_material := ShaderMaterial.new()
	form_material.shader = preload("res://shaders/blue_form.gdshader")
	material = form_material
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = ThemeDB.fallback_font
	for key in ["portrait", "heart", "key", "coin", "crystal", "gun"]:
		art[key] = load("res://assets/environment/reference/" + key + ".png")
	for key in ["chest"]:
		art[key] = load("res://assets/environment/reference/" + key + ".png")
	art["capsule"] = load("res://assets/environment/docks/capsule.png")
	art["key_clean"] = load("res://assets/environment/docks/key.png")
	art["coin_clean"] = load("res://assets/environment/docks/coin.png")
	art["titan"] = load("res://assets/mech/titan_v2.png")
	art["portraits"] = load("res://assets/ui/hud/marty_omega_portraits_v1.png")
	art["azul_icon"] = load("res://assets/characters/marty/azul/front.tres")
	art["omega_icon"] = load("res://assets/ui/equipamento/icones/icon_armadura_omega.png")
	art["robot_titan"] = load("res://assets/ui/equipamento/icones/icon_robo_titan.png")
	art["robot_spectre"] = load("res://assets/ui/equipamento/icones/icon_robo_spectre.png")
	art["boss"] = load("res://assets/boss/almirante_idle.png")
	# 0.16: ícones do mapa (tools/prepare_map_icons.py) — 48x48, mostrados em 1/2 (24) no mapa e 1/3 (16) no minimapa
	for key in ["boss", "shop", "challenge", "chest", "locked", "exit"]: art["map_" + key] = load("res://assets/ui/map_icons/map_icon_" + key + ".png")
	for key in ["pistol", "shotgun", "smg", "bazooka", "omega_sword"]:
		art["w_" + key] = load("res://assets/weapons/" + ("bazooka_v2" if key == "bazooka" else key) + ".png")

func _process(_dt: float) -> void:
	visible = app.playing and not app.menu.visible
	if visible: queue_redraw()

func frame(r: Rect2) -> void:
	draw_rect(r.grow(3), Color("0b0e15")); draw_rect(r, GOLD)
	draw_rect(r.grow(-3), Color("51442f")); draw_rect(r.grow(-6), Color("081724"))
	for p in [r.position + Vector2(4,4), r.position + Vector2(r.size.x-5,4), r.end - Vector2(5,5), r.position + Vector2(4,r.size.y-5)]:
		draw_rect(Rect2(p, Vector2(3,3)), Color("ffdc95"))

func weapon_frame() -> void:
	var r := Rect2(300, 14, 146, 82)
	draw_rect(r.grow(3), Color("050b12"))
	draw_rect(r, Color("b38b50"))
	draw_rect(r.grow(-2), Color("18333a"))
	draw_rect(r.grow(-5), Color("091a24"))
	draw_rect(Rect2(307, 21, 91, 44), Color("0e2932"))
	draw_rect(Rect2(400, 21, 39, 44), Color("10242b"))
	draw_rect(Rect2(398, 21, 2, 44), Color("695a40"))
	draw_rect(Rect2(306, 67, 134, 1), Color("ad8a55"))
	draw_rect(Rect2(306, 69, 134, 1), Color("315b61"))
	for x in [304, 438]:
		draw_rect(Rect2(x, 18, 4, 2), Color("f6d291"))
		draw_rect(Rect2(x, 90, 4, 2), Color("f6d291"))
	draw_rect(Rect2(310, 24, 2, 37), Color("58c6cc"))
	draw_rect(Rect2(393, 24, 2, 37), Color("58c6cc"))

func text(p: Vector2, value: String, size: int = 15, color: Color = Color("e8dfba")) -> void:
	draw_string(font, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_boss_health(s) -> void:
	if s.mode != "run" or s.boss_dead: return
	var boss: Dictionary = {}
	for enemy in s.enemies:
		if enemy.kind == "boss" and enemy.hp > 0:
			boss = enemy
			break
	if boss.is_empty(): return
	var in_arena := false
	for actor in s.actors:
		if actor.active and not actor.dead and s.room_at(actor.p).get("id", "") == "boss":
			in_arena = true
			break
	if not in_arena: return
	var vp := get_viewport_rect().size
	var center := Vector2(vp.x * 0.5, vp.y - 205)
	var panel := Rect2(center + Vector2(-190, -47), Vector2(380, 94))
	var gold := Color("d8ab66")
	var bright := Color("ffe1a0")
	draw_rect(panel.grow(5), Color(0.01, 0.015, 0.03, 0.72))
	draw_rect(panel, Color("0b1423"))
	draw_rect(panel, gold, false, 3)
	draw_rect(panel.grow(-5), Color("574a48"), false, 1)
	draw_rect(Rect2(center + Vector2(-180, -37), Vector2(360, 2)), Color("755d50"))
	draw_rect(Rect2(center + Vector2(-180, 30), Vector2(360, 2)), Color("755d50"))
	for side in [-1, 1]:
		var x: float = center.x + side * 165
		var tip := Vector2(x, center.y - 19)
		draw_circle(tip, 15, Color("1a3440"))
		draw_arc(tip, 14, 0, TAU, 20, gold, 2)
		draw_line(tip + Vector2(0, -11), tip + Vector2(0, 9), bright, 2)
		draw_line(tip + Vector2(-7, -7), tip + Vector2(-7, 3), gold, 2)
		draw_line(tip + Vector2(7, -7), tip + Vector2(7, 3), gold, 2)
		draw_line(tip + Vector2(-7, 3), tip + Vector2(7, 3), gold, 2)
		draw_circle(center + Vector2(side * 182, 0), 3, bright)
	var name := "O ALMIRANTE DAS PROFUNDEZAS"
	var name_size := 17
	var name_width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
	var name_pos := center + Vector2(-name_width * 0.5, -15)
	draw_string(font, name_pos + Vector2(1, 2), name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, Color("291726"))
	draw_string(font, name_pos, name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, bright)
	var title := "✦  SENHOR DO ABISMO  ✦"
	var title_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, center + Vector2(-title_width * 0.5, 1), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9bc3cc"))
	var track := Rect2(center + Vector2(-151, 11), Vector2(302, 14))
	draw_rect(track.grow(3), gold)
	draw_rect(track, Color("291724"))
	var ratio: float = clampf(boss.hp / boss.max, 0.0, 1.0)
	var fill := Rect2(track.position + Vector2(2, 2), Vector2((track.size.x - 4) * ratio, track.size.y - 4))
	var pulse := 0.12 * sin(s.tick_time * 8.0) if ratio < 0.33 else 0.0
	draw_rect(fill, Color(0.75 + pulse, 0.18, 0.3, 1.0) if ratio < 0.33 else Color("b34775"))
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2)), Color("ffb3bd") if ratio < 0.33 else Color("ef9bbc"))
	for marker in [1, 2]:
		var mx: float = track.position.x + track.size.x * marker / 3.0
		draw_line(Vector2(mx, track.position.y + 1), Vector2(mx, track.end.y - 1), Color("33263a"), 2)
		draw_circle(Vector2(mx, track.end.y + 5), 2, gold)
	draw_rect(Rect2(center + Vector2(-8, 37), Vector2(16, 2)), bright)

func draw_omega_indicator(s, a: Dictionary, ps: bool, id: int) -> void:
	var armor_info: Dictionary = s.ARMORS[a.armor_type]
	var ratio: float = 1.0
	var state := "PRONTA"
	var detail := "L1 • VESTIR" if ps else "R • VESTIR"
	var color := CYAN
	if a.armor:
		ratio = clampf(a.armor_time / armor_info.duration, 0.0, 1.0)
		state = "ATIVA • %.0fs" % ceilf(a.armor_time)
		detail = "TEMPO RESTANTE"
	elif a.armor_cd > 0.0:
		ratio = clampf(1.0 - a.armor_cd / armor_info.cooldown, 0.0, 1.0)
		state = "RECARREGANDO • %.0fs" % ceilf(a.armor_cd)
		detail = "%d%% CARREGADA" % int(roundf(ratio * 100.0))
		color = GOLD
	elif a.mech:
		state = "PRONTA"
		detail = "SAIA DO TITAN PARA VESTIR"

	var center := Vector2(55, 140)
	var icon_tint := Color.WHITE if a.armor or a.armor_cd <= 0.0 else Color(0.55, 0.58, 0.62)
	draw_rect(Rect2(17, 102, 76, 76), Color("081724"))
	if a.armor_type == "azul":
		draw_texture_rect(art.azul_icon, Rect2(37, 114, 35, 52), false, Color(0.125, 0.25, 0.875, icon_tint.r))
	else:
		draw_texture_rect(art.omega_icon, Rect2(29, 114, 52, 52), false, icon_tint)
	for segment in range(12):
		var start: float = -PI * 0.5 + TAU * float(segment) / 12.0
		var end: float = start + TAU * 0.075
		var segment_color: Color = color if float(segment) < ratio * 12.0 else Color("34404a")
		draw_arc(center, 35.0, start, end, 3, segment_color, 4.0, true)
	if ratio >= 1.0 and not a.armor:
		var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.008)
		draw_arc(center, 39.0, -PI * 0.5, PI * 1.5, 36, Color(CYAN, pulse), 2.0, true)
	text(Vector2(103, 125), "FORMA AZUL" if a.armor_type == "azul" else "ARMADURA ÔMEGA", 13, GOLD)
	text(Vector2(103, 146), state, 14, color)
	text(Vector2(103, 165), detail, 11, Color("b6c8cd"))
	if a.armor:
		var special_key := "→" if ps else ("T" if id == 0 else "P")
		if s.is_blue_form(a):
			var claw_cooldown: float = a.get("claw_cd", 0.0)
			var claw_label := "GARRA • %.1fs" % claw_cooldown if claw_cooldown > 0 else "%s • GARRA DO CHÃO" % special_key
			text(Vector2(103, 182), claw_label, 11, CYAN if claw_cooldown <= 0 else Color("8a7a58"))
			return
		var beam_label := "RAIO ATIVO • %.1fs" % a.beam_time if a.beam_time > 0 else ("RAIO • %.0fs" % ceilf(a.beam_cd) if a.beam_cd > 0 else "%s • SEGURAR RAIO" % special_key)
		text(Vector2(103, 182), beam_label, 11, CYAN if a.beam_cd <= 0 else Color("8a7a58"))

func draw_robot_indicator(s, a: Dictionary, ps: bool, id: int) -> void:
	var robot_id: String = a.get("selected_robot", "")
	var center := Vector2(55, 241)
	var color := Color("87959d")
	var ratio := 0.0
	var state := "NENHUM EQUIPADO"
	var detail := "ESCOLHA UM ROBÔ"
	var controls := ""
	var switch_hint := "← • TROCAR ROBÔ" if ps else "V / ◀ • TROCAR ROBÔ"
	var robot_icon: Texture2D = null
	if robot_id == "titan":
		robot_icon = art.robot_titan
		color = Color("e8a33d")
		ratio = clampf(float(s.mech.hp) / 240.0, 0.0, 1.0)
		state = "PILOTANDO" if a.mech else ("EM CAMPO" if s.mech.deployed else "GUARDADO")
		if s.mech.hp <= 0.0: state = "SEM INTEGRIDADE"
		detail = "INTEGRIDADE %d%%  •  GAS %d%%" % [int(roundf(ratio * 100.0)), int(roundf(clampf(float(s.mech.fuel) / s.FUEL_MAX, 0.0, 1.0) * 100.0))]
		controls = "↑ INVOCAR  •  △ PILOTAR" if ps else "C INVOCAR  •  E PILOTAR"
	elif robot_id == "spectre":
		robot_icon = art.robot_spectre
		color = Color("c68cff")
		ratio = clampf(float(s.spectres[id].hp) / 100.0, 0.0, 1.0)
		state = "FUSÃO" if a.fused else ("EM CAMPO" if s.spectres[id].state == "following" else "GUARDADO")
		if s.spectres[id].hp <= 0.0: state = "SEM ENERGIA"
		detail = "ENERGIA %d%%" % int(roundf(ratio * 100.0))
		controls = "↑ INVOCAR  •  ↓ FUNDIR" if ps else "C INVOCAR  •  G FUNDIR"
	if robot_id != "" and a.summon_cd > 0.0:
		state += "  •  RECARGA %.1fs" % a.summon_cd

	draw_rect(Rect2(17, 203, 76, 76), Color("081724"))
	if robot_icon != null:
		draw_texture_rect(robot_icon, Rect2(29, 215, 52, 52), false, Color.WHITE if ratio > 0.0 else Color(0.45, 0.48, 0.52))
	else:
		text(Vector2(47, 252), "–", 26, color)
	for segment in range(12):
		var start: float = -PI * 0.5 + TAU * float(segment) / 12.0
		var end: float = start + TAU * 0.075
		var segment_color: Color = color if float(segment) < ratio * 12.0 else Color("34404a")
		draw_arc(center, 35.0, start, end, 3, segment_color, 4.0, true)
	if ratio >= 1.0 and a.summon_cd <= 0.0:
		var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.008)
		draw_arc(center, 39.0, -PI * 0.5, PI * 1.5, 36, Color(color, pulse), 2.0, true)
	text(Vector2(103, 226), "ROBÔ • " + (robot_id.to_upper() if robot_id != "" else "NENHUM"), 13, GOLD)
	text(Vector2(103, 247), state, 13, color)
	text(Vector2(103, 265), detail, 11, Color("b6c8cd"))
	if controls != "": text(Vector2(103, 283), controls, 11)
	text(Vector2(103, 301), switch_hint, 11, GOLD)

func _draw() -> void:
	if app == null or app.sim == null: return
	var s = app.sim
	var ps: bool = app.playstation_controller_connected()
	var id: int = 1 if app.online and not app.hosting else 0
	var a: Dictionary = s.actors[id]
	var portrait_sheet: Texture2D = art.portraits
	var portrait_cell := Vector2(portrait_sheet.get_width() * 0.5, portrait_sheet.get_height())
	var portrait_index := 1 if a.armor else 0
	if s.is_blue_form(a):
		draw_texture_rect_region(portrait_sheet, Rect2(14, 14, 82, 82), Rect2(Vector2.ZERO, portrait_cell), Color(0.125, 0.25, 0.875, 1))
	else:
		draw_texture_rect_region(portrait_sheet, Rect2(14, 14, 82, 82), Rect2(portrait_index * portrait_cell.x, 0, portrait_cell.x, portrait_cell.y))
	# 0.12: vida em corações (1 coração = 10) + corações de escudo Ômega em ciano
	var hearts: int = int(roundf(s.max_hp() / s.HEART))
	var shield_hearts: int = int(ceilf(a.get("shield", 0.0) / s.HEART))
	for n in range(hearts + shield_hearts):
		var hx := 111 + n * 22
		if n < hearts:
			var filled: float = clampf(a.hp / s.HEART - n, 0, 1)
			draw_texture_rect(art.heart, Rect2(hx,18,20,20), false, Color(0.25,0.25,0.3))
			if filled > 0: draw_texture_rect_region(art.heart, Rect2(hx,18,20*filled,20), Rect2(0,0,21*filled,21))
		else:
			var sf: float = clampf(a.shield / s.HEART - (n - hearts), 0, 1)
			draw_texture_rect_region(art.heart, Rect2(hx,18,20*sf,20), Rect2(0,0,21*sf,21), Color(0.4, 1.3, 1.6))
	text(Vector2(111,57), "DASH", 12, CYAN)
	for n in range(6):
		draw_rect(Rect2(153+n*21,46,18,8), CYAN if (1-a.dodge_cd/s.uniform_of(a).dash_cd)*6 > n else Color("1a3548"))
	text(Vector2(111,80), "UNIFORME: " + s.UNIFORMS[a.outfit].name, 13, GOLD)
	# A carga da Ômega acompanha o ícone abaixo do retrato.
	draw_omega_indicator(s, a, ps, id)
	draw_robot_indicator(s, a, ps, id)
	var vp: Vector2 = get_viewport_rect().size
	var dx := vp.x - 1280.0; var dy := vp.y - 800.0   # HUD ancorado nas bordas reais (qualquer proporção)
	if a.mech:
		var box := Rect2(660 + dx * 0.5, 14, 260, 54)
		frame(box)
		var bcd: float = a.get("bomb_cd", 0.0)
		var bomb_ratio: float = clampf(1.0 - bcd / s.MECH_BOMB.cooldown, 0.0, 1.0)
		var bomb_color := Color("ff9a4a") if bcd <= 0 else Color("8a7a58")
		text(box.position + Vector2(12, 22), ("→ • BOMBA PRONTA" if ps else "R • BOMBA PRONTA") if bcd <= 0 else "BOMBA • %.1fs" % bcd, 13, bomb_color)
		draw_rect(Rect2(box.position + Vector2(12, 32), Vector2(236, 10)), Color("1a2430"))
		draw_rect(Rect2(box.position + Vector2(12, 32), Vector2(236 * bomb_ratio, 10)), bomb_color)
	weapon_frame()
	var weapon: String = s.weapon_of(a)
	if weapon == "mech": weapon = "shotgun"
	var wtex: Texture2D = art["w_" + weapon]
	var wsize: Vector2 = wtex.get_size() * minf(1.8, minf(78.0 / wtex.get_size().x, 35.0 / wtex.get_size().y))
	draw_texture_rect(wtex, Rect2(Vector2(351, 43) - wsize * 0.5, wsize), false)
	text(Vector2(405, 49), str(a.get("run_weapons", {}).get(weapon, 0)) if weapon == "bazooka" else "∞", 23, GOLD)
	text(Vector2(311, 82), s.weapon_name(a), 12, CYAN if a.armor else Color("e8dfba"))
	if s.coop != "solo":
		var partner: Dictionary = s.actors[1-id]
		frame(Rect2(466,14,181,54)); text(Vector2(478,36), "PARCEIRO IA" if s.coop == "ai" else "PARCEIRO P2", 13, CYAN)
		text(Vector2(478,55), "CAÍDO • REANIMAR" if partner.dead else "♥ %.1f / %d" % [partner.hp / s.HEART, int(s.max_hp() / s.HEART)], 13)
	if s.streak >= 2:
		# 0.15: sequência de abates — selo com barra de tempo restante
		var pulse := 1.0 + sin(s.tick_time * 12) * 0.06
		draw_set_transform(Vector2(640, 96), 0, Vector2(pulse, pulse))
		text(Vector2(-60, 8), "SEQUÊNCIA ×%d" % s.streak, 18, Color("e8be6e"))
		draw_rect(Rect2(-60, 16, 120, 5), Color("26323a"))
		draw_rect(Rect2(-60, 16, 120 * clampf(s.streak_t / 2.2, 0, 1), 5), Color("e8be6e"))
		draw_set_transform(Vector2(dx, 0))
	else: draw_set_transform(Vector2(dx, 0))
	draw_minimap(s, a)
	draw_set_transform(Vector2(dx, dy))
	frame(Rect2(978,721,288,60))
	for n in range(3):
		var key: String = ["key", "coin", "crystal"][n]
		draw_texture_rect(art[key],Rect2(992+n*87,733,25,32),false)
		text(Vector2(1024+n*87,757), str([s.keys,s.money,s.materials][n]),22)
	draw_set_transform(Vector2(dx * 0.5, dy))
	text(Vector2(468,779), "OPTIONS • MENU / INVENTÁRIO" if ps else "B • EQUIPAMENTO     ESC • MENU", 13, GOLD)
	draw_set_transform(Vector2.ZERO)
	draw_boss_health(s)
	if app.map_open: draw_full_map(s, a)

# ───────── Minimapa e mapa completo (estilo Enter the Gungeon) ─────────
const MAP_ROOM := Color("2f3566")
const MAP_ROOM_DIM := Color("1a1e38")
const MAP_LINE := Color("d9d9ee")

func map_rooms(s) -> Array:
	var out: Array = []
	for room in s.rooms:
		if room.kind == "secret" and not s.secret_open: continue
		out.append(room)
	return out

func room_visible(s, room: Dictionary) -> bool:
	return s.mode != "run" or s.visited.has(room.get("id", ""))

func draw_map_geometry(s, to_screen: Callable, scale_factor: float, clip: Rect2, a: Dictionary) -> void:
	var known: Array = map_rooms(s).filter(func(rm): return room_visible(s, rm))
	var known_corridors: Dictionary = s.visible_corridor_rects()
	for r in s.floors:
		# névoa no mapa: só corredores ligados a salas já visitadas
		if s.mode == "run" and not known_corridors.has(r) and not known.any(func(rm): return r.grow(6).intersects(rm.r)): continue
		var target: Rect2 = Rect2(to_screen.call(r.position), r.size * scale_factor).intersection(clip)
		if target.size.x > 0 and target.size.y > 0: draw_rect(target, MAP_ROOM_DIM)
	for room in map_rooms(s):
		var seen: bool = room_visible(s, room)
		if not seen: continue
		for rr in [room.r] + room.get("extra", []):
			var target: Rect2 = Rect2(to_screen.call(rr.position), rr.size * scale_factor).intersection(clip)
			if target.size.x <= 0 or target.size.y <= 0: continue
			draw_rect(target, Color("5a2030") if room.get("locked", false) else MAP_ROOM)
			draw_rect(target, MAP_LINE if seen else Color("50557a"), false, 2.0 if scale_factor > 0.1 else 1.0)
			if rr.has_point(a.p): draw_rect(target, Color(0.3, 0.9, 1, 0.18))
	for box in s.obstacles:
		if s.mode == "run":
			var br: Dictionary = s.room_at(box.get_center())
			if br.is_empty() or not room_visible(s, br): continue
		var target: Rect2 = Rect2(to_screen.call(box.position), box.size * scale_factor).intersection(clip)
		if target.size.x > 1 and target.size.y > 1: draw_rect(target, Color("8f93b8"))

func map_icon(s, pos: Vector2, kind: String, size: float, done: bool = false) -> void:
	var c := Color.WHITE if not done else Color(0.45, 0.45, 0.5, 0.8)
	var icon: String = {"boss": "map_boss", "shop": "map_shop", "side": "map_challenge", "chest": "map_chest", "locked": "map_locked", "capsule": "map_exit"}.get(kind, "")
	if icon != "":
		if kind == "capsule" and not s.boss_dead: c = Color(0.55, 0.6, 0.65)
		draw_texture_rect(art[icon], Rect2((pos - Vector2(size, size) * 0.5).round(), Vector2(size, size)), false, c)
		return
	match kind:
		"key": draw_texture_rect(art.key_clean, Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), false)
		"titan": draw_texture_rect_region(art.titan, Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), Rect2(0, 0, 176, 176))

func draw_map_icons(s, to_screen: Callable, size: float, clip: Rect2) -> void:
	if s.mode != "run": return
	var P: Dictionary = s.run_points
	var icons: Array = []
	for chest in s.chests:
		if chest.secret and not s.secret_open: continue
		icons.append([chest.p, "chest", chest.open])
	icons.append([P.shop, "shop", s.shop_bought]); icons.append([P.side, "side", s.side_complete or s.side_failed])
	icons.append([P.extraction + Vector2(0, -40), "capsule", false])
	# 0.16: salas descobertas mostram o ícone do tipo (chefe na sala dele; portão trancado no centro)
	for room in s.rooms:
		if room.get("kind", "") == "boss" and not s.boss_dead: icons.append([room.r.get_center() + Vector2(0, 120), "boss", false])
		if room.get("locked", false): icons.append([room.r.get_center(), "locked", false])
	var story: Dictionary = s.room_at(s.story_npc_position())
	if show_story_marker(s.story_quest) and not story.is_empty() and room_visible(s,story):
		var location: Vector2 = to_screen.call(s.story_npc_position())
		if clip.has_point(location): draw_string(ThemeDB.fallback_font,location,"!",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ffd36a"))
	for pk in s.pickups:
		if pk.kind == "key": icons.append([pk.p, "key", false])
	if s.mech.deployed: icons.append([s.mech.p, "titan", false])
	for icon in icons:
		var room: Dictionary = s.room_at(icon[0])
		if not room.is_empty() and not room_visible(s, room): continue
		var sp: Vector2 = to_screen.call(icon[0])
		if clip.has_point(sp): map_icon(s, sp, icon[1], size, icon[2])

func draw_minimap(s, a: Dictionary) -> void:
	frame(Rect2(1086, 14, 180, 112))
	var clip := Rect2(1098, 26, 156, 76)
	var scale_factor := 0.05 if s.mode == "run" else minf(156.0 / 1400.0, 76.0 / 800.0)
	var center: Vector2 = a.p if s.mode == "run" else Vector2(672, 400)
	var to_screen := func(w: Vector2) -> Vector2: return clip.get_center() + (w - center) * scale_factor
	draw_rect(clip, Color("0b0d18"))
	draw_map_geometry(s, to_screen, scale_factor, clip, a)
	draw_map_icons(s, to_screen, 16.0, clip)
	draw_circle(to_screen.call(a.p), 3, CYAN)
	text(Vector2(1100, 118), "TAB / M • MAPA", 11)

func draw_full_map(s, a: Dictionary) -> void:
	var screen := get_viewport_rect()
	draw_rect(screen, Color(0.02, 0.02, 0.05, 0.88))
	var bounds: Rect2 = s.floors[0]
	for r in s.floors: bounds = bounds.merge(r)
	for room in s.rooms: bounds = bounds.merge(room.r)
	var area := Rect2(90, 70, screen.size.x - 180, screen.size.y - 160)
	var scale_factor: float = minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y)
	var origin: Vector2 = area.position + (area.size - bounds.size * scale_factor) / 2 - bounds.position * scale_factor
	var to_screen := func(w: Vector2) -> Vector2: return origin + w * scale_factor
	draw_map_geometry(s, to_screen, scale_factor, screen, a)
	for room in map_rooms(s):
		if room_visible(s, room):
			var tl: Vector2 = to_screen.call(room.r.position)
			text(tl + Vector2(6, 16), room.name, 11, Color("b9bddb"))
	draw_map_icons(s, to_screen, 24.0, screen)
	for other in s.actors:
		if other.active and not other.dead and other.id != a.id: draw_circle(to_screen.call(other.p), 5, GOLD)
	var me: Vector2 = to_screen.call(a.p)
	draw_texture_rect(art.portrait, Rect2(me - Vector2(14, 14), Vector2(28, 28)), false)
	draw_arc(me, 17, 0, TAU, 20, CYAN, 2)
	text(Vector2(90, 50), "DOCAS DE 1941 • MAPA", 22, GOLD)
	text(Vector2(90, screen.size.y - 40), "TAB / M / clique no minimapa para fechar     •  caveira = chefe   saco = oficina   cronômetro = desafio   baú   cadeado = sala trancada   seta = extração", 14, Color("c6c9e0"))

