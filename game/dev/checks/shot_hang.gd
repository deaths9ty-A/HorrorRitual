extends SceneTree
## ถ่ายภาพตอนห้อยเกาะขอบ (เครื่องมือของนักพัฒนา) · รัน: Godot --path game -s res://dev/checks/shot_hang.gd -- --shot=ภาพ.png

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://hang.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			out = a.substr(7)
	var scene: Node = load("res://scenes/chase/chasm_jumps.tscn").instantiate()
	root.add_child(scene)
	var p: Player = scene.get_node("Player")
	for i in 30:
		await physics_frame
	p.global_position = Vector3(0, -0.7, -12.9)
	p.velocity = Vector3.ZERO
	p.get_node("Head").rotation.x = deg_to_rad(-5)
	Input.action_press("grab")
	Input.action_press("move_forward")
	for i in 20:
		await physics_frame
		if (p.get_node("LedgeClimb") as LedgeClimb).mode == LedgeClimb.Mode.HANGING:
			break
	Input.action_release("move_forward")
	for i in 30:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	print("SHOT ", out, " mode=", (p.get_node("LedgeClimb") as LedgeClimb).mode)
	Input.action_release("grab")
	quit()
