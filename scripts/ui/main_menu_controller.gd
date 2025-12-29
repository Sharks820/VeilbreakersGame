extends Control
## MainMenuController: Handles main menu logic and navigation with styled buttons.

@onready var new_game_button: TextureButton = $ButtonContainer/NewGameButton
@onready var continue_button: TextureButton = $ButtonContainer/ContinueButton
@onready var settings_button: TextureButton = $ButtonContainer/SettingsButton
@onready var quit_button: TextureButton = $ButtonContainer/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	GameManager.change_state(Enums.GameState.MAIN_MENU)

	# Update version label
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1.0")
	version_label.text = "v%s - Development Build" % version

	# Check if there are any saves for Continue button
	_update_continue_button()

	# Setup button hover effects
	_setup_button_effects()

	# Focus first button
	new_game_button.grab_focus()

	EventBus.emit_debug("Main menu ready")

func _setup_button_effects() -> void:
	# Connect hover signals for all buttons
	for button in [new_game_button, continue_button, settings_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.focus_entered.connect(_on_button_hover.bind(button))
		button.focus_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: TextureButton) -> void:
	if button.disabled:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.3, 1.1, 1.1, 1.0), 0.15)

func _on_button_unhover(button: TextureButton) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _update_continue_button() -> void:
	continue_button.disabled = not SaveManager.has_any_saves()
	if continue_button.disabled:
		continue_button.modulate.a = 0.5
	else:
		continue_button.modulate.a = 1.0

func _on_new_game_pressed() -> void:
	EventBus.emit_debug("New Game selected")
	_play_button_press(new_game_button)
	GameManager.reset_for_new_game()

	# TODO: Show character creation or intro cutscene
	# For now, just go to test battle
	await get_tree().create_timer(0.2).timeout
	SceneManager.change_scene("res://scenes/test/test_battle.tscn")

func _on_continue_pressed() -> void:
	EventBus.emit_debug("Continue selected")
	_play_button_press(continue_button)

	var slot := SaveManager.get_most_recent_slot()
	if slot >= 0:
		SaveManager.load_game(slot)
		# TODO: Transition to game scene after load
	else:
		EventBus.emit_notification("No save data found", "warning")

func _on_settings_pressed() -> void:
	EventBus.emit_debug("Settings selected")
	_play_button_press(settings_button)

	# TODO: Open settings menu
	EventBus.emit_notification("Settings - Not yet implemented", "info")

func _on_quit_pressed() -> void:
	EventBus.emit_debug("Quit selected")
	_play_button_press(quit_button)
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _play_button_press(button: TextureButton) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.08)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		# Toggle debug console (future implementation)
		pass
