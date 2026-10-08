extends Area3D
## เหว/พื้นที่ตาย: ผู้เล่นตกเข้ากล่องนี้ = ตาย แล้วเริ่มใหม่ที่เช็กพอยต์ (แบบ LN ที่ตกลงไปในความมืดแล้วตาย)
## ขนาดกล่องตั้งที่ CollisionShape3D ลูก · วางไว้ใต้เหว

func _ready() -> void:
	collision_layer = 0
	body_entered.connect(func(b): if b is Player: b.die())
