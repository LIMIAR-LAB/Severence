extends SceneTree
const Cellar = preload("res://scripts/scenarios/cellar_platforms.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error("FAIL: "+label)
	else: print("PASS: ",label)
func jump(sim, actor: Dictionary, start: Vector2, frames_moving: int = 40) -> void:
	actor.p=start; actor.jump=0.0; actor.jump_cd=0.0; actor.hurt=0.0
	for frame in 41:
		sim.step_actor(actor,{"move":Vector2.UP if frame<frames_moving else Vector2.ZERO,"jump":frame==0,"aim":Vector2.RIGHT},1.0/60.0)
func _init() -> void:
	var sim := Expedition.new(); sim.start_run(1941)
	var a: Dictionary = sim.actors[0]
	check(Cellar.active(sim),"new run installs cellar geometry")
	check(Cellar.platforms(sim).size()==4,"shared four solid platforms")
	var origin := Cellar.bounds(sim).position
	var water := origin+Vector2(1250,840)
	check(not sim.clear_at(water,11) and sim.clear_at(water,11,true),"water blocks ground but permits flight")
	check(not sim.clear_at(origin+Vector2(1250,885),11),"body radius cannot overlap water")
	var grounded := origin+Vector2(1250,900)
	check(sim.move_body(grounded,Vector2(0,-180),11).y>=origin.y+891,"walking cannot cross channel")
	for local_y in [900,650,390]:
		jump(sim,a,origin+Vector2(1250,local_y))
		check(sim.clear_at(a.p,11) and a.p.y<origin.y+local_y-130,"existing jump lands on next platform "+str(local_y))
	var takeoff := origin+Vector2(1250,900)
	jump(sim,a,takeoff,15)
	check(a.p.distance_to(takeoff)<1 and sim.clear_at(a.p,11),"failed landing returns to safe takeoff")
	a.p=takeoff; a.jump=0; Cellar.remember(sim,a)
	var b: Dictionary=sim.actors[1]; b.p=origin+Vector2(1200,950); Cellar.remember(sim,b)
	check(a.cellar_checkpoint!=b.cellar_checkpoint,"coop actors have separate checkpoints")
	a.p=water; a.jump=0.02; a.jump_from=takeoff
	var saved: Dictionary=sim.snapshot().duplicate(true)
	var restored := Expedition.new(); restored.apply_snapshot(saved)
	var ra: Dictionary=restored.actors[0]
	restored.step_actor(ra,{"move":Vector2.ZERO},0.03)
	check(ra.p==takeoff and restored.clear_at(ra.p,11),"midair snapshot restores safe landing")
	check(restored.gaps==sim.gaps,"snapshot preserves materialized water geometry")
	sim.obstacles.append(Rect2(takeoff-Vector2(20,20),Vector2(40,40))); sim.obstacle_kinds.append("test"); sim.obstacle_hp.append(-1); sim.ob_grid_count=-1
	a.p=water; a.jump_from=takeoff
	check(Cellar.recover(sim,a) and a.p!=takeoff and sim.clear_at(a.p,11),"blocked checkpoint finds another solid base")
	var legacy: Dictionary=saved.duplicate(true); legacy.layout_manifest.erase("cellar_platforms_version")
	restored.apply_snapshot(legacy)
	check(not Cellar.active(restored) and restored.gaps==legacy.gaps,"old snapshot is not migrated")
	check(not Cellar.water_at(sim,sim.run_points.spawn,11),"other rooms outside feature")
	print("CELLAR_PLATFORM_FAILURES ",failures)
	quit(0 if failures==0 else 1)
