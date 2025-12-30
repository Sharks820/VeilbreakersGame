extends Control
## MainMenuController: AAA-quality main menu with perfect cursor-tracking demon eyes.

@onready var logo: Sprite2D = $Logo
@onready var button_container: HBoxContainer = $ButtonContainer
@onready var new_game_button: TextureButton = $ButtonContainer/NewGameButton
@onready var continue_button: TextureButton = $ButtonContainer/ContinueButton
@onready var settings_button: TextureButton = $ButtonContainer/SettingsButton
@onready var quit_button: TextureButton = $ButtonContainer/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var monster_eye: Sprite2D = $MonsterEye
@onready var eye_backdrop: Sprite2D = $EyeBackdrop
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var red_breath_overlay: ColorRect = $RedBreathOverlay
@onready var background: TextureRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var ember_particles: GPUParticles2D = $EmberParticles

# =============================================================================
# EYE TRACKING SYSTEM - 6x7 SPRITE SHEET (42 frames)
# =============================================================================
# 4 frames per direction + 4 blink frames for smooth animation.
# Layout (6 columns x 7 rows):
#   Row 0: UP-LEFT (0-3), UP (4-5)
#   Row 1: UP (6-7), UP-RIGHT (8-11)
#   Row 2: LEFT (12-15), CENTER (16-17)
#   Row 3: CENTER (18-19), RIGHT (20-23)
#   Row 4: DOWN-LEFT (24-27), DOWN (28-29)
#   Row 5: DOWN (30-31), DOWN-RIGHT (32-35)
#   Row 6: BLINK (36-39), empty (40-41)

# Sprite sheet configuration
const EYE_GRID_COLS: int = 6
const EYE_GRID_ROWS: int = 7
const EYE_TOTAL_FRAMES: int = 42

# =============================================================================
# DIRECTIONAL FRAME ARRAYS - 4 frames each for smooth animation
# =============================================================================
const FRAMES_UP_LEFT: Array[int] = [0, 1, 2, 3]
const FRAMES_UP: Array[int] = [4, 5, 6, 7]
const FRAMES_UP_RIGHT: Array[int] = [8, 9, 10, 11]
const FRAMES_LEFT: Array[int] = [12, 13, 14, 15]
const FRAMES_CENTER: Array[int] = [16, 17, 18, 19]
const FRAMES_RIGHT: Array[int] = [20, 21, 22, 23]
const FRAMES_DOWN_LEFT: Array[int] = [24, 25, 26, 27]
const FRAMES_DOWN: Array[int] = [28, 29, 30, 31]
const FRAMES_DOWN_RIGHT: Array[int] = [32, 33, 34, 35]

# Blink frames (eyes squinting/closing)
const BLINK_ENABLED: bool = true
const BLINK_FRAMES: Array[int] = [36, 37, 38, 39]
const BLINK_FRAME_COUNT: int = 4

# Zone threshold - distance from center to trigger edge zones (normalized 0-1)
# Lower value = more sensitive, triggers directions more easily
const ZONE_THRESHOLD: float = 0.08

# Smooth animation timing - very slow cycling for subtle variation
const FRAME_CYCLE_SPEED: float = 0.3  # Frames per second within direction (slow = subtle)

# Timing constants
const EYE_TRACK_SPEED: float = 12.0  # Higher = snappier tracking
const EYE_SMOOTHING: float = 0.08    # Lower = smoother frame transitions
const BLINK_INTERVAL_MIN: float = 2.5
const BLINK_INTERVAL_MAX: float = 6.0
const BLINK_FRAME_DURATION: float = 0.035  # Time per blink frame (faster blink)

# Eye state
var eye_current_frame: float = 0.0
var eye_target_frame: int = 0
var eye_is_blinking: bool = false
var eye_blink_timer: float = 0.0
var eye_next_blink: float = 4.0
var eye_blink_frame_index: int = 0
var eye_blink_frame_timer: float = 0.0

# Store last valid tracking frame for after blink
var eye_last_tracking_frame: int = 0

