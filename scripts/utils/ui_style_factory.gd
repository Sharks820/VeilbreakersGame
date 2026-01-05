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

## Text colors
const TEXT_WHITE := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_GRAY := Color(0.7, 0.7, 0.7, 1.0)
const TEXT_DIM := Color(0.5, 0.5, 0.5, 1.0)
const TEXT_DAMAGE := Color(1.0, 0.3, 0.3, 1.0)
const TEXT_HEAL := Color(0.3, 1.0, 0.3, 1.0)
const TEXT_CRITICAL := Color(1.0, 0.8, 0.2, 1.0)
const TEXT_MISS := Color(0.6, 0.6, 0.6, 1.0)
const TEXT_MP := Color(0.4, 0.6, 1.0, 1.0)

## Status effect colors
const STATUS_POISON := Color(0.4, 0.8, 0.2, 1.0)
const STATUS_BURN := Color(1.0, 0.5, 0.2, 1.0)
const STATUS_FREEZE := Color(0.4, 0.8, 1.0, 1.0)
const STATUS_PARALYSIS := Color(1.0, 1.0, 0.3, 1.0)
const STATUS_BLEED := Color(0.8, 0.1, 0.1, 1.0)
const STATUS_REGEN := Color(0.3, 1.0, 0.5, 1.0)
const STATUS_BUFF := Color(0.3, 0.8, 1.0, 1.0)
const STATUS_DEBUFF := Color(0.8, 0.3, 0.8, 1.0)

## Brand colors (matching BrandSystem)
const BRAND_SAVAGE := Color(0.9, 0.2, 0.2, 1.0)
const BRAND_IRON := Color(0.6, 0.6, 0.7, 1.0)
const BRAND_VENOM := Color(0.4, 0.8, 0.3, 1.0)
const BRAND_SURGE := Color(1.0, 0.9, 0.3, 1.0)
const BRAND_DREAD := Color(0.5, 0.2, 0.6, 1.0)
const BRAND_LEECH := Color(0.6, 0.2, 0.3, 1.0)

## Effectiveness colors
const EFFECTIVE_STRONG := Color(0.3, 1.0, 0.3, 1.0)
const EFFECTIVE_WEAK := Color(1.0, 0.4, 0.4, 1.0)
const EFFECTIVE_NEUTRAL := Color(1.0, 1.0, 1.0, 1.0)

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

## Create tooltip style (default)
static func create_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	return style

