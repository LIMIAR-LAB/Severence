extends RefCounted
const DOCKS = preload("res://scripts/docks_map.gd")

# Composição das arenas: cobertura estrutural, fossos e corredores de circulação.
# Mantida fora do mapa gerado para não perder os ajustes ao regenerar docks_map.gd.
const CURATED_ROOMS := ["cranes", "warehouse", "market", "shop", "generator", "ammo", "rails", "stairs", "drydock", "cellar"]
# Cada grupo acompanha uma função da sala: carga no cais, bancas no mercado,
# munição nas paredes e equipamentos ao redor do gerador. O centro fica livre.
const ROOM_PROPS := [
	# Guindastes e carga em duas faixas, com os explosivos junto aos contêineres.
	[2750, 6060, 96, 60, "crane"], [4040, 6060, 96, 60, "crane"],
	[3090, 5920, 140, 70, "container_red"], [3250, 5920, 140, 70, "container_olive"], [3520, 5920, 150, 72, "container_open_red"],
	[3100, 6860, 140, 70, "container"], [3410, 6860, 150, 72, "container_open_olive"],
	[3310, 6070, 42, 30, "barrel_explosive"], [3358, 6070, 42, 30, "barrel_oil"], [3328, 6106, 42, 30, "barrel_explosive"],
	[2700, 6970, 36, 28, "bollard"], [3150, 6970, 36, 28, "bollard"], [3600, 6970, 36, 28, "bollard"], [4050, 6970, 36, 28, "bollard"],
	# Armazém: as duas paredes internas originais definem os corredores; a carga fica encostada nelas.
	[4800, 6040, 140, 70, "container_olive"], [4800, 6170, 140, 70, "container"],
	[5870, 6770, 56, 40, "crate"], [5930, 6770, 56, 40, "crate_2"],
	# Mercado: duas bancas legíveis, com cestos ao lado, e uma faixa de passagem central.
	[6870, 6100, 120, 30, "market_stall"], [7500, 6100, 120, 30, "market_stall"],
	[7020, 6120, 56, 36, "fish_basket"], [7080, 6120, 56, 36, "fish_basket"],
	[7650, 6120, 56, 36, "fish_basket"], [7710, 6120, 56, 36, "fish_basket"],
	[6850, 6780, 112, 30, "bench"], [7750, 6780, 112, 30, "bench"],
	[6740, 5980, 42, 30, "barrel_explosive"], [6788, 5980, 42, 30, "barrel_oil"], [6758, 6016, 42, 30, "barrel_explosive"],
	# Oficina: ferramentas na parede e estoque no fundo, longe do balcão de compra.
	[9250, 6060, 88, 26, "workshop_bench"], [8470, 6040, 56, 20, "workshop_tool_rack"], [9380, 6040, 56, 20, "workshop_tool_rack"],
	[8500, 6120, 72, 36, "medkit"], [9310, 6150, 70, 40, "radio"],
	[8710, 6720, 56, 40, "crate"], [8770, 6720, 56, 40, "crate"], [8830, 6720, 56, 40, "crate"],
	[9170, 6720, 60, 22, "workshop_parts"], [9235, 6720, 60, 22, "workshop_parts"],
	# Gerador: barris de combustível em duas reservas junto às laterais.
	[8895, 4260, 110, 90, "generator"],
	[8380, 4460, 42, 30, "barrel_explosive"], [8428, 4460, 42, 30, "barrel_oil"], [8398, 4496, 42, 30, "barrel_explosive"],
	[9380, 4460, 42, 30, "barrel_explosive"], [9428, 4460, 42, 30, "barrel_oil"], [9398, 4496, 42, 30, "barrel_explosive"],
	# Depósito: munição no fundo, cobertura alinhada aos pilares e carga junto à parede sul.
	[6330, 3850, 70, 50, "ammo"], [6405, 3850, 70, 50, "ammo"], [6480, 3850, 70, 50, "ammo"],
	[7540, 3850, 70, 50, "ammo"], [7615, 3850, 70, 50, "ammo"], [7690, 3850, 70, 50, "ammo"],
	[6350, 4720, 140, 70, "container_red"], [7580, 4720, 140, 70, "container"],
	[6340, 4380, 110, 40, "sandbags"], [7600, 4380, 110, 40, "sandbags"],
	[6850, 3900, 42, 30, "barrel_explosive"], [6898, 3900, 42, 30, "barrel_oil"], [6868, 3936, 42, 30, "barrel_explosive"],
	# Trilhos: carga paralela às bordas do pátio; trilhos permanecem visíveis no piso.
	[4330, 4050, 140, 70, "container_red"], [4490, 4050, 140, 70, "container_olive"],
	[4530, 4660, 140, 70, "container_olive"], [4690, 4660, 150, 72, "container_open"],
	[4880, 4720, 42, 30, "barrel_explosive"], [4928, 4720, 42, 30, "barrel_oil"], [4898, 4756, 42, 30, "barrel_explosive"],
	# Farol: a plataforma elevada e os pilares compõem a cobertura.
	[2445, 4480, 110, 40, "sandbags"], [2557, 4480, 110, 40, "sandbags"], [2669, 4480, 110, 40, "sandbags"],
	# Doca seca: aparelhagem junto às extremidades, borda do canal desobstruída.
	[400, 1440, 96, 60, "crane"], [1400, 2340, 96, 60, "crane"],
	[1330, 1330, 56, 40, "crate"], [1390, 1330, 56, 40, "crate_2"],
	[280, 2410, 56, 40, "crate"], [340, 2410, 56, 40, "crate_2"],
	[1360, 1800, 42, 30, "barrel_explosive"], [1408, 1800, 42, 30, "barrel_oil"], [1378, 1836, 42, 30, "barrel_explosive"],
	# Adega: barris em fileiras, estoque separado do vão inundado.
	[7680, 1320, 42, 30, "barrel_oil"], [7730, 1320, 42, 30, "barrel_oil"], [7780, 1320, 42, 30, "barrel_oil"],
	[7680, 1520, 42, 30, "barrel_oil"], [7730, 1520, 42, 30, "barrel_oil"], [7780, 1520, 42, 30, "barrel_oil"],
	[7680, 1720, 42, 30, "barrel_oil"], [7730, 1720, 42, 30, "barrel_oil"], [7780, 1720, 42, 30, "barrel_oil"],
	[8150, 1290, 56, 40, "crate"], [8210, 1290, 56, 40, "crate_2"],
]
const STRUCTURE := ["pillar", "wall_block"]
const WALL_AND_GAMEPLAY_DECOR := ["poster", "iron_door", "wall_lamp", "market_lanterns", "tentacle_pool", "tentacle_planks", "rails_diag", "rowboat", "phone_booth"]
const PITS := [Rect2(3500, 6410, 270, 180), Rect2(4740, 4430, 300, 220), Rect2(6840, 4440, 280, 200)]
const NEW_PILLARS := [
	[2870, 6290, 220, 160, "stone_pillar"], [3990, 6560, 220, 160, "stone_pillar"],
	[4170, 4160, 220, 160, "stone_pillar"], [5320, 4490, 220, 160, "stone_pillar"],
	[6570, 4240, 220, 160, "stone_pillar"], [7490, 4240, 220, 160, "stone_pillar"],
]

