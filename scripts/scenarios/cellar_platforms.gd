extends RefCounted
## Geometry shared with scenery. Floor coverage remains underneath for airborne movement.
const Cut = preload("res://scripts/scenarios/sanctuary_fixed.gd")
const VERSION := 1
const SOLID := [Rect2(0,0,1500,280), Rect2(350,360,1000,180), Rect2(650,620,700,180), Rect2(0,880,1500,220)]

static func active(sim) -> bool:
	return sim.mode=="run" and sim.layout_manifest.get("cellar_platforms_version",0)==VERSION

static func bounds(sim) -> Rect2:
	return sim.room_by_id("cellar").get("r",Rect2())

static func platforms(sim) -> Array:
	var result := []
	var origin := bounds(sim).position
	for local in SOLID: result.append(Rect2(origin+local.position,local.size))
	return result

static func water(sim) -> Array:
	var result := [bounds(sim)]
	for solid in platforms(sim):
		var remainder := []
		for area in result: remainder.append_array(Cut.subtract(area,solid))
		result=remainder
	return result

static func water_at(sim, point: Vector2, radius: float) -> bool:
	if not active(sim): return false
	if not bounds(sim).grow(radius).has_point(point): return false
	for area in water(sim):
		if area.grow(radius).has_point(point): return true
	return false

static func safe_point(sim, preferred: Vector2, radius: float = 11.0) -> Vector2:
	if sim.clear_at(preferred,radius): return preferred
	# Search authored platforms, nearest first; bounded and checks current dynamic blockers.
	var candidates: Array[Vector2] = []
	for solid in platforms(sim):
		for x in range(int(solid.position.x)+32,int(solid.end.x)-31,48):
			for y in range(int(solid.position.y)+32,int(solid.end.y)-31,48): candidates.append(Vector2(x,y))
	candidates.sort_custom(func(a,b):return a.distance_squared_to(preferred)<b.distance_squared_to(preferred))
	for point in candidates:
		if sim.clear_at(point,radius): return point
	var spawn: Vector2 = sim.run_points.get("spawn",sim.actors[0].p)
	return spawn if sim.clear_at(spawn,radius) else preferred

static func remember(sim, actor: Dictionary) -> void:
	if active(sim) and actor.jump<=0 and bounds(sim).has_point(actor.p) and sim.clear_at(actor.p,11):
		actor["cellar_checkpoint"]=actor.p

static func recover(sim, actor: Dictionary) -> bool:
	if not active(sim): return false
	if not bounds(sim).has_point(actor.p) and not bounds(sim).has_point(actor.get("jump_from",actor.p)): return false
	var preferred: Vector2 = actor.get("cellar_checkpoint",actor.get("jump_from",bounds(sim).position+Vector2(1250,1000)))
	actor.p=safe_point(sim,preferred)
	actor["cellar_checkpoint"]=actor.p
	actor.knockback=Vector2.ZERO
	actor.dodge=0.0
	return true

static func install(sim) -> void:
	if bounds(sim).size!=Vector2(1500,1100): return
	var area := bounds(sim)
	sim.layout_manifest["cellar_platforms_version"]=VERSION
	var kept := []
	for gap in sim.gaps: kept.append_array(Cut.subtract(gap,area))
	kept.append_array(water(sim)); sim.gaps=kept
	# Remove collisions floating in the newly flooded channel, keeping solid platform props.
	for i in range(sim.obstacles.size()-1,-1,-1):
		if not area.has_point(sim.obstacles[i].get_center()) or not water_at(sim,sim.obstacles[i].get_center(),0): continue
		sim.obstacles.remove_at(i); sim.obstacle_kinds.remove_at(i); sim.obstacle_hp.remove_at(i)
	sim.ob_grid_count=-1
	for collection in [sim.actors,sim.enemies,sim.pickups,sim.chests]:
		for item in collection:
			if area.has_point(item.p) and not sim.clear_at(item.p,16): item.p=safe_point(sim,item.p,16)
	for actor in sim.actors: remember(sim,actor)
