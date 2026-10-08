extends SceneTree
## เทสกันพังของด่านเหว: กดปุ่มจำลอง (ไม่ใช่หลักฐานว่าเล่นแล้วรู้สึกดี)
## รัน: Godot --headless --path game -s res://dev/checks/check_chasm.gd

var _scene: Node
var p: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	for pair in [["NoiseBus", "res://systems/noise_bus.gd"], ["Checkpoints", "res://systems/checkpoints.gd"]]:
		if root.get_node_or_null(pair[0]) == null:
			var n: Node = load(pair[1]).new()
			n.name = pair[0]
			root.add_child(n)
	await _reset(Vector3(0, 0, 14.5))
	await _jump_gap("GAP1_walk_2m", false, 12.3, 10.0)
	await _reset(Vector3(0, 0, 8.5))
	await _jump_gap("GAP2_run_3.2m", true, 2.3, -1.2)
	await _reset(Vector3(0, 0, -1.8))
	await _vault()
	await _reset(Vector3(0, 0, -1.8))
	await _auto_vault()
	await _reset(Vector3(0, 0, -1.6))
	await _early_jump()
	await _heartbeat()
	await _reset(Vector3(0, 1.4, -32.6))
	await _auto_duck()
	await _reset(Vector3(0, 0, -8.0))
	await _ledge()
	await _reset(Vector3(0, 0, 3.0))
	await _fall()
	await _reset(Vector3(0, 0, -8.0))
	p.global_position = Vector3(0, -0.7, -12.9)
	p.velocity = Vector3.ZERO
	await _hang()
	quit()


func _reset(pos: Vector3) -> void:
	_release_all()
	if _scene:
		_scene.queue_free()
		await process_frame
	_scene = load("res://scenes/chase/chasm_jumps.tscn").instantiate()
	root.add_child(_scene)
	p = _scene.get_node("Player")
	p.global_position = pos
	p.rotation.y = 0.0
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _release_all() -> void:
	for a in ["move_forward", "run", "jump", "grab"]:
		Input.action_release(a)


## วิ่ง/เดินไปข้างหน้า กดกระโดดเมื่อถึง jump_z แล้วดูว่าตกถึงแท่นถัดไป (z < land_z) โดยไม่ตกเหว
func _jump_gap(label: String, run: bool, jump_z: float, land_z: float) -> void:
	Input.action_press("move_forward")
	if run:
		Input.action_press("run")
	for i in 240:
		await physics_frame
		if p.global_position.z <= jump_z:
			Input.action_press("jump")
			await physics_frame
			Input.action_release("jump")
			break
	await _frames(90)
	_release_all()
	await _frames(10)
	print(label, " z=", snappedf(p.global_position.z, 0.1), " y=", snappedf(p.global_position.y, 0.1),
		" landed_ok=", p.global_position.z < land_z and p.global_position.y > -0.5, " dead=", p.get("_caught"))


func _vault() -> void:
	Input.action_press("move_forward")
	Input.action_press("run")
	var vaulted := false
	var speed_before := 0.0
	for i in 180:
		await physics_frame
		if p.global_position.z < -4.4 and not vaulted:
			speed_before = Vector2(p.velocity.x, p.velocity.z).length()
			Input.action_press("jump")
			await physics_frame
			Input.action_release("jump")
			vaulted = true
		if vaulted and p.global_position.z < -6.2:
			break
	await _frames(3)
	var speed_after := Vector2(p.velocity.x, p.velocity.z).length()
	_release_all()
	print("VAULT passed_wall=", p.global_position.z < -6.0, " speed_before=", snappedf(speed_before, 0.1),
		" speed_after=", snappedf(speed_after, 0.1), " (หลังข้ามควรยังเร็วใกล้เดิม)")


func _ledge() -> void:
	var lc: LedgeClimb = p.get_node("LedgeClimb")
	Input.action_press("move_forward")
	Input.action_press("run")
	Input.action_press("grab")
	var saw_hang := false
	var saw_climb := false
	for i in 240:
		await physics_frame
		if p.global_position.z <= -9.7 and p.is_on_floor():
			Input.action_press("jump")
			await physics_frame
			Input.action_release("jump")
		if lc.mode == LedgeClimb.Mode.HANGING:
			saw_hang = true
			Input.action_press("jump")
		if lc.mode == LedgeClimb.Mode.CLIMBING:
			saw_climb = true
		if p.global_position.y > 1.3 and p.is_on_floor() and lc.mode == LedgeClimb.Mode.NONE:
			break
	_release_all()
	await _frames(5)
	var floor_name := "-"
	for i in p.get_slide_collision_count():
		var c := p.get_slide_collision(i)
		if c.get_normal().y > 0.7:
			floor_name = str(c.get_collider().name)
	print("LEDGE standing_on=", floor_name)
	print("LEDGE hang=", saw_hang, " climb=", saw_climb, " on_P4=", p.global_position.y > 1.3,
		" y=", snappedf(p.global_position.y, 0.1), " z=", snappedf(p.global_position.z, 0.1), " dead=", p.get("_caught"))


