extends SceneTree
## สร้างฉากไล่ล่าแบบ Little Nightmares 5 ฉาก (ประกอบด้วยสคริปต์ แล้วบันทึกเป็น .tscn ให้เจ้าของแก้ต่อในเอดิเตอร์)
## รัน: Godot --headless --path game -s res://dev/build/build_chase_scenes.gd [-- --only=chasm]
## --only=ชื่อ สร้างเฉพาะฉากนั้น (lair kitchen dining ward corridor chasm) ฉากอื่นไม่ถูกเขียนทับ
## ⚠️ รันซ้ำ = เขียนทับฉากเดิม ถ้าเจ้าของแก้ฉากในเอดิเตอร์แล้ว อย่ารันซ้ำ
## ผังห้อง ขนาด และตัวเลขทั้งหมดเป็นค่าเริ่มที่ Claude ตั้ง · กติกาของแต่ละห้องอ้างจาก LN (ดู docs/chase-scenes.md)

const OUT := "res://scenes/chase/"
const S := 1.6  # ของในฉากใหญ่กว่าตัวผู้เล่น (LN: ตัวเอกตัวเล็กในโลกยักษ์) ทำให้มุดใต้โต๊ะได้

var impacts: Array[AudioStream] = []
var steps: Array[AudioStream] = []


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	impacts = _sounds("res://assets/audio/kenney/impact-sounds", ["impactWood", "impactMetal", "impactPlate"])
	steps = _sounds("res://assets/audio/kenney/rpg-audio", ["footstep"])
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	var builders := {"lair": build_lair, "kitchen": build_kitchen, "dining": build_dining, "ward": build_ward,
		"corridor": build_corridor, "chasm": build_chasm}
	for key in builders:
		if only == "" or only == key:
			await builders[key].call()
	quit()


func _sounds(dir: String, prefixes: Array) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".ogg") and prefixes.any(func(p): return f.begins_with(p)):
			out.append(load(dir + "/" + f))
	return out


func _player(kit: LevelKit, pos: Vector3, yaw := 0.0) -> void:
	var p := kit.player(pos, yaw)
	var fs := p.get_node_or_null("Footsteps")
	if fs:
		fs.set("step_sounds", steps)
	kit.checkpoint(pos + Vector3(0, 1, 0), Vector3(3, 2, 3), pos, yaw)


## ทำให้เส้นทางโค้งเรียบที่จุดหักมุม (มอนเลี้ยวนุ่ม ไม่กระตุก)
func _smooth(c: Curve3D) -> void:
	for i in range(1, c.point_count - 1):
		var t := (c.get_point_position(i + 1) - c.get_point_position(i - 1)) / 6.0
		c.set_point_in(i, -t)
		c.set_point_out(i, t)


