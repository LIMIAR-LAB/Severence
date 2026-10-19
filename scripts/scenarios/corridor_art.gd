extends RefCounted
## Reuses approved image materials at one consistent world scale.
const Cranes=preload("res://scripts/scenarios/cranes_fixed.gd")
const Sanctuary=preload("res://scripts/scenarios/sanctuary_fixed.gd")
const Warehouse=preload("res://scripts/scenarios/warehouse_fixed.gd")
const Map=preload("res://scripts/docks_map.gd")
const STONE=preload("res://assets/environment/docks12/cranes/fixed_v01/cranes.png")
const TIMBER=preload("res://assets/environment/docks12/corridors/transition_v02/timber.png")
const ALTAR_STONE=preload("res://assets/environment/docks12/chapel/fixed_v01/sanctuary.png")
const FLOOR_SOURCE:=Rect2(800,590,192,128)
const SCALE:=2500.0/2048.0
const WATER_SOURCE:=Rect2(640,1260,400,100)

static func routes(sim) -> Array:
	var result: Array=sim.run_corridors.duplicate()
	if sim.secret_open: result.append_array(sim.run_secret_floors)
	for shortcut in Map.SHORTCUTS:
		result.append(Rect2(shortcut.r.position+sim.room_offsets.get(shortcut.room,Vector2.ZERO),shortcut.r.size))
	if Cranes.active(sim): result.append(Cranes.apron(sim))
	if Warehouse.active(sim): result.append(Warehouse.apron())
	return result

static func is_corridor(sim, rect: Rect2) -> bool:
	return routes(sim).any(func(r):return r.encloses(rect))

static func visible_surfaces(sim, visible: Array) -> Array:
	# Use the materialized fragments, including clipped shortcuts and the secret
	# passage after opening. Logical normal corridors alone miss these surfaces.
	return visible.filter(func(r):return is_corridor(sim,r))

static func transition_surfaces(sim, visible: Array) -> Array:
	var result: Array=[]
	for route: Rect2 in routes(sim):
		for floor_rect: Rect2 in visible:
			var part:=route.intersection(floor_rect)
			if not part.has_area(): continue
			for piece in pieces_outside(part,result+sim.obstacles+sim.gaps):
				if piece.has_area(): result.append(piece)
	return result

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
	tiles(ci,area,view,STONE,FLOOR_SOURCE,SCALE,Color(1,1,1,alpha),true)

static func altar_transition(sim, area: Rect2) -> bool:
	var chapel: Dictionary=sim.room_by_id("chapel")
	if chapel.is_empty(): return false
	for route: Rect2 in sim.run_corridors:
		if route.size.x<=route.size.y or absf(route.position.x-chapel.r.end.x)>2: continue
		if route.get_center().y<chapel.r.position.y or route.get_center().y>chapel.r.end.y: continue
		if route.encloses(area): return true
	return false

static func altar_exterior(sim, area: Rect2) -> Rect2:
	var start:=maxf(area.position.x,Sanctuary.bounds(sim).end.x)
	return Rect2(start,area.position.y,maxf(0,area.end.x-start),area.size.y)

static func sanctuary_floor(ci: CanvasItem, area: Rect2, view: Rect2) -> void:
	# Continue the nave paving at its original scale, reflected at the last intact
	# column of stones. The doorway and external landing share this same origin.
	var anchor: Vector2=Sanctuary.rect(ci.sim,Rect2(1000,738,180,202)).position
	# tiles() resets its transform, so render into world coordinates through a
	# translated source grid implemented as clipped strips here.
	var width:=180.0*Sanctuary.SCALE
	var clip:=area.intersection(view)
	if not clip.has_area(): return
	for column in range(floori((clip.position.x-anchor.x)/width),ceili((clip.end.x-anchor.x)/width)):
		var cell:=Rect2(anchor+Vector2(column*width,0),Vector2(width,202*Sanctuary.SCALE))
		var part:=cell.intersection(clip)
		if not part.has_area(): continue
		var mirrored:=posmod(column,2)==1
		var sx:=cell.end.x-part.end.x if mirrored else part.position.x-cell.position.x
		var native:=1744.0/1361.0
		var sample:=Rect2(Vector2(1000+sx/Sanctuary.SCALE,738+(part.position.y-anchor.y)/Sanctuary.SCALE)*native,part.size/Sanctuary.SCALE*native)
		if mirrored:
			ci.draw_set_transform(Vector2(part.position.x+part.end.x,0),0,Vector2(-1,1))
		ci.draw_texture_rect_region(ALTAR_STONE,part,sample)
		if mirrored: ci.draw_set_transform(Vector2.ZERO)

