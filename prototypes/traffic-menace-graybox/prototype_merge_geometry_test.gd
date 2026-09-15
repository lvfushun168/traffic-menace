extends SceneTree

const FRAME_DELTA: float = 1.0 / 60.0
const MERGE_JUNCTION_MIN_SPACING: float = 260.0


## 启动几何专项烟测，分别验证左右支路的第一落点与完整并线过程。
func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	var left_result: Dictionary = _test_side(scene, -1)
	var right_result: Dictionary = _test_side(scene, 1)
	var multi_result: Dictionary = _test_same_side(scene, -1)
	var edge_lanes_ok: bool = int(left_result.get("target_lane", -1)) == 0 and int(right_result.get("target_lane", -1)) == 4
	var endpoints_ok: bool = bool(left_result.get("endpoint_ok", false)) and bool(right_result.get("endpoint_ok", false))
	var monotonic_ok: bool = bool(left_result.get("monotonic_ok", false)) and bool(right_result.get("monotonic_ok", false))
	var no_cross_road_ok: bool = bool(left_result.get("no_cross_road_ok", false)) and bool(right_result.get("no_cross_road_ok", false))
	var completed_ok: bool = bool(left_result.get("completed", false)) and bool(right_result.get("completed", false))
	var dynamic_spawn_ok: bool = bool(left_result.get("dynamic_spawn_ok", false)) and bool(right_result.get("dynamic_spawn_ok", false))
	var dynamic_sync_ok: bool = bool(left_result.get("dynamic_sync_ok", false)) and bool(right_result.get("dynamic_sync_ok", false))
	var recycled_ok: bool = bool(left_result.get("recycled_ok", false)) and bool(right_result.get("recycled_ok", false))
	var no_junction_without_car: bool = bool(left_result.get("no_junction_without_car", false)) and bool(right_result.get("no_junction_without_car", false))
	var multi_spawn_ok: bool = bool(multi_result.get("multi_spawn_ok", false))
	var multi_spacing_ok: bool = bool(multi_result.get("multi_spacing_ok", false))
	var multi_sync_ok: bool = bool(multi_result.get("multi_sync_ok", false))
	var multi_completed_ok: bool = bool(multi_result.get("multi_completed_ok", false))
	var multi_recycled_ok: bool = bool(multi_result.get("multi_recycled_ok", false))
	print("GRAYBOX_MERGE_GEOMETRY_TEST edges=%s endpoints=%s monotonic=%s no_cross_road=%s completed=%s no_junction=%s dynamic_spawn=%s dynamic_sync=%s recycled=%s multi_spawn=%s multi_spacing=%s multi_sync=%s multi_completed=%s multi_recycled=%s left=%s right=%s multi=%s" % [edge_lanes_ok, endpoints_ok, monotonic_ok, no_cross_road_ok, completed_ok, no_junction_without_car, dynamic_spawn_ok, dynamic_sync_ok, recycled_ok, multi_spawn_ok, multi_spacing_ok, multi_sync_ok, multi_completed_ok, multi_recycled_ok, left_result, right_result, multi_result])
	quit(0 if edge_lanes_ok and endpoints_ok and monotonic_ok and no_cross_road_ok and completed_ok and no_junction_without_car and dynamic_spawn_ok and dynamic_sync_ok and recycled_ok and multi_spawn_ok and multi_spacing_ok and multi_sync_ok and multi_completed_ok and multi_recycled_ok else 1)


