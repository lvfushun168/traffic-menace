extends SceneTree

const ITEM_KEYS: Array[String] = [
	"SOFA DROP", "ROLLING TIRE", "BANANA CART", "FAKE TURN SIGNAL", "LONG TRAILER",
	"POPCORN MACHINE", "BROKEN TRUNK", "ROADWORK SIGN", "GIANT MATTRESS", "MAGNET",
	"PAINT LEAK", "FAKE POLICE LIGHT", "OVERLOADED RACK", "INFLATABLE POOL",
	"ROGUE SHOPPING CART", "OIL LEAK", "BLACK SMOKE", "SLOW MODE", "WIDE BODY",
	"SNAKE SWERVE", "NAIL RAIN", "FAKE BRAKE LIGHT", "MOVING ROADBLOCK",
]

const PASSIVE_ITEM_KEYS: Array[String] = [
	"BROKEN TRUNK", "OVERLOADED RACK", "SLOW MODE", "WIDE BODY", "SNAKE SWERVE",
	"FAKE BRAKE LIGHT", "MOVING ROADBLOCK",
]


func _init() -> void:
	var scene: Node = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	scene.call("reset_run")

	var definitions: Dictionary = scene.get("item_definitions")
	var definitions_ok: bool = definitions.size() == ITEM_KEYS.size()
	for item_key in ITEM_KEYS:
		if not definitions.has(item_key):
			definitions_ok = false
			break

	var active_successes: int = 0
	var active_expected: int = ITEM_KEYS.size() - PASSIVE_ITEM_KEYS.size()
	var passive_ok: bool = true
	var active_ok: bool = true
	for item_key in ITEM_KEYS:
		var test_slots: Array[String] = [item_key, "", ""]
		var empty_hazards: Array[Dictionary] = []
		var empty_props: Array[Dictionary] = []
		var empty_traffic: Array[Dictionary] = []
		scene.set("item_slots", test_slots)
		scene.set("selected_item_slot", 0)
		scene.set("item_cooldown_remaining", 0.0)
		scene.set("hazards", empty_hazards)
		scene.set("active_effects", {})
		scene.set("loose_props", empty_props)
		scene.set("traffic", empty_traffic)
		var use_before: int = int(scene.get("item_use_count"))
		scene.call("_use_item")
		var slots: Array = scene.get("item_slots")
		if str(slots[0]) != item_key:
			active_ok = false
		if item_key in PASSIVE_ITEM_KEYS:
			passive_ok = passive_ok and int(scene.get("item_use_count")) == use_before and bool(scene.call("_has_item", item_key))
		else:
			var hazards: Array = scene.get("hazards")
			var active_effects: Dictionary = scene.get("active_effects")
			var generated: bool = not hazards.is_empty() or active_effects.has(item_key)
			active_successes += 1 if generated else 0
			active_ok = active_ok and generated and int(scene.get("item_use_count")) == use_before + 1

	# 抽查三类被动行为：速度、车身宽度、移动护栏的路线阻挡。
	var slow_slots: Array[String] = ["SLOW MODE", "", ""]
	scene.set("item_slots", slow_slots)
	scene.set("player_speed", 40.0)
	scene.call("_update_player", 0.1)
	var slow_mode_ok: bool = float(scene.get("player_speed")) < 40.0
	var wide_slots: Array[String] = ["WIDE BODY", "", ""]
	scene.set("item_slots", wide_slots)
	var wide_body_ok: bool = float((scene.call("_player_body_size") as Vector2).x) > 68.0
	var barrier_slots: Array[String] = ["MOVING ROADBLOCK", "", ""]
	scene.set("item_slots", barrier_slots)
	var moving_barrier_ok: bool = bool(scene.call("_moving_barrier_blocks_lane", 2, float(scene.get("player_y")) + 106.0))

	print("GRAYBOX_ITEM_TEST definitions=%s total=%s active=%s/%s passive=%s" % [definitions_ok, definitions.size(), active_successes, active_expected, passive_ok])
	print("GRAYBOX_ITEM_TEST slow_mode=%s wide_body=%s moving_barrier=%s" % [slow_mode_ok, wide_body_ok, moving_barrier_ok])
	quit(0 if definitions_ok and active_ok and active_successes == active_expected and passive_ok and slow_mode_ok and wide_body_ok and moving_barrier_ok else 1)
