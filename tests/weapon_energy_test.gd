extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
	else: print("PASS ", label)
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	run.call_deferred()
func run() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena(); s.enemies.clear(); s.obstacles.clear(); s.bullets.clear()
	var a: Dictionary = s.actors[0]
	a.p = Vector2(600, 600); a.aim = Vector2.RIGHT
	for npc in s.RESCUE_NPCS:
		s.grant_run_weapon(a, npc.weapon, npc.ammo)
		check(a.run_weapons[npc.weapon] == {"mosquete":20,"tesla":90,"arpoador":30}[npc.weapon], "larger acquisition " + npc.weapon)
		s.grant_run_weapon(a, npc.weapon, 999)
		check(a.run_weapons[npc.weapon] == s.RUN_WEAPON_CAPS[npc.weapon], "cap " + npc.weapon)
		var tex: Texture2D = preload("res://scripts/weapon_visuals.gd").texture(npc.weapon)
		check(tex is AtlasTexture and tex.get_width() > 1500, "high resolution cropped art " + npc.weapon)
		for n in range(8):
			a.aim = Vector2.RIGHT.rotated(n * PI / 4); a.run_weapon = npc.weapon
			var geometry := s.weapon_geometry(a)
			check(geometry.size.x <= 104 and geometry.ground.distance_to(a.p) < 130, "bounded geometry " + npc.weapon + str(n))
			s.fire_actor(a)
	var old := s.snapshot().duplicate(true)
	old.actors[0].run_weapons = {"tesla":7}
	var restored := Expedition.new(); restored.apply_snapshot(old)
	check(restored.actors[0].run_weapons.tesla == 7, "old save keeps exact ammo")
	a.run_weapons.tesla = 250; s.grant_run_weapon(a, "tesla", 10)
	check(a.run_weapons.tesla == 250, "above cap old reserve never reduced")
	s.set_armor(a, true); a.transform = 0; a.aim = Vector2.RIGHT
	s.bullets.clear(); s.spawn_enemy(a.p + Vector2(70,0), "brute")
	var enemy: Dictionary = s.enemies[0]; enemy.hp = 1000; enemy.max = 1000
	s.sword_attack(a)
	check(enemy.hp == 962 and s.bullets[-1].kind == "p_omega", "close cast plus energy orb")
	var orb: Dictionary = s.bullets[-1]; orb.p = enemy.p; s.hit_bullet_enemy(orb)
	check(enemy.hp == 962, "same cast never hits close target twice")
	check(orb.visual_r == 27 and orb.height > 60, "large sphere comes from elevated palm")
	check(s.effects.all(func(f): return f.kind != "sword"), "no sword smear")
	s.bullets.clear(); s.enemies.clear(); s.obstacles = [Rect2(630,450,20,300)]; s.obstacle_hp = [-1]
	s.spawn_enemy(Vector2(680,600), "brute"); enemy = s.enemies[0]; enemy.hp = 1000
	s.sword_attack(a)
	for n in range(30): s.step_bullets(0.02)
	check(enemy.hp == 1000, "energy blocked by cover including close hit")
	for combo in [0, 2]:
		s.bullets.clear(); s.enemies.clear(); a.combo = combo; a.combo_t = 1
		s.obstacles = [Rect2(650,450,10,300)]; s.ob_grid_count = -1
		s.spawn_enemy(Vector2(680,600), "brute"); enemy = s.enemies[0]; enemy.hp = 1000
		s.sword_attack(a)
		for frame in range(30): s.step_bullets(0.02)
		check(enemy.hp == 1000, "large orb overlap cannot reach through thin cover " + str(combo))
	check(s.loadout_stats("omega").any(func(row): return row[0] == "ESFERA FINAL" and row[1].contains("64")), "equipment reports actual finisher damage")
	var view := DockView.new(); view.sim = s
	a.armor = false; a.run_weapon = "mosquete"
	var gun := preload("res://scripts/weapon_visuals.gd").texture("mosquete")
	view.weapon_art["mosquete"] = gun
	check(view.blade_render_size(a, gun) == Vector2(104,30), "HD firearm melee remains bounded")
	for tool in ["knife", "wrench"]:
		var texture: Texture2D = load("res://assets/weapons/" + tool + ".png")
		check(view.blade_render_size(a, texture) == texture.get_size(), "equipped HD firearm does not stretch " + tool)
	view.free()
	print("WEAPON_ENERGY_TESTS_DONE failures=", failures)
	quit(1 if failures else 0)
