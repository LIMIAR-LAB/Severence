extends SceneTree
const Generator = preload("res://tools/scenarios/prototype/layout_generator.gd")
const Docks = preload("res://scripts/scenarios/procedural_docks.gd")
const Seeds = preload("res://scripts/scenarios/seed_manifest.gd")
func _initialize() -> void:
	var sim := Expedition.new(); sim.start_run(1941)
	var source: Dictionary = Docks.inputs(sim)
	var cases: Array = []; var unique: Dictionary = {}; var failed: Array = []
	for seed_value in range(2,32):
		var started := Time.get_ticks_msec()
		var result := Generator.generate_layout(seed_value,source.rooms,source.edges)
		var row := {"seed":seed_value,"ok":result.ok,"elapsed_ms":Time.get_ticks_msec()-started,"attempts":result.get("manifest",{}).get("attempts",result.get("attempts",0)),"errors":result.errors}
		if result.ok:
			row["hash"]=Seeds.canonical(result).sha256_text()
			unique[Seeds.canonical(result.origins)]=true
		else: failed.append(seed_value)
		cases.append(row); print(JSON.stringify(row))
	var report := {"cases":cases,"failed_seeds":failed,"unique_origins":unique.size(),"max_attempts":Generator.MAX_ATTEMPTS}
	var destination := "res://_bmad-output/implementation-artifacts/cenarios-gerador/layout-sample-2-31.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): destination=arg.trim_prefix("--report=")
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit(0 if failed.is_empty() else 1)
