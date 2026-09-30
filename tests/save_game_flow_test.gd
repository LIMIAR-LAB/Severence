extends SceneTree

var failures := 0

class FailingSaveApp extends "res://scripts/main.gd":
	func save_game() -> bool: return false

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var path := "user://expedition.save"
	var had_save := FileAccess.file_exists(path)
	var original := FileAccess.get_file_as_bytes(path) if had_save else PackedByteArray()
	var app = load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	app.start_local(); app.sim.start_run(1941)
	app.sim.actors[0].p = Vector2(978, 1241)
	app.sim.actors[1].p = Vector2(1020, 1280)
	app.sim.actors[0].outfit = "espiao"
	app.sim.keys = 3; app.sim.money = 47; app.sim.boss_dead = true
	app.menu.open("pause")
	check(app.paused and app.menu.screen == "pause", "partida abre menu de pausa separado")
	check(app.menu.content.find_child("PauseFrame", true, false) is TextureRect, "moldura PixelLab aparece na pausa")
	check(app.menu.content.find_child("SaveGame", true, false) is Button, "pausa oferece salvar jogo")
	check(app.menu.content.find_child("ReturnToMenu", true, false) is Button, "pausa oferece voltar ao menu")
	check(app.menu.content.find_child("Slot_padrao", true, false) == null, "pausa não oferece troca de uniforme")
	app.menu.content.find_child("SaveGame", true, false).pressed.emit()
	check(app.has_saved_game(), "arquivo da expedição criado")
	app.sim.keys = 4
	check(app.save_game(), "salvamento existente pode ser atualizado")
	app.sim.keys = 5
	app.menu.content.find_child("ReturnToMenu", true, false).pressed.emit()
	check(not app.playing and not app.paused and app.menu.screen == "main", "voltar abre o título")
	check(app.has_saved_game(), "voltar grava a sessão offline antes de sair")
	app.queue_free(); await process_frame; await process_frame
	var loaded = load("res://scenes/main.tscn").instantiate(); root.add_child(loaded)
	await process_frame
	var load_button: Button = loaded.menu.content.find_child("Title_0", true, false)
	check(not load_button.disabled, "Continuar habilitado após salvar")
	load_button.pressed.emit()
	check(loaded.playing and not loaded.menu.visible and loaded.sim.mode == "run", "retoma dentro das docas")
	check(loaded.sim.coop == "local" and loaded.sim.actors[1].active, "coop local preservado")
	check(loaded.sim.actors[0].p == Vector2(978, 1241) and loaded.sim.actors[1].p == Vector2(1020, 1280), "posições preservadas")
	check(loaded.sim.actors[0].outfit == "espiao" and loaded.sim.keys == 5 and loaded.sim.money == 47 and loaded.sim.boss_dead, "equipamento e progresso preservados no salvamento de saída")
	check(loaded.sim.nav.get_point_count() > 0, "navegação reconstruída após carregar")
	loaded.menu.open("equipment")
	check(loaded.menu.screen == "pause", "equipamento não abre durante a partida")
	loaded.queue_free(); await process_frame; await process_frame
	var failed := FailingSaveApp.new(); root.add_child(failed); await process_frame
	failed.start_single(); failed.menu.open("pause")
	failed.menu.content.find_child("ReturnToMenu", true, false).pressed.emit()
	check(failed.playing and failed.paused and failed.menu.screen == "pause", "falha de gravação mantém a partida em pausa")
	check("Não foi possível salvar" in failed.menu.telemetry.text, "falha de gravação aparece na pausa")
	failed.queue_free(); await process_frame; await process_frame
	var online = load("res://scenes/main.tscn").instantiate(); root.add_child(online); await process_frame
	online.start_single(); online.online = true; online.hosting = true; online.menu.open("pause")
	check(online.menu.content.find_child("SaveGame", true, false).disabled, "salvar fica indisponível na sessão online")
	var before_online := FileAccess.get_file_as_bytes(path)
	online.menu.content.find_child("ReturnToMenu", true, false).pressed.emit()
	check(not online.playing and not online.online and online.menu.screen == "main", "voltar encerra a sessão online")
	check(FileAccess.get_file_as_bytes(path) == before_online, "retorno online não substitui o save offline")
	online.queue_free(); await process_frame; await process_frame
	if had_save:
		var restore := FileAccess.open(path, FileAccess.WRITE)
		restore.store_buffer(original); restore.close()
	else: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SAVE GAME FLOW failures=", failures)
	quit(1 if failures else 0)
