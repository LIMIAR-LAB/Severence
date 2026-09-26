extends SceneTree

# 0.15: os atlas do Titan, Spectre e fusão precisam conservar as grades do renderer.
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)

func _init() -> void:
	var atlases := [
		["res://assets/mech/titan_v3_clean.png", Vector2i(1760, 880), "Titan limpo: 10x5 em 176px"],
		["res://assets/mech/spectre_octopus_v2.png", Vector2i(512, 512), "Spectre: 4x4 em 128px"],
		["res://assets/marty/spectre_fusion_v2.png", Vector2i(640, 640), "Fusão: 4x4 em 160px"]]
	for spec in atlases:
		var image := Image.load_from_file(ProjectSettings.globalize_path(spec[0]))
		check(not image.is_empty() and image.get_size() == spec[1], spec[2])
	var titan := Image.load_from_file(ProjectSettings.globalize_path("res://assets/mech/titan_v3_clean.png"))
	for row in range(5):
		for column in range(10):
			var used := titan.get_region(Rect2i(column * 176, row * 176, 176, 176)).get_used_rect()
			check(used.position.x >= 4 and used.end.x <= 172 and used.position.y >= 4 and used.end.y <= 172,
				"Titan quadro %d,%d tem margem isolada" % [column, row])
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
	sim.actors[0].fire_flash = 0.08
	check(view.titan_visual_direction(titan_state) == Vector2.RIGHT, "Titan disparando acompanha a mira")
	view.free()
	print("ROBOT_SPRITE_ATLAS failures=", failures)
	quit(1 if failures else 0)
