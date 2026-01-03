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

# Level up tracking for victory screen
var _battle_level_ups: Dictionary = {}  # CharacterBase -> {old_level, new_level, stat_gains}

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_hide_all_menus()
	_style_action_buttons()
	
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
	
	# Connect capture system signals for animated corruption bar
	_connect_capture_signals()

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
		# Make PartyPanel background fully transparent (remove black box)
		var transparent_style := StyleBoxEmpty.new()
		party_panel.add_theme_stylebox_override("panel", transparent_style)
		party_panel.show()
		party_panel.visible = true
		print("[BATTLE_UI] PartyPanel positioned: size=%s, visible=%s" % [party_panel.size, party_panel.visible])

		# Hide the party status container from main panel
		if party_status_container:
			party_status_container.hide()

	# CombatLog - bottom-right corner, LARGER default size (expandable)
	if combat_log:
		combat_log.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		combat_log.offset_right = -10
		combat_log.offset_bottom = -110  # More space above action buttons
		_update_combat_log_size()
		combat_log.show()
		# Fix dual scrollbar: disable RichTextLabel's built-in scroll, use only ScrollContainer
		if combat_log_scroll:
			combat_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
			combat_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			# Make sure mouse filter allows scrolling
			combat_log_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
			# Style the scrollbar to be visible
			var scrollbar := combat_log_scroll.get_v_scroll_bar()
			if scrollbar:
				scrollbar.custom_minimum_size.x = 8  # Make scrollbar wider/visible
				# Create a visible style for the scrollbar
				var grabber_style := StyleBoxFlat.new()
				grabber_style.bg_color = Color(0.5, 0.45, 0.4, 0.8)
				grabber_style.set_corner_radius_all(4)
				scrollbar.add_theme_stylebox_override("grabber", grabber_style)
				scrollbar.add_theme_stylebox_override("grabber_highlight", grabber_style)
				scrollbar.add_theme_stylebox_override("grabber_pressed", grabber_style)
				var scroll_bg := StyleBoxFlat.new()
				scroll_bg.bg_color = Color(0.15, 0.12, 0.1, 0.6)
				scroll_bg.set_corner_radius_all(4)
				scrollbar.add_theme_stylebox_override("scroll", scroll_bg)
		if combat_log_text:
			# Disable RichTextLabel's internal scrolling to prevent dual scrollbar
			# But keep scroll_active true so content can be scrolled via ScrollContainer
			combat_log_text.scroll_active = true
			combat_log_text.scroll_following = false
			# Let mouse events pass through to ScrollContainer
			combat_log_text.mouse_filter = Control.MOUSE_FILTER_PASS
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
	print("[COMBAT_LOG] _on_action_started called - character: %s, action: %d" % [character.character_name, action])
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

	print("[COMBAT_LOG] Logging action: %s uses %s" % [character.character_name, action_name])
	log_action(character.character_name, action_name)

func _on_action_executed(character: CharacterBase, action: int, result: Dictionary) -> void:
	# NOTE: Action name is already logged by _on_action_started() - only log results here
	print("[COMBAT_LOG] _on_action_executed called - character: %s, action: %d, result: %s" % [character.character_name, action, result])
	
	var attacker_name: String = result.get("attacker_name", character.character_name)
	var target_name: String = result.get("target_name", "target")
	
	# Log the result (damage, miss, heal, etc.)
	if result.has("is_miss") and result.is_miss:
		print("[COMBAT_LOG] Logging MISS: %s -> %s" % [attacker_name, target_name])
		log_miss(attacker_name, target_name)
	elif result.has("damage") and result.damage > 0:
		var is_crit: bool = result.get("is_critical", false)
		print("[COMBAT_LOG] Logging DAMAGE: %s took %d damage (crit: %s)" % [target_name, result.damage, is_crit])
		log_damage(target_name, result.damage, is_crit)
	elif result.has("heal") and result.heal > 0:
		print("[COMBAT_LOG] Logging HEAL: %s healed %d" % [target_name, result.heal])
		log_heal(target_name, result.heal)
	else:
		print("[COMBAT_LOG] No loggable result - keys: %s" % result.keys())

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
	# Pass the full rewards dictionary to show_victory for enhanced display
	var victory_data := {
		"exp_gained": rewards.get("experience", 0),
		"gold": rewards.get("currency", 0),
		"items_dropped": rewards.get("items", [])
	}
	show_victory(victory_data)

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
	
	# Level up tracking for victory screen stat display
	EventBus.level_up.connect(_on_character_level_up)
	EventBus.battle_started.connect(_on_battle_started_clear_level_ups)

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
	print("[BATTLE_UI] setup_battle called with %d players, %d enemies" % [player_party.size(), enemy_party.size()])
	# Assign to typed arrays
	party_members.clear()
	for p in player_party:
		if p is CharacterBase:
			party_members.append(p)
	print("[BATTLE_UI] After filtering: party_members=%d" % party_members.size())

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

	# Flee button: Only protagonist can flee for the party
	# Allied monsters cannot flee (corruption-based fleeing is handled separately by AI)
	var is_protagonist := current_character.is_protagonist
	if is_protagonist:
		# Protagonist can flee unless it's a boss battle
		flee_button.visible = true
		flee_button.disabled = _is_boss_battle()
	else:
		# Allied monsters cannot use flee button - hide it entirely
		flee_button.visible = false
		flee_button.disabled = true

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
	# Start target selection for allies (defend ally feature)
	_start_target_selection(true)  # Target allies with BLUE highlights

func _on_flee_pressed() -> void:
	_reset_combat_log_scroll()
	pending_action = Enums.BattleAction.FLEE
	pending_skill = ""
	action_selected.emit(pending_action, null, "")
	set_ui_state(UIState.ANIMATING)

# =============================================================================
# BUTTON STYLING
# =============================================================================

func _style_action_buttons() -> void:
	"""Apply polished AAA styling to action buttons with icons"""
	var button_data := {
		attack_button: {"icon": "res://assets/ui/icons/actions/attack.png", "color": Color(0.9, 0.3, 0.3)},
		skill_button: {"icon": "res://assets/ui/icons/actions/skill.png", "color": Color(0.3, 0.5, 0.9)},
		purify_button: {"icon": "res://assets/ui/icons/actions/special.png", "color": Color(0.8, 0.6, 0.9)},
		item_button: {"icon": "res://assets/ui/icons/actions/item.png", "color": Color(0.3, 0.8, 0.4)},
		defend_button: {"icon": "res://assets/ui/icons/actions/defend.png", "color": Color(0.6, 0.6, 0.7)},
		flee_button: {"icon": "res://assets/ui/icons/actions/flee.png", "color": Color(0.8, 0.7, 0.3)}
	}
	
	for button in button_data.keys():
		if not button:
			continue
		
		var data: Dictionary = button_data[button]
		var accent_color: Color = data.color
		
		# Create custom stylebox for normal state
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
		normal_style.border_color = accent_color.darkened(0.3)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(6)
		normal_style.shadow_color = Color(0, 0, 0, 0.5)
		normal_style.shadow_size = 4
		normal_style.shadow_offset = Vector2(2, 2)
		
		# Hover style - brighter
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.18, 0.18, 0.22, 0.98)
		hover_style.border_color = accent_color
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(6)
		hover_style.shadow_color = accent_color.darkened(0.5)
		hover_style.shadow_color.a = 0.6
		hover_style.shadow_size = 8
		hover_style.shadow_offset = Vector2(0, 0)
		
		# Pressed style
		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = accent_color.darkened(0.4)
		pressed_style.border_color = accent_color.lightened(0.2)
		pressed_style.set_border_width_all(2)
		pressed_style.set_corner_radius_all(6)
		
		# Disabled style
		var disabled_style := StyleBoxFlat.new()
		disabled_style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
		disabled_style.border_color = Color(0.3, 0.3, 0.3, 0.5)
		disabled_style.set_border_width_all(1)
		disabled_style.set_corner_radius_all(6)
		
		# Focus style - same as hover so focus indicator matches hover
		var focus_style := StyleBoxFlat.new()
		focus_style.bg_color = Color(0.18, 0.14, 0.22, 0.95)
		focus_style.border_color = Color(0.7, 0.55, 0.4, 1.0)
		focus_style.set_border_width_all(2)
		focus_style.set_corner_radius_all(6)
		
		# Apply styles
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_stylebox_override("disabled", disabled_style)
		button.add_theme_stylebox_override("focus", focus_style)  # Match hover style
		
		# Text styling
		button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.85))
		button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
		button.add_theme_font_size_override("font_size", 16)
		
		# Add icon if texture exists
		var icon_path: String = data.icon
		if ResourceLoader.exists(icon_path):
			var icon_tex := load(icon_path) as Texture2D
			if icon_tex:
				button.icon = icon_tex
				button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.expand_icon = true
				# Scale icon to fit button height
				button.add_theme_constant_override("icon_max_width", 28)

