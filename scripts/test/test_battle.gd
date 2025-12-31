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
@export var enemy_type: String = "ravener"

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

	# Remove the fake placeholder BattleUI - it has disconnected TextureButtons
	# The real battle_ui.tscn is loaded by battle_arena.gd with connected buttons
	var fake_ui = get_node_or_null("BattleUI")
	if fake_ui:
		fake_ui.queue_free()

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

	# Note: Health bars are now handled by the real battle_ui.tscn loaded via battle_arena.gd

	EventBus.emit_debug("Test battle started: %d party vs %d enemies" % [party.size(), enemies.size()])

	# Auto-test damage numbers after 3 seconds (for debugging)
	await get_tree().create_timer(3.0).timeout
	_debug_auto_attack()

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

	# F10 - Test damage numbers
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		_debug_test_damage_numbers()

	# F11 - Auto-attack first enemy
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		_debug_auto_attack()

func _debug_test_damage_numbers() -> void:
	# Emit fake damage events to test the damage number display system
	var party = GameManager.player_party
	if party.is_empty():
		EventBus.emit_debug("No party to test damage on")
		return

	var target = party[0]
	EventBus.emit_debug("Testing damage numbers on %s" % target.character_name)

	# Test regular damage
	EventBus.damage_dealt.emit(null, target, 42, false)

	# Test critical damage after short delay
	await get_tree().create_timer(0.3).timeout
	EventBus.damage_dealt.emit(null, target, 128, true)

	# Test healing after another delay
	await get_tree().create_timer(0.3).timeout
	EventBus.healing_done.emit(null, target, 25)

func _debug_auto_attack() -> void:
	EventBus.emit_debug("_debug_auto_attack called")
	print("[TEST] _debug_auto_attack called")

	if not battle_arena:
		EventBus.emit_debug("battle_arena is null!")
		print("[TEST] battle_arena is null!")
		return

	if not battle_arena.battle_manager:
		EventBus.emit_debug("battle_manager is null!")
		print("[TEST] battle_manager is null!")
		return

	var bm = battle_arena.battle_manager
	print("[TEST] enemy_party size: %d" % bm.enemy_party.size())

	if bm.enemy_party.is_empty():
		EventBus.emit_debug("No enemies to attack")
		print("[TEST] No enemies in enemy_party")
		return

	var attacker = GameManager.player_party[0] if not GameManager.player_party.is_empty() else null
	var target = bm.enemy_party[0]

	if attacker and target:
		EventBus.emit_debug("Auto-attacking %s with %s" % [target.character_name, attacker.character_name])
		print("[TEST] Attacking %s (HP: %d) with %s" % [target.character_name, target.current_hp, attacker.character_name])
		# Directly deal damage to test the system
		var result = target.take_damage(50, attacker, false)
		print("[TEST] Damage result: %s" % str(result))
		print("[TEST] Target HP after: %d" % target.current_hp)
	else:
		print("[TEST] attacker or target is null: attacker=%s, target=%s" % [str(attacker), str(target)])

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
