extends Node2D
const DisplaySettingsScript = preload("res://scripts/display_settings.gd")

const Sim = preload("res://scripts/simulation.gd")
const View = preload("res://scripts/world_view.gd")
const EquipmentData := preload("res://scripts/equipment_data.gd")
const InventoryState := preload("res://scripts/inventory_state.gd")
const PORT := 24871
const RUN_SAVE := "user://expedition.save"
var sim: Expedition
var world: DockView
var camera: Camera2D
var canvas: CanvasLayer
var menu: Control
var hud_panel: PanelContainer
var hud: Label
var banner: Label
var help_label: Label
var status_label: Label
var address: LineEdit
var seed_input: LineEdit
var playing := false
var paused := false
var online := false
var hosting := false
var guest_id := 0
var remote_cmd: Dictionary = {}
var remote_age := 0.0
var send_timer := 0.0
var save_timer := 0.0
var previous_buttons: Dictionary = {}
# 0.19: preserva a mira do controle ao soltar o analógico.
var joy_aim: Dictionary = {}
var last_save := ""
var network_status := "OFFLINE"
var map_open := false
var screenshot_mode := false
var demo_ticks := 0
var automated := false
var automated_snapshot_logged := false
var frames := 0
var sounds: Dictionary = {}
var sound_players: Array = []
var last_audio: Array = [0.0, 0.0]
var pref_armor := false
var pref_outfit := "padrao"
var pref_gun := 0
var pref_robot := "titan"
var volume_percent := 70.0
var ui_input_block := 0.0
var presented_summary_seq := 0
# 0.18: remapeamento de controles do P1 (teclado/mouse). P2 local e joypad ainda são fixos.
const KEY_BIND_DEFAULTS := {"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D,
	"melee": KEY_F, "jump": KEY_SPACE, "dash": KEY_SHIFT, "interact": KEY_E, "armor": KEY_R,
	"weapon": KEY_Q, "summon": KEY_C, "fusion": KEY_G}
const KEY_BIND_LABELS := {"up": "ANDAR PRA CIMA", "down": "ANDAR PRA BAIXO", "left": "ANDAR PRA ESQUERDA",
	"right": "ANDAR PRA DIREITA", "melee": "GOLPE", "jump": "SALTO", "dash": "DASH", "interact": "INTERAGIR",
	"armor": "ARMADURA ÔMEGA", "weapon": "TROCAR ARMA", "summon": "INVOCAR ROBÔ", "fusion": "FUNDIR SPECTRE"}
const KEY_BIND_RESERVED := [KEY_ESCAPE, KEY_TAB, KEY_M, KEY_B, KEY_F2]
var key_binds: Dictionary = KEY_BIND_DEFAULTS.duplicate()
var display := DisplaySettingsScript.new()

func safe_int(value, fallback: int = 0) -> int:
	return int(value) if value is int or value is float else fallback

func safe_float(value, fallback: float = 0.0) -> float:
	return float(value) if value is int or value is float else fallback

func valid_saved_actor(value) -> bool:
	if not value is Dictionary: return false
	var actor: Dictionary = value
	return actor.get("p") is Vector2 and actor.p.is_finite() and (actor.get("hp") is float or actor.get("hp") is int)