# =============================================================================
# BUTTON HOVER EFFECTS
# =============================================================================

func _on_action_button_hover(button: Button) -> void:
	"""Highlight button on hover/focus with scale and color tween"""
	# Grab focus when mouse hovers - this syncs the focus indicator with mouse
	button.grab_focus()
	
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
		# Highlight all valid enemy targets in RED (check both panel types)
		for enemy in enemies:
			if enemy in valid_targets:
				_set_panel_highlight(enemy, "ui_panel", Color(1.0, 0.3, 0.3, 1.0), 2)  # Red glow
				_set_panel_highlight(enemy, "enemy_sidebar_panel", Color(1.0, 0.3, 0.3, 1.0), 2)  # Red glow on right sidebar

func _highlight_enemy_in_sidebar(target: CharacterBase) -> void:
	"""Highlight the SELECTED enemy target (brighter red), others stay dimmer red"""
	for enemy in enemies:
		# Check both ui_panel and enemy_sidebar_panel
		var panels: Array[PanelContainer] = []
		if enemy.has_meta("ui_panel"):
			var p: PanelContainer = enemy.get_meta("ui_panel")
			if is_instance_valid(p):
				panels.append(p)
		if enemy.has_meta("enemy_sidebar_panel"):
			var p: PanelContainer = enemy.get_meta("enemy_sidebar_panel")
			if is_instance_valid(p):
				panels.append(p)
		
		for panel in panels:
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
	# Reset enemy sidebar to normal state (check both ui_panel and enemy_sidebar_panel)
	for enemy in enemies:
		if enemy.has_meta("ui_panel"):
			var panel: PanelContainer = enemy.get_meta("ui_panel")
			if is_instance_valid(panel):
				var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.border_color = Color(0.5, 0.25, 0.25, 1.0)
					style.set_border_width_all(1)
					style.shadow_size = 0  # Clear shadow
		
		# Also check enemy_sidebar_panel (right sidebar)
		if enemy.has_meta("enemy_sidebar_panel"):
			var panel: PanelContainer = enemy.get_meta("enemy_sidebar_panel")
			if is_instance_valid(panel):
				var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.border_color = Color(0.5, 0.3, 0.3, 1.0)
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
		Enums.StatusEffect.UNTARGETABLE:
			return "res://assets/ui/icons/buffs/invisible.png"
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

		# Create container for icon with background
		var icon_container := PanelContainer.new()
		icon_container.custom_minimum_size = Vector2(20, 20)
		
		# Style the container based on buff/debuff
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(3)
		style.set_border_width_all(1)
		
		# Determine if buff or debuff for coloring
		var is_buff := effect in [
			Enums.StatusEffect.REGEN, Enums.StatusEffect.SHIELD,
			Enums.StatusEffect.ATTACK_UP, Enums.StatusEffect.DEFENSE_UP,
			Enums.StatusEffect.SPEED_UP, Enums.StatusEffect.PURIFYING,
			Enums.StatusEffect.UNTARGETABLE
		]
		
		if is_buff:
			style.bg_color = Color(0.1, 0.3, 0.1, 0.8)  # Green tint for buffs
			style.border_color = Color(0.3, 0.7, 0.3, 0.9)
		else:
			style.bg_color = Color(0.3, 0.1, 0.1, 0.8)  # Red tint for debuffs
			style.border_color = Color(0.7, 0.3, 0.3, 0.9)
		
		icon_container.add_theme_stylebox_override("panel", style)
		
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = load(icon_path)
		icon_container.add_child(icon)

		# Add tooltip with effect name and remaining duration
		var effect_data: Dictionary = character.status_effects[effect_key]
		var duration: int = effect_data.get("duration", 0)
		var stacks: int = effect_data.get("stacks", 1)
		var tooltip := _get_status_effect_name(effect)
		if duration > 0:
			tooltip += " (%d turns)" % duration
		if stacks > 1:
			tooltip += " x%d" % stacks
		icon_container.tooltip_text = tooltip

		status_icons.add_child(icon_container)
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

func log_action(attacker_name: String, action_name: String, target_name: String = "", skill_name: String = "") -> void:
	var entry := ""
	# If skill_name is provided, use it; otherwise use action_name
	var display_action := skill_name if skill_name != "" else action_name
	
	if target_name.is_empty():
		entry = "[color=#e0d8c8]%s[/color] uses [color=#66ccff]'%s'[/color]" % [attacker_name, display_action]
	else:
		entry = "[color=#e0d8c8]%s[/color] uses [color=#66ccff]'%s'[/color] on [color=#ffcc66]%s[/color]" % [attacker_name, display_action, target_name]
	_append_to_log(entry)

func log_skill_use(attacker_name: String, skill_id: String, target_name: String = "") -> void:
	"""Log a skill use with proper skill display name"""
	var skill_display_name := _get_skill_display_name(skill_id)
	log_action(attacker_name, "Skill", target_name, skill_display_name)

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
	# Schedule auto-scroll after text is rendered
	_schedule_auto_scroll()

func _schedule_auto_scroll() -> void:
	"""Schedule auto-scroll after frame to ensure text layout is complete"""
	if not combat_log_scroll or user_scrolled_log:
		return
	# Wait for the text layout to update
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for RichTextLabel layout
	_auto_scroll_combat_log()

func clear_combat_log() -> void:
	combat_log_text.clear()
	combat_log_text.append_text("[color=#cc9933]╔══════════════════════════════╗[/color]")
	combat_log_text.append_text("\n[color=#cc9933]║[/color]      [color=#ffcc66]⚔ BATTLE START ⚔[/color]      [color=#cc9933]║[/color]")
	combat_log_text.append_text("\n[color=#cc9933]╚══════════════════════════════╝[/color]")

# =============================================================================
# BATTLE END SCREENS
# =============================================================================

