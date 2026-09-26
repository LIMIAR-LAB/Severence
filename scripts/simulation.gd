class_name Expedition
extends RefCounted
const DOCKS := preload("res://scripts/docks_map.gd")  # não depende do cache de class_name
const SummonFX = preload("res://scripts/summon_fx.gd")

# All gameplay state is serializable. Only the host advances simulation.
var actors: Array = []
var enemies: Array = []
var bullets: Array = []
var pickups: Array = []
var effects: Array = []
var rooms: Array = []
var floors: Array = []
var obstacles: Array = []
var chests: Array = []
var mech: Dictionary = {}
var rng := RandomNumberGenerator.new()
var seed_value := 1
var mode := "hub"
var message := ""
var message_time := 0.0
var money := 0
var keys := 0
var materials := 0
var upgrade := 0
var clears := 0
var armor_unlocked := false
var side_active := false
var side_complete := false
var side_time := 0.0
var side_failed := false
var shop_bought := false
var boss_dead := false
var secret_open := false
var tick_time := 0.0
var uid := 0
var coop := "ai"
var reward_claimed := false
var ramps: Array = []
var raised: Array = []
var gaps: Array = []
var jump_gap := Rect2()   # primeiro canal (compatibilidade)
var obstacle_kinds: Array = []
var decor: Array = []
var visited: Array = []
var doors: Array = []        # 0.12: portões entre salas e corredores {"r", "room", "side"}
var gate_blocks: Array = []  # retângulos dos portões fechados agora (colisão)
var hazards: Array = []      # 0.12: perigos do cenário (poça com tentáculo)
var nav := AStar2D.new()
var nav_points: Dictionary = {}
var ai_path := PackedVector2Array()
var ai_path_timer := 0.0
var arena_wave := 0
var arena_wait := 0.0
var spectres: Array = []
var obstacle_hp: Array = []      # 0.13: vida de cada obstáculo (-1 = indestrutível)
var fuses: Array = []            # barris explosivos prestes a estourar (reação em cadeia)
var ob_grid: Dictionary = {}     # grade espacial dos obstáculos (mapa grande = muitos props)
var ob_grid_count := -1

func _init() -> void:
	make_hub()

func actor(id: int, pos: Vector2) -> Dictionary:
	return {"id": id, "active": id == 0 or coop != "solo", "p": pos, "aim": Vector2.RIGHT, "facing": Vector2.DOWN, "dash_dir": Vector2.RIGHT, "move": Vector2.ZERO, "hp": BASE_HEARTS * HEART, "shield": 0.0, "armor": false,
		"jump": 0.0, "jump_cd": 0.0, "shot": 0.0, "slash": 0.0, "dodge": 0.0, "dodge_cd": 0.0,
		"hurt": 0.0, "step": 0.0, "mech": false, "dead": id == 1 and coop == "solo", "gun": 0, "interact_cd": 0.0, "revive": 0.0,
		"selected_robot": "titan", "summon_cd": 0.0, "fused": false, "armor_before_fusion": false,
		"outfit": "padrao" if id == 0 else "mecanico", "snare": 0.0, "fire_flash": 0.0, "transform": 0.0,
		"armor_type": "omega", "armor_time": 0.0, "armor_cd": 0.0, "bomb_cd": 0.0, "combo": 0, "combo_t": 0.0, "boost": 1.0}

# UNIFORMES (skins, sempre vestidos) e ARMADURAS (poder temporário com recarga).
# Cada uniforme tem arma, velocidade, golpe e resistência próprios.
const OUTFITS := ["padrao", "mecanico", "espiao"]
const UNIFORMS := {
	"padrao": {"name": "PADRÃO", "weapon": "pistol", "weapon_name": "BLASTER", "speed": 320.0, "melee": 26.0, "taken": 1.0, "dash_cd": 0.6,
		"desc": "Equilibrado.\nBlaster: 16 de dano, cadência média.\nVelocidade 320 • golpe 26."},
	"mecanico": {"name": "MECÂNICO", "weapon": "shotgun", "weapon_name": "ESCOPETA DE REBITE", "speed": 290.0, "melee": 46.0, "taken": 0.85, "dash_cd": 0.7,
		"desc": "MAIS FORÇA.\nEscopeta: 6 chumbos de 9.\nChave inglesa: golpe 46.\n−15% de dano recebido • mais lento (290)."},
	"espiao": {"name": "ESPIÃO", "weapon": "smg", "weapon_name": "SUBMETRALHADORA", "speed": 385.0, "melee": 20.0, "taken": 1.1, "dash_cd": 0.35,
		"desc": "MAIS VELOCIDADE.\nSubmetralhadora: rajada rápida (7).\nVelocidade 385 • dash recarrega 2× mais rápido.\nInimigos só o notam de perto.\n+10% de dano recebido."}}
const ARMORS := {
	"omega": {"name": "ARMADURA ÔMEGA", "duration": 5.0, "cooldown": 60.0, "speed": 430.0, "taken": 1.0,
		"desc": "LENDÁRIA • dura 5s, recarrega 60s (R).\nBaús recarregam na hora.\nLâmina Ômega: combo de 3 cortes (38/38/64);\no 3º solta uma onda que atravessa inimigos.\n+3 CORAÇÕES DE ESCUDO • MUITO mais rápido (430) • corte reflete tiros.\nUniforme e arma não mudam enquanto ativa."}}
const OUTFIT_NAMES := {"padrao": "PADRÃO", "mecanico": "MECÂNICO", "espiao": "ESPIÃO", "omega": "ARMADURA ÔMEGA"}

# Enrage do Almirante: sem isso a luta podia travar indefinidamente contra um time passivo.
# Depois de BOSS_ENRAGE_TIME segundos de combate ativo, os cooldowns de ataque encolhem por BOSS_ENRAGE_SCALE.
const BOSS_ENRAGE_TIME := 150.0
const BOSS_ENRAGE_SCALE := 0.6

# ── Vida em corações (0.12) ─────────────────────────────────────────────────
# 1 coração = 10 de vida. Marty começa com 3. Golpe comum tira meio coração; golpe pesado
# (arpão, bala de canhão: dano ≥ 20 depois do uniforme) tira um coração inteiro.
const HEART := 10.0
const BASE_HEARTS := 3
const HURT_IFRAMES := 0.9
const OMEGA_SHIELD_HEARTS := 3

func max_hp() -> float:
	# 0.14: todos começam SEMPRE com 3 corações. As melhorias da bancada estão congeladas até
	# definirmos a progressão de vida (o valor "upgrade" continua salvo para não perder o progresso).
	return BASE_HEARTS * HEART

func heart_damage(amount: float) -> float:
	return HEART if amount >= 20.0 else HEART * 0.5

func heal(a: Dictionary, hearts: float) -> void:
	a.hp = minf(a.hp + hearts * HEART, max_hp())

func uniform_of(a: Dictionary) -> Dictionary:
	return UNIFORMS.get(a.get("outfit", "padrao"), UNIFORMS.padrao)

# R: veste a armadura se estiver carregada; enquanto ativa, R a guarda antes do tempo.
func toggle_armor(a: Dictionary) -> void:
	if a.fused: say("Desfaça a fusão antes de vestir a armadura."); return
	if a.mech: return
	if a.armor:
		set_armor(a, false); a.armor_cd = ARMORS[a.armor_type].cooldown; return
	if a.armor_cd > 0: say("%s recarregando: %.0fs" % [ARMORS[a.armor_type].name, ceilf(a.armor_cd)]); return
	set_armor(a, true); a.armor_time = ARMORS[a.armor_type].duration

const TRANSFORM_TIME := 1.4
const TRANSFORM_BURST := 0.75  # quando a onda de choque sai (segundos restantes)

# Liga/desliga a Armadura Ômega. Ligar dispara a transformação (aura, pilar de luz e onda de choque).
func set_armor(a: Dictionary, on: bool) -> void:
	if on == a.armor: return
	a.armor = on
	a.shield = OMEGA_SHIELD_HEARTS * HEART if on else 0.0   # 3 corações temporários de escudo
	if on:
		a.transform = TRANSFORM_TIME; a.hurt = 0.0
		effects.append({"p": a.p, "kind": "transform", "life": TRANSFORM_TIME, "max": TRANSFORM_TIME, "owner": a.id})
		say("ARMADURA ÔMEGA ATIVADA!")
	else:
		effects.append({"p": a.p, "kind": "power_down", "life": 0.45, "max": 0.45})

func transform_burst(a: Dictionary) -> void:
	effects.append({"p": a.p, "kind": "shockwave", "life": 0.55, "max": 0.55})
	for e in enemies:
		var d: float = e.p.distance_to(a.p)
		if d < 190:
			e.hp -= 40.0 if e.kind != "boss" else 25.0; e.hurt = 0.2
			if e.kind != "boss": e.p = move_body(e.p, (e.p - a.p).normalized() * (190 - d) * 0.6, 14)
	for b in bullets:
		if b.team == 1 and b.p.distance_to(a.p) < 240: b.life = 0

func outfit_of(a: Dictionary) -> String:
	return "omega" if a.armor else a.get("outfit", "padrao")

func new_mech(pos: Vector2) -> Dictionary:
	# 0.14: o Titan consome gasolina enquanto pilotado — começa com tanque parcial.
	return {"p": pos, "hp": 240.0, "fuel": 70.0, "occupant": -1, "aim": Vector2.RIGHT, "step": 0.0, "deployed": true, "owner": -1}

func reset_spectres() -> void:
	spectres = []
	for a in actors:
		spectres.append({"owner": a.id, "state": "stored", "hp": SPECTRE_HP, "p": a.p, "aim": Vector2.RIGHT, "shot": 0.0})

