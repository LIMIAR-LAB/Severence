extends RefCounted

const PATH := "res://assets/vehicles/moto_temporal_blue.png"
const RIDING_PATH := "res://assets/vehicles/moto_temporal_omega_riding.png"
const SIZE := Vector2(180, 90)
var sprite: Texture2D
var region := Rect2()
var riding_sprite: Texture2D
var riding_region := Rect2()

func _init() -> void:
	if ResourceLoader.exists(PATH):
		sprite = load(PATH)
		# Ignore transparent generation padding without modifying the source image.
		region = Rect2(sprite.get_image().get_used_rect())
	if ResourceLoader.exists(RIDING_PATH):
		riding_sprite = load(RIDING_PATH)
		riding_region = Rect2(riding_sprite.get_image().get_used_rect())

func draw(ci: CanvasItem, p: Vector2, facing: Vector2) -> bool:
	if sprite == null or region.size == Vector2.ZERO: return false
	var mirror := facing.x < -0.1
	ci.visual_transform(p, 0.0, Vector2(-1.0 if mirror else 1.0, 1.0))
	ci.draw_texture_rect_region(sprite, Rect2(Vector2(-SIZE.x/2, 6-SIZE.y), SIZE), region)
	ci.visual_transform(Vector2.ZERO)
	return true

func draw_riding(ci: CanvasItem, p: Vector2, facing: Vector2, tint := Color.WHITE) -> bool:
	if riding_sprite == null or riding_region.size == Vector2.ZERO: return false
	# Same wheel width and ground anchor as the empty motorcycle, with room for seated rider.
	var size := Vector2(SIZE.x, SIZE.x * riding_region.size.y / riding_region.size.x)
	ci.visual_transform(p, 0.0, Vector2(-1.0 if facing.x < -0.1 else 1.0, 1.0))
	ci.draw_texture_rect_region(riding_sprite, Rect2(Vector2(-size.x * 0.5, 6.0 - size.y), size), riding_region, tint)
	ci.visual_transform(Vector2.ZERO)
	return true
