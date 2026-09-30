extends SceneTree

const GameAudio = preload("res://scripts/game_audio.gd")

func _init() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var sim := Expedition.new()
	sim.coop = "solo"
	sim.start_run(1941)
	var audio := GameAudio.new()
	root.add_child(audio)
	var failures := 0
	var boss_room: Dictionary = sim.room_by_id("boss")
	sim.actors[0].p = boss_room.r.get_center()
	if not audio.boss_fight_active(sim):
		push_error("A entrada na arena precisa ativar a música do boss")
		failures += 1
	audio.update(sim, true, false, false, sim.actors[0].p, 0.1)
	if not audio.music["boss"].playing or not audio.music["boss"].stream.loop:
		push_error("A faixa do boss precisa tocar durante a luta")
		failures += 1
	# Let the audio thread consume the start before switching tracks.
	await create_timer(0.1).timeout
	sim.boss_dead = true
	audio.update(sim, true, false, false, sim.actors[0].p, 2.0)
	if audio.boss_fight_active(sim) or not audio.music["expedition"].playing:
		push_error("A música da expedição precisa voltar após a derrota")
		failures += 1
	print("BOSS_MUSIC_TEST failures=", failures)
	await create_timer(0.1).timeout
	sim = null
	await preload("res://tests/support/scene_cleanup.gd").finish(self)
	quit(1 if failures else 0)