static func room_id_at(point: Vector2, rooms: Array) -> String:
	for room in rooms:
		if room.r.has_point(point): return room.id
		for extra in room.get("extra", []):
			if extra.has_point(point): return room.id
	return ""

static func composed_obstacles(source: Array, rooms: Array) -> Array:
	var result: Array = []
	for obstacle in source:
		var box := Rect2(obstacle[0], obstacle[1], obstacle[2], obstacle[3])
		var kind: String = obstacle[4]
		if PITS.any(func(pit: Rect2): return pit.intersects(box)):
			continue
		var room_id := room_id_at(box.get_center(), rooms)
		# Explosives beside cracked walls are authored interaction hooks, not disposable decor.
		var shortcut_trigger: bool = kind == "barrel_explosive" and DOCKS.SHORTCUTS.any(func(sc): return box.get_center().distance_to(sc.wall.get_center()) <= 220.0)
		if room_id in CURATED_ROOMS and kind not in STRUCTURE and not shortcut_trigger and not (room_id == "warehouse" and kind == "maze_wall"):
			continue
		if kind == "pillar":
			var center := box.get_center()
			result.append([center.x - 110, center.y - 80, 220, 160, "stone_pillar"])
		else:
			result.append(obstacle)
	for prop in ROOM_PROPS:
		var box := Rect2(prop[0], prop[1], prop[2], prop[3])
		if not PITS.any(func(pit: Rect2): return pit.intersects(box)):
			result.append(prop)
	result.append_array(NEW_PILLARS)
	return result

static func composed_decor(source: Array, rooms: Array) -> Array:
	var result: Array = []
	for item in source:
		var room_id := room_id_at(Vector2(item[0], item[1]), rooms)
		if room_id not in CURATED_ROOMS or item[2] in WALL_AND_GAMEPLAY_DECOR:
			result.append(item)
	return result

static func composed_gaps(source: Array) -> Array:
	var result := source.duplicate()
	result.append_array(PITS)
	return result
