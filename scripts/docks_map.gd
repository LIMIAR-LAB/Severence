extends RefCounted

# Mapa FIXO das Docas de 1941 — 0.13. GERADO por tools/build_docks_map.py (edite lá e rode o script).
# 13 salas + sala secreta, com laços estilo Enter the Gungeon. Esquadrões fixos; a seed varia posições e elites.
# Obstáculos: [x, y, w, h, tipo] (caixa = pés do prop). Decoração: [x, y, tipo, extras?].

const ENTRY_ART_BOUNDS := Rect2(187, 6000, 2013, 1280)
const ENTRY_RECTS := [Rect2(600, 6380, 1240, 540), Rect2(600, 6260, 1050, 120), Rect2(900, 6000, 200, 260), Rect2(1840, 6400, 360, 230), Rect2(1600, 6920, 160, 65)]
const ROOMS := [
{"id": "entry", "name": "01 • DESEMBARQUE", "kind": "entry", "floor": "stone", "r": Rect2(600, 6380, 1240, 540), "extra": [Rect2(600, 6260, 1050, 120), Rect2(900, 6000, 200, 260), Rect2(1840, 6400, 360, 230), Rect2(1600, 6920, 160, 65)]},
{"id": "cranes", "name": "02 • PÁTIO DOS GUINDASTES", "kind": "fight", "floor": "stone", "r": Rect2(2500, 5800, 1900, 1300), "extra": [Rect2(4400, 5800, 300, 300)]},
{"id": "warehouse", "name": "03 • ARMAZÉM 7", "kind": "maze", "floor": "planks", "r": Rect2(4700, 5900, 1600, 1100), "extra": [Rect2(4700, 7000, 320, 300)]},
{"id": "market", "name": "04 • MERCADO DE PEIXE", "kind": "fight", "floor": "cobble", "r": Rect2(6600, 5900, 1500, 1100), "extra": [Rect2(6320, 5900, 280, 260)]},
{"id": "shop", "name": "05 • OFICINA", "kind": "shop", "floor": "cobble", "r": Rect2(8400, 6000, 1100, 900)},
{"id": "generator", "name": "06 • O ÚLTIMO GERADOR", "kind": "side", "floor": "stone", "r": Rect2(8300, 3900, 1300, 1100)},
{"id": "ammo", "name": "07 • DEPÓSITO DE MUNIÇÃO", "kind": "fight", "floor": "stone", "r": Rect2(6200, 3700, 1700, 1300)},
{"id": "rails", "name": "08 • PÁTIO FERROVIÁRIO", "kind": "fight", "floor": "stone", "r": Rect2(3900, 3700, 1900, 1300), "extra": [Rect2(5800, 3700, 300, 320)]},
{"id": "stairs", "name": "09 • BALCÃO DO FAROL", "kind": "stairs", "floor": "cobble", "r": Rect2(1800, 3700, 1700, 1300)},
{"id": "chapel", "name": "10 • CAPELA DO CULTO", "kind": "story", "floor": "cobble", "r": Rect2(200, 3600, 1300, 1400), "extra": [Rect2(300, 5000, 300, 340), Rect2(1200, 5000, 300, 340)]},
{"id": "drydock", "name": "11 • DOQUE SECO", "kind": "fight", "floor": "stone", "r": Rect2(200, 1200, 1500, 1500), "extra": [Rect2(1400, 900, 500, 300)]},
{"id": "cellar", "name": "13 • ADEGA INUNDADA", "kind": "chest", "floor": "planks", "r": Rect2(7600, 1200, 1500, 1100), "extra": [Rect2(7000, 1400, 600, 600)]},
{"id": "boss", "name": "12 • O ALMIRANTE DAS PROFUNDEZAS", "kind": "boss", "floor": "stone", "r": Rect2(3000, 400, 2400, 1800), "extra": [Rect2(2600, 700, 400, 500), Rect2(5400, 800, 300, 600)]},
{"id": "secret", "name": "? • CONTRABANDO", "kind": "secret", "floor": "planks", "r": Rect2(5900, 900, 900, 700)}]

