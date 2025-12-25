extends CharacterBody2D
## PlayerController: Handles player movement and interaction in the overworld.

# =============================================================================
# EXPORTS
# =============================================================================

@export var move_speed: float = 200.0
@export var run_multiplier: float = 1.5

# =============================================================================
# NODES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# =============================================================================
# STATE
# =============================================================================

var is_moving: bool = false
var is_running: bool = false
var facing_direction: Vector2 = Vector2.DOWN
var can_move: bool = true

var nearby_interactables: Array = []

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interactable_entered)
		interaction_area.body_exited.connect(_on_interactable_exited)

	_connect_signals()

func _connect_signals() -> void:
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	_handle_movement(delta)
	_update_animation()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if not can_move:
		return

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("toggle_menu"):
		_open_pause_menu()

# =============================================================================
# MOVEMENT
# =============================================================================

func _handle_movement(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	is_running = Input.is_action_pressed("ui_shift")  # Or custom run action
	is_moving = input_direction.length() > 0.1

	if is_moving:
		facing_direction = input_direction.normalized()
		var speed := move_speed * (run_multiplier if is_running else 1.0)
		velocity = input_direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 0.5)

func _update_animation() -> void:
	if not animation_player:
		return

	var anim_name := "idle"

	if is_moving:
		anim_name = "run" if is_running else "walk"

	# Add direction suffix
	if facing_direction.y > 0.5:
		anim_name += "_down"
	elif facing_direction.y < -0.5:
		anim_name += "_up"
	elif facing_direction.x > 0.5:
		anim_name += "_right"
	elif facing_direction.x < -0.5:
		anim_name += "_left"

	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func stop_movement() -> void:
	can_move = false
	velocity = Vector2.ZERO
	is_moving = false

func resume_movement() -> void:
	can_move = true

# =============================================================================
# INTERACTION
# =============================================================================

func _try_interact() -> void:
	if nearby_interactables.is_empty():
		return

	# Get closest interactable
	var closest: Node = null
	var closest_dist := INF

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue
		var dist := global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = interactable

	if closest and closest.has_method("interact"):
		closest.interact(self)

func _on_interactable_entered(body: Node2D) -> void:
	if body.has_method("interact"):
		nearby_interactables.append(body)

func _on_interactable_exited(body: Node2D) -> void:
	nearby_interactables.erase(body)

# =============================================================================
# MENU
# =============================================================================

func _open_pause_menu() -> void:
	if GameManager.is_state(Enums.GameState.OVERWORLD):
		GameManager.change_state(Enums.GameState.PAUSED)
		EventBus.menu_opened.emit(Enums.MenuType.PAUSE)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_game_state_changed(_old: int, new: int) -> void:
	match new:
		Enums.GameState.OVERWORLD:
			resume_movement()
		Enums.GameState.BATTLE, Enums.GameState.DIALOGUE, Enums.GameState.PAUSED, Enums.GameState.CUTSCENE:
			stop_movement()

func _on_dialogue_started(_dialogue_id: String) -> void:
	stop_movement()

func _on_dialogue_ended() -> void:
	if GameManager.is_state(Enums.GameState.OVERWORLD):
		resume_movement()

func _on_battle_started(_enemies: Array) -> void:
	stop_movement()
	visible = false

func _on_battle_ended(_victory: bool, _rewards: Dictionary) -> void:
	visible = true
	if GameManager.is_state(Enums.GameState.OVERWORLD):
		resume_movement()

# =============================================================================
# SAVE/LOAD
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"facing": {"x": facing_direction.x, "y": facing_direction.y}
	}

func load_save_data(data: Dictionary) -> void:
	var pos: Dictionary = data.get("position", {"x": 0, "y": 0})
	global_position = Vector2(pos.x, pos.y)

	var facing: Dictionary = data.get("facing", {"x": 0, "y": 1})
	facing_direction = Vector2(facing.x, facing.y)
