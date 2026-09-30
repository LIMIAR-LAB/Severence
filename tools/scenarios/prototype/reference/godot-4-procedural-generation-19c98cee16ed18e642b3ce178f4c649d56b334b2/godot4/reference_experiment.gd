extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var rng = RandomNumberGenerator.new()
	rng.seed = 4101
	var rooms = []
	var data = {}
	var room_records = []
	var edges = []
	var basic = load("res://basic_dungeon/03_bonus/generator.gd")
	for i in range(15):
		var room = basic._get_random_room(Vector2i(100, 80), Vector2i(10, 14), rng)
		if basic._intersects(rooms, room):
			continue
		basic._add_room(data, rooms, room)
		var idx = rooms.size() - 1
		room_records.append({"id": idx, "rect": [room.rect.position.x, room.rect.position.y, room.rect.size.x, room.rect.size.y], "organic": room is BasicDungeonRoomOrganic})
		if rooms.size() > 1:
			basic._add_connection(rng, data, rooms[-2], room)
			edges.append([idx - 1, idx])
	var result = {"schema": "reference-observation-v0", "seed": 4101, "warning": "Organic room internal RNG randomizes independently; not deterministic", "rooms": room_records, "edges": edges, "cells": data.size()}
	FileAccess.open("res://../../basic-observation.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("BASIC_OBSERVATION ", JSON.stringify(result))
	var points = [Vector2(0,0), Vector2(40,0), Vector2(0,40), Vector2(80,20), Vector2(40,80)]
	var graph = MSTDungeonUtils.mst(points.duplicate())
	var mst_rooms = []
	var mst_edges = []
	for id in graph.get_point_ids():
		var p = graph.get_point_position(id)
		mst_rooms.append({"id": id, "position": [p.x,p.y]})
		for other in graph.get_point_connections(id):
			if id < other: mst_edges.append([id,other])
	var mst_result = {"schema":"reference-observation-v0", "mode":"original_mst_function_fixed_points_no_physics", "rooms":mst_rooms, "edges":mst_edges}
	FileAccess.open("res://../../mst-fixed-points.json", FileAccess.WRITE).store_string(JSON.stringify(mst_result,"\t"))
	print("MST_FIXED_POINTS ",JSON.stringify(mst_result))
	var scene = load("res://mst_dungeon/mst_dungeon.tscn").instantiate()
	root.add_child(scene)
	await create_timer(10.0).timeout
	var full = {"schema":"reference-observation-v0", "mode":"original_unmodified_mst_scene", "elapsed_seconds":10, "sleeping_rooms":scene._sleeping_rooms,"max_rooms":scene.max_rooms,"has_graph":scene._path != null,"cells":scene._data.size()}
	if scene._path != null:
		full["graph_points"] = scene._path.get_point_count()
		full["rooms"] = []
		full["edges"] = []
		for id in scene._path.get_point_ids():
			var p = scene._path.get_point_position(id)
			full["rooms"].append({"id":id,"position":[p.x,p.y]})
			for other in scene._path.get_point_connections(id):
				if id < other: full["edges"].append([id,other])
	FileAccess.open("res://../../mst-scene-observation.json",FileAccess.WRITE).store_string(JSON.stringify(full,"\t"))
	print("MST_SCENE ",JSON.stringify(full))
	scene.queue_free()
	await process_frame
	quit()

