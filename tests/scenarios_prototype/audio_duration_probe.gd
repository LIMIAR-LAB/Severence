extends SceneTree
const Audio = preload("res://scripts/game_audio.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var audio := Audio.new()
	root.add_child(audio)
	await process_frame
	for key in audio.music:
		var stream = audio.music[key].stream
		print(JSON.stringify({"track":key,"seconds":stream.get_length(),"loop":stream.loop}))
	audio.queue_free()
	await process_frame
	quit()
