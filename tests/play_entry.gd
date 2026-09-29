extends SceneTree
# 0.19: abre uma expedição jogável no Desembarque, com os controles normais.
func _init() -> void: call_deferred("launch")
func launch() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	app.start_single()
	app.sim.start_run(1941)
	app.camera.position = app.sim.actors[0].p
	app.camera.reset_smoothing()
