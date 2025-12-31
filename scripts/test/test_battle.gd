extends Node
## TestBattle: Sets up and runs a test battle for debugging and development.

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Party Setup")
@export var ally_monster_count: int = 3  # 3 allied monsters with player
@export var party_level: int = 10

@export_group("Enemy Setup")
@export var enemy_count: int = 2  # 2 enemy monsters
@export var enemy_level: int = 8
@export var enemy_type: String = "shadow_imp"

@export_group("VERA Setup")
@export var starting_corruption: float = 25.0
@export var vera_state: Enums.VERAState = Enums.VERAState.INTERFACE

# =============================================================================
# NODES
# =============================================================================

var battle_arena: Node2D = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.emit_debug("TestBattle scene loaded")

	# Remove the fake placeholder BattleArena (we'll load the real one)
	var fake_arena = get_node_or_null("BattleArena")
	if fake_arena:
		fake_arena.queue_free()
	# Keep the styled BattleUI from the scene - it has visible buttons and combat log

	# Load and instantiate the REAL battle arena scene
	var arena_scene := load("res://scenes/battle/battle_arena.tscn")
	if arena_scene:
		battle_arena = arena_scene.instantiate()
		add_child(battle_arena)
		EventBus.emit_debug("Real battle arena loaded")
	else:
		push_error("Failed to load battle_arena.tscn")
		return

	# Wait a frame for everything to initialize
	await get_tree().process_frame

	_setup_test_battle()

func _setup_test_battle() -> void:
	# Set up VERA state
	_setup_vera()

	# Create party
	var party := _create_test_party()

	# Create enemies
	var enemies := _create_test_enemies()

	# Start the battle
	_start_battle(party, enemies)

# =============================================================================
# VERA SETUP
# =============================================================================

func _setup_vera() -> void:
	GameManager.vera_corruption = starting_corruption
	GameManager.vera_state = vera_state

	EventBus.emit_debug("VERA set to state %s with corruption %.1f%%" % [
		Enums.VERAState.keys()[vera_state],
		starting_corruption
	])

# =============================================================================
# PARTY CREATION
# =============================================================================

func _create_test_party() -> Array[CharacterBase]:
	var party: Array[CharacterBase] = []

	# Create protagonist (the player character) - "Rend" matches hero sprite
	var protagonist := _create_test_character("Rend", party_level, Enums.Brand.FANG)
	protagonist.is_protagonist = true
	party.append(protagonist)

	# Create allied monsters (recruited/captured monsters that fight with the player)
	var ally_monster_templates := [
		{"name": "Mawling", "id": "mawling", "brand": Enums.Brand.SAVAGE},
		{"name": "Hollow", "id": "hollow", "brand": Enums.Brand.VOID},
		{"name": "Flicker", "id": "flicker", "brand": Enums.Brand.SURGE}
	]

	for i in range(mini(ally_monster_count, ally_monster_templates.size())):
		var template: Dictionary = ally_monster_templates[i]
		var ally_monster := _create_ally_monster(template.id, party_level, template.brand)
		ally_monster.character_name = template.name
		party.append(ally_monster)

	EventBus.emit_debug("Created test party: 1 player + %d allied monsters" % (party.size() - 1))
	return party

func _create_ally_monster(monster_id: String, level: int, brand: Enums.Brand) -> Monster:
	var monster := Monster.new()

	monster.monster_id = monster_id
	monster.level = level
	monster.brand = brand
	monster.character_type = Enums.CharacterType.MONSTER
	monster.is_corrupted = false  # Allied monsters are purified/recruited

	# Base stats scaled by level
	monster.base_max_hp = 60 + (level * 10)
	monster.base_attack = 12 + (level * 2)
	monster.base_defense = 8 + level
	monster.base_magic = 10 + level
	monster.base_speed = 10 + level

	monster.current_hp = monster.base_max_hp

	# No corruption - this is an ally
	monster.corruption_level = 0.0

	# Add skills
	monster.known_skills = ["basic_attack", "fury_strike"]

	monster.rarity = Enums.Rarity.COMMON

	return monster

