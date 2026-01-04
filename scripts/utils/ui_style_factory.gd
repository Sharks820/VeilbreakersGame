class_name UIStyleFactory
extends RefCounted
## UIStyleFactory: Centralized factory for creating consistent UI styles.
## Eliminates duplication of StyleBoxFlat creation across UI controllers.

# =============================================================================
# STYLE PRESETS
# =============================================================================

## Standard panel colors
const PANEL_DARK := Color(0.08, 0.08, 0.12, 0.95)
const PANEL_MEDIUM := Color(0.12, 0.12, 0.16, 0.95)
const PANEL_LIGHT := Color(0.15, 0.15, 0.2, 0.9)
const PANEL_TRANSPARENT := Color(0.1, 0.1, 0.15, 0.8)

## Border colors
const BORDER_DEFAULT := Color(0.3, 0.3, 0.4, 1.0)
const BORDER_HIGHLIGHT := Color(0.5, 0.5, 0.6, 1.0)
const BORDER_GOLD := Color(0.8, 0.6, 0.2, 1.0)
const BORDER_RED := Color(0.8, 0.3, 0.3, 1.0)
const BORDER_GREEN := Color(0.3, 0.8, 0.3, 1.0)
const BORDER_BLUE := Color(0.3, 0.5, 0.8, 1.0)

## Button colors
const BUTTON_NORMAL_BG := Color(0.15, 0.15, 0.2, 0.95)
const BUTTON_HOVER_BG := Color(0.2, 0.2, 0.28, 0.95)
const BUTTON_PRESSED_BG := Color(0.12, 0.12, 0.16, 0.95)
const BUTTON_DISABLED_BG := Color(0.1, 0.1, 0.12, 0.6)

## Standard sizes
const BORDER_WIDTH_THIN := 1
const BORDER_WIDTH_NORMAL := 2
const BORDER_WIDTH_THICK := 3
const CORNER_RADIUS_SMALL := 4
const CORNER_RADIUS_NORMAL := 8
const CORNER_RADIUS_LARGE := 12
const CONTENT_MARGIN_SMALL := 8
const CONTENT_MARGIN_NORMAL := 16
const CONTENT_MARGIN_LARGE := 24

# =============================================================================
# PANEL STYLES
# =============================================================================

## Create a standard dark panel style
static func create_dark_panel(
	border_color: Color = BORDER_DEFAULT,
	border_width: int = BORDER_WIDTH_NORMAL,
	corner_radius: int = CORNER_RADIUS_NORMAL,
	content_margin: int = CONTENT_MARGIN_NORMAL
) -> StyleBoxFlat:
	return create_panel_style(PANEL_DARK, border_color, border_width, corner_radius, content_margin)

## Create a transparent panel style
static func create_transparent_panel(
	border_color: Color = BORDER_DEFAULT,
	border_width: int = BORDER_WIDTH_NORMAL,
	corner_radius: int = CORNER_RADIUS_NORMAL,
	content_margin: int = CONTENT_MARGIN_NORMAL
) -> StyleBoxFlat:
	return create_panel_style(PANEL_TRANSPARENT, border_color, border_width, corner_radius, content_margin)

## Create a custom panel style
static func create_panel_style(
	bg_color: Color,
	border_color: Color = BORDER_DEFAULT,
	border_width: int = BORDER_WIDTH_NORMAL,
	corner_radius: int = CORNER_RADIUS_NORMAL,
	content_margin: int = CONTENT_MARGIN_NORMAL
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.set_content_margin_all(content_margin)
	return style

## Create a panel style with separate margin control
static func create_panel_style_margins(
	bg_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	margin_left: int,
	margin_top: int,
	margin_right: int,
	margin_bottom: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = margin_left
	style.content_margin_top = margin_top
	style.content_margin_right = margin_right
	style.content_margin_bottom = margin_bottom
	return style

# =============================================================================
# BUTTON STYLES
# =============================================================================

## Apply standard button styling to a Button node
static func apply_button_style(button: Button,
	normal_color: Color = BUTTON_NORMAL_BG,
	hover_color: Color = BUTTON_HOVER_BG,
	pressed_color: Color = BUTTON_PRESSED_BG,
	disabled_color: Color = BUTTON_DISABLED_BG,
	border_color: Color = BORDER_DEFAULT
) -> void:
	button.add_theme_stylebox_override("normal", create_button_state(normal_color, border_color))
	button.add_theme_stylebox_override("hover", create_button_state(hover_color, border_color))
	button.add_theme_stylebox_override("pressed", create_button_state(pressed_color, border_color))
	button.add_theme_stylebox_override("disabled", create_button_state(disabled_color, border_color, 0.5))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

## Create a single button state style
static func create_button_state(
	bg_color: Color,
	border_color: Color = BORDER_DEFAULT,
	alpha_mult: float = 1.0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var color := bg_color
	color.a *= alpha_mult
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(BORDER_WIDTH_NORMAL)
	style.set_corner_radius_all(CORNER_RADIUS_NORMAL)
	style.set_content_margin_all(CONTENT_MARGIN_SMALL)
	return style

# =============================================================================
# STAT BAR STYLES
# =============================================================================

## Create HP bar background style
static func create_hp_bar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.05, 0.05, 0.9)
	style.border_color = Color(0.4, 0.2, 0.2, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

## Create HP bar fill style (green gradient effect)
static func create_hp_bar_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.7, 0.3, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create MP bar background style
static func create_mp_bar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.9)
	style.border_color = Color(0.2, 0.2, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

## Create MP bar fill style (blue)
static func create_mp_bar_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.4, 0.8, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create enemy HP bar fill style (red)
static func create_enemy_hp_bar_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	style.set_corner_radius_all(2)
	return style

# =============================================================================
# SPECIALTY STYLES
# =============================================================================

## Create tooltip style
static func create_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	return style

## Create combat log style
static func create_combat_log_style() -> StyleBoxFlat:
	return create_panel_style(
		Color(0.05, 0.05, 0.08, 0.85),
		Color(0.25, 0.25, 0.35, 1.0),
		2,
		6,
		10
	)

## Create action bar style (transparent)
static func create_action_bar_style() -> StyleBoxFlat:
	return create_panel_style(
		Color(0.1, 0.1, 0.15, 0.6),
		Color(0.3, 0.3, 0.4, 0.8),
		2,
		8,
		12
	)

## Create sidebar style
static func create_sidebar_style(is_enemy: bool = false) -> StyleBoxFlat:
	if is_enemy:
		return create_panel_style(
			Color(0.12, 0.08, 0.08, 0.9),
			Color(0.5, 0.25, 0.25, 0.8),
			2,
			6,
			8
		)
	else:
		return create_panel_style(
			Color(0.08, 0.1, 0.12, 0.9),
			Color(0.25, 0.4, 0.35, 0.8),
			2,
			6,
			8
		)

# =============================================================================
# APPLY HELPERS
# =============================================================================

## Apply panel style to a PanelContainer or Panel
static func apply_to_panel(panel: Control, style: StyleBoxFlat) -> void:
	if panel is PanelContainer:
		panel.add_theme_stylebox_override("panel", style)
	elif panel is Panel:
		panel.add_theme_stylebox_override("panel", style)

## Apply dark panel style quickly
static func apply_dark_panel(panel: Control) -> void:
	apply_to_panel(panel, create_dark_panel())

## Apply transparent panel style quickly
static func apply_transparent_panel(panel: Control) -> void:
	apply_to_panel(panel, create_transparent_panel())
