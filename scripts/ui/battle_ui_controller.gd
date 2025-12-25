class_name BattleUIController
extends Control
## BattleUIController: Manages all battle UI elements and player input.

signal action_selected(action: Enums.BattleAction, target: CharacterBase, skill_id: String)
signal target_confirmed(target: CharacterBase)
signal target_cancelled

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var top_bar: PanelContainer = $TopBar
@onready var turn_order_display: HBoxContainer = $TopBar/HBoxContainer/TurnOrderDisplay
@onready var battle_info_label: Label = $TopBar/HBoxContainer/BattleInfoLabel

@onready var party_panel: PanelContainer = $PartyPanel
@onready var party_status_container: HBoxContainer = $PartyPanel/VBoxContainer/PartyStatusContainer
@onready var action_menu: HBoxContainer = $PartyPanel/VBoxContainer/ActionMenu

@onready var attack_button: Button = $PartyPanel/VBoxContainer/ActionMenu/AttackButton
@onready var skill_button: Button = $PartyPanel/VBoxContainer/ActionMenu/SkillButton
@onready var purify_button: Button = $PartyPanel/VBoxContainer/ActionMenu/PurifyButton
@onready var item_button: Button = $PartyPanel/VBoxContainer/ActionMenu/ItemButton
@onready var defend_button: Button = $PartyPanel/VBoxContainer/ActionMenu/DefendButton
@onready var flee_button: Button = $PartyPanel/VBoxContainer/ActionMenu/FleeButton

@onready var enemy_info_panel: PanelContainer = $EnemyInfoPanel
@onready var enemy_name_label: Label = $EnemyInfoPanel/VBoxContainer/EnemyNameLabel
@onready var enemy_hp_bar: ProgressBar = $EnemyInfoPanel/VBoxContainer/EnemyHPBar
@onready var enemy_hp_label: Label = $EnemyInfoPanel/VBoxContainer/EnemyHPLabel
@onready var corruption_bar: ProgressBar = $EnemyInfoPanel/VBoxContainer/CorruptionBar
@onready var corruption_label: Label = $EnemyInfoPanel/VBoxContainer/CorruptionLabel
@onready var status_effects_container: HBoxContainer = $EnemyInfoPanel/VBoxContainer/StatusEffectsContainer

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

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_hide_all_menus()

func set_battle_manager(manager: BattleManager) -> void:
	battle_manager = manager

	# Connect battle manager signals
	battle_manager.waiting_for_player_input.connect(_on_waiting_for_input)
	battle_manager.round_started.connect(_on_round_started)
	battle_manager.battle_victory.connect(_on_victory)
	battle_manager.battle_defeat.connect(_on_defeat)

	# Connect UI signals to battle manager
	action_selected.connect(_on_action_selected)

func _on_action_selected(action: Enums.BattleAction, target: CharacterBase, skill_id: String) -> void:
	if battle_manager:
		battle_manager.submit_player_action(action, target, skill_id)

func _on_waiting_for_input(character: CharacterBase) -> void:
	start_turn(character)

