# =============================================================================
# VEILBREAKERS - SOULBIND CAPTURE SYSTEM (v5.2)
# Orchestrates monster capture via SOULBIND, PURIFY, DOMINATE, and BARGAIN
# =============================================================================
#
# CORE PHILOSOPHY: Corruption is the ENEMY. Goal is ASCENSION.
# - Lower corruption = stronger monster
# - PURIFY is the righteous path (reduces corruption)
# - DOMINATE is the dark path (works but causes Instability)
# - BARGAIN is the gambler's path (immediate random price)
# - SOULBIND is the standard path (item-based, no drawbacks)

class_name CaptureSystem
extends Node

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal capture_initiated(monster: Node, method: Enums.CaptureMethod)
signal capture_attempt_started(monster: Node, vessel_tier: Enums.SoulVesselTier, chance: float)
signal capture_succeeded(monster: Node, method: Enums.CaptureMethod, bonus_data: Dictionary)
signal capture_failed(monster: Node, method: Enums.CaptureMethod, reason: String)

signal corruption_battle_started(monster: Node, passes_needed: int)
signal corruption_battle_pass(monster: Node, current_pass: int, total_passes: int)
signal corruption_battle_ended(monster: Node, success: bool)

signal corruption_reduced(monster: Node, old_value: float, new_value: float)
signal purify_attempted(monster: Node, success: bool, corruption_reduced: float)
signal dominate_attempted(monster: Node, success: bool, hp_cost: int)
signal bargain_price_revealed(monster: Node, price: Dictionary)
signal bargain_accepted(monster: Node, price: Dictionary)
signal bargain_declined(monster: Node)

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
enum CaptureState {
	IDLE,
	SELECTING_METHOD,
	CORRUPTION_BATTLE,
	RESOLVING,
	BARGAIN_PROMPT
}

var current_state: CaptureState = CaptureState.IDLE
var active_monster: Node = null
var active_captor: Node = null
var active_method: Enums.CaptureMethod = Enums.CaptureMethod.SOULBIND
var active_vessel_tier: Enums.SoulVesselTier = Enums.SoulVesselTier.STANDARD

var current_capture_chance: float = 0.0
var current_pass: int = 0
var total_passes: int = 1

var pending_bargain_price: Dictionary = {}

# Cached autoload references
var _inventory_system: Node = null
var _vera_system: Node = null

# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------
func _ready() -> void:
	_inventory_system = get_node_or_null("/root/InventorySystem")
	_vera_system = get_node_or_null("/root/VERASystem")
	tree_exiting.connect(_on_tree_exiting)

func _on_tree_exiting() -> void:
	_reset_state()

