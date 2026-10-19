extends SceneTree

# P8 — golden mutante: escondido no Contrabando, lambida que cura, teleporte pro Refúgio.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := Expedition.new()
	s.coop = "solo"; s.start_run(1941)
	var a: Dictionary = s.actors[0]

	# ── Spawn preguiçoso na sala secreta ──
	check(s.dog.is_empty(), "cachorro só existe quando a run resolve o mapa")
	s.step(0.016, [{}])
	var secret := s.room_by_id("secret")
	check(not s.dog.is_empty() and secret.r.has_point(s.dog.p), "golden escondido no Contrabando")
	check(s.dog.state == "hiding", "começa escondido")

	# ── Encontro: lambida + cura total + coração ──
	a.hp = 10.0
	a.p = s.dog.p + Vector2(50, 0)
	s.step(0.016, [{}])
	check(s.dog.state == "licking", "encontrar dispara a lambida gigante")
	check(a.hp == s.max_hp(), "lambida restaura a vida inteira")
	check(s.effects.any(func(fx): return fx.kind == "heart"), "coração aparece sobre Marty")
	check(s.message.contains("GOLDEN"), "Marty reage à língua gigante")

	# ── Teleporte pra base ──
	for _i in range(3): s.step(0.34, [{}])
	check(s.dog.state == "gone", "após a lambida ele some")
	check(s.story_flags.get("missao_cachorro") == "encontrado", "missão do cachorro concluída")
	check(s.effects.any(func(fx): return fx.kind == "summon"), "teleporte deixa efeito")
	check(s.missions_list().any(func(m): return m.title == "O BOM GAROTO" and m.done), "diário marca O BOM GAROTO concluída")

	# ── Ele não volta a se esconder ──
	s.step(0.5, [{}])
	check(s.dog.state == "gone", "não reaparece escondido nesta run")

	# ── Refúgio: vive na base e cura de novo ──
	s.make_hub()
	s.step(0.1, [{}])
	check(not s.hub_dog.is_empty(), "golden passa a viver no Refúgio")
	var wander0: Vector2 = s.hub_dog.p
	s.step(1.0, [{}])
	check(s.hub_dog.p != wander0, "vagabunda satisfeito pela base")
	var hero: Dictionary = s.actors[0]
	hero.hp = 20.0; hero.p = s.hub_dog.p + Vector2(30, 0)
	s.interact(hero)
	check(hero.hp == s.max_hp() and s.effects.any(func(fx): return fx.kind == "heart"), "E na base = lambida + cura")
	check(s.hub_dog.get("state") == "licking", "interação no Refúgio anima a lambida")
	var lick_position: Vector2 = s.hub_dog.p
	s.step_dog(0.45)
	check(s.hub_dog.p == lick_position and s.hub_dog.velocity == Vector2.ZERO, "para de passear durante a lambida")
	s.step_dog(0.5); s.step_dog(0.1)
	check(s.hub_dog.state == "idle" and s.hub_dog.p.distance_to(lick_position) < 5.0, "retoma passeio sem salto")

	# ── Snapshot preserva o cachorro ──
	var snap := s.snapshot()
	var s2 := Expedition.new(); s2.apply_snapshot(snap)
	check(s2.story_flags.get("missao_cachorro") == "encontrado", "flag do cachorro persistida")

	# ── Run nova com a missão já feita: não esconde de novo ──
	var s3 := Expedition.new()
	s3.story_flags["missao_cachorro"] = "encontrado"
	s3.coop = "solo"; s3.start_run(1941)
	s3.step(0.016, [{}])
	check(s3.dog.is_empty(), "encontrado não se esconde de novo em runs futuras")

	print("DOG_P8_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
