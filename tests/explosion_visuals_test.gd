extends SceneTree
const FX = preload("res://scripts/explosion_visuals.gd")
var failures:=0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func _init() -> void:
	var atlas:=FX.ATLAS.get_image()
	check(atlas.get_pixel(0,0).a==0.0,"Atlas has genuine transparent background")
	for i in FX.SOURCES.size():
		check(Rect2(Vector2.ZERO,atlas.get_size()).encloses(FX.SOURCES[i]),"Frame stays inside atlas: %s"%i)
	check(FX.frame_at(0.04)==0 and FX.frame_at(0.15)==2,"Brief ignition reaches peak quickly")
	check(FX.frame_at(0.6)>=5 and FX.opacity(0.8)<0.25,"Late smoke leaves threats visible")
	check(FX.opacity(1.0)==0.0,"Smoke finishes fully transparent")
	var small:=FX.destination(Vector2(200,100),65,2)
	var large:=FX.destination(Vector2(200,100),125,2)
	check(is_equal_approx(large.size.x/small.size.x,125.0/65.0),"Blast size follows existing gameplay radius")
	print("EXPLOSION_VISUALS failures=",failures)
	quit(1 if failures else 0)
