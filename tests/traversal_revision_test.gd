extends SceneTree
const Markers=preload("res://scripts/mission_markers.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func _init() -> void:
	var s:=Expedition.new(); s.coop="solo"; s.start_run(1941)
	var a: Dictionary=s.actors[0]
	var original: Dictionary=s.enemies.filter(func(e):return s.TitanRecovery.original(s,e))[0]
	check(s.enemies.any(func(e):return e.get("titan_copy",false)),"cópia separada no leste")
	s.unlocked.erase("titan"); s.story_flags["peca_titan"]=true; s.check_unlocks()
	check(not s.is_unlocked("titan"),"núcleo sozinho não entrega Titan")
	original["stunned"]=true; original["ray_state"]="defeated"; s.robobolas=0
	s.capture_robot(a,original)
	check(s.story_flags.get("titan_chassis",false) and not s.is_unlocked("titan"),"chassi recuperado mas resta energia")
	s.side_complete=true; s.check_unlocks()
	check(s.is_unlocked("titan"),"três etapas restauram Titan")
	var copy: Dictionary=s.enemies.filter(func(e):return e.get("titan_copy",false))[0]
	copy.stunned=true; s.robobolas=1; s.capture_robot(a,copy)
	check("sentinela" in s.captured_robots and s.robobolas==0,"cópia capturável com robobola")
	check(Markers.targets(s).any(func(m):return m.label=="ALMIRANTE"),"mapa marca missão principal")
	s.reward_claimed=true
	check(not Markers.targets(s).any(func(m):return m.label=="ALMIRANTE"),"objetivo concluído sai do mapa")
	s.start_arena(); s.enemies.clear(); a=s.actors[0]
	s.floors=[Rect2(0,0,1200,1000)]; s.obstacles=[]; s.gate_blocks=[]; s.tentacle_gates=[]; s.harpoons=[]; s.mode="run"; s.rooms=[]; s.gaps=[Rect2(300,0,80,1000)]; s.ob_grid_count=-1
	a.p=Vector2(280,400); a.armor=false; s.step_actor(a,{"move":Vector2.RIGHT},0.3)
	check(a.p.x<300,"a pé permanece bloqueado pelo vão")
	a.armor=true; a.armor_type="omega"; a.armor_time=300; a.transform=0.0
	s.step_actor(a,{"move":Vector2.RIGHT},0.4)
	check(a.p.x>380 and a.jump==0,"Omega cruza vão sem saltar")
	s.gate_blocks=[Rect2(500,0,30,1000)]; s.step_actor(a,{"move":Vector2.RIGHT},0.5)
	check(a.p.x<500,"Omega respeita portão fechado")
	s.start_run(1942); s.enemies.clear(); a=s.actors[0]; a.armor=true; a.armor_type="omega"; a.armor_time=300; a.transform=0.0; a.bike=true; s.bike.riding=true
	a.p=s.run_points.bike_checkpoint
	s.step_actor(a,{"move":Vector2.RIGHT},0.1)
	check(a.bike_speed>0 and a.bike_speed<s.BIKE_SPEED,"moto acelera progressivamente")
	for i in 60: s.BikeHandling.speed(a,{"move":Vector2.RIGHT,"boost":true},1.0/60)
	check(a.bike_speed>s.BIKE_SPEED and a.bike_turbo<0.7,"turbo acelera e consome carga")
	var charge: float=a.bike_turbo
	for i in 60: s.BikeHandling.speed(a,{"move":Vector2.RIGHT},1.0/60)
	check(a.bike_turbo>charge,"turbo recarrega")
	s.add_bullet(a.p,Vector2.RIGHT,0,10,500,4,0)
	check(s.bullets[-1].v.length()>s.BikeHandling.TURBO,"tiro ultrapassa moto em turbo")
	var barrier: Rect2=s.BikeHandling.obstacles(s)[0]; a.p=barrier.get_center(); a.shield=0; a.hurt=0; a.invuln=0; var hp: float=a.hp
	s.BikeHandling.collide(s,a,a.p-Vector2(100,0))
	check(a.hp<hp and a.bike_speed==120,"barreira tira vida e velocidade")
	s.fall_off_bridge(a); a.hp=a.max_hp if a.has("max_hp") else s.HEART*6; a.dead=false; a.invuln=1000
	var elapsed:=0.0; var boost:=true
	while elapsed<35 and not s.bridge_done:
		var target_y: float=s.bridge_zone().get_center().y
		for box in s.BikeHandling.obstacles(s):
			if box.end.x+40<a.p.x: continue
			target_y=s.bridge_zone().position.y+(315 if box.get_center().y<s.bridge_zone().get_center().y else 85)
			break
		if a.get("bike_turbo",1.0)<0.15: boost=false
		elif a.get("bike_turbo",1.0)>0.85: boost=true
		var steering:=Vector2(1,clampf((target_y-a.p.y)/200,-0.75,0.75))
		s.step(1.0/60,[{"move":steering,"boost":boost,"aim":Vector2.RIGHT}]); elapsed+=1.0/60
	check(s.bridge_done,"corrida concluível com desvio e turbo: %.2fs" % elapsed)
	check(not a.bike and not s.bike.riding,"chegada desmonta automaticamente")
	check(a.get("bike_hit_cd",0.0)<=0,"pilotagem evita barreiras")
	var restored:=Expedition.new(); restored.apply_snapshot(s.snapshot().duplicate(true))
	check(restored.bridge_done and not restored.actors[0].bike,"snapshot conserva desembarque")
	# Holding straight on the centre line hits both alternating barrier lanes.
	s.start_run(1943); s.enemies.clear(); a=s.actors[0]; a.p=s.run_points.bike_checkpoint; a.bike=true; s.bike.riding=true; a.invuln=1000
	var collisions:=0
	for i in 1500:
		var previous_cd: float=a.get("bike_hit_cd",0.0)
		s.step(1.0/60,[{"move":Vector2.RIGHT}])
		if a.get("bike_hit_cd",0.0)>previous_cd: collisions+=1
		if s.bridge_done: break
	check(collisions>0 and not s.bridge_done,"segurar reto sem desviar não completa corrida")
	var legacy:=s.snapshot().duplicate(true); legacy.layout_manifest.erase("titan_copy_version"); legacy.enemies=[]; legacy.captured_robots=[]
	restored.apply_snapshot(legacy)
	check(restored.enemies.any(func(e):return e.get("titan_copy",false)),"save antigo recebe cópia capturável")
	var count: int=restored.enemies.size(); restored.apply_snapshot(restored.snapshot().duplicate(true))
	check(restored.enemies.size()==count,"migração não duplica cópia")
	print("TRAVERSAL_REVISION failures=",failures)
	quit(0 if failures==0 else 1)
