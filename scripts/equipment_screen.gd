extends Control

# 0.20: shell de Equipamento em abas. Catálogo/estado ficam fora da apresentação.
const DATA := preload("res://scripts/equipment_data.gd")
const InventoryData := preload("res://scripts/inventory_data.gd")
const InventoryState := preload("res://scripts/inventory_state.gd")
const DIR := "res://assets/ui/equipamento/"
const SIZE := Vector2(1344, 752)
const TAB_NAMES := ["INVENTÁRIO", "ROBÔS", "ÔMEGA", "EQUIPADOS", "ATRIBUTOS"]
const FILTERS := [["todos", "TODOS"], ["armas", "UNIFORMES"], ["pecas", "ROBÔS"], ["consumiveis", "ÔMEGA"], ["recursos", "EXPEDIÇÃO"]]
const TEAL := Color("54e4e7")
const GOLD := Color("efc56b")
const TEXT := Color("dce8df")
const DIM := Color("83968e")
const IMPROVEMENT := Color("73e06f")
const REGRESSION := Color("ff6b6b")
const PANEL := Color("102b25")
const BRASS := Color("a87732")
const RARITY := {"comum": Color("aab8b4"), "incomum": Color("67d591"), "raro": Color("57a8ff"), "especial": Color("d186ff"), "lendario": Color("ffc34f")}

var host
var app
var inventory: RefCounted
var active_tab := 0
var focus_id := ""
var slots: Dictionary = {}
var order: Array = ["padrao", "mecanico", "espiao", "omega", "titan", "spectre"]
var card: TextureRect
var card_lock: TextureRect
var numbers: Array = []
var robot_label: Label
var desc_body: Label
var status: Label
var tabs: Array = []
var page: Control
var detail_title: Label
var detail_rarity: Label
var detail_text: Label
var detail_stats: Label
var detail_description_panel: Panel
var comparison_panel: Panel
var comparison_scroll: ScrollContainer
var comparison_rich: RichTextLabel
var detail_action: Button
var detail_compare: Button
var detail_reason: Label
var capacity_label: Label
var grid_buttons: Array = []
var inventory_page := 0
var mission_mode := false
var mission_signature := ""

func tex(path: String) -> Texture2D:
	return load(path) if path != "" and ResourceLoader.exists(path) else null

func make_style(bg: Color, border: Color, width := 2, radius := 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = bg; box.border_color = border
	box.set_border_width_all(width); box.set_corner_radius_all(radius); return box

func panel(parent: Control, rect: Rect2, bg := PANEL, border := BRASS) -> Panel:
	var p := Panel.new(); p.position = rect.position; p.size = rect.size; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", make_style(bg, border)); parent.add_child(p); return p

func label(parent: Control, rect: Rect2, caption: String, font_size := 16, color := TEXT) -> Label:
	var node := Label.new(); node.position = rect.position; node.size = rect.size; node.text = caption
	node.add_theme_font_size_override("font_size", font_size); node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8)); node.add_theme_constant_override("shadow_offset_x", 1); node.add_theme_constant_override("shadow_offset_y", 1)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(node); return node

func button(parent: Control, rect: Rect2, caption: String, callback: Callable, name_value := "") -> Button:
	var b := Button.new(); b.position = rect.position; b.size = rect.size; b.text = caption
	b.add_theme_font_size_override("font_size", 15); b.add_theme_color_override("font_color", TEXT)
	b.add_theme_stylebox_override("normal", make_style(Color("102d27"), Color("5e683e")))
	b.add_theme_stylebox_override("hover", make_style(Color("15433c"), TEAL, 3))
	b.add_theme_stylebox_override("focus", make_style(Color("123c38"), TEAL, 3))
	b.add_theme_stylebox_override("pressed", make_style(Color("17605e"), TEAL, 3))
	b.add_theme_stylebox_override("disabled", make_style(Color("101918"), Color("3d4844")))
	b.pressed.connect(callback)
	if name_value != "": b.name = name_value
	parent.add_child(b); return b

func image(parent: Control, rect: Rect2, texture: Texture2D) -> TextureRect:
	var node := TextureRect.new(); node.position = rect.position; node.size = rect.size; node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; node.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(node); return node

func build() -> void:
	size = SIZE; mouse_filter = Control.MOUSE_FILTER_PASS
	var legacy_bg := TextureRect.new(); legacy_bg.texture = load(DIR + "equip_moldura.png"); legacy_bg.size = SIZE
	legacy_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; legacy_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(legacy_bg)
	var veil := ColorRect.new(); veil.color = Color("06110fee"); veil.size = SIZE; veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(veil)
	build_header()
	status = label(self, Rect2(455, 707, 625, 25), "", 13, DIM); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.live_status = status
	var back := button(self, Rect2(24, 699, 190, 38), "ESC / ○  VOLTAR" if app.playstation_controller_connected() else "ESC / B  VOLTAR", go_back, "Back")
	var launch := button(self, Rect2(1093, 699, 225, 38), "VOLTAR À PAUSA" if mission_mode else "IR AO REFÚGIO", go_back if mission_mode else host.launch_refuge, "Refuge")
	back.add_theme_color_override("font_color", GOLD); launch.add_theme_color_override("font_color", GOLD)
	build_compatibility_nodes()
	inventory = InventoryState.new(app.sim.inventory_state)
	if mission_mode:
		# A missão sempre abre a visão completa: um filtro persistido no Refúgio
		# não pode esconder o outro módulo de robô durante a troca rápida.
		inventory.set_filter("todos")
	else:
		sync_entitlements()
	focus_id = host.outfit_choice
	refresh_compat()
	show_tab(0)
	mission_signature = current_mission_signature()
	focus_initial.call_deferred()

func focus_initial() -> void:
	if is_inside_tree() and not tabs.is_empty(): (tabs[0] as Button).grab_focus()


func go_back() -> void:
	host.show_screen("pause" if mission_mode else "play")

