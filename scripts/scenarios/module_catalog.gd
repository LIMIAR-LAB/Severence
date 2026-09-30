extends RefCounted
## Read-only runtime loader. Publication requires the explicit authoring CLI flag.
const Rooms = preload("res://scripts/scenarios/room_contract.gd")
const ID := "docks.farol.pilot"
const INDEX_PATH := "res://scripts/scenarios/modules.json"
const TEMPLATE_PATH := "res://scripts/scenarios/templates/farol.json"
const SCHEMA := 1
const MAX_BYTES := 4 * 1024 * 1024

static func _fail(message: String) -> Dictionary:
	return {"ok":false,"errors":[message]}

static func _walk(value: Variant, encode: bool, errors: Array[String], depth: int = 0) -> Variant:
	if depth > 64:
		errors.append("codec: nesting limit"); return null
	if encode and value is Vector2:
		if not value.is_finite(): errors.append("codec: non-finite Vector2"); return null
		return {"$type":"Vector2","values":[value.x,value.y]}
	if encode and value is int:
		return {"$type":"int","value":str(value)}
	if encode and value is Rect2:
		if not value.position.is_finite() or not value.size.is_finite(): errors.append("codec: non-finite Rect2"); return null
		return {"$type":"Rect2","values":[value.position.x,value.position.y,value.size.x,value.size.y]}
	if value is Dictionary:
		if value.has("$type"):
			if encode: errors.append("codec: reserved $type key"); return null
			if value["$type"] == "int":
				if value.size() != 2 or not value.get("value") is String or not value.value.is_valid_int() or str(value.value.to_int()) != value.value:
					errors.append("codec: invalid integer"); return null
				return value.value.to_int()
			if value.size() != 2 or not value.get("values") is Array or value.get("$type") not in ["Vector2","Rect2"]:
				errors.append("codec: invalid tagged value"); return null
			var numbers: Array = value.values
			if numbers.size() != (2 if value["$type"] == "Vector2" else 4): errors.append("codec: invalid coordinate count"); return null
			for number in numbers:
				if typeof(number) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(number)): errors.append("codec: invalid coordinate"); return null
			if value["$type"] == "Vector2":
				var vector := Vector2(numbers[0],numbers[1])
				if not vector.is_finite(): errors.append("codec: Vector2 overflow"); return null
				return vector
			var rect := Rect2(numbers[0],numbers[1],numbers[2],numbers[3])
			if not rect.position.is_finite() or not rect.size.is_finite(): errors.append("codec: Rect2 overflow"); return null
			return rect
		var output: Dictionary = {}
		for key in value:
			if not key is String: errors.append("codec: dictionary keys must be strings"); return null
			output[key] = _walk(value[key],encode,errors,depth+1)
		return output
	if value is Array:
		var output: Array = []
		for item in value: output.append(_walk(item,encode,errors,depth+1))
		return output
	if typeof(value) in [TYPE_NIL,TYPE_BOOL,TYPE_STRING]: return value
	if typeof(value) in [TYPE_INT,TYPE_FLOAT]:
		if not is_finite(float(value)) or absf(float(value)) > 9007199254740991.0: errors.append("codec: number outside safe JSON range"); return null
		return value
	errors.append("codec: unsupported type " + type_string(typeof(value)))
	return null

