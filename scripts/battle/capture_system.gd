# =============================================================================
# VEILBREAKERS - UNIFIED CAPTURE SYSTEM
# Orchestrates monster capture via PURIFY, BARGAIN, FORCE, and ORB methods
# =============================================================================

class_name CaptureSystem
extends Node

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal capture_initiated(monster: Node, method: int)
signal capture_attempt_started(monster: Node, orb_tier: int, chance: float)
signal capture_succeeded(monster: Node, method: int, bonus_data: Dictionary)
signal capture_failed(monster: Node, method: int, reason: String)
signal capture_escaped(monster: Node, shake_number: int)

signal corruption_reduced(monster: Node, old_value: float, new_value: float)
signal purify_attempted(monster: Node, success: bool, amount: float)
signal bargain_attempted(monster: Node, success: bool)
signal force_attempted(monster: Node, success: bool)

signal shake_progress(monster: Node, current_shake: int, total_shakes: int)

# -----------------------------------------------------------------------------
# ENUMS
# -----------------------------------------------------------------------------
enum CaptureMethod {
	ORB,      # Direct orb throw - primary capture method
	PURIFY,   # Reduce corruption to improve capture odds
	BARGAIN,  # RNG chance-based - "I give my word"
	FORCE     # Only for lower level monsters, applies debuff
}

enum OrbTier {
	BASIC,     # 5-25% capture rate
	GREATER,   # 15-40% capture rate
	MASTER,    # 50-70% base, level-scaled (buyable + craftable)
	LEGENDARY  # 80% flat rate on ALL monsters (chest drop or crafted)
}

enum CaptureState {
	IDLE,
	SELECTING_METHOD,
	PURIFYING,
	BARGAINING,
	FORCING,
	THROWING_ORB,
	SHAKING,
	RESOLVING
}

# -----------------------------------------------------------------------------
# CONSTANTS - ORB CAPTURE RATES
# -----------------------------------------------------------------------------
# These are INITIAL rates (if thrown at battle start, full HP, full corruption)

const BASIC_ORB_MIN_RATE: float = 0.05      # 5%
const BASIC_ORB_MAX_RATE: float = 0.25      # 25%

const GREATER_ORB_MIN_RATE: float = 0.15    # 15%
const GREATER_ORB_MAX_RATE: float = 0.40    # 40%

const MASTER_ORB_BASE_RATE: float = 0.50    # 50% within 5 levels
const MASTER_ORB_LOW_LEVEL_RATE: float = 0.70  # 70% if monster 5+ levels lower
const MASTER_ORB_LEVEL_PENALTY: float = 0.05   # -5% per level above threshold

# Level thresholds
const MASTER_ORB_LEVEL_THRESHOLD: int = 5   # Within 5 levels = base rate

# LEGENDARY ORB - Ultimate tier
const LEGENDARY_ORB_RATE: float = 0.80      # 80% flat rate on ALL monsters

# -----------------------------------------------------------------------------
# CONSTANTS - CORRUPTION & PURIFICATION
# -----------------------------------------------------------------------------
const BASE_CORRUPTION: float = 80.0         # All monsters start at 80%+
const CORRUPTION_CAP: float = 100.0

# Purification effectiveness scaling (early = bad, late = good)
const PURIFY_EARLY_SUCCESS_RATE: float = 0.20   # 20% success at battle start
const PURIFY_LATE_SUCCESS_RATE: float = 0.80    # 80% success at peak conditions
const PURIFY_BASE_AMOUNT: float = 5.0           # Base corruption reduction
const PURIFY_BONUS_LOW_HP: float = 10.0         # Extra reduction at low HP

# Corruption drop rate modifiers (lower = drops slower)
const CORRUPTION_DROP_COMMON: float = 1.0
const CORRUPTION_DROP_UNCOMMON: float = 0.85
const CORRUPTION_DROP_RARE: float = 0.70
const CORRUPTION_DROP_EPIC: float = 0.55
const CORRUPTION_DROP_LEGENDARY: float = 0.40

