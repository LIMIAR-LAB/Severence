extends SceneTree
const View = preload("res://scripts/world_view.gd")
var output := "res://_bmad-output/implementation-artifacts/cenarios-base/captures/corridor-before/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	root.size=Vector2i(1280,800)
	var sim := Expedition.new()
	var requested_seed := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): requested_seed=int(arg.trim_prefix("--seed="))
	var saved: Variant = null
	if requested_seed<0 and FileAccess.file_exists("user://expedition.save"):
		saved=FileAccess.open("user://expedition.save",FileAccess.READ).get_var(false)
	if requested_seed>=0:
		sim.procedural_enabled=true; sim.start_run(requested_seed)
	elif saved is Dictionary and saved.get("state",{}).get("mode")=="run":
		sim.apply_snapshot(saved.state.duplicate(true)); sim.ob_grid_count=-1; sim.build_navigation()
	else: sim.procedural_enabled=true; sim.start_run(1941)
	print("INSPECTED_SAVE seed=",sim.seed_value," actor=",sim.actors[0].p," layout=",sim.layout_manifest.get("version","legacy"))
	sim.enemies.clear(); sim.effects.clear(); sim.bullets.clear(); sim.actors[1].active=false
	sim.actors[0].armor=false; sim.actors[0].fused=false; sim.actors[0].mech=false; sim.actors[0].jump=0
	var view := View.new(); view.sim=sim; root.add_child(view)
	for room in sim.rooms: sim.visited.append(room.id); view.scenery.reveal_at[room.id]=-1.0
	var camera := Camera2D.new(); root.add_child(camera); camera.zoom=Vector2.ONE*1.05
	var origin: Vector2 = sim.room_by_id("stairs").r.position
	var probes := [{"id":"dock-sanctuary","p":Vector2(1000,5740)},{"id":"sanctuary-farol","p":Vector2(1730,4340)},{"id":"cranes-north","p":Vector2(3970,5650)},{"id":"cranes-warehouse","p":Vector2(4700,6490)}]
	if "--all" in OS.get_cmdline_user_args():
		probes.clear()
		sim.open_secret()
		var routes: Array=sim.run_corridors.duplicate()
		routes.append_array(sim.run_secret_floors)
		for shortcut in sim.DOCKS.SHORTCUTS: routes.append(shortcut.r)
		for i in range(sim.obstacles.size()-1,-1,-1):
			if sim.obstacle_kinds[i].begins_with("wall_crack_"): sim.open_shortcut(i)
		for i in routes.size():
			var r: Rect2=routes[i]
			var count:=maxi(1,ceili(maxf(r.size.x,r.size.y)/650.0))
			for j in count:
				var p:=r.get_center()
				if r.size.x>r.size.y: p.x=r.position.x+r.size.x*(j+0.5)/count
				else: p.y=r.position.y+r.size.y*(j+0.5)/count
				probes.append({"id":"route-%02d-%02d"%[i,j],"p":p})
	if "--merchant" in OS.get_cmdline_user_args(): probes.append({"id":"merchant","p":sim.run_points.shop+Vector2(0,100)})
	var sheet:=Image.create(1280,ceili(probes.size()/4.0)*200,false,Image.FORMAT_RGB8)
	var capture_index:=0
	DirAccess.make_dir_recursive_absolute(output)
	for probe in probes:
		pass
		sim.actors[0].p=probe.p; sim.mech.deployed=probe.id.ends_with("titan")
		sim.actors[0].mech=sim.mech.deployed; sim.mech.occupant=0 if sim.mech.deployed else -1; sim.mech.p=probe.p
		sim.room_by_id("stairs")["locked"] = probe.id=="farol-south"
		camera.position=probe.p; camera.force_update_scroll()
		await process_frame; view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		var captured:=root.get_texture().get_image()
		captured.save_png(output+probe.id+".png")
		captured.resize(320,200)
		captured.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(captured,Rect2i(0,0,320,200),Vector2i((capture_index%4)*320,(capture_index/4)*200))
		capture_index+=1
	sheet.save_png(output+"overview.png")
	FileAccess.open(output+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"seed":sim.seed_value,"zoom":1.05,"probes":str(probes),"save_read_only":true},"  "))
	print("JUNCTION_CAPTURE_DONE ",output); quit()




