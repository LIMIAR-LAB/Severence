class_name Expedition
extends RefCounted
const DOCKS := preload("res://scripts/docks_map.gd")  # não depende do cache de class_name
const SummonFX = preload("res://scripts/summon_fx.gd")
const EquipmentData := preload("res://scripts/equipment_data.gd")
const InventoryState := preload("res://scripts/inventory_state.gd")
const InventoryData := preload("res://scripts/inventory_data.gd")

# All gameplay state is serializable. Only the host advances simulation.
var actors: Array = []
var enemies: Array = []
var bullets: Array = []
# 0.18: ameaças temporárias autoritativas, nunca gravadas na geometria do mapa.
var combat_zones: Array = []
var harpoons: Array = []
const ATTACK_LIMIT := 3
const ATTACK_WARNING := 0.55
const GUARD_WARNING := 1.1  # 0.20: preparação lenta, com escudo ainda erguido.
const GUARD_ATTACK_TIME := 2.4
const GUARD_SHOT_INTERVAL := 0.48
const GUARD_SHOTS := 5
const MAX_COMBAT_ZONES := 64
var pickups: Array = []
var effects: Array = []
var visible_world_rect := Rect2()
# Host-authored transient sound cues; presentation never consumes gameplay RNG.
const MAX_AUDIO_EVENTS := 64
var audio_events: Array = []
var audio_sequence := 0
var rooms: Array = []
var floors: Array = []
var obstacles: Array = []
var chests: Array = []
# 0.17: missão compartilhada pela equipe; salva e sincronizada.
var story_quest := 0
var dialogue_queue: Array = []
const STORY_NPC := Vector2(1160, 4740)
var mech: Dictionary = {}
var rng := RandomNumberGenerator.new()
var seed_value := 1
var mode := "hub"
var message := ""
var message_time := 0.0
var money := 0
var keys := 0
var materials := 0
var run_materials_start := 0
var upgrade := 0
var clears := 0
var armor_unlocked := false
# 0.17: itens de equipamento liberados (id -> true). Sozinha, a simulação é um "sandbox" com tudo
# liberado (testes, arena); o jogo (main.gd) troca pelo estado do save — jogo novo = só o Padrão.
var unlocked: Dictionary = {"padrao": true, "mecanico": true, "espiao": true, "omega": true, "titan": true, "spectre": true}
var new_unlocks: Array = []   # desbloqueados nesta sessão ainda não salvos (main.gd salva e limpa)
var inventory_state: Dictionary = InventoryState.defaults()
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
var tentacle_gates: Array = []  # 0.16: poças que bloqueiam um corredor até um evento (DOCKS.TENTACLE_GATES)
var nav := AStar2D.new()
var nav_points: Dictionary = {}
var ai_path := PackedVector2Array()
var ai_path_timer := 0.0
var arena_wave := 0
var arena_wait := 0.0
var pending_spawns: Array = []   # 0.15: inimigos aguardando o portal da arena terminar
var spectres: Array = []
var obstacle_hp: Array = []      # 0.13: vida de cada obstáculo (-1 = indestrutível)
var fuses: Array = []            # barris explosivos prestes a estourar (reação em cadeia)
var hitstop := 0.0               # 0.15: micro-pausa em golpes fortes (main.gd aplica Engine.time_scale)
var clutch_t := 0.0              # 0.15: slow-mo quando o jogador fica com meio coração
var clutch_cd := 0.0
var streak := 0                  # 0.15: abates em sequência — bônus de moedas
var streak_t := 0.0
# Resumo da expedição: telemetria da run atual e último resultado imutável.
var run_stats: Dictionary = {}
var last_run_summary: Dictionary = {}
var summary_seq := 0
var ob_grid: Dictionary = {}     # grade espacial dos obstáculos (mapa grande = muitos props)
var ob_grid_count := -1

func _init() -> void:
	make_hub()

func emit_audio(key: String, p: Vector2) -> void:
	audio_sequence += 1
	audio_events.append({"id": audio_sequence, "key": key, "p": p, "time": tick_time})
	if audio_events.size() > MAX_AUDIO_EVENTS: audio_events.pop_front()

func actor(id: int, pos: Vector2) -> Dictionary:
	return {"id": id, "active": id == 0 or coop != "solo", "p": pos, "aim": Vector2.RIGHT, "facing": Vector2.DOWN, "dash_dir": Vector2.RIGHT, "move": Vector2.ZERO, "hp": BASE_HEARTS * HEART, "shield": 0.0, "armor": false,
		"jump": 0.0, "jump_cd": 0.0, "shot": 0.0, "slash": 0.0, "dodge": 0.0, "roll_visual": 0.0, "dodge_cd": 0.0,
		"hurt": 0.0, "step": 0.0, "mech": false, "dead": id == 1 and coop == "solo", "gun": 0, "interact_cd": 0.0, "revive": 0.0,
		"selected_robot": default_robot(), "summon_cd": 0.0, "fused": false, "armor_before_fusion": false,
		"outfit": "mecanico" if id == 1 and is_unlocked("mecanico") else "padrao", "snare": 0.0, "fire_flash": 0.0, "transform": 0.0,
		"armor_type": "omega", "armor_time": 0.0, "armor_cd": 0.0, "beam_time": 0.0, "beam_cd": 0.0, "beam_end": pos, "bomb_cd": 0.0, "combo": 0, "combo_t": 0.0, "boost": 1.0,
		"last_damage_source": "unknown", "last_damage_attack": "", "run_weapons": {}, "run_weapon": ""}

func fresh_run_stats() -> Dictionary:
	return {"kills": 0, "kills_by_kind": {}, "damage_dealt": 0.0, "damage_received": 0.0,
		"max_streak": 0, "chests_opened": 0, "revives": 0, "fatal_source": "unknown", "fatal_attack": ""}

func ensure_run_stats() -> void:
	if run_stats.is_empty(): run_stats = fresh_run_stats()

func hurt_enemy(enemy: Dictionary, amount: float, credit_player: bool = true) -> void:
	var before := maxf(0.0, float(enemy.get("hp", 0.0)))
	enemy.hp -= amount
	if mode == "run" and credit_player:
		ensure_run_stats()
		run_stats.damage_dealt += minf(before, maxf(0.0, amount))

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
	"omega": {"name": "ARMADURA ÔMEGA", "duration": 300.0, "cooldown": 60.0, "speed": 430.0, "taken": 1.0,
		"desc": "LENDÁRIA • dura 5 min, recarrega 60s (R).\nComeça cada expedição carregada; baús recarregam na hora.\nLâmina Ômega: combo de 3 cortes (38/38/64);\no 3º solta uma onda que atravessa inimigos.\nSegure T: raio de luz por até 3s; recarga de 30s.\nAo guardar, luz atinge inimigos próximos visíveis.\n+3 CORAÇÕES DE ESCUDO • MUITO mais rápido (430) • corte reflete tiros.\nUniforme e arma não mudam enquanto ativa."}}
const OUTFIT_NAMES := {"padrao": "PADRÃO", "mecanico": "MECÂNICO", "espiao": "ESPIÃO", "omega": "ARMADURA ÔMEGA"}

# Enrage do Almirante: sem isso a luta podia travar indefinidamente contra um time passivo.
# Depois de BOSS_ENRAGE_TIME segundos de combate ativo, os cooldowns de ataque encolhem por BOSS_ENRAGE_SCALE.
const BOSS_ENRAGE_TIME := 150.0
const BOSS_ENRAGE_SCALE := 0.6

# ── Inimigos especiais e ondas temáticas (0.15) ──────────────────────────────
const BOMBER_BLAST := {"radius": 90.0, "damage": 22.0, "trigger": 40.0}
const ARENA_SPAWN_DELAY := 0.8
const ARENA_HP_PER_WAVE := 0.15
const ARENA_DAMAGE_PER_WAVE := 0.04
const KEY_DROP_CHANCE := 0.04   # 0.21: chaves devem exigir escolha nos baús.
const AMMO_DROP_CHANCE := 0.06  # Foguetes são suprimento raro durante a RUN.

# ── Vida em corações (0.12) ─────────────────────────────────────────────────
# 1 coração = 10 de vida. Marty começa com 3. Golpe comum tira meio coração; golpe pesado
# (arpão, bala de canhão: dano ≥ 20 depois do uniforme) tira um coração inteiro.
const HEART := 10.0
const BASE_HEARTS := 3
const HURT_IFRAMES := 0.9
const OMEGA_SHIELD_HEARTS := 3
const OMEGA_BEAM_DURATION := 3.0
const OMEGA_BEAM_COOLDOWN := 30.0
const OMEGA_BEAM_RANGE := 620.0
const OMEGA_BEAM_DAMAGE := 90.0
const OMEGA_RECALL_RANGE := 520.0
const OMEGA_RECALL_DAMAGE := 40.0

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
	if not is_unlocked(a.armor_type): say("Nenhuma armadura desbloqueada ainda."); return
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
		if a.beam_time > 0: stop_omega_beam(a)
		recall_light(a)
		effects.append({"p": a.p, "kind": "power_down", "life": 0.45, "max": 0.45})

func stop_omega_beam(a: Dictionary) -> void:
	a.beam_time = 0.0
	a.beam_cd = OMEGA_BEAM_COOLDOWN

func omega_beam_endpoint(from: Vector2, direction: Vector2) -> Vector2:
	var end := from + direction * OMEGA_BEAM_RANGE
	for n in range(1, int(OMEGA_BEAM_RANGE / 10.0) + 1):
		var point := from + direction * (n * 10.0)
		if not clear_at(point, 0.0, true): return from + direction * ((n - 1) * 10.0)
	return end

func recall_light(a: Dictionary) -> void:
	var screen := visible_world_rect if visible_world_rect.has_area() else Rect2(a.p - Vector2(640, 400), Vector2(1280, 800))
	for e in enemies:
		if e.hp <= 0 or e.p.distance_to(a.p) > OMEGA_RECALL_RANGE or not screen.has_point(e.p) or not line_of_fire(a.p, e.p): continue
		hurt_enemy(e, OMEGA_RECALL_DAMAGE); e.hurt = 0.2; e.alerted = true
		pop_dmg(e.p, OMEGA_RECALL_DAMAGE, true)
		effects.append({"p": a.p, "to": e.p, "kind": "recall_light", "life": 0.42, "max": 0.42})

func transform_burst(a: Dictionary) -> void:
	effects.append({"p": a.p, "kind": "shockwave", "life": 0.55, "max": 0.55})
	for e in enemies:
		var d: float = e.p.distance_to(a.p)
		if d < 190:
			hurt_enemy(e, 40.0 if e.kind != "boss" else 25.0); e.hurt = 0.2
			if e.kind != "boss": e.p = move_body(e.p, (e.p - a.p).normalized() * (190 - d) * 0.6, 14)
	for b in bullets:
		if b.team == 1 and b.p.distance_to(a.p) < 240: b.life = 0

func outfit_of(a: Dictionary) -> String:
	return "omega" if a.armor else a.get("outfit", "padrao")

func new_mech(pos: Vector2) -> Dictionary:
	# 0.14: o Titan consome gasolina enquanto pilotado — começa com tanque parcial.
	return {"p": pos, "hp": 240.0, "fuel": 70.0, "occupant": -1, "aim": Vector2.RIGHT, "move_dir": Vector2.DOWN,
		"step": 0.0, "deployed": true, "owner": -1}

func reset_spectres() -> void:
	spectres = []
	for a in actors:
		spectres.append({"owner": a.id, "state": "stored", "hp": SPECTRE_HP, "p": a.p, "aim": Vector2.RIGHT,
			"move_dir": Vector2.DOWN, "shot": 0.0})

