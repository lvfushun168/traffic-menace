extends Node2D

## Traffic Menace 灰盒：只保留“观察意图 → 干预 → 连锁反应”验证所需的系统。

const RUN_LIMIT_SECONDS: float = 480.0
const PLAYER_SPEED_SCALE: float = 3.0
const MAX_DURABILITY: int = 10
const LANE_COUNT: int = 5
const UPGRADE_THRESHOLDS: Array[int] = [1800, 5000, 9800, 16000, 24000, 34000]
const PLAYER_BASE_BODY_WIDTH: float = 68.0
const LANE_WIDTH_TO_PLAYER_RATIO: float = 1.5
const ROAD_WIDTH_REFERENCE: float = PLAYER_BASE_BODY_WIDTH * LANE_WIDTH_TO_PLAYER_RATIO * float(LANE_COUNT)
const MIN_ROAD_WIDTH: float = ROAD_WIDTH_REFERENCE
const OPENING_TRAFFIC_INITIAL_COUNT: int = 6
const OPENING_TRAFFIC_TARGET_COUNT: int = 8
const OPENING_TRAFFIC_FIRST_PHASE_SECONDS: float = 10.0
const OPENING_TRAFFIC_SECOND_PHASE_SECONDS: float = 30.0
const OPENING_TRAFFIC_BASELINE_SECONDS: float = 60.0
const STARTING_TRAFFIC_COUNT: int = 30
const MAX_TRAFFIC_AT_END: int = 80
const TRAFFIC_CLEANUP_BUFFER: float = 920.0
const TRAFFIC_FAR_AI_INTERVAL: float = 0.10
const TRAFFIC_CRASH_RETENTION_SECONDS: float = 3.0
const ITEM_SLOT_COUNT: int = 3
const ITEM_COOLDOWN_SECONDS: float = 3.0
const UPGRADE_FIRST_AVAILABLE_SECONDS: float = 10.0
const UPGRADE_MIN_INTERVAL_SECONDS: float = 15.0
const UPGRADE_MODAL_GAP_SECONDS: float = 3.0
const MERGE_GATE_Y_RATIO: float = 0.62
const MERGE_BASE_INTERVAL_START: float = 1.80
const MERGE_BASE_INTERVAL_END: float = 1.15
const MERGE_EVENT_INTERVAL_START: float = 0.90
const MERGE_EVENT_INTERVAL_END: float = 0.60
const MERGE_QUEUE_LIMIT: int = 8
const MERGE_CAPACITY_BUFFER: int = 5
const MERGE_ENTRY_OFFSET: float = 82.0
const MERGE_ENTRY_Y_OFFSET: float = 84.0
const MERGE_JUNCTION_START_Y: float = -260.0
const MERGE_JUNCTION_CULL_MARGIN: float = 220.0
const MERGE_RAMP_WIDTH: float = 78.0
const MERGE_RAMP_SHOULDER_WIDTH: float = 92.0
const MERGE_PATH_SAMPLE_COUNT: int = 16
const MERGE_COMMIT_PROGRESS: float = 0.32
const MERGE_PATH_TIME_PADDING: float = 0.14
const MERGE_LATERAL_SPEED: float = 300.0
const MERGE_GAP_PADDING: float = 4.0
const MERGE_REPLAN_INTERVAL: float = 0.35
const MERGE_EXIT_DURATION: float = 26.0
const MERGE_EXIT_SPEED_BONUS: float = 14.0
const MERGE_YIELD_PROBE_DURATION: float = 1.60
const PLAYER_REAR_BUFFER: float = 18.0
const PLAYER_LATERAL_CLEARANCE: float = 4.0
const PLAYER_AVOID_DURATION: float = 0.75
const MAX_OVERTAKE_HOPS: int = 4
const NPC_BRAKE_DECELERATION: float = 20.0
const NPC_CONTACT_SPEED_THRESHOLD: float = 12.0
const NPC_CONTACT_SEPARATION: float = 6.0
const NPC_BODY_BUFFER: float = 10.0
const NPC_SPAWN_MIN_CLEARANCE: float = 42.0
const NPC_LANE_RESERVATION_PADDING: float = 18.0
const NPC_CRUISE_LATERAL_PADDING: float = 12.0
const NPC_LANE_RESERVATION_DURATION: float = 0.55
const NPC_LANE_COMMIT_DURATION: float = 0.28
const NPC_REPLAN_INTERVAL: float = 0.16
const NPC_SPEED_SHOCK_TARGET: float = 10.0
const NPC_SPEED_SHOCK_DURATION: float = 0.90
const NPC_SPEED_SHOCK_MEMORY: float = 1.25
const NPC_SPEED_SHOCK_RESET_DISTANCE: float = 360.0
const NPC_CRASH_BLOCK_DURATION: float = 2.0
const NPC_FOLLOW_GAP_RECOVERY_MAX: float = 12.0
const OPENING_PLAYER_CENTER_GAP: float = 260.0
const OPENING_PLAYER_RESPONSE_BUFFER: float = 120.0
const OPENING_PLAYER_GRACE_SECONDS: float = 5.0

const DRIVER_PROFILES: Dictionary = {
	"CAUTIOUS": {
		"speed_min": 39.1,
		"speed_max": 46.0,
		"reaction_distance": 260.0,
		"follow_gap": 170.0,
		"reaction_time": 0.45,
		"overtake_trigger_distance": 260.0,
		"overtake_commit_distance": 70.0,
		"wait_min": 1.0,
		"wait_max": 1.8,
		"lateral_speed": 105.0,
		"cruise_offset": 0.05,
		"wander_amplitude": 1.5,
		"follow_speed": 39.1,
		"overtake_speed": 52.9,
		"pass_burst_speed": 62.1,
		"overtake_acceleration": 70.0,
		"pass_burst_duration": 0.20,
		"lane_change_padding": 24.0,
		"brake_speed": 28.0,
	},
	"NORMAL": {
		"speed_min": 43.7,
		"speed_max": 52.9,
		"reaction_distance": 190.0,
		"follow_gap": 135.0,
		"reaction_time": 0.30,
		"overtake_trigger_distance": 360.0,
		"overtake_commit_distance": 100.0,
		"wait_min": 0.45,
		"wait_max": 0.9,
		"lateral_speed": 170.0,
		"cruise_offset": 0.20,
		"wander_amplitude": 3.0,
		"follow_speed": 41.4,
		"overtake_speed": 59.8,
		"pass_burst_speed": 78.2,
		"overtake_acceleration": 110.0,
		"pass_burst_duration": 0.30,
		"lane_change_padding": 14.0,
		"brake_speed": 30.0,
	},
	"AGGRESSIVE": {
		"speed_min": 55.2,
		"speed_max": 64.4,
		"reaction_distance": 115.0,
		"follow_gap": 92.0,
		"reaction_time": 0.18,
		"overtake_trigger_distance": 470.0,
		"overtake_commit_distance": 145.0,
		"wait_min": 0.10,
		"wait_max": 0.35,
		"lateral_speed": 270.0,
		"cruise_offset": 0.42,
		"wander_amplitude": 6.0,
		"follow_speed": 48.3,
		"overtake_speed": 69.0,
		"pass_burst_speed": 103.5,
		"overtake_acceleration": 180.0,
		"pass_burst_duration": 0.45,
		"lane_change_padding": 6.0,
		"brake_speed": 34.0,
	},
}

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

const COLOR_BG := Color("#091018")
const COLOR_SIDEWALK := Color("#17222d")
const COLOR_ROAD := Color("#26323b")
const COLOR_ROAD_EDGE := Color("#64717a")
const COLOR_LANE := Color("#9ca8ae")
const COLOR_CURB := Color("#4c5b61")
const COLOR_MERGE := Color("#63c7d9")
const COLOR_ACCENT := Color("#58e1c1")
const COLOR_WARNING := Color("#ffcb5c")
const COLOR_DANGER := Color("#ff6b6b")
const COLOR_INFO := Color("#9ac7ff")
const COLOR_PANEL := Color(0.035, 0.065, 0.10, 0.94)

var rng := RandomNumberGenerator.new()
var screen_size: Vector2 = Vector2(1280, 720)
var ui_font: Font
var road_surface_texture: Texture2D
var sidewalk_surface_texture: Texture2D
var player_y: float = 180.0
var road_left: float = 240.0
var road_width: float = ROAD_WIDTH_REFERENCE
var lane_width: float = PLAYER_BASE_BODY_WIDTH * LANE_WIDTH_TO_PLAYER_RATIO
var lane_centers: Array[float] = []

var run_time: float = 0.0
var player_x: float = 640.0
var previous_player_x: float = 640.0
var player_speed: float = 40.0
var player_steer: float = 0.0
var road_scroll: float = 0.0
var durability: int = MAX_DURABILITY
var score: int = 0
var combo: int = 0
var combo_timer: float = 0.0
var chain_count: int = 0
var chain_timer: float = 0.0
var last_overtake_damage_time: float = -10.0
var player_collision_cooldown: float = 0.0
var vehicles_trapped: int = 0
var chaos_multiplier: float = 1.0

var item_slots: Array[String] = ["OIL LEAK", "", ""]
var selected_item_slot: int = 0
var item_cooldown_remaining: float = 0.0
var item_count: int = 0
var item_use_count: int = 0
var pickup_count: int = 0
var pending_pickup_item: String = ""
var pending_replacement_source: String = ""
var item_replacement_active: bool = false
var item_definitions: Dictionary = {}
var active_effects: Dictionary = {}
var player_lane: int = 2
var previous_player_lane: int = 2
var lane_change_cooldown: float = 0.0
var loose_props: Array[Dictionary] = []
var spawn_clock: float = 0.0
var pickup_clock: float = 8.0
var road_event_clock: float = 0.0
var road_event_count: int = 0
var next_car_id: int = 1
var merge_source_clock: float = 0.0
var merge_queue_count: int = 0
var merge_queue_peak: int = 0
var merge_spawned_count: int = 0
var merge_side_toggle: int = -1
var merge_display_lane: int = 2
var merge_last_feedback_time: float = -10.0
var merge_release_cooldown: float = 0.0
var merge_yield_probe_lane: int = -1
var merge_yield_probe_car_id: int = -1
var merge_yield_probe_side: int = 0
var merge_yield_probe_timer: float = 0.0
var merge_junctions: Array[Dictionary] = []

var traffic: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var road_events: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var messages: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []

var upgrade_pool: Array[Dictionary] = []
var upgrade_cards: Array[Dictionary] = []
var next_upgrade_index: int = 0
var upgrade_active: bool = false
var upgrade_cooldown_remaining: float = 0.0
var upgrade_offer_count: int = 0
var upgrade_offer_times: Array[float] = []
var paused: bool = false
var game_over: bool = false
var run_complete: bool = false

var traffic_ai_full_updates: int = 0
var traffic_ai_lod_updates: int = 0

var shake_trauma: float = 0.0
var shake_phase: float = 0.0
var flash_alpha: float = 0.0


func _ready() -> void:
	rng.seed = 18062026
	_ensure_input_actions()
	ui_font = ThemeDB.fallback_font
	var bundled_font: Font = load("res://ui_font.ttf") as Font
	if bundled_font != null:
		ui_font = bundled_font
	_load_road_textures()
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	_build_item_definitions()
	_build_upgrade_pool()
	reset_run()


## 创建可平铺的道路材质；窗口运行时优先读取 SVG，无窗口环境使用程序纹理兜底。
func _load_road_textures() -> void:
	var display_server_name: String = DisplayServer.get_name().to_lower()
	if display_server_name == "headless" or OS.has_feature("headless") or OS.has_feature("movie"):
		return
	road_surface_texture = load("res://assets/road/road_surface.svg") as Texture2D
	sidewalk_surface_texture = load("res://assets/road/sidewalk_surface.svg") as Texture2D
	if road_surface_texture == null:
		road_surface_texture = _build_road_surface_texture()
	if sidewalk_surface_texture == null:
		sidewalk_surface_texture = _build_sidewalk_surface_texture()


## 生成带低对比像素磨损的沥青纹理，车道线由运行时单独绘制。
func _build_road_surface_texture() -> Texture2D:
	var image: Image = Image.create(128, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color("#26343a"))
	for y in range(256):
		for x in range(128):
			var hash_value: int = posmod(x * 17 + y * 31 + (x / 8) * 13, 257)
			if hash_value == 7 or hash_value == 53:
				image.set_pixel(x, y, Color("#35464c"))
			elif hash_value == 101 or hash_value == 181:
				image.set_pixel(x, y, Color("#1f2c32"))
		for x in range(0, 128, 32):
			image.set_pixel(x, y, Color("#2c3b41"))
		if y == 128 or y == 129 or y == 134:
			for x in range(128):
				image.set_pixel(x, y, Color("#1d292f"))
	var patch_rects: Array[Rect2i] = [
		Rect2i(11, 22, 23, 3), Rect2i(75, 14, 16, 4), Rect2i(43, 48, 31, 3),
		Rect2i(94, 69, 22, 4), Rect2i(7, 93, 16, 4), Rect2i(54, 112, 19, 3),
		Rect2i(23, 153, 28, 4), Rect2i(83, 174, 25, 3), Rect2i(8, 201, 22, 3),
		Rect2i(48, 224, 35, 4),
	]
	for patch_rect in patch_rects:
		for y in range(patch_rect.position.y, patch_rect.end.y):
			for x in range(patch_rect.position.x, patch_rect.end.x):
				image.set_pixel(x, y, Color("#1c282e"))
	return ImageTexture.create_from_image(image)


## 生成混凝土板与路肩纹理，使用明显但低亮度的拼缝提示道路边界。
func _build_sidewalk_surface_texture() -> Texture2D:
	var image: Image = Image.create(96, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color("#17242c"))
	for y in range(256):
		for x in range(96):
			if x == 46 or x == 47:
				image.set_pixel(x, y, Color("#101b22"))
			elif (x * 11 + y * 7) % 149 == 9:
				image.set_pixel(x, y, Color("#2c3d45"))
	for y in [59, 60, 61, 123, 124, 125, 187, 188, 189]:
		for x in range(96):
			image.set_pixel(x, y, Color("#101b22"))
	for y in [12, 13, 14, 30, 31, 32, 80, 81, 82, 98, 99, 100, 151, 152, 153, 166, 167, 168, 215, 216, 217, 231, 232, 233]:
		for x in range(8, 32):
			if (x + y) % 5 < 3:
				image.set_pixel(x, y, Color("#2c3d45"))
	return ImageTexture.create_from_image(image)


func _on_viewport_resized() -> void:
	screen_size = get_viewport_rect().size
	player_y = screen_size.y * 0.25
	road_width = minf(ROAD_WIDTH_REFERENCE, maxf(screen_size.x - 48.0, MIN_ROAD_WIDTH))
	road_width = minf(road_width, maxf(screen_size.x - 24.0, 160.0))
	road_left = (screen_size.x - road_width) * 0.5
	lane_width = road_width / float(LANE_COUNT)
	lane_centers.clear()
	for lane in range(LANE_COUNT):
		lane_centers.append(road_left + lane_width * (float(lane) + 0.5))
	var player_margin: float = _player_body_size().x * 0.5
	player_x = clampf(player_x, road_left + player_margin, road_left + road_width - player_margin)
	previous_player_x = player_x


func reset_run() -> void:
	run_time = 0.0
	player_x = _lane_x(2)
	previous_player_x = player_x
	player_lane = 2
	previous_player_lane = 2
	player_speed = 40.0
	player_steer = 0.0
	road_scroll = 0.0
	durability = MAX_DURABILITY
	score = 0
	combo = 0
	combo_timer = 0.0
	chain_count = 0
	chain_timer = 0.0
	last_overtake_damage_time = -10.0
	player_collision_cooldown = 0.0
	vehicles_trapped = 0
	chaos_multiplier = 1.0
	item_slots = ["OIL LEAK", "", ""]
	selected_item_slot = 0
	item_cooldown_remaining = 0.0
	item_count = 0
	item_use_count = 0
	pickup_count = 0
	pending_pickup_item = ""
	pending_replacement_source = ""
	item_replacement_active = false
	active_effects.clear()
	lane_change_cooldown = 0.0
	spawn_clock = 0.0
	pickup_clock = 8.0
	road_event_clock = 0.0
	road_event_count = 0
	next_car_id = 1
	merge_source_clock = 0.0
	merge_queue_count = 0
	merge_queue_peak = 0
	merge_spawned_count = 0
	merge_side_toggle = -1
	merge_display_lane = 2
	merge_last_feedback_time = -10.0
	merge_release_cooldown = 0.0
	merge_yield_probe_lane = -1
	merge_yield_probe_car_id = -1
	merge_yield_probe_side = 0
	merge_yield_probe_timer = 0.0
	merge_junctions.clear()
	traffic.clear()
	hazards.clear()
	pickups.clear()
	road_events.clear()
	particles.clear()
	messages.clear()
	floating_texts.clear()
	loose_props.clear()
	upgrade_cards.clear()
	next_upgrade_index = 0
	upgrade_active = false
	upgrade_cooldown_remaining = 0.0
	upgrade_offer_count = 0
	upgrade_offer_times.clear()
	paused = false
	game_over = false
	run_complete = false
	traffic_ai_full_updates = 0
	traffic_ai_lod_updates = 0
	shake_trauma = 0.0
	shake_phase = 0.0
	flash_alpha = 0.0

	# 开局先铺五道车道的首排和一辆错峰车辆，后续车流由分段目标逐步补齐。
	var opening_kinds: Array[String] = ["SEDAN", "SUV", "PICKUP", "VAN", "TRUCK", "BUS"]
	var opening_gate_y: float = _merge_gate_y()
	var opening_start_base: float = maxf(player_y + OPENING_PLAYER_CENTER_GAP, opening_gate_y - 180.0)
	var opening_lane_starts: Array[float] = [
		opening_start_base,
		opening_start_base + 18.0,
		opening_start_base - 12.0,
		opening_start_base + 28.0,
		opening_start_base - 6.0,
	]
	var next_lane_y: Array[float] = []
	for lane_index in range(LANE_COUNT):
		var start_index: int = mini(lane_index, opening_lane_starts.size() - 1)
		next_lane_y.append(opening_lane_starts[start_index])
	for index in range(OPENING_TRAFFIC_INITIAL_COUNT):
		var lane: int = index % LANE_COUNT
		var aggressive: bool = index % 7 == 0 or index % 11 == 0
		var driver_type: String = "AGGRESSIVE" if aggressive else ("CAUTIOUS" if index % 5 == 0 else "NORMAL")
		var visible_kinds: Array[String] = ["SEDAN", "SUV", "PICKUP", "VAN", "TRUCK"]
		var row: int = index / LANE_COUNT
		var kind: String = "SEDAN" if aggressive else (visible_kinds[lane] if row < 4 else opening_kinds[index % opening_kinds.size()])
		var profile: Dictionary = _driver_profile(driver_type)
		var speed_phase: float = float((index * 7) % 11) / 10.0
		var base_speed: float = lerpf(float(profile["speed_min"]), float(profile["speed_max"]), speed_phase)
		var y: float = float(next_lane_y[lane])
		_spawn_traffic(kind, lane, y, base_speed, aggressive, driver_type)
		var opening_car: Dictionary = traffic[traffic.size() - 1]
		var player_safe_y: float = _player_rear_safe_y(opening_car)
		var minimum_opening_y: float = maxf(player_y + OPENING_PLAYER_CENTER_GAP, player_safe_y + OPENING_PLAYER_RESPONSE_BUFFER)
		opening_car["y"] = maxf(float(opening_car.get("y", y)), minimum_opening_y)
		opening_car["previous_y"] = float(opening_car["y"])
		opening_car["opening_grace_remaining"] = OPENING_PLAYER_GRACE_SECONDS
		_ensure_new_car_clearance(opening_car)
		y = float(opening_car.get("y", y))
		# 开局车流需要错峰，不能让五条车道的第一排车辆同时堵在合流口。
		var opening_clearance: float = maxf(maxf(NPC_SPAWN_MIN_CLEARANCE, float(profile["follow_gap"]) * 0.72), 260.0)
		next_lane_y[lane] = y + _car_dimensions(kind).y + opening_clearance
	_seed_loose_props()
	_push_message("目标  /  堵住超车", COLOR_ACCENT, 3.0)
	_push_message("←/→ 移动 · ↓ 减速 30 · ↑ 加速 50 · 1/2/3 直接使用道具", COLOR_INFO, 4.5)
	queue_redraw()


## 返回指定司机人格的调校参数，未知人格统一回退到普通司机。
func _driver_profile(driver_type: String) -> Dictionary:
	return DRIVER_PROFILES.get(driver_type, DRIVER_PROFILES["NORMAL"])


## 按开局教学节奏和后期压力曲线返回当前允许的主路有效车辆数量。
func _traffic_target_count(elapsed: float) -> int:
	var safe_elapsed: float = maxf(elapsed, 0.0)
	if safe_elapsed < OPENING_TRAFFIC_FIRST_PHASE_SECONDS:
		return int(round(lerpf(float(OPENING_TRAFFIC_INITIAL_COUNT), float(OPENING_TRAFFIC_TARGET_COUNT), safe_elapsed / OPENING_TRAFFIC_FIRST_PHASE_SECONDS)))
	if safe_elapsed < OPENING_TRAFFIC_SECOND_PHASE_SECONDS:
		var second_phase_progress: float = (safe_elapsed - OPENING_TRAFFIC_FIRST_PHASE_SECONDS) / (OPENING_TRAFFIC_SECOND_PHASE_SECONDS - OPENING_TRAFFIC_FIRST_PHASE_SECONDS)
		return int(round(lerpf(float(OPENING_TRAFFIC_TARGET_COUNT), float(STARTING_TRAFFIC_COUNT), second_phase_progress)))
	if safe_elapsed < OPENING_TRAFFIC_BASELINE_SECONDS:
		var baseline_progress: float = (safe_elapsed - OPENING_TRAFFIC_SECOND_PHASE_SECONDS) / (OPENING_TRAFFIC_BASELINE_SECONDS - OPENING_TRAFFIC_SECOND_PHASE_SECONDS)
		return int(round(lerpf(float(STARTING_TRAFFIC_COUNT * 0.5), float(STARTING_TRAFFIC_COUNT), baseline_progress)))
	var late_phase_progress: float = clampf((safe_elapsed - OPENING_TRAFFIC_BASELINE_SECONDS) / (RUN_LIMIT_SECONDS - OPENING_TRAFFIC_BASELINE_SECONDS), 0.0, 1.0)
	return int(round(lerpf(float(STARTING_TRAFFIC_COUNT), float(MAX_TRAFFIC_AT_END), late_phase_progress)))


## 判断车辆是否已经离开可视区域，允许普通巡航车辆降低路线决策频率。
func _traffic_is_far_from_player(car: Dictionary) -> bool:
	var car_y: float = float(car.get("y", player_y))
	return car_y < -160.0 or car_y > screen_size.y + 180.0


## 决定车辆本帧是否需要运行完整的路线、障碍和超车决策。
func _traffic_requires_full_ai(car: Dictionary) -> bool:
	if bool(car.get("crashed", false)):
		return false
	var state: String = str(car.get("state", "CRUISE"))
	if state != "CRUISE" or not _traffic_is_far_from_player(car):
		return true
	if float(car.get("merge_exit_timer", 0.0)) > 0.0 or bool(car.get("merge_exit_offset_pending", false)):
		return true
	return float(car.get("ai_decision_timer", 0.0)) <= 0.0


## 以轻量巡航逻辑推进远端车辆，避免在不可见区域重复进行完整路线扫描。
func _advance_distant_traffic(car: Dictionary, delta: float) -> void:
	var driver_type: String = str(car.get("driver_type", "NORMAL"))
	var profile: Dictionary = _driver_profile(driver_type)
	var kind: String = str(car.get("kind", "SEDAN"))
	car["pressure"] = maxf(float(car.get("pressure", 0.0)) - delta, 0.0)
	car["indicator_clock"] = float(car.get("indicator_clock", 0.0)) + delta
	car["slip"] = maxf(float(car.get("slip", 0.0)) - delta, 0.0)
	car["hazard_cooldown"] = maxf(float(car.get("hazard_cooldown", 0.0)) - delta, 0.0)
	car["player_avoid_timer"] = maxf(float(car.get("player_avoid_timer", 0.0)) - delta, 0.0)
	car["contact_cooldown"] = maxf(float(car.get("contact_cooldown", 0.0)) - delta, 0.0)
	car["speed_shock_timer"] = maxf(float(car.get("speed_shock_timer", 0.0)) - delta, 0.0)
	car["speed_shock_memory_timer"] = maxf(float(car.get("speed_shock_memory_timer", 0.0)) - delta, 0.0)
	if float(car.get("speed_shock_timer", 0.0)) <= 0.0:
		car["speed_shock_target"] = -1.0
	if float(car.get("speed_shock_memory_timer", 0.0)) <= 0.0:
		car["speed_shock_source"] = ""
	var desired_speed: float = float(car.get("base_speed", player_speed))
	if float(car.get("speed_shock_timer", 0.0)) > 0.0:
		desired_speed = minf(desired_speed, float(car.get("speed_shock_target", NPC_SPEED_SHOCK_TARGET)))
	var current_speed: float = float(car.get("speed", desired_speed))
	var next_speed: float = move_toward(current_speed, desired_speed, 30.0 * delta)
	car["speed"] = next_speed
	car["speed_command"] = desired_speed
	car["y"] = float(car.get("y", player_y)) + (player_speed - next_speed) * PLAYER_SPEED_SCALE * delta
	var target_x: float = float(car.get("lateral_target_x", _lane_x(int(car.get("lane", 0)))))
	var wander_phase: float = float(car.get("wander_phase", 0.0))
	var wander_amplitude: float = float(profile.get("wander_amplitude", 0.0))
	var desired_x: float = _clamp_car_center_x(target_x + sin(run_time * 1.35 + wander_phase) * wander_amplitude, _car_dimensions(kind).x)
	car["x"] = move_toward(float(car.get("x", target_x)), desired_x, float(profile.get("lateral_speed", 120.0)) * delta)
	car["x"] = _clamp_car_center_x(float(car["x"]), _car_dimensions(kind).x)


## 为车辆选择一个可用的相邻车道分隔线，避免目标落在道路外侧边界。
func _choose_divider_side(lane: int) -> int:
	if lane <= 0:
		return 1
	if lane >= LANE_COUNT - 1:
		return -1
	return -1 if rng.randf() < 0.5 else 1


## 根据人格和分隔线方向生成稳定的巡航横向偏移。
func _driver_cruise_offset(driver_type: String, divider_side: int) -> float:
	var profile: Dictionary = _driver_profile(driver_type)
	var magnitude: float = float(profile["cruise_offset"])
	var varied_magnitude: float = rng.randf_range(magnitude * 0.85, magnitude * 1.10)
	return clampf(float(divider_side if divider_side != 0 else 1) * varied_magnitude, -0.46, 0.46)


## 把连续横向坐标限制在车辆实际车身可以通过的道路范围内。
func _clamp_car_center_x(x: float, body_width: float) -> float:
	var half_width: float = body_width * 0.5
	return clampf(x, road_left + half_width, road_left + road_width - half_width)


## 返回两条相邻车道之间的真实分隔线坐标。
func _lane_boundary_x(first_lane: int, second_lane: int) -> float:
	var boundary_index: int = clampi(maxi(first_lane, second_lane), 1, LANE_COUNT - 1)
	return road_left + float(boundary_index) * lane_width


## 按车辆人格偏移计算指定车道的连续横向目标点。
func _lane_target_x(car: Dictionary, lane: int) -> float:
	var kind: String = str(car.get("kind", "SEDAN"))
	var offset: float = float(car.get("cruise_offset", 0.0))
	return _clamp_car_center_x(_lane_x(lane) + offset * lane_width, _car_dimensions(kind).x)


## 把车辆的横向目标切换到指定车道，同时保留其自然的压线偏好。
func _set_lateral_target(car: Dictionary, lane: int) -> void:
	car["lateral_target_x"] = _safe_cruise_target_x(car, _lane_target_x(car, lane), lane)


## 在保留压线风格的前提下，避免相邻车道车辆的实际车身互相侵入。
func _safe_cruise_target_x(car: Dictionary, desired_x: float, lane: int = -1) -> float:
	var current_lane: int = int(car.get("lane", 0)) if lane < 0 else lane
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var road_min_x: float = road_left + car_size.x * 0.5
	var road_max_x: float = road_left + road_width - car_size.x * 0.5
	var lane_center: float = _lane_x(current_lane)
	var candidates: Array[float] = [clampf(desired_x, road_min_x, road_max_x), lane_center]
	var position_padding: float = NPC_CRUISE_LATERAL_PADDING
	var car_id: int = int(car.get("id", -1))
	for other in traffic:
		if int(other.get("id", -2)) == car_id or bool(other.get("crashed", false)):
			continue
		if int(other.get("lane", current_lane)) == current_lane:
			continue
		var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
		var vertical_limit: float = (car_size.y + other_size.y) * 0.5 + NPC_LANE_RESERVATION_PADDING
		if absf(float(car.get("y", 0.0)) - float(other.get("y", 0.0))) > vertical_limit:
			continue
		var horizontal_clearance: float = (car_size.x + other_size.x) * 0.5 + position_padding
		candidates.append(clampf(float(other.get("x", lane_center)) - horizontal_clearance, road_min_x, road_max_x))
		candidates.append(clampf(float(other.get("x", lane_center)) + horizontal_clearance, road_min_x, road_max_x))
	var best_x: float = lane_center
	var best_distance: float = INF
	var found_safe_position: bool = false
	for candidate_x in candidates:
		var safe: bool = true
		for other in traffic:
			if int(other.get("id", -2)) == car_id or bool(other.get("crashed", false)):
				continue
			if int(other.get("lane", current_lane)) == current_lane:
				continue
			var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
			var vertical_limit: float = (car_size.y + other_size.y) * 0.5 + NPC_LANE_RESERVATION_PADDING
			if absf(float(car.get("y", 0.0)) - float(other.get("y", 0.0))) > vertical_limit:
				continue
			if _horizontal_overlap(candidate_x, car_size.x, float(other.get("x", candidate_x)), other_size.x, position_padding):
				safe = false
				break
		if safe and absf(candidate_x - desired_x) < best_distance:
			found_safe_position = true
			best_distance = absf(candidate_x - desired_x)
			best_x = candidate_x
	if found_safe_position:
		return best_x
	return lane_center


## 将开局或普通刷新车辆沿纵向推到已有车流之后，避免混合车型在生成瞬间重叠。
func _ensure_new_car_clearance(car: Dictionary) -> void:
	var car_id: int = int(car.get("id", -1))
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var guard: int = 0
	var moved: bool = true
	while moved and guard < traffic.size() + 2:
		moved = false
		guard += 1
		for other in traffic:
			if int(other.get("id", -2)) == car_id or bool(other.get("crashed", false)):
				continue
			var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
			var car_center: Vector2 = Vector2(float(car.get("x", 0.0)), float(car.get("y", 0.0)))
			var other_center: Vector2 = Vector2(float(other.get("x", 0.0)), float(other.get("y", 0.0)))
			if not _rects_overlap(car_center, car_size, other_center, other_size):
				continue
			var required_y: float = float(other.get("y", 0.0)) + (car_size.y + other_size.y) * 0.5 + NPC_SPAWN_MIN_CLEARANCE
			if float(car.get("y", 0.0)) < required_y:
				car["y"] = required_y
				car["previous_y"] = required_y
				if str(car.get("spawn_origin", "MAIN")) == "MAIN":
					car["merge_gate_y"] = required_y
				moved = true


func _physics_process(delta: float) -> void:
	_update_feedback(delta)

	if Input.is_action_just_pressed("restart"):
		reset_run()
		return

	if game_over or run_complete:
		queue_redraw()
		return

	if Input.is_action_just_pressed("pause") and not upgrade_active and not item_replacement_active:
		paused = not paused
		_push_message("已暂停" if paused else "继续游戏", COLOR_INFO, 1.5)

	if paused:
		queue_redraw()
		return

	if item_replacement_active:
		_handle_item_replacement_input()
		queue_redraw()
		return

	if upgrade_active:
		_handle_upgrade_input()
		queue_redraw()
		return

	run_time += delta
	upgrade_cooldown_remaining = maxf(upgrade_cooldown_remaining - delta, 0.0)
	item_cooldown_remaining = maxf(item_cooldown_remaining - delta, 0.0)
	player_collision_cooldown = maxf(player_collision_cooldown - delta, 0.0)
	_update_player(delta)
	road_scroll = fmod(road_scroll + player_speed * PLAYER_SPEED_SCALE * delta, 96.0)
	_update_merge_junctions(delta)
	_update_active_effects(delta)
	_update_hazards(delta)
	_update_loose_props(delta)
	_update_road_events(delta)
	_update_pickups(delta)
	_update_traffic(delta)
	_resolve_hazard_collisions()
	_resolve_npc_collisions(delta)
	_resolve_player_collisions()
	_refresh_traffic_metrics()
	_update_spawn_logic(delta)
	_cleanup_entities()
	_check_upgrade_threshold()

	if run_time >= RUN_LIMIT_SECONDS:
		run_complete = true
		_push_message("本局完成  /  成功撑过 8 分钟", COLOR_ACCENT, 5.0)
		_add_floating_text(Vector2(screen_size.x * 0.5, player_y), "本局完成", COLOR_ACCENT, 2.0)

	queue_redraw()


