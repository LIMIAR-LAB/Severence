extends SceneTree
# 0.19: oito rumos de esquiva, fontes das quatro roupas e teleporte Ômega.
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS MARTY: ", label)
	else: failures += 1; push_error(label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var view := DockView.new()
	view.sim = Expedition.new()
	root.add_child(view)
	await process_frame
	var padrao_frames := {"idle":4,"run":8,"jump":9,"evade":6,"shoot":3,"melee":6,"hurt":6,"defeat":7}
	for action in padrao_frames:
		var texture := load("res://assets/characters/marty/padrao/pixellab/%s.png" % action) as Texture2D
		check(texture != null and texture.get_size() == Vector2(96 * padrao_frames[action], 96 * 8), "Marty Padrao %s: 8 direcoes" % action)
	var omega_frames := {"idle":4,"run":8,"jump":8,"evade":7,"melee":6,"hurt":6,"defeat":8}
	for action in omega_frames:
		var texture := load("res://assets/characters/marty/omega/pixellab/%s.png" % action) as Texture2D
		check(texture != null and texture.get_size() == Vector2(112 * omega_frames[action], 112 * 8), "Marty Omega %s: 8 direcoes" % action)
		if texture != null:
			var image := texture.get_image()
			var all_cells_present := true
			var all_cells_clear := true
			var all_directions_animated := true
			for row in range(8):
				var frame_hashes := {}
				for frame in range(omega_frames[action]):
					var cell := image.get_region(Rect2i(frame * 112, row * 112, 112, 112))
					var used := cell.get_used_rect()
					all_cells_present = all_cells_present and used.has_area()
					all_cells_clear = all_cells_clear and (not used.has_area() or (used.position.x > 0 and used.position.y > 0 and used.end.x < 112 and used.end.y < 112))
					frame_hashes[hash(cell.get_data())] = true
				all_directions_animated = all_directions_animated and frame_hashes.size() > 1
			check(all_cells_present, "Marty Omega %s: nenhuma celula vazia" % action)
			check(all_cells_clear, "Marty Omega %s: nenhuma arte toca a borda" % action)
			check(all_directions_animated, "Marty Omega %s: movimento real nas oito direcoes" % action)
	var assembly := load("res://assets/characters/marty/omega/assembly/omega_assembly_overlay_v1.png") as Texture2D
	var portraits := load("res://assets/ui/hud/marty_omega_portraits_v1.png") as Texture2D
	check(assembly != null and assembly.get_width() > assembly.get_height(), "montagem Omega progressiva carrega como folha horizontal")
	check(portraits != null and portraits.get_width() > portraits.get_height(), "retratos Marty/Omega carregam como dupla horizontal")
	check(view.omega_assembly_frame(0.0) == 0 and view.omega_assembly_frame(0.5) == 4 and view.omega_assembly_frame(1.0) == 7, "montagem Omega percorre oito estágios sem ultrapassar a folha")
	for action in ["idle", "run", "jump", "evade", "melee", "hurt", "defeat"]:
		check(not view.marty_padrao_shows_weapon(action), "Marty Padrao sem arma em " + action)
	check(view.marty_padrao_shows_weapon("shoot"), "Marty Padrao exibe arma somente no disparo")
	check(not view.marty_padrao_shows_weapon("shoot", 0.5), "transformacao nao mistura arma Omega com sprite Padrao")
	var directions := [Vector2.DOWN, Vector2(1,1), Vector2.RIGHT, Vector2(1,-1), Vector2.UP, Vector2(-1,-1), Vector2.LEFT, Vector2(-1,1)]
	for row in range(directions.size()):
		check(view.marty_direction_row(directions[row]) == row, "linha direcional PixelLab %d" % row)
	for path in ["marty_roll_side_v1.png", "marty_roll_front_diag_v1.png", "marty_roll_back_diag_v1.png"]:
		var texture := load("res://assets/marty/" + path) as Texture2D
		check(texture != null and texture.get_size() == Vector2(384,384), "folha comum 4x4: " + path)
	for path in ["marty_teleport_side_v1.png", "marty_teleport_diagonal_v1.png"]:
		var texture := load("res://assets/marty/" + path) as Texture2D
		check(texture != null and texture.get_width() == 384, "folha Ômega: " + path)
	for direction in [Vector2(1,0),Vector2(-1,0)]:
		check(view.marty_dash_view(direction)=="side", "esquiva lateral " + str(direction))
	for direction in [Vector2(1,1),Vector2(-1,1),Vector2(0,1)]:
		check(view.marty_dash_view(direction)=="front_diag", "esquiva frente/diagonal " + str(direction))
	for direction in [Vector2(1,-1),Vector2(-1,-1),Vector2(0,-1)]:
		check(view.marty_dash_view(direction)=="back_diag", "esquiva costas/diagonal " + str(direction))
	var sim := view.sim
	sim.coop="solo"; sim.start_run(1941)
	var a: Dictionary = sim.actors[0]
	var padrao_anchors := [Vector2(10,-35), Vector2(15,-36), Vector2(17,-35), Vector2(14,-38), Vector2(7,-40), Vector2(-14,-38), Vector2(-17,-35), Vector2(-15,-36)]
	for row in range(directions.size()):
		a.aim = directions[row]
		check(view.weapon_hand_anchor(a) == padrao_anchors[row], "ancora da arma PixelLab %d" % row)
	a.outfit = "mecanico"
	check(view.weapon_hand_anchor(a) == Vector2(20,-27), "roupa legada conserva ancora existente")
	check(view.marty_uses_legacy_weapon_hand(a), "roupa legada ainda pode usar mao do atlas antigo")
	a.outfit = "padrao"
	check(not view.marty_uses_legacy_weapon_hand(a), "Marty Padrao nao usa mao do atlas antigo")
	a.armor = true
	check(not view.marty_uses_legacy_weapon_hand(a), "Armadura Omega nao usa mao do atlas antigo")
	var omega_anchors := [Vector2(20,-40), Vector2(23,-43), Vector2(25,-44), Vector2(20,-47), Vector2(10,-49), Vector2(-20,-47), Vector2(-25,-44), Vector2(-23,-43)]
	for row in range(directions.size()):
		a.aim = directions[row]
		check(view.weapon_hand_anchor(a) == omega_anchors[row], "ancora da espada Omega %d" % row)
	a.armor = false
	var start: Vector2 = a.p
	sim.step(0.016,[{"move":Vector2(1,1),"aim":Vector2.RIGHT,"dodge":true},{}])
	check(a.dash_dir.distance_to(Vector2(1,1).normalized())<0.001,"dash conserva direção diagonal normalizada")
	check(a.p.x>start.x and a.p.y>start.y,"dash diagonal move Marty nos dois eixos")
	for _i in 13: sim.step_actor(a, {}, 0.016)
	check(a.dodge <= 0 and a.roll_visual > 0, "leitura da pose continua depois da proteção")
	check(view.marty_padrao_action(a, false, false) == "evade", "render usa temporização visual independente")
	a.hurt = 0; var hp: float = a.hp; sim.damage_actor(a, 10)
	check(a.hp < hp, "pose visual não prolonga invulnerabilidade")
	# All gun textures and directions use a shared barrel with elevation separate from collision.
	sim.start_arena(); a = sim.actors[0]; a.p = Vector2(500, 500); a.jump = 0; a.armor = false; sim.obstacles.clear()
	for outfit in ["padrao", "mecanico", "espiao", "bazooka"]:
		a.outfit = "padrao" if outfit == "bazooka" else outfit
		a.run_weapon = "bazooka" if outfit == "bazooka" else ""
		a.run_weapons = {"bazooka": 12}
		a.jump = 0.3 if outfit == "bazooka" else 0.0
		for direction in directions:
			a.aim = direction.normalized(); a.facing = a.aim
			var geometry: Dictionary = sim.weapon_geometry(a)
			sim.fire_actor(a)
			var bullet: Dictionary = sim.bullets[-1]
			check((bullet.p - Vector2(0, bullet.height)).distance_to(a.p + (geometry.muzzle - a.p) * sim.ACTOR_VISUAL_SCALE) < 0.01, "origem visual no cano %s %s" % [outfit, direction])
			check(bullet.v.normalized().dot(a.aim) > 0.96, "tiro acompanha direção da arma")
	a.outfit = "padrao"; a.run_weapon = ""; a.jump = 0; a.aim = Vector2.RIGHT; a.facing = a.aim
	sim.obstacles = [Rect2(525, 470, 3, 80)]
	sim.fire_actor(a)
	check(sim.bullets[-1].p.x < 525, "cano não gera projétil depois de parede fina")
	sim.obstacles.clear(); a.aim = Vector2.RIGHT; a.move = Vector2.LEFT; a.facing = Vector2.LEFT; a.fire_flash = 0
	var carried: Dictionary = sim.weapon_geometry(a, a.move)
	check(carried.hand == sim.weapon_hand_anchor(a, Vector2.LEFT) and carried.angle == a.aim.angle(), "arma em movimento acompanha mão do corpo sem mudar mira")
	sim.fire_actor(a)
	var fired_geometry: Dictionary = sim.weapon_geometry(a)
	check((sim.bullets[-1].p - Vector2(0, sim.bullets[-1].height)).distance_to(a.p + (fired_geometry.muzzle - a.p) * sim.ACTOR_VISUAL_SCALE) < 0.01, "primeiro disparo em movimento oposto nasce no cano da pose de tiro")
	print("MARTY ACTIONS failures=", failures)
	quit(failures)
