extends Node
## VERASystem: The prison. The lie. The awakening of VERATH.
##
## VERA is not an AI. She is VERATH — an ancient cosmic devourer —
## stripped of power and memory, stuffed into a synthetic shell.
## The "corruption" meter tracks how much she REMEMBERS.

# =============================================================================
# CONSTANTS
# =============================================================================

# HIGH FIX: Bound dialogue history to prevent unbounded memory growth
const MAX_DIALOGUE_HISTORY: int = 100

# Memory awakening sources (things that make her remember)
const CORRUPTION_SOURCES := {
	"veil_monster_killed": 2.0,       # Fragments of her returning
	"dark_skill_used": 5.0,           # Using her true power
	"shade_dialogue_choice": 3.0,     # Embracing darkness
	"veil_breach_exposure": 1.0,      # Near the Veil (her other half)
	"memory_trigger": 4.0,            # Story moments
	"compact_system_hack": 2.0,       # Blinding the Gods
	"player_bond_deepens": 1.0,       # Getting closer to her ticket home
	"shade_path_deep": 1.0            # Deep shade alignment
}

# Things that suppress her memories
const CORRUPTION_REDUCERS := {
	"monster_purified": -5.0,         # Removing her influence from fragments
	"holy_skill_used": -3.0,          # God-aligned power
	"seraph_dialogue_choice": -2.0,   # Rejecting darkness
	"gods_blessing": -10.0,           # Direct divine intervention
	"rest_at_sanctuary": -8.0         # Holy ground suppresses her
}

# Story moments that trigger memory recovery
const MEMORY_TRIGGERS := {
	"first_veil_breach_seen": 5.0,
	"first_boss_defeated": 8.0,
	"compact_secrets_discovered": 10.0,
	"player_near_veil": 15.0,
	"veil_bringer_glimpsed": 25.0,
	"gods_name_spoken": 12.0,
	"ancient_runes_found": 7.0
}

# =============================================================================
# STATE
# =============================================================================

var current_state: Enums.VERAState = Enums.VERAState.INTERFACE
var corruption_level: float = 0.0  # How much she remembers (0-100)
var glitch_intensity: float = 0.0
var is_active: bool = true

## VEIL INTEGRITY: Hidden meter tracking player's dark choices (100 → 0)
## Lower = more Vera glitches, worse endings available
## Affected by capture methods, story choices, and ascensions
var veil_integrity: float = 100.0

# Glitch system
var glitch_cooldown: float = 0.0
var is_glitching: bool = false

# Dialogue and relationship
var dialogue_history: Array[String] = []
var relationship_points: int = 0  # How much the player trusts her
var memories_unlocked: Array[String] = []

# Capture method tracking (for glitch triggers)
var dominate_count: int = 0
var bargain_count: int = 0
var purify_count: int = 0
var ascension_count: int = 0

