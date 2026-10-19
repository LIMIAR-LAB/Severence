extends SceneTree

var failures := 0
func ride_command(s, a: Dictionary) -> Dictionary:
	var target_y: float=s.bridge_zone().get_center().y
	for box in s.BikeHandling.obstacles(s):
		if box.end.x+40<a.p.x: continue
		target_y=s.bridge_zone().position.y+(315 if box.get_center().y<s.bridge_zone().get_center().y else 85)
		break
	var boost: bool=a.get("test_boost",true)
	if a.get("bike_turbo",1.0)<0.15: boost=false
	elif a.get("bike_turbo",1.0)>0.85: boost=true
	a["test_boost"]=boost
	return {"move":Vector2(1,clampf((target_y-a.p.y)/200,-0.75,0.75)),"boost":boost,"aim":Vector2.RIGHT}
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	var a: Dictionary = s.actors[0]
	var zone := s.bridge_zone()
	check(zone.size.x / s.BIKE_SPEED == 20.0, "ponte horizontal tem 20 segundos de comprimento")
	check(s.room_by_id("forest").r.size.x == zone.size.x, "duas rotas paralelas grandes")
	check(s.room_by_id("boss").r.position.x == zone.end.x, "arena só no extremo leste")
	check(s.clear_at(s.run_points.bike_checkpoint, 11), "checkpoint livre antes da partida")
	check(s.bridge_segments().size() == 20, "20 segmentos seguem a velocidade real")
	var minibosses := s.enemies.filter(func(e): return e.get("boss_name", "") == "RAÍZ-PODRE")
	check(minibosses.size() == 1 and s.room_at(minibosses[0].p).get("id") == "forest", "miniboss preservado no mangue")
	minibosses[0].hp = 0; s.step_enemies(0.016)
	check(s.chests.any(func(c): return c.get("reward", false)), "miniboss deixa recompensa")
	s.enemies.clear()
	a.p = s.bike.p + Vector2(85, 0); s.interact(a)
	check(not a.get("bike", false), "montar exige empréstimo")
	a.p = s.bike.p; s.interact(a)
	while not s.dialogue_queue.is_empty(): s.interact(a)
	s.interact(a)
	check(not a.get("bike", false), "montar exige armadura")
	s.set_armor(a, true); a.armor_type = "azul"; s.interact(a)
	check(not a.get("bike", false), "outra armadura não substitui Ômega")
	a.armor_type = "omega"; s.interact(a)
	check(a.get("bike", false), "Ômega e empréstimo permitem montar")
	a.invuln = 100.0
	var elapsed := 0.0
	var observed_enemies := false
	var saved_midway := false
	while elapsed < 23.0 and not s.bridge_done:
		s.step(1.0 / 60.0, [ride_command(s,a)])
		elapsed += 1.0 / 60.0
		observed_enemies = observed_enemies or s.enemies.any(func(e): return e.get("bridge_attempt", false))
		if elapsed > 10.0 and not saved_midway:
			s.interact(a); check(a.get("bike", false), "desmontar durante travessia bloqueado")
			var midpoint := s.snapshot().duplicate(true)
			var restored := Expedition.new(); restored.apply_snapshot(midpoint.duplicate(true))
			check(restored.actors[0].p == a.p and restored.bridge_timer == s.bridge_timer and restored.actors[0].get("bike", false), "snapshot restaura tentativa no meio")
			for frame in 900:
				restored.step(1.0 / 60.0, [ride_command(restored,restored.actors[0])])
				if restored.bridge_done: break
			check(restored.bridge_done, "save no meio continua até chegada física")
			restored.apply_snapshot(midpoint.duplicate(true))
			restored.actors[0].p = restored.bridge_broken[0].get_center()
			restored.step_bridge(0.016)
			check(restored.actors[0].p == restored.run_points.bike_checkpoint and restored.bridge_timer < 0.0, "save no meio permite queda e reinício")
			saved_midway = true
		if not s.bridge_done and (s.room_at(a.p).get("id", "") == "boss" or s.boss_intro_seen):
			check(false, "introdução antecipada durante o percurso")
	check(s.bridge_done and elapsed >= 13.0 and elapsed < 23.0, "desvio e turbo completam corrida: %.2f" % elapsed)
	check(observed_enemies, "inimigos surgem durante a viagem")
	check(s.room_at(a.p).get("id") == "boss", "chegada física dentro da arena")
	check(s.bridge_broken.size() == 20, "ponte cai depois da chegada")
	check(not a.get("bike", false), "chegada desmonta automaticamente")
	s.start_run(1942); a = s.actors[0]; s.enemies.clear()
	a["bike"] = true; s.bike.riding = true
	a.p = Vector2(zone.position.x + 50, zone.get_center().y)
	for frame in 200: s.step(1.0 / 60.0, [{}])
	check(a.p == s.run_points.bike_checkpoint, "parar faz cair e retorna ao checkpoint")
	check(s.bridge_timer < 0 and s.bridge_broken.is_empty(), "ponte reparada para repetir")
	check(not s.enemies.any(func(e): return e.get("bridge_attempt", false)), "reinício remove inimigos da tentativa")
	a.p = Vector2(3900, -1700); s.bridge_timer = 1.0; s.step_bridge(0.01)
	check(not s.bridge_done, "posição ao norte sem destino não conclui travessia")
	s.start_run(1943); s.enemies.clear(); a = s.actors[0]; a.invuln = 1000
	a.p = Vector2(zone.position.x - 20, zone.get_center().y)
	s.step_actor(a, {"move": Vector2.RIGHT}, 0.2)
	check(a.p.x < zone.position.x, "entrada a pé na ponte é recusada")
	s.set_armor(a, true)
	a.transform = 0.0
	s.step_actor(a, {"move": Vector2.RIGHT, "dodge": true}, 0.016)
	check(a.p.x < zone.position.x, "blink Ômega não permite entrar a pé na ponte")
	s.set_armor(a, false)
	a.p = Vector2(4500, -600)
	for frame in 5200:
		s.step(1.0 / 60.0, [{"move": Vector2.RIGHT}])
		if s.room_at(a.p).get("id") == "boss": break
	check(s.room_at(a.p).get("id") == "boss", "mangue converge caminhando para a mesma arena")
	var legacy := s.snapshot().duplicate(true)
	legacy.rooms = legacy.rooms.filter(func(room): return room.id != "bridge")
	for room in legacy.rooms:
		if room.id == "boss": room.r = Rect2(3000, 400, 2400, 1800)
		elif room.id == "forest": room.r = Rect2(4600, 2800, 2100, 800); room["extra"] = [Rect2(5000, 1400, 400, 1400)]
		elif room.id == "antessala": room.r = Rect2(3200, 2400, 1400, 800)
	legacy.floors = []
	for room in legacy.rooms:
		legacy.floors.append(room.r); legacy.floors.append_array(room.get("extra", []))
	legacy.floors.append(Rect2(4500, 1400, 250, 1000))
	legacy.gaps = []; legacy.obstacles = []; legacy.obstacle_kinds = []; legacy.obstacle_hp = []
	legacy.enemies = []; legacy.doors = []; legacy.gate_blocks = []
	legacy.run_points.boss = Vector2(4200, 1200); legacy.run_points.extraction = Vector2(4200, 720)
	legacy.run_points.bike_checkpoint = Vector2(4300, 2700)
	legacy.bridge_done = false; legacy.bridge_timer = 0.5
	s.apply_snapshot(legacy)
	check(s.bridge_zone() == Rect2(4500, 1400, 250, 1000) and s.bridge_segments().size() == 8, "save antigo mantém ponte vertical")
	a = s.actors[0]; a["bike"] = true; a.p = Vector2(4620, 1420)
	s.step_bridge(0.01)
	check(s.bridge_done, "save antigo ainda permite chegada")
	legacy.erase("run_points"); legacy.erase("run_corridors"); legacy.erase("layout_manifest")
	s.apply_snapshot(legacy)
	check(s.run_points.bike_checkpoint == Vector2(4300, 2700) and s.run_points.boss == Vector2(4200, 1200), "save antigo sem pontos usa destinos legados")
	# Split-route co-op never pulls either player across the map.
	s.coop = "local"; s.start_run(1944)
	a = s.actors[0]; var partner: Dictionary = s.actors[1]
	a.p = s.run_points.bike_checkpoint
	partner.p = Vector2(4700, -600)
	s.step_gates()
	check(a.p == s.run_points.bike_checkpoint and partner.p == Vector2(4700, -600), "coop: entrada no mangue preserva ambos os jogadores")
	s.enemies.clear(); s.step_gates()
	a.p = Vector2(zone.position.x + 700, zone.get_center().y)
	s.spawn_enemy(a.p + Vector2(100, 0), "crawler")
	s.enemies[-1].hp = 0; s.step_enemies(0.016)
	check(s.enemies.any(func(e): return e.kind == "crawler_small"), "teste cria filhos do crawler na ponte")
	s.fall_off_bridge(a)
	check(not s.enemies.any(func(e): return e.get("room", "") == "bridge"), "queda também remove filhos do crawler")
	a.p = Vector2(zone.end.x + 100, zone.get_center().y)
	var partner_before: Vector2 = partner.p
	s.spawn_enemy(s.run_points.boss, "boss"); s.step_gates()
	check(partner.p == partner_before and not s.room_by_id("boss").get("locked", false), "coop: chegada não teleporta parceiro nem sela sua entrada")
	print("route_p12:", "OK" if failures == 0 else "%d falhas" % failures)
	quit(1 if failures > 0 else 0)
