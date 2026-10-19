extends RefCounted
## Physical world objects replacing the early geometric stand-ins.
const PATHS := {
	"acolyte":"res://assets/npcs/sanctuary_acolyte_v1.png",
	"fuel":"res://assets/pickups/fuel_can_v1.png",
	"battery":"res://assets/pickups/battery_cell_v1.png",
	"bomb":"res://assets/pickups/mortar_bomb_v1.png",
}
var textures := {}
func _init() -> void:
	for key in PATHS:
		var path: String=PATHS[key]
		textures[key]=load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
func follower(ci: CanvasItem, foot: Vector2, time: float, index: int) -> void:
	var size:=Vector2(62,86)*(0.96+0.025*(index%3))
	var angle:=sin(time*1.65+index*1.7)*0.024
	var transform:=Transform2D(angle,foot)
	if index>2: transform.x=-transform.x
	ci.draw_set_transform_matrix(transform)
	var tint:=Color.WHITE if index%2==0 else Color(0.92,0.96,1.0)
	ci.draw_texture_rect(textures.acolyte,Rect2(Vector2(-size.x*0.5,-size.y+2),size),false,tint)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