func _ready() -> void:
	Input.joy_connection_changed.connect(log_joypad)
	for device in Input.get_connected_joypads(): log_joypad(device, true)
	sim = Sim.new(); load_progress(); load_settings()
	display.apply(get_tree())
	world = View.new(); world.sim = sim; add_child(world)
	camera = Camera2D.new(); camera.position = Vector2(500, 410); camera.zoom = Vector2(1.05, 1.05); add_child(camera)
	build_ui()
	for key in ["shot", "heavy", "jump", "hit"]: sounds[key] = load("res://assets/audio/" + key + ".wav")
	for _n in range(6):
		var player := AudioStreamPlayer.new(); player.volume_db = -12; add_child(player); sound_players.append(player)
	set_volume(volume_percent)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	var args := OS.get_cmdline_user_args()
	if "--capture" in args or "--capture-run" in args:
		screenshot_mode = true; start_solo()
		if "--capture-run" in args:
			sim.start_run(1941); sim.actors[0].p = Vector2(1760, 1320); sim.actors[1].p = Vector2(1820, 1280)
			sim.actors[0].armor = true
		else: sim.make_hub()
	for arg in args:
		if arg.begins_with("--hub-pos="):
			var xy: PackedStringArray = arg.trim_prefix("--hub-pos=").split(",")
			sim.actors[0].p = Vector2(float(xy[0]), float(xy[1])); sim.actors[1].p = sim.actors[0].p + Vector2(60, 10)
	if "--capture-arena" in args: screenshot_mode = true; start_solo()
	if "--capture-boss" in args:
		# Arena do Almirante para conferir sprites: -- --capture-boss --boss-hp=0.5
		screenshot_mode = true; start_single(); sim.start_run(1941)
		sim.actors[0].p = Vector2(520, 340); sim.actors[0].aim = Vector2.UP
		for e in sim.enemies:
			if e.kind == "boss":
				for arg in args:
					if arg.begins_with("--boss-hp="): e.hp = e.max * float(arg.trim_prefix("--boss-hp="))
	if "--open-chest" in args:
		screenshot_mode = true; start_single(); sim.start_run(1941)
		var c: Dictionary = sim.chests[0]; sim.actors[0].p = c.p + Vector2(-50, 10); sim.keys = 1
		sim.actors[0].p = c.p; sim.interact(sim.actors[0]); sim.actors[0].p = c.p + Vector2(-60, 20)
	if "--summon-demo" in args:
		# Captura da Cápsula Temporal: -- --capture --summon-demo --capture-tick=N  (recolhe e invoca o Titan)
		var sa: Dictionary = sim.actors[0]; sa.p = Vector2(900, 520); sa.facing = Vector2.RIGHT
		sim.mech.p = Vector2(1080, 560); sim.mech.owner = 0
		sim.summon_robot(sa); sa.summon_cd = 0
		if "--summon-in" in args: sim.effects.clear(); sim.summon_robot(sa)
	if "--pilot" in args:
		var pa: Dictionary = sim.actors[0]; pa.p = sim.mech.p - Vector2(40, 0); sim.interact(pa)
	if "--transform-demo" in args:
		# Captura no meio da transformação: -- --capture-arena --transform-demo --transform-at=0.5
		sim.actors[0].armor = false; sim.set_armor(sim.actors[0], true)
	for arg in args:
		if arg.begins_with("--outfit="): sim.actors[0].outfit = arg.trim_prefix("--outfit="); sim.actors[0].armor = false
		if arg == "--armor": sim.actors[0].armor = true; sim.actors[0].armor_time = 99.0
	if "--capture-docks-v04" in args:
		screenshot_mode = true; start_single(); sim.start_run(1941); sim.actors[0].armor = false
	for arg in args:
		if arg.begins_with("--at="):
			var xy: PackedStringArray = arg.trim_prefix("--at=").split(",")
			sim.actors[0].p = Vector2(float(xy[0]), float(xy[1])); sim.actors[1].p = sim.actors[0].p + Vector2(60, 20)
			camera.position = sim.actors[0].p
		if arg == "--boss-dead": sim.boss_dead = true; sim.enemies = sim.enemies.filter(func(e): return e.kind != "boss")
		if arg == "--map-open": map_open = true
		# 0.16: capturas do cenário — atalhos abertos, portões selados, sem inimigos
		if arg == "--open-shortcuts":
			for i in range(sim.obstacles.size() - 1, -1, -1):
				if sim.obstacle_kinds[i].begins_with("wall_crack_"): sim.open_shortcut(i)
		if arg == "--seal-gates": sim.enemies = sim.enemies.filter(func(e): return e.kind != "warden"); sim.side_complete = true
		if arg == "--no-enemies": sim.enemies = sim.enemies.filter(func(e): return e.kind == "warden")
		# 0.17: capturas/testes da tela de Equipamento nos dois estados
		if arg == "--new-game": sim.set_unlocks(EquipmentData.starting_unlocks())
		if arg == "--unlock-all": sim.set_unlocks(EquipmentData.items().map(func(it): return it.id))
		if arg == "--visit-all":
			for room in sim.rooms: sim.visited.append(room.id)
	for page in ["main", "play", "online", "equipment", "mission_inventory", "options", "characters", "pause", "summary"]:
		if "--capture-ui-" + page in args and page == "options": menu.show_screen("options")
		if "--capture-ui-" + page in args:
			screenshot_mode = true
			if page == "pause": start_refuge(); menu.open("pause")
			elif page == "summary":
				start_single(); sim.start_run(1941)
				sim.tick_time = 1122.0; sim.visited = sim.rooms.slice(0, maxi(1, int(sim.rooms.size() * 0.7))).map(func(room): return room.id)
				sim.run_stats = {"kills": 247, "kills_by_kind": {"fish": 14}, "damage_dealt": 48320.0, "damage_received": 2840.0, "max_streak": 36, "chests_opened": 3, "revives": 1, "fatal_source": "fish", "fatal_attack": "harpoon"}
				sim.money = 1240; sim.materials = sim.run_materials_start + 38; sim.finish_run("death")
				presented_summary_seq = sim.summary_seq; menu.open("summary")
			else:
				menu.read_equipment(); menu.show_screen(page)
	if "--network-host-test" in args: automated = true; host_game(); sim.start_run(1941)
	if "--network-client-test" in args: automated = true; address.text = "127.0.0.1"; join_game()

