class_name Expedition
extends RefCounted
const RayEncounter = preload("res://scripts/ray_encounter.gd")
const CellarPlatforms = preload("res://scripts/scenarios/cellar_platforms.gd")
const BikeHandling = preload("res://scripts/bike_handling.gd")
const TitanRecovery = preload("res://scripts/titan_recovery.gd")
const Supernova = preload("res://scripts/supernova_armor.gd")
const DOCKS := preload("res://scripts/docks_map.gd")  # não depende do cache de class_name
const ScenarioLayout := preload("res://scripts/scenario_layout.gd")
const FarolRuntime = preload("res://scripts/scenarios/farol_runtime.gd")
const ProceduralDocks = preload("res://scripts/scenarios/procedural_docks.gd")
const SanctuaryFixed = preload("res://scripts/scenarios/sanctuary_fixed.gd")
const CranesFixed = preload("res://scripts/scenarios/cranes_fixed.gd")
const WarehouseFixed = preload("res://scripts/scenarios/warehouse_fixed.gd")
const RemainingFixed = preload("res://scripts/scenarios/remaining_fixed.gd")
var scenario_modules: Dictionary = {}
var scenario_module_ids: Array = []
var procedural_enabled := false # Main game enables it; isolated legacy fixtures remain reproducible.
var layout_manifest: Dictionary = {}
var scenario_geometry_revision := 0
var run_points: Dictionary = DOCKS.POINTS.duplicate()
var run_corridors: Array = DOCKS.CORRIDORS.duplicate()
var run_secret_floors: Array = [DOCKS.SECRET_CORRIDOR]
var room_offsets: Dictionary = {}
var run_corridor_groups: Array = []
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
const ATTACK_WARNING := 0.5
const GUARD_WARNING := 0.85
const GUARD_ATTACK_TIME := 2.05
const GUARD_SHOT_INTERVAL := 0.42
const GUARD_SHOTS := 5
# Barrel tips on the canonical PixelLab body, relative to its foot pivot.
const ENEMY_MUZZLE_OFFSETS := {
	"cult": [Vector2(26, -37), Vector2(30, -39), Vector2(26, -40), Vector2(21, -38), Vector2(-29, -40), Vector2(-31, -39), Vector2(-20, -38), Vector2(-2, -36)],
	"fish": [Vector2(3.71, -42.66), Vector2(34.31, -50.07), Vector2(25.96, -48.22), Vector2(44.51, -58.42), Vector2(0, -82.53), Vector2(-45.44, -58.42), Vector2(-26.89, -48.22), Vector2(-35.24, -50.07)],
	"brute": [Vector2(37, -46), Vector2(38, -48), Vector2(26, -50), Vector2(26, -49), Vector2(-30, -49), Vector2(-37, -48), Vector2(-23, -47), Vector2(27, -46)],
	"guard": [Vector2(-34, -19), Vector2(-13, -16), Vector2(0, -12), Vector2(25, -19), Vector2(33, -24), Vector2(14, -19), Vector2(-4, -24), Vector2(-27, -29)],
}
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
var dialogue_owner := ""
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
# P6 — captura de robôs: robobolas e capturados são meta (persistem entre expedições).
var robobolas := 0
var captured_robots: Array = []
var capture_hint_seen := false
# P7 — sobreviventes que aparecem quando uma sala é limpa.
var rescue_npcs: Array = []
# P8 — golden mutante: escondido no Contrabando; depois mora no Refúgio.
var dog: Dictionary = {}
var hub_dog: Dictionary = {}
const HUB_DOG_RADIUS := 28.0
const HUB_DOG_SPEED := 28.0
const HUB_DOG_ROUTE := [Vector2(770,335),Vector2(845,345),Vector2(840,425),Vector2(770,450)]
# P9 — falas contextuais do Marty (usa randf global: não consome o rng da run).
var bark_cd := 0.0
func bark(text: String, chance: float = 1.0) -> void:
	if bark_cd > 0.0 or randf() > chance: return
	bark_cd = 8.0
	say("Marty: " + text)
# P9 — morte dramática: a run segue viva durante a queda; o relatório só abre no fim.
const DEATH_CINE_TIME := 0.95   # tempo de jogo — com slow-mo 0.25× dura ~3,8s reais
var death_cine := 0.0
var death_seq_started := false
# P10 — extração: entra na cápsula, ela fecha e some antes do relatório de vitória.
var extract_state := ""      # "" | "enter" | "close" | "launch"
var extract_t := 0.0
var extract_actor := -1
const EXTRACT_INSIDE := Vector2(0, -58)   # posição interna da cápsula relativa a extraction
func fatal_bark() -> void:
	var source := str(run_stats.get("fatal_source", ""))
	var line := "Droga... o tempo não espera ninguém."
	match source:
		"warden", "boss": line = "Grande demais... pra mim. Dessa vez."
		"lobo", "sentinela", "turret": line = "Derrubado por uma máquina enferrujada..."
		"cult", "adepto", "brute": line = "Maldição de culto... Mestre Coral vai rir disso."
		"fish", "crawler": line = "O polvo jantou primeiro."
		"hazard", "water", "gap", "explosion", "bomber": line = "Nem foi um monstro. Que vexame."
	say("Marty: " + line)
const RESCUE_NPCS := [
	{"room": "warehouse", "name": "Nadir", "weapon": "mosquete", "ammo": 20,
		"thanks": "Nadir: pensei que apodreceria no Armazém 7. Leve meu MOSQUETE 1901 — herança de família."},
	{"room": "drydock", "name": "Volt", "weapon": "tesla", "ammo": 90,
		"thanks": "Volt: viu os arcos?! Minha BOBINA TESLA é sua — impossível demais pra essa época, eu sei."},
	{"room": "rails", "name": "Bento", "weapon": "arpoador", "ammo": 30,
		"thanks": "Bento: os trilhos são seus agora. Fique com o LANÇA-ARPÕES — atravessa fila de monstro."}]
var run_materials_start := 0
var upgrade := 0
var clears := 0
var armor_unlocked := false
# 0.17: itens de equipamento liberados (id -> true). Sozinha, a simulação é um "sandbox" com tudo
# liberado (testes, arena); o jogo (main.gd) troca pelo estado do save — jogo novo = só o Padrão.
var unlocked: Dictionary = {"padrao": true, "mecanico": true, "espiao": true, "omega": true, "azul": true, "titan": true, "spectre": true}
var new_unlocks: Array = []   # desbloqueados nesta sessão ainda não salvos (main.gd salva e limpa)
var inventory_state: Dictionary = InventoryState.defaults()
var side_active := false
var side_complete := false
var side_time := 0.0
var side_failed := false
var shop_bought := false
var boss_dead := false
var boss_intro_seen := false
var secret_open := false
var tick_time := 0.0
var uid := 0
var coop := "ai"
var reward_claimed := false
# P12 — Travessia: Moto Temporal (ponte que desaba) vs Mangue Negro (a pé, miniboss).
var bike := {}                  # {"p": Vector2, "riding": bool}
var bike_npc := {}              # Faísca, o motoqueiro do amanhã — empresta a moto
var bridge_timer := -1.0        # <0 = ponte íntegra; >=0 = desabando
var bridge_broken: Array = []   # Rect2 dos segmentos que já caíram
var bridge_done := false        # travessia concluída (a ponte não se refaz depois disso)
var route_hint_seen := false
# Lore das Docas (Passo 1): story_flags sobrevive à morte (meta); os reveals são por expedição.
var story_flags := {}            # "ordem_pista" (altar), "peca_titan" e "simbolo_ordem" (1ª vitória)
var warden_intro_seen := false   # reveal do Guardião da Maré — repete a cada expedição
var first_victory_beat := false  # a vitória desta expedição entregou o story beat garantido
var whisper_cd := 0.0            # ambientação de horror: sussurros perto da água/capela
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
# Desempenho: último piso que conteve um ponto (coerência espacial) e cache de posições de inimigos já validadas.
var floor_hint := 0
var room_ok_cache: Dictionary = {}
var room_ok_sig := -1

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
		"punch": 0, "punch_t": 0.0, "slash_max": 0.45, "motion": [], "invuln": 0.0, "sp_cd": 0.0, "shadows": [],
		"last_damage_source": "unknown", "last_damage_attack": "", "run_weapons": {}, "run_weapon": "", "claw_cd": 0.0,
		"basic_weapon": "shotgun" if id == 1 and is_unlocked("mecanico") else "pistol", "knockback": Vector2.ZERO}

func fresh_run_stats() -> Dictionary:
	return {"kills": 0, "kills_by_kind": {}, "damage_dealt": 0.0, "damage_received": 0.0,
		"max_streak": 0, "chests_opened": 0, "revives": 0, "fatal_source": "unknown", "fatal_attack": ""}

func ensure_run_stats() -> void:
	if run_stats.is_empty(): run_stats = fresh_run_stats()

func hurt_enemy(enemy: Dictionary, amount: float, credit_player: bool = true) -> void:
	if RayEncounter.protected_enemy(self,enemy): return
	if enemy.get("capturable", false) and enemy.get("stunned", false): return
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
	"supernova": {"name":"ARMADURA SUPERNOVA","duration":300.0,"cooldown":60.0,"speed":430.0,"taken":1.0,"desc":"REATOR SOLAR • R ativa por 5 minutos.\nTiro: plasma solar (32 de dano).\nF / T: pulso solar (72 de dano, raio 210, recarga 6s).\n+3 corações de escudo; flutua sobre vãos."},
	"azul": {"name": "FORMA AZUL", "duration": 300.0, "cooldown": 60.0, "speed": 430.0, "taken": 1.0,
		"desc": "FORMA LUMINOSA • dura 5 min, recarrega 60s (R).\nF / botão direito ou T: garra afiada emerge sob o inimigo visível mais próximo.\n64 de dano • alcance 520 • recarga 1,2s.\n+3 CORAÇÕES DE ESCUDO • velocidade 430.\nA arma de fogo equipada continua disponível."},
	"omega": {"name": "ARMADURA ÔMEGA", "duration": 300.0, "cooldown": 60.0, "speed": 430.0, "taken": 1.0,
		"desc": "LENDÁRIA • dura 5 min, recarrega 60s (R).\nComeça cada expedição carregada; baús recarregam na hora.\nR2 / clique esquerdo: combo de 3 esferas (38/38/64);\na 3ª esfera é maior e atravessa inimigos.\nSegure T: raio de luz por até 3s; recarga de 30s.\nAo guardar, luz atinge inimigos próximos visíveis.\n+3 CORAÇÕES DE ESCUDO • MUITO mais rápido (430) • energia reflete tiros.\nEsferas substituem a arma enquanto ativa; a arma anterior volta ao guardar."}}
const OUTFIT_NAMES := {"padrao": "PADRÃO", "mecanico": "MECÂNICO", "espiao": "ESPIÃO", "omega": "ARMADURA ÔMEGA", "azul": "FORMA AZUL"}

# Enrage do Almirante: sem isso a luta podia travar indefinidamente contra um time passivo.
# 0.22: chefe maior, mais rápido e mais forte (pedido direto de dificuldade/impacto).
const BOSS_RADIUS := 70.0
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
const BLUE_CLAW_RANGE := 520.0
const BLUE_CLAW_DAMAGE := 64.0
const BLUE_CLAW_COOLDOWN := 1.2

func is_blue_form(a: Dictionary) -> bool:
	return a.get("armor", false) and a.get("armor_type", "omega") == "azul"

func max_hp() -> float:
	# 0.14: todos começam SEMPRE com 3 corações. As melhorias da bancada estão congeladas até
	# definirmos a progressão de vida (o valor "upgrade" continua salvo para não perder o progresso).
	return BASE_HEARTS * HEART

func heart_damage(amount: float) -> float:
	return HEART if amount > 0.0 else 0.0

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
		say("%s ATIVADA!" % ARMORS[a.armor_type].name)
	else:
		if a.beam_time > 0: stop_omega_beam(a)
		if a.armor_type == "omega": recall_light(a)
		a["shadows"] = []
		effects.append({"p": a.p, "kind": "power_down", "life": 0.45, "max": 0.45})

func stop_omega_beam(a: Dictionary) -> void:
	a.beam_time = 0.0
	a.beam_cd = OMEGA_BEAM_COOLDOWN

const OMEGA_BLINK := 320.0        # distância do teleporte (dash comum anda ~180px)
const OMEGA_SHADOW_LIFE := 4.0    # cada sombra some depois disso
const OMEGA_SHADOW_MAX := 3       # acumulo máximo
const OMEGA_BLINK_CD := 0.55      # intervalo entre teleportes
const OMEGA_RETURN_CD := 1.6      # intervalo depois de voltar numa sombra

func live_shadows(a: Dictionary) -> Array:
	var out: Array = []
	for s in a.get("shadows", []):
		if tick_time - float(s.t) < OMEGA_SHADOW_LIFE: out.append(s)
	return out

# Ômega: Shift+direção teleporta e deixa uma sombra na origem; Shift parado volta pra sombra mais recente.
func omega_blink(a: Dictionary, moving: Vector2) -> void:
	if moving.length() < 0.1:
		omega_return(a); return
	var shadows := live_shadows(a)
	shadows.append({"p": a.p, "t": tick_time})
	while shadows.size() > OMEGA_SHADOW_MAX: shadows.pop_front()
	a["shadows"] = shadows
	emit_audio("dash", a.p)
	effects.append({"p": a.p, "kind": "blink", "life": 0.3, "max": 0.3})
	# Teleporte cruza brechas (airborne) mas para antes de parede/portão.
	a.p = move_body(a.p, moving.normalized() * OMEGA_BLINK, 11, true)
	a.invuln = 0.25; a.roll_visual = 0.28; a.dodge_cd = OMEGA_BLINK_CD
	effects.append({"p": a.p, "kind": "blink", "life": 0.3, "max": 0.3})

func omega_return(a: Dictionary) -> void:
	var shadows := live_shadows(a)
	if shadows.is_empty():
		a.dodge_cd = 0.35; return  # sem sombra viva: dodge entra em recarga curta e nada acontece
	var dest: Vector2 = shadows.back().p
	shadows.pop_back(); a["shadows"] = shadows
	emit_audio("dash", a.p)
	effects.append({"p": a.p, "kind": "blink", "life": 0.3, "max": 0.3})
	a.p = dest
	a.invuln = 0.3; a.roll_visual = 0.28; a.dodge_cd = OMEGA_RETURN_CD
	effects.append({"p": a.p, "kind": "blink", "life": 0.3, "max": 0.3})

func omega_beam_endpoint(from: Vector2, direction: Vector2) -> Vector2:
	var end := from + direction * OMEGA_BEAM_RANGE
	for n in range(1, int(OMEGA_BEAM_RANGE / 10.0) + 1):
		var point := from + direction * (n * 10.0)
		if not clear_at(point, 0.0, true): return from + direction * ((n - 1) * 10.0)
	return end

func recall_light(a: Dictionary) -> void:
	var screen := visible_world_rect if visible_world_rect.has_area() else Rect2(a.p - Vector2(640, 400), Vector2(1280, 800))
	for e in enemies:
		if e.hp <= 0 or e.p.distance_to(a.p) > OMEGA_RECALL_RANGE or (coop != "online" and not screen.has_point(e.p)) or not line_of_fire(a.p, e.p): continue
		hurt_enemy(e, OMEGA_RECALL_DAMAGE); e.hurt = 0.2; e.alerted = true
		pop_dmg(e.p, OMEGA_RECALL_DAMAGE, true)
		effects.append({"p": a.p, "to": e.p, "kind": "recall_light", "life": 0.42, "max": 0.42})

func transform_burst(a: Dictionary) -> void:
	effects.append({"p": a.p, "kind": "shockwave", "life": 0.55, "max": 0.55})
	for e in enemies:
		var d: float = e.p.distance_to(a.p)
		if d < 190:
			hurt_enemy(e, 40.0 if e.kind != "boss" else 25.0); e.hurt = 0.2
			if e.kind != "boss": e.p = move_enemy_body(e, (e.p - a.p).normalized() * (190 - d) * 0.6, 14)
	for b in bullets:
		if b.team == 1 and b.p.distance_to(a.p) < 240: b.life = 0

func outfit_of(a: Dictionary) -> String:
	return a.get("armor_type", "omega") if a.armor else a.get("outfit", "padrao")

func new_mech(pos: Vector2) -> Dictionary:
	# 0.14: o Titan consome gasolina enquanto pilotado — começa com tanque parcial.
	return {"p": pos, "hp": 240.0, "fuel": 70.0, "occupant": -1, "aim": Vector2.RIGHT, "move_dir": Vector2.DOWN,
		"step": 0.0, "deployed": true, "owner": -1}

func reset_spectres() -> void:
	spectres = []
	for a in actors:
		spectres.append({"owner": a.id, "state": "stored", "hp": SPECTRE_HP, "p": a.p, "aim": Vector2.RIGHT,
			"move_dir": Vector2.DOWN, "shot": 0.0, "kind": "spectre"})

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
	dialogue_queue.clear(); dialogue_owner = ""
	audio_events.clear()
	doors.clear(); gate_blocks.clear(); hazards.clear(); tentacle_gates.clear()
	mode = "hub"
	money = 0; keys = 0  # 0.21: moeda e chaves não atravessam o portal temporal.
	pending_spawns.clear()   # 0.15: portais atrasados da arena não atravessam para o Refúgio
	death_cine = 0.0; death_seq_started = false
	extract_state = ""; extract_t = 0.0; extract_actor = -1
	var selected_armors: Array = actors.map(func(a): return a.get("armor_type", "omega"))
	actors = [actor(0, Vector2(760, 440)), actor(1, Vector2(820, 450))]
	for a in actors:
		if a.id < selected_armors.size() and selected_armors[a.id] in ARMORS: a.armor_type = selected_armors[a.id]
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

func start_new_run() -> void:
	var chooser := RandomNumberGenerator.new()
	chooser.randomize()
	var next_seed := int(chooser.randi() & 0x7fffffff)
	if next_seed == seed_value: next_seed = (next_seed + 1) & 0x7fffffff
	start_run(next_seed)

