extends SceneTree
const Catalog = preload("res://scripts/scenarios/module_catalog.gd")
const Farol = preload("res://scripts/scenarios/farol_module.gd")
func _initialize() -> void:
	if not "--publish-farol" in OS.get_cmdline_user_args():
		print("No files written. Publication requires -- --publish-farol after pilot validation.")
		quit(1); return
	var sim := Expedition.new()
	sim.start_run(1941)
	var data := Farol.template(sim)
	data["publication"] = "published"
	var result := Catalog.publish(data)
	print(JSON.stringify(result))
	quit(0 if result.ok else 1)