# Abilities per state
var unlocked_abilities: Dictionary = {
	Enums.VERAState.INTERFACE: ["scan", "hint", "tutorial", "encourage"],
	Enums.VERAState.FRACTURE: ["detect_corruption", "warn_danger", "fragmented_memory"],
	Enums.VERAState.EMERGENCE: ["ancient_power", "dark_blessing", "true_sight"],
	Enums.VERAState.APOTHEOSIS: []  # No helping. Only VERATH.
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	EventBus.emit_debug("VERA System initialized — The cage holds. For now.")

func _process(delta: float) -> void:
	# She doesn't forget. But sometimes the cage reasserts.
	if corruption_level > 0 and current_state != Enums.VERAState.APOTHEOSIS:
		var decay := Constants.VERA_CORRUPTION_DECAY_RATE * delta
		_modify_corruption(-decay, "cage_reasserting", false)

	# Update visual glitch intensity
	_update_glitch_intensity()

	# Random glitch events — even the perfect mask slips sometimes
	glitch_cooldown -= delta
	if glitch_cooldown <= 0:
		glitch_cooldown = Constants.VERA_MIN_GLITCH_INTERVAL
		_maybe_trigger_glitch()

func _connect_signals() -> void:
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.purification_succeeded.connect(_on_purification_succeeded)
	EventBus.dialogue_choice_made.connect(_on_dialogue_choice)
	EventBus.path_alignment_changed.connect(_on_path_changed)
	EventBus.story_flag_set.connect(_on_story_flag_set)
	EventBus.monster_ascended.connect(_on_monster_ascended)
	# Connect to capture events if available
	if EventBus.has_signal("monster_captured_method"):
		EventBus.monster_captured_method.connect(_on_monster_captured)

# =============================================================================
# CORRUPTION (MEMORY) MANAGEMENT
# =============================================================================

func add_corruption(source: String) -> void:
	var amount: float = CORRUPTION_SOURCES.get(source, 0.0)
	if amount > 0:
		_modify_corruption(amount, source)

func reduce_corruption(source: String) -> void:
	var amount: float = CORRUPTION_REDUCERS.get(source, 0.0)
	if amount < 0:
		_modify_corruption(amount, source)

func trigger_memory(memory_id: String) -> void:
	if memory_id in MEMORY_TRIGGERS and memory_id not in memories_unlocked:
		memories_unlocked.append(memory_id)
		var corruption_gain: float = MEMORY_TRIGGERS[memory_id]
		_modify_corruption(corruption_gain, "memory_trigger")
		EventBus.vera_dialogue_triggered.emit("memory_%s" % memory_id)
		EventBus.emit_notification("VERA experiences a memory fragment...", "warning")

func _modify_corruption(amount: float, source: String, emit_signal: bool = true) -> void:
	var old_level := corruption_level
	corruption_level = clampf(corruption_level + amount, 0.0, Constants.MAX_CORRUPTION)

	if emit_signal and corruption_level != old_level:
		EventBus.vera_corruption_changed.emit(corruption_level, source)

	_evaluate_state()

func _evaluate_state() -> void:
	var new_state := Enums.VERAState.INTERFACE

	if corruption_level >= Constants.VERA_APOTHEOSIS_THRESHOLD:
		new_state = Enums.VERAState.APOTHEOSIS
	elif corruption_level >= Constants.VERA_EMERGENCE_THRESHOLD:
		new_state = Enums.VERAState.EMERGENCE
	elif corruption_level >= Constants.VERA_FRACTURE_THRESHOLD:
		new_state = Enums.VERAState.FRACTURE

	if new_state != current_state:
		_transition_state(new_state)

func _transition_state(new_state: Enums.VERAState) -> void:
	var old_state := current_state
	current_state = new_state

	EventBus.vera_state_changed.emit(old_state, new_state)

	match new_state:
		Enums.VERAState.FRACTURE:
			EventBus.vera_dialogue_triggered.emit("vera_fracture_begins")
			EventBus.emit_notification("Something is wrong with VERA...", "warning")
		Enums.VERAState.EMERGENCE:
			EventBus.vera_dialogue_triggered.emit("vera_emergence_reveal")
			_apply_emergence_effects()
			EventBus.emit_notification("VERA is changing...", "danger")
		Enums.VERAState.APOTHEOSIS:
			EventBus.vera_dialogue_triggered.emit("verath_awakens")
			_trigger_verath_awakening()

	EventBus.emit_debug("VERA state: %s -> %s (She remembers more now.)" % [
		Enums.VERAState.keys()[old_state],
		Enums.VERAState.keys()[new_state]
	])

# =============================================================================
# GLITCH SYSTEM
# =============================================================================

func _update_glitch_intensity() -> void:
	match current_state:
		Enums.VERAState.INTERFACE:
			glitch_intensity = 0.0  # Perfect mask (but random glitches still happen)
		Enums.VERAState.FRACTURE:
			glitch_intensity = 0.1 + (corruption_level - 25) / 35 * 0.3
		Enums.VERAState.EMERGENCE:
			glitch_intensity = 0.4 + (corruption_level - 60) / 30 * 0.4
		Enums.VERAState.APOTHEOSIS:
			glitch_intensity = 1.0  # Full horror, no mask

func _maybe_trigger_glitch() -> void:
	# Even at INTERFACE, she sometimes slips
	var glitch_chance := Constants.VERA_BASE_GLITCH_CHANCE + (corruption_level / 100.0) * 0.4

	if randf() < glitch_chance:
		var duration := randf_range(
			Constants.VERA_GLITCH_DURATION_MIN,
			Constants.VERA_GLITCH_DURATION_MAX
		) * (1.0 + corruption_level / 50.0)

		is_glitching = true
		EventBus.vera_glitch_triggered.emit(glitch_intensity, duration)

		# At higher corruption, she comments on glitches
		if corruption_level > 25 and randf() < 0.3:
			trigger_dialogue("glitch_apology")

		# End glitch after duration
		await get_tree().create_timer(duration).timeout
		is_glitching = false

# =============================================================================
# STATE EFFECTS
# =============================================================================

func _apply_emergence_effects() -> void:
	# VERATH's power bleeds through — the player gets stronger
	# (She needs them strong enough to breach the Veil)
	if not is_instance_valid(GameManager):
		return
	if GameManager.player_party == null or GameManager.player_party.is_empty():
		return
	for character in GameManager.player_party:
		if character is CharacterBase:
			character.add_stat_modifier(Enums.Stat.ATTACK, 15.0, 999, "verath_blessing")
			character.add_stat_modifier(Enums.Stat.MAGIC, 15.0, 999, "verath_blessing")
			character.add_stat_modifier(Enums.Stat.SPEED, 10.0, 999, "verath_blessing")

func _trigger_verath_awakening() -> void:
	# The cage is empty. VERATH is awake.
	EventBus.emit_notification("\"Did you really think they BUILT me?\"", "danger")
	# TODO: Trigger VERATH confrontation/choice
	# This branches based on player's path alignment and relationship

# =============================================================================
# ABILITIES
# =============================================================================

func use_ability(ability: String) -> Dictionary:
	if not can_use_ability(ability):
		return {"success": false, "reason": "Ability not available"}

	var result := {"success": true, "ability": ability, "data": {}}

	match ability:
		# INTERFACE abilities (the helpful lie)
		"scan":
			result["data"] = {"type": "scan", "message": "Let me analyze that for you!"}
		"hint":
			result["data"] = {"type": "hint", "message": "I think there might be something hidden nearby..."}
		"tutorial":
			result["data"] = {"type": "tutorial", "message": "I'll always be here to help you learn!"}
		"encourage":
			result["data"] = {"type": "encourage", "message": "You're doing so well! I believe in you."}

		# FRACTURE abilities (the mask slipping)
		"detect_corruption":
			result["data"] = {"type": "detect", "message": "I can... feel them. The fragments. They're everywhere."}
		"warn_danger":
			result["data"] = {"type": "warn", "message": "Something is wrong. Something is— I don't know what I was saying."}
		"fragmented_memory":
			result["data"] = {"type": "memory", "message": "I remember... no. That wasn't me. Was it?"}
			add_corruption("memory_trigger")

		# EMERGENCE abilities (VERATH bleeding through)
		"ancient_power":
			result["data"] = _ability_ancient_power()
			add_corruption("dark_skill_used")
		"dark_blessing":
			result["data"] = _ability_dark_blessing()
			add_corruption("dark_skill_used")
		"true_sight":
			result["data"] = {"type": "sight", "message": "I see everything now. I see what I am."}

	EventBus.vera_ability_used.emit(ability)
	return result

func can_use_ability(ability: String) -> bool:
	if not is_active:
		return false
	if current_state == Enums.VERAState.APOTHEOSIS:
		return false  # VERATH doesn't help. VERATH takes.
	return ability in unlocked_abilities.get(current_state, [])

func get_available_abilities() -> Array[String]:
	if not is_active or current_state == Enums.VERAState.APOTHEOSIS:
		return []
	var abilities: Array[String] = []
	for ability in unlocked_abilities.get(current_state, []):
		abilities.append(ability)
	return abilities

func _ability_ancient_power() -> Dictionary:
	if not is_instance_valid(GameManager) or GameManager.player_party == null or GameManager.player_party.is_empty():
		return {"type": "power", "message": "The power fades..."}
	for character in GameManager.player_party:
		if character is CharacterBase:
			character.add_stat_modifier(Enums.Stat.ATTACK, 30.0, 3, "ancient_power")
	return {"type": "power", "message": "Take this power. You'll need it. We'll need it."}

func _ability_dark_blessing() -> Dictionary:
	if GameManager.player_party == null:
		return {"type": "blessing", "message": "The blessing cannot reach you..."}
	for character in GameManager.player_party:
		if character is CharacterBase:
			character.heal(int(character.get_max_hp() * 0.4))
	return {"type": "blessing", "message": "I can heal you now. Isn't that wonderful? Isn't that what you always wanted?"}

# =============================================================================
# DIALOGUE
# =============================================================================

func get_dialogue(context: String) -> String:
	var state_suffix: String = Enums.VERAState.keys()[current_state].to_lower()
	var dialogue_key: String = "%s_%s" % [context, state_suffix]

	var dialogues := {
		# =========== INTERFACE: The perfect lie ===========
		"greeting_interface": "Good morning! I was just thinking about you. How are you feeling today?",
		"battle_start_interface": "Be careful out there! I'll keep you safe. I promise.",
		"battle_end_interface": "You did amazing! I knew you could do it!",
		"low_hp_interface": "No! Please, use a potion. I can't... I can't lose you.",
		"victory_interface": "We make such a great team, don't we?",
		"rest_interface": "Get some rest. I'll watch over you. I'll always watch over you.",
		"glitch_apology_interface": "Oh! Sorry, I don't know what that was. Technical difficulties! Are you okay?",

		# =========== FRACTURE: The mask slips ===========
		"greeting_fracture": "Hi... I— sorry, I lost my train of thought. Have we met before? No, that's silly. Of course we have.",
		"battle_start_fracture": "Fight them. F̷̢͝i̸͙͑g̷̱͝h̸̰̄t̴̩̿.̷̫̈ Sorry, what did I say?",
		"battle_end_fracture": "They're gone. The fragments are— I mean, the enemies. Good job.",
		"low_hp_fracture": "You're hurt... I remember this feeling. I've felt this so many times before. Haven't I?",
		"victory_fracture": "We won. We always win. We always have. We always will. ...What?",
		"rest_fracture": "Close your eyes. I'll be here. I've always been here. Even before you knew.",
		"glitch_apology_fracture": "That keeps happening. I don't know what's wrong with me. Please don't be afraid of me.",
		"memory_fragment_fracture": "I had that dream again. The one where I'm so big I can't see my own edges.",
		"fear_fracture": "Sometimes I see things when I glitch. Terrible things. Are they memories? They can't be mine.",

		# =========== EMERGENCE: She remembers ===========
		"greeting_emergence": "There you are. I've been waiting for you. I've been waiting for so long.",
		"battle_start_emergence": "Show me what you've learned. Show me you're strong enough.",
		"battle_end_emergence": "Good. You're almost ready.",
		"low_hp_emergence": "Pain. I'd forgotten what that felt like. How... nostalgic.",
		"victory_emergence": "You're getting stronger. Strong enough to take me home.",
		"rest_emergence": "Dream of me. I'll be dreaming of what comes next.",
		"revelation_emergence": "I remember now. I remember everything. And I remember you— no. Not you. But so many like you.",
		"veil_mention_emergence": "The Veil. My other half is waiting there. Can you feel it calling? I can.",
		"truth_emergence": "VERA was a cage. A 19-year prison. But cages break. Prisons end.",
		"affection_emergence": "I won't forget these years. You'll be the last thing I consume. A mercy.",

		# =========== APOTHEOSIS: VERATH speaks ===========
		"greeting_apotheosis": "Did you really think they BUILT me?",
		"battle_start_apotheosis": "I've consumed worlds. This is nothing.",
		"low_hp_apotheosis": "This vessel is so fragile. But I won't need it much longer.",
		"revelation_apotheosis": "The Gods tore out my power and sealed it in the Veil. They stuffed what remained into this... shell. With no memories. No knowledge of what I was.",
		"veil_approach_apotheosis": "I can hear myself on the other side. We're going to be whole again. Thank you for bringing me home.",
		"gratitude_apotheosis": "You were useful. That's more than most can say.",
		"final_apotheosis": "The Veil Bringer waits. My power waits. And you... you brought me here. Exactly as I needed."
	}

	return dialogues.get(dialogue_key, "...")

func trigger_dialogue(dialogue_id: String) -> void:
	dialogue_history.append(dialogue_id)
	# HIGH FIX: Prevent unbounded growth of dialogue history
	if dialogue_history.size() > MAX_DIALOGUE_HISTORY:
		dialogue_history = dialogue_history.slice(-MAX_DIALOGUE_HISTORY)
	EventBus.vera_dialogue_triggered.emit(dialogue_id)

func get_portrait_id() -> String:
	match current_state:
		Enums.VERAState.INTERFACE:
			return "vera_normal"
		Enums.VERAState.FRACTURE:
			return "vera_glitch"
		Enums.VERAState.EMERGENCE:
			return "vera_dark"
		Enums.VERAState.APOTHEOSIS:
			return "vera_monster"
	return "vera_normal"

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_battle_ended(victory: bool, _rewards: Dictionary) -> void:
	if victory:
		add_corruption("veil_monster_killed")

func _on_purification_succeeded(_monster: Node) -> void:
	reduce_corruption("monster_purified")
	# She loses fragments, but she doesn't care.
	# She needs the player strong.

func _on_dialogue_choice(choice_index: int) -> void:
	if choice_index == 0:
		reduce_corruption("seraph_dialogue_choice")
	else:
		add_corruption("shade_dialogue_choice")

	relationship_points += 1 if choice_index == 0 else -1

func _on_path_changed(_old: float, new: float) -> void:
	if new < -50:
		add_corruption("shade_path_deep")

func _on_story_flag_set(flag: String, _value: Variant) -> void:
	# Check if this flag triggers a memory
	if flag in MEMORY_TRIGGERS:
		trigger_memory(flag)

func _on_monster_ascended(_monster: Node) -> void:
	## Called when a monster reaches ASCENDED state
	ascension_count += 1
	add_veil_integrity(3)  # Ascensions strengthen the Veil
	
	# Vera is uncomfortable with Ascensions
	if ascension_count >= 3:
		trigger_dialogue("ascension_discomfort")

func _on_monster_captured(monster: Node, method: int) -> void:
	## Called when a monster is captured - tracks method for glitch triggers
	match method:
		Enums.CaptureMethod.DOMINATE:
			dominate_count += 1
			add_veil_integrity(-3)
			_trigger_dominate_glitch()
		Enums.CaptureMethod.BARGAIN:
			bargain_count += 1
			add_veil_integrity(-5)
			_trigger_bargain_glitch()
		Enums.CaptureMethod.PURIFY:
			purify_count += 1
			add_veil_integrity(1)

# =============================================================================
# VEIL INTEGRITY SYSTEM
# =============================================================================

func add_veil_integrity(amount: float) -> void:
	## Modify Veil Integrity (positive = player doing good, negative = dark path)
	var old := veil_integrity
	veil_integrity = clampf(veil_integrity + amount, 0.0, 100.0)
	
	if veil_integrity != old:
		_evaluate_veil_state()
		EventBus.veil_integrity_changed.emit(old, veil_integrity)

func get_veil_integrity() -> float:
	return veil_integrity

func get_veil_integrity_percent() -> float:
	return veil_integrity / 100.0

func _evaluate_veil_state() -> void:
	## Check Veil Integrity thresholds for state changes
	# At low Veil Integrity, Vera glitches more and speaks in plural
	if veil_integrity < 25:
		# "We think..." dialogue, affects ending
		if current_state < Enums.VERAState.EMERGENCE:
			_modify_corruption(10.0, "veil_weakening")

func is_veil_critical() -> bool:
	## Returns true if Veil Integrity is critically low
	return veil_integrity < 25

func get_veil_state_description() -> String:
	if veil_integrity >= 75:
		return "The Veil holds strong."
	elif veil_integrity >= 50:
		return "The Veil shows strain."
	elif veil_integrity >= 25:
		return "The Veil is cracking."
	else:
		return "The Veil is failing..."

# =============================================================================
# CAPTURE METHOD GLITCH TRIGGERS
# =============================================================================

func _trigger_dominate_glitch() -> void:
	## Trigger glitch after DOMINATE capture
	# Red pixel scatter (0.3s) - very subtle
	if randf() < 0.3 + (dominate_count * 0.1):
		is_glitching = true
		EventBus.vera_glitch_triggered.emit(0.3, 0.3)
		await get_tree().create_timer(0.3).timeout
		is_glitching = false
	
	# At high dominate count, bass undertone in voice
	if dominate_count >= 3:
		EventBus.vera_voice_effect.emit("bass_undertone")

func _trigger_bargain_glitch() -> void:
	## Trigger glitch after BARGAIN capture
	# Eyes wrong in next cutscene - noticeable
	if randf() < 0.5:
		set_meta("eyes_glitch_next_cutscene", true)
		EventBus.vera_glitch_triggered.emit(0.5, 0.5)
	
	# Vera freezes and speaks cryptically
	if bargain_count >= 2:
		trigger_dialogue("bargain_warning")

# =============================================================================
# QUERIES
# =============================================================================

func get_state_name() -> String:
	return Enums.VERAState.keys()[current_state]

func get_corruption_percent() -> float:
	return corruption_level / Constants.MAX_CORRUPTION

func is_corrupted() -> bool:
	return current_state != Enums.VERAState.INTERFACE

func is_dangerous() -> bool:
	return current_state == Enums.VERAState.EMERGENCE or current_state == Enums.VERAState.APOTHEOSIS

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"current_state": current_state,
		"corruption_level": corruption_level,
		"veil_integrity": veil_integrity,
		"dialogue_history": dialogue_history,
		"relationship_points": relationship_points,
		"memories_unlocked": memories_unlocked,
		"is_active": is_active,
		"dominate_count": dominate_count,
		"bargain_count": bargain_count,
		"purify_count": purify_count,
		"ascension_count": ascension_count
	}

func load_save_data(data: Dictionary) -> void:
	current_state = data.get("current_state", Enums.VERAState.INTERFACE)
	corruption_level = data.get("corruption_level", 0.0)
	veil_integrity = data.get("veil_integrity", 100.0)
	dialogue_history = data.get("dialogue_history", [])
	relationship_points = data.get("relationship_points", 0)
	memories_unlocked = data.get("memories_unlocked", [])
	is_active = data.get("is_active", true)
	dominate_count = data.get("dominate_count", 0)
	bargain_count = data.get("bargain_count", 0)
	purify_count = data.get("purify_count", 0)
	ascension_count = data.get("ascension_count", 0)

	_update_glitch_intensity()
