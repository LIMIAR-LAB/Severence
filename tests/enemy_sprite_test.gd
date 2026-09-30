extends SceneTree

var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func _init() -> void:
	var view := DockView.new()
	check(view.enemy_art_kind("crawler_small") == "crawler", "filhote reutiliza a arte nova do crawler")
	check(view.enemy_art_kind("brute") == "brute", "brute mantém sua própria arte")
	check(view.enemy_art_scale("crawler_small").is_equal_approx(Vector2(0.6, 0.6)), "filhote mantém escala de 60% vivo e morto")
	check(view.enemy_art_scale("brute", true).is_equal_approx(Vector2(1.0, 0.78)), "brute agachado mantém compressão vertical")
	var directions := [Vector2.DOWN, Vector2(1, 1), Vector2.RIGHT, Vector2(1, -1), Vector2.UP, Vector2(-1, -1), Vector2.LEFT, Vector2(-1, 1)]
	for row in range(8):
		check(view.enemy_octant(directions[row]) == row, "direção %d usa linha própria sem espelhar" % row)
	view.free()
	for kind in DockView.PIXELLAB_ENEMY_VERSION:
		var path := "res://assets/enemies/%s_pixellab_%s.png" % [kind, DockView.PIXELLAB_ENEMY_VERSION[kind]]
		check(ResourceLoader.exists(path), "%s: arte PixelLab disponível" % kind)
		if not ResourceLoader.exists(path): continue
		var texture: Texture2D = load(path)
		var image: Image = texture.get_image() if texture != null else null
		check(image != null and image.get_size() == Vector2i(480, 768), "%s: atlas 5 poses x 8 direções" % kind)
		if image == null: continue
		for row in range(8):
			for frame in range(5):
				var used := false
				for y in range(row * 96, (row + 1) * 96):
					for x in range(frame * 96, (frame + 1) * 96):
						if image.get_pixel(x, y).a > 0.5: used = true; break
					if used: break
				check(used, "%s: direção %d pose %d contém desenho" % [kind, row, frame])
	var sim := Expedition.new()
	sim.start_run(1941)
	sim.spawn_enemy(sim.actors[0].p + Vector2(100, 0), "guard")
	sim.spawn_enemy(sim.actors[0].p + Vector2(-100, 0), "bomber")
	check(sim.enemies.any(func(e): return e.kind == "guard"), "guard pode surgir na partida")
	check(sim.enemies.any(func(e): return e.kind == "bomber"), "bomber pode surgir na partida")
	print("failures=", failures)
	quit(failures)
