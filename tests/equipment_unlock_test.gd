extends SceneTree

# 0.17: dados do equipamento batem com o jogo, o início é sem armadura/robô e as regras de desbloqueio funcionam.
const EquipmentData := preload("res://scripts/equipment_data.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	# dados
	check(EquipmentData.items().size() == 6 and EquipmentData.stats().size() == 6, "6 itens e 6 atributos no JSON")
	for it in EquipmentData.items():
		for key in ["id", "nome", "descricao", "atributos", "raridade", "icone", "card", "desbloqueio", "desbloqueado_no_inicio"]:
			if not it.has(key): check(false, "%s sem %s" % [it.get("id", "?"), key])
		for path in [it.icone, it.card, it.get("icone_bloqueado", "")]:
			if path != "" and not ResourceLoader.exists(path): check(false, "arquivo faltando: " + path)
	check(EquipmentData.starting_unlocks() == ["padrao", "omega", "titan", "spectre"], "Padrão, Ômega, Titan e Spectre liberados desde o início")
	var testing = Expedition.new()
	testing.set_unlocks(EquipmentData.starting_unlocks())
	testing.make_hub()
	check(testing.is_unlocked("omega"), "Armadura Ômega disponível desde o início")
	check(testing.is_unlocked("titan") and testing.is_unlocked("spectre"), "robôs disponíveis no Refúgio")
	check(testing.equip(0, "padrao", "titan"), "Titan pode ser equipado desde o início")
	check(testing.equip(0, "padrao", "spectre"), "Spectre pode ser equipado desde o início")
	var s = Expedition.new()
	for id in s.OUTFITS:
		var u: Dictionary = s.UNIFORMS[id]
		var w: Dictionary = s.WEAPONS[u.weapon]
		var at: Dictionary = EquipmentData.item(id).atributos
		check(int(at.velocidade) == int(u.speed) and int(at.golpe) == int(u.melee) and absf(float(at.dash) - u.dash_cd) < 0.001, "%s: velocidade/golpe/dash iguais ao jogo" % id)
		check(int(at.defesa) == roundi((1.0 - u.taken) * 100) and int(at.dano) == roundi(w.damage * w.count / w.cooldown), "%s: defesa e dano/seg iguais ao jogo" % id)
	check(EquipmentData.combine("padrao", "omega", "").final.vida == 6.0, "Ômega soma 3 corações de escudo")
	check(EquipmentData.combine("espiao", "", "titan").final.velocidade == 190.0, "Titan pilotado anda a 190")

	# início do jogo
	# Mantém a cobertura da progressão normal com a Ômega como equipamento inicial.
	s.set_unlocks(["padrao", "omega"])
	s.coop = "solo"; s.start_run(1941)
	var a: Dictionary = s.actors[0]
	check(a.selected_robot == "" and not s.mech.deployed, "começa sem robô e sem Titan no mapa")
	s.toggle_armor(a)
	check(a.armor and is_equal_approx(a.armor_time, 300.0), "R veste a Ômega inicial por 5 minutos")
	s.set_armor(a, false)
	check(not s.summon_robot(a), "C não invoca robô bloqueado")
	check(not s.equip(0, "mecanico", ""), "uniforme bloqueado não equipa")
	# Titan: encontrado na Oficina
	a.p = s.room_by_id("shop").r.get_center(); s.step(0.016, [{}, {}])
	check(s.is_unlocked("titan") and s.mech.deployed and a.selected_robot == "titan", "entrar na Oficina libera o Titan")
	check(s.new_unlocks.has("titan"), "desbloqueio marcado para salvar")
	# Spectre: desafio do gerador
	s.side_active = true; s.side_time = 30; s.enemies.clear(); s.step(0.016, [{}, {}])
	check(s.is_unlocked("spectre"), "desafio do gerador libera o Spectre")
	# chefe + expedições
	s.boss_dead = true; a.p = s.DOCKS.POINTS.extraction; s.interact(a)
	check(s.is_unlocked("omega") and s.is_unlocked("mecanico") and not s.is_unlocked("espiao"), "extração mantém Ômega e libera Mecânico (1 expedição)")
	s.clears = 2; s.check_unlocks()
	check(s.is_unlocked("espiao"), "2 expedições liberam o Espião")
	print("EQUIPMENT_UNLOCK_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
