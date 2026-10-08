class_name PathChaser
extends PathFollow3D
## ฉากไล่ล่าที่วางเส้นทางไว้ล่วงหน้า (แบบ Little Nightmares: Chef วิ่งไล่ลงโถงจนผู้เล่นหลบเข้าห้องน้ำ)
## ใส่ไว้ใต้ Path3D · มอนวิ่งตามเส้น · เริ่มเมื่อ start() ถูกเรียก (จาก ChaseTrigger) · หยุดที่ปลายเส้น
## ตัวโมเดลใส่เป็นลูกชื่อ Model

## วิ่งเร็วกี่เมตร/วินาที (ผู้เล่นวิ่ง 6.5) · ค่าเริ่มที่ Claude ตั้ง
@export var speed := 5.6
## เร่งจากหยุดถึงความเร็วเต็มกี่วินาที (ให้เวลาผู้เล่นตั้งตัวแบบ LN ที่ส่งสัญญาณอันตรายล่วงหน้า)
@export var ramp_time := 0.8
## จับได้เมื่อผู้เล่นอยู่ใกล้กว่านี้ (เมตร)
@export var catch_range := 1.2
## ถ้าผู้เล่นซ่อนอยู่ตอนมอนวิ่งมาถึงปลายเส้น มอนจะไม่เห็น
@export var respects_hiding := true
## ซ่อนตัวไว้จนกว่าจะเริ่มไล่ (โผล่มาตอนเริ่มฉากไล่ ผู้เล่นไม่เห็นมันยืนรอ)
@export var hidden_until_start := true
## หัวใจผู้เล่น: NONE = ไม่มีผล · AWARENESS = ตามสถานะ · PROXIMITY = ยิ่งเข้าใกล้ยิ่งดัง
@export_enum("NONE", "AWARENESS", "PROXIMITY") var heartbeat := 2
## (PROXIMITY) เริ่มได้ยินเสียงหัวใจเมื่อเข้ามาใกล้กว่ากี่เมตร
@export var heartbeat_range := 16.0
## ชื่อท่าวิ่งในโมเดล (ว่าง = ไม่เล่นท่า)
@export var anim_run := ""
## ความเร็วที่ท่าวิ่งถูกทำมา (เมตร/วินาที) ใช้ปรับความเร็วท่าตามความเร็วจริง · ค่าประเมิน ยังไม่ได้ตรวจด้วยตา
@export var anim_run_speed := 4.7

var state: Monster.State = Monster.State.IDLE
var awareness := 0.0

var _t := 0.0
var _player: Player
var _anim: AnimationPlayer


func _ready() -> void:
	add_to_group("monster")
	loop = false
	_anim = _find_anim(get_node_or_null("Model"))
	if hidden_until_start:
		visible = false
	await get_tree().physics_frame
	_player = get_tree().get_first_node_in_group("player") as Player


func start() -> void:
	if state != Monster.State.IDLE:
		return
	state = Monster.State.CHASE
	awareness = 1.0
	visible = true
	if _anim and anim_run != "" and _anim.has_animation(anim_run):
		_anim.play(anim_run, 0.3)


func _physics_process(delta: float) -> void:
	if state != Monster.State.CHASE:
		return
	_t += delta
	var ramp := clampf(_t / ramp_time, 0.0, 1.0)
	# ออกตัวแบบค่อย ๆ เร่ง (ease) ไม่พุ่งเต็มความเร็วทันที
	var cur_speed := speed * ramp * ramp * (3.0 - 2.0 * ramp)
	progress += cur_speed * delta
	if _anim:
		_anim.speed_scale = clampf(cur_speed / anim_run_speed, 0.5, 1.5)
	if progress_ratio >= 1.0:
		state = Monster.State.SEARCH
		awareness = 0.6
		if _anim:
			_anim.stop()
		return
	if _player and global_position.distance_to(_player.global_position) < catch_range:
		if not (respects_hiding and _player.is_hidden):
			state = Monster.State.CATCH
			_player.get_caught(self)


func _find_anim(n: Node) -> AnimationPlayer:
	if n == null:
		return null
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var a := _find_anim(c)
		if a:
			return a
	return null


## หัวใจผู้เล่นควรเต้นแรงแค่ไหนเพราะมอนตัวนี้ (0–1) · ยังไม่เริ่มไล่ = 0
func heartbeat_level(listener: Vector3) -> float:
	if state == Monster.State.IDLE:
		return 0.0
	match heartbeat:
		1:
			return awareness
		2:
			return clampf(1.0 - global_position.distance_to(listener) / heartbeat_range, 0.0, 1.0)
	return 0.0
