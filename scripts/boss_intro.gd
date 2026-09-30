extends Control

signal completed

const VIDEO_PATH := "res://assets/video/boss_intro.ogv"
const VIDEO_SIZE := Vector2(1280, 720)
var player: VideoStreamPlayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	player = VideoStreamPlayer.new()
	player.expand = true
	player.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.finished.connect(finish)
	add_child(player)
	resized.connect(fit_video)
	fit_video()
	var skip := Button.new()
	skip.name = "SkipBossIntro"
	skip.text = "PULAR  ·  ESC / ENTER / BOTÃO"
	skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -340
	skip.offset_top = -60
	skip.offset_right = -22
	skip.offset_bottom = -18
	skip.pressed.connect(finish)
	add_child(skip)

func fit_video() -> void:
	if player == null: return
	var fitted := VIDEO_SIZE * minf(size.x / VIDEO_SIZE.x, size.y / VIDEO_SIZE.y)
	player.size = fitted
	player.position = (size - fitted) * 0.5

func play_intro(volume_percent: float) -> bool:
	if not ResourceLoader.exists(VIDEO_PATH): return false
	var stream := load(VIDEO_PATH) as VideoStream
	if stream == null: return false
	player.stream = stream
	player.volume = clampf(volume_percent / 100.0, 0.0, 1.0)
	show()
	player.play()
	if player.is_playing(): return true
	hide()
	return false

func _input(event: InputEvent) -> void:
	if not visible: return
	var skip: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]
	skip = skip or (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_START, JOY_BUTTON_A])
	if skip:
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if not visible: return
	player.stop()
	hide()
	completed.emit()