func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_LEFT])
	_add_key_action("move_right", [KEY_RIGHT])
	_add_key_action("brake", [KEY_DOWN])
	_add_key_action("boost", [KEY_UP])
	_add_key_action("restart", [KEY_R])
	_add_key_action("pause", [KEY_ESCAPE])
	_add_key_action("choose_1", [KEY_1])
	_add_key_action("choose_2", [KEY_2])
	_add_key_action("choose_3", [KEY_3])
	_add_key_action("select_item_1", [KEY_1])
	_add_key_action("select_item_2", [KEY_2])
	_add_key_action("select_item_3", [KEY_3])


func _add_key_action(action_name: String, key_codes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	for key_code in key_codes:
		var event := InputEventKey.new()
		event.keycode = int(key_code)
		event.physical_keycode = int(key_code)
		InputMap.action_add_event(action_name, event)


func _update_player(delta: float) -> void:
	previous_player_x = player_x
	_handle_item_selection()
	var steer_input: float = Input.get_axis("move_left", "move_right")
	player_steer = move_toward(player_steer, steer_input, 7.0 * delta)
	var snake_offset: float = sin(run_time * 3.2) * 18.0 if _has_item("SNAKE SWERVE") else 0.0
	player_x += player_steer * 430.0 * delta + snake_offset * delta
	var margin: float = _player_body_size().x * 0.5
	player_x = clampf(player_x, road_left + margin, road_left + road_width - margin)
	var new_player_lane: int = _nearest_lane(player_x)
	if new_player_lane != player_lane:
		previous_player_lane = player_lane
		player_lane = new_player_lane
		lane_change_cooldown = 0.0
		if _has_item("OVERLOADED RACK"):
			_drop_random_furniture(player_x, player_y + 112.0, 1 if rng.randf() < 0.7 else 2)
			_register_event("行李架超载  /  变道掉东西", 42, Vector2(player_x, player_y + 90.0), COLOR_WARNING)
	else:
		lane_change_cooldown = maxf(lane_change_cooldown - delta, 0.0)

	var target_speed: float = 40.0
	if Input.is_action_pressed("brake"):
		target_speed = 30.0
	elif Input.is_action_pressed("boost"):
		target_speed = 50.0
	if _has_item("SLOW MODE"):
		if Input.is_action_pressed("brake"):
			target_speed = 28.0
		elif Input.is_action_pressed("boost"):
			target_speed = 42.0
		else:
			target_speed = 32.0
	player_speed = move_toward(player_speed, target_speed, 30.0 * delta)
	if Input.is_action_just_pressed("brake") and _has_item("BROKEN TRUNK"):
		if rng.randf() < 0.55:
			_drop_random_furniture(player_x, player_y + 116.0, 1)
			_register_event("后备箱失控  /  家具飞出", 58, Vector2(player_x, player_y + 100.0), COLOR_WARNING)

func _spawn_traffic(kind: String, lane: int, y: float, speed: float, aggressive: bool, driver_type: String = "", spawn_origin: String = "MAIN") -> void:
	var resolved_driver_type: String = driver_type
	if resolved_driver_type.is_empty():
		resolved_driver_type = "AGGRESSIVE" if aggressive else ("CAUTIOUS" if rng.randf() < 0.32 else "NORMAL")
	var is_aggressive: bool = resolved_driver_type == "AGGRESSIVE"
	var resolved_lane: int = clampi(lane, 0, LANE_COUNT - 1)
	var is_merge_spawn: bool = spawn_origin == "MERGE"
	var divider_side: int = _choose_divider_side(resolved_lane)
	var cruise_offset: float = _driver_cruise_offset(resolved_driver_type, divider_side)
	var initial_x: float = _clamp_car_center_x(_lane_x(resolved_lane) + cruise_offset * lane_width, _car_dimensions(kind).x)
	var palette: Color = Color("#60a5fa")
	match kind:
		"SEDAN":
			palette = Color("#ff7a90") if is_aggressive else Color("#60a5fa")
		"SUV":
			palette = Color("#b794f4")
		"VAN":
			palette = Color("#f6c85f")
		"TRUCK":
			palette = Color("#8bd3a8")
		"PICKUP":
			palette = Color("#e8a36a")
		"BUS":
			palette = Color("#e77acb")

	var car: Dictionary = {
		"id": next_car_id,
		"kind": kind,
		"lane": resolved_lane,
		"target_lane": resolved_lane,
		"previous_lane": -1,
		"overtake_hops": 0,
		"route_plan": [],
		"route_index": 0,
		"maneuver_reason": "",
		"replan_cooldown": 0.0,
		"lane_change_commit_timer": 0.0,
		"lane_reservation": -1,
		"lane_reservation_timer": 0.0,
		"x": initial_x,
		"previous_x": initial_x,
		"lateral_target_x": initial_x,
		"divider_side": divider_side,
		"cruise_offset": cruise_offset,
		"wander_phase": rng.randf_range(0.0, TAU),
		"y": y,
		"previous_y": y,
		"speed": speed,
		"previous_speed": speed,
		"base_speed": speed,
		"speed_command": speed,
		"brake_reason": "",
		"speed_shock_target": -1.0,
		"speed_shock_timer": 0.0,
		"speed_shock_memory_timer": 0.0,
		"speed_shock_source": "",
		"speed_shock_latched": false,
		"follow_front_id": -1,
		"follow_front_speed_seen": speed,
		"follow_reaction_timer": 0.0,
		"aggressive": is_aggressive,
		"driver_type": resolved_driver_type,
		"spawn_origin": spawn_origin,
		"merge_side": 0,
		"merge_target_lane": resolved_lane,
		"merge_junction_id": -1,
		"merge_phase": "CRUISE",
		"merge_entry_x": _lane_x(resolved_lane),
		"merge_gate_y": y,
		"merge_start_y": y,
		"merge_progress": 0.0 if is_merge_spawn else 1.0,
		"merge_elapsed": 0.0,
		"merge_duration": 0.0,
		"merge_flow_offset": 0.0,
		"merge_exit_attached": false,
		"initial_behind": y > player_y,
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
		"indicator_clock": rng.randf_range(0.0, 0.7),
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
		"merge_exit_speed": player_speed,
		"merge_exit_cruise_offset": 0.0,
		"merge_exit_offset_pending": false,
		"merge_exit_clear_y": y,
		"merge_flow_floor": 0.0,
		"opening_grace_remaining": 0.0,
		"ai_decision_timer": 0.0,
		"color": palette,
	}
	next_car_id += 1
	traffic.append(car)
	var safe_initial_x: float = _safe_cruise_target_x(car, initial_x, resolved_lane)
	car["x"] = safe_initial_x
	car["previous_x"] = safe_initial_x
	car["lateral_target_x"] = safe_initial_x


## 返回当前车道左右两侧仍在道路内的相邻车道。
func _adjacent_lanes(current_lane: int) -> Array[int]:
	var candidates: Array[int] = []
	if current_lane > 0:
		candidates.append(current_lane - 1)
	if current_lane < LANE_COUNT - 1:
		candidates.append(current_lane + 1)
	return candidates


## 估算车辆从当前位置横向移动到目标点所需的时间，用于提前判断路线是否来得及完成。
func _estimate_lateral_travel_time(car: Dictionary, target_x: float) -> float:
	var driver_type: String = str(car.get("driver_type", "NORMAL"))
	var profile: Dictionary = _driver_profile(driver_type)
	var lateral_speed: float = maxf(float(profile.get("lateral_speed", 120.0)), 1.0)
	var state: String = str(car.get("state", "CRUISE"))
	if state == "PREPARE OVERTAKE":
		lateral_speed *= 0.85
	return absf(target_x - float(car.get("x", target_x))) / lateral_speed


## 返回车辆在同一物理帧内的决策优先级，让即将遇到障碍的车辆先占用安全空隙。
func _traffic_decision_priority(car: Dictionary, snapshot: Array = []) -> int:
	if bool(car.get("crashed", false)):
		return -100000
	var priority: int = 0
	var state: String = str(car.get("state", "CRUISE"))
	if state == "LANE CHANGE" or state == "AVOID" or state == "PASS PLAYER":
		priority += 120
	elif state == "PREPARE OVERTAKE":
		priority += 90
	elif state == "MERGING":
		priority += 70
	if str(car.get("driver_type", "NORMAL")) == "AGGRESSIVE":
		priority += 20
	if _obstacle_in_lane_ahead(car):
		priority += 420
	var front_vehicle: Dictionary = _front_vehicle_for_car(car, snapshot)
	if not front_vehicle.is_empty():
		var front_clearance: float = _vehicle_clearance(
			float(car.get("y", 0.0)),
			str(car.get("kind", "SEDAN")),
			float(front_vehicle.get("y", 0.0)),
			str(front_vehicle.get("kind", "SEDAN"))
		)
		if front_clearance < _traffic_required_clearance(car, front_vehicle):
			priority += 240
	priority += int(clampf(520.0 - float(car.get("y", 0.0)), -120.0, 220.0) * 0.1)
	return priority


## 按变道紧迫度生成本物理帧的处理顺序，减少多辆车同时抢同一条路线。
func _traffic_processing_order(snapshot: Array = []) -> Array[int]:
	var remaining: Array[int] = []
	var deferred: Array[int] = []
	var priorities: Dictionary = {}
	for index in range(traffic.size()):
		var car: Dictionary = traffic[index]
		if not _traffic_requires_full_ai(car):
			deferred.append(index)
			continue
		remaining.append(index)
		priorities[index] = _traffic_decision_priority(traffic[index], snapshot)
	var order: Array[int] = []
	while not remaining.is_empty():
		var best_position: int = 0
		var best_priority: int = -100001
		for position in range(remaining.size()):
			var candidate_index: int = remaining[position]
			var candidate_priority: int = int(priorities.get(candidate_index, -100000))
			if candidate_priority > best_priority:
				best_priority = candidate_priority
			best_position = position
		order.append(remaining[best_position])
		remaining.remove_at(best_position)
	order.append_array(deferred)
	return order


## 判断其他 NPC 是否已经预约了候选车道的横向扫掠空间，避免同一空隙被同时抢占。
func _lateral_path_is_reserved(car: Dictionary, candidate_lane: int, candidate_x: float) -> bool:
	var car_id: int = int(car.get("id", -1))
	var car_y: float = float(car.get("y", 0.0))
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	for other in traffic:
		if int(other.get("id", -2)) == car_id or bool(other.get("crashed", false)):
			continue
		var other_state: String = str(other.get("state", "CRUISE"))
		if other_state != "PREPARE OVERTAKE" and other_state != "LANE CHANGE" and other_state != "AVOID" and other_state != "PASS PLAYER" and other_state != "MERGING":
			continue
		if int(other.get("lane_reservation", -1)) != candidate_lane and int(other.get("target_lane", -1)) != candidate_lane:
			continue
		var other_y: float = float(other.get("y", 0.0))
		var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
		var vertical_limit: float = (car_size.y + other_size.y) * 0.5 + NPC_LANE_RESERVATION_PADDING
		if absf(car_y - other_y) > vertical_limit:
			continue
		if _horizontal_path_overlap(car, other, candidate_x, NPC_LANE_RESERVATION_PADDING):
			return true
	return false


## 为车辆提交一段短暂的横向路线预约，提交失败时由上层重新选择或等待。
func _claim_lateral_reservation(car: Dictionary, candidate_lane: int, candidate_x: float) -> bool:
	if _lateral_path_is_reserved(car, candidate_lane, candidate_x):
		return false
	car["lane_reservation"] = candidate_lane
	car["lane_reservation_timer"] = NPC_LANE_RESERVATION_DURATION
	return true


## 判断超车目标点是否已经离开玩家车身的横向范围，决定是否继续下一次相邻变道。
func _overtake_target_clears_player(car: Dictionary, target_x: float, target_lane: int = -1) -> bool:
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var player_size: Vector2 = _player_body_size()
	var resolved_target_lane: int = target_lane if target_lane >= 0 else _nearest_lane(target_x)
	var player_lane_at_target: int = _nearest_lane(player_x)
	var car_y: float = float(car.get("y", player_y))
	if resolved_target_lane == player_lane_at_target and car_y > player_y:
		var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
		var player_lane_horizon: float = maxf(float(profile["overtake_trigger_distance"]), 260.0) + float(profile["follow_gap"]) + 80.0
		if car_y - player_y < player_lane_horizon:
			return false
	if not _horizontal_overlap(target_x, car_size.x, player_x, player_size.x, PLAYER_LATERAL_CLEARANCE):
		return true
	var safe_depth: float = (car_size.y + player_size.y) * 0.5 + PLAYER_REAR_BUFFER
	return car_y < player_y - safe_depth


## 为激进司机搜索最多四次相邻变道的可行路线，实际行驶仍按路线中的下一跳执行。
func _plan_overtake_route(car: Dictionary, snapshot: Array = []) -> Array[int]:
	var current_lane: int = int(car.get("lane", 0))
	var driver_type: String = str(car.get("driver_type", "NORMAL"))
	var max_hops: int = MAX_OVERTAKE_HOPS if driver_type == "AGGRESSIVE" else 1
	var start_node: Dictionary = {
		"lane": current_lane,
		"x": float(car.get("x", _lane_x(current_lane))),
		"previous_lane": int(car.get("previous_lane", -1)),
		"path": [],
		"score": 0.0,
	}
	var frontier: Array[Dictionary] = [start_node]
	var best_fallback_path: Array[int] = []
	var best_fallback_score: float = -INF
	var best_fallback_preference: int = -1
	for depth in range(max_hops):
		var next_frontier: Array[Dictionary] = []
		var best_goal_path_at_depth: Array[int] = []
		var best_goal_score_at_depth: float = -INF
		var best_goal_preference_at_depth: int = -1
		for node in frontier:
			var node_lane: int = int(node["lane"])
			var node_path: Array = node["path"]
			for candidate_lane in _adjacent_lanes(node_lane):
				if depth > 0 and candidate_lane == int(node["previous_lane"]):
					continue
				var probe: Dictionary = car.duplicate(true)
				probe["lane"] = node_lane
				probe["x"] = float(node["x"])
				probe["lateral_target_x"] = float(node["x"])
				probe["previous_lane"] = int(node["previous_lane"])
				probe["overtake_hops"] = int(car.get("overtake_hops", 0)) + depth
				probe["lane_reservation"] = -1
				probe["route_plan"] = node_path.duplicate()
				probe["route_index"] = node_path.size()
				var lane_score: float = _overtake_lane_score(probe, candidate_lane, snapshot)
				if lane_score <= -100000000.0:
					continue
				var path: Array[int] = []
				for node_lane_value in node_path:
					path.append(int(node_lane_value))
				path.append(candidate_lane)
				var candidate_x: float = _overtake_target_x(probe, candidate_lane)
				var clears_player: bool = _overtake_target_clears_player(probe, candidate_x, candidate_lane)
				var normalized_score: float = minf(lane_score, 1600.0)
				var total_score: float = float(node["score"]) + normalized_score - float(depth) * 45.0
				var path_preference: int = 0
				if not path.is_empty() and int(path[0]) - current_lane == int(car.get("divider_side", 0)):
					path_preference = 1
				if path.size() == 1 and total_score > best_fallback_score:
					if clears_player or candidate_lane != _nearest_lane(player_x):
						best_fallback_score = total_score
						best_fallback_path = path.duplicate()
						best_fallback_preference = path_preference
				elif path.size() == 1 and absf(total_score - best_fallback_score) <= 0.001 and path_preference > best_fallback_preference:
					if clears_player or candidate_lane != _nearest_lane(player_x):
						best_fallback_path = path.duplicate()
						best_fallback_preference = path_preference
				if clears_player and (
					total_score > best_goal_score_at_depth
					or (absf(total_score - best_goal_score_at_depth) <= 0.001 and path_preference > best_goal_preference_at_depth)
				):
					best_goal_score_at_depth = total_score
					best_goal_path_at_depth = path.duplicate()
					best_goal_preference_at_depth = path_preference
				if path.size() < max_hops and not clears_player:
					next_frontier.append({
						"lane": candidate_lane,
						"x": candidate_x,
						"previous_lane": node_lane,
						"path": path,
						"score": total_score,
					})
		if not best_goal_path_at_depth.is_empty():
			return best_goal_path_at_depth
		frontier = next_frontier
		if frontier.is_empty():
			break
	return best_fallback_path


## 判断两个横向车身区间是否相交，可选地加入换道安全余量。
func _horizontal_overlap(first_x: float, first_width: float, second_x: float, second_width: float, padding: float = 0.0) -> bool:
	return absf(first_x - second_x) < (first_width + second_width) * 0.5 + padding


## 计算车辆与玩家之间按真实车身高度得到的纵向安全距离。
func _player_rear_safe_y(car: Dictionary) -> float:
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var player_size: Vector2 = _player_body_size()
	return player_y + (car_size.y + player_size.y) * 0.5 + PLAYER_REAR_BUFFER


## 判断车辆的横向目标是否会进入玩家车身的安全区域。
func _player_target_is_safe(car: Dictionary, target_x: float) -> bool:
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var player_size: Vector2 = _player_body_size()
	var player_path_left: float = minf(previous_player_x, player_x) - player_size.x * 0.5
	var player_path_right: float = maxf(previous_player_x, player_x) + player_size.x * 0.5
	var car_x: float = float(car.get("x", target_x))
	var car_y: float = float(car.get("y", player_y))
	if car_y > player_y:
		var swept_left: float = minf(car_x, target_x) - car_size.x * 0.5
		var swept_right: float = maxf(car_x, target_x) + car_size.x * 0.5
		if swept_right > player_path_left and swept_left < player_path_right:
			var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
			var travel_time: float = _estimate_lateral_travel_time(car, target_x)
			var closing_speed: float = maxf(float(car.get("speed", player_speed)) - player_speed, 0.0)
			var closing_distance: float = closing_speed * PLAYER_SPEED_SCALE * travel_time
			var swept_safe_depth: float = (car_size.y + player_size.y) * 0.5 + PLAYER_LATERAL_CLEARANCE
			if car_y - player_y < swept_safe_depth + closing_distance:
				return false
	var target_left: float = target_x - car_size.x * 0.5
	var target_right: float = target_x + car_size.x * 0.5
	if target_right <= player_path_left or target_left >= player_path_right:
		return true
	var safe_depth: float = (car_size.y + player_size.y) * 0.5 + PLAYER_REAR_BUFFER
	return absf(float(car.get("y", player_y)) - player_y) >= safe_depth


## 生成不会侵入玩家车身的超车目标点，优先保留司机的压线偏好。
func _overtake_target_x(car: Dictionary, target_lane: int) -> float:
	var kind: String = str(car.get("kind", "SEDAN"))
	var car_size: Vector2 = _car_dimensions(kind)
	var target_x: float = _lane_target_x(car, target_lane)
	var player_size: Vector2 = _player_body_size()
	var safe_depth: float = (car_size.y + player_size.y) * 0.5 + PLAYER_REAR_BUFFER
	if absf(float(car.get("y", player_y)) - player_y) < safe_depth and _horizontal_overlap(target_x, car_size.x, player_x, player_size.x):
		var direction: float = -1.0 if target_x < player_x else 1.0
		if is_zero_approx(target_x - player_x):
			direction = -1.0 if target_lane < _nearest_lane(player_x) else 1.0
		target_x = player_x + direction * ((car_size.x + player_size.x) * 0.5 + PLAYER_LATERAL_CLEARANCE)
	return _clamp_car_center_x(target_x, car_size.x)


## 根据障碍物的纵向接近时间，返回车辆横向扫掠路径上的采样位置。
func _path_x_at_time(car: Dictionary, candidate_x: float, obstacle_y: float) -> float:
	var start_x: float = float(car.get("x", candidate_x))
	var travel_time: float = _estimate_lateral_travel_time(car, candidate_x)
	if travel_time <= 0.001:
		return candidate_x
	var car_speed: float = maxf(float(car.get("speed", player_speed)), 1.0)
	var closing_speed: float = maxf(car_speed * PLAYER_SPEED_SCALE, 1.0)
	var gap: float = maxf(float(car.get("y", obstacle_y)) - obstacle_y, 0.0)
	var obstacle_time: float = gap / closing_speed
	return lerpf(start_x, candidate_x, clampf(obstacle_time / travel_time, 0.0, 1.0))


## 检查候选横向目标和实际扫掠路径上的道路障碍、事件和路边危险物。
func _overtake_route_is_clear(car: Dictionary, candidate_lane: int, candidate_x: float, look_ahead: float) -> bool:
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var car_y: float = float(car.get("y", 0.0))
	for hazard in hazards:
		if not bool(hazard.get("active", true)) or not bool(hazard.get("blocks_route", false)):
			continue
		var gap: float = car_y - float(hazard.get("y", 0.0))
		var hazard_width: float = float(hazard.get("width", lane_width * 0.45))
		var path_x: float = _path_x_at_time(car, candidate_x, float(hazard.get("y", 0.0)))
		if gap > 0.0 and gap < look_ahead and _horizontal_overlap(path_x, car_size.x, float(hazard.get("x", 0.0)), hazard_width, 4.0):
			return false
	for road_event in road_events:
		if not bool(road_event.get("active", true)):
			continue
		var event_gap: float = car_y - float(road_event.get("y", 0.0))
		var event_x: float = _path_x_at_time(car, candidate_x, float(road_event.get("y", 0.0)))
		var event_lane: int = _nearest_lane(event_x)
		if event_gap > 0.0 and event_gap < look_ahead and _road_event_blocks_lane(road_event, event_lane):
			return false
	for prop in loose_props:
		if not bool(prop.get("active", true)) or not bool(prop.get("dangerous", false)):
			continue
		var prop_gap: float = car_y - float(prop.get("y", 0.0))
		var prop_width: float = 40.0 if str(prop.get("type", "")) == "TRASH CAN" else 46.0
		var prop_x: float = _path_x_at_time(car, candidate_x, float(prop.get("y", 0.0)))
		if prop_gap > 0.0 and prop_gap < look_ahead and _horizontal_overlap(prop_x, car_size.x, float(prop.get("x", 0.0)), prop_width, 4.0):
			return false
	var barrier: Vector2 = _moving_barrier_position()
	var barrier_x: float = _path_x_at_time(car, candidate_x, barrier.y)
	if _has_item("MOVING ROADBLOCK") and absf(car_y - barrier.y) < look_ahead and _horizontal_overlap(barrier_x, car_size.x, barrier.x, lane_width * 0.80, 4.0):
		return false
	return true


## 用候选车辆和所有实际车身的前后间距评估一条相邻车道。
func _overtake_lane_score(car: Dictionary, candidate_lane: int, snapshot: Array = []) -> float:
	if candidate_lane < 0 or candidate_lane >= LANE_COUNT:
		return -INF
	var current_lane: int = int(car.get("lane", 0))
	if abs(candidate_lane - current_lane) != 1:
		return -INF
	var previous_lane: int = int(car.get("previous_lane", -1))
	if int(car.get("overtake_hops", 0)) > 0 and candidate_lane == previous_lane and float(car.get("replan_cooldown", 0.0)) > 0.0:
		return -INF
	var candidate_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var candidate_x: float = _overtake_target_x(car, candidate_lane)
	var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
	if not _player_target_is_safe(car, candidate_x):
		return -INF
	if _lateral_path_is_reserved(car, candidate_lane, candidate_x):
		return -INF
	if not _overtake_route_is_clear(car, candidate_lane, candidate_x, maxf(260.0, float(profile["reaction_distance"]) + 140.0)):
		return -INF

	var front_gap: float = INF
	var rear_gap: float = INF
	var front_speed: float = float(car.get("speed", 0.0))
	var rear_speed: float = float(car.get("speed", 0.0))
	var car_y: float = float(car.get("y", 0.0))
	var horizontal_padding: float = float(profile["lane_change_padding"])
	var states: Array = snapshot
	if states.is_empty():
		states = _build_traffic_snapshot()
	for other in states:
		if (bool(other.get("crashed", false)) and float(other.get("crash_time", 0.0)) >= NPC_CRASH_BLOCK_DURATION) or int(other.get("id", -1)) == int(car.get("id", -2)):
			continue
		var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
		if not _horizontal_path_overlap(car, other, candidate_x, horizontal_padding):
			continue
		var other_y: float = float(other.get("y", 0.0))
		var clear_distance: float = absf(car_y - other_y) - (candidate_size.y + other_size.y) * 0.5
		if other_y < car_y:
			if clear_distance < front_gap:
				front_gap = clear_distance
				front_speed = float(other.get("speed", front_speed))
		else:
			if clear_distance < rear_gap:
				rear_gap = clear_distance
				rear_speed = float(other.get("speed", rear_speed))

	var lateral_time: float = _estimate_lateral_travel_time(car, candidate_x)
	var front_relative_speed: float = maxf(float(car.get("speed", 0.0)) - front_speed, 0.0)
	var rear_required_speed: float = maxf(rear_speed - float(car.get("speed", 0.0)), 0.0)
	var front_required: float = float(profile["follow_gap"]) + candidate_size.y * 0.16 + horizontal_padding + front_relative_speed * PLAYER_SPEED_SCALE * lateral_time * 0.35
	var rear_required: float = float(profile["follow_gap"]) * 0.58 + candidate_size.y * 0.12 + horizontal_padding + maxf(rear_required_speed, 0.0) * PLAYER_SPEED_SCALE * lateral_time * 0.55
	if front_gap < front_required or rear_gap < rear_required:
		return -INF
	var usable_gap: float = minf(front_gap, rear_gap)
	var lane_score: float = 100000.0 if is_inf(usable_gap) else usable_gap + minf(front_gap, 420.0) * 0.15 + minf(rear_gap, 300.0) * 0.08
	var fake_turn: Dictionary = _active_effect_data("FAKE TURN SIGNAL")
	var signal_side: int = int(fake_turn.get("side", 0))
	if signal_side != 0 and candidate_lane == current_lane + signal_side:
		lane_score += 36.0 if str(car.get("driver_type", "NORMAL")) != "AGGRESSIVE" else 8.0
	if candidate_lane - current_lane == int(car.get("divider_side", 0)):
		lane_score += 0.5
	return lane_score


## 选择完整安全路线中的下一条相邻车道，非激进司机仍只提交一跳。
func _choose_overtake_lane(car: Dictionary, snapshot: Array = []) -> int:
	var route: Array[int] = _plan_overtake_route(car, snapshot)
	if route.is_empty():
		return -1
	return int(route[0])


## 开始或重新开始一次超车路段，没有空隙时进入 Blocked 等待下一次检查。
func _start_overtake_attempt(car: Dictionary, snapshot: Array = []) -> bool:
	var current_lane: int = int(car.get("lane", 0))
	var route: Array[int] = _plan_overtake_route(car, snapshot)
	var target_lane: int = -1 if route.is_empty() else int(route[0])
	car["attempted_pass"] = true
	car["block_timer"] = 0.0
	car["route_plan"] = route
	car["route_index"] = 0
	if target_lane < 0:
		car["target_lane"] = current_lane
		car["indicator"] = 0
		car["state"] = "BLOCKED"
		car["maneuver_reason"] = "BLOCKED_ROUTE"
		var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
		car["wait_timer"] = rng.randf_range(float(profile["wait_min"]), float(profile["wait_max"]))
		return false
	if not _claim_lateral_reservation(car, target_lane, _overtake_target_x(car, target_lane)):
		car["route_plan"] = []
		car["target_lane"] = current_lane
		car["indicator"] = 0
		car["state"] = "BLOCKED"
		car["maneuver_reason"] = "LANE_RESERVED"
		return false
	car["target_lane"] = target_lane
	car["indicator"] = signi(target_lane - current_lane)
	car["state"] = "PREPARE OVERTAKE"
	car["maneuver_reason"] = "OVERTAKE"
	car["replan_cooldown"] = NPC_REPLAN_INTERVAL
	_set_overtake_lateral_target(car, "PREPARE OVERTAKE")
	car["pressure"] = maxf(float(car.get("pressure", 0.0)), 1.0)
	return true


## 在当前目标车道失效时重新寻找相邻空隙，避免强行穿过玩家或其他车辆。
func _retarget_overtake(car: Dictionary, snapshot: Array = []) -> bool:
	var route: Array[int] = _plan_overtake_route(car, snapshot)
	var target_lane: int = -1 if route.is_empty() else int(route[0])
	if target_lane < 0:
		return false
	if not _claim_lateral_reservation(car, target_lane, _overtake_target_x(car, target_lane)):
		return false
	car["route_plan"] = route
	car["route_index"] = 0
	car["target_lane"] = target_lane
	car["indicator"] = signi(target_lane - int(car.get("lane", 0)))
	car["state"] = "PREPARE OVERTAKE"
	car["maneuver_reason"] = "OVERTAKE"
	car["replan_cooldown"] = NPC_REPLAN_INTERVAL
	car["block_timer"] = 0.0
	car["wait_timer"] = 0.0
	_set_overtake_lateral_target(car, "PREPARE OVERTAKE")
	return true


## 完成一条相邻车道变更，激进司机仍有空隙时继续逐道找缝。
func _complete_overtake_segment(car: Dictionary, target_lane: int) -> void:
	var previous_lane: int = int(car.get("lane", 0))
	car["previous_lane"] = previous_lane
	car["lane"] = target_lane
	car["lane_reservation"] = -1
	car["lane_reservation_timer"] = 0.0
	car["overtake_hops"] = int(car.get("overtake_hops", 0)) + 1
	car["route_index"] = int(car.get("route_index", 0)) + 1
	car["block_timer"] = 0.0
	car["wait_timer"] = 0.0
	var driver_type: String = str(car.get("driver_type", "NORMAL"))
	var profile: Dictionary = _driver_profile(driver_type)
	car["pass_burst_timer"] = float(profile["pass_burst_duration"])
	if driver_type == "AGGRESSIVE" and int(car["overtake_hops"]) < MAX_OVERTAKE_HOPS:
		var fresh_snapshot: Array[Dictionary] = _build_traffic_snapshot()
		var current_lane_clear: bool = _overtake_target_clears_player(car, float(car.get("x", _lane_x(target_lane))), target_lane)
		var route_still_blocked: bool = _obstacle_in_lane_ahead(car) or _traffic_ahead_close(-1, car, fresh_snapshot)
		if not current_lane_clear or route_still_blocked:
			if _retarget_overtake(car, fresh_snapshot):
				return
	car["state"] = "PASS PLAYER"
	car["maneuver_reason"] = "PASS_PLAYER"
	_set_overtake_lateral_target(car, "PASS PLAYER")


## 判断车辆是否仍有资格从玩家侧方安全完成超车记录。
func _can_log_safe_pass(car: Dictionary) -> bool:
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var player_size: Vector2 = _player_body_size()
	if _rects_overlap(Vector2(float(car.get("x", 0.0)), float(car.get("y", 0.0))), car_size, Vector2(player_x, player_y), player_size):
		return false
	return not _horizontal_overlap(float(car.get("x", 0.0)), car_size.x, player_x, player_size.x, PLAYER_LATERAL_CLEARANCE)


## 根据超车阶段设置连续横向目标，准备阶段优先靠近车道分隔线。
func _set_overtake_lateral_target(car: Dictionary, phase: String) -> void:
	var current_lane: int = int(car.get("lane", 0))
	var target_lane: int = int(car.get("target_lane", current_lane))
	var kind: String = str(car.get("kind", "SEDAN"))
	if current_lane != target_lane and phase == "PREPARE OVERTAKE":
		var prepare_x: float = _clamp_car_center_x(_lane_boundary_x(current_lane, target_lane), _car_dimensions(kind).x)
		if not _player_target_is_safe(car, prepare_x):
			prepare_x = _overtake_target_x(car, target_lane)
		car["lateral_target_x"] = prepare_x
	else:
		car["lateral_target_x"] = _overtake_target_x(car, target_lane)


## 判断车辆是否已经完成准备超车阶段的横向靠线动作。
func _overtake_prepare_is_ready(car: Dictionary) -> bool:
	var lateral_target_x: float = float(car.get("lateral_target_x", car.get("x", 0.0)))
	return absf(float(car.get("x", lateral_target_x)) - lateral_target_x) <= 8.0


## 在固定物理步内平滑执行车辆横向意图，并保留轻微人格化摆动。
func _apply_lateral_motion(car: Dictionary, delta: float) -> void:
	var driver_type: String = str(car.get("driver_type", "NORMAL"))
	var profile: Dictionary = _driver_profile(driver_type)
	var kind: String = str(car.get("kind", "SEDAN"))
	var current_lane: int = int(car.get("lane", 0))
	var lateral_target_x: float = float(car.get("lateral_target_x", _lane_target_x(car, current_lane)))
	var state: String = str(car.get("state", "CRUISE"))
	var wander_amplitude: float = float(profile["wander_amplitude"])
	if state == "PREPARE OVERTAKE" or state == "LANE CHANGE" or state == "AVOID" or state == "PASS PLAYER":
		wander_amplitude *= 0.35
	var wander_phase: float = float(car.get("wander_phase", 0.0))
	var wander_offset: float = sin(run_time * 1.35 + wander_phase) * wander_amplitude
	var desired_x: float = _clamp_car_center_x(lateral_target_x + wander_offset, _car_dimensions(kind).x)
	if state != "PREPARE OVERTAKE" and state != "LANE CHANGE" and state != "AVOID" and state != "PASS PLAYER" and state != "MERGING":
		desired_x = _safe_cruise_target_x(car, desired_x, current_lane)
	var lateral_speed: float = float(profile["lateral_speed"])
	if state == "PREPARE OVERTAKE":
		lateral_speed *= 0.85
	car["x"] = move_toward(float(car.get("x", _lane_x(current_lane))), desired_x, lateral_speed * delta)
	if float(car.get("slip", 0.0)) > 0.0:
		car["x"] = move_toward(float(car["x"]), float(car["x"]) + float(car.get("x_velocity", 0.0)) * 0.25, delta * 80.0)
	car["x"] = _clamp_car_center_x(float(car["x"]), _car_dimensions(kind).x)


## 返回车辆车身实际覆盖的所有车道，允许压线车辆同时影响两道。
func _lanes_touched_by_car(car: Dictionary) -> Array[int]:
	var kind: String = str(car.get("kind", "SEDAN"))
	var center_x: float = float(car.get("x", _lane_x(int(car.get("lane", 0)))))
	var half_width: float = _car_dimensions(kind).x * 0.5
	var touched: Array[int] = []
	for lane in range(LANE_COUNT):
		var lane_left: float = road_left + float(lane) * lane_width
		var lane_right: float = lane_left + lane_width
		if center_x + half_width > lane_left and center_x - half_width < lane_right:
			touched.append(lane)
	if touched.is_empty():
		touched.append(_nearest_lane(center_x))
	return touched


## 建立本物理步开始时的交通快照，避免车辆按数组顺序互相看到半更新状态。
func _build_traffic_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for car in traffic:
		snapshot.append({
			"id": int(car.get("id", -1)),
			"kind": str(car.get("kind", "SEDAN")),
			"lane": int(car.get("lane", 0)),
			"target_lane": int(car.get("target_lane", car.get("lane", 0))),
			"spawn_origin": str(car.get("spawn_origin", "MAIN")),
			"merge_side": int(car.get("merge_side", 0)),
			"merge_target_lane": int(car.get("merge_target_lane", car.get("target_lane", car.get("lane", 0)))),
			"merge_junction_id": int(car.get("merge_junction_id", -1)),
			"merge_phase": str(car.get("merge_phase", "CRUISE")),
			"merge_start_y": float(car.get("merge_start_y", car.get("y", 0.0))),
			"merge_progress": float(car.get("merge_progress", 1.0)),
			"merge_elapsed": float(car.get("merge_elapsed", 0.0)),
			"merge_duration": float(car.get("merge_duration", 0.0)),
			"merge_flow_offset": float(car.get("merge_flow_offset", 0.0)),
			"route_plan": car.get("route_plan", []),
			"route_index": int(car.get("route_index", 0)),
			"x": float(car.get("x", 0.0)),
			"lateral_target_x": float(car.get("lateral_target_x", car.get("x", 0.0))),
			"y": float(car.get("y", 0.0)),
			"speed": float(car.get("speed", 0.0)),
			"state": str(car.get("state", "CRUISE")),
			"crashed": bool(car.get("crashed", false)),
			"crash_time": float(car.get("crash_time", 0.0)),
			"crash_cause": str(car.get("crash_cause", "")),
			"speed_shock_timer": float(car.get("speed_shock_timer", 0.0)),
			"speed_shock_memory_timer": float(car.get("speed_shock_memory_timer", 0.0)),
			"speed_shock_target": float(car.get("speed_shock_target", -1.0)),
			"speed_shock_source": str(car.get("speed_shock_source", "")),
			"lane_reservation": int(car.get("lane_reservation", -1)),
			"lane_reservation_timer": float(car.get("lane_reservation_timer", 0.0)),
			"maneuver_reason": str(car.get("maneuver_reason", "")),
		})
	return snapshot


## 判断一辆车当前横向目标的扫掠车身是否会进入另一辆车的扫掠车身。
func _horizontal_path_overlap(car: Dictionary, other: Dictionary, candidate_x_override: float = -1.0, padding: float = 0.0) -> bool:
	var car_kind: String = str(car.get("kind", "SEDAN"))
	var other_kind: String = str(other.get("kind", "SEDAN"))
	var car_width: float = _car_dimensions(car_kind).x
	var other_width: float = _car_dimensions(other_kind).x
	var car_start_x: float = float(car.get("x", 0.0))
	var car_end_x: float = float(car.get("lateral_target_x", car_start_x))
	if candidate_x_override >= 0.0:
		car_end_x = candidate_x_override
	var other_start_x: float = float(other.get("x", 0.0))
	var other_end_x: float = float(other.get("lateral_target_x", other_start_x))
	var car_left: float = minf(car_start_x, car_end_x) - car_width * 0.5
	var car_right: float = maxf(car_start_x, car_end_x) + car_width * 0.5
	var other_left: float = minf(other_start_x, other_end_x) - other_width * 0.5
	var other_right: float = maxf(other_start_x, other_end_x) + other_width * 0.5
	return car_right > other_left - padding and car_left < other_right + padding


## 按两辆车的真实车身高度计算后车与前车之间的净纵向距离。
func _vehicle_clearance(rear_y: float, rear_kind: String, front_y: float, front_kind: String) -> float:
	var rear_size: Vector2 = _car_dimensions(rear_kind)
	var front_size: Vector2 = _car_dimensions(front_kind)
	return rear_y - front_y - (rear_size.y + front_size.y) * 0.5


## 返回当前横向路径上最近的前车，短时间内的事故车辆仍会占用道路。
func _front_vehicle_for_car(car: Dictionary, snapshot: Array = []) -> Dictionary:
	var states: Array = snapshot
	if states.is_empty():
		states = _build_traffic_snapshot()
	var car_id: int = int(car.get("id", -1))
	var car_y: float = float(car.get("y", 0.0))
	var nearest_distance: float = INF
	var front_vehicle: Dictionary = {}
	for other in states:
		if int(other.get("id", -2)) == car_id:
			continue
		if bool(other.get("crashed", false)) and float(other.get("crash_time", 0.0)) >= NPC_CRASH_BLOCK_DURATION:
			continue
		var other_y: float = float(other.get("y", 0.0))
		if other_y >= car_y:
			continue
		if not _horizontal_path_overlap(car, other, -1.0, 0.0):
			continue
		var distance: float = car_y - other_y
		if distance < nearest_distance:
			nearest_distance = distance
			front_vehicle = other
	return front_vehicle


## 返回事故车辆或正常前车在本规则中的有效速度。
func _front_vehicle_speed(front_vehicle: Dictionary) -> float:
	return 0.0 if bool(front_vehicle.get("crashed", false)) else float(front_vehicle.get("speed", 0.0))


## 按司机反应时间、相对速度和统一刹车减速度计算所需安全净距。
func _traffic_required_clearance(car: Dictionary, front_vehicle: Dictionary) -> float:
	var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
	var front_speed: float = _front_vehicle_speed(front_vehicle)
	var relative_speed: float = maxf(float(car.get("speed", 0.0)) - front_speed, 0.0)
	var reaction_distance: float = relative_speed * PLAYER_SPEED_SCALE * float(profile.get("reaction_time", 0.30))
	var braking_distance: float = relative_speed * relative_speed / (2.0 * NPC_BRAKE_DECELERATION) * PLAYER_SPEED_SCALE
	return float(profile["follow_gap"]) + NPC_BODY_BUFFER + reaction_distance + braking_distance


## 记录前车速度突变并返回当前司机是否仍处于反应时间内。
func _update_follow_reaction(car: Dictionary, front_vehicle: Dictionary, delta: float) -> bool:
	var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
	var front_id: int = int(front_vehicle.get("id", -1))
	var front_speed: float = _front_vehicle_speed(front_vehicle)
	var alert_speed: float = front_speed
	var shock_target: float = float(front_vehicle.get("speed_shock_target", -1.0))
	if shock_target >= 0.0 and (float(front_vehicle.get("speed_shock_timer", 0.0)) > 0.0 or float(front_vehicle.get("speed_shock_memory_timer", 0.0)) > 0.0):
		alert_speed = minf(alert_speed, shock_target)
	var previous_front_id: int = int(car.get("follow_front_id", -1))
	var previous_seen_speed: float = float(car.get("follow_front_speed_seen", alert_speed))
	if front_id != previous_front_id:
		car["follow_front_id"] = front_id
		car["follow_front_speed_seen"] = alert_speed
		car["follow_reaction_timer"] = float(profile.get("reaction_time", 0.30)) if alert_speed < front_speed - 0.5 else 0.0
	elif alert_speed < previous_seen_speed - 1.0:
		car["follow_front_speed_seen"] = alert_speed
		car["follow_reaction_timer"] = maxf(float(car.get("follow_reaction_timer", 0.0)), float(profile.get("reaction_time", 0.30)))
	else:
		car["follow_front_speed_seen"] = alert_speed
	car["follow_reaction_timer"] = maxf(float(car.get("follow_reaction_timer", 0.0)) - delta, 0.0)
	return float(car.get("follow_reaction_timer", 0.0)) > 0.0


## 将实际前后净距换算成后车允许的最高跟车速度。
func _traffic_follow_speed_limit(car: Dictionary, snapshot: Array = [], delta: float = 1.0 / 60.0) -> float:
	var front_vehicle: Dictionary = _front_vehicle_for_car(car, snapshot)
	if front_vehicle.is_empty():
		car["follow_front_id"] = -1
		car["follow_reaction_timer"] = 0.0
		return INF
	var car_y: float = float(car.get("y", 0.0))
	var front_y: float = float(front_vehicle.get("y", car_y))
	var clearance: float = _vehicle_clearance(car_y, str(car.get("kind", "SEDAN")), front_y, str(front_vehicle.get("kind", "SEDAN")))
	var in_reaction_time: bool = _update_follow_reaction(car, front_vehicle, delta)
	var shock_active: bool = float(front_vehicle.get("speed_shock_memory_timer", 0.0)) > 0.0 or not str(front_vehicle.get("speed_shock_source", "")).is_empty()
	if in_reaction_time and shock_active and clearance > 0.0:
		return INF
	var required_clearance: float = _traffic_required_clearance(car, front_vehicle)
	if clearance >= required_clearance:
		return INF
	var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
	var available_braking_gap: float = maxf(clearance - float(profile["follow_gap"]) - NPC_BODY_BUFFER, 0.0)
	var relative_speed_limit: float = sqrt(available_braking_gap * 2.0 * NPC_BRAKE_DECELERATION / PLAYER_SPEED_SCALE)
	var gap_deficit: float = maxf(required_clearance - clearance, 0.0)
	var gap_recovery_speed: float = clampf(gap_deficit * 0.14, 0.0, NPC_FOLLOW_GAP_RECOVERY_MAX)
	# 这里只返回安全上限，不把车辆当前的低速锁死；实际加速仍由固定物理帧中的加速度推进。
	# 净距已经不足时，短暂低于前车速度来恢复距离，避免“同速贴车”长期锁死。
	return maxf(_front_vehicle_speed(front_vehicle) + relative_speed_limit - gap_recovery_speed, 0.0)


## 判断车辆是否还在等待对玩家道具造成的前车突减做出反应。
func _is_following_shock_reaction(car: Dictionary, snapshot: Array = []) -> bool:
	var front_vehicle: Dictionary = _front_vehicle_for_car(car, snapshot)
	if front_vehicle.is_empty() or float(car.get("follow_reaction_timer", 0.0)) <= 0.0:
		return false
	return float(front_vehicle.get("speed_shock_memory_timer", 0.0)) > 0.0 or not str(front_vehicle.get("speed_shock_source", "")).is_empty()


## 预测当前物理步后的纵向位置，车辆能及时刹车时把车身夹回前车安全距离。
func _clamp_npc_next_y(car: Dictionary, next_y: float, delta: float, snapshot: Array) -> float:
	var front_vehicle: Dictionary = _front_vehicle_for_car(car, snapshot)
	if front_vehicle.is_empty():
		return next_y
	var front_y: float = float(front_vehicle.get("y", 0.0))
	var front_speed: float = _front_vehicle_speed(front_vehicle)
	var front_next_y: float = front_y + (player_speed - front_speed) * PLAYER_SPEED_SCALE * delta
	var safe_y: float = front_next_y + (_car_dimensions(str(car.get("kind", "SEDAN"))).y + _car_dimensions(str(front_vehicle.get("kind", "SEDAN"))).y) * 0.5 + NPC_CONTACT_SEPARATION
	if next_y >= safe_y:
		return next_y
	var current_clearance: float = _vehicle_clearance(float(car.get("y", 0.0)), str(car.get("kind", "SEDAN")), front_y, str(front_vehicle.get("kind", "SEDAN")))
	var relative_speed: float = maxf(float(car.get("speed", 0.0)) - front_speed, 0.0)
	var braking_distance: float = relative_speed * relative_speed / (2.0 * NPC_BRAKE_DECELERATION) * PLAYER_SPEED_SCALE
	var shock_active: bool = float(front_vehicle.get("speed_shock_memory_timer", 0.0)) > 0.0 or not str(front_vehicle.get("speed_shock_source", "")).is_empty()
	var crash_disruption: bool = str(front_vehicle.get("crash_cause", "")) in ["PLAYER_ITEM_CHAIN", "ENVIRONMENT", "PLAYER_SIDE_COLLISION"]
	if shock_active and current_clearance > 0.0 and float(car.get("follow_reaction_timer", 0.0)) > 0.0:
		return next_y
	if current_clearance >= braking_distance + NPC_BODY_BUFFER or not (shock_active or crash_disruption):
		car["speed"] = minf(float(car.get("speed", player_speed)), front_speed)
		car["brake_reason"] = "FOLLOW"
		return safe_y
	return next_y


func _update_traffic(delta: float) -> void:
	for car in traffic:
		car["previous_x"] = float(car.get("x", 0.0))
		car["previous_y"] = float(car.get("y", 0.0))
		car["previous_speed"] = float(car.get("speed", 0.0))
		car["lane_reservation_timer"] = maxf(float(car.get("lane_reservation_timer", 0.0)) - delta, 0.0)
		car["opening_grace_remaining"] = maxf(float(car.get("opening_grace_remaining", 0.0)) - delta, 0.0)
		car["ai_decision_timer"] = maxf(float(car.get("ai_decision_timer", 0.0)) - delta, 0.0)
		if float(car.get("lane_reservation_timer", 0.0)) <= 0.0:
			car["lane_reservation"] = -1
		if not bool(car.get("crashed", false)):
			_apply_signal_pressure(car, int(car.get("lane", 0)), float(car.get("y", player_y)))
	var traffic_snapshot: Array[Dictionary] = _build_traffic_snapshot()
	merge_yield_probe_timer = maxf(merge_yield_probe_timer - delta, 0.0)
	if merge_yield_probe_timer <= 0.0:
		_plan_merge_yield_request(traffic_snapshot)
	for car in traffic:
		if bool(car.get("crashed", false)):
			continue
		var committed_state: String = str(car.get("state", "CRUISE"))
		var committed_lane: int = int(car.get("target_lane", car.get("lane", 0)))
		if committed_lane != int(car.get("lane", 0)) and (committed_state == "PREPARE OVERTAKE" or committed_state == "LANE CHANGE" or committed_state == "AVOID" or committed_state == "PASS PLAYER" or committed_state == "MERGING"):
			car["lane_reservation"] = committed_lane
			car["lane_reservation_timer"] = maxf(float(car.get("lane_reservation_timer", 0.0)), NPC_LANE_RESERVATION_DURATION)
	for i in _traffic_processing_order(traffic_snapshot):
		var car: Dictionary = traffic[i]
		if bool(car["crashed"]):
			car["crash_time"] = float(car["crash_time"]) + delta
			car["spin_angle"] = float(car["spin_angle"]) + float(car["spin_speed"]) * delta
			car["x"] = float(car["x"]) + float(car["x_velocity"]) * delta
			car["x_velocity"] = move_toward(float(car["x_velocity"]), 0.0, 90.0 * delta)
			car["y"] = float(car["y"]) + player_speed * PLAYER_SPEED_SCALE * delta
			continue
		if not _traffic_requires_full_ai(car):
			traffic_ai_lod_updates += 1
			_advance_distant_traffic(car, delta)
			continue
		traffic_ai_full_updates += 1
		if str(car.get("state", "")) == "MERGE APPROACH" or str(car.get("state", "")) == "MERGING" or str(car.get("state", "")) == "MERGE WAIT":
			_update_merge_traffic(car, delta, traffic_snapshot)
			continue

		car["pressure"] = maxf(float(car["pressure"]) - delta, 0.0)
		car["indicator_clock"] = float(car["indicator_clock"]) + delta
		car["slip"] = maxf(float(car["slip"]) - delta, 0.0)
		car["hazard_cooldown"] = maxf(float(car.get("hazard_cooldown", 0.0)) - delta, 0.0)
		car["player_avoid_timer"] = maxf(float(car.get("player_avoid_timer", 0.0)) - delta, 0.0)
		car["contact_cooldown"] = maxf(float(car.get("contact_cooldown", 0.0)) - delta, 0.0)
		car["replan_cooldown"] = maxf(float(car.get("replan_cooldown", 0.0)) - delta, 0.0)
		car["lane_change_commit_timer"] = maxf(float(car.get("lane_change_commit_timer", 0.0)) - delta, 0.0)
		car["speed_shock_timer"] = maxf(float(car.get("speed_shock_timer", 0.0)) - delta, 0.0)
		car["speed_shock_memory_timer"] = maxf(float(car.get("speed_shock_memory_timer", 0.0)) - delta, 0.0)
		car["merge_exit_timer"] = maxf(float(car.get("merge_exit_timer", 0.0)) - delta, 0.0)
		if float(car.get("speed_shock_timer", 0.0)) <= 0.0:
			car["speed_shock_target"] = -1.0
		if float(car.get("speed_shock_memory_timer", 0.0)) <= 0.0:
			car["speed_shock_source"] = ""
		var y: float = float(car["y"])
		var current_lane: int = int(car["lane"])
		if bool(car.get("merge_exit_offset_pending", false)) and (
			y < float(car.get("merge_exit_clear_y", y)) or float(car.get("merge_exit_timer", 0.0)) <= 0.0
		):
			car["cruise_offset"] = float(car.get("merge_exit_cruise_offset", 0.0))
			car["merge_exit_offset_pending"] = false
			_set_lateral_target(car, current_lane)
		var desired_speed: float = float(car["base_speed"])
		car["brake_reason"] = ""
		var driver_type: String = str(car.get("driver_type", "NORMAL"))
		var profile: Dictionary = _driver_profile(driver_type)

		var state: String = str(car["state"])
		var approach_gap: float = y - player_y
		var overtake_trigger_distance: float = float(profile["overtake_trigger_distance"])
		var obstacle_close: bool = _obstacle_in_lane_ahead(car, float(profile["reaction_distance"]))
		var traffic_ahead: bool = _traffic_ahead_close(i, car, traffic_snapshot)
		var front_vehicle: Dictionary = _front_vehicle_for_car(car, traffic_snapshot)
		var front_speed: float = _front_vehicle_speed(front_vehicle)
		var slow_front: bool = not front_vehicle.is_empty() and float(car.get("base_speed", 0.0)) - front_speed > 3.0
		var front_clearance: float = INF
		if not front_vehicle.is_empty():
			front_clearance = _vehicle_clearance(y, str(car.get("kind", "SEDAN")), float(front_vehicle.get("y", y)), str(front_vehicle.get("kind", "SEDAN")))
		var follow_speed_limit: float = _traffic_follow_speed_limit(car, traffic_snapshot, delta)
		var following_shock_reaction: bool = _is_following_shock_reaction(car, traffic_snapshot)
		var merge_yield_limit: float = _merge_yield_speed_limit(car, traffic_snapshot)
		var slow_front_visible: bool = slow_front and front_clearance > 0.0 and front_clearance < overtake_trigger_distance
		var needs_overtake: bool = obstacle_close or (slow_front_visible and not following_shock_reaction)
		var player_route_conflict: bool = _car_path_overlaps_player_x(car) and approach_gap < overtake_trigger_distance + float(profile["follow_gap"])
		var initial_player_pressure: bool = bool(car["initial_behind"]) and float(car.get("opening_grace_remaining", 0.0)) <= 0.0 and approach_gap < overtake_trigger_distance and player_route_conflict
		if not bool(car["attempted_pass"]) and float(car.get("player_avoid_timer", 0.0)) <= 0.0 and (
			initial_player_pressure or needs_overtake
		):
			_start_overtake_attempt(car, traffic_snapshot)
			state = str(car["state"])

		if bool(car["attempted_pass"]) and not bool(car["passed"]):
			if state == "PREPARE OVERTAKE":
				var prepare_lane: int = int(car["target_lane"])
				if _overtake_lane_score(car, prepare_lane, traffic_snapshot) <= -100000000.0:
					if float(car.get("replan_cooldown", 0.0)) <= 0.0 and not _retarget_overtake(car, traffic_snapshot):
						car["state"] = "BLOCKED"
						state = "BLOCKED"
						car["maneuver_reason"] = "BLOCKED_ROUTE"
						car["wait_timer"] = rng.randf_range(float(profile["wait_min"]), float(profile["wait_max"]))
					else:
						state = str(car["state"])
					prepare_lane = int(car.get("target_lane", prepare_lane))
				if state == "PREPARE OVERTAKE":
					_set_overtake_lateral_target(car, "PREPARE OVERTAKE")
					var obstacle_requires_commit: bool = obstacle_close
					var front_requires_commit: bool = traffic_ahead and (slow_front or front_clearance < float(profile["follow_gap"]) * 1.35)
					var player_lane_requires_commit: bool = driver_type == "AGGRESSIVE" and int(car.get("overtake_hops", 0)) > 0 and current_lane == _nearest_lane(player_x) and approach_gap > 0.0 and approach_gap < maxf(float(profile["overtake_trigger_distance"]), 260.0) + float(profile["follow_gap"])
					var safe_rear_gap: float = maxf(_player_rear_safe_y(car) - player_y, 0.0)
					var commit_gap: float = maxf(float(profile["overtake_commit_distance"]), safe_rear_gap)
					var lateral_prepare_ready: bool = _overtake_prepare_is_ready(car)
					if lateral_prepare_ready or approach_gap <= commit_gap or obstacle_requires_commit or front_requires_commit or player_lane_requires_commit:
						if _overtake_lane_score(car, prepare_lane, traffic_snapshot) > -100000000.0:
							car["state"] = "LANE CHANGE"
							state = "LANE CHANGE"
							car["lane_change_commit_timer"] = NPC_LANE_COMMIT_DURATION
							_set_overtake_lateral_target(car, "LANE CHANGE")
						else:
							car["state"] = "BLOCKED"
							state = "BLOCKED"
							car["maneuver_reason"] = "BLOCKED_ROUTE"

			if state == "LANE CHANGE" or state == "AVOID":
				var target_lane: int = int(car["target_lane"])
				if float(car.get("lane_change_commit_timer", 0.0)) <= 0.0 and _overtake_lane_score(car, target_lane, traffic_snapshot) <= -100000000.0:
					if float(car.get("replan_cooldown", 0.0)) <= 0.0 and not _retarget_overtake(car, traffic_snapshot):
						car["state"] = "BLOCKED"
						state = "BLOCKED"
						car["maneuver_reason"] = "BLOCKED_ROUTE"
						car["wait_timer"] = rng.randf_range(float(profile["wait_min"]), float(profile["wait_max"]))
					else:
						state = str(car["state"])
				if state == "LANE CHANGE":
					_set_overtake_lateral_target(car, "LANE CHANGE")
					desired_speed = float(profile["overtake_speed"])
					if absf(float(car["x"]) - float(car["lateral_target_x"])) < 8.0:
						_complete_overtake_segment(car, target_lane)
						state = str(car["state"])

			if state == "BRAKE" or state == "BLOCKED":
				desired_speed = minf(desired_speed, float(profile["brake_speed"]))
				car["block_timer"] = float(car["block_timer"]) + delta
				car["pressure"] = maxf(float(car["pressure"]), 3.0)
				if not bool(car["block_reported"]) and float(car["block_timer"]) > 0.35:
					car["block_reported"] = true
					_register_event("堵住了！", 75, Vector2(float(car["x"]), y), COLOR_ACCENT)
				if state == "BLOCKED":
					car["wait_timer"] = maxf(float(car.get("wait_timer", 0.0)) - delta, 0.0)
					if float(car["wait_timer"]) <= 0.0 and float(car.get("replan_cooldown", 0.0)) <= 0.0:
						if _retarget_overtake(car, traffic_snapshot):
							state = str(car["state"])
						else:
							car["wait_timer"] = rng.randf_range(float(profile["wait_min"]), float(profile["wait_max"]))
							car["replan_cooldown"] = NPC_REPLAN_INTERVAL
				elif not obstacle_close and approach_gap > float(profile["overtake_commit_distance"]) * 0.65 and float(car.get("replan_cooldown", 0.0)) <= 0.0:
					if _retarget_overtake(car, traffic_snapshot):
						state = str(car["state"])

			if state == "PASS PLAYER":
				_set_overtake_lateral_target(car, "PASS PLAYER")
				var pass_target_x: float = float(car["lateral_target_x"])
				if not _player_target_is_safe(car, pass_target_x):
					if not _retarget_overtake(car, traffic_snapshot):
						car["state"] = "BLOCKED"
						state = "BLOCKED"
						car["player_avoid_timer"] = PLAYER_AVOID_DURATION
					else:
						state = str(car["state"])
				if state == "PASS PLAYER":
					var pass_burst_timer: float = float(car.get("pass_burst_timer", 0.0))
					if pass_burst_timer > 0.0:
						desired_speed = float(profile["pass_burst_speed"])
						car["pass_burst_timer"] = maxf(pass_burst_timer - delta, 0.0)
					else:
						desired_speed = float(profile["overtake_speed"])
					if _rects_overlap(Vector2(float(car["x"]), y), _car_dimensions(str(car["kind"])), Vector2(player_x, player_y), _player_body_size()):
						car["state"] = "BRAKE"
						state = "BRAKE"
						car["pressure"] = maxf(float(car["pressure"]), 2.5)
						car["player_avoid_timer"] = PLAYER_AVOID_DURATION
					if y < player_y - 115.0 and not bool(car["pass_logged"]) and _can_log_safe_pass(car):
						car["pass_logged"] = true
						car["passed"] = true
						car["state"] = "CRUISE"
						car["route_plan"] = []
						car["route_index"] = 0
						car["lane_reservation"] = -1
						car["lane_reservation_timer"] = 0.0
						car["maneuver_reason"] = "RECOVER"
						_register_overtake(car)

		if not bool(car["attempted_pass"]):
			if state == "LANE CHANGE" or state == "AVOID":
				var merge_lane: int = int(car["target_lane"])
				var merge_target_x: float = _overtake_target_x(car, merge_lane)
				var safe_lane_change: bool = _player_target_is_safe(car, merge_target_x) and _overtake_route_is_clear(car, merge_lane, merge_target_x, 170.0) and not _lateral_path_is_reserved(car, merge_lane, merge_target_x)
				if safe_lane_change:
					car["lateral_target_x"] = merge_target_x
					car["lane_reservation"] = merge_lane
					car["lane_reservation_timer"] = NPC_LANE_RESERVATION_DURATION
					desired_speed = minf(desired_speed, float(profile["follow_speed"]))
					if absf(float(car["x"]) - float(car["lateral_target_x"])) < 8.0:
						car["lane"] = merge_lane
						car["lane_reservation"] = -1
						car["lane_reservation_timer"] = 0.0
						car["state"] = "RECOVER"
						state = "RECOVER"
						car["maneuver_reason"] = "RECOVER"
				else:
					car["lane_reservation"] = -1
					car["lane_reservation_timer"] = 0.0
					car["target_lane"] = current_lane
					car["indicator"] = 0
					_set_lateral_target(car, current_lane)
					car["state"] = "WAIT"
					state = "WAIT"
					car["maneuver_reason"] = "BLOCKED_ROUTE"
					car["wait_timer"] = maxf(float(car.get("wait_timer", 0.0)), 0.35)

			if state == "WAIT" or state == "BLOCKED":
				car["wait_timer"] = maxf(float(car.get("wait_timer", 0.0)) - delta, 0.0)
			if state == "WAIT" or state == "FOLLOW" or state == "BLOCKED" or state == "BRAKE" or state == "CRUISE" or state == "RECOVER":
				if not obstacle_close and not traffic_ahead:
					if state != "CRUISE":
						car["state"] = "CRUISE"
						state = "CRUISE"
						car["maneuver_reason"] = "RECOVER"
					else:
						car["maneuver_reason"] = "CRUISE"
					_set_lateral_target(car, current_lane)
				else:
					var avoid_lane: int = _find_avoid_lane(car, traffic_snapshot) if float(car.get("replan_cooldown", 0.0)) <= 0.0 else -1
					var avoid_start_distance: float = maxf(60.0, float(profile["follow_gap"]) - 30.0)
					var can_avoid: bool = avoid_lane >= 0 and (obstacle_close or approach_gap > avoid_start_distance) and _try_commit_lane_change(car, avoid_lane, "AVOID", traffic_snapshot)
					if can_avoid:
						state = str(car.get("state", "AVOID"))
					elif traffic_ahead:
						if driver_type == "CAUTIOUS":
							car["state"] = "WAIT"
							state = "WAIT"
							car["maneuver_reason"] = "FOLLOW_FRONT"
							car["wait_timer"] = maxf(float(car.get("wait_timer", 0.0)), rng.randf_range(float(profile["wait_min"]), float(profile["wait_max"])))
						elif driver_type == "NORMAL":
							car["state"] = "FOLLOW"
							state = "FOLLOW"
							car["maneuver_reason"] = "FOLLOW_FRONT"
							desired_speed = minf(desired_speed, float(profile["follow_speed"]))
						else:
							car["state"] = "BLOCKED"
							state = "BLOCKED"
							car["maneuver_reason"] = "BLOCKED_ROUTE"
							car["wait_timer"] = maxf(float(car.get("wait_timer", 0.0)), float(profile["wait_min"]))
						desired_speed = minf(desired_speed, float(profile["brake_speed"]))
					else:
						car["state"] = "BRAKE"
						state = "BRAKE"
						car["maneuver_reason"] = "BLOCKED_ROUTE"
						desired_speed = minf(desired_speed, float(profile["brake_speed"]))

		if (state == "PREPARE OVERTAKE" or state == "LANE CHANGE") and float(car.get("pass_burst_timer", 0.0)) > 0.0:
			desired_speed = maxf(desired_speed, float(profile["pass_burst_speed"]))
			car["pass_burst_timer"] = maxf(float(car["pass_burst_timer"]) - delta, 0.0)

		# 刚并入主路的车辆先用短暂的流速适应段离开合流口，避免低速车型停在入口处把后续车辆全部挡住。
		if float(car.get("merge_exit_timer", 0.0)) > 0.0:
			desired_speed = maxf(desired_speed, float(car.get("merge_exit_speed", player_speed + MERGE_EXIT_SPEED_BONUS)))
		if bool(car.get("merge_completed", false)) and float(car.get("merge_flow_floor", 0.0)) > 0.0:
			# 合流后的车辆至少跟上主路流速，避免谨慎司机回落到 35 km/h 后重新堵在入口。
			desired_speed = maxf(desired_speed, float(car.get("merge_flow_floor", player_speed)))

		if float(car.get("speed_shock_timer", 0.0)) > 0.0:
			desired_speed = minf(desired_speed, float(car.get("speed_shock_target", NPC_SPEED_SHOCK_TARGET)))
			car["brake_reason"] = "PLAYER_ITEM"
		if not is_inf(follow_speed_limit):
			desired_speed = minf(desired_speed, follow_speed_limit)
			if str(car.get("brake_reason", "")).is_empty():
				car["brake_reason"] = "FOLLOW"
		if not is_inf(merge_yield_limit):
			desired_speed = minf(desired_speed, merge_yield_limit)
			if str(car.get("brake_reason", "")).is_empty():
				car["brake_reason"] = "MERGE_YIELD"

		if float(car["slip"]) > 0.0:
			desired_speed = minf(desired_speed, 31.0)
		if _has_active_effect("BLACK SMOKE") and y > player_y + 34.0 and y < player_y + 300.0:
			car["pressure"] = maxf(float(car["pressure"]), 1.5)

		var speed_acceleration: float = 30.0
		var current_state: String = str(car.get("state", state))
		if current_state == "LANE CHANGE" or current_state == "AVOID" or current_state == "PASS PLAYER":
			speed_acceleration = float(profile["overtake_acceleration"])
		_advance_traffic_position(car, desired_speed, delta, speed_acceleration, traffic_snapshot)
		y = float(car["y"])
		_apply_lateral_motion(car, delta)
		if absf(player_x - float(car["x"])) < lane_width * 0.25 and absf(float(car["y"]) - player_y) < 170.0:
			car["pressure"] = maxf(float(car["pressure"]), 0.6)
		if _traffic_is_far_from_player(car) and str(car.get("state", "CRUISE")) == "CRUISE":
			car["ai_decision_timer"] = TRAFFIC_FAR_AI_INTERVAL
		else:
			car["ai_decision_timer"] = 0.0


## 按统一刹车减速度推进车辆，并在可及时制动时夹回前车安全距离。
func _advance_traffic_position(car: Dictionary, desired_speed: float, delta: float, acceleration: float, snapshot: Array = []) -> void:
	if delta <= 0.0:
		return
	desired_speed = maxf(desired_speed, 0.0)
	if float(car.get("speed_shock_timer", 0.0)) > 0.0:
		desired_speed = minf(desired_speed, float(car.get("speed_shock_target", NPC_SPEED_SHOCK_TARGET)))
		car["brake_reason"] = "PLAYER_ITEM"
	var safe_speed_limit: float = _player_rear_speed_limit(car, desired_speed, delta)
	var player_limited_speed: bool = not is_inf(safe_speed_limit) and desired_speed > safe_speed_limit + 0.1
	if player_limited_speed:
		desired_speed = minf(desired_speed, safe_speed_limit)
		car["player_avoid_timer"] = maxf(float(car.get("player_avoid_timer", 0.0)), PLAYER_AVOID_DURATION)
	car["speed_command"] = desired_speed
	var current_speed: float = float(car.get("speed", desired_speed))
	var speed_change_rate: float = acceleration if desired_speed >= current_speed else NPC_BRAKE_DECELERATION
	var next_speed: float = move_toward(current_speed, desired_speed, speed_change_rate * delta)
	if player_limited_speed:
		next_speed = minf(next_speed, safe_speed_limit)
	car["speed"] = next_speed
	var current_y: float = float(car.get("y", player_y + 200.0))
	var next_y: float = current_y + (player_speed - next_speed) * PLAYER_SPEED_SCALE * delta
	if not snapshot.is_empty():
		next_y = _clamp_npc_next_y(car, next_y, delta, snapshot)
	if current_y > player_y and not _player_is_cutting_into_car(car) and _car_path_overlaps_player_x(car) and next_y < _player_rear_safe_y(car):
		next_y = _player_rear_safe_y(car)
		car["speed"] = minf(float(car["speed"]), player_speed)
		car["player_avoid_timer"] = maxf(float(car.get("player_avoid_timer", 0.0)), PLAYER_AVOID_DURATION)
	car["y"] = next_y


## 判断 NPC 当前车身或横向目标是否进入玩家的横向范围。
func _car_path_overlaps_player_x(car: Dictionary) -> bool:
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var player_size: Vector2 = _player_body_size()
	var current_x: float = float(car.get("x", 0.0))
	var target_x: float = float(car.get("lateral_target_x", current_x))
	return _horizontal_overlap(current_x, car_size.x, player_x, player_size.x) or _horizontal_overlap(target_x, car_size.x, player_x, player_size.x)


## 计算 NPC 在不追上玩家车尾时允许达到的最高速度。
func _player_rear_speed_limit(car: Dictionary, _desired_speed: float, delta: float) -> float:
	if delta <= 0.0 or float(car.get("y", player_y)) <= player_y or _player_is_cutting_into_car(car) or not _car_path_overlaps_player_x(car):
		return INF
	var safe_y: float = _player_rear_safe_y(car)
	var allowed_speed: float = player_speed + (float(car.get("y", safe_y)) - safe_y) / (PLAYER_SPEED_SCALE * delta)
	return clampf(allowed_speed, 0.0, INF)


## 判断玩家是否在本物理步主动横向切入并排行驶的 NPC。
func _player_is_cutting_into_car(car: Dictionary) -> bool:
	var player_delta_x: float = player_x - previous_player_x
	if absf(player_delta_x) < 1.5:
		return false
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var player_size: Vector2 = _player_body_size()
	if absf(float(car.get("y", 0.0)) - player_y) > minf(player_size.y, car_size.y) * 0.58:
		return false
	var moved_toward_car: bool = player_delta_x * (float(car.get("x", player_x)) - previous_player_x) > 0.0
	return moved_toward_car and _horizontal_overlap(player_x, player_size.x, float(car.get("x", 0.0)), car_size.x)


## 判断支路队首，后面的等待车辆不重复向同一辆主路车请求让行。
func _is_merge_queue_head(car: Dictionary) -> bool:
	var car_id: int = int(car.get("id", -1))
	var merge_side: int = int(car.get("merge_side", 0))
	var car_y: float = float(car.get("y", 0.0))
	for other in traffic:
		if int(other.get("id", -2)) == car_id or bool(other.get("crashed", false)):
			continue
		if str(other.get("spawn_origin", "MAIN")) != "MERGE" or str(other.get("state", "")) != "MERGE WAIT":
			continue
		if int(other.get("merge_side", 0)) == merge_side and int(other.get("id", -2)) < car_id and absf(float(other.get("y", car_y)) - car_y) < 24.0:
			return false
	return true


## 为支路队首附近的主路后车有限减速，逐步形成可解释的拉链空隙。
func _merge_yield_speed_limit(car: Dictionary, _snapshot: Array = []) -> float:
	var car_state: String = str(car.get("state", ""))
	if bool(car.get("crashed", false)) or (str(car.get("spawn_origin", "MAIN")) == "MERGE" and (car_state == "MERGING" or car_state == "MERGE WAIT")):
		return INF
	var car_y: float = float(car.get("y", 0.0))
	var car_speed: float = float(car.get("speed", 0.0))
	var car_kind: String = str(car.get("kind", "SEDAN"))
	var best_limit: float = INF
	for merge_car in traffic:
		if str(merge_car.get("spawn_origin", "MAIN")) != "MERGE" or bool(merge_car.get("crashed", false)):
			continue
		var merge_state: String = str(merge_car.get("state", ""))
		if merge_state != "MERGING" and merge_state != "MERGE WAIT":
			continue
		if merge_state == "MERGE WAIT" and not _is_merge_queue_head(merge_car):
			continue
		var target_lane: int = clampi(int(merge_car.get("merge_target_lane", merge_car.get("lane", 0))), 0, LANE_COUNT - 1)
		var merge_kind: String = str(merge_car.get("kind", "SEDAN"))
		var merge_size: Vector2 = _car_dimensions(merge_kind)
		var merge_x: float = float(merge_car.get("x", _lane_x(target_lane)))
		var merge_body_in_road: bool = merge_x + merge_size.x * 0.5 > road_left and merge_x - merge_size.x * 0.5 < road_left + road_width
		if merge_state == "MERGING" and not merge_body_in_road:
			continue
		var merge_path_overlaps: bool = target_lane in _lanes_touched_by_car(car) or _horizontal_path_overlap(merge_car, car, _lane_target_x(merge_car, target_lane), 0.0)
		if not merge_path_overlaps:
			continue
		var merge_y: float = float(merge_car.get("y", car_y))
		if car_y <= merge_y:
			continue
		var clearance: float = _vehicle_clearance(car_y, car_kind, merge_y, merge_kind)
		var merge_speed: float = float(merge_car.get("speed", player_speed))
		if car_speed <= merge_speed + 1.0 or clearance > 150.0:
			continue
		# 让行只消除相对速度，不把主路车压到异常低速，避免形成新的“礼让墙”。
		var yield_limit: float = maxf(merge_speed, car_speed - 8.0)
		if clearance < 70.0:
			yield_limit = minf(yield_limit, merge_speed)
		best_limit = minf(best_limit, yield_limit)
	if merge_yield_probe_timer > 0.0 and int(car.get("id", -1)) == merge_yield_probe_car_id and merge_yield_probe_lane >= 0:
		var probe_gate_y: float = _merge_gate_y()
		if car_y > probe_gate_y and merge_yield_probe_lane in _lanes_touched_by_car(car):
			# 让行只作用于一辆真正挡在入口后方的车，且保留最低流速，避免形成整条主路的礼让墙。
			var probe_limit: float = maxf(24.0, player_speed - 12.0)
			best_limit = minf(best_limit, probe_limit)
	return best_limit


## 为支路队列寻找一辆局部后车，短暂降速制造拉链窗口，而不是让整条主路统一减速。
func _plan_merge_yield_request(snapshot: Array = []) -> void:
	merge_yield_probe_lane = -1
	merge_yield_probe_car_id = -1
	merge_yield_probe_side = 0
	if merge_queue_count <= 0:
		return
	var states: Array = snapshot
	if states.is_empty():
		states = traffic
	var gate_y: float = _merge_gate_y()
	var candidate_size: Vector2 = _car_dimensions("SEDAN")
	var candidate_speed: float = minf(player_speed + 4.0, 44.0)
	var side_order: Array[int] = [merge_side_toggle, -merge_side_toggle]
	var best_score: float = -INF
	for side_value in side_order:
		if side_value == 0:
			continue
		var entry_x: float = _merge_entry_x(side_value)
		var candidate_lanes: Array[int] = [_merge_entry_lane(side_value)]
		for lane in candidate_lanes:
			var candidate_x: float = _lane_x(lane)
			if _lane_blocked_by_player(lane, gate_y, "SEDAN", candidate_x):
				continue
			# 已经有完整空隙时直接交给正常生成逻辑，不额外制造让行请求。
			if _merge_lane_gap_clear(lane, gate_y, "SEDAN", -1, candidate_x, states, candidate_speed, entry_x, "NORMAL"):
				continue
			var candidate_path_left: float = minf(entry_x, candidate_x) - candidate_size.x * 0.5 - MERGE_GAP_PADDING
			var candidate_path_right: float = maxf(entry_x, candidate_x) + candidate_size.x * 0.5 + MERGE_GAP_PADDING
			var front_gap: float = INF
			var rear_gap: float = INF
			var rear_car_id: int = -1
			var rear_car_speed: float = 0.0
			for other in states:
				var other_state: String = str(other.get("state", ""))
				if bool(other.get("crashed", false)) or (str(other.get("spawn_origin", "MAIN")) == "MERGE" and (other_state == "MERGING" or other_state == "MERGE WAIT")):
					continue
				var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
				var other_start_x: float = float(other.get("x", 0.0))
				var other_target_x: float = float(other.get("lateral_target_x", other_start_x))
				var other_path_left: float = minf(other_start_x, other_target_x) - other_size.x * 0.5
				var other_path_right: float = maxf(other_start_x, other_target_x) + other_size.x * 0.5
				if candidate_path_right <= other_path_left or candidate_path_left >= other_path_right:
					continue
				var other_y: float = float(other.get("y", gate_y))
				var body_clearance: float = (candidate_size.y + other_size.y) * 0.5
				if other_y < gate_y:
					var current_front_gap: float = gate_y - other_y - body_clearance
					if current_front_gap < front_gap:
						front_gap = current_front_gap
				else:
					var current_rear_gap: float = other_y - gate_y - body_clearance
					if current_rear_gap < rear_gap:
						rear_gap = current_rear_gap
						rear_car_id = int(other.get("id", -1))
						rear_car_speed = float(other.get("speed", player_speed))
			if rear_car_id < 0 or rear_car_speed <= player_speed + 2.0:
				continue
			# 不能用让行掩盖已经重叠的车身；只有接近安全线但仍有实体间距时才建立请求。
			if rear_gap <= -160.0 or front_gap < 18.0 or rear_gap > 260.0:
				continue
			var edge_lane: int = 0 if side_value < 0 else LANE_COUNT - 1
			var lane_bias: float = float(abs(lane - edge_lane)) * 18.0
			var side_bias: float = 8.0 if side_value == merge_side_toggle else 0.0
			var score: float = minf(front_gap, rear_gap) - lane_bias + side_bias
			if score > best_score:
				best_score = score
				merge_yield_probe_lane = lane
				merge_yield_probe_car_id = rear_car_id
				merge_yield_probe_side = side_value
	if merge_yield_probe_car_id >= 0:
		merge_yield_probe_timer = MERGE_YIELD_PROBE_DURATION


func _update_merge_traffic(car: Dictionary, delta: float, snapshot: Array = []) -> void:
	var merge_side: int = int(car.get("merge_side", -1))
	if merge_side == 0:
		merge_side = -1 if float(car.get("merge_entry_x", road_left)) < road_left else 1
	var target_lane: int = _merge_entry_lane(merge_side)
	var driver_type: String = str(car.get("driver_type", "NORMAL"))
	var profile: Dictionary = _driver_profile(driver_type)
	var car_kind: String = str(car["kind"])
	var junction: Dictionary = _merge_junction_for_car(car)
	var gate_y: float = float(car.get("merge_gate_y", _merge_gate_y()))
	var has_junction: bool = not junction.is_empty()
	var merge_phase: String = str(car.get("merge_phase", "MERGING"))
	if has_junction:
		gate_y = float(junction.get("y", gate_y))
		merge_phase = str(junction.get("phase", merge_phase))
		car["merge_gate_y"] = gate_y
		car["merge_start_y"] = gate_y + MERGE_ENTRY_Y_OFFSET
	var entry_x: float = float(car.get("merge_entry_x", _merge_entry_x(merge_side)))
	var entry_y: float = gate_y + MERGE_ENTRY_Y_OFFSET
	var ignored_id: int = int(car.get("id", -1))
	car["pressure"] = maxf(float(car.get("pressure", 0.0)) - delta, 0.0)
	car["contact_cooldown"] = maxf(float(car.get("contact_cooldown", 0.0)) - delta, 0.0)
	car["replan_cooldown"] = maxf(float(car.get("replan_cooldown", 0.0)) - delta, 0.0)
	car["lane_change_commit_timer"] = maxf(float(car.get("lane_change_commit_timer", 0.0)) - delta, 0.0)
	car["speed_shock_timer"] = maxf(float(car.get("speed_shock_timer", 0.0)) - delta, 0.0)
	car["speed_shock_memory_timer"] = maxf(float(car.get("speed_shock_memory_timer", 0.0)) - delta, 0.0)
	if float(car.get("speed_shock_timer", 0.0)) <= 0.0:
		car["speed_shock_target"] = -1.0
	if float(car.get("speed_shock_memory_timer", 0.0)) <= 0.0:
		car["speed_shock_source"] = ""
	car["player_avoid_timer"] = maxf(float(car.get("player_avoid_timer", 0.0)) - delta, 0.0)
	car["indicator_clock"] = float(car.get("indicator_clock", 0.0)) + delta
	if has_junction and merge_phase == "APPROACH":
		# 合流道路段抵达判定线前，车辆只跟随道路段一起前进，不提前检查或跨入主路。
		car["state"] = "MERGE APPROACH"
		car["merge_phase"] = "APPROACH"
		car["x"] = entry_x
		car["previous_x"] = entry_x
		car["lateral_target_x"] = entry_x
		car["y"] = entry_y
		car["merge_progress"] = 0.0
		car["merge_elapsed"] = 0.0
		car["merge_flow_offset"] = 0.0
		car["indicator"] = -merge_side
		var approach_speed: float = minf(float(car.get("base_speed", 40.0)), player_speed + 4.0)
		if float(car.get("speed_shock_timer", 0.0)) > 0.0:
			approach_speed = minf(approach_speed, float(car.get("speed_shock_target", NPC_SPEED_SHOCK_TARGET)))
		car["speed"] = move_toward(float(car.get("speed", approach_speed)), approach_speed, 80.0 * delta)
		car["speed_command"] = approach_speed
		if gate_y < _merge_gate_y():
			return
		merge_phase = "MERGING"
		_set_merge_junction_phase(car, "MERGING", true)
		car["merge_phase"] = merge_phase
	if str(car.get("state", "")) == "MERGE WAIT" and float(car.get("replan_cooldown", 0.0)) <= 0.0:
		var replanned_lane: int = _choose_merge_target_lane(
			gate_y,
			car_kind,
			float(car.get("speed", 0.0)),
			ignored_id,
			merge_side,
			entry_x,
			driver_type
		)
		car["replan_cooldown"] = MERGE_REPLAN_INTERVAL
		if replanned_lane < 0:
			car["maneuver_reason"] = "MERGE_WAIT_GAP"
			car["wait_timer"] = 0.0
	car["merge_target_lane"] = target_lane
	car["target_lane"] = target_lane
	car["merge_side"] = merge_side
	var target_x: float = _lane_x(target_lane)
	car["lateral_target_x"] = target_x
	var merge_state: String = str(car.get("state", "MERGE WAIT"))
	if merge_phase == "WAIT":
		merge_state = "MERGE WAIT"
	elif merge_phase == "MERGING":
		merge_state = "MERGING"
	var merge_progress: float = clampf(float(car.get("merge_progress", 0.0)), 0.0, 1.0)
	var merge_lateral_speed: float = minf(MERGE_LATERAL_SPEED, float(profile["lateral_speed"]) * 1.35)
	var merge_duration: float = float(car.get("merge_duration", 0.0))
	if merge_duration <= 0.0:
		merge_duration = absf(target_x - entry_x) / maxf(merge_lateral_speed, 1.0) + MERGE_PATH_TIME_PADDING
		car["merge_duration"] = merge_duration
	var merge_committed: bool = merge_state == "MERGING" and merge_progress >= MERGE_COMMIT_PROGRESS
	var route_open: bool = _player_target_is_safe(car, target_x) and _overtake_route_is_clear(car, target_lane, target_x, 220.0)
	var gap_open: bool = merge_committed or _merge_lane_gap_clear(target_lane, gate_y, car_kind, ignored_id, target_x, snapshot, -1.0, entry_x, driver_type)
	var merge_approach_speed: float = minf(float(car.get("base_speed", 40.0)), player_speed + 4.0)
	var desired_speed: float = player_speed if merge_state == "MERGE WAIT" else merge_approach_speed
	if float(car.get("speed_shock_timer", 0.0)) > 0.0:
		desired_speed = minf(desired_speed, float(car.get("speed_shock_target", NPC_SPEED_SHOCK_TARGET)))
		car["brake_reason"] = "PLAYER_ITEM"
	var follow_speed_limit: float = INF
	if merge_state != "MERGE WAIT":
		follow_speed_limit = _traffic_follow_speed_limit(car, snapshot, delta)
		if not is_inf(follow_speed_limit):
			desired_speed = minf(desired_speed, follow_speed_limit)
			if str(car.get("brake_reason", "")).is_empty():
				car["brake_reason"] = "FOLLOW"
	if (route_open and gap_open) or merge_committed:
		car["state"] = "MERGING"
		car["lane_reservation"] = target_lane
		car["lane_reservation_timer"] = maxf(float(car.get("lane_reservation_timer", 0.0)), merge_duration)
		car["merge_elapsed"] = float(car.get("merge_elapsed", 0.0)) + delta
		var previous_y: float = float(car.get("y", entry_y))
		_advance_traffic_position(car, desired_speed, delta, 75.0, snapshot)
		var flow_delta: float = float(car.get("y", previous_y)) - previous_y
		car["merge_flow_offset"] = float(car.get("merge_flow_offset", 0.0)) + flow_delta
		merge_progress = clampf(float(car.get("merge_elapsed", 0.0)) / maxf(merge_duration, 0.001), 0.0, 1.0)
		car["merge_progress"] = merge_progress
		var merge_point: Vector2 = _merge_path_point_for_car(car, merge_progress)
		car["x"] = merge_point.x
		car["y"] = merge_point.y + float(car.get("merge_flow_offset", 0.0))
		car["merge_phase"] = "MERGING"
		_set_merge_junction_phase(car, "MERGING", true)
		if merge_progress >= 1.0:
			car["x"] = target_x
			car["y"] = gate_y + float(car.get("merge_flow_offset", 0.0))
			car["lane"] = target_lane
			car["target_lane"] = target_lane
			car["merge_target_lane"] = target_lane
			car["state"] = "CRUISE"
			car["merge_completed"] = true
			car["merge_exit_attached"] = true
			car["merge_exit_timer"] = MERGE_EXIT_DURATION
			car["merge_exit_speed"] = player_speed + MERGE_EXIT_SPEED_BONUS
			car["merge_exit_cruise_offset"] = float(car.get("merge_cruise_offset", 0.0))
			car["merge_exit_offset_pending"] = true
			car["merge_exit_clear_y"] = float(car.get("y", gate_y)) - 180.0
			car["merge_flow_floor"] = maxf(player_speed, 40.0)
			car["cruise_offset"] = 0.0
			car["indicator"] = 0
			car["replan_cooldown"] = 0.0
			car["lane_change_commit_timer"] = 0.0
			car["lane_reservation"] = -1
			car["lane_reservation_timer"] = 0.0
			car["merge_phase"] = "EXIT"
			_set_merge_junction_phase(car, "EXIT", true)
			if run_time - merge_last_feedback_time > 2.0:
				merge_last_feedback_time = run_time
				_push_message("支路车辆汇入  /  车流补充", COLOR_INFO, 1.4)
				_add_floating_text(Vector2(target_x, gate_y), "汇入 L%d" % (target_lane + 1), COLOR_INFO, 0.9)
	else:
		car["state"] = "MERGE WAIT"
		car["merge_phase"] = "WAIT"
		_set_merge_junction_phase(car, "WAIT", false)
		car["lane_change_commit_timer"] = 0.0
		car["lane_reservation"] = -1
		car["lane_reservation_timer"] = 0.0
		car["lateral_target_x"] = entry_x
		car["x"] = entry_x
		car["y"] = entry_y
		car["merge_progress"] = 0.0
		car["merge_elapsed"] = 0.0
		car["merge_flow_offset"] = 0.0
		car["merge_start_y"] = entry_y
		car["speed"] = move_toward(float(car.get("speed", player_speed)), player_speed, 80.0 * delta)
		car["speed_command"] = player_speed
		car["pressure"] = maxf(float(car.get("pressure", 0.0)), 1.0)
		car["wait_timer"] = float(car.get("wait_timer", 0.0)) + delta


func _active_traffic_count() -> int:
	var active_count: int = 0
	for car in traffic:
		if not bool(car.get("crashed", false)):
			active_count += 1
	return active_count


func _merge_gate_y() -> float:
	var preferred_y: float = screen_size.y * MERGE_GATE_Y_RATIO
	var lower_bound: float = minf(player_y + 150.0, screen_size.y - 90.0)
	var upper_bound: float = maxf(lower_bound, screen_size.y - 90.0)
	return clampf(preferred_y, lower_bound, upper_bound)


## 返回左右支路第一次进入主路时对应的最近外侧车道。
func _merge_entry_lane(side: int) -> int:
	return 0 if side < 0 else LANE_COUNT - 1


## 返回支路车辆等待和开始加速并线时的屏幕纵坐标。
func _merge_entry_y() -> float:
	return _merge_gate_y() + MERGE_ENTRY_Y_OFFSET


func _merge_entry_x(side: int) -> float:
	return road_left - MERGE_ENTRY_OFFSET if side < 0 else road_left + road_width + MERGE_ENTRY_OFFSET


## 按车辆记录的 ID 找到其绑定的动态合流道路段；找不到时返回空字典兼容旧测试夹具。
func _merge_junction_for_car(car: Dictionary) -> Dictionary:
	var junction_id: int = int(car.get("merge_junction_id", -1))
	if junction_id < 0:
		return {}
	for junction in merge_junctions:
		if int(junction.get("id", -1)) == junction_id:
			return junction
	return {}


## 按道路段 ID 找到仍在场的合流车辆；车辆撞毁或已回收时不再绘制支路。
func _merge_car_for_junction(junction: Dictionary) -> Dictionary:
	var junction_id: int = int(junction.get("id", -1))
	if junction_id < 0:
		return {}
	for car in traffic:
		if int(car.get("id", -1)) != junction_id:
			continue
		if bool(car.get("crashed", false)):
			return {}
		return car
	return {}


## 按道路段 ID 返回数组下标，便于在状态切换时同步写回道路段。
func _merge_junction_index(junction_id: int) -> int:
	for index in range(merge_junctions.size()):
		if int(merge_junctions[index].get("id", -1)) == junction_id:
			return index
	return -1


## 判断同侧是否已有正在移动或等待的道路段，避免两段支路重叠成一根固定管道。
func _merge_side_has_active_junction(side: int) -> bool:
	for junction in merge_junctions:
		if int(junction.get("side", 0)) == side and str(junction.get("phase", "")) != "EXIT":
			return true
	return false


## 同步修改车辆与动态道路段的阶段和是否继续随镜头移动的标记。
func _set_merge_junction_phase(car: Dictionary, phase: String, moving: bool) -> void:
	car["merge_phase"] = phase
	var junction_id: int = int(car.get("merge_junction_id", -1))
	var junction_index: int = _merge_junction_index(junction_id)
	if junction_index < 0:
		return
	merge_junctions[junction_index]["phase"] = phase
	merge_junctions[junction_index]["moving"] = moving


## 推进动态合流道路段；道路段无绑定车辆时只等待自身离开后回收，避免出现常驻支路。
func _update_merge_junctions(delta: float) -> void:
	if delta <= 0.0:
		return
	var camera_motion: float = player_speed * PLAYER_SPEED_SCALE * delta
	for index in range(merge_junctions.size() - 1, -1, -1):
		var junction: Dictionary = merge_junctions[index]
		if bool(junction.get("moving", true)):
			junction["y"] = float(junction.get("y", MERGE_JUNCTION_START_Y)) + camera_motion
		var car: Dictionary = _merge_car_for_junction(junction)
		if car.is_empty():
			junction["phase"] = "EXIT"
			junction["moving"] = true
			if float(junction.get("y", 0.0)) > screen_size.y + MERGE_JUNCTION_CULL_MARGIN:
				merge_junctions.remove_at(index)
				continue
		else:
			var junction_y: float = float(junction.get("y", _merge_gate_y()))
			car["merge_gate_y"] = junction_y
			car["merge_start_y"] = junction_y + MERGE_ENTRY_Y_OFFSET
			var phase: String = str(junction.get("phase", car.get("merge_phase", "APPROACH")))
			if bool(car.get("crashed", false)):
				phase = "EXIT"
				junction["phase"] = phase
				junction["moving"] = true
				car["merge_phase"] = phase
			if phase == "APPROACH":
				car["x"] = float(car.get("merge_entry_x", _merge_entry_x(int(junction.get("side", -1)))))
				car["previous_x"] = car["x"]
				car["lateral_target_x"] = car["x"]
				car["y"] = float(junction.get("y", MERGE_JUNCTION_START_Y)) + MERGE_ENTRY_Y_OFFSET
				car["previous_y"] = car["y"]
				car["merge_progress"] = 0.0
				car["merge_elapsed"] = 0.0
				car["merge_flow_offset"] = 0.0
				car["state"] = "MERGE APPROACH"
			elif phase == "EXIT" and bool(car.get("merge_exit_attached", false)) and not bool(car.get("crashed", false)):
				# 完成并线后的短暂退出段仍与道路段同向下移，保证支路和车辆不会在屏幕边缘脱节。
				car["x"] = _lane_x(clampi(int(junction.get("target_lane", car.get("lane", 0))), 0, LANE_COUNT - 1))
				car["y"] = junction_y + float(car.get("merge_flow_offset", 0.0))
			elif phase == "EXIT" and str(car.get("state", "")) == "MERGE APPROACH":
				# 车辆异常离场时不把道路段重新切回等待态。
				car["merge_phase"] = phase
			if phase == "EXIT" and junction_y > screen_size.y + MERGE_JUNCTION_CULL_MARGIN:
				# 道路段和绑定车辆都已经离开可视区；车辆解除绑定后交回普通回收流程。
				car["merge_junction_id"] = -1
				car["merge_phase"] = "CRUISE"
				car["merge_exit_attached"] = false
				merge_junctions.remove_at(index)
				continue
		merge_junctions[index] = junction

## 把合流进度转换为平滑的曲线进度，避免车辆在路径起点和终点突然变向。
func _merge_path_ease(progress: float) -> float:
	var t: float = clampf(progress, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## 返回一段带控制点的贝塞尔曲线上的位置，用于视觉和车辆移动共用同一条路线。
func _cubic_merge_path_point(start: Vector2, control_a: Vector2, control_b: Vector2, end: Vector2, progress: float) -> Vector2:
	var t: float = _merge_path_ease(progress)
	var inverse_t: float = 1.0 - t
	var inverse_t_squared: float = inverse_t * inverse_t
	var t_squared: float = t * t
	return start * inverse_t_squared * inverse_t + control_a * 3.0 * inverse_t_squared * t + control_b * 3.0 * inverse_t * t_squared + end * t_squared * t


## 根据汇入侧、目标车道、起点和动态合流点返回真实的支路曲线路径点。
func _merge_path_point_between(side: int, target_lane: int, start_x: float, start_y: float, progress: float, gate_y_override: float = INF) -> Vector2:
	var start: Vector2 = Vector2(start_x, start_y)
	var gate_y: float = _merge_gate_y() if is_inf(gate_y_override) else gate_y_override
	var end: Vector2 = Vector2(_lane_x(target_lane), gate_y)
	var direction: float = 1.0 if side < 0 else -1.0
	var vertical_span: float = maxf(absf(start_y - end.y), 40.0)
	var control_a: Vector2 = start + Vector2(direction * 24.0, -vertical_span * 0.22)
	var control_b: Vector2 = end - Vector2(direction * 34.0, -vertical_span * 0.62)
	return _cubic_merge_path_point(start, control_a, control_b, end, progress)


## 返回标准左右支路的曲线路径点，供道路标线和提示箭头使用。
func _merge_path_point(side: int, progress: float) -> Vector2:
	return _merge_path_point_between(side, _merge_entry_lane(side), _merge_entry_x(side), _merge_entry_y(), progress)


## 返回指定合流车辆当前进度对应的曲线路径点。
func _merge_path_point_for_car(car: Dictionary, progress: float) -> Vector2:
	var side: int = int(car.get("merge_side", 0))
	var target_lane: int = clampi(int(car.get("merge_target_lane", _merge_entry_lane(side))), 0, LANE_COUNT - 1)
	var start_x: float = float(car.get("merge_entry_x", _merge_entry_x(side)))
	var gate_y: float = float(car.get("merge_gate_y", _merge_gate_y()))
	var junction: Dictionary = _merge_junction_for_car(car)
	if not junction.is_empty():
		gate_y = float(junction.get("y", gate_y))
		car["merge_gate_y"] = gate_y
		car["merge_start_y"] = gate_y + MERGE_ENTRY_Y_OFFSET
	var start_y: float = float(car.get("merge_start_y", gate_y + MERGE_ENTRY_Y_OFFSET))
	return _merge_path_point_between(side, target_lane, start_x, start_y, progress, gate_y)


## 返回动态合流道路段在指定进度上的中心点，视觉道路和车辆共享这一条路径。
func _merge_path_point_for_junction(junction: Dictionary, progress: float) -> Vector2:
	var side: int = int(junction.get("side", -1))
	var target_lane: int = clampi(int(junction.get("target_lane", _merge_entry_lane(side))), 0, LANE_COUNT - 1)
	var gate_y: float = float(junction.get("y", _merge_gate_y()))
	return _merge_path_point_between(side, target_lane, _merge_entry_x(side), gate_y + MERGE_ENTRY_Y_OFFSET, progress, gate_y)


## 根据动态合流道路段生成路面带状多边形，随道路段而不是固定屏幕装饰移动。
func _merge_path_strip_for_junction(junction: Dictionary, width: float) -> PackedVector2Array:
	var left_points: PackedVector2Array = PackedVector2Array()
	var right_points: PackedVector2Array = PackedVector2Array()
	var half_width: float = width * 0.5
	for sample_index in range(MERGE_PATH_SAMPLE_COUNT + 1):
		var progress: float = float(sample_index) / float(MERGE_PATH_SAMPLE_COUNT)
		var center: Vector2 = _merge_path_point_for_junction(junction, progress)
		var before: Vector2 = _merge_path_point_for_junction(junction, maxf(progress - 0.02, 0.0))
		var after: Vector2 = _merge_path_point_for_junction(junction, minf(progress + 0.02, 1.0))
		var tangent: Vector2 = (after - before).normalized()
		var normal: Vector2 = Vector2(-tangent.y, tangent.x)
		left_points.append(center + normal * half_width)
		right_points.append(center - normal * half_width)
	var strip: PackedVector2Array = PackedVector2Array()
	for point in left_points:
		strip.append(point)
	for index in range(right_points.size() - 1, -1, -1):
		strip.append(right_points[index])
	return strip


## 生成支路路面带状多边形，让运行时道路材质和车辆路径保持一致。
func _merge_path_strip(side: int, width: float) -> PackedVector2Array:
	var standard_junction: Dictionary = {
		"side": side,
		"target_lane": _merge_entry_lane(side),
		"y": _merge_gate_y(),
	}
	return _merge_path_strip_for_junction(standard_junction, width)


## 判断支路车辆沿实际横向路径移动时，指定时刻的车身中心位置。
func _merge_path_x_at_time(start_x: float, target_x: float, lateral_speed: float, elapsed: float) -> float:
	return move_toward(start_x, target_x, maxf(lateral_speed, 1.0) * maxf(elapsed, 0.0))


## 判断合流横向扫掠与另一辆车是否会在同一时刻形成不安全的纵向间距。
func _merge_path_conflicts_with_vehicle(candidate_start_x: float, candidate_x: float, center_y: float, candidate_speed: float, candidate_driver_type: String, candidate_size: Vector2, other: Dictionary, other_size: Vector2) -> bool:
	var candidate_profile: Dictionary = _driver_profile(candidate_driver_type)
	var candidate_lateral_speed: float = MERGE_LATERAL_SPEED
	var candidate_merge_side: int = -1 if candidate_start_x < road_left else (1 if candidate_start_x > road_left + road_width else 0)
	var candidate_start_y: float = center_y + MERGE_ENTRY_Y_OFFSET if candidate_merge_side != 0 else center_y
	var candidate_target_lane: int = _nearest_lane(candidate_x)
	var candidate_travel_time: float = absf(candidate_x - candidate_start_x) / candidate_lateral_speed + MERGE_PATH_TIME_PADDING
	var other_start_x: float = float(other.get("x", 0.0))
	var other_target_x: float = float(other.get("lateral_target_x", other_start_x))
	var other_profile: Dictionary = _driver_profile(str(other.get("driver_type", "NORMAL")))
	var other_lateral_speed: float = float(other_profile.get("lateral_speed", 120.0))
	if str(other.get("state", "")) == "MERGING":
		other_lateral_speed = minf(MERGE_LATERAL_SPEED, other_lateral_speed * 1.35)
	var horizon: float = candidate_travel_time + 0.18
	var sample_count: int = clampi(ceili(horizon * 30.0), 8, 24)
	var other_speed: float = float(other.get("speed", candidate_speed))
	var front_closing_speed: float = maxf(candidate_speed - other_speed, 0.0)
	var rear_closing_speed: float = maxf(other_speed - candidate_speed, 0.0)
	var reaction_time: float = float(candidate_profile.get("reaction_time", 0.30))
	var front_reaction_margin: float = front_closing_speed * PLAYER_SPEED_SCALE * reaction_time
	var front_braking_margin: float = front_closing_speed * front_closing_speed / (2.0 * NPC_BRAKE_DECELERATION) * PLAYER_SPEED_SCALE
	var rear_reaction_margin: float = rear_closing_speed * PLAYER_SPEED_SCALE * reaction_time
	var rear_braking_margin: float = rear_closing_speed * rear_closing_speed / (2.0 * NPC_BRAKE_DECELERATION) * PLAYER_SPEED_SCALE
	var body_limit: float = (candidate_size.y + other_size.y) * 0.5 + MERGE_GAP_PADDING
	for sample_index in range(sample_count + 1):
		var elapsed: float = horizon * float(sample_index) / float(sample_count)
		var candidate_progress: float = clampf(elapsed / maxf(candidate_travel_time, 0.001), 0.0, 1.0)
		var candidate_point: Vector2 = Vector2(
			lerpf(candidate_start_x, candidate_x, _merge_path_ease(candidate_progress)),
			lerpf(candidate_start_y, center_y, _merge_path_ease(candidate_progress))
		)
		if candidate_merge_side != 0:
			candidate_point = _merge_path_point_between(candidate_merge_side, candidate_target_lane, candidate_start_x, candidate_start_y, candidate_progress, center_y)
		var candidate_at_time: float = candidate_point.x
		var other_at_time: float = _merge_path_x_at_time(other_start_x, other_target_x, other_lateral_speed, elapsed)
		if not _horizontal_overlap(candidate_at_time, candidate_size.x, other_at_time, other_size.x):
			continue
		var candidate_y_at_time: float = candidate_point.y + (player_speed - candidate_speed) * PLAYER_SPEED_SCALE * elapsed
		var other_y_at_time: float = float(other.get("y", center_y)) + (player_speed - other_speed) * PLAYER_SPEED_SCALE * elapsed
		var other_is_ahead: bool = other_y_at_time < candidate_y_at_time
		var dynamic_limit: float = body_limit
		if other_is_ahead:
			dynamic_limit += front_reaction_margin + minf(front_braking_margin * 0.35, 48.0)
		else:
			dynamic_limit += rear_reaction_margin + minf(rear_braking_margin, 160.0)
		if absf(candidate_y_at_time - other_y_at_time) < dynamic_limit:
			return true
	return false


## 按实际车身、相对速度和横向移动时间判断支路车辆能否进入目标车道。
func _merge_lane_gap_clear(lane: int, center_y: float, car_kind: String, ignored_id: int = -1, candidate_x_override: float = -1.0, snapshot: Array = [], candidate_speed_override: float = -1.0, candidate_start_x_override: float = -1.0, candidate_driver_type: String = "NORMAL") -> bool:
	var candidate_size: Vector2 = _car_dimensions(car_kind)
	var candidate_x: float = _lane_x(lane) if candidate_x_override < 0.0 else candidate_x_override
	var candidate_speed: float = candidate_speed_override if candidate_speed_override >= 0.0 else 40.0
	var candidate_start_x: float = candidate_start_x_override if candidate_start_x_override >= 0.0 else candidate_x
	var states: Array = snapshot
	if states.is_empty():
		states = traffic
	if ignored_id >= 0:
		for candidate_state in states:
			if int(candidate_state.get("id", -2)) == ignored_id:
				candidate_speed = float(candidate_state.get("speed", candidate_speed))
				candidate_start_x = float(candidate_state.get("x", candidate_start_x))
				break
	var candidate_merge_side: int = -1 if candidate_start_x < road_left else (1 if candidate_start_x > road_left + road_width else 0)
	var candidate_id: int = ignored_id
	for other in states:
		if (bool(other.get("crashed", false)) and float(other.get("crash_time", 0.0)) >= NPC_CRASH_BLOCK_DURATION) or int(other.get("id", -1)) == ignored_id:
			continue
		var other_y: float = float(other.get("y", 0.0))
		var vertical_gap: float = absf(center_y - other_y)
		var other_state: String = str(other.get("state", ""))
		var other_merge_side: int = int(other.get("merge_side", 0))
		var other_id: int = int(other.get("id", -1))
		var same_y_queue_order: bool = absf(other_y - center_y) < 4.0 and candidate_id >= 0 and other_id > candidate_id
		var other_is_waiting_behind_in_same_branch: bool = other_state == "MERGE WAIT" and candidate_merge_side != 0 and other_merge_side == candidate_merge_side and (other_y > center_y + 4.0 or same_y_queue_order)
		if other_is_waiting_behind_in_same_branch:
			continue
		if (other_state == "MERGING" or other_state == "MERGE WAIT") and int(other.get("merge_target_lane", -1)) == lane and vertical_gap < 180.0:
			return false
		var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
		var other_speed: float = float(other.get("speed", candidate_speed))
		var other_is_ahead: bool = other_y < center_y
		if candidate_merge_side != 0 and _merge_path_conflicts_with_vehicle(candidate_start_x, candidate_x, center_y, candidate_speed, candidate_driver_type, candidate_size, other, other_size):
			return false
		# 只计算真正会缩短这一侧间距的相对速度；例如后车比合流车慢时，不应凭空增加后方安全距离。
		var closing_speed: float = maxf(candidate_speed - other_speed, 0.0) if other_is_ahead else maxf(other_speed - candidate_speed, 0.0)
		var profile: Dictionary = _driver_profile(candidate_driver_type)
		var reaction_time: float = float(profile.get("reaction_time", 0.30))
		var reaction_margin: float = closing_speed * PLAYER_SPEED_SCALE * reaction_time
		var braking_margin: float = closing_speed * closing_speed / (2.0 * NPC_BRAKE_DECELERATION) * PLAYER_SPEED_SCALE
		# 合流车辆还要留出一小段进入后的跟车余量，但不要求整条车道先清空。
		var merge_follow_margin: float = float(profile.get("follow_gap", 120.0)) * 0.12 if candidate_merge_side != 0 else 0.0
		var vertical_limit: float = (candidate_size.y + other_size.y) * 0.5 + MERGE_GAP_PADDING + merge_follow_margin + reaction_margin + minf(braking_margin, 160.0)
		var candidate_path_left: float = minf(candidate_start_x, candidate_x) - candidate_size.x * 0.5 - MERGE_GAP_PADDING
		var candidate_path_right: float = maxf(candidate_start_x, candidate_x) + candidate_size.x * 0.5 + MERGE_GAP_PADDING
		var other_start_x: float = float(other.get("x", 0.0))
		var other_target_x: float = float(other.get("lateral_target_x", other_start_x))
		var other_path_left: float = minf(other_start_x, other_target_x) - other_size.x * 0.5
		var other_path_right: float = maxf(other_start_x, other_target_x) + other_size.x * 0.5
		if vertical_gap < vertical_limit and candidate_path_right > other_path_left and candidate_path_left < other_path_right:
			return false
	return true


## 为支路车辆优先选择靠近入口且有真实前后空隙的目标车道。
func _choose_merge_target_lane(center_y: float, car_kind: String, candidate_speed: float = 40.0, ignored_id: int = -1, merge_side: int = 0, candidate_start_x: float = -1.0, candidate_driver_type: String = "NORMAL") -> int:
	var best_lane: int = -1
	var best_score: float = INF
	var candidate_lanes: Array[int] = []
	if merge_side != 0:
		candidate_lanes.append(_merge_entry_lane(merge_side))
	else:
		for lane_index in range(LANE_COUNT):
			candidate_lanes.append(lane_index)
	for lane in candidate_lanes:
		var candidate_x: float = _lane_x(lane)
		if _lane_blocked_by_player(lane, center_y, car_kind, candidate_x) or _lane_has_route_blocker(lane, center_y + 2.0, 220.0):
			continue
		if not _merge_lane_gap_clear(lane, center_y, car_kind, ignored_id, candidate_x, [], candidate_speed, candidate_start_x, candidate_driver_type):
			continue
		var nearby_count: int = 0
		for car in traffic:
			if bool(car.get("crashed", false)) or int(car.get("id", -2)) == ignored_id:
				continue
			if absf(float(car.get("y", 0.0)) - center_y) < 300.0 and lane in _lanes_touched_by_car(car):
				nearby_count += 1
		var edge_lane: int = 0 if merge_side < 0 else (LANE_COUNT - 1 if merge_side > 0 else merge_display_lane)
		# 支路先进入靠近入口的一道；进入主路后再由普通超车规划向内侧移动，避免横穿整条主路抢远端空位。
		var lane_score: float = float(nearby_count) * 10.0 + absf(float(lane - edge_lane)) * 80.0 + absf(float(lane - merge_display_lane)) * 0.1
		if lane_score < best_score:
			best_score = lane_score
			best_lane = lane
	return best_lane


func _random_traffic_profile(difficulty: float) -> Dictionary:
	var aggressive_chance: float = 0.18 + difficulty * 0.30
	var roll: float = rng.randf()
	var driver_type: String = "AGGRESSIVE" if roll < aggressive_chance else ("CAUTIOUS" if roll < aggressive_chance + 0.28 else "NORMAL")
	var aggressive: bool = driver_type == "AGGRESSIVE"
	var kinds: Array[String] = ["SEDAN", "SUV", "VAN", "PICKUP", "TRUCK", "BUS"]
	var kind: String = "SEDAN" if aggressive else kinds[rng.randi_range(0, kinds.size() - 1)]
	var profile: Dictionary = _driver_profile(driver_type)
	var base_speed: float = rng.randf_range(float(profile["speed_min"]), float(profile["speed_max"]))
	return {
		"kind": kind,
		"base_speed": base_speed,
		"aggressive": aggressive,
		"driver_type": driver_type,
	}


## 从支路队首挑选能实际找到空隙的车型；大车当前无空隙时换下一辆候选，不把整个入口锁死。
func _try_spawn_merge_car(max_cars: int, difficulty: float) -> bool:
	if merge_queue_count <= 0 or _active_traffic_count() >= max_cars:
		return false
	var merge_y: float = _merge_gate_y()
	var side: int = merge_side_toggle
	if _merge_side_has_active_junction(side):
		return false
	var entry_x: float = _merge_entry_x(side)
	var junction_start_y: float = MERGE_JUNCTION_START_Y
	var entry_y: float = junction_start_y + MERGE_ENTRY_Y_OFFSET
	var profile: Dictionary = {}
	var merge_speed: float = 0.0
	var target_lane: int = -1
	# 队列记录的是等待进入的车辆数量，具体车型可在入口根据当前空隙重新择机，避免一辆大车把入口永久卡住。
	for _attempt in range(8):
		var candidate_profile: Dictionary = _random_traffic_profile(difficulty)
		# 支路先用接近主路的速度找空隙，完成并线后再恢复该司机自己的巡航速度。
		var candidate_merge_speed: float = minf(float(candidate_profile["base_speed"]), player_speed + 4.0)
		# 选择时就带上从支路入口到外侧目标车道的实际扫掠路径，避免先生成在“看似可用”、实际无法穿过的车道。
		var candidate_lane: int = _choose_merge_target_lane(merge_y, str(candidate_profile["kind"]), candidate_merge_speed, -1, side, entry_x, str(candidate_profile["driver_type"]))
		if candidate_lane < 0:
			continue
		profile = candidate_profile
		merge_speed = candidate_merge_speed
		target_lane = candidate_lane
		break
	if target_lane < 0:
		return false
	_spawn_traffic(str(profile["kind"]), target_lane, entry_y, merge_speed, bool(profile["aggressive"]), str(profile["driver_type"]), "MERGE")
	var car: Dictionary = traffic[traffic.size() - 1]
	car["x"] = _merge_entry_x(side)
	car["previous_x"] = car["x"]
	car["lateral_target_x"] = car["x"]
	car["y"] = entry_y
	car["lane"] = target_lane
	car["target_lane"] = target_lane
	car["merge_side"] = side
	car["merge_target_lane"] = target_lane
	car["merge_entry_x"] = entry_x
	car["merge_junction_id"] = int(car.get("id", -1))
	car["merge_phase"] = "APPROACH"
	car["merge_gate_y"] = junction_start_y
	car["merge_start_y"] = entry_y
	car["merge_progress"] = 0.0
	car["merge_elapsed"] = 0.0
	car["merge_duration"] = 0.0
	car["merge_flow_offset"] = 0.0
	# 并线阶段先对准车道中心，避免人格巡航偏移把刚确认的空隙又扩大成一次新的拒绝。
	car["merge_cruise_offset"] = float(car.get("cruise_offset", 0.0))
	car["cruise_offset"] = 0.0
	car["merge_completed"] = false
	car["initial_behind"] = false
	car["attempted_pass"] = false
	car["state"] = "MERGE APPROACH"
	car["indicator"] = -side
	car["speed"] = merge_speed
	car["speed_command"] = merge_speed
	car["base_speed"] = float(profile["base_speed"])
	merge_junctions.append({
		"id": int(car.get("id", -1)),
		"side": side,
		"target_lane": target_lane,
		"y": junction_start_y,
		"phase": "APPROACH",
		"moving": true,
	})
	merge_queue_count -= 1
	merge_spawned_count += 1
	merge_display_lane = target_lane
	merge_side_toggle *= -1
	return true


func _branch_merge_active() -> bool:
	for road_event in road_events:
		if bool(road_event.get("active", true)) and str(road_event.get("type", "")) == "BRANCH MERGE":
			return true
	return false


func _update_merge_source(delta: float, difficulty: float, max_cars: int) -> void:
	merge_source_clock += delta
	merge_release_cooldown = maxf(merge_release_cooldown - delta, 0.0)
	var branch_merge_active: bool = _branch_merge_active()
	var spawn_interval: float = lerpf(MERGE_BASE_INTERVAL_START, MERGE_BASE_INTERVAL_END, difficulty)
	if branch_merge_active:
		spawn_interval = lerpf(MERGE_EVENT_INTERVAL_START, MERGE_EVENT_INTERVAL_END, difficulty)
	if merge_source_clock >= spawn_interval:
		merge_source_clock = fmod(merge_source_clock, spawn_interval)
		merge_queue_count = mini(merge_queue_count + 1, MERGE_QUEUE_LIMIT)
		merge_queue_peak = maxi(merge_queue_peak, merge_queue_count)
	if merge_queue_count > 0 and merge_release_cooldown <= 0.0:
		# 开局车流采用渐进目标，但支路仍保留少量专用名额，避免入口永久排队。
		var merge_capacity: int = mini(MAX_TRAFFIC_AT_END, max_cars + MERGE_CAPACITY_BUFFER)
		var merge_spawned: bool = _try_spawn_merge_car(merge_capacity, difficulty)
		if not merge_spawned:
			# 一侧被堵住时立即给另一侧一次机会，不能让单个入口失败把左右两侧一起饿死。
			merge_side_toggle *= -1
			merge_spawned = _try_spawn_merge_car(merge_capacity, difficulty)
			if not merge_spawned:
				merge_side_toggle *= -1
		if merge_spawned:
			merge_yield_probe_lane = -1
			merge_yield_probe_car_id = -1
			merge_yield_probe_side = 0
			merge_yield_probe_timer = 0.0
			merge_release_cooldown = minf(spawn_interval * 0.55, 0.75)


func _traffic_ahead_close(_index: int, car: Dictionary, snapshot: Array = []) -> bool:
	var front_vehicle: Dictionary = _front_vehicle_for_car(car, snapshot)
	if front_vehicle.is_empty():
		return false
	var clearance: float = _vehicle_clearance(float(car.get("y", 0.0)), str(car.get("kind", "SEDAN")), float(front_vehicle.get("y", 0.0)), str(front_vehicle.get("kind", "SEDAN")))
	return clearance < _traffic_required_clearance(car, front_vehicle)


## 根据刹车距离和横向移动时间，返回车辆需要开始观察障碍的提前距离。
func _obstacle_lookahead_distance(car: Dictionary, reaction_distance_override: float = -1.0) -> float:
	var profile: Dictionary = _driver_profile(str(car.get("driver_type", "NORMAL")))
	var reaction_distance: float = float(profile["reaction_distance"]) if reaction_distance_override <= 0.0 else reaction_distance_override
	if _has_active_effect("BLACK SMOKE") and float(car.get("y", player_y)) > player_y:
		reaction_distance *= 0.48
	var current_lane: int = int(car.get("lane", 0))
	var divider_lane: int = clampi(current_lane + int(car.get("divider_side", 1)), 0, LANE_COUNT - 1)
	var lateral_time: float = _estimate_lateral_travel_time(car, _lane_boundary_x(current_lane, divider_lane))
	var current_speed: float = float(car.get("speed", 0.0))
	var relative_speed: float = maxf(current_speed - player_speed, 0.0)
	var reaction_time: float = float(profile.get("reaction_time", 0.30))
	var reaction_closing_distance: float = relative_speed * PLAYER_SPEED_SCALE * reaction_time
	var braking_distance: float = relative_speed * relative_speed / (2.0 * NPC_BRAKE_DECELERATION) * PLAYER_SPEED_SCALE
	var approach_distance: float = maxf(current_speed, player_speed) * PLAYER_SPEED_SCALE * lateral_time
	return reaction_distance + float(profile["follow_gap"]) * 0.45 + reaction_closing_distance + braking_distance + approach_distance + NPC_BODY_BUFFER


## 判断当前车身覆盖的路线前方是否存在需要提前处理的障碍物或封道路段。
func _obstacle_in_lane_ahead(car: Dictionary, reaction_distance_override: float = -1.0) -> bool:
	var reaction_distance: float = _obstacle_lookahead_distance(car, reaction_distance_override)
	var touched_lanes: Array[int] = _lanes_touched_by_car(car)
	for hazard in hazards:
		if not bool(hazard["active"]):
			continue
		if not bool(hazard.get("blocks_route", false)):
			continue
		var gap: float = float(car["y"]) - float(hazard["y"])
		if gap > 0.0 and gap < reaction_distance:
			for lane in touched_lanes:
				if _hazard_overlaps_lane(hazard, lane):
					return true
	for road_event in road_events:
		if not bool(road_event.get("active", true)):
			continue
		var event_gap: float = float(car["y"]) - float(road_event["y"])
		if event_gap > 0.0 and event_gap < reaction_distance:
			for lane in touched_lanes:
				if _road_event_blocks_lane(road_event, lane):
					return true
	for lane in touched_lanes:
		if _moving_barrier_blocks_lane(lane, float(car["y"])):
			return true
	return false


func _road_event_blocks_lane(road_event: Dictionary, lane: int) -> bool:
	var blocked_lanes: Array = road_event.get("blocked_lanes", [int(road_event.get("lane", 0))])
	return lane in blocked_lanes


func _lane_blocked_by_player(target_lane: int, car_y: float, car_kind: String = "SEDAN", candidate_x_override: float = -1.0) -> bool:
	if _has_active_effect("LONG TRAILER"):
		return absf(car_y - player_y) < 260.0
	var candidate_size: Vector2 = _car_dimensions(car_kind)
	var candidate_x: float = _lane_x(target_lane) if candidate_x_override < 0.0 else candidate_x_override
	var player_size: Vector2 = _player_body_size()
	var safe_depth: float = (candidate_size.y + player_size.y) * 0.5 + PLAYER_REAR_BUFFER
	return _horizontal_overlap(candidate_x, candidate_size.x, player_x, player_size.x) and absf(car_y - player_y) < safe_depth


## 为普通避让选择实际空隙最大的相邻车道，沿用与超车一致的车身检查。
func _find_avoid_lane(car: Dictionary, snapshot: Array = []) -> int:
	var current_lane: int = int(car["lane"])
	var best_lane: int = -1
	var best_score: float = -INF
	for candidate in _adjacent_lanes(current_lane):
		var lane_score: float = _overtake_lane_score(car, candidate, snapshot)
		if lane_score > best_score:
			best_score = lane_score
			best_lane = candidate
	return best_lane


## 按实际车身、相对速度和玩家安全区判断普通刷新位置是否可以安全加入车流。
func _spawn_gap_is_clear(kind: String, lane: int, center_y: float, speed: float, driver_type: String) -> bool:
	var candidate_size: Vector2 = _car_dimensions(kind)
	var candidate_x: float = _lane_x(lane)
	var profile: Dictionary = _driver_profile(driver_type)
	var player_size: Vector2 = _player_body_size()
	if _horizontal_overlap(candidate_x, candidate_size.x, player_x, player_size.x) and absf(center_y - player_y) < (candidate_size.y + player_size.y) * 0.5 + PLAYER_REAR_BUFFER:
		return false
	for other in traffic:
		if bool(other.get("crashed", false)) and float(other.get("crash_time", 0.0)) >= NPC_CRASH_BLOCK_DURATION:
			continue
		var other_size: Vector2 = _car_dimensions(str(other.get("kind", "SEDAN")))
		var other_start_x: float = float(other.get("x", 0.0))
		var other_target_x: float = float(other.get("lateral_target_x", other_start_x))
		var other_path_left: float = minf(other_start_x, other_target_x) - other_size.x * 0.5 - NPC_LANE_RESERVATION_PADDING
		var other_path_right: float = maxf(other_start_x, other_target_x) + other_size.x * 0.5 + NPC_LANE_RESERVATION_PADDING
		var candidate_left: float = candidate_x - candidate_size.x * 0.5
		var candidate_right: float = candidate_x + candidate_size.x * 0.5
		if candidate_right <= other_path_left or candidate_left >= other_path_right:
			continue
		var clearance: float = absf(center_y - float(other.get("y", center_y))) - (candidate_size.y + other_size.y) * 0.5
		var relative_speed: float = absf(speed - float(other.get("speed", speed)))
		var dynamic_margin: float = relative_speed * PLAYER_SPEED_SCALE * float(profile.get("reaction_time", 0.30))
		var braking_margin: float = relative_speed * relative_speed / (2.0 * NPC_BRAKE_DECELERATION) * PLAYER_SPEED_SCALE
		var required_clearance: float = maxf(NPC_SPAWN_MIN_CLEARANCE, float(profile.get("follow_gap", 120.0)) * 0.35 + dynamic_margin + minf(braking_margin, 120.0))
		if clearance < required_clearance:
			return false
	return true


## 在目标刷新车道不可用时尝试相邻车道，空间不足则延迟刷新而不是硬插入。
func _spawn_traffic_if_safe(kind: String, preferred_lane: int, center_y: float, speed: float, aggressive: bool, driver_type: String) -> bool:
	for offset in range(LANE_COUNT):
		var candidate_lane: int = posmod(preferred_lane + offset, LANE_COUNT)
		if not _spawn_gap_is_clear(kind, candidate_lane, center_y, speed, driver_type):
			continue
		_spawn_traffic(kind, candidate_lane, center_y, speed, aggressive, driver_type)
		_ensure_new_car_clearance(traffic[traffic.size() - 1])
		return true
	return false


## 经过玩家、障碍物、车身间距和预约检查后提交一次普通变道意图。
func _try_commit_lane_change(car: Dictionary, target_lane: int, reason: String, snapshot: Array = []) -> bool:
	var current_lane: int = int(car.get("lane", 0))
	if target_lane < 0 or target_lane >= LANE_COUNT or target_lane == current_lane:
		return false
	var target_x: float = _overtake_target_x(car, target_lane)
	if not _player_target_is_safe(car, target_x):
		return false
	if not _overtake_route_is_clear(car, target_lane, target_x, 220.0):
		return false
	if _overtake_lane_score(car, target_lane, snapshot) <= -100000000.0:
		return false
	if not _claim_lateral_reservation(car, target_lane, target_x):
		return false
	car["target_lane"] = target_lane
	car["indicator"] = signi(target_lane - current_lane)
	car["state"] = "AVOID" if reason == "AVOID" else "LANE CHANGE"
	car["maneuver_reason"] = reason
	car["lane_change_commit_timer"] = NPC_LANE_COMMIT_DURATION
	car["lateral_target_x"] = target_x
	car["pressure"] = maxf(float(car.get("pressure", 0.0)), 1.0)
	return true


## 触发一次玩家误导类道具造成的突发减速，实际车速仍按物理刹车率下降。
func _trigger_npc_speed_shock(car: Dictionary, source: String) -> void:
	if bool(car.get("speed_shock_latched", false)):
		return
	car["speed_shock_target"] = NPC_SPEED_SHOCK_TARGET
	car["speed_command"] = NPC_SPEED_SHOCK_TARGET
	car["speed_shock_timer"] = NPC_SPEED_SHOCK_DURATION
	car["speed_shock_memory_timer"] = NPC_SPEED_SHOCK_MEMORY
	car["speed_shock_source"] = source
	car["speed_shock_latched"] = true
	car["brake_reason"] = "PLAYER_ITEM"
	car["pressure"] = maxf(float(car.get("pressure", 0.0)), 2.0)


func _apply_signal_pressure(car: Dictionary, current_lane: int, car_y: float) -> void:
	var gap: float = car_y - player_y
	if gap <= 0.0 or gap > NPC_SPEED_SHOCK_RESET_DISTANCE:
		car["speed_shock_latched"] = false
		return
	var player_traffic_area: bool = _car_path_overlaps_player_x(car)
	if not player_traffic_area:
		car["speed_shock_latched"] = false
	if _has_item("FAKE BRAKE LIGHT") and gap < 310.0 and player_traffic_area:
		car["pressure"] = maxf(float(car["pressure"]), 1.25)
		if not bool(car["attempted_pass"]) and gap < 235.0:
			car["state"] = "BRAKE"
		_trigger_npc_speed_shock(car, "PLAYER_ITEM")
	if _has_active_effect("BLACK SMOKE") and gap < 260.0 and player_traffic_area:
		car["pressure"] = maxf(float(car["pressure"]), 1.5)
		_trigger_npc_speed_shock(car, "PLAYER_ITEM")
	if _has_active_effect("FAKE TURN SIGNAL") and gap < 330.0:
		car["pressure"] = maxf(float(car.get("pressure", 0.0)), 2.0)
		if not bool(car["attempted_pass"]) and not bool(car["passed"]) and float(car.get("player_avoid_timer", 0.0)) <= 0.0:
			var signal_snapshot: Array[Dictionary] = _build_traffic_snapshot()
			if _start_overtake_attempt(car, signal_snapshot):
				car["maneuver_reason"] = "SIGNAL_PRESSURE"
	if _has_active_effect("FAKE POLICE LIGHT") and gap < 360.0 and not bool(car.get("police_reacted", false)):
		var target_lane: int = _most_crowded_neighbor(current_lane)
		if target_lane != current_lane:
			if _try_commit_lane_change(car, target_lane, "POLICE_PRESSURE"):
				car["police_reacted"] = true
				car["pressure"] = maxf(float(car["pressure"]), 3.0)
			else:
				car["maneuver_reason"] = "BLOCKED_ROUTE"


func _most_crowded_neighbor(current_lane: int) -> int:
	var candidates: Array[int] = []
	if current_lane > 0:
		candidates.append(current_lane - 1)
	if current_lane < LANE_COUNT - 1:
		candidates.append(current_lane + 1)
	if candidates.is_empty():
		return current_lane
	var best_lane: int = candidates[0]
	var best_count: int = -1
	for candidate in candidates:
		var count: int = 0
		for car in traffic:
			if bool(car["crashed"]):
				continue
			if candidate in _lanes_touched_by_car(car) and absf(float(car["y"]) - player_y) < 330.0:
				count += 1
		if count > best_count:
			best_count = count
			best_lane = candidate
	return best_lane


func _hazard_overlaps_lane(hazard: Dictionary, lane: int) -> bool:
	var hazard_width: float = float(hazard.get("width", lane_width * 0.45))
	var lane_left: float = road_left + float(lane) * lane_width
	var lane_right: float = lane_left + lane_width
	var hazard_left: float = float(hazard["x"]) - hazard_width * 0.5
	var hazard_right: float = float(hazard["x"]) + hazard_width * 0.5
	return hazard_right > lane_left + 5.0 and hazard_left < lane_right - 5.0


func _lane_has_route_blocker(lane: int, center_y: float, look_ahead: float) -> bool:
	for hazard in hazards:
		if not bool(hazard["active"]) or not bool(hazard.get("blocks_route", false)):
			continue
		var gap: float = center_y - float(hazard["y"])
		if gap > 0.0 and gap < look_ahead and _hazard_overlaps_lane(hazard, lane):
			return true
	for road_event in road_events:
		if not bool(road_event.get("active", true)):
			continue
		var event_gap: float = center_y - float(road_event["y"])
		if event_gap > 0.0 and event_gap < look_ahead and _road_event_blocks_lane(road_event, lane):
			return true
	for prop in loose_props:
		if not bool(prop.get("active", true)) or not bool(prop.get("dangerous", false)):
			continue
		var prop_gap: float = center_y - float(prop["y"])
		var prop_width: float = 40.0 if str(prop.get("type", "")) == "TRASH CAN" else 46.0
		var lane_left: float = road_left + float(lane) * lane_width
		var lane_right: float = lane_left + lane_width
		var prop_left: float = float(prop["x"]) - prop_width * 0.5
		var prop_right: float = float(prop["x"]) + prop_width * 0.5
		if prop_gap > 0.0 and prop_gap < look_ahead and prop_right > lane_left + 5.0 and prop_left < lane_right - 5.0:
			return true
	return _moving_barrier_blocks_lane(lane, center_y)


func _update_hazards(delta: float) -> void:
	for hazard in hazards:
		if not bool(hazard.get("active", true)):
			continue
		var hazard_type: String = str(hazard["type"])
		var world_speed: float = player_speed * PLAYER_SPEED_SCALE
		if hazard_type == "ROGUE CART":
			world_speed = (player_speed - float(hazard.get("forward_speed", 58.0))) * PLAYER_SPEED_SCALE
		hazard["y"] = float(hazard["y"]) + world_speed * delta
		hazard["life"] = float(hazard["life"]) - delta
		if hazard_type == "TIRE":
			hazard["x"] = float(hazard["x"]) + float(hazard["x_velocity"]) * delta
			if float(hazard["x"]) < road_left + 28.0 or float(hazard["x"]) > road_left + road_width - 28.0:
				hazard["x_velocity"] = -float(hazard["x_velocity"])
			hazard["x"] = clampf(float(hazard["x"]), road_left + 28.0, road_left + road_width - 28.0)
		elif hazard_type == "ROGUE CART":
			hazard["x"] = clampf(float(hazard["x"]) + sin(run_time * 3.1 + float(hazard.get("phase", 0.0))) * 42.0 * delta, road_left + 26.0, road_left + road_width - 26.0)
		elif hazard_type == "GIANT MATTRESS" and str(hazard.get("stage", "FLYING")) == "FLYING":
			hazard["flight_time"] = float(hazard.get("flight_time", 1.6)) - delta
			hazard["flight_height"] = sin(clampf(1.0 - float(hazard["flight_time"]) / 1.6, 0.0, 1.0) * PI) * 95.0
			if float(hazard["flight_time"]) <= 0.0:
				var landing_lane: int = rng.randi_range(0, LANE_COUNT - 1)
				hazard["x"] = _lane_x(landing_lane)
				hazard["stage"] = "LANDED"
				hazard["blocks_route"] = true
				hazard["persistent"] = true
				hazard["width"] = lane_width * 0.96
				hazard["height"] = 72.0
				_push_message("巨大床垫落地  /  车道被占", COLOR_WARNING, 2.0)
				_register_event("床垫落地  /  随机封道", 72, Vector2(float(hazard["x"]), float(hazard["y"])), COLOR_WARNING)
		elif hazard_type == "INFLATABLE POOL":
			var inflate: float = minf(float(hazard.get("inflate", 0.15)) + delta / 2.5, 1.0)
			hazard["inflate"] = inflate
			hazard["width"] = lane_width * (0.30 + inflate * 0.70)
			if inflate >= 1.0:
				hazard["blocks_route"] = true


func _update_loose_props(delta: float) -> void:
	for prop in loose_props:
		if not bool(prop.get("active", true)):
			continue
		if bool(prop.get("pulled", false)) and _has_active_effect("MAGNET"):
			var prop_index: int = int(prop.get("index", 0))
			var target: Vector2 = Vector2(player_x + float(prop_index - 1) * 32.0, player_y + 105.0 + float(prop_index) * 22.0)
			prop["x"] = move_toward(float(prop["x"]), target.x, 330.0 * delta)
			prop["y"] = move_toward(float(prop["y"]), target.y, 330.0 * delta)
		else:
			prop["y"] = float(prop["y"]) + player_speed * PLAYER_SPEED_SCALE * delta
		if bool(prop.get("pulled", false)) and not _has_active_effect("MAGNET"):
			prop["pulled"] = false
			prop["dangerous"] = true
		if float(prop["y"]) > screen_size.y + 180.0:
			prop["active"] = false


func _update_road_events(delta: float) -> void:
	for road_event in road_events:
		road_event["y"] = float(road_event["y"]) + player_speed * PLAYER_SPEED_SCALE * delta
		road_event["life"] = float(road_event["life"]) - delta


func _update_pickups(delta: float) -> void:
	for pickup in pickups:
		pickup["y"] = float(pickup["y"]) + player_speed * PLAYER_SPEED_SCALE * delta
		if bool(pickup["collected"]):
			continue
		if absf(float(pickup["y"]) - player_y) < 58.0 and absf(float(pickup["x"]) - player_x) < 62.0:
			pickup["collected"] = true
			item_count += 1
			_receive_item(str(pickup["item"]), "环境拾取")
			_register_event("神秘道具  /  " + _localized_item(str(pickup["item"])), 35, Vector2(float(pickup["x"]), player_y), COLOR_WARNING)


func _refresh_traffic_metrics() -> void:
	var trapped_count: int = 0
	for car in traffic:
		var is_trapped: bool = false
		if bool(car["crashed"]):
			is_trapped = bool(car.get("attributed", false)) and float(car["crash_time"]) < 3.0
		else:
			var state: String = str(car["state"])
			is_trapped = float(car["pressure"]) > 0.5 and (state == "BRAKE" or state == "BLOCKED" or state == "WAIT" or float(car["speed"]) < 33.0)
		car["trapped"] = is_trapped
		if is_trapped:
			trapped_count += 1
	vehicles_trapped = trapped_count
	chaos_multiplier = 1.0 + minf(float(vehicles_trapped) * 0.08, 1.2)


func _resolve_hazard_collisions() -> void:
	for i in range(traffic.size()):
		var car: Dictionary = traffic[i]
		if bool(car["crashed"]):
			continue
		for hazard in hazards:
			if not bool(hazard.get("active", true)) or not bool(hazard.get("collision", true)):
				continue
			if float(car.get("hazard_cooldown", 0.0)) > 0.0:
				continue
			var car_size: Vector2 = _car_dimensions(str(car["kind"]))
			var hazard_size := Vector2(float(hazard.get("width", 60.0)), float(hazard.get("height", 60.0)))
			if not _rects_overlap(Vector2(float(car["x"]), float(car["y"])), car_size, Vector2(float(hazard["x"]), float(hazard["y"])), hazard_size):
				continue
			var hazard_type: String = str(hazard["type"])
			if hazard_type == "OIL":
				car["slip"] = 1.3
				car["x_velocity"] = -170.0 if float(car["x"]) > player_x else 170.0
				car["pressure"] = 3.0
				car["hazard_cooldown"] = 0.65
				_register_event("漏油  /  车辆打滑", 68, Vector2(float(car["x"]), float(car["y"])), COLOR_WARNING)
			elif hazard_type == "BANANA CART":
				hazard["active"] = false
				car["slip"] = 2.2
				car["x_velocity"] = -190.0 if float(car["x"]) > player_x else 190.0
				car["pressure"] = 3.0
				car["hazard_cooldown"] = 0.65
				_register_event("香蕉车厢  /  后车打滑", 92, Vector2(float(car["x"]), float(car["y"])), COLOR_WARNING)
			elif hazard_type == "TIRE":
				hazard["active"] = false
				car["x_velocity"] = float(hazard["x_velocity"]) * 0.8
				car["pressure"] = 3.0
				_crash_car(i, true, Vector2(float(car["x"]), float(car["y"])), "轮胎大乱", "ENVIRONMENT")
			else:
				if not bool(hazard.get("persistent", false)):
					hazard["active"] = false
				car["pressure"] = 3.0
				_crash_car(i, true, Vector2(float(car["x"]), float(car["y"])), "间接碰撞", "ENVIRONMENT")
			break
	_resolve_loose_prop_collisions()


func _resolve_loose_prop_collisions() -> void:
	for i in range(traffic.size()):
		var car: Dictionary = traffic[i]
		if bool(car["crashed"]) or float(car.get("hazard_cooldown", 0.0)) > 0.0:
			continue
		var car_size: Vector2 = _car_dimensions(str(car["kind"]))
		for prop in loose_props:
			if not bool(prop.get("active", true)) or not bool(prop.get("dangerous", false)):
				continue
			var prop_size := Vector2(46.0, 54.0)
			if str(prop.get("type", "")) == "TRASH CAN":
				prop_size = Vector2(40.0, 50.0)
			if _rects_overlap(Vector2(float(car["x"]), float(car["y"])), car_size, Vector2(float(prop["x"]), float(prop["y"])), prop_size):
				prop["dangerous"] = false
				car["hazard_cooldown"] = 0.45
				car["pressure"] = 3.0
				_crash_car(i, true, Vector2(float(car["x"]), float(car["y"])), "路边杂物引发事故", "ENVIRONMENT")
				break


## 判断事故车辆在短暂演出期间是否仍是其他 NPC 的实体障碍。
func _npc_is_collision_blocker(car: Dictionary) -> bool:
	return not bool(car.get("crashed", false)) or float(car.get("crash_time", 0.0)) < NPC_CRASH_BLOCK_DURATION


## 计算两辆 NPC 接触时的纵向或横向相对冲击速度。
func _npc_contact_speed(first: Dictionary, second: Dictionary, delta: float) -> float:
	if delta <= 0.0:
		return 0.0
	var first_speed: float = 0.0 if bool(first.get("crashed", false)) else float(first.get("speed", 0.0))
	var second_speed: float = 0.0 if bool(second.get("crashed", false)) else float(second.get("speed", 0.0))
	var first_y: float = float(first.get("y", 0.0))
	var second_y: float = float(second.get("y", 0.0))
	var rear_speed: float = first_speed if first_y >= second_y else second_speed
	var front_speed: float = second_speed if first_y >= second_y else first_speed
	var closing_speed: float = maxf(rear_speed - front_speed, 0.0)
	var first_lateral_speed: float = (float(first.get("x", 0.0)) - float(first.get("previous_x", first.get("x", 0.0)))) / delta / PLAYER_SPEED_SCALE
	var second_lateral_speed: float = (float(second.get("x", 0.0)) - float(second.get("previous_x", second.get("x", 0.0)))) / delta / PLAYER_SPEED_SCALE
	var first_state: String = str(first.get("state", "CRUISE"))
	var second_state: String = str(second.get("state", "CRUISE"))
	var lateral_maneuver: bool = first_state in ["LANE CHANGE", "AVOID", "MERGING", "PASS PLAYER"] or second_state in ["LANE CHANGE", "AVOID", "MERGING", "PASS PLAYER"] or int(first.get("target_lane", first.get("lane", 0))) != int(first.get("lane", 0)) or int(second.get("target_lane", second.get("lane", 0))) != int(second.get("lane", 0))
	var different_declared_lanes: bool = int(first.get("lane", 0)) != int(second.get("lane", 0))
	if (lateral_maneuver or different_declared_lanes) and _npc_side_contact(first, second):
		return absf(first_lateral_speed - second_lateral_speed)
	return closing_speed


## 返回一对车辆接触是否由玩家道具、障碍或既有事故直接诱发。
func _npc_contact_cause(first: Dictionary, second: Dictionary) -> String:
	for car in [first, second]:
		var crash_cause: String = str(car.get("crash_cause", ""))
		if crash_cause == "PLAYER_ITEM_CHAIN" or crash_cause == "ENVIRONMENT" or crash_cause == "PLAYER_SIDE_COLLISION":
			return crash_cause
		if float(car.get("speed_shock_memory_timer", 0.0)) > 0.0 and str(car.get("speed_shock_source", "")) == "PLAYER_ITEM":
			return "PLAYER_ITEM_CHAIN"
	return ""


## 判断接触的最小穿透方向，用于选择纵向或横向的无伤分离方式。
func _npc_side_contact(first: Dictionary, second: Dictionary) -> bool:
	var first_size: Vector2 = _car_dimensions(str(first.get("kind", "SEDAN")))
	var second_size: Vector2 = _car_dimensions(str(second.get("kind", "SEDAN")))
	var penetration_x: float = (first_size.x + second_size.x) * 0.5 - absf(float(first.get("x", 0.0)) - float(second.get("x", 0.0)))
	var penetration_y: float = (first_size.y + second_size.y) * 0.5 - absf(float(first.get("y", 0.0)) - float(second.get("y", 0.0)))
	return penetration_x < penetration_y


## 对低冲击 NPC 接触做无伤分离、限速和短暂的碰撞冷却。
func _separate_npc_contact(first: Dictionary, second: Dictionary) -> void:
	var first_crashed: bool = bool(first.get("crashed", false))
	var second_crashed: bool = bool(second.get("crashed", false))
	if first_crashed and second_crashed:
		return
	if _npc_side_contact(first, second):
		var direction: float = -1.0 if float(first.get("x", 0.0)) <= float(second.get("x", 0.0)) else 1.0
		var first_size: Vector2 = _car_dimensions(str(first.get("kind", "SEDAN")))
		var second_size: Vector2 = _car_dimensions(str(second.get("kind", "SEDAN")))
		var overlap: float = (first_size.x + second_size.x) * 0.5 - absf(float(first.get("x", 0.0)) - float(second.get("x", 0.0))) + NPC_CONTACT_SEPARATION
		if not first_crashed:
			first["x"] = _clamp_car_center_x(float(first.get("x", 0.0)) + direction * overlap * 0.5, first_size.x)
			first["lateral_target_x"] = first["x"]
			first["speed"] = minf(float(first.get("speed", 0.0)), float(first.get("speed_command", first.get("speed", 0.0))))
			first["brake_reason"] = "CONTACT"
			first["contact_cooldown"] = 0.35
		if not second_crashed:
			second["x"] = _clamp_car_center_x(float(second.get("x", 0.0)) - direction * overlap * 0.5, second_size.x)
			second["lateral_target_x"] = second["x"]
			second["speed"] = minf(float(second.get("speed", 0.0)), float(second.get("speed_command", second.get("speed", 0.0))))
			second["brake_reason"] = "CONTACT"
			second["contact_cooldown"] = 0.35
		return
	var first_is_front: bool = float(first.get("y", 0.0)) <= float(second.get("y", 0.0))
	var front: Dictionary = first if first_is_front else second
	var rear: Dictionary = second if first_is_front else first
	if bool(rear.get("crashed", false)):
		return
	var safe_y: float = float(front.get("y", 0.0)) + (_car_dimensions(str(front.get("kind", "SEDAN"))).y + _car_dimensions(str(rear.get("kind", "SEDAN"))).y) * 0.5 + NPC_CONTACT_SEPARATION
	rear["y"] = maxf(float(rear.get("y", safe_y)), safe_y)
	rear["speed"] = minf(float(rear.get("speed", 0.0)), _front_vehicle_speed(front))
	rear["speed_command"] = minf(float(rear.get("speed_command", rear.get("speed", 0.0))), _front_vehicle_speed(front))
	rear["brake_reason"] = "CONTACT"
	rear["contact_cooldown"] = 0.35
	if str(rear.get("state", "")) == "PASS PLAYER" or str(rear.get("state", "")) == "LANE CHANGE" or str(rear.get("state", "")) == "AVOID":
		rear["state"] = "FOLLOW"
	rear["target_lane"] = int(rear.get("lane", 0))
	rear["indicator"] = 0
	_set_lateral_target(rear, int(rear.get("lane", 0)))


## 只在实际冲击速度达到阈值时把 NPC-NPC 接触记为事故。
func _should_crash_npc_contact(_first: Dictionary, _second: Dictionary, impact_speed: float) -> bool:
	if impact_speed < NPC_CONTACT_SPEED_THRESHOLD:
		return false
	return true


func _resolve_npc_collisions(delta: float = 1.0 / 60.0) -> void:
	for i in range(traffic.size()):
		var first: Dictionary = traffic[i]
		if not _npc_is_collision_blocker(first):
			continue
		for j in range(i + 1, traffic.size()):
			var second: Dictionary = traffic[j]
			if not _npc_is_collision_blocker(second):
				continue
			if bool(first.get("crashed", false)) and bool(second.get("crashed", false)):
				continue
			if float(first.get("contact_cooldown", 0.0)) > 0.0 or float(second.get("contact_cooldown", 0.0)) > 0.0:
				continue
			if _rects_overlap(Vector2(float(first["x"]), float(first["y"])), _car_dimensions(str(first["kind"])), Vector2(float(second["x"]), float(second["y"])), _car_dimensions(str(second["kind"]))):
				var impact_speed: float = _npc_contact_speed(first, second, delta)
				var contact_cause: String = _npc_contact_cause(first, second)
				var impact_pos := (Vector2(float(first["x"]), float(first["y"])) + Vector2(float(second["x"]), float(second["y"]))) * 0.5
				if _should_crash_npc_contact(first, second, impact_speed):
					var attributed: bool = not contact_cause.is_empty()
					var cause: String = contact_cause if not contact_cause.is_empty() else "TRAFFIC_IMPACT"
					_crash_car(i, attributed, impact_pos, "间接碰撞" if attributed else "交通事故", cause)
					_crash_car(j, attributed, impact_pos + Vector2(8.0, 12.0), "间接碰撞" if attributed else "交通事故", cause)
				else:
					_separate_npc_contact(first, second)
				break


## 对非玩家主动侧撞造成的重叠做无伤分离和短暂避让。
func _correct_non_side_player_overlap(car: Dictionary) -> void:
	var car_size: Vector2 = _car_dimensions(str(car.get("kind", "SEDAN")))
	var player_size: Vector2 = _player_body_size()
	var car_y: float = float(car.get("y", player_y))
	var separation: float = (car_size.y + player_size.y) * 0.5 + PLAYER_REAR_BUFFER
	if car_y >= player_y:
		car["y"] = maxf(car_y, player_y + separation)
		car["speed"] = minf(float(car.get("speed", player_speed)), player_speed)
	else:
		car["y"] = minf(car_y, player_y - separation)
	if str(car.get("state", "")) == "PASS PLAYER" or str(car.get("state", "")) == "LANE CHANGE" or str(car.get("state", "")) == "AVOID":
		car["state"] = "BRAKE"
		car["target_lane"] = int(car.get("lane", 0))
		car["indicator"] = 0
	car["player_avoid_timer"] = PLAYER_AVOID_DURATION
	car["pressure"] = maxf(float(car.get("pressure", 0.0)), 1.5)


func _resolve_player_collisions() -> void:
	for i in range(traffic.size()):
		var car: Dictionary = traffic[i]
		if bool(car["crashed"]):
			continue
		if _rects_overlap(Vector2(float(car["x"]), float(car["y"])), _car_dimensions(str(car["kind"])), Vector2(player_x, player_y), _player_body_size()):
			if player_collision_cooldown <= 0.0 and _player_is_cutting_into_car(car):
				_crash_car(i, false, Vector2(float(car["x"]), float(car["y"])), "侧向碰撞", "PLAYER_SIDE_COLLISION")
				_take_damage(2, "侧向碰撞  -2")
				player_collision_cooldown = 0.85
				return
			_correct_non_side_player_overlap(car)


func _crash_car(index: int, attributed: bool, position: Vector2, label: String, cause: String = "") -> void:
	if index < 0 or index >= traffic.size():
		return
	var car: Dictionary = traffic[index]
	if bool(car["crashed"]):
		return
	car["crashed"] = true
	car["attributed"] = attributed
	car["crash_cause"] = cause if not cause.is_empty() else ("ENVIRONMENT" if attributed else "TRAFFIC_IMPACT")
	car["state"] = "CRASH"
	car["crash_time"] = 0.0
	car["spin_angle"] = 0.0
	car["spin_speed"] = rng.randf_range(-5.0, 5.0)
	if absf(float(car["x_velocity"])) < 30.0:
		car["x_velocity"] = rng.randf_range(-100.0, 100.0)
	_spawn_burst(position, COLOR_WARNING if attributed else COLOR_DANGER, 12)
	_register_event(label, 115 if attributed else 25, position, COLOR_WARNING if attributed else COLOR_DANGER)


func _register_overtake(car: Dictionary) -> void:
	if run_time - last_overtake_damage_time >= 2.0:
		last_overtake_damage_time = run_time
		durability = maxi(durability - 1, 0)
		_push_message("被超车  -1", COLOR_DANGER, 2.2)
		_add_floating_text(Vector2(float(car["x"]), player_y - 95.0), "被超车 -1", COLOR_DANGER, 1.2)
		_spawn_burst(Vector2(float(car["x"]), player_y - 90.0), COLOR_DANGER, 6)
		if durability <= 0:
			game_over = true
			_push_message("耐久归零  /  按 R 重开", COLOR_DANGER, 5.0)
	else:
		_push_message("被超车  /  伤害保护间隔", COLOR_WARNING, 1.0)


func _take_damage(amount: int, label: String) -> void:
	durability = maxi(durability - amount, 0)
	_push_message(label, COLOR_DANGER, 2.0)
	flash_alpha = maxf(flash_alpha, 0.35)
	shake_trauma = minf(shake_trauma + 0.5, 1.0)
	if durability <= 0:
		game_over = true
		_push_message("游戏结束  /  按 R 重开", COLOR_DANGER, 5.0)


func _register_event(label: String, points: int, position: Vector2, color: Color) -> void:
	_refresh_traffic_metrics()
	if chain_timer <= 0.0:
		chain_count = 0
	chain_count += 1
	chain_timer = 3.0
	if combo_timer > 0.0:
		combo += 1
	else:
		combo = 1
	combo_timer = 3.0
	var base_award: int = points + maxi(combo - 1, 0) * 12
	var build_multiplier: float = 1.35 if _has_item("SLOW MODE") else 1.0
	var awarded: int = int(round(float(base_award) * chaos_multiplier * build_multiplier))
	score += awarded
	var suffix: String = "  /  连锁 ×%d" % chain_count if chain_count > 1 else ""
	if chaos_multiplier > 1.05:
		suffix += "  /  堵塞倍率 ×%.1f" % chaos_multiplier
	_push_message(label + suffix + "  +%d" % awarded, color, 2.8)
	_add_floating_text(position, "+%d  %s" % [awarded, label], color, 1.5)
	_spawn_burst(position, color, 7 if points < 100 else 14)
	shake_trauma = minf(shake_trauma + (0.18 if points < 100 else 0.36), 1.0)
	flash_alpha = maxf(flash_alpha, 0.08 if points < 100 else 0.18)


func _handle_item_selection() -> void:
	var selected: int = -1
	if Input.is_action_just_pressed("select_item_1"):
		selected = 0
	elif Input.is_action_just_pressed("select_item_2"):
		selected = 1
	elif Input.is_action_just_pressed("select_item_3"):
		selected = 2
	if selected >= 0:
		selected_item_slot = selected
		_use_item_at_slot(selected)


func _receive_item(item_key: String, source: String) -> void:
	if not item_definitions.has(item_key):
		return
	var empty_slot: int = _first_empty_item_slot()
	if empty_slot >= 0:
		item_slots[empty_slot] = item_key
		selected_item_slot = empty_slot
		_push_message("%s  /  %s → 槽位 %d" % [source, _localized_item(item_key), empty_slot + 1], COLOR_WARNING, 2.0)
		if _is_passive_item(item_key):
			_push_message("被动效果已生效  /  " + _item_description(item_key), COLOR_ACCENT, 2.6)
	else:
		pending_pickup_item = item_key
		pending_replacement_source = source
		item_replacement_active = true
		_push_message("道具槽已满  /  请选择要替换的槽位", COLOR_WARNING, 3.0)


func _handle_item_replacement_input() -> void:
	var selected: int = -1
	if Input.is_action_just_pressed("choose_1"):
		selected = 0
	elif Input.is_action_just_pressed("choose_2"):
		selected = 1
	elif Input.is_action_just_pressed("choose_3"):
		selected = 2
	if selected < 0 or pending_pickup_item.is_empty():
		return
	var replaced_item: String = item_slots[selected]
	item_slots[selected] = pending_pickup_item
	selected_item_slot = selected
	item_replacement_active = false
	upgrade_cooldown_remaining = maxf(upgrade_cooldown_remaining, UPGRADE_MODAL_GAP_SECONDS)
	_push_message("已替换槽位 %d  /  %s → %s" % [selected + 1, _localized_item(replaced_item), _localized_item(pending_pickup_item)], COLOR_WARNING, 2.4)
	if _is_passive_item(pending_pickup_item):
		_push_message("被动效果已生效  /  " + _item_description(pending_pickup_item), COLOR_ACCENT, 2.4)
	pending_pickup_item = ""
	pending_replacement_source = ""


func _first_empty_item_slot() -> int:
	for index in range(item_slots.size()):
		if str(item_slots[index]).is_empty():
			return index
	return -1


func _use_item() -> void:
	_use_item_at_slot(selected_item_slot)


func _use_item_at_slot(slot_index: int) -> void:
	selected_item_slot = clampi(slot_index, 0, ITEM_SLOT_COUNT - 1)
	var used_item: String = str(item_slots[selected_item_slot])
	if used_item.is_empty():
		_push_message("按 %d  /  当前槽位为空" % (selected_item_slot + 1), COLOR_WARNING, 1.2)
		return
	if _is_passive_item(used_item):
		_push_message("被动已生效  /  " + _localized_item(used_item), COLOR_INFO, 1.2)
		return
	if item_cooldown_remaining > 0.0:
		_push_message("共享冷却  /  %.1f 秒后可用" % item_cooldown_remaining, COLOR_WARNING, 1.2)
		return
	item_cooldown_remaining = ITEM_COOLDOWN_SECONDS
	item_use_count += 1
	_activate_item(used_item)
	_push_message("已使用  /  " + _localized_item(used_item), COLOR_WARNING, 1.8)
	_add_floating_text(Vector2(player_x, player_y + 25.0), _localized_item(used_item), COLOR_WARNING, 1.2)


func _activate_item(item_key: String) -> void:
	var drop_y: float = player_y + 116.0
	match item_key:
		"SOFA DROP":
			_drop_hazard("SOFA", player_x, drop_y, 10.0)
		"ROLLING TIRE":
			_drop_hazard("TIRE", player_x, drop_y, 8.0, {"x_velocity": -185.0 if rng.randf() < 0.5 else 185.0})
		"BANANA CART":
			_drop_hazard("BANANA CART", player_x, drop_y, 8.0)
		"FAKE TURN SIGNAL":
			var signal_side: int = -1 if player_steer < -0.1 else (1 if player_steer > 0.1 else (-1 if player_lane > 0 else 1))
			_start_effect(item_key, 5.0, {"side": signal_side})
		"LONG TRAILER":
			_start_effect(item_key, 5.0)
		"POPCORN MACHINE":
			_start_effect(item_key, 5.0, {"clock": 0.0})
		"ROADWORK SIGN":
			_drop_hazard("ROADWORK SIGN", _lane_x(player_lane), drop_y, 8.0, {"lane": player_lane})
		"GIANT MATTRESS":
			_drop_hazard("GIANT MATTRESS", player_x, drop_y, 9.6, {"stage": "FLYING", "flight_time": 1.6, "flight_height": 0.0, "collision": false, "blocks_route": false, "width": 100.0, "height": 62.0})
		"MAGNET":
			_pull_loose_props()
			_start_effect(item_key, 4.0)
		"PAINT LEAK":
			_drop_hazard("PAINT", _lane_x(player_lane), drop_y, 9.0, {"lane": player_lane, "width": lane_width * 0.92, "height": 118.0})
		"FAKE POLICE LIGHT":
			for car in traffic:
				car["police_reacted"] = false
			_start_effect(item_key, 5.0)
			_trigger_fake_police()
		"INFLATABLE POOL":
			_drop_hazard("INFLATABLE POOL", _lane_x(player_lane), drop_y, 10.0, {"lane": player_lane, "inflate": 0.15, "blocks_route": false, "width": lane_width * 0.40, "height": 76.0})
		"ROGUE SHOPPING CART":
			_drop_hazard("ROGUE CART", player_x, drop_y, 9.0, {"forward_speed": 58.0, "phase": rng.randf_range(0.0, TAU)})
		"OIL LEAK":
			_start_effect(item_key, 5.0, {"clock": 0.0})
		"BLACK SMOKE":
			_start_effect(item_key, 5.0)
		"NAIL RAIN":
			_start_effect(item_key, 5.0, {"clock": 0.0})


func _start_effect(effect_key: String, life: float, extra: Dictionary = {}) -> void:
	var effect: Dictionary = {"life": life}
	for key in extra.keys():
		effect[key] = extra[key]
	active_effects[effect_key] = effect


func _update_active_effects(delta: float) -> void:
	var expired: Array[String] = []
	for key_variant in active_effects.keys():
		var key: String = str(key_variant)
		var effect: Dictionary = active_effects[key]
		effect["life"] = float(effect.get("life", 0.0)) - delta
		if key == "OIL LEAK":
			effect["clock"] = float(effect.get("clock", 0.0)) - delta
			while float(effect["clock"]) <= 0.0:
				_drop_hazard("OIL", player_x + rng.randf_range(-24.0, 24.0), player_y + 108.0, 5.0)
				effect["clock"] = float(effect["clock"]) + 0.35
		elif key == "POPCORN MACHINE":
			effect["clock"] = float(effect.get("clock", 0.0)) - delta
			while float(effect["clock"]) <= 0.0:
				_drop_hazard("POPCORN", player_x + rng.randf_range(-56.0, 56.0), player_y + 106.0, 4.0)
				effect["clock"] = float(effect["clock"]) + 0.45
		elif key == "NAIL RAIN":
			effect["clock"] = float(effect.get("clock", 0.0)) - delta
			while float(effect["clock"]) <= 0.0:
				_drop_hazard("NAIL", _lane_x(rng.randi_range(0, LANE_COUNT - 1)), player_y + 116.0, 2.2)
				effect["clock"] = float(effect["clock"]) + 0.75
		if float(effect["life"]) <= 0.0:
			expired.append(key)
		else:
			active_effects[key] = effect
	for key in expired:
		active_effects.erase(key)


func _active_effect_data(effect_key: String) -> Dictionary:
	var data: Variant = active_effects.get(effect_key, {})
	return data if data is Dictionary else {}


func _has_active_effect(effect_key: String) -> bool:
	return active_effects.has(effect_key) and float(_active_effect_data(effect_key).get("life", 0.0)) > 0.0


func _has_item(item_key: String) -> bool:
	return item_key in item_slots


func _is_passive_item(item_key: String) -> bool:
	return item_key in PASSIVE_ITEM_KEYS


func _drop_random_furniture(x: float, y: float, amount: int) -> void:
	var furniture: Array[String] = ["BOX", "CHAIR", "LAMP", "SOFA"]
	for index in range(amount):
		var item_type: String = furniture[rng.randi_range(0, furniture.size() - 1)]
		_drop_hazard(item_type, x + rng.randf_range(-42.0, 42.0), y + float(index) * 26.0, 7.0)


func _drop_hazard(hazard_type: String, x: float, y: float, life: float = 12.0, extra: Dictionary = {}) -> void:
	var velocity_x: float = 0.0
	if hazard_type == "TIRE":
		velocity_x = -185.0 if rng.randf() < 0.5 else 185.0
	var hazard: Dictionary = {
		"type": hazard_type,
		"x": x,
		"y": y,
		"life": life,
		"active": true,
		"x_velocity": velocity_x,
		"width": 52.0,
		"height": 52.0,
		"blocks_route": false,
		"collision": true,
		"persistent": false,
		"stage": "ACTIVE",
	}
	match hazard_type:
		"OIL":
			hazard["width"] = 72.0
			hazard["height"] = 34.0
			hazard["persistent"] = true
		"SOFA":
			hazard["width"] = lane_width * 0.90
			hazard["height"] = 64.0
			hazard["blocks_route"] = true
			hazard["persistent"] = true
		"TIRE":
			hazard["blocks_route"] = true
		"BANANA CART":
			hazard["width"] = 58.0
			hazard["height"] = 54.0
		"POPCORN":
			hazard["width"] = 28.0
			hazard["height"] = 28.0
			hazard["blocks_route"] = true
		"BOX":
			hazard["width"] = 44.0
			hazard["height"] = 44.0
			hazard["blocks_route"] = true
		"CHAIR":
			hazard["width"] = 44.0
			hazard["height"] = 54.0
			hazard["blocks_route"] = true
		"LAMP":
			hazard["width"] = 38.0
			hazard["height"] = 58.0
			hazard["blocks_route"] = true
		"ROADWORK SIGN":
			hazard["width"] = lane_width * 0.92
			hazard["height"] = 72.0
			hazard["blocks_route"] = true
			hazard["collision"] = false
			hazard["persistent"] = true
		"PAINT":
			hazard["height"] = 118.0
			hazard["blocks_route"] = true
			hazard["collision"] = false
			hazard["persistent"] = true
		"GIANT MATTRESS":
			hazard["persistent"] = true
		"INFLATABLE POOL":
			hazard["persistent"] = true
		"ROGUE CART":
			hazard["width"] = 42.0
			hazard["height"] = 58.0
			hazard["blocks_route"] = true
		"NAIL":
			hazard["width"] = 54.0
			hazard["height"] = 24.0
			hazard["blocks_route"] = true
	for key in extra.keys():
		hazard[key] = extra[key]
	hazards.append(hazard)
	_spawn_burst(Vector2(x, y), COLOR_WARNING, 8)


func _seed_loose_props() -> void:
	var prop_types: Array[String] = ["SHOPPING CART", "TRASH CAN", "SHOPPING CART", "TRASH CAN", "SHOPPING CART"]
	for index in range(prop_types.size()):
		loose_props.append({
			"index": index,
			"type": prop_types[index],
			"x": _lane_x(index % LANE_COUNT),
			"y": player_y + 180.0 + float(index) * 96.0,
			"active": true,
			"pulled": false,
			"dangerous": false,
		})


func _pull_loose_props() -> void:
	var pulled_count: int = 0
	for prop in loose_props:
		if not bool(prop.get("active", true)):
			continue
		if absf(float(prop["y"]) - player_y) < 340.0:
			prop["pulled"] = true
			pulled_count += 1
	if pulled_count == 0:
		for index in range(2):
			loose_props.append({
				"index": index,
				"type": "SHOPPING CART" if index == 0 else "TRASH CAN",
				"x": player_x + rng.randf_range(-120.0, 120.0),
				"y": player_y + 190.0 + float(index) * 36.0,
				"active": true,
				"pulled": true,
				"dangerous": false,
			})
		pulled_count = 2
	_register_event("磁铁  /  吸来 %d 件路边杂物" % pulled_count, 78, Vector2(player_x, player_y + 100.0), COLOR_WARNING)


func _build_item_definitions() -> void:
	item_definitions.clear()
	var definitions: Array[Dictionary] = [
		{"key": "SOFA DROP", "title": "掉沙发", "description": "实体障碍，NPC 会绕行。", "kind": "主动", "accent": Color("#d99162")},
		{"key": "ROLLING TIRE", "title": "掉轮胎", "description": "滚动跨车道，撞上就失控。", "kind": "主动", "accent": Color("#a7b0bb")},
		{"key": "BANANA CART", "title": "香蕉车厢", "description": "后车压到后会打滑。", "kind": "主动", "accent": Color("#f6dc65")},
		{"key": "FAKE TURN SIGNAL", "title": "假左/右转灯", "description": "让后车误判你的让道方向。", "kind": "主动", "accent": Color("#ff9e5c")},
		{"key": "LONG TRAILER", "title": "超长拖车", "description": "短时间变成横向封锁器。", "kind": "主动", "accent": Color("#ff786d")},
		{"key": "POPCORN MACHINE", "title": "爆米花机", "description": "持续喷出小型障碍。", "kind": "主动", "accent": Color("#fff0a6")},
		{"key": "BROKEN TRUNK", "title": "坏掉的后备箱", "description": "每次 BRAKE 有概率甩出家具。", "kind": "被动", "accent": Color("#c59063")},
		{"key": "ROADWORK SIGN", "title": "道路施工牌", "description": "让 NPC 把一条车道判断成关闭。", "kind": "主动", "accent": Color("#ffb84f")},
		{"key": "GIANT MATTRESS", "title": "巨大床垫", "description": "飞起后落到随机车道。", "kind": "主动", "accent": Color("#d8b8ff")},
		{"key": "MAGNET", "title": "磁铁", "description": "把路边杂物吸到你的车后。", "kind": "主动", "accent": Color("#83d7ff")},
		{"key": "PAINT LEAK", "title": "漏漆桶", "description": "留下 NPC 误判的不可通行区域。", "kind": "主动", "accent": Color("#ff7ab8")},
		{"key": "FAKE POLICE LIGHT", "title": "假警灯", "description": "后车让道，却挤向更拥挤的车道。", "kind": "主动", "accent": Color("#ff6b8a")},
		{"key": "OVERLOADED RACK", "title": "超载行李架", "description": "变道时随机掉落家具。", "kind": "被动", "accent": Color("#d9a46f")},
		{"key": "INFLATABLE POOL", "title": "充气泳池", "description": "落地膨胀，慢慢盖住整条车道。", "kind": "主动", "accent": Color("#68d8e6")},
		{"key": "ROGUE SHOPPING CART", "title": "失控购物车", "description": "沿路自己跑，持续制造局部混乱。", "kind": "主动", "accent": Color("#a7e3a2")},
		{"key": "OIL LEAK", "title": "漏油", "description": "留下持续一段时间的滑油带。", "kind": "主动", "accent": Color("#7f8b98")},
		{"key": "BLACK SMOKE", "title": "黑烟", "description": "降低后车的视野和反应距离。", "kind": "主动", "accent": Color("#9da7b3")},
		{"key": "SLOW MODE", "title": "龟速模式", "description": "车速更慢，但积分倍率提高。", "kind": "被动", "accent": Color("#f0c26f")},
		{"key": "WIDE BODY", "title": "宽体改装", "description": "车身宽度增加 25%。", "kind": "被动", "accent": Color("#ff8a65")},
		{"key": "SNAKE SWERVE", "title": "蛇皮走位", "description": "车辆周期性轻微自动摆尾。", "kind": "被动", "accent": Color("#bf9cff")},
		{"key": "NAIL RAIN", "title": "钉子雨", "description": "定期掉落短时路障。", "kind": "主动", "accent": Color("#cad1d9")},
		{"key": "FAKE BRAKE LIGHT", "title": "假刹车灯", "description": "让后车更容易误判和急刹。", "kind": "被动", "accent": Color("#ff6b6b")},
		{"key": "MOVING ROADBLOCK", "title": "移动路障", "description": "车后拖一根摇摆护栏。", "kind": "被动", "accent": Color("#ffca70")},
	]
	for definition in definitions:
		item_definitions[str(definition["key"])] = definition


func _item_description(item_key: String) -> String:
	var definition: Dictionary = item_definitions.get(item_key, {})
	return str(definition.get("description", ""))


func _item_slot_title(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= item_slots.size():
		return "空"
	var item_key: String = str(item_slots[slot_index])
	return "空" if item_key.is_empty() else _localized_item(item_key)


func _trigger_fake_police() -> void:
	var affected: int = 0
	for car in traffic:
		if bool(car["crashed"]) or float(car["y"]) <= player_y or float(car["y"]) > player_y + 360.0:
			continue
		var current_lane: int = int(car["lane"])
		var target_lane: int = _most_crowded_neighbor(current_lane)
		if target_lane == current_lane:
			continue
		if _try_commit_lane_change(car, target_lane, "POLICE_PRESSURE"):
			car["police_reacted"] = true
			car["pressure"] = 3.0
			affected += 1
		else:
			car["maneuver_reason"] = "BLOCKED_ROUTE"
	if affected > 0:
		_register_event("假警灯  /  后车挤向拥堵车道", 110, Vector2(player_x, player_y + 120.0), COLOR_WARNING)
	else:
		_push_message("假警灯  /  暂时没有后车上钩", COLOR_WARNING, 1.5)


func _player_body_size() -> Vector2:
	var body_width: float = PLAYER_BASE_BODY_WIDTH
	if _has_item("WIDE BODY"):
		body_width *= 1.25
	if _has_active_effect("LONG TRAILER"):
		body_width = road_width * 0.94
	return Vector2(body_width, 118.0)


func _moving_barrier_position() -> Vector2:
	return Vector2(player_x + sin(run_time * 3.0) * 26.0, player_y + 106.0)


func _moving_barrier_blocks_lane(lane: int, center_y: float) -> bool:
	if not _has_item("MOVING ROADBLOCK"):
		return false
	var barrier: Vector2 = _moving_barrier_position()
	var barrier_left: float = barrier.x - lane_width * 0.40
	var barrier_right: float = barrier.x + lane_width * 0.40
	var lane_left: float = road_left + float(lane) * lane_width
	var lane_right: float = lane_left + lane_width
	return barrier_right > lane_left and barrier_left < lane_right and absf(center_y - barrier.y) < 120.0


func _rects_overlap(first_center: Vector2, first_size: Vector2, second_center: Vector2, second_size: Vector2) -> bool:
	return absf(first_center.x - second_center.x) < (first_size.x + second_size.x) * 0.5 and absf(first_center.y - second_center.y) < (first_size.y + second_size.y) * 0.5


func _spawn_road_event(difficulty: float) -> void:
	var event_type: String = "BRANCH MERGE"
	if road_event_count > 0:
		var event_roll: float = rng.randf()
		event_type = "BRANCH MERGE" if event_roll < 0.45 else ("LANE CLOSURE" if event_roll < 0.73 else "BREAKDOWN")
	var lane: int = rng.randi_range(0, LANE_COUNT - 1)
	var blocked_lanes: Array[int] = [lane]
	if event_type == "LANE CLOSURE" and difficulty > 0.45 and rng.randf() < 0.35:
		var neighbor_lane: int = lane + (1 if lane == 0 else -1)
		blocked_lanes.append(neighbor_lane)
	road_events.append({
		"type": event_type,
		"lane": lane,
		"blocked_lanes": blocked_lanes,
		"x": _lane_x(lane),
		"y": -130.0,
		"life": 16.0,
		"active": true,
		"merge_boost": event_type == "BRANCH MERGE",
	})
	road_event_count += 1
	_push_message("道路事件  /  " + _localized_road_event(event_type), COLOR_INFO, 2.8)
	_add_floating_text(Vector2(_lane_x(lane), 70.0), _localized_road_event(event_type), COLOR_INFO, 1.5)


func _update_spawn_logic(delta: float) -> void:
	spawn_clock += delta
	pickup_clock += delta
	road_event_clock += delta
	var difficulty: float = clampf(run_time / RUN_LIMIT_SECONDS, 0.0, 1.0)
	var max_cars: int = _traffic_target_count(run_time)
	_update_merge_source(delta, difficulty, max_cars)
	var spawn_interval: float = maxf(0.65, 1.45 - difficulty * 0.70)
	if spawn_clock >= spawn_interval and _active_traffic_count() < max_cars:
		var lane: int = rng.randi_range(0, LANE_COUNT - 1)
		var profile: Dictionary = _random_traffic_profile(difficulty)
		var spawn_y: float = screen_size.y + rng.randf_range(90.0, 260.0)
		if _spawn_traffic_if_safe(str(profile["kind"]), lane, spawn_y, float(profile["base_speed"]), bool(profile["aggressive"]), str(profile["driver_type"])):
			spawn_clock = 0.0
		else:
			# 保留大部分计时进度，空间一旦释放即可补发，但不会每个物理帧重复尝试。
			spawn_clock = spawn_interval * 0.82

	if road_event_clock >= 28.0 and road_events.size() < 2 and road_event_count < 12:
		road_event_clock = 0.0
		_spawn_road_event(difficulty)

	if pickup_clock >= 18.0 and pickups.size() < 1 and pickup_count < 3:
		pickup_clock = 0.0
		var lane_for_pickup: int = rng.randi_range(0, LANE_COUNT - 1)
		var possible_items: Array[String] = _available_item_rolls()
		pickups.append({
			"x": _lane_x(lane_for_pickup),
			"y": -90.0,
			"item": possible_items[rng.randi_range(0, possible_items.size() - 1)],
			"collected": false,
		})
		pickup_count += 1
		_push_message("神秘道具出现  /  靠近 ? 自动获得", COLOR_INFO, 2.0)


func _cleanup_entities() -> void:
	for i in range(traffic.size() - 1, -1, -1):
		var car: Dictionary = traffic[i]
		var crash_finished: bool = bool(car.get("crashed", false)) and float(car.get("crash_time", 0.0)) >= TRAFFIC_CRASH_RETENTION_SECONDS
		if crash_finished or float(car["y"]) > screen_size.y + TRAFFIC_CLEANUP_BUFFER or float(car["y"]) < -240.0:
			traffic.remove_at(i)
	for i in range(hazards.size() - 1, -1, -1):
		if not bool(hazards[i]["active"]) or float(hazards[i]["life"]) <= 0.0 or float(hazards[i]["y"]) > screen_size.y + 220.0:
			hazards.remove_at(i)
	for i in range(pickups.size() - 1, -1, -1):
		if bool(pickups[i]["collected"]) or float(pickups[i]["y"]) > screen_size.y + 160.0:
			pickups.remove_at(i)
	for i in range(road_events.size() - 1, -1, -1):
		if not bool(road_events[i].get("active", true)) or float(road_events[i]["life"]) <= 0.0 or float(road_events[i]["y"]) > screen_size.y + 220.0:
			road_events.remove_at(i)
	for i in range(loose_props.size() - 1, -1, -1):
		if not bool(loose_props[i].get("active", true)) or float(loose_props[i]["y"]) > screen_size.y + 220.0:
			loose_props.remove_at(i)


func _check_upgrade_threshold() -> void:
	if upgrade_active or item_replacement_active or next_upgrade_index >= UPGRADE_THRESHOLDS.size():
		return
	if run_time < UPGRADE_FIRST_AVAILABLE_SECONDS or upgrade_cooldown_remaining > 0.0:
		return
	if score < UPGRADE_THRESHOLDS[next_upgrade_index]:
		return
	upgrade_cards.clear()
	var start_index: int = (next_upgrade_index * 2) % upgrade_pool.size()
	for card_index in range(3):
		upgrade_cards.append(upgrade_pool[(start_index + card_index) % upgrade_pool.size()])
	upgrade_active = true
	upgrade_offer_count += 1
	upgrade_offer_times.append(run_time)
	_push_message("混乱升级可选  /  按 1、2、3", COLOR_ACCENT, 3.0)


func _handle_upgrade_input() -> void:
	var selected: int = -1
	if Input.is_action_just_pressed("choose_1"):
		selected = 0
	elif Input.is_action_just_pressed("choose_2"):
		selected = 1
	elif Input.is_action_just_pressed("choose_3"):
		selected = 2
	if selected < 0 or selected >= upgrade_cards.size():
		return
	var card: Dictionary = upgrade_cards[selected]
	next_upgrade_index += 1
	upgrade_active = false
	upgrade_cooldown_remaining = UPGRADE_MIN_INTERVAL_SECONDS
	_receive_item(str(card["key"]), "混乱奖励")
	_register_event("升级  /  " + str(card["title"]), 30, Vector2(player_x, player_y - 70.0), COLOR_ACCENT)
	_push_message("已选择  /  " + str(card["description"]).replace("\n", " "), COLOR_ACCENT, 3.0)


func _available_item_rolls() -> Array[String]:
	var available: Array[String] = []
	for item_key in ITEM_KEYS:
		if not item_key in item_slots:
			available.append(item_key)
	if available.is_empty():
		return ITEM_KEYS.duplicate()
	return available


func _build_upgrade_pool() -> void:
	upgrade_pool.clear()
	for item_key in ITEM_KEYS:
		var definition: Dictionary = item_definitions.get(item_key, {})
		upgrade_pool.append({
			"key": item_key,
			"title": str(definition.get("title", _localized_item(item_key))),
			"description": str(definition.get("description", "")),
			"kind": str(definition.get("kind", "主动")),
			"accent": definition.get("accent", COLOR_ACCENT),
		})


func _update_feedback(delta: float) -> void:
	combo_timer = maxf(combo_timer - delta, 0.0)
	chain_timer = maxf(chain_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo = 0
	if chain_timer <= 0.0:
		chain_count = 0
	shake_trauma = maxf(shake_trauma - delta * 1.35, 0.0)
	shake_phase += delta * 28.0
	flash_alpha = maxf(flash_alpha - delta * 3.0, 0.0)

	for i in range(messages.size() - 1, -1, -1):
		messages[i]["life"] = float(messages[i]["life"]) - delta
		if float(messages[i]["life"]) <= 0.0:
			messages.remove_at(i)
	for i in range(floating_texts.size() - 1, -1, -1):
		floating_texts[i]["life"] = float(floating_texts[i]["life"]) - delta
		floating_texts[i]["position"] = Vector2(floating_texts[i]["position"]) + Vector2(0.0, -24.0 * delta)
		if float(floating_texts[i]["life"]) <= 0.0:
			floating_texts.remove_at(i)
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["life"] = float(particles[i]["life"]) - delta
		particles[i]["position"] = Vector2(particles[i]["position"]) + Vector2(particles[i]["velocity"]) * delta
		particles[i]["velocity"] = Vector2(particles[i]["velocity"]) * 0.94
		if float(particles[i]["life"]) <= 0.0:
			particles.remove_at(i)


func _push_message(text_value: String, color: Color, life: float) -> void:
	messages.push_front({"text": text_value, "color": color, "life": life})
	while messages.size() > 7:
		messages.pop_back()


func _add_floating_text(position: Vector2, text_value: String, color: Color, life: float) -> void:
	floating_texts.append({"position": position, "text": text_value, "color": color, "life": life, "max_life": life})


func _spawn_burst(position: Vector2, color: Color, amount: int) -> void:
	for _index in range(amount):
		particles.append({
			"position": position,
			"velocity": Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(35.0, 145.0),
			"color": color,
			"life": rng.randf_range(0.25, 0.65),
		})


func _draw() -> void:
	_draw_background()
	var shake: Vector2 = _get_shake_offset()
	_draw_road(shake)
	_draw_merge_source(shake)
	_draw_road_events(shake)
	_draw_hazards(shake)
	_draw_loose_props(shake)
	_draw_pickups(shake)
	_draw_traffic(shake)
	_draw_player(shake)
	_draw_particles(shake)
	_draw_floating_texts(shake)
	_draw_hud()
	if paused:
		_draw_center_overlay("已暂停", "Esc  继续游戏")
	elif item_replacement_active:
		_draw_item_replacement_overlay()
	elif upgrade_active:
		_draw_upgrade_overlay()
	elif game_over:
		_draw_center_overlay("游戏结束", "R  重开   /   分数 %d" % score)
	elif run_complete:
		_draw_center_overlay("本局完成", "R  重开   /   分数 %d" % score)
	if flash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(1.0, 0.75, 0.45, flash_alpha * 0.16))


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), COLOR_BG)
	var block_scroll: float = fmod(road_scroll * 0.55, 160.0)
	for side in [-1, 1]:
		var base_x: float = road_left - 22.0 if side < 0 else road_left + road_width + 22.0
		for building_index in range(8):
			var y: float = fmod(float(building_index) * 142.0 + block_scroll, screen_size.y + 170.0) - 150.0
			var width: float = 86.0 + float((building_index * 17) % 48)
			var height: float = 78.0 + float((building_index * 31) % 70)
			var x: float = base_x - width if side < 0 else base_x
			draw_rect(Rect2(x, y, width, height), Color("#111b26"))
			for window_index in range(3):
				var wx: float = x + 12.0 + float(window_index) * 22.0
				if wx < x + width - 8.0:
					draw_rect(Rect2(wx, y + 16.0, 9.0, 12.0), Color(0.95, 0.75, 0.32, 0.14))


## 返回采用统一道路位移规则的平铺起点；道路前进时所有标记的屏幕纵坐标都增大。
func _scroll_pattern_origin(base_y: float, scroll: float, spacing: float) -> float:
	if spacing <= 0.0:
		return base_y
	return base_y + fposmod(scroll, spacing)


func _draw_road(shift: Vector2) -> void:
	var shoulder_rect := Rect2(Vector2(road_left - 42.0, 0.0) + shift, Vector2(road_width + 84.0, screen_size.y))
	if sidewalk_surface_texture != null:
		draw_texture_rect(sidewalk_surface_texture, shoulder_rect, true, Color.WHITE)
	else:
		draw_rect(shoulder_rect, COLOR_SIDEWALK)
	draw_rect(Rect2(Vector2(road_left - 12.0, 0.0) + shift, Vector2(12.0, screen_size.y)), COLOR_CURB)
	draw_rect(Rect2(Vector2(road_left + road_width, 0.0) + shift, Vector2(12.0, screen_size.y)), COLOR_CURB)
	var road_rect := Rect2(Vector2(road_left, 0.0) + shift, Vector2(road_width, screen_size.y))
	if road_surface_texture != null:
		draw_texture_rect(road_surface_texture, road_rect, true, Color.WHITE)
	else:
		draw_rect(road_rect, COLOR_ROAD)
	_draw_road_surface_accents(shift)
	draw_line(Vector2(road_left, 0.0) + shift, Vector2(road_left, screen_size.y) + shift, COLOR_ROAD_EDGE, 4.0)
	draw_line(Vector2(road_left + road_width, 0.0) + shift, Vector2(road_left + road_width, screen_size.y) + shift, COLOR_ROAD_EDGE, 4.0)
	draw_line(Vector2(road_left + 8.0, 0.0) + shift, Vector2(road_left + 8.0, screen_size.y) + shift, Color(0.12, 0.18, 0.20, 0.78), 2.0)
	draw_line(Vector2(road_left + road_width - 8.0, 0.0) + shift, Vector2(road_left + road_width - 8.0, screen_size.y) + shift, Color(0.12, 0.18, 0.20, 0.78), 2.0)
	for lane in range(1, LANE_COUNT):
		var x: float = road_left + lane_width * float(lane)
		var y: float = _scroll_pattern_origin(-96.0, road_scroll, 96.0)
		while y < screen_size.y + 96.0:
			draw_rect(Rect2(Vector2(x - 2.0, y) + shift, Vector2(4.0, 58.0)), Color(0.84, 0.85, 0.76, 0.74))
			draw_rect(Rect2(Vector2(x - 1.0, y + 5.0) + shift, Vector2(2.0, 48.0)), Color(0.97, 0.93, 0.78, 0.28))
			y += 96.0

	var reflector_y: float = _scroll_pattern_origin(-48.0, road_scroll * 0.72, 64.0)
	while reflector_y < screen_size.y + 64.0:
		draw_rect(Rect2(Vector2(road_left + 12.0, reflector_y) + shift, Vector2(4.0, 9.0)), Color(0.40, 0.88, 0.76, 0.54))
		draw_rect(Rect2(Vector2(road_left + road_width - 16.0, reflector_y) + shift, Vector2(4.0, 9.0)), Color(0.40, 0.88, 0.76, 0.54))
		reflector_y += 64.0


## 绘制低对比、随道路滚动的磨损标记，避免平铺材质显得完全静止。
func _draw_road_surface_accents(shift: Vector2) -> void:
	for accent_index in range(10):
		var lane: int = posmod(accent_index * 3 + 1, LANE_COUNT)
		var y: float = fmod(float(accent_index) * 137.0 + road_scroll * 0.38, screen_size.y + 180.0) - 90.0
		var x: float = road_left + lane_width * (float(lane) + 0.18) + float((accent_index * 19) % 28)
		var width: float = 9.0 + float((accent_index * 7) % 18)
		draw_rect(Rect2(Vector2(x, y) + shift, Vector2(width, 3.0)), Color(0.08, 0.12, 0.14, 0.24))


func _draw_merge_source(shift: Vector2) -> void:
	var pulse: float = 0.32 + 0.16 * (0.5 + 0.5 * sin(run_time * 4.0))
	for junction in merge_junctions:
		if _merge_car_for_junction(junction).is_empty():
			continue
		var path_visible: bool = false
		for sample_index in range(MERGE_PATH_SAMPLE_COUNT + 1):
			var sample_point: Vector2 = _merge_path_point_for_junction(junction, float(sample_index) / float(MERGE_PATH_SAMPLE_COUNT))
			if sample_point.y > -120.0 and sample_point.y < screen_size.y + 140.0:
				path_visible = true
				break
		if not path_visible:
			continue
		var shoulder_points: PackedVector2Array = _offset_points(_merge_path_strip_for_junction(junction, MERGE_RAMP_SHOULDER_WIDTH), shift)
		var ramp_points: PackedVector2Array = _offset_points(_merge_path_strip_for_junction(junction, MERGE_RAMP_WIDTH), shift)
		draw_colored_polygon(shoulder_points, Color("#101a20"))
		draw_colored_polygon(ramp_points, Color("#29383e"))
		var centerline: PackedVector2Array = PackedVector2Array()
		for sample_index in range(MERGE_PATH_SAMPLE_COUNT + 1):
			var progress: float = float(sample_index) / float(MERGE_PATH_SAMPLE_COUNT)
			centerline.append(_merge_path_point_for_junction(junction, progress) + shift)
		draw_polyline(centerline, Color(0.46, 0.61, 0.63, 0.72), 2.0, true)
		var interior_line_color: Color = COLOR_MERGE
		interior_line_color.a = pulse
		for dash_index in range(0, MERGE_PATH_SAMPLE_COUNT, 2):
			var dash_start: Vector2 = _merge_path_point_for_junction(junction, float(dash_index) / float(MERGE_PATH_SAMPLE_COUNT)) + shift
			var dash_end: Vector2 = _merge_path_point_for_junction(junction, float(dash_index + 1) / float(MERGE_PATH_SAMPLE_COUNT)) + shift
			draw_line(dash_start, dash_end, interior_line_color, 3.0)
		var arrow_progress: float = 0.58
		var arrow_center: Vector2 = _merge_path_point_for_junction(junction, arrow_progress) + shift
		var before: Vector2 = _merge_path_point_for_junction(junction, arrow_progress - 0.03)
		var after: Vector2 = _merge_path_point_for_junction(junction, arrow_progress + 0.03)
		var direction: Vector2 = (after - before).normalized()
		var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
		draw_line(arrow_center - direction * 15.0 - perpendicular * 8.0, arrow_center, interior_line_color, 3.0)
		draw_line(arrow_center - direction * 15.0 + perpendicular * 8.0, arrow_center, interior_line_color, 3.0)
		for hatch_index in range(4):
			var hatch_progress: float = 0.70 + float(hatch_index) * 0.06
			var hatch_center: Vector2 = _merge_path_point_for_junction(junction, hatch_progress) + shift
			var hatch_before: Vector2 = _merge_path_point_for_junction(junction, hatch_progress - 0.015)
			var hatch_after: Vector2 = _merge_path_point_for_junction(junction, hatch_progress + 0.015)
			var hatch_direction: Vector2 = (hatch_after - hatch_before).normalized()
			var hatch_normal: Vector2 = Vector2(-hatch_direction.y, hatch_direction.x)
			draw_line(hatch_center - hatch_normal * 18.0 - hatch_direction * 8.0, hatch_center + hatch_normal * 18.0 + hatch_direction * 8.0, Color(0.85, 0.78, 0.57, 0.46), 2.0)
		var entry_point: Vector2 = _merge_path_point_for_junction(junction, 0.0) + shift
		draw_circle(entry_point, 6.0, Color(0.25, 0.82, 0.85, 0.72))
		var label_color: Color = COLOR_INFO
		label_color.a = 0.92
		if entry_point.y > -30.0 and entry_point.y < screen_size.y + 40.0:
			_draw_text(entry_point + Vector2(-30.0, 30.0), "动态入口", 11, label_color)
		var target_lane: int = clampi(int(junction.get("target_lane", _merge_entry_lane(int(junction.get("side", -1))))), 0, LANE_COUNT - 1)
		var phase: String = str(junction.get("phase", "APPROACH"))
		var destination_color: Color = COLOR_WARNING if phase == "WAIT" else interior_line_color
		_draw_text(_merge_path_point_for_junction(junction, 0.86) + Vector2(-25.0, -10.0) + shift, "等待" if phase == "WAIT" else "汇入 L%d" % (target_lane + 1), 10, destination_color)


func _draw_road_events(shift: Vector2) -> void:
	for road_event in road_events:
		if not bool(road_event.get("active", true)):
			continue
		var center_y: float = float(road_event["y"])
		var event_type: String = str(road_event["type"])
		var blocked_lanes: Array = road_event.get("blocked_lanes", [int(road_event.get("lane", 0))])
		if event_type == "LANE CLOSURE":
			for lane_value in blocked_lanes:
				var lane: int = int(lane_value)
				var closure_rect := Rect2(Vector2(road_left + lane_width * float(lane) + 7.0, center_y - 30.0) + shift, Vector2(lane_width - 14.0, 60.0))
				draw_rect(closure_rect, Color(0.82, 0.35, 0.18, 0.72))
				for stripe_index in range(4):
					var stripe_x: float = road_left + lane_width * float(lane) + 19.0 + float(stripe_index) * 38.0
					draw_line(Vector2(stripe_x, center_y + 25.0) + shift, Vector2(stripe_x + 24.0, center_y - 25.0) + shift, COLOR_WARNING, 5.0)
				_draw_text(Vector2(road_left + lane_width * float(int(blocked_lanes[0])), center_y - 40.0) + shift, "车道封闭", 12, COLOR_WARNING)
		elif event_type == "BREAKDOWN":
			var breakdown_center := Vector2(_lane_x(int(road_event["lane"])), center_y) + shift
			_draw_box_with_border(breakdown_center, Vector2(58.0, 92.0), Color("#65727b"), Color("#303940"))
			_draw_box(breakdown_center + Vector2(0.0, -11.0), Vector2(42.0, 24.0), Color("#313d46"))
			draw_circle(breakdown_center + Vector2(-16.0, 28.0), 5.0, COLOR_WARNING)
			draw_circle(breakdown_center + Vector2(16.0, 28.0), 5.0, COLOR_WARNING)
			_draw_text(breakdown_center + Vector2(-31.0, -54.0), "车辆抛锚", 12, COLOR_WARNING)
		else:
			var merge_x: float = _lane_x(int(road_event["lane"]))
			var merge_center := Vector2(merge_x, center_y) + shift
			draw_circle(merge_center, 26.0, Color(0.20, 0.52, 0.66, 0.22))
			draw_arc(merge_center, 26.0, 0.0, TAU, 24, COLOR_INFO, 2.0)
			_draw_text(merge_center + Vector2(-42.0, -42.0), "支路合流事件", 12, COLOR_INFO)
			_draw_text(merge_center + Vector2(-9.0, 20.0), "↓", 24, COLOR_INFO)


func _draw_hazards(shift: Vector2) -> void:
	for hazard in hazards:
		if not bool(hazard.get("active", true)):
			continue
		var center := Vector2(float(hazard["x"]), float(hazard["y"])) + shift
		var hazard_type: String = str(hazard["type"])
		match hazard_type:
			"OIL":
				draw_circle(center, 34.0, Color(0.03, 0.04, 0.05, 0.72))
				draw_circle(center + Vector2(-16.0, 7.0), 12.0, Color(0.08, 0.10, 0.12, 0.84))
				draw_circle(center + Vector2(15.0, -8.0), 9.0, Color(0.12, 0.14, 0.16, 0.85))
				_draw_text(center + Vector2(-18.0, 51.0), "油污", 12, Color("#94a3b8"))
			"SOFA":
				var sofa_width: float = float(hazard.get("width", lane_width * 0.9))
				_draw_box_with_border(center, Vector2(sofa_width, 64.0), Color("#c47f58"), Color("#7f4f3c"))
				_draw_box_with_border(center + Vector2(0.0, -6.0), Vector2(sofa_width * 0.78, 34.0), Color("#e0a276"), Color("#7f4f3c"))
				_draw_text(center + Vector2(-28.0, 48.0), "沙发", 12, Color("#ffd0a8"))
			"TIRE":
				draw_circle(center, 27.0, Color("#101317"))
				draw_arc(center, 27.0, 0.0, TAU, 24, Color("#343d46"), 6.0)
				draw_circle(center, 10.0, Color("#7c8790"))
				draw_line(center - Vector2(17.0, 17.0), center + Vector2(17.0, 17.0), Color("#505b64"), 3.0)
				_draw_text(center + Vector2(-25.0, 45.0), "滚轮胎", 12, Color("#c7d0d5"))
			"BANANA CART":
				_draw_box_with_border(center, Vector2(58.0, 54.0), Color("#e8bc4f"), Color("#8b6731"))
				for banana_index in range(3):
					draw_circle(center + Vector2(-17.0 + float(banana_index) * 17.0, -4.0), 8.0, Color("#fff1a4"))
				_draw_text(center + Vector2(-29.0, 43.0), "香蕉车", 11, Color("#fff0a6"))
			"POPCORN":
				_draw_box_with_border(center, Vector2(28.0, 28.0), Color("#fff0a6"), Color("#b57c49"))
				draw_circle(center + Vector2(-9.0, -18.0), 5.0, Color("#fff7cc"))
				draw_circle(center + Vector2(7.0, -21.0), 4.0, Color("#fff7cc"))
			"BOX":
				_draw_box_with_border(center, Vector2(44.0, 44.0), Color("#d8984c"), Color("#6d4326"))
				draw_line(center - Vector2(22.0, 22.0), center + Vector2(22.0, 22.0), Color("#f4c47c"), 3.0)
				_draw_text(center + Vector2(-18.0, 37.0), "纸箱", 11, Color("#f4c47c"))
			"CHAIR":
				_draw_box_with_border(center + Vector2(0.0, -9.0), Vector2(38.0, 30.0), Color("#b9794d"), Color("#704631"))
				draw_line(center + Vector2(-14.0, 7.0), center + Vector2(-19.0, 27.0), Color("#704631"), 5.0)
				draw_line(center + Vector2(14.0, 7.0), center + Vector2(19.0, 27.0), Color("#704631"), 5.0)
				_draw_text(center + Vector2(-18.0, 43.0), "椅子", 11, Color("#e5b18b"))
			"LAMP":
				draw_colored_polygon(PackedVector2Array([center + Vector2(-19.0, -12.0), center + Vector2(19.0, -12.0), center + Vector2(12.0, 7.0), center + Vector2(-12.0, 7.0)]), Color("#e6b85c"))
				draw_line(center + Vector2(0.0, 7.0), center + Vector2(0.0, 27.0), Color("#855b3c"), 4.0)
				_draw_text(center + Vector2(-18.0, 43.0), "台灯", 11, Color("#ffe7a7"))
			"ROADWORK SIGN":
				var sign_width: float = float(hazard.get("width", lane_width * 0.92))
				_draw_box(center, Vector2(sign_width, 72.0), Color(0.82, 0.35, 0.18, 0.22))
				draw_line(center + Vector2(-sign_width * 0.38, 27.0), center + Vector2(-sign_width * 0.18, -25.0), COLOR_WARNING, 5.0)
				draw_line(center + Vector2(sign_width * 0.08, 27.0), center + Vector2(sign_width * 0.28, -25.0), COLOR_WARNING, 5.0)
				_draw_text(center + Vector2(-36.0, -36.0), "施工封道", 12, COLOR_WARNING)
			"PAINT":
				var paint_width: float = float(hazard.get("width", lane_width * 0.92))
				draw_rect(Rect2(center - Vector2(paint_width * 0.5, 59.0), Vector2(paint_width, 118.0)), Color(0.95, 0.25, 0.54, 0.32))
				for paint_line in range(4):
					var paint_x: float = center.x - paint_width * 0.38 + float(paint_line) * paint_width * 0.25
					draw_line(Vector2(paint_x, center.y - 45.0), Vector2(paint_x + 20.0, center.y + 44.0), Color(1.0, 0.62, 0.78, 0.65), 4.0)
				_draw_text(center + Vector2(-25.0, 76.0), "漏漆区", 12, Color("#ffabc9"))
			"GIANT MATTRESS":
				var flight_height: float = float(hazard.get("flight_height", 0.0))
				if str(hazard.get("stage", "FLYING")) == "FLYING":
					_draw_ellipse(center, Vector2(48.0, 14.0), Color(0.02, 0.03, 0.04, 0.35))
				var mattress_center: Vector2 = center - Vector2(0.0, flight_height)
				_draw_box_with_border(mattress_center, Vector2(float(hazard.get("width", 100.0)), float(hazard.get("height", 62.0))), Color("#d7c4b1"), Color("#76685d"))
				draw_line(mattress_center - Vector2(34.0, 9.0), mattress_center + Vector2(34.0, 9.0), Color("#f3e2d1"), 4.0)
				_draw_text(mattress_center + Vector2(-31.0, 46.0), "床垫", 12, Color("#f0ddcc"))
			"INFLATABLE POOL":
				var pool_width: float = float(hazard.get("width", lane_width * 0.4))
				var pool_height: float = 76.0
				_draw_box_with_border(center, Vector2(pool_width, pool_height), Color(0.22, 0.70, 0.84, 0.68), Color("#b4f3ff"))
				draw_arc(center, minf(pool_width, pool_height) * 0.38, 0.0, TAU, 24, Color("#d9fbff"), 3.0)
				_draw_text(center + Vector2(-29.0, 54.0), "泳池", 12, Color("#d9fbff"))
			"ROGUE CART":
				_draw_box_with_border(center, Vector2(42.0, 58.0), Color("#8ecf9d"), Color("#3e7150"))
				draw_line(center + Vector2(-13.0, -22.0), center + Vector2(-22.0, -36.0), Color("#a6e9b1"), 4.0)
				draw_circle(center + Vector2(-13.0, 26.0), 6.0, Color("#27362d"))
				draw_circle(center + Vector2(13.0, 26.0), 6.0, Color("#27362d"))
				_draw_text(center + Vector2(-30.0, 48.0), "失控购物车", 11, Color("#b7f3c1"))
			"NAIL":
				_draw_box(center, Vector2(54.0, 24.0), Color("#bec9d2"))
				for nail_index in range(4):
					draw_line(center + Vector2(-20.0 + float(nail_index) * 13.0, -8.0), center + Vector2(-26.0 + float(nail_index) * 13.0, -18.0), Color("#f2f6f8"), 3.0)
				_draw_text(center + Vector2(-24.0, 40.0), "钉子", 11, Color("#e2e9ee"))


func _draw_loose_props(shift: Vector2) -> void:
	for prop in loose_props:
		if not bool(prop.get("active", true)):
			continue
		var center := Vector2(float(prop["x"]), float(prop["y"])) + shift
		var pulled: bool = bool(prop.get("pulled", false))
		var color: Color = COLOR_WARNING if pulled else Color("#647a83")
		if str(prop.get("type", "")) == "SHOPPING CART":
			_draw_box_with_border(center, Vector2(38.0, 28.0), color, Color("#263a40"))
			draw_circle(center + Vector2(-12.0, 17.0), 4.0, Color("#172228"))
			draw_circle(center + Vector2(12.0, 17.0), 4.0, Color("#172228"))
		else:
			_draw_box_with_border(center, Vector2(34.0, 42.0), color, Color("#263a40"))
		_draw_text(center + Vector2(-29.0, 39.0), str(prop.get("type", "杂物")), 10, color)


func _draw_pickups(shift: Vector2) -> void:
	for pickup in pickups:
		if bool(pickup["collected"]):
			continue
		var center := Vector2(float(pickup["x"]), float(pickup["y"])) + shift
		draw_circle(center, 31.0, Color(0.12, 0.30, 0.36, 0.92))
		draw_arc(center, 35.0, 0.0, TAU, 24, COLOR_ACCENT, 3.0)
		_draw_text(center + Vector2(-10.0, 11.0), "?", 28, Color.WHITE)
		_draw_text(center + Vector2(-42.0, -43.0), "神秘道具", 11, COLOR_ACCENT)


func _draw_traffic(shift: Vector2) -> void:
	for car in traffic:
		if float(car["y"]) < -160.0 or float(car["y"]) > screen_size.y + 180.0:
			continue
		_draw_car(car, shift)


func _draw_car(car: Dictionary, shift: Vector2) -> void:
	var center := Vector2(float(car["x"]), float(car["y"])) + shift
	var dimensions: Vector2 = _car_dimensions(str(car["kind"]))
	var angle: float = float(car["spin_angle"])
	var body_color: Color = car["color"]
	if bool(car["crashed"]):
		body_color = body_color.darkened(0.25)

	_draw_box(center + Vector2(4.0, 7.0), dimensions + Vector2(8.0, 8.0), Color(0.02, 0.03, 0.04, 0.48), angle)
	_draw_box(center, dimensions, body_color, angle)
	_draw_box(_rotated_point(center, Vector2(0.0, -13.0), angle), Vector2(dimensions.x * 0.74, dimensions.y * 0.25), Color("#263746"), angle)
	_draw_box(_rotated_point(center, Vector2(0.0, 26.0), angle), Vector2(dimensions.x * 0.68, dimensions.y * 0.17), Color("#1b2630"), angle)

	var blink_on: bool = fmod(float(car["indicator_clock"]), 0.8) < 0.42
	var indicator: int = int(car["indicator"])
	if indicator != 0 and blink_on and not bool(car["crashed"]):
		var indicator_x: float = (dimensions.x * 0.5 + 4.0) * float(indicator)
		var indicator_pos := _rotated_point(center, Vector2(indicator_x, -dimensions.y * 0.18), angle)
		draw_circle(indicator_pos, 5.0, COLOR_WARNING)
	if str(car["state"]) == "BRAKE" or float(car["slip"]) > 0.0:
		for side in [-1.0, 1.0]:
			var light_pos := _rotated_point(center, Vector2(side * dimensions.x * 0.30, dimensions.y * 0.39), angle)
			draw_circle(light_pos, 5.0, COLOR_DANGER)

	var driver_type: String = str(car.get("driver_type", "NORMAL"))
	if not bool(car["crashed"]) and (driver_type != "NORMAL" or str(car["state"]) != "CRUISE"):
		var driver_color: Color = Color("#ff9aa8") if driver_type == "AGGRESSIVE" else (COLOR_INFO if driver_type == "CAUTIOUS" else Color("#b8c5cc"))
		_draw_text(center + Vector2(-51.0, -dimensions.y * 0.5 - 30.0), _localized_driver_type(driver_type), 11, driver_color)
	var state_key: String = str(car["state"])
	var state_text: String = _localized_state(state_key)
	var state_color: Color = COLOR_INFO
	if state_key == "PREPARE OVERTAKE" or state_key == "LANE CHANGE" or state_key == "AVOID" or state_key == "MERGING":
		state_color = COLOR_WARNING
	elif state_key == "BRAKE" or state_key == "BLOCKED":
		state_color = COLOR_DANGER
	elif state_key == "WAIT" or state_key == "MERGE WAIT":
		state_color = Color("#c7b8ff")
	elif state_key == "CRASH":
		state_color = COLOR_WARNING
	if not bool(car["crashed"]) or float(car["crash_time"]) < 0.55:
		var state_label_y: float = dimensions.y * 0.5 + 19.0
		if bool(car["aggressive"]) and float(car["y"]) > player_y - 220.0:
			state_label_y = -dimensions.y * 0.5 - 48.0
		_draw_text(center + Vector2(-48.0, state_label_y), state_text, 11, state_color)
	if (state_key == "PREPARE OVERTAKE" or state_key == "LANE CHANGE" or state_key == "AVOID") and indicator != 0:
		_draw_text(center + Vector2(-8.0, -dimensions.y * 0.5 - 7.0), "<" if indicator < 0 else ">", 22, COLOR_WARNING)


func _draw_player(shift: Vector2) -> void:
	var body_size: Vector2 = _player_body_size()
	var center := Vector2(player_x, player_y) + shift
	if _has_active_effect("BLACK SMOKE"):
		for puff_index in range(4):
			var puff_offset: float = sin(run_time * 2.0 + float(puff_index) * 1.7) * 13.0
			var puff_pos := center + Vector2(puff_offset, 64.0 + float(puff_index) * 17.0)
			draw_circle(puff_pos, 13.0 + float(puff_index) * 2.0, Color(0.12, 0.14, 0.16, 0.27 - float(puff_index) * 0.04))

	if _has_active_effect("LONG TRAILER"):
		var trailer_center := center + Vector2(0.0, 84.0)
		_draw_box_with_border(trailer_center, Vector2(road_width * 0.92, 28.0), Color("#69757e"), Color("#d5a76c"))
		for stripe_index in range(7):
			var stripe_x: float = trailer_center.x - road_width * 0.37 + float(stripe_index) * road_width * 0.12
			draw_line(Vector2(stripe_x, trailer_center.y - 10.0), Vector2(stripe_x + 15.0, trailer_center.y + 10.0), COLOR_WARNING, 4.0)
		_draw_text(trailer_center + Vector2(-36.0, 7.0), "超长拖车", 12, Color.WHITE)
	if _has_item("MOVING ROADBLOCK"):
		var barrier_center: Vector2 = _moving_barrier_position() + shift
		_draw_box_with_border(barrier_center, Vector2(lane_width * 0.82, 24.0), Color("#d2a35c"), Color("#533e2a"), sin(run_time * 3.0) * 0.08)
		draw_line(barrier_center - Vector2(lane_width * 0.30, 0.0), barrier_center + Vector2(lane_width * 0.30, 0.0), COLOR_WARNING, 3.0)
	if _has_item("OVERLOADED RACK"):
		_draw_box_with_border(center + Vector2(0.0, -62.0), Vector2(54.0, 22.0), Color("#b17c44"), Color("#613e29"))
		_draw_box(center + Vector2(-15.0, -77.0), Vector2(20.0, 16.0), Color("#e5bd76"))
		_draw_box(center + Vector2(13.0, -77.0), Vector2(20.0, 16.0), Color("#bb7d5e"))
	_draw_box(center + Vector2(4.0, 7.0), body_size + Vector2(8.0, 8.0), Color(0.02, 0.03, 0.04, 0.55))
	var player_color: Color = Color("#f08a5d")
	if _has_item("SLOW MODE"):
		player_color = Color("#e1b56a")
	_draw_box(center, body_size, player_color)
	_draw_box(center + Vector2(0.0, -15.0), Vector2(body_size.x * 0.72, 32.0), Color("#243c55"))
	_draw_box(center + Vector2(0.0, 32.0), Vector2(body_size.x * 0.68, 21.0), Color("#8e4d3e"))
	for side in [-1.0, 1.0]:
		draw_circle(center + Vector2(side * body_size.x * 0.30, -body_size.y * 0.42), 5.0, Color("#fff3b0"))
		var fake_brake_on: bool = _has_item("FAKE BRAKE LIGHT") and fmod(run_time, 0.95) < 0.42
		var brake_color: Color = COLOR_DANGER if Input.is_action_pressed("brake") or fake_brake_on else Color("#74363a")
		draw_circle(center + Vector2(side * body_size.x * 0.30, body_size.y * 0.39), 5.0, brake_color)
	if _has_active_effect("FAKE TURN SIGNAL") and fmod(run_time, 0.8) < 0.42:
		var signal_side: int = int(_active_effect_data("FAKE TURN SIGNAL").get("side", 1))
		draw_circle(center + Vector2(float(signal_side) * body_size.x * 0.46, -body_size.y * 0.18), 5.0, COLOR_WARNING)
	if _has_active_effect("FAKE POLICE LIGHT"):
		var police_color: Color = Color("#ff526f") if fmod(run_time, 0.48) < 0.24 else Color("#5fa8ff")
		draw_circle(center + Vector2(-body_size.x * 0.42, -body_size.y * 0.18), 6.0, police_color)
		draw_circle(center + Vector2(body_size.x * 0.42, -body_size.y * 0.18), 6.0, Color("#5fa8ff") if police_color == Color("#ff526f") else Color("#ff526f"))
	_draw_text(center + Vector2(-17.0, -body_size.y * 0.5 - 18.0), "玩家", 13, Color.WHITE)


func _draw_particles(shift: Vector2) -> void:
	for particle in particles:
		var alpha: float = clampf(float(particle["life"]) / 0.65, 0.0, 1.0)
		var color: Color = Color(particle["color"])
		color.a *= alpha
		draw_circle(Vector2(particle["position"]) + shift, 3.0 + alpha * 2.0, color)


func _draw_floating_texts(shift: Vector2) -> void:
	for floating in floating_texts:
		var alpha: float = clampf(float(floating["life"]) / float(floating["max_life"]), 0.0, 1.0)
		var color: Color = Color(floating["color"])
		color.a = alpha
		_draw_text(Vector2(floating["position"]) + shift, str(floating["text"]), 14, color)


func _draw_hud() -> void:
	var top_left := Rect2(18.0, 16.0, 360.0, 152.0)
	draw_rect(top_left, COLOR_PANEL)
	draw_line(Vector2(18.0, 168.0), Vector2(378.0, 168.0), Color(0.35, 0.88, 0.75, 0.5), 2.0)
	_draw_text(Vector2(32.0, 42.0), "交通恶霸  //  灰盒", 18, Color.WHITE)
	_draw_text(Vector2(32.0, 70.0), "混乱分数  %05d" % score, 19, COLOR_ACCENT)
	_draw_text(Vector2(214.0, 70.0), "连击  x%d" % combo, 16, COLOR_WARNING)
	_draw_text(Vector2(32.0, 99.0), "车辆耐久", 13, Color("#b9c4cc"))
	for health_index in range(MAX_DURABILITY):
		var health_color: Color = COLOR_DANGER if health_index >= durability else COLOR_ACCENT
		draw_rect(Rect2(117.0 + float(health_index) * 19.0, 88.0, 14.0, 13.0), health_color)
	_draw_text(Vector2(32.0, 124.0), "困住车辆  %02d" % vehicles_trapped, 14, COLOR_INFO)
	_draw_text(Vector2(32.0, 150.0), "连锁事故  x%d  /  堵塞倍率 ×%.1f" % [chain_count, chaos_multiplier], 13, COLOR_WARNING)

	var right_panel := Rect2(screen_size.x - 282.0, 16.0, 264.0, 160.0)
	draw_rect(right_panel, COLOR_PANEL)
	_draw_text(Vector2(screen_size.x - 264.0, 42.0), "本局  %s / 08:00" % _format_time(run_time), 17, Color.WHITE)
	_draw_text(Vector2(screen_size.x - 264.0, 68.0), "速度  %02d km/h" % int(round(player_speed)), 17, _speed_color())
	_draw_text(Vector2(screen_size.x - 264.0, 94.0), "意图  %s" % _intent_summary(), 12, COLOR_INFO)
	_draw_text(Vector2(screen_size.x - 264.0, 119.0), "车流  %02d  /  困住  %02d" % [_active_traffic_count(), vehicles_trapped], 12, COLOR_WARNING)
	_draw_text(Vector2(screen_size.x - 264.0, 143.0), "动态道路段 %02d  /  等待汇入 %02d" % [merge_junctions.size(), merge_queue_count], 11, COLOR_INFO)

	var banner := Rect2(screen_size.x * 0.5 - 232.0, 16.0, 464.0, 34.0)
	draw_rect(banner, Color(0.09, 0.18, 0.22, 0.92))
	_draw_text(Vector2(banner.position.x + 20.0, 39.0), "测试循环  /  堵住 → 反应 → 事故", 14, COLOR_ACCENT)

	var feed_panel := Rect2(screen_size.x - 360.0, 190.0, 342.0, 188.0)
	draw_rect(feed_panel, Color(0.03, 0.06, 0.09, 0.72))
	_draw_text(Vector2(feed_panel.position.x + 16.0, feed_panel.position.y + 24.0), "事件记录", 12, Color("#9aa7b1"))
	for index in range(messages.size()):
		var message: Dictionary = messages[index]
		var message_color: Color = message["color"]
		message_color.a = clampf(float(message["life"]) / 1.0, 0.35, 1.0)
		_draw_text(Vector2(feed_panel.position.x + 16.0, feed_panel.position.y + 49.0 + float(index) * 19.0), str(message["text"]), 12, message_color)

	var controls_panel := Rect2(18.0, screen_size.y - 88.0, 294.0, 64.0)
	draw_rect(controls_panel, Color(0.03, 0.06, 0.09, 0.88))
	_draw_text(Vector2(32.0, screen_size.y - 59.0), "←/→  移动", 13, COLOR_INFO)
	_draw_text(Vector2(32.0, screen_size.y - 37.0), "↑/↓  50 / 30 km/h     Esc 暂停     R 重开", 11, Color("#b6c0c7"))

	var item_panel_width: float = minf(screen_size.x - 390.0, 650.0)
	item_panel_width = minf(maxf(item_panel_width, 430.0), maxf(screen_size.x - 24.0, 160.0))
	var item_panel := Rect2(screen_size.x * 0.5 - item_panel_width * 0.5, screen_size.y - 109.0, item_panel_width, 85.0)
	draw_rect(item_panel, Color(0.09, 0.14, 0.17, 0.96))
	draw_line(item_panel.position, item_panel.position + Vector2(item_panel.size.x, 0.0), COLOR_WARNING, 2.0)
	var card_gap: float = 8.0
	var card_width: float = (item_panel.size.x - 30.0 - card_gap * 2.0) / 3.0
	for slot_index in range(ITEM_SLOT_COUNT):
		_draw_item_slot_card(item_panel.position + Vector2(10.0 + float(slot_index) * (card_width + card_gap), 8.0), Vector2(card_width, 63.0), slot_index)
	var cooldown_bar_width: float = item_panel.size.x - 154.0
	draw_rect(Rect2(item_panel.position + Vector2(10.0, 71.0), Vector2(cooldown_bar_width, 4.0)), Color("#263943"))
	var cooldown_ready_ratio: float = 1.0 - clampf(item_cooldown_remaining / ITEM_COOLDOWN_SECONDS, 0.0, 1.0)
	draw_rect(Rect2(item_panel.position + Vector2(10.0, 71.0), Vector2(cooldown_bar_width * cooldown_ready_ratio, 4.0)), COLOR_ACCENT if item_cooldown_remaining <= 0.0 else COLOR_WARNING)
	var cooldown_text: String = "共享冷却 %.1f 秒" % item_cooldown_remaining if item_cooldown_remaining > 0.0 else "共享冷却就绪"
	_draw_text(item_panel.position + Vector2(item_panel.size.x - 140.0, 82.0), cooldown_text, 10, COLOR_WARNING if item_cooldown_remaining > 0.0 else COLOR_ACCENT)

	var target_panel := Rect2(screen_size.x * 0.5 - 190.0, 62.0, 380.0, 28.0)
	_draw_text(Vector2(target_panel.position.x, target_panel.position.y + 18.0), "前 30 秒：读意图 → 卡位 → 让后车堵住", 12, Color("#d6dee3"))


func _draw_item_slot_card(position: Vector2, size: Vector2, slot_index: int) -> void:
	var item_key: String = str(item_slots[slot_index])
	var selected: bool = selected_item_slot == slot_index
	var definition: Dictionary = item_definitions.get(item_key, {})
	var accent: Color = definition.get("accent", Color("#53616b")) if not item_key.is_empty() else Color("#53616b")
	var fill: Color = Color(0.14, 0.20, 0.24, 0.98) if selected else Color(0.07, 0.11, 0.14, 0.98)
	draw_rect(Rect2(position, size), fill)
	draw_line(position, position + Vector2(size.x, 0.0), accent if selected else Color("#3a4b54"), 3.0 if selected else 1.0)
	_draw_text(position + Vector2(8.0, 17.0), "%d" % (slot_index + 1), 16, accent)
	var title: String = "空槽" if item_key.is_empty() else str(definition.get("title", _localized_item(item_key)))
	_draw_text(position + Vector2(32.0, 16.0), title, 12, Color.WHITE if not item_key.is_empty() else Color("#78858d"))
	var kind_text: String = "碰到道具自动获得" if item_key.is_empty() else str(definition.get("kind", "主动"))
	_draw_text(position + Vector2(32.0, 34.0), kind_text, 10, COLOR_INFO if item_key.is_empty() else accent)
	var action_text: String = "" if item_key.is_empty() else ("被动生效" if _is_passive_item(item_key) else ("冷却中" if item_cooldown_remaining > 0.0 else "按 %d 直接使用" % (slot_index + 1)))
	_draw_text(position + Vector2(32.0, 51.0), action_text, 10, Color("#b5c0c7"))


func _draw_upgrade_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.015, 0.025, 0.04, 0.88))
	var panel := Rect2(screen_size.x * 0.5 - 510.0, screen_size.y * 0.5 - 205.0, 1020.0, 410.0)
	draw_rect(panel, Color("#12202a"))
	draw_line(Vector2(panel.position.x, panel.position.y + 80.0), Vector2(panel.end.x, panel.position.y + 80.0), COLOR_ACCENT, 3.0)
	_draw_text(Vector2(panel.position.x + 34.0, panel.position.y + 48.0), "混乱升级  //  选择一张", 28, Color.WHITE)
	_draw_text(Vector2(panel.position.x + 34.0, panel.position.y + 70.0), "这张卡会改变交通行为，不只是增加数值。", 13, Color("#aebbc3"))

	var card_width: float = 296.0
	var gap: float = 20.0
	for index in range(upgrade_cards.size()):
		var card: Dictionary = upgrade_cards[index]
		var card_rect := Rect2(panel.position.x + 34.0 + float(index) * (card_width + gap), panel.position.y + 108.0, card_width, 210.0)
		var accent: Color = card["accent"]
		draw_rect(card_rect, Color(0.06, 0.11, 0.15, 1.0))
		draw_line(card_rect.position, card_rect.position + Vector2(card_rect.size.x, 0.0), accent, 5.0)
		_draw_text(card_rect.position + Vector2(20.0, 42.0), "%d" % (index + 1), 28, accent)
		_draw_text(card_rect.position + Vector2(62.0, 39.0), str(card["title"]), 15, Color.WHITE)
		_draw_text_block(card_rect.position + Vector2(20.0, 92.0), str(card["description"]), 13, Color("#c8d1d7"), 20.0)
		_draw_text(card_rect.position + Vector2(20.0, 180.0), "按 %d 选择" % (index + 1), 12, accent)


