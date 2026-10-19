extends SceneTree
const Main=preload("res://scripts/main.gd")
const Terminal=preload("res://scripts/terminal_ui.gd")
class TestApp extends Main:
	var settings_saved:=0
	func _ready() -> void: pass
	func _process(_dt: float) -> void: pass
	func _physics_process(_dt: float) -> void: pass
	func _notification(_what: int) -> void: pass
	func save_settings() -> void: settings_saved+=1
var failures:=0
func check(ok: bool,message: String) -> void:
	if not ok: failures+=1; push_error(message)
	else: print("PASS: ",message)
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/pause-settings")
	root.get_texture().get_image().save_png("res://test-output/pause-settings/"+name+".png")
func run() -> void:
	root.size=Vector2i(1344,752)
	var app:=TestApp.new(); app.sim=Main.Sim.new(); root.add_child(app)
	app.playing=true; app.paused=true
	var menu:=Terminal.new(); menu.app=app; app.menu=menu; root.add_child(menu)
	menu.show_screen("pause"); await process_frame
	var panel: Control=menu.content.find_child("PausePanel",true,false)
	var interior:=Rect2(85,90,730,442)
	for child in panel.get_children():
		if child is Button or child is Label: check(interior.encloses(child.get_rect()),"Pause content fits decorative frame: "+child.name)
	await capture("pause")
	var settings: Button=menu.content.find_child("PauseSettings",true,false)
	settings.pressed.emit(); await process_frame
	check(menu.screen=="options" and menu.options_return_screen=="pause" and app.paused,"Pause opens settings without resuming")
	check(menu.content.find_children("*","OptionButton",true,false).size()>=5,"Video settings expose resolution and display choices")
	await capture("video")
	menu.options_tab="audio"; menu.show_screen("options"); await process_frame
	var sliders:=menu.content.find_children("*","HSlider",true,false)
	check(sliders.size()==3,"Audio provides master, music and effects")
	sliders[0].value=45; check(app.volume_percent==45,"Master volume callback applies value")
	await capture("audio")
	menu.content.find_child("OptionsBack",true,false).pressed.emit()
	check(menu.screen=="pause" and app.paused and app.settings_saved>0,"Back saves settings and preserves pause")
	menu.open_options("pause")
	var cancel:=InputEventJoypadButton.new(); cancel.button_index=JOY_BUTTON_B; cancel.pressed=true
	menu._unhandled_input(cancel)
	check(menu.screen=="pause","Controller back returns to pause")
	app.sim.keys=2; app.sim.money=17; app.sim.materials=5; app.sim.actors[0].run_weapons={"bazooka":12}
	menu.read_equipment(); menu.show_screen("mission_inventory"); await process_frame
	await capture("inventory")
	check(load("res://assets/ui/equipamento/items_hd_v1/key.tres").get_width()==512,"Inventory uses high resolution icon")
	menu.free(); app.free(); print("PAUSE_SETTINGS failures=",failures); quit(1 if failures else 0)
