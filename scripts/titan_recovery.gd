extends RefCounted
## The cult machine is recovered first; the generator and Admiral restore it.
static func original(sim,e: Dictionary) -> bool:
	return sim.RayEncounter.owns(sim,e)

static func ready(sim) -> bool:
	return sim.story_flags.get("titan_chassis",false) and sim.story_flags.get("titan_power",false) and sim.story_flags.get("peca_titan",false)

static func install_copy(sim) -> void:
	if sim.mode!="run" or sim.layout_manifest.get("titan_copy_version",0)>=1: return
	sim.layout_manifest["titan_copy_version"]=1
	if "sentinela" in sim.captured_robots or sim.enemies.any(func(e):return e.get("titan_copy",false)): return
	sim.uid=maxi(sim.uid,sim.enemies.reduce(func(value,e):return maxi(value,int(e.id)),0))
	sim.spawn_enemy(sim.run_points.mech,"sentinela")
	sim.enemies[-1]["titan_copy"]=true

static func secure(sim,e: Dictionary) -> bool:
	if not original(sim,e): return false
	sim.story_flags["titan_chassis"]=true
	sim.enemies.erase(e)
	sim.check_unlocks()
	sim.say("TITAN RECUPERADO • chassi protegido do culto. Restaure a energia no Gerador e recupere o núcleo do Almirante.")
	return true

static func mission(sim) -> Dictionary:
	var chassis: bool=sim.story_flags.get("titan_chassis",false)
	var power: bool=sim.story_flags.get("titan_power",false)
	var core: bool=sim.story_flags.get("peca_titan",false)
	var done: bool=sim.is_unlocked("titan")
	var objective := "Neutralize o Titan protegido pelo culto nos Guindastes e recupere com E"
	if chassis: objective="Conclua o ritual do Último Gerador para restaurar a alimentação"
	if chassis and power: objective="Derrote o Almirante e extraia seu núcleo para restaurar o Titan"
	if done: objective="Titan restaurado: C invoca e E pilota"
	return {"title":"A MÁQUINA DO CULTO","objective":objective,"progress":"Chassi %s • energia %s • núcleo %s" % ["✓" if chassis else "—","✓" if power else "—","✓" if core else "—"],"reward":"TITAN pilotável recuperado do culto","done":done}
