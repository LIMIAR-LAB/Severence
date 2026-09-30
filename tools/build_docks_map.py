"""Gera scripts/docks_map.gd — mapa FIXO e grande das Docas de 1941 (versão 0.13).

O mapa não é gerado no jogo: este script só ajuda a montar e VALIDAR o layout feito à mão
(salas, corredores, props, perigos, ondas). Rode sempre que mexer no layout:

    python tools/build_docks_map.py

Validações: corredores encostam nas salas (viram portões), nenhum prop fica em cima de porta,
toda sala é alcançável a pé a partir do desembarque (raio do Marty) e a rota principal passa com o Titan.
"""
from pathlib import Path
from collections import deque

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "scripts/docks_map.gd"

# ─────────────────────────────────────────────────────────────── salas
# id, nome, tipo, piso, rect (x, y, w, h)
# id, nome, tipo, piso, rect principal, [retos extras] — alas/alcovas grudadas na sala (0.17)
ROOMS = [
    ("entry", "01 • DESEMBARQUE", "entry", "planks", (600, 6000, 1600, 1000), []),
    ("cranes", "02 • PÁTIO DOS GUINDASTES", "fight", "stone", (2500, 5800, 1900, 1300), []),
    ("warehouse", "03 • ARMAZÉM 7", "chest", "planks", (4700, 5900, 1600, 1100), []),
    ("market", "04 • MERCADO DE PEIXE", "fight", "cobble", (6600, 5900, 1500, 1100), []),
    ("shop", "05 • OFICINA", "shop", "cobble", (8400, 6000, 1100, 900), []),
    ("generator", "06 • O ÚLTIMO GERADOR", "side", "stone", (8300, 3900, 1300, 1100), []),
    ("ammo", "07 • DEPÓSITO DE MUNIÇÃO", "fight", "stone", (6200, 3700, 1700, 1300), []),
    ("rails", "08 • PÁTIO FERROVIÁRIO", "fight", "stone", (3900, 3700, 1900, 1300), []),
    ("stairs", "09 • BALCÃO DO FAROL", "stairs", "cobble", (1800, 3700, 1700, 1300), []),
    # Capela em T: duas relicarias abrem na parede de baixo, ladeando o corredor de entrada.
    ("chapel", "10 • CAPELA DO CULTO", "chest", "cobble", (200, 3600, 1300, 1400), [(300, 5000, 300, 340), (1200, 5000, 300, 340)]),
    # Doque Seco ganha uma doca menor em cima (atracação de serviço).
    ("drydock", "11 • DOQUE SECO", "fight", "stone", (200, 1200, 1500, 1500), [(1400, 900, 500, 300)]),
    # Adega em L: ala oeste alagada.
    ("cellar", "13 • ADEGA INUNDADA", "chest", "planks", (7600, 1200, 1500, 1100), [(7000, 1400, 600, 600)]),
    # Arena do Almirante: alcovas laterais no meio — a silhueta deixa de ser um retângulo.
    ("boss", "12 • O ALMIRANTE DAS PROFUNDEZAS", "boss", "stone", (3000, 400, 2400, 1800), [(2600, 700, 400, 500), (5400, 800, 300, 600)]),
    ("secret", "? • CONTRABANDO", "secret", "planks", (5900, 900, 900, 700), []),
]
R = {r[0]: r[4] for r in ROOMS}

# 0.18: ALAS — recortes extras ligados a uma sala (a sala vira composta de vários retângulos,
# em vez de só um Rect2; o desenho de piso/parede já trata cada retângulo do jeito certo por
# encostar num vizinho igual a um corredor). Preencha com content() como o resto da sala.
ROOM_EXTRA: dict = {}
def extra(room_id, x, y, w, h): ROOM_EXTRA.setdefault(room_id, []).append((x, y, w, h))

# Corredores sempre abertos (cada ponta que encosta numa sala vira um portão).
CORRIDORS = [
    (2200, 6400, 300, 200),   # 01 → 02 (o primeiro é o que sai do Desembarque)
    (900, 5000, 200, 1000),   # 01 ↑ 10 (laço pela Capela)
    (4400, 6300, 300, 200),   # 02 → 03
    (6300, 6300, 300, 200),   # 03 → 04
    (8100, 6300, 300, 200),   # 04 → 05
    (8850, 5000, 200, 1000),  # 05 ↑ 06
    (7000, 5000, 200, 900),   # 04 ↑ 07
    (7900, 4300, 400, 200),   # 07 → 06
    (5800, 4200, 400, 200),   # 08 → 07
    (4000, 5000, 200, 800),   # 02 ↑ 08
    (3500, 4200, 400, 200),   # 09 → 08
    (1500, 4200, 300, 200),   # 10 → 09
    (700, 2700, 200, 900),    # 10 ↑ 11
    (1700, 1500, 1300, 200),  # 11 → 12 (entrada lateral da arena)
    (3300, 2200, 200, 1500),  # 09 ↑ 12 (entrada principal da arena)
    (8800, 2300, 200, 1600),  # 06 ↑ 13
]
SECRET_CORRIDOR = (6450, 1600, 180, 2100)   # 07 ↑ ? (parede rachada no topo do Depósito)
EXTRA_FLOORS = []

# Balcão elevado no 09 com duas rampas laterais.
RAISED = [(2250, 4000, 800, 360)]
RAMPS = [((2050, 4000, 200, 360), "x", 2050.0, 2250.0), ((3050, 4000, 200, 360), "x", 3250.0, 3050.0)]
# Água que bloqueia a passagem (salte com Espaço se for estreita).
GAPS = [(5480, 5900, 80, 780), (7950, 1200, 80, 700), (650, 1650, 600, 520)]

