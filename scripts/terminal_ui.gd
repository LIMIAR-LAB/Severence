class_name TemporalTerminal
extends Control
const DisplaySettingsScript = preload("res://scripts/display_settings.gd")
const MenuBackground = preload("res://scripts/menu_background.gd")
const EquipmentScreen = preload("res://scripts/equipment_screen.gd")
const CharacterSilhouette = preload("res://scripts/character_silhouette.gd")
const EncyclopediaScreen = preload("res://scripts/encyclopedia_screen.gd")
const MARTY_PORTRAIT := "res://assets/ui/equipamento/cards/card_marty_padrao.png"
const PAUSE_FRAME := "res://assets/ui/pause/pause_frame_pixellab.png"

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
	var fit := minf(vp.x/1280.0,vp.y/800.0)
	stage.scale = Vector2(1280.0/1344,800.0/752)*fit
	stage.position = ((vp - Vector2(1280, 800)*fit) * 0.5).floor()
	if screen == "main" and content != null:
		var title_scene := content.find_child("TitleSceneCrop", false, false) as Control
		if title_scene != null: fit_title_background(title_scene)
	place_equipment()

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

# 0.17: equipamento centralizado com escala proporcional contínua para ocupar a janela.
func place_equipment() -> void:
	if content == null or screen not in ["equipment", "mission_inventory"] or content.get_parent() != self: return
	var k := get_viewport().get_final_transform().get_scale().x   # lógico -> pixels da janela
	if k <= 0: k = 1.0
	var phys := get_viewport_rect().size * k
	var fit := minf(phys.x / 1344.0, phys.y / 752.0)
	var s := fit # 0.17: ocupa a janela também entre escalas inteiras
	content.scale = Vector2.ONE * (s / k)
	content.position = ((phys - Vector2(1344, 752) * s) * 0.5).floor() / k

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
	backdrop.color = Color(0.015, 0.025, 0.04, 0.82) if next == "pause" else Color("05080d")
	if content != null:
		content.get_parent().remove_child(content); content.queue_free()
	content = Control.new(); content.size = Vector2(1344, 752)
	if next in ["equipment", "mission_inventory"]: add_child(content); place_equipment()   # escala inteira, fora do stage
	else: stage.add_child(content)
	rows.clear(); slot_buttons.clear(); preview = null; detail = null; live_status = null; main_resume = null; telemetry = null; equipment = null; encyclopedia = null
	if next in ["equipment", "mission_inventory"]: build_equipment(next == "mission_inventory"); return
	if next != "pause":
		if next == "main":
			var title_scene := title_background(); content.add_child(title_scene); fit_title_background(title_scene)
		else:
			var bg := TextureRect.new(); bg.texture = load("res://assets/ui/" + ("online" if next == "online" else "menu") + ".png")
			if next == "play": bg.texture = load("res://assets/ui/adventure.png")
			bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.size = Vector2(1344, 752); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(bg)
	match next:
		"main": build_main()
		"characters": build_characters()
		"online": build_online()
		"play": build_play()
		"pause": build_pause()
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
		var crop_scale := root.size.x / TITLE_SCENE_CROP.size.x
		title_video.position = -TITLE_SCENE_CROP.position * crop_scale
		title_video.size = Vector2(1344, 752) * crop_scale
		title_video.mouse_filter = Control.MOUSE_FILTER_IGNORE; title_video.autoplay = true
		if "loop" in title_video: title_video.set("loop", true)
		title_video.finished.connect(title_video.play)   # garante o loop em qualquer versão
		root.add_child(title_video)
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

func continue_title() -> void:
	if app.playing: close()
	elif app.has_saved_game(): app.load_game()

