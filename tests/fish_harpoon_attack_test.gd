extends SceneTree
const Motion = preload("res://scripts/enemy_motion.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
	else: print("PASS: ", label)
func _init() -> void:
	var motion := Motion.new(); motion.load_assets()
	var manifest: Dictionary = motion.manifests.fish
	check(int(manifest.cell) == 128 and Vector2(manifest.pivot[0],manifest.pivot[1]) == Vector2(64,112), "Fish retains native cell and foot pivot")
	for row in range(8):
		var face := Vector2.DOWN.rotated(-row*PI/4)
		var e := {"kind":"fish","face":face,"combat":"warning","combat_t":0.5}
		var sample: Dictionary = motion.sample(e)
		check(sample.action == "attack" and sample.count == 9, "Nine generated/reference poses: " + Motion.DIRECTIONS[row])
		check(sample.texture.get_width() == sample.count*128 and sample.texture.get_height() == 128, "Native atlas dimensions: " + Motion.DIRECTIONS[row])
		e.combat = "attack"; e.combat_t = 0.449
		check(motion.sample(e).frame == manifest.clips.attack[Motion.DIRECTIONS[row]].fire_frame, "Firing pose synchronized with emission: " + Motion.DIRECTIONS[row])
		var sim := Expedition.new(); sim.start_arena(); sim.enemies.clear(); sim.bullets.clear()
		sim.actors[0].p = Vector2(650,500) + face*220
		sim.spawn_enemy(Vector2(650,500),"fish")
		var fish: Dictionary = sim.enemies[0]
		fish.merge({"combat":"attack","combat_t":0.45,"target_id":0,"locked":sim.actors[0].p,"burst":0,"burst_t":0.0},true)
		sim.step_common_enemy(fish,sim.actors[0],0.001)
		check(sim.bullets.size()==1 and sim.bullets[0].kind=="harpoon" and sim.bullets[0].stake, "One held-gun harpoon: " + Motion.DIRECTIONS[row])
		check(is_equal_approx(sim.bullets[0].damage,22*fish.damage_scale) and is_equal_approx(sim.bullets[0].v.length(),560), "Damage/speed unchanged: " + Motion.DIRECTIONS[row])
		check(sim.bullets[0].p.is_equal_approx(sim.enemy_muzzle_position(fish)), "Projectile starts at barrel: " + Motion.DIRECTIONS[row])
	print("FISH_HARPOON_ATTACK failures=",failures)
	quit(1 if failures else 0)
