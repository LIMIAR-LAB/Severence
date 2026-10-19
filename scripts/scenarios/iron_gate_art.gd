extends RefCounted
const PATH:="res://assets/environment/docks12/gates/iron_gate_hd.png"
const SOURCE:=Rect2(6,150,2160,370)
var art: AtlasTexture
func texture() -> AtlasTexture:
	if art==null:
		var source: Texture2D
		if ResourceLoader.exists(PATH): source=load(PATH)
		elif FileAccess.file_exists(PATH):
			var image:=Image.load_from_file(PATH)
			if image!=null and not image.is_empty(): source=ImageTexture.create_from_image(image)
		if source==null: return null
		art=AtlasTexture.new()
		art.atlas=source
		art.region=SOURCE
	return art
static func geometry(rect: Rect2) -> Dictionary:
	var horizontal:=rect.size.x>rect.size.y
	var length:=maxf(rect.size.x,rect.size.y)+12.0
	var height:=clampf(length*SOURCE.size.y/SOURCE.size.x,24,72)
	return {"center":rect.get_center(),"rotation":0.0 if horizontal else PI/2,"size":Vector2(length,height)}
func draw(ci: CanvasItem, door: Dictionary, locked: bool) -> void:
	if not locked: return
	var shape:=geometry(door.r)
	ci.draw_set_transform(shape.center,shape.rotation)
	var sprite:=texture()
	if sprite!=null:
		ci.draw_texture_rect(sprite,Rect2(-shape.size*0.5,shape.size),false,Color(1.4,1.4,1.4,1))
	else:
		# A broken asset must never leave an invisible solid combat barrier.
		ci.draw_rect(Rect2(-shape.size*0.5,shape.size),Color("324655"))
		ci.draw_rect(Rect2(-shape.size*0.5,shape.size),Color("b69a60"),false,2)
	ci.draw_set_transform(Vector2.ZERO)
