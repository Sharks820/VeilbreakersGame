class_name StringHelpers
extends RefCounted
## StringHelpers: Centralized helper functions for common string operations.
## Consolidates 181+ format patterns, 22+ to_lower, 10+ capitalize patterns.

# =============================================================================
# FORMATTING HELPERS (181+ % [value] patterns)
# =============================================================================

## Format HP display (current/max)
static func format_hp(current: int, max_hp: int) -> String:
	return "%d/%d" % [current, max_hp]

## Format MP display (current/max)
static func format_mp(current: int, max_mp: int) -> String:
	return "%d/%d" % [current, max_mp]

## Format stat display (name: value)
static func format_stat(name: String, value: int) -> String:
	return "%s: %d" % [name, value]

## Format stat with sign (+5 or -3)
static func format_stat_change(value: int) -> String:
	if value >= 0:
		return "+%d" % value
	return "%d" % value

## Format percentage (45%)
static func format_percent(value: float) -> String:
	return "%.0f%%" % (value * 100)

## Format percentage with decimal (45.5%)
static func format_percent_decimal(value: float, decimals: int = 1) -> String:
	var format_str := "%%.%df%%%%" % decimals
	return format_str % (value * 100)

## Format damage/heal number with sign
static func format_damage(amount: int) -> String:
	return "-%d" % amount

static func format_heal(amount: int) -> String:
	return "+%d" % amount

## Format level display (Lv. 5)
static func format_level(level: int) -> String:
	return "Lv. %d" % level

## Format level short (L5)
static func format_level_short(level: int) -> String:
	return "L%d" % level

## Format XP display (100/500 XP)
static func format_xp(current: int, required: int) -> String:
	return "%d/%d XP" % [current, required]

## Format gold/currency
static func format_currency(amount: int) -> String:
	if amount >= 1000:
		return "%.1fK" % (amount / 1000.0)
	return str(amount)

## Format time in seconds to MM:SS
static func format_time_mmss(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

## Format time with hours HH:MM:SS
static func format_time_hhmmss(seconds: float) -> String:
	var hours := int(seconds) / 3600
	var mins := (int(seconds) % 3600) / 60
	var secs := int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, mins, secs]

# =============================================================================
# BATTLE LOG FORMATTING
# =============================================================================

## Format attack message
static func format_attack(attacker: String, target: String, skill_name: String) -> String:
	return "%s uses %s on %s!" % [attacker, skill_name, target]

## Format damage message
static func format_damage_dealt(target: String, damage: int) -> String:
	return "%s takes %d damage!" % [target, damage]

## Format critical hit
static func format_critical(target: String, damage: int) -> String:
	return "Critical hit! %s takes %d damage!" % [target, damage]

## Format heal message
static func format_heal_message(target: String, amount: int) -> String:
	return "%s recovers %d HP!" % [target, amount]

## Format status effect applied
static func format_status_applied(target: String, status: String) -> String:
	return "%s is now %s!" % [target, status]

## Format status effect expired
static func format_status_expired(target: String, status: String) -> String:
	return "%s's %s wore off." % [target, status]

## Format death message
static func format_death(target: String) -> String:
	return "%s was defeated!" % target

## Format miss message
static func format_miss(attacker: String) -> String:
	return "%s's attack missed!" % attacker

## Format evade message
static func format_evade(target: String) -> String:
	return "%s evaded the attack!" % target

# =============================================================================
# CASE CONVERSION HELPERS (22+ to_lower, 10+ capitalize patterns)
# =============================================================================

## Capitalize first letter only
static func capitalize_first(text: String) -> String:
	if text.is_empty():
		return text
	return text[0].to_upper() + text.substr(1)

## Title case (each word capitalized)
static func title_case(text: String) -> String:
	var words := text.split(" ")
	var result: PackedStringArray = []
	for word in words:
		result.append(capitalize_first(word.to_lower()))
	return " ".join(result)

## Convert to display name (SAVAGE_BRAND -> Savage Brand)
static func enum_to_display(enum_name: String) -> String:
	return title_case(enum_name.replace("_", " "))

## Convert display name to enum (Savage Brand -> SAVAGE_BRAND)
static func display_to_enum(display_name: String) -> String:
	return display_name.to_upper().replace(" ", "_")

## Normalize for comparison (trim, lowercase)
static func normalize(text: String) -> String:
	return text.strip_edges().to_lower()

## Check if strings match (case-insensitive)
static func matches_ignore_case(a: String, b: String) -> bool:
	return a.to_lower() == b.to_lower()