func build_main() -> void:
	var lockup := Control.new(); lockup.name = "TitleLockup"; lockup.position = Vector2(45, 34); lockup.size = Vector2(455, 185); lockup.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(lockup)
	var title_top := label(lockup, Rect2(0, 0, 455, 67), "FRATURAS", 50, Color("e1a84f"))
	var title_bottom := label(lockup, Rect2(0, 55, 455, 72), "DO TEMPO", 55, Color("e9ecea"))
	for title_line in [title_top, title_bottom]:
		title_line.add_theme_color_override("font_outline_color", Color("10171a")); title_line.add_theme_constant_override("outline_size", 9)
	var bolt := ColorRect.new(); bolt.position = Vector2(326, 7); bolt.size = Vector2(7, 119); bolt.rotation = 0.08; bolt.color = Color("57f1f5"); bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE; lockup.add_child(bolt)
	var era := label(lockup, Rect2(7, 137, 305, 26), "DOCAS DE 1941", 14, Color("f0d48b")); era.add_theme_color_override("font_outline_color", Color("10171a")); era.add_theme_constant_override("outline_size", 5)

	var deck := panel(content, Rect2(28, 565, 1288, 165), Color("111813e8"), Color("b28b43")); deck.name = "TitleCommandDeck"
	deck.add_theme_stylebox_override("panel", title_style(Color("111813e8"), Color("b28b43"), 4, 9))
	var callbacks: Dictionary = {
		"new": func(): show_screen("characters"), "online": func(): show_screen("online"),
		"options": func(): show_screen("options"),
		"exit": func(): app.save_progress(); app.get_tree().quit(),
	}
	var has_continue: bool = app.playing or app.has_saved_game()
	var new_run := title_button(deck, 1, Rect2(20, 16, 430, 62), "▶  NOVA EXPEDIÇÃO", callbacks.new, not app.playing)
	main_resume = title_button(deck, 0, Rect2(464, 16, 330, 62), "CONTINUAR", continue_title, app.playing)
	main_resume.disabled = not has_continue
	if app.playing: main_resume.tooltip_text = "Voltar para a expedição em andamento"
	elif app.has_saved_game(): main_resume.tooltip_text = "Carregar a última expedição salva"
	else: main_resume.tooltip_text = "Nenhuma expedição para continuar"
	var status_panel := panel(deck, Rect2(808, 16, 460, 62), Color("0d1310"), Color("34443b")); status_panel.name = "TitleStatusPanel"
	var status_color := Color("79e5e5") if app.network_status != "OFFLINE" else Color("b9a66c")
	var status := label(status_panel, Rect2(18, 11, 424, 24), "●  " + app.network_status, 14, status_color); status.name = "TitleNetworkStatus"
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label(status_panel, Rect2(18, 35, 424, 17), "COOP LOCAL APÓS ESCOLHER PERSONAGEM", 10, Color("69796e"))
	var online_button := title_button(deck, 2, Rect2(20, 91, 240, 50), "ONLINE", callbacks.online)
	var options_button := title_button(deck, 5, Rect2(274, 91, 240, 50), "OPÇÕES", callbacks.options)
	var exit_button := title_button(deck, 6, Rect2(528, 91, 240, 50), "SAIR", callbacks.exit)
	label(deck, Rect2(808, 99, 445, 28), "FRATURAS DO TEMPO  •  PROTÓTIPO", 12, Color("78867c")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	var p := panel(content, Rect2(95, 45, 1154, 660), Color("101f2a"), Color("75b5a2"))
	label(p, Rect2(36, 20, 1080, 48), "ESCOLHA SEU PERSONAGEM", 30, GOLD)
	label(p, Rect2(38, 69, 1050, 30), "Marty está pronto. Outros viajantes poderão ser liberados depois.", 17, Color("b3c8c5"))
	for i in 6:
		var col := i % 3; var row := i / 3
		var rect := Rect2(42 + col * 358, 116 + row * 225, 328, 205)
		var card := panel(p, rect, Color("15343b") if i == 0 else Color("131a21"), CYAN if i == 0 else Color("35434b"))
		if i == 0:
			var crop := AtlasTexture.new(); crop.atlas = load(MARTY_PORTRAIT); crop.region = Rect2(65, 48, 225, 260)
			var portrait := Sprite2D.new(); portrait.texture = crop; portrait.position = Vector2(83, 90.5)
			portrait.scale = Vector2(130.0 / 225.0, 157.0 / 260.0); portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			card.add_child(portrait)
			label(card, Rect2(158, 49, 155, 45), "MARTY", 27, GOLD)
			label(card, Rect2(158, 97, 155, 55), "DISPONÍVEL", 16, CYAN)
			var pick := button(p, rect, "", func(): show_screen("play"), true); pick.name = "CharacterMarty"
		else:
			var shadow := CharacterSilhouette.new(); shadow.variant = i - 1
			shadow.position = Vector2(18, 11); shadow.size = Vector2(125, 160); shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shadow.name = "Silhouette%d" % i; card.add_child(shadow)
			label(card, Rect2(150, 55, 165, 90), "VIAJANTE %d\nBLOQUEADO" % (i + 1), 18, Color("687983"))
			var locked := button(p, rect, "", func(): pass, true); locked.name = "CharacterLocked%d" % i; locked.disabled = true
	label(p, Rect2(40, 575, 470, 30), "1 de 6 personagens disponíveis", 17, CYAN)
	button(p, Rect2(835, 566, 270, 58), "VOLTAR", func(): show_screen("main"))

func build_play() -> void:
	if pending_mode not in ["solo", "ai", "local"]: pending_mode = "solo"
	var choices := Control.new(); choices.size = Vector2(1344, 752); choices.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(choices)
	for i in range(2):
		var mode_name: String = "solo" if i == 0 else "ai"
		var b := button(choices, Rect2(391 + i * 298, 171, 272, 329), "", func(): pending_mode = mode_name; read_equipment(); show_screen("equipment"), true)
		b.name = "SoloChoice" if i == 0 else "AIChoice"
		b.tooltip_text = "Apenas Marty" if i == 0 else "Marty com parceiro IA"
		if pending_mode == mode_name:
			var selected := b.get_theme_stylebox("normal").duplicate(); selected.border_color = CYAN; selected.set_border_width_all(4); b.add_theme_stylebox_override("normal", selected)
	var local := button(content, Rect2(391, 517, 570, 68), "COOP LOCAL  •  2 JOGADORES", func(): pending_mode = "local"; read_equipment(); show_screen("equipment"))
	local.name = "LocalChoice"; local.tooltip_text = "Dois jogadores no mesmo computador"
	button(content, Rect2(388, 611, 205, 55), "", func(): show_screen("characters"), true).tooltip_text = "Voltar"
	if pending_mode != "local":
		panel(content, Rect2(685, 424, 252, 31) if pending_mode == "ai" else Rect2(400,424,250,31), Color("273929"), CYAN)
		label(content, Rect2(720, 426, 220, 29) if pending_mode == "ai" else Rect2(455,426,180,29), "SOLO + IA  ✓" if pending_mode == "ai" else "SOLO  ✓", 23, GOLD)

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
	label(p, Rect2(110, 89, 680, 48), "PAUSA", 31, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(p, Rect2(110, 139, 680, 36), "Expedição em andamento", 20, Color("c6dccd")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var resume := button(p, Rect2(160, 174, 580, 52), "CONTINUAR", close)
	resume.name = "ResumeGame"
	var save := button(p, Rect2(160, 236, 580, 52), "SALVAR JOGO", func():
		if app.save_game(): telemetry.text = "Expedição salva."
		else: telemetry.text = "Não foi possível salvar esta partida.")
	save.name = "SaveGame"; save.disabled = app.online
	var leave := button(p, Rect2(160, 298, 580, 52), "VOLTAR AO MENU", func():
		if not app.return_to_title():
			telemetry.text = "Não foi possível salvar. A partida continua em pausa."
			telemetry.add_theme_color_override("font_color", Color("ffad99")))
	leave.name = "ReturnToMenu"
	var encyclopedia_button := button(p, Rect2(160, 360, 580, 48), "ARQUIVO DO REFÚGIO", func(): open_encyclopedia("pause"))
	encyclopedia_button.name = "PauseEncyclopedia"
	var mission_inventory := button(p, Rect2(160, 416, 580, 48), "INVENTÁRIO DA MISSÃO", func(): read_equipment(); show_screen("mission_inventory"))
	mission_inventory.name = "MissionInventory"
	resume.focus_neighbor_bottom = resume.get_path_to(save); resume.focus_next = resume.get_path_to(save)
	save.focus_neighbor_top = save.get_path_to(resume); save.focus_neighbor_bottom = save.get_path_to(leave)
	save.focus_previous = save.get_path_to(resume); save.focus_next = save.get_path_to(leave)
	leave.focus_neighbor_top = leave.get_path_to(save); leave.focus_previous = leave.get_path_to(save)
	leave.focus_neighbor_bottom = leave.get_path_to(encyclopedia_button); leave.focus_next = leave.get_path_to(encyclopedia_button)
	encyclopedia_button.focus_neighbor_top = encyclopedia_button.get_path_to(leave); encyclopedia_button.focus_neighbor_bottom = encyclopedia_button.get_path_to(mission_inventory)
	encyclopedia_button.focus_previous = encyclopedia_button.get_path_to(leave); encyclopedia_button.focus_next = encyclopedia_button.get_path_to(mission_inventory)
	mission_inventory.focus_neighbor_top = mission_inventory.get_path_to(encyclopedia_button); mission_inventory.focus_previous = mission_inventory.get_path_to(encyclopedia_button)
	telemetry = label(p, Rect2(105, 476, 690, 34), "Esc ou Start também continua a partida.", 15, GOLD)
	telemetry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
	encyclopedia_return_screen = return_screen if return_screen in ["main", "pause"] else "main"
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
			label(p, Rect2(30, 100, 600, 35), "VOLUME DOS EFEITOS", 18)
			var volume := HSlider.new(); volume.position = Vector2(30, 145); volume.size = Vector2(760, 40); volume.min_value = 0; volume.max_value = 100; volume.value = app.volume_percent
			volume.value_changed.connect(func(value): app.set_volume(value)); p.add_child(volume)
		"controls": build_controls_options(p)
	button(p, Rect2(30, 585, 200, 48), "VOLTAR", func(): app.save_settings(); show_screen("main"))

# 0.18: remapeamento do P1 (teclado/mouse). P2 local e joypad continuam fixos.
func build_controls_options(p: Control) -> void:
	awaiting_bind = ""; bind_buttons.clear()
	label(p, Rect2(30, 90, 760, 26), "MARTY / P1 — clique numa tecla e pressione a nova", 16, Color("9fc3bb"))
	var actions: Array = app.KEY_BIND_DEFAULTS.keys()
	var col_h := 44
	for i in actions.size():
		var action: String = actions[i]
		var col := i / 6; var row := i % 6
		var rect := Rect2(30 + col * 390, 125 + row * col_h, 370, 38)
		var b := button(p, rect, bind_caption(action), func(): start_rebind(action))
		b.add_theme_font_size_override("font_size", 15)
		bind_buttons[action] = b
	label(p, Rect2(30, 400, 760, 26), "Mouse: mirar e atirar (clique esquerdo) • direito também golpeia", 14, GOLD)
	button(p, Rect2(30, 440, 400, 44), "RESTAURAR PADRÃO", func(): reset_binds())

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
	armor_choice = "omega" if app.sim.is_unlocked("omega") else ""

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
		elif event.button_index == JOY_BUTTON_B and screen != "main": show_screen("main"); accept_event()
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_accept")):
		focus_first(); accept_event()

func focus_first() -> void:
	# primeiro botão visível da tela recebe o foco (para jogar só com o controle)
	if screen == "main" and app.playing and main_resume != null and main_resume.visible and not main_resume.disabled:
		main_resume.grab_focus(); return
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
	outfit_choice = a.outfit; robot_choice = a.selected_robot
	if equipment != null: equipment.refresh()

func launch_refuge() -> void:
	if app.online:
		live_status.text = "Refúgio pelo portal da expedição."; return
	launch()
	app.sim.make_hub(); app.apply_preferences(0); close()

func _process(_dt: float) -> void:
	pass