# Refúgio • Fora do Tempo — coordenadas iguais às de assets/environment/refuge/refuge_bg.png (1344x752).
# Pisos e obstáculos são colisores invisíveis sobre a arte pintada.
const HUB_SIZE := Vector2(1344, 752)
const HUB_POINTS := [
	{"id": "portal", "p": Vector2(655, 215), "r": 80, "label": "E • DOCAS / 1941"},
	{"id": "lost", "p": Vector2(965, 275), "r": 85, "label": "COORDENADA PERDIDA • BLOQUEADO"},
	{"id": "core", "p": Vector2(640, 455), "r": 70, "label": "E • NÚCLEO TEMPORAL"},
	{"id": "bench", "p": Vector2(330, 335), "r": 85, "label": "E • BANCADA (em breve)"},
	{"id": "armor", "p": Vector2(265, 580), "r": 85, "label": "E • CONSULTAR EQUIPAMENTO"},
	{"id": "mural", "p": Vector2(672, 478), "r": 55, "label": "E • MURAL DA EQUIPE"},
	{"id": "hangar", "p": Vector2(1000, 545), "r": 70, "label": "HANGAR DO TITAN"}]
const HUB_TITAN_BAY := Vector2(1140, 548)

func make_hub() -> void:
	audio_events.clear()
	doors.clear(); gate_blocks.clear(); hazards.clear(); tentacle_gates.clear()
	mode = "hub"
	money = 0; keys = 0  # 0.21: moeda e chaves não atravessam o portal temporal.
	pending_spawns.clear()   # 0.15: portais atrasados da arena não atravessam para o Refúgio
	actors = [actor(0, Vector2(760, 440)), actor(1, Vector2(820, 450))]
	combat_zones.clear(); harpoons.clear(); enemies.clear(); bullets.clear(); pickups.clear(); effects.clear(); obstacles.clear(); chests.clear(); obstacle_kinds.clear(); obstacle_hp.clear(); fuses.clear()
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
	mech = new_mech(HUB_TITAN_BAY); mech.aim = Vector2.DOWN; apply_unlock_state()
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
	audio_events.clear()
	mode = "arena"; tick_time = 0; arena_wave = 0; arena_wait = 0
	pending_spawns.clear()
	side_active = false; side_complete = false; side_failed = false; side_time = 0
	actors = [actor(0, Vector2(400, 600)), actor(1, Vector2(470, 650))]
	combat_zones.clear(); harpoons.clear(); enemies.clear(); bullets.clear(); pickups.clear(); effects.clear(); obstacles.clear(); chests.clear(); obstacle_kinds.clear(); obstacle_hp.clear(); fuses.clear()
	floors = [Rect2(80, 100, 1120, 820)]
	rooms = [{"r": floors[0], "name": "ARENA DE TESTE • ONDAS / DASH / ROBÔ", "kind": "arena"}]
	mech = new_mech(Vector2(250, 800)); money = 0; keys = 0; apply_unlock_state()
	reset_spectres()
	doors.clear(); gate_blocks.clear(); hazards.clear(); tentacle_gates.clear()
	build_navigation(); spawn_arena_wave()
	say("TESTE IMEDIATO • inimigos à direita • Shift: DASH • F: golpe • R: armadura • E: robô")

func spawn_arena_wave() -> void:
	arena_wave += 1
	if arena_wave == 1: pending_spawns.clear()
	var kinds: Array = []
	if arena_wave <= 2:
		for n in range(4 + arena_wave): kinds.append(["cult", "fish", "crawler"][n % 3])
	elif arena_wave == 3:
		for n in range(10): kinds.append("crawler_small")
	elif arena_wave == 4:
		kinds = ["brute", "brute", "bomber", "cult", "fish"]
	else:
		var count := 6 + mini(arena_wave - 5, 5)
		for n in range(count): kinds.append(["cult", "fish", "crawler", "brute", "bomber"][n % 5])
		if (arena_wave - 5) % 4 == 0: kinds.append("warden")
	var hp_scale := 1.0 + arena_wave * ARENA_HP_PER_WAVE
	var damage_scale := 1.0 + arena_wave * ARENA_DAMAGE_PER_WAVE
	for n in range(kinds.size()):
		var pos := Vector2(800 + (n % 3) * 120, 260 + floorf(float(n) / 3) * 155)
		pending_spawns.append({"p": pos, "kind": kinds[n], "timer": ARENA_SPAWN_DELAY, "hp_scale": hp_scale, "damage_scale": damage_scale})
		effects.append({"p": pos, "kind": "spawn_portal", "life": ARENA_SPAWN_DELAY, "max": ARENA_SPAWN_DELAY})
	for a in actors:
		if not a.dead: heal(a, 1)

func start_run(new_seed: int) -> void:
	audio_events.clear()
	# Mapa fixo (scripts/docks_map.gd). A seed só sorteia os tipos de inimigo e pequenos desvios.
	pending_spawns.clear()   # 0.15: nenhuma onda da arena pode vazar para uma expedição
	seed_value = new_seed; rng.seed = seed_value
	run_stats = fresh_run_stats(); last_run_summary = {}
	mode = "run"; tick_time = 0; money = 12; keys = 1; run_materials_start = materials
	streak = 0; streak_t = 0.0; hitstop = 0.0; clutch_t = 0.0; clutch_cd = 0.0
	side_active = false; side_complete = false; side_failed = false; shop_bought = false
	boss_dead = false; secret_open = false; reward_claimed = false
	var P: Dictionary = DOCKS.POINTS
	actors = [actor(0, P.spawn), actor(1, P.spawn2)]
	for a in actors:
		a.hp = max_hp(); a.shield = 0.0; a.armor = false; a.armor_cd = 0.0  # começa pronta para vestir
	combat_zones.clear(); harpoons.clear(); enemies.clear(); bullets.clear(); pickups.clear(); effects.clear(); obstacles.clear(); chests.clear(); obstacle_kinds.clear(); decor.clear(); visited.clear()
	rooms = []
	for room in DOCKS.ROOMS: rooms.append(room.duplicate())
	floors = []
	for room in rooms:
		if room.kind != "secret":
			floors.append(room.r)
			floors.append_array(room.get("extra", []))   # 0.17: alas/alcovas da sala
	floors.append_array(DOCKS.EXTRA_FLOORS); floors.append_array(DOCKS.CORRIDORS)
	for sc in DOCKS.SHORTCUTS: floors.append(sc.r)   # 0.16: atalhos (fechados pela parede rachada)
	raised = DOCKS.RAISED.duplicate(); ramps = DOCKS.RAMPS.duplicate(true); gaps = DOCKS.GAPS.duplicate()
	jump_gap = gaps[0]
	build_doors(); hazards = DOCKS.HAZARDS.duplicate(true)
	obstacle_hp.clear(); fuses.clear()
	for o in DOCKS.OBSTACLES:
		obstacles.append(Rect2(o[0], o[1], o[2], o[3])); obstacle_kinds.append(o[4]); obstacle_hp.append(DESTRUCTIBLE.get(o[4], -1.0))
	# 0.16: parede rachada A, B ou C em cada atalho (sorteada pela seed, sem mexer no rng dos inimigos)
	for i in DOCKS.SHORTCUTS.size():
		obstacles.append(DOCKS.SHORTCUTS[i].wall); obstacle_kinds.append("wall_crack_" + ["a", "b", "c"][posmod(seed_value * 31 + i * 17, 3)]); obstacle_hp.append(-1.0)
	tentacle_gates = DOCKS.TENTACLE_GATES.duplicate(true)
	for g in tentacle_gates: g["sealed"] = false; g["cd"] = 0.0
	for d in DOCKS.DECOR:
		var item := {"p": Vector2(d[0], d[1]), "kind": d[2]}
		if d.size() > 3: item.merge(d[3])
		decor.append(item)
	for c in DOCKS.CHESTS: chests.append({"p": Vector2(c[0], c[1]), "open": false, "secret": c[2]})
	mech = new_mech(P.mech); apply_unlock_state()
	reset_spectres()
	for sp in DOCKS.SPAWNS:

		var pos := Vector2(sp[0], sp[1]) + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
		if not clear_at(pos, 16): pos = Vector2(sp[0], sp[1])
		spawn_enemy(pos, sp[2])
	spawn_enemy(P.boss, "boss")
	spawn_enemy(P.warden, "warden")
	pickups.append({"p": P.key, "kind": "key"})
	pickups.append({"p": P.spawn + Vector2(165, 0), "kind": "weapon", "weapon": "bazooka", "ammo": 6})
	build_navigation()
	say("Docas de 1941 • recupere o núcleo do Almirante. TAB/M abre o mapa. Armadura Ômega pronta.")

func run_progress_percent(outcome: String = "") -> int:
	var discoverable := rooms.filter(func(room): return room.get("kind", "") != "secret")
	var visited_discoverable := 0
	for room in discoverable:
		if visited.has(room.id): visited_discoverable += 1
	var room_part := 0.0 if discoverable.is_empty() else clampf(float(visited_discoverable) / float(discoverable.size()), 0.0, 1.0) * 80.0
	var objective_part := (10.0 if boss_dead else 0.0) + (10.0 if outcome == "victory" else 0.0)
	return 100 if outcome == "victory" else clampi(int(round(room_part + objective_part)), 0, 99)

func run_grade(outcome: String, progress: int) -> String:
	ensure_run_stats()
	var score := float(progress) + minf(float(run_stats.kills), 50.0) * 0.4
	# Até 12 pontos por eficiência; o bônus se esgota após 24 minutos.
	score += clampf(12.0 - tick_time / 120.0, 0.0, 12.0)
	if side_complete: score += 10.0
	if secret_open: score += 5.0
	if outcome == "victory": score += 20.0
	if score >= 130.0: return "S"
	if score >= 105.0: return "A"
	if score >= 80.0: return "B"
	if score >= 55.0: return "C"
	return "D"

func obituary_for(source: String, attack: String = "") -> String:
	var lines := {
		"fish": ["O peixe mutante arrancou os seus olhos e comeu igual jujuba.", "O peixe mutante provou que arpões também funcionam fora d'água."],
		"crawler": ["Virou almoço de uma coisa com tentáculos demais e educação de menos."],
		"crawler_small": ["Foi vencido por um tentáculo do tamanho de um cachecol."],
		"brute": ["Tentou discutir estratégia com um soldado possuído. Ele preferiu violência."],
		"bomber": ["Abraçou a explosão. A explosão não estava emocionalmente disponível."],
		"warden": ["O Guardião carimbou sua passagem só de ida para o Refúgio."],
		"boss": ["O Almirante promoveu Marty ao posto de decoração submarina."],
		"hazard": ["Ignorou uma poça suspeita em 1941. A poça venceu."],
		"water": ["Caiu nas docas e descobriu que armadura pesada não é boia."],
		"explosion": ["Tentou abraçar uma explosão. O sentimento não era recíproco."],
		"unknown": ["A linha do tempo se recusa a explicar o que aconteceu aqui."]}
	var choices: Array = lines.get(source, lines.unknown)
	var key := "%d:%s:%s" % [seed_value, source, attack]
	return str(choices[posmod(key.hash(), choices.size())])

func finish_run(outcome: String) -> Dictionary:
	if mode != "run": return last_run_summary
	ensure_run_stats()
	var fatal_source := str(run_stats.get("fatal_source", "unknown"))
	var fatal_attack := str(run_stats.get("fatal_attack", ""))
	var progress := run_progress_percent(outcome)
	last_run_summary = {
		"outcome": outcome, "seed": seed_value, "time": tick_time, "progress": progress,
		"kills": int(run_stats.kills), "kills_by_kind": run_stats.kills_by_kind.duplicate(true),
		"damage_dealt": int(round(float(run_stats.damage_dealt))), "damage_received": int(round(float(run_stats.damage_received))),
		"max_streak": int(run_stats.max_streak), "chests": int(run_stats.chests_opened),
		"scrap": maxi(0, money - 12), "fragments": maxi(0, materials - run_materials_start),
		"nucleus": 1 if outcome == "victory" else 0, "clears": clears,
		"side_complete": side_complete, "secret_open": secret_open, "boss_dead": boss_dead,
		"grade": run_grade(outcome, progress), "fatal_source": fatal_source, "fatal_attack": fatal_attack,
		"obituary": "Núcleo recuperado. O tempo perdeu esta rodada." if outcome == "victory" else obituary_for(fatal_source, fatal_attack)
	}.duplicate(true)
	summary_seq += 1
	make_hub()
	return last_run_summary

