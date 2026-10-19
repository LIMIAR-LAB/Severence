extends RefCounted
## Visual discovery only: never changes walkable geometry or entity visibility.
const Art=preload("res://scripts/scenarios/corridor_art.gd")
const Sanctuary=preload("res://scripts/scenarios/sanctuary_fixed.gd")
var cloud: ImageTexture
const PATH_FOG_FACTOR := 0.04

func clear_paths(sim, visible: Array, view: Rect2) -> Array:
	# Preserve a readable lane in both travel directions, including the real landing.
	var paths: Array=[]
	for route: Rect2 in Art.routes(sim):
		if not route.grow(320).intersects(view): continue
		if not visible.any(func(floor_rect):return route.intersects(floor_rect)): continue
		var horizontal:=route.size.x>route.size.y
		var lane:=route.grow_individual(320,0,320,0) if horizontal else route.grow_individual(0,320,0,320)
		if horizontal:
			lane.position.y+=route.size.y*0.12; lane.size.y*=0.76
		else:
			lane.position.x+=route.size.x*0.12; lane.size.x*=0.76
		for floor_rect: Rect2 in sim.floors:
			var part:=lane.intersection(floor_rect).intersection(view.grow(360))
			if part.has_area(): paths.append_array(Art.pieces_outside(part,sim.obstacles+sim.gaps+paths))
	return paths

func draw_cloud(ci: CanvasItem, target: Rect2, tint: Color, paths: Array) -> void:
	# Feather outward from the union of clear lanes; adjoining fragments have no seams.
	var nearby:=paths.filter(func(path):return path.grow(40).intersects(target))
	if nearby.is_empty():
		ci.draw_texture_rect(texture(),target,false,tint); return
	var remaining: Array=[target]
	var patches: Array=[]
	for band in 6:
		var strength:=lerpf(PATH_FOG_FACTOR,1.0,smoothstep(0.0,5.0,float(band)))
		for lane: Rect2 in nearby:
			var path:=lane.grow(float(band)*8.0)
			var next: Array=[]
			for part: Rect2 in remaining:
				var overlap:=part.intersection(path)
				if overlap.has_area(): patches.append({"rect":overlap,"factor":strength})
				next.append_array(Sanctuary.subtract(part,path))
			remaining=next
	for part: Rect2 in remaining: patches.append({"rect":part,"factor":1.0})
	var tex:=texture()
	for patch in patches:
		var part: Rect2=patch.rect
		var color:=tint; color.a*=patch.factor
		var source:=Rect2((part.position-target.position)/target.size*tex.get_size(),part.size/target.size*tex.get_size())
		ci.draw_texture_rect_region(tex,part,source,color)

static func floor_owner(sim, rect: Rect2) -> String:
	# Hand-traced walk polygons can overhang the painted bounds by ~1 world unit.
	if Sanctuary.bounds(sim).grow(4).encloses(rect): return "chapel"
	if sim.CranesFixed.active(sim) and sim.CranesFixed.bounds(sim).encloses(rect): return "cranes"
	if sim.WarehouseFixed.active(sim) and sim.WarehouseFixed.bounds(sim).encloses(rect): return "warehouse"
	for room in sim.rooms:
		for area: Rect2 in [room.r]+room.get("extra",[]):
			if area.encloses(rect): return room.get("id", "")
	return ""

static func floor_is_discovered(sim, rect: Rect2) -> bool:
	var owner:=floor_owner(sim,rect)
	return sim.mode!="run" or owner.is_empty() or sim.visited.has(owner)

func texture() -> ImageTexture:
	if cloud!=null: return cloud
	var noise:=FastNoiseLite.new(); noise.seed=1941; noise.frequency=0.038
	noise.fractal_octaves=4
	var image:=Image.create(192,192,false,Image.FORMAT_RGBA8)
	for y in 192:
		for x in 192:
			var uv:=(Vector2(x,y)-Vector2(95.5,95.5))/95.5
			var n:=noise.get_noise_2d(x,y)*0.5+0.5
			var radius:=uv.length()+0.14*(n-0.5)
			var envelope:=1.0-smoothstep(0.24,0.96,radius)
			image.set_pixel(x,y,Color(1,1,1,envelope*(0.48+0.52*n)))
	cloud=ImageTexture.create_from_image(image)
	return cloud

static func reveal_alpha(sim, owner: String, reveal_at: Dictionary) -> float:
	if not sim.visited.has(owner): return 1.0
	var age: float=sim.tick_time-float(reveal_at.get(owner,-100))
	return 1.0-smoothstep(0.0,1.2,maxf(age,0.0))

