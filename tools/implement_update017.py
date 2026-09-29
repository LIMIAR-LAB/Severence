from pathlib import Path
p=Path('tools/build_docks_map.py');s=p.read_text(encoding='utf-8');at=s.index('# ─',s.index('def validate')) if False else s.index('def v2(')
block='''# 0.17: salas sem combate e paredes internas preservadas pelo gerador.
def inside_room(p, room):
    x,y,w,h=R[room]
    return x <= p[0] <= x+w and y <= p[1] <= y+h
ROOMS = [(i,n,("maze" if i=="warehouse" else "story" if i=="chapel" else k),f,r) for i,n,k,f,r in ROOMS]
OB[:] = [o for o in OB if not inside_room(o,"warehouse")]
GAPS[:] = [g for g in GAPS if not inside_room(g,"warehouse")]
SPAWNS[:] = [p for p in SPAWNS if not any(inside_room(p,r) for r in ["warehouse","chapel"])]
HAZ[:] = [h for h in HAZ if not any(inside_room(h["p"],r) for r in ["warehouse","chapel"])]
OB.extend([(5100,6000,90,650,"maze_wall"),(5680,6370,90,530,"maze_wall")])
for pos,kind,phase in [((5300,6800),"spikes",0),((5470,6150),"darts",0.8),((6000,6510),"steam",1.6)]:
    HAZ.append({"p":pos,"r":75,"damage":12,"trap":kind,"offset":phase})
CHESTS[:] = [c for c in CHESTS if not inside_room(c,"warehouse")]
CHESTS.append((6100,6100,False))

'''
s=s[:at]+block+s[at:]
line=next(l for l in s.splitlines() if 'L.append("const HAZARDS' in l)
s=s.replace(line,'    L.append("const HAZARDS := [\\n\\t" + ",\\n\\t".join(val(h) for h in HAZ) + "]")')
p.write_text(s,encoding='utf-8')
p=Path('scripts/simulation.gd');s=p.read_text(encoding='utf-8')
s=s.replace('var chests: Array = []','var chests: Array = []\n# 0.17: missão compartilhada pela equipe; salva e sincronizada.\nvar story_quest := 0\nvar dialogue_queue: Array = []\nconst STORY_NPC := Vector2(850, 4400)')
s=s.replace('return uniform_of(a).weapon','return a.get("weapon_override", uniform_of(a).weapon)')
s=s.replace('"r": radius, "life": life','"r": maxf(radius, 6.0) if team == 0 else radius * 1.12, "visual_r": maxf(radius, 6.0) / 0.8 if team == 0 else radius * 1.4, "life": life')
s=s.replace('func interact(a: Dictionary) -> void:\n','''func interact(a: Dictionary) -> void:
	if mode == "run" and a.p.distance_to(STORY_NPC) < 95:
		story_interact(a); return
	for chest in chests:
		if chest.get("reward", false) and not chest.open and a.p.distance_to(chest.p) < 85:
			open_reward(chest, a); return
''')
s=s.replace('if e.kind == "boss": boss_dead = true;', '''if e.kind == "warden" or e.get("miniboss", false):
			chests.append({"p": e.p, "open": false, "secret": false, "reward": true})
			say("MINIBOSS DERROTADO • baú dourado sem chave! [E]")
		if e.kind == "boss": boss_dead = true;''')
