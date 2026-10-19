extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func fixture():
	var s:=Sim.new(); s.coop="ai"; s.start_arena(); s.mode="run"
	s.enemies.clear(); s.pending_spawns.clear(); s.obstacles.clear(); s.obstacle_kinds.clear()
	s.ob_grid_count=-1; s.gaps.clear(); s.harpoons.clear(); s.tentacle_gates.clear(); s.combat_zones.clear()
	s.rooms=[{"id":"fight","kind":"fight","r":Rect2(100,100,400,400),"locked":false,"cleared":false}]
	s.floors=[Rect2(100,100,400,400),Rect2(0,250,100,100)]
	s.doors=[{"room":"fight","side":"left","r":Rect2(100,250,30,100)}]; s.gate_blocks.clear()
	s.actors[0].p=Vector2(155,300); s.actors[1].p=Vector2(60,300)
	s.spawn_enemy(Vector2(430,430),"cult")
	return s
func _init() -> void:
	var hash_before:=FileAccess.get_sha256("user://expedition.save")
	var s=fixture(); var a: Dictionary=s.actors[1]
	s.step_gates()
	check(s.rooms[0].locked,"Enemy encounter closes gate")
	check(s.room_contains(s.rooms[0],a.p,-11) and s.clear_at(a.p,11),"Follower enters valid space after gate closes")
	a.p=Vector2(60,300); s.ai_path=PackedVector2Array([Vector2(60,300)]); s.ai_path_timer=5
	s.step_gates()
	check(s.room_contains(s.rooms[0],a.p,-11),"Late follower recovers when room was already locked")
	check(s.ai_path.is_empty() and s.ai_path_timer==0,"Old path through closed gate is discarded")
	var inside: Vector2=a.p; s.step_gates(); check(a.p==inside,"Follower already inside is not moved repeatedly")
	a.p=Vector2(115,300); a.mech=true; s.mech.occupant=1
	s.step_gates(); check(s.clear_at(a.p,23) and s.mech.p==a.p,"Titan follower fits through recovery and vehicle stays aligned")
	a.mech=false; a.dead=true; a.p=Vector2(60,300); s.step_gates()
	check(a.p==Vector2(60,300) and a.dead,"Fallen companion is not moved or revived")
	a.dead=false; s.coop="local"; s.step_gates()
	check(a.p==Vector2(60,300),"Human local partner is unaffected by AI catch-up")
	s.coop="ai"; s.rooms[0].locked=false; s.rooms[0].cleared=true; s.refresh_gate_blocks(); s.step_gates()
	check(a.p==Vector2(60,300),"Open room does not teleport follower")
	var boss=fixture(); boss.rooms[0].id="boss"; boss.enemies[0].room="boss"; boss.doors[0].room="boss"
	boss.rooms.append({"id":"bridge","kind":"bridge","r":Rect2(900,900,100,100)})
	boss.step_gates()
	check(boss.rooms[0].locked and boss.room_contains(boss.rooms[0],boss.actors[1].p,-11),"Boss room includes delayed AI despite split-route rule")
	check(FileAccess.get_sha256("user://expedition.save")==hash_before,"Saved expedition untouched")
	print("AI_CLOSED_GATE failures=",failures); quit(1 if failures else 0)
