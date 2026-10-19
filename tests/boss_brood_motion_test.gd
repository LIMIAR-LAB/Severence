extends SceneTree
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func fixture() -> Expedition:
	var s:=Expedition.new(); s.mode="arena"; s.coop="solo"
	s.floors=[Rect2(0,0,1800,1400)]; s.rooms=[]; s.obstacles=[]; s.hazards=[]; s.gate_blocks=[]
	s.actors=[s.actor(0,Vector2(1100,700)),s.actor(1,Vector2(1150,700))]; s.actors[1].active=false
	s.mech=s.new_mech(Vector2(100,100)); s.spawn_enemy(Vector2(700,700),"boss")
	return s
func _init() -> void:
	var s:=fixture(); var boss: Dictionary=s.enemies[0]; var target: Dictionary=s.actors[0]
	var start: Vector2=boss.p
	s.boss_motion(boss,target,0.1)
	check(boss.p.distance_to(start)>1 and boss.moving,"chefe caminha entre ataques")
	boss.motion_cd=0; s.boss_motion(boss,target,0.016)
	check(boss.motion=="warning" and boss.motion_to.distance_to(boss.p)>60,"reposição tem aviso e destino útil")
	var safe:=true
	for i in 150:
		s.boss_motion(boss,target,1.0/60.0)
		safe=safe and s.clear_at(boss.p,s.BOSS_RADIUS)
	check(safe,"movimento mantém colisão válida")
	boss.brood_cd=0; s.step_boss_brood(boss,0.01)
	check(s.pending_spawns.size()==4,"primeira fase anuncia quatro mini polvos")
	check(s.enemies.size()==1 and s.effects.filter(func(f):return f.kind=="spawn_portal").size()==4,"aviso aparece antes dos inimigos")
	check(s.pending_spawns.all(func(p):return s.clear_at(p.p,12) and p.p.distance_to(target.p)>=105),"nascimentos fora de paredes e do jogador")
	s.step_enemies(0.4)
	check(s.enemies.size()==1,"não materializa antes do aviso")
	s.step_enemies(0.65)
	check(s.enemies.filter(func(e):return e.get("boss_owner",-1)==boss.id).size()==4,"materializa quatro polvos que perseguem")
	boss.hp=boss.max*0.25; boss.brood_cd=0; s.step_boss_brood(boss,0.01)
	check(s.pending_spawns.size()==6,"fase final anuncia seis")
	boss.brood_cd=0; s.step_boss_brood(boss,0.01)
	check(s.pending_spawns.size()==6,"limite inclui polvos vivos e pendentes")
	var snapshot:=s.snapshot(); var restored:=Expedition.new(); restored.apply_snapshot(snapshot)
	check(restored.pending_spawns.size()==6 and restored.enemies[0].has("brood_cd"),"snapshot preserva onda e recarga")
	boss.hp=0; s.step_enemies(0.7)
	check(s.pending_spawns.is_empty() and not s.enemies.any(func(e):return e.has("boss_owner")),"derrota cancela ondas e remove invocados")
	print("BOSS_BROOD_MOTION failures=",failures)
	quit(0 if failures==0 else 1)
