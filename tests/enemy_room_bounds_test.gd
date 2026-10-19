extends SceneTree

var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func fixture() -> Expedition:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena(); s.enemies.clear(); s.pending_spawns.clear()
	s.mode = "run"
	s.rooms = [{"id": "fight", "kind": "fight", "r": Rect2(100, 100, 400, 400), "extra": [Rect2(500, 200, 100, 200)]}]
	s.floors = [Rect2(100, 100, 400, 400), Rect2(500, 200, 100, 200), Rect2(600, 250, 250, 100)]
	s.obstacles.clear(); s.obstacle_kinds.clear(); s.gaps.clear(); s.harpoons.clear(); s.tentacle_gates.clear()
	s.ob_grid_count = -1
	s.doors = [{"room": "fight", "side": "right", "r": Rect2(600, 250, 36, 100)}]
	s.gate_blocks.clear(); s.actors[0].p = Vector2(300, 300)
	return s

func _init() -> void:
	var s := fixture()
	s.spawn_enemy(Vector2(565, 300), "cult")
	var e: Dictionary = s.enemies[0]
	e.p = s.move_enemy_body(e, Vector2(500, 0), 14)
	check(s.room_contains(s.rooms[0], e.p) and e.p.x < 586.1, "knockback cannot expel owned enemy into open corridor")
	e.p = Vector2(470, 300)
	e.p = s.move_enemy_body(e, Vector2(80, 0), 14)
	check(e.p.x > 520, "joined room alcove remains traversable")

	# Recover old saves before locking, without discarding the enemy or its health.
	e.p = Vector2(730, 300); var hp_before: float = e.hp
	s.step_gates()
	check(s.rooms[0].locked and s.room_threats("fight") == 1, "living off-room enemy still prevents room completion")
	check(s.enemy_room_position_valid(e, e.p, 14) and s.line_of_fire(s.actors[0].p, e.p), "gate closure recovers enemy onto reachable room floor")
	check(e.hp == hp_before and s.enemies.has(e), "recovery retains enemy and health")

	s = fixture(); s.spawn_enemy(Vector2(700, 300), "cult"); e = s.enemies[0]
	check(e.room == "fight" and s.enemy_room_position_valid(e, e.p, 14), "corridor spawn receives encounter ownership and free room floor")

	# Invalid spawn embedded in a prop is relocated rather than frozen there.
	s = fixture(); s.obstacles = [Rect2(250, 250, 100, 100)]; s.ob_grid_count = -1
	s.actors[0].p = Vector2(180, 180)
	s.spawn_enemy(Vector2(300, 300), "cult"); e = s.enemies[0]
	check(s.enemy_room_position_valid(e, e.p, 14), "spawn overlapping prop relocates to free floor")

	for kind in ["warden", "boss", "crawler"]:
		s = fixture(); s.spawn_enemy(Vector2(565, 300), kind); e = s.enemies[0]
		var radius: float = s.enemy_room_radius(e)
		check(s.enemy_room_position_valid(e, e.p, radius), kind + " spawn respects collision radius")
		e.p = s.move_enemy_body(e, Vector2(800, 0), radius)
		check(s.enemy_room_position_valid(e, e.p, radius), kind + " charge/leap stays inside room")

	# Killing the recovered enemy, rather than ignoring it, opens the doors.
	s = fixture(); s.spawn_enemy(Vector2(350, 300), "cult"); s.step_gates()
	s.enemies[0].hp = 0; s.step_enemies(0.016); s.step_gates()
	check(not s.rooms[0].locked and s.rooms[0].cleared, "actual enemy defeat opens encounter normally")
	print("ENEMY_ROOM_BOUNDS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
