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
