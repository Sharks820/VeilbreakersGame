class_name SignalHelpers
extends RefCounted
## SignalHelpers: Centralized signal emission helper functions.
## Consolidates 23+ duplicate dual-signal emission patterns.
## Many systems emit both local signals AND EventBus signals - this centralizes that pattern.

# =============================================================================
# INVENTORY SIGNALS
# =============================================================================


## Emit item added signals (local + EventBus)
static func emit_item_added(local_signal: Signal, item_id: String, quantity: int) -> void:
	local_signal.emit(item_id, quantity)
	EventBus.item_obtained.emit(item_id, quantity)


## Emit item removed signals (local + EventBus)
static func emit_item_removed(local_signal: Signal, item_id: String, quantity: int) -> void:
	local_signal.emit(item_id, quantity)
	EventBus.item_removed.emit(item_id, quantity)


## Emit inventory changed with EventBus notification
static func emit_inventory_changed(inventory_signal: Signal) -> void:
	inventory_signal.emit()


## Emit equipment changed signals (local + EventBus)
static func emit_equipment_changed(
	local_signal: Signal, character: Node, slot: String, old_item: String, new_item: String
) -> void:
	local_signal.emit(character, slot)
	EventBus.equipment_changed.emit(character, slot, old_item, new_item)


# =============================================================================
# CHARACTER HEALTH SIGNALS
# =============================================================================


## Emit damage dealt signals (hp_changed + EventBus.damage_dealt)
static func emit_damage_dealt(
	hp_signal: Signal,
	source: Node,
	target: Node,
	old_hp: int,
	new_hp: int,
	damage: int,
	is_critical: bool
) -> void:
	hp_signal.emit(old_hp, new_hp)
	EventBus.damage_dealt.emit(source, target, damage, is_critical)


## Emit healing done signals (hp_changed + EventBus.healing_done)
static func emit_healing_done(
	hp_signal: Signal, source: Node, target: Node, old_hp: int, new_hp: int, heal_amount: int
) -> void:
	hp_signal.emit(old_hp, new_hp)
	EventBus.healing_done.emit(source, target, heal_amount)


## Emit character died signals (local + EventBus)
static func emit_character_died(local_signal: Signal, character: Node) -> void:
	local_signal.emit()
	EventBus.character_died.emit(character)


## Emit character revived signals (local + EventBus)
static func emit_character_revived(local_signal: Signal, character: Node) -> void:
	local_signal.emit()
	EventBus.character_revived.emit(character)


# =============================================================================
# STATUS EFFECT SIGNALS
# =============================================================================


## Emit status effect applied signals (local + EventBus)
static func emit_status_applied(
	local_signal: Signal, character: Node, effect: Enums.StatusEffect, duration: int
) -> void:
	local_signal.emit(effect)
	EventBus.status_effect_applied.emit(character, effect, duration)


## Emit status effect removed signals (local + EventBus)
static func emit_status_removed(
	local_signal: Signal, character: Node, effect: Enums.StatusEffect
) -> void:
	local_signal.emit(effect)
	EventBus.status_effect_removed.emit(character, effect)


# =============================================================================
# QUEST SIGNALS
# =============================================================================


## Emit quest started signals (local + EventBus)
static func emit_quest_started(local_signal: Signal, quest_id: String) -> void:
	local_signal.emit(quest_id)
	EventBus.quest_started.emit(quest_id)


## Emit quest updated signals (local + EventBus)
static func emit_quest_updated(
	local_signal: Signal, quest_id: String, objective_index: int
) -> void:
	local_signal.emit(quest_id, objective_index)
	EventBus.quest_objective_updated.emit(quest_id, objective_index)


## Emit quest completed signals (local + EventBus)
static func emit_quest_completed(local_signal: Signal, quest_id: String) -> void:
	local_signal.emit(quest_id)
	EventBus.quest_completed.emit(quest_id)


# =============================================================================
# PURIFICATION SIGNALS
# =============================================================================


## Emit purification started signals (local + EventBus)
static func emit_purification_started(local_signal: Signal, target: Node) -> void:
	EventBus.purification_started.emit(target)
	local_signal.emit(target)


## Emit purification success signals (local + EventBus)
static func emit_purification_success(local_signal: Signal, target: Node) -> void:
	local_signal.emit(target)
	EventBus.purification_succeeded.emit(target)


## Emit purification failure signals (local + EventBus)
static func emit_purification_failure(local_signal: Signal, target: Node) -> void:
	local_signal.emit(target)
	EventBus.purification_failed.emit(target)


## Emit purification progress signals (local + EventBus)
static func emit_purification_progress(local_signal: Signal, target: Node, progress: float) -> void:
	local_signal.emit()
	EventBus.purification_progress.emit(target, progress)


# =============================================================================
# DIALOGUE SIGNALS
# =============================================================================


## Emit dialogue choice made signals (local + EventBus)
static func emit_dialogue_choice(local_signal: Signal, choice_index: int) -> void:
	local_signal.emit(choice_index)
	EventBus.dialogue_choice_made.emit(choice_index)


## Emit dialogue ended signals (EventBus + local)
static func emit_dialogue_ended(local_signal: Signal) -> void:
	EventBus.dialogue_ended.emit()
	local_signal.emit()


# =============================================================================
# BATTLE SIGNALS
# =============================================================================


## Emit turn ended signals (local + EventBus)
static func emit_turn_ended(local_signal: Signal, character: Node) -> void:
	EventBus.turn_ended.emit(character)
	local_signal.emit(character)


## Emit battle action signals
## Uses existing EventBus signals with correct parameters
static func emit_battle_action(action_type: String, character: Node, data: Dictionary = {}) -> void:
	match action_type:
		"attack":
			# Use action_executed with ATTACK action type (0)
			EventBus.action_executed.emit(character, Enums.BattleAction.ATTACK, data)
		"skill":
			EventBus.skill_used.emit(character, data.get("skill_id", ""), data.get("targets", []))
		"defend":
			# Use action_executed with DEFEND action type (2)
			EventBus.action_executed.emit(character, Enums.BattleAction.DEFEND, data)
		"item":
			# item_used only takes item_id - emit that, then action_executed for full context
			var item_id: String = data.get("item_id", "")
			EventBus.item_used.emit(item_id)
			EventBus.action_executed.emit(character, Enums.BattleAction.ITEM, data)


# =============================================================================
# BRAND/ALIGNMENT SIGNALS
# =============================================================================


## Emit brand changed signals (local + conditional EventBus)
static func emit_brand_changed(
	local_signal: Signal,
	old_brand: Enums.Brand,
	new_brand: Enums.Brand,
	is_new_unlock: bool = false
) -> void:
	local_signal.emit(old_brand, new_brand)
	if is_new_unlock and new_brand != Enums.Brand.NONE:
		EventBus.brand_unlocked.emit(new_brand)


## Emit stats changed signal
static func emit_stats_changed(local_signal: Signal) -> void:
	local_signal.emit()


# =============================================================================
# UTILITY
# =============================================================================


## Batch emit multiple signals (for complex state changes)
static func emit_batch(signals_and_args: Array) -> void:
	for item in signals_and_args:
		if item.size() >= 1 and item[0] is Signal:
			var sig: Signal = item[0]
			var args: Array = item.slice(1) if item.size() > 1 else []
			match args.size():
				0:
					sig.emit()
				1:
					sig.emit(args[0])
				2:
					sig.emit(args[0], args[1])
				3:
					sig.emit(args[0], args[1], args[2])
				4:
					sig.emit(args[0], args[1], args[2], args[3])
				_:
					push_warning("SignalHelpers.emit_batch: Too many arguments")
