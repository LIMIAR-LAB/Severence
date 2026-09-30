extends SceneTree
const Generator = preload("res://tools/scenarios/prototype/layout_generator.gd")
const DocksInput = preload("res://scripts/scenarios/procedural_docks.gd")
const Codec = preload("res://scripts/scenarios/module_catalog.gd")
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
var failures: Array[String] = []
func check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
func _svg(result: Dictionary) -> void:
	var bounds: Rect2 = result.manifest.reservations[0]
	for rect in result.manifest.reservations: bounds=bounds.merge(rect)
	for rect in result.corridors: bounds=bounds.merge(rect)
	bounds=bounds.grow(200)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1100" viewBox="%s %s %s %s"><rect x="%s" y="%s" width="%s" height="%s" fill="#101820"/>' % [bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y,bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y]
	for rect in result.corridors:
		svg += '<rect x="%s" y="%s" width="%s" height="%s" fill="#6b8391"/>' % [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
	for room in result.manifest.rooms:
		var origin: Vector2 = result.origins[room.id]
		var reserve: Rect2 = Generator._bounds(room.template); reserve.position+=origin
		svg += '<rect x="%s" y="%s" width="%s" height="%s" fill="none" stroke="#eabc66" stroke-width="10"/>' % [reserve.position.x,reserve.position.y,reserve.size.x,reserve.size.y]
		for local in room.template.footprint:
			var rect := Rect2(local.position+origin,local.size)
			svg += '<rect x="%s" y="%s" width="%s" height="%s" fill="#345e6f" stroke="#77bed0" stroke-width="6"/>' % [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
		svg += '<text x="%s" y="%s" font-size="100" fill="white">%s</text>' % [origin.x+60,origin.y+150,room.id.xml_escape()]
	for door in result.doors:
		svg += '<circle cx="%s" cy="%s" r="42" fill="%s"/>' % [door.position.x,door.position.y,"#ff805a" if door.type=="shortcut" else "#b7ef91"]
	svg+='</svg>'
	FileAccess.open("res://_bmad-output/implementation-artifacts/cenarios-gerador/layout-variation-%s.svg" % result.manifest.seed+"",FileAccess.WRITE).store_string(svg)
	var image := Image.new()
	if image.load_svg_from_string(svg)==OK: image.save_png("res://_bmad-output/implementation-artifacts/cenarios-gerador/layout-variation-%s.png" % result.manifest.seed+"")
func _initialize() -> void:
	var sim := Expedition.new(); sim.start_run(1941)
	var source: Dictionary = DocksInput.inputs(sim)
	var hashes: Array = []; var unique: Dictionary = {}; var times: Array = []; var cases: Array = []
	for seed_value in [1941,42]:
		var start := Time.get_ticks_msec()
		var result := Generator.generate_layout(seed_value,source.rooms,source.edges,{"variable_topology":true})
		times.append(Time.get_ticks_msec()-start)
		cases.append({"seed":seed_value,"ok":result.ok,"elapsed_ms":times.back(),"attempts":result.get("manifest",{}).get("attempts",result.get("attempts",0)),"errors":result.errors})
		check(result.ok,"real layout rejected %d: %s" % [seed_value,result.errors])
		if not result.ok: continue
		cases.back()["edge_ids"]=result.manifest.edges.map(func(e):return e.id)
		cases.back()["dropped_edges"]=result.manifest.dropped_edges
		cases.back()["caps"]=result.manifest.caps_needed.size()
		var connected := {"entry":true}
		for pass_index in source.rooms.size():
			for edge in result.manifest.edges:
				if edge.get("hidden",false) or edge.get("shortcut",false) or edge.id in ["corridor-07","corridor-08"]: continue
				if connected.has(edge.from): connected[edge.to]=true
				if connected.has(edge.to): connected[edge.from]=true
		check(connected.size()==13,"walk graph depends on secret/shortcut")
		for id in ["secret","shortcut-cranes","shortcut-warehouse","corridor-07","corridor-08"]:
			check(id in cases.back().edge_ids,"required edge missing: "+id)
		for cap in result.manifest.caps_needed:
			check(cap.has("position") and cap.has("normal") and cap.has("width") and cap.has("height"),"cap geometry missing")
		check(result.origins.size()==14 and result.manifest.edges.size()>=15 and result.manifest.edges.size()<19,"all rooms/edges preserved")
		for node in source.rooms:
			if node.has("fixed_origin"): check(result.origins[node.id]==node.fixed_origin,"fixed anchor moved")
		for i in result.manifest.reservations.size():
			for j in range(i+1,result.manifest.reservations.size()):
				check(not result.manifest.reservations[i].intersects(result.manifest.reservations[j]),"art reservation overlap")
		for edge in result.manifest.edges:
			if edge.get("shortcut",false): check(edge.endpoint_width==128,"shortcut width changed")
			var rects: Array = result.corridors.slice(edge.corridor_start,edge.corridor_start+edge.corridor_count)
			check(not rects.is_empty(),"edge has no corridor geometry")
			if edge.get("shortcut",false): check(minf(rects[0].size.x,rects[0].size.y)==128,"shortcut neck widened")
		for i in result.manifest.edges.size():
			var left: Dictionary = result.manifest.edges[i]
			for j in range(i+1,result.manifest.edges.size()):
				var right: Dictionary = result.manifest.edges[j]
				for rect_a in result.corridors.slice(left.corridor_start,left.corridor_start+left.corridor_count):
					for rect_b in result.corridors.slice(right.corridor_start,right.corridor_start+right.corridor_count):
						check(not rect_a.grow(0.1).intersects(rect_b),"corridors create unintended cross-edge junction")
		_svg(result)
		var canonical: String = Seeds.canonical(result)
		hashes.append(canonical.sha256_text()); unique[Seeds.canonical(result.origins)] = true
		if seed_value==1941:
			var shuffled: Array = source.rooms.duplicate(true); shuffled.reverse()
			var shuffled_edges: Array = source.edges.duplicate(true); shuffled_edges.reverse()
			check(Seeds.canonical(Generator.generate_layout(seed_value,shuffled,shuffled_edges,{"variable_topology":true}))==canonical,"array order changes result")
			FileAccess.open("res://_bmad-output/implementation-artifacts/cenarios-gerador/layout-variation-current.json",FileAccess.WRITE).store_string(Codec.serialize(result).text)
			_svg(result)
	check(unique.size()>1,"seed does not change origins")
	check(cases[0].get("edge_ids",[])!=cases[1].get("edge_ids",[]),"seeds have same topology")
	var invalid: Array = source.rooms.duplicate(true); invalid[0]["transform"]="rotate90"
	var rejected := Generator.generate_layout(1,invalid,source.edges,{"variable_topology":true})
	check(not rejected.ok and rejected.origins.is_empty() and rejected.corridors.is_empty(),"rotation failure not atomic")
	invalid = source.rooms.duplicate(true)
	for node in invalid: node["fixed_origin"] = Vector2.ZERO
	rejected=Generator.generate_layout(1,invalid,source.edges,{"variable_topology":true})
	check(not rejected.ok and rejected.origins.is_empty() and rejected.corridors.is_empty(),"impossible overlap not atomic")
	var report := {"engine":Engine.get_version_info().string,"version":"scn-layout-2","seeds":[1941,42],"cases":cases,"hashes":hashes,"unique_origins":unique.size(),"elapsed_ms":times,"failures":failures}
	var destination := "res://_bmad-output/implementation-artifacts/cenarios-gerador/layout-variation-tests.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): destination=arg.trim_prefix("--report=")
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LAYOUT_TEST ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)


