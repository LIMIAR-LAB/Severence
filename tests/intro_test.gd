extends SceneTree

class TestIntro extends "res://scripts/intro.gd":
	var transitions := 0
	func _open_menu() -> void: transitions += 1

var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
	else: print("PASS: ", label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/intro.tscn", "opening is the launch scene")
	var intro := TestIntro.new()
	root.add_child(intro)
	await process_frame
	check(intro.player.is_playing(), "Theora opening starts with audio")
	await create_timer(0.3).timeout
	check(intro.player.stream_position > 0, "decoder advances playback")
	intro.size = Vector2(1280, 800); intro._fit_video()
	check(intro.player.size.is_equal_approx(Vector2(1280, 720)) and intro.player.position.is_equal_approx(Vector2(0, 40)), "16:10 window preserves video proportions")
	var key := InputEventKey.new(); key.keycode = KEY_ENTER; key.pressed = true; key.echo = true
	intro._input(key)
	check(not intro.leaving, "held key repeats do not skip")
	key.echo = false; intro._input(key); intro.finish()
	await process_frame
	check(intro.transitions == 1 and not intro.player.is_playing(), "keyboard skip stops audio and enters menu once")
	intro.free()
	for mode in ["controller", "button", "finished", "missing"]:
		intro = TestIntro.new()
		if mode == "missing": intro.video_path = "res://assets/video/missing.ogv"
		root.add_child(intro)
		await process_frame
		if mode == "controller":
			var event := InputEventJoypadButton.new(); event.button_index = JOY_BUTTON_A; event.pressed = true
			intro._input(event)
		elif mode == "button": intro.get_node("SkipIntro").pressed.emit()
		elif mode == "finished": intro.player.finished.emit()
		await process_frame
		check(intro.transitions == 1, mode + " opens menu exactly once")
		intro.free()
	if "--full-intro" in OS.get_cmdline_user_args():
		intro = TestIntro.new(); root.add_child(intro)
		for second in range(65):
			await create_timer(1.0).timeout
			if intro.transitions > 0: break
		check(intro.transitions == 1, "full 60-second playback finishes automatically")
		intro.free()
	change_scene_to_file("res://scenes/intro.tscn")
	await process_frame
	await process_frame
	var press := InputEventKey.new(); press.keycode = KEY_ENTER; press.pressed = true
	Input.parse_input_event(press)
	for frame in range(4): await process_frame
	check(current_scene.scene_file_path == "res://scenes/main.tscn", "skip reaches the actual menu scene")
	check(current_scene.menu.screen == "main" and not current_scene.playing, "skip press does not start a game or activate a menu action")
	current_scene.queue_free()
	await process_frame
	await preload("res://tests/support/scene_cleanup.gd").finish(self)
	quit(failures)
