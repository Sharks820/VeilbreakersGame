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
## @deprecated Use brand_affinity instead. Kept for save compatibility.
@export var element_affinity: Enums.Element = Enums.Element.NONE
## v5.0: Brand affinity - determines brand bonuses and visual effects
@export var brand_affinity: Enums.Brand = Enums.Brand.NONE
## Brand requirement to equip this item (uses Constants.BRAND_EQUIPMENT_THRESHOLD)
@export var brand_requirement: Enums.Brand = Enums.Brand.NONE

# =============================================================================
# METHODS
# =============================================================================

## Apply this item's effects to a target character.
## @param target The CharacterBase to receive the item's effects
## @returns Dictionary with "success" (bool), "effects" (Array), and optionally "is_capture_item" and "capture_tier"
func use_on_target(target: CharacterBase) -> Dictionary:
	if target == null:
		push_error("ItemData.use_on_target: target is null")
		return {"success": false, "effects": [], "error": "null_target"}

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

	# Apply Status (safe dictionary access)
	for status_data in applies_status:
		var effect = status_data.get("effect", Enums.StatusEffect.NONE)
		var duration: int = status_data.get("duration", 1)
		if effect != Enums.StatusEffect.NONE:
			target.add_status_effect(effect, duration)
			result.effects.append({"type": "apply", "status": effect})

	# Stat Buffs (safe dictionary access)
	for buff in stat_buffs:
		var buff_stat = buff.get("stat")
		var buff_amount: float = buff.get("amount", 0.0)
		var buff_duration: int = buff.get("duration", 1)
		if buff_stat != null and buff_amount != 0.0:
			target.add_stat_modifier(buff_stat, buff_amount, buff_duration, display_name)
			result.effects.append({"type": "buff", "stat": buff_stat, "amount": buff_amount})

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

	# Special Effects (capture orbs, etc.)
	if special_effect != "":
		var special_result := _process_special_effect(target)
		if special_result.size() > 0:
			result.effects.append(special_result)
			# Capture effects are handled differently - signal that this is a capture item
			if special_effect.begins_with("attempt_capture"):
				result["is_capture_item"] = true
				result["capture_tier"] = _get_capture_tier_from_effect()

	return result

## Process special effects based on special_effect string
## Note: target is available for future effects that need target info (buff items, etc.)
func _process_special_effect(_target: CharacterBase) -> Dictionary:
	match special_effect:
		"attempt_capture":
			return {"type": "capture", "tier": 0, "tier_name": "Basic"}
		"attempt_capture_enhanced":
			return {"type": "capture", "tier": 1, "tier_name": "Greater"}
		"attempt_capture_master":
			return {"type": "capture", "tier": 2, "tier_name": "Master"}
		"attempt_capture_legendary":
			return {"type": "capture", "tier": 3, "tier_name": "Legendary"}
		"purify_monster_5":
			return {"type": "purify", "corruption_reduction": 5.0}
		"purify_monster_10":
			return {"type": "purify", "corruption_reduction": 10.0}
		"purify_monster_15":
			return {"type": "purify", "corruption_reduction": 15.0}
		_:
			if special_effect != "":
				push_warning("Unknown special effect: %s" % special_effect)
			return {}

## Get capture tier from special_effect string
func _get_capture_tier_from_effect() -> int:
	match special_effect:
		"attempt_capture": return 0
		"attempt_capture_enhanced": return 1
		"attempt_capture_master": return 2
		"attempt_capture_legendary": return 3
	return 0

## Check if this is a capture item
func is_capture_item() -> bool:
	return special_effect.begins_with("attempt_capture")

## Get capture tier for this item (0-3)
func get_capture_tier() -> int:
	return _get_capture_tier_from_effect()

## Check if this item can be used on the given target.
## @param target The potential target CharacterBase
## @returns true if the item can be used on this target, false otherwise
func can_use(target: CharacterBase) -> bool:
	if target == null:
		return false

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
