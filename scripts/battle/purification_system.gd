class_name PurificationSystem
extends Node
## PurificationSystem: Handles monster purification mechanics in battle.
##
## CORE PHILOSOPHY: Lower corruption = STRONGER monster.
## Goal is to guide monsters to ASCENSION (0-10% corruption) for +25% stats.
## This system handles in-battle corruption manipulation and purification attempts.

signal purification_started(monster: Monster, purifier: CharacterBase)
signal purification_progress(monster: Monster, progress: float)
signal purification_complete(monster: Monster, success: bool)
signal corruption_break(monster: Monster, stage: int)
signal corruption_state_changed(monster: Monster, old_state: int, new_state: int)

# =============================================================================
# PURIFICATION CONSTANTS
# =============================================================================

const BASE_PURIFICATION_POWER := 10.0
const CORRUPTION_RESISTANCE_FACTOR := 0.5
const HP_THRESHOLD_BONUS := 0.3  # Bonus when monster HP is low
const WEAKNESS_BONUS := 0.5  # Bonus when hitting elemental weakness

# Corruption break thresholds (corruption state transitions)
# These align with the CorruptionState enum thresholds
const CORRUPTION_BREAK_THRESHOLDS := [
	Constants.CORRUPTION_CORRUPTED_MAX,  # 75% - Corrupted to Unstable
	Constants.CORRUPTION_UNSTABLE_MAX,   # 50% - Unstable threshold
	Constants.CORRUPTION_PURIFIED_MAX,   # 25% - Unstable to Purified
	Constants.CORRUPTION_ASCENDED_MAX    # 10% - Purified to Ascended
]

# =============================================================================
# STATE
# =============================================================================

var active_purifications: Dictionary = {}  # monster_id -> purification_data

# =============================================================================
# PURIFICATION ATTEMPT
# =============================================================================

func attempt_purification(purifier: CharacterBase, monster: Monster, skill_id: String = "") -> Dictionary:
	## Attempt to purify a monster. Returns result dictionary.
	var result := {
		"success": false,
		"corruption_reduced": 0.0,
		"broke_corruption": false,
		"break_stage": 0,
		"fully_purified": false,
		"message": ""
	}

	# Check if monster can be purified
	if not monster.can_be_purified():
		result.message = "This monster cannot be purified!"
		return result

	# Calculate purification power
	var purification_power := calculate_purification_power(purifier, monster, skill_id)

	# Apply corruption reduction
	var old_corruption := monster.corruption_level
	monster.reduce_corruption(purification_power)
	var corruption_reduced := old_corruption - monster.corruption_level

	result.corruption_reduced = corruption_reduced
	result.success = corruption_reduced > 0

	# Check for corruption breaks
	var break_result := _check_corruption_breaks(monster, old_corruption)
	result.broke_corruption = break_result.broke
	result.break_stage = break_result.stage

	# Check for full purification
	if monster.is_purified():
		result.fully_purified = true
		result.message = "%s has been purified!" % monster.character_name
		purification_complete.emit(monster, true)
	elif result.broke_corruption:
		result.message = "Corruption barrier broken! Stage %d reached." % result.break_stage
		corruption_break.emit(monster, result.break_stage)
	else:
		result.message = "Purification reduced corruption by %.1f" % corruption_reduced

	purification_progress.emit(monster, monster.get_purification_progress())

	return result

func calculate_purification_power(purifier: CharacterBase, monster: Monster, skill_id: String = "") -> float:
	## Calculate how much corruption is reduced
	## Higher power = faster path to ASCENSION
	var power := BASE_PURIFICATION_POWER

	# Skill-based power (if using a purification skill)
	if skill_id != "":
		power = _get_skill_purification_power(skill_id)

	# Magic stat scaling
	var magic := purifier.get_stat(Enums.Stat.MAGIC)
	power *= (magic / 50.0) + 0.5

	# Level difference scaling
	var level_diff := purifier.level - monster.level
	var level_mod := clampf(1.0 + (level_diff * 0.05), 0.5, 2.0)
	power *= level_mod

	# Monster's corruption resistance
	var resistance := monster.corruption_resistance * CORRUPTION_RESISTANCE_FACTOR
	power *= (1.0 - resistance)

	# HP threshold bonus (low HP monsters are easier to purify)
	var hp_percent := monster.get_hp_percent()
	if hp_percent < 0.5:
		var bonus := (0.5 - hp_percent) * HP_THRESHOLD_BONUS * 2
		power *= (1.0 + bonus)

	# Brand bonuses - IRON brand has purification affinity
	if purifier is PlayerCharacter:
		var player := purifier as PlayerCharacter
		if player.current_brand == Enums.Brand.IRON:
			power *= 1.25  # Iron brand has purification bonus (protection/purity)
		elif player.current_brand == Enums.Brand.DREAD or player.current_brand == Enums.Brand.LEECH:
			power *= 0.75  # Dark brands have purification penalty

	# Brand alignment bonus (IRON alignment improves purification)
	if purifier is PlayerCharacter:
		var player := purifier as PlayerCharacter
		var iron_alignment := player.get_brand_alignment("IRON")
		if iron_alignment > 50:
			power *= 1.0 + ((iron_alignment - 50) / 100.0) * 0.3  # Up to 15% bonus

	return maxf(1.0, power)

