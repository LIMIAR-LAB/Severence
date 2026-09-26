extends Control
# 0.17: tela de EQUIPAMENTO modular. A moldura (assets/ui/equipamento/equip_moldura.png) é só o fundo:
# ícones, cards, textos, números, barras e seleção são nós separados por cima, controlados pelos dados
# (data/equipamento.json via equipment_data.gd) e pelo estado de desbloqueio da simulação (sim.unlocked).
# Todas as caixas abaixo foram medidas na moldura (espaço 1344x752). Filtro Nearest em tudo.

const DATA := preload("res://scripts/equipment_data.gd")
const DIR := "res://assets/ui/equipamento/"
const SIZE := Vector2(1344, 752)

const UNIFORM_ROW := [Rect2(40, 130, 318, 86), Rect2(40, 222, 318, 81), Rect2(40, 311, 318, 86)]
const UNIFORM_ICON := [Rect2(44, 136, 84, 74), Rect2(44, 225, 84, 75), Rect2(43, 313, 85, 77)]
const ARMOR_SLOT := [Rect2(45, 471, 91, 94), Rect2(158, 472, 87, 93), Rect2(268, 472, 85, 93)]
const ARMOR_TEXT := Rect2(58, 586, 292, 58)
const ROBOT_SLOT := [Rect2(413, 540, 89, 95), Rect2(517, 541, 85, 94), Rect2(616, 541, 88, 94)]
const ROBOT_TEXT := Rect2(728, 540, 200, 100)
const VITRINE := Rect2(410, 100, 525, 370)
const CARD := Rect2(492, 105, 360, 360)
const ARROWS := [Rect2(392, 258, 38, 64), Rect2(912, 258, 38, 64)]
const STAT_Y := [142, 184, 227, 269, 312, 354]   # topo dos segmentos de cada linha
const SEG_X0 := 1044.0
const SEG_STEP := 16.73
const SEG_SIZE := Vector2(15, 15)
const NUM_X := 1257.0
const DESC_TEXT := Rect2(1000, 462, 296, 180)
const TABS := [Rect2(872, 22, 204, 46), Rect2(1084, 22, 210, 46)]
const BACK_BUTTON := Rect2(20, 680, 220, 53)
const REFUGE_BUTTON := Rect2(1062, 680, 266, 53)
const STATUS_LINE := Rect2(390, 30, 440, 22)

const TEAL := Color("5fd6d8")
const GOLD := Color("f3c86a")
const TEXT := Color("d8dccf")
const DIM := Color("7c8a86")
const LOCKED := Color("5d6668")

var host          # TemporalTerminal: dono das escolhas (outfit_choice, robot_choice, armor_choice, gear_actor)
var app
var focus_id := ""                  # item mostrado na vitrine
var slots: Dictionary = {}          # id -> {"button", "icon", "frame", "rect", "name"?...}
var order: Array = []               # ordem das setas ◀ ▶ / LB RB
var card: TextureRect
var card_lock: TextureRect
var seg_rects: Array = []           # [linha][segmento] ColorRect
var numbers: Array = []
var desc_title: Label
var desc_sub: Label
var desc_body: Label
var armor_label: Label
var robot_label: Label
var robot_detail: Label
var status: Label
var tabs: Array = []
var pulse := 0.0

func unlocked(id: String) -> bool:
	return id != "" and app.sim.is_unlocked(id)

func tex(path: String) -> Texture2D:
	return load(path) if path != "" and ResourceLoader.exists(path) else null

func add_label(parent: Control, rect: Rect2, text: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.position = rect.position; l.size = rect.size; l.text = text
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7)); l.add_theme_constant_override("shadow_offset_x", 1); l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(l); return l

func add_image(parent: Control, rect: Rect2, t: Texture2D, centered := true) -> TextureRect:
	# textura desenhada 1:1 (os ícones já foram gerados no tamanho do slot), centrada na caixa
	var r := TextureRect.new(); r.texture = t; r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if centered else TextureRect.STRETCH_KEEP
	r.position = rect.position; r.size = rect.size; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r); return r

func add_frame(rect: Rect2, legendary: bool) -> NinePatchRect:
	var f := NinePatchRect.new(); f.texture = load(DIR + ("icones/frame_lendario.png" if legendary else "icones/frame_selecao.png"))
	f.patch_margin_left = 14; f.patch_margin_right = 14; f.patch_margin_top = 14; f.patch_margin_bottom = 14
	f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var r := rect.grow(4); f.position = r.position; f.size = r.size; f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.visible = false; add_child(f); return f