func build_header() -> void:
	panel(self, Rect2(18, 14, 1308, 70), Color("18362b"), BRASS)
	var title := label(self, Rect2(38, 25, 170 if mission_mode else 285, 48), "MISSÃO" if mission_mode else "EQUIPAMENTO", 30, GOLD)
	title.add_theme_color_override("font_outline_color", Color("5b2e13")); title.add_theme_constant_override("outline_size", 3)
	if mission_mode and not app.online and app.sim.actors.size() > 1 and app.sim.actors[1].get("active", false):
		button(self, Rect2(212, 30, 105, 38), "P%d • TROCAR" % (host.gear_actor + 1), toggle_actor, "ActorToggle")
	for i in TAB_NAMES.size():
		var tab := button(self, Rect2(330 + i * 195, 24, 184, 48), TAB_NAMES[i], func(): show_tab(i), "MenuTab_%d" % i)
		tab.focus_entered.connect(func():
			if active_tab != i: show_tab(i))
		tabs.append(tab)
	for i in tabs.size():
		var prev: Button = tabs[(i - 1 + tabs.size()) % tabs.size()]
		var next: Button = tabs[(i + 1) % tabs.size()]
		tabs[i].focus_neighbor_left = tabs[i].get_path_to(prev); tabs[i].focus_neighbor_right = tabs[i].get_path_to(next)

func update_tabs() -> void:
	for i in tabs.size():
		var b: Button = tabs[i]
		b.add_theme_color_override("font_color", TEAL if i == active_tab else GOLD)
		b.add_theme_stylebox_override("normal", make_style(Color("15534f") if i == active_tab else Color("102d27"), TEAL if i == active_tab else Color("5e683e"), 3 if i == active_tab else 2))

func show_tab(index: int) -> void:
	active_tab = clampi(index, 0, TAB_NAMES.size() - 1); update_tabs()
	if page != null: remove_child(page); page.queue_free()
	page = Control.new(); page.position = Vector2(18, 94); page.size = Vector2(1308, 592); add_child(page)
	match active_tab:
		0: build_inventory()
		1: build_equipment_category("robo", "ROBÔS", "Unidades de combate e apoio")
		2: build_equipment_category("armadura", "ÔMEGA", "Poder temporário • ative com R durante a expedição")
		3: build_equipped()
		4: build_status()

func sync_entitlements() -> void:
	for entry in InventoryData.valid_items():
		if entry.get("equipavel", false) == true and InventoryData.unlocked(entry, app.sim.unlocked) and inventory.quantity(entry.id) == 0:
			inventory.add(entry.id, 1)
	app.sim.inventory_state = inventory.to_dict()

func set_inventory_filter(filter_id: String) -> void:
	inventory_page = 0; inventory.set_filter(filter_id)
	if not mission_mode: app.sim.inventory_state = inventory.to_dict()
	rebuild_current()

func carried(entry: Dictionary) -> bool:
	var loadout := str(entry.get("loadout_id", ""))
	match str(entry.get("slot", "")):
		"uniforme": return loadout == host.outfit_choice
		"robo": return loadout != "" and loadout == host.robot_choice
		"armadura": return loadout != "" and loadout == host.armor_choice
	return false

func quantity_for(entry: Dictionary) -> int:
	if not entry.get("transiente", false):
		if mission_mode:
			if entry.get("slot", "") == "robo": return inventory.quantity(entry.id)
			return 1 if carried(entry) else 0
		return inventory.quantity(entry.id)
	var mission_actor: Dictionary = app.sim.actors[host.gear_actor] if host.gear_actor >= 0 and host.gear_actor < app.sim.actors.size() else {}
	match str(entry.id):
		"missao_bazuca": return 1 if mission_actor.get("run_weapons", {}).has("bazooka") else 0
		"missao_foguetes": return maxi(0, int(mission_actor.get("run_weapons", {}).get("bazooka", 0)))
		"missao_chaves": return maxi(0, int(app.sim.keys))
		"missao_moedas": return maxi(0, int(app.sim.money))
		"missao_fragmentos": return maxi(0, int(app.sim.materials) - int(app.sim.run_materials_start))
		"missao_combustivel":
			if host.robot_choice != "titan": return 0
			return clampi(roundi(float(app.sim.mech.get("fuel", 0.0)) / maxf(app.sim.FUEL_MAX, 1.0) * 100.0), 0, 100)
		"missao_energia":
			if host.robot_choice != "spectre": return 0
			if host.gear_actor >= 0 and host.gear_actor < app.sim.spectres.size(): return clampi(roundi(float(app.sim.spectres[host.gear_actor].get("hp", 0.0))), 0, 100)
	return 0

func inventory_entry_visible(entry: Dictionary) -> bool:
	if entry.get("prototipo", false) or entry.id in ["missao_combustivel", "missao_energia"]: return false
	if mission_mode:
		return quantity_for(entry) > 0
	return entry.get("transiente", false) != true

func matches_filter(entry: Dictionary) -> bool:
	match inventory.filter:
		"armas": return entry.get("slot", "") == "uniforme"
		"pecas": return entry.get("slot", "") == "robo"
		"consumiveis": return entry.get("slot", "") == "armadura"
		"recursos": return entry.get("transiente", false)
	return true

func item_role(entry: Dictionary) -> String:
	match entry.get("slot", ""):
		"uniforme": return "UNIFORME + ARMA"
		"robo": return "ROBÔ"
		"armadura": return "PODER TEMPORÁRIO"
	return "EXPEDIÇÃO"

