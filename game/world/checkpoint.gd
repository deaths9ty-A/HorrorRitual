extends Area3D
## จุดเช็กพอยต์: ผู้เล่นเดินผ่านกล่องนี้ = ตายแล้วจะกลับมาเกิดที่ Spawn (ลูก Marker3D) หรือที่กล่องนี้

func _ready() -> void:
	collision_layer = 0
	body_entered.connect(_on_enter)


func _on_enter(b: Node) -> void:
	if b is Player:
		var spawn := get_node_or_null("Spawn") as Node3D
		get_node("/root/Checkpoints").save_here(spawn.global_transform if spawn else global_transform)
