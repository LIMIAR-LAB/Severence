extends Control
# Fundo animado da tela inicial (assets/ui/menu.png + shaders/menu_bg.gdshader).
# O shader anima a própria ilustração: fogo tremulando, brilho ciano pulsando, engrenagens girando,
# destroços flutuando, água ondulando e raios crepitando.
# Este nó desenha por cima: relâmpagos com clarão, faróis varrendo o céu, brasas, garoa e névoa.

const SIZE := Vector2(1344, 752)
const PANEL_X := 415.0          # à esquerda fica o painel do menu (não animamos por cima dele)
const MONSTER := Vector2(915, 130)
const FIRES := [Rect2(420, 410, 170, 140), Rect2(1090, 460, 60, 40), Rect2(1200, 470, 80, 35), Rect2(560, 520, 60, 40)]
const BEAMS := [[Vector2(1225, 560), -2.05, 0.9], [Vector2(1290, 540), -1.85, 1.3], [Vector2(705, 520), -1.25, 0.7]]

var bg: TextureRect
var glow: Node2D
var t := 0.0
var next_bolt := 1.2
var bolts: Array = []     # {pts: [PackedVector2Array], life, max}
var embers: Array = []
var rain: Array = []
var fog: Array = []
var rng := RandomNumberGenerator.new()
var scene_only := false

class Glow extends Node2D:
	var host
	func _draw() -> void: host.draw_glow(self)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SIZE
	rng.seed = 1941
	bg = TextureRect.new()
	var menu_texture = load("res://assets/ui/menu.png")
	if scene_only and menu_texture != null:
		var cropped := AtlasTexture.new(); cropped.atlas = menu_texture; cropped.region = Rect2(384, 107, 960, 537)
		bg.texture = cropped
	else: bg.texture = menu_texture
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.size = SIZE; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new(); mat.shader = load("res://shaders/menu_bg.gdshader")
	mat.set_shader_parameter("gears", [Vector4(705, 37, 29, 0.55), Vector4(1164, 65, 27, -0.7), Vector4(857, 222, 19, 0.9), Vector4(685, 110, 11, -1.2), Vector4(0, 0, 0, 0)])
	mat.set_shader_parameter("floaters", [Vector4(765, 144, 46, 0.0), Vector4(615, 100, 50, 1.3), Vector4(1252, 68, 40, 2.1), Vector4(670, 192, 46, 3.4),
		Vector4(1195, 200, 42, 4.2), Vector4(1001, 265, 46, 5.0), Vector4(1145, 268, 30, 0.7), Vector4(820, 300, 20, 2.6), Vector4(1060, 210, 22, 1.9), Vector4(0, 0, 0, 0)])
	bg.material = mat
	add_child(bg)
	glow = Glow.new(); glow.host = self
	var add := CanvasItemMaterial.new(); add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = add
	add_child(glow)
	for i in 70: rain.append(Vector2(rng.randf_range(PANEL_X, SIZE.x), rng.randf_range(0, SIZE.y)))
	for i in 7: fog.append({"p": Vector2(rng.randf_range(PANEL_X, SIZE.x), rng.randf_range(560, 740)), "r": rng.randf_range(90, 170), "v": rng.randf_range(6, 16)})

func _process(dt: float) -> void:
	if not is_visible_in_tree(): return
	t += dt
	# relâmpagos: a cada 2–5 s, às vezes em dupla
	next_bolt -= dt
	if next_bolt <= 0:
		spawn_bolt()
		next_bolt = rng.randf_range(0.12, 0.25) if rng.randf() < 0.3 else rng.randf_range(2.0, 5.0)
	var flash := 0.0
	for b in bolts:
		b.life -= dt
		flash = maxf(flash, clampf(b.life / b.max, 0, 1) * b.power)
	bolts = bolts.filter(func(b): return b.life > 0)
	var mat: ShaderMaterial = bg.material
	mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("bolt_crackle", 0.5 + 0.5 * sin(t * 23.0) * sin(t * 7.0))
	# brasas saindo do fogo
	if rng.randf() < dt * 22:
		var r: Rect2 = FIRES[rng.randi() % FIRES.size()]
		embers.append({"p": Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y + r.size.y * 0.4, r.end.y)),
			"v": Vector2(rng.randf_range(-8, 14), rng.randf_range(-45, -25)), "life": rng.randf_range(1.2, 2.6), "max": 2.6, "s": rng.randf_range(1.5, 3.0)})
	for e in embers:
		e.life -= dt; e.p += (e.v + Vector2(sin(t * 3 + e.p.y * 0.05) * 10, 0)) * dt
	embers = embers.filter(func(e): return e.life > 0)
	for i in rain.size():
		rain[i] += Vector2(-60, 520) * dt
		if rain[i].y > SIZE.y or rain[i].x < PANEL_X: rain[i] = Vector2(rng.randf_range(PANEL_X + 40, SIZE.x + 80), rng.randf_range(-40, 0))
	for f in fog:
		f.p.x += f.v * dt
		if f.p.x - f.r > SIZE.x: f.p.x = PANEL_X - f.r * 0.5
	queue_redraw(); glow.queue_redraw()

