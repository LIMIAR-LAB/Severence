extends SceneTree
func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/titan-cockpit.png"))
	var atlas := Image.create(1056,176,false,Image.FORMAT_RGBA8)
	for col in range(6):
		var tile := source.get_region(Rect2i(col*362,0,362,724))
		var crop := tile.get_region(tile.get_used_rect())
		crop.resize(roundi(crop.get_width()*0.37),roundi(crop.get_height()*0.37),Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(col*176+88-crop.get_width()/2,164-crop.get_height()))
	quit(atlas.save_png("res://assets/mech/titan_cockpit.png"))