func show_victory(data_or_exp, gold_gained: int = 0, items_obtained: Array = []) -> void:
	## Show victory screen with rewards
	## Can be called with:
	##   show_victory(exp: int, gold: int, items: Array) - legacy
	##   show_victory(data: Dictionary) - new format with party info
	set_ui_state(UIState.WAITING)
	
	var exp_gained: int = 0
	var gold: int = gold_gained
	var items: Array = items_obtained
	var party_data: Array = []  # Array of {character, exp_before, exp_after, level_before, level_after}
	
	# Handle both call signatures
	if data_or_exp is Dictionary:
		var data: Dictionary = data_or_exp
		exp_gained = data.get("exp_gained", 0)
		gold = data.get("gold", data.get("currency", 0))
		items = data.get("items_dropped", [])
		party_data = data.get("party_xp_data", [])
	else:
		exp_gained = data_or_exp as int
		gold = gold_gained
		items = items_obtained
	
	# Style the victory panel
	_style_victory_panel()
	
	victory_screen.show()
	
	# Get the rewards container
	var rewards_container: VBoxContainer = victory_screen.get_node_or_null("VictoryPanel/VBoxContainer/RewardsContainer")
	if rewards_container:
		# Clear old content and rebuild
		_build_victory_rewards_display(rewards_container, exp_gained, gold, items, party_data)
	else:
		# Fallback to simple labels
		exp_label.text = "EXP Gained: %d" % exp_gained
		gold_label.text = "Gold: %d" % gold
		var item_text := "Items: "
		if items.is_empty():
			item_text += "None"
		else:
			var item_names: Array[String] = []
			for item in items:
				if item is Dictionary:
					item_names.append(item.get("item_id", "Unknown"))
				else:
					item_names.append(str(item))
			item_text += ", ".join(item_names)
		items_label.text = item_text

	continue_button.grab_focus()
	
	# === VICTORY FANFARE SEQUENCE ===
	# 1. Screen flash effect
	_play_victory_screen_flash()
	
	# 2. Animate victory screen entrance with dramatic timing
	var victory_panel: PanelContainer = victory_screen.get_node_or_null("VictoryPanel")
	if victory_panel:
		victory_panel.modulate.a = 0.0
		victory_panel.scale = Vector2(0.5, 0.5)
		victory_panel.pivot_offset = victory_panel.size / 2
		
		var tween := create_tween()
		tween.set_parallel(true)
		# Fade in with slight delay for flash
		tween.tween_property(victory_panel, "modulate:a", 1.0, 0.5).set_delay(0.15).set_ease(Tween.EASE_OUT)
		# Scale up with dramatic bounce
		tween.tween_property(victory_panel, "scale", Vector2(1.0, 1.0), 0.6).set_delay(0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 3. Animate the "VICTORY!" title with extra flair
	await get_tree().create_timer(0.2).timeout
	_animate_victory_title()

func _build_victory_rewards_display(container: VBoxContainer, exp_gained: int, gold: int, items: Array, party_data: Array) -> void:
	## Build the enhanced victory rewards display with per-character XP bars
	
	# Clear existing children except the original labels (we'll hide them)
	for child in container.get_children():
		if child.name.begins_with("CharXP_") or child.name == "PartyXPSection" or child.name == "Separator":
			child.queue_free()
	
	# Hide original simple labels - we'll use our custom display
	if exp_label:
		exp_label.hide()
	if gold_label:
		gold_label.hide()
	if items_label:
		items_label.hide()
	
	# === TOTAL EXP HEADER ===
	var exp_header := Label.new()
	exp_header.name = "CharXP_Header"
	exp_header.text = "⚔ BATTLE REWARDS ⚔"
	exp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_header.add_theme_font_size_override("font_size", 20)
	exp_header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	container.add_child(exp_header)
	
	# === PARTY XP SECTION ===
	var party_section := VBoxContainer.new()
	party_section.name = "PartyXPSection"
	party_section.add_theme_constant_override("separation", 8)
	container.add_child(party_section)
	
	# Get party members from battle_manager or GameManager
	var party: Array = []
	if battle_manager and battle_manager.player_party.size() > 0:
		party = battle_manager.player_party
	elif GameManager and GameManager.player_party.size() > 0:
		party = GameManager.player_party
	
	# Calculate XP per member
	var alive_count := 0
	for member in party:
		if member and member.is_alive():
			alive_count += 1
	var xp_per_member: int = exp_gained / maxi(1, alive_count) if alive_count > 0 else 0
	
	# Create XP display for each party member
	var delay := 0.0
	for i in range(party.size()):
		var member: CharacterBase = party[i]
		if not member:
			continue
		
		var char_row := _create_character_xp_row(member, xp_per_member, delay)
		party_section.add_child(char_row)
		delay += 0.15  # Stagger animations
	
	# === SEPARATOR ===
	var sep := HSeparator.new()
	sep.name = "Separator"
	sep.add_theme_constant_override("separation", 10)
	sep.modulate = Color(0.4, 0.8, 0.4, 0.5)
	container.add_child(sep)
	
	# === GOLD & ITEMS ROW ===
	var rewards_row := HBoxContainer.new()
	rewards_row.name = "CharXP_RewardsRow"
	rewards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_row.add_theme_constant_override("separation", 40)
	container.add_child(rewards_row)
	
	# Gold display
	var gold_display := HBoxContainer.new()
	gold_display.add_theme_constant_override("separation", 5)
	rewards_row.add_child(gold_display)
	
	var gold_icon := Label.new()
	gold_icon.text = "💰"
	gold_icon.add_theme_font_size_override("font_size", 20)
	gold_display.add_child(gold_icon)
	
	var gold_amount := Label.new()
	gold_amount.text = "%d Gold" % gold
	gold_amount.add_theme_font_size_override("font_size", 18)
	gold_amount.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	gold_display.add_child(gold_amount)
	
	# Items display
	var items_display := HBoxContainer.new()
	items_display.add_theme_constant_override("separation", 5)
	rewards_row.add_child(items_display)
	
	var items_icon := Label.new()
	items_icon.text = "📦"
	items_icon.add_theme_font_size_override("font_size", 20)
	items_display.add_child(items_icon)
	
	var items_text := Label.new()
	if items.is_empty():
		items_text.text = "No items"
		items_text.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		var item_names: Array[String] = []
		for item in items:
			if item is Dictionary:
				var qty: int = item.get("quantity", 1)
				var name: String = item.get("item_id", "Unknown")
				item_names.append("%s x%d" % [name, qty] if qty > 1 else name)
			else:
				item_names.append(str(item))
		items_text.text = ", ".join(item_names)
		items_text.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	items_text.add_theme_font_size_override("font_size", 16)
	items_display.add_child(items_text)
	
	# Animate rewards row entrance
	rewards_row.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(rewards_row, "modulate:a", 1.0, 0.3).set_delay(delay + 0.3)
	
	# === BATTLE STATS SECTION ===
	_add_battle_stats_section(container, delay + 0.5)

func _add_battle_stats_section(container: VBoxContainer, delay: float) -> void:
	## Add battle statistics summary to victory screen
	if not battle_manager:
		return
	
	var stats: Dictionary = battle_manager.battle_stats
	if stats.is_empty():
		return
	
	# Separator
	var sep2 := HSeparator.new()
	sep2.name = "CharXP_StatsSep"
	sep2.add_theme_constant_override("separation", 8)
	sep2.modulate = Color(0.4, 0.6, 0.8, 0.4)
	container.add_child(sep2)
	
	# Stats header
	var stats_header := Label.new()
	stats_header.name = "CharXP_StatsHeader"
	stats_header.text = "📊 BATTLE STATS"
	stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_header.add_theme_font_size_override("font_size", 14)
	stats_header.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	container.add_child(stats_header)
	
	# Stats grid
	var stats_grid := GridContainer.new()
	stats_grid.name = "CharXP_StatsGrid"
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 30)
	stats_grid.add_theme_constant_override("v_separation", 4)
	container.add_child(stats_grid)
	
	# Add stat entries
	var stat_entries: Array[Dictionary] = [
		{"icon": "⚔", "label": "Turns", "value": stats.get("turns_taken", 0), "color": Color(0.9, 0.9, 0.9)},
		{"icon": "💥", "label": "Damage Dealt", "value": stats.get("damage_dealt", 0), "color": Color(1.0, 0.6, 0.4)},
		{"icon": "🛡", "label": "Damage Taken", "value": stats.get("damage_received", 0), "color": Color(0.6, 0.8, 1.0)},
	]
	
	# Add capture stats if any captures were attempted
	if stats.get("captures_attempted", 0) > 0:
		stat_entries.append({
			"icon": "🔮", 
			"label": "Captures", 
			"value": "%d/%d" % [stats.get("captures_successful", 0), stats.get("captures_attempted", 0)],
			"color": Color(0.8, 0.5, 1.0)
		})
	
	for entry in stat_entries:
		var stat_label := Label.new()
		stat_label.text = "%s %s:" % [entry.icon, entry.label]
		stat_label.add_theme_font_size_override("font_size", 12)
		stat_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stats_grid.add_child(stat_label)
		
		var stat_value := Label.new()
		stat_value.text = str(entry.value)
		stat_value.add_theme_font_size_override("font_size", 12)
		stat_value.add_theme_color_override("font_color", entry.color)
		stat_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(stat_value)
	
	# Animate stats section entrance
	sep2.modulate.a = 0.0
	stats_header.modulate.a = 0.0
	stats_grid.modulate.a = 0.0
	
	var stats_tween := create_tween()
	stats_tween.tween_property(sep2, "modulate:a", 0.4, 0.2).set_delay(delay)
	stats_tween.tween_property(stats_header, "modulate:a", 1.0, 0.2).set_delay(delay + 0.1)
	stats_tween.tween_property(stats_grid, "modulate:a", 1.0, 0.3).set_delay(delay + 0.2)

