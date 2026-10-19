extends SceneTree
func _init() -> void:
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(42)
	var result:=[]
	for id in ["market","shop","generator","ammo","rails","stairs","drydock","cellar","secret","antessala"]:
		var room: Dictionary=sim.room_by_id(id)
		var doors:=[]
		for door in sim.doors:
			if door.room==id: doors.append({"side":door.side,"rect":str(door.r)})
		result.append({"id":id,"room":str(room.r),"extra":str(room.get("extra",[])),"doors":doors})
	DirAccess.make_dir_recursive_absolute("res://art/scenarios/scn-production/remaining-fixed-v01")
	FileAccess.open("res://art/scenarios/scn-production/remaining-fixed-v01/geometry.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print(JSON.stringify(result)); quit()
