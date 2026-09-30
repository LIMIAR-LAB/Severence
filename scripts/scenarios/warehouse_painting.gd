extends RefCounted
const Geometry=preload("res://scripts/scenarios/warehouse_fixed.gd")
var texture: Texture2D
func ground(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	if not Geometry.active(sim): return
	if texture==null and ResourceLoader.exists(Geometry.TEXTURE): texture=load(Geometry.TEXTURE)
	if texture==null: return
	var area:=Geometry.bounds(sim)
	if rooms.any(func(r):return r.id=="warehouse"):
		if area.intersects(view): ci.draw_texture_rect(texture,area,false)
	elif rooms.any(func(r):return r.id=="cranes"):
		var west:=Rect2(area.position+Vector2(0,503),Vector2(190,320))
		ci.draw_texture_rect_region(texture,west,Rect2((west.position-area.position)*1.28,west.size*1.28))
