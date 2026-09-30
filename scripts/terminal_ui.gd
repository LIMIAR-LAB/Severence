class_name TemporalTerminal
extends Control
const DisplaySettingsScript = preload("res://scripts/display_settings.gd")
const MenuBackground = preload("res://scripts/menu_background.gd")
const EquipmentScreen = preload("res://scripts/equipment_screen.gd")
const CharacterSilhouette = preload("res://scripts/character_silhouette.gd")
const EncyclopediaScreen = preload("res://scripts/encyclopedia_screen.gd")
const MARTY_PORTRAIT := "res://assets/ui/equipamento/cards/card_marty_padrao.png"
const TITLE_CONCEPT := "res://art/concept/tela-inicial-conceito-v3-severence.png"
const CHARACTER_CONCEPT := "res://art/concept/selecao-personagem-conceito-v3.png"
const CHARACTER_COOP_CONCEPT := "res://art/concept/selecao-personagem-coop-conceito-v3.png"
const ADVENTURE_CONCEPT := "res://art/concept/selecao-aventura-conceito-v3.png"
const TITLE_CONCEPT_SHADER := preload("res://shaders/title_concept_overlay.gdshader")
const PAUSE_FRAME := "res://assets/ui/pause/pause_frame_pixellab.png"
const RUN_SUMMARY_FRAME := "res://assets/ui/run_summary/frame_main.png"
const RUN_SUMMARY_DIR := "res://assets/ui/run_summary/"
const RUN_SUMMARY_LOOT := "res://assets/ui/run_summary/loot/"
const RUN_SUMMARY_FAITHFUL := "res://assets/ui/run_summary/faithful/"
const RUN_SUMMARY_MASTER_SIZE := Vector2(1672, 941)

# Supplied concept screens form the decorative layer. Every active region is a
# real Control; editable text, selections, previews and statuses are live.
const CYAN := Color("65f0f5")
const GOLD := Color("f3dda0")
var app: Node
var stage: Control
var backdrop: ColorRect
var content: Control
var screen := "main"
var pending_mode := "solo"
var gear_actor := 0
var outfit_choice := "padrao"
var robot_choice := "titan"
var preview_kind := "armor"
var preview: TextureRect
var detail: Label
var live_status: Label
var rows: Array = []
var slot_buttons: Dictionary = {}
var start_target := "arena"
var current_choice: Label
var main_resume: Button
var telemetry: Label
var encyclopedia: Control
var encyclopedia_return_screen := "main"
var summary_force_fallback := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Fundo que cobre a sobra de telas 16:9 / 21:9 / 4:3; o menu (arte 1280×800) fica centralizado.
	backdrop = ColorRect.new(); backdrop.color = Color("05080d"); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(backdrop)
	stage = Control.new(); stage.size = Vector2(1344, 752); stage.scale = Vector2(1280.0 / 1344, 800.0 / 752); add_child(stage)
	get_viewport().size_changed.connect(center_stage); center_stage()
	show_screen("main")

func center_stage() -> void:
	if stage == null: return
	var vp := get_viewport_rect().size
	var fit := minf(vp.x / 1344.0, vp.y / 752.0)
	stage.scale = Vector2.ONE * fit
	stage.position = ((vp - stage.size * fit) * 0.5).floor()
	if screen != "main" and content != null:
		var secondary_scene := content.find_child("SecondaryMenuScene", true, false) as Control
		if secondary_scene != null: fit_title_background(secondary_scene)
		var archive_scene := content.find_child("ArchiveBackdropScene", true, false) as Control
		if archive_scene != null: fit_title_background(archive_scene)
	place_equipment()
	place_summary()

func summary_fit(viewport_size: Vector2) -> float:
	return minf(viewport_size.x / RUN_SUMMARY_MASTER_SIZE.x, viewport_size.y / RUN_SUMMARY_MASTER_SIZE.y)

func place_summary(viewport_size: Vector2 = Vector2.ZERO) -> void:
	if content == null or screen != "summary" or content.get_parent() != self: return
	if viewport_size == Vector2.ZERO: viewport_size = get_viewport_rect().size
	var fit := summary_fit(viewport_size)
	content.scale = Vector2.ONE * fit
	content.position = ((viewport_size - RUN_SUMMARY_MASTER_SIZE * fit) * 0.5).floor()

func fit_title_background(title_scene: Control) -> void:
	# O cenário compensa a escala legada do palco e usa aspect-cover uniforme.
	var vp := get_viewport_rect().size
	var cover := maxf(vp.x / 1344.0, vp.y / 752.0)
	title_scene.scale = Vector2(cover / stage.scale.x, cover / stage.scale.y)
	var target := (vp - Vector2(1344, 752) * cover) * 0.5
	title_scene.position = Vector2(
		(target.x - stage.position.x) / stage.scale.x,
		(target.y - stage.position.y) / stage.scale.y
	)

# Equipamento usa um canvas lógico próprio e fica acima do palco legado. A escala
# continua uniforme em qualquer proporção; somente a sobra externa vira letterbox.
func place_equipment() -> void:
	if content == null or screen not in ["equipment", "mission_inventory"] or content.get_parent() != self: return
	var k := get_viewport().get_final_transform().get_scale().x   # lógico -> pixels da janela
	if k <= 0: k = 1.0
	var phys := get_viewport_rect().size * k
	var fit := minf(phys.x / 1344.0, phys.y / 752.0)
	var s := fit # 0.17: ocupa a janela também entre escalas inteiras
	content.scale = Vector2.ONE * (s / k)
	content.position = ((phys - Vector2(1344, 752) * s) * 0.5).floor() / k
	content.z_index = 20

func panel(parent: Control, rect: Rect2, bg: Color = Color("0b2430"), outline: Color = Color("3d929f")) -> Panel:
	var p := Panel.new(); p.position = rect.position; p.size = rect.size; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new(); style.bg_color = bg; style.border_color = outline; style.set_border_width_all(2); style.set_corner_radius_all(5)
	p.add_theme_stylebox_override("panel", style); parent.add_child(p); return p

func label(parent: Control, rect: Rect2, caption: String, font_size: int = 18, color: Color = CYAN) -> Label:
	var l := Label.new(); l.position = rect.position; l.size = rect.size; l.text = caption
	l.add_theme_font_size_override("font_size", font_size); l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(l); return l

func button(parent: Control, rect: Rect2, caption: String, callback: Callable, transparent: bool = false) -> Button:
	var b := Button.new(); b.position = rect.position; b.size = rect.size; b.text = caption
	b.add_theme_font_size_override("font_size", 19); b.add_theme_color_override("font_color", CYAN)
	var normal := StyleBoxFlat.new(); normal.bg_color = Color(0, 0, 0, 0) if transparent else Color("0b2a34")
	normal.border_color = Color(0, 0, 0, 0) if transparent else Color("3f8390"); normal.set_border_width_all(2); normal.set_corner_radius_all(5)
	var hover := normal.duplicate(); hover.bg_color = Color(0.05, 0.55, 0.66, 0.22) if transparent else Color("174653"); hover.border_color = CYAN
	var pressed := hover.duplicate(); pressed.bg_color = Color("185869")
	b.add_theme_stylebox_override("normal", normal); b.add_theme_stylebox_override("hover", hover); b.add_theme_stylebox_override("focus", hover); b.add_theme_stylebox_override("pressed", pressed)
	b.pressed.connect(callback); parent.add_child(b); return b