s=s.replace('"armor_unlocked", "unlocked",','"armor_unlocked", "unlocked", "story_quest", "dialogue_queue",')
s=s.replace('\t\th["cd"] = maxf', '\t\tif h.has("trap") and trap_phase(h) != "active": continue\n\t\th["cd"] = maxf')
s=s.replace('\t# Três estágios: a cada um', '\tif boss_motion(e, target, dt): return\n\t# Três estágios: a cada um')
s+='''
# 0.17: recompensas e narrativa sem consumir as chaves da expedição.
func open_reward(chest: Dictionary, a: Dictionary) -> void:
	if chest.open: return
	chest.open = true; chest["t"] = tick_time
	var tiers := ["pistol", "smg", "shotgun", "omega"]
	var current: String = a.get("weapon_override", uniform_of(a).weapon)
	var tier := tiers.find(current)
	if tier < tiers.size()-1:
		a["weapon_override"] = tiers[maxi(0,tier+1)]
		say("ARMA RECUPERADA • " + str(a.weapon_override).to_upper() + " • equipada nesta expedição")
	else:
		materials += 3; keys += 2; heal(a,2)
		say("ARSENAL COMPLETO • +3 materiais, +2 chaves e cura")
	effects.append({"p":chest.p,"kind":"chest_burst","life":1.3,"max":1.3,"secret":true})

func trap_phase(h: Dictionary) -> String:
	var t := fposmod(tick_time + float(h.get("offset",0)),4.0)
	return "safe" if t < 2.2 else ("warning" if t < 3.0 else "active")

func story_interact(a: Dictionary) -> void:
	if not dialogue_queue.is_empty():
		say(str(dialogue_queue.pop_front())); return
	if story_quest == 0:
		story_quest = 1
		dialogue_queue = ["A Adega Inundada abriga criaturas. Elimine todas e volte.","Eu guardo materiais e chaves para quem nos ajudar. [E para continuar]"]
		say("Pescador: o culto tomou nosso porto... [E]")
	elif story_quest == 1:
		var cellar := room_by_id("cellar")
		if visited.has("cellar") and not enemies.any(func(e): return e.hp > 0 and cellar.r.has_point(e.p)):
			story_quest = 2; materials += 4; keys += 2; heal(a,2)
			say("Pescador: você nos salvou! +4 materiais, +2 chaves e cura.")
		else: say("Pescador: limpe a Adega Inundada e volte aqui.")
	else: say("Pescador: o porto se lembrará de você, Marty.")

func boss_motion(e: Dictionary, target: Dictionary, dt: float) -> bool:
	var state: String = e.get("motion", "idle")
	if state == "idle":
		e["motion_cd"] = float(e.get("motion_cd", 2.5))-dt
		if e.motion_cd > 0: return false
		var arena: Rect2 = room_by_id("boss").get("r", Rect2(e.p-Vector2(800,600),Vector2(1600,1200)))
		var destination: Vector2 = arena.get_center()+Vector2(500*cos(e.phase*1.9),380*sin(e.phase*1.9))
		if not clear_at(destination,45): e.motion_cd=1.0; return false
		e["motion_to"]=destination; e["motion"]="warning"; e["motion_t"]=0.7
		e["motion_kind"]="dive" if e.hp/e.max <= 0.33 else ("charge" if e.hp/e.max <= 0.66 else "walk")
		return true
	e.motion_t -= dt
	if state == "warning":
		if e.motion_t <= 0: e.motion="moving"; e.motion_t=1.4
		return true
	var delta: Vector2 = e.motion_to-e.p
	e.p=move_body(e.p,delta.normalized()*minf(delta.length(),(440.0 if e.motion_kind == "charge" else 260.0)*dt),45)
	if e.motion_kind == "charge" and e.p.distance_to(target.p)<70: damage_actor(target,20)
	if e.motion_t <= 0 or delta.length()<12:
		e.motion="idle";e.motion_cd=3.0;e.cd=maxf(e.cd,0.5)
	return true
'''
p.write_text(s,encoding='utf-8')
p=Path('scripts/terminal_ui.gd');s=p.read_text(encoding='utf-8').replace('var s := floorf(fit) if fit >= 1.0 else fit','var s := fit # 0.17: ocupa a janela também entre escalas inteiras');p.write_text(s,encoding='utf-8')
p=Path('scripts/display_settings.gd');s=p.read_text(encoding='utf-8').replace('"normal": 0.82','"normal": 1.22');p.write_text(s,encoding='utf-8')
p=Path('scripts/main.gd');s=p.read_text(encoding='utf-8').replace('"unlocked": sim.unlocked.keys()', '"unlocked": sim.unlocked.keys(), "story_quest": sim.story_quest').replace('sim.armor_unlocked = data.get','sim.story_quest = clampi(int(data.get("story_quest", 0)),0,2)\n\tsim.armor_unlocked = data.get');p.write_text(s,encoding='utf-8')
