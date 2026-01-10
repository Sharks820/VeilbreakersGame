class_name CharacterSelectVERAPanel
extends PanelContainer
## VERA panel for character select screen.
## Uses VERADialoguePortrait for animated sprite sheet display.
## Provides contextual dialogue based on selected hero.

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_finished

# =============================================================================
# CONSTANTS
# =============================================================================

# Hero-specific dialogue
const HERO_DIALOGUES: Dictionary = {
	"bastion": "[color=#9999bb]Bastion walks the IRONBOUND path.[/color] A living fortress. Monsters of the IRON brand will find their defensive capabilities amplified under their command. The Veil's corruption breaks against such resolve.",
	"rend": "[color=#cc6666]Rend follows the FANGBORN path.[/color] Pure predatory instinct. SAVAGE brand monsters will hunt with terrifying efficiency alongside this one. Blood calls to blood.",
	"marrow": "[color=#9966aa]Marrow treads the VOIDTOUCHED path.[/color] They understand the exchange of life force. LEECH brand monsters will drain with greater potency, their stolen vitality flowing to heal allies.",
	"mirage": "[color=#66aacc]Mirage dances the UNCHAINED path.[/color] Reality bends around them. SURGE and DREAD brand monsters will find their speed and terror effects magnified. What is real becomes... negotiable."
}

const INITIAL_GREETING := "Welcome, Hunter. I am VERA - your Virtual Entity for Reconnaissance and Analysis. Choose your champion wisely. Each walks a different Path, and the monsters you capture will resonate with that choice."

# =============================================================================
# STATE
# =============================================================================

var vera_portrait: VERADialoguePortrait = null
var vera_dialogue: RichTextLabel = null
var vera_name_label: Label = null

var _dialogue_tween: Tween = null
var _current_hero_id: String = ""

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()
	# Show initial greeting after a short delay
	await get_tree().create_timer(0.3).timeout
	show_dialogue(INITIAL_GREETING)


func _build_ui() -> void:
	name = "VERAPanel"
	add_theme_stylebox_override("panel", UIStyleFactory.create_vera_panel_style())
	custom_minimum_size.y = 120

	var hbox := UIStyleFactory.create_hbox(25)
	add_child(hbox)

	# VERA portrait using VERADialoguePortrait
	_build_portrait(hbox)

	# Dialogue section
	_build_dialogue_section(hbox)


func _build_portrait(parent: Control) -> void:
	# Portrait frame (our own styling)
	var portrait_frame := UIStyleFactory.create_styled_panel(UIStyleFactory.create_vera_portrait_frame())
	portrait_frame.name = "PortraitFrame"
	portrait_frame.custom_minimum_size = Vector2(90, 90)
	parent.add_child(portrait_frame)

	# VERADialoguePortrait handles all animation
	vera_portrait = VERADialoguePortrait.new()
	vera_portrait.portrait_size = Vector2(84, 84)
	vera_portrait.auto_animate = true
	# Hide the built-in dialogue frame - we use our own panel styling
	portrait_frame.add_child(vera_portrait)

	# Wait for ready to hide the dialogue frame
	vera_portrait.ready.connect(func(): vera_portrait.show_dialogue_frame(false))


func _build_dialogue_section(parent: Control) -> void:
	var dialogue_vbox := UIStyleFactory.create_vbox(8)
	UIStyleFactory.expand_horizontal(dialogue_vbox)
	parent.add_child(dialogue_vbox)

	# VERA name with glowing effect
	vera_name_label = UIStyleFactory.create_label("V.E.R.A.", 16, Color(0.7, 0.5, 0.8))
	vera_name_label.name = "VERAName"
	vera_name_label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.4))
	vera_name_label.add_theme_constant_override("outline_size", 2)
	dialogue_vbox.add_child(vera_name_label)

	# Dialogue text
	vera_dialogue = RichTextLabel.new()
	vera_dialogue.bbcode_enabled = true
	vera_dialogue.fit_content = true
	UIStyleFactory.expand_horizontal(vera_dialogue)
	vera_dialogue.custom_minimum_size.y = 60
	vera_dialogue.add_theme_font_size_override("normal_font_size", 14)
	vera_dialogue.add_theme_color_override("default_color", Color(0.82, 0.78, 0.72))
	dialogue_vbox.add_child(vera_dialogue)


# =============================================================================
# PUBLIC API
# =============================================================================


func show_dialogue(text: String) -> void:
	if not vera_dialogue:
		return

	# Kill existing tween
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()

	# Start talking animation
	if vera_portrait:
		vera_portrait.start_talking()

	# Flash portrait when speaking
	_flash_portrait()

	# Typewriter effect
	vera_dialogue.text = text
	vera_dialogue.visible_characters = 0
	vera_dialogue.modulate.a = 0.0

	_dialogue_tween = create_tween()
	_dialogue_tween.set_parallel(false)

	# Fade in
	_dialogue_tween.tween_property(vera_dialogue, "modulate:a", 1.0, 0.2)

	# Type out text (faster for better UX)
	var type_duration: float = text.length() * 0.015
	_dialogue_tween.tween_property(vera_dialogue, "visible_characters", text.length(), type_duration)

	# Callback when done
	_dialogue_tween.tween_callback(_on_typing_complete)


func update_for_hero(hero_id: String) -> void:
	if hero_id == _current_hero_id:
		return  # Same hero, no change needed

	_current_hero_id = hero_id

	var dialogue: String = HERO_DIALOGUES.get(hero_id, "Choose wisely, Hunter.")
	show_dialogue(dialogue)

	# Play gesture for emphasis
	if vera_portrait:
		vera_portrait.play_gesture()


func get_current_hero_id() -> String:
	return _current_hero_id


# =============================================================================
# ANIMATIONS
# =============================================================================


func _flash_portrait() -> void:
	if not vera_portrait:
		return

	# Quick bright flash when speaking
	var tween := create_tween()
	tween.tween_property(vera_portrait, "modulate", Color(1.3, 1.1, 1.4), 0.15)
	tween.tween_property(vera_portrait, "modulate", Color.WHITE, 0.3)


func _on_typing_complete() -> void:
	# Stop talking animation
	if vera_portrait:
		vera_portrait.stop_talking()

	dialogue_finished.emit()


# =============================================================================
# CLEANUP
# =============================================================================


func _exit_tree() -> void:
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()
