class_name StyleManager
extends Node
## StyleManager: Centralized style factory for all UI elements.
##
## PROBLEM SOLVED:
## The codebase had 98+ StyleBoxFlat.new() calls and 800+ Color() calls
## creating duplicate styles and colors repeatedly, causing:
## - Memory fragmentation from repeated allocations
## - Inconsistent colors across the UI
## - Maintenance nightmare when changing colors
##
## SOLUTION:
## This singleton provides factory methods for all common UI styles.
## It uses UIStyleCache internally for caching and Constants for colors.
##
## USAGE:
## Instead of:
##   var style := StyleBoxFlat.new()
##   style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
##   style.border_color = Color(0.3, 0.25, 0.4, 1.0)
##   style.set_border_width_all(2)
##   style.set_corner_radius_all(8)
##
## Use:
##   var style := StyleManager.panel_dark()
##
## Or for custom styles:
##   var style := StyleManager.custom_panel(Constants.COLOR_PANEL_DARK, Constants.COLOR_BORDER_PURPLE, 2, 8)

# =============================================================================
# REFERENCES
# =============================================================================

## Reference to UIStyleCache for caching
var _cache: Node = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Get reference to UIStyleCache (should be loaded before this)
	_cache = get_node_or_null("/root/UIStyleCache")
	if not _cache:
		push_warning("StyleManager: UIStyleCache not found. Styles will not be cached.")

# =============================================================================
# PANEL STYLES
# =============================================================================

func panel_dark() -> StyleBoxFlat:
	## Standard dark panel background
	if _cache:
		return _cache.panel_dark
	return _create_panel(Constants.COLOR_PANEL_DARK, Constants.COLOR_BORDER_PURPLE, 2, 8)

func panel_dark_red() -> StyleBoxFlat:
	## Enemy-tinted panel background
	if _cache:
		return _cache.panel_dark_red
	return _create_panel(Constants.COLOR_PANEL_DARK_RED, Constants.COLOR_BORDER_ENEMY, 2, 8)

func panel_dark_blue() -> StyleBoxFlat:
	## Ally-tinted panel background
	if _cache:
		return _cache.panel_dark_blue
	return _create_panel(Constants.COLOR_PANEL_DARK_BLUE, Color(0.25, 0.3, 0.5, 1.0), 2, 8)

func panel_transparent() -> StyleBoxFlat:
	## Fully transparent panel
	if _cache:
		return _cache.panel_transparent
	return _create_panel(Constants.COLOR_TRANSPARENT, Constants.COLOR_TRANSPARENT, 0, 0)

func panel_for_team(is_enemy: bool) -> StyleBoxFlat:
	## Get panel style based on team
	return panel_dark_red() if is_enemy else panel_dark_blue()

func custom_panel(bg_color: Color, border_color: Color, border_width: int = 2, corner_radius: int = 8) -> StyleBoxFlat:
	## Create a custom panel with caching
	if _cache:
		return _cache.get_flat(bg_color, border_color, border_width, corner_radius)
	return _create_panel(bg_color, border_color, border_width, corner_radius)

# =============================================================================
# HP/MP/CORRUPTION BAR STYLES
# =============================================================================

func hp_fill(is_enemy: bool = false) -> StyleBoxFlat:
	## HP bar fill style
	if _cache:
		return _cache.get_hp_bar_fill(is_enemy)
	var color := Constants.COLOR_HP_FILL_ENEMY if is_enemy else Constants.COLOR_HP_FILL_ALLY
	return _create_bar_fill(color)

func hp_bg() -> StyleBoxFlat:
	## HP bar background style
	if _cache:
		return _cache.get_hp_bar_bg()
	return _create_bar_bg(Constants.COLOR_HP_BG)

func mp_fill() -> StyleBoxFlat:
	## MP bar fill style
	if _cache:
		return _cache.get_mp_bar_fill()
	return _create_bar_fill(Constants.COLOR_MP_FILL)

func mp_bg() -> StyleBoxFlat:
	## MP bar background style
	if _cache:
		return _cache.get_mp_bar_bg()
	return _create_bar_bg(Constants.COLOR_MP_BG)

func corruption_fill() -> StyleBoxFlat:
	## Corruption bar fill style
	if _cache:
		return _cache.get_corruption_bar_fill()
	return _create_bar_fill(Constants.COLOR_CORRUPTION_FILL)

func corruption_bg() -> StyleBoxFlat:
	## Corruption bar background style
	if _cache:
		return _cache.get_corruption_bar_bg()
	return _create_bar_bg(Constants.COLOR_CORRUPTION_BG)

func xp_fill() -> StyleBoxFlat:
	## XP bar fill style
	return _create_bar_fill(Constants.COLOR_XP_BAR_FILL)

