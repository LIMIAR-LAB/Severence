extends SceneTree
const Farol = preload("res://scripts/scenarios/farol_module.gd")
func _initialize() -> void:
	var id: String = OS.get_cmdline_user_args()[0]
	var a := {"width":160,"height":0,"type":"walk","material_family":"docks-stone","normal":Vector2.RIGHT}
	var b := a.duplicate(true)
	b.normal = Vector2.LEFT
	match id:
		"missing_normal": a.erase("normal")
		"string_normal": b.normal = "left"
		"zero_normals": a.normal = Vector2.ZERO; b.normal = Vector2.ZERO
		"diagonal_normals": a.normal = Vector2(1,1); b.normal = Vector2(-1,-1)
		"zero_width": a.width = 0; b.width = 0
		"negative_width": a.width = -1; b.width = -1
		"string_width": a.width = "wide"; b.width = "wide"
		"infinite_height": a.height = INF; b.height = INF
		"string_height": a.height = "high"; b.height = "high"
		"empty_type": a.type = ""; b.type = ""
		"empty_material": a.material_family = ""; b.material_family = ""
		"missing_width": a.erase("width")
		"mismatch_width": b.width = 80
		"mismatch_height": b.height = 44
		"mismatch_type": b.type = "jump"
		"mismatch_material": b.material_family = "rail"
		"same_normal": b.normal = Vector2.RIGHT
	print("PROBE_START ",id)
	var error: String = Farol.connection_error(a,b)
	print("PROBE_RESULT ",JSON.stringify({"case":id,"accepted":error.is_empty(),"error":error}))
	quit()
