extends Node
## InventorySystem: Manages player inventory, equipment, and item usage.

# =============================================================================
# SIGNALS
# =============================================================================

signal inventory_changed()
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal equipment_changed(character: CharacterBase, slot: int)

# =============================================================================
# STATE
# =============================================================================

var items: Dictionary = {}  # {item_id: quantity}
var key_items: Array[String] = []
var item_database: Dictionary = {}  # {item_id: ItemData resource}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_load_item_database()
	EventBus.emit_debug("InventorySystem initialized")

func _load_item_database() -> void:
	# Load all item resources from data/items/
	var dir := DirAccess.open("res://data/items/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item: ItemData = load("res://data/items/" + file_name)
				if item:
					item_database[item.item_id] = item
			file_name = dir.get_next()

# =============================================================================
# ITEM MANAGEMENT
# =============================================================================

func add_item(item_id: String, quantity: int = 1) -> bool:
	var item_data: ItemData = item_database.get(item_id, null)

	# Handle key items
	if item_data and item_data.is_key_item:
		if item_id not in key_items:
			key_items.append(item_id)
			item_added.emit(item_id, 1)
			inventory_changed.emit()
			EventBus.item_obtained.emit(item_id, 1)
		return true

	# Handle stackable items
	var max_stack := 99
	if item_data:
		max_stack = item_data.max_stack

	if items.has(item_id):
		var new_quantity := mini(items[item_id] + quantity, max_stack)
		var actual_added := new_quantity - items[item_id]
		items[item_id] = new_quantity

		if actual_added > 0:
			item_added.emit(item_id, actual_added)
			inventory_changed.emit()
			EventBus.item_obtained.emit(item_id, actual_added)
	else:
		items[item_id] = mini(quantity, max_stack)
		item_added.emit(item_id, items[item_id])
		inventory_changed.emit()
		EventBus.item_obtained.emit(item_id, items[item_id])

	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	# Handle key items
	if item_id in key_items:
		key_items.erase(item_id)
		item_removed.emit(item_id, 1)
		inventory_changed.emit()
		EventBus.item_removed.emit(item_id, 1)
		return true

	if not items.has(item_id):
		return false

	if items[item_id] < quantity:
		return false

	items[item_id] -= quantity

	if items[item_id] <= 0:
		items.erase(item_id)

	item_removed.emit(item_id, quantity)
	inventory_changed.emit()
	EventBus.item_removed.emit(item_id, quantity)
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	if item_id in key_items:
		return true
	return items.get(item_id, 0) >= quantity

func get_item_count(item_id: String) -> int:
	if item_id in key_items:
		return 1
	return items.get(item_id, 0)

func get_item_data(item_id: String) -> ItemData:
	return item_database.get(item_id, null)

# =============================================================================
# ITEM USAGE
# =============================================================================

func use_item(item_id: String, target: CharacterBase) -> Dictionary:
	var item_data := get_item_data(item_id)
	if not item_data:
		return {"success": false, "reason": "Unknown item"}

	if not has_item(item_id):
		return {"success": false, "reason": "Don't have item"}

	if not item_data.can_use(target):
		return {"success": false, "reason": "Cannot use on this target"}

	# Check context
	var in_battle := GameManager.is_in_battle()
	if in_battle and not item_data.usable_in_battle:
		return {"success": false, "reason": "Cannot use in battle"}
	if not in_battle and not item_data.usable_in_field:
		return {"success": false, "reason": "Cannot use outside battle"}

	# Use the item
	var result := item_data.use_on_target(target)

	# Consume if applicable
	if item_data.consumed_on_use:
		remove_item(item_id, 1)

	EventBus.item_used.emit(item_id)
	return result

# =============================================================================
# EQUIPMENT
# =============================================================================

func equip_item(character: CharacterBase, item_id: String) -> Dictionary:
	var item_data := get_item_data(item_id)
	if not item_data:
		return {"success": false, "reason": "Unknown item"}

	if item_data.item_type != Enums.ItemType.EQUIPMENT:
		return {"success": false, "reason": "Not equipment"}

	if not has_item(item_id):
		return {"success": false, "reason": "Don't have item"}

	var slot := item_data.equipment_slot
	var old_item := ""

	# Get current equipment
	match slot:
		Enums.EquipmentSlot.WEAPON:
			old_item = character.equipped_weapon
			character.equipped_weapon = item_id
		Enums.EquipmentSlot.ARMOR:
			old_item = character.equipped_armor
			character.equipped_armor = item_id
		Enums.EquipmentSlot.ACCESSORY_1:
			old_item = character.equipped_accessory_1
			character.equipped_accessory_1 = item_id
		Enums.EquipmentSlot.ACCESSORY_2:
			old_item = character.equipped_accessory_2
			character.equipped_accessory_2 = item_id

	# Remove new item from inventory
	remove_item(item_id)

	# Add old item back to inventory
	if old_item != "":
		add_item(old_item)

	# Apply/remove stat bonuses
	if old_item != "":
		_remove_equipment_stats(character, old_item)
	_apply_equipment_stats(character, item_id)

	equipment_changed.emit(character, slot)
	EventBus.equipment_changed.emit(character, slot, old_item, item_id)

	return {"success": true, "old_item": old_item}

func unequip_item(character: CharacterBase, slot: Enums.EquipmentSlot) -> Dictionary:
	var current_item := ""

	match slot:
		Enums.EquipmentSlot.WEAPON:
			current_item = character.equipped_weapon
			character.equipped_weapon = ""
		Enums.EquipmentSlot.ARMOR:
			current_item = character.equipped_armor
			character.equipped_armor = ""
		Enums.EquipmentSlot.ACCESSORY_1:
			current_item = character.equipped_accessory_1
			character.equipped_accessory_1 = ""
		Enums.EquipmentSlot.ACCESSORY_2:
			current_item = character.equipped_accessory_2
			character.equipped_accessory_2 = ""

	if current_item == "":
		return {"success": false, "reason": "Nothing equipped"}

	# Remove stats
	_remove_equipment_stats(character, current_item)

	# Add to inventory
	add_item(current_item)

	equipment_changed.emit(character, slot)
	EventBus.equipment_changed.emit(character, slot, current_item, "")

	return {"success": true, "item": current_item}

func _apply_equipment_stats(character: CharacterBase, item_id: String) -> void:
	var item_data := get_item_data(item_id)
	if not item_data:
		return

	for stat in item_data.stat_bonuses:
		var amount: int = item_data.stat_bonuses[stat]
		character.add_stat_modifier(stat, amount, 9999, "equipment_%s" % item_id)

func _remove_equipment_stats(character: CharacterBase, item_id: String) -> void:
	# Remove modifiers with matching source
	var source_key := "equipment_%s" % item_id
	for stat in character.stat_modifiers.keys():
		var mods: Array = character.stat_modifiers[stat]
		for i in range(mods.size() - 1, -1, -1):
			if mods[i].get("source", "") == source_key:
				mods.remove_at(i)

# =============================================================================
# QUERIES
# =============================================================================

func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for item_id in items:
		result.append({
			"item_id": item_id,
			"quantity": items[item_id],
			"data": get_item_data(item_id)
		})

	return result

func get_items_by_type(item_type: Enums.ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for item_id in items:
		var data := get_item_data(item_id)
		if data and data.item_type == item_type:
			result.append({
				"item_id": item_id,
				"quantity": items[item_id],
				"data": data
			})

	return result

func get_key_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item_id in key_items:
		var data := get_item_data(item_id)
		if data:
			result.append(data)
	return result

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"items": items.duplicate(),
		"key_items": key_items.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	items = data.get("items", {})
	key_items = data.get("key_items", [])
	inventory_changed.emit()
