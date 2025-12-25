extends Node
## QuestSystem: Manages quests, objectives, and story progression.

# =============================================================================
# SIGNALS
# =============================================================================

signal quest_added(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

# =============================================================================
# QUEST DATA STRUCTURE
# =============================================================================

class Quest:
	var quest_id: String
	var title: String
	var description: String
	var quest_type: QuestType
	var status: QuestStatus
	var objectives: Array[Objective]
	var current_objective: int
	var rewards: Dictionary
	var prerequisites: Array[String]
	var is_main_quest: bool
	var chapter: int

	func _init(data: Dictionary = {}) -> void:
		quest_id = data.get("quest_id", "")
		title = data.get("title", "Unknown Quest")
		description = data.get("description", "")
		quest_type = data.get("quest_type", QuestType.MAIN)
		status = data.get("status", QuestStatus.LOCKED)
		current_objective = data.get("current_objective", 0)
		rewards = data.get("rewards", {})
		prerequisites = data.get("prerequisites", [])
		is_main_quest = data.get("is_main_quest", false)
		chapter = data.get("chapter", 1)

		objectives = []
		for obj_data in data.get("objectives", []):
			objectives.append(Objective.new(obj_data))

class Objective:
	var description: String
	var objective_type: ObjectiveType
	var target_id: String
	var target_count: int
	var current_count: int
	var is_complete: bool
	var is_optional: bool

	func _init(data: Dictionary = {}) -> void:
		description = data.get("description", "")
		objective_type = data.get("objective_type", ObjectiveType.KILL)
		target_id = data.get("target_id", "")
		target_count = data.get("target_count", 1)
		current_count = data.get("current_count", 0)
		is_complete = data.get("is_complete", false)
		is_optional = data.get("is_optional", false)

	func add_progress(amount: int = 1) -> bool:
		if is_complete:
			return false
		current_count = mini(current_count + amount, target_count)
		if current_count >= target_count:
			is_complete = true
			return true
		return false

enum QuestType {
	MAIN,
	SIDE,
	HUNT,
	COLLECTION,
	EXPLORATION
}

enum QuestStatus {
	LOCKED,
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED
}

enum ObjectiveType {
	KILL,
	PURIFY,
	COLLECT,
	TALK,
	EXPLORE,
	REACH,
	PROTECT,
	SURVIVE
}

# =============================================================================
# STATE
# =============================================================================

var quests: Dictionary = {}  # {quest_id: Quest}
var active_quests: Array[String] = []
var completed_quests: Array[String] = []
var failed_quests: Array[String] = []

var quest_database: Dictionary = {}  # Loaded quest definitions

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_load_quest_database()
	_connect_signals()
	EventBus.emit_debug("QuestSystem initialized")

func _load_quest_database() -> void:
	# Load quest definitions from JSON or resources
	# For now, create some test quests
	_create_test_quests()

func _connect_signals() -> void:
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.purification_succeeded.connect(_on_purification_succeeded)
	EventBus.item_obtained.connect(_on_item_obtained)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.story_flag_set.connect(_on_story_flag_set)

func _create_test_quests() -> void:
	# Main Quest: Chapter 1
	quest_database["mq_01_awakening"] = {
		"quest_id": "mq_01_awakening",
		"title": "Awakening",
		"description": "Learn about the Veil and your new powers. VERA will guide you.",
		"quest_type": QuestType.MAIN,
		"is_main_quest": true,
		"chapter": 1,
		"objectives": [
			{"description": "Speak with VERA", "objective_type": ObjectiveType.TALK, "target_id": "vera_intro"},
			{"description": "Complete the tutorial battle", "objective_type": ObjectiveType.KILL, "target_id": "tutorial_enemy", "target_count": 1},
			{"description": "Purify your first monster", "objective_type": ObjectiveType.PURIFY, "target_id": "any", "target_count": 1}
		],
		"rewards": {"experience": 100, "currency": 50, "items": ["potion"]}
	}

	# Side Quest: Hunt
	quest_database["sq_01_shadow_hunt"] = {
		"quest_id": "sq_01_shadow_hunt",
		"title": "Shadow Hunt",
		"description": "Defeat Shadow Imps lurking near the village.",
		"quest_type": QuestType.HUNT,
		"is_main_quest": false,
		"chapter": 1,
		"objectives": [
			{"description": "Defeat Shadow Imps", "objective_type": ObjectiveType.KILL, "target_id": "shadow_imp", "target_count": 5}
		],
		"rewards": {"experience": 50, "currency": 100}
	}

# =============================================================================
# QUEST MANAGEMENT
# =============================================================================

func start_quest(quest_id: String) -> bool:
	if not quest_database.has(quest_id):
		push_warning("Unknown quest: %s" % quest_id)
		return false

	if quest_id in active_quests or quest_id in completed_quests:
		return false

	var quest_data: Dictionary = quest_database[quest_id]

	# Check prerequisites
	for prereq in quest_data.get("prerequisites", []):
		if prereq not in completed_quests:
			return false

	var quest := Quest.new(quest_data)
	quest.status = QuestStatus.ACTIVE
	quests[quest_id] = quest
	active_quests.append(quest_id)

	quest_added.emit(quest_id)
	EventBus.quest_started.emit(quest_id)
	EventBus.emit_notification("New Quest: %s" % quest.title, "quest")

	return true

func update_objective(quest_id: String, objective_type: ObjectiveType, target_id: String, amount: int = 1) -> void:
	if quest_id not in active_quests:
		return

	var quest: Quest = quests[quest_id]

	for i in range(quest.objectives.size()):
		var obj := quest.objectives[i]
		if obj.objective_type == objective_type:
			if obj.target_id == target_id or obj.target_id == "any":
				if obj.add_progress(amount):
					quest_updated.emit(quest_id, i)
					EventBus.quest_objective_updated.emit(quest_id, i)
					_check_quest_completion(quest_id)
				return

func _check_quest_completion(quest_id: String) -> void:
	var quest: Quest = quests[quest_id]

	var all_complete := true
	for obj in quest.objectives:
		if not obj.is_optional and not obj.is_complete:
			all_complete = false
			break

	if all_complete:
		complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if quest_id not in active_quests:
		return

	var quest: Quest = quests[quest_id]
	quest.status = QuestStatus.COMPLETED

	active_quests.erase(quest_id)
	completed_quests.append(quest_id)

	# Grant rewards
	_grant_rewards(quest.rewards)

	quest_completed.emit(quest_id)
	EventBus.quest_completed.emit(quest_id)
	EventBus.emit_notification("Quest Complete: %s" % quest.title, "success")

func fail_quest(quest_id: String) -> void:
	if quest_id not in active_quests:
		return

	var quest: Quest = quests[quest_id]
	quest.status = QuestStatus.FAILED

	active_quests.erase(quest_id)
	failed_quests.append(quest_id)

	quest_failed.emit(quest_id)
	EventBus.emit_notification("Quest Failed: %s" % quest.title, "error")

func _grant_rewards(rewards: Dictionary) -> void:
	if rewards.has("experience"):
		EventBus.experience_gained.emit(null, rewards.experience)

	if rewards.has("currency"):
		GameManager.add_currency(rewards.currency)

	if rewards.has("items"):
		for item_id in rewards.items:
			EventBus.item_obtained.emit(item_id, 1)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_battle_ended(victory: bool, _rewards: Dictionary) -> void:
	if not victory:
		return

	# Update kill objectives for all active quests
	for quest_id in active_quests:
		update_objective(quest_id, ObjectiveType.KILL, "any", 1)

func _on_purification_succeeded(monster: Node) -> void:
	var monster_id := ""
	if monster is Monster:
		monster_id = monster.monster_id

	for quest_id in active_quests:
		update_objective(quest_id, ObjectiveType.PURIFY, monster_id, 1)
		update_objective(quest_id, ObjectiveType.PURIFY, "any", 1)

func _on_item_obtained(item_id: String, quantity: int) -> void:
	for quest_id in active_quests:
		update_objective(quest_id, ObjectiveType.COLLECT, item_id, quantity)

func _on_dialogue_ended() -> void:
	# Check for talk objectives
	pass

func _on_story_flag_set(flag: String, _value: Variant) -> void:
	# Check if this flag triggers any quest updates
	pass

# =============================================================================
# QUERIES
# =============================================================================

func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id, null)

