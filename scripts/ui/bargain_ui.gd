# =============================================================================
# VEILBREAKERS - BARGAIN UI & VISUALS
# The mindscape presentation layer for The Bargain capture system
# Handles: Visual transition, choice presentation, dialogue display
# =============================================================================

class_name BargainUI
extends CanvasLayer

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal choice_selected(approach: int)  # BargainSystem.Approach enum value
signal skip_dialogue_requested

# -----------------------------------------------------------------------------
# NODE REFERENCES
# -----------------------------------------------------------------------------
@export_group("Backgrounds")
@export var mindscape_overlay: ColorRect  # Full screen color/shader overlay
@export var void_background: TextureRect  # Abstract void texture
@export var brand_particles: GPUParticles2D  # Brand-colored ambient particles

@export_group("Creature Display")
@export var creature_portrait: TextureRect  # Large creature image
@export var creature_silhouette: TextureRect  # Backlit silhouette effect
@export var creature_eyes: Control  # Glowing eyes overlay

@export_group("Dialogue")
@export var dialogue_container: Control
@export var dialogue_label: RichTextLabel
@export var speaker_label: Label
@export var dialogue_indicator: Control  # "Press to continue" indicator

@export_group("Choice Panel")
@export var choice_container: Control
@export var dominate_button: Button
@export var promise_button: Button
@export var break_button: Button
@export var choice_description: RichTextLabel

@export_group("Audio")
@export var mindscape_ambience: AudioStreamPlayer
@export var dialogue_blip: AudioStreamPlayer
@export var choice_hover_sound: AudioStreamPlayer
@export var choice_select_sound: AudioStreamPlayer

# -----------------------------------------------------------------------------
# BRAND VISUALS
# -----------------------------------------------------------------------------
const BRAND_MINDSCAPE_COLORS = {
	"SAVAGE": {
		"primary": Color("c73e3e"),
		"void": Color("1a0505"),
		"particle": Color("ff6b6b"),
		"eye_glow": Color("ff0000"),
	},
	"IRON": {
		"primary": Color("7b8794"),
		"void": Color("0a0c0f"),
		"particle": Color("a8b5c4"),
		"eye_glow": Color("ffffff"),
	},
	"VENOM": {
		"primary": Color("6b9b37"),
		"void": Color("0a1205"),
		"particle": Color("9acd32"),
		"eye_glow": Color("00ff00"),
	},
	"SURGE": {
		"primary": Color("4a90d9"),
		"void": Color("050a12"),
		"particle": Color("87ceeb"),
		"eye_glow": Color("00ffff"),
	},
	"DREAD": {
		"primary": Color("5d3e8c"),
		"void": Color("0a0510"),
		"particle": Color("9370db"),
		"eye_glow": Color("ff00ff"),
	},
	"LEECH": {
		"primary": Color("c75b8a"),
		"void": Color("12050a"),
		"particle": Color("ff91af"),
		"eye_glow": Color("ff69b4"),
	},
}

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
var current_brand: String = "SAVAGE"
var is_showing_dialogue: bool = false
var is_showing_choices: bool = false
var current_approaches: Dictionary = {}
var dialogue_queue: Array = []
var current_dialogue_index: int = 0

# Typewriter effect
var full_dialogue_text: String = ""
var displayed_chars: int = 0
var chars_per_second: float = 40.0
var typewriter_timer: float = 0.0

# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------
func _ready() -> void:
	visible = false
	_connect_buttons()

func _process(delta: float) -> void:
	if is_showing_dialogue:
		_process_typewriter(delta)

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if is_showing_dialogue and event.is_action_pressed("ui_accept"):
		if displayed_chars < full_dialogue_text.length():
			# Show all text immediately
			displayed_chars = full_dialogue_text.length()
			dialogue_label.text = full_dialogue_text
		else:
			# Advance to next dialogue or show choices
			skip_dialogue_requested.emit()

func _connect_buttons() -> void:
	if dominate_button:
		dominate_button.pressed.connect(_on_dominate_pressed)
		dominate_button.mouse_entered.connect(_on_choice_hovered.bind(0))
	if promise_button:
		promise_button.pressed.connect(_on_promise_pressed)
		promise_button.mouse_entered.connect(_on_choice_hovered.bind(1))
	if break_button:
		break_button.pressed.connect(_on_break_pressed)
		break_button.mouse_entered.connect(_on_choice_hovered.bind(2))

