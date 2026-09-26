extends SceneTree

# 0.14 — Combustível do Titan: o mech bebe gasolina enquanto pilotado,
# para quando o tanque zera e volta a funcionar com galões dos baús.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.bullets.clear()
	var a: Dictionary = s.actors[0]

	# Embarque consome e bloqueia por combustível
	a.p = s.mech.p - Vector2(30, 0)
	s.interact(a)
	check(a.mech, "Marty embarca no Titan com gasolina")
	check(s.mech.fuel > 0 and s.mech.fuel <= s.FUEL_MAX, "tanque começa parcial (70%)")

	var fuel0: float = s.mech.fuel
	for i in range(60): s.step_actor(a, {"move": Vector2.RIGHT}, 0.016)
	check(s.mech.fuel < fuel0, "andar pilotando consome gasolina")
	var fuel_move: float = fuel0 - s.mech.fuel
	var fuel1: float = s.mech.fuel
	for i in range(60): s.step_actor(a, {"move": Vector2.RIGHT, "boost": true}, 0.016)
	check(fuel1 - s.mech.fuel > fuel_move * 1.5, "turbo consome muito mais gasolina")

	# Canhão e bomba custam combustível
	var fuel2: float = s.mech.fuel
	a.shot = 0; s.step_actor(a, {"fire": true}, 0.016)
	check(s.mech.fuel < fuel2 and s.bullets.size() == 1, "canhão pesado gasta gasolina")
	s.bullets.clear(); a.bomb_cd = 0
	s.step_actor(a, {"armor": true}, 0.016)
	check(s.bullets.size() == 1 and s.bullets[0].kind == "bomb", "bomba sai com gasolina")
	s.bullets.clear()

	# Tanque vazio: mech apaga mas o piloto ainda sai
	s.mech.fuel = 0
	var p0: Vector2 = a.p
	for i in range(30): s.step_actor(a, {"move": Vector2.RIGHT}, 0.016)
	check(a.p.distance_to(p0) < 5, "sem gasolina o Titan não anda")
	a.shot = 0; s.step_actor(a, {"fire": true}, 0.016)
	check(s.bullets.is_empty(), "sem gasolina o canhão não dispara")
	a.bomb_cd = 0; s.step_actor(a, {"armor": true}, 0.016)
	check(s.bullets.is_empty(), "sem gasolina a bomba não sai")
	s.interact(a)
	check(not a.mech, "piloto desembarca mesmo sem gasolina")

	# Reembarque bloqueado até abastecer
	a.p = s.mech.p - Vector2(30, 0); a.interact_cd = 0
	s.interact(a)
	check(not a.mech, "não embarca com o tanque vazio")
	s.pickups.append({"p": a.p, "kind": "fuel"})
	s.collect_pickups()
	check(s.mech.fuel == s.FUEL_PICKUP, "galão recarrega +40%% de gasolina")
	s.interact(a)
	check(a.mech, "com gasolina o Titan volta a funcionar")

	# Bateria: recarrega e reanima o Spectre
	var sp: Dictionary = s.spectres[a.id]
	sp.hp = 0; sp.state = "destroyed"
	s.pickups.append({"p": a.p, "kind": "battery"})
	s.collect_pickups()
	check(sp.hp == s.BATTERY_PICKUP and sp.state == "stored", "bateria reanima o Spectre")

	# Baú solta galão + bateria junto das recompensas
	var s2 := Expedition.new()
	s2.coop = "solo"; s2.start_run(1941)
	var c: Dictionary = s2.chests[0]
	s2.actors[0].p = c.p; s2.keys = 1
	var before: int = s2.pickups.size()
	s2.interact(s2.actors[0])
	var kinds: Array = []
	for i in range(before, s2.pickups.size()): kinds.append(s2.pickups[i].kind)
	check(c.open, "baú abre")
	check(kinds.has("fuel") and kinds.has("battery"), "baú solta galão e bateria")

	print("TITAN_FUEL_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