# -----------------------------------------------------------------------------
# CONSTANTS - BARGAIN
# -----------------------------------------------------------------------------
const BARGAIN_MIN_RATE: float = 0.10        # 10% at battle start
const BARGAIN_MAX_RATE: float = 0.20        # 20% at peak conditions

# -----------------------------------------------------------------------------
# CONSTANTS - FORCE
# -----------------------------------------------------------------------------
const FORCE_CAPTURE_RATE: float = 0.60      # 60% capture rate
const FORCE_HP_THRESHOLD: float = 0.45      # Monster HP must be < 45%
const FORCE_DEBUFF_PURIFY_GOAL: float = 0.15  # 15% purification to clear debuff

# Force debuff - limits monster but not crippling
const FORCE_DEBUFF_STAT_REDUCTION: float = 0.15  # -15% to one random stat

# -----------------------------------------------------------------------------
# CONSTANTS - CAPTURE SCALING FACTORS
# -----------------------------------------------------------------------------
# How much each factor influences capture rate
const HP_INFLUENCE_WEIGHT: float = 0.30     # 30% of scaling from HP
const CORRUPTION_INFLUENCE_WEIGHT: float = 0.40  # 40% from corruption
const LEVEL_INFLUENCE_WEIGHT: float = 0.30  # 30% from level difference

# HP thresholds for bonus capture chance
const LOW_HP_THRESHOLD: float = 0.50        # Below 50% HP
const VERY_LOW_HP_THRESHOLD: float = 0.25   # Below 25% HP
const CRITICAL_HP_THRESHOLD: float = 0.10   # Below 10% HP

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
var current_state: CaptureState = CaptureState.IDLE
var active_monster: Node = null
var active_captor: Node = null
var active_method: CaptureMethod = CaptureMethod.ORB
var active_orb_tier: OrbTier = OrbTier.BASIC

var battle_progress: float = 0.0  # 0.0 = battle start, 1.0 = peak conditions
var current_capture_chance: float = 0.0
var shake_count: int = 0
var max_shakes: int = 3

# References
var bargain_system: Node = null

# -----------------------------------------------------------------------------
# INITIALIZATION
# -----------------------------------------------------------------------------
func _ready() -> void:
	_find_bargain_system()

func _find_bargain_system() -> void:
	# Find existing BargainSystem
	bargain_system = get_node_or_null("../animation/BargainSystem")
	if bargain_system == null:
		bargain_system = get_node_or_null("BargainSystem")

# -----------------------------------------------------------------------------
# PUBLIC API - Check Capture Availability
# -----------------------------------------------------------------------------
func can_use_method(monster: Node, captor: Node, method: CaptureMethod) -> Dictionary:
	var result := {
		"available": false,
		"reason": "",
		"capture_chance": 0.0
	}

	if monster == null or captor == null:
		result.reason = "Invalid target"
		return result

	match method:
		CaptureMethod.ORB:
			result.available = true
			result.capture_chance = calculate_orb_capture_chance(monster, captor, active_orb_tier)

		CaptureMethod.PURIFY:
			result.available = true
			result.capture_chance = calculate_purify_success_rate(monster)
			result.reason = "Reduces corruption. More effective as battle progresses."

		CaptureMethod.BARGAIN:
			result.available = true
			result.capture_chance = calculate_bargain_rate(monster)
			result.reason = "RNG-based. Good for rare/high-level monsters."

		CaptureMethod.FORCE:
			var monster_level: int = monster.level if "level" in monster else 1
			var captor_level: int = captor.level if "level" in captor else 1
			var monster_hp_percent: float = _get_hp_percent(monster)

			if monster_level >= captor_level:
				result.reason = "Monster must be lower level than hero"
			elif monster_hp_percent >= FORCE_HP_THRESHOLD:
				result.reason = "Monster HP must be below 45%"
			else:
				result.available = true
				result.capture_chance = FORCE_CAPTURE_RATE
				result.reason = "Warning: Captured monster will have a debuff"

	return result

