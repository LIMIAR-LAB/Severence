extends SceneTree
# 0.18: contratos de simulação, sem depender de renderer ou relógio real.
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)
func arena() -> Expedition:
	var s := Expedition.new(); s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.pending_spawns.clear(); s.bullets.clear(); s.effects.clear()
	s.actors[0].p = Vector2(600, 500)
	return s
func advance(s: Expedition, seconds: float) -> void:
	for frame in range(int(ceil(seconds / 0.01))): s.step_enemies(0.01)
func _init() -> void:
	var s := arena()
	for n in range(6): s.spawn_enemy(Vector2(350 + n * 30, 350), "cult"); s.enemies[-1].cd = 0
	s.step_enemies(0.01)
	check(s.attack_slots(0) == 3 and s.bullets.is_empty(), "limite três e aviso antes do tiro")
	advance(s, 0.45)
	check(s.bullets.is_empty(), "nenhum dano antes de 0,45s")
	advance(s, 0.15)
	check(s.bullets.size() == 3, "três atacantes disparam após aviso")
	var waiting_id: int = s.enemies[3].id
	advance(s, 0.7)
	check(s.enemies.filter(func(e): return e.id == waiting_id)[0].combat == "warning", "vagas circulam durante recuperação")
	s.actors[0].dead = true; s.step_enemies(0.01)
	check(s.attack_slots(0) == 0, "alvo morto libera reservas")
	s = arena(); s.spawn_enemy(Vector2(500,500), "cult"); s.enemies[0].cd = 0
	s.step_enemies(0.01); s.enemies[0].hp = 0; s.step_enemies(0.01)
	check(s.attack_slots(0) == 0, "morte cancela reserva")
	# Reserva não sobrevive à morte do alvo em coop enquanto o parceiro continua vivo.
	s = arena(); s.coop = "local"; s.actors[1].active = true; s.actors[1].p = Vector2(650,500)
	s.spawn_enemy(Vector2(400,500), "brute"); var attacker: Dictionary = s.enemies[0]
	attacker.merge({"combat":"attack", "combat_t":0.6, "target_id":0, "locked":s.actors[0].p, "burst":0, "burst_t":0.0}, true)
	s.actors[0].dead = true; s.step_enemies(0.01)
	check(attacker.combat == "ready" and s.attack_slots(0) == 0 and s.bullets.is_empty(), "morte do alvo em coop cancela ataque sem transferir reserva")
	# Soldado tem tempo de chegar a cobertura distante e recarregar abaixado.
	s = arena(); s.obstacles = [Rect2(600,400,40,40)]; s.obstacle_kinds = ["sandbags"]
	s.actors[0].p = Vector2(800,420); s.spawn_enemy(Vector2(350,420), "brute"); attacker = s.enemies[0]
	attacker.merge({"combat":"attack", "combat_t":0.001, "alerted":true, "target_id":0, "locked":s.actors[0].p, "burst":6, "burst_t":0.0}, true)
	s.step_enemies(0.01)
	check(attacker.has("cover") and attacker.combat_t > 2, "recuperação inclui percurso até cobertura")
	advance(s, 2.6)
	check(attacker.combat == "recover" and attacker.crouched, "soldado chega à cobertura e recarrega abaixado")
	# Projétil curvo acelera; orbe divide uma única vez.
	s = arena(); s.actors[0].p = Vector2(1000,700)
	s.add_bullet(Vector2(400,300), Vector2.RIGHT, 1, 12, 100)
	s.bullets[0].merge({"curve": 0.6, "accel": 200.0, "split_at": 0.4})
	s.step_bullets(0.2)
	check(s.bullets[0].v.y > 0 and s.bullets[0].v.length() > 100, "curvatura e aceleração")
	s.step_bullets(0.21)
	check(s.bullets.size() == 4 and s.bullets.all(func(b): return b.split_at < 0), "divisão em quatro filhos sem recursão")
	s.step_bullets(0.5); check(s.bullets.size() <= 4, "filhos não se dividem")
	s.bullets.clear(); s.add_bullet(s.actors[0].p, Vector2.ZERO, 1, 99, 0, 5, -1, "", 0.01)
	var health: float = s.actors[0].hp; s.step_bullets(0.02)
	check(s.actors[0].hp == health, "projétil expirado não causa dano")
	# Arco: sobrevoa sem hitbox, só o pouso cria área.
	s = arena(); health = s.actors[0].hp
	s.add_bullet(Vector2(400,500), Vector2.RIGHT, 1, 12, 100)
	s.bullets[0].merge({"arc": true, "from": Vector2(400,500), "to": s.actors[0].p, "flight": 0.9})
	s.step_bullets(0.45); s.step_combat_zones(0.01)
	check(s.actors[0].hp == health and s.combat_zones.is_empty(), "arco não causa dano antecipado")
	s.step_bullets(0.46); s.step_combat_zones(0.01)
	check(s.actors[0].hp < health and not s.combat_zones.is_empty(), "pouso ocupa área marcada")
	# Salto interrompido pela parede, com ácido e recuperação.
	s = arena(); s.spawn_enemy(Vector2(420,500), "crawler"); var crawler: Dictionary = s.enemies[0]
	crawler.cd = 0; s.step_enemies(0.01); s.obstacles.append(Rect2(490,400,25,200))
	advance(s, 1.4)
	check(crawler.p.x < 490 and crawler.combat == "recover" and s.combat_zones.any(func(z): return z.kind == "acid"), "salto respeita parede e deixa ácido")
	# 0.18: regressões da revisão — cancelamento, sala segura e escala do ácido.
	s = arena(); s.spawn_enemy(Vector2(420,500), "crawler"); crawler = s.enemies[0]
	crawler.cd = 0; s.step_enemies(0.01); advance(s, 0.8)
	check(crawler.get("jump_height", 0.0) > 0, "salto tem altura visual")
	s.actors[0].dead = true; s.step_enemies(0.01)
	check(crawler.jump_height == 0 and s.attack_slots(0) == 0, "perder alvo limpa salto e reserva")
	s = arena(); s.obstacles.clear(); s.mode = "run"
	s.rooms = [{"id":"fight","kind":"fight","r":Rect2(80,100,420,820)}, {"id":"safe","kind":"story","r":Rect2(500,100,700,820)}]
	s.spawn_enemy(Vector2(480,500), "crawler"); crawler = s.enemies[0]
	crawler.merge({"combat":"attack", "combat_t":0.7, "locked":Vector2(600,500), "launch":Vector2(480,500), "damage_scale":2.0, "target_id":0}, true)
	advance(s, 0.72)
	check(crawler.p.x < 500, "salto não invade sala segura")
	check(s.combat_zones.any(func(z): return z.kind == "acid" and z.damage == 24), "ácido respeita escala de dano")
	# Estacas temporárias não aparecem em cima de atores ou portas.
	s = arena(); s.lodge_harpoon(s.actors[0].p)
	check(s.harpoons.is_empty(), "arpão não bloqueia jogador")
	s.lodge_harpoon(Vector2(400,350)); check(not s.clear_at(Vector2(400,350), 10), "arpão cravado colide")
	s.step_combat_zones(4); check(s.harpoons.is_empty(), "arpão expira")
	# Elite explosivo: aviso único inclusive chamada repetida.
	s = arena(); s.spawn_enemy(Vector2(500,500), "cult"); s.enemies[0].elite = "explosive"; s.enemies[0].hp = 0
	s.step_enemies(0.01); s.step_enemies(0.01)
	check(s.combat_zones.size() == 1 and s.combat_zones[0].warning > 0.45, "elite morto anuncia uma única explosão")
	var copy := Expedition.new(); copy.apply_snapshot(s.snapshot().duplicate(true))
	check(copy.combat_zones == s.combat_zones and copy.enemies == s.enemies, "snapshot preserva ameaças")
	s.make_hub(); check(s.combat_zones.is_empty() and s.harpoons.is_empty() and s.bullets.is_empty(), "refúgio limpa combate temporário")
	# Esquadrões e elites reproduzíveis; áreas seguras sem inimigos.
	s.start_run(1827); copy.start_run(1827)
	check(s.enemies.map(func(e): return [e.p,e.kind,e.elite]) == copy.enemies.map(func(e): return [e.p,e.kind,e.elite]), "seed reproduz composição e modificadores")
	check(s.enemies.any(func(e): return e.kind == "bomber") and s.enemies.any(func(e): return e.kind == "guard"), "Docas contêm Bomber e Guard")
	check(s.enemies.all(func(e): return e.room not in ["warehouse", "chapel"]), "salas seguras sem encontros")
	check(s.enemies.filter(func(e): return e.room == "entry").all(func(e): return e.elite == ""), "entrada sem elites")
	print("COMBAT_FRAMEWORK failures=", failures)
	quit(1 if failures else 0)
