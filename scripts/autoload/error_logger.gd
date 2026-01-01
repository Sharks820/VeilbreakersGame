extends Node
## ErrorLogger - Cross-platform error logging and crash reporting
## Ships with the game - provides error logs users can submit for bug reports

# Log file location (user:// is cross-platform safe)
const LOG_DIR := "user://logs/"
const MAX_LOG_FILES := 5  # Keep last 5 sessions
const MAX_LOG_SIZE := 1048576  # 1MB per log file

var _log_file: FileAccess
var _session_id: String
var _log_path: String
var _error_count: int = 0
var _warning_count: int = 0

# Telemetry consent (default off - must be opted in)
var telemetry_enabled: bool = false

signal error_logged(message: String, severity: String)
signal crash_detected(error: String)


func _init() -> void:
	# Run window setup as early as possible (before _ready)
	call_deferred("_setup_window_size")

func _ready() -> void:

	_session_id = _generate_session_id()
	_ensure_log_directory()
	_cleanup_old_logs()
	_open_log_file()

	# Log session start after log file is ready
	_log_session_start()

	# Connect to Godot's error output
	if OS.is_debug_build():
		push_warning("[ErrorLogger] Running in debug mode - verbose logging enabled")

func _setup_window_size() -> void:
	"""Configure window to fit screen with taskbar - runs FIRST"""
	# Only adjust in windowed mode
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return

	# Get usable screen area (excludes taskbar)
	var screen_id := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen_id)

	# Target 90% of usable area to leave margin
	var target_width := int(usable_rect.size.x * 0.9)
	var target_height := int(usable_rect.size.y * 0.9)

	# Maintain 16:9 aspect ratio
	var aspect := 16.0 / 9.0
	if float(target_width) / float(target_height) > aspect:
		target_width = int(target_height * aspect)
	else:
		target_height = int(target_width / aspect)

	# Set window size
	DisplayServer.window_set_size(Vector2i(target_width, target_height))

	# Center in usable area
	var center_x := usable_rect.position.x + (usable_rect.size.x - target_width) / 2
	var center_y := usable_rect.position.y + (usable_rect.size.y - target_height) / 2
	DisplayServer.window_set_position(Vector2i(center_x, center_y))
	print("[Window] Sized to %dx%d at (%d, %d)" % [target_width, target_height, center_x, center_y])

func _log_session_start() -> void:
	_log("INFO", "=== SESSION START ===")
	_log("INFO", "Session ID: %s" % _session_id)
	_log("INFO", "Game Version: %s" % ProjectSettings.get_setting("application/config/version", "0.0.0"))
	_log("INFO", "Platform: %s" % OS.get_name())
	_log("INFO", "Godot Version: %s" % Engine.get_version_info().string)
	_log("INFO", "========================")

func _exit_tree() -> void:
	_log("INFO", "=== SESSION END ===")
	_log("INFO", "Errors: %d | Warnings: %d" % [_error_count, _warning_count])
	_close_log_file()


# =============================================================================
# PUBLIC API
# =============================================================================

func log_info(message: String, context: String = "") -> void:
	_log("INFO", message, context)


func log_debug(message: String, context: String = "") -> void:
	## Debug messages only show in debug builds
	if OS.is_debug_build():
		_log("DEBUG", message, context)


func log_warning(message: String, context: String = "") -> void:
	_warning_count += 1
	_log("WARN", message, context)
	error_logged.emit(message, "WARN")


func log_error(message: String, context: String = "") -> void:
	_error_count += 1
	_log("ERROR", message, context)
	error_logged.emit(message, "ERROR")

	# In release builds, show user-friendly error
	if not OS.is_debug_build():
		_show_error_popup(message)


func log_critical(message: String, context: String = "") -> void:
	_error_count += 1
	_log("CRITICAL", message, context)
	error_logged.emit(message, "CRITICAL")
	crash_detected.emit(message)

	# Always show critical errors
	_show_error_popup("A critical error occurred. The game will try to continue.\n\nError: " + message)


func log_exception(message: String, stack_trace: String = "") -> void:
	_error_count += 1
	var full_message := message
	if stack_trace:
		full_message += "\nStack trace:\n" + stack_trace
	_log("EXCEPTION", full_message)
	error_logged.emit(message, "EXCEPTION")


func log_battle_event(event_type: String, details: Dictionary) -> void:
	## Special logging for battle events - helps debug combat issues
	var detail_str := JSON.stringify(details)
	_log("BATTLE", "%s: %s" % [event_type, detail_str])


