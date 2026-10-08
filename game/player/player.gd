class_name Player
extends CharacterBody3D
## ตัวเอกมุมมองบุคคลที่หนึ่ง: เดิน วิ่ง ย่อ กระโดด หันกล้องด้วยเมาส์
## ชุดท่าก็อปจาก Little Nightmares (วิ่ง กระโดด ย่อ ปีน จับลาก ขว้าง ไฟแช็ก) ปรับเป็นมุมบุคคลที่หนึ่ง

## ส่งตอนเท้าแตะพื้นหลังลอยอยู่ (ความเร็วตกเป็นเมตร/วินาที) ให้กล้องยุบตาม
signal landed(fall_speed: float)

@export_group("ความเร็ว")
## ความเร็วเดิน (เมตร/วินาที) · ค่าที่เจ้าของเคยเทสผ่านในโปรเจกต์เก่า
@export var walk_speed := 4.0
## ความเร็ววิ่ง (เมตร/วินาที) · ค่าที่เจ้าของเคยเทสผ่านในโปรเจกต์เก่า
@export var run_speed := 6.5
## ความเร็วตอนย่อ (เมตร/วินาที) · ค่าที่เจ้าของเคยเทสผ่านในโปรเจกต์เก่า
@export var crouch_speed := 2.0
## ออกตัวเร็วแค่ไหน (เมตร/วินาที²) ยิ่งน้อยยิ่งมีน้ำหนัก (14 ≈ ถึงความเร็วเดินใน 0.3 วิ) · ค่าเริ่มที่ Claude ตั้ง
@export var ground_accel := 14.0
## หยุดเร็วแค่ไหน (เมตร/วินาที²) ยิ่งน้อยยิ่งไถลต่อ · ค่าเริ่มที่ Claude ตั้ง
@export var ground_decel := 18.0
## ควบคุมทิศกลางอากาศได้แค่ไหน (0 = ไม่ได้เลย, 1 = เท่าบนพื้น) · ค่าเริ่มที่ Claude ตั้ง
@export_range(0.0, 1.0) var air_control := 0.3

@export_group("กระโดด")
## กระโดดสูงสุดกี่เมตร · ค่าเริ่มที่ Claude ตั้ง
@export var jump_height := 0.7
## ใช้เวลากี่วินาทีถึงจุดสูงสุด ยิ่งน้อยยิ่งกระโดดไว ไม่ลอย · ค่าเริ่มที่ Claude ตั้ง
@export var jump_time_to_apex := 0.32
## ตอนตกแรงโน้มถ่วงคูณเพิ่มกี่เท่า (มากกว่า 1 = ตกไวกว่าขึ้น ไม่ลอย) · ค่าเริ่มที่ Claude ตั้ง
@export var fall_gravity_scale := 1.7
## เดินตกขอบไปแล้วยังกดกระโดดได้อีกกี่วินาที · ค่าเริ่มที่ Claude ตั้ง
@export var coyote_time := 0.1
## กดกระโดดก่อนเท้าแตะพื้นได้เร็วสุดกี่วินาที แล้วจะกระโดดให้ตอนแตะพื้น · ค่าเริ่มที่ Claude ตั้ง
@export var jump_buffer := 0.12

@export_group("ช่วยข้าม")
## วิ่ง (ค้าง Shift) เข้าหาสิ่งกีดขวางแล้วข้ามหรือปีนเอง ไม่ต้องกดกระโดด
@export var auto_traverse_when_running := true
## กดกระโดดก่อนถึงสิ่งกีดขวาง จำไว้นานกี่วินาที แล้วปีน/ข้ามให้เมื่อถึงระยะ · ค่าเริ่มที่ Claude ตั้ง
@export var climb_buffer_time := 0.6
## เดินเข้าหาที่เตี้ย (คาน ช่องลอด) แล้วย่อมุดให้เอง ผ่านแล้วลุกเอง
@export var auto_duck := true
## ตรวจที่เตี้ยข้างหน้าล่วงหน้ากี่เมตร
@export var duck_lookahead := 0.9

@export_group("ตก")
## ตกจากที่สูงเกินกี่เมตรแล้วตาย (วัดจากจุดสูงสุดที่ลอยถึง) · ค่าเริ่มที่ Claude ตั้ง
@export var lethal_fall_height := 6.0
## ตกต่ำกว่าระดับนี้ (เมตร) = ตายแน่นอน กันตกทะลุโลก
@export var kill_floor_y := -40.0

@export_group("ย่อ")
## ความสูงตัวตอนยืน (เมตร)
@export var stand_height := 1.7
## ความสูงตัวตอนย่อ (เมตร)
@export var crouch_height := 1.0
## ตาอยู่ต่ำกว่าหัวกี่เมตร
@export var eye_below_top := 0.1
## ย่อและลุกนุ่มแค่ไหน ยิ่งมากยิ่งไว (ค่อย ๆ ช้าลงตอนใกล้ถึง ไม่หยุดกึก) · ค่าเริ่มที่ Claude ตั้ง
@export var crouch_smoothing := 10.0

