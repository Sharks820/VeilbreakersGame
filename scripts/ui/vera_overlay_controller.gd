extends CanvasLayer
## VERAOverlayController: Displays VERA status and glitch effects.
## The horror hides beneath the helpful UI.

# =============================================================================
# NODES
# =============================================================================

@onready var container: Control = $Container
@onready var portrait: TextureRect = $Container/Portrait
@onready var state_label: Label = $Container/StateLabel
@onready var corruption_bar: ProgressBar = $Container/CorruptionBar
@onready var corruption_label: Label = $Container/CorruptionLabel
@onready var glitch_overlay: ColorRect = $GlitchOverlay
@onready var ability_container: HBoxContainer = $Container/AbilityContainer

# =============================================================================
# STATE
# =============================================================================

var _glitch_timer: float = 0.0
var _glitch_active: bool = false
var _current_glitch_duration: float = 0.0
var _pulse_tween: Tween = null

# Portrait textures cache
var _portraits: Dictionary = {}

# Horror colors for glitch frames
var horror_colors: Array[Color] = [
	Color(0.8, 0, 0, 0.3),      # Blood red
	Color(0.5, 0, 0.5, 0.4),    # Void purple
	Color(0, 0, 0, 0.8),        # Darkness
	Color(1, 0, 0.5, 0.3),      # Sickly magenta
	Color(0.2, 0, 0.2, 0.5)     # Deep void
]

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_update_display()
	glitch_overlay.visible = false

	# Start with overlay hidden if not in gameplay
	if GameManager.current_state == Enums.GameState.MAIN_MENU:
		container.visible = false

func _process(delta: float) -> void:
	if _glitch_active:
		_process_glitch(delta)

func _connect_signals() -> void:
	EventBus.vera_state_changed.connect(_on_state_changed)
	EventBus.vera_corruption_changed.connect(_on_corruption_changed)
	EventBus.vera_glitch_triggered.connect(_on_glitch_triggered)
	EventBus.game_state_changed.connect(_on_game_state_changed)

# =============================================================================
# DISPLAY UPDATE
# =============================================================================

func _update_display() -> void:
	if not has_node("/root/VERASystem"):
		return

	var vera = get_node("/root/VERASystem")

	# Update state label with new names (including corrupted text)
	var state_names := {
		Enums.VERAState.INTERFACE: "VERA",
		Enums.VERAState.FRACTURE: "V̷E̸R̵A̶",
		Enums.VERAState.EMERGENCE: "V̷̢̛E̸̡R̵̨A̶̧T̷̢H̸̡",
		Enums.VERAState.APOTHEOSIS: "V̷̢̛̖̗E̸̡̘̙R̵̨̚̕A̶̧̛̜T̷̢̝̞H̸̡̟̠"
	}
	state_label.text = state_names.get(vera.current_state, "VERA")

	# Update corruption bar (player sees it as "System Status")
	corruption_bar.value = vera.corruption_level

	# Hide true meaning from player initially
	if vera.current_state == Enums.VERAState.INTERFACE:
		corruption_label.text = "System Status: Optimal"
	elif vera.current_state == Enums.VERAState.FRACTURE:
		corruption_label.text = "System Status: Unstable"
	elif vera.current_state == Enums.VERAState.EMERGENCE:
		corruption_label.text = "System Status: C̷̨̛R̵̢̛I̸̡̛T̷̢̛Į̵̛C̸̡̛A̷̢̛L̵̨̛"
	else:
		corruption_label.text = "SHE REMEMBERS"

	# Update portrait
	_update_portrait(vera.current_state)

	# Color based on state
	_update_state_colors(vera.current_state)

	# Update available abilities
	_update_abilities(vera)

func _update_portrait(state: Enums.VERAState) -> void:
	var portrait_ids := {
		Enums.VERAState.INTERFACE: "vera_normal",
		Enums.VERAState.FRACTURE: "vera_glitch",
		Enums.VERAState.EMERGENCE: "vera_dark",
		Enums.VERAState.APOTHEOSIS: "vera_monster"
	}

	var portrait_id: String = portrait_ids.get(state, "vera_normal")
	var path := "res://assets/portraits/%s.png" % portrait_id

	if _portraits.has(portrait_id):
		portrait.texture = _portraits[portrait_id]
	elif ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_portraits[portrait_id] = tex
		portrait.texture = tex

func _update_state_colors(state: Enums.VERAState) -> void:
	match state:
		Enums.VERAState.INTERFACE:
			state_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))  # Friendly teal
			corruption_bar.modulate = Color.CYAN
		Enums.VERAState.FRACTURE:
			state_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))  # Warning gold
			corruption_bar.modulate = Color(1.0, 0.8, 0.0)
		Enums.VERAState.EMERGENCE:
			state_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.9))  # Ominous purple
			corruption_bar.modulate = Color(0.6, 0.1, 0.8)
		Enums.VERAState.APOTHEOSIS:
			state_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))  # Blood red
			corruption_bar.modulate = Color(0.8, 0, 0)

