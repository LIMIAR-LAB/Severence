class_name TemporalTerminal
extends Control
const DisplaySettingsScript = preload("res://scripts/display_settings.gd")
const MenuBackground = preload("res://scripts/menu_background.gd")
const EquipmentScreen = preload("res://scripts/equipment_screen.gd")

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
	place_equipment()

# 0.17: a tela de Equipamento (pixel art) fica fora do "stage" esticado: escala INTEIRA em pixels reais
# (1x, 2x, 3x…) e centrada. Só quando a janela é menor que 1344x752 ela reduz para caber.
func place_equipment() -> void:
	if content == null or screen != "equipment" or content.get_parent() != self: return
	var k := get_viewport().get_final_transform().get_scale().x   # lógico -> pixels da janela
	if k <= 0: k = 1.0
	var phys := get_viewport_rect().size * k
	var fit := minf(phys.x / 1344.0, phys.y / 752.0)
	var s := floorf(fit) if fit >= 1.0 else fit
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
	if content != null:
		content.get_parent().remove_child(content); content.queue_free()
	content = Control.new(); content.size = Vector2(1344, 752)
	if next == "equipment": add_child(content); place_equipment()   # escala inteira, fora do stage
	else: stage.add_child(content)
	rows.clear(); slot_buttons.clear(); preview = null; detail = null; live_status = null; main_resume = null; telemetry = null; equipment = null
	if next == "equipment": build_equipment(); return   # a moldura é desenhada pela própria tela
	var bg := TextureRect.new(); bg.texture = load("res://assets/ui/" + ("online" if next == "online" else "menu") + ".png")
	if next == "play": bg.texture = load("res://assets/ui/adventure.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.size = Vector2(1344, 752); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bg.texture.resource_path.ends_with("menu.png"):
		bg.free(); content.add_child(title_background())   # tela inicial: vídeo em loop (0.16)
	else: content.add_child(bg)
	match next:
		"main": build_main()
		"online": build_online()
		"play": build_play()
		"seed": build_seed()
		"options": build_options()
	focus_first.call_deferred()   # navegação pelo controle

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
	# 0.17: só itens desbloqueados ficam equipados
	if outfit_choice not in app.sim.OUTFITS or not app.sim.is_unlocked(outfit_choice): outfit_choice = "padrao"
	if not app.sim.is_unlocked(robot_choice): robot_choice = app.sim.default_robot()
	armor_choice = "omega" if app.sim.is_unlocked("omega") else ""

# ── Tela de EQUIPAMENTO 0.17: módulo scripts/equipment_screen.gd (moldura + camadas, dados em data/equipamento.json)
var equipment: Control
var armor_choice := ""

func build_equipment() -> void:
	equipment = EquipmentScreen.new(); equipment.host = self; equipment.app = app
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
	if equipment != null: equipment.cycle(step)

func apply_gear() -> bool:
	app.pref_outfit = outfit_choice; app.pref_robot = robot_choice; app.save_settings()
	if app.playing:
		var accepted: bool = app.request_loadout(gear_actor, outfit_choice, robot_choice, "omega")
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
	outfit_choice = a.outfit; robot_choice = a.selected_robot
	if equipment != null: equipment.refresh()

func launch_refuge() -> void:
	if app.online:
		live_status.text = "Refúgio pelo portal da expedição."; return
	launch()
	app.sim.make_hub(); app.apply_preferences(0); close()

func _process(_dt: float) -> void:
	pass
