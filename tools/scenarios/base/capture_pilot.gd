extends SceneTree
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const RoomView = preload("res://scripts/scenarios/room_preview.gd")
const Biomes = preload("res://scripts/scenarios/biome_catalog.gd")
const OUTPUT := "res://_bmad-output/implementation-artifacts/cenarios-base/captures/pilot-materials.png"
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://art/scenarios/scn-production/farol-docas-v01/layers.proposal.json"))
	var template := Rooms.fixture()
	template.template_id = "study.materials"; template.biome_id = "docks"
	template.footprint = [Rect2(0, 0, 1152, 288)]
	template.connectors = []; template.obstacles = []; template.layers = []
	template.spawns = [{"id": "player", "position": Vector2(300, 180), "radius": 11}]
	for source in data.layers:
		var layer: Dictionary = source.duplicate(true)
		layer.rect = Rect2(source.rect[0], source.rect[1], source.rect[2], source.rect[3])
		if layer.rect.position.y < 0: layer.depth = "foreground"
		template.layers.append(layer)
	var instance := Rooms.instantiate(template, "pilot-study", Vector2.ZERO)
	if not instance.ok: push_error(str(instance.errors)); quit(1); return
	var sim := Expedition.new(); sim.start_run(1941)
	sim.actors[0].p = Vector2(300,180); sim.actors[1].active = false
	sim.raised.clear(); sim.ramps.clear()
	var view := RoomView.new(); view.sim = sim; view.instance = instance
	view.profile = Biomes.profile("docks"); view.neutral = true
	root.add_child(view)
	var camera := Camera2D.new(); camera.position = Vector2(576, 110); root.add_child(camera)
	var layer := CanvasLayer.new(); root.add_child(layer)
	var label := Label.new(); label.text = "SCN-02.01 | estudo de materiais | escala nativa 1:1 | Marty real x1.12 | sem aceite de escadas"
	label.position = Vector2(20,20); layer.add_child(label)
	var errors := 0
	for floor_id in ["stone", "wood"]:
		sim.actors[0].p = Vector2(300 if floor_id == "stone" else 880, 180)
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var path := OUTPUT if floor_id == "stone" else OUTPUT.replace(".png", "-wood.png")
		if root.get_texture().get_image().save_png(path) != OK: errors += 1
	print("PILOT_CAPTURE_DONE errors=", errors)
	quit(0 if errors == 0 else 1)