POINTS = {
    "spawn": (820, 6480), "spawn2": (880, 6540), "key": (1450, 6560),
    "shop": (8950, 6170), "side": (8950, 4450), "secret_wall": (6540, 3740),
    "boss": (4200, 1200), "extraction": (4200, 720), "mech": (9250, 6700),
    "ammo_center": (7050, 4350), "warden": (4850, 4350),
}
CHESTS = [(6150, 6080, False), (850, 3800, False), (8850, 1400, False), (6350, 1150, True)]

# Estilo das bordas de cada sala: top facade|wall|none, bottom wall|quay|none, left/right wall|pier.
# wall_set (0.17): pele da fachada por ambiente — default = tijolo de armazém.
ROOM_STYLE = {
    "entry": {"top": "facade", "bottom": "quay", "left": "pier", "quay_band": 180},
    "cranes": {"top": "facade", "bottom": "quay", "quay_band": 150},
    "warehouse": {"top": "facade", "bottom": "wall"},
    "market": {"top": "facade", "bottom": "quay", "quay_band": 140, "floor_set": "market"},
    "shop": {"top": "facade", "bottom": "quay", "right": "pier", "quay_band": 130, "floor_set": "workshop"},
    "generator": {"top": "facade", "bottom": "wall", "wall_set": "rail"},
    "ammo": {"top": "facade", "bottom": "wall", "wall_set": "rail", "floor_set": "depot"},
    "rails": {"top": "facade", "bottom": "wall", "wall_set": "rail"},
    "stairs": {"top": "facade", "bottom": "wall", "wall_set": "rail", "floor_set": "lighthouse"},
    "chapel": {"top": "facade", "bottom": "wall", "left": "pier", "wall_set": "cult", "floor_set": "chapel", "floor_patch": (640, 3700, 420, 1300)},
    "drydock": {"top": "facade", "bottom": "wall", "left": "pier", "wall_set": "rail", "floor_set": "drydock"},
    "cellar": {"top": "facade", "bottom": "wall", "right": "pier", "wall_set": "abyssal", "floor_set": "cellar"},
    "boss": {"top": "facade", "bottom": "wall", "wall_set": "abyssal", "floor_set": "boss"},
    "secret": {"top": "facade", "bottom": "wall", "wall_set": "abyssal"},
}
# Mar visível (aparece junto com a sala dona).
WATER = [
    ("entry", (-400, 5600, 1000, 2000)), ("entry", (600, 7000, 1900, 600)),
    ("cranes", (2500, 7100, 1900, 500)), ("market", (6600, 7000, 1500, 600)),
    ("shop", (8400, 6900, 1100, 700)), ("shop", (9500, 5800, 900, 1800)),
    ("chapel", (-500, 3400, 700, 1800)), ("drydock", (-500, 1000, 700, 1900)),
    ("cellar", (9100, 1000, 900, 1500)),
]

# 0.16: ATALHOS — corredor fechado por uma fachada rachada. Explosão (barril, bomba, canhão) perto da
# parede troca o sprite pela versão _open e libera a passagem. Sem portões (não entram em CORRIDORS).
# r = piso do corredor; wall = colisão da parede (na borda da sala); room = sala do lado da parede.
SHORTCUTS = [
    {"r": (2740, 5000, 128, 800), "wall": (2740, 5776, 128, 36), "room": "cranes"},      # 02 Guindastes ↑ 09 Farol
    {"r": (5100, 5000, 128, 900), "wall": (5100, 5876, 128, 36), "room": "warehouse"},   # 03 Armazém ↑ 08 Ferroviário
]
# 0.18: alas — pequenas reentrâncias que tiram as salas do quadrado, encostadas numa borda livre.
extra("cranes", 4400, 5800, 300, 300)      # 02 Guindastes: baia à direita
extra("rails", 5800, 3700, 300, 320)       # 08 Ferroviário: baia à direita
extra("market", 6320, 5900, 280, 260)      # 04 Mercado: reentrância à esquerda
extra("warehouse", 4700, 7000, 320, 300)   # 03 Armazém: baia embaixo
# 0.19: "entry" agora é a composição pintada do Desembarque (arrival_art.gd) — não usa ala/props
# procedurais. Revertido para não conflitar com os pisos mapeados na imagem (docs/DESEMBARQUE_ARTISTICO_0_19.md).

# 0.16: PORTÕES DE TENTÁCULO — poça que bloqueia um corredor e fere quem encosta (active) até o evento
# ligado a ela acontecer; aí vira grade selada (sealed), segura e atravessável.
# event: warden (mini-chefe do Pátio Ferroviário morto) | side (desafio do Último Gerador concluído)
TENTACLE_GATES = [
    {"p": (6000, 4300), "block": (5860, 4200, 280, 200), "event": "warden", "damage": 12},   # 08 → 07
    {"p": (8100, 4400), "block": (7960, 4300, 280, 200), "event": "side", "damage": 12},     # 07 → 06
]

# ─────────────────────────────────────────────────────────────── conteúdo
OB = []      # obstáculos [x, y, w, h, kind]
DEC = []     # decoração [x, y, kind] (+ extras)
HAZ = []     # perigos
SPAWNS = []  # [x, y, grupo]

