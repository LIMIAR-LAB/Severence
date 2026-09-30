class_name EncyclopediaScreen
extends Control

const EncyclopediaData = preload("res://scripts/encyclopedia_data.gd")
const CYAN := Color("65f0f5")
const GOLD := Color("f3dda0")
const MUTED := Color("9ab4b2")

var host: Control
var category := "monstros"
var records_override: Variant = null
var selected_ids := {}
var tabs := {}
var entry_buttons: Array[Button] = []
var list_box: VBoxContainer
var empty_label: Label
var portrait: TextureRect
var fallback: Label
var name_label: Label
var subtitle_label: Label
var description_label: Label
var traits_label: Label
var count_label: Label
var back_button: Button

func build() -> void:
	name = "EncyclopediaScreen"
	size = Vector2(1344, 752)
	var shade := ColorRect.new(); shade.color = Color("071219"); shade.size = size; shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(shade)
	var frame := make_panel(Rect2(54, 34, 1236, 684), Color("0c2028"), Color("8d7540"), 3)
	frame.name = "EncyclopediaFrame"
	add_child(frame)
	make_label(frame, Rect2(32, 20, 760, 48), "ARQUIVO DO REFÚGIO", 32, GOLD)
	make_label(frame, Rect2(34, 65, 750, 25), "Registros reunidos através das fraturas do tempo", 15, MUTED)
	count_label = make_label(frame, Rect2(905, 28, 280, 30), "", 14, MUTED)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	for i in EncyclopediaData.CATEGORIES.size():
		var category_id: String = EncyclopediaData.CATEGORIES[i]
		var tab := make_button(frame, Rect2(32 + i * 184, 108, 168, 45), EncyclopediaData.CATEGORY_LABELS[category_id])
		tab.name = "Category_" + category_id
		tab.pressed.connect(func(): select_category(category_id))
		tabs[category_id] = tab
	for i in EncyclopediaData.CATEGORIES.size():
		var current: Button = tabs[EncyclopediaData.CATEGORIES[i]]
		var previous: Button = tabs[EncyclopediaData.CATEGORIES[(i - 1 + EncyclopediaData.CATEGORIES.size()) % EncyclopediaData.CATEGORIES.size()]]
		var next: Button = tabs[EncyclopediaData.CATEGORIES[(i + 1) % EncyclopediaData.CATEGORIES.size()]]
		current.focus_neighbor_left = current.get_path_to(previous)
		current.focus_neighbor_right = current.get_path_to(next)

	var list_panel := make_panel(Rect2(32, 169, 390, 430), Color("09171e"), Color("315966"), 2)
	frame.add_child(list_panel)
	var scroll := ScrollContainer.new(); scroll.name = "EntryScroll"; scroll.position = Vector2(10, 10); scroll.size = Vector2(370, 410)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; list_panel.add_child(scroll)
	list_box = VBoxContainer.new(); list_box.name = "EntryList"; list_box.custom_minimum_size = Vector2(350, 0); list_box.add_theme_constant_override("separation", 7); scroll.add_child(list_box)
	empty_label = make_label(list_panel, Rect2(20, 170, 350, 80), "", 18, MUTED)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; empty_label.visible = false

	var detail_panel := make_panel(Rect2(442, 169, 762, 430), Color("0b1921"), Color("315966"), 2)
	frame.add_child(detail_panel)
	var image_panel := make_panel(Rect2(24, 24, 224, 220), Color("081218"), Color("477481"), 2)
	detail_panel.add_child(image_panel)
	portrait = TextureRect.new(); portrait.name = "EntryImage"; portrait.position = Vector2(12, 12); portrait.size = Vector2(200, 196)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE; image_panel.add_child(portrait)
	fallback = make_label(image_panel, Rect2(12, 12, 200, 196), "?", 74, Color("49717a")); fallback.name = "EntryFallback"
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label = make_label(detail_panel, Rect2(274, 25, 460, 51), "", 27, GOLD); name_label.name = "EntryName"
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label = make_label(detail_panel, Rect2(276, 82, 455, 31), "", 16, CYAN); subtitle_label.name = "EntrySubtitle"
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var text_scroll := ScrollContainer.new(); text_scroll.name = "DetailScroll"; text_scroll.position = Vector2(274, 126); text_scroll.size = Vector2(460, 278)
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; detail_panel.add_child(text_scroll)
	var text_stack := VBoxContainer.new(); text_stack.custom_minimum_size = Vector2(438, 0); text_stack.add_theme_constant_override("separation", 18); text_scroll.add_child(text_stack)
	description_label = make_label(text_stack, Rect2(), "", 17, Color("d4e2dd")); description_label.name = "EntryDescription"
	description_label.custom_minimum_size = Vector2(438, 130)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	traits_label = make_label(text_stack, Rect2(), "", 16, Color("b7d9d5")); traits_label.name = "EntryTraits"
	traits_label.custom_minimum_size = Vector2(438, 130)
	traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	make_label(frame, Rect2(35, 616, 760, 25), "Selecione uma categoria e consulte os registros disponíveis.", 14, MUTED)
	back_button = make_button(frame, Rect2(978, 614, 226, 48), "VOLTAR")
	back_button.name = "EncyclopediaBack"
	back_button.pressed.connect(func(): host.show_screen(host.encyclopedia_return_screen))
	select_category(category)

