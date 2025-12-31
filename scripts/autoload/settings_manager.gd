extends Node
## SettingsManager: Handles all game settings with persistence.

# =============================================================================
# DEFAULT SETTINGS
# =============================================================================

const DEFAULTS := {
	# Audio
	"audio/master_volume": 1.0,
	"audio/music_volume": 0.8,
	"audio/sfx_volume": 1.0,
	"audio/voice_volume": 1.0,
	"audio/mute_when_unfocused": true,

	# Display
	"display/fullscreen": false,  # Default to windowed for easier development
	"display/vsync": true,
	"display/resolution_index": 0,
	"display/ui_scale": 1.0,
	"display/brightness": 1.0,

	# Gameplay
	"gameplay/text_speed": 1.0,
	"gameplay/auto_advance_dialogue": false,
	"gameplay/battle_animations": true,
	"gameplay/confirm_flee": true,
	"gameplay/show_damage_numbers": true,
	"gameplay/show_battle_log": true,
	"gameplay/auto_save": true,

	# Accessibility
	"accessibility/screen_shake": true,
	"accessibility/flash_effects": true,
	"accessibility/colorblind_mode": 0,  # 0=Off, 1=Protanopia, 2=Deuteranopia, 3=Tritanopia
	"accessibility/large_text": false,
	"accessibility/reduce_motion": false,

	# Controls
	"controls/key_bindings": {},
	"controls/gamepad_vibration": true
}

# Resolution options
const RESOLUTIONS := [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 576)
]

# =============================================================================
# STATE
# =============================================================================

var settings: Dictionary = {}
var _config: ConfigFile

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_config = ConfigFile.new()
	_load_settings()
	_apply_all_settings()
	EventBus.emit_debug("SettingsManager initialized")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if get_setting("audio/mute_when_unfocused"):
			AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if get_setting("audio/mute_when_unfocused"):
			AudioServer.set_bus_mute(0, false)

# =============================================================================
# SETTINGS ACCESS
# =============================================================================

func get_setting(key: String) -> Variant:
	if settings.has(key):
		return settings[key]
	if DEFAULTS.has(key):
		return DEFAULTS[key]
	push_warning("Unknown setting requested: %s" % key)
	return null

func set_setting(key: String, value: Variant, apply: bool = true) -> void:
	var old_value = get_setting(key)
	settings[key] = value

	if apply:
		_apply_setting(key, value)

	EventBus.settings_changed.emit(key, value)
	EventBus.emit_debug("Setting changed: %s = %s (was %s)" % [key, value, old_value])

func reset_to_defaults() -> void:
	settings = DEFAULTS.duplicate(true)
	_apply_all_settings()
	save_settings()
	EventBus.emit_notification("Settings reset to defaults", "info")

func reset_category(category: String) -> void:
	for key in DEFAULTS:
		if key.begins_with(category + "/"):
			settings[key] = DEFAULTS[key]
			_apply_setting(key, settings[key])
	save_settings()

# =============================================================================
# PERSISTENCE
# =============================================================================

func _load_settings() -> void:
	settings = DEFAULTS.duplicate(true)

	var error := _config.load(Constants.SETTINGS_FILE)
	if error != OK:
		EventBus.emit_debug("No settings file found, using defaults")
		return

	for section in _config.get_sections():
		for key in _config.get_section_keys(section):
			var full_key := "%s/%s" % [section, key]
			if DEFAULTS.has(full_key):
				settings[full_key] = _config.get_value(section, key)

	EventBus.emit_debug("Settings loaded from file")

func save_settings() -> void:
	for key in settings:
		var parts: PackedStringArray = key.split("/")
		if parts.size() == 2:
			_config.set_value(parts[0], parts[1], settings[key])

	var error := _config.save(Constants.SETTINGS_FILE)
	if error != OK:
		push_error("Failed to save settings: %s" % error)
	else:
		EventBus.emit_debug("Settings saved")

# =============================================================================
# APPLY SETTINGS
# =============================================================================

func _apply_all_settings() -> void:
	for key in settings:
		_apply_setting(key, settings[key])

func _apply_setting(key: String, value: Variant) -> void:
	match key:
		# Audio
		"audio/master_volume":
			AudioManager.set_bus_volume("Master", value)
		"audio/music_volume":
			AudioManager.set_bus_volume("Music", value)
		"audio/sfx_volume":
			AudioManager.set_bus_volume("SFX", value)
		"audio/voice_volume":
			AudioManager.set_bus_volume("Voice", value)

		# Display
		"display/fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"display/vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
			)
		"display/resolution_index":
			if not get_setting("display/fullscreen"):
				var res_index: int = value
				if res_index >= 0 and res_index < RESOLUTIONS.size():
					var resolution: Vector2i = RESOLUTIONS[res_index]
					DisplayServer.window_set_size(resolution)
		"display/ui_scale":
			# Will be applied to UI theme
			pass