func build_ui() -> void:
	canvas = CanvasLayer.new(); add_child(canvas)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; canvas.add_child(root)
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.035, 0.065, 0.11, 0.93); style.border_color = Color("426474"); style.set_border_width_all(2); style.set_corner_radius_all(8)
	style.content_margin_left = 20; style.content_margin_right = 20; style.content_margin_top = 10; style.content_margin_bottom = 10
	hud_panel = PanelContainer.new(); hud_panel.position = Vector2(20, 16); hud_panel.size = Vector2(1240, 78); hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_theme_stylebox_override("panel", style); root.add_child(hud_panel)
	hud = Label.new(); hud.add_theme_font_size_override("font_size", 15); hud_panel.add_child(hud)
	banner = Label.new(); banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.anchor_left = 0.5; banner.anchor_right = 0.5; banner.anchor_top = 1.0; banner.anchor_bottom = 1.0
	banner.offset_left = -348; banner.offset_right = 348; banner.offset_top = -105; banner.offset_bottom = -45
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_theme_color_override("font_color", Color("f6d59a")); banner.add_theme_color_override("font_outline_color", Color("071019")); banner.add_theme_constant_override("outline_size", 6); banner.add_theme_font_size_override("font_size", 15); root.add_child(banner)
	help_label = Label.new(); help_label.position = Vector2(26, 744); help_label.add_theme_font_size_override("font_size", 13)
	help_label.text = "WASD mover • Mouse atirar • F golpe • Espaço salto • Shift dash • E pilotar • B PAUSA\nC INVOCAR/RECOLHER • G FUNDIR/SEPARAR • Q arma • R armadura • Tab mapa • Esc menu"
	root.add_child(help_label)
	# Hidden defaults support direct-launch/test paths before the online screen exists.
	address = LineEdit.new(); address.text = "127.0.0.1"; address.hide(); root.add_child(address)
	seed_input = LineEdit.new(); seed_input.hide(); root.add_child(seed_input)
	status_label = Label.new(); status_label.hide(); root.add_child(status_label)
	var visual_hud := preload("res://scripts/combat_hud.gd").new(); visual_hud.app = self; canvas.add_child(visual_hud)
	menu = preload("res://scripts/terminal_ui.gd").new(); menu.app = self; canvas.add_child(menu)

func disconnect_network() -> void:
	if multiplayer.multiplayer_peer != null: multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null; online = false; hosting = false; guest_id = 0; remote_cmd = {}; network_status = "OFFLINE"

func start_solo() -> void:
	disconnect_network(); sim.coop = "ai"; playing = true; paused = false; menu.hide()
	sim.start_arena(); apply_preferences(0); ui_input_block = 0.2

func start_single() -> void:
	start_solo(); sim.coop = "solo"; sim.start_arena(); apply_preferences(0)

func start_refuge() -> void:
	start_solo(); sim.make_hub(); apply_preferences(0)

func start_local() -> void:
	disconnect_network(); sim.coop = "local"; playing = true; paused = false; menu.hide()
	sim.start_arena(); apply_preferences(0); ui_input_block = 0.2
	sim.say("P2: setas mover, IJKL mirar, Enter tiro, / saltar, . corpo a corpo, Ctrl interagir. Ou controle.")

func start_seed() -> void:
	start_solo(); sim.start_run(seed_input.text.to_int() if seed_input.text.is_valid_int() else 1941); apply_preferences(0)

func present_summary_if_needed() -> void:
	if sim.summary_seq <= presented_summary_seq or sim.last_run_summary.is_empty(): return
	presented_summary_seq = sim.summary_seq
	if not online or hosting: save_progress()
	menu.open("summary")

func summary_new_run() -> void:
	if online and not hosting: return
	var next_seed := int(Time.get_ticks_msec()) % 999999
	sim.start_run(next_seed); apply_preferences(0)
	paused = false; map_open = false; menu.hide(); ui_input_block = 0.2

func summary_return_refuge() -> void:
	paused = false; map_open = false; menu.hide(); ui_input_block = 0.2

func host_game() -> void:
	disconnect_network()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 1)
	if error != OK: status_label.text = "Não foi possível abrir a porta: " + str(error); return
	multiplayer.multiplayer_peer = peer; online = true; hosting = true
	sim.coop = "ai"; playing = true; paused = false; menu.hide(); network_status = "HOST • aguardando P2"
	sim.start_arena(); apply_preferences(0); ui_input_block = 0.2
	sim.say("Servidor aberto. Parceiro IA ativo até alguém entrar.")

func join_game() -> void:
	disconnect_network()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.text.strip_edges(), PORT)
	if error != OK: status_label.text = "Falha ao iniciar conexão: " + str(error); return
	multiplayer.multiplayer_peer = peer; online = true; hosting = false
	status_label.text = "Conectando..."; network_status = "CONECTANDO"

func peer_connected(id: int) -> void:
	if hosting:
		guest_id = id; sim.coop = "online"; remote_age = 0
		sim.actors[1].active = true; sim.actors[1].dead = false
		network_status = "ONLINE • 2 jogadores"; sim.say("Jogador 2 conectado. IA desativada.")
		print("NETWORK_HOST_CONNECTED ", id)

func peer_disconnected(id: int) -> void:
	if hosting and id == guest_id:
		guest_id = 0; sim.coop = "ai"; remote_cmd = {}; network_status = "HOST • parceiro IA"
		sim.say("P2 desconectou. A IA assumiu o parceiro.")

func connected() -> void:
	playing = true; paused = false; menu.hide(); network_status = "ONLINE • você é P2"
	ui_input_block = 0.2
	print("NETWORK_CLIENT_CONNECTED")

