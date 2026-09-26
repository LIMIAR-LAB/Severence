extends SceneTree
class Preview extends DockView:
	func _draw() -> void:
		for row in range(5):
			for col in range(5):
				var m := sim.new_mech(Vector2(110+col*190,170+row*190))
				m.occupant=0
				m.moving=col>0
				m.step=maxi(0,col-1)
				m.move_dir=[Vector2.DOWN,Vector2(1,1).normalized(),Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP][row]
				m.aim=m.move_dir
				draw_mech(m)
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1040,1000)
	var v:=Preview.new()
	v.sim=Expedition.new(); v.sim.make_hub()
	root.add_child(v)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/titan-v5.png")
	quit()
