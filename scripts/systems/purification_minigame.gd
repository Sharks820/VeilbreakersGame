extends Node
## PurificationMinigame: Handles the interactive purification minigame mechanics.
## This is the gameplay-focused system for purifying monsters.

# =============================================================================
# SIGNALS
# =============================================================================

signal minigame_started(monster: Monster)
signal minigame_progress(progress: float)
signal minigame_success(monster: Monster)
signal minigame_failure(monster: Monster)
signal minigame_cancelled()
signal input_success()
signal input_failure()

# =============================================================================
# STATE
# =============================================================================

var is_active: bool = false
var current_target: Monster = null
var purification_progress: float = 0.0
var corruption_resistance: float = 0.0

# Minigame settings
const PROGRESS_PER_SUCCESS: float = 20.0
const PROGRESS_DECAY_RATE: float = 5.0
const MAX_ATTEMPTS: int = 5
const TIME_LIMIT: float = 10.0
const PERFECT_TIMING_BONUS: float = 1.5

var current_attempts: int = 0
var time_remaining: float = 0.0
var combo_count: int = 0
var best_combo: int = 0

# Rhythm minigame state
var beat_sequence: Array[float] = []
var current_beat_index: int = 0
var beat_window: float = 0.2  # Time window to hit a beat
var last_beat_time: float = 0.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.emit_debug("PurificationMinigame initialized")

func _process(delta: float) -> void:
	if not is_active:
		return

	# Decay progress over time based on corruption resistance
	var decay := PROGRESS_DECAY_RATE * delta * (1.0 + corruption_resistance)
	purification_progress = maxf(0.0, purification_progress - decay)

	# Time limit countdown
	time_remaining -= delta
	if time_remaining <= 0:
		_on_failure()
		return

	minigame_progress.emit(purification_progress)

# =============================================================================
# MAIN INTERFACE
# =============================================================================

func start_purification(target: Monster) -> void:
	if is_active:
		push_warning("Purification minigame already in progress")
		return

	if not target.can_be_purified():
		EventBus.emit_notification("This monster cannot be purified!", "warning")
		return

	is_active = true
	current_target = target
	purification_progress = 0.0
	corruption_resistance = target.corruption_level / 100.0
	current_attempts = 0
	time_remaining = TIME_LIMIT * (1.0 + corruption_resistance * 0.5)  # More time for harder monsters
	combo_count = 0
	best_combo = 0

	# Generate beat sequence for rhythm mechanic
	_generate_beat_sequence()

	EventBus.purification_started.emit(target)
	minigame_started.emit(target)
	EventBus.emit_debug("Purification minigame started for: %s" % target.character_name)

func cancel_purification() -> void:
	if not is_active:
		return

	is_active = false
	current_target = null
	beat_sequence.clear()
	minigame_cancelled.emit()
	EventBus.emit_debug("Purification cancelled")

func _generate_beat_sequence() -> void:
	beat_sequence.clear()
	var num_beats := 5 + int(corruption_resistance * 5)  # 5-10 beats based on difficulty
	var interval := (TIME_LIMIT * 0.8) / num_beats

	for i in range(num_beats):
		beat_sequence.append(interval * (i + 1))

	current_beat_index = 0

# =============================================================================
# MINIGAME INPUTS
# =============================================================================

func register_input_success(timing_quality: float = 1.0) -> void:
	"""Called when player successfully completes a minigame action.
	timing_quality: 0.5-1.5, where 1.0 is normal, 1.5 is perfect timing"""
	if not is_active:
		return

	var success_amount := PROGRESS_PER_SUCCESS * (1.0 - corruption_resistance * 0.3)
	success_amount *= timing_quality

	# Combo bonus
	combo_count += 1
	if combo_count > best_combo:
		best_combo = combo_count
	success_amount *= (1.0 + combo_count * 0.1)  # 10% bonus per combo

	purification_progress += success_amount

	input_success.emit()
	EventBus.purification_progress.emit(current_target, purification_progress)

	if purification_progress >= 100.0:
		_on_success()

