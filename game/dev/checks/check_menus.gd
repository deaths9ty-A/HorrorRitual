extends SceneTree
## เทสกันพัง + ถ่ายภาพ: เมนูหยุดเกม (Esc) และหน้าตั้งค่า · รัน: Godot --path game -s res://dev/checks/check_menus.gd -- --dir=โฟลเดอร์ภาพ

var _dir := "user://"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			_dir = a.substr(6) + "/"
	var settings := root.get_node("Settings")
	var old_fps: bool = settings.get_value("display/show_fps")
	change_scene_to_file("res://scenes/chase/lair_hearing.tscn")
	await _frames(40)
	_press_esc()
	await _frames(5)
	print("PAUSE opened paused=", paused, " mouse_visible=", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	await _shot("pause.png")
	var pm := root.get_node("PauseMenu")
	pm._open_settings()
	await _frames(5)
	settings.set_value("display/show_fps", true)
	await _frames(5)
	await _shot("pause_settings.png")
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	print("SETTINGS saved show_fps=", cfg.get_value("display", "show_fps", "missing"))
	_press_esc()
	await _frames(3)
	print("ESC closes settings first: menu_visible=", pm._root.visible, " settings_open=", pm._settings != null)
	_press_esc()
	await _frames(3)
	print("RESUME paused=", paused, " menu_visible=", pm._root.visible)
	change_scene_to_file("res://scenes/menu/main_menu.tscn")
	await _frames(10)
	current_scene._open_settings()
	await _frames(5)
	await _shot("main_settings.png")
	# คืนค่าที่เทสเปลี่ยนไป ไม่ให้ค้างในเครื่องเจ้าของ
	settings.set_value("display/show_fps", old_fps)
	quit()


func _press_esc() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(_dir + name)


func _frames(n: int) -> void:
	for i in n:
		await process_frame