func start_run(new_seed: int) -> void:
	dialogue_queue.clear(); dialogue_owner = ""
	layout_manifest.clear(); room_offsets.clear()
	run_corridor_groups.clear()
	run_points = DOCKS.POINTS.duplicate(); run_corridors = DOCKS.CORRIDORS.duplicate(); run_secret_floors = [DOCKS.SECRET_CORRIDOR]
	audio_events.clear()
	# Mapa fixo (scripts/docks_map.gd). A seed só sorteia os tipos de inimigo e pequenos desvios.
	pending_spawns.clear()   # 0.15: nenhuma onda da arena pode vazar para uma expedição
	seed_value = new_seed; rng.seed = seed_value
	run_stats = fresh_run_stats(); last_run_summary = {}
	mode = "run"; tick_time = 0; money = 12; keys = 1; run_materials_start = materials
	streak = 0; streak_t = 0.0; hitstop = 0.0; clutch_t = 0.0; clutch_cd = 0.0
	side_active = false; side_complete = false; side_failed = false; shop_bought = false
	boss_dead = false; boss_intro_seen = false; secret_open = false; reward_claimed = false
	death_cine = 0.0; death_seq_started = false
	extract_state = ""; extract_t = 0.0; extract_actor = -1
	warden_intro_seen = false; first_victory_beat = false; whisper_cd = 4.0
	var P: Dictionary = DOCKS.POINTS
	var selected_armors: Array = actors.map(func(a): return a.get("armor_type", "omega"))
	actors = [actor(0, P.spawn), actor(1, P.spawn2)]
	for a in actors:
		if a.id < selected_armors.size() and selected_armors[a.id] in ARMORS: a.armor_type = selected_armors[a.id]
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
	raised = DOCKS.RAISED.duplicate(); ramps = DOCKS.RAMPS.duplicate(true); gaps = ScenarioLayout.composed_gaps(DOCKS.GAPS)
	jump_gap = gaps[0]
	build_doors(); hazards = DOCKS.HAZARDS.duplicate(true)
	obstacle_hp.clear(); fuses.clear()
	for o in ScenarioLayout.composed_obstacles(DOCKS.OBSTACLES, rooms):
		obstacles.append(Rect2(o[0], o[1], o[2], o[3])); obstacle_kinds.append(o[4]); obstacle_hp.append(DESTRUCTIBLE.get(o[4], -1.0))
	# 0.16: parede rachada A, B ou C em cada atalho (sorteada pela seed, sem mexer no rng dos inimigos)
	for i in DOCKS.SHORTCUTS.size():
		obstacles.append(DOCKS.SHORTCUTS[i].wall); obstacle_kinds.append("wall_crack_" + ["a", "b", "c"][posmod(seed_value * 31 + i * 17, 3)]); obstacle_hp.append(-1.0)
	tentacle_gates = DOCKS.TENTACLE_GATES.duplicate(true)
	for g in tentacle_gates: g["sealed"] = false; g["cd"] = 0.0
	for d in ScenarioLayout.composed_decor(DOCKS.DECOR, rooms):
		var item := {"p": Vector2(d[0], d[1]), "kind": d[2]}
		if d.size() > 3: item.merge(d[3])
		decor.append(item)
	for c in DOCKS.CHESTS: chests.append({"p": Vector2(c[0], c[1]), "open": false, "secret": c[2]})
	mech = new_mech(P.mech); apply_unlock_state()
	bike = {"p": P.bike, "riding": false}
	bike_npc = {"p": P.bike + Vector2(-80, -20), "talked": false}
	bridge_timer = -1.0; bridge_broken.clear(); bridge_done = false; route_hint_seen = false
	reset_spectres()
	FarolRuntime.install_geometry(self)
	refresh_chapel_geometry()
	scenario_geometry_revision = 2
	# 0.22: menos inimigos espalhados pelo mapa, porém mais fortes (ver hp em spawn_enemy) —
	# pedido para dar mais peso a cada combate em vez de enxames. ~20% das entradas ficam de fora,
	# sorteado pela seed da expedição (reproduzível, não falha reachability pois não remove inimigos
	# únicos de missão como boss/warden, só a população comum do mapa).
	var enemy_thin_chance := 0.2
	for sp in DOCKS.SPAWNS:
		var entry_spawn: bool = room_at(Vector2(sp[0], sp[1])).get("id", "") == "entry"
		if rng.randf() < enemy_thin_chance and not entry_spawn: continue
		var pos := Vector2(sp[0], sp[1]) + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
		if not clear_at(pos, 16): pos = Vector2(sp[0], sp[1])
		spawn_enemy(pos, sp[2])
		if entry_spawn: enemies[-1]["onboarding_wait"] = str(sp[2]) != "crawler"
	spawn_enemy(P.boss, "boss")
	spawn_enemy(P.warden, "warden")
	# P6: LOBO-9 guarda as robobolas no Mercado; o Sentinela corrompido dorme no
	# fundo do Pátio dos Guindastes — acorda quando o jogador chega perto.
	var lobo_room := room_by_id("market")
	if not lobo_room.is_empty(): spawn_enemy(lobo_room.r.get_center(), "lobo")
	var sentinel_room := room_by_id("cranes")
	if not sentinel_room.is_empty():
		var sr: Rect2 = sentinel_room.r
		var sentinel_pos := Vector2(sr.end.x - 240, sr.get_center().y)
		if not clear_at(sentinel_pos, 20): sentinel_pos = sr.get_center()
		spawn_enemy(sentinel_pos, "golem")
	# A separate corrupted copy waits at the eastern workshop, capturable normally.
	TitanRecovery.install_copy(self)
	# P12: RAÍZ-PODRE guarda o coração do Mangue Negro — miniboss da rota a pé.
	var forest_room := room_by_id("forest")
	if not forest_room.is_empty():
		var fpos: Vector2 = forest_room.r.get_center()
		if not clear_at(fpos, 20): fpos += Vector2(140, 0)
		spawn_enemy(fpos, "brute")
		var fboss: Dictionary = enemies[-1]
		fboss["miniboss"] = true; fboss.hp = 340; fboss["boss_name"] = "RAÍZ-PODRE"
	pickups.append({"p": P.key, "kind": "key"})
	pickups.append({"p": P.spawn + Vector2(165, 0), "kind": "weapon", "weapon": "bazooka", "ammo": 30})
	build_navigation()
	say("Docas de 1941 • recupere o núcleo do Almirante. TAB/M abre o mapa. Armadura Ômega pronta.")
	if procedural_enabled and not CranesFixed.FIXED_PILOT:
		var generated := ProceduralDocks.generate(self)
		if not generated.ok:
			layout_manifest = {"ok":false,"fallback":"legacy","errors":generated.get("errors",[]),"seed":str(seed_value)}
			push_warning("Procedural layout rejected; legacy fallback: "+str(generated.get("errors",[])))
			say("Não foi possível montar esta seed. Docas de segurança carregadas; uma nova expedição tentará outro mapa.")
	if CranesFixed.FIXED_PILOT:
		layout_manifest={"version":"fixed-art-pilot-v1","seed":str(seed_value),"fixed_rooms":["entry","chapel","cranes","warehouse"]}
	if scenario_geometry_revision<3:
		SanctuaryFixed.install(self)
		build_navigation()
	if scenario_geometry_revision<4:
		CranesFixed.install(self)
		build_navigation()
	if scenario_geometry_revision<5:
		WarehouseFixed.install(self)
		build_navigation()
	RemainingFixed.install(self)
	CellarPlatforms.install(self)
	SanctuaryFixed.align_east_passage(self)
	SanctuaryFixed.align_south_passage(self)
	build_navigation()

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
		"warden": ["O Guardião da Maré carimbou sua passagem só de ida para o Refúgio."],
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
		"story_beat": first_victory_beat,
		"armor_seconds": float(run_stats.get("armor_seconds", 0.0)),
		"airborne_seconds": float(run_stats.get("airborne_seconds", 0.0)),
		"obituary": victory_note() if outcome == "victory" else obituary_for(fatal_source, fatal_attack)
	}.duplicate(true)
	summary_seq += 1
	make_hub()
	return last_run_summary

# A primeira vitória garante a peça do Titan e a pista da Ordem — nunca depende de sorte.
func victory_note() -> String:
	if not first_victory_beat: return "Núcleo recuperado. O tempo perdeu esta rodada."
	return "Núcleo para restaurar o Titan recuperado. O medalhão da ORDEM DA MARÉ NEGRA coincide com a assinatura do ataque à nave. No núcleo, uma mensagem de Letícia: 'Estou viva. Sigo a luz da nossa nave.' O Refúgio guardou o sinal para localizar sua era."

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
			for f: Rect2 in run_corridors:
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
	# The long routes touch the arena directly; their mouths still need combat gates.
	if not room_by_id("bridge").is_empty():
		var forest_rect: Rect2 = room_by_id("forest").r
		doors.append({"r": Rect2(forest_rect.end.x - DOOR_DEPTH, forest_rect.position.y, DOOR_DEPTH, forest_rect.size.y), "room": "forest", "side": "right"})
		for route_id in ["bridge", "forest"]:
			var route_rect: Rect2 = room_by_id(route_id).r
			doors.append({"r": Rect2(route_rect.end.x - DOOR_DEPTH, route_rect.position.y, DOOR_DEPTH, route_rect.size.y), "room": "boss", "side": "left"})

func room_contains(room: Dictionary, p: Vector2, margin: float = 0.0) -> bool:
	# 0.19: alcovas estreitas não podem gerar Rect2 negativo ao testar margem interna.
	for rect: Rect2 in [room.r] + room.get("extra", []):
		var inner := rect.grow(margin)
		if inner.size.x > 0 and inner.size.y > 0 and inner.has_point(p): return true
	return false

func visible_corridor_rects() -> Dictionary:
	var visible := {}
	for group in run_corridor_groups:
		if group.hidden and not secret_open: continue
		var discovered: bool = visited.has(group.from) or visited.has(group.to)
		if not discovered:
			for actor in actors:
				if actor.active and group.rects.any(func(rect): return rect.has_point(actor.p)): discovered = true; break
		if discovered:
			for rect in group.rects: visible[rect] = true
	return visible

func room_by_id(id: String) -> Dictionary:
	for room in rooms:
		if room.get("id", "") == id: return room
	return {}

# Enemies keep their encounter ownership even when attacks push them toward a door.
func enemy_room_radius(e: Dictionary) -> float:
	return BOSS_RADIUS if e.kind == "boss" else (48.0 if e.kind == "warden" else (12.0 if e.kind == "crawler_small" else 14.0))

