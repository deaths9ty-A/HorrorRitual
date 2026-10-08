extends Control
## เมนูหลักของเกม: เริ่มเกม · โหมดเอดิเตอร์ (ด่านทดสอบอยู่ในนี้) · ออกเกม

const EDITOR_MENU := "res://scenes/menu/editor_menu.tscn"

var _box: VBoxContainer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var box := VBoxContainer.new()
	_box = box
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := MenuStyle.label("HorrorRitual", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(Control.new())
	var start := MenuStyle.button("เริ่มเกม", func(): pass)
	# ยังไม่มีด่านเกมจริง (รอเนื้อเรื่อง) ปุ่มนี้จึงกดไม่ได้
	start.disabled = true
	start.tooltip_text = "ยังไม่มีด่านเกมจริง"
	box.add_child(start)
	box.add_child(MenuStyle.button("ตั้งค่า", _open_settings))
	box.add_child(MenuStyle.button("โหมดเอดิเตอร์", func(): get_tree().change_scene_to_file(EDITOR_MENU)))
	box.add_child(MenuStyle.button("ออกเกม", func(): get_tree().quit()))
	# จัดกล่องให้อยู่กลางจอหลังรู้ขนาดจริง
	await get_tree().process_frame
	box.position = (size - box.size) / 2.0


func _open_settings() -> void:
	_box.visible = false
	var panel := SettingsPanel.new()
	add_child(panel)
	panel.closed.connect(func():
		panel.queue_free()
		_box.visible = true)
	await get_tree().process_frame
	panel.position = (size - panel.size) / 2.0
