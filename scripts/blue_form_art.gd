extends RefCounted

# The transformation uses Marty's exact pixel silhouettes, pivots and eight-way
# action sheets. The canvas shader remaps only draws carrying this marker.
const PALETTE_MARKER := Color(0.125, 0.25, 0.875, 1.0)
const LIGHT := Color("83d6dc")

static func draw_pose(view, a: Dictionary, action: String, direction: Vector2, frame: int, foot: Vector2, tint: Color) -> void:
	if a.transform <= 0 and action in ["run", "shoot"]:
		view.draw_carry_pose(view.marty_padrao_actions.idle, view.marty_padrao_actions[action], 96, 96, 94, 66, foot, direction, frame, action == "run", tint)
	else:
		view.draw_marty_padrao_frame(action, direction, frame, foot, tint)

static func draw_body(view, a: Dictionary, foot: Vector2) -> void:
	var walking: bool = a.move.length() > 0.1
	var firing: bool = a.get("fire_flash", 0.0) > 0
	var action: String = "defeat" if a.dead else view.marty_padrao_action(a, walking, firing)
	var direction: Vector2 = a.dash_dir if action == "evade" else a.aim
	var frame: int = view.MARTY_PADRAO_FRAMES.defeat - 1 if a.dead else view.marty_padrao_frame(a, action, 0.35)
	var progress: float = 1.0 - a.get("transform", 0.0) / view.sim.TRANSFORM_TIME
	var tint := PALETTE_MARKER
	if a.hurt > 0 and int(a.hurt * 20) % 2 == 0: tint.a = 0.5
	if a.dead:
		view.draw_marty_padrao_frame(action, direction, frame, foot, tint)
		view.text_at(foot + Vector2(-35, -25), "E • REANIMAR", Color("f77c89"), 12)
		return
	# One-source-pixel edge light, no blur or photographic halo.
	for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:
		draw_pose(view, a, action, direction, frame, foot + offset, Color(0.3, 0.85, 1.0, 0.2))
	draw_pose(view, a, action, direction, frame, foot, tint)
	if progress < 1.0:
		draw_pose(view, a, action, direction, frame, foot, Color(1, 1, 1, 1.0 - smoothstep(0.1, 0.8, progress)))
	# Sparse square sparks use the same pixel scale as the sprite.
	for n in range(4):
		var phase := fposmod(view.sim.tick_time * 0.6 + n * 0.25, 1.0)
		var offset := Vector2(roundf(sin(n * 2.4 + phase) * 22), roundf(-phase * 68))
		view.draw_rect(Rect2(foot + offset, Vector2(2, 2)), Color(0.5, 0.9, 0.9, sin(phase * PI) * 0.7))
	view.text_at(foot + Vector2(-25, -86), "MARTY" if a.id == 0 else "ECHO", LIGHT, 11)

static func draw_transform(view, fx: Dictionary, owner: Dictionary) -> void:
	var p: Vector2 = owner.p - Vector2(0, view.sim.height_at(owner.p))
	var progress: float = 1.0 - fx.life / fx.max
	var pulse := sin(progress * PI)
	view.draw_rect(Rect2(p - Vector2(23, 110), Vector2(46, 110)), Color(0.1, 0.4, 0.8, pulse * 0.12))
	view.draw_rect(Rect2(p - Vector2(7, 110), Vector2(14, 110)), Color(0.6, 0.95, 1, pulse * 0.25))
	view.visual_transform(p, 0, Vector2(1, 0.4))
	view.draw_arc(Vector2.ZERO, 16 + progress * 64, 0, TAU, 16, Color(0.25, 0.8, 1, 1 - progress), 2, false)
	view.visual_transform(Vector2.ZERO)

static func draw_claw(view, fx: Dictionary) -> void:
	var p: Vector2 = fx.p - Vector2(0, view.sim.height_at(fx.p))
	var progress: float = clampf(1.0 - fx.life / fx.max, 0, 1)
	# Start emerging on the damage frame; retract into the same ground fissure.
	var rise := lerpf(0.15, 1.0, ease(clampf(progress / 0.24, 0, 1), 0.35)) * (1.0 - smoothstep(0.60, 1.0, progress))
	var alpha := 1.0 - smoothstep(0.55, 1.0, progress)
	view.visual_transform(p, 0, Vector2(1, 0.35))
	view.draw_circle(Vector2.ZERO, 27, Color(0.02, 0.06, 0.10, 0.85 * alpha))
	view.draw_arc(Vector2.ZERO, 28 + progress * 10, 0, TAU, 12, Color(0.15, 0.4, 0.55, alpha * 0.7), 2, false)
	view.draw_arc(Vector2.ZERO, 25, 0, TAU, 12, Color(0.5, 0.82, 0.85, alpha), 1, false)
	view.visual_transform(p, 0, Vector2.ONE * 0.72)
	# Three hooked, sharpened fingers and a shared palm rise beneath the target.
	var palm := PackedVector2Array([Vector2(-30, 2), Vector2(-27, -24 * rise), Vector2(0, -36 * rise), Vector2(28, -24 * rise), Vector2(30, 2)])
	view.draw_colored_polygon(palm, Color(0.06, 0.18, 0.29, alpha))
	for n in range(3):
		var x := (n - 1) * 22.0
		var height := (106.0 if n == 1 else 84.0) * rise
		var mirror := -1.0 if n == 2 else 1.0
		var points := PackedVector2Array([Vector2(x - 9 * mirror, 0), Vector2(x - 12 * mirror, -height * 0.48), Vector2(x - 5 * mirror, -height * 0.84), Vector2(x + 15 * mirror, -height), Vector2(x + 5 * mirror, -height * 0.64), Vector2(x + 9 * mirror, 0)])
		view.draw_colored_polygon(points, Color(0.10, 0.34, 0.5, alpha))
		var outline := points.duplicate(); outline.append(points[0])
		view.draw_polyline(outline, Color(0.02, 0.06, 0.12, alpha), 3, false)
		view.draw_polyline(points.slice(1, 5), Color(0.57, 0.87, 0.86, alpha), 2, false)
	for n in range(8):
		var shard := Vector2(cos(n * 2.4) * (22 + progress * 42), -sin(progress * PI) * (18 + n * 5))
		view.draw_rect(Rect2(shard.round(), Vector2(3, 3)), Color(0.3, 0.6, 0.7, alpha))
	view.visual_transform(Vector2.ZERO)
