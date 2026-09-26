extends SceneTree

# 0.14: vida inicial fixa em 3 corações e STATUS da tela de Equipamento coerente com o jogo real.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func find(rows: Array, label: String) -> Array:
	for r in rows:
		if r[0] == label: return r
	return []

func _init() -> void:
	var s = Expedition.new()
	s.upgrade = 3; s.materials = 10
	s.start_run(1941)
	check(s.max_hp() == 3 * s.HEART and s.actors[0].hp == 3 * s.HEART, "começa com 3 corações mesmo com melhorias salvas")
	s.make_hub(); var a: Dictionary = s.actors[0]
	a.p = Vector2(330, 335); var mats: int = s.materials; s.interact(a)
	check(s.materials == mats and s.max_hp() == 3 * s.HEART, "bancada não compra corações por enquanto")
	s.heal(a, 5)
	check(a.hp <= 3 * s.HEART, "cura nunca passa de 3 corações")
	# armas: o tiro real usa os mesmos números mostrados na tela
	s.start_arena()
	for outfit in ["padrao", "mecanico", "espiao"]:
		a = s.actors[0]; a.outfit = outfit; a.armor = false; a.shot = 0; a.mech = false
		s.bullets.clear(); s.fire_actor(a)
		var w: Dictionary = s.WEAPONS[s.UNIFORMS[outfit].weapon]
		var total := 0.0
		for b in s.bullets: total += b.damage
		var rows: Array = s.loadout_stats("uniform", outfit)
		var dmg_row: Array = find(rows, "DANO / TIRO")
		var shown := float(dmg_row[1].split("×")[0]) * float(dmg_row[1].split("×")[1]) if "×" in dmg_row[1] else float(dmg_row[1])
		check(is_equal_approx(total, shown) and is_equal_approx(a.shot, w.cooldown), "%s: dano por disparo (%s) e cadência batem com o jogo" % [outfit, dmg_row[1]])
		check(find(rows, "VELOCIDADE")[1] == str(int(s.UNIFORMS[outfit].speed)) and find(rows, "CORAÇÕES")[1] == "3", "%s: velocidade e corações" % outfit)
	var titan: Array = s.loadout_stats("titan")
	check(find(titan, "INTEGRIDADE")[1] == str(int(s.new_mech(Vector2.ZERO).hp)) and find(titan, "CANHÃO")[1].begins_with(str(int(s.MECH_SHELL.damage))), "Titan: integridade e canhão reais")
	var omega: Array = s.loadout_stats("omega")
	check(find(omega, "VELOCIDADE")[1] == str(int(s.ARMORS.omega.speed)) and find(omega, "LÂMINA")[1].ends_with(str(int(s.SWORD.finisher))), "Ômega: velocidade e lâmina reais")
	var sp: Array = s.loadout_stats("spectre")
	check(find(sp, "ENERGIA")[1] == str(int(s.SPECTRE_HP)), "Spectre: energia real")
	print("HEARTS_STATS_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
