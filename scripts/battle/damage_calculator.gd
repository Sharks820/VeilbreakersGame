class_name DamageCalculator
extends Node
## DamageCalculator: Handles all damage, healing, and combat calculations.

# =============================================================================
# CONSTANTS (Element weakness chart - computed once at compile time)
# =============================================================================

const ELEMENT_WEAKNESSES := {
	Enums.Element.FIRE: [Enums.Element.ICE, Enums.Element.WIND],
	Enums.Element.ICE: [Enums.Element.LIGHTNING, Enums.Element.EARTH],
	Enums.Element.LIGHTNING: [Enums.Element.WATER],
	Enums.Element.EARTH: [Enums.Element.LIGHTNING],
	Enums.Element.WATER: [Enums.Element.FIRE],
	Enums.Element.WIND: [Enums.Element.EARTH],
	Enums.Element.LIGHT: [Enums.Element.DARK, Enums.Element.VOID],
	Enums.Element.DARK: [Enums.Element.LIGHT],
	Enums.Element.HOLY: [Enums.Element.VOID, Enums.Element.DARK],
	Enums.Element.VOID: [Enums.Element.HOLY, Enums.Element.LIGHT]
}

# =============================================================================
# DAMAGE CALCULATION
# =============================================================================

func calculate_damage(attacker: CharacterBase, defender: CharacterBase, skill: Resource) -> Dictionary:
	var result := {
		"damage": 0,
		"is_critical": false,
		"is_miss": false,
		"element_effectiveness": 1.0,
		"element": Enums.Element.PHYSICAL,
		"damage_type": Enums.DamageType.PHYSICAL
	}

	# Check for miss (skill accuracy modifier applied after)
	var skill_accuracy_mod := 0.0
	if skill != null and skill is SkillData:
		skill_accuracy_mod = skill.accuracy_modifier
	var hit_chance := calculate_hit_chance(attacker, defender) + skill_accuracy_mod

	if randf() > hit_chance:
		result.is_miss = true
		return result

	# Get skill properties or use basic attack
	var power := 10.0
	var scaling_stat := Enums.Stat.ATTACK
	var defense_stat := Enums.Stat.DEFENSE
	var element := Enums.Element.PHYSICAL
	var damage_type := Enums.DamageType.PHYSICAL
	var accuracy_mod := 0.0
	var crit_mod := 0.0
	var hit_count := 1

	if skill != null and skill is SkillData:
		power = float(skill.base_power)
		scaling_stat = skill.scaling_stat
		element = skill.element
		damage_type = skill.damage_type
		accuracy_mod = skill.accuracy_modifier
		crit_mod = skill.crit_modifier
		hit_count = skill.hit_count

	# Select appropriate defense stat
	if damage_type == Enums.DamageType.MAGICAL:
		defense_stat = Enums.Stat.RESISTANCE

	# Base damage calculation
	var attack := attacker.get_stat(scaling_stat)
	var defense := defender.get_stat(defense_stat)

	# Level scaling
	var level_factor := (float(attacker.level) / 10.0) + 1.0

	# Base formula: (Power * Attack / Defense) * LevelFactor
	var raw_damage := (power * (attack / maxf(1.0, defense))) * level_factor

	# Elemental modifier
	var element_mod := _get_element_modifier(element, defender.elements)
	result.element_effectiveness = element_mod
	result.element = element
	result.damage_type = damage_type

	# Critical hit check (skill can modify crit chance)
	var crit_chance := attacker.get_stat(Enums.Stat.CRIT_CHANCE) + crit_mod
	if randf() < crit_chance:
		result.is_critical = true
		raw_damage *= attacker.get_stat(Enums.Stat.CRIT_DAMAGE)

	# Multi-hit skills
	if hit_count > 1:
		raw_damage *= hit_count

	# Damage variance (+/- 10%)
	var variance := randf_range(1.0 - Constants.DAMAGE_VARIANCE, 1.0 + Constants.DAMAGE_VARIANCE)

	# Defender status effects
	var defender_mod := 1.0
	if defender.has_status_effect(Enums.StatusEffect.DEFENSE_DOWN):
		defender_mod *= 1.25
	if defender.has_status_effect(Enums.StatusEffect.DEFENSE_UP):
		defender_mod *= 0.75

	# Attacker status effects
	var attacker_mod := 1.0
	if attacker.has_status_effect(Enums.StatusEffect.ATTACK_UP):
		attacker_mod *= 1.25
	if attacker.has_status_effect(Enums.StatusEffect.ATTACK_DOWN):
		attacker_mod *= 0.75

	# Final damage (minimum 1)
	result.damage = maxi(1, int(raw_damage * element_mod * variance * defender_mod * attacker_mod))

	return result

func calculate_hit_chance(attacker: CharacterBase, defender: CharacterBase) -> float:
	var accuracy := attacker.get_stat(Enums.Stat.ACCURACY)
	var evasion := defender.get_stat(Enums.Stat.EVASION)

	# Blind status reduces accuracy
	if attacker.has_status_effect(Enums.StatusEffect.BLIND):
		accuracy *= 0.5

	# Speed difference affects evasion
	var speed_diff := defender.get_stat(Enums.Stat.SPEED) - attacker.get_stat(Enums.Stat.SPEED)
	var speed_evasion_bonus := clampf(speed_diff * 0.002, -0.1, 0.1)

	var hit_chance := accuracy - evasion - speed_evasion_bonus
	return clampf(hit_chance, 0.1, 0.99)