# Refúgio • Fora do Tempo — coordenadas iguais às de assets/environment/refuge/refuge_bg.png (1344x752).
# Pisos e obstáculos são colisores invisíveis sobre a arte pintada.
const HUB_SIZE := Vector2(1344, 752)
const HUB_POINTS := [
	{"id": "portal", "p": Vector2(655, 215), "r": 80, "label": "E • DOCAS / 1941"},
	{"id": "lost", "p": Vector2(965, 275), "r": 85, "label": "COORDENADA PERDIDA • BLOQUEADO"},
	{"id": "core", "p": Vector2(640, 455), "r": 70, "label": "E • NÚCLEO TEMPORAL"},
	{"id": "bench", "p": Vector2(330, 335), "r": 85, "label": "E • BANCADA (em breve)"},
	{"id": "armor", "p": Vector2(265, 580), "r": 85, "label": "E • TROCAR UNIFORME"},
	{"id": "mural", "p": Vector2(672, 478), "r": 55, "label": "E • MURAL DA EQUIPE"},
	{"id": "hangar", "p": Vector2(1000, 545), "r": 70, "label": "HANGAR DO TITAN"}]
const HUB_TITAN_BAY := Vector2(1140, 548)

func make_hub() -> void:
	doors.clear(); gate_blocks.clear(); hazards.clear()
	mode = "hub"
	actors = [actor(0, Vector2(760, 440)), actor(1, Vector2(820, 450))]
	enemies.clear(); bullets.clear(); pickups.clear(); effects.clear(); obstacles.clear(); chests.clear(); obstacle_kinds.clear(); obstacle_hp.clear(); fuses.clear()
	floors = [
		Rect2(420, 300, 490, 188),   # piso central (xadrez)
		Rect2(560, 180, 190, 125),   # escadaria do portal
		Rect2(470, 235, 100, 70),    # cabos à esquerda da escadaria
		Rect2(750, 230, 160, 75),    # paralelepípedos à direita
		Rect2(895, 245, 115, 70),    # plataforma da coordenada perdida
		Rect2(265, 318, 160, 42),    # tablado da bancada
		Rect2(400, 350, 125, 180),   # corredor inferior esquerdo
		Rect2(400, 530, 68, 82),     # passagem entre armadura e canto pessoal
		Rect2(215, 556, 220, 56),    # frente da armadura de treino
		Rect2(826, 480, 115, 150),   # piso inferior direito
		Rect2(880, 515, 150, 60),    # rampa de acesso ao hangar
		Rect2(1010, 468, 240, 108)]  # baia do Titan
	obstacles = [
		Rect2(570, 348, 140, 86),    # pedestal do núcleo
		Rect2(505, 150, 40, 90), Rect2(770, 150, 40, 90),  # postes de lanterna do portal
		Rect2(270, 300, 44, 22),     # banquinho
		Rect2(880, 462, 62, 52),     # bloco de pedra do hangar
		Rect2(1235, 450, 30, 130)]   # bancada vermelha do hangar
	rooms = [{"r": Rect2(Vector2.ZERO, HUB_SIZE), "name": "REFÚGIO • FORA DO TEMPO", "kind": "hub"}]
	mech = new_mech(HUB_TITAN_BAY); mech.aim = Vector2.DOWN
	reset_spectres()
	for a in actors:
		a.armor = false; a.armor_cd = 0.0
	build_navigation()
	say("Bem-vindo, Marty. Suba até o portal DOCAS / 1941 e pressione E.")


func hub_point_near(pos: Vector2) -> Dictionary:
	for point in HUB_POINTS:
		if pos.distance_to(point.p) < point.r: return point
	return {}

func start_arena() -> void:
	mode = "arena"; tick_time = 0; arena_wave = 0; arena_wait = 0
	side_active = false; side_complete = false; side_failed = false; side_time = 0
	actors = [actor(0, Vector2(400, 600)), actor(1, Vector2(470, 650))]
	enemies.clear(); bullets.clear(); pickups.clear(); effects.clear(); obstacles.clear(); chests.clear(); obstacle_kinds.clear(); obstacle_hp.clear(); fuses.clear()
	floors = [Rect2(80, 100, 1120, 820)]
	rooms = [{"r": floors[0], "name": "ARENA DE TESTE • ONDAS / DASH / ROBÔ", "kind": "arena"}]
	mech = new_mech(Vector2(250, 800)); money = 0; keys = 0
	reset_spectres()
	doors.clear(); gate_blocks.clear(); hazards.clear()
	build_navigation(); spawn_arena_wave()
	say("TESTE IMEDIATO • inimigos à direita • Shift: DASH • F: golpe • R: armadura • E: robô")

func spawn_arena_wave() -> void:
	arena_wave += 1
	for n in range(4 + mini(arena_wave, 4)):
		spawn_enemy(Vector2(800 + (n % 3) * 120, 290 + floorf(float(n) / 3) * 190), ["cult", "fish", "crawler", "brute"][n % 4])
	for a in actors:
		if not a.dead: heal(a, 1)

func start_run(new_seed: int) -> void:
	# Mapa fixo (scripts/docks_map.gd). A seed só sorteia os tipos de inimigo e pequenos desvios.
	seed_value = new_seed; rng.seed = seed_value
	mode = "run"; tick_time = 0; money = 12; keys = 1
	side_active = false; side_complete = false; side_failed = false; shop_bought = false
	boss_dead = false; secret_open = false; reward_claimed = false
	var P: Dictionary = DOCKS.POINTS
	actors = [actor(0, P.spawn), actor(1, P.spawn2)]
	for a in actors:
		a.hp = max_hp(); a.shield = 0.0; a.armor = false; a.armor_cd = ARMORS[a.armor_type].cooldown  # carrega durante a expedição
	enemies.clear(); bullets.clear(); pickups.clear(); effects.clear(); obstacles.clear(); chests.clear(); obstacle_kinds.clear(); decor.clear(); visited.clear()
	rooms = []
	for room in DOCKS.ROOMS: rooms.append(room.duplicate())
	floors = []
	for room in rooms:
		if room.kind != "secret": floors.append(room.r)
	floors.append_array(DOCKS.EXTRA_FLOORS); floors.append_array(DOCKS.CORRIDORS)
	raised = DOCKS.RAISED.duplicate(); ramps = DOCKS.RAMPS.duplicate(true); gaps = DOCKS.GAPS.duplicate()
	jump_gap = gaps[0]
	build_doors(); hazards = DOCKS.HAZARDS.duplicate(true)
	obstacle_hp.clear(); fuses.clear()
	for o in DOCKS.OBSTACLES:
		obstacles.append(Rect2(o[0], o[1], o[2], o[3])); obstacle_kinds.append(o[4]); obstacle_hp.append(DESTRUCTIBLE.get(o[4], -1.0))
	for d in DOCKS.DECOR:
		var item := {"p": Vector2(d[0], d[1]), "kind": d[2]}
		if d.size() > 3: item.merge(d[3])
		decor.append(item)
	for room in rooms:
		room["waves"] = DOCKS.WAVES.get(room.get("id", ""), []).duplicate(true)
	for c in DOCKS.CHESTS: chests.append({"p": Vector2(c[0], c[1]), "open": false, "secret": c[2]})
	mech = new_mech(P.mech)
	reset_spectres()
	for sp in DOCKS.SPAWNS:
		var pool: Array = DOCKS.GROUPS[sp[2]]
		var pos := Vector2(sp[0], sp[1]) + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
		if not clear_at(pos, 16): pos = Vector2(sp[0], sp[1])
		spawn_enemy(pos, pool[rng.randi_range(0, pool.size() - 1)])
	spawn_enemy(P.boss, "boss")
	spawn_enemy(P.warden, "warden")
	pickups.append({"p": P.key, "kind": "key"})
	build_navigation()
	say("Docas de 1941 • recupere o núcleo do Almirante. TAB/M abre o mapa. A armadura carrega em 60s.")

# ── Portões (0.12) ───────────────────────────────────────────────────────────
# Cada ponta de corredor que encosta numa sala vira um portão. Ao entrar numa sala com inimigos,
# todos os portões dela fecham até o último inimigo daquela sala cair (estilo Enter the Gungeon).
const DOOR_DEPTH := 36.0

func build_doors() -> void:
	doors.clear(); gate_blocks.clear()
	for room in rooms:
		if not room.has("id") or room.kind == "secret": continue
		var r: Rect2 = room.r
		for f: Rect2 in DOCKS.CORRIDORS:
			var side := ""
			var span_x: bool = f.position.x < r.end.x and f.end.x > r.position.x
			var span_y: bool = f.position.y < r.end.y and f.end.y > r.position.y
			if span_x and absf(f.end.y - r.position.y) < 3: side = "top"
			elif span_x and absf(f.position.y - r.end.y) < 3: side = "bottom"
			elif span_y and absf(f.end.x - r.position.x) < 3: side = "left"
			elif span_y and absf(f.position.x - r.end.x) < 3: side = "right"
			if side == "": continue
			var d := Rect2()
			match side:
				"top": d = Rect2(f.position.x, r.position.y - DOOR_DEPTH, f.size.x, DOOR_DEPTH)
				"bottom": d = Rect2(f.position.x, r.end.y, f.size.x, DOOR_DEPTH)
				"left": d = Rect2(r.position.x - DOOR_DEPTH, f.position.y, DOOR_DEPTH, f.size.y)
				"right": d = Rect2(r.end.x, f.position.y, DOOR_DEPTH, f.size.y)
			doors.append({"r": d, "room": room.id, "side": side})

func room_by_id(id: String) -> Dictionary:
	for room in rooms:
		if room.get("id", "") == id: return room
	return {}

func room_threats(id: String) -> int:
	return enemies.filter(func(e): return e.get("room", "") == id and not e.side).size()

func refresh_gate_blocks() -> void:
	gate_blocks.clear()
	for d in doors:
		if room_by_id(d.room).get("locked", false): gate_blocks.append(d.r)