func enemy_room_position_valid(e: Dictionary, point: Vector2, radius: float) -> bool:
	var owner := room_by_id(str(e.get("room", "")))
	if not owner.is_empty():
		for offset in [Vector2.ZERO, Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
			if not room_contains(owner, point + offset): return false
	return clear_at(point, radius)

func room_validity_sig() -> int:
	var unsealed := 0
	for tg in tentacle_gates:
		if not tg.sealed: unsealed += 1
	return floors.size() + gaps.size() * 131 + obstacles.size() * 17161 + gate_blocks.size() * 2248091 + harpoons.size() * 294499921 + unsealed * 7

func recover_enemy_room(e: Dictionary) -> void:
	if mode != "run" or e.hp <= 0: return
	var sig := room_validity_sig()
	if sig != room_ok_sig: room_ok_cache.clear(); room_ok_sig = sig
	var cached: Array = room_ok_cache.get(e.id, [])
	if not cached.is_empty() and cached[0] == e.p and cached[1] == str(e.get("room", "")) and tick_time >= float(cached[2]) and tick_time - float(cached[2]) < 0.25: return
	var owner := room_by_id(str(e.get("room", "")))
	if owner.is_empty():
		# Legacy saves and jittered spawns may have lost their encounter assignment.
		owner = room_at(e.p)
		if owner.is_empty():
			var nearest_distance := INF
			for room in rooms:
				if not room.has("id") or room.get("kind", "") in ["entry", "story", "shop", "secret", "maze"]: continue
				for rect: Rect2 in [room.r] + room.get("extra", []):
					var nearest := Vector2(clampf(e.p.x, rect.position.x, rect.end.x), clampf(e.p.y, rect.position.y, rect.end.y))
					var distance: float = nearest.distance_squared_to(e.p)
					if distance < nearest_distance: owner = room; nearest_distance = distance
		if owner.is_empty(): return
		e["room"] = str(owner.get("id", ""))
	var radius := enemy_room_radius(e)
	if enemy_room_position_valid(e, e.p, radius):
		room_ok_cache[e.id] = [e.p, str(e.get("room", "")), tick_time]
		return
	# Prefer the player's connected free space when recovering a legacy/off-floor spawn.
	var reference: Vector2 = e.p
	var player_present := false
	for a in actors:
		if a.active and not a.dead and room_contains(owner, a.p):
			reference = a.p; player_present = true; break
	var best := Vector2.INF
	var distance := INF
	for rect: Rect2 in [owner.r] + owner.get("extra", []):
		for y in range(int(rect.position.y + radius + 1), int(rect.end.y - radius), 32):
			for x in range(int(rect.position.x + radius + 1), int(rect.end.x - radius), 32):
				var candidate := Vector2(x, y)
				var candidate_distance := candidate.distance_squared_to(reference)
				if candidate_distance >= distance or not enemy_room_position_valid(e, candidate, radius): continue
				if player_present and not line_of_fire(reference, candidate): continue
				best = candidate; distance = candidate_distance
	if best != Vector2.INF:
		e.p = best; e["combat"] = "ready"; e["combat_t"] = 0.0
		e["attack_state"] = "hunt"; e["attack_time"] = 0.0
		e["jump_height"] = 0.0; e["motion"] = "idle"; e["motion_t"] = 0.0
		e["moving"] = false
		e.erase("cover")

func move_enemy_body(e: Dictionary, movement: Vector2, radius: float, origin: Vector2 = Vector2.INF) -> Vector2:
	var position: Vector2 = e.p if origin == Vector2.INF else origin
	if mode != "run" or str(e.get("room", "")) == "": return move_body(position, movement, radius)
	var count := maxi(1, int(ceil(movement.length() / 6.0)))
	var increment := movement / count
	for _i in range(count):
		var next := move_body(position, increment, radius)
		if not enemy_room_position_valid(e, next, radius): break
		position = next
	return position

func room_threats(id: String) -> int:
	# Atordoado não tranca a sala: sem robobola o jogador poderia sair e voltar depois.
	return enemies.filter(func(e): return e.get("room", "") == id and not e.side and not e.get("stunned", false) and not RayEncounter.owns(self,e)).size()

func refresh_gate_blocks() -> void:
	gate_blocks.clear()
	for d in doors:
		if room_by_id(d.room).get("locked", false): gate_blocks.append(d.r)

func room_threat_counts() -> Dictionary:
	var counts := {}
	for e in enemies:
		if e.side or e.get("stunned", false) or RayEncounter.owns(self, e): continue
		var id: String = e.get("room", "")
		counts[id] = int(counts.get(id, 0)) + 1
	return counts

func step_gates(_step_dt: float = 0.016) -> void:
	for enemy in enemies: recover_enemy_room(enemy)
	var threats := room_threat_counts()
	var changed := false
	for room in rooms:
		if not room.has("id") or room.kind == "secret": continue
		if room.get("id", "") == "bridge": continue
		if room.get("locked", false):
			if int(threats.get(room.id, 0)) == 0:
				room.locked = false; room.cleared = true; changed = true
				say("SALA LIMPA • os portões se abriram!")
				bark("Você viu isso? A gente tá ficando bom nisso.", 0.18)
				for d in doors:
					if d.room == room.id: effects.append({"p": d.r.get_center(), "kind": "gate_open", "life": 0.8, "max": 0.8})
				for npc_def in RESCUE_NPCS:
					if npc_def.room == room.id: spawn_rescue_npc(npc_def)
		elif not room.get("cleared", false):
			if coop != "ai" and room.id == "boss" and not room_by_id("bridge").is_empty() and actors.any(func(a): return a.active and not a.dead and not room_contains(room, a.p)):
				continue # Split-route co-op players enter by their own route before sealing the arena.
			var inside: Dictionary = {}
			for a in actors:
				if a.active and not a.dead and room_contains(room, a.p, -50): inside = a; break
			if inside.is_empty(): continue
			if int(threats.get(room.id, 0)) == 0:
				room.cleared = true
				for npc_def in RESCUE_NPCS:
					if npc_def.room == room.id: spawn_rescue_npc(npc_def)
				continue
	# P8 — step_dog cuida do encontro; roda em run (escondido) e hub (depois de resgatado).
			room.locked = true; changed = true
			say("PORTÕES FECHADOS • elimine todos os inimigos da sala!")
			for d in doors:
				if d.room == room.id: effects.append({"p": d.r.get_center(), "kind": "gate_slam", "life": 0.5, "max": 0.5})
			# quem ficou do lado de fora é puxado para dentro (ninguém fica preso no corredor)
			for a in actors:
				if coop == "ai" and a.id == 1: continue # Reunite after gate collision is updated.
				if not room_by_id("bridge").is_empty() and room.id in ["antessala", "forest", "boss"]: continue
				if a.active and not a.dead and not room_contains(room, a.p):
					var spot: Vector2 = inside.p + Vector2(-50, 30)
					a.p = spot if clear_at(spot, 23 if a.mech else 11) else inside.p
					if a.mech: mech.p = a.p
	if changed: refresh_gate_blocks()
	reunite_ai_at_closed_gate()

func reunite_ai_at_closed_gate() -> void:
	if coop != "ai" or actors.size()<2: return
	var leader: Dictionary=actors[0]
	var companion: Dictionary=actors[1]
	if not leader.active or not companion.active or companion.dead: return
	var radius:=23.0 if companion.mech else 11.0
	for room in rooms:
		if not room.get("locked",false) or not room_contains(room,leader.p,-radius): continue
		if room_contains(room,companion.p,-radius) and not gate_blocks.any(func(gate):return gate.grow(radius).has_point(companion.p)): return
		# Search around the leader after the doors close, rather than using an
		# unchecked offset which can land outside the room or inside its gate.
		for distance in [56.0,88.0,128.0,176.0,0.0]:
			for i in 12:
				var point: Vector2=leader.p+Vector2.RIGHT.rotated(i*TAU/12.0)*distance
				if not room_contains(room,point,-radius) or not clear_at(point,radius): continue
				if enemies.any(func(e):return e.hp>0 and not e.get("stunned",false) and e.p.distance_to(point)<radius+28): continue
				if combat_zones.any(func(z):return z.p.distance_to(point)<z.r+radius): continue
				companion.p=point; companion.jump=0.0; companion.dodge=0.0
				companion["jump_from"]=point; companion["knockback"]=Vector2.ZERO
				companion.move=Vector2.ZERO; companion.roll_visual=0.0
				if companion.mech: mech.p=point
				ai_path.clear(); ai_path_timer=0.0
				return

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
	# O Almirante sustenta uma luta mais longa que os inimigos comuns.
	# 0.22: guard (escudo, sala 02 • Pátio dos Guindastes) muito mais resistente —
	# pedido para ser um obstáculo de peso, não só mais um mob comum.
	var hp: float = {"boss": 900.0, "brute": 95.0, "fish": 66.0, "crawler": 45.0, "crawler_small": 18.0,
		"bomber": 24.0, "guard": 150.0}.get(kind, 52.0)
	if kind == "warden": hp = 420.0
	elif kind == "lobo": hp = 380.0
	elif kind == "sentinela": hp = 330.0
	elif kind == "golem": hp = 480.0
	elif kind != "boss": hp *= 1.25
	enemies.append({"id": uid, "p": pos, "kind": kind, "hp": hp, "max": hp, "cd": rng.randf_range(0.5, 1.5), "phase": 0, "hurt": 0.0, "side": optional,
		"room": room_at(pos).get("id", "") if mode == "run" else "",
		"face": Vector2.DOWN, "moving": false, "shot": 0.0, "stage": 1, "charge": 0.0, "spin": 0.0, "spin_angle": 0.0, "step": 0.0,
		"fight_time": 0.0, "enraged": false, "fuse": -1.0, "zigzag": rng.randf_range(0.0, TAU), "detonated": false, "damage_scale": 1.0, "combat": "ready", "combat_t": 0.0, "target_id": -1, "elite": "", "trail_t": 0.0})
	if kind in ["sentinela", "golem"]:
		enemies[-1]["dormant"] = true; enemies[-1]["capturable"] = true
	# Modificador único, reproduzível pela seed; a entrada e salas seguras ficam livres.
	var room_id: String = room_at(pos).get("id", "")
	if mode == "run" and room_id not in ["", "entry", "dock", "landing", "spawn", "chapel", "warehouse", "shop", "secret"] and kind not in ["boss", "warden", "crawler_small", "lobo", "sentinela", "golem"] and rng.randf() < 0.16:
		enemies[-1].elite = ["shield", "trail", "explosive"][rng.randi_range(0, 2)]

	recover_enemy_room(enemies[-1])

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

func on_floor(p: Vector2) -> bool:
	if floor_hint < floors.size() and floors[floor_hint].has_point(p): return true
	for i in floors.size():
		if floors[i].has_point(p): floor_hint = i; return true
	return false

func clear_at(pos: Vector2, radius: float, airborne: bool = false) -> bool:
	if not airborne and CellarPlatforms.water_at(self,pos,radius): return false
	if not on_floor(pos): return false
	if radius != 0.0 and not (on_floor(pos + Vector2(radius, 0)) and on_floor(pos - Vector2(radius, 0)) and on_floor(pos + Vector2(0, radius)) and on_floor(pos - Vector2(0, radius))): return false
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
		if e.hp <= 0 or e.get("stunned", false) or e.get("onboarding_wait", false): continue
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
	# Rescue takes priority over combat and optional interactions.
	if leader.dead and leader.active and not a.mech:
		return {"move": path_direction(a.p, leader.p), "aim": a.aim, "interact": a.p.distance_to(leader.p) < 75}
	if not a.mech and a.run_weapons.has(a.get("run_weapon", "")) and int(a.run_weapons[a.run_weapon]) <= 0:
		a.run_weapon = ""
		for candidate in a.run_weapons:
			if int(a.run_weapons[candidate]) > 0:
				a.run_weapon = candidate; break
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
	if a.armor and a.armor_type == "omega" and not a.mech and not a.fused and not a.get("bike",false) and a.get("transform",0.0)<=0:
		ai_omega_abilities(a,target,command)
	if leader.dead:
		command.move = path_direction(a.p, leader.p)
		if delta_pos.length() < 75: command.interact = true
	elif not a.armor and not a.mech and not a.fused and not target.is_empty() and mech.deployed and mech.occupant == -1 and mech.hp > 0 and a.p.distance_to(mech.p) < 220:
		command.move = (mech.p - a.p).normalized()
		if a.p.distance_to(mech.p) < 80: command.interact = true
	if leader.jump > 0: command.jump = true
	if mode == "run":
		for gap in gaps:
			if gap.grow(35).has_point(a.p): command.jump = true
	return command

func ai_omega_abilities(a: Dictionary, target: Dictionary, command: Dictionary) -> void:
	if target.is_empty(): return
	var distance: float=a.p.distance_to(target.p)
	var visible:=line_of_fire(a.p,target.p)
	# Hold the command for the whole channel; release when the target is obstructed.
	if visible and distance<=OMEGA_BEAM_RANGE-24 and (a.beam_time>0 or (a.beam_cd<=0 and distance>125)):
		command["special"]=true
		command["move"]=Vector2.ZERO
	elif visible and distance<=120:
		command["fire"]=true
		command["melee"]=false
		command["move"]=Vector2.ZERO
	# Reposition while the beam recharges, or evade the projectile already detected.
	var evade: bool=command.get("dodge",false)
	if a.dodge_cd>0:
		command.erase("dodge")
		return
	if not evade and not (visible and distance>430 and a.beam_cd>0): return
	var shadows:=live_shadows(a)
	if evade and not shadows.is_empty():
		var back: Vector2=shadows.back().p
		if ai_omega_landing_safe(back) and back.distance_to(target.p)>150 and back.distance_to(actors[0].p)<550:
			command["dodge"]=true; command["move"]=Vector2.ZERO
			return
	var direction: Vector2=command.get("move",Vector2.ZERO) if evade else (target.p-a.p).normalized()
	# Beam aiming may have stopped movement; retain a perpendicular escape option.
	if direction.length()<0.1: direction=(target.p-a.p).normalized().orthogonal()
	var destination:=move_body(a.p,direction.normalized()*OMEGA_BLINK,11,true)
	if destination.distance_to(a.p)>80 and destination.distance_to(target.p)>100 and destination.distance_to(actors[0].p)<550 and ai_omega_landing_safe(destination):
		command["dodge"]=true; command["move"]=direction
	else:
		command.erase("dodge")

func ai_omega_landing_safe(position: Vector2) -> bool:
	if not clear_at(position,11): return false
	if not room_by_id("bridge").is_empty() and bridge_zone().has_point(position): return false
	for zone in combat_zones:
		if position.distance_to(zone.p)<float(zone.r)+20: return false
	for hazard in hazards:
		if position.distance_to(hazard.p)<float(hazard.r)+20: return false
	return true

func step(dt: float, commands: Array) -> void:
	tick_time += dt; message_time = maxf(0, message_time - dt)
	ai_path_timer -= dt
	clutch_t = maxf(0, clutch_t - dt); clutch_cd = maxf(0, clutch_cd - dt)
	streak_t = maxf(0, streak_t - dt)
	if streak_t <= 0: streak = 0
	bark_cd = maxf(0.0, bark_cd - dt)
	for a in actors:
		if a.dead: a["dead_t"] = a.get("dead_t", 0.0) + dt
	for a in actors:
		if not a.active: continue
		var cmd: Dictionary = commands[a.id] if commands.size() > a.id else {}
		if a.id == 1 and coop == "ai": cmd = ai_input()
		step_actor(a, cmd, dt)
	# Bullets must advance in every scene, including the refuge and training arena.
	step_spectres(dt); step_enemies(dt); step_bullets(dt); collect_pickups(); step_dog(dt)
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
				if not room.is_empty() and not visited.has(room.id):
					visited.append(room.id); check_unlocks()
					if room.id == "boss": bark("Sinto cheiro de enxofre... e de derrota. A dele.", 1.0)
					elif room.id == "antessala" and not route_hint_seen:
						route_hint_seen = true
						story_flags["rotas_docas"] = true
						say("DUAS ROTAS PARA LESTE • ÔMEGA: pegue a MOTO TEMPORAL e acelere pela ponte por cerca de 20 segundos. A pé: siga pelo MANGUE NEGRO e enfrente RAÍZ-PODRE. O Almirante espera no fim.")
		step_gates(dt)
		# Reveal depois dos portões: o nome do Guardião não pode ser sobreposto pelo aviso de sala trancada.
		if not warden_intro_seen:
			for e in enemies:
				if e.kind != "warden": continue
				for a in actors:
					if a.active and not a.dead and a.p.distance_to(e.p) < 620:
						warden_intro_seen = true
						say("GUARDIÃO DA MARÉ • a máquina do cais, possuída pelo culto, selou os trilhos.")
						break
				if warden_intro_seen: break
		# Sussurros da fissura: capela, adega ou beira de canal. Sem tocar no rng da expedição.
		whisper_cd = maxf(0.0, whisper_cd - dt)
		if whisper_cd <= 0.0:
			for a in actors:
				if a.active and not a.dead and (room_at(a.p).get("id", "") in ["chapel", "cellar"] or near_water(a.p)):
					emit_audio("whisper", a.p); whisper_cd = 7.0 + fposmod(tick_time * 37.0, 5.0); break
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
			if not death_seq_started:
				death_seq_started = true; death_cine = DEATH_CINE_TIME
				fatal_bark()
			elif death_cine > 0.0:
				death_cine -= dt
				if death_cine <= 0.0:
					death_cine = 0.0; death_seq_started = false
					finish_run("death"); say("A âncora temporal resgatou a equipe. Confira o relatório.")
		elif death_seq_started:
			death_seq_started = false; death_cine = 0.0   # reanimou a tempo — o tempo perdoou
		step_bridge(dt)
		step_extraction(dt)
	for fx in effects: fx.life -= dt
	effects = effects.filter(func(fx): return fx.life > 0)

# P12 — travessia de moto: a Ponte Temporal desaba atrás do piloto. Cair na água volta
# ao checkpoint com a ponte remontada para a próxima tentativa.
func step_bridge(dt: float) -> void:
	if bike.is_empty(): return
	var zone := bridge_zone()
	var segs := bridge_segments()
	if bridge_timer < 0.0:
		var started := false
		for a in actors:
			if a.active and not a.dead and a.get("bike", false) and zone.has_point(a.p):
				bridge_timer = 0.0; started = true
				say("Marty: A PONTE ESTÁ DESABANDO — NÃO PARA, NÃO OLHA PRA TRÁS!")
				emit_audio("explosion", a.p); hit_stop(0.12)
				break
		if not started: return
	if bridge_done: return
	bridge_timer += dt
	var legacy := zone.size.y > zone.size.x
	var due := int(maxf(0.0, bridge_timer - (0.75 if legacy else BRIDGE_GRACE)) / (0.38 if legacy else BRIDGE_SEG_TIME))
	while bridge_broken.size() < mini(due, segs.size()):
		var seg: Rect2 = segs[bridge_broken.size()]
		bridge_broken.append(seg); gaps.append(seg)
		effects.append({"p":seg.get_center(),"kind":"bridge_debris","life":1.2,"max":1.2})
		effects.append({"p": seg.get_center(), "kind": "splash", "life": 0.7, "max": 0.7})
		emit_audio("explosion", seg.get_center())
	for a in actors:
		if not (a.active and not a.dead and a.get("bike", false)): continue
		if bridge_arrived(a):
			bridge_done = true
			a["bike"] = false; a["bike_speed"] = 0.0; a["bike_boosting"] = false
			bike["riding"] = false; bike["p"] = a.p
			for seg in segs:
				if not bridge_broken.has(seg): bridge_broken.append(seg); gaps.append(seg)
			say("Marty: TRAVESSIA COMPLETA! A ponte foi pro fundo — sem volta. Agora é você e ele.")
			emit_audio("pickup", a.p)
			continue
		if not legacy and zone.has_point(a.p):
			var wave := int(bike.get("route_wave", 0))
			if wave < 8 and a.p.x >= zone.position.x + 700 + wave * 1750:
				bike["route_wave"] = wave + 1
				spawn_enemy(Vector2(a.p.x + 560, zone.get_center().y), "crawler" if wave % 2 == 0 else "fish")
				# spawn_enemy appends to enemies; the flag makes failed attempts reversible.
				if not enemies.is_empty(): enemies[-1]["bridge_attempt"] = true
		for seg in bridge_broken:
			if seg.grow(4).has_point(a.p): fall_off_bridge(a); break
	# Ponte 100% caída e nenhum piloto nela: o tempo se remenda para a próxima tentativa.
	if bridge_broken.size() >= segs.size() and not bridge_done \
		and not actors.any(func(a): return a.active and not a.dead and a.get("bike", false) and zone.grow(40).has_point(a.p)):
		for seg in bridge_broken: gaps.erase(seg)
		bridge_broken.clear(); bridge_timer = -1.0
		bike["route_wave"] = 0
		enemies = enemies.filter(func(e): return not e.get("bridge_attempt", false) and e.get("room", "") != "bridge")
		pickups = pickups.filter(func(item): return not zone.has_point(item.p))
		say("A Ponte Temporal se remenda — pronta para outra tentativa.")

# Saved expeditions retain their original geometry; new runs use the long route.
func bridge_zone() -> Rect2:
	if room_by_id("bridge").is_empty(): return Rect2(4500, 1400, 250, 1000)
	return room_by_id("bridge").r

func bridge_segments() -> Array:
	var zone := bridge_zone()
	if zone.size.x > zone.size.y: return DOCKS.BRIDGE_SEGS
	var segments: Array = []
	for i in 8: segments.append(Rect2(4500, 2400 - (i + 1) * 125, 250, 125))
	return segments

func bridge_arrived(a: Dictionary) -> bool:
	if bridge_timer < 0.0 or not room_contains(room_by_id("boss"), a.p): return false
	var zone := bridge_zone()
	if zone.size.x > zone.size.y:
		return a.p.x >= zone.end.x and a.p.y >= zone.position.y and a.p.y < zone.end.y
	return a.p.y < zone.position.y + 60 and a.p.x >= zone.position.x and a.p.x < zone.end.x

# P12 — Faísca: o motoqueiro descolado do ano 2099, encalhado nas Docas de '41.
# É o empréstimo da moto — diálogo em fila igual ao Mestre Coral.
func bike_npc_interact(_a: Dictionary) -> void:
	if advance_dialogue("faisca"): return
	dialogue_owner = "faisca"
	if not bike_npc.get("talked", false):
		bike_npc["talked"] = true
		dialogue_queue = [
			"Faísca: cruzador do ano 2099, encalhado nesse cais fedorento desde sempre. Longa história — envolve um temporal e uma má aposta.",
			"Faísca: aquela aí é a MINHA Moto Temporal. Corre mais que a própria linha do tempo — te empresto de graça, tá?",
			"Faísca: uma condição: ela só obedece quem veste o ÔMEGA. E na ponte, NÃO FREIA — ela desaba atrás de quem para. [E]",
			"Marty: valeu, motoqueiro espectral. Se eu voltar inteiro, o café é por minha conta."]
		say("Faísca: opa, rosto novo! Piloto, marinheiro ou assombração?  [E]")
	elif bike.get("riding", false):
		say("Faísca: ela tá contigo agora. Dá orgulho, viu — cuida da minha bebê.")
	else:
		say("Faísca: veste o ÔMEGA e acelera. E lembra: na ponte, NÃO PARA.")

func fall_off_bridge(a: Dictionary) -> void:
	a["bike_speed"] = 0.0; a["bike_turbo"] = 1.0; a["bike_hit_cd"] = 0.0
	a.p = run_points.get("bike_checkpoint", Vector2(4300, 2700))
	a.jump = 0.0; a.knockback = Vector2.ZERO
	damage_actor(a, 12, "water", "bridge_fall")
	effects.append({"p": a.p, "kind": "splash", "life": 0.6, "max": 0.6})
	emit_audio("hit", a.p)
	for seg in bridge_broken: gaps.erase(seg)
	bridge_broken.clear(); bridge_timer = -1.0
	bike["route_wave"] = 0
	enemies = enemies.filter(func(e): return not e.get("bridge_attempt", false) and e.get("room", "") != "bridge")
	pickups = pickups.filter(func(item): return not bridge_zone().has_point(item.p))
	bullets = bullets.filter(func(b): return b.team != 1 or not bridge_zone().has_point(b.p))
	say("Marty: A ponte cedeu! De volta ao checkpoint — mais rápido dessa vez.")

# P10 — sequência da cápsula: o herói entra, a porta fecha, a cápsula parte.
func step_extraction(dt: float) -> void:
	if extract_state == "" or extract_actor < 0 or extract_actor >= actors.size(): return
	var hero: Dictionary = actors[extract_actor]
	extract_t += dt
	match extract_state:
		"enter":
			var inside: Vector2 = run_points.extraction + EXTRACT_INSIDE
			hero.p = hero.p.move_toward(inside, dt * 300.0)
			hero.move = (inside - hero.p).normalized()
			if extract_t >= 1.2 or hero.p.distance_to(inside) < 6.0:
				extract_state = "close"; extract_t = 0.0
				hero.move = Vector2.ZERO; hero.facing = Vector2.UP
				emit_audio("dash", run_points.extraction)
		"close":
			if extract_t >= 0.55:
				extract_state = "launch"; extract_t = 0.0
				hero["hidden"] = true
				effects.append({"p": run_points.extraction, "kind": "summon", "life": 0.9, "max": 0.9, "dir": Vector2.UP})
				emit_audio("spectre", run_points.extraction)
		"launch":
			if extract_t >= 0.9:
				extract_state = ""; extract_actor = -1
				finish_run("victory"); say("Núcleo recuperado! Confira o relatório da expedição.")

func step_actor(a: Dictionary, cmd: Dictionary, dt: float) -> void:
	if mode == "run" and a.active and not a.dead:
		ensure_run_stats()
		if a.armor: run_stats["armor_seconds"] = float(run_stats.get("armor_seconds", 0.0)) + dt
		if a.jump > 0: run_stats["airborne_seconds"] = float(run_stats.get("airborne_seconds", 0.0)) + dt
	CellarPlatforms.remember(self,a)
	if a.get("extracting", false): return
	var route_origin: Vector2 = a.p # Capture before blink, shadow return or ordinary movement.
	if mech.get("cockpit_t", 0.0) > 0 and mech.get("cockpit_actor", -1) == a.id:
		mech.cockpit_t = maxf(0.0, mech.cockpit_t - dt)
		if a.dead or mech.hp <= 0: mech.cockpit_t = 0.0
		a.move = Vector2.ZERO
		return
	for timer in ["shot", "slash", "hurt", "jump_cd", "dodge_cd", "interact_cd", "summon_cd", "snare", "fire_flash", "transform", "armor_cd", "beam_cd", "claw_cd", "combo_t", "punch_t", "bomb_cd", "roll_visual", "invuln", "sp_cd"]:
		a[timer] = maxf(0, a.get(timer, 0.0) - dt)
	a["nova_cd"]=maxf(0,a.get("nova_cd",0.0)-dt)
	if a.dead: return
	if a.armor and a.get("transform", 0.0) <= 0:
		a.armor_time = maxf(0, a.armor_time - dt)
		if a.armor_time <= 0:
			set_armor(a, false); a.armor_cd = ARMORS[a.armor_type].cooldown
			say("%s se desfez. Recarga: %ds." % [ARMORS[a.armor_type].name, int(a.armor_cd)])
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
	record_motion(a, moving)
	var aim: Vector2 = cmd.get("aim", a.aim)
	if aim.length() > 0.1: a.aim = aim.normalized()
	if a.beam_time > 0 and (not cmd.get("special", false) or not a.armor or a.mech or is_blue_form(a)): stop_omega_beam(a)
	if cmd.get("special", false) and is_blue_form(a): ground_claw(a)
	if cmd.get("special",false) and Supernova.active(a): Supernova.pulse(self,a)
	if cmd.get("special", false) and a.armor and a.armor_type == "omega" and not a.mech and a.beam_cd <= 0 and a.beam_time <= 0:
		a.beam_time = OMEGA_BEAM_DURATION
	if a.beam_time > 0:
		var beam_dt: float = minf(dt, a.beam_time)
		a.beam_end = omega_beam_endpoint(a.p, a.aim)
		for e in enemies:
			if e.hp <= 0 or Geometry2D.get_closest_point_to_segment(e.p, a.p, a.beam_end).distance_to(e.p) > 24: continue
			hurt_enemy(e, OMEGA_BEAM_DAMAGE * beam_dt); e.hurt = 0.08; e.alerted = true
		a.beam_time -= beam_dt
		if a.beam_time <= 0: stop_omega_beam(a)
	if cmd.get("jump", false) and a.jump <= 0 and a.jump_cd <= 0 and not a.mech and not a.get("bike", false):
		emit_audio("jump", a.p)
		a.jump = 0.65; a.jump_cd = 0.8; a["jump_from"] = a.p
	if cmd.get("dodge", false) and a.dodge_cd <= 0 and not a.mech and not a.get("bike", false):
		if a.armor and a.armor_type == "omega": omega_blink(a, moving)
		else:
			emit_audio("dash", a.p)
			a.dodge = 0.20; a.roll_visual = 0.36; a.dodge_cd = 0.3 if a.armor else uniform_of(a).dash_cd
			a.dash_dir = moving.normalized() if moving.length() > 0.1 else a.facing.normalized()
	var speed: float = 190.0 if a.mech else (ARMORS[a.armor_type].speed if a.armor else uniform_of(a).speed)
	if a.fused: speed = FUSION.speed
	if a.get("bike", false): speed = BikeHandling.speed(a,cmd,dt)
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
	# 0.22: impacto dos golpes inimigos — empurrão que arrasta Marty por alguns quadros
	# e perde força aos poucos (ver damage_actor), em vez de só tirar vida.
	var knockback: Vector2 = a.get("knockback", Vector2.ZERO)
	var previous_position: Vector2 = a.p
	var hovering: bool = a.armor and a.armor_type in ["omega","supernova"] and not a.mech and not a.fused and not a.get("bike",false)
	if hovering and clear_at(a.p,11): a["hover_safe"] = a.p
	a.p = move_body(a.p, moving * speed * dt + knockback * dt, 23 if a.mech else 11, a.jump > 0 or hovering)
	if a.get("bike",false): BikeHandling.collide(self,a,previous_position)
	elif not hovering and a.jump<=0 and a.has("hover_safe") and not clear_at(a.p,11):
		a.p = a.hover_safe
	if not room_by_id("bridge").is_empty():
		if bridge_zone().has_point(a.p) and not a.get("bike", false):
			a.p = route_origin; say("A ponte exige a Moto Temporal. A pé, siga pelo Mangue Negro.")
		elif room_contains(room_by_id("forest"), a.p) and a.get("bike", false):
			a.p = route_origin; say("O mangue é uma rota a pé. Desça da moto antes de entrar.")
	a.knockback = knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * dt)
	# P12: em velocidade de moto, os inimigos menores viram obstáculos — atropelo fere e empurra.
	if a.get("bike", false) and speed >= BIKE_SPEED * 0.8 and moving.length() > 0.1:
		for e in enemies:
			if e.hp <= 0 or e.kind == "boss" or e.p.distance_to(a.p) > 34: continue
			hurt_enemy(e, BIKE_RAM_DAMAGE); e.hurt = 0.25; e["alerted"] = true
			e.p = move_enemy_body(e, (e.p - a.p).normalized() * 46, 14)
			pop_dmg(e.p, BIKE_RAM_DAMAGE); emit_audio("hit", e.p)
			effects.append({"p": e.p, "kind": "hit", "life": 0.2, "max": 0.2})
	if moving.length() > 0.1:
		var before_step: float = a.step
		a.step += dt * ((9.0 if boosting else 5.0) if a.mech else 14.0)
		# pisada do Titan: poeira + tremor a cada pé que toca o chão
		if a.mech and int(a.step) != int(before_step) and int(a.step) % 2 == 1:
			effects.append({"p": a.p, "kind": "stomp", "life": 0.35, "max": 0.35})
	if a.jump > 0:
		a.jump = maxf(0, a.jump - dt)
		if a.jump == 0 and not hovering and (not clear_at(a.p, 10) or CellarPlatforms.water_at(self,a.p,11)):
			# caiu na água: volta para onde saltou e perde meio coração
			if not CellarPlatforms.recover(self,a): a.p = a.get("jump_from", a.p)
			damage_actor(a, 12, "water", "fall")
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
	if Supernova.active(a):
		if cmd.get("fire",false): Supernova.fire(self,a)
		if cmd.get("melee",false) or cmd.get("melee_m",false) or cmd.get("melee_h",false): Supernova.pulse(self,a)
	elif is_blue_form(a) and not a.mech:
		if cmd.get("melee", false) or cmd.get("melee_m", false) or cmd.get("melee_h", false): ground_claw(a)
		if cmd.get("fire", false) and a.shot <= 0: fire_actor(a)
	elif a.armor and not a.mech:
		if a.beam_time <= 0 and a.shot <= 0:
			if cmd.get("fire", false): fire_actor(a)
			elif a.slash <= 0 and (cmd.get("melee", false) or cmd.get("melee_m", false) or cmd.get("melee_h", false)): melee(a)
	else:
		# Ao golpear, as armas são guardadas: o soco tem prioridade sobre o tiro.
		if a.slash <= 0:
			if cmd.get("melee_h", false): melee(a, 2)
			elif cmd.get("melee_m", false): melee(a, 1)
			elif cmd.get("melee", false): melee(a)
		if cmd.get("fire", false) and a.shot <= 0 and a.slash <= 0 and not (a.mech and mech.fuel <= 0): fire_actor(a)
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
		if d < radius + (BOSS_RADIUS if e.kind == "boss" else 19) and line_of_fire(p, e.p):
			var dealt: float = damage * (1.0 - 0.45 * clampf(d / radius, 0, 1))
			hurt_enemy(e, dealt, credit_player); e.hurt = 0.2; e["alerted"] = true
			pop_dmg(e.p, dealt, big)
	if hurts_all:   # barril: atinge todo mundo (1 coração) e empurra
		for a in actors:
			if a.active and not a.dead and a.p.distance_to(p) < radius * 0.8 and line_of_fire(p, a.p):
				damage_actor(a, 20.0, "explosion", "barrel")
				var push: Vector2 = (a.p - p).normalized() if a.p.distance_to(p) > 1 else Vector2.DOWN
				a.p = move_body(a.p, push * 60, 23 if a.mech else 11)
	# Resolve exposure before breaking cover; one blast cannot reach through a
	# wall that this same blast has just removed. Ignore each target's own volume.
	var hit: Array = []
	for i in obstacles.size():
		var cracked: bool = i < obstacle_kinds.size() and obstacle_kinds[i].begins_with("wall_crack_")
		var destructible: bool = i < obstacle_hp.size() and obstacle_hp[i] >= 0
		var reach: float = radius + (70.0 if cracked else 20.0)
		if (cracked or destructible) and obstacles[i].get_center().distance_to(p) < reach and blast_reaches_obstacle(p, obstacles[i]): hit.append(i)
	hit.reverse()
	for i in hit:
		if obstacle_kinds[i].begins_with("wall_crack_"): open_shortcut(i)
		else: damage_obstacle(i, damage)
	effects.append({"p": p, "kind": "explosion", "life": 0.55 if big else 0.4, "max": 0.55 if big else 0.4, "r": radius})

