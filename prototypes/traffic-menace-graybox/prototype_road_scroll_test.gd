extends SceneTree

## 验证道路标记与主路前进方向一致，滚动量增加时屏幕纵坐标必须增大。
func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	var dash_at_zero: float = float(scene.call("_scroll_pattern_origin", -96.0, 0.0, 96.0))
	var dash_after_scroll: float = float(scene.call("_scroll_pattern_origin", -96.0, 48.0, 96.0))
	var reflector_at_zero: float = float(scene.call("_scroll_pattern_origin", -48.0, 0.0, 64.0))
	var reflector_after_scroll: float = float(scene.call("_scroll_pattern_origin", -48.0, 32.0, 64.0))
	var dash_forward_ok: bool = dash_after_scroll > dash_at_zero
	var reflector_forward_ok: bool = reflector_after_scroll > reflector_at_zero
	print("GRAYBOX_ROAD_SCROLL_TEST dash=%s reflector=%s dash_y=%s->%s reflector_y=%s->%s" % [dash_forward_ok, reflector_forward_ok, dash_at_zero, dash_after_scroll, reflector_at_zero, reflector_after_scroll])
	quit(0 if dash_forward_ok and reflector_forward_ok else 1)