func _get_skill_purification_power(skill_id: String) -> float:
	## Get base purification power from skill
	# TODO: Load from skill resource
	match skill_id:
		"purify_light":
			return 20.0
		"purify_radiance":
			return 35.0
		"purify_divine":
			return 50.0
		"purify_salvation":
			return 80.0
		_:
			return BASE_PURIFICATION_POWER

func _check_corruption_breaks(monster: Monster, old_corruption: float) -> Dictionary:
	## Check if purification crossed a corruption break threshold
	var max_corruption := maxf(monster.max_corruption, 1.0)
	var current := monster.corruption_level / max_corruption
	var old := old_corruption / max_corruption

	for i in range(CORRUPTION_BREAK_THRESHOLDS.size()):
		var threshold: float = CORRUPTION_BREAK_THRESHOLDS[i]
		if old > threshold and current <= threshold:
			return {"broke": true, "stage": i + 1}

	return {"broke": false, "stage": 0}

# =============================================================================
# CAPTURE MECHANICS
# =============================================================================

func can_capture(monster: Monster) -> bool:
	## Check if monster can be captured
	## NOTE: With the new Soulbind system, capture is handled by CaptureSystem
	## This method is kept for legacy/alternative capture paths
	if monster.is_boss():
		return false  # Bosses are NEVER capturable
	if not monster.is_alive():
		return false
	return true

func _can_capture_boss(_monster: Monster) -> bool:
	## Bosses cannot be captured - they drop Covenant Vessels instead
	return false

func calculate_capture_chance(purifier: CharacterBase, monster: Monster) -> float:
	## Calculate capture chance based on corruption state
	## NOTE: New system - lower corruption = easier capture (inverted from old)
	
	# Base chance from corruption state
	var base_chance := 0.5
	var corruption := monster.corruption_level
	
	# Lower corruption = higher chance (ASCENDED monsters are easiest)
	if corruption <= Constants.CORRUPTION_ASCENDED_MAX:
		base_chance = 0.90  # 90% at Ascended
	elif corruption <= Constants.CORRUPTION_PURIFIED_MAX:
		base_chance = 0.75  # 75% at Purified
	elif corruption <= Constants.CORRUPTION_UNSTABLE_MAX:
		base_chance = 0.50  # 50% at Unstable
	elif corruption <= Constants.CORRUPTION_CORRUPTED_MAX:
		base_chance = 0.30  # 30% at Corrupted
	else:
		base_chance = 0.15  # 15% at Abyssal

	# Level difference affects capture chance
	var level_diff := purifier.level - monster.level
	var level_mod := clampf(level_diff * 0.02, -0.20, 0.20)

	# Monster rarity affects difficulty
	var rarity_mod := 0.0
	match monster.rarity:
		Enums.Rarity.COMMON:
			rarity_mod = 0.10
		Enums.Rarity.UNCOMMON:
			rarity_mod = 0.05
		Enums.Rarity.RARE:
			rarity_mod = 0.0
		Enums.Rarity.EPIC:
			rarity_mod = -0.10
		Enums.Rarity.LEGENDARY:
			rarity_mod = -0.25

	# HP bonus - low HP = easier
	var hp_bonus := (1.0 - monster.get_hp_percent()) * 0.2

	return clampf(base_chance + level_mod + rarity_mod + hp_bonus, 0.05, 0.95)

func attempt_capture(purifier: CharacterBase, monster: Monster) -> Dictionary:
	## Legacy capture attempt - redirects to new system recommendation
	## For full capture, use CaptureSystem.attempt_capture()
	var result := {
		"success": false,
		"chance": 0.0,
		"message": "",
		"redirect_to_capture_system": true
	}

	if not can_capture(monster):
		result.message = "This monster cannot be captured!"
		return result

	result.message = "Use CaptureSystem for SOULBIND, PURIFY, DOMINATE, or BARGAIN capture."
	result.chance = calculate_capture_chance(purifier, monster)

	return result

func _on_capture_success(monster: Monster, method: Enums.CaptureMethod = Enums.CaptureMethod.SOULBIND) -> void:
	## Handle successful monster capture
	# Notify monster of capture
	if monster.has_method("on_captured"):
		monster.on_captured(method)
	
	# Add monster to party/storage
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("add_monster_to_collection"):
		game_manager.add_monster_to_collection(monster.monster_id, monster.level)

	EventBus.monster_captured.emit(monster.monster_id, monster.character_name)
	EventBus.monster_captured_method.emit(monster, method)