FOOT = {  # caixa de colisão por prop (largura, altura) — pés do sprite
    "crate": (56, 40), "crate_2": (56, 40), "crate_3": (52, 40), "crate_net": (64, 42), "crate_barnacles": (66, 44),
    "crate_broken": (64, 40), "barrel": (44, 30), "barrel_oil": (42, 30), "barrel_toxic": (42, 30),
    "barrel_explosive": (42, 30), "barrel_tipped": (70, 30), "sandbags": (110, 40), "sandbags_corner": (112, 40),
    "sandbags_damaged": (104, 40), "bollard": (36, 28), "bollard_rope": (36, 28), "fish_basket": (56, 36),
    "lobster_trap": (84, 40), "wheelbarrow": (86, 38), "bench": (112, 30), "lamp_post": (22, 18),
    "brazier": (36, 26), "container": (140, 70), "container_red": (140, 70), "container_olive": (140, 70),
    "container_open": (150, 72), "container_open_red": (150, 72), "container_open_olive": (150, 72),
    "crane": (96, 60), "phone_booth": (70, 40), "radio": (70, 40), "jerrycans": (84, 34), "medkit": (72, 36),
    "pillar": (90, 90), "generator": (110, 90), "altar": (200, 90), "pew": (180, 44), "ammo": (70, 50),
    # 0.16: microbiomas (Oficina, Mercado, Capela)
    "workshop_bench": (88, 26), "workshop_tool_rack": (56, 20), "workshop_welder": (58, 22), "workshop_parts": (60, 22),
    "market_stall": (120, 30), "market_net": (92, 14), "market_baskets": (60, 24), "market_ice_barrel": (44, 26),
    "market_rowboat": (90, 20), "chapel_stained_glass": (50, 20), "chapel_offering_bowl": (44, 20),
}

def ob(kind, x, y):
    """Prop com os pés em (x, y) (centro da base)."""
    w, h = FOOT[kind]
    OB.append([int(x - w / 2), int(y - h), w, h, kind])

def row(kind, x, y, n, dx):
    for i in range(n): ob(kind, x + i * dx, y)

def col(kind, x, y, n, dy):
    for i in range(n): ob(kind, x, y + i * dy)

def dec(kind, x, y, **extra):
    DEC.append([int(x), int(y), kind, extra] if extra else [int(x), int(y), kind])

def crate_pile(x, y, variant=0):
    kinds = [["crate_2", "crate", "crate_net"], ["crate", "crate_barnacles", "crate_3"], ["crate_net", "crate_2", "barrel"]][variant % 3]
    ob(kinds[0], x, y); ob(kinds[1], x + 60, y); ob(kinds[2], x + 22, y + 44)

def barrels(x, y, explosive=False):
    ob("barrel_explosive" if explosive else "barrel", x, y); ob("barrel_oil", x + 48, y + 6)
    ob("barrel_explosive" if explosive else "barrel_toxic", x + 18, y + 38)

def sandbag_wall(x, y, n, vertical=False):
    if vertical: col("sandbags", x, y, n, 40)
    else: row("sandbags", x, y, n, 112)

def facade_decor(room_id, items, lamps=True):
    x0, y0, w, h = R[room_id]
    top = y0
    taken = []
    for kind, fx in items:
        x = x0 + fx
        taken.append(x)
        if kind == "poster": dec("poster", x, top - 50)
        elif kind == "iron_door": dec("iron_door", x, top + 2)
        elif kind == "phone_booth_wall": dec("phone_booth", x, top + 6)
    if lamps:
        x = x0 + 150
        while x < x0 + w - 100:
            if all(abs(x - t) > 90 for t in taken): dec("wall_lamp", x, top - 80)
            x += 420

def spawns(group, pts):
    for p in pts: SPAWNS.append([p[0], p[1], group])

def hazard(x, y, r=62, dmg=12):
    HAZ.append({"p": (x, y), "r": r, "damage": dmg})
    dec("tentacle_pool", x, y)

# ── 01 Desembarque 0.19: composição pintada, colisão derivada do piso.
spawns("dock", [(1450, 6380), (1710, 6580), (1510, 6790)])

# ── 02 Pátio dos Guindastes ──
facade_decor("cranes", [("poster", 520), ("iron_door", 980), ("poster", 1480)])
for cx, cy in [(2850, 6150), (3950, 6150), (2850, 6800), (3950, 6800)]: ob("crane", cx, cy)
ob("container_red", 3180, 6000); ob("container_olive", 3340, 6000); ob("container_open_red", 3620, 6020)
ob("container", 3180, 6960); ob("container_open_olive", 3500, 6980)
sandbag_wall(2700, 6480, 2); sandbag_wall(3830, 6480, 2)
barrels(3330, 6400, True); barrels(3430, 6620, True)
crate_pile(2620, 5900, 1); crate_pile(4180, 6900, 2)
barrels(2960, 5930, True)   # 0.16: abrem o atalho da parede rachada (↑ Farol)
ob("lamp_post", 3080, 6460); ob("lamp_post", 3760, 6700); ob("brazier", 2620, 6700)
dec("rails", 3400, 6250); dec("rails", 3400, 6560)
dec("grate", 3000, 6620); dec("manhole", 3800, 6300); dec("symbol_2", 3400, 6780)
row("bollard", 2700, 7040, 6, 330)
spawns("mix", [(2750, 6300), (3100, 6200), (3650, 6250), (4150, 6300), (2750, 6900), (3300, 6850), (3750, 6600), (4150, 6700)])

