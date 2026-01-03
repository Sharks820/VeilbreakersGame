extends Node
## TestBattle: Sets up and runs a test battle for debugging and development.
## Also serves as the TUTORIAL BATTLE when tutorial_battle_pending flag is set.

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
# TUTORIAL STATE
# =============================================================================

var is_tutorial: bool = false
var tutorial_step: int = 0
var tutorial_dialogue_shown: bool = false
var vera_tutorial_panel: Control = null

# Smooth breathing animation state (using _process for frame-perfect animation)
var _vera_breathing_time: float = 0.0
var _vera_breathing_enabled: bool = false
var _vera_breathing_portrait: TextureRect = null

# Tutorial progress tracking
var _tutorial_shown_turn_start: bool = false
var _tutorial_shown_action_selected: bool = false
var _tutorial_shown_first_attack: bool = false
var _tutorial_shown_enemy_low_hp: bool = false
var _tutorial_first_round: bool = true

const TUTORIAL_DIALOGUES: Array[Dictionary] = [
	{
		"trigger": "battle_start",
		"speaker": "V.E.R.A.",
		"text": "Welcome to your first battle, Hunter. I'll guide you through the basics.\n\nThe corrupted creatures before you must be defeated... or [color=#88ff88]purified[/color] and recruited to your cause.",
		"highlight": "",
		"arrow_target": ""
	},
	{
		"trigger": "turn_start",
		"speaker": "V.E.R.A.",
		"text": "Each round, you'll select actions for your entire party before they execute.\n\n[color=#ffaa88]ATTACK[/color] - Deal physical damage\n[color=#88aaff]SKILLS[/color] - Use special abilities\n[color=#88ff88]PURIFY[/color] - Attempt to capture weakened monsters",
		"highlight": "action_bar",
		"arrow_target": "action_buttons"
	},
	{
		"trigger": "action_selected",
		"speaker": "V.E.R.A.",
		"text": "Excellent. Now select a [color=#ff8888]target[/color] for your attack.\n\nEnemies are highlighted in [color=#ff6666]RED[/color]. Click on one to confirm your action.",
		"highlight": "enemies",
		"arrow_target": "enemy_sidebar"
	},
	{
		"trigger": "first_attack",
		"speaker": "V.E.R.A.",
		"text": "Well done! Notice the [color=#ffff88]Brand effectiveness[/color] system:\n\nSAVAGE → IRON → VENOM → SURGE → DREAD → LEECH → SAVAGE\n\nAttacking a Brand you're strong against deals [color=#88ff88]1.5x damage[/color]!",
		"highlight": "",
		"arrow_target": ""
	},
	{
		"trigger": "enemy_low_hp",
		"speaker": "V.E.R.A.",
		"text": "That creature is weakened! You can now attempt to [color=#88ff88]PURIFY[/color] it.\n\n[color=#cc88ff]PURIFY[/color] reduces a monster's corruption. When corruption is low enough, the monster can be captured and join your party!\n\n[color=#aaaaaa]Lower corruption = Stronger ally when captured[/color]",
		"highlight": "purify_button",
		"arrow_target": "purify_button"
	},
	{
		"trigger": "battle_end",
		"speaker": "V.E.R.A.",
		"text": "Victory! You've completed your first battle.\n\nRemember: the monsters you capture will synergize with your [color=#ffcc88]Path[/color]. Choose wisely, Hunter.",
		"highlight": "",
		"arrow_target": ""
	}
]

# =============================================================================
# NODES
# =============================================================================

var battle_arena: Node2D = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.emit_debug("TestBattle scene loaded")
	
	# Enable processing even when paused (for breathing animation during tutorial)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Check if this is a tutorial battle
	is_tutorial = GameManager.get_story_flag("tutorial_battle_pending", false)
	if is_tutorial:
		EventBus.emit_debug("TUTORIAL MODE ACTIVE")
		# Use easier settings for tutorial
		enemy_count = 2
		enemy_level = 5
		enemy_type = "hollow"  # Easier enemy for tutorial
		ally_monster_count = 1  # Just player + 1 monster for simplicity

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
	
	# Start tutorial if applicable
	if is_tutorial:
		# Connect to battle events for tutorial triggers
		_connect_tutorial_signals()
		await get_tree().create_timer(0.5).timeout
		_show_tutorial_step("battle_start")

