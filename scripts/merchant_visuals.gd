extends RefCounted
## Rigid idle: preserve the approved artwork without stretching its anatomy.
const PATH := "res://assets/npcs/merchant_hunchback_v1.png"
const SIZE := Vector2(200,245)
const PERIOD := 3.2
var texture: Texture2D

func _init() -> void:
	if ResourceLoader.exists(PATH): texture=load(PATH)
	elif FileAccess.file_exists(PATH): texture=ImageTexture.create_from_image(Image.load_from_file(PATH))

static func idle_transform(time: float) -> Transform2D:
	var phase := TAU*time/PERIOD
	# Gentle weight shift around the feet. No scale, shear or local deformation.
	return Transform2D(sin(phase)*0.018+sin(phase*2.0)*0.004,Vector2(0,-0.6*(1.0-cos(phase))))

static func motion(point: Vector2, time: float) -> Vector2:
	var local := point*SIZE-Vector2(SIZE.x*0.5,SIZE.y-12)
	return idle_transform(time)*local-local

func draw(ci: CanvasItem, position: Vector2, time: float) -> bool:
	if texture==null: return false
	var transform := idle_transform(time)
	transform.origin+=position
	ci.draw_set_transform_matrix(transform)
	ci.draw_texture_rect(texture,Rect2(-Vector2(SIZE.x*0.5,SIZE.y-12),SIZE),false)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	return true