# ---------------------------------------------------------------
# 1) ห้องนอนเด็กแบบ Lair: มอนตาบอดหูดี (Janitor)
#    LN: Janitor ตาบอดแต่ได้ยินพื้นไม้ลั่น ผู้เล่นต้องเดินบนผ้า · ขว้างของล่อ
# ---------------------------------------------------------------
func build_lair() -> void:
	var k := LevelKit.new("Lair_Hearing", S)
	k.environment(0.12, 0.02)
	var wood := k.material("WoodFloor043", 0.5)
	var wall := k.material("Wallpaper002A", 0.4, Color(0.7, 0.68, 0.6))
	var rug := k.material("Carpet016", 0.6)
	k.room("Room", Vector3(14, 5, 24), Vector3(0, 0, 0), wood, wall, "wood")
	# ทางพรม (เงียบ) วิ่งเลี้ยวไปมา
	k.box("Rug1", Vector3(2, 0.03, 8), Vector3(-4, 0.015, 7), rug, "carpet")
	k.box("Rug2", Vector3(8, 0.03, 2), Vector3(-1, 0.015, 2), rug, "carpet")
	k.box("Rug3", Vector3(2, 0.03, 9), Vector3(4, 0.015, -3.5), rug, "carpet")
	k.box("Rug4", Vector3(6, 0.03, 2), Vector3(1, 0.015, -9), rug, "carpet")
	# เตียงและตู้ (สิ่งกีดขวาง) · โต๊ะ (มุดซ่อนได้)
	k.prop("GothicBed_01", Vector3(4.5, 0, 7), 90)
	k.prop("vintage_day_bed", Vector3(-4.5, 0, -3), 90)
	k.prop("wooden_bookshelf_worn", Vector3(-6.3, 0, 3), 90)
	k.prop("GothicCabinet_01", Vector3(6.3, 0, -1), -90)
	k.prop("painted_wooden_shelves", Vector3(-6.3, 0, -9), 90)
	k.prop("WoodenTable_02", Vector3(0, 0, 9.5), 0, "table")
	k.prop("WoodenTable_01", Vector3(-1, 0, -5), 90, "table")
	k.box("ExitDoorFrame", Vector3(2, 3, 0.3), Vector3(1, 1.5, -12.0), k.material("Planks037A", 0.5))
	var polys: int = await k.bake(self)
	print("lair nav ", polys)
	k.hide_spot(Vector3(0, 0.5, 9.5), Vector3(2.0, 1.0, 1.2))
	k.hide_spot(Vector3(-1, 0.5, -5), Vector3(1.2, 1.0, 2.0))
	for i in 5:
		k.grabbable(["can_rusted", "brass_pot_01", "wooden_bowl_02", "jug_01", "russian_food_cans_01"][i],
			Vector3(-3.5 + i * 0.6, 0.4, 10), 0.6, false, impacts, 1.0)
	_player(k, Vector3(-4, 0, 10.5), 0)
	k.monster("res://content/monsters/janitor.tres", Vector3(3, 0, -6), 180,
		[Vector3(3, 0, -6), Vector3(3, 0, 4), Vector3(-3, 0, 4), Vector3(-3, 0, -6)], Monster.State.PATROL, 1.3,
		Color(0.25, 0.2, 0.17), 1.0)
	k.light(Vector3(0, 4.5, 4), 0.8, 9.0, Color(1, 0.8, 0.55))
	k.light(Vector3(0, 4.5, -8), 0.6, 8.0, Color(1, 0.8, 0.55))
	k.sign("ห้อง 1 · มอนตาบอด หูดี (แบบ Janitor)\nพื้นไม้ = ดัง · พรม = เงียบ · วิ่ง = ดังมาก\nขว้างของไปอีกทางเพื่อล่อ · ไปให้ถึงประตูฝั่งตรงข้าม",
		Vector3(-4, 3.0, 5.5), 0, 34)
	k.save(OUT + "lair_hearing.tscn")