func _process(delta: float) -> void:
	# Smooth VERA portrait breathing animation using sine wave - no frame skipping
	# This runs even when paused because process_mode = PROCESS_MODE_ALWAYS
	if _vera_breathing_enabled and _vera_breathing_portrait and is_instance_valid(_vera_breathing_portrait):
		_vera_breathing_time += delta
		# Gentle sine wave pulse on modulate for smooth glow effect
		var pulse: float = sin(_vera_breathing_time * 2.0) * 0.5 + 0.5  # 0 to 1 range
		var glow_intensity: float = 1.0 + pulse * 0.15  # 1.0 to 1.15 range
		_vera_breathing_portrait.modulate = Color(glow_intensity, glow_intensity * 0.95, glow_intensity * 1.05, 1.0)

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

	# Check if player has a selected hero from character select
	var player_char: PlayerCharacter = GameManager.get_player_character()
	if player_char:
		# Use the actual selected hero
		player_char.is_protagonist = true
		party.append(player_char)
		EventBus.emit_debug("Using selected hero: %s" % player_char.character_name)
	else:
		# Fallback: Create protagonist (the player character) - "Rend" matches hero sprite
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
		# Use proper battle system to trigger full animation flow
		# This calls execute_action which emits action_animation_started signal
		bm.execute_action(attacker, Enums.BattleAction.ATTACK, target, "")
		print("[TEST] Attack action submitted via battle manager")
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
		if is_tutorial:
			_show_tutorial_step("battle_end")
			# Mark tutorial as complete
			GameManager.set_story_flag("tutorial_battle_pending", false)
			GameManager.set_story_flag("tutorial_complete", true)
	elif fled:
		EventBus.emit_debug("Test battle FLED!")
	else:
		EventBus.emit_debug("Test battle LOST!")

# =============================================================================
# TUTORIAL SIGNAL CONNECTIONS
# =============================================================================

func _connect_tutorial_signals() -> void:
	"""Connect to battle events to trigger tutorial steps at the right moments"""
	if not is_tutorial:
		return
	
	# Connect to EventBus signals for tutorial triggers
	if not EventBus.action_selected.is_connected(_on_tutorial_action_selected):
		EventBus.action_selected.connect(_on_tutorial_action_selected)
	if not EventBus.damage_dealt.is_connected(_on_tutorial_damage_dealt):
		EventBus.damage_dealt.connect(_on_tutorial_damage_dealt)
	if not EventBus.turn_started.is_connected(_on_tutorial_turn_started):
		EventBus.turn_started.connect(_on_tutorial_turn_started)
	
	# Get battle manager reference for round tracking
	if battle_arena:
		var bm: BattleManager = battle_arena.get_node_or_null("BattleManager")
		if bm and bm.has_signal("waiting_for_player_input"):
			if not bm.waiting_for_player_input.is_connected(_on_tutorial_waiting_for_input):
				bm.waiting_for_player_input.connect(_on_tutorial_waiting_for_input)

func _on_tutorial_waiting_for_input() -> void:
	"""Called when battle is waiting for player input - show turn_start tutorial"""
	if not is_tutorial or _tutorial_shown_turn_start:
		return
	_tutorial_shown_turn_start = true
	# Small delay so player sees the battle state first
	await get_tree().create_timer(0.3).timeout
	_show_tutorial_step("turn_start")

func _on_tutorial_action_selected(_character: Node, action: int, _target: Node) -> void:
	"""Called when player selects an action - show targeting tutorial"""
	if not is_tutorial or _tutorial_shown_action_selected:
		return
	# Only trigger on first action selection (Attack)
	if action == Enums.BattleAction.ATTACK:
		_tutorial_shown_action_selected = true
		await get_tree().create_timer(0.2).timeout
		_show_tutorial_step("action_selected")

func _on_tutorial_turn_started(character: Node) -> void:
	"""Called when a turn starts - track for first attack tutorial"""
	pass  # Reserved for future use

