class_name TimedDefenseSystem
extends Node
## TimedDefenseSystem: Active defense mechanic - press defend button when attacked for damage reduction
## Features anti-spam: early clicks fail, only clicks on the popup button count

# =============================================================================
# SIGNALS
# =============================================================================

signal defense_popup_shown(defender: CharacterBase, attacker: CharacterBase)
signal defense_success(defender: CharacterBase, is_perfect: bool, reduction: float)
signal defense_failed(defender: CharacterBase, reason: String)
signal defense_window_closed()

# =============================================================================
# STATE
# =============================================================================

enum DefenseState { IDLE, WAITING_DELAY, POPUP_ACTIVE, COOLDOWN }

var current_state: DefenseState = DefenseState.IDLE
var current_defender: CharacterBase = null
var current_attacker: CharacterBase = null
var popup_start_time: float = 0.0
var window_timer: Timer = null
var delay_timer: Timer = null
var has_clicked_early: bool = false  # Anti-spam: if clicked before popup, fail
var defense_result: Dictionary = {}

# UI References (set by battle scene)
var popup_button: Button = null
var popup_container: Control = null
var timing_bar: ProgressBar = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Create timers
	window_timer = Timer.new()
	window_timer.name = "WindowTimer"
	window_timer.one_shot = true
	window_timer.timeout.connect(_on_window_expired)
	add_child(window_timer)

	delay_timer = Timer.new()
	delay_timer.name = "DelayTimer"
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_on_delay_complete)
	add_child(delay_timer)

func setup_ui(container: Control, button: Button, bar: ProgressBar = null) -> void:
	## Connect UI elements for the timed defense popup
	popup_container = container
	popup_button = button
	timing_bar = bar

	if popup_button:
		popup_button.pressed.connect(_on_popup_button_pressed)

	if popup_container:
		popup_container.hide()

# =============================================================================
# DEFENSE FLOW
# =============================================================================

func start_defense_opportunity(defender: CharacterBase, attacker: CharacterBase) -> Dictionary:
	## Called when an enemy attacks - gives defender chance to block
	## Returns result after window closes
	current_defender = defender
	current_attacker = attacker
	has_clicked_early = false
	defense_result = {}

	# Start with random delay to prevent spam timing
	var delay := randf_range(Constants.TIMED_DEFENSE_POPUP_DELAY_MIN, Constants.TIMED_DEFENSE_POPUP_DELAY_MAX)
	current_state = DefenseState.WAITING_DELAY
	delay_timer.start(delay)

	# Wait for defense result
	while defense_result.is_empty():
		await get_tree().process_frame

	return defense_result

func _on_delay_complete() -> void:
	## Delay finished, show the popup
	if has_clicked_early:
		# Player clicked too early - instant fail
		_complete_defense(false, "early_click")
		return

	current_state = DefenseState.POPUP_ACTIVE
	popup_start_time = Time.get_ticks_msec() / 1000.0

	# Position popup near the defender
	if popup_container and current_defender:
		var sprite: Node2D = current_defender.get_meta("battle_sprite", null)
		if sprite:
			popup_container.global_position = sprite.global_position + Vector2(-40, -100)
		popup_container.show()

		# Animate popup entrance
		popup_container.scale = Vector2(0.5, 0.5)
		popup_container.modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(popup_container, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(popup_container, "modulate:a", 1.0, 0.1)

	# Start the timing window
	window_timer.start(Constants.TIMED_DEFENSE_WINDOW)

	defense_popup_shown.emit(current_defender, current_attacker)

func _on_popup_button_pressed() -> void:
	## Player clicked the defense button
	if current_state != DefenseState.POPUP_ACTIVE:
		return

	var click_time := Time.get_ticks_msec() / 1000.0
	var elapsed := click_time - popup_start_time

	# Check for perfect timing (first 0.1s of window)
	var is_perfect := elapsed <= Constants.TIMED_DEFENSE_PERFECT_WINDOW

	_complete_defense(true, "success", is_perfect)

func _on_window_expired() -> void:
	## Timing window closed without input
	if current_state == DefenseState.POPUP_ACTIVE:
		_complete_defense(false, "timeout")

func _complete_defense(success: bool, reason: String, is_perfect: bool = false) -> void:
	## Finalize the defense attempt
	current_state = DefenseState.COOLDOWN

	# Hide popup with animation
	if popup_container:
		var tween := create_tween()
		tween.tween_property(popup_container, "modulate:a", 0.0, 0.1)
		tween.tween_callback(popup_container.hide)

	window_timer.stop()

	var reduction := 0.0
	if success:
		reduction = Constants.TIMED_DEFENSE_PERFECT_REDUCTION if is_perfect else Constants.TIMED_DEFENSE_REDUCTION
		defense_success.emit(current_defender, is_perfect, reduction)
		EventBus.emit_debug("%s TIMED DEFENSE %s! (%.0f%% reduction)" % [
			current_defender.character_name,
			"PERFECT" if is_perfect else "SUCCESS",
			reduction * 100
		])
	else:
		defense_failed.emit(current_defender, reason)
		EventBus.emit_debug("%s timed defense FAILED (%s)" % [current_defender.character_name, reason])

	defense_result = {
		"success": success,
		"is_perfect": is_perfect,
		"reduction": reduction,
		"reason": reason
	}

	defense_window_closed.emit()
	current_state = DefenseState.IDLE

# =============================================================================
# INPUT HANDLING (Anti-spam)
# =============================================================================

func _input(event: InputEvent) -> void:
	## Track early clicks during the delay phase to punish spam
	if current_state == DefenseState.WAITING_DELAY:
		if event is InputEventMouseButton and event.pressed:
			has_clicked_early = true
			EventBus.emit_debug("Timed Defense: Early click detected - will fail!")
		elif event.is_action_pressed("ui_accept"):
			has_clicked_early = true
			EventBus.emit_debug("Timed Defense: Early click detected - will fail!")

# =============================================================================
# PROCESS (Timing bar update)
# =============================================================================

func _process(_delta: float) -> void:
	if current_state == DefenseState.POPUP_ACTIVE and timing_bar:
		var elapsed := (Time.get_ticks_msec() / 1000.0) - popup_start_time
		var progress := 1.0 - (elapsed / Constants.TIMED_DEFENSE_WINDOW)
		timing_bar.value = clampf(progress, 0.0, 1.0)

		# Color feedback: green -> yellow -> red as time runs out
		if progress > 0.6:
			timing_bar.modulate = Color(0.3, 1.0, 0.3)  # Green
		elif progress > 0.3:
			timing_bar.modulate = Color(1.0, 1.0, 0.3)  # Yellow
		else:
			timing_bar.modulate = Color(1.0, 0.3, 0.3)  # Red

# =============================================================================
# UTILITIES
# =============================================================================

func is_active() -> bool:
	return current_state != DefenseState.IDLE

func cancel() -> void:
	## Cancel any active defense opportunity
	if current_state != DefenseState.IDLE:
		window_timer.stop()
		delay_timer.stop()
		if popup_container:
			popup_container.hide()
		current_state = DefenseState.IDLE
		defense_result = {"success": false, "reason": "cancelled", "reduction": 0.0}
