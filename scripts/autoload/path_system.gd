extends Node
## PathSystem: Manages player path affinities and skill tree access.
##
## The 4 Paths:
## - IRONBOUND: Protection, order, sacrifice, duty (Tank/Defense)
## - FANGBORN: Strength, dominance, survival, apex (Attack/DPS)
## - VOIDTOUCHED: Knowledge, truth, patience, secrets (Utility/Special)
## - UNCHAINED: Freedom, chaos, adaptability (Hybrid/Disruptor)

# =============================================================================
# SIGNALS
# =============================================================================

signal path_affinity_changed(path: Enums.Path, old_value: float, new_value: float)
signal path_unlocked(path: Enums.Path)
signal path_locked(path: Enums.Path)
signal skill_tree_state_changed(path: Enums.Path, old_state: Enums.SkillTreeState, new_state: Enums.SkillTreeState)

# =============================================================================
# CONSTANTS
# =============================================================================

const UNLOCK_THRESHOLD: float = 30.0
const MAX_AFFINITY: float = 100.0
const MIN_AFFINITY: float = 0.0

# Path colors for UI
const PATH_COLORS: Dictionary = {
	Enums.Path.IRONBOUND: Color(0.48, 0.53, 0.58),    # Steel gray
	Enums.Path.FANGBORN: Color(0.55, 0.16, 0.26),     # Blood red
	Enums.Path.VOIDTOUCHED: Color(0.36, 0.24, 0.55),  # Deep purple
	Enums.Path.UNCHAINED: Color(0.18, 0.55, 0.45)     # Teal green
}

# Which brands align with which paths (for monster catching)
const PATH_BRAND_ALIGNMENT: Dictionary = {
	Enums.Path.IRONBOUND: [Enums.Brand.IRON, Enums.Brand.DREAD],
	Enums.Path.FANGBORN: [Enums.Brand.SAVAGE, Enums.Brand.SURGE],
	Enums.Path.VOIDTOUCHED: [Enums.Brand.DREAD, Enums.Brand.LEECH],
	Enums.Path.UNCHAINED: [Enums.Brand.VENOM, Enums.Brand.SURGE]
}

# =============================================================================
# STATE
# =============================================================================

## Current affinity for each path (0-100)
var path_affinities: Dictionary = {
	Enums.Path.IRONBOUND: 0.0,
	Enums.Path.FANGBORN: 0.0,
	Enums.Path.VOIDTOUCHED: 0.0,
	Enums.Path.UNCHAINED: 0.0
}

## Skill tree states - tracks if paths were previously unlocked
var skill_tree_states: Dictionary = {
	Enums.Path.IRONBOUND: Enums.SkillTreeState.LOCKED,
	Enums.Path.FANGBORN: Enums.SkillTreeState.LOCKED,
	Enums.Path.VOIDTOUCHED: Enums.SkillTreeState.LOCKED,
	Enums.Path.UNCHAINED: Enums.SkillTreeState.LOCKED
}

## Allocated skill points per path
var skill_points_allocated: Dictionary = {
	Enums.Path.IRONBOUND: 0,
	Enums.Path.FANGBORN: 0,
	Enums.Path.VOIDTOUCHED: 0,
	Enums.Path.UNCHAINED: 0
}

## Available skill points to allocate
var available_skill_points: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.level_up.connect(_on_player_leveled_up)

# =============================================================================
# AFFINITY MANAGEMENT
# =============================================================================

func modify_affinity(path: Enums.Path, amount: float, source: String = "") -> void:
	## Modify a path's affinity. Positive = increase, negative = decrease.
	if not path_affinities.has(path):
		return

	var old_value: float = path_affinities[path]
	var new_value: float = clampf(old_value + amount, MIN_AFFINITY, MAX_AFFINITY)

	if old_value == new_value:
		return

	path_affinities[path] = new_value
	path_affinity_changed.emit(path, old_value, new_value)

	# Check for threshold crossings
	_check_unlock_threshold(path, old_value, new_value)

	# Log the change
	if OS.is_debug_build() and source != "":
		ErrorLogger.log_debug("[PATH] %s: %.1f -> %.1f (%s)" % [
			Enums.Path.keys()[path], old_value, new_value, source
		])

