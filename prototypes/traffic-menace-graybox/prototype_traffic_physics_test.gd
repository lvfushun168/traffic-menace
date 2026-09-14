extends SceneTree

const FRAME_DELTA: float = 1.0 / 60.0


func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	var lane_count: int = (scene.get("lane_centers") as Array).size()
	var lane_width: float = float(scene.get("lane_width"))
	var road_width: float = float(scene.get("road_width"))
	var player_body_width: float = (scene.call("_player_body_size") as Vector2).x
	var player_lane: int = int(scene.get("player_lane"))
	var layout_ok: bool = lane_count == 5 and absf(road_width - 510.0) < 1.0 and absf(lane_width - 102.0) < 1.0 and absf(player_body_width - 68.0) < 1.0 and absf(lane_width / player_body_width - 1.5) < 0.01 and player_lane == 2
	var stable_traffic_ok: bool = _test_stable_traffic(scene)
	var follow_ok: bool = _test_predictive_following(scene)
	var braking_ok: bool = _test_braking_rate(scene)
	var shock_ok: bool = _test_speed_shock(scene)
	var chain_ok: bool = _test_player_item_chain(scene)
	var contact_ok: bool = _test_contact_threshold(scene)
	var lane_safety_ok: bool = _test_lane_change_safety(scene)
	var vehicle_bounds_ok: bool = _test_vehicle_bounds(scene)
	var blocked_edge_overtake_ok: bool = _test_blocked_edge_lane_overtake(scene)
	var player_lane_wait_ok: bool = _test_player_lane_wait_and_replan(scene)
	var reservation_ok: bool = _test_lane_reservation(scene)
	var route_sweep_ok: bool = _test_obstacle_route_sweep(scene)
	var spawn_safety_ok: bool = _test_spawn_safety(scene)
	var opening_stability_ok: bool = _test_opening_stability(scene)
	var opening_ramp_ok: bool = _test_opening_ramp(scene)
	var traffic_lod_ok: bool = _test_traffic_lod(scene)

	print("GRAYBOX_TRAFFIC_PHYSICS_TEST lanes=%s layout=%s stable_traffic=%s following=%s braking=%s shock=%s item_chain=%s contact_threshold=%s lane_safety=%s vehicle_bounds=%s blocked_edge_overtake=%s player_lane_wait=%s reservation=%s route_sweep=%s spawn_safety=%s opening_stability=%s opening_ramp=%s traffic_lod=%s full_updates=%s lod_updates=%s" % [lane_count, layout_ok, stable_traffic_ok, follow_ok, braking_ok, shock_ok, chain_ok, contact_ok, lane_safety_ok, vehicle_bounds_ok, blocked_edge_overtake_ok, player_lane_wait_ok, reservation_ok, route_sweep_ok, spawn_safety_ok, opening_stability_ok, opening_ramp_ok, traffic_lod_ok, scene.get("traffic_ai_full_updates"), scene.get("traffic_ai_lod_updates")])
	quit(0 if layout_ok and stable_traffic_ok and follow_ok and braking_ok and shock_ok and chain_ok and contact_ok and lane_safety_ok and vehicle_bounds_ok and blocked_edge_overtake_ok and player_lane_wait_ok and reservation_ok and route_sweep_ok and spawn_safety_ok and opening_stability_ok and opening_ramp_ok and traffic_lod_ok else 1)


## 清空交通和道路状态，恢复无输入、无道具的中间车道玩家。
func _clear_world(scene: Node) -> void:
	var cleared_traffic: Array = scene.get("traffic")
	cleared_traffic.clear()
	scene.set("traffic", cleared_traffic)
	scene.set("hazards", [])
	scene.set("road_events", [])
	scene.set("loose_props", [])
	scene.set("active_effects", {})
	var empty_items: Array[String] = ["", "", ""]
	scene.set("item_slots", empty_items)
	scene.set("run_time", 0.0)
	scene.set("player_speed", 40.0)
	scene.set("player_x", float(scene.call("_lane_x", 2)))
	scene.set("previous_player_x", float(scene.call("_lane_x", 2)))
	scene.set("player_lane", 2)
	scene.set("player_collision_cooldown", 0.0)
	scene.set("durability", 10)