# Shader-based gaze tracking
var eye_gaze_target: Vector2 = Vector2.ZERO
var eye_gaze_current: Vector2 = Vector2.ZERO

# =============================================================================
# GENERAL ANIMATION STATE
# =============================================================================

var background_base_pos: Vector2
var ambient_time: float = 0.0
var animations_ready: bool = false
var continue_has_saves: bool = false

# Logo scale pulse constants
const LOGO_BASE_SCALE: float = 0.11
const LOGO_SCALE_MIN: float = 0.11
const LOGO_SCALE_MAX: float = 0.112
const LOGO_PULSE_DURATION: float = 2.5

var logo_tween: Tween

# Button base positions for hover restoration
var button_base_positions: Dictionary = {}

# Breathing effect constants
const BREATH_SPEED: float = 0.35
const VIGNETTE_SPEED: float = 0.25
const VIGNETTE_MIN: float = 0.15
const VIGNETTE_MAX: float = 0.35

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	GameManager.change_state(Enums.GameState.MAIN_MENU)

	# Update version label
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1.0")
	version_label.text = "v%s - Development Build" % version

	# Check saves for Continue button
	continue_has_saves = SaveManager.has_any_saves()

	# Setup hover effects
	_setup_button_effects()

	# Store base positions
	background_base_pos = background.position

	# Store button base positions
	for btn in [new_game_button, continue_button, settings_button, quit_button]:
		button_base_positions[btn] = btn.position.y

	# Initialize hidden state
	_hide_all_elements()

	# Randomize first blink
	eye_next_blink = randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)

	# Play entrance sequence
	_play_aaa_entrance()

	EventBus.emit_debug("Main menu ready - Demon eyes tracking active")

func _hide_all_elements() -> void:
	# Logo - starts invisible
	logo.modulate.a = 0.0

	# Monster eye and backdrop - visible immediately to cover background eyes
	# Eyes slightly more visible than background
	monster_eye.modulate.a = 1.0
	eye_backdrop.modulate.a = 1.0

	# Buttons - invisible and offset down
	for btn in [new_game_button, continue_button, settings_button, quit_button]:
		btn.modulate.a = 0.0
		btn.position.y += 100
		btn.pivot_offset = btn.size / 2.0
		btn.scale = Vector2(0.8, 0.8)

	# Version label
	version_label.modulate.a = 0.0

	# RED BREATH - START IMMEDIATELY with background!
	red_breath_overlay.modulate.a = 0.6
	vignette.modulate.a = VIGNETTE_MIN
	ember_particles.modulate.a = 0.5

# =============================================================================
# ENTRANCE ANIMATION
# =============================================================================

func _play_aaa_entrance() -> void:
	# Effects already visible from _hide_all_elements - just intensify them smoothly

	# Phase 1: Embers intensify
	var ember_tween = create_tween()
	ember_tween.tween_property(ember_particles, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT)

	# Phase 2: Red breath intensifies (already at 0.6, going to 1.0)
	var breath_tween = create_tween()
	breath_tween.tween_property(red_breath_overlay, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_OUT)

	# Phase 3: Logo entrance after short delay
	await get_tree().create_timer(0.3).timeout
	var logo_entrance = create_tween()
	logo_entrance.tween_property(logo, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 4: Buttons slide up (shortened delays for snappier feel)
	await get_tree().create_timer(0.8).timeout
	var buttons = [new_game_button, continue_button, settings_button, quit_button]
	for i in range(buttons.size()):
		var btn = buttons[i]
		var delay = i * 0.15
		var target_alpha = 0.4 if (btn == continue_button and not continue_has_saves) else 1.0
		var target_y = button_base_positions[btn]

		var btn_tween = create_tween().set_parallel(true)
		btn_tween.tween_property(btn, "modulate:a", target_alpha, 0.7).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		btn_tween.tween_property(btn, "position:y", target_y, 0.9).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		btn_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.8).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Phase 6: Version label
	await get_tree().create_timer(0.8).timeout
	var version_tween = create_tween()
	version_tween.tween_property(version_label, "modulate:a", 0.5, 0.6).set_ease(Tween.EASE_OUT)

	# Phase 7: Start idle animations
	await get_tree().create_timer(0.5).timeout
	animations_ready = true
	_start_logo_pulse()
	new_game_button.grab_focus()

