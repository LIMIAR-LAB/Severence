extends SceneTree
var output := "res://output/passage-gate/captures"
var capture_failed := false
var app
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate(); run.call_deferred()
func shot(label: String) -> void:
	app.camera.position=app.sim.actors[0].p; app.camera.reset_smoothing(); app.camera.force_update_scroll(); app.update_hud()
	for frame in 5: app.world.queue_redraw(); await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output+"/"+label+".png") != OK:
		capture_failed=true; push_error("Cannot save capture: "+label)
func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/SeverenceTests/"): quit(1); return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	output=ProjectSettings.globalize_path(output)
	if DirAccess.make_dir_recursive_absolute(output) != OK: quit(1); return
	root.size=Vector2i(1600,1000)
	app=preload("res://scripts/main.gd").new(); root.add_child(app)
	app.set_process(false); app.set_physics_process(false); app.screenshot_mode=true
	app.sim.procedural_enabled=true; app.sim.coop="solo"; app.sim.start_run(1941)
	app.playing=true; app.paused=false; app.menu.visible=false; app.sim.actors[1].active=false
	app.sim.visited=["chapel"]; app.sim.tick_time=5; app.sim.message_time=0
	for room in app.sim.rooms: app.world.scenery.reveal_at[room.id]=-100; room.locked=false
	app.sim.refresh_gate_blocks(); app.sim.actors[0].p=Vector2(1660,4370)
	app.camera.zoom=Vector2.ONE*1.2; app.display.ui_scale=1; app.display.apply(self)
	var prefix: String="before" if "before" in OS.get_cmdline_user_args() else "after"
	await shot(prefix+"-chapel-east-unknown")
	app.sim.room_by_id("stairs").locked=true; app.sim.refresh_gate_blocks()
	await shot(prefix+"-gate-closed")
	app.sim.visited.append("stairs"); app.world.scenery.reveal_at["stairs"]=-100
	await shot(prefix+"-gate-closed-known")
	app.sim.room_by_id("stairs").locked=false; app.sim.visited.append("stairs"); app.sim.refresh_gate_blocks()
	app.world.scenery.reveal_at["stairs"]=-100
	await shot(prefix+"-gate-open-known")
	var horizontal_captured:=false
	for door in app.sim.doors:
		if door.r.size.x<=door.r.size.y or not app.sim.RemainingFixed.owns(app.sim,door.room): continue
		app.sim.visited.append(door.room); app.world.scenery.reveal_at[door.room]=-100
		app.sim.room_by_id(door.room).locked=true; app.sim.refresh_gate_blocks()
		app.sim.actors[0].p=door.r.get_center()+Vector2(0,80)
		await shot(prefix+"-gate-horizontal-closed"); horizontal_captured=true; break
	app.queue_free(); await process_frame; quit(1 if capture_failed or not horizontal_captured else 0)
