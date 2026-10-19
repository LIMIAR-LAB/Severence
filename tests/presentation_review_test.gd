extends SceneTree
const Main = preload("res://scripts/main.gd")
const Display = preload("res://scripts/display_settings.gd")
const HUD = preload("res://scripts/combat_hud.gd")
const Audio = preload("res://scripts/game_audio.gd")
var failures := 0
func check(ok: bool, caption: String) -> void:
	if not ok: failures += 1; push_error(caption)
	else: print("PASS: ", caption)
func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	run.call_deferred()
func run() -> void:
	check(OS.get_user_data_dir().replace("\\", "/").contains("/SeverenceTests/"), "isolated profile")
	var settings := Display.new()
	settings.from_dict({"camera_shake": -3, "screen_flash": 8})
	check(settings.camera_shake == 0 and settings.screen_flash == 1, "comfort values clamp")
	settings.from_dict({"camera_shake": "bad", "screen_flash": null})
	check(settings.camera_shake == 1 and settings.screen_flash == 1, "invalid comfort values retain compatible defaults")
	settings.camera_shake = 0.5; settings.screen_flash = 0
	var restored := Display.new(); restored.from_dict(settings.to_dict())
	check(restored.camera_shake == 0.5 and restored.screen_flash == 0, "comfort settings roundtrip")
	for viewport in [Vector2(1280,800), Vector2(1280,720), Vector2(984,615), Vector2(1720,720)]:
		var bounds := Rect2(Vector2.ZERO, viewport)
		check(bounds.encloses(HUD.resources_rect(viewport)), "resources inside viewport " + str(viewport))
		check(bounds.encloses(HUD.dialogue_rect(viewport)), "dialogue inside viewport " + str(viewport))
		check(not HUD.titan_rect(viewport).intersects(Rect2(viewport.x - 194, 14, 180,112)), "Titan avoids minimap " + str(viewport))
	var harpoon_size := DockView.projectile_size(Vector2(51,24), 1, "harpoon", 8)
	check(harpoon_size.x > harpoon_size.y and harpoon_size.x <= 72, "enemy harpoon preserves silhouette at readable bounded scale")
	var app := Main.new(); root.add_child(app); app.set_process(false); app.set_physics_process(false)
	await process_frame
	app.music_percent = 35; app.effects_percent = 0; app.set_volume(70)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Severence SFX")), "effects mute independently")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Severence Music")), "music stays enabled")
	app.display.camera_shake = 0; app.display.screen_flash = 0.5; app.save_settings()
	app.music_percent = 100; app.effects_percent = 100; app.display.camera_shake = 1; app.load_settings()
	check(app.music_percent == 35 and app.effects_percent == 0 and app.display.camera_shake == 0 and app.display.screen_flash == 0.5, "all new settings survive reload")
	app.menu.open("missions")
	await process_frame; await process_frame
	var scroll: ScrollContainer = app.menu.content.find_child("JournalScroll", true, false)
	var back: Button = app.menu.content.find_child("MissionsBack", true, false)
	var entries: Array = app.menu.content.find_children("JournalEntry*", "PanelContainer", true, false)
	check(entries.size() == app.sim.missions_list().size() + app.sim.journal_entries().size() and entries.size() >= 4 and scroll.follow_focus, "missions and four crew signals share focus-following journal")
	if not entries.is_empty():
		app.menu.focus_first(); await process_frame; await process_frame
		check(root.gui_get_focus_owner() == entries[0] and scroll.scroll_vertical == 0, "journal opens at first mission instead of last records")
		entries[0].grab_focus()
		for index in entries.size() - 1:
			var focused := root.gui_get_focus_owner()
			var next := focused.get_node(focused.focus_neighbor_bottom) as Control
			next.grab_focus()
			await process_frame
		await process_frame; await process_frame
		check(root.gui_get_focus_owner() == entries.back() and scroll.scroll_vertical > 0, "controller traversal reveals entries beyond initial viewport")
		check(entries.back().get_node(entries.back().focus_neighbor_bottom) == back, "last record leads to fixed back button")
	app.menu.show_operation_error("Checkpoint antigo: seu progresso mais recente foi preservado.")
	await process_frame
	var notice := app.menu.get_node("OperationError") as AcceptDialog
	check(notice.visible and notice.dialog_text.contains("preservado") and notice.get_ok_button().has_focus(), "save/load refusal is visible and controller accessible")
	notice.queue_free()
	app.menu.open("options"); app.menu.options_tab = "audio"; app.menu.show_screen("options")
	check(app.menu.content.find_children("*", "HSlider", true, false).size() == 3, "independent mix controls exposed")
	app.menu.options_tab = "video"; app.menu.show_screen("options")
	check(app.menu.content.find_children("*", "OptionButton", true, false).size() == 7, "video exposes comfort alongside existing UI scale")
	app.queue_free(); await process_frame; await create_timer(0.2).timeout
	print("PRESENTATION_REVIEW failures=", failures)
	quit(failures)
