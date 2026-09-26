extends RefCounted

# Cápsula Temporal: efeito de invocar/recolher robôs (hexágono laranja).
# GENÉRICO: serve para qualquer robô, atual ou futuro, sem animação própria. Ele só precisa do sprite
# parado do robô (textura + região + tamanho): a silhueta branca, a materialização de baixo para cima,
# o encolhimento e o voo até a mão são gerados a partir dessa imagem. Ver ROBOT_SPRITES / register_robot().
# Arquivo independente: só desenha. Quem cria os efeitos é a simulação, quem chama é o world_view.
#
# INVOCAR  (efeito kind = "robot_summon", 1,1s)
#   0,00–0,35  cápsula voa em arco da mão do Marty até o ponto de invocação, girando
#   0,35–0,50  quica, pisca e abre em duas metades (clarão + anel no chão)
#   0,45–0,95  feixe vertical; o robô "materializa": silhueta branca cresce de baixo para cima e ganha cor
#   0,95–1,10  anel de choque e faíscas; o robô real já está desenhado
# RECOLHER (efeito kind = "robot_recall", 0,8s)
#   0,00–0,35  feixe vermelho/ciano liga a mão do Marty ao robô; robô vira silhueta branca pulsando
#   0,35–0,60  silhueta encolhe num ponto de luz e voa até a mão
#   0,60–0,80  cápsula fecha na mão com um estalo (anel + faíscas)
#
# Campos do efeito: p (onde o robô aparece/estava), from (posição da mão do Marty), robot ("titan"/"spectre"),
# life, max, owner. O world_view não deve desenhar o robô real enquanto robot_hidden() for true.

const SUMMON_TIME := 1.1
const RECALL_TIME := 0.8
const ORANGE := Color("f08a24")
const ORANGE_DARK := Color("b85a14")
const ORANGE_LIGHT := Color("ffb45a")
const RED := ORANGE   # feixes e faíscas usam o laranja da cápsula
const CYAN := Color(0.45, 0.95, 1.0)
const WHITE := Color(1, 1, 1)

# Registro de robôs: um robô novo só precisa de uma linha aqui (ou register_robot em tempo de execução).
static var ROBOT_SPRITES := {
	"titan": {"texture": "res://assets/mech/titan_v2.png", "region": Rect2(0, 0, 176, 176), "size": Vector2(176, 176)},
	"spectre": {"texture": "res://assets/mech/spectre.png", "region": Rect2(), "size": Vector2(44, 66)}}
static var _tex_cache: Dictionary = {}

static func register_robot(id: String, texture_path: String, region: Rect2 = Rect2(), size: Vector2 = Vector2.ZERO) -> void:
	ROBOT_SPRITES[id] = {"texture": texture_path, "region": region, "size": size}

static func sprite_of(robot: String) -> Dictionary:
	var info: Dictionary = ROBOT_SPRITES.get(robot, ROBOT_SPRITES.titan)
	if not _tex_cache.has(info.texture): _tex_cache[info.texture] = load(info.texture)
	var tex: Texture2D = _tex_cache[info.texture]
	var region: Rect2 = info.region if info.region.size != Vector2.ZERO else Rect2(Vector2.ZERO, tex.get_size())
	var size: Vector2 = info.size if info.size != Vector2.ZERO else region.size
	return {"texture": tex, "region": region, "size": size}

# Atalho: desenha qualquer efeito de cápsula usando o registro (o world_view só chama isto).
static func draw_auto(c: CanvasItem, fx: Dictionary) -> void:
	var sp := sprite_of(fx.get("robot", "titan"))
	draw(c, fx, sp.texture, sp.region, sp.size)

static func summon_effect(owner_id: int, from: Vector2, at: Vector2, robot: String) -> Dictionary:
	return {"kind": "robot_summon", "p": at, "from": from, "robot": robot, "owner": owner_id, "life": SUMMON_TIME, "max": SUMMON_TIME}

