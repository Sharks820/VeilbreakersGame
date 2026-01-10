class_name CharacterSelectButtonBar
extends HBoxContainer
## Button bar for character select screen.
## Contains Back and Begin Journey buttons with AAA-quality hover/press animations.

# =============================================================================
# SIGNALS
# =============================================================================

signal back_pressed
signal confirm_pressed

# =============================================================================
# STATE
# =============================================================================

var back_button: Button = null
var confirm_button: Button = null

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Container settings
	add_theme_constant_override("separation", 20)

	# Back button (left side)
	back_button = _create_action_button("BACK", Color(0.4, 0.35, 0.35), 150)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

	# Spacer (pushes confirm to right)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(spacer)

	# Confirm button (right side, larger)
	confirm_button = _create_action_button("BEGIN JOURNEY", Color(0.3, 0.5, 0.4), 220)
	confirm_button.pressed.connect(_on_confirm_pressed)
	add_child(confirm_button)


func _create_action_button(text: String, color: Color, min_width: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 55)

	# Apply base style
	UIStyleFactory.apply_color_button_style(button, color)

	# AAA hover animations
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_unhover.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))

	return button


# =============================================================================
# ANIMATIONS - AAA QUALITY
# =============================================================================


func _on_button_hover(button: Button) -> void:
	# Scale up + slight glow + subtle y offset
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Scale up with overshoot
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.15)

	# Warm glow
	tween.tween_property(button, "modulate", Color(1.15, 1.1, 1.05), 0.15)

	# Slight lift (negative y = up)
	tween.tween_property(button, "position:y", button.position.y - 4, 0.15)


func _on_button_unhover(button: Button) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Return to normal
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	tween.tween_property(button, "modulate", Color.WHITE, 0.12)
	tween.tween_property(button, "position:y", 0.0, 0.12)


func _on_button_down(button: Button) -> void:
	# Quick press down effect
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)


func _on_button_up(button: Button) -> void:
	# Bounce back with slight overshoot
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.1)


# =============================================================================
# PUBLIC API
# =============================================================================


func set_confirm_enabled(enabled: bool) -> void:
	if confirm_button:
		confirm_button.disabled = not enabled
		confirm_button.modulate.a = 1.0 if enabled else 0.5


func set_confirm_text(text: String) -> void:
	if confirm_button:
		confirm_button.text = text


func focus_confirm() -> void:
	if confirm_button:
		confirm_button.grab_focus()


func focus_back() -> void:
	if back_button:
		back_button.grab_focus()


# =============================================================================
# BUTTON HANDLERS
# =============================================================================


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_confirm_pressed() -> void:
	confirm_pressed.emit()