# ---------------------------------------------------------------
# 2) ครัวแบบ Kitchen: มอนใช้ตา ค้นที่ซ่อนตอนสงสัย (Twin Chefs)
#    LN: Chef เดินตรวจครัว · Six ซ่อนใต้โต๊ะ/ในห้องน้ำ · Chef เข้ามาดูแล้วออกไป
# ---------------------------------------------------------------
func build_kitchen() -> void:
	var k := LevelKit.new("Kitchen_Sight", S)
	k.environment(0.15, 0.015)
	var tile := k.material("Tiles139", 0.6)
	var wall := k.material("PaintedPlaster017", 0.4, Color(0.8, 0.78, 0.7))
	k.room("Kitchen", Vector3(18, 5, 16), Vector3(0, 0, 0), tile, wall, "tile")
	# ห้องน้ำเล็กติดครัว (ซ่อนได้ แต่ Chef จะเข้ามาดูตอนค้นหา)
	k.box("RestroomWallA", Vector3(0.2, 5, 4), Vector3(5, 2.5, -6), wall)
	k.box("RestroomWallB", Vector3(2.5, 5, 0.2), Vector3(7.75, 2.5, -4), wall)
	# โต๊ะยาวเรียงสองแถว (มุดใต้ได้)
	for i in 3:
		k.prop("dining_table", Vector3(-5 + i * 4.5, 0, 1.5), 0, "table")
	k.prop("WoodenTable_02", Vector3(-4, 0, -4.5), 0, "table")
	k.prop("electric_stove", Vector3(-8.3, 0, -6), 90)
	k.prop("steel_frame_shelves_01", Vector3(-8.3, 0, 3), 90)
	k.prop("painted_wooden_cabinet", Vector3(8.3, 0, 4), -90)
	k.prop("Barrel_01", Vector3(1, 0, -7))
	k.prop("barrel_03", Vector3(2.4, 0, -7.2))
	k.prop("wooden_crate_01", Vector3(-1.5, 0, 6.8))
	k.box("ExitDoorFrame", Vector3(2, 3, 0.3), Vector3(-8.85, 1.5, 6.5), k.material("Planks037A", 0.5))
	var polys: int = await k.bake(self)
	print("kitchen nav ", polys)
	for i in 3:
		k.hide_spot(Vector3(-5 + i * 4.5, 0.55, 1.5), Vector3(2.4, 1.1, 1.2))
	k.hide_spot(Vector3(-4, 0.55, -4.5), Vector3(2.0, 1.1, 1.0))
	k.hide_spot(Vector3(7, 1.0, -6), Vector3(3.6, 2.0, 3.6), false)
	for i in 4:
		k.grabbable(["brass_pan_01", "pot_enamel_01", "ceramic_pot", "wooden_cutting_board"][i],
			Vector3(-5 + i * 3.0, 1.3, 1.5), 0.8, false, impacts, 1.0)
	_player(k, Vector3(7, 0, 6.5), 90)
	k.monster("res://content/monsters/chef.tres", Vector3(-6, 0, -2), 90,
		[Vector3(-6, 0, -2), Vector3(5, 0, -2), Vector3(5, 0, 5), Vector3(-6, 0, 5)], Monster.State.PATROL, 1.25,
		Color(0.85, 0.7, 0.65), 1.35)
	k.monster("res://content/monsters/chef.tres", Vector3(2, 0, -5.5), -90,
		[Vector3(2, 0, -5.5), Vector3(-6, 0, -6.5)], Monster.State.PATROL, 1.25,
		Color(0.85, 0.7, 0.65), 1.35)
	k.light(Vector3(-4, 4.5, 0), 1.0, 10.0, Color(1, 0.9, 0.7))
	k.light(Vector3(4, 4.5, 0), 0.9, 10.0, Color(1, 0.9, 0.7))
	k.light(Vector3(7, 4.0, -6), 0.25, 4.0, Color(0.8, 0.9, 1.0))
	k.sign("ห้อง 2 · มอนใช้ตา (แบบ Chef)\nมุดใต้โต๊ะ (ย่อ) = มองไม่เห็น · แต่ถ้ามันสงสัยแล้วเดินมาใกล้ จะเจอ\nห้องน้ำขวามือซ่อนได้ · ไปให้ถึงประตูซ้ายสุด",
		Vector3(2.5, 3.2, 6.5), 0, 34)
	k.save(OUT + "kitchen_sight.tscn")


# ---------------------------------------------------------------
# 3) ห้องอาหารแบบ Guest Area: ฝูงมอนตื่นแล้วไล่ (Guests)
#    LN: แขกตัวใหญ่นั่งกินที่โต๊ะยาว · ฉากไล่ล่าจบด้วยการวิ่งหนี
# ---------------------------------------------------------------
func build_dining() -> void:
	var k := LevelKit.new("Dining_Stampede", S)
	k.environment(0.2, 0.01)
	var floor_mat := k.material("WoodFloor051", 0.5)
	var wall := k.material("Wallpaper001A", 0.4, Color(0.75, 0.6, 0.55))
	k.room("Hall", Vector3(12, 6, 36), Vector3(0, 0, 0), floor_mat, wall, "wood")
	for i in 5:
		k.prop("dining_table", Vector3(0, 0, -12 + i * 5.2), 90, "table")
	for i in 6:
		k.prop("painted_wooden_chair_02", Vector3(-2.6, 0, -13 + i * 5), 90)
	k.prop("vintage_grandfather_clock_01", Vector3(5.6, 0, 10), -90)
	k.box("ExitDoorFrame", Vector3(2.4, 3.2, 0.3), Vector3(0, 1.6, -18.0), k.material("Planks037A", 0.5))
	var polys: int = await k.bake(self)
	print("dining nav ", polys)
	var guests: Array[Node] = []
	for i in 6:
		var side := -1 if i % 2 == 0 else 1
		guests.append(k.monster("res://content/monsters/guest.tres", Vector3(side * 3.6, 0, -12 + i * 4.6),
			90 * -side, [], Monster.State.IDLE, 1.2, Color(0.12, 0.12, 0.14), 1.6, true))
	_player(k, Vector3(4, 0, 16), 0)
	k.trigger("WakeGuests", Vector3(0, 1, 2), Vector3(12, 2, 1.0), guests)
	k.light(Vector3(0, 5.5, 8), 1.0, 12.0, Color(1, 0.8, 0.6))
	k.light(Vector3(0, 5.5, -8), 1.0, 12.0, Color(1, 0.8, 0.6))
	k.sign("ห้อง 3 · ฝูงมอน (แบบ Guests)\nเดินผ่านกลางห้องแล้วพวกมันจะตื่น · วิ่ง (Shift) ไปประตูปลายห้อง",
		Vector3(4, 3.2, 11), 0, 34)
	k.save(OUT + "dining_stampede.tscn")


