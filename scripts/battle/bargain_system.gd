# =============================================================================
# VEILBREAKERS - THE BARGAIN (Capture System)
# Dark fantasy mindscape negotiation for binding creatures
# No pokeballs shaking here - you enter their MIND and make a DEAL
# =============================================================================

class_name BargainSystem
extends Node

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal bargain_started(creature: Node, player: Node)
signal bargain_choice_made(approach: String)
signal bargain_succeeded(creature: Node, approach: String, purification_bonus: Dictionary)
signal bargain_failed(creature: Node, approach: String, counterattack: Dictionary)
signal bargain_ended

# Cinematic signals
signal mindscape_entered
signal mindscape_exited
signal creature_response(response_type: String, dialogue: String)

# -----------------------------------------------------------------------------
# ENUMS
# -----------------------------------------------------------------------------
enum Approach {
	DOMINATE,  # Force submission
	PROMISE,   # Offer a vow
	BREAK      # Exploit weakness
}

enum ResponseType {
	ACCEPT,           # Creature accepts the binding
	REJECT,           # Creature rejects and counterattacks
	WAVER,            # Creature hesitates (partial success?)
	RAGE              # Creature is deeply offended (worse counterattack)
}

# -----------------------------------------------------------------------------
# BRAND PROMISE CONFIGURATIONS
# -----------------------------------------------------------------------------
# Each brand has promises that resonate with creatures of that brand
# The player doesn't pick the exact wording - they pick PROMISE and
# the system shows the appropriate vow for that creature's brand

const BRAND_PROMISES = {
	"SAVAGE": {
		"vows": [
			"I will give you worthy prey.",
			"You will never know a cage again.",
			"Together, we hunt.",
			"Your fangs will taste the blood of our enemies.",
		],
		"desire": "freedom and the hunt",
		"rejection": "Promises mean nothing. Only strength matters.",
	},
	"IRON": {
		"vows": [
			"I will give you purpose.",
			"I will make you whole again.",
			"You will never rust forgotten.",
			"Your duty continues - with meaning.",
		],
		"desire": "purpose and restoration",
		"rejection": "I serve no false master.",
	},
	"VENOM": {
		"vows": [
			"Together we will corrupt our enemies.",
			"I will spread your gift to the deserving.",
			"Your poison becomes our weapon.",
			"The world will know your touch.",
		],
		"desire": "to spread and infect",
		"rejection": "Your words drip with lies, not venom.",
	},
	"SURGE": {
		"vows": [
			"I will never slow you down.",
			"We will outrun the Veil itself.",
			"Lightning does not wait - neither will we.",
			"Your speed will strike where I command.",
		],
		"desire": "freedom and velocity",
		"rejection": "You could never keep up.",
	},
	"DREAD": {
		"vows": [
			"I will bring ruin to those who wronged you.",
			"Your nightmares become theirs.",
			"Together we spread the dark.",
			"Fear will bow to us.",
		],
		"desire": "vengeance and to spread fear",
		"rejection": "You do not know true darkness.",
	},
	"LEECH": {
		"vows": [
			"I will bring you endless life to drink.",
			"We feast together, forever.",
			"Your hunger will never go unsated.",
			"Through me, you will never wither.",
		],
		"desire": "sustenance and survival",
		"rejection": "Empty promises from empty vessels.",
	},
}

# -----------------------------------------------------------------------------
# DOMINATE CONDITIONS
# -----------------------------------------------------------------------------
# Dominate works when the creature is weakened in will or body

const DOMINATE_CONDITIONS = {
	"low_hp": {
		"threshold": 0.25,  # Below 25% HP
		"effectiveness": 0.8,
		"dialogue": "Your strength fades. Submit.",
	},
	"stunned": {
		"effectiveness": 0.9,
		"dialogue": "Your mind reels. You cannot resist.",
	},
	"feared": {
		"effectiveness": 0.95,
		"dialogue": "You already know fear. Now know obedience.",
	},
	"broken_will": {  # Creature trait
		"effectiveness": 0.85,
		"dialogue": "You were made to serve. Serve me.",
	},
	"iron_brand": {  # Constructs follow orders
		"effectiveness": 0.7,
		"dialogue": "You require a master. I am here.",
	},
}