func show_screen(next: String) -> void:
	screen = next
	backdrop.visible = true
	backdrop.color = Color(0.015, 0.025, 0.04, 0.9) if next in ["pause", "summary"] else Color("05080d")
	if content != null:
		content.get_parent().remove_child(content); content.queue_free()
	content = Control.new(); content.size = RUN_SUMMARY_MASTER_SIZE if next == "summary" else Vector2(1344, 752)
	content.clip_contents = false
	if next in ["equipment", "mission_inventory"]: add_child(content); place_equipment()
	elif next == "summary": add_child(content); place_summary()
	else: stage.add_child(content)
	rows.clear(); slot_buttons.clear(); preview = null; detail = null; live_status = null; main_resume = null; telemetry = null; equipment = null; encyclopedia = null
	if next in ["equipment", "mission_inventory"]: build_equipment(next == "mission_inventory"); return
	if next not in ["pause", "summary"]:
		if next == "main":
			var title_scene := title_background(); content.add_child(title_scene)
		elif next in ["characters", "characters_coop", "play"]:
			var concept_path := CHARACTER_CONCEPT if next == "characters" else (CHARACTER_COOP_CONCEPT if next == "characters_coop" else ADVENTURE_CONCEPT)
			var concept := concept_art(concept_path, "MenuConceptArt")
			content.add_child(concept)
		else:
			if next == "online":
				var bg := TextureRect.new(); bg.name = "SecondaryMenuBackdrop"; bg.texture = load("res://assets/ui/online.png")
				bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.size = Vector2(1344, 752); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
				content.add_child(bg)
			else:
				var secondary_scene := unbranded_background("SecondaryMenuScene", "SecondaryMenuBackdrop")
				content.add_child(secondary_scene); fit_title_background(secondary_scene)
	match next:
		"main": build_main()
		"characters": build_characters()
		"characters_coop": build_characters_coop()
		"online": build_online()
		"play": build_play()
		"pause": build_pause()
		"summary": build_summary()
		"seed": build_seed()
		"options": build_options()
		"encyclopedia": build_encyclopedia()
	focus_first.call_deferred()   # navegação pelo controle

func open(page: String = "main") -> void:
	if app.playing and page == "equipment": page = "pause"
	show(); app.paused = app.playing and not app.online
	show_screen(page)

func close() -> void:
	if not app.playing: show_screen("main"); return
	hide(); app.paused = false
	# A UI click must not become a weapon shot in the same frame.
	app.ui_input_block = 0.2

# ── Tela inicial: o vídeo é cenário; todo o console e seus estados são controles vivos.
const TITLE_DIR := "res://assets/ui/title/"
const TITLE_SCENE_CROP := Rect2(384, 107, 960, 537)
const TITLE_TIPS := ["Voltar para a expedição em andamento", "Escolher personagem e modo", "Hospedar ou entrar por IP",
	"Escolher uma seed para as docas", "Carregar expedição salva", "Resolução, modo de tela, FPS, câmera, áudio e controles", "Sair do jogo",
	"Consultar monstros, itens e robôs"]
var title_video: VideoStreamPlayer

func title_background() -> Control:
	var still_texture = load(TITLE_DIR + "title_still.png") if ResourceLoader.exists(TITLE_DIR + "title_still.png") else null
	if still_texture == null:
		var fallback := MenuBackground.new(); fallback.name = "TitleSceneCrop"; fallback.scene_only = true
		return fallback
	var root := Control.new(); root.name = "TitleSceneCrop"; root.size = Vector2(1344, 752); root.clip_contents = true; root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cropped := AtlasTexture.new(); cropped.atlas = still_texture; cropped.region = TITLE_SCENE_CROP
	var still := TextureRect.new(); still.name = "TitleStillCropped"; still.texture = cropped
	still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; still.size = root.size; still.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(still)
	var stream = load(TITLE_DIR + "title_loop.ogv") if ResourceLoader.exists(TITLE_DIR + "title_loop.ogv") else null
	if stream != null and DisplayServer.get_name() != "headless":
		title_video = VideoStreamPlayer.new(); title_video.stream = stream; title_video.expand = true
		var video_rect := title_video_rect()
		title_video.position = video_rect.position; title_video.size = video_rect.size
		title_video.mouse_filter = Control.MOUSE_FILTER_IGNORE; title_video.autoplay = true
		if "loop" in title_video: title_video.set("loop", true)
		title_video.finished.connect(title_video.play)   # garante o loop em qualquer versão
		root.add_child(title_video)
	return root

func title_video_rect() -> Rect2:
	var crop_scale := 1344.0 / TITLE_SCENE_CROP.size.x
	return Rect2(-TITLE_SCENE_CROP.position * crop_scale, Vector2(1344, 752) * crop_scale)

func unbranded_title_texture() -> Texture2D:
	if not ResourceLoader.exists(TITLE_DIR + "title_still.png"): return null
	var cropped := AtlasTexture.new()
	cropped.atlas = load(TITLE_DIR + "title_still.png")
	cropped.region = TITLE_SCENE_CROP
	return cropped

func unbranded_background(root_name: String, visual_name: String, force_fallback: bool = false) -> Control:
	var root := Control.new(); root.name = root_name; root.size = Vector2(1344, 752)
	root.clip_contents = true; root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = null if force_fallback else unbranded_title_texture()
	if texture != null:
		var still := TextureRect.new(); still.name = visual_name; still.texture = texture
		still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; still.stretch_mode = TextureRect.STRETCH_SCALE
		still.size = root.size; still.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(still)
	else:
		var fallback := MenuBackground.new(); fallback.name = visual_name; fallback.scene_only = true
		root.add_child(fallback)
	return root