static func transition_surface(ci: CanvasItem, route: Rect2, area: Rect2, view: Rect2) -> void:
	var clip:=area.intersection(view)
	if not clip.has_area(): return
	if altar_transition(ci.sim,route):
		clip=altar_exterior(ci.sim,clip)
		if not clip.has_area(): return
		sanctuary_floor(ci,clip,view)
		return
	# One full generated texture spans 640 world units; no mirrored masonry scraps.
	var source:=Rect2(Vector2.ZERO,TIMBER.get_size())
	if route.size.x>route.size.y:
		var turned:=Rect2(Vector2(clip.position.y,-clip.end.x),Vector2(clip.size.y,clip.size.x))
		ci.draw_set_transform(Vector2.ZERO,PI/2)
		tiles(ci,turned,turned,TIMBER,source,640.0/source.size.x)
		ci.draw_set_transform(Vector2.ZERO)
	else:
		tiles(ci,clip,clip,TIMBER,source,640.0/source.size.x)

static func transition_edge(ci: CanvasItem, p: Vector2, q: Vector2, normal: Vector2) -> void:
	# Low continuous iron beams, entirely outside the walkable footprint.
	ci.draw_line(p+normal*15+Vector2(0,12),q+normal*15+Vector2(0,12),Color(0.01,0.02,0.03,0.65),24)
	ci.draw_line(p+normal*9,q+normal*9,Color("171e24"),18)
	ci.draw_line(p+normal*3,q+normal*3,Color("68716e"),3)
	var tangent: Vector2=(q-p).normalized()
	for distance in range(24,int(p.distance_to(q)),160):
		var bolt:=p+tangent*distance+normal*9
		ci.draw_circle(bolt,3,Color("9c8965"))
static func backdrop(ci: CanvasItem, sim, visible: Array, view: Rect2) -> void:
	var reserved:=protected(sim)
	# An undiscovered painting is not a black rectangular occluder over the sea.
	if not sim.visited.has("chapel"): reserved.erase(Sanctuary.bounds(sim))
	for room in sim.rooms:
		reserved.append(room.r); reserved.append_array(room.get("extra",[]))
	# Never borrow a whole strip containing quay walls or walkable paving.
	# Disjoint patches also avoid overdrawing the same water at junctions.
	var painted:=[]
	for corridor in visible_surfaces(sim,visible):
		if not corridor.grow(900).intersects(view): continue
		for part in pieces_outside(corridor.grow(900).intersection(view),reserved+painted):
			tiles(ci,part,view,STONE,WATER_SOURCE,SCALE,Color("8fa9b0"),true)
			painted.append(part)
static func boundary(ci: CanvasItem, p: Vector2, q: Vector2, normal: Vector2, view: Rect2) -> void:
	var horizontal:=absf(p.y-q.y)<1
	var rect:=Rect2()
	if horizontal: rect=Rect2(minf(p.x,q.x),p.y-34 if normal.y<0 else p.y,absf(q.x-p.x),34)
	else: rect=Rect2(p.x-27 if normal.x<0 else p.x,minf(p.y,q.y),27,absf(q.y-p.y))
	# The seaward face stays entirely outside the collision footprint.
	if horizontal and normal.y>0:
		var face:=Rect2(rect.position,Vector2(rect.size.x,58))
		tiles(ci,face,view,STONE,Rect2(790,1120,150,62),1.0,Color("b8bec8"))
		ci.draw_rect(Rect2(face.position+Vector2(0,58),Vector2(face.size.x,14)),Color(0.01,0.025,0.03,0.4))
	ci.draw_rect(Rect2(rect.position+Vector2(0,13),rect.size),Color(0.01,0.025,0.03,0.65))
	tiles(ci,rect,view,STONE,Rect2(0,504,112,40) if horizontal else Rect2(116,774,27,128),1.0)
