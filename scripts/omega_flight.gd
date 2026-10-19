extends RefCounted
## Presentation only: never writes to actors or changes the jump/collision state.
const CELL := 112.0
const DRAW_SIZE := 124.0
const METADATA := "res://assets/characters/marty/omega/rounded_v4/flight.json"
var anchors: Array = []
var states: Dictionary = {}

func load_assets() -> void:
	anchors = JSON.parse_string(FileAccess.get_file_as_string(METADATA)).anchors

static func eligible(a: Dictionary) -> bool:
	return a.get("armor", false) and a.get("armor_type", "omega") == "omega" and not (
		a.get("dead", false) or a.get("hidden", false) or a.get("mech", false)
		or a.get("bike", false) or a.get("fused", false) or a.get("transform", 0.0) > 0
		or a.get("roll_visual", a.get("dodge", 0.0)) > 0 or a.get("slash", 0.0) > 0
		or a.get("hurt", 0.0) > 0 or a.get("fire_flash", 0.0) > 0 or a.get("beam_time", 0.0) > 0)

static func requested(a: Dictionary) -> bool:
	return eligible(a) and (a.get("move", Vector2.ZERO).length() > 0.1 or a.get("jump", 0.0) > 0)

func sample(a: Dictionary, time: float) -> Dictionary:
	var id: int = a.get("id", 0)
	var wants := requested(a)
	var previous: Dictionary = states.get(id, {"time":time, "blend":0.0})
	var dt := clampf(time - float(previous.time), 0.0, 0.1)
	var blend := move_toward(float(previous.blend), 1.0 if wants else 0.0, dt / 0.14)
	if not eligible(a) or time < float(previous.time): blend = 0.0
	var result := {"time":time, "blend":blend, "active":blend > 0.001,
		"frame":0, "lift":(8.0 + sin(time * 6.0) * 0.6) * smoothstep(0.0, 1.0, blend)}
	states[id] = result
	return result

func emitters(row: int, frame: int) -> Array:
	var result: Array = []
	var poses: Array = anchors[posmod(row, 8)]
	for point in poses[posmod(frame, poses.size())]:
		result.append(Vector2(point[0], point[1]) * DRAW_SIZE / CELL - Vector2(DRAW_SIZE * 0.5, DRAW_SIZE - 2.0))
	return result

func draw_exhaust(canvas: Node2D, foot: Vector2, row: int, frame: int, time: float, strength: float, alpha: float, front: bool = false) -> void:
	var points := emitters(row, frame)
	for i in range(4):
		# Near palms sit in front of the cape; far palms remain occluded in profile.
		var near_palm := i < 2 and (row in [0,1,4,7] or (i == 1 and row in [2,3]) or (i == 0 and row in [5,6]))
		if front != near_palm: continue
		var origin: Vector2 = foot + points[i]
		var pulse := 0.85 + sin(time * 37.0 + i * 1.7) * 0.12
		var width := (3.0 if i < 2 else 3.5) * strength
		var length := (23.0 if i < 2 else 27.0) * strength * pulse
		# All four nozzles point toward the ground, independent of aim direction.
		var tip := origin + Vector2(sin(time * 29.0 + i) * 1.2, length)
		canvas.draw_colored_polygon(PackedVector2Array([origin + Vector2(-width-1,0),origin + Vector2(width+1,0),tip + Vector2(0,5)]),Color(0.04,0.45,1.0,0.65*alpha))
		canvas.draw_colored_polygon(PackedVector2Array([origin + Vector2(-width,0),origin + Vector2(width,0),tip]),Color(0.15,0.93,1.0,0.95*alpha))
		canvas.draw_colored_polygon(PackedVector2Array([origin + Vector2(-width*0.45,0),origin + Vector2(width*0.45,0),origin + Vector2(0,length*0.6)]),Color(0.92,1.0,1.0,alpha))
