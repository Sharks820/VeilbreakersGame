extends Control
## MainMenuController: AAA-quality main menu with Diablo/God of War tier animations.

@onready var logo: Sprite2D = $Logo
@onready var button_container: HBoxContainer = $ButtonContainer
@onready var new_game_button: TextureButton = $ButtonContainer/NewGameButton
@onready var continue_button: TextureButton = $ButtonContainer/ContinueButton
@onready var settings_button: TextureButton = $ButtonContainer/SettingsButton
@onready var quit_button: TextureButton = $ButtonContainer/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var monster_eyes: Control = $MonsterEyes
@onready var left_eye: Control = $MonsterEyes/LeftEye
@onready var right_eye: Control = $MonsterEyes/RightEye
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var red_breath_overlay: ColorRect = $RedBreathOverlay
@onready var background: TextureRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var ember_particles: GPUParticles2D = $EmberParticles

# Animation state
var left_eye_base_pos: Vector2
var right_eye_base_pos: Vector2
var background_base_pos: Vector2
var ambient_time: float = 0.0
var animations_ready: bool = false
var continue_has_saves: bool = false
var next_blink_time: float = 0.0
var is_blinking: bool = false

# Logo scale pulse constants - subtle breathing
const LOGO_BASE_SCALE: float = 0.11
const LOGO_SCALE_MIN: float = 0.11
const LOGO_SCALE_MAX: float = 0.112
const LOGO_PULSE_DURATION: float = 2.5

var logo_tween: Tween

# Button base positions for hover restoration
var button_base_positions: Dictionary = {}

# AAA Animation constants - Diablo/Dark Souls style (SLOW and atmospheric)
const PUPIL_TRACK_RANGE: float = 3.0
const PUPIL_TRACK_SPEED: float = 4.0
const BLINK_MIN_INTERVAL: float = 2.0
const BLINK_MAX_INTERVAL: float = 6.0
const BLINK_DURATION: float = 0.15
const BREATH_SPEED: float = 0.35
const VIGNETTE_SPEED: float = 0.25
const VIGNETTE_MIN: float = 0.15
const VIGNETTE_MAX: float = 0.35

func _ready() -> void:
	GameManager.change_state(Enums.GameState.MAIN_MENU)

	# Update version label
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1.0")
	version_label.text = "v%s - Development Build" % version

	# Check saves for Continue button - store result but DON'T disable
	continue_has_saves = SaveManager.has_any_saves()

	# Setup hover effects
	_setup_button_effects()

	# Store base positions BEFORE hiding
	left_eye_base_pos = left_eye.position
	right_eye_base_pos = right_eye.position
	background_base_pos = background.position

	# Schedule first blink
	next_blink_time = randf_range(BLINK_MIN_INTERVAL, BLINK_MAX_INTERVAL)

	# Store button base positions
	for btn in [new_game_button, continue_button, settings_button, quit_button]:
		button_base_positions[btn] = btn.position.y

	# Initialize hidden state
	_hide_all_elements()

	# Play AAA entrance sequence
	_play_aaa_entrance()

	EventBus.emit_debug("Main menu ready")

func _hide_all_elements() -> void:
	# Logo - starts invisible (pivot already set in scene file)
	logo.modulate.a = 0.0

	# Eyes - invisible
	monster_eyes.modulate.a = 0.0

	# Buttons - invisible and offset down (ALL buttons including continue)
	for btn in [new_game_button, continue_button, settings_button, quit_button]:
		btn.modulate.a = 0.0
		btn.position.y += 100
		btn.pivot_offset = btn.size / 2.0
		btn.scale = Vector2(0.8, 0.8)

	# Version label
	version_label.modulate.a = 0.0

	# Red overlay starts invisible
	red_breath_overlay.modulate.a = 0.0

	# Vignette starts invisible
	vignette.modulate.a = 0.0

	# Ember particles start invisible
	ember_particles.modulate.a = 0.0

