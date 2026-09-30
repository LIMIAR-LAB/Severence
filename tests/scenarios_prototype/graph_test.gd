extends SceneTree

const Generator = preload("res://graph_generator.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition and failures.size() < 30:
		failures.append(message)

func reachable(graph: Dictionary, start: String, removed: String = "") -> Array:
	var seen: Array = [start]
	var queue: Array = [start]
	while not queue.is_empty():
		var current = queue.pop_front()
		for edge in graph.edges:
			var next: String = ""
			if edge.from == current: next = edge.to
			elif edge.to == current: next = edge.from
			if next != "" and next != removed and not seen.has(next):
				seen.append(next)
				queue.append(next)
	return seen

func _initialize() -> void:
	var report: Dictionary = {"schema": "prototype-test-report-v1", "engine_version": Engine.get_version_info().string, "generator_version": Generator.VERSION, "profiles": [], "failures": []}
	var profiles: Array = Generator.profiles()
	check(profiles.size() == 5, "Expected five profile fixtures")
	for profile in profiles:
		if not profile is Dictionary or not profile.has("id"):
			check(false, "Malformed profile fixture")
			continue
		var hashes: Array = []
		var unique: Dictionary = {}
		var started: int = Time.get_ticks_usec()
		for seed_value in range(1000):
			var graph: Dictionary = Generator.generate(seed_value, profile)
			check(graph.get("ok", false), "Generation rejected %s/%d: %s" % [profile.id, seed_value, graph])
			if not graph.get("ok", false): continue
			check(graph.branch_count >= profile.branches_min and graph.branch_count <= profile.branches_max, "Branch bounds violated")
			check(graph.cycle_count >= profile.cycles_min and graph.cycle_count <= profile.cycles_max, "Cycle bounds violated")
			check(graph.edges.size() - graph.rooms.size() + 1 == graph.cycle_count, "Declared cycle rank mismatch")
			var canonical: String = Generator.canonical(graph)
			hashes.append(canonical.sha256_text())
			var reordered: Dictionary = {}
			var keys: Array = profile.keys()
			keys.reverse()
			for key in keys: reordered[key] = profile[key]
			check(canonical == Generator.canonical(Generator.generate(seed_value, reordered)), "Dictionary order affected seed %d" % seed_value)
			var roles: Dictionary = {}
			var ids: Array = []
			for room in graph.rooms:
				check(not ids.has(room.id), "Duplicate room ID")
				ids.append(room.id)
				if room.role in ["entry", "clue", "miniboss", "boss"]:
					check(not roles.has(room.role), "Duplicate required role")
					roles[room.role] = room.id
			for role in ["entry", "clue", "miniboss", "boss"]:
				check(roles.has(role), "Missing required role %s" % role)
			if roles.size() != 4: continue
			check(reachable(graph, roles.entry).size() == ids.size(), "Disconnected graph")
			for role in ["clue", "miniboss"]:
				check(not reachable(graph, roles.entry, roles[role]).has(roles.boss), "Mandatory role bypass: %s" % role)
			check(not reachable(graph, roles.entry, roles.clue).has(roles.miniboss), "Clue must precede miniboss")
			var edge_keys: Array = []
			var edge_ids: Array = []
			var actual_branches: int = 0
			for edge in graph.edges:
				check(not edge_ids.has(edge.id), "Duplicate edge ID")
				edge_ids.append(edge.id)
				if graph.main_path.has(edge.from) and not graph.main_path.has(edge.to): actual_branches += 1
				check(ids.has(edge.from) and ids.has(edge.to), "Unknown endpoint")
				check(edge.from != edge.to, "Self-loop")
				var endpoints: Array = [edge.from, edge.to]
				endpoints.sort()
				var edge_key: String = str(endpoints)
				check(not edge_keys.has(edge_key), "Duplicate edge")
				edge_keys.append(edge_key)
			check(actual_branches == graph.branch_count, "Actual branch count mismatch")
			var shape: Dictionary = {"rooms": graph.rooms, "edges": graph.edges}
			unique[JSON.stringify(shape, "", true).sha256_text()] = true
			if seed_value in [0, 42]:
				var sample = FileAccess.open("res://../../../_bmad-output/implementation-artifacts/cenarios-gerador/sample-%s-%d.json" % [profile.id, seed_value], FileAccess.WRITE)
				if sample: sample.store_string(JSON.stringify(graph, "\t", true))
		var elapsed_ms: float = (Time.get_ticks_usec() - started) / 1000.0
		report.profiles.append({"id":profile.id,"seeds":1000,"unique_graphs":unique.size(),"corpus_hash":str(hashes).sha256_text(),"elapsed_ms":elapsed_ms})
	check(not Generator.generate(1, {}).get("ok", true), "Empty profile accepted")
	var invalid: Dictionary = profiles[0].duplicate(true) if not profiles.is_empty() and profiles[0] is Dictionary else {}
	invalid.branches_min = -1
	check(not Generator.generate(1, invalid).get("ok", true), "Negative bounds accepted")
	invalid = profiles[0].duplicate(true) if not profiles.is_empty() and profiles[0] is Dictionary else {}
	invalid.cycles_max = 9999
	check(not Generator.generate(1, invalid).get("ok", true), "Impossible cycle count accepted")
	if not profiles.is_empty() and profiles[0] is Dictionary:
		for mutation in [{"id":"unknown"}, {"attachment":"unknown"}, {"branches_min":10,"branches_max":2}, {"spine_length":1.5}, {"spine_length":INF}, {"spine_length":"2"}]:
			invalid = profiles[0].duplicate(true)
			invalid.merge(mutation, true)
			var rejected: Dictionary = Generator.generate(1, invalid)
			check(not rejected.get("ok", true) and rejected.has("error") and rejected.size() == 2, "Invalid configuration returned partial data")
		var zero: Dictionary = profiles[0].duplicate(true)
		zero.merge({"branches_min":0,"branches_max":0,"cycles_min":0,"cycles_max":0}, true)
		var zero_graph: Dictionary = Generator.generate(-1, zero)
		check(zero_graph.get("ok", false) and zero_graph.edges.size() == zero_graph.rooms.size()-1, "Zero-branch tree failed")
		for extreme_seed in [-9223372036854775807, 9223372036854775807]:
			check(Generator.canonical(Generator.generate(extreme_seed, profiles[0])) == Generator.canonical(Generator.generate(extreme_seed, profiles[0])), "Extreme seed unstable")
	report.failures = failures
	var destination: String = "res://../../../_bmad-output/implementation-artifacts/cenarios-gerador/graph-tests.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): destination = arg.trim_prefix("--report=")
	var output = FileAccess.open(destination, FileAccess.WRITE)
	if output: output.store_string(JSON.stringify(report, "\t", true))
	else: check(false, "Cannot write evidence report: " + destination)
	print(JSON.stringify(report, "", true))
	quit(0 if failures.is_empty() else 1)
