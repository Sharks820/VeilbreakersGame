class_name BattleUIController
extends Control
## BattleUIController: Manages all battle UI elements and player input.

signal action_selected(action: Enums.BattleAction, target: CharacterBase, skill_id: String)
signal target_confirmed(target: CharacterBase)
signal target_cancelled
signal target_highlight_changed(target: CharacterBase)

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var top_bar: PanelContainer = $TopBar
@onready var turn_order_display: HBoxContainer = $TopBar/HBoxContainer/TurnOrderDisplay
@onready var battle_info_label: Label = $TopBar/HBoxContainer/BattleInfoLabel

@onready var combat_log: PanelContainer = $CombatLog
@onready var combat_log_text: RichTextLabel = $CombatLog/VBoxContainer/ScrollContainer/CombatLogText
@onready var combat_log_scroll: ScrollContainer = $CombatLog/VBoxContainer/ScrollContainer

@onready var party_panel: PanelContainer = $PartyPanel
@onready var party_status_container: HBoxContainer = $PartyPanel/VBoxContainer/PartyStatusContainer
@onready var action_menu: HBoxContainer = $PartyPanel/VBoxContainer/ActionMenu

@onready var attack_button: Button = $PartyPanel/VBoxContainer/ActionMenu/AttackButton
@onready var skill_button: Button = $PartyPanel/VBoxContainer/ActionMenu/SkillButton
@onready var purify_button: Button = $PartyPanel/VBoxContainer/ActionMenu/PurifyButton
@onready var item_button: Button = $PartyPanel/VBoxContainer/ActionMenu/ItemButton
@onready var defend_button: Button = $PartyPanel/VBoxContainer/ActionMenu/DefendButton
@onready var flee_button: Button = $PartyPanel/VBoxContainer/ActionMenu/FleeButton

@onready var enemy_panel: PanelContainer = $EnemyPanel
@onready var enemy_status_container: VBoxContainer = $EnemyPanel/VBoxContainer/EnemyStatusContainer

@onready var skill_menu: PanelContainer = $SkillMenu
@onready var skill_list: VBoxContainer = $SkillMenu/VBoxContainer/SkillList
@onready var skill_back_button: Button = $SkillMenu/VBoxContainer/BackButton

@onready var item_menu: PanelContainer = $ItemMenu
@onready var item_list: VBoxContainer = $ItemMenu/VBoxContainer/ItemList
@onready var item_back_button: Button = $ItemMenu/VBoxContainer/BackButton

@onready var target_selector: Control = $TargetSelector
@onready var target_indicator: Sprite2D = $TargetSelector/TargetIndicator
@onready var target_name_label: Label = $TargetSelector/TargetNameLabel

@onready var message_box: PanelContainer = $MessageBox
@onready var message_label: Label = $MessageBox/MessageLabel

@onready var victory_screen: ColorRect = $VictoryScreen
@onready var exp_label: Label = $VictoryScreen/VictoryPanel/VBoxContainer/RewardsContainer/EXPLabel
@onready var gold_label: Label = $VictoryScreen/VictoryPanel/VBoxContainer/RewardsContainer/GoldLabel
@onready var items_label: Label = $VictoryScreen/VictoryPanel/VBoxContainer/RewardsContainer/ItemsLabel
@onready var continue_button: Button = $VictoryScreen/VictoryPanel/VBoxContainer/ContinueButton

@onready var defeat_screen: ColorRect = $DefeatScreen
@onready var retry_button: Button = $DefeatScreen/DefeatPanel/VBoxContainer/ButtonsContainer/RetryButton
@onready var title_button: Button = $DefeatScreen/DefeatPanel/VBoxContainer/ButtonsContainer/TitleButton

# =============================================================================
# STATE
# =============================================================================

enum UIState { ACTION_SELECT, SKILL_SELECT, ITEM_SELECT, TARGET_SELECT, ANIMATING, WAITING }

var current_state: UIState = UIState.WAITING
var current_character: CharacterBase = null
var pending_action: Enums.BattleAction = Enums.BattleAction.ATTACK
var pending_skill: String = ""
var valid_targets: Array[CharacterBase] = []
var current_target_index: int = 0
var party_members: Array[CharacterBase] = []
var enemies: Array[CharacterBase] = []

var battle_manager: BattleManager = null

# Enemy tooltip state
var enemy_tooltip: PanelContainer = null
var tooltip_visible: bool = false

# Party tooltip state
var party_tooltip: PanelContainer = null

# Combat log scroll state
var user_scrolled_log: bool = false  # True if user manually scrolled
var combat_log_expanded: bool = false  # False = small, True = expanded
var combat_log_drag_handle: Button = null
var _log_dragging: bool = false
var _log_drag_start_y: float = 0.0
var _log_start_top: float = 0.0

# Turn order breathing tweens (stored to kill before recreating)
var _turn_order_tweens: Array[Tween] = []

# Sprite hitbox reference for mouse hover
var _sprite_hitboxes: Dictionary = {}  # CharacterBase -> Rect2
var _hovered_sprite_character: CharacterBase = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_hide_all_menus()
	
	# Ensure we receive input events for mouse tracking
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_PASS  # Pass events through but still receive them



	# IMMEDIATELY hide party_status_container and clear its placeholder children
	# This must happen before the first frame renders to avoid showing placeholders
	if party_status_container:
		party_status_container.visible = false
		party_status_container.hide()
		# Immediately free placeholder children from scene
		for child in party_status_container.get_children():
			child.free()  # Immediate removal, not queue_free

	# Force full-screen size and positioning for CanvasLayer compatibility
	await get_tree().process_frame
	_force_ui_layout()

	# Connect to viewport size changes for responsive UI in windowed mode
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	# Connect combat log scroll bar for smart scrolling
	if combat_log_scroll:
		var scrollbar := combat_log_scroll.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value_changed.connect(_on_combat_log_scrolled)

func _on_viewport_size_changed() -> void:
	"""Called when viewport size changes (windowed mode resize) - reposition all UI elements"""
	_force_ui_layout()

func _force_ui_layout() -> void:
	"""Force UI elements to correct positions for CanvasLayer rendering - RESPONSIVE"""
	var viewport_size := Vector2(1920, 1080)
	var queried_size := get_viewport().get_visible_rect().size
	if queried_size.x > 0 and queried_size.y > 0:
		viewport_size = queried_size

	# Set this control to fill screen
	position = Vector2.ZERO
	size = viewport_size
	visible = true

	# TopBar - top of screen, full width, 50px height
	if top_bar:
		top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		top_bar.offset_bottom = 50
		top_bar.show()

	# PartyPanel - bottom CENTER, use anchors for responsive positioning
	if party_panel:
		# Use anchor preset for bottom-center
		party_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		party_panel.anchor_left = 0.5
		party_panel.anchor_right = 0.5
		party_panel.anchor_top = 1.0
		party_panel.anchor_bottom = 1.0
		# Scale panel width based on viewport (min 600, max 900 for 6 buttons)
		var panel_width := clampf(viewport_size.x * 0.55, 750.0, 900.0)
		party_panel.offset_left = -panel_width / 2
		party_panel.offset_right = panel_width / 2
		# Taller panel to properly contain 50px buttons with padding
		party_panel.offset_top = -100
		party_panel.offset_bottom = -5
		party_panel.show()
		party_panel.visible = true
		print("[BATTLE_UI] PartyPanel positioned: size=%s, visible=%s" % [party_panel.size, party_panel.visible])

		# Hide the party status container from main panel
		if party_status_container:
			party_status_container.hide()

	# CombatLog - bottom-right corner, smaller by default (expandable)
	if combat_log:
		combat_log.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		combat_log.offset_right = -10
		combat_log.offset_bottom = -90
		_update_combat_log_size()
		combat_log.show()
		# Ensure scroll bar is visible
		if combat_log_scroll:
			combat_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		# Add drag handle if not exists
		_add_combat_log_drag_handle()

	# Hide scene-based EnemyPanel - we use dynamic sidebar instead
	if enemy_panel:
		enemy_panel.hide()

	# Create left party sidebar if not exists
	_create_left_party_sidebar(viewport_size)

func set_battle_manager(manager: BattleManager) -> void:
	battle_manager = manager
	print("[BATTLE_UI] set_battle_manager called - manager: %s" % str(manager))

	# Connect battle manager signals
	battle_manager.waiting_for_player_input.connect(_on_waiting_for_input)
	battle_manager.round_started.connect(_on_round_started)
	battle_manager.turn_started_signal.connect(_on_turn_started_update_order)
	print("[BATTLE_UI] Signals connected to battle_manager")
	battle_manager.battle_victory.connect(_on_victory)
	battle_manager.battle_defeat.connect(_on_defeat)
	battle_manager.action_animation_started.connect(_on_action_started)

	# Connect to EventBus for action results
	if not EventBus.action_executed.is_connected(_on_action_executed):
		EventBus.action_executed.connect(_on_action_executed)
	if not EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.connect(_on_level_up)

	# Connect UI signals to battle manager
	action_selected.connect(_on_action_selected)

	# Clear combat log for new battle
	clear_combat_log()

func _on_action_started(character: CharacterBase, action: int) -> void:
	var action_name := ""
	match action:
		Enums.BattleAction.ATTACK:
			action_name = "Attack"
		Enums.BattleAction.SKILL:
			action_name = "Skill"
		Enums.BattleAction.DEFEND:
			action_name = "Defend"
		Enums.BattleAction.ITEM:
			action_name = "Item"
		Enums.BattleAction.PURIFY:
			action_name = "Purify"
		Enums.BattleAction.FLEE:
			action_name = "Flee"

	log_action(character.character_name, action_name)

func _on_action_executed(character: CharacterBase, action: int, result: Dictionary) -> void:
	if result.has("is_miss") and result.is_miss:
		log_miss(character.character_name, result.get("target_name", "target"))
	elif result.has("damage") and result.damage > 0:
		var target_name: String = result.get("target_name", "target")
		var is_crit: bool = result.get("is_critical", false)
		log_damage(target_name, result.damage, is_crit)
	elif result.has("heal") and result.heal > 0:
		var target_name: String = result.get("target_name", character.character_name)
		log_heal(target_name, result.heal)

func _on_action_selected(action: Enums.BattleAction, target: CharacterBase, skill_id: String) -> void:
	if battle_manager:
		battle_manager.submit_player_action(action, target, skill_id)

func _on_waiting_for_input(character: CharacterBase) -> void:
	print("[BATTLE_UI] _on_waiting_for_input - character: %s, is_protagonist: %s" % [character.character_name, character.is_protagonist])
	start_turn(character)

func _on_round_started(round_number: int) -> void:
	print("[BATTLE_UI] _on_round_started - round: %d" % round_number)
	update_round_display(round_number)
	log_round_start(round_number)
	if battle_manager:
		print("[BATTLE_UI] Updating turn order with %d characters" % battle_manager.turn_order.size())
		update_turn_order(battle_manager.turn_order)

func _on_turn_started_update_order(character: CharacterBase) -> void:
	"""Update turn order display when a new character's turn starts"""
	if not battle_manager:
		return
	# Rebuild turn order starting from the current character
	var current_order: Array[CharacterBase] = []
	var found_current := false
	
	# First pass: add characters from current onwards
	for c in battle_manager.turn_order:
		if c == character:
			found_current = true
		if found_current and c.is_alive():
			current_order.append(c)
	
	# Second pass: add remaining characters (wrapped around for next round preview)
	for c in battle_manager.turn_order:
		if c == character:
			break
		if c.is_alive():
			current_order.append(c)
	
	if not current_order.is_empty():
		update_turn_order(current_order)

func _on_victory(rewards: Dictionary) -> void:
	var items: Array = []
	for item in rewards.get("items", []):
		items.append(item.get("item_id", "Unknown"))
	show_victory(rewards.get("experience", 0), rewards.get("currency", 0), items)

func _on_defeat() -> void:
	show_defeat()

