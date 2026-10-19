extends SceneTree
const View=preload("res://scripts/world_view.gd")
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(720,540); root.content_scale_size=root.size
	var sim:=Expedition.new(); sim.start_run(1941); sim.enemies.clear()
	for actor in sim.actors: actor.active=false
	var center:=sim.story_npc_position()+Vector2(0,250)
	sim.pickups=[{"p":center+Vector2(-60,0),"kind":"fuel"},{"p":center+Vector2(0,0),"kind":"battery"}]
	sim.bullets=[{"p":center+Vector2(65,30),"to":center+Vector2(65,30),"kind":"bomb","t":0.0,"r":10.0}]
	sim.bullets.append({"p":center+Vector2(0,-40),"v":Vector2(150,-80),"kind":"p_rocket","height":28.0,"r":10.0})
	sim.obstacles.append(Rect2(center+Vector2(100,-30),Vector2(65,60))); sim.obstacle_kinds.append("mangrove")
	var view:=View.new(); view.sim=sim; root.add_child(view)
	for room in sim.rooms: sim.visited.append(room.id); view.scenery.reveal_at[room.id]=-1.0
	var camera:=Camera2D.new(); root.add_child(camera); camera.zoom=Vector2.ONE*2.5
	camera.position=center+Vector2(30,-35); camera.force_update_scroll()
	view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/world-details")
	root.get_texture().get_image().save_png("res://output/world-details/pickups-bomb-tree.png")
	print("WORLD_DETAILS_CAPTURE loaded=",view.world_detail_art.textures.size())
	quit()
