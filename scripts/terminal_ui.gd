class_name TemporalTerminal
extends Control
const DisplaySettingsScript = preload("res://scripts/display_settings.gd")
const MenuBackground = preload("res://scripts/menu_background.gd")

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
	var bg := TextureRect.new(); bg.texture = load("res://assets/ui/" + ("online" if next == "online" else "equipment_v3" if next == "equipment" else "menu") + ".png")
	if next == "play": bg.texture = load("res://assets/ui/adventure.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.size = Vector2(1344, 752); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bg.texture.resource_path.ends_with("menu.png"):
		bg.free(); content.add_child(title_background())   # tela inicial: vídeo em loop (0.16)
	else: content.add_child(bg)
	match next:
		"main": build_main()
		"online": build_online()
		"equipment": build_equipment()
		"play": build_play()
		"seed": build_seed()
		"options": build_options()
	if next != "equipment": focus_first.call_deferred()   # navegação pelo controle

func open(page: String = "main") -> void:
	show(); app.paused = app.playing and not app.online
	if page == "equipment": read_equipment()
	show_screen(page)

func close() -> void:
	if not app.playing: show_screen("main"); return
	hide(); app.paused = false
	# A UI click must not become a weapon shot in the same frame.
	app.ui_input_block = 0.2

# ── Tela inicial 0.16: vídeo em loop (assets/ui/title, tools/make_title_screen.py) com o menu desenhado nele.
# Cada botão do vídeo tem duas placas estáticas por cima (normal / aceso); o Button real é invisível.
const TITLE_DIR := "res://assets/ui/title/"
const TITLE_BUTTONS := [Rect2(30, 261, 317, 55), Rect2(30, 311, 317, 55), Rect2(30, 361, 317, 55), Rect2(30, 410, 317, 55), Rect2(30, 460, 317, 55), Rect2(30, 510, 317, 55), Rect2(30, 560, 317, 55)]
const TITLE_TIPS := ["Voltar para a expedição em andamento", "Escolher single player ou parceiro IA", "Hospedar ou entrar por IP",
	"Escolher uma seed para as docas", "Uniforme, armadura e robô", "Resolução, modo de tela, FPS, câmera, áudio e controles", "Sair do jogo"]
var title_video: VideoStreamPlayer

func title_background() -> Control:
	if not ResourceLoader.exists(TITLE_DIR + "title_still.png"): return MenuBackground.new()
	var root := Control.new(); root.size = Vector2(1344, 752); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var still := TextureRect.new(); still.texture = load(TITLE_DIR + "title_still.png")   # quadro parado (sem vídeo / headless)
	still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; still.size = root.size; still.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(still)
	var stream = load(TITLE_DIR + "title_loop.ogv") if ResourceLoader.exists(TITLE_DIR + "title_loop.ogv") else null
	if stream != null and DisplayServer.get_name() != "headless":
		title_video = VideoStreamPlayer.new(); title_video.stream = stream; title_video.expand = true
		title_video.size = root.size; title_video.mouse_filter = Control.MOUSE_FILTER_IGNORE; title_video.autoplay = true
		if "loop" in title_video: title_video.set("loop", true)
		title_video.finished.connect(title_video.play)   # garante o loop em qualquer versão
		root.add_child(title_video)
	return root

func title_button(i: int, callback: Callable, sel_layer: Control) -> Button:
	var r: Rect2 = TITLE_BUTTONS[i]
	var sel := TextureRect.new(); sel.texture = load(TITLE_DIR + "btn_%d_sel.png" % i); sel.position = r.position; sel.size = r.size
	sel.mouse_filter = Control.MOUSE_FILTER_IGNORE; sel.visible = false; sel_layer.add_child(sel)
	var b := Button.new(); b.position = r.position + Vector2(10, 5); b.size = r.size - Vector2(20, 10)   # só a placa, sem a margem
	for state in ["normal", "hover", "pressed", "focus", "disabled"]: b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.tooltip_text = TITLE_TIPS[i]; b.name = "Title_%d" % i
	var lit := func(on: bool): sel.visible = on and not b.disabled
	b.mouse_entered.connect(lit.bind(true)); b.mouse_exited.connect(func(): lit.call(b.has_focus()))
	b.focus_entered.connect(lit.bind(true)); b.focus_exited.connect(lit.bind(false))
	b.pressed.connect(callback); content.add_child(b)
	return b

func build_main() -> void:
	if not ResourceLoader.exists(TITLE_DIR + "btn_0.png"): return
	var normals := Control.new(); normals.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(normals)
	for i in range(TITLE_BUTTONS.size() - 1, -1, -1):   # de baixo para cima: o CONTINUAR fica por cima da vizinha
		var n := TextureRect.new(); n.texture = load(TITLE_DIR + "btn_%d.png" % i); n.position = TITLE_BUTTONS[i].position; n.size = TITLE_BUTTONS[i].size
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE; n.name = "Plate_%d" % i; normals.add_child(n)
	var sel_layer := Control.new(); sel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(sel_layer)
	var callbacks: Array[Callable] = [close, func(): show_screen("play"), func(): show_screen("online"), func(): show_screen("seed"),
		func(): pending_mode = "current"; open("equipment"), func(): show_screen("options"), func(): app.save_progress(); app.get_tree().quit()]
	for i in TITLE_BUTTONS.size():
		var b := title_button(i, callbacks[i], sel_layer)
		if i == 0:
			main_resume = b; b.disabled = not app.playing
			if b.disabled:
				b.tooltip_text = "Nenhuma expedição em andamento"
				normals.get_node("Plate_0").modulate = Color(0.5, 0.5, 0.5)
	# coop local (não está no desenho do menu): linha discreta entre SAIR e o status
	var coop := button(content, Rect2(40, 617, 298, 30), "COOP LOCAL  •  2 JOGADORES", func(): pending_mode = "local"; start_target = "arena"; read_equipment(); show_screen("equipment"), true)
	coop.add_theme_font_size_override("font_size", 14); coop.add_theme_color_override("font_color", Color("e8c98a")); coop.name = "CoopLocal"
	coop.tooltip_text = "Dois jogadores no mesmo computador"
	# status da rede: o vídeo já diz OFFLINE; qualquer outro estado é escrito por cima
	if app.network_status != "OFFLINE":
		panel(content, Rect2(78, 667, 222, 28), Color("2c3222"), Color("2c3222"))
		label(content, Rect2(78, 669, 222, 26), app.network_status, 14, Color("f0d9a0")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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

# Tela de equipamento 0.16 — layout v3 (art/concept/equipamento-v3-mockup.png).
# Fundo estático: assets/ui/equipment_v3.png (tools/equipment_v3.py). Tudo que muda é Control real.
# Cada clique já aplica a escolha. Controle: direcional navega, A seleciona, B volta, LB/RB trocam o uniforme.
const OUTFIT_ROW := {"padrao": 0, "espiao": 1, "mecanico": 2, "omega": 3}
const UNIFORM_CARDS := [["padrao", "1. PADRÃO", "equilibrado", Color("65f0f5")], ["mecanico", "2. MECÂNICO", "+ força", Color("8fdc6a")], ["espiao", "3. ESPIÃO", "+ velocidade", Color("b98cff")]]
const SHORT_DESC := {"padrao": "Equilibrado em tudo. Blaster de energia com cadência média.",
	"mecanico": "Mais força e resistência. Chave inglesa pesada; um pouco mais lento.",
	"espiao": "Rápido e discreto: os inimigos só o notam de perto."}
const LEGEND := Color("ffc94a")

class StatPanel extends Control:
	var host
	func _draw() -> void: host.draw_stats(self)

var stage_title: Label
var stage_line: Label
var stat_panel: StatPanel
var info_icons: Array = []
var info_titles: Array = []
var info_bodies: Array = []
var actor_tabs: Array = []

func sprite_of(key: String) -> AtlasTexture:
	if key == "titan": return atlas("res://assets/mech/titan_v3.png", Rect2(0, 0, 176, 176))
	if key == "spectre": return atlas("res://assets/mech/spectre_octopus_v2.png", Rect2(0, 0, 128, 128))
	return atlas("res://assets/marty/outfits.png", Rect2(0, 96 * OUTFIT_ROW.get(key, 0), 96, 96))

func icon_at(parent: Control, rect: Rect2, tex: Texture2D) -> TextureRect:
	var icon := TextureRect.new(); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex; icon.position = rect.position; icon.size = rect.size
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(icon); return icon

func build_equipment() -> void:
	# 0.16: layout v3 (art/concept/equipamento-v3-mockup.png). As caixas batem com tools/equipment_v3.py.
	info_icons.clear(); info_titles.clear(); info_bodies.clear(); actor_tabs.clear()
	# abas de jogador no topo (coop local: equipar Marty ou Echo)
	for i in 2:
		var tab := button(content, Rect2(1094 + i * 116, 21, 110, 28), "MARTY" if i == 0 else "ECHO (P2)", func(): select_actor(i))
		tab.add_theme_font_size_override("font_size", 14); tab.focus_mode = Control.FOCUS_NONE
		tab.disabled = i == 1 and not (app.playing and app.sim.coop == "local")
		actor_tabs.append(tab)
	live_status = label(content, Rect2(640, 22, 444, 26), "", 13, Color("9fc3bb")); live_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# UNIFORME: cartões com o sprite do jogo
	for i in 3:
		var data: Array = UNIFORM_CARDS[i]
		var key: String = "o_" + data[0]
		var b := button(content, Rect2(29, 113 + i * 101, 277, 86), "", func(): choose(key), true)
		b.name = "Slot_" + key; slot_buttons[key] = b
		icon_at(b, Rect2(6, 2, 90, 82), sprite_of(data[0]))
		label(b, Rect2(104, 10, 170, 26), data[1], 18, Color("e2e8dc")).name = "Name"
		label(b, Rect2(104, 36, 170, 22), data[2], 14, data[3])
		label(b, Rect2(104, 58, 170, 20), app.sim.UNIFORMS[data[0]].weapon_name, 11, Color("7f9a9a"))
	# ARMADURA lendária (única disponível por enquanto — liberada para testes); as 2 bloqueadas estão no fundo
	var ab := button(content, Rect2(28, 496, 86, 118), "", func(): choose("armor_omega"), true)
	ab.name = "Slot_armor_omega"; slot_buttons["armor_omega"] = ab
	icon_at(ab, Rect2(4, 4, 78, 78), sprite_of("omega"))
	label(ab, Rect2(0, 82, 86, 18), "ÔMEGA", 13, LEGEND).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(ab, Rect2(0, 99, 86, 16), "★ LENDÁRIA", 10, Color("ffe7a6")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# PALCO: arte do personagem em cena (assets/ui/portraits_v3, tools/make_portraits_v3.py)
	preview = TextureRect.new(); preview.position = Vector2(330, 74); preview.size = Vector2(688, 440)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.clip_contents = true; preview.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(preview)
	var fade := TextureRect.new(); var grad := GradientTexture2D.new(); grad.fill_from = Vector2(0, 1); grad.fill_to = Vector2(0, 0)
	grad.gradient = Gradient.new(); grad.gradient.set_color(0, Color(0.02, 0.05, 0.07, 0.92)); grad.gradient.set_color(1, Color(0.02, 0.05, 0.07, 0))
	fade.texture = grad; fade.position = Vector2(330, 404); fade.size = Vector2(688, 110); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(fade)
	stage_title = label(content, Rect2(330, 444, 688, 36), "", 26, Color.WHITE); stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_line = label(content, Rect2(330, 480, 688, 24), "", 13, CYAN); stage_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for s in [0, 1]:
		var side: int = -1 if s == 0 else 1
		var ax := 338 if side < 0 else 974
		var arrow := button(content, Rect2(ax, 272, 36, 36), "◀" if side < 0 else "▶", func(): cycle_outfit(side))
		arrow.add_theme_font_size_override("font_size", 16); arrow.focus_mode = Control.FOCUS_NONE
		label(content, Rect2(ax, 310, 36, 16), "LB" if side < 0 else "RB", 10, Color("9fb4b4")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# STATUS (desenhado) + descrições com sprites
	stat_panel = StatPanel.new(); stat_panel.host = self; stat_panel.position = Vector2(1042, 66); stat_panel.size = Vector2(286, 258); stat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(stat_panel)
	for i in 3:
		var y := 348 + i * 74
		info_icons.append(icon_at(content, Rect2(1058, y + 2, 56, 62), null))
		info_titles.append(label(content, Rect2(1126, y, 196, 20), "", 12, CYAN))
		var body := label(content, Rect2(1126, y + 20, 196, 50), "", 11, Color("c8d0cc")); body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_bodies.append(body)
	# ROBÔ: Titan e Spectre (a 3ª vaga, bloqueada, está no fundo)
	var robots := [["titan", "TITAN", "PILOTAR (E)", Color("8fdc6a")], ["spectre", "SPECTRE", "FUNDIR (G)", Color("b98cff")]]
	for i in 2:
		var r: Array = robots[i]
		var key: String = r[0]
		var b := button(content, Rect2(338 + i * 264, 580, 250, 90), "", func(): choose(key), true)
		slot_buttons["robot" + str(i)] = b
		icon_at(b, Rect2(6, 4, 90, 82), sprite_of(key))
		label(b, Rect2(106, 12, 136, 26), r[1], 18, Color("e2e8dc"))
		panel(b, Rect2(106, 48, 128, 26), Color(r[3], 0.18), r[3])
		label(b, Rect2(106, 50, 128, 24), r[2], 12, r[3]).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	telemetry = label(content, Rect2(740, 546, 272, 22), "", 11, Color("9fc3bb")); telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# BOTÕES
	var refuge := button(content, Rect2(1042, 582, 286, 48), "IR AO REFÚGIO  ▶", launch_refuge); refuge.add_theme_font_size_override("font_size", 20)
	var start := button(content, Rect2(1042, 636, 286, 46), "CONTINUAR" if app.playing and pending_mode == "current" else "⚔  INICIAR ARENA", launch)
	start.add_theme_color_override("font_color", Color("f08a24")); start.add_theme_color_override("font_hover_color", Color("ffb45a"))
	var back := button(content, Rect2(16, 634, 302, 48), "◀  VOLTAR", func(): show_screen("main"))
	back.add_theme_color_override("font_color", Color("e8be6e")); back.name = "Back"
	refresh_gear()
	var first: Button = slot_buttons.get("o_" + outfit_choice, slot_buttons["o_padrao"])
	first.grab_focus.call_deferred()

func select_actor(i: int) -> void:
	if gear_actor != i: swap_actor()

# Controle: LB/RB trocam o uniforme, B volta (os botões usam o foco do Godot: direcional + A).
func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventJoypadButton and event.pressed:
		if screen == "equipment" and event.button_index == JOY_BUTTON_LEFT_SHOULDER: cycle_outfit(-1); accept_event()
		elif screen == "equipment" and event.button_index == JOY_BUTTON_RIGHT_SHOULDER: cycle_outfit(1); accept_event()
		elif event.button_index == JOY_BUTTON_B and screen != "main": show_screen("main"); accept_event()
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_accept")):
		focus_first(); accept_event()

func focus_first() -> void:
	# primeiro botão visível da tela recebe o foco (para jogar só com o controle)
	var stack: Array = [content]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is Button and n.visible and not n.disabled and n.focus_mode != Control.FOCUS_NONE: n.grab_focus(); return
		stack.append_array(n.get_children())

func cycle_outfit(step: int) -> void:
	var order := ["padrao", "mecanico", "espiao"]
	var i := (order.find(outfit_choice) + step + order.size()) % order.size()
	choose("o_" + order[i])
	if slot_buttons.has("o_" + outfit_choice): slot_buttons["o_" + outfit_choice].grab_focus()

func draw_stats(c: Control) -> void:
	# 0.14: números vêm de Expedition.loadout_stats — as mesmas constantes que o jogo usa.
	var sim = app.sim
	var kind := "omega" if preview_kind == "armor_omega" else (preview_kind if preview_kind in ["titan", "spectre"] else "uniform")
	var rows: Array = sim.loadout_stats(kind, outfit_choice)
	var f := ThemeDB.fallback_font
	var sub: String = {"omega": "armadura lendária", "titan": "robô", "spectre": "robô"}.get(kind, "uniforme " + sim.UNIFORMS[outfit_choice].name.to_lower())
	c.draw_string(f, Vector2(84, 33), sub, HORIZONTAL_ALIGNMENT_RIGHT, 184, 11, Color("7f9a9a"))
	var colors := {"cyan": CYAN, "orange": Color("f08a24"), "gold": Color("e8be6e"), "green": Color("8fdc6a"), "violet": Color("b98cff")}
	var step := 30.0 if rows.size() > 6 else 34.0
	for i in rows.size():
		var r: Array = rows[i]
		var y := 50.0 + i * step
		c.draw_string(f, Vector2(18, y + 9), r[0], HORIZONTAL_ALIGNMENT_LEFT, 98, 12, Color("e2e8dc"))
		if r[3] in ["hearts", "hearts_shield"]:
			for h in sim.BASE_HEARTS + (sim.OMEGA_SHIELD_HEARTS if r[3] == "hearts_shield" else 0):
				var x: float = 118.0 + float(h) * 22
				var col := Color("e8404e") if h < sim.BASE_HEARTS else Color("54e0f0")
				c.draw_colored_polygon(PackedVector2Array([Vector2(x, y + 3), Vector2(x + 9, y + 15), Vector2(x + 18, y + 3), Vector2(x + 13.5, y - 2), Vector2(x + 9, y + 1), Vector2(x + 4.5, y - 2)]), col)
			if r[3] == "hearts": c.draw_string(f, Vector2(200, y + 9), r[1], HORIZONTAL_ALIGNMENT_RIGHT, 70, 13, Color("e2e8dc"))
			continue
		var color: Color = colors.get(r[3], CYAN)
		if r[2] >= 0:
			c.draw_rect(Rect2(118, y, 90, 10), Color("14202a")); c.draw_rect(Rect2(118, y, 90, 10), Color("28404a"), false, 1)
			var fill := int(roundf(9 * clampf(r[2], 0, 1)))
			for n in 9: c.draw_rect(Rect2(120 + n * 9.7, y + 2, 7.7, 6), color if n < fill else Color("1a2c32"))
		c.draw_string(f, Vector2(212, y + 10), r[1], HORIZONTAL_ALIGNMENT_RIGHT, 58, 12, color)

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
	# palco: arte em cena (tools/make_portraits_v3.py); sem arte, o sprite do jogo
	var portrait := "res://assets/ui/portraits_v3/%s.png" % preview_kind
	if ResourceLoader.exists(portrait):
		preview.texture = load(portrait); preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		preview.texture = sprite_of(preview_kind.trim_prefix("o_").replace("armor_", "")); preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var who := "ECHO" if gear_actor == 1 else "MARTY"
	match preview_kind:
		"titan": stage_title.text = "TITAN-01 • ROBÔ PILOTÁVEL"
		"spectre": stage_title.text = "SPECTRE • COMPANHEIRO FERAL"
		"armor_omega": stage_title.text = "%s • ARMADURA ÔMEGA ★ LENDÁRIA" % who
		_: stage_title.text = "%s • UNIFORME %s" % [who, uni.name]
	stage_title.add_theme_color_override("font_color", LEGEND if preview_kind == "armor_omega" else Color.WHITE)
	stage_line.text = "ARMA: %s   |   ARMADURA: ÔMEGA (R)   |   ROBÔ: %s" % [uni.weapon_name, robot_choice.to_upper()]
	# descrições com os sprites do jogo
	var infos := [[outfit_choice, "UNIFORME " + uni.name, CYAN, SHORT_DESC.get(outfit_choice, "")],
		["omega", "ARMADURA ÔMEGA • LENDÁRIA", LEGEND, "Lâmina de energia, 3 corações de escudo e +velocidade por 5s."],
		[robot_choice, "COMPANHEIRO • " + robot_choice.to_upper(), Color("8fdc6a") if robot_choice == "titan" else Color("b98cff"),
			"C invoca, E pilota. Canhão, bomba (R) e turbo (Shift)." if robot_choice == "titan" else "C invoca: acompanha e atira. G funde: +velocidade e dano."]]
	for i in infos.size():
		info_icons[i].texture = sprite_of(infos[i][0])
		info_titles[i].text = infos[i][1]; info_titles[i].add_theme_color_override("font_color", infos[i][2])
		info_bodies[i].text = infos[i][3]
	if stat_panel: stat_panel.queue_redraw()
	for i in actor_tabs.size():
		var tab: Button = actor_tabs[i]
		tab.add_theme_color_override("font_color", CYAN if i == gear_actor else Color("5f7a7e"))
	for key in slot_buttons:
		var selected: bool = key == "o_" + outfit_choice or (key == "armor_omega" and armor_choice == "omega") or (key == "robot0" and robot_choice == "titan") or (key == "robot1" and robot_choice == "spectre")
		var b: Button = slot_buttons[key]
		var edge: Color = LEGEND if key == "armor_omega" else CYAN
		var style := StyleBoxFlat.new(); style.bg_color = Color(edge, 0.1) if selected else Color(0, 0, 0, 0)
		style.border_color = edge if selected else Color(0, 0, 0, 0); style.set_border_width_all(3 if selected else 0); style.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", style)
		var hover := StyleBoxFlat.new(); hover.bg_color = Color(edge, 0.16); hover.border_color = edge.lightened(0.3); hover.set_border_width_all(3); hover.set_corner_radius_all(4)
		b.add_theme_stylebox_override("hover", hover); b.add_theme_stylebox_override("focus", hover)
		if b.has_node("Name"): (b.get_node("Name") as Label).add_theme_color_override("font_color", CYAN if selected else Color("e2e8dc"))

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
		telemetry.text = "Integridade: Titan %d • Spectre %d%s" % [app.sim.mech.hp, s.hp, "" if a.summon_cd <= 0 else "  •  recarga %.1fs" % a.summon_cd]