func _create_character_xp_row(character: CharacterBase, xp_gained: int, delay: float) -> PanelContainer:
	## Create a single character's XP display row with animated progress bar
	var row := PanelContainer.new()
	row.name = "CharXP_%s" % character.character_name
	row.custom_minimum_size = Vector2(380, 50)
	
	# Style the row panel
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0.05, 0.08, 0.05, 0.8)
	row_style.border_color = Color(0.3, 0.5, 0.3, 0.6)
	row_style.set_border_width_all(1)
	row_style.set_corner_radius_all(6)
	row_style.content_margin_left = 10
	row_style.content_margin_right = 10
	row_style.content_margin_top = 5
	row_style.content_margin_bottom = 5
	row.add_theme_stylebox_override("panel", row_style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)
	
	# Character name and level
	var name_container := VBoxContainer.new()
	name_container.custom_minimum_size.x = 100
	hbox.add_child(name_container)
	
	var name_label := Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	name_container.add_child(name_label)
	
	var level_label := Label.new()
	level_label.text = "Lv. %d" % character.level
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	name_container.add_child(level_label)
	
	# XP bar section
	var xp_section := VBoxContainer.new()
	xp_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_section.add_theme_constant_override("separation", 2)
	hbox.add_child(xp_section)
	
	# XP text row
	var xp_text_row := HBoxContainer.new()
	xp_section.add_child(xp_text_row)
	
	var xp_label := Label.new()
	xp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_label.add_theme_font_size_override("font_size", 11)
	xp_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	xp_text_row.add_child(xp_label)
	
	var xp_gained_label := Label.new()
	xp_gained_label.text = "+%d XP" % xp_gained
	xp_gained_label.add_theme_font_size_override("font_size", 12)
	xp_gained_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	xp_text_row.add_child(xp_gained_label)
	
	# XP progress bar
	var xp_bar := ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(200, 12)
	xp_bar.show_percentage = false
	xp_section.add_child(xp_bar)
	
	# Style the progress bar
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.15, 0.1, 0.9)
	bar_bg.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	bar_fill.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("fill", bar_fill)
	
	# Calculate XP values
	var current_xp: int = 0
	var xp_for_next: int = 100
	var is_alive := character.is_alive()
	
	if character.has_method("get_xp_for_next_level"):
		xp_for_next = character.get_xp_for_next_level()
	
	# Get current XP - check for both player and monster
	if "current_experience" in character:
		current_xp = character.current_experience
	
	# Calculate the XP BEFORE this battle's gain (for animation)
	var xp_before: int = current_xp - xp_gained if is_alive else current_xp
	xp_before = maxi(0, xp_before)
	
	# Set initial bar state
	xp_bar.max_value = xp_for_next
	xp_bar.value = xp_before
	
	# Update XP text
	xp_label.text = "%d / %d" % [current_xp, xp_for_next]
	
	# Dead characters get dimmed and no XP
	if not is_alive:
		row.modulate = Color(0.5, 0.5, 0.5, 0.7)
		xp_gained_label.text = "(KO)"
		xp_gained_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	# Animate entrance
	row.modulate.a = 0.0
	row.position.x = -20
	
	var entrance_tween := create_tween()
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(row, "modulate:a", 1.0 if is_alive else 0.7, 0.3).set_delay(delay)
	entrance_tween.tween_property(row, "position:x", 0.0, 0.3).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Animate XP bar fill (only for alive characters)
	if is_alive and xp_gained > 0:
		var bar_tween := create_tween()
		bar_tween.tween_property(xp_bar, "value", float(current_xp), 0.8).set_delay(delay + 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		# Check for level up - use our tracked level up data
		if has_character_leveled_up(character):
			# Level up occurred! Add celebration effect with stat gains
			bar_tween.tween_callback(_show_level_up_flash.bind(row, level_label, character.level, character)).set_delay(delay + 1.2)
	
	return row

func _show_level_up_flash(row: PanelContainer, level_label: Label, new_level: int, character: CharacterBase = null) -> void:
	## Flash effect when character levels up, with stat gains display
	level_label.text = "Lv. %d ⬆" % new_level
	level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	
	# Flash the row
	var flash_tween := create_tween()
	flash_tween.tween_property(row, "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.15)
	flash_tween.tween_property(row, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	
	# Add "LEVEL UP!" popup with stat gains
	var popup := PanelContainer.new()
	popup.name = "LevelUpPopup"
	popup.z_index = 10
	
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.15, 0.12, 0.05, 0.95)
	popup_style.border_color = Color(1.0, 0.85, 0.3)
	popup_style.set_border_width_all(2)
	popup_style.set_corner_radius_all(6)
	popup_style.content_margin_left = 10
	popup_style.content_margin_right = 10
	popup_style.content_margin_top = 6
	popup_style.content_margin_bottom = 6
	popup.add_theme_stylebox_override("panel", popup_style)
	
	var popup_vbox := VBoxContainer.new()
	popup_vbox.add_theme_constant_override("separation", 2)
	popup.add_child(popup_vbox)
	
	# Title
	var title := Label.new()
	title.text = "⭐ LEVEL UP! ⭐"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_vbox.add_child(title)
	
	# Get stat gains if we have level up data
	var level_up_data: Dictionary = {}
	if character:
		level_up_data = get_level_up_data(character)
	
	if not level_up_data.is_empty() and level_up_data.has("stat_gains"):
		var stat_gains: Dictionary = level_up_data["stat_gains"]
		
		# Create stat gains display
		var stats_grid := GridContainer.new()
		stats_grid.columns = 4  # 4 stats per row
		stats_grid.add_theme_constant_override("h_separation", 8)
		stats_grid.add_theme_constant_override("v_separation", 1)
		popup_vbox.add_child(stats_grid)
		
		# Add stat gains in a compact format
		var stat_order: Array[String] = ["max_hp", "max_mp", "attack", "defense", "magic", "resistance", "speed", "luck"]
		var stat_abbrevs := {
			"max_hp": "HP", "max_mp": "MP", "attack": "ATK", "defense": "DEF",
			"magic": "MAG", "resistance": "RES", "speed": "SPD", "luck": "LCK"
		}
		var stat_colors := {
			"max_hp": Color(0.4, 0.9, 0.4), "max_mp": Color(0.4, 0.6, 1.0),
			"attack": Color(1.0, 0.5, 0.4), "defense": Color(0.5, 0.7, 1.0),
			"magic": Color(0.8, 0.5, 1.0), "resistance": Color(0.6, 0.8, 0.9),
			"speed": Color(0.5, 1.0, 0.7), "luck": Color(1.0, 0.9, 0.4)
		}
		
		for stat in stat_order:
			if stat_gains.has(stat) and stat_gains[stat] > 0:
				var stat_label := Label.new()
				stat_label.text = "%s+%d" % [stat_abbrevs.get(stat, stat), stat_gains[stat]]
				stat_label.add_theme_font_size_override("font_size", 10)
				stat_label.add_theme_color_override("font_color", stat_colors.get(stat, Color.WHITE))
				stats_grid.add_child(stat_label)
	
	# Position popup above the row
	popup.position = Vector2(row.size.x / 2 - 80, -60)
	row.add_child(popup)
	
	# Animate popup entrance and exit
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.8, 0.8)
	popup.pivot_offset = popup.size / 2
	
	var popup_tween := create_tween()
	popup_tween.set_parallel(true)
	popup_tween.tween_property(popup, "modulate:a", 1.0, 0.2)
	popup_tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	popup_tween.tween_property(popup, "position:y", -80.0, 0.5).set_ease(Tween.EASE_OUT)
	popup_tween.chain().tween_property(popup, "modulate:a", 0.0, 0.5).set_delay(1.5)
	popup_tween.tween_callback(popup.queue_free)

func _style_victory_panel() -> void:
	"""Apply polished styling to victory screen"""
	var victory_panel: PanelContainer = victory_screen.get_node_or_null("VictoryPanel")
	if not victory_panel:
		return
	
	# Style the panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.12, 0.08, 0.98)
	panel_style.border_color = Color(0.4, 0.8, 0.3)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_color = Color(0.2, 0.6, 0.2, 0.4)
	panel_style.shadow_size = 20
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	victory_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style the title
	var title: Label = victory_panel.get_node_or_null("VBoxContainer/VictoryTitle")
	if title:
		title.add_theme_font_size_override("font_size", 36)
		title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	
	# Style the labels
	for label in [exp_label, gold_label, items_label]:
		if label:
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	
	# Style the continue button
	if continue_button:
		var btn_normal := StyleBoxFlat.new()
		btn_normal.bg_color = Color(0.2, 0.5, 0.2, 0.95)
		btn_normal.border_color = Color(0.4, 0.8, 0.4)
		btn_normal.set_border_width_all(2)
		btn_normal.set_corner_radius_all(6)
		
		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = Color(0.3, 0.6, 0.3, 0.98)
		btn_hover.border_color = Color(0.5, 1.0, 0.5)
		btn_hover.set_border_width_all(2)
		btn_hover.set_corner_radius_all(6)
		btn_hover.shadow_color = Color(0.3, 0.8, 0.3, 0.5)
		btn_hover.shadow_size = 8
		
		continue_button.add_theme_stylebox_override("normal", btn_normal)
		continue_button.add_theme_stylebox_override("hover", btn_hover)
		continue_button.add_theme_stylebox_override("pressed", btn_hover)
		continue_button.add_theme_font_size_override("font_size", 18)
		continue_button.add_theme_color_override("font_color", Color.WHITE)

func _play_victory_screen_flash() -> void:
	## Create a dramatic screen flash effect for victory
	var flash := ColorRect.new()
	flash.name = "VictoryFlash"
	flash.color = Color(1.0, 1.0, 0.8, 0.0)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 50
	victory_screen.add_child(flash)
	
	# Flash sequence: quick bright flash then fade
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.7, 0.08)
	tween.tween_property(flash, "color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func _animate_victory_title() -> void:
	## Animate the VICTORY! title with dramatic effects
	var victory_panel: PanelContainer = victory_screen.get_node_or_null("VictoryPanel")
	if not victory_panel:
		return
	
	var title: Label = victory_panel.get_node_or_null("VBoxContainer/VictoryTitle")
	if not title:
		return
	
	# Store original text
	var original_text := title.text
	title.text = ""
	
	# Animate each letter appearing
	var full_text := "⚔ VICTORY! ⚔"
	var letter_delay := 0.05
	
	for i in range(full_text.length()):
		await get_tree().create_timer(letter_delay).timeout
		title.text = full_text.substr(0, i + 1)
	
	# Final pulse effect on the title
	title.pivot_offset = title.size / 2
	var pulse_tween := create_tween()
	pulse_tween.tween_property(title, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT)
	pulse_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_IN_OUT)
	
	# Add glow effect by modulating color
	var glow_tween := create_tween()
	glow_tween.set_loops(3)
	glow_tween.tween_property(title, "modulate", Color(1.3, 1.3, 1.0, 1.0), 0.3)
	glow_tween.tween_property(title, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func show_defeat(data: Dictionary = {}) -> void:
	## Show defeat screen. Accepts optional data dictionary for battle stats.
	set_ui_state(UIState.WAITING)
	
	# Style the defeat panel
	_style_defeat_panel()
	
	defeat_screen.show()
	retry_button.grab_focus()
	
	# === DEFEAT SEQUENCE ===
	# 1. Red screen flash effect
	_play_defeat_screen_flash()
	
	# 2. Animate defeat screen entrance with somber timing
	var defeat_panel: PanelContainer = defeat_screen.get_node_or_null("DefeatPanel")
	if defeat_panel:
		defeat_panel.modulate.a = 0.0
		defeat_panel.scale = Vector2(0.9, 0.9)
		defeat_panel.pivot_offset = defeat_panel.size / 2
		
		var tween := create_tween()
		tween.set_parallel(true)
		# Slower, more somber fade in
		tween.tween_property(defeat_panel, "modulate:a", 1.0, 0.8).set_delay(0.3).set_ease(Tween.EASE_OUT)
		tween.tween_property(defeat_panel, "scale", Vector2(1.0, 1.0), 0.6).set_delay(0.3).set_ease(Tween.EASE_OUT)
	
	# 3. Animate the defeat title
	await get_tree().create_timer(0.4).timeout
	_animate_defeat_title()

func _play_defeat_screen_flash() -> void:
	## Create a dramatic red screen flash effect for defeat
	var flash := ColorRect.new()
	flash.name = "DefeatFlash"
	flash.color = Color(0.6, 0.0, 0.0, 0.0)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 50
	defeat_screen.add_child(flash)
	
	# Flash sequence: slower, more ominous
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.5, 0.15)
	tween.tween_property(flash, "color:a", 0.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func _animate_defeat_title() -> void:
	## Animate the DEFEAT title with somber effects
	var defeat_panel: PanelContainer = defeat_screen.get_node_or_null("DefeatPanel")
	if not defeat_panel:
		return
	
	var title: Label = defeat_panel.get_node_or_null("VBoxContainer/DefeatTitle")
	if not title:
		return
	
	# Slow fade-in of text with slight shake
	title.modulate.a = 0.0
	title.text = "💀 DEFEAT 💀"
	
	var tween := create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_IN)
	
	# Subtle shake effect
	var original_pos := title.position
	var shake_tween := create_tween()
	shake_tween.set_loops(3)
	shake_tween.tween_property(title, "position:x", original_pos.x - 2, 0.05)
	shake_tween.tween_property(title, "position:x", original_pos.x + 2, 0.05)
	shake_tween.tween_property(title, "position:x", original_pos.x, 0.05)