# =============================================================================
# PROCESS LOOP
# =============================================================================

func _process(delta: float) -> void:
	# Eye tracking and breathing start IMMEDIATELY - no waiting!
	ambient_time += delta
	_update_breathing(delta)
	_update_eye_tracking(delta)
	_update_vignette(delta)

# =============================================================================
# EYE TRACKING SYSTEM
# =============================================================================

func _update_eye_tracking(delta: float) -> void:
	# Handle blink timer (only if blinking is enabled)
	if BLINK_ENABLED and not eye_is_blinking:
		eye_blink_timer += delta
		if eye_blink_timer >= eye_next_blink:
			_start_blink()

	# Handle blinking animation
	if eye_is_blinking:
		_update_blink(delta)
	else:
		_update_cursor_tracking(delta)

	# Apply subtle breathing pulse to eye scale (base scale is 0.17x0.17)
	var breath = (sin(ambient_time * BREATH_SPEED) + 1.0) * 0.5
	var base_scale_x = 0.17
	var base_scale_y = 0.17
	var pulse_x = base_scale_x + breath * 0.005
	var pulse_y = base_scale_y + breath * 0.005
	monster_eye.scale = Vector2(pulse_x, pulse_y)
	eye_backdrop.scale = Vector2(pulse_x, pulse_y)

	# Blend eyes with fiery red background - brighter but with red warmth
	var red_tint = 1.0 + breath * 0.1
	var green = 0.65 + breath * 0.05
	var blue = 0.55 + breath * 0.03
	var alpha = 0.95  # Nearly opaque
	monster_eye.modulate = Color(red_tint, green, blue, alpha)

func _update_cursor_tracking(delta: float) -> void:
	# SMOOTH 9-ZONE TRACKING with frame cycling within each direction
	var mouse_pos = get_global_mouse_position()
	var eye_pos = monster_eye.global_position
	var viewport_size = get_viewport_rect().size

	# Calculate normalized direction from eye to cursor (-1 to 1)
	var dx = (mouse_pos.x - eye_pos.x) / (viewport_size.x * 0.35)
	var dy = (mouse_pos.y - eye_pos.y) / (viewport_size.y * 0.35)

	# Clamp to valid range
	dx = clamp(dx, -1.0, 1.0)
	dy = clamp(dy, -1.0, 1.0)

	# Determine 9-zone direction based on thresholds
	var look_left = dx < -ZONE_THRESHOLD
	var look_right = dx > ZONE_THRESHOLD
	var look_up = dy < -ZONE_THRESHOLD
	var look_down = dy > ZONE_THRESHOLD

	# Select frame array based on zone
	var target_frames: Array[int] = FRAMES_CENTER

	if look_up and look_left:
		target_frames = FRAMES_UP_LEFT
	elif look_up and look_right:
		target_frames = FRAMES_UP_RIGHT
	elif look_up:
		target_frames = FRAMES_UP
	elif look_down and look_left:
		target_frames = FRAMES_DOWN_LEFT
	elif look_down and look_right:
		target_frames = FRAMES_DOWN_RIGHT
	elif look_down:
		target_frames = FRAMES_DOWN
	elif look_left:
		target_frames = FRAMES_LEFT
	elif look_right:
		target_frames = FRAMES_RIGHT
	else:
		target_frames = FRAMES_CENTER

	# Use first frame only - cycling disabled to prevent glitching
	var target_frame: int = target_frames[0]

	# Update frame for both eye and backdrop
	eye_target_frame = target_frame
	eye_last_tracking_frame = target_frame
	monster_eye.frame = target_frame
	eye_backdrop.frame = target_frame

func _start_blink() -> void:
	eye_is_blinking = true
	eye_blink_frame_index = 0
	eye_blink_frame_timer = 0.0
	eye_blink_timer = 0.0
	eye_next_blink = randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)

