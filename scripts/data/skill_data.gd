class_name SkillData
extends Resource
## SkillData: Defines a skill's properties, costs, and effects.

@export_group("Identity")
@export var skill_id: String = ""
@export var display_name: String = "Unknown Skill"
@export var description: String = ""
@export var icon_path: String = ""

@export_group("Classification")
@export var skill_type: SkillType = SkillType.DAMAGE
@export var damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL
@export var target_type: Enums.TargetType = Enums.TargetType.SINGLE_ENEMY
## Brand type determines effectiveness and visual effects
@export var brand_type: Enums.Brand = Enums.Brand.NONE
## Brand requirement to learn/use this skill
@export var brand_requirement: Enums.Brand = Enums.Brand.NONE

enum SkillType {
	DAMAGE,
	HEAL,
	BUFF,
	DEBUFF,
	STATUS,
	UTILITY,
	PASSIVE
}

@export_group("Costs")
@export var mp_cost: int = 0
@export var hp_cost: int = 0
@export var cooldown_turns: int = 0

@export_group("Power")
@export var base_power: int = 10
@export var scaling_stat: Enums.Stat = Enums.Stat.ATTACK
@export var scaling_ratio: float = 1.0
@export var hit_count: int = 1
@export var accuracy_modifier: float = 0.0
@export var crit_modifier: float = 0.0

@export_group("Effects")
@export var status_effects: Array[Dictionary] = []  # [{effect, chance, duration}]
@export var stat_modifiers: Array[Dictionary] = []  # [{stat, amount, duration}]
@export var special_effects: Array[String] = []  # Custom effect IDs

@export_group("Animation")
@export var animation_id: String = ""
@export var sound_effect: String = ""
@export var particle_effect: String = ""
@export var screen_shake: bool = false

@export_group("Unlocking")
@export var level_requirement: int = 1
@export var path_requirement: float = 0.0  # Positive = Seraph, Negative = Shade
@export var prerequisite_skills: Array[String] = []

# =============================================================================
# METHODS
# =============================================================================

func can_use(character: CharacterBase) -> Dictionary:
	var result := {"can_use": true, "reasons": []}

	# Check MP
	if character.current_mp < mp_cost:
		result.can_use = false
		result.reasons.append("Not enough MP")

	# Check HP cost
	if character.current_hp <= hp_cost:
		result.can_use = false
		result.reasons.append("Not enough HP")

	# Check cooldown (would need to track in character)
	# TODO: Implement cooldown tracking

	return result

func get_expected_damage(attacker: CharacterBase, defender: CharacterBase) -> int:
	if skill_type != SkillType.DAMAGE:
		return 0

	var attack_stat := attacker.get_stat(scaling_stat)
	var defense_stat: float

	if damage_type == Enums.DamageType.PHYSICAL:
		defense_stat = defender.get_stat(Enums.Stat.DEFENSE)
	else:
		defense_stat = defender.get_stat(Enums.Stat.RESISTANCE)

	# Guard against division by zero
	defense_stat = maxf(defense_stat, 1.0)

	var level_factor := (attacker.level / 10.0) + 1.0
	var raw_damage := (base_power * (attack_stat / defense_stat) * scaling_ratio) * level_factor

	return int(raw_damage * hit_count)

func get_expected_healing(caster: CharacterBase) -> int:
	if skill_type != SkillType.HEAL:
		return 0

	var magic := caster.get_stat(Enums.Stat.MAGIC)
	var level_factor := (caster.level / 10.0) + 1.0

	return int(base_power * (magic / 10.0) * scaling_ratio * level_factor)

func get_tooltip() -> String:
	var tooltip := "%s\n%s\n\n" % [display_name, description]

	if mp_cost > 0:
		tooltip += "MP Cost: %d\n" % mp_cost
	if hp_cost > 0:
		tooltip += "HP Cost: %d\n" % hp_cost

	if brand_type != Enums.Brand.NONE:
		tooltip += "Brand: %s\n" % Enums.Brand.keys()[brand_type]
	
	tooltip += "Target: %s\n" % Enums.TargetType.keys()[target_type]

	if base_power > 0:
		tooltip += "Power: %d" % base_power
		if hit_count > 1:
			tooltip += " x%d hits" % hit_count
		tooltip += "\n"

	if status_effects.size() > 0:
		tooltip += "Effects: "
		for effect in status_effects:
			tooltip += "%s (%d%%), " % [Enums.StatusEffect.keys()[effect.effect], int(effect.chance * 100)]
		tooltip = tooltip.trim_suffix(", ") + "\n"

	return tooltip