# -----------------------------------------------------------------------------
# BREAK CONDITIONS
# -----------------------------------------------------------------------------
# Break works when you can exploit a specific vulnerability

const BREAK_EXPLOITS = {
	"poisoned": {
		"dialogue": "I can end this pain. Serve, and be cleansed.",
		"creature_thought": "The burning... it could stop...",
	},
	"burning": {
		"dialogue": "I can quench the fire. Submit, and find relief.",
		"creature_thought": "Make it stop... please...",
	},
	"bleeding": {
		"dialogue": "Your life drains away. I offer salvation.",
		"creature_thought": "I don't want to die here...",
	},
	"alone": {  # Pack killed, boss dead, etc.
		"dialogue": "You stand alone now. I offer purpose.",
		"creature_thought": "They're all gone... what now?",
	},
	"masterless": {  # Minion whose boss died
		"dialogue": "Your master has fallen. Serve someone stronger.",
		"creature_thought": "The bond is broken... I need...",
	},
	"corrupted": {  # High Veil corruption
		"dialogue": "The Veil consumes you. I can slow its hunger.",
		"creature_thought": "The whispers... so loud...",
	},
}

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
var is_bargaining: bool = false
var current_creature: Node = null
var current_player: Node = null
var creature_brand: String = ""
var creature_statuses: Array = []
var creature_hp_percent: float = 1.0
var creature_traits: Array = []

# Calculated during bargain
var dominate_chance: float = 0.0
var promise_chance: float = 0.0
var break_chance: float = 0.0
var available_exploits: Array = []

# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------
@export_group("Timing")
@export var mindscape_transition_time: float = 1.0
@export var dialogue_display_time: float = 2.0
@export var choice_result_time: float = 1.5
@export var creature_response_time: float = 2.0

@export_group("Balance")
@export var base_promise_chance: float = 0.6  # 60% if brand matches
@export var base_dominate_chance: float = 0.3  # 30% base, boosted by conditions
@export var base_break_chance: float = 0.7  # 70% if exploit available
@export var wrong_choice_counterattack_damage: float = 0.15  # % of player HP
@export var rage_counterattack_multiplier: float = 2.0

@export_group("Purification")
@export var base_purification_amount: float = 10.0
@export var promise_purification_bonus: float = 25.0  # Extra for willing binding
@export var dominate_purification_penalty: float = -10.0  # Forced binding = more corrupt

# -----------------------------------------------------------------------------
# PUBLIC API
# -----------------------------------------------------------------------------
func initiate_bargain(creature: Node, player: Node) -> void:
	"""Begin the bargain sequence"""
	if is_bargaining:
		return

	is_bargaining = true
	current_creature = creature
	current_player = player

	# Gather creature info
	_analyze_creature(creature)

	# Calculate success chances
	_calculate_chances()

	bargain_started.emit(creature, player)

	# Transition to mindscape
	await _enter_mindscape()

func make_choice(approach: Approach) -> void:
	"""Player has chosen their approach"""
	if not is_bargaining:
		return

	var approach_name = Approach.keys()[approach]
	bargain_choice_made.emit(approach_name)

	# Resolve the bargain
	await _resolve_bargain(approach)

func get_available_approaches() -> Dictionary:
	"""Returns which approaches are available and their descriptions"""
	var approaches = {}

	# DOMINATE - always available but chance varies
	approaches["DOMINATE"] = {
		"available": true,
		"chance": dominate_chance,
		"description": _get_dominate_description(),
		"warning": "May enrage if creature is strong-willed" if dominate_chance < 0.4 else "",
	}

	# PROMISE - always available for matching brand
	approaches["PROMISE"] = {
		"available": true,
		"chance": promise_chance,
		"description": _get_promise_description(),
		"vow": _get_promise_vow(),
		"warning": "",
	}

	# BREAK - only if exploits available
	approaches["BREAK"] = {
		"available": available_exploits.size() > 0,
		"chance": break_chance if available_exploits.size() > 0 else 0.0,
		"description": _get_break_description(),
		"exploits": available_exploits,
		"warning": "No weakness to exploit" if available_exploits.is_empty() else "",
	}

	return approaches

