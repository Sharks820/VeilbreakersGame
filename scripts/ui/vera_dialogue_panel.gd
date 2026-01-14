extends Control
class_name VERADialoguePanel
## VERADialoguePanel: Complete dialogue UI for VERA featuring animated portrait
## and BC-styled speech bubble. The friendly guide who hides cosmic horror.

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_completed
signal typing_finished

# =============================================================================
# CONSTANTS
# =============================================================================

const TYPEWRITER_SPEED := 0.03  # Seconds per character
const GESTURE_KEYWORDS := ["look", "see", "here", "there", "this", "that", "point"]
const EMPHASIS_KEYWORDS := ["important", "careful", "warning", "danger", "remember"]

# =============================================================================
# EXPORTS
# =============================================================================

@export var portrait_size: Vector2 = Vector2(200, 200)
@export var dialogue_box_width: float = 500.0
@export var show_speaker_name: bool = true
@export var auto_gesture: bool = true  # Auto-trigger gestures on keywords

# =============================================================================
# STATE
# =============================================================================

var is_typing: bool = false
var current_text: String = ""
var displayed_text: String = ""
var char_index: int = 0
var type_timer: float = 0.0

# Nodes
var portrait: VERADialoguePortrait
var dialogue_frame: Control
var speaker_label: Label
var text_label: RichTextLabel
var continue_indicator: Control

# Tween tracking for cleanup
var _continue_indicator_tween: Tween = null

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	visible = false


func _process(delta: float) -> void:
	if not is_typing:
		return

	type_timer += delta
	if type_timer >= TYPEWRITER_SPEED:
		type_timer = 0.0
		_advance_character()


func _setup_ui() -> void:
	# Main horizontal container
	var main_container := HBoxContainer.new()
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.add_theme_constant_override("separation", 16)
	add_child(main_container)

	# Portrait container (left side)
	var portrait_container := Control.new()
	portrait_container.custom_minimum_size = portrait_size + Vector2(32, 32)
	main_container.add_child(portrait_container)

	# Create animated VERA portrait
	portrait = VERADialoguePortrait.new()
	portrait.portrait_size = portrait_size
	portrait.position = Vector2(16, 16)
	portrait_container.add_child(portrait)

	# Dialogue box container (right side)
	var dialogue_container := Control.new()
	dialogue_container.custom_minimum_size = Vector2(dialogue_box_width, portrait_size.y + 32)
	dialogue_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(dialogue_container)

	# BC-style dialogue frame background
	dialogue_frame = _create_dialogue_frame(dialogue_container.custom_minimum_size)
	dialogue_container.add_child(dialogue_frame)

	# Vertical layout for text content
	var text_vbox := VBoxContainer.new()
	text_vbox.anchors_preset = Control.PRESET_FULL_RECT
	text_vbox.offset_left = 20
	text_vbox.offset_top = 16
	text_vbox.offset_right = -20
	text_vbox.offset_bottom = -16
	text_vbox.add_theme_constant_override("separation", 8)
	dialogue_container.add_child(text_vbox)

	# Speaker name label
	speaker_label = Label.new()
	speaker_label.text = "VERA"
	speaker_label.add_theme_font_size_override("font_size", 20)
	speaker_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))  # Teal for VERA
	if show_speaker_name:
		text_vbox.add_child(speaker_label)

	# Dialogue text (RichTextLabel for formatting)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size", 16)
	text_label.add_theme_color_override("default_color", Color.WHITE)
	text_vbox.add_child(text_label)

	# Continue indicator (animated arrow/triangle)
	continue_indicator = _create_continue_indicator()
	continue_indicator.position = Vector2(dialogue_box_width - 40, portrait_size.y)
	continue_indicator.visible = false
	dialogue_container.add_child(continue_indicator)


func _create_dialogue_frame(size: Vector2) -> Control:
	# Use UIStyleFactory's BC dialogue frame
	var frame := UIStyleFactory.create_bc_dialogue_frame(size)

	# If frame texture doesn't exist, create fallback styled panel
	if not frame.texture:
		var fallback := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
		style.border_color = Color(0.4, 0.9, 0.9, 0.8)  # VERA teal
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(16)
		fallback.add_theme_stylebox_override("panel", style)
		fallback.custom_minimum_size = size
		return fallback

	return frame


func _create_continue_indicator() -> Control:
	var indicator := Control.new()
	indicator.custom_minimum_size = Vector2(20, 20)

	# Create animated triangle
	var triangle := Polygon2D.new()
	triangle.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(16, 8),
		Vector2(0, 16)
	])
	triangle.color = Color(0.4, 0.9, 0.9)  # VERA teal
	indicator.add_child(triangle)

	# Bounce animation - use class variable for proper cleanup
	_continue_indicator_tween = indicator.create_tween()
	_continue_indicator_tween.set_loops()
	_continue_indicator_tween.tween_property(triangle, "position:x", 5.0, 0.5)
	_continue_indicator_tween.tween_property(triangle, "position:x", 0.0, 0.5)

	return indicator


func _connect_signals() -> void:
	EventBus.vera_dialogue_triggered.connect(_on_vera_dialogue_triggered)