func _on_round_started(round_number: int) -> void:
	update_round_display(round_number)
	if battle_manager:
		update_turn_order(battle_manager.turn_order)

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

	skill_back_button.pressed.connect(_on_skill_back_pressed)
	item_back_button.pressed.connect(_on_item_back_pressed)

	continue_button.pressed.connect(_on_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	title_button.pressed.connect(_on_title_pressed)

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
	if current_state == UIState.TARGET_SELECT:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			_select_previous_target()
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			_select_next_target()
		elif event.is_action_pressed("ui_accept"):
			_confirm_target()
		elif event.is_action_pressed("ui_cancel"):
			_cancel_target_selection()

# =============================================================================
# BATTLE FLOW
# =============================================================================

func setup_battle(player_party: Array[CharacterBase], enemy_party: Array[CharacterBase]) -> void:
	party_members = player_party
	enemies = enemy_party

	_update_party_display()
	_update_enemy_display(enemies[0] if not enemies.is_empty() else null)

func start_turn(character: CharacterBase) -> void:
	current_character = character

	if character is PlayerCharacter:
		show_action_menu()
	else:
		set_ui_state(UIState.ANIMATING)

func show_action_menu() -> void:
	set_ui_state(UIState.ACTION_SELECT)
	action_menu.show()
	_update_action_buttons()
	attack_button.grab_focus()

func hide_action_menu() -> void:
	action_menu.hide()

func set_ui_state(state: UIState) -> void:
	current_state = state

	match state:
		UIState.ACTION_SELECT:
			action_menu.show()
			skill_menu.hide()
			item_menu.hide()
			target_selector.hide()
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

func _update_action_buttons() -> void:
	if current_character == null:
		return

	# Disable skill if silenced
	skill_button.disabled = current_character.has_status_effect(Enums.StatusEffect.SILENCE)

	# Disable purify if no valid targets
	var has_purifiable_targets := false
	for enemy in enemies:
		if enemy is Monster and enemy.can_be_purified():
			has_purifiable_targets = true
			break
	purify_button.disabled = not has_purifiable_targets

	# Disable item if no usable items
	# TODO: Check inventory
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
	pending_action = Enums.BattleAction.ATTACK
	pending_skill = ""
	_start_target_selection(false)  # Target enemies

func _on_skill_pressed() -> void:
	_show_skill_menu()

func _on_purify_pressed() -> void:
	pending_action = Enums.BattleAction.PURIFY
	pending_skill = ""
	_start_target_selection(false, true)  # Target enemies (purifiable only)

func _on_item_pressed() -> void:
	_show_item_menu()

func _on_defend_pressed() -> void:
	pending_action = Enums.BattleAction.DEFEND
	pending_skill = ""
	action_selected.emit(pending_action, current_character, "")
	set_ui_state(UIState.ANIMATING)

func _on_flee_pressed() -> void:
	pending_action = Enums.BattleAction.FLEE
	pending_skill = ""
	action_selected.emit(pending_action, null, "")
	set_ui_state(UIState.ANIMATING)

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
		if current_character.can_use_skill(skill_id):
			var button := Button.new()
			button.text = _get_skill_display_name(skill_id)
			button.pressed.connect(_on_skill_selected.bind(skill_id))
			skill_list.add_child(button)

func _get_skill_display_name(skill_id: String) -> String:
	# TODO: Load from skill database
	return skill_id.capitalize().replace("_", " ")

func _on_skill_selected(skill_id: String) -> void:
	pending_action = Enums.BattleAction.SKILL
	pending_skill = skill_id
	skill_menu.hide()

	# Determine target type based on skill
	var targets_allies := _skill_targets_allies(skill_id)
	_start_target_selection(targets_allies)

func _skill_targets_allies(skill_id: String) -> bool:
	# TODO: Read from skill data
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

	# TODO: Get usable items from inventory
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

	# Most items target allies
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

	# Position indicator
	# TODO: Get actual world position of target
	target_name_label.text = target.character_name

	# Update enemy info panel if targeting enemy
	if target in enemies:
		_update_enemy_display(target)

func _confirm_target() -> void:
	if valid_targets.is_empty():
		return

	var target := valid_targets[current_target_index]
	target_selector.hide()

	action_selected.emit(pending_action, target, pending_skill)
	set_ui_state(UIState.ANIMATING)

func _cancel_target_selection() -> void:
	target_selector.hide()
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
	panel.custom_minimum_size = Vector2(150, 80)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = character.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var hp_bar := ProgressBar.new()
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(hp_bar)

	var hp_label := Label.new()
	hp_label.text = "HP: %d/%d" % [character.current_hp, character.get_max_hp()]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hp_label)

	if character.get_max_mp() > 0:
		var mp_label := Label.new()
		mp_label.text = "MP: %d/%d" % [character.current_mp, character.get_max_mp()]
		mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(mp_label)

	return panel

func _update_enemy_display(enemy: CharacterBase) -> void:
	if enemy == null:
		enemy_info_panel.hide()
		return

	enemy_info_panel.show()
	enemy_name_label.text = enemy.character_name

	var hp_percent := enemy.get_hp_percent()
	enemy_hp_bar.value = hp_percent
	enemy_hp_label.text = "HP: %d/%d" % [enemy.current_hp, enemy.get_max_hp()]

	if enemy is Monster:
		var monster := enemy as Monster
		corruption_bar.show()
		corruption_label.show()
		var corruption_percent := monster.corruption_level / monster.max_corruption
		corruption_bar.value = corruption_percent
		corruption_label.text = "Corruption: %d%%" % int(corruption_percent * 100)
	else:
		corruption_bar.hide()
		corruption_label.hide()

	_update_status_effects_display(enemy)

func _update_status_effects_display(character: CharacterBase) -> void:
	for child in status_effects_container.get_children():
		child.queue_free()

	for effect in character.status_effects.keys():
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		# TODO: Load actual status effect icons
		status_effects_container.add_child(icon)

func update_turn_order(order: Array[CharacterBase]) -> void:
	for child in turn_order_display.get_children():
		child.queue_free()

	for i in range(mini(6, order.size())):
		var label := Label.new()
		label.text = order[i].character_name
		if i == 0:
			label.add_theme_color_override("font_color", Color.YELLOW)
		turn_order_display.add_child(label)

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
	# Signal is already emitted from BattleManager with rewards, this just hides UI

func _on_retry_pressed() -> void:
	defeat_screen.hide()
	EventBus.battle_retry_requested.emit()

func _on_title_pressed() -> void:
	defeat_screen.hide()
	SceneManager.goto_main_menu()

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
