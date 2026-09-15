extends SceneTree


func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	# 用超长耐久跑完整的中期节奏，避免测试被“玩家没操作”提前结束。
	scene.set("durability", 999)
	# 新规则下无输入车流不应靠 NPC-NPC 追尾制造事故；这里单独注入一次环境轮胎，验证事故后的补车链路。
	var seeded_car: Dictionary = (scene.get("traffic") as Array)[0]
	var seeded_hazard: Dictionary = {
		"type": "TIRE",
		"x": float(seeded_car.get("x", scene.call("_lane_x", 0))),
		"y": float(seeded_car.get("y", scene.get("player_y"))),
		"life": 2.0,
		"active": true,
		"blocks_route": true,
		"collision": true,
		"width": 54.0,
		"height": 54.0,
		"x_velocity": 0.0,
	}
	var seeded_hazards: Array[Dictionary] = [seeded_hazard]
	scene.set("hazards", seeded_hazards)
	scene.call("_resolve_hazard_collisions")
	seeded_hazard["active"] = false
	var initial_traffic_count: int = (scene.get("traffic") as Array).size()
	var max_traffic_count: int = initial_traffic_count
	var max_trapped: int = 0
	var blocked_seen: bool = false
	var crashed_seen: bool = false
	var merge_car_seen: bool = false
	var merge_after_crash_seen: bool = false
	for _frame in range(3600):
		scene.call("_physics_process", 1.0 / 60.0)
		if bool(scene.get("item_replacement_active")):
			Input.action_press("choose_1")
			scene.call("_physics_process", 1.0 / 60.0)
			Input.action_release("choose_1")
		elif bool(scene.get("upgrade_active")):
			Input.action_press("choose_1")
			scene.call("_physics_process", 1.0 / 60.0)
			Input.action_release("choose_1")
		max_traffic_count = maxi(max_traffic_count, (scene.get("traffic") as Array).size())
		max_trapped = maxi(max_trapped, int(scene.get("vehicles_trapped")))
		for car in scene.get("traffic") as Array:
			if bool(car.get("crashed", false)):
				crashed_seen = true
			if str(car.get("spawn_origin", "")) == "MERGE":
				merge_car_seen = true
				if crashed_seen:
					merge_after_crash_seen = true
			if str(car.get("state", "")) == "BLOCKED":
				blocked_seen = true

	var road_event_count: int = int(scene.get("road_event_count"))
	var car_count: int = scene.get("traffic").size()
	var score: int = int(scene.get("score"))
	var merge_spawned_count: int = int(scene.get("merge_spawned_count"))
	var merge_queue_peak: int = int(scene.get("merge_queue_peak"))
	var final_multiplier: float = float(scene.get("chaos_multiplier"))
	var final_upgrade_index: int = int(scene.get("next_upgrade_index"))
	var upgrade_times: Array = (scene.get("upgrade_offer_times") as Array).duplicate()
	var upgrade_cadence_ok: bool = not upgrade_times.is_empty()
	for index in range(upgrade_times.size()):
		var offer_time: float = float(upgrade_times[index])
		if index == 0:
			upgrade_cadence_ok = upgrade_cadence_ok and offer_time >= 10.0
		else:
			upgrade_cadence_ok = upgrade_cadence_ok and offer_time - float(upgrade_times[index - 1]) >= 14.99
	var traffic_target_curve_ok: bool = int(scene.call("_traffic_target_count", 10.0)) == 8 and int(scene.call("_traffic_target_count", 30.0)) == 15 and int(scene.call("_traffic_target_count", 60.0)) == 30 and int(scene.call("_traffic_target_count", 480.0)) == 80
	var traffic_lod_seen: bool = int(scene.get("traffic_ai_lod_updates")) > 0
	var crash_cleanup_ok: bool = true
	for car in scene.get("traffic") as Array:
		crash_cleanup_ok = crash_cleanup_ok and not (bool(car.get("crashed", false)) and float(car.get("crash_time", 0.0)) >= 3.0)
	var upgrade_gate_test_ok: bool = _test_upgrade_cadence(scene)
	print("GRAYBOX_SYSTEM_TEST initial_cars=%s max_cars=%s road_events=%s cars=%s score=%s max_trapped=%s blocked=%s crashed=%s merge_seen=%s merge_after_crash=%s merge_spawned=%s merge_queue_peak=%s multiplier=%s upgrade_index=%s upgrade_times=%s upgrade_cadence=%s target_curve=%s lod_seen=%s crash_cleanup=%s upgrade_gate=%s" % [initial_traffic_count, max_traffic_count, road_event_count, car_count, score, max_trapped, blocked_seen, crashed_seen, merge_car_seen, merge_after_crash_seen, merge_spawned_count, merge_queue_peak, final_multiplier, final_upgrade_index, upgrade_times, upgrade_cadence_ok, traffic_target_curve_ok, traffic_lod_seen, crash_cleanup_ok, upgrade_gate_test_ok])
	quit(0 if initial_traffic_count == 6 and road_event_count > 0 and score > 0 and max_trapped > 0 and blocked_seen and crashed_seen and merge_car_seen and merge_after_crash_seen and merge_spawned_count > 0 and upgrade_cadence_ok and traffic_target_curve_ok and traffic_lod_seen and crash_cleanup_ok and upgrade_gate_test_ok else 1)


## 验证分数提前越过多个阈值时，升级仍按最短游戏时间间隔逐个出现。
func _test_upgrade_cadence(scene: Node) -> bool:
	scene.call("reset_run")
	scene.set("durability", 999)
	scene.set("score", 100000)
	var quiet_traffic: Array[Dictionary] = []
	scene.set("traffic", quiet_traffic)
	scene.set("spawn_clock", 0.0)
	scene.set("road_event_clock", -100.0)
	scene.set("pickup_clock", -100.0)
	scene.set("merge_source_clock", -100.0)
	scene.set("run_time", 9.0)
	scene.call("_check_upgrade_threshold")
	var blocked_before_ten: bool = not bool(scene.get("upgrade_active"))
	scene.set("run_time", 10.0)
	scene.call("_check_upgrade_threshold")
	var first_offer_opened: bool = bool(scene.get("upgrade_active"))
	var first_offer_times: Array = (scene.get("upgrade_offer_times") as Array).duplicate()
	Input.action_press("choose_1")
	scene.call("_physics_process", 1.0 / 60.0)
	Input.action_release("choose_1")
	var selection_closed: bool = not bool(scene.get("upgrade_active")) and int(scene.get("next_upgrade_index")) == 1
	var no_immediate_second_offer: bool = not bool(scene.get("upgrade_active"))
	for _frame in range(960):
		scene.call("_physics_process", 1.0 / 60.0)
		if bool(scene.get("upgrade_active")):
			break
	var second_offer_times: Array = scene.get("upgrade_offer_times")
	var second_offer_opened: bool = bool(scene.get("upgrade_active")) and second_offer_times.size() == 2
	var interval_ok: bool = false
	if first_offer_times.size() == 1 and second_offer_times.size() == 2:
		interval_ok = float(second_offer_times[1]) - float(second_offer_times[0]) >= 14.99
	return blocked_before_ten and first_offer_opened and selection_closed and no_immediate_second_offer and second_offer_opened and interval_ok
