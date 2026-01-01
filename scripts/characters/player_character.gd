class_name PlayerCharacter
extends CharacterBase
## PlayerCharacter: Playable character with brand system, equipment, and brand alignment.
##
## BRAND ALIGNMENT: Player develops alignment with 6 Brands (0-100% each)
## based on story choices and battle actions. Required for Brand-locked equipment.

# =============================================================================
# SIGNALS
# =============================================================================

signal experience_changed(old_value: int, new_value: int)
signal brand_changed(old_brand: int, new_brand: int)
signal equipment_changed(slot: int, old_item: String, new_item: String)
signal brand_alignment_changed(brand: Enums.Brand, old_value: float, new_value: float)
signal equipment_alignment_warning(slot: int, item_id: String, battles_below: int)
signal equipment_shattered(slot: int, item_id: String)

# =============================================================================
# PLAYER-SPECIFIC PROPERTIES
# =============================================================================

@export_group("Player Data")
@export var player_id: String = "player"
@export var current_brand: Enums.Brand = Enums.Brand.NONE
@export var unlocked_brands: Array[Enums.Brand] = [Enums.Brand.NONE]

@export_group("Experience")
@export var current_experience: int = 0
@export var total_experience: int = 0

@export_group("Brand Affinity")
@export var brand_affinity: Dictionary = {}  # {brand: affinity_level}

@export_group("Brand Alignment")
## Player's alignment with each of the 6 pure Brands (0-100%)
## Affects equipment requirements and story outcomes
@export var brand_alignment: Dictionary = {
	"SAVAGE": 20.0,
	"IRON": 20.0,
	"VENOM": 20.0,
	"SURGE": 20.0,
	"DREAD": 20.0,
	"LEECH": 20.0
}

## Tracks battles below alignment threshold per equipment slot
## {slot: {item_id: battles_count}}
@export var equipment_decay_tracking: Dictionary = {}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	super._ready()
	character_type = Enums.CharacterType.PLAYER
	_apply_brand_bonuses()

# =============================================================================
# BRAND SYSTEM
# =============================================================================

func set_brand(brand: Enums.Brand) -> bool:
	if brand not in unlocked_brands:
		return false

	var old_brand := current_brand
	current_brand = brand
	_apply_brand_bonuses()
	brand_changed.emit(old_brand, brand)
	return true

func unlock_brand(brand: Enums.Brand) -> void:
	if brand not in unlocked_brands:
		unlocked_brands.append(brand)
		EventBus.brand_unlocked.emit(brand)

func has_brand(brand: Enums.Brand) -> bool:
	return brand in unlocked_brands

func _apply_brand_bonuses() -> void:
	# Clear previous brand modifiers by removing all with "brand" source
	for stat in stat_modifiers.keys():
		var mods: Array = stat_modifiers[stat]
		for i in range(mods.size() - 1, -1, -1):
			if mods[i].get("source", "") == "brand":
				mods.remove_at(i)

	if current_brand == Enums.Brand.NONE:
		return

	# Validate enum index is within bounds
	var brand_keys := Enums.Brand.keys()
	if current_brand < 0 or current_brand >= brand_keys.size():
		push_warning("Invalid brand enum value: %d" % current_brand)
		return

	var brand_key: String = brand_keys[current_brand]
	if not Constants.BRAND_BONUSES.has(brand_key):
		return

	var bonuses: Dictionary = Constants.BRAND_BONUSES[brand_key]

	# Apply multipliers as percentage bonuses
	for key in bonuses:
		var mult: float = bonuses[key]
		var bonus: float = (mult - 1.0)  # Convert multiplier to bonus

		match key:
			"hp_mult":
				add_stat_modifier(Enums.Stat.MAX_HP, base_max_hp * bonus, 9999, "brand")
			"atk_mult":
				add_stat_modifier(Enums.Stat.ATTACK, base_attack * bonus, 9999, "brand")
			"def_mult":
				add_stat_modifier(Enums.Stat.DEFENSE, base_defense * bonus, 9999, "brand")
			"mag_mult":
				add_stat_modifier(Enums.Stat.MAGIC, base_magic * bonus, 9999, "brand")
			"res_mult":
				add_stat_modifier(Enums.Stat.RESISTANCE, base_resistance * bonus, 9999, "brand")
			"spd_mult":
				add_stat_modifier(Enums.Stat.SPEED, base_speed * bonus, 9999, "brand")
			"crit_mult":
				add_stat_modifier(Enums.Stat.CRIT_CHANCE, base_crit_chance * bonus, 9999, "brand")

func get_brand_name() -> String:
	return Enums.Brand.keys()[current_brand]

