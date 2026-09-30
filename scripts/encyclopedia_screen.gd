class_name EncyclopediaScreen
extends Control

const EncyclopediaData = preload("res://scripts/encyclopedia_data.gd")
const ARCHIVE_BACKDROP_PATH := "res://assets/ui/title/title_still.png"
const ORNATE_FRAME_PATH := "res://assets/ui/pause/pause_frame_pixellab.png"

const CYAN := Color("65f0f5")
const CYAN_DIM := Color("2d7b83")
const BRASS := Color("c5a557")
const GOLD := Color("f3dda0")
const CREAM := Color("e8dfc3")
const MUTED := Color("9eaa9a")
const OLIVE := Color("24291f")
const DEEP := Color("070d12")
const VIOLET := Color("735080")

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
var fallback_glyph: Label
var name_label: Label
var subtitle_label: Label
var description_label: Label
var traits_label: Label
var count_label: Label
var back_button: Button

func build() -> void:
	name = "EncyclopediaScreen"
	size = Vector2(1344, 752)
	_build_atmosphere()

	var frame := make_panel(Rect2(42, 25, 1260, 702), Color("111b19"), BRASS, 3)
	frame.name = "ArchiveChassis"
	add_child(frame)
	_add_corner_rivets(frame)
	var inner := make_panel(Rect2(12, 12, 1236, 678), Color("15201c"), Color("5e684a"), 1)
	inner.name = "ArchiveInnerPlate"
	frame.add_child(inner)

	var title_plate := make_panel(Rect2(24, 18, 1188, 83), OLIVE, Color("806c3d"), 2)
	title_plate.name = "ArchiveHeaderPlate"
	inner.add_child(title_plate)
	make_label(title_plate, Rect2(22, 11, 760, 38), "ARQUIVO TEMPORAL", 29, GOLD)
	make_label(title_plate, Rect2(24, 47, 780, 22), "REFÚGIO // REGISTROS RECUPERADOS DAS FRATURAS", 13, MUTED)
	count_label = make_label(title_plate, Rect2(885, 15, 275, 25), "", 14, CYAN)
	count_label.name = "ArchiveRecordCount"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var status := make_label(title_plate, Rect2(914, 46, 246, 20), "●  NÚCLEO SINCRONIZADO", 11, CYAN_DIM)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	for i in EncyclopediaData.CATEGORIES.size():
		var category_id: String = EncyclopediaData.CATEGORIES[i]
		var tab := make_button(inner, Rect2(24 + i * 178, 113, 164, 42), EncyclopediaData.CATEGORY_LABELS[category_id])
		tab.name = "Category_" + category_id
		tab.pressed.connect(func(): select_category(category_id))
		tabs[category_id] = tab
	for i in EncyclopediaData.CATEGORIES.size():
		var current: Button = tabs[EncyclopediaData.CATEGORIES[i]]
		var previous: Button = tabs[EncyclopediaData.CATEGORIES[(i - 1 + EncyclopediaData.CATEGORIES.size()) % EncyclopediaData.CATEGORIES.size()]]
		var next: Button = tabs[EncyclopediaData.CATEGORIES[(i + 1) % EncyclopediaData.CATEGORIES.size()]]
		current.focus_neighbor_left = current.get_path_to(previous)
		current.focus_neighbor_right = current.get_path_to(next)

	var list_panel := make_panel(Rect2(24, 168, 408, 424), Color("0c1514"), Color("6d6945"), 2)
	list_panel.name = "DossierListPanel"
	inner.add_child(list_panel)
	make_label(list_panel, Rect2(14, 8, 300, 22), "ÍNDICE DE DOSSIÊS", 13, BRASS)
	make_label(list_panel, Rect2(316, 8, 74, 22), "SETOR A", 10, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var list_rule := ColorRect.new()
	list_rule.color = CYAN_DIM; list_rule.position = Vector2(14, 34); list_rule.size = Vector2(376, 2); list_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_panel.add_child(list_rule)
	var scroll := ScrollContainer.new()
	scroll.name = "EntryScroll"; scroll.position = Vector2(12, 45); scroll.size = Vector2(384, 365)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.name = "EntryList"; list_box.custom_minimum_size = Vector2(364, 0); list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(list_box)
	empty_label = make_label(list_panel, Rect2(26, 155, 356, 96), "", 17, MUTED)
	empty_label.name = "ArchiveEmptyState"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; empty_label.visible = false

	var detail_panel := make_panel(Rect2(447, 168, 765, 424), Color("0b1415"), Color("6d6945"), 2)
	detail_panel.name = "ArchiveDossierPanel"
	inner.add_child(detail_panel)
	make_label(detail_panel, Rect2(22, 9, 260, 21), "DOSSIÊ // LEITURA", 12, BRASS)
	make_label(detail_panel, Rect2(590, 9, 150, 21), "CLASSIFICAÇÃO R-7", 10, VIOLET).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var portrait_frame := NinePatchRect.new()
	portrait_frame.name = "ArchivePortraitFrame"; portrait_frame.position = Vector2(20, 38); portrait_frame.size = Vector2(246, 264)
	portrait_frame.texture = _safe_texture(ORNATE_FRAME_PATH); portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.patch_margin_left = 44; portrait_frame.patch_margin_top = 44; portrait_frame.patch_margin_right = 44; portrait_frame.patch_margin_bottom = 44
	portrait_frame.draw_center = false
	portrait_frame.z_index = 2
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_panel.add_child(portrait_frame)
	var image_well := make_panel(Rect2(39, 58, 208, 224), DEEP, CYAN_DIM, 1)
	image_well.name = "ArchiveImageWell"
	detail_panel.add_child(image_well)
	portrait = TextureRect.new()
	portrait.name = "EntryImage"; portrait.position = Vector2(9, 9); portrait.size = Vector2(190, 206)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_well.add_child(portrait)
	fallback = make_label(image_well, Rect2(9, 9, 190, 206), "", 58, Color("8c8258"))
	fallback.name = "EntryFallback"; fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var seal_ring := make_panel(Rect2(41, 49, 108, 108), Color("0a1110"), Color("8c8258"), 2)
	seal_ring.name = "MissingArtSeal"; seal_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE; fallback.add_child(seal_ring)
	fallback_glyph = make_label(seal_ring, Rect2(8, 8, 92, 58), "?", 36, GOLD)
	fallback_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fallback_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	make_label(seal_ring, Rect2(8, 72, 92, 20), "SEM IMAGEM", 9, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scan_label := make_label(detail_panel, Rect2(43, 307, 200, 20), "ARTEFATO VISUAL // 01", 10, CYAN_DIM)
	scan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	name_label = make_label(detail_panel, Rect2(289, 43, 445, 46), "", 27, GOLD)
	name_label.name = "EntryName"; name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label = make_label(detail_panel, Rect2(291, 88, 440, 29), "", 15, CYAN)
	subtitle_label.name = "EntrySubtitle"; subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var fracture := ColorRect.new()
	fracture.name = "FractureAccent"; fracture.color = VIOLET; fracture.position = Vector2(289, 121); fracture.size = Vector2(445, 2); fracture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_panel.add_child(fracture)
	var text_scroll := ScrollContainer.new()
	text_scroll.name = "DetailScroll"; text_scroll.position = Vector2(289, 135); text_scroll.size = Vector2(451, 260)
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(text_scroll)
	var text_stack := VBoxContainer.new()
	text_stack.custom_minimum_size = Vector2(429, 0); text_stack.add_theme_constant_override("separation", 16)
	text_scroll.add_child(text_stack)
	description_label = make_label(text_stack, Rect2(), "", 16, CREAM)
	description_label.name = "EntryDescription"; description_label.custom_minimum_size = Vector2(429, 114)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	traits_label = make_label(text_stack, Rect2(), "", 15, Color("c1d1c3"))
	traits_label.name = "EntryTraits"; traits_label.custom_minimum_size = Vector2(429, 126)
	traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var legend := make_panel(Rect2(24, 605, 920, 49), Color("111916"), Color("52543b"), 1)
	legend.name = "ArchiveControlLegend"
	inner.add_child(legend)
	make_label(legend, Rect2(17, 8, 880, 17), "[← →] CATEGORIA     [↑ ↓] DOSSIÊ     [ENTER] ABRIR     [ESC] RETORNAR", 11, MUTED)
	make_label(legend, Rect2(17, 26, 880, 16), "LINHA TEMPORAL ESTÁVEL  //  ACESSO LOCAL DO REFÚGIO", 9, CYAN_DIM)
	back_button = make_button(inner, Rect2(963, 605, 249, 49), "VOLTAR AO TERMINAL")
	back_button.name = "EncyclopediaBack"
	back_button.pressed.connect(func(): host.show_screen(host.encyclopedia_return_screen))
	select_category(category)

func _build_atmosphere() -> void:
	var backdrop := TextureRect.new()
	backdrop.name = "ArchiveBackdrop"; backdrop.size = size; backdrop.texture = _safe_texture(ARCHIVE_BACKDROP_PATH)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; backdrop.modulate = Color(0.22, 0.28, 0.22, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(backdrop)
	var shade := ColorRect.new()
	shade.name = "ArchiveAtmosphereShade"; shade.color = Color(0.025, 0.045, 0.05, 0.76); shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(shade)
	for rect in [Rect2(0, 18, 1344, 4), Rect2(0, 730, 1344, 4), Rect2(18, 0, 3, 752), Rect2(1323, 0, 3, 752)]:
		var trace := ColorRect.new(); trace.color = Color(0.25, 0.85, 0.88, 0.24); trace.position = rect.position; trace.size = rect.size
		trace.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(trace)

func _safe_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path): return null
	var resource := load(path)
	return resource as Texture2D

func _add_corner_rivets(parent: Control) -> void:
	for point in [Vector2(8, 8), Vector2(1238, 8), Vector2(8, 680), Vector2(1238, 680)]:
		var rivet := make_panel(Rect2(point, Vector2(14, 14)), Color("73633b"), GOLD, 1)
		rivet.name = "ArchiveRivet"; parent.add_child(rivet)

func make_panel(rect: Rect2, fill: Color, edge: Color, width: int) -> Panel:
	var result := Panel.new(); result.position = rect.position; result.size = rect.size; result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.set_corner_radius_all(2)
	result.add_theme_stylebox_override("panel", style)
	return result

func make_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var result := Label.new(); result.position = rect.position; result.size = rect.size; result.text = text
	result.add_theme_font_size_override("font_size", font_size); result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(result)
	return result

func make_button(parent: Control, rect: Rect2, text: String) -> Button:
	var result := Button.new(); result.position = rect.position; result.size = rect.size; result.text = text
	result.focus_mode = Control.FOCUS_ALL; result.add_theme_font_size_override("font_size", 16); result.add_theme_color_override("font_color", CREAM)
	result.add_theme_color_override("font_hover_color", GOLD); result.add_theme_color_override("font_focus_color", CYAN)
	var normal := StyleBoxFlat.new(); normal.bg_color = Color("18221d"); normal.border_color = Color("55583d"); normal.set_border_width_all(2); normal.set_corner_radius_all(1)
	var hover := normal.duplicate(); hover.bg_color = Color("263329"); hover.border_color = BRASS
	var focus := hover.duplicate(); focus.bg_color = Color("1c3432"); focus.border_color = CYAN
	var pressed := focus.duplicate(); pressed.bg_color = Color("214743")
	result.add_theme_stylebox_override("normal", normal); result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("focus", focus); result.add_theme_stylebox_override("pressed", pressed)
	result.mouse_entered.connect(func(): result.grab_focus())
	parent.add_child(result)
	return result

func select_category(next_category: String) -> void:
	if next_category not in EncyclopediaData.CATEGORIES: return
	category = next_category
	for category_id in tabs:
		var tab: Button = tabs[category_id]
		var style: StyleBoxFlat = tab.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color("334036") if category_id == category else Color("18221d")
		style.border_color = BRASS if category_id == category else Color("55583d")
		tab.add_theme_stylebox_override("normal", style)
		var focus_style: StyleBoxFlat = tab.get_theme_stylebox("focus").duplicate()
		focus_style.border_width_bottom = 5 if category_id == category else 2
		tab.add_theme_stylebox_override("focus", focus_style)
		tab.add_theme_color_override("font_color", GOLD if category_id == category else CREAM)
		tab.add_theme_color_override("font_focus_color", GOLD if category_id == category else CYAN)
	rebuild_list()

func rebuild_list() -> void:
	for child in list_box.get_children(): child.queue_free()
	entry_buttons.clear()
	var records := records_for_category(category)
	empty_label.visible = records.is_empty()
	empty_label.text = "Nenhum registro recuperado.\nAguardando sincronização temporal."
	count_label.text = "%02d DOSSIÊS // %s" % [records.size(), category.to_upper()]
	if records.is_empty():
		show_entry({})
		back_button.grab_focus.call_deferred()
		return
	var wanted := str(selected_ids.get(category, records[0].id))
	var selected_index := 0
	for i in records.size():
		var entry: Dictionary = records[i]
		var row_text := "%02d  //  %s" % [i + 1, str(entry.nome)]
		var entry_button := make_button(list_box, Rect2(), row_text)
		entry_button.name = "Entry_" + entry.id; entry_button.custom_minimum_size = Vector2(364, 50)
		entry_button.alignment = HORIZONTAL_ALIGNMENT_LEFT; entry_button.tooltip_text = "%s\n%s" % [entry.nome, entry.subtitulo]
		entry_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		entry_button.add_theme_constant_override("outline_size", 1)
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
		style.border_color = BRASS if active else Color("55583d")
		style.bg_color = Color("303b30") if active else Color("18221d")
		style.border_width_left = 5 if active else 2
		entry_button.add_theme_stylebox_override("normal", style)
		var focus_style: StyleBoxFlat = entry_button.get_theme_stylebox("focus").duplicate()
		focus_style.border_width_left = 5 if active else 2
		entry_button.add_theme_stylebox_override("focus", focus_style)
		entry_button.add_theme_color_override("font_color", GOLD if active else CREAM)
		entry_button.add_theme_color_override("font_focus_color", GOLD if active else CYAN)

func show_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		portrait.texture = null; portrait.visible = false; fallback.visible = true; fallback_glyph.text = "—"
		name_label.text = "SEM REGISTROS"; subtitle_label.text = "CANAL TEMPORAL OCIOSO"
		description_label.text = "Esta categoria ainda pode receber novos conteúdos."
		traits_label.text = "SISTEMA\n• Catálogo pronto para sincronização"
		return
	name_label.text = entry.nome; name_label.tooltip_text = entry.nome
	subtitle_label.text = entry.subtitulo; subtitle_label.tooltip_text = entry.subtitulo; description_label.text = entry.descricao
	traits_label.text = "CARACTERÍSTICAS RECUPERADAS\n" + "\n".join(entry.tracos.map(func(feature_text): return "◆ " + str(feature_text)))
	var image_path := EncyclopediaData.image_path(entry)
	portrait.texture = load(image_path) if not image_path.is_empty() else null
	portrait.visible = portrait.texture != null
	fallback.visible = not portrait.visible
	fallback_glyph.text = entry.nome.substr(0, 1).to_upper()
