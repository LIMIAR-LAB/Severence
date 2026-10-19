extends RefCounted

# Configurações de vídeo (menu OPÇÕES → VÍDEO). Salvas em user://settings.json junto com o resto.
# A interface é desenhada numa base de 1280×800 e escala (stretch "canvas_items" + aspecto "expand"):
# telas mais largas (16:9, 21:9) ou mais altas (4:3) mostram MAIS mundo, sem faixas pretas,
# e o HUD se ancora nas bordas reais da tela.

const RESOLUTIONS := [
	Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1366, 768), Vector2i(1440, 900), Vector2i(1600, 900),
	Vector2i(1680, 1050), Vector2i(1920, 1080), Vector2i(1920, 1200), Vector2i(2560, 1080), Vector2i(2560, 1440),
	Vector2i(2560, 1600), Vector2i(3440, 1440), Vector2i(3840, 2160)]
const MODES := ["JANELA", "TELA CHEIA (SEM BORDA)", "TELA CHEIA EXCLUSIVA"]
const FPS_LIMITS := [30, 60, 120, 144, 165, 240, 0]   # 0 = sem limite
const VIEWS := {"perto": 1.4, "normal": 1.22, "longe": 0.68}   # zoom da câmera na expedição
const VIEW_NAMES := {"perto": "PERTO", "normal": "NORMAL", "longe": "LONGE (vê mais sala)"}
const UI_SCALES := [0.75, 0.9, 1.0, 1.15, 1.3]

var resolution := Vector2i(1600, 1000)
var mode := 0
var vsync := true
var fps_limit := 0
var view := "normal"
var pixel_perfect := false
var ui_scale := 1.0
var camera_shake := 1.0
var screen_flash := 1.0

func to_dict() -> Dictionary:
	return {"resolution": [resolution.x, resolution.y], "mode": mode, "vsync": vsync, "fps_limit": fps_limit,
		"view": view, "pixel_perfect": pixel_perfect, "ui_scale": ui_scale, "camera_shake": camera_shake, "screen_flash": screen_flash}

func from_dict(data: Dictionary) -> void:
	var r = data.get("resolution", [])
	if r is Array and r.size() == 2: resolution = Vector2i(clampi(int(r[0]), 640, 7680), clampi(int(r[1]), 400, 4320))
	mode = clampi(int(data.get("mode", mode)), 0, MODES.size() - 1)
	vsync = data.get("vsync", vsync) == true
	fps_limit = int(data.get("fps_limit", fps_limit)) if int(data.get("fps_limit", fps_limit)) in FPS_LIMITS else 0
	view = str(data.get("view", view)) if str(data.get("view", view)) in VIEWS else "normal"
	pixel_perfect = data.get("pixel_perfect", pixel_perfect) == true
	var us := float(data.get("ui_scale", ui_scale))
	ui_scale = us if us in UI_SCALES else 1.0
	camera_shake = comfort_value(data.get("camera_shake", 1.0))
	screen_flash = comfort_value(data.get("screen_flash", 1.0))

static func comfort_value(value) -> float:
	return clampf(float(value), 0.0, 1.0) if (value is float or value is int) and is_finite(float(value)) else 1.0

func camera_zoom() -> float:
	return VIEWS[view]

# Lista de resoluções que cabem no monitor atual (sempre inclui a atual).
func available_resolutions() -> Array:
	var screen := DisplayServer.screen_get_size()
	var out: Array = []
	for r in RESOLUTIONS:
		if screen.x <= 0 or (r.x <= screen.x and r.y <= screen.y): out.append(r)
	if not out.has(resolution): out.append(resolution)
	if screen.x > 0 and not out.has(screen): out.append(screen)
	out.sort_custom(func(a, b): return a.x * a.y < b.x * b.y)
	return out

func apply(tree: SceneTree) -> void:
	if DisplayServer.get_name() == "headless": return
	var win := tree.root
	# Escala: base 1280×800 × escala da interface. "expand" usa a sobra da tela para mostrar mais mundo.
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_size = Vector2i(roundi(1280 / ui_scale), roundi(800 / ui_scale))
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if pixel_perfect else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = fps_limit
	# A janela embutida pertence ao editor; ele controla tamanho, modo e posição.
	if "--wid" in OS.get_cmdline_args(): return
	if "--resolution" in OS.get_cmdline_args() or Array(OS.get_cmdline_user_args()).any(func(arg): return arg.begins_with("--capture")): return   # testes/capturas definem a janela pela linha de comando
	match mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			var screen := DisplayServer.screen_get_size()
			var size := resolution
			if screen.x > 0: size = Vector2i(mini(size.x, screen.x), mini(size.y, screen.y))
			DisplayServer.window_set_size(size)
			var origin := DisplayServer.screen_get_position()
			if screen.x > 0: DisplayServer.window_set_position(origin + (screen - size) / 2)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func summary() -> String:
	var sz := DisplayServer.window_get_size() if DisplayServer.get_name() != "headless" else resolution
	return "Janela atual: %d×%d  •  %s" % [sz.x, sz.y, MODES[mode]]
