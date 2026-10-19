extends SceneTree
const Main = preload("res://scripts/main.gd")
const Sim = preload("res://scripts/simulation.gd")
const View = preload("res://scripts/world_view.gd")
class TestApp extends Main:
	var pads: Array = []
	func _ready() -> void: pass
	func _physics_process(_dt: float) -> void: pass
	func _notification(_what: int) -> void: pass
	func connected_gamepads() -> Array: return pads
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
	else: print("PASS: ", label)
func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new(); e.physical_keycode = code; e.keycode = code; e.pressed = down; Input.parse_input_event(e); Input.flush_buffered_events()
func axis(which: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new(); e.device = 0; e.axis = which; e.axis_value = value; Input.parse_input_event(e); Input.flush_buffered_events()
func click(down: bool) -> void:
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = down; Input.parse_input_event(e); Input.flush_buffered_events()
func _init() -> void: call_deferred("run")
func run() -> void:
	# Save-free fixture: never runs scene startup, settings, progress or expedition save.
	var app := TestApp.new(); app.auto_aim = false; app.sim = Sim.new(); root.add_child(app)
	var a: Dictionary = app.sim.actors[0]; a.aim = Vector2.DOWN
	key(KEY_D, true)
	var cmd: Dictionary = app.player_input(0)
	check(cmd.aim.is_equal_approx(Vector2.RIGHT), "Keyboard movement beats stationary cursor")
	app.sim.step_actor(a, cmd, 0.016)
	check(a.facing.is_equal_approx(Vector2.RIGHT) and a.aim == a.facing, "Simulation aligns body and weapon with resolved input")
	key(KEY_D, false)
	check(app.player_input(0).aim.is_equal_approx(Vector2.RIGHT), "Idle retains last direction")
	key(KEY_W, true)
	check(app.player_input(0).aim.is_equal_approx(Vector2.UP), "Keyboard changes direction without mouse")
	var motion := InputEventMouseMotion.new(); motion.relative = Vector2(8, 0); app._input(motion)
	var expected: Vector2 = (app.get_global_mouse_position() - a.p + Vector2(0,28)).normalized()
	check(app.player_input(0).aim.is_equal_approx(expected), "Recent mouse motion deliberately aims")
	app.last_mouse_aim_usec = Time.get_ticks_usec() - Main.MOUSE_AIM_GRACE_USEC - 1
	check(app.player_input(0).aim.is_equal_approx(Vector2.UP), "Expired mouse activity yields to movement")
	click(true)
	check(app.player_input(0).aim.is_equal_approx(expected), "Mouse fire retains explicit cursor aim even without motion")
	app.ui_input_block = 1
	check(app.player_input(0).aim.is_equal_approx(Vector2.UP), "Suppressed UI click cannot turn player to cursor")
	app.ui_input_block = 0; click(false); key(KEY_W, false)
	app.pads = [0]; app.sim.coop = "solo"
	axis(JOY_AXIS_LEFT_X, -0.8); axis(JOY_AXIS_RIGHT_Y, -0.8)
	check(app.player_input(0).aim.is_equal_approx(Vector2.UP), "Right stick overrides opposing left stick")
	axis(JOY_AXIS_RIGHT_Y, 0)
	check(app.player_input(0).aim.is_equal_approx(Vector2.LEFT), "Releasing right stick immediately restores movement facing")
	axis(JOY_AXIS_RIGHT_Y, 0.2)
	check(app.player_input(0).aim.is_equal_approx(Vector2.LEFT), "Right stick noise within deadzone cannot lock aim")
	axis(JOY_AXIS_RIGHT_Y, 0); axis(JOY_AXIS_LEFT_X, 0)
	a.aim = Vector2.UP
	check(app.player_input(0).aim.is_equal_approx(Vector2.UP), "Both sticks released retain last direction")
	axis(JOY_AXIS_LEFT_X, 0.8); axis(JOY_AXIS_RIGHT_X, -0.9); app._input(motion)
	check(app.player_input(0).aim.is_equal_approx(Vector2.LEFT), "Right stick wins over recent mouse motion")
	axis(JOY_AXIS_LEFT_X, 0); axis(JOY_AXIS_RIGHT_X, 0); app.pads = []
	key(KEY_RIGHT, true); key(KEY_I, true)
	check(app.player_input(1, false).aim.is_equal_approx(Vector2.UP), "P2 aim keys override arrow movement")
	key(KEY_I, false)
	check(app.player_input(1, false).aim.is_equal_approx(Vector2.RIGHT), "P2 aim release restores movement despite P1 mouse activity")
	key(KEY_RIGHT, false)
	app.pads = [0]; app.sim.coop = "local"; axis(JOY_AXIS_LEFT_X, -0.8)
	app.last_mouse_aim_usec = -Main.MOUSE_AIM_GRACE_USEC; key(KEY_D, true)
	check(app.player_input(0).aim.is_equal_approx(Vector2.RIGHT), "Single local coop pad does not override P1 keyboard")
	check(app.player_input(1, false).aim.is_equal_approx(Vector2.LEFT), "Single local coop pad drives P2 facing")
	key(KEY_D, false); axis(JOY_AXIS_LEFT_X, 0)
	var view := View.new(); view.sim = app.sim
	a.aim = Vector2.UP; a.move = Vector2.LEFT
	check(view.fusion_visual_direction(a).is_equal_approx(Vector2.UP), "Fusion fallback respects deliberate aim while walking")
	check(view.titan_visual_direction({"occupant":0,"moving":true,"move_dir":Vector2.LEFT}).is_equal_approx(Vector2.UP), "Piloted Titan respects deliberate aim while walking")
	check(view.titan_visual_direction({"occupant":-1,"moving":true,"move_dir":Vector2.LEFT}).is_equal_approx(Vector2.LEFT), "Autonomous Titan keeps movement behavior")
	app.sim.coop = "ai"
	var companion: Dictionary = app.sim.actors[1]
	companion.aim = Vector2.RIGHT; companion.move = Vector2.LEFT
	check(view.fusion_visual_direction(companion) == Vector2.LEFT, "AI companion faces walking direction despite opposing combat aim")
	check(view.titan_visual_direction({"occupant":1}) == Vector2.LEFT, "AI pilot faces walking direction")
	check(companion.aim == Vector2.RIGHT, "Visual direction preserves combat targeting")
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		check(view.spectre_visual_direction({"moving":true, "move_dir":direction, "aim":-direction, "shot":0.4}) == direction, "Moving ally faces travel even while shooting")
	check(view.spectre_visual_direction({"moving":false, "aim":Vector2.RIGHT, "shot":0.4}) == Vector2.RIGHT, "Stationary ally faces target")
	app.sim.coop = "local"
	check(view.fusion_visual_direction(companion) == Vector2.RIGHT, "Human P2 keeps deliberate aim")
	view.free(); app.free()
	print("INPUT_FACING checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
