extends SceneTree
const Main=preload("res://scripts/main.gd")
class FixtureApp extends Main:
	func _ready() -> void: pass
	func _process(_dt: float) -> void: pass
	func _physics_process(_dt: float) -> void: pass
	func _notification(_what: int) -> void: pass
	func save_progress(_force_revision: bool = false) -> bool: return true
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1344,752);root.content_scale_size=root.size
	DirAccess.make_dir_recursive_absolute("res://test-output/supernova")
	var app:=FixtureApp.new();app.sim=Expedition.new();app.sim.coop="solo";app.sim.start_arena();app.sim.enemies.clear();app.sim.unlocked.supernova=true
	root.add_child(app);app.playing=true
	app.menu=preload("res://scripts/terminal_ui.gd").new();app.menu.app=app;root.add_child(app.menu);app.menu.hide()
	var s=app.sim;var a: Dictionary=s.actors[0];s.equip(0,"padrao","","supernova");s.toggle_armor(a);a.transform=0;a.p=Vector2(650,500);a.aim=Vector2(1,1).normalized();s.tick_time=2.0
	var view:=DockView.new();view.sim=s;root.add_child(view)
	var camera:=Camera2D.new();camera.position=a.p-Vector2(0,40);camera.zoom=Vector2(2,2);root.add_child(camera)
	var layer:=CanvasLayer.new();root.add_child(layer)
	var hud:=CombatHUD.new();hud.app=app;layer.add_child(hud)
	s.Supernova.pulse(s,a);s.effects[-1].life=0.3;s.fire_actor(a)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/supernova/gameplay.png")
	for i in 8:
		a.aim=Vector2.DOWN.rotated(-i*PI/4);view.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-output/supernova/direction-%d.png"%i)
	s.set_armor(a,false);app.grant_starting_form();app.menu.reparent(layer);app.menu.read_equipment();app.menu.show();app.menu.show_screen("mission_inventory");hud.hide();view.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/supernova/inventory.png")
	print("SUPERNOVA_PREVIEW_DONE");quit()