func title_style(fill: Color, edge: Color, width: int = 2, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge
	style.set_border_width_all(width); style.set_corner_radius_all(radius)
	style.content_margin_left = 15; style.content_margin_right = 15
	return style

func title_button(parent: Control, i: int, rect: Rect2, caption: String, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new(); b.position = rect.position; b.size = rect.size; b.text = caption
	b.name = "Title_%d" % i; b.tooltip_text = TITLE_TIPS[i]; b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER; b.add_theme_font_size_override("font_size", 23 if primary else 17)
	b.add_theme_color_override("font_color", Color("f1d58c") if not primary else Color("f5ead0"))
	b.add_theme_color_override("font_hover_color", Color("ffffff")); b.add_theme_color_override("font_focus_color", Color("ffffff"))
	b.add_theme_color_override("font_pressed_color", Color("ffffff")); b.add_theme_color_override("font_disabled_color", Color("59605b"))
	var normal := title_style(Color("19211d") if not primary else Color("19383b"), Color("8d7540") if not primary else Color("56cdd4"), 2, 5)
	var hover := title_style(Color("22474a"), Color("78f5f4"), 3, 5)
	var pressed := title_style(Color("153237"), Color("f1c96d"), 3, 5)
	var disabled := title_style(Color("101511"), Color("343a31"), 1, 5)
	b.add_theme_stylebox_override("normal", normal); b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover); b.add_theme_stylebox_override("pressed", pressed); b.add_theme_stylebox_override("disabled", disabled)
	b.mouse_entered.connect(func():
		if not b.disabled: b.grab_focus())
	b.pressed.connect(callback); parent.add_child(b); return b

func concept_art(path: String, art_name: String) -> TextureRect:
	var art := TextureRect.new(); art.name = art_name
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture = load(path)
	art.size = Vector2(1344, 752)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art

func concept_button(parent: Control, button_name: String, rect: Rect2, callback: Callable, disabled: bool = false) -> Button:
	var hit := Button.new(); hit.name = button_name; hit.position = rect.position; hit.size = rect.size
	hit.text = ""; hit.focus_mode = Control.FOCUS_ALL; hit.disabled = disabled
	var normal := StyleBoxFlat.new(); normal.bg_color = Color.TRANSPARENT
	var hover := StyleBoxFlat.new(); hover.bg_color = Color(0.16, 0.95, 1.0, 0.11)
	hover.border_color = CYAN; hover.set_border_width_all(3); hover.set_corner_radius_all(7)
	var pressed := hover.duplicate() as StyleBoxFlat; pressed.border_color = GOLD
	var inactive := normal.duplicate() as StyleBoxFlat
	hit.add_theme_stylebox_override("normal", normal)
	hit.add_theme_stylebox_override("hover", hover)
	hit.add_theme_stylebox_override("focus", hover)
	hit.add_theme_stylebox_override("pressed", pressed)
	hit.add_theme_stylebox_override("disabled", inactive)
	hit.mouse_entered.connect(func():
		if not hit.disabled: hit.grab_focus())
	hit.pressed.connect(callback); parent.add_child(hit)
	return hit

func continue_title() -> void:
	if app.playing: close()
	elif app.has_saved_game(): app.load_game()

func build_main() -> void:
	var art := concept_art(TITLE_CONCEPT, "TitleConceptArt")
	var ink := ShaderMaterial.new(); ink.shader = TITLE_CONCEPT_SHADER; art.material = ink
	content.add_child(art)
	var lockup := Control.new(); lockup.name = "TitleLockup"; lockup.position = Vector2(25, 85)
	lockup.size = Vector2(485, 230); lockup.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(lockup)
	var title_top := label(lockup, Rect2(0, 0, 470, 58), "SEVERENCE", 42, Color.TRANSPARENT); title_top.name = "TitlePrimary"
	var title_bottom := label(lockup, Rect2(0, 62, 470, 58), "ECOS DO TEMPO", 38, Color.TRANSPARENT); title_bottom.name = "TitleSubtitle"
	var deck := Panel.new(); deck.name = "TitleCommandDeck"; deck.size = Vector2(1344, 752)
	var empty := StyleBoxEmpty.new(); deck.add_theme_stylebox_override("panel", empty)
	deck.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(deck)
	var callbacks: Dictionary = {
		"new": func(): show_screen("characters"), "online": func(): show_screen("online"),
		"options": func(): show_screen("options"),
		"exit": func(): app.save_progress(); app.get_tree().quit(),
	}
	var has_continue: bool = app.playing or app.has_saved_game()
	if app.playing:
		var unavailable_new := ColorRect.new(); unavailable_new.name = "NewRunUnavailable"
		unavailable_new.position = Vector2(44, 588); unavailable_new.size = Vector2(477, 84)
		unavailable_new.color = Color(0.02, 0.03, 0.03, 0.5); unavailable_new.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck.add_child(unavailable_new)
	if not has_continue:
		var unavailable := ColorRect.new(); unavailable.name = "ContinueUnavailable"
		unavailable.position = Vector2(553, 606); unavailable.size = Vector2(286, 67)
		unavailable.color = Color(0.02, 0.03, 0.03, 0.52); unavailable.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck.add_child(unavailable)
	var new_run := concept_button(deck, "Title_1", Rect2(40, 586, 483, 88), callbacks.new, app.playing)
	new_run.tooltip_text = "Escolher personagem e iniciar uma nova expedição"
	main_resume = concept_button(deck, "Title_0", Rect2(547, 607, 299, 68), continue_title, not has_continue)
	if app.playing: main_resume.tooltip_text = "Voltar para a expedição em andamento"
	elif app.has_saved_game(): main_resume.tooltip_text = "Carregar a última expedição salva"
	else: main_resume.tooltip_text = "Nenhuma expedição para continuar"
	var online_button := concept_button(deck, "Title_2", Rect2(43, 680, 261, 58), callbacks.online)
	var options_button := concept_button(deck, "Title_5", Rect2(311, 680, 245, 58), callbacks.options)
	var exit_button := concept_button(deck, "Title_6", Rect2(561, 680, 215, 58), callbacks.exit)
	if app.network_status != "OFFLINE":
		var status_cover := ColorRect.new(); status_cover.name = "TitleNetworkStatusCover"
		status_cover.position = Vector2(848, 685); status_cover.size = Vector2(112, 40)
		status_cover.color = Color("182222"); status_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck.add_child(status_cover)
	var status := label(deck, Rect2(851, 691, 104, 27), app.network_status, 15, Color.TRANSPARENT if app.network_status == "OFFLINE" else CYAN)
	status.name = "TitleNetworkStatus"; status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var visual_order: Array[Button] = [new_run, main_resume, online_button, options_button, exit_button]
	var enabled_order: Array[Button] = []
	for title_action in visual_order:
		if not title_action.disabled: enabled_order.append(title_action)
	for i in enabled_order.size():
		var current := enabled_order[i]
		current.focus_next = current.get_path_to(enabled_order[(i + 1) % enabled_order.size()])
		current.focus_previous = current.get_path_to(enabled_order[(i - 1 + enabled_order.size()) % enabled_order.size()])
	new_run.focus_neighbor_right = new_run.get_path_to(main_resume if not main_resume.disabled else online_button); new_run.focus_neighbor_bottom = new_run.get_path_to(online_button)
	main_resume.focus_neighbor_left = main_resume.get_path_to(new_run); main_resume.focus_neighbor_bottom = main_resume.get_path_to(exit_button)
	online_button.focus_neighbor_top = online_button.get_path_to(new_run); online_button.focus_neighbor_right = online_button.get_path_to(options_button)
	options_button.focus_neighbor_top = options_button.get_path_to(new_run); options_button.focus_neighbor_left = options_button.get_path_to(online_button); options_button.focus_neighbor_right = options_button.get_path_to(exit_button)
	exit_button.focus_neighbor_top = exit_button.get_path_to(main_resume if not main_resume.disabled else new_run); exit_button.focus_neighbor_left = exit_button.get_path_to(options_button)

func overlay(title: String) -> Panel:
	var dim := ColorRect.new(); dim.color = Color(0.015, 0.025, 0.04, 0.78); dim.size = Vector2(1344, 752); content.add_child(dim)
	var p := panel(content, Rect2(400, 125, 700, 520), Color("102922"), Color("75b5a2"))
	label(p, Rect2(30, 20, 640, 55), title, 30, GOLD)
	return p

func build_characters() -> void:
	var roster := Control.new(); roster.name = "CharacterRoster"; roster.size = Vector2(1344, 752)
	roster.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(roster)
	var pick := concept_button(roster, "CharacterMarty", Rect2(654, 139, 222, 171), func(): show_screen("play"))
	pick.tooltip_text = "Marty disponível — escolher aventura"
	var hero_pick := concept_button(roster, "CharacterMartyHero", Rect2(230, 230, 320, 420), func(): show_screen("play"))
	hero_pick.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]: hero_pick.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hero_pick.tooltip_text = "Escolher Marty"
	var locked_regions := [Rect2(882, 139, 224, 171), Rect2(654, 316, 222, 171),
		Rect2(882, 316, 224, 171), Rect2(654, 489, 222, 168), Rect2(882, 489, 224, 168)]
	for i in locked_regions.size():
		var locked := concept_button(roster, "CharacterLocked%d" % (i + 1), locked_regions[i], func(): pass, true)
		locked.tooltip_text = "Viajante ainda bloqueado"
	var back := concept_button(roster, "CharacterBack", Rect2(790, 661, 310, 62), func(): show_screen("main"))
	back.tooltip_text = "Voltar ao menu"
	pick.focus_next = pick.get_path_to(back); back.focus_previous = back.get_path_to(pick)

func build_characters_coop() -> void:
	var roster := Control.new(); roster.name = "CoopCharacterRoster"; roster.size = Vector2(1344, 752)
	roster.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(roster)
	var pick := concept_button(roster, "CharacterMarty", Rect2(451, 224, 136, 182), func(): pass)
	pick.tooltip_text = "Marty selecionado para os dois jogadores"
	var locked_regions := [Rect2(591, 224, 151, 182), Rect2(745, 224, 151, 182),
		Rect2(451, 412, 136, 185), Rect2(591, 412, 151, 185), Rect2(745, 412, 151, 185)]
	for i in locked_regions.size():
		concept_button(roster, "CharacterLocked%d" % (i + 1), locked_regions[i], func(): pass, true)
	var back := concept_button(roster, "CharacterBack", Rect2(614, 647, 250, 65), func(): show_screen("play"))
	var confirm := concept_button(roster, "ConfirmCharacters", Rect2(868, 647, 290, 65), func(): read_equipment(); show_screen("equipment"))
	confirm.tooltip_text = "Confirmar Marty para os dois jogadores"
	back.focus_next = back.get_path_to(confirm); confirm.focus_previous = confirm.get_path_to(back)

