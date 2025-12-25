extends Node2D
## BattleArena: Visual representation of battle with character placement and effects.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var player_positions: Node2D = $BattleField/PlayerPositions
@onready var enemy_positions: Node2D = $BattleField/EnemyPositions
@onready var players_container: Node2D = $BattleField/CharacterContainer/Players
@onready var enemies_container: Node2D = $BattleField/CharacterContainer/Enemies
@onready var vfx_container: Node2D = $EffectsLayer/VFXContainer
@onready var damage_numbers: Node2D = $EffectsLayer/DamageNumbers
@onready var battle_manager: BattleManager = $Systems/BattleManager
@onready var turn_manager: TurnManager = $Systems/TurnManager
@onready var damage_calculator: DamageCalculator = $Systems/DamageCalculator
@onready var ui_layer: CanvasLayer = $UILayer
@onready var camera: Camera2D = $Camera2D

# =============================================================================
# STATE
# =============================================================================

var player_sprites: Array[Node2D] = []
var enemy_sprites: Array[Node2D] = []
var battle_ui: Control = null
var is_battle_active: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_setup_battle_ui()
	_setup_battle_manager()
	EventBus.emit_debug("BattleArena ready")

func _connect_signals() -> void:
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.healing_done.connect(_on_healing_done)

func _setup_battle_ui() -> void:
	# Load and instantiate battle UI
	var ui_scene := load("res://scenes/battle/battle_ui.tscn")
	if ui_scene:
		battle_ui = ui_scene.instantiate()
		ui_layer.add_child(battle_ui)
		battle_ui.set_battle_manager(battle_manager)

func _setup_battle_manager() -> void:
	# Connect battle manager signals
	battle_manager.battle_initialized.connect(_on_battle_initialized)
	battle_manager.action_animation_started.connect(_on_action_animation_started)
	battle_manager.battle_victory.connect(_on_battle_victory)
	battle_manager.battle_defeat.connect(_on_battle_defeat)

	# Link subsystems
	battle_manager.turn_manager = turn_manager
	battle_manager.damage_calculator = damage_calculator

# =============================================================================
# BATTLE INITIALIZATION
# =============================================================================

func initialize_battle(players: Array[CharacterBase], enemies: Array[CharacterBase]) -> void:
	is_battle_active = true

	# Place characters on the battlefield
	_place_characters(players, player_positions, players_container, player_sprites)
	_place_characters(enemies, enemy_positions, enemies_container, enemy_sprites)

	# Start battle logic
	battle_manager.start_battle(players, enemies)

	EventBus.emit_debug("Battle initialized with %d players vs %d enemies" % [players.size(), enemies.size()])

func _place_characters(characters: Array[CharacterBase], positions_node: Node2D, container: Node2D, sprite_array: Array[Node2D]) -> void:
	sprite_array.clear()
	var markers := positions_node.get_children()

	for i in range(mini(characters.size(), markers.size())):
		var character := characters[i]
		var marker: Marker2D = markers[i]

		# Create visual representation
		var sprite := _create_character_sprite(character)
		sprite.global_position = marker.global_position
		container.add_child(sprite)
		sprite_array.append(sprite)

		# Store reference for animations
		character.set_meta("battle_sprite", sprite)
		character.battle_position = marker.global_position

func _create_character_sprite(character: CharacterBase) -> Node2D:
	var container := Node2D.new()
	container.name = character.character_name

	# Placeholder colored rectangle (will be replaced with Spine/sprites)
	var sprite := ColorRect.new()
	sprite.size = Vector2(80, 120)
	sprite.position = Vector2(-40, -120)

	# Color based on character type
	match character.character_type:
		Enums.CharacterType.PLAYER:
			sprite.color = Color(0.2, 0.6, 1.0, 0.9)
		Enums.CharacterType.MONSTER:
			sprite.color = Color(0.8, 0.2, 0.2, 0.9)
		Enums.CharacterType.BOSS:
			sprite.color = Color(0.6, 0.1, 0.6, 0.9)
			sprite.size = Vector2(100, 150)  # Bosses are larger
			sprite.position = Vector2(-50, -150)
		_:
			sprite.color = Color(0.5, 0.5, 0.5, 0.9)

	container.add_child(sprite)

	# Name label
	var label := Label.new()
	label.text = character.character_name
	label.position = Vector2(-40, -140)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	container.add_child(label)

	# HP bar above character
	var hp_bar := ProgressBar.new()
	hp_bar.size = Vector2(70, 8)
	hp_bar.position = Vector2(-35, -150)
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.name = "HPBar"
	container.add_child(hp_bar)

	return container

# =============================================================================
# ANIMATIONS
# =============================================================================

