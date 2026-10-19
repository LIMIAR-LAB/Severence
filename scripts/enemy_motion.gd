extends RefCounted
## Directional PixelLab sequences. Atlas geometry never depends on the pose.

const DIRECTIONS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
var manifests: Dictionary = {}
var textures: Dictionary = {}

func load_assets() -> void:
	for kind in ["crawler", "cult", "fish", "brute", "guard", "bomber", "golem"]:
		var path := "res://assets/enemies/motion_v3/%s/manifest.json" % kind
		if not FileAccess.file_exists(path): continue
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		manifests[kind] = manifest
		for action in manifest.clips:
			for direction in manifest.clips[action]:
				var clip: Dictionary = manifest.clips[action][direction]
				textures[clip.path] = load(clip.path)

func row_for(face: Vector2) -> int:
	return posmod(roundi((PI * 0.5 - face.angle()) / (PI * 0.25)), 8)

func sample(e: Dictionary, death_seconds: float = -1.0) -> Dictionary:
	var kind: String = "crawler" if e.kind == "crawler_small" else e.kind
	if not manifests.has(kind): return {}
	var manifest: Dictionary = manifests[kind]
	var direction: String = DIRECTIONS[row_for(e.get("face", Vector2.DOWN))]
	var action := "walk"
	var progress := 0.0
	var combat: String = e.get("combat", "ready")
	if death_seconds >= 0.0:
		action = "death"
		progress = death_seconds
	elif combat == "warning":
		action = "attack"
		var warning := 0.85 if kind == "guard" else 0.5
		progress = clampf(1.0 - e.get("combat_t", warning) / warning, 0.0, 1.0) * 0.25
	elif combat == "attack":
		action = "attack"
		var duration := 2.05 if kind == "guard" else (0.6 if kind in ["crawler", "brute"] else 0.45)
		progress = 0.25 + clampf(1.0 - e.get("combat_t", duration) / duration, 0.0, 1.0) * 0.5
	elif combat == "recover" and e.get("combat_t", 0.0) > 0.65:
		action = "attack"
		progress = 0.75 + clampf((0.9 - e.combat_t) / 0.25, 0.0, 1.0) * 0.25
	elif e.get("moving", false):
		# Simulation step advances by eight per second for common enemies.
		progress = fposmod(e.get("step", 0.0) / 8.0, 0.9) / 0.9
	var clip: Dictionary = manifest.clips.get(action, {}).get(direction, {})
	if clip.is_empty(): return {}
	var count := int(clip.frames)
	if action == "death": progress /= float(clip.duration)
	var frame := clampi(int(progress * (count - 1)), 0, count - 1)
	# Gun clips put the firing pose at the existing projectile emission instant.
	# This changes visual sampling only, never warning/attack timers or damage.
	if action == "attack" and clip.has("fire_frame"):
		var fire_frame := int(clip.fire_frame)
		var recover_frame := int(clip.get("recover_frame", count - 2))
		if combat == "warning":
			frame = clampi(int(progress / 0.25 * fire_frame), 0, fire_frame - 1)
		elif combat == "attack":
			frame = clampi(fire_frame + int((progress - 0.25) / 0.5 * (recover_frame - fire_frame)), fire_frame, recover_frame)
		elif combat == "recover":
			frame = clampi(recover_frame + int((progress - 0.75) / 0.25 * (count - 1 - recover_frame)), recover_frame, count - 1)
	var scale: float = manifest.world_scale * (0.6 if e.kind == "crawler_small" else 1.0)
	var cell := float(manifest.cell)
	var pivot := Vector2(manifest.pivot[0], manifest.pivot[1])
	return {"texture": textures[clip.path], "source": Rect2(frame * cell, 0, cell, cell),
		"destination": Rect2(-pivot * scale, Vector2.ONE * cell * scale),
		"action": action, "frame": frame, "count": count, "scale": scale}