func build_play() -> void:
	if pending_mode not in ["solo", "ai", "local"]: pending_mode = "solo"
	var choices := Control.new(); choices.name = "AdventureChoices"; choices.size = Vector2(1344, 752)
	choices.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(choices)
	var solo := concept_button(choices, "SoloChoice", Rect2(348, 191, 311, 312), func(): choose_adventure("solo"))
	solo.tooltip_text = "Só Marty"
	var ai := concept_button(choices, "AIChoice", Rect2(682, 191, 312, 312), func(): choose_adventure("ai"))
	ai.tooltip_text = "Marty com parceiro controlado pelo jogo"
	var local := concept_button(choices, "LocalChoice", Rect2(309, 519, 730, 90), func(): choose_adventure("local"))
	local.tooltip_text = "Dois jogadores no mesmo computador"
	var back := concept_button(choices, "AdventureBack", Rect2(346, 630, 280, 68), func(): show_screen("characters"))
	back.tooltip_text = "Voltar aos personagens"
	solo.focus_next = solo.get_path_to(ai); ai.focus_next = ai.get_path_to(local)
	local.focus_next = local.get_path_to(back); back.focus_next = back.get_path_to(solo)

func choose_adventure(mode: String) -> void:
	pending_mode = mode
	if mode == "local": show_screen("characters_coop")
	else: read_equipment(); show_screen("equipment")

