extends Node
## Presentation-only audio: does not consume the gameplay RNG or drive combat.
const ROOT := "res://assets/audio/generated/"
const SFX_KEYS := ["pistol", "shotgun", "smg", "bazooka", "mech", "sword", "melee", "spectre",
	"enemy_cult", "enemy_fish", "enemy_crawler", "enemy_brute", "enemy_guard", "enemy_bomber",
	"enemy_warden", "enemy_boss", "enemy_die", "explosion", "hit", "jump", "dash", "pickup", "dry_fire",
	"whisper"]
const VOICES := 20
const MAX_DISTANCE := 1300.0
var samples: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var music: Dictionary = {}
var music_gain := {"refuge": 0.0, "expedition": 0.0, "boss": 0.0}
var master := 0.7
var duck := 1.0
var last_sequence := 0
var recent: Dictionary = {}
var sounds_started := 0
var playback_rng := RandomNumberGenerator.new()
var was_active := false

func _ready() -> void:
	playback_rng.seed = 19410930
	ensure_bus("Severence Mix", "Master", true)
	ensure_bus("Severence SFX", "Severence Mix", false)
	ensure_bus("Severence Music", "Severence Mix", false)
	for key in SFX_KEYS:
		samples[key] = load(ROOT + key + ".wav")
	for index in range(VOICES):
		var player := AudioStreamPlayer.new()
		player.bus = "Severence SFX"
		add_child(player)
		voices.append(player)
	for key in ["refuge", "expedition", "boss"]:
		var player := AudioStreamPlayer.new()
		var path: String = ROOT + "music_" + key
		player.stream = load(path + (".ogg" if ResourceLoader.exists(path + ".ogg") else ".wav"))
		if player.stream is AudioStreamOggVorbis:
			player.stream.loop = true
		elif player.stream is AudioStreamWAV:
			player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			player.stream.loop_begin = 0
			player.stream.loop_end = player.stream.data.size() / (4 if player.stream.stereo else 2)
		player.bus = "Severence Music"
		player.volume_db = -80.0
		add_child(player)
		music[key] = player
	set_volume(master * 100.0)

func ensure_bus(bus_name: String, send: String, limit: bool) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0: return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, send)
	if limit:
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.threshold_db = -2.0
		AudioServer.add_bus_effect(index, limiter)

func _exit_tree() -> void:
	for player in voices:
		player.stop()
		player.stream = null
	for player in music.values():
		player.stop()
		player.stream = null
	samples.clear()

func set_volume(percent: float) -> void:
	master = clampf(percent / 100.0, 0.0, 1.0)
	var index := AudioServer.get_bus_index("Severence Mix")
	if index >= 0:
		AudioServer.set_bus_mute(index, master <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(master) if master > 0 else -80.0)

func set_channel_volumes(music_percent: float, effects_percent: float) -> void:
	for channel in [["Severence Music", music_percent], ["Severence SFX", effects_percent]]:
		var index := AudioServer.get_bus_index(channel[0])
		var gain := clampf(float(channel[1]) / 100.0, 0.0, 1.0)
		if index >= 0:
			AudioServer.set_bus_mute(index, gain <= 0.0)
			AudioServer.set_bus_volume_db(index, linear_to_db(gain) if gain > 0 else -80.0)

func discard_history(sequence: int) -> void:
	last_sequence = sequence
	recent.clear()
	for voice in voices: voice.stop()

func update(sim, playing: bool, paused: bool, menu_visible: bool, listener: Vector2, dt: float) -> void:
	var active := playing and not paused
	if was_active and not active:
		for voice in voices: voice.stop()
	was_active = active
	# A loaded save or a new host can have a lower sequence. Never replay its log.
	if sim.audio_sequence < last_sequence: discard_history(sim.audio_sequence)
	for event in sim.audio_events:
		if event.id <= last_sequence: continue
		last_sequence = event.id
		if active and sim.tick_time - float(event.time) < 0.6:
			play_effect(event.key, event.p, listener)
	var track := "expedition" if playing and sim.mode in ["run", "arena"] else "refuge"
	if track == "expedition" and boss_fight_active(sim): track = "boss"
	duck = move_toward(duck, 0.35 if paused or (playing and menu_visible) else 1.0, dt * 2.0)
	for key in music:
		var player: AudioStreamPlayer = music[key]
		music_gain[key] = move_toward(float(music_gain[key]), 1.0 if key == track else 0.0, dt / 1.5)
		var gain: float = music_gain[key] * duck
		player.volume_db = -13.0 + linear_to_db(gain) if gain > 0.001 else -80.0
		if key == track and not player.playing: player.play()
		elif key != track and gain <= 0.001 and player.playing: player.stop()

func boss_fight_active(sim) -> bool:
	if sim.mode != "run" or sim.boss_dead: return false
	if not sim.enemies.any(func(e): return e.kind == "boss" and e.hp > 0): return false
	for actor in sim.actors:
		if actor.active and not actor.dead and sim.room_at(actor.p).get("id", "") == "boss": return true
	return false

func play_effect(key: String, position: Vector2, listener: Vector2) -> bool:
	if master <= 0.0 or not samples.has(key) or samples[key] == null: return false
	var distance := position.distance_to(listener)
	if distance >= MAX_DISTANCE: return false
	var now := Time.get_ticks_msec()
	# Coalesce simultaneous pellets/swarm events without losing automatic fire.
	# A faraway shot must never suppress the listener's louder shot or warning.
	var gain := effect_gain(key, distance)
	var previous: Dictionary = recent.get(key, {})
	if now - int(previous.get("time", -10000)) < 40 and gain <= float(previous.get("gain", -80.0)): return false
	var chosen: AudioStreamPlayer
	for voice in voices:
		if not voice.playing:
			chosen = voice
			break
	if chosen == null:
		# Preserve near/player feedback; discard quieter events when the pool is full.
		for voice in voices:
			if chosen == null or voice.volume_db < chosen.volume_db: chosen = voice
		if chosen.volume_db >= gain: return false
		chosen.stop()
	recent[key] = {"time": now, "gain": gain}
	chosen.stream = samples[key]
	chosen.pitch_scale = playback_rng.randf_range(0.96, 1.04)
	chosen.volume_db = gain
	chosen.play()
	sounds_started += 1
	return true

func effect_gain(key: String, distance: float) -> float:
	var gain := -7.0
	if key.begins_with("enemy_"): gain -= 4.0
	if key in ["explosion", "mech"]: gain -= 3.0
	return gain + linear_to_db(maxf(0.025, 1.0 - distance / MAX_DISTANCE))
