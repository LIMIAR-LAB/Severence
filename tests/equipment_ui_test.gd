extends SceneTree

# 0.14: tela de Equipamento v2 — cartões com sprites do jogo, palco com retrato, Ômega lendária, LB/RB e foco p/ controle.
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _initialize() -> void:
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	var ui = app.menu
	ui.read_equipment(); ui.outfit_choice = "padrao"; ui.preview_kind = "o_padrao"; ui.show_screen("equipment")
	await process_frame; await process_frame
	check(ui.slot_buttons.has("o_padrao") and ui.slot_buttons.has("o_mecanico") and ui.slot_buttons.has("o_espiao"), "3 cartões de uniforme")
	check(ui.slot_buttons.has("armor_omega") and ui.slot_buttons.has("robot0") and ui.slot_buttons.has("robot1"), "vaga da armadura e 2 robôs")
	check(ui.preview.texture != null and ui.preview.texture.resource_path.ends_with("portraits_v3/o_padrao.png"), "palco mostra a arte v3 do uniforme")
	var focus: Control = root.get_viewport().gui_get_focus_owner()
	check(focus == ui.slot_buttons["o_padrao"], "uniforme atual recebe o foco (navegação pelo controle)")
	ui.cycle_outfit(1)
	check(ui.outfit_choice == "mecanico" and ui.preview.texture.resource_path.ends_with("o_mecanico.png"), "RB troca para o Mecânico")
	ui.cycle_outfit(-1); ui.cycle_outfit(-1)
	check(ui.outfit_choice == "espiao", "LB volta em círculo até o Espião")
	ui.choose("armor_omega")
	check(ui.stage_title.text.contains("LENDÁRIA") and ui.preview.texture.resource_path.ends_with("armor_omega.png"), "Ômega aparece como lendária no palco")
	ui.choose("spectre")
	check(ui.robot_choice == "spectre" and ui.info_titles[2].text.contains("SPECTRE"), "escolher Spectre atualiza o companheiro")
	var icon: TextureRect = ui.info_icons[0]
	check(icon.texture is AtlasTexture and (icon.texture as AtlasTexture).atlas.resource_path.ends_with("outfits.png"), "descrições usam o sprite do jogo")
	ui.show_screen("main"); await process_frame; await process_frame
	check(root.get_viewport().gui_get_focus_owner() is Button, "menu principal já abre com um botão focado")
	print("EQUIPMENT_UI_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
