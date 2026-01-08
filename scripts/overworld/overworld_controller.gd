extends Node2D
class_name OverworldController
## OverworldController: Manages the overworld scene, zones, and transitions.

# =============================================================================
# NODES
# =============================================================================

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera
@onready var encounter_manager: Node = $EncounterManager
@onready var world: Node2D = $World
@onready var zones: Node2D = $World/Zones
@onready var location_label: Label = $UILayer/LocationLabel

# =============================================================================
# STATE
# =============================================================================

var current_zone: String = "frontier_camp"
var player_step_distance: float = 0.0
var last_player_position: Vector2 = Vector2.ZERO

const STEP_DISTANCE: float = 32.0  # Pixels per "step" for encounter checks

# Zone configurations - Brand-aligned biomes
const ZONE_DATA: Dictionary = {
	"frontier_camp": {
		"name": "Frontier Camp",
		"description": "Your base of operations",
		"encounters_enabled": false,
		"ambient_color": Color(0.2, 0.18, 0.22)
	},
	"blood_marshes": {
		"name": "Blood Marshes",
		"description": "SAVAGE brand territory",
		"encounters_enabled": true,
		"ambient_color": Color(0.25, 0.1, 0.1),
		"encounters": [
			{"weight": 3.0, "monsters": [{"id": "mawling", "level": 5, "count": 2}]},
			{"weight": 2.0, "monsters": [{"id": "ravener", "level": 6, "count": 1}]},
			{"weight": 1.0, "monsters": [{"id": "mawling", "level": 5, "count": 1}, {"id": "ravener", "level": 6, "count": 1}]}
		]
	},
	"rusted_wastes": {
		"name": "Rusted Wastes",
		"description": "IRON brand territory",
		"encounters_enabled": true,
		"ambient_color": Color(0.2, 0.15, 0.1),
		"encounters": [
			{"weight": 3.0, "monsters": [{"id": "chainbound", "level": 5, "count": 2}]},
			{"weight": 2.0, "monsters": [{"id": "the_bulwark", "level": 7, "count": 1}]},
			{"weight": 1.0, "monsters": [{"id": "ironjaw", "level": 6, "count": 1}]}
		]
	},
	"toxic_depths": {
		"name": "Toxic Depths",
		"description": "VENOM brand territory",
		"encounters_enabled": true,
		"ambient_color": Color(0.1, 0.2, 0.1),
		"encounters": [
			{"weight": 3.0, "monsters": [{"id": "sporecaller", "level": 5, "count": 2}]},
			{"weight": 2.0, "monsters": [{"id": "needlefang", "level": 6, "count": 1}]}
		]
	},
	"storm_peaks": {
		"name": "Storm Peaks",
		"description": "SURGE brand territory",
		"encounters_enabled": true,
		"ambient_color": Color(0.15, 0.15, 0.25),
		"encounters": [
			{"weight": 3.0, "monsters": [{"id": "crackling", "level": 5, "count": 2}]},
			{"weight": 2.0, "monsters": [{"id": "flicker", "level": 6, "count": 1}]},
			{"weight": 1.0, "monsters": [{"id": "voltgeist", "level": 7, "count": 1}]}
		]
	},
	"shadow_hollows": {
		"name": "Shadow Hollows",
		"description": "DREAD brand territory",
		"encounters_enabled": true,
		"ambient_color": Color(0.1, 0.08, 0.15),
		"encounters": [
			{"weight": 3.0, "monsters": [{"id": "hollow", "level": 5, "count": 2}]},
			{"weight": 2.0, "monsters": [{"id": "the_weeping", "level": 6, "count": 1}]}
		]
	},
	"withered_gardens": {
		"name": "Withered Gardens",
		"description": "LEECH brand territory",
		"encounters_enabled": true,
		"ambient_color": Color(0.15, 0.1, 0.15),
		"encounters": [
			{"weight": 3.0, "monsters": [{"id": "gluttony_polyp", "level": 5, "count": 2}]},
			{"weight": 2.0, "monsters": [{"id": "bloodshade", "level": 6, "count": 1}]}
		]
	}
}

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	GameManager.change_state(Enums.GameState.OVERWORLD)

	# Set up camera to follow player
	if camera and camera.has_method("set_follow_target"):
		camera.set_follow_target(player)

	# Initialize starting zone
	_enter_zone(current_zone)

	# Store initial position for step tracking
	if player:
		last_player_position = player.global_position

	_connect_signals()
	EventBus.emit_debug("Overworld initialized")


