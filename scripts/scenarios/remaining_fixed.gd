extends RefCounted
## Fixed paintings with source-space collision traces. Sources are measured on
## 1600px inspection previews; textures remain untouched at native resolution.
const Pilot=preload("res://scripts/scenarios/cranes_fixed.gd")
const Cut=preload("res://scripts/scenarios/sanctuary_fixed.gd")
const Art=preload("res://scripts/scenarios/corridor_art.gd")
const Cellar=preload("res://scripts/scenarios/cellar_platforms.gd")
const PassagePreview=preload("res://scripts/scenarios/passage_preview.gd")
const ROOT="res://assets/environment/docks12/remaining_fixed_v01/"
const VERSION=1
const MUD=preload("res://assets/environment/docks12/mangue/mng_floor_mud.png")
const DATA={
	"market":{"floor":Rect2(165,235,1240,1045),"tile":Rect2(620,760,160,128),"blocks":[Rect2(270,300,300,250),Rect2(810,450,390,280),Rect2(490,960,330,245)]},
	"shop":{"floor":Rect2(180,290,1230,990),"tile":Rect2(850,900,180,100),"blocks":[Rect2(220,290,400,260),Rect2(900,290,400,310),Rect2(280,930,515,335)]},
	"generator":{"floor":Rect2(180,245,1220,1060),"tile":Rect2(760,350,160,128),"blocks":[Rect2(340,270,350,355),Rect2(950,780,340,370)]},
	"ammo":{"floor":Rect2(180,240,1270,1070),"tile":Rect2(700,620,160,128),"blocks":[Rect2(320,290,330,270),Rect2(920,330,310,240),Rect2(555,905,505,230)]},
	"rails":{"floor":Rect2(130,235,1320,995),"tile":Rect2(680,700,160,128),"blocks":[Rect2(285,345,375,205),Rect2(800,885,390,250),Rect2(1250,235,50,240),Rect2(1250,445,135,40)]},
	"stairs":{"floor":Rect2(160,245,1280,1090),"tile":Rect2(700,1100,160,128),"blocks":[Rect2(190,245,490,355),Rect2(880,1005,280,220)]},
	"drydock":{"floor":Rect2(135,330,1300,1020),"tile":Rect2(175,365,160,128),"blocks":[Rect2(1020,330,415,700),Rect2(345,545,510,78),Rect2(345,620,35,510),Rect2(800,620,55,510),Rect2(345,1120,510,65)],"pit":Rect2(380,623,420,497)},
	"cellar":{"floor":Rect2(390,230,1110,1090),"tile":Rect2(690,615,120,60),"blocks":[]},
	"secret":{"floor":Rect2(185,260,1230,960),"tile":Rect2(650,900,160,128),"blocks":[Rect2(205,260,330,320),Rect2(990,310,370,440)]},
	"antessala":{"floor":Rect2(160,260,1235,1030),"tile":Rect2(520,1060,160,128),"blocks":[Rect2(225,340,250,360),Rect2(920,275,245,335)]}
}
var textures: Dictionary={}

static func active(sim) -> bool:
	return Pilot.active(sim) and sim.layout_manifest.get("remaining_fixed_version",0)==VERSION
static func owns(sim, id: String) -> bool: return active(sim) and DATA.has(id)
static func owns_rect(sim, area: Rect2) -> bool:
	if not active(sim): return false
	for id in DATA:
		var room: Dictionary=sim.room_by_id(id)
		for r: Rect2 in [room.r]+room.get("extra",[]):
			if r.encloses(area): return true
	return false
static func image_area(sim, id: String) -> Rect2:
	var room: Rect2=sim.room_by_id(id).r
	var source: Rect2=DATA[id].floor
	var scale_factor:=minf(room.size.x/source.size.x,room.size.y/source.size.y)
	var size:=source.size*scale_factor
	var origin:=room.get_center()-size*0.5
	# Leave the market's fixed north doorway east of the first fish stall.
	if id=="market": origin.x=room.position.x
	return Rect2(origin,size)
static func source_rect(sim, id: String, source: Rect2) -> Rect2:
	var area:=image_area(sim,id)
	var original: Rect2=DATA[id].floor
	var factor:=area.size.x/original.size.x
	return Rect2(area.position+(source.position-original.position)*factor,source.size*factor)
static func safe_point(sim, room: Rect2, point: Vector2, radius:=24.0) -> Vector2:
	if room.grow(-radius).has_point(point) and sim.clear_at(point,radius): return point
	var best:=point; var distance:=INF
	for y in range(int(room.position.y)+40,int(room.end.y)-39,40):
		for x in range(int(room.position.x)+40,int(room.end.x)-39,40):
			var p:=Vector2(x,y)
			if p.distance_squared_to(point)<distance and sim.clear_at(p,radius): best=p; distance=p.distance_squared_to(point)
	return best