func spawn_bolt() -> void:
	# raio que nasce no monstro e se ramifica para o céu
	var target := MONSTER + Vector2(rng.randf_range(-380, 400), rng.randf_range(-120, 260))
	target.x = clampf(target.x, PANEL_X + 30, SIZE.x - 10)
	var paths: Array = [jag(MONSTER + Vector2(rng.randf_range(-40, 40), rng.randf_range(-20, 30)), target, 14)]
	for k in rng.randi_range(1, 3):
		var main: PackedVector2Array = paths[0]
		var from: Vector2 = main[rng.randi_range(3, main.size() - 3)]
		paths.append(jag(from, from + Vector2(rng.randf_range(-150, 150), rng.randf_range(-40, 140)), 7))
	var life := rng.randf_range(0.18, 0.32)
	bolts.append({"paths": paths, "life": life, "max": life, "power": rng.randf_range(0.55, 1.0)})

func jag(a: Vector2, b: Vector2, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array([a])
	var normal := (b - a).orthogonal().normalized()
	for i in range(1, n):
		pts.append(a.lerp(b, float(i) / n) + normal * rng.randf_range(-18, 18))
	pts.append(b)
	return pts

func _draw() -> void:
	# garoa fina (só sobre a ilustração)
	for p in rain: draw_line(p, p + Vector2(-2.5, 14), Color(0.7, 0.8, 1.0, 0.18), 1.0)
	# névoa rasteira no cais
	for f in fog:
		for k in 3: draw_circle(f.p + Vector2(k * f.r * 0.5, sin(t * 0.5 + k) * 8), f.r * (1.0 - k * 0.2), Color(0.55, 0.62, 0.8, 0.025))

func draw_glow(ci: CanvasItem) -> void:
	# faróis varrendo o céu
	for b in BEAMS:
		var o: Vector2 = b[0]
		var ang: float = b[1] + sin(t * 0.35 * b[2] + b[2]) * 0.16
		var dir := Vector2.from_angle(ang); var n := dir.orthogonal()
		var far := o + dir * 900
		ci.draw_colored_polygon(PackedVector2Array([o - n * 6, o + n * 6, far + n * 70, far - n * 70]), Color(0.35, 0.5, 0.8, 0.07))
		ci.draw_colored_polygon(PackedVector2Array([o - n * 3, o + n * 3, far + n * 25, far - n * 25]), Color(0.45, 0.6, 0.9, 0.06))
	# relâmpagos
	for b in bolts:
		var k: float = clampf(b.life / b.max, 0, 1) * b.power
		for i in b.paths.size():
			var pts: PackedVector2Array = b.paths[i]
			var w := 1.0 if i > 0 else 1.6
			ci.draw_polyline(pts, Color(0.55, 0.35, 1.0, 0.35 * k), 9 * w)
			ci.draw_polyline(pts, Color(0.5, 0.85, 1.0, 0.7 * k), 3.5 * w)
			ci.draw_polyline(pts, Color(1, 1, 1, 0.9 * k), 1.3 * w)
		ci.draw_circle(MONSTER, 90 * k, Color(0.5, 0.4, 1.0, 0.15 * k))
	# brasas
	for e in embers:
		var a: float = clampf(e.life / 1.2, 0, 1)
		ci.draw_circle(e.p, e.s, Color(1.0, 0.55 + 0.3 * a, 0.15, 0.8 * a))
	# brilho do núcleo do robô
	var pulse := 0.5 + 0.5 * sin(t * 2.6)
	ci.draw_circle(Vector2(835, 440), 36 + 6 * pulse, Color(0.2, 0.8, 1.0, 0.05 + 0.05 * pulse))