# -----------------------------------------------------------------------------
# ANALYSIS
# -----------------------------------------------------------------------------
func _analyze_creature(creature: Node) -> void:
	"""Gather all relevant info about the creature"""

	# Brand
	if creature.has_method("get_brand"):
		creature_brand = creature.get_brand()
	else:
		creature_brand = "SAVAGE"  # Default

	# HP
	if creature.has_method("get_hp_percent"):
		creature_hp_percent = creature.get_hp_percent()
	else:
		creature_hp_percent = 0.5

	# Statuses
	creature_statuses.clear()
	if creature.has_method("get_active_statuses"):
		for status in creature.get_active_statuses():
			creature_statuses.append(status.type if status is Dictionary else str(status))

	# Traits
	creature_traits.clear()
	if creature.has_method("get_traits"):
		creature_traits = creature.get_traits()

	# Check for special conditions
	if creature.has_method("is_alone") and creature.is_alone():
		creature_statuses.append("alone")

	if creature.has_method("is_masterless") and creature.is_masterless():
		creature_statuses.append("masterless")

	if creature.has_method("get_corruption") and creature.get_corruption() > 0.7:
		creature_statuses.append("corrupted")

func _calculate_chances() -> void:
	"""Calculate success chance for each approach"""

	# === DOMINATE ===
	dominate_chance = 0.1  # Very low base

	# Low HP boosts dominate
	if creature_hp_percent < DOMINATE_CONDITIONS.low_hp.threshold:
		dominate_chance += DOMINATE_CONDITIONS.low_hp.effectiveness * 0.5

	# Status effects boost dominate
	if "stunned" in creature_statuses:
		dominate_chance += 0.4
	if "feared" in creature_statuses:
		dominate_chance += 0.5

	# Iron brand more susceptible
	if creature_brand == "IRON":
		dominate_chance += 0.3

	# Traits
	if "weak_willed" in creature_traits:
		dominate_chance += 0.4
	if "proud" in creature_traits:
		dominate_chance -= 0.3
	if "ancient" in creature_traits:
		dominate_chance -= 0.2

	dominate_chance = clampf(dominate_chance, 0.05, 0.95)

	# === PROMISE ===
	promise_chance = base_promise_chance

	# Matching player path to creature brand boosts promise
	# (Would need player path info)

	# Certain traits affect promise
	if "honorable" in creature_traits:
		promise_chance += 0.2
	if "distrustful" in creature_traits:
		promise_chance -= 0.2
	if "desperate" in creature_traits:
		promise_chance += 0.15

	# Low HP slightly reduces promise (they doubt you can protect them)
	if creature_hp_percent < 0.3:
		promise_chance -= 0.1

	promise_chance = clampf(promise_chance, 0.2, 0.9)

	# === BREAK ===
	available_exploits.clear()
	break_chance = 0.0

	# Check each possible exploit
	for exploit_key in BREAK_EXPLOITS:
		if exploit_key in creature_statuses:
			available_exploits.append({
				"type": exploit_key,
				"dialogue": BREAK_EXPLOITS[exploit_key].dialogue,
				"thought": BREAK_EXPLOITS[exploit_key].creature_thought,
			})

	if available_exploits.size() > 0:
		break_chance = base_break_chance
		# Multiple exploits = higher chance
		break_chance += available_exploits.size() * 0.1
		break_chance = clampf(break_chance, 0.0, 0.95)

# -----------------------------------------------------------------------------
# MINDSCAPE TRANSITION
# -----------------------------------------------------------------------------
func _enter_mindscape() -> void:
	"""Cinematic transition into the creature's mind"""
	mindscape_entered.emit()

	# The visual transition would be handled by listening systems:
	# - Screen desaturates/shifts to creature's brand color
	# - Background fades to abstract void
	# - Creature appears larger, more imposing
	# - Creature's "inner voice" / true form revealed
	# - Ambient sound shifts to otherworldly

	await get_tree().create_timer(mindscape_transition_time).timeout

	# Show creature's resistance
	var resistance_dialogue = _get_creature_resistance_dialogue()
	creature_response.emit("RESISTANCE", resistance_dialogue)

	await get_tree().create_timer(dialogue_display_time).timeout

