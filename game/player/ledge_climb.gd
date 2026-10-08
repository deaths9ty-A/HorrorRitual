class_name LedgeClimb
extends Node
## ปีน ข้าม และเกาะขอบ
## - ขอบเตี้ย + กำลังวิ่ง = ข้ามเร็วแล้ววิ่งต่อ ไม่เสียความเร็ว (แบบ Mirror's Edge ที่แก่นคือรักษาความเร็ว)
## - ขอบสูงไม่เกิน max_height = ปีนขึ้น (บนพื้นกดกระโดด · กลางอากาศชนขอบแล้วปีนเอง)
## - ขอบสูงกว่านั้นตอนลอยอยู่ + กดจับค้าง = ห้อยตัวเกาะขอบ (แบบ LN ที่ต้องกดจับค้างไว้ถึงจะเกาะ)
##   ห้อยอยู่: กดกระโดดหรือเดินหน้า = ดึงตัวขึ้น · ปล่อยปุ่มจับหรือกดย่อ = ปล่อยตัวลง
## - ขั้นเตี้ยมาก (ไม่เกิน step_height) = ก้าวขึ้นเองไม่ต้องกดอะไร
## ค่าทั้งหมดเป็นค่าเริ่มที่ Claude ตั้ง

enum Mode { NONE, CLIMBING, HANGING }

@export_group("ความสูง (เมตร วัดจากเท้า)")
## ก้าวขึ้นเองได้สูงสุด
@export var step_height := 0.35
## ต่ำกว่านี้ไม่นับเป็นขอบ
@export var min_height := 0.4
## ข้ามเร็วได้สูงสุด (ตอนวิ่ง)
@export var vault_max_height := 1.25
## ปีนขึ้นได้สูงสุด
@export var max_height := 1.6
## เกาะขอบได้สูงสุด (ตอนลอยอยู่)
@export var hang_max_height := 2.5

@export_group("ระยะและเวลา")
## เอื้อมไปข้างหน้าได้ไกลแค่ไหนตอนยืน (เมตร) · ยิ่งมากยิ่งกดปีนได้ไกลจากขอบ
@export var reach := 1.2
## วิ่งเร็วขึ้น ตรวจขอบล่วงหน้าไกลขึ้นกี่วินาที (กันวิ่งชนแล้วติด)
@export var lookahead_time := 0.2
## กลางอากาศเอื้อมได้ไกลแค่ไหน (สั้นกว่าบนพื้น ไม่ให้ตกช่องแล้วถูกดึงขึ้นฝั่งตรงข้ามง่ายเกินไป)
@export var air_reach := 0.7
## กดกระโดดตอนยังห่างสิ่งกีดขวางไม่เกินเท่านี้ (เมตร) = จำไว้ แล้วปีน/ข้ามให้เองเมื่อถึงระยะ (ไม่กระโดดเปล่า)
@export var approach_range := 3.0
## ต้องวิ่งเร็วกว่านี้ (เมตร/วินาที) ถึงจะข้ามเร็วแทนการปีน
@export var vault_min_speed := 3.0
## ข้ามเร็วใช้เวลากี่วินาที
@export var vault_time := 0.32
## เวลาปีนขั้นต่ำ (วินาที)
@export var climb_time_base := 0.35
## ขอบสูงขึ้นทุก 1 เมตร ปีนนานขึ้นกี่วินาที
@export var climb_time_per_meter := 0.35
## ดึงตัวขึ้นจากท่าห้อยใช้เวลากี่วินาที
@export var pull_up_time := 0.75
## ห้อยค้างอย่างน้อยกี่วินาที ก่อนที่การค้างปุ่มเดินหน้าจะดึงตัวขึ้นเอง (กดกระโดด = ดึงทันที)
@export var min_hang_time := 0.25
## ตอนเริ่มปีนกล้องก้มลงหาขอบกี่องศา
@export var climb_look_down_deg := 10.0

var mode := Mode.NONE

@onready var _player: Player = get_parent()
var _arms: Arms
var _ledge := {}
var _hang_time := 0.0


func _ready() -> void:
	_arms = _player.get_node_or_null("Head/Camera3D/Arms") as Arms