func get_available_methods(monster: Node, captor: Node) -> Array[CaptureMethod]:
	var methods: Array[CaptureMethod] = []

	for method in CaptureMethod.values():
		var check := can_use_method(monster, captor, method)
		if check.available:
			methods.append(method)

	return methods

# -----------------------------------------------------------------------------
# PUBLIC API - Execute Capture
# -----------------------------------------------------------------------------
func attempt_capture(monster: Node, captor: Node, method: CaptureMethod, orb_tier: OrbTier = OrbTier.BASIC) -> void:
	if current_state != CaptureState.IDLE:
		push_warning("Capture already in progress")
		return

	active_monster = monster
	active_captor = captor
	active_method = method
	active_orb_tier = orb_tier

	capture_initiated.emit(monster, method)

	match method:
		CaptureMethod.ORB:
			await _execute_orb_capture()
		CaptureMethod.PURIFY:
			await _execute_purify()
		CaptureMethod.BARGAIN:
			await _execute_bargain()
		CaptureMethod.FORCE:
			await _execute_force()

# -----------------------------------------------------------------------------
# CAPTURE METHOD: ORB
# -----------------------------------------------------------------------------
func _execute_orb_capture() -> void:
	current_state = CaptureState.THROWING_ORB

	# Calculate capture chance
	current_capture_chance = calculate_orb_capture_chance(active_monster, active_captor, active_orb_tier)
	capture_attempt_started.emit(active_monster, active_orb_tier, current_capture_chance)

	# Consume orb
	_consume_orb(active_orb_tier)

	# Throw animation delay
	await get_tree().create_timer(0.5).timeout

	# Shake sequence
	current_state = CaptureState.SHAKING
	var success := await _shake_sequence()

	# Result
	current_state = CaptureState.RESOLVING
	await get_tree().create_timer(0.3).timeout

	if success:
		_handle_capture_success({})
	else:
		_handle_capture_failure("Monster broke free!")

	_reset_state()

func calculate_orb_capture_chance(monster: Node, captor: Node, orb_tier: OrbTier) -> float:
	# Check for boss (monster_tier BOSS+ or rarity LEGENDARY+ = uncapturable)
	var tier: int = monster.monster_tier if "monster_tier" in monster else 0
	var rarity: int = monster.rarity if "rarity" in monster else 0
	if tier >= 3 or rarity >= 4:  # BOSS tier or LEGENDARY rarity
		return 0.0  # Bosses cannot be captured

	var min_rate: float
	var max_rate: float

	match orb_tier:
		OrbTier.BASIC:
			min_rate = BASIC_ORB_MIN_RATE
			max_rate = BASIC_ORB_MAX_RATE
		OrbTier.GREATER:
			min_rate = GREATER_ORB_MIN_RATE
			max_rate = GREATER_ORB_MAX_RATE
		OrbTier.MASTER:
			return _calculate_master_orb_rate(monster, captor)
		OrbTier.LEGENDARY:
			return LEGENDARY_ORB_RATE  # 80% flat - no conditions

	# Calculate scaling factor (0.0 = worst conditions, 1.0 = best)
	var scaling := _calculate_capture_scaling(monster, captor)

	# Interpolate between min and max based on scaling
	return lerpf(min_rate, max_rate, scaling)

func _calculate_master_orb_rate(monster: Node, captor: Node) -> float:
	var monster_level: int = monster.level if "level" in monster else 1
	var captor_level: int = captor.level if "level" in captor else 1
	var level_diff: int = monster_level - captor_level

	var base_rate: float

	if level_diff <= -MASTER_ORB_LEVEL_THRESHOLD:
		# Monster is 5+ levels LOWER - 70% rate
		base_rate = MASTER_ORB_LOW_LEVEL_RATE
	elif level_diff <= MASTER_ORB_LEVEL_THRESHOLD:
		# Within 5 levels - 50% rate
		base_rate = MASTER_ORB_BASE_RATE
	else:
		# Monster is higher level - apply penalty
		var levels_over := level_diff - MASTER_ORB_LEVEL_THRESHOLD
		base_rate = MASTER_ORB_BASE_RATE - (levels_over * MASTER_ORB_LEVEL_PENALTY)

	# Master orb also scales with battle conditions
	var scaling := _calculate_capture_scaling(monster, captor)
	var scaling_bonus := scaling * 0.15  # Up to +15% from conditions

	return clampf(base_rate + scaling_bonus, 0.10, 0.85)

