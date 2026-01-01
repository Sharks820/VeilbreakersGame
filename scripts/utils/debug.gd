class_name Debug
extends RefCounted
## Debug: Debug utilities and console commands.

# =============================================================================
# DEBUG FLAGS
# =============================================================================

static var show_fps: bool = false
static var show_collision: bool = false
static var god_mode: bool = false
static var infinite_money: bool = false
static var skip_battles: bool = false
static var instant_purification: bool = false

# =============================================================================
# CONSOLE COMMANDS
# =============================================================================

static var commands: Dictionary = {
	"help": _cmd_help,
	"god": _cmd_god_mode,
	"money": _cmd_money,
	"heal": _cmd_heal,
	"level": _cmd_level,
	"setpath": _cmd_set_path,
	"vera": _cmd_vera_state,
	"unlock": _cmd_unlock_brand,
	"tp": _cmd_teleport,
	"spawn": _cmd_spawn,
	"setflag": _cmd_set_flag,
	"getflag": _cmd_get_flag,
	"save": _cmd_save,
	"load": _cmd_load,
	"fps": _cmd_toggle_fps,
	"clear": _cmd_clear
}

static func execute_command(command_line: String) -> String:
	if not OS.is_debug_build():
		return "Debug commands disabled in release builds"

	var parts := command_line.strip_edges().split(" ", false)
	if parts.is_empty():
		return ""

	var cmd := parts[0].to_lower()
	var args := parts.slice(1)

	if commands.has(cmd):
		return commands[cmd].call(args)
	else:
		return "Unknown command: %s. Type 'help' for available commands." % cmd

# =============================================================================
# COMMAND IMPLEMENTATIONS
# =============================================================================

static func _cmd_help(_args: Array) -> String:
	return """Available commands:
  help - Show this help
  god - Toggle god mode (invincibility)
  money [amount] - Add currency (default: 10000)
  heal - Fully heal party
  level [amount] - Add levels (default: 1)
  setpath [value] - Set path alignment (-100 to 100)
  vera [state] - Set VERA state (0-3)
  unlock [brand] - Unlock brand (savage/iron/venom/surge/dread/leech)
  tp [area] - Teleport to area
  spawn [monster] - Spawn monster in next battle
  setflag [flag] [value] - Set story flag
  getflag [flag] - Get story flag value
  save [slot] - Quick save to slot (0-2)
  load [slot] - Quick load from slot (0-2)
  fps - Toggle FPS display
  clear - Clear console"""

static func _cmd_god_mode(_args: Array) -> String:
	god_mode = not god_mode
	return "God mode: %s" % ("ON" if god_mode else "OFF")

static func _cmd_money(args: Array) -> String:
	var amount := 10000
	if args.size() > 0 and args[0].is_valid_int():
		amount = int(args[0])
	GameManager.add_currency(amount)
	return "Added %d currency. Total: %d" % [amount, GameManager.currency]

static func _cmd_heal(_args: Array) -> String:
	# Will fully heal party when party system is implemented
	return "Party fully healed"

static func _cmd_level(args: Array) -> String:
	var amount := 1
	if args.size() > 0 and args[0].is_valid_int():
		amount = int(args[0])
	GameManager.player_level += amount
	return "Level increased by %d. Current level: %d" % [amount, GameManager.player_level]

static func _cmd_set_path(args: Array) -> String:
	if args.is_empty() or not args[0].is_valid_float():
		return "Usage: setpath [value] (e.g., setpath 50)"
	var value := float(args[0])
	var old := GameManager.path_alignment
	GameManager.path_alignment = clampf(value, Constants.PATH_MIN, Constants.PATH_MAX)
	return "Path alignment: %.1f -> %.1f (%s)" % [old, GameManager.path_alignment, GameManager.get_path_name()]

static func _cmd_vera_state(args: Array) -> String:
	if args.is_empty() or not args[0].is_valid_int():
		return "Usage: vera [state] (0=INTERFACE, 1=FRACTURE, 2=EMERGENCE, 3=APOTHEOSIS)"
	var state := int(args[0])
	if state < 0 or state > 3:
		return "Invalid state. Use 0-3"
	# Will set VERA state when VERASystem is implemented
	return "VERA state set to: %s" % Enums.VERAState.keys()[state]