func xp_bg() -> StyleBoxFlat:
	## XP bar background style
	var style := _create_bar_bg(Constants.COLOR_XP_BAR_BG)
	style.border_color = Constants.COLOR_XP_BAR_BORDER
	style.set_border_width_all(1)
	return style

# =============================================================================
# BUTTON STYLES
# =============================================================================

func button_normal() -> StyleBoxFlat:
	## Normal button state
	if _cache:
		return _cache.get_button_style("normal")
	return _create_button(Constants.COLOR_BTN_NORMAL_BG, Constants.COLOR_BTN_BORDER)

func button_hover() -> StyleBoxFlat:
	## Hover button state
	if _cache:
		return _cache.get_button_style("hover")
	return _create_button(Constants.COLOR_BTN_HOVER_BG, Constants.COLOR_BTN_BORDER_HOVER)

func button_pressed() -> StyleBoxFlat:
	## Pressed button state
	if _cache:
		return _cache.get_button_style("pressed")
	return _create_button(Constants.COLOR_BTN_PRESSED_BG, Constants.COLOR_BTN_BORDER)

func button_disabled() -> StyleBoxFlat:
	## Disabled button state
	if _cache:
		return _cache.get_button_style("disabled")
	return _create_button(Constants.COLOR_BTN_DISABLED_BG, Constants.COLOR_BTN_BORDER_DISABLED)

func button_focus() -> StyleBoxFlat:
	## Focused button state
	if _cache:
		return _cache.get_button_style("focus")
	return _create_button(Constants.COLOR_BTN_FOCUS_BG, Constants.COLOR_BTN_BORDER_FOCUS)

# =============================================================================
# PORTRAIT STYLES
# =============================================================================

func portrait_frame(is_enemy: bool = false) -> StyleBoxFlat:
	## Portrait frame style
	if _cache:
		return _cache.get_portrait_frame(is_enemy)
	if is_enemy:
		return _create_panel(Constants.COLOR_PORTRAIT_BG_ENEMY, Constants.COLOR_PORTRAIT_BORDER_ENEMY, 2, 4)
	return _create_panel(Constants.COLOR_PORTRAIT_BG_ALLY, Constants.COLOR_PORTRAIT_BORDER_ALLY, 2, 4)

# =============================================================================
# TOOLTIP STYLES
# =============================================================================

func tooltip() -> StyleBoxFlat:
	## Tooltip background style
	if _cache:
		return _cache.get_tooltip_style()
	return _create_panel(Constants.COLOR_TOOLTIP_BG, Constants.COLOR_TOOLTIP_BORDER, 1, 4)

# =============================================================================
# SIDEBAR STYLES
# =============================================================================

func sidebar_ally() -> StyleBoxFlat:
	## Ally sidebar panel
	return _create_panel(Constants.COLOR_SIDEBAR_ALLY_BG, Constants.COLOR_SIDEBAR_ALLY_BORDER, 2, 8)

func sidebar_enemy() -> StyleBoxFlat:
	## Enemy sidebar panel
	return _create_panel(Constants.COLOR_SIDEBAR_ENEMY_BG, Constants.COLOR_SIDEBAR_ENEMY_BORDER, 2, 8)

func sidebar_slot_ally() -> StyleBoxFlat:
	## Ally sidebar slot
	return _create_panel(Constants.COLOR_SIDEBAR_ALLY_SLOT_BG, Constants.COLOR_SIDEBAR_ALLY_SLOT_BORDER, 1, 4)

func sidebar_slot_enemy() -> StyleBoxFlat:
	## Enemy sidebar slot
	return _create_panel(Constants.COLOR_SIDEBAR_ENEMY_SLOT_BG, Constants.COLOR_SIDEBAR_ENEMY_SLOT_BORDER, 1, 4)

# =============================================================================
# BUFF/DEBUFF STYLES
# =============================================================================

func buff_panel() -> StyleBoxFlat:
	## Buff indicator panel
	return _create_panel(Constants.COLOR_BUFF_PANEL_BG, Constants.COLOR_BUFF_PANEL_BORDER, 1, 4)

func debuff_panel() -> StyleBoxFlat:
	## Debuff indicator panel
	return _create_panel(Constants.COLOR_DEBUFF_PANEL_BG, Constants.COLOR_DEBUFF_PANEL_BORDER, 1, 4)

func status_panel(is_buff: bool) -> StyleBoxFlat:
	## Get status panel based on type
	return buff_panel() if is_buff else debuff_panel()

# =============================================================================
# MONSTER ROW STYLES (Victory Screen)
# =============================================================================

func monster_row() -> StyleBoxFlat:
	## Monster row in victory screen
	return _create_panel(Constants.COLOR_MONSTER_ROW_BG, Constants.COLOR_MONSTER_ROW_BORDER, 1, 4)

# =============================================================================
# SCROLLBAR STYLES
# =============================================================================