# ── Portões (0.12) ───────────────────────────────────────────────────────────
# Cada ponta de corredor que encosta numa sala vira um portão. Ao entrar numa sala com inimigos,
# todos os portões dela fecham até o último inimigo daquela sala cair (estilo Enter the Gungeon).
const DOOR_DEPTH := 36.0

func build_doors() -> void:
	doors.clear(); gate_blocks.clear()
	for room in rooms:
		if not room.has("id") or room.kind == "secret": continue
		# 0.19: saídas também nas alas das salas compostas.
		for r: Rect2 in [room.r] + room.get("extra", []):
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

func room_contains(room: Dictionary, p: Vector2, margin: float = 0.0) -> bool:
	# 0.19: alcovas estreitas não podem gerar Rect2 negativo ao testar margem interna.
	for rect: Rect2 in [room.r] + room.get("extra", []):
		var inner := rect.grow(margin)
		if inner.size.x > 0 and inner.size.y > 0 and inner.has_point(p): return true
	return false

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

func step_gates(_step_dt: float = 0.016) -> void:
	var changed := false
	for room in rooms:
		if not room.has("id") or room.kind == "secret": continue
		if room.get("locked", false):
			if room_threats(room.id) == 0:
				room.locked = false; room.cleared = true; changed = true
				say("SALA LIMPA • os portões se abriram!")
				for d in doors:
					if d.room == room.id: effects.append({"p": d.r.get_center(), "kind": "gate_open", "life": 0.8, "max": 0.8})
		elif not room.get("cleared", false):
			var inside: Dictionary = {}
			for a in actors:
				if a.active and not a.dead and room_contains(room, a.p, -50): inside = a; break
			if inside.is_empty(): continue
			if room_threats(room.id) == 0: room.cleared = true; continue
			room.locked = true; changed = true
			say("PORTÕES FECHADOS • elimine todos os inimigos da sala!")
			for d in doors:
				if d.room == room.id: effects.append({"p": d.r.get_center(), "kind": "gate_slam", "life": 0.5, "max": 0.5})
			# quem ficou do lado de fora é puxado para dentro (ninguém fica preso no corredor)
			for a in actors:
				if a.active and not a.dead and not room_contains(room, a.p):
					var spot: Vector2 = inside.p + Vector2(-50, 30)
					a.p = spot if clear_at(spot, 23 if a.mech else 11) else inside.p
					if a.mech: mech.p = a.p
	if changed: refresh_gate_blocks()

# ── Props destrutíveis e barris explosivos (0.13) ─────────────────────────────
const DESTRUCTIBLE := {"crate": 34.0, "crate_2": 44.0, "crate_3": 44.0, "crate_net": 40.0, "crate_barnacles": 50.0, "crate_broken": 20.0,
	"barrel": 40.0, "barrel_oil": 40.0, "barrel_toxic": 40.0, "barrel_explosive": 16.0, "barrel_tipped": 30.0,
	"fish_basket": 16.0, "lobster_trap": 22.0, "sandbags": 110.0, "sandbags_corner": 110.0, "sandbags_damaged": 60.0, "jerrycans": 24.0,
	"market_baskets": 16.0, "market_ice_barrel": 40.0, "workshop_parts": 30.0}   # 0.16
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
	step_tentacle_gates(dt)
	for h in hazards:
		if h.has("trap") and trap_phase(h) != "active": continue
		h["cd"] = maxf(0, h.get("cd", 0.0) - dt)
		for a in actors:
			if not a.active or a.dead: continue
			var d: Vector2 = a.p - h.p
			if h.get("trap", "") == "darts":
				var hit_dart := false
				for off in [-h.r*0.7, 0.0, h.r*0.7]:
					var dart_x: float = h.r-fposmod(tick_time*3.0+off,1.0)*h.r*2.0
					if absf(d.y-off)<14 and absf(d.x-dart_x)<22: hit_dart=true
				if not hit_dart: continue
			if Vector2(d.x, d.y * 1.5).length() < h.r:
				if a.jump > 0: continue   # saltar por cima escapa do tentáculo
				if h.cd <= 0 and not h.has("trap"):
					h.cd = 0.7
					effects.append({"p": h.p, "kind": "tentacle_strike", "life": 0.35, "max": 0.35, "dir": d.normalized() if d.length() > 1 else Vector2.RIGHT})
				damage_actor(a, h.get("damage", 12.0), "hazard", str(h.get("kind", "tentacle")))
				a.p = move_body(a.p, (d.normalized() if d.length() > 1 else Vector2.DOWN) * 260 * dt, 23 if a.mech else 11)

func room_at(pos: Vector2) -> Dictionary:
	for room in rooms:
		if room.kind == "secret" and not secret_open: continue
		if room.r.has_point(pos): return room
		for ex in room.get("extra", []):
			if ex.has_point(pos): return room
	return {}

func spawn_enemy(pos: Vector2, kind: String, optional: bool = false) -> void:
	uid += 1
	# 0.11: inimigos mais resistentes (≈ +50% de vida) e o Almirante com 600.
	var hp: float = {"boss": 600.0, "brute": 95.0, "fish": 66.0, "crawler": 45.0, "crawler_small": 18.0,
		"bomber": 24.0, "guard": 64.0}.get(kind, 52.0)
	if kind == "warden": hp = 420.0
	elif kind != "boss": hp *= 1.25
	enemies.append({"id": uid, "p": pos, "kind": kind, "hp": hp, "max": hp, "cd": rng.randf_range(0.5, 1.5), "phase": 0, "hurt": 0.0, "side": optional,
		"room": room_at(pos).get("id", "") if mode == "run" else "",
		"face": Vector2.DOWN, "moving": false, "shot": 0.0, "stage": 1, "charge": 0.0, "spin": 0.0, "spin_angle": 0.0, "step": 0.0,
		"fight_time": 0.0, "enraged": false, "fuse": -1.0, "zigzag": rng.randf_range(0.0, TAU), "detonated": false, "damage_scale": 1.0, "combat": "ready", "combat_t": 0.0, "target_id": -1, "elite": "", "trail_t": 0.0})
	# Modificador único, reproduzível pela seed; a entrada e salas seguras ficam livres.
	var room_id: String = room_at(pos).get("id", "")
	if mode == "run" and room_id not in ["", "entry", "dock", "landing", "spawn", "chapel", "warehouse", "shop", "secret"] and kind not in ["boss", "warden", "crawler_small"] and rng.randf() < 0.16:
		enemies[-1].elite = ["shield", "trail", "explosive"][rng.randi_range(0, 2)]

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
	for tg in tentacle_gates:
		if not tg.sealed and tg.block.grow(radius).has_point(pos): return false
	for stake in harpoons:
		if pos.distance_to(stake.p) < radius + 9: return false
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
		if not a.armor and a.armor_cd <= 0 and delta_enemy.length() < 300 and not a.mech and is_unlocked(a.armor_type): command.armor = true
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
	clutch_t = maxf(0, clutch_t - dt); clutch_cd = maxf(0, clutch_cd - dt)
	streak_t = maxf(0, streak_t - dt)
	if streak_t <= 0: streak = 0
	for a in actors:
		if not a.active: continue
		var cmd: Dictionary = commands[a.id] if commands.size() > a.id else {}
		if a.id == 1 and coop == "ai": cmd = ai_input()
		step_actor(a, cmd, dt)
	# Bullets must advance in every scene, including the refuge and training arena.
	step_spectres(dt); step_enemies(dt); step_bullets(dt); collect_pickups()
	# 0.15: slow-mo "clutch" — meio coração com inimigos por perto dispara uma vez
	for a in actors:
		if a.active and not a.dead and a.hp <= HEART * 0.5 + 0.01 and not enemies.is_empty() and clutch_cd <= 0:
			clutch_t = 2.2; clutch_cd = 20.0
			effects.append({"p": a.p, "kind": "clutch", "life": 0.6, "max": 0.6})
			say("NO LIMITE • cuidado!")
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
				if not room.is_empty() and not visited.has(room.id): visited.append(room.id); check_unlocks()
		step_gates(dt)
		step_hazards(dt)
		step_fuses(dt)
		if side_active:
			side_time -= dt
			if side_time <= 0:
				side_active = false; side_failed = true; say("Gerador perdido. A missão principal continua.")
			elif enemies.filter(func(e): return e.side).is_empty():
				side_active = false; side_complete = true; money += 25; keys += 2; materials += 1
				check_unlocks()
				for a in actors: heal(a, 2)
				say("DESAFIO CONCLUÍDO • 2 chaves, 25 moedas, cura e 1 fragmento permanente!")
		if actors.all(func(a): return a.dead):
			finish_run("death"); say("A âncora temporal resgatou a equipe. Confira o relatório.")
	for fx in effects: fx.life -= dt
	effects = effects.filter(func(fx): return fx.life > 0)

func step_actor(a: Dictionary, cmd: Dictionary, dt: float) -> void:
	if mech.get("cockpit_t", 0.0) > 0 and mech.get("cockpit_actor", -1) == a.id:
		mech.cockpit_t = maxf(0.0, mech.cockpit_t - dt)
		if a.dead or mech.hp <= 0: mech.cockpit_t = 0.0
		a.move = Vector2.ZERO
		return
	for timer in ["shot", "slash", "hurt", "jump_cd", "dodge_cd", "interact_cd", "summon_cd", "snare", "fire_flash", "transform", "armor_cd", "beam_cd", "combo_t", "bomb_cd", "roll_visual"]:
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
	if cmd.get("robot_switch", false): cycle_owned_robot(a)
	var moving: Vector2 = cmd.get("move", Vector2.ZERO)
	moving = moving.limit_length()
	var aim: Vector2 = cmd.get("aim", a.aim)
	if aim.length() > 0.1: a.aim = aim.normalized()
	if a.beam_time > 0 and (not cmd.get("special", false) or not a.armor or a.mech): stop_omega_beam(a)
	if cmd.get("special", false) and a.armor and not a.mech and a.beam_cd <= 0 and a.beam_time <= 0:
		a.beam_time = OMEGA_BEAM_DURATION
	if a.beam_time > 0:
		var beam_dt: float = minf(dt, a.beam_time)
		a.beam_end = omega_beam_endpoint(a.p, a.aim)
		for e in enemies:
			if e.hp <= 0 or Geometry2D.get_closest_point_to_segment(e.p, a.p, a.beam_end).distance_to(e.p) > 24: continue
			hurt_enemy(e, OMEGA_BEAM_DAMAGE * beam_dt); e.hurt = 0.08; e.alerted = true
		a.beam_time -= beam_dt
		if a.beam_time <= 0: stop_omega_beam(a)
	if cmd.get("jump", false) and a.jump <= 0 and a.jump_cd <= 0 and not a.mech:
		emit_audio("jump", a.p)
		a.jump = 0.65; a.jump_cd = 0.8; a["jump_from"] = a.p
	if cmd.get("dodge", false) and a.dodge_cd <= 0 and not a.mech:
		emit_audio("dash", a.p)
		a.dodge = 0.20; a.roll_visual = 0.36; a.dodge_cd = 0.3 if a.armor else uniform_of(a).dash_cd
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
			a.p = a.get("jump_from", a.p); damage_actor(a, 12, "water", "fall")
			effects.append({"p": a.p, "kind": "splash", "life": 0.5, "max": 0.5})
		elif a.jump == 0 and a.mech:
			# 0.15: pouso do Titan — onda de choque fere e quebra quem está perto
			explode(a.p, 80.0, 16.0, false)
			effects.append({"p": a.p, "kind": "stomp", "life": 0.5, "max": 0.5})
			hit_stop(0.04)
	if a.mech:
		mech.p = a.p; mech.aim = a.aim; mech.step = a.step; mech["facing"] = a.facing; mech["moving"] = a.move.length() > 0.1
		if a.move.length() > 0.1: mech["move_dir"] = a.move.normalized()
	if a.dodge <= 0 and (cmd.get("fire", false) or cmd.get("melee", false) or a.jump > 0): a.roll_visual = 0.0
	if a.armor and not a.mech:
		if a.beam_time <= 0 and (cmd.get("fire", false) or cmd.get("melee", false)) and a.shot <= 0: sword_attack(a)
	else:
		if cmd.get("fire", false) and a.shot <= 0 and not (a.mech and mech.fuel <= 0): fire_actor(a)
		if cmd.get("melee", false) and a.slash <= 0: melee(a)
	if cmd.get("interact", false) and a.interact_cd <= 0:
		a.interact_cd = 0.4; interact(a)
	if cmd.get("armor", false):
		if a.mech: throw_bomb(a)   # no Titan, R / LB lança uma bomba
		else: toggle_armor(a)
	if cmd.get("weapon", false) and not a.mech: toggle_run_weapon(a)

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

