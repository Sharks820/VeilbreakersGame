extends Control
## SettingsMenu: Full-featured settings panel with audio, display, gameplay, and accessibility options.
## Matches the dark fantasy horror aesthetic of VEILBREAKERS.

signal settings_closed

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var panel: PanelContainer = $Panel
@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HeaderContainer/CloseButton

# Audio tab
@onready var master_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterVolume/HSlider
@onready var music_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SFXVolume/HSlider
@onready var voice_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/VoiceVolume/HSlider
@onready var mute_unfocused_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MuteUnfocused/CheckButton

# Display tab
@onready var fullscreen_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/Fullscreen/CheckButton
@onready var vsync_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/VSync/CheckButton
@onready var resolution_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/Resolution/OptionButton
@onready var brightness_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/Brightness/HSlider

# Gameplay tab
@onready var text_speed_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/TextSpeed/HSlider
@onready var battle_anims_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/BattleAnimations/CheckButton
@onready var damage_numbers_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/DamageNumbers/CheckButton
@onready var battle_log_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/BattleLog/CheckButton
@onready var autosave_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Gameplay/VBoxContainer/AutoSave/CheckButton

# Accessibility tab
@onready var screen_shake_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Accessibility/VBoxContainer/ScreenShake/CheckButton
@onready var flash_effects_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Accessibility/VBoxContainer/FlashEffects/CheckButton
@onready var reduce_motion_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Accessibility/VBoxContainer/ReduceMotion/CheckButton
@onready var large_text_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Accessibility/VBoxContainer/LargeText/CheckButton

# Footer buttons
@onready var reset_button: Button = $Panel/MarginContainer/VBoxContainer/FooterContainer/ResetButton
@onready var apply_button: Button = $Panel/MarginContainer/VBoxContainer/FooterContainer/ApplyButton

# =============================================================================
# STATE
# =============================================================================

var is_open: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Hide on start
	visible = false
	modulate.a = 0.0
	
	# Connect signals
	_connect_signals()
	
	# Load current settings
	_load_settings()
	
	# Setup resolution options
	_setup_resolution_options()

func _connect_signals() -> void:
	# Close button
	close_button.pressed.connect(_on_close_pressed)
	
	# Audio sliders
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	voice_slider.value_changed.connect(_on_voice_volume_changed)
	mute_unfocused_check.toggled.connect(_on_mute_unfocused_toggled)
	
	# Display options
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	
	# Gameplay options
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	battle_anims_check.toggled.connect(_on_battle_anims_toggled)
	damage_numbers_check.toggled.connect(_on_damage_numbers_toggled)
	battle_log_check.toggled.connect(_on_battle_log_toggled)
	autosave_check.toggled.connect(_on_autosave_toggled)
	
	# Accessibility options
	screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	flash_effects_check.toggled.connect(_on_flash_effects_toggled)
	reduce_motion_check.toggled.connect(_on_reduce_motion_toggled)
	large_text_check.toggled.connect(_on_large_text_toggled)
	
	# Footer buttons
	reset_button.pressed.connect(_on_reset_pressed)
	apply_button.pressed.connect(_on_apply_pressed)

func _setup_resolution_options() -> void:
	resolution_option.clear()
	var options := SettingsManager.get_resolution_options()
	for i in range(options.size()):
		resolution_option.add_item(options[i], i)

func _load_settings() -> void:
	# Audio
	master_slider.value = SettingsManager.get_master_volume()
	music_slider.value = SettingsManager.get_music_volume()
	sfx_slider.value = SettingsManager.get_sfx_volume()
	voice_slider.value = SettingsManager.get_voice_volume()
	mute_unfocused_check.button_pressed = SettingsManager.get_setting("audio/mute_when_unfocused")
	
	# Display
	fullscreen_check.button_pressed = SettingsManager.is_fullscreen()
	vsync_check.button_pressed = SettingsManager.is_vsync_enabled()
	resolution_option.selected = SettingsManager.get_resolution_index()
	brightness_slider.value = SettingsManager.get_setting("display/brightness")
	
	# Gameplay
	text_speed_slider.value = SettingsManager.get_text_speed()
	battle_anims_check.button_pressed = SettingsManager.are_battle_animations_enabled()
	damage_numbers_check.button_pressed = SettingsManager.should_show_damage_numbers()
	battle_log_check.button_pressed = SettingsManager.get_setting("gameplay/show_battle_log")
	autosave_check.button_pressed = SettingsManager.is_autosave_enabled()
	
	# Accessibility
	screen_shake_check.button_pressed = SettingsManager.is_screen_shake_enabled()
	flash_effects_check.button_pressed = SettingsManager.is_flash_effects_enabled()
	reduce_motion_check.button_pressed = SettingsManager.is_reduced_motion_enabled()
	large_text_check.button_pressed = SettingsManager.is_large_text_enabled()

# =============================================================================
# OPEN/CLOSE
# =============================================================================

func open() -> void:
	if is_open:
		return
	
	is_open = true
	visible = true
	_load_settings()
	
	# Animate in
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	
	# Scale animation for panel
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2.0
	var panel_tween := create_tween()
	panel_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	close_button.grab_focus()

func close() -> void:
	if not is_open:
		return
	
	is_open = false
	
	# Save settings on close
	SettingsManager.save_settings()
	
	# Animate out
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false)
	
	settings_closed.emit()

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# AUDIO CALLBACKS
# =============================================================================

func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)

func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)

func _on_voice_volume_changed(value: float) -> void:
	SettingsManager.set_voice_volume(value)

func _on_mute_unfocused_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("audio/mute_when_unfocused", pressed)

# =============================================================================
# DISPLAY CALLBACKS
# =============================================================================

func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("display/fullscreen", pressed)

func _on_vsync_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("display/vsync", pressed)

func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution_index(index)

func _on_brightness_changed(value: float) -> void:
	SettingsManager.set_setting("display/brightness", value)

# =============================================================================
# GAMEPLAY CALLBACKS
# =============================================================================

func _on_text_speed_changed(value: float) -> void:
	SettingsManager.set_text_speed(value)

func _on_battle_anims_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay/battle_animations", pressed)

func _on_damage_numbers_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay/show_damage_numbers", pressed)

func _on_battle_log_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay/show_battle_log", pressed)

func _on_autosave_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay/auto_save", pressed)

# =============================================================================
# ACCESSIBILITY CALLBACKS
# =============================================================================

func _on_screen_shake_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("accessibility/screen_shake", pressed)

func _on_flash_effects_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("accessibility/flash_effects", pressed)

func _on_reduce_motion_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("accessibility/reduce_motion", pressed)

func _on_large_text_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("accessibility/large_text", pressed)

# =============================================================================
# FOOTER CALLBACKS
# =============================================================================

func _on_close_pressed() -> void:
	close()

func _on_reset_pressed() -> void:
	SettingsManager.reset_to_defaults()
	_load_settings()
	EventBus.emit_notification("Settings reset to defaults", "info")

func _on_apply_pressed() -> void:
	SettingsManager.save_settings()
	EventBus.emit_notification("Settings saved", "success")