func step_gates(step_dt: float = 0.016) -> void:
	var changed := false
	for room in rooms:
		if not room.has("id") or room.kind == "secret": continue
		if room.get("locked", false):
			if room.get("wave_t", 0.0) > 0:
				room.wave_t -= step_dt
				if room.wave_t <= 0: spawn_wave(room)
				continue
			if room_threats(room.id) == 0 and not room.get("waves", []).is_empty():
				room.wave_t = 1.1
				say("REFORÇOS! Mais criaturas emergem das docas!")
				for w in room.waves: effects.append({"p": Vector2(w[0], w[1]), "kind": "spawn_portal", "life": 1.2, "max": 1.2})
				continue
			if room_threats(room.id) == 0:
				room.locked = false; room.cleared = true; changed = true
				say("SALA LIMPA • os portões se abriram!")
				for d in doors:
					if d.room == room.id: effects.append({"p": d.r.get_center(), "kind": "gate_open", "life": 0.8, "max": 0.8})
		elif not room.get("cleared", false):
			var inside: Dictionary = {}
			for a in actors:
				if a.active and not a.dead and room.r.grow(-50).has_point(a.p): inside = a; break
			if inside.is_empty(): continue
			if room_threats(room.id) == 0: room.cleared = true; continue
			room.locked = true; changed = true
			say("PORTÕES FECHADOS • elimine todos os inimigos da sala!")
			for d in doors:
				if d.room == room.id: effects.append({"p": d.r.get_center(), "kind": "gate_slam", "life": 0.5, "max": 0.5})
			# quem ficou do lado de fora é puxado para dentro (ninguém fica preso no corredor)
			for a in actors:
				if a.active and not a.dead and not room.r.has_point(a.p):
					var spot: Vector2 = inside.p + Vector2(-50, 30)
					a.p = spot if clear_at(spot, 23 if a.mech else 11) else inside.p
					if a.mech: mech.p = a.p
	if changed: refresh_gate_blocks()

func spawn_wave(room: Dictionary) -> void:
	for w in room.waves:
		var pool: Array = DOCKS.GROUPS[w[2]]
		spawn_enemy(Vector2(w[0], w[1]), pool[rng.randi_range(0, pool.size() - 1)])
		enemies[-1]["alerted"] = true; enemies[-1]["room"] = room.id
	room.waves = []

# ── Props destrutíveis e barris explosivos (0.13) ─────────────────────────────
const DESTRUCTIBLE := {"crate": 34.0, "crate_2": 44.0, "crate_3": 44.0, "crate_net": 40.0, "crate_barnacles": 50.0, "crate_broken": 20.0,
	"barrel": 40.0, "barrel_oil": 40.0, "barrel_toxic": 40.0, "barrel_explosive": 16.0, "barrel_tipped": 30.0,
	"fish_basket": 16.0, "lobster_trap": 22.0, "sandbags": 110.0, "sandbags_corner": 110.0, "sandbags_damaged": 60.0, "jerrycans": 24.0}
const BARREL_BLAST := {"radius": 150.0, "damage": 60.0, "fuse": 0.18}

func rebuild_ob_grid() -> void:
	ob_grid.clear(); ob_grid_count = obstacles.size()
	for i in obstacles.size():
		var b: Rect2 = obstacles[i].grow(32)
		for gy in range(int(floorf(b.position.y / 200.0)), int(floorf(b.end.y / 200.0)) + 1):
			for gx in range(int(floorf(b.position.x / 200.0)), int(floorf(b.end.x / 200.0)) + 1):
				var key := Vector2i(gx, gy)
				if not ob_grid.has(key): ob_grid[key] = []
				ob_grid[key].append(i)

func obstacles_near(pos: Vector2) -> Array:
	if ob_grid_count != obstacles.size(): rebuild_ob_grid()
	return ob_grid.get(Vector2i(int(floorf(pos.x / 200.0)), int(floorf(pos.y / 200.0))), [])

func obstacle_at(pos: Vector2, margin: float = 2.0) -> int:
	for i in obstacles_near(pos):
		if obstacles[i].grow(margin).has_point(pos): return i
	return -1

func damage_obstacle(i: int, amount: float) -> void:
	if i < 0 or i >= obstacles.size() or i >= obstacle_hp.size() or obstacle_hp[i] < 0: return
	obstacle_hp[i] -= amount
	if obstacle_hp[i] > 0:
		effects.append({"p": obstacles[i].get_center(), "kind": "splinter", "life": 0.25, "max": 0.25})
		return
	var box: Rect2 = obstacles[i]
	var kind: String = obstacle_kinds[i]
	obstacles.remove_at(i); obstacle_kinds.remove_at(i); obstacle_hp.remove_at(i)
	ob_grid_count = -1
	var foot := Vector2(box.get_center().x, box.end.y)
	var debris := "debris_barrel" if kind.begins_with("barrel") else ("debris_sandbags" if kind.begins_with("sandbags") else "debris_crate")
	decor.append({"p": foot, "kind": debris, "small": true})
	effects.append({"p": foot, "kind": "prop_break", "life": 0.5, "max": 0.5, "prop": kind})
	if kind == "barrel_explosive":
		fuses.append({"p": box.get_center(), "t": BARREL_BLAST.fuse})
	elif kind.begins_with("crate") and rng.randf() < 0.3:
		pickups.append({"p": foot + Vector2(0, 10), "kind": "coin"})

func step_fuses(dt: float) -> void:
	var ready: Array = []
	for f in fuses:
		f.t -= dt
		if f.t <= 0: ready.append(f)
	fuses = fuses.filter(func(f): return f.t > 0)
	for f in ready: explode(f.p, BARREL_BLAST.radius, BARREL_BLAST.damage, true, true)

# ── Perigos do cenário ───────────────────────────────────────────────────────
func step_hazards(dt: float) -> void:
	for h in hazards:
		h["cd"] = maxf(0, h.get("cd", 0.0) - dt)
		for a in actors:
			if not a.active or a.dead: continue
			var d: Vector2 = a.p - h.p
			if Vector2(d.x, d.y * 1.5).length() < h.r:
				if a.jump > 0: continue   # saltar por cima escapa do tentáculo
				if h.cd <= 0:
					h.cd = 0.7
					effects.append({"p": h.p, "kind": "tentacle_strike", "life": 0.35, "max": 0.35, "dir": d.normalized() if d.length() > 1 else Vector2.RIGHT})
				damage_actor(a, h.get("damage", 12.0))
				a.p = move_body(a.p, (d.normalized() if d.length() > 1 else Vector2.DOWN) * 260 * dt, 23 if a.mech else 11)

func room_at(pos: Vector2) -> Dictionary:
	for room in rooms:
		if room.r.has_point(pos) and (room.kind != "secret" or secret_open): return room
	return {}

func spawn_enemy(pos: Vector2, kind: String, optional: bool = false) -> void:
	uid += 1
	# 0.11: inimigos mais resistentes (≈ +50% de vida) e o Almirante com 600.
	var hp: float = {"boss": 600.0, "brute": 95.0, "fish": 66.0, "crawler": 45.0, "crawler_small": 18.0}.get(kind, 52.0)
	if kind == "warden": hp = 420.0
	elif kind != "boss": hp *= 1.25
	enemies.append({"id": uid, "p": pos, "kind": kind, "hp": hp, "max": hp, "cd": rng.randf_range(0.5, 1.5), "phase": 0, "hurt": 0.0, "side": optional,
		"room": room_at(pos).get("id", "") if mode == "run" else "",
		"face": Vector2.DOWN, "moving": false, "shot": 0.0, "stage": 1, "charge": 0.0, "spin": 0.0, "spin_angle": 0.0, "step": 0.0,
		"fight_time": 0.0, "enraged": false})

func say(text: String) -> void:
	message = text; message_time = 5.0

func height_at(pos: Vector2) -> float:
	if mode != "run": return 0.0
	for ramp in ramps:
		if ramp.r.has_point(pos):
			var v: float = pos.x if ramp.axis == "x" else pos.y
			return clampf((v - ramp.low) / (ramp.high - ramp.low), 0, 1) * 44
	for area in raised:
		if area.has_point(pos): return 44.0
	return 0.0

