extends Control
class_name VERAAnimatedDialogue
## VERAAnimatedDialogue: Complete animated VERA dialogue system.
## Combines animated sprite portrait with BC-style dialogue frame.
## Use this for tutorials, tips, and VERA conversations!

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_completed
signal typing_finished
signal choice_made(index: int)

# =============================================================================
# CONSTANTS
# =============================================================================

const TYPEWRITER_SPEED := 0.025  # Seconds per character
const GESTURE_KEYWORDS := ["look", "see", "here", "there", "this", "that", "point", "watch"]
const EMPHASIS_KEYWORDS := ["important", "careful", "warning", "danger", "remember", "listen"]

# =============================================================================
# EXPORTS
# =============================================================================

@export var portrait_size: Vector2 = Vector2(200, 200)
@export var dialogue_width: float = 550.0
@export var auto_gesture: bool = true

# =============================================================================
# STATE
# =============================================================================

var is_active: bool = false
var is_typing: bool = false
var current_text: String = ""
var displayed_text: String = ""
var char_index: int = 0
var type_timer: float = 0.0
var current_speaker: String = "VERA"

var current_dialogue_queue: Array = []
var current_queue_index: int = 0

# =============================================================================
# NODES (created dynamically)
# =============================================================================

var main_container: HBoxContainer
var portrait_container: Control
var vera_portrait: VERADialoguePortrait
var dialogue_container: Control
var dialogue_frame: Control
var speaker_label: Label
var text_label: RichTextLabel
var continue_indicator: Control
var choices_container: VBoxContainer

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


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if is_typing:
			_skip_typing()
		elif choices_container and choices_container.visible:
			pass  # Let choice buttons handle it
		else:
			_advance_dialogue()
		get_viewport().set_input_as_handled()


func _setup_ui() -> void:
	# Main container - fills parent
	anchors_preset = Control.PRESET_FULL_RECT

	# Semi-transparent background for focus
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Center container for dialogue panel
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	add_child(center)

	# Main horizontal layout (portrait + dialogue)
	main_container = HBoxContainer.new()
	main_container.add_theme_constant_override("separation", 16)
	center.add_child(main_container)

	# ===== Portrait Section =====
	portrait_container = Control.new()
	portrait_container.custom_minimum_size = portrait_size + Vector2(20, 20)
	main_container.add_child(portrait_container)

	# Animated VERA portrait
	vera_portrait = VERADialoguePortrait.new()
	vera_portrait.portrait_size = portrait_size
	vera_portrait.position = Vector2(10, 10)
	portrait_container.add_child(vera_portrait)

	# ===== Dialogue Section =====
	dialogue_container = Control.new()
	dialogue_container.custom_minimum_size = Vector2(dialogue_width, portrait_size.y + 40)
	main_container.add_child(dialogue_container)

	# BC-style dialogue frame
	dialogue_frame = _create_dialogue_frame()
	dialogue_container.add_child(dialogue_frame)

	# Text content container
	var text_container := VBoxContainer.new()
	text_container.anchors_preset = Control.PRESET_FULL_RECT
	text_container.offset_left = 24
	text_container.offset_top = 16
	text_container.offset_right = -24
	text_container.offset_bottom = -16
	text_container.add_theme_constant_override("separation", 8)
	dialogue_container.add_child(text_container)

	# Speaker name
	speaker_label = Label.new()
	speaker_label.text = "VERA"
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))
	text_container.add_child(speaker_label)

	# Dialogue text (RichTextLabel for BBCode support)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size", 18)
	text_label.add_theme_color_override("default_color", Color.WHITE)
	text_container.add_child(text_label)

	# Continue indicator
	continue_indicator = _create_continue_indicator()
	continue_indicator.position = Vector2(dialogue_width - 50, portrait_size.y + 10)
	continue_indicator.visible = false
	dialogue_container.add_child(continue_indicator)

	# Choices container (for branching dialogue)
	choices_container = VBoxContainer.new()
	choices_container.visible = false
	choices_container.add_theme_constant_override("separation", 8)
	text_container.add_child(choices_container)