func _calculate_capture_scaling(monster: Node, captor: Node) -> float:
	# Returns 0.0 (worst) to 1.0 (best conditions)
	var hp_factor := _calculate_hp_factor(monster)
	var corruption_factor := _calculate_corruption_factor(monster)
	var level_factor := _calculate_level_factor(monster, captor)

	return (hp_factor * HP_INFLUENCE_WEIGHT +
			corruption_factor * CORRUPTION_INFLUENCE_WEIGHT +
			level_factor * LEVEL_INFLUENCE_WEIGHT)

func _calculate_hp_factor(monster: Node) -> float:
	var hp_percent := _get_hp_percent(monster)

	if hp_percent <= CRITICAL_HP_THRESHOLD:
		return 1.0  # Maximum bonus
	elif hp_percent <= VERY_LOW_HP_THRESHOLD:
		return 0.8
	elif hp_percent <= LOW_HP_THRESHOLD:
		return 0.5
	else:
		return hp_percent  # Linear scaling above 50%

func _calculate_corruption_factor(monster: Node) -> float:
	var corruption := _get_corruption(monster)
	# Lower corruption = higher factor (better capture)
	# 80% corruption = 0.2 factor, 0% corruption = 1.0 factor
	return 1.0 - (corruption / CORRUPTION_CAP)

func _calculate_level_factor(monster: Node, captor: Node) -> float:
	var monster_level: int = monster.level if "level" in monster else 1
	var captor_level: int = captor.level if "level" in captor else 1
	var level_diff: int = monster_level - captor_level

	if level_diff <= -5:
		return 1.0  # Much lower level = easy
	elif level_diff <= 0:
		return 0.8  # Lower level
	elif level_diff <= 5:
		return 0.5  # Within 5 levels
	else:
		# Higher level monster = harder
		return maxf(0.1, 0.5 - (level_diff - 5) * 0.05)

# -----------------------------------------------------------------------------
# CAPTURE METHOD: PURIFY
# -----------------------------------------------------------------------------
func _execute_purify() -> void:
	current_state = CaptureState.PURIFYING

	var success_rate := calculate_purify_success_rate(active_monster)
	var success := randf() < success_rate

	if success:
		var amount := calculate_purify_amount(active_monster)
		var old_corruption := _get_corruption(active_monster)

		_reduce_corruption(active_monster, amount)

		var new_corruption := _get_corruption(active_monster)
		corruption_reduced.emit(active_monster, old_corruption, new_corruption)
		purify_attempted.emit(active_monster, true, amount)
	else:
		purify_attempted.emit(active_monster, false, 0.0)

	await get_tree().create_timer(0.8).timeout
	_reset_state()

func calculate_purify_success_rate(monster: Node) -> float:
	# Starts low, increases as battle progresses
	var hp_factor := 1.0 - _get_hp_percent(monster)  # Lower HP = higher success
	var corruption_factor := 1.0 - (_get_corruption(monster) / CORRUPTION_CAP)

	# Combined "battle progress" factor
	var progress := (hp_factor + corruption_factor) / 2.0

	return lerpf(PURIFY_EARLY_SUCCESS_RATE, PURIFY_LATE_SUCCESS_RATE, progress)

func calculate_purify_amount(monster: Node) -> float:
	var base := PURIFY_BASE_AMOUNT
	var hp_percent := _get_hp_percent(monster)

	# Bonus at low HP
	if hp_percent < LOW_HP_THRESHOLD:
		base += PURIFY_BONUS_LOW_HP * (1.0 - hp_percent / LOW_HP_THRESHOLD)

	# Apply rarity modifier (rarer = less reduction)
	var rarity_mod := _get_corruption_drop_modifier(monster)

	return base * rarity_mod