@export_group("เมาส์")
## ความไวเมาส์
@export var mouse_sensitivity := 0.002
## ก้มและเงยได้สุดกี่องศา
@export var max_pitch_deg := 85.0

## ตัวคูณความเร็วที่ระบบอื่นตั้ง เช่น ตอนลากของหนัก (ไม่ต้องแก้เอง)
var speed_scale := 1.0
## ปิดการควบคุมชั่วคราว เช่น ตอนกำลังปีน
var control_enabled := true
var is_crouching := false
## ที่ซ่อนแต่ละอันโหวตว่าผู้เล่นซ่อนอยู่ไหม (HideSpot ตั้งให้ ไม่ต้องแก้เอง)
var hide_votes := {}
## ผู้เล่นซ่อนอยู่ = มอนที่ใช้ตามองไม่เห็น
var is_hidden: bool:
	get:
		return hide_votes.values().has(true)
## ตัดสัญญาณโหลดฉากซ้ำตอนถูกจับ
var _caught := false

var _height: float
var _rise_gravity: float
var _jump_speed: float
var _since_floor := 0.0
var _since_jump_press := 999.0
var _was_on_floor := true
var _air_peak_y := 0.0
var _climb_buffer := 0.0
var _auto_ducking := false

@onready var _shape: CollisionShape3D = $CollisionShape3D
@onready var _head: Node3D = $Head
@onready var _ledge: LedgeClimb = $LedgeClimb


func _ready() -> void:
	add_to_group("player")
	_height = stand_height
	_apply_height()
	# คำนวณแรงโน้มถ่วงกับความเร็วกระโดดจากความสูงและเวลา (วิธีจาก GDC 2016 "Building a Better Jump")
	_rise_gravity = 2.0 * jump_height / (jump_time_to_apex * jump_time_to_apex)
	_jump_speed = 2.0 * jump_height / jump_time_to_apex
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# คลิกในหน้าต่างเพื่อจับเมาส์กลับมา
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and control_enabled:
		# ความไวและการกลับแกนจากหน้าตั้งค่า (Autoload Settings)
		var settings := get_node_or_null("/root/Settings")
		var sens := mouse_sensitivity * (float(settings.get_value("controls/mouse_sensitivity")) if settings else 1.0)
		var flip := -1.0 if settings and settings.get_value("controls/invert_y") else 1.0
		rotate_y(-event.relative.x * sens)
		var limit := deg_to_rad(max_pitch_deg)
		_head.rotation.x = clampf(_head.rotation.x - event.relative.y * sens * flip, -limit, limit)


func _physics_process(delta: float) -> void:
	if not control_enabled:
		_was_on_floor = true
		return
	_update_crouch(delta)
	_since_floor = 0.0 if is_on_floor() else _since_floor + delta
	_since_jump_press = 0.0 if Input.is_action_just_pressed("jump") else _since_jump_press + delta

	# แรงโน้มถ่วง: ตอนตกแรงกว่าตอนขึ้น จะได้ไม่ลอย
	if not is_on_floor():
		var g := _rise_gravity if velocity.y > 0.0 else _rise_gravity * fall_gravity_scale
		velocity.y -= g * delta

	# บนพื้น: กดกระโดดหน้าขอบ = ปีนหรือข้าม · กลางอากาศ: เดินหน้าชนขอบ = ปีนเอง (กดจับค้าง = เกาะขอบสูง)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		if _ledge.try_climb(true):
			return
		# กดก่อนถึงสิ่งกีดขวาง: จำไว้ ไม่กระโดดเปล่า แล้วปีน/ข้ามให้เมื่อถึงระยะ
		if _ledge.ledge_ahead():
			_climb_buffer = climb_buffer_time
			_since_jump_press = 999.0
	elif _climb_buffer > 0.0:
		_climb_buffer -= delta
		if _ledge.try_climb(is_on_floor()):
			_climb_buffer = 0.0
			return
	# วิ่งค้าง Shift เข้าหาสิ่งกีดขวาง = ข้ามหรือปีนเองไม่ต้องกดกระโดด (แบบ Assassin's Creed ที่กดค้างตอนวิ่งแล้วข้ามเอง)
	elif is_on_floor() and auto_traverse_when_running and Input.is_action_pressed("run") and input.y < -0.3 and not is_crouching:
		if _ledge.try_climb(true):
			return
	elif not is_on_floor() and input.y < -0.3:
		if _ledge.try_climb(false):
			return
	if _since_jump_press <= jump_buffer and _since_floor <= coyote_time and not is_crouching and velocity.y <= 0.0:
		velocity.y = _jump_speed
		_since_jump_press = 999.0
		_since_floor = 999.0

	var dir := global_basis * Vector3(input.x, 0.0, input.y)
	dir.y = 0.0
	dir = dir.normalized()
	var target := dir * _current_speed() * speed_scale
	var rate := ground_accel if target.length() > 0.01 else ground_decel
	if not is_on_floor():
		rate *= air_control
	var flat := Vector2(velocity.x, velocity.z).move_toward(Vector2(target.x, target.z), rate * delta)
	velocity.x = flat.x
	velocity.z = flat.y

	var fall_speed := -velocity.y
	move_and_slide()
	# ก้าวขึ้นขั้นเตี้ยเองตอนเดินชน
	if is_on_floor() and is_on_wall() and input.length() > 0.1:
		_ledge.try_step()
	if not is_on_floor():
		_air_peak_y = maxf(_air_peak_y, global_position.y) if not _was_on_floor else global_position.y
	if is_on_floor() and not _was_on_floor:
		landed.emit(fall_speed)
		if _air_peak_y - global_position.y >= lethal_fall_height:
			die()
	if global_position.y < kill_floor_y:
		die()
	_was_on_floor = is_on_floor()


