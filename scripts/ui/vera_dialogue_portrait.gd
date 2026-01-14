extends Control
class_name VERADialoguePortrait
## VERADialoguePortrait: Animated VERA portrait for dialogue sequences.
## Uses sprite sheets for talking, gesturing, and idle animations.
## The friendly face that hides the cosmic horror beneath.

# =============================================================================
# ENUMS
# =============================================================================

enum AnimationState {
	IDLE,
	TALKING,
	GESTURING,
	HEAD_MOVEMENT,
	FULL_BODY
}

# =============================================================================
# CONSTANTS
# =============================================================================

# Sprite sheet configuration (based on vera_c_sheet.png - the labeled reference)
const SHEET_COLUMNS := 5
const SHEET_ROWS := 4  # Talking, Head Movements, Hand Gestures, Full Body

# Frame dimensions (estimated from sprite sheet)
const FRAME_WIDTH := 256
const FRAME_HEIGHT := 256

# Animation timing
const TALK_FRAME_DURATION := 0.08  # Fast mouth movement
const IDLE_FRAME_DURATION := 0.15  # Slower idle breathing
const GESTURE_FRAME_DURATION := 0.12  # Medium gesture speed
const BLINK_INTERVAL_MIN := 2.0
const BLINK_INTERVAL_MAX := 5.0

# Row indices in vera_c_sheet (0-indexed)
const ROW_TALKING := 0
const ROW_HEAD_MOVEMENT := 1
const ROW_HAND_GESTURES := 2
const ROW_FULL_BODY := 3

# =============================================================================
# EXPORTS
# =============================================================================

@export var portrait_size: Vector2 = Vector2(256, 256)
@export var auto_animate: bool = true

# =============================================================================
# NODES
# =============================================================================

var sprite: TextureRect
var glitch_overlay: ColorRect
var dialogue_frame: TextureRect

# =============================================================================
# STATE
# =============================================================================

var current_state: AnimationState = AnimationState.IDLE
var current_frame: int = 0
var animation_timer: float = 0.0
var blink_timer: float = 0.0
var is_talking: bool = false
var _glitch_active: bool = false
var _glitch_timer: float = 0.0

# Sprite sheet textures cache
var _sprite_sheets: Dictionary = {}
var _current_sheet: String = "vera_c"  # Default to the labeled sheet

# Frame duration based on state
var _frame_duration: float = IDLE_FRAME_DURATION

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_setup_nodes()
	_load_sprite_sheets()
	_connect_signals()
	_reset_blink_timer()


func _process(delta: float) -> void:
	if not auto_animate:
		return

	_process_animation(delta)
	_process_blink(delta)

	if _glitch_active:
		_process_glitch(delta)


func _setup_nodes() -> void:
	# Create main container
	custom_minimum_size = portrait_size

	# Create dialogue frame background (BC style)
	dialogue_frame = UIStyleFactory.create_bc_dialogue_frame(portrait_size + Vector2(32, 32))
	dialogue_frame.position = Vector2(-16, -16)
	add_child(dialogue_frame)

	# Create sprite display
	sprite = TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.custom_minimum_size = portrait_size
	sprite.size = portrait_size
	add_child(sprite)

	# Create glitch overlay
	glitch_overlay = ColorRect.new()
	glitch_overlay.size = portrait_size
	glitch_overlay.color = Color(0.8, 0, 0, 0)
	glitch_overlay.visible = false
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glitch_overlay)


func _load_sprite_sheets() -> void:
	# Load all VERA sprite sheets
	var sheet_names := ["vera_a", "vera_b", "vera_c", "vera_d", "vera_e"]

	for sheet_name in sheet_names:
		var path := "res://assets/sprites/vera/%s_sheet.png" % sheet_name
		if ResourceLoader.exists(path):
			_sprite_sheets[sheet_name] = load(path)
			EventBus.emit_debug("Loaded VERA sprite sheet: %s" % sheet_name)
		else:
			EventBus.emit_debug("VERA sprite sheet not found: %s" % path)

	# Set initial frame
	_update_sprite_frame()


