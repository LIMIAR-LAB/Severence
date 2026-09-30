extends SceneTree

# Reproducible render check without changing the player's save or settings.
func _initialize() -> void:
	call_deferred("capture_blue")

func capture_blue() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.set_physics_process(false)
	app.screenshot_mode = true
	root.size = Vector2i(1280, 800)
	app.start_single()
	app.sim.enemies.clear()
	app.sim.effects.clear()
	app.sim.bullets.clear()
	app.sim.mech.deployed = false
	var actor: Dictionary = app.sim.actors[0]
	actor.p = Vector2(515, 535)
	actor.armor_type = "azul"
	app.sim.set_armor(actor, true)
	actor.transform = 0.0
	actor.armor_time = 300.0
	actor.aim = Vector2(1, 0.8).normalized()
	actor.facing = actor.aim
	app.sim.effects.clear()
	app.sim.visible_world_rect = Rect2(0, 0, 1280, 900)
	app.sim.spawn_enemy(Vector2(725, 535), "brute")
	app.sim.enemies[0].hp = 500
	app.sim.enemies[0].max = 500
	app.sim.spawn_enemy(Vector2(970, 595), "cult")
	app.sim.ground_claw(actor)
	# Same-scene art check: original Marty beside the blue transformation.
	var reference: Dictionary = app.sim.actors[1]
	reference.active = true; reference.dead = false; reference.armor = false
	reference.outfit = "padrao"; reference.p = Vector2(400, 535)
	reference.aim = actor.aim; reference.facing = actor.facing
	for effect in app.sim.effects:
		if effect.kind == "ground_claw": effect.life = 0.43
	app.sim.tick_time = 1.7
	app.camera.position = Vector2(660, 460)
	app.camera.zoom = Vector2(1.05, 1.05)
	app.camera.reset_smoothing()
	app.world.queue_redraw()
	app.update_hud()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/blue-form")
	var result := root.get_texture().get_image().save_png("res://test-output/blue-form/style-comparison.png")
	print("BLUE_FORM_CAPTURE ", result)
	app.queue_free()
	await process_frame
	quit(result)