func _connect_signals() -> void:
	if encounter_manager:
		if encounter_manager.has_signal("encounter_triggered"):
			encounter_manager.encounter_triggered.connect(_on_encounter_triggered)

	EventBus.battle_ended.connect(_on_battle_ended)


func _process(_delta: float) -> void:
	if not player:
		return

	# Track player movement for encounter steps
	var distance := player.global_position.distance_to(last_player_position)
	if distance >= STEP_DISTANCE:
		player_step_distance += distance
		last_player_position = player.global_position

		# Register step with encounter manager
		if encounter_manager and encounter_manager.has_method("register_step"):
			encounter_manager.register_step()


# =============================================================================
# ZONE MANAGEMENT
# =============================================================================


func _enter_zone(zone_id: String) -> void:
	if zone_id not in ZONE_DATA:
		push_warning("Unknown zone: %s" % zone_id)
		return

	current_zone = zone_id
	var zone_info: Dictionary = ZONE_DATA[zone_id]

	# Update location label
	if location_label:
		location_label.text = zone_info.get("name", zone_id.capitalize())

	# Update encounter table
	if encounter_manager:
		if zone_info.get("encounters_enabled", false):
			var encounters: Array = zone_info.get("encounters", [])
			var typed_encounters: Array[Dictionary] = []
			for enc in encounters:
				typed_encounters.append(enc)
			encounter_manager.set_area_encounters(typed_encounters)
			encounter_manager.enable_encounters()
		else:
			encounter_manager.disable_encounters()
			encounter_manager.clear_encounters()

	EventBus.emit_debug("Entered zone: %s" % zone_info.get("name", zone_id))


func change_zone(zone_id: String) -> void:
	## Public method to change zones (called by zone triggers)
	_enter_zone(zone_id)


# =============================================================================
# ENCOUNTER HANDLING
# =============================================================================


func _on_encounter_triggered(_enemies: Array) -> void:
	# Camera shake before transition
	if camera and camera.has_method("shake"):
		camera.shake(0.5)

	# Short delay for dramatic effect
	await get_tree().create_timer(0.3).timeout

	# Transition to battle (handled by SceneManager via EventBus.battle_started)


func _on_battle_ended(victory: bool, _rewards: Dictionary) -> void:
	if victory:
		EventBus.emit_debug("Battle won - returning to overworld")
	else:
		# Handle defeat - could return to hub or show game over
		EventBus.emit_debug("Battle lost")


# =============================================================================
# PLAYER MANAGEMENT
# =============================================================================


func teleport_player(position: Vector2) -> void:
	if player:
		player.global_position = position
		last_player_position = position

		# Snap camera immediately
		if camera:
			camera.global_position = position


func get_player_position() -> Vector2:
	return player.global_position if player else Vector2.ZERO


# =============================================================================
# SAVE/LOAD
# =============================================================================


func get_save_data() -> Dictionary:
	return {
		"zone": current_zone,
		"player_data": player.get_save_data() if player and player.has_method("get_save_data") else {}
	}


func load_save_data(data: Dictionary) -> void:
	var zone_id: String = data.get("zone", "frontier_camp")
	_enter_zone(zone_id)

	if player and player.has_method("load_save_data"):
		player.load_save_data(data.get("player_data", {}))