func flat_button(rect: Rect2, callback: Callable, id := "") -> Button:
	var b := Button.new(); b.position = rect.position; b.size = rect.size; b.flat = true
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]: b.add_theme_stylebox_override(st, empty)
	b.pressed.connect(callback)
	if id != "":
		b.name = "Slot_" + id
		b.focus_entered.connect(func(): show_item(id)); b.mouse_entered.connect(b.grab_focus)
	add_child(b); return b

func outline_button(rect: Rect2, callback: Callable) -> Button:
	# botões desenhados na moldura (VOLTAR, IR AO REFÚGIO, abas): o Button é transparente e só acende a borda
	var b := Button.new(); b.position = rect.position; b.size = rect.size
	var normal := StyleBoxEmpty.new()
	var lit := StyleBoxFlat.new(); lit.bg_color = Color(0.37, 0.84, 0.85, 0.08); lit.border_color = TEAL; lit.set_border_width_all(2); lit.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", normal); b.add_theme_stylebox_override("disabled", normal)
	for st in ["hover", "focus", "pressed"]: b.add_theme_stylebox_override(st, lit)
	b.pressed.connect(callback); add_child(b); return b

func build() -> void:
	size = SIZE; mouse_filter = Control.MOUSE_FILTER_PASS
	var bg := TextureRect.new(); bg.texture = load(DIR + "equip_moldura.png"); bg.size = SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(bg)
	status = add_label(self, STATUS_LINE, "", 12, DIM); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	host.live_status = status
	# abas de jogador (coop local: equipar Marty ou Echo)
	for i in 2:
		var tab := outline_button(TABS[i], func(): host.select_actor(i))
		tab.name = "Tab_%d" % i; tab.focus_mode = Control.FOCUS_NONE
		tab.disabled = i == 1 and not (app.playing and app.sim.coop == "local")
		tabs.append(tab)
	# UNIFORME: 3 linhas
	var uniforms := DATA.by_category("uniforme")
	for i in mini(3, uniforms.size()):
		var it: Dictionary = uniforms[i]
		var row: Rect2 = UNIFORM_ROW[i]
		var entry := {"rect": UNIFORM_ICON[i], "category": "uniforme"}
		entry["icon"] = add_image(self, UNIFORM_ICON[i], null)
		entry["frame"] = add_frame(UNIFORM_ICON[i], false)
		entry["name"] = add_label(self, Rect2(row.position.x + 106, row.position.y + 8, 206, 26), "", 18, TEXT)
		entry["sub"] = add_label(self, Rect2(row.position.x + 106, row.position.y + 33, 206, 20), "", 13, TEAL)
		entry["line"] = add_label(self, Rect2(row.position.x + 106, row.position.y + 54, 206, 18), "", 11, DIM)
		for k in ["name", "sub", "line"]: (entry[k] as Label).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; (entry[k] as Label).clip_text = true
		entry["button"] = flat_button(row, func(): pick(it.id), it.id)
		slots[it.id] = entry; order.append(it.id)
	# ARMADURA: 3 vagas (itens + vagas vazias)
	var armors := DATA.by_category("armadura")
	for i in 3:
		if i < armors.size():
			var it: Dictionary = armors[i]
			var entry := {"rect": ARMOR_SLOT[i], "category": "armadura"}
			entry["icon"] = add_image(self, ARMOR_SLOT[i], null)
			entry["frame"] = add_frame(ARMOR_SLOT[i], it.get("raridade", "") == "lendario")
			entry["button"] = flat_button(ARMOR_SLOT[i], func(): pick(it.id), it.id)
			slots[it.id] = entry; order.append(it.id)
		else:
			add_image(self, ARMOR_SLOT[i], load(DIR + "icones/icon_slot_vazio.png")).name = "EmptyArmor_%d" % i
	armor_label = add_label(self, ARMOR_TEXT, "", 12, TEXT); armor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# VITRINE: card do item em foco + setas
	card = add_image(self, CARD, null, false); card.name = "Card"
	card_lock = add_image(self, Rect2(CARD.get_center() - Vector2(58, 56), Vector2(116, 112)), load(DIR + "icones/icon_cadeado.png"))
	card_lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; card_lock.stretch_mode = TextureRect.STRETCH_SCALE   # 58x56 -> 2x exato
	for s in [0, 1]:
		var step := -1 if s == 0 else 1
		var arrow := outline_button(ARROWS[s], func(): cycle(step))
		arrow.name = "Arrow_%d" % s; arrow.focus_mode = Control.FOCUS_NONE
	# ROBÔ: 3 vagas
	var robots := DATA.by_category("robo")
	for i in 3:
		if i < robots.size():
			var it: Dictionary = robots[i]
			var entry := {"rect": ROBOT_SLOT[i], "category": "robo"}
			entry["icon"] = add_image(self, ROBOT_SLOT[i], null)
			entry["frame"] = add_frame(ROBOT_SLOT[i], it.get("raridade", "") == "lendario")
			entry["button"] = flat_button(ROBOT_SLOT[i], func(): pick(it.id), it.id)
			slots[it.id] = entry; order.append(it.id)
		else:
			add_image(self, ROBOT_SLOT[i], load(DIR + "icones/icon_slot_vazio.png")).name = "EmptyRobot_%d" % i
	robot_label = add_label(self, Rect2(ROBOT_TEXT.position, Vector2(ROBOT_TEXT.size.x, 22)), "", 15, TEXT)
	robot_detail = add_label(self, Rect2(ROBOT_TEXT.position + Vector2(0, 24), ROBOT_TEXT.size - Vector2(0, 24)), "", 11, DIM)
	robot_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# STATUS: 6 linhas × 12 segmentos + número
	for r in STAT_Y.size():
		var row: Array = []
		for s in DATA.SEGMENTS:
			var seg := ColorRect.new(); seg.position = Vector2(roundf(SEG_X0 + s * SEG_STEP), STAT_Y[r]); seg.size = SEG_SIZE
			seg.mouse_filter = Control.MOUSE_FILTER_IGNORE; seg.visible = false; add_child(seg); row.append(seg)
		seg_rects.append(row)
		var num := add_label(self, Rect2(NUM_X, STAT_Y[r] - 5, 45, 25), "", 12, TEXT)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.name = "Stat_%d" % r; numbers.append(num)
	# DESCRIÇÃO
	desc_title = add_label(self, Rect2(DESC_TEXT.position, Vector2(DESC_TEXT.size.x, 24)), "", 17, TEXT)
	desc_sub = add_label(self, Rect2(DESC_TEXT.position + Vector2(0, 24), Vector2(DESC_TEXT.size.x, 18)), "", 11, DIM)
	desc_body = add_label(self, Rect2(DESC_TEXT.position + Vector2(0, 46), DESC_TEXT.size - Vector2(0, 46)), "", 13, TEXT)
	desc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# rodapé: só VOLTAR e IR AO REFÚGIO (desenhados na moldura)
	var back := outline_button(BACK_BUTTON, func(): host.show_screen("main")); back.name = "Back"
	var refuge := outline_button(REFUGE_BUTTON, host.launch_refuge); refuge.name = "Refuge"
	focus_id = host.outfit_choice
	refresh()
	(slots[focus_id].button as Button).grab_focus.call_deferred()