# =============================================================================
# TYPEWRITER EFFECT
# =============================================================================


func _advance_character() -> void:
	if char_index >= current_text.length():
		_finish_typing()
		return

	char_index += 1
	displayed_text = current_text.substr(0, char_index)
	text_label.text = displayed_text

	# Check for gesture keywords while typing
	if auto_gesture and char_index > 3:
		var recent_word := _get_recent_word()
		if recent_word in GESTURE_KEYWORDS:
			portrait.play_gesture()
		elif recent_word in EMPHASIS_KEYWORDS:
			portrait.play_head_movement()


func _get_recent_word() -> String:
	var text := displayed_text.to_lower()
	var words := text.split(" ")
	if words.size() > 0:
		return words[-1].strip_edges()
	return ""


func _finish_typing() -> void:
	is_typing = false
	text_label.text = current_text
	continue_indicator.visible = true
	portrait.stop_talking()
	typing_finished.emit()


func skip_typing() -> void:
	if is_typing:
		is_typing = false
		char_index = current_text.length()
		text_label.text = current_text
		continue_indicator.visible = true
		portrait.stop_talking()


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================


func show_dialogue(text: String, speaker: String = "VERA") -> void:
	## Display dialogue with typewriter effect and animated portrait
	visible = true
	current_text = text
	displayed_text = ""
	char_index = 0
	type_timer = 0.0
	is_typing = true
	continue_indicator.visible = false

	# Update speaker
	speaker_label.text = speaker
	_update_speaker_color(speaker)

	# Clear and start typing
	text_label.text = ""

	# Start portrait talking animation
	portrait.start_talking()


func show_dialogue_instant(text: String, speaker: String = "VERA") -> void:
	## Display dialogue instantly without typewriter effect
	visible = true
	current_text = text
	displayed_text = text
	text_label.text = text
	is_typing = false
	continue_indicator.visible = true

	speaker_label.text = speaker
	_update_speaker_color(speaker)


func hide_dialogue() -> void:
	visible = false
	is_typing = false
	portrait.stop_talking()


func complete_dialogue() -> void:
	hide_dialogue()
	dialogue_completed.emit()


func _update_speaker_color(speaker: String) -> void:
	match speaker:
		"VERA":
			speaker_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))  # Teal
			portrait.set_sprite_sheet("vera_c")
		"VERATH", "V̷̢̛E̸̡R̵̨A̶̧T̷̢H̸̡":
			speaker_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.9))  # Purple
			portrait.set_sprite_sheet("vera_e")
		_:
			speaker_label.add_theme_color_override("font_color", Color.WHITE)


# =============================================================================
# VERA-SPECIFIC DIALOGUE
# =============================================================================


func show_vera_dialogue(context: String) -> void:
	## Show VERA's context-appropriate dialogue with animation
	var vera_text := "..."
	var speaker := "VERA"

	if has_node("/root/VERASystem"):
		var vera_system = get_node("/root/VERASystem")
		vera_text = vera_system.get_dialogue(context)

		# Adjust speaker based on VERA's state
		match vera_system.current_state:
			Enums.VERAState.EMERGENCE:
				speaker = "V̷E̸R̵A̶"
			Enums.VERAState.APOTHEOSIS:
				speaker = "V̷̢̛E̸̡R̵̨A̶̧T̷̢H̸̡"

	show_dialogue(vera_text, speaker)


func trigger_glitch_dialogue(text: String, intensity: float = 0.5) -> void:
	## Show dialogue with glitch effects
	show_dialogue(text, "V̷E̸R̵A̶")
	EventBus.vera_glitch_triggered.emit(intensity, 0.5)


# =============================================================================
# TUTORIAL HELPERS
# =============================================================================


func show_tutorial_message(title: String, text: String) -> void:
	## Show a tutorial message from VERA with gesture
	show_dialogue("[b]%s[/b]\n\n%s" % [title, text], "VERA")
	await get_tree().create_timer(0.3).timeout
	portrait.play_gesture()


func show_hint(text: String) -> void:
	## Quick hint from VERA
	show_dialogue("[color=#aaffff]Hint:[/color] %s" % text, "VERA")


func show_warning(text: String) -> void:
	## Warning message from VERA with head movement
	show_dialogue("[color=#ffaa00]Warning:[/color] %s" % text, "VERA")
	portrait.play_head_movement()


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================


func _on_vera_dialogue_triggered(context: String) -> void:
	show_vera_dialogue(context)


# =============================================================================
# INPUT HANDLING
# =============================================================================


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if is_typing:
			skip_typing()
		else:
			complete_dialogue()
		get_viewport().set_input_as_handled()


# =============================================================================
# CLEANUP
# =============================================================================


func _exit_tree() -> void:
	# Kill infinite looping tween to prevent memory leak
	if _continue_indicator_tween and _continue_indicator_tween.is_valid():
		_continue_indicator_tween.kill()

	if EventBus.vera_dialogue_triggered.is_connected(_on_vera_dialogue_triggered):
		EventBus.vera_dialogue_triggered.disconnect(_on_vera_dialogue_triggered)