func reveal_regions(sim, reveal_at: Dictionary) -> Array:
	var result: Array=[]
	if sim.mode!="run": return result
	for room in sim.rooms:
		var owner: String=room.get("id","")
		if owner.is_empty() or not sim.visited.has(owner): continue
		if owner=="secret" and not sim.secret_open: continue
		var opacity:=reveal_alpha(sim,owner,reveal_at)
		if opacity<=0: continue
		var areas: Array=[room.r]+room.get("extra",[])
		if owner=="chapel": areas.append(Sanctuary.bounds(sim))
		if owner=="entry": areas.append(sim.DOCKS.ENTRY_ART_BOUNDS)
		if owner=="cranes" and sim.CranesFixed.active(sim): areas.append(sim.CranesFixed.bounds(sim))
		if owner=="warehouse" and sim.WarehouseFixed.active(sim): areas.append(sim.WarehouseFixed.bounds(sim))
		if sim.RemainingFixed.owns(sim,owner): areas.append(sim.RemainingFixed.image_area(sim,owner))
		for area: Rect2 in areas:
			result.append({"rect":area,"alpha":opacity,"owner":owner})
	return result

func regions(sim, visible: Array, reveal_at: Dictionary) -> Array:
	var result: Array=[]
	if sim.mode!="run": return result
	var routes:=Art.routes(sim).filter(func(route):return visible.any(func(floor_rect):return route.intersects(floor_rect)))
	for floor_rect: Rect2 in sim.floors:
		var owner:=floor_owner(sim,floor_rect)
		if owner.is_empty(): continue
		if owner=="secret" and not sim.secret_open: continue
		var opacity:=reveal_alpha(sim,owner,reveal_at)
		if opacity<=0: continue
		for route: Rect2 in routes:
			var overlap:=route.intersection(floor_rect)
			# Ordinary entrances merely touch; a shallow band bridges their shared edge.
			if not overlap.has_area(): overlap=route.intersection(floor_rect.grow(8))
			if not overlap.has_area(): continue
			result.append({"rect":overlap,"alpha":opacity})
	return result

func draw(ci: CanvasItem, sim, visible: Array, reveal_at: Dictionary, view: Rect2) -> void:
	var paths:=clear_paths(sim,visible,view)
	# World-aligned cloud cells cover whole newly revealed paintings, including wings.
	# Deduplication prevents overlapping room rectangles from darkening the same cell twice.
	var cells: Dictionary={}
	for region in reveal_regions(sim,reveal_at):
		var area: Rect2=region.rect.intersection(view.grow(360))
		if not area.has_area(): continue
		for y in range(floori(area.position.y/180),ceili(area.end.y/180)+1):
			for x in range(floori(area.position.x/180),ceili(area.end.x/180)+1):
				var key:=Vector2i(x,y)
				cells[key]=maxf(cells.get(key,0.0),region.alpha)
	for cell: Vector2i in cells:
		var center:=Vector2(cell)*180
		var phase:=center.x*0.013+center.y*0.019
		var drift:=Vector2(sin(sim.tick_time*0.19+phase)*24,cos(sim.tick_time*0.14+phase)*17)
		draw_cloud(ci,Rect2(center+drift-Vector2(330,330),Vector2(660,660)),Color(0.10,0.15,0.19,0.64*cells[cell]),paths)
	for region in regions(sim,visible,reveal_at):
		var r: Rect2=region.rect
		if not r.grow(360).intersects(view): continue
		var horizontal:=r.size.x>r.size.y
		var length: float=maxf(r.size.x,r.size.y)
		var count:=maxi(2,ceili(length/125.0))
		for i in count+1:
			var fraction:=float(i)/count
			var center:=Vector2(lerpf(r.position.x,r.end.x,fraction),r.get_center().y) if horizontal else Vector2(r.get_center().x,lerpf(r.position.y,r.end.y,fraction))
			var phase:=center.x*0.013+center.y*0.019
			for layer in 3:
				var drift:=Vector2(sin(sim.tick_time*0.19+phase+layer)*24,cos(sim.tick_time*0.14+phase+layer*2)*17)
				var span:=Vector2(340,470) if horizontal else Vector2(470,340)
				span*=1.0+layer*0.16
				var color:=Color(0.18,0.24,0.29,0.22*region.alpha)
				if layer==0: color=Color(0.10,0.15,0.19,0.32*region.alpha)
				draw_cloud(ci,Rect2(center+drift-span*0.5,span),color,paths)
