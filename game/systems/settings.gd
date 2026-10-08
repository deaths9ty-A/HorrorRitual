extends Node
## ค่าตั้งค่าของผู้เล่น บันทึกที่ user://settings.cfg และมีผลทันที (Autoload ชื่อ Settings)
## รายการอิงจากชุดตั้งค่าที่เจ้าของเคยอนุมัติในโปรเจกต์เก่า (ภาพ เสียง การควบคุม) เอาเฉพาะที่ใช้ได้ตอนนี้

signal changed(key: String)

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"display/fullscreen": false,
	"display/vsync": true,
	"display/brightness": 1.0,
	"display/show_fps": false,
	"audio/master": 1.0,
	"audio/sfx": 1.0,
	"audio/ambience": 1.0,
	"audio/voice": 1.0,
	"controls/mouse_sensitivity": 1.0,
	"controls/invert_y": false,
}
## ชื่อ bus เสียงของแต่ละช่อง
const BUSES := {"audio/master": "Master", "audio/sfx": "SFX", "audio/ambience": "Ambience", "audio/voice": "Voice"}

var _values := {}
var _fps_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	var ok := cfg.load(PATH) == OK
	for key in DEFAULTS:
		var parts: PackedStringArray = key.split("/")
		_values[key] = cfg.get_value(parts[0], parts[1], DEFAULTS[key]) if ok else DEFAULTS[key]
	_make_fps_label()
	for key in _values:
		_apply(key)
	get_tree().scene_changed.connect(func(): _apply("display/brightness"))


func get_value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	_values[key] = value
	_apply(key)
	_save()
	changed.emit(key)


func _save() -> void:
	var cfg := ConfigFile.new()
	for key in _values:
		var parts: PackedStringArray = key.split("/")
		cfg.set_value(parts[0], parts[1], _values[key])
	cfg.save(PATH)


func _apply(key: String) -> void:
	var v: Variant = _values[key]
	match key:
		"display/fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED)
		"display/vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v else DisplayServer.VSYNC_DISABLED)
		"display/brightness":
			_apply_brightness(float(v))
		"display/show_fps":
			_fps_label.visible = bool(v)
		_:
			if BUSES.has(key):
				var idx := AudioServer.get_bus_index(BUSES[key])
				if idx >= 0:
					AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(float(v), 0.0001)))


# ความสว่าง: ปรับที่ WorldEnvironment ของด่านที่เปิดอยู่
func _apply_brightness(v: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for we in scene.find_children("*", "WorldEnvironment", true, false):
		var env := (we as WorldEnvironment).environment
		if env:
			env.adjustment_enabled = true
			env.adjustment_brightness = v


func _make_fps_label() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 95
	add_child(layer)
	_fps_label = Label.new()
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.position = Vector2(-120, 8)
	_fps_label.add_theme_font_size_override("font_size", 18)
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_fps_label)


func _process(_delta: float) -> void:
	if _fps_label.visible:
		var fps := Engine.get_frames_per_second()
		_fps_label.text = "FPS %d" % fps
		# ต่ำกว่า 60 = ผิดเกณฑ์ของเจ้าของ ขึ้นสีเหลือง
		_fps_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if fps < 60 else Color.WHITE)