func clear_at(pos: Vector2, radius: float, airborne: bool = false) -> bool:
	for off in [Vector2.ZERO, Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
		var found := false
		for floor_rect in floors:
			if floor_rect.has_point(pos + off): found = true; break
		if not found: return false
	if mode == "run" and not airborne:
		for gap in gaps:
			if gap.has_point(pos): return false
	if mode == "run":
		for i in obstacles_near(pos):
			if obstacles[i].grow(radius).has_point(pos): return false
	else:
		for box in obstacles:
			if box.grow(radius).has_point(pos): return false
	for gate in gate_blocks:
		if gate.grow(radius).has_point(pos): return false
	return true

func move_body(pos: Vector2, movement: Vector2, radius: float, airborne: bool = false) -> Vector2:
	# Small swept steps prevent jumping, dodging and large frame deltas tunnelling through walls.
	var count := maxi(1, int(ceil(movement.length() / 6.0)))
	var increment := movement / count
	for _i in range(count):
		var next := pos + Vector2(increment.x, 0)
		if clear_at(next, radius, airborne) and (airborne or absf(height_at(next) - height_at(pos)) < 8): pos = next
		next = pos + Vector2(0, increment.y)
		if clear_at(next, radius, airborne) and (airborne or absf(height_at(next) - height_at(pos)) < 8): pos = next
	return pos

func build_navigation() -> void:
	nav.clear(); nav_points.clear(); ai_path.clear(); ai_path_timer = 0
	# Grade só sobre os pisos (o mapa 0.11 é grande): 50px no mapa, 40px no refúgio/arena.
	var step := 50 if mode == "run" else 40
	var seen := {}
	for f in floors:
		for y in range(int(floor(f.position.y / step)) * step, int(f.end.y) + step, step):
			for x in range(int(floor(f.position.x / step)) * step, int(f.end.x) + step, step):
				var key := Vector2i(x, y)
				if seen.has(key): continue
				seen[key] = true
				if clear_at(Vector2(x, y), 15):
					var id := nav.get_available_point_id(); nav.add_point(id, Vector2(x, y)); nav_points[key] = id
	for p in nav_points:
		for off in [Vector2i(step, 0), Vector2i(0, step)]:
			var q: Vector2i = p + off
			if nav_points.has(q) and absf(height_at(Vector2(p)) - height_at(Vector2(q))) < 15:
				if clear_at((Vector2(p) + Vector2(q)) / 2, 15): nav.connect_points(nav_points[p], nav_points[q])

func path_direction(from: Vector2, to: Vector2) -> Vector2:
	if nav.get_point_count() == 0: return (to - from).normalized()
	if ai_path_timer <= 0 or ai_path.is_empty():
		ai_path_timer = 0.4
		ai_path = nav.get_point_path(nav.get_closest_point(from), nav.get_closest_point(to))
	while ai_path.size() > 1 and from.distance_to(ai_path[0]) < 30: ai_path.remove_at(0)
	return (ai_path[0] - from).normalized() if not ai_path.is_empty() else Vector2.ZERO

func nearest_enemy(pos: Vector2, distance: float = 600.0) -> Dictionary:
	var found: Dictionary = {}
	for e in enemies:
		var d: float = pos.distance_to(e.p)
		if d < distance: distance = d; found = e
	return found

func line_of_fire(from: Vector2, to: Vector2) -> bool:
	var count := maxi(1, int(from.distance_to(to) / 12.0))
	for n in range(1, count):
		if not clear_at(from.lerp(to, float(n) / count), 0, true): return false
	return true

func ai_input() -> Dictionary:
	var a: Dictionary = actors[1]
	var leader: Dictionary = actors[0]
	var target := nearest_enemy(a.p, 720)
	var delta_pos: Vector2 = leader.p - a.p
	var command := {"move": path_direction(a.p, leader.p) if delta_pos.length() > 100 else Vector2.ZERO, "aim": a.aim, "fire": false}
	if not target.is_empty():
		var delta_enemy: Vector2 = target.p - a.p
		command.aim = delta_enemy.normalized(); command.fire = line_of_fire(a.p, target.p)
		if not command.fire or delta_enemy.length() > 330:
			command.move = path_direction(a.p, target.p)
		elif delta_enemy.length() < 145: command.move = -delta_enemy.normalized()
		else: command.move = delta_enemy.normalized().orthogonal() * 0.55
		if delta_enemy.length() < 65: command.melee = true
		if not a.armor and a.armor_cd <= 0 and delta_enemy.length() < 300 and not a.mech: command.armor = true
		if a.mech and a.get("bomb_cd", 0.0) <= 0 and delta_enemy.length() > 180 and delta_enemy.length() < 380: command.armor = true
	for b in bullets:
		if b.team == 1 and a.p.distance_to(b.p) < 65:
			command.dodge = true; command.move = b.v.normalized().orthogonal(); break
	if leader.dead:
		command.move = path_direction(a.p, leader.p)
		if delta_pos.length() < 75: command.interact = true
	elif not a.mech and not a.fused and not target.is_empty() and mech.deployed and mech.occupant == -1 and mech.hp > 0 and a.p.distance_to(mech.p) < 220:
		command.move = (mech.p - a.p).normalized()
		if a.p.distance_to(mech.p) < 80: command.interact = true
	if leader.jump > 0: command.jump = true
	if mode == "run":
		for gap in gaps:
			if gap.grow(35).has_point(a.p): command.jump = true
	return command

func step(dt: float, commands: Array) -> void:
	tick_time += dt; message_time = maxf(0, message_time - dt)
	ai_path_timer -= dt
	for a in actors:
		if not a.active: continue
		var cmd: Dictionary = commands[a.id] if commands.size() > a.id else {}
		if a.id == 1 and coop == "ai": cmd = ai_input()
		step_actor(a, cmd, dt)
	# Bullets must advance in every scene, including the refuge and training arena.
	step_spectres(dt); step_enemies(dt); step_bullets(dt); collect_pickups()
	if mode == "arena":
		if enemies.is_empty():
			arena_wait += dt
			if arena_wait >= 2.0:
				arena_wait = 0; spawn_arena_wave(); say("ONDA " + str(arena_wave) + " • inimigos repostos / +1 coração")
		if actors.all(func(a): return a.dead): start_arena()
	if mode == "run":
		for a in actors:
			if a.active and not a.dead:
				var room := room_at(a.p)
				if not room.is_empty() and not visited.has(room.id): visited.append(room.id)
		step_gates(dt)
		step_hazards(dt)
		step_fuses(dt)
		if side_active:
			side_time -= dt
			if side_time <= 0:
				side_active = false; side_failed = true; say("Gerador perdido. A missão principal continua.")
			elif enemies.filter(func(e): return e.side).is_empty():
				side_active = false; side_complete = true; money += 25; keys += 2; materials += 1
				for a in actors: heal(a, 2)
				say("DESAFIO CONCLUÍDO • 2 chaves, 25 moedas, cura e 1 fragmento permanente!")
		if actors.all(func(a): return a.dead):
			make_hub(); say("A âncora temporal resgatou a equipe. Tente novamente.")
	for fx in effects: fx.life -= dt
	effects = effects.filter(func(fx): return fx.life > 0)

func step_actor(a: Dictionary, cmd: Dictionary, dt: float) -> void:
	for timer in ["shot", "slash", "hurt", "jump_cd", "dodge_cd", "interact_cd", "summon_cd", "snare", "fire_flash", "transform", "armor_cd", "combo_t", "bomb_cd"]:
		a[timer] = maxf(0, a.get(timer, 0.0) - dt)
	if a.dead: return
	if a.armor and a.get("transform", 0.0) <= 0:
		a.armor_time = maxf(0, a.armor_time - dt)
		if a.armor_time <= 0:
			set_armor(a, false); a.armor_cd = ARMORS[a.armor_type].cooldown
			say("A Armadura Ômega se desfez. Recarga: %ds." % int(a.armor_cd))
	if a.get("transform", 0.0) > 0:
		# Transformação: parado, invulnerável; a onda de choque sai no meio do efeito.
		var before: float = a.transform + dt
		if before > TRANSFORM_BURST and a.transform <= TRANSFORM_BURST: transform_burst(a)
		a.move = Vector2.ZERO
		if a.transform > 0.25: return
	if cmd.get("summon", false): summon_robot(a)
	if cmd.get("fusion", false): toggle_fusion(a)
	var moving: Vector2 = cmd.get("move", Vector2.ZERO)
	moving = moving.limit_length()
	var aim: Vector2 = cmd.get("aim", a.aim)
	if aim.length() > 0.1: a.aim = aim.normalized()
	if cmd.get("jump", false) and a.jump <= 0 and a.jump_cd <= 0 and not a.mech:
		a.jump = 0.65; a.jump_cd = 0.8; a["jump_from"] = a.p
	if cmd.get("dodge", false) and a.dodge_cd <= 0 and not a.mech:
		a.dodge = 0.20; a.dodge_cd = 0.3 if a.armor else uniform_of(a).dash_cd
		a.dash_dir = moving.normalized() if moving.length() > 0.1 else a.facing.normalized()
	var speed: float = 190.0 if a.mech else (ARMORS[a.armor_type].speed if a.armor else uniform_of(a).speed)
	if a.fused: speed = FUSION.speed
	if a.jump > 0: speed *= 1.12
	# Titan: pesado (190), mas Shift segura o TURBO dos propulsores enquanto houver energia.
	var boosting := false
	if a.mech:
		if cmd.get("boost", false) and a.boost > 0.02 and moving.length() > 0.1:
			boosting = true; speed = 420.0; a.boost = maxf(0, a.boost - dt / 2.4)
			if int(tick_time * 30) % 2 == 0: effects.append({"p": a.p - moving.normalized() * 30, "kind": "thrust", "life": 0.3, "max": 0.3, "dir": -moving.normalized()})
		else: a.boost = minf(1.0, a.boost + dt / 3.5)
		# 0.14: combustível — tanque vazio para o Titan no lugar (motor morre).
		var drain: float = (FUEL_MOVE if moving.length() > 0.1 else FUEL_IDLE) + (FUEL_BOOST if boosting else 0.0)
		mech.fuel = maxf(0, mech.fuel - drain * dt)
		if mech.fuel <= 0:
			speed = 0.0
			if not a.get("fuel_warned", false): a["fuel_warned"] = true; say("TITAN SEM GASOLINA • procure um galão nos baús.")
		elif mech.fuel < 20.0 and not a.get("fuel_warned", false): a["fuel_warned"] = true; say("Gasolina no fim • procure um galão nos baús.")
		elif mech.fuel >= 20.0: a["fuel_warned"] = false
	mech["boosting"] = boosting and a.mech
	if a.get("snare", 0.0) > 0 and not a.mech: speed *= 0.4  # preso pelo arpão
	if a.dodge > 0:
		speed = 900; moving = a.dash_dir; a.dodge = maxf(0, a.dodge - dt)
		effects.append({"p": a.p, "kind": "dash", "life": 0.16, "dir": moving})
	a.facing = a.aim  # corpo sempre virado para a mira: evita a arma "atravessar" o personagem quando o mouse aponta para trás
	a.move = moving
	a.p = move_body(a.p, moving * speed * dt, 23 if a.mech else 11, a.jump > 0)
	if moving.length() > 0.1:
		var before_step: float = a.step
		a.step += dt * ((9.0 if boosting else 5.0) if a.mech else 14.0)
		# pisada do Titan: poeira + tremor a cada pé que toca o chão
		if a.mech and int(a.step) != int(before_step) and int(a.step) % 2 == 1:
			effects.append({"p": a.p, "kind": "stomp", "life": 0.35, "max": 0.35})
	if a.jump > 0:
		a.jump = maxf(0, a.jump - dt)
		if a.jump == 0 and not clear_at(a.p, 10):
			# caiu na água: volta para onde saltou e perde meio coração
			a.p = a.get("jump_from", a.p); damage_actor(a, 12)
			effects.append({"p": a.p, "kind": "splash", "life": 0.5, "max": 0.5})
	if a.mech: mech.p = a.p; mech.aim = a.aim; mech.step = a.step; mech["facing"] = a.facing; mech["moving"] = a.move.length() > 0.1
	if a.armor and not a.mech:
		if (cmd.get("fire", false) or cmd.get("melee", false)) and a.shot <= 0: sword_attack(a)
	else:
		if cmd.get("fire", false) and a.shot <= 0 and not (a.mech and mech.fuel <= 0): fire_actor(a)
		if cmd.get("melee", false) and a.slash <= 0: melee(a)
	if cmd.get("interact", false) and a.interact_cd <= 0:
		a.interact_cd = 0.4; interact(a)
	if cmd.get("armor", false):
		if a.mech: throw_bomb(a)   # no Titan, R / LB lança uma bomba
		else: toggle_armor(a)

# ── Titan: canhão pesado, bombas e combustível (0.14) ─────────────────────────
# Canhão: projétil grande e lento que explode no impacto (dano em área).
const MECH_SHELL := {"damage": 70.0, "speed": 330.0, "radius": 14.0, "cooldown": 0.85, "splash": 80.0, "splash_damage": 34.0}
# Gasolina: o Titan só funciona pilotado enquanto houver fuel. Baús dão galões.
const FUEL_MAX := 100.0
const FUEL_IDLE := 0.15     # por segundo, parado pilotando
const FUEL_MOVE := 0.8      # por segundo, andando
const FUEL_BOOST := 1.6     # por segundo extra com o turbo
const FUEL_SHOT := 1.2      # por disparo do canhão pesado
const FUEL_BOMB := 4.0      # por bomba arremessada
const FUEL_PICKUP := 40.0   # galão de gasolina dos baús
const BATTERY_PICKUP := 50.0  # bateria: recarrega a energia do Spectre
# Bomba: arremessada em arco por cima de obstáculos, explode ao cair.
const MECH_BOMB := {"range": 320.0, "flight": 0.8, "radius": 125.0, "damage": 95.0, "cooldown": 2.6}

func throw_bomb(a: Dictionary) -> void:
	if a.get("bomb_cd", 0.0) > 0 or mech.fuel <= 0: return
	mech.fuel = maxf(0, mech.fuel - FUEL_BOMB)
	var target: Vector2 = a.p + a.aim * MECH_BOMB.range
	bullets.append({"p": a.p, "v": Vector2.ZERO, "team": 0, "damage": MECH_BOMB.damage, "r": 10.0, "life": MECH_BOMB.flight + 1.0,
		"owner": a.id, "kind": "bomb", "from": a.p, "to": target, "t": 0.0})
	a.bomb_cd = MECH_BOMB.cooldown
	effects.append({"p": a.p + a.aim * 30, "kind": "flash", "life": 0.1, "dir": a.aim})

func explode(p: Vector2, radius: float, damage: float, big: bool, hurts_all: bool = false) -> void:
	for e in enemies:
		var d: float = e.p.distance_to(p)
		if d < radius + (45 if e.kind == "boss" else 19) and line_of_fire(p, e.p):
			e.hp -= damage * (1.0 - 0.45 * clampf(d / radius, 0, 1)); e.hurt = 0.2; e["alerted"] = true
	if hurts_all:   # barril: atinge todo mundo (1 coração) e empurra
		for a in actors:
			if a.active and not a.dead and a.p.distance_to(p) < radius * 0.8:
				damage_actor(a, 20.0)
				var push: Vector2 = (a.p - p).normalized() if a.p.distance_to(p) > 1 else Vector2.DOWN
				a.p = move_body(a.p, push * 60, 23 if a.mech else 11)
	# props no raio quebram (e barris explosivos encadeiam)
	var hit: Array = []
	for i in obstacles.size():
		if i < obstacle_hp.size() and obstacle_hp[i] >= 0 and obstacles[i].get_center().distance_to(p) < radius + 20: hit.append(i)
	hit.reverse()
	for i in hit: damage_obstacle(i, damage)
	effects.append({"p": p, "kind": "explosion", "life": 0.55 if big else 0.4, "max": 0.55 if big else 0.4, "r": radius})

func step_bomb(b: Dictionary, dt: float) -> void:
	b.t += dt
	var k: float = clampf(b.t / MECH_BOMB.flight, 0, 1)
	b.p = b.from.lerp(b.to, k)
	if k >= 1.0:
		explode(b.p, MECH_BOMB.radius, b.damage, true); b.life = 0

func add_bullet(pos: Vector2, direction: Vector2, team: int, damage: float, speed: float, radius: float = 5.0, owner_id: int = -1, kind: String = "", life: float = 3.0) -> void:
	bullets.append({"p": pos, "v": direction * speed, "team": team, "damage": damage, "r": radius, "life": life, "owner": owner_id, "kind": kind})

func weapon_of(a: Dictionary) -> String:
	if a.mech: return "mech"
	if a.armor: return "omega_sword"
	return uniform_of(a).weapon

# 0.14: tabela única das armas — o jogo e a tela de Equipamento (loadout_stats) leem daqui.
const WEAPONS := {
	"pistol": {"count": 1, "damage": 16.0, "cooldown": 0.22, "speed": 660.0, "radius": 4.0, "spread": 0.12, "kind": "p_pistol", "pierce": 0},
	"shotgun": {"count": 6, "damage": 9.0, "cooldown": 0.65, "speed": 620.0, "radius": 4.0, "spread": 0.11, "kind": "p_pellet", "pierce": 0},
	"smg": {"count": 1, "damage": 7.0, "cooldown": 0.085, "speed": 740.0, "radius": 4.0, "spread": 0.12, "kind": "p_smg", "pierce": 0},
	# Canhão de Plasma Ômega: disparo duplo, perfurante.
	"omega": {"count": 2, "damage": 24.0, "cooldown": 0.2, "speed": 860.0, "radius": 7.0, "spread": 0.05, "kind": "p_omega", "pierce": 2}}
const SWORD := {"hit": 38.0, "finisher": 64.0, "wave": 30.0}   # Lâmina Ômega (3º corte + onda)
const MECH_PUNCH := 55.0
const SPECTRE_SHOT := {"damage": 9.0, "cooldown": 0.55}
const SPECTRE_HP := 100.0
const FUSION := {"damage": 1.35, "cadence": 0.8, "speed": 360.0}

func fire_actor(a: Dictionary) -> void:
	var weapon := weapon_of(a)
	var w: Dictionary = WEAPONS.get(weapon, WEAPONS.pistol)
	var count: int = w.count; var damage: float = w.damage; var cooldown: float = w.cooldown; var speed: float = w.speed
	var radius: float = w.radius; var spread: float = w.spread; var kind: String = w.kind; var pierce: int = w.pierce
	if weapon == "mech":
		count = 1; spread = 0.0; pierce = 0
		damage = MECH_SHELL.damage; cooldown = MECH_SHELL.cooldown; radius = MECH_SHELL.radius; speed = MECH_SHELL.speed; kind = "p_heavy"
		mech.fuel = maxf(0, mech.fuel - FUEL_SHOT)
	if a.fused: damage *= FUSION.damage; cooldown *= FUSION.cadence
	for n in range(count):
		var direction: Vector2 = a.aim.rotated((n - (count - 1) / 2.0) * spread)
		add_bullet(a.p + direction * (40 if a.mech else 34), direction, 0, damage, speed, radius, a.id, kind)
		bullets[-1]["pierce"] = pierce
		if weapon == "shotgun": bullets[-1].v *= rng.randf_range(0.85, 1.1)
	a.shot = cooldown; a["fire_flash"] = 0.09
	if a.mech: effects.append({"p": a.p + a.aim * 30, "kind": "flash", "life": 0.12, "dir": a.aim}); effects.append({"p": a.p, "kind": "recoil", "life": 0.2, "max": 0.2, "dir": a.aim})
	elif weapon in ["shotgun", "smg"]:
		effects.append({"p": a.p, "kind": "casing", "life": 0.5, "max": 0.5, "dir": a.aim.rotated(-PI / 2 if a.aim.x >= 0 else PI / 2), "seed": rng.randi() % 1000})

# Lâmina Ômega: combo de 3 cortes em arco. O 3º é mais largo e solta uma onda perfurante.
func sword_attack(a: Dictionary) -> void:
	if a.combo_t <= 0: a.combo = 0
	var hit: int = a.combo
	a.combo = (a.combo + 1) % 3; a.combo_t = 0.7
	var finisher := hit == 2
	var reach := 120.0 if finisher else 100.0
	var arc := 0.25 if finisher else 0.1   # produto escalar mínimo (≈ 150° / 170°)
	var damage: float = SWORD.finisher if finisher else SWORD.hit
	a.slash = 0.32; a.shot = 0.42 if finisher else 0.24; a.facing = a.aim
	a["swing"] = hit
	effects.append({"p": a.p, "kind": "sword", "life": 0.26, "max": 0.26, "dir": a.aim, "combo": hit, "owner": a.id})
	for e in enemies:
		var offset: Vector2 = e.p - a.p
		if offset.length() < reach + (30 if e.kind == "boss" else 0) and offset.normalized().dot(a.aim) > -arc:
			e.hp -= damage; e.hurt = 0.18
			effects.append({"p": e.p, "kind": "impact", "life": 0.2, "max": 0.2, "omega": true})
			if e.kind != "boss": e.p = move_body(e.p, offset.normalized() * (18 if finisher else 8), 14)
	for b in bullets:
		if b.team == 1 and a.p.distance_to(b.p) < reach:
			b.team = 0; b.v = a.aim * 560; b.damage = 18; b.kind = "p_omega"
	props_in_arc(a, reach, damage)
	if mode == "run" and a.p.distance_to(DOCKS.POINTS.secret_wall) < 125: open_secret()
	if finisher:
		add_bullet(a.p + a.aim * 40, a.aim, 0, SWORD.wave, 540, 16, a.id, "p_wave", 0.65)
		bullets[-1]["pierce"] = 5

func props_in_arc(a: Dictionary, reach: float, damage: float) -> void:
	if mode != "run": return
	var hit: Array = []
	for i in obstacles.size():
		var off: Vector2 = obstacles[i].get_center() - a.p
		if i < obstacle_hp.size() and obstacle_hp[i] >= 0 and off.length() < reach + 20 and off.normalized().dot(a.aim) > 0.1: hit.append(i)
	hit.reverse()
	for i in hit: damage_obstacle(i, damage)

func melee(a: Dictionary) -> void:
	a.slash = 0.65 if a.mech else 0.45
	var reach := 115.0 if a.mech else 78.0
	effects.append({"p": a.p, "kind": "slash", "life": 0.18, "dir": a.aim, "reach": reach})
	for e in enemies:
		var offset: Vector2 = e.p - a.p
		if offset.length() < reach and offset.normalized().dot(a.aim) > 0.05:
			e.hp -= MECH_PUNCH if a.mech else float(uniform_of(a).melee); e.hurt = 0.15
	props_in_arc(a, reach, 40.0 if a.mech else float(uniform_of(a).melee))
	# A clearly hinted crack opens with a close attack, never a consumable key.
	if mode == "run" and a.p.distance_to(DOCKS.POINTS.secret_wall) < 125:
		open_secret()
	if a.armor:
		for b in bullets:
			if b.team == 1 and a.p.distance_to(b.p) < reach:
				b.team = 0; b.v = a.aim * 550; b.damage = 16

func open_secret() -> void:
	if secret_open: return
	secret_open = true
	floors.append(DOCKS.SECRET_CORRIDOR)
	for room in rooms:
		if room.kind == "secret": floors.append(room.r)
	build_navigation()
	say("Passagem secreta revelada! Há um baú de contrabando.")

func interact(a: Dictionary) -> void:
	if a.mech:
		for offset in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 65), Vector2(0, -65)]:
			if clear_at(a.p + offset, 12):
				mech.occupant = -1; a.mech = false; a.p += offset; say("Desembarque. A máquina mantém os danos."); return
		say("Saída bloqueada."); return
	for other in actors:
		if other.active and other.id != a.id and other.dead and a.p.distance_to(other.p) < 75:
			other.dead = false; other.hp = HEART * 1.5; other.hurt = 2; say("Parceiro reanimado!"); return
	if mech.deployed and mech.hp > 0 and mech.occupant == -1 and not a.fused and a.p.distance_to(mech.p) < 90:
		if mech.fuel <= 0: say("Titan sem gasolina • abra os baús para achar um galão."); return
		mech.occupant = a.id; a.mech = true; a.p = mech.p; a["fuel_warned"] = false; say("TITAN-01 • Tiro: canhão pesado / R: bomba / Shift: turbo / E: sair • GASOLINA %.0f%%" % (mech.fuel / FUEL_MAX * 100)); return
	if mode == "hub":
		var point := hub_point_near(a.p)
		match point.get("id", ""):
			"portal":
				start_run(int(Time.get_ticks_msec()) % 999999); return
			"lost":
				say("Anel rachado, preso por correntes. Esta coordenada ainda não pode ser estabilizada."); return
			"core":
				say("Núcleo Temporal estável • expedições concluídas: %d • fragmentos: %d" % [clears, materials]); return
			"bench":
				say("Bancada: melhorias de vida em breve. Por enquanto todos começam com 3 corações.")
				return
			"armor":
				# Vitrine: troca o UNIFORME (Padrão → Mecânico → Espião). A armadura é o R.
				if a.armor: say("Com a armadura ativa não dá para trocar de uniforme nem de arma."); return
				a.outfit = OUTFITS[(OUTFITS.find(a.outfit) + 1) % OUTFITS.size()]
				say("Uniforme: " + UNIFORMS[a.outfit].name + " • " + UNIFORMS[a.outfit].desc.split("\n")[0] + "  (R veste a Armadura Ômega)"); return
			"mural":
				var photos := mini(clears, 4)
				if photos == 0: say("O mural da equipe perdida. Marty ainda não conseguiu trazer ninguém de volta.")
				else: say("Mural da equipe: %d/4 lembranças recuperadas." % photos)
				return
			"hangar":
				if not mech.deployed: say("Baia vazia • C invoca o Titan de volta.")
				else: say("Hangar do Titan • aproxime-se da máquina e pressione E para pilotar.")
				return
	elif mode == "run":
		for chest in chests:
			if not chest.open and a.p.distance_to(chest.p) < 65:
				if keys <= 0: say("Baú trancado: precisa de 1 chave."); return
				keys -= 1; chest.open = true; chest["t"] = tick_time; money += 10
				heal(a, 1); a.armor_cd = 0.0
				effects.append({"p": chest.p, "kind": "chest_burst", "life": 1.3, "max": 1.3, "secret": chest.secret})
				# 0.14: os baús sempre soltam um galão de gasolina e uma bateria ao lado.
				pickups.append({"p": chest.p + Vector2(46, 18), "kind": "fuel"})
				pickups.append({"p": chest.p + Vector2(-46, 18), "kind": "battery"})
				if chest.secret: materials += 1
				say("+10 moedas, +1 coração, ARMADURA (R), galão e bateria" + (" + fragmento!" if chest.secret else ".")); return
		if a.p.distance_to(DOCKS.POINTS.shop) < 110:
			if shop_bought: say("Comerciante: estoque esgotado nesta expedição.")
			elif money >= 15:
				money -= 15; keys += 1; heal(a, 2); shop_bought = true
				say("Comprou 1 chave e cura por 15 moedas.")
			else: say("Comerciante: chave + cura por 15 moedas.")
			return
		if a.p.distance_to(DOCKS.POINTS.side) < 110 and not side_active and not side_complete and not side_failed:
			side_active = true; side_time = 55
			var guards := [Vector2(-450, -300), Vector2(450, -300), Vector2(-500, 150), Vector2(500, 150), Vector2(-250, 380), Vector2(250, 380), Vector2(0, -330)]
			for n in range(7):
				var gp: Vector2 = DOCKS.POINTS.side + guards[n]
				if not clear_at(gp, 14): gp = DOCKS.POINTS.side + guards[n] * 0.7
				spawn_enemy(gp, "cult" if n % 2 == 0 else "brute", true)
			say("OPCIONAL • Elimine os 7 guardiões em 55s. Recompensa: chaves, cura e fragmento."); return
		if boss_dead and a.p.distance_to(DOCKS.POINTS.extraction) < 120:
			if not reward_claimed:
				reward_claimed = true; materials += 3; clears += 1; armor_unlocked = true
			make_hub(); say("Núcleo recuperado! Armadura permanente e 3 fragmentos. A equipe retornou."); return
	say("Aproxime-se de um portal, baú, parceiro caído, comerciante ou robô e pressione E.")

