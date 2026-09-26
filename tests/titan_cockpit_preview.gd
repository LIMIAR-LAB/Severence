extends SceneTree
class Preview extends DockView:
	func _draw() -> void:
		for row in range(2):
			for col in range(5):
				var m:=sim.new_mech(Vector2(110+col*190,210+row*230))
				m["cockpit_t"]=1.2*(1.0-float(col)/5.0)
				m["cockpit_entering"]=row==0
				m["cockpit_actor"]=0
				m["cockpit_outside"]=m.p+Vector2(45,30)
				draw_cockpit(m)
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1040,540)
	var v:=Preview.new()
	v.sim=Expedition.new();v.sim.make_hub()
	root.add_child(v)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/titan-cockpit.png")
	quit()
