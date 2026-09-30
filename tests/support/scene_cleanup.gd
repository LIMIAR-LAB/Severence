extends RefCounted
## Nodes release audio players before the mixer finishes releasing Ogg playbacks.
static func finish(tree: SceneTree) -> void:
	# Freeze controllers before stopping players, so update() cannot restart music.
	for child in tree.root.get_children(): child.process_mode = Node.PROCESS_MODE_DISABLED
	await tree.create_timer(0.1).timeout
	stop_players(tree.root)
	await tree.physics_frame
	await tree.physics_frame
	for child in tree.root.get_children(): child.queue_free()
	await tree.process_frame
	await tree.create_timer(0.25).timeout

static func stop_players(node: Node) -> void:
	if node is AudioStreamPlayer:
		node.stop(); node.stream = null
	for child in node.get_children(): stop_players(child)