# ---------------------------------------------------------------
# 4) ห้องผู้ป่วยแบบ Hospital (LN2): ขยับเฉพาะตอนมืด โดนแสงแล้วหยุด (Patients)
#    LN2: ส่องไฟฉายใส่หุ่นแล้วหุ่นหยุด · ไม่รู้ว่าตัวไหนจะขยับจนเข้าไปใกล้
# ---------------------------------------------------------------
func build_ward() -> void:
	var k := LevelKit.new("Ward_LightFreeze", S)
	k.environment(0.03, 0.03)
	var floor_mat := k.material("Concrete047A", 0.5)
	var wall := k.material("Plaster001", 0.4, Color(0.7, 0.75, 0.7))
	k.room("Ward", Vector3(14, 4.5, 26), Vector3(0, 0, 0), floor_mat, wall, "tile")
	for i in 4:
		k.prop("vintage_day_bed", Vector3(-4.8, 0, -8 + i * 5), 90)
		k.prop("GothicBed_01", Vector3(4.8, 0, -8 + i * 5), -90)
	k.prop("metal_trash_can", Vector3(0, 0, 4))
	k.prop("worn_metal_rack", Vector3(-1.5, 0, -2))
	k.box("ExitDoorFrame", Vector3(2, 3, 0.3), Vector3(0, 1.5, -13.0), k.material("Planks037A", 0.5))
	var polys: int = await k.bake(self)
	print("ward nav ", polys)
	# ตัวแรกห่างจุดเกิดเกิน 9 ม. (ระยะตื่น 7 ม.) ผู้เล่นจะไม่ถูกจับทันทีที่เกิด
	var spots := [Vector3(-2, 0, 2.5), Vector3(2.5, 0, 0), Vector3(-2.5, 0, -3), Vector3(2, 0, -6),
		Vector3(-1.5, 0, -9), Vector3(2.2, 0, -11)]
	for i in spots.size():
		k.monster("res://content/monsters/patient.tres", spots[i], randf_range(-180, 180), [], Monster.State.IDLE, 1.0,
			Color(0.82, 0.8, 0.76), 1.0)
	_player(k, Vector3(0, 0, 11.5), 0)
	# ไฟเพดานสองดวง (ทำให้มอนในวงไฟหยุด) ที่เหลือมืด ต้องใช้ไฟแช็ก (F)
	k.light(Vector3(-3, 4.0, 2), 0.7, 4.5, Color(0.8, 0.95, 0.85), true, true)
	k.light(Vector3(3, 4.0, -7), 0.7, 4.5, Color(0.8, 0.95, 0.85), true, true)
	k.sign("ห้อง 4 · หุ่นขยับเฉพาะตอนมืด (แบบ Patients ใน LN2)\nไฟแช็ก (F) ส่องแล้วหุ่นหยุด · ปิดไฟ = มันเดินเข้ามา\nไปให้ถึงประตูปลายห้อง",
		Vector3(0, 3.0, 7.5), 0, 34)
	k.save(OUT + "ward_light_freeze.tscn")