func blast_reaches_obstacle(origin: Vector2, box: Rect2) -> bool:
	if box.has_point(origin): return true
	var surface := Vector2(clampf(origin.x, box.position.x, box.end.x), clampf(origin.y, box.position.y, box.end.y))
	return line_of_fire(origin, surface.move_toward(origin, 1.0))

func step_bomb(b: Dictionary, dt: float) -> void:
	b.t += dt
	var k: float = clampf(b.t / MECH_BOMB.flight, 0, 1)
	b.p = b.from.lerp(b.to, k)
	if k >= 1.0:
		explode(b.p, MECH_BOMB.radius, b.damage, true); b.life = 0

# 0.22: balas maiores e a área de acerto acompanha o visual. Antes o raio de colisão
# (r) era menor que o desenho (visual_r), então tiros "quase certos" na tela erravam
# de verdade. BULLET_SIZE_SCALE cresce as duas coisas juntas; o raio visual fica só
# um pouco acima do raio de colisão (brilho/contorno), sem enganar o alcance real.
const BULLET_SIZE_SCALE := 1.6
func add_bullet(pos: Vector2, direction: Vector2, team: int, damage: float, speed: float, radius: float = 5.0, owner_id: int = -1, kind: String = "", life: float = 3.0) -> void:
	if team==0 and owner_id>=0 and owner_id<actors.size() and actors[owner_id].get("bike",false):
		speed = maxf(speed, BikeHandling.TURBO+650.0)
	var base_radius: float = maxf(radius, 6.0) * BULLET_SIZE_SCALE
	var hit_radius: float = base_radius if team == 0 else base_radius * 1.15
	bullets.append({"p": pos, "v": direction * speed, "team": team, "damage": damage, "r": hit_radius, "visual_r": hit_radius * 1.08, "age": 0.0, "life": life, "owner": owner_id, "kind": kind})

# 0.15: número de dano flutuante — desenhado em world_view.gd
func pop_dmg(p: Vector2, amount: float, heavy: bool = false) -> void:
	effects.append({"p": p, "kind": "dmg_num", "life": 0.6, "max": 0.6, "value": int(amount), "heavy": heavy, "vx": rng.randf_range(-14, 14)})

func hit_stop(d: float) -> void:
	hitstop = maxf(hitstop, d)

func auto_aim_direction(a: Dictionary, fallback: Vector2, screen: Rect2) -> Vector2:
	# Linha de tiro é cara: ordena por distância e só testa até achar o primeiro alvo visível.
	var candidates: Array = []
	for enemy in enemies:
		if enemy.hp<=0 or enemy.get("stunned",false) or not screen.has_point(enemy.p): continue
		if mode=="run" and not visited.has(enemy.get("room","")): continue
		var distance: float=(enemy.p-a.p).length_squared()
		if distance>=0.001: candidates.append([distance, enemy.p])
	candidates.sort_custom(func(x, y): return x[0] < y[0])
	for c in candidates:
		if line_of_fire(a.p, c[1]): return (c[1]-a.p).normalized()
	return fallback

func weapon_of(a: Dictionary) -> String:
	if a.mech: return "mech"
	if Supernova.active(a): return "supernova"
	if a.armor and not is_blue_form(a): return "omega_orb"
	var selected: String = a.get("run_weapon", "")
	if selected != "" and a.get("run_weapons", {}).has(selected): return selected
	# Migrate old saves once; a later outfit/form change cannot replace equipment.
	if not a.has("basic_weapon"): a["basic_weapon"] = uniform_of(a).weapon
	return a.basic_weapon

const WEAPON_NAMES := {"omega_orb": "ESFERAS ÔMEGA", "pistol": "BLASTER", "shotgun": "ESCOPETA DE REBITE", "smg": "SUBMETRALHADORA", "bazooka": "BAZUCA", "mech": "CANHÃO PESADO",
	"mosquete": "MOSQUETE 1901", "tesla": "BOBINA TESLA", "arpoador": "LANÇA-ARPÕES"}
func weapon_name(a: Dictionary) -> String:
	if Supernova.active(a): return "PLASMA SOLAR"
	return WEAPON_NAMES.get(weapon_of(a), "ARMA")

func weapon_behind_body(a: Dictionary) -> bool:
	return a.aim.y < -0.25

func grant_run_weapon(a: Dictionary, name: String, ammo: int) -> void:
	var owned: Dictionary = a.get("run_weapons", {})
	var first: bool = not owned.has(name)
	owned[name] = maxi(int(owned.get(name, 0)), mini(int(owned.get(name, 0)) + maxi(0, ammo), int(RUN_WEAPON_CAPS.get(name, 90))))
	a["run_weapons"] = owned
	if first and not (a.armor and not is_blue_form(a)): a["run_weapon"] = name
	say("%s • %d cargas nesta expedição • Q/RB troca arma" % [WEAPON_NAMES.get(name, name.to_upper()), owned[name]])

const RUN_WEAPON_CAPS := {"bazooka": 90, "mosquete": 60, "tesla": 180, "arpoador": 90}

func toggle_run_weapon(a: Dictionary) -> void:
	if a.armor and not is_blue_form(a): return
	var choices := available_weapons(a)
	var next: String = choices[(choices.find(weapon_of(a)) + 1) % choices.size()]
	select_run_weapon(a.id, next)
	say(weapon_name(a) + (" • %d cargas" % int(a.run_weapons.get(next, 0)) if a.run_weapons.has(next) else " • munição infinita"))

func available_weapons(a: Dictionary) -> Array[String]:
	var choices: Array[String] = ["pistol"]
	if is_unlocked("mecanico"): choices.append("shotgun")
	if is_unlocked("espiao"): choices.append("smg")
	for owned_weapon in a.get("run_weapons", {}):
		if owned_weapon not in choices: choices.append(owned_weapon)
	return choices

func select_run_weapon(id: int, weapon: String) -> bool:
	if id < 0 or id >= actors.size(): return false
	var a: Dictionary = actors[id]
	if not a.active or a.dead or a.mech or (a.armor and not is_blue_form(a)): return false
	if weapon == "": a.run_weapon = ""; return true
	if weapon not in available_weapons(a): return false
	if a.run_weapons.has(weapon): a.run_weapon = weapon
	else: a.basic_weapon = weapon; a.run_weapon = ""
	return true


# 0.14: tabela única das armas — o jogo e a tela de Equipamento (loadout_stats) leem daqui.
const WEAPONS := {
	"pistol": {"count": 1, "damage": 16.0, "cooldown": 0.22, "speed": 660.0, "radius": 4.0, "spread": 0.12, "kind": "p_pistol", "pierce": 0},
	"shotgun": {"count": 6, "damage": 9.0, "cooldown": 0.65, "speed": 620.0, "radius": 4.0, "spread": 0.11, "kind": "p_pellet", "pierce": 0},
	"smg": {"count": 1, "damage": 7.0, "cooldown": 0.085, "speed": 740.0, "radius": 4.0, "spread": 0.12, "kind": "p_smg", "pierce": 0},
	"bazooka": {"count": 1, "damage": 48.0, "cooldown": 0.9, "speed": 390.0, "radius": 10.0, "spread": 0.0, "kind": "p_rocket", "pierce": 0},
	# P7 — armas dos sobreviventes: época (mosquete, arpoador) ou francamente futurista (tesla).
	"mosquete": {"count": 1, "damage": 62.0, "cooldown": 1.05, "speed": 900.0, "radius": 6.0, "spread": 0.02, "kind": "p_heavy", "pierce": 1},
	"tesla": {"count": 3, "damage": 11.0, "cooldown": 0.5, "speed": 720.0, "radius": 4.0, "spread": 0.16, "kind": "p_wave", "pierce": 2},
	"arpoador": {"count": 1, "damage": 40.0, "cooldown": 0.8, "speed": 540.0, "radius": 8.0, "spread": 0.0, "kind": "harpoon", "pierce": 3},
	# Canhão de Plasma Ômega: disparo duplo, perfurante.
	"omega": {"count": 2, "damage": 24.0, "cooldown": 0.2, "speed": 860.0, "radius": 7.0, "spread": 0.05, "kind": "p_omega", "pierce": 2}}
const SWORD := {"hit": 38.0, "finisher": 64.0, "wave": 30.0}   # Legacy constant name retained for saves/tests; energy combo damage.
const MECH_PUNCH := 55.0
const SPECTRE_SHOT := {"damage": 9.0, "cooldown": 0.55}
const SPECTRE_HP := 100.0
# P6 — aliado capturado: mais resistente e mais forte que o Spectre.
const SENTINELA_SHOT := {"damage": 16.0, "cooldown": 0.42}
const SENTINELA_HP := 160.0
const GOLEM_SHOT := {"damage": 26.0, "cooldown": 0.62}
const GOLEM_HP := 260.0
const ROBOT_NAMES := {"spectre": "SPECTRE", "titan": "TITAN-01", "sentinela": "SENTINELA-7", "golem": "GOLEM-9"}
const FUSION := {"damage": 1.35, "cadence": 0.8, "speed": 360.0}

const ACTOR_VISUAL_SCALE := 1.12

# Hand and barrel geometry is shared with WorldView. Height never shifts collision Y.
func weapon_hand_anchor(a: Dictionary, body_direction: Vector2 = Vector2.ZERO) -> Vector2:
	var direction: Vector2 = a.get("aim", a.facing) if body_direction == Vector2.ZERO else body_direction
	if a.get("fused", false):
		return [Vector2(19,-29), Vector2(19,-31), Vector2(17,-32), Vector2(20,-34), Vector2(19,-34), Vector2(-20,-34), Vector2(-17,-32), Vector2(-19,-31)][weapon_direction_row(direction)]
	if outfit_of(a) == "omega":
		var omega_anchors := [
			Vector2(21, -66), Vector2(24, -68), Vector2(24, -68), Vector2(23, -67),
			Vector2(24, -68), Vector2(-23, -67), Vector2(-24, -68), Vector2(-24, -68),
		]
		return omega_anchors[weapon_direction_row(direction)]
	if outfit_of(a) in ["padrao", "azul"]:
		# O novo atlas tem oito direcoes e corpo mais alto que o legado.
		# A ancora segue a mira para manter a empunhadura junto da mao no disparo.
		var padrao_anchors := [
			Vector2(16, -28), Vector2(14, -30), Vector2(9, -31), Vector2(15, -32),
			Vector2(15, -32), Vector2(-15, -32), Vector2(-9, -31), Vector2(-14, -30),
		]
		return padrao_anchors[weapon_direction_row(direction)]
	# 0.17: acompanha a mão visível de cada vista, em vez de orbitar o centro do corpo.
	var pose := weapon_pose(direction)
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
	sizes.merge(preload("res://scripts/weapon_visuals.gd").SIZES)
	var size: Vector2 = sizes.get(weapon, Vector2(32, 20))
	var handle: Vector2 = {"pistol": Vector2(8, 12), "shotgun": Vector2(18, 12), "smg": Vector2(17, 15), "bazooka": Vector2(34, 42), "mosquete": Vector2(35, 21), "tesla": Vector2(30, 29), "arpoador": Vector2(32, 26)}.get(weapon, Vector2(8, size.y * 0.5))
	var aim: Vector2 = a.aim.normalized()
	var mirror := -1.0 if aim.x < 0 else 1.0
	var hand := weapon_hand_anchor(a, body_direction)
	var tip: Vector2 = Vector2(90, 28) if weapon == "bazooka" else Vector2(size.x - 2, size.y * 0.5)
	var barrel := Vector2(tip.x - handle.x, (tip.y - handle.y) * mirror).rotated(aim.angle())
	var jump_height := sin((1.0 - a.jump / 0.65) * PI) * 68 if a.jump > 0 else 0.0
	return {"size": size, "hand": hand, "handle": handle, "angle": aim.angle(), "mirror": mirror,
		"ground": a.p + (Vector2(hand.x, 0) + barrel) * ACTOR_VISUAL_SCALE, "height": (-hand.y + height_at(a.p) + jump_height) * ACTOR_VISUAL_SCALE,
		"muzzle": a.p + hand + barrel - Vector2(0, height_at(a.p) + jump_height)}

func fire_actor(a: Dictionary) -> void:
	if Supernova.active(a): Supernova.fire(self,a); return
	var weapon := weapon_of(a)
	if weapon == "omega_orb":
		sword_attack(a); return
	if a.run_weapons.has(weapon):
		var owned: Dictionary = a.run_weapons
		if int(owned.get(weapon, 0)) <= 0:
			emit_audio("dry_fire", a.p)
			a.shot = 0.3; say("%s SEM CARGAS • Q/RB equipa a arma básica" % weapon_name(a)); return
		owned[weapon] = maxi(0, int(owned[weapon]) - 1)
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
		# Visual kind is shared with the musket; only the Titan shell has splash.
		bullets[-1]["shell_splash"] = weapon == "mech"
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
	if a.run_weapons.has(weapon) and int(a.run_weapons[weapon]) == 0:
		say("%s SEM CARGAS • Q/RB equipa a arma básica" % weapon_name(a))
	if a.mech: effects.append({"p": a.p + a.aim * 30, "kind": "flash", "life": 0.12, "dir": a.aim}); effects.append({"p": a.p, "kind": "recoil", "life": 0.2, "max": 0.2, "dir": a.aim})
	elif weapon in ["shotgun", "smg"]:
		effects.append({"p": a.p, "kind": "casing", "life": 0.5, "max": 0.5, "dir": a.aim.rotated(-PI / 2 if a.aim.x >= 0 else PI / 2), "seed": rng.randi() % 1000})