static func recall_effect(owner_id: int, from: Vector2, at: Vector2, robot: String) -> Dictionary:
	return {"kind": "robot_recall", "p": at, "from": from, "robot": robot, "owner": owner_id, "life": RECALL_TIME, "max": RECALL_TIME}

static func elapsed(fx: Dictionary) -> float:
	return fx.max - fx.life

# O robô real fica escondido enquanto a cápsula ainda não "soltou" ele.
static func robot_hidden(effects: Array, robot: String, owner_id: int = -1) -> bool:
	for fx in effects:
		if fx.get("robot", "") != robot: continue
		if owner_id >= 0 and fx.get("owner", -1) != owner_id: continue
		if fx.kind == "robot_summon" and elapsed(fx) < 0.95: return true
	return false

# ─────────────────────────── desenho ───────────────────────────

static func draw_capsule(c: CanvasItem, pos: Vector2, angle: float, open_amount: float, scale: float = 1.0, glow: float = 0.0) -> void:
	# Cápsula Temporal: hexágono laranja com faixa grafite e núcleo ciano, que se parte em duas metades.
	var r := 12.0 * scale
	var gap := open_amount * 9.0 * scale
	var up := Vector2(0, -1).rotated(angle)
	if glow > 0: c.draw_circle(pos, r * 2.2, Color(ORANGE, 0.22 * glow))
	c.draw_set_transform(pos + up * gap, angle - open_amount * 0.8)
	_half(c, r, true)
	c.draw_set_transform(pos - up * gap, angle + open_amount * 0.35)
	_half(c, r, false)
	c.draw_set_transform(Vector2.ZERO)

static func _hex(r: float, top: bool) -> PackedVector2Array:
	# metade de um hexágono "deitado" (vértices a 0°, 60°, 120°, 180°), cortado na horizontal
	var pts := PackedVector2Array()
	for i in range(4):
		var a := deg_to_rad(180.0 + 60.0 * i) if top else deg_to_rad(60.0 * i)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

static func _half(c: CanvasItem, r: float, top: bool) -> void:
	c.draw_colored_polygon(_hex(r + 1.5, top), Color("1a120e"))
	c.draw_colored_polygon(_hex(r, top), ORANGE if top else ORANGE_DARK)
	var inner := _hex(r * 0.62, top)
	c.draw_colored_polygon(inner, ORANGE_LIGHT if top else ORANGE)
	if top: c.draw_line(Vector2(-r * 0.5, -r * 0.75), Vector2(r * 0.1, -r * 0.75), Color(1, 1, 1, 0.75), 1.5)
	c.draw_rect(Rect2(-r - 1.5, -2.0 if top else 0.0, r * 2 + 3, 2.0), Color("2a2f3a"))   # faixa grafite
	# núcleo hexagonal ciano
	var core := PackedVector2Array()
	for i in range(6):
		var a := deg_to_rad(30.0 + 60.0 * i)
		core.append(Vector2(cos(a), sin(a)) * r * 0.3)
	c.draw_colored_polygon(core, Color("1a120e"))
	var core_in := PackedVector2Array()
	for p in core: core_in.append(p * 0.62)
	c.draw_colored_polygon(core_in, CYAN)

static func draw_robot_silhouette(c: CanvasItem, tex: Texture2D, region: Rect2, foot: Vector2, size: Vector2, reveal: float, whiteness: float, squash: float = 1.0) -> void:
	# Desenha o robô revelado de baixo para cima (reveal 0..1) e com "brancura" 1 = silhueta de luz.
	if tex == null or reveal <= 0: return
	var h := size.y * reveal
	var src := Rect2(region.position.x, region.position.y + region.size.y * (1.0 - reveal), region.size.x, region.size.y * reveal)
	var dst := Rect2(foot.x - size.x * 0.5 * squash, foot.y - h, size.x * squash, h)
	if whiteness < 0.98: c.draw_texture_rect_region(tex, dst, src)
	if whiteness > 0.02:
		c.draw_texture_rect_region(white_version(tex), dst, src, Color(0.88, 1.0, 1.0, whiteness))
	# linha de varredura na borda da revelação
	if reveal < 1.0:
		c.draw_rect(Rect2(dst.position.x - 6, dst.position.y - 2, dst.size.x + 12, 3), Color(WHITE, 0.9))
		c.draw_rect(Rect2(dst.position.x - 10, dst.position.y - 6, dst.size.x + 20, 10), Color(CYAN, 0.25))