func _create_test_character(char_name: String, level: int, brand: Enums.Brand) -> CharacterBase:
	var character := CharacterBase.new()

	character.character_name = char_name
	character.level = level
	character.brand = brand

	# Base stats scaled by level
	character.base_max_hp = 100 + (level * 15)
	character.base_max_mp = 30 + (level * 5)
	character.base_attack = 15 + (level * 3)
	character.base_defense = 10 + (level * 2)
	character.base_magic = 12 + (level * 3)
	character.base_resistance = 8 + (level * 2)
	character.base_speed = 10 + (level * 2)

	# Full HP/MP
	character.current_hp = character.base_max_hp
	character.current_mp = character.base_max_mp

	# Add brand-specific bonuses
	_apply_brand_bonuses(character, brand)

	# Add some test skills
	_add_test_skills(character)

	return character

func _apply_brand_bonuses(character: CharacterBase, brand: Enums.Brand) -> void:
	match brand:
		Enums.Brand.FANG:
			character.base_attack += 5
			character.base_speed += 3
		Enums.Brand.RADIANT:
			character.base_magic += 5
			character.base_resistance += 3
		Enums.Brand.BULWARK:
			character.base_max_hp += 30
			character.base_defense += 5
		Enums.Brand.VOID:
			character.base_max_mp += 15
			character.base_magic += 3
		Enums.Brand.EMBER:
			character.base_magic += 5
			character.base_attack += 2
		Enums.Brand.FROST:
			character.base_magic += 3
			character.base_defense += 3

func _add_test_skills(character: CharacterBase) -> void:
	# Add basic attack skill
	character.known_skills.append("basic_attack")

	# Add brand-specific skill
	match character.brand:
		Enums.Brand.FANG:
			character.known_skills.append("fury_strike")
		Enums.Brand.RADIANT:
			character.known_skills.append("prismatic_ray")
		Enums.Brand.BULWARK:
			character.known_skills.append("stone_wall")
		Enums.Brand.VOID:
			character.known_skills.append("drain_essence")
		Enums.Brand.EMBER:
			character.known_skills.append("fire_blast")
		Enums.Brand.FROST:
			character.known_skills.append("ice_shard")
		_:
			character.known_skills.append("power_strike")

	# Add healing skill to support character
	if character.brand == Enums.Brand.RADIANT:
		character.known_skills.append("healing_light")

# =============================================================================
# ENEMY CREATION
# =============================================================================

func _create_test_enemies() -> Array[CharacterBase]:
	var enemies: Array[CharacterBase] = []

	for i in range(enemy_count):
		var enemy := _create_test_enemy(enemy_type, enemy_level + randi_range(-1, 1))
		enemies.append(enemy)

	EventBus.emit_debug("Created %d test enemies" % enemies.size())
	return enemies

func _create_test_enemy(monster_id: String, level: int) -> Monster:
	var monster := Monster.new()

	monster.monster_id = monster_id
	monster.character_name = monster_id.capitalize().replace("_", " ")
	monster.level = level
	monster.character_type = Enums.CharacterType.MONSTER  # Enemies are monsters
	monster.is_corrupted = true  # Enemy monsters are corrupted

	# Base stats scaled by level
	monster.base_max_hp = 40 + (level * 8)
	monster.base_attack = 10 + (level * 2)
	monster.base_defense = 6 + level
	monster.base_magic = 8 + level
	monster.base_speed = 8 + level

	monster.current_hp = monster.base_max_hp

	# Corruption level for purification
	monster.corruption_level = 40.0 + randf() * 30.0
	monster.corruption_resistance = level * 0.5

	# Add enemy skills
	monster.known_skills = ["basic_attack", "shadow_claw"]

	# Random rarity
	var rarity_roll := randf()
	if rarity_roll < 0.6:
		monster.rarity = Enums.Rarity.COMMON
	elif rarity_roll < 0.85:
		monster.rarity = Enums.Rarity.UNCOMMON
	elif rarity_roll < 0.95:
		monster.rarity = Enums.Rarity.RARE
	else:
		monster.rarity = Enums.Rarity.EPIC

	return monster

