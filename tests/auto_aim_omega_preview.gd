extends SceneTree
const OUTPUT := "C:/Users/tsmar/OneDrive/Documentos/ChatGPT/Jogo Steam/output/auto-aim-omega/captures"
var app
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	run.call_deferred()
func shot(name: String) -> void:
	app.world.queue_redraw()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")
	print("CAPTURE_SAVED ", name)
func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/SeverenceTests/"): quit(1); return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size = Vector2i(1600,1000)
	app = preload("res://scripts/main.gd").new(); root.add_child(app)
	app.set_process(false); app.set_physics_process(false); app.screenshot_mode = true
	app.sim.procedural_enabled = false; app.sim.start_run(1941)
	app.playing = true; app.paused = false; app.menu.visible = false
	app.sim.coop = "solo"; app.sim.actors[1].active = false
	app.sim.actors[0].p = app.sim.room_by_id("entry").r.get_center()
	app.sim.visited.append("entry"); app.sim.tick_time = 3.0
	for room in app.sim.rooms: app.world.scenery.reveal_at[room.id] = -100.0
	app.camera.position = app.sim.actors[0].p; app.camera.zoom = Vector2.ONE * 1.0
	app.display.ui_scale = 1.0; app.display.apply(self)

	app.sim.enemies.clear(); app.sim.bullets.clear(); app.sim.pickups.clear(); app.sim.message_time = 0
	var a: Dictionary = app.sim.actors[0]
	app.camera.zoom = Vector2.ONE * 1.65
	for weapon in ["mosquete", "tesla", "arpoador"]:
		a.run_weapons[weapon] = app.sim.RESCUE_NPCS[["mosquete","tesla","arpoador"].find(weapon)].ammo
		a.run_weapon = weapon; a.aim = Vector2.RIGHT; a.facing = Vector2.RIGHT
		app.sim.pickups = [{"p":a.p+Vector2(140,60),"kind":"weapon","weapon":weapon,"ammo":30}]
		app.sim.fire_actor(a); app.sim.bullets.clear(); app.update_hud()
		await shot(weapon + "-hd")
		a.slash = 0.2; await shot(weapon + "-melee"); a.slash = 0
	app.sim.pickups.clear(); app.sim.set_armor(a,true); a.transform = 0; a.armor_time = 300; a.run_weapon = ""; app.sim.message_time = 0; app.sim.effects.clear()
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2(-1,-1).normalized()]:
		a.aim = direction; a.facing = direction; a.combo = 2; a.combo_t = 1
		app.sim.bullets.clear(); app.sim.fire_actor(a)
		app.sim.bullets[-1].p += direction * 110
		app.update_hud(); await shot("omega-energy-" + str(int(direction.angle()*100)))
	app.camera.zoom = Vector2.ONE; app.update_hud(); await shot("omega-energy-normal-scale")
	a.slash = 0; await shot("omega-idle-weapon")
	app.auto_aim=true; app.menu.visible=true; app.menu.options_tab="controls"; app.menu.open_options("pause")
	await shot("controls-auto-aim")
	app.queue_free(); await process_frame; await create_timer(0.2).timeout; quit()
