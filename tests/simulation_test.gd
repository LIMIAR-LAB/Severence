extends SceneTree
const DocksMap = preload("res://scripts/docks_map.gd")

const Sim = preload("res://scripts/simulation.gd")
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s = Sim.new()
	s.coop = "local"
	var a: Dictionary = s.actors[0]
	var b: Dictionary = s.actors[1]
	a.p = s.mech.p - Vector2(40, 0); b.p = s.mech.p + Vector2(40, 0)
	s.interact(a); wait_cockpit(s, a); s.interact(b)
	check(a.mech and not b.mech and s.mech.occupant == 0, "exclusive mech seat for simultaneous requests")
	s.damage_actor(a, 50); var health: float = s.mech.hp
	s.interact(a); wait_cockpit(s, a); s.interact(a); wait_cockpit(s, a)
	check(s.mech.hp == health and a.mech, "mech integrity persists across embark/disembark")
	s.obstacles.append(Rect2(a.p - Vector2(100, 100), Vector2(200, 200)))
	s.interact(a); wait_cockpit(s, a)
	check(a.mech, "blocked disembark preserves occupant")
	s.obstacles.clear(); s.interact(a); wait_cockpit(s, a)
	check(not a.mech and s.mech.occupant == -1, "valid exit clears seat")
	a.p = Vector2(780, 460); a.hurt = 0; a.hp = 30; a.armor = false; a.shield = 0.0
	s.damage_actor(a, 20); check(a.hp == 20, "golpe pesado tira 1 coração")
	a.hurt = 0; s.damage_actor(a, 8); check(a.hp == 15, "golpe comum tira meio coração")
	a.hurt = 0; a.shield = 30.0
	s.damage_actor(a, 20); check(a.hp == 15 and a.shield == 20.0, "escudo Ômega absorve o golpe antes da vida")
	a.hurt = 0; a.jump = 0.4; s.damage_actor(a, 50, "hazard", "acid")
	check(a.hp == 15 and a.shield == 20.0, "normal jump clears ground acid without spending shield")
	a.shield = 0.0
	a.jump = 0
	var old: Vector2 = a.p
	s.step_actor(a, {"move": Vector2(1, -1).normalized(), "jump": true}, 0.1)
	check(a.p.x > old.x and a.p.y < old.y and a.jump > 0, "diagonal jump moves on both axes")
	s.start_run(1941)
	var first: Array = s.enemies.duplicate(true)
	s.start_run(1941)
	check(s.enemies[0].p == first[0].p and s.enemies[0].kind == first[0].kind, "same seed reproduces encounters")
	s.start_run(1942)
	check(s.enemies[0].p != first[0].p, "different seed changes encounters")
	s.coop = "local"; a = s.actors[0]; b = s.actors[1]
	a.p = s.chests[0].p; s.keys = 0; s.interact(a); wait_cockpit(s, a)
	check(not s.chests[0].open, "locked chest cannot open without key")
	s.keys = 1; s.interact(a); wait_cockpit(s, a); s.interact(a); wait_cockpit(s, a)
	check(s.keys == 0 and s.chests[0].open, "chest consumes exactly one key")
	a.p = DocksMap.POINTS.shop; s.money = 15; var k: int = s.keys
	s.interact(a); wait_cockpit(s, a); s.interact(a); wait_cockpit(s, a)
	check(s.money == 0 and s.keys == k + 1, "shop purchase is atomic and stock limited")
	s.enemies.clear(); s.spawn_enemy(Vector2(1130, 6450), "brute")
	a.p = Vector2(1100, 6450); a.aim = Vector2.RIGHT; a.slash = 0
	s.melee(a); var hp: float = s.enemies[0].hp
	s.step_actor(a, {"melee": true}, 0.01)
	check(s.enemies[0].hp == hp, "melee cooldown prevents repeated damage per frame")
	s.bullets.clear(); s.enemies.clear(); s.spawn_enemy(Vector2(1210, 6450), "brute")
	s.add_bullet(Vector2(1100, 6450), Vector2.RIGHT, 0, 10, 2000)
	s.step_bullets(0.1)
	check(s.enemies[0].hp == s.enemies[0].max - 10 and s.bullets.is_empty(), "fast projectile sweep hits once without tunnelling")
	s.enemies.clear(); a.p = DocksMap.POINTS.side; s.interact(a); wait_cockpit(s, a)
	check(s.side_active and s.enemies.size() == 7, "optional encounter spawns seven guards")
	s.enemies.clear(); s.step(0.016, [{}, {}])
	check(s.side_complete and not s.side_active, "optional reward granted on completion")
	var coins: int = s.money; s.step(0.016, [{}, {}])
	check(s.money == coins, "optional reward cannot repeat")
	s.open_secret()
	check(s.clear_at(DocksMap.SECRET_CORRIDOR.get_center(), 10) and s.clear_at(Vector2(6350, 1250), 10), "secret opens a traversable corridor")
	check(s.height_at(Vector2(2060, 4100)) == 0 and s.height_at(Vector2(2240, 4100)) == 0, "published flat Farol has no legacy ramp elevation")
	var blocked: Vector2 = s.move_body(Vector2(2650, 4400), Vector2(0, -150), 11)
	check(blocked.y <= 4251, "published flat Farol has no ghost balcony ledge")
	var climbed: Vector2 = s.move_body(Vector2(2060, 4150), Vector2(300, 0), 11)
	check(climbed.x > 2260 and s.height_at(climbed) == 0, "flat Farol remains traversable")
	var route: PackedVector2Array = s.nav.get_point_path(s.nav.get_closest_point(DocksMap.POINTS.spawn), s.nav.get_closest_point(DocksMap.POINTS.boss))
	check(route.size() > 2, "AI navigation connects arrival to boss")
	a.dead = true; a.hp = 0; b.p = a.p + Vector2(30, 0); s.interact(b)
	check(not a.dead and a.hp == s.HEART * 1.5, "partner can revive downed player")
	a.p = DocksMap.POINTS.extraction; s.boss_dead = true; var before: int = s.materials
	s.interact(a); wait_cockpit(s, a)
	check(s.extract_state == "enter" and s.materials == before + 3, "extraction starts cinematic and grants reward once")
	for i in range(80): s.step_extraction(0.05)
	check(s.mode == "hub" and s.materials == before + 3 and s.armor_unlocked, "extraction awards permanent armor and returns to hub")
	var copy = Sim.new(); copy.apply_snapshot(s.snapshot().duplicate(true))
	check(copy.mode == s.mode and copy.actors[0].p == s.actors[0].p, "network state roundtrip")
	print("SIMULATION_TESTS: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

func wait_cockpit(s, a: Dictionary) -> void:
	if s.mech.get("cockpit_t", 0.0) > 0: s.step_actor(a, {}, 1.3)