func damage_actor(a: Dictionary, amount: float) -> void:
	if a.hurt > 0 or a.dodge > 0 or a.dead or a.jump > 0 or a.get("transform", 0.0) > 0: return
	a.hurt = 0.45 if a.mech else HURT_IFRAMES
	if a.mech:
		mech.hp = maxf(0, mech.hp - amount)
		if mech.hp == 0:
			a.mech = false; mech.occupant = -1; a.hurt = 2
			say("Robô destruído! Ejeção de emergência ativada.")
	elif a.fused:
		var s: Dictionary = spectres[a.id]
		var overflow: float = maxf(0, amount - s.hp)
		s.hp = maxf(0, s.hp - amount)
		if s.hp <= 0:
			end_fusion(a); s.state = "destroyed"
			if overflow > 0: a.hp -= heart_damage(overflow)
			say("Spectre esgotado. Fusão encerrada.")
			if a.hp <= 0: a.hp = 0; a.dead = true
	else:
		var hit := heart_damage(amount * float(uniform_of(a).taken))
		if a.get("shield", 0.0) > 0:
			# Armadura Ômega: corações de escudo absorvem o golpe inteiro.
			a.shield = maxf(0, a.shield - hit)
			effects.append({"p": a.p, "kind": "shield_hit", "life": 0.3, "max": 0.3})
			if a.shield <= 0: say("Escudo Ômega quebrado!")
			return
		a.hp -= hit
		if a.hp <= 0: a.hp = 0; a.dead = true; say("Parceiro caído! Aproxime-se e pressione E para reanimar.")