func _on_tutorial_damage_dealt(_source: Node, target: Node, amount: int, _is_critical: bool) -> void:
	"""Called when damage is dealt - show brand effectiveness or low HP tutorial"""
	if not is_tutorial:
		return
	
	# Show first attack tutorial after first damage
	if not _tutorial_shown_first_attack and _tutorial_first_round:
		_tutorial_shown_first_attack = true
		_tutorial_first_round = false
		await get_tree().create_timer(0.5).timeout
		_show_tutorial_step("first_attack")
		return
	
	# Check if enemy is low HP for purify tutorial
	if not _tutorial_shown_enemy_low_hp and target is CharacterBase:
		var char_target: CharacterBase = target as CharacterBase
		var hp_percent: float = float(char_target.current_hp) / float(char_target.get_max_hp())
		if hp_percent <= 0.35 and hp_percent > 0:  # Below 35% HP but not dead
			_tutorial_shown_enemy_low_hp = true
			await get_tree().create_timer(0.3).timeout
			_show_tutorial_step("enemy_low_hp")

# =============================================================================
# TUTORIAL SYSTEM
# =============================================================================

func _show_tutorial_step(trigger: String) -> void:
	"""Show a tutorial dialogue for the given trigger"""
	if not is_tutorial:
		return
	
	# Find the dialogue for this trigger
	for dialogue in TUTORIAL_DIALOGUES:
		if dialogue.trigger == trigger:
			_display_vera_tutorial(dialogue)
			return

func _display_vera_tutorial(dialogue: Dictionary) -> void:
	"""Display VERA tutorial panel with the given dialogue - PAUSES GAME"""
	# Create or get the tutorial panel
	if not vera_tutorial_panel:
		_create_vera_tutorial_panel()
	
	# PAUSE THE GAME during tutorial
	get_tree().paused = true
	vera_tutorial_panel.process_mode = Node.PROCESS_MODE_ALWAYS  # Panel works while paused
	
	# Add darkening overlay behind the panel
	_show_tutorial_overlay()
	
	# Show highlight and arrow FIRST (before text) so user sees what we're referring to
	# This also ensures the UI elements are captured before any state changes
	if dialogue.highlight != "":
		_highlight_ui_element(dialogue.highlight)
	
	if dialogue.has("arrow_target") and dialogue.arrow_target != "":
		_show_tutorial_arrow(dialogue.arrow_target)
	
	vera_tutorial_panel.visible = true
	
	# Update content - use new node paths
	var speaker_label: Label = vera_tutorial_panel.get_node("MainVBox/HBox/VBox/SpeakerLabel")
	var text_label: RichTextLabel = vera_tutorial_panel.get_node("MainVBox/HBox/VBox/TextLabel")
	var portrait: TextureRect = vera_tutorial_panel.get_node("MainVBox/HBox/PortraitFrame/Portrait")
	var continue_button: Button = vera_tutorial_panel.get_node("MainVBox/ButtonContainer/ContinueButton")
	var hint_label: Label = vera_tutorial_panel.get_node("MainVBox/HintLabel")
	
	speaker_label.text = dialogue.speaker
	text_label.text = ""
	continue_button.visible = false
	hint_label.visible = false
	
	# Load VERA portrait immediately
	if ResourceLoader.exists("res://assets/characters/vera/vera_interface.png"):
		portrait.texture = load("res://assets/characters/vera/vera_interface.png")
	
	# Start smooth breathing animation on portrait
	_start_vera_tutorial_breathing(portrait)
	
	# Typewriter effect - FAST for snappy UX (3-4 chars at a time)
	var full_text: String = dialogue.text
	var chars_per_tick := 3  # Show 3 characters at a time for speed
	var i := 0
	while i < full_text.length():
		i = mini(i + chars_per_tick, full_text.length())
		text_label.text = full_text.substr(0, i)
		await get_tree().create_timer(0.008).timeout  # 8ms per tick (was 15ms per char)
	
	# Wait briefly then show continue button
	await get_tree().create_timer(0.3).timeout
	
	# Show continue button and hint
	continue_button.visible = true
	hint_label.visible = true
	continue_button.grab_focus()
	
	# Connect button signal (disconnect first to avoid duplicates)
	if continue_button.pressed.is_connected(_on_tutorial_continue_pressed):
		continue_button.pressed.disconnect(_on_tutorial_continue_pressed)
	continue_button.pressed.connect(_on_tutorial_continue_pressed)
	
	# Wait for input (button click OR keyboard)
	await _wait_for_tutorial_continue()
	
	# Hide and cleanup
	continue_button.visible = false
	hint_label.visible = false
	vera_tutorial_panel.visible = false
	_stop_vera_tutorial_breathing()
	_clear_highlights()
	_hide_tutorial_arrow()
	_hide_tutorial_overlay()
	
	# UNPAUSE THE GAME
	get_tree().paused = false