func get_affinity(path: Enums.Path) -> float:
	return path_affinities.get(path, 0.0)

func set_affinity(path: Enums.Path, value: float) -> void:
	## Set a path's affinity directly (use modify_affinity for normal changes)
	var old_value: float = path_affinities.get(path, 0.0)
	modify_affinity(path, value - old_value, "set_affinity")

# =============================================================================
# UNLOCK STATUS
# =============================================================================

func is_path_unlocked(path: Enums.Path) -> bool:
	## Returns true if path affinity >= 30%
	return path_affinities.get(path, 0.0) >= UNLOCK_THRESHOLD

func get_unlocked_paths() -> Array[Enums.Path]:
	## Returns array of all paths at 30%+ affinity
	var unlocked: Array[Enums.Path] = []
	for path in path_affinities:
		if path_affinities[path] >= UNLOCK_THRESHOLD:
			unlocked.append(path)
	return unlocked

func get_skill_tree_state(path: Enums.Path) -> Enums.SkillTreeState:
	return skill_tree_states.get(path, Enums.SkillTreeState.LOCKED)

func _check_unlock_threshold(path: Enums.Path, old_value: float, new_value: float) -> void:
	var old_unlocked := old_value >= UNLOCK_THRESHOLD
	var new_unlocked := new_value >= UNLOCK_THRESHOLD

	if not old_unlocked and new_unlocked:
		# Just unlocked
		var old_state: Enums.SkillTreeState = skill_tree_states[path]
		skill_tree_states[path] = Enums.SkillTreeState.UNLOCKED
		path_unlocked.emit(path)
		skill_tree_state_changed.emit(path, old_state, Enums.SkillTreeState.UNLOCKED)
		EventBus.emit_debug("Path %s UNLOCKED at %.1f%%" % [Enums.Path.keys()[path], new_value])

	elif old_unlocked and not new_unlocked:
		# Just dropped below threshold
		var old_state: Enums.SkillTreeState = skill_tree_states[path]
		# Only go DARK if it was previously UNLOCKED (had points allocated)
		if old_state == Enums.SkillTreeState.UNLOCKED:
			skill_tree_states[path] = Enums.SkillTreeState.DARK
			path_locked.emit(path)
			skill_tree_state_changed.emit(path, old_state, Enums.SkillTreeState.DARK)
			EventBus.emit_debug("Path %s went DARK at %.1f%%" % [Enums.Path.keys()[path], new_value])

# =============================================================================
# SKILL POINTS
# =============================================================================

func add_skill_points(amount: int) -> void:
	available_skill_points += amount
	EventBus.emit_debug("Gained %d skill points (total: %d)" % [amount, available_skill_points])

func allocate_skill_point(path: Enums.Path) -> bool:
	## Allocate a skill point to a path. Returns false if not allowed.
	if available_skill_points <= 0:
		return false

	if skill_tree_states.get(path, Enums.SkillTreeState.LOCKED) != Enums.SkillTreeState.UNLOCKED:
		return false

	available_skill_points -= 1
	skill_points_allocated[path] += 1

	EventBus.emit_debug("Allocated point to %s (now %d)" % [
		Enums.Path.keys()[path], skill_points_allocated[path]
	])

	return true

func reset_skill_points(path: Enums.Path) -> int:
	## Reset all points from a path (via Skill Reset Token). Returns points refunded.
	var points: int = skill_points_allocated.get(path, 0)
	if points == 0:
		return 0

	skill_points_allocated[path] = 0
	available_skill_points += points

	EventBus.emit_debug("Reset %d points from %s" % [points, Enums.Path.keys()[path]])

	return points

func get_allocated_points(path: Enums.Path) -> int:
	return skill_points_allocated.get(path, 0)

