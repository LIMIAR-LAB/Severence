extends SceneTree

# 0.17: tela de Equipamento modular — moldura + camadas, dois estados: começo do jogo (Padrão + Ômega)
# e tudo desbloqueado. Cards, ícones, textos e números vêm de data/equipamento.json.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func tex_name(r: TextureRect) -> String:
	return r.texture.resource_path.get_file() if r != null and r.texture != null else ""

func _initialize() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	var ui = app.menu
	var sim = app.sim

	# ── estado 1: começo do jogo ──
	sim.set_unlocks(["padrao", "omega"]); app.pref_outfit = "padrao"; app.pref_robot = "titan"
	ui.read_equipment(); ui.show_screen("equipment")
	await process_frame; await process_frame
	var eq = ui.equipment
	check(eq != null and ui.content.get_parent() == ui, "tela montada fora do stage (escala inteira)")
	var inventory_tab: Button = eq.find_child("MenuTab_0", true, false)
	check(tex_name(eq.get_child(0)) == "refuge_bg.png" and inventory_tab.icon.resource_path.ends_with("tab_inventory.svg"), "cenário contextual fica sob o chrome industrial com navegação iconográfica")
	for id in ["padrao", "mecanico", "espiao", "omega", "titan", "spectre"]:
		check(eq.slots.has(id), "slot do item " + id)
	check(tex_name(eq.slots.padrao.icon) == "icon_uniforme_padrao.png", "Padrão com o ícone dele")
	check(tex_name(eq.slots.mecanico.icon) == "icon_uniforme_mecanico_bloqueado.png" and eq.slots.mecanico.sub.text == "BLOQUEADO", "Mecânico bloqueado no início")
	check(tex_name(eq.slots.omega.icon) == "icon_armadura_omega.png", "Ômega liberada no início")
	check(tex_name(eq.slots.titan.icon) == "icon_robo_titan_bloqueado.png" and tex_name(eq.slots.spectre.icon) == "icon_robo_spectre_bloqueado.png", "robôs bloqueados no início")
	check(eq.find_child("EmptyArmor_1", true, false) != null and eq.find_child("EmptyRobot_2", true, false) != null, "vagas vazias com icon_slot_vazio")
	check(ui.armor_choice == "omega" and ui.robot_choice == "", "Ômega equipada e nenhum robô selecionado")
	check(eq.robot_label.text == "SEM ROBÔ", "painel do robô vazio")
	check(tex_name(eq.card) == "card_marty_padrao.png" and eq.card.modulate == Color.WHITE and not eq.card_lock.visible, "vitrine mostra o card do Padrão")
	check(eq.slots.padrao.frame.visible, "Padrão equipado com frame de seleção")
	eq.show_item("titan")
	check(tex_name(eq.card) == "card_titan.png" and eq.card.modulate.v < 0.4 and eq.card_lock.visible, "item bloqueado: card escurecido + cadeado")
	check(eq.desc_body.text.begins_with("Como desbloquear"), "descrição explica como desbloquear")
	ui.choose("titan")
	check(ui.robot_choice == "", "bloqueado não equipa")
	check(eq.numbers[0].text == "3" and eq.numbers[1].text == "320", "referência Padrão mantém 3 corações e velocidade 320")
	check(ui.find_child("INICIAR*", true, false) == null, "sem botão INICIAR ARENA")
	for b in ui.content.find_children("*", "Button", true, false):
		check(not b.text.contains("ARENA"), "nenhum botão de arena")

	# ── estado 2: tudo desbloqueado ──
	sim.set_unlocks(["padrao", "mecanico", "espiao", "omega", "titan", "spectre"])
	ui.read_equipment(); ui.show_screen("equipment")
	await process_frame; await process_frame
	eq = ui.equipment
	check(tex_name(eq.slots.mecanico.icon) == "icon_uniforme_mecanico.png" and eq.slots.mecanico.sub.text == "+ força", "Mecânico liberado")
	check(tex_name(eq.slots.omega.icon) == "icon_armadura_omega.png" and eq.slots.omega.frame.visible, "Ômega liberada com frame lendário")
	check(eq.slots.omega.frame.texture.resource_path.ends_with("frame_lendario.png"), "Ômega usa frame_lendario")
	check(ui.armor_choice == "omega" and ui.robot_choice == "titan", "Ômega e Titan equipados")
	ui.choose("o_mecanico")
	check(ui.outfit_choice == "mecanico" and tex_name(eq.card) == "card_marty_mecanico.png", "equipar o Mecânico troca o card")
	ui.choose("spectre")
	check(ui.robot_choice == "spectre" and eq.robot_label.text == "SPECTRE", "equipar o Spectre")
	eq.show_item("omega")
	check(eq.numbers[0].text == "3" and eq.numbers[1].text == "290", "Ômega não altera a referência do Mecânico")
	eq.show_item("mecanico")
	check(eq.numbers[4].text == "+15%", "Spectre não adiciona defesa fictícia ao Mecânico")
	eq.show_tab(4)
	check(eq.find_child("MartyReference_0", true, false).text == "3", "painel visível mantém três corações com Spectre e Ômega")
	check(eq.find_child("OmegaReference_0", true, false).text == "3 corações", "escudo temporário separado da vida")
	eq.pick("titan"); eq.show_tab(4)
	check(eq.find_child("MartyReference_0", true, false).text == "3" and eq.find_child("RobotReference_0", true, false).text == "240", "Titan mantém integridade separada da vida de Marty")
	var before: String = eq.focus_id
	ui.cycle_outfit(1)
	check(eq.focus_id != before, "LB/RB e setas passam pelos itens da vitrine")
	print("EQUIPMENT_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