func _draw_item_replacement_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.015, 0.025, 0.04, 0.90))
	var panel_width: float = minf(screen_size.x - 36.0, 920.0)
	var panel := Rect2(screen_size.x * 0.5 - panel_width * 0.5, screen_size.y * 0.5 - 198.0, panel_width, 396.0)
	draw_rect(panel, Color("#12202a"))
	draw_line(panel.position, panel.position + Vector2(panel.size.x, 0.0), COLOR_WARNING, 4.0)
	_draw_text(panel.position + Vector2(28.0, 45.0), "道具槽已满  //  选择替换", 25, Color.WHITE)
	_draw_text(panel.position + Vector2(28.0, 70.0), "碰到的新道具：" + _localized_item(pending_pickup_item), 14, COLOR_WARNING)
	_draw_text(panel.position + Vector2(28.0, 91.0), "交通已暂停，必须选择一个槽位；按 Esc 不会丢弃新道具。", 12, Color("#b9c6cd"))
	var card_gap: float = 16.0
	var card_width: float = (panel.size.x - 56.0 - card_gap * 2.0) / 3.0
	for slot_index in range(ITEM_SLOT_COUNT):
		var card_position: Vector2 = panel.position + Vector2(20.0 + float(slot_index) * (card_width + card_gap), 125.0)
		var item_key: String = str(item_slots[slot_index])
		var definition: Dictionary = item_definitions.get(item_key, {})
		var accent: Color = definition.get("accent", COLOR_INFO)
		_draw_box(card_position + Vector2(card_width * 0.5, 88.0), Vector2(card_width, 176.0), Color(0.07, 0.12, 0.15, 1.0))
		draw_line(card_position, card_position + Vector2(card_width, 0.0), accent, 5.0)
		_draw_text(card_position + Vector2(14.0, 34.0), "%d" % (slot_index + 1), 27, accent)
		_draw_text(card_position + Vector2(54.0, 32.0), _localized_item(item_key), 15, Color.WHITE)
		_draw_text(card_position + Vector2(14.0, 73.0), str(definition.get("kind", "")), 11, accent)
		_draw_text_block(card_position + Vector2(14.0, 101.0), _item_description(item_key), 12, Color("#c8d1d7"), 18.0)
		_draw_text(card_position + Vector2(14.0, 159.0), "按 %d 替换" % (slot_index + 1), 12, COLOR_WARNING)


