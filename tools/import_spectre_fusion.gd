extends SceneTree
# 0.18: normaliza a simbiose e garante laterais coerentes, inclusive no ataque.
func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/spectre-fusion-v3.png"))
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			if source.get_pixel(x,y).a < 0.1: source.set_pixel(x,y,Color(0,0,0,0))
	var atlas := Image.create(640,640,false,Image.FORMAT_RGBA8)
	var ys := [0,345,640,930,1254]
	for row in range(4):
		for col in range(4):
			# A segunda linha da fonte olha à direita; espelho produz a esquerda.
			var source_row := 1 if row in [1,2] else row
			var x0 := roundi(col*1254.0/4)
			var x1 := roundi((col+1)*1254.0/4)
			var tile := source.get_region(Rect2i(x0,ys[source_row],x1-x0,ys[source_row+1]-ys[source_row]))
			var crop := tile.get_region(tile.get_used_rect())
			crop.resize(roundi(crop.get_width()*0.42),roundi(crop.get_height()*0.42),Image.INTERPOLATE_NEAREST)
			crop = crop.get_region(crop.get_used_rect())
			if row == 1: crop.flip_x()
			assert(crop.get_width()<148 and crop.get_height()<148)
			atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(col*160+80-crop.get_width()/2,row*160+154-crop.get_height()))
	quit(atlas.save_png("res://assets/marty/spectre_fusion_v3.png"))