func _connect_signals() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	skill_button.pressed.connect(_on_skill_pressed)
	purify_button.pressed.connect(_on_purify_pressed)
	item_button.pressed.connect(_on_item_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	flee_button.pressed.connect(_on_flee_pressed)

	# Connect hover effects for action buttons
	for button in [attack_button, skill_button, purify_button, item_button, defend_button, flee_button]:
		button.mouse_entered.connect(_on_action_button_hover.bind(button))
		button.mouse_exited.connect(_on_action_button_unhover.bind(button))
		button.focus_entered.connect(_on_action_button_hover.bind(button))
		button.focus_exited.connect(_on_action_button_unhover.bind(button))

	skill_back_button.pressed.connect(_on_skill_back_pressed)
	item_back_button.pressed.connect(_on_item_back_pressed)

	continue_button.pressed.connect(_on_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	title_button.pressed.connect(_on_title_pressed)

	# Status effect signals for icon updates
	EventBus.status_effect_applied.connect(_on_status_effect_changed)
	EventBus.status_effect_removed.connect(_on_status_effect_changed)
	
	# Character sprite hover signals (from battle arena)
	EventBus.character_hovered.connect(_on_character_sprite_hovered)
	EventBus.character_unhovered.connect(_on_character_sprite_unhovered)
	EventBus.target_selected.connect(_on_target_selected_from_sprite)

func _hide_all_menus() -> void:
	skill_menu.hide()
	item_menu.hide()
	target_selector.hide()
	message_box.hide()
	victory_screen.hide()
	defeat_screen.hide()

# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	# Handle cancel/escape for various states
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			UIState.TARGET_SELECT:
				_cancel_target_selection()
				get_viewport().set_input_as_handled()
			UIState.SKILL_SELECT:
				_on_skill_back_pressed()
				get_viewport().set_input_as_handled()
			UIState.ITEM_SELECT:
				_on_item_back_pressed()
				get_viewport().set_input_as_handled()
		return
	
	# Handle right-click as cancel during target selection
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		match current_state:
			UIState.TARGET_SELECT:
				_cancel_target_selection()
				get_viewport().set_input_as_handled()
			UIState.SKILL_SELECT:
				_on_skill_back_pressed()
				get_viewport().set_input_as_handled()
			UIState.ITEM_SELECT:
				_on_item_back_pressed()
				get_viewport().set_input_as_handled()
		return
	
	# Handle target selection with arrow keys - MUST consume input to prevent focus stealing
	if current_state == UIState.TARGET_SELECT:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			_select_previous_target()
			get_viewport().set_input_as_handled()  # Prevent focus from moving
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			_select_next_target()
			get_viewport().set_input_as_handled()  # Prevent focus from moving
		elif event.is_action_pressed("ui_accept"):
			_confirm_target()
			get_viewport().set_input_as_handled()

func register_sprite_hitbox(character: CharacterBase, hitbox: Rect2) -> void:
	"""Register a character's sprite hitbox for mouse detection (called from BattleArena)"""
	_sprite_hitboxes[character] = hitbox

func clear_sprite_hitboxes() -> void:
	"""Clear all sprite hitboxes"""
	_sprite_hitboxes.clear()
	_hovered_sprite_character = null

func _check_sprite_hover_at(mouse_pos: Vector2) -> void:
	"""Check if mouse is over any character sprite hitbox (called from BattleArena)"""
	var hovered: CharacterBase = null
	
	for character in _sprite_hitboxes:
		var hitbox: Rect2 = _sprite_hitboxes[character]
		if hitbox.has_point(mouse_pos):
			hovered = character
			break
	
	# Handle hover state change
	if hovered != _hovered_sprite_character:
		# Unhover previous
		if _hovered_sprite_character:
			_on_character_sprite_unhovered(_hovered_sprite_character)
		
		# Hover new
		_hovered_sprite_character = hovered
		if _hovered_sprite_character:
			_on_character_sprite_hovered(_hovered_sprite_character)

func _check_sprite_click_at(mouse_pos: Vector2) -> void:
	"""Check if mouse clicked on a character sprite"""
	if current_state != UIState.TARGET_SELECT:
		return
	
	for character in _sprite_hitboxes:
		var hitbox: Rect2 = _sprite_hitboxes[character]
		if hitbox.has_point(mouse_pos):
			# Check if this is a valid target
			if character in valid_targets:
				var idx := valid_targets.find(character)
				if idx >= 0:
					current_target_index = idx
					_update_target_display()
					_confirm_target()
			break

# =============================================================================
# BATTLE FLOW
# =============================================================================

func setup_battle(player_party: Array, enemy_party: Array) -> void:
	# Assign to typed arrays
	party_members.clear()
	for p in player_party:
		if p is CharacterBase:
			party_members.append(p)

	enemies.clear()
	for e in enemy_party:
		if e is CharacterBase:
			enemies.append(e)

	_update_party_display()

	# Get viewport size for dynamic sidebars
	var viewport_size := Vector2(1920, 1080)
	var queried_size := get_viewport().get_visible_rect().size
	if queried_size.x > 0 and queried_size.y > 0:
		viewport_size = queried_size

	# Create both dynamic sidebars with matching positions
	_create_left_party_sidebar(viewport_size)
	_create_right_enemy_sidebar(viewport_size)

	# FORCE hide party_status_container - we use left sidebar instead
	if party_status_container:
		party_status_container.hide()
		party_status_container.visible = false
		# Also collapse its size to prevent layout issues
		party_status_container.custom_minimum_size = Vector2.ZERO
		party_status_container.size = Vector2.ZERO

func start_turn(character: CharacterBase) -> void:
	current_character = character
	print("[BATTLE_UI] start_turn called for: %s, is_protagonist: %s" % [character.character_name, character.is_protagonist])

	# Log turn start
	var is_ally := character.is_protagonist or character in party_members
	log_turn_start(character.character_name, is_ally)

	# Determine if this character should be player-controlled
	# - Protagonist: always player controlled
	# - Party monsters: player controlled unless high corruption
	var is_player_controlled := character.is_protagonist
	
	if not is_player_controlled and character in party_members:
		# Check if monster has high corruption (auto-attacks on its own)
		if character is Monster:
			var monster: Monster = character as Monster
			if monster.corruption_level < Constants.MONSTER_AUTO_ATTACK_CORRUPTION_THRESHOLD:
				# Player controls this party monster
				is_player_controlled = true
		else:
			# Non-monster party member - player controlled
			is_player_controlled = true

	# Show action menu for player-controlled characters (protagonist OR party monsters)
	if is_player_controlled:
		print("[BATTLE_UI] Character is player-controlled - showing action menu")
		show_action_menu()
	else:
		print("[BATTLE_UI] Character is AI-controlled (high corruption) - setting ANIMATING state")
		set_ui_state(UIState.ANIMATING)

func show_action_menu() -> void:
	print("[BATTLE_UI] show_action_menu called")
	set_ui_state(UIState.ACTION_SELECT)
	action_menu.show()
	print("[BATTLE_UI] action_menu.visible = %s, party_panel.visible = %s" % [action_menu.visible, party_panel.visible if party_panel else "null"])
	_update_action_buttons()
	attack_button.grab_focus()

func hide_action_menu() -> void:
	action_menu.hide()

func set_ui_state(state: UIState) -> void:
	var previous_state := current_state
	current_state = state

	match state:
		UIState.ACTION_SELECT:
			action_menu.show()
			skill_menu.hide()
			item_menu.hide()
			target_selector.hide()
			# Clear all highlights when returning to action select
			if previous_state == UIState.TARGET_SELECT:
				_clear_all_sidebar_highlights()
				target_highlight_changed.emit(null)
		UIState.SKILL_SELECT:
			skill_menu.show()
		UIState.ITEM_SELECT:
			item_menu.show()
		UIState.TARGET_SELECT:
			target_selector.show()
		UIState.ANIMATING, UIState.WAITING:
			action_menu.hide()
			skill_menu.hide()
			item_menu.hide()
			target_selector.hide()
			# Clear all highlights when action is submitted
			_clear_all_sidebar_highlights()
			target_highlight_changed.emit(null)

func _update_action_buttons() -> void:
	if current_character == null:
		return

	# Check if current character is a monster (party monster, not protagonist)
	var is_monster := current_character is Monster

	# Disable skill if silenced
	skill_button.disabled = current_character.has_status_effect(Enums.StatusEffect.SILENCE)

	# Disable purify/capture for monsters - only player characters can capture
	# Also disable if no valid targets
	if is_monster and not Constants.MONSTER_CAN_CAPTURE:
		purify_button.disabled = true
	else:
		var has_purifiable_targets := false
		for enemy in enemies:
			if enemy is Monster and enemy.can_be_purified():
				has_purifiable_targets = true
				break
		purify_button.disabled = not has_purifiable_targets

	# Disable item for monsters - only player characters can use items
	if is_monster and not Constants.MONSTER_CAN_USE_ITEMS:
		item_button.disabled = true
	else:
		# TODO: Check inventory for usable items
		item_button.disabled = false

	# Flee might be disabled in boss battles
	flee_button.disabled = _is_boss_battle()

func _is_boss_battle() -> bool:
	for enemy in enemies:
		if enemy is Monster and enemy.is_boss():
			return true
	return false

# =============================================================================
# ACTION BUTTON HANDLERS
# =============================================================================

func _on_attack_pressed() -> void:
	_reset_combat_log_scroll()  # Resume auto-scroll on user interaction
	pending_action = Enums.BattleAction.ATTACK
	pending_skill = ""
	_start_target_selection(false)  # Target enemies

func _on_skill_pressed() -> void:
	_reset_combat_log_scroll()
	_show_skill_menu()

func _on_purify_pressed() -> void:
	_reset_combat_log_scroll()
	pending_action = Enums.BattleAction.PURIFY
	pending_skill = ""
	_start_target_selection(false, true)  # Target enemies (purifiable only)

func _on_item_pressed() -> void:
	_reset_combat_log_scroll()
	_show_item_menu()

func _on_defend_pressed() -> void:
	_reset_combat_log_scroll()
	pending_action = Enums.BattleAction.DEFEND
	pending_skill = ""
	action_selected.emit(pending_action, current_character, "")
	set_ui_state(UIState.ANIMATING)

func _on_flee_pressed() -> void:
	_reset_combat_log_scroll()
	pending_action = Enums.BattleAction.FLEE
	pending_skill = ""
	action_selected.emit(pending_action, null, "")
	set_ui_state(UIState.ANIMATING)

# =============================================================================
# BUTTON HOVER EFFECTS
# =============================================================================

func _on_action_button_hover(button: Button) -> void:
	"""Highlight button on hover/focus with scale and color tween"""
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(button, "modulate", Color(1.3, 1.1, 0.9, 1.0), 0.12)
	# Ensure pivot is centered for proper scaling
	button.pivot_offset = button.size / 2

func _on_action_button_unhover(button: Button) -> void:
	"""Reset button on unhover/unfocus"""
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

# =============================================================================
# SKILL MENU
# =============================================================================

func _show_skill_menu() -> void:
	set_ui_state(UIState.SKILL_SELECT)
	_populate_skill_list()

func _populate_skill_list() -> void:
	# Clear existing
	for child in skill_list.get_children():
		child.queue_free()

	if current_character == null:
		return

	for skill_id in current_character.known_skills:
		var can_use := current_character.can_use_skill(skill_id)
		var skill_name := _get_skill_display_name(skill_id)
		var mp_cost := _get_skill_mp_cost(skill_id)

		var button := Button.new()
		if mp_cost > 0:
			button.text = "%s (%d MP)" % [skill_name, mp_cost]
		else:
			button.text = skill_name

		if can_use:
			button.pressed.connect(_on_skill_selected.bind(skill_id))
		else:
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 0.8)
		skill_list.add_child(button)

func _get_skill_display_name(skill_id: String) -> String:
	var skill_data := DataManager.get_skill(skill_id)
	if skill_data:
		return skill_data.display_name
	return skill_id.capitalize().replace("_", " ")

func _get_skill_mp_cost(skill_id: String) -> int:
	var skill_data := DataManager.get_skill(skill_id)
	if skill_data:
		return skill_data.mp_cost
	return 0

func _on_skill_selected(skill_id: String) -> void:
	pending_action = Enums.BattleAction.SKILL
	pending_skill = skill_id
	skill_menu.hide()

	# Determine target type based on skill
	var targets_allies := _skill_targets_allies(skill_id)
	_start_target_selection(targets_allies)

func _skill_targets_allies(skill_id: String) -> bool:
	var skill_data := DataManager.get_skill(skill_id)
	if skill_data:
		match skill_data.target_type:
			Enums.TargetType.SINGLE_ALLY, Enums.TargetType.ALL_ALLIES, Enums.TargetType.SELF:
				return true
			_:
				return false
	# Fallback
	return skill_id.contains("heal") or skill_id.contains("buff")

func _on_skill_back_pressed() -> void:
	skill_menu.hide()
	set_ui_state(UIState.ACTION_SELECT)
	skill_button.grab_focus()

# =============================================================================
# ITEM MENU
# =============================================================================

func _show_item_menu() -> void:
	set_ui_state(UIState.ITEM_SELECT)
	_populate_item_list()

func _populate_item_list() -> void:
	# Clear existing
	for child in item_list.get_children():
		child.queue_free()

	# Get usable items from inventory
	var battle_items := InventorySystem.get_battle_usable_items()

	if battle_items.is_empty():
		var label := Label.new()
		label.text = "No usable items"
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		item_list.add_child(label)
		return

	for item_info in battle_items:
		var item_data: ItemData = item_info.data
		var quantity: int = item_info.quantity
		var item_id: String = item_info.item_id

		var button := Button.new()
		button.text = "%s x%d" % [item_data.display_name, quantity]
		button.pressed.connect(_on_item_selected.bind(item_id))
		item_list.add_child(button)

func _populate_item_list_fallback() -> void:
	"""Fallback for when inventory is empty (test purposes)"""
	var items := ["Potion", "Ether", "Antidote"]

	for item_name in items:
		var button := Button.new()
		button.text = item_name
		button.pressed.connect(_on_item_selected.bind(item_name.to_lower()))
		item_list.add_child(button)

func _on_item_selected(item_id: String) -> void:
	pending_action = Enums.BattleAction.ITEM
	pending_skill = item_id  # Using skill field for item ID
	item_menu.hide()

	# Get item data to determine target type
	var item_data: ItemData = DataManager.get_item(item_id)
	if item_data:
		match item_data.target_type:
			Enums.TargetType.SELF:
				# Self-targeting - use current character directly
				valid_targets.clear()
				valid_targets.append(current_character)
				current_target_index = 0
				set_ui_state(UIState.TARGET_SELECT)
				_highlight_all_valid_targets(true)
				_update_target_display()
			Enums.TargetType.SINGLE_ALLY, Enums.TargetType.ALL_ALLIES:
				_start_target_selection(true)  # Target allies (BLUE)
			Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.ALL_ENEMIES, Enums.TargetType.RANDOM_ENEMY:
				# Check if this is a capture/purify item
				var is_purify := item_data.special_effect.begins_with("purify")
				_start_target_selection(false, is_purify)  # Target enemies (RED)
			Enums.TargetType.ALL:
				# Target all - default to enemies for combat items
				_start_target_selection(false)
			_:
				_start_target_selection(true)  # Default to allies
	else:
		# Fallback - most items target allies
		_start_target_selection(true)

func _on_item_back_pressed() -> void:
	item_menu.hide()
	set_ui_state(UIState.ACTION_SELECT)
	item_button.grab_focus()

# =============================================================================
# TARGET SELECTION
# =============================================================================

func _start_target_selection(target_allies: bool, purify_only: bool = false) -> void:
	set_ui_state(UIState.TARGET_SELECT)

	valid_targets.clear()

	if target_allies:
		for ally in party_members:
			if ally.is_alive():
				valid_targets.append(ally)
	else:
		for enemy in enemies:
			if enemy.is_alive():
				if purify_only:
					if enemy is Monster and enemy.can_be_purified():
						valid_targets.append(enemy)
				else:
					valid_targets.append(enemy)

	if valid_targets.is_empty():
		_cancel_target_selection()
		return

	# Highlight ALL valid targets with appropriate colors
	_highlight_all_valid_targets(target_allies)

	current_target_index = 0
	_update_target_display()

func _select_previous_target() -> void:
	if valid_targets.is_empty():
		return
	current_target_index = (current_target_index - 1 + valid_targets.size()) % valid_targets.size()
	_update_target_display()

func _select_next_target() -> void:
	if valid_targets.is_empty():
		return
	current_target_index = (current_target_index + 1) % valid_targets.size()
	_update_target_display()

func _update_target_display() -> void:
	if valid_targets.is_empty():
		return

	var target := valid_targets[current_target_index]

	# Determine if target is ally or enemy
	var is_ally := target in party_members
	var highlight_color := Color(0.4, 0.7, 1.0) if is_ally else Color(1.0, 0.4, 0.4)  # BLUE for ally, RED for enemy

	# Update target name with appropriate color highlight
	target_name_label.text = "► " + target.character_name + " ◄"
	target_name_label.add_theme_color_override("font_color", highlight_color)
	target_name_label.add_theme_font_size_override("font_size", 18)

	# Highlight target in enemy sidebar if targeting enemy
	if target in enemies:
		_highlight_enemy_in_sidebar(target)

	# Highlight target in party sidebar if targeting ally
	if is_ally:
		_highlight_ally_in_sidebar(target)

	# Emit signal for battle arena to highlight the target sprite
	target_highlight_changed.emit(target)

func _confirm_target() -> void:
	if valid_targets.is_empty():
		return

	_reset_combat_log_scroll()  # Resume auto-scroll on target confirm
	var target := valid_targets[current_target_index]
	target_selector.hide()

	# Clear all target highlights from sidebars and sprites
	_clear_all_sidebar_highlights()
	target_highlight_changed.emit(null)  # Clear sprite highlight

	action_selected.emit(pending_action, target, pending_skill)
	set_ui_state(UIState.ANIMATING)

func _cancel_target_selection() -> void:
	target_selector.hide()

	# Clear all target highlights from sidebars and sprites
	_clear_all_sidebar_highlights()
	target_highlight_changed.emit(null)  # Clear sprite highlight

	target_cancelled.emit()
	set_ui_state(UIState.ACTION_SELECT)
	attack_button.grab_focus()

# =============================================================================
# DISPLAY UPDATES
# =============================================================================

func _update_party_display() -> void:
	# Clear existing
	for child in party_status_container.get_children():
		child.queue_free()

	for member in party_members:
		var panel := _create_party_member_panel(member)
		party_status_container.add_child(panel)

func _create_party_member_panel(character: CharacterBase) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 60)

	# Style the panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	panel_style.border_color = Color(0.3, 0.25, 0.4, 1.0)
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", panel_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	# Portrait container
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(50, 50)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	portrait_style.border_color = Color(0.4, 0.35, 0.5, 1.0)
	portrait_style.border_width_top = 2
	portrait_style.border_width_bottom = 2
	portrait_style.border_width_left = 2
	portrait_style.border_width_right = 2
	portrait_style.corner_radius_top_left = 3
	portrait_style.corner_radius_top_right = 3
	portrait_style.corner_radius_bottom_left = 3
	portrait_style.corner_radius_bottom_right = 3
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_container)

	# Load portrait texture
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(46, 46)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# Try to load portrait based on character
	var portrait_path := _get_portrait_path(character)
	if portrait_path != "":
		var tex := load(portrait_path)
		if tex:
			portrait.texture = tex

	portrait_container.add_child(portrait)

	# Info container (name + bars)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))
	vbox.add_child(name_label)

	# HP Bar with styling
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(110, 14)
	hp_bar.name = "HPBar"

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	hp_fill.corner_radius_top_left = 2
	hp_fill.corner_radius_top_right = 2
	hp_fill.corner_radius_bottom_left = 2
	hp_fill.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	hp_bg.corner_radius_top_left = 2
	hp_bg.corner_radius_top_right = 2
	hp_bg.corner_radius_bottom_left = 2
	hp_bg.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	vbox.add_child(hp_bar)

	var hp_label := Label.new()
	hp_label.text = "%d/%d" % [character.current_hp, character.get_max_hp()]
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	hp_label.name = "HPLabel"
	vbox.add_child(hp_label)

	# MP Bar if character has MP
	if character.get_max_mp() > 0:
		var mp_bar := ProgressBar.new()
		mp_bar.max_value = character.get_max_mp()
		mp_bar.value = character.current_mp
		mp_bar.show_percentage = false
		mp_bar.custom_minimum_size = Vector2(110, 10)
		mp_bar.name = "MPBar"

		var mp_fill := StyleBoxFlat.new()
		mp_fill.bg_color = Color(0.2, 0.4, 0.9, 1.0)
		mp_fill.corner_radius_top_left = 2
		mp_fill.corner_radius_top_right = 2
		mp_fill.corner_radius_bottom_left = 2
		mp_fill.corner_radius_bottom_right = 2
		mp_bar.add_theme_stylebox_override("fill", mp_fill)

		var mp_bg := StyleBoxFlat.new()
		mp_bg.bg_color = Color(0.1, 0.1, 0.15, 0.9)
		mp_bg.corner_radius_top_left = 2
		mp_bg.corner_radius_top_right = 2
		mp_bg.corner_radius_bottom_left = 2
		mp_bg.corner_radius_bottom_right = 2
		mp_bar.add_theme_stylebox_override("background", mp_bg)
		vbox.add_child(mp_bar)

	# Brand display for monsters
	if character is Monster:
		var monster := character as Monster
		var brand_label := Label.new()
		brand_label.name = "BrandLabel"
		brand_label.add_theme_font_size_override("font_size", 9)

		var brand_name := _get_brand_name(monster.brand)
		var brand_color := _get_brand_color(monster.brand)
		brand_label.text = brand_name
		brand_label.add_theme_color_override("font_color", brand_color)
		vbox.add_child(brand_label)

	# Status icons container - displays active buffs/debuffs
	var status_icons := HBoxContainer.new()
	status_icons.name = "StatusIcons"
	status_icons.add_theme_constant_override("separation", 2)
	status_icons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(status_icons)

	# Store reference for updates
	character.set_meta("ui_panel", panel)
	character.set_meta("status_icons", status_icons)

	return panel