## ลอยอยู่ต่ำกว่าขอบ 2 ม. + กดจับค้าง + เดินหน้า = ต้องห้อยตัว · แล้วกดกระโดด = ดึงขึ้น
func _hang() -> void:
	var lc: LedgeClimb = p.get_node("LedgeClimb")
	Input.action_press("grab")
	Input.action_press("move_forward")
	var hung := false
	for i in 60:
		await physics_frame
		if lc.mode == LedgeClimb.Mode.HANGING:
			hung = true
			break
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame
	var hold_y := p.global_position.y
	await _frames(30)
	var still := absf(p.global_position.y - hold_y) < 0.05
	var arms := p.get_node("Head/Camera3D/Arms") as Node3D
	var arms_visible := arms.visible
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await _frames(70)
	_release_all()
	await _frames(5)
	print("HANG hung=", hung, " stayed_still=", still, " arms_visible=", arms_visible, " pulled_up_y=", snappedf(p.global_position.y, 0.1),
		" (ควร ~1.4) dead=", p.get("_caught"))


func _fall() -> void:
	# เดินออกด้านข้างไม่ได้ (มีผนัง) จึงเดินตกช่อง GAP2 โดยไม่กระโดด
	Input.action_press("move_forward")
	for i in 300:
		await physics_frame
		if p.get("_caught"):
			break
	_release_all()
	print("FALL dead=", p.get("_caught"), " y=", snappedf(p.global_position.y, 0.1))


## วิ่งค้าง Shift เข้าหากำแพงเตี้ยโดยไม่กดกระโดด = ต้องข้ามเอง
func _auto_vault() -> void:
	Input.action_press("move_forward")
	Input.action_press("run")
	for i in 120:
		await physics_frame
		if p.global_position.z < -6.2:
			break
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	_release_all()
	print("AUTO_VAULT passed_wall=", p.global_position.z < -6.0, " speed_after=", snappedf(speed, 0.1), " (ไม่ได้กดกระโดดเลย)")


## มอนไล่ตามเส้นทาง (PROXIMITY): ยิ่งเข้าใกล้ หัวใจยิ่งแรง
func _heartbeat() -> void:
	var ch: PathChaser = _scene.get_node("ChasePath/Chaser")
	p.global_position = Vector3(0, 1.4, -22)
	await _frames(5)
	print("HEART before_start=", snappedf(ch.heartbeat_level(p.global_position), 0.01), " (ควร 0)")
	ch.start()
	var levels := []
	for i in 4:
		await _frames(30)
		levels.append(snappedf(ch.heartbeat_level(p.global_position), 0.01))
	print("HEART approaching=", levels, " (ควรเพิ่มขึ้นเรื่อย ๆ)")


## เดิน (ไม่วิ่ง) แล้วกดกระโดดตอนยังห่างกำแพงเตี้ย ~2 ม. = ต้องจำไว้แล้วปีน/ข้ามให้เมื่อถึงระยะ
func _early_jump() -> void:
	var lc: LedgeClimb = p.get_node("LedgeClimb")
	Input.action_press("move_forward")
	var pressed_at := 0.0
	var climbed := false
	for i in 240:
		await physics_frame
		if pressed_at == 0.0 and p.global_position.z <= -3.3:
			pressed_at = p.global_position.z
			Input.action_press("jump")
			await physics_frame
			Input.action_release("jump")
		if lc.mode != LedgeClimb.Mode.NONE:
			climbed = true
		if p.global_position.z < -6.2:
			break
	_release_all()
	print("EARLY_JUMP pressed_at_z=", snappedf(pressed_at, 0.1), " wall_at_z=-5.3 climbed=", climbed, " passed=", p.global_position.z < -6.0)


## เดินเข้าหาคานเตี้ยโดยไม่กดย่อ = ต้องย่อมุดเอง แล้วลุกเองเมื่อพ้น
func _auto_duck() -> void:
	Input.action_press("move_forward")
	var ducked := false
	for i in 200:
		await physics_frame
		if p.is_crouching:
			ducked = true
		if p.global_position.z < -37.0:
			break
	await _frames(40)
	_release_all()
	print("AUTO_DUCK ducked=", ducked, " passed_beam=", p.global_position.z < -36.0, " stood_after=", not p.is_crouching)