func connection_failed() -> void:
	disconnect_network(); status_label.text = "Conexão falhou. Confira IP, firewall e porta UDP 24871."; menu.show()

func server_disconnected() -> void:
	disconnect_network(); playing = false; menu.show(); status_label.text = "Anfitrião desconectado. Progresso local preservado."

@rpc("any_peer", "call_remote", "reliable", 1)
func submit_input(data: Dictionary) -> void:
	if not hosting or multiplayer.get_remote_sender_id() != guest_id: return
	var clean := {}
	for key in ["move", "aim"]:
		if data.get(key) is Vector2 and data[key].is_finite(): clean[key] = data[key].limit_length()
	for key in ["fire", "melee", "jump", "dodge", "boost", "interact", "armor", "weapon", "summon", "fusion"]:
		clean[key] = data.get(key, false) == true
	remote_cmd = clean; remote_age = 0

func request_loadout(id: int, outfit: String, robot: String, armor_type: String = "omega") -> bool:
	if online and not hosting:
		if id != 1: return false
		change_loadout.rpc_id(1, outfit, robot, armor_type); return true
	return sim.equip(id, outfit, robot, armor_type)

@rpc("any_peer", "call_remote", "reliable", 3)
func change_loadout(outfit: String, robot: String, armor_type: String) -> void:
	if hosting and multiplayer.get_remote_sender_id() == guest_id:
		sim.equip(1, outfit, robot, armor_type)

func request_robot_action(id: int, action: String) -> void:
	if action not in ["summon", "fusion"]: return
	if online and not hosting:
		if id == 1: robot_action.rpc_id(1, action)
		return
	if id < 0 or id >= sim.actors.size(): return
	if action == "summon": sim.summon_robot(sim.actors[id])
	else: sim.toggle_fusion(sim.actors[id])

@rpc("any_peer", "call_remote", "reliable", 3)
func robot_action(action: String) -> void:
	if hosting and multiplayer.get_remote_sender_id() == guest_id: request_robot_action(1, action)

@rpc("authority", "call_remote", "reliable", 2)
func receive_state(packet: PackedByteArray) -> void:
	if hosting: return
	var unpacked := packet.decompress_dynamic(1048576, FileAccess.COMPRESSION_DEFLATE)
	if unpacked.size() < 4: return
	var decoded = bytes_to_var(unpacked)
	if not decoded is Dictionary: return
	var data: Dictionary = decoded
	sim.apply_snapshot(data)
	if sim.mode == "run" and sim.last_run_summary.is_empty() and menu.visible and menu.screen == "summary":
		menu.hide(); paused = false; map_open = false; ui_input_block = 0.2
	if automated and not automated_snapshot_logged:
		automated_snapshot_logged = true
		print("NETWORK_SNAPSHOT ", sim.actors[1].p)

func edge(action_name: String, value: bool) -> bool:
	var before: bool = previous_buttons.get(action_name, false)
	previous_buttons[action_name] = value
	return value and not before

func log_joypad(device: int, connected_pad: bool) -> void:
	if connected_pad:
		print("CONTROLE conectado: ", device, " • ", Input.get_joy_name(device), " • reconhecido=", Input.is_joy_known(device))
	else: print("CONTROLE desconectado: ", device)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.relative.length_squared() > 0.0:
		joy_aim.clear()

# 0.19: um controle no coop pertence ao P2; dois controles atendem os dois pilotos.
func connected_gamepads() -> Array:
	return Input.get_connected_joypads()

func gameplay_joypad(use_primary: bool, devices: Array) -> int:
	if devices.is_empty(): return -1
	if use_primary:
		return int(devices[0]) if sim.coop != "local" or devices.size() >= 2 else -1
	return int(devices[1] if devices.size() > 1 else devices[0])