func _get_portrait_path(character: CharacterBase) -> String:
	# Check if it's a monster with a sprite
	if character is Monster:
		var monster := character as Monster
		var monster_path := "res://assets/sprites/monsters/%s.png" % monster.monster_id
		if ResourceLoader.exists(monster_path):
			return monster_path

	# Check for hero portraits
	var hero_path := "res://assets/characters/heroes/%s.png" % character.character_name.to_lower()
	if ResourceLoader.exists(hero_path):
		return hero_path

	# Default - no portrait found
	return ""

func _update_enemy_sidebar() -> void:
	"""Populate the enemy sidebar with all enemies"""
	# Clear existing enemy entries
	for child in enemy_status_container.get_children():
		child.queue_free()

	for enemy in enemies:
		var panel := _create_enemy_slot_panel(enemy)
		enemy_status_container.add_child(panel)

func _create_enemy_slot_panel(enemy: CharacterBase) -> PanelContainer:
	"""Create a panel for one enemy in the sidebar"""
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 80)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Style the panel with red-tinted border for enemies
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.1, 0.1, 0.85)
	panel_style.border_color = Color(0.5, 0.25, 0.25, 1.0)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	# Connect hover signals for tooltip
	panel.mouse_entered.connect(_on_enemy_panel_hover.bind(enemy, panel))
	panel.mouse_exited.connect(_on_enemy_panel_unhover)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	panel.add_child(hbox)

	# Portrait container
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(45, 45)
	portrait_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.2, 0.1, 0.1, 1.0)
	portrait_style.border_color = Color(0.6, 0.3, 0.3, 1.0)
	portrait_style.set_border_width_all(2)
	portrait_style.set_corner_radius_all(3)
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_container)

	# Load portrait texture
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(41, 41)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent

	var portrait_path := _get_portrait_path(enemy)
	if portrait_path != "":
		var tex := load(portrait_path)
		if tex:
			portrait.texture = tex
	portrait_container.add_child(portrait)

	# Info container (name + bars)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.text = enemy.character_name
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.8, 1.0))
	vbox.add_child(name_label)

	# HP Bar - red themed
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = enemy.get_max_hp()
	hp_bar.value = enemy.current_hp
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(120, 12)
	hp_bar.name = "HPBar"
	hp_bar.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.2, 0.2, 1.0)  # Red for enemies
	hp_fill.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	hp_bg.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	vbox.add_child(hp_bar)

	var hp_label := Label.new()
	hp_label.text = "%d/%d" % [enemy.current_hp, enemy.get_max_hp()]
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.6, 1.0))
	hp_label.name = "HPLabel"
	hp_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	vbox.add_child(hp_label)

	# Corruption bar for monsters
	if enemy is Monster:
		var monster := enemy as Monster
		var corruption_bar := ProgressBar.new()
		corruption_bar.max_value = 100.0
		var corruption_percent := (monster.corruption_level / monster.max_corruption) * 100.0
		corruption_bar.value = corruption_percent
		corruption_bar.show_percentage = false
		corruption_bar.custom_minimum_size = Vector2(120, 8)
		corruption_bar.name = "CorruptionBar"
		corruption_bar.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent

		var corruption_fill := StyleBoxFlat.new()
		corruption_fill.bg_color = Color(0.5, 0.1, 0.6, 1.0)  # Purple for corruption
		corruption_fill.set_corner_radius_all(2)
		corruption_bar.add_theme_stylebox_override("fill", corruption_fill)

		var corruption_bg := StyleBoxFlat.new()
		corruption_bg.bg_color = Color(0.1, 0.05, 0.1, 0.9)
		corruption_bg.set_corner_radius_all(2)
		corruption_bar.add_theme_stylebox_override("background", corruption_bg)
		vbox.add_child(corruption_bar)

		# Brand display
		var brand_label := Label.new()
		brand_label.name = "BrandLabel"
		brand_label.add_theme_font_size_override("font_size", 9)
		brand_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent

		var brand_name := _get_brand_name(monster.brand)
		var brand_color := _get_brand_color(monster.brand)
		brand_label.text = brand_name
		brand_label.add_theme_color_override("font_color", brand_color)
		vbox.add_child(brand_label)

	# Status icons container - displays active buffs/debuffs
	var status_icons := HBoxContainer.new()
	status_icons.name = "StatusIcons"
	status_icons.add_theme_constant_override("separation", 2)
	status_icons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	status_icons.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	vbox.add_child(status_icons)

	# Store reference for updates
	enemy.set_meta("ui_panel", panel)
	enemy.set_meta("status_icons", status_icons)

	return panel

