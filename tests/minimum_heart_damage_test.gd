extends SceneTree

const Simulation = preload("res://scripts/simulation.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
	else: print("PASS: ", label)

func _init() -> void:
	var s = Simulation.new()
	s.start_arena()
	var a: Dictionary = s.actors[0]
	s.damage_actor(a, 0.1)
	check(a.hp == 2 * s.HEART, "small hit removes one whole heart")
	s.damage_actor(a, 8)
	check(a.hp == 2 * s.HEART, "invulnerability still prevents repeated hits")
	a.hurt = 0; s.damage_actor(a, 0)
	check(a.hp == 2 * s.HEART and a.hurt == 0, "zero damage has no effect")
	a.shield = 3 * s.HEART; s.damage_actor(a, 1)
	check(a.shield == 2 * s.HEART and a.hp == 2 * s.HEART, "shield absorbs one whole heart")
	a.shield = 0; a.hurt = 0; s.damage_actor(a, 8)
	a.hurt = 0; s.damage_actor(a, 8)
	check(a.hp == 0 and a.dead, "three confirmed hits defeat a three-heart player")
	print("MINIMUM_HEART_DAMAGE failures=", failures)
	quit(1 if failures else 0)
