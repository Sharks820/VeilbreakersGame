extends Node
## GameManager: Central hub for game state, player data, and runtime information.

# =============================================================================
# STATE
# =============================================================================

var current_state: Enums.GameState = Enums.GameState.NONE
var previous_state: Enums.GameState = Enums.GameState.NONE
var is_initialized: bool = false

# =============================================================================
# PLAYER DATA
# =============================================================================

var player_party: Array = []  # Array of Character nodes/resources
var reserve_party: Array = []  # Benched party members
var owned_monsters: Array = []  # All captured monsters

# =============================================================================
# PROGRESSION
# =============================================================================

var player_level: int = 1
var total_experience: int = 0
var path_alignment: float = 0.0  # -100 (Shade) to +100 (Seraph)
var unlocked_brands: Array[int] = [Enums.Brand.NONE]
var story_flags: Dictionary = {}
var current_chapter: int = 1

# =============================================================================
# VERA STATE
# =============================================================================

var vera_state: Enums.VERAState = Enums.VERAState.INTERFACE
var vera_corruption: float = 0.0
var vera_power_used: float = 0.0

# =============================================================================
# VERA STORY FLAGS
# =============================================================================

var vera_story_flags := {
	# Discovery
	"first_glitch_witnessed": false,
	"asked_about_glitches": false,
	"found_ancient_texts": false,
	"texts_match_vera_glitches": false,

	# Relationship
	"vera_admitted_fear": false,
	"player_comforted_vera": false,
	"player_suspicious_of_vera": false,
	"vera_confessed_dreams": false,

	# Awakening
	"first_memory_surfaced": false,
	"vera_remembered_name": false,
	"vera_spoke_ancient_language": false,
	"vera_recognized_veil_bringer": false,

	# Truth
	"truth_about_compact": false,
	"gods_watching_discovered": false,
	"vera_blinding_gods": false,
	"veil_bringer_is_her_power": false,

	# Endgame
	"approaching_veil": false,
	"verath_fully_awakened": false,
	"final_choice_made": false,
	"player_chose_fight": false,
	"player_chose_join": false,
	"player_chose_save": false
}

# =============================================================================
# WORLD STATE
# =============================================================================

var current_area: String = ""
var current_map: String = ""
var player_position: Vector2 = Vector2.ZERO
var visited_areas: Array[String] = []

# =============================================================================
# RUNTIME STATS
# =============================================================================

var play_time_seconds: float = 0.0
var battle_count: int = 0
var victory_count: int = 0
var defeat_count: int = 0
var flee_count: int = 0
var purification_attempts: int = 0
var purification_successes: int = 0
var monsters_defeated: int = 0
var currency: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_signals()
	_setup_window()
	is_initialized = true
	EventBus.emit_debug("GameManager initialized")

func _setup_window() -> void:
	"""Configure window to fit screen with taskbar"""
	# Get usable screen area (excludes taskbar)
	var screen_id := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen_id)

	# Target 90% of usable area to leave some margin
	var target_width := int(usable_rect.size.x * 0.9)
	var target_height := int(usable_rect.size.y * 0.9)

	# Maintain 16:9 aspect ratio
	var aspect := 16.0 / 9.0
	if float(target_width) / float(target_height) > aspect:
		target_width = int(target_height * aspect)
	else:
		target_height = int(target_width / aspect)

	# Set window size and center it
	DisplayServer.window_set_size(Vector2i(target_width, target_height))

	# Center window in usable area
	var center_x := usable_rect.position.x + (usable_rect.size.x - target_width) / 2
	var center_y := usable_rect.position.y + (usable_rect.size.y - target_height) / 2
	DisplayServer.window_set_position(Vector2i(center_x, center_y))

	EventBus.emit_debug("Window sized to %dx%d, positioned at (%d, %d)" % [target_width, target_height, center_x, center_y])

func _process(delta: float) -> void:
	if current_state in [Enums.GameState.OVERWORLD, Enums.GameState.BATTLE, Enums.GameState.DIALOGUE]:
		play_time_seconds += delta

func _connect_signals() -> void:
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.purification_succeeded.connect(_on_purification_succeeded)
	EventBus.purification_failed.connect(_on_purification_failed)
	EventBus.path_alignment_changed.connect(_on_path_alignment_changed)

# =============================================================================
# STATE MANAGEMENT
# =============================================================================

