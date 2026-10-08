extends SceneTree
## ถ่ายภาพจากตำแหน่งที่กำหนด (เครื่องมือของนักพัฒนา)
## รัน: Godot --path game -s res://dev/checks/shot_at.gd -- --scene=res://... --pos=x,y,z --shot=ภาพ.png

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var path := ""
	var pos := Vector3.ZERO
	var out := "user://shot.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			path = a.substr(8)
		elif a.begins_with("--pos="):
			var v := a.substr(6).split(",")
			pos = Vector3(float(v[0]), float(v[1]), float(v[2]))
		elif a.begins_with("--shot="):
			out = a.substr(7)
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	var p := scene.get_node("Player") as Node3D
	for i in 20:
		await physics_frame
	p.global_position = pos
	for i in 40:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	print("SHOT ", out)
	quit()
