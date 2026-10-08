@tool
class_name GrassField
extends MultiMeshInstance3D
## หญ้าทั้งทุ่งแบบเบา (ใช้ MultiMesh วาดทีเดียวหลายพันกอ) · ปรับจำนวน รัศมี ความสูงได้ใน Inspector แล้วเห็นผลในเอดิเตอร์ทันที
## เป็นงานชั่วคราวให้ทุ่งดูมีหญ้า รอเจ้าของทำหญ้าจริง · ลบโหนดนี้ทิ้งได้ถ้าไม่ต้องการ
## ค่าทั้งหมดเป็นค่าเริ่มที่ Claude ตั้ง

## จำนวนกอหญ้า (มากไปจะกิน FPS)
@export var count := 16000:
	set(v):
		count = v
		_rebuild()
## โรยหญ้าในรัศมีกี่เมตรรอบโหนดนี้
@export var radius := 45.0:
	set(v):
		radius = v
		_rebuild()
## ความสูงของกอหญ้า (เมตร) ต่ำสุดและสูงสุด
@export var min_height := 0.25:
	set(v):
		min_height = v
		_rebuild()
@export var max_height := 0.55:
	set(v):
		max_height = v
		_rebuild()
## สุ่มตำแหน่งแบบเดิมทุกครั้ง (เปลี่ยนเลขเพื่อสุ่มใหม่)
@export var seed_value := 7:
	set(v):
		seed_value = v
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _blade_mesh()
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		# โรยแบบหนาแน่นใกล้กลาง บางลงที่ขอบ
		var r := radius * sqrt(rng.randf())
		var a := rng.randf() * TAU
		var h := rng.randf_range(min_height, max_height)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(h, h, h))
		mm.set_instance_transform(i, Transform3D(b, Vector3(cos(a) * r, 0.0, sin(a) * r)))
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# กอหญ้า = แผ่นสี่เหลี่ยมไขว้กัน 3 แผ่น สูง 1 เมตร (สเกลตามความสูงที่สุ่ม)
func _blade_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var dir := Vector3(cos(k * PI / 3.0), 0.0, sin(k * PI / 3.0)) * 0.35
		var p := [-dir, dir, dir + Vector3.UP, -dir + Vector3.UP]
		var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uv[idx])
			st.add_vertex(p[idx])
	var mesh := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/grass_blade.gdshader")
	mesh.surface_set_material(0, mat)
	return mesh
