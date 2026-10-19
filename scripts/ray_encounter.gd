extends RefCounted
## Encounter state lives in the enemy dictionary and travels with existing saves.
static func owns(sim, e: Dictionary) -> bool:
	return sim.mode=="run" and e.get("kind","")=="golem" and e.get("room","")=="cranes"

static func protected_enemy(sim,e: Dictionary) -> bool:
	return owns(sim,e) and e.get("ray_state","waiting")!="active"

static func target_for(sim,e: Dictionary) -> Dictionary:
	var room: Dictionary=sim.room_by_id("cranes")
	var best: Dictionary={}
	var distance:=INF
	for a in sim.actors:
		if not a.active or a.dead or not sim.room_contains(room,a.p): continue
		if a.p.distance_to(e.p)<distance: best=a; distance=a.p.distance_to(e.p)
	return best

static func blink_point(sim,e: Dictionary,a: Dictionary) -> Vector2:
	var facing: Vector2=a.get("facing",Vector2.DOWN).normalized()
	if facing==Vector2.ZERO: facing=Vector2.DOWN
	for angle in [0.0,0.45,-0.45,0.9,-0.9,1.4,-1.4]:
		for distance in [110.0,150.0,190.0]:
			var p: Vector2=a.p-facing.rotated(angle)*distance
			if not sim.enemy_room_position_valid(e,p,26) or not sim.line_of_fire(p,a.p): continue
			if sim.actors.any(func(other):return other.active and not other.dead and other.p.distance_to(p)<55): continue
			return p
	return Vector2.INF

static func zone(sim,e: Dictionary,p: Vector2,radius: float,warning: float) -> void:
	if sim.combat_zones.size()>=sim.MAX_COMBAT_ZONES: return
	sim.combat_zones.append({"p":p,"r":radius,"damage":sim.HEART,"kind":"blast","warning":warning,"life":0.1,"cd":0.0,"ray_owner":e.id})

static func resolve_zone(sim,z: Dictionary) -> void:
	var owner: Array=sim.enemies.filter(func(e):return e.id==z.ray_owner and e.hp>0 and not e.get("stunned",false))
	if owner.is_empty(): return
	sim.effects.append({"kind":"explosion","p":z.p,"r":z.r,"life":0.55,"max":0.55})
	sim.emit_audio("explosion",z.p)
	for a in sim.actors:
		if a.active and not a.dead and a.p.distance_to(z.p)<z.r and sim.line_of_fire(z.p,a.p):
			sim.damage_actor(a,z.damage,"golem","blast")

static func step(sim,e: Dictionary,dt: float) -> bool:
	if not owns(sim,e): return false
	if e.get("stunned",false): e["ray_state"]="defeated"; return true
	var room: Dictionary=sim.room_by_id("cranes")
	var target:=target_for(sim,e)
	if e.get("ray_state","waiting")!="active":
		e["ray_state"]="waiting"; e.dormant=true; e.combat="ready"
		if not room.get("cleared",false) or sim.room_threats("cranes")>0 or target.is_empty() or target.p.distance_to(e.p)>480: return true
		e.ray_state="active"; e.dormant=false; e.alerted=true
		e["ray_phase"]="recover"; e["ray_timer"]=0.8; e["ray_cycle"]=0
		sim.say("TITAN DO CULTO ATIVADO • evite as rajadas e saia das áreas marcadas!")
	if target.is_empty():
		e.ray_phase="recover"; e.ray_timer=0.8; e.combat="ready"
		return true
	e.face=(target.p-e.p).normalized()
	e["ray_timer"]=float(e.get("ray_timer",0.8))-dt
	var phase: String=e.get("ray_phase","recover")
	if phase=="recover":
		sim.tactical_move(e,target,dt)
		if e.ray_timer>0: return true
		var cycle:=int(e.get("ray_cycle",0))%3
		e.ray_cycle=cycle+1; e["locked"]=target.p; e.target_id=target.id
		e.combat="warning"
		if cycle==0:
			e.ray_phase="cannon_warning"; e.ray_timer=0.55
		elif cycle==1:
			e.ray_phase="missiles"; e.ray_timer=1.15
			for offset in [Vector2(-105,0),Vector2.ZERO,Vector2(105,0)]:
				var impact: Vector2=target.p+offset
				if not sim.enemy_room_position_valid(e,impact,8): continue
				zone(sim,e,impact,76,1.0)
				sim.add_bullet(sim.enemy_muzzle_position(e),(impact-e.p).normalized(),1,0,300,7,-1,"cannon",1.0)
				sim.bullets[-1].merge({"arc":true,"ray_missile":true,"from":sim.enemy_muzzle_position(e),"to":impact,"flight":0.85},true)
		else:
			var destination:=blink_point(sim,e,target)
			if not destination.is_finite(): e.ray_phase="recover"; e.ray_timer=0.65; e.combat="ready"; return true
			e["ray_destination"]=destination; e["ray_blinked"]=false
			e.ray_phase="blink"; e.ray_timer=0.7
			zone(sim,e,destination,150,0.7)
	elif phase=="cannon_warning" and e.ray_timer<=0:
		e.ray_phase="cannon"; e.ray_timer=0.0; e["ray_shots"]=0; e.combat="attack"
	elif phase=="cannon" and e.ray_timer<=0:
		if sim.line_of_fire(e.p,target.p):
			var muzzle: Vector2=sim.enemy_muzzle_position(e)
			sim.add_bullet(muzzle,(target.p-muzzle).normalized(),1,sim.HEART,390,9,-1,"p_heavy")
			sim.bullets[-1]["source"]="golem"; sim.bullets[-1]["height"]=0.0
			e.shot=0.22; sim.emit_audio("enemy_guard",e.p)
		e.ray_shots+=1; e.ray_timer=0.18
		if e.ray_shots>=4: e.ray_phase="recover"; e.ray_timer=0.7; e.combat="recover"
	elif phase=="blink":
		if not e.ray_blinked and e.ray_timer<=0.24:
			if sim.enemy_room_position_valid(e,e.ray_destination,26) and not sim.actors.any(func(a):return a.active and not a.dead and a.p.distance_to(e.ray_destination)<55):
				sim.effects.append({"p":e.p,"kind":"summon","life":0.3,"dir":Vector2.UP})
				e.p=e.ray_destination
			e.ray_blinked=true
		if e.ray_timer<=0: e.ray_phase="recover"; e.ray_timer=0.85; e.combat="recover"
	elif phase=="missiles" and e.ray_timer<=0:
		e.ray_phase="recover"; e.ray_timer=0.6; e.combat="recover"
	return true
