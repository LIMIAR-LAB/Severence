extends SceneTree

class PosePreview extends DockView:
	var rolling := false
	func _draw() -> void:
		for row in 3:
			for col in 8:
				var a: Dictionary = sim.actors[0].duplicate(true)
				a.p = Vector2(90 + col * 155, 145 + row * 180)
				a.aim = Vector2.DOWN.rotated(-col * PI / 4); a.facing = a.aim; a.dash_dir = a.aim
				a.run_weapons = {"bazooka": 0}; a.run_weapon = "bazooka" if row > 0 else ""
				a.fire_flash = 0.09 if row < 2 else 0.0
				if row == 2: a.move = -a.aim; a.facing = -a.aim
				if rolling:
					a.run_weapon = ""; a.fire_flash = 0; a.hurt = 0.2
					a.dodge = maxf(0, 0.2 - row * 0.12); a.roll_visual = 0.36 - row * 0.12
				visual_scale = sim.ACTOR_VISUAL_SCALE; visual_origin = a.p; visual_transform(Vector2.ZERO)
				draw_actor(a)
				visual_scale = 1.0; visual_origin = Vector2.ZERO; visual_transform(Vector2.ZERO)
				if not rolling and row < 2:
					var geometry: Dictionary = sim.weapon_geometry(a)
					var point: Vector2 = geometry.ground - Vector2(0, geometry.height)
					draw_circle(point, 3, Color.MAGENTA)

func _initialize() -> void: run.call_deferred()
func save(viewport: Viewport, name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://test-output/" + name + ".png")
func run() -> void:
	var viewport := SubViewport.new(); viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
	var app = load("res://scenes/main.tscn").instantiate(); viewport.add_child(app)
	await process_frame; await process_frame
	app.start_single(); app.sim.make_hub(); app.set_physics_process(false); app.set_process(false)
	for size in [Vector2i(1920,1080), Vector2i(960,720)]:
		viewport.size = size; app.menu.open("pause")
		await save(viewport, "bugfix-pause-%d" % size.x)
		app.sim.grant_run_weapon(app.sim.actors[0], "bazooka", 0)
		app.menu.read_equipment(); app.menu.show_screen("mission_inventory")
		app.menu.equipment.find_child("InventorySlot_missao_bazuca", true, false).grab_focus()
		await save(viewport, "bugfix-inventory-%d" % size.x)
		app.menu.equipment.show_comparison()
		await save(viewport, "bugfix-comparison-%d" % size.x)
	app.queue_free(); await process_frame
	viewport.size = Vector2i(1280, 640)
	var poses := PosePreview.new(); poses.sim = Expedition.new(); poses.sim.make_hub(); viewport.add_child(poses)
	await save(viewport, "bugfix-muzzles-empty")
	poses.rolling = true; poses.queue_redraw(); await save(viewport, "bugfix-roll-sequence")
	quit()