func player_input(index: int, use_primary: bool = true) -> Dictionary:
	var a: Dictionary = sim.actors[index]
	var cmd := {"move": Vector2.ZERO, "aim": a.aim, "fire": false, "melee": false, "jump": false, "dodge": false, "interact": false, "armor": false, "weapon": false, "summon": false, "fusion": false}
	if use_primary:
		cmd.move = Vector2(float(Input.is_physical_key_pressed(key_binds.right)) - float(Input.is_physical_key_pressed(key_binds.left)), float(Input.is_physical_key_pressed(key_binds.down)) - float(Input.is_physical_key_pressed(key_binds.up))).normalized()
		if not joy_aim.get(index, false): cmd.aim = (get_global_mouse_position() - a.p + Vector2(0, 28)).normalized()
		cmd.fire = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not map_open and not minimap_rect().has_point(get_viewport().get_mouse_position())
		cmd.melee = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(key_binds.melee)
		cmd.jump = Input.is_physical_key_pressed(key_binds.jump)
		cmd.dodge = Input.is_physical_key_pressed(key_binds.dash); cmd.boost = cmd.dodge
		cmd.interact = Input.is_physical_key_pressed(key_binds.interact)
		cmd.armor = Input.is_physical_key_pressed(key_binds.armor)
		cmd.weapon = Input.is_physical_key_pressed(key_binds.weapon)
		cmd.summon = Input.is_physical_key_pressed(key_binds.summon); cmd.fusion = Input.is_physical_key_pressed(key_binds.fusion)
	else:
		cmd.move = Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))).normalized()
		var dir := Vector2(float(Input.is_physical_key_pressed(KEY_L)) - float(Input.is_physical_key_pressed(KEY_J)), float(Input.is_physical_key_pressed(KEY_K)) - float(Input.is_physical_key_pressed(KEY_I)))
		if dir.length() > 0.1: cmd.aim = dir.normalized()
		cmd.fire = Input.is_physical_key_pressed(KEY_ENTER); cmd.melee = Input.is_physical_key_pressed(KEY_PERIOD)
		cmd.jump = Input.is_physical_key_pressed(KEY_SLASH); cmd.dodge = Input.is_physical_key_pressed(KEY_COMMA); cmd.boost = cmd.dodge
		cmd.interact = Input.is_physical_key_pressed(KEY_CTRL); cmd.armor = Input.is_physical_key_pressed(KEY_O); cmd.weapon = Input.is_physical_key_pressed(KEY_U)
		cmd.summon = Input.is_physical_key_pressed(KEY_N); cmd.fusion = Input.is_physical_key_pressed(KEY_M)
	var devices := connected_gamepads()
	var device := gameplay_joypad(use_primary, devices)
	if device >= 0:
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2: cmd.move = stick.limit_length()
		stick = Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
		if stick.length() > 0.25:
			cmd.aim = stick.normalized(); joy_aim[index] = true
		cmd.fire = cmd.fire or Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.3
		cmd.melee = cmd.melee or Input.is_joy_button_pressed(device, JOY_BUTTON_X)
		cmd.jump = cmd.jump or Input.is_joy_button_pressed(device, JOY_BUTTON_A)
		cmd.dodge = cmd.dodge or Input.is_joy_button_pressed(device, JOY_BUTTON_B); cmd.boost = cmd.dodge
		cmd.interact = cmd.interact or Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
		cmd.weapon = cmd.weapon or Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_SHOULDER)
		cmd.armor = cmd.armor or Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER)
		cmd.summon = cmd.summon or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)
		cmd.fusion = cmd.fusion or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)
	for key in ["interact", "armor", "weapon", "dodge", "jump", "summon", "fusion"]: cmd[key] = edge(str(index) + key, cmd[key])
	if ui_input_block > 0: cmd.fire = false; cmd.melee = false
	return cmd