# =============================================================================
# ELEMENTAL SYSTEM
# =============================================================================

func _get_element_modifier(attack_element: Enums.Element, defender_elements: Array) -> float:
	if defender_elements.is_empty():
		return 1.0

	var modifier := 1.0

	for def_element in defender_elements:
		if _is_strong_against(attack_element, def_element):
			modifier *= Constants.ELEMENTAL_WEAKNESS_MULTIPLIER
		elif _is_weak_against(attack_element, def_element):
			modifier *= Constants.ELEMENTAL_RESISTANCE_MULTIPLIER
		elif _is_immune_to(attack_element, def_element):
			modifier *= 0.0

	return modifier

func _is_strong_against(attacker: Enums.Element, defender: Enums.Element) -> bool:
	## Returns true if attacker element is strong against defender element
	if ELEMENT_WEAKNESSES.has(attacker):
		return defender in ELEMENT_WEAKNESSES[attacker]
	return false

func _is_weak_against(attacker: Enums.Element, defender: Enums.Element) -> bool:
	## Reverse of strong against
	return _is_strong_against(defender, attacker)

func _is_immune_to(attack_element: Enums.Element, defender_element: Enums.Element) -> bool:
	## Check for immunities (same element typically)
	if attack_element == defender_element:
		match attack_element:
			Enums.Element.FIRE, Enums.Element.ICE, Enums.Element.LIGHTNING:
				return false  # Not immune, just resistant
	return false

func get_element_name(element: Enums.Element) -> String:
	return Enums.Element.keys()[element]

func get_effectiveness_text(modifier: float) -> String:
	if modifier >= 2.0:
		return "Super Effective!"
	elif modifier > 1.0:
		return "Effective!"
	elif modifier < 0.5:
		return "Resisted..."
	elif modifier == 0.0:
		return "Immune!"
	elif modifier < 1.0:
		return "Not Very Effective..."
	return ""

# =============================================================================
# HEALING CALCULATION
# =============================================================================

func calculate_healing(healer: CharacterBase, target: CharacterBase, skill: Resource) -> Dictionary:
	var power := 20.0  # Base healing power
	var scaling_ratio := 1.0

	if skill != null and skill is SkillData:
		power = float(skill.base_power)
		scaling_ratio = skill.scaling_ratio

	var magic := healer.get_stat(Enums.Stat.MAGIC)
	var level_factor := (float(healer.level) / 10.0) + 1.0

	var raw_healing := power * (magic / 10.0) * level_factor * scaling_ratio

	# Healing variance (+/- 5%)
	var variance := randf_range(0.95, 1.05)

	# Status effect modifiers
	if target.has_status_effect(Enums.StatusEffect.REGEN):
		raw_healing *= 1.2

	var final_healing := maxi(1, int(raw_healing * variance))

	return {
		"heal_amount": final_healing,
		"target_hp_after": mini(target.get_max_hp(), target.current_hp + final_healing)
	}

# =============================================================================
# STATUS EFFECT CHANCE
# =============================================================================

func calculate_status_chance(applier: CharacterBase, target: CharacterBase, base_chance: float) -> float:
	# Magic stat increases status chance
	var magic_bonus := applier.get_stat(Enums.Stat.MAGIC) * 0.002

	# Luck affects both application and resistance
	var luck_diff := applier.get_stat(Enums.Stat.LUCK) - target.get_stat(Enums.Stat.LUCK)
	var luck_mod := luck_diff * 0.01

	# Resistance reduces status chance
	var resistance_mod := target.get_stat(Enums.Stat.RESISTANCE) * 0.001

	var final_chance := base_chance + magic_bonus + luck_mod - resistance_mod
	return clampf(final_chance, 0.05, 0.95)

# =============================================================================
# DAMAGE PREVIEW
# =============================================================================

func preview_damage(attacker: CharacterBase, defender: CharacterBase, skill: Resource = null) -> Dictionary:
	## Get estimated damage range without RNG
	var power := 10.0
	var scaling_stat := Enums.Stat.ATTACK
	var defense_stat := Enums.Stat.DEFENSE
	var element := Enums.Element.PHYSICAL
	var hit_count := 1

	if skill != null and skill is SkillData:
		power = float(skill.base_power)
		scaling_stat = skill.scaling_stat
		element = skill.element
		hit_count = skill.hit_count
		if skill.damage_type == Enums.DamageType.MAGICAL:
			defense_stat = Enums.Stat.RESISTANCE

	var attack := attacker.get_stat(scaling_stat)
	var defense := defender.get_stat(defense_stat)
	var level_factor := (float(attacker.level) / 10.0) + 1.0

	var base_damage := (power * (attack / maxf(1.0, defense))) * level_factor
	var element_mod := _get_element_modifier(element, defender.elements)

	# Apply hit_count multiplier
	base_damage *= hit_count

	var min_damage := int(base_damage * element_mod * (1.0 - Constants.DAMAGE_VARIANCE))
	var max_damage := int(base_damage * element_mod * (1.0 + Constants.DAMAGE_VARIANCE))
	var crit_damage := int(max_damage * attacker.get_stat(Enums.Stat.CRIT_DAMAGE))

	return {
		"min": maxi(1, min_damage),
		"max": maxi(1, max_damage),
		"crit_max": maxi(1, crit_damage),
		"element_effectiveness": element_mod,
		"hit_chance": calculate_hit_chance(attacker, defender)
	}
