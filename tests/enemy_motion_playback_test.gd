extends SceneTree

const EnemyMotion = preload("res://scripts/enemy_motion.gd")

func _init() -> void:
	var motion := EnemyMotion.new()
	motion.load_assets()
	var sim := Expedition.new()
	sim.start_arena()
	sim.enemies.clear()
	sim.bullets.clear()
	sim.actors[0].p = Vector2(300, 500)
	sim.actors[0].hp = 10000
	sim.spawn_enemy(Vector2(300, 320), "crawler")
	var e: Dictionary = sim.enemies[0]
	e.cd = 0
	var found := {}
	var uncovered := {}
	for i in range(150):
		sim.step_enemies(1.0 / 60.0)
		if sim.enemies.is_empty(): break
		var action: String = sim.enemies[0].combat
		var clip: Dictionary = motion.sample(sim.enemies[0])
		if action in ["warning", "attack"]:
			if clip.is_empty():
				uncovered[motion.row_for(sim.enemies[0].face)] = true
				continue
			if clip.action != "attack":
				push_error("Wrong crawler clip in combat: " + action)
				quit(1)
				return
			found[action] = true
	if not found.has("warning") or not found.has("attack"):
		push_error("Live simulation did not reach warning and attack: " + str(found))
		quit(1)
	else:
		if not uncovered.is_empty():
			push_error("Live crawler attack has uncovered directions: " + str(uncovered))
			quit(1)
		else:
			print("PASS: live warning and attack use articulated clips in every observed direction")
			quit(0)