func _style_defeat_panel() -> void:
	"""Apply polished styling to defeat screen"""
	var defeat_panel: PanelContainer = defeat_screen.get_node_or_null("DefeatPanel")
	if not defeat_panel:
		return
	
	# Style the panel - dark red theme
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.06, 0.06, 0.98)
	panel_style.border_color = Color(0.7, 0.2, 0.2)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_color = Color(0.5, 0.1, 0.1, 0.4)
	panel_style.shadow_size = 20
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	defeat_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style the title
	var title: Label = defeat_panel.get_node_or_null("VBoxContainer/DefeatTitle")
	if title:
		title.add_theme_font_size_override("font_size", 36)
		title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	
	# Style the message
	var message: Label = defeat_panel.get_node_or_null("VBoxContainer/DefeatMessage")
	if message:
		message.add_theme_font_size_override("font_size", 16)
		message.add_theme_color_override("font_color", Color(0.8, 0.7, 0.7))
	
	# Style buttons
	for button in [retry_button, title_button]:
		if not button:
			continue
		var btn_normal := StyleBoxFlat.new()
		btn_normal.bg_color = Color(0.4, 0.15, 0.15, 0.95)
		btn_normal.border_color = Color(0.6, 0.3, 0.3)
		btn_normal.set_border_width_all(2)
		btn_normal.set_corner_radius_all(6)
		
		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = Color(0.5, 0.2, 0.2, 0.98)
		btn_hover.border_color = Color(0.8, 0.4, 0.4)
		btn_hover.set_border_width_all(2)
		btn_hover.set_corner_radius_all(6)
		btn_hover.shadow_color = Color(0.6, 0.2, 0.2, 0.5)
		btn_hover.shadow_size = 8
		
		button.add_theme_stylebox_override("normal", btn_normal)
		button.add_theme_stylebox_override("hover", btn_hover)
		button.add_theme_stylebox_override("pressed", btn_hover)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.9))

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
	# Handle invalid brand values (can happen with old .tres files)
	var brand_int := int(brand)
	if brand_int < 0 or brand_int > 11:
		return "— UNKNOWN"
	
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
		Enums.Brand.NONE:
			return "— NONE"
		_:
			return "— UNKNOWN"

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
		var player := character as PlayerCharacter
		
		# Player character - show Brand if they have one
		if player.current_brand != Enums.Brand.NONE:
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
			var brand_icon := _create_brand_icon(player.current_brand)
			brand_info.add_child(brand_icon)

			var brand_value := Label.new()
			brand_value.text = _get_brand_name(player.current_brand)
			brand_value.add_theme_font_size_override("font_size", 10)
			brand_value.add_theme_color_override("font_color", _get_brand_color(player.current_brand))
			brand_info.add_child(brand_value)
		
		# Also show Path
		var sep_path := HSeparator.new()
		sep_path.add_theme_color_override("separator", Color(0.3, 0.4, 0.35))
		vbox.add_child(sep_path)

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
		brand_value.text = _get_brand_name(monster.brand)
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
		brand_value.text = _get_brand_name(monster.brand)
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
	print("[BATTLE_UI] _create_left_party_sidebar called, party_members: %d, viewport: %s" % [party_members.size(), str(viewport_size)])
	# Don't create sidebar if no party members
	if party_members.is_empty():
		print("[BATTLE_UI] No party members, skipping party sidebar")
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
	print("[BATTLE_UI] Party sidebar added to tree, visible: %s, position: %s, z_index: %d" % [left_party_sidebar.visible, str(left_party_sidebar.global_position), left_party_sidebar.z_index])

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

	# Path display for player characters (with aligned brand info)
	if character.character_type == Enums.CharacterType.PLAYER and character.current_path != Enums.Path.NONE:
		var path_label := Label.new()
		path_label.name = "PathLabel"
		var path_name: String = Enums.get_path_name(character.current_path)
		var aligned_brand: String = _get_path_aligned_brand(character.current_path)
		path_label.text = "%s [%s]" % [path_name, aligned_brand]
		path_label.add_theme_font_size_override("font_size", 9)
		path_label.add_theme_color_override("font_color", _get_path_type_color(character.current_path))
		path_label.mouse_filter = Control.MOUSE_FILTER_PASS
		vbox.add_child(path_label)
	
	# Brand display for monsters (allied monsters in party)
	if character is Monster:
		var monster := character as Monster
		var brand_label := Label.new()
		brand_label.name = "BrandLabel"
		var brand_name := _get_brand_name(monster.brand)
		var brand_color := _get_brand_color(monster.brand)
		brand_label.text = brand_name
		brand_label.add_theme_font_size_override("font_size", 9)
		brand_label.add_theme_color_override("font_color", brand_color)
		brand_label.mouse_filter = Control.MOUSE_FILTER_PASS
		vbox.add_child(brand_label)

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
				
				# Handle death state - fade out dead party members
				if member.is_dead():
					_mark_sidebar_panel_dead(panel)
				else:
					panel.modulate.a = 1.0  # Ensure alive members are fully visible

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

	# Brand display for enemies
	if enemy.brand != Enums.Brand.NONE:
		var brand_label := Label.new()
		brand_label.name = "BrandLabel"
		var brand_name: String = Enums.get_brand_name(enemy.brand)
		brand_label.text = brand_name
		brand_label.add_theme_font_size_override("font_size", 9)
		brand_label.add_theme_color_override("font_color", _get_brand_color(enemy.brand))
		brand_label.mouse_filter = Control.MOUSE_FILTER_PASS
		vbox.add_child(brand_label)

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

	# HP Label (numeric) - matches party sidebar
	var hp_label := Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "%d/%d" % [enemy.current_hp, enemy.get_max_hp()]
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.6))
	hp_label.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(hp_label)

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
				var hp_label := panel.find_child("HPLabel", true, false) as Label
				var corruption_bar := panel.find_child("CorruptionBar", true, false) as ProgressBar

				if hp_bar:
					hp_bar.max_value = maxi(1, enemy.get_max_hp())
					hp_bar.value = enemy.current_hp
				if hp_label:
					hp_label.text = "%d/%d" % [enemy.current_hp, enemy.get_max_hp()]
				if corruption_bar and enemy is Monster:
					var monster := enemy as Monster
					var corruption_percent := (monster.corruption_level / monster.max_corruption) * 100.0
					corruption_bar.value = corruption_percent
				
				# Handle death state - fade out dead enemies
				if enemy.is_dead():
					_mark_sidebar_panel_dead(panel)
				else:
					panel.modulate.a = 1.0  # Ensure alive enemies are fully visible