# Inimigos das Docas de 1941 e o Almirante das Profundezas.
#   cult   Cultista Atirador      orbe magenta, distância média
#   fish   Arpoador das Profundezas  arpão lento e forte que prende (reduz a velocidade)
#   crawler Rastejante Tentacular ácido de curta distância; ao morrer vira duas bolhas menores
#   brute  Soldado Possuído       leque de balas violeta
func detection_range(a: Dictionary, base: float) -> float:
	# Disfarce de Londres: inimigos só notam Marty mais de perto.
	return base * 0.55 if outfit_of(a) == "espiao" and not a.mech else base

func step_enemies(dt: float) -> void:
	var spawned: Array = []
	for e in enemies:
		e.hurt = maxf(0, e.hurt - dt); e.shot = maxf(0, e.shot - dt); e.moving = false
		var target: Dictionary = {}; var closest := 99999.0
		# Linha de visão só é testada a cada 0,3s para quem ainda não foi alertado (mapa grande = muitos inimigos).
		var look := true
		if not e.get("alerted", false) and e.kind != "boss":
			e["los_t"] = e.get("los_t", 0.0) - dt
			if e.los_t > 0: look = false
			else: e.los_t = 0.3
		if not look: continue
		for a in actors:
			if not a.active or a.dead: continue
			var d: float = a.p.distance_to(e.p)
			var reach := detection_range(a, 900.0 if e.kind == "boss" else 700.0)
			if e.get("alerted", false): reach = maxf(reach, 640.0)
			if d < reach and d < closest and (e.get("alerted", false) or e.kind == "boss" or line_of_fire(e.p, a.p)): closest = d; target = a
		if target.is_empty(): continue
		e["alerted"] = true
		var direction: Vector2 = (target.p - e.p).normalized()
		e.face = direction
		if e.kind == "warden": step_warden(e, target, direction, closest, dt); continue
		if e.kind == "boss": step_boss(e, target, direction, closest, dt); continue
		var preferred: float = {"cult": 240.0, "fish": 210.0, "brute": 220.0, "crawler": 110.0, "crawler_small": 18.0}.get(e.kind, 120.0)
		var speed: float = {"cult": 100.0, "fish": 85.0, "brute": 95.0, "crawler": 140.0, "crawler_small": 170.0}.get(e.kind, 100.0)
		speed *= 1.2
		if closest > preferred:
			var before: Vector2 = e.p
			e.p = move_body(e.p, direction * speed * dt, 14)
			e.moving = e.p.distance_to(before) > 0.1; e.step += dt * 8
		e.cd -= dt
		if e.cd > 0: continue
		match e.kind:
			# 0.11: cadência ~40% maior, projéteis mais rápidos e mais fortes
			"cult":
				e.cd = 0.9; e.shot = 0.3
				add_bullet(e.p, direction, 1, 12, 240, 6, -1, "magenta")
				if rng.randf() < 0.35: add_bullet(e.p, direction.rotated(0.18), 1, 12, 240, 6, -1, "magenta")
			"fish":
				e.cd = 1.4; e.shot = 0.35
				add_bullet(e.p, direction, 1, 22, 320, 6, -1, "harpoon")
			"brute":
				e.cd = 1.2; e.shot = 0.35
				for n in range(6): add_bullet(e.p, direction.rotated((n - 2.5) * 0.12), 1, 9, 290, 5, -1, "violet")
			"crawler":
				e.cd = 0.8
				if closest < 220:
					e.shot = 0.3
					for n in range(3): add_bullet(e.p, direction.rotated((n - 1) * 0.28), 1, 9, 250, 6, -1, "acid", 0.9)
			"crawler_small":
				e.cd = 0.55
				if closest < 34: damage_actor(target, 8)
		e.cd *= 0.85
	for e in enemies:
		if e.hp > 0: continue
		money += 4
		pickups.append({"p": e.p, "kind": "coin"})
		if rng.randf() < 0.2: pickups.append({"p": e.p + Vector2(15, 0), "kind": "key"})
		effects.append({"p": e.p, "kind": "corpse", "enemy": e.kind, "life": 2.6 if e.kind == "boss" else 1.2, "max": 2.6 if e.kind == "boss" else 1.2, "flip": e.face.x < 0})
		if e.kind == "crawler":
			for off in [Vector2(-18, 6), Vector2(18, -6)]:
				if clear_at(e.p + off, 10): spawned.append([e.p + off, e.side])
		if e.kind == "boss": boss_dead = true; say("O Almirante afundou! Use o portal da arena para recuperar o núcleo e retornar.")
	enemies = enemies.filter(func(e): return e.hp > 0)
	for item in spawned: spawn_enemy(item[0], "crawler_small", item[1])