func _highlight_all_valid_targets(target_allies: bool) -> void:
	"""Highlight ALL valid targets - RED for enemies, BLUE for allies"""
	if target_allies:
		# Highlight all valid ally targets in BLUE
		for ally in party_members:
			if ally in valid_targets:
				_set_panel_highlight(ally, "sidebar_panel", Color(0.3, 0.5, 1.0, 1.0), 2)  # Blue glow
	else:
		# Highlight all valid enemy targets in RED
		for enemy in enemies:
			if enemy in valid_targets:
				_set_panel_highlight(enemy, "ui_panel", Color(1.0, 0.3, 0.3, 1.0), 2)  # Red glow

func _highlight_enemy_in_sidebar(target: CharacterBase) -> void:
	"""Highlight the SELECTED enemy target (brighter red), others stay dimmer red"""
	for enemy in enemies:
		if enemy.has_meta("ui_panel"):
			var panel: PanelContainer = enemy.get_meta("ui_panel")
			if is_instance_valid(panel):
				var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					if enemy == target:
						# SELECTED - bright red border + glow effect
						style.border_color = Color(1.0, 0.2, 0.2, 1.0)
						style.set_border_width_all(4)
						style.shadow_color = Color(1.0, 0.0, 0.0, 0.6)
						style.shadow_size = 8
					elif enemy in valid_targets:
						# Valid but not selected - dimmer red
						style.border_color = Color(0.8, 0.3, 0.3, 1.0)
						style.set_border_width_all(2)
						style.shadow_color = Color(1.0, 0.0, 0.0, 0.3)
						style.shadow_size = 4
					else:
						# Not targetable - normal border
						style.border_color = Color(0.5, 0.25, 0.25, 1.0)
						style.set_border_width_all(1)
						style.shadow_size = 0

func _highlight_ally_in_sidebar(target: CharacterBase) -> void:
	"""Highlight the SELECTED ally target (brighter blue), others stay dimmer blue"""
	for ally in party_members:
		# Check sidebar_panel (left sidebar) - this is the main ally panel
		if ally.has_meta("sidebar_panel"):
			var panel: PanelContainer = ally.get_meta("sidebar_panel")
			if is_instance_valid(panel):
				var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					if ally == target:
						# SELECTED - bright blue border + glow effect
						style.border_color = Color(0.2, 0.6, 1.0, 1.0)
						style.set_border_width_all(4)
						style.shadow_color = Color(0.0, 0.5, 1.0, 0.6)
						style.shadow_size = 8
					elif ally in valid_targets:
						# Valid but not selected - dimmer blue
						style.border_color = Color(0.3, 0.5, 0.8, 1.0)
						style.set_border_width_all(2)
						style.shadow_color = Color(0.0, 0.4, 1.0, 0.3)
						style.shadow_size = 4
					else:
						# Not targetable - normal border
						style.border_color = Color(0.3, 0.5, 0.4, 1.0)
						style.set_border_width_all(1)
						style.shadow_size = 0

func _set_panel_highlight(character: CharacterBase, meta_key: String, color: Color, width: int) -> void:
	"""Helper to set panel highlight by meta key"""
	if character.has_meta(meta_key):
		var panel: PanelContainer = character.get_meta(meta_key)
		if is_instance_valid(panel):
			var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
			if style:
				style.border_color = color
				style.set_border_width_all(width)
				style.shadow_color = Color(color.r, color.g, color.b, 0.4)
				style.shadow_size = 6

func _clear_all_sidebar_highlights() -> void:
	"""Clear all target highlights from both enemy and party sidebars"""
	# Reset enemy sidebar to normal state
	for enemy in enemies:
		if enemy.has_meta("ui_panel"):
			var panel: PanelContainer = enemy.get_meta("ui_panel")
			if is_instance_valid(panel):
				var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.border_color = Color(0.5, 0.25, 0.25, 1.0)
					style.set_border_width_all(1)
					style.shadow_size = 0  # Clear shadow

	# Reset party sidebar to normal state
	for ally in party_members:
		if ally.has_meta("ui_panel"):
			var panel: PanelContainer = ally.get_meta("ui_panel")
			if is_instance_valid(panel):
				var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.border_color = Color(0.3, 0.25, 0.4, 1.0)
					style.set_border_width_all(1)
					style.shadow_size = 0  # Clear shadow

		# Also check sidebar_panel (left sidebar)
		if ally.has_meta("sidebar_panel"):
			var panel: PanelContainer = ally.get_meta("sidebar_panel")
			if is_instance_valid(panel):
				var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.border_color = Color(0.3, 0.5, 0.4, 1.0)
					style.set_border_width_all(1)
					style.shadow_size = 0  # Clear shadow

func update_enemy_hp(enemy: CharacterBase) -> void:
	"""Update a single enemy's HP display in the sidebar"""
	if enemy.has_meta("ui_panel"):
		var panel: PanelContainer = enemy.get_meta("ui_panel")
		if is_instance_valid(panel):
			var hp_bar := panel.find_child("HPBar", true, false) as ProgressBar
			var hp_label := panel.find_child("HPLabel", true, false) as Label
			if hp_bar:
				hp_bar.value = enemy.current_hp
			if hp_label:
				hp_label.text = "%d/%d" % [enemy.current_hp, enemy.get_max_hp()]

func _get_status_effect_icon_path(effect: Enums.StatusEffect) -> String:
	"""Map status effects to icon paths"""
	match effect:
		# Debuffs
		Enums.StatusEffect.POISON:
			return "res://assets/ui/icons/debuffs/poison.png"
		Enums.StatusEffect.BURN:
			return "res://assets/ui/icons/debuffs/burn.png"
		Enums.StatusEffect.FREEZE:
			return "res://assets/ui/icons/debuffs/freeze.png"
		Enums.StatusEffect.PARALYSIS:
			return "res://assets/ui/icons/debuffs/stun.png"
		Enums.StatusEffect.SLEEP:
			return "res://assets/ui/icons/debuffs/sleep.png"
		Enums.StatusEffect.CONFUSION:
			return "res://assets/ui/icons/debuffs/confuse.png"
		Enums.StatusEffect.BLIND:
			return "res://assets/ui/icons/debuffs/blind.png"
		Enums.StatusEffect.SILENCE:
			return "res://assets/ui/icons/debuffs/silence.png"
		Enums.StatusEffect.BLEED:
			return "res://assets/ui/icons/debuffs/bleed.png"
		Enums.StatusEffect.CORRUPTED:
			return "res://assets/ui/icons/debuffs/corruption.png"
		Enums.StatusEffect.SORROW:
			return "res://assets/ui/icons/debuffs/curse.png"
		Enums.StatusEffect.ATTACK_DOWN:
			return "res://assets/ui/icons/debuffs/attack_down.png"
		Enums.StatusEffect.DEFENSE_DOWN:
			return "res://assets/ui/icons/debuffs/defense_down.png"
		Enums.StatusEffect.SPEED_DOWN:
			return "res://assets/ui/icons/debuffs/speed_down.png"
		# Buffs
		Enums.StatusEffect.REGEN:
			return "res://assets/ui/icons/buffs/regen.png"
		Enums.StatusEffect.SHIELD:
			return "res://assets/ui/icons/buffs/shield.png"
		Enums.StatusEffect.ATTACK_UP:
			return "res://assets/ui/icons/buffs/attack_up.png"
		Enums.StatusEffect.DEFENSE_UP:
			return "res://assets/ui/icons/buffs/defense_up.png"
		Enums.StatusEffect.SPEED_UP:
			return "res://assets/ui/icons/buffs/speed_up.png"
		Enums.StatusEffect.PURIFYING:
			return "res://assets/ui/icons/buffs/blessed.png"
		_:
			return ""

func _get_status_effect_name(effect: Enums.StatusEffect) -> String:
	"""Get display name for status effect tooltip"""
	return Enums.StatusEffect.keys()[effect].capitalize().replace("_", " ")


# =============================================================================
# STATUS ICON DISPLAY
# =============================================================================

func _on_status_effect_changed(target: Node, _effect: int, _extra: int = 0) -> void:
	"""Called when a status effect is applied or removed - update icons"""
	if target is CharacterBase:
		_update_character_status_icons(target as CharacterBase)


func _update_character_status_icons(character: CharacterBase) -> void:
	"""Update the status icon display for a character's panel"""
	if not character.has_meta("status_icons"):
		return

	var status_icons: HBoxContainer = character.get_meta("status_icons")
	if not is_instance_valid(status_icons):
		return

	# Clear existing icons
	for child in status_icons.get_children():
		child.queue_free()

	# Add icons for each active status effect (max 6 to prevent overflow)
	var icon_count := 0
	var max_icons := 6

	for effect_key in character.status_effects.keys():
		if icon_count >= max_icons:
			break

		var effect: Enums.StatusEffect = effect_key as Enums.StatusEffect
		var icon_path := _get_status_effect_icon_path(effect)

		if icon_path == "" or not ResourceLoader.exists(icon_path):
			continue

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = load(icon_path)

		# Add tooltip with effect name and remaining duration
		var effect_data: Dictionary = character.status_effects[effect_key]
		var duration: int = effect_data.get("duration", 0)
		var stacks: int = effect_data.get("stacks", 1)
		var tooltip := _get_status_effect_name(effect)
		if duration > 0:
			tooltip += " (%d turns)" % duration
		if stacks > 1:
			tooltip += " x%d" % stacks
		icon.tooltip_text = tooltip

		status_icons.add_child(icon)
		icon_count += 1


func _refresh_all_status_icons() -> void:
	"""Refresh status icons for all party members and enemies"""
	for member in party_members:
		_update_character_status_icons(member)
	for enemy in enemies:
		_update_character_status_icons(enemy)