# -----------------------------------------------------------------------------
# PUBLIC API - Called by BargainSystem
# -----------------------------------------------------------------------------
func enter_mindscape(creature: Node, brand: String) -> void:
	"""Begin the mindscape visual transition"""
	current_brand = brand
	var colors = BRAND_MINDSCAPE_COLORS.get(brand, BRAND_MINDSCAPE_COLORS.SAVAGE)

	visible = true
	choice_container.visible = false
	dialogue_container.visible = false

	# Configure colors
	if mindscape_overlay:
		var void_color: Color = colors.void
		mindscape_overlay.color = Color(void_color.r, void_color.g, void_color.b, 0.0)

	if void_background:
		void_background.modulate = colors.void

	if brand_particles and brand_particles.process_material:
		brand_particles.process_material.color = colors.particle

	if creature_eyes:
		creature_eyes.modulate = colors.eye_glow

	# Set creature portrait
	if creature_portrait and creature.has_method("get_portrait"):
		creature_portrait.texture = creature.get_portrait()

	# Animate transition
	await _animate_enter(colors)

	# Start ambience
	if mindscape_ambience:
		mindscape_ambience.play()

func exit_mindscape() -> void:
	"""Exit the mindscape"""
	choice_container.visible = false
	dialogue_container.visible = false

	await _animate_exit()

	if mindscape_ambience:
		mindscape_ambience.stop()

	visible = false

func show_dialogue(speaker: String, text: String, response_type: String = "") -> void:
	"""Display dialogue with typewriter effect"""
	dialogue_container.visible = true
	choice_container.visible = false
	is_showing_dialogue = true

	# Configure speaker
	if speaker_label:
		match response_type:
			"PLAYER_DOMINATE", "PLAYER_PROMISE", "PLAYER_BREAK":
				speaker_label.text = "YOU"
				speaker_label.add_theme_color_override("font_color", Color.WHITE)
			"CREATURE_RESIST", "CREATURE_RAGE", "CREATURE_REJECT":
				speaker_label.text = "???"
				speaker_label.add_theme_color_override("font_color", Color.RED)
			"CREATURE_WAVER", "CREATURE_CONSIDER", "CREATURE_VULNERABLE":
				speaker_label.text = "???"
				speaker_label.add_theme_color_override("font_color", Color.YELLOW)
			"CREATURE_ACCEPT", "CREATURE_SUBMIT", "CREATURE_YIELD":
				speaker_label.text = "???"
				speaker_label.add_theme_color_override("font_color", Color.GREEN)
			_:
				speaker_label.text = speaker

	# Style text based on response type
	full_dialogue_text = _style_dialogue(text, response_type)
	displayed_chars = 0
	dialogue_label.text = ""

	if dialogue_indicator:
		dialogue_indicator.visible = false

func show_choices(approaches: Dictionary) -> void:
	"""Show the three approach choices"""
	current_approaches = approaches
	dialogue_container.visible = false
	choice_container.visible = true
	is_showing_dialogue = false
	is_showing_choices = true

	# Configure DOMINATE button
	if dominate_button:
		dominate_button.disabled = false
		var dom_data = approaches.get("DOMINATE", {})
		_style_choice_button(dominate_button, "DOMINATE", dom_data.get("chance", 0.0))

	# Configure PROMISE button
	if promise_button:
		promise_button.disabled = false
		var prom_data = approaches.get("PROMISE", {})
		_style_choice_button(promise_button, "PROMISE", prom_data.get("chance", 0.0))

	# Configure BREAK button
	if break_button:
		var break_data = approaches.get("BREAK", {})
		break_button.disabled = not break_data.get("available", false)
		_style_choice_button(break_button, "BREAK", break_data.get("chance", 0.0))
		if not break_data.get("available", false):
			break_button.text = "BREAK\n[No Weakness]"

	# Initial description
	if choice_description:
		choice_description.text = "[center]Choose your approach to bind this creature.[/center]"

func hide_choices() -> void:
	"""Hide the choice panel"""
	choice_container.visible = false
	is_showing_choices = false