# Energia Ômega: emissão próxima e esfera perfurante; IDs antigos preservados.
func sword_attack(a: Dictionary) -> void:
	if is_blue_form(a): return
	emit_audio("omega", a.p)
	if a.combo_t <= 0: a.combo = 0
	var hit: int = a.combo
	a.combo = (a.combo + 1) % 3; a.combo_t = 0.7
	var finisher := hit == 2
	var reach := 120.0 if finisher else 100.0
	var arc := 0.25 if finisher else 0.1   # produto escalar mínimo (≈ 150° / 170°)
	var damage: float = SWORD.finisher if finisher else SWORD.hit
	a["omega_cast"] = true
	a.slash = 0.32; a.slash_max = 0.32; a.shot = 0.42 if finisher else 0.24; a.facing = a.aim
	a["swing"] = hit
	var close_hits: Array = []
	for e in enemies:
		var offset: Vector2 = e.p - a.p
		if not e.get("stunned", false) and offset.length() < reach + (BOSS_RADIUS - 15.0 if e.kind == "boss" else 0.0) and offset.normalized().dot(a.aim) > -arc and muzzle_line_clear(a.p, e.p):
			close_hits.append(e.id)
			hurt_enemy(e, damage); e.hurt = 0.18
			pop_dmg(e.p, damage, finisher)
			effects.append({"p": e.p, "kind": "impact", "life": 0.2, "max": 0.2, "omega": true})
			if e.kind != "boss": e.p = move_enemy_body(e, offset.normalized() * (18 if finisher else 8), 14)
	for b in bullets:
		if b.team == 1 and a.p.distance_to(b.p) < reach and muzzle_line_clear(a.p, b.p):
			b.team = 0; b.v = a.aim * 560; b.damage = 18; b.kind = "p_omega"
	props_in_arc(a, reach, damage)
	if mode == "run" and a.p.distance_to(run_points.secret_wall) < 125: open_secret()
	var hand := weapon_hand_anchor(a)
	var origin: Vector2 = a.p + Vector2(hand.x, 0) * ACTOR_VISUAL_SCALE
	if not muzzle_line_clear(a.p, origin): origin = a.p
	add_bullet(origin, a.aim, 0, damage, 540, 22 if finisher else 16, a.id, "p_omega", 1.6)
	bullets[-1]["pierce"] = 5 if finisher else 2
	bullets[-1]["hits"] = close_hits
	bullets[-1]["visual_r"] = 38.0 if finisher else 27.0
	var jump_height := sin((1.0 - a.jump / 0.65) * PI) * 68 if a.jump > 0 else 0.0
	bullets[-1]["height"] = (-hand.y + height_at(a.p) + jump_height) * ACTOR_VISUAL_SCALE

func props_in_arc(a: Dictionary, reach: float, damage: float) -> void:
	if mode != "run": return
	var hit: Array = []
	for i in obstacles.size():
		var off: Vector2 = obstacles[i].get_center() - a.p
		if i < obstacle_hp.size() and obstacle_hp[i] >= 0 and off.length() < reach + 20 and off.normalized().dot(a.aim) > 0.1: hit.append(i)
	hit.reverse()
	for i in hit: damage_obstacle(i, damage)

func ground_claw(a: Dictionary) -> void:
	if not is_blue_form(a) or a.dead or a.mech or a.fused or a.get("transform", 0.0) > 0 or a.get("claw_cd", 0.0) > 0: return
	var screen := visible_world_rect if visible_world_rect.has_area() else Rect2(a.p - Vector2(640, 400), Vector2(1280, 800))
	var target: Dictionary = {}
	var nearest := BLUE_CLAW_RANGE
	for e in enemies:
		var distance: float = a.p.distance_to(e.p)
		# Online cameras are independent. Range and line of sight are authoritative;
		# the host's viewport must never reject the guest's nearby target.
		if e.hp <= 0 or e.get("stunned", false) or distance > nearest or (coop != "online" and not screen.has_point(e.p)) or not line_of_fire(a.p, e.p): continue
		if not target.is_empty() and distance == nearest: continue
		target = e; nearest = distance
	if target.is_empty(): return
	a["claw_cd"] = BLUE_CLAW_COOLDOWN
	a.slash = 0.35; a.slash_max = 0.35
	var cast_direction: Vector2 = target.p - a.p
	if cast_direction.length_squared() > 0: a.facing = cast_direction.normalized()
	effects.append({"kind": "ground_claw", "p": target.p, "life": 0.65, "max": 0.65, "owner": a.id})
	emit_audio("sword", target.p)
	hurt_enemy(target, BLUE_CLAW_DAMAGE); target.hurt = 0.2; target.alerted = true
	pop_dmg(target.p, BLUE_CLAW_DAMAGE, true)

# Combo de socos estilo jogo de luta: jab rapido -> direto -> uppercut pesado.
# Cada estagio tem ritmo, dano, alcance e empurrao proprios; apertar melee de novo
# dentro da janela punch_t encadeia o proximo golpe. O Titan segue com um soco unico.
const PUNCH_STAGES := [
	{"slash": 0.22, "dmg": 0.5, "reach": 74.0, "push": 6.0},
	{"slash": 0.34, "dmg": 1.0, "reach": 80.0, "push": 10.0},
	{"slash": 0.52, "dmg": 2.0, "reach": 88.0, "push": 22.0},
]
const PUNCH_CHAIN := 0.55   # tempo extra apos a animacao para encadear o proximo golpe

# ── Comandos de movimento estilo jogo de luta (Passo de luta SF) ──────────────
# O historico de direcoes de movimento fica em a.motion ({d, t}); especiais saem
# quando o padrao aparece dentro da janela. Nao consome o rng da expedição.
const MOTION_WINDOW := 0.45
const MOTION_MAX := 10

func record_motion(a: Dictionary, move: Vector2) -> void:
	if not a.has("motion"): a["motion"] = []
	var hist: Array = a.motion
	# Solta do direcional também entra no buffer ("n"): é o que permite o toque-duplo.
	var d := Vector2(signf(move.x), signf(move.y)) if move.length() > 0.4 else Vector2.ZERO
	if hist.is_empty() or hist[-1].d != d: hist.append({"d": d, "t": tick_time})
	while not hist.is_empty() and tick_time - float(hist[0].t) > MOTION_WINDOW: hist.pop_front()
	if hist.size() > MOTION_MAX: hist = hist.slice(hist.size() - MOTION_MAX)
	a["motion"] = hist

func _motion_code(d: Vector2, fwd: float) -> String:
	if d.length() < 0.5: return "n"
	var x := int(signf(d.x) * fwd)   # +1 pra frente, -1 pra tras
	if d.y > 0.5: return "df" if x == 1 else ("db" if x == -1 else "d")
	if d.y < -0.5: return "uf" if x == 1 else "u"
	if x == 1: return "f"
	if x == -1: return "b"
	return ""

# "dp" (frente-baixo-frente ou toque-duplo frente/trás), "hcf" (meia lua pra frente), "qcf" (baixo-diagonal/frente).
func motion_detect(a: Dictionary) -> String:
	var hist: Array = a.get("motion", [])
	if hist.size() < 2: return ""
	var fwd := signf(a.aim.x); if fwd == 0.0: fwd = 1.0
	var raw := []
	var codes := []
	for h in hist:
		var c := _motion_code(h.d, fwd)
		raw.append(c)
		if c != "n": codes.append(c)
	# Toque duplo pra frente ou pra trás (dir, solta, mesma dir) → shoryuken.
	for i in range(raw.size() - 2):
		if raw[i] in ["f", "b"] and raw[i + 1] == "n" and raw[i + 2] == raw[i]: return "dp"
	var seen_f := false; var seen_d := false
	for c in codes:
		if c == "f":
			if seen_f and seen_d: return "dp"
			seen_f = true
		elif c.begins_with("d") and seen_f: seen_d = true
	seen_f = false; seen_d = false; var seen_b := false
	for c in codes:
		if c in ["b", "db"]: seen_b = true
		elif c.begins_with("d") and seen_b: seen_d = true
		elif c == "f" and seen_b and seen_d: return "hcf"
	for i in range(codes.size()):
		for j in range(i + 1, codes.size()):
			if codes[i] in ["d", "df"] and codes[j] in ["df", "f", "db"]: return "qcf"
	return ""

# Hadouken: projetil de energia; a forca do botao define dano e velocidade.
func hadouken(a: Dictionary, strength: int) -> void:
	var tier := clampi(strength, 0, 2) if strength >= 0 else 1
	var base: float = uniform_of(a).melee
	var dmg: float = base * [0.9, 1.2, 1.6][tier]
	var spd: float = [420.0, 540.0, 660.0][tier]
	a.slash = 0.3; a.slash_max = 0.3; a.punch = 1; a.punch_t = a.slash + PUNCH_CHAIN * 0.5
	a.facing = a.aim
	a["motion"] = []; a.sp_cd = 1.4
	emit_audio("spectre", a.p)
	add_bullet(a.p + a.aim * 34, a.aim, 0, dmg, spd, 9.0, a.id, "p_wave", 2.4)
	effects.append({"p": a.p + a.aim * 26, "kind": "impact", "life": 0.16, "max": 0.16, "omega": true})
	hit_stop(0.02)
	say(["HADOUKEN!", "HADOUKEN MÉDIO!", "HADOUKEN FORTE!"][tier])

# Shoryuken: uppercut ascendente com i-frames; lanca o inimigo para cima.
func shoryuken(a: Dictionary, strength: int) -> void:
	var tier := 2 if strength < 0 else clampi(strength, 0, 2)
	var base: float = uniform_of(a).melee
	var damage: float = base * [2.0, 2.4, 3.0][tier]
	a.slash = 0.52; a.slash_max = 0.52; a.punch = 2; a.punch_t = a.slash + PUNCH_CHAIN * 0.4
	a.facing = a.aim
	a.invuln = 0.4   # subida invencivel — atravessa golpes no meio do arco
	a["motion"] = []; a.sp_cd = 1.6
	emit_audio("sword", a.p)
	var reach := 96.0
	effects.append({"p": a.p + a.aim * 30, "kind": "slash", "life": 0.22, "dir": a.aim, "reach": reach})
	for e in enemies:
		var offset: Vector2 = e.p - a.p
		if offset.length() < reach and offset.normalized().dot(a.aim) > -0.15:
			hurt_enemy(e, damage); e.hurt = 0.4
			pop_dmg(e.p, damage, true)
			if e.kind != "boss": e.p = move_enemy_body(e, (offset.normalized() + Vector2(0, -0.9)).normalized() * 34.0, 14)
	props_in_arc(a, reach, damage)
	hit_stop(0.06)
	effects.append({"p": a.p + a.aim * 40 - Vector2(0, 30), "kind": "impact", "life": 0.28, "max": 0.28})
	say("SHORYUKEN!")

func melee(a: Dictionary, strength: int = -1) -> void:
	a["omega_cast"] = false
	if is_blue_form(a) and not a.mech:
		ground_claw(a)
		return
	if not a.mech:
		var m := motion_detect(a)
		# Custo/intervalo dos especiais: em recarga o comando vira soco normal.
		if a.get("sp_cd", 0.0) <= 0.0:
			if m in ["dp", "hcf"]: shoryuken(a, strength); return
			if m == "qcf": hadouken(a, strength); return
	emit_audio("melee", a.p)
	var stage := 0
	if not a.mech:
		stage = clampi(strength, 0, 2) if strength >= 0 else ((a.punch + 1) % PUNCH_STAGES.size() if a.punch_t > 0 else 0)
		a.punch = stage
	var data: Dictionary = PUNCH_STAGES[stage]
	a.slash = 0.65 if a.mech else float(data.slash)
	a.slash_max = a.slash
	a.punch_t = a.slash + PUNCH_CHAIN
	var reach: float = 115.0 if a.mech else float(data.reach)
	var base: float = MECH_PUNCH if a.mech else float(uniform_of(a).melee)
	var damage: float = base if a.mech else base * float(data.dmg)
	var finisher: bool = not a.mech and stage == 2
	a.facing = a.aim
	effects.append({"p": a.p, "kind": "slash", "life": 0.18, "dir": a.aim, "reach": reach})
	for e in enemies:
		var offset: Vector2 = e.p - a.p
		if offset.length() < reach and offset.normalized().dot(a.aim) > 0.05:
			hurt_enemy(e, damage); e.hurt = 0.3 if finisher else 0.15
			pop_dmg(e.p, damage, finisher or a.mech)
			if e.kind != "boss" and (a.mech or stage > 0):
				e.p = move_enemy_body(e, offset.normalized() * data.push, 14)
	props_in_arc(a, reach, 40.0 if a.mech else damage)
	if finisher:
		hit_stop(0.05)
		effects.append({"p": a.p + a.aim * 40, "kind": "impact", "life": 0.22, "max": 0.22})
	# A clearly hinted crack opens with a close attack, never a consumable key.
	if mode == "run" and a.p.distance_to(run_points.secret_wall) < 125:
		open_secret()
	if a.armor:
		for b in bullets:
			if b.team == 1 and a.p.distance_to(b.p) < reach and muzzle_line_clear(a.p, b.p):
				b.team = 0; b.v = a.aim * 550; b.damage = 16

func open_secret() -> void:
	if secret_open: return
	secret_open = true
	floors.append_array(run_secret_floors)
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
	if not a.mech:
		for other in actors:
			if other.active and other.id != a.id and other.dead and a.p.distance_to(other.p) < 75:
				other.dead = false; other.hp = HEART * 1.5; other.hurt = 2
				if mode == "run": ensure_run_stats(); run_stats.revives += 1
				say("Parceiro reanimado!"); return
	if mode == "run" and a.p.distance_to(story_npc_position()) < 95:
		story_interact(a); return
	if mode == "run" and altar_position() != Vector2.INF and a.p.distance_to(altar_position()) < 170:
		altar_interact(a); return
	if mode == "run":
		for npc in rescue_npcs:
			if a.p.distance_to(npc.p) < 100:
				rescue_interact(a, npc); return
	if mode == "run":
		for e in enemies:
			if e.get("stunned", false) and e.get("capturable", false) and a.p.distance_to(e.p) < 110:
				capture_robot(a, e); return
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
		if not hub_dog.is_empty() and a.p.distance_to(hub_dog.p) < 95:
			hub_dog["state"] = "licking"; hub_dog["lick_t"] = 0.9; hub_dog["target"] = a.id
			a.hp = max_hp()
			effects.append({"p": a.p - Vector2(0, 78), "kind": "heart", "life": 1.5, "max": 1.5})
			emit_audio("pickup", hub_dog.p)
			say("O golden te lambe com a língua gigante — vida cheia! Ele continua com fome.")
			return
		var point := hub_point_near(a.p)
		match point.get("id", ""):
			"portal":
				start_new_run(); return
			"lost":
				say("Anel rachado, preso por correntes. Esta coordenada ainda não pode ser estabilizada."); return
			"core":
				var relics := ""
				if story_flags.get("peca_titan", false): relics += " • peça TITAN-01 na baia"
				if story_flags.get("simbolo_ordem", false): relics += " • selo da Ordem catalogado"
				say("Núcleo Temporal estável • expedições concluídas: %d • fragmentos: %d%s" % [clears, materials, relics]); return
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
		# P12 — Faísca, o motoqueiro do amanhã: é ELE quem empresta a moto.
		if not bike_npc.is_empty() and a.p.distance_to(bike_npc.p) < 105 \
			and (not bike_npc.get("talked", false) or not dialogue_queue.is_empty() or a.p.distance_to(bike.p) >= 90):
			bike_npc_interact(a); return
		# P12 — Moto Temporal: só a armadura ÔMEGA aguenta o torque; na ponte não dá pra descer.
		if not bike.is_empty():
			if a.get("bike", false):
				if bridge_zone().grow(30).has_point(a.p) and not bridge_done:
					bark("Não dá pra descer no meio da ponte!")
				else:
					a["bike"] = false; bike["riding"] = false; bike["p"] = a.p
					say("Moto estacionada.")
				return
			if not bike.get("riding", false) and a.p.distance_to(bike.p) < 90:
				if not bike_npc.get("talked", false):
					say("Faísca: ei, camarada — pergunta antes de subir na minha bebê. Vem cá.")
				elif not a.armor or a.armor_type != "omega" or a.mech or a.fused:
					bark("A Moto Temporal rasga piloto comum na linha do tempo. VISTO O ÔMEGA e volto.")
				else:
					a["bike"] = true; bike["riding"] = true
					a["bike_speed"] = 0.0; a["bike_turbo"] = 1.0; a["bike_hit_cd"] = 0.0
					emit_audio("dash", a.p)
					say("MOTO TEMPORAL • Direcione para acelerar e desviar • segure o botão de esquiva para TURBO • barreiras causam dano e freiam!")
				return
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
		if a.p.distance_to(run_points.shop) < 110:
			if shop_bought: say("Comerciante: estoque esgotado nesta expedição.")
			elif money >= 15:
				money -= 15; keys += 1; heal(a, 2); shop_bought = true
				say("Comprou 1 chave e cura por 15 moedas.")
			else: say("Comerciante: chave + cura por 15 moedas.")
			return
		if a.p.distance_to(run_points.side) < 110 and not side_active and not side_complete and not side_failed:
			side_active = true; side_time = 55
			var guards := [Vector2(-450, -300), Vector2(450, -300), Vector2(-500, 150), Vector2(500, 150), Vector2(-250, 380), Vector2(250, 380), Vector2(0, -330)]
			for n in range(7):
				var gp: Vector2 = run_points.side + guards[n]
				if not clear_at(gp, 14): gp = run_points.side + guards[n] * 0.7
				spawn_enemy(gp, "cult" if n % 2 == 0 else "brute", true)
			say("OPCIONAL • Rompa os 7 pontos do ritual em 55s. Recompensa: chaves, cura e fragmento."); return
		if boss_dead and extract_state == "" and a.p.distance_to(run_points.extraction) < 120:
			if not reward_claimed:
				reward_claimed = true; materials += 3; clears += 1; armor_unlocked = true
				if not story_flags.get("peca_titan", false):
					story_flags["peca_titan"] = true; story_flags["simbolo_ordem"] = true; story_flags["sinal_leticia"] = true; first_victory_beat = true
				check_unlocks()
			extract_state = "enter"; extract_t = 0.0; extract_actor = a.id
			a["extracting"] = true
			say("Marty: Missão cumprida. Te vejo do outro lado."); return
	say("Aproxime-se de um portal, baú, parceiro caído, comerciante ou robô e pressione E.")

const KNOCKBACK_DECAY := 2200.0   # px/s² — o empurrão perde força rápido, mas dá tempo de sentir o arrasto
# P12 — Moto Temporal: 4x a velocidade a pé; a ponte desaba em segmentos perseguindo o piloto.
const BIKE_SPEED := 780.0
const BIKE_RAM_DAMAGE := 45.0
const BRIDGE_GRACE := 2.0        # steering allowance behind the rider
const BRIDGE_SEG_TIME := 1.0     # each 780-unit section takes one second at bike speed
func jump_evades(a: Dictionary, source_kind: String, source_attack: String) -> bool:
	if a.get("jump", 0.0) <= 0: return false
	# Both powered forms retain their existing airborne protection.
	if a.get("armor", false): return true
	return source_kind == "hazard" and source_attack in ["tentacle", "tentacle_gate", "acid", "trail", "spike", "spikes"]