func update_turn_order(order: Array[CharacterBase]) -> void:
	# Verify turn_order_display exists
	if not turn_order_display:
		push_error("[TURN ORDER] turn_order_display is NULL!")
		return

	# Kill existing breathing tweens to prevent memory leak
	for tween in _turn_order_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_turn_order_tweens.clear()

	# Clear existing children immediately (don't await - causes issues)
	for child in turn_order_display.get_children():
		child.free()

	if order.is_empty():
		return

	for i in range(mini(8, order.size())):
		var character := order[i]
		# Check if ally by checking protagonist flag OR if in player_party from battle_manager
		var is_ally := character.is_protagonist or (battle_manager and character in battle_manager.player_party)

		# Create portrait container - compact 36x36
		var portrait_panel := PanelContainer.new()
		portrait_panel.custom_minimum_size = Vector2(36, 36)

		# Create stylebox for colored border
		var style := StyleBoxFlat.new()
		if i == 0:
			# Current turn - bright yellow border
			style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
			style.border_color = Color.YELLOW
			style.set_border_width_all(2)
		elif is_ally:
			# Ally - green border
			style.bg_color = Color(0.1, 0.15, 0.1, 0.9)
			style.border_color = Color(0.3, 0.9, 0.3)  # Green
			style.set_border_width_all(1)
		else:
			# Enemy - red border
			style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
			style.border_color = Color(0.9, 0.3, 0.3)  # Red
			style.set_border_width_all(1)

		style.set_corner_radius_all(3)
		portrait_panel.add_theme_stylebox_override("panel", style)

		# Portrait TextureRect with actual character sprite
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(32, 32)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# Load actual portrait texture
		var portrait_path := _get_portrait_path(character)
		if portrait_path != "":
			var tex := load(portrait_path)
			if tex:
				portrait.texture = tex

		# Fallback to colored placeholder if no texture found
		if portrait.texture == null:
			var fallback := ColorRect.new()
			fallback.custom_minimum_size = Vector2(32, 32)
			fallback.color = Color(0.3, 0.8, 0.3) if is_ally else Color(0.8, 0.3, 0.3)
			fallback.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			portrait_panel.add_child(fallback)
		else:
			portrait_panel.add_child(portrait)

		turn_order_display.add_child(portrait_panel)

		# Add breathing animation - subtle pulse effect
		var base_color: Color
		var glow_color: Color
		if i == 0:
			# Current turn - yellow breathing
			base_color = Color(1.0, 1.0, 1.0, 1.0)
			glow_color = Color(1.3, 1.2, 0.9, 1.0)
		elif is_ally:
			# Ally - green breathing
			base_color = Color(1.0, 1.0, 1.0, 1.0)
			glow_color = Color(0.9, 1.2, 0.9, 1.0)
		else:
			# Enemy - red breathing
			base_color = Color(1.0, 1.0, 1.0, 1.0)
			glow_color = Color(1.2, 0.9, 0.9, 1.0)

		var breathe_tween := create_tween().set_loops()
		breathe_tween.tween_property(portrait_panel, "modulate", glow_color, 0.8).set_ease(Tween.EASE_IN_OUT)
		breathe_tween.tween_property(portrait_panel, "modulate", base_color, 0.8).set_ease(Tween.EASE_IN_OUT)
		_turn_order_tweens.append(breathe_tween)

		# Add arrow between characters (except after last)
		if i < mini(7, order.size() - 1):
			var arrow := Label.new()
			arrow.text = "►"
			arrow.add_theme_font_size_override("font_size", 10)
			arrow.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			turn_order_display.add_child(arrow)

func update_round_display(round_number: int) -> void:
	battle_info_label.text = "Round %d" % round_number

# =============================================================================
# MESSAGES
# =============================================================================

func show_message(text: String, duration: float = 2.0) -> void:
	message_label.text = text
	message_box.show()

	if duration > 0:
		await get_tree().create_timer(duration).timeout
		message_box.hide()

func hide_message() -> void:
	message_box.hide()

# =============================================================================
# COMBAT LOG
# =============================================================================

func log_action(attacker_name: String, action_name: String, target_name: String = "") -> void:
	var entry := ""
	if target_name.is_empty():
		entry = "[color=white]%s[/color] uses [color=cyan]%s[/color]" % [attacker_name, action_name]
	else:
		entry = "[color=white]%s[/color] uses [color=cyan]%s[/color] on [color=yellow]%s[/color]" % [attacker_name, action_name, target_name]
	_append_to_log(entry)

func log_damage(target_name: String, amount: int, is_critical: bool = false) -> void:
	var color := "red" if not is_critical else "orange"
	var crit_text := " [color=orange]CRITICAL![/color]" if is_critical else ""
	var entry := "[color=%s]%s takes %d damage!%s[/color]" % [color, target_name, amount, crit_text]
	_append_to_log(entry)

func log_heal(target_name: String, amount: int) -> void:
	var entry := "[color=green]%s recovers %d HP![/color]" % [target_name, amount]
	_append_to_log(entry)

func log_miss(attacker_name: String, target_name: String) -> void:
	var entry := "[color=gray]%s's attack missed %s![/color]" % [attacker_name, target_name]
	_append_to_log(entry)

func log_status_effect(target_name: String, effect_name: String, applied: bool = true) -> void:
	var action := "afflicted with" if applied else "recovered from"
	var color := "purple" if applied else "lime"
	var entry := "[color=%s]%s is %s %s![/color]" % [color, target_name, action, effect_name]
	_append_to_log(entry)

func log_defeat(character_name: String) -> void:
	var entry := "[color=red][b]%s has been defeated![/b][/color]" % character_name
	_append_to_log(entry)

func log_turn_start(character_name: String, is_ally: bool) -> void:
	var color := "lime" if is_ally else "salmon"
	var entry := "\n[color=%s]>>> %s's turn <<<[/color]" % [color, character_name]
	_append_to_log(entry)

func log_round_start(round_number: int) -> void:
	var entry := "\n[color=gold]========== ROUND %d ==========[/color]" % round_number
	_append_to_log(entry)

func _append_to_log(entry: String) -> void:
	combat_log_text.append_text("\n" + entry)
	# Auto-scroll to bottom only if user hasn't scrolled up
	await get_tree().process_frame
	var scrollbar := combat_log_scroll.get_v_scroll_bar()
	var at_bottom := scrollbar.value >= scrollbar.max_value - 30  # 30px tolerance
	if at_bottom:
		combat_log_scroll.scroll_vertical = scrollbar.max_value

func clear_combat_log() -> void:
	combat_log_text.clear()
	combat_log_text.append_text("[color=gray]Battle started...[/color]")

# =============================================================================
# BATTLE END SCREENS
# =============================================================================

func show_victory(exp_gained: int, gold_gained: int, items_obtained: Array) -> void:
	set_ui_state(UIState.WAITING)
	victory_screen.show()

	exp_label.text = "EXP Gained: %d" % exp_gained
	gold_label.text = "Gold: %d" % gold_gained

	var item_text := "Items: "
	if items_obtained.is_empty():
		item_text += "None"
	else:
		item_text += ", ".join(items_obtained)
	items_label.text = item_text

	continue_button.grab_focus()

func show_defeat() -> void:
	set_ui_state(UIState.WAITING)
	defeat_screen.show()
	retry_button.grab_focus()

func _on_continue_pressed() -> void:
	victory_screen.hide()
	# [DEV] For testing: return to overworld after victory
	# In production, this would return to the location where battle was triggered
	SceneManager.go_to_overworld()

func _on_retry_pressed() -> void:
	defeat_screen.hide()
	EventBus.battle_retry_requested.emit()

func _on_title_pressed() -> void:
	defeat_screen.hide()
	SceneManager.goto_main_menu()

func _on_level_up(character: CharacterBase, new_level: int, stat_gains: Dictionary) -> void:
	## Display level up notification during battle
	_show_level_up_notification(character, new_level, stat_gains)
	log_level_up(character.character_name, new_level)

func _show_level_up_notification(character: CharacterBase, new_level: int, stat_gains: Dictionary) -> void:
	## Creates a dramatic level up popup
	var popup := PanelContainer.new()
	popup.name = "LevelUpPopup"
	popup.z_index = 100

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.3, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	popup.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	popup.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "LEVEL UP!"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Character name and level
	var name_label := Label.new()
	name_label.text = "%s → Level %d" % [character.character_name, new_level]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Stat gains
	var stats_container := HBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 15)
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stats_container)

	for stat_name in stat_gains:
		var gain: int = stat_gains[stat_name]
		if gain > 0:
			var stat_label := Label.new()
			stat_label.text = "%s +%d" % [stat_name.to_upper().left(3), gain]
			stat_label.add_theme_font_size_override("font_size", 12)
			stat_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			stats_container.add_child(stat_label)

	add_child(popup)

	# Position in center of screen
	await get_tree().process_frame
	var viewport_size := get_viewport_rect().size
	popup.position = (viewport_size - popup.size) / 2
	popup.position.y -= 50  # Slightly above center

	# Start off-screen and scale 0
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.5, 0.5)
	popup.pivot_offset = popup.size / 2

	# Animate in
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Hold and fade out
	tween.set_parallel(false)
	tween.tween_interval(1.5)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)

func log_level_up(character_name: String, new_level: int) -> void:
	## Logs level up to combat log
	var msg := "[color=gold]★ %s reached Level %d! ★[/color]" % [character_name, new_level]
	combat_log_text.append_text("\n" + msg)
	_auto_scroll_combat_log()

# =============================================================================
# ANIMATION SUPPORT
# =============================================================================

