class_name ItemData
extends Resource
## ItemData: Defines an item's properties and effects.

@export_group("Identity")
@export var item_id: String = ""
@export var display_name: String = "Unknown Item"
@export var description: String = ""
@export var icon_path: String = ""

@export_group("Classification")
@export var item_type: Enums.ItemType = Enums.ItemType.CONSUMABLE
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON
@export var is_key_item: bool = false
@export var is_stackable: bool = true
@export var max_stack: int = 99

@export_group("Economy")
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var can_sell: bool = true

@export_group("Usage")
@export var usable_in_battle: bool = true
@export var usable_in_field: bool = true
@export var target_type: Enums.TargetType = Enums.TargetType.SINGLE_ALLY
@export var consumed_on_use: bool = true

@export_group("Effects - Healing")
@export var hp_restore: int = 0
@export var hp_restore_percent: float = 0.0
@export var mp_restore: int = 0
@export var mp_restore_percent: float = 0.0

@export_group("Effects - Status")
@export var cures_status: Array[Enums.StatusEffect] = []
@export var applies_status: Array[Dictionary] = []  # [{effect, duration}]
@export var revives: bool = false
@export var revive_hp_percent: float = 0.5

@export_group("Effects - Stats")
@export var stat_buffs: Array[Dictionary] = []  # [{stat, amount, duration}]
@export var permanent_stat_increase: Dictionary = {}  # {stat: amount}

@export_group("Effects - Special")
@export var special_effect: String = ""  # Custom effect ID
@export var corruption_change: float = 0.0  # For VERA-related items
@export var path_change: float = 0.0  # For alignment items

@export_group("Equipment Stats")  # Only for equipment
@export var equipment_slot: Enums.EquipmentSlot = Enums.EquipmentSlot.WEAPON
@export var stat_bonuses: Dictionary = {}  # {Stat: amount}
@export var element_affinity: Enums.Element = Enums.Element.NONE
@export var brand_requirement: Enums.Brand = Enums.Brand.NONE

# =============================================================================
# METHODS
# =============================================================================

func use_on_target(target: CharacterBase) -> Dictionary:
	var result := {"success": true, "effects": []}

	# HP Restore
	if hp_restore > 0 or hp_restore_percent > 0:
		var heal_amount := hp_restore
		if hp_restore_percent > 0:
			heal_amount += int(target.get_max_hp() * hp_restore_percent)
		var actual_heal := target.heal(heal_amount)
		result.effects.append({"type": "heal_hp", "amount": actual_heal})

	# MP Restore
	if mp_restore > 0 or mp_restore_percent > 0:
		var restore_amount := mp_restore
		if mp_restore_percent > 0:
			restore_amount += int(target.get_max_mp() * mp_restore_percent)
		var actual_restore := target.restore_mp(restore_amount)
		result.effects.append({"type": "heal_mp", "amount": actual_restore})

	# Revive
	if revives and target.is_dead():
		target.revive(revive_hp_percent)
		result.effects.append({"type": "revive"})

	# Cure Status
	for status in cures_status:
		if target.has_status_effect(status):
			target.remove_status_effect(status)
			result.effects.append({"type": "cure", "status": status})

	# Apply Status
	for status_data in applies_status:
		target.add_status_effect(status_data.effect, status_data.duration)
		result.effects.append({"type": "apply", "status": status_data.effect})

	# Stat Buffs
	for buff in stat_buffs:
		target.add_stat_modifier(buff.stat, buff.amount, buff.duration, display_name)
		result.effects.append({"type": "buff", "stat": buff.stat, "amount": buff.amount})

	# Permanent Stat Increases
	for stat in permanent_stat_increase:
		var amount: int = permanent_stat_increase[stat]
		match stat:
			Enums.Stat.MAX_HP:
				target.base_max_hp += amount
			Enums.Stat.MAX_MP:
				target.base_max_mp += amount
			Enums.Stat.ATTACK:
				target.base_attack += amount
			Enums.Stat.DEFENSE:
				target.base_defense += amount
			Enums.Stat.MAGIC:
				target.base_magic += amount
			Enums.Stat.RESISTANCE:
				target.base_resistance += amount
			Enums.Stat.SPEED:
				target.base_speed += amount
		result.effects.append({"type": "permanent", "stat": stat, "amount": amount})

	# Corruption Change (VERA items)
	if corruption_change != 0:
		if corruption_change > 0:
			GameManager.use_vera_power(corruption_change)
		else:
			GameManager.reduce_vera_corruption(-corruption_change)
		result.effects.append({"type": "corruption", "amount": corruption_change})

	# Path Change
	if path_change != 0:
		GameManager.modify_path_alignment(path_change, display_name)
		result.effects.append({"type": "path", "amount": path_change})

	return result

func can_use(target: CharacterBase) -> bool:
	# Can't use healing items on full HP targets
	if (hp_restore > 0 or hp_restore_percent > 0) and target.current_hp >= target.get_max_hp():
		if mp_restore == 0 and mp_restore_percent == 0:
			return false

	# Can't use revive items on alive targets
	if revives and target.is_alive():
		return false

	# Can't use cure items if target doesn't have the status
	if cures_status.size() > 0:
		var has_curable := false
		for status in cures_status:
			if target.has_status_effect(status):
				has_curable = true
				break
		if not has_curable:
			return false

	return true

func get_tooltip() -> String:
	var tooltip := "%s\n%s\n\n" % [display_name, description]

	if item_type == Enums.ItemType.CONSUMABLE:
		if hp_restore > 0:
			tooltip += "Restores %d HP\n" % hp_restore
		if hp_restore_percent > 0:
			tooltip += "Restores %d%% HP\n" % int(hp_restore_percent * 100)
		if mp_restore > 0:
			tooltip += "Restores %d MP\n" % mp_restore
		if revives:
			tooltip += "Revives fallen ally\n"
		if cures_status.size() > 0:
			tooltip += "Cures: "
			for status in cures_status:
				tooltip += Enums.StatusEffect.keys()[status] + ", "
			tooltip = tooltip.trim_suffix(", ") + "\n"

	elif item_type == Enums.ItemType.EQUIPMENT:
		for stat in stat_bonuses:
			var amount: int = stat_bonuses[stat]
			var sign_str := "+" if amount > 0 else ""
			tooltip += "%s %s%d\n" % [Enums.Stat.keys()[stat], sign_str, amount]

	if buy_price > 0:
		tooltip += "\nBuy: %d | Sell: %d" % [buy_price, sell_price]

	return tooltip
