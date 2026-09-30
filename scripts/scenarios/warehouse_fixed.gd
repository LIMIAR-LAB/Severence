extends RefCounted
## Candidate 572ccb09. Traced in 1600-square preview coordinates, uniform native scale.
const TEXTURE="res://assets/environment/docks12/warehouse/fixed_v01/warehouse.png"
const ORIGIN:=Vector2(4700,5840)
const SIZE:=Vector2(1600,1600)
const Cut=preload("res://scripts/scenarios/sanctuary_fixed.gd")
const Pilot=preload("res://scripts/scenarios/cranes_fixed.gd")
const WALK: Array=[Rect2(187,255,1244,921),Rect2(0,563,190,202),Rect2(1428,565,172,210),Rect2(460,0,132,262),Rect2(187,1100,405,206)]
const BLOCKS: Array=[Rect2(335,441,286,238),Rect2(750,397,365,153),Rect2(628,717,299,155),Rect2(960,895,328,159),Rect2(650,205,450,143),Rect2(1110,210,288,110),Rect2(186,210,184,82),Rect2(183,367,48,78),Rect2(1380,310,60,155),Rect2(187,1105,97,195),Rect2(530,1132,62,174),Rect2(193,935,81,95),Rect2(185,994,110,110),Rect2(504,994,90,110),Rect2(589,994,34,182)]
static func active(sim) -> bool: return Pilot.active(sim)
static func bounds(sim) -> Rect2: return Rect2(ORIGIN,SIZE)
static func rect(source: Rect2) -> Rect2: return Rect2(ORIGIN+source.position,source.size)
static func apron() -> Rect2: return Rect2(5100,5780,192,61)
static func install(sim) -> void:
	if not active(sim):
		sim.scenario_geometry_revision=5; return
	var area:=bounds(sim)
	var floors:=[]
	for floor_rect in sim.floors: floors.append_array(Cut.subtract(floor_rect,area))
	for source in WALK: floors.append(rect(source))
	floors.append(apron()); sim.floors=floors
	# Match the painted east opening with the whole passage to the market.
	var old_link:=Rect2(6300,6300,300,200)
	var east_link:=Rect2(6300,6405,300,210)
	for i in sim.floors.size():
		if sim.floors[i]==old_link: sim.floors[i]=east_link
	for i in sim.run_corridors.size():
		if sim.run_corridors[i]==old_link: sim.run_corridors[i]=east_link
	for i in range(sim.obstacles.size()-1,-1,-1):
		if not area.has_point(sim.obstacles[i].get_center()): continue
		if sim.obstacle_kinds[i].begins_with("wall_crack_"):
			var old: Rect2=sim.obstacles[i]
			sim.obstacles[i]=Rect2(5160,old.position.y,132,old.size.y); continue
		sim.obstacles.remove_at(i); sim.obstacle_kinds.remove_at(i); sim.obstacle_hp.remove_at(i)
	for source in BLOCKS:
		sim.obstacles.append(rect(source)); sim.obstacle_kinds.append("warehouse_baked"); sim.obstacle_hp.append(-1.0)
	sim.decor=sim.decor.filter(func(d):return not area.has_point(d.p))
	for door in sim.doors:
		if door.room=="market" and door.side=="left":
			door.r=Rect2(door.r.position.x,east_link.position.y,door.r.size.x,east_link.size.y)
		if door.room!="warehouse": continue
		match door.side:
			"left": door.r=rect(Rect2(150,563,18,202))
			"right": door.r=rect(Rect2(1450,565,18,210))
	for chest in sim.chests:
		if area.has_point(chest.p): chest.p=Vector2(6040,6320)
	for hazard in sim.hazards:
		if area.has_point(hazard.p) and hazard.get("trap","")=="darts": hazard.p=Vector2(5700,6420)
	sim.ob_grid_count=-1
	for field in [sim.actors,sim.enemies,sim.pickups,[sim.mech]]:
		for item in field:
			if not area.has_point(item.p) or sim.clear_at(item.p,24): continue
			var start: Vector2=item.p
			var found:=false
			for radius in range(32,801,32):
				for step in 16:
					var candidate:=start+Vector2.from_angle(TAU*step/16.0)*radius
					if area.has_point(candidate) and sim.clear_at(candidate,24): item.p=candidate; found=true; break
				if found: break
	sim.scenario_geometry_revision=5