func explode(p: Vector2, radius: float, damage: float, big: bool, hurts_all: bool = false, credit_player: bool = true) -> void:
	emit_audio("explosion", p)
	for e in enemies:
		var d: float = e.p.distance_to(p)
		if d < radius + (45 if e.kind == "boss" else 19) and line_of_fire(p, e.p):
			var dealt: float = damage * (1.0 - 0.45 * clampf(d / radius, 0, 1))
			hurt_enemy(e, dealt, credit_player); e.hurt = 0.2; e["alerted"] = true
			pop_dmg(e.p, dealt, big)
	if hurts_all:   # barril: atinge todo mundo (1 coração) e empurra
		for a in actors:
			if a.active and not a.dead and a.p.distance_to(p) < radius * 0.8:
				damage_actor(a, 20.0, "explosion", "barrel")
				var push: Vector2 = (a.p - p).normalized() if a.p.distance_to(p) > 1 else Vector2.DOWN
				a.p = move_body(a.p, push * 60, 23 if a.mech else 11)
	# 0.16: parede rachada perto da explosão desmorona e abre o atalho
	for i in range(obstacles.size() - 1, -1, -1):
		if i < obstacle_kinds.size() and obstacle_kinds[i].begins_with("wall_crack_") and obstacles[i].get_center().distance_to(p) < radius + 70: open_shortcut(i)
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
	bullets.append({"p": pos, "v": direction * speed, "team": team, "damage": damage, "r": maxf(radius, 6.0) if team == 0 else radius * 1.12, "visual_r": maxf(radius, 6.0) / 0.8 if team == 0 else radius * 1.4, "age": 0.0, "life": life, "owner": owner_id, "kind": kind})

# 0.15: número de dano flutuante — desenhado em world_view.gd
func pop_dmg(p: Vector2, amount: float, heavy: bool = false) -> void:
	effects.append({"p": p, "kind": "dmg_num", "life": 0.6, "max": 0.6, "value": int(amount), "heavy": heavy, "vx": rng.randf_range(-14, 14)})

func hit_stop(d: float) -> void:
	hitstop = maxf(hitstop, d)

func weapon_of(a: Dictionary) -> String:
	if a.mech: return "mech"
	if a.armor: return "omega_sword"
	var selected: String = a.get("run_weapon", "")
	if selected != "" and a.get("run_weapons", {}).has(selected): return selected
	return uniform_of(a).weapon

func grant_run_weapon(a: Dictionary, name: String, ammo: int) -> void:
	var owned: Dictionary = a.get("run_weapons", {})
	var first: bool = not owned.has(name)
	owned[name] = mini(12, int(owned.get(name, 0)) + ammo)
	a["run_weapons"] = owned
	if first: a["run_weapon"] = name
	say("%s • %d foguetes nesta expedição • Q/RB troca arma" % [name.to_upper(), owned[name]])

func toggle_run_weapon(a: Dictionary) -> void:
	var owned: Dictionary = a.get("run_weapons", {})
	if a.get("run_weapon", "") != "":
		a["run_weapon"] = ""; say("ARMA BÁSICA • munição infinita"); return
	for name in owned:
		a["run_weapon"] = name; say("%s • %d foguetes" % [str(name).to_upper(), owned[name]]); return
	say("Nenhuma arma de expedição obtida.")

func select_run_weapon(id: int, weapon: String) -> bool:
	if id < 0 or id >= actors.size(): return false
	var a: Dictionary = actors[id]
	if not a.active or a.dead or a.mech or a.armor: return false
	if weapon != "" and (weapon != "bazooka" or not a.get("run_weapons", {}).has(weapon)): return false
	a.run_weapon = weapon
	return true


# 0.14: tabela única das armas — o jogo e a tela de Equipamento (loadout_stats) leem daqui.
const WEAPONS := {
	"pistol": {"count": 1, "damage": 16.0, "cooldown": 0.22, "speed": 660.0, "radius": 4.0, "spread": 0.12, "kind": "p_pistol", "pierce": 0},
	"shotgun": {"count": 6, "damage": 9.0, "cooldown": 0.65, "speed": 620.0, "radius": 4.0, "spread": 0.11, "kind": "p_pellet", "pierce": 0},
	"smg": {"count": 1, "damage": 7.0, "cooldown": 0.085, "speed": 740.0, "radius": 4.0, "spread": 0.12, "kind": "p_smg", "pierce": 0},
	"bazooka": {"count": 1, "damage": 48.0, "cooldown": 0.9, "speed": 390.0, "radius": 10.0, "spread": 0.0, "kind": "p_rocket", "pierce": 0},
	# Canhão de Plasma Ômega: disparo duplo, perfurante.
	"omega": {"count": 2, "damage": 24.0, "cooldown": 0.2, "speed": 860.0, "radius": 7.0, "spread": 0.05, "kind": "p_omega", "pierce": 2}}
const SWORD := {"hit": 38.0, "finisher": 64.0, "wave": 30.0}   # Lâmina Ômega (3º corte + onda)
const MECH_PUNCH := 55.0
const SPECTRE_SHOT := {"damage": 9.0, "cooldown": 0.55}
const SPECTRE_HP := 100.0
const FUSION := {"damage": 1.35, "cadence": 0.8, "speed": 360.0}

const ACTOR_VISUAL_SCALE := 1.12

# Hand and barrel geometry is shared with WorldView. Height never shifts collision Y.
func weapon_hand_anchor(a: Dictionary, body_direction: Vector2 = Vector2.ZERO) -> Vector2:
	var direction: Vector2 = a.get("aim", a.facing) if body_direction == Vector2.ZERO else body_direction
	if outfit_of(a) == "omega":
		var omega_anchors := [
			Vector2(20, -40), Vector2(23, -43), Vector2(25, -44), Vector2(20, -47),
			Vector2(10, -49), Vector2(-20, -47), Vector2(-25, -44), Vector2(-23, -43),
		]
		return omega_anchors[weapon_direction_row(direction)]
	if outfit_of(a) == "padrao":
		# O novo atlas tem oito direcoes e corpo mais alto que o legado.
		# A ancora segue a mira para manter a empunhadura junto da mao no disparo.
		var padrao_anchors := [
			Vector2(10, -35), Vector2(15, -36), Vector2(17, -35), Vector2(14, -38),
			Vector2(7, -40), Vector2(-14, -38), Vector2(-17, -35), Vector2(-15, -36),
		]
		return padrao_anchors[weapon_direction_row(direction)]
	# 0.17: acompanha a mão visível de cada vista, em vez de orbitar o centro do corpo.
	var pose := weapon_pose(a.facing)
	var anchors := [Vector2(20, -27), Vector2(21, -28), Vector2(18, -26), Vector2(18, -26), Vector2(20, -25)]
	var hand: Vector2 = anchors[pose[0]]
	if pose[1]: hand.x = -hand.x
	if a.armor: hand.y -= 2
	return hand

func weapon_pose(f: Vector2) -> Array:
	# 8 direções com 5 vistas: frente, frente-3/4, lado, costas-3/4, costas (espelhadas para a esquerda).
	var octant := int(round(fposmod(f.angle(), TAU) / (TAU / 8))) % 8
	match octant:
		0: return [2, false]   # direita
		1: return [1, false]   # baixo-direita
		2: return [0, false]   # baixo
		3: return [1, true]    # baixo-esquerda
		4: return [2, true]    # esquerda
		5: return [3, true]    # cima-esquerda
		6: return [4, false]   # cima
		_: return [3, false]   # cima-direita

func weapon_direction_row(direction: Vector2) -> int:
	# Ordem do export PixelLab: sul, sudeste, leste, nordeste, norte,
	# noroeste, oeste, sudoeste.
	var f := direction.normalized() if direction.length() > 0.01 else Vector2.DOWN
	var octant := int(round(fposmod(f.angle(), TAU) / (TAU / 8))) % 8
	return [2, 1, 0, 7, 6, 5, 4, 3][octant]

