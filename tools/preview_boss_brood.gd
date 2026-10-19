extends SceneTree
const View=preload("res://scripts/world_view.gd")
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(900,680); root.content_scale_size=root.size
	var sim:=Expedition.new(); sim.start_run(1941)
	sim.enemies=sim.enemies.filter(func(e):return e.kind=="boss")
	var boss: Dictionary=sim.enemies[0]; boss.brood_cd=0.8
	sim.actors[0].p=boss.p+Vector2(300,100); sim.actors[1].active=false
	var view:=View.new(); view.sim=sim; root.add_child(view)
	for room in sim.rooms: sim.visited.append(room.id); view.scenery.reveal_at[room.id]=-1.0
	var camera:=Camera2D.new(); root.add_child(camera); camera.zoom=Vector2.ONE*0.9
	camera.position=boss.p+Vector2(70,-60); camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute("res://output/boss-brood")
	for i in 96:
		sim.tick_time+=0.05; sim.step_enemies(0.05)
		for fx in sim.effects: fx.life-=0.05
		sim.effects=sim.effects.filter(func(f):return f.life>0)
		view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		if i in [0,24,48,72,95]: root.get_texture().get_image().save_png("res://output/boss-brood/frame-%02d.png"%i)
	var children:=sim.enemies.filter(func(e):return e.has("boss_owner"))
	print("BOSS_BROOD_CAPTURE children=",children.size()," safe=",children.all(func(e):return sim.clear_at(e.p,12)))
	quit(0 if children.size()>=4 else 1)
