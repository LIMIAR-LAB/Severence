extends RefCounted
## Bounded materialized layout, consumed by the caller; no scene or file writes.
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
const VERSION := "scn-layout-1"
const WIDTH := 200.0
const GRID := 200.0
const MARGIN := 0.0 # Authored art_bounds already include the real exterior shell.
const MAX_ATTEMPTS := 12
const MAX_VISITS := 12000

static func _failure(message: String, attempts: int = 0) -> Dictionary:
	return {"ok":false,"origins":{},"corridors":[],"doors":[],"manifest":{},"errors":[message],"attempts":attempts}

static func _bounds(t: Dictionary) -> Rect2:
	var bounds: Rect2 = t.footprint[0]
	for rect in t.footprint: bounds = bounds.merge(rect)
	for layer in t.layers: bounds = bounds.merge(layer.rect)
	for rect in t.get("art_bounds",[]): bounds = bounds.merge(rect)
	return bounds.grow(MARGIN)

static func _segment(a: Vector2, b: Vector2, width: float = WIDTH) -> Rect2:
	return Rect2(Vector2(minf(a.x,b.x),minf(a.y,b.y))-Vector2.ONE*width/2,Vector2(absf(a.x-b.x),absf(a.y-b.y))+Vector2.ONE*width)

static func _physical_bounds(room: Dictionary) -> Rect2:
	var result: Rect2 = room.footprint[0]
	for rect in room.footprint: result=result.merge(rect)
	return result

static func _compatible(a: Dictionary, b: Dictionary, edge: Dictionary) -> bool:
	var kind: String = "shortcut" if edge.has("from_connector") and edge.has("to_connector") and a.type == "shortcut" else "walk"
	var minimum: float = 128 if kind == "shortcut" else WIDTH
	return a.type == kind and b.type == kind and a.width >= minimum and b.width >= minimum and a.height == b.height and a.get("material_family","") == b.get("material_family","")

static func _stub(port: Dictionary, bounds: Rect2) -> Dictionary:
	var point: Vector2 = port.position
	var n: Vector2 = port.normal
	var outside := point
	if n.x > 0: outside.x = ceilf((bounds.end.x+GRID)/GRID)*GRID
	elif n.x < 0: outside.x = floorf((bounds.position.x-GRID)/GRID)*GRID
	elif n.y > 0: outside.y = ceilf((bounds.end.y+GRID)/GRID)*GRID
	else: outside.y = floorf((bounds.position.y-GRID)/GRID)*GRID
	var snapped := outside.snapped(Vector2.ONE*GRID)
	var width: float = 128 if port.type=="shortcut" else WIDTH
	return {"cell":Vector2i(roundi(snapped.x/GRID),roundi(snapped.y/GRID)),"rects":[_segment(point,outside,width),_segment(outside,snapped,width)]}

static func _free(rect: Rect2, occupied: Array, corridors: Array) -> bool:
	for other in occupied:
		if rect.intersects(other): return false
	for other in corridors:
		if rect.grow(16).intersects(other): return false
	return true