func _safe_wait(duration: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(duration).timeout

# -----------------------------------------------------------------------------
# PUBLIC API - Check Capture Availability
# -----------------------------------------------------------------------------
func can_use_method(monster: Node, captor: Node, method: Enums.CaptureMethod) -> Dictionary:
	var result := {
		"available": false,
		"reason": "",
		"capture_chance": 0.0,
		"cost": {}
	}

	if monster == null or captor == null:
		result.reason = "Invalid target"
		return result

	# Bosses cannot be captured
	if monster.has_method("is_boss") and monster.is_boss():
		result.reason = "Bosses cannot be captured"
		return result

	var corruption: float = _get_corruption(monster)

	match method:
		Enums.CaptureMethod.SOULBIND:
			# Check if player has Soul Vessels
			var has_vessel := _has_soul_vessel()
			if not has_vessel:
				result.reason = "No Soul Vessels available"
				return result
			result.available = true
			result.capture_chance = calculate_soulbind_chance(monster, captor, active_vessel_tier)
			result.cost = {"item": _get_best_vessel_id(), "quantity": 1}

		Enums.CaptureMethod.PURIFY:
			# Check Sanctum Energy
			var energy_cost := _calculate_purify_energy_cost(corruption)
			var has_energy := _has_sanctum_energy(energy_cost)
			if not has_energy:
				result.reason = "Not enough Sanctum Energy (%d required)" % int(energy_cost)
				return result
			result.available = true
			result.capture_chance = calculate_purify_chance(monster, captor)
			result.cost = {"sanctum_energy": energy_cost}
			if corruption > 75:
				result.reason = "Warning: -30% chance at high corruption, costs double energy"

		Enums.CaptureMethod.DOMINATE:
			# Check corruption threshold
			if corruption < Constants.DOMINATE_MIN_CORRUPTION:
				result.reason = "DOMINATE requires corruption >= 26%"
				return result
			# Check HP cost
			var hp_cost := _calculate_dominate_hp_cost(captor)
			if captor.current_hp <= hp_cost:
				result.reason = "Not enough HP (would kill you)"
				return result
			result.available = true
			result.capture_chance = calculate_dominate_chance(monster, captor)
			result.cost = {"hp": hp_cost}
			result.reason = "Warning: Costs %d HP. Monster will have Instability." % hp_cost

		Enums.CaptureMethod.BARGAIN:
			result.available = true
			result.capture_chance = calculate_bargain_chance(monster, captor)
			result.cost = {"unknown": true}
			result.reason = "Price revealed before you decide. Always paid, success or fail."

	return result

func get_available_methods(monster: Node, captor: Node) -> Array[Enums.CaptureMethod]:
	var methods: Array[Enums.CaptureMethod] = []

	for method in [Enums.CaptureMethod.SOULBIND, Enums.CaptureMethod.PURIFY, 
				   Enums.CaptureMethod.DOMINATE, Enums.CaptureMethod.BARGAIN]:
		var check := can_use_method(monster, captor, method)
		if check.available:
			methods.append(method)

	return methods

# -----------------------------------------------------------------------------
# PUBLIC API - Execute Capture
# -----------------------------------------------------------------------------
func attempt_capture(monster: Node, captor: Node, method: Enums.CaptureMethod, 
					 vessel_tier: Enums.SoulVesselTier = Enums.SoulVesselTier.STANDARD) -> void:
	if current_state != CaptureState.IDLE:
		push_warning("Capture already in progress")
		return

	if not is_instance_valid(monster):
		push_error("CaptureSystem: Invalid monster node")
		capture_failed.emit(null, method, "Invalid target")
		return

	if not is_instance_valid(captor):
		push_error("CaptureSystem: Invalid captor node")
		capture_failed.emit(monster, method, "Invalid captor")
		return

	active_monster = monster
	active_captor = captor
	active_method = method
	active_vessel_tier = vessel_tier

	capture_initiated.emit(monster, method)
	
	# Notify VERA system about capture method (affects Veil Integrity)
	_notify_vera_capture_attempt(method)

	match method:
		Enums.CaptureMethod.SOULBIND:
			await _execute_soulbind()
		Enums.CaptureMethod.PURIFY:
			await _execute_purify()
		Enums.CaptureMethod.DOMINATE:
			await _execute_dominate()
		Enums.CaptureMethod.BARGAIN:
			await _execute_bargain()

# -----------------------------------------------------------------------------
# CAPTURE METHOD: SOULBIND (Item-Based)
# -----------------------------------------------------------------------------
func _execute_soulbind() -> void:
	current_state = CaptureState.CORRUPTION_BATTLE

	if not is_instance_valid(active_monster) or not is_instance_valid(active_captor):
		_handle_capture_failure("Target lost")
		_reset_state()
		return

	# Calculate capture chance
	current_capture_chance = calculate_soulbind_chance(active_monster, active_captor, active_vessel_tier)
	capture_attempt_started.emit(active_monster, active_vessel_tier, current_capture_chance)

	# Consume Soul Vessel
	_consume_soul_vessel(active_vessel_tier)

	# Corruption Battle animation
	var success: bool = await _corruption_battle_sequence()

	if not is_instance_valid(active_monster):
		_reset_state()
		return

	if success:
		_handle_capture_success({
			"method": "soulbind",
			"vessel_tier": active_vessel_tier
		})
	else:
		_handle_capture_failure("The corruption held strong!")

	_reset_state()

func calculate_soulbind_chance(monster: Node, captor: Node, vessel_tier: Enums.SoulVesselTier) -> float:
	# Base chance from rarity
	var base := _get_base_capture_chance(monster)
	
	# HP modifier: +0.5% per 1% HP missing (max +40%)
	var hp_percent := _get_hp_percent(monster)
	var hp_bonus := minf((1.0 - hp_percent) * Constants.CAPTURE_HP_BONUS_PER_MISSING * 100, 
						  Constants.CAPTURE_HP_BONUS_MAX)
	
	# Soul Vessel bonus
	var vessel_bonus := 0.0
	match vessel_tier:
		Enums.SoulVesselTier.CRACKED:
			vessel_bonus = Constants.SOUL_VESSEL_CRACKED_BONUS
		Enums.SoulVesselTier.STANDARD:
			vessel_bonus = Constants.SOUL_VESSEL_STANDARD_BONUS
		Enums.SoulVesselTier.PRISTINE:
			vessel_bonus = Constants.SOUL_VESSEL_PRISTINE_BONUS
		Enums.SoulVesselTier.COVENANT:
			vessel_bonus = Constants.SOUL_VESSEL_COVENANT_BONUS
	
	# Level difference modifier
	var level_mod := _calculate_level_modifier(monster, captor)
	
	return clampf(base + hp_bonus + vessel_bonus + level_mod, 0.05, 0.95)

# -----------------------------------------------------------------------------
# CAPTURE METHOD: PURIFY (Sanctum Energy Cost)
# -----------------------------------------------------------------------------
func _execute_purify() -> void:
	current_state = CaptureState.CORRUPTION_BATTLE

	if not is_instance_valid(active_monster) or not is_instance_valid(active_captor):
		_handle_capture_failure("Target lost")
		_reset_state()
		return

	var corruption := _get_corruption(active_monster)
	var energy_cost := _calculate_purify_energy_cost(corruption)
	
	# Consume Sanctum Energy
	_consume_sanctum_energy(energy_cost)

	# Calculate capture chance
	current_capture_chance = calculate_purify_chance(active_monster, active_captor)
	capture_attempt_started.emit(active_monster, Enums.SoulVesselTier.STANDARD, current_capture_chance)

	# PURIFY always reduces corruption, even on fail
	var old_corruption := corruption
	if active_monster.has_method("reduce_corruption"):
		active_monster.reduce_corruption(Constants.PURIFY_CORRUPTION_REDUCTION_ON_FAIL)
	var new_corruption := _get_corruption(active_monster)
	corruption_reduced.emit(active_monster, old_corruption, new_corruption)

	# Corruption Battle (PURIFY gets -1 pass)
	var success: bool = await _corruption_battle_sequence()

	if not is_instance_valid(active_monster):
		_reset_state()
		return

	purify_attempted.emit(active_monster, success, old_corruption - new_corruption)

	if success:
		_handle_capture_success({
			"method": "purify",
			"corruption_reduced": old_corruption - new_corruption,
			"joins_purified": true
		})
	else:
		_handle_capture_failure("Purification incomplete, but corruption weakened!")

	_reset_state()

func calculate_purify_chance(monster: Node, captor: Node) -> float:
	var base := _get_base_capture_chance(monster)
	var corruption := _get_corruption(monster)
	
	# HP modifier
	var hp_percent := _get_hp_percent(monster)
	var hp_bonus := minf((1.0 - hp_percent) * Constants.CAPTURE_HP_BONUS_PER_MISSING * 100, 
						  Constants.CAPTURE_HP_BONUS_MAX)
	
	# Corruption modifier
	var corruption_mod := 0.0
	if corruption < 25:
		corruption_mod = Constants.PURIFY_LOW_CORRUPTION_BONUS
	elif corruption > 75:
		corruption_mod = -Constants.PURIFY_HIGH_CORRUPTION_PENALTY
	
	# Level difference
	var level_mod := _calculate_level_modifier(monster, captor)
	
	return clampf(base + hp_bonus + corruption_mod + level_mod, 0.05, 0.95)

func _calculate_purify_energy_cost(corruption: float) -> float:
	var cost := Constants.PURIFY_ENERGY_BASE + (corruption * Constants.PURIFY_ENERGY_CORRUPTION_MULT)
	# Double cost at high corruption
	if corruption > 75:
		cost *= 2.0
	return cost

# -----------------------------------------------------------------------------
# CAPTURE METHOD: DOMINATE (HP Cost)
# -----------------------------------------------------------------------------
func _execute_dominate() -> void:
	current_state = CaptureState.CORRUPTION_BATTLE

	if not is_instance_valid(active_monster) or not is_instance_valid(active_captor):
		_handle_capture_failure("Target lost")
		_reset_state()
		return

	var corruption := _get_corruption(active_monster)
	
	# Check corruption threshold
	if corruption < Constants.DOMINATE_MIN_CORRUPTION:
		_handle_capture_failure("Target's corruption is too low for DOMINATE")
		_reset_state()
		return

	# Pay HP cost
	var hp_cost := _calculate_dominate_hp_cost(active_captor)
	active_captor.take_damage(hp_cost)
	
	# Calculate capture chance
	current_capture_chance = calculate_dominate_chance(active_monster, active_captor)
	capture_attempt_started.emit(active_monster, Enums.SoulVesselTier.STANDARD, current_capture_chance)

	# Corruption Battle
	var success: bool = await _corruption_battle_sequence()

	if not is_instance_valid(active_monster):
		_reset_state()
		return

	dominate_attempted.emit(active_monster, success, hp_cost)

	if success:
		# Monster gains corruption from DOMINATE
		if active_monster.has_method("add_corruption"):
			active_monster.add_corruption(Constants.DOMINATE_FAIL_CORRUPTION_GAIN)
		
		_handle_capture_success({
			"method": "dominate",
			"hp_cost": hp_cost,
			"has_instability": true,
			"instability_amount": 0.20 if corruption > 75 else 0.10
		})
	else:
		# On fail, monster gets enraged
		if active_monster.has_method("add_corruption"):
			active_monster.add_corruption(Constants.DOMINATE_FAIL_CORRUPTION_GAIN)
		_handle_capture_failure("The creature resisted your will! It's enraged!")
		# TODO: Apply Defiant buff to monster

	_reset_state()

func calculate_dominate_chance(monster: Node, captor: Node) -> float:
	var base := _get_base_capture_chance(monster)
	var corruption := _get_corruption(monster)
	
	# HP modifier
	var hp_percent := _get_hp_percent(monster)
	var hp_bonus := minf((1.0 - hp_percent) * Constants.CAPTURE_HP_BONUS_PER_MISSING * 100, 
						  Constants.CAPTURE_HP_BONUS_MAX)
	
	# DOMINATE bonus at high corruption
	var corruption_mod := 0.0
	if corruption > 75:
		corruption_mod = Constants.DOMINATE_HIGH_CORRUPTION_BONUS
	
	# Level difference
	var level_mod := _calculate_level_modifier(monster, captor)
	
	return clampf(base + hp_bonus + corruption_mod + level_mod, 0.05, 0.95)

func _calculate_dominate_hp_cost(captor: Node) -> int:
	return int(captor.current_hp * Constants.DOMINATE_HP_COST_PERCENT)

# -----------------------------------------------------------------------------
# CAPTURE METHOD: BARGAIN (Immediate Price)
# -----------------------------------------------------------------------------
func _execute_bargain() -> void:
	current_state = CaptureState.BARGAIN_PROMPT

	if not is_instance_valid(active_monster) or not is_instance_valid(active_captor):
		_handle_capture_failure("Target lost")
		_reset_state()
		return

	# Roll the price
	pending_bargain_price = _roll_bargain_price()
	bargain_price_revealed.emit(active_monster, pending_bargain_price)
	
	# Wait for player decision (in real implementation, this would be async UI)
	# For now, auto-accept after a delay
	await _safe_wait(0.5)
	
	# Assume accepted - in real game, this comes from UI
	await _bargain_accepted()

func _bargain_accepted() -> void:
	if not is_instance_valid(active_monster):
		_reset_state()
		return

	current_state = CaptureState.CORRUPTION_BATTLE
	
	# Pay price immediately
	_apply_bargain_price(pending_bargain_price)
	bargain_accepted.emit(active_monster, pending_bargain_price)

	# Calculate capture chance (BARGAIN gets +25% bonus)
	current_capture_chance = calculate_bargain_chance(active_monster, active_captor)
	capture_attempt_started.emit(active_monster, Enums.SoulVesselTier.STANDARD, current_capture_chance)

	# Corruption Battle
	var success: bool = await _corruption_battle_sequence()

	if not is_instance_valid(active_monster):
		_reset_state()
		return

	if success:
		_handle_capture_success({
			"method": "bargain",
			"price_paid": pending_bargain_price,
			"willing": true
		})
	else:
		_handle_capture_failure("The bargain was struck, but the creature broke free!")

	_reset_state()

func bargain_declined() -> void:
	## Called when player declines bargain
	bargain_declined.emit(active_monster)
	_reset_state()

func calculate_bargain_chance(monster: Node, captor: Node) -> float:
	var base := _get_base_capture_chance(monster)
	
	# HP modifier
	var hp_percent := _get_hp_percent(monster)
	var hp_bonus := minf((1.0 - hp_percent) * Constants.CAPTURE_HP_BONUS_PER_MISSING * 100, 
						  Constants.CAPTURE_HP_BONUS_MAX)
	
	# BARGAIN always gets +25% bonus
	var bargain_bonus := Constants.BARGAIN_CAPTURE_BONUS
	
	# Level difference
	var level_mod := _calculate_level_modifier(monster, captor)
	
	return clampf(base + hp_bonus + bargain_bonus + level_mod, 0.10, 0.95)

func _roll_bargain_price() -> Dictionary:
	## Roll d20 for bargain price
	var roll := randi_range(1, 20)
	
	match roll:
		1, 2, 3, 4, 5:
			return {
				"type": "blood_tithe",
				"description": "Blood Tithe: -15% max HP until next Shrine rest",
				"effect": {"stat": "max_hp", "modifier": -0.15, "duration": "shrine"}
			}
		6, 7, 8:
			return {
				"type": "soul_fragment",
				"description": "Soul Fragment: One party member can't use ultimate this battle",
				"effect": {"disable_ultimate": true, "duration": "battle"}
			}
		9, 10, 11:
			return {
				"type": "whispered_secret",
				"description": "Whispered Secret: Vera learns something...",
				"effect": {"vera_learns": true, "affects_ending": true}
			}
		12, 13, 14:
			return {
				"type": "echoed_pain",
				"description": "Echoed Pain: Monster's abilities cost double for 3 battles",
				"effect": {"ability_cost_mult": 2.0, "duration_battles": 3}
			}
		15, 16, 17:
			return {
				"type": "borrowed_time",
				"description": "Borrowed Time: Monster starts battles with random debuff",
				"effect": {"battle_start_debuff": true, "permanent": true}
			}
		18, 19:
			return {
				"type": "watchers_interest",
				"description": "The Watcher's Interest: Next boss has +10% stats",
				"effect": {"next_boss_buff": 0.10}
			}
		20:
			return {
				"type": "true_name_given",
				"description": "True Name Given: Perfect loyalty, but Vera becomes unstable...",
				"effect": {"perfect_loyalty": true, "vera_unstable": true}
			}
	
	return {"type": "unknown", "description": "Unknown price", "effect": {}}

func _apply_bargain_price(price: Dictionary) -> void:
	## Apply the bargain price effect
	var effect: Dictionary = price.get("effect", {})
	
	match price.get("type", ""):
		"blood_tithe":
			# Reduce max HP by 15% until shrine rest
			if active_captor.has_method("add_stat_modifier"):
				var hp_reduction := int(active_captor.get_max_hp() * 0.15)
				active_captor.add_stat_modifier(Enums.Stat.MAX_HP, -hp_reduction, 999, "blood_tithe")
		
		"whispered_secret":
			# Vera learns something (affects Veil Integrity)
			if _vera_system and _vera_system.has_method("add_veil_integrity"):
				_vera_system.add_veil_integrity(-5)
		
		"true_name_given":
			# Perfect loyalty but Vera destabilizes
			if _vera_system and _vera_system.has_method("add_corruption"):
				_vera_system.add_corruption("bargain_true_name")
	
	# Store price on monster for tracking
	if active_monster.has_method("set_meta"):
		active_monster.set_meta("bargain_price", price)

# -----------------------------------------------------------------------------
# CORRUPTION BATTLE SEQUENCE
# -----------------------------------------------------------------------------
func _corruption_battle_sequence() -> bool:
	## Animated corruption battle - tug-of-war between corruption and freedom
	if not is_instance_valid(active_monster):
		return false

	# Calculate passes needed
	total_passes = _calculate_passes_needed()
	current_pass = 0
	
	corruption_battle_started.emit(active_monster, total_passes)
	
	# Each pass is a chance to succeed
	for i in range(total_passes):
		current_pass = i + 1
		
		if not is_instance_valid(active_monster):
			return false
		
		corruption_battle_pass.emit(active_monster, current_pass, total_passes)
		
		# Animation delay per pass
		var pass_time := _get_pass_time()
		await _safe_wait(pass_time)
		
		# Early escape check (weighted toward later passes)
		var escape_chance := (1.0 - current_capture_chance) * (float(i) / float(total_passes)) * 0.3
		if randf() < escape_chance and i < total_passes - 1:
			corruption_battle_ended.emit(active_monster, false)
			return false
	
	# Final roll
	var success := randf() < current_capture_chance
	corruption_battle_ended.emit(active_monster, success)
	
	await _safe_wait(0.3)
	return success

func _calculate_passes_needed() -> int:
	if not is_instance_valid(active_monster):
		return 1
	
	var rarity: int = active_monster.rarity if "rarity" in active_monster else 0
	var base_passes := 1
	
	match rarity:
		Enums.Rarity.COMMON:
			base_passes = Constants.CAPTURE_PASSES_COMMON
		Enums.Rarity.UNCOMMON:
			base_passes = Constants.CAPTURE_PASSES_UNCOMMON
		Enums.Rarity.RARE:
			base_passes = Constants.CAPTURE_PASSES_RARE
		Enums.Rarity.EPIC:
			base_passes = Constants.CAPTURE_PASSES_EPIC
		Enums.Rarity.LEGENDARY:
			base_passes = Constants.CAPTURE_PASSES_LEGENDARY
	
	# Reductions
	var reductions := 0
	
	# Low HP reduction
	if _get_hp_percent(active_monster) < 0.25:
		reductions += Constants.CAPTURE_PASS_REDUCTION_LOW_HP
	
	# Low corruption reduction
	if _get_corruption(active_monster) < 25:
		reductions += Constants.CAPTURE_PASS_REDUCTION_LOW_CORRUPTION
	
	# PURIFY method reduction
	if active_method == Enums.CaptureMethod.PURIFY:
		reductions += Constants.CAPTURE_PASS_REDUCTION_PURIFY
	
	# Soul Vessel reductions
	match active_vessel_tier:
		Enums.SoulVesselTier.PRISTINE:
			reductions += Constants.CAPTURE_PASS_REDUCTION_PRISTINE
		Enums.SoulVesselTier.COVENANT:
			reductions += Constants.CAPTURE_PASS_REDUCTION_COVENANT
	
	return maxi(1, base_passes - reductions)

func _get_pass_time() -> float:
	if not is_instance_valid(active_monster):
		return Constants.CAPTURE_PASS_TIME_SHORT
	
	var rarity: int = active_monster.rarity if "rarity" in active_monster else 0
	
	match rarity:
		Enums.Rarity.COMMON, Enums.Rarity.UNCOMMON:
			return Constants.CAPTURE_PASS_TIME_SHORT
		Enums.Rarity.RARE, Enums.Rarity.EPIC:
			return Constants.CAPTURE_PASS_TIME_MEDIUM
		Enums.Rarity.LEGENDARY:
			return Constants.CAPTURE_PASS_TIME_LONG
	
	return Constants.CAPTURE_PASS_TIME_SHORT

# -----------------------------------------------------------------------------
# CAPTURE RESULT HANDLERS
# -----------------------------------------------------------------------------
func _handle_capture_success(bonus_data: Dictionary) -> void:
	if not is_instance_valid(active_monster):
		return
	
	# Notify monster of capture
	if active_monster.has_method("on_captured"):
		active_monster.on_captured(active_method)
	
	capture_succeeded.emit(active_monster, active_method, bonus_data)
	
	# Notify VERA of capture success
	_notify_vera_capture_success(active_method)

func _handle_capture_failure(reason: String) -> void:
	if is_instance_valid(active_monster):
		# Small corruption reduction on failed capture (creature is weakened)
		if active_monster.has_method("reduce_corruption"):
			active_monster.reduce_corruption(2.0)
		capture_failed.emit(active_monster, active_method, reason)
	else:
		capture_failed.emit(null, active_method, reason)

# -----------------------------------------------------------------------------
# VERA INTEGRATION
# -----------------------------------------------------------------------------
func _notify_vera_capture_attempt(method: Enums.CaptureMethod) -> void:
	if _vera_system == null:
		return
	
	# Different methods affect Veil Integrity differently
	match method:
		Enums.CaptureMethod.DOMINATE:
			if _vera_system.has_method("add_veil_integrity"):
				_vera_system.add_veil_integrity(-3)
		Enums.CaptureMethod.BARGAIN:
			if _vera_system.has_method("add_veil_integrity"):
				_vera_system.add_veil_integrity(-5)
		Enums.CaptureMethod.PURIFY:
			if _vera_system.has_method("add_veil_integrity"):
				_vera_system.add_veil_integrity(1)

func _notify_vera_capture_success(method: Enums.CaptureMethod) -> void:
	if _vera_system == null:
		return
	
	# Trigger Vera dialogue based on method
	if _vera_system.has_method("trigger_dialogue"):
		match method:
			Enums.CaptureMethod.SOULBIND:
				_vera_system.trigger_dialogue("capture_soulbind")
			Enums.CaptureMethod.PURIFY:
				_vera_system.trigger_dialogue("capture_purify")
			Enums.CaptureMethod.DOMINATE:
				_vera_system.trigger_dialogue("capture_dominate")
			Enums.CaptureMethod.BARGAIN:
				_vera_system.trigger_dialogue("capture_bargain")

# -----------------------------------------------------------------------------
# HELPER METHODS
# -----------------------------------------------------------------------------
func _get_base_capture_chance(monster: Node) -> float:
	var rarity: int = monster.rarity if "rarity" in monster else 0
	
	match rarity:
		Enums.Rarity.COMMON:
			return Constants.CAPTURE_BASE_COMMON
		Enums.Rarity.UNCOMMON:
			return Constants.CAPTURE_BASE_UNCOMMON
		Enums.Rarity.RARE:
			return Constants.CAPTURE_BASE_RARE
		Enums.Rarity.EPIC:
			return Constants.CAPTURE_BASE_EPIC
		Enums.Rarity.LEGENDARY:
			return Constants.CAPTURE_BASE_LEGENDARY
	
	return Constants.CAPTURE_BASE_COMMON

func _calculate_level_modifier(monster: Node, captor: Node) -> float:
	var monster_level: int = monster.level if "level" in monster else 1
	var captor_level: int = captor.level if "level" in captor else 1
	var level_diff: int = captor_level - monster_level
	
	# +/- 2% per level difference, capped at +/-20%
	return clampf(level_diff * 0.02, -0.20, 0.20)

func _get_hp_percent(monster: Node) -> float:
	if monster.has_method("get_hp_percent"):
		return monster.get_hp_percent()
	elif "current_hp" in monster and "max_hp" in monster:
		if monster.max_hp > 0:
			return float(monster.current_hp) / float(monster.max_hp)
	return 1.0

func _get_corruption(monster: Node) -> float:
	if "corruption_level" in monster:
		return monster.corruption_level
	elif monster.has_method("get_corruption"):
		return monster.get_corruption()
	return 50.0

func _has_soul_vessel() -> bool:
	if _inventory_system == null:
		return true  # Assume yes if no inventory system
	
	var vessel_ids := ["soul_vessel_cracked", "soul_vessel_standard", 
					   "soul_vessel_pristine", "soul_vessel_covenant"]
	
	for vessel_id in vessel_ids:
		if _inventory_system.has_method("has_item") and _inventory_system.has_item(vessel_id):
			return true
	
	return true  # Default to true for testing

func _get_best_vessel_id() -> String:
	# Return the best available vessel
	if _inventory_system == null:
		return "soul_vessel_standard"
	
	var vessels := [
		["soul_vessel_covenant", Enums.SoulVesselTier.COVENANT],
		["soul_vessel_pristine", Enums.SoulVesselTier.PRISTINE],
		["soul_vessel_standard", Enums.SoulVesselTier.STANDARD],
		["soul_vessel_cracked", Enums.SoulVesselTier.CRACKED]
	]
	
	for vessel in vessels:
		if _inventory_system.has_method("has_item") and _inventory_system.has_item(vessel[0]):
			active_vessel_tier = vessel[1]
			return vessel[0]
	
	return "soul_vessel_standard"

func _consume_soul_vessel(tier: Enums.SoulVesselTier) -> void:
	var vessel_id := "soul_vessel_standard"
	match tier:
		Enums.SoulVesselTier.CRACKED:
			vessel_id = "soul_vessel_cracked"
		Enums.SoulVesselTier.STANDARD:
			vessel_id = "soul_vessel_standard"
		Enums.SoulVesselTier.PRISTINE:
			vessel_id = "soul_vessel_pristine"
		Enums.SoulVesselTier.COVENANT:
			vessel_id = "soul_vessel_covenant"
	
	if _inventory_system and _inventory_system.has_method("remove_item"):
		_inventory_system.remove_item(vessel_id, 1)

func _has_sanctum_energy(amount: float) -> bool:
	# Check GameManager for Sanctum Energy
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager and "sanctum_energy" in game_manager:
		return game_manager.sanctum_energy >= amount
	return true  # Default to true for testing

func _consume_sanctum_energy(amount: float) -> void:
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager and "sanctum_energy" in game_manager:
		game_manager.sanctum_energy -= amount

func _reset_state() -> void:
	current_state = CaptureState.IDLE
	active_monster = null
	active_captor = null
	current_capture_chance = 0.0
	current_pass = 0
	total_passes = 1
	pending_bargain_price = {}

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

func get_method_description(method: Enums.CaptureMethod) -> String:
	match method:
		Enums.CaptureMethod.SOULBIND:
			return "Standard capture using a Soul Vessel. No drawbacks."
		Enums.CaptureMethod.PURIFY:
			return "Costs Sanctum Energy. Best for low corruption. Always reduces corruption."
		Enums.CaptureMethod.DOMINATE:
			return "Costs 25% HP. Best for high corruption. Monster gains Instability."
		Enums.CaptureMethod.BARGAIN:
			return "Pay a random price (revealed first). +25% capture chance."
	return "Unknown capture method."

func get_vessel_tier_name(tier: Enums.SoulVesselTier) -> String:
	match tier:
		Enums.SoulVesselTier.CRACKED:
			return "Cracked Soul Vessel"
		Enums.SoulVesselTier.STANDARD:
			return "Soul Vessel"
		Enums.SoulVesselTier.PRISTINE:
			return "Pristine Soul Vessel"
		Enums.SoulVesselTier.COVENANT:
			return "Covenant Vessel"
	return "Unknown Vessel"

func get_method_name(method: Enums.CaptureMethod) -> String:
	match method:
		Enums.CaptureMethod.SOULBIND:
			return "SOULBIND"
		Enums.CaptureMethod.PURIFY:
			return "PURIFY"
		Enums.CaptureMethod.DOMINATE:
			return "DOMINATE"
		Enums.CaptureMethod.BARGAIN:
			return "BARGAIN"
	return "UNKNOWN"
