class_name MenuStyle
extends RefCounted
## หน้าตาร่วมของเมนู (ฟอนต์ไทย ขนาดปุ่ม) ใช้ที่เดียวทุกหน้า


static func font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Leelawadee UI", "Tahoma", "Noto Sans Thai"])
	return f


static func label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	return l


static func button(text: String, on_press: Callable, width := 420.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", 22)
	b.custom_minimum_size = Vector2(width, 48)
	b.pressed.connect(on_press)
	return b