static func _route(start: Vector2i, finish: Vector2i, occupied: Array, corridors: Array, limits: Rect2, direction_offset: int, budget: Dictionary) -> Array:
	var queue: Array[Vector2i] = [start]
	var parent: Dictionary = {start:start}
	var head := 0
	var directions := [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
	while not queue.is_empty() and head < MAX_VISITS and budget.visits < 120000:
		var cell: Vector2i = queue.pop_front(); head += 1; budget.visits += 1
		if cell == finish:
			var path: Array = []
			while cell != start:
				path.push_front(Vector2(cell)*GRID)
				cell = parent[cell]
			path.push_front(Vector2(start)*GRID)
			return path
		for i in 4:
			var next: Vector2i = cell + directions[(i+direction_offset)%4]
			if parent.has(next): continue
			var center := Vector2(next)*GRID
			if not limits.has_point(center): continue
			if not _free(_segment(Vector2(cell)*GRID,center),occupied,corridors): continue
			parent[next] = cell
			var score: int = absi(next.x-finish.x)+absi(next.y-finish.y)
			var insertion := queue.size()
			while insertion>0:
				var previous: Vector2i = queue[insertion-1]
				if absi(previous.x-finish.x)+absi(previous.y-finish.y) <= score: break
				insertion -= 1
			queue.insert(insertion,next)
	return []

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var item = items[i]; items[i]=items[j]; items[j]=item

static func _root(groups: Dictionary, id: String) -> String:
	while groups[id]!=id: id=groups[id]
	return id

## Walk connectivity never depends on destructible shortcuts or the secret room.
static func _select_topology(nodes: Array, edges: Array, rng: RandomNumberGenerator) -> Array:
	var groups := {}; var selected: Array = []; var optional: Array = []; var loops: Array = []
	for node in nodes: groups[node.id]=node.id
	for edge in edges:
		# These tentacle corridors start blocked; never count them as tree links.
		if edge.get("shortcut",false) or edge.id in ["corridor-07","corridor-08"]: selected.append(edge); continue
		if edge.get("hidden",false) or edge.get("required",false):
			selected.append(edge); groups[_root(groups,edge.from)]=_root(groups,edge.to)
		else: optional.append(edge)
	_shuffle(optional,rng)
	for edge in optional:
		var a := _root(groups,edge.from); var b := _root(groups,edge.to)
		if a!=b: selected.append(edge); groups[a]=b
		else: loops.append(edge)
	_shuffle(loops,rng)
	# Leave at least one removable legacy loop out so the result is not the full graph.
	for i in rng.randi_range(0,maxi(0,mini(1,loops.size()-1))): selected.append(loops[i])
	selected.sort_custom(func(a,b):return a.id<b.id)
	return selected

static func generate_layout(seed_value: int, input_rooms: Array, input_edges: Array, options: Dictionary = {}) -> Dictionary:
	if input_rooms.is_empty() or input_rooms.size()>32: return _failure("rooms: expected 1..32")
	var nodes: Array = input_rooms.duplicate(true)
	var edges: Array = input_edges.duplicate(true)
	var known: Dictionary = {}; var roles := {"entry":0,"boss":0}; var repeats: Dictionary = {}
	var pitch := Vector2(3000,3000)
	for node in nodes:
		if not node is Dictionary or not node.get("id") is String or node.id.is_empty() or known.has(node.id): return _failure("rooms: invalid/duplicate id")
		if not node.get("template") is Dictionary: return _failure("rooms: template required")
		if node.get("transform","translate") != "translate": return _failure("rotation unsupported")
		if node.has("fixed_origin") and (not node.fixed_origin is Vector2 or not node.fixed_origin.is_finite()): return _failure("fixed_origin must be finite Vector2")
		var errors := Rooms.validate(node.template)
		if not errors.is_empty(): return _failure("template invalid: "+str(errors))
		if not node.template.get("art_bounds",[]) is Array: return _failure("art_bounds must be an array")
		for rect in node.template.get("art_bounds",[]):
			if not rect is Rect2 or not rect.position.is_finite() or not rect.size.is_finite() or not rect.has_area(): return _failure("invalid art reservation")
		var template_id: String = node.template.template_id
		repeats[template_id] = repeats.get(template_id,0)+1
		if repeats[template_id]>node.template.get("repeat_limit",32): return _failure("template repeat_limit exceeded: "+template_id)
		known[node.id] = true
		if roles.has(node.get("role","")): roles[node.role] += 1
		var size := _bounds(node.template).size
		pitch.x = maxf(pitch.x,ceilf((size.x+1600)/GRID)*GRID)
		pitch.y = maxf(pitch.y,ceilf((size.y+1600)/GRID)*GRID)
	if roles.entry != 1 or roles.boss != 1: return _failure("one entry and one boss required")
	var edge_ids: Dictionary = {}; var pairs: Dictionary = {}; var adjacency: Dictionary = {}
	for id in known: adjacency[id] = []
	for edge in edges:
		if not edge is Dictionary or not edge.get("id") is String or edge.id.is_empty() or edge_ids.has(edge.id): return _failure("edges: invalid/duplicate id")
		if not known.has(edge.get("from")) or not known.has(edge.get("to")) or edge.from == edge.to: return _failure("edges: invalid endpoints")
		var pair: Array = [edge.from,edge.to]; pair.sort()
		var key: String = str(pair)
		if pairs.has(key): return _failure("edges: duplicate pair")
		pairs[key] = true; edge_ids[edge.id] = true
		adjacency[edge.from].append(edge.to); adjacency[edge.to].append(edge.from)
	var seen: Dictionary = {}; var pending: Array = [nodes[0].id]
	while not pending.is_empty():
		var id: String = pending.pop_back()
		if seen.has(id): continue
		seen[id] = true
		pending.append_array(adjacency[id])
	if seen.size()!=nodes.size(): return _failure("graph disconnected")
	nodes.sort_custom(func(a,b):return a.id<b.id)
	edges.sort_custom(func(a,b):return a.id<b.id)
	var variable: bool = options.get("variable_topology",false)
	var dropped: Array = []
	if variable:
		var topology_rng := RandomNumberGenerator.new()
		topology_rng.seed=Seeds.derive(seed_value,"docks",0,"topology","scn-layout-2")
		var selected := _select_topology(nodes,edges,topology_rng)
		for edge in edges:
			if not selected.has(edge): dropped.append(edge.id)
		edges=selected
		for id in adjacency: adjacency[id]=[]
		for edge in edges:
			adjacency[edge.from].append(edge.to); adjacency[edge.to].append(edge.from)
	var rejection_counts: Dictionary = {}
	var budget := {"visits":0}
	for attempt in MAX_ATTEMPTS:
		var rng := RandomNumberGenerator.new(); rng.seed = Seeds.derive(seed_value,"docks",attempt,"layout",VERSION)
		var slots: Array = range(nodes.size()*3)
		for i in range(slots.size()-1,0,-1):
			var j := rng.randi_range(0,i); var value: int = slots[i]; slots[i]=slots[j]; slots[j]=value
		var origins: Dictionary = {}; var instances: Dictionary = {}; var occupied: Array = []; var limits := Rect2(); var valid := true
		var placement_nodes: Array = nodes.duplicate()
		var placement_edges: Array = edges.duplicate()
		if variable:
			_shuffle(placement_nodes,rng)
			_shuffle(placement_edges,rng)
		placement_nodes.sort_custom(func(a,b):return a.has("fixed_origin") and not b.has("fixed_origin"))
		var remaining: Array = placement_nodes.duplicate()
		while not remaining.is_empty():
			var selected_index := 0
			for index in remaining.size():
				if remaining[index].has("fixed_origin"): selected_index=index; break
				var anchored := false
				for neighbor in adjacency[remaining[index].id]:
					if instances.has(neighbor): anchored=true
				if anchored: selected_index=index; break
			var node: Dictionary = remaining.pop_at(selected_index)
			var local := _bounds(node.template)
			var origin: Vector2 = node.get("fixed_origin",Vector2.ZERO)
			if not node.has("fixed_origin"):
				var found := false
				var candidates: Array = []
				for edge in placement_edges:
					var parent_id: String = edge.from if edge.to==node.id else (edge.to if edge.from==node.id else "")
					if not instances.has(parent_id): continue
					var parent: Dictionary = instances[parent_id]
					for pa in parent.connectors:
						var parent_key: String = "from_connector" if edge.from==parent_id else "to_connector"
						var child_key: String = "to_connector" if edge.from==parent_id else "from_connector"
						if edge.has(parent_key) and edge[parent_key]!=pa.id: continue
						for pb in node.template.connectors:
							if edge.has(child_key) and edge[child_key]!=pb.id: continue
							if pa.normal != -pb.normal or not _compatible(pa,pb,edge): continue
							for gap_index in 12:
								var gap: float = 400+200*((gap_index+rng.randi_range(0,3))%12)
								if variable: gap=800+400*((gap_index+rng.randi_range(0,8))%12)
								candidates.append(pa.position+pa.normal*gap-pb.position)
				for slot in slots: candidates.append(Vector2(int(slot)%6,floori(float(slot)/6))*pitch)
				for candidate in candidates:
					origin = candidate
					if _free(Rect2(local.position+origin,local.size),occupied,[]): found=true; break
				if not found: valid=false; break
			var reservation := Rect2(local.position+origin,local.size)
			if not _free(reservation,occupied,[]): valid=false; break
			occupied.append(reservation)
			limits = reservation if origins.is_empty() else limits.merge(reservation)
			origins[node.id] = origin
			instances[node.id] = Rooms.instantiate(node.template,node.id,origin)
			var translated_art: Array = []
			for rect in node.template.get("art_bounds",[]): translated_art.append(Rect2(rect.position+origin,rect.size))
			instances[node.id]["art_bounds"] = translated_art
		if not valid:
			rejection_counts["overlap"] = rejection_counts.get("overlap",0)+1; continue
		limits = limits.grow(2400)
		var corridors: Array = []; var doors: Array = []; var used: Dictionary = {}; var routes: Array = []; var gates: Array = []
		for edge in edges:
			var a: Dictionary = instances[edge.from]; var b: Dictionary = instances[edge.to]
			var ports_a: Array = a.connectors.duplicate(); var ports_b: Array = b.connectors.duplicate()
			ports_a.sort_custom(func(x,y):return x.id<y.id); ports_b.sort_custom(func(x,y):return x.id<y.id)
			var bound_a := _physical_bounds(a); var bound_b := _physical_bounds(b)
			var route_occupied: Array = []
			for room_id in instances:
				if room_id in [edge.from,edge.to]: route_occupied.append_array(instances[room_id].footprint)
				else: route_occupied.append(_bounds(instances[room_id]))
			var connected := false
			for pa in ports_a:
				if used.has(edge.from+":"+pa.id) or (edge.has("from_connector") and edge.from_connector!=pa.id): continue
				for pb in ports_b:
					if used.has(edge.to+":"+pb.id) or (edge.has("to_connector") and edge.to_connector!=pb.id) or not _compatible(pa,pb,edge): continue
					var sa := _stub(pa,bound_a); var sb := _stub(pb,bound_b)
					var stub_rects: Array = sa.rects+sb.rects
					var delta: Vector2 = pb.position-pa.position
					var direct: bool = pa.normal == -pb.normal and absf(delta.cross(pa.normal))<0.01 and delta.dot(pa.normal)>=0
					if direct:
						var foreign: Array = []
						for room_id in instances:
							if room_id not in [edge.from,edge.to]: foreign.append(_bounds(instances[room_id]))
						if not _free(_segment(pa.position,pb.position,128 if pa.type=="shortcut" else WIDTH),foreign,corridors): direct=false
					if direct: stub_rects = [_segment(pa.position,pb.position,128 if pa.type=="shortcut" else WIDTH)]
					var clear := true
					for owner in [edge.from,edge.to]:
						var owner_port: Dictionary = pa if owner==edge.from else pb
						for offset in [-80,-40,0,40,80]:
							var foot: Vector2 = owner_port.position + owner_port.normal*offset
							for obstacle in instances[owner].obstacles:
								if obstacle.rect.grow(23).has_point(foot):
									if owner_port.type == "shortcut":
										var gate := {"edge_id":edge.id,"room":owner,"connector_id":owner_port.id,"rect":obstacle.rect,"kind":obstacle.kind,"requires_replacement":true}
										if not gates.has(gate): gates.append(gate)
										continue
									clear=false
									rejection_counts["throat:"+owner+":"+str(obstacle.kind)] = rejection_counts.get("throat:"+owner+":"+str(obstacle.kind),0)+1
						for rect in (stub_rects if direct else (sa.rects if owner==edge.from else sb.rects)):
							for gap in instances[owner].get("gaps",[]):
								if rect.intersects(gap): clear=false
							for other_id in instances:
								if other_id!=owner and not (direct and other_id in [edge.from,edge.to]):
									var other_bounds: Rect2 = _physical_bounds(instances[other_id]) if other_id in [edge.from,edge.to] else _bounds(instances[other_id])
									if rect.intersects(other_bounds): clear=false
							if not _free(rect,[],corridors): clear=false
					if not clear: continue
					var path: Array = [pa.position] if direct else _route(sa.cell,sb.cell,route_occupied,corridors,limits,rng.randi_range(0,3),budget)
					if budget.visits >= 120000: return _failure("routing search budget exhausted",attempt+1)
					if path.is_empty(): continue
					var start_index := corridors.size()
					corridors.append_array(stub_rects)
					for i in range(path.size()-1): corridors.append(_segment(path[i],path[i+1]))
					for pair in [[edge.from,pa],[edge.to,pb]]:
						var port: Dictionary = pair[1]
						used[pair[0]+":"+port.id]=true
						doors.append({"id":edge.id+":"+pair[0],"room":pair[0],"connector_id":port.id,"position":port.position,"normal":port.normal,"width":128 if port.type=="shortcut" else WIDTH,"height":port.height,"type":port.type,"edge_id":edge.id})
					var route: Dictionary = edge.duplicate(true)
					route.merge({"corridor_start":start_index,"corridor_count":corridors.size()-start_index,"from_connector":pa.id,"to_connector":pb.id,"endpoint_width":128 if pa.type=="shortcut" else WIDTH,"from_position":pa.position,"to_position":pb.position},true)
					routes.append(route)
					connected=true; break
				if connected: break
			if not connected:
				rejection_counts["edge:"+edge.id] = rejection_counts.get("edge:"+edge.id,0)+1
				valid=false; break
		if not valid:
			rejection_counts["routing_or_ports"] = rejection_counts.get("routing_or_ports",0)+1; continue
		var caps: Array = []
		for node in nodes:
			for port in instances[node.id].connectors:
				if not used.has(node.id+":"+port.id): caps.append({"room":node.id,"connector_id":port.id,"type":port.type,"position":port.position,"normal":port.normal,"width":port.width,"height":port.height})
		if variable:
			return {"ok":true,"origins":origins,"corridors":corridors,"doors":doors,"errors":[],"manifest":{"seed":str(seed_value),"version":"scn-layout-2","rooms":nodes,"edges":routes,"caps_needed":caps,"gates_needed":gates,"attempts":attempt+1,"rejections":rejection_counts,"catalog_fingerprint":Seeds.canonical(nodes).sha256_text(),"reservations":occupied,"corridor_width":WIDTH,"dropped_edges":dropped,"topology":"seeded-walk-tree-with-loops"}}
		return {"ok":true,"origins":origins,"corridors":corridors,"doors":doors,"errors":[],"manifest":{"seed":str(seed_value),"version":VERSION,"rooms":nodes,"edges":routes,"caps_needed":caps,"gates_needed":gates,"attempts":attempt+1,"rejections":rejection_counts,"catalog_fingerprint":Seeds.canonical(nodes).sha256_text(),"reservations":occupied,"corridor_width":WIDTH}}
	return _failure("bounded search exhausted: "+str(rejection_counts),MAX_ATTEMPTS)