func _draw_center_overlay(title: String, subtitle: String) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.015, 0.025, 0.04, 0.74))
	var center := Vector2(screen_size.x * 0.5, screen_size.y * 0.5)
	_draw_text(center + Vector2(-160.0, -18.0), title, 36, COLOR_ACCENT if title == "本局完成" else COLOR_DANGER)
	_draw_text(center + Vector2(-160.0, 26.0), subtitle, 15, Color.WHITE)


## 为一组多边形顶点统一添加屏幕震动偏移，保持道路层和提示层同步。
func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted_points: PackedVector2Array = PackedVector2Array()
	for point in points:
		shifted_points.append(point + offset)
	return shifted_points


func _draw_box(center: Vector2, size: Vector2, color: Color, angle: float = 0.0) -> void:
	draw_colored_polygon(_rotated_rect(center, size, angle), color)


func _draw_box_with_border(center: Vector2, size: Vector2, fill_color: Color, border_color: Color, angle: float = 0.0) -> void:
	_draw_box(center, size, border_color, angle)
	_draw_box(center, size - Vector2(5.0, 5.0), fill_color, angle)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _rotated_rect(center: Vector2, size: Vector2, angle: float) -> PackedVector2Array:
	var half := size * 0.5
	var points := PackedVector2Array()
	points.append(center + Vector2(-half.x, -half.y).rotated(angle))
	points.append(center + Vector2(half.x, -half.y).rotated(angle))
	points.append(center + Vector2(half.x, half.y).rotated(angle))
	points.append(center + Vector2(-half.x, half.y).rotated(angle))
	return points


