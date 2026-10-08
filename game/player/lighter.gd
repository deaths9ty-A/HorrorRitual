extends OmniLight3D
## ไฟแช็กของตัวเอก (แบบ Little Nightmares): กดปุ่มเพื่อเปิดหรือปิด ส่องได้แค่รอบตัว
## ปรับความสว่างและระยะได้ที่ Light > Energy และ Omni > Range ใน Inspector

## เริ่มเกมมาไฟแช็กเปิดอยู่ไหม
@export var start_on := false


func _ready() -> void:
	# แสงที่ทำให้มอนแบบ Patients หยุดนิ่ง
	add_to_group("freeze_light")
	visible = start_on


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lighter"):
		visible = not visible