func show_damage_number(amount: int, position: Vector2, is_critical: bool = false, is_heal: bool = false) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.position = position

	if is_heal:
		label.add_theme_color_override("font_color", Color.GREEN)
	elif is_critical:
		label.add_theme_color_override("font_color", Color.ORANGE)
		label.scale = Vector2(1.5, 1.5)
	else:
		label.add_theme_color_override("font_color", Color.WHITE)

	add_child(label)

	# Animate floating up
	var tween := create_tween()
	tween.parallel().tween_property(label, "position:y", position.y - 50, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.tween_callback(label.queue_free)

func flash_character(character: CharacterBase, color: Color = Color.WHITE) -> void:
	# TODO: Implement character sprite flash effect
	pass

func shake_screen(intensity: float = 5.0, duration: float = 0.2) -> void:
	# TODO: Implement screen shake
	pass

# =============================================================================
# BRAND DISPLAY
# =============================================================================

func _get_brand_name(brand: Enums.Brand) -> String:
	"""Get display name for monster brand"""
	match brand:
		# Pure Brands
		Enums.Brand.SAVAGE:
			return "⚔ SAVAGE"
		Enums.Brand.IRON:
			return "🛡 IRON"
		Enums.Brand.VENOM:
			return "☠ VENOM"
		Enums.Brand.SURGE:
			return "⚡ SURGE"
		Enums.Brand.DREAD:
			return "💀 DREAD"
		Enums.Brand.LEECH:
			return "🩸 LEECH"
		# Hybrid Brands
		Enums.Brand.BLOODIRON:
			return "⚔🛡 BLOODIRON"
		Enums.Brand.CORROSIVE:
			return "🛡☠ CORROSIVE"
		Enums.Brand.VENOMSTRIKE:
			return "☠⚡ VENOMSTRIKE"
		Enums.Brand.TERRORFLUX:
			return "⚡💀 TERRORFLUX"
		Enums.Brand.NIGHTLEECH:
			return "💀🩸 NIGHTLEECH"
		Enums.Brand.RAVENOUS:
			return "🩸⚔ RAVENOUS"
		_:
			return "— NONE"

func _get_brand_color(brand: Enums.Brand) -> Color:
	"""Get color for monster brand display"""
	match brand:
		# Pure Brands
		Enums.Brand.SAVAGE:
			return Color(1.0, 0.4, 0.3)  # Red-orange - raw power
		Enums.Brand.IRON:
			return Color(0.6, 0.7, 0.8)  # Steel blue - defense
		Enums.Brand.VENOM:
			return Color(0.4, 0.9, 0.3)  # Toxic green - poison/debuffs
		Enums.Brand.SURGE:
			return Color(0.3, 0.8, 1.0)  # Electric blue - speed/energy
		Enums.Brand.DREAD:
			return Color(0.6, 0.3, 0.8)  # Dark purple - fear/mental
		Enums.Brand.LEECH:
			return Color(0.8, 0.2, 0.4)  # Blood red - life drain
		# Hybrid Brands
		Enums.Brand.BLOODIRON:
			return Color(0.85, 0.5, 0.4)  # Red-steel blend
		Enums.Brand.CORROSIVE:
			return Color(0.5, 0.8, 0.5)  # Steel-green blend
		Enums.Brand.VENOMSTRIKE:
			return Color(0.35, 0.85, 0.65)  # Green-blue blend
		Enums.Brand.TERRORFLUX:
			return Color(0.45, 0.55, 0.9)  # Blue-purple blend
		Enums.Brand.NIGHTLEECH:
			return Color(0.7, 0.25, 0.6)  # Purple-red blend
		Enums.Brand.RAVENOUS:
			return Color(0.9, 0.3, 0.35)  # Red-orange blend
		_:
			return Color(0.5, 0.5, 0.5)  # Gray for none

func _create_brand_icon(brand: Enums.Brand) -> PanelContainer:
	"""Create a colored icon indicator for the brand"""
	var icon := PanelContainer.new()
	icon.custom_minimum_size = Vector2(14, 14)

	var style := StyleBoxFlat.new()
	style.bg_color = _get_brand_color(brand)
	style.set_corner_radius_all(3)  # Slightly rounded
	style.border_color = _get_brand_color(brand).lightened(0.3)
	style.set_border_width_all(1)
	icon.add_theme_stylebox_override("panel", style)

	return icon

func _get_path_color() -> Color:
	"""Get color for player's Path based on alignment"""
	var alignment := GameManager.path_alignment if GameManager else 0.0
	if alignment > 30:
		return Color(0.9, 0.85, 0.4)  # Gold/yellow for Seraph (light path)
	elif alignment < -30:
		return Color(0.5, 0.3, 0.7)  # Purple for Shade (dark path)
	else:
		return Color(0.6, 0.6, 0.6)  # Gray for neutral/undecided

# =============================================================================
# ENEMY HOVER TOOLTIP
# =============================================================================

func _on_enemy_panel_hover(enemy: CharacterBase, panel: PanelContainer) -> void:
	"""Show tooltip with enemy details on hover, also select as target if in TARGET_SELECT"""
	_hide_enemy_tooltip()  # Hide any existing tooltip

	# If in target selection mode, hovering selects this enemy
	if current_state == UIState.TARGET_SELECT and enemy in valid_targets:
		var idx := valid_targets.find(enemy)
		if idx >= 0:
			current_target_index = idx
			_update_target_display()

	# Create tooltip panel
	enemy_tooltip = PanelContainer.new()
	enemy_tooltip.name = "EnemyTooltip"
	enemy_tooltip.custom_minimum_size = Vector2(280, 0)
	enemy_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the tooltip
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	tooltip_style.border_color = Color(0.6, 0.3, 0.4, 1.0)
	tooltip_style.set_border_width_all(2)
	tooltip_style.set_corner_radius_all(6)
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 10
	tooltip_style.content_margin_bottom = 10
	enemy_tooltip.add_theme_stylebox_override("panel", tooltip_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	enemy_tooltip.add_child(vbox)

	# Name header
	var name_label := Label.new()
	name_label.text = enemy.character_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.7))
	vbox.add_child(name_label)

	# Level and tier
	var level_label := Label.new()
	if enemy is Monster:
		var monster := enemy as Monster
		var tier_name: String = str(Enums.MonsterTier.keys()[monster.monster_tier])
		level_label.text = "Lv.%d %s" % [enemy.level, tier_name]
	else:
		level_label.text = "Level %d" % enemy.level
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(level_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.4, 0.3, 0.35))
	vbox.add_child(sep)

	# Stats section
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 16)
	stats_grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(stats_grid)

	_add_stat_row(stats_grid, "ATK", enemy.base_attack, Color(1.0, 0.5, 0.4))
	_add_stat_row(stats_grid, "DEF", enemy.base_defense, Color(0.5, 0.7, 1.0))
	_add_stat_row(stats_grid, "MAG", enemy.base_magic, Color(0.8, 0.5, 1.0))
	_add_stat_row(stats_grid, "SPD", enemy.base_speed, Color(0.5, 1.0, 0.7))

	# Monster-specific info
	if enemy is Monster:
		var monster := enemy as Monster

		# Brand info
		var sep2 := HSeparator.new()
		sep2.add_theme_color_override("separator", Color(0.4, 0.3, 0.35))
		vbox.add_child(sep2)

		var brand_info := HBoxContainer.new()
		brand_info.add_theme_constant_override("separation", 6)
		vbox.add_child(brand_info)

		var brand_title := Label.new()
		brand_title.text = "Brand:"
		brand_title.add_theme_font_size_override("font_size", 10)
		brand_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		brand_info.add_child(brand_title)

		# Brand icon (colored indicator)
		var brand_icon := _create_brand_icon(monster.brand)
		brand_info.add_child(brand_icon)

		var brand_value := Label.new()
		brand_value.text = _get_brand_name(monster.brand)
		brand_value.add_theme_font_size_override("font_size", 10)
		brand_value.add_theme_color_override("font_color", _get_brand_color(monster.brand))
		brand_info.add_child(brand_value)

		# Corruption info
		var corruption_info := HBoxContainer.new()
		corruption_info.add_theme_constant_override("separation", 8)
		vbox.add_child(corruption_info)

		var corruption_title := Label.new()
		corruption_title.text = "Corruption:"
		corruption_title.add_theme_font_size_override("font_size", 10)
		corruption_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		corruption_info.add_child(corruption_title)

		var corruption_percent := (monster.corruption_level / monster.max_corruption) * 100.0
		var corruption_value := Label.new()
		corruption_value.text = "%.0f%%" % corruption_percent
		corruption_value.add_theme_font_size_override("font_size", 10)
		corruption_value.add_theme_color_override("font_color", Color(0.6, 0.2, 0.7))
		corruption_info.add_child(corruption_value)

		# Description if available
		if monster.description != "":
			var sep3 := HSeparator.new()
			sep3.add_theme_color_override("separator", Color(0.4, 0.3, 0.35))
			vbox.add_child(sep3)

			var desc_label := Label.new()
			desc_label.text = monster.description
			desc_label.add_theme_font_size_override("font_size", 10)
			desc_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_label.custom_minimum_size.x = 256
			vbox.add_child(desc_label)

	# Position tooltip to the left of the panel
	add_child(enemy_tooltip)
	await get_tree().process_frame

	var panel_global := panel.global_position
	var tooltip_pos := Vector2(panel_global.x - enemy_tooltip.size.x - 10, panel_global.y)

	# Keep within screen bounds
	if tooltip_pos.x < 10:
		tooltip_pos.x = panel_global.x + panel.size.x + 10
	if tooltip_pos.y + enemy_tooltip.size.y > size.y - 10:
		tooltip_pos.y = size.y - enemy_tooltip.size.y - 10

	enemy_tooltip.position = tooltip_pos
	tooltip_visible = true

func _add_stat_row(grid: GridContainer, stat_name: String, value: int, color: Color) -> void:
	"""Helper to add a stat row to the tooltip grid"""
	var name_label := Label.new()
	name_label.text = stat_name + ":"
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	grid.add_child(name_label)

	var value_label := Label.new()
	value_label.text = str(value)
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", color)
	grid.add_child(value_label)

func _on_enemy_panel_unhover() -> void:
	"""Hide tooltip when mouse leaves enemy panel"""
	_hide_enemy_tooltip()

