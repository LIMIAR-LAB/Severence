extends SceneTree
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func fixture() -> Expedition:
	var s:=Expedition.new(); s.mode="arena"; s.coop="ai"
	s.floors=[Rect2(-1000,-1000,3000,3000)]; s.obstacles.clear(); s.gate_blocks.clear(); s.hazards.clear(); s.combat_zones.clear()
	s.actors=[s.actor(0,Vector2(100,100)),s.actor(1,Vector2(100,100))]
	s.mech=s.new_mech(Vector2(120,100)); s.mech.deployed=false
	var a: Dictionary=s.actors[1]; a.armor=true; a.armor_type="omega"; a.armor_time=300; a.transform=0
	s.spawn_enemy(Vector2(400,100),"guard"); s.enemies[0].hp=10000
	return s
func _init() -> void:
	var s:=fixture(); var a: Dictionary=s.actors[1]
	var cmd:=s.ai_input()
	check(cmd.get("special",false),"IA aciona raio com alvo visível")
	var health: float=s.enemies[0].hp
	s.step_actor(a,cmd,0.1)
	check(a.beam_time>0 and s.enemies[0].hp<health,"comando causa dano real com raio")
	for i in 10: s.step_actor(a,s.ai_input(),0.1)
	check(a.beam_time>1.5 and a.beam_cd==0,"IA sustenta canalização entre quadros")
	s.obstacles=[Rect2(220,0,20,300)]
	s.step_actor(a,s.ai_input(),0.1)
	check(a.beam_time==0 and a.beam_cd>0,"parede interrompe raio e respeita recarga")
	s.obstacles.clear(); a.p=Vector2(100,100); a.shot=0; a.beam_cd=10
	s.enemies[0].p=Vector2(190,100)
	cmd=s.ai_input(); check(cmd.get("fire",false),"dispara arma temporária Ômega")
	s.step_actor(a,cmd,0.016)
	check(a.combo==1 and s.bullets.any(func(b):return b.kind=="p_omega"),"golpe produz combo e esfera Ômega")
	s.enemies[0].p=Vector2(650,100); a.p=Vector2(100,100); a.dodge_cd=0
	cmd=s.ai_input(); check(cmd.get("dodge",false),"teleporta para aproximar durante recarga do raio")
	s.step_actor(a,cmd,0.016)
	check(not s.live_shadows(a).is_empty() and a.p.x>400,"teleporte real deixa sombra")
	a.p=Vector2(100,100); a.dodge_cd=1
	check(not s.ai_input().get("dodge",false),"respeita recarga do teleporte")
	a.dodge_cd=0; s.hazards=[{"p":Vector2(420,100),"r":80}]
	check(not s.ai_input().get("dodge",false),"não teleporta para perigo no chão")
	s.hazards.clear(); s.bullets.clear(); a.p=Vector2(300,100); a.shadows=[{"p":Vector2(100,100),"t":s.tick_time}]
	s.bullets.append({"team":1,"p":Vector2(310,100),"v":Vector2.LEFT*100})
	cmd=s.ai_input()
	check(cmd.get("dodge",false) and cmd.move==Vector2.ZERO,"retorna à sombra segura para escapar de tiro")
	s.bullets.clear(); s.mech.deployed=true; s.mech.p=a.p
	check(not s.ai_input().get("interact",false),"não abandona forma ativa para embarcar no Titan")
	s.actors[0].dead=true; s.actors[0].p=a.p+Vector2(20,0)
	cmd=s.ai_input()
	check(cmd.get("interact",false) and not cmd.get("special",false),"reanimar parceiro tem prioridade")
	s.actors[0].dead=false; s.enemies.clear()
	check(not s.ai_input().get("special",false),"não gasta raio sem alvo")
	s=fixture(); s.actors[1].armor=false
	check(not s.ai_input().get("special",false),"forma normal não recebe habilidades Ômega")
	print("OMEGA_AI_ABILITIES failures=",failures)
	quit(0 if failures==0 else 1)
