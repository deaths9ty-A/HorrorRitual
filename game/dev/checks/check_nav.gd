extends SceneTree
## เทสกันพัง: ระบบนำทางของฉากไล่ล่าเลี่ยงเฟอร์นิเจอร์ไหม (เครื่องมือของนักพัฒนา)

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var scene: Node = load("res://scenes/chase/lair_hearing.tscn").instantiate()
	root.add_child(scene)
	var nav: NavigationRegion3D = scene.get_node("Navigation")
	var nm := nav.navigation_mesh
	var verts := nm.get_vertices()
	print("polys=", nm.get_polygon_count(), " verts=", verts.size())
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		var pts := []
		for idx in poly:
			pts.append(Vector2(snappedf(verts[idx].x, 0.1), snappedf(verts[idx].z, 0.1)))
		print("  poly ", i, " y=", snappedf(verts[poly[0]].y, 0.01), " ", pts)
	var bed := scene.get_node("Navigation/GothicBed_01")
	print("bed children: ", bed.get_children().map(func(c): return c.get_class()))
	quit()
