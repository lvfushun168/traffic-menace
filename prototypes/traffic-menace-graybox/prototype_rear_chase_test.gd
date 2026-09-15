extends SceneTree

const FRAME_DELTA: float = 1.0 / 60.0


## 启动后方追赶专项烟测，验证低密度刷新、追上玩家、择机超车和离场清理。
func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	var cleared_traffic: Array = scene.get("traffic")
	cleared_traffic.clear()
	scene.set("traffic", cleared_traffic)
	scene.set("hazards", [])
	scene.set("road_events", [])
	scene.set("loose_props", [])
	scene.set("merge_junctions", [])
	scene.set("run_time", 12.0)
	scene.set("player_speed", 40.0)
	scene.set("player_lane", 2)
	scene.set("previous_player_lane", 2)
	scene.set("player_x", float(scene.call("_lane_x", 2)))
	scene.set("previous_player_x", float(scene.call("_lane_x", 2)))

	var spawned: bool = bool(scene.call("_try_spawn_rear_chase_car", 10))
	var traffic: Array = scene.get("traffic")
	var chase_car: Dictionary = traffic[0] if spawned and not traffic.is_empty() else {}
	var initial_y: float = float(chase_car.get("y", 0.0))
	var initial_speed: float = float(chase_car.get("speed", 0.0))
	var screen_size: Vector2 = scene.get("screen_size")
	var spawned_below_screen: bool = spawned and initial_y > screen_size.y
	var aggressive: bool = spawned and bool(chase_car.get("rear_chase", false)) and str(chase_car.get("driver_type", "")) == "AGGRESSIVE"
	var faster_than_player: bool = spawned and initial_speed > float(scene.get("player_speed"))
	var same_player_lane: bool = spawned and int(chase_car.get("lane", -1)) == int(scene.get("player_lane"))

	var entered_view: bool = false
	var approached_player: bool = false
	var overtake_started: bool = false
	for _frame in range(1200):
		scene.call("_update_traffic", FRAME_DELTA)
		traffic = scene.get("traffic")
		if traffic.is_empty():
			break
		chase_car = traffic[0]
		var car_y: float = float(chase_car.get("y", 0.0))
		entered_view = entered_view or car_y <= screen_size.y
		approached_player = approached_player or car_y < float(scene.get("player_y")) + 470.0
		var state: String = str(chase_car.get("state", ""))
		overtake_started = overtake_started or bool(chase_car.get("attempted_pass", false)) or state == "PREPARE OVERTAKE" or state == "LANE CHANGE" or state == "PASS PLAYER"

	var cleanup_ok: bool = false
	for _frame in range(1800):
		if (scene.get("traffic") as Array).is_empty():
			cleanup_ok = true
			break
		scene.call("_update_traffic", FRAME_DELTA)
		scene.call("_cleanup_entities")
	cleanup_ok = cleanup_ok or (scene.get("traffic") as Array).is_empty()

	# 有较多主路车辆时不生成额外追赶车。
	var dense_traffic: Array = scene.get("traffic")
	dense_traffic.clear()
	scene.set("traffic", dense_traffic)
	for index in range(8):
		scene.call("_spawn_traffic", "SEDAN", index % 5, -500.0 - float(index) * 110.0, 40.0, false, "NORMAL")
	scene.set("run_time", 20.0)
	var crowded_block: bool = not bool(scene.call("_try_spawn_rear_chase_car", 10))

	# 玩家前方有同车道车辆时，即使总量不高也不额外生成追赶压力。
	var front_blocked_traffic: Array = scene.get("traffic")
	front_blocked_traffic.clear()
	scene.set("traffic", front_blocked_traffic)
	scene.call("_spawn_traffic", "SEDAN", 2, float(scene.get("player_y")) - 120.0, 40.0, false, "NORMAL")
	var front_block: bool = not bool(scene.call("_try_spawn_rear_chase_car", 10))

	print("GRAYBOX_REAR_CHASE_TEST spawned=%s bottom_spawn=%s aggressive=%s faster=%s same_lane=%s entered=%s approached=%s overtake=%s crowded_block=%s front_block=%s cleanup=%s" % [spawned, spawned_below_screen, aggressive, faster_than_player, same_player_lane, entered_view, approached_player, overtake_started, crowded_block, front_block, cleanup_ok])
	quit(0 if spawned and spawned_below_screen and aggressive and faster_than_player and same_player_lane and entered_view and approached_player and overtake_started and crowded_block and front_block and cleanup_ok else 1)