func get_brand_description() -> String:
	match current_brand:
		Enums.Brand.SAVAGE:
			return "Raw Destruction - +25% ATK"
		Enums.Brand.IRON:
			return "Unyielding Defense - +30% HP"
		Enums.Brand.VENOM:
			return "Precision Poison - +20% Crit, +15% Status"
		Enums.Brand.SURGE:
			return "Lightning Speed - +25% SPD"
		Enums.Brand.DREAD:
			return "Terror Incarnate - +20% Evasion, +15% Fear"
		Enums.Brand.LEECH:
			return "Life Drain - +20% Lifesteal"
		Enums.Brand.BLOODIRON:
			return "Savage + Iron Hybrid"
		Enums.Brand.CORROSIVE:
			return "Iron + Venom Hybrid"
		Enums.Brand.VENOMSTRIKE:
			return "Venom + Surge Hybrid"
		Enums.Brand.TERRORFLUX:
			return "Surge + Dread Hybrid"
		Enums.Brand.NIGHTLEECH:
			return "Dread + Leech Hybrid"
		Enums.Brand.RAVENOUS:
			return "Leech + Savage Hybrid"
	return "No brand active"

# =============================================================================
# BRAND ALIGNMENT SYSTEM
# =============================================================================

func get_brand_alignment(brand_key: String) -> float:
	## Get alignment with a specific Brand (0-100)
	return brand_alignment.get(brand_key, 0.0)

func set_brand_alignment(brand_key: String, value: float) -> void:
	## Set alignment with a specific Brand
	var old: float = brand_alignment.get(brand_key, 0.0)
	brand_alignment[brand_key] = clampf(value, 0.0, 100.0)
	if brand_alignment[brand_key] != old:
		var brand_enum := _brand_key_to_enum(brand_key)
		brand_alignment_changed.emit(brand_enum, old, brand_alignment[brand_key])

func modify_brand_alignment(brand_key: String, amount: float) -> void:
	## Add or subtract from Brand alignment
	var current: float = brand_alignment.get(brand_key, 0.0)
	set_brand_alignment(brand_key, current + amount)

func apply_story_choice_alignment(choice_effects: Dictionary) -> void:
	## Apply Brand alignment changes from a story choice
	## choice_effects format: {"IRON": 15, "SAVAGE": -5}
	for brand_key in choice_effects:
		var amount: float = choice_effects[brand_key]
		# Clamp to maximum story effect
		amount = clampf(amount, -Constants.ALIGNMENT_STORY_MAXIMUM, Constants.ALIGNMENT_STORY_MAXIMUM)
		modify_brand_alignment(brand_key, amount)

func apply_battle_action_alignment(action: String) -> void:
	## Apply Brand alignment changes from battle actions
	match action:
		"dominate":
			modify_brand_alignment("DREAD", Constants.ALIGNMENT_BATTLE_DOMINATE_DREAD)
			modify_brand_alignment("LEECH", Constants.ALIGNMENT_BATTLE_DOMINATE_LEECH)
		"purify":
			modify_brand_alignment("IRON", Constants.ALIGNMENT_BATTLE_PURIFY_IRON)
			modify_brand_alignment("VENOM", Constants.ALIGNMENT_BATTLE_PURIFY_VENOM)
		"execute":
			modify_brand_alignment("SAVAGE", Constants.ALIGNMENT_BATTLE_EXECUTE_SAVAGE)

func get_dominant_brand() -> String:
	## Get the Brand with highest alignment
	var highest_brand := "IRON"
	var highest_value := 0.0
	
	for brand_key in brand_alignment:
		if brand_alignment[brand_key] > highest_value:
			highest_value = brand_alignment[brand_key]
			highest_brand = brand_key
	
	return highest_brand

func meets_equipment_requirement(brand_key: String) -> bool:
	## Check if player meets the 55% alignment requirement for brand-locked equipment
	return get_brand_alignment(brand_key) >= Constants.BRAND_EQUIPMENT_THRESHOLD

func meets_hybrid_equipment_requirement(brand_key_1: String, brand_key_2: String) -> bool:
	## Check if player meets 40%+ in BOTH brands for hybrid equipment
	return get_brand_alignment(brand_key_1) >= Constants.BRAND_HYBRID_EQUIPMENT_THRESHOLD and \
		   get_brand_alignment(brand_key_2) >= Constants.BRAND_HYBRID_EQUIPMENT_THRESHOLD

func _brand_key_to_enum(brand_key: String) -> Enums.Brand:
	match brand_key:
		"SAVAGE": return Enums.Brand.SAVAGE
		"IRON": return Enums.Brand.IRON
		"VENOM": return Enums.Brand.VENOM
		"SURGE": return Enums.Brand.SURGE
		"DREAD": return Enums.Brand.DREAD
		"LEECH": return Enums.Brand.LEECH
	return Enums.Brand.NONE

