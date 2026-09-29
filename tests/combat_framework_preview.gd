extends SceneTree
# Galeria reproduzível de avisos, movimento e leitura das ameaças 0.18.
class Preview extends DockView:
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,800), Color("15202b"))
		for y in range(0,800,64):
			for x in range(0,1280,64): draw_rect(Rect2(x,y,62,62),Color("26343b"),false,1)
		text_at(Vector2(40,45),"COMBATE 0.18 • AVISAR / ATACAR / REPOSICIONAR",GOLD,24)
		draw_combat_warnings()
		for enemy in sim.enemies:
			visual_origin = enemy.p; visual_scale = 1.12; visual_transform(Vector2.ZERO)
			draw_enemy(enemy)
			visual_scale = 1; visual_origin = Vector2.ZERO; visual_transform(Vector2.ZERO)
			text_at(enemy.p + Vector2(-60,45), enemy.kind + " / " + enemy.combat, GOLD,13)
		visual_origin = sim.actors[0].p; visual_scale = 1.12; visual_transform(Vector2.ZERO)
		draw_actor(sim.actors[0])
		visual_scale = 1; visual_origin = Vector2.ZERO; visual_transform(Vector2.ZERO)
		text_at(Vector2(60,745),"CORPOS +12% • PROJÉTEIS +15% • HITBOXES PRESERVADAS",CYAN,20)
func _init() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280,800)
	var view := Preview.new(); view.sim = Expedition.new(); view.sim.start_arena()
	view.sim.enemies.clear(); view.sim.pending_spawns.clear()
	view.sim.actors[0].p = Vector2(660,650); view.sim.actors[0].facing = Vector2.RIGHT
	for n in range(6):
		view.sim.spawn_enemy(Vector2(170+n%3*420,245+n/3*280), ["cult","fish","brute","crawler","bomber","guard"][n])
		var enemy: Dictionary = view.sim.enemies[-1]
		enemy.combat = "warning"; enemy["locked"] = enemy.p + Vector2(100,75); enemy.combat_t = 0.4
		if n == 2: enemy.combat = "recover"; enemy["crouched"] = true; enemy.elite = "shield"
		if n == 3: enemy.combat = "attack"; enemy["jump_height"] = 35; enemy.elite = "trail"
	view.sim.add_combat_zone(Vector2(275,570),58,12,"acid",0,2)
	view.sim.add_combat_zone(Vector2(1050,665),62,12,"trail",0.5,2)
	view.sim.harpoons.append({"p": Vector2(980,350), "life": 3.0})
	root.add_child(view)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/combat018-gallery.png")
	quit()
