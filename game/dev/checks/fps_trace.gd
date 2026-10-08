extends SceneTree
## พิมพ์ FPS ทุกวินาที และเฟรมที่นานเกิน 50 ms (เครื่องมือของนักพัฒนา)
## รัน: Godot --path game -s res://dev/checks/fps_trace.gd -- --scene=res://...

func _initialize() -> void:
	var path := "res://scenes/menu/main_menu.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			path = a.substr(8)
	root.add_child(load(path).instantiate())
	var t0 := Time.get_ticks_msec()
	var last := t0
	var per_sec := []
	for i in 600:
		await process_frame
		var now := Time.get_ticks_msec()
		if now - last > 50:
			print("SLOW frame ", i, " at ", (now - t0) / 1000.0, "s took ", now - last, " ms")
		last = now
		if i % 60 == 0:
			per_sec.append(Engine.get_frames_per_second())
	print("PER_SEC ", per_sec)
	quit()
