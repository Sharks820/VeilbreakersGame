class_name DebugHelpers
extends RefCounted
## DebugHelpers: Centralized debug logging and formatting functions.
## Eliminates 45+ duplicate print/log patterns across the codebase.

# =============================================================================
# LOGGING TOGGLE (for release builds)
# =============================================================================

## Master debug flag - set to false to disable all debug output
const DEBUG_ENABLED := true

## Category-specific toggles
const LOG_BATTLE_UI := true
const LOG_COMBAT_LOG := true
const LOG_BATTLE_MANAGER := true
const LOG_GAME_MANAGER := true
const LOG_VERA_SYSTEM := true
const LOG_ANIMATION := true

# =============================================================================
# CORE LOGGING
# =============================================================================


## Generic debug log with tag
static func log_tagged(tag: String, message: String) -> void:
	if DEBUG_ENABLED:
		print("[%s] %s" % [tag, message])


## Log to EventBus debug (uses ErrorLogger if available)
static func log_event(message: String) -> void:
	if DEBUG_ENABLED:
		EventBus.emit_debug(message)


# =============================================================================
# BATTLE UI LOGGING
# =============================================================================


## Log battle UI state change
static func log_ui_state(state_name: String, context: String = "") -> void:
	if DEBUG_ENABLED and LOG_BATTLE_UI:
		if context.is_empty():
			print("[BATTLE_UI] State: %s" % state_name)
		else:
			print("[BATTLE_UI] State: %s - %s" % [state_name, context])


## Log battle UI action for character
static func log_ui_character_action(
	action: String, character_name: String, is_protagonist: bool = false
) -> void:
	if DEBUG_ENABLED and LOG_BATTLE_UI:
		print(
			(
				"[BATTLE_UI] %s - character: %s, is_protagonist: %s"
				% [action, character_name, is_protagonist]
			)
		)


## Log battle UI setup
static func log_ui_setup(player_count: int, enemy_count: int) -> void:
	if DEBUG_ENABLED and LOG_BATTLE_UI:
		print(
			(
				"[BATTLE_UI] setup_battle called with %d players, %d enemies"
				% [player_count, enemy_count]
			)
		)


## Log waiting for input
static func log_ui_waiting(character_name: String, is_protagonist: bool) -> void:
	if DEBUG_ENABLED and LOG_BATTLE_UI:
		print(
			(
				"[BATTLE_UI] Waiting for input - character: %s, is_protagonist: %s"
				% [character_name, is_protagonist]
			)
		)


# =============================================================================
# COMBAT LOG LOGGING
# =============================================================================


## Log action started
static func log_combat_action_started(character_name: String, action: int) -> void:
	if DEBUG_ENABLED and LOG_COMBAT_LOG:
		print("[COMBAT_LOG] Action started - character: %s, action: %d" % [character_name, action])


## Log action for skill usage
static func log_combat_skill_use(character_name: String, action_name: String) -> void:
	if DEBUG_ENABLED and LOG_COMBAT_LOG:
		print("[COMBAT_LOG] %s uses %s" % [character_name, action_name])


## Log miss
static func log_combat_miss(attacker_name: String, target_name: String) -> void:
	if DEBUG_ENABLED and LOG_COMBAT_LOG:
		print("[COMBAT_LOG] MISS: %s -> %s" % [attacker_name, target_name])


## Log damage dealt
static func log_combat_damage(target_name: String, damage: int, is_critical: bool) -> void:
	if DEBUG_ENABLED and LOG_COMBAT_LOG:
		print(
			"[COMBAT_LOG] DAMAGE: %s took %d damage (crit: %s)" % [target_name, damage, is_critical]
		)


## Log healing done
static func log_combat_heal(target_name: String, amount: int) -> void:
	if DEBUG_ENABLED and LOG_COMBAT_LOG:
		print("[COMBAT_LOG] HEAL: %s healed %d" % [target_name, amount])


## Log action result
static func log_combat_result(character_name: String, action: int, result_keys: Array) -> void:
	if DEBUG_ENABLED and LOG_COMBAT_LOG:
		print(
			(
				"[COMBAT_LOG] Action executed - character: %s, action: %d, result keys: %s"
				% [character_name, action, result_keys]
			)
		)


# =============================================================================
# BATTLE MANAGER LOGGING
# =============================================================================


