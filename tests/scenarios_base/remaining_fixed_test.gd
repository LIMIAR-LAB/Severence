extends SceneTree
const Fixed=preload("res://scripts/scenarios/remaining_fixed.gd")
var failures:=0
var checks:=0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func _init() -> void:
	var hash_before:=FileAccess.get_sha256("user://expedition.save")
	var sim:=Expedition.new(); sim.coop="solo"; sim.start_run(42); sim.open_secret()
	for room in sim.rooms: room.locked=false
	sim.refresh_gate_blocks()
	for gate in sim.tentacle_gates: gate.sealed=true
	check(Fixed.active(sim),"new fixed rooms installed")
	for id in Fixed.DATA:
		check(ResourceLoader.exists(Fixed.ROOT+id+".png"),id+" painting exists")
		check(id in sim.layout_manifest.fixed_rooms,id+" recorded in snapshot")
		var room: Rect2=sim.room_by_id(id).r
		check(room.encloses(Fixed.image_area(sim,id)),id+" painting stays within real floor")
		for source: Rect2 in Fixed.DATA[id].blocks:
			check(not sim.clear_at(Fixed.source_rect(sim,id,source).get_center(),11),id+" painted object collides")
	for door in sim.doors:
		if not Fixed.DATA.has(door.room): continue
		var out: Vector2={"top":Vector2.UP,"bottom":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[door.side]
		var first: Vector2=door.r.get_center()+out*60
		var last: Vector2=door.r.get_center()-out*90
		for radius in [11.0,23.0]:
			for reverse in [false,true]:
				var p: Vector2=last if reverse else first
				var target: Vector2=first if reverse else last
				for step in 40: p=sim.move_body(p,(target-p).limit_length(4),radius)
				check(p.distance_to(target)<0.1,"door %s/%s radius%s -> %s"%[door.room,door.side,radius,p])
	for enemy in sim.enemies:
		var room: Dictionary=sim.room_at(enemy.p)
		if not room.is_empty() and Fixed.DATA.has(room.id): check(sim.clear_at(enemy.p,11),"enemy spawned clear "+room.id)
	for chest in sim.chests: check(sim.clear_at(chest.p,11),"chest clear "+str(chest.p))
	for key in ["shop","side","ammo_center","warden"]: check(sim.clear_at(sim.run_points[key],11),"interaction reachable "+key)
	var restored:=Expedition.new(); restored.apply_snapshot(sim.snapshot().duplicate(true))
	check(Fixed.active(restored) and restored.obstacles==sim.obstacles,"snapshot keeps authored geometry")
	var legacy: Dictionary=sim.snapshot().duplicate(true); legacy.layout_manifest.erase("remaining_fixed_version")
	restored.apply_snapshot(legacy); check(not Fixed.active(restored),"legacy save not silently repainted")
	check(FileAccess.get_sha256("user://expedition.save")==hash_before,"user save unchanged")
	print("REMAINING_FIXED checks=",checks," failures=",failures); quit(1 if failures else 0)
