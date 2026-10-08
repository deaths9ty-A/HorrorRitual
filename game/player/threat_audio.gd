extends Node
## เสียงความกลัวของผู้เล่น (แบบ Little Nightmares: ได้ยินเสียงหัวใจตอนถูกเห็นหรือตอนซ่อนรอ)
## มอนแต่ละชนิดเลือกเองว่าทำให้หัวใจเต้นแบบไหน (ไม่มีผล / ตามที่รู้ตัว / ยิ่งใกล้ยิ่งดัง) ตั้งใน profile หรือที่ตัวมอน
## ตอนถูกไล่มีเสียงชั้นไล่ล่าเพิ่ม
## ค่าทั้งหมดเป็นค่าเริ่มที่ Claude ตั้ง

## เสียงหัวใจ (วนเล่น)
@export var heartbeat: AudioStream
## เสียงตอนถูกไล่ (วนเล่น)
@export var chase_loop: AudioStream
## เสียงหัวใจเบาสุด/ดังสุด (dB)
@export var heartbeat_min_db := -40.0
@export var heartbeat_max_db := -2.0
## เสียงหัวใจเร็วขึ้นสุดกี่เท่าตอนถูกไล่
@export var heartbeat_max_pitch := 1.6
## เสียงเปลี่ยนเร็วแค่ไหน
@export var blend_speed := 2.5

var _heart: AudioStreamPlayer
var _chase: AudioStreamPlayer
var _level := 0.0
var _chase_level := 0.0


func _ready() -> void:
	_heart = _make(heartbeat)
	_chase = _make(chase_loop)


func _process(delta: float) -> void:
	var aware := 0.0
	var chasing := false
	var ear: Vector3 = (get_parent() as Node3D).global_position
	for m in get_tree().get_nodes_in_group("monster"):
		if m.has_method("heartbeat_level"):
			aware = maxf(aware, m.heartbeat_level(ear))
		chasing = chasing or m.state == Monster.State.CHASE
	_level = move_toward(_level, aware, blend_speed * delta)
	_chase_level = move_toward(_chase_level, 1.0 if chasing else 0.0, blend_speed * 0.5 * delta)
	_heart.volume_db = lerpf(heartbeat_min_db, heartbeat_max_db, _level) if _level > 0.01 else -80.0
	_heart.pitch_scale = lerpf(1.0, heartbeat_max_pitch, _level)
	_chase.volume_db = linear_to_db(maxf(_chase_level, 0.0001))


func _make(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -80.0
	p.bus = &"SFX"
	add_child(p)
	if stream:
		# วนเล่นเองเมื่อจบ (ไม่ต้องตั้ง loop ในไฟล์เสียง)
		p.finished.connect(p.play)
		p.play()
	return p