func register_input_failure() -> void:
	"""Called when player fails a minigame action"""
	if not is_active:
		return

	current_attempts += 1
	combo_count = 0  # Reset combo
	purification_progress = maxf(0.0, purification_progress - 10.0)

	input_failure.emit()

	if current_attempts >= MAX_ATTEMPTS:
		_on_failure()

func check_beat_timing() -> Dictionary:
	"""Check if player input is within timing window of current beat.
	Returns {hit: bool, quality: float (0.5-1.5), early: bool, late: bool}"""
	var current_time := TIME_LIMIT - time_remaining

	if current_beat_index >= beat_sequence.size():
		return {"hit": false, "quality": 0.0, "early": false, "late": false}

	var beat_time := beat_sequence[current_beat_index]
	var diff := absf(current_time - beat_time)

	if diff <= beat_window:
		# Hit! Calculate quality
		var quality := 1.5 - (diff / beat_window)  # 1.5 for perfect, 0.5 for edge
		current_beat_index += 1
		return {
			"hit": true,
			"quality": quality,
			"early": current_time < beat_time,
			"late": current_time > beat_time
		}
	elif current_time > beat_time + beat_window:
		# Missed the beat
		current_beat_index += 1
		return {"hit": false, "quality": 0.0, "early": false, "late": true}

	return {"hit": false, "quality": 0.0, "early": true, "late": false}

# =============================================================================
# RESULTS
# =============================================================================

func _on_success() -> void:
	is_active = false

	# Apply purification to monster
	if current_target:
		current_target.reduce_corruption(current_target.corruption_level)  # Full cleanse
		current_target.is_corrupted = false

	# Calculate bonus based on performance
	var performance_bonus := 1.0 + (best_combo * 0.05)  # 5% per combo

	minigame_success.emit(current_target)
	EventBus.purification_succeeded.emit(current_target)

	# Offer recruitment
	if current_target:
		current_target.recruit_to_party()

	EventBus.emit_notification("Purification successful!", "success")
	EventBus.emit_debug("Purification complete. Best combo: %d" % best_combo)

	current_target = null
	beat_sequence.clear()

func _on_failure() -> void:
	is_active = false

	minigame_failure.emit(current_target)
	EventBus.purification_failed.emit(current_target)

	# Monster becomes enraged
	if current_target:
		current_target.add_corruption(10.0)
		current_target.add_stat_modifier(Enums.Stat.ATTACK, 5.0, 3, "purify_rage")

	EventBus.emit_notification("Purification failed!", "warning")
	EventBus.emit_debug("Purification failed. Attempts: %d" % current_attempts)

	current_target = null
	beat_sequence.clear()

# =============================================================================
# QUERIES
# =============================================================================

func get_purification_difficulty(monster: Monster) -> String:
	var resistance := monster.corruption_level / 100.0

	if resistance < 0.3:
		return "Easy"
	elif resistance < 0.5:
		return "Medium"
	elif resistance < 0.7:
		return "Hard"
	else:
		return "Very Hard"

func get_difficulty_color(monster: Monster) -> Color:
	var difficulty := get_purification_difficulty(monster)
	match difficulty:
		"Easy":
			return Color.GREEN
		"Medium":
			return Color.YELLOW
		"Hard":
			return Color.ORANGE
		"Very Hard":
			return Color.RED
	return Color.WHITE

func get_current_progress() -> float:
	return purification_progress

func get_time_remaining() -> float:
	return time_remaining

func get_time_percent() -> float:
	return time_remaining / TIME_LIMIT

func get_combo() -> int:
	return combo_count

func get_next_beat_time() -> float:
	if current_beat_index >= beat_sequence.size():
		return -1.0
	return beat_sequence[current_beat_index]

func get_attempts_remaining() -> int:
	return MAX_ATTEMPTS - current_attempts
