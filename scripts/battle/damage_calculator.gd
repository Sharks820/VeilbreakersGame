class_name DamageCalculator
extends Node
## DamageCalculator: Handles all damage, healing, and combat calculations.
## Uses Brand effectiveness system for type advantages.

# =============================================================================
# BRAND EFFECTIVENESS
# Wheel: SAVAGE → IRON → VENOM → SURGE → DREAD → LEECH → SAVAGE
# =============================================================================

## Get brand name from enum value
static func _get_brand_name(brand: Enums.Brand) -> String:
	match brand:
		Enums.Brand.SAVAGE: return "SAVAGE"
		Enums.Brand.IRON: return "IRON"
		Enums.Brand.VENOM: return "VENOM"
		Enums.Brand.SURGE: return "SURGE"
		Enums.Brand.DREAD: return "DREAD"
		Enums.Brand.LEECH: return "LEECH"
		Enums.Brand.BLOODIRON: return "BLOODIRON"
		Enums.Brand.CORROSIVE: return "CORROSIVE"
		Enums.Brand.VENOMSTRIKE: return "VENOMSTRIKE"
		Enums.Brand.TERRORFLUX: return "TERRORFLUX"
		Enums.Brand.NIGHTLEECH: return "NIGHTLEECH"
		Enums.Brand.RAVENOUS: return "RAVENOUS"
		_: return "NONE"

## Get the PRIMARY brand for effectiveness calculations (hybrids use their primary)
static func _get_primary_brand(brand: Enums.Brand) -> String:
	var brand_name := _get_brand_name(brand)
	if Constants.HYBRID_BRAND_COMPONENTS.has(brand_name):
		return Constants.HYBRID_BRAND_COMPONENTS[brand_name]["primary"]
	return brand_name

## Calculate brand effectiveness multiplier
func get_brand_effectiveness(attacker_brand: Enums.Brand, defender_brand: Enums.Brand) -> float:
	if attacker_brand == Enums.Brand.NONE or defender_brand == Enums.Brand.NONE:
		return Constants.BRAND_NEUTRAL

	var attacker_primary := _get_primary_brand(attacker_brand)
	var defender_primary := _get_primary_brand(defender_brand)

	# Check effectiveness matrix
	if Constants.BRAND_EFFECTIVENESS.has(attacker_primary):
		var matchups: Dictionary = Constants.BRAND_EFFECTIVENESS[attacker_primary]
		if matchups.has(defender_primary):
			return matchups[defender_primary]

	return Constants.BRAND_NEUTRAL

## Check path-brand effectiveness for heroes
func get_path_brand_modifier(hero_path: Enums.Path, monster_brand: Enums.Brand) -> float:
	if hero_path == Enums.Path.NONE:
		return 1.0

	var path_name: String = Enums.Path.keys()[hero_path]
	var brand_name: String = _get_primary_brand(monster_brand)

	# Check if hero's path is strong against this brand
	if Constants.PATH_BRAND_STRENGTH.has(path_name):
		if Constants.PATH_BRAND_STRENGTH[path_name] == brand_name:
			return Constants.PATH_STRONG_MULTIPLIER  # 1.35x

	# Check if hero's path is weak against this brand
	if Constants.PATH_BRAND_WEAKNESS.has(path_name):
		if Constants.PATH_BRAND_WEAKNESS[path_name] == brand_name:
			return Constants.PATH_WEAK_MULTIPLIER  # 0.70x

	return 1.0

# =============================================================================
# DAMAGE CALCULATION
# =============================================================================

