extends RefCounted
## Hand-traced footprint of candidate 7206bc7b; all art uses one uniform scale.
const TEXTURE = "res://assets/environment/docks12/chapel/fixed_v01/sanctuary.png"
const SCALE := 1600.0 / 1361.0
const ORIGIN := Vector2(100,3400)
const SIZE := Vector2(1600,2336.0*1600.0/1744.0)
const WALK := [Rect2(145,310,1063,990),Rect2(538,0,98,315),Rect2(1200,738,161,202),Rect2(450,1295,485,190),Rect2(455,1480,192,195),Rect2(704,1480,194,344),Rect2(150,1460,245,175),Rect2(365,1340,91,155),Rect2(900,1340,117,155),Rect2(984,1460,220,175)]
const BLOCKS := [Rect2(832,310,224,116),Rect2(338,486,182,68),Rect2(660,486,183,68),Rect2(338,582,182,67),Rect2(660,582,183,67),Rect2(338,678,182,67),Rect2(660,678,183,67),Rect2(338,777,182,67),Rect2(660,777,183,67),Rect2(207,1465,133,84),Rect2(1020,1465,131,84)]

static func bounds(sim) -> Rect2:
	return Rect2(ORIGIN+sim.room_offsets.get("chapel",Vector2.ZERO),SIZE)

static func rect(sim, source: Rect2) -> Rect2:
	return Rect2(bounds(sim).position+source.position*SCALE,source.size*SCALE)

static func align_south_passage(sim) -> void:
	# The traced landing starts 27px to the right of the connecting deck.
	# Fill only missing slivers of the real connector, keeping one straight edge.
	var landing:=rect(sim,Rect2(704,1480,194,344))
	for route: Rect2 in sim.run_corridors:
		if route.size.x>=route.size.y or not route.intersects(landing) or route.end.y<=landing.end.y: continue
		var missing: Array=[route.intersection(bounds(sim))]
		for floor_rect: Rect2 in sim.floors:
			var next: Array=[]
			for part: Rect2 in missing: next.append_array(subtract(part,floor_rect))
			missing=next
		for part: Rect2 in missing:
			if part.has_area(): sim.floors.append(part)
		for door in sim.doors:
			if door.room!="chapel" or door.side!="bottom" or not route.intersects(door.r): continue
			var left:=minf(door.r.position.x,route.position.x)
			door.r=Rect2(left,door.r.position.y,maxf(door.r.end.x,route.end.x)-left,door.r.size.y)
	sim.ob_grid_count=-1
	sim.refresh_gate_blocks()

static func align_east_passage(sim) -> void:
	var opening:=rect(sim,Rect2(1200,738,161,202))
	var chapel: Dictionary=sim.room_by_id("chapel")
	if chapel.is_empty(): return
	for i in sim.run_corridors.size():
		var old: Rect2=sim.run_corridors[i]
		if old.size.x<=old.size.y or absf(old.position.x-chapel.r.end.x)>2: continue
		if not old.grow(120).intersects(opening): continue
		var aligned:=Rect2(old.position.x,opening.position.y,old.size.x,opening.size.y)
		if old==aligned: continue
		var floors: Array=[]
		for floor_rect: Rect2 in sim.floors:
			# Preserve both rooms; replace only the exposed connector fragment.
			if old.encloses(floor_rect) and not bounds(sim).encloses(floor_rect): continue
			floors.append(floor_rect)
		floors.append(Rect2(bounds(sim).end.x,aligned.position.y,aligned.end.x-bounds(sim).end.x,aligned.size.y))
		sim.floors=floors
		sim.run_corridors[i]=aligned
		for actor in sim.actors:
			if old.has_point(actor.p) and actor.p.x>=bounds(sim).end.x and not aligned.grow(-24).has_point(actor.p):
				actor.p.y=clampf(actor.p.y,aligned.position.y+24,aligned.end.y-24)
		if not sim.mech.is_empty() and old.has_point(sim.mech.p) and sim.mech.p.x>=bounds(sim).end.x:
			sim.mech.p.y=clampf(sim.mech.p.y,aligned.position.y+48,aligned.end.y-48)
		for group in sim.run_corridor_groups:
			for j in group.rects.size():
				if group.rects[j]==old: group.rects[j]=aligned
		for door in sim.doors:
			if door.room=="stairs" and door.side=="left" and door.r.grow(120).intersects(old):
				door.r=Rect2(door.r.position.x,aligned.position.y,door.r.size.x,aligned.size.y)
		sim.ob_grid_count=-1
		sim.refresh_gate_blocks()

static func subtract(area: Rect2, cut: Rect2) -> Array:
	var hit := area.intersection(cut)
	if not hit.has_area(): return [area]
	var pieces := [Rect2(area.position,Vector2(area.size.x,hit.position.y-area.position.y)),Rect2(Vector2(area.position.x,hit.end.y),Vector2(area.size.x,area.end.y-hit.end.y)),Rect2(Vector2(area.position.x,hit.position.y),Vector2(hit.position.x-area.position.x,hit.size.y)),Rect2(Vector2(hit.end.x,hit.position.y),Vector2(area.end.x-hit.end.x,hit.size.y))]
	return pieces.filter(func(r): return r.has_area())

static func install(sim) -> void:
	var area := bounds(sim)
	var floors := []
	for floor_rect in sim.floors: floors.append_array(subtract(floor_rect,area))
	for source in WALK: floors.append(rect(sim,source))
	sim.floors = floors
	for i in range(sim.obstacles.size()-1,-1,-1):
		if area.has_point(sim.obstacles[i].get_center()):
			sim.obstacles.remove_at(i); sim.obstacle_kinds.remove_at(i); sim.obstacle_hp.remove_at(i)
	for i in BLOCKS.size():
		sim.obstacles.append(rect(sim,BLOCKS[i])); sim.obstacle_kinds.append("altar" if i==0 else "sanctuary_baked"); sim.obstacle_hp.append(-1.0)
	sim.decor=sim.decor.filter(func(d): return not area.has_point(d.p))
	# Seal combat at the actual visible passages, without decorative legacy frames.
	for door in sim.doors:
		if door.room!="chapel": continue
		match door.side:
			"top": door.r=rect(sim,Rect2(538,280,98,20))
			"right": door.r=rect(sim,Rect2(1200,738,20,202))
			"bottom": door.r=rect(sim,Rect2(704,1700,194,20))
	sim.scenario_geometry_revision=3
	sim.ob_grid_count=-1