## Log capture success
static func log_capture_success(
	monster_name: String, method_name: String, capture_chance: float
) -> void:
	if DEBUG_ENABLED and LOG_BATTLE_MANAGER:
		EventBus.emit_debug(
			(
				"%s was captured via %s! (chance: %.0f%%)"
				% [monster_name, method_name, capture_chance * 100]
			)
		)


## Log capture failure
static func log_capture_failure(
	monster_name: String, method_name: String, capture_chance: float
) -> void:
	if DEBUG_ENABLED and LOG_BATTLE_MANAGER:
		EventBus.emit_debug(
			(
				"%s escaped capture via %s (chance: %.0f%%)"
				% [monster_name, method_name, capture_chance * 100]
			)
		)


## Log corruption change
static func log_corruption_change(monster_name: String, old_val: float, new_val: float) -> void:
	if DEBUG_ENABLED and LOG_BATTLE_MANAGER:
		EventBus.emit_debug("%s corruption: %.0f%% -> %.0f%%" % [monster_name, old_val, new_val])


## Log character cannot act
static func log_cannot_act(character_name: String, reason: String = "status effect") -> void:
	if DEBUG_ENABLED and LOG_BATTLE_MANAGER:
		EventBus.emit_debug("%s cannot act due to %s" % [character_name, reason])


## Log status effect damage
static func log_status_damage(character_name: String, damage: int, effect_name: String) -> void:
	if DEBUG_ENABLED and LOG_BATTLE_MANAGER:
		EventBus.emit_debug("%s took %d damage from %s" % [character_name, damage, effect_name])


# =============================================================================
# ANIMATION LOGGING
# =============================================================================


## Log animation state
static func log_animation(
	sprite_name: String, animation_type: String, context: String = ""
) -> void:
	if DEBUG_ENABLED and LOG_ANIMATION:
		if context.is_empty():
			print("[BattleArena] Playing %s animation for %s" % [animation_type, sprite_name])
		else:
			print(
				(
					"[BattleArena] %s - sprite: %s, context: %s"
					% [animation_type, sprite_name, context]
				)
			)


## Log sprite sheet load error
static func log_sheet_load_error(sheet_path: String) -> void:
	if DEBUG_ENABLED and LOG_ANIMATION:
		push_warning("SpriteSheetAnimator: Failed to load sheet: %s" % sheet_path)


# =============================================================================
# GAME MANAGER LOGGING
# =============================================================================


## Log game state transition
static func log_game_state(from_state: String, to_state: String) -> void:
	if DEBUG_ENABLED and LOG_GAME_MANAGER:
		EventBus.emit_debug("Game state: %s -> %s" % [from_state, to_state])


## Log scene change
static func log_scene_change(scene_name: String) -> void:
	if DEBUG_ENABLED and LOG_GAME_MANAGER:
		EventBus.emit_debug("Scene changed to: %s" % scene_name)


# =============================================================================
# VERA SYSTEM LOGGING
# =============================================================================


## Log VERA state change
static func log_vera_state(old_state: String, new_state: String) -> void:
	if DEBUG_ENABLED and LOG_VERA_SYSTEM:
		EventBus.emit_debug("VERA state: %s -> %s" % [old_state, new_state])


## Log VERA corruption level
static func log_vera_corruption(old_level: float, new_level: float, source: String) -> void:
	if DEBUG_ENABLED and LOG_VERA_SYSTEM:
		EventBus.emit_debug("VERA corruption: %.1f -> %.1f (%s)" % [old_level, new_level, source])


# =============================================================================
# RESOURCE LOADING LOGGING
# =============================================================================


## Log resource not found
static func log_resource_missing(resource_type: String, resource_id: String) -> void:
	if DEBUG_ENABLED:
		EventBus.emit_debug("%s not found: %s" % [resource_type, resource_id])


## Log resource loaded
static func log_resource_loaded(resource_type: String, resource_id: String) -> void:
	if DEBUG_ENABLED:
		EventBus.emit_debug("%s loaded: %s" % [resource_type, resource_id])


# =============================================================================
# PERFORMANCE LOGGING
# =============================================================================


## Log performance metric
static func log_performance(label: String, elapsed_ms: float) -> void:
	if DEBUG_ENABLED:
		print("[PERF] %s: %.3f ms" % [label, elapsed_ms])


## Time a function call and log result
static func time_function(label: String, callable: Callable) -> Variant:
	var start := Time.get_ticks_msec()
	var result = callable.call()
	var elapsed := Time.get_ticks_msec() - start
	log_performance(label, elapsed)
	return result