func build_inventory() -> void:
	panel(page, Rect2(0, 0, 210, 592), Color("122c25"), BRASS)
	label(page, Rect2(20, 16, 170, 30), "FILTROS", 19, GOLD)
	for i in FILTERS.size():
		var filter_id: String = FILTERS[i][0]
		var b := button(page, Rect2(14, 58 + i * 63, 182, 50), FILTERS[i][1], func(): set_inventory_filter(filter_id), "Filter_%s" % filter_id)
		if inventory.filter == filter_id: b.add_theme_stylebox_override("normal", make_style(Color("15534f"), TEAL, 3))
	var note := "Equipamentos e recursos\ndesta missão.\n\nCombustível e energia\ndo robô ficam na\naba ATRIBUTOS." if mission_mode else "Escolha seu uniforme\ne robô para partir.\n\nArmas e recursos\nencontrados aparecem\ndurante a expedição."
	label(page, Rect2(18, 395, 176, 150), note, 13, DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel(page, Rect2(222, 0, 650, 592), Color("091d1d"), BRASS)
	label(page, Rect2(244, 14, 380, 32), "INVENTÁRIO DA MISSÃO" if mission_mode else "EQUIPAMENTO", 22, GOLD)
	grid_buttons.clear()
	var all: Array = InventoryData.valid_items().filter(func(entry): return inventory_entry_visible(entry) and matches_filter(entry))
	all.sort_custom(InventoryData.compare)
	capacity_label = label(page, Rect2(700, 17, 150, 28), "%d ITENS" % all.size(), 18, TEXT); capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var page_count := maxi(1, ceili(all.size() / 20.0)); inventory_page = clampi(inventory_page, 0, page_count - 1)
	var offset := inventory_page * 20
	for i in 20:
		var col := i % 5; var row := i / 5; var rect := Rect2(240 + col * 123, 58 + row * 126, 108, 110)
		if offset + i < all.size(): build_inventory_slot(all[offset + i], rect)
		else:
			var empty := panel(page, rect, Color("081716"), Color("334b48")); empty.name = "InventoryEmpty_%d" % i
	if page_count > 1:
		var previous := button(page, Rect2(242, 552, 100, 32), "<", func(): inventory_page -= 1; rebuild_current(), "InventoryPrevious")
		var next := button(page, Rect2(754, 552, 100, 32), ">", func(): inventory_page += 1; rebuild_current(), "InventoryNext")
		previous.disabled = inventory_page == 0; next.disabled = inventory_page == page_count - 1
		var page_number := label(page, Rect2(460, 554, 180, 28), "PÁGINA %d / %d" % [inventory_page + 1, page_count], 13, DIM); page_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_details_panel()
	if inventory.selected_id == "" or not all.any(func(entry): return entry.id == inventory.selected_id): inventory.selected_id = str(all[0].id) if not all.is_empty() else ""
	refresh_inventory_details()

func build_inventory_slot(entry: Dictionary, rect: Rect2) -> void:
	var open: bool = entry.get("transiente", false) == true or InventoryData.unlocked(entry, app.sim.unlocked)
	var owned: bool = quantity_for(entry) > 0
	var selected: bool = inventory.selected_id == entry.id
	var border: Color = TEAL if selected else RARITY.get(entry.get("raridade", "comum"), DIM)
	var p := panel(page, rect, Color("0d2525") if open else Color("101617"), border)
	var icon := image(p, Rect2(10, 7, 88, 68), tex(entry.get("icone", ""))); icon.modulate = Color.WHITE if open and owned else Color(0.25, 0.3, 0.3)
	var qty: int = quantity_for(entry)
	var slot_caption := str(entry.nome).trim_prefix("UNIFORME ") if entry.get("slot", "") == "uniforme" else str(entry.nome)
	label(p, Rect2(7, 79, 95, 24), slot_caption, 11, TEXT if open else DIM).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if qty > 1:
		var q := label(p, Rect2(73, 55, 29, 25), str(qty), 15, GOLD); q.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not open:
		var lock := label(p, Rect2(74, 4, 28, 26), "X", 14, DIM); lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	elif not owned: label(p, Rect2(3, 3, 102, 20), "NÃO OBTIDO", 9, DIM)
	if not entry.get("transiente", false) and carried(entry):
		label(p, Rect2(3, 3, 60, 20), "EQUIP.", 10, TEAL).name = "EquippedBadge_%s" % entry.id
	var hit := Button.new(); hit.flat = true; hit.position = rect.position; hit.size = rect.size; hit.name = "InventorySlot_%s" % entry.id
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); hit.add_theme_stylebox_override("pressed", make_style(Color(0, 0, 0, 0), TEAL, 4))
	hit.add_theme_stylebox_override("hover", make_style(Color(0.1, 0.8, 0.8, 0.05), TEAL, 3)); hit.add_theme_stylebox_override("focus", make_style(Color(0.1, 0.8, 0.8, 0.05), TEAL, 4))
	hit.focus_entered.connect(func(): select_inventory(entry.id)); hit.pressed.connect(func(): select_inventory(entry.id))
	page.add_child(hit); grid_buttons.append(hit)

func build_details_panel() -> void:
	panel(page, Rect2(884, 0, 424, 592), Color("0b2626"), BRASS)
	detail_title = label(page, Rect2(908, 20, 374, 42), "", 25, GOLD)
	detail_rarity = label(page, Rect2(908, 61, 374, 28), "", 15, TEAL)
	detail_description_panel = panel(page, Rect2(906, 98, 380, 158), Color("071b1d"), Color("316b69"))
	detail_text = label(page, Rect2(922, 112, 348, 130), "", 14, TEXT); detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_stats = label(page, Rect2(910, 276, 368, 142), "", 15, TEXT); detail_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_panel = panel(page, Rect2(906, 98, 380, 342), Color("071b1d"), Color("316b69")); comparison_panel.visible = false
	comparison_scroll = ScrollContainer.new(); comparison_scroll.name = "InventoryComparisonScroll"
	comparison_scroll.position = Vector2(916, 108); comparison_scroll.size = Vector2(360, 322)
	comparison_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; comparison_scroll.visible = false
	comparison_scroll.focus_mode = Control.FOCUS_ALL; comparison_scroll.gui_input.connect(handle_comparison_scroll_input)
	comparison_rich = RichTextLabel.new(); comparison_rich.name = "InventoryComparisonText"
	comparison_rich.bbcode_enabled = true; comparison_rich.fit_content = true
	comparison_rich.custom_minimum_size = Vector2(338, 0); comparison_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	comparison_rich.add_theme_font_size_override("normal_font_size", 13)
	comparison_scroll.add_child(comparison_rich); page.add_child(comparison_scroll)
	detail_action = button(page, Rect2(908, 454, 180, 50), "EQUIPAR", equip_selected_inventory, "InventoryAction")
	detail_compare = button(page, Rect2(1102, 454, 180, 50), "COMPARAR", show_comparison, "InventoryCompare")
	detail_reason = label(page, Rect2(908, 516, 374, 55), "", 13, DIM); detail_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_compare.tooltip_text = "Compara com o item equipado."
	detail_compare.focus_neighbor_top = detail_compare.get_path_to(comparison_scroll)
	comparison_scroll.focus_neighbor_bottom = comparison_scroll.get_path_to(detail_compare)