func _connect_signals() -> void:
	EventBus.vera_glitch_triggered.connect(_on_glitch_triggered)
	EventBus.vera_state_changed.connect(_on_vera_state_changed)
	EventBus.dialogue_line_shown.connect(_on_dialogue_line_shown)


# =============================================================================
# ANIMATION PROCESSING
# =============================================================================


func _process_animation(delta: float) -> void:
	animation_timer += delta

	if animation_timer >= _frame_duration:
		animation_timer = 0.0
		_advance_frame()


func _advance_frame() -> void:
	match current_state:
		AnimationState.IDLE:
			# FIXED: IDLE should be STATIC - no frame cycling!
			# Hold frame 0 (neutral expression) - no animation glitching
			current_frame = 0
			_frame_duration = 999.0  # Effectively infinite - no cycling

		AnimationState.TALKING:
			# Smooth mouth animation - cycle through frames 0-3 (skip 4 for smoother loop)
			# Use slower timing for natural speech feel
			current_frame = (current_frame + 1) % 4
			_frame_duration = TALK_FRAME_DURATION * 1.5  # 120ms instead of 80ms

		AnimationState.GESTURING:
			# Gesture animation - full range
			current_frame = (current_frame + 1) % SHEET_COLUMNS
			_frame_duration = GESTURE_FRAME_DURATION

		AnimationState.HEAD_MOVEMENT:
			# Head movement animation
			current_frame = (current_frame + 1) % SHEET_COLUMNS
			_frame_duration = GESTURE_FRAME_DURATION

		AnimationState.FULL_BODY:
			# Full body loop - slower for idle feel
			current_frame = (current_frame + 1) % 3
			_frame_duration = IDLE_FRAME_DURATION * 2.0

	_update_sprite_frame()


func _process_blink(delta: float) -> void:
	if current_state != AnimationState.IDLE:
		return

	blink_timer -= delta
	if blink_timer <= 0:
		_trigger_blink()
		_reset_blink_timer()


func _trigger_blink() -> void:
	# Quick blink by switching to a closed-eye frame briefly
	# This would use vera_d_sheet which has eye variations
	pass  # Could be enhanced with eye-specific frames


func _reset_blink_timer() -> void:
	blink_timer = randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)


func _update_sprite_frame() -> void:
	if not _sprite_sheets.has(_current_sheet):
		return

	var sheet_texture: Texture2D = _sprite_sheets[_current_sheet]
	if not sheet_texture:
		return

	# Calculate frame region based on current state and frame
	var row := _get_row_for_state()
	var col := current_frame

	# Get actual sheet dimensions
	var sheet_size := sheet_texture.get_size()
	var actual_frame_width := sheet_size.x / SHEET_COLUMNS
	var actual_frame_height := sheet_size.y / SHEET_ROWS

	# Create atlas texture for the current frame
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet_texture
	atlas.region = Rect2(
		col * actual_frame_width,
		row * actual_frame_height,
		actual_frame_width,
		actual_frame_height
	)

	sprite.texture = atlas


func _get_row_for_state() -> int:
	match current_state:
		AnimationState.IDLE:
			return ROW_FULL_BODY  # Use full body for idle
		AnimationState.TALKING:
			return ROW_TALKING
		AnimationState.HEAD_MOVEMENT:
			return ROW_HEAD_MOVEMENT
		AnimationState.GESTURING:
			return ROW_HAND_GESTURES
		AnimationState.FULL_BODY:
			return ROW_FULL_BODY
	return ROW_FULL_BODY


# =============================================================================
# GLITCH EFFECTS
# =============================================================================


