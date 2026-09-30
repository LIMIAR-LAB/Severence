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
	a.outfit = "padrao"
	var start: Vector2 = a.p
	sim.step(0.016,[{"move":Vector2(1,1),"aim":Vector2.RIGHT,"dodge":true},{}])
	check(a.dash_dir.distance_to(Vector2(1,1).normalized())<0.001,"dash conserva direção diagonal normalizada")
	check(a.p.x>start.x and a.p.y>start.y,"dash diagonal move Marty nos dois eixos")
	print("MARTY ACTIONS failures=", failures)
	quit(failures)
