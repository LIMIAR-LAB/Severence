extends SceneTree
## Native atlas inspection through Godot, all eight attack directions.
class Sheet extends Node2D:
	var motion = preload("res://scripts/enemy_motion.gd").new()
	func _ready() -> void: motion.load_assets()
	func _draw() -> void:
		draw_rect(Rect2(0,0,1252,1080),Color("18232e"))
		var font := ThemeDB.fallback_font
		for row in range(8):
			var direction: String = motion.DIRECTIONS[row]
			var clip: Dictionary = motion.manifests.fish.clips.attack[direction]
			draw_string(font,Vector2(4,38+row*132),direction,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
			for frame in range(int(clip.frames)):
				draw_texture_rect_region(motion.textures[clip.path],Rect2(96+frame*128,12+row*132,128,128),Rect2(frame*128,0,128,128))
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1252,1080);root.content_scale_size=root.size
	var sheet:=Sheet.new();root.add_child(sheet)
	await process_frame;await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/fish-harpoon-v2")
	root.get_texture().get_image().save_png("res://output/fish-harpoon-v2/all-directions.png")
	print("FISH_HARPOON_SHEET_DONE");quit()
