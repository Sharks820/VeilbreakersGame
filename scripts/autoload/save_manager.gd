extends Node
## SaveManager: Handles all save/load operations with multiple slots and validation.

# =============================================================================
# CONSTANTS
# =============================================================================

const SAVE_VERSION: int = 1
const ENCRYPTION_KEY: String = "veilbreakers_save_key_2024"  # Change for production

# =============================================================================
# STATE
# =============================================================================

var save_slots: Array[Dictionary] = []
var current_slot: int = -1
var is_saving: bool = false
var is_loading: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_ensure_save_directory()
	_load_slot_metadata()
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)
	EventBus.emit_debug("SaveManager initialized")

func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

# =============================================================================
# SLOT MANAGEMENT
# =============================================================================

func _load_slot_metadata() -> void:
	save_slots.clear()
	for i in range(Constants.MAX_SAVE_SLOTS):
		var slot_data := _get_slot_metadata(i)
		save_slots.append(slot_data)

func _get_slot_metadata(slot: int) -> Dictionary:
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {"empty": true, "slot": slot}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"empty": true, "slot": slot, "error": "Could not open file"}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		return {"empty": true, "slot": slot, "error": "Invalid JSON"}

	var data: Dictionary = json.data
	return {
		"empty": false,
		"slot": slot,
		"timestamp": data.get("timestamp", "Unknown"),
		"play_time": data.get("game_data", {}).get("play_time", 0.0),
		"chapter": data.get("game_data", {}).get("current_chapter", 1),
		"area": data.get("game_data", {}).get("current_area", "Unknown"),
		"version": data.get("version", 0)
	}

func get_slot_info(slot: int) -> Dictionary:
	if slot >= 0 and slot < save_slots.size():
		return save_slots[slot]
	return {"empty": true, "slot": slot}

func is_slot_empty(slot: int) -> bool:
	return get_slot_info(slot).get("empty", true)

func _get_save_path(slot: int) -> String:
	return Constants.SAVE_DIR + "slot_%d%s" % [slot, Constants.SAVE_FILE_EXTENSION]

func get_formatted_slot_time(slot: int) -> String:
	var info := get_slot_info(slot)
	if info.empty:
		return "Empty"
	var total_seconds := int(info.get("play_time", 0.0))
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	return "%02d:%02d" % [hours, minutes]

# =============================================================================
# SAVE OPERATIONS
# =============================================================================

func save_game(slot: int) -> bool:
	if is_saving:
		EventBus.emit_debug("Save already in progress")
		return false

	is_saving = true
	current_slot = slot

	var save_data := _compile_save_data()
	var success := _write_save_file(slot, save_data)

	is_saving = false

	if success:
		_load_slot_metadata()  # Refresh metadata
		EventBus.save_completed.emit(slot, true)
		EventBus.emit_notification("Game saved to Slot %d" % (slot + 1), "success")
	else:
		EventBus.save_completed.emit(slot, false)
		EventBus.emit_notification("Failed to save game", "error")

	return success

func _compile_save_data() -> Dictionary:
	var timestamp := Time.get_datetime_string_from_system()

	return {
		"version": SAVE_VERSION,
		"timestamp": timestamp,
		"game_data": GameManager.get_save_data(),
		"vera_data": _get_vera_save_data(),
		"inventory_data": _get_inventory_save_data(),
		"party_data": _get_party_save_data()
	}

func _get_vera_save_data() -> Dictionary:
	# Get VERA save data from VERASystem if available
	if has_node("/root/VERASystem"):
		return get_node("/root/VERASystem").get_save_data()
	return {
		"corruption_level": 0.0,
		"current_state": Enums.VERAState.INTERFACE
	}

func _get_inventory_save_data() -> Dictionary:
	# Will be implemented when InventorySystem exists
	return {
		"items": {},
		"equipment": {}
	}

func _get_party_save_data() -> Array:
	# Will be implemented when party system is complete
	return []

func _write_save_file(slot: int, data: Dictionary) -> bool:
	var path := _get_save_path(slot)
	var json_string := JSON.stringify(data, "  ")

	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file for writing: %s" % path)
		return false

	file.store_string(json_string)
	file.close()

	EventBus.emit_debug("Game saved to: %s" % path)
	return true

# =============================================================================
# LOAD OPERATIONS
# =============================================================================

func load_game(slot: int) -> bool:
	if is_loading:
		EventBus.emit_debug("Load already in progress")
		return false

	if is_slot_empty(slot):
		EventBus.emit_notification("No save data in Slot %d" % (slot + 1), "warning")
		return false

	is_loading = true
	current_slot = slot

	var save_data := _read_save_file(slot)
	if save_data.is_empty():
		is_loading = false
		EventBus.load_completed.emit(slot, false)
		return false

	var success := _apply_save_data(save_data)

	is_loading = false

	if success:
		EventBus.load_completed.emit(slot, true)
		EventBus.emit_notification("Game loaded from Slot %d" % (slot + 1), "success")
	else:
		EventBus.load_completed.emit(slot, false)
		EventBus.emit_notification("Failed to load game", "error")

	return success

func _read_save_file(slot: int) -> Dictionary:
	var path := _get_save_path(slot)

	if not FileAccess.file_exists(path):
		push_error("Save file does not exist: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file: %s" % path)
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file: %s" % json.get_error_message())
		return {}

	return json.data

func _apply_save_data(data: Dictionary) -> bool:
	# Version check
	var save_version: int = data.get("version", 0)
	if save_version > SAVE_VERSION:
		push_error("Save file version (%d) is newer than game version (%d)" % [save_version, SAVE_VERSION])
		return false

	# Apply game data
	if data.has("game_data"):
		GameManager.load_save_data(data.game_data)

	# Apply VERA data (when system exists)
	# Apply inventory data (when system exists)
	# Apply party data (when system exists)

	EventBus.emit_debug("Save data applied successfully")
	return true

# =============================================================================
# DELETE OPERATIONS
# =============================================================================

func delete_save(slot: int) -> bool:
	var path := _get_save_path(slot)

	if not FileAccess.file_exists(path):
		return true

	var dir := DirAccess.open(Constants.SAVE_DIR)
	if dir:
		var result := dir.remove(path.get_file())
		if result == OK:
			_load_slot_metadata()
			EventBus.emit_notification("Slot %d deleted" % (slot + 1), "info")
			return true

	return false

# =============================================================================
# AUTOSAVE
# =============================================================================

var _autosave_timer: float = 0.0

func _process(delta: float) -> void:
	if GameManager.current_state in [Enums.GameState.OVERWORLD]:
		_autosave_timer += delta
		if _autosave_timer >= Constants.AUTOSAVE_INTERVAL:
			_autosave_timer = 0.0
			autosave()

func autosave() -> void:
	if current_slot >= 0:
		EventBus.autosave_triggered.emit()
		save_game(current_slot)
		EventBus.emit_debug("Autosave completed")

func reset_autosave_timer() -> void:
	_autosave_timer = 0.0

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_save_requested(slot: int) -> void:
	save_game(slot)

func _on_load_requested(slot: int) -> void:
	load_game(slot)

# =============================================================================
# UTILITY
# =============================================================================

func has_any_saves() -> bool:
	for slot in save_slots:
		if not slot.get("empty", true):
			return true
	return false

func get_most_recent_slot() -> int:
	var most_recent := -1
	var most_recent_time := ""

	for i in range(save_slots.size()):
		var slot := save_slots[i]
		if not slot.get("empty", true):
			var timestamp: String = slot.get("timestamp", "")
			if timestamp > most_recent_time:
				most_recent_time = timestamp
				most_recent = i

	return most_recent
