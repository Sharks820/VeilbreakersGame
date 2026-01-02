class_name PauseMenuController
extends CanvasLayer
## PauseMenuController: Global pause menu accessible from anywhere via ESC.
## During battle: Cannot save, quit saves pre-battle position.

# =============================================================================
# SIGNALS
# =============================================================================

signal menu_closed()
signal quit_to_menu_requested()
signal quit_to_desktop_requested()

# =============================================================================
# CONSTANTS
# =============================================================================

const PANEL_WIDTH: int = 400
const BUTTON_HEIGHT: int = 50
const BUTTON_SPACING: int = 10

# =============================================================================
# STATE
# =============================================================================

var is_open: bool = false
var _previous_pause_state: bool = false
var _in_battle: bool = false

# =============================================================================
# UI REFERENCES
# =============================================================================

var _panel: PanelContainer
var _vbox: VBoxContainer
var _title_label: Label
var _resume_button: Button
var _settings_button: Button
var _save_button: Button
var _report_bug_button: Button
var _quit_menu_button: Button
var _quit_desktop_button: Button
var _battle_warning_label: Label

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	layer = 200  # Above everything
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_menu()
	
	# Connect to game state changes
	EventBus.game_state_changed.connect(_on_game_state_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_open:
			hide_menu()
		else:
			# Don't open pause menu during certain states
			var state := GameManager.current_state
			if state in [Enums.GameState.MAIN_MENU, Enums.GameState.LOADING, Enums.GameState.NONE]:
				return
			show_menu()
		get_viewport().set_input_as_handled()

# =============================================================================
# UI BUILDING
# =============================================================================

func _build_ui() -> void:
	# Dimmed background
	var bg := ColorRect.new()
	bg.name = "DimBackground"
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Center container
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Main panel with dark style
	_panel = PanelContainer.new()
	_panel.name = "MenuPanel"
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	
	# Create stylebox for panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_color = Color(0.3, 0.3, 0.4, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_panel)
	
	# VBox for content
	_vbox = VBoxContainer.new()
	_vbox.name = "VBoxContainer"
	_vbox.add_theme_constant_override("separation", BUTTON_SPACING)
	_panel.add_child(_vbox)
	
	# Title
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "PAUSED"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	_vbox.add_child(_title_label)
	
	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	_vbox.add_child(sep)
	
	# Battle warning (hidden by default)
	_battle_warning_label = Label.new()
	_battle_warning_label.name = "BattleWarning"
	_battle_warning_label.text = "Cannot save during battle.\nQuit will return you to before this battle."
	_battle_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_battle_warning_label.add_theme_font_size_override("font_size", 14)
	_battle_warning_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	_battle_warning_label.visible = false
	_vbox.add_child(_battle_warning_label)
	
	# Buttons
	_resume_button = _create_button("Resume", _on_resume_pressed)
	_settings_button = _create_button("Settings", _on_settings_pressed)
	_save_button = _create_button("Save Game", _on_save_pressed)
	_report_bug_button = _create_button("Report Bug", _on_report_bug_pressed)
	_quit_menu_button = _create_button("Quit to Menu", _on_quit_menu_pressed)
	_quit_desktop_button = _create_button("Quit to Desktop", _on_quit_desktop_pressed)
	
	# Style quit buttons differently
	_quit_menu_button.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
	_quit_desktop_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _create_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.pressed.connect(callback)
	
	# Create hover/focus styles
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	normal_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.35, 1.0)
	hover_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	pressed_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.25, 0.25, 0.3, 1.0)
	focus_style.border_color = Color(0.6, 0.5, 0.3, 1.0)
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("focus", focus_style)
	
	_vbox.add_child(button)
	return button

# =============================================================================
# MENU CONTROL
# =============================================================================