func _on_action_animation_started(character: CharacterBase, action: int) -> void:
	var sprite: Node2D = character.get_meta("battle_sprite", null)
	if not sprite:
		return

	var original_pos := sprite.position
	var tween := create_tween()

	match action:
		Enums.BattleAction.ATTACK:
			var direction := 1.0 if character in battle_manager.player_party else -1.0
			tween.tween_property(sprite, "position:x", original_pos.x + (80 * direction), 0.15)
			tween.tween_property(sprite, "position:x", original_pos.x, 0.15)

		Enums.BattleAction.SKILL:
			# Glow effect for skills
			tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.5), 0.2)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

		Enums.BattleAction.DEFEND:
			tween.tween_property(sprite, "modulate", Color(0.5, 0.7, 1.0), 0.1)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)

		Enums.BattleAction.PURIFY:
			# Holy light effect
			tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.8), 0.3)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func _play_hit_animation(sprite: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	# Shake effect
	var original_pos := sprite.position
	tween.parallel().tween_property(sprite, "position:x", original_pos.x + 5, 0.02)
	tween.tween_property(sprite, "position:x", original_pos.x - 5, 0.04)
	tween.tween_property(sprite, "position:x", original_pos.x, 0.04)

func _play_heal_animation(sprite: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _play_death_animation(sprite: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y + 20, 0.5)

# =============================================================================
# DAMAGE NUMBERS
# =============================================================================

func _spawn_damage_number(pos: Vector2, amount: int, is_critical: bool, is_heal: bool = false) -> void:
	var label := Label.new()
	label.text = str(amount) if not is_heal else "+" + str(amount)
	label.global_position = pos + Vector2(randf_range(-20, 20), 0)
	label.z_index = 100

	# Styling
	var font_size := 32 if is_critical else 24
	label.add_theme_font_size_override("font_size", font_size)

	var color := Color.WHITE
	if is_heal:
		color = Color.LIME_GREEN
	elif is_critical:
		color = Color.YELLOW
	else:
		color = Color.WHITE
	label.add_theme_color_override("font_color", color)

	damage_numbers.add_child(label)

	# Animate
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", pos.y - 60, Constants.DAMAGE_NUMBER_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, Constants.DAMAGE_NUMBER_DURATION)
	tween.chain().tween_callback(label.queue_free)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_battle_started(enemy_data: Array) -> void:
	# Create enemy characters from data if provided
	if enemy_data.is_empty():
		return

	var enemies: Array[CharacterBase] = []
	for data in enemy_data:
		if data is Monster:
			enemies.append(data)
		elif data is Dictionary:
			enemies.append(Monster.create_from_data(data))

	# Get current party
	var players: Array[CharacterBase] = []
	for member in GameManager.player_party:
		if member is CharacterBase:
			players.append(member)

	if not players.is_empty() and not enemies.is_empty():
		initialize_battle(players, enemies)

func _on_battle_initialized() -> void:
	EventBus.emit_debug("Battle arena: Battle initialized")

func _on_damage_dealt(_source: Node, target: Node, amount: int, is_critical: bool) -> void:
	if not target is CharacterBase:
		return

	var character: CharacterBase = target
	var sprite: Node2D = character.get_meta("battle_sprite", null)
	if not sprite:
		return

	# Update HP bar
	var hp_bar: ProgressBar = sprite.get_node_or_null("HPBar")
	if hp_bar:
		hp_bar.value = character.current_hp

	# Spawn damage number
	_spawn_damage_number(sprite.global_position + Vector2(0, -80), amount, is_critical)

	# Play hit animation
	_play_hit_animation(sprite)

	# Check for death
	if character.is_dead():
		_play_death_animation(sprite)

func _on_healing_done(_source: Node, target: Node, amount: int) -> void:
	if not target is CharacterBase:
		return

	var character: CharacterBase = target
	var sprite: Node2D = character.get_meta("battle_sprite", null)
	if not sprite:
		return

	# Update HP bar
	var hp_bar: ProgressBar = sprite.get_node_or_null("HPBar")
	if hp_bar:
		hp_bar.value = character.current_hp

	# Spawn heal number
	_spawn_damage_number(sprite.global_position + Vector2(0, -80), amount, false, true)

	# Play heal animation
	_play_heal_animation(sprite)

func _on_battle_victory(rewards: Dictionary) -> void:
	is_battle_active = false
	EventBus.emit_debug("Victory! Rewards: %s" % str(rewards))

	# Play victory animations
	for sprite in player_sprites:
		var tween := create_tween()
		tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.2)
		tween.tween_property(sprite, "position:y", sprite.position.y, 0.2)

func _on_battle_defeat() -> void:
	is_battle_active = false
	EventBus.emit_debug("Defeat!")

# =============================================================================
# CAMERA EFFECTS
# =============================================================================

func shake_camera(intensity: float = 5.0, duration: float = 0.2) -> void:
	var original_offset := camera.offset
	var tween := create_tween()

	for i in range(int(duration / 0.05)):
		var shake_offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", original_offset + shake_offset, 0.05)

	tween.tween_property(camera, "offset", original_offset, 0.05)

# =============================================================================
# CLEANUP
# =============================================================================

func cleanup_battle() -> void:
	# Clear character sprites
	for sprite in player_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	player_sprites.clear()

	for sprite in enemy_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	enemy_sprites.clear()

	# Clear damage numbers
	for child in damage_numbers.get_children():
		child.queue_free()

	is_battle_active = false

# =============================================================================
# UTILITY
# =============================================================================

func get_battle_manager() -> BattleManager:
	return battle_manager

func get_turn_manager() -> TurnManager:
	return turn_manager