static func install(sim) -> void:
	if not Pilot.active(sim): return
	for id in DATA:
		if not ResourceLoader.exists(ROOT+id+".png"): return
	sim.layout_manifest["remaining_fixed_version"]=VERSION
	sim.layout_manifest.fixed_rooms.append_array(DATA.keys())
	for id in DATA:
		var room: Rect2=sim.room_by_id(id).r
		for i in range(sim.obstacles.size()-1,-1,-1):
			if not room.has_point(sim.obstacles[i].get_center()): continue
			if sim.obstacle_kinds[i].begins_with("wall_crack_"): continue
			sim.obstacles.remove_at(i); sim.obstacle_kinds.remove_at(i); sim.obstacle_hp.remove_at(i)
		for source in DATA[id].blocks:
			sim.obstacles.append(source_rect(sim,id,source)); sim.obstacle_kinds.append("remaining_baked"); sim.obstacle_hp.append(-1.0)
		sim.decor=sim.decor.filter(func(d):return not room.has_point(d.p))
		if id=="drydock":
			sim.gaps=sim.gaps.filter(func(g):return not room.has_point(g.get_center()))
			sim.gaps.append(source_rect(sim,id,DATA[id].pit))
		sim.ob_grid_count=-1
		for collection in [sim.actors,sim.enemies,sim.pickups,sim.chests,[sim.mech]]:
			for item in collection:
				if room.has_point(item.p) and not sim.clear_at(item.p,24): item.p=safe_point(sim,room,item.p)
		for hazard in sim.hazards:
			if room.has_point(hazard.p) and not sim.clear_at(hazard.p,24): hazard.p=safe_point(sim,room,hazard.p)
	# Interaction points must remain reachable beside the new machines.
	for key in ["shop","side","ammo_center","warden"]:
		var p: Vector2=sim.run_points[key]
		var room: Dictionary=sim.room_at(p)
		if not room.is_empty() and DATA.has(room.id): sim.run_points[key]=safe_point(sim,room.r,p)
	sim.scenario_geometry_revision=6

func texture(id: String) -> Texture2D:
	if not textures.has(id): textures[id]=load(ROOT+id+".png")
	return textures[id]
static func native(rect: Rect2) -> Rect2: return Rect2(rect.position*1.28,rect.size*1.28)
func region(ci: CanvasItem, tex: Texture2D, target: Rect2, source: Rect2, view: Rect2) -> void:
	var clip:=target.intersection(view)
	if not clip.has_area(): return
	var ratio:=source.size/target.size
	ci.draw_texture_rect_region(tex,clip,Rect2(source.position+(clip.position-target.position)*ratio,clip.size*ratio))
func material_fill(ci: CanvasItem, id: String, area: Rect2, view: Rect2, alpha:=1.0) -> void:
	Art.tiles(ci,area,view,texture(id),native(DATA[id].tile),1.0/1.28,Color(1,1,1,alpha))
func backdrop(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	if not active(sim): return
	var reserved:=Art.protected(sim)
	for room in sim.rooms: reserved.append(room.r); reserved.append_array(room.get("extra",[]))
	var painted:=[]
	for room in rooms:
		if not DATA.has(room.id) and room.id not in ["forest","bridge"]: continue
		if not room.r.grow(650).intersects(view): continue
		for part in Art.pieces_outside(room.r.grow(650).intersection(view),reserved+painted):
			Art.tiles(ci,part,view,Art.STONE,Art.WATER_SOURCE,Art.SCALE,Color("8fa9a6"),true)
			painted.append(part)
func frame(ci: CanvasItem, sim, id: String, area: Rect2, view: Rect2) -> void:
	var points: Array=[area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)]
	var normals: Array=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
	for side in 4:
		var a: Vector2=points[side]; var b: Vector2=points[(side+1)%4]
		var tangent: Vector2=(b-a).normalized()
		for run in ci.scenery.wall_runs(sim.floors,a,b,normals[side]):
			var p: Vector2=a+tangent*run.x; var q: Vector2=a+tangent*run.y
			if not Rect2(p,q-p).abs().grow(120).intersects(view): continue
			if side==0:
				var north:=Rect2(p-Vector2(0,100),Vector2(q.x-p.x,100))
				var sample:=Rect2(590,125,160,100)
				if id=="stairs": sample=Rect2(700,125,160,100)
				if id=="drydock": sample=Rect2(480,230,160,100)
				if id=="cellar": sample=Rect2(505,95,160,130)
				Art.tiles(ci,north,view,texture(id),native(sample),1.0/1.28)
			else: Art.boundary(ci,p,q,normals[side],view)
			for n in range(70,int(run.y-run.x),420):
				var light: Vector2=p+tangent*n+normals[side]*12
				ci.draw_texture_rect(ci.dock_art.lamp,Rect2(light-Vector2(9,24),Vector2(18,30)),false)
				ci.scenery.lights.append({"p":light,"kind":"bulb"})
