extends Control

const DisplaySettings = preload("res://scripts/display_settings.gd")
@export_file("*.ogv") var video_path := "res://assets/video/opening.ogv"
@export_file("*.tscn") var menu_path := "res://scenes/main.tscn"
var player: VideoStreamPlayer
var leaving := false
var pause_button: Button

func _ready() -> void:
	var settings = JSON.parse_string(FileAccess.get_file_as_string("user://settings.json")) if FileAccess.file_exists("user://settings.json") else {}
	if not settings is Dictionary: settings = {}
	var display := DisplaySettings.new()
	if settings.get("display") is Dictionary: display.from_dict(settings.display)
	display.apply(get_tree())
	# Preserve direct capture/automation entry points used by project tooling.
	for arg in OS.get_cmdline_user_args():
		if arg == "--skip-intro" or arg.begins_with("--capture") or arg.begins_with("--network-"):
			finish()
			return
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	player = VideoStreamPlayer.new()
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	player.volume = clampf(float(settings.get("volume", 70)), 0, 100) / 100.0
	add_child(player)
	resized.connect(_fit_video)
	_fit_video()
	var skip := Button.new()
	skip.name = "SkipIntro"
	skip.text = "PULAR  ·  ENTER / BOTÃO A"
	skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -380
	skip.offset_top = -64
	skip.offset_right = -24
	skip.offset_bottom = -20
	skip.pressed.connect(finish)
	add_child(skip)
	pause_button = Button.new(); pause_button.name = "PauseIntro"
	pause_button.text = "PAUSAR  ·  ESPAÇO / START"
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pause_button.offset_left = 24; pause_button.offset_right = 400; pause_button.offset_top = -64; pause_button.offset_bottom = -20
	pause_button.pressed.connect(toggle_pause); add_child(pause_button)
	if not ResourceLoader.exists(video_path):
		finish()
		return
	player.stream = load(video_path) as VideoStream
	if player.stream == null:
		finish()
		return
	player.finished.connect(finish)
	player.play()
	if not player.is_playing(): finish()

func _fit_video() -> void:
	# Letterbox rather than stretching the cinematic on 16:10 or ultrawide screens.
	var fitted := Vector2(1920, 1080) * minf(size.x / 1920.0, size.y / 1080.0)
	player.size = fitted
	player.position = (size - fitted) * 0.5

func toggle_pause() -> void:
	if leaving or player == null: return
	player.paused = not player.paused
	pause_button.text = "RETOMAR  ·  ESPAÇO / START" if player.paused else "PAUSAR  ·  ESPAÇO / START"

func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		toggle_pause(); get_viewport().set_input_as_handled(); return
	var skip: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A)
	if skip and not leaving:
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if leaving: return
	leaving = true
	set_process_input(false)
	if player != null: player.stop()
	# Consume the skip press before creating the menu, so it cannot activate an item.
	_open_menu.call_deferred()

func _open_menu() -> void:
	get_tree().change_scene_to_file(menu_path)