func handle_comparison_scroll_input(event: InputEvent) -> void:
	if not comparison_scroll.visible or not event.is_pressed(): return
	var direction := 0
	if event.is_action_pressed("ui_down") or (event is InputEventKey and event.keycode == KEY_PAGEDOWN): direction = 1
	elif event.is_action_pressed("ui_up") or (event is InputEventKey and event.keycode == KEY_PAGEUP): direction = -1
	if direction == 0: return
	var bar := comparison_scroll.get_v_scroll_bar()
	var limit := maxi(0, roundi(bar.max_value - bar.page))
	var target := clampi(comparison_scroll.scroll_vertical + direction * 56, 0, limit)
	if target == comparison_scroll.scroll_vertical and direction > 0:
		detail_compare.grab_focus()
	else:
		comparison_scroll.scroll_vertical = target
	comparison_scroll.accept_event()

func select_inventory(id: String) -> void:
	inventory.selected_id = id
	if not mission_mode: app.sim.inventory_state = inventory.to_dict()
	refresh_inventory_details()

func refresh_inventory_details() -> void:
	if detail_title == null: return
	reset_comparison_view()
	detail_stats.position.y = 276; detail_stats.size.y = 142
	detail_stats.add_theme_font_size_override("font_size", 13)
	var entry := InventoryData.item(inventory.selected_id)
	if entry.is_empty():
		detail_title.text = "INVENTÁRIO VAZIO"; detail_rarity.text = ""; detail_text.text = "Nenhum item corresponde ao filtro."; detail_stats.text = ""; detail_action.disabled = true; detail_reason.text = "Selecione outro filtro."; return
	var transient: bool = entry.get("transiente", false) == true
	var open: bool = transient or InventoryData.unlocked(entry, app.sim.unlocked)
	detail_title.text = entry.nome
	detail_rarity.text = "%s • %s%s" % [item_role(entry), str(entry.raridade).to_upper(), " • BLOQUEADO" if not open else ""]
	detail_rarity.add_theme_color_override("font_color", RARITY.get(entry.get("raridade", "comum"), TEXT))
	detail_text.text = entry.get("descricao", "") if open else "Como desbloquear: " + DATA.item(entry.get("desbloqueio_id", "")).get("desbloqueio", {}).get("texto", "Prossiga na campanha.")
	var lines: Array[String] = []
	if transient: lines.append("QUANTIDADE  %d" % quantity_for(entry))
	if entry.id == "missao_bazuca":
		var mission_actor: Dictionary = app.sim.actors[host.gear_actor] if host.gear_actor >= 0 and host.gear_actor < app.sim.actors.size() else {}
		lines.append("FOGUETES  %d" % int(mission_actor.get("run_weapons", {}).get("bazooka", 0)))
		lines.append("ESTADO  %s" % ("EM USO" if mission_actor.get("run_weapon", "") == "bazooka" and not mission_actor.get("armor", false) and not mission_actor.get("mech", false) else "GUARDADA"))
	if entry.id == "missao_bazuca":
		lines.append("DANO DIRETO  %d" % app.sim.WEAPONS.bazooka.damage)
	var loadout_id := str(entry.get("loadout_id", ""))
	if loadout_id != "":
		var kind := "uniform" if entry.get("slot", "") == "uniforme" else loadout_id
		for row in reference_rows(kind, loadout_id):
			if lines.size() >= 7: break
			lines.append("%s  %s" % [str(row[0]), str(row[1])])
	detail_stats.text = "\n".join(lines) if not lines.is_empty() else "SEM ATRIBUTOS ATIVOS"
	var usable: bool = not transient and entry.get("equipavel", false) == true and not entry.get("prototipo", false) and quantity_for(entry) > 0 and open
	if entry.id == "missao_bazuca" and mission_mode and quantity_for(entry) > 0:
		var actor: Dictionary = app.sim.actors[host.gear_actor]
		usable = actor.active and not actor.dead and not actor.mech and not actor.armor
	detail_action.visible = not transient or entry.id == "missao_bazuca"
	detail_action.disabled = not usable
	detail_action.text = "EQUIPADO" if carried(entry) else "EQUIPAR"
	if entry.id == "missao_bazuca":
		detail_action.text = "ARMA BÁSICA" if app.sim.actors[host.gear_actor].get("run_weapon", "") == "bazooka" else "EQUIPAR"
	if not open: detail_reason.text = "Ação indisponível: item bloqueado."
	elif entry.id == "missao_fragmentos": detail_reason.text = "Ganho desta missão • preservado entre expedições."
	elif transient: detail_reason.text = (("Saia do Titan ou da armadura e esteja vivo para trocar." if not usable else ("Arma temporária • Q/R1 também alterna; vazia continua selecionável." if app.playstation_controller_connected() else "Arma temporária • Q/RB também alterna; vazia continua selecionável.")) if entry.id == "missao_bazuca" else "Recurso temporário • utilizado durante a expedição.")
	elif quantity_for(entry) <= 0: detail_reason.text = "Ação indisponível: item ainda não obtido."
	elif entry.get("prototipo", false): detail_reason.text = "Ação indisponível: protótipo sem mecânica implementada."
	elif entry.get("equipavel", false) != true: detail_reason.text = "Este item não ocupa um slot equipável."
	else: detail_reason.text = "Compatível com o slot: " + str(entry.get("slot", "")).to_upper()

func equip_selected_inventory() -> void:
	var id: String = inventory.selected_id
	var previous_inventory: Dictionary = inventory.to_dict()
	var previous_outfit: String = host.outfit_choice; var previous_robot: String = host.robot_choice; var previous_armor: String = host.armor_choice
	var entry := InventoryData.item(id); var loadout := str(entry.get("loadout_id", ""))
	if id == "missao_bazuca" and mission_mode:
		var target := "" if app.sim.actors[host.gear_actor].get("run_weapon", "") == "bazooka" else "bazooka"
		if app.request_run_weapon(host.gear_actor, target):
			status.text = "Solicitado ao anfitrião; aguardando confirmação." if app.online and not app.hosting else ("Arma básica equipada." if target == "" else "Bazuca equipada.")
		else: status.text = "Troca indisponível: saia do Titan/armadura e verifique a arma obtida."
		refresh_inventory_details(); return
	if entry.get("transiente", false): status.text = "Recursos da missão são usados pelas regras da expedição."; return
	if not mission_mode and not inventory.equip(id, app.sim.unlocked): status.text = inventory.last_error; refresh_inventory_details(); return
	match str(entry.get("slot", "")):
		"uniforme": host.outfit_choice = loadout
		"robo": host.robot_choice = loadout
		"armadura": host.armor_choice = loadout
	if host.apply_gear():
		if mission_mode and app.online and not app.hosting:
			host.outfit_choice = previous_outfit; host.robot_choice = previous_robot; host.armor_choice = previous_armor
			status.text = "Solicitado ao anfitrião; aguardando confirmação."
		else: status.text = "%s equipado." % entry.nome
	else:
		host.outfit_choice = previous_outfit; host.robot_choice = previous_robot; host.armor_choice = previous_armor
		inventory.from_dict(previous_inventory); status.text = "Não é possível trocar o equipamento agora."
	if not mission_mode: app.sim.inventory_state = inventory.to_dict()
	rebuild_current()

