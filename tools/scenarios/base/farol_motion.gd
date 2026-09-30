extends "res://tools/scenarios/base/farol_workbench.gd"
## Continuous rendered traversal, with a floor aperture probe on every frame.
var runtime_mode := false

func install_at(at: Vector2) -> bool:
	if not runtime_mode: return super.install_at(at)
	sim.start_run(1941); origin = at
	for room in sim.rooms:
		sim.visited.append(room.id); view.scenery.reveal_at[room.id] = -1.0
	return sim.scenario_modules.has("stairs")

func open() -> void:
	runtime_mode = "--runtime" in OS.get_cmdline_user_args()
	await super.open()
	capturing = true
	if runtime_mode:
		view.free(); view = load("res://scripts/world_view.gd").new(); view.sim = sim; root.add_child(view)
	var output := OUTPUT+("runtime-motion/" if runtime_mode else "motion/")
	DirAccess.make_dir_recursive_absolute(output)
	var records := []; var failures := 0
	for at in ([Vector2(1800,3700)] if runtime_mode else [Vector2(1800,3700),Vector2(400,-500)]):
		if not install_at(at): quit(1); return
		sim.mech.deployed = false
		var assembly: Dictionary = sim.scenario_modules.stairs if runtime_mode else view.instance
		for join in assembly.joins:
			var actor: Dictionary = sim.actors[0]
			actor.p = join.position+join.normal*140; actor.move = Vector2.ZERO
			var misses := 0; var sampled := 0; var files := []
			for frame in 81:
				if frame > 0: sim.step_actor(actor,{"move":-join.normal,"aim":-join.normal},0.016)
				camera.position = actor.p; camera.zoom = Vector2(1.22,1.22); camera.force_update_scroll()
				await process_frame
				view.queue_redraw()
				await RenderingServer.frame_post_draw
				var screenshot := root.get_texture().get_image()
				var tangent := Vector2(-join.normal.y,join.normal.x)
				var extent: float = 42 if join.side=="shortcut" else 75
				for along in [-extent,-extent*0.66,extent*0.66,extent]:
					for across in [-2,0,2]:
						var world: Vector2 = join.position+tangent*along+join.normal*across
						var pixel: Vector2i = Vector2i(view.get_canvas_transform()*world)
						if not Rect2i(Vector2i.ZERO,screenshot.get_size()).has_point(pixel): continue
						var color := screenshot.get_pixelv(pixel)
						sampled += 1
						var background := Color("101821") * (Color("bdc7f5") if runtime_mode else Color(view.profile.atmosphere.tint))
						if absf(color.r-background.r)<0.004 and absf(color.g-background.g)<0.004 and absf(color.b-background.b)<0.004: misses += 1
				if frame % 20 == 0:
					var name := "%d-%s-%03d.png" % [at.x,join.side,frame]
					screenshot.save_png(output+name); files.append(name)
			var traversed: bool = (actor.p-join.position).dot(join.normal)<-100
			if misses>0 or not traversed: failures += 1
			records.append({"origin":str(at),"side":join.side,"frames":81,"floor_samples":sampled,"background_samples":misses,"crossed":traversed,"captures":files})
	var file := FileAccess.open(output+"report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"traversals":records,"scope":"Rendered real actor movement, camera follows at1.22; probes inside useful aperture; static geometry is tested separately."},"  "))
	print("FAROL_MOTION_DONE failures=",failures)
	quit(1 if failures else 0)