const EXTRA_FLOORS := []
const ROOM_EXTRA := {"cranes": [Rect2(4400, 5800, 300, 300)], "warehouse": [Rect2(4700, 7000, 320, 300)], "market": [Rect2(6320, 5900, 280, 260)], "rails": [Rect2(5800, 3700, 300, 320)], "chapel": [Rect2(300, 5000, 300, 340), Rect2(1200, 5000, 300, 340)], "drydock": [Rect2(1400, 900, 500, 300)], "cellar": [Rect2(7000, 1400, 600, 600)], "boss": [Rect2(2600, 700, 400, 500), Rect2(5400, 800, 300, 600)], "entry": [Rect2(600, 6260, 1050, 120), Rect2(900, 6000, 200, 260), Rect2(1840, 6400, 360, 230), Rect2(1600, 6920, 160, 65)]}
const CORRIDORS := [
	Rect2(2200, 6400, 300, 200), Rect2(900, 5000, 200, 1000), Rect2(4400, 6300, 300, 200), Rect2(6300, 6300, 300, 200),
	Rect2(8100, 6300, 300, 200), Rect2(8850, 5000, 200, 1000), Rect2(7000, 5000, 200, 900), Rect2(7900, 4300, 400, 200),
	Rect2(5800, 4200, 400, 200), Rect2(4000, 5000, 200, 800), Rect2(3500, 4200, 400, 200), Rect2(1500, 4200, 300, 200),
	Rect2(700, 2700, 200, 900), Rect2(1700, 1500, 1300, 200), Rect2(3300, 2200, 200, 1500), Rect2(8800, 2300, 200, 1600)]
const SECRET_CORRIDOR := Rect2(6450, 1600, 180, 2100)
const RAISED := [Rect2(2250, 4000, 800, 360)]
const RAMPS := [
	{"r": Rect2(2050, 4000, 200, 360), "axis": "x", "low": 2050.0, "high": 2250.0},
	{"r": Rect2(3050, 4000, 200, 360), "axis": "x", "low": 3250.0, "high": 3050.0}]
const GAPS := [Rect2(7950, 1200, 80, 700), Rect2(650, 1650, 600, 520)]

const POINTS := {
	"spawn": Vector2(850, 6550), "spawn2": Vector2(920, 6590), "key": Vector2(1450, 6560), "shop": Vector2(8950, 6170),
	"side": Vector2(8950, 4450), "secret_wall": Vector2(6540, 3740), "boss": Vector2(4200, 1200), "extraction": Vector2(4200, 720),
	"mech": Vector2(9250, 6700), "ammo_center": Vector2(7050, 4350), "warden": Vector2(4850, 4350)}
const CHESTS := [[850, 3800, false], [8850, 1400, false], [6350, 1150, true], [6100, 6100, false]]

# Bordas: top facade|wall|none • bottom wall|quay|none • left/right wall|pier • quay_band = faixa de granito
const ROOM_STYLE := {
	"entry": {"painted": true, "top": "none", "bottom": "none", "left": "none", "right": "none"},
	"cranes": {"top": "facade", "bottom": "quay", "quay_band": 150},
	"warehouse": {"top": "facade", "bottom": "wall"},
	"market": {"top": "facade", "bottom": "quay", "quay_band": 140, "floor_set": "market"},
	"shop": {"top": "facade", "bottom": "quay", "right": "pier", "quay_band": 130, "floor_set": "workshop"},
	"generator": {"top": "facade", "bottom": "wall", "wall_set": "rail"},
	"ammo": {"top": "facade", "bottom": "wall", "wall_set": "rail", "floor_set": "depot"},
	"rails": {"top": "facade", "bottom": "wall", "wall_set": "rail"},
	"stairs": {"top": "facade", "bottom": "wall", "wall_set": "rail", "floor_set": "lighthouse"},
	"chapel": {"top": "facade", "bottom": "wall", "left": "pier", "wall_set": "cult", "floor_set": "chapel", "floor_patch": Rect2(640, 3700, 420, 1300)},
	"drydock": {"top": "facade", "bottom": "wall", "left": "pier", "wall_set": "rail", "floor_set": "drydock"},
	"cellar": {"top": "facade", "bottom": "wall", "right": "pier", "wall_set": "abyssal", "floor_set": "cellar"},
	"boss": {"top": "facade", "bottom": "wall", "wall_set": "abyssal", "floor_set": "boss"},
	"secret": {"top": "facade", "bottom": "wall", "wall_set": "abyssal"}}
