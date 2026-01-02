class_name AIController
extends Node
## AIController: Controls enemy AI decision-making in battle.
## Enhanced with brand effectiveness targeting and smart attack rules.
##
## TARGETING RULES:
## - Basic attacks can ONLY target party monsters (not player character)
## - Skills, debuffs, and area attacks CAN target player character
## - Player character only targetable with basic attacks when ALL party monsters are dead
## - AI prioritizes targets with brand weakness and low HP

# =============================================================================
# CONSTANTS
# =============================================================================

## Weight multipliers for target selection
const BRAND_ADVANTAGE_WEIGHT := 40.0  # High priority for brand advantage
const LOW_HP_WEIGHT := 30.0           # Priority for finishing off low HP targets
const THREAT_WEIGHT := 20.0           # Priority for high-threat targets
const RANDOM_WEIGHT := 10.0           # Small random factor for unpredictability

# =============================================================================
# REFERENCES
# =============================================================================

var damage_calculator: DamageCalculator = null

func _ready() -> void:
	# Get damage calculator reference for brand effectiveness
	damage_calculator = DamageCalculator.new()
	add_child(damage_calculator)

# =============================================================================
# AI DECISION MAKING
# =============================================================================

func get_action(character: CharacterBase, allies: Array, enemies: Array) -> Dictionary:
	if character is Monster:
		var monster: Monster = character as Monster
		return _get_monster_action(monster, allies, enemies)

	# Default AI for non-monster enemies
	return _default_ai(character, allies, enemies)

func _get_monster_action(monster: Monster, allies: Array, enemies: Array) -> Dictionary:
	## Enhanced monster AI with brand-aware targeting
	
	# Check instability first (from Monster class)
	if monster.check_instability():
		return monster.get_instability_action(allies, enemies)
	
	# Get valid targets based on action type
	var basic_attack_targets := _get_valid_basic_attack_targets(enemies)
	var skill_targets := _get_valid_skill_targets(enemies)
	
	# If no valid targets at all, defend
	if basic_attack_targets.is_empty() and skill_targets.is_empty():
		return {"action": Enums.BattleAction.DEFEND, "target": monster, "skill": ""}
	
	# Decide action based on AI pattern
	match monster.ai_pattern:
		"aggressive":
			return _ai_aggressive(monster, allies, enemies, basic_attack_targets, skill_targets)
		"defensive":
			return _ai_defensive(monster, allies, enemies, basic_attack_targets, skill_targets)
		"support":
			return _ai_support(monster, allies, enemies, basic_attack_targets, skill_targets)
		"boss":
			return _ai_boss(monster, allies, enemies, basic_attack_targets, skill_targets)
		_:
			return _ai_random(monster, basic_attack_targets)

func _default_ai(character: CharacterBase, _allies: Array, enemies: Array) -> Dictionary:
	var valid_targets := _get_valid_basic_attack_targets(enemies)

	if valid_targets.is_empty():
		return {"action": Enums.BattleAction.DEFEND, "target": null, "skill": ""}

	# Simple AI: attack optimal target based on brand and HP
	var target := _select_optimal_target(character, valid_targets, false)

	return {
		"action": Enums.BattleAction.ATTACK,
		"target": target,
		"skill": ""
	}

# =============================================================================
# TARGET FILTERING (Targeting Rules)
# =============================================================================

func _get_valid_basic_attack_targets(enemies: Array) -> Array[CharacterBase]:
	## Basic attacks can ONLY target monsters, not the player character
	## Exception: Player is targetable when ALL party monsters are dead
	var valid_targets: Array[CharacterBase] = []
	var player_character: CharacterBase = null
	var has_alive_monsters := false
	
	for enemy in enemies:
		if not enemy is CharacterBase:
			continue
		if not enemy.is_alive():
			continue
		
		# Check if this is the player character (protagonist)
		if enemy.is_protagonist or enemy.character_type == Enums.CharacterType.PLAYER:
			player_character = enemy
		else:
			# It's a monster ally - valid target for basic attacks
			valid_targets.append(enemy)
			has_alive_monsters = true
	
	# If no alive monsters, player becomes targetable
	if not has_alive_monsters and player_character != null:
		valid_targets.append(player_character)
	
	return valid_targets

func _get_valid_skill_targets(enemies: Array) -> Array[CharacterBase]:
	## Skills can target anyone (including player character)
	var valid_targets: Array[CharacterBase] = []
	
	for enemy in enemies:
		if enemy is CharacterBase and enemy.is_alive():
			valid_targets.append(enemy)
	
	return valid_targets