func _get_corruption_drop_modifier(monster: Node) -> float:
	var rarity: int = monster.rarity if "rarity" in monster else 0

	match rarity:
		0: return CORRUPTION_DROP_COMMON
		1: return CORRUPTION_DROP_UNCOMMON
		2: return CORRUPTION_DROP_RARE
		3: return CORRUPTION_DROP_EPIC
		4: return CORRUPTION_DROP_LEGENDARY

	return CORRUPTION_DROP_COMMON

# -----------------------------------------------------------------------------
# CAPTURE METHOD: BARGAIN
# -----------------------------------------------------------------------------
func _execute_bargain() -> void:
	current_state = CaptureState.BARGAINING

	var success_rate := calculate_bargain_rate(active_monster)
	var success := randf() < success_rate

	bargain_attempted.emit(active_monster, success)

	if success:
		# Bargain success = immediate capture
		await get_tree().create_timer(1.0).timeout
		_handle_capture_success({"method": "bargain", "willing": true})
	else:
		await get_tree().create_timer(0.8).timeout
		capture_failed.emit(active_monster, CaptureMethod.BARGAIN, "The creature refused your bargain.")

	_reset_state()

func calculate_bargain_rate(monster: Node, captor: Node = null) -> float:
	# 10% at battle start, up to 20% at peak conditions
	var effective_captor = captor if captor else active_captor
	if effective_captor == null:
		return BARGAIN_MIN_RATE  # Return minimum if no captor available
	var scaling := _calculate_capture_scaling(monster, effective_captor)
	return lerpf(BARGAIN_MIN_RATE, BARGAIN_MAX_RATE, scaling)

# -----------------------------------------------------------------------------
# CAPTURE METHOD: FORCE
# -----------------------------------------------------------------------------
func _execute_force() -> void:
	current_state = CaptureState.FORCING

	var check := can_use_method(active_monster, active_captor, CaptureMethod.FORCE)
	if not check.available:
		capture_failed.emit(active_monster, CaptureMethod.FORCE, check.reason)
		_reset_state()
		return

	var success := randf() < FORCE_CAPTURE_RATE

	force_attempted.emit(active_monster, success)

	if success:
		await get_tree().create_timer(0.5).timeout
		_handle_capture_success({
			"method": "force",
			"has_debuff": true,
			"debuff_purify_goal": FORCE_DEBUFF_PURIFY_GOAL,
			"debuff_stat_reduction": FORCE_DEBUFF_STAT_REDUCTION
		})
	else:
		await get_tree().create_timer(0.5).timeout
		capture_failed.emit(active_monster, CaptureMethod.FORCE, "Monster resisted the forced capture!")

	_reset_state()

# -----------------------------------------------------------------------------
# SHAKE SEQUENCE
# -----------------------------------------------------------------------------
func _shake_sequence() -> bool:
	max_shakes = _get_shake_count()

	for i in range(max_shakes):
		shake_count = i + 1
		shake_progress.emit(active_monster, shake_count, max_shakes)

		await get_tree().create_timer(0.6).timeout

		# Check for escape (weighted towards later shakes)
		var escape_check := (1.0 - current_capture_chance) * (float(i + 1) / max_shakes)
		if randf() < escape_check * 0.3 and i < max_shakes - 1:
			capture_escaped.emit(active_monster, shake_count)
			return false

	# Final roll
	return randf() < current_capture_chance

func _get_shake_count() -> int:
	var rarity: int = active_monster.rarity if "rarity" in active_monster else 0
	match rarity:
		0: return 2  # Common
		1: return 3  # Uncommon
		2: return 3  # Rare
		3: return 4  # Epic
		4: return 5  # Legendary
	return 3

