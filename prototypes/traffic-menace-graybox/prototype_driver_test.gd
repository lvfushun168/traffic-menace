extends SceneTree

const FRAME_DELTA: float = 1.0 / 60.0


func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")
	var opening_traffic: Array = scene.get("traffic")
	opening_traffic.clear()
	scene.set("traffic", opening_traffic)

	var cautious: Dictionary = scene.call("_driver_profile", "CAUTIOUS")
	var normal: Dictionary = scene.call("_driver_profile", "NORMAL")
	var aggressive: Dictionary = scene.call("_driver_profile", "AGGRESSIVE")
	var profile_order_ok: bool = (
		float(cautious["reaction_distance"]) > float(normal["reaction_distance"])
		and float(normal["reaction_distance"]) > float(aggressive["reaction_distance"])
		and float(cautious["follow_gap"]) > float(normal["follow_gap"])
		and float(normal["follow_gap"]) > float(aggressive["follow_gap"])
		and float(cautious["lateral_speed"]) < float(normal["lateral_speed"])
		and float(normal["lateral_speed"]) < float(aggressive["lateral_speed"])
		and float(cautious["overtake_trigger_distance"]) < float(normal["overtake_trigger_distance"])
		and float(normal["overtake_trigger_distance"]) < float(aggressive["overtake_trigger_distance"])
	)
	var speed_profile_ok: bool = (
		absf(float(cautious["speed_min"]) - 39.1) < 0.01
		and absf(float(cautious["speed_max"]) - 46.0) < 0.01
		and absf(float(cautious["follow_speed"]) - 39.1) < 0.01
		and absf(float(cautious["overtake_speed"]) - 52.9) < 0.01
		and absf(float(cautious["pass_burst_speed"]) - 62.1) < 0.01
		and absf(float(normal["speed_min"]) - 43.7) < 0.01
		and absf(float(normal["speed_max"]) - 52.9) < 0.01
		and absf(float(normal["follow_speed"]) - 41.4) < 0.01
		and absf(float(normal["overtake_speed"]) - 59.8) < 0.01
		and absf(float(normal["pass_burst_speed"]) - 78.2) < 0.01
		and absf(float(aggressive["speed_min"]) - 55.2) < 0.01
		and absf(float(aggressive["speed_max"]) - 64.4) < 0.01
		and absf(float(aggressive["follow_speed"]) - 48.3) < 0.01
		and absf(float(aggressive["overtake_speed"]) - 69.0) < 0.01
		and absf(float(aggressive["pass_burst_speed"]) - 103.5) < 0.01
		and absf(float(cautious["brake_speed"]) - 28.0) < 0.01
		and absf(float(normal["brake_speed"]) - 30.0) < 0.01
		and absf(float(aggressive["brake_speed"]) - 34.0) < 0.01
	)

	var lane_count: int = (scene.get("lane_centers") as Array).size()
	var lane_center: float = float(scene.call("_lane_x", 2))
	var lane_width: float = float(scene.get("lane_width"))
	var road_left: float = float(scene.get("road_left"))
	var road_width: float = float(scene.get("road_width"))
	var player_y: float = float(scene.get("player_y"))
	var lane_layout_ok: bool = lane_count == 5 and absf(road_width - 510.0) < 1.0 and absf(lane_width - 102.0) < 1.0 and int(scene.get("player_lane")) == 2
	var cars: Array[Dictionary] = []
	for index in range(3):
		var driver_type: String = ["CAUTIOUS", "NORMAL", "AGGRESSIVE"][index]
		scene.call("_spawn_traffic", "SEDAN", 2, player_y + 600.0 + float(index) * 180.0, 40.0, driver_type == "AGGRESSIVE", driver_type)
	cars = scene.get("traffic")
	for car in cars:
		car["wander_phase"] = 0.0
	for _frame in range(30):
		scene.call("_update_traffic", FRAME_DELTA)

	var cautious_car: Dictionary = cars[0]
	var normal_car: Dictionary = cars[1]
	var aggressive_car: Dictionary = cars[2]
	var cautious_offset: float = absf(float(cautious_car["x"]) - lane_center)
	var normal_offset: float = absf(float(normal_car["x"]) - lane_center)
	var aggressive_offset: float = absf(float(aggressive_car["x"]) - lane_center)
	var divider_index: int = 2 + (1 if int(aggressive_car["divider_side"]) > 0 else 0)
	var divider_x: float = road_left + lane_width * float(divider_index)
	var touched_lanes: Array[int] = scene.call("_lanes_touched_by_car", aggressive_car)
	var lateral_style_ok: bool = (
		cautious_offset < lane_width * 0.12
		and normal_offset > cautious_offset + 4.0
		and aggressive_offset > normal_offset
		and absf(float(aggressive_car["x"]) - divider_x) < lane_width * 0.18
		and touched_lanes.size() >= 2
	)

	var bounds_ok: bool = true
	for car in cars:
		var body_width: float = float((scene.call("_car_dimensions", str(car["kind"])) as Vector2).x)
		bounds_ok = bounds_ok and float(car["x"]) >= road_left + body_width * 0.5 - 0.1
		bounds_ok = bounds_ok and float(car["x"]) <= road_left + road_width - body_width * 0.5 + 0.1

	var cautious_triggered: Dictionary = _setup_single_car(scene, "CAUTIOUS", 300.0)
	scene.call("_update_traffic", FRAME_DELTA)
	var cautious_trigger_ok: bool = not bool(cautious_triggered["attempted_pass"])
	var normal_triggered: Dictionary = _setup_single_car(scene, "NORMAL", 300.0)
	scene.call("_update_traffic", FRAME_DELTA)
	var normal_trigger_ok: bool = bool(normal_triggered["attempted_pass"]) and str(normal_triggered["state"]) == "PREPARE OVERTAKE"
	var aggressive_triggered: Dictionary = _setup_single_car(scene, "AGGRESSIVE", 300.0)
	scene.call("_update_traffic", FRAME_DELTA)
	var aggressive_trigger_ok: bool = bool(aggressive_triggered["attempted_pass"]) and str(aggressive_triggered["state"]) == "PREPARE OVERTAKE"

	var cautious_commit: Dictionary = _setup_single_car(scene, "CAUTIOUS", 120.0)
	scene.call("_update_traffic", FRAME_DELTA)
	var normal_commit: Dictionary = _setup_single_car(scene, "NORMAL", 120.0)
	scene.call("_update_traffic", FRAME_DELTA)
	var aggressive_commit: Dictionary = _setup_single_car(scene, "AGGRESSIVE", 120.0)
	scene.call("_update_traffic", FRAME_DELTA)
	var commit_order_ok: bool = (
		str(cautious_commit["state"]) == "LANE CHANGE"
		and str(normal_commit["state"]) == "LANE CHANGE"
		and str(aggressive_commit["state"]) == "LANE CHANGE"
	)
	var aggressive_pass_peak_speed: float = _measure_overtake_peak_speed(scene, "AGGRESSIVE")
	var aggressive_pass_speed_ok: bool = aggressive_pass_peak_speed >= 103.0

	var cautious_reaction_speed: float = _measure_blocked_speed(scene, "CAUTIOUS")
	var cautious_reaction_state: String = str((scene.get("traffic") as Array)[0].get("state", ""))
	var normal_reaction_speed: float = _measure_blocked_speed(scene, "NORMAL")
	var aggressive_reaction_speed: float = _measure_blocked_speed(scene, "AGGRESSIVE")
	var reaction_order_ok: bool = (
		cautious_reaction_speed < normal_reaction_speed
		and normal_reaction_speed <= aggressive_reaction_speed
		and cautious_reaction_state in ["WAIT", "BRAKE", "BLOCKED", "PREPARE OVERTAKE"]
	)
	var actual_gap_choice_ok: bool = _test_actual_gap_choice(scene)
	var multi_hop_ok: bool = _test_aggressive_multi_hop(scene)
	var no_rear_end_ok: bool = _test_no_player_rear_end(scene)
	var weaving_player_pass_ok: bool = _test_weaving_player_allows_pass(scene)
	var vehicle_bounds_ok: bool = _test_vehicle_width_bounds(scene)
	var side_collision_ok: bool = _test_player_side_collision(scene)
	var same_speed_overtake_ok: bool = _test_same_speed_overtake(scene)
	var right_lane_choice_ok: bool = _test_right_lane_choice(scene)

	print("GRAYBOX_DRIVER_TEST lanes=%s layout=%s profile_order=%s speed_profile=%s pass_speed=%s peak=%.1f lateral_style=%s types=%s/%s/%s offsets=%.1f/%.1f/%.1f x=%.1f/%.1f/%.1f targets=%.1f/%.1f/%.1f cruise=%.2f/%.2f/%.2f divider_x=%.1f touched=%s bounds=%s" % [lane_count, lane_layout_ok, profile_order_ok, speed_profile_ok, aggressive_pass_speed_ok, aggressive_pass_peak_speed, lateral_style_ok, str(cautious_car["driver_type"]), str(normal_car["driver_type"]), str(aggressive_car["driver_type"]), cautious_offset, normal_offset, aggressive_offset, float(cautious_car["x"]), float(normal_car["x"]), float(aggressive_car["x"]), float(cautious_car["lateral_target_x"]), float(normal_car["lateral_target_x"]), float(aggressive_car["lateral_target_x"]), float(cautious_car["cruise_offset"]), float(normal_car["cruise_offset"]), float(aggressive_car["cruise_offset"]), divider_x, touched_lanes, bounds_ok])
	print("GRAYBOX_DRIVER_TEST trigger=cautious:%s normal:%s aggressive:%s commit_order=%s reaction_order=%s gap_choice=%s right_choice=%s same_speed=%s multi_hop=%s no_rear_end=%s weave_pass=%s vehicle_bounds=%s side_collision=%s states=%s speeds=%.1f/%.1f/%.1f" % [cautious_trigger_ok, normal_trigger_ok, aggressive_trigger_ok, commit_order_ok, reaction_order_ok, actual_gap_choice_ok, right_lane_choice_ok, same_speed_overtake_ok, multi_hop_ok, no_rear_end_ok, weaving_player_pass_ok, vehicle_bounds_ok, side_collision_ok, cautious_reaction_state, cautious_reaction_speed, normal_reaction_speed, aggressive_reaction_speed])
	quit(0 if lane_layout_ok and profile_order_ok and speed_profile_ok and aggressive_pass_speed_ok and lateral_style_ok and bounds_ok and cautious_trigger_ok and normal_trigger_ok and aggressive_trigger_ok and commit_order_ok and reaction_order_ok and actual_gap_choice_ok and right_lane_choice_ok and same_speed_overtake_ok and multi_hop_ok and no_rear_end_ok and weaving_player_pass_ok and vehicle_bounds_ok and side_collision_ok else 1)


