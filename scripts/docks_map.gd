extends RefCounted

# Mapa FIXO das Docas de 1941 (não é gerado): 9 salas grandes + sala secreta, ligadas por corredores,
# com laços como no Enter the Gungeon (Depósito ↔ Gerador). A seed só varia os tipos de inimigo.
# Coordenadas em pixels de mundo. Obstáculos: [x, y, w, h, tipo]; decoração: [x, y, tipo].

const ROOMS := [
	{"id": "entry", "name": "01 • DESEMBARQUE", "kind": "entry", "floor": "planks", "r": Rect2(400, 4300, 1200, 800)},
	{"id": "cranes", "name": "02 • PÁTIO DOS GUINDASTES", "kind": "fight", "floor": "stone", "r": Rect2(1900, 4100, 1600, 1100)},
	{"id": "warehouse", "name": "03 • ARMAZÉM 7", "kind": "chest", "floor": "planks", "r": Rect2(3800, 4200, 1300, 900)},
	{"id": "shop", "name": "04 • OFICINA", "kind": "shop", "floor": "cobble", "r": Rect2(5400, 4250, 1000, 800)},
	{"id": "generator", "name": "05 • O ÚLTIMO GERADOR", "kind": "side", "floor": "stone", "r": Rect2(5350, 2800, 1100, 900)},
	{"id": "ammo", "name": "06 • DEPÓSITO DE MUNIÇÃO", "kind": "fight", "floor": "stone", "r": Rect2(3500, 2600, 1500, 1200)},
	{"id": "stairs", "name": "07 • BALCÃO DO FAROL", "kind": "stairs", "floor": "cobble", "r": Rect2(1900, 2500, 1400, 1100)},
	{"id": "chapel", "name": "08 • CAPELA DO CULTO", "kind": "chest", "floor": "cobble", "r": Rect2(400, 2700, 1100, 1100)},
	{"id": "boss", "name": "09 • O ALMIRANTE DAS PROFUNDEZAS", "kind": "boss", "floor": "stone", "r": Rect2(1600, 400, 2000, 1500)},
	{"id": "secret", "name": "? • CONTRABANDO", "kind": "secret", "floor": "planks", "r": Rect2(3950, 900, 650, 600)}]

# Pisos extras (alas da arena do chefe) e corredores sempre abertos.
const EXTRA_FLOORS := [Rect2(1400, 600, 200, 1100), Rect2(3600, 600, 200, 1100)]
const CORRIDORS := [
	Rect2(1600, 4600, 300, 180), Rect2(3500, 4550, 300, 180), Rect2(5100, 4550, 300, 180),
	Rect2(5800, 3700, 200, 550), Rect2(4250, 3800, 200, 400), Rect2(5000, 3050, 350, 180),
	Rect2(3300, 3050, 200, 180), Rect2(1500, 3150, 400, 180), Rect2(2500, 1900, 200, 600)]
const SECRET_CORRIDOR := Rect2(4180, 1500, 180, 1100)

# Balcão elevado no 07 com duas rampas laterais (a altura sobe no eixo x).
const RAISED := [Rect2(2250, 2800, 700, 320)]
const RAMPS := [
	{"r": Rect2(2050, 2800, 200, 320), "axis": "x", "low": 2050.0, "high": 2250.0},
	{"r": Rect2(2950, 2800, 200, 320), "axis": "x", "low": 3150.0, "high": 2950.0}]
# Canal de água no Armazém 7: salte (Espaço) ou dê a volta pela passarela de baixo.
const GAPS := [Rect2(4600, 4200, 70, 700)]

const POINTS := {
	"warden": Vector2(1350, 4620),
	"spawn": Vector2(700, 4750), "spawn2": Vector2(760, 4800), "key": Vector2(1150, 4650),
	"shop": Vector2(5900, 4420), "side": Vector2(5900, 3290), "secret_wall": Vector2(4270, 2640),
	"boss": Vector2(2600, 1000), "extraction": Vector2(2600, 600), "mech": Vector2(6150, 4880),
	"ammo_center": Vector2(4250, 3200)}

const CHESTS := [[4950, 4380, false], [950, 2860, false], [4275, 1150, true]]

