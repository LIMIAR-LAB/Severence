extends SceneTree
const View=preload("res://scripts/world_view.gd")
const Ray=preload("res://scripts/ray_encounter.gd")
const OUT="res://test-output/ray-encounter/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(960,540)
	var s:=Expedition.new(); s.coop="solo"; s.start_run(42)
	var e: Dictionary=s.enemies.filter(func(enemy):return Ray.owns(s,enemy))[0]
	s.enemies=[e]; s.effects.clear(); s.bullets.clear(); s.combat_zones.clear()
	var room: Dictionary=s.room_by_id("cranes"); room.cleared=true; room.locked=false; s.refresh_gate_blocks()
	var center: Vector2=room.r.get_center()+Vector2(0,200)
	s.actors[0].p=s.RemainingFixed.safe_point(s,room.r,center,11)
	s.actors[0].facing=Vector2.RIGHT; s.actors[0].invuln=100
	e.p=s.actors[0].p+Vector2(220,0); s.recover_enemy_room(e)
	var view:=View.new(); view.sim=s; root.add_child(view)
	for r in s.rooms: s.visited.append(r.id); view.scenery.reveal_at[r.id]=-1
	var camera:=Camera2D.new(); root.add_child(camera)
	camera.position=s.actors[0].p; camera.zoom=Vector2.ONE*1.2; camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute(OUT)
	for i in 105:
		if i>0:
			s.step_enemies(0.1); s.step_bullets(0.1); s.tick_time+=0.1
			for fx in s.effects: fx.life-=0.1
			s.effects=s.effects.filter(func(fx):return fx.life>0)
		await process_frame; view.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"frame-%03d.png"%i)
	print("RAY_CAPTURE_DONE frames=105"); quit()