func get_total_allocated_points() -> int:
	var total := 0
	for path in skill_points_allocated:
		total += skill_points_allocated[path]
	return total

# =============================================================================
# MONSTER CATCHING
# =============================================================================

func can_catch_monster_brand(brand: Enums.Brand) -> bool:
	## Check if player can catch a monster with this brand based on path affinity
	for path in PATH_BRAND_ALIGNMENT:
		if brand in PATH_BRAND_ALIGNMENT[path]:
			if is_path_unlocked(path):
				return true
	return false

func get_paths_for_brand(brand: Enums.Brand) -> Array[Enums.Path]:
	## Get which paths allow catching this brand
	var paths: Array[Enums.Path] = []
	for path in PATH_BRAND_ALIGNMENT:
		if brand in PATH_BRAND_ALIGNMENT[path]:
			paths.append(path)
	return paths

func get_brands_for_path(path: Enums.Path) -> Array[Enums.Brand]:
	## Get which brands this path allows catching
	var brands: Array[Enums.Brand] = []
	if PATH_BRAND_ALIGNMENT.has(path):
		for brand in PATH_BRAND_ALIGNMENT[path]:
			brands.append(brand)
	return brands

# =============================================================================
# QUERIES
# =============================================================================

func get_dominant_path() -> Enums.Path:
	## Returns the path with highest affinity
	var highest_path := Enums.Path.NONE
	var highest_value := -1.0

	for path in path_affinities:
		if path_affinities[path] > highest_value:
			highest_value = path_affinities[path]
			highest_path = path

	return highest_path

func get_path_color(path: Enums.Path) -> Color:
	return PATH_COLORS.get(path, Color.WHITE)

func get_path_name(path: Enums.Path) -> String:
	if path == Enums.Path.NONE:
		return "None"
	return Enums.Path.keys()[path].capitalize()

func get_affinity_description(path: Enums.Path) -> String:
	var affinity := get_affinity(path)
	if affinity >= 80:
		return "Devoted"
	elif affinity >= 60:
		return "Committed"
	elif affinity >= 40:
		return "Aligned"
	elif affinity >= 30:
		return "Initiated"
	elif affinity >= 15:
		return "Curious"
	else:
		return "Neutral"

# =============================================================================
# CALLBACKS
# =============================================================================

func _on_player_leveled_up(_character: Node, _new_level: int, _stat_gains: Dictionary) -> void:
	# Grant skill point on level up
	add_skill_points(1)

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"path_affinities": path_affinities.duplicate(),
		"skill_tree_states": skill_tree_states.duplicate(),
		"skill_points_allocated": skill_points_allocated.duplicate(),
		"available_skill_points": available_skill_points
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("path_affinities"):
		path_affinities = data.path_affinities.duplicate()
	if data.has("skill_tree_states"):
		skill_tree_states = data.skill_tree_states.duplicate()
	if data.has("skill_points_allocated"):
		skill_points_allocated = data.skill_points_allocated.duplicate()
	if data.has("available_skill_points"):
		available_skill_points = data.available_skill_points

func reset_to_default() -> void:
	path_affinities = {
		Enums.Path.IRONBOUND: 0.0,
		Enums.Path.FANGBORN: 0.0,
		Enums.Path.VOIDTOUCHED: 0.0,
		Enums.Path.UNCHAINED: 0.0
	}
	skill_tree_states = {
		Enums.Path.IRONBOUND: Enums.SkillTreeState.LOCKED,
		Enums.Path.FANGBORN: Enums.SkillTreeState.LOCKED,
		Enums.Path.VOIDTOUCHED: Enums.SkillTreeState.LOCKED,
		Enums.Path.UNCHAINED: Enums.SkillTreeState.LOCKED
	}
	skill_points_allocated = {
		Enums.Path.IRONBOUND: 0,
		Enums.Path.FANGBORN: 0,
		Enums.Path.VOIDTOUCHED: 0,
		Enums.Path.UNCHAINED: 0
	}
	available_skill_points = 0
