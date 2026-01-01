class_name PlayerCharacter
extends CharacterBase
## PlayerCharacter: Playable character with brand system and equipment.

# =============================================================================
# SIGNALS
# =============================================================================

signal experience_changed(old_value: int, new_value: int)
signal brand_changed(old_brand: int, new_brand: int)
signal equipment_changed(slot: int, old_item: String, new_item: String)

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
		Enums.Brand.BULWARK:
			return "Tank - High HP and Defense, lower Speed"
		Enums.Brand.FANG:
			return "Physical DPS - High Attack and Crit, lower Defense"
		Enums.Brand.EMBER:
			return "Fire Mage - High Magic and Speed, lower Resistance"
		Enums.Brand.FROST:
			return "Ice Control - High Magic and Defense, lower Speed"
		Enums.Brand.VOID:
			return "Dark Debuffer - High Magic and Speed, lower HP"
		Enums.Brand.RADIANT:
			return "Holy Healer - High Magic and HP, lower Attack"
	return "No brand active"

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
		"brand_affinity": brand_affinity
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