func step_warden(e: Dictionary, target: Dictionary, direction: Vector2, closest: float, dt: float) -> void:
	var state: String = e.get("attack_state", "hunt")
	e["attack_time"] = maxf(0, e.get("attack_time", 0.0) - dt)
	if state == "warning":
		e.face = e.charge_dir
		if e.attack_time <= 0: e.attack_state = "charge"; e.attack_time = 0.4
		return
	if state == "charge":
		e.face = e.charge_dir
		var before: Vector2 = e.p
		e.p = move_body(e.p, e.charge_dir * 850.0 * dt, 48)
		e.moving = true; e.step += dt * 18
		# Sweep contact along the actual collision-constrained movement.
		for a in actors:
			if a.active and not a.dead and Geometry2D.get_closest_point_to_segment(a.p, before, e.p).distance_to(a.p) < 62 and line_of_fire(e.p, a.p): damage_actor(a, 32)
		if e.attack_time <= 0 or e.p.distance_to(before) < 850.0 * dt * 0.8:
			e.attack_state = "recover"; e.attack_time = 0.9
		return
	if state == "recover":
		if e.attack_time <= 0: e.attack_state = "hunt"; e.cd = 0.45
		return
	e.cd -= dt
	if closest < 560 and e.cd <= 0 and line_of_fire(e.p, target.p):
		e["attack_state"] = "warning"; e.attack_time = 0.55; e["charge_dir"] = direction
		return
	var before: Vector2 = e.p
	e.p = move_body(e.p, direction * 300.0 * dt, 48)
	e.moving = e.p.distance_to(before) > 0.1; e.step += dt * 10

func enrage_scale(e: Dictionary) -> float:
	return BOSS_ENRAGE_SCALE if e.get("enraged", false) else 1.0

func step_boss(e: Dictionary, target: Dictionary, direction: Vector2, closest: float, dt: float) -> void:
	# Três estágios: a cada um o Almirante perde armas e o padrão de tiro muda.
	var ratio: float = e.hp / e.max
	var stage := 1 if ratio > 0.66 else (2 if ratio > 0.33 else 3)
	if stage > e.stage:
		e.stage = stage; e.cd = 1.2 * enrage_scale(e); e.spin = 0; e.charge = 0
		effects.append({"p": e.p + Vector2(60, -60), "kind": "weapon_drop", "life": 1.2, "max": 1.2})
		say("O Almirante larga a espingarda! Agora ele gira e carrega o canhão." if stage == 2 else "FÚRIA! O Almirante perdeu o chapéu: tinta, chamas e arpões!")
	# Enrage: sem timeout, uma equipe passiva podia travar a luta para sempre.
	e.fight_time += dt
	if not e.enraged and e.fight_time > BOSS_ENRAGE_TIME:
		e.enraged = true
		say("O Almirante entra em furor: os ataques ficam bem mais rápidos!")
	if e.charge > 0:
		e.charge -= dt
		if e.charge <= 0:
			e.shot = 0.4
			add_bullet(e.p + direction * 30, direction, 1, 24, 200, 13, -1, "cannon", 4.0)
		return
	if e.spin > 0:
		e.spin -= dt; e.cd -= dt
		if e.cd <= 0:
			e.cd = 0.11 * enrage_scale(e); e.spin_angle += 0.42
			for k in range(2 if stage == 2 else 3):
				add_bullet(e.p, Vector2.RIGHT.rotated(e.spin_angle + k * TAU / (2 if stage == 2 else 3)), 1, 10, 165, 6, -1, "orb")
		return
	e.cd -= dt
	if e.cd > 0: return
	e.phase += 1
	match stage:
		1:
			e.shot = 0.4; e.cd = 1.1 * enrage_scale(e)
			if e.phase % 2 == 1:
				for n in range(16): add_bullet(e.p, Vector2.RIGHT.rotated(n * TAU / 16 + e.phase * 0.2), 1, 12, 150, 7, -1, "orb")
			else:
				for n in range(7): add_bullet(e.p, direction.rotated((n - 3) * 0.14), 1, 10, 215, 6, -1, "orb")
		2:
			if e.phase % 3 == 0: e.charge = 0.9; e.cd = 1.0 * enrage_scale(e)
			else: e.spin = 2.2; e.cd = 0.0
		3:
			e.shot = 0.4; e.cd = 0.8 * enrage_scale(e)
			match e.phase % 3:
				0:
					for n in range(3): add_bullet(e.p, direction.rotated((n - 1) * 0.35), 1, 14, 115, 11, -1, "ink", 4.5)
				1:
					add_bullet(e.p, direction, 1, 18, 280, 6, -1, "harpoon")
					if closest < 260:
						for n in range(6): add_bullet(e.p + direction * 30, direction.rotated((n - 2.5) * 0.12), 1, 8, 280, 8, -1, "flame", 0.7)
				2:
					for n in range(20): add_bullet(e.p, Vector2.RIGHT.rotated(n * TAU / 20 + e.phase * 0.3), 1, 12, 175, 7, -1, "orb")

func step_bullets(dt: float) -> void:
	for b in bullets:
		b.life -= dt
		if b.get("kind", "") == "bomb": step_bomb(b, dt); continue
		var distance: float = b.v.length() * dt
		var count := maxi(1, int(ceil(distance / 5.0)))
		for _n in range(count):
			b.p += b.v * dt / count
			if not clear_at(b.p, 0, true):
				b.life = 0
				if mode == "run" and b.get("kind", "") != "p_heavy": damage_obstacle(obstacle_at(b.p), b.damage * (0.5 if b.team == 1 else 1.0))
				if b.get("kind", "") == "p_heavy": explode(b.p, MECH_SHELL.splash, MECH_SHELL.splash_damage, false)
				if b.team == 0: effects.append({"p": b.p, "kind": "impact", "life": 0.18, "max": 0.18, "omega": b.get("kind", "") == "p_omega"})
				break
			if b.team == 0:
				for e in enemies:
					if b.p.distance_to(e.p) < (48 if e.kind == "warden" else (45 if e.kind == "boss" else (12 if e.kind == "crawler_small" else 19))) + b.r:
						var hits: Array = b.get("hits", [])
						if hits.has(e.id): continue
						e.hp -= b.damage; e.hurt = 0.12; e["alerted"] = true
						if b.get("kind", "") == "p_heavy":
							hits = b.get("hits", []); hits.append(e.id)
							for other in enemies:   # respingo não repete o dano no alvo direto
								if not hits.has(other.id) and other.p.distance_to(b.p) < MECH_SHELL.splash + 19:
									other.hp -= MECH_SHELL.splash_damage; other.hurt = 0.15; other["alerted"] = true
							effects.append({"p": b.p, "kind": "explosion", "life": 0.4, "max": 0.4, "r": MECH_SHELL.splash})
						effects.append({"p": b.p, "kind": "impact", "life": 0.18, "max": 0.18, "omega": b.get("kind", "") == "p_omega"})
						if b.get("pierce", 0) > 0:
							b.pierce -= 1; hits.append(e.id); b["hits"] = hits
						else: b.life = 0
						break
			else:
				for s in spectres:
					if s.state == "following" and b.p.distance_to(s.p) < 15 + b.r:
						s.hp = maxf(0, s.hp - b.damage); b.life = 0
						if s.hp <= 0: s.state = "destroyed"
						break
				if b.life <= 0: break
				for a in actors:
					if not a.dead and b.p.distance_to(a.p) < (27 if a.mech else 11) + b.r:
						if a.jump > 0 or a.dodge > 0: continue
						damage_actor(a, b.damage); b.life = 0
						if b.get("kind", "") == "harpoon" and not a.mech: a.snare = 0.9
						break
			if b.life <= 0: break
	bullets = bullets.filter(func(b): return b.life > 0)

func collect_pickups() -> void:
	for pickup in pickups:
		for a in actors:
			if a.active and not a.dead and a.p.distance_to(pickup.p) < 32:
				if pickup.kind == "key": keys += 1
				elif pickup.kind == "fuel":
					mech.fuel = minf(FUEL_MAX, mech.fuel + FUEL_PICKUP); say("GALÃO DE GASOLINA • Titan +%.0f%% de combustível" % (FUEL_PICKUP / FUEL_MAX * 100))
				elif pickup.kind == "battery":
					var bs: Dictionary = spectres[a.id]
					if bs.hp <= 0: bs.state = "stored"   # bateria reanima um Spectre destruído
					bs.hp = minf(100.0, bs.hp + BATTERY_PICKUP); say("BATERIA • Spectre recarregado")
				else: money += 2
				pickup["taken"] = true; break
	pickups = pickups.filter(func(p): return not p.get("taken", false))

