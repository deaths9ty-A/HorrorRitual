extends SceneTree
## สร้างด่าน 1 · ทุ่งโล่ง สว่าง (แม่แบบให้เจ้าของจัดวางอาร์ตต่อเอง) แล้วบันทึกเป็น .tscn
## รัน: Godot --headless --path game -s res://dev/build/build_level_01.gd
## ⚠️ รันซ้ำ = เขียนทับด่านเดิม ถ้าเจ้าของแก้ด่านในเอดิเตอร์แล้ว อย่ารันซ้ำ
## ท้องฟ้า: Poly Haven kloofendal_48d_partly_cloudy_puresky (CC0) · พื้น: ambientCG Grass004 (CC0)

const OUT := "res://scenes/levels/level_01_field.tscn"
const SKY := "res://assets/skies/polyhaven/kloofendal_48d_partly_cloudy_puresky_2k.hdr"
## ขนาดพื้น (เมตร) และกำแพงล่องหนกันเดินออกนอกด่าน
const SIZE := 240.0


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	await process_frame
	var k := LevelKit.new("Level01_Field", 1.0)
	# ท้องฟ้าและแสงกลางวัน
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	var sky := Sky.new()
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load(SKY)
	sky.sky_material = pano
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.84, 0.9)
	env.fog_density = 0.004
	env.fog_aerial_perspective = 0.6
	we.environment = env
	k._add(k.root, we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	k._add(k.root, sun)
	# พื้นหญ้า (เสียงเท้า = หญ้า)
	var ground_mat := k.material("Grass004", 0.1)
	k.box("Ground", Vector3(SIZE, 0.2, SIZE), Vector3(0, -0.1, 0), ground_mat, "grass")
	await k.bake(self)
	# กำแพงล่องหนรอบด่าน
	var walls := StaticBody3D.new()
	walls.name = "Boundary"
	k._add(k.root, walls)
	for side in [[Vector3(SIZE / 2, 5, 0), Vector3(1, 10, SIZE)], [Vector3(-SIZE / 2, 5, 0), Vector3(1, 10, SIZE)],
			[Vector3(0, 5, SIZE / 2), Vector3(SIZE, 10, 1)], [Vector3(0, 5, -SIZE / 2), Vector3(SIZE, 10, 1)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = side[1]
		cs.shape = bs
		cs.position = side[0]
		walls.add_child(cs)
		cs.owner = k.root
	# หญ้า (ชั่วคราว ลบได้)
	var grass := MultiMeshInstance3D.new()
	grass.set_script(load("res://world/grass_field.gd"))
	grass.name = "GrassField"
	k._add(k.root, grass)
	# ผู้เล่น + เช็กพอยต์ตั้งต้น
	k.player(Vector3(0, 0, 0), 0)
	k.checkpoint(Vector3(0, 1, 0), Vector3(3, 2, 3), Vector3.ZERO, 0)
	k.save(OUT)
	quit()