func log_save_event(event_type: String, slot: int, success: bool) -> void:
	## Log save/load operations
	_log("SAVE", "%s slot %d: %s" % [event_type, slot, "SUCCESS" if success else "FAILED"])


# =============================================================================
# LOG FILE MANAGEMENT
# =============================================================================

func get_log_path() -> String:
	return _log_path


func get_all_log_files() -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(LOG_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name:
			if file_name.ends_with(".log"):
				files.append(LOG_DIR + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return files


func get_current_log_contents() -> String:
	## Returns current log for bug report submission
	_close_log_file()
	var contents := ""
	var file := FileAccess.open(_log_path, FileAccess.READ)
	if file:
		contents = file.get_as_text()
		file.close()
	_open_log_file()
	return contents


func export_logs_for_report() -> String:
	## Creates a combined log export for bug reports
	var report := "=== VEILBREAKERS BUG REPORT ===\n"
	report += "Generated: %s\n" % Time.get_datetime_string_from_system()
	report += "Session ID: %s\n" % _session_id
	report += "Platform: %s\n" % OS.get_name()
	report += "Version: %s\n\n" % ProjectSettings.get_setting("application/config/version", "0.0.0")
	report += "=== CURRENT SESSION LOG ===\n"
	report += get_current_log_contents()
	return report


# =============================================================================
# INTERNAL METHODS
# =============================================================================

func _log(level: String, message: String, context: String = "") -> void:
	var timestamp := Time.get_datetime_string_from_system()
	var log_line := "[%s] [%s]" % [timestamp, level]

	if context:
		log_line += " [%s]" % context

	log_line += " %s\n" % message

	# Write to file
	if _log_file:
		_log_file.store_string(log_line)
		_log_file.flush()

	# Also print to console in debug builds
	if OS.is_debug_build():
		match level:
			"ERROR", "CRITICAL", "EXCEPTION":
				push_error(message)
			"WARN":
				push_warning(message)
			_:
				print(log_line.strip_edges())


func _generate_session_id() -> String:
	var time := Time.get_unix_time_from_system()
	var rand := randi()
	return "%d_%d" % [time, rand]


func _ensure_log_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("logs"):
		dir.make_dir("logs")


func _cleanup_old_logs() -> void:
	var files := get_all_log_files()
	if files.size() >= MAX_LOG_FILES:
		# Sort by name (which includes timestamp) and delete oldest
		files.sort()
		var to_delete := files.size() - MAX_LOG_FILES + 1
		for i in range(to_delete):
			DirAccess.remove_absolute(files[i])


func _open_log_file() -> void:
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	_log_path = LOG_DIR + "veilbreakers_%s.log" % timestamp
	_log_file = FileAccess.open(_log_path, FileAccess.WRITE)


func _close_log_file() -> void:
	if _log_file:
		_log_file.close()
		_log_file = null


func _show_error_popup(message: String) -> void:
	## Show user-friendly error in release builds
	# This will be connected to UI system
	if has_node("/root/SceneManager"):
		# Try to show in-game popup
		pass
	else:
		# Fallback to OS dialog
		OS.alert(message, "VEILBREAKERS Error")


# =============================================================================
# PERFORMANCE LOGGING
# =============================================================================

var _perf_timers: Dictionary = {}

func perf_start(label: String) -> void:
	_perf_timers[label] = Time.get_ticks_usec()


func perf_end(label: String) -> float:
	if not _perf_timers.has(label):
		return 0.0
	var start_time: int = _perf_timers[label]
	var elapsed: float = (Time.get_ticks_usec() - start_time) / 1000.0
	_perf_timers.erase(label)
	_log("PERF", "%s: %.3f ms" % [label, elapsed])
	return elapsed


# =============================================================================
# SYSTEM INFO (for bug reports)
# =============================================================================

func get_system_info() -> Dictionary:
	return {
		"os": OS.get_name(),
		"os_version": OS.get_version(),
		"processor_name": OS.get_processor_name(),
		"processor_count": OS.get_processor_count(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"video_vendor": RenderingServer.get_video_adapter_vendor(),
		"memory_mb": OS.get_static_memory_usage() / 1048576,
		"godot_version": Engine.get_version_info().string,
		"game_version": ProjectSettings.get_setting("application/config/version", "0.0.0"),
	}
