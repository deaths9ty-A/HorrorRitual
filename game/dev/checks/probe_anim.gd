extends SceneTree
## วัดความสมูทของมอน (เครื่องมือของนักพัฒนา): นับการสลับท่า การกระโดดของความเร็ว และการหมุนกระตุก
## รัน: Godot --headless --path game -s res://dev/checks/probe_anim.gd

var _scene: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	for pair in [["NoiseBus", "res://systems/noise_bus.gd"], ["Checkpoints", "res://systems/checkpoints.gd"]]:
		if root.get_node_or_null(pair[0]) == null:
			var n: Node = load(pair[1]).new()
			n.name = pair[0]
			root.add_child(n)
	await _monster_case("lair_hearing.tscn", "janitor patrol", 480, func(_m, _p): pass)
	await _monster_case("kitchen_sight.tscn", "chef patrol", 480, func(_m, _p): pass)
	await _monster_case("lair_hearing.tscn", "janitor chase", 300, func(m, p):
		p.global_position = m.global_position + Vector3(0, 0, 6)
		root.get_node("NoiseBus").emit_noise(p.global_position, 8.0, p))
	await _path_case()
	quit()


func _load(path: String) -> void:
	if _scene:
		_scene.queue_free()
		await process_frame
	_scene = load("res://scenes/chase/" + path).instantiate()
	root.add_child(_scene)
	for i in 30:
		await physics_frame


func _monster_case(path: String, label: String, frames: int, setup: Callable) -> void:
	await _load(path)
	var m: Monster = get_nodes_in_group("monster").filter(func(x): return _scene.is_ancestor_of(x))[0]
	var p: Player = _scene.get_node("Player")
	setup.call(m, p)
	var anim: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	var last_clip := ""
	var clip_changes := 0
	var last_pos := m.global_position
	var last_speed := 0.0
	var max_accel := 0.0
	var accels := []
	var max_rate_step := 0.0
	var last_yaw := m.rotation.y
	var max_turn := 0.0
	var scale_changes := 0
	var last_scale := anim.speed_scale
	var log := []
	for i in frames:
		await physics_frame
		var hd := m.global_position - last_pos
		hd.y = 0.0
		var spd := hd.length() * 60.0
		if i > 10:
			accels.append(absf(spd - last_speed) * 60.0)
			max_accel = maxf(max_accel, accels[-1])
		last_speed = spd
		last_pos = m.global_position
		max_turn = maxf(max_turn, absf(wrapf(m.rotation.y - last_yaw, -PI, PI)) * 60.0)
		last_yaw = m.rotation.y
		if anim.current_animation != last_clip:
			clip_changes += 1
			log.append("%d:%s(%s)" % [i, anim.current_animation, Monster.State.keys()[m.state]])
			last_clip = anim.current_animation
		max_rate_step = maxf(max_rate_step, absf(anim.speed_scale - last_scale))
		last_scale = anim.speed_scale
	accels.sort()
	print("ANIM ", label, " clip_changes=", clip_changes, " max_rate_step_per_frame=", snappedf(max_rate_step, 0.001),
		" accel_p95=", snappedf(accels[int(accels.size() * 0.95)], 0.1), " max_accel=", snappedf(max_accel, 0.1), " m/s2 max_turn=", snappedf(rad_to_deg(max_turn), 1), " deg/s  log=", log.slice(0, 10))


func _path_case() -> void:
	await _load("corridor_path_chase.tscn")
	var ch: PathChaser = _scene.get_node("ChasePath/Chaser")
	# ผู้เล่นอยู่ไกลสุดโถง ไม่ให้ถูกจับก่อนวัดครบ
	(_scene.get_node("Player") as Node3D).global_position = Vector3(0, 0, -19.5)
	ch.start()
	var anim: AnimationPlayer = ch.find_children("*", "AnimationPlayer", true, false)[0]
	var rates := []
	var last := ch.global_position
	var last_yaw := ch.global_rotation.y
	var max_step := 0.0
	var max_turn := 0.0
	var max_dy := 0.0
	for i in 400:
		await physics_frame
		var d := ch.global_position - last
		max_step = maxf(max_step, d.length())
		max_dy = maxf(max_dy, absf(d.y))
		max_turn = maxf(max_turn, absf(wrapf(ch.global_rotation.y - last_yaw, -PI, PI)))
		last = ch.global_position
		last_yaw = ch.global_rotation.y
		if i % 20 == 0:
			rates.append(snappedf(anim.speed_scale, 0.01))
		if ch.state != Monster.State.CHASE:
			break
	print("PATH max_step_per_frame=", snappedf(max_step, 0.001), " m (ความเร็วเต็ม ", ch.speed / 60.0, ") max_dy=", snappedf(max_dy, 0.001),
		" m/frame max_turn=", snappedf(rad_to_deg(max_turn), 1), " deg/frame frames_run=", rates.size() * 20, " anim_rate_every_20f=", rates)
