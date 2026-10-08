extends Area3D
## ที่ซ่อน (ใต้โต๊ะ ใต้เตียง หลังของ): ผู้เล่นอยู่ในกล่องนี้ = มอนที่ใช้ตามองไม่เห็น
## แบบ Little Nightmares: ซ่อนได้จากตา แต่ถ้าขยับแล้วมีเสียง มอนที่ใช้หูยังได้ยิน
## ขนาดกล่องตั้งที่ CollisionShape3D ลูก

## ต้องย่อตัวถึงจะนับว่าซ่อน (ใต้โต๊ะ = เปิด · หลังตู้สูง = ปิด)
@export var require_crouch := true

var _player: Player


func _ready() -> void:
	collision_layer = 0
	body_entered.connect(func(b): if b is Player: _player = b)
	body_exited.connect(_on_exit)


func _physics_process(_delta: float) -> void:
	if _player:
		_player.hide_votes[self] = (not require_crouch) or _player.is_crouching


func _on_exit(b: Node) -> void:
	if b is Player:
		b.hide_votes.erase(self)
		_player = null