## 清理场景后生成一辆指定侧的支路车辆，并记录它的真实曲线路径。
func _test_side(scene: Node, side: int) -> Dictionary:
	var cleared_traffic: Array = scene.get("traffic")
	cleared_traffic.clear()
	scene.set("traffic", cleared_traffic)
	scene.set("hazards", [])
	scene.set("road_events", [])
	scene.set("merge_queue_count", 1)
	scene.set("merge_spawned_count", 0)
	scene.set("merge_source_clock", 0.0)
	scene.set("merge_release_cooldown", 0.0)
	var cleared_junctions: Array = scene.get("merge_junctions")
	cleared_junctions.clear()
	scene.set("merge_junctions", cleared_junctions)
	var no_junction_without_car: bool = (scene.get("merge_junctions") as Array).is_empty()
	scene.set("merge_side_toggle", side)
	scene.call("_update_merge_source", 0.0, 0.0, 30)
	var cars: Array = scene.get("traffic")
	if cars.is_empty():
		return {"target_lane": -1}
	var car: Dictionary = cars[0]
	var junctions: Array = scene.get("merge_junctions")
	if junctions.is_empty():
		return {"target_lane": -1, "dynamic_spawn_ok": false}
	var junction: Dictionary = junctions[0]
	var target_lane: int = int(car.get("merge_target_lane", -1))
	var start_x: float = float(car.get("x", 0.0))
	var start_y: float = float(car.get("y", 0.0))
	var start_junction_y: float = float(junction.get("y", 0.0))
	var dynamic_spawn_ok: bool = start_junction_y < 0.0 and start_y < 0.0 and str(car.get("merge_phase", "")) == "APPROACH"
	var previous_x: float = start_x
	var previous_junction_y: float = start_junction_y
	var monotonic_ok: bool = true
	var no_cross_road_ok: bool = true
	var dynamic_sync_ok: bool = true
	var junction_moved_down: bool = false
	var completed: bool = false
	var end_x: float = start_x
	var end_y: float = start_y
	for _frame in range(900):
		scene.call("_update_merge_junctions", FRAME_DELTA)
		scene.call("_update_traffic", FRAME_DELTA)
		junctions = scene.get("merge_junctions")
		if junctions.is_empty():
			break
		junction = junctions[0]
		var current_junction_y: float = float(junction.get("y", previous_junction_y))
		junction_moved_down = junction_moved_down or current_junction_y > start_junction_y + 0.1
		dynamic_sync_ok = dynamic_sync_ok and current_junction_y >= previous_junction_y - 0.1
		var current_x: float = float(car.get("x", 0.0))
		var current_y: float = float(car.get("y", 0.0))
		var current_phase: String = str(car.get("merge_phase", ""))
		if current_phase == "APPROACH":
			dynamic_sync_ok = dynamic_sync_ok and absf(current_y - current_junction_y - 84.0) < 1.0
		if not bool(car.get("merge_completed", false)):
			monotonic_ok = monotonic_ok and (current_x >= previous_x - 0.1 if side < 0 else current_x <= previous_x + 0.1)
		if current_phase == "MERGING" or bool(car.get("merge_completed", false)):
			var body_size: Vector2 = scene.call("_car_dimensions", str(car.get("kind", "SEDAN")))
			var current_road_left: float = float(scene.get("road_left"))
			var current_road_right: float = current_road_left + float(scene.get("road_width"))
			var body_left: float = current_x - body_size.x * 0.5
			var body_right: float = current_x + body_size.x * 0.5
			# 车辆从路外进入时允许暂时保留支路侧的车身，不能越过主路的另一侧；完全进入主路后再要求车身完整落在边界内。
			if side < 0:
				no_cross_road_ok = no_cross_road_ok and body_right <= current_road_right + 0.1
			else:
				no_cross_road_ok = no_cross_road_ok and body_left >= current_road_left - 0.1
			if bool(car.get("merge_completed", false)):
				no_cross_road_ok = no_cross_road_ok and body_left >= current_road_left - 0.1 and body_right <= current_road_right + 0.1
		previous_x = current_x
		previous_junction_y = current_junction_y
		if bool(car.get("merge_completed", false)):
			completed = true
			end_x = current_x
			end_y = current_y
			break
	var expected_x: float = float(scene.call("_lane_x", target_lane))
	var expected_y: float = float(junction.get("y", scene.call("_merge_gate_y"))) if not junction.is_empty() else float(scene.call("_merge_gate_y"))
	var expected_flow_y: float = expected_y + float(car.get("merge_flow_offset", 0.0))
	var endpoint_ok: bool = completed and absf(end_x - expected_x) < 0.1 and absf(end_y - expected_flow_y) < 2.0
	var recycled_ok: bool = false
	for _frame in range(1100):
		scene.call("_update_merge_junctions", FRAME_DELTA)
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_cleanup_entities")
		if (scene.get("merge_junctions") as Array).is_empty():
			recycled_ok = true
			break
	return {
		"target_lane": target_lane,
		"start": Vector2(start_x, start_y),
		"end": Vector2(end_x, end_y),
		"monotonic_ok": monotonic_ok,
		"no_cross_road_ok": no_cross_road_ok,
		"endpoint_ok": endpoint_ok,
		"completed": completed,
		"dynamic_spawn_ok": dynamic_spawn_ok,
		"dynamic_sync_ok": dynamic_sync_ok and junction_moved_down,
		"recycled_ok": recycled_ok,
		"no_junction_without_car": no_junction_without_car,
	}


