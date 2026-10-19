extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures += 1; push_error(label)
func _init() -> void:
	var s := Expedition.new(); s.coop = "solo"; s.start_arena(); s.enemies.clear(); s.obstacles.clear()
	var a: Dictionary = s.actors[0]; a.p = Vector2(500,500)
	s.grant_run_weapon(a,"bazooka",6)
	for outfit in ["padrao","mecanico","espiao"]:
		a.outfit = outfit
		for form in ["normal","fusion"]:
			a.armor = form == "omega"; a.fused = form == "fusion"
			check(s.weapon_of(a) == "bazooka" and a.run_weapons.bazooka == 6,"equipment survives " + outfit + "/" + form)
			for row in 8:
				a.aim = Vector2.DOWN.rotated(-row*PI/4); a.move = -a.aim; a.facing = a.move
				a.jump = 0.3
				var g := s.weapon_geometry(a)
				check(s.weapon_behind_body(a) == (row in [3,4,5]),"depth " + str(row))
				s.fire_actor(a); a.run_weapons.bazooka += 1
				var b: Dictionary = s.bullets[-1]
				check((b.p-Vector2(0,b.height)).distance_to(a.p+(g.muzzle-a.p)*s.ACTOR_VISUAL_SCALE)<0.01,"muzzle shared " + outfit + "/" + form + "/" + str(row))
	a.mech = true; s.fire_actor(a)
	check(s.weapon_of(a)=="mech" and a.run_weapons.bazooka==6,"robot stores carried ammo")
	a.mech = false; check(s.weapon_of(a)=="bazooka","disembarking restores weapon")
	check(s.select_run_weapon(0,""),"Omega can select basic weapon")
	a.outfit = "espiao"; check(s.weapon_of(a)=="pistol","outfit cannot silently replace basic weapon")
	var restored := Expedition.new(); restored.apply_snapshot(s.snapshot().duplicate(true))
	check(restored.weapon_of(restored.actors[0])=="pistol" and restored.actors[0].run_weapons.bazooka==6,"snapshot retains selection and ammo")
	var old := s.snapshot().duplicate(true); old.actors[0].erase("basic_weapon")
	restored.apply_snapshot(old); var old_weapon := restored.weapon_of(restored.actors[0]); restored.actors[0].outfit="padrao"
	check(restored.weapon_of(restored.actors[0])==old_weapon,"legacy migration binds once")
	s.set_unlocks(["padrao","omega"])
	check(not s.select_run_weapon(0,"shotgun"),"locked shotgun rejected")
	s.set_unlocks(["padrao","omega","mecanico","espiao"])
	check(s.select_run_weapon(0,"shotgun") and s.weapon_of(a)=="shotgun","unlocked shotgun selectable independent of outfit")
	a.outfit="padrao"; a.armor=true
	check(s.weapon_of(a)=="omega_orb" and a.basic_weapon=="shotgun","Omega stores selected shotgun under temporary orbs")
	check(not s.select_run_weapon(0,"smg"),"temporary weapon cannot be replaced in armor")
	a.armor=false
	check(s.weapon_of(a)=="shotgun","shotgun returns when armor ends")
	var view := DockView.new()
	var size := view.omega_assembly_draw_size(Vector2(271.5,724))
	check(is_equal_approx(size.x/size.y,271.5/724.0),"transformation preserves source aspect")
	view.free()
	print("INDEPENDENT_WEAPONS failures=",failures); quit(failures)
