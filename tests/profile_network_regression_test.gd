extends SceneTree
const App = preload("res://scripts/main.gd")
var failures := 0
var checks := 0
class CoreApp extends "res://scripts/main.gd":
	func _ready() -> void: pass

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
	else: print("PASS CORE: ", label)

func _initialize() -> void:
	preload("res://tests/support/isolated_user_data.gd").activate()
	run.call_deferred()

func run() -> void:
	# No application _ready, renderer or procedural generation is needed here.
	var app := CoreApp.new()
	app.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(app)
	app.sim = Expedition.new()
	app.menu = Control.new()
	app.playing = true
	app.sim.materials = 17
	check(app.save_game(), "paired profile and checkpoint commit")
	var revision: int = app.profile_revision
	app.sim.materials = 6
	check(app.save_progress(), "newer permanent spending persists")
	check(app.profile_revision > revision, "permanent change advances revision")
	check(not app.load_game() and not app.load_error.is_empty(), "stale checkpoint explicitly refused")
	check(app.sim.materials == 6, "stale resume cannot undo spending")
	check(app.save_game(), "fresh paired checkpoint replaces stale checkpoint")
	app.sim.money = 999
	check(app.load_game() and app.sim.money != 999 and app.sim.materials == 6, "matching checkpoint resumes exact world and profile")
	app.sim.materials += 1
	check(app.prepare_quit() and app.load_game() and app.sim.materials == 7, "menu and window exit pair current progress with resumable checkpoint")
	app.sim.materials = 6
	# Apply the same entitlement migration as a normal application startup before
	# recording the local profile whose identity the network test protects.
	check(app.save_progress(), "migrated local entitlements persisted before joining")
	var before_profile := FileAccess.get_file_as_bytes("user://progress.json")
	var local_rng: int = app.sim.rng.state
	app.sim.new_unlocks = ["local_marker"]
	app.preserve_local_session()
	app.online = true; app.hosting = false
	var host := Expedition.new()
	host.materials = 900; host.story_flags["host_only"] = true
	app.receive_state(var_to_bytes(host.snapshot()).compress(FileAccess.COMPRESSION_DEFLATE))
	check(app.sim.materials == 900, "connected guest displays host replica")
	check(not app.save_progress(), "guest replica cannot write profile")
	app.disconnect_network()
	check(app.sim.materials == 6 and not app.sim.story_flags.has("host_only"), "disconnect restores local profile before offline writes")
	check(app.sim.new_unlocks == ["local_marker"] and app.sim.rng.state == local_rng, "disconnect restores transient entitlements and random state")
	check(app.save_progress() and FileAccess.get_file_as_bytes("user://progress.json") == before_profile, "disconnect then save preserves original profile bytes")
	app.receive_state(var_to_bytes(host.snapshot()).compress(FileAccess.COMPRESSION_DEFLATE))
	check(app.sim.materials == 6, "late snapshot ignored after disconnect")
	app.accept_remote_input({"jump": true, "interact": true, "move": Vector2.RIGHT, "fire": true})
	app.accept_remote_input({"jump": false, "interact": false, "move": Vector2.LEFT, "fire": false})
	var command: Dictionary = app.consume_remote_input()
	check(command.jump and command.interact, "press survives release packet before host tick")
	check(command.move == Vector2.LEFT and not command.fire, "continuous controls use latest packet")
	command = app.consume_remote_input()
	check(not command.jump and not command.interact, "edge actions consumed only once")
	app.accept_remote_input({"weapon": true}); app.remote_age = 0.5
	check(app.consume_remote_input().is_empty(), "expired input cannot fire late")
	app.accept_remote_input({"jump": true}); app.disconnect_network()
	check(app.remote_cmd.is_empty(), "disconnect clears all queued controls")
	# Legacy files have no proof that their rewards match the current profile.
	var legacy := FileAccess.open(App.RUN_SAVE, FileAccess.WRITE)
	legacy.store_var({"version": 2, "state": app.sim.snapshot()}); legacy.close()
	check(not app.load_game() and app.sim.materials == 6, "unverifiable legacy checkpoint preserves profile and explains refusal")
	app.menu.free(); app.free()
	print("PROFILE_NETWORK checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
