extends Node
## EventBus: Central signal hub for decoupled communication between game systems.
## All cross-system communication should go through EventBus signals.

# =============================================================================
# GAME STATE SIGNALS
# =============================================================================

signal game_state_changed(old_state: int, new_state: int)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over()

# =============================================================================
# BATTLE SIGNALS
# =============================================================================

signal battle_started(enemy_data: Array)
signal battle_ended(victory: bool, rewards: Dictionary)
signal turn_started(character: Node)
signal turn_ended(character: Node)
signal action_selected(character: Node, action: int, target: Node)
signal action_executed(character: Node, action: int, results: Dictionary)
signal damage_dealt(source: Node, target: Node, amount: int, is_critical: bool)
signal healing_done(source: Node, target: Node, amount: int)
signal character_died(character: Node)
signal character_revived(character: Node)
signal status_effect_applied(target: Node, effect: int, duration: int)
signal status_effect_removed(target: Node, effect: int)
signal status_effect_tick(target: Node, effect: int, damage: int)

# =============================================================================
# PURIFICATION SIGNALS
# =============================================================================

signal purification_started(monster: Node)
signal purification_progress(monster: Node, progress: float)
signal purification_succeeded(monster: Node)
signal purification_failed(monster: Node)
signal monster_recruited(monster: Node)
signal monster_captured(monster_id: String, monster_name: String)
signal battle_retry_requested()

# =============================================================================
# VERA SIGNALS
# =============================================================================

signal vera_corruption_changed(new_value: float, source: String)
signal vera_state_changed(old_state: int, new_state: int)
signal vera_dialogue_triggered(dialogue_id: String)
signal vera_glitch_triggered(intensity: float, duration: float)
signal vera_ability_used(ability: String)

# =============================================================================
# PROGRESSION SIGNALS
# =============================================================================

signal experience_gained(character: Node, amount: int)
signal level_up(character: Node, new_level: int, stat_gains: Dictionary)
signal path_alignment_changed(old_value: float, new_value: float)
signal brand_unlocked(brand: int)
signal skill_learned(character: Node, skill_id: String)
signal achievement_unlocked(achievement_id: String)

# =============================================================================
# INVENTORY SIGNALS
# =============================================================================

signal item_obtained(item_id: String, quantity: int)
signal item_used(item_id: String)
signal item_removed(item_id: String, quantity: int)
signal equipment_changed(character: Node, slot: int, old_item: String, new_item: String)
signal currency_changed(old_amount: int, new_amount: int)

# =============================================================================
# DIALOGUE & QUEST SIGNALS
# =============================================================================

signal dialogue_started(dialogue_id: String)
signal dialogue_line_shown(speaker: String, text: String)
signal dialogue_choice_made(choice_index: int)
signal dialogue_ended()
signal quest_started(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal story_flag_set(flag: String, value: Variant)

# =============================================================================
# SCENE & UI SIGNALS
# =============================================================================

signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene: String)
signal menu_opened(menu_type: int)
signal menu_closed(menu_type: int)
signal notification_requested(message: String, type: String)
signal tooltip_requested(text: String, position: Vector2)
signal tooltip_hidden()

# =============================================================================
# SETTINGS SIGNALS
# =============================================================================

signal settings_changed(key: String, value: Variant)

# =============================================================================
# SAVE/LOAD SIGNALS
# =============================================================================

signal save_requested(slot: int)
signal save_completed(slot: int, success: bool)
signal load_requested(slot: int)
signal load_completed(slot: int, success: bool)
signal autosave_triggered()

# =============================================================================
# AUDIO SIGNALS
# =============================================================================

signal music_change_requested(track_id: String, fade_duration: float)
signal sfx_play_requested(sfx_id: String, position: Vector2)
signal voice_play_requested(voice_id: String)
signal audio_settings_changed()

# =============================================================================
# DEBUG SIGNALS
# =============================================================================

signal debug_command_executed(command: String, args: Array)
signal debug_log(message: String, level: int)

# =============================================================================
# HELPER METHODS
# =============================================================================

func emit_notification(message: String, type: String = "info") -> void:
	notification_requested.emit(message, type)

func emit_debug(message: String, level: int = 0) -> void:
	if OS.is_debug_build():
		debug_log.emit(message, level)
		print("[DEBUG] ", message)

func emit_warning(message: String) -> void:
	if OS.is_debug_build():
		debug_log.emit(message, 1)
		push_warning("[WARN] " + message)

func emit_error(message: String) -> void:
	debug_log.emit(message, 2)
	push_error("[ERROR] " + message)
