class_name CharacterSelectConfirmationPopup
extends Control
## Confirmation popup for character selection.
## Shows hero name and asks for confirmation before starting the game.

# =============================================================================
# SIGNALS
# =============================================================================

signal confirmed(hero_id: String)
signal cancelled

# =============================================================================
# STATE
# =============================================================================

var _hero_id: String = ""
var _hero_name: String = ""
var _popup_panel: PanelContainer = null
var _entrance_tween: Tween = null

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Full-screen overlay
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	add_child(bg)

	# Popup panel - NO anchors (position calculated at runtime in show_popup)
	_popup_panel = UIStyleFactory.create_styled_panel(UIStyleFactory.create_confirmation_popup_style())
	_popup_panel.name = "PopupPanel"
	_popup_panel.custom_minimum_size = Vector2(500, 240)
	_popup_panel.size = Vector2(500, 240)
	_popup_panel.pivot_offset = Vector2(250, 120)  # Center pivot for animations
	# Don't use anchors - position will be set dynamically in show_popup()
	add_child(_popup_panel)

	var vbox := UIStyleFactory.create_vbox(20)
	vbox.name = "VBoxContainer"
	_popup_panel.add_child(vbox)

	# Title
	var title := UIStyleFactory.create_centered_label("CONFIRM SELECTION", 24, Color(0.9, 0.8, 0.6))
	title.name = "Title"
	vbox.add_child(title)

	# Message (will be updated when shown)
	var message := UIStyleFactory.create_centered_label("", 16, Color(0.8, 0.75, 0.7))
	message.name = "Message"
	vbox.add_child(message)

	# Button container
	var button_hbox := UIStyleFactory.create_hbox(30)
	button_hbox.name = "HBoxContainer"
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_hbox)

	# Cancel button
	var cancel_btn := _create_styled_button("CANCEL", Color(0.5, 0.35, 0.35), 140)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	button_hbox.add_child(cancel_btn)

	# Confirm button
	var confirm_btn := _create_styled_button("CONFIRM", Color(0.35, 0.5, 0.4), 140)
	confirm_btn.name = "ConfirmButton"
	confirm_btn.pressed.connect(_on_confirm_pressed)
	button_hbox.add_child(confirm_btn)

	# Start hidden
	visible = false


func _create_styled_button(text: String, color: Color, min_width: int = 150) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 55)
	UIStyleFactory.apply_color_button_style(button, color)

	# Connect hover animations
	button.mouse_entered.connect(func(): AnimationEffects.button_hover(button))
	button.mouse_exited.connect(func(): AnimationEffects.button_unhover(button))

	return button


# =============================================================================
# PUBLIC API
# =============================================================================


func show_popup(hero_name: String, hero_id: String) -> void:
	_hero_id = hero_id
	_hero_name = hero_name

	# Update message
	var message := _popup_panel.get_node("VBoxContainer/Message") as Label
	if message:
		message.text = "Are you sure you want to choose\n%s as your champion?" % hero_name

	# FORCE CENTER: Calculate position dynamically based on viewport
	var viewport_size := get_viewport_rect().size
	var panel_size := _popup_panel.size
	_popup_panel.position = (viewport_size - panel_size) / 2.0

	# Show and animate
	visible = true
	_animate_entrance()

	# Focus confirm button
	var confirm_btn := _popup_panel.get_node("VBoxContainer/HBoxContainer/ConfirmButton") as Button
	if confirm_btn:
		confirm_btn.grab_focus()


func hide_popup() -> void:
	_animate_exit()


# =============================================================================
# ANIMATIONS
# =============================================================================


func _animate_entrance() -> void:
	if _entrance_tween and _entrance_tween.is_valid():
		_entrance_tween.kill()

	# Start state
	_popup_panel.modulate.a = 0.0
	_popup_panel.scale = Vector2(0.8, 0.8)

	# Animate
	_entrance_tween = create_tween()
	_entrance_tween.set_parallel(true)
	_entrance_tween.tween_property(_popup_panel, "modulate:a", 1.0, 0.2)
	_entrance_tween.tween_property(_popup_panel, "scale", Vector2.ONE, 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _animate_exit() -> void:
	if _entrance_tween and _entrance_tween.is_valid():
		_entrance_tween.kill()

	_entrance_tween = create_tween()
	_entrance_tween.set_parallel(true)
	_entrance_tween.tween_property(_popup_panel, "modulate:a", 0.0, 0.15)
	_entrance_tween.tween_property(_popup_panel, "scale", Vector2(0.9, 0.9), 0.15)
	_entrance_tween.set_parallel(false)
	_entrance_tween.tween_callback(func(): visible = false)


# =============================================================================
# BUTTON HANDLERS
# =============================================================================


func _on_confirm_pressed() -> void:
	confirmed.emit(_hero_id)
	hide_popup()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide_popup()


# =============================================================================
# CLEANUP
# =============================================================================


func _exit_tree() -> void:
	if _entrance_tween and _entrance_tween.is_valid():
		_entrance_tween.kill()
