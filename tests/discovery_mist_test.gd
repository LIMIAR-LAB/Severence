extends SceneTree
const Scenery=preload("res://scripts/dock_scenery.gd")
const Mist=preload("res://scripts/discovery_mist.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	run.call_deferred()
func run() -> void:
	var sim:=Expedition.new(); sim.procedural_enabled=true; sim.coop="solo"; sim.start_run(1941)
	sim.visited=["entry"]; sim.actors[0].p=Vector2(1000,5740); sim.tick_time=4
	var scenery:=Scenery.new(); var mist:=Mist.new()
	var floors:=scenery.visible_floors(sim,scenery.discovered_rooms(sim))
	var original:=floors.duplicate()
	var found:=false
	for rect: Rect2 in floors:
		if rect.has_point(Vector2(1000,5500)):
			found=true
			check(Mist.floor_owner(sim,rect)=="chapel","authored overhang belongs to chapel")
			check(not Mist.floor_is_discovered(sim,rect),"unknown chapel fallback hidden")
	check(found,"real north approach fixture exists")
	var regions:=mist.regions(sim,floors,scenery.reveal_at)
	check(not regions.is_empty(),"unknown transition has mist")
	check(floors==original,"mist leaves logical discovery unchanged")
	check(sim.visited==["entry"] and not sim.secret_open,"mist does not discover rooms or secrets")
	var paths:=mist.clear_paths(sim,floors,Rect2(400,5000,1200,1300))
	check(paths.any(func(rect):return rect.has_point(Vector2(1000,5500))),"north path center remains readable under fog")
	check(paths.any(func(rect):return rect.has_point(Vector2(1000,5740))),"return path remains readable under fog")
	for path: Rect2 in paths:
		check(sim.floors.any(func(rect):return rect.encloses(path)),"clear lane stays on physical floor")
		check(not sim.gaps.any(func(rect):return rect.intersects(path)),"clear lane never bridges a gap")
		check(not sim.obstacles.any(func(rect):return rect.intersects(path)),"clear lane never crosses a wall")
	check(mist.texture()==mist.texture(),"cloud texture allocated once")
	var pixels:=mist.texture().get_image()
	check(pixels.get_pixel(0,0).a==0 and pixels.get_pixel(191,191).a==0,"texture edges fully transparent")
	sim.visited.append("chapel"); scenery.discovered_rooms(sim)
	var initial:=mist.regions(sim,floors,scenery.reveal_at)
	sim.tick_time+=0.6
	var fading:=mist.regions(sim,floors,scenery.reveal_at)
	check(fading.size()==initial.size(),"reveal retains frontier while dissipating")
	check(Mist.reveal_alpha(sim,"chapel",scenery.reveal_at)>0.0 and Mist.reveal_alpha(sim,"chapel",scenery.reveal_at)<1.0,"reveal alpha decreases to a positive intermediate value")
	var room_fade:=mist.reveal_regions(sim,scenery.reveal_at)
	check(room_fade.any(func(region):return region.owner=="chapel" and region.rect.has_point(Vector2(600,4000))),"full chapel interior fades beyond corridor routes")
	check(room_fade.any(func(region):return region.owner=="chapel" and region.rect.has_point(Vector2(1300,5200))),"chapel wing fades with room")
	sim.tick_time+=2
	for rect: Rect2 in floors:
		if Mist.floor_owner(sim,rect)=="chapel": check(Mist.floor_is_discovered(sim,rect),"visited chapel renders authored floor")
	for region in mist.regions(sim,floors,scenery.reveal_at):
		check(not region.rect.has_point(Vector2(1000,5500)),"known chapel frontier clears")
	sim.tick_time=0; sim.visited=["entry"]; scenery.discovered_rooms(sim)
	check(not scenery.reveal_at.has("chapel"),"new expedition clears old reveal timestamps")
	sim.mode="hub"
	check(mist.regions(sim,floors,scenery.reveal_at).is_empty(),"hub has no discovery fog")
	check(mist.reveal_regions(sim,scenery.reveal_at).is_empty(),"hub has no room fade")
	sim.mode="run"; sim.visited=["touch_from"]
	sim.rooms=[{"id":"touch_from","r":Rect2(20000,20000,100,200),"kind":"fight"},{"id":"touch_to","r":Rect2(20300,20000,100,200),"kind":"fight"}]
	sim.floors=[Rect2(20000,20000,100,200),Rect2(20100,20050,200,100),Rect2(20300,20000,100,200)]
	sim.run_corridors=[Rect2(20100,20050,200,100)]
	var touch_regions:=mist.regions(sim,[sim.floors[0],sim.floors[1]],{})
	check(touch_regions.any(func(region):return region.rect.has_point(Vector2(20299,20100)) and region.alpha>0),"abutting horizontal destination gets frontier mist without positive floor overlap")
	print("DISCOVERY_MIST_TEST failures=",failures); quit(1 if failures else 0)
