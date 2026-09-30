extends SceneTree

var failures := 0
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	# 0.17: jogo novo começa sem robôs; este teste cobre os robôs, então libera tudo
	app.sim.set_unlocks(["padrao", "mecanico", "espiao", "omega", "titan", "spectre"])
	app.menu.show_screen("play")
	# Exercise the actual solo selection callback, then equipment launch.
	app.menu.content.find_child("SoloChoice", true, false).pressed.emit()
	check(app.menu.pending_mode == "solo" and not app.playing, "solo card selects without prematurely starting")
	check(app.menu.screen == "play", "solo card remains selected until confirmation")
	app.menu.content.find_child("EquipAndEnter", true, false).pressed.emit()
	check(app.menu.screen == "equipment" and app.menu.pending_mode == "solo", "solo confirmation opens equipment")
	# O teste precisa começar com Titan, sem depender da preferência persistida em user://.
	app.menu.outfit_choice = "padrao"; app.menu.robot_choice = "titan"
	app.menu.launch(); app.paused = true
	var s = app.sim
	check(s.coop == "solo" and not s.actors[1].active and s.actors[1].dead, "solo starts without active partner")
	var a: Dictionary = s.actors[0]
	check(s.owned_robot_ids(0) == ["titan", "spectre"], "unlocked robots reconcile to owned mission modules")
	var partner_pos: Vector2 = s.actors[1].p
	s.step(0.1, [{}, {"fire": true, "move": Vector2.RIGHT}])
	check(s.actors[1].p == partner_pos and s.bullets.filter(func(b): return b.owner == 1).is_empty(), "inactive partner cannot move or shoot")
	s.enemies.clear()
	check(s.summon_robot(a), "solo can summon Titan")
	s.mech.hp = 211; s.mech.fuel = 64; s.spectres[0].hp = 73
	check(s.cycle_owned_robot(a) and a.selected_robot == "spectre" and not s.mech.deployed, "cycle stores Titan and selects owned Spectre")
	check(s.mech.hp == 211 and s.mech.fuel == 64 and s.spectres[0].hp == 73, "cycle preserves both robot resources")
	check(s.cycle_owned_robot(a) and a.selected_robot == "titan", "cycle returns to owned Titan")
	a.mech = true
	check(not s.cycle_owned_robot(a) and a.selected_robot == "titan", "robot cycle is blocked while piloting")
	a.mech = false
	a.summon_cd = 0; check(s.summon_robot(a) and s.mech.deployed, "selected Titan can deploy again after cycling")
	s.mech.hp = 123; a.summon_cd = 0
	check(s.summon_robot(a) and not s.mech.deployed, "Titan recalls")
	a.summon_cd = 0
	check(s.summon_robot(a) and s.mech.hp == 123, "resummoning preserves damage")
	a.summon_cd = 0; s.mech.occupant = 1
	check(not s.summon_robot(a), "occupied Titan cannot be summoned away")
	s.mech.occupant = -1
	s.spectres[0].hp = 100
	check(s.equip(0, "padrao", "spectre") and s.summon_robot(a), "solo can summon Spectre")
	check(s.toggle_fusion(a) and a.fused and s.spectres[0].state == "fused", "fusion consumes follower state")
	a.hp = 100; a.hurt = 0; s.damage_actor(a, 25)
	check(s.spectres[0].hp == 75 and a.hp == 100, "fusion absorbs impact using robot energy")
	check(s.toggle_fusion(a) and not a.armor and s.spectres[0].hp == 75, "separation restores armor without free healing")
	s.toggle_fusion(a); a.hurt = 0; s.damage_actor(a, 90)
	check(not a.fused and a.hp == 95 and s.spectres[0].state == "destroyed", "depleted fusion applies overflow damage")
	a.summon_cd = 0
	check(not s.summon_robot(a), "destroyed robot cannot be healed by resummoning")
	var copy = load("res://scripts/simulation.gd").new(); copy.apply_snapshot(s.snapshot())
	check(not copy.actors[1].active and copy.spectres[0].hp == 0, "snapshot preserves solo and robot state")
	a.dead = true; s.step(0.016, [{}, {}])
	check(not s.actors[0].dead and not s.actors[1].active, "solo defeat restarts arena without spawning partner")
	app.start_solo()
	check(s.coop == "ai" and s.actors[1].active, "AI companion remains a separate playable option")
	print("SOLO / ROBOTS: ", failures, " failures")
	quit(1 if failures else 0)