# =============================================================================
# BATTLE START
# =============================================================================

func _start_battle(party: Array[CharacterBase], enemies: Array[CharacterBase]) -> void:
	# Register party with GameManager
	GameManager.player_party = party

	# Change game state
	GameManager.change_state(Enums.GameState.BATTLE)

	# Emit battle started signal
	EventBus.battle_started.emit(enemies)

	# Update health bars to show actual party members
	_update_health_bars(party)

	EventBus.emit_debug("Test battle started: %d party vs %d enemies" % [party.size(), enemies.size()])

func _update_health_bars(party: Array[CharacterBase]) -> void:
	var health_bars_container = get_node_or_null("BattleUI/UIRoot/HeroHealthBars")
	if not health_bars_container:
		return

	# Clear existing health bars
	for child in health_bars_container.get_children():
		child.queue_free()

	# Wait a frame for children to be freed
	await get_tree().process_frame

	# Create health bars with portraits for each party member
	for character in party:
		var panel := _create_party_panel_with_portrait(character)
		health_bars_container.add_child(panel)

func _create_party_panel_with_portrait(character: CharacterBase) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 48)  # Compact size

	# Panel style - minimal
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.1, 0.8)
	panel_style.border_color = Color(0.3, 0.25, 0.4, 0.6)
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.corner_radius_top_left = 3
	panel_style.corner_radius_top_right = 3
	panel_style.corner_radius_bottom_left = 3
	panel_style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", panel_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	# Portrait container - smaller
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(32, 32)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	portrait_style.border_color = Color(0.35, 0.3, 0.45, 1.0)
	portrait_style.border_width_top = 1
	portrait_style.border_width_bottom = 1
	portrait_style.border_width_left = 1
	portrait_style.border_width_right = 1
	portrait_style.corner_radius_top_left = 2
	portrait_style.corner_radius_top_right = 2
	portrait_style.corner_radius_bottom_left = 2
	portrait_style.corner_radius_bottom_right = 2
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_container)

	# Load portrait texture
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(30, 30)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# Try to load portrait based on character
	var portrait_path := _get_character_portrait_path(character)
	if portrait_path != "":
		var tex := load(portrait_path)
		if tex:
			portrait.texture = tex
	portrait_container.add_child(portrait)

	# Info container (name + bars)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))
	vbox.add_child(name_label)

	# HP Bar with custom frame - compact
	var hp_container := Control.new()
	hp_container.custom_minimum_size = Vector2(95, 14)
	vbox.add_child(hp_container)

	# HP frame background
	var hp_frame := TextureRect.new()
	var hp_frame_tex := load("res://assets/ui/bars/hp_bar_frame.png")
	if hp_frame_tex:
		hp_frame.texture = hp_frame_tex
		hp_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hp_frame.stretch_mode = TextureRect.STRETCH_SCALE
		hp_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		hp_frame.size = Vector2(95, 14)
		hp_container.add_child(hp_frame)

	# HP fill bar - scaled for smaller frame
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.position = Vector2(22, 4)  # Scaled offset
	hp_bar.size = Vector2(65, 6)  # Scaled fill area
	hp_bar.name = "HPBar"

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.85, 0.2, 0.2, 1.0)
	hp_fill.corner_radius_top_left = 1
	hp_fill.corner_radius_top_right = 1
	hp_fill.corner_radius_bottom_left = 1
	hp_fill.corner_radius_bottom_right = 1
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var hp_bg := StyleBoxEmpty.new()
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_container.add_child(hp_bar)

	# MP Bar with custom frame - compact
	var mp_container := Control.new()
	mp_container.custom_minimum_size = Vector2(95, 14)
	vbox.add_child(mp_container)

	# MP frame background
	var mp_frame := TextureRect.new()
	var mp_frame_tex := load("res://assets/ui/bars/mp_bar_frame.png")
	if mp_frame_tex:
		mp_frame.texture = mp_frame_tex
		mp_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mp_frame.stretch_mode = TextureRect.STRETCH_SCALE
		mp_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		mp_frame.size = Vector2(95, 14)
		mp_container.add_child(mp_frame)

	# MP fill bar - scaled for smaller frame
	var mp_bar := ProgressBar.new()
	mp_bar.max_value = character.get_max_mp() if character.has_method("get_max_mp") else 100
	mp_bar.value = character.current_mp if "current_mp" in character else 100
	mp_bar.show_percentage = false
	mp_bar.position = Vector2(22, 4)  # Scaled offset
	mp_bar.size = Vector2(65, 6)  # Scaled fill area
	mp_bar.name = "MPBar"

	var mp_fill := StyleBoxFlat.new()
	mp_fill.bg_color = Color(0.3, 0.5, 0.95, 1.0)
	mp_fill.corner_radius_top_left = 1
	mp_fill.corner_radius_top_right = 1
	mp_fill.corner_radius_bottom_left = 1
	mp_fill.corner_radius_bottom_right = 1
	mp_bar.add_theme_stylebox_override("fill", mp_fill)

	var mp_bg := StyleBoxEmpty.new()
	mp_bar.add_theme_stylebox_override("background", mp_bg)
	mp_container.add_child(mp_bar)

	# Store references
	character.set_meta("hp_bar", hp_bar)
	character.set_meta("mp_bar", mp_bar)

	return panel

