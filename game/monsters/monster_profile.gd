class_name MonsterProfile
extends Resource
## ค่าของมอนหนึ่งชนิด (เก็บเป็นไฟล์ .tres แก้ใน Inspector) · แต่ละชนิดมีประสาทสัมผัสต่างกันแบบ Little Nightmares
## ค่าตัวเลขทั้งหมดเป็นค่าเริ่มที่ Claude ตั้ง

@export var display_name := "มอน"

@export_group("ความเร็ว (เมตร/วินาที)")
## เดินตรวจ
@export var patrol_speed := 1.4
## เดินไปดูจุดที่ได้ยินเสียง
@export var investigate_speed := 2.2
## ไล่ (ผู้เล่นวิ่ง 6.5 · เดิน 4.0)
@export var chase_speed := 5.2
## หมุนตัวเร็วแค่ไหน (เรเดียน/วินาที) · 4 ≈ 230°/วินาที
@export var turn_speed := 4.0
## ออกตัว/เร่งความเร็วขึ้นกี่ม./วิ ต่อวินาที (ยิ่งน้อยยิ่งมีน้ำหนัก คนจริงราว 3–6)
@export var accel := 6.0
## ชะลอ/หยุดกี่ม./วิ ต่อวินาที
@export var decel := 9.0

@export_group("หู (แบบ Janitor)")
## ได้ยินไหม
@export var can_hear := true
## ความไวหู: คูณระยะเสียง (1 = ได้ยินตามระยะที่เสียงไปถึง · 2 = หูดีสองเท่า)
@export var hearing_scale := 1.0

@export_group("ตา (แบบ Chef)")
## มองเห็นไหม (Janitor ตาบอด = ปิด)
@export var can_see := true
## มองได้ไกลกี่เมตร
@export var sight_range := 12.0
## มุมมองกว้างกี่องศา
@export var sight_fov_deg := 100.0
## ตอนกำลังค้นหา ถ้าเข้ามาใกล้จุดซ่อนไม่เกินกี่เมตรจะเห็นผู้เล่นที่ซ่อนอยู่ (0 = ไม่เห็นเลย)
@export var peek_hidden_distance := 0.0

@export_group("ไล่และค้นหา")
## มองไม่เห็นหรือไม่ได้ยินผู้เล่นนานเท่านี้ (วินาที) จะเลิกไล่แล้วค้นหาแทน
@export var lose_target_time := 2.5
## ค้นหารอบจุดสุดท้ายนานกี่วินาที ก่อนกลับไปเดินตรวจ
@export var search_time := 8.0
## ค้นหาในรัศมีกี่เมตรจากจุดสุดท้าย
@export var search_radius := 4.0
## จับได้เมื่อผู้เล่นอยู่ใกล้กว่านี้ (เมตร)
@export var catch_range := 1.1

@export_group("แสง (แบบ Patients ใน LN2)")
## โดนแสงแล้วหยุดนิ่ง ขยับได้เฉพาะตอนอยู่ในที่มืด
@export var frozen_by_light := false
## ตื่นแล้วไล่เองเมื่อผู้เล่นเข้ามาใกล้กว่านี้ (เมตร) · 0 = ใช้ตาหูตามปกติ
@export var wake_distance := 0.0

@export_group("เสียงหัวใจของผู้เล่น")
## มอนชนิดนี้ทำให้หัวใจผู้เล่นเต้นแบบไหน
## NONE = ไม่มีผล · AWARENESS = ตามที่มันรู้ตัว (เดินมาดู ไล่) · PROXIMITY = ยิ่งเข้าใกล้ยิ่งดัง
@export_enum("NONE", "AWARENESS", "PROXIMITY") var heartbeat := 1
## (PROXIMITY) เริ่มได้ยินเสียงหัวใจเมื่อมอนเข้ามาใกล้กว่ากี่เมตร
@export var heartbeat_range := 14.0

@export_group("ชื่อท่าในโมเดล (ว่าง = ไม่เล่นท่า)")
@export var anim_idle := ""
@export var anim_walk := ""
@export var anim_run := ""
## ท่าวิ่งเร็ว (ใช้ตอนความเร็วใกล้กับท่านี้มากที่สุด)
@export var anim_sprint := ""
@export var anim_catch := ""
## ความเร็วที่ท่าถูกทำมา (เมตร/วินาที) ใช้ปรับความเร็วท่าให้เท้าไม่ไถล · ค่าประเมินจากระยะก้าวเท้า ยังไม่ได้ตรวจด้วยตา
## ถ้าเห็นเท้าไถลไปข้างหน้า = ใส่ค่าให้มากขึ้น · เท้าไถลถอยหลัง = ให้น้อยลง
@export var anim_walk_speed := 1.0
@export var anim_run_speed := 2.8
@export var anim_sprint_speed := 4.7
