extends SceneTree
const Dog=preload("res://scripts/dog_visuals.gd")
func _init() -> void:
	var failures:=0
	var maximum_jump:=0.0
	for i in 120:
		var t:=float(i)/30.0
		for walking in [false,true]:
			for y in Dog.ROWS:
				for x in Dog.COLS:
					var a:=Vector2(float(x)/Dog.COLS,float(y)/Dog.ROWS)
					var b:=a+Vector2(1.0/Dog.COLS,0)
					var c:=a+Vector2(0,1.0/Dog.ROWS)
					var d:=b+Vector2(0,1.0/Dog.ROWS)
					var pa:=a*Dog.SIZE+Dog.motion(a,t,walking)
					var pb:=b*Dog.SIZE+Dog.motion(b,t,walking)
					var pc:=c*Dog.SIZE+Dog.motion(c,t,walking)
					var pd:=d*Dog.SIZE+Dog.motion(d,t,walking)
					if (pb-pa).cross(pc-pa)<=0 or (pd-pb).cross(pc-pb)<=0: failures+=1
					maximum_jump=maxf(maximum_jump,Dog.motion(a,t,walking).distance_to(Dog.motion(a,t+1.0/60.0,walking)))
	if maximum_jump>2.0: failures+=1
	print("DOG_MOTION failures=",failures," maximum_frame_travel=",maximum_jump)
	quit(0 if failures==0 else 1)
