extends SceneTree

# 0.15: os atlas do Titan, Spectre e fusão precisam conservar as grades do renderer.
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)

func _init() -> void:
	var atlases := [
		["res://assets/mech/titan_v5.png", Vector2i(1760, 880), "Titan limpo: 10x5 em 176px"],
		["res://assets/mech/spectre_octopus_v2.png", Vector2i(512, 512), "Spectre: 4x4 em 128px"],
		["res://assets/marty/spectre_fusion_v2.png", Vector2i(640, 640), "Fusão: 4x4 em 160px"]]
	for spec in atlases:
		var image := Image.load_from_file(ProjectSettings.globalize_path(spec[0]))
		check(not image.is_empty() and image.get_size() == spec[1], spec[2])
	var titan := Image.load_from_file(ProjectSettings.globalize_path("res://assets/mech/titan_v5.png"))
	for row in range(5):
		var first := titan.get_region(Rect2i(176, row * 176 + 120, 176, 44)).get_data()
		var second := titan.get_region(Rect2i(352, row * 176 + 120, 176, 44)).get_data()
		check(first != second, "Titan vista %d possui passos distintos" % row)
	for row in range(5):
		for column in range(10):
			var used := titan.get_region(Rect2i(column * 176, row * 176, 176, 176)).get_used_rect()
			check(used.position.x >= 4 and used.end.x <= 172 and used.position.y >= 4 and used.end.y <= 172,
				"Titan quadro %d,%d tem margem isolada" % [column, row])
	# 0.15: linhas 3 e 4 são costas — sem viseira acesa nem núcleo ciano no tronco
	for row in [3, 4]:
		for column in range(10):
			var lit := 0
			for y in range(row * 176 + 20, row * 176 + 92):
				for x in range(column * 176 + 50, column * 176 + 130):
					var c := titan.get_pixel(x, y)
					if c.a > 0.8 and c.b > 0.55 and c.g > 0.5 and c.b - c.r > 0.2: lit += 1
			check(lit < 25, "Titan costas %d,%d sem viseira/núcleo (%d px ciano)" % [column, row, lit])
	var sim := Expedition.new()
	var view := DockView.new(); view.sim = sim
	var fused := {"move": Vector2.UP, "aim": Vector2.RIGHT, "facing": Vector2.RIGHT, "slash": 0.0, "fire_flash": 0.0}
	check(view.fusion_visual_direction(fused) == Vector2.UP, "fusão andando para cima mostra as costas")
	fused.fire_flash = 0.08
	check(view.fusion_visual_direction(fused) == Vector2.RIGHT, "fusão atacando acompanha a mira")
	var spectre := {"moving": true, "move_dir": Vector2.UP, "aim": Vector2.RIGHT, "shot": 0.0}
	check(view.spectre_visual_direction(spectre) == Vector2.UP, "Spectre andando para cima mostra as costas")
	spectre.shot = 0.4
	check(view.spectre_visual_direction(spectre) == Vector2.RIGHT, "Spectre atacando acompanha a mira")
	sim.actors = [sim.actor(0, Vector2.ZERO)]
	var titan_state := sim.new_mech(Vector2.ZERO); titan_state.occupant = 0; titan_state.moving = true; titan_state.move_dir = Vector2.UP
	check(view.titan_visual_direction(titan_state) == Vector2.UP, "Titan andando para cima mostra as costas")
	check(view.titan_pose(Vector2.UP)[0] == 4, "Titan olhando para cima usa a linha de costas")
	check(view.titan_pose(Vector2.RIGHT) == [2, false], "Titan à direita conserva a lateral original")
	check(view.titan_pose(Vector2.LEFT) == [2, true], "Titan à esquerda espelha a lateral original")
	check(view.titan_pose(Vector2.DOWN) == [0, false], "Titan para baixo usa frente")
	titan_state.moving = false; titan_state.aim = Vector2.UP
	check(view.titan_pose(view.titan_visual_direction(titan_state))[0] == 4, "Titan parado mirando para cima mostra as costas")
	titan_state.moving = true; titan_state.aim = Vector2.RIGHT
	sim.actors[0].fire_flash = 0.08
	check(view.titan_visual_direction(titan_state) == Vector2.RIGHT, "Titan disparando acompanha a mira")
	view.free()
	print("ROBOT_SPRITE_ATLAS failures=", failures)
	quit(1 if failures else 0)
