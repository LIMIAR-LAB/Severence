extends SceneTree
class Preview extends DockView:
	func _draw() -> void:
		for outfit in range(4):
			for view in range(5):
				var a: Dictionary = sim.actors[0].duplicate(true)
				a.outfit = ["padrao", "espiao", "mecanico", "padrao"][outfit]
				a.armor = outfit == 3
				a.p = Vector2(90 + view * 180, 120 + outfit * 150)
				a.aim = [Vector2.DOWN, Vector2(1,1).normalized(), Vector2.RIGHT, Vector2(1,-1).normalized(), Vector2.UP][view]
				a.facing = a.aim
				draw_actor(a)
func _init() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(950,650)
	var v := Preview.new()
	v.sim = Expedition.new()
	v.sim.make_hub()
	root.add_child(v)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/marty-grips.png")
	quit()
