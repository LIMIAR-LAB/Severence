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
		var action_path := "res://assets/enemies/%s_actions_v2.png" % kind
		check(ResourceLoader.exists(action_path), "%s: transições, ataque e morte gerados" % kind)
		if ResourceLoader.exists(action_path):
			var actions := load(action_path) as Texture2D
			check(actions.get_size() == Vector2(1024, 1280), "%s: quatro poses em oito direções" % kind)
			var action_image := actions.get_image()
			for direction in range(8):
				var poses := []
				for pose in range(4): poses.append(action_image.get_region(Rect2i(pose * 256, direction * 160, 256, 160)))
				check(poses.all(func(pose): return pose.get_used_rect().has_area()), "%s: quatro poses visíveis na direção %d" % [kind, direction])
				check(hash(poses[0].get_data()) != hash(poses[1].get_data()) and hash(poses[1].get_data()) != hash(poses[2].get_data()), "%s: movimento de ataque distinto na direção %d" % [kind, direction])
				if Expedition.ENEMY_MUZZLE_OFFSETS.has(kind):
					var muzzle: Vector2 = Expedition.ENEMY_MUZZLE_OFFSETS[kind][direction]
					var pixel := Vector2i(128 + roundi(muzzle.x), 145 + roundi(muzzle.y))
					var tip_visible := false
					for y in range(maxi(0, pixel.y - 8), mini(160, pixel.y + 9)):
						for x in range(maxi(0, pixel.x - 8), mini(256, pixel.x + 9)):
							if poses[1].get_pixel(x, y).a > 0.5: tip_visible = true; break
						if tip_visible: break
					check(tip_visible, "%s: origem do tiro coincide com a arma na direção %d" % [kind, direction])
	var sim := Expedition.new()
	sim.start_run(1941)
	sim.spawn_enemy(sim.actors[0].p + Vector2(100, 0), "guard")
	sim.spawn_enemy(sim.actors[0].p + Vector2(-100, 0), "bomber")
	check(sim.enemies.any(func(e): return e.kind == "guard"), "guard pode surgir na partida")
	check(sim.enemies.any(func(e): return e.kind == "bomber"), "bomber pode surgir na partida")
	print("failures=", failures)
	quit(failures)
