extends SceneTree
const OUTPUT := "C:/Users/tsmar/OneDrive/Documentos/ChatGPT/Jogo Steam/output/discovery-mist/captures"
var app
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	run.call_deferred()
func shot(label: String) -> void:
	app.camera.position=app.sim.actors[0].p
	app.camera.reset_smoothing()
	app.camera.force_update_scroll()
	app.update_hud(); app.world.queue_redraw()
	for frame in range(5):
		app.world.queue_redraw()
		await process_frame
	print(label," mode=",app.sim.mode," view=",app.world.view_rect()," p=",app.sim.actors[0].p," floor=",app.sim.floors.filter(func(f):return f.has_point(app.sim.actors[0].p))," visible=",app.world.vis_floors)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+"/"+label+".png")
func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/SeverenceTests/"): quit(1); return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size=Vector2i(1600,1000)
	app=preload("res://scripts/main.gd").new(); root.add_child(app)
	app.set_process(false); app.set_physics_process(false); app.screenshot_mode=true
	app.sim.procedural_enabled=true; app.sim.coop="solo"; app.sim.start_run(1941)
	app.playing=true; app.paused=false; app.menu.visible=false
	app.sim.actors[1].active=false; app.sim.visited=["entry"]; app.sim.tick_time=3
	app.sim.message_time=0; app.camera.zoom=Vector2.ONE*1.15
	for room in app.sim.rooms: app.world.scenery.reveal_at[room.id]=-100.0
	print("ROUTES ",app.sim.run_corridors)
	app.display.ui_scale=1; app.display.apply(self)
	var prefix: String="before" if "before" in OS.get_cmdline_user_args() else "after"
	app.sim.actors[0].p=Vector2(1000,5740)
	await shot(prefix+"-north-unknown")
	app.sim.actors[0].p=Vector2(1000,5500)
	await shot(prefix+"-north-frontier")
	app.sim.visited.append("chapel"); app.sim.tick_time=3.4
	app.world.scenery.reveal_at["chapel"]=3.0
	await shot(prefix+"-north-reveal")
	app.sim.tick_time=6
	await shot(prefix+"-north-known")
	app.sim.visited=["entry"]; app.sim.actors[0].p=Vector2(2350,6500)
	await shot(prefix+"-east-unknown")
	app.queue_free(); await process_frame; quit()
