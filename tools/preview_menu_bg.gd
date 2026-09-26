extends SceneTree

# Gera quadros da tela inicial animada para conferir (test-output/menu_bg/NN.png).
# Uso: godot --path . --rendering-driver opengl3 --resolution 1344x752 -s tools/preview_menu_bg.gd
const MenuBackground = preload("res://scripts/menu_background.gd")

func _initialize() -> void:
	root.content_scale_size = Vector2i(1344, 752)
	var bgnode = MenuBackground.new()
	root.add_child(bgnode)
	bgnode.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://test-output/menu_bg")
	var frames := 48
	for i in range(frames):
		# avança o tempo manualmente (12 quadros/s) para a prévia não depender do relógio
		for k in 5: bgnode._process(1.0 / 60.0)
		if i == 10 or i == 30: bgnode.next_bolt = 0.0; bgnode._process(0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("res://test-output/menu_bg/%02d.png" % i)
	print("MENU_BG_PREVIEW_DONE")
	quit()
