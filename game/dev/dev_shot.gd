extends Node
## เครื่องมือของนักพัฒนา: ถ่ายภาพหน้าจอแล้วปิดเกม (ไม่มีผลตอนเล่นปกติ)
## ใช้: Godot --path game -- --shot=ภาพ.png [--frames=60]


func _ready() -> void:
	var path := ""
	var frames := 60
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			path = arg.substr(7)
		elif arg.begins_with("--frames="):
			frames = int(arg.substr(9))
	if path == "":
		return
	for i in frames:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	print("DEV_SHOT saved ", path)
	get_tree().quit()
