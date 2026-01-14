class_name CharacterSelectVERAPanel
extends PanelContainer
## AAA VERA panel for character select screen.
## Features large animated portrait with full sprite sheet support.
## VERA is a major character - her presence should be PROMINENT.

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_finished

# =============================================================================
# CONSTANTS
# =============================================================================

# Portrait sizing - MUCH LARGER for prominence
const PORTRAIT_SIZE := Vector2(160, 160)  # Big enough to see expressions
const PANEL_MIN_HEIGHT := 180  # Taller panel for impact

# Hero-specific dialogue with more personality
const HERO_DIALOGUES: Dictionary = {
	"bastion": "[color=#9999bb]Bastion walks the IRONBOUND path.[/color] A living fortress. Monsters of the IRON brand will find their defensive capabilities amplified under their command. The Veil's corruption breaks against such resolve.",
	"rend": "[color=#cc6666]Rend follows the FANGBORN path.[/color] Pure predatory instinct. SAVAGE brand monsters will hunt with terrifying efficiency alongside this one. Blood calls to blood.",
	"marrow": "[color=#9966aa]Marrow treads the VOIDTOUCHED path.[/color] They understand the exchange of life force. LEECH brand monsters will drain with greater potency, their stolen vitality flowing to heal allies.",
	"mirage": "[color=#66aacc]Mirage dances the UNCHAINED path.[/color] Reality bends around them. SURGE and DREAD brand monsters will find their speed and terror effects magnified. What is real becomes... negotiable."
}

const INITIAL_GREETING := "Welcome, Hunter. I am [color=#aa88cc]V.E.R.A.[/color] - your Virtual Entity for Reconnaissance and Analysis. Choose your champion wisely. Each walks a different Path, and the monsters you capture will [color=#ffcc88]resonate[/color] with that choice."

# =============================================================================
# STATE
# =============================================================================

var vera_portrait: VERADialoguePortrait = null
var vera_dialogue: RichTextLabel = null
var vera_name_label: Label = null
var _portrait_glow: ColorRect = null

var _dialogue_tween: Tween = null
var _glow_tween: Tween = null
var _current_hero_id: String = ""

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()
	_start_portrait_glow()
	# Show initial greeting after a short delay
	await get_tree().create_timer(0.3).timeout
	show_dialogue(INITIAL_GREETING)


func _build_ui() -> void:
	name = "VERAPanel"
	add_theme_stylebox_override("panel", _create_enhanced_panel_style())
	custom_minimum_size.y = PANEL_MIN_HEIGHT

	var hbox := UIStyleFactory.create_hbox(20)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12
	hbox.offset_right = -12
	hbox.offset_top = 10
	hbox.offset_bottom = -10
	add_child(hbox)

	# VERA portrait using VERADialoguePortrait - LARGE and prominent
	_build_portrait(hbox)

	# Dialogue section
	_build_dialogue_section(hbox)


func _create_enhanced_panel_style() -> StyleBoxFlat:
	## Create an enhanced panel style for AAA look
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	style.border_color = Color(0.5, 0.35, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	# Inner glow effect via shadow
	style.shadow_color = Color(0.6, 0.4, 0.8, 0.3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 0)
	return style


func _build_portrait(parent: Control) -> void:
	# Portrait container with glow effect
	var portrait_container := Control.new()
	portrait_container.name = "PortraitContainer"
	portrait_container.custom_minimum_size = PORTRAIT_SIZE + Vector2(16, 16)
	parent.add_child(portrait_container)

	# Animated glow behind portrait
	_portrait_glow = ColorRect.new()
	_portrait_glow.name = "PortraitGlow"
	_portrait_glow.color = Color(0.6, 0.4, 0.8, 0.4)
	_portrait_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_glow.offset_left = -4
	_portrait_glow.offset_right = 4
	_portrait_glow.offset_top = -4
	_portrait_glow.offset_bottom = 4
	portrait_container.add_child(_portrait_glow)

	# Portrait frame with enhanced styling
	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.add_theme_stylebox_override("panel", _create_portrait_frame_style())
	portrait_frame.custom_minimum_size = PORTRAIT_SIZE + Vector2(8, 8)
	portrait_frame.set_anchors_preset(Control.PRESET_CENTER)
	portrait_frame.offset_left = -PORTRAIT_SIZE.x / 2 - 4
	portrait_frame.offset_right = PORTRAIT_SIZE.x / 2 + 4
	portrait_frame.offset_top = -PORTRAIT_SIZE.y / 2 - 4
	portrait_frame.offset_bottom = PORTRAIT_SIZE.y / 2 + 4
	portrait_container.add_child(portrait_frame)

	# VERADialoguePortrait handles all animation - LARGE size
	vera_portrait = VERADialoguePortrait.new()
	vera_portrait.portrait_size = PORTRAIT_SIZE
	vera_portrait.auto_animate = true
	portrait_frame.add_child(vera_portrait)

	# Hide built-in dialogue frame - we use custom styling
	vera_portrait.ready.connect(func(): vera_portrait.show_dialogue_frame(false))


func _create_portrait_frame_style() -> StyleBoxFlat:
	## Create portrait frame with inner border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.08, 1.0)
	style.border_color = Color(0.6, 0.45, 0.7, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


func _build_dialogue_section(parent: Control) -> void:
	var dialogue_vbox := UIStyleFactory.create_vbox(6)
	UIStyleFactory.expand_horizontal(dialogue_vbox)
	dialogue_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(dialogue_vbox)

	# VERA name with prominent glowing effect
	vera_name_label = Label.new()
	vera_name_label.name = "VERAName"
	vera_name_label.text = "V.E.R.A."
	vera_name_label.add_theme_font_size_override("font_size", 20)
	vera_name_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.95))
	vera_name_label.add_theme_color_override("font_outline_color", Color(0.4, 0.2, 0.5))
	vera_name_label.add_theme_constant_override("outline_size", 3)
	dialogue_vbox.add_child(vera_name_label)

	# Subtitle showing VERA's role
	var subtitle := Label.new()
	subtitle.text = "Virtual Entity for Reconnaissance & Analysis"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.45, 0.55))
	dialogue_vbox.add_child(subtitle)

	# Small spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	dialogue_vbox.add_child(spacer)

	# Dialogue text - larger and more readable
	vera_dialogue = RichTextLabel.new()
	vera_dialogue.name = "DialogueText"
	vera_dialogue.bbcode_enabled = true
	vera_dialogue.fit_content = false
	vera_dialogue.scroll_active = false
	UIStyleFactory.expand_horizontal(vera_dialogue)
	vera_dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vera_dialogue.add_theme_font_size_override("normal_font_size", 15)
	vera_dialogue.add_theme_font_size_override("bold_font_size", 16)
	vera_dialogue.add_theme_color_override("default_color", Color(0.85, 0.82, 0.78))
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


func _start_portrait_glow() -> void:
	## Start continuous pulsing glow behind portrait for AAA feel
	if not _portrait_glow:
		return

	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	_glow_tween = create_tween()
	_glow_tween.set_loops()  # Infinite loop

	# Pulse the glow alpha for mystical effect
	_glow_tween.tween_property(_portrait_glow, "color:a", 0.6, 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(_portrait_glow, "color:a", 0.3, 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
