extends SceneTree
# 0.18: empacota poses completas, sem cortar extremidades para criar margens.
func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/titan-walk-v5.png"))
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			if source.get_pixel(x,y).a < 0.1: source.set_pixel(x,y,Color(0,0,0,0))
	var xs := [0,270,515,770,1025,1289]
	var ys := [0,245,480,710,930,1220]
	var atlas := Image.create(1760,880,false,Image.FORMAT_RGBA8)
	for row in range(5):
		for col in range(10):
			var source_col := col if col < 5 else 0
			var tile := source.get_region(Rect2i(xs[source_col],ys[row],xs[source_col+1]-xs[source_col],ys[row+1]-ys[row]))
			var crop := tile.get_region(tile.get_used_rect())
			crop.resize(roundi(crop.get_width()*0.63),roundi(crop.get_height()*0.63),Image.INTERPOLATE_NEAREST)
			crop = crop.get_region(crop.get_used_rect())
			assert(crop.get_width() <= 156 and crop.get_height() <= 156)
			atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(col*176+88-crop.get_width()/2,row*176+164-crop.get_height()))
	quit(atlas.save_png("res://assets/mech/titan_v5.png"))