func scrollbar_grabber() -> StyleBoxFlat:
	## Scrollbar grabber style
	var style := StyleBoxFlat.new()
	style.bg_color = Constants.COLOR_SCROLLBAR_GRABBER
	style.set_corner_radius_all(4)
	return style

func scrollbar_bg() -> StyleBoxFlat:
	## Scrollbar background style
	var style := StyleBoxFlat.new()
	style.bg_color = Constants.COLOR_SCROLLBAR_BG
	style.set_corner_radius_all(4)
	return style

# =============================================================================
# EMPTY STYLE
# =============================================================================

func empty() -> StyleBoxEmpty:
	## Get an empty StyleBox
	if _cache:
		return _cache.get_empty()
	return StyleBoxEmpty.new()

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

func _create_panel(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style

func _create_bar_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style

func _create_bar_bg(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style

func _create_button(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Constants.COLOR_BTN_SHADOW
	style.shadow_size = 2
	return style

# =============================================================================
# THEME COLOR HELPERS
# =============================================================================

## Apply standard font colors to a button
static func apply_button_font_colors(button: Button) -> void:
	button.add_theme_color_override("font_color", Constants.COLOR_FONT_NORMAL)
	button.add_theme_color_override("font_hover_color", Constants.COLOR_FONT_HOVER)
	button.add_theme_color_override("font_pressed_color", Constants.COLOR_FONT_PRESSED)
	button.add_theme_color_override("font_disabled_color", Constants.COLOR_FONT_DISABLED)

## Apply standard font color to a label
static func apply_label_color(label: Label, color_type: String = "normal") -> void:
	var color: Color
	match color_type:
		"gold": color = Constants.COLOR_TEXT_GOLD
		"parchment": color = Constants.COLOR_TEXT_PARCHMENT
		"disabled": color = Constants.COLOR_TEXT_DISABLED
		"muted": color = Constants.COLOR_FONT_MUTED
		"label": color = Constants.COLOR_FONT_LABEL
		"ally": color = Constants.COLOR_TEXT_ALLY
		"enemy": color = Constants.COLOR_TEXT_ENEMY
		_: color = Constants.COLOR_FONT_NORMAL
	label.add_theme_color_override("font_color", color)

## Get action button color
static func get_action_color(action: String) -> Color:
	match action.to_lower():
		"attack": return Constants.COLOR_ACTION_ATTACK
		"skill": return Constants.COLOR_ACTION_SKILL
		"special", "purify": return Constants.COLOR_ACTION_SPECIAL
		"item": return Constants.COLOR_ACTION_ITEM
		"defend": return Constants.COLOR_ACTION_DEFEND
		"flee": return Constants.COLOR_ACTION_FLEE
		_: return Constants.COLOR_FONT_NORMAL

# =============================================================================
# ACTION BUTTON STYLES (with accent colors)
# =============================================================================

func action_button_normal(accent_color: Color) -> StyleBoxFlat:
	## Normal state for action buttons with accent-tinted border
	var style := StyleBoxFlat.new()
	style.bg_color = Constants.COLOR_BTN_NORMAL_BG
	style.border_color = accent_color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Constants.COLOR_BTN_SHADOW
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	return style

func action_button_hover(accent_color: Color) -> StyleBoxFlat:
	## Hover state for action buttons with accent glow
	var style := StyleBoxFlat.new()
	style.bg_color = Constants.COLOR_BTN_HOVER_BG
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	var shadow_color := accent_color.darkened(0.5)
	shadow_color.a = 0.6
	style.shadow_color = shadow_color
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 0)
	return style

func action_button_pressed(accent_color: Color) -> StyleBoxFlat:
	## Pressed state for action buttons
	var style := StyleBoxFlat.new()
	style.bg_color = accent_color.darkened(0.4)
	style.border_color = accent_color.lightened(0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

func action_button_disabled() -> StyleBoxFlat:
	## Disabled state for action buttons
	var style := StyleBoxFlat.new()
	style.bg_color = Constants.COLOR_BTN_DISABLED_BG
	style.border_color = Constants.COLOR_BTN_BORDER_DISABLED
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

func action_button_focus() -> StyleBoxFlat:
	## Focus state for action buttons
	var style := StyleBoxFlat.new()
	style.bg_color = Constants.COLOR_BTN_FOCUS_BG
	style.border_color = Constants.COLOR_BTN_BORDER_FOCUS
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

## Apply all action button styles to a button
func apply_action_button_styles(button: Button, accent_color: Color) -> void:
	button.add_theme_stylebox_override("normal", action_button_normal(accent_color))
	button.add_theme_stylebox_override("hover", action_button_hover(accent_color))
	button.add_theme_stylebox_override("pressed", action_button_pressed(accent_color))
	button.add_theme_stylebox_override("disabled", action_button_disabled())
	button.add_theme_stylebox_override("focus", action_button_focus())
	# Apply font colors
	apply_button_font_colors(button)
