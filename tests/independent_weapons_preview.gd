extends SceneTree

class Preview extends DockView:
	var form := "padrao"
	var moment := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0,0,1440,620), Color("202b38"))
		for row in 3:
			for col in 8:
				var a: Dictionary = sim.actors[0].duplicate(true)
				a.p = Vector2(95+col*177,170+row*195)
				a.outfit = form if form in ["padrao","mecanico","espiao"] else "padrao"
				a.armor = form == "omega"; a.fused = form == "fusion"
				a.aim = Vector2.DOWN.rotated(-col*PI/4); a.facing = a.aim
				a.run_weapons = {"bazooka":6}; a.run_weapon = "bazooka" if row == 2 else ""
				a.move = -a.aim if row == 1 else Vector2.ZERO; a.step = moment*8
				a.fire_flash = 0.08 if row == 2 else 0.0
				if form == "transform":
					a.armor = true; a.aim = Vector2.DOWN; a.facing = a.aim; a.transform = sim.TRANSFORM_TIME*(1.0-(col+0.5)/8.0)
					if row == 2 and col == 7: a.transform = 0; a.run_weapon = ""; a.aim = Vector2.DOWN
				visual_scale = sim.ACTOR_VISUAL_SCALE; visual_origin = a.p; visual_transform(Vector2.ZERO)
				draw_actor(a)
				visual_scale = 1; visual_origin = Vector2.ZERO; visual_transform(Vector2.ZERO)

func _initialize() -> void: run.call_deferred()
func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	var viewport := SubViewport.new(); viewport.size = Vector2i(1440,620)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
	var view := Preview.new(); view.sim = Expedition.new(); view.sim.make_hub(); viewport.add_child(view)
	DirAccess.make_dir_recursive_absolute("res://test-output/independent-weapons")
	for form in ["padrao","mecanico","espiao","omega","fusion","transform"]:
		view.form = form
		for frame in 4:
			view.moment = frame*0.125; view.sim.tick_time = view.moment; view.queue_redraw()
			await process_frame; await process_frame; RenderingServer.force_draw(false)
			var path := "res://test-output/independent-weapons/%s-%d.png" % [form,frame]
			assert(viewport.get_texture().get_image().save_png(path) == OK)
	print("INDEPENDENT_WEAPONS_PREVIEW: 24 renderer captures saved")
	view.queue_free(); await process_frame
	viewport.size = Vector2i(1440,810)
	var app = load("res://scenes/main.tscn").instantiate(); viewport.add_child(app)
	await process_frame; await process_frame
	app.start_single(); app.set_physics_process(false); app.set_process(false)
	app.sim.grant_run_weapon(app.sim.actors[0],"bazooka",6)
	app.menu.open("pause"); app.menu.read_equipment(); app.menu.show_screen("mission_inventory")
	await process_frame; await process_frame
	app.menu.equipment.show_tab(4)
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	assert(viewport.get_texture().get_image().save_png("res://test-output/independent-weapons/equipment.png") == OK)
	quit()
