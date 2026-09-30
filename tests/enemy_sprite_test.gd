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
	check(view.enemy_art_scale("brute", true).is_equal_approx(Vector2.ONE), "agachar não deforma o corpo")
	var directions := [Vector2.DOWN, Vector2(1, 1), Vector2.RIGHT, Vector2(1, -1), Vector2.UP, Vector2(-1, -1), Vector2.LEFT, Vector2(-1, 1)]
	for row in range(8):
		check(view.enemy_octant(directions[row]) == row, "direção %d usa linha própria sem espelhar" % row)
	# The entire animation must be a rigid transform of the same directional body.
	for kind in ["crawler", "crawler_small", "cult", "fish", "brute", "guard", "bomber"]:
		var expected_scale: float = 0.6 if kind == "crawler_small" else 1.0
		for face in directions:
			for phase in range(21):
				var e := {"kind": kind, "face": face, "moving": true, "step": phase * 0.2, "shot": 0.2 if phase % 2 == 0 else 0.0, "crouched": phase % 3 == 0}
				for death in [-1.0, float(phase) / 20.0]:
					var pose := view.enemy_body_pose(e, death)
					if not (is_equal_approx(pose.x.length(), expected_scale) and is_equal_approx(pose.y.length(), expected_scale) and is_zero_approx(pose.x.dot(pose.y))):
						check(false, "%s: animação alterou proporção" % kind)
		check(true, "%s: movimento, tiro, agachamento e queda preservam escala" % kind)
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
		if Expedition.ENEMY_MUZZLE_OFFSETS.has(kind):
			for row in range(8):
				var muzzle: Vector2 = Expedition.ENEMY_MUZZLE_OFFSETS[kind][row]
				var pixel: Vector2 = (muzzle * 96.0 / DockView.PIXELLAB_ENEMY_SIZE[kind] + Vector2(48, 92)).round()
				var visible := false
				for y in range(maxi(0, int(pixel.y) - 4), mini(96, int(pixel.y) + 5)):
					for x in range(maxi(0, int(pixel.x) - 4), mini(96, int(pixel.x) + 5)):
						if image.get_pixel(x, row * 96 + y).a > 0.5: visible = true
				check(visible, "%s: cano alinhado ao corpo na direção %d" % [kind, row])
	var sim := Expedition.new()
	sim.start_run(1941)
	sim.spawn_enemy(sim.actors[0].p + Vector2(100, 0), "guard")
	sim.spawn_enemy(sim.actors[0].p + Vector2(-100, 0), "bomber")
	check(sim.enemies.any(func(e): return e.kind == "guard"), "guard pode surgir na partida")
	check(sim.enemies.any(func(e): return e.kind == "bomber"), "bomber pode surgir na partida")
	print("failures=", failures)
	quit(failures)