func comparison_values(entry: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	for key in entry.get("atributos", {}):
		values[str(key).to_upper().replace("_", " ")] = {"display": str(entry.atributos[key]), "score": null}
	var loadout := str(entry.get("loadout_id", ""))
	if loadout != "":
		for row in reference_rows("uniform" if entry.get("slot", "") == "uniforme" else loadout, loadout):
			values[str(row[0])] = {"display": str(row[1]), "score": row[2] if row.size() > 2 and float(row[2]) >= 0.0 else null}
	return values

func reset_comparison_view() -> void:
	if comparison_panel == null: return
	comparison_panel.visible = false; comparison_scroll.visible = false; comparison_rich.text = ""
	detail_description_panel.visible = true; detail_text.visible = true; detail_stats.visible = true
	detail_stats.position.y = 276; detail_stats.size.y = 142
	detail_stats.add_theme_font_size_override("font_size", 13)

func comparison_tone(before: Dictionary, after: Dictionary) -> String:
	var before_display := str(before.get("display", "—")); var after_display := str(after.get("display", "—"))
	if before_display == after_display: return "neutral"
	var before_score = before.get("score"); var after_score = after.get("score")
	if before_score == null or after_score == null: return "changed"
	if is_equal_approx(float(before_score), float(after_score)): return "neutral"
	return "improvement" if float(after_score) > float(before_score) else "regression"

func comparison_color(tone: String) -> Color:
	match tone:
		"improvement": return IMPROVEMENT
		"regression": return REGRESSION
		"changed": return TEAL
	return TEXT

func bbcode_color(color: Color) -> String:
	return color.to_html(false)

func comparison_markup(title: String, before: Dictionary, after: Dictionary, keys: Array) -> String:
	var rows: Array[String] = ["[color=#%s][b]%s[/b][/color]" % [bbcode_color(GOLD), title]]
	for key in keys:
		var previous: Dictionary = before.get(key, {"display": "—", "score": null})
		var selected: Dictionary = after.get(key, {"display": "—", "score": null})
		var tone := comparison_tone(previous, selected)
		rows.append("[color=#%s]%s:  %s  →  [/color][color=#%s]%s[/color]" % [bbcode_color(DIM), str(key), str(previous.display), bbcode_color(comparison_color(tone)), str(selected.display)])
	# A linha em branco mantém rótulo, origem, seta e destino legíveis em telas menores;
	# comparações longas passam a usar a rolagem em vez de comprimir ou transbordar.
	return "\n\n".join(rows)

func display_comparison(title: String, before: Dictionary, after: Dictionary) -> void:
	var keys: Array = before.keys()
	for key in after:
		if not keys.has(key): keys.append(key)
	detail_description_panel.visible = false; detail_text.visible = false; detail_stats.visible = false
	comparison_panel.visible = true; comparison_scroll.visible = true
	comparison_rich.text = comparison_markup(title, before, after, keys)
	comparison_scroll.scroll_vertical = 0
	comparison_scroll.grab_focus.call_deferred()

func show_comparison() -> void:
	var entry := InventoryData.item(inventory.selected_id)
	if entry.is_empty(): return
	if entry.id == "missao_bazuca":
		var basic: String = app.sim.uniform_of(app.sim.actors[host.gear_actor]).weapon
		var gun: Dictionary = app.sim.WEAPONS[basic]
		var rocket: Dictionary = app.sim.WEAPONS.bazooka
		var before := {
			"DANO / TIRO": {"display": str(int(gun.damage * gun.count)), "score": float(gun.damage * gun.count)},
			"INTERVALO": {"display": "%.2fs" % gun.cooldown, "score": 1.0 / float(gun.cooldown)},
			"MUNIÇÃO": {"display": "infinita", "score": null}}
		var after := {
			"DANO / TIRO": {"display": "%d + área" % rocket.damage, "score": float(rocket.damage)},
			"INTERVALO": {"display": "%.2fs" % rocket.cooldown, "score": 1.0 / float(rocket.cooldown)},
			"MUNIÇÃO": {"display": str(app.sim.actors[host.gear_actor].run_weapons.bazooka), "score": null}}
		display_comparison("ARMA BÁSICA → BAZUCA", before, after)
		detail_reason.text = "Comparação com a arma básica do uniforme."; return
	if entry.get("transiente", false): detail_reason.text = "Recurso automático • quantidade nesta tentativa: %d." % quantity_for(entry); return
	var slot := str(entry.get("slot", "")); var current_id := ""
	for candidate in InventoryData.valid_items():
		if candidate.get("slot", "") == slot and carried(candidate): current_id = candidate.id; break
	var current := InventoryData.item(current_id)
	if current.is_empty(): detail_reason.text = "Sem item comparável neste slot."; return
	var before := comparison_values(current); var after := comparison_values(entry)
	display_comparison("%s → %s" % [current.nome, entry.nome], before, after)
	detail_reason.text = "Atual → selecionado" + (" • mesmo item" if current_id == entry.id else "")

func build_equipment_category(category: String, title: String, subtitle: String) -> void:
	panel(page, Rect2(0, 0, 1308, 592), Color("0b211e"), BRASS)
	label(page, Rect2(28, 20, 500, 35), title, 25, GOLD); label(page, Rect2(28, 57, 700, 26), subtitle, 15, DIM)
	var list := DATA.by_category(category)
	for i in list.size():
		var entry: Dictionary = list[i]; var open := unlocked(entry.id); var selected := equipped(entry.id)
		var p := panel(page, Rect2(28 + i * 335, 108, 310, 360), Color("102c28"), TEAL if selected else RARITY.get(entry.get("raridade", "comum"), BRASS))
		var portrait := image(p, Rect2(30, 20, 250, 190), tex(entry.get("card", ""))); portrait.modulate = Color.WHITE if open else Color(0.22, 0.25, 0.28)
		label(p, Rect2(22, 220, 266, 32), entry.nome, 21, GOLD if open else DIM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var state := "EQUIPADO" if selected else ("DISPONÍVEL" if open else "BLOQUEADO")
		label(p, Rect2(22, 254, 266, 24), state, 14, TEAL if selected else DIM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var body := label(p, Rect2(22, 285, 266, 58), entry.descricao_curta if open else entry.desbloqueio.texto, 12, TEXT if open else DIM); body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var hit := Button.new(); hit.flat = true; hit.position = p.position; hit.size = p.size; hit.name = "%sCard_%s" % ["Armaduras" if category == "armadura" else title.capitalize(), entry.id]
		hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); hit.add_theme_stylebox_override("pressed", make_style(Color(0, 0, 0, 0), TEAL, 4))
		hit.add_theme_stylebox_override("hover", make_style(Color(0.1, 0.8, 0.8, 0.05), TEAL, 3)); hit.add_theme_stylebox_override("focus", make_style(Color(0.1, 0.8, 0.8, 0.05), TEAL, 4))
		hit.pressed.connect(func(): pick(entry.id)); hit.focus_entered.connect(func(): show_item(entry.id)); page.add_child(hit)
	var hint := label(page, Rect2(30, 505, 1240, 55), "Selecione para equipar. Itens bloqueados mostram como desbloquear.", 14, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func build_equipped() -> void:
	panel(page, Rect2(0, 0, 1308, 592), Color("0b211e"), BRASS)
	label(page, Rect2(28, 20, 500, 38), "ITENS EQUIPADOS", 25, GOLD)
	var rows := [["UNIFORME / ARMA", "uniforme", host.outfit_choice], ["ROBÔ", "robo", host.robot_choice], ["ARMADURA", "armadura", host.armor_choice]]
	for i in rows.size():
		var equipment_id: String = rows[i][2]; var entry := DATA.item(equipment_id)
		var p := panel(page, Rect2(35, 90 + i * 145, 1238, 120), Color("102c28"), TEAL if not entry.is_empty() else Color("46534c"))
		label(p, Rect2(20, 12, 230, 28), rows[i][0], 16, GOLD)
		image(p, Rect2(260, 10, 95, 95), tex(entry.get("icone", DIR + "icones/icon_slot_vazio.png")))
		label(p, Rect2(380, 17, 400, 35), entry.get("nome", "VAZIO"), 22, TEXT)
		label(p, Rect2(380, 56, 560, 35), entry.get("descricao_curta", "Nenhum item compatível equipado."), 14, DIM)
		var slot_name: String = rows[i][1]
		var clear := button(p, Rect2(1010, 31, 190, 52), "DESEQUIPAR", func(): unequip_slot(slot_name), "Unequip_%s" % slot_name)
		clear.disabled = equipment_id == "" or slot_name in ["uniforme", "armadura"]
		if slot_name == "armadura": clear.text = "PODER FIXO"; clear.tooltip_text = "A Armadura Ômega é um poder desbloqueado e não um slot removível."

func unequip_slot(slot: String) -> void:
	if slot != "robo": status.text = "Este slot não pode ficar vazio."; return
	var previous_robot: String = host.robot_choice; var previous_inventory: Dictionary = inventory.to_dict()
	host.robot_choice = ""
	if not mission_mode: inventory.unequip(slot)
	if not host.apply_gear(): host.robot_choice = previous_robot; inventory.from_dict(previous_inventory); status.text = "Não é possível trocar o equipamento agora."
	else: status.text = "Robô desequipado."
	if not mission_mode: app.sim.inventory_state = inventory.to_dict()
	rebuild_current()

func reference_rows(kind: String, outfit: String = "padrao") -> Array:
	var rows: Array = app.sim.loadout_stats(kind, outfit).duplicate(true)
	if kind == "omega":
		rows[0][0] = "ESCUDO TEMPORÁRIO"; rows[0][1] = "%d corações" % app.sim.OMEGA_SHIELD_HEARTS
	if kind == "uniform":
		var u: Dictionary = app.sim.UNIFORMS.get(outfit, app.sim.UNIFORMS.padrao)
		var cooldown := float(app.sim.WEAPONS[u.weapon].cooldown)
		rows[4][0] = "INTERVALO DE TIRO"; rows[4][1] = "%.2fs" % cooldown; rows[4][2] = 1.0 / cooldown
		rows[5][0] = "RESISTÊNCIA"; rows[5][1] = "Maior" if float(u.taken) < 1.0 else ("Menor" if float(u.taken) > 1.0 else "Padrão")
	return rows

func condition_label(rect: Rect2, caption: String, node_name: String, color := TEXT) -> Label:
	var current := page.find_child(node_name, true, false) as Label
	if current != null:
		current.text = caption
		return current
	current = label(page, rect, caption, 14, color); current.name = node_name
	return current

func status_panel(x: float, title: String, subtitle: String, rows: Array, node_name: String) -> void:
	var p := panel(page, Rect2(x, 86, 410, 340), Color("102c28"), BRASS)
	label(p, Rect2(18, 14, 374, 28), title, 20, GOLD)
	label(p, Rect2(18, 48, 374, 42), subtitle, 13, DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in rows.size():
		label(p, Rect2(18, 98 + i * 31, 220, 28), str(rows[i][0]), 13, DIM)
		var value := label(p, Rect2(218, 98 + i * 31, 175, 28), str(rows[i][1]), 11 if str(rows[i][1]).length() > 22 else 14, TEXT)
		value.name = "%s_%d" % [node_name, i]

func build_status() -> void:
	panel(page, Rect2(0, 0, 1308, 592), Color("0b211e"), BRASS)
	label(page, Rect2(28, 16, 1250, 36), "ATRIBUTOS DE REFERÊNCIA • CADA EQUIPAMENTO TEM SEU USO", 23, GOLD)
	label(page, Rect2(28, 53, 1240, 26), "Uniforme a pé • Ômega somente quando ativa • robô separado da vida de Marty", 15, DIM)
	var u: Dictionary = app.sim.UNIFORMS.get(host.outfit_choice, app.sim.UNIFORMS.padrao)
	status_panel(20, "MARTY • " + str(u.name), str(u.weapon_name) + " • munição infinita\nGolpes tiram ½ ou 1 coração.", reference_rows("uniform", host.outfit_choice), "MartyReference")
	var omega_ready := unlocked(host.armor_choice)
	status_panel(449, "ARMADURA ÔMEGA", "R ativa a armadura e sua lâmina temporária." if omega_ready else "Poder bloqueado.", reference_rows("omega") if omega_ready else [], "OmegaReference")
	var robot: String = host.robot_choice if unlocked(host.robot_choice) else ""
	status_panel(878, robot.to_upper() if robot != "" else "SEM ROBÔ", "C invoca • E pilota • consome combustível" if robot == "titan" else ("C invoca/recolhe • G funde/separa" if robot == "spectre" else "Selecione um robô na aba ROBÔS."), reference_rows(robot) if robot != "" else [], "RobotReference")
	if not mission_mode:
		label(page, Rect2(30, 456, 1240, 65), "PREPARAÇÃO DA EXPEDIÇÃO\nVida, escudo, munição e condição do robô aparecem aqui durante a missão.", 16, DIM)
		return
	update_status_condition()

func update_status_condition() -> void:
	var a: Dictionary = app.sim.actors[host.gear_actor]
	var u: Dictionary = app.sim.UNIFORMS.get(host.outfit_choice, app.sim.UNIFORMS.padrao)
	var omega_ready := unlocked(host.armor_choice)
	var robot: String = host.robot_choice if unlocked(host.robot_choice) else ""
	condition_label(Rect2(30, 438, 1200, 27), "CONDIÇÃO ATUAL • JOGADOR %d" % (host.gear_actor + 1), "MissionPlayer", GOLD)
	var state := "CAÍDO" if a.get("dead", false) else ("PILOTANDO TITAN" if a.get("mech", false) else ("ÔMEGA ATIVA" if a.get("armor", false) else ("EM FUSÃO" if a.get("fused", false) else "A PÉ")))
	var health := condition_label(Rect2(30, 476, 390, 65), "VIDA  %.1f / %d corações\n%s" % [float(a.hp) / app.sim.HEART, app.sim.BASE_HEARTS, state], "MissionHealth")
	var omega_state := "ATIVA • %.0fs restantes" % ceilf(float(a.get("armor_time", 0))) if a.get("armor", false) else ("RECARREGANDO • %.0fs" % ceilf(float(a.get("armor_cd", 0))) if float(a.get("armor_cd", 0)) > 0 else ("INATIVA • pronta para ativar" if omega_ready else "BLOQUEADA"))
	var shield := condition_label(Rect2(450, 476, 410, 65), "ESCUDO  %.1f / %d corações\n%s" % [float(a.get("shield", 0)) / app.sim.HEART, app.sim.OMEGA_SHIELD_HEARTS, omega_state], "MissionShield")
	var robot_text := "Nenhum robô selecionado"
	if robot == "titan":
		var mech: Dictionary = app.sim.mech
		var mech_state := "DESTRUÍDO" if float(mech.hp) <= 0 else ("PILOTADO POR P%d" % (int(mech.occupant) + 1) if int(mech.occupant) >= 0 else ("NO CENÁRIO" if mech.get("deployed", false) else "RECOLHIDO"))
		robot_text = "%s • integridade %.0f / %.0f\nCOMBUSTÍVEL  %.0f%%" % [mech_state, mech.hp, app.sim.new_mech(Vector2.ZERO).hp, float(mech.fuel) / app.sim.FUEL_MAX * 100]
	elif robot == "spectre" and host.gear_actor < app.sim.spectres.size():
		var spectre: Dictionary = app.sim.spectres[host.gear_actor]
		var states := {"stored": "RECOLHIDO", "following": "ACOMPANHANDO", "fused": "EM FUSÃO", "destroyed": "DESTRUÍDO"}
		robot_text = "%s\nENERGIA  %.0f / %.0f" % [states.get(spectre.state, "INATIVO"), spectre.hp, app.sim.SPECTRE_HP]
	var condition := condition_label(Rect2(880, 476, 400, 65), robot_text, "MissionRobot")
	var ammo := condition_label(Rect2(30, 548, 1250, 28), "ARMA BÁSICA • %s • munição infinita" % u.weapon_name, "MissionAmmo", TEAL)
	if a.get("mech", false): ammo.text = "CANHÃO TITAN EM USO • consome combustível"
	elif a.get("armor", false): ammo.text = "LÂMINA ÔMEGA EM USO"
	if a.get("run_weapons", {}).has("bazooka"):
		ammo.text += "    |    BAZUCA %s • %d foguetes" % ["EM USO" if a.get("run_weapon", "") == "bazooka" and not a.get("armor", false) and not a.get("mech", false) else "GUARDADA", a.run_weapons.bazooka]

func rebuild_current() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var focus_name := str(focused.name) if focused != null and is_ancestor_of(focused) else ""
	show_tab(active_tab)
	if focus_name != "": call_deferred("restore_focus", focus_name)

func restore_focus(control_name: String) -> void:
	var target := find_child(control_name, true, false)
	if target is Button and target.visible and not target.disabled: target.grab_focus()

func owns_loadout(id: String) -> bool:
	for entry in InventoryData.valid_items():
		if entry.get("loadout_id", "") == id: return inventory.quantity(entry.id) > 0
	return false

func toggle_actor() -> void:
	host.select_actor(1 - host.gear_actor)
	var actor_toggle := find_child("ActorToggle", true, false)
	if actor_toggle is Button: actor_toggle.text = "P%d • TROCAR" % (host.gear_actor + 1)

func sync_authoritative_loadout() -> void:
	if not mission_mode or not app.online or app.hosting or host.gear_actor < 0 or host.gear_actor >= app.sim.actors.size(): return
	var actor: Dictionary = app.sim.actors[host.gear_actor]
	host.outfit_choice = actor.get("outfit", "padrao")
	host.robot_choice = actor.get("selected_robot", "")
	host.armor_choice = actor.get("armor_type", "omega") if app.sim.is_unlocked(actor.get("armor_type", "omega")) else ""

func current_mission_signature() -> String:
	if not mission_mode: return ""
	var mission_actor: Dictionary = app.sim.actors[host.gear_actor] if host.gear_actor >= 0 and host.gear_actor < app.sim.actors.size() else {}
	var watched: Array = [app.sim.keys, app.sim.money, app.sim.materials, host.gear_actor, host.outfit_choice, host.robot_choice, host.armor_choice]
	for key in ["armor", "fused", "run_weapons", "run_weapon", "active", "dead", "mech"]: watched.append(mission_actor.get(key))
	return str(watched)


func _process(_delta: float) -> void:
	if not mission_mode or page == null: return
	sync_authoritative_loadout()
	if active_tab == 4: update_status_condition()
	var next_signature := current_mission_signature()
	if next_signature != mission_signature:
		mission_signature = next_signature
		rebuild_current()

func unlocked(id: String) -> bool:
	return id != "" and app.sim.is_unlocked(id)

func equipped(id: String) -> bool:
	match DATA.item(id).get("categoria", ""):
		"uniforme": return host.outfit_choice == id
		"armadura": return host.armor_choice == id
		"robo": return host.robot_choice == id
	return false

func pick(id: String) -> void:
	focus_id = id; var entry := DATA.item(id)
	if entry.is_empty(): status.text = "Item desconhecido."; return
	if not unlocked(id): status.text = "%s ainda bloqueado." % entry.nome; refresh_compat(); return
	if mission_mode and not owns_loadout(id) and not equipped(id): status.text = "%s não foi levado para esta missão." % entry.nome; refresh_compat(); return
	var previous_outfit: String = host.outfit_choice; var previous_robot: String = host.robot_choice; var previous_armor: String = host.armor_choice
	match entry.categoria:
		"uniforme": host.outfit_choice = id
		"robo": host.robot_choice = id
		"armadura": host.armor_choice = id
	if not host.apply_gear():
		host.outfit_choice = previous_outfit; host.robot_choice = previous_robot; host.armor_choice = previous_armor
		status.text = "Não é possível trocar o equipamento agora."; refresh_compat(); return
	if mission_mode and app.online and not app.hosting:
		host.outfit_choice = previous_outfit; host.robot_choice = previous_robot; host.armor_choice = previous_armor
		status.text = "Solicitado ao anfitrião; aguardando confirmação."
	if not mission_mode:
		for inv_entry in InventoryData.valid_items():
			if inv_entry.get("loadout_id", "") == id:
				if inventory.quantity(inv_entry.id) == 0: inventory.add(inv_entry.id)
				inventory.equip(inv_entry.id, app.sim.unlocked)
		app.sim.inventory_state = inventory.to_dict()
	refresh_compat(); rebuild_current()

func show_item(id: String) -> void:
	focus_id = id; refresh_compat()

func cycle(step: int) -> void:
	var i := (order.find(focus_id) + step + order.size()) % order.size(); focus_id = order[i]
	show_tab((active_tab + step + tabs.size()) % tabs.size()); (tabs[active_tab] as Button).grab_focus(); refresh_compat()

func build_compatibility_nodes() -> void:
	var compat := Control.new(); compat.name = "LegacyCompatibility"; compat.visible = false; add_child(compat)
	for id in order:
		var icon := TextureRect.new(); var frame := NinePatchRect.new(); var name_label := Label.new(); var sub := Label.new(); var line := Label.new(); var hit := Button.new()
		compat.add_child(icon); compat.add_child(frame); compat.add_child(name_label); compat.add_child(sub); compat.add_child(line); compat.add_child(hit)
		slots[id] = {"icon": icon, "frame": frame, "name": name_label, "sub": sub, "line": line, "button": hit}
	for empty_name in ["EmptyArmor_1", "EmptyArmor_2", "EmptyRobot_2"]:
		var empty := TextureRect.new(); empty.name = empty_name; empty.texture = load(DIR + "icones/icon_slot_vazio.png"); compat.add_child(empty)
	card = TextureRect.new(); card.name = "Card"; compat.add_child(card)
	card_lock = TextureRect.new(); compat.add_child(card_lock)
	desc_body = Label.new(); compat.add_child(desc_body)
	robot_label = Label.new(); compat.add_child(robot_label)
	for i in 6:
		var n := Label.new(); compat.add_child(n); numbers.append(n)
	refresh_compat()

func refresh_compat() -> void:
	if slots.is_empty(): return
	for id in slots:
		var entry := DATA.item(id); var open := unlocked(id); var node: Dictionary = slots[id]
		node.icon.texture = tex(entry.get("icone", "")) if open or entry.get("icone_bloqueado", "") == "" else tex(entry.icone_bloqueado)
		node.sub.text = entry.get("subtitulo", "") if open else "BLOQUEADO"; node.name.text = entry.get("nome", "")
		node.frame.texture = load(DIR + ("icones/frame_lendario.png" if entry.get("raridade", "") == "lendario" else "icones/frame_selecao.png"))
		node.frame.visible = (open and (equipped(id) or entry.get("raridade", "") == "lendario")) or id == focus_id
	var robot := DATA.item(host.robot_choice); robot_label.text = robot.get("nome", "SEM ROBÔ") if unlocked(host.robot_choice) else "SEM ROBÔ"
	var focus := DATA.item(focus_id)
	card.texture = tex(focus.get("card", "")); card.modulate = Color.WHITE if unlocked(focus_id) else Color(0.2, 0.2, 0.26); card_lock.visible = not unlocked(focus_id)
	desc_body.text = focus.get("descricao", "") if unlocked(focus_id) else "Como desbloquear: " + focus.get("desbloqueio", {}).get("texto", "")
	var outfit: String = focus_id if unlocked(focus_id) and focus.get("categoria", "") == "uniforme" else host.outfit_choice
	var u: Dictionary = app.sim.UNIFORMS.get(outfit, app.sim.UNIFORMS.padrao)
	var w: Dictionary = app.sim.WEAPONS[u.weapon]
	var values := [float(app.sim.BASE_HEARTS), float(u.speed), float(u.melee), float(w.damage * w.count / w.cooldown), (1.0 - float(u.taken)) * 100, float(u.dash_cd)]
	var stats := DATA.stats()
	for i in mini(numbers.size(), stats.size()): numbers[i].text = DATA.format(stats[i].id, values[i])

func refresh() -> void:
	refresh_compat()
	if page != null: rebuild_current()