func _process_glitch(delta: float) -> void:
	_glitch_timer -= delta

	if _glitch_timer <= 0:
		_end_glitch()
		return

	# Random color flashes
	if randf() < 0.3:
		var horror_colors := [
			Color(0.8, 0, 0, 0.4),    # Blood red
			Color(0.5, 0, 0.5, 0.5),  # Void purple
			Color(0, 0, 0, 0.7),      # Darkness
			Color(1, 0, 0.5, 0.4),    # Sickly magenta
		]
		glitch_overlay.color = horror_colors[randi() % horror_colors.size()]
		glitch_overlay.visible = true
	else:
		glitch_overlay.visible = false

	# Position jitter
	if randf() < 0.2:
		sprite.position = Vector2(
			randf_range(-5, 5),
			randf_range(-3, 3)
		)
	else:
		sprite.position = Vector2.ZERO


func _end_glitch() -> void:
	_glitch_active = false
	glitch_overlay.visible = false
	glitch_overlay.color.a = 0
	sprite.position = Vector2.ZERO


func _on_glitch_triggered(intensity: float, duration: float) -> void:
	if intensity <= 0:
		_end_glitch()
		return

	_glitch_active = true
	_glitch_timer = duration


# =============================================================================
# STATE MANAGEMENT
# =============================================================================


func set_animation_state(new_state: AnimationState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	current_frame = 0
	animation_timer = 0.0

	# Update frame duration for new state
	match new_state:
		AnimationState.IDLE:
			_frame_duration = IDLE_FRAME_DURATION
		AnimationState.TALKING:
			_frame_duration = TALK_FRAME_DURATION
		AnimationState.GESTURING, AnimationState.HEAD_MOVEMENT:
			_frame_duration = GESTURE_FRAME_DURATION
		AnimationState.FULL_BODY:
			_frame_duration = IDLE_FRAME_DURATION

	_update_sprite_frame()


func start_talking() -> void:
	is_talking = true
	set_animation_state(AnimationState.TALKING)


func stop_talking() -> void:
	is_talking = false
	set_animation_state(AnimationState.IDLE)


func play_gesture() -> void:
	set_animation_state(AnimationState.GESTURING)
	# Return to idle after gesture completes
	await get_tree().create_timer(GESTURE_FRAME_DURATION * SHEET_COLUMNS).timeout
	if not is_talking:
		set_animation_state(AnimationState.IDLE)


func play_head_movement() -> void:
	set_animation_state(AnimationState.HEAD_MOVEMENT)
	await get_tree().create_timer(GESTURE_FRAME_DURATION * SHEET_COLUMNS).timeout
	if not is_talking:
		set_animation_state(AnimationState.IDLE)


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================


func _on_vera_state_changed(_old: int, new: int) -> void:
	# Change sprite sheet based on VERA's corruption state
	match new:
		Enums.VERAState.INTERFACE:
			_current_sheet = "vera_c"  # Normal friendly VERA
		Enums.VERAState.FRACTURE:
			_current_sheet = "vera_c"  # Same sheet but with glitches
		Enums.VERAState.EMERGENCE:
			_current_sheet = "vera_e"  # Magical/powerful version
		Enums.VERAState.APOTHEOSIS:
			_current_sheet = "vera_e"  # Full power VERATH

	_update_sprite_frame()


func _on_dialogue_line_shown(speaker: String, _text: String) -> void:
	if speaker == "VERA" or speaker == "VERATH":
		start_talking()


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================


func set_sprite_sheet(sheet_name: String) -> void:
	if _sprite_sheets.has(sheet_name):
		_current_sheet = sheet_name
		_update_sprite_frame()


func get_current_state() -> AnimationState:
	return current_state


func show_dialogue_frame(show: bool) -> void:
	if dialogue_frame:
		dialogue_frame.visible = show


# =============================================================================
# CLEANUP
# =============================================================================


func _exit_tree() -> void:
	if EventBus.vera_glitch_triggered.is_connected(_on_glitch_triggered):
		EventBus.vera_glitch_triggered.disconnect(_on_glitch_triggered)
	if EventBus.vera_state_changed.is_connected(_on_vera_state_changed):
		EventBus.vera_state_changed.disconnect(_on_vera_state_changed)
	if EventBus.dialogue_line_shown.is_connected(_on_dialogue_line_shown):
		EventBus.dialogue_line_shown.disconnect(_on_dialogue_line_shown)
