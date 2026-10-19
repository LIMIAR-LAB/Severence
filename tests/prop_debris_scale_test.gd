extends SceneTree
const Scenery = preload("res://scripts/dock_scenery.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _init() -> void:
	var art := Scenery.new()
	for pair in [["crate", "debris_crate"], ["barrel", "debris_barrel"], ["sandbags", "debris_sandbags"]]:
		var intact: Vector2 = art.prop_size(pair[0])
		var debris: Vector2 = art.debris_size({"kind": pair[1], "small": true})
		check(debris.x <= intact.x and debris.y <= intact.y, "%s destruction never enlarges the prop" % pair[0])
		check(art.debris_size({"kind": pair[1]}) == art.prop_size(pair[1]), "authored large debris preserves its scale")
	print("PROP_DEBRIS_SCALE_TEST failures=", failures)
	quit(1 if failures else 0)