const WATER := [
	{"room": "entry", "r": Rect2(-400, 5600, 1000, 2000)},
	{"room": "entry", "r": Rect2(600, 7000, 1900, 600)},
	{"room": "cranes", "r": Rect2(2500, 7100, 1900, 500)},
	{"room": "market", "r": Rect2(6600, 7000, 1500, 600)},
	{"room": "shop", "r": Rect2(8400, 6900, 1100, 700)},
	{"room": "shop", "r": Rect2(9500, 5800, 900, 1800)},
	{"room": "chapel", "r": Rect2(-500, 3400, 700, 1800)},
	{"room": "drydock", "r": Rect2(-500, 1000, 700, 1900)},
	{"room": "cellar", "r": Rect2(9100, 1000, 900, 1500)},
	# Moldura aquática visual da arena; pisos/alas são desenhados por cima e mantêm a colisão original.
	{"room": "boss", "r": Rect2(500, -1000, 7400, 1500)},
	{"room": "boss", "r": Rect2(500, 400, 2500, 3200)},
	{"room": "boss", "r": Rect2(5400, 400, 2500, 3200)},
	{"room": "boss", "r": Rect2(500, 2200, 7400, 1400)}]
# Perigos: poça com tentáculo (pisar = meio coração e empurrão; saltar escapa).
const HAZARDS := [
	{"p": Vector2(7420, 6700), "r": 66, "damage": 12},
	{"p": Vector2(450, 2250), "r": 60, "damage": 12},
	{"p": Vector2(1450, 2050), "r": 60, "damage": 12},
	{"p": Vector2(8300, 2050), "r": 60, "damage": 12},
	{"p": Vector2(3350, 1300), "r": 64, "damage": 12},
	{"p": Vector2(5050, 1300), "r": 64, "damage": 12},
	{"p": Vector2(5300, 6800), "r": 75, "damage": 12, "trap": "spikes", "offset": 0},
	{"p": Vector2(5470, 6150), "r": 75, "damage": 12, "trap": "darts", "offset": 0.8},
	{"p": Vector2(6000, 6510), "r": 75, "damage": 12, "trap": "steam", "offset": 1.6}]
# 0.16: atalhos (parede rachada que a explosão abre) e portões de tentáculo (selam num evento).
const SHORTCUTS := [
	{"r": Rect2(2740, 5000, 128, 800), "wall": Rect2(2740, 5776, 128, 36), "room": "cranes"},
	{"r": Rect2(5100, 5000, 128, 900), "wall": Rect2(5100, 5876, 128, 36), "room": "warehouse"}]
const TENTACLE_GATES := [
	{"p": Vector2(6000, 4300), "block": Rect2(5860, 4200, 280, 200), "event": "warden", "damage": 12.0},
	{"p": Vector2(8100, 4400), "block": Rect2(7960, 4300, 280, 200), "event": "side", "damage": 12.0}]

