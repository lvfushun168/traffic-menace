extends SceneTree

const FRAME_DELTA: float = 1.0 / 60.0


func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	var screen_size: Vector2 = scene.get("screen_size")
	var road_width: float = float(scene.get("road_width"))
	var lane_width: float = float(scene.get("lane_width"))
	var player_y: float = float(scene.get("player_y"))
	var initial_traffic_count: int = (scene.get("traffic") as Array).size()
	var player_body_width: float = (scene.call("_player_body_size") as Vector2).x
	var initial_player_lane: int = int(scene.get("player_lane"))
	var road_ok: bool = absf(road_width - 510.0) < 1.0 and absf(lane_width - 102.0) < 1.0 and absf(lane_width / player_body_width - 1.5) < 0.01 and initial_player_lane == 2
	var player_frame_ok: bool = absf(player_y - screen_size.y * 0.25) < 1.0
	var arrow_controls_ok: bool = _action_has_key("move_left", KEY_LEFT) and _action_has_key("move_right", KEY_RIGHT) and _action_has_key("brake", KEY_DOWN) and _action_has_key("boost", KEY_UP)
	var number_selection_ok: bool = _action_has_key("select_item_1", KEY_1) and _action_has_key("select_item_2", KEY_2) and _action_has_key("select_item_3", KEY_3)
	var space_removed_ok: bool = not InputMap.has_action("use_item")

	# 把一辆车放到玩家正下方的目标车道，直接验证“按实际车身宽度判断卡位”。
	var cars: Array[Dictionary] = scene.get("traffic")
	var opening_distance_ok: bool = initial_traffic_count == 6
	var opening_grace_ok: bool = initial_traffic_count == 6
	for opening_car in cars:
		opening_distance_ok = opening_distance_ok and float(opening_car.get("y", player_y)) - player_y >= 259.9
		opening_grace_ok = opening_grace_ok and float(opening_car.get("opening_grace_remaining", 0.0)) >= 4.99
	if not cars.is_empty():
		var blocker: Dictionary = cars[0]
		blocker["x"] = float(scene.call("_lane_x", 2))
		blocker["lateral_target_x"] = blocker["x"]
		blocker["cruise_offset"] = 0.0
		blocker["y"] = player_y + 100.0
		blocker["lane"] = 2
		blocker["target_lane"] = 2
		blocker["attempted_pass"] = true
		blocker["passed"] = false
		blocker["crashed"] = false
		blocker["state"] = "LANE CHANGE"
		blocker["block_timer"] = 0.0
		blocker["block_reported"] = false
		cars[0] = blocker
		scene.set("traffic", cars)
		scene.set("player_x", float(scene.call("_lane_x", 2)))
		scene.set("previous_player_x", float(scene.call("_lane_x", 2)))
		scene.set("player_lane", 2)
	for _frame in range(30):
		scene.call("_update_traffic", FRAME_DELTA)
	var found_blocked: bool = false
	for car in scene.get("traffic") as Array:
		if str(car.get("state", "")) == "BLOCKED":
			found_blocked = true
			break

	# 空槽接触 Mystery Pickup 后自动放入，不需要主动按键。
	var auto_slots: Array[String] = ["OIL LEAK", "", ""]
	scene.set("item_slots", auto_slots)
	scene.set("selected_item_slot", 0)
	scene.set("item_replacement_active", false)
	scene.set("item_count", 0)
	var pickup_list: Array[Dictionary] = [{
		"x": float(scene.get("player_x")),
		"y": float(scene.get("player_y")),
		"item": "SOFA DROP",
		"collected": false,
	}]
	scene.set("pickups", pickup_list)
	scene.call("_update_pickups", 0.0)
	var slots_after_pickup: Array = scene.get("item_slots")
	var auto_pickup_ok: bool = str(slots_after_pickup[1]) == "SOFA DROP" and int(scene.get("item_count")) == 1

	# 满槽拾取必须暂停并进入替换界面；替换完成后新道具进入所选槽位。
	var full_slots: Array[String] = ["OIL LEAK", "SOFA DROP", "ROLLING TIRE"]
	scene.set("item_slots", full_slots)
	scene.set("selected_item_slot", 0)
	scene.set("item_replacement_active", false)
	var replacement_pickup_list: Array[Dictionary] = [{
		"x": float(scene.get("player_x")),
		"y": float(scene.get("player_y")),
		"item": "BANANA CART",
		"collected": false,
	}]
	scene.set("pickups", replacement_pickup_list)
	scene.call("_update_pickups", 0.0)
	var replacement_open: bool = bool(scene.get("item_replacement_active")) and str(scene.get("pending_pickup_item")) == "BANANA CART"
	var frozen_run_time: float = float(scene.get("run_time"))
	var frozen_cooldown: float = float(scene.get("item_cooldown_remaining"))
	scene.call("_physics_process", FRAME_DELTA)
	var replacement_pauses_world: bool = absf(float(scene.get("run_time")) - frozen_run_time) < 0.001 and absf(float(scene.get("item_cooldown_remaining")) - frozen_cooldown) < 0.001
	Input.action_press("choose_2")
	scene.call("_physics_process", FRAME_DELTA)
	Input.action_release("choose_2")
	Input.action_release("select_item_2")
	await process_frame
	var slots_after_replace: Array = scene.get("item_slots")
	var replacement_ok: bool = not bool(scene.get("item_replacement_active")) and str(slots_after_replace[1]) == "BANANA CART" and int(scene.get("selected_item_slot")) == 1
	var replacement_cooldown_value: float = float(scene.get("upgrade_cooldown_remaining"))
	var replacement_modal_gap_ok: bool = replacement_cooldown_value >= 2.9
	scene.set("score", 1800)
	scene.set("run_time", 10.0)
	scene.set("next_upgrade_index", 0)
	scene.set("upgrade_active", false)
	scene.call("_check_upgrade_threshold")
	var upgrade_waits_for_modal_gap: bool = not bool(scene.get("upgrade_active"))
	scene.set("upgrade_cooldown_remaining", 0.0)
	scene.call("_check_upgrade_threshold")
	var upgrade_after_modal_gap_ok: bool = bool(scene.get("upgrade_active"))
	scene.set("upgrade_active", false)
	var direct_use_slots: Array[String] = ["OIL LEAK", "BANANA CART", "ROLLING TIRE"]
	scene.set("item_slots", direct_use_slots)
	scene.set("selected_item_slot", 0)
	scene.set("item_cooldown_remaining", 0.0)
	scene.set("active_effects", {})
	scene.set("hazards", [])
	var direct_traffic: Array = scene.get("traffic")
	direct_traffic.clear()
	scene.set("traffic", direct_traffic)
	var direct_use_before: int = int(scene.get("item_use_count"))
	scene.call("_use_item_at_slot", 2)
	var direct_use_hazards: Array = scene.get("hazards")
	var direct_use_ok: bool = int(scene.get("selected_item_slot")) == 2 and int(scene.get("item_use_count")) == direct_use_before + 1 and not direct_use_hazards.is_empty()

	var passive_use_before: int = int(scene.get("item_use_count"))
	var passive_slots: Array[String] = ["SLOW MODE", "", ""]
	scene.set("item_slots", passive_slots)
	scene.set("selected_item_slot", 0)
	scene.set("item_cooldown_remaining", 0.0)
	scene.call("_use_item_at_slot", 0)
	var passive_key_ok: bool = int(scene.get("selected_item_slot")) == 0 and int(scene.get("item_use_count")) == passive_use_before and float(scene.get("item_cooldown_remaining")) <= 0.0

	# 主动道具可重复使用但不消耗；共享冷却期间第二次使用应被挡住。
	var cooldown_slots: Array[String] = ["OIL LEAK", "BANANA CART", "ROLLING TIRE"]
	scene.set("item_slots", cooldown_slots)
	scene.set("selected_item_slot", 0)
	scene.set("item_cooldown_remaining", 0.0)
	scene.set("active_effects", {})
	var use_before: int = int(scene.get("item_use_count"))
	scene.call("_use_item")
	var use_after_first: int = int(scene.get("item_use_count"))
	var slot_persistent: bool = str((scene.get("item_slots") as Array)[0]) == "OIL LEAK" and use_after_first == use_before + 1
	scene.call("_use_item")
	var cooldown_blocks_repeat: bool = int(scene.get("item_use_count")) == use_after_first and float(scene.get("item_cooldown_remaining")) > 2.9
	scene.set("item_cooldown_remaining", 0.0)
	scene.call("_use_item")
	var reusable_after_cooldown: bool = int(scene.get("item_use_count")) == use_after_first + 1

	print("GRAYBOX_SMOKE_TEST road=%s road_width=%.1f initial_cars=%s lane_width=%.1f base_player_width=%.1f player_lane=%s player_y=%.1f player_frame=%s opening_distance=%s opening_grace=%s blocked=%s arrows=%s numbers=%s" % [road_ok, road_width, initial_traffic_count, lane_width, player_body_width, initial_player_lane, player_y, player_frame_ok, opening_distance_ok, opening_grace_ok, found_blocked, arrow_controls_ok, number_selection_ok])
	print("GRAYBOX_SMOKE_TEST auto_pickup=%s replacement_open=%s replacement_pause=%s replacement_ok=%s modal_gap=%s replacement_cooldown=%.2f upgrade_wait=%s upgrade_after_gap=%s direct_use=%s passive_key=%s space_removed=%s" % [auto_pickup_ok, replacement_open, replacement_pauses_world, replacement_ok, replacement_modal_gap_ok, replacement_cooldown_value, upgrade_waits_for_modal_gap, upgrade_after_modal_gap_ok, direct_use_ok, passive_key_ok, space_removed_ok])
	print("GRAYBOX_SMOKE_TEST persistent=%s cooldown=%s reusable=%s slots=%s" % [slot_persistent, cooldown_blocks_repeat, reusable_after_cooldown, scene.get("item_slots")])
	quit(0 if road_ok and initial_traffic_count == 6 and player_frame_ok and opening_distance_ok and opening_grace_ok and found_blocked and arrow_controls_ok and number_selection_ok and space_removed_ok and auto_pickup_ok and replacement_open and replacement_pauses_world and replacement_ok and replacement_modal_gap_ok and upgrade_waits_for_modal_gap and upgrade_after_modal_gap_ok and direct_use_ok and passive_key_ok and slot_persistent and cooldown_blocks_repeat and reusable_after_cooldown else 1)


func _action_has_key(action_name: String, key_code: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null and (int(key_event.keycode) == key_code or int(key_event.physical_keycode) == key_code):
			return true
	return false
