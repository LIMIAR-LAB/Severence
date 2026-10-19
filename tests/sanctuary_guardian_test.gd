extends SceneTree
const Guardian=preload("res://scripts/sanctuary_guardian_visuals.gd")
const Main=preload("res://scripts/main.gd")
var failures:=0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
	else: print("PASS: ",label)
func _init() -> void:
	var save_path:="user://expedition.save"
	var hash_before:=FileAccess.get_sha256(save_path) if FileAccess.file_exists(save_path) else ""
	var guardian:=Guardian.new()
	check(guardian.texture!=null,"arte do guardião carregada")
	var image:=guardian.texture.get_image()
	check(image.get_pixel(0,0).a==0.0,"fundo transparente")
	var rigid:=true
	var anchored:=true
	var smooth:=true
	var head:=Vector2(0,-155)
	var travel:=0.0
	for i in 97:
		var time:=float(i)*Guardian.PERIOD/96.0
		var transform:=Guardian.idle_transform(time)
		rigid=rigid and absf(transform.x.length()-1.0)<0.0001 and absf(transform.y.length()-1.0)<0.0001 and absf(transform.x.dot(transform.y))<0.0001
		anchored=anchored and (transform*Guardian.STAFF_PIVOT).distance_to(Guardian.STAFF_PIVOT)<0.001
		smooth=smooth and (transform*head).distance_to(Guardian.idle_transform(time+1.0/60.0)*head)<0.5
		travel=maxf(travel,(transform*head).distance_to(head))
	check(rigid,"idle mantém proporções e pivô")
	check(anchored and smooth,"cajado apoiado e movimento contínuo")
	check(travel>5.0,"movimento perceptível no tamanho do jogo")
	check((Guardian.idle_transform(0)*head).distance_to(Guardian.idle_transform(Guardian.PERIOD)*head)<0.001,"ciclo sem salto")
	var ui:=Main.new()
	var portrait: Texture2D=ui.portrait_for_message("Mestre Coral: teste")
	check(portrait is AtlasTexture and portrait.atlas.resource_path==Guardian.PATH,"diálogo usa retrato novo")
	var other: Texture2D=ui.portrait_for_message("Bento: teste")
	check(other is AtlasTexture and other.atlas.resource_path!=Guardian.PATH,"outros NPCs preservados")
	ui.free()
	var sim:=Expedition.new()
	sim.story_interact({})
	check(sim.story_quest==1 and sim.message.begins_with("Mestre Coral:"),"missão e diálogo preservados")
	var hash_after:=FileAccess.get_sha256(save_path) if FileAccess.file_exists(save_path) else ""
	check(hash_before==hash_after,"save intacto")
	print("SANCTUARY_GUARDIAN_TEST failures=",failures)
	quit(0 if failures==0 else 1)
