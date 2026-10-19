extends SceneTree
const Flight = preload("res://scripts/omega_flight.gd")
const DIRECTIONS := [Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1),Vector2.UP,Vector2(-1,-1),Vector2.LEFT,Vector2(-1,1)]
class Sheet extends Node2D:
	var flight := Flight.new()
	var texture: Texture2D
	func _ready() -> void:
		flight.load_assets(); texture = load("res://assets/characters/marty/omega/rounded_v4/flight.png")
	func _draw() -> void:
		draw_rect(Rect2(0,0,1120,680),Color("18232e"))
		for row in range(8):
			var foot := Vector2(140+row%4*280,270+row/4*330)
			draw_set_transform(foot,0,Vector2(2,2))
			flight.draw_exhaust(self,Vector2.ZERO,row,0,0.5,1.0,1.0)
			draw_texture_rect_region(texture,Rect2(-62,-122,124,124),Rect2(0,row*112,112,112))
			flight.draw_exhaust(self,Vector2.ZERO,row,0,0.5,1.0,1.0,true)
			draw_set_transform(Vector2.ZERO)
			draw_string(ThemeDB.fallback_font,foot+Vector2(-45,50),["S","SE","E","NE","N","NW","W","SW"][row],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
func _init() -> void: call_deferred("capture")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://output/omega-flight")
	root.size=Vector2i(1120,680);root.content_scale_size=root.size
	var sheet:=Sheet.new();sheet.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(sheet)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/omega-flight/eight-directions.png")
	sheet.queue_free();await process_frame
	var s:=Expedition.new();s.start_arena();s.coop="solo";s.enemies.clear();s.actors[1].active=false
	var a:Dictionary=s.actors[0];a.p=Vector2(650,500);a.armor=true;a.armor_type="omega";a.transform=0;a.armor_time=300
	var view:=DockView.new();view.sim=s;root.add_child(view)
	var camera:=Camera2D.new();camera.position=a.p-Vector2(0,70);camera.zoom=Vector2(2.4,2.4);root.add_child(camera)
	for row in range(8):
		a.aim=DIRECTIONS[row].normalized();a.facing=a.aim;a.move=Vector2.RIGHT;a.jump=0
		view.omega_flight.states.clear();view.omega_flight.sample(a,0);view.omega_flight.sample(a,0.1);s.tick_time=0.2
		view.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/omega-flight/runtime-%d.png"%row)
	a.aim=Vector2.DOWN;a.facing=a.aim;a.move=Vector2.ZERO
	view.omega_flight.states.clear()
	for i in range(20):
		a.jump=maxf(0.0,0.65-i*0.05);s.tick_time=1.0+i*0.05
		view.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/omega-flight/jump-%02d.png"%i)
	view.queue_free();camera.queue_free();await process_frame
	print("OMEGA_FLIGHT_PREVIEW_DONE");quit()
