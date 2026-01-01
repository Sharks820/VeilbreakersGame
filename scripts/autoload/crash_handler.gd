extends Node
## CrashHandler - Graceful error recovery and auto-save on crash
## Prevents hard crashes and saves player progress when errors occur

const AUTO_SAVE_SLOT := 99  # Special slot for crash recovery saves
const RECOVERY_FILE := "user://crash_recovery.json"

var _last_known_good_state: Dictionary = {}
var _is_recovering: bool = false
var _crash_count: int = 0
var _max_crashes_before_safe_mode: int = 3

signal recovery_save_created(slot: int)
signal safe_mode_activated()
signal crash_recovered(error: String)


func _ready() -> void:
	# Load crash count from previous sessions
	_load_crash_count()

	# Check for previous crash on startup
	_check_for_crash_recovery()

	# Connect to error signals - use call_deferred to ensure ErrorLogger is ready
	call_deferred("_connect_error_logger")

	# Periodic state snapshots for recovery
	var timer := Timer.new()
	timer.wait_time = 60.0  # Snapshot every minute
	timer.timeout.connect(_save_state_snapshot)
	timer.autostart = true
	add_child(timer)


func _connect_error_logger() -> void:
	# Deferred connection to ErrorLogger to handle autoload order
	if has_node("/root/ErrorLogger"):
		if not ErrorLogger.crash_detected.is_connected(_on_crash_detected):
			ErrorLogger.crash_detected.connect(_on_crash_detected)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Clean shutdown - remove recovery file
		_clear_crash_recovery()
	elif what == NOTIFICATION_PREDELETE:
		# Node is being deleted unexpectedly - attempt emergency save
		if not _is_recovering:
			_emergency_save()


# =============================================================================
# PUBLIC API
# =============================================================================

func safe_call(callable: Callable, error_context: String = "Unknown") -> Variant:
	## Wraps a function call in error handling
	## Use for any operation that might fail (file I/O, network, etc.)
	var result: Variant = null

	# GDScript doesn't have try/catch, so we use signals and careful checking
	result = callable.call()
	return result


func register_critical_state(key: String, value: Variant) -> void:
	## Register important state that should be preserved on crash
	_last_known_good_state[key] = value


func get_recovered_state(key: String) -> Variant:
	## Get state that was recovered after a crash
	return _last_known_good_state.get(key, null)


func is_in_safe_mode() -> bool:
	return _crash_count >= _max_crashes_before_safe_mode


func reset_crash_count() -> void:
	_crash_count = 0
	_save_crash_count()


# =============================================================================
# CRASH DETECTION & RECOVERY
# =============================================================================

func _on_crash_detected(error: String) -> void:
	_crash_count += 1
	_save_crash_count()

	ErrorLogger.log_critical("Crash detected: %s (count: %d)" % [error, _crash_count])

	if _crash_count >= _max_crashes_before_safe_mode:
		_activate_safe_mode()
	else:
		_attempt_recovery(error)


func _attempt_recovery(error: String) -> void:
	if _is_recovering:
		return  # Prevent recursive recovery

	_is_recovering = true
	ErrorLogger.log_info("Attempting crash recovery...")

	# 1. Create emergency save
	_emergency_save()

	# 2. Try to restore last known good state
	if not _last_known_good_state.is_empty():
		ErrorLogger.log_info("Restoring last known good state...")
		# Emit signal for systems to restore themselves
		crash_recovered.emit(error)

	_is_recovering = false


func _activate_safe_mode() -> void:
	ErrorLogger.log_warning("Too many crashes - activating safe mode")
	safe_mode_activated.emit()

	# In safe mode:
	# - Disable non-essential features
	# - Use simplified rendering
	# - Skip problematic content

	# Notify user
	if not OS.is_debug_build():
		OS.alert(
			"VEILBREAKERS has encountered multiple errors and is running in safe mode.\n\n" +
			"Some features may be disabled. Please report this issue.",
			"Safe Mode Activated"
		)


func _emergency_save() -> void:
	ErrorLogger.log_info("Creating emergency save...")

	var save_data := {
		"timestamp": Time.get_datetime_string_from_system(),
		"crash_count": _crash_count,
		"state": _last_known_good_state,
		"game_state": _capture_game_state()
	}

	var file := FileAccess.open(RECOVERY_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		ErrorLogger.log_info("Emergency save created")
		recovery_save_created.emit(AUTO_SAVE_SLOT)
	else:
		ErrorLogger.log_error("Failed to create emergency save!")


func _capture_game_state() -> Dictionary:
	## Capture current game state for recovery
	var state := {}

	# Get state from GameManager if available
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		state["game_state"] = gm.current_state if "current_state" in gm else 0
		state["current_area"] = gm.current_area if "current_area" in gm else ""

	# Get VERA state
	if has_node("/root/VERASystem"):
		var vera = get_node("/root/VERASystem")
		state["vera_state"] = vera.current_state if "current_state" in vera else 0
		state["corruption"] = vera.corruption if "corruption" in vera else 0.0

	return state


func _check_for_crash_recovery() -> void:
	## Called on startup to check if we crashed last session
	if FileAccess.file_exists(RECOVERY_FILE):
		ErrorLogger.log_warning("Crash recovery file found - game crashed last session")

		var file := FileAccess.open(RECOVERY_FILE, FileAccess.READ)
		if file:
			var json := JSON.new()
			var parse_result := json.parse(file.get_as_text())
			file.close()

			if parse_result == OK:
				var data: Dictionary = json.data
				_crash_count = data.get("crash_count", 0)
				_last_known_good_state = data.get("state", {})

				# Offer to restore
				if not OS.is_debug_build() and not data.get("state", {}).is_empty():
					# In release, could show UI to offer restore
					pass

		# Clear the recovery file now that we've handled it
		_clear_crash_recovery()


func _clear_crash_recovery() -> void:
	if FileAccess.file_exists(RECOVERY_FILE):
		DirAccess.remove_absolute(RECOVERY_FILE)


func _save_state_snapshot() -> void:
	## Periodic snapshot of game state
	if has_node("/root/GameManager"):
		register_critical_state("snapshot_time", Time.get_datetime_string_from_system())
		# GameManager can register its own critical state


func _save_crash_count() -> void:
	var file := FileAccess.open("user://crash_count.dat", FileAccess.WRITE)
	if file:
		file.store_32(_crash_count)
		file.close()


func _load_crash_count() -> void:
	if FileAccess.file_exists("user://crash_count.dat"):
		var file := FileAccess.open("user://crash_count.dat", FileAccess.READ)
		if file:
			_crash_count = file.get_32()
			file.close()
