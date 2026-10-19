extends RefCounted
## Floor-only preview. It never registers discovery or exposes room contents.
const Art=preload("res://scripts/scenarios/corridor_art.gd")
const DEPTH:=320.0
static func pieces(sim, visible: Array) -> Array:
	var result: Array=[]
	if sim.mode!="run" or not sim.RemainingFixed.active(sim): return result
	for route: Rect2 in Art.routes(sim):
		if not visible.any(func(floor_rect):return floor_rect.intersects(route)): continue
		var horizontal:=route.size.x>route.size.y
		for sign in [-1.0,1.0]:
			var end:=Vector2(route.position.x if sign<0 else route.end.x,route.get_center().y) if horizontal else Vector2(route.get_center().x,route.position.y if sign<0 else route.end.y)
			if not visible.any(func(floor_rect):return floor_rect.grow(2).has_point(end)): continue
			var extension:=Rect2(Vector2(end.x-DEPTH if sign<0 else end.x,route.position.y),Vector2(DEPTH,route.size.y)) if horizontal else Rect2(Vector2(route.position.x,end.y-DEPTH if sign<0 else end.y),Vector2(route.size.x,DEPTH))
			for room in sim.rooms:
				var id: String=room.get("id","")
				if id=="secret" or sim.visited.has(id) or not sim.RemainingFixed.owns(sim,id): continue
				for room_area: Rect2 in [room.r]+room.get("extra",[]):
					if not room_area.grow(2).has_point(end): continue
					for floor_rect: Rect2 in sim.floors:
						var overlap:=extension.intersection(room_area).intersection(floor_rect)
						if not overlap.has_area(): continue
						for part: Rect2 in Art.pieces_outside(overlap,sim.obstacles+sim.gaps+result.map(func(piece):return piece.rect)):
							result.append({"rect":part,"id":id,"end":end,"horizontal":horizontal,"sign":sign})
	return result

static func draw(ci: CanvasItem, sim, renderer, view: Rect2) -> void:
	for piece in pieces(sim,ci.vis_floors):
		var area: Rect2=piece.rect.intersection(view)
		if not area.has_area(): continue
		# Fade the far end of the real material beneath the atmospheric frontier.
		for i in 48:
			var distance:=DEPTH*i/48.0
			var stripe:=Rect2()
			if piece.horizontal:
				stripe=Rect2(piece.end.x+distance if piece.sign>0 else piece.end.x-distance-DEPTH/48.0,area.position.y,DEPTH/48.0,area.size.y)
			else:
				stripe=Rect2(area.position.x,piece.end.y+distance if piece.sign>0 else piece.end.y-distance-DEPTH/48.0,area.size.x,DEPTH/48.0)
			var part:=area.intersection(stripe)
			if part.has_area(): renderer.material_fill(ci,piece.id,part,view,1.0-smoothstep(150.0,DEPTH,distance+DEPTH/96.0))
