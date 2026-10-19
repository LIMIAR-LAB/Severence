extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const Ray=preload("res://scripts/ray_encounter.gd")
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func fixture():
	var s:=Sim.new(); s.coop="solo"; s.start_run(42)
	s.enemies.clear(); s.obstacles.clear(); s.obstacle_kinds.clear(); s.obstacle_hp.clear(); s.ob_grid_count=-1
	s.gaps.clear(); s.doors.clear(); s.gate_blocks.clear(); s.pending_spawns.clear(); s.combat_zones.clear(); s.effects.clear()
	s.rooms=[{"id":"cranes","kind":"combat","r":Rect2(0,0,1200,1000),"cleared":false,"locked":false}]
	s.floors=[Rect2(0,0,1200,1000)]; s.actors[0].p=Vector2(500,500); s.actors[0].facing=Vector2.RIGHT
	s.spawn_enemy(Vector2(750,500),"golem"); s.spawn_enemy(Vector2(300,500),"cult")
	return s
func _init() -> void:
	var saved_hash:=FileAccess.get_sha256("user://expedition.save")
	var s=fixture(); var e: Dictionary=s.enemies[0]; var a: Dictionary=s.actors[0]
	check(s.room_threats("cranes")==1,"Dormant Ray excluded from normal room clear")
	s.hurt_enemy(e,999); check(e.hp==e.max,"Dormant Ray cannot be damaged before encounter")
	Ray.step(s,e,10); check(e.ray_state=="waiting" and s.bullets.is_empty(),"Proximity cannot wake Ray during normal fight")
	s.robobolas=1; e.stunned=true; s.capture_robot(a,e)
	check(s.robobolas==1 and s.enemies.has(e),"Early capture rejected even with an invalid stunned flag")
	e.stunned=false; s.enemies.remove_at(1); s.step_gates()
	check(s.rooms[0].cleared and not s.rooms[0].locked,"Room clears and opens with Ray still present")
	Ray.step(s,e,0.01); check(e.ray_state=="active" and not e.dormant,"Encounter activates after clear")
	check(s.room_threats("cranes")==0,"Optional duel cannot softlock room clear")
	for i in 110: Ray.step(s,e,0.016)
	check(s.bullets.any(func(b):return b.team==1 and b.damage>=s.HEART),"Cannon volley poses real heart damage")
	e.ray_phase="recover"; e.ray_timer=0; e.ray_cycle=1; Ray.step(s,e,0.016)
	check(s.combat_zones.size()==3 and s.combat_zones.all(func(z):return z.warning>=0.9),"Three missile impacts have reaction warnings")
	check(s.bullets.filter(func(b):return b.get("ray_missile",false)).size()==3,"Missiles have visible airborne projectiles")
	s.combat_zones.clear(); e.ray_phase="recover"; e.ray_timer=0; e.ray_cycle=2
	Ray.step(s,e,0.016)
	var destination: Vector2=e.ray_destination
	check(destination.x<a.p.x and s.enemy_room_position_valid(e,destination,26),"Teleport reserves valid floor behind player")
	var before: Vector2=e.p; Ray.step(s,e,0.3)
	check(e.p==before,"Teleport does not happen before warning")
	Ray.step(s,e,0.2); check(e.p==destination,"Ray teleports after readable warning")
	var hp: float=a.hp; s.step_combat_zones(0.71); s.step_combat_zones(0.01)
	check(a.hp<=hp-s.HEART,"Teleport blast deals at least a heart")
	check(e.hp==e.max,"Ray cannot damage itself with its explosion")
	var zone: Dictionary={"p":a.p,"r":150.0,"damage":s.HEART,"ray_owner":e.id}
	hp=a.hp; a.invuln=1; Ray.resolve_zone(s,zone); check(a.hp==hp,"Blast respects invulnerability")
	a.invuln=0; a.hurt=0; s.obstacles=[Rect2(a.p-Vector2(50,100),Vector2(20,200))]; s.ob_grid_count=-1
	zone.p=a.p-Vector2(80,0); Ray.resolve_zone(s,zone); check(a.hp==hp,"Blast respects walls")
	s.obstacles.clear(); s.ob_grid_count=-1
	var restored:=Sim.new(); restored.apply_snapshot(s.snapshot().duplicate(true))
	var saved_ray: Dictionary=restored.enemies[0]
	check(saved_ray.ray_state==e.ray_state and saved_ray.ray_phase==e.ray_phase,"Save preserves active encounter phase")
	s.hurt_enemy(e,9999); s.step_enemies(0.016)
	check(e.stunned and e.hp>0,"Defeat leaves robot stunned for recruitment")
	s.capture_robot(a,e); check(s.story_flags.get("titan_chassis",false) and not s.enemies.has(e) and s.robobolas==1,"Cult Titan recovery secures chassis without consuming a roboball")
	var legacy=fixture(); var old: Dictionary=legacy.enemies[0]; old.stunned=true
	legacy.robobolas=1; legacy.capture_robot(legacy.actors[0],old)
	check(legacy.story_flags.get("titan_chassis",false),"Previously defeated legacy machine remains recoverable")
	var replay=fixture(); var replay_ray: Dictionary=replay.enemies[0]
	replay.enemies=[replay_ray]; replay.rooms[0].cleared=true; replay.story_flags["missao_robo"]="invocar"
	Ray.step(replay,replay_ray,0.01)
	check(replay.story_flags.missao_robo=="invocar","Encounter cannot reset recruitment rewards")
	replay.floors=[]
	check(not Ray.blink_point(replay,replay_ray,replay.actors[0]).is_finite(),"No valid floor cancels teleport safely")
	replay_ray.room="market"
	check(not Ray.owns(replay,replay_ray),"Other robot encounters keep existing behavior")
	check(FileAccess.get_sha256("user://expedition.save")==saved_hash,"User save remains untouched")
	print("RAY_ENCOUNTER checks=",checks," failures=",failures); quit(1 if failures else 0)
