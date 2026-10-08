extends Camera3D
## ขยับกล้องเล็กน้อยให้ตัวรู้สึกมีน้ำหนัก: ยุบลงตอนเท้าแตะพื้น · ก้มลงตอนปีน แล้วเด้งกลับเองแบบสปริง
## ค่าทั้งหมดเป็นค่าเริ่มที่ Claude ตั้ง ให้เจ้าของปรับเอง

## ตกเร็ว 1 เมตร/วินาที กล้องยุบลงกี่เมตร
@export var land_dip_per_speed := 0.012
## ยุบได้มากสุดกี่เมตร
@export var max_land_dip := 0.12
## สปริงแข็งแค่ไหน ยิ่งมากยิ่งเด้งกลับไว
@export var spring_stiffness := 120.0
## สปริงหน่วงแค่ไหน ยิ่งมากยิ่งไม่แกว่ง
@export var spring_damping := 18.0

var _y := 0.0
var _y_vel := 0.0
var _pitch := 0.0
var _pitch_vel := 0.0


func _ready() -> void:
	var player := owner as Player
	if player:
		player.landed.connect(_on_landed)


## ผลักกล้อง: ลงกี่เมตร และก้มกี่องศา (ระบบปีนเรียกใช้)
func kick(drop_m: float, pitch_deg: float) -> void:
	_y_vel -= drop_m * spring_stiffness * 0.1
	_pitch_vel -= deg_to_rad(pitch_deg) * spring_stiffness * 0.1


func _on_landed(fall_speed: float) -> void:
	var dip := minf(fall_speed * land_dip_per_speed, max_land_dip)
	_y_vel -= dip * spring_stiffness * 0.1


func _process(delta: float) -> void:
	# สปริงแบบมีแรงหน่วง ดึงกลับเข้าศูนย์
	_y_vel += (-spring_stiffness * _y - spring_damping * _y_vel) * delta
	_y += _y_vel * delta
	_pitch_vel += (-spring_stiffness * _pitch - spring_damping * _pitch_vel) * delta
	_pitch += _pitch_vel * delta
	position.y = _y
	rotation.x = _pitch
