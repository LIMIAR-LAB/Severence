extends RefCounted
## State stays on the rider so snapshots preserve acceleration and turbo.
const CRUISE := 780.0
const TURBO := 1180.0

static func speed(a: Dictionary, cmd: Dictionary, dt: float) -> float:
	a["bike_hit_cd"] = maxf(0.0, a.get("bike_hit_cd",0.0)-dt)
	var moving: Vector2 = cmd.get("move",Vector2.ZERO)
	var charge: float = a.get("bike_turbo",1.0)
	var boosting: bool = cmd.get("boost",false) and moving.length()>0.1 and charge>0.02 and a.bike_hit_cd<=0
	a["bike_boosting"] = boosting
	a["bike_turbo"] = maxf(0,charge-dt/2.2) if boosting else minf(1,charge+dt/5.0)
	var target := (TURBO if boosting else CRUISE) if moving.length()>0.1 else 0.0
	if a.bike_hit_cd>0: target *= 0.4
	a["bike_speed"] = move_toward(a.get("bike_speed",0.0),target,1400.0*dt)
	return a.bike_speed

static func obstacles(sim) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var zone: Rect2 = sim.bridge_zone()
	if zone.size.x<zone.size.y: return result
	# Alternating barriers leave at least 210 world units for steering.
	for i in 12:
		var x: float = zone.position.x+1100+i*1120
		var y: float = zone.position.y+(35 if i%2==0 else 205)
		result.append(Rect2(x,y,78,160))
	return result

static func collide(sim,a: Dictionary,previous: Vector2) -> void:
	if a.get("bike_hit_cd",0.0)>0: return
	for box in obstacles(sim):
		var nearest := Geometry2D.get_closest_point_to_segment(box.get_center(),previous,a.p)
		if not box.grow(20).has_point(nearest): continue
		a["bike_speed"]=120.0; a["bike_hit_cd"]=0.9; a["bike_boosting"]=false
		sim.damage_actor(a,sim.HEART,"road","barrier")
		sim.emit_audio("hit",a.p)
		sim.effects.append({"p":a.p,"kind":"hit","life":0.3,"max":0.3})
		return

static func draw(ci,sim,view: Rect2) -> void:
	for box in obstacles(sim):
		if not box.intersects(view) or sim.bridge_broken.any(func(seg):return seg.has_point(box.get_center())): continue
		ci.draw_rect(box.grow(5),Color("09191f"))
		ci.draw_rect(box,Color("555264"))
		ci.draw_rect(box,Color("c9a469"),false,4)
		for y in range(int(box.position.y)+8,int(box.end.y)-8,24):
			ci.draw_line(Vector2(box.position.x+8,y),Vector2(box.end.x-8,y+12),Color("e8af43"),9)
		ci.draw_circle(box.position+Vector2(8,8),5,Color("ff7457"))
		ci.draw_circle(box.end-Vector2(8,8),5,Color("ff7457"))
	for fx in sim.effects:
		if fx.kind!="bridge_debris": continue
		var t: float=1.0-fx.life/fx.max
		for i in 9:
			var p: Vector2=fx.p+Vector2((i-4)*66,80*t*t+sin(i*2.4)*90)
			ci.visual_transform(p,sin(i*2.0)*t*2.0,Vector2.ONE*(1.0-t*0.65))
			ci.draw_rect(Rect2(-30,-8,60,16),Color(0.42,0.28,0.13,1.0-t))
			ci.draw_line(Vector2(-25,-3),Vector2(25,-3),Color(0.75,0.53,0.27,1-t),2)
		ci.visual_transform(Vector2.ZERO)
