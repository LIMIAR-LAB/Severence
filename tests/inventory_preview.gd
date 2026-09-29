extends SceneTree

func _initialize() -> void:
	var viewport := SubViewport.new(); viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
	var app = load("res://scenes/main.tscn").instantiate(); viewport.add_child(app)
	await process_frame
	app.sim.set_unlocks(["padrao", "mecanico", "espiao", "omega", "titan", "spectre"])
	app.menu.read_equipment(); app.menu.show_screen("equipment")
	await process_frame; await process_frame; await process_frame
	DirAccess.make_dir_recursive_absolute("res://test-output")
	var image := viewport.get_texture().get_image()
	var error := image.save_png("res://test-output/menu-inventario-final.png")
	app.sim.set_unlocks(["padrao", "mecanico", "espiao", "omega", "titan", "spectre"])
	app.start_single(); app.sim.start_run(1941); app.sim.keys = 4; app.sim.money = 36; app.sim.materials = 12
	app.sim.mech.fuel = app.sim.FUEL_MAX * 0.74; app.sim.spectres[0].hp = 83
	app.menu.open("mission_inventory")
	await process_frame; await process_frame; await process_frame
	var mission_image := viewport.get_texture().get_image()
	var mission_error := mission_image.save_png("res://test-output/menu-inventario-missao-final.png")
	print("INVENTORY_PREVIEW_SAVED preparation=", error, " mission=", mission_error, " size=", mission_image.get_size())
	app.queue_free(); quit(0 if error == OK and mission_error == OK else 1)