static var _white_cache: Dictionary = {}

# Versão branca (mesmo alfa) da textura, criada uma vez e guardada: a silhueta de luz do efeito.
static func white_version(tex: Texture2D) -> Texture2D:
	var key := tex.get_rid().get_id()
	if _white_cache.has(key): return _white_cache[key]
	var img := tex.get_image()
	if img.is_compressed(): img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var a := img.get_pixel(x, y).a
			if a > 0: img.set_pixel(x, y, Color(1, 1, 1, a))
	var out := ImageTexture.create_from_image(img)
	_white_cache[key] = out
	return out

static func _sparks(c: CanvasItem, center: Vector2, t: float, count: int, radius: float, color: Color, seed: int) -> void:
	for n in range(count):
		var a := n * TAU / count + seed * 0.37
		var d := radius * t * (0.7 + 0.3 * sin(n * 5.1 + seed))
		var p := center + Vector2(cos(a), sin(a) * 0.55) * d
		var s := 3.0 * (1.0 - t)
		c.draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), Color(color, 1.0 - t))

static func draw_summon(c: CanvasItem, fx: Dictionary, tex: Texture2D, region: Rect2, size: Vector2) -> void:
	var t := elapsed(fx)
	var from: Vector2 = fx.from
	var to: Vector2 = fx.p
	# 1) voo em arco
	if t < 0.35:
		var k := t / 0.35
		var arc := from.lerp(to, k) - Vector2(0, sin(k * PI) * 90.0 + 30.0 * (1.0 - k))
		c.draw_set_transform(to, 0, Vector2(1, 0.35)); c.draw_circle(Vector2.ZERO, 8.0 * k, Color(0, 0, 0, 0.3 * k)); c.draw_set_transform(Vector2.ZERO)
		for i in range(4):   # rastro
			var kk := maxf(0.0, k - i * 0.06)
			var tp := from.lerp(to, kk) - Vector2(0, sin(kk * PI) * 90.0 + 30.0 * (1.0 - kk))
			c.draw_circle(tp, 5.0 - i, Color(CYAN, 0.35 - i * 0.08))
		draw_capsule(c, arc, k * TAU * 2.0, 0.0, 1.0)
		return
	var ground := to - Vector2(0, 8)
	# 2) quica e abre
	var open_k := clampf((t - 0.38) / 0.12, 0, 1)
	var bounce := 0.0
	if t < 0.45: bounce = sin((t - 0.35) / 0.1 * PI) * 10.0
	if t < 0.95:
		draw_capsule(c, ground - Vector2(0, bounce), 0.0, open_k, 1.0, open_k)
	if t >= 0.38 and t < 0.6:
		var fl := 1.0 - (t - 0.38) / 0.22
		c.draw_circle(ground, 60.0 * (1.0 - fl) + 10.0, Color(WHITE, fl * 0.8))
	# anel no chão
	if t >= 0.4:
		var rk := clampf((t - 0.4) / 0.55, 0, 1)
		c.draw_set_transform(to, 0, Vector2(1, 0.4))
		c.draw_arc(Vector2.ZERO, 30.0 + rk * 50.0, 0, TAU, 40, Color(CYAN, 1.0 - rk * 0.6), 3)
		c.draw_arc(Vector2.ZERO, 20.0 + rk * 30.0, t * 8.0, t * 8.0 + 4.0, 24, Color(RED, 0.9 - rk * 0.5), 2)
		c.draw_set_transform(Vector2.ZERO)
	# 3) feixe + materialização
	if t >= 0.45 and t < 1.0:
		var bk := clampf((t - 0.45) / 0.5, 0, 1)
		var beam_w := size.x * 0.55 * (1.0 - absf(bk - 0.5) * 1.2)
		c.draw_rect(Rect2(to.x - beam_w * 0.5, to.y - size.y * 1.6, beam_w, size.y * 1.6), Color(CYAN, 0.22))
		c.draw_rect(Rect2(to.x - beam_w * 0.18, to.y - size.y * 1.6, beam_w * 0.36, size.y * 1.6), Color(WHITE, 0.4))
		draw_robot_silhouette(c, tex, region, to, size, bk, 1.0 - clampf((t - 0.75) / 0.2, 0, 1), 0.85 + 0.15 * bk)
	# 4) choque final
	if t >= 0.92:
		var sk := clampf((t - 0.92) / 0.18, 0, 1)
		c.draw_set_transform(to, 0, Vector2(1, 0.45))
		c.draw_arc(Vector2.ZERO, 40.0 + sk * 90.0, 0, TAU, 48, Color(WHITE, 1.0 - sk), 4)
		c.draw_set_transform(Vector2.ZERO)
		_sparks(c, to - Vector2(0, size.y * 0.4), sk, 14, 110.0, CYAN, 3)