# -----------------------------------------------------------------------------
# CAPTURE RESULT HANDLERS
# -----------------------------------------------------------------------------
func _handle_capture_success(bonus_data: Dictionary) -> void:
	# Apply force debuff if applicable
	if bonus_data.get("has_debuff", false):
		_apply_force_debuff(active_monster, bonus_data)

	capture_succeeded.emit(active_monster, active_method, bonus_data)

func _handle_capture_failure(reason: String) -> void:
	# Small corruption reduction on failed capture
	_reduce_corruption(active_monster, 2.0)
	capture_failed.emit(active_monster, active_method, reason)

func _apply_force_debuff(monster: Node, data: Dictionary) -> void:
	# Store debuff info on monster
	if monster.has_method("set_meta"):
		monster.set_meta("force_capture_debuff", {
			"active": true,
			"stat_reduction": data.get("debuff_stat_reduction", FORCE_DEBUFF_STAT_REDUCTION),
			"purify_goal": data.get("debuff_purify_goal", FORCE_DEBUFF_PURIFY_GOAL),
			"purify_progress": 0.0
		})

# -----------------------------------------------------------------------------
# HELPER METHODS
# -----------------------------------------------------------------------------
func _get_hp_percent(monster: Node) -> float:
	if monster.has_method("get_hp_percent"):
		return monster.get_hp_percent()
	elif "current_hp" in monster and "max_hp" in monster:
		if monster.max_hp > 0:
			return float(monster.current_hp) / float(monster.max_hp)
		return 1.0
	return 1.0

func _get_corruption(monster: Node) -> float:
	if "corruption_level" in monster:
		return monster.corruption_level
	elif monster.has_method("get_corruption"):
		return monster.get_corruption()
	return BASE_CORRUPTION

func _reduce_corruption(monster: Node, amount: float) -> void:
	if monster.has_method("reduce_corruption"):
		monster.reduce_corruption(amount)
	elif "corruption_level" in monster:
		monster.corruption_level = maxf(0.0, monster.corruption_level - amount)

func _consume_orb(tier: OrbTier) -> void:
	var orb_id: String
	match tier:
		OrbTier.BASIC: orb_id = "capture_orb"
		OrbTier.GREATER: orb_id = "greater_capture_orb"
		OrbTier.MASTER: orb_id = "master_capture_orb"
		OrbTier.LEGENDARY: orb_id = "legendary_capture_orb"

	# Remove from inventory (autoload access in Godot 4.x)
	var inv = get_node_or_null("/root/InventorySystem")
	if inv and inv.has_method("remove_item"):
		inv.remove_item(orb_id, 1)

func _reset_state() -> void:
	current_state = CaptureState.IDLE
	active_monster = null
	active_captor = null
	current_capture_chance = 0.0
	shake_count = 0

# -----------------------------------------------------------------------------
# UI HELPER METHODS
# -----------------------------------------------------------------------------
func get_capture_chance_text(chance: float) -> String:
	if chance >= 0.70:
		return "Very High"
	elif chance >= 0.50:
		return "High"
	elif chance >= 0.30:
		return "Moderate"
	elif chance >= 0.15:
		return "Low"
	else:
		return "Very Low"

func get_method_description(method: CaptureMethod) -> String:
	match method:
		CaptureMethod.ORB:
			return "Throw a capture orb. Success varies by orb type and conditions."
		CaptureMethod.PURIFY:
			return "Attempt to reduce corruption. More effective as battle progresses."
		CaptureMethod.BARGAIN:
			return "Make a deal with the creature. Low chance but works on any monster."
		CaptureMethod.FORCE:
			return "Force capture on weakened, lower-level monsters. Applies a temporary debuff."
	return ""

func get_orb_tier_name(tier: OrbTier) -> String:
	match tier:
		OrbTier.BASIC: return "Capture Orb"
		OrbTier.GREATER: return "Greater Capture Orb"
		OrbTier.MASTER: return "Master Capture Orb"
		OrbTier.LEGENDARY: return "Legendary Capture Orb"
	return "Unknown Orb"
