extends SceneTree

const Visuals := preload("res://scripts/weapon_visuals.gd")
const HUD := preload("res://scripts/combat_hud.gd")
const Equipment := preload("res://scripts/equipment_screen.gd")
var failures := 0

# Esta tela isolada não cria Main nem escreve progresso em user://.
class TestApp extends Node:
	var sim := Expedition.new()
	var online := false
	var hosting := false
	var playing := true
	var map_open := false
	var menu := Control.new()
	func playstation_controller_connected() -> bool:
		return false
	func request_run_weapon(id: int, weapon: String) -> bool:
		return sim.select_run_weapon(id, weapon)

class TestHost extends RefCounted:
	var gear_actor := 0
	var outfit_choice := "padrao"
	var armor_choice := "omega"
	var robot_choice := ""

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else: failures += 1; push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var app := TestApp.new(); root.add_child(app)
	app.add_child(app.menu); app.menu.hide()
	app.sim.coop = "solo"; app.sim.start_run(1941)
	app.sim.set_unlocks(["padrao", "omega", "mecanico", "espiao"])
	var actor: Dictionary = app.sim.actors[0]
	for weapon in ["bazooka", "mosquete", "tesla", "arpoador"]:
		app.sim.grant_run_weapon(actor, weapon, 6)
	var eq := Equipment.new(); eq.app = app; eq.host = TestHost.new(); eq.mission_mode = true
	eq.active_tab = 4
	root.add_child(eq); eq.set_process(false) # isolated selector has no full screen host
	eq.page = Control.new(); eq.add_child(eq.page)
	for index in 5:
		var tab := Button.new(); eq.add_child(tab); eq.tabs.append(tab)
	for node_name in ["Back", "Refuge"]:
		var nav := Button.new(); nav.name = node_name; eq.add_child(nav)
	eq.build_status()
	await process_frame
	var scroll := eq.page.find_child("WeaponSelector", true, false) as ScrollContainer
	check(scroll != null and scroll.follow_focus, "Todas as armas acessíveis por rolagem e foco")
	var paths := {}
	for weapon in app.sim.available_weapons(actor):
		var control := eq.page.find_child("SelectWeapon_" + weapon, true, false) as Button
		check(control != null and control.icon != null, "Miniatura presente: " + weapon)
		if control == null or control.icon == null: continue
		check(control.icon.resource_path == Visuals.PATHS[weapon], "Miniatura corresponde ao tipo: " + weapon)
		check(not paths.has(control.icon.resource_path), "Silhueta própria: " + weapon)
		paths[control.icon.resource_path] = true
		control.pressed.emit()
		check(app.sim.weapon_of(actor) == weapon, "Botão seleciona a própria arma: " + weapon)
		check(control.text.begins_with("• ") and control.text.ends_with(app.sim.WEAPON_NAMES[weapon]), "Legenda e seleção preservam identidade: " + weapon)
	var hud := HUD.new(); hud.app = app; root.add_child(hud)
	for weapon in Visuals.PATHS:
		app.sim.select_run_weapon(0, weapon); hud.queue_redraw(); await process_frame
		check(hud.art.get("w_" + weapon) != null, "HUD loads drawable weapon: " + weapon)
		var icon := HUD.weapon_texture(weapon)
		check(icon != null and icon.resource_path == Visuals.PATHS[weapon], "HUD shares weapon silhouette: " + weapon)
	for weapon in ["bazooka", "mosquete", "tesla", "arpoador"]:
		check(HUD.weapon_ammo_caption(actor, weapon) == "6", "HUD shows run charges: " + weapon)
	check(HUD.weapon_ammo_caption(actor, "pistol") == "∞", "Basic weapon shows infinite ammunition")
	actor.run_weapons.tesla = 0
	check(HUD.weapon_ammo_caption(actor, "tesla") == "0", "Empty run weapon shows zero charges")
	check(HUD.weapon_texture("unknown") == null, "HUD does not invent unknown weapon icon")
	check(Visuals.texture("unknown") == null, "Tipo desconhecido não recebe imagem de outra arma")
	hud.free(); eq.free(); app.free()
	print("WEAPON_THUMBNAIL_TESTS_DONE failures=", failures)
	quit(1 if failures > 0 else 0)