static func _cmd_unlock_brand(args: Array) -> String:
	if args.is_empty():
		return "Usage: unlock [brand] (savage/iron/venom/surge/dread/leech/bloodiron/corrosive/venomstrike/terrorflux/nightleech/ravenous)"
	var brand_name := args[0].to_upper()
	var brand_map := {
		# Pure Brands
		"SAVAGE": Enums.Brand.SAVAGE,
		"IRON": Enums.Brand.IRON,
		"VENOM": Enums.Brand.VENOM,
		"SURGE": Enums.Brand.SURGE,
		"DREAD": Enums.Brand.DREAD,
		"LEECH": Enums.Brand.LEECH,
		# Hybrid Brands
		"BLOODIRON": Enums.Brand.BLOODIRON,
		"CORROSIVE": Enums.Brand.CORROSIVE,
		"VENOMSTRIKE": Enums.Brand.VENOMSTRIKE,
		"TERRORFLUX": Enums.Brand.TERRORFLUX,
		"NIGHTLEECH": Enums.Brand.NIGHTLEECH,
		"RAVENOUS": Enums.Brand.RAVENOUS
	}
	if not brand_map.has(brand_name):
		return "Unknown brand: %s" % args[0]
	GameManager.unlock_brand(brand_map[brand_name])
	return "Unlocked brand: %s" % brand_name

static func _cmd_teleport(args: Array) -> String:
	if args.is_empty():
		return "Usage: tp [area]"
	var area := args[0]
	GameManager.current_area = area
	return "Teleported to: %s (scene change not implemented)" % area

static func _cmd_spawn(args: Array) -> String:
	if args.is_empty():
		return "Usage: spawn [monster_id]"
	return "Will spawn %s in next battle (not implemented)" % args[0]

static func _cmd_set_flag(args: Array) -> String:
	if args.size() < 2:
		return "Usage: setflag [flag] [value]"
	var flag := args[0]
	var value: Variant = true
	if args[1].to_lower() == "false":
		value = false
	elif args[1].is_valid_int():
		value = int(args[1])
	elif args[1].is_valid_float():
		value = float(args[1])
	else:
		value = args[1]
	GameManager.set_story_flag(flag, value)
	return "Flag '%s' set to: %s" % [flag, value]

static func _cmd_get_flag(args: Array) -> String:
	if args.is_empty():
		return "Usage: getflag [flag]"
	var flag := args[0]
	var value = GameManager.get_story_flag(flag)
	return "Flag '%s' = %s" % [flag, value]

static func _cmd_save(args: Array) -> String:
	var slot := 0
	if args.size() > 0 and args[0].is_valid_int():
		slot = clampi(int(args[0]), 0, Constants.MAX_SAVE_SLOTS - 1)
	SaveManager.save_game(slot)
	return "Saving to slot %d..." % slot

static func _cmd_load(args: Array) -> String:
	var slot := 0
	if args.size() > 0 and args[0].is_valid_int():
		slot = clampi(int(args[0]), 0, Constants.MAX_SAVE_SLOTS - 1)
	SaveManager.load_game(slot)
	return "Loading from slot %d..." % slot

static func _cmd_toggle_fps(_args: Array) -> String:
	show_fps = not show_fps
	return "FPS display: %s" % ("ON" if show_fps else "OFF")

static func _cmd_clear(_args: Array) -> String:
	return "[CLEAR]"

# =============================================================================
# LOGGING HELPERS
# =============================================================================

static func log_battle(message: String) -> void:
	if OS.is_debug_build():
		print("[BATTLE] ", message)

static func log_system(message: String) -> void:
	if OS.is_debug_build():
		print("[SYSTEM] ", message)

static func log_vera(message: String) -> void:
	if OS.is_debug_build():
		print("[VERA] ", message)

static func log_save(message: String) -> void:
	if OS.is_debug_build():
		print("[SAVE] ", message)

# =============================================================================
# PERFORMANCE HELPERS
# =============================================================================

static var _perf_markers: Dictionary = {}

static func perf_start(label: String) -> void:
	_perf_markers[label] = Time.get_ticks_usec()

static func perf_end(label: String) -> float:
	if not _perf_markers.has(label):
		return 0.0
	var elapsed := (Time.get_ticks_usec() - _perf_markers[label]) / 1000.0
	_perf_markers.erase(label)
	if OS.is_debug_build():
		print("[PERF] %s: %.3f ms" % [label, elapsed])
	return elapsed
