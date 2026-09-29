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
	var start: Vector2 = a.p
	sim.step(0.016,[{"move":Vector2(1,1),"aim":Vector2.RIGHT,"dodge":true},{}])
	check(a.dash_dir.distance_to(Vector2(1,1).normalized())<0.001,"dash conserva direção diagonal normalizada")
	check(a.p.x>start.x and a.p.y>start.y,"dash diagonal move Marty nos dois eixos")
	print("MARTY ACTIONS failures=", failures)
	quit(failures)