# -----------------------------------------------------------------------------
# TYPEWRITER EFFECT
# -----------------------------------------------------------------------------
func _process_typewriter(delta: float) -> void:
	if displayed_chars >= full_dialogue_text.length():
		if dialogue_indicator:
			dialogue_indicator.visible = true
		return

	typewriter_timer += delta
	var chars_to_add = int(typewriter_timer * chars_per_second)

	if chars_to_add > 0:
		typewriter_timer = 0.0
		displayed_chars = min(displayed_chars + chars_to_add, full_dialogue_text.length())
		dialogue_label.text = full_dialogue_text.substr(0, displayed_chars)

		# Play blip sound
		if dialogue_blip and displayed_chars % 3 == 0:
			dialogue_blip.pitch_scale = randf_range(0.9, 1.1)
			dialogue_blip.play()

func _style_dialogue(text: String, response_type: String) -> String:
	"""Add BBCode styling based on response type"""
	match response_type:
		"PLAYER_DOMINATE":
			return "[color=#ff4444][b]" + text + "[/b][/color]"
		"PLAYER_PROMISE":
			return "[color=#44ff44][b]" + text + "[/b][/color]"
		"PLAYER_BREAK":
			return "[color=#ffff44][b]" + text + "[/b][/color]"
		"CREATURE_RAGE":
			return "[shake rate=20 level=10][color=#ff0000]" + text + "[/color][/shake]"
		"CREATURE_VULNERABLE":
			return "[wave amp=20 freq=5][color=#888888][i]" + text + "[/i][/color][/wave]"
		"CREATURE_ACCEPT":
			return "[color=#00ff00]" + text + "[/color]"
		_:
			return text

# -----------------------------------------------------------------------------
# CHOICE HANDLING
# -----------------------------------------------------------------------------
func _style_choice_button(button: Button, approach: String, chance: float) -> void:
	"""Style a choice button based on success chance"""
	var chance_text = ""
	var chance_color = Color.WHITE

	if chance >= 0.7:
		chance_text = "HIGH"
		chance_color = Color.GREEN
	elif chance >= 0.4:
		chance_text = "MEDIUM"
		chance_color = Color.YELLOW
	else:
		chance_text = "LOW"
		chance_color = Color.RED

	button.text = approach + "\n[" + chance_text + "]"
	# Would apply color through theme or stylebox

func _on_choice_hovered(choice_index: int) -> void:
	"""Show description for hovered choice"""
	if choice_hover_sound:
		choice_hover_sound.play()

	if not choice_description:
		return

	match choice_index:
		0:  # DOMINATE
			var data = current_approaches.get("DOMINATE", {})
			var desc = "[color=#ff4444][b]DOMINATE[/b][/color]\n"
			desc += "Force the creature to submit through sheer will.\n\n"
			desc += "[i]" + data.get("description", "") + "[/i]\n"
			if data.get("warning", "") != "":
				desc += "\n[color=#ffff00]Warning: " + data.warning + "[/color]"
			choice_description.text = desc

		1:  # PROMISE
			var data = current_approaches.get("PROMISE", {})
			var desc = "[color=#44ff44][b]PROMISE[/b][/color]\n"
			desc += "Offer a vow that resonates with the creature's nature.\n\n"
			desc += "[i]\"" + data.get("vow", "") + "\"[/i]\n"
			desc += "\n" + data.get("description", "")
			if data.get("warning", "") != "":
				desc += "\n[color=#ffff00]Warning: " + data.warning + "[/color]"
			choice_description.text = desc

		2:  # BREAK
			var data = current_approaches.get("BREAK", {})
			var desc = "[color=#ffff44][b]BREAK[/b][/color]\n"
			desc += "Exploit the creature's current weakness or desperation.\n\n"
			if data.get("available", false):
				desc += "[i]" + data.get("description", "") + "[/i]\n"
				var exploits = data.get("exploits", [])
				if exploits.size() > 0:
					desc += "\nVulnerabilities:\n"
					for exploit in exploits:
						desc += "- " + exploit.type.capitalize() + "\n"
			else:
				desc += "[color=#888888]This creature has no exploitable weakness.[/color]"
			choice_description.text = desc

func _on_dominate_pressed() -> void:
	if choice_select_sound:
		choice_select_sound.play()
	choice_selected.emit(0)  # BargainSystem.Approach.DOMINATE

