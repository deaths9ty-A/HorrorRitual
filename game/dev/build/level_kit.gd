class_name LevelKit
extends RefCounted
## ชุดเครื่องมือของนักพัฒนาสำหรับประกอบฉากทดสอบด้วยสคริปต์ (สร้างครั้งเดียวแล้วบันทึกเป็น .tscn ให้เจ้าของแก้ในเอดิเตอร์ต่อ)
## ไม่ได้ใช้ตอนเล่นเกม

const PH := "res://assets/models/polyhaven/%s/%s_1k.gltf"
const UAL := "res://assets/models/quaternius/ual_standard/ual_standard.glb"
const TEX := "res://assets/textures/ambientcg/%s/%s_1K-JPG_%s.jpg"

var root: Node3D
var nav: NavigationRegion3D
## ขนาดโลกเทียบตัวผู้เล่น (Little Nightmares: ตัวเอกตัวเล็กในโลกที่ของทุกอย่างใหญ่)
var world_scale := 1.0
var _mats := {}
var _font: SystemFont


func _init(scene_name: String, scale := 1.0) -> void:
	world_scale = scale
	root = Node3D.new()
	root.name = scene_name
	nav = NavigationRegion3D.new()
	nav.name = "Navigation"
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.5
	nm.agent_height = 1.8
	nm.agent_max_climb = 0.3
	nm.cell_size = 0.1
	nm.cell_height = 0.1
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.navigation_mesh = nm
	_add(root, nav)
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Leelawadee UI", "Tahoma", "Noto Sans Thai"])


# ---------- พื้นฐาน ----------

func _add(parent: Node, n: Node) -> Node:
	parent.add_child(n)
	n.owner = root
	return n


