extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const Main=preload("res://scripts/main.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1;push_error(label)
	else:print("PASS: ",label)
func _init() -> void:
	var s:=Sim.new();s.coop="solo";s.set_unlocks(s.EquipmentData.starting_unlocks());s.start_arena();s.enemies.clear()
	var a: Dictionary=s.actors[0]
	check(s.is_unlocked("supernova"),"Supernova disponível no catálogo inicial")
	check(s.equip(0,"padrao","","supernova"),"equipar pelo inventário")
	s.toggle_armor(a)
	check(a.armor and a.shield==3*s.HEART,"ativação concede três escudos")
	a.transform=0;a.p=Vector2(650,500);a.aim=Vector2.RIGHT
	s.fire_actor(a)
	check(s.bullets.size()==1 and s.bullets[0].kind=="p_supernova" and s.bullets[0].damage==32,"plasma solar independente da Omega")
	s.spawn_enemy(a.p+Vector2(100,0),"brute");var enemy: Dictionary=s.enemies[-1];var before: float=enemy.hp
	s.Supernova.pulse(s,a)
	check(enemy.hp==before-72 and a.nova_cd==6,"pulso causa 72 de dano e inicia recarga")
	before=enemy.hp;s.Supernova.pulse(s,a)
	check(enemy.hp==before,"recarga impede pulsos repetidos")
	a.nova_cd=0;s.obstacles=[Rect2(690,350,20,300)];s.ob_grid_count=-1;s.Supernova.pulse(s,a)
	check(enemy.hp==before,"pulso não atravessa paredes")
	s.obstacles.clear();s.ob_grid_count=-1;a.armor_time=0.01;s.step_actor(a,{},0.02)
	check(not a.armor and a.armor_cd==60,"expiração restaura uniforme e recarga")
	check(s.weapon_of(a)=="pistol","arma original preservada")
	var saved:=s.snapshot().duplicate(true);saved.unlocked.erase("supernova")
	var restored:=Sim.new();restored.apply_snapshot(saved)
	check(restored.is_unlocked("supernova") and restored.InventoryState.new(restored.inventory_state).quantity("armadura_supernova")==1,"migração disponibiliza armadura sem duplicar")
	var art: Texture2D=load("res://assets/characters/marty/supernova/v1/atlas.png")
	check(art.get_image().get_pixel(0,0).a==0,"arte GameLab tem transparência")
	var ui:=Main.new();ui.sim=s;ui.grant_starting_form();ui.grant_starting_form()
	check(s.InventoryState.new(s.inventory_state).quantity("armadura_supernova")==1,"concessão inicial idempotente")
	ui.free()
	print("SUPERNOVA failures=",failures);quit(1 if failures else 0)
