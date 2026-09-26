extends SceneTree

# 0.16: microbiomas (Oficina, Mercado, Capela), atalhos de parede rachada, portões de tentáculo e ícones do mapa.
const Scenery := preload("res://scripts/dock_scenery.gd")
const DOCKS := preload("res://scripts/docks_map.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func wall_index(s, sc: Dictionary) -> int:
	for i in s.obstacles.size():
		if s.obstacles[i] == sc.wall: return i
	return -1

func _init() -> void:
	var sc = Scenery.new()
	var missing: Array = []
	for n in sc.props: if sc.props[n] == null: missing.append(n)
	for n in sc.tiles: if sc.tiles[n] == null: missing.append(n)
	check(missing.is_empty(), "arte 0.16 carrega (faltando: %s)" % [missing])
	for set_name in Scenery.FLOOR_SETS:
		for e in Scenery.FLOOR_SETS[set_name]:
			check(sc.tiles[e[0]].get_size() == Vector2(64, 64), "piso %s 64x64" % e[0])
	check(sc.tiles.wall_crack_a.get_size() == Vector2(128, 216) and sc.props.tentacle_gate_active.get_size() == Vector2(140, 100), "parede 128x216 e poça 140x100")
	for key in ["boss", "shop", "challenge", "chest", "locked", "exit"]:
		var tex: Texture2D = load("res://assets/ui/map_icons/map_icon_%s.png" % key)
		check(tex != null and tex.get_size() == Vector2(48, 48), "ícone do mapa " + key)
	check(DOCKS.ROOM_STYLE.shop.floor_set == "workshop" and DOCKS.ROOM_STYLE.market.floor_set == "market" and DOCKS.ROOM_STYLE.chapel.has("floor_patch"), "salas 04, 05 e 10 com piso próprio")

	# atalhos: parede rachada fecha, explosão abre
	var s = Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	var variants := {}
	for seed in [1, 2, 3, 4, 5, 6]:
		s.start_run(seed)
		variants[s.obstacle_kinds[wall_index(s, DOCKS.SHORTCUTS[0])]] = true
	check(variants.size() == 3, "parede sorteada entre A, B e C pela seed (%s)" % [variants.keys()])
	s.start_run(1941)
	for sc_def in DOCKS.SHORTCUTS:
		var i := wall_index(s, sc_def)
		check(i >= 0 and s.obstacle_kinds[i].begins_with("wall_crack_") and s.obstacle_hp[i] < 0, "atalho fechado por parede rachada indestrutível a tiro")
		var mid: Vector2 = sc_def.wall.get_center()
		check(not s.clear_at(mid, 11), "parede bloqueia a passagem")
		for k in 5: s.add_bullet(mid + Vector2(0, 120), Vector2.UP, 0, 30, 900); s.step_bullets(0.1)
		check(wall_index(s, sc_def) >= 0, "tiros não derrubam a parede")
	# barril ao lado da parede do Pátio dos Guindastes
	var first: Dictionary = DOCKS.SHORTCUTS[0]
	var kind: String = s.obstacle_kinds[wall_index(s, first)]
	var b := -1
	for i in s.obstacles.size():
		if s.obstacle_kinds[i] == "barrel_explosive" and s.obstacles[i].get_center().distance_to(first.wall.get_center()) < 260: b = i; break
	check(b >= 0, "barril explosivo perto da parede rachada")
	s.enemies.clear()
	s.damage_obstacle(b, 99)
	for k in 30: s.step(0.016, [{}, {}])
	check(wall_index(s, first) < 0 and s.clear_at(first.wall.get_center(), 11), "explosão abre o atalho e libera a colisão")
	check(s.decor.any(func(d): return d.kind == kind + "_open"), "sprite troca para a versão _open (%s_open)" % kind)
	check(s.clear_at(Vector2(first.r.get_center().x, first.r.position.y + 100), 11), "corredor do atalho é piso")

	# portões de tentáculo
	s.start_run(1941)
	check(s.tentacle_gates.size() == 2 and s.tentacle_gates.all(func(g): return not g.sealed), "2 portões de tentáculo ativos")
	var g: Dictionary = s.tentacle_gates.filter(func(x): return x.event == "warden")[0]
	check(not s.clear_at(g.block.get_center(), 11), "portão ativo bloqueia o corredor")
	var a: Dictionary = s.actors[0]
	a.p = Vector2(g.block.position.x - 8, g.block.get_center().y); a.hurt = 0
	var hp: float = a.hp
	s.step(0.016, [{}, {}])
	check(a.hp < hp and a.p.x < g.block.position.x - 8, "encostar fere e empurra para trás")
	s.enemies = s.enemies.filter(func(e): return e.kind != "warden")
	a.p = Vector2(820, 6480); s.step(0.016, [{}, {}])
	check(g.sealed and s.clear_at(g.block.get_center(), 11), "mini-chefe morto: portão selado e atravessável")
	a.p = g.p; a.hurt = 0; hp = a.hp; s.step(0.016, [{}, {}])
	check(a.hp == hp, "selado não fere")
	var side: Dictionary = s.tentacle_gates.filter(func(x): return x.event == "side")[0]
	check(not side.sealed, "portão do gerador segue ativo")
	s.side_complete = true; s.step(0.016, [{}, {}])
	check(side.sealed, "desafio do gerador concluído sela o outro portão")
	print("SCENERY_016_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
