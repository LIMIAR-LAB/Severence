extends RefCounted
static func targets(sim) -> Array:
	var result: Array=[]
	if sim.mode!="run": return result
	if not sim.reward_claimed:
		result.append({"p":sim.run_points.extraction if sim.boss_dead else sim.run_points.boss,"label":"EXTRAÇÃO" if sim.boss_dead else "ALMIRANTE"})
	if sim.story_quest<2:
		var cellar: Dictionary=sim.room_by_id("cellar")
		var clean: bool=sim.visited.has("cellar") and not sim.enemies.any(func(e):return e.hp>0 and cellar.r.has_point(e.p))
		result.append({"p":cellar.r.get_center() if sim.story_quest==1 and not clean else sim.story_npc_position(),"label":"RITUAL"})
	if not sim.is_unlocked("titan"):
		if not sim.story_flags.get("titan_chassis",false): result.append({"p":sim.room_by_id("cranes").r.get_center(),"label":"TITAN"})
		elif not sim.story_flags.get("titan_power",false): result.append({"p":sim.run_points.side,"label":"ENERGIA TITAN"})
	if sim.side_active: result.append({"p":sim.run_points.side,"label":"GERADOR"})
	for e in sim.enemies:
		if e.get("capturable",false) and not sim.TitanRecovery.original(sim,e): result.append({"p":e.p,"label":"CAPTURAR"})
	if sim.story_flags.get("missao_cachorro","")=="procurar" and not sim.dog.is_empty(): result.append({"p":sim.dog.p,"label":"BOM GAROTO"})
	return result
