extends SceneTree
const OUTPUT := "C:/Users/tsmar/OneDrive/Documentos/ChatGPT/Jogo Steam/output/review-improvements/presentation"
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
	app.sim.say("Marty: quatro sinais perdidos. O núcleo das Docas pode mostrar por onde começar. As pistas ficam no diário.")
	app.update_hud(); await shot("hud-normal-dialogue")
	app.display.ui_scale = 1.3; app.display.apply(self)
	await process_frame; app.update_hud(); await shot("hud-enlarged-dialogue")
	app.sim.message_time = 0; app.update_hud(); await shot("hud-enlarged-combat")
	app.menu.open("missions"); await process_frame; await process_frame
	app.menu.focus_first(); await shot("journal")
	var entries: Array = app.menu.content.find_children("JournalEntry*", "PanelContainer", true, false)
	if not entries.is_empty(): entries.back().grab_focus()
	await shot("journal-scrolled")
	app.menu.options_tab = "video"; app.menu.open("options"); await shot("options-video")
	app.menu.options_tab = "audio"; app.menu.show_screen("options"); await shot("options-audio")
	app.menu.visible = false; app.paused = false; app.sim.message_time = 0
	app.display.ui_scale = 1.0; app.display.apply(self)
	app.sim.enemies.clear(); app.sim.bullets.clear()
	for i in range(5):
		app.sim.bullets.append({"p":app.camera.position + Vector2((i-2)*110, -80), "v":Vector2(400,0).rotated(i*0.35), "r":7.0, "kind":["harpoon","acid","flame","orb","magenta"][i], "team":1,"life":2.0})
	app.update_hud(); app.world.queue_redraw(); await shot("projectile-silhouettes")
	app.queue_free(); await process_frame; await create_timer(0.2).timeout
	quit()
