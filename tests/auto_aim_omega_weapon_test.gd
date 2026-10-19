extends SceneTree
const Main=preload("res://scripts/main.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	var s:=Expedition.new(); s.start_arena(); s.enemies.clear(); s.obstacles.clear(); s.gate_blocks.clear()
	var a: Dictionary=s.actors[0]; a.p=Vector2(400,500)
	var screen:=Rect2(0,0,1280,800)
	s.spawn_enemy(a.p+Vector2(200,0),"guard"); s.spawn_enemy(a.p+Vector2(0,100),"guard")
	check(s.auto_aim_direction(a,Vector2.LEFT,screen)==Vector2.DOWN,"nearest enemy selected independent of manual aim")
	s.enemies[1].hp=0
	check(s.auto_aim_direction(a,Vector2.LEFT,screen)==Vector2.RIGHT,"dead target replaced immediately")
	s.enemies[1].hp=100; s.enemies[1].stunned=true
	check(s.auto_aim_direction(a,Vector2.LEFT,screen)==Vector2.RIGHT,"stunned robot ignored")
	s.obstacles=[Rect2(460,440,20,120)]; s.ob_grid_count=-1
	check(s.auto_aim_direction(a,Vector2.LEFT,screen)==Vector2.LEFT,"wall blocks target and manual fallback survives")
	s.obstacles.clear(); s.ob_grid_count=-1; s.enemies[0].p=Vector2(1500,500)
	check(s.auto_aim_direction(a,Vector2.UP,screen)==Vector2.UP,"offscreen enemy ignored")
	s.enemies.clear(); a.run_weapons={"tesla":17}; a.run_weapon="tesla"
	s.set_armor(a,true); a.transform=0; a.armor_time=300; a.shot=0; a.aim=Vector2.RIGHT
	check(s.weapon_of(a)=="omega_orb","temporary weapon overrides selected gun")
	for i in 3:
		a.shot=0; s.step_actor(a,{"fire":true,"aim":Vector2.RIGHT},0.016)
	check(s.bullets.size()==3 and s.bullets.all(func(b):return b.kind=="p_omega"),"fire button casts only energy orbs")
	check(s.bullets[-1].pierce==5 and s.bullets[-1].damage==64,"third orb retains finisher")
	check(a.run_weapons.tesla==17,"temporary weapon never spends stored ammo")
	s.toggle_run_weapon(a); check(a.run_weapon=="tesla","switch button preserves stored selection")
	check(not s.select_run_weapon(0,"pistol"),"equipment cannot replace temporary weapon")
	s.set_armor(a,false); check(s.weapon_of(a)=="tesla" and a.run_weapons.tesla==17,"previous gun and exact ammo restored")
	var app:=Main.new(); app.auto_aim=true; app.save_settings(); app.auto_aim=false; app.load_settings()
	check(app.auto_aim,"auto aim preference persists")
	app.free()
	print("AUTO_AIM_OMEGA_WEAPON failures=",failures); quit(1 if failures else 0)

