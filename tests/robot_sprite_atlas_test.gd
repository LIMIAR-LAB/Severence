extends SceneTree

# 0.15: os atlas do Titan, Spectre e fusão precisam conservar as grades do renderer.
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)

func _init() -> void:
	var atlases := [
		["res://assets/mech/titan_v3.png", Vector2i(1760, 880), "Titan: 10x5 em 176px"],
		["res://assets/mech/spectre_octopus_v2.png", Vector2i(512, 512), "Spectre: 4x4 em 128px"],
		["res://assets/marty/spectre_fusion_v2.png", Vector2i(640, 640), "Fusão: 4x4 em 160px"]]
	for spec in atlases:
		var image := Image.load_from_file(ProjectSettings.globalize_path(spec[0]))
		check(not image.is_empty() and image.get_size() == spec[1], spec[2])
	print("ROBOT_SPRITE_ATLAS failures=", failures)
	quit(1 if failures else 0)
