extends SceneTree
## เทสกันพังของชิ้นที่ 1 (ไม่ใช่หลักฐานว่าเล่นดี) · รัน: Godot --headless --path game -s res://dev/checks/check_piece1.gd

func _initialize() -> void:
	var room: Node3D = load("res://scenes/test/graybox_room.tscn").instantiate()
	root.add_child(room)
	var p: Player = room.get_node("Player")
	await _frames(10)
	# 1) ปีนกล่อง 1.0 ม. (กล่องอยู่ x=-6.5 z=-2.5 ขอบหน้า x=-5.9) หันหน้าไปทาง -X
	p.global_position = Vector3(-5.4, 0.0, -2.5)
	p.rotation.y = deg_to_rad(90)
	await _frames(20)
	var ok: bool = (p.get_node("LedgeClimb") as LedgeClimb).try_climb(true)
	await _frames(60)
	print("CLIMB_1.0 started=", ok, " y=", snappedf(p.global_position.y, 0.01))
	# 2) กล่อง 2.0 ม. ต้องปีนไม่ได้
	p.global_position = Vector3(-5.4, 0.0, 3.5)
	await _frames(20)
	print("CLIMB_2.0 started=", (p.get_node("LedgeClimb") as LedgeClimb).try_climb(true), " (ควรเป็น false)")
	# 3) ใต้คาน 1.2 ม. ลุกไม่ได้
	p.global_position = Vector3(1.5, 0.0, -5.0)
	await _frames(10)
	print("STAND_UNDER_BEAM fits=", p.fits_at(p.global_position, p.stand_height), " (ควรเป็น false)")
	# 4) หยิบของเล็ก
	var item: Grabbable = room.get_node("SmallItem2")
	p.global_position = Vector3(0.0, 0.0, 2.0)
	p.rotation.y = 0.0
	p.get_node("Head").rotation.x = deg_to_rad(-56)
	await _frames(10)
	var hand: Hand = p.get_node("Hand")
	hand._try_grab()
	await _frames(30)
	print("GRAB_SMALL held=", hand.held == item, " item_y=", snappedf(item.global_position.y, 0.01))
	# 4.1) ก้มมองของที่ถือ ดึงลงมาชิดตัว ผู้เล่นต้องไม่ถูกดัน
	var before := p.global_position
	p.get_node("Head").rotation.x = deg_to_rad(-85)
	await _frames(40)
	print("HELD_NO_PUSH moved_m=", snappedf((p.global_position - before).length(), 0.001), " (ควรเป็น 0)")
	p.get_node("Head").rotation.x = 0.0
	await _frames(20)
	var z0 := item.global_position.z
	print("  before_throw held=", hand.held == item, " item=", item.global_position.snappedf(0.01))
	hand._throw()
	await _frames(30)
	print("THROW flew_m=", snappedf(z0 - item.global_position.z, 0.01), " (ควรมากกว่า 2)")
	quit()

func _frames(n: int) -> void:
	for i in n:
		await physics_frame
