extends SceneTree
const FX=preload("res://scripts/explosion_visuals.gd")
class Contrast extends Node2D:
	func _draw() -> void:
		for i in 8:
			var origin:=Vector2(i%4*320,i/4*360)
			draw_rect(Rect2(origin,Vector2(320,180)),Color("101827"))
			draw_rect(Rect2(origin+Vector2(0,180),Vector2(320,180)),Color("dfd8c8"))
			var progress: float=(FX.FRAME_ENDS[i]+(0.0 if i==0 else FX.FRAME_ENDS[i-1]))*0.5
			for y in [125,305]:
				FX.draw(self,{"p":origin+Vector2(160,y),"life":1.0-progress,"max":1.0,"r":70.0},[])
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.add_child(Contrast.new())
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/explosion-v01/contrast.png")
	print("EXPLOSION_CONTRAST_DONE"); quit()
