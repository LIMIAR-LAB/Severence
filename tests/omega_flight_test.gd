extends SceneTree
const Flight = preload("res://scripts/omega_flight.gd")
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
	else: print("PASS: ", label)
func _init() -> void:
	var s := Expedition.new(); s.start_arena(); s.enemies.clear()
	var a: Dictionary = s.actors[0]
	a.armor = true; a.armor_type = "omega"; a.transform = 0; a.move = Vector2.RIGHT
	var fx := Flight.new(); fx.load_assets()
	var snapshot := var_to_bytes(a)
	fx.sample(a, 0.0)
	check(fx.sample(a, 0.1).active and fx.sample(a, 0.2).blend == 1.0, "Movement smoothly ignites visual flight")
	check(var_to_bytes(a) == snapshot, "Rendering leaves actor state byte-identical")
	a.move = Vector2.ZERO
	check(fx.sample(a, 0.25).active, "Stopping retains short landing transition")
	check(not fx.sample(a, 0.35).active, "Landing extinguishes all jets")
	a.jump = 0.5
	check(Flight.requested(a), "Existing jump requests upright flight")
	fx.sample(a, 0.45)
	a.jump = 0.0
	check(not fx.sample(a, 0.55).active, "Jump landing releases flight pose")
	a.move = Vector2.RIGHT
	for key in ["dead","hidden","bike","mech","fused"]:
		a[key] = true; check(not Flight.eligible(a), key + " excludes flight"); a[key] = false
	for key in ["transform","slash","hurt","fire_flash","beam_time","roll_visual"]:
		a[key] = 0.2; check(not Flight.eligible(a), key + " retains its own pose"); a[key] = 0.0
	a.armor_type = "azul"; check(not Flight.eligible(a), "Blue form is unaffected"); a.armor_type = "omega"
	fx.sample(a, 0.7); fx.sample(a, 0.8)
	a.dead = true; check(not fx.sample(a, 0.8).active, "Death cancels jets immediately, even while paused"); a.dead = false
	for row in range(8):
		for frame in range(DockView.MARTY_OMEGA_FRAMES.flight):
			var points := fx.emitters(row, frame)
			check(points.size() == 4 and points[0].y < points[2].y and points[1].y < points[3].y, "Two palms above two soles: %d/%d" % [row,frame])
	var view := DockView.new(); view.sim = s
	check(view.marty_omega_action(a,true) == "flight", "Omega locomotion selects dedicated flight art")
	var initial := Vector2(650,500); a.p=initial; a.jump=0; a.jump_cd=0; a.move=Vector2.ZERO
	s.step_actor(a,{"jump":true},0.016)
	check(a.jump > 0 and a.jump <= 0.65, "Jump retains existing bounded duration")
	for i in range(45): s.step_actor(a,{},0.016)
	check(a.jump == 0, "Visual flight grants no indefinite airborne state")
	view.free()
	print("OMEGA_FLIGHT checks=",checks," failures=",failures); quit(1 if failures else 0)