## ลองปีน/ข้าม/เกาะ ตรงหน้า · on_ground = กดกระโดดจากพื้น · คืน true ถ้าเริ่มแล้ว
func try_climb(on_ground: bool) -> bool:
	if mode != Mode.NONE:
		return false
	var limit := max_height
	var can_hang := not on_ground and Input.is_action_pressed("grab")
	if can_hang:
		limit = hang_max_height
	var l := _find_ledge(limit) if on_ground else _find_ledge(limit, -1.0, air_reach + Vector2(_player.velocity.x, _player.velocity.z).length() * 0.05)
	if l.is_empty():
		return false
	var h: float = l.height
	if h > max_height:
		if can_hang:
			_start_hang(l)
			return true
		return false
	var end_pos = _end_pos(l)
	if end_pos == null:
		return false
	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	if h <= vault_max_height and speed >= vault_min_speed:
		_vault(l, end_pos, speed)
	else:
		_mantle(l, end_pos)
	return true


## ข้างหน้าในระยะ approach_range มีสิ่งที่ปีน/ข้ามได้ไหม (ใช้ตัดสินว่ากดกระโดดตอนนี้ควรจำไว้รอปีน)
func ledge_ahead() -> bool:
	return not _find_ledge(max_height, -1.0, approach_range).is_empty()


## ก้าวขึ้นขั้นเตี้ย ๆ เอง (ผู้เล่นเรียกตอนเดินชนผนังบนพื้น)
func try_step() -> bool:
	if mode != Mode.NONE:
		return false
	var l := _find_ledge(step_height, 0.05)
	if l.is_empty() or not _player.fits_at(l.top + l.into * 0.3, _player.stand_height if not _player.is_crouching else _player.crouch_height):
		return false
	_player.global_position.y = l.top.y + 0.02
	return true


func _physics_process(delta: float) -> void:
	if mode != Mode.HANGING:
		return
	_hang_time += delta
	if Input.is_action_just_pressed("jump") or (_hang_time >= min_hang_time and Input.is_action_pressed("move_forward")):
		_pull_up()
	elif not Input.is_action_pressed("grab") or Input.is_action_just_pressed("crouch"):
		_drop()


# ---------- หาขอบ ----------

func _find_ledge(limit: float, low := -1.0, reach_override := -1.0) -> Dictionary:
	var lowest := min_height if low < 0.0 else low
	var space := _player.get_world_3d().direct_space_state
	var feet := _player.global_position
	var fwd := -_player.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	var r := reach + speed * lookahead_time if reach_override < 0.0 else reach_override
	# ยิงหาผนังหลายระดับ (แข้ง เอว อก) จะได้เจอทั้งขอบเตี้ยและขอบสูง
	var heights := [0.03] if low >= 0.0 else [0.3, 0.9, 1.5]
	var wall := {}
	for hgt in heights:
		if hgt > limit:
			continue
		var from: Vector3 = feet + Vector3.UP * hgt
		wall = _ray(space, from, from + fwd * r)
		if not wall.is_empty() and absf(wall.normal.y) < 0.3:
			break
		wall = {}
	if wall.is_empty():
		return {}
	var into: Vector3 = -wall.normal
	into.y = 0.0
	into = into.normalized()
	var probe: Vector3 = wall.position + into * 0.3
	var top := _ray(space, Vector3(probe.x, feet.y + limit + 0.3, probe.z), Vector3(probe.x, feet.y + lowest - 0.05, probe.z))
	if top.is_empty() or top.normal.y < 0.7:
		return {}
	var height: float = top.position.y - feet.y
	if height < lowest or height > limit:
		return {}
	var edge := Vector3(wall.position.x, top.position.y, wall.position.z)
	return {"top": top.position, "edge": edge, "normal": wall.normal, "into": into, "height": height}


# ---------- ท่า ----------

func _begin(l: Dictionary) -> void:
	_ledge = l
	_player.control_enabled = false
	var hand := _player.get_node_or_null("Hand")
	if hand and hand.held:
		hand.release()
	if _arms:
		_arms.grab_ledge(l.edge, l.normal)


func _end(keep_velocity := Vector3.ZERO) -> void:
	mode = Mode.NONE
	if _arms:
		_arms.release()
	_player.velocity = keep_velocity
	_player.control_enabled = true


## จุดยืนบนขอบ (ยืนไม่พอ = ย่อ · ย่อก็ไม่พอ = null)
func _end_pos(l: Dictionary) -> Variant:
	var end_pos: Vector3 = l.top + l.into * 0.4
	if _player.fits_at(end_pos, _player.stand_height):
		return end_pos
	if _player.fits_at(end_pos, _player.crouch_height):
		return end_pos
	return null


