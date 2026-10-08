extends AudioStreamPlayer3D
## เสียงเท้าของผู้เล่น: เล่นเสียงทุกก้าว และส่งเสียงให้มอนได้ยินผ่าน NoiseBus
## พื้นผิวตั้งที่พื้นเอง: ใส่ metadata ชื่อ "surface" บนตัวพื้น (wood / carpet / metal / tile) ถ้าไม่มี = ปกติ
## แบบ Little Nightmares: พื้นไม้ดัง มอนตาบอดได้ยิน · พรมเงียบ (ค่าทั้งหมดเป็นค่าเริ่มที่ Claude ตั้ง)

## เดินกี่เมตรนับเป็นหนึ่งก้าว
@export var stride := 0.75
## เสียงไปได้ไกลกี่เมตร ตอนเดิน / วิ่ง / ย่อ
@export var walk_loudness := 5.0
@export var run_loudness := 11.0
@export var crouch_loudness := 1.2
## ตัวคูณความดังตามพื้นผิว
@export var surface_loudness := {"wood": 1.4, "carpet": 0.35, "metal": 1.6, "tile": 1.1, "grass": 0.6}
## ลงพื้นจากการกระโดดหรือตก: ความเร็วตก 1 ม./วิ เสียงไปไกลกี่เมตร
@export var land_loudness_per_speed := 2.0
## โฟลเดอร์เสียงเท้า และชื่อขึ้นต้นของไฟล์ต่อพื้นผิว (ไม่ระบุพื้นผิว = ใช้ "default")
@export_dir var sound_folder := "res://assets/audio/kenney/impact-sounds"
@export var surface_sound_prefix := {"wood": "footstep_wood", "carpet": "footstep_carpet", "metal": "footstep_concrete",
	"tile": "footstep_concrete", "grass": "footstep_grass", "default": "footstep_concrete"}
## ไฟล์เสียงเท้าเพิ่มเติม (ใช้เมื่อหาไฟล์ตามพื้นผิวไม่เจอ)
@export var step_sounds: Array[AudioStream] = []

var _by_surface := {}

var _distance := 0.0
var _last_pos: Vector3
@onready var _player: Player = get_parent()


func _ready() -> void:
	_last_pos = _player.global_position
	_player.landed.connect(_on_landed)
	# ResourceLoader.list_directory ใช้ได้ทั้งตอนรันในเอดิเตอร์และหลัง export
	for f in ResourceLoader.list_directory(sound_folder):
		if f.ends_with(".ogg"):
			for surface in surface_sound_prefix:
				if f.begins_with(surface_sound_prefix[surface]):
					if not _by_surface.has(surface):
						_by_surface[surface] = []
					_by_surface[surface].append(load(sound_folder + "/" + f))


func _physics_process(_delta: float) -> void:
	var moved := _player.global_position - _last_pos
	_last_pos = _player.global_position
	if not _player.is_on_floor() or not _player.control_enabled:
		return
	_distance += Vector2(moved.x, moved.z).length()
	if _distance >= stride:
		_distance = 0.0
		_step()


func _step() -> void:
	var base := walk_loudness
	if _player.is_crouching:
		base = crouch_loudness
	elif Input.is_action_pressed("run"):
		base = run_loudness
	var surface := _surface()
	var loud := base * float(surface_loudness.get(surface, 1.0))
	_bus().emit_noise(_player.global_position, loud, _player)
	var pool: Array = _by_surface.get(surface, _by_surface.get("default", step_sounds))
	if not pool.is_empty():
		stream = pool.pick_random()
		volume_db = linear_to_db(clampf(loud / run_loudness, 0.15, 1.0))
		pitch_scale = randf_range(0.9, 1.1)
		play()


func _on_landed(fall_speed: float) -> void:
	if fall_speed > 2.0:
		var scale_ := float(surface_loudness.get(_surface(), 1.0))
		_bus().emit_noise(_player.global_position, fall_speed * land_loudness_per_speed * scale_, _player)


## พื้นผิวที่ยืนอยู่ (อ่านจาก metadata "surface" ของพื้น) ไม่มี = "default"
func _surface() -> String:
	var col := _player.get_last_slide_collision()
	var floor_body: Object = null
	for i in _player.get_slide_collision_count():
		var c := _player.get_slide_collision(i)
		if c.get_normal().y > 0.7:
			floor_body = c.get_collider()
	if floor_body == null and col:
		floor_body = col.get_collider()
	if floor_body and floor_body.has_meta("surface"):
		return str(floor_body.get_meta("surface"))
	return "default"


# ใช้ get_node แทนชื่อ Autoload ตรง ๆ เพื่อให้สคริปต์สร้างฉาก (โหมด -s) โหลดไฟล์นี้ได้
func _bus() -> Node:
	return get_node("/root/NoiseBus")
