class_name MathHelpers
extends RefCounted
## MathHelpers: Centralized math calculation helper functions.
## Consolidates 50+ duplicate calculation patterns across the codebase.

# =============================================================================
# HP PERCENTAGE CALCULATIONS (7+ duplicates)
# =============================================================================


## Get HP as percentage (0.0 to 1.0) - handles division by zero
static func get_hp_percent(current_hp: int, max_hp: int) -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)


## Get HP percent from character node (assumes current_hp/max_hp or get_max_hp())
static func get_character_hp_percent(character: Variant) -> float:
	if character == null:
		return 0.0
	var current: int = character.current_hp if "current_hp" in character else 0
	var maximum: int = 0
	if character.has_method("get_max_hp"):
		maximum = character.get_max_hp()
	elif "max_hp" in character:
		maximum = character.max_hp
	return get_hp_percent(current, maximum)


## Check if HP is below threshold (common pattern for low HP triggers)
static func hp_below(current_hp: int, max_hp: int, threshold: float) -> bool:
	return get_hp_percent(current_hp, max_hp) < threshold


## Check if HP is at or below threshold
static func hp_at_or_below(current_hp: int, max_hp: int, threshold: float) -> bool:
	return get_hp_percent(current_hp, max_hp) <= threshold


## Get HP bonus for capture/purification (higher bonus for lower HP)
## Returns bonus from 0.0 to max_bonus based on missing HP
static func get_hp_missing_bonus(
	current_hp: int, max_hp: int, max_bonus: float = Constants.CAPTURE_HP_BONUS_MAX
) -> float:
	var hp_percent := get_hp_percent(current_hp, max_hp)
	var missing_percent := 1.0 - hp_percent
	return minf(missing_percent * Constants.CAPTURE_HP_BONUS_PER_MISSING * 100.0, max_bonus)


# =============================================================================
# PROBABILITY CLAMPING (12+ duplicates)
# =============================================================================


## Clamp probability to standard capture/purify range (5% to 95%)
static func clamp_probability(value: float) -> float:
	return clampf(value, 0.05, 0.95)


## Clamp probability with custom range
static func clamp_probability_range(value: float, min_chance: float, max_chance: float) -> float:
	return clampf(value, min_chance, max_chance)


## Clamp flee chance (10% to 90%)
static func clamp_flee_chance(value: float) -> float:
	return clampf(value, 0.1, 0.9)


## Clamp hit chance (10% to 99%)
static func clamp_hit_chance(value: float) -> float:
	return clampf(value, 0.1, 0.99)


## Clamp instability (0% to 50%)
static func clamp_instability(value: float) -> float:
	return clampf(value, 0.0, 0.5)


## Clamp break chance (0% to 95%)
static func clamp_break_chance(value: float) -> float:
	return clampf(value, 0.0, 0.95)


# =============================================================================
# SAFE DIVISION (5+ duplicates)
# =============================================================================


## Safe division that returns default on divide by zero
static func safe_divide(numerator: float, denominator: float, default: float = 0.0) -> float:
	if denominator == 0.0:
		return default
	return numerator / denominator


## Safe integer division
static func safe_divide_int(numerator: int, denominator: int, default: int = 0) -> int:
	if denominator == 0:
		return default
	return numerator / denominator


## Safe modulo that returns 0 on divide by zero
static func safe_modulo(value: int, divisor: int) -> int:
	if divisor == 0:
		return 0
	return value % divisor


# =============================================================================
# DAMAGE VARIANCE (4+ duplicates)
# =============================================================================


## Apply standard damage variance (±10%)
static func apply_damage_variance(base_damage: float) -> float:
	var variance := randf_range(1.0 - Constants.DAMAGE_VARIANCE, 1.0 + Constants.DAMAGE_VARIANCE)
	return base_damage * variance


## Apply custom variance
static func apply_variance(base_value: float, variance_percent: float) -> float:
	var variance := randf_range(1.0 - variance_percent, 1.0 + variance_percent)
	return base_value * variance


## Apply healing variance (±5%)
static func apply_healing_variance(base_heal: float) -> float:
	var variance := randf_range(1.0 - Constants.HEALING_VARIANCE, 1.0 + Constants.HEALING_VARIANCE)
	return base_heal * variance


# =============================================================================
# LEVEL SCALING (6+ duplicates)
# =============================================================================