const OBSTACLES := [
	[2802, 6090, 96, 60, "crane"], [3902, 6090, 96, 60, "crane"], [2802, 6740, 96, 60, "crane"], [3902, 6740, 96, 60, "crane"],
	[3110, 5930, 140, 70, "container_red"], [3270, 5930, 140, 70, "container_olive"], [3545, 5948, 150, 72, "container_open_red"], [3110, 6890, 140, 70, "container"],
	[3425, 6908, 150, 72, "container_open_olive"], [2645, 6440, 110, 40, "sandbags"], [2757, 6440, 110, 40, "sandbags"], [3775, 6440, 110, 40, "sandbags"],
	[3887, 6440, 110, 40, "sandbags"], [3309, 6370, 42, 30, "barrel_explosive"], [3357, 6376, 42, 30, "barrel_oil"], [3327, 6408, 42, 30, "barrel_explosive"],
	[3409, 6590, 42, 30, "barrel_explosive"], [3457, 6596, 42, 30, "barrel_oil"], [3427, 6628, 42, 30, "barrel_explosive"], [2592, 5860, 56, 40, "crate"],
	[2647, 5856, 66, 44, "crate_barnacles"], [2616, 5904, 52, 40, "crate_3"], [4148, 6858, 64, 42, "crate_net"], [4212, 6860, 56, 40, "crate_2"],
	[4180, 6914, 44, 30, "barrel"], [2939, 5900, 42, 30, "barrel_explosive"], [2987, 5906, 42, 30, "barrel_oil"], [2957, 5938, 42, 30, "barrel_explosive"],
	[3069, 6442, 22, 18, "lamp_post"], [3749, 6682, 22, 18, "lamp_post"], [2602, 6674, 36, 26, "brazier"], [2682, 7012, 36, 28, "bollard"],
	[3012, 7012, 36, 28, "bollard"], [3342, 7012, 36, 28, "bollard"], [3672, 7012, 36, 28, "bollard"], [4002, 7012, 36, 28, "bollard"],
	[4332, 7012, 36, 28, "bollard"], [4509, 5932, 22, 18, "lamp_post"], [4518, 5958, 64, 42, "crate_net"], [4582, 5960, 56, 40, "crate_2"],
	[4550, 6014, 44, 30, "barrel"], [4722, 7040, 56, 40, "crate"], [4777, 7036, 66, 44, "crate_barnacles"], [4746, 7084, 52, 40, "crate_3"],
	[4858, 7186, 84, 34, "jerrycans"], [4769, 7232, 22, 18, "lamp_post"], [6744, 6120, 112, 30, "bench"], [6924, 6120, 112, 30, "bench"],
	[7272, 6114, 56, 36, "fish_basket"], [7342, 6114, 56, 36, "fish_basket"], [7412, 6114, 56, 36, "fish_basket"], [6744, 6420, 112, 30, "bench"],
	[6924, 6420, 112, 30, "bench"], [7272, 6414, 56, 36, "fish_basket"], [7342, 6414, 56, 36, "fish_basket"], [7412, 6414, 56, 36, "fish_basket"],
	[7708, 6110, 84, 40, "lobster_trap"], [7808, 6410, 84, 40, "lobster_trap"], [7915, 6110, 70, 40, "radio"], [7132, 6624, 36, 26, "brazier"],
	[7682, 6624, 36, 26, "brazier"], [6709, 6682, 22, 18, "lamp_post"], [7969, 6682, 22, 18, "lamp_post"], [6729, 5970, 42, 30, "barrel_explosive"],
	[6777, 5976, 42, 30, "barrel_oil"], [6747, 6008, 42, 30, "barrel_explosive"], [7852, 5890, 56, 40, "crate_2"], [7912, 5890, 56, 40, "crate"],
	[7870, 5932, 64, 42, "crate_net"], [6702, 6932, 36, 28, "bollard"], [7032, 6932, 36, 28, "bollard"], [7362, 6932, 36, 28, "bollard"],
	[7692, 6932, 36, 28, "bollard"], [8022, 6932, 36, 28, "bollard"], [7090, 6130, 120, 30, "market_stall"], [7520, 6430, 120, 30, "market_stall"],
	[7558, 6144, 44, 26, "market_ice_barrel"], [7128, 6444, 44, 26, "market_ice_barrel"], [7850, 6676, 60, 24, "market_baskets"], [6854, 6746, 92, 14, "market_net"],
	[7155, 6910, 90, 20, "market_rowboat"], [6392, 5944, 56, 36, "fish_basket"], [6458, 6070, 44, 30, "barrel"], [8762, 6200, 56, 40, "crate"],
	[8822, 6200, 56, 40, "crate"], [8882, 6200, 56, 40, "crate"], [8942, 6200, 56, 40, "crate"], [9002, 6200, 56, 40, "crate"],
	[9062, 6200, 56, 40, "crate"], [8504, 6114, 72, 36, "medkit"], [9345, 6110, 70, 40, "radio"], [9318, 6366, 84, 34, "jerrycans"],
	[8509, 6582, 22, 18, "lamp_post"], [9389, 6582, 22, 18, "lamp_post"], [8472, 6740, 56, 40, "crate"], [8527, 6736, 66, 44, "crate_barnacles"],
	[8496, 6784, 52, 40, "crate_3"], [9256, 6044, 88, 26, "workshop_bench"], [8452, 6040, 56, 20, "workshop_tool_rack"], [9412, 6040, 56, 20, "workshop_tool_rack"],
	[9151, 6398, 58, 22, "workshop_welder"], [8590, 6428, 60, 22, "workshop_parts"], [9120, 6578, 60, 22, "workshop_parts"], [8895, 4260, 110, 90, "generator"],
	[8505, 4060, 90, 90, "pillar"], [9305, 4060, 90, 90, "pillar"], [8505, 4710, 90, 90, "pillar"], [9305, 4710, 90, 90, "pillar"],
	[8399, 4420, 42, 30, "barrel_explosive"], [8447, 4426, 42, 30, "barrel_oil"], [8417, 4458, 42, 30, "barrel_explosive"], [9399, 4520, 42, 30, "barrel_explosive"],
	[9447, 4526, 42, 30, "barrel_oil"], [9417, 4558, 42, 30, "barrel_explosive"], [8682, 4574, 36, 26, "brazier"], [9182, 4574, 36, 26, "brazier"],
	[6325, 3850, 70, 50, "ammo"], [6397, 3850, 70, 50, "ammo"], [6469, 3850, 70, 50, "ammo"], [7565, 3850, 70, 50, "ammo"],
	[7637, 3850, 70, 50, "ammo"], [7709, 3850, 70, 50, "ammo"], [6425, 4210, 110, 40, "sandbags"], [6537, 4210, 110, 40, "sandbags"],
	[7345, 4210, 110, 40, "sandbags"], [7457, 4210, 110, 40, "sandbags"], [6879, 4020, 42, 30, "barrel_explosive"], [6927, 4026, 42, 30, "barrel_oil"],
	[6897, 4058, 42, 30, "barrel_explosive"], [7229, 4020, 42, 30, "barrel_explosive"], [7277, 4026, 42, 30, "barrel_oil"], [7247, 4058, 42, 30, "barrel_explosive"],
	[7029, 4520, 42, 30, "barrel_explosive"], [7077, 4526, 42, 30, "barrel_oil"], [7047, 4558, 42, 30, "barrel_explosive"], [6350, 4730, 140, 70, "container_red"],
	[7580, 4730, 140, 70, "container"], [6975, 4798, 150, 72, "container_open"], [6268, 4478, 64, 42, "crate_net"], [6332, 4480, 56, 40, "crate_2"],
	[6300, 4534, 44, 30, "barrel"], [7672, 4480, 56, 40, "crate_2"], [7732, 4480, 56, 40, "crate"], [7690, 4522, 64, 42, "crate_net"],
	[6689, 4582, 22, 18, "lamp_post"], [7439, 4582, 22, 18, "lamp_post"], [4330, 4060, 140, 70, "container_red"], [4490, 4060, 140, 70, "container_olive"],
	[5130, 4330, 140, 70, "container"], [5285, 4348, 150, 72, "container_open_red"], [4530, 4630, 140, 70, "container_olive"], [4685, 4648, 150, 72, "container_open"],
	[4022, 3820, 56, 40, "crate"], [4077, 3816, 66, 44, "crate_barnacles"], [4046, 3864, 52, 40, "crate_3"], [5518, 3818, 64, 42, "crate_net"],
	[5582, 3820, 56, 40, "crate_2"], [5550, 3874, 44, 30, "barrel"], [5472, 4760, 56, 40, "crate_2"], [5532, 4760, 56, 40, "crate"],
	[5490, 4802, 64, 42, "crate_net"], [4045, 4410, 110, 40, "sandbags"], [4945, 3960, 110, 40, "sandbags"], [5498, 4360, 104, 40, "sandbags_damaged"],
	[4879, 4570, 42, 30, "barrel_explosive"], [4927, 4576, 42, 30, "barrel_oil"], [4897, 4608, 42, 30, "barrel_explosive"], [4207, 4862, 86, 38, "wheelbarrow"],
	[4289, 4282, 22, 18, "lamp_post"], [5089, 4782, 22, 18, "lamp_post"], [4832, 3924, 36, 26, "brazier"], [5872, 3740, 56, 40, "crate_2"],
	[5932, 3740, 56, 40, "crate"], [5890, 3782, 64, 42, "crate_net"], [5989, 3932, 22, 18, "lamp_post"], [1905, 4610, 90, 90, "pillar"],
	[3305, 4610, 90, 90, "pillar"], [2305, 4470, 90, 90, "pillar"], [2905, 4470, 90, 90, "pillar"], [2445, 4480, 110, 40, "sandbags"],
	[2557, 4480, 110, 40, "sandbags"], [2669, 4480, 110, 40, "sandbags"], [2282, 4024, 36, 26, "brazier"], [2982, 4024, 36, 26, "brazier"],
	[1872, 3760, 56, 40, "crate_2"], [1932, 3760, 56, 40, "crate"], [1890, 3802, 64, 42, "crate_net"], [2972, 3760, 56, 40, "crate"],
	[3027, 3756, 66, 44, "crate_barnacles"], [2996, 3804, 52, 40, "crate_3"], [2678, 4770, 44, 30, "barrel"], [2727, 4776, 42, 30, "barrel_oil"],
	[2697, 4808, 42, 30, "barrel_toxic"], [2089, 4532, 22, 18, "lamp_post"], [3189, 4532, 22, 18, "lamp_post"], [750, 3860, 200, 90, "altar"],
	[322, 4000, 210, 44, "pew"], [545, 3998, 190, 44, "pew"], [545, 4055, 190, 42, "pew"], [545, 4110, 190, 42, "pew"],
	[966, 3998, 190, 44, "pew"], [966, 4055, 190, 42, "pew"], [966, 4110, 190, 42, "pew"], [1168, 4000, 210, 44, "pew"],
	[375, 3680, 50, 20, "chapel_stained_glass"], [1275, 3680, 50, 20, "chapel_stained_glass"], [628, 3990, 44, 20, "chapel_offering_bowl"], [1028, 3990, 44, 20, "chapel_offering_bowl"],
	[632, 3754, 36, 26, "brazier"], [1032, 3754, 36, 26, "brazier"], [402, 1440, 96, 60, "crane"], [1402, 2340, 96, 60, "crane"],
	[1318, 1258, 64, 42, "crate_net"], [1382, 1260, 56, 40, "crate_2"], [1350, 1314, 44, 30, "barrel"], [272, 2410, 56, 40, "crate_2"],
	[332, 2410, 56, 40, "crate"], [290, 2452, 64, 42, "crate_net"], [1379, 1770, 42, 30, "barrel_explosive"], [1427, 1776, 42, 30, "barrel_oil"],
	[1397, 1808, 42, 30, "barrel_explosive"], [329, 1970, 42, 30, "barrel_explosive"], [377, 1976, 42, 30, "barrel_oil"], [347, 2008, 42, 30, "barrel_explosive"],
	[602, 2252, 36, 28, "bollard"], [772, 2252, 36, 28, "bollard"], [942, 2252, 36, 28, "bollard"], [1112, 2252, 36, 28, "bollard"],
	[549, 1382, 22, 18, "lamp_post"], [1339, 2232, 22, 18, "lamp_post"], [7679, 1320, 42, 30, "barrel_oil"], [7729, 1320, 42, 30, "barrel_oil"],
	[7779, 1320, 42, 30, "barrel_oil"], [7679, 1520, 42, 30, "barrel_oil"], [7729, 1520, 42, 30, "barrel_oil"], [7779, 1520, 42, 30, "barrel_oil"],
	[7679, 1720, 42, 30, "barrel_oil"], [7729, 1720, 42, 30, "barrel_oil"], [7779, 1720, 42, 30, "barrel_oil"], [8122, 1260, 56, 40, "crate"],
	[8177, 1256, 66, 44, "crate_barnacles"], [8146, 1304, 52, 40, "crate_3"], [8167, 1656, 66, 44, "crate_barnacles"], [8239, 1656, 66, 44, "crate_barnacles"],
	[8479, 1920, 42, 30, "barrel_explosive"], [8527, 1926, 42, 30, "barrel_oil"], [8497, 1958, 42, 30, "barrel_explosive"], [8918, 2010, 64, 40, "crate_broken"],
	[7672, 2064, 56, 36, "fish_basket"], [8382, 1574, 36, 26, "brazier"], [8989, 1682, 22, 18, "lamp_post"], [3355, 710, 90, 90, "pillar"],
	[4955, 710, 90, 90, "pillar"], [3355, 1710, 90, 90, "pillar"], [4955, 1710, 90, 90, "pillar"], [3232, 574, 36, 26, "brazier"],
	[5132, 574, 36, 26, "brazier"], [3232, 2024, 36, 26, "brazier"], [5132, 2024, 36, 26, "brazier"], [3782, 1124, 36, 26, "brazier"],
	[4582, 1124, 36, 26, "brazier"], [3129, 1270, 42, 30, "barrel_explosive"], [3177, 1276, 42, 30, "barrel_oil"], [3147, 1308, 42, 30, "barrel_explosive"],
	[5179, 1270, 42, 30, "barrel_explosive"], [5227, 1276, 42, 30, "barrel_oil"], [5197, 1308, 42, 30, "barrel_explosive"], [3589, 982, 22, 18, "lamp_post"],
	[4789, 982, 22, 18, "lamp_post"], [5952, 940, 56, 40, "crate_2"], [6012, 940, 56, 40, "crate"], [5970, 982, 64, 42, "crate_net"],
	[6572, 940, 56, 40, "crate"], [6627, 936, 66, 44, "crate_barnacles"], [6596, 984, 52, 40, "crate_3"], [5978, 1370, 44, 30, "barrel"],
	[6027, 1376, 42, 30, "barrel_oil"], [5997, 1408, 42, 30, "barrel_toxic"], [6614, 1414, 72, 36, "medkit"], [5100, 6000, 90, 650, "maze_wall"],
	[5680, 6370, 90, 530, "maze_wall"], [6680, 4280, 90, 470, "maze_wall"], [7420, 3900, 90, 430, "maze_wall"]]

