extends SceneTree
var s: Expedition
var view: DockView
var camera: Camera2D
class MapSheet extends CombatHUD:
	var fixture: Expedition
	func _process(_dt: float) -> void: pass
	func _draw() -> void: draw_full_map(fixture,fixture.actors[0])
func _init() -> void: call_deferred("capture")
func shot(name: String) -> void:
	view.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/traversal-revision/"+name+".png")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-output/traversal-revision")
	root.size=Vector2i(1344,752); root.content_scale_size=root.size
	s=Expedition.new(); s.coop="solo"; s.unlocked.erase("titan"); s.start_run(1941); s.actors[1].active=false
	for room in s.rooms:
		if room.id not in s.visited: s.visited.append(room.id)
	var a: Dictionary=s.actors[0]; a.armor=true; a.armor_type="omega"; a.armor_time=300; a.transform=0
	a.p=s.run_points.bike_checkpoint; a.bike=false; s.tick_time=1.0
	view=DockView.new();view.sim=s;root.add_child(view)
	for room in s.rooms: view.scenery.reveal_at[room.id]=-100.0
	camera=Camera2D.new();camera.position=a.p-Vector2(0,90);camera.zoom=Vector2(1.22,1.22);root.add_child(camera)
	await shot("faisca")
	a.p=s.bridge_zone().position+Vector2(850,305);a.bike=true;a.bike_boosting=true;a.move=Vector2.RIGHT;a.facing=Vector2.RIGHT;s.bike.riding=true
	s.bridge_timer=3.4;s.bridge_broken=[s.bridge_segments()[0]];s.gaps.append(s.bridge_segments()[0]);s.effects.append({"p":s.bridge_segments()[0].get_center(),"kind":"bridge_debris","life":0.8,"max":1.2})
	camera.position=a.p+Vector2(200,-35);camera.zoom=Vector2(1.05,1.05)
	await shot("corrida")
	view.queue_free();camera.queue_free();await process_frame
	var map:=MapSheet.new(); map.fixture=s; root.add_child(map)
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/traversal-revision/mapa.png")
	print("TRAVERSAL_PREVIEW_DONE");quit()
