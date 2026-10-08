extends SceneTree
## เทสกันพัง: ถูกจับแล้วโหลดฉากใหม่และเกิดที่เช็กพอยต์ · รัน: Godot --headless --path game -s res://dev/checks/check_respawn.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	change_scene_to_file("res://scenes/chase/lair_hearing.tscn")
	await _frames(40)
	var cp := root.get_node("Checkpoints")
	var pl := get_first_node_in_group("player") as Player
	var spawn := pl.global_position
	print("RESPAWN start scene=", current_scene.name, " spawn=", spawn.snappedf(0.1))
	pl.global_position += Vector3(0, 0, -6)
	await _frames(5)
	var m := get_first_node_in_group("monster") as Node3D
	pl.get_caught(m)
	await _frames(150)
	var pl2 := get_first_node_in_group("player") as Player
	print("RESPAWN after new_player=", pl2 != pl, " pos=", pl2.global_position.snappedf(0.1), " fade_alpha=", snappedf(cp._fade.color.a, 0.01))
	quit()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