func damage_actor(a: Dictionary, amount: float, source_kind: String = "unknown", source_attack: String = "", knockback: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0.0: return
	if a.hurt > 0 or a.dodge > 0 or a.get("invuln", 0.0) > 0 or a.dead or jump_evades(a, source_kind, source_attack) or a.get("transform", 0.0) > 0: return
	if amount > 0: emit_audio("hit", a.p)
	var hp_before := float(a.hp)
	a.last_damage_source = source_kind; a.last_damage_attack = source_attack
	a.hurt = 0.45 if a.mech else HURT_IFRAMES
	if knockback.length() > 0.1: a.knockback = knockback * (0.4 if a.mech else 1.0)
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
			if a.hp <= 0: a.hp = 0; a.dead = true; a["dead_t"] = 0.0
	else:
		var hit := heart_damage(amount * float(uniform_of(a).taken))
		if a.get("shield", 0.0) > 0:
			# Armadura Ômega: corações de escudo absorvem o golpe inteiro.
			a.shield = maxf(0, a.shield - hit)
			effects.append({"p": a.p, "kind": "shield_hit", "life": 0.3, "max": 0.3})
			if a.shield <= 0: say("Escudo Ômega quebrado!")
			return
		a.hp -= hit
		if a.hp <= 0: a.hp = 0; a.dead = true; a["dead_t"] = 0.0; say("Parceiro caído! Aproxime-se e pressione E para reanimar.")
		elif a.hp <= HEART and hp_before > HEART: bark("Não hoje. AINDA não.", 1.0)
	if mode == "run":
		ensure_run_stats()
		run_stats.damage_received += maxf(0.0, hp_before - float(a.hp))
		if a.dead:
			run_stats.fatal_source = source_kind
			run_stats.fatal_attack = source_attack
			# P9 — impacto da queda: micro-pausa forte + onda de choque no corpo.
			hit_stop(0.32); effects.append({"p": a.p, "kind": "shockwave", "life": 0.55, "max": 0.55, "r": 120.0})

# Inimigos das Docas de 1941 e o Almirante das Profundezas.
#   cult   Cultista Atirador      orbe magenta, distância média
#   fish   Arpoador das Profundezas  arpão lento e forte que prende (reduz a velocidade)
#   crawler Rastejante Tentacular ácido de curta distância; ao morrer vira duas bolhas menores
#   brute  Soldado Possuído       leque de balas violeta
func detection_range(a: Dictionary, base: float) -> float:
	# Disfarce de Londres: inimigos só notam Marty mais de perto.
	return base * 0.55 if outfit_of(a) == "espiao" and not a.mech else base

func step_entry_onboarding() -> void:
	if mode != "run": return
	var first_threat := enemies.any(func(e): return e.get("room", "") == "entry" and e.kind == "crawler" and e.hp > 0)
	var players_left := actors.any(func(a): return a.active and not a.dead and room_at(a.p).get("id", "") not in ["entry", ""])
	var near_entry := actors.any(func(a): return a.active and not a.dead and room_at(a.p).get("id", "") == "entry")
	if near_entry and not story_flags.get("treino_docas", false):
		story_flags["treino_docas"] = true
		say("DESEMBARQUE • observe o salto do rastejante. Salte sobre poças de ácido e tentáculos; use o dash para evitar tiros. Ômega e Azul mantêm proteção no ar.")
	if not first_threat or players_left:
		for e in enemies:
			if e.get("onboarding_wait", false): e.onboarding_wait = false; e.cd = maxf(e.cd, 1.2)

func step_enemies(dt: float) -> void:
	step_entry_onboarding()
	step_combat_zones(dt)
	# 0.15: o portal aparece primeiro; só materializa o inimigo depois de 0,8s.
	var ready_spawns: Array = []
	for pending in pending_spawns:
		pending.timer -= dt
		if pending.timer <= 0: ready_spawns.append(pending)
	if not pending_spawns.is_empty(): arena_wait = 0.0
	pending_spawns = pending_spawns.filter(func(p): return p.timer > 0)
	for pending in ready_spawns:
		if pending.has("boss_owner"):
			if not enemies.any(func(owner):return owner.id==pending.boss_owner and owner.hp>0): continue
			if not clear_at(pending.p,12): continue
		spawn_enemy(pending.p, pending.kind)
		var spawned_enemy: Dictionary = enemies[-1]
		if pending.has("boss_owner"):
			spawned_enemy["boss_owner"]=pending.boss_owner
			spawned_enemy["alerted"]=true
		spawned_enemy.hp *= pending.hp_scale; spawned_enemy.max = spawned_enemy.hp
		spawned_enemy.damage_scale = pending.damage_scale
	var spawned: Array = []
	for e in enemies:
		e.hurt = maxf(0, e.hurt - dt); e.shot = maxf(0, e.shot - dt); e.moving = false
		if e.hp <= 0: continue
		recover_enemy_room(e)
		if RayEncounter.step(self,e,dt): continue
		if e.get("stunned", false) or e.get("onboarding_wait", false): continue  # espera captura ou primeiro confronto
		if e.get("dormant", false):
			var woken := false
			for sleeper_check in actors:
				if sleeper_check.active and not sleeper_check.dead and sleeper_check.p.distance_to(e.p) < 320: woken = true
			if not woken: continue
			e["dormant"] = false; e["alerted"] = true
			effects.append({"p": e.p, "kind": "summon", "life": 0.5, "dir": Vector2.UP})
			emit_audio("enemy_guard", e.p)
			say("%s ACORDOU • robô de guerra corrompido pelo culto — atordoe e capture!" % ROBOT_NAMES.get(e.kind, e.kind.to_upper()))
			if not story_flags.has("missao_robo"): story_flags["missao_robo"] = "capturar"
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
		if e.get("capturable", false) and not e.get("stunned", false):
			# Derrotado ≠ destruído: fica atordoado esperando a robobola.
			e["stunned"] = true; e.hp = 60.0; e.combat = "ready"; e.combat_t = 0.0
			hit_stop(0.06)
			effects.append({"p": e.p, "kind": "summon", "life": 0.5, "dir": Vector2.UP})
			say("%s ATORDOADO • aproxime-se e pressione E para lançar uma ROBOBOLA." % ROBOT_NAMES.get(e.kind, e.kind.to_upper()))
			if TitanRecovery.original(self,e): say("TITAN NEUTRALIZADO • E para recuperar o chassi protegido pelo culto.")
			continue
		emit_audio("enemy_die", e.p)
		if e.kind in ["fish", "crawler"]: bark("Vamos ter polvo pro jantar.", 0.22)
		elif e.kind == "boss": bark("Grande demais pro cais dele.", 1.0)
		else: bark("Mais um que não volta pro culto.", 0.08)
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
			pickups.append({"p": e.p + Vector2(-15, 0), "kind": "ammo", "weapon": "bazooka", "ammo": 10})
		effects.append({"p": e.p, "kind": "corpse", "enemy": e.kind, "life": 2.6 if e.kind == "boss" else 2.0, "max": 2.6 if e.kind == "boss" else 2.0, "face": e.face, "flip": e.face.x < 0})
		if e.kind == "crawler":
			for off in [Vector2(-18, 6), Vector2(18, -6)]:
				if clear_at(e.p + off, 10): spawned.append([e.p + off, e.side])
		if e.kind == "warden" or e.get("miniboss", false):
			chests.append({"p": e.p, "open": false, "secret": false, "reward": true})
			say("GUARDIÃO DA MARÉ DERROTADO • baú do culto liberado! [E]" if e.kind == "warden" else "MINIBOSS DERROTADO • baú dourado sem chave! [E]")
		if e.kind == "lobo":
			robobolas += 2; hit_stop(0.09)
			say("LOBO-9 DESTRUÍDO • +2 ROBOBOLAS — Marty: \"As duas bolas do LOBO são minhas. Eu sei o que eu disse.\"")
		if e.kind == "boss": boss_dead = true; say("O Almirante afundou! Use o portal da arena para recuperar o núcleo e retornar.")
	enemies = enemies.filter(func(e): return e.hp > 0)
	var live_boss_ids:=enemies.filter(func(e):return e.kind=="boss").map(func(e):return e.id)
	enemies=enemies.filter(func(e):return not e.has("boss_owner") or e.boss_owner in live_boss_ids)
	pending_spawns=pending_spawns.filter(func(p):return not p.has("boss_owner") or p.boss_owner in live_boss_ids)
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
		e.p = move_enemy_body(e, e.charge_dir * 850.0 * dt, 48)
		e.moving = true; e.step += dt * 18
		# Sweep contact along the actual collision-constrained movement.
		for a in actors:
			if a.active and not a.dead and Geometry2D.get_closest_point_to_segment(a.p, before, e.p).distance_to(a.p) < 62 and line_of_fire(e.p, a.p): damage_actor(a, 32, "warden", "charge", e.charge_dir * 620)
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
	e.p = move_enemy_body(e, direction * 300.0 * dt, 48)
	e.moving = e.p.distance_to(before) > 0.1; e.step += dt * 10

func enrage_scale(e: Dictionary) -> float:
	return BOSS_ENRAGE_SCALE if e.get("enraged", false) else 1.0

func step_boss(e: Dictionary, target: Dictionary, direction: Vector2, closest: float, dt: float) -> void:
	step_boss_brood(e,dt)
	if boss_motion(e, target, dt): return
	direction=(target.p-e.p).normalized(); closest=e.p.distance_to(target.p)
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
			add_bullet(e.p + direction * BOSS_RADIUS, direction, 1, 24, 270, 13, -1, "cannon", 4.0)
		return
	if e.spin > 0:
		e.spin -= dt; e.cd -= dt
		if e.cd <= 0:
			e.cd = 0.09 * enrage_scale(e); e.spin_angle += 0.42
			emit_audio("enemy_boss", e.p)
			var streams := 3 if stage == 2 else 4
			for k in range(streams):
				add_bullet(e.p, Vector2.RIGHT.rotated(e.spin_angle + k * TAU / streams), 1, 10, 215, 6, -1, "orb")
		return
	e.cd -= dt
	if e.cd > 0: return
	e.phase += 1
	match stage:
		1:
			emit_audio("enemy_boss", e.p)
			e.shot = 0.4; e.cd = 0.85 * enrage_scale(e)
			if e.phase % 2 == 1:
				for n in range(22): add_bullet(e.p, Vector2.RIGHT.rotated(n * TAU / 22 + e.phase * 0.2), 1, 12, 205, 7, -1, "orb")
			else:
				for n in range(9): add_bullet(e.p, direction.rotated((n - 4) * 0.12), 1, 10, 285, 6, -1, "orb")
		2:
			if e.phase % 3 == 0: e.charge = 0.9; e.cd = 1.0 * enrage_scale(e)
			else: e.spin = 2.2; e.cd = 0.0
		3:
			e.shot = 0.4; e.cd = 0.65 * enrage_scale(e)
			emit_audio("enemy_boss", e.p)
			match e.phase % 3:
				0:
					for n in range(5): add_bullet(e.p, direction.rotated((n - 2) * 0.24), 1, 14, 160, 11, -1, "ink", 4.5)
				1:
					add_bullet(e.p, direction, 1, 18, 370, 6, -1, "harpoon")
					bullets[-1]["source"] = "boss"
					if closest < 260:
						for n in range(8): add_bullet(e.p + direction * BOSS_RADIUS, direction.rotated((n - 3.5) * 0.1), 1, 8, 340, 8, -1, "flame", 0.7)
				2:
					for n in range(26): add_bullet(e.p, Vector2.RIGHT.rotated(n * TAU / 26 + e.phase * 0.3), 1, 12, 235, 7, -1, "orb")

func muzzle_line_clear(from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1, ceili(from.distance_to(to) / 2.0))
	for step in range(1, steps + 1):
		if not clear_at(from.lerp(to, float(step) / steps), 0, true): return false
	return true

func hit_bullet_enemy(b: Dictionary, check_wall: bool = false) -> void:
	for e in enemies:
		if e.get("stunned", false): continue
		if b.p.distance_to(e.p) < (48 if e.kind == "warden" else (BOSS_RADIUS if e.kind == "boss" else (12 if e.kind == "crawler_small" else 19))) + b.r:
			var previous_hits: Array = b.get("hits", [])
			if previous_hits.has(e.id): continue
			if e.hp <= 0: continue
			if (check_wall or b.get("kind", "") == "p_omega") and not muzzle_line_clear(b.p, e.p): continue
			if (e.kind == "guard" or e.get("elite", "") == "shield") and not (e.kind == "guard" and e.combat == "attack") and -b.v.normalized().dot(e.face) > 0 and b.get("kind", "") not in ["p_omega", "p_rocket"]:
				b.team = 1; b.v = -b.v; b["owner"] = -1; b.p += b.v.normalized() * 12
				effects.append({"p": b.p, "kind": "impact", "omega": false, "life": 0.18, "max": 0.18}); break
			hurt_enemy(e, b.damage); e.hurt = 0.12; e["alerted"] = true
			if b.get("kind", "") == "p_rocket":
				explode(b.p, 72, 30, false); b.life = 0; break
			# 0.15: número de dano + empurrão leve no impacto (pesada empurra mais)
			pop_dmg(e.p, b.damage, b.get("kind", "") in ["p_heavy", "p_omega"])
			if e.kind not in ["boss", "warden"]:
				e.p = move_enemy_body(e, b.v.normalized() * (14.0 if b.get("kind", "") == "p_heavy" else 4.0), 12 if e.kind == "crawler_small" else 14)
			if b.get("shell_splash", false):
				var heavy_hits: Array = b.get("hits", []); heavy_hits.append(e.id)
				for other in enemies:   # respingo não repete o dano no alvo direto
					if not heavy_hits.has(other.id) and other.p.distance_to(b.p) < MECH_SHELL.splash + 19 and line_of_fire(b.p, other.p):
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
				if b.get("ray_missile",false): b.life=0; continue
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
				if mode == "run" and not b.get("shell_splash", false): damage_obstacle(obstacle_at(b.p), b.damage * (0.5 if b.team == 1 else 1.0))
				if b.get("shell_splash", false): explode(b.p, MECH_SHELL.splash, MECH_SHELL.splash_damage, false)
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
						if jump_evades(a, "projectile", str(b.get("kind", ""))) or a.dodge > 0: continue
						var bullet_source := str(b.get("source", {"cannon": "boss", "orb": "boss", "ink": "boss", "flame": "boss", "violet": "brute", "magenta": "cult"}.get(b.get("kind", ""), "unknown")))
						# 0.22: arpão já prende/reduz velocidade (snare) — empurrão aqui conflitaria com isso.
						var hit_knockback: Vector2 = Vector2.ZERO if b.get("kind", "") == "harpoon" else b.v.normalized() * 420
						damage_actor(a, b.damage, bullet_source, str(b.get("kind", "projectile")), hit_knockback); b.life = 0
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
				elif pickup.kind == "weapon":
					grant_run_weapon(a, pickup.weapon, int(pickup.ammo))
					bark("Agora simmm! Isso aqui muda o jogo.", 0.85)
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
	var known_robots: Array = ["", "titan", "spectre"] + captured_robots
	if outfit not in OUTFITS or robot not in known_robots or armor_type not in ARMORS: return false
	if not is_unlocked(outfit) or (robot != "" and not is_unlocked(robot) and robot not in captured_robots):
		say("Esse item ainda está bloqueado."); return false
	var a: Dictionary = actors[id]
	if a.dead: return false
	if a.armor and armor_type != a.armor_type:
		say("Guarde a transformação antes de trocar de forma."); return false
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
	else:
		var inventory := InventoryState.new(inventory_state)
		for robot_id in ["titan", "spectre"]:
			var entry := robot_module_entry(robot_id)
			if is_unlocked(robot_id) and not entry.is_empty() and inventory.quantity(entry.id) > 0: result.append(robot_id)
	# Robôs capturados em combate pertencem à equipe toda.
	for robot_id in captured_robots:
		if robot_id not in result: result.append(robot_id)
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
	elif a.selected_robot != "titan" and spectres[a.id].state == "following":
		effects.append(SummonFX.recall_effect(a.id, a.p - Vector2(0, 30), spectres[a.id].p, spectres[a.id].get("kind", "spectre"))); spectres[a.id].state = "stored"

func select_owned_robot(a: Dictionary, robot_id: String) -> bool:
	if robot_id == a.selected_robot: return true
	if robot_id not in owned_robot_ids(a.id): say("Esse módulo de robô não está disponível."); return false
	if not can_switch_robot(a): return false
	store_selected_robot(a); a.selected_robot = robot_id
	say("ROBÔ SELECIONADO • %s" % ROBOT_NAMES.get(robot_id, robot_id.to_upper()))
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
	if a.selected_robot == "" or (not is_unlocked(a.selected_robot) and a.selected_robot not in captured_robots):
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
	var ally_name: String = ROBOT_NAMES.get(a.selected_robot, a.selected_robot.to_upper())
	if s.hp <= 0: say("%s destruído. Recuperação na próxima tentativa." % ally_name); return false
	if s.state == "following":
		effects.append(SummonFX.recall_effect(a.id, a.p - Vector2(0, 30), s.p, s.get("kind", "spectre")))
		s.state = "stored"; a.summon_cd = 3; say("%s recolhido. Energia preservada." % ally_name); return true
	var pos := free_summon_position(a, 14)
	if not pos.is_finite(): say("Sem espaço livre para invocar %s." % ally_name); return false
	s.p = pos; s.state = "following"; s["kind"] = a.selected_robot
	s.hp = GOLEM_HP if s.kind == "golem" else (SENTINELA_HP if s.kind == "sentinela" else SPECTRE_HP)
	a.summon_cd = 6
	effects.append(SummonFX.summon_effect(a.id, a.p - Vector2(0, 30), pos, s.kind))
	if s.kind in ["sentinela", "golem"] and story_flags.get("missao_robo", "") == "invocar":
		story_flags["missao_robo"] = "concluida"; materials += 4
		say("MISSÃO CUMPRIDA • %s responde ao seu chamado. +4 fragmentos." % ally_name)
	else:
		say("%s INVOCADO • acompanha e atira.%s" % [ally_name, " G para fundir / separar." if s.kind == "spectre" else ""])
	return true

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
	if s.get("kind", "spectre") != "spectre" or s.state != "following" or s.hp <= 0:
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
		if not owner_actor.active or owner_actor.dead or owner_actor.selected_robot != s.get("kind", "spectre"): s.state = "stored"; continue
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
		var ally_kind: String = s.get("kind", "spectre")
		var shot_def: Dictionary = GOLEM_SHOT if ally_kind == "golem" else (SENTINELA_SHOT if ally_kind == "sentinela" else SPECTRE_SHOT)
		var target := nearest_enemy(s.p, 520)
		if not target.is_empty() and line_of_fire(s.p, target.p):
			s.aim = (target.p - s.p).normalized()
			if s.shot <= 0:
				add_bullet(s.p + s.aim * 20, s.aim, 0, shot_def.damage, 480 if ally_kind == "golem" else 600, 7 if ally_kind == "golem" else 4, s.owner)
				emit_audio("spectre", s.p)
				s.shot = shot_def.cooldown

func snapshot() -> Dictionary:
	var data := {}
	data["dialogue_owner"] = dialogue_owner
	data["reward_claimed"] = reward_claimed
	data["scenario_geometry_revision"] = scenario_geometry_revision
	data["scenario_module_ids"] = scenario_module_ids.duplicate()
	for field in ["procedural_enabled","layout_manifest","run_points","run_corridors","run_secret_floors","room_offsets","run_corridor_groups"]: data[field] = get(field)
	data["audio_events"] = audio_events.duplicate(true)
	data["audio_sequence"] = audio_sequence
	data["spectres"] = spectres
	for name in ["actors", "enemies", "bullets", "pickups", "effects", "rooms", "floors", "obstacles", "chests", "mech", "seed_value", "mode", "money", "keys", "materials", "run_materials_start", "upgrade", "clears", "armor_unlocked", "unlocked", "inventory_state", "story_quest", "dialogue_queue", "combat_zones", "harpoons", "pending_spawns", "side_active", "side_complete", "side_time", "side_failed", "boss_dead", "boss_intro_seen", "secret_open", "story_flags", "warden_intro_seen", "first_victory_beat", "whisper_cd", "message", "message_time", "coop", "tick_time", "shop_bought", "arena_wave", "obstacle_kinds", "decor", "visited", "ramps", "raised", "gaps", "doors", "gate_blocks", "hazards", "tentacle_gates", "obstacle_hp", "fuses", "hitstop", "clutch_t", "clutch_cd", "streak", "streak_t", "run_stats", "death_cine", "death_seq_started", "extract_state", "extract_t", "extract_actor", "last_run_summary", "summary_seq", "robobolas", "captured_robots", "capture_hint_seen", "rescue_npcs", "dog", "bike", "bike_npc", "bridge_timer", "bridge_broken", "bridge_done", "route_hint_seen"]:
		data[name] = get(name)
	return data

func apply_snapshot(data: Dictionary) -> void:
	if not data.has("dialogue_owner"): dialogue_owner = ""; dialogue_queue.clear()
	var previous_layout := layout_manifest
	if not data.has("layout_manifest"):
		layout_manifest = {}; room_offsets = {}; run_corridor_groups = []; procedural_enabled = false
		run_points = DOCKS.POINTS.duplicate(); run_corridors = DOCKS.CORRIDORS.duplicate(); run_secret_floors = [DOCKS.SECRET_CORRIDOR]
	var allowed := snapshot().keys()
	for name in data:
		if name in allowed and name not in ["inventory_state", "audio_events", "audio_sequence"]: set(name, data[name])
	if mode == "run" and room_by_id("bridge").is_empty():
		if not data.has("run_points"):
			run_points["bike"] = Vector2(4460, 2580)
			run_points["bike_checkpoint"] = Vector2(4300, 2700)
			run_points["boss"] = Vector2(4200, 1200)
			run_points["extraction"] = Vector2(4200, 720)
		if not data.has("run_corridors"):
			run_corridors = DOCKS.CORRIDORS.filter(func(rect): return rect != Rect2(3300, 0, 200, 3700))
			run_corridors.append_array([Rect2(1700, 1500, 1300, 200), Rect2(3300, 2200, 200, 200), Rect2(3300, 3200, 200, 500), Rect2(4300, 3200, 200, 500)])
	for a in actors:
		if not a.has("basic_weapon"): a["basic_weapon"] = uniform_of(a).weapon
		if not a.has("claw_cd"): a["claw_cd"] = 0.0
	if mode != "run" or not "docks.farol.pilot" in data.get("scenario_module_ids",[]):
		scenario_modules.clear(); scenario_module_ids.clear()
	elif scenario_modules.is_empty() or previous_layout != layout_manifest or scenario_modules.get("stairs",{}).get("origin",Vector2.INF) != room_by_id("stairs").r.position:
		var module := FarolRuntime.instance_for(self)
		if not module.is_empty(): scenario_modules["stairs"] = module
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
	if not story_flags is Dictionary: story_flags = {}
	unlocked["omega"] = true
	unlocked["azul"] = true
	unlocked["supernova"] = true
	if data.get("inventory_state") is Dictionary: inventory_state = InventoryState.new(data.inventory_state).to_dict()
	else: inventory_state = InventoryState.new(inventory_state).to_dict()
	var migrated_inventory := InventoryState.new(inventory_state)
	for starting_form in ["forma_azul","armadura_supernova"]:
		if migrated_inventory.quantity(starting_form) == 0:
			# Initial transformation entitlement must never displace existing inventory items.
			if migrated_inventory.used_slots() >= migrated_inventory.capacity:
				migrated_inventory.capacity = mini(120, migrated_inventory.capacity + 1)
			migrated_inventory.add(starting_form)
	inventory_state = migrated_inventory.to_dict()
	if not run_stats is Dictionary or run_stats.is_empty(): run_stats = fresh_run_stats()
	if not last_run_summary is Dictionary: last_run_summary = {}
	if mode=="run" and int(data.get("scenario_geometry_revision",0))<2:
		FarolRuntime.install_geometry(self)
		refresh_chapel_geometry()
		scenario_geometry_revision = 2
		ob_grid_count = -1
	if mode=="run" and int(data.get("scenario_geometry_revision",0))<3:
		SanctuaryFixed.install(self)
	if mode=="run" and int(data.get("scenario_geometry_revision",0))<4:
		CranesFixed.install(self)
	if mode=="run" and int(data.get("scenario_geometry_revision",0))<5:
		WarehouseFixed.install(self)
	TitanRecovery.install_copy(self)
	if mode=="run":
		SanctuaryFixed.align_east_passage(self)
		SanctuaryFixed.align_south_passage(self)

func story_npc_position() -> Vector2:
	return STORY_NPC + room_offsets.get("chapel",Vector2.ZERO)

func refresh_chapel_geometry() -> void:
	var offset: Vector2 = room_offsets.get("chapel",Vector2.ZERO)
	for i in obstacles.size():
		if obstacle_kinds[i]=="altar": obstacles[i]=Rect2(Vector2(1095,3910)+offset,Vector2(210,40))


# ── 0.14: números da tela de Equipamento, sempre calculados das mesmas constantes do jogo ──
# Cada linha: {label, valor exibido, fração 0..1 para a barra (-1 = sem barra), cor}
func loadout_stats(kind: String, outfit: String = "padrao") -> Array:
	var u: Dictionary = UNIFORMS.get(outfit, UNIFORMS.padrao)
	var rows: Array = []
	match kind:
		"supernova":
			rows=[["CORAÇÕES","3 + 3 escudo",-1.0,"hearts_shield"],["VELOCIDADE","430",1.0,"orange"],["PLASMA","32 de dano",0.46,"gold"],["PULSO SOLAR","72 • raio 210",1.0,"orange"],["RECARGA PULSO","6s",-1.0,"violet"],["DURAÇÃO","300s",1.0,"green"],["RECARGA","60s",0.5,"violet"]]
		"azul":
			var ar: Dictionary = ARMORS.azul
			rows = [["CORAÇÕES", "%d + %d escudo" % [BASE_HEARTS, OMEGA_SHIELD_HEARTS], -1.0, "hearts_shield"],
				["VELOCIDADE", str(int(ar.speed)), ar.speed / 430.0, "cyan"],
				["GARRA", "%d de dano" % BLUE_CLAW_DAMAGE, BLUE_CLAW_DAMAGE / 70.0, "cyan"],
				["ALCANCE", "%d" % BLUE_CLAW_RANGE, 1.0, "cyan"],
				["RECARGA GARRA", "%.1fs" % BLUE_CLAW_COOLDOWN, -1.0, "violet"],
				["DURAÇÃO", "%ds" % int(ar.duration), 1.0, "green"],
				["RECARGA", "%ds" % int(ar.cooldown), 0.5, "violet"]]
		"omega":
			var ar: Dictionary = ARMORS.omega
			rows = [["CORAÇÕES", "%d + %d escudo" % [BASE_HEARTS, OMEGA_SHIELD_HEARTS], -1.0, "hearts_shield"],
				["VELOCIDADE", str(int(ar.speed)), ar.speed / 430.0, "cyan"],
				["ENERGIA", "%d / %d / %d" % [SWORD.hit, SWORD.hit, SWORD.finisher], SWORD.finisher / 70.0, "orange"],
				["ESFERA FINAL", "%d (atravessa)" % SWORD.finisher, SWORD.finisher / 70.0, "gold"],
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
		if not is_unlocked(a.selected_robot) and a.selected_robot not in captured_robots: a.selected_robot = default_robot()
	apply_unlock_state()
	reconcile_robot_entitlements()

func unlock(id: String) -> bool:
	if is_unlocked(id) or EquipmentData.item(id).is_empty(): return false
	unlocked[id] = true; new_unlocks.append(id)
	if id in ["titan", "spectre"]: reconcile_robot_entitlements()
	for a in actors:
		if a.selected_robot == "" and id in ["titan", "spectre"]: a.selected_robot = id
	if id == "titan" and mode == "run" and mech.occupant == -1: mech.deployed = true   # o Titan estava guardado na Oficina
	apply_unlock_state()
	say("DESBLOQUEADO • %s • veja no Equipamento." % EquipmentData.item(id).get("nome", id.to_upper()))
	return true

# Avalia as regras de desbloqueio de cada item: inicio | sala | desafio | chefe | expedicoes.
func check_unlocks() -> void:
	if side_complete: story_flags["titan_power"] = true
	for it in EquipmentData.items():
		if is_unlocked(it.id): continue
		var cond: Dictionary = it.get("desbloqueio", {})
		var ok := false
		match str(cond.get("tipo", "")):
			"inicio": ok = true
			"sala": ok = mode == "run" and visited.has(str(cond.get("sala", "")))
			"desafio": ok = side_complete
			"chefe": ok = TitanRecovery.ready(self) if it.id == "titan" else armor_unlocked
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
	else: grant_run_weapon(a, "bazooka", 15)
	effects.append({"p":chest.p,"kind":"chest_burst","life":1.3,"max":1.3,"secret":true})

func trap_phase(h: Dictionary) -> String:
	var t := fposmod(tick_time + float(h.get("offset",0)),4.0)
	return "safe" if t < 2.2 else ("warning" if t < 3.0 else "active")

func near_water(p: Vector2) -> bool:
	for gap in gaps:
		if gap.grow(140).has_point(p): return true
	return false

func altar_position() -> Vector2:
	for i in range(obstacles.size()):
		if obstacle_kinds[i] == "altar": return obstacles[i].get_center()
	return Vector2.INF

# A pista da Ordem é determinística: ler o altar uma vez basta; a meta flag persiste entre expedições.
func altar_interact(_a: Dictionary) -> void:
	if story_flags.get("ordem_pista", false):
		say("O altar repete a maré negra do selo. Nada de novo sob a pedra molhada.")
		return
	story_flags["ordem_pista"] = true; materials += 1
	say("ALTAR PROFANADO • ORDEM DA MARÉ NEGRA. O medalhão tem a mesma assinatura dos atacantes da nave. Coral precisa explicar isso. +1 fragmento • pista no Diário")

# P6 — lançar a robobola num robô atordoado o traz para a equipe.
# P7 — sobrevivente resgatado: agradece, entrega arma nova e apresenta o cachorro.
func spawn_rescue_npc(npc_def: Dictionary) -> void:
	if rescue_npcs.any(func(n): return n.room == npc_def.room): return
	var room := room_by_id(npc_def.room)
	if room.is_empty(): return
	var pos: Vector2 = room.r.get_center()
	if not clear_at(pos, 16):
		for radius in [80, 140, 200]:
			var found := false
			for n in range(8):
				var c: Vector2 = room.r.get_center() + Vector2.from_angle(TAU * n / 8) * radius
				if clear_at(c, 16): pos = c; found = true; break
			if found: break
	rescue_npcs.append({"p": pos, "name": npc_def.name, "weapon": npc_def.weapon, "ammo": npc_def.ammo, "thanks": npc_def.thanks, "room": npc_def.room, "thanked": false})
	say("Um sobrevivente surge do esconderijo em %s • vá falar com %s." % [room.get("name", npc_def.room), npc_def.name])

func rescue_interact(a: Dictionary, npc: Dictionary) -> void:
	if not npc.get("thanked", false):
		npc["thanked"] = true
		pickups.append({"p": npc.p + Vector2(56, 18), "kind": "weapon", "weapon": npc.weapon, "ammo": int(npc.ammo)})
		var text: String = npc.thanks
		if not story_flags.get("missao_cachorro", false):
			story_flags["missao_cachorro"] = "procurar"
			text += " E olha — vi um GOLDEN GORDO de língua gigante sumir pelos túneis. Ache o cachorro, Marty."
		emit_audio("pickup", npc.p)
		say(text)
		return
	if story_flags.get("missao_cachorro", "") == "procurar":
		say("%s: o golden continua por aí. Procure onde a água é mais rasa." % npc.name)
	else:
		say("%s: o porto agradece, Marty." % npc.name)

# P8 — GOLDEN: golden retriever gordo e redondo, mutação = língua gigante +
# teleporte. Esconde-se na sala secreta (Contrabando); ao ser achado lambe Marty,
# restaura a vida inteira e teleporta para o Refúgio, onde passa a morar.
func step_dog(dt: float) -> void:
	if mode == "run":
		if dog.is_empty():
			if story_flags.get("missao_cachorro", "") == "encontrado": return
			var secret_room := room_by_id("secret")
			if secret_room.is_empty(): return
			dog = {"p": secret_room.r.get_center() + Vector2(0, 60), "state": "hiding", "lick_t": 0.0, "t": 0.0}
		dog.t += dt
		match dog.state:
			"hiding":
				for a in actors:
					if a.active and not a.dead and a.p.distance_to(dog.p) < 110:
						dog.state = "licking"; dog.lick_t = 0.9; dog["target"] = a.id
						a.hp = max_hp()  # a lambida restaura a vida toda
						effects.append({"p": a.p - Vector2(0, 78), "kind": "heart", "life": 1.5, "max": 1.5})
						emit_audio("pickup", dog.p)
						say("Marty: espera— um GOLDEN?! E essa LÍNGUA?! ...Ok. Agora simmm!")
						break
			"licking":
				dog.lick_t -= dt
				if dog.lick_t <= 0:
					dog.state = "gone"
					effects.append({"p": dog.p, "kind": "summon", "life": 0.7, "max": 0.7, "dir": Vector2.UP})
					story_flags["missao_cachorro"] = "encontrado"
					say("O golden lambeu suas feridas (CURA TOTAL) e teleportou de volta ao Refúgio!")
	elif mode == "hub" and story_flags.get("missao_cachorro", "") == "encontrado":
		if hub_dog.is_empty(): hub_dog = {"p": Vector2(790,440), "t": 0.0, "waypoint": 0}
		# Recover old sessions whose previous orbit put the dog outside the floor.
		if not clear_at(hub_dog.p,HUB_DOG_RADIUS):
			var nearest := Vector2.INF
			var distance := INF
			for candidate in HUB_DOG_ROUTE:
				if clear_at(candidate,HUB_DOG_RADIUS) and candidate.distance_to(hub_dog.p)<distance:
					nearest=candidate; distance=candidate.distance_to(hub_dog.p)
			if nearest==Vector2.INF:
				hub_dog["velocity"]=Vector2.ZERO
				return
			hub_dog.p=nearest
		hub_dog.t += dt
		if hub_dog.get("state", "idle") == "licking":
			hub_dog["velocity"] = Vector2.ZERO
			hub_dog.lick_t -= dt
			if hub_dog.lick_t <= 0: hub_dog.state = "idle"
			return
		# Walk only across the free central floor, using the same swept collision as actors.
		var waypoint := int(hub_dog.get("waypoint",0)) % HUB_DOG_ROUTE.size()
		var target: Vector2 = HUB_DOG_ROUTE[waypoint]
		if hub_dog.p.distance_to(target)<3.0:
			waypoint=(waypoint+1)%HUB_DOG_ROUTE.size()
			target=HUB_DOG_ROUTE[waypoint]
		hub_dog["waypoint"]=waypoint
		var dog_previous: Vector2 = hub_dog.p
		hub_dog.p = move_body(dog_previous,(target-dog_previous).limit_length(HUB_DOG_SPEED*maxf(dt,0.0)),HUB_DOG_RADIUS)
		hub_dog["velocity"] = (hub_dog.p-dog_previous)/maxf(dt,0.001)
		hub_dog["blocked_t"] = float(hub_dog.get("blocked_t",0.0))+dt if hub_dog.p.distance_to(dog_previous)<0.01 else 0.0
		if hub_dog.blocked_t>1.0:
			hub_dog["waypoint"]=(waypoint+1)%HUB_DOG_ROUTE.size()
			hub_dog.blocked_t=0.0

func capture_robot(a: Dictionary, e: Dictionary) -> void:
	if RayEncounter.owns(self,e) and e.get("ray_state","") not in ["active","defeated"] and not (e.get("stunned",false) and not e.has("ray_state")): return
	if not enemies.has(e) or not e.get("capturable", false) or not e.get("stunned", false): return
	if TitanRecovery.secure(self,e): return
	if robobolas <= 0:
		say("Sem ROBOBOLAS • o LOBO-9 do Mercado carrega duas. Derrote-o primeiro.")
		return
	robobolas -= 1
	var robot_kind: String = e.kind
	enemies.erase(e)
	if robot_kind not in captured_robots: captured_robots.append(robot_kind)
	effects.append(SummonFX.summon_effect(a.id, a.p - Vector2(0, 30), e.p, robot_kind))
	emit_audio("pickup", e.p)
	var robot_name: String = ROBOT_NAMES.get(robot_kind, robot_kind.to_upper())
	if story_flags.get("missao_robo", "") in ["", "capturar"]:
		story_flags["missao_robo"] = "invocar"
		materials += 3
		say("%s CAPTURADO! • missão concluída, +3 fragmentos • nova missão: invoque-o (selecione com V, invoque com C)." % robot_name)
	else:
		say("%s CAPTURADO! • V troca de robô, C invoca." % robot_name)

# P7 — seção Missões: objetivo, progresso e recompensa. Cada flag garante que a
# recompensa só é entregue uma vez (os says de recompensa verificam a flag).
func missions_list() -> Array:
	var list: Array = []
	list.append(TitanRecovery.mission(self))
	var crew_lead: bool = story_flags.get("sinal_leticia", false) or story_flags.get("peca_titan", false)
	list.append({"title": "SINAIS DA TRIPULAÇÃO", "objective": "Recupere o núcleo para rastrear Letícia, Vincent, Elias e Íris" if not crew_lead else "Leia no Diário a mensagem recuperada de Letícia", "progress": "quatro amigos desaparecidos" if not crew_lead else "sinal de Letícia recuperado; era ainda não localizada", "reward": "primeira pista da tripulação", "done": crew_lead})
	if route_hint_seen or story_flags.get("rotas_docas", false):
		list.append({"title": "CAMINHO DO ALMIRANTE", "objective": "Ponte: Ômega + moto, mantenha a velocidade. Mangue: a pé, vença Raíz-Podre", "progress": "As duas rotas chegam ao Almirante; a ponte desaba, o mangue permite parar", "reward": "acesso ao núcleo", "done": boss_dead})
	list.append({"title": "O NÚCLEO DO ALMIRANTE", "objective": "Derrote o Almirante das Profundezas e extraia o núcleo",
		"progress": "concluída" if reward_claimed else ("chefe abatido — vá à extração" if boss_dead else "em andamento"),
		"reward": "peça TITAN-01, selo da Ordem, +3 fragmentos", "done": reward_claimed})
	var cellar := room_by_id("cellar")
	var cellar_clean: bool = visited.has("cellar") and not enemies.any(func(e): return e.hp > 0 and cellar.r.has_point(e.p))
	match story_quest:
		0: list.append({"title": "O RITUAL DA ORDEM", "objective": "Fale com o Mestre Coral na capela", "progress": "não iniciada", "reward": "—", "done": false})
		1: list.append({"title": "O RITUAL DA ORDEM", "objective": "Purifique a Adega Inundada", "progress": "adega purificada — volte ao Mestre" if cellar_clean else "em andamento", "reward": "+4 fragmentos, +2 chaves, cura", "done": false})
		_: list.append({"title": "O RITUAL DA ORDEM", "objective": "Purifique a Adega Inundada", "progress": "concluída", "reward": "+4 fragmentos, +2 chaves, cura", "done": true})
	match story_flags.get("missao_robo", ""):
		"capturar": list.append({"title": "MÁQUINA NOVA", "objective": "Atordoe a cópia corrompida na Oficina do leste e capture com uma robobola", "progress": "em andamento", "reward": "robô capturado + 3 fragmentos", "done": false})
		"invocar": list.append({"title": "TESTE DE CAMPO", "objective": "Invoque o robô capturado (V seleciona, C invoca)", "progress": "em andamento", "reward": "+4 fragmentos", "done": false})
		"concluida": list.append({"title": "MÁQUINA NOVA", "objective": "Robô capturado e testado", "progress": "concluída", "reward": "robô + 7 fragmentos", "done": true})
	if story_flags.get("missao_cachorro", "") == "procurar":
		list.append({"title": "O BOM GAROTO", "objective": "Encontre o golden de língua gigante escondido na fase", "progress": "em andamento", "reward": "???", "done": false})
	elif story_flags.get("missao_cachorro", "") == "encontrado":
		list.append({"title": "O BOM GAROTO", "objective": "O golden foi encontrado e voltou pra base", "progress": "concluída", "reward": "cura + amizade eterna", "done": true})
	if side_active or side_complete or side_failed:
		list.append({"title": "PONTOS DO RITUAL", "objective": "Rompa os 7 pontos do ritual em 55s",
			"progress": "concluída" if side_complete else ("falhou" if side_failed else "%.0fs restantes" % side_time),
			"reward": "chassi Spectre, chaves, cura e fragmento", "done": side_complete})
	return list

func journal_entries() -> Array:
	var found: bool = story_flags.get("sinal_leticia", false) or story_flags.get("peca_titan", false)
	var entries: Array = [
		{"title": "LETÍCIA • SINAL RECUPERADO" if found else "LETÍCIA • SINAL PERDIDO", "text": "O núcleo guardava sua voz: 'Estou viva. Sigo a luz da nossa nave.' O sinal foi salvo no Refúgio; a era ainda precisa ser localizada." if found else "Separada de Marty no ataque à nave. Recuperar o núcleo das Docas pode revelar seu sinal."},
		{"title": "VINCENT • SINAL PERDIDO", "text": "Desaparecido na ruptura. Nenhuma coordenada confirmada; procurar registros da nave."},
		{"title": "ELIAS • SINAL PERDIDO", "text": "Piloto e estudioso das anomalias. Seu sinal continua perdido entre as fraturas."},
		{"title": "ÍRIS • SINAL PERDIDO", "text": "Médica da equipe, desaparecida com o Spectre original. Recuperar um chassi de apoio não significa ter encontrado Íris ou seu simbionte."}]
	if story_flags.get("ordem_pista", false) or story_flags.get("simbolo_ordem", false):
		entries.append({"title": "O ATAQUE À NAVE", "text": "O selo da Ordem da Maré Negra tem a assinatura dos atacantes da nave. O Almirante usava nosso núcleo para ampliar a fissura das Docas."})
	if story_flags.get("coral_acordo", false):
		entries.append({"title": "O ACORDO DE CORAL", "text": "Coral rompeu com o ritual do Almirante. Limpar a Adega protege os trabalhadores refugiados. Marty aceita essa trégua, sem aderir à Ordem."})
	if found:
		entries.append({"title": "TITAN-01", "text": "Recupere o chassi protegido pelo culto nos Guindastes, restaure a energia no Último Gerador e extraia o núcleo do Almirante. Após restaurar o Titan, C invoca e E pilota."})
	if is_unlocked("spectre"):
		entries.append({"title": "CHASSI SPECTRE", "text": "O Gerador fornece um chassi de apoio compatível com fusão. O Spectre original e Íris continuam desaparecidos."})
	if story_flags.get("treino_docas", false):
		entries.append({"title": "EVITAR AMEAÇAS", "text": "O salto comum evita ácido no chão e tentáculos, mas não tiros ou explosões. O dash evita impactos. Ômega e Azul preservam sua proteção durante o salto."})
	if story_flags.get("rotas_docas", false):
		entries.append({"title": "DUAS ROTAS", "text": "Na antessala: a Moto Temporal exige Ômega e cruza a ponte que desaba atrás de você. Pelo Mangue Negro é possível parar, mas Raíz-Podre guarda o caminho. Ambas levam ao Almirante."})
	return entries

func advance_dialogue(speaker: String) -> bool:
	if dialogue_owner != speaker:
		dialogue_queue.clear(); dialogue_owner = speaker
		return false
	if dialogue_queue.is_empty(): return false
	say(str(dialogue_queue.pop_front())); return true

func story_interact(a: Dictionary) -> void:
	if (story_flags.get("ordem_pista", false) or story_flags.get("simbolo_ordem", false)) and not story_flags.get("coral_confrontado", false):
		story_flags["coral_confrontado"] = true; story_flags["coral_acordo"] = true
		dialogue_owner = "coral"
		dialogue_queue = ["Mestre Coral: reconheço o selo. Rompi com o Almirante quando ele entregou nossos trabalhadores ao ritual. Não peço sua fé; peço que proteja quem ficou na Adega.", "Marty: salvamos os trabalhadores. Depois você me conta tudo sobre quem atacou minha nave. [E]"]
		say("Marty: esse selo estava no ataque à minha nave. Por que eu ajudaria a sua Ordem?"); return
	if advance_dialogue("coral"): return
	if story_quest == 0:
		story_quest = 1
		story_flags["coral_acordo"] = true
		dialogue_queue = ["Mestre Coral: trabalhadores se escondem na Adega Inundada. Purifique-a das criaturas e eu forneço suprimentos.","Marty: trato feito pelos trabalhadores. A Ordem vai ter que conquistar minha confiança. [E]"]
		say("Mestre Coral: pertenço à ORDEM DA MARÉ NEGRA, mas rompi com o ritual do Almirante. Aqui protejo os que ele abandonou. [E]")
	elif story_quest == 1:
		var cellar := room_by_id("cellar")
		if visited.has("cellar") and not enemies.any(func(e): return e.hp > 0 and cellar.r.has_point(e.p)):
			story_quest = 2; materials += 4; keys += 2; heal(a,2)
			say("Mestre Coral: os trabalhadores estão seguros. Cumpro nosso acordo: +4 materiais, +2 chaves e cura.")
		else: say("Mestre Coral: ainda há criaturas na Adega. Proteja os trabalhadores e volte pelos suprimentos.")
	else: say("Mestre Coral: os trabalhadores lembram de quem os ajudou, Marty. Nossa trégua continua.")

func step_boss_brood(e: Dictionary, dt: float) -> void:
	e["brood_cd"]=float(e.get("brood_cd",3.5))-dt
	if e.brood_cd>0: return
	var alive:=enemies.filter(func(child):return child.get("boss_owner",-1)==e.id and child.hp>0).size()
	alive+=pending_spawns.filter(func(child):return child.get("boss_owner",-1)==e.id).size()
	var amount:=mini(10-alive,4 if e.hp/e.max>0.66 else (5 if e.hp/e.max>0.33 else 6))
	var placed:=0
	for i in 24:
		if placed>=amount: break
		var point: Vector2=e.p+Vector2.RIGHT.rotated(i*TAU/12.0+e.phase*0.45)*(155.0+65.0*(i/12))
		var child_probe: Dictionary={"p":point,"room":e.get("room", ""),"kind":"crawler_small"}
		if not clear_at(point,12) or not enemy_room_position_valid(child_probe,point,12): continue
		if actors.any(func(a):return a.active and not a.dead and a.p.distance_to(point)<105): continue
		if pending_spawns.any(func(p):return p.p.distance_to(point)<35): continue
		pending_spawns.append({"p":point,"kind":"crawler_small","timer":1.0,"hp_scale":1.0,"damage_scale":0.8,"boss_owner":e.id})
		effects.append({"p":point,"kind":"spawn_portal","life":1.0,"max":1.0})
		placed+=1
	e["brood_cd"]=8.0 if e.hp/e.max>0.33 else 6.5
	if placed>0:
		e["brood_flash"]=0.7
		emit_audio("enemy_crawler",e.p)

func boss_motion(e: Dictionary, target: Dictionary, dt: float) -> bool:
	e["brood_flash"]=maxf(0,float(e.get("brood_flash",0.0))-dt)
	var state: String = e.get("motion", "idle")
	if state == "idle":
		if e.charge>0 or e.spin>0: return false
		e["motion_cd"] = float(e.get("motion_cd", 2.5))-dt
		if e.motion_cd > 0:
			var toward: Vector2=(target.p-e.p).normalized()
			var drift:=toward.orthogonal()*0.7+toward*clampf((e.p.distance_to(target.p)-290.0)/180.0,-1.0,1.0)
			var previous: Vector2=e.p
			e.p=move_enemy_body(e,drift.limit_length()*65.0*dt,BOSS_RADIUS)
			e.moving=e.p.distance_to(previous)>0.01; e.step+=dt*3.0
			return false
		var arena: Rect2 = room_by_id("boss").get("r", Rect2(e.p-Vector2(800,600),Vector2(1600,1200)))
		e["motion_cycle"]=int(e.get("motion_cycle",0))+1
		var flank: Vector2=(e.p-target.p).normalized().rotated(0.85 if e.motion_cycle%2==0 else -0.85)
		var destination: Vector2 = target.p+flank*280.0
		if not arena.grow(-80).has_point(destination): destination = arena.get_center()
		var reached: Vector2 = e.p
		for i in range(24): reached = move_enemy_body(e, (destination-e.p)/24.0,BOSS_RADIUS,reached)
		destination = reached
		if not clear_at(destination,BOSS_RADIUS) or destination.distance_to(e.p)<60: e.motion_cd=1.0; return false
		e["motion_to"]=destination; e["motion"]="warning"; e["motion_t"]=0.7
		e["motion_kind"]="dive" if e.hp/e.max <= 0.33 else ("charge" if e.hp/e.max <= 0.66 else "walk")
		return true
	e.motion_t -= dt
	if state == "warning":
		if e.motion_t <= 0:
			e.motion="moving"; e.motion_t=1.4
			e["motion_duration"]=1.4
		return true
	var delta: Vector2 = e.motion_to-e.p
	var progress:=clampf(1.0-e.motion_t/float(e.get("motion_duration",1.4)),0.0,1.0)
	var ease:=0.3+0.7*sin(progress*PI)
	var previous: Vector2=e.p
	e.p=move_enemy_body(e,delta.normalized()*minf(delta.length(),(650.0 if e.motion_kind == "charge" else 390.0)*ease*dt),BOSS_RADIUS)
	e.moving=e.p.distance_to(previous)>0.01; e.step+=dt*8.0
	if e.motion_kind == "charge":
		for actor in actors:
			if actor.active and not actor.dead and Geometry2D.get_closest_point_to_segment(actor.p,previous,e.p).distance_to(actor.p)<85 and line_of_fire(e.p,actor.p): damage_actor(actor,28,"boss","charge",delta.normalized()*680)
	if e.motion_t <= 0 or delta.length()<12:
		e.motion="idle";e.motion_cd=2.4;e.cd=maxf(e.cd,0.4)
	return true

# 0.18: ciclo comum. Chefes conservam seus próprios estados e padrões.
func attack_slots(target_id: int) -> int:
	return enemies.filter(func(e): return e.hp > 0 and e.get("target_id", -1) == target_id and e.get("combat", "") in ["warning", "attack"]).size()

func tactical_move(e: Dictionary, target: Dictionary, dt: float) -> void:
	var delta: Vector2 = target.p - e.p
	var direction := delta.normalized()
	var distance := delta.length()
	var speed: float = {"guard": 60.0, "bomber": 220.0, "crawler": 150.0, "crawler_small": 190.0, "fish": 110.0, "brute": 85.0, "lobo": 250.0, "sentinela": 240.0, "golem": 150.0}.get(e.kind, 110.0)
	var preferred: float = {"bomber": 30.0, "crawler": 160.0, "crawler_small": 35.0, "guard": 180.0, "fish": 310.0, "brute": 290.0, "lobo": 80.0, "sentinela": 320.0, "golem": 340.0}.get(e.kind, 260.0)
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
	e.p = move_enemy_body(e, movement * speed * dt, 14)
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

func enemy_muzzle_position(e: Dictionary) -> Vector2:
	var offsets: Array = ENEMY_MUZZLE_OFFSETS.get(e.kind, [])
	if offsets.is_empty(): return e.p
	var face: Vector2 = e.get("face", Vector2.DOWN)
	var row := posmod(roundi((PI * 0.5 - face.angle()) / (PI * 0.25)), 8)
	return e.p + offsets[row]

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
			e.combat = "attack"; e.combat_t = GUARD_ATTACK_TIME if e.kind in ["guard", "sentinela", "golem"] else (0.6 if e.kind in ["crawler", "crawler_small", "brute", "lobo"] else 0.45)
			if e.kind in ["crawler", "crawler_small", "lobo"]: emit_audio("enemy_crawler", e.p)
			e["burst"] = 0; e["burst_t"] = 0.0; e["launch"] = e.p
		return
	if e.combat == "attack":
		var direction: Vector2 = ((target.p if e.kind in ["guard", "sentinela", "golem"] else e.locked) - e.p).normalized()
		e.face = direction
		var muzzle := enemy_muzzle_position(e)
		var shot_direction: Vector2 = ((target.p if e.kind in ["guard", "sentinela", "golem"] else e.locked) - muzzle).normalized()
		if shot_direction.length_squared() < 0.01: shot_direction = direction
		match e.kind:
			"guard":
				# 0.20: rajada cadenciada; durante toda a ofensiva a guarda fica aberta.
				e.burst_t -= dt
				if e.burst_t <= 0 and e.burst < GUARD_SHOTS:
					e.shot = 0.22
					emit_audio("enemy_guard", e.p)
					add_bullet(muzzle, shot_direction, 1, 14 * e.damage_scale, 280, 7, -1, "magenta")
					bullets[-1]["height"] = 0.0
					e.burst += 1; e.burst_t = GUARD_SHOT_INTERVAL
			"brute":
				e.burst_t -= dt
				if e.burst_t <= 0 and e.burst < 6:
					e.shot = 0.22
					emit_audio("enemy_brute", e.p)
					add_bullet(muzzle, shot_direction.rotated((e.burst - 2.5) * 0.13), 1, 12 * e.damage_scale, 260, 6, -1, "violet")
					bullets[-1]["height"] = 0.0
					bullets[-1]["source"] = e.kind; bullets[-1]["accel"] = 90.0; e.burst += 1; e.burst_t = 0.1
			"sentinela":
				# Rajada pesada de 5 tiros mirados — máquina de guerra, não mob comum.
				e.burst_t -= dt
				if e.burst_t <= 0 and e.burst < 5:
					e.shot = 0.22
					emit_audio("enemy_guard", e.p)
					add_bullet(muzzle, shot_direction.rotated((e.burst - 2) * 0.09), 1, 16 * e.damage_scale, 340, 7, -1, "magenta")
					bullets[-1]["height"] = 0.0
					e.burst += 1; e.burst_t = 0.14
			"golem":
				# Canhão rotativo: rajada lenta de projéteis pesados e grandes.
				e.burst_t -= dt
				if e.burst_t <= 0 and e.burst < 4:
					e.shot = 0.26
					emit_audio("enemy_guard", e.p)
					add_bullet(muzzle, shot_direction.rotated((e.burst - 1.5) * 0.08), 1, 22 * e.damage_scale, 380, 9, -1, "magenta")
					bullets[-1]["height"] = 0.0
					bullets[-1]["source"] = e.kind
					e.burst += 1; e.burst_t = 0.24
			"crawler", "crawler_small", "lobo":
				var max_distance := 340.0 if e.kind == "lobo" else (220.0 if e.kind == "crawler" else 110.0)
				var goal: Vector2 = e.launch + (e.locked - e.launch).limit_length(max_distance)
				if e.shot <= 0 and e.combat_t > 0.45: e.shot = 0.22
				e["jump_height"] = sin(clampf(1 - e.combat_t / 0.6, 0, 1) * PI) * (90.0 if e.kind == "lobo" else 65.0)
				var before_jump: Vector2 = e.p
				e.p = move_enemy_body(e, (goal - e.p).limit_length((460.0 if e.kind == "lobo" else 400.0) * dt), 14)
				if mode == "run" and room_at(e.p).get("kind", "") in ["entry", "maze", "story", "shop"] and room_at(e.p).get("id", "") != e.get("room", ""):
					e.p = before_jump
				e.moving = true
				if e.combat_t <= 0:
					e.jump_height = 0
					add_combat_zone(e.p, 70 if e.kind == "lobo" else (58 if e.kind == "crawler" else 32), (18 if e.kind == "lobo" else 12) * e.damage_scale, "acid", 0.15, 2.5)
			"bomber":
				emit_audio("enemy_bomber", e.p)
				e.hp = 0; e.detonated = true
				combat_blast(e.p, BOMBER_BLAST.radius, BOMBER_BLAST.damage * e.damage_scale)
			_:
				if e.burst == 0:
					e.shot = 0.22
					emit_audio("enemy_fish" if e.kind == "fish" else "enemy_cult", e.p)
					e.burst = 1
					add_bullet(muzzle, shot_direction, 1, (22 if e.kind == "fish" else 12) * e.damage_scale, 560 if e.kind == "fish" else 230, 7, -1, "harpoon" if e.kind == "fish" else "magenta")
					bullets[-1]["height"] = 0.0
					bullets[-1]["source"] = e.kind
					if e.kind == "cult": bullets[-1]["split_at"] = 0.8; bullets[-1]["curve"] = 0.18
					if e.get("elite", "") == "trail": bullets[-1]["trail"] = true
					if e.kind == "fish": bullets[-1]["stake"] = true
					if e.kind == "guard":
						bullets[-1].merge({"arc": true, "from": e.p, "to": e.locked, "flight": 0.9}, true)
		if e.combat_t <= 0:
			e.combat = "recover"; e.combat_t = 0.9; e.target_id = -1
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
	if e.kind == "lobo" and e.p.distance_to(target.p) > 380: return
	e.combat = "warning"; e.combat_t = GUARD_WARNING if e.kind in ["guard", "sentinela", "golem"] else ATTACK_WARNING; e.target_id = target.id
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
			if zone.has("ray_owner"):
				RayEncounter.resolve_zone(self,zone); zone.life=0; continue
			combat_blast(zone.p, zone.r, zone.damage); zone.life = 0; continue
		if zone.life <= 0 or zone.cd > 0: continue
		zone.cd = 0.4
		for a in actors:
			if a.active and not a.dead and a.p.distance_to(zone.p) < zone.r * 0.8 and line_of_fire(zone.p, a.p): damage_actor(a, zone.damage, "hazard", str(zone.kind))
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
