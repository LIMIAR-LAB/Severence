extends SceneTree

# 0.15: props HD do cenário (tools/make_props_hd.py) — carregam, mantêm o tamanho e têm detalhe (não são blocos lisos).
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

const SIZES := {"pillar": Vector2i(96, 140), "generator": Vector2i(120, 120), "altar": Vector2i(210, 120), "pew": Vector2i(180, 50),
	"ammo": Vector2i(70, 52), "candles": Vector2i(40, 40), "puddle": Vector2i(120, 50), "crack": Vector2i(80, 80),
	"rug": Vector2i(140, 330), "stairs": Vector2i(64, 64), "capsule": Vector2i(150, 240)}

func _init() -> void:
	for n in SIZES:
		var tex: Texture2D = load("res://assets/environment/docks/%s.png" % n)
		check(tex != null and Vector2i(tex.get_size()) == SIZES[n], "%s carrega no tamanho %s" % [n, SIZES[n]])
		if tex == null: continue
		var img := tex.get_image()
		var colors := {}
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.1: colors[c.to_rgba32()] = true
		check(colors.size() >= (4 if n == "puddle" else 6), "%s tem detalhe (%d cores)" % [n, colors.size()])
	print("PROPS_HD_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
