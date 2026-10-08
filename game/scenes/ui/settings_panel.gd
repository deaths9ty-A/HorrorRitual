class_name SettingsPanel
extends PanelContainer
## หน้าตั้งค่า (ใช้ทั้งในเมนูหลักและเมนูหยุดเกม) · ค่าบันทึกทันทีที่เปลี่ยน
## เพิ่มหัวข้อใหม่: เพิ่มใน TABS ที่นี่ และใน DEFAULTS ของ systems/settings.gd

signal closed

const TABS := [
	["ภาพ", [
		["display/fullscreen", "เต็มจอ", "bool"],
		["display/vsync", "V-Sync (ล็อกเฟรมตามจอ)", "bool"],
		["display/brightness", "ความสว่าง", "range", 0.5, 1.6, 0.05],
		["display/show_fps", "แสดง FPS (เหลือง = ต่ำกว่า 60)", "bool"],
	]],
	["เสียง", [
		["audio/master", "เสียงรวม", "range", 0.0, 1.0, 0.05],
		["audio/sfx", "เสียงประกอบ (เท้า ของ หัวใจ)", "range", 0.0, 1.0, 0.05],
		["audio/ambience", "เสียงบรรยากาศ", "range", 0.0, 1.0, 0.05],
		["audio/voice", "เสียงพากย์", "range", 0.0, 1.0, 0.05],
	]],
	["การควบคุม", [
		["controls/mouse_sensitivity", "ความไวเมาส์", "range", 0.2, 3.0, 0.05],
		["controls/invert_y", "กลับแกนเมาส์ขึ้น-ลง", "bool"],
	]],
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(640, 420)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.09, 0.97)
	bg.set_content_margin_all(20)
	bg.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", bg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(MenuStyle.label("ตั้งค่า", 30))
	var tabs := TabContainer.new()
	tabs.add_theme_font_override("font", MenuStyle.font())
	tabs.add_theme_font_size_override("font_size", 20)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	var settings := get_node("/root/Settings")
	for tab in TABS:
		var grid := GridContainer.new()
		grid.name = tab[0]
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 12)
		tabs.add_child(grid)
		for row in tab[1]:
			var key: String = row[0]
			var name_label := MenuStyle.label(row[1], 20)
			name_label.custom_minimum_size.x = 300
			grid.add_child(name_label)
			if row[2] == "bool":
				# ใช้สวิตช์แทนช่องติ๊ก (ช่องว่างของ CheckBox มองแทบไม่เห็นบนพื้นมืด)
				var cb := CheckButton.new()
				cb.button_pressed = bool(settings.get_value(key))
				cb.add_theme_font_override("font", MenuStyle.font())
				cb.add_theme_font_size_override("font_size", 18)
				cb.text = "เปิด" if cb.button_pressed else "ปิด"
				cb.toggled.connect(func(on):
					cb.text = "เปิด" if on else "ปิด"
					settings.set_value(key, on))
				grid.add_child(cb)
			else:
				grid.add_child(_slider(settings, key, row[3], row[4], row[5]))
	box.add_child(MenuStyle.button("ปิด", func(): closed.emit(), 200))


func _slider(settings: Node, key: String, lo: float, hi: float, step: float) -> HBoxContainer:
	var line := HBoxContainer.new()
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step
	slider.custom_minimum_size.x = 220
	slider.value = float(settings.get_value(key))
	var value_label := MenuStyle.label("%.2f" % slider.value, 18)
	slider.value_changed.connect(func(v):
		value_label.text = "%.2f" % v
		settings.set_value(key, v))
	line.add_child(slider)
	line.add_child(value_label)
	return line