# =============================================================================
# SMART TARGET SELECTION
# =============================================================================

func _select_optimal_target(attacker: CharacterBase, targets: Array[CharacterBase], is_skill: bool) -> CharacterBase:
	## Select the best target based on brand effectiveness, HP, and threat
	if targets.is_empty():
		return null
	
	if targets.size() == 1:
		return targets[0]
	
	var best_target: CharacterBase = targets[0]
	var best_score := -999.0
	
	for target in targets:
		var score := _calculate_target_score(attacker, target, is_skill)
		if score > best_score:
			best_score = score
			best_target = target
	
	return best_target

func _calculate_target_score(attacker: CharacterBase, target: CharacterBase, _is_skill: bool) -> float:
	## Calculate a score for how good this target is
	var score := 0.0
	
	# 1. Brand effectiveness bonus (highest priority)
	var brand_mult := _get_brand_effectiveness(attacker.brand, target.brand)
	if brand_mult >= Constants.BRAND_STRONG:
		score += BRAND_ADVANTAGE_WEIGHT * 1.5  # Super effective
	elif brand_mult > 1.0:
		score += BRAND_ADVANTAGE_WEIGHT
	elif brand_mult <= Constants.BRAND_WEAK:
		score -= BRAND_ADVANTAGE_WEIGHT  # Avoid resistant targets
	
	# 2. Low HP bonus (finish off weak targets)
	var hp_percent := target.get_hp_percent()
	if hp_percent < 0.25:
		score += LOW_HP_WEIGHT * 2.0  # Very low HP - high priority
	elif hp_percent < 0.5:
		score += LOW_HP_WEIGHT
	elif hp_percent < 0.75:
		score += LOW_HP_WEIGHT * 0.5
	
	# 3. Threat assessment (target dangerous enemies)
	var threat := _calculate_threat(target)
	score += (threat / 100.0) * THREAT_WEIGHT
	
	# 4. Small random factor for unpredictability
	score += randf() * RANDOM_WEIGHT
	
	# 5. Penalty for targeting player character (prefer monsters)
	if target.is_protagonist or target.character_type == Enums.CharacterType.PLAYER:
		score -= 15.0  # Slight preference for monster targets
	
	return score

func _get_brand_effectiveness(attacker_brand: Enums.Brand, defender_brand: Enums.Brand) -> float:
	## Get brand effectiveness multiplier
	if damage_calculator:
		return damage_calculator.get_brand_effectiveness(attacker_brand, defender_brand)
	
	# Fallback: manual calculation if no damage calculator
	if attacker_brand == Enums.Brand.NONE or defender_brand == Enums.Brand.NONE:
		return 1.0
	
	# Brand wheel: SAVAGE > IRON > VENOM > SURGE > DREAD > LEECH > SAVAGE
	var effectiveness_map := {
		Enums.Brand.SAVAGE: Enums.Brand.IRON,
		Enums.Brand.IRON: Enums.Brand.VENOM,
		Enums.Brand.VENOM: Enums.Brand.SURGE,
		Enums.Brand.SURGE: Enums.Brand.DREAD,
		Enums.Brand.DREAD: Enums.Brand.LEECH,
		Enums.Brand.LEECH: Enums.Brand.SAVAGE,
	}
	
	# Get primary brand for hybrids
	var attacker_primary := _get_primary_brand(attacker_brand)
	var defender_primary := _get_primary_brand(defender_brand)
	
	if effectiveness_map.has(attacker_primary):
		if effectiveness_map[attacker_primary] == defender_primary:
			return Constants.BRAND_STRONG  # 1.5x
	
	# Check reverse (weakness)
	if effectiveness_map.has(defender_primary):
		if effectiveness_map[defender_primary] == attacker_primary:
			return Constants.BRAND_WEAK  # 0.75x
	
	return 1.0

func _get_primary_brand(brand: Enums.Brand) -> Enums.Brand:
	## Get the primary brand for hybrid brands
	match brand:
		Enums.Brand.BLOODIRON:
			return Enums.Brand.SAVAGE
		Enums.Brand.CORROSIVE:
			return Enums.Brand.IRON
		Enums.Brand.VENOMSTRIKE:
			return Enums.Brand.VENOM
		Enums.Brand.TERRORFLUX:
			return Enums.Brand.SURGE
		Enums.Brand.NIGHTLEECH:
			return Enums.Brand.DREAD
		Enums.Brand.RAVENOUS:
			return Enums.Brand.LEECH
		_:
			return brand

