extends SceneTree

var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func _init() -> void:
	for kind in ["guard", "bomber"]:
		var path := "res://assets/enemies/%s_pixellab_v1.png" % kind
		var texture: Texture2D = load(path)
		var image: Image = texture.get_image() if texture != null else null
		check(image != null and image.get_size() == Vector2i(480, 768), "%s: atlas 5 poses x 8 direções" % kind)
		if image == null: continue
		for row in range(8):
			var used := false
			for y in range(row * 96, (row + 1) * 96):
				for x in range(96):
					if image.get_pixel(x, y).a > 0.5: used = true; break
				if used: break
			check(used, "%s: direção %d contém desenho" % [kind, row])
	var sim := Expedition.new()
	sim.start_run(1941)
	sim.spawn_enemy(sim.actors[0].p + Vector2(100, 0), "guard")
	sim.spawn_enemy(sim.actors[0].p + Vector2(-100, 0), "bomber")
	check(sim.enemies.any(func(e): return e.kind == "guard"), "guard pode surgir na partida")
	check(sim.enemies.any(func(e): return e.kind == "bomber"), "bomber pode surgir na partida")
	print("failures=", failures)
	quit(failures)