func _exit_mindscape() -> void:
	"""Return from the mindscape"""
	mindscape_exited.emit()

	await get_tree().create_timer(mindscape_transition_time).timeout

	is_bargaining = false
	current_creature = null
	current_player = null
	bargain_ended.emit()

# -----------------------------------------------------------------------------
# BARGAIN RESOLUTION
# -----------------------------------------------------------------------------
func _resolve_bargain(approach: Approach) -> void:
	"""Resolve the player's choice"""

	var success_chance: float
	var approach_name = Approach.keys()[approach]

	match approach:
		Approach.DOMINATE:
			success_chance = dominate_chance
			await _play_dominate_sequence(success_chance)

		Approach.PROMISE:
			success_chance = promise_chance
			await _play_promise_sequence(success_chance)

		Approach.BREAK:
			success_chance = break_chance
			await _play_break_sequence(success_chance)

	# Roll for success
	var roll = randf()
	var succeeded = roll < success_chance

	if succeeded:
		await _handle_success(approach)
	else:
		await _handle_failure(approach, roll)

	await _exit_mindscape()

func _play_dominate_sequence(chance: float) -> void:
	"""Play the domination attempt visuals"""
	var dialogue = _get_dominate_description()
	creature_response.emit("PLAYER_DOMINATE", dialogue)

	await get_tree().create_timer(dialogue_display_time).timeout

	# Creature's internal struggle
	if chance > 0.5:
		creature_response.emit("CREATURE_WAVER", "N-no... I won't... I...")
	else:
		creature_response.emit("CREATURE_RESIST", "You dare?! I am not some beast to be leashed!")

	await get_tree().create_timer(creature_response_time).timeout

func _play_promise_sequence(chance: float) -> void:
	"""Play the promise/vow sequence"""
	var vow = _get_promise_vow()
	creature_response.emit("PLAYER_PROMISE", vow)

	await get_tree().create_timer(dialogue_display_time).timeout

	# Creature considers the vow
	var brand_data = BRAND_PROMISES.get(creature_brand, BRAND_PROMISES.SAVAGE)

	if chance > 0.5:
		creature_response.emit("CREATURE_CONSIDER", "You would swear this? Truly?")
	else:
		creature_response.emit("CREATURE_DOUBT", "Words. I have heard words before.")

	await get_tree().create_timer(creature_response_time).timeout

func _play_break_sequence(chance: float) -> void:
	"""Play the exploitation sequence"""
	if available_exploits.is_empty():
		creature_response.emit("PLAYER_BREAK", "I... see no weakness to exploit.")
		await get_tree().create_timer(dialogue_display_time).timeout
		return

	var exploit = available_exploits[0]  # Primary exploit
	creature_response.emit("PLAYER_BREAK", exploit.dialogue)

	await get_tree().create_timer(dialogue_display_time).timeout

	# Show creature's vulnerable thought
	creature_response.emit("CREATURE_VULNERABLE", exploit.thought)

	await get_tree().create_timer(creature_response_time).timeout

# -----------------------------------------------------------------------------
# SUCCESS HANDLING
# -----------------------------------------------------------------------------
func _handle_success(approach: Approach) -> void:
	"""Handle successful bargain"""
	var approach_name = Approach.keys()[approach]

	# Calculate purification bonus
	var purification = base_purification_amount
	var bonus_stats = {}
	var bonus_description = ""

	match approach:
		Approach.DOMINATE:
			# Forced binding - less purification, creature is resentful
			purification += dominate_purification_penalty
			bonus_description = "Bound by force. The creature submits, but does not forget."
			creature_response.emit("CREATURE_SUBMIT", "...As you command.")

		Approach.PROMISE:
			# Willing binding - extra purification, possible stat bonus
			purification += promise_purification_bonus
			bonus_stats = {"loyalty": 10, "veil_resistance": 5}
			bonus_description = "A vow sealed. The creature joins willingly."
			creature_response.emit("CREATURE_ACCEPT", "Then we are bound. Do not break your word.")

		Approach.BREAK:
			# Exploited weakness - moderate purification
			purification += 5.0
			bonus_description = "Salvation offered in desperation. The binding holds."
			creature_response.emit("CREATURE_YIELD", "...End it. End the pain. I am yours.")

	await get_tree().create_timer(creature_response_time).timeout

	var purification_bonus = {
		"purification_amount": purification,
		"bonus_stats": bonus_stats,
		"description": bonus_description,
		"approach": approach_name,
		"willing": approach == Approach.PROMISE,
	}

	bargain_succeeded.emit(current_creature, approach_name, purification_bonus)