func _create_dialogue_frame() -> Control:
	# Try to use BC dialogue frame from UIStyleFactory
	var frame := UIStyleFactory.create_bc_dialogue_frame(Vector2(dialogue_width, portrait_size.y + 40))

	# If texture not available, create styled fallback
	if not frame.texture:
		var fallback := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
		style.border_color = Color(0.4, 0.9, 0.9, 0.8)
		style.set_border_width_all(3)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(20)

		# Add subtle gradient/glow effect
		style.shadow_color = Color(0.4, 0.9, 0.9, 0.2)
		style.shadow_size = 8

		fallback.add_theme_stylebox_override("panel", style)
		fallback.custom_minimum_size = Vector2(dialogue_width, portrait_size.y + 40)
		return fallback

	return frame


func _create_continue_indicator() -> Control:
	var indicator := Control.new()
	indicator.custom_minimum_size = Vector2(24, 24)

	# Animated arrow
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(20, 10),
		Vector2(0, 20)
	])
	arrow.color = Color(0.4, 0.9, 0.9)
	indicator.add_child(arrow)

	# Bounce animation
	var tween := indicator.create_tween()
	tween.set_loops()
	tween.tween_property(arrow, "position:x", 6.0, 0.4).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(arrow, "position:x", 0.0, 0.4).set_ease(Tween.EASE_IN_OUT)

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

	# Check for gesture triggers
	if auto_gesture:
		_check_gesture_triggers()


func _check_gesture_triggers() -> void:
	if not _is_vera_speaker() or not vera_portrait:
		return

	var text_so_far := displayed_text.to_lower()
	if not text_so_far.ends_with(" "):
		return

	var words := text_so_far.split(" ")
	if words.size() < 2:
		return

	var recent_word := words[-2].strip_edges()

	if recent_word in GESTURE_KEYWORDS:
		vera_portrait.play_gesture()
	elif recent_word in EMPHASIS_KEYWORDS:
		vera_portrait.play_head_movement()


func _finish_typing() -> void:
	is_typing = false
	text_label.text = current_text
	continue_indicator.visible = true

	if vera_portrait:
		vera_portrait.stop_talking()

	typing_finished.emit()


func _skip_typing() -> void:
	is_typing = false
	char_index = current_text.length()
	text_label.text = current_text
	continue_indicator.visible = true

	if vera_portrait:
		vera_portrait.stop_talking()


# =============================================================================
# DIALOGUE FLOW
# =============================================================================


func _advance_dialogue() -> void:
	current_queue_index += 1

	if current_queue_index >= current_dialogue_queue.size():
		hide_dialogue()
		return

	_show_queue_item(current_queue_index)


func _show_queue_item(index: int) -> void:
	if index >= current_dialogue_queue.size():
		return

	var item: Dictionary = current_dialogue_queue[index]

	current_speaker = item.get("speaker", "VERA")
	current_text = item.get("text", "...")

	_update_speaker_display()
	_start_typing()

	# Handle choices if present
	if item.has("choices"):
		await typing_finished
		_show_choices(item["choices"])


func _start_typing() -> void:
	displayed_text = ""
	char_index = 0
	type_timer = 0.0
	is_typing = true
	continue_indicator.visible = false
	text_label.text = ""

	if vera_portrait and _is_vera_speaker():
		vera_portrait.start_talking()


func _update_speaker_display() -> void:
	speaker_label.text = current_speaker

	if _is_vera_speaker():
		match current_speaker:
			"VERA":
				speaker_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))
				if vera_portrait:
					vera_portrait.set_sprite_sheet("vera_c")
			"V̷E̸R̵A̶":
				speaker_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
				if vera_portrait:
					vera_portrait.set_sprite_sheet("vera_c")
			"VERATH", "V̷̢̛E̸̡R̵̨A̶̧T̷̢H̸̡":
				speaker_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.9))
				if vera_portrait:
					vera_portrait.set_sprite_sheet("vera_e")
		if vera_portrait:
			vera_portrait.visible = true
	else:
		speaker_label.add_theme_color_override("font_color", Color.WHITE)
		if vera_portrait:
			vera_portrait.visible = false