func _physics_process(dt: float) -> void:
	frames += 1
	ui_input_block = maxf(0, ui_input_block - dt)
	# 0.15: hitstop (micro-pausa em abates) e slow-mo "clutch" (meio coração)
	if playing and not paused:
		sim.hitstop = maxf(0, sim.hitstop - dt / maxf(Engine.time_scale, 0.001))
		var ts := 1.0
		if sim.clutch_t > 0: ts = 0.55
		if sim.hitstop > 0: ts = 0.12
		Engine.time_scale = ts
	elif Engine.time_scale != 1.0: Engine.time_scale = 1.0
	# 0.19: Options/Start também retoma a pausa automática ao perder o foco.
	var pause_pressed := Input.is_physical_key_pressed(KEY_ESCAPE)
	for device in connected_gamepads():
		pause_pressed = pause_pressed or Input.is_joy_button_pressed(device, JOY_BUTTON_START)
	if edge("esc", pause_pressed):
		if menu.visible:
			if menu.screen == "equipment": menu.show_screen("play")
			elif menu.screen == "mission_inventory": menu.show_screen("pause")
			else: menu.close()
		elif playing: menu.open("pause")
	if edge("gear", Input.is_physical_key_pressed(KEY_B)) and playing:
		if menu.visible:
			if menu.screen == "mission_inventory": menu.show_screen("pause")
			else: menu.close()
		else: menu.open("pause")
	# Mapa: TAB, M ou clique no minimapa (canto superior direito)
	var mouse_on_map := minimap_rect().has_point(get_viewport().get_mouse_position())
	if edge("map", Input.is_physical_key_pressed(KEY_TAB) or Input.is_physical_key_pressed(KEY_M) or (mouse_on_map and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))): map_open = not map_open
	if edge("coop", Input.is_physical_key_pressed(KEY_F2)) and not online:
		sim.coop = "local" if sim.coop == "ai" else "ai"; sim.say("Parceiro: " + sim.coop)
		sim.actors[1].active = true; sim.actors[1].dead = false; sim.actors[1].hp = maxf(sim.HEART * 1.5, sim.actors[1].hp)
	if playing and not paused:
		if online and not hosting:
			if menu.visible: submit_input.rpc_id(1, {})
			if not menu.visible:
				var command := player_input(1)
				if automated:
					command.move = Vector2.RIGHT if frames < 150 else Vector2.ZERO
					command.aim = Vector2.RIGHT; command.fire = frames < 240
					command.jump = frames == 100
				submit_input.rpc_id(1, command)
		else:
			var primary := {} if menu.visible or screenshot_mode else player_input(0)
			if screenshot_mode and "--demo-walk" in OS.get_cmdline_user_args():
				primary = {"move": Vector2(1, 0.25).normalized(), "aim": Vector2(1, -0.15).normalized(), "fire": true}
			var secondary := {} if menu.visible or screenshot_mode else player_input(1, false)
			if hosting and guest_id > 0:
				remote_age += dt
				secondary = remote_cmd if remote_age < 0.4 and not (menu.visible and menu.screen == "summary") else {}
			sim.step(dt, [primary, secondary])
			for key in ["interact", "armor", "weapon", "summon", "fusion", "dodge", "jump"]: remote_cmd[key] = false
			if hosting and guest_id > 0:
				send_timer += dt
				if send_timer >= 0.05:
					send_timer = 0
					receive_state.rpc(var_to_bytes(sim.snapshot()).compress(FileAccess.COMPRESSION_DEFLATE))
			save_timer += dt
			if save_timer > 2: save_timer = 0; save_progress()
			if not sim.new_unlocks.is_empty(): sim.new_unlocks.clear(); save_progress()   # desbloqueio salva na hora
	present_summary_if_needed()
	var target: Vector2 = sim.actors[0].p
	if sim.coop == "local": target = (sim.actors[0].p + sim.actors[1].p) / 2
	elif online and not hosting: target = sim.actors[1].p
	var zoom := display.camera_zoom() if sim.mode == "run" else 1.1   # expedição: distância da câmera configurável (OPÇÕES)
	if sim.coop == "local": zoom = clampf(950.0 / maxf(700, sim.actors[0].p.distance_to(sim.actors[1].p) + 380), 0.45, zoom)
	if not playing or sim.mode == "hub": target = Vector2(672, 459); zoom = 0.955
	elif sim.mode == "arena": target = Vector2(640, 530); zoom = 0.80
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zoom=") and sim.mode == "run": zoom = float(arg.trim_prefix("--zoom="))   # capturas de conferência
	camera.position = camera.position.lerp(target - Vector2(0, 40), 0.12)
	camera.zoom = camera.zoom.lerp(Vector2(zoom, zoom), 0.1)
	# Tremor de câmera: onda de choque da Ômega, tiro de escopeta e explosões do baú.
	var shake := 0.0
	for fx in sim.effects:
		if fx.kind == "shockwave": shake = maxf(shake, fx.life / fx.max * 12.0)
		elif fx.kind == "transform" and fx.life / fx.max > 0.45: shake = maxf(shake, 2.0)
		elif fx.kind == "chest_burst" and fx.life / fx.max > 0.75: shake = maxf(shake, 3.0)
		elif fx.kind == "stomp" and fx.life / fx.max > 0.7: shake = maxf(shake, 3.5)
		elif fx.kind == "explosion" and fx.p.distance_to(sim.actors[0].p) < 900: shake = maxf(shake, fx.life / fx.max * (9.0 if fx.get("r", 0.0) > 100 else 4.0))
		elif fx.kind == "gate_slam" and fx.life / fx.max > 0.6: shake = maxf(shake, 3.0)
		elif fx.kind == "recoil" and fx.life / fx.max > 0.6: shake = maxf(shake, 3.0)
	for a in sim.actors:
		if a.get("fire_flash", 0.0) > 0.06 and sim.weapon_of(a) in ["shotgun", "omega"]: shake = maxf(shake, 2.5)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	world.queue_redraw(); update_hud()
	if playing and not paused:
		for a in sim.actors:
			if a.shot > last_audio[a.id]: play_sound("heavy" if a.mech else "shot")
			last_audio[a.id] = a.shot
	if screenshot_mode:
		demo_ticks += 1
		var capture_tick := 90 if "--capture-arena" in OS.get_cmdline_user_args() or "--capture-boss" in OS.get_cmdline_user_args() else 30
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture-tick="): capture_tick = int(arg.trim_prefix("--capture-tick="))
		if demo_ticks == capture_tick: capture.call_deferred()
	if automated and frames > 420:
		if hosting: print("NETWORK_REMOTE_POSITION ", sim.actors[1].p, " MOVED=", sim.actors[1].p.x > 400)
		print("NETWORK_TEST_END ", "host" if hosting else "client"); get_tree().quit()

func play_sound(key: String) -> void:
	for player in sound_players:
		if not player.playing:
			player.stream = sounds[key]; player.play(); return