func _update_blink(delta: float) -> void:
	eye_blink_frame_timer += delta

	if eye_blink_frame_timer >= BLINK_FRAME_DURATION:
		eye_blink_frame_timer = 0.0
		eye_blink_frame_index += 1

		if eye_blink_frame_index >= BLINK_FRAME_COUNT:
			# Blink finished, return to tracking
			eye_is_blinking = false
			monster_eye.frame = eye_last_tracking_frame
			eye_backdrop.frame = eye_last_tracking_frame
			return

	# Use blink frames from the BLINK_FRAMES array
	var blink_frame: int = BLINK_FRAMES[eye_blink_frame_index % BLINK_FRAMES.size()]
	monster_eye.frame = blink_frame
	eye_backdrop.frame = blink_frame

# =============================================================================
# AMBIENT ANIMATIONS
# =============================================================================

func _start_logo_pulse() -> void:
	if logo_tween:
		logo_tween.kill()
	logo_tween = create_tween().set_loops()
	logo_tween.tween_property(logo, "scale", Vector2(LOGO_SCALE_MAX, LOGO_SCALE_MAX), LOGO_PULSE_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	logo_tween.tween_property(logo, "scale", Vector2(LOGO_SCALE_MIN, LOGO_SCALE_MIN), LOGO_PULSE_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _update_breathing(delta: float) -> void:
	var breath = (sin(ambient_time * BREATH_SPEED) + 1.0) * 0.5
	var brightness = 0.85 + breath * 0.35
	background.self_modulate = Color(brightness * 1.15, brightness * 0.85, brightness * 0.75, 1.0)
	dark_overlay.color.a = 0.15 - breath * 0.1

func _update_vignette(delta: float) -> void:
	var vignette_pulse = (sin(ambient_time * VIGNETTE_SPEED) + 1.0) * 0.5
	vignette.color.a = VIGNETTE_MIN + vignette_pulse * (VIGNETTE_MAX - VIGNETTE_MIN)

# =============================================================================
# BUTTON EFFECTS
# =============================================================================

func _setup_button_effects() -> void:
	for button in [new_game_button, continue_button, settings_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.focus_entered.connect(_on_button_hover.bind(button))
		button.focus_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: TextureButton) -> void:
	if button == continue_button and not continue_has_saves:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "modulate:a", 0.55, 0.2)
		return

	var base_y = button_base_positions.get(button, button.position.y)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.12, 1.12), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "position:y", base_y - 12, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color(1.2, 1.1, 1.05, 1.0), 0.15)
	tween.tween_property(button, "rotation_degrees", randf_range(-1.0, 1.0), 0.12)

func _on_button_unhover(button: TextureButton) -> void:
	var base_y = button_base_positions.get(button, button.position.y + 20)
	var target_alpha = 0.4 if (button == continue_button and not continue_has_saves) else 1.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "position:y", base_y, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, target_alpha), 0.2)
	tween.tween_property(button, "rotation_degrees", 0.0, 0.15)

# =============================================================================
# BUTTON ACTIONS
# =============================================================================

func _on_new_game_pressed() -> void:
	EventBus.emit_debug("New Game selected")
	_play_button_press(new_game_button)
	GameManager.reset_for_new_game()
	await get_tree().create_timer(0.3).timeout
	SceneManager.change_scene("res://scenes/test/test_battle.tscn")

func _on_continue_pressed() -> void:
	if not continue_has_saves:
		EventBus.emit_notification("No save data found", "warning")
		return

	EventBus.emit_debug("Continue selected")
	_play_button_press(continue_button)
	var slot = SaveManager.get_most_recent_slot()
	if slot >= 0:
		SaveManager.load_game(slot)
	else:
		EventBus.emit_notification("No save data found", "warning")

func _on_settings_pressed() -> void:
	EventBus.emit_debug("Settings selected")
	_play_button_press(settings_button)
	EventBus.emit_notification("Settings - Not yet implemented", "info")

func _on_quit_pressed() -> void:
	EventBus.emit_debug("Quit selected")
	_play_button_press(quit_button)
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()

func _play_button_press(button: TextureButton) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.08).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		pass