func change_state(new_state: Enums.GameState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state

	EventBus.game_state_changed.emit(previous_state, new_state)
	EventBus.emit_debug("State changed: %s -> %s" % [
		Enums.GameState.keys()[previous_state],
		Enums.GameState.keys()[new_state]
	])

func is_state(state: Enums.GameState) -> bool:
	return current_state == state

func is_paused() -> bool:
	return current_state == Enums.GameState.PAUSED

func is_in_battle() -> bool:
	return current_state == Enums.GameState.BATTLE

func is_in_dialogue() -> bool:
	return current_state == Enums.GameState.DIALOGUE

func return_to_previous_state() -> void:
	change_state(previous_state)

# =============================================================================
# PARTY MANAGEMENT
# =============================================================================

func add_to_party(character: Node) -> bool:
	if player_party.size() >= Constants.MAX_PARTY_SIZE:
		if reserve_party.size() >= Constants.MAX_RESERVE_SIZE:
			return false
		reserve_party.append(character)
	else:
		player_party.append(character)
	return true

func remove_from_party(character: Node) -> bool:
	if character in player_party:
		player_party.erase(character)
		return true
	if character in reserve_party:
		reserve_party.erase(character)
		return true
	return false

func swap_party_member(party_index: int, reserve_index: int) -> void:
	if party_index >= player_party.size() or reserve_index >= reserve_party.size():
		return
	var temp = player_party[party_index]
	player_party[party_index] = reserve_party[reserve_index]
	reserve_party[reserve_index] = temp

func get_active_party() -> Array:
	return player_party.filter(func(c): return c != null)

func get_party_size() -> int:
	return player_party.size()

# =============================================================================
# PROGRESSION
# =============================================================================

func modify_path_alignment(amount: float, source: String = "") -> void:
	var old_value := path_alignment
	path_alignment = clampf(path_alignment + amount, Constants.PATH_MIN, Constants.PATH_MAX)
	if path_alignment != old_value:
		EventBus.path_alignment_changed.emit(old_value, path_alignment)
		EventBus.emit_debug("Path alignment: %.1f -> %.1f (source: %s)" % [old_value, path_alignment, source])

func get_current_path() -> Enums.Path:
	if path_alignment <= -51:
		return Enums.Path.SHADE
	elif path_alignment <= -26:
		return Enums.Path.TWILIGHT
	elif path_alignment <= 25:
		return Enums.Path.NEUTRAL
	elif path_alignment <= 50:
		return Enums.Path.LIGHT
	else:
		return Enums.Path.SERAPH

func get_path_name() -> String:
	match get_current_path():
		Enums.Path.SHADE:
			return "Shade"
		Enums.Path.TWILIGHT:
			return "Twilight"
		Enums.Path.NEUTRAL:
			return "Neutral"
		Enums.Path.LIGHT:
			return "Light"
		Enums.Path.SERAPH:
			return "Seraph"
	return "Unknown"

func set_story_flag(flag: String, value: Variant = true) -> void:
	story_flags[flag] = value
	EventBus.story_flag_set.emit(flag, value)

func get_story_flag(flag: String, default: Variant = false) -> Variant:
	return story_flags.get(flag, default)

func has_story_flag(flag: String) -> bool:
	return story_flags.has(flag) and story_flags[flag]

func set_vera_flag(flag: String, value: bool = true) -> void:
	if vera_story_flags.has(flag):
		vera_story_flags[flag] = value
		EventBus.story_flag_set.emit(flag, value)

func get_vera_flag(flag: String) -> bool:
	return vera_story_flags.get(flag, false)

func unlock_brand(brand: Enums.Brand) -> void:
	if brand not in unlocked_brands:
		unlocked_brands.append(brand)
		EventBus.brand_unlocked.emit(brand)
		EventBus.emit_debug("Brand unlocked: %s" % Enums.Brand.keys()[brand])

func has_brand(brand: Enums.Brand) -> bool:
	return brand in unlocked_brands

# =============================================================================
# ALIGNMENT HELPERS
# =============================================================================

func get_alignment() -> float:
	return path_alignment

func add_alignment(amount: float) -> void:
	modify_path_alignment(amount, "direct")

# =============================================================================
# VERA MANAGEMENT
# =============================================================================

func use_vera_power(amount: float) -> void:
	vera_power_used += amount
	vera_corruption = clampf(vera_corruption + amount * 0.1, 0.0, 100.0)
	_update_vera_state()

func reduce_vera_corruption(amount: float) -> void:
	var old := vera_corruption
	vera_corruption = clampf(vera_corruption - amount, 0.0, 100.0)
	if vera_corruption != old:
		_update_vera_state()

func update_vera_state(new_state: Enums.VERAState) -> void:
	## Directly set VERA state (for debug/testing)
	var old_state := vera_state
	if new_state != old_state:
		vera_state = new_state
		EventBus.vera_state_changed.emit(old_state, new_state)
		EventBus.emit_debug("VERA state manually set: %s -> %s" % [
			Enums.VERAState.keys()[old_state],
			Enums.VERAState.keys()[new_state]
		])

func _update_vera_state() -> void:
	var old_state := vera_state
	var new_state := Enums.VERAState.INTERFACE

	if vera_corruption >= Constants.VERA_APOTHEOSIS_THRESHOLD:
		new_state = Enums.VERAState.APOTHEOSIS
	elif vera_corruption >= Constants.VERA_EMERGENCE_THRESHOLD:
		new_state = Enums.VERAState.EMERGENCE
	elif vera_corruption >= Constants.VERA_FRACTURE_THRESHOLD:
		new_state = Enums.VERAState.FRACTURE

	if new_state != old_state:
		vera_state = new_state
		EventBus.vera_state_changed.emit(old_state, new_state)
		EventBus.emit_debug("VERA state changed: %s -> %s" % [
			Enums.VERAState.keys()[old_state],
			Enums.VERAState.keys()[new_state]
		])

# =============================================================================
# MONSTER COLLECTION
# =============================================================================

func add_monster_to_collection(monster_id: String, monster_level: int) -> void:
	owned_monsters.append({
		"id": monster_id,
		"level": monster_level,
		"captured_at": Time.get_unix_time_from_system()
	})
	EventBus.emit_debug("Monster added to collection: %s (Lv.%d)" % [monster_id, monster_level])

# =============================================================================
# CURRENCY
# =============================================================================

func add_currency(amount: int) -> void:
	var old := currency
	currency += amount
	EventBus.currency_changed.emit(old, currency)

func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false
	var old := currency
	currency -= amount
	EventBus.currency_changed.emit(old, currency)
	return true

func can_afford(amount: int) -> bool:
	return currency >= amount

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_battle_ended(victory: bool, _rewards: Dictionary) -> void:
	battle_count += 1
	if victory:
		victory_count += 1
	else:
		defeat_count += 1

func _on_purification_succeeded(_monster: Node) -> void:
	purification_successes += 1
	purification_attempts += 1

func _on_purification_failed(_monster: Node) -> void:
	purification_attempts += 1

func _on_path_alignment_changed(_old: float, _new: float) -> void:
	# Check for brand unlocks based on alignment
	if path_alignment >= 50 and not has_brand(Enums.Brand.RADIANT):
		unlock_brand(Enums.Brand.RADIANT)
	if path_alignment <= -50 and not has_brand(Enums.Brand.VOID):
		unlock_brand(Enums.Brand.VOID)

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"version": ProjectSettings.get_setting("application/config/version"),
		"play_time": play_time_seconds,
		"player_level": player_level,
		"total_experience": total_experience,
		"path_alignment": path_alignment,
		"unlocked_brands": unlocked_brands,
		"story_flags": story_flags,
		"current_chapter": current_chapter,
		"current_area": current_area,
		"current_map": current_map,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"visited_areas": visited_areas,
		"battle_count": battle_count,
		"victory_count": victory_count,
		"defeat_count": defeat_count,
		"flee_count": flee_count,
		"purification_attempts": purification_attempts,
		"purification_successes": purification_successes,
		"monsters_defeated": monsters_defeated,
		"currency": currency,
		"vera_state": vera_state,
		"vera_corruption": vera_corruption,
		"vera_power_used": vera_power_used,
		"owned_monsters": owned_monsters
	}