# =============================================================================
# EQUIPMENT ALIGNMENT DECAY
# =============================================================================

func check_equipment_alignment_decay() -> void:
	## Called after each battle to check equipment alignment decay
	var slots := [Enums.EquipmentSlot.WEAPON, Enums.EquipmentSlot.ARMOR, 
				  Enums.EquipmentSlot.ACCESSORY_1, Enums.EquipmentSlot.ACCESSORY_2]
	
	for slot in slots:
		var item_id := get_equipped_item(slot)
		if item_id == "":
			continue
		
		var required_brand := _get_equipment_required_brand(item_id)
		if required_brand == "":
			continue  # No brand requirement
		
		var meets_requirement := meets_equipment_requirement(required_brand)
		
		if not meets_requirement:
			_increment_equipment_decay(slot, item_id)
		else:
			_reset_equipment_decay(slot, item_id)

func _increment_equipment_decay(slot: Enums.EquipmentSlot, item_id: String) -> void:
	## Increment decay counter for equipment below alignment threshold
	if not equipment_decay_tracking.has(slot):
		equipment_decay_tracking[slot] = {}
	
	var current: int = equipment_decay_tracking[slot].get(item_id, 0)
	current += 1
	equipment_decay_tracking[slot][item_id] = current
	
	# Check decay stage
	if current >= Constants.EQUIPMENT_SHATTER_BATTLES:
		_shatter_equipment(slot, item_id)
	elif current >= Constants.EQUIPMENT_CORRUPTION_BATTLES:
		equipment_alignment_warning.emit(slot, item_id, current)
		EventBus.emit_notification("Equipment corroding! Unequip soon or it will shatter!", "danger")
	elif current >= Constants.EQUIPMENT_REJECTION_BATTLES:
		equipment_alignment_warning.emit(slot, item_id, current)
		EventBus.emit_notification("Equipment rejecting you...", "warning")
	elif current >= Constants.EQUIPMENT_RESISTANCE_BATTLES:
		equipment_alignment_warning.emit(slot, item_id, current)

func _reset_equipment_decay(slot: Enums.EquipmentSlot, item_id: String) -> void:
	## Reset decay counter when alignment requirement is met
	if equipment_decay_tracking.has(slot):
		equipment_decay_tracking[slot].erase(item_id)

func _shatter_equipment(slot: Enums.EquipmentSlot, item_id: String) -> void:
	## Equipment shatters from alignment decay
	# Deal 25% max HP damage
	var damage := int(get_max_hp() * Constants.EQUIPMENT_SHATTER_HP_DAMAGE)
	take_damage(damage)
	
	# Remove equipment
	unequip_item(slot)
	
	# Equipment is GONE (not returned to inventory)
	equipment_shattered.emit(slot, item_id)
	EventBus.emit_notification("Equipment SHATTERED! %s is gone forever!" % item_id, "danger")

func _get_equipment_required_brand(item_id: String) -> String:
	## Get the Brand required for this equipment (from item database)
	## TODO: Query actual item database
	# Placeholder - check item_id prefix
	if item_id.begins_with("savage_"):
		return "SAVAGE"
	elif item_id.begins_with("iron_"):
		return "IRON"
	elif item_id.begins_with("venom_"):
		return "VENOM"
	elif item_id.begins_with("surge_"):
		return "SURGE"
	elif item_id.begins_with("dread_"):
		return "DREAD"
	elif item_id.begins_with("leech_"):
		return "LEECH"
	return ""

func get_equipment_decay_stage(slot: Enums.EquipmentSlot) -> String:
	## Get the current decay stage for equipment in a slot
	var item_id := get_equipped_item(slot)
	if item_id == "":
		return "none"
	
	var battles: int = 0
	if equipment_decay_tracking.has(slot):
		battles = equipment_decay_tracking[slot].get(item_id, 0)
	
	if battles >= Constants.EQUIPMENT_CORRUPTION_BATTLES:
		return "corruption"
	elif battles >= Constants.EQUIPMENT_REJECTION_BATTLES:
		return "rejection"
	elif battles >= Constants.EQUIPMENT_RESISTANCE_BATTLES:
		return "resistance"
	return "none"

# =============================================================================
# EXPERIENCE & LEVELING
# =============================================================================