static func draw_recall(c: CanvasItem, fx: Dictionary, tex: Texture2D, region: Rect2, size: Vector2) -> void:
	var t := elapsed(fx)
	var hand: Vector2 = fx.from
	var at: Vector2 = fx.p
	var mid := at - Vector2(0, size.y * 0.45)
	# 1) feixe e silhueta pulsando
	if t < 0.6:
		var pulse := 0.5 + 0.5 * sin(t * 50.0)
		var w := 6.0 + pulse * 3.0
		c.draw_line(hand, mid, Color(RED, 0.55), w + 4)
		c.draw_line(hand, mid, Color(WHITE, 0.9), w * 0.4)
		for i in range(5):   # bolinhas correndo no feixe
			var k := fposmod(t * 3.0 + i * 0.2, 1.0)
			c.draw_circle(mid.lerp(hand, k), 3.0, Color(CYAN, 0.9))
		draw_capsule(c, hand + Vector2(0, -6), 0.0, 1.0, 1.0, 1.0)
	if t < 0.35:
		var wk := clampf(t / 0.2, 0, 1)
		draw_robot_silhouette(c, tex, region, at, size, 1.0, wk, 1.0)
	elif t < 0.6:
		# 2) encolhe para um ponto e voa até a mão
		var k := (t - 0.35) / 0.25
		var shrink := 1.0 - k
		var foot := at.lerp(hand + Vector2(0, size.y * 0.1 * shrink), k * k)
		if shrink > 0.08:
			draw_robot_silhouette(c, tex, region, foot, size * Vector2(shrink * (1.0 + 0.3 * k), shrink), 1.0, 1.0, 1.0)
		c.draw_circle(foot - Vector2(0, size.y * 0.4 * shrink), 6.0 + 10.0 * shrink, Color(WHITE, 0.85))
		c.draw_circle(foot - Vector2(0, size.y * 0.4 * shrink), 14.0 + 14.0 * shrink, Color(CYAN, 0.25))
	else:
		# 3) cápsula fecha com estalo
		var k := (t - 0.6) / 0.2
		draw_capsule(c, hand + Vector2(0, -6), 0.0, maxf(0.0, 1.0 - k * 2.5), 1.0, 1.0 - k)
		c.draw_arc(hand + Vector2(0, -6), 10.0 + k * 30.0, 0, TAU, 28, Color(WHITE, 1.0 - k), 3)
		_sparks(c, hand + Vector2(0, -6), k, 10, 40.0, RED, 7)

static func draw(c: CanvasItem, fx: Dictionary, tex: Texture2D, region: Rect2, size: Vector2) -> void:
	if fx.kind == "robot_summon": draw_summon(c, fx, tex, region, size)
	elif fx.kind == "robot_recall": draw_recall(c, fx, tex, region, size)