## 放置一辆字段完整、位置和速度可重复的测试车辆。
func _place_car(scene: Node, kind: String, lane: int, y: float, speed: float, driver_type: String = "NORMAL") -> Dictionary:
	scene.call("_spawn_traffic", kind, lane, y, speed, driver_type == "AGGRESSIVE", driver_type)
	var cars: Array[Dictionary] = scene.get("traffic")
	var car: Dictionary = cars[cars.size() - 1]
	var center_x: float = float(scene.call("_lane_x", lane))
	car["x"] = center_x
	car["previous_x"] = center_x
	car["lateral_target_x"] = center_x
	car["cruise_offset"] = 0.0
	car["y"] = y
	car["previous_y"] = y
	car["speed"] = speed
	car["previous_speed"] = speed
	car["base_speed"] = speed
	car["speed_command"] = speed
	car["initial_behind"] = false
	car["attempted_pass"] = false
	car["passed"] = false
	car["state"] = "CRUISE"
	car["previous_lane"] = -1
	car["overtake_hops"] = 0
	car["route_plan"] = []
	car["route_index"] = 0
	car["maneuver_reason"] = ""
	car["replan_cooldown"] = 0.0
	car["lane_change_commit_timer"] = 0.0
	car["lane_reservation"] = -1
	car["lane_reservation_timer"] = 0.0
	car["speed_shock_target"] = -1.0
	car["speed_shock_timer"] = 0.0
	car["speed_shock_memory_timer"] = 0.0
	car["speed_shock_source"] = ""
	car["speed_shock_latched"] = false
	car["brake_reason"] = ""
	car["follow_front_id"] = -1
	car["follow_front_speed_seen"] = speed
	car["follow_reaction_timer"] = 0.0
	car["contact_cooldown"] = 0.0
	car["crash_cause"] = ""
	car["crash_block_timer"] = 0.0
	cars[cars.size() - 1] = car
	scene.set("traffic", cars)
	return car


