class_name Grabbable
extends RigidBody3D
## ของที่จับได้ · heavy = ลากไปตามพื้นได้อย่างเดียว (แบบลังใน Little Nightmares)
## ไม่ heavy = ยกถือและขว้างได้ · น้ำหนักของตั้งที่ Mass ใน Inspector

## ของหนัก: ลากได้ ยกไม่ได้ ขว้างไม่ได้
@export var heavy := false
## ตอนลากของหนัก ผู้เล่นเดินช้าลงเหลือกี่เท่า · ค่าเริ่มที่ Claude ตั้ง
@export_range(0.1, 1.0) var drag_speed_scale := 0.5
## ของวิ่งตามมือแรงแค่ไหน
@export var follow_strength := 15.0
## ของเคลื่อนเร็วสุดตอนถูกถือ (เมตร/วินาที)
@export var max_follow_speed := 8.0

## ของกระแทกพื้นหรือผนังด้วยความเร็ว 1 ม./วิ เสียงไปไกลกี่เมตร (มอนได้ยิน ใช้ล่อมอนได้แบบ LN) · ค่าเริ่มที่ Claude ตั้ง
@export var impact_loudness_per_speed := 2.5
## กระแทกเบากว่านี้ (ม./วิ) ไม่มีเสียง
@export var min_impact_speed := 1.5
## เสียงตอนกระแทก (สุ่มเล่น)
@export var impact_sounds: Array[AudioStream] = []

## มือตั้งค่าสองตัวนี้ตอนถือ
var held := false
var hold_target := Vector3.ZERO
var _last_speed := 0.0
var _sound: AudioStreamPlayer3D


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_hit)
	_sound = AudioStreamPlayer3D.new()
	_sound.bus = &"SFX"
	add_child(_sound)


func _on_hit(_body: Node) -> void:
	if held or _last_speed < min_impact_speed:
		return
	var bus := get_node_or_null("/root/NoiseBus")
	if bus:
		bus.emit_noise(global_position, _last_speed * impact_loudness_per_speed, self)
	if not impact_sounds.is_empty() and not _sound.playing:
		_sound.stream = impact_sounds.pick_random()
		_sound.volume_db = linear_to_db(clampf(_last_speed / 8.0, 0.2, 1.0))
		_sound.play()


# เอกสาร Godot เตือนว่าอย่าตั้ง linear_velocity บ่อย ๆ จากข้างนอก ให้ทำใน _integrate_forces แทน
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_last_speed = state.linear_velocity.length()
	if not held:
		return
	var v := (hold_target - state.transform.origin) * follow_strength
	if heavy:
		var flat := Vector3(v.x, 0.0, v.z).limit_length(max_follow_speed)
		# ของหนักยังตกตามแรงโน้มถ่วง ไม่ลอยขึ้น
		state.linear_velocity = Vector3(flat.x, state.linear_velocity.y, flat.z)
		state.angular_velocity = Vector3.ZERO
	else:
		state.linear_velocity = v.limit_length(max_follow_speed)
		state.angular_velocity *= 0.9