func _calculate_threat(target: CharacterBase) -> float:
	## Calculate threat score based on attack power and role
	var threat := 0.0

	# Attack stat contributes to threat
	threat += target.get_stat(Enums.Stat.ATTACK) * 2.0

	# Magic stat for casters
	threat += target.get_stat(Enums.Stat.MAGIC) * 1.5

	# Speed makes targets more dangerous
	threat += target.get_stat(Enums.Stat.SPEED) * 0.5

	# Low HP targets are less threatening (but may be worth finishing)
	var hp_percent := target.get_hp_percent()
	threat *= (0.5 + hp_percent * 0.5)

	return threat

# =============================================================================
# AI PATTERNS
# =============================================================================

func _ai_aggressive(monster: Monster, _allies: Array, _enemies: Array, 
		basic_targets: Array[CharacterBase], skill_targets: Array[CharacterBase]) -> Dictionary:
	## Aggressive AI: Prioritize damage, use skills often
	
	# Try to use a skill if available (every 2+ turns)
	if monster.turns_since_last_skill >= 2 and not monster.known_skills.is_empty():
		var skill_result := _try_use_skill(monster, skill_targets)
		if skill_result.skill != "":
			monster.turns_since_last_skill = 0
			return skill_result
	
	# Basic attack with smart targeting
	if basic_targets.is_empty():
		return {"action": Enums.BattleAction.DEFEND, "target": monster, "skill": ""}
	
	var target := _select_optimal_target(monster, basic_targets, false)
	monster.turns_since_last_skill += 1
	
	return {
		"action": Enums.BattleAction.ATTACK,
		"target": target,
		"skill": ""
	}

func _ai_defensive(monster: Monster, allies: Array, _enemies: Array,
		basic_targets: Array[CharacterBase], skill_targets: Array[CharacterBase]) -> Dictionary:
	## Defensive AI: Defend when low HP, heal allies
	
	# Defend if HP < 30%
	if monster.get_hp_percent() < 0.3:
		return {"action": Enums.BattleAction.DEFEND, "target": monster, "skill": ""}
	
	# Try to heal allies if any are low
	for ally in allies:
		if ally is CharacterBase and ally.is_alive() and ally.get_hp_percent() < 0.5:
			# Check for healing skill
			for skill_id in monster.known_skills:
				if skill_id.contains("heal") or skill_id.contains("restore"):
					if monster.can_use_skill(skill_id):
						return {
							"action": Enums.BattleAction.SKILL,
							"target": ally,
							"skill": skill_id
						}
	
	# Otherwise attack
	return _ai_aggressive(monster, allies, _enemies, basic_targets, skill_targets)

func _ai_support(monster: Monster, allies: Array, _enemies: Array,
		basic_targets: Array[CharacterBase], skill_targets: Array[CharacterBase]) -> Dictionary:
	## Support AI: Prioritize healing and buffs
	
	# Find lowest HP ally
	var lowest_ally: CharacterBase = null
	var lowest_percent := 1.0

	for ally in allies:
		if ally is CharacterBase and ally.is_alive():
			var hp_percent: float = ally.get_hp_percent()
			if hp_percent < lowest_percent:
				lowest_percent = hp_percent
				lowest_ally = ally

	# Heal if any ally below 50%
	if lowest_ally and lowest_percent < 0.5:
		for skill_id in monster.known_skills:
			if skill_id.contains("heal") or skill_id.contains("siphon") or skill_id.contains("restore"):
				if monster.can_use_skill(skill_id):
					return {
						"action": Enums.BattleAction.SKILL,
						"target": lowest_ally,
						"skill": skill_id
					}
	
	# Try buff skills
	for skill_id in monster.known_skills:
		if skill_id.contains("buff") or skill_id.contains("shield") or skill_id.contains("protect"):
			if monster.can_use_skill(skill_id):
				var buff_target: CharacterBase = allies[randi() % allies.size()] if not allies.is_empty() else monster
				return {
					"action": Enums.BattleAction.SKILL,
					"target": buff_target,
					"skill": skill_id
				}
	
	# Fallback to aggressive
	return _ai_aggressive(monster, allies, _enemies, basic_targets, skill_targets)

