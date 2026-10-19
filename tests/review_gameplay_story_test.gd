extends SceneTree

var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func fixture() -> Expedition:
	var s := Expedition.new()
	s.mode = "arena"; s.coop = "ai"
	s.floors = [Rect2(-1000,-1000,3000,3000)]
	s.obstacles.clear(); s.obstacle_kinds.clear(); s.obstacle_hp.clear()
	s.enemies.clear(); s.bullets.clear(); s.pending_spawns.clear(); s.gate_blocks.clear()
	s.actors = [s.actor(0,Vector2(100,100)),s.actor(1,Vector2(130,100))]
	s.actors[1].active = true
	s.mech = s.new_mech(Vector2(700,700)); s.mech.deployed = false
	s.nav.clear(); s.nav_points.clear()
	return s

func _initialize() -> void:
	var s := fixture()
	var a: Dictionary = s.actors[1]
	a.run_weapons = {"bazooka":0,"tesla":2}; a.run_weapon = "bazooka"
	s.ai_input(); check(a.run_weapon == "tesla", "AI chooses charged weapon")
	a.run_weapons.tesla = 0; s.ai_input(); check(a.run_weapon == "" and s.weapon_of(a) == a.basic_weapon, "AI falls back to basic weapon")
	s.grant_run_weapon(a,"tesla",90); check(a.run_weapons.tesla == 90,"Tesla keeps all 90 reward charges")
	s.grant_run_weapon(a,"tesla",99); check(a.run_weapons.tesla == 180,"Tesla cap stable")
	s.spawn_enemy(Vector2(180,100),"golem")
	var robot: Dictionary = s.enemies[-1]; robot.stunned = true; robot.hp = 60.0
	s.hurt_enemy(robot,999); s.explode(robot.p,80,999,false)
	check(robot.hp == 60 and s.nearest_enemy(a.p).is_empty(),"stunned robot immune and excluded from AI")
	s.add_bullet(robot.p,Vector2.RIGHT,0,999,1,8,0,"p_pistol")
	s.hit_bullet_enemy(s.bullets[-1]); check(robot.hp == 60 and s.bullets[-1].life > 0,"shots pass stunned robot")
	s.actors[0].dead = true; s.actors[0].hp = 0
	s.story_quest = 0; s.mode = "run"; s.rooms = [{"id":"chapel","kind":"story","r":Rect2(0,0,500,500)}]
	var command := s.ai_input(); check(command.get("interact",false) and not command.get("fire",false),"AI prioritizes fallen leader")
	s.interact(a); check(not s.actors[0].dead and s.story_quest == 0,"revive precedes optional interactions")

	s = fixture(); a = s.actors[0]; a.jump = 0.4
	var hp: float = a.hp
	s.damage_actor(a,12,"hazard","acid"); check(a.hp == hp,"normal jump clears acid puddle")
	s.damage_actor(a,12,"fish","harpoon"); check(a.hp < hp,"normal jump does not negate ranged attack")
	for form in ["omega","azul"]:
		a.hurt = 0; a.armor = true; a.armor_type = form; a.shield = 30; hp = a.hp
		s.damage_actor(a,100,"boss","orb")
		check(a.hp == hp and a.shield == 30,"powered airborne immunity preserved: "+form)
	a.armor = false; a.shield = 0; a.hurt = 0; a.jump = 0.4; hp = a.hp
	s.add_bullet(a.p,Vector2.RIGHT,1,12,1,8,-1,"harpoon"); s.step_bullets(0.01)
	check(a.hp < hp,"ranged collision hits airborne normal actor")

	s = fixture(); a = s.actors[0]
	s.spawn_enemy(Vector2(300,100),"brute"); s.spawn_enemy(Vector2(360,100),"brute")
	s.obstacles.append(Rect2(330,40,10,120))
	var behind_hp: float = s.enemies[1].hp
	s.add_bullet(Vector2(300,100),Vector2.RIGHT,0,70,1,8,0,"p_heavy")
	s.bullets[-1].shell_splash = true; s.hit_bullet_enemy(s.bullets[-1])
	check(s.enemies[1].hp == behind_hp,"wall blocks Titan direct-hit splash")
	s.obstacles.clear(); s.ob_grid_count = -1; s.enemies.clear(); s.bullets.clear(); s.effects.clear()
	s.spawn_enemy(Vector2(300,100),"brute"); s.spawn_enemy(Vector2(340,140),"brute")
	behind_hp = s.enemies[1].hp
	s.grant_run_weapon(a,"mosquete",2); a.aim = Vector2.RIGHT; s.fire_actor(a)
	var shot: Dictionary = s.bullets[-1]; shot.p = Vector2(300,100); s.hit_bullet_enemy(shot)
	check(not shot.shell_splash and s.enemies[1].hp == behind_hp and not s.effects.any(func(e):return e.kind == "explosion"),"musket pierces without Titan splash")

	s = fixture(); a = s.actors[0]; s.coop = "online"
	s.visible_world_rect = Rect2(-1000,-1000,20,20)
	s.spawn_enemy(a.p+Vector2(200,0),"brute"); hp = s.enemies[0].hp; s.recall_light(a)
	check(s.enemies[0].hp == hp-s.OMEGA_RECALL_DAMAGE,"online recall independent of host camera")
	check(s.ARMORS.omega.duration == 300 and s.ARMORS.omega.cooldown == 60 and s.ARMORS.omega.speed == 430 and s.OMEGA_SHIELD_HEARTS == 3,"Omega attributes unchanged")

	s = fixture(); a = s.actors[0]; s.bike_npc = {"talked":false}; s.bike = {"riding":false}
	s.story_interact(a); check(s.dialogue_owner == "coral" and s.dialogue_queue.size() == 2,"Coral conversation owned")
	s.bike_npc_interact(a); check(s.message.begins_with("Faísca:") and s.dialogue_owner == "faisca","switching to Faísca clears Coral queue")
	s.story_interact(a); check(s.message.begins_with("Mestre Coral:") and s.dialogue_owner == "coral","switching back never consumes Faísca lines")
	s.story_flags.ordem_pista = true; s.story_interact(a)
	check(s.message.begins_with("Marty:") and s.story_flags.coral_confrontado,"discovery triggers confrontation")
	check(s.dialogue_queue[0].contains("Rompi"),"Coral explains dissidence")
	s.story_flags.peca_titan = true; s.story_flags.simbolo_ordem = true; s.first_victory_beat = true
	check(s.victory_note().contains("ataque à nave") and s.victory_note().contains("Letícia"),"first victory connects ship attack and crew")
	s.say("irrelevant combat message")
	check(s.journal_entries().any(func(e):return e.title.contains("LETÍCIA") and e.text.contains("Estou viva")),"crew lead survives overwritten message and old victory flags")
	check(s.journal_entries().size() >= 4 and s.missions_list()[0].done,"crew mission advances")
	s.reward_claimed = true
	var copy := fixture(); copy.apply_snapshot(s.snapshot())
	check(copy.reward_claimed and copy.dialogue_owner == "coral","network carries mission completion and dialogue owner")
	check(copy.journal_entries().any(func(e):return e.title.contains("ATAQUE")),"journal survives snapshot")

	s = fixture(); s.mode = "run"; s.rooms = [{"id":"entry","kind":"entry","r":Rect2(0,0,500,500)}]
	s.spawn_enemy(Vector2(250,100),"crawler"); s.spawn_enemy(Vector2(400,100),"fish")
	s.enemies[1].onboarding_wait = true; s.step_entry_onboarding()
	check(s.enemies[1].onboarding_wait and s.story_flags.treino_docas,"first threat introduced alone")
	s.enemies[0].hp = 0; s.step_entry_onboarding(); check(not s.enemies[1].onboarding_wait,"next threats join after first")
	s.set_unlocks(["padrao","omega","azul"]); s.check_unlocks()
	check(not s.is_unlocked("titan") and not s.is_unlocked("spectre"),"new campaign robots earned")
	s.story_flags.peca_titan = true; s.check_unlocks(); check(s.is_unlocked("titan"),"Titan earned by first victory piece")
	s.side_complete = true; s.check_unlocks(); check(s.is_unlocked("spectre"),"generator grants support chassis")
	s.set_unlocks(["padrao","omega","azul","titan","spectre"])
	check(s.is_unlocked("titan") and s.is_unlocked("spectre"),"existing ownership preserved")
	s = fixture(); a = s.actors[0]; s.robobolas = 3
	s.spawn_enemy(Vector2(180,100),"golem")
	robot = s.enemies[-1]; robot.stunned = true
	var fragments_before: int = s.materials
	s.capture_robot(a, robot); s.capture_robot(a, robot)
	check(s.robobolas == 2 and s.materials == fragments_before + 3, "same capture cannot consume or reward twice")
	s.spawn_enemy(Vector2(220,100),"golem"); robot = s.enemies[-1]; robot.stunned = true
	s.capture_robot(a, robot)
	check(s.robobolas == 1 and s.materials == fragments_before + 3, "second capture before invocation cannot repeat mission reward")
	s = fixture(); a = s.actors[0]; a.p = Vector2(200,100); s.actors[1].active = false
	s.obstacles = [Rect2(145,0,10,250), Rect2(195,130,20,20), Rect2(90,130,20,20)]
	s.obstacle_kinds = ["wall", "barrel_explosive", "barrel_explosive"]; s.obstacle_hp = [-1.0,16.0,16.0]
	var position_before: Vector2 = a.p; hp = a.hp
	s.explode(Vector2(100,100),150,60,true,true)
	check(a.hp == hp and a.p == position_before, "wall blocks barrel damage and push against player")
	check(s.obstacles.size() == 2 and s.obstacle_hp[1] == 16 and s.fuses.size() == 1, "wall blocks chain reaction while exposed barrel still ignites")
	print("REVIEW_GAMEPLAY_STORY checks=",checks," failures=",failures)
	quit(1 if failures else 0)