func _is_vera_speaker() -> bool:
	return current_speaker in ["VERA", "VERATH", "V̷E̸R̵A̶", "V̷̢̛E̸̡R̵̨A̶̧T̷̢H̸̡"]


# =============================================================================
# CHOICES
# =============================================================================


func _show_choices(choices: Array) -> void:
	continue_indicator.visible = false

	# Clear existing
	for child in choices_container.get_children():
		child.queue_free()

	# Create choice buttons
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button := UIStyleFactory.create_action_button(choice.get("text", "..."))
		button.pressed.connect(_on_choice_pressed.bind(i, choice.get("next", -1)))
		button.focus_mode = Control.FOCUS_ALL
		choices_container.add_child(button)

	choices_container.visible = true

	# Focus first choice
	await get_tree().process_frame
	if choices_container.get_child_count() > 0:
		choices_container.get_child(0).grab_focus()


func _on_choice_pressed(index: int, next_index: int) -> void:
	choices_container.visible = false
	choice_made.emit(index)
	EventBus.dialogue_choice_made.emit(index)

	if next_index >= 0:
		current_queue_index = next_index - 1  # -1 because _advance_dialogue increments
	_advance_dialogue()


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================


func show_dialogue(text: String, speaker: String = "VERA") -> void:
	## Show single dialogue line with typewriter effect
	show_dialogue_sequence([{"speaker": speaker, "text": text}])


func show_dialogue_sequence(dialogue_array: Array) -> void:
	## Show multiple dialogue lines in sequence
	current_dialogue_queue = dialogue_array
	current_queue_index = 0

	is_active = true
	visible = true

	_show_queue_item(0)


func hide_dialogue() -> void:
	## Hide dialogue and clean up
	is_active = false
	visible = false
	is_typing = false
	current_dialogue_queue = []
	current_queue_index = 0

	if vera_portrait:
		vera_portrait.stop_talking()

	dialogue_completed.emit()


func show_tutorial(title: String, message: String) -> void:
	## Show tutorial message with title formatting
	var formatted := "[b]%s[/b]\n\n%s" % [title, message]
	show_dialogue(formatted, "VERA")

	# Gesture after delay
	if vera_portrait:
		await get_tree().create_timer(0.5).timeout
		if is_active:
			vera_portrait.play_gesture()


func show_hint(text: String) -> void:
	## Quick hint from VERA
	show_dialogue("[color=#aaffff]Hint:[/color] %s" % text, "VERA")


func show_warning(text: String) -> void:
	## Warning message with emphasis
	show_dialogue("[color=#ffaa00]Warning:[/color] %s" % text, "VERA")

	if vera_portrait:
		await get_tree().create_timer(0.3).timeout
		if is_active:
			vera_portrait.play_head_movement()


func show_vera_context_dialogue(context: String) -> void:
	## Show VERA's context-appropriate dialogue from VERASystem
	var vera_text := "..."
	var vera_speaker := "VERA"

	if has_node("/root/VERASystem"):
		var vera_system = get_node("/root/VERASystem")
		vera_text = vera_system.get_dialogue(context)

		match vera_system.current_state:
			Enums.VERAState.INTERFACE:
				vera_speaker = "VERA"
			Enums.VERAState.FRACTURE:
				vera_speaker = "V̷E̸R̵A̶"
			Enums.VERAState.EMERGENCE, Enums.VERAState.APOTHEOSIS:
				vera_speaker = "V̷̢̛E̸̡R̵̨A̶̧T̷̢H̸̡"

	show_dialogue(vera_text, vera_speaker)


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================


func _on_vera_dialogue_triggered(context: String) -> void:
	show_vera_context_dialogue(context)


# =============================================================================
# CLEANUP
# =============================================================================


func _exit_tree() -> void:
	if EventBus.vera_dialogue_triggered.is_connected(_on_vera_dialogue_triggered):
		EventBus.vera_dialogue_triggered.disconnect(_on_vera_dialogue_triggered)