func weapon_geometry(a: Dictionary, body_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	var weapon := weapon_of(a)
	var sizes := {"pistol": Vector2(40, 18), "shotgun": Vector2(56, 18), "smg": Vector2(52, 22), "bazooka": Vector2(96, 64), "omega": Vector2(44, 18)}
	var size: Vector2 = sizes.get(weapon, Vector2(32, 20))
	var handle: Vector2 = {"pistol": Vector2(8, 12), "shotgun": Vector2(18, 12), "smg": Vector2(17, 15), "bazooka": Vector2(34, 42)}.get(weapon, Vector2(8, size.y * 0.5))
	var aim: Vector2 = a.aim.normalized()
	var mirror := -1.0 if aim.x < 0 else 1.0
	var hand := weapon_hand_anchor(a, body_direction)
	var tip: Vector2 = Vector2(90, 28) if weapon == "bazooka" else Vector2(size.x - 2, size.y * 0.5)
	var barrel := Vector2(tip.x - handle.x, (tip.y - handle.y) * mirror).rotated(aim.angle())
	var jump_height := sin((1.0 - a.jump / 0.65) * PI) * 68 if a.jump > 0 else 0.0
	return {"hand": hand, "handle": handle, "angle": aim.angle(), "mirror": mirror,
		"ground": a.p + (Vector2(hand.x, 0) + barrel) * ACTOR_VISUAL_SCALE, "height": (-hand.y + height_at(a.p) + jump_height) * ACTOR_VISUAL_SCALE,
		"muzzle": a.p + hand + barrel - Vector2(0, height_at(a.p) + jump_height)}

func fire_actor(a: Dictionary) -> void:
	var weapon := weapon_of(a)
	if weapon == "bazooka":
		var owned: Dictionary = a.run_weapons
		if int(owned.get("bazooka", 0)) <= 0:
			emit_audio("dry_fire", a.p)
			a.shot = 0.3; say("BAZUCA SEM FOGUETES • Q/RB equipa a arma básica"); return
		owned.bazooka = maxi(0, int(owned.bazooka) - 1)
		a.run_weapons = owned
	var w: Dictionary = WEAPONS.get(weapon, WEAPONS.pistol)
	var count: int = w.count; var damage: float = w.damage; var cooldown: float = w.cooldown; var speed: float = w.speed
	var radius: float = w.radius; var spread: float = w.spread; var kind: String = w.kind; var pierce: int = w.pierce
	if weapon == "mech":
		count = 1; spread = 0.0; pierce = 0
		damage = MECH_SHELL.damage; cooldown = MECH_SHELL.cooldown; radius = MECH_SHELL.radius; speed = MECH_SHELL.speed; kind = "p_heavy"
		mech.fuel = maxf(0, mech.fuel - FUEL_SHOT)
	if a.fused: damage *= FUSION.damage; cooldown *= FUSION.cadence
	var geometry := weapon_geometry(a)
	var origin: Vector2 = a.p + a.aim * 40 if a.mech else geometry.ground
	# Sweep to the barrel so a long weapon cannot spawn through a thin wall.
	var steps := maxi(1, ceili(a.p.distance_to(origin) / 2.0))
	for step in range(1, steps + 1):
		var sample: Vector2 = a.p.lerp(origin, float(step) / steps)
		if not clear_at(sample, radius, true):
			origin = a.p.lerp(origin, float(step - 1) / steps); break
	for n in range(count):
		var direction: Vector2 = a.aim.rotated((n - (count - 1) / 2.0) * spread)
		add_bullet(origin, direction, 0, damage, speed, radius, a.id, kind)
		bullets[-1]["height"] = 28.0 if a.mech else geometry.height
		bullets[-1]["pierce"] = pierce
		if weapon == "shotgun": bullets[-1].v *= rng.randf_range(0.85, 1.1)
		# Resolve close targets hidden behind the long barrel before normal flight.
		var bullet: Dictionary = bullets[-1]
		var near_steps := maxi(1, ceili(a.p.distance_to(origin) / 2.0))
		for step in range(1, near_steps + 1):
			bullet.p = a.p.lerp(origin, float(step) / near_steps)
			hit_bullet_enemy(bullet, true)
			if bullet.life <= 0 or bullet.team != 0: break
	a.shot = cooldown; a["fire_flash"] = 0.09
	emit_audio(weapon, a.p)
	if weapon == "bazooka" and int(a.run_weapons.bazooka) == 0:
		say("BAZUCA SEM FOGUETES • Q/RB equipa a arma básica")
	if a.mech: effects.append({"p": a.p + a.aim * 30, "kind": "flash", "life": 0.12, "dir": a.aim}); effects.append({"p": a.p, "kind": "recoil", "life": 0.2, "max": 0.2, "dir": a.aim})
	elif weapon in ["shotgun", "smg"]:
		effects.append({"p": a.p, "kind": "casing", "life": 0.5, "max": 0.5, "dir": a.aim.rotated(-PI / 2 if a.aim.x >= 0 else PI / 2), "seed": rng.randi() % 1000})

# Lâmina Ômega: combo de 3 cortes em arco. O 3º é mais largo e solta uma onda perfurante.
func sword_attack(a: Dictionary) -> void:
	emit_audio("sword", a.p)
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
			hurt_enemy(e, damage); e.hurt = 0.18
			pop_dmg(e.p, damage, finisher)
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
	emit_audio("melee", a.p)
	a.slash = 0.65 if a.mech else 0.45
	var reach := 115.0 if a.mech else 78.0
	effects.append({"p": a.p, "kind": "slash", "life": 0.18, "dir": a.aim, "reach": reach})
	for e in enemies:
		var offset: Vector2 = e.p - a.p
		if offset.length() < reach and offset.normalized().dot(a.aim) > 0.05:
			var mdmg: float = MECH_PUNCH if a.mech else float(uniform_of(a).melee)
			hurt_enemy(e, mdmg); e.hurt = 0.15
			pop_dmg(e.p, mdmg, a.mech)
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

func begin_cockpit(a: Dictionary, entering: bool, outside: Vector2) -> void:
	# 0.18: estado visual serializado junto do Titan; bloqueia comandos durante a escotilha.
	mech["cockpit_t"] = 1.2
	mech["cockpit_actor"] = a.id
	mech["cockpit_entering"] = entering
	mech["cockpit_outside"] = outside
	mech["moving"] = false
	mech["boosting"] = false

func interact(a: Dictionary) -> void:
	if mode == "run" and a.p.distance_to(STORY_NPC) < 95:
		story_interact(a); return
	for chest in chests:
		if chest.get("reward", false) and not chest.open and a.p.distance_to(chest.p) < 85:
			open_reward(chest, a); return
	if mech.get("cockpit_t", 0.0) > 0: return
	if a.mech:
		for offset in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 65), Vector2(0, -65)]:
			if clear_at(a.p + offset, 12):
				begin_cockpit(a, false, a.p + offset); mech.occupant = -1; a.mech = false; a.p += offset; say("Desembarque. A máquina mantém os danos."); return
		say("Saída bloqueada."); return
	for other in actors:
		if other.active and other.id != a.id and other.dead and a.p.distance_to(other.p) < 75:
			other.dead = false; other.hp = HEART * 1.5; other.hurt = 2
			if mode == "run": ensure_run_stats(); run_stats.revives += 1
			say("Parceiro reanimado!"); return
	if mech.deployed and is_unlocked("titan") and mech.hp > 0 and mech.occupant == -1 and not a.fused and a.p.distance_to(mech.p) < 90:
		if mech.fuel <= 0: say("Titan sem gasolina • abra os baús para achar um galão."); return
		begin_cockpit(a, true, a.p); mech.occupant = a.id; a.mech = true; a.p = mech.p; a["fuel_warned"] = false; say("TITAN-01 • Tiro: canhão pesado / R: bomba / Shift: turbo / E: sair • GASOLINA %.0f%%" % (mech.fuel / FUEL_MAX * 100)); return
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
				say("Uniforme: " + UNIFORMS[a.outfit].name + ". Configure o próximo visual antes da expedição."); return
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
				ensure_run_stats(); run_stats.chests_opened += 1
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
				check_unlocks()
			finish_run("victory"); say("Núcleo recuperado! Confira o relatório da expedição."); return
	say("Aproxime-se de um portal, baú, parceiro caído, comerciante ou robô e pressione E.")

func damage_actor(a: Dictionary, amount: float, source_kind: String = "unknown", source_attack: String = "") -> void:
	if a.hurt > 0 or a.dodge > 0 or a.dead or a.jump > 0 or a.get("transform", 0.0) > 0: return
	if amount > 0: emit_audio("hit", a.p)
	var hp_before := float(a.hp)
	a.last_damage_source = source_kind; a.last_damage_attack = source_attack
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
	if mode == "run":
		ensure_run_stats()
		run_stats.damage_received += maxf(0.0, hp_before - float(a.hp))
		if a.dead:
			run_stats.fatal_source = source_kind
			run_stats.fatal_attack = source_attack

# Inimigos das Docas de 1941 e o Almirante das Profundezas.
#   cult   Cultista Atirador      orbe magenta, distância média
#   fish   Arpoador das Profundezas  arpão lento e forte que prende (reduz a velocidade)
#   crawler Rastejante Tentacular ácido de curta distância; ao morrer vira duas bolhas menores
#   brute  Soldado Possuído       leque de balas violeta
func detection_range(a: Dictionary, base: float) -> float:
	# Disfarce de Londres: inimigos só notam Marty mais de perto.
	return base * 0.55 if outfit_of(a) == "espiao" and not a.mech else base

func step_enemies(dt: float) -> void:
	step_combat_zones(dt)
	# 0.15: o portal aparece primeiro; só materializa o inimigo depois de 0,8s.
	var ready_spawns: Array = []
	for pending in pending_spawns:
		pending.timer -= dt
		if pending.timer <= 0: ready_spawns.append(pending)
	if not pending_spawns.is_empty(): arena_wait = 0.0
	pending_spawns = pending_spawns.filter(func(p): return p.timer > 0)
	for pending in ready_spawns:
		spawn_enemy(pending.p, pending.kind)
		var spawned_enemy: Dictionary = enemies[-1]
		spawned_enemy.hp *= pending.hp_scale; spawned_enemy.max = spawned_enemy.hp
		spawned_enemy.damage_scale = pending.damage_scale
	var spawned: Array = []
	for e in enemies:
		e.hurt = maxf(0, e.hurt - dt); e.shot = maxf(0, e.shot - dt); e.moving = false
		if e.hp <= 0: continue
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
		if target.is_empty():
			e["combat"] = "ready"; e["target_id"] = -1; e["jump_height"] = 0.0; e["crouched"] = false; continue
		e["alerted"] = true
		var direction: Vector2 = (target.p - e.p).normalized()
		e.face = direction
		if e.kind == "warden": step_warden(e, target, direction, closest, dt); continue
		if e.kind == "boss": step_boss(e, target, direction, closest, dt); continue
		step_common_enemy(e, target, dt)

	for e in enemies:
		if e.hp > 0: continue
		emit_audio("enemy_die", e.p)
		if e.kind == "bomber" and not e.detonated:
			e.detonated = true
			add_combat_zone(e.p, BOMBER_BLAST.radius, BOMBER_BLAST.damage * e.damage_scale, "blast", 0.65, 0.1)
		if e.get("elite", "") == "explosive": add_combat_zone(e.p, 100, 22, "blast", 0.75, 0.1)
		# 0.15: sequência de abates — bônus de moedas crescente + hitstop (maior em elites)
		streak += 1; streak_t = 2.2
		if mode == "run":
			ensure_run_stats()
			run_stats.kills += 1
			run_stats.kills_by_kind[e.kind] = int(run_stats.kills_by_kind.get(e.kind, 0)) + 1
			run_stats.max_streak = maxi(int(run_stats.max_streak), streak)
		money += 4 + mini(streak - 1, 4)
		if e.kind in ["boss", "warden"]: hit_stop(0.09); streak_t = 3.0
		else: hit_stop(0.03)
		pickups.append({"p": e.p, "kind": "coin"})
		if rng.randf() < KEY_DROP_CHANCE: pickups.append({"p": e.p + Vector2(15, 0), "kind": "key"})
		if e.kind not in ["crawler_small", "boss"] and rng.randf() < AMMO_DROP_CHANCE:
			pickups.append({"p": e.p + Vector2(-15, 0), "kind": "ammo", "weapon": "bazooka", "ammo": 2})
		effects.append({"p": e.p, "kind": "corpse", "enemy": e.kind, "life": 2.6 if e.kind == "boss" else 1.2, "max": 2.6 if e.kind == "boss" else 1.2, "face": e.face, "flip": e.face.x < 0})
		if e.kind == "crawler":
			for off in [Vector2(-18, 6), Vector2(18, -6)]:
				if clear_at(e.p + off, 10): spawned.append([e.p + off, e.side])
		if e.kind == "warden" or e.get("miniboss", false):
			chests.append({"p": e.p, "open": false, "secret": false, "reward": true})
			say("MINIBOSS DERROTADO • baú dourado sem chave! [E]")
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
			if a.active and not a.dead and Geometry2D.get_closest_point_to_segment(a.p, before, e.p).distance_to(a.p) < 62 and line_of_fire(e.p, a.p): damage_actor(a, 32, "warden", "charge")
		if e.attack_time <= 0 or e.p.distance_to(before) < 850.0 * dt * 0.8:
			e.attack_state = "recover"; e.attack_time = 0.9
		return
	if state == "recover":
		if e.attack_time <= 0: e.attack_state = "hunt"; e.cd = 0.45
		return
	e.cd -= dt
	if closest < 560 and e.cd <= 0 and line_of_fire(e.p, target.p):
		emit_audio("enemy_warden", e.p)
		e["attack_state"] = "warning"; e.attack_time = 0.55; e["charge_dir"] = direction
		return
	var before: Vector2 = e.p
	e.p = move_body(e.p, direction * 300.0 * dt, 48)
	e.moving = e.p.distance_to(before) > 0.1; e.step += dt * 10