## 清空交通场景并放置一辆可重复测试的指定人格车辆。
func _setup_single_car(scene: Node, driver_type: String, gap: float) -> Dictionary:
	var cleared_traffic: Array = scene.get("traffic")
	cleared_traffic.clear()
	scene.set("traffic", cleared_traffic)
	scene.set("hazards", [])
	scene.set("road_events", [])
	scene.set("loose_props", [])
	scene.set("run_time", 0.0)
	scene.set("player_speed", 40.0)
	scene.set("player_x", float(scene.call("_lane_x", 2)))
	scene.set("previous_player_x", float(scene.call("_lane_x", 2)))
	scene.set("player_lane", 2)
	scene.call("_spawn_traffic", "SEDAN", 2, float(scene.get("player_y")) + gap, 40.0, driver_type == "AGGRESSIVE", driver_type)
	var cars: Array[Dictionary] = scene.get("traffic")
	var car: Dictionary = cars[0]
	car["x"] = float(scene.call("_lane_x", 2))
	car["previous_x"] = car["x"]
	car["lateral_target_x"] = car["x"]
	car["cruise_offset"] = 0.0
	car["divider_side"] = 1
	car["wander_phase"] = 0.0
	car["initial_behind"] = true
	car["attempted_pass"] = false
	car["passed"] = false
	car["state"] = "CRUISE"
	car["speed"] = 40.0
	car["previous_y"] = car["y"]
	car["previous_speed"] = 40.0
	car["route_plan"] = []
	car["route_index"] = 0
	car["maneuver_reason"] = ""
	car["replan_cooldown"] = 0.0
	car["lane_change_commit_timer"] = 0.0
	car["lane_reservation"] = -1
	car["lane_reservation_timer"] = 0.0
	car["base_speed"] = 40.0
	car["speed_command"] = 40.0
	car["brake_reason"] = ""
	car["speed_shock_target"] = -1.0
	car["speed_shock_timer"] = 0.0
	car["speed_shock_memory_timer"] = 0.0
	car["speed_shock_source"] = ""
	car["speed_shock_latched"] = false
	car["follow_front_id"] = -1
	car["follow_front_speed_seen"] = 40.0
	car["follow_reaction_timer"] = 0.0
	car["contact_cooldown"] = 0.0
	car["crash_cause"] = ""
	car["crash_block_timer"] = 0.0
	cars[0] = car
	scene.set("traffic", cars)
	return car