static func serialize(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var encoded: Variant = _walk(data,true,errors)
	if not errors.is_empty(): return {"ok":false,"errors":errors}
	var text: String = JSON.stringify(encoded,"\t",true,true)
	if text.to_utf8_buffer().size() > MAX_BYTES: return _fail("codec: size limit")
	return {"ok":true,"text":text}

static func deserialize(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES: return _fail("codec: size limit")
	var parser := JSON.new()
	if parser.parse(text) != OK: return _fail("codec: invalid JSON at line " + str(parser.get_error_line()))
	var errors: Array[String] = []
	var decoded: Variant = _walk(parser.data,false,errors)
	if not errors.is_empty(): return {"ok":false,"errors":errors}
	if not decoded is Dictionary: return _fail("codec: root must be object")
	return {"ok":true,"data":decoded}

static func validate_template(data: Dictionary) -> Array[String]:
	var errors: Array[String] = Rooms.validate(data)
	if not errors.is_empty(): return errors
	for layer in data.layers:
		if layer.has("sort_y"):
			if typeof(layer.sort_y) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(layer.sort_y)):
				errors.append("catalog: sort_y must be a finite number")
	if data.get("template_id") != ID: errors.append("catalog: unsupported template ID")
	if data.get("version") != 1: errors.append("catalog: unsupported version")
	if data.get("repeat_limit") != 1: errors.append("catalog: repeat_limit must be 1")
	if data.get("neighbor_rules") != {"material_family":"docks-stone","height":0}: errors.append("catalog: invalid neighbor_rules")
	return errors

static func read_template(text: String) -> Dictionary:
	var result := deserialize(text)
	if not result.ok: return result
	var errors := validate_template(result.data)
	if not errors.is_empty(): return {"ok":false,"errors":errors}
	return result

static func template(id: String) -> Dictionary:
	if id != ID: return _fail("catalog: unknown ID " + id)
	if not FileAccess.file_exists(INDEX_PATH): return _fail("catalog: not published")
	var index := deserialize(FileAccess.get_file_as_string(INDEX_PATH))
	if not index.ok: return index
	var document: Dictionary = index.data
	if document.get("schema") != SCHEMA or not document.get("modules") is Array or document.modules.size() != 1: return _fail("catalog: invalid index")
	var entry: Variant = document.modules[0]
	if not entry is Dictionary: return _fail("catalog: invalid entry")
	if entry.get("id") != ID or entry.get("version") != 1 or entry.get("path") != TEMPLATE_PATH: return _fail("catalog: invalid ID/version/path")
	if not FileAccess.file_exists(TEMPLATE_PATH): return _fail("catalog: template missing")
	var text := FileAccess.get_file_as_string(TEMPLATE_PATH)
	if entry.get("sha256") != text.sha256_text(): return _fail("catalog: template checksum mismatch")
	var result := read_template(text)
	if not result.ok: return result
	if entry.get("repeat_limit") != result.data.repeat_limit or entry.get("neighbor_rules") != result.data.neighbor_rules: return _fail("catalog: rule metadata mismatch")
	return result.data

static func instantiate(id: String, origin: Vector2) -> Dictionary:
	var data := template(id)
	if data.get("ok") == false: return data
	return Rooms.instantiate(data,id+"@"+str(origin),origin)

static func publish(data: Dictionary) -> Dictionary:
	if not "--publish-farol" in OS.get_cmdline_user_args(): return _fail("publication: authoring flag --publish-farol required")
	var encoded := serialize(data)
	if not encoded.ok: return encoded
	var checked := read_template(encoded.text)
	if not checked.ok: return checked
	var document := {"schema":SCHEMA,"modules":[{"id":ID,"version":1,"path":TEMPLATE_PATH,"sha256":encoded.text.sha256_text(),"repeat_limit":data.repeat_limit,"neighbor_rules":data.neighbor_rules.duplicate(true)}]}
	var index := serialize(document)
	if not index.ok: return index
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEMPLATE_PATH.get_base_dir()))
	if mkdir_error != OK: return _fail("publication: cannot create template directory")
	for pair in [[TEMPLATE_PATH,encoded.text],[INDEX_PATH,index.text]]:
		var file := FileAccess.open(pair[0]+".pending",FileAccess.WRITE)
		if file == null: return _fail("publication: cannot stage " + pair[0])
		file.store_string(pair[1]); file.flush()
		var error := file.get_error()
		file.close()
		if error != OK: return _fail("publication: cannot write " + pair[0])
	# Commit index last. Checksum prevents loading an interrupted mixed revision.
	for path in [TEMPLATE_PATH,INDEX_PATH]:
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".pending"),ProjectSettings.globalize_path(path)) != OK:
			return _fail("publication: rename failed; incomplete publication, rerun tool: " + path)
	var loaded := template(ID)
	if loaded.get("ok") == false: return loaded
	return {"ok":true,"id":ID,"version":1,"path":TEMPLATE_PATH,"sha256":encoded.text.sha256_text()}