func add_experience(amount: int) -> Dictionary:
	var old_exp := current_experience
	var old_level := level
	var levels_gained := 0
	var all_stat_gains := {}

	current_experience += amount
	total_experience += amount

	experience_changed.emit(old_exp, current_experience)
	EventBus.experience_gained.emit(self, amount)

	# Check for level ups
	while current_experience >= get_xp_for_next_level() and level < Constants.MAX_LEVEL:
		current_experience -= get_xp_for_next_level()
		var stat_gains := level_up()
		levels_gained += 1

		# Merge stat gains
		for stat in stat_gains:
			if all_stat_gains.has(stat):
				all_stat_gains[stat] += stat_gains[stat]
			else:
				all_stat_gains[stat] = stat_gains[stat]

	return {
		"old_level": old_level,
		"new_level": level,
		"levels_gained": levels_gained,
		"stat_gains": all_stat_gains,
		"experience_added": amount
	}

func get_xp_for_next_level() -> int:
	return Constants.get_xp_for_level(level + 1)

func get_level_progress() -> float:
	var required := get_xp_for_next_level()
	if required == 0:
		return 1.0
	return float(current_experience) / float(required)

# =============================================================================
# EQUIPMENT
# =============================================================================

func equip_item(slot: Enums.EquipmentSlot, item_id: String) -> String:
	var old_item := ""

	match slot:
		Enums.EquipmentSlot.WEAPON:
			old_item = equipped_weapon
			equipped_weapon = item_id
		Enums.EquipmentSlot.ARMOR:
			old_item = equipped_armor
			equipped_armor = item_id
		Enums.EquipmentSlot.ACCESSORY_1:
			old_item = equipped_accessory_1
			equipped_accessory_1 = item_id
		Enums.EquipmentSlot.ACCESSORY_2:
			old_item = equipped_accessory_2
			equipped_accessory_2 = item_id

	equipment_changed.emit(slot, old_item, item_id)
	EventBus.equipment_changed.emit(self, slot, old_item, item_id)
	stats_changed.emit()

	return old_item

func unequip_item(slot: Enums.EquipmentSlot) -> String:
	return equip_item(slot, "")

func get_equipped_item(slot: Enums.EquipmentSlot) -> String:
	match slot:
		Enums.EquipmentSlot.WEAPON:
			return equipped_weapon
		Enums.EquipmentSlot.ARMOR:
			return equipped_armor
		Enums.EquipmentSlot.ACCESSORY_1:
			return equipped_accessory_1
		Enums.EquipmentSlot.ACCESSORY_2:
			return equipped_accessory_2
	return ""

# Equipment bonus calculation is handled by parent class CharacterBase
# which properly queries InventorySystem for equipment stats

# =============================================================================
# SKILL LEARNING
# =============================================================================

func get_learnable_skills_for_level() -> Array[String]:
	# TODO: Return skills that can be learned at current level
	return []

func auto_learn_level_skills() -> Array[String]:
	var learned: Array[String] = []
	for skill_id in get_learnable_skills_for_level():
		if skill_id not in known_skills:
			learn_skill(skill_id)
			learned.append(skill_id)
	return learned

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	var data := super.get_save_data()
	data.merge({
		"player_id": player_id,
		"current_brand": current_brand,
		"unlocked_brands": unlocked_brands,
		"current_experience": current_experience,
		"total_experience": total_experience,
		"brand_affinity": brand_affinity,
		"brand_alignment": brand_alignment,
		"equipment_decay_tracking": equipment_decay_tracking
	})
	return data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	player_id = data.get("player_id", "player")
	current_brand = data.get("current_brand", Enums.Brand.NONE)
	unlocked_brands = data.get("unlocked_brands", [Enums.Brand.NONE])
	current_experience = data.get("current_experience", 0)
	total_experience = data.get("total_experience", 0)
	brand_affinity = data.get("brand_affinity", {})
	brand_alignment = data.get("brand_alignment", {
		"SAVAGE": 20.0, "IRON": 20.0, "VENOM": 20.0,
		"SURGE": 20.0, "DREAD": 20.0, "LEECH": 20.0
	})
	equipment_decay_tracking = data.get("equipment_decay_tracking", {})
	_apply_brand_bonuses()

# =============================================================================
# FACTORY METHOD
# =============================================================================

static func create_new_player(player_name: String = "Veilbreaker") -> PlayerCharacter:
	var player := PlayerCharacter.new()
	player.character_name = player_name
	player.player_id = "player_main"
	player.level = 1
	player.current_brand = Enums.Brand.NONE
	player.unlocked_brands = [Enums.Brand.NONE]

	# Starting stats
	player.base_max_hp = 150
	player.base_max_mp = 80
	player.base_attack = 15
	player.base_defense = 12
	player.base_magic = 12
	player.base_resistance = 10
	player.base_speed = 12
	player.base_luck = 8

	player.initialize_stats()

	# Starting skills
	player.learn_skill("attack_basic")
	player.learn_skill("defend")

	return player
