extends Node
## กด F1 ในด่านทดสอบ = กลับหน้า โหมดเอดิเตอร์ > เทสแมพ (Autoload ชื่อ HubReturn · เครื่องมือของนักพัฒนา)

const EDITOR_MENU := "res://scenes/menu/editor_menu.tscn"
const MENUS := ["res://scenes/menu/editor_menu.tscn", "res://scenes/menu/main_menu.tscn"]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back_to_hub") and get_tree().current_scene and not MENUS.has(get_tree().current_scene.scene_file_path):
		get_tree().change_scene_to_file(EDITOR_MENU)