## 清空司机行为测试场景，恢复中间车道的玩家和无障碍道路。
func _clear_driver_test_world(scene: Node) -> void:
	var cleared_traffic: Array = scene.get("traffic")
	cleared_traffic.clear()
	scene.set("traffic", cleared_traffic)
	var empty_hazards: Array[Dictionary] = []
	var empty_road_events: Array[Dictionary] = []
	var empty_props: Array[Dictionary] = []
	var empty_items: Array[String] = ["", "", ""]
	scene.set("hazards", empty_hazards)
	scene.set("road_events", empty_road_events)
	scene.set("loose_props", empty_props)
	scene.set("active_effects", {})
	scene.set("item_slots", empty_items)
	scene.set("player_speed", 40.0)
	scene.set("player_x", float(scene.call("_lane_x", 2)))
	scene.set("previous_player_x", float(scene.call("_lane_x", 2)))
	scene.set("player_lane", 2)
	scene.set("player_collision_cooldown", 0.0)
	scene.set("durability", 10)
	scene.set("run_time", 0.0)


## 验证激进司机会避开近处堵塞车道，选择实际更宽的相邻空隙。
func _test_actual_gap_choice(scene: Node) -> bool:
	_clear_driver_test_world(scene)
	var player_y: float = float(scene.get("player_y"))
	scene.call("_spawn_traffic", "SEDAN", 2, player_y + 420.0, 40.0, true, "AGGRESSIVE")
	var cars: Array[Dictionary] = scene.get("traffic")
	var aggressive_car: Dictionary = cars[0]
	aggressive_car["x"] = float(scene.call("_lane_x", 2))
	aggressive_car["lateral_target_x"] = aggressive_car["x"]
	aggressive_car["cruise_offset"] = 0.0
	aggressive_car["divider_side"] = 1
	aggressive_car["previous_lane"] = -1
	aggressive_car["overtake_hops"] = 0
	scene.call("_spawn_traffic", "BUS", 1, float(aggressive_car["y"]) - 130.0, 40.0, false, "NORMAL")
	cars = scene.get("traffic")
	var blocking_bus: Dictionary = cars[1]
	blocking_bus["x"] = float(scene.call("_lane_x", 1))
	blocking_bus["lateral_target_x"] = blocking_bus["x"]
	blocking_bus["cruise_offset"] = 0.0
	return int(scene.call("_choose_overtake_lane", aggressive_car)) == 3