var _tutorial_continue_pressed: bool = false

func _on_tutorial_continue_pressed() -> void:
	"""Called when continue button is clicked"""
	_tutorial_continue_pressed = true

func _create_vera_tutorial_panel() -> void:
	"""Create the VERA tutorial panel UI - positioned in CENTER of screen"""
	vera_tutorial_panel = PanelContainer.new()
	vera_tutorial_panel.name = "VERATutorialPanel"
	
	# Position in CENTER of screen - not at bottom where buttons are
	vera_tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	vera_tutorial_panel.anchor_left = 0.5
	vera_tutorial_panel.anchor_right = 0.5
	vera_tutorial_panel.anchor_top = 0.5
	vera_tutorial_panel.anchor_bottom = 0.5
	vera_tutorial_panel.offset_left = -450
	vera_tutorial_panel.offset_right = 450
	vera_tutorial_panel.offset_top = -120  # Center vertically
	vera_tutorial_panel.offset_bottom = 120
	
	# Style - dark fantasy horror theme
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.98)
	style.border_color = Color(0.5, 0.35, 0.6, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.3, 0.2, 0.4, 0.5)
	style.shadow_size = 15
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	vera_tutorial_panel.add_theme_stylebox_override("panel", style)
	
	# Main content container
	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 12)
	vera_tutorial_panel.add_child(main_vbox)
	
	# Content row (portrait + text)
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(hbox)
	
	# Portrait with circular frame
	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.custom_minimum_size = Vector2(90, 90)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.06, 0.1, 1.0)
	frame_style.border_color = Color(0.5, 0.4, 0.6, 1.0)
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(45)  # Circular frame
	portrait_frame.add_theme_stylebox_override("panel", frame_style)
	hbox.add_child(portrait_frame)
	
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(84, 84)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_frame.add_child(portrait)
	
	# Text content
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var speaker := Label.new()
	speaker.name = "SpeakerLabel"
	speaker.add_theme_font_size_override("font_size", 20)
	speaker.add_theme_color_override("font_color", Color(0.7, 0.55, 0.8))
	vbox.add_child(speaker)
	
	var text := RichTextLabel.new()
	text.name = "TextLabel"
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size.y = 80
	text.add_theme_font_size_override("normal_font_size", 15)
	text.add_theme_color_override("default_color", Color(0.88, 0.83, 0.78))
	vbox.add_child(text)
	
	# Continue button (replaces keyboard prompt)
	var continue_button := Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "▶ CONTINUE"
	continue_button.custom_minimum_size = Vector2(180, 40)
	continue_button.visible = false
	
	# Style the continue button
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.12, 0.2, 0.95)
	btn_normal.border_color = Color(0.5, 0.4, 0.6, 0.8)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(6)
	
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.25, 0.2, 0.35, 0.98)
	btn_hover.border_color = Color(0.7, 0.55, 0.8, 1.0)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(6)
	btn_hover.shadow_color = Color(0.5, 0.3, 0.6, 0.4)
	btn_hover.shadow_size = 6
	
	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.35, 0.28, 0.45, 1.0)
	btn_pressed.border_color = Color(0.8, 0.65, 0.9, 1.0)
	btn_pressed.set_border_width_all(2)
	btn_pressed.set_corner_radius_all(6)
	
	continue_button.add_theme_stylebox_override("normal", btn_normal)
	continue_button.add_theme_stylebox_override("hover", btn_hover)
	continue_button.add_theme_stylebox_override("pressed", btn_pressed)
	continue_button.add_theme_font_size_override("font_size", 14)
	continue_button.add_theme_color_override("font_color", Color(0.9, 0.85, 0.95))
	continue_button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 1.0))
	
	# Center the button
	var button_container := CenterContainer.new()
	button_container.name = "ButtonContainer"
	button_container.add_child(continue_button)
	main_vbox.add_child(button_container)
	
	# Also keep keyboard hint as secondary option
	var hint_label := Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "(or press SPACE/ENTER)"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.5))
	hint_label.visible = false
	main_vbox.add_child(hint_label)
	
	# Add to scene on high layer
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(vera_tutorial_panel)

