extends RefCounted
const Geometry = preload("res://scripts/scenarios/cranes_fixed.gd")
var texture: Texture2D
var iron_gate:=preload("res://scripts/scenarios/iron_gate_art.gd").new()
func ground(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	if not Geometry.active(sim): return
	if texture==null and ResourceLoader.exists(Geometry.TEXTURE): texture=load(Geometry.TEXTURE)
	if texture==null: return
	var area := Geometry.bounds(sim)
	var discovered: bool=rooms.any(func(r):return r.id=="cranes")
	if not discovered:
		if rooms.any(func(r):return r.id=="entry"):
			var west:=Rect2(area.position+Vector2(0,510)*Geometry.SCALE,Vector2(300,190*Geometry.SCALE))
			ci.draw_texture_rect_region(texture,west,Rect2((west.position-area.position)/Geometry.SIZE*texture.get_size(),west.size/Geometry.SIZE*texture.get_size()))
		return
	if area.intersects(view): ci.draw_texture_rect(texture,area,false)
func gate(ci: CanvasItem, door: Dictionary, locked: bool) -> void:
	iron_gate.draw(ci,door,locked)

func overhead(ci: CanvasItem, sim, rooms: Array) -> void:
	if texture==null or not Geometry.active(sim) or not rooms.any(func(r):return r.id=="cranes"): return
	# Only the thin raised booms occlude actors; never redraw surrounding floor.
	for outline in [[Vector2(480,227),Vector2(725,92),Vector2(754,110),Vector2(502,251)], [Vector2(523,307),Vector2(748,119),Vector2(758,141),Vector2(543,330)], [Vector2(1354,787),Vector2(1581,629),Vector2(1603,649),Vector2(1381,818)], [Vector2(1420,877),Vector2(1595,650),Vector2(1607,670),Vector2(1437,910)]]:
		var points:=PackedVector2Array(); var uv:=PackedVector2Array()
		for point in outline:
			points.append(Geometry.bounds(sim).position+point*Geometry.SCALE)
			uv.append(point*2048.0/1927.0/texture.get_size())
		ci.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,texture)