func _on_enemy_panel_clicked(event: InputEvent, enemy: CharacterBase) -> void:
	"""Handle click on enemy panel - select and confirm target"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# If in target selection mode, clicking confirms this target
		if current_state == UIState.TARGET_SELECT and enemy in valid_targets:
			var idx := valid_targets.find(enemy)
			if idx >= 0:
				current_target_index = idx
				_confirm_target()
		# If in action select, clicking enemy starts attack targeting that enemy
		elif current_state == UIState.ACTION_SELECT:
			pending_action = Enums.BattleAction.ATTACK
			_start_target_selection(false)  # Start enemy target selection
			# Select the clicked enemy
			var idx := valid_targets.find(enemy)
			if idx >= 0:
				current_target_index = idx
				_update_target_display()

func _hide_enemy_tooltip() -> void:
	"""Remove and destroy the tooltip"""
	if enemy_tooltip and is_instance_valid(enemy_tooltip):
		enemy_tooltip.queue_free()
		enemy_tooltip = null
	tooltip_visible = false

# =============================================================================
# PARTY HOVER TOOLTIP
# =============================================================================

func _on_party_panel_hover(character: CharacterBase, panel: PanelContainer) -> void:
	"""Show tooltip with party member details on hover"""
	_hide_party_tooltip()  # Hide any existing tooltip

	# Create tooltip panel
	party_tooltip = PanelContainer.new()
	party_tooltip.name = "PartyTooltip"
	party_tooltip.custom_minimum_size = Vector2(280, 0)
	party_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the tooltip with green/ally theme
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.06, 0.1, 0.08, 0.95)
	tooltip_style.border_color = Color(0.3, 0.6, 0.4, 1.0)
	tooltip_style.set_border_width_all(2)
	tooltip_style.set_corner_radius_all(6)
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 10
	tooltip_style.content_margin_bottom = 10
	party_tooltip.add_theme_stylebox_override("panel", tooltip_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	party_tooltip.add_child(vbox)

	# Name header
	var name_label := Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
	vbox.add_child(name_label)

	# Level info
	var level_label := Label.new()
	level_label.text = "Level %d" % character.level
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(level_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.3, 0.4, 0.35))
	vbox.add_child(sep)

	# HP/MP section
	var hp_info := HBoxContainer.new()
	hp_info.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_info)

	var hp_title := Label.new()
	hp_title.text = "HP:"
	hp_title.add_theme_font_size_override("font_size", 11)
	hp_title.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	hp_info.add_child(hp_title)

	var hp_value := Label.new()
	hp_value.text = "%d / %d" % [character.current_hp, character.get_max_hp()]
	hp_value.add_theme_font_size_override("font_size", 11)
	hp_value.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	hp_info.add_child(hp_value)

	# MP info if character has MP
	if character.get_max_mp() > 0:
		var mp_info := HBoxContainer.new()
		mp_info.add_theme_constant_override("separation", 8)
		vbox.add_child(mp_info)

		var mp_title := Label.new()
		mp_title.text = "MP:"
		mp_title.add_theme_font_size_override("font_size", 11)
		mp_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		mp_info.add_child(mp_title)

		var mp_value := Label.new()
		mp_value.text = "%d / %d" % [character.current_mp, character.get_max_mp()]
		mp_value.add_theme_font_size_override("font_size", 11)
		mp_value.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
		mp_info.add_child(mp_value)

	# Separator
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("separator", Color(0.3, 0.4, 0.35))
	vbox.add_child(sep2)

	# Stats section
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 16)
	stats_grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(stats_grid)

	_add_stat_row(stats_grid, "ATK", character.base_attack, Color(1.0, 0.5, 0.4))
	_add_stat_row(stats_grid, "DEF", character.base_defense, Color(0.5, 0.7, 1.0))
	_add_stat_row(stats_grid, "MAG", character.base_magic, Color(0.8, 0.5, 1.0))
	_add_stat_row(stats_grid, "SPD", character.base_speed, Color(0.5, 1.0, 0.7))

	# For monsters: show Brand. For player characters: show Path
	if character is Monster:
		# Monster - show Brand
		var monster := character as Monster
		if monster.brand != Enums.Brand.NONE:
			var sep3 := HSeparator.new()
			sep3.add_theme_color_override("separator", Color(0.3, 0.4, 0.35))
			vbox.add_child(sep3)

			var brand_info := HBoxContainer.new()
			brand_info.add_theme_constant_override("separation", 6)
			vbox.add_child(brand_info)

			var brand_title := Label.new()
			brand_title.text = "Brand:"
			brand_title.add_theme_font_size_override("font_size", 10)
			brand_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			brand_info.add_child(brand_title)

			# Brand icon (colored indicator)
			var brand_icon := _create_brand_icon(monster.brand)
			brand_info.add_child(brand_icon)

			var brand_value := Label.new()
			brand_value.text = _get_brand_name(monster.brand)
			brand_value.add_theme_font_size_override("font_size", 10)
			brand_value.add_theme_color_override("font_color", _get_brand_color(monster.brand))
			brand_info.add_child(brand_value)
	elif character is PlayerCharacter:
		# Player character - show Path
		var sep3 := HSeparator.new()
		sep3.add_theme_color_override("separator", Color(0.3, 0.4, 0.35))
		vbox.add_child(sep3)

		var path_info := HBoxContainer.new()
		path_info.add_theme_constant_override("separation", 6)
		vbox.add_child(path_info)

		var path_title := Label.new()
		path_title.text = "Path:"
		path_title.add_theme_font_size_override("font_size", 10)
		path_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		path_info.add_child(path_title)

		var path_value := Label.new()
		var path_name := GameManager.get_path_name() if GameManager.has_method("get_path_name") else "Unknown"
		path_value.text = path_name
		path_value.add_theme_font_size_override("font_size", 10)
		path_value.add_theme_color_override("font_color", _get_path_color())
		path_info.add_child(path_value)

	# Position tooltip to the RIGHT of the panel (party is on left side)
	add_child(party_tooltip)
	await get_tree().process_frame

	var panel_global := panel.global_position
	var tooltip_pos := Vector2(panel_global.x + panel.size.x + 10, panel_global.y)

	# Keep within screen bounds
	if tooltip_pos.x + party_tooltip.size.x > size.x - 10:
		tooltip_pos.x = panel_global.x - party_tooltip.size.x - 10
	if tooltip_pos.y + party_tooltip.size.y > size.y - 10:
		tooltip_pos.y = size.y - party_tooltip.size.y - 10

	party_tooltip.position = tooltip_pos

func _on_party_panel_unhover() -> void:
	"""Hide tooltip when mouse leaves party panel"""
	_hide_party_tooltip()

func _hide_party_tooltip() -> void:
	"""Remove and destroy the party tooltip"""
	if party_tooltip and is_instance_valid(party_tooltip):
		party_tooltip.queue_free()
		party_tooltip = null

# =============================================================================
# CHARACTER SPRITE HOVER (from Battle Arena)
# =============================================================================

func _on_character_sprite_hovered(character: Node) -> void:
	"""Handle hover on character sprite in battle arena - show tooltip and update target if in TARGET_SELECT"""
	if not character is CharacterBase:
		return
	var char := character as CharacterBase
	
	# If in target selection mode, hovering selects this character as target
	if current_state == UIState.TARGET_SELECT and char in valid_targets:
		var idx := valid_targets.find(char)
		if idx >= 0 and idx != current_target_index:
			current_target_index = idx
			_update_target_display()
	
	# Don't show sprite tooltip if sidebar tooltip is already visible (prevents glitching)
	if tooltip_visible or (party_tooltip and is_instance_valid(party_tooltip)):
		return
	
	# Determine if this is an enemy or ally and show appropriate tooltip
	if char is Monster and (char as Monster).is_corrupted:
		# Enemy monster - show enemy tooltip at mouse position
		_show_sprite_enemy_tooltip(char)
	else:
		# Ally - show party tooltip at mouse position
		_show_sprite_party_tooltip(char)

func _on_character_sprite_unhovered(character: Node) -> void:
	"""Hide tooltips when mouse leaves character sprite"""
	_hide_enemy_tooltip()
	_hide_party_tooltip()

func _on_target_selected_from_sprite(character: Node) -> void:
	"""Handle target selection from clicking on character sprite"""
	if not character is CharacterBase:
		return
	var char := character as CharacterBase
	
	# Only process if we're in target selection mode
	if current_state != UIState.TARGET_SELECT:
		return
	
	# Check if this is a valid target
	if char in valid_targets:
		var idx := valid_targets.find(char)
		if idx >= 0:
			current_target_index = idx
			_update_target_display()
			# Confirm the selection
			_confirm_target()

func _show_sprite_enemy_tooltip(enemy: CharacterBase) -> void:
	"""Show enemy tooltip near mouse position when hovering arena sprite"""
	_hide_enemy_tooltip()
	
	# Create tooltip (same as _on_enemy_panel_hover but positioned at mouse)
	enemy_tooltip = PanelContainer.new()
	enemy_tooltip.name = "EnemyTooltip"
	enemy_tooltip.custom_minimum_size = Vector2(280, 0)
	enemy_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	tooltip_style.border_color = Color(0.6, 0.3, 0.4, 1.0)
	tooltip_style.set_border_width_all(2)
	tooltip_style.set_corner_radius_all(6)
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 10
	tooltip_style.content_margin_bottom = 10
	enemy_tooltip.add_theme_stylebox_override("panel", tooltip_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	enemy_tooltip.add_child(vbox)
	
	# Name header
	var name_label := Label.new()
	name_label.text = enemy.character_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.7))
	vbox.add_child(name_label)
	
	# Level and tier
	var level_label := Label.new()
	if enemy is Monster:
		var monster := enemy as Monster
		var tier_name: String = str(Enums.MonsterTier.keys()[monster.monster_tier])
		level_label.text = "Lv.%d %s" % [enemy.level, tier_name]
	else:
		level_label.text = "Level %d" % enemy.level
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(level_label)
	
	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.4, 0.3, 0.35))
	vbox.add_child(sep)
	
	# HP info
	var hp_info := HBoxContainer.new()
	hp_info.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_info)
	
	var hp_title := Label.new()
	hp_title.text = "HP:"
	hp_title.add_theme_font_size_override("font_size", 11)
	hp_title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	hp_info.add_child(hp_title)
	
	var hp_value := Label.new()
	hp_value.text = "%d / %d" % [enemy.current_hp, enemy.get_max_hp()]
	hp_value.add_theme_font_size_override("font_size", 11)
	hp_value.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	hp_info.add_child(hp_value)
	
	# Brand info for monsters
	if enemy is Monster:
		var monster := enemy as Monster
		var brand_info := HBoxContainer.new()
		brand_info.add_theme_constant_override("separation", 8)
		vbox.add_child(brand_info)
		
		var brand_title := Label.new()
		brand_title.text = "Brand:"
		brand_title.add_theme_font_size_override("font_size", 11)
		brand_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		brand_info.add_child(brand_title)
		
		var brand_value := Label.new()
		var brand_name: String = Enums.Brand.keys()[monster.brand] if monster.brand < Enums.Brand.size() else "UNKNOWN"
		brand_value.text = brand_name
		brand_value.add_theme_font_size_override("font_size", 11)
		brand_value.add_theme_color_override("font_color", _get_brand_color(monster.brand))
		brand_info.add_child(brand_value)
	
	add_child(enemy_tooltip)
	tooltip_visible = true
	
	# Position near mouse
	await get_tree().process_frame
	var mouse_pos := get_global_mouse_position()
	var tooltip_pos := mouse_pos + Vector2(15, 15)
	
	# Keep tooltip on screen
	if tooltip_pos.x + enemy_tooltip.size.x > size.x - 10:
		tooltip_pos.x = mouse_pos.x - enemy_tooltip.size.x - 15
	if tooltip_pos.y + enemy_tooltip.size.y > size.y - 10:
		tooltip_pos.y = size.y - enemy_tooltip.size.y - 10
	
	enemy_tooltip.position = tooltip_pos

func _show_sprite_party_tooltip(character: CharacterBase) -> void:
	"""Show party tooltip near mouse position when hovering arena sprite"""
	_hide_party_tooltip()
	
	party_tooltip = PanelContainer.new()
	party_tooltip.name = "PartyTooltip"
	party_tooltip.custom_minimum_size = Vector2(280, 0)
	party_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.06, 0.1, 0.08, 0.95)
	tooltip_style.border_color = Color(0.3, 0.6, 0.4, 1.0)
	tooltip_style.set_border_width_all(2)
	tooltip_style.set_corner_radius_all(6)
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 10
	tooltip_style.content_margin_bottom = 10
	party_tooltip.add_theme_stylebox_override("panel", tooltip_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	party_tooltip.add_child(vbox)
	
	# Name header
	var name_label := Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
	vbox.add_child(name_label)
	
	# Level info
	var level_label := Label.new()
	level_label.text = "Level %d" % character.level
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(level_label)
	
	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.3, 0.4, 0.35))
	vbox.add_child(sep)
	
	# HP info
	var hp_info := HBoxContainer.new()
	hp_info.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_info)
	
	var hp_title := Label.new()
	hp_title.text = "HP:"
	hp_title.add_theme_font_size_override("font_size", 11)
	hp_title.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	hp_info.add_child(hp_title)
	
	var hp_value := Label.new()
	hp_value.text = "%d / %d" % [character.current_hp, character.get_max_hp()]
	hp_value.add_theme_font_size_override("font_size", 11)
	hp_value.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	hp_info.add_child(hp_value)
	
	# MP info if character has MP
	if character.get_max_mp() > 0:
		var mp_info := HBoxContainer.new()
		mp_info.add_theme_constant_override("separation", 8)
		vbox.add_child(mp_info)
		
		var mp_title := Label.new()
		mp_title.text = "MP:"
		mp_title.add_theme_font_size_override("font_size", 11)
		mp_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		mp_info.add_child(mp_title)
		
		var mp_value := Label.new()
		mp_value.text = "%d / %d" % [character.current_mp, character.get_max_mp()]
		mp_value.add_theme_font_size_override("font_size", 11)
		mp_value.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		mp_info.add_child(mp_value)
	
	# Brand info for monsters
	if character is Monster:
		var monster := character as Monster
		var brand_info := HBoxContainer.new()
		brand_info.add_theme_constant_override("separation", 8)
		vbox.add_child(brand_info)
		
		var brand_title := Label.new()
		brand_title.text = "Brand:"
		brand_title.add_theme_font_size_override("font_size", 11)
		brand_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		brand_info.add_child(brand_title)
		
		var brand_value := Label.new()
		var brand_name: String = Enums.Brand.keys()[monster.brand] if monster.brand < Enums.Brand.size() else "UNKNOWN"
		brand_value.text = brand_name
		brand_value.add_theme_font_size_override("font_size", 11)
		brand_value.add_theme_color_override("font_color", _get_brand_color(monster.brand))
		brand_info.add_child(brand_value)
	
	add_child(party_tooltip)
	
	# Position near mouse
	await get_tree().process_frame
	var mouse_pos := get_global_mouse_position()
	var tooltip_pos := mouse_pos + Vector2(15, 15)
	
	# Keep tooltip on screen
	if tooltip_pos.x + party_tooltip.size.x > size.x - 10:
		tooltip_pos.x = mouse_pos.x - party_tooltip.size.x - 15
	if tooltip_pos.y + party_tooltip.size.y > size.y - 10:
		tooltip_pos.y = size.y - party_tooltip.size.y - 10
	
	party_tooltip.position = tooltip_pos

# =============================================================================
# LEFT PARTY SIDEBAR
# =============================================================================

var left_party_sidebar: PanelContainer = null

# =============================================================================
# RIGHT ENEMY SIDEBAR (Dynamic - mirrors party sidebar positioning)
# =============================================================================

var right_enemy_sidebar: PanelContainer = null

func _create_left_party_sidebar(viewport_size: Vector2) -> void:
	"""Create a vertical party sidebar on the left side of the screen"""
	# Don't create sidebar if no party members
	if party_members.is_empty():
		return

	# Remove existing sidebar if present (use .free() for immediate removal to prevent duplication)
	if left_party_sidebar and is_instance_valid(left_party_sidebar):
		left_party_sidebar.free()
		left_party_sidebar = null

	left_party_sidebar = PanelContainer.new()
	left_party_sidebar.name = "LeftPartySidebar"
	left_party_sidebar.custom_minimum_size = Vector2(160, 300)  # Force minimum height
	left_party_sidebar.size = Vector2(160, 300)

	# Force absolute positioning mode (required for children of anchor-based Controls)
	left_party_sidebar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	left_party_sidebar.position = Vector2(10, 70)  # Below top bar

	# Style the sidebar with BRIGHT debug colors so we can see it
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.2, 0.95)  # Dark blue-gray
	style.border_color = Color(0.3, 0.8, 0.5, 1.0)  # Bright green border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	left_party_sidebar.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "PartyList"
	vbox.add_theme_constant_override("separation", 8)
	left_party_sidebar.add_child(vbox)

	# Add "Your Party" title to match enemy sidebar
	var title_label := Label.new()
	title_label.text = "Your Party"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	vbox.add_child(title_label)

	# Populate with party members
	for member in party_members:
		var slot := _create_party_sidebar_slot(member)
		vbox.add_child(slot)

	add_child(left_party_sidebar)
	left_party_sidebar.show()
	left_party_sidebar.visible = true

	# Refresh status icons for all characters
	_refresh_all_status_icons()

func _create_party_sidebar_slot(character: CharacterBase) -> PanelContainer:
	"""Create a compact party member slot for the left sidebar"""
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(144, 60)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Style with ally colors
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.9)
	style.border_color = Color(0.3, 0.5, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	# Connect hover signals for tooltip
	panel.mouse_entered.connect(_on_party_panel_hover.bind(character, panel))
	panel.mouse_exited.connect(_on_party_panel_unhover)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	panel.add_child(hbox)

	# Portrait
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(36, 36)
	portrait_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.15, 0.18, 0.2, 1.0)
	portrait_style.border_color = Color(0.4, 0.5, 0.45, 1.0)
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(3)
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_container)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(32, 32)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	var portrait_path := _get_portrait_path(character)
	if portrait_path != "":
		var tex := load(portrait_path)
		if tex:
			portrait.texture = tex
	portrait_container.add_child(portrait)

	# Info container
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	hbox.add_child(vbox)

	# Name
	var name_label := Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.85))
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	vbox.add_child(name_label)

	# HP Bar
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.max_value = maxi(1, character.get_max_hp())
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(85, 12)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.3, 0.8, 0.35, 1.0)
	hp_fill.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.15, 0.15, 0.9)
	hp_bg.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	vbox.add_child(hp_bar)

	# HP Label
	var hp_label := Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "%d/%d" % [character.current_hp, character.get_max_hp()]
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.65))
	hp_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	vbox.add_child(hp_label)

	# MP Bar (if character has MP)
	if character.get_max_mp() > 0:
		var mp_bar := ProgressBar.new()
		mp_bar.name = "MPBar"
		mp_bar.max_value = maxi(1, character.get_max_mp())
		mp_bar.value = character.current_mp
		mp_bar.show_percentage = false
		mp_bar.custom_minimum_size = Vector2(85, 8)
		mp_bar.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent

		var mp_fill := StyleBoxFlat.new()
		mp_fill.bg_color = Color(0.3, 0.5, 0.9, 1.0)
		mp_fill.set_corner_radius_all(2)
		mp_bar.add_theme_stylebox_override("fill", mp_fill)

		var mp_bg := StyleBoxFlat.new()
		mp_bg.bg_color = Color(0.12, 0.12, 0.18, 0.9)
		mp_bg.set_corner_radius_all(2)
		mp_bar.add_theme_stylebox_override("background", mp_bg)
		vbox.add_child(mp_bar)

	# Status icons container - displays active buffs/debuffs
	var status_icons := HBoxContainer.new()
	status_icons.name = "StatusIcons"
	status_icons.add_theme_constant_override("separation", 2)
	status_icons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	status_icons.mouse_filter = Control.MOUSE_FILTER_PASS  # Pass mouse to parent
	vbox.add_child(status_icons)

	# Store reference for updates
	character.set_meta("sidebar_panel", panel)
	character.set_meta("status_icons", status_icons)

	return panel

func update_party_sidebar() -> void:
	"""Update HP/MP bars in the left party sidebar"""
	for member in party_members:
		if member.has_meta("sidebar_panel"):
			var panel: PanelContainer = member.get_meta("sidebar_panel")
			if is_instance_valid(panel):
				var hp_bar := panel.find_child("HPBar", true, false) as ProgressBar
				var hp_label := panel.find_child("HPLabel", true, false) as Label
				var mp_bar := panel.find_child("MPBar", true, false) as ProgressBar

				if hp_bar:
					hp_bar.max_value = maxi(1, member.get_max_hp())
					hp_bar.value = member.current_hp
				if hp_label:
					hp_label.text = "%d/%d" % [member.current_hp, member.get_max_hp()]
				if mp_bar:
					mp_bar.max_value = maxi(1, member.get_max_mp())
					mp_bar.value = member.current_mp

func _create_right_enemy_sidebar(viewport_size: Vector2) -> void:
	"""Create a vertical enemy sidebar on the right side - mirrors party sidebar"""
	print("[BATTLE_UI] _create_right_enemy_sidebar called, enemies: %d, viewport: %s" % [enemies.size(), str(viewport_size)])

	# Don't create if no enemies
	if enemies.is_empty():
		print("[BATTLE_UI] No enemies, skipping enemy sidebar")
		return

	# Remove existing sidebar
	if right_enemy_sidebar and is_instance_valid(right_enemy_sidebar):
		right_enemy_sidebar.free()
		right_enemy_sidebar = null

	right_enemy_sidebar = PanelContainer.new()
	right_enemy_sidebar.name = "RightEnemySidebar"
	right_enemy_sidebar.custom_minimum_size = Vector2(160, 300)
	right_enemy_sidebar.size = Vector2(160, 300)

	# Use PRESET_TOP_LEFT (same as party sidebar) then set X position for right side
	right_enemy_sidebar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	right_enemy_sidebar.position = Vector2(viewport_size.x - 170, 70)  # Same Y=70 as party sidebar
	print("[BATTLE_UI] Enemy sidebar position set to: %s" % str(right_enemy_sidebar.position))

	# Style with red theme for enemies
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.1, 0.95)  # Dark red-gray
	style.border_color = Color(0.8, 0.3, 0.3, 1.0)  # Red border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	right_enemy_sidebar.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "EnemyList"
	vbox.add_theme_constant_override("separation", 8)
	right_enemy_sidebar.add_child(vbox)

	# Add "Enemies" title
	var title_label := Label.new()
	title_label.text = "Enemies"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7))
	vbox.add_child(title_label)

	# Populate with enemies
	for enemy in enemies:
		var slot := _create_enemy_sidebar_slot(enemy)
		vbox.add_child(slot)

	add_child(right_enemy_sidebar)
	right_enemy_sidebar.show()
	right_enemy_sidebar.z_index = 100  # Ensure it's on top
	print("[BATTLE_UI] Enemy sidebar added to tree, visible: %s, position: %s" % [right_enemy_sidebar.visible, str(right_enemy_sidebar.global_position)])

func _create_enemy_sidebar_slot(enemy: CharacterBase) -> PanelContainer:
	"""Create a compact enemy slot for the right sidebar"""
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(144, 70)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Style with enemy colors
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	style.border_color = Color(0.5, 0.3, 0.3, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	# Connect hover signals
	panel.mouse_entered.connect(_on_enemy_panel_hover.bind(enemy, panel))
	panel.mouse_exited.connect(_on_enemy_panel_unhover)

	# Connect click signal for target selection
	panel.gui_input.connect(_on_enemy_panel_clicked.bind(enemy))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(hbox)

	# Portrait
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(36, 36)
	portrait_container.mouse_filter = Control.MOUSE_FILTER_PASS
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.2, 0.12, 0.12, 1.0)
	portrait_style.border_color = Color(0.6, 0.35, 0.35, 1.0)
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(3)
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_container)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(32, 32)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.mouse_filter = Control.MOUSE_FILTER_PASS
	var portrait_path := _get_portrait_path(enemy)
	if portrait_path != "":
		var tex := load(portrait_path)
		if tex:
			portrait.texture = tex
	portrait_container.add_child(portrait)

	# Info container
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(vbox)

	# Name
	var name_label := Label.new()
	name_label.text = enemy.character_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.8))
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(name_label)

	# HP Bar - red themed
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.max_value = maxi(1, enemy.get_max_hp())
	hp_bar.value = enemy.current_hp
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(85, 10)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_PASS

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.25, 0.25, 1.0)  # Red for enemies
	hp_fill.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.12, 0.12, 0.9)
	hp_bg.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	vbox.add_child(hp_bar)

	# Corruption bar for monsters
	if enemy is Monster:
		var monster := enemy as Monster
		var corruption_bar := ProgressBar.new()
		corruption_bar.name = "CorruptionBar"
		corruption_bar.max_value = 100.0
		var corruption_percent := (monster.corruption_level / monster.max_corruption) * 100.0
		corruption_bar.value = corruption_percent
		corruption_bar.show_percentage = false
		corruption_bar.custom_minimum_size = Vector2(85, 6)
		corruption_bar.mouse_filter = Control.MOUSE_FILTER_PASS

		var corr_fill := StyleBoxFlat.new()
		corr_fill.bg_color = Color(0.6, 0.2, 0.7, 1.0)  # Purple for corruption
		corr_fill.set_corner_radius_all(2)
		corruption_bar.add_theme_stylebox_override("fill", corr_fill)

		var corr_bg := StyleBoxFlat.new()
		corr_bg.bg_color = Color(0.15, 0.1, 0.15, 0.9)
		corr_bg.set_corner_radius_all(2)
		corruption_bar.add_theme_stylebox_override("background", corr_bg)
		vbox.add_child(corruption_bar)

	# Store reference for updates
	enemy.set_meta("enemy_sidebar_panel", panel)

	return panel

func update_enemy_sidebar() -> void:
	"""Update HP/corruption bars in the right enemy sidebar"""
	for enemy in enemies:
		if enemy.has_meta("enemy_sidebar_panel"):
			var panel: PanelContainer = enemy.get_meta("enemy_sidebar_panel")
			if is_instance_valid(panel):
				var hp_bar := panel.find_child("HPBar", true, false) as ProgressBar
				var corruption_bar := panel.find_child("CorruptionBar", true, false) as ProgressBar

				if hp_bar:
					hp_bar.max_value = maxi(1, enemy.get_max_hp())
					hp_bar.value = enemy.current_hp
				if corruption_bar and enemy is Monster:
					var monster := enemy as Monster
					var corruption_percent := (monster.corruption_level / monster.max_corruption) * 100.0
					corruption_bar.value = corruption_percent

func _auto_scroll_combat_log() -> void:
	"""Auto-scroll combat log to bottom if user hasn't manually scrolled away"""
	if not combat_log_scroll:
		return
	if user_scrolled_log:
		return  # User scrolled manually, don't auto-scroll until they interact
	var scrollbar := combat_log_scroll.get_v_scroll_bar()
	combat_log_scroll.scroll_vertical = int(scrollbar.max_value)