const OBSTACLES := [
	# 01 Desembarque: cabeços na borda do cais, caixas e um contêiner
	[520, 5030, 30, 30, "bollard"], [820, 5030, 30, 30, "bollard"], [1120, 5030, 30, 30, "bollard"], [1420, 5030, 30, 30, "bollard"],
	[440, 4340, 56, 56, "crate"], [500, 4340, 56, 56, "crate"], [440, 4400, 56, 56, "crate"],
	[1230, 4330, 230, 100, "container_blue"], [1000, 4880, 60, 40, "fishbox"],
	# 02 Pátio dos guindastes: 4 bases de guindaste, 2 contêineres e sacos de areia
	[2250, 4380, 90, 90, "pillar"], [3060, 4380, 90, 90, "pillar"], [2250, 4860, 90, 90, "pillar"], [3060, 4860, 90, 90, "pillar"],
	[2580, 4190, 230, 100, "container_red"], [2580, 4980, 230, 100, "container_olive"],
	[2060, 4640, 130, 44, "sandbags"], [3220, 4640, 130, 44, "sandbags"], [2660, 4640, 70, 50, "ammo"],
	# 03 Armazém 7: pilhas de caixas formando corredores
	[3900, 4300, 56, 56, "crate"], [3956, 4300, 56, 56, "crate"], [3900, 4356, 56, 56, "crate"],
	[4100, 4560, 56, 56, "crate"], [4156, 4560, 56, 56, "crate"], [4400, 4300, 56, 56, "barrel"],
	[4760, 4560, 56, 56, "crate"], [4816, 4560, 56, 56, "crate"], [4816, 4616, 56, 56, "crate"],
	[4950, 4800, 56, 56, "barrel"], [3950, 4900, 230, 100, "container_olive"],
	# 04 Oficina: balcão do comerciante e bancadas
	[5780, 4340, 240, 44, "crate_row"], [5450, 4300, 70, 50, "ammo"], [6300, 4300, 56, 56, "barrel"],
	# 05 Gerador
	[5850, 3150, 110, 90, "generator"], [5500, 2900, 90, 90, "pillar"], [6250, 2900, 90, 90, "pillar"],
	[5500, 3500, 90, 90, "pillar"], [6250, 3500, 90, 90, "pillar"],
	# 06 Depósito de munição: fileiras de munição e barris
	[3650, 2800, 70, 50, "ammo"], [3720, 2800, 70, 50, "ammo"], [4650, 2800, 70, 50, "ammo"], [4720, 2800, 70, 50, "ammo"],
	[3700, 3150, 130, 44, "sandbags"], [4650, 3150, 130, 44, "sandbags"], [4180, 3000, 56, 56, "barrel"], [4290, 3000, 56, 56, "barrel"],
	[3650, 3500, 230, 100, "container_red"], [4550, 3500, 230, 100, "container_blue"], [4180, 3420, 56, 56, "barrel"],
	# 07 Balcão do farol: pilares embaixo do balcão
	[2000, 3300, 90, 90, "pillar"], [3100, 3300, 90, 90, "pillar"], [2560, 3380, 130, 44, "sandbags"],
	# 08 Capela: altar e bancos
	[850, 3050, 200, 90, "altar"], [550, 3300, 180, 44, "pew"], [1170, 3300, 180, 44, "pew"], [550, 3480, 180, 44, "pew"], [1170, 3480, 180, 44, "pew"],
	# 09 Arena do Almirante: 4 colunas de cobertura
	[1900, 700, 100, 100, "pillar"], [3200, 700, 100, 100, "pillar"], [1900, 1500, 100, 100, "pillar"], [3200, 1500, 100, 100, "pillar"],
	# ? Contrabando
	[4000, 950, 56, 56, "crate"], [4500, 950, 56, 56, "crate"], [4000, 1380, 56, 56, "barrel"]]

const DECOR := [
	[600, 4500, "rope"], [900, 4600, "puddle"], [1400, 4900, "anchor"], [700, 4380, "net"],
	[2400, 4630, "rails"], [2900, 4630, "rails"], [2100, 4300, "puddle"], [3200, 5050, "puddle"],
	[4300, 4800, "oil"], [4050, 4700, "puddle"], [5600, 4700, "oil"], [6100, 4500, "puddle"],
	[5700, 3000, "oil"], [3900, 3300, "puddle"], [4500, 2950, "oil"], [2300, 3450, "puddle"],
	[700, 3000, "candles"], [1200, 3000, "candles"], [600, 3700, "candles"], [1300, 3700, "candles"], [900, 3250, "rug"],
	[2200, 1200, "puddle"], [3000, 1300, "puddle"], [2600, 1700, "oil"], [4300, 1300, "rope"]]

# Inimigos posicionados à mão: [x, y, grupo]. O grupo define a lista de tipos sorteada pela seed.
const SPAWNS := [
	[1350, 4550, "dock"], [1400, 4900, "dock"],
	[2150, 4250, "mix"], [2500, 4450, "mix"], [2850, 4450, "mix"], [3300, 4300, "mix"], [2150, 5050, "mix"], [2800, 4800, "mix"], [3350, 5000, "mix"], [2650, 4750, "mix"], [3000, 4250, "mix"],
	[4000, 4450, "mix"], [4300, 4700, "mix"], [4800, 4350, "mix"], [4950, 4650, "mix"], [4500, 5000, "mix"], [4200, 4300, "mix"], [4750, 4950, "mix"],
	[3700, 2700, "heavy"], [4050, 2700, "heavy"], [4450, 2700, "heavy"], [4850, 2700, "heavy"], [3800, 3350, "heavy"], [4700, 3350, "heavy"], [4250, 3650, "heavy"], [3650, 3700, "heavy"], [4850, 3700, "heavy"],
	[2400, 2900, "mix"], [2700, 2950, "mix"], [2800, 2900, "mix"], [2050, 2600, "mix"], [3150, 2600, "mix"], [2100, 3500, "mix"], [3100, 3100, "mix"],
	[550, 2850, "cult"], [1350, 2850, "cult"], [700, 3650, "cult"], [1250, 3650, "cult"], [900, 3400, "cult"], [1000, 2950, "cult"]]
const GROUPS := {"dock": ["crawler", "fish"], "mix": ["cult", "fish", "brute", "crawler"], "heavy": ["brute", "fish", "cult", "brute"], "cult": ["cult", "cult", "crawler"]}