## 验证普通和谨慎司机与玩家同速时，横向准备完成后会继续换道。
func _test_same_speed_overtake(scene: Node) -> bool:
	var all_ok: bool = true
	for driver_type in ["CAUTIOUS", "NORMAL"]:
		var car: Dictionary = _setup_single_car(scene, driver_type, 300.0)
		var first_transition_frame: int = -1
		var first_transition_state: String = ""
		for frame in range(90):
			scene.call("_update_traffic", FRAME_DELTA)
			var state: String = str(car.get("state", ""))
			if first_transition_frame < 0 and state != "PREPARE OVERTAKE":
				first_transition_frame = frame + 1
				first_transition_state = state
		var transitioned_to_maneuver: bool = first_transition_state in ["LANE CHANGE", "PASS PLAYER", "CRUISE", "RECOVER"]
		all_ok = all_ok and first_transition_frame > 0 and first_transition_frame <= 60 and transitioned_to_maneuver and not bool(car.get("crashed", false))
	return all_ok


## 验证左侧近处被占用时，普通司机会选择右侧安全车道。
func _test_right_lane_choice(scene: Node) -> bool:
	var car: Dictionary = _setup_single_car(scene, "NORMAL", 300.0)
	var player_y: float = float(scene.get("player_y"))
	scene.call("_spawn_traffic", "BUS", 1, player_y + 285.0, 40.0, false, "NORMAL")
	var cars: Array[Dictionary] = scene.get("traffic")
	var blocking_bus: Dictionary = cars[1]
	var blocker_x: float = float(scene.call("_lane_x", 1))
	blocking_bus["x"] = blocker_x
	blocking_bus["previous_x"] = blocker_x
	blocking_bus["lateral_target_x"] = blocker_x
	blocking_bus["cruise_offset"] = 0.0
	cars[1] = blocking_bus
	scene.set("traffic", cars)
	var route: Array[int] = scene.call("_plan_overtake_route", car)
	return not route.is_empty() and int(route[0]) == 3 and int(scene.call("_choose_overtake_lane", car)) == 3


