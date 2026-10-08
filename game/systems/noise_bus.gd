extends Node
## ช่องกลางของ "เสียงในโลก" ที่มอนได้ยิน (Autoload ชื่อ NoiseBus)
## ใครทำเสียงก็เรียก NoiseBus.emit_noise() · มอนที่ได้ยินจะฟังสัญญาณ noise
## loudness = เสียงไปได้ไกลกี่เมตร (มอนแต่ละตัวคูณด้วยความไวหูของตัวเองอีกที)

signal noise(position: Vector3, loudness: float, source: Node)


func emit_noise(position: Vector3, loudness: float, source: Node = null) -> void:
	noise.emit(position, loudness, source)
