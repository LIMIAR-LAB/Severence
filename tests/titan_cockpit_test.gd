extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _init() -> void:
	var s := Expedition.new()
	s.make_hub()
	var a: Dictionary = s.actors[0]
	a.p = s.mech.p + Vector2(60,0)
	s.interact(a)
	check(a.mech and s.mech.cockpit_t > 0,"embarque inicia transição")
	var pos: Vector2 = a.p
	s.step_actor(a,{"move":Vector2.RIGHT,"fire":true},0.2)
	check(a.p == pos and s.bullets.is_empty(),"transição bloqueia movimento e tiro")
	s.interact(a)
	check(a.mech,"não desembarca durante abertura")
	s.step_actor(a,{},1.1)
	s.interact(a)
	check(not a.mech and not s.mech.cockpit_entering,"desembarque animado")
	s.step_actor(a,{},1.3)
	check(s.mech.cockpit_t == 0,"transição termina")
	print("COCKPIT failures=", failures)
	quit(1 if failures else 0)