func cellar_ground(ci: CanvasItem, sim, view: Rect2) -> void:
	var room: Rect2=Cellar.bounds(sim)
	Art.tiles(ci,room,view,Art.STONE,Art.WATER_SOURCE,Art.SCALE,Color("91b4a8"),true)
	for platform: Rect2 in Cellar.platforms(sim):
		region(ci,texture("cellar"),platform,native(Rect2(577,548,584,150)),view)
		# The pale rim stays inside the exact safe rectangle; no bridge across gaps.
		ci.draw_rect(platform.grow(-3),Color("89958d"),false,6)
		var face:=Rect2(platform.position.x,platform.end.y,platform.size.x,24)
		Art.tiles(ci,face,view,Art.STONE,Rect2(790,1120,150,62),0.4,Color("879c95"))
	frame(ci,sim,"cellar",room,view)
func ground(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	if not active(sim): return
	PassagePreview.draw(ci,sim,self,view)
	routes_ground(ci,sim,rooms,view)
	for room in rooms:
		var id: String=room.id
		if not DATA.has(id) or not room.r.grow(150).intersects(view): continue
		for extra: Rect2 in room.get("extra",[]):
			material_fill(ci,id,extra,view); frame(ci,sim,id,extra,view)
		if id=="cellar" and Cellar.active(sim): cellar_ground(ci,sim,view); continue
		material_fill(ci,id,room.r,view)
		region(ci,texture(id),image_area(sim,id),native(DATA[id].floor),view)
		frame(ci,sim,id,room.r,view)
		if id=="stairs":
			var upper:=Rect2(180,0,510,245)
			region(ci,texture(id),source_rect(sim,id,upper),native(upper),view)

func routes_ground(ci: CanvasItem, sim, rooms: Array, view: Rect2) -> void:
	for room in rooms:
		if room.id not in ["forest","bridge"] or not room.r.grow(80).intersects(view): continue
		var area: Rect2=room.r
		if room.id=="forest":
			Art.tiles(ci,area,view,MUD,Rect2(4,4,56,56),1.25,Color("91a098"),true)
			var trail:=Rect2(area.position.x,area.get_center().y-88,area.size.x,176)
			material_fill(ci,"shop",trail,view)
			for y in [trail.position.y,trail.end.y]: ci.draw_line(Vector2(maxf(area.position.x,view.position.x),y),Vector2(minf(area.end.x,view.end.x),y),Color("2b241c"),8)
		else:
			var sea:=Rect2(area.position-Vector2(0,140),area.size+Vector2(0,280))
			Art.tiles(ci,sea,view,Art.STONE,Art.WATER_SOURCE,Art.SCALE,Color("8fa9a6"),true)
			for part in Art.pieces_outside(area,sim.bridge_broken): material_fill(ci,"shop",part,view)
			for segment: Rect2 in sim.bridge_segments():
				if segment in sim.bridge_broken or not segment.intersects(view): continue
				ci.draw_rect(Rect2(segment.position,Vector2(7,segment.size.y)),Color("25282b"))
				for y in [segment.position.y+14,segment.end.y-14]:
					ci.draw_circle(Vector2(segment.position.x+3,y),3,Color("a28a67"))
			if sim.bridge_timer>=0 and not sim.bridge_done and sim.bridge_broken.size()<sim.bridge_segments().size():
				var next: Rect2=sim.bridge_segments()[sim.bridge_broken.size()]
				ci.draw_rect(next,Color(1,0.3,0.2,0.18+0.18*sin(sim.tick_time*14)))
				ci.draw_rect(next,Color(1,0.6,0.3,0.55),false,2)
		var edge_areas: Array=Art.pieces_outside(area,sim.bridge_broken) if room.id=="bridge" else [area]
		for edge: Rect2 in edge_areas:
			for y in [edge.position.y,edge.end.y]:
				var upper: bool=y==edge.position.y
				Art.boundary(ci,Vector2(edge.position.x,y),Vector2(edge.end.x,y),Vector2.UP if upper else Vector2.DOWN,view)