# =============================================================================
# CORRUPTION DAMAGE
# =============================================================================

func apply_corruption_damage(monster: Monster) -> float:
	## Apply end-of-turn corruption damage to monster (hurts itself when corrupted)
	if monster.corruption_level <= 0:
		return 0.0

	var corruption_percent := monster.corruption_level / maxf(monster.max_corruption, 1.0)

	# Higher corruption = more self-damage
	var damage_percent := corruption_percent * 0.05  # Up to 5% max HP per turn
	var damage := int(monster.get_max_hp() * damage_percent)

	# Don't kill from corruption damage alone
	damage = mini(damage, monster.current_hp - 1)

	if damage > 0:
		monster.take_damage(damage)

	return damage

func apply_corruption_heal(monster: Monster) -> float:
	## Apply healing when corruption is very low (purified monsters heal)
	if monster.corruption_level > monster.max_corruption * 0.25:
		return 0.0

	var heal_percent := 0.03  # 3% max HP heal per turn
	var heal := int(monster.get_max_hp() * heal_percent)

	monster.heal(heal)

	return heal

# =============================================================================
# VERA INTERACTION
# =============================================================================

func get_vera_purification_bonus() -> float:
	## Get purification bonus from VERA's current state
	## VERA secretly HATES purification (weakens her connection to fragments)
	var vera_system := get_node_or_null("/root/VERASystem")
	if vera_system == null:
		return 1.0
	
	var vera_state: int = vera_system.current_state if "current_state" in vera_system else 0

	match vera_state:
		Enums.VERAState.INTERFACE:
			return 1.5  # 50% bonus in interface mode (the helpful lie)
		Enums.VERAState.FRACTURE:
			return 1.0  # Normal (mask is slipping)
		Enums.VERAState.EMERGENCE:
			return 0.5  # Penalty (she's remembering)
		Enums.VERAState.APOTHEOSIS:
			return 0.0  # Cannot purify (VERATH is awake)

	return 1.0

func can_use_vera_purification() -> bool:
	## Check if VERA can assist with purification
	var vera_system := get_node_or_null("/root/VERASystem")
	if vera_system == null:
		return false
	
	var vera_state: int = vera_system.current_state if "current_state" in vera_system else 0
	return vera_state == Enums.VERAState.INTERFACE or vera_state == Enums.VERAState.FRACTURE

func vera_assist_purification(monster: Monster) -> Dictionary:
	## VERA assists with purification (special action)
	## Irony: She helps you purify, which weakens her hold on these fragments
	var result := {
		"success": false,
		"corruption_reduced": 0.0,
		"message": "",
		"vera_glitched": false
	}

	if not can_use_vera_purification():
		result.message = "VERA cannot assist right now..."
		return result

	var bonus := get_vera_purification_bonus()
	var power := BASE_PURIFICATION_POWER * 2.0 * bonus  # Double base power

	var old_corruption := monster.corruption_level
	monster.reduce_corruption(power)

	result.success = true
	result.corruption_reduced = old_corruption - monster.corruption_level
	result.message = "VERA's light purifies the corruption!"

	# Using VERA for purification affects Veil Integrity (she loses fragments)
	var vera_system := get_node_or_null("/root/VERASystem")
	if vera_system:
		if vera_system.has_method("add_veil_integrity"):
			vera_system.add_veil_integrity(2)  # Purification strengthens Veil
		
		# Chance for glitch when she helps purify (she hates it)
		if randf() < 0.2:
			result.vera_glitched = true
			if vera_system.has_method("trigger_dialogue"):
				vera_system.trigger_dialogue("purify_assist_glitch")

	return result

# =============================================================================
# QUERIES
# =============================================================================

func get_purification_effectiveness(purifier: CharacterBase, monster: Monster) -> String:
	## Get a text description of purification effectiveness
	var power := calculate_purification_power(purifier, monster)
	var turns_needed := ceili(monster.corruption_level / power)

	if turns_needed <= 1:
		return "Almost purified!"
	elif turns_needed <= 3:
		return "Very effective"
	elif turns_needed <= 5:
		return "Effective"
	elif turns_needed <= 8:
		return "Moderate"
	else:
		return "Difficult"

func get_capture_chance_text(chance: float) -> String:
	## Get text description of capture chance
	if chance >= 0.9:
		return "Almost certain"
	elif chance >= 0.7:
		return "Very likely"
	elif chance >= 0.5:
		return "Likely"
	elif chance >= 0.3:
		return "Possible"
	elif chance >= 0.1:
		return "Unlikely"
	else:
		return "Nearly impossible"

func estimate_purification_turns(purifier: CharacterBase, monster: Monster) -> int:
	## Estimate how many turns needed to fully purify
	var power := calculate_purification_power(purifier, monster)
	return ceili(monster.corruption_level / power)
