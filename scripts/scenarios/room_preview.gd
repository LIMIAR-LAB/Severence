extends "res://scripts/world_view.gd"
## Inspection renderer only. Materials and geometry are supplied by validated data.
const Contract = preload("res://scripts/scenarios/room_contract.gd")
var instance: Dictionary = {}
var profile: Dictionary = {}
var neutral := false
var layer_painter = preload("res://scripts/scenarios/layer_painter.gd").new()

func _draw() -> void:
	if instance.is_empty() or not instance.get("ok", false): return
	scenery.lights.clear()
	if light_layer: light_layer.visible = false
	modulate = Color.WHITE if neutral else Color(profile.atmosphere.tint)
	var bounds := view_rect()
	draw_rect(bounds, Color("101821"))
	for layer in instance.layers:
		if layer.depth == "ground":
			if layer.get("projected",false):
				draw_layer(layer, bounds); continue
			for footprint in instance.footprint:
				var clipped: Dictionary = layer.duplicate()
				clipped["original_rect"] = layer.rect
				clipped.rect = layer.rect.intersection(footprint)
				if clipped.rect.has_area(): draw_layer(clipped, bounds)
	var drawables := []
	for obstacle in instance.obstacles:
		if not obstacle.get("baked", false): drawables.append({"kind":"obstacle","data":obstacle,"y":obstacle.rect.end.y})
	for actor in sim.actors:
		if actor.active:
			drawables.append({"kind":"actor","data":actor,"y":actor.p.y-sim.height_at(actor.p)})
	if sim.mech.deployed: drawables.append({"kind":"mech","data":sim.mech,"y":sim.mech.p.y-sim.height_at(sim.mech.p)})
	for enemy in sim.enemies: drawables.append({"kind":"enemy","data":enemy,"y":enemy.p.y-sim.height_at(enemy.p)})
	for layer in instance.layers:
		if layer.depth == "foreground": drawables.append({"kind":"layer","data":layer,"y":layer.get("sort_y",layer.rect.end.y)})
	drawables.sort_custom(func(a,b): return a.y < b.y)
	for item in drawables:
		visual_scale = sim.ACTOR_VISUAL_SCALE if item.kind in ["actor","mech","enemy"] else 1.0
		# Scale the sprite around its projected feet; height must not be multiplied by visual scale.
		visual_origin = item.data.p-Vector2(0,sim.height_at(item.data.p)) if item.kind in ["actor","mech","enemy"] else Vector2.ZERO
		visual_transform(Vector2.ZERO)
		match item.kind:
			"actor": draw_actor(item.data)
			"mech": draw_mech(item.data)
			"enemy": draw_enemy(item.data)
			"obstacle": draw_obstacle(item.data.rect,item.data.kind)
			"layer": draw_layer(item.data,bounds)
	visual_scale = 1.0; visual_origin = Vector2.ZERO; visual_transform(Vector2.ZERO)
	draw_occlusion_markers(drawables)

func draw_occlusion_markers(drawables: Array) -> void:
	# Occluded actors retain a colored foot/identity marker without fading the whole building.
	for actor in drawables:
		if actor.kind not in ["actor","mech","enemy"]: continue
		var foot: Vector2 = actor.data.p-Vector2(0,sim.height_at(actor.data.p))
		var occluded := false
		for cover in drawables:
			if cover.kind not in ["obstacle","layer"] or cover.y <= actor.y: continue
			var rect: Rect2 = cover.data.rect
			if cover.kind == "obstacle": rect = Rect2(rect.position-Vector2(0,96),rect.size+Vector2(0,96))
			if rect.has_point(foot-Vector2(0,24)): occluded = true; break
		if occluded:
			var color := Color("ff7c76") if actor.kind == "enemy" else Color("57edf4")
			draw_circle(foot,14,color,false,2)
			draw_line(foot,foot-Vector2(0,44),color,2)
			draw_circle(foot-Vector2(0,48),6,color,false,2)
			draw_string(ThemeDB.fallback_font,foot+Vector2(18,-24),str(actor.data.get("kind",actor.kind)),HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

func draw_layer(layer: Dictionary, bounds: Rect2) -> void:
	layer_painter.draw_layer(self,layer,bounds,profile)

func move_actor(delta: Vector2) -> bool:
	var point: Vector2 = sim.actors[0].p + delta
	if not Contract.clear_at(instance, point, 11): return false
	sim.actors[0].p = point; queue_redraw(); return true