func _update_abilities(vera) -> void:
	if not ability_container:
		return

	# Clear existing
	for child in ability_container.get_children():
		child.queue_free()

	# Add ability icons
	var abilities: Array[String] = vera.get_available_abilities()
	for ability in abilities:
		var button := Button.new()
		button.text = ability.capitalize().substr(0, 4)
		button.tooltip_text = ability
		button.custom_minimum_size = Vector2(40, 30)
		button.pressed.connect(_on_ability_pressed.bind(ability))
		ability_container.add_child(button)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_state_changed(_old: int, _new: int) -> void:
	_update_display()

	# Dramatic flash on state change
	if _pulse_tween:
		_pulse_tween.kill()

	_pulse_tween = create_tween()
	_pulse_tween.tween_property(container, "modulate", Color(3, 3, 3), 0.1)
	_pulse_tween.tween_property(container, "modulate", Color.WHITE, 0.4)

	# Play sound effect
	EventBus.sfx_play_requested.emit("vera_state_change", Vector2.ZERO)

func _on_corruption_changed(new_value: float, _source: String) -> void:
	# Animate corruption bar
	var tween := create_tween()
	tween.tween_property(corruption_bar, "value", new_value, 0.3)

	_update_display()

	# Flash red when corruption increases significantly
	if new_value > corruption_bar.value + 5:
		var flash := create_tween()
		flash.tween_property(corruption_bar, "modulate", Color.RED, 0.1)
		flash.tween_property(corruption_bar, "modulate", Color.WHITE, 0.2)

func _on_glitch_triggered(intensity: float, duration: float = 0.3) -> void:
	if intensity <= 0:
		_glitch_active = false
		glitch_overlay.visible = false
		return

	_glitch_active = true
	_current_glitch_duration = duration
	_glitch_timer = 0.0
	glitch_overlay.visible = true

func _on_game_state_changed(_old: Enums.GameState, new: Enums.GameState) -> void:
	# Show overlay during gameplay, hide in menus
	match new:
		Enums.GameState.MAIN_MENU, Enums.GameState.LOADING:
			hide_overlay()
		Enums.GameState.OVERWORLD, Enums.GameState.BATTLE:
			show_overlay()

func _on_ability_pressed(ability: String) -> void:
	if has_node("/root/VERASystem"):
		var result: Dictionary = get_node("/root/VERASystem").use_ability(ability)
		if result.success:
			EventBus.emit_notification(result.data.get("message", ""), "info")
		else:
			EventBus.emit_notification(result.get("reason", "Ability failed"), "warning")

# =============================================================================
# GLITCH EFFECTS
# =============================================================================

func _process_glitch(delta: float) -> void:
	_glitch_timer += delta

	if _glitch_timer >= _current_glitch_duration:
		_glitch_active = false
		glitch_overlay.visible = false
		glitch_overlay.color.a = 0
		container.position = Vector2.ZERO
		return

	# Rapid horror flashes
	if randf() < 0.3:
		var horror_color: Color = horror_colors[randi() % horror_colors.size()]
		horror_color.a *= (1.0 - _glitch_timer / _current_glitch_duration)
		glitch_overlay.color = horror_color

	# Screen tear effect (random position offset)
	if randf() < 0.2 and has_node("/root/VERASystem"):
		var vera := get_node("/root/VERASystem")
		container.position.x = randf_range(-10, 10) * vera.glitch_intensity
		container.position.y = randf_range(-5, 5) * vera.glitch_intensity
	else:
		container.position = Vector2.ZERO

	# Text corruption during glitch
	if randf() < 0.1:
		var corrupt_names := ["V̸̢̛O̷̡̔I̵̢̛D̶̨̛", "H̷̨̛U̸̡̔N̵̢̛G̶̨̛E̷̡̔R̵̢̛", "Ṱ̵̛̈H̷̨̊E̸̢̓ ̵̧̌M̷̨̈́O̶̡̊U̵̢̓Ť̸̨Ḧ̷̡́", "S̵̨̛E̸̢̓Ȩ̵̌ ̷̨̈́M̶̡̊E̵̢̓"]
		state_label.text = corrupt_names[randi() % corrupt_names.size()]

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func show_overlay() -> void:
	container.visible = true
	_update_display()

func hide_overlay() -> void:
	container.visible = false

func toggle_overlay() -> void:
	container.visible = not container.visible
	if container.visible:
		_update_display()

func pulse_corruption() -> void:
	"""Visual pulse effect when corruption changes"""
	if _pulse_tween:
		_pulse_tween.kill()

	_pulse_tween = create_tween()
	_pulse_tween.tween_property(corruption_bar, "scale", Vector2(1.1, 1.1), 0.1)
	_pulse_tween.tween_property(corruption_bar, "scale", Vector2.ONE, 0.2)

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	# Disconnect EventBus signals to prevent errors after scene is freed
	if EventBus.vera_state_changed.is_connected(_on_state_changed):
		EventBus.vera_state_changed.disconnect(_on_state_changed)
	if EventBus.vera_corruption_changed.is_connected(_on_corruption_changed):
		EventBus.vera_corruption_changed.disconnect(_on_corruption_changed)
	if EventBus.vera_glitch_triggered.is_connected(_on_glitch_triggered):
		EventBus.vera_glitch_triggered.disconnect(_on_glitch_triggered)
	if EventBus.game_state_changed.is_connected(_on_game_state_changed):
		EventBus.game_state_changed.disconnect(_on_game_state_changed)
	
	# Kill any running tweens
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
