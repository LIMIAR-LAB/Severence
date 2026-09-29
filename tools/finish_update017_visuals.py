from pathlib import Path
p=Path('scripts/world_view.gd');s=p.read_text(encoding='utf-8')
s=s.replace('func draw_obstacle(box: Rect2, kind: String) -> void:\n','''func draw_obstacle(box: Rect2, kind: String) -> void:
	if kind == "maze_wall":
		draw_rect(box,Color("222d39")); draw_rect(box,Color("81919c"),false,3)
		for y in range(int(box.position.y),int(box.end.y),28): draw_line(Vector2(box.position.x,y),Vector2(box.end.x,y),Color("111923"),2)
		return
''')
s=s.replace('func draw_chest(chest: Dictionary) -> void:\n','''func draw_chest(chest: Dictionary) -> void:
	if chest.get("reward",false):
		draw_circle(chest.p,44,Color(1,0.75,0.15,0.18))
		draw_arc(chest.p,34,0,TAU,32,GOLD,3)
		text_at(chest.p+Vector2(-65,-70),"ARSENAL • SEM CHAVE" if not chest.open else "RECUPERADO",GOLD,12)
''')
s=s.replace('func draw_boss(e: Dictionary) -> void:\n','''func draw_boss(e: Dictionary) -> void:
	if e.get("motion", "idle") == "warning":
		draw_arc(e.motion_to,75,0,TAU,48,Color("ffb451"),5)
		draw_line(e.p,e.motion_to,Color(1,0.4,0.2,0.6),4)
		text_at(e.motion_to-Vector2(50,85),"! MERGULHO" if e.motion_kind == "dive" else "! AVANÇO",GOLD,16)
	if e.get("motion", "idle") == "moving" and e.get("motion_kind", "") == "dive":
		draw_arc(e.p,60,0,TAU,32,CYAN,3); return
''')
s=s.replace('\t\tvar alert := false\n','''		if h.has("trap") and seen(h.p):
			var phase: String = sim.trap_phase(h)
			var color := Color("6f8a91") if phase == "safe" else (GOLD if phase == "warning" else Color("ff6048"))
			draw_circle(h.p,h.r,Color(color,0.12 if phase == "safe" else 0.3))
			draw_arc(h.p,h.r,0,TAU,32,color,3)
			text_at(h.p+Vector2(-32,-8),str(h.trap).to_upper(),color,14)
			if phase == "active":
				for n in range(5):
					var at: Vector2 = h.p+Vector2((n-2)*20,0)
					draw_line(at,at+Vector2(0,-35),color,6)
		var alert := false
''')
s=s.replace('\tvar drawable: Array = []','''	if sim.mode == "run" and seen(sim.STORY_NPC):
		var npc: Vector2 = sim.STORY_NPC
		draw_texture_rect_region(marty_anim,Rect2(npc-Vector2(48,92),Vector2(96,96)),Rect2(0,5*96,96,96),Color(0.65,0.85,1))
		text_at(npc+Vector2(-65,-105),"PESCADOR • E",GOLD,14)
	var drawable: Array = []''')
s=s.replace('\t\tif projectile_art.has(kind):','''		var visual_radius: float = b.get("visual_r",b.r)
		if b.team == 1:
			draw_circle(bullet_pos,visual_radius+2,Color("11101c"))
			draw_circle(bullet_pos,visual_radius,Color("f965ae"))
			draw_circle(bullet_pos,visual_radius*0.45,Color("fff4db"))
			continue
		if projectile_art.has(kind):''')
s=s.replace('draw_texture(tex, -tex.get_size() * 0.5)\n\t\t\tdraw_set_transform(Vector2.ZERO)','draw_texture_rect(tex, Rect2(-tex.get_size()*0.75,tex.get_size()*1.5),false)\n\t\t\tdraw_set_transform(Vector2.ZERO)')
p.write_text(s,encoding='utf-8')
p=Path('scripts/combat_hud.gd');s=p.read_text(encoding='utf-8').replace('\tfor pk in s.pickups:','''	var story: Dictionary = s.room_at(s.STORY_NPC)
	if not story.is_empty() and room_visible(s,story):
		var location: Vector2 = to_screen.call(s.STORY_NPC)
		if clip.has_point(location): draw_string(ThemeDB.fallback_font,location,"!",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ffd36a"))
	for pk in s.pickups:''');p.write_text(s,encoding='utf-8')
