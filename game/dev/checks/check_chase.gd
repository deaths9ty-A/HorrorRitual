extends SceneTree
## เทสกันพังของฉากไล่ล่า (ไม่ใช่หลักฐานว่าเล่นสนุกหรือน่ากลัว) · รัน: Godot --headless --path game -s res://dev/checks/check_chase.gd

var _scene: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	_ensure_autoloads()
	await _lair()
	await _kitchen()
	await _dining()
	await _ward()
	await _corridor()
	quit()


# โหมด -s อาจยังไม่มี Autoload ใส่ให้เองถ้าไม่มี
func _ensure_autoloads() -> void:
	for pair in [["NoiseBus", "res://systems/noise_bus.gd"], ["Checkpoints", "res://systems/checkpoints.gd"]]:
		if root.get_node_or_null(pair[0]) == null:
			var n: Node = load(pair[1]).new()
			n.name = pair[0]
			root.add_child(n)
	print("autoloads ok: ", root.get_node_or_null("NoiseBus") != null)


func _load(path: String) -> void:
	if _scene:
		_scene.queue_free()
		await process_frame
	_scene = load(path).instantiate()
	root.add_child(_scene)
	await _frames(30)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _monsters() -> Array:
	return get_nodes_in_group("monster").filter(func(m): return _scene.is_ancestor_of(m))


func _player() -> Player:
	return _scene.get_node("Player") as Player


func _lair() -> void:
	await _load("res://scenes/chase/lair_hearing.tscn")
	var m: Monster = _monsters()[0]
	var p0 := m.global_position
	await _frames(120)
	print("LAIR patrol_moved_m=", snappedf(m.global_position.distance_to(p0), 0.01), " state=", Monster.State.keys()[m.state])
	root.get_node("NoiseBus").emit_noise(m.global_position + Vector3(2, 0, 0), 5.0, null)
	await _frames(2)
	print("LAIR heard_object_noise state=", Monster.State.keys()[m.state], " (ควร INVESTIGATE)")
	var pl := _player()
	pl.global_position = m.global_position + Vector3(0, 0, 3)
	await _frames(5)
	root.get_node("NoiseBus").emit_noise(pl.global_position, 6.0, pl)
	await _frames(2)
	print("LAIR heard_player state=", Monster.State.keys()[m.state], " (ควร CHASE เพราะตาบอดไล่ด้วยหู)")
	await _frames(90)
	print("LAIR caught=", pl.get("_caught"), " (ควร true)")


func _kitchen() -> void:
	await _load("res://scenes/chase/kitchen_sight.tscn")
	var m: Monster = _monsters()[0]
	var pl := _player()
	# ยืนโล่งตรงหน้ามอน
	pl.global_position = m.global_position - m.global_basis.z * 5.0
	await _frames(5)
	print("KITCHEN sees_open state=", Monster.State.keys()[m.state], " (ควร CHASE)")


func _dining() -> void:
	await _load("res://scenes/chase/dining_stampede.tscn")
	var ms := _monsters()
	await _frames(60)
	var chasing := ms.filter(func(g): return g.state == Monster.State.CHASE).size()
	print("DINING before_trigger chasing=", chasing, "/", ms.size(), " (ควร 0)")
	var trig := _scene.get_node("WakeGuests")
	trig._on_enter(_player())
	await _frames(5)
	chasing = ms.filter(func(g): return g.state == Monster.State.CHASE).size()
	print("DINING after_trigger chasing=", chasing, "/", ms.size(), " (ควรทั้งหมด)")


func _ward() -> void:
	await _load("res://scenes/chase/ward_light_freeze.tscn")
	var ms := _monsters()
	var pl := _player()
	var awake := ms.filter(func(g): return g.state == Monster.State.CHASE).size()
	print("WARD at_spawn chasing=", awake, " (ควร 0 · ตัวที่อยู่ในวงไฟเพดานจะเป็น FROZEN)")
	# เลือกหุ่นที่ไม่ได้อยู่ในวงไฟเพดาน (ยังหลับ)
	var m: Monster = ms.filter(func(g): return g.state == Monster.State.IDLE)[0]
	pl.global_position = m.global_position + Vector3(0, 0, 5)
	await _frames(30)
	var d0 := m.global_position.distance_to(pl.global_position)
	print("WARD dark state=", Monster.State.keys()[m.state], " dist_after_0.5s=", snappedf(d0, 0.1), " (ควร CHASE และน้อยกว่า 5)")
	var lighter := pl.get_node("Head/Camera3D/Lighter") as OmniLight3D
	lighter.visible = true
	await _frames(10)
	var pos := m.global_position
	await _frames(30)
	print("WARD lit state=", Monster.State.keys()[m.state], " moved_m=", snappedf(m.global_position.distance_to(pos), 0.01), " (ควร FROZEN, 0)")


func _corridor() -> void:
	await _load("res://scenes/chase/corridor_path_chase.tscn")
	var ch: PathChaser = _scene.get_node("ChasePath/Chaser")
	var trig := _scene.get_node("StartChase")
	trig._on_enter(_player())
	await _frames(90)
	print("CORRIDOR chaser_state=", Monster.State.keys()[ch.state], " progress_m=", snappedf(ch.progress, 0.1))
