extends Area3D
## กล่องเริ่มเหตุการณ์: ผู้เล่นเดินเข้า → เรียก start() ของเป้าหมายทุกตัว (มอนไล่ตามเส้น ฝูงมอน ฯลฯ) ครั้งเดียว

## สิ่งที่จะเริ่ม (ต้องมีฟังก์ชัน start() หรือเป็น Monster)
@export var targets: Array[Node] = []

var _done := false


func _ready() -> void:
	collision_layer = 0
	body_entered.connect(_on_enter)


func _on_enter(b: Node) -> void:
	if _done or not (b is Player):
		return
	_done = true
	for t in targets:
		if t is Monster:
			t.wake_and_chase()
		elif t and t.has_method("start"):
			t.start()
