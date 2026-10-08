class_name Hand
extends Node
## มือของตัวเอก (แบบ Little Nightmares): กดค้างเพื่อจับ ปล่อยปุ่ม = วาง
## ของเล็ก = ยกขึ้นถือ แล้วคลิกขวาเพื่อขว้าง · ของหนัก = ลากไปตามพื้น ผู้เล่นเดินช้าลง

## ขว้างแรงแค่ไหน (เมตร/วินาที) · ค่าเริ่มที่ Claude ตั้ง
@export var throw_speed := 11.0
## ถ้าของหลุดห่างจากมือเกินนี้ (เมตร) จะปล่อยเอง เช่น ตอนของติดขอบ
@export var break_distance := 1.5
## ของต้องห่างจากมือเกิน break_distance ต่อเนื่องนานเท่านี้ (วินาที) ถึงจะหลุด (กันของหลุดตอนสะบัดเมาส์เร็ว) · ค่าเริ่มที่ Claude ตั้ง
@export var break_time := 0.25
## ของเล็กที่ปล่อยแล้วต้องห่างจากกลางตัวเกินนี้ (เมตร) ถึงจะกลับมาชนกับตัวผู้เล่น · ค่าเริ่มที่ Claude ตั้ง
@export var clear_distance := 1.2

@onready var _player: Player = get_parent()
@onready var _ray: RayCast3D = %InteractRay
@onready var _hold_point: Marker3D = %HoldPoint

## ของที่ถืออยู่ (null = มือว่าง)
var held: Grabbable
var _drag_distance := 0.0
var _far_time := 0.0
## ของเล็กที่เพิ่งปล่อย ยังไม่ชนกับตัวผู้เล่นจนกว่าจะออกห่าง (กันของดันตัวตอนปล่อยทับตัวเอง)
var _ghosts: Array[Grabbable] = []


func _ready() -> void:
	_ray.add_exception(_player)


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("grab"):
		_try_grab()
	elif event.is_action_released("grab"):
		release()
	elif event.is_action_pressed("throw"):
		_throw()


func _physics_process(delta: float) -> void:
	_restore_ghosts()
	if held == null:
		return
	var target: Vector3
	if held.heavy:
		# ของหนักอยู่หน้าตัวที่ระยะเดิม และอยู่บนพื้นเหมือนเดิม
		var fwd := -_player.global_basis.z
		fwd.y = 0.0
		target = _player.global_position + fwd.normalized() * _drag_distance
		target.y = held.global_position.y
	else:
		target = _hold_point.global_position
	held.hold_target = target
	if held.global_position.distance_to(target) > break_distance:
		_far_time += delta
	else:
		_far_time = 0.0
	if _far_time > break_time or not _player.control_enabled:
		release()


## ปล่อยของในมือ
func release() -> void:
	if held == null:
		return
	held.held = false
	if not held.heavy and not _ghosts.has(held):
		_ghosts.append(held)
	held = null
	_player.speed_scale = 1.0


func _try_grab() -> void:
	if held != null or not _player.control_enabled:
		return
	_ray.force_raycast_update()
	var obj := _ray.get_collider() as Grabbable
	if obj == null:
		return
	held = obj
	_far_time = 0.0
	obj.held = true
	obj.sleeping = false
	if not obj.heavy:
		# ของเล็กในมือไม่ชนกับตัวผู้เล่น (ไม่งั้นของจะดันตัวเราเอง) · ของหนักยังชนตามปกติ
		_player.add_collision_exception_with(obj)
		obj.add_collision_exception_with(_player)
		_ghosts.erase(obj)
	if obj.heavy:
		var flat := obj.global_position - _player.global_position
		flat.y = 0.0
		_drag_distance = flat.length()
		_player.speed_scale = obj.drag_speed_scale


func _throw() -> void:
	if held == null or held.heavy:
		return
	var obj := held
	release()
	var dir := -_hold_point.global_basis.z
	obj.linear_velocity = Vector3.ZERO
	obj.apply_central_impulse(dir * throw_speed * obj.mass)


# คืนการชนให้ของที่ปล่อยแล้ว เมื่อของออกห่างจากตัวผู้เล่นพ้นแล้ว
func _restore_ghosts() -> void:
	var body_center := _player.global_position + Vector3.UP * 0.85
	for obj in _ghosts.duplicate():
		if not is_instance_valid(obj):
			_ghosts.erase(obj)
		elif obj.global_position.distance_to(body_center) > clear_distance:
			_player.remove_collision_exception_with(obj)
			obj.remove_collision_exception_with(_player)
			_ghosts.erase(obj)
