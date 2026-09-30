extends SceneTree
const View = preload("res://scripts/world_view.gd")
const OUTPUT := "res://_bmad-output/implementation-artifacts/cenarios-base/captures/farol/runtime/"
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var sim := Expedition.new(); sim.coop = "solo"; sim.start_run(1941)
	if not sim.scenario_modules.has("stairs"): push_error("published module missing"); quit(1); return
	var view := View.new(); view.sim = sim; root.add_child(view)
	for room in sim.rooms:
		sim.visited.append(room.id); view.scenery.reveal_at[room.id] = -1.0
	sim.actors[1].active = false
	var camera := Camera2D.new(); root.add_child(camera)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var records := []
	for probe in [{"id":"room","p":Vector2(2650,4350),"zoom":0.52},{"id":"west","p":Vector2(1800,4300),"zoom":1.22},{"id":"east","p":Vector2(3500,4300),"zoom":1.22},{"id":"north","p":Vector2(3400,3700),"zoom":1.22},{"id":"landing","p":Vector2(2650,4180),"zoom":1.22}]:
		sim.actors[0].p = probe.p
		var offset: Vector2 = Vector2(-60,75) if probe.id=="north" else (Vector2(-70,80) if probe.id=="east" else Vector2(70,80))
		sim.mech.p = probe.p+offset; sim.mech.deployed = true
		camera.position = probe.p; camera.zoom = Vector2.ONE*probe.zoom; camera.force_update_scroll()
		await process_frame; view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(OUTPUT+probe.id+".png")
		records.append({"id":probe.id,"error":result,"zoom":probe.zoom,"actor":str(probe.p)})
	var file := FileAccess.open(OUTPUT+"report.json",FileAccess.WRITE); file.store_string(JSON.stringify(records,"  "))
	print("FAROL_RUNTIME_CAPTURE_DONE")
	quit()
