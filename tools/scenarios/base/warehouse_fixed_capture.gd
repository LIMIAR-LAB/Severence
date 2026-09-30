extends SceneTree
const View = preload("res://scripts/world_view.gd")
var output := "res://_bmad-output/implementation-artifacts/cenarios-base/captures/warehouse-fixed-v01/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	root.size=Vector2i(1280,800)
	var sim := Expedition.new()
	var requested_seed := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): requested_seed=int(arg.trim_prefix("--seed="))
	var saved: Variant = FileAccess.open("user://expedition.save",FileAccess.READ).get_var(false)
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
	var probes := [{"id":"warehouse-main","p":Vector2(5520,6480)},{"id":"warehouse-cargo","p":Vector2(5350,6520)},{"id":"warehouse-cranes-join","p":Vector2(4710,6500)},{"id":"warehouse-east","p":Vector2(6300,6510)},{"id":"warehouse-titan","p":Vector2(5520,6480)}]
	DirAccess.make_dir_recursive_absolute(output)
	for probe in probes:
		pass
		sim.actors[0].p=probe.p; sim.mech.deployed=probe.id.ends_with("titan")
		sim.actors[0].mech=sim.mech.deployed; sim.mech.occupant=0 if sim.mech.deployed else -1; sim.mech.p=probe.p
		sim.room_by_id("stairs")["locked"] = probe.id=="farol-south"
		camera.position=probe.p; camera.force_update_scroll()
		await process_frame; view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+probe.id+".png")
	FileAccess.open(output+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"seed":sim.seed_value,"zoom":1.05,"probes":str(probes),"save_read_only":true},"  "))
	print("JUNCTION_CAPTURE_DONE ",output); quit()