func enrage_scale(e: Dictionary) -> float:
	return BOSS_ENRAGE_SCALE if e.get("enraged", false) else 1.0

func step_boss(e: Dictionary, target: Dictionary, direction: Vector2, closest: float, dt: float) -> void:
	if boss_motion(e, target, dt): return
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
			emit_audio("enemy_boss", e.p)
			e.shot = 0.4
			add_bullet(e.p + direction * 30, direction, 1, 24, 200, 13, -1, "cannon", 4.0)
		return
	if e.spin > 0:
		e.spin -= dt; e.cd -= dt
		if e.cd <= 0:
			e.cd = 0.11 * enrage_scale(e); e.spin_angle += 0.42
			emit_audio("enemy_boss", e.p)
			for k in range(2 if stage == 2 else 3):
				add_bullet(e.p, Vector2.RIGHT.rotated(e.spin_angle + k * TAU / (2 if stage == 2 else 3)), 1, 10, 165, 6, -1, "orb")
		return
	e.cd -= dt
	if e.cd > 0: return
	e.phase += 1
	match stage:
		1:
			emit_audio("enemy_boss", e.p)
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
			emit_audio("enemy_boss", e.p)
			match e.phase % 3:
				0:
					for n in range(3): add_bullet(e.p, direction.rotated((n - 1) * 0.35), 1, 14, 115, 11, -1, "ink", 4.5)
				1:
					add_bullet(e.p, direction, 1, 18, 280, 6, -1, "harpoon")
					bullets[-1]["source"] = "boss"
					if closest < 260:
						for n in range(6): add_bullet(e.p + direction * 30, direction.rotated((n - 2.5) * 0.12), 1, 8, 280, 8, -1, "flame", 0.7)
				2:
					for n in range(20): add_bullet(e.p, Vector2.RIGHT.rotated(n * TAU / 20 + e.phase * 0.3), 1, 12, 175, 7, -1, "orb")

func muzzle_line_clear(from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1, ceili(from.distance_to(to) / 2.0))
	for step in range(1, steps + 1):
		if not clear_at(from.lerp(to, float(step) / steps), 0, true): return false
	return true

func hit_bullet_enemy(b: Dictionary, check_wall: bool = false) -> void:
	for e in enemies:
		if b.p.distance_to(e.p) < (48 if e.kind == "warden" else (45 if e.kind == "boss" else (12 if e.kind == "crawler_small" else 19))) + b.r:
			var previous_hits: Array = b.get("hits", [])
			if previous_hits.has(e.id): continue
			if e.hp <= 0: continue
			if check_wall and not muzzle_line_clear(b.p, e.p): continue
			if (e.kind == "guard" or e.get("elite", "") == "shield") and not (e.kind == "guard" and e.combat == "attack") and -b.v.normalized().dot(e.face) > 0 and b.get("kind", "") not in ["p_omega", "p_rocket"]:
				b.team = 1; b.v = -b.v; b["owner"] = -1; b.p += b.v.normalized() * 12
				effects.append({"p": b.p, "kind": "impact", "omega": false, "life": 0.18, "max": 0.18}); break
			hurt_enemy(e, b.damage); e.hurt = 0.12; e["alerted"] = true
			if b.get("kind", "") == "p_rocket":
				explode(b.p, 72, 30, false); b.life = 0; break
			# 0.15: número de dano + empurrão leve no impacto (pesada empurra mais)
			pop_dmg(e.p, b.damage, b.get("kind", "") in ["p_heavy", "p_omega"])
			if e.kind not in ["boss", "warden"]:
				e.p = move_body(e.p, b.v.normalized() * (14.0 if b.get("kind", "") == "p_heavy" else 4.0), 12 if e.kind == "crawler_small" else 14)
			if b.get("kind", "") == "p_heavy":
				var heavy_hits: Array = b.get("hits", []); heavy_hits.append(e.id)
				for other in enemies:   # respingo não repete o dano no alvo direto
					if not heavy_hits.has(other.id) and other.p.distance_to(b.p) < MECH_SHELL.splash + 19:
						hurt_enemy(other, MECH_SHELL.splash_damage); other.hurt = 0.15; other["alerted"] = true
						pop_dmg(other.p, MECH_SHELL.splash_damage)
				effects.append({"p": b.p, "kind": "explosion", "life": 0.4, "max": 0.4, "r": MECH_SHELL.splash})
				emit_audio("explosion", b.p)
			effects.append({"p": b.p, "kind": "impact", "life": 0.18, "max": 0.18, "omega": b.get("kind", "") == "p_omega"})
			if b.get("pierce", 0) > 0:
				b.pierce -= 1; previous_hits.append(e.id); b["hits"] = previous_hits
			else: b.life = 0
			break

func step_bullets(dt: float) -> void:
	var children: Array = []
	for b in bullets:
		if b.life <= 0: continue
		b.life -= dt
		if b.life <= 0:
			if b.get("stake", false): lodge_harpoon(b.p)
			continue
		b["age"] = b.get("age", 0.0) + dt
		if b.get("arc", false):
			b.p = b.from.lerp(b.to, minf(1, b.age / b.flight))
			if b.age >= b.flight:
				add_combat_zone(b.to, 62, b.damage, "acid", 0, 2.5); b.life = 0
			continue
		b.v = b.v.rotated(b.get("curve", 0.0) * dt)
		if b.get("accel", 0.0) != 0: b.v = b.v.normalized() * clampf(b.v.length() + b.accel * dt, 40, 620)
		if b.get("trail", false) and b.age >= b.get("trail_next", 0.0):
			b["trail_next"] = b.age + 0.22; add_combat_zone(b.p, 22, 10, "trail", 0.5, 1.3)
		if b.get("kind", "") == "bomb": step_bomb(b, dt); continue
		var distance: float = b.v.length() * dt
		var count := maxi(1, int(ceil(distance / 5.0)))
		for _n in range(count):
			b.p += b.v * dt / count
			if not clear_at(b.p, 0, true):
				b.life = 0
				if mode == "run" and b.get("kind", "") != "p_heavy": damage_obstacle(obstacle_at(b.p), b.damage * (0.5 if b.team == 1 else 1.0))
				if b.get("kind", "") == "p_heavy": explode(b.p, MECH_SHELL.splash, MECH_SHELL.splash_damage, false)
				if b.get("kind", "") == "p_rocket": explode(b.p, 72, 30, false)
				if b.team == 0: effects.append({"p": b.p, "kind": "impact", "life": 0.18, "max": 0.18, "omega": b.get("kind", "") == "p_omega"})
				break
			if b.team == 0:
				hit_bullet_enemy(b)
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
						var bullet_source := str(b.get("source", {"cannon": "boss", "orb": "boss", "ink": "boss", "flame": "boss", "violet": "brute", "magenta": "cult"}.get(b.get("kind", ""), "unknown")))
						damage_actor(a, b.damage, bullet_source, str(b.get("kind", "projectile"))); b.life = 0
						if b.get("kind", "") == "harpoon" and not a.mech: a.snare = 0.9
						break
			if b.life <= 0: break
		if b.life <= 0 and b.get("stake", false): lodge_harpoon(b.p - b.v.normalized() * 18)
		if b.life > 0 and b.get("split_at", -1.0) > 0 and b.age >= b.split_at:
			for n in range(4):
				var child: Dictionary = b.duplicate(true)
				child.v = b.v.normalized().rotated(n * TAU / 4) * 220; child.life = 2.5; child.age = 0; child.split_at = -1; child.curve = 0
				children.append(child)
			b.life = 0
	bullets = bullets.filter(func(b): return b.life > 0)
	bullets.append_array(children)

func collect_pickups() -> void:
	for pickup in pickups:
		for a in actors:
			if a.active and not a.dead and a.p.distance_to(pickup.p) < 32:
				if pickup.kind == "key": keys += 1
				elif pickup.kind == "weapon": grant_run_weapon(a, pickup.weapon, int(pickup.ammo))
				elif pickup.kind == "ammo":
					if not a.run_weapons.has(pickup.weapon): continue
					grant_run_weapon(a, pickup.weapon, int(pickup.ammo))
				elif pickup.kind == "fuel":
					mech.fuel = minf(FUEL_MAX, mech.fuel + FUEL_PICKUP); say("GALÃO DE GASOLINA • Titan +%.0f%% de combustível" % (FUEL_PICKUP / FUEL_MAX * 100))
				elif pickup.kind == "battery":
					var bs: Dictionary = spectres[a.id]
					if bs.hp <= 0: bs.state = "stored"   # bateria reanima um Spectre destruído
					bs.hp = minf(100.0, bs.hp + BATTERY_PICKUP); say("BATERIA • Spectre recarregado")
				else: money += 2
				emit_audio("pickup", pickup.p)
				pickup["taken"] = true; break
	pickups = pickups.filter(func(p): return not p.get("taken", false))

func equip(id: int, outfit: String, robot: String, armor_type: String = "omega") -> bool:
	if id < 0 or id >= actors.size() or not actors[id].active: return false
	if outfit not in OUTFITS or robot not in ["", "titan", "spectre"] or armor_type not in ARMORS: return false
	if not is_unlocked(outfit) or (robot != "" and not is_unlocked(robot)):
		say("Esse item ainda está bloqueado."); return false
	var a: Dictionary = actors[id]
	if a.dead: return false
	if robot != a.selected_robot and not can_switch_robot(a): return false
	if a.fused and robot != a.selected_robot:
		say("Desfaça a fusão antes de trocar de robô."); return false
	if a.armor and outfit != a.outfit:
		say("Com a armadura ativa não dá para trocar de uniforme nem de arma."); return false
	# O inventário persistente pertence ao jogador principal; P2/guest não sobrescreve seu loadout meta.
	if id == 0:
		var inventory := InventoryState.new(inventory_state)
		for entry in InventoryData.valid_items():
			var loadout_id := str(entry.get("loadout_id", "")); var slot := str(entry.get("slot", ""))
			var required := (loadout_id == outfit and slot == "uniforme") or (loadout_id == robot and slot == "robo")
			var optional_armor := loadout_id == armor_type and slot == "armadura" and InventoryData.unlocked(entry, unlocked)
			if required or optional_armor:
				if inventory.quantity(entry.id) == 0 and not inventory.add(entry.id): return false
				if not inventory.equip(entry.id, unlocked): return false
		if robot == "" and not inventory.unequip("robo"): return false
		inventory_state = inventory.to_dict()
	a.outfit = outfit
	if robot != a.selected_robot: store_selected_robot(a); a.selected_robot = robot
	if not a.armor: a.armor_type = armor_type
	return true

func robot_module_entry(robot_id: String) -> Dictionary:
	for entry in InventoryData.valid_items():
		if entry.get("slot", "") == "robo" and entry.get("loadout_id", "") == robot_id: return entry
	return {}

func owned_robot_ids(actor_id: int) -> Array[String]:
	var result: Array[String] = []
	if actor_id != 0:
		for robot_id in ["titan", "spectre"]:
			if is_unlocked(robot_id): result.append(robot_id)
		return result
	var inventory := InventoryState.new(inventory_state)
	for robot_id in ["titan", "spectre"]:
		var entry := robot_module_entry(robot_id)
		if is_unlocked(robot_id) and not entry.is_empty() and inventory.quantity(entry.id) > 0: result.append(robot_id)
	return result

func reconcile_robot_entitlements() -> void:
	var inventory := InventoryState.new(inventory_state)
	for robot_id in ["titan", "spectre"]:
		if not is_unlocked(robot_id): continue
		var entry := robot_module_entry(robot_id)
		if not entry.is_empty() and inventory.quantity(entry.id) == 0: inventory.add(entry.id)
	inventory_state = inventory.to_dict()