## 验证同侧第二段道路只能在满足最小间距后生成，并与第一段分别完成回收。
func _test_same_side(scene: Node, side: int) -> Dictionary:
	var cleared_traffic: Array = scene.get("traffic")
	cleared_traffic.clear()
	scene.set("traffic", cleared_traffic)
	scene.set("hazards", [])
	scene.set("road_events", [])
	scene.set("merge_queue_count", 2)
	scene.set("merge_spawned_count", 0)
	scene.set("merge_source_clock", 0.0)
	scene.set("merge_release_cooldown", 0.0)
	scene.set("merge_side_toggle", side)
	var first_spawned: bool = bool(scene.call("_try_spawn_merge_car", 30, 0.0))
	var first_traffic: Array = scene.get("traffic")
	var first_id: int = int(first_traffic[0].get("id", -1)) if first_spawned and not first_traffic.is_empty() else -1
	var spacing_frames: int = int(ceil(MERGE_JUNCTION_MIN_SPACING / (float(scene.get("player_speed")) * 3.0 * FRAME_DELTA))) + 2
	for _frame in range(spacing_frames):
		scene.call("_update_merge_junctions", FRAME_DELTA)
	scene.set("merge_side_toggle", side)
	scene.set("merge_release_cooldown", 0.0)
	var second_spawned: bool = bool(scene.call("_try_spawn_merge_car", 30, 0.0))
	var second_traffic: Array = scene.get("traffic")
	var second_id: int = int(second_traffic[1].get("id", -1)) if second_spawned and second_traffic.size() > 1 else -1
	var junctions: Array = scene.get("merge_junctions")
	var multi_spawn_ok: bool = first_spawned and second_spawned and junctions.size() == 2
	var multi_spacing_ok: bool = false
	if junctions.size() == 2:
		var first_y: float = float(junctions[0].get("y", 0.0))
		var second_y: float = float(junctions[1].get("y", 0.0))
		multi_spacing_ok = absf(first_y - second_y) >= MERGE_JUNCTION_MIN_SPACING - 0.1

	var multi_sync_ok: bool = true
	for _frame in range(80):
		scene.call("_update_merge_junctions", FRAME_DELTA)
		scene.call("_update_traffic", FRAME_DELTA)
		var current_junctions: Array = scene.get("merge_junctions")
		for junction in current_junctions:
			var junction_id: int = int(junction.get("id", -1))
			for car in scene.get("traffic") as Array:
				if int(car.get("id", -2)) != junction_id:
					continue
				if str(car.get("merge_phase", "")) == "APPROACH":
					multi_sync_ok = multi_sync_ok and absf(float(car.get("y", 0.0)) - float(junction.get("y", 0.0)) - 84.0) < 1.0
				break

	var completed_ids: Array[int] = []
	var multi_recycled_ok: bool = false
	for _frame in range(2400):
		scene.call("_update_merge_junctions", FRAME_DELTA)
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_cleanup_entities")
		for car in scene.get("traffic") as Array:
			var car_id: int = int(car.get("id", -1))
			if (car_id == first_id or car_id == second_id) and bool(car.get("merge_completed", false)) and not completed_ids.has(car_id):
				completed_ids.append(car_id)
		if (scene.get("merge_junctions") as Array).is_empty():
			multi_recycled_ok = true
			break
	var multi_completed_ok: bool = completed_ids.size() >= 2
	return {
		"multi_spawn_ok": multi_spawn_ok,
		"multi_spacing_ok": multi_spacing_ok,
		"multi_sync_ok": multi_sync_ok,
		"multi_completed_ok": multi_completed_ok,
		"multi_recycled_ok": multi_recycled_ok,
	}
