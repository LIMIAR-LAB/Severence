extends SceneTree
const MAP = preload("res://scripts/docks_map.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
	else: print("PASS: ", label)
func _init() -> void:
	var s := Expedition.new()
	s.coop = "local"; s.start_run(1941)
	for p in [MAP.POINTS.spawn, MAP.POINTS.spawn2, MAP.POINTS.key]:
		check(s.clear_at(p,23), "ponto inicial/chave seguro para Titan")
	for radius in [11,23]:
		var ok := true
		# Centro → rua norte; centro → ponte leste. Sem teleporte nas amostras.
		for route in [[Vector2(1000,6550),Vector2(1000,5900)], [Vector2(1000,6510),Vector2(2400,6510)]]:
			for i in range(101):
				if not s.clear_at(route[0].lerp(route[1],i/100.0), radius): ok=false
		check(ok,"rotas norte/leste livres, raio %d"%radius)
	for p in [Vector2(400,6600),Vector2(1200,7100),Vector2(2050,6800),Vector2(1750,6300)]:
		check(not s.clear_at(p,11),"navio, mar e carga pintada bloqueiam: %s"%p)
	check(s.doors.filter(func(d): return d.room=="entry").size()==2,"duas portas da entrada composta")
	check(not s.hazards.any(func(h): return MAP.ENTRY_ART_BOUNDS.has_point(h.p)),"sem perigos invisíveis antigos")
	for e in s.enemies:
		if e.room=="entry": check(s.clear_at(e.p,16),"inimigo nasce sobre pedra")
	check(s.tick_time==0,"animação recomeça a cada expedição")
	s.tick_time=3.5
	var peer := Expedition.new(); peer.apply_snapshot(s.snapshot())
	check(peer.tick_time==s.tick_time,"animação sincronizada em coop")
	print("failures=",failures); quit(failures)