func _start_vera_tutorial_breathing(portrait: TextureRect) -> void:
	"""Start smooth breathing animation on VERA portrait using _process()"""
	if not portrait:
		return
	
	# Enable smooth per-frame breathing animation via _process()
	# This avoids the frame-skipping issues that tweens cause
	# Works even when game is paused because process_mode = PROCESS_MODE_ALWAYS
	_vera_breathing_time = 0.0
	_vera_breathing_portrait = portrait
	_vera_breathing_enabled = true
	portrait.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _stop_vera_tutorial_breathing() -> void:
	"""Stop the breathing animation"""
	_vera_breathing_enabled = false
	if _vera_breathing_portrait and is_instance_valid(_vera_breathing_portrait):
		_vera_breathing_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_vera_breathing_portrait = null

func _wait_for_tutorial_continue() -> void:
	"""Wait for player to press continue (button click OR keyboard)"""
	_tutorial_continue_pressed = false
	while true:
		await get_tree().process_frame
		# Check for button click OR keyboard input
		if _tutorial_continue_pressed:
			break
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
			break

var _tutorial_arrow: Control = null
var _tutorial_overlay: ColorRect = null
var _tutorial_overlay_canvas: CanvasLayer = null
var _highlight_panels: Array[Control] = []

func _show_tutorial_overlay() -> void:
	"""Show a dark overlay behind the tutorial panel to focus attention"""
	if _tutorial_overlay_canvas:
		return  # Already showing
	
	_tutorial_overlay_canvas = CanvasLayer.new()
	_tutorial_overlay_canvas.name = "TutorialOverlayCanvas"
	_tutorial_overlay_canvas.layer = 98  # Below tutorial panel (100) but above game
	_tutorial_overlay_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_tutorial_overlay_canvas)
	
	_tutorial_overlay = ColorRect.new()
	_tutorial_overlay.name = "TutorialOverlay"
	_tutorial_overlay.color = Color(0, 0, 0, 0.7)  # Dark semi-transparent
	_tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks
	_tutorial_overlay_canvas.add_child(_tutorial_overlay)
	
	# Fade in
	_tutorial_overlay.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(_tutorial_overlay, "modulate:a", 1.0, 0.3)

func _hide_tutorial_overlay() -> void:
	"""Hide the tutorial overlay"""
	if _tutorial_overlay_canvas and is_instance_valid(_tutorial_overlay_canvas):
		_tutorial_overlay_canvas.queue_free()
		_tutorial_overlay_canvas = null
		_tutorial_overlay = null