## วัสดุจากพื้นผิว ambientCG (ถ้าหาไฟล์ไม่เจอใช้สีแทน)
func material(tex_id: String, uv_scale := 1.0, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "%s_%s" % [tex_id, uv_scale]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	var col := TEX % [tex_id, tex_id, "Color"]
	if ResourceLoader.exists(col):
		m.albedo_texture = load(col)
		var nrm := TEX % [tex_id, tex_id, "NormalGL"]
		if ResourceLoader.exists(nrm):
			m.normal_enabled = true
			m.normal_texture = load(nrm)
		var rough := TEX % [tex_id, tex_id, "Roughness"]
		if ResourceLoader.exists(rough):
			m.roughness_texture = load(rough)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * uv_scale
	_mats[key] = m
	return m


## กล่องทึบ (ผนัง พื้น) · surface = พื้นผิวสำหรับเสียงเท้า (wood/carpet/metal/tile)
func box(name: String, size: Vector3, pos: Vector3, mat: Material, surface := "") -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = name
	b.size = size
	b.position = pos
	b.use_collision = true
	b.material = mat
	if surface != "":
		b.set_meta("surface", surface)
	_add(nav, b)
	return b


## ห้องสี่เหลี่ยม: พื้น เพดาน ผนัง 4 ด้าน (ศูนย์กลางพื้นที่ center)
func room(name: String, size: Vector3, center: Vector3, floor_mat: Material, wall_mat: Material, floor_surface := "", ceiling := true) -> void:
	var t := 0.2
	box(name + "_Floor", Vector3(size.x, t, size.z), center + Vector3(0, -t / 2, 0), floor_mat, floor_surface)
	if ceiling:
		box(name + "_Ceiling", Vector3(size.x, t, size.z), center + Vector3(0, size.y + t / 2, 0), wall_mat)
	box(name + "_WallN", Vector3(size.x, size.y, t), center + Vector3(0, size.y / 2, -size.z / 2 - t / 2), wall_mat)
	box(name + "_WallS", Vector3(size.x, size.y, t), center + Vector3(0, size.y / 2, size.z / 2 + t / 2), wall_mat)
	box(name + "_WallW", Vector3(t, size.y, size.z), center + Vector3(-size.x / 2 - t / 2, size.y / 2, 0), wall_mat)
	box(name + "_WallE", Vector3(t, size.y, size.z), center + Vector3(size.x / 2 + t / 2, size.y / 2, 0), wall_mat)


## ป้ายตัวหนังสือลอย (อธิบายกติกาของห้องให้เจ้าของตอนทดสอบ)
func sign(text: String, pos: Vector3, yaw_deg := 0.0, size := 32) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = _font
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 8
	l.position = pos
	l.rotation_degrees.y = yaw_deg
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.name = "Sign"
	_add(root, l)


func light(pos: Vector3, energy := 1.0, rng := 8.0, color := Color(1, 0.85, 0.65), shadows := true, freeze := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_energy = energy
	l.omni_range = rng
	l.light_color = color
	l.shadow_enabled = shadows
	if freeze:
		l.add_to_group("freeze_light", true)
	_add(root, l)
	return l


func environment(ambient := 0.25, fog := 0.0) -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.4, 0.45)
	e.ambient_light_energy = ambient
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if fog > 0.0:
		e.fog_enabled = true
		e.fog_light_color = Color(0.05, 0.05, 0.06)
		e.fog_density = fog
	we.environment = e
	_add(root, we)


# ---------- ของจาก Poly Haven ----------

func _model(id: String) -> Node3D:
	var path := PH % [id, id]
	if not ResourceLoader.exists(path):
		push_warning("ไม่มีโมเดล " + id)
		return null
	return (load(path) as PackedScene).instantiate()


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var stack := [[n, xf]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var t: Transform3D = item[1]
		if node is Node3D and node != n:
			t = t * (node as Node3D).transform
		if node is MeshInstance3D and (node as MeshInstance3D).mesh:
			var a := t * (node as MeshInstance3D).mesh.get_aabb()
			out = a if first else out.merge(a)
			first = false
		for c in node.get_children():
			stack.append([c, t])
	return out


## ของตั้งพื้น (ชนได้ มอนเดินอ้อม) · kind: "solid" = กล่องทึบ · "table" = มีแค่พื้นโต๊ะกับขา (มุดใต้ได้)
func prop(id: String, pos: Vector3, yaw_deg := 0.0, kind := "solid", scale := -1.0) -> StaticBody3D:
	var model := _model(id)
	if model == null:
		return null
	var s := world_scale if scale < 0.0 else scale
	var body := StaticBody3D.new()
	body.name = id
	body.position = pos
	body.rotation_degrees.y = yaw_deg
	_add(nav, body)
	model.scale = Vector3.ONE * s
	body.add_child(model)
	model.owner = root
	var a := _aabb(model, Transform3D(Basis().scaled(model.scale), Vector3.ZERO))
	if kind == "table":
		var top := 0.08 * s
		_shape(body, Vector3(a.size.x, top, a.size.z), a.get_center() + Vector3(0, a.size.y / 2 - top / 2, 0))
		var leg := 0.08 * s
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				var c := a.get_center() + Vector3(sx * (a.size.x / 2 - leg), 0, sz * (a.size.z / 2 - leg))
				_shape(body, Vector3(leg, a.size.y, leg), c)
	else:
		_shape(body, a.size, a.get_center())
	return body


func _shape(body: Node, size: Vector3, center: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = center
	body.add_child(cs)
	cs.owner = root


## ของที่หยิบ ลาก หรือขว้างได้ (heavy = ลากได้อย่างเดียว)
func grabbable(id: String, pos: Vector3, mass := 0.6, heavy := false, impact_sounds: Array[AudioStream] = [], scale := -1.0) -> RigidBody3D:
	var model := _model(id)
	if model == null:
		return null
	var s := world_scale if scale < 0.0 else scale
	var body := RigidBody3D.new()
	body.set_script(load("res://props/grabbable.gd"))
	body.name = id
	body.position = pos
	body.mass = mass
	body.set("heavy", heavy)
	body.set("impact_sounds", impact_sounds)
	_add(root, body)
	model.scale = Vector3.ONE * s
	body.add_child(model)
	model.owner = root
	var a := _aabb(model, Transform3D(Basis().scaled(model.scale), Vector3.ZERO))
	_shape(body, a.size, a.get_center())
	return body


# ---------- ระบบเกม ----------

func hide_spot(pos: Vector3, size: Vector3, require_crouch := true) -> Area3D:
	var a := Area3D.new()
	a.set_script(load("res://world/hide_spot.gd"))
	a.name = "HideSpot"
	a.position = pos
	a.set("require_crouch", require_crouch)
	_add(root, a)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	a.add_child(cs)
	cs.owner = root
	return a


func checkpoint(pos: Vector3, size: Vector3, spawn: Vector3, spawn_yaw := 0.0) -> void:
	var a := Area3D.new()
	a.set_script(load("res://world/checkpoint.gd"))
	a.name = "Checkpoint"
	a.position = pos
	_add(root, a)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	a.add_child(cs)
	cs.owner = root
	var m := Marker3D.new()
	m.name = "Spawn"
	_add(a, m)
	m.position = spawn - pos
	m.rotation_degrees.y = spawn_yaw


## เหว: ตกลงไปในกล่องนี้ = ตาย
func kill_zone(pos: Vector3, size: Vector3) -> void:
	var a := Area3D.new()
	a.set_script(load("res://world/kill_zone.gd"))
	a.name = "KillZone"
	a.position = pos
	_add(root, a)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	a.add_child(cs)
	cs.owner = root


func trigger(name: String, pos: Vector3, size: Vector3, targets: Array[Node]) -> Area3D:
	var a := Area3D.new()
	a.set_script(load("res://world/chase_trigger.gd"))
	a.name = name
	a.position = pos
	_add(root, a)
	a.set("targets", targets)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	a.add_child(cs)
	cs.owner = root
	return a


func player(pos: Vector3, yaw_deg := 0.0) -> Node3D:
	var p: Node3D = (load("res://player/player.tscn") as PackedScene).instantiate()
	p.position = pos
	p.rotation_degrees.y = yaw_deg
	_add(root, p)
	return p


## วางมอน · ใช้หุ่นจาก Universal Animation Library (CC0) · body_width = อ้วนกว่าปกติกี่เท่า
## สร้างโหนดเองทั้งหมด (ไม่ใช้ monster.tscn เป็นแม่แบบ) เพราะโหนดที่เพิ่มใต้ฉากแม่แบบบันทึกไม่ติด
func monster(profile_path: String, pos: Vector3, yaw_deg := 0.0, patrol: Array[Vector3] = [], start := Monster.State.PATROL, size := 1.0, tint := Color(0, 0, 0, 0), body_width := 1.0, dormant := false) -> Monster:
	var m := CharacterBody3D.new()
	m.set_script(load("res://monsters/monster.gd"))
	m.name = "Monster"
	m.position = pos
	m.rotation_degrees.y = yaw_deg
	m.scale = Vector3.ONE * size
	m.set("profile", load(profile_path))
	m.set("start_state", start)
	m.set("model_tint", tint)
	m.set("dormant", dormant)
	_add(root, m)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 2.2
	col.shape = cap
	col.position.y = 1.1
	col.name = "CollisionShape3D"
	_add(m, col)
	var agent := NavigationAgent3D.new()
	agent.name = "NavigationAgent3D"
	agent.path_desired_distance = 0.5
	agent.target_desired_distance = 0.6
	agent.radius = 0.5
	agent.height = 2.2
	_add(m, agent)
	var eye := Marker3D.new()
	eye.name = "Eye"
	eye.position = Vector3(0, 1.95, -0.3)
	_add(m, eye)
	var model := Node3D.new()
	model.name = "Model"
	_add(m, model)
	if ResourceLoader.exists(UAL):
		var body: Node3D = (load(UAL) as PackedScene).instantiate()
		body.name = "Mannequin"
		body.scale = Vector3(body_width, 1.0, body_width) * 1.2
		body.rotation_degrees.y = 180  # หุ่นหันหน้าไป +Z แต่มอนเดินไปทาง -Z
		_add(model, body)
	var points: Array[Node3D] = []
	for i in patrol.size():
		var mk := Marker3D.new()
		mk.name = "%s_Patrol%d" % [m.name, i]
		mk.position = patrol[i]
		_add(root, mk)
		points.append(mk)
	m.set("patrol_points", points)
	return m as Monster


## อบระบบนำทางของมอน (เรียกหลังวางผนังและของตั้งพื้นครบ ก่อนวางผู้เล่น มอน และของที่มีสคริปต์)
func bake(tree: SceneTree) -> int:
	tree.root.add_child(root)
	# CSG สร้างตัวชนหลังเข้า tree หนึ่งเฟรม ต้องรอก่อนอบ ไม่งั้นพื้นจะหายจากระบบนำทาง
	await tree.physics_frame
	await tree.physics_frame
	nav.bake_navigation_mesh(false)
	var polys := nav.navigation_mesh.get_polygon_count()
	tree.root.remove_child(root)
	return polys


## บันทึกฉาก
func save(path: String) -> void:
	var polys := nav.navigation_mesh.get_polygon_count()
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("BUILT ", path, " nav_polys=", polys, " err=", err)
	root.free()
