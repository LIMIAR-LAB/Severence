extends SceneTree
## Separate entry point: never loads main, settings, progress, or networking.
const Baseline = preload("res://scripts/scenarios/baseline.gd")
const View = preload("res://tools/scenarios/base/inspection_view.gd")
const RoomView = preload("res://scripts/scenarios/room_preview.gd")
const Contract = preload("res://scripts/scenarios/room_contract.gd")
const Biomes = preload("res://scripts/scenarios/biome_catalog.gd")
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
const Display = preload("res://scripts/display_settings.gd")
const Metrics = preload("res://scripts/scenarios/inspection_metrics.gd")
var sim: Expedition
var view: DockView
var camera: Camera2D
var overlay: GeometryOverlay
var label: Label
var room_id := "stairs"
var selected: Dictionary
var capture := false
var contract_mode := false
var profile_id := "docks"
var inspection := false
var input_host: InputHost
var actor_preset := false
var fit_camera := true

class InputHost extends Node:
	var host
	func _unhandled_input(event: InputEvent) -> void: host.handle_input(event)

class GeometryOverlay extends Node2D:
	var sim: Expedition
	var selected: Dictionary
	func _draw() -> void:
		if selected.is_empty(): return
		var room: Dictionary = selected.room
		for rect in [room.r] + room.get("extra", []): draw_rect(rect, Color.CYAN, false, 3)
		for box in sim.obstacles:
			if box.intersects(selected.bounds): draw_rect(box, Color(1, 0.25, 0.1, 0.6), false, 2)
		for ramp in sim.ramps: draw_rect(ramp.r, Color.YELLOW, false, 3)
		for door in sim.doors:
			if door.room == room.id:
				draw_rect(door.r, Color.MAGENTA, false, 3)
				draw_circle(door.r.get_center(), 12, Color.MAGENTA)
		for actor in sim.actors:
			if actor.active:
				draw_circle(actor.p, 11, Color.GREEN, false, 2)
				draw_line(actor.p + Vector2(-60, 20), actor.p + Vector2(40, 20), Color.WHITE, 2)
				draw_string(ThemeDB.fallback_font, actor.p + Vector2(-60, 42), "100 unidades", HORIZONTAL_ALIGNMENT_LEFT, -1, 15)

func _initialize() -> void:
	call_deferred("open_bench")

func open_bench() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="): room_id = arg.trim_prefix("--room=")
		if arg == "--capture": capture = true
		if arg == "--contract": contract_mode = true
		if arg == "--inspection": inspection = true; capture = true; actor_preset = true; fit_camera = false
		if arg.begins_with("--profile="): profile_id = arg.trim_prefix("--profile=")
	sim = Expedition.new()
	sim.coop = "solo"
	sim.start_run(1941)
	view = RoomView.new() if contract_mode else View.new()
	view.sim = sim; root.add_child(view)
	input_host = InputHost.new(); input_host.host = self; root.add_child(input_host)
	camera = Camera2D.new(); root.add_child(camera)
	overlay = GeometryOverlay.new(); overlay.sim = sim; root.add_child(overlay)
	var ui := CanvasLayer.new(); root.add_child(ui)
	label = Label.new(); label.position = Vector2(18, 12); ui.add_child(label)
	select(room_id)
	if contract_mode and capture:
		await capture_contract()
		quit(); return
	if inspection:
		await capture_inspection()
		quit(); return
	if capture:
		DirAccess.make_dir_recursive_absolute(Baseline.OUTPUT)
		var records := []
		for id in ["stairs", "cranes", "chapel"]:
			select(id)
			for mode in ["normal", "collision"]:
				overlay.visible = mode == "collision"
				await process_frame
				await RenderingServer.frame_post_draw
				var path: String = Baseline.OUTPUT + id + ("" if mode == "normal" else "-collision") + ".png"
				var error := root.get_texture().get_image().save_png(path)
				records.append({"room": id, "mode": mode, "path": path, "error": error, "camera": str(camera.position), "zoom": camera.zoom.x, "viewport": str(root.size), "actor": str(sim.actors[0].p)})
		var file := FileAccess.open(Baseline.OUTPUT + "baseline.json", FileAccess.WRITE)
		var catalog := []
		for room in sim.rooms: catalog.append({"id": room.id, "variants": ["baseline"]})
		var manifest := Seeds.select(sim, "docks", 0, catalog)
		manifest.connections = sim.doors.duplicate(true)
		file.store_string(Seeds.canonical({"seed": 1941, "geometry_sha256": Baseline.fingerprint(sim), "sources": Baseline.source_hashes(), "captures": records, "manifest": manifest}))
		print("WORKBENCH_CAPTURE_DONE")
		quit()