ob("lamp_post", 4520, 5950); crate_pile(4550, 6000, 2)   # 0.18: baía extra (ROOM_EXTRA)
dec("rope", 4600, 6150)
# ── 03 Armazém 7 (canal com passarela embaixo) ──
facade_decor("warehouse", [("iron_door", 300), ("poster", 900), ("iron_door", 1350)])
for yy in (6060, 6260, 6460):
    crate_pile(4820, yy, (yy // 200) % 3)
row("crate", 5100, 6200, 3, 60); row("crate_2", 5100, 6560, 3, 60)
ob("jerrycans", 5320, 6760); ob("wheelbarrow", 5140, 6900)
crate_pile(5700, 6060, 2); barrels(5300, 5990, True)   # 0.16: atalho ↑ Ferroviário
row("crate_barnacles", 5650, 6420, 2, 72); barrels(5900, 6520)
ob("container_olive", 5950, 6960); ob("fish_basket", 6200, 6120); ob("lobster_trap", 6150, 6800)
ob("lamp_post", 5620, 6300); ob("brazier", 6000, 6250)
dec("tentacle_planks", 5300, 6380); dec("debris_barrel", 5850, 6800); dec("rope", 5000, 6800)
spawns("mix", [(5000, 6400), (5300, 6100), (5700, 6300), (6000, 6700), (5300, 6850), (6200, 6200)])

crate_pile(4750, 7080, 1); ob("jerrycans", 4900, 7220)   # 0.18: baía extra (ROOM_EXTRA)
ob("lamp_post", 4780, 7250)
# ── 04 Mercado de Peixe ──
facade_decor("market", [("poster", 350), ("phone_booth_wall", 800), ("iron_door", 1200)])
for i, yy in enumerate((6150, 6450)):
    row("bench", 6800, yy, 2, 180); row("fish_basket", 7300, yy, 3, 70)
ob("lobster_trap", 7750, 6150); ob("lobster_trap", 7850, 6450); ob("radio", 7950, 6150)
ob("brazier", 7150, 6650); ob("brazier", 7700, 6650); ob("lamp_post", 6720, 6700); ob("lamp_post", 7980, 6700)
barrels(6750, 6000, True); crate_pile(7880, 5930, 0)
row("bollard", 6720, 6960, 5, 330)
hazard(7420, 6700, 66)
dec("grate", 7000, 6330); dec("symbol_1", 7550, 6330); dec("anchor", 6700, 6400)
spawns("mix", [(6900, 6300), (7200, 6050), (7600, 6300), (7900, 6600), (7000, 6800), (7400, 6150), (7750, 6800)])
# 0.16: microbioma do mercado (tools/prepare_market.py)
ob("market_stall", 7150, 6160); ob("market_stall", 7580, 6460)
ob("market_ice_barrel", 7580, 6170); ob("market_ice_barrel", 7150, 6470)
ob("market_baskets", 7880, 6700); ob("market_net", 6900, 6760); ob("market_rowboat", 7200, 6930)
dec("market_lanterns", 6850, 5850); dec("market_lanterns", 7280, 5850)

ob("fish_basket", 6420, 5980); ob("barrel", 6480, 6100)   # 0.18: reentrância extra (ROOM_EXTRA)
dec("grate", 6400, 6120)
# ── 05 Oficina (comerciante) ──
facade_decor("shop", [("iron_door", 250), ("poster", 800)])
row("crate", 8790, 6240, 6, 60)          # balcão do comerciante
ob("medkit", 8540, 6150); ob("radio", 9380, 6150); ob("jerrycans", 9360, 6400)
ob("lamp_post", 8520, 6600); ob("lamp_post", 9400, 6600); crate_pile(8500, 6780, 1)
dec("manhole", 8950, 6600); dec("rope", 9100, 6800)
# 0.16: microbioma da oficina (tools/prepare_workshop.py)
ob("workshop_bench", 9300, 6070); ob("workshop_tool_rack", 8480, 6060); ob("workshop_tool_rack", 9440, 6060)
ob("workshop_welder", 9180, 6420); ob("workshop_parts", 8620, 6450); ob("workshop_parts", 9150, 6600)
dec("workshop_hoist", 9250, 6560)
for p in [(8850, 6480), (9060, 6720), (8600, 6300)]: dec("workshop_oil_puddle", *p)

# ── 06 O Último Gerador (desafio opcional) ──
facade_decor("generator", [("iron_door", 300), ("iron_door", 1000)])
ob("generator", 8950, 4350)
for cx, cy in [(8550, 4150), (9350, 4150), (8550, 4800), (9350, 4800)]: ob("pillar", cx, cy)
barrels(8420, 4450, True); barrels(9420, 4550, True)
ob("brazier", 8700, 4600); ob("brazier", 9200, 4600)
dec("symbol_0", 8950, 4650); dec("grate", 8650, 4350); dec("grate", 9250, 4350)

# ── 07 Depósito de Munição (muitos barris explosivos) ──
facade_decor("ammo", [("poster", 700), ("iron_door", 1200)])   # 340: parede rachada (sala secreta)
row("ammo", 6360, 3900, 3, 72); row("ammo", 7600, 3900, 3, 72)
sandbag_wall(6480, 4250, 2); sandbag_wall(7400, 4250, 2)
barrels(6900, 4050, True); barrels(7250, 4050, True); barrels(7050, 4550, True)
ob("container_red", 6420, 4800); ob("container", 7650, 4800); ob("container_open", 7050, 4870)
crate_pile(6300, 4520, 2); crate_pile(7700, 4520, 0)
ob("lamp_post", 6700, 4600); ob("lamp_post", 7450, 4600)
dec("manhole", 7050, 4300); dec("debris_sandbags", 6600, 4650)
spawns("heavy", [(6400, 4050), (6800, 3900), (7300, 3900), (7700, 4100), (6500, 4650), (7600, 4650), (7050, 4750), (6900, 4350), (7300, 4400)])

# ── 08 Pátio Ferroviário ──
facade_decor("rails", [("poster", 400), ("iron_door", 950), ("poster", 1500)])
dec("rails_diag", 3950, 3900, to=(5750, 4450)); dec("rails_diag", 3950, 4500, to=(5750, 4950))
ob("container_red", 4400, 4130); ob("container_olive", 4560, 4130); ob("container", 5200, 4400); ob("container_open_red", 5360, 4420)
ob("container_olive", 4600, 4700); ob("container_open", 4760, 4720)
crate_pile(4050, 3860, 1); crate_pile(5550, 3860, 2); crate_pile(5500, 4800, 0)
sandbag_wall(4100, 4450, 1); sandbag_wall(5000, 4000, 1); ob("sandbags_damaged", 5550, 4400)
barrels(4900, 4600, True); ob("wheelbarrow", 4250, 4900)
ob("lamp_post", 4300, 4300); ob("lamp_post", 5100, 4800); ob("brazier", 4850, 3950)
dec("grate", 4700, 4400); dec("symbol_2", 5300, 4700); dec("debris_crate", 4350, 4700)
spawns("mix", [(4100, 4100), (4500, 3900), (5000, 4250), (5600, 4150), (4400, 4550), (4900, 4850), (5500, 4650), (5250, 3900)])

crate_pile(5900, 3780, 0); ob("lamp_post", 6000, 3950)   # 0.18: baía extra (ROOM_EXTRA)
# ── 09 Balcão do Farol (rampas) ──
facade_decor("stairs", [("iron_door", 350), ("poster", 850), ("iron_door", 1350)])
for cx in (1950, 3350): ob("pillar", cx, 4700)
row("pillar", 2350, 4560, 2, 600)
sandbag_wall(2500, 4520, 3)
ob("brazier", 2300, 4050); ob("brazier", 3000, 4050)
crate_pile(1900, 3800, 0); crate_pile(3000, 3800, 1); barrels(2700, 4800)
ob("lamp_post", 2100, 4550); ob("lamp_post", 3200, 4550)
dec("symbol_1", 2650, 4200); dec("manhole", 2650, 4900)
spawns("mix", [(2400, 4100), (2700, 4150), (2900, 4100), (2000, 3900), (3300, 4300), (2100, 4850), (3200, 4900)])

# ── 10 Capela do Culto ──
facade_decor("chapel", [("iron_door", 650)], lamps=False)
ob("altar", 850, 3950)
# 0.21: colisões alinhadas aos oito bancos pintados da placa PixelLab.
# As caixas representam somente a base dos móveis; o corredor central e as
# conexões norte/leste/sul permanecem livres.
OB.extend([
    [322, 4000, 210, 44, "pew"], [545, 3998, 190, 44, "pew"],
    [545, 4055, 190, 42, "pew"], [545, 4110, 190, 42, "pew"],
    [966, 3998, 190, 44, "pew"], [966, 4055, 190, 42, "pew"],
    [966, 4110, 190, 42, "pew"], [1168, 4000, 210, 44, "pew"],
])
dec("ritual_circle", 850, 4150); dec("symbol_0", 450, 3850); dec("symbol_2", 1250, 3850)
for p in [(450, 3750), (1250, 3750), (400, 4850), (1300, 4850), (700, 3990), (1000, 3990)]: dec("chapel_candles", *p)
# 0.16: microbioma da capela (tools/prepare_chapel.py); tapete e altar continuam
ob("chapel_stained_glass", 400, 3700); ob("chapel_stained_glass", 1300, 3700)
ob("chapel_offering_bowl", 650, 4010); ob("chapel_offering_bowl", 1050, 4010)
dec("chapel_banner", 560, 3590); dec("chapel_banner", 1140, 3590)
dec("rug", 850, 4500); dec("tentacle_planks", 500, 4880)
ob("brazier", 650, 3780); ob("brazier", 1050, 3780)
hazard(1200, 4900, 58)
spawns("cult", [(450, 3950), (1250, 3950), (700, 4800), (1050, 4800), (850, 4350), (600, 4100)])

# ── 11 Doque Seco (fosso de água no meio) ──
facade_decor("drydock", [("poster", 350), ("iron_door", 900)])
dec("rowboat", 950, 1900)
ob("crane", 450, 1500); ob("crane", 1450, 2400)
crate_pile(1350, 1300, 2); crate_pile(300, 2450, 0)
barrels(1400, 1800, True); barrels(350, 2000, True)
row("bollard", 620, 2280, 4, 170)
ob("lamp_post", 560, 1400); ob("lamp_post", 1350, 2250)
hazard(450, 2250, 60); hazard(1450, 2050, 60)
dec("rope", 1100, 1400); dec("anchor", 300, 1350)
spawns("heavy", [(400, 1350), (1100, 1350), (1500, 1550), (400, 2500), (1100, 2450), (1550, 2550)])

# ── 13 Adega Inundada ──
facade_decor("cellar", [("iron_door", 400), ("iron_door", 1000)])
for yy in (1350, 1550, 1750):
    row("barrel_oil", 7700, yy, 3, 50)
crate_pile(8150, 1300, 1); row("crate_barnacles", 8200, 1700, 2, 72)
barrels(8500, 1950, True); ob("crate_broken", 8950, 2050); ob("fish_basket", 7700, 2100)
ob("brazier", 8400, 1600); ob("lamp_post", 9000, 1700)
hazard(8300, 2050, 60)
dec("tentacle_planks", 7750, 2000); dec("symbol_1", 8700, 1500); dec("debris_barrel", 8450, 1350)
spawns("dock", [(8100, 1500), (8600, 1400), (8900, 1600), (8300, 2150), (8800, 2150)])

# ── 12 Arena do Almirante ──
facade_decor("boss", [("iron_door", 1200)])
for cx, cy in [(3400, 800), (5000, 800), (3400, 1800), (5000, 1800)]: ob("pillar", cx, cy)
for p in [(3250, 600), (5150, 600), (3250, 2050), (5150, 2050), (3800, 1150), (4600, 1150)]: ob("brazier", *p)
dec("ritual_circle", 4200, 1250); dec("symbol_0", 3600, 1500); dec("symbol_1", 4800, 1500); dec("symbol_2", 4200, 1900)
barrels(3150, 1300, True); barrels(5200, 1300, True)
hazard(3350, 1300, 64); hazard(5050, 1300, 64)
for p in [(3200, 480), (5200, 480), (3150, 2150), (5250, 2150)]: dec("debris_crate" if p[1] < 1000 else "debris_barrel", *p)
dec("tentacle_planks", 3700, 2080); dec("tentacle_planks", 4750, 2080); dec("anchor", 3150, 1000); dec("anchor", 5250, 1000)
dec("grate", 3800, 1700); dec("grate", 4600, 1700); dec("manhole", 4200, 2000)
for x in (3600, 4800): ob("lamp_post", x, 1000)

# ── ? Contrabando ──
crate_pile(5980, 980, 0); crate_pile(6600, 980, 1); barrels(6000, 1400); ob("medkit", 6650, 1450)
dec("rope", 6200, 1450)

GROUPS = {"dock": ["crawler", "fish"], "mix": ["cult", "fish", "brute", "crawler"],
          "heavy": ["brute", "fish", "cult", "brute"], "cult": ["cult", "cult", "crawler"]}

# ─────────────────────────────────────────────────────────────── validação
def rect_has(r, x, y): return r[0] <= x < r[0] + r[2] and r[1] <= y < r[1] + r[3]
def grow(r, m): return (r[0] - m, r[1] - m, r[2] + 2 * m, r[3] + 2 * m)

def room_rects(room):
    return [room[4]] + list(room[5])

def check_corridors():
    rooms = [r for r in ROOMS if r[2] != "secret"]
    for c in CORRIDORS:
        ends = set()
        for room in rooms:
            for rr in room_rects(room):
                sx = c[0] < rr[0] + rr[2] and c[0] + c[2] > rr[0]
                sy = c[1] < rr[1] + rr[3] and c[1] + c[3] > rr[1]
                if (sx and (abs(c[1] + c[3] - rr[1]) < 3 or abs(c[1] - (rr[1] + rr[3])) < 3)) or \
                   (sy and (abs(c[0] + c[2] - rr[0]) < 3 or abs(c[0] - (rr[0] + rr[2])) < 3)): ends.add(room[0]); break
        assert len(ends) == 2, f"corredor {c} encosta em {len(ends)} salas (esperado 2)"

def walkable(x, y, rad, floors, blocks):
    for ox, oy in ((0, 0), (rad, 0), (-rad, 0), (0, rad), (0, -rad)):
        if not any(rect_has(f, x + ox, y + oy) for f in floors): return False
    return not any(rect_has(grow(b, rad), x, y) for b in blocks)

def flood(start, rad, floors, blocks, step=10):
    sx, sy = round(start[0] / step), round(start[1] / step)
    seen = {(sx, sy)}; q = deque([(sx, sy)])
    while q:
        cx, cy = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (cx + dx, cy + dy)
            if n in seen: continue
            if walkable(n[0] * step, n[1] * step, rad, floors, blocks): seen.add(n); q.append(n)
    return seen

def reach(seen, p, step=10, tol=30):
    return any(abs(c[0] * step - p[0]) < tol and abs(c[1] * step - p[1]) < tol for c in seen)

def validate():
    check_corridors()
    floors = [rr for r in ROOMS if r[2] != "secret" for rr in room_rects(r)] + CORRIDORS + EXTRA_FLOORS + [RAMPS[0][0], RAMPS[1][0]]
    obstacles = [tuple(o[:4]) for o in OB]
    # portas livres: nenhum obstáculo encosta na boca de um corredor
    bad = []
    for c in CORRIDORS:
        mouth = grow(c, 70)
        for o in OB:
            b = o[:4]
            if b[0] < mouth[0] + mouth[2] and b[0] + b[2] > mouth[0] and b[1] < mouth[1] + mouth[3] and b[1] + b[3] > mouth[1]:
                bad.append(f"obstáculo {o} bloqueia a boca do corredor {c}")
    if bad: raise SystemExit("\n".join(bad))
    # o balcão elevado é uma parede para quem vem de baixo
    raised_block = [(RAISED[0][0], RAISED[0][1] + RAISED[0][3] - 4, RAISED[0][2], 8)]
    gates = [g["block"] for g in TENTACLE_GATES]
    for sc in SHORTCUTS: assert any(rect_has(R[sc["room"]], sc["wall"][0] + 5, sc["wall"][1] + sc["wall"][3] - 5) for _ in [0]), f"atalho fora da sala {sc}"
    marty = flood(POINTS["spawn"], 11, floors, obstacles + list(GAPS) + raised_block + gates)
    for room in ROOMS:
        rid, kind = room[0], room[2]
        if kind == "secret": continue
        ok = all(any(rect_has(rr, c[0] * 10, c[1] * 10) for c in marty) for rr in room_rects(room))
        assert ok, f"sala {rid} não é alcançável a pé (incluindo alas extras)"
    for k in ("key", "shop", "side", "boss", "extraction", "mech"):
        assert reach(marty, POINTS[k], tol=60), f"ponto {k} não alcançável"
    for x, y, secret in CHESTS:
        if not secret: assert reach(marty, (x, y), tol=70), f"baú em {(x, y)} não alcançável"
    titan = flood(POINTS["mech"], 23, floors, obstacles + list(GAPS) + raised_block + gates, step=12)
    for k in ("spawn", "boss"):
        assert reach(titan, POINTS[k], step=12, tol=80), f"Titan não chega em {k}"
    def nudge(s):
        # inimigo em cima de prop: procura o ponto livre mais próximo (até 120 px)
        blocks = obstacles + list(GAPS)
        if walkable(s[0], s[1], 14, floors, blocks): return
        for r in range(10, 130, 10):
            for dx, dy in ((r, 0), (-r, 0), (0, r), (0, -r), (r, r), (-r, r), (r, -r), (-r, -r)):
                if walkable(s[0] + dx, s[1] + dy, 14, floors, blocks):
                    s[0] += dx; s[1] += dy; return
        raise SystemExit(f"spawn preso {s}")
    for s in SPAWNS: nudge(s)
    for x, y, secret in CHESTS:
        assert walkable(x, y + 40, 11, floors + [SECRET_CORRIDOR, R["secret"]], obstacles), f"baú sem acesso {(x, y)}"
    print(f"validado: {len(ROOMS)} salas, {len(CORRIDORS)} corredores, {len(OB)} obstáculos, {len(DEC)} decorações, "
          f"{len(SPAWNS)} inimigos, {len(HAZ)} perigos")

# ─────────────────────────────────────────────────────────────── saída
# 0.17: salas sem combate e paredes internas preservadas pelo gerador.
def inside_room(p, room):
    x,y,w,h=R[room]
    return x <= p[0] <= x+w and y <= p[1] <= y+h
ROOMS = [(i,n,("maze" if i=="warehouse" else "story" if i=="chapel" else k),f,r,ex) for i,n,k,f,r,ex in ROOMS]
OB[:] = [o for o in OB if not inside_room(o,"warehouse")]
GAPS[:] = [g for g in GAPS if not inside_room(g,"warehouse")]
SPAWNS[:] = [p for p in SPAWNS if not any(inside_room(p,r) for r in ["warehouse","chapel"])]
HAZ[:] = [h for h in HAZ if not any(inside_room(h["p"],r) for r in ["warehouse","chapel"])]
OB.extend([(5100,6000,90,650,"maze_wall"),(5680,6370,90,530,"maze_wall")])
# 0.17 (Tarefa C): colunas interiores do Depósito — quebram o retângulo vazio.
OB.extend([(6680,4280,90,470,"maze_wall"),(7420,3900,90,430,"maze_wall")])
for pos,kind,phase in [((5300,6800),"spikes",0),((5470,6150),"darts",0.8),((6000,6510),"steam",1.6)]:
    HAZ.append({"p":pos,"r":75,"damage":12,"trap":kind,"offset":phase})
CHESTS[:] = [c for c in CHESTS if not inside_room(c,"warehouse")]
CHESTS.append((6100,6100,False))
DEC[:] = [d for d in DEC if not (d[2] == "tentacle_pool" and any(inside_room(d,r) for r in ["warehouse","chapel"]))]

# 0.18: esquadrões fixos por sala, sem sorteio de classes.
SQUADS = {
    "entry": ["crawler", "fish", "cult"],
    "rails": ["guard", "brute", "bomber", "cult"],
    "market": ["fish", "crawler", "guard", "bomber"],
    "cellar": ["crawler", "cult", "bomber"],
    "ammo": ["brute", "guard", "fish", "bomber"],
}
counts = {}
for point in SPAWNS:
    room = next((rid for rid in R if inside_room(point, rid)), "dock")
    squad = SQUADS.get(room, ["cult", "guard", "crawler", "fish", "bomber", "brute"])
    index = counts.get(room, 0); counts[room] = index + 1
    point[2] = squad[index % len(squad)]
# Integração 0.18: preservar alas adicionadas na main e nas salas especiais.
ROOMS = [(i,n,k,f,r,list(dict.fromkeys(list(ex) + ROOM_EXTRA.get(i, [])))) for i,n,k,f,r,ex in ROOMS]
ROOM_EXTRA = {i: ex for i,n,k,f,r,ex in ROOMS if ex}

# 0.19: somente superfícies de pedra da arte são caminháveis. Água/navio não são piso.
ENTRY_ART_BOUNDS = (187, 6000, 2013, 1280)
ENTRY_RECTS = [(600,6380,1240,540), (600,6260,1050,120), (900,6000,200,260), (1840,6400,360,230), (1600,6920,160,65)]
ROOMS = [(i,n,k,("stone" if i=="entry" else f),(ENTRY_RECTS[0] if i=="entry" else r),(ENTRY_RECTS[1:] if i=="entry" else ex)) for i,n,k,f,r,ex in ROOMS]
R["entry"] = ENTRY_RECTS[0]
ROOM_EXTRA["entry"] = ENTRY_RECTS[1:]
ROOM_STYLE["entry"] = {"painted": True, "top":"none", "bottom":"none", "left":"none", "right":"none"}
POINTS["spawn"] = (850,6550)
POINTS["spawn2"] = (920,6590)

def v2(p): return f"Vector2({p[0]}, {p[1]})"
def r2(r): return f"Rect2({r[0]}, {r[1]}, {r[2]}, {r[3]})"
def val(x):
    if isinstance(x, bool): return "true" if x else "false"
    if isinstance(x, (int, float)): return str(x)
    if isinstance(x, str): return '"' + x + '"'
    if isinstance(x, tuple) and len(x) == 2: return v2(x)
    if isinstance(x, tuple) and len(x) == 4: return r2(x)
    if isinstance(x, dict): return "{" + ", ".join(f'"{k}": {val(v)}' for k, v in x.items()) + "}"
    if isinstance(x, list): return "[" + ", ".join(val(i) for i in x) + "]"
    raise TypeError(x)

def chunks(items, n=6):
    for i in range(0, len(items), n): yield items[i:i + n]

def emit():
    L = ["extends RefCounted", "",
         "# Mapa FIXO das Docas de 1941 — 0.13. GERADO por tools/build_docks_map.py (edite lá e rode o script).",
         "# 13 salas + sala secreta, com laços estilo Enter the Gungeon. Esquadrões fixos; a seed varia posições e elites.",
         "# Obstáculos: [x, y, w, h, tipo] (caixa = pés do prop). Decoração: [x, y, tipo, extras?].", ""]
    L.append("const ENTRY_ART_BOUNDS := " + r2(ENTRY_ART_BOUNDS))
    L.append("const ENTRY_RECTS := " + val(ENTRY_RECTS))
    L.append("const ROOMS := [")
    def room_dict(i, n, k, f, r, ex):
        d = f'{{"id": "{i}", "name": "{n}", "kind": "{k}", "floor": "{f}", "r": {r2(r)}'
        return d + (f', "extra": {val(list(ex))}}}' if ex else "}")
    L.append(",\n".join(room_dict(*rm) for rm in ROOMS) + "]")
    L.append(""); L.append("const EXTRA_FLOORS := [" + ", ".join(r2(r) for r in EXTRA_FLOORS) + "]")
    L.append("const ROOM_EXTRA := {" + ", ".join(f'"{k}": [' + ", ".join(r2(e) for e in v) + "]" for k, v in ROOM_EXTRA.items()) + "}")
    L.append("const CORRIDORS := [\n\t" + ",\n\t".join(", ".join(r2(c) for c in ch) for ch in chunks(CORRIDORS, 4)) + "]")
    L.append(f"const SECRET_CORRIDOR := {r2(SECRET_CORRIDOR)}")
    L.append("const RAISED := [" + ", ".join(r2(r) for r in RAISED) + "]")
    L.append("const RAMPS := [\n\t" + ",\n\t".join(f'{{"r": {r2(r)}, "axis": "{a}", "low": {lo}, "high": {hi}}}' for r, a, lo, hi in RAMPS) + "]")
    L.append("const GAPS := [" + ", ".join(r2(r) for r in GAPS) + "]")
    L.append("")
    L.append("const POINTS := {\n\t" + ",\n\t".join(", ".join(f'"{k}": {v2(v)}' for k, v in ch) for ch in chunks(list(POINTS.items()), 4)) + "}")
    L.append("const CHESTS := [" + ", ".join(f"[{x}, {y}, {val(s)}]" for x, y, s in CHESTS) + "]")
    L.append("")
    L.append("# Bordas: top facade|wall|none • bottom wall|quay|none • left/right wall|pier • quay_band = faixa de granito")
    L.append("const ROOM_STYLE := {\n\t" + ",\n\t".join(f'"{k}": {val(v)}' for k, v in ROOM_STYLE.items()) + "}")
    L.append("const WATER := [\n\t" + ",\n\t".join(f'{{"room": "{rid}", "r": {r2(r)}}}' for rid, r in WATER) + "]")
    L.append("# Perigos: poça com tentáculo (pisar = meio coração e empurrão; saltar escapa).")
    L.append("const HAZARDS := [\n\t" + ",\n\t".join(val(h) for h in HAZ) + "]")
    L.append("# 0.16: atalhos (parede rachada que a explosão abre) e portões de tentáculo (selam num evento).")
    L.append("const SHORTCUTS := [\n\t" + ",\n\t".join(f'{{"r": {r2(c["r"])}, "wall": {r2(c["wall"])}, "room": "{c["room"]}"}}' for c in SHORTCUTS) + "]")
    L.append("const TENTACLE_GATES := [\n\t" + ",\n\t".join(f'{{"p": {v2(g["p"])}, "block": {r2(g["block"])}, "event": "{g["event"]}", "damage": {g["damage"]}.0}}' for g in TENTACLE_GATES) + "]")
    L.append("")
    L.append("const OBSTACLES := [")
    L.append(",\n".join("\t" + ", ".join(f'[{o[0]}, {o[1]}, {o[2]}, {o[3]}, "{o[4]}"]' for o in ch) for ch in chunks(OB, 4)) + "]")
    L.append("")
    def d(x):
        base = f'[{x[0]}, {x[1]}, "{x[2]}"'
        return base + (", " + val(x[3]) + "]" if len(x) > 3 else "]")
    L.append("const DECOR := [")
    L.append(",\n".join("\t" + ", ".join(d(x) for x in ch) for ch in chunks(DEC, 5)) + "]")
    L.append("")
    L.append("# Inimigos posicionados à mão: [x, y, grupo]. O grupo define os tipos sorteados pela seed.")
    L.append("const SPAWNS := [")
    L.append(",\n".join("\t" + ", ".join(f'[{s[0]}, {s[1]}, "{s[2]}"]' for s in ch) for ch in chunks(SPAWNS, 6)) + "]")
    L.append("const GROUPS := " + "{" + ", ".join(f'"{k}": [' + ", ".join(f'"{t}"' for t in v) + "]" for k, v in GROUPS.items()) + "}")
    OUT.write_text("\n".join(L) + "\n", encoding="utf-8")
    print("escrito", OUT)

if __name__ == "__main__":
    validate()
    emit()