func _on_combat_log_scrolled(_value: float) -> void:
	"""Called when user manually scrolls the combat log"""
	if not combat_log_scroll:
		return
	var scrollbar := combat_log_scroll.get_v_scroll_bar()
	# If user scrolled away from bottom, mark as manually scrolled
	var at_bottom := scrollbar.value >= scrollbar.max_value - 30
	if not at_bottom:
		user_scrolled_log = true

func _reset_combat_log_scroll() -> void:
	"""Reset scroll state when user interacts with battle (button press, target select, etc.)"""
	user_scrolled_log = false
	_auto_scroll_combat_log()

func _update_combat_log_size() -> void:
	"""Update combat log size - default 238x158px, draggable to expand"""
	if not combat_log:
		return
	# Default size: 238x158 px (offset_left=-248 for width, offset_top=-248 for height)
	# With offset_right=-10 and offset_bottom=-90, this gives 238x158
	combat_log.offset_left = -248
	if not _log_dragging:
		# Only reset offset_top if not currently dragging
		combat_log.offset_top = _log_start_top if _log_start_top != 0.0 else -248
	# Update drag handle text based on current size
	if combat_log_drag_handle:
		var is_expanded := combat_log.offset_top < -300
		combat_log_drag_handle.text = "━━ ▲ ━━" if is_expanded else "━━ ▼ ━━"

func _add_combat_log_drag_handle() -> void:
	"""Add a draggable handle to resize the combat log"""
	if combat_log_drag_handle and is_instance_valid(combat_log_drag_handle):
		return  # Already exists

	var vbox := combat_log.get_node_or_null("VBoxContainer")
	if not vbox:
		return

	# Create drag handle button (keeps Button type for stability)
	combat_log_drag_handle = Button.new()
	combat_log_drag_handle.name = "DragHandle"
	combat_log_drag_handle.text = "━━ ▼ ━━"
	combat_log_drag_handle.flat = true
	combat_log_drag_handle.add_theme_font_size_override("font_size", 10)
	combat_log_drag_handle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	combat_log_drag_handle.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 1.0))
	combat_log_drag_handle.custom_minimum_size = Vector2(0, 20)
	combat_log_drag_handle.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	# Connect gui_input for drag handling
	combat_log_drag_handle.gui_input.connect(_on_combat_log_drag_input)

	# Insert at the beginning (before title)
	vbox.add_child(combat_log_drag_handle)
	vbox.move_child(combat_log_drag_handle, 0)

	# Initialize default position
	_log_start_top = -248.0  # Default height: 158px

func _on_combat_log_drag_input(event: InputEvent) -> void:
	"""Handle drag input on combat log handle"""
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# Start dragging
				_log_dragging = true
				_log_drag_start_y = mb.global_position.y
				_log_start_top = combat_log.offset_top
			else:
				# Stop dragging
				_log_dragging = false
	elif event is InputEventMouseMotion and _log_dragging:
		var mm := event as InputEventMouseMotion
		# Calculate new offset_top based on drag delta
		var delta_y := mm.global_position.y - _log_drag_start_y
		# Dragging UP (negative delta) = larger panel (more negative offset_top)
		# Dragging DOWN (positive delta) = smaller panel (less negative offset_top)
		var new_top := _log_start_top + delta_y
		# Clamp between default size (-248) and max expansion (-500)
		# -248 = default 158px height, -500 = max ~410px height
		new_top = clampf(new_top, -500.0, -248.0)
		combat_log.offset_top = new_top
		# Update drag handle text
		var is_expanded := new_top < -300
		combat_log_drag_handle.text = "━━ ▲ ━━" if is_expanded else "━━ ▼ ━━"

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	# Disconnect EventBus signals to prevent errors after scene is freed
	if EventBus.status_effect_applied.is_connected(_on_status_effect_changed):
		EventBus.status_effect_applied.disconnect(_on_status_effect_changed)
	if EventBus.status_effect_removed.is_connected(_on_status_effect_changed):
		EventBus.status_effect_removed.disconnect(_on_status_effect_changed)
	if EventBus.character_hovered.is_connected(_on_character_sprite_hovered):
		EventBus.character_hovered.disconnect(_on_character_sprite_hovered)
	if EventBus.character_unhovered.is_connected(_on_character_sprite_unhovered):
		EventBus.character_unhovered.disconnect(_on_character_sprite_unhovered)
	if EventBus.target_selected.is_connected(_on_target_selected_from_sprite):
		EventBus.target_selected.disconnect(_on_target_selected_from_sprite)
	
	# Kill any running tweens
	for tween in _turn_order_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_turn_order_tweens.clear()
