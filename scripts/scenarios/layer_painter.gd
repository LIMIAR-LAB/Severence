extends RefCounted
const Contract = preload("res://scripts/scenarios/room_contract.gd")
var layer_textures: Dictionary = {}

func ground(ci: CanvasItem, instance: Dictionary, bounds: Rect2) -> void:
	for layer in instance.layers:
		if layer.depth != "ground": continue
		if layer.get("projected",false):
			draw_layer(ci,layer,bounds); continue
		for area in instance.footprint:
			var clipped: Dictionary = layer.duplicate()
			clipped["original_rect"] = layer.rect
			clipped.rect = layer.rect.intersection(area)
			if clipped.rect.has_area(): draw_layer(ci,clipped,bounds)

func draw_layer(ci: CanvasItem, layer: Dictionary, bounds: Rect2, profile: Dictionary = {}) -> void:
	if not layer.rect.intersects(bounds): return
	var path: String = profile.materials.floor if layer.get("material", "") == "floor" else layer.texture
	if not layer_textures.has(path): layer_textures[path] = Contract.texture_resource(path)
	var texture: Texture2D = layer_textures[path]
	var authored: Rect2 = layer.get("original_rect", layer.rect)
	if layer.mode == "plate":
		var ratio := texture.get_size() / authored.size
		var source := Rect2((layer.rect.position - authored.position) * ratio, layer.rect.size * ratio)
		ci.draw_texture_rect_region(texture, layer.rect, source)
		return
	var clip: Rect2 = layer.rect.intersection(bounds)
	if not clip.has_area(): return
	var cell := texture.get_size()
	for y in range(int(authored.position.y), int(layer.rect.end.y), int(cell.y)):
		for x in range(int(authored.position.x), int(layer.rect.end.x), int(cell.x)):
			var target := Rect2(Vector2(x, y), cell).intersection(layer.rect)
			if not target.has_area() or not target.intersects(bounds): continue
			var source_offset := target.position - Vector2(x, y)
			if texture is AtlasTexture:
				ci.draw_texture_rect_region(texture.atlas, target, Rect2(texture.region.position + source_offset, target.size))
			else:
				ci.draw_texture_rect_region(texture, target, Rect2(source_offset, target.size))

