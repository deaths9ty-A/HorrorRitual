extends Control
## โหมดเอดิเตอร์ (สำหรับทีม) · หัวข้อ "เทสแมพ" = ด่านทดสอบทั้งหมด
## หาด่านเองจากโฟลเดอร์ใน TEST_MAP_FOLDERS · ในด่านกด F1 = กลับมาหน้านี้

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const TEST_MAP_FOLDERS := ["res://scenes/levels/", "res://scenes/chase/", "res://scenes/test/"]
## ชื่อภาษาไทยของด่าน (ไม่มีในรายการ = ใช้ชื่อไฟล์)
const MAP_NAMES := {
	"lair_hearing": "1 · มอนตาบอด หูดี (แบบ Janitor)",
	"kitchen_sight": "2 · มอนใช้ตา ค้นที่ซ่อน (แบบ Chef)",
	"dining_stampede": "3 · ฝูงมอนตื่นแล้วไล่ (แบบ Guests)",
	"ward_light_freeze": "4 · หุ่นขยับเฉพาะตอนมืด (แบบ Patients LN2)",
	"corridor_path_chase": "5 · ไล่ล่าตามเส้นทาง (โถงทางเดิน)",
	"chasm_jumps": "6 · เหว กระโดด เกาะขอบ",
	"graybox_room": "ห้องกล่องเทา (ทดสอบท่าผู้เล่น)",
	"level_01_field": "ด่าน 1 · ทุ่งโล่ง (แม่แบบ)",
}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var box := VBoxContainer.new()
	box.position = Vector2(56, 40)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(MenuStyle.label("โหมดเอดิเตอร์", 34))
	box.add_child(MenuStyle.label("เทสแมพ  (ในด่านกด F1 เพื่อกลับมาหน้านี้)", 24))
	for path in _test_maps():
		var key: String = path.get_file().get_basename()
		box.add_child(MenuStyle.button(MAP_NAMES.get(key, key), func(): get_tree().change_scene_to_file(path), 560))
	box.add_child(Control.new())
	box.add_child(MenuStyle.button("กลับเมนูหลัก", func(): get_tree().change_scene_to_file(MAIN_MENU), 560))


func _test_maps() -> Array:
	var out := []
	for folder in TEST_MAP_FOLDERS:
		# ResourceLoader.list_directory ใช้ได้ทั้งตอนรันในเอดิเตอร์และหลัง export
		var files := Array(ResourceLoader.list_directory(folder)).filter(func(f): return f.ends_with(".tscn"))
		files.sort_custom(func(a, b): return str(MAP_NAMES.get(a.get_basename(), "z" + a)) < str(MAP_NAMES.get(b.get_basename(), "z" + b)))
		for f in files:
			out.append(folder + f)
	return out