func can_switch_robot(a: Dictionary) -> bool:
	if not a.active or a.dead:
		say("Não é possível trocar de robô enquanto Marty está caído."); return false
	if a.mech:
		say("Saia do Titan antes de trocar de robô."); return false
	if a.fused:
		say("Desfaça a fusão antes de trocar de robô."); return false
	if mech.get("cockpit_t", 0.0) > 0 and mech.get("cockpit_actor", -1) == a.id:
		say("Espere a entrada ou saída do cockpit terminar."); return false
	return true

func store_selected_robot(a: Dictionary) -> void:
	if a.selected_robot == "titan" and mech.get("owner", -1) in [-1, a.id] and mech.get("occupant", -1) == -1 and mech.get("deployed", false):
		effects.append(SummonFX.recall_effect(a.id, a.p - Vector2(0, 30), mech.p, "titan")); mech.deployed = false
	elif a.selected_robot == "spectre" and spectres[a.id].state == "following":
		effects.append(SummonFX.recall_effect(a.id, a.p - Vector2(0, 30), spectres[a.id].p, "spectre")); spectres[a.id].state = "stored"

func select_owned_robot(a: Dictionary, robot_id: String) -> bool:
	if robot_id == a.selected_robot: return true
	if robot_id not in owned_robot_ids(a.id): say("Esse módulo de robô não está disponível."); return false
	if not can_switch_robot(a): return false
	store_selected_robot(a); a.selected_robot = robot_id
	say("ROBÔ SELECIONADO • %s" % robot_id.to_upper())
	return true

func cycle_owned_robot(a: Dictionary) -> bool:
	if not can_switch_robot(a): return false
	var owned := owned_robot_ids(a.id)
	if owned.size() < 2:
		say("Nenhum robô alternativo disponível."); return false
	var index := owned.find(str(a.selected_robot))
	return select_owned_robot(a, owned[(index + 1) % owned.size()] if index >= 0 else owned[0])

func free_summon_position(a: Dictionary, radius: float) -> Vector2:
	for distance in [100, 145, 190]:
		for n in range(8):
			var dir: Vector2 = a.facing.rotated(n * TAU / 8)
			var pos: Vector2 = a.p + dir * distance
			if clear_at(pos, radius) and line_of_fire(a.p, pos) and absf(height_at(pos) - height_at(a.p)) < 8:
				return pos
	return Vector2.INF

func summon_robot(a: Dictionary) -> bool:
	if mech.get("cockpit_t", 0.0) > 0 and a.selected_robot == "titan": return false
	if not a.active or a.dead: return false
	if a.selected_robot == "" or not is_unlocked(a.selected_robot):
		say("Nenhum robô desbloqueado ainda."); return false
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
		if not owner_actor.active or owner_actor.dead or owner_actor.selected_robot != "spectre": s.state = "stored"; continue
		var offset: Vector2 = owner_actor.p - s.p
		s["moving"] = offset.length() > 85
		if s.moving:
			s["move_dir"] = offset.normalized(); s.aim = s.move_dir; s["step"] = s.get("step", 0.0) + dt * 10
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
				emit_audio("spectre", s.p)
				s.shot = SPECTRE_SHOT.cooldown

func snapshot() -> Dictionary:
	var data := {}
	data["audio_events"] = audio_events.duplicate(true)
	data["audio_sequence"] = audio_sequence
	data["spectres"] = spectres
	for name in ["actors", "enemies", "bullets", "pickups", "effects", "rooms", "floors", "obstacles", "chests", "mech", "seed_value", "mode", "money", "keys", "materials", "run_materials_start", "upgrade", "clears", "armor_unlocked", "unlocked", "inventory_state", "story_quest", "dialogue_queue", "combat_zones", "harpoons", "pending_spawns", "side_active", "side_complete", "side_time", "side_failed", "boss_dead", "secret_open", "message", "message_time", "coop", "tick_time", "shop_bought", "arena_wave", "obstacle_kinds", "decor", "visited", "ramps", "raised", "gaps", "doors", "gate_blocks", "hazards", "tentacle_gates", "obstacle_hp", "fuses", "hitstop", "clutch_t", "clutch_cd", "streak", "streak_t", "run_stats", "last_run_summary", "summary_seq"]:
		data[name] = get(name)
	return data

func apply_snapshot(data: Dictionary) -> void:
	var allowed := snapshot().keys()
	for name in data:
		if name in allowed and name not in ["inventory_state", "audio_events", "audio_sequence"]: set(name, data[name])
	# Replicas adopt the host's sequence, including a new host with lower IDs.
	# Legacy saves have no cues and preserve the local sequence.
	audio_events.clear()
	var incoming_sequence: Variant = data.get("audio_sequence")
	if incoming_sequence is int: audio_sequence = maxi(0, incoming_sequence)
	var incoming_events: Variant = data.get("audio_events", [])
	if incoming_events is Array:
		for event in incoming_events:
			if not event is Dictionary: continue
			if not event.get("id") is int or not event.get("key") is String or not event.get("p") is Vector2: continue
			if not (event.get("time") is float or event.get("time") is int): continue
			if event.id <= 0: continue
			audio_events.append(event.duplicate(true))
			audio_sequence = maxi(audio_sequence, event.id)
			if audio_events.size() > MAX_AUDIO_EVENTS: audio_events.pop_front()
	# Saves de expedições antigas podem carregar uma lista anterior de desbloqueios.
	# A Ômega agora é inicial; migre somente ela sem alterar a progressão dos outros itens.
	if not unlocked is Dictionary: unlocked = {}
	unlocked["omega"] = true
	if data.get("inventory_state") is Dictionary: inventory_state = InventoryState.new(data.inventory_state).to_dict()
	else: inventory_state = InventoryState.new(inventory_state).to_dict()
	if not run_stats is Dictionary or run_stats.is_empty(): run_stats = fresh_run_stats()
	if not last_run_summary is Dictionary: last_run_summary = {}


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


# ── 0.17: desbloqueio de equipamento (regras em data/equipamento.json) ─────────
func is_unlocked(id: String) -> bool:
	return id != "" and unlocked.get(id, false) == true

func default_robot() -> String:
	for id in ["titan", "spectre"]:
		if is_unlocked(id): return id
	return ""

func set_unlocks(ids: Array) -> void:
	unlocked.clear()
	for id in ids: unlocked[str(id)] = true
	new_unlocks.clear()
	for a in actors:
		if not is_unlocked(a.outfit): a.outfit = "padrao"
		if not is_unlocked(a.selected_robot): a.selected_robot = default_robot()
	apply_unlock_state()
	reconcile_robot_entitlements()

func unlock(id: String) -> bool:
	if is_unlocked(id) or EquipmentData.item(id).is_empty(): return false
	unlocked[id] = true; new_unlocks.append(id)
	for a in actors:
		if a.selected_robot == "" and id in ["titan", "spectre"]: a.selected_robot = id
	if id == "titan" and mode == "run" and mech.occupant == -1: mech.deployed = true   # o Titan estava guardado na Oficina
	apply_unlock_state()
	say("DESBLOQUEADO • %s • veja no Equipamento." % EquipmentData.item(id).get("nome", id.to_upper()))
	return true

# Avalia as regras de desbloqueio de cada item: inicio | sala | desafio | chefe | expedicoes.
func check_unlocks() -> void:
	for it in EquipmentData.items():
		if is_unlocked(it.id): continue
		var cond: Dictionary = it.get("desbloqueio", {})
		var ok := false
		match str(cond.get("tipo", "")):
			"inicio": ok = true
			"sala": ok = mode == "run" and visited.has(str(cond.get("sala", "")))
			"desafio": ok = side_complete
			"chefe": ok = armor_unlocked
			"expedicoes": ok = clears >= int(cond.get("valor", 1))
		if ok: unlock(it.id)

# Titan bloqueado não fica no mapa (nem na baia do Refúgio, nem na Oficina das docas).
func apply_unlock_state() -> void:
	if mech.is_empty(): return
	if not is_unlocked("titan") and mech.get("occupant", -1) == -1: mech.deployed = false


# ── 0.16: atalhos de parede rachada ─────────────────────────────────────────
func open_shortcut(i: int) -> void:
	var box: Rect2 = obstacles[i]
	var kind: String = obstacle_kinds[i]
	obstacles.remove_at(i); obstacle_kinds.remove_at(i); obstacle_hp.remove_at(i)
	ob_grid_count = -1
	decor.append({"p": Vector2(box.position.x, box.end.y), "kind": kind + "_open"})
	effects.append({"p": box.get_center(), "kind": "prop_break", "life": 0.6, "max": 0.6, "prop": "sandbags"})
	build_navigation()
	say("ATALHO ABERTO • a explosão derrubou a parede!")

# ── 0.16: portões de tentáculo ──────────────────────────────────────────────
func tentacle_event_done(g: Dictionary) -> bool:
	match str(g.get("event", "")):
		"warden": return not enemies.any(func(e): return e.kind == "warden")
		"side": return side_complete
	return false

func step_tentacle_gates(dt: float) -> void:
	for g in tentacle_gates:
		if g.sealed: continue
		if tentacle_event_done(g):
			g.sealed = true
			effects.append({"p": g.p, "kind": "gate_open", "life": 0.8, "max": 0.8})
			build_navigation()
			say("A poça de tentáculos foi selada • a passagem está livre.")
			continue
		g.cd = maxf(0, g.cd - dt)
		var zone: Rect2 = g.block.grow(16)
		for a in actors:
			if not a.active or a.dead or a.jump > 0 or not zone.has_point(a.p): continue
			if g.cd <= 0:
				g.cd = 0.7
				effects.append({"p": g.p, "kind": "tentacle_strike", "life": 0.35, "max": 0.35, "dir": (a.p - g.p).normalized()})
			damage_actor(a, g.damage, "hazard", "tentacle_gate")
			var away: Vector2 = Vector2(signf(a.p.x - g.block.get_center().x), 0) if g.block.size.x < g.block.size.y * 3 else Vector2(0, signf(a.p.y - g.block.get_center().y))
			a.p = move_body(a.p, away * 300 * dt, 23 if a.mech else 11)

# 0.17: recompensas e narrativa sem consumir as chaves da expedição.
func open_reward(chest: Dictionary, a: Dictionary) -> void:
	if chest.open: return
	chest.open = true; chest["t"] = tick_time
	if mode == "run": ensure_run_stats(); run_stats.chests_opened += 1
	if a.run_weapons.has("bazooka"):
		materials += 3; heal(a, 2)
		say("SUPRIMENTOS RESGATADOS • +3 fragmentos e cura")
	else: grant_run_weapon(a, "bazooka", 3)
	effects.append({"p":chest.p,"kind":"chest_burst","life":1.3,"max":1.3,"secret":true})

func trap_phase(h: Dictionary) -> String:
	var t := fposmod(tick_time + float(h.get("offset",0)),4.0)
	return "safe" if t < 2.2 else ("warning" if t < 3.0 else "active")

func story_interact(a: Dictionary) -> void:
	if not dialogue_queue.is_empty():
		say(str(dialogue_queue.pop_front())); return
	if story_quest == 0:
		story_quest = 1
		dialogue_queue = ["A Adega Inundada abriga criaturas. Elimine todas e volte.","Eu guardo materiais e chaves para quem nos ajudar. [E para continuar]"]
		say("Pescador: o culto tomou nosso porto... [E]")
	elif story_quest == 1:
		var cellar := room_by_id("cellar")
		if visited.has("cellar") and not enemies.any(func(e): return e.hp > 0 and cellar.r.has_point(e.p)):
			story_quest = 2; materials += 4; keys += 2; heal(a,2)
			say("Pescador: você nos salvou! +4 materiais, +2 chaves e cura.")
		else: say("Pescador: limpe a Adega Inundada e volte aqui.")
	else: say("Pescador: o porto se lembrará de você, Marty.")

