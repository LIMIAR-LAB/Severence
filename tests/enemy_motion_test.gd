extends SceneTree

const Motion = preload("res://scripts/enemy_motion.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures += 1; push_error(label)

func _init() -> void:
	var motion := Motion.new()
	var directions := [Vector2.DOWN, Vector2(1, 1), Vector2.RIGHT, Vector2(1, -1), Vector2.UP, Vector2(-1, -1), Vector2.LEFT, Vector2(-1, 1)]
	var clips := {}
	for action in ["walk", "attack", "death"]:
		clips[action] = {}
		for direction in Motion.DIRECTIONS:
			clips[action][direction] = {"path": "fixture", "frames": 17, "duration": 1.0}
	motion.manifests.crawler = {"cell": 160, "pivot": [80, 144], "world_scale": 0.9, "clips": clips}
	motion.textures.fixture = null
	for row in range(8): check(motion.row_for(directions[row]) == row, "direction %d retains its own art" % row)
	var e := {"kind": "crawler", "face": Vector2.DOWN, "combat": "ready", "moving": true, "step": 0.0}
	var frames := {}
	var initial: Rect2 = motion.sample(e).destination
	for i in range(60):
		e.step = i * 8.0 / 60.0
		var sample: Dictionary = motion.sample(e)
		frames[sample.frame] = true
		check(sample.destination == initial, "walk frame %d keeps fixed canvas and pivot" % i)
	check(frames.size() >= 16, "walk plays actual sequence instead of a moving still")
	for combat in ["warning", "attack", "recover"]:
		e.combat = combat
		e.combat_t = 0.8 if combat == "recover" else 0.25
		var sample: Dictionary = motion.sample(e)
		check(sample.action == "attack" and sample.destination == initial, "%s uses articulated attack at the same scale" % combat)
	var end: Dictionary = motion.sample(e, 10.0)
	check(end.action == "death" and end.frame == 16, "death holds final pose without looping")
	check(end.destination == initial, "lying corpse does not resize to standing height")
	e.kind = "crawler_small"
	check(is_equal_approx(motion.sample(e, 0.5).scale, 0.54), "offspring preserves 60 percent scale through death")
	# Real assets must contain distinct frames and agree with their atlas metadata.
	motion.load_assets()
	check(motion.manifests.crawler.clips.walk.size() == 8,
		"octopus walking has all eight authored directions")
	for kind in motion.manifests:
		for action in motion.manifests[kind].clips:
			for direction in motion.manifests[kind].clips[action]:
				var clip: Dictionary = motion.manifests[kind].clips[action][direction]
				if clip.path == "fixture": continue
				var tex: Texture2D = motion.textures[clip.path]
				var cell := int(motion.manifests[kind].cell)
				check(tex.get_size() == Vector2(cell * int(clip.frames), cell), "%s/%s/%s atlas dimensions" % [kind, action, direction])
				var hashes := {}
				for i in range(int(clip.frames)):
					var frame := tex.get_image().get_region(Rect2i(i * cell, 0, cell, cell))
					hashes[hash(frame.get_data())] = true
				check(hashes.size() >= 8, "%s/%s/%s has at least eight unique poses" % [kind, action, direction])
		for direction in Motion.DIRECTIONS:
			var reference: PackedByteArray = PackedByteArray()
			for action in ["walk", "attack", "death"]:
				if not motion.manifests[kind].clips.get(action, {}).has(direction): continue
				var path: String = motion.manifests[kind].clips[action][direction].path
				var first: PackedByteArray = motion.textures[path].get_image().get_region(
					Rect2i(0, 0, int(motion.manifests[kind].cell), int(motion.manifests[kind].cell))).get_data()
				if reference.is_empty(): reference = first
				else: check(first == reference, "%s/%s/%s starts from the same anatomy" % [kind, action, direction])
	print("ENEMY_MOTION failures=", failures)
	quit(failures)