# ---------------------------------------------------------------
# 5) โถงทางเดิน: ไล่ล่าตามเส้นทางที่วางไว้ (scripted chase)
#    LN: Chef ลงลิฟต์ วิ่งไล่ลงโถง Six หนีเข้าห้องน้ำ Chef เข้ามาดูแล้วออกไป
# ---------------------------------------------------------------
func build_corridor() -> void:
	var k := LevelKit.new("Corridor_PathChase", S)
	k.environment(0.1, 0.02)
	var floor_mat := k.material("MetalWalkway014", 0.8)
	var wall := k.material("CorrugatedSteel007A", 0.4)
	k.room("Hall", Vector3(5, 4, 44), Vector3(0, 0, 0), floor_mat, wall, "metal")
	# สิ่งกีดขวาง: กล่องให้ปีน · คานให้ย่อลอด
	k.box("ClimbCrate", Vector3(5, 1.0, 1.2), Vector3(0, 0.5, 4), k.material("Planks037A", 0.5))
	k.box("DuckBeam", Vector3(5, 2.6, 1.0), Vector3(0, 2.7, -6), wall)
	k.box("ClimbCrate2", Vector3(5, 1.2, 1.2), Vector3(0, 0.6, -14), k.material("Planks037A", 0.5))
	# ห้องหลบท้ายโถง
	k.box("SafeRoomWall", Vector3(3.2, 4, 0.2), Vector3(-0.9, 2, -18.5), wall)
	k.prop("modular_industrial_pipes_01", Vector3(2.0, 2.6, 10), 90)
	await k.bake(self)
	_player(k, Vector3(0, 0, 18), 0)
	# เส้นทางของมอน: เริ่มหลังผู้เล่น วิ่งตามโถงจนถึงหน้าห้องหลบ
	var path := Path3D.new()
	path.name = "ChasePath"
	var c := Curve3D.new()
	for p in [Vector3(0, 0, 21.5), Vector3(0, 0, 10), Vector3(0, 1.0, 4.2), Vector3(0, 0, 0), Vector3(0, 0, -6),
			Vector3(0, 1.2, -14), Vector3(0, 0, -17.5), Vector3(1.6, 0, -19.5)]:
		c.add_point(p)
	_smooth(c)
	path.curve = c
	k._add(k.root, path)
	var chaser := PathFollow3D.new()
	chaser.set_script(load("res://monsters/path_chaser.gd"))
	chaser.name = "Chaser"
	chaser.rotation_mode = PathFollow3D.ROTATION_Y
	k._add(path, chaser)
	var model := Node3D.new()
	model.name = "Model"
	k._add(chaser, model)
	var body: Node3D = (load(LevelKit.UAL) as PackedScene).instantiate()
	body.name = "Mannequin"
	body.scale = Vector3(1.35, 1.0, 1.35) * 1.2 * 1.25
	body.rotation_degrees.y = 180  # หุ่นหันหน้าไป +Z แต่ PathFollow3D เดินไปทาง -Z
	k._add(model, body)
	chaser.set("anim_run", "Sprint")
	k.trigger("StartChase", Vector3(0, 1, 13), Vector3(5, 2, 1), [chaser])
	k.hide_spot(Vector3(1.6, 1.0, -21), Vector3(1.6, 2.0, 2.6), false)
	k.light(Vector3(0, 3.6, 14), 0.8, 7.0, Color(1, 0.7, 0.45))
	k.light(Vector3(0, 3.6, 0), 0.6, 7.0, Color(1, 0.7, 0.45))
	k.light(Vector3(0, 3.6, -14), 0.6, 7.0, Color(1, 0.7, 0.45))
	k.sign("ห้อง 5 · ไล่ล่าตามเส้นทาง
เดินไปข้างหน้าแล้วมันจะวิ่งมาจากข้างหลัง
วิ่งค้าง Shift ชนกล่อง = ข้ามเอง · ย่อลอดคาน (Ctrl)
หนีเข้าห้องเล็กซ้ายมือท้ายโถง",
		Vector3(0, 3.0, 13.5), 0, 30)
	k.save(OUT + "corridor_path_chase.tscn")