func boss_motion(e: Dictionary, target: Dictionary, dt: float) -> bool:
	var state: String = e.get("motion", "idle")
	if state == "idle":
		e["motion_cd"] = float(e.get("motion_cd", 2.5))-dt
		if e.motion_cd > 0: return false
		var arena: Rect2 = room_by_id("boss").get("r", Rect2(e.p-Vector2(800,600),Vector2(1600,1200)))
		var destination: Vector2 = e.p + Vector2(260*cos(e.phase*1.9),220*sin(e.phase*1.9))
		if not arena.grow(-80).has_point(destination): destination = arena.get_center()
		var reached: Vector2 = e.p
		for i in range(24): reached = move_body(reached, (destination-e.p)/24.0,45)
		destination = reached
		if not clear_at(destination,45): e.motion_cd=1.0; return false
		e["motion_to"]=destination; e["motion"]="warning"; e["motion_t"]=0.7
		e["motion_kind"]="dive" if e.hp/e.max <= 0.33 else ("charge" if e.hp/e.max <= 0.66 else "walk")
		return true
	e.motion_t -= dt
	if state == "warning":
		if e.motion_t <= 0: e.motion="moving"; e.motion_t=1.4
		return true
	var delta: Vector2 = e.motion_to-e.p
	e.p=move_body(e.p,delta.normalized()*minf(delta.length(),(440.0 if e.motion_kind == "charge" else 260.0)*dt),45)
	if e.motion_kind == "charge" and e.p.distance_to(target.p)<70: damage_actor(target,20,"boss","charge")
	if e.motion_t <= 0 or delta.length()<12:
		e.motion="idle";e.motion_cd=3.0;e.cd=maxf(e.cd,0.5)
	return true

# 0.18: ciclo comum. Chefes conservam seus próprios estados e padrões.
func attack_slots(target_id: int) -> int:
	return enemies.filter(func(e): return e.hp > 0 and e.get("target_id", -1) == target_id and e.get("combat", "") in ["warning", "attack"]).size()

func tactical_move(e: Dictionary, target: Dictionary, dt: float) -> void:
	var delta: Vector2 = target.p - e.p
	var direction := delta.normalized()
	var distance := delta.length()
	var speed: float = {"guard": 60.0, "bomber": 220.0, "crawler": 150.0, "crawler_small": 190.0, "fish": 110.0, "brute": 85.0}.get(e.kind, 110.0)
	var preferred: float = {"bomber": 30.0, "crawler": 160.0, "crawler_small": 35.0, "guard": 180.0, "fish": 310.0, "brute": 290.0}.get(e.kind, 260.0)
	var movement := direction if distance > preferred else direction.orthogonal() * (1 if int(e.id) % 2 == 0 else -1)
	if distance < preferred * 0.65: movement = -direction
	if e.kind == "bomber": movement = direction.rotated(sin(e.zigzag) * 0.65)
	elif e.kind == "crawler": movement = movement.rotated(sin(e.zigzag * 0.7) * 0.4)
	elif e.kind == "fish": movement = movement * (1.0 if fposmod(e.step, 3) < 1.7 else 0.25)
	elif e.kind == "guard": movement = direction if distance > preferred else -direction * 0.2
	e["crouched"] = false
	if e.kind == "brute" and e.combat == "recover" and e.has("cover"):
		movement = (e.cover - e.p).normalized()
		if e.p.distance_to(e.cover) < 12: movement = Vector2.ZERO; e.crouched = true
	var before: Vector2 = e.p
	e.p = move_body(e.p, movement * speed * dt, 14)
	if mode == "run" and room_at(e.p).get("kind", "") in ["entry", "maze", "story", "shop"] and room_at(e.p).get("id", "") != e.get("room", ""):
		e.p = before
	e.moving = e.p.distance_to(before) > 0.1; e.step += dt * 8

func find_cover(e: Dictionary, target: Dictionary) -> void:
	e.erase("cover")
	var best := 360.0
	for i in range(obstacles.size()):
		if i >= obstacle_kinds.size() or obstacle_kinds[i] != "sandbags": continue
		var box: Rect2 = obstacles[i]
		var candidate: Vector2 = box.get_center() + (box.get_center() - target.p).normalized() * (box.size.length() * 0.5 + 24)
		if e.p.distance_to(candidate) < best and clear_at(candidate, 16) and line_of_fire(e.p, candidate):
			best = e.p.distance_to(candidate); e["cover"] = candidate

func step_common_enemy(e: Dictionary, target: Dictionary, dt: float) -> void:
	e["combat"] = e.get("combat", "ready"); e["combat_t"] = e.get("combat_t", 0.0) - dt
	# 0.18: a reserva pertence a um alvo válido; não transferir ataque sem novo aviso.
	if e.combat in ["warning", "attack"]:
		var reserved_id: int = e.get("target_id", -1)
		if reserved_id < 0 or reserved_id >= actors.size() or not actors[reserved_id].active or actors[reserved_id].dead:
			e.combat = "ready"; e.target_id = -1; e["jump_height"] = 0.0; e["crouched"] = false; e.cd = 0.15
			return
	e.zigzag += dt * 8
	if e.get("elite", "") == "trail":
		e.trail_t -= dt
		if e.trail_t <= 0: e.trail_t = 0.65; add_combat_zone(e.p, 25, 10, "trail", 0.65, 2)
	if e.combat == "warning":
		if e.get("target_id", -1) != target.id:
			e.combat = "ready"; e.target_id = -1; e["jump_height"] = 0.0; return
		e.hurt = 0.12 if sin(e.zigzag * 2) > 0 else 0
		if e.kind != "fish": e["locked"] = target.p
		e.face = (e.locked - e.p).normalized()
		if e.combat_t <= 0:
			e.combat = "attack"; e.combat_t = GUARD_ATTACK_TIME if e.kind == "guard" else 0.7
			if e.kind in ["crawler", "crawler_small"]: emit_audio("enemy_crawler", e.p)
			e["burst"] = 0; e["burst_t"] = 0.0; e["launch"] = e.p
		return
	if e.combat == "attack":
		var direction: Vector2 = ((target.p if e.kind == "guard" else e.locked) - e.p).normalized()
		e.face = direction; e.shot = 0.15
		match e.kind:
			"guard":
				# 0.20: rajada cadenciada; durante toda a ofensiva a guarda fica aberta.
				e.burst_t -= dt
				if e.burst_t <= 0 and e.burst < GUARD_SHOTS:
					emit_audio("enemy_guard", e.p)
					add_bullet(e.p, direction, 1, 10 * e.damage_scale, 280, 7, -1, "magenta")
					e.burst += 1; e.burst_t = GUARD_SHOT_INTERVAL
			"brute":
				e.burst_t -= dt
				if e.burst_t <= 0 and e.burst < 6:
					emit_audio("enemy_brute", e.p)
					add_bullet(e.p, direction.rotated((e.burst - 2.5) * 0.13), 1, 12 * e.damage_scale, 260, 6, -1, "violet")
					bullets[-1]["source"] = e.kind; bullets[-1]["accel"] = 90.0; e.burst += 1; e.burst_t = 0.1
			"crawler", "crawler_small":
				var max_distance := 220.0 if e.kind == "crawler" else 110.0
				var goal: Vector2 = e.launch + (e.locked - e.launch).limit_length(max_distance)
				e["jump_height"] = sin(clampf(1 - e.combat_t / 0.7, 0, 1) * PI) * 65
				var before_jump: Vector2 = e.p
				e.p = move_body(e.p, (goal - e.p).limit_length(400 * dt), 14)
				if mode == "run" and room_at(e.p).get("kind", "") in ["entry", "maze", "story", "shop"] and room_at(e.p).get("id", "") != e.get("room", ""):
					e.p = before_jump
				e.moving = true
				if e.combat_t <= 0:
					e.jump_height = 0
					add_combat_zone(e.p, 58 if e.kind == "crawler" else 32, 12 * e.damage_scale, "acid", 0.15, 2.5)
			"bomber":
				emit_audio("enemy_bomber", e.p)
				e.hp = 0; e.detonated = true
				combat_blast(e.p, BOMBER_BLAST.radius, BOMBER_BLAST.damage * e.damage_scale)
			_:
				if e.burst == 0:
					emit_audio("enemy_fish" if e.kind == "fish" else "enemy_cult", e.p)
					e.burst = 1
					add_bullet(e.p, direction, 1, (22 if e.kind == "fish" else 12) * e.damage_scale, 560 if e.kind == "fish" else 230, 7, -1, "harpoon" if e.kind == "fish" else "magenta")
					bullets[-1]["source"] = e.kind
					if e.kind == "cult": bullets[-1]["split_at"] = 0.8; bullets[-1]["curve"] = 0.18
					if e.get("elite", "") == "trail": bullets[-1]["trail"] = true
					if e.kind == "fish": bullets[-1]["stake"] = true
					if e.kind == "guard":
						bullets[-1].merge({"arc": true, "from": e.p, "to": e.locked, "flight": 0.9}, true)
		if e.combat_t <= 0:
			e.combat = "recover"; e.combat_t = 1.4; e.target_id = -1
			if e.kind == "brute":
				find_cover(e, target)
				if e.has("cover"): e.combat_t = maxf(e.combat_t, e.p.distance_to(e.cover) / 85.0 + 0.7)
		return
	tactical_move(e, target, dt)
	if e.combat == "recover":
		if e.combat_t <= 0: e.combat = "ready"; e.cd = 0.15
		return
	e.cd -= dt
	if e.cd > 0 or attack_slots(target.id) >= ATTACK_LIMIT or not line_of_fire(e.p, target.p): return
	if e.kind == "bomber" and e.p.distance_to(target.p) > 100: return
	if e.kind in ["crawler", "crawler_small"] and e.p.distance_to(target.p) > 300: return
	e.combat = "warning"; e.combat_t = GUARD_WARNING if e.kind == "guard" else ATTACK_WARNING; e.target_id = target.id
	e["locked"] = target.p; e["launch"] = e.p

func add_combat_zone(p: Vector2, radius: float, damage: float, kind: String, warning: float, duration: float) -> void:
	if combat_zones.size() >= MAX_COMBAT_ZONES: return
	combat_zones.append({"p": p, "r": radius, "damage": damage, "kind": kind, "warning": warning, "life": duration, "cd": 0.0})

func step_combat_zones(dt: float) -> void:
	for stake in harpoons: stake.life -= dt
	harpoons = harpoons.filter(func(h): return h.life > 0)
	for zone in combat_zones.duplicate():
		if zone.warning > 0: zone.warning -= dt; continue
		zone.life -= dt; zone.cd -= dt
		if zone.kind == "blast":
			combat_blast(zone.p, zone.r, zone.damage); zone.life = 0; continue
		if zone.life <= 0 or zone.cd > 0: continue
		zone.cd = 0.4
		for a in actors:
			if a.active and not a.dead and a.jump <= 0 and a.p.distance_to(zone.p) < zone.r * 0.8 and line_of_fire(zone.p, a.p): damage_actor(a, zone.damage, "hazard", str(zone.kind))
	combat_zones = combat_zones.filter(func(z): return z.life > 0)

func lodge_harpoon(p: Vector2) -> void:
	if harpoons.size() >= 24 or not clear_at(p, 14): return
	for a in actors:
		if a.active and a.p.distance_to(p) < 45: return
	for door in doors:
		if door.r.grow(45).has_point(p): return
	harpoons.append({"p": p, "life": 3.5})

func combat_blast(p: Vector2, radius: float, damage: float) -> void:
	# O explode existente cuida dos barris e inimigos; jogadores respeitam paredes.
	explode(p, radius, damage, true, false, false)
	for a in actors:
		if a.active and not a.dead and a.p.distance_to(p) < radius * 0.8 and line_of_fire(p, a.p): damage_actor(a, damage, "bomber", "blast")