func _get_character_portrait_path(character: CharacterBase) -> String:
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

# =============================================================================
# DEBUG CONTROLS
# =============================================================================

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	# F5 - Restart battle
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		_restart_battle()

	# F6 - Win battle instantly
	if event is InputEventKey and event.pressed and event.keycode == KEY_F6:
		_debug_win_battle()

	# F7 - Lose battle instantly
	if event is InputEventKey and event.pressed and event.keycode == KEY_F7:
		_debug_lose_battle()

	# F8 - Toggle VERA state
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		_debug_cycle_vera_state()

	# F9 - Add corruption
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		_debug_add_corruption()

func _restart_battle() -> void:
	EventBus.emit_debug("Restarting test battle...")
	get_tree().reload_current_scene()

func _debug_win_battle() -> void:
	EventBus.emit_debug("DEBUG: Forcing battle victory")
	var rewards := {
		"experience": 100 * enemy_count,
		"currency": 50 * enemy_count,
		"items": []
	}
	EventBus.battle_ended.emit(true, rewards)
	GameManager.change_state(Enums.GameState.OVERWORLD)

func _debug_lose_battle() -> void:
	EventBus.emit_debug("DEBUG: Forcing battle defeat")
	EventBus.battle_ended.emit(false, {})
	GameManager.change_state(Enums.GameState.GAME_OVER)

func _debug_cycle_vera_state() -> void:
	var current := GameManager.vera_state as int
	var next := (current + 1) % Enums.VERAState.size()
	GameManager.update_vera_state(next as Enums.VERAState)
	EventBus.emit_debug("DEBUG: VERA state changed to %s" % Enums.VERAState.keys()[next])

func _debug_add_corruption() -> void:
	GameManager.use_vera_power(10.0)
	EventBus.emit_debug("DEBUG: Added 10 corruption (now %.1f%%)" % GameManager.vera_corruption)

# =============================================================================
# BATTLE CALLBACKS
# =============================================================================

func _on_battle_ended(victory: bool, _rewards: Dictionary) -> void:
	if victory:
		EventBus.emit_debug("Test battle WON!")
	else:
		EventBus.emit_debug("Test battle LOST!")