func _play_aaa_entrance() -> void:
	# === PHASE 1: Embers start floating up from darkness ===
	var ember_tween = create_tween()
	ember_tween.tween_property(ember_particles, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_OUT)

	# === PHASE 2: Background breathing starts ===
	await get_tree().create_timer(0.5).timeout
	var breath_tween = create_tween()
	breath_tween.tween_property(red_breath_overlay, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT)

	# Vignette fades in
	var vignette_tween = create_tween()
	vignette_tween.tween_property(vignette, "modulate:a", VIGNETTE_MIN, 2.0).set_ease(Tween.EASE_OUT)

	# === PHASE 3: Logo entrance - ONLY OPACITY (no scale to avoid conflict with idle) ===
	await get_tree().create_timer(0.4).timeout

	var logo_tween = create_tween()
	logo_tween.tween_property(logo, "modulate:a", 1.0, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# === PHASE 4: Monster eyes fade in eerily ===
	await get_tree().create_timer(0.8).timeout

	var eyes_tween = create_tween()
	eyes_tween.tween_property(monster_eyes, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# === PHASE 5: Buttons slide up with stagger (power3.out style) ===
	await get_tree().create_timer(0.5).timeout

	var buttons = [new_game_button, continue_button, settings_button, quit_button]
	for i in range(buttons.size()):
		var btn = buttons[i]
		var delay = i * 0.15  # Stagger
		# Continue button animates but appears dimmer if no saves
		var target_alpha = 0.4 if (btn == continue_button and not continue_has_saves) else 1.0
		var target_y = button_base_positions[btn]

		var btn_tween = create_tween().set_parallel(true)
		btn_tween.tween_property(btn, "modulate:a", target_alpha, 0.7).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		btn_tween.tween_property(btn, "position:y", target_y, 0.9).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		btn_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.8).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# === PHASE 6: Version label ===
	await get_tree().create_timer(0.8).timeout
	var version_tween = create_tween()
	version_tween.tween_property(version_label, "modulate:a", 0.5, 0.6).set_ease(Tween.EASE_OUT)

	# === PHASE 7: Start idle animations ===
	await get_tree().create_timer(0.5).timeout
	animations_ready = true
	_start_logo_pulse()
	new_game_button.grab_focus()

func _process(delta: float) -> void:
	if not animations_ready:
		return

	ambient_time += delta
	_update_breathing(delta)
	_update_eye_tracking(delta)
	_update_blinking(delta)
	_update_vignette(delta)

func _start_logo_pulse() -> void:
	# Smooth looping tween for logo scale pulse
	if logo_tween:
		logo_tween.kill()
	logo_tween = create_tween().set_loops()
	logo_tween.tween_property(logo, "scale", Vector2(LOGO_SCALE_MAX, LOGO_SCALE_MAX), LOGO_PULSE_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	logo_tween.tween_property(logo, "scale", Vector2(LOGO_SCALE_MIN, LOGO_SCALE_MIN), LOGO_PULSE_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _update_breathing(delta: float) -> void:
	# Dark Souls style breathing - the background art's red glows and dims
	var breath = (sin(ambient_time * BREATH_SPEED) + 1.0) * 0.5  # 0 to 1

	# Visible but not overwhelming breathing effect
	# At peak: warm glow (1.2), at low: slightly darker (0.85)
	var brightness = 0.85 + breath * 0.35  # Range: 0.85 to 1.2
	# Emphasize red channel for hellish glow
	background.self_modulate = Color(brightness * 1.15, brightness * 0.85, brightness * 0.75, 1.0)

	# Subtle darkening overlay pulse
	dark_overlay.color.a = 0.15 - breath * 0.1  # Range: 0.05 to 0.15

func _update_vignette(delta: float) -> void:
	# Vignette pulses very slowly for cinematic feel
	var vignette_pulse = (sin(ambient_time * VIGNETTE_SPEED) + 1.0) * 0.5
	vignette.color.a = VIGNETTE_MIN + vignette_pulse * (VIGNETTE_MAX - VIGNETTE_MIN)

func _update_eye_tracking(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()

	# Track left eye - subtle movement toward mouse
	var left_dir = (mouse_pos - left_eye.global_position).normalized()
	var left_dist = clamp((mouse_pos - left_eye.global_position).length() / 500.0, 0.0, 1.0)
	var left_target = left_eye_base_pos + left_dir * PUPIL_TRACK_RANGE * left_dist
	left_eye.position = left_eye.position.lerp(left_target, delta * PUPIL_TRACK_SPEED)

	# Track right eye
	var right_dir = (mouse_pos - right_eye.global_position).normalized()
	var right_dist = clamp((mouse_pos - right_eye.global_position).length() / 500.0, 0.0, 1.0)
	var right_target = right_eye_base_pos + right_dir * PUPIL_TRACK_RANGE * right_dist
	right_eye.position = right_eye.position.lerp(right_target, delta * PUPIL_TRACK_SPEED)

	# Subtle pulse synchronized with breathing
	var breath = (sin(ambient_time * BREATH_SPEED) + 1.0) * 0.5
	var pulse = 1.0 + breath * 0.1
	left_eye.scale = Vector2(pulse, pulse)
	right_eye.scale = Vector2(pulse, pulse)

func _update_blinking(delta: float) -> void:
	if is_blinking:
		return

	next_blink_time -= delta
	if next_blink_time <= 0:
		_do_blink()
		next_blink_time = randf_range(BLINK_MIN_INTERVAL, BLINK_MAX_INTERVAL)

func _do_blink() -> void:
	is_blinking = true

	# Glowing eyes blink by fading out then back in
	var blink_tween = create_tween()
	blink_tween.tween_property(left_eye, "modulate:a", 0.1, BLINK_DURATION).set_ease(Tween.EASE_IN)
	blink_tween.parallel().tween_property(right_eye, "modulate:a", 0.1, BLINK_DURATION).set_ease(Tween.EASE_IN)

	# Fade back in
	blink_tween.tween_property(left_eye, "modulate:a", 1.0, BLINK_DURATION).set_ease(Tween.EASE_OUT)
	blink_tween.parallel().tween_property(right_eye, "modulate:a", 1.0, BLINK_DURATION).set_ease(Tween.EASE_OUT)

	blink_tween.tween_callback(func(): is_blinking = false)

func _setup_button_effects() -> void:
	for button in [new_game_button, continue_button, settings_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.focus_entered.connect(_on_button_hover.bind(button))
		button.focus_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: TextureButton) -> void:
	# Continue button can hover even without saves (but can't click)
	if button == continue_button and not continue_has_saves:
		# Subtle hover for disabled state
		var tween = create_tween().set_parallel(true)
		tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "modulate:a", 0.55, 0.2)
		return

	# AAA hover - STRONG scale up with overshoot, lift, intense glow, tilt
	var base_y = button_base_positions.get(button, button.position.y)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.18, 1.18), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "position:y", base_y - 20, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "modulate", Color(1.6, 1.25, 1.15, 1.0), 0.15)
	tween.tween_property(button, "rotation_degrees", randf_range(-2.0, 2.0), 0.12)

func _on_button_unhover(button: TextureButton) -> void:
	var base_y = button_base_positions.get(button, button.position.y + 20)
	var target_alpha = 0.4 if (button == continue_button and not continue_has_saves) else 1.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "position:y", base_y, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, target_alpha), 0.2)
	tween.tween_property(button, "rotation_degrees", 0.0, 0.15)

func _on_new_game_pressed() -> void:
	EventBus.emit_debug("New Game selected")
	_play_button_press(new_game_button)
	GameManager.reset_for_new_game()
	await get_tree().create_timer(0.3).timeout
	SceneManager.change_scene("res://scenes/test/test_battle.tscn")

func _on_continue_pressed() -> void:
	# Block if no saves
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
	# Satisfying press animation - quick squish then bounce back
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.08).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_CUBIC)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		pass