# ── estado ─────────────────────────────────────────────────────────────
func equipped(id: String) -> bool:
	match DATA.item(id).get("categoria", ""):
		"uniforme": return host.outfit_choice == id
		"armadura": return host.armor_choice == id
		"robo": return host.robot_choice == id
	return false

func pick(id: String) -> void:
	# clicar/confirmar: equipa se estiver desbloqueado; bloqueado só mostra como desbloquear
	focus_id = id
	if not unlocked(id):
		status.text = "%s ainda bloqueado." % DATA.item(id).get("nome", id); refresh(); return
	match DATA.item(id).categoria:
		"uniforme": host.outfit_choice = id
		"robo": host.robot_choice = id
		"armadura": host.armor_choice = id
	if not host.apply_gear() and app.playing and not app.online:
		var a: Dictionary = app.sim.actors[host.gear_actor]
		host.outfit_choice = a.outfit; host.robot_choice = a.selected_robot
	refresh()

func show_item(id: String) -> void:
	focus_id = id; refresh()

func cycle(step: int) -> void:
	var i := (order.find(focus_id) + step + order.size()) % order.size()
	focus_id = order[i]
	(slots[focus_id].button as Button).grab_focus()
	refresh()

# ── desenho ────────────────────────────────────────────────────────────
func refresh() -> void:
	for id in slots:
		var it := DATA.item(id)
		var e: Dictionary = slots[id]
		var open := unlocked(id)
		e.icon.texture = tex(it.icone) if open or it.get("icone_bloqueado", "") == "" else tex(it.icone_bloqueado)
		if not open and it.get("icone_bloqueado", "") == "": e.icon.texture = load(DIR + "icones/icon_cadeado.png")
		var legendary: bool = it.get("raridade", "") == "lendario"
		e.frame.visible = open and (equipped(id) or legendary) or id == focus_id
		e.frame.modulate = Color.WHITE
		if e.has("name"):
			e.name.text = it.nome
			e.name.add_theme_color_override("font_color", TEAL if equipped(id) else (TEXT if open else LOCKED))
			e.sub.text = it.get("subtitulo", "") if open else "BLOQUEADO"
			e.sub.add_theme_color_override("font_color", Color(it.get("cor", "5fd6d8")) if open else LOCKED)
			e.line.text = it.get("arma", "") if open else it.desbloqueio.get("texto", "")
	# armadura e robô equipados
	var armor := DATA.item(host.armor_choice)
	armor_label.text = ("%s • %s" % [armor.nome, armor.descricao_curta]) if unlocked(host.armor_choice) else "Nenhuma armadura. As armaduras aparecem aqui quando forem desbloqueadas."
	armor_label.add_theme_color_override("font_color", GOLD if unlocked(host.armor_choice) else DIM)
	var robot := DATA.item(host.robot_choice)
	if unlocked(host.robot_choice):
		robot_label.text = robot.nome; robot_detail.text = robot.descricao_curta + telemetry()
	else:
		robot_label.text = "SEM ROBÔ"; robot_detail.text = "Os robôs aparecem aqui quando forem encontrados."
	# vitrine
	var focus := DATA.item(focus_id)
	var open := unlocked(focus_id)
	card.texture = tex(focus.get("card", ""))
	card.modulate = Color.WHITE if open else Color(0.2, 0.2, 0.26)
	card_lock.visible = not open
	# descrição
	desc_title.text = focus.get("nome", "")
	desc_title.add_theme_color_override("font_color", GOLD if focus.get("raridade", "") == "lendario" else (TEAL if open else LOCKED))
	var rarity: String = {"lendario": "★ LENDÁRIA", "raro": "RARO", "comum": "COMUM"}.get(focus.get("raridade", ""), "")
	desc_sub.text = "%s • %s%s" % [focus.get("categoria", "").to_upper().replace("ROBO", "ROBÔ"), rarity, "" if open else " • BLOQUEADO"]
	desc_body.text = focus.get("descricao", "") if open else "Como desbloquear: " + focus.get("desbloqueio", {}).get("texto", "")
	draw_stats()
	# abas
	for i in tabs.size():
		(tabs[i] as Button).add_theme_color_override("font_color", TEAL)
		var lit := StyleBoxFlat.new(); lit.bg_color = Color(0.37, 0.84, 0.85, 0.06); lit.border_color = TEAL if i == host.gear_actor else Color(0, 0, 0, 0); lit.set_border_width_all(2); lit.set_corner_radius_all(4)
		(tabs[i] as Button).add_theme_stylebox_override("normal", lit)
		(tabs[i] as Button).modulate = Color(1, 1, 1, 0.45) if tabs[i].disabled else Color.WHITE