func _auto_scroll_combat_log() -> void:
	"""Auto-scroll combat log to bottom if user hasn't manually scrolled away"""
	if not combat_log_scroll:
		return
	if user_scrolled_log:
		return  # User scrolled manually, don't auto-scroll until they interact
	var scrollbar := combat_log_scroll.get_v_scroll_bar()
	if scrollbar:
		# Force scroll to absolute bottom
		combat_log_scroll.scroll_vertical = int(scrollbar.max_value) + 100

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

func _mark_sidebar_panel_dead(panel: PanelContainer) -> void:
	"""Mark a sidebar panel as dead with visual feedback"""
	if not is_instance_valid(panel):
		return
	
	# Skip if already marked dead
	if panel.has_meta("is_dead_panel") and panel.get_meta("is_dead_panel"):
		return
	
	panel.set_meta("is_dead_panel", true)
	
	# Animate fade out
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.35, 0.5)
	
	# Add "DEAD" overlay text
	var dead_label := Label.new()
	dead_label.name = "DeadOverlay"
	dead_label.text = "DEAD"
	dead_label.add_theme_font_size_override("font_size", 14)
	dead_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 0.9))
	dead_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dead_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dead_label.set_anchors_preset(Control.PRESET_CENTER)
	dead_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dead_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_child(dead_label)

func _update_combat_log_size() -> void:
	"""Update combat log size - LARGER default 300x220px, draggable to expand"""
	if not combat_log:
		return
	# LARGER default size: 300x220 px
	# offset_left = -(width + offset_right) = -(300 + 10) = -310
	# offset_top = -(height + offset_bottom) = -(220 + 110) = -330
	combat_log.offset_left = -310
	if not _log_dragging:
		# Only reset offset_top if not currently dragging
		combat_log.offset_top = _log_start_top if _log_start_top != 0.0 else -330
	# Update drag handle text based on current size
	if combat_log_drag_handle:
		var is_expanded := combat_log.offset_top < -380
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

	# Initialize default position (LARGER default)
	_log_start_top = -330.0  # Default height: 220px

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
		# Clamp between LARGER default size (-330) and max expansion (-600)
		# -330 = default 220px height, -600 = max ~490px height
		new_top = clampf(new_top, -600.0, -330.0)
		combat_log.offset_top = new_top
		# Update drag handle text
		var is_expanded := new_top < -380
		combat_log_drag_handle.text = "━━ ▲ ━━" if is_expanded else "━━ ▼ ━━"

# =============================================================================
# PATH & BRAND HELPERS
# =============================================================================

func _get_path_aligned_brand(path: Enums.Path) -> String:
	"""Get the primary aligned brand for a given Path"""
	match path:
		Enums.Path.IRONBOUND:
			return "IRON"
		Enums.Path.FANGBORN:
			return "SAVAGE"
		Enums.Path.VOIDTOUCHED:
			return "LEECH"
		Enums.Path.UNCHAINED:
			return "SURGE"
	return ""

func _get_path_type_color(path: Enums.Path) -> Color:
	"""Get the display color for a given Path type (IRONBOUND, FANGBORN, etc.)"""
	match path:
		Enums.Path.IRONBOUND:
			return Color(0.6, 0.65, 0.75)  # Steel blue
		Enums.Path.FANGBORN:
			return Color(0.85, 0.4, 0.3)   # Savage red
		Enums.Path.VOIDTOUCHED:
			return Color(0.6, 0.3, 0.7)    # Void purple
		Enums.Path.UNCHAINED:
			return Color(0.9, 0.8, 0.3)    # Lightning gold
	return Color(0.7, 0.7, 0.7)

