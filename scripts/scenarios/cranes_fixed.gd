extends RefCounted
## Candidate 18fbce97. Coordinates traced on its 1927-wide inspection preview.
const TEXTURE = "res://assets/environment/docks12/cranes/fixed_v01/cranes.png"
const ORIGIN := Vector2(2200,5722)
const SIZE := Vector2(2500,1360.0*2500.0/2048.0)
const SCALE := 2500.0/1927.0
const Cut = preload("res://scripts/scenarios/sanctuary_fixed.gd")
const FIXED_PILOT := true
# 0.22: o conector vertical 6→7→1 só sobrepunha ~5px nas duas pontas — margem
# estreita o bastante para virar uma "parede invisível" (a arte pintada mostra
# piso aberto, mas a colisão não conectava). Alarguei rect6/rect7/rect1 nesse trecho.
const WALK := [Rect2(145,210,1390,830),Rect2(1530,515,202,525),Rect2(0,521,250,166),Rect2(1700,537,227,137),Rect2(1255,0,130,220),Rect2(392,0,116,220),Rect2(1562,278,283,187),Rect2(1655,420,90,120)]
const BLOCKS := [Rect2(398,244,205,202),Rect2(879,272,231,140),Rect2(1018,169,151,92),Rect2(1202,542,208,134),Rect2(490,818,330,132),Rect2(1260,800,265,230),Rect2(1724,305,125,124),Rect2(1510,465,125,65),Rect2(170,184,119,54),Rect2(1490,175,44,127),Rect2(160,383,57,76),Rect2(160,927,55,104),Rect2(1668,899,60,135)]
static func bounds(sim) -> Rect2:
	return Rect2(ORIGIN+sim.room_offsets.get("cranes",Vector2.ZERO),SIZE)
static func rect(sim, source: Rect2) -> Rect2:
	return Rect2(bounds(sim).position+source.position*SCALE,source.size*SCALE)
static func apron(sim) -> Rect2:
	return Rect2(Vector2(3800,5580)+sim.room_offsets.get("cranes",Vector2.ZERO),Vector2(400,143))
static func active(sim) -> bool:
	return sim.layout_manifest.get("version","")=="fixed-art-pilot-v1"
static func install(sim) -> void:
	# Old materialized expeditions retain their exact room placement and geometry.
	if not active(sim):
		sim.scenario_geometry_revision=4
		return
	var area := bounds(sim)
	var floors := []
	for floor_rect in sim.floors: floors.append_array(Cut.subtract(floor_rect,area))
	for source in WALK: floors.append(rect(sim,source))
	floors.append(apron(sim)); sim.floors=floors
	for i in range(sim.obstacles.size()-1,-1,-1):
		if not area.has_point(sim.obstacles[i].get_center()): continue
		if sim.obstacle_kinds[i].begins_with("wall_crack_"):
			var old: Rect2=sim.obstacles[i]
			sim.obstacles[i]=Rect2(Vector2(rect(sim,Rect2(392,0,116,220)).position.x,old.position.y),Vector2(116*SCALE,old.size.y)); continue
		sim.obstacles.remove_at(i); sim.obstacle_kinds.remove_at(i); sim.obstacle_hp.remove_at(i)
	for source in BLOCKS:
		sim.obstacles.append(rect(sim,source)); sim.obstacle_kinds.append("cranes_baked"); sim.obstacle_hp.append(-1.0)
	sim.decor=sim.decor.filter(func(d): return not area.has_point(d.p))
	for door in sim.doors:
		if door.room!="cranes": continue
		match door.side:
			"left": door.r=rect(sim,Rect2(230,521,18,166))
			"right": door.r=rect(sim,Rect2(1715,537,18,137))
			"top": door.r=rect(sim,Rect2(392 if door.r.get_center().x<area.position.x+1000 else 1255,55,116 if door.r.get_center().x<area.position.x+1000 else 130,18))
	sim.ob_grid_count=-1
	# Existing saved actors and seeded enemies must not start inside painted cargo.
	for field in [sim.actors,sim.enemies,sim.pickups,sim.chests]:
		for item in field:
			if not area.has_point(item.p) or sim.clear_at(item.p,24): continue
			var start: Vector2=item.p
			var found := false
			for radius in range(32,801,32):
				for step in 16:
					var candidate: Vector2=start+Vector2.from_angle(TAU*step/16.0)*radius
					if area.has_point(candidate) and sim.clear_at(candidate,24): item.p=candidate; found=true; break
				if found: break
	sim.scenario_geometry_revision=4