const DECOR := [
	[3020, 5750, "poster"], [3480, 5802, "iron_door"], [3980, 5750, "poster"], [2650, 5720, "wall_lamp"], [3400, 6250, "rails"],
	[3400, 6560, "rails"], [3000, 6620, "grate"], [3800, 6300, "manhole"], [3400, 6780, "symbol_2"], [4600, 6150, "rope"],
	[5000, 5902, "iron_door"], [5600, 5850, "poster"], [6050, 5902, "iron_door"], [4850, 5820, "wall_lamp"], [5270, 5820, "wall_lamp"],
	[5300, 6380, "tentacle_planks"], [5850, 6800, "debris_barrel"], [5000, 6800, "rope"], [6950, 5850, "poster"], [7400, 5906, "phone_booth"],
	[7800, 5902, "iron_door"], [6750, 5820, "wall_lamp"], [7170, 5820, "wall_lamp"], [7590, 5820, "wall_lamp"], [7420, 6700, "tentacle_pool"],
	[7000, 6330, "grate"], [7550, 6330, "symbol_1"], [6700, 6400, "anchor"], [6850, 5850, "market_lanterns"], [7280, 5850, "market_lanterns"],
	[6400, 6120, "grate"], [8650, 6002, "iron_door"], [9200, 5950, "poster"], [8550, 5920, "wall_lamp"], [8970, 5920, "wall_lamp"],
	[9390, 5920, "wall_lamp"], [8950, 6600, "manhole"], [9100, 6800, "rope"], [9250, 6560, "workshop_hoist"], [8850, 6480, "workshop_oil_puddle"],
	[9060, 6720, "workshop_oil_puddle"], [8600, 6300, "workshop_oil_puddle"], [8600, 3902, "iron_door"], [9300, 3902, "iron_door"], [8450, 3820, "wall_lamp"],
	[8870, 3820, "wall_lamp"], [8950, 4650, "symbol_0"], [8650, 4350, "grate"], [9250, 4350, "grate"], [6900, 3650, "poster"],
	[7400, 3702, "iron_door"], [6350, 3620, "wall_lamp"], [6770, 3620, "wall_lamp"], [7190, 3620, "wall_lamp"], [7610, 3620, "wall_lamp"],
	[7050, 4300, "manhole"], [6600, 4650, "debris_sandbags"], [4300, 3650, "poster"], [4850, 3702, "iron_door"], [5400, 3650, "poster"],
	[4050, 3620, "wall_lamp"], [4470, 3620, "wall_lamp"], [3950, 3900, "rails_diag", {"to": Vector2(5750, 4450)}], [3950, 4500, "rails_diag", {"to": Vector2(5750, 4950)}], [4700, 4400, "grate"],
	[5300, 4700, "symbol_2"], [4350, 4700, "debris_crate"], [2150, 3702, "iron_door"], [2650, 3650, "poster"], [3150, 3702, "iron_door"],
	[1950, 3620, "wall_lamp"], [2370, 3620, "wall_lamp"], [2790, 3620, "wall_lamp"], [2650, 4200, "symbol_1"], [2650, 4900, "manhole"],
	[850, 3602, "iron_door"], [850, 4150, "ritual_circle"], [450, 3850, "symbol_0"], [1250, 3850, "symbol_2"], [450, 3750, "chapel_candles"],
	[1250, 3750, "chapel_candles"], [400, 4850, "chapel_candles"], [1300, 4850, "chapel_candles"], [700, 3990, "chapel_candles"], [1000, 3990, "chapel_candles"],
	[560, 3590, "chapel_banner"], [1140, 3590, "chapel_banner"], [850, 4500, "rug"], [500, 4880, "tentacle_planks"], [550, 1150, "poster"],
	[1100, 1202, "iron_door"], [350, 1120, "wall_lamp"], [770, 1120, "wall_lamp"], [950, 1900, "rowboat"], [450, 2250, "tentacle_pool"],
	[1450, 2050, "tentacle_pool"], [1100, 1400, "rope"], [300, 1350, "anchor"], [8000, 1202, "iron_door"], [8600, 1202, "iron_door"],
	[7750, 1120, "wall_lamp"], [8170, 1120, "wall_lamp"], [8300, 2050, "tentacle_pool"], [7750, 2000, "tentacle_planks"], [8700, 1500, "symbol_1"],
	[8450, 1350, "debris_barrel"], [4200, 402, "iron_door"], [3150, 320, "wall_lamp"], [3570, 320, "wall_lamp"], [3990, 320, "wall_lamp"],
	[4410, 320, "wall_lamp"], [4830, 320, "wall_lamp"], [5250, 320, "wall_lamp"], [4200, 1250, "ritual_circle"], [3600, 1500, "symbol_0"],
	[4800, 1500, "symbol_1"], [4200, 1900, "symbol_2"], [3350, 1300, "tentacle_pool"], [5050, 1300, "tentacle_pool"], [3200, 480, "debris_crate"],
	[5200, 480, "debris_crate"], [3150, 2150, "debris_barrel"], [5250, 2150, "debris_barrel"], [3700, 2080, "tentacle_planks"], [4750, 2080, "tentacle_planks"],
	[3150, 1000, "anchor"], [5250, 1000, "anchor"], [3800, 1700, "grate"], [4600, 1700, "grate"], [4200, 2000, "manhole"],
	[6200, 1450, "rope"]]