# ---------------------------------------------------------------
# 6) เหว: กระโดดข้ามช่อง เกาะขอบ ตกแล้วตาย + ช่วงท้ายมีมอนไล่
#    LN: ต้องกดจับค้างถึงจะเกาะขอบ (Twinfinite) · ตกจากที่สูง/ตกเหวแล้วตาย
#    ความยาวช่องคิดจาก: วิ่ง 6.5 ม./วิ ลอยราว 0.55 วิ = ไกลสุดราว 3.6 ม. · เดิน 4.0 ม./วิ ≈ 2.2 ม.
# ---------------------------------------------------------------
func build_chasm() -> void:
	var k := LevelKit.new("Chasm_Jumps", 1.0)
	k.environment(0.12, 0.035)
	var plat := k.material("MetalWalkway014", 0.8)
	var wood := k.material("Planks037A", 0.5)
	var wall := k.material("CorrugatedSteel007A", 0.3, Color(0.6, 0.6, 0.6))
	# แท่น: [ชื่อ, z เริ่ม, z จบ, ความสูงผิว]
	var platforms := [["Start", 24.0, 12.0, 0.0], ["P2", 10.0, 2.0, 0.0], ["P3", -1.2, -10.0, 0.0],
		["P4", -13.5, -24.0, 1.4], ["P5", -26.5, -42.0, 1.4]]
	for p in platforms:
		var length: float = p[1] - p[2]
		var top: float = p[3]
		k.box(p[0], Vector3(5, 1.0, length), Vector3(0, top - 0.5, (p[1] + p[2]) / 2.0), plat, "metal")
	# ผนังสองข้างยาวตลอดเหว (ลึกลงไปมืด ๆ)
	k.box("WallW", Vector3(0.3, 30, 70), Vector3(-2.65, -8, -9), wall)
	k.box("WallE", Vector3(0.3, 30, 70), Vector3(2.65, -8, -9), wall)
	k.box("EndWall", Vector3(5, 8, 0.3), Vector3(0, 3, -42.2), wall)
	# สิ่งกีดขวาง: กำแพงเตี้ยให้ข้ามเร็ว · ลังให้ข้ามตอนถูกไล่ · คานให้ย่อลอด
	k.box("VaultWall", Vector3(5, 1.0, 0.4), Vector3(0, 0.5, -5.5), wood)
	k.box("ChaseCrate", Vector3(5, 1.1, 1.0), Vector3(0, 1.4 + 0.55, -31), wood)
	k.box("DuckBeam", Vector3(5, 2.0, 0.6), Vector3(0, 1.4 + 1.25 + 1.0, -35), wall)
	k.box("SafeWall", Vector3(3.0, 4, 0.2), Vector3(-1.0, 1.4 + 2, -39.0), wall)
	await k.bake(self)
	k.kill_zone(Vector3(0, -14, -9), Vector3(6, 2, 80))
	_player(k, Vector3(0, 0, 22), 0)
	k.checkpoint(Vector3(0, 1.4 + 1, -16), Vector3(5, 2, 2), Vector3(0, 1.4, -16), 0)
	k.hide_spot(Vector3(1.2, 1.4 + 1.0, -40.6), Vector3(2.4, 2.0, 2.6), false)
	# มอนวิ่งไล่ตามเส้นทาง (ลอยข้ามช่องตามเส้น) เริ่มเมื่อเดินถึงกลางแท่น P4
	var path := Path3D.new()
	path.name = "ChasePath"
	var c := Curve3D.new()
	for pt in [Vector3(0, 0, -6.5), Vector3(0, 0, -10), Vector3(0, 2.0, -11.8), Vector3(0, 1.4, -13.8), Vector3(0, 1.4, -24), Vector3(0, 2.6, -25.3), Vector3(0, 1.4, -26.8),
			Vector3(0, 1.4, -30.2), Vector3(0, 2.5, -31), Vector3(0, 1.4, -32), Vector3(0, 1.4, -38.2), Vector3(1.2, 1.4, -39.6)]:
		c.add_point(pt)
	_smooth(c)
	path.curve = c
	k._add(k.root, path)
	var chaser := PathFollow3D.new()
	chaser.set_script(load("res://monsters/path_chaser.gd"))
	chaser.name = "Chaser"
	chaser.rotation_mode = PathFollow3D.ROTATION_Y
	chaser.set("speed", 5.4)
	chaser.set("anim_run", "Sprint")
	k._add(path, chaser)
	var model := Node3D.new()
	model.name = "Model"
	k._add(chaser, model)
	var body: Node3D = (load(LevelKit.UAL) as PackedScene).instantiate()
	body.name = "Mannequin"
	body.scale = Vector3(1.3, 1.0, 1.3) * 1.5
	body.rotation_degrees.y = 180
	k._add(model, body)
	k.trigger("StartChase", Vector3(0, 1.4 + 1, -18.5), Vector3(5, 2, 1), [chaser])
	for z in [20.0, 6.0, -6.0, -18.0, -30.0, -38.0]:
		var top := 0.0 if z > -12 else 1.4
		k.light(Vector3(0, top + 3.5, z), 0.8, 8.0, Color(1, 0.75, 0.5))
	k.sign("ห้อง 6 · เหว (ตกแล้วตาย)
ช่อง 2 ม. เดินกระโดด · ช่อง 3.2 ม. ต้องวิ่ง
วิ่งค้าง Shift ชนสิ่งกีดขวาง = ข้ามเอง ไม่เสียความเร็ว
ขอบสูง: คลิกซ้ายค้างกลางอากาศ = เกาะ · Space = ดึงขึ้น",
		Vector3(0, 3.0, 17.5), 0, 26)
	k.save(OUT + "chasm_jumps.tscn")
