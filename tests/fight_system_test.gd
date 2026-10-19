extends SceneTree

# Sistema de luta estilo SF: fraco/médio/forte, esquiva e especiais por comando.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func fresh() -> Expedition:
	var s := Expedition.new()
	s.coop = "solo"; s.start_arena()
	s.enemies.clear(); s.bullets.clear()
	var a: Dictionary = s.actors[0]
	a.hp = s.max_hp(); a.p = Vector2(400, 500); a.aim = Vector2.RIGHT
	return s

func _init() -> void:
	# Três forças: botões dedicados saltam direto para o estágio.
	var s := fresh()
	var a: Dictionary = s.actors[0]
	var base: float = s.uniform_of(a).melee

	s.melee(a, 0)
	check(absf(a.slash - 0.22) < 0.01 and a.punch == 0, "soco fraco é o jab (0.22s)")
	s.step(0.6, [])
	s.melee(a, 1)
	check(absf(a.slash - 0.34) < 0.01 and a.punch == 1, "soco médio é o direto (0.34s)")
	s.step(0.6, [])
	s.melee(a, 2)
	check(absf(a.slash - 0.52) < 0.01 and a.punch == 2, "soco forte é o uppercut (0.52s)")
	s.step(0.6, [])

	# Auto-combo preservado no botão fraco.
	s.melee(a); check(a.punch == 0, "combo recomeça no jab")
	s.step(0.4, []); s.melee(a); check(a.punch == 1, "combo encadeia no direto")

	# Hadouken: baixo -> frente + soco dispara projétil de energia.
	s = fresh(); a = s.actors[0]
	for i in range(6): s.step_actor(a, {"move": Vector2.DOWN}, 0.03)
	for i in range(6): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	s.step_actor(a, {"melee": true}, 0.016)
	var wave := s.bullets.filter(func(b): return b.get("kind", "") == "p_wave")
	check(wave.size() == 1, "meia lua (baixo→frente) + soco dispara o hadouken")
	if wave.size() == 1:
		check(wave[0].team == 0 and wave[0].damage > base * 0.8, "hadouken é projétil do jogador com dano de soco médio")
	check(str(s.message).contains("HADOUKEN"), "hadouken anuncia o golpe")

	# Hadouken forte: botão forte também sai com movimento (dano maior).
	s = fresh(); a = s.actors[0]
	for i in range(6): s.step_actor(a, {"move": Vector2.DOWN}, 0.03)
	for i in range(6): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	s.step_actor(a, {"melee_h": true}, 0.016)
	wave = s.bullets.filter(func(b): return b.get("kind", "") == "p_wave")
	check(wave.size() == 1 and wave[0].damage > base * 1.5, "hadouken forte bate mais e mais rápido")

	# Shoryuken: frente-baixo-frente + soco = uppercut invencível que lança.
	s = fresh(); a = s.actors[0]
	s.spawn_enemy(Vector2(460, 500), "warden")   # 420 HP: o shoryuken mostra o dano cheio sem matar
	for i in range(4): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	for i in range(4): s.step_actor(a, {"move": Vector2.DOWN}, 0.03)
	for i in range(4): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	var e: Dictionary = s.enemies[0]
	e.p = a.p + Vector2(50, 0)   # o ator andou durante o comando; alvo entra no arco
	var hp0: float = e.hp
	s.step_actor(a, {"melee": true}, 0.016)
	check(a.punch == 2 and absf(a.slash - 0.52) < 0.01, "frente-baixo-frente sai o shoryuken (anim do uppercut)")
	check(a.get("invuln", 0.0) > 0.2, "shoryuken concede i-frames de subida")
	check(e.hp <= hp0 - base * 1.9, "shoryuken causa dano pesado")
	check(str(s.message).contains("SHORYUKEN"), "shoryuken anuncia o golpe")

	# i-frames do shoryuken bloqueiam dano de verdade.
	var hp_a: float = a.hp
	s.damage_actor(a, 50, "brute", "test")
	check(a.hp == hp_a, "i-frames do shoryuken bloqueiam dano")

	# Esquiva (dash) segue com i-frames próprios.
	s = fresh(); a = s.actors[0]
	s.step_actor(a, {"dodge": true, "move": Vector2.RIGHT}, 0.016)
	check(a.dodge > 0, "botão de esquiva dispara o dash")
	s.damage_actor(a, 50, "brute", "test")
	check(a.hp == s.max_hp(), "esquiva não recebe dano durante o rolamento")

	# Toque duplo pra frente + soco também sai o shoryuken (spec do jogador).
	s = fresh(); a = s.actors[0]
	for i in range(3): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	for i in range(3): s.step_actor(a, {"move": Vector2.ZERO}, 0.03)
	for i in range(3): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	s.step_actor(a, {"melee": true}, 0.016)
	check(a.get("invuln", 0.0) > 0.2, "toque duplo pra frente + soco dispara o shoryuken")

	# Cooldown do especial: no intervalo, o comando vira soco normal.
	s = fresh(); a = s.actors[0]
	for i in range(6): s.step_actor(a, {"move": Vector2.DOWN}, 0.03)
	for i in range(6): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	s.step_actor(a, {"melee": true}, 0.016)
	check(s.bullets.filter(func(b): return b.get("kind", "") == "p_wave").size() == 1, "1º hadouken sai")
	check(a.get("sp_cd", 0.0) > 0, "especial entra em recarga")
	for i in range(6): s.step_actor(a, {"move": Vector2.DOWN}, 0.03)
	for i in range(6): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	s.step_actor(a, {"melee": true}, 0.016)
	check(s.bullets.filter(func(b): return b.get("kind", "") == "p_wave").size() == 1, "durante a recarga o comando vira soco normal")

	# Armas guardadas durante os golpes: não atira com slash ativo.
	s = fresh(); a = s.actors[0]
	s.step_actor(a, {"melee": true, "fire": true}, 0.016)
	check(s.bullets.is_empty(), "arma guardada enquanto o soco está ativo")

	# Titan não muda: soco único, sem especiais.
	s = fresh(); a = s.actors[0]
	a.mech = true; s.mech.occupant = a.id; s.mech.deployed = true; s.mech.hp = 300
	for i in range(6): s.step_actor(a, {"move": Vector2.DOWN}, 0.03)
	for i in range(6): s.step_actor(a, {"move": Vector2.RIGHT}, 0.03)
	s.melee(a, 1)
	check(s.bullets.is_empty(), "Titan não dispara hadouken — soco pesado segue igual")

	print("FIGHT_SYSTEM_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