# Inimigos posicionados à mão: [x, y, grupo]. O grupo define os tipos sorteados pela seed.
const SPAWNS := [
	[1450, 6380, "crawler"], [1710, 6580, "fish"], [1510, 6790, "cult"], [2750, 6300, "cult"], [3100, 6200, "guard"], [3650, 6250, "crawler"],
	[4150, 6300, "fish"], [2750, 6900, "bomber"], [3300, 6850, "brute"], [3750, 6600, "cult"], [4150, 6700, "guard"], [6900, 6300, "fish"],
	[7200, 6050, "crawler"], [7600, 6300, "guard"], [7900, 6600, "bomber"], [7000, 6800, "fish"], [7400, 6170, "crawler"], [7750, 6800, "guard"],
	[6400, 4050, "brute"], [6800, 3900, "guard"], [7300, 3900, "fish"], [7700, 4100, "bomber"], [6500, 4650, "brute"], [7600, 4650, "guard"],
	[7050, 4750, "fish"], [6900, 4350, "bomber"], [7300, 4400, "brute"], [4100, 4100, "guard"], [4500, 3900, "brute"], [5000, 4250, "bomber"],
	[5600, 4150, "cult"], [4400, 4550, "guard"], [4900, 4850, "brute"], [5500, 4650, "bomber"], [5250, 3900, "cult"], [2400, 4100, "cult"],
	[2700, 4150, "guard"], [2900, 4100, "crawler"], [2000, 3900, "fish"], [3300, 4300, "bomber"], [2100, 4850, "brute"], [3200, 4900, "cult"],
	[400, 1350, "cult"], [1100, 1350, "guard"], [1500, 1550, "crawler"], [400, 2500, "fish"], [1100, 2450, "bomber"], [1550, 2550, "brute"],
	[8100, 1500, "crawler"], [8600, 1400, "cult"], [8900, 1600, "bomber"], [8300, 2150, "crawler"], [8800, 2150, "cult"]]
const GROUPS := {"dock": ["crawler", "fish"], "mix": ["cult", "fish", "brute", "crawler"], "heavy": ["brute", "fish", "cult", "brute"], "cult": ["cult", "cult", "crawler"]}