## ตำแหน่งตา (มอนใช้เช็กว่ามองเห็นไหม)
func eye_position() -> Vector3:
	return _head.global_position


## ตาย (ตกเหว ตกจากที่สูง หรือถูกจับ): หยุดควบคุม แล้วให้ Checkpoints เริ่มใหม่ที่เช็กพอยต์
func die() -> void:
	if _caught:
		return
	_caught = true
	control_enabled = false
	velocity = Vector3.ZERO
	get_node("/root/Checkpoints").player_died()


## ถูกมอนจับ: หันหน้าเข้าหามอนแล้วตาย
func get_caught(by: Node3D) -> void:
	if _caught:
		return
	var look := by.global_position + Vector3.UP * 1.5
	var flat := look - global_position
	var yaw := atan2(-flat.x, -flat.z)
	var pitch := atan2(look.y - _head.global_position.y, Vector2(flat.x, flat.z).length())
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "rotation:y", yaw, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_head, "rotation:x", pitch, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	die()


## ตัวผู้เล่นสูง height ยืนที่ feet ได้ไหม (ไม่ชนอะไร)
func fits_at(feet: Vector3, height: float) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = (_shape.shape as CapsuleShape3D).radius
	capsule.height = height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	# ยกขึ้น 5 ซม. ไม่ให้ไปชนพื้นที่ยืนอยู่
	query.transform = Transform3D(Basis(), feet + Vector3.UP * (height * 0.5 + 0.05))
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## บังคับให้อยู่ในท่าย่อทันที (ใช้ตอนปีนขึ้นที่เตี้ย)
func force_crouch() -> void:
	is_crouching = true
	_height = crouch_height
	_apply_height()


func _current_speed() -> float:
	if is_crouching:
		return crouch_speed
	if Input.is_action_pressed("run"):
		return run_speed
	return walk_speed


func _update_crouch(delta: float) -> void:
	_update_auto_duck()
	if Input.is_action_pressed("crouch") or _auto_ducking:
		is_crouching = true
	elif is_crouching and fits_at(global_position, stand_height):
		# ลุกได้เฉพาะตอนเหนือหัวว่าง
		is_crouching = false
	var target := crouch_height if is_crouching else stand_height
	# เข้าหาเป้าแบบค่อย ๆ ช้าลง (ไม่หยุดกึก)
	_height = lerpf(_height, target, 1.0 - exp(-crouch_smoothing * delta))
	_apply_height()


func _apply_height() -> void:
	var capsule := _shape.shape as CapsuleShape3D
	capsule.height = _height
	_shape.position.y = _height * 0.5
	_head.position.y = _height - eye_below_top


# เดินเข้าหาที่เตี้ย: ข้างหน้ายืนไม่พอแต่ย่อพอ = ย่อมุดให้เอง · ผ่านแล้ว (ตรงนี้และข้างหน้ายืนได้) = เลิกย่อเอง
func _update_auto_duck() -> void:
	if not auto_duck or not is_on_floor():
		return
	var move := Vector2(velocity.x, velocity.z)
	if move.length() < 0.5:
		return
	var ahead := global_position + Vector3(move.x, 0.0, move.y).normalized() * duck_lookahead
	if not _auto_ducking:
		if not fits_at(ahead, stand_height) and fits_at(ahead, crouch_height):
			_auto_ducking = true
			var cam := get_node_or_null("Head/Camera3D")
			if cam and cam.has_method("kick"):
				cam.kick(0.04, 4.0)
	elif fits_at(global_position, stand_height) and fits_at(ahead, stand_height):
		_auto_ducking = false