func telemetry() -> String:
	if not app.playing: return ""
	if host.robot_choice == "titan": return "\nIntegridade %d • gasolina %d%%" % [app.sim.mech.hp, int(app.sim.mech.get("fuel", 0.0))]
	return "\nEnergia %d" % app.sim.spectres[host.gear_actor].hp

# STATUS: combinação equipada; se o foco está num item desbloqueado, mostra a combinação com ele.
func preview_combo() -> Array:
	var outfit: String = host.outfit_choice
	var armor: String = host.armor_choice if unlocked(host.armor_choice) else ""
	var robot: String = host.robot_choice if unlocked(host.robot_choice) else ""
	if unlocked(focus_id):
		match DATA.item(focus_id).categoria:
			"uniforme": outfit = focus_id
			"armadura": armor = focus_id
			"robo": robot = focus_id
	return [outfit, armor, robot]

func draw_stats() -> void:
	var combo := preview_combo()
	var values := DATA.combine(combo[0], combo[1], combo[2])
	var stats := DATA.stats()
	for r in mini(stats.size(), STAT_Y.size()):
		var st: Dictionary = stats[r]
		var color := Color(st.get("cor", "5fd6d8"))
		var base_n := DATA.segments(st.id, values.base[st.id])
		var final_n := DATA.segments(st.id, values.final[st.id])
		for s in DATA.SEGMENTS:
			var seg: ColorRect = seg_rects[r][s]
			seg.visible = s < maxi(base_n, final_n)
			if s < mini(base_n, final_n): seg.color = color.darkened(0.15)          # base do uniforme
			elif s < final_n: seg.color = color.lightened(0.45)                    # bônus da armadura/robô
			else: seg.color = Color(0.45, 0.12, 0.14, 0.8)                          # perda (ex.: Titan é mais lento)
		numbers[r].text = DATA.format(st.id, values.final[st.id])
		numbers[r].add_theme_color_override("font_color", color.lightened(0.3) if values.final[st.id] != values.base[st.id] else TEXT)

func _process(dt: float) -> void:
	# o slot em foco pisca de leve (o equipado fica aceso fixo)
	pulse += dt
	if slots.has(focus_id) and not equipped(focus_id):
		slots[focus_id].frame.modulate = Color(1, 1, 1, 0.55 + 0.45 * absf(sin(pulse * 3.0)))
