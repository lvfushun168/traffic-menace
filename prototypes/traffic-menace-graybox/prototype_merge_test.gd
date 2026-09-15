extends SceneTree

const FRAME_DELTA: float = 1.0 / 60.0
const MERGE_INTERVAL: float = 1.8


## 清理测试场景中的动态合流道路段，避免上一个场景状态影响下一段断言。
func _clear_merge_junctions(scene: Node) -> void:
	var junctions: Array = scene.get("merge_junctions")
	junctions.clear()
	scene.set("merge_junctions", junctions)


## 按真实运行顺序推进动态道路段和交通，供等待与释放断言共用。
func _step_merge_world(scene: Node, frame_count: int) -> void:
	for _frame in range(frame_count):
		scene.call("_update_merge_junctions", FRAME_DELTA)
		scene.call("_update_traffic", FRAME_DELTA)


func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	# 关掉普通生成与其他道路事件，只观察动态合流道路段。
	var cleared_traffic: Array = scene.get("traffic")
	cleared_traffic.clear()
	scene.set("traffic", cleared_traffic)
	_clear_merge_junctions(scene)
	scene.set("spawn_clock", -100.0)
	scene.set("road_event_clock", -100.0)
	scene.set("pickup_clock", -100.0)
	scene.set("merge_source_clock", 0.0)
	scene.set("merge_queue_count", 0)
	scene.set("merge_spawned_count", 0)
	scene.set("merge_side_toggle", -1)
	scene.set("merge_release_cooldown", 0.0)
	for _frame in range(420):
		scene.call("_update_spawn_logic", FRAME_DELTA)

	var merge_cars: int = 0
	var left_entry_seen: bool = false
	var right_entry_seen: bool = false
	for car in scene.get("traffic") as Array:
		if str(car.get("spawn_origin", "")) != "MERGE":
			continue
		merge_cars += 1
		if int(car.get("merge_side", 0)) < 0:
			left_entry_seen = true
		elif int(car.get("merge_side", 0)) > 0:
			right_entry_seen = true

	_step_merge_world(scene, 900)
	var joined_main_road: bool = false
	for car in scene.get("traffic") as Array:
		if str(car.get("spawn_origin", "")) == "MERGE" and bool(car.get("merge_completed", false)):
			joined_main_road = true
			break

	# 道路段抵达判定线后遇到障碍，车辆和道路段必须一起暂停；清障后继续完成并线。
	var waiting_traffic: Array = scene.get("traffic")
	waiting_traffic.clear()
	scene.set("traffic", waiting_traffic)
	_clear_merge_junctions(scene)
	scene.set("hazards", [])
	scene.set("road_events", [])
	scene.set("loose_props", [])
	scene.set("merge_queue_count", 1)
	scene.set("merge_spawned_count", 0)
	scene.set("merge_source_clock", 0.0)
	scene.set("merge_release_cooldown", 0.0)
	scene.set("merge_side_toggle", -1)
	scene.call("_update_merge_source", 0.0, 0.0, 30)
	var waiting_spawned: bool = not (scene.get("traffic") as Array).is_empty() and not (scene.get("merge_junctions") as Array).is_empty()
	var waiting_car: Dictionary = (scene.get("traffic") as Array)[0] if waiting_spawned else {}
	var waiting_junction: Dictionary = (scene.get("merge_junctions") as Array)[0] if waiting_spawned else {}
	var waiting_gate_y: float = float(scene.call("_merge_gate_y"))
	var waiting_blockers: Array[Dictionary] = []
	waiting_blockers.append({
		"type": "SOFA",
		"x": float(scene.call("_lane_x", 0)),
		"y": waiting_gate_y,
		"life": 10.0,
		"active": true,
		"blocks_route": true,
		"collision": false,
		"width": float(scene.get("lane_width")) * 0.9,
		"height": 64.0,
	})
	scene.set("hazards", waiting_blockers)
	var wait_reached: bool = false
	var wait_sync_ok: bool = true
	for _frame in range(900):
		scene.call("_update_merge_junctions", FRAME_DELTA)
		scene.call("_update_traffic", FRAME_DELTA)
		if waiting_spawned:
			var current_junctions: Array = scene.get("merge_junctions")
			if current_junctions.is_empty():
				break
			waiting_junction = current_junctions[0]
			var current_phase: String = str(waiting_car.get("merge_phase", ""))
			if current_phase == "WAIT":
				wait_reached = true
				wait_sync_ok = absf(float(waiting_car.get("y", 0.0)) - float(waiting_junction.get("y", 0.0)) - 84.0) < 1.0 and not bool(waiting_junction.get("moving", true))
				break
	var cleared_wait_hazards: Array = scene.get("hazards")
	cleared_wait_hazards.clear()
	scene.set("hazards", cleared_wait_hazards)
	var released_waiting: bool = false
	for _frame in range(240):
		scene.call("_update_merge_junctions", FRAME_DELTA)
		scene.call("_update_traffic", FRAME_DELTA)
		if waiting_spawned and bool(waiting_car.get("merge_completed", false)):
			released_waiting = true
			break
	var dynamic_wait_ok: bool = waiting_spawned and wait_reached and wait_sync_ok and released_waiting

	# 五条车道全部不可通行时，入口车辆应进入等待队列而不是消失。
	waiting_traffic = scene.get("traffic")
	waiting_traffic.clear()
	scene.set("traffic", waiting_traffic)
	_clear_merge_junctions(scene)
	scene.set("merge_spawned_count", 0)
	scene.set("merge_queue_count", 0)
	scene.set("merge_source_clock", MERGE_INTERVAL)
	var gate_y: float = float(scene.call("_merge_gate_y"))
	var blocked_hazards: Array[Dictionary] = []
	for lane in range(5):
		blocked_hazards.append({
			"type": "SOFA",
			"x": float(scene.call("_lane_x", lane)),
			"y": gate_y,
			"life": 10.0,
			"active": true,
			"blocks_route": true,
			"collision": false,
			"width": float(scene.get("lane_width")) * 0.9,
			"height": 64.0,
		})
	scene.set("hazards", blocked_hazards)
	scene.call("_update_spawn_logic", 0.0)
	var queue_wait_ok: bool = int(scene.get("merge_queue_count")) == 1 and int(scene.get("merge_spawned_count")) == 0 and (scene.get("traffic") as Array).is_empty()

	# 清除障碍后，下一次刷新应释放排队车辆。
	var clear_blockers: Array = scene.get("hazards")
	clear_blockers.clear()
	scene.set("hazards", clear_blockers)
	scene.set("merge_source_clock", MERGE_INTERVAL)
	scene.set("merge_release_cooldown", 0.0)
	scene.call("_update_spawn_logic", 0.0)
	var released_after_wait_ok: bool = int(scene.get("merge_spawned_count")) == 1 and int(scene.get("merge_queue_count")) == 1

	# 高速后车距合流口过近时，合流必须等待，不能只看当前位置是否重叠。
	var high_speed_traffic: Array = scene.get("traffic")
	high_speed_traffic.clear()
	scene.set("traffic", high_speed_traffic)
	_clear_merge_junctions(scene)
	scene.call("_spawn_traffic", "SEDAN", 2, gate_y + 100.0, 90.0, false, "NORMAL")
	var high_speed_rear_blocks_merge: bool = not bool(scene.call("_merge_lane_gap_clear", 2, gate_y, "SEDAN", -1, float(scene.call("_lane_x", 2)), [], 40.0))

	# 填满包含合流缓冲后的有效上限时只排队；撞毁/离场释放容量后，队列继续进入。
	var template_car: Dictionary = {
		"id": -1,
		"kind": "SEDAN",
		"lane": 2,
		"target_lane": 2,
		"previous_lane": -1,
		"overtake_hops": 0,
		"route_plan": [],
		"route_index": 0,
		"maneuver_reason": "",
		"replan_cooldown": 0.0,
		"lane_change_commit_timer": 0.0,
		"lane_reservation": -1,
		"lane_reservation_timer": 0.0,
		"x": float(scene.call("_lane_x", 2)),
		"previous_x": float(scene.call("_lane_x", 2)),
		"lateral_target_x": float(scene.call("_lane_x", 2)),
		"divider_side": 0,
		"cruise_offset": 0.0,
		"wander_phase": 0.0,
		"y": gate_y,
		"previous_y": gate_y,
		"speed": 40.0,
		"previous_speed": 40.0,
		"base_speed": 40.0,
		"speed_command": 40.0,
		"brake_reason": "",
		"speed_shock_target": -1.0,
		"speed_shock_timer": 0.0,
		"speed_shock_memory_timer": 0.0,
		"speed_shock_source": "",
		"speed_shock_latched": false,
		"follow_front_id": -1,
		"follow_front_speed_seen": 40.0,
		"follow_reaction_timer": 0.0,
		"aggressive": false,
		"driver_type": "NORMAL",
		"spawn_origin": "MAIN",
		"merge_side": 0,
		"merge_target_lane": 2,
		"merge_entry_x": float(scene.call("_lane_x", 2)),
		"merge_gate_y": gate_y,
		"initial_behind": false,
		"attempted_pass": false,
		"passed": false,
		"pass_burst_timer": 0.0,
		"player_avoid_timer": 0.0,
		"contact_cooldown": 0.0,
		"pass_logged": false,
		"block_reported": false,
		"block_timer": 0.0,
		"wait_timer": 0.0,
		"trapped": false,
		"state": "CRUISE",
		"indicator": 0,
		"indicator_clock": 0.0,
		"pressure": 0.0,
		"attributed": false,
		"crashed": false,
		"crash_cause": "",
		"crash_time": 0.0,
		"crash_block_timer": 0.0,
		"spin_angle": 0.0,
		"spin_speed": 0.0,
		"x_velocity": 0.0,
		"slip": 0.0,
		"hazard_cooldown": 0.0,
		"police_reacted": false,
		"merge_exit_timer": 0.0,
		"merge_exit_speed": 40.0,
		"merge_exit_cruise_offset": 0.0,
		"merge_exit_offset_pending": false,
		"merge_exit_clear_y": gate_y,
		"merge_flow_floor": 0.0,
		"color": Color("#60a5fa"),
	}
	var full_traffic: Array[Dictionary] = []
	for _index in range(35):
		full_traffic.append(template_car.duplicate(true))
	scene.set("traffic", full_traffic)
	scene.set("merge_queue_count", 0)
	scene.set("merge_source_clock", MERGE_INTERVAL)
	scene.set("merge_spawned_count", 0)
	scene.set("merge_release_cooldown", 0.0)
	scene.call("_update_spawn_logic", 0.0)
	var full_queue_ok: bool = int(scene.get("merge_queue_count")) == 1 and int(scene.get("merge_spawned_count")) == 0
	var released_traffic: Array = scene.get("traffic")
	released_traffic.clear()
	scene.set("traffic", released_traffic)
	_clear_merge_junctions(scene)
	scene.set("merge_source_clock", MERGE_INTERVAL)
	scene.set("merge_release_cooldown", 0.0)
	scene.call("_update_spawn_logic", 0.0)
	var released_from_full_ok: bool = int(scene.get("merge_spawned_count")) == 1 and int(scene.get("merge_queue_count")) == 1

	print("GRAYBOX_MERGE_TEST cars=%s left=%s right=%s joined=%s dynamic_wait=%s wait=%s release=%s fast_rear=%s full_queue=%s full_release=%s peak=%s" % [merge_cars, left_entry_seen, right_entry_seen, joined_main_road, dynamic_wait_ok, queue_wait_ok, released_after_wait_ok, high_speed_rear_blocks_merge, full_queue_ok, released_from_full_ok, scene.get("merge_queue_peak")])
	quit(0 if merge_cars > 0 and left_entry_seen and right_entry_seen and joined_main_road and dynamic_wait_ok and queue_wait_ok and released_after_wait_ok and high_speed_rear_blocks_merge and full_queue_ok and released_from_full_ok else 1)
