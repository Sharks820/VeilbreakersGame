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
	# Using SAVAGE brand for attack-focused protagonist (v5.0 Brand system)
	var protagonist := _create_test_character("Rend", party_level, Enums.Brand.SAVAGE)
	protagonist.is_protagonist = true
	party.append(protagonist)

	# Create allied monsters (recruited/captured monsters that fight with the player)
	# Using valid v5.0 Brand system values: SAVAGE, IRON, VENOM, SURGE, DREAD, LEECH
	var ally_monster_templates := [
		{"name": "Mawling", "id": "mawling", "brand": Enums.Brand.SAVAGE},
		{"name": "Hollow", "id": "hollow", "brand": Enums.Brand.DREAD},  # Dark/void creature
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
	# Try to load from MonsterData resource first (proper brand/stats from .tres)
	var data_path := "res://data/monsters/%s.tres" % monster_id
	if ResourceLoader.exists(data_path):
		var monster_data: MonsterData = load(data_path)
		if monster_data:
			var monster := monster_data.create_instance(level)
			monster.is_corrupted = false  # Allied monsters are purified/recruited
			monster.corruption_level = 0.0  # No corruption - this is an ally
			return monster
	
	# Fallback: create basic monster manually
	var monster := Monster.new()

	monster.monster_id = monster_id
	monster.character_name = monster_id.capitalize()
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

func _create_test_character(char_name: String, level: int, brand: Enums.Brand, path: Enums.Path = Enums.Path.FANGBORN) -> CharacterBase:
	var character := CharacterBase.new()

	character.character_name = char_name
	character.level = level
	character.brand = brand
	character.current_path = path  # Set the character's Path
	character.character_type = Enums.CharacterType.PLAYER  # Set as player for proper battle handling

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
	# v5.0 Brand system bonuses - matches Constants.BRAND_BONUSES
	match brand:
		Enums.Brand.SAVAGE:
			# +25% ATK - Raw destruction
			character.base_attack += 5
			character.base_speed += 3
		Enums.Brand.IRON:
			# +30% HP - Unyielding defense
			character.base_max_hp += 30
			character.base_defense += 5
		Enums.Brand.VENOM:
			# +20% Crit, +15% Status - Precision poison
			character.base_attack += 3
			character.base_speed += 2
		Enums.Brand.SURGE:
			# +25% SPD - Lightning speed
			character.base_speed += 5
			character.base_attack += 2
		Enums.Brand.DREAD:
			# +20% Evasion, +15% Fear - Terror incarnate
			character.base_speed += 4
			character.base_magic += 3
		Enums.Brand.LEECH:
			# +20% Lifesteal - Life drain
			character.base_magic += 5
			character.base_resistance += 3
		# Hybrid brands use primary brand bonuses at 70%
		Enums.Brand.BLOODIRON:  # SAVAGE(70%) + IRON(30%)
			character.base_attack += 4
			character.base_max_hp += 10
		Enums.Brand.CORROSIVE:  # IRON(70%) + VENOM(30%)
			character.base_max_hp += 20
			character.base_defense += 3
		Enums.Brand.VENOMSTRIKE:  # VENOM(70%) + SURGE(30%)
			character.base_attack += 3
			character.base_speed += 3
		Enums.Brand.TERRORFLUX:  # SURGE(70%) + DREAD(30%)
			character.base_speed += 4
			character.base_magic += 2
		Enums.Brand.NIGHTLEECH:  # DREAD(70%) + LEECH(30%)
			character.base_speed += 3
			character.base_magic += 3
		Enums.Brand.RAVENOUS:  # LEECH(70%) + SAVAGE(30%)
			character.base_magic += 4
			character.base_attack += 2

func _add_test_skills(character: CharacterBase) -> void:
	# Add basic attack skill
	character.known_skills.append("basic_attack")

	# Add brand-specific skill (v5.0 Brand system)
	match character.brand:
		Enums.Brand.SAVAGE:
			character.known_skills.append("fury_strike")  # Raw destruction
		Enums.Brand.IRON:
			character.known_skills.append("stone_wall")  # Unyielding defense
		Enums.Brand.VENOM:
			character.known_skills.append("poison_fang")  # Precision poison
		Enums.Brand.SURGE:
			character.known_skills.append("lightning_dash")  # Lightning speed
		Enums.Brand.DREAD:
			character.known_skills.append("terror_shriek")  # Terror incarnate
		Enums.Brand.LEECH:
			character.known_skills.append("drain_essence")  # Life drain
		# Hybrid brands get primary brand skill
		Enums.Brand.BLOODIRON, Enums.Brand.RAVENOUS:
			character.known_skills.append("fury_strike")  # SAVAGE-based
		Enums.Brand.CORROSIVE:
			character.known_skills.append("stone_wall")  # IRON-based
		Enums.Brand.VENOMSTRIKE:
			character.known_skills.append("poison_fang")  # VENOM-based
		Enums.Brand.TERRORFLUX:
			character.known_skills.append("lightning_dash")  # SURGE-based
		Enums.Brand.NIGHTLEECH:
			character.known_skills.append("terror_shriek")  # DREAD-based
		_:
			character.known_skills.append("power_strike")

	# Add lifesteal skill to LEECH brand characters
	if character.brand == Enums.Brand.LEECH or character.brand == Enums.Brand.NIGHTLEECH or character.brand == Enums.Brand.RAVENOUS:
		character.known_skills.append("life_siphon")

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
	# Try to load from MonsterData resource first (proper brand/stats)
	var data_path := "res://data/monsters/%s.tres" % monster_id
	if ResourceLoader.exists(data_path):
		var monster_data: MonsterData = load(data_path)
		if monster_data:
			var monster := monster_data.create_instance(level)
			monster.is_corrupted = true  # Enemy monsters are corrupted
			# Wild monsters are 80%+ corrupted
			monster.corruption_level = 80.0 + randf() * 20.0
			return monster
	
	# Fallback: create basic monster manually (brand will be NONE)
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

	# Corruption level for purification (wild monsters are 80%+ corrupted)
	monster.corruption_level = 80.0 + randf() * 20.0
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
	# DEBUG: Log party and enemy details before starting
	print("[DEBUG] _start_battle called")
	print("[DEBUG]   Party size: %d" % party.size())
	for i in range(party.size()):
		print("[DEBUG]   Party[%d]: %s (type: %s)" % [i, party[i].character_name, Enums.CharacterType.keys()[party[i].character_type]])
	print("[DEBUG]   Enemies size: %d" % enemies.size())
	for i in range(enemies.size()):
		print("[DEBUG]   Enemy[%d]: %s (corrupted: %s)" % [i, enemies[i].character_name, enemies[i].is_corrupted if enemies[i] is Monster else "N/A"])
	
	# Register party with GameManager
	GameManager.player_party = party
	print("[DEBUG]   GameManager.player_party set, size: %d" % GameManager.player_party.size())

	# Change game state
	GameManager.change_state(Enums.GameState.BATTLE)

	# Emit battle started signal
	print("[DEBUG]   Emitting EventBus.battle_started with %d enemies" % enemies.size())
	EventBus.battle_started.emit(enemies)
	print("[DEBUG]   EventBus.battle_started emitted")

	# Note: Health bars are now handled by the real battle_ui.tscn loaded via battle_arena.gd

	EventBus.emit_debug("Test battle started: %d party vs %d enemies" % [party.size(), enemies.size()])

	# DEBUG AUTO-ATTACK DISABLED - Waiting for player input now
	# Use F11 to manually trigger auto-attack if needed

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

func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	var fled: bool = rewards.get("fled", false)
	if victory:
		EventBus.emit_debug("Test battle WON!")
	elif fled:
		EventBus.emit_debug("Test battle FLED!")
	else:
		EventBus.emit_debug("Test battle LOST!")
