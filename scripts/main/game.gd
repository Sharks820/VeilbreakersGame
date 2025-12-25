class_name Game
extends Node
## Game: Main game controller that orchestrates gameplay systems.

# =============================================================================
# SIGNALS
# =============================================================================

signal game_ready()
signal player_created(player: PlayerCharacter)

# =============================================================================
# EXPORTS
# =============================================================================

@export var starting_scene: String = "res://scenes/main/main_menu.tscn"
@export var debug_mode: bool = false

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var world_container: Node2D = $WorldContainer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var transition_layer: CanvasLayer = $TransitionLayer
@onready var debug_layer: CanvasLayer = $DebugLayer if has_node("DebugLayer") else null

# =============================================================================
# STATE
# =============================================================================

var current_player: PlayerCharacter = null
var current_world_scene: Node = null
var is_game_started: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_initialize_game()
	game_ready.emit()
	EventBus.emit_debug("Game controller initialized")

func _connect_signals() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.load_completed.connect(_on_load_completed)
	EventBus.battle_retry_requested.connect(_on_battle_retry_requested)

func _initialize_game() -> void:
	# Set initial game state
	GameManager.change_state(Enums.GameState.LOADING)

	# Enable debug mode if set
	if debug_mode:
		_enable_debug_features()

func _enable_debug_features() -> void:
	if debug_layer:
		debug_layer.visible = true
	EventBus.emit_debug("Debug mode enabled")

# =============================================================================
# GAME FLOW
# =============================================================================

func start_new_game(player_name: String = "Veilbreaker") -> void:
	GameManager.reset_for_new_game()

	# Create player character
	current_player = PlayerCharacter.create_new_player(player_name)
	GameManager.add_to_party(current_player)

	player_created.emit(current_player)
	EventBus.game_started.emit()

	is_game_started = true
	EventBus.emit_debug("New game started for: %s" % player_name)

func continue_game(save_slot: int) -> void:
	SaveManager.load_game(save_slot)
	is_game_started = true

func end_game() -> void:
	is_game_started = false
	current_player = null
	current_world_scene = null
	GameManager.change_state(Enums.GameState.MAIN_MENU)
	SceneManager.goto_main_menu()

# =============================================================================
# WORLD MANAGEMENT
# =============================================================================

func load_world_scene(scene_path: String) -> void:
	if current_world_scene:
		current_world_scene.queue_free()
		current_world_scene = null

	var scene_resource := load(scene_path)
	if scene_resource:
		current_world_scene = scene_resource.instantiate()
		world_container.add_child(current_world_scene)
		EventBus.emit_debug("World scene loaded: %s" % scene_path)
	else:
		EventBus.emit_error("Failed to load world scene: %s" % scene_path)

func unload_world_scene() -> void:
	if current_world_scene:
		current_world_scene.queue_free()
		current_world_scene = null

# =============================================================================
# BATTLE INTEGRATION
# =============================================================================

func start_battle(enemy_data: Array) -> void:
	GameManager.change_state(Enums.GameState.BATTLE)

	# Store current world state for return
	var return_position := GameManager.player_position
	var return_area := GameManager.current_area

	# Transition to battle scene
	SceneManager.change_scene("res://scenes/battle/battle_arena.tscn")

func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	if victory:
		EventBus.emit_debug("Battle won! Rewards: %s" % str(rewards))
	else:
		EventBus.emit_debug("Battle lost!")

	# Return to overworld or handle game over
	if victory:
		GameManager.change_state(Enums.GameState.OVERWORLD)
		# Return to previous scene
	else:
		GameManager.change_state(Enums.GameState.GAME_OVER)

func _on_battle_retry_requested() -> void:
	# Reload the battle with same enemies
	EventBus.emit_debug("Battle retry requested")
	# Re-initialize battle with same enemy data

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_game_started() -> void:
	# Transition to first gameplay area
	GameManager.change_state(Enums.GameState.OVERWORLD)
	GameManager.current_chapter = 1
	GameManager.set_story_flag("game_started", true)

func _on_load_completed(slot: int, success: bool) -> void:
	if success:
		EventBus.emit_debug("Game loaded from slot %d" % slot)
		GameManager.change_state(Enums.GameState.OVERWORLD)
		is_game_started = true
	else:
		EventBus.emit_error("Failed to load game from slot %d" % slot)

# =============================================================================
# PAUSE MANAGEMENT
# =============================================================================

func pause_game() -> void:
	if GameManager.current_state == Enums.GameState.PAUSED:
		return

	GameManager.change_state(Enums.GameState.PAUSED)
	get_tree().paused = true
	EventBus.game_paused.emit()

func resume_game() -> void:
	if GameManager.current_state != Enums.GameState.PAUSED:
		return

	GameManager.return_to_previous_state()
	get_tree().paused = false
	EventBus.game_resumed.emit()

func toggle_pause() -> void:
	if GameManager.current_state == Enums.GameState.PAUSED:
		resume_game()
	elif GameManager.current_state in [Enums.GameState.OVERWORLD, Enums.GameState.BATTLE]:
		pause_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

# =============================================================================
# VERA INTEGRATION
# =============================================================================

func trigger_vera_dialogue(dialogue_id: String) -> void:
	EventBus.vera_dialogue_triggered.emit(dialogue_id)

func trigger_vera_glitch(intensity: float = 0.5, duration: float = 0.3) -> void:
	EventBus.vera_glitch_triggered.emit(intensity, duration)

func use_vera_ability(ability: String) -> void:
	GameManager.use_vera_power(10.0)
	EventBus.vera_ability_used.emit(ability)

# =============================================================================
# UTILITY
# =============================================================================

func get_player() -> PlayerCharacter:
	return current_player

func is_in_battle() -> bool:
	return GameManager.is_in_battle()

func is_paused() -> bool:
	return GameManager.is_paused()

func get_play_time() -> String:
	return GameManager.get_formatted_play_time()