## Calculate level difference modifier (common for capture/purify)
static func get_level_modifier(source_level: int, target_level: int, scale: float = 0.02) -> float:
	return (source_level - target_level) * scale


## Apply level scaling to a value
static func apply_level_scale(base_value: float, level: int, scale: float = 0.02) -> float:
	return base_value * (1.0 + level * scale)


# =============================================================================
# STAT CALCULATIONS (8+ duplicates)
# =============================================================================


## Calculate stat multiplier from corruption state
static func get_corruption_stat_mult(corruption: float) -> float:
	if corruption <= Constants.CORRUPTION_ASCENDED_MAX:
		return Constants.STAT_MULT_ASCENDED
	elif corruption <= Constants.CORRUPTION_PURIFIED_MAX:
		return Constants.STAT_MULT_PURIFIED
	elif corruption <= Constants.CORRUPTION_UNSTABLE_MAX:
		return Constants.STAT_MULT_UNSTABLE
	elif corruption <= Constants.CORRUPTION_CORRUPTED_MAX:
		return Constants.STAT_MULT_CORRUPTED
	else:
		return Constants.STAT_MULT_ABYSSAL


## Get instability from corruption level
static func get_corruption_instability(corruption: float) -> float:
	if corruption <= Constants.CORRUPTION_ASCENDED_MAX:
		return Constants.INSTABILITY_ASCENDED
	elif corruption <= Constants.CORRUPTION_PURIFIED_MAX:
		return Constants.INSTABILITY_PURIFIED
	elif corruption <= Constants.CORRUPTION_UNSTABLE_MAX:
		return Constants.INSTABILITY_UNSTABLE
	elif corruption <= Constants.CORRUPTION_CORRUPTED_MAX:
		return Constants.INSTABILITY_CORRUPTED
	else:
		return Constants.INSTABILITY_ABYSSAL


## Calculate percentage value clamped 0-100
static func percent_clamped(value: float) -> float:
	return clampf(value, 0.0, 100.0)


## Normalize value to 0-1 range
static func normalize(value: float, min_val: float, max_val: float) -> float:
	if max_val <= min_val:
		return 0.0
	return clampf((value - min_val) / (max_val - min_val), 0.0, 1.0)


# =============================================================================
# RANDOM UTILITIES (15+ duplicates)
# =============================================================================


## Roll probability check (returns true if roll succeeds)
static func roll_chance(probability: float) -> bool:
	return randf() < probability


## Get random value in symmetric range (-amount to +amount)
static func random_symmetric(amount: float) -> float:
	return randf_range(-amount, amount)


## Get random Vector2 offset in symmetric range
static func random_offset(x_range: float, y_range: float) -> Vector2:
	return Vector2(randf_range(-x_range, x_range), randf_range(-y_range, y_range))


## Get shake offset (x symmetric, y half-symmetric for screen shake)
static func shake_offset(intensity: float) -> Vector2:
	return Vector2(
		randf_range(-intensity, intensity), randf_range(-intensity * 0.5, intensity * 0.5)
	)


# =============================================================================
# INTERPOLATION HELPERS
# =============================================================================


## Lerp with ease in/out (smooth step)
static func smooth_lerp(from: float, to: float, t: float) -> float:
	var smooth_t := t * t * (3.0 - 2.0 * t)
	return lerpf(from, to, smooth_t)


## Inverse lerp (get t value from result)
static func inverse_lerp(from: float, to: float, value: float) -> float:
	if to == from:
		return 0.0
	return (value - from) / (to - from)


## Remap value from one range to another
static func remap(
	value: float, from_min: float, from_max: float, to_min: float, to_max: float
) -> float:
	var t := inverse_lerp(from_min, from_max, value)
	return lerpf(to_min, to_max, t)


# =============================================================================
# COMBAT CALCULATIONS
# =============================================================================


## Calculate defense reduction
static func calculate_defense_reduction(
	defense: int, factor: float = Constants.DAMAGE_DEFENSE_FACTOR
) -> float:
	return defense * factor


## Calculate damage floor (minimum damage)
static func calculate_damage_floor(power: int) -> float:
	return power * Constants.DAMAGE_FLOOR_RATIO


## Calculate speed-based evasion bonus
static func get_speed_evasion_bonus(speed: int) -> float:
	return speed * Constants.EVASION_SPEED_FACTOR


## Calculate effective stat with multiplier
static func apply_stat_multiplier(base_stat: int, multiplier: float) -> int:
	return int(base_stat * multiplier)