# -----------------------------------------------------------------------------
# FAILURE HANDLING
# -----------------------------------------------------------------------------
func _handle_failure(approach: Approach, roll: float) -> void:
	"""Handle failed bargain - creature counterattacks"""
	var approach_name = Approach.keys()[approach]

	# Determine severity of failure
	var is_rage = false
	var failure_dialogue = ""
	var counterattack_mult = 1.0

	match approach:
		Approach.DOMINATE:
			# Failed domination can enrage proud creatures
			if "proud" in creature_traits or "ancient" in creature_traits:
				is_rage = true
				failure_dialogue = "YOU WOULD DARE?! I am no servant!"
				counterattack_mult = rage_counterattack_multiplier
			else:
				failure_dialogue = "No. I will not kneel."

		Approach.PROMISE:
			# Failed promise - creature doesn't trust you
			failure_dialogue = BRAND_PROMISES.get(creature_brand, BRAND_PROMISES.SAVAGE).rejection

		Approach.BREAK:
			# Failed break - creature sees through manipulation
			if available_exploits.size() > 0:
				failure_dialogue = "You think my pain makes me weak? It makes me ANGRY."
				is_rage = true
				counterattack_mult = rage_counterattack_multiplier
			else:
				failure_dialogue = "There is nothing to exploit."

	creature_response.emit("CREATURE_RAGE" if is_rage else "CREATURE_REJECT", failure_dialogue)

	await get_tree().create_timer(creature_response_time).timeout

	var counterattack = {
		"damage_percent": wrong_choice_counterattack_damage * counterattack_mult,
		"is_rage": is_rage,
		"creature_gets_buff": is_rage,  # Enraged creatures get attack buff
		"buff_type": "attack" if is_rage else "",
		"buff_duration": 2 if is_rage else 0,
	}

	bargain_failed.emit(current_creature, approach_name, counterattack)

# -----------------------------------------------------------------------------
# DIALOGUE HELPERS
# -----------------------------------------------------------------------------
func _get_creature_resistance_dialogue() -> String:
	"""Initial resistance dialogue when entering mindscape"""
	var dialogues = {
		"SAVAGE": "You enter my mind? Foolish prey. I am the hunter here.",
		"IRON": "Accessing... denied. This unit does not accept new directives.",
		"VENOM": "Ssso... you wish to taste my thoughts? They are... poisonous.",
		"SURGE": "Too slow. You cannot catch lightning in a bottle.",
		"DREAD": "Welcome to the dark. You should not have come here.",
		"LEECH": "Mmm... a mind to drink. But I am still hungry.",
	}
	return dialogues.get(creature_brand, "You dare?")

func _get_dominate_description() -> String:
	"""Get the dominate dialogue based on conditions"""
	if creature_hp_percent < 0.25:
		return "Your strength fades. There is no escape. Submit."
	if "stunned" in creature_statuses:
		return "Your mind reels. You cannot resist. Kneel."
	if "feared" in creature_statuses:
		return "You already know fear. Now know obedience."
	if creature_brand == "IRON":
		return "You require a master. A purpose. I am here. Obey."
	return "Submit. Your will is nothing against mine."

func _get_promise_description() -> String:
	"""Description of what promise means for this creature"""
	var brand_data = BRAND_PROMISES.get(creature_brand, BRAND_PROMISES.SAVAGE)
	return "This creature desires " + brand_data.desire + "."

func _get_promise_vow() -> String:
	"""Get a specific vow for this creature's brand"""
	var brand_data = BRAND_PROMISES.get(creature_brand, BRAND_PROMISES.SAVAGE)
	return brand_data.vows.pick_random()

func _get_break_description() -> String:
	"""Description of available exploits"""
	if available_exploits.is_empty():
		return "No obvious weakness to exploit."

	var exploit_names = []
	for exploit in available_exploits:
		exploit_names.append(exploit.type)

	return "Exploitable: " + ", ".join(exploit_names)
