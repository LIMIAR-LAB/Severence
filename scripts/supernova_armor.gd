extends RefCounted
const DAMAGE := 32.0
const PULSE_DAMAGE := 72.0
const PULSE_RADIUS := 210.0
const PULSE_COOLDOWN := 6.0
const ART := "res://assets/characters/marty/supernova/v1/atlas.png"
static var texture: Texture2D

static func active(a: Dictionary) -> bool:
	return a.get("armor",false) and a.get("armor_type","")=="supernova" and not a.get("mech",false) and not a.get("fused",false)

static func fire(sim,a: Dictionary) -> void:
	if not active(a) or a.dead or a.transform>0 or a.shot>0: return
	var origin: Vector2=sim.move_body(a.p,a.aim*28,0,true)
	sim.add_bullet(origin,a.aim,0,DAMAGE,980,7,a.id,"p_supernova")
	sim.bullets[-1]["height"]=58.0
	a.shot=0.24; a.fire_flash=0.12
	sim.emit_audio("omega",a.p)

static func pulse(sim,a: Dictionary) -> void:
	if not active(a) or a.dead or a.transform>0 or a.get("nova_cd",0.0)>0: return
	a["nova_cd"]=PULSE_COOLDOWN
	for e in sim.enemies:
		if e.hp>0 and e.p.distance_to(a.p)<=PULSE_RADIUS and sim.line_of_fire(a.p,e.p): sim.hurt_enemy(e,PULSE_DAMAGE)
	for b in sim.bullets:
		if b.team==1 and b.p.distance_to(a.p)<=PULSE_RADIUS and sim.line_of_fire(a.p,b.p): b.life=0
	sim.effects.append({"p":a.p,"kind":"supernova_pulse","life":0.55,"max":0.55,"r":PULSE_RADIUS})
	sim.emit_audio("explosion",a.p)

static func draw(ci,a: Dictionary,p: Vector2,time: float) -> void:
	if texture==null: texture=load(ART)
	var row: int=posmod(roundi((PI*0.5-a.aim.angle())/(PI*0.25)),8)
	var cell := texture.get_size()/Vector2(4,2)
	var source := Rect2(Vector2(row%4,row/4)*cell,cell)
	var lift := 5.0+sin(time*5)*2.0
	var tint := Color.WHITE
	if a.dead: tint=Color(0.5,0.4,0.4)
	elif a.hurt>0: tint=Color(1.5,1.2,0.9)
	var scale := 0.52
	if a.dead: ci.visual_transform(p,PI*0.45)
	else: ci.visual_transform(p-Vector2(0,lift))
	ci.draw_texture_rect_region(texture,Rect2(Vector2(-128,-238)*scale,cell*scale),source,tint)
	if not a.dead:
		for x in [-14,14]:
			ci.draw_line(Vector2(x,-3),Vector2(x,8+sin(time*24+x)*3),Color("ffb750"),3)
	ci.visual_transform(Vector2.ZERO)
	if a.transform>0: ci.draw_arc(p-Vector2(0,45),56,0,TAU,40,Color(1,0.55,0.12,0.8),4)
	if a.get("shield",0)>0: ci.draw_arc(p-Vector2(0,48),60,0,TAU,40,Color(1,0.65,0.2,0.2),2)
	if a.dead: ci.text_at(p+Vector2(-40,-30),"E • REANIMAR",Color("ff945a"),12)

static func effects(ci,sim) -> void:
	for fx in sim.effects:
		if fx.kind!="supernova_pulse": continue
		var progress: float=1-fx.life/fx.max
		ci.draw_arc(fx.p,fx.r*sqrt(progress),0,TAU,64,Color(1,0.55,0.1,1-progress),8*(1-progress)+1)
		ci.draw_circle(fx.p,fx.r*progress,Color(1,0.75,0.25,(1-progress)*0.10))