func build_pause() -> void:
	var p := panel(content, Rect2(222, 110, 900, 532), Color("11272b"), Color("1c2829"))
	p.name = "PausePanel"
	if ResourceLoader.exists(PAUSE_FRAME):
		var frame := TextureRect.new(); frame.name = "PauseFrame"; frame.texture = load(PAUSE_FRAME)
		frame.position = Vector2.ZERO; frame.size = p.size
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE; p.add_child(frame)
	label(p, Rect2(110, 86, 680, 40), "PAUSA", 31, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(p, Rect2(110, 125, 680, 28), "Expedição em andamento", 20, Color("c6dccd")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var mission_inventory := button(p, Rect2(160, 158, 580, 42), "INVENTÁRIO DA MISSÃO   [B]", func(): read_equipment(); show_screen("mission_inventory"))
	mission_inventory.name = "MissionInventory"
	mission_inventory.tooltip_text = "Consultar itens levados e recursos obtidos nesta missão"
	mission_inventory.add_theme_font_size_override("font_size", 21)
	mission_inventory.add_theme_color_override("font_color", GOLD)
	var inventory_normal := mission_inventory.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	inventory_normal.bg_color = Color("16444a"); inventory_normal.border_color = CYAN; inventory_normal.set_border_width_all(3)
	mission_inventory.add_theme_stylebox_override("normal", inventory_normal)
	var resume := button(p, Rect2(160, 208, 580, 42), "CONTINUAR", close)
	resume.name = "ResumeGame"
	var save := button(p, Rect2(160, 258, 580, 42), "SALVAR JOGO", func():
		if app.save_game(): telemetry.text = "Expedição salva."
		else: telemetry.text = "Não foi possível salvar esta partida.")
	save.name = "SaveGame"; save.disabled = app.online
	var leave := button(p, Rect2(160, 308, 580, 42), "VOLTAR AO MENU", func():
		if not app.return_to_title():
			telemetry.text = "Não foi possível salvar. A partida continua em pausa."
			telemetry.add_theme_color_override("font_color", Color("ffad99")))
	leave.name = "ReturnToMenu"
	var encyclopedia_button := button(p, Rect2(160, 358, 580, 42), "ARQUIVO DO REFÚGIO", func(): open_encyclopedia("pause"))
	encyclopedia_button.name = "PauseEncyclopedia"
	mission_inventory.focus_neighbor_bottom = mission_inventory.get_path_to(resume); mission_inventory.focus_next = mission_inventory.get_path_to(resume)
	resume.focus_neighbor_top = resume.get_path_to(mission_inventory); resume.focus_previous = resume.get_path_to(mission_inventory)
	resume.focus_neighbor_bottom = resume.get_path_to(save); resume.focus_next = resume.get_path_to(save)
	save.focus_neighbor_top = save.get_path_to(resume); save.focus_neighbor_bottom = save.get_path_to(leave)
	save.focus_previous = save.get_path_to(resume); save.focus_next = save.get_path_to(leave)
	leave.focus_neighbor_top = leave.get_path_to(save); leave.focus_previous = leave.get_path_to(save)
	leave.focus_neighbor_bottom = leave.get_path_to(encyclopedia_button); leave.focus_next = leave.get_path_to(encyclopedia_button)
	encyclopedia_button.focus_neighbor_top = encyclopedia_button.get_path_to(leave)
	encyclopedia_button.focus_previous = encyclopedia_button.get_path_to(leave)
	encyclopedia_button.focus_neighbor_bottom = encyclopedia_button.get_path_to(mission_inventory)
	encyclopedia_button.focus_next = encyclopedia_button.get_path_to(mission_inventory)
	mission_inventory.focus_neighbor_top = mission_inventory.get_path_to(encyclopedia_button)
	mission_inventory.focus_previous = mission_inventory.get_path_to(encyclopedia_button)
	telemetry = label(p, Rect2(110, 406, 680, 42), "Esc ou Start também continua a partida.", 15, GOLD)
	telemetry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func summary_time(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	return "%02d:%02d" % [total / 60, total % 60]

func summary_killer_texture(source: String) -> Texture2D:
	if source not in ["cult", "fish", "crawler", "crawler_small", "brute"]: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/enemies/docas_anim.png")
	var row: int = int({"cult": 0, "fish": 1, "crawler": 2, "crawler_small": 2, "brute": 3}.get(source, 0))
	atlas.region = Rect2(0, row * 96, 144, 96)
	return atlas

func summary_stat(parent: Control, rect: Rect2, title: String, value: String, accent: Color = CYAN) -> void:
	var box := panel(parent, rect, Color("071b24d9"), Color("9c7038"))
	var head := label(box, Rect2(8, 5, rect.size.x - 16, 22), title, 13, GOLD); head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var val := label(box, Rect2(8, 26, rect.size.x - 16, rect.size.y - 30), value, 25, accent); val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func summary_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null: return imported
	if not FileAccess.file_exists(path): return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty(): return null
	return ImageTexture.create_from_image(image)

func summary_art(parent: Control, path: String, rect: Rect2, alpha: float = 1.0) -> void:
	var texture := summary_texture(path)
	if texture == null: return
	var art := TextureRect.new(); art.texture = texture; art.position = rect.position; art.size = rect.size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; art.modulate = Color(1, 1, 1, alpha)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(art)

func summary_live_label(parent: Control, rect: Rect2, caption: String, font_size: int, color: Color, outline_size: int = 3, outline_color: Color = Color("07131b")) -> Label:
	var live := label(parent, rect, caption, font_size, color)
	live.add_theme_constant_override("outline_size", outline_size)
	live.add_theme_color_override("font_outline_color", outline_color)
	live.add_theme_constant_override("shadow_offset_x", 2)
	live.add_theme_constant_override("shadow_offset_y", 3)
	live.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	return live

func faithful_portrait_path(data: Dictionary, victory: bool) -> String:
	if victory: return RUN_SUMMARY_FAITHFUL + "portrait_victory.png"
	if str(data.get("fatal_source", "unknown")) == "fish": return RUN_SUMMARY_FAITHFUL + "portrait_fish.png"
	return RUN_SUMMARY_FAITHFUL + "portrait_fallback.png"

func faithful_assets_ready(data: Dictionary, victory: bool) -> bool:
	var required := ["shell.png", "portrait_fallback.png"]
	for kind in ["scrap", "fragment", "blueprint", "relic"]:
		required.append("loot/%s.png" % kind)
	for relative_path in required:
		if summary_texture(RUN_SUMMARY_FAITHFUL + relative_path) == null: return false
	return true

func faithful_loot(parent: Control, rect: Rect2, icon_name: String, title: String, value: int) -> void:
	var texture := summary_texture(RUN_SUMMARY_FAITHFUL + "loot/" + icon_name + ".png")
	if texture != null:
		var icon := TextureRect.new(); icon.texture = texture; icon.position = rect.position + Vector2(24, 8); icon.size = Vector2(84, 84)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(icon)
	var loot_title := summary_live_label(parent, Rect2(rect.position.x, rect.position.y + 125, rect.size.x, 22), title, 14, Color("f7e6b6"), 2)
	loot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var loot_value := summary_live_label(parent, Rect2(rect.position.x, rect.position.y + 147, rect.size.x, 34), str(value), 27, CYAN, 3)
	loot_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func build_summary_faithful(data: Dictionary, victory: bool) -> void:
	var root := Control.new(); root.name = "RunSummary"; root.size = RUN_SUMMARY_MASTER_SIZE; content.add_child(root)
	summary_art(root, RUN_SUMMARY_FAITHFUL + "shell.png", Rect2(Vector2.ZERO, RUN_SUMMARY_MASTER_SIZE))

	var title_text := "EXPEDIÇÃO CONCLUÍDA" if victory else "FIM DA EXPEDIÇÃO"
	var title_size := 58 if victory else 72
	var title := summary_live_label(root, Rect2(365, 58, 860, 138), title_text, title_size, Color("f4ddb0"), 9, Color("1b211d"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var grade_head := summary_live_label(root, Rect2(1300, 79, 196, 40), "NOTA", 24, Color("f7e6b6"), 3)
	grade_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grade_text := str(data.get("grade", "D")).left(2)
	var grade := summary_live_label(root, Rect2(1285, 108, 226, 140), grade_text, 100, Color("ffb72f"), 8, Color("462608"))
	grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; grade.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var stat_specs := [
		[Rect2(320, 231, 250, 82), "TEMPO", summary_time(float(data.get("time", 0.0)))],
		[Rect2(621, 231, 250, 82), "PROGRESSO", "%d%%" % int(data.get("progress", 0))],
		[Rect2(920, 231, 250, 82), "INIMIGOS", str(int(data.get("kills", 0)))],
	]
	for spec in stat_specs:
		var heading := summary_live_label(root, Rect2(spec[0].position, Vector2(spec[0].size.x, 26)), spec[1], 18, Color("f5dda1"), 2)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var value := summary_live_label(root, Rect2(spec[0].position + Vector2(0, 24), Vector2(spec[0].size.x, 54)), spec[2], 40, CYAN, 4)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var report_title := summary_live_label(root, Rect2(365, 371, 545, 54), "RELATÓRIO DE EXTRAÇÃO" if victory else "NOTA DE FALECIMENTO", 31, Color("2b251d"), 1, Color("d5c18d"))
	report_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var portrait := summary_texture(faithful_portrait_path(data, victory))
	if portrait == null: portrait = summary_texture(RUN_SUMMARY_FAITHFUL + "portrait_fallback.png")
	if portrait != null:
		var picture := TextureRect.new(); picture.name = "SummaryPortrait"
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.texture = portrait; picture.position = Vector2(337, 468); picture.size = Vector2(238, 260); picture.clip_contents = true
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; picture.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(picture)
	var note_text := str(data.get("obituary", "A linha do tempo perdeu o relatório.")).left(240)
	if victory: note_text = str(data.get("obituary", "O núcleo temporal foi recuperado e a expedição voltou inteira."))
	var note := summary_live_label(root, Rect2(610, 468, 310, 188), note_text, 24, Color("231d16"), 1, Color("ead9b0"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.clip_text = true; note.max_lines_visible = 6; note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var cause := "RESULTADO: NÚCLEO RECUPERADO" if victory else "CAUSA: " + str(data.get("fatal_source", "DESCONHECIDA")).to_upper().left(32)
	var cause_label := summary_live_label(root, Rect2(610, 660, 310, 25), cause, 13, Color("493b2e"), 1, Color("ead9b0"))
	var seed_label := summary_live_label(root, Rect2(610, 697, 310, 24), "SEED %d  •  DOCAS DE 1941" % int(data.get("seed", 0)), 13, Color("493b2e"), 1, Color("ead9b0"))
	cause_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	cause_label.clip_text = true; cause_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	seed_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)

	var loot_head := summary_live_label(root, Rect2(1010, 361, 555, 38), "OBTIDO NA RUN", 23, Color("f5dda1"), 3)
	loot_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	faithful_loot(root, Rect2(1007, 416, 132, 142), "scrap", "SUCATA", int(data.get("scrap", 0)))
	faithful_loot(root, Rect2(1154, 416, 132, 142), "fragment", "FRAGMENTOS", int(data.get("fragments", 0)))
	faithful_loot(root, Rect2(1300, 416, 132, 142), "blueprint", "BAÚS", int(data.get("chests", 0)))
	faithful_loot(root, Rect2(1447, 416, 132, 142), "relic", "NÚCLEO", int(data.get("nucleus", 0)))

	var perf_head := summary_live_label(root, Rect2(1010, 641, 555, 36), "DESEMPENHO NA RUN", 23, Color("f5dda1"), 3)
	perf_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var perf_specs := [
		[Rect2(1004, 693, 182, 72), "DANO CAUSADO", str(int(data.get("damage_dealt", 0)))],
		[Rect2(1200, 693, 182, 72), "DANO RECEBIDO", str(int(data.get("damage_received", 0)))],
		[Rect2(1395, 693, 182, 72), "MAIOR COMBO", str(int(data.get("max_streak", 0)))],
	]
	for spec in perf_specs:
		var perf_label := summary_live_label(root, Rect2(spec[0].position, Vector2(spec[0].size.x, 24)), spec[1], 14, Color("f7e6b6"), 2)
		perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var perf_value := summary_live_label(root, Rect2(spec[0].position + Vector2(0, 24), Vector2(spec[0].size.x, 43)), spec[2], 28, CYAN, 3)
		perf_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var retry := button(root, Rect2(425, 803, 495, 75), "▶  NOVA EXPEDIÇÃO", app.summary_new_run, true)
	retry.name = "SummaryNewRun"; retry.add_theme_font_size_override("font_size", 28); retry.add_theme_color_override("font_color", Color("ecffff")); retry.add_theme_constant_override("outline_size", 4); retry.add_theme_color_override("font_outline_color", Color("06343d"))
	if app.online and not app.hosting:
		retry.disabled = true; retry.text = "AGUARDANDO ANFITRIÃO"
	var refuge := button(root, Rect2(975, 803, 440, 75), "⌂  VOLTAR AO REFÚGIO", app.summary_return_refuge, true)
	refuge.name = "SummaryRefuge"; refuge.add_theme_font_size_override("font_size", 24); refuge.add_theme_color_override("font_color", Color("f7e6b6")); refuge.add_theme_constant_override("outline_size", 4); refuge.add_theme_color_override("font_outline_color", Color("2b1b08"))
	retry.focus_neighbor_right = retry.get_path_to(refuge); retry.focus_next = retry.get_path_to(refuge)
	refuge.focus_neighbor_left = refuge.get_path_to(retry); refuge.focus_previous = refuge.get_path_to(retry)

func summary_loot(parent: Control, x: float, icon_name: String, title: String, value: int) -> void:
	var box := panel(parent, Rect2(x, 0, 102, 122), Color("061922e8"), Color("9c7038"))
	var path := RUN_SUMMARY_LOOT + icon_name + ".png"
	var texture := summary_texture(path)
	if texture != null:
		var icon := TextureRect.new(); icon.texture = texture; icon.position = Vector2(22, 8); icon.size = Vector2(58, 58)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; box.add_child(icon)
	label(box, Rect2(4, 68, 94, 20), title, 12, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(box, Rect2(4, 87, 94, 29), str(value), 22, CYAN).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func build_summary() -> void:
	var data: Dictionary = app.sim.last_run_summary
	var victory: bool = str(data.get("outcome", "death")) == "victory"
	if not summary_force_fallback and faithful_assets_ready(data, victory):
		build_summary_faithful(data, victory)
	else:
		build_summary_fallback()

func build_summary_fallback() -> void:
	var data: Dictionary = app.sim.last_run_summary
	var victory: bool = str(data.get("outcome", "death")) == "victory"
	var legacy := Control.new(); legacy.name = "SummaryFallbackCanvas"; legacy.size = Vector2(1344, 752)
	var legacy_fit := minf(RUN_SUMMARY_MASTER_SIZE.x / legacy.size.x, RUN_SUMMARY_MASTER_SIZE.y / legacy.size.y)
	legacy.scale = Vector2.ONE * legacy_fit
	legacy.position = ((RUN_SUMMARY_MASTER_SIZE - legacy.size * legacy_fit) * 0.5).floor()
	content.add_child(legacy)
	var root := panel(legacy, Rect2(32, 16, 1280, 720), Color("07141ced"), Color("9c7038"))
	root.name = "RunSummary"
	var frame_texture := summary_texture(RUN_SUMMARY_FRAME)
	if frame_texture != null:
		var art := TextureRect.new(); art.texture = frame_texture; art.position = Vector2.ZERO; art.size = root.size
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_SCALE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; art.modulate = Color(1, 1, 1, 0.38)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(art)
	var title_text := "EXPEDIÇÃO CONCLUÍDA" if victory else "FIM DA EXPEDIÇÃO"
	var title := label(root, Rect2(46, 20, 1015, 66), title_text, 43, GOLD); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grade_box := panel(root, Rect2(1080, 15, 155, 155), Color("061922e8"), CYAN)
	summary_art(grade_box, RUN_SUMMARY_DIR + "grade_ring.png", Rect2(27, 42, 100, 100), 0.72)
	label(grade_box, Rect2(10, 12, 135, 28), "NOTA", 18, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grade_label := label(grade_box, Rect2(10, 48, 135, 90), str(data.get("grade", "D")), 58, Color("ffb43c"))
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; grade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_stat(root, Rect2(62, 92, 280, 80), "TEMPO", summary_time(float(data.get("time", 0.0))))
	summary_stat(root, Rect2(356, 92, 280, 80), "PROGRESSO", "%d%%" % int(data.get("progress", 0)))
	summary_stat(root, Rect2(650, 92, 280, 80), "INIMIGOS", str(int(data.get("kills", 0))))

	var obituary := panel(root, Rect2(48, 190, 708, 405), Color("d8c69ce8"), Color("6d482a"))
	summary_art(obituary, RUN_SUMMARY_DIR + "frame_obituary.png", Rect2(0, 0, 708, 405), 0.38)
	label(obituary, Rect2(22, 16, 664, 45), "RELATÓRIO DE EXTRAÇÃO" if victory else "NOTA DE FALECIMENTO", 29, Color("261c16")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var portrait_panel := panel(obituary, Rect2(24, 78, 210, 212), Color("071923"), Color("6d482a"))
	var killer := summary_texture(RUN_SUMMARY_LOOT + "relic.png") if victory else summary_killer_texture(str(data.get("fatal_source", "unknown")))
	if killer != null:
		var pic := TextureRect.new(); pic.texture = killer; pic.position = Vector2(8, 22); pic.size = Vector2(194, 160)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; portrait_panel.add_child(pic)
	else:
		label(portrait_panel, Rect2(0, 45, 210, 110), "☠", 72, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var note := label(obituary, Rect2(260, 82, 420, 175), str(data.get("obituary", "A linha do tempo perdeu o relatório.")), 25, Color("201914"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var cause := "RESULTADO: NÚCLEO RECUPERADO" if victory else "CAUSA: " + str(data.get("fatal_source", "DESCONHECIDA")).to_upper()
	label(obituary, Rect2(260, 266, 420, 28), cause, 14, Color("463427"))
	label(obituary, Rect2(24, 322, 660, 44), "SEED %d  •  DOCAS DE 1941" % int(data.get("seed", 0)), 16, Color("463427")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var loot := panel(root, Rect2(780, 190, 452, 174), Color("071b24e8"), Color("9c7038"))
	summary_art(loot, RUN_SUMMARY_DIR + "loot_slot.png", Rect2(8, 38, 436, 128), 0.16)
	label(loot, Rect2(14, 8, 424, 30), "OBTIDO NA RUN", 21, GOLD)
	var loot_row := Control.new(); loot_row.position = Vector2(12, 42); loot_row.size = Vector2(428, 122); loot.add_child(loot_row)
	summary_loot(loot_row, 0, "scrap", "SUCATA", int(data.get("scrap", 0)))
	summary_loot(loot_row, 108, "fragment", "FRAGMENTOS", int(data.get("fragments", 0)))
	summary_loot(loot_row, 216, "blueprint", "BAÚS", int(data.get("chests", 0)))
	summary_loot(loot_row, 324, "relic", "NÚCLEO", int(data.get("nucleus", 0)))
	var performance := panel(root, Rect2(780, 380, 452, 215), Color("071b24e8"), Color("9c7038"))
	summary_art(performance, RUN_SUMMARY_DIR + "stat_slot.png", Rect2(8, 40, 436, 155), 0.08)
	label(performance, Rect2(14, 8, 424, 30), "DESEMPENHO NA RUN", 21, GOLD)
	summary_stat(performance, Rect2(12, 48, 136, 76), "DANO CAUSADO", str(int(data.get("damage_dealt", 0))))
	summary_stat(performance, Rect2(158, 48, 136, 76), "DANO RECEBIDO", str(int(data.get("damage_received", 0))))
	summary_stat(performance, Rect2(304, 48, 136, 76), "MAIOR COMBO", str(int(data.get("max_streak", 0))))
	label(performance, Rect2(12, 143, 428, 48), "CONCLUSÕES %d  •  DESAFIO %s  •  SEGREDO %s" % [int(data.get("clears", 0)), "SIM" if data.get("side_complete", false) else "NÃO", "SIM" if data.get("secret_open", false) else "NÃO"], 13, Color("c6dccd")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_art(root, RUN_SUMMARY_DIR + "button_primary.png", Rect2(180, 620, 430, 66))
	summary_art(root, RUN_SUMMARY_DIR + "button_secondary.png", Rect2(670, 620, 430, 66))
	var retry := button(root, Rect2(180, 620, 430, 66), "NOVA EXPEDIÇÃO", app.summary_new_run, true)
	retry.name = "SummaryNewRun"
	if app.online and not app.hosting:
		retry.disabled = true; retry.text = "AGUARDANDO ANFITRIÃO"
	var refuge := button(root, Rect2(670, 620, 430, 66), "VOLTAR AO REFÚGIO", app.summary_return_refuge, true)
	refuge.name = "SummaryRefuge"
	retry.focus_neighbor_right = retry.get_path_to(refuge); retry.focus_next = retry.get_path_to(refuge)
	refuge.focus_neighbor_left = refuge.get_path_to(retry); refuge.focus_previous = refuge.get_path_to(retry)

func build_online() -> void:
	# Keep the user's illustrated radio and its borders; replace only live regions.
	panel(content, Rect2(713, 353, 258, 38), Color("043441"), CYAN)
	app.address = LineEdit.new(); app.address.position = Vector2(715, 355); app.address.size = Vector2(254, 36); app.address.text = "127.0.0.1"
	app.address.add_theme_font_size_override("font_size", 23); app.address.add_theme_color_override("font_color", CYAN)
	content.add_child(app.address)
	button(content, Rect2(382, 396, 265, 59), "", func(): app.host_game(); app.apply_preferences(0), true)
	button(content, Rect2(711, 402, 263, 53), "", app.join_game, true)
	button(content, Rect2(334, 669, 130, 39), "", func(): show_screen("main"), true)
	panel(content, Rect2(425, 489, 513, 39), Color("042b36"), CYAN)
	app.status_label = label(content, Rect2(438, 493, 490, 33), "PRONTO • escolha hospedar ou conectar", 17)
	label(content, Rect2(355, 543, 660, 26), "Conexão direta por IP • internet requer UDP 24871 acessível", 15, GOLD)

func open_encyclopedia(return_screen: String) -> void:
	encyclopedia_return_screen = return_screen if return_screen in ["main", "options", "pause"] else "main"
	show_screen("encyclopedia")

func build_encyclopedia() -> void:
	encyclopedia = EncyclopediaScreen.new(); encyclopedia.host = self
	content.add_child(encyclopedia); encyclopedia.build()

func build_seed() -> void:
	var p := overlay("EXPEDIÇÃO DIRETA")
	label(p, Rect2(30, 87, 640, 44), "A mesma seed reproduz os encontros e atalhos das docas.", 18, Color("c6dccd"))
	app.seed_input = LineEdit.new(); app.seed_input.position = Vector2(30, 145); app.seed_input.size = Vector2(640, 52); app.seed_input.text = "1941"; app.seed_input.placeholder_text = "Digite um número"; p.add_child(app.seed_input)
	button(p, Rect2(30, 230, 640, 60), "EXPEDIÇÃO SOLO", func(): launch_seed("solo"))
	button(p, Rect2(30, 306, 640, 60), "EXPEDIÇÃO COM PARCEIRO IA", func(): launch_seed("ai"))
	button(p, Rect2(30, 425, 200, 50), "VOLTAR", func(): show_screen("main"))

func launch_seed(kind: String) -> void:
	var value: String = app.seed_input.text
	if not value.is_valid_int(): app.seed_input.placeholder_text = "Use um número inteiro"; app.seed_input.text = ""; return
	app.start_solo(); app.sim.coop = kind; app.sim.start_run(value.to_int()); app.apply_preferences(0)

var options_tab := "video"
var awaiting_bind := ""   # 0.18: nome da ação esperando a próxima tecla, ou "" se nenhuma
var bind_buttons: Dictionary = {}

func build_options() -> void:
	var dim := ColorRect.new(); dim.color = Color(0.015, 0.025, 0.04, 0.82); dim.size = Vector2(1344, 752); content.add_child(dim)
	var p := panel(content, Rect2(270, 50, 820, 650), Color("102922"), Color("75b5a2"))
	label(p, Rect2(30, 16, 400, 50), "OPÇÕES", 30, GOLD)
	for i in range(3):
		var tab: String = ["video", "audio", "controls"][i]
		var t := button(p, Rect2(300 + i * 170, 18, 160, 42), ["VÍDEO", "ÁUDIO", "CONTROLES"][i], func(): options_tab = tab; show_screen("options"))
		if tab == options_tab: t.add_theme_color_override("font_color", GOLD)
	match options_tab:
		"video": build_video_options(p)
		"audio":
			label(p, Rect2(30, 100, 600, 35), "VOLUME GERAL • MÚSICA E EFEITOS", 18)
			var volume := HSlider.new(); volume.position = Vector2(30, 145); volume.size = Vector2(760, 40); volume.min_value = 0; volume.max_value = 100; volume.value = app.volume_percent
			volume.value_changed.connect(func(value): app.set_volume(value)); p.add_child(volume)
		"controls": build_controls_options(p)
	button(p, Rect2(30, 585, 200, 48), "VOLTAR", func(): app.save_settings(); show_screen("main"))
	var encyclopedia_button := button(p, Rect2(550, 585, 240, 48), "ARQUIVO DO REFÚGIO", func(): app.save_settings(); open_encyclopedia("options"))
	encyclopedia_button.name = "EncyclopediaButton"

# 0.18: remapeamento do P1 (teclado/mouse). P2 local e joypad continuam fixos.
func build_controls_options(p: Control) -> void:
	awaiting_bind = ""; bind_buttons.clear()
	label(p, Rect2(30, 90, 760, 26), "MARTY / P1 — clique numa tecla e pressione a nova", 16, Color("9fc3bb"))
	var actions: Array = app.KEY_BIND_DEFAULTS.keys()
	var col_h := 38
	for i in actions.size():
		var action: String = actions[i]
		var col := i / 7; var row := i % 7
		var rect := Rect2(30 + col * 390, 125 + row * col_h, 370, 34)
		var b := button(p, rect, bind_caption(action), func(): start_rebind(action))
		b.add_theme_font_size_override("font_size", 15)
		bind_buttons[action] = b
	label(p, Rect2(30, 400, 760, 26), "Mouse: mirar e atirar (clique esquerdo) • direito também golpeia", 14, GOLD)
	if app.playstation_controller_connected():
		var ps_legend := label(p, Rect2(30, 428, 760, 26), "CONTROLE PLAYSTATION DETECTADO", 16, GOLD)
		ps_legend.name = "PlayStationControlsLegend"
		label(p, Rect2(30, 453, 760, 25), "Analógico esquerdo mover • direito mirar • R2 atirar", 14)
		label(p, Rect2(30, 478, 760, 25), "□ golpe • ✕ salto • ○ dash • △ interagir • L1 armadura • R1 arma", 14)
		label(p, Rect2(30, 503, 760, 25), "↑ invocar • ↓ fundir • ← trocar robô • → raio Ômega • OPTIONS pausa", 14)
	button(p, Rect2(30, 530 if app.playstation_controller_connected() else 440, 400, 44), "RESTAURAR PADRÃO", func(): reset_binds())

func bind_caption(action: String) -> String:
	var label_text: String = app.KEY_BIND_LABELS.get(action, action)
	if awaiting_bind == action: return label_text + " — pressione uma tecla..."
	return label_text + " — " + OS.get_keycode_string(app.key_binds[action])

func start_rebind(action: String) -> void:
	awaiting_bind = action
	get_viewport().gui_release_focus() # sem isso o botão focado engole Espaço/Enter
	for a in bind_buttons: bind_buttons[a].text = bind_caption(a)

func reset_binds() -> void:
	app.key_binds = app.KEY_BIND_DEFAULTS.duplicate(); app.save_settings()
	for a in bind_buttons: bind_buttons[a].text = bind_caption(a)

func option_row(p: Control, y: int, caption: String, items: Array, selected: int, on_pick: Callable) -> OptionButton:
	label(p, Rect2(30, y + 6, 330, 32), caption, 17, Color("c6dccd"))
	var ob := OptionButton.new(); ob.position = Vector2(370, y); ob.size = Vector2(420, 42)
	ob.add_theme_font_size_override("font_size", 17)
	for it in items: ob.add_item(it)
	ob.select(selected); ob.item_selected.connect(on_pick); p.add_child(ob); return ob

func build_video_options(p: Control) -> void:
	var d = app.display
	var res_list: Array = d.available_resolutions()
	var res_names: Array = []
	for r in res_list: res_names.append("%d × %d" % [r.x, r.y])
	var res_row := option_row(p, 90, "RESOLUÇÃO (janela)", res_names, maxi(0, res_list.find(d.resolution)), func(i): d.resolution = res_list[i]; apply_video())
	res_row.disabled = d.mode != 0
	option_row(p, 145, "MODO DE TELA", d.MODES, d.mode, func(i): d.mode = i; apply_video(); show_screen("options"))
	var fps_names: Array = []
	for f in d.FPS_LIMITS: fps_names.append("SEM LIMITE" if f == 0 else str(f) + " FPS")
	option_row(p, 200, "LIMITE DE FPS", fps_names, maxi(0, d.FPS_LIMITS.find(d.fps_limit)), func(i): d.fps_limit = d.FPS_LIMITS[i]; apply_video())
	var view_keys: Array = d.VIEWS.keys()
	var view_names: Array = []
	for k in view_keys: view_names.append(d.VIEW_NAMES[k])
	option_row(p, 255, "DISTÂNCIA DA CÂMERA", view_names, view_keys.find(d.view), func(i): d.view = view_keys[i]; app.save_settings())
	var ui_names: Array = []
	for u in d.UI_SCALES: ui_names.append("%d%%" % roundi(u * 100))
	option_row(p, 310, "TAMANHO DA INTERFACE", ui_names, maxi(0, d.UI_SCALES.find(d.ui_scale)), func(i): d.ui_scale = d.UI_SCALES[i]; apply_video())
	var vs := CheckButton.new(); vs.position = Vector2(30, 365); vs.size = Vector2(380, 44); vs.text = "VSYNC (sem tearing)"; vs.button_pressed = d.vsync
	vs.add_theme_font_size_override("font_size", 17); vs.toggled.connect(func(on): d.vsync = on; apply_video()); p.add_child(vs)
	var pp := CheckButton.new(); pp.position = Vector2(420, 365); pp.size = Vector2(380, 44); pp.text = "PIXEL PERFEITO (escala inteira)"; pp.button_pressed = d.pixel_perfect
	pp.add_theme_font_size_override("font_size", 17); pp.toggled.connect(func(on): d.pixel_perfect = on; apply_video()); p.add_child(pp)
	label(p, Rect2(30, 420, 760, 150), d.summary() + "\n\nTelas 16:9, 16:10, 21:9 e 4:3: a interface se ajusta às bordas e a sobra da tela mostra mais mapa.\nEm tela cheia o jogo usa a resolução do monitor. \"Longe\" mostra mais da sala; \"Pixel perfeito\" evita\nborrões em monitores com resolução múltipla de 1280×800 (pode deixar faixas pretas).", 14, Color("9fc3bb"))

func apply_video() -> void:
	app.display.apply(get_tree()); app.save_settings()
	await get_tree().process_frame
	if screen == "options": show_screen("options")

func read_equipment() -> void:
	gear_actor = 1 if app.online and not app.hosting else 0
	if app.playing:
		var a: Dictionary = app.sim.actors[gear_actor]
		robot_choice = a.selected_robot; outfit_choice = a.get("outfit", "padrao")
	else:
		robot_choice = app.pref_robot; outfit_choice = app.pref_outfit
	# 0.17: só itens desbloqueados ficam equipados
	if outfit_choice not in app.sim.OUTFITS or not app.sim.is_unlocked(outfit_choice): outfit_choice = "padrao"
	if not app.sim.is_unlocked(robot_choice): robot_choice = app.sim.default_robot()
	armor_choice = str(app.sim.actors[gear_actor].get("armor_type", "omega")) if app.playing else app.selected_armor()
	if not app.sim.is_unlocked(armor_choice): armor_choice = ""

# ── Tela de EQUIPAMENTO 0.17: módulo scripts/equipment_screen.gd (moldura + camadas, dados em data/equipamento.json)
var equipment: Control
var armor_choice := ""

func build_equipment(mission_mode: bool = false) -> void:
	equipment = EquipmentScreen.new(); equipment.host = self; equipment.app = app
	equipment.mission_mode = mission_mode
	content.add_child(equipment); equipment.build()

func select_actor(i: int) -> void:
	if gear_actor != i: swap_actor()

# compatível com a API antiga: "o_mecanico", "armor_omega", "titan"…
func choose(key: String) -> void:
	var id := key.trim_prefix("o_").trim_prefix("armor_")
	if equipment != null: equipment.pick(id)

# Controle: LB/RB (e as setas da vitrine) passam pelos itens; A equipa; B volta.
func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if awaiting_bind != "" and event is InputEventKey and event.pressed:
		var action := awaiting_bind; awaiting_bind = ""
		if event.physical_keycode != KEY_ESCAPE:
			if not app.rebind_key(action, event.physical_keycode):
				bind_buttons[action].text = bind_caption(action) + " (em uso!)"
				accept_event(); return
		for a in bind_buttons: bind_buttons[a].text = bind_caption(a)
		accept_event(); return
	if event is InputEventJoypadButton and event.pressed:
		if screen in ["equipment", "mission_inventory"] and event.button_index == JOY_BUTTON_LEFT_SHOULDER: cycle_outfit(-1); accept_event()
		elif screen in ["equipment", "mission_inventory"] and event.button_index == JOY_BUTTON_RIGHT_SHOULDER: cycle_outfit(1); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen == "pause": close(); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen == "equipment": show_screen("play"); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen == "mission_inventory": show_screen("pause"); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen == "encyclopedia": show_screen(encyclopedia_return_screen); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen == "play": show_screen("characters"); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen == "characters_coop": show_screen("play"); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen == "summary": app.summary_return_refuge(); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen != "main": show_screen("main"); accept_event()
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_accept")):
		focus_first(); accept_event()

func focus_first() -> void:
	# primeiro botão visível da tela recebe o foco (para jogar só com o controle)
	if screen == "main" and app.playing and main_resume != null and main_resume.visible and not main_resume.disabled:
		main_resume.grab_focus(); return
	if screen == "play":
		var selected_name := "AIChoice" if pending_mode == "ai" else ("LocalChoice" if pending_mode == "local" else "SoloChoice")
		var selected_choice := content.find_child(selected_name, true, false) as Button
		if selected_choice != null: selected_choice.grab_focus(); return
	if screen == "characters_coop":
		var confirm := content.find_child("ConfirmCharacters", true, false) as Button
		if confirm != null: confirm.grab_focus(); return
	var stack: Array = [content]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is Button and n.visible and not n.disabled and n.focus_mode != Control.FOCUS_NONE: n.grab_focus(); return
		stack.append_array(n.get_children())

func cycle_outfit(step: int) -> void:
	if equipment != null: equipment.cycle(step)

func apply_gear() -> bool:
	if app.playing:
		var accepted: bool = app.request_loadout(gear_actor, outfit_choice, robot_choice, armor_choice if armor_choice != "" else "omega")
		if live_status != null: live_status.text = "Solicitado ao anfitrião." if app.online and not app.hosting else ("Aplicado à missão." if accepted else app.sim.message)
		return accepted
	app.pref_outfit = outfit_choice; app.pref_robot = robot_choice; app.save_settings()
	if live_status != null: live_status.text = "Salvo para a próxima partida."
	return true

func launch() -> void:
	if app.playing: return
	app.pref_outfit = outfit_choice; app.pref_robot = robot_choice; app.save_settings()
	if pending_mode == "local": app.start_local()
	elif pending_mode == "solo": app.start_single()
	else: app.start_solo()
	app.apply_preferences(0)

func swap_actor() -> void:
	gear_actor = 1 - gear_actor
	var a: Dictionary = app.sim.actors[gear_actor]
	outfit_choice = a.outfit; robot_choice = a.selected_robot; armor_choice = a.get("armor_type", "omega")
	if equipment != null: equipment.refresh()

func launch_refuge() -> void:
	if app.online:
		live_status.text = "Refúgio pelo portal da expedição."; return
	launch()
	app.sim.make_hub(); app.apply_preferences(0); close()

func _process(_dt: float) -> void:
	pass
