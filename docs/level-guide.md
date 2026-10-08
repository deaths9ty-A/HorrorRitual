# คู่มือจัดวางด่าน (ฉบับสั้น)

> เขียน 7 ต.ค. 2026 · ด่านแรก: `game/scenes/levels/level_01_field.tscn` (ทุ่งโล่ง สว่าง)
> ขั้นตอนเขียนจากเอกสาร Godot และความรู้ของ Claude · ยังไม่ได้ลองเปิดเอดิเตอร์ 4.8-dev7 แบบมีหน้าจอ ชื่อปุ่มอาจต่างเล็กน้อย

## เปิดด่าน
1. Godots → HorrorRitual → แก้ไข (4.8-dev7)
2. แผง FileSystem (ซ้ายล่าง) → `scenes/levels/level_01_field.tscn` → ดับเบิลคลิก
3. บินดูฉาก: เมาส์ขวาค้าง + WASD · F6 = เล่นเฉพาะด่านนี้

## ในด่านมีอะไร (แผง Scene ซ้ายบน)
| โหนด | คืออะไร | แก้ยังไง |
|---|---|---|
| `WorldEnvironment` | ท้องฟ้า (Poly Haven, CC0) หมอก แสงรอบตัว | Inspector > Environment > Sky (เปลี่ยนภาพท้องฟ้า) · Fog (หมอก) |
| `Sun` | แสงแดด | หมุนเพื่อเปลี่ยนทิศแดด · Light > Energy = ความแรง |
| `Navigation/Ground` | พื้นหญ้า 240×240 ม. เสียงเท้า = หญ้า | Size = ขนาด · Material = พื้นผิว |
| `Boundary` | กำแพงล่องหนรอบด่าน | ย้าย CollisionShape3D ลูก ๆ ตามขนาดด่าน |
| `GrassField` | หญ้าชั่วคราว (ทำเอง ไม่ใช่งานจริง) | Count / Radius / ความสูง ปรับแล้วเห็นทันที · ลบทิ้งได้ |
| `Player` | ผู้เล่น | ย้ายไปจุดเริ่ม |
| `Checkpoint` | จุดเกิดใหม่ตอนตาย | ย้ายพร้อม `Spawn` ข้างใน |

## ขึ้นรูปคร่าว ๆ (blockout)
- เลือกโหนด `Navigation` → Ctrl+A → `CSGBox3D` → ติ๊ก **Use Collision** (ชนได้)
- W = ย้าย · E = หมุน · ปรับขนาดที่ Size หรือจุดจับในฉาก
- เสียงเท้าตามพื้น: Inspector ล่างสุด → Add Metadata → ชื่อ `surface` ค่า `wood` `carpet` `metal` `tile` `grass`
- CSG มีไว้ทำต้นแบบ แปลงเป็น mesh ได้ด้วย Bake Mesh Instance และส่งออกทั้งฉากเป็น glTF ไปทำต่อใน Blender ได้ ([เอกสาร Godot](https://docs.godotengine.org/en/latest/tutorials/3d/csg_tools.html))

## วางของตกแต่ง
- ลาก `.gltf` จาก `assets/models/polyhaven/` ลงฉาก
- ⚠️ ของที่ลากมาตรง ๆ **ไม่มีตัวชน** (เดินทะลุ) · ถ้าต้องชน: เลือกโมเดล → เมนู Mesh บนแถบด้านบน → Create Collision Shape (ยังไม่ได้ลองใน 4.8-dev7)

## หลังขยับผนังหรือของ (ถ้าด่านมีมอน)
- เลือก `Navigation` → กดปุ่มอบ (Bake NavigationMesh) บนแถบด้านบน ไม่งั้นมอนเดินตามทางเก่า

## ทดสอบในเกม
- เมนูหลัก → โหมดเอดิเตอร์ → เทสแมพ → "ด่าน 1 · ทุ่งโล่ง (แม่แบบ)"

## ⚠️ ห้าม
- ห้ามรัน `dev/build/build_level_01.gd` อีกหลังจากแก้ด่านเอง (สคริปต์จะสร้างด่านใหม่ทับ)
