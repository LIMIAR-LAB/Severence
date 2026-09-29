extends SceneTree
# 0.19: isola a paisagem sem fenda/atores para comprovar movimento ambiental real.
class Landscape extends Node2D:
	var art = preload("res://scripts/arrival_art.gd").new()
	var clock := 0.0
	func _draw() -> void:
		draw_texture(art.PAINTING,Vector2.ZERO)

func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1536,1024)
	root.content_scale_size = Vector2i(1536,1024)
	var landscape := Landscape.new()
	root.add_child(landscape)
	var overlay := Node2D.new()
	overlay.scale = Vector2(1536,1024)/landscape.art.MAP.ENTRY_ART_BOUNDS.size
	overlay.position = -landscape.art.MAP.ENTRY_ART_BOUNDS.position*overlay.scale
	root.add_child(overlay)
	overlay.draw.connect(func(): landscape.art.draw_environment(overlay,landscape.clock))
	var frames: Array[Image] = []
	for t in [0.0,1.5]:
		landscape.clock=t; overlay.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		frames.append(frame)
		frame.save_png("res://test-output/entry-environment-%s.png"%str(t))
	var changes := 0
	for y in range(932,1020):
		for x in range(280,1050):
			if frames[0].get_pixel(x,y)!=frames[1].get_pixel(x,y): changes+=1
	print("Pixels de água/reflexo animados: ",changes)
	print("failures=",int(changes<100))
	quit(int(changes<100))
