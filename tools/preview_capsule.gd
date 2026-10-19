extends SceneTree
class Preview extends DockView:
	func _draw() -> void:
		draw_rect(Rect2(0,0,1120,490),Color("111b26"))
		var stages := ["sealed","ready","close","launch"]
		for i in stages.size():
			sim.run_points.extraction=Vector2(140+i*280,380)
			sim.boss_dead=i>0
			sim.extract_state="" if i<2 else stages[i]
			sim.extract_t=0.35 if i==2 else 0.28
			draw_capsule()
			text_at(Vector2(85+i*280,465),["SELADA","PRONTA","FECHANDO","PARTINDO"][i],Color.WHITE,18)
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1120,490)
	root.content_scale_size=Vector2i(1120,490)
	var view := Preview.new(); view.sim=Expedition.new(); view.sim.tick_time=2.0
	root.add_child(view)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/capsule-preview")
	root.get_texture().get_image().save_png("res://output/capsule-preview/naval-v2.png")
	print("CAPSULE_PREVIEW_DONE")
	quit()

