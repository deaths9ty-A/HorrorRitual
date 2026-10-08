extends SceneTree
## วัดระยะก้าวของเท้าในแต่ละท่า (เมตรต่อรอบท่า) เพื่อประเมินความเร็วที่ท่าถูกทำมา = ระยะก้าวต่อรอบ ÷ เวลารอบ
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var s: Node3D = load("res://assets/models/quaternius/ual_standard/ual_standard.glb").instantiate()
	root.add_child(s)
	var ap: AnimationPlayer = s.find_children("*", "AnimationPlayer", true, false)[0]
	var sk: Skeleton3D = s.find_children("*", "Skeleton3D", true, false)[0]
	var b := sk.find_bone("DEF-foot.L")
	for clip in ["Walk", "Jog_Fwd", "Sprint"]:
		var len := ap.get_animation(clip).length
		ap.play(clip)
		var zs := []
		var ys := []
		for i in 61:
			ap.seek(len * i / 60.0, true)
			await process_frame
			var o := sk.get_bone_global_pose(b).origin
			zs.append(o.z)
			ys.append(o.y)
		zs.sort()
		ys.sort()
		var zr: float = zs[-1] - zs[0]
		print("CLIP ", clip, " cycle_s=", snappedf(len, 0.01), " foot_z_range=", snappedf(zr, 0.02), " m  foot_lift=", snappedf(ys[-1] - ys[0], 0.02),
			" m  -> stride_per_cycle~", snappedf(zr, 0.02), " m = ~", snappedf(zr / len, 0.01), " m/s foot sweep")
	quit()