func update_hud() -> void:
	hud_panel.visible = false
	banner.visible = not menu.visible
	help_label.visible = false
	var a: Dictionary = sim.actors[0]; var b: Dictionary = sim.actors[1]
	var guns := ["PISTOLA", "ESCOPETA", "AUTOMÁTICA"]
	var area := "REFÚGIO" if sim.mode == "hub" else ("ARENA • ONDA " + str(sim.arena_wave) if sim.mode == "arena" else "DOCAS • SEED " + str(sim.seed_value))
	var dash_status := "DASH PRONTO" if a.dodge_cd <= 0 else "DASH %.1fs" % a.dodge_cd
	hud.text = "MARTY  %03d HP   %s   %s     |     ECHO %03d HP • %s     |     TITAN %03d • GAS %d%%\n%s    CHAVES %d    MOEDAS %d    FRAGMENTOS %d    %s    %s" % [int(a.hp), "COM ARMADURA" if a.armor else "SEM ARMADURA", guns[a.gun], int(b.hp), sim.coop.to_upper(), int(sim.mech.hp), int(sim.mech.get("fuel", 0.0) / sim.FUEL_MAX * 100), dash_status, sim.keys, sim.money, sim.materials, area, network_status]
	if sim.coop == "solo": hud.text = hud.text.replace("ECHO %03d HP • SOLO" % int(b.hp), "SINGLE PLAYER • SEM PARCEIRO")
	var controlled: Dictionary = sim.actors[1] if online and not hosting else a
	var robot_status := "C: %s %s" % [controlled.selected_robot.to_upper(), "PRONTO" if controlled.summon_cd <= 0 else "%.1fs" % controlled.summon_cd]
	if controlled.fused: robot_status += " • FUSÃO %d" % sim.spectres[controlled.id].hp
	hud.text = hud.text.replace(network_status, robot_status)
	banner.text = sim.message if sim.message_time > 0 else ("OPCIONAL • %.0fs • elimine os guardiões" % sim.side_time if sim.side_active else "")
	if paused: banner.text = "PAUSADO • Esc / Options / Start para continuar"
	if not playing: hud.text = "MARTY — FRATURAS DO TEMPO     /     PRIMEIRA VERSÃO JOGÁVEL\n2 estados de armadura • IA / coop local / conexão online direta"

func apply_preferences(id: int) -> void:
	# 0.17: só o que estiver desbloqueado; sem robô liberado, o ator fica sem robô
	var outfit := pref_outfit if pref_outfit in sim.OUTFITS and sim.is_unlocked(pref_outfit) else "padrao"
	var robot := pref_robot if sim.is_unlocked(pref_robot) else sim.default_robot()
	sim.equip(id, outfit, robot)

func ui_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func minimap_rect() -> Rect2:
	return Rect2(ui_size().x - 194, 14, 180, 112)

func set_volume(value: float) -> void:
	volume_percent = clampf(value, 0, 100)
	for player in sound_players:
		player.volume_db = -80.0 if volume_percent <= 0 else linear_to_db(volume_percent / 100.0) - 8

# 0.18: aplica um novo bind se a tecla não estiver em uso por outra ação; devolve true se aplicou.
func rebind_key(action: String, keycode: int) -> bool:
	if not KEY_BIND_DEFAULTS.has(action) or keycode in KEY_BIND_RESERVED: return false
	for other in key_binds:
		if other != action and key_binds[other] == keycode: return false
	key_binds[action] = keycode
	save_settings()
	return true

func save_settings() -> void:
	var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"armor": pref_armor, "outfit": pref_outfit, "gun": pref_gun, "robot": pref_robot, "volume": volume_percent, "display": display.to_dict(), "key_binds": key_binds}))

func load_settings() -> void:
	if not FileAccess.file_exists("user://settings.json"): return
	var data = JSON.parse_string(FileAccess.get_file_as_string("user://settings.json"))
	if not data is Dictionary: return
	pref_armor = data.get("armor", false) == true
	if data.get("display") is Dictionary: display.from_dict(data.display)
	pref_gun = clampi(int(data.get("gun", 0)), 0, 2)
	var saved_outfit: String = str(data.get("outfit", "padrao")).replace("londres", "espiao")
	pref_outfit = saved_outfit if saved_outfit in ["padrao", "mecanico", "espiao"] else "padrao"
	pref_robot = data.get("robot", "titan") if data.get("robot", "titan") in ["", "titan", "spectre"] else "titan"
	volume_percent = clampf(float(data.get("volume", 70)), 0, 100)
	if data.get("key_binds") is Dictionary:
		var loaded := {}
		for action in KEY_BIND_DEFAULTS:
			var bound = data.key_binds.get(action)
			if bound is float or bound is int:
				var kc := int(bound)
				if kc > 0 and kc not in KEY_BIND_RESERVED and not loaded.values().has(kc): loaded[action] = kc
		for action in loaded:
			var clash := false
			for other in key_binds:
				if other != action and not loaded.has(other) and key_binds[other] == loaded[action]: clash = true
			if not clash: key_binds[action] = loaded[action]

func save_progress() -> void:
	if online and not hosting: return
	var data := {"version": 2, "materials": sim.materials, "upgrade": sim.upgrade, "clears": sim.clears, "armor_unlocked": sim.armor_unlocked, "unlocked": sim.unlocked.keys(), "story_quest": sim.story_quest, "inventory": InventoryState.new(sim.inventory_state).to_dict()}
	var serialized := JSON.stringify(data)
	if serialized == last_save: return
	var file := FileAccess.open("user://progress.tmp", FileAccess.WRITE)
	if file == null: return
	file.store_string(serialized); file.close()
	var err := DirAccess.rename_absolute("user://progress.tmp", "user://progress.json")
	if err == OK: last_save = serialized

