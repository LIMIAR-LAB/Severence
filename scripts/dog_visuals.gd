extends RefCounted
## One golden character in both worlds, with continuous tail/ear/tongue and gait motion.
const PATH := "res://assets/npcs/golden_dog_v1.png"
const SIZE := Vector2(120,90)
const COLS := 32
const ROWS := 24
var texture: Texture2D
var mesh := ArrayMesh.new()
var uv := PackedVector2Array()
var indices := PackedInt32Array()
var facing := 1.0
var stride_phase := 0.0
var walk_blend := 0.0
var last_time := -1.0

func _init() -> void:
	if ResourceLoader.exists(PATH): texture=load(PATH)
	elif FileAccess.file_exists(PATH): texture=ImageTexture.create_from_image(Image.load_from_file(PATH))
	for y in ROWS+1:
		for x in COLS+1: uv.append(Vector2(float(x)/COLS,float(y)/ROWS))
	for y in ROWS:
		for x in COLS:
			var a := y*(COLS+1)+x
			indices.append_array(PackedInt32Array([a,a+1,a+COLS+1,a+1,a+COLS+2,a+COLS+1]))

static func weight(point: Vector2, center: Vector2, extent: Vector2) -> float:
	return exp(-((point-center)/extent).length_squared()*2.0)

static func motion(point: Vector2, time: float, walking: bool, phase: float = -1.0, blend: float = -1.0) -> Vector2:
	var gait := time*6.0 if phase<0 else phase
	var amount := (1.0 if walking else 0.0) if blend<0 else blend
	var feet := 1.0-smoothstep(0.76,0.93,point.y)
	var bob := (cos(gait*2.0)-1.0)*1.25*amount
	var offset := Vector2(sin(gait)*0.9*amount,sin(time*2.6)*0.8+bob)*feet
	# Tail swings around its root, leaving the rump stable.
	var tail_angle := sin(time*7.0)*0.22+sin(time*14.0)*0.025
	var tail_local := (point-Vector2(0.28,0.49))*SIZE
	offset += (tail_local.rotated(tail_angle)-tail_local)*weight(point,Vector2(0.15,0.25),Vector2(0.20,0.28))
	var follow := sin(gait-0.65)*amount
	offset += Vector2(follow*1.5,sin(time*3.2)*0.6+follow*1.8)*weight(point,Vector2(0.70,0.36),Vector2(0.26,0.27))
	offset += Vector2(sin(time*4.0)*0.7+follow,sin(time*4.0+0.5)+follow*1.7)*weight(point,Vector2(0.59,0.43),Vector2(0.12,0.20))
	offset += Vector2(sin(time*5.0)*1.3,sin(time*5.0-0.7)*1.5+follow)*weight(point,Vector2(0.81,0.54),Vector2(0.10,0.14))
	# Diagonal pairs alternate; each paw lifts only during its forward swing.
	var centers := [Vector2(0.61,0.87),Vector2(0.27,0.79),Vector2(0.82,0.82),Vector2(0.42,0.78)]
	for i in 4:
		var step_phase := gait + (PI if i==1 or i==2 else 0.0)
		var lift := pow(maxf(0.0,sin(step_phase)),2.0)
		var travel := Vector2(cos(step_phase)*4.0,-lift*4.0)*amount
		offset += travel*weight(point,centers[i],Vector2(0.115,0.16))
	return offset

func mouth(position: Vector2, time: float, walking: bool) -> Vector2:
	var point := Vector2(0.77,0.44)
	var local := point*SIZE-Vector2(SIZE.x*0.5,SIZE.y-10)+motion(point,time,walking,stride_phase,walk_blend)
	return position+Vector2(local.x*facing,local.y)

func draw(ci: CanvasItem, dog: Dictionary, time: float) -> bool:
	if texture==null: return false
	var velocity: Vector2=dog.get("velocity",Vector2.ZERO)
	if absf(velocity.x)>2: facing=signf(velocity.x)
	var walking := velocity.length()>1
	var dt := clampf(time-last_time,0.0,0.1) if last_time>=0 and time>=last_time else 0.0
	last_time=time
	# Cadence follows actual travel rather than an unrelated clock.
	stride_phase=fmod(stride_phase+velocity.length()*dt*TAU/24.0,TAU)
	walk_blend=lerpf(walk_blend,clampf(velocity.length()/12.0,0.0,1.0),1.0-exp(-dt*10.0))
	var vertices := PackedVector3Array()
	for point in uv:
		var p := point*SIZE-Vector2(SIZE.x*0.5,SIZE.y-10)+motion(point,time,walking,stride_phase,walk_blend)
		vertices.append(Vector3(p.x,p.y,0))
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_TEX_UV]=uv; arrays[Mesh.ARRAY_INDEX]=indices
	mesh.clear_surfaces(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	ci.draw_mesh(mesh,texture,Transform2D(Vector2(facing,0),Vector2(0,1),dog.p))
	return true
