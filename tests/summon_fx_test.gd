extends SceneTree

# Efeito de invocar/recolher robô (scripts/summon_fx.gd) — independente da simulação.
const FX = preload("res://scripts/summon_fx.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _init() -> void:
	var s := FX.summon_effect(0, Vector2(0, 0), Vector2(200, 0), "titan")
	check(s.kind == "robot_summon" and is_equal_approx(s.max, FX.SUMMON_TIME), "invocação cria efeito com duração")
	check(FX.robot_hidden([s], "titan", 0), "robô real fica escondido enquanto a cápsula voa/abre")
	s.life = s.max - 1.0
	check(not FX.robot_hidden([s], "titan", 0), "robô aparece no fim da materialização")
	check(not FX.robot_hidden([s], "spectre", 0), "efeito do Titan não esconde o Spectre")
	var r := FX.recall_effect(1, Vector2.ZERO, Vector2(100, 0), "spectre")
	check(r.kind == "robot_recall" and r.owner == 1, "recolher cria efeito próprio")
	var tex: Texture2D = load("res://assets/mech/titan_v2.png")
	var w: Texture2D = FX.white_version(tex)
	var img := w.get_image()
	var found := false
	for y in range(0, 176, 4):
		for x in range(0, 176, 4):
			var c := img.get_pixel(x, y)
			if c.a > 0.5: found = c.r > 0.99 and c.g > 0.99 and c.b > 0.99; break
		if found: break
	check(found, "silhueta branca gerada a partir do sprite")
	check(FX.white_version(tex) == w, "silhueta fica em cache")
	print("SUMMON_FX_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