func has_saved_game() -> bool:
	return FileAccess.file_exists(RUN_SAVE)

func save_game() -> bool:
	if not playing or online: return false
	save_progress()
	var data := {"version": 2, "state": sim.snapshot(), "rng_state": sim.rng.state,
		"arena_wait": sim.arena_wait, "uid": sim.uid, "reward_claimed": sim.reward_claimed,
		"spectres": sim.spectres, "jump_gap": sim.jump_gap, "coop": sim.coop}
	var file := FileAccess.open("user://expedition.tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_var(data); file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path("user://expedition.tmp"), ProjectSettings.globalize_path(RUN_SAVE)) == OK

func return_to_title() -> bool:
	if playing and not online and not save_game(): return false
	disconnect_network()
	playing = false; paused = false; map_open = false
	previous_buttons.clear(); joy_aim.clear(); ui_input_block = 0.2
	menu.open("main")
	return true

func load_game() -> bool:
	if not has_saved_game(): return false
	var file := FileAccess.open(RUN_SAVE, FileAccess.READ)
	if file == null: return false
	var data = file.get_var(false); file.close()
	if not data is Dictionary or safe_int(data.get("version", 0)) not in [1, 2] or not data.get("state") is Dictionary: return false
	var state: Dictionary = data.state
	if state.get("mode") not in ["hub", "run", "arena"] or not state.get("actors") is Array or state.actors.size() != 2: return false
	if not valid_saved_actor(state.actors[0]) or not valid_saved_actor(state.actors[1]): return false
	var saved_spectres = state.get("spectres", data.get("spectres", []))
	if not saved_spectres is Array or saved_spectres.size() != 2: return false
	disconnect_network()
	sim.apply_snapshot(state)
	presented_summary_seq = sim.summary_seq
	sim.rng.state = safe_int(data.get("rng_state", sim.rng.state), sim.rng.state)
	sim.arena_wait = safe_float(data.get("arena_wait", 0.0)); sim.uid = safe_int(data.get("uid", 0))
	sim.reward_claimed = data.get("reward_claimed", false) == true
	if data.get("spectres") is Array and data.spectres.size() == 2: sim.spectres = data.spectres
	sim.jump_gap = data.get("jump_gap", Rect2())
	sim.coop = data.get("coop", "solo") if data.get("coop", "solo") in ["solo", "ai", "local"] else "solo"
	sim.ob_grid_count = -1; sim.build_navigation()
	playing = true; paused = false; map_open = false; previous_buttons.clear(); joy_aim.clear()
	ui_input_block = 0.2; menu.hide()
	return true

func load_progress() -> void:
	# 0.17: equipamento inicial definido no JSON; Titan e Spectre liberados durante os testes.
	sim.set_unlocks(EquipmentData.starting_unlocks())
	if not FileAccess.file_exists("user://progress.json"): sim.make_hub(); return
	var data = JSON.parse_string(FileAccess.get_file_as_string("user://progress.json"))
	if not data is Dictionary or safe_int(data.get("version", 0)) not in [1, 2]: return
	sim.materials = clampi(safe_int(data.get("materials", 0)), 0, 9999)
	sim.upgrade = clampi(safe_int(data.get("upgrade", 0)), 0, 3)
	sim.clears = clampi(safe_int(data.get("clears", 0)), 0, 9999)
	sim.story_quest = clampi(safe_int(data.get("story_quest", 0)),0,2)
	sim.armor_unlocked = data.get("armor_unlocked", false) == true
	var saved = data.get("unlocked", [])
	if saved is Array:
		for id in saved:
			if not EquipmentData.item(str(id)).is_empty(): sim.unlocked[str(id)] = true
	if data.get("inventory") is Dictionary: sim.inventory_state = InventoryState.new(data.inventory).to_dict()
	else: sim.inventory_state = InventoryState.new().to_dict()
	sim.check_unlocks()      # saves antigos: libera o que o progresso (chefe, expedições) já garantia
	sim.new_unlocks.clear()
	sim.make_hub()

func capture() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output")
	var path := "res://test-output/gameplay.png" if "--capture-run" in OS.get_cmdline_user_args() else "res://test-output/refugio.png"
	if "--capture-arena" in OS.get_cmdline_user_args(): path = "res://test-output/arena-v06.png"
	if "--capture-boss" in OS.get_cmdline_user_args(): path = "res://test-output/boss-v06.png"
	if "--capture-docks-v04" in OS.get_cmdline_user_args(): path = "res://test-output/docks-v04.png"
	for page in ["main", "play", "online", "equipment", "mission_inventory", "options", "characters", "pause", "summary"]:
		if "--capture-ui-" + page in OS.get_cmdline_user_args(): path = "res://test-output/ui-" + page + ".png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-name="): path = "res://test-output/" + arg.trim_prefix("--capture-name=") + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ", path); get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and sim != null: save_progress()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing and not online:
		paused = true; if_menu_show()

func if_menu_show() -> void:
	if menu != null and not menu.visible: menu.open("pause")
