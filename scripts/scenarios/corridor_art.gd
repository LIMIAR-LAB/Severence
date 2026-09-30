extends RefCounted
## Reuses approved image materials at one consistent world scale.
const Cranes=preload("res://scripts/scenarios/cranes_fixed.gd")
const Sanctuary=preload("res://scripts/scenarios/sanctuary_fixed.gd")
const Warehouse=preload("res://scripts/scenarios/warehouse_fixed.gd")
const Map=preload("res://scripts/docks_map.gd")
const STONE=preload("res://assets/environment/docks12/cranes/fixed_v01/cranes.png")
const FLOOR_SOURCE:=Rect2(800,590,192,128)
const SCALE:=2500.0/2048.0

static func protected(sim) -> Array:
	var areas: Array=[Map.ENTRY_ART_BOUNDS,Sanctuary.bounds(sim)]
	if Cranes.active(sim): areas.append(Cranes.bounds(sim))
	if Warehouse.active(sim): areas.append(Warehouse.bounds(sim))
	return areas
static func is_authored(sim, rect: Rect2) -> bool:
	return protected(sim).any(func(area):return area.encloses(rect))
static func pieces_outside(rect: Rect2, areas: Array) -> Array:
	var pieces: Array=[rect]
	for area in areas:
		var next:=[]
		for piece in pieces: next.append_array(Sanctuary.subtract(piece,area))
		pieces=next
	return pieces
static func tiles(ci: CanvasItem, area: Rect2, view: Rect2, texture: Texture2D, source: Rect2, scale_factor: float, tint:=Color.WHITE, mirror:=false) -> void:
	var clip:=area.intersection(view)
	if not clip.has_area(): return
	var size:=source.size*scale_factor
	for y in range(floori(clip.position.y/size.y),ceili(clip.end.y/size.y)):
		for x in range(floori(clip.position.x/size.x),ceili(clip.end.x/size.x)):
			var cell:=Rect2(Vector2(x,y)*size,size)
			var part:=cell.intersection(clip)
			var sample:=Rect2(source.position+(part.position-cell.position)/scale_factor,part.size/scale_factor)
			var target:=part
			var reflection:=Vector2.ONE
			var origin:=Vector2.ZERO
			if mirror and posmod(y,2)==1:
				sample.position.y=source.position.y+(cell.end.y-part.end.y)/scale_factor
				target.position.y=cell.position.y+cell.end.y-part.end.y
				reflection.y=-1; origin.y=cell.position.y+cell.end.y
			if mirror and posmod(x,2)==1:
				sample.position.x=source.position.x+(cell.end.x-part.end.x)/scale_factor
				target.position.x=cell.position.x+cell.end.x-part.end.x
				reflection.x=-1; origin.x=cell.position.x+cell.end.x
			if mirror: ci.draw_set_transform(origin,0,reflection)
			ci.draw_texture_rect_region(texture,target,sample,tint)
			if mirror: ci.draw_set_transform(Vector2.ZERO)
static func floor_surface(ci: CanvasItem, area: Rect2, view: Rect2, alpha:=1.0) -> void:
	tiles(ci,area,view,STONE,FLOOR_SOURCE,SCALE,Color(1,1,1,alpha))
static func backdrop(ci: CanvasItem, sim, visible: Array, view: Rect2) -> void:
	var reserved:=protected(sim)
	for room in sim.rooms:
		reserved.append(room.r); reserved.append_array(room.get("extra",[]))
	for corridor in sim.run_corridors:
		if not visible.any(func(f):return corridor.intersects(f)): continue
		if not corridor.grow(900).intersects(view): continue
		for part in pieces_outside(corridor.grow(900),reserved):
			tiles(ci,part,view,STONE,Rect2(0,1230,2048,130),SCALE,Color("78949f"),true)
static func boundary(ci: CanvasItem, p: Vector2, q: Vector2, normal: Vector2, view: Rect2) -> void:
	var horizontal:=absf(p.y-q.y)<1
	var rect:=Rect2()
	if horizontal: rect=Rect2(minf(p.x,q.x),p.y-34 if normal.y<0 else p.y,absf(q.x-p.x),34)
	else: rect=Rect2(p.x-27 if normal.x<0 else p.x,minf(p.y,q.y),27,absf(q.y-p.y))
	ci.draw_rect(Rect2(rect.position+Vector2(0,13),rect.size),Color(0.01,0.025,0.03,0.65))
	tiles(ci,rect,view,STONE,Rect2(0,504,112,40) if horizontal else Rect2(116,774,27,128),1.0)