## 验证激进司机在五道空路上可以连续完成四次相邻车道变更。
func _test_aggressive_multi_hop(scene: Node) -> bool:
	_clear_driver_test_world(scene)
	var player_y: float = float(scene.get("player_y"))
	scene.call("_spawn_traffic", "SEDAN", 0, player_y + 520.0, 40.0, true, "AGGRESSIVE")
	var cars: Array[Dictionary] = scene.get("traffic")
	var aggressive_car: Dictionary = cars[0]
	aggressive_car["x"] = float(scene.call("_lane_x", 0))
	aggressive_car["lateral_target_x"] = aggressive_car["x"]
	aggressive_car["cruise_offset"] = 0.0
	aggressive_car["divider_side"] = 1
	aggressive_car["previous_lane"] = -1
	aggressive_car["overtake_hops"] = 0
	var route_ok: bool = true
	for expected_lane in range(1, 5):
		scene.call("_complete_overtake_segment", aggressive_car, expected_lane)
		route_ok = route_ok and int(aggressive_car["lane"]) == expected_lane and int(aggressive_car["overtake_hops"]) == expected_lane
	return route_ok and str(aggressive_car["state"]) == "PASS PLAYER" and int(aggressive_car["previous_lane"]) == 3


## 验证不同人格和车身在无玩家横向输入时都不会追尾玩家。
func _test_no_player_rear_end(scene: Node) -> bool:
	var all_safe: bool = true
	for driver_type in ["CAUTIOUS", "NORMAL", "AGGRESSIVE"]:
		for kind in ["SEDAN", "BUS"]:
			_clear_driver_test_world(scene)
			var player_y: float = float(scene.get("player_y"))
			scene.call("_spawn_traffic", kind, 2, player_y + 150.0, 90.0, driver_type == "AGGRESSIVE", driver_type)
			var cars: Array[Dictionary] = scene.get("traffic")
			var car: Dictionary = cars[0]
			car["x"] = float(scene.call("_lane_x", 2))
			car["lateral_target_x"] = car["x"]
			car["cruise_offset"] = 0.0
			car["previous_lane"] = -1
			car["overtake_hops"] = 0
			car["initial_behind"] = false
			car["attempted_pass"] = false
			car["passed"] = false
			car["state"] = "CRUISE"
			car["speed"] = 90.0
			car["base_speed"] = 90.0
			for _frame in range(120):
				scene.call("_update_traffic", FRAME_DELTA)
				scene.call("_resolve_player_collisions")
			var safe_y: float = float(scene.call("_player_rear_safe_y", car))
			all_safe = all_safe and not bool(car.get("crashed", false)) and int(scene.get("durability")) == 10 and float(car["y"]) >= safe_y - 0.1
	return all_safe


