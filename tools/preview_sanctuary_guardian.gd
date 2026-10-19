extends SceneTree
const View=preload("res://scripts/world_view.gd")
const Guardian=preload("res://scripts/sanctuary_guardian_visuals.gd")
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(720,620); root.content_scale_size=root.size
	var sim:=Expedition.new(); sim.start_run(1941); sim.enemies.clear(); sim.actors[1].active=false
	var position:=sim.story_npc_position()
	sim.actors[0].p=position+Vector2(90,65)
	var view:=View.new(); view.sim=sim; root.add_child(view)
	for room in sim.rooms: sim.visited.append(room.id); view.scenery.reveal_at[room.id]=-1.0
	var camera:=Camera2D.new(); root.add_child(camera); camera.zoom=Vector2.ONE*1.7
	camera.position=position+Vector2(0,-60); camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute("res://output/sanctuary-guardian")
	var animated := "--animated" in OS.get_cmdline_user_args()
	var frame_count := 72 if animated else 4
	for i in frame_count:
		sim.tick_time=float(i)*Guardian.PERIOD/frame_count; view.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		var filename := "idle-%02d.png"%i if animated else "pose-%d.png"%i
		root.get_texture().get_image().save_png("res://output/sanctuary-guardian/"+filename)
	print("SANCTUARY_GUARDIAN loaded=",view.sanctuary_guardian_visuals.texture!=null)
	quit(0 if view.sanctuary_guardian_visuals.texture!=null else 1)