## 验证无玩家输入、无道具时，五道车流运行十秒不会自行互撞。
func _test_stable_traffic(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	for lane in range(5):
		for row in range(6):
			_place_car(scene, "SEDAN", lane, player_y + 320.0 + float(row) * 260.0, 40.0)
	for _frame in range(600):
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_resolve_npc_collisions", FRAME_DELTA)
		scene.call("_resolve_player_collisions")
	var crash_count: int = 0
	for car in scene.get("traffic") as Array:
		if bool(car.get("crashed", false)):
			crash_count += 1
	return crash_count == 0 and int(scene.get("durability")) == 10


## 验证速度更快的后车会提前按真实净距跟随，而不是等到重叠后追尾。
func _test_predictive_following(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var front: Dictionary = _place_car(scene, "SEDAN", 2, player_y + 300.0, 40.0)
	var rear: Dictionary = _place_car(scene, "SEDAN", 2, player_y + 520.0, 60.0)
	_place_car(scene, "SEDAN", 1, float(rear["y"]), 40.0)
	_place_car(scene, "SEDAN", 3, float(rear["y"]), 40.0)
	for _frame in range(180):
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_resolve_npc_collisions", FRAME_DELTA)
	var body_sum: float = float((scene.call("_car_dimensions", "SEDAN") as Vector2).y) * 2.0
	var clear_y: float = float(rear["y"]) - float(front["y"]) - body_sum * 0.5
	return not bool(front.get("crashed", false)) and not bool(rear.get("crashed", false)) and float(rear["speed"]) <= 42.0 and clear_y >= 5.5


## 验证 NPC 从六十公里每小时刹停时，固定刹车率为每秒二十公里。
func _test_braking_rate(scene: Node) -> bool:
	_clear_world(scene)
	var car: Dictionary = _place_car(scene, "SEDAN", 0, float(scene.get("player_y")) + 900.0, 60.0)
	for _frame in range(180):
		scene.call("_advance_traffic_position", car, 0.0, FRAME_DELTA, 30.0)
	return absf(float(car["speed"])) < 0.1


## 验证道具突减会立即改目标速度，但实际车速仍按固定物理率下降。
func _test_speed_shock(scene: Node) -> bool:
	_clear_world(scene)
	var car: Dictionary = _place_car(scene, "SEDAN", 0, float(scene.get("player_y")) + 900.0, 60.0)
	scene.call("_trigger_npc_speed_shock", car, "PLAYER_ITEM")
	var command_ok: bool = absf(float(car["speed_command"]) - 10.0) < 0.1 and str(car["speed_shock_source"]) == "PLAYER_ITEM"
	for _frame in range(60):
		scene.call("_advance_traffic_position", car, 60.0, FRAME_DELTA, 30.0)
	var physical_rate_ok: bool = absf(float(car["speed"]) - 40.0) < 0.5
	return command_ok and physical_rate_ok


## 验证玩家误导类道具能让前车突减，并在刹车距离不足时产生可归因连锁。
func _test_player_item_chain(scene: Node) -> bool:
	_clear_world(scene)
	var fake_items: Array[String] = ["FAKE BRAKE LIGHT", "", ""]
	scene.set("item_slots", fake_items)
	var player_y: float = float(scene.get("player_y"))
	var lead: Dictionary = _place_car(scene, "SEDAN", 2, player_y + 300.0, 60.0)
	var follower: Dictionary = _place_car(scene, "SEDAN", 2, player_y + 422.0, 90.0)
	_place_car(scene, "SEDAN", 1, float(follower["y"]), 40.0)
	_place_car(scene, "SEDAN", 3, float(follower["y"]), 40.0)
	var shock_seen: bool = false
	for _frame in range(60):
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_resolve_npc_collisions", FRAME_DELTA)
		shock_seen = shock_seen or absf(float(lead.get("speed_command", 60.0)) - 10.0) < 0.1
		if bool(follower.get("crashed", false)):
			break
	return shock_seen and bool(follower.get("crashed", false)) and str(follower.get("crash_cause", "")) == "PLAYER_ITEM_CHAIN"


## 验证低速接触无伤分离，高速接触才会进入交通事故状态。
func _test_contact_threshold(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var slow_front: Dictionary = _place_car(scene, "SEDAN", 0, player_y + 300.0, 40.0)
	var slow_rear: Dictionary = _place_car(scene, "SEDAN", 0, player_y + 380.0, 40.0)
	scene.call("_resolve_npc_collisions", FRAME_DELTA)
	var slow_clear: float = float(slow_rear["y"]) - float(slow_front["y"]) - 112.0
	var low_speed_ok: bool = not bool(slow_front.get("crashed", false)) and not bool(slow_rear.get("crashed", false)) and slow_clear >= 5.9

	_clear_world(scene)
	var fast_front: Dictionary = _place_car(scene, "SEDAN", 0, player_y + 300.0, 0.0)
	var fast_rear: Dictionary = _place_car(scene, "SEDAN", 0, player_y + 380.0, 60.0)
	scene.call("_resolve_npc_collisions", FRAME_DELTA)
	var high_speed_ok: bool = bool(fast_front.get("crashed", false)) and bool(fast_rear.get("crashed", false)) and str(fast_front.get("crash_cause", "")) == "TRAFFIC_IMPACT"
	return low_speed_ok and high_speed_ok


## 验证实际车身会避开已占用的相邻车道，并优先选择空的另一侧。
func _test_lane_change_safety(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var aggressive: Dictionary = _place_car(scene, "SEDAN", 2, player_y + 420.0, 50.0, "AGGRESSIVE")
	aggressive["divider_side"] = -1
	_place_car(scene, "BUS", 1, float(aggressive["y"]), 40.0)
	var selected_lane: int = int(scene.call("_choose_overtake_lane", aggressive))
	return selected_lane == 3


## 验证轿车、大巴和卡车的实际车身在道路两侧横向移动时不会越界。
func _test_vehicle_bounds(scene: Node) -> bool:
	var road_left: float = float(scene.get("road_left"))
	var road_width: float = float(scene.get("road_width"))
	for kind in ["SEDAN", "BUS", "TRUCK"]:
		_clear_world(scene)
		var left_car: Dictionary = _place_car(scene, kind, 0, float(scene.get("player_y")) + 500.0, 40.0)
		var right_car: Dictionary = _place_car(scene, kind, 4, float(scene.get("player_y")) + 700.0, 40.0)
		var cars: Array[Dictionary] = [left_car, right_car]
		for car in cars:
			var body_width: float = (scene.call("_car_dimensions", kind) as Vector2).x
			car["x"] = road_left - 200.0 if int(car["lane"]) == 0 else road_left + road_width + 200.0
			car["lateral_target_x"] = car["x"]
			scene.call("_apply_lateral_motion", car, FRAME_DELTA)
			if float(car["x"]) < road_left + body_width * 0.5 - 0.1 or float(car["x"]) > road_left + road_width - body_width * 0.5 + 0.1:
				return false
	return true


## 验证第五道被障碍封住时，后车会先向第四道再向第三道逐道找缝。
func _test_blocked_edge_lane_overtake(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var player_lane: int = 3
	var blocked_lane: int = 4
	var player_center_x: float = float(scene.call("_lane_x", player_lane))
	scene.set("player_x", player_center_x)
	scene.set("previous_player_x", player_center_x)
	scene.set("player_lane", player_lane)
	var npc: Dictionary = _place_car(scene, "SEDAN", blocked_lane, player_y + 520.0, 50.0, "AGGRESSIVE")
	npc["initial_behind"] = true
	npc["attempted_pass"] = false
	npc["passed"] = false
	var blocked_hazard: Dictionary = {
		"type": "SOFA",
		"x": float(scene.call("_lane_x", blocked_lane)),
		"y": player_y + 420.0,
		"life": 10.0,
		"active": true,
		"blocks_route": true,
		"collision": false,
		"width": float(scene.get("lane_width")) * 0.9,
		"height": 64.0,
	}
	var blocked_hazards: Array[Dictionary] = [blocked_hazard]
	scene.set("hazards", blocked_hazards)
	var planned_route: Array = scene.call("_plan_overtake_route", npc)
	var route_plan_ok: bool = planned_route.size() >= 2 and int(planned_route[0]) == player_lane and int(planned_route[1]) == 2
	var first_hop_seen: bool = false
	var second_hop_seen: bool = false
	var last_lane: int = int(npc.get("lane", blocked_lane))
	var lane_hop_ok: bool = true
	for _frame in range(180):
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_resolve_npc_collisions", FRAME_DELTA)
		var current_lane: int = int(npc.get("lane", blocked_lane))
		lane_hop_ok = lane_hop_ok and abs(current_lane - last_lane) <= 1
		last_lane = current_lane
		first_hop_seen = first_hop_seen or int(npc.get("target_lane", blocked_lane)) == player_lane
		second_hop_seen = second_hop_seen or int(npc.get("target_lane", blocked_lane)) == 2 or current_lane == 2
	return route_plan_ok and first_hop_seen and second_hop_seen and lane_hop_ok and not bool(npc.get("crashed", false)) and int(scene.get("durability")) == 10


## 验证玩家近距离占用下一道时，NPC 会先安全等待；玩家移开后能重新规划下一跳。
func _test_player_lane_wait_and_replan(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var player_lane: int = 3
	var player_x_on_lane: float = float(scene.call("_lane_x", player_lane))
	scene.set("player_x", player_x_on_lane)
	scene.set("previous_player_x", player_x_on_lane)
	scene.set("player_lane", player_lane)
	var npc: Dictionary = _place_car(scene, "SEDAN", 4, player_y + 110.0, 50.0, "AGGRESSIVE")
	npc["initial_behind"] = true
	var blocked_hazard: Dictionary = {
		"type": "SOFA",
		"x": float(scene.call("_lane_x", 4)),
		"y": player_y + 40.0,
		"life": 10.0,
		"active": true,
		"blocks_route": true,
		"collision": false,
		"width": float(scene.get("lane_width")) * 0.9,
		"height": 64.0,
	}
	var blocked_hazards: Array[Dictionary] = [blocked_hazard]
	scene.set("hazards", blocked_hazards)
	for _frame in range(18):
		scene.call("_update_traffic", FRAME_DELTA)
	var waiting_state: bool = str(npc.get("state", "")) in ["BLOCKED", "BRAKE", "WAIT"] and float(npc.get("speed", 50.0)) < 50.0
	var moved_player_x: float = float(scene.call("_lane_x", 2))
	blocked_hazard["active"] = false
	scene.set("player_x", moved_player_x)
	scene.set("previous_player_x", moved_player_x)
	scene.set("player_lane", 2)
	var reroute_seen: bool = false
	for _frame in range(36):
		scene.call("_update_traffic", FRAME_DELTA)
		reroute_seen = reroute_seen or int(npc.get("lane", 4)) == player_lane or int(npc.get("target_lane", 4)) == player_lane or player_lane in (npc.get("route_plan", []) as Array)
	return waiting_state and reroute_seen and not bool(npc.get("crashed", false)) and int(scene.get("durability")) == 10


## 验证两辆车同时争抢同一条横向路线时只有优先车辆能预约空隙。
func _test_lane_reservation(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var first: Dictionary = _place_car(scene, "SEDAN", 4, player_y + 500.0, 54.0, "AGGRESSIVE")
	var second: Dictionary = _place_car(scene, "BUS", 2, player_y + 500.0, 54.0, "AGGRESSIVE")
	first["state"] = "LANE CHANGE"
	first["target_lane"] = 3
	first["lateral_target_x"] = float(scene.call("_lane_x", 3))
	second["state"] = "CRUISE"
	second["target_lane"] = 2
	second["lateral_target_x"] = float(scene.call("_lane_x", 2))
	var target_x: float = float(scene.call("_lane_x", 3))
	var first_claimed: bool = bool(scene.call("_claim_lateral_reservation", first, 3, target_x))
	var second_claimed: bool = bool(scene.call("_claim_lateral_reservation", second, 3, target_x))
	return first_claimed and not second_claimed and int(first.get("lane_reservation", -1)) == 3 and int(second.get("lane_reservation", -1)) != 3 and not bool(first.get("crashed", false)) and not bool(second.get("crashed", false))


## 验证最终车道虽然空闲，但横向扫掠路径经过障碍时必须拒绝该路线。
func _test_obstacle_route_sweep(scene: Node) -> bool:
	_clear_world(scene)
	var player_y: float = float(scene.get("player_y"))
	var car: Dictionary = _place_car(scene, "SEDAN", 2, player_y + 520.0, 40.0)
	var target_x: float = float(scene.call("_lane_x", 3))
	var sweep_hazard: Dictionary = {
		"type": "SOFA",
		"x": float(scene.get("road_left")) + float(scene.get("lane_width")) * 2.45,
		"y": player_y + 490.0,
		"life": 10.0,
		"active": true,
		"blocks_route": true,
		"collision": false,
		"width": 32.0,
		"height": 48.0,
	}
	var sweep_hazards: Array[Dictionary] = [sweep_hazard]
	scene.set("hazards", sweep_hazards)
	var path_rejected: bool = not bool(scene.call("_overtake_route_is_clear", car, 3, target_x, 220.0))
	sweep_hazard["active"] = false
	var path_released: bool = bool(scene.call("_overtake_route_is_clear", car, 3, target_x, 220.0))
	return path_rejected and path_released


## 验证刷新遇到占用车道时会改选空道或延迟，而不会把新车硬插入车流。
func _test_spawn_safety(scene: Node) -> bool:
	_clear_world(scene)
	var current_screen_size: Vector2 = scene.get("screen_size")
	var spawn_y: float = current_screen_size.y + 180.0
	var blocker: Dictionary = _place_car(scene, "BUS", 2, spawn_y, 40.0)
	var before_fallback_count: int = (scene.get("traffic") as Array).size()
	var fallback_spawned: bool = bool(scene.call("_spawn_traffic_if_safe", "SEDAN", 2, spawn_y, 40.0, false, "NORMAL"))
	var fallback_traffic: Array = scene.get("traffic")
	var fallback_car: Dictionary = fallback_traffic[fallback_traffic.size() - 1] if fallback_traffic.size() > before_fallback_count else {}
	var fallback_lane_ok: bool = fallback_spawned and not fallback_car.is_empty() and int(fallback_car.get("lane", 2)) != 2
	var blocker_center: Vector2 = Vector2(float(blocker.get("x", 0.0)), float(blocker.get("y", 0.0)))
	var fallback_center: Vector2 = Vector2(float(fallback_car.get("x", 0.0)), float(fallback_car.get("y", 0.0)))
	var blocker_size: Vector2 = scene.call("_car_dimensions", str(blocker.get("kind", "BUS")))
	var fallback_size: Vector2 = scene.call("_car_dimensions", str(fallback_car.get("kind", "SEDAN")))
	var fallback_overlap_ok: bool = fallback_lane_ok and not bool(scene.call("_rects_overlap", blocker_center, blocker_size, fallback_center, fallback_size))

	var blocked_traffic: Array = scene.get("traffic")
	blocked_traffic.clear()
	scene.set("traffic", blocked_traffic)
	for lane in range(5):
		_place_car(scene, "SEDAN", lane, spawn_y, 40.0)
	var before_delayed_count: int = (scene.get("traffic") as Array).size()
	var delayed: bool = not bool(scene.call("_spawn_traffic_if_safe", "SEDAN", 2, spawn_y, 40.0, false, "NORMAL"))
	var delayed_count_ok: bool = (scene.get("traffic") as Array).size() == before_delayed_count
	return fallback_overlap_ok and delayed and delayed_count_ok


## 验证固定开局的混合车型经过十秒无输入运行仍保持稳定且不自发互撞。
func _test_opening_stability(scene: Node) -> bool:
	scene.call("reset_run")
	scene.set("durability", 999)
	var initial_traffic: Array = scene.get("traffic")
	var initial_spacing_ok: bool = initial_traffic.size() == 6
	var opening_distance_ok: bool = true
	var opening_grace_ok: bool = true
	var player_y: float = float(scene.get("player_y"))
	for car in initial_traffic:
		opening_distance_ok = opening_distance_ok and float(car.get("y", player_y)) - player_y >= 259.9
		opening_grace_ok = opening_grace_ok and float(car.get("opening_grace_remaining", 0.0)) >= 4.99
	for first_index in range(initial_traffic.size()):
		var first: Dictionary = initial_traffic[first_index]
		for second_index in range(first_index + 1, initial_traffic.size()):
			var second: Dictionary = initial_traffic[second_index]
			var first_size: Vector2 = scene.call("_car_dimensions", str(first.get("kind", "SEDAN")))
			var second_size: Vector2 = scene.call("_car_dimensions", str(second.get("kind", "SEDAN")))
			var actual_overlap: bool = scene.call("_rects_overlap", Vector2(float(first.get("x", 0.0)), float(first.get("y", 0.0))), first_size, Vector2(float(second.get("x", 0.0)), float(second.get("y", 0.0))), second_size)
			initial_spacing_ok = initial_spacing_ok and not actual_overlap
			if int(first.get("lane", -1)) != int(second.get("lane", -2)):
				continue
			var clearance: float = absf(float(first.get("y", 0.0)) - float(second.get("y", 0.0))) - first_size.y * 0.5 - second_size.y * 0.5
			initial_spacing_ok = initial_spacing_ok and clearance >= 41.9
	for _frame in range(600):
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_resolve_npc_collisions", FRAME_DELTA)
		scene.call("_resolve_player_collisions")
	var crash_count: int = 0
	for car in scene.get("traffic") as Array:
		if bool(car.get("crashed", false)):
			crash_count += 1
	return initial_spacing_ok and opening_distance_ok and opening_grace_ok and crash_count == 0 and int(scene.get("durability")) == 999


## 验证开局车流在 10、30、60 秒和终局时按约定目标平滑增长。
func _test_opening_ramp(scene: Node) -> bool:
	scene.call("reset_run")
	var initial_count_ok: bool = (scene.get("traffic") as Array).size() == 6
	var target_0_ok: bool = int(scene.call("_traffic_target_count", 0.0)) == 6
	var target_10_ok: bool = int(scene.call("_traffic_target_count", 10.0)) == 8
	var target_30_ok: bool = int(scene.call("_traffic_target_count", 30.0)) == 15
	var target_60_ok: bool = int(scene.call("_traffic_target_count", 60.0)) == 30
	var target_end_ok: bool = int(scene.call("_traffic_target_count", 480.0)) == 80
	return initial_count_ok and target_0_ok and target_10_ok and target_30_ok and target_60_ok and target_end_ok


## 验证远端普通巡航车辆会进入降频路径，同时仍保持基本位置更新。
func _test_traffic_lod(scene: Node) -> bool:
	scene.call("reset_run")
	var distant_traffic: Array = scene.get("traffic")
	distant_traffic.clear()
	scene.set("traffic", distant_traffic)
	scene.set("traffic_ai_full_updates", 0)
	scene.set("traffic_ai_lod_updates", 0)
	var current_screen_size: Vector2 = scene.get("screen_size")
	for index in range(40):
		var lane: int = index % 5
		var row: int = index / 5
		scene.call("_spawn_traffic", "SEDAN", lane, current_screen_size.y + 720.0 + float(row) * 220.0, 45.0, false, "NORMAL")
	var first_y: float = float((scene.get("traffic") as Array)[0].get("y", 0.0))
	for _frame in range(60):
		scene.call("_update_traffic", FRAME_DELTA)
	var cars: Array = scene.get("traffic")
	var basic_motion_ok: bool = not cars.is_empty() and absf(float(cars[0].get("y", first_y)) - first_y) > 0.0
	return int(scene.get("traffic_ai_full_updates")) > 0 and int(scene.get("traffic_ai_lod_updates")) > 0 and basic_motion_ok
