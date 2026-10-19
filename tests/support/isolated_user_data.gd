extends RefCounted
## Must run before creating any application scene. Does not delete user data.
static func activate() -> void:
	if OS.get_user_data_dir().replace("\\", "/").contains("/SeverenceTests/"): return
	var original := OS.get_user_data_dir()
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "SeverenceTests/" + str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec()))
	var isolated := OS.get_user_data_dir()
	if isolated == original or not isolated.replace("\\", "/").contains("/SeverenceTests/"):
		push_error("Test isolation failed; terminating before accessing the real profile")
		OS.kill(OS.get_process_id())
		return
	DirAccess.make_dir_recursive_absolute(isolated)
	print("ISOLATED_USER_DATA ", isolated)
