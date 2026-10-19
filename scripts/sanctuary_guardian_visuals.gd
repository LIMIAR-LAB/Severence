extends RefCounted
## Mestre Coral keeps a single coherent silhouette; idle never stretches the art.
const PATH := "res://assets/npcs/mestre_coral_guardian_v1.png"
const SIZE := Vector2(128,176)
const PERIOD := 3.6
const STAFF_PIVOT := Vector2(-43,0)
var texture: Texture2D
func _init() -> void:
	if ResourceLoader.exists(PATH): texture=load(PATH)
	elif FileAccess.file_exists(PATH): texture=ImageTexture.create_from_image(Image.load_from_file(PATH))
static func idle_transform(time: float) -> Transform2D:
	var phase := time*TAU/PERIOD
	# Weight shifts around the planted staff; the second harmonic gives a gentle nod.
	var angle := sin(phase)*0.032+sin(phase*2.0)*0.006
	return Transform2D(angle,STAFF_PIVOT-STAFF_PIVOT.rotated(angle))
func draw(ci: CanvasItem, position: Vector2, time: float) -> bool:
	if texture==null: return false
	var transform:=idle_transform(time)
	transform.origin+=position
	ci.draw_set_transform_matrix(transform)
	ci.draw_texture_rect(texture,Rect2(Vector2(-SIZE.x*0.5,-SIZE.y+3),SIZE),false)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	return true