func load_save_data(data: Dictionary) -> void:
	play_time_seconds = data.get("play_time", 0.0)
	player_level = data.get("player_level", 1)
	total_experience = data.get("total_experience", 0)
	path_alignment = data.get("path_alignment", 0.0)
	unlocked_brands = data.get("unlocked_brands", [Enums.Brand.NONE])
	story_flags = data.get("story_flags", {})
	current_chapter = data.get("current_chapter", 1)
	current_area = data.get("current_area", "")
	current_map = data.get("current_map", "")
	var pos = data.get("player_position", {"x": 0, "y": 0})
	player_position = Vector2(pos.x, pos.y)
	visited_areas = data.get("visited_areas", [])
	battle_count = data.get("battle_count", 0)
	victory_count = data.get("victory_count", 0)
	defeat_count = data.get("defeat_count", 0)
	flee_count = data.get("flee_count", 0)
	purification_attempts = data.get("purification_attempts", 0)
	purification_successes = data.get("purification_successes", 0)
	monsters_defeated = data.get("monsters_defeated", 0)
	currency = data.get("currency", 0)
	vera_state = data.get("vera_state", Enums.VERAState.INTERFACE)
	vera_corruption = data.get("vera_corruption", 0.0)
	vera_power_used = data.get("vera_power_used", 0.0)
	owned_monsters = data.get("owned_monsters", [])

# =============================================================================
# UTILITY
# =============================================================================

func get_formatted_play_time() -> String:
	var total_seconds := int(play_time_seconds)
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func get_purification_rate() -> float:
	if purification_attempts == 0:
		return 0.0
	return float(purification_successes) / float(purification_attempts) * 100.0

func reset_for_new_game() -> void:
	player_party.clear()
	reserve_party.clear()
	owned_monsters.clear()
	player_level = 1
	total_experience = 0
	path_alignment = 0.0
	unlocked_brands = [Enums.Brand.NONE]
	story_flags.clear()
	current_chapter = 1
	current_area = ""
	current_map = ""
	player_position = Vector2.ZERO
	visited_areas.clear()
	play_time_seconds = 0.0
	battle_count = 0
	victory_count = 0
	defeat_count = 0
	flee_count = 0
	purification_attempts = 0
	purification_successes = 0
	monsters_defeated = 0
	currency = 0
	vera_state = Enums.VERAState.INTERFACE
	vera_corruption = 0.0
	vera_power_used = 0.0
	EventBus.emit_debug("Game reset for new game")
