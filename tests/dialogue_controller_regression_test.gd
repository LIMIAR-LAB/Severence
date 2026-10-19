extends SceneTree

const Main = preload("res://scripts/main.gd")
class ControllerApp extends Main:
	func playstation_controller_connected() -> bool:
		return true

var failures := 0

func check(ok: bool, description: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + description)
	else: print("PASS: " + description)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	# No _ready, load_progress or scene startup: player saves are never accessed.
	var app = ControllerApp.new()
	var cmd: Dictionary = Main.controller_combat_buttons(false, true, false, false)
	check(cmd.interact and not cmd.melee_m and not cmd.melee_h, "Triangle interacts without punching")
	cmd = Main.controller_combat_buttons(false, false, true, false)
	check(cmd.weapon and not cmd.melee_h, "R1 switches weapon without punching")
	cmd = Main.controller_combat_buttons(true, false, false, false)
	check(cmd.melee and not cmd.melee_m, "Square performs weak punch")
	cmd = Main.controller_combat_buttons(true, false, false, true)
	check(cmd.melee_m and not cmd.melee, "L2 + Square performs medium punch exclusively")
	cmd = Main.controller_combat_buttons(false, false, true, true)
	check(cmd.melee_h and not cmd.weapon, "L2 + R1 performs strong punch without changing weapon")
	check(app.portrait_for_message("Marty: agora sim!") != null, "Marty has a dedicated portrait")
	var coral: Texture2D = app.portrait_for_message("Mestre Coral: aproxime-se.")
	check(coral is AtlasTexture and coral.atlas.resource_path.ends_with("fisherman_frame_00.png"), "Coral portrait uses actual NPC artwork, not an enemy")
	check(coral.region.size.y < coral.atlas.get_height(), "NPC portrait crops upper body rather than shrinking whole sprite")
	for name in ["Nadir", "Volt", "Bento", "Faísca", "Comerciante"]:
		check(app.portrait_for_message(name + ": obrigado.") != null, name + " uses existing survivor artwork")
	check(app.portrait_for_message("DASH: pronto") == null, "Status text is not misidentified as NPC dialogue")
	check(app.portrait_for_message("Desconhecido: teste") == null, "Unknown speaker does not receive misleading cult portrait")
	app.build_ui()
	check(app.banner_frame is Panel and not app.banner_frame is PanelContainer, "Dialogue panel does not stretch portrait over text")
	check(app.banner_portrait.position.y < 0 and app.banner.position.y >= app.banner_portrait.position.y + app.banner_portrait.size.y, "Portrait is above dialogue text without overlap")
	check(app.banner_portrait_frame.position.y < 0, "Portrait has its own frame above dialogue")
	app.menu.content = Control.new(); app.menu.add_child(app.menu.content)
	app.menu.options_tab = "controls"; app.menu.build_options()
	var restore: Button = null
	var back: Button = null
	for button: Button in app.menu.content.find_children("*", "Button", true, false):
		if button.text == "RESTAURAR PADRÃO": restore = button
		if button.text == "VOLTAR": back = button
	check(restore != null and back != null and restore.position.y + restore.size.y <= back.position.y, "PlayStation legend and controls buttons fit without overlapping")
	var clear_labels := true
	var modified_punch_hint := false
	for label: Label in app.menu.content.find_children("*", "Label", true, false):
		for symbol in ["□", "✕", "○", "△"]:
			if label.text.contains(symbol): clear_labels = false
		if label.text.contains("L2+QUADRADO") and label.text.contains("L2+R1"): modified_punch_hint = true
	check(clear_labels, "PlayStation buttons use readable names instead of unavailable font glyphs")
	check(modified_punch_hint, "Controls page documents both modified punch buttons")
	app.free()
	print("DIALOGUE_CONTROLLER_REGRESSION failures=", failures)
	quit(1 if failures > 0 else 0)