func calculate_damage(attacker: CharacterBase, defender: CharacterBase, skill: Resource) -> Dictionary:
	var result := {
		"damage": 0,
		"is_critical": false,
		"is_miss": false,
		"brand_effectiveness": 1.0,
		"damage_type": Enums.DamageType.PHYSICAL,
		"attacker_brand": Enums.Brand.NONE,
		"defender_brand": Enums.Brand.NONE
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
	var damage_type := Enums.DamageType.PHYSICAL
	var crit_mod := 0.0
	var hit_count := 1

	if skill != null and skill is SkillData:
		power = float(skill.base_power)
		scaling_stat = skill.scaling_stat
		damage_type = skill.damage_type
		crit_mod = skill.crit_modifier
		hit_count = skill.hit_count

	# Select appropriate defense stat
	if damage_type == Enums.DamageType.MAGICAL:
		defense_stat = Enums.Stat.RESISTANCE

	# Base damage calculation
	var attack := attacker.get_stat(scaling_stat)
	var defense := defender.get_stat(defense_stat)

	# Level scaling - BALANCED for challenging but fair combat
	# Target: ~15-35 damage per hit, battles last 4-6 rounds
	# Previous settings were TOO defensive (enemies dealt almost no damage)
	# New: Level matters moderately (0.95 to 1.15 range at level 10)
	var level_factor := 0.95 + (float(attacker.level) / 50.0)  # Level 10 = 1.15x

	# Base formula with MODERATE defense scaling
	# Defense reduces damage but doesn't negate it
	var defense_multiplier := 1.3  # Defense counts 1.3x (was 2.0 - too high)
	var effective_defense := maxf(8.0, defense * defense_multiplier)
	
	# Damage = Power * (Attack / Defense) * LevelFactor * GlobalScale
	var global_damage_scale := 0.65  # 65% of original (was 0.4 - too low)
	var raw_damage := power * (attack / effective_defense) * level_factor * global_damage_scale

	# Brand effectiveness
	var brand_mod := 1.0
	var attacker_brand: Enums.Brand = attacker.brand if "brand" in attacker else Enums.Brand.NONE
	var defender_brand: Enums.Brand = defender.brand if "brand" in defender else Enums.Brand.NONE

	# Get brand from skill if available (skills can have brand_type)
	if skill != null and skill is SkillData and "brand_type" in skill:
		if skill.brand_type != Enums.Brand.NONE:
			attacker_brand = skill.brand_type

	# Calculate brand effectiveness
	brand_mod = get_brand_effectiveness(attacker_brand, defender_brand)

	# Path-Brand modifier (for heroes attacking monsters)
	if "path" in attacker:
		var path_mod := get_path_brand_modifier(attacker.path, defender_brand)
		brand_mod *= path_mod

	result.brand_effectiveness = brand_mod
	result.attacker_brand = attacker_brand
	result.defender_brand = defender_brand
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
	if defender.has_status_effect(Enums.StatusEffect.SORROW):
		defender_mod *= 1.15  # DREAD brand debuff - +15% damage taken

	# Attacker status effects
	var attacker_mod := 1.0
	if attacker.has_status_effect(Enums.StatusEffect.ATTACK_UP):
		attacker_mod *= 1.25
	if attacker.has_status_effect(Enums.StatusEffect.ATTACK_DOWN):
		attacker_mod *= 0.75

	# Final damage (minimum 1)
	result.damage = maxi(1, int(raw_damage * brand_mod * variance * defender_mod * attacker_mod))

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
# BRAND EFFECTIVENESS TEXT
# =============================================================================

func get_effectiveness_text(modifier: float) -> String:
	if modifier >= Constants.BRAND_STRONG:
		return "Super Effective!"
	elif modifier > 1.0:
		return "Effective!"
	elif modifier <= Constants.BRAND_WEAK:
		return "Resisted..."
	elif modifier < 1.0:
		return "Not Very Effective..."
	return ""

func get_brand_name(brand: Enums.Brand) -> String:
	return _get_brand_name(brand)

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
	var hit_count := 1

	if skill != null and skill is SkillData:
		power = float(skill.base_power)
		scaling_stat = skill.scaling_stat
		hit_count = skill.hit_count
		if skill.damage_type == Enums.DamageType.MAGICAL:
			defense_stat = Enums.Stat.RESISTANCE

	var attack := attacker.get_stat(scaling_stat)
	var defense := defender.get_stat(defense_stat)
	# Match the BALANCED scaling from calculate_damage
	var level_factor := 0.95 + (float(attacker.level) / 50.0)
	
	var defense_multiplier := 1.3
	var effective_defense := maxf(8.0, defense * defense_multiplier)
	var global_damage_scale := 0.65
	var base_damage := power * (attack / effective_defense) * level_factor * global_damage_scale

	# Get brand effectiveness
	var attacker_brand: Enums.Brand = attacker.brand if "brand" in attacker else Enums.Brand.NONE
	var defender_brand: Enums.Brand = defender.brand if "brand" in defender else Enums.Brand.NONE
	
	if skill != null and skill is SkillData and "brand_type" in skill:
		if skill.brand_type != Enums.Brand.NONE:
			attacker_brand = skill.brand_type
	
	var brand_mod := get_brand_effectiveness(attacker_brand, defender_brand)

	# Apply hit_count multiplier
	base_damage *= hit_count

	var min_damage := int(base_damage * brand_mod * (1.0 - Constants.DAMAGE_VARIANCE))
	var max_damage := int(base_damage * brand_mod * (1.0 + Constants.DAMAGE_VARIANCE))
	var crit_damage := int(max_damage * attacker.get_stat(Enums.Stat.CRIT_DAMAGE))

	return {
		"min": maxi(1, min_damage),
		"max": maxi(1, max_damage),
		"crit_max": maxi(1, crit_damage),
		"brand_effectiveness": brand_mod,
		"hit_chance": calculate_hit_chance(attacker, defender)
	}
