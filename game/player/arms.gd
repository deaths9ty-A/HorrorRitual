class_name Arms
extends Node3D
## แขนของผู้เล่น (โมเดล CC0 "FPS Arms" โดย para) · ติดกล้อง ซ่อนไว้ตอนปกติ
## ตอนปีนหรือเกาะขอบ วางมือสองข้างลงบนขอบจริงด้วย TwoBoneIK3D (แบบ Dying Light ที่มือขยับตามขอบที่เกาะ)

## โมเดลแขน (.glb ที่มีกระดูก upper_arm / forearm / hand ซ้ายขวา)
@export var arms_scene: PackedScene = preload("res://assets/models/opengameart/fps_arms/fps_arms.glb")
## ภาพผิวของแขน (ไฟล์ .glb ไม่ได้ฝังภาพมา)
@export var skin_texture: Texture2D = preload("res://assets/models/opengameart/fps_arms/new_diff.png")
## มือสองข้างห่างกันกี่เมตรตอนวางบนขอบ
@export var hand_spacing := 0.45
## แขนเลื่อนเข้าออกเร็วแค่ไหน
@export var show_speed := 12.0
## ศอกชี้ไปทางไหน (ตำแหน่งเทียบกับแขน: ออกด้านข้าง ลงล่าง) ให้ศอกตกลงแบบคนเกาะขอบจริง
@export var elbow_pole := Vector3(0.6, -0.7, 0.2)

var _model: Node3D
var _skeleton: Skeleton3D
var _ik: TwoBoneIK3D
var _targets: Array[Marker3D] = []
var _rest_pos := Vector3.ZERO
var _shown := false
var _amount := 0.0


func _ready() -> void:
	_model = arms_scene.instantiate()
	add_child(_model)
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0]
	if skin_texture:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = skin_texture
		mat.roughness = 0.8
		for mi in _model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = mat
	# เป้าของมือ (อยู่ในโลก ไม่ขยับตามกล้อง)
	for side in ["L", "R"]:
		var t := Marker3D.new()
		t.name = "HandTarget" + side
		t.top_level = true
		add_child(t)
		_targets.append(t)
	# จุดบอกทิศศอก (ขยับตามกล้อง)
	var poles: Array[Marker3D] = []
	for i in 2:
		var pole := Marker3D.new()
		pole.name = "ElbowPole" + ["L", "R"][i]
		# แขนหมุน 180° ในฉากผู้เล่น ฝั่งซ้ายของโมเดลจึงอยู่ด้าน +X ของโหนดนี้
		pole.position = Vector3(elbow_pole.x * (1 if i == 0 else -1), elbow_pole.y, elbow_pole.z)
		add_child(pole)
		poles.append(pole)
	_ik = TwoBoneIK3D.new()
	_ik.name = "HandIK"
	_skeleton.add_child(_ik)
	_ik.setting_count = 2
	for i in 2:
		var side: String = ["L", "R"][i]
		_ik.set_root_bone_name(i, "upper_arm." + side)
		_ik.set_middle_bone_name(i, "forearm." + side)
		_ik.set_end_bone_name(i, "hand." + side)
		_ik.set_target_node(i, _ik.get_path_to(_targets[i]))
		_ik.set_pole_node(i, _ik.get_path_to(poles[i]))
	_ik.active = false
	_ik.influence = 0.0
	_rest_pos = position
	visible = false


## วางมือสองข้างบนขอบ: ledge_point = จุดกึ่งกลางบนขอบ · wall_normal = ทิศที่ผนังหันออกมาหาผู้เล่น
func grab_ledge(ledge_point: Vector3, wall_normal: Vector3) -> void:
	var side := wall_normal.cross(Vector3.UP).normalized()
	_targets[0].global_position = ledge_point - side * hand_spacing * 0.5
	_targets[1].global_position = ledge_point + side * hand_spacing * 0.5
	_ik.active = true
	_shown = true
	visible = true


## เอามือออก (เลิกเกาะ)
func release() -> void:
	_shown = false


func _process(delta: float) -> void:
	_amount = move_toward(_amount, 1.0 if _shown else 0.0, show_speed * delta)
	# IK ค่อย ๆ จับขอบตามที่แขนโผล่ ไม่ดีดเข้าตำแหน่ง
	_ik.influence = _amount
	if _amount <= 0.0:
		_ik.active = false
	# แขนเลื่อนขึ้นจากใต้จอตอนโผล่ และลงไปตอนซ่อน
	position = _rest_pos + Vector3(0, -0.5 * (1.0 - _amount), 0)
	if _amount <= 0.0:
		visible = false