func show_menu() -> void:
	if is_open:
		return
	
	is_open = true
	_previous_pause_state = get_tree().paused
	_in_battle = GameManager.is_in_battle()
	
	# Update UI based on whether we're in battle
	_update_battle_state_ui()
	
	# Pause the game
	get_tree().paused = true
	GameManager.change_state(Enums.GameState.PAUSED)
	
	# Show and animate
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)
	
	# Focus resume button
	_resume_button.grab_focus()
	
	EventBus.game_paused.emit()
	EventBus.emit_debug("Pause menu opened (in_battle: %s)" % _in_battle)

func hide_menu() -> void:
	if not is_open:
		return
	
	is_open = false
	
	# Animate out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.1)
	tween.tween_property(_panel, "scale", Vector2(0.95, 0.95), 0.1)
	
	await tween.finished
	visible = false
	
	# Restore previous pause state and game state
	get_tree().paused = _previous_pause_state
	GameManager.return_to_previous_state()
	
	EventBus.game_resumed.emit()
	EventBus.emit_debug("Pause menu closed")
	menu_closed.emit()

func _update_battle_state_ui() -> void:
	if _in_battle:
		_battle_warning_label.visible = true
		_save_button.disabled = true
		_save_button.modulate.a = 0.5
		_quit_menu_button.text = "Quit to Menu (Lose Progress)"
	else:
		_battle_warning_label.visible = false
		_save_button.disabled = false
		_save_button.modulate.a = 1.0
		_quit_menu_button.text = "Quit to Menu"

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_resume_pressed() -> void:
	hide_menu()

func _on_settings_pressed() -> void:
	# TODO: Open settings submenu
	EventBus.emit_notification("Settings not yet implemented", "info")
	EventBus.emit_debug("Settings button pressed")

func _on_save_pressed() -> void:
	if _in_battle:
		EventBus.emit_notification("Cannot save during battle", "warning")
		return
	
	# Quick save to current slot, or slot 0 if no current slot
	var slot := SaveManager.current_slot
	if slot < 0:
		slot = 0
	
	SaveManager.save_game(slot)
	hide_menu()

func _on_report_bug_pressed() -> void:
	# Open GitHub issues page or feedback form
	var url := "https://github.com/sst/opencode/issues"  # Replace with actual bug report URL
	OS.shell_open(url)
	EventBus.emit_notification("Opening bug report page...", "info")

func _on_quit_menu_pressed() -> void:
	if _in_battle:
		# Save pre-battle state and quit
		_save_pre_battle_and_quit_to_menu()
	else:
		# Normal quit to menu
		_quit_to_menu()

func _on_quit_desktop_pressed() -> void:
	if _in_battle:
		# Save pre-battle state and quit
		_save_pre_battle_and_quit_to_desktop()
	else:
		# Normal quit - save if we have a slot
		if SaveManager.current_slot >= 0:
			SaveManager.save_game(SaveManager.current_slot)
		get_tree().quit()

func _save_pre_battle_and_quit_to_menu() -> void:
	# Restore pre-battle save state if available
	if GameManager.has_method("restore_pre_battle_state"):
		GameManager.restore_pre_battle_state()
	
	# Save to current slot with pre-battle state
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	
	_quit_to_menu()

func _save_pre_battle_and_quit_to_desktop() -> void:
	# Restore pre-battle save state if available
	if GameManager.has_method("restore_pre_battle_state"):
		GameManager.restore_pre_battle_state()
	
	# Save to current slot with pre-battle state
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	
	get_tree().quit()

func _quit_to_menu() -> void:
	is_open = false
	visible = false
	get_tree().paused = false
	
	# Use SceneManager to go to main menu
	SceneManager.go_to_main_menu()
	quit_to_menu_requested.emit()

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_game_state_changed(_old_state: int, new_state: int) -> void:
	# Auto-close pause menu if game state changes unexpectedly
	if is_open and new_state != Enums.GameState.PAUSED:
		is_open = false
		visible = false

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	# Disconnect EventBus signals to prevent errors after scene is freed
	if EventBus.game_state_changed.is_connected(_on_game_state_changed):
		EventBus.game_state_changed.disconnect(_on_game_state_changed)