func _highlight_ui_element(element_name: String) -> void:
	"""Highlight a UI element for the tutorial with a glowing border"""
	EventBus.emit_debug("Tutorial highlight: %s" % element_name)
	
	# Try to find actual UI elements from battle arena
	var ui_controller: Control = null
	if battle_arena:
		ui_controller = battle_arena.get_node_or_null("UILayer/BattleUI")
	
	if ui_controller:
		print("[Tutorial] Found BattleUI at: %s" % ui_controller.get_path())
	else:
		print("[Tutorial] WARNING: Could not find UILayer/BattleUI!")
	
	var target_rect: Rect2 = Rect2()
	var found := false
	
	match element_name:
		"action_bar":
			# Find the ActionMenu which contains action buttons
			if ui_controller:
				var action_menu := ui_controller.get_node_or_null("PartyPanel/VBoxContainer/ActionMenu")
				if action_menu and action_menu.visible:
					target_rect = Rect2(action_menu.global_position, action_menu.size)
					found = true
					print("[Tutorial] Found ActionMenu at global_pos: %s, size: %s" % [action_menu.global_position, action_menu.size])
				else:
					# Try PartyPanel as fallback
					var party_panel := ui_controller.get_node_or_null("PartyPanel")
					if party_panel and party_panel.visible:
						target_rect = Rect2(party_panel.global_position, party_panel.size)
						found = true
						print("[Tutorial] Found PartyPanel at global_pos: %s, size: %s" % [party_panel.global_position, party_panel.size])
			if not found:
				# Fallback - bottom center area
				var vs := get_viewport().get_visible_rect().size
				target_rect = Rect2(Vector2(vs.x / 2 - 400, vs.y - 110), Vector2(800, 100))
				print("[Tutorial] Using fallback rect for action_bar")
		"enemies":
			# Find the EnemyPanel (NOT RightEnemySidebar - that doesn't exist!)
			if ui_controller:
				var enemy_panel := ui_controller.get_node_or_null("EnemyPanel")
				if enemy_panel and enemy_panel.visible:
					target_rect = Rect2(enemy_panel.global_position, enemy_panel.size)
					found = true
					print("[Tutorial] Found EnemyPanel at global_pos: %s, size: %s" % [enemy_panel.global_position, enemy_panel.size])
			if not found:
				var vs := get_viewport().get_visible_rect().size
				target_rect = Rect2(Vector2(vs.x - 180, 280), Vector2(170, 350))
				print("[Tutorial] Using fallback rect for enemies")
		"purify_button":
			# Find the actual purify button
			if ui_controller:
				var purify_btn := ui_controller.get_node_or_null("PartyPanel/VBoxContainer/ActionMenu/PurifyButton")
				if purify_btn and purify_btn.visible:
					target_rect = Rect2(purify_btn.global_position, purify_btn.size)
					found = true
					print("[Tutorial] Found PurifyButton at global_pos: %s, size: %s" % [purify_btn.global_position, purify_btn.size])
			if not found:
				var vs := get_viewport().get_visible_rect().size
				target_rect = Rect2(Vector2(vs.x / 2 - 60, vs.y - 95), Vector2(120, 70))
				print("[Tutorial] Using fallback rect for purify_button")
	
	if target_rect.size.x > 0:
		var highlight := _create_highlight_rect(target_rect.position, target_rect.size)
		_highlight_panels.append(highlight)
		print("[Tutorial] Created highlight at pos: %s, size: %s" % [target_rect.position, target_rect.size])

func _create_highlight_rect(pos: Vector2, size: Vector2) -> Control:
	"""Create a pulsing highlight rectangle"""
	var highlight := Panel.new()
	highlight.position = pos
	highlight.size = size
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)  # Transparent background
	style.border_color = Color(1.0, 0.9, 0.3, 1.0)  # Golden border
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	highlight.add_theme_stylebox_override("panel", style)
	
	# Add to overlay canvas so it's visible during pause
	if _tutorial_overlay_canvas:
		_tutorial_overlay_canvas.add_child(highlight)
		highlight.z_index = 5  # Above overlay
	
	# Pulsing animation
	var tween := create_tween().set_loops()
	tween.tween_property(highlight, "modulate:a", 0.5, 0.5)
	tween.tween_property(highlight, "modulate:a", 1.0, 0.5)
	
	return highlight

func _clear_highlights() -> void:
	"""Clear all tutorial highlights"""
	for panel in _highlight_panels:
		if is_instance_valid(panel):
			panel.queue_free()
	_highlight_panels.clear()

