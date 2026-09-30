extends SceneTree
const Audio := preload("res://scripts/game_audio.gd")
var failures := 0

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var audio := Audio.new()
	root.add_child(audio)
	await create_timer(0.1).timeout
	var sim := Expedition.new()
	for key in Audio.SFX_KEYS:
		check(audio.samples.get(key) is AudioStreamWAV and audio.samples[key].get_length() > 0.02, key + " carrega áudio real")
	for key in audio.music:
		# Current authored scores: sixteen 4-beat bars at120BPM for boss, distinct loops elsewhere.
		var expected_seconds: float = {"boss":32.0,"refuge":64.0,"expedition":51.2}[key]
		check(absf(audio.music[key].stream.get_length()-expected_seconds) < 0.02 and audio.music[key].stream.loop, key + " conserva duração autorada e loop")
	audio.discard_history(sim.audio_sequence)
	var rng_before := sim.rng.state
	sim.emit_audio("pistol", Vector2.ZERO)
	audio.update(sim, true, false, false, Vector2.ZERO, 0.016)
	check(audio.sounds_started == 1, "evento de disparo toca uma vez")
	audio.update(sim, true, false, false, Vector2.ZERO, 0.016)
	check(audio.sounds_started == 1, "snapshot repetido não repete o som")
	check(sim.rng.state == rng_before, "variação de áudio não altera RNG do combate")
	sim.emit_audio("shotgun", Vector2(2000, 0))
	audio.update(sim, true, false, false, Vector2.ZERO, 0.016)
	check(audio.sounds_started == 1, "inimigos distantes não poluem a mixagem")
	sim.emit_audio("melee", Vector2.ZERO)
	audio.update(sim, true, true, true, Vector2.ZERO, 0.016)
	check(not audio.voices.any(func(voice): return voice.playing), "pausa interrompe efeitos ativos")
	audio.update(sim, true, false, false, Vector2.ZERO, 0.016)
	check(audio.sounds_started == 1, "retomar não reproduz fila da pausa")
	audio.set_volume(0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Severence Mix")), "volume zero silencia efeitos e música")
	check(not audio.play_effect("sword", Vector2.ZERO, Vector2.ZERO), "efeitos não começam no mudo")
	audio.set_volume(70)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Severence Mix")), "volume restaura a mixagem")
	sim.mode = "hub"
	audio.update(sim, true, false, false, Vector2.ZERO, 2.0)
	check(audio.music.refuge.playing and not audio.music.expedition.playing, "refúgio usa sua música")
	sim.mode = "run"
	audio.update(sim, true, false, false, Vector2.ZERO, 2.0)
	check(audio.music.expedition.playing and not audio.music.refuge.playing, "expedição troca de música")
	audio.update(sim, true, true, true, Vector2.ZERO, 2.0)
	check(is_equal_approx(audio.duck, 0.35), "menu reduz suavemente a música")
	sim.emit_audio("bazooka", Vector2.ZERO)
	audio.discard_history(sim.audio_sequence)
	audio.update(sim, true, false, false, Vector2.ZERO, 0.016)
	check(audio.sounds_started == 1, "carregar sessão descarta efeitos históricos")
	check(audio.play_effect("pistol", Vector2(1200, 0), Vector2.ZERO), "tiro distante pode tocar baixo")
	check(audio.play_effect("pistol", Vector2.ZERO, Vector2.ZERO), "tiro distante não suprime o tiro local simultâneo")
	check(not audio.play_effect("pistol", Vector2(1000, 0), Vector2.ZERO), "tiro distante duplicado não sobrepõe o local")
	await create_timer(0.1).timeout
	audio.queue_free()
	await process_frame
	# The mixer releases stream playbacks on its own thread after nodes exit.
	await create_timer(0.1).timeout
	print("GAME_AUDIO failures=", failures)
	quit(failures)