# =============================================================================
# LEVEL UP TRACKING FOR VICTORY SCREEN
# =============================================================================

func _on_battle_started_clear_level_ups(_enemy_data: Array) -> void:
	## Clear level up tracking when a new battle starts
	_battle_level_ups.clear()

func _on_character_level_up(character: Node, new_level: int, stat_gains: Dictionary) -> void:
	## Track level ups during battle for display on victory screen
	if not character:
		return
	
	# Store or update level up data for this character
	if _battle_level_ups.has(character):
		# Character leveled up multiple times - merge stat gains
		var existing: Dictionary = _battle_level_ups[character]
		existing["new_level"] = new_level
		for stat in stat_gains:
			if existing["stat_gains"].has(stat):
				existing["stat_gains"][stat] += stat_gains[stat]
			else:
				existing["stat_gains"][stat] = stat_gains[stat]
	else:
		_battle_level_ups[character] = {
			"old_level": new_level - 1,
			"new_level": new_level,
			"stat_gains": stat_gains.duplicate()
		}

func get_level_up_data(character: CharacterBase) -> Dictionary:
	## Get level up data for a character (if they leveled up this battle)
	return _battle_level_ups.get(character, {})

func has_character_leveled_up(character: CharacterBase) -> bool:
	## Check if a character leveled up during this battle
	return _battle_level_ups.has(character)

# =============================================================================
# CAPTURE SYSTEM UI ANIMATIONS
# =============================================================================

var _corruption_bar_tweens: Dictionary = {}  # monster -> Tween
var _capture_overlay: ColorRect = null

func _connect_capture_signals() -> void:
	"""Connect to CaptureSystem signals for animated UI feedback"""
	# These signals come from CaptureSystem - connect if it exists
	var capture_system := get_node_or_null("/root/BattleManager/CaptureSystem")
	if capture_system:
		if capture_system.has_signal("corruption_reduced"):
			capture_system.corruption_reduced.connect(_on_corruption_reduced)
		if capture_system.has_signal("capture_succeeded"):
			capture_system.capture_succeeded.connect(_on_capture_succeeded)
		if capture_system.has_signal("capture_failed"):
			capture_system.capture_failed.connect(_on_capture_failed)
		if capture_system.has_signal("capture_attempt_started"):
			capture_system.capture_attempt_started.connect(_on_capture_attempt_started)
		if capture_system.has_signal("corruption_battle_started"):
			capture_system.corruption_battle_started.connect(_on_corruption_battle_started)
		if capture_system.has_signal("corruption_battle_pass"):
			capture_system.corruption_battle_pass.connect(_on_corruption_battle_pass)
	
	# Also connect via EventBus for decoupled communication
	if not EventBus.corruption_battle_started.is_connected(_on_corruption_battle_started_event):
		EventBus.corruption_battle_started.connect(_on_corruption_battle_started_event)
	if not EventBus.corruption_battle_pass_completed.is_connected(_on_corruption_battle_pass_event):
		EventBus.corruption_battle_pass_completed.connect(_on_corruption_battle_pass_event)

func _on_corruption_reduced(monster: Node, old_value: float, new_value: float) -> void:
	"""Animate corruption bar decrease with dramatic effect"""
	if not monster or not is_instance_valid(monster):
		return
	
	# Find the corruption bar for this monster
	var corruption_bar := _get_monster_corruption_bar(monster)
	if not corruption_bar:
		return
	
	# Kill any existing tween for this monster
	if _corruption_bar_tweens.has(monster) and _corruption_bar_tweens[monster].is_valid():
		_corruption_bar_tweens[monster].kill()
	
	# Calculate percentages
	var max_corruption: float = 100.0
	if monster.has_method("get_max_corruption"):
		max_corruption = monster.get_max_corruption()
	elif "max_corruption" in monster:
		max_corruption = monster.max_corruption
	
	var old_percent := (old_value / max_corruption) * 100.0
	var new_percent := (new_value / max_corruption) * 100.0
	
	# Create dramatic animation
	var tween := create_tween()
	_corruption_bar_tweens[monster] = tween
	
	# Flash the bar bright purple
	var bar_fill := corruption_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if bar_fill:
		var original_color := bar_fill.bg_color
		var flash_color := Color(0.9, 0.4, 1.0, 1.0)  # Bright purple flash
		
		tween.tween_callback(func(): bar_fill.bg_color = flash_color)
		tween.tween_interval(0.1)
		tween.tween_callback(func(): bar_fill.bg_color = original_color)
	
	# Animate the value decrease with easing
	tween.tween_property(corruption_bar, "value", new_percent, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Add floating text showing corruption reduction
	var reduction := old_value - new_value
	if reduction > 0:
		_show_corruption_reduction_popup(monster, reduction)
	
	# Log to combat log
	if monster.has_method("get_character_name"):
		var name: String = monster.character_name if "character_name" in monster else "Monster"
		_append_to_log("[color=purple]%s's corruption reduced by %.0f%%![/color]" % [name, reduction])

func _get_monster_corruption_bar(monster: Node) -> ProgressBar:
	"""Find the corruption bar for a monster in the UI"""
	# Check enemy_sidebar_panel first (right sidebar)
	if monster.has_meta("enemy_sidebar_panel"):
		var panel: PanelContainer = monster.get_meta("enemy_sidebar_panel")
		if is_instance_valid(panel):
			return panel.find_child("CorruptionBar", true, false) as ProgressBar
	
	# Check ui_panel (old sidebar)
	if monster.has_meta("ui_panel"):
		var panel: PanelContainer = monster.get_meta("ui_panel")
		if is_instance_valid(panel):
			return panel.find_child("CorruptionBar", true, false) as ProgressBar
	
	return null

func _show_corruption_reduction_popup(monster: Node, amount: float) -> void:
	"""Show floating popup when corruption is reduced"""
	var popup := Label.new()
	popup.text = "-%.0f%% CORRUPTION" % amount
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))  # Purple
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.15))
	popup.add_theme_constant_override("outline_size", 3)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 100
	
	# Position near the monster's sidebar panel
	var panel_pos := Vector2(size.x - 200, 150)  # Default to right side
	if monster.has_meta("enemy_sidebar_panel"):
		var panel: PanelContainer = monster.get_meta("enemy_sidebar_panel")
		if is_instance_valid(panel):
			panel_pos = panel.global_position + Vector2(-50, 20)
	
	popup.position = panel_pos
	add_child(popup)
	
	# Animate float up and fade
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", panel_pos.y - 60, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.8).set_delay(0.4)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)

func _on_capture_attempt_started(monster: Node, vessel_tier: int, chance: float) -> void:
	"""Show capture attempt UI with chance display"""
	if not monster or not is_instance_valid(monster):
		return
	
	var name: String = monster.character_name if "character_name" in monster else "Monster"
	_append_to_log("[color=cyan]⚔ Capture attempt on %s! (%.0f%% chance)[/color]" % [name, chance * 100])
	
	# Start corruption bar pulsing animation
	_start_corruption_bar_pulse(monster)

