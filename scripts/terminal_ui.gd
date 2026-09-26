class_name TemporalTerminal
extends Control
const DisplaySettingsScript = preload("res://scripts/display_settings.gd")

# Supplied concept screens form the decorative layer. Every active region is a
# real Control; editable text, selections, previews and statuses are live.
const CYAN := Color("65f0f5")
const GOLD := Color("f3dda0")
var app: Node
var stage: Control
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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Fundo que cobre a sobra de telas 16:9 / 21:9 / 4:3; o menu (arte 1280×800) fica centralizado.
	var backdrop := ColorRect.new(); backdrop.color = Color("05080d"); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(backdrop)
	stage = Control.new(); stage.size = Vector2(1344, 752); stage.scale = Vector2(1280.0 / 1344, 800.0 / 752); add_child(stage)
	get_viewport().size_changed.connect(center_stage); center_stage()
	show_screen("main")

func center_stage() -> void:
	if stage == null: return
	var vp := get_viewport_rect().size
	stage.position = ((vp - Vector2(1280, 800)) * 0.5).floor()

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
	if content != null:
		stage.remove_child(content); content.queue_free()
	content = Control.new(); content.size = Vector2(1344, 752); stage.add_child(content)
	rows.clear(); slot_buttons.clear(); preview = null; detail = null; live_status = null; main_resume = null; telemetry = null
	var bg := TextureRect.new(); bg.texture = load("res://assets/ui/" + ("online" if next == "online" else "equipment" if next == "equipment" else "menu") + ".png")
	if next == "play": bg.texture = load("res://assets/ui/adventure.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.size = Vector2(1344, 752); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(bg)
	match next:
		"main": build_main()
		"online": build_online()
		"equipment": build_equipment()
		"play": build_play()
		"seed": build_seed()
		"options": build_options()

func open(page: String = "main") -> void:
	show(); app.paused = app.playing and not app.online
	if page == "equipment": read_equipment()
	show_screen(page)

func close() -> void:
	if not app.playing: show_screen("main"); return
	hide(); app.paused = false
	# A UI click must not become a weapon shot in the same frame.
	app.ui_input_block = 0.2

func build_main() -> void:
	panel(content, Rect2(41, 207, 348, 23), Color("16291c"), Color("16291c"))
	label(content, Rect2(64, 207, 330, 23), "PROTÓTIPO 0.4  •  DOCAS DE 1941", 15, Color("b7d2b7"))
	panel(content, Rect2(123, 277, 255, 24), Color("153a35"), Color("153a35"))
	label(content, Rect2(134, 276, 260, 26), "Solo, parceiro IA ou coop", 17, Color("bde3cf"))
	var ys := [242, 314, 382, 450, 519, 589]
	var callbacks: Array[Callable] = [func(): show_screen("play"), func(): pending_mode = "local"; start_target = "arena"; read_equipment(); show_screen("equipment"), func(): show_screen("online"), func(): show_screen("seed"), func(): show_screen("options"), func(): app.save_progress(); app.get_tree().quit()]
	for i in range(6):
		var b := button(content, Rect2(42, ys[i], 346, 64), "", callbacks[i], true)
		b.tooltip_text = ["Escolher single player ou parceiro IA", "Dois jogadores no mesmo computador", "Hospedar ou entrar por IP", "Escolher uma seed para as docas", "Resolução, modo de tela, FPS, câmera, áudio e controles", "Sair do jogo"][i]
	panel(content, Rect2(55, 668, 333, 37), Color("18291c"), Color("18291c"))
	label(content, Rect2(62, 673, 320, 30), app.network_status, 17, Color("bad9bf"))
	main_resume = button(content, Rect2(938, 676, 350, 50), "CONTINUAR  [ESC]", close)
	main_resume.visible = app.playing
	button(content, Rect2(938, 614, 350, 50), "EQUIPAMENTO  [B]", func(): pending_mode = "current"; open("equipment"))

func overlay(title: String) -> Panel:
	var dim := ColorRect.new(); dim.color = Color(0.015, 0.025, 0.04, 0.78); dim.size = Vector2(1344, 752); content.add_child(dim)
	var p := panel(content, Rect2(400, 125, 700, 520), Color("102922"), Color("75b5a2"))
	label(p, Rect2(30, 20, 640, 55), title, 30, GOLD)
	return p

func build_play() -> void:
	if pending_mode not in ["solo", "ai"]: pending_mode = "solo"
	var choices := Control.new(); choices.size = Vector2(1344, 752); choices.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(choices)
	for i in range(2):
		var mode_name: String = "solo" if i == 0 else "ai"
		var b := button(choices, Rect2(391 + i * 298, 171, 272, 329), "", func(): pending_mode = mode_name; read_equipment(); show_screen("equipment"), true)
		b.name = "SoloChoice" if i == 0 else "AIChoice"
		b.tooltip_text = "Apenas Marty" if i == 0 else "Marty com parceiro IA"
		if pending_mode == mode_name:
			var selected := b.get_theme_stylebox("normal").duplicate(); selected.border_color = CYAN; selected.set_border_width_all(4); b.add_theme_stylebox_override("normal", selected)
	button(content, Rect2(388, 611, 205, 55), "", func(): show_screen("main"), true).tooltip_text = "Voltar"
	panel(content, Rect2(685, 424, 252, 31) if pending_mode == "ai" else Rect2(400,424,250,31), Color("273929"), CYAN)
	label(content, Rect2(720, 426, 220, 29) if pending_mode == "ai" else Rect2(455,426,180,29), "SOLO + IA  ✓" if pending_mode == "ai" else "SOLO  ✓", 23, GOLD)

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
		"controls":
			label(p, Rect2(30, 100, 760, 400), "WASD mover • Mouse mirar/atirar • F / botão direito golpe\nEspaço salto (também na diagonal) • Shift dash (no Titan: turbo)\nR vestir armadura • E interagir / pilotar Titan\nC invocar/recolher robô • G fundir Spectre\nTAB ou M mapa • B equipamento • Esc menu\n\nControle: analógicos mover/mirar • RT tiro • X golpe\nA salto • B dash • Y interagir • LB armadura", 18, Color("c6dccd"))
			button(p, Rect2(30, 470, 400, 50), "UNIFORME / ARMADURA / ROBÔ", func(): pending_mode = "current"; read_equipment(); show_screen("equipment"))
	button(p, Rect2(30, 585, 200, 48), "VOLTAR", func(): app.save_settings(); show_screen("main"))

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
	if outfit_choice not in app.sim.OUTFITS: outfit_choice = "padrao"
	preview_kind = "o_" + outfit_choice; info_kind = ""

var info_title: Label
var info_body: Label
var armor_body: Label
var companion_body: Label
var weapon_icon: TextureRect
var weapon_label: Label

# Tela de equipamento: UNIFORME (skin + arma), ARMADURA levada (ativada com R) e ROBÔ.
# Cada clique já aplica a escolha — não há botão de aplicar.
func build_equipment() -> void:
	panel(content, Rect2(166, 20, 222, 42), Color("0b1a22"), Color("0b1a22"))
	label(content, Rect2(172, 22, 206, 38), "UNIFORME", 22, GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel(content, Rect2(147, 65, 287, 455), Color("0b2430"), Color("365566"))
	var slots := [["o_padrao", "PADRÃO", "equilibrado", 0], ["o_mecanico", "MECÂNICO", "+ força", 2], ["o_espiao", "ESPIÃO", "+ velocidade", 1]]
	for i in range(3):
		var data: Array = slots[i]
		var key: String = data[0]
		var b := button(content, Rect2(155, 75 + i * 98, 270, 90), "", func(): choose(key))
		b.name = "Slot_" + key; slot_buttons[key] = b
		label(b, Rect2(95, 14, 175, 30), data[1], 17, GOLD)
		label(b, Rect2(95, 44, 175, 30), data[2], 14, Color("b6dfdc"))
		add_icon(b, atlas("res://assets/marty/outfits.png", Rect2(0, data[3] * 96, 96, 96)))
	# Armaduras: escolha UMA para levar (ativada com R). Outras virão depois.
	label(content, Rect2(160, 370, 270, 26), "ARMADURA — escolha 1 (R)", 14, CYAN)
	for i in range(3):
		var key := "armor_omega" if i == 0 else "armor_locked" + str(i)
		var ab := button(content, Rect2(155 + i * 92, 398, 86, 112), "", func(): choose(key))
		ab.name = "Slot_" + key; slot_buttons[key] = ab
		if i == 0:
			var icon := TextureRect.new(); icon.texture = atlas("res://assets/marty/outfits.png", Rect2(0, 288, 96, 96))
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.position = Vector2(4, 2); icon.size = Vector2(78, 80); icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; ab.add_child(icon)
			label(ab, Rect2(4, 84, 78, 24), "ÔMEGA", 14, CYAN).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			ab.disabled = true
			label(ab, Rect2(4, 30, 78, 40), "?", 30, Color("48606a")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label(ab, Rect2(4, 84, 78, 24), "BLOQUEADA", 11, Color("48606a")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel(content, Rect2(474, 35, 377, 313), Color("07303e"), CYAN)
	preview = TextureRect.new(); preview.position = Vector2(525, 66); preview.size = Vector2(270, 265); preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; preview.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(preview)
	panel(content, Rect2(480, 365, 364, 93), Color("0b242c"), Color("477f82"))
	current_choice = label(content, Rect2(493, 371, 340, 80), "", 15, GOLD)
	# Three permanent information regions; selection only changes the preview.
	panel(content, Rect2(895, 20, 310, 505), Color("081e29"), Color("497381"))
	info_title = label(content, Rect2(910, 30, 280, 27), "", 18, GOLD)
	info_body = label(content, Rect2(910, 62, 280, 125), "", 14, Color("b6dfdc"))
	info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(content, Rect2(910, 198, 280, 27), "ARMADURA TEMPORÁRIA", 18, CYAN)
	armor_body = label(content, Rect2(910, 230, 280, 145), "", 14, Color("b6dfdc"))
	armor_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(content, Rect2(910, 383, 280, 27), "COMPANHEIRO", 18, CYAN)
	companion_body = label(content, Rect2(910, 413, 280, 104), "", 14, Color("b6dfdc"))
	companion_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in range(3):
		var key: String = ["titan", "spectre", "locked_robot"][i]
		var b := button(content, Rect2(344 + i * 237, 574, 201, 140), "", func(): choose(key), true)
		b.disabled = i == 2; slot_buttons["robot" + str(i)] = b
		if i == 1:
			panel(b, Rect2(3, 3, 195, 114), Color("082331"), Color("082331"))
			var icon := TextureRect.new(); icon.texture = atlas("res://assets/mech/spectre-feral.png", Rect2(0, 0, 128, 128))
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.position = Vector2(40, 0); icon.size = Vector2(120, 112); icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; b.add_child(icon)
		panel(content, Rect2(347 + i * 237, 692, 193, 22), Color("082331"), Color("082331"))
		label(content, Rect2(353 + i * 237, 692, 185, 22), ["TITAN • PILOTAR", "SPECTRE • FUNDIR", "BLOQUEADO"][i], 15)
	button(content, Rect2(22, 622, 224, 45), "VOLTAR", func(): show_screen("main"))
	button(content, Rect2(22, 681, 224, 45), "CONTINUAR" if app.playing and pending_mode == "current" else "INICIAR ARENA", launch)
	detail = label(content, Rect2(24, 540, 240, 80), "R vestir armadura\nC invocar/recolher robô\nE pilotar Titan • G fundir Spectre", 14, GOLD)
	live_status = label(content, Rect2(1000, 560, 270, 60), "", 14, CYAN)
	telemetry = label(content, Rect2(1000, 620, 270, 40), "", 12, GOLD)
	button(content, Rect2(480, 479, 365, 42), "IR AO REFÚGIO", launch_refuge)
	if app.playing and app.sim.coop == "local":
		button(content, Rect2(1000, 680, 270, 36), "EDITAR OUTRO JOGADOR", swap_actor).add_theme_font_size_override("font_size", 14)
	refresh_gear()

func add_icon(parent: Control, tex: Texture2D) -> void:
	var icon := TextureRect.new(); icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.position = Vector2(12, 4); icon.size = Vector2(80, 82); icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(icon)

func atlas(path: String, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new(); texture.atlas = load(path); texture.region = region; return texture

var info_kind := ""
var armor_choice := "omega"

func choose(key: String) -> void:
	info_kind = key
	if key.begins_with("o_"): outfit_choice = key.trim_prefix("o_"); preview_kind = key
	elif key in ["titan", "spectre"]: robot_choice = key; preview_kind = key
	elif key == "armor_omega": armor_choice = "omega"; preview_kind = key
	if not apply_gear() and app.playing and not app.online:
		outfit_choice = app.sim.actors[gear_actor].outfit; preview_kind = "o_" + outfit_choice
	refresh_gear()

const ROBOT_INFO := {
	"titan": ["TITAN", "Robô de combate pilotável e pesado.\nC invoca perto de você; E entra e sai.\nShift segurado: TURBO dos propulsores\n(barra amarela sob o Titan).\nCanhão pesado e golpe de 55.\nMantém os danos ao desembarcar."],
	"spectre": ["SPECTRE", "Predador simbionte de apoio.\nC invoca: ele acompanha e atira.\nG funde com Marty: +velocidade e dano,\na energia do Spectre absorve os golpes."]}

func refresh_gear() -> void:
	if preview == null: return
	var sim = app.sim
	var uni: Dictionary = sim.UNIFORMS[outfit_choice]
	var armor: Dictionary = sim.ARMORS.omega
	var rows_by_key := {"o_padrao": 0, "o_espiao": 1, "o_mecanico": 2, "armor_omega": 3}
	if preview_kind == "titan": preview.texture = atlas("res://assets/mech/titan_v2.png", Rect2(880, 0, 176, 176))
	elif preview_kind == "spectre": preview.texture = atlas("res://assets/mech/spectre-feral.png", Rect2(0, 0, 128, 128))
	else: preview.texture = atlas("res://assets/marty/outfits.png", Rect2(0, 96 * rows_by_key.get(preview_kind, 0), 96, 96))
	info_title.text = "UNIFORME " + uni.name
	info_body.text = uni.desc + "\nArma: " + uni.weapon_name
	armor_body.text = "ÔMEGA • R • 5s / recarga 60s\nLâmina: 38/38/64, final com onda.\nVelocidade 430 • resistência 60%.\nTiros: mínimo de 1 coração após resistência. Baús recarregam."
	companion_body.text = ("TITAN • C invoca, E pilota.\nCanhão, bomba e turbo (Shift).\nIntegridade absorve impactos." if robot_choice == "titan" else "SPECTRE FERAL • C invoca.\nPredador de apoio; G funde/separa.\nFusão: +velocidade/dano. Energia absorve impactos; incompatível com Ômega.")
	current_choice.text = "%s • UNIFORME %s\nARMA: %s\nARMADURA: ÔMEGA (R)  •  ROBÔ: %s" % ["ECHO" if gear_actor == 1 else "MARTY", uni.name, uni.weapon_name, robot_choice.to_upper()]
	for key in slot_buttons:
		var selected: bool = key == "o_" + outfit_choice or key == "armor_" + armor_choice or (key == "robot0" and robot_choice == "titan") or (key == "robot1" and robot_choice == "spectre")
		var b: Button = slot_buttons[key]
		var style: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate()
		style.border_color = CYAN if selected else Color("365566"); style.border_width_left = 3 if selected else 1; style.border_width_right = style.border_width_left; style.border_width_top = style.border_width_left; style.border_width_bottom = style.border_width_left
		b.add_theme_stylebox_override("normal", style)

func apply_gear() -> bool:
	app.pref_outfit = outfit_choice; app.pref_robot = robot_choice; app.save_settings()
	if app.playing:
		var accepted: bool = app.request_loadout(gear_actor, outfit_choice, robot_choice, armor_choice)
		if live_status != null: live_status.text = "Solicitado ao anfitrião." if app.online and not app.hosting else ("Aplicado." if accepted else app.sim.message)
		return accepted
	if live_status != null: live_status.text = "Salvo para a próxima partida."
	return true

func launch() -> void:
	if app.playing and pending_mode == "current":
		apply_gear(); close(); return
	app.pref_outfit = outfit_choice; app.pref_robot = robot_choice; app.save_settings()
	if pending_mode == "local": app.start_local()
	elif pending_mode == "solo": app.start_single()
	else: app.start_solo()
	app.apply_preferences(0)

func swap_actor() -> void:
	gear_actor = 1 - gear_actor
	var a: Dictionary = app.sim.actors[gear_actor]
	outfit_choice = a.outfit; robot_choice = a.selected_robot; refresh_gear()

func launch_refuge() -> void:
	if app.online:
		live_status.text = "Refúgio pelo portal da expedição."; return
	launch()
	app.sim.make_hub(); app.apply_preferences(0); close()

func _process(_dt: float) -> void:
	if not visible: return
	if telemetry != null and app.playing:
		var a: Dictionary = app.sim.actors[gear_actor]
		var s: Dictionary = app.sim.spectres[gear_actor]
		telemetry.text = "T: %d HP • S: %d HP • %.1fs" % [app.sim.mech.hp, s.hp, a.summon_cd]
