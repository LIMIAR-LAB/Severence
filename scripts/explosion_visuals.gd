extends RefCounted
## Shared, preloaded animation. Rendering only: does not own timers or damage.
const ATLAS := preload("res://assets/effects/explosion_v01/atlas.png")
# Measured cells preserve the generated sparks beyond the nominal grid boundary.
const SOURCES := [
	Rect2(0,0,435,467), Rect2(435,0,435,467),
	Rect2(870,0,464,467), Rect2(1334,0,440,467),
	Rect2(0,467,443,420), Rect2(443,467,444,420),
	Rect2(887,467,443,420), Rect2(1330,467,444,420)]
const ANCHORS := [Vector2(222,330),Vector2(230,330),Vector2(222,330),Vector2(220,330),
	Vector2(222,350),Vector2(222,350),Vector2(222,350),Vector2(222,350)]
const FRAME_ENDS := [0.055,0.14,0.28,0.43,0.57,0.70,0.85,1.0]

static func frame_at(progress: float) -> int:
	for i in FRAME_ENDS.size():
		if progress < FRAME_ENDS[i]: return i
	return 7

static func opacity(progress: float) -> float:
	return 1.0 - smoothstep(0.36,1.0,progress)

static func destination(position: Vector2, radius: float, frame: int) -> Rect2:
	var scale_factor := maxf(radius,1.0)*2.2/444.0
	return Rect2(position-ANCHORS[frame]*scale_factor,SOURCES[frame].size*scale_factor)

static func draw(ci: CanvasItem, fx: Dictionary, lights: Array) -> void:
	var progress := clampf(1.0-float(fx.life)/maxf(0.01,float(fx.get("max",fx.life))),0.0,1.0)
	if progress >= 1.0: return
	var frame := frame_at(progress)
	var radius: float = fx.get("r",100.0)
	ci.draw_texture_rect_region(ATLAS,destination(fx.p,radius,frame),SOURCES[frame],Color(1,1,1,opacity(progress)))
	# Light exists only during ignition/fire, never throughout the smoke tail.
	if progress < 0.36:
		lights.append({"p":fx.p,"kind":"blast","r":radius*1.45*(1.0-progress/0.36)})
