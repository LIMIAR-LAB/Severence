extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func _init() -> void:
	var sim := Expedition.new()
	sim.make_hub()
	sim.step_dog(0.1)
	check(sim.hub_dog.is_empty(),"resgate continua necessário")
	sim.story_flags["missao_cachorro"]="encontrado"
	sim.step_dog(0.1)
	var safe := true
	var bounded := true
	var route_seen := {}
	for i in 3600:
		var previous: Vector2=sim.hub_dog.p
		sim.step_dog(1.0/30.0)
		safe = safe and sim.clear_at(sim.hub_dog.p,sim.HUB_DOG_RADIUS)
		bounded = bounded and previous.distance_to(sim.hub_dog.p)<=sim.HUB_DOG_SPEED/30.0+0.001
		route_seen[sim.hub_dog.waypoint]=true
	check(safe,"dois minutos de passeio respeitam pisos e obstáculos")
	check(bounded and route_seen.size()==4,"percorre a rota inteira sem saltos")
	sim.hub_dog.p=Vector2(760,560)
	sim.step_dog(0.016)
	check(sim.clear_at(sim.hub_dog.p,sim.HUB_DOG_RADIUS),"recupera posição inválida de sessão antiga")
	# Put a thin wall across the entire route. A large delta must not tunnel through it.
	sim.obstacles.append(Rect2(720,380,190,4))
	sim.hub_dog.p=Vector2(770,335); sim.hub_dog.waypoint=3
	sim.step_dog(10.0)
	check(sim.hub_dog.p.y<380 and sim.clear_at(sim.hub_dog.p,sim.HUB_DOG_RADIUS),"não atravessa parede mesmo com intervalo grande")
	sim.hub_dog.state="licking"; sim.hub_dog.lick_t=0.9
	var stopped: Vector2=sim.hub_dog.p
	sim.step_dog(0.4)
	check(sim.hub_dog.p==stopped and sim.hub_dog.velocity==Vector2.ZERO,"lambida pausa o passeio")
	print("DOG_HUB_COLLISION failures=",failures)
	quit(0 if failures==0 else 1)