func _rotated_point(center: Vector2, local: Vector2, angle: float) -> Vector2:
	return center + local.rotated(angle)


func _draw_text(position: Vector2, value: String, font_size: int, color: Color) -> void:
	var font_to_use: Font = ui_font if ui_font != null else ThemeDB.fallback_font
	draw_string(font_to_use, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_text_block(position: Vector2, value: String, font_size: int, color: Color, line_gap: float) -> void:
	var lines: PackedStringArray = value.split("\n")
	for line_index in range(lines.size()):
		_draw_text(position + Vector2(0.0, float(line_index) * line_gap), lines[line_index], font_size, color)


func _car_dimensions(kind: String) -> Vector2:
	match kind:
		"SUV":
			return Vector2(70.0, 118.0)
		"VAN":
			return Vector2(76.0, 132.0)
		"TRUCK":
			return Vector2(84.0, 150.0)
		"PICKUP":
			return Vector2(72.0, 124.0)
		"BUS":
			return Vector2(92.0, 176.0)
	return Vector2(64.0, 112.0)


func _lane_x(lane: int) -> float:
	if lane_centers.is_empty():
		return screen_size.x * 0.5
	return lane_centers[clampi(lane, 0, LANE_COUNT - 1)]


func _nearest_lane(x: float) -> int:
	var best_lane: int = 0
	var best_distance: float = INF
	for lane in range(lane_centers.size()):
		var distance: float = absf(x - lane_centers[lane])
		if distance < best_distance:
			best_distance = distance
			best_lane = lane
	return best_lane


func _get_shake_offset() -> Vector2:
	var strength: float = shake_trauma * shake_trauma
	return Vector2(
		sin(shake_phase * 1.7) * 13.0 * strength,
		sin(shake_phase * 2.3) * 8.0 * strength,
	)


func _speed_color() -> Color:
	if player_speed < 35.0:
		return COLOR_DANGER
	if player_speed > 45.0:
		return COLOR_ACCENT
	return COLOR_WARNING


func _intent_summary() -> String:
	for car in traffic:
		if bool(car["crashed"]) or not bool(car["aggressive"]):
			continue
		if float(car["y"]) > -60.0 and float(car["y"]) < player_y + 380.0:
			var intent: String = _localized_state(str(car["state"]))
			if int(car["indicator"]) != 0:
				intent += " <" if int(car["indicator"]) < 0 else " >"
			return intent
	return "观察道路"


func _format_time(seconds_total: float) -> String:
	var total_seconds: int = maxi(int(seconds_total), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _localized_driver_type(driver_type: String) -> String:
	match driver_type:
		"AGGRESSIVE":
			return "激进司机"
		"CAUTIOUS":
			return "谨慎司机"
		"NORMAL":
			return "普通司机"
	return driver_type


func _localized_road_event(event_type: String) -> String:
	match event_type:
		"BRANCH MERGE":
			return "支路合流"
		"LANE CLOSURE":
			return "临时封道"
		"BREAKDOWN":
			return "车辆抛锚"
	return event_type


func _localized_state(state_key: String) -> String:
	match state_key:
		"CRUISE":
			return "巡航"
		"FOLLOW":
			return "跟车"
		"BRAKE":
			return "急刹"
		"PREPARE OVERTAKE":
			return "准备超车"
		"LANE CHANGE":
			return "变道中"
		"PASS PLAYER":
			return "正在超车"
		"CRASH":
			return "碰撞"
		"WAIT":
			return "等待"
		"BLOCKED":
			return "被堵"
		"AVOID":
			return "避让"
		"RECOVER":
			return "恢复"
		"MERGING":
			return "汇入中"
		"MERGE WAIT":
			return "等待汇入"
	return state_key


func _localized_item(item_key: String) -> String:
	match item_key:
		"SOFA DROP":
			return "掉沙发"
		"ROLLING TIRE":
			return "掉轮胎"
		"BANANA CART":
			return "香蕉车厢"
		"FAKE TURN SIGNAL":
			return "假左/右转灯"
		"LONG TRAILER":
			return "超长拖车"
		"POPCORN MACHINE":
			return "爆米花机"
		"BROKEN TRUNK":
			return "坏掉的后备箱"
		"ROADWORK SIGN":
			return "道路施工牌"
		"GIANT MATTRESS":
			return "巨大床垫"
		"MAGNET":
			return "磁铁"
		"PAINT LEAK":
			return "漏漆桶"
		"FAKE POLICE LIGHT":
			return "假警灯"
		"OVERLOADED RACK":
			return "超载行李架"
		"INFLATABLE POOL":
			return "充气泳池"
		"ROGUE SHOPPING CART":
			return "失控购物车"
		"OIL LEAK":
			return "漏油"
		"BLACK SMOKE":
			return "黑烟"
		"SLOW MODE":
			return "龟速模式"
		"WIDE BODY":
			return "宽体改装"
		"SNAKE SWERVE":
			return "蛇皮走位"
		"NAIL RAIN":
			return "钉子雨"
		"FAKE BRAKE LIGHT":
			return "假刹车灯"
		"MOVING ROADBLOCK":
			return "移动路障"
	return item_key
