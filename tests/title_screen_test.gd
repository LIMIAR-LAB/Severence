extends SceneTree

# Tela inicial unificada — cenário em vídeo, console vivo, estados e atalhos corretos.
var failures := 0
class SaveStateApp extends "res://scripts/main.gd":
	var fake_save := false
	var load_requested := false
	func has_saved_game() -> bool: return fake_save
	func load_game() -> bool: load_requested = true; return true

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _initialize() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Severence — Ecos do Tempo", "janela do Godot usa o nome oficial")
	var launcher := FileAccess.get_file_as_string("res://Jogar.cmd")
	check(launcher.contains("chcp 65001") and launcher.contains("start \"Severence — Ecos do Tempo\""), "lançador do Windows usa UTF-8 e o nome oficial")
	var app = SaveStateApp.new(); root.add_child(app)
	await process_frame
	var ui = app.menu
	ui.show_screen("main"); await process_frame; await process_frame
	check(ResourceLoader.exists("res://assets/ui/title/title_loop.ogv"), "vídeo da tela inicial no projeto (Theora)")
	check(ui.content.find_child("TitleLockup", true, false) is Control, "novo lockup pertence ao cenário")
	var lockup := ui.content.find_child("TitleLockup", true, false) as Control
	var title_primary := lockup.find_child("TitlePrimary", false, false) as Label
	var title_subtitle := lockup.find_child("TitleSubtitle", false, false) as Label
	check(title_primary != null and title_primary.text == "SEVERENCE", "linha principal usa o nome oficial")
	check(title_subtitle != null and title_subtitle.text == "ECOS DO TEMPO", "subtítulo usa o nome oficial")
	check(title_primary.get_combined_minimum_size().x <= title_primary.size.x and title_primary.get_combined_minimum_size().y <= title_primary.size.y, "glifos da linha principal cabem no lockup")
	check(title_subtitle.get_combined_minimum_size().x <= title_subtitle.size.x and title_subtitle.get_combined_minimum_size().y <= title_subtitle.size.y, "glifos do subtítulo cabem no lockup")
	var title_footer := ui.content.find_child("TitleFooter", true, false) as Label
	check(title_footer != null and title_footer.text == "SEVERENCE — ECOS DO TEMPO  •  PROTÓTIPO", "rodapé usa o nome oficial")
	check(ui.content.find_child("TitleCommandDeck", true, false) is Panel, "um único deck concentra toda a navegação")
	var scene_crop := ui.content.find_child("TitleStillCropped", true, false) as TextureRect
	check(scene_crop != null and scene_crop.texture is AtlasTexture and scene_crop.texture.region == Rect2(384, 107, 960, 537), "fundo recorta a sidebar na fonte sem distorção não uniforme")
	var title_scene := ui.content.find_child("TitleSceneCrop", true, false) as Control
	var final_bg_scale: Vector2 = ui.stage.scale * title_scene.scale
	check(is_equal_approx(final_bg_scale.x, final_bg_scale.y), "cenário mantém escala uniforme após o ajuste global")
	var video_rect: Rect2 = ui.title_video_rect()
	check(video_rect.position.x < 0 and video_rect.position.y < 0 and video_rect.end.x >= 1344 and video_rect.end.y >= 752, "vídeo cobre a área após recortar a marca antiga")
	var forced_fallback: Control = ui.unbranded_background("FallbackScene", "FallbackVisual", true)
	var fallback_visual: Node = forced_fallback.find_child("FallbackVisual", false, false)
	check(fallback_visual is Control and bool(fallback_visual.get("scene_only")), "ausência da imagem estática usa fallback sem marca antiga")
	forced_fallback.free()
	var button_ids := [0, 1, 2, 5, 6]
	var buttons: Array = button_ids.map(func(i): return ui.content.find_child("Title_%d" % i, true, false))
	check(buttons.all(func(b): return b is Button), "5 ações do conceito são controles vivos")
	var deck := ui.content.find_child("TitleCommandDeck", true, false) as Panel
	check(deck.find_children("*", "Button", true, false).size() == 5, "deck contém exatamente cinco ações")
	check(ui.content.find_child("Title_3", true, false) == null, "Expedição Direta foi removida")
	check(ui.content.find_child("Title_4", true, false) == null, "não existe botão separado de Carregar")
	check(ui.content.find_child("EncyclopediaButton", true, false) == null, "Arquivo permanece fora da tela inicial")
	check(buttons[0].disabled and not app.playing, "CONTINUAR desativado sem expedição ou save")
	var focus: Control = root.get_viewport().gui_get_focus_owner()
	check(focus == buttons[1], "foco inicial em NOVA EXPEDIÇÃO")
	check(not buttons[1].disabled and buttons[1].has_focus(), "somente uma ação habilitada inicia em foco")
	check(ui.content.find_child("TitleControlMask", true, false) == null, "não mascara a sidebar antiga com outro painel")
	check(ui.content.find_child("TitleNetworkStatus", true, false) is Label, "estado da rede ocupa área própria no rodapé")
	check(buttons[1].focus_next != NodePath(""), "navegação sequencial usa a ordem visual do deck")
	buttons[2].mouse_entered.emit(); await process_frame
	check(root.get_viewport().gui_get_focus_owner() == buttons[2], "hover transfere o foco e mantém um único destaque")
	app.playing = true; app.fake_save = true; ui.show_screen("main"); await process_frame; await process_frame
	var active_continue := ui.content.find_child("Title_0", true, false) as Button
	check(not active_continue.disabled, "CONTINUAR habilitado durante expedição ativa")
	check(root.get_viewport().gui_get_focus_owner() == active_continue, "expedição ativa prioriza CONTINUAR no foco")
	check(active_continue.get_theme_stylebox("normal").border_color == Color("56cdd4"), "expedição ativa promove CONTINUAR à ação principal")
	active_continue.pressed.emit(); check(not ui.visible and not app.paused and not app.load_requested, "CONTINUAR prioriza a expedição ativa mesmo quando também existe save")
	app.playing = false; ui.show(); ui.show_screen("main"); await process_frame
	var save_app := SaveStateApp.new(); root.add_child(save_app); await process_frame
	check(save_app.menu.content.find_child("Title_0", true, false).disabled, "CONTINUAR fica indisponível sem save")
	save_app.fake_save = true; save_app.menu.show_screen("main"); await process_frame
	var saved_continue := save_app.menu.content.find_child("Title_0", true, false) as Button
	check(not saved_continue.disabled, "CONTINUAR fica disponível com save")
	saved_continue.pressed.emit(); check(save_app.load_requested, "CONTINUAR carrega a expedição salva")
	save_app.queue_free(); await process_frame
	var targets := {1: "characters", 2: "online", 5: "options"}
	for i in targets:
		ui.show_screen("main"); await process_frame
		(ui.content.find_child("Title_%d" % i, true, false) as Button).pressed.emit()
		check(ui.screen == targets[i], "botão %d abre %s" % [i, targets[i]])
		if targets[i] != "online":
			var secondary_bg := ui.content.find_child("SecondaryMenuBackdrop", true, false) as TextureRect
			check(secondary_bg != null and secondary_bg.texture is AtlasTexture and secondary_bg.texture.region == Rect2(384, 107, 960, 537), "tela %s usa cenário sem a marca antiga" % targets[i])
			var secondary_scene := ui.content.find_child("SecondaryMenuScene", true, false) as Control
			var final_secondary_scale: Vector2 = ui.stage.scale * secondary_scene.scale
			check(is_equal_approx(final_secondary_scale.x, final_secondary_scale.y), "tela %s mantém fundo sem distorção" % targets[i])
	ui.show_screen("encyclopedia"); await process_frame
	var archive_bg := ui.content.find_child("ArchiveBackdrop", true, false) as TextureRect
	check(archive_bg != null and archive_bg.texture is AtlasTexture and archive_bg.texture.region == Rect2(384, 107, 960, 537), "Arquivo recorta a marca antiga do cenário")
	var archive_scene := ui.content.find_child("ArchiveBackdropScene", true, false) as Control
	var final_archive_scale: Vector2 = ui.stage.scale * archive_scene.scale
	check(is_equal_approx(final_archive_scale.x, final_archive_scale.y), "Arquivo mantém fundo sem distorção")
	ui.show_screen("characters"); await process_frame
	check(ui.content.find_child("CharacterMarty", true, false) is Button, "Marty selecionável")
	for i in range(1, 6):
		check(ui.content.find_child("CharacterLocked%d" % i, true, false).disabled, "personagem futuro %d bloqueado" % i)
	ui.content.find_child("CharacterMarty", true, false).pressed.emit()
	check(ui.screen == "play" and ui.content.find_child("LocalChoice", true, false) is Button, "escolha de Marty abre os três modos")
	ui.content.find_child("LocalChoice", true, false).pressed.emit()
	check(ui.screen == "equipment" and ui.pending_mode == "local", "coop local leva à configuração de equipamento")
	ui.content.find_child("Back", true, false).pressed.emit()
	check(ui.screen == "play", "equipamento volta à escolha do modo")
	ui.content.find_child("LocalChoice", true, false).pressed.emit()
	ui.content.find_child("Refuge", true, false).pressed.emit()
	check(app.playing and app.sim.coop == "local" and app.sim.mode == "hub", "coop local inicia no refúgio")
	print("TITLE_SCREEN_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