func _start_corruption_bar_pulse(monster: Node) -> void:
	"""Make corruption bar pulse during capture attempt"""
	var corruption_bar := _get_monster_corruption_bar(monster)
	if not corruption_bar:
		return
	
	# Create pulsing glow effect
	var pulse_tween := create_tween().set_loops(5)  # Pulse 5 times
	pulse_tween.tween_property(corruption_bar, "modulate", Color(1.4, 1.0, 1.4, 1.0), 0.3)
	pulse_tween.tween_property(corruption_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _on_corruption_battle_started(monster: Node, passes_needed: int) -> void:
	"""Show corruption battle UI overlay"""
	if not monster or not is_instance_valid(monster):
		return
	
	var name: String = monster.character_name if "character_name" in monster else "Monster"
	_append_to_log("[color=magenta]═══ CORRUPTION BATTLE: %s ═══[/color]" % name)
	_append_to_log("[color=gray]%d passes needed to break the corruption...[/color]" % passes_needed)
	
	# Create dramatic overlay effect
	_show_capture_overlay(Color(0.3, 0.1, 0.4, 0.3))

func _on_corruption_battle_started_event(monster: Node, passes: int) -> void:
	"""EventBus version of corruption battle started"""
	_on_corruption_battle_started(monster, passes)

func _on_corruption_battle_pass(monster: Node, current_pass: int, total_passes: int) -> void:
	"""Show progress during corruption battle"""
	_append_to_log("[color=purple]Pass %d/%d complete![/color]" % [current_pass, total_passes])
	
	# Flash the corruption bar
	var corruption_bar := _get_monster_corruption_bar(monster)
	if corruption_bar:
		var flash_tween := create_tween()
		flash_tween.tween_property(corruption_bar, "modulate", Color(2.0, 1.5, 2.0, 1.0), 0.1)
		flash_tween.tween_property(corruption_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_corruption_battle_pass_event(monster: Node, current: int, total: int) -> void:
	"""EventBus version of corruption battle pass"""
	_on_corruption_battle_pass(monster, current, total)

func _on_capture_succeeded(monster: Node, method: int, bonus_data: Dictionary) -> void:
	"""Show dramatic capture success animation"""
	if not monster or not is_instance_valid(monster):
		return
	
	var name: String = monster.character_name if "character_name" in monster else "Monster"
	var method_name := _get_capture_method_name(method)
	
	_append_to_log("[color=lime][b]★ CAPTURE SUCCESS! ★[/b][/color]")
	_append_to_log("[color=green]%s has been captured via %s![/color]" % [name, method_name])
	
	# Hide capture overlay
	_hide_capture_overlay()
	
	# Show success popup
	_show_capture_result_popup(true, name, method_name)
	
	# Flash the monster's panel green
	_flash_monster_panel(monster, Color(0.3, 1.0, 0.3, 1.0))

func _on_capture_failed(monster: Node, method: int, reason: String) -> void:
	"""Show capture failure animation"""
	if not monster or not is_instance_valid(monster):
		return
	
	var name: String = monster.character_name if "character_name" in monster else "Monster"
	var method_name := _get_capture_method_name(method)
	
	_append_to_log("[color=red][b]✗ CAPTURE FAILED![/b][/color]")
	_append_to_log("[color=salmon]%s[/color]" % reason)
	
	# Hide capture overlay
	_hide_capture_overlay()
	
	# Show failure popup
	_show_capture_result_popup(false, name, method_name)
	
	# Flash the monster's panel red
	_flash_monster_panel(monster, Color(1.0, 0.3, 0.3, 1.0))

func _get_capture_method_name(method: int) -> String:
	"""Get display name for capture method"""
	match method:
		0: return "SOULBIND"
		1: return "PURIFY"
		2: return "DOMINATE"
		3: return "BARGAIN"
		_: return "UNKNOWN"

func _show_capture_overlay(color: Color) -> void:
	"""Show semi-transparent overlay during capture"""
	if _capture_overlay and is_instance_valid(_capture_overlay):
		_capture_overlay.queue_free()
	
	_capture_overlay = ColorRect.new()
	_capture_overlay.name = "CaptureOverlay"
	_capture_overlay.color = color
	_capture_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capture_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capture_overlay.z_index = 50
	add_child(_capture_overlay)
	
	# Fade in
	_capture_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_capture_overlay, "modulate:a", 1.0, 0.3)

func _hide_capture_overlay() -> void:
	"""Hide and remove capture overlay"""
	if _capture_overlay and is_instance_valid(_capture_overlay):
		var tween := create_tween()
		tween.tween_property(_capture_overlay, "modulate:a", 0.0, 0.3)
		tween.tween_callback(_capture_overlay.queue_free)
		_capture_overlay = null

func _show_capture_result_popup(success: bool, monster_name: String, method_name: String) -> void:
	"""Show dramatic capture result popup"""
	var popup := PanelContainer.new()
	popup.name = "CaptureResultPopup"
	popup.z_index = 100
	
	# Style based on success/failure
	var style := StyleBoxFlat.new()
	if success:
		style.bg_color = Color(0.1, 0.2, 0.1, 0.95)
		style.border_color = Color(0.4, 1.0, 0.4)
	else:
		style.bg_color = Color(0.2, 0.1, 0.1, 0.95)
		style.border_color = Color(1.0, 0.4, 0.4)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	popup.add_child(vbox)
	
	# Title
	var title := Label.new()
	if success:
		title.text = "★ CAPTURED! ★"
		title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		title.text = "✗ ESCAPED!"
		title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Monster name
	var name_label := Label.new()
	name_label.text = monster_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Method used
	var method_label := Label.new()
	method_label.text = "via %s" % method_name
	method_label.add_theme_font_size_override("font_size", 14)
	method_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	method_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(method_label)
	
	add_child(popup)
	
	# Center on screen
	await get_tree().process_frame
	var viewport_size := get_viewport_rect().size
	popup.position = (viewport_size - popup.size) / 2
	
	# Animate entrance
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.5, 0.5)
	popup.pivot_offset = popup.size / 2
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Hold and fade out
	tween.set_parallel(false)
	tween.tween_interval(2.0)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)

func _flash_monster_panel(monster: Node, color: Color) -> void:
	"""Flash a monster's sidebar panel with a color"""
	var panel: PanelContainer = null
	if monster.has_meta("enemy_sidebar_panel"):
		panel = monster.get_meta("enemy_sidebar_panel")
	elif monster.has_meta("ui_panel"):
		panel = monster.get_meta("ui_panel")
	
	if not panel or not is_instance_valid(panel):
		return
	
	var tween := create_tween()
	tween.tween_property(panel, "modulate", color, 0.15)
	tween.tween_property(panel, "modulate", Color.WHITE, 0.3)
	tween.tween_property(panel, "modulate", color.lerp(Color.WHITE, 0.5), 0.15)
	tween.tween_property(panel, "modulate", Color.WHITE, 0.2)

func animate_corruption_change(monster: Node, new_corruption: float) -> void:
	"""Public method to animate corruption bar change (called from battle system)"""
	if not monster or not is_instance_valid(monster):
		return
	
	var corruption_bar := _get_monster_corruption_bar(monster)
	if not corruption_bar:
		return
	
	# Calculate percentage
	var max_corruption: float = 100.0
	if "max_corruption" in monster:
		max_corruption = monster.max_corruption
	var new_percent := (new_corruption / max_corruption) * 100.0
	
	# Animate smoothly
	var tween := create_tween()
	tween.tween_property(corruption_bar, "value", new_percent, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

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
	if EventBus.level_up.is_connected(_on_character_level_up):
		EventBus.level_up.disconnect(_on_character_level_up)
	if EventBus.battle_started.is_connected(_on_battle_started_clear_level_ups):
		EventBus.battle_started.disconnect(_on_battle_started_clear_level_ups)
	
	# Disconnect capture system signals
	if EventBus.corruption_battle_started.is_connected(_on_corruption_battle_started_event):
		EventBus.corruption_battle_started.disconnect(_on_corruption_battle_started_event)
	if EventBus.corruption_battle_pass_completed.is_connected(_on_corruption_battle_pass_event):
		EventBus.corruption_battle_pass_completed.disconnect(_on_corruption_battle_pass_event)
	
	# Kill any running tweens
	for tween in _turn_order_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_turn_order_tweens.clear()
	
	# Kill corruption bar tweens
	for monster in _corruption_bar_tweens:
		var tween: Tween = _corruption_bar_tweens[monster]
		if tween and tween.is_valid():
			tween.kill()
	_corruption_bar_tweens.clear()
	
	# Clean up capture overlay
	if _capture_overlay and is_instance_valid(_capture_overlay):
		_capture_overlay.queue_free()
		_capture_overlay = null