# =============================================================================
# TRUNCATION AND PADDING
# =============================================================================

## Truncate text with ellipsis
static func truncate(text: String, max_length: int, ellipsis: String = "...") -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length - ellipsis.length()) + ellipsis

## Pad left with character
static func pad_left(text: String, total_width: int, pad_char: String = " ") -> String:
	var padding := maxi(0, total_width - text.length())
	return pad_char.repeat(padding) + text

## Pad right with character
static func pad_right(text: String, total_width: int, pad_char: String = " ") -> String:
	var padding := maxi(0, total_width - text.length())
	return text + pad_char.repeat(padding)

## Center text with padding
static func center(text: String, total_width: int, pad_char: String = " ") -> String:
	var padding := maxi(0, total_width - text.length())
	var left_pad := padding / 2
	var right_pad := padding - left_pad
	return pad_char.repeat(left_pad) + text + pad_char.repeat(right_pad)

# =============================================================================
# PLURALIZATION
# =============================================================================

## Simple pluralize (1 item, 2 items)
static func pluralize(count: int, singular: String, plural: String = "") -> String:
	if plural.is_empty():
		plural = singular + "s"
	return "%d %s" % [count, singular if count == 1 else plural]

## Get plural form only
static func plural_form(count: int, singular: String, plural: String = "") -> String:
	if plural.is_empty():
		plural = singular + "s"
	return singular if count == 1 else plural

# =============================================================================
# PATH AND FILENAME HELPERS
# =============================================================================

## Extract filename from path
static func get_filename(path: String) -> String:
	var parts := path.split("/")
	return parts[-1] if not parts.is_empty() else path

## Extract filename without extension
static func get_filename_no_ext(path: String) -> String:
	var filename := get_filename(path)
	var dot_pos := filename.rfind(".")
	if dot_pos > 0:
		return filename.substr(0, dot_pos)
	return filename

## Get file extension
static func get_extension(path: String) -> String:
	var dot_pos := path.rfind(".")
	if dot_pos > 0:
		return path.substr(dot_pos + 1)
	return ""

## Sanitize filename (remove invalid characters)
static func sanitize_filename(name: String) -> String:
	var invalid := ['<', '>', ':', '"', '/', '\\', '|', '?', '*']
	var result := name
	for char in invalid:
		result = result.replace(char, "_")
	return result

# =============================================================================
# RICH TEXT (BBCode) HELPERS
# =============================================================================

## Wrap text in color BBCode
static func bbcode_color(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]

## Wrap text in bold BBCode
static func bbcode_bold(text: String) -> String:
	return "[b]%s[/b]" % text

## Wrap text in italic BBCode
static func bbcode_italic(text: String) -> String:
	return "[i]%s[/i]" % text

## Create colored stat text (e.g., +5 ATK in green)
static func bbcode_stat_change(value: int, stat_name: String, positive_color: Color = Color.GREEN, negative_color: Color = Color.RED) -> String:
	var color := positive_color if value >= 0 else negative_color
	var sign := "+" if value >= 0 else ""
	return bbcode_color("%s%d %s" % [sign, value, stat_name], color)

## Strip all BBCode tags
static func strip_bbcode(text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)

# =============================================================================
# VALIDATION
# =============================================================================

## Check if string is empty or whitespace
static func is_blank(text: String) -> bool:
	return text.strip_edges().is_empty()

## Check if string contains only digits
static func is_numeric(text: String) -> bool:
	if text.is_empty():
		return false
	for c in text:
		if not c.is_valid_int():
			return false
	return true

## Check if string is valid identifier (alphanumeric + underscore, not starting with digit)
static func is_valid_identifier(text: String) -> bool:
	if text.is_empty():
		return false
	if text[0].is_valid_int():
		return false
	for c in text:
		if not (c.is_valid_identifier() or c == "_"):
			return false
	return true

# =============================================================================
# JOINING AND SPLITTING
# =============================================================================

## Join array with comma and "and" for last item
static func join_with_and(items: Array) -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return str(items[0])
	if items.size() == 2:
		return "%s and %s" % [items[0], items[1]]
	var all_but_last := items.slice(0, -1)
	return "%s, and %s" % [", ".join(all_but_last.map(func(x): return str(x))), items[-1]]

## Join array with comma and "or" for last item
static func join_with_or(items: Array) -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return str(items[0])
	if items.size() == 2:
		return "%s or %s" % [items[0], items[1]]
	var all_but_last := items.slice(0, -1)
	return "%s, or %s" % [", ".join(all_but_last.map(func(x): return str(x))), items[-1]]