## ข้ามเร็ว: ยกตัวข้ามขอบเป็นโค้งเดียว แล้ววิ่งต่อด้วยความเร็วเดิม (ออกตัวนุ่ม ๆ แล้วไม่ชะลอตอนจบ)
func _vault(l: Dictionary, end_pos: Vector3, speed: float) -> void:
	mode = Mode.CLIMBING
	_begin(l)
	_crouch_if_needed(end_pos)
	_kick(0.03, climb_look_down_deg * 0.5)
	var keep: Vector3 = l.into * speed
	var lip: float = l.top.y + 0.05
	var start := _player.global_position
	var mid := Vector3(start.x, lip + 0.12, start.z).lerp(Vector3(end_pos.x, lip + 0.12, end_pos.z), 0.45)
	await _glide([start, mid, Vector3(end_pos.x, lip, end_pos.z)], vault_time, false)
	_end(keep)


## ปีนขึ้น: ดึงตัว → ยกข้ามขอบ → ก้าวขึ้น เป็นเส้นโค้งเส้นเดียว ไม่หยุดตามรอยต่อ
func _mantle(l: Dictionary, end_pos: Vector3) -> void:
	mode = Mode.CLIMBING
	_begin(l)
	_crouch_if_needed(end_pos)
	_kick(0.05, climb_look_down_deg)
	var total := climb_time_base + climb_time_per_meter * float(l.height)
	await _climb_path(_player.global_position, end_pos, total)
	_end()


func _climb_path(start: Vector3, end_pos: Vector3, total: float) -> void:
	var lip := end_pos.y + 0.05
	var chest := Vector3(start.x, maxf(start.y, lip - 0.3), start.z)
	var over := Vector3(start.x, lip, start.z).lerp(Vector3(end_pos.x, lip, end_pos.z), 0.35)
	await _glide([start, chest, over, Vector3(end_pos.x, lip, end_pos.z)], total, true)


## เคลื่อนผู้เล่นผ่านจุดต่าง ๆ เป็นเส้นโค้งเส้นเดียว (Catmull-Rom) ด้วยจังหวะเดียว
## ease_both = เริ่มและจบแบบนุ่ม · ไม่ใช่ = เริ่มนุ่มแต่จบด้วยความเร็วเต็ม (ใช้ตอนข้ามแล้ววิ่งต่อ)
func _glide(points: Array, duration: float, ease_both: bool) -> void:
	var tw := _tween()
	tw.tween_method(func(t: float):
		var s := t * t * (3.0 - 2.0 * t) if ease_both else pow(t, 1.5)
		var n := points.size() - 1
		var f := s * n
		var i := mini(int(f), n - 1)
		var local := f - i
		var p0: Vector3 = points[maxi(i - 1, 0)]
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[i + 1]
		var p3: Vector3 = points[mini(i + 2, n)]
		_player.global_position = p1.cubic_interpolate(p2, p0, p3, local),
		0.0, 1.0, duration)
	await tw.finished


## ห้อยตัว: ตัวแนบผนัง มือบนขอบ ตาอยู่ระดับขอบพอดี
func _start_hang(l: Dictionary) -> void:
	mode = Mode.HANGING
	_hang_time = 0.0
	_begin(l)
	_player.velocity = Vector3.ZERO
	_kick(0.08, -4.0)
	var eye := _player.eye_position().y - _player.global_position.y
	var hang_pos: Vector3 = l.edge + l.normal * 0.4
	hang_pos.y = l.top.y - eye + 0.05
	var tw := _tween()
	tw.tween_property(_player, "global_position", hang_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _pull_up() -> void:
	var end_pos = _end_pos(_ledge)
	if end_pos == null:
		return
	mode = Mode.CLIMBING
	_crouch_if_needed(end_pos)
	_kick(0.04, climb_look_down_deg)
	await _climb_path(_player.global_position, end_pos, pull_up_time)
	_end()


func _drop() -> void:
	_end(_ledge.get("normal", Vector3.ZERO) * 1.0)


func _crouch_if_needed(end_pos: Vector3) -> void:
	if not _player.fits_at(end_pos, _player.stand_height):
		_player.force_crouch()


func _tween() -> Tween:
	var tw := create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	return tw


func _kick(drop: float, pitch: float) -> void:
	var camera := _player.get_node_or_null("Head/Camera3D")
	if camera and camera.has_method("kick"):
		camera.kick(drop, pitch)


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_player.get_rid()]
	return space.intersect_ray(query)