# =============================================================================
# CONVENIENCE METHODS - AUDIO
# =============================================================================

func get_master_volume() -> float:
	return get_setting("audio/master_volume")

func set_master_volume(value: float) -> void:
	set_setting("audio/master_volume", clampf(value, 0.0, 1.0))

func get_music_volume() -> float:
	return get_setting("audio/music_volume")

func set_music_volume(value: float) -> void:
	set_setting("audio/music_volume", clampf(value, 0.0, 1.0))

func get_sfx_volume() -> float:
	return get_setting("audio/sfx_volume")

func set_sfx_volume(value: float) -> void:
	set_setting("audio/sfx_volume", clampf(value, 0.0, 1.0))

func get_voice_volume() -> float:
	return get_setting("audio/voice_volume")

func set_voice_volume(value: float) -> void:
	set_setting("audio/voice_volume", clampf(value, 0.0, 1.0))

# =============================================================================
# CONVENIENCE METHODS - DISPLAY
# =============================================================================

func is_fullscreen() -> bool:
	return get_setting("display/fullscreen")

func toggle_fullscreen() -> void:
	set_setting("display/fullscreen", not is_fullscreen())

func is_vsync_enabled() -> bool:
	return get_setting("display/vsync")

func toggle_vsync() -> void:
	set_setting("display/vsync", not is_vsync_enabled())

func get_resolution_index() -> int:
	return get_setting("display/resolution_index")

func set_resolution_index(index: int) -> void:
	set_setting("display/resolution_index", clampi(index, 0, RESOLUTIONS.size() - 1))

func get_current_resolution() -> Vector2i:
	var index: int = get_resolution_index()
	return RESOLUTIONS[index]

func get_resolution_options() -> Array[String]:
	var options: Array[String] = []
	for res in RESOLUTIONS:
		options.append("%dx%d" % [res.x, res.y])
	return options

# =============================================================================
# CONVENIENCE METHODS - GAMEPLAY
# =============================================================================

func get_text_speed() -> float:
	return get_setting("gameplay/text_speed")

func set_text_speed(value: float) -> void:
	set_setting("gameplay/text_speed", clampf(value, 0.5, 3.0))

func is_auto_advance_enabled() -> bool:
	return get_setting("gameplay/auto_advance_dialogue")

func are_battle_animations_enabled() -> bool:
	return get_setting("gameplay/battle_animations")

func toggle_battle_animations() -> void:
	set_setting("gameplay/battle_animations", not are_battle_animations_enabled())

func should_confirm_flee() -> bool:
	return get_setting("gameplay/confirm_flee")

func should_show_damage_numbers() -> bool:
	return get_setting("gameplay/show_damage_numbers")

func is_autosave_enabled() -> bool:
	return get_setting("gameplay/auto_save")

# =============================================================================
# CONVENIENCE METHODS - ACCESSIBILITY
# =============================================================================

func is_screen_shake_enabled() -> bool:
	return get_setting("accessibility/screen_shake")

func toggle_screen_shake() -> void:
	set_setting("accessibility/screen_shake", not is_screen_shake_enabled())

func is_flash_effects_enabled() -> bool:
	return get_setting("accessibility/flash_effects")

func toggle_flash_effects() -> void:
	set_setting("accessibility/flash_effects", not is_flash_effects_enabled())

func get_colorblind_mode() -> int:
	return get_setting("accessibility/colorblind_mode")

func set_colorblind_mode(mode: int) -> void:
	set_setting("accessibility/colorblind_mode", clampi(mode, 0, 3))

func is_large_text_enabled() -> bool:
	return get_setting("accessibility/large_text")

func toggle_large_text() -> void:
	set_setting("accessibility/large_text", not is_large_text_enabled())

func is_reduced_motion_enabled() -> bool:
	return get_setting("accessibility/reduce_motion")

# =============================================================================
# UTILITY
# =============================================================================

func get_all_settings() -> Dictionary:
	return settings.duplicate()

func get_settings_for_category(category: String) -> Dictionary:
	var result := {}
	for key in settings:
		if key.begins_with(category + "/"):
			result[key] = settings[key]
	return result