## Create enemy tooltip style (red tint) - margins 12/12/10/10
static func create_enemy_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	style.border_color = Color(0.6, 0.3, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

## Create ally tooltip style (green tint) - margins 12/12/10/10
static func create_ally_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.08, 0.95)
	style.border_color = Color(0.3, 0.6, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
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

# =============================================================================
# BUTTON STATE SETS (v0.98 - Consolidate 17+ duplicate patterns)
# =============================================================================

## Create all button states with an accent color (for skill/action buttons)
static func create_accent_button_states(accent_color: Color) -> Dictionary:
	return {
		"normal": create_button_state(Color(0.12, 0.12, 0.15, 0.95), accent_color),
		"hover": create_button_state(Color(0.18, 0.18, 0.22, 0.98), accent_color.lightened(0.1)),
		"pressed": create_button_state(accent_color.darkened(0.4), accent_color),
		"disabled": create_button_state(Color(0.08, 0.08, 0.1, 0.7), accent_color, 0.5),
		"focus": create_button_state(Color(0.18, 0.14, 0.22, 0.95), accent_color)
	}

## Apply accent button states to a button
static func apply_accent_button_style(button: Button, accent_color: Color) -> void:
	var states := create_accent_button_states(accent_color)
	button.add_theme_stylebox_override("normal", states["normal"])
	button.add_theme_stylebox_override("hover", states["hover"])
	button.add_theme_stylebox_override("pressed", states["pressed"])
	button.add_theme_stylebox_override("disabled", states["disabled"])
	button.add_theme_stylebox_override("focus", states["focus"])

## Create hero card button states (for character select screen)
static func create_hero_card_states(base_color: Color) -> Dictionary:
	return {
		"normal": create_panel_style(base_color.darkened(0.3), base_color, BORDER_WIDTH_NORMAL, CORNER_RADIUS_NORMAL),
		"hover": create_panel_style(base_color.darkened(0.1), base_color.lightened(0.2), BORDER_WIDTH_NORMAL, CORNER_RADIUS_NORMAL),
		"pressed": create_panel_style(base_color.darkened(0.4), base_color, BORDER_WIDTH_THICK, CORNER_RADIUS_NORMAL)
	}

## Apply hero card button states
static func apply_hero_card_style(button: Button, base_color: Color) -> void:
	var states := create_hero_card_states(base_color)
	button.add_theme_stylebox_override("normal", states["normal"])
	button.add_theme_stylebox_override("hover", states["hover"])
	button.add_theme_stylebox_override("pressed", states["pressed"])

# =============================================================================
# CHARACTER PANEL STYLES
# =============================================================================

## Create player character panel style
static func create_player_panel_style() -> StyleBoxFlat:
	return create_panel_style(
		Color(0.06, 0.08, 0.12, 0.95),
		Color(0.3, 0.5, 0.4, 0.8),
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_SMALL,
		CONTENT_MARGIN_SMALL
	)

## Create enemy character panel style
static func create_enemy_panel_style() -> StyleBoxFlat:
	return create_panel_style(
		Color(0.12, 0.06, 0.08, 0.95),
		Color(0.5, 0.3, 0.3, 0.8),
		BORDER_WIDTH_NORMAL,
		CORNER_RADIUS_SMALL,
		CONTENT_MARGIN_SMALL
	)

## Create portrait frame style
static func create_portrait_frame_style(border_color: Color = BORDER_DEFAULT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.border_color = border_color
	style.set_border_width_all(BORDER_WIDTH_NORMAL)
	style.set_corner_radius_all(3)
	return style

# =============================================================================
# FONT SIZE PRESETS (v1.02 - Consolidate 120+ add_theme_font_size_override)
# =============================================================================

const FONT_TINY := 9           # Brand indicators, small badges
const FONT_SMALL := 10         # Secondary info, stat labels
const FONT_CAPTION := 11       # Captions, level labels
const FONT_BODY := 12          # Body text, stat rows
const FONT_NORMAL := 14        # Standard text
const FONT_SUBHEADING := 16    # Subheadings, names
const FONT_HEADING := 18       # Section headers
const FONT_TITLE := 20         # Titles
const FONT_SUBTITLE := 22      # Subtitles
const FONT_LARGE_TITLE := 24   # Dialog titles
const FONT_HUGE := 32          # Victory/defeat text
const FONT_DISPLAY := 36       # Large display text
const FONT_HERO := 42          # Hero name display
const FONT_ARROW := 48         # Navigation arrows

# =============================================================================
# COMMON TEXT COLORS (v1.02 - Consolidate 150+ add_theme_color_override)
# =============================================================================

# UI Colors
const COLOR_PARCHMENT := Color(0.95, 0.9, 0.8)        # Default light text
const COLOR_CREAM := Color(0.9, 0.85, 0.7)            # Warmer light text
const COLOR_SUBTITLE := Color(0.7, 0.65, 0.55)        # Subtitle gray
const COLOR_DIM_LABEL := Color(0.6, 0.6, 0.6)         # Dim label text
const COLOR_MUTED := Color(0.5, 0.45, 0.4)            # Muted decorative
const COLOR_GOLD := Color(1.0, 0.85, 0.4)             # Gold highlights
const COLOR_AGED_GOLD := Color(0.85, 0.7, 0.45)       # Aged gold headers

# Health/Resource Colors
const COLOR_HP_TITLE := Color(0.6, 0.8, 0.6)          # HP title green
const COLOR_HP_VALUE := Color(0.4, 0.9, 0.4)          # HP value bright green
const COLOR_MP_TITLE := Color(0.6, 0.6, 0.8)          # MP title blue
const COLOR_MP_VALUE := Color(0.4, 0.6, 1.0)          # MP value bright blue
const COLOR_ENEMY_HP := Color(0.9, 0.4, 0.4)          # Enemy HP red

# State Colors
const COLOR_LEVEL := Color(0.7, 0.7, 0.7)             # Level text
const COLOR_XP := Color(0.7, 0.9, 0.7)                # XP text
const COLOR_SEPARATOR := Color(0.4, 0.3, 0.35)        # Separator lines
const COLOR_GREEN_SEP := Color(0.3, 0.4, 0.35)        # Green separator

# Enemy/Ally Variant Colors (v1.14)
const COLOR_ENEMY_NAME := Color(0.95, 0.85, 0.8)      # Enemy name (warmer parchment)
const COLOR_ENEMY_HP_LABEL := Color(0.7, 0.6, 0.6)    # Enemy HP label (muted red)
const COLOR_ENEMY_HP_TITLE := Color(0.8, 0.6, 0.6)    # Enemy HP title
const COLOR_ALLY_NAME := Color(0.85, 1.0, 0.9)        # Ally name (green tint)
const COLOR_ALLY_NAME_ALT := Color(0.9, 0.95, 0.9)    # Ally name alternate
const COLOR_ALLY_HP_LABEL := Color(0.65, 0.7, 0.65)   # Ally HP label

# Victory/Defeat Colors (v1.14)
const COLOR_VICTORY_TITLE := Color(1.0, 0.9, 0.3)     # Victory screen title
const COLOR_LEVEL_UP := Color(1.0, 1.0, 0.3)          # Level up yellow
const COLOR_STAT_GAIN := Color(0.5, 1.0, 0.5)         # Stat gain green
const COLOR_DEFEAT_TITLE := Color(0.9, 0.3, 0.3)      # Defeat title red
const COLOR_DEFEAT_MSG := Color(0.8, 0.7, 0.7)        # Defeat message muted
const COLOR_BUTTON_LIGHT := Color(0.95, 0.9, 0.9)     # Light button text

# Tooltip/Panel Colors (v1.14)
const COLOR_TOOLTIP_TITLE := Color(0.7, 0.9, 0.75)    # Tooltip title green
const COLOR_TOOLTIP_NAME := Color(0.9, 0.95, 0.85)    # Tooltip name
const COLOR_PANEL_TITLE_RED := Color(0.9, 0.7, 0.7)   # Red panel title
const COLOR_CAPTURE_TITLE := Color(1.0, 0.85, 0.3)    # Capture popup title
const COLOR_CAPTURE_PURPLE := Color(0.8, 0.4, 1.0)    # Capture purple
const COLOR_MP_VALUE_ALT := Color(0.5, 0.7, 1.0)      # Alt MP value
const COLOR_STATS_HEADER := Color(0.7, 0.85, 1.0)     # Stats header blue
const COLOR_ITEM_TEXT := Color(0.8, 0.75, 0.65)       # Item text warm
const COLOR_PARCHMENT_WARM := Color(0.85, 0.8, 0.7)   # Warm parchment variant
const COLOR_BUTTON_GOLD := Color(1.0, 0.9, 0.7)       # Gold button text
const COLOR_DESC_MUTED := Color(0.7, 0.65, 0.6)       # Description muted
const COLOR_DEAD := Color(0.8, 0.2, 0.2, 0.9)         # Dead character indicator
const COLOR_LOG_HANDLE := Color(0.6, 0.6, 0.7)        # Combat log handle

# =============================================================================
# LABEL CREATION HELPERS (v1.02 - Consolidate 100+ Label.new() patterns)
# =============================================================================

## Create a styled label with font size and color
static func create_label(
	text: String,
	font_size: int = FONT_NORMAL,
	color: Color = COLOR_PARCHMENT
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

## Create a styled label with outline
static func create_outlined_label(
	text: String,
	font_size: int = FONT_NORMAL,
	color: Color = COLOR_PARCHMENT,
	outline_color: Color = Color(0.1, 0.1, 0.1)
) -> Label:
	var label := create_label(text, font_size, color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", 2)
	return label

## Create a title label (large, gold)
static func create_title_label(text: String, font_size: int = FONT_LARGE_TITLE) -> Label:
	return create_label(text, font_size, COLOR_CREAM)

## Create a subtitle label (smaller, muted)
static func create_subtitle_label(text: String, font_size: int = FONT_CAPTION) -> Label:
	return create_label(text, font_size, COLOR_SUBTITLE)

## Create a header label (medium, highlighted)
static func create_header_label(text: String, font_size: int = FONT_HEADING) -> Label:
	return create_label(text, font_size, COLOR_AGED_GOLD)

## Create a stat name label (small, dim)
static func create_stat_name_label(text: String) -> Label:
	return create_label(text, FONT_SMALL, COLOR_DIM_LABEL)

## Create a stat value label (colored)
static func create_stat_value_label(text: String, color: Color = Color.WHITE) -> Label:
	return create_label(text, FONT_SMALL, color)

## Create an HP label (value + title style)
static func create_hp_label_pair(title_text: String = "HP", value_text: String = "") -> Dictionary:
	return {
		"title": create_label(title_text, FONT_CAPTION, COLOR_HP_TITLE),
		"value": create_label(value_text, FONT_CAPTION, COLOR_HP_VALUE)
	}

## Create an MP label (value + title style)
static func create_mp_label_pair(title_text: String = "MP", value_text: String = "") -> Dictionary:
	return {
		"title": create_label(title_text, FONT_CAPTION, COLOR_MP_TITLE),
		"value": create_label(value_text, FONT_CAPTION, COLOR_MP_VALUE)
	}

## Create a character name label
static func create_name_label(text: String, is_enemy: bool = false) -> Label:
	var color := COLOR_PARCHMENT if not is_enemy else Color(1.0, 0.85, 0.7)
	return create_label(text, FONT_SUBHEADING, color)

## Create a level label
static func create_level_label(level: int) -> Label:
	return create_label("Lv. %d" % level, FONT_CAPTION, COLOR_LEVEL)

## Create a brand label with brand color
static func create_brand_label(brand_name: String, brand_color: Color, font_size: int = FONT_TINY) -> Label:
	return create_label(brand_name, font_size, brand_color)

# =============================================================================
# RICH TEXT LABEL HELPERS
# =============================================================================

## Create a styled RichTextLabel
static func create_rich_text_label(
	font_size: int = FONT_BODY,
	color: Color = COLOR_PARCHMENT,
	scroll_active: bool = false
) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = not scroll_active
	rtl.scroll_active = scroll_active
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_color_override("default_color", color)
	return rtl

# =============================================================================
# SEPARATOR HELPERS
# =============================================================================

## Create a styled HSeparator
static func create_separator(color: Color = COLOR_SEPARATOR) -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", color)
	return sep

## Create a styled VSeparator
static func create_vseparator(color: Color = COLOR_SEPARATOR) -> VSeparator:
	var sep := VSeparator.new()
	sep.add_theme_color_override("separator", color)
	return sep

# =============================================================================
# APPLY LABEL STYLE HELPERS
# =============================================================================

## Apply font size and color to existing label
static func style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

## Apply outline to existing label
static func add_label_outline(label: Label, outline_color: Color, outline_size: int = 2) -> void:
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", outline_size)

## Apply gold style to label (for important text)
static func style_label_gold(label: Label, font_size: int = FONT_HEADING) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.1))
	label.add_theme_constant_override("outline_size", 2)

# =============================================================================
# CENTERED LABEL HELPERS (v1.03 - Consolidate 32+ alignment patterns)
# =============================================================================

## Create a centered label
static func create_centered_label(
	text: String,
	font_size: int = FONT_NORMAL,
	color: Color = COLOR_PARCHMENT
) -> Label:
	var label := create_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

## Create a centered title label
static func create_centered_title(text: String, font_size: int = FONT_LARGE_TITLE) -> Label:
	var label := create_label(text, font_size, COLOR_CREAM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

## Create a centered header label
static func create_centered_header(text: String, font_size: int = FONT_HEADING) -> Label:
	var label := create_label(text, font_size, COLOR_AGED_GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

## Create a right-aligned stat value
static func create_right_aligned_value(text: String, color: Color = Color.WHITE) -> Label:
	var label := create_label(text, FONT_BODY, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return label

## Apply center alignment to existing label
static func center_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

## Apply both center alignments to label (for overlays)
static func center_label_full(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

# =============================================================================
# ADDITIONAL COLOR CONSTANTS (v1.03 - More common colors found in codebase)
# =============================================================================

# Disabled/inactive states
const COLOR_DISABLED := Color(0.5, 0.5, 0.5, 0.8)     # Disabled button/text
const COLOR_INACTIVE := Color(0.5, 0.5, 0.5, 0.7)     # Inactive elements

# Alert colors
const COLOR_WARNING := Color(1.0, 0.7, 0.3)           # Warning orange
const COLOR_ERROR := Color(1.0, 0.4, 0.4)             # Error red
const COLOR_SUCCESS := Color(0.4, 1.0, 0.4)           # Success green

# Combat log colors
const COLOR_DAMAGE := Color(1.0, 0.3, 0.3)            # Damage text
const COLOR_HEAL := Color(0.3, 1.0, 0.3)              # Heal text
const COLOR_MISS := Color(0.6, 0.6, 0.6)              # Miss text
const COLOR_CRITICAL := Color(1.0, 0.8, 0.2)          # Critical hit

# Brand indicator colors (for labels, not brand system)
const COLOR_BRAND_TITLE := Color(0.6, 0.6, 0.6)       # "Brand:" label
const COLOR_CORRUPTION := Color(0.6, 0.2, 0.7)        # Corruption value

# Panel accent colors
const COLOR_ALLY_ACCENT := Color(0.3, 0.6, 0.4)       # Ally panel border
const COLOR_ENEMY_ACCENT := Color(0.6, 0.3, 0.3)      # Enemy panel border

# =============================================================================
# STAT COLOR DICTIONARY (v1.03 - For stat display consistency)
# =============================================================================

const STAT_COLORS := {
	"hp": Color(0.4, 0.9, 0.4),
	"max_hp": Color(0.4, 0.9, 0.4),
	"mp": Color(0.4, 0.6, 1.0),
	"max_mp": Color(0.4, 0.6, 1.0),
	"attack": Color(1.0, 0.5, 0.4),
	"atk": Color(1.0, 0.5, 0.4),
	"defense": Color(0.6, 0.7, 0.9),
	"def": Color(0.6, 0.7, 0.9),
	"magic": Color(0.8, 0.5, 1.0),
	"mag": Color(0.8, 0.5, 1.0),
	"resistance": Color(0.7, 0.6, 0.9),
	"res": Color(0.7, 0.6, 0.9),
	"speed": Color(0.5, 0.9, 0.8),
	"spd": Color(0.5, 0.9, 0.8),
	"luck": Color(1.0, 0.85, 0.4),
	"luk": Color(1.0, 0.85, 0.4)
}

## Get stat color by name (case-insensitive)
static func get_stat_color(stat_name: String) -> Color:
	return STAT_COLORS.get(stat_name.to_lower(), Color.WHITE)

# =============================================================================
# CONTAINER HELPERS (v1.03 - Common container setup patterns)
# =============================================================================

## Create a VBoxContainer with standard settings
static func create_vbox(separation: int = 4) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", separation)
	return vbox

## Create an HBoxContainer with standard settings
static func create_hbox(separation: int = 4) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", separation)
	return hbox

## Create a MarginContainer with all margins set
static func create_margin_container(margin: int = 8) -> MarginContainer:
	var container := MarginContainer.new()
	container.add_theme_constant_override("margin_left", margin)
	container.add_theme_constant_override("margin_top", margin)
	container.add_theme_constant_override("margin_right", margin)
	container.add_theme_constant_override("margin_bottom", margin)
	return container

## Create a PanelContainer with dark style
static func create_styled_panel(style: StyleBoxFlat = null) -> PanelContainer:
	var panel := PanelContainer.new()
	if style:
		panel.add_theme_stylebox_override("panel", style)
	else:
		panel.add_theme_stylebox_override("panel", create_dark_panel())
	return panel

# =============================================================================
# PROGRESS BAR HELPERS (v1.03 - Consolidate 14+ ProgressBar patterns)
# =============================================================================

## Create a styled HP bar
static func create_hp_bar(min_size: Vector2 = Vector2(80, 8)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.add_theme_stylebox_override("background", create_hp_bar_bg())
	bar.add_theme_stylebox_override("fill", create_hp_bar_fill())
	return bar

## Create a styled MP bar
static func create_mp_bar(min_size: Vector2 = Vector2(60, 6)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.add_theme_stylebox_override("background", create_mp_bar_bg())
	bar.add_theme_stylebox_override("fill", create_mp_bar_fill())
	return bar

## Create an enemy HP bar (red fill)
static func create_enemy_hp_bar(min_size: Vector2 = Vector2(80, 8)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.add_theme_stylebox_override("background", create_hp_bar_bg())
	bar.add_theme_stylebox_override("fill", create_enemy_hp_bar_fill())
	return bar

## Create corruption bar fill style (purple)
static func create_corruption_bar_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.6, 0.2, 0.7, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create corruption bar background style
static func create_corruption_bar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.12, 0.9)
	style.set_corner_radius_all(2)
	return style

## Create a corruption bar (purple)
static func create_corruption_bar(min_size: Vector2 = Vector2(60, 4)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.add_theme_stylebox_override("background", create_corruption_bar_bg())
	bar.add_theme_stylebox_override("fill", create_corruption_bar_fill())
	return bar

## Create XP bar fill style (gold)
static func create_xp_bar_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.75, 0.3, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create XP bar background style
static func create_xp_bar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.05, 0.9)
	style.set_corner_radius_all(2)
	return style

## Create an XP bar (gold)
static func create_xp_bar(min_size: Vector2 = Vector2(100, 6)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.add_theme_stylebox_override("background", create_xp_bar_bg())
	bar.add_theme_stylebox_override("fill", create_xp_bar_fill())
	return bar

# =============================================================================
# TEXTURE RECT HELPERS (v1.03 - Consolidate 14+ TextureRect patterns)
# =============================================================================

## Create a portrait TextureRect (ignore size, stretch)
static func create_portrait(size: Vector2 = Vector2(64, 64)) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = size
	return rect

## Create an icon TextureRect (smaller, for turn order etc.)
static func create_icon(size: Vector2 = Vector2(32, 32)) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = size
	return rect

## Create a background TextureRect (fills container)
static func create_background_texture() -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.anchors_preset = Control.PRESET_FULL_RECT
	return rect

## Create a sprite TextureRect (proportional width)
static func create_sprite_rect(size: Vector2 = Vector2(48, 48)) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.custom_minimum_size = size
	return rect

# =============================================================================
# MOUSE FILTER HELPERS (v1.03 - Consolidate 48+ mouse_filter patterns)
# =============================================================================

## Set mouse filter to PASS (allows parent to receive events)
static func set_mouse_pass(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS

## Set mouse filter to STOP (blocks events from passing through)
static func set_mouse_stop(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_STOP

## Set mouse filter to IGNORE (completely ignores mouse events)
static func set_mouse_ignore(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Apply PASS filter to multiple controls (common pattern for tooltip internals)
static func set_all_mouse_pass(controls: Array) -> void:
	for control in controls:
		if control is Control:
			control.mouse_filter = Control.MOUSE_FILTER_PASS

## Create a control with IGNORE filter (for overlays, flashes)
static func create_overlay_rect() -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchors_preset = Control.PRESET_FULL_RECT
	return rect

# =============================================================================
# BUTTON CREATION HELPERS (v1.03 - Consolidate 9+ Button patterns)
# =============================================================================

## Create a styled button with text
static func create_button(
	text: String,
	font_size: int = FONT_SUBHEADING,
	min_size: Vector2 = Vector2(100, 40)
) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", COLOR_PARCHMENT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", COLOR_DISABLED)
	apply_button_style(button)
	return button

## Create a menu button (for pause menu, main menu)
static func create_menu_button(text: String) -> Button:
	return create_button(text, FONT_SUBHEADING, Vector2(200, 50))

## Create a small action button
static func create_action_button(text: String) -> Button:
	return create_button(text, FONT_NORMAL, Vector2(80, 32))

## Create a continue/confirm button
static func create_continue_button(text: String = "Continue") -> Button:
	var button := create_button(text, FONT_TITLE, Vector2(150, 45))
	button.add_theme_color_override("font_color", COLOR_CREAM)
	return button

# =============================================================================
# COMMON LAYOUT PATTERNS (v1.03)
# =============================================================================

## Create a horizontal stat row (name: value)
static func create_stat_row(name_text: String, value_text: String, value_color: Color = Color.WHITE) -> HBoxContainer:
	var hbox := create_hbox(8)
	var name_label := create_stat_name_label(name_text + ":")
	var value_label := create_stat_value_label(value_text, value_color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	hbox.add_child(value_label)
	return hbox

## Create character info header (name + level)
static func create_character_header(name_text: String, level: int, is_enemy: bool = false) -> VBoxContainer:
	var vbox := create_vbox(2)
	var name_label := create_name_label(name_text, is_enemy)
	var level_label := create_level_label(level)
	vbox.add_child(name_label)
	vbox.add_child(level_label)
	return vbox

# =============================================================================
# SIZE FLAGS HELPERS (v1.03 - Consolidate 20+ size_flags patterns)
# =============================================================================

## Set control to expand horizontally
static func expand_horizontal(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

## Set control to expand vertically
static func expand_vertical(control: Control) -> void:
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL

## Set control to expand in both directions
static func expand_both(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL

## Create a spacer control (expands to fill space)
static func create_spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer

## Create a vertical spacer
static func create_vspacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer

# =============================================================================
# SCROLLBAR STYLES (v1.15 - Combat log scrollbar patterns)
# =============================================================================

## Create scrollbar grabber style
static func create_scrollbar_grabber() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.45, 0.4, 0.8)
	style.set_corner_radius_all(4)
	return style

## Create scrollbar background style
static func create_scrollbar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.1, 0.6)
	style.set_corner_radius_all(4)
	return style

## Apply scrollbar styles to a scroll container
static func apply_scrollbar_style(scroll_container: ScrollContainer) -> void:
	var scrollbar := scroll_container.get_v_scroll_bar()
	if scrollbar:
		scrollbar.custom_minimum_size.x = 8
		var grabber := create_scrollbar_grabber()
		scrollbar.add_theme_stylebox_override("grabber", grabber)
		scrollbar.add_theme_stylebox_override("grabber_highlight", grabber)
		scrollbar.add_theme_stylebox_override("grabber_pressed", grabber)
		scrollbar.add_theme_stylebox_override("scroll", create_scrollbar_bg())

# =============================================================================
# VICTORY/DEFEAT PANEL STYLES (v1.15)
# =============================================================================

## Create victory screen outer panel style (golden amber border)
static func create_victory_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.98)
	style.border_color = Color(0.75, 0.55, 0.25, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	return style

## Create victory screen inner panel style
static func create_victory_inner_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	style.border_color = Color(0.4, 0.3, 0.15, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	return style

## Create defeat screen panel style (red border)
static func create_defeat_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.06, 0.06, 0.98)
	style.border_color = Color(0.7, 0.2, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	return style

# =============================================================================
# VICTORY/DEFEAT BUTTON STYLES (v1.15)
# =============================================================================

## Create victory button normal state
static func create_victory_button_normal() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.98)
	style.border_color = Color(0.65, 0.5, 0.25, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Create victory button hover state
static func create_victory_button_hover() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.1, 0.98)
	style.border_color = Color(0.9, 0.7, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Create victory button pressed state
static func create_victory_button_pressed() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.2, 0.12, 0.98)
	style.border_color = Color(1.0, 0.8, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Apply victory button style to a button
static func apply_victory_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_victory_button_normal())
	button.add_theme_stylebox_override("hover", create_victory_button_hover())
	button.add_theme_stylebox_override("pressed", create_victory_button_pressed())

## Create defeat button normal state (red theme)
static func create_defeat_button_normal() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.15, 0.15, 0.95)
	style.border_color = Color(0.6, 0.3, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Create defeat button hover state
static func create_defeat_button_hover() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.2, 0.2, 0.98)
	style.border_color = Color(0.8, 0.4, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Apply defeat button style to a button
static func apply_defeat_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_defeat_button_normal())
	button.add_theme_stylebox_override("hover", create_defeat_button_hover())

# =============================================================================
# LEVEL UP POPUP STYLES (v1.15)
# =============================================================================

## Create level up popup style (golden border)
static func create_level_up_popup_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.05, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style

## Create XP bar row style (dark green)
static func create_xp_row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.05, 0.8)
	style.border_color = Color(0.3, 0.5, 0.3, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

# =============================================================================
# CAPTURE POPUP STYLES (v1.15)
# =============================================================================

## Create capture popup style (blue with gold border)
static func create_capture_popup_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.3, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	return style

# =============================================================================
# TURN ORDER INDICATOR STYLES (v1.15)
# =============================================================================

## Create turn order indicator style (current turn - yellow border)
static func create_turn_order_current() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

## Create turn order indicator style (upcoming ally - green border)
static func create_turn_order_ally() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	style.border_color = Color(0.4, 0.7, 0.5, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

## Create turn order indicator style (upcoming enemy - red border)
static func create_turn_order_enemy() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	style.border_color = Color(0.7, 0.4, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

# =============================================================================
# SIDEBAR PANEL STYLES (v1.15 - Party/Enemy sidebar specific)
# =============================================================================

## Create party sidebar card style
static func create_party_sidebar_card() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.9)
	style.border_color = Color(0.3, 0.5, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

## Create enemy sidebar card style
static func create_enemy_sidebar_card() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	style.border_color = Color(0.5, 0.3, 0.3, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

## Create party sidebar header style (bright green border)
static func create_party_sidebar_header() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.2, 0.95)
	style.border_color = Color(0.3, 0.8, 0.5, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	return style

## Create enemy sidebar header style (red border)
static func create_enemy_sidebar_header() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.1, 0.95)
	style.border_color = Color(0.8, 0.3, 0.3, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	return style

## Create portrait frame style for sidebars
static func create_sidebar_portrait_frame(is_enemy: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if is_enemy:
		style.bg_color = Color(0.2, 0.12, 0.12, 1.0)
		style.border_color = Color(0.6, 0.35, 0.35, 1.0)
	else:
		style.bg_color = Color(0.15, 0.18, 0.2, 1.0)
		style.border_color = Color(0.4, 0.5, 0.45, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

# =============================================================================
# BRAND INDICATOR STYLES (v1.15)
# =============================================================================

## Create brand indicator pill style
static func create_brand_indicator(brand_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = brand_color
	style.border_color = brand_color.lightened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

# =============================================================================
# SUCCESS/FAILURE POPUP STYLES (v1.15)
# =============================================================================

## Create success popup style (green)
static func create_success_popup_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.2, 0.1, 0.95)
	style.border_color = Color(0.4, 1.0, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style

## Create failure popup style (red)
static func create_failure_popup_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.1, 0.95)
	style.border_color = Color(1.0, 0.4, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style

# =============================================================================
# ACTION BUTTON STYLES (v1.16 - Skill/Item action buttons with accent colors)
# =============================================================================

## Create action button normal style with accent color and shadow
static func create_action_button_normal(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_color = accent_color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	return style

## Create action button hover style with glow effect
static func create_action_button_hover(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22, 0.98)
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = accent_color.darkened(0.5)
	style.shadow_color.a = 0.6
	style.shadow_size = 8
	style.shadow_offset = Vector2.ZERO
	return style

## Create action button pressed style
static func create_action_button_pressed(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent_color.darkened(0.4)
	style.border_color = accent_color.lightened(0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

## Create action button disabled style
static func create_action_button_disabled() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
	style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

## Create action button focus style
static func create_action_button_focus() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.22, 0.95)
	style.border_color = Color(0.7, 0.55, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

## Apply full action button styling with accent color
static func apply_action_button_style(button: Button, accent_color: Color) -> void:
	button.add_theme_stylebox_override("normal", create_action_button_normal(accent_color))
	button.add_theme_stylebox_override("hover", create_action_button_hover(accent_color))
	button.add_theme_stylebox_override("pressed", create_action_button_pressed(accent_color))
	button.add_theme_stylebox_override("disabled", create_action_button_disabled())
	button.add_theme_stylebox_override("focus", create_action_button_focus())
	button.add_theme_color_override("font_color", COLOR_PARCHMENT)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.85))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	button.add_theme_font_size_override("font_size", FONT_SUBHEADING)

# =============================================================================
# STATUS EFFECT ICON STYLES (v1.16)
# =============================================================================

## Create status effect buff icon container style (green)
static func create_status_buff_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.3, 0.1, 0.8)
	style.border_color = Color(0.3, 0.7, 0.3, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

## Create status effect debuff icon container style (red)
static func create_status_debuff_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.1, 0.1, 0.8)
	style.border_color = Color(0.7, 0.3, 0.3, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

# =============================================================================
# PARTY MEMBER PANEL STYLES (v1.16 - Target selection panels)
# =============================================================================

## Create party member panel style (green-tinted border)
static func create_party_member_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.border_color = Color(0.3, 0.25, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

## Create party member portrait frame style
static func create_party_member_portrait() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style.border_color = Color(0.4, 0.35, 0.5, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style

## Create enemy panel style for target selection (red-tinted)
static func create_enemy_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.85)
	style.border_color = Color(0.5, 0.25, 0.25, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

# =============================================================================
# COMPACT SIDEBAR PANEL STYLES (v1.16 - With content margins)
# =============================================================================

## Create compact party sidebar panel with margins
static func create_party_sidebar_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.9)
	style.border_color = Color(0.3, 0.5, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

## Create compact enemy sidebar panel with margins
static func create_enemy_sidebar_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	style.border_color = Color(0.5, 0.3, 0.3, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

# =============================================================================
# TURN ORDER DISPLAY STYLES (v1.16 - Dynamic styles)
# =============================================================================

## Create turn order indicator for current turn (bright yellow)
static func create_turn_order_current_dynamic() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	style.border_color = Color.YELLOW
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

## Create turn order indicator for ally (green, smaller border)
static func create_turn_order_ally_dynamic() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.1, 0.9)
	style.border_color = Color(0.3, 0.9, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

## Create turn order indicator for enemy (red, smaller border)
static func create_turn_order_enemy_dynamic() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	style.border_color = Color(0.9, 0.3, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

# =============================================================================
# VICTORY PANEL WITH SHADOW (v1.16)
# =============================================================================

## Create victory panel style with shadow effect
static func create_victory_panel_with_shadow() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.98)
	style.border_color = Color(0.75, 0.55, 0.25, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.6, 0.4, 0.1, 0.6)
	style.shadow_size = 25
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	return style

## Create defeat panel style with shadow effect
static func create_defeat_panel_with_shadow() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.06, 0.06, 0.98)
	style.border_color = Color(0.7, 0.2, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.5, 0.1, 0.1, 0.4)
	style.shadow_size = 20
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	return style

## Create victory button hover with shadow
static func create_victory_button_hover_shadow() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.1, 0.98)
	style.border_color = Color(0.9, 0.7, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.7, 0.5, 0.2, 0.5)
	style.shadow_size = 10
	return style

## Apply victory button style with shadow on hover
static func apply_victory_button_style_with_shadow(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_victory_button_normal())
	button.add_theme_stylebox_override("hover", create_victory_button_hover_shadow())
	button.add_theme_stylebox_override("pressed", create_victory_button_pressed())
	button.add_theme_font_size_override("font_size", FONT_TITLE)
	button.add_theme_color_override("font_color", COLOR_BUTTON_GOLD)

## Create defeat button hover with shadow
static func create_defeat_button_hover_shadow() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.2, 0.2, 0.98)
	style.border_color = Color(0.8, 0.4, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.6, 0.2, 0.2, 0.5)
	style.shadow_size = 8
	return style

## Apply defeat button style with shadow
static func apply_defeat_button_style_with_shadow(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_defeat_button_normal())
	button.add_theme_stylebox_override("hover", create_defeat_button_hover_shadow())
	button.add_theme_stylebox_override("pressed", create_defeat_button_hover_shadow())
	button.add_theme_font_size_override("font_size", FONT_SUBHEADING)
	button.add_theme_color_override("font_color", COLOR_BUTTON_LIGHT)

# =============================================================================
# CAPTURE POPUP STYLES (v1.16 - Larger margins)
# =============================================================================

## Create capture success popup style (large margins)
static func create_capture_success_popup() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.2, 0.1, 0.95)
	style.border_color = Color(0.4, 1.0, 0.4, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	return style

## Create capture failure popup style (large margins)
static func create_capture_failure_popup() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.1, 0.95)
	style.border_color = Color(1.0, 0.4, 0.4, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	return style

# =============================================================================
# XP BAR STYLES (v1.16 - Victory screen golden style)
# =============================================================================

## Create golden XP bar fill for victory screen
static func create_victory_xp_bar_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.65, 0.25, 1.0)
	style.set_corner_radius_all(4)
	return style

## Create golden XP bar background for victory screen
static func create_victory_xp_bar_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
	style.border_color = Color(0.4, 0.3, 0.15, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

## Create level up popup style with specific margins
static func create_level_up_popup_compact() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.05, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

# =============================================================================
# CHARACTER SELECT STYLES (v1.16)
# =============================================================================

## Create character select main panel style
static func create_char_select_panel(margin: int = 15) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09, 0.95)
	style.border_color = Color(0.25, 0.2, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(margin)
	return style

## Create hero card style with class-based accent
static func create_hero_card_style(class_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = class_color.darkened(0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

## Create hero card portrait frame style
static func create_hero_portrait_frame(class_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.14)
	style.border_color = class_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

## Create hero display backdrop (semi-transparent)
static func create_hero_display_backdrop() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.7)
	style.set_corner_radius_all(16)
	return style

## Create hero name overlay panel
static func create_hero_name_overlay() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.04, 0.9)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	return style

## Create monster showcase card style
static func create_monster_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.border_color = Color(0.3, 0.25, 0.35, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

## Create VERA panel style (purple glowing)
static func create_vera_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.06, 0.98)
	style.border_color = Color(0.5, 0.3, 0.6, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.4, 0.2, 0.5, 0.4)
	style.shadow_size = 10
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	return style

## Create VERA portrait frame (circular)
static func create_vera_portrait_frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.1)
	style.border_color = Color(0.6, 0.4, 0.7)
	style.set_border_width_all(3)
	style.set_corner_radius_all(45)  # Circular
	style.shadow_color = Color(0.5, 0.3, 0.6, 0.5)
	style.shadow_size = 8
	return style

## Create styled button normal state with custom color
static func create_color_button_normal(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.3)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Create styled button hover state with custom color
static func create_color_button_hover(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.1)
	style.border_color = color.lightened(0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = color
	style.shadow_color.a = 0.4
	style.shadow_size = 8
	return style

## Create styled button pressed state with custom color
static func create_color_button_pressed(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Apply styled button with custom color
static func apply_color_button_style(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("normal", create_color_button_normal(color))
	button.add_theme_stylebox_override("hover", create_color_button_hover(color))
	button.add_theme_stylebox_override("pressed", create_color_button_pressed(color))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)

## Create selected hero card style (with glow)
static func create_hero_card_selected(class_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.16, 0.98)
	style.border_color = class_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_color = class_color
	style.shadow_color.a = 0.5
	style.shadow_size = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

## Create normal (unselected) hero card style
static func create_hero_card_normal(class_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = class_color.darkened(0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_size = 0
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

## Create hovered hero card style
static func create_hero_card_hovered(class_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.14, 0.98)
	style.border_color = class_color.darkened(0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_size = 0
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

## Create confirmation popup style
static func create_confirmation_popup_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09, 0.98)
	style.border_color = Color(0.5, 0.4, 0.6, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.3, 0.2, 0.4, 0.6)
	style.shadow_size = 20
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	return style

# =============================================================================
# BATTLE ARENA SIDEBAR STYLES (v1.16)
# =============================================================================

## Create party sidebar container style (green tint)
static func create_arena_party_sidebar() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	style.border_color = Color(0.25, 0.4, 0.35, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	return style

## Create party member slot style (green border)
static func create_arena_party_slot() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.18, 0.9)
	style.border_color = Color(0.3, 0.45, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(4)
	return style

## Create ally portrait frame style (green border)
static func create_arena_ally_portrait() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	style.border_color = Color(0.4, 0.5, 0.45, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

## Create enemy sidebar container style (red tint)
static func create_arena_enemy_sidebar() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.08, 0.08, 0.92)
	style.border_color = Color(0.5, 0.25, 0.25, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	return style

## Create enemy slot style (red border)
static func create_arena_enemy_slot() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.12, 0.9)
	style.border_color = Color(0.5, 0.3, 0.3, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(4)
	return style

## Create enemy portrait frame style (red border)
static func create_arena_enemy_portrait() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.06, 0.06, 1.0)
	style.border_color = Color(0.6, 0.3, 0.3, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

## Create arena HP bar fill style (bright green)
static func create_arena_hp_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.75, 0.3, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create arena HP bar background style
static func create_arena_hp_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create arena MP bar fill style (bright blue)
static func create_arena_mp_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.5, 0.9, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create arena MP bar background style
static func create_arena_mp_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create arena enemy HP bar fill style (red)
static func create_arena_enemy_hp_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.25, 0.2, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create arena enemy HP bar background style
static func create_arena_enemy_hp_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.08, 1.0)
	style.set_corner_radius_all(2)
	return style

# =============================================================================
# PAUSE MENU STYLES (v1.16)
# =============================================================================

## Create pause menu panel style
static func create_pause_menu_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	style.border_color = Color(0.4, 0.35, 0.5, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 20
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	return style

## Create pause menu button normal style
static func create_pause_button_normal() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_color = Color(0.35, 0.3, 0.45, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Create pause menu button hover style
static func create_pause_button_hover() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.16, 0.25, 0.98)
	style.border_color = Color(0.5, 0.45, 0.65, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Create pause menu button pressed style
static func create_pause_button_pressed() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.2, 0.3, 0.98)
	style.border_color = Color(0.6, 0.55, 0.75, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Create pause menu button focus style
static func create_pause_button_focus() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.14, 0.22, 0.95)
	style.border_color = Color(0.6, 0.5, 0.7, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

## Apply pause menu button styling
static func apply_pause_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_pause_button_normal())
	button.add_theme_stylebox_override("hover", create_pause_button_hover())
	button.add_theme_stylebox_override("pressed", create_pause_button_pressed())
	button.add_theme_stylebox_override("focus", create_pause_button_focus())

# =============================================================================
# FLOATING HP BAR STYLES (v1.16) - In-battle floating HP bars above characters
# =============================================================================

## Create floating HP bar fill style (bright green)
static func create_floating_hp_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	style.set_corner_radius_all(2)
	return style

## Create floating HP bar background style (dark with border)
static func create_floating_hp_bg() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.9)
	style.border_color = Color(0.3, 0.25, 0.2, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

## Apply floating HP bar styling
static func apply_floating_hp_bar_style(bar: ProgressBar) -> void:
	bar.add_theme_stylebox_override("fill", create_floating_hp_fill())
	bar.add_theme_stylebox_override("background", create_floating_hp_bg())

# =============================================================================
# VERA TUTORIAL STYLES (v1.16) - VERA AI assistant UI elements
# =============================================================================

## Create VERA tutorial panel style (dark fantasy horror theme)
static func create_vera_tutorial_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.98)
	style.border_color = Color(0.5, 0.35, 0.6, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.3, 0.2, 0.4, 0.5)
	style.shadow_size = 15
	return style

## Create VERA portrait frame (circular)
static func create_vera_portrait_circle() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 1.0)
	style.border_color = Color(0.5, 0.4, 0.6, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(45)
	return style

## Create VERA button normal state
static func create_vera_button_normal() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2, 0.95)
	style.border_color = Color(0.5, 0.4, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

## Create VERA button hover state
static func create_vera_button_hover() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.2, 0.35, 0.98)
	style.border_color = Color(0.7, 0.55, 0.8, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.5, 0.3, 0.6, 0.4)
	style.shadow_size = 6
	return style

## Create VERA button pressed state
static func create_vera_button_pressed() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.28, 0.45, 1.0)
	style.border_color = Color(0.8, 0.65, 0.9, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

## Apply VERA button styling
static func apply_vera_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_vera_button_normal())
	button.add_theme_stylebox_override("hover", create_vera_button_hover())
	button.add_theme_stylebox_override("pressed", create_vera_button_pressed())

## Create golden highlight panel (for tutorials)
static func create_tutorial_highlight() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.9, 0.3, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style
