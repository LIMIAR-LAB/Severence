extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: "+label)
	else: print("PASS: "+label)
func _init() -> void:
	var s := Expedition.new()
	s.coop="local"; s.start_run(1941)
	var a: Dictionary=s.actors[0]
	var w: Dictionary=s.enemies.filter(func(e): return e.kind=="warden")[0]
	var death: Vector2=w.p
	w.hp=0; s.step_enemies(0.016)
	var rewards: Array=s.chests.filter(func(c): return c.get("reward",false))
	check(rewards.size()==1 and rewards[0].p==death,"miniboss deixa baú no local da morte")
	s.keys=0; a.p=death; s.interact(a)
	check(rewards[0].open and s.keys==0 and s.weapon_of(a)=="bazooka" and a.run_weapons.bazooka==15,"baú gratuito equipa bazuca temporária")
	check(s.weapon_of(s.actors[1])!="bazooka","troca não altera arma do parceiro")
	var top={"p":a.p,"open":false,"reward":true,"secret":false}
	var before:int=s.materials
	s.open_reward(top,a);s.open_reward(top,a)
	check(s.materials==before+3,"recompensa equivalente paga uma vez")
	check(s.room_by_id("warehouse").kind=="maze" and s.room_by_id("chapel").kind=="story","tipos especiais no mapa")
	for room_id in ["warehouse","chapel"]:
		var room: Dictionary=s.room_by_id(room_id)
		check(not s.enemies.any(func(e): return room.r.has_point(e.p)),room_id+" sem inimigos")
	var trap={"p":Vector2(5300,6800),"r":75.0,"damage":12.0,"trap":"spikes"}
	s.hazards=[trap];a.p=trap.p;a.hp=30;a.hurt=0;a.armor=false;a.jump=0
	s.tick_time=2.5;s.step_hazards(0.016)
	check(a.hp==30 and s.trap_phase(trap)=="warning","aviso da armadilha não fere")
	s.tick_time=3.2;s.step_hazards(0.016)
	check(a.hp<30,"armadilha fere na janela ativa")
	s.story_quest=0;s.dialogue_queue.clear();s.story_interact(a)
	check(s.story_quest==1 and s.dialogue_queue.size()==2,"conversa aceita missão e tem múltiplas falas")
	s.dialogue_queue.clear();s.visited.append("cellar")
	var cellar:Rect2=s.room_by_id("cellar").r
	s.enemies=s.enemies.filter(func(e):return not cellar.has_point(e.p))
	before=s.materials;s.story_interact(a);s.story_interact(a)
	check(s.story_quest==2 and s.materials==before+4,"quest paga uma vez ao retornar")
	var remote:=Expedition.new();remote.apply_snapshot(s.snapshot())
	check(remote.story_quest==2,"quest sincronizada em snapshot")
	s.add_bullet(a.p,Vector2.RIGHT,1,10,100,6)
	check(is_equal_approx(s.bullets[-1].r/s.bullets[-1].visual_r,0.8),"hitbox inimiga 80% do visual")
	var boss:Dictionary=s.enemies.filter(func(e):return e.kind=="boss")[0]
	for ratio in [1.0,0.5,0.2]:
		boss.hp=boss.max*ratio;boss.motion="idle";boss.motion_cd=0.0
		var origin:Vector2=boss.p
		s.boss_motion(boss,a,0.016)
		check(boss.motion=="warning" and boss.motion_t>=0.4,"boss anuncia movimento")
		for i in range(8):s.boss_motion(boss,a,0.05)
		check(boss.p==origin,"boss permanece parado no aviso")
		for i in range(45):s.boss_motion(boss,a,0.05)
		check(boss.p.distance_to(origin)>5 and s.clear_at(boss.p,45),"boss move sem atravessar obstáculo")
	print("UPDATE_017 failures=",failures)
	quit(1 if failures else 0)
