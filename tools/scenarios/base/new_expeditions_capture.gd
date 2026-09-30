extends SceneTree
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
const Cleanup = preload("res://tests/support/scene_cleanup.gd")
var output := "res://_bmad-output/implementation-artifacts/cenarios-base/captures/variation-before/"
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	var backups := {}
	for path in ["user://settings.json","user://progress.json","user://expedition.save"]:
		backups[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	var records := []
	for index in 2:
		var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
		await process_frame
		app.screenshot_mode = true
		app.demo_ticks = -100000
		for button_name in ["Title_1","CharacterMarty","SoloChoice","Refuge"]:
			var button = app.menu.content.find_child(button_name,true,false)
			check(button != null,"normal menu button "+button_name)
			if button == null: break
			button.pressed.emit(); await process_frame
		check(app.sim.mode=="hub","normal flow reaches refuge")
		app.sim.actors[0].p = Vector2(655,215)
		app.sim.interact(app.sim.actors[0])
		check(app.sim.mode=="run","portal starts expedition")
		check(not app.sim.layout_manifest.has("fallback"),"portal uses procedural layout")
		app.set_process(false)
		var layout: Dictionary = app.sim.layout_manifest.duplicate(true)
		var start: int = app.sim.nav.get_closest_point(app.sim.actors[0].p)
		var target: int = app.sim.nav.get_closest_point(app.sim.room_by_id("boss").r.get_center())
		var reachable: bool = not app.sim.nav.get_id_path(start,target).is_empty()
		check(reachable,"normal run reaches boss")
		for room in app.sim.rooms: app.sim.visited.append(room.id); app.world.scenery.reveal_at[room.id]=-1.0
		app.map_open=true; app.update_hud(); app.world.queue_redraw()
		app.camera.position=app.sim.actors[0].p; app.camera.force_update_scroll()
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"run-%d.png"%index)
		check(app.save_game(),"save generated run")
		check(app.load_game(),"continue generated run")
		check(app.sim.layout_manifest==layout,"continue preserves layout exactly")
		# A collision-driven walkthrough in test mode, with encounters cleared.
		# This traverses every path segment; it never teleports between rooms.
		app.sim.enemies.clear(); app.sim.step_gates(); app.sim.build_navigation()
		var waypoints: PackedVector2Array = app.sim.nav.get_point_path(app.sim.nav.get_closest_point(app.sim.actors[0].p),app.sim.nav.get_closest_point(app.sim.room_by_id("boss").r.get_center()))
		var walked := 0.0
		for point in waypoints:
			for tick in 20:
				var delta: Vector2 = point-app.sim.actors[0].p
				if delta.length()<0.1: break
				var position: Vector2 = app.sim.move_body(app.sim.actors[0].p,delta.limit_length(8),11)
				walked += position.distance_to(app.sim.actors[0].p)
				app.sim.actors[0].p = position
			check(app.sim.actors[0].p.distance_to(point)<0.1,"walkthrough reaches waypoint "+str(point))
		var walked_to_boss: bool = app.sim.room_contains(app.sim.room_by_id("boss"),app.sim.actors[0].p)
		check(walked_to_boss,"collision walkthrough reaches boss")
		records.append({"seed":app.sim.seed_value,"hash":Seeds.canonical(layout).sha256_text(),"origins":str(app.sim.room_offsets),"edges":layout.get("edges",[]).map(func(edge):return edge.id),"fallback":layout.get("fallback",""),"boss_reachable":reachable,"walked_to_boss":walked_to_boss,"walked_distance":walked,"save_restored":app.sim.layout_manifest==layout})
		await Cleanup.finish(self)
	check(records.size()==2 and records[0].seed!=records[1].seed,"two new runs choose different seeds")
	FileAccess.open(output+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"runs":records},"  "))
	for path in backups:
		if backups[path]==null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else: FileAccess.open(path,FileAccess.WRITE).store_buffer(backups[path])
	print("NEW_EXPEDITIONS_TESTS_DONE failures=",failures)
	quit(1 if failures else 0)
