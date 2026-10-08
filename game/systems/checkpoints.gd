extends Node
## เช็กพอยต์และการตาย (Autoload ชื่อ Checkpoints) แบบ Little Nightmares:
## ถูกจับ → จอดำ → โหลดฉากใหม่ทั้งฉาก (ปริศนา มอน ของ กลับสภาพเดิม) → ผู้เล่นเกิดที่เช็กพอยต์ล่าสุด

## จอมืดลงกี่วินาที
@export var fade_out_time := 0.6
## ค้างจอดำกี่วินาที
@export var black_time := 0.4

var _scene_path := ""
var _spawn: Transform3D
var _has_spawn := false
var _busy := false
var _fade: ColorRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	get_tree().scene_changed.connect(_on_scene_changed)


## จดเช็กพอยต์ (Checkpoint ในฉากเรียกตอนผู้เล่นเดินผ่าน)
func save_here(t: Transform3D) -> void:
	if get_tree().current_scene == null:
		return
	_scene_path = get_tree().current_scene.scene_file_path
	_spawn = t
	_has_spawn = true


## ผู้เล่นถูกจับ: จอดำแล้วเริ่มใหม่ที่เช็กพอยต์
func player_died() -> void:
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, fade_out_time)
	tw.tween_interval(black_time)
	await tw.finished
	if get_tree().current_scene:
		get_tree().reload_current_scene()


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if _has_spawn and scene.scene_file_path == _scene_path:
		var p := get_tree().get_first_node_in_group("player") as Node3D
		if p:
			p.global_transform = _spawn
	elif scene.scene_file_path != _scene_path:
		_has_spawn = false
	_busy = false
	create_tween().tween_property(_fade, "color:a", 0.0, 0.5)