func select(id: String) -> void:
	if contract_mode: sim.start_run(1941)
	selected = Baseline.select_room(sim, id)
	room_id = selected.room.id
	for room in sim.rooms:
		if room.id not in sim.visited: sim.visited.append(room.id)
		view.scenery.reveal_at[room.id] = -1.0
	sim.actors[0].p = Baseline.reference_position(sim, selected.bounds)
	sim.actors[1].active = false
	if actor_preset:
		sim.actors[0].p = selected.bounds.get_center() + Vector2(-160, 220)
		sim.mech.p = sim.actors[0].p + Vector2(200, 0); sim.mech.deployed = true
		sim.enemies.clear(); sim.spawn_enemy(sim.actors[0].p + Vector2(340, 0), "guard")
	if contract_mode:
		view.profile = Biomes.profile(profile_id)
		if view.profile.has("error"):
			label.text = str(view.profile.error); return
		var template_id: String = view.profile.template_pool[0]
		var template := Contract.from_legacy(sim, template_id.trim_prefix("legacy.")) if template_id.begins_with("legacy.") else Contract.fixture()
		template.biome_id = view.profile.biome_id
		template.template_id = template_id
		for layer in template.layers: layer["material"] = "floor"
		view.instance = Contract.instantiate(template, room_id + "-preview", selected.room.r.position)
		if not view.instance.ok: label.text = str(view.instance.errors); return
		sim.actors[0].p = view.instance.spawns[0].position
		var area: Rect2 = view.instance.footprint[0]
		for rect in view.instance.footprint: area = area.merge(rect)
		selected.bounds = area
		selected.room.r = view.instance.footprint[0]
		selected.room.extra = view.instance.footprint.slice(1)
		sim.obstacles.clear(); sim.obstacle_kinds.clear()
		for obstacle in view.instance.obstacles:
			sim.obstacles.append(obstacle.rect); sim.obstacle_kinds.append(obstacle.kind)
		sim.floors = view.instance.footprint.duplicate()
		sim.raised = view.instance.raised.duplicate()
		sim.gaps = view.instance.gaps.duplicate()
		sim.ramps.clear(); sim.doors.clear()
		for ramp in view.instance.ramps:
			sim.ramps.append({"r": ramp.rect, "axis": ramp.axis, "low": ramp.low, "high": ramp.high})
		for connector in view.instance.connectors:
			var size := Vector2(4, connector.width) if connector.normal.x else Vector2(connector.width, 4)
			sim.doors.append({"room": room_id, "r": Rect2(connector.position - size * 0.5, size)})
	camera.position = selected.bounds.get_center()
	var size: Vector2 = root.get_visible_rect().size
	var zoom := minf(size.x / (selected.bounds.size.x + 360), (size.y - 80) / (selected.bounds.size.y + 360))
	camera.zoom = Vector2.ONE * zoom
	if not fit_camera:
		camera.zoom = Vector2.ONE * Display.VIEWS.normal
		camera.position = sim.actors[0].p + Vector2(100, -80)
	overlay.selected = selected; overlay.queue_redraw(); view.queue_redraw()
	label.text = "%s | seed 1941 | Tab sala | G geometria | C camera | A atores | N luz | setas mover\n%s" % [room_id, selected.error]

func _process(_delta: float) -> bool:
	if capture or sim == null: return false
	if Input.is_action_just_pressed("ui_focus_next"):
		var ids: Array = sim.rooms.map(func(room): return room.id)
		select(ids[(ids.find(room_id) + 1) % ids.size()])
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		if contract_mode: view.move_actor(direction * 180 * _delta)
		else: sim.actors[0].p = sim.move_body(sim.actors[0].p, direction * 180 * _delta, 11)
		view.queue_redraw(); overlay.queue_redraw()
	return false

func handle_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_G: overlay.visible = not overlay.visible
		KEY_C: fit_camera = not fit_camera; select(room_id)
		KEY_A: actor_preset = not actor_preset; select(room_id)
		KEY_N: view.neutral = not view.neutral; view.queue_redraw()

func capture_inspection() -> void:
	var dir := Baseline.OUTPUT + "inspection/"
	DirAccess.make_dir_recursive_absolute(dir)
	var records := []
	for resolution in Display.RESOLUTIONS:
		root.size = resolution
		root.content_scale_size = Vector2i(1280, 800)
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		await process_frame
		select("stairs")
		for mode in ["normal", "neutral", "collision"]:
			view.neutral = mode == "neutral"; overlay.visible = mode == "collision"
			view.queue_redraw(); overlay.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := dir + "%dx%d-%s.png" % [resolution.x, resolution.y, mode]
			var img := root.get_texture().get_image()
			var error := img.save_png(path)
			records.append({"path": path, "requested": str(resolution), "actual": str(img.get_size()), "logical_viewport": str(root.get_visible_rect().size), "zoom": camera.zoom.x, "mode": mode, "error": error})
	var file := FileAccess.open(dir + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": records, "sources": Baseline.source_hashes(), "actor_visual_scale": sim.ACTOR_VISUAL_SCALE, "marty_frame": 96, "titan_frame": 176, "density_example": Metrics.density(Vector2(688,384), Vector2(1700,1300)), "neutral_limit": "night modulation and additive lights off; baked lighting remains", "scene": "baseline with actor inspection fixtures"}, "\t"))
	root.size = Vector2i(1280, 800)
	select("stairs")
	var prop: Rect2 = sim.obstacles.filter(func(box): return selected.bounds.encloses(box))[0]
	camera.position = prop.get_center()
	for offset in [-70, -10, 70]:
		sim.actors[0].p = Vector2(prop.get_center().x, prop.end.y + offset)
		view.neutral = false; overlay.visible = true; view.queue_redraw(); overlay.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(dir + "occlusion-%d.png" % offset)
	print("INSPECTION_CAPTURE_DONE count=", records.size())

func capture_contract() -> void:
	DirAccess.make_dir_recursive_absolute(Baseline.OUTPUT)
	for profile in Biomes.load_records():
		profile_id = profile.biome_id
		select("stairs")
		overlay.visible = true
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(Baseline.OUTPUT + "contract-" + profile_id + ".png")
	print("CONTRACT_CAPTURE_DONE")