func get_active_quests() -> Array[Quest]:
	var result: Array[Quest] = []
	for quest_id in active_quests:
		if quests.has(quest_id):
			result.append(quests[quest_id])
	return result

func get_main_quest() -> Quest:
	for quest_id in active_quests:
		var quest: Quest = quests.get(quest_id)
		if quest and quest.is_main_quest:
			return quest
	return null

func is_quest_active(quest_id: String) -> bool:
	return quest_id in active_quests

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	var quest_states := {}
	for quest_id in quests:
		var quest: Quest = quests[quest_id]
		var objectives_data := []
		for obj in quest.objectives:
			objectives_data.append({
				"current_count": obj.current_count,
				"is_complete": obj.is_complete
			})

		quest_states[quest_id] = {
			"status": quest.status,
			"current_objective": quest.current_objective,
			"objectives": objectives_data
		}

	return {
		"quest_states": quest_states,
		"active_quests": active_quests.duplicate(),
		"completed_quests": completed_quests.duplicate(),
		"failed_quests": failed_quests.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	active_quests.assign(data.get("active_quests", []))
	completed_quests.assign(data.get("completed_quests", []))
	failed_quests.assign(data.get("failed_quests", []))

	var quest_states: Dictionary = data.get("quest_states", {})

	for quest_id in quest_states:
		if quest_database.has(quest_id):
			var quest := Quest.new(quest_database[quest_id])
			var state: Dictionary = quest_states[quest_id]

			quest.status = state.get("status", QuestStatus.ACTIVE)
			quest.current_objective = state.get("current_objective", 0)

			var obj_states: Array = state.get("objectives", [])
			for i in range(mini(obj_states.size(), quest.objectives.size())):
				quest.objectives[i].current_count = obj_states[i].get("current_count", 0)
				quest.objectives[i].is_complete = obj_states[i].get("is_complete", false)

			quests[quest_id] = quest