func _on_promise_pressed() -> void:
	if choice_select_sound:
		choice_select_sound.play()
	choice_selected.emit(1)  # BargainSystem.Approach.PROMISE

func _on_break_pressed() -> void:
	if choice_select_sound:
		choice_select_sound.play()
	choice_selected.emit(2)  # BargainSystem.Approach.BREAK

# -----------------------------------------------------------------------------
# ANIMATIONS
# -----------------------------------------------------------------------------
func _animate_enter(colors: Dictionary) -> void:
	"""Animate entering the mindscape"""
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in overlay
	if mindscape_overlay:
		mindscape_overlay.color.a = 0.0
		tween.tween_property(mindscape_overlay, "color:a", 0.95, 0.8)

	# Void background fades in
	if void_background:
		void_background.modulate.a = 0.0
		tween.tween_property(void_background, "modulate:a", 1.0, 1.0)

	# Creature portrait scales in dramatically
	if creature_portrait:
		creature_portrait.scale = Vector2(0.5, 0.5)
		creature_portrait.modulate.a = 0.0
		tween.tween_property(creature_portrait, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(creature_portrait, "modulate:a", 1.0, 0.4)

	# Eyes glow in after portrait
	if creature_eyes:
		creature_eyes.modulate.a = 0.0
		tween.tween_property(creature_eyes, "modulate:a", 1.0, 0.3).set_delay(0.5)

	# Start particles
	if brand_particles:
		brand_particles.emitting = true

	await tween.finished

func _animate_exit() -> void:
	"""Animate exiting the mindscape"""
	var tween = create_tween()
	tween.set_parallel(true)

	if mindscape_overlay:
		tween.tween_property(mindscape_overlay, "color:a", 0.0, 0.5)

	if void_background:
		tween.tween_property(void_background, "modulate:a", 0.0, 0.5)

	if creature_portrait:
		tween.tween_property(creature_portrait, "modulate:a", 0.0, 0.3)

	if creature_eyes:
		tween.tween_property(creature_eyes, "modulate:a", 0.0, 0.2)

	if brand_particles:
		brand_particles.emitting = false

	await tween.finished

# -----------------------------------------------------------------------------
# SUCCESS/FAILURE ANIMATIONS
# -----------------------------------------------------------------------------
func animate_success(approach: int) -> void:
	"""Play success visual feedback"""
	var tween = create_tween()

	# Flash based on approach
	var flash_color = Color.WHITE
	match approach:
		0: flash_color = Color.RED     # Dominate
		1: flash_color = Color.GREEN   # Promise
		2: flash_color = Color.YELLOW  # Break

	if mindscape_overlay:
		var original_color = mindscape_overlay.color
		tween.tween_property(mindscape_overlay, "color", flash_color, 0.1)
		tween.tween_property(mindscape_overlay, "color", original_color, 0.3)

	# Creature portrait reaction
	if creature_portrait:
		tween.parallel().tween_property(creature_portrait, "modulate", flash_color, 0.1)
		tween.tween_property(creature_portrait, "modulate", Color.WHITE, 0.3)

func animate_failure(is_rage: bool) -> void:
	"""Play failure visual feedback"""
	var tween = create_tween()

	# Screen shake via viewport
	# Would emit signal for camera to handle

	# Creature becomes threatening
	if creature_portrait:
		if is_rage:
			# Aggressive shake
			var original_pos = creature_portrait.position
			for i in range(10):
				tween.tween_property(creature_portrait, "position", original_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10)), 0.03)
			tween.tween_property(creature_portrait, "position", original_pos, 0.1)

			# Scale up menacingly
			tween.parallel().tween_property(creature_portrait, "scale", Vector2(1.2, 1.2), 0.2)
			tween.tween_property(creature_portrait, "scale", Vector2.ONE, 0.3)
		else:
			# Just a rejection - creature turns away or fades slightly
			tween.tween_property(creature_portrait, "modulate:a", 0.5, 0.2)
			tween.tween_property(creature_portrait, "modulate:a", 1.0, 0.3)

	# Red flash for rage
	if is_rage and mindscape_overlay:
		var original_color = mindscape_overlay.color
		tween.parallel().tween_property(mindscape_overlay, "color", Color.RED, 0.1)
		tween.tween_property(mindscape_overlay, "color", original_color, 0.2)
