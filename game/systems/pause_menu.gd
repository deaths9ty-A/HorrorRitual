extends CanvasLayer
## เมนูหยุดเกม: กด Esc ในด่าน (Autoload ชื่อ PauseMenu) · ในหน้าเมนูไม่ทำงาน
## เล่นต่อ · ตั้งค่า · กลับเทสแมพ · กลับเมนูหลัก · ออกเกม

const MENUS := ["res://scenes/menu/main_menu.tscn", "res://scenes/menu/editor_menu.tscn"]
const EDITOR_MENU := "res://scenes/menu/editor_menu.tscn"
const MAIN_MENU := "res://scenes/menu/main_menu.tscn"

var _root: Control
var _buttons: VBoxContainer
var _settings: SettingsPanel


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	_buttons.position = Vector2(80, 120)
	_root.add_child(_buttons)
	_buttons.add_child(MenuStyle.label("หยุดเกม", 34))
	_buttons.add_child(MenuStyle.button("เล่นต่อ", close))
	_buttons.add_child(MenuStyle.button("ตั้งค่า", _open_settings))
	_buttons.add_child(MenuStyle.button("กลับเทสแมพ", func(): _go(EDITOR_MENU)))
	_buttons.add_child(MenuStyle.button("กลับเมนูหลัก", func(): _go(MAIN_MENU)))
	_buttons.add_child(MenuStyle.button("ออกเกม", func(): get_tree().quit()))
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var scene := get_tree().current_scene
	if scene == null or MENUS.has(scene.scene_file_path):
		return
	get_viewport().set_input_as_handled()
	if not _root.visible:
		open()
	elif _settings:
		_close_settings()
	else:
		close()


func open() -> void:
	_root.visible = true
	_buttons.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_close_settings()
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	_buttons.visible = false
	_settings = SettingsPanel.new()
	_settings.position = Vector2(80, 80)
	_settings.closed.connect(_close_settings)
	_root.add_child(_settings)


func _close_settings() -> void:
	if _settings:
		_settings.queue_free()
		_settings = null
	_buttons.visible = true


func _go(path: String) -> void:
	_close_settings()
	_root.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