func equip(id: int, outfit: String, robot: String, armor_type: String = "omega") -> bool:
	if id < 0 or id >= actors.size() or not actors[id].active: return false
	if outfit not in OUTFITS or robot not in ["titan", "spectre"] or armor_type not in ARMORS: return false
	var a: Dictionary = actors[id]
	if a.dead: return false
	if a.fused and robot != a.selected_robot:
		say("Desfaça a fusão antes de trocar de robô."); return false
	if a.armor and outfit != a.outfit:
		say("Com a armadura ativa não dá para trocar de uniforme nem de arma."); return false
	a.outfit = outfit; a.selected_robot = robot
	if not a.armor: a.armor_type = armor_type
	return true

func free_summon_position(a: Dictionary, radius: float) -> Vector2:
	for distance in [100, 145, 190]:
		for n in range(8):
			var dir: Vector2 = a.facing.rotated(n * TAU / 8)
			var pos: Vector2 = a.p + dir * distance
			if clear_at(pos, radius) and line_of_fire(a.p, pos) and absf(height_at(pos) - height_at(a.p)) < 8:
				return pos
	return Vector2.INF

func summon_robot(a: Dictionary) -> bool:
	if not a.active or a.dead: return false
	if a.summon_cd > 0:
		say("Invocação recarregando: %.1fs" % a.summon_cd); return false
	if a.mech or a.fused:
		say("Saia do robô ou desfaça a fusão antes de invocar."); return false
	if a.selected_robot == "titan":
		if mech.occupant >= 0:
			say("Titan ocupado pelo parceiro."); return false
		if mech.hp <= 0:
			say("Titan destruído. Recuperação na próxima tentativa."); return false
		if mech.deployed and mech.owner == a.id and a.p.distance_to(mech.p) < 240:
			effects.append(SummonFX.recall_effect(a.id, a.p - Vector2(0, 30), mech.p, "titan"))
			mech.deployed = false; a.summon_cd = 3; say("Titan recolhido. Integridade preservada."); return true
		var titan_pos := free_summon_position(a, 28)
		if not titan_pos.is_finite(): say("Sem espaço livre para invocar o Titan."); return false
		mech.p = titan_pos; mech.deployed = true; mech.owner = a.id; mech.aim = a.aim; a.summon_cd = 6
		effects.append(SummonFX.summon_effect(a.id, a.p - Vector2(0, 30), titan_pos, "titan"))
		say("TITAN INVOCADO • aproxime-se e pressione E para pilotar."); return true
	var s: Dictionary = spectres[a.id]
	if s.hp <= 0: say("Spectre destruído. Recuperação na próxima tentativa."); return false
	if s.state == "following":
		effects.append(SummonFX.recall_effect(a.id, a.p - Vector2(0, 30), s.p, "spectre"))
		s.state = "stored"; a.summon_cd = 3; say("Spectre recolhido. Energia preservada."); return true
	var pos := free_summon_position(a, 14)
	if not pos.is_finite(): say("Sem espaço livre para invocar Spectre."); return false
	s.p = pos; s.state = "following"; a.summon_cd = 6
	effects.append(SummonFX.summon_effect(a.id, a.p - Vector2(0, 30), pos, "spectre"))
	say("SPECTRE INVOCADO • acompanha e atira. G para fundir / separar."); return true

func toggle_fusion(a: Dictionary) -> bool:
	if not a.active or a.dead: return false
	if a.fused:
		var pos := free_summon_position(a, 14)
		if not pos.is_finite(): say("Sem espaço para separar Spectre."); return false
		end_fusion(a); spectres[a.id].p = pos; spectres[a.id].state = "following"
		say("Fusão desfeita. Spectre voltou a acompanhar."); return true
	if a.mech: say("Saia do Titan antes de se fundir."); return false
	if a.armor or a.get("transform", 0.0) > 0: say("Espere a Ômega terminar antes de fundir Spectre."); return false
	var s: Dictionary = spectres[a.id]
	if s.state != "following" or s.hp <= 0:
		say("Selecione Spectre no equipamento e invoque com C antes de fundir."); return false
	if a.p.distance_to(s.p) > 240:
		say("Aproxime-se do Spectre para fundir."); return false
	a.fused = true; s.state = "fused"
	effects.append({"p": a.p, "kind": "summon", "life": 0.6, "dir": Vector2.UP})
	say("FUSÃO ATIVA • +velocidade e dano; energia do Spectre absorve impactos.")
	return true

func end_fusion(a: Dictionary) -> void:
	a.fused = false

func step_spectres(dt: float) -> void:
	for s in spectres:
		if s.state != "following": continue
		var owner_actor: Dictionary = actors[s.owner]
		if not owner_actor.active or owner_actor.dead: s.state = "stored"; continue
		var offset: Vector2 = owner_actor.p - s.p
		s["moving"] = offset.length() > 85
		if s.moving:
			s.aim = offset.normalized(); s["step"] = s.get("step", 0.0) + dt * 10
			# Small hover unit; collision still prevents moving through walls.
			s.p = move_body(s.p, offset.normalized() * minf(420, offset.length() * 3) * dt, 10, true)
		if offset.length() > 600:
			var pos := free_summon_position(owner_actor, 14)
			if pos.is_finite(): s.p = pos
		s.shot = maxf(0, s.shot - dt)
		var target := nearest_enemy(s.p, 520)
		if not target.is_empty() and line_of_fire(s.p, target.p):
			s.aim = (target.p - s.p).normalized()
			if s.shot <= 0:
				add_bullet(s.p + s.aim * 20, s.aim, 0, SPECTRE_SHOT.damage, 600, 4, s.owner)
				s.shot = SPECTRE_SHOT.cooldown

func snapshot() -> Dictionary:
	var data := {}
	data["spectres"] = spectres
	for name in ["actors", "enemies", "bullets", "pickups", "effects", "rooms", "floors", "obstacles", "chests", "mech", "seed_value", "mode", "money", "keys", "materials", "upgrade", "clears", "armor_unlocked", "side_active", "side_complete", "side_time", "side_failed", "boss_dead", "secret_open", "message", "message_time", "coop", "tick_time", "shop_bought", "arena_wave", "obstacle_kinds", "decor", "visited", "ramps", "raised", "gaps", "doors", "gate_blocks", "hazards", "obstacle_hp", "fuses"]:
		data[name] = get(name)
	return data

func apply_snapshot(data: Dictionary) -> void:
	for name in data: set(name, data[name])


# ── 0.14: números da tela de Equipamento, sempre calculados das mesmas constantes do jogo ──
# Cada linha: {label, valor exibido, fração 0..1 para a barra (-1 = sem barra), cor}
func loadout_stats(kind: String, outfit: String = "padrao") -> Array:
	var u: Dictionary = UNIFORMS.get(outfit, UNIFORMS.padrao)
	var rows: Array = []
	match kind:
		"omega":
			var ar: Dictionary = ARMORS.omega
			rows = [["CORAÇÕES", "%d + %d escudo" % [BASE_HEARTS, OMEGA_SHIELD_HEARTS], -1.0, "hearts_shield"],
				["VELOCIDADE", str(int(ar.speed)), ar.speed / 430.0, "cyan"],
				["LÂMINA", "%d / %d / %d" % [SWORD.hit, SWORD.hit, SWORD.finisher], SWORD.finisher / 70.0, "orange"],
				["ONDA", "%d (atravessa)" % SWORD.wave, SWORD.wave / 70.0, "gold"],
				["DURAÇÃO", "%ds" % int(ar.duration), ar.duration / 10.0, "green"],
				["RECARGA", "%ds" % int(ar.cooldown), 1.0 - ar.cooldown / 120.0, "violet"]]
		"titan":
			rows = [["INTEGRIDADE", str(int(new_mech(Vector2.ZERO).hp)), 1.0, "green"],
				["VELOCIDADE", "190 • turbo 420", 190.0 / 430.0, "cyan"],
				["CANHÃO", "%d + %d área" % [MECH_SHELL.damage, MECH_SHELL.splash_damage], MECH_SHELL.damage / 100.0, "orange"],
				["BOMBA (R)", "%d • raio %d" % [MECH_BOMB.damage, MECH_BOMB.radius], MECH_BOMB.damage / 100.0, "gold"],
				["SOCO", str(int(MECH_PUNCH)), MECH_PUNCH / 70.0, "orange"],
				["GASOLINA", "começa %d%%" % int(new_mech(Vector2.ZERO).fuel), new_mech(Vector2.ZERO).fuel / FUEL_MAX, "violet"]]
		"spectre":
			rows = [["ENERGIA", str(int(SPECTRE_HP)), 1.0, "green"],
				["TIRO", "%d a cada %.2fs" % [SPECTRE_SHOT.damage, SPECTRE_SHOT.cooldown], SPECTRE_SHOT.damage / 20.0, "gold"],
				["FUSÃO DANO", "+%d%%" % int(roundf((FUSION.damage - 1.0) * 100)), FUSION.damage - 1.0, "orange"],
				["FUSÃO RITMO", "+%d%%" % int(roundf((1.0 / FUSION.cadence - 1.0) * 100)), 1.0 / FUSION.cadence - 1.0, "violet"],
				["FUSÃO VELOC.", str(int(FUSION.speed)), FUSION.speed / 430.0, "cyan"],
				["ABSORVE", "golpes", -1.0, "cyan"]]
		_:
			var w: Dictionary = WEAPONS[u.weapon]
			var per_shot: float = w.damage * w.count
			var dps: float = per_shot / w.cooldown
			rows = [["CORAÇÕES", str(BASE_HEARTS), -1.0, "hearts"],
				["VELOCIDADE", str(int(u.speed)), u.speed / 430.0, "cyan"],
				["GOLPE", str(int(u.melee)), u.melee / 50.0, "orange"],
				["DANO / TIRO", ("%d×%d" % [w.count, w.damage]) if w.count > 1 else str(int(w.damage)), per_shot / 60.0, "gold"],
				["DANO / SEG", str(int(roundf(dps))), dps / 90.0, "gold"],
				["DEFESA", "%+d%%" % int(roundf((1.0 - u.taken) * 100)), clampf(0.5 + (1.0 - u.taken) * 2.5, 0, 1), "green"],
				["DASH", "%.2fs" % u.dash_cd, clampf(0.35 / u.dash_cd, 0, 1), "violet"]]
	return rows