func make_panel(rect: Rect2, fill: Color, edge: Color, width: int) -> Panel:
	var result := Panel.new(); result.position = rect.position; result.size = rect.size; result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.set_corner_radius_all(6)
	result.add_theme_stylebox_override("panel", style)
	return result

func make_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var result := Label.new(); result.position = rect.position; result.size = rect.size; result.text = text
	result.add_theme_font_size_override("font_size", font_size); result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(result)
	return result

func make_button(parent: Control, rect: Rect2, text: String) -> Button:
	var result := Button.new(); result.position = rect.position; result.size = rect.size; result.text = text
	result.focus_mode = Control.FOCUS_ALL; result.add_theme_font_size_override("font_size", 17); result.add_theme_color_override("font_color", CYAN)
	var normal := StyleBoxFlat.new(); normal.bg_color = Color("102a34"); normal.border_color = Color("315966"); normal.set_border_width_all(2); normal.set_corner_radius_all(4)
	var hover := normal.duplicate(); hover.bg_color = Color("174653"); hover.border_color = CYAN
	var pressed := hover.duplicate(); pressed.bg_color = Color("185869")
	result.add_theme_stylebox_override("normal", normal); result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("focus", hover); result.add_theme_stylebox_override("pressed", pressed)
	result.mouse_entered.connect(func(): result.grab_focus())
	parent.add_child(result)
	return result

func select_category(next_category: String) -> void:
	if next_category not in EncyclopediaData.CATEGORIES: return
	category = next_category
	for category_id in tabs:
		var tab: Button = tabs[category_id]
		var style: StyleBoxFlat = tab.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color("1b4b55") if category_id == category else Color("102a34")
		style.border_color = GOLD if category_id == category else Color("315966")
		tab.add_theme_stylebox_override("normal", style)
	rebuild_list()

func rebuild_list() -> void:
	for child in list_box.get_children(): child.queue_free()
	entry_buttons.clear()
	var records := records_for_category(category)
	empty_label.visible = records.is_empty()
	empty_label.text = "Nenhum registro nesta categoria.\nAdicione novas entradas em data/enciclopedia.json."
	count_label.text = "%d REGISTROS" % records.size()
	if records.is_empty():
		show_entry({})
		back_button.grab_focus.call_deferred()
		return
	var wanted := str(selected_ids.get(category, records[0].id))
	var selected_index := 0
	for i in records.size():
		var entry: Dictionary = records[i]
		var entry_button := make_button(list_box, Rect2(), entry.nome)
		entry_button.name = "Entry_" + entry.id; entry_button.custom_minimum_size = Vector2(350, 55)
		entry_button.alignment = HORIZONTAL_ALIGNMENT_LEFT; entry_button.tooltip_text = entry.subtitulo
		entry_button.pressed.connect(func(): select_entry(entry))
		entry_buttons.append(entry_button)
		if entry.id == wanted: selected_index = i
	for i in entry_buttons.size():
		entry_buttons[i].focus_neighbor_top = entry_buttons[i].get_path_to(entry_buttons[(i - 1 + entry_buttons.size()) % entry_buttons.size()])
		entry_buttons[i].focus_neighbor_bottom = entry_buttons[i].get_path_to(entry_buttons[(i + 1) % entry_buttons.size()])
	var active_tab: Button = tabs[category]
	active_tab.focus_neighbor_bottom = active_tab.get_path_to(entry_buttons[0])
	entry_buttons[0].focus_neighbor_top = entry_buttons[0].get_path_to(active_tab)
	entry_buttons[-1].focus_neighbor_bottom = entry_buttons[-1].get_path_to(back_button)
	back_button.focus_neighbor_top = back_button.get_path_to(entry_buttons[-1])
	select_entry(records[selected_index])
	entry_buttons[selected_index].grab_focus.call_deferred()

func records_for_category(category_id: String) -> Array:
	if records_override is Array:
		return records_override.filter(func(entry): return entry is Dictionary and entry.get("categoria", "") == category_id)
	return EncyclopediaData.by_category(category_id)

func select_entry(entry: Dictionary) -> void:
	if entry.is_empty(): show_entry({}); return
	selected_ids[category] = entry.id
	show_entry(entry)
	for entry_button in entry_buttons:
		var active: bool = entry_button.name == "Entry_" + entry.id
		var style: StyleBoxFlat = entry_button.get_theme_stylebox("normal").duplicate()
		style.border_color = GOLD if active else Color("315966")
		style.bg_color = Color("193b42") if active else Color("102a34")
		entry_button.add_theme_stylebox_override("normal", style)

func show_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		portrait.texture = null; portrait.visible = false; fallback.visible = true; fallback.text = "—"
		name_label.text = "SEM REGISTROS"; subtitle_label.text = ""; description_label.text = "Esta categoria ainda pode receber novos conteúdos."
		traits_label.text = "Edite data/enciclopedia.json para ampliar o arquivo."
		return
	name_label.text = entry.nome; name_label.tooltip_text = entry.nome
	subtitle_label.text = entry.subtitulo; subtitle_label.tooltip_text = entry.subtitulo; description_label.text = entry.descricao
	traits_label.text = "CARACTERÍSTICAS\n" + "\n".join(entry.tracos.map(func(feature_text): return "• " + str(feature_text)))
	var image_path := EncyclopediaData.image_path(entry)
	portrait.texture = load(image_path) if not image_path.is_empty() else null
	portrait.visible = portrait.texture != null
	fallback.visible = not portrait.visible
	fallback.text = entry.nome.substr(0, 1).to_upper()
