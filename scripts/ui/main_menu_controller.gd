extends Control
## MainMenuController: Handles main menu logic and navigation.

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/ContinueButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	GameManager.change_state(Enums.GameState.MAIN_MENU)

	# Update version label
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1.0")
	version_label.text = "v%s - Development Build" % version

	# Check if there are any saves for Continue button
	_update_continue_button()

	# Focus first button
	new_game_button.grab_focus()

	EventBus.emit_debug("Main menu ready")

func _update_continue_button() -> void:
	continue_button.disabled = not SaveManager.has_any_saves()
	if continue_button.disabled:
		continue_button.modulate.a = 0.5
	else:
		continue_button.modulate.a = 1.0

func _on_new_game_pressed() -> void:
	EventBus.emit_debug("New Game selected")
	GameManager.reset_for_new_game()

	# TODO: Show character creation or intro cutscene
	# For now, just go to overworld
	# SceneManager.change_scene_with_loading("res://scenes/overworld/overworld.tscn")

	EventBus.emit_notification("New Game - Not yet implemented", "info")

func _on_continue_pressed() -> void:
	EventBus.emit_debug("Continue selected")

	var slot := SaveManager.get_most_recent_slot()
	if slot >= 0:
		SaveManager.load_game(slot)
		# TODO: Transition to game scene after load
	else:
		EventBus.emit_notification("No save data found", "warning")

func _on_settings_pressed() -> void:
	EventBus.emit_debug("Settings selected")

	# TODO: Open settings menu
	EventBus.emit_notification("Settings - Not yet implemented", "info")

func _on_quit_pressed() -> void:
	EventBus.emit_debug("Quit selected")
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		# Toggle debug console (future implementation)
		pass