func _show_tutorial_arrow(target: String) -> void:
	"""Show an animated arrow pointing to a UI element"""
	_hide_tutorial_arrow()  # Clear any existing arrow
	
	# Try to find actual UI elements from battle arena
	var ui_controller: Control = null
	if battle_arena:
		ui_controller = battle_arena.get_node_or_null("UILayer/BattleUI")
	
	# Create arrow indicator
	_tutorial_arrow = Control.new()
	_tutorial_arrow.name = "TutorialArrow"
	_tutorial_arrow.z_index = 101
	_tutorial_arrow.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var arrow_label := Label.new()
	arrow_label.name = "ArrowLabel"
	arrow_label.add_theme_font_size_override("font_size", 48)
	arrow_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	arrow_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	arrow_label.add_theme_constant_override("outline_size", 4)
	_tutorial_arrow.add_child(arrow_label)
	
	var arrow_pos := Vector2.ZERO
	var viewport_size := get_viewport().get_visible_rect().size
	
	match target:
		"action_buttons":
			arrow_label.text = "▼"
			# Find ActionMenu position (the actual button container)
			if ui_controller:
				var action_menu := ui_controller.get_node_or_null("PartyPanel/VBoxContainer/ActionMenu")
				if action_menu and action_menu.visible:
					arrow_pos = action_menu.global_position + Vector2(action_menu.size.x / 2 - 20, -50)
					print("[Tutorial] Arrow pointing to ActionMenu at: %s" % arrow_pos)
				else:
					var party_panel := ui_controller.get_node_or_null("PartyPanel")
					if party_panel and party_panel.visible:
						arrow_pos = party_panel.global_position + Vector2(party_panel.size.x / 2 - 20, -50)
						print("[Tutorial] Arrow pointing to PartyPanel at: %s" % arrow_pos)
					else:
						arrow_pos = Vector2(viewport_size.x / 2 - 20, viewport_size.y - 130)
						print("[Tutorial] Arrow using fallback for action_buttons")
			else:
				arrow_pos = Vector2(viewport_size.x / 2 - 20, viewport_size.y - 130)
		"enemy_sidebar":
			arrow_label.text = "◀"  # Point LEFT toward enemies on right
			# Find EnemyPanel (NOT RightEnemySidebar!)
			if ui_controller:
				var enemy_panel := ui_controller.get_node_or_null("EnemyPanel")
				if enemy_panel and enemy_panel.visible:
					arrow_pos = enemy_panel.global_position + Vector2(-50, enemy_panel.size.y / 2 - 20)
					print("[Tutorial] Arrow pointing to EnemyPanel at: %s" % arrow_pos)
				else:
					arrow_pos = Vector2(viewport_size.x - 200, 400)
					print("[Tutorial] Arrow using fallback for enemy_sidebar")
			else:
				arrow_pos = Vector2(viewport_size.x - 200, 400)
		"purify_button":
			arrow_label.text = "▼"
			if ui_controller:
				var purify_btn := ui_controller.get_node_or_null("PartyPanel/VBoxContainer/ActionMenu/PurifyButton")
				if purify_btn and purify_btn.visible:
					arrow_pos = purify_btn.global_position + Vector2(purify_btn.size.x / 2 - 20, -50)
					print("[Tutorial] Arrow pointing to PurifyButton at: %s" % arrow_pos)
				else:
					arrow_pos = Vector2(viewport_size.x / 2 - 60, viewport_size.y - 130)
					print("[Tutorial] Arrow using fallback for purify_button")
			else:
				arrow_pos = Vector2(viewport_size.x / 2 - 60, viewport_size.y - 130)
		_:
			arrow_label.text = "▼"
			arrow_pos = Vector2(viewport_size.x / 2 - 20, viewport_size.y / 2)
			print("[Tutorial] Arrow using default position")
	
	_tutorial_arrow.position = arrow_pos
	
	# Add to high layer canvas that works while paused
	var canvas := CanvasLayer.new()
	canvas.name = "ArrowCanvas"
	canvas.layer = 101
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	canvas.add_child(_tutorial_arrow)
	
	# Animate the arrow (bobbing motion)
	var tween := create_tween().set_loops()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	var start_pos := _tutorial_arrow.position
	# Bob in direction of arrow
	if arrow_label.text == "▼":
		tween.tween_property(_tutorial_arrow, "position:y", start_pos.y + 15, 0.4).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_tutorial_arrow, "position:y", start_pos.y, 0.4).set_ease(Tween.EASE_IN_OUT)
	else:  # Horizontal arrow
		tween.tween_property(_tutorial_arrow, "position:x", start_pos.x - 15, 0.4).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_tutorial_arrow, "position:x", start_pos.x, 0.4).set_ease(Tween.EASE_IN_OUT)

func _hide_tutorial_arrow() -> void:
	"""Hide and cleanup tutorial arrow"""
	if _tutorial_arrow and is_instance_valid(_tutorial_arrow):
		var canvas := _tutorial_arrow.get_parent()
		_tutorial_arrow.queue_free()
		if canvas and canvas.name == "ArrowCanvas":
			canvas.queue_free()
		_tutorial_arrow = null
