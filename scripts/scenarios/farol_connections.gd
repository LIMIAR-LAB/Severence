extends RefCounted
## Bench assembly: room endpoints remain distinct from corridor outer endpoints.
const Module = preload("res://scripts/scenarios/farol_module.gd")
const Contract = preload("res://scripts/scenarios/room_contract.gd")
const MANIFEST := "res://art/scenarios/scn-production/farol-docas-v01/connectors/manifest.json"

static func assemble(sim, origin: Vector2) -> Dictionary:
	var room := Module.instantiate(sim,origin)
	return attach(room)

static func attach(room: Dictionary, used_connector_ids: Variant = null) -> Dictionary:
	if not room.ok: return room
	var origin: Vector2 = room.origin
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not manifest is Dictionary or not manifest.get("connectors") is Array: return {"ok":false,"errors":["connectors: invalid manifest"]}
	room["joins"] = []
	for authored in manifest.connectors:
		if used_connector_ids != null and not authored.legacy_id in used_connector_ids: continue
		var matches: Array = room.connectors.filter(func(c): return c.id == authored.legacy_id)
		if matches.size() != 1: return {"ok":false,"errors":["connector binding: missing or ambiguous ID"]}
		var door: Dictionary = matches[0]
		var point := origin+Vector2(authored.position[0],authored.position[1])
		var normal := Vector2(authored.normal[0],authored.normal[1])
		var neighbor := {"normal":-normal,"width":authored.width,"height":authored.height,"type":"walk","material_family":authored.material_family}
		var error := Module.connection_error(door,neighbor)
		if not error.is_empty() or point != door.position: return {"ok":false,"errors":["connector binding: "+error+" position="+str(point)]}
		var corridor: Rect2
		if normal.x != 0: corridor = Rect2(point+Vector2(-300 if normal.x<0 else 0,-100),Vector2(300,200))
		else: corridor = Rect2(point+Vector2(-100,-300),Vector2(200,300))
		room.footprint.append(corridor)
		var r: Array = authored.rect
		var texture := Contract.texture_resource(authored.textures.combined.texture)
		if texture == null or texture.get_size() != Vector2(r[2],r[3]): return {"ok":false,"errors":["threshold: native texture dimensions mismatch"]}
		room.layers.append({"id":"threshold-"+authored.side,"rect":Rect2(origin+Vector2(r[0],r[1]),Vector2(r[2],r[3])),"texture":authored.textures.combined.texture,"mode":"plate","depth":"ground"})
		room.joins.append({"side":authored.side,"position":point,"normal":normal,"corridor":corridor})
	for endpoint in room.connectors:
		if endpoint.type != "shortcut": continue
		if used_connector_ids != null and not endpoint.id in used_connector_ids: continue
		var corridor := Rect2(endpoint.position-Vector2(endpoint.width/2,0),Vector2(endpoint.width,300))
		room.footprint.append(corridor)
		room.joins.append({"side":"shortcut","position":endpoint.position,"normal":endpoint.normal,"corridor":corridor})
	# Enlarge the common floor source by exact periods (64x48), keeping room phase.
	room.layers[0].rect = Rect2(origin-Vector2(384,384),room.footprint[0].size+Vector2(768,768))
	return room