func _ai_boss(monster: Monster, allies: Array, _enemies: Array,
		basic_targets: Array[CharacterBase], skill_targets: Array[CharacterBase]) -> Dictionary:
	## Boss AI: Use skills frequently, phase-based behavior
	
	var hp_percent := monster.get_hp_percent()
	
	# Phase 3: Enraged (< 25% HP) - spam skills
	if hp_percent < 0.25:
		if not monster.known_skills.is_empty() and randf() > 0.2:
			var skill_result := _try_use_skill(monster, skill_targets)
			if skill_result.skill != "":
				return skill_result
	
	# Phase 2: Desperate (< 50% HP) - more skills
	elif hp_percent < 0.5:
		if not monster.known_skills.is_empty() and randf() > 0.4:
			var skill_result := _try_use_skill(monster, skill_targets)
			if skill_result.skill != "":
				return skill_result
	
	# Phase 1: Normal - occasional skills
	else:
		if not monster.known_skills.is_empty() and randf() > 0.6:
			var skill_result := _try_use_skill(monster, skill_targets)
			if skill_result.skill != "":
				return skill_result
	
	# Basic attack with smart targeting
	return _ai_aggressive(monster, allies, _enemies, basic_targets, skill_targets)

func _ai_random(monster: Monster, basic_targets: Array[CharacterBase]) -> Dictionary:
	## Random AI: Unpredictable behavior
	var actions := [Enums.BattleAction.ATTACK, Enums.BattleAction.DEFEND]
	var action: Enums.BattleAction = actions[randi() % actions.size()]

	var target: CharacterBase = null
	if action == Enums.BattleAction.ATTACK and not basic_targets.is_empty():
		target = basic_targets[randi() % basic_targets.size()]

	return {"action": action, "target": target, "skill": ""}

# =============================================================================
# SKILL SELECTION
# =============================================================================

func _try_use_skill(monster: Monster, targets: Array[CharacterBase]) -> Dictionary:
	## Try to use a skill, returns empty skill if none available
	if monster.known_skills.is_empty() or targets.is_empty():
		return {"action": Enums.BattleAction.SKILL, "target": null, "skill": ""}
	
	# Weight skills based on monster's skill_weights
	var available_skills: Array[String] = []
	var skill_weights: Array[float] = []
	var total_weight := 0.0
	
	for skill_id in monster.known_skills:
		if monster.can_use_skill(skill_id):
			available_skills.append(skill_id)
			var weight: float = monster.skill_weights.get(skill_id, 25.0)
			skill_weights.append(weight)
			total_weight += weight
	
	if available_skills.is_empty():
		return {"action": Enums.BattleAction.SKILL, "target": null, "skill": ""}
	
	# Weighted random selection
	var roll := randf() * total_weight
	var cumulative := 0.0
	var selected_skill := available_skills[0]
	
	for i in range(available_skills.size()):
		cumulative += skill_weights[i]
		if roll <= cumulative:
			selected_skill = available_skills[i]
			break
	
	# Select optimal target for skill
	var target := _select_optimal_target(monster, targets, true)
	
	return {
		"action": Enums.BattleAction.SKILL,
		"target": target,
		"skill": selected_skill
	}

# =============================================================================
# LEGACY TARGET SELECTION (for compatibility)
# =============================================================================

func _select_target_by_hp(targets: Array[CharacterBase], lowest: bool = true) -> CharacterBase:
	if targets.is_empty():
		return null

	var selected := targets[0]
	for target in targets:
		if lowest:
			if target.current_hp < selected.current_hp:
				selected = target
		else:
			if target.current_hp > selected.current_hp:
				selected = target

	return selected

func _select_random_target(targets: Array[CharacterBase]) -> CharacterBase:
	if targets.is_empty():
		return null
	return targets[randi() % targets.size()]

# =============================================================================
# BEHAVIOR HELPERS
# =============================================================================

func get_behavior_for_hp_phase(character: CharacterBase) -> String:
	## Returns behavior pattern based on HP percentage
	var hp_percent := character.get_hp_percent()

	if hp_percent > 0.75:
		return "normal"
	elif hp_percent > 0.5:
		return "cautious"
	elif hp_percent > 0.25:
		return "desperate"
	else:
		return "enraged"

func should_use_item(character: CharacterBase) -> bool:
	## Determine if AI should use a healing item
	var hp_percent := character.get_hp_percent()
	return hp_percent < 0.3 and randf() > 0.5

func should_defend(character: CharacterBase) -> bool:
	## Determine if AI should defend
	var hp_percent := character.get_hp_percent()
	return hp_percent < 0.2 and randf() > 0.7

func should_flee(character: CharacterBase, _enemies: Array) -> bool:
	## Determine if AI should attempt to flee (for non-boss enemies)
	if character is Monster and character.is_boss():
		return false

	var hp_percent := character.get_hp_percent()

	# Flee if very low HP
	if hp_percent < 0.15:
		return randf() > 0.6

	return false
