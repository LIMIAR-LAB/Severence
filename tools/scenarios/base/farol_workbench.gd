extends SceneTree
## Isolated playable inspection; does not load saves or the main menu.
const Module = preload("res://scripts/scenarios/farol_module.gd")
const View = preload("res://scripts/scenarios/room_preview.gd")
const Biomes = preload("res://scripts/scenarios/biome_catalog.gd")
const Connections = preload("res://scripts/scenarios/farol_connections.gd")
const OUTPUT := "res://_bmad-output/implementation-artifacts/cenarios-base/captures/farol/"
var sim: Expedition
var view: Node2D
var camera: Camera2D
var label: Label
var origin := Vector2(1800,3700)
var capturing := false
var interaction_down := false
var connections := false

func _initialize() -> void:
	call_deferred("open")

func open() -> void:
	capturing = "--capture" in OS.get_cmdline_user_args()
	connections = "--connections" in OS.get_cmdline_user_args()
	sim = Expedition.new(); sim.coop = "solo"; sim.start_run(1941)
	view = View.new(); view.sim = sim; view.profile = Biomes.profile("docks")
	root.add_child(view)
	camera = Camera2D.new(); camera.zoom = Vector2(0.7,0.7); root.add_child(camera)
	var ui := CanvasLayer.new(); root.add_child(ui)
	label = Label.new(); label.position = Vector2(18,12); ui.add_child(label)
	if not install_at(origin): quit(1); return
	if capturing:
		DirAccess.make_dir_recursive_absolute(OUTPUT)
		var records := []
		for offset in [Vector2(1800,3700),Vector2(400,-500)]:
			if not install_at(offset): quit(1); return
			var probes := [{"id":"west","p":Vector2(340,480)},{"id":"landing","p":Vector2(850,480)},{"id":"east","p":Vector2(1360,480)},{"id":"front","p":Vector2(850,695)}]
			if connections:
				probes = []
				for join in view.instance.joins: probes.append({"id":"join-"+join.side,"p":join.position-origin})
			for probe in probes:
				if connections: camera.position = origin+probe.p; camera.zoom = Vector2(1.22,1.22)
				for performer in ["marty","titan"]:
					sim.actors[0].active = performer == "marty"
					sim.actors[0].p = origin + probe.p
					sim.mech.p = origin + probe.p; sim.mech.deployed = performer == "titan"
					camera.force_update_scroll()
					await process_frame
					view.queue_redraw()
					await process_frame
					await RenderingServer.frame_post_draw
					var name: String = str(int(origin.x))+"-"+probe.id+"-"+performer+".png"
					var result := root.get_texture().get_image().save_png(OUTPUT+name)
					records.append({"file":name,"origin":str(origin),"actor":str(sim.actors[0].p),"height":sim.height_at(sim.actors[0].p),"error":result})
		var file := FileAccess.open(OUTPUT+("connections.json" if connections else "captures.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(records,"  "))
		print("FAROL_CAPTURE_DONE ",records.size())
		quit()

func install_at(at: Vector2) -> bool:
	# Recreate legacy source before materializing another translated instance.
	sim.start_run(1941)
	var instance := Connections.assemble(sim,at) if connections else Module.instantiate(sim,at)
	if not instance.ok: push_error(str(instance.errors)); return false
	origin = at; Module.install(sim,instance); view.instance = instance
	camera.position = origin + Vector2(850,450)
	camera.force_update_scroll()
	label.text = "Farol | piloto isolado | setas: mover | Shift: dash/turbo | espaco: salto | E: Titan\nMarty + Titan | pecas nativas 1:1 | origem " + str(origin)
	if not capturing:
		sim.mech.deployed = true; sim.mech.p = sim.actors[0].p + Vector2(65,0)
	view.queue_redraw()
	return true

func _process(delta: float) -> bool:
	if not sim or capturing: return false
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_UP))).normalized()
	var a: Dictionary = sim.actors[0]
	var pressed := Input.is_physical_key_pressed(KEY_E)
	if pressed and not interaction_down: sim.interact(a)
	interaction_down = pressed
	sim.step_actor(a,{"move":direction,"jump":Input.is_physical_key_pressed(KEY_SPACE),"dodge":Input.is_physical_key_pressed(KEY_SHIFT),"boost":Input.is_physical_key_pressed(KEY_SHIFT)},minf(delta,0.05))
	if connections: camera.position = a.p; camera.zoom = Vector2(1.22,1.22)
	view.queue_redraw()
	return false
