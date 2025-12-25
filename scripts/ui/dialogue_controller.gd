extends Control
## DialogueController: Manages dialogue display, typewriter effect, and player choices.

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_finished()
signal choice_selected(index: int)
signal line_completed()

# =============================================================================
# NODES
# =============================================================================

@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var speaker_label: Label = $DialogueBox/VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $DialogueBox/VBox/TextLabel
@onready var portrait: TextureRect = $Portrait
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var continue_indicator: Control = $DialogueBox/ContinueIndicator

# =============================================================================
# STATE
# =============================================================================

var is_active: bool = false
var current_dialogue: Array = []
var current_index: int = 0
var is_typing: bool = false
var full_text: String = ""

var text_speed: float = 0.02
var _type_timer: float = 0.0
var _char_index: int = 0

# Portrait cache
var _portrait_cache: Dictionary = {}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	visible = false
	_hide_all_elements()

	# Get text speed from settings
	if has_node("/root/SettingsManager"):
		text_speed = Constants.DIALOGUE_CHAR_DELAY / SettingsManager.get_text_speed()

	# Connect to VERA dialogue triggers
	EventBus.vera_dialogue_triggered.connect(_on_vera_dialogue_triggered)

func _process(delta: float) -> void:
	if not is_typing:
		return

	_type_timer += delta
	if _type_timer >= text_speed:
		_type_timer = 0.0
		_char_index += 1

		if _char_index >= full_text.length():
			_finish_typing()
		else:
			text_label.text = full_text.substr(0, _char_index)

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if is_typing:
			_skip_typing()
		elif choices_container.visible:
			pass  # Let buttons handle it
		else:
			_advance_dialogue()

	if event.is_action_pressed("ui_cancel"):
		if choices_container.visible:
			pass  # Can't cancel choices
		else:
			# Quick skip option
			if is_typing:
				_skip_typing()

func _hide_all_elements() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	if choices_container:
		choices_container.visible = false
	if continue_indicator:
		continue_indicator.visible = false
	if portrait:
		portrait.visible = false

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func start_dialogue(dialogue_data: Array) -> void:
	"""
	dialogue_data format:
	[
		{"speaker": "VERA", "text": "Hello!", "portrait": "vera_happy"},
		{"speaker": "Player", "text": "Hi there.", "choices": [
			{"text": "Nice to meet you", "next": 2},
			{"text": "Whatever", "next": 3}
		]}
	]
	"""
	if dialogue_data.is_empty():
		push_warning("Empty dialogue data provided")
		return

	current_dialogue = dialogue_data
	current_index = 0
	is_active = true
	visible = true
	dialogue_box.visible = true

	GameManager.change_state(Enums.GameState.DIALOGUE)
	EventBus.dialogue_started.emit("custom")

	_show_current_line()

func start_simple_dialogue(speaker: String, text: String, portrait_id: String = "") -> void:
	"""Quick helper for single-line dialogues"""
	start_dialogue([{
		"speaker": speaker,
		"text": text,
		"portrait": portrait_id
	}])

func end_dialogue() -> void:
	is_active = false
	visible = false
	current_dialogue = []
	current_index = 0
	is_typing = false

	_hide_all_elements()

	GameManager.return_to_previous_state()
	EventBus.dialogue_ended.emit()
	dialogue_finished.emit()

# =============================================================================
# DIALOGUE FLOW
# =============================================================================

func _show_current_line() -> void:
	if current_index >= current_dialogue.size():
		end_dialogue()
		return

	var line: Dictionary = current_dialogue[current_index]

	# Set speaker
	speaker_label.text = line.get("speaker", "???")

	# Color speaker name based on who's speaking
	var speaker := line.get("speaker", "")
	if speaker == "VERA":
		speaker_label.add_theme_color_override("font_color", Color.CYAN)
	elif speaker == "Player" or speaker == "Veilbreaker":
		speaker_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		speaker_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)

	# Set portrait
	var portrait_id: String = line.get("portrait", "")
	_set_portrait(portrait_id)

	# Set text with typewriter effect
	full_text = line.get("text", "")
	text_label.text = ""
	_char_index = 0
	is_typing = true
	continue_indicator.visible = false

	EventBus.dialogue_line_shown.emit(line.get("speaker", ""), full_text)

func _advance_dialogue() -> void:
	var line: Dictionary = current_dialogue[current_index]

	if line.has("choices"):
		# Don't auto-advance if there are choices
		return

	if line.has("next"):
		current_index = line.next
	else:
		current_index += 1

	_show_current_line()

func _finish_typing() -> void:
	is_typing = false
	text_label.text = full_text

	var line: Dictionary = current_dialogue[current_index]

	if line.has("choices"):
		_show_choices(line.choices)
	else:
		continue_indicator.visible = true

	line_completed.emit()

func _skip_typing() -> void:
	is_typing = false
	text_label.text = full_text
	_finish_typing()

# =============================================================================
# PORTRAIT
# =============================================================================

func _set_portrait(portrait_id: String) -> void:
	if portrait_id.is_empty():
		portrait.visible = false
		return

	# Try to load portrait
	var portrait_path := "res://assets/portraits/%s.png" % portrait_id

	if _portrait_cache.has(portrait_id):
		portrait.texture = _portrait_cache[portrait_id]
		portrait.visible = true
	elif ResourceLoader.exists(portrait_path):
		var tex: Texture2D = load(portrait_path)
		_portrait_cache[portrait_id] = tex
		portrait.texture = tex
		portrait.visible = true
	else:
		portrait.visible = false
		EventBus.emit_debug("Portrait not found: %s" % portrait_id)

# =============================================================================
# CHOICES
# =============================================================================

func _show_choices(choices: Array) -> void:
	# Clear existing
	for child in choices_container.get_children():
		child.queue_free()

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = choice.get("text", "...")
		button.pressed.connect(_on_choice_selected.bind(i, choice.get("next", current_index + 1)))
		button.focus_mode = Control.FOCUS_ALL
		choices_container.add_child(button)

	choices_container.visible = true

	# Focus first choice
	await get_tree().process_frame
	if choices_container.get_child_count() > 0:
		choices_container.get_child(0).grab_focus()

func _on_choice_selected(index: int, next_index: int) -> void:
	choices_container.visible = false

	choice_selected.emit(index)
	EventBus.dialogue_choice_made.emit(index)

	current_index = next_index
	_show_current_line()

# =============================================================================
# VERA INTEGRATION
# =============================================================================

func _on_vera_dialogue_triggered(context: String) -> void:
	show_vera_dialogue(context)

func show_vera_dialogue(context: String) -> void:
	"""Quick helper to show VERA's context-appropriate dialogue"""
	var vera_text := "..."
	var vera_portrait := "vera_normal"

	if has_node("/root/VERASystem"):
		var vera_system = get_node("/root/VERASystem")
		vera_text = vera_system.get_dialogue(context)
		vera_portrait = vera_system.get_portrait_id()

	start_dialogue([{
		"speaker": "VERA",
		"text": vera_text,
		"portrait": vera_portrait
	}])

# =============================================================================
# UTILITY
# =============================================================================

func is_dialogue_active() -> bool:
	return is_active

func skip_to_end() -> void:
	"""Skip all remaining dialogue (for testing/accessibility)"""
	if is_active:
		end_dialogue()