## 验证玩家持续左右变道时，激进司机仍能在安全窗口出现后完成超车。
func _test_weaving_player_allows_pass(scene: Node) -> bool:
	_clear_driver_test_world(scene)
	var player_y: float = float(scene.get("player_y"))
	scene.call("_spawn_traffic", "SEDAN", 2, player_y + 520.0, 56.0, true, "AGGRESSIVE")
	var cars: Array[Dictionary] = scene.get("traffic")
	var car: Dictionary = cars[0]
	car["x"] = float(scene.call("_lane_x", 2))
	car["previous_x"] = car["x"]
	car["lateral_target_x"] = car["x"]
	car["cruise_offset"] = 0.0
	car["divider_side"] = -1
	car["initial_behind"] = true
	var target_x: float = car["x"]
	var pass_seen: bool = false
	var player_lane_targets: Array[int] = [2, 2, 2, 3, 4, 3, 4, 3, 4, 3]
	for frame in range(720):
		if frame % 72 == 0 and frame / 72 < player_lane_targets.size():
			target_x = float(scene.call("_lane_x", player_lane_targets[frame / 72]))
		var old_player_x: float = float(scene.get("player_x"))
		var next_player_x: float = move_toward(old_player_x, target_x, 430.0 * FRAME_DELTA)
		scene.set("previous_player_x", old_player_x)
		scene.set("player_x", next_player_x)
		scene.set("player_lane", int(scene.call("_nearest_lane", next_player_x)))
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_resolve_npc_collisions", FRAME_DELTA)
		scene.call("_resolve_player_collisions")
		pass_seen = pass_seen or bool(car.get("passed", false))
	return pass_seen and not bool(car.get("crashed", false)) and int(scene.get("durability")) >= 9


## 验证轿车和大巴在五道道路的两侧运动时仍被车身边界限制。
func _test_vehicle_width_bounds(scene: Node) -> bool:
	var road_left: float = float(scene.get("road_left"))
	var road_width: float = float(scene.get("road_width"))
	for kind in ["SEDAN", "BUS"]:
		_clear_driver_test_world(scene)
		for lane in [0, 4]:
			scene.call("_spawn_traffic", kind, lane, float(scene.get("player_y")) + 500.0, 40.0, false, "NORMAL")
		var cars: Array[Dictionary] = scene.get("traffic")
		for car in cars:
			var body_width: float = float((scene.call("_car_dimensions", kind) as Vector2).x)
			car["x"] = road_left - 200.0 if int(car["lane"]) == 0 else road_left + road_width + 200.0
			car["lateral_target_x"] = car["x"]
			scene.call("_apply_lateral_motion", car, FRAME_DELTA)
			if float(car["x"]) < road_left + body_width * 0.5 - 0.1 or float(car["x"]) > road_left + road_width - body_width * 0.5 + 0.1:
				return false
	return true


## 验证玩家主动横向切入并排行驶车辆时仍保留侧向碰撞反馈。
func _test_player_side_collision(scene: Node) -> bool:
	_clear_driver_test_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var previous_x: float = float(scene.call("_lane_x", 1))
	var current_x: float = float(scene.call("_lane_x", 2))
	scene.set("previous_player_x", previous_x)
	scene.set("player_x", current_x)
	scene.set("player_lane", 2)
	scene.call("_spawn_traffic", "SEDAN", 2, player_y, 40.0, false, "NORMAL")
	var cars: Array[Dictionary] = scene.get("traffic")
	var car: Dictionary = cars[0]
	car["x"] = current_x
	car["y"] = player_y
	car["lateral_target_x"] = current_x
	scene.call("_resolve_player_collisions")
	return bool(car["crashed"]) and int(scene.get("durability")) == 8


## 在五道实体障碍前运行固定帧数，返回车辆最终速度。
func _measure_blocked_speed(scene: Node, driver_type: String) -> float:
	var car: Dictionary = _setup_single_car(scene, driver_type, 220.0)
	var blocker_y: float = float(car["y"]) - 220.0
	var blockers: Array[Dictionary] = []
	for lane in range(5):
		blockers.append({
			"type": "SOFA",
			"x": float(scene.call("_lane_x", lane)),
			"y": blocker_y,
			"life": 10.0,
			"active": true,
			"blocks_route": true,
			"collision": false,
			"width": float(scene.get("lane_width")) * 0.9,
			"height": 64.0,
		})
	scene.set("hazards", blockers)
	for _frame in range(60):
		scene.call("_update_traffic", FRAME_DELTA)
	return float((scene.get("traffic") as Array)[0].get("speed", 40.0))


## 运行车辆进入换道与超车阶段，返回期间记录到的最高速度。
func _measure_overtake_peak_speed(scene: Node, driver_type: String) -> float:
	var car: Dictionary = _setup_single_car(scene, driver_type, 120.0)
	var peak_speed: float = float(car["speed"])
	for _frame in range(36):
		scene.call("_update_traffic", FRAME_DELTA)
		var cars: Array = scene.get("traffic")
		if cars.is_empty():
			break
		peak_speed = maxf(peak_speed, float(cars[0].get("speed", 0.0)))
	return peak_speed
