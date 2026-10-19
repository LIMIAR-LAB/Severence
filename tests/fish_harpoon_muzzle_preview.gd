extends SceneTree
class Sheet extends Node2D:
	var images: Array = []
	var names := ["south","south-east","east","north-east","north","north-west","west","south-west"]
	func _ready() -> void:
		for name in names:
			var image := Image.load_from_file("res://art/source/pixellab/enemy-motion-v3/fish/harpoon-fire-v2/staged/fish/attack-"+name+".png")
			images.append(ImageTexture.create_from_image(image))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1536,832),Color("18232e"))
		for i in range(8):
			var origin := Vector2(i%4*384,i/4*416)
			draw_string(ThemeDB.fallback_font,origin+Vector2(4,18),names[i]+" fire pose5",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
			draw_texture_rect_region(images[i],Rect2(origin+Vector2(0,24),Vector2(384,384)),Rect2(5*128,0,128,128))
			for coord in [32,64,96,112]:
				draw_line(origin+Vector2(coord*3,24),origin+Vector2(coord*3,408),Color(1,1,1,0.15))
				draw_line(origin+Vector2(0,24+coord*3),origin+Vector2(384,24+coord*3),Color(1,1,1,0.15))
				draw_string(ThemeDB.fallback_font,origin+Vector2(coord*3,410),str(coord),HORIZONTAL_ALIGNMENT_LEFT,-1,12)
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1536,832);root.content_scale_size=root.size
	var sheet:=Sheet.new();sheet.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(sheet)
	await process_frame;await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/fish-harpoon-v2")
	root.get_texture().get_image().save_png("res://output/fish-harpoon-v2/muzzle-review.png")
	quit()
