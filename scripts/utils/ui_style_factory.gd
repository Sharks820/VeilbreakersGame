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
# GOTHIC DARK FANTASY STYLE CONSTANTS
# =============================================================================

## Gothic panel colors - deep void aesthetics
const GOTHIC_PANEL_VOID := Color(0.03, 0.02, 0.05, 0.96)       # Deepest void
const GOTHIC_PANEL_DARK := Color(0.05, 0.04, 0.07, 0.95)       # Standard dark
const GOTHIC_PANEL_MEDIUM := Color(0.08, 0.06, 0.10, 0.93)     # Slightly lighter
const GOTHIC_PANEL_ALLY := Color(0.04, 0.05, 0.08, 0.95)       # Blue-void tint for allies
const GOTHIC_PANEL_ENEMY := Color(0.08, 0.04, 0.04, 0.95)      # Red-void tint for enemies

## Gothic border colors - rusted iron and blood
const GOTHIC_BORDER_IRON := Color(0.22, 0.18, 0.20, 1.0)       # Dark rusted iron
const GOTHIC_BORDER_IRON_LIGHT := Color(0.35, 0.30, 0.32, 1.0) # Lighter iron
const GOTHIC_BORDER_BLOOD := Color(0.5, 0.12, 0.12, 1.0)       # Dried blood
const GOTHIC_BORDER_VOID := Color(0.15, 0.10, 0.20, 1.0)       # Void purple

## Gothic glow colors - embers and corruption
const GOTHIC_GLOW_EMBER := Color(0.9, 0.25, 0.08, 0.7)         # Ember orange glow
const GOTHIC_GLOW_BLOOD := Color(0.7, 0.1, 0.1, 0.6)           # Blood red glow
const GOTHIC_GLOW_ALLY := Color(0.2, 0.4, 0.7, 0.5)            # Ally blue glow
const GOTHIC_GLOW_VOID := Color(0.4, 0.15, 0.5, 0.5)           # Void purple glow
const GOTHIC_GLOW_ACTIVE := Color(1.0, 0.8, 0.3, 0.6)          # Active turn gold

## Gothic HP/MP bar colors - desaturated, grim
const GOTHIC_HP_FILL := Color(0.65, 0.18, 0.15, 1.0)           # Desaturated blood red
const GOTHIC_HP_BG := Color(0.12, 0.05, 0.05, 0.85)            # Dark blood void
const GOTHIC_HP_LOW := Color(0.8, 0.1, 0.1, 1.0)               # Critical HP pulsing
const GOTHIC_MP_FILL := Color(0.2, 0.35, 0.6, 1.0)             # Desaturated arcane blue
const GOTHIC_MP_BG := Color(0.05, 0.06, 0.12, 0.85)            # Dark arcane void
const GOTHIC_ENEMY_HP_FILL := Color(0.55, 0.12, 0.12, 1.0)     # Enemy - darker red
const GOTHIC_CORRUPTION_FILL := Color(0.45, 0.12, 0.5, 1.0)    # Corruption purple

## Gothic text colors
const GOTHIC_TEXT_BONE := Color(0.85, 0.82, 0.75, 1.0)         # Aged bone white
const GOTHIC_TEXT_BLOOD := Color(0.8, 0.25, 0.2, 1.0)          # Blood red text
const GOTHIC_TEXT_EMBER := Color(1.0, 0.6, 0.2, 1.0)           # Ember highlight

## Gothic sizing
const GOTHIC_BORDER_WIDTH := 4
const GOTHIC_CORNER_LARGE := 14
const GOTHIC_CORNER_SMALL := 6
const GOTHIC_GLOW_SIZE := 8
const GOTHIC_GLOW_SIZE_ACTIVE := 12

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
	return create_panel_style(
		PANEL_TRANSPARENT, border_color, border_width, corner_radius, content_margin
	)


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
static func apply_button_style(
	button: Button,
	normal_color: Color = BUTTON_NORMAL_BG,
	hover_color: Color = BUTTON_HOVER_BG,
	pressed_color: Color = BUTTON_PRESSED_BG,
	disabled_color: Color = BUTTON_DISABLED_BG,
	border_color: Color = BORDER_DEFAULT
) -> void:
	button.add_theme_stylebox_override("normal", create_button_state(normal_color, border_color))
	button.add_theme_stylebox_override("hover", create_button_state(hover_color, border_color))
	button.add_theme_stylebox_override("pressed", create_button_state(pressed_color, border_color))
	button.add_theme_stylebox_override(
		"disabled", create_button_state(disabled_color, border_color, 0.5)
	)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Create a single button state style
static func create_button_state(
	bg_color: Color, border_color: Color = BORDER_DEFAULT, alpha_mult: float = 1.0
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
	return create_panel_style(Color(0.05, 0.05, 0.08, 0.85), Color(0.25, 0.25, 0.35, 1.0), 2, 6, 10)


## Create action bar style (transparent)
static func create_action_bar_style() -> StyleBoxFlat:
	return create_panel_style(Color(0.1, 0.1, 0.15, 0.6), Color(0.3, 0.3, 0.4, 0.8), 2, 8, 12)


## Create sidebar style
static func create_sidebar_style(is_enemy: bool = false) -> StyleBoxFlat:
	if is_enemy:
		return create_panel_style(
			Color(0.12, 0.08, 0.08, 0.9), Color(0.5, 0.25, 0.25, 0.8), 2, 6, 8
		)
	else:
		return create_panel_style(Color(0.08, 0.1, 0.12, 0.9), Color(0.25, 0.4, 0.35, 0.8), 2, 6, 8)


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
		"normal":
		create_panel_style(
			base_color.darkened(0.3), base_color, BORDER_WIDTH_NORMAL, CORNER_RADIUS_NORMAL
		),
		"hover":
		create_panel_style(
			base_color.darkened(0.1),
			base_color.lightened(0.2),
			BORDER_WIDTH_NORMAL,
			CORNER_RADIUS_NORMAL
		),
		"pressed":
		create_panel_style(
			base_color.darkened(0.4), base_color, BORDER_WIDTH_THICK, CORNER_RADIUS_NORMAL
		)
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

const FONT_TINY := 9  # Brand indicators, small badges
const FONT_SMALL := 10  # Secondary info, stat labels
const FONT_CAPTION := 11  # Captions, level labels
const FONT_BODY := 12  # Body text, stat rows
const FONT_NORMAL := 14  # Standard text
const FONT_SUBHEADING := 16  # Subheadings, names
const FONT_HEADING := 18  # Section headers
const FONT_TITLE := 20  # Titles
const FONT_SUBTITLE := 22  # Subtitles
const FONT_LARGE_TITLE := 24  # Dialog titles
const FONT_HUGE := 32  # Victory/defeat text
const FONT_DISPLAY := 36  # Large display text
const FONT_HERO := 42  # Hero name display
const FONT_ARROW := 48  # Navigation arrows

# =============================================================================
# COMMON TEXT COLORS (v1.02 - Consolidate 150+ add_theme_color_override)
# =============================================================================

# UI Colors
const COLOR_PARCHMENT := Color(0.95, 0.9, 0.8)  # Default light text
const COLOR_CREAM := Color(0.9, 0.85, 0.7)  # Warmer light text
const COLOR_SUBTITLE := Color(0.7, 0.65, 0.55)  # Subtitle gray
const COLOR_DIM_LABEL := Color(0.6, 0.6, 0.6)  # Dim label text
const COLOR_MUTED := Color(0.5, 0.45, 0.4)  # Muted decorative
const COLOR_GOLD := Color(1.0, 0.85, 0.4)  # Gold highlights
const COLOR_AGED_GOLD := Color(0.85, 0.7, 0.45)  # Aged gold headers

# Health/Resource Colors
const COLOR_HP_TITLE := Color(0.6, 0.8, 0.6)  # HP title green
const COLOR_HP_VALUE := Color(0.4, 0.9, 0.4)  # HP value bright green
const COLOR_MP_TITLE := Color(0.6, 0.6, 0.8)  # MP title blue
const COLOR_MP_VALUE := Color(0.4, 0.6, 1.0)  # MP value bright blue
const COLOR_ENEMY_HP := Color(0.9, 0.4, 0.4)  # Enemy HP red

# State Colors
const COLOR_LEVEL := Color(0.7, 0.7, 0.7)  # Level text
const COLOR_XP := Color(0.7, 0.9, 0.7)  # XP text
const COLOR_SEPARATOR := Color(0.4, 0.3, 0.35)  # Separator lines
const COLOR_GREEN_SEP := Color(0.3, 0.4, 0.35)  # Green separator

# Enemy/Ally Variant Colors (v1.14)
const COLOR_ENEMY_NAME := Color(0.95, 0.85, 0.8)  # Enemy name (warmer parchment)
const COLOR_ENEMY_HP_LABEL := Color(0.7, 0.6, 0.6)  # Enemy HP label (muted red)
const COLOR_ENEMY_HP_TITLE := Color(0.8, 0.6, 0.6)  # Enemy HP title
const COLOR_ALLY_NAME := Color(0.85, 1.0, 0.9)  # Ally name (green tint)
const COLOR_ALLY_NAME_ALT := Color(0.9, 0.95, 0.9)  # Ally name alternate
const COLOR_ALLY_HP_LABEL := Color(0.65, 0.7, 0.65)  # Ally HP label

# Victory/Defeat Colors (v1.14)
const COLOR_VICTORY_TITLE := Color(1.0, 0.9, 0.3)  # Victory screen title
const COLOR_LEVEL_UP := Color(1.0, 1.0, 0.3)  # Level up yellow
const COLOR_STAT_GAIN := Color(0.5, 1.0, 0.5)  # Stat gain green
const COLOR_DEFEAT_TITLE := Color(0.9, 0.3, 0.3)  # Defeat title red
const COLOR_DEFEAT_MSG := Color(0.8, 0.7, 0.7)  # Defeat message muted
const COLOR_BUTTON_LIGHT := Color(0.95, 0.9, 0.9)  # Light button text

# Tooltip/Panel Colors (v1.14)
const COLOR_TOOLTIP_TITLE := Color(0.7, 0.9, 0.75)  # Tooltip title green
const COLOR_TOOLTIP_NAME := Color(0.9, 0.95, 0.85)  # Tooltip name
const COLOR_PANEL_TITLE_RED := Color(0.9, 0.7, 0.7)  # Red panel title
const COLOR_CAPTURE_TITLE := Color(1.0, 0.85, 0.3)  # Capture popup title
const COLOR_CAPTURE_PURPLE := Color(0.8, 0.4, 1.0)  # Capture purple
const COLOR_MP_VALUE_ALT := Color(0.5, 0.7, 1.0)  # Alt MP value
const COLOR_STATS_HEADER := Color(0.7, 0.85, 1.0)  # Stats header blue
const COLOR_ITEM_TEXT := Color(0.8, 0.75, 0.65)  # Item text warm
const COLOR_PARCHMENT_WARM := Color(0.85, 0.8, 0.7)  # Warm parchment variant
const COLOR_BUTTON_GOLD := Color(1.0, 0.9, 0.7)  # Gold button text
const COLOR_DESC_MUTED := Color(0.7, 0.65, 0.6)  # Description muted
const COLOR_DEAD := Color(0.8, 0.2, 0.2, 0.9)  # Dead character indicator
const COLOR_LOG_HANDLE := Color(0.6, 0.6, 0.7)  # Combat log handle

# =============================================================================
# LABEL CREATION HELPERS (v1.02 - Consolidate 100+ Label.new() patterns)
# =============================================================================


## Create a styled label with font size and color
static func create_label(
	text: String, font_size: int = FONT_NORMAL, color: Color = COLOR_PARCHMENT
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
static func create_brand_label(
	brand_name: String, brand_color: Color, font_size: int = FONT_TINY
) -> Label:
	return create_label(brand_name, font_size, brand_color)


# =============================================================================
# RICH TEXT LABEL HELPERS
# =============================================================================


## Create a styled RichTextLabel
static func create_rich_text_label(
	font_size: int = FONT_BODY, color: Color = COLOR_PARCHMENT, scroll_active: bool = false
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
	text: String, font_size: int = FONT_NORMAL, color: Color = COLOR_PARCHMENT
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
const COLOR_DISABLED := Color(0.5, 0.5, 0.5, 0.8)  # Disabled button/text
const COLOR_INACTIVE := Color(0.5, 0.5, 0.5, 0.7)  # Inactive elements

# Alert colors
const COLOR_WARNING := Color(1.0, 0.7, 0.3)  # Warning orange
const COLOR_ERROR := Color(1.0, 0.4, 0.4)  # Error red
const COLOR_SUCCESS := Color(0.4, 1.0, 0.4)  # Success green

# Combat log colors
const COLOR_DAMAGE := Color(1.0, 0.3, 0.3)  # Damage text
const COLOR_HEAL := Color(0.3, 1.0, 0.3)  # Heal text
const COLOR_MISS := Color(0.6, 0.6, 0.6)  # Miss text
const COLOR_CRITICAL := Color(1.0, 0.8, 0.2)  # Critical hit

# Brand indicator colors (for labels, not brand system)
const COLOR_BRAND_TITLE := Color(0.6, 0.6, 0.6)  # "Brand:" label
const COLOR_CORRUPTION := Color(0.6, 0.2, 0.7)  # Corruption value

# Panel accent colors
const COLOR_ALLY_ACCENT := Color(0.3, 0.6, 0.4)  # Ally panel border
const COLOR_ENEMY_ACCENT := Color(0.6, 0.3, 0.3)  # Enemy panel border

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
# BATTLE CHASERS STYLE BARS (Ornate textured frames)
# =============================================================================

## Path to Battle Chasers HP/MP bar frames asset
const BC_BAR_FRAMES_PATH := "res://assets/ui/battlechasers/hp_mp_bar_frames.png"

## Create a Battle Chasers style HP bar with ornate frame
## Returns a Control containing the frame TextureRect and ProgressBar
static func create_bc_hp_bar(min_size: Vector2 = Vector2(200, 32)) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size

	# Load the bar frames texture
	var frames_tex: Texture2D = load(BC_BAR_FRAMES_PATH)
	if not frames_tex:
		# Fallback to regular HP bar
		var fallback := create_hp_bar(min_size)
		return fallback

	# Create atlas texture for HP bar (top half of sprite)
	var hp_atlas := AtlasTexture.new()
	hp_atlas.atlas = frames_tex
	hp_atlas.region = Rect2(0, 0, frames_tex.get_width(), frames_tex.get_height() / 2)

	# Frame background (ornate border)
	var frame := TextureRect.new()
	frame.texture = hp_atlas
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(frame)

	# Progress bar (positioned inside the frame)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Inset the bar inside the frame
	bar.offset_left = min_size.x * 0.22  # Account for heart emblem
	bar.offset_right = -min_size.x * 0.05
	bar.offset_top = min_size.y * 0.25
	bar.offset_bottom = -min_size.y * 0.25
	bar.add_theme_stylebox_override("background", _create_bc_bar_bg(Color(0.2, 0.05, 0.05, 0.8)))
	bar.add_theme_stylebox_override("fill", _create_bc_bar_fill(Color(0.9, 0.2, 0.2)))
	bar.name = "HPBar"
	container.add_child(bar)

	return container


## Create a Battle Chasers style MP bar with ornate frame
static func create_bc_mp_bar(min_size: Vector2 = Vector2(200, 32)) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size

	# Load the bar frames texture
	var frames_tex: Texture2D = load(BC_BAR_FRAMES_PATH)
	if not frames_tex:
		# Fallback to regular MP bar
		var fallback := create_mp_bar(min_size)
		return fallback

	# Create atlas texture for MP bar (bottom half of sprite)
	var mp_atlas := AtlasTexture.new()
	mp_atlas.atlas = frames_tex
	mp_atlas.region = Rect2(0, frames_tex.get_height() / 2, frames_tex.get_width(), frames_tex.get_height() / 2)

	# Frame background (ornate border)
	var frame := TextureRect.new()
	frame.texture = mp_atlas
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(frame)

	# Progress bar (positioned inside the frame)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Inset the bar inside the frame
	bar.offset_left = min_size.x * 0.22  # Account for crystal emblem
	bar.offset_right = -min_size.x * 0.05
	bar.offset_top = min_size.y * 0.25
	bar.offset_bottom = -min_size.y * 0.25
	bar.add_theme_stylebox_override("background", _create_bc_bar_bg(Color(0.05, 0.1, 0.2, 0.8)))
	bar.add_theme_stylebox_override("fill", _create_bc_bar_fill(Color(0.2, 0.5, 0.9)))
	bar.name = "MPBar"
	container.add_child(bar)

	return container


## Internal: Create BC bar background style
static func _create_bc_bar_bg(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style


## Internal: Create BC bar fill style
static func _create_bc_bar_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style


## Create a Battle Chasers style dialogue box frame
static func create_bc_dialogue_frame(size: Vector2 = Vector2(800, 200)) -> TextureRect:
	var frame := TextureRect.new()
	var tex: Texture2D = load("res://assets/ui/battlechasers/dialogue_box_frame.png")
	if tex:
		frame.texture = tex
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.custom_minimum_size = size
	return frame


## Create a status effect icon from the status effects sheet
## icon_index: 0-63 (8x8 grid of 64 icons)
static func create_bc_status_icon(icon_index: int, size: Vector2 = Vector2(32, 32)) -> TextureRect:
	var icon := TextureRect.new()
	var tex: Texture2D = load("res://assets/ui/battlechasers/status_effects_icons.png")
	if tex:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		# 8x8 grid layout (64 icons, indices 0-63)
		var col := icon_index % 8
		var row := icon_index / 8
		var icon_size := Vector2(tex.get_width() / 8.0, tex.get_height() / 8.0)
		atlas.region = Rect2(col * icon_size.x, row * icon_size.y, icon_size.x, icon_size.y)
		icon.texture = atlas
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = size
	return icon


## Create a loot rarity frame from the rarity frames sheet
## rarity: 0=Common, 1=Uncommon, 2=Rare, 3=Epic, 4=Legendary, 5=Mythic, 6=Artifact, 7=Divine
static func create_bc_rarity_frame(rarity: int, size: Vector2 = Vector2(64, 64)) -> TextureRect:
	var frame := TextureRect.new()
	var tex: Texture2D = load("res://assets/ui/battlechasers/loot_rarity_frames.png")
	if tex:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var col := rarity % 4
		var row := rarity / 4
		var frame_size := Vector2(128, 128)  # Each frame is 128x128
		atlas.region = Rect2(col * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
		frame.texture = atlas
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.custom_minimum_size = size
	return frame


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
	text: String, font_size: int = FONT_SUBHEADING, min_size: Vector2 = Vector2(100, 40)
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


## Create a battle action button (AAA styled, 100x80 minimum size)
static func create_action_button(text: String) -> Button:
	return create_button(text, FONT_HEADING, Vector2(100, 80))


## Create a continue/confirm button
static func create_continue_button(text: String = "Continue") -> Button:
	var button := create_button(text, FONT_TITLE, Vector2(150, 45))
	button.add_theme_color_override("font_color", COLOR_CREAM)
	return button


# =============================================================================
# COMMON LAYOUT PATTERNS (v1.03)
# =============================================================================


## Create a horizontal stat row (name: value)
static func create_stat_row(
	name_text: String, value_text: String, value_color: Color = Color.WHITE
) -> HBoxContainer:
	var hbox := create_hbox(8)
	var name_label := create_stat_name_label(name_text + ":")
	var value_label := create_stat_value_label(value_text, value_color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	hbox.add_child(value_label)
	return hbox


## Create character info header (name + level)
static func create_character_header(
	name_text: String, level: int, is_enemy: bool = false
) -> VBoxContainer:
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

## Create action button normal style with accent color and shadow (AAA styling)
## Enhanced for larger 100x80 pixel battle buttons with prominent borders
static func create_action_button_normal(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# Darker, more prominent background
	style.bg_color = Color(0.1, 0.1, 0.14, 0.98)
	# Thicker accent-colored border for visibility
	style.border_color = accent_color.darkened(0.2)
	style.set_border_width_all(3)
	# Larger corner radius for modern AAA look
	style.set_corner_radius_all(10)
	# Stronger drop shadow for depth
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 3)
	# Content margins for padding
	style.set_content_margin_all(8)
	return style

## Create action button hover style with glow effect (AAA styling)
static func create_action_button_hover(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# Lighter background on hover
	style.bg_color = Color(0.16, 0.16, 0.22, 0.98)
	# Bright accent border
	style.border_color = accent_color.lightened(0.1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	# Prominent glow effect
	style.shadow_color = accent_color
	style.shadow_color.a = 0.7
	style.shadow_size = 12
	style.shadow_offset = Vector2.ZERO
	style.set_content_margin_all(8)
	return style

## Create action button pressed style (AAA styling)
static func create_action_button_pressed(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# Accent-tinted background when pressed
	style.bg_color = accent_color.darkened(0.5)
	style.border_color = accent_color.lightened(0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	# Inner shadow effect
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1, 1)
	style.set_content_margin_all(8)
	return style

## Create action button disabled style (AAA styling)
static func create_action_button_disabled() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.8)
	style.border_color = Color(0.25, 0.25, 0.3, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	return style

## Create action button focus style (AAA styling - gold/amber highlight)
static func create_action_button_focus() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.12, 0.18, 0.98)
	# Gold focus border for clear visibility
	style.border_color = Color(0.85, 0.65, 0.25, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	# Gold glow effect
	style.shadow_color = Color(0.85, 0.65, 0.25, 0.6)
	style.shadow_size = 10
	style.shadow_offset = Vector2.ZERO
	style.set_content_margin_all(8)
	return style

## Apply full action button styling with accent color (AAA battle buttons)
## Designed for large 100x80 pixel buttons with high visibility
static func apply_action_button_style(button: Button, accent_color: Color) -> void:
	button.add_theme_stylebox_override("normal", create_action_button_normal(accent_color))
	button.add_theme_stylebox_override("hover", create_action_button_hover(accent_color))
	button.add_theme_stylebox_override("pressed", create_action_button_pressed(accent_color))
	button.add_theme_stylebox_override("disabled", create_action_button_disabled())
	button.add_theme_stylebox_override("focus", create_action_button_focus())
	# High contrast text colors
	button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.95))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.45))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.85))
	# Larger font size for 80px tall buttons (FONT_HEADING = 18)
	button.add_theme_font_size_override("font_size", FONT_HEADING)

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

# =============================================================================
# CUSTOM ASSET-BASED UI COMPONENTS (v1.20 - Integration of art assets)
# =============================================================================

## Asset paths for UI textures
const ASSET_HP_BAR_FRAME := "res://assets/ui/bars/hp_bar_frame.png"
const ASSET_MP_BAR_FRAME := "res://assets/ui/bars/mp_bar_frame.png"
const ASSET_HP_MP_BARS := "res://assets/ui/bars/hp_mp_bars.png"
const ASSET_DIALOGUE_FRAME := "res://assets/ui/frames/DIALOGUE_FRAMENOBG.png"

## Buff icon paths
const BUFF_ICON_PATHS := {
	"attack_up": "res://assets/ui/icons/buffs/attack_up.png",
	"defense_up": "res://assets/ui/icons/buffs/defense_up.png",
	"speed_up": "res://assets/ui/icons/buffs/haste.png",
	"magic_up": "res://assets/ui/icons/buffs/magic_up.png",
	"regen": "res://assets/ui/icons/buffs/regen.png",
	"shield": "res://assets/ui/icons/buffs/shield.png",
	"protected": "res://assets/ui/icons/buffs/protected.png",
	"counter": "res://assets/ui/icons/buffs/counter.png",
	"reflect": "res://assets/ui/icons/buffs/reflect.png",
	"absorb": "res://assets/ui/icons/buffs/absorb.png",
	"berserk": "res://assets/ui/icons/buffs/berserk.png",
	"blessed": "res://assets/ui/icons/buffs/blessed.png",
	"clarity": "res://assets/ui/icons/buffs/clarity.png",
	"critical_up": "res://assets/ui/icons/buffs/critical_up.png",
	"empower": "res://assets/ui/icons/buffs/empower.png",
	"focus": "res://assets/ui/icons/buffs/focus.png",
	"fortify": "res://assets/ui/icons/buffs/fortify.png",
	"haste": "res://assets/ui/icons/buffs/haste.png",
	"inspired": "res://assets/ui/icons/buffs/inspired.png",
	"invisible": "res://assets/ui/icons/buffs/invisible.png",
	"lucky": "res://assets/ui/icons/buffs/lucky.png",
	"overcharge": "res://assets/ui/icons/buffs/overcharge.png",
}

## Debuff icon paths
const DEBUFF_ICON_PATHS := {
	"poison": "res://assets/ui/icons/debuffs/poison.png",
	"burn": "res://assets/ui/icons/debuffs/burn.png",
	"freeze": "res://assets/ui/icons/debuffs/freeze.png",
	"frozen": "res://assets/ui/icons/debuffs/frozen.png",
	"paralysis": "res://assets/ui/icons/debuffs/shock.png",
	"sleep": "res://assets/ui/icons/debuffs/sleep.png",
	"confusion": "res://assets/ui/icons/debuffs/confusion.png",
	"confuse": "res://assets/ui/icons/debuffs/confuse.png",
	"blind": "res://assets/ui/icons/debuffs/blind.png",
	"silence": "res://assets/ui/icons/debuffs/silence.png",
	"bleed": "res://assets/ui/icons/debuffs/bleed.png",
	"corrupted": "res://assets/ui/icons/debuffs/corruption.png",
	"corruption": "res://assets/ui/icons/debuffs/corruption.png",
	"attack_down": "res://assets/ui/icons/debuffs/attack_down.png",
	"defense_down": "res://assets/ui/icons/debuffs/defense_down.png",
	"speed_down": "res://assets/ui/icons/debuffs/speed_down.png",
	"magic_down": "res://assets/ui/icons/debuffs/magic_down.png",
	"curse": "res://assets/ui/icons/debuffs/curse.png",
	"doom": "res://assets/ui/icons/debuffs/doom.png",
	"exhausted": "res://assets/ui/icons/debuffs/exhausted.png",
	"fear": "res://assets/ui/icons/debuffs/fear.png",
	"marked": "res://assets/ui/icons/debuffs/marked.png",
	"slow": "res://assets/ui/icons/debuffs/slow.png",
	"stun": "res://assets/ui/icons/debuffs/stun.png",
	"weak": "res://assets/ui/icons/debuffs/weak.png",
}

## Action icon paths
const ACTION_ICON_PATHS := {
	"attack": "res://assets/ui/icons/actions/attack.png",
	"defend": "res://assets/ui/icons/actions/defend.png",
	"skill": "res://assets/ui/icons/actions/skill.png",
	"item": "res://assets/ui/icons/actions/item.png",
	"flee": "res://assets/ui/icons/actions/flee.png",
	"special": "res://assets/ui/icons/actions/special.png",
	"analyze": "res://assets/ui/icons/actions/analyze.png",
	"wait": "res://assets/ui/icons/actions/wait.png",
}

## Create an HP bar with custom ornate frame texture overlay
## Returns a Control containing the textured frame and progress bar
static func create_textured_hp_bar(min_size: Vector2 = Vector2(180, 36)) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size
	container.name = "TexturedHPBar"

	# Load the HP bar frame texture
	var frame_tex: Texture2D = null
	if ResourceLoader.exists(ASSET_HP_BAR_FRAME):
		frame_tex = load(ASSET_HP_BAR_FRAME)

	if not frame_tex:
		# Fallback to regular HP bar if texture missing
		var fallback := create_hp_bar(min_size)
		container.add_child(fallback)
		return container

	# Progress bar (positioned behind the frame)
	var bar := ProgressBar.new()
	bar.name = "HPBar"
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Inset the bar inside the ornate frame (heart emblem on left)
	bar.offset_left = min_size.x * 0.20
	bar.offset_right = -min_size.x * 0.04
	bar.offset_top = min_size.y * 0.28
	bar.offset_bottom = -min_size.y * 0.28
	bar.add_theme_stylebox_override("background", _create_textured_bar_bg(Color(0.15, 0.05, 0.05, 0.7)))
	bar.add_theme_stylebox_override("fill", _create_textured_bar_fill(Color(0.85, 0.25, 0.2)))
	container.add_child(bar)

	# Frame overlay (ornate border on top)
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = frame_tex
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(frame)

	return container


## Create an MP bar with custom ornate frame texture overlay
static func create_textured_mp_bar(min_size: Vector2 = Vector2(180, 36)) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size
	container.name = "TexturedMPBar"

	# Load the MP bar frame texture
	var frame_tex: Texture2D = null
	if ResourceLoader.exists(ASSET_MP_BAR_FRAME):
		frame_tex = load(ASSET_MP_BAR_FRAME)

	if not frame_tex:
		# Fallback to regular MP bar if texture missing
		var fallback := create_mp_bar(min_size)
		container.add_child(fallback)
		return container

	# Progress bar (positioned behind the frame)
	var bar := ProgressBar.new()
	bar.name = "MPBar"
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Inset the bar inside the ornate frame (crystal emblem on left)
	bar.offset_left = min_size.x * 0.20
	bar.offset_right = -min_size.x * 0.04
	bar.offset_top = min_size.y * 0.28
	bar.offset_bottom = -min_size.y * 0.28
	bar.add_theme_stylebox_override("background", _create_textured_bar_bg(Color(0.05, 0.08, 0.18, 0.7)))
	bar.add_theme_stylebox_override("fill", _create_textured_bar_fill(Color(0.25, 0.55, 0.9)))
	container.add_child(bar)

	# Frame overlay (ornate border on top)
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = frame_tex
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(frame)

	return container


## Internal: Create textured bar background style
static func _create_textured_bar_bg(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


## Internal: Create textured bar fill style with gradient effect
static func _create_textured_bar_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	# Add subtle inner glow effect
	style.shadow_color = color.lightened(0.3)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, -1)
	return style


## Create a status effect icon from individual asset files
## effect_name: lowercase name matching file (e.g., "poison", "attack_up")
## is_buff: true for buff icons, false for debuffs
static func create_status_effect_icon(effect_name: String, is_buff: bool, size: Vector2 = Vector2(24, 24)) -> TextureRect:
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = size

	# Look up the icon path
	var icon_path: String = ""
	var lookup_name := effect_name.to_lower().replace(" ", "_")

	if is_buff and BUFF_ICON_PATHS.has(lookup_name):
		icon_path = BUFF_ICON_PATHS[lookup_name]
	elif not is_buff and DEBUFF_ICON_PATHS.has(lookup_name):
		icon_path = DEBUFF_ICON_PATHS[lookup_name]

	# Try to load the texture
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex := load(icon_path) as Texture2D
		if tex:
			icon.texture = tex

	return icon


## Create a status effect icon with styled container
static func create_status_icon_with_container(effect_name: String, is_buff: bool, size: Vector2 = Vector2(28, 28)) -> PanelContainer:
	var container := PanelContainer.new()
	var style := create_status_buff_style() if is_buff else create_status_debuff_style()
	container.add_theme_stylebox_override("panel", style)
	container.custom_minimum_size = size

	var icon := create_status_effect_icon(effect_name, is_buff, size - Vector2(4, 4))
	container.add_child(icon)

	return container


## Get action icon texture by name
static func get_action_icon(action_name: String) -> Texture2D:
	var lookup_name := action_name.to_lower().replace(" ", "_")
	if ACTION_ICON_PATHS.has(lookup_name):
		var path: String = ACTION_ICON_PATHS[lookup_name]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


## Create a dialogue frame using the custom texture
static func create_dialogue_frame_textured(size: Vector2 = Vector2(800, 200)) -> TextureRect:
	var frame := TextureRect.new()
	if ResourceLoader.exists(ASSET_DIALOGUE_FRAME):
		var tex := load(ASSET_DIALOGUE_FRAME) as Texture2D
		if tex:
			frame.texture = tex
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.custom_minimum_size = size
	return frame


## Create a panel with NinePatchRect frame overlay for ornate borders
static func create_ornate_panel(frame_texture_path: String, size: Vector2) -> Control:
	var container := Control.new()
	container.custom_minimum_size = size

	# Background panel
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", create_dark_panel(BORDER_DEFAULT, 0))  # No border, we use texture
	container.add_child(bg)

	# Frame overlay
	if ResourceLoader.exists(frame_texture_path):
		var frame := TextureRect.new()
		frame.texture = load(frame_texture_path)
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(frame)

	return container


## Apply action icon to a button
static func apply_action_icon_to_button(button: Button, action_name: String) -> void:
	var icon := get_action_icon(action_name)
	if icon:
		button.icon = icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 28)


## Create a compact textured HP bar for sidebars (smaller version)
static func create_compact_textured_hp_bar(min_size: Vector2 = Vector2(100, 20)) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size
	container.name = "CompactHPBar"

	# Load the HP bar frame texture
	var frame_tex: Texture2D = null
	if ResourceLoader.exists(ASSET_HP_BAR_FRAME):
		frame_tex = load(ASSET_HP_BAR_FRAME)

	if not frame_tex:
		# Fallback to regular HP bar
		var fallback := create_hp_bar(min_size)
		container.add_child(fallback)
		return container

	# Progress bar
	var bar := ProgressBar.new()
	bar.name = "HPBar"
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.offset_left = min_size.x * 0.22
	bar.offset_right = -min_size.x * 0.05
	bar.offset_top = min_size.y * 0.22
	bar.offset_bottom = -min_size.y * 0.22
	bar.add_theme_stylebox_override("background", _create_textured_bar_bg(Color(0.15, 0.05, 0.05, 0.6)))
	bar.add_theme_stylebox_override("fill", _create_textured_bar_fill(Color(0.85, 0.25, 0.2)))
	container.add_child(bar)

	# Frame overlay
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = frame_tex
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(frame)

	return container


## Create a compact textured MP bar for sidebars
static func create_compact_textured_mp_bar(min_size: Vector2 = Vector2(100, 20)) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size
	container.name = "CompactMPBar"

	# Load the MP bar frame texture
	var frame_tex: Texture2D = null
	if ResourceLoader.exists(ASSET_MP_BAR_FRAME):
		frame_tex = load(ASSET_MP_BAR_FRAME)

	if not frame_tex:
		# Fallback to regular MP bar
		var fallback := create_mp_bar(min_size)
		container.add_child(fallback)
		return container

	# Progress bar
	var bar := ProgressBar.new()
	bar.name = "MPBar"
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.offset_left = min_size.x * 0.22
	bar.offset_right = -min_size.x * 0.05
	bar.offset_top = min_size.y * 0.22
	bar.offset_bottom = -min_size.y * 0.22
	bar.add_theme_stylebox_override("background", _create_textured_bar_bg(Color(0.05, 0.08, 0.18, 0.6)))
	bar.add_theme_stylebox_override("fill", _create_textured_bar_fill(Color(0.25, 0.55, 0.9)))
	container.add_child(bar)

	# Frame overlay
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = frame_tex
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(frame)

	return container


## Create a compact textured enemy HP bar (red themed)
static func create_compact_textured_enemy_hp_bar(min_size: Vector2 = Vector2(100, 20)) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size
	container.name = "CompactEnemyHPBar"

	# Load the HP bar frame texture
	var frame_tex: Texture2D = null
	if ResourceLoader.exists(ASSET_HP_BAR_FRAME):
		frame_tex = load(ASSET_HP_BAR_FRAME)

	if not frame_tex:
		# Fallback to regular enemy HP bar
		var fallback := create_enemy_hp_bar(min_size)
		container.add_child(fallback)
		return container

	# Progress bar
	var bar := ProgressBar.new()
	bar.name = "HPBar"
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.offset_left = min_size.x * 0.22
	bar.offset_right = -min_size.x * 0.05
	bar.offset_top = min_size.y * 0.22
	bar.offset_bottom = -min_size.y * 0.22
	bar.add_theme_stylebox_override("background", _create_textured_bar_bg(Color(0.18, 0.05, 0.05, 0.6)))
	bar.add_theme_stylebox_override("fill", _create_textured_bar_fill(Color(0.75, 0.2, 0.2)))
	container.add_child(bar)

	# Frame overlay
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = frame_tex
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(frame)

	return container


# =============================================================================
# GOTHIC DARK FANTASY STYLE METHODS
# =============================================================================


## Create a gothic panel style with asymmetric corners and shadow glow
static func create_gothic_panel_style(
	bg_color: Color = GOTHIC_PANEL_DARK,
	glow_color: Color = Color.TRANSPARENT,
	glow_size: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color

	# Asymmetric corners for organic/jagged feel
	style.corner_radius_top_left = GOTHIC_CORNER_LARGE
	style.corner_radius_top_right = GOTHIC_CORNER_SMALL
	style.corner_radius_bottom_left = GOTHIC_CORNER_SMALL
	style.corner_radius_bottom_right = GOTHIC_CORNER_LARGE

	# Thick dark iron border
	style.border_color = GOTHIC_BORDER_IRON
	style.border_width_left = GOTHIC_BORDER_WIDTH
	style.border_width_right = GOTHIC_BORDER_WIDTH
	style.border_width_top = GOTHIC_BORDER_WIDTH
	style.border_width_bottom = GOTHIC_BORDER_WIDTH

	# Shadow glow effect
	if glow_size > 0 and glow_color.a > 0:
		style.shadow_color = glow_color
		style.shadow_size = glow_size
		style.shadow_offset = Vector2(0, 2)

	# Content margins
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	return style


## Create a gothic sidebar style (ally or enemy themed)
static func create_gothic_sidebar_style(is_enemy: bool) -> StyleBoxFlat:
	var bg_color := GOTHIC_PANEL_ENEMY if is_enemy else GOTHIC_PANEL_ALLY
	var glow_color := GOTHIC_GLOW_BLOOD if is_enemy else GOTHIC_GLOW_ALLY
	return create_gothic_panel_style(bg_color, glow_color, 4)


## Create a gothic character card style for sidebar slots
static func create_gothic_character_card_style(is_enemy: bool, is_active: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	# Base color with enemy/ally tint
	style.bg_color = GOTHIC_PANEL_ENEMY if is_enemy else GOTHIC_PANEL_ALLY

	# Asymmetric corners
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 10

	# Border - iron with colored accent on one side
	style.border_color = GOTHIC_BORDER_IRON
	style.border_width_left = 3
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3

	# Active glow
	if is_active:
		style.shadow_color = GOTHIC_GLOW_ACTIVE
		style.shadow_size = GOTHIC_GLOW_SIZE_ACTIVE
		style.shadow_offset = Vector2(0, 0)
	else:
		style.shadow_color = Color.TRANSPARENT
		style.shadow_size = 0

	# Margins
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	return style


## Create a gothic portrait frame style
static func create_gothic_portrait_frame_style(is_active: bool = false, is_enemy: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GOTHIC_PANEL_VOID

	# Sharp corners for portrait frame
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 6

	# Border
	style.border_color = GOTHIC_BORDER_IRON_LIGHT
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	# Glow when active
	if is_active:
		var glow := GOTHIC_GLOW_BLOOD if is_enemy else GOTHIC_GLOW_ALLY
		style.shadow_color = glow
		style.shadow_size = 6
	else:
		style.shadow_size = 0

	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2

	return style


## Create a glowing border style for highlighting
static func create_glowing_border_style(
	glow_color: Color,
	glow_size: int = GOTHIC_GLOW_SIZE,
	border_color: Color = GOTHIC_BORDER_IRON
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT

	# Asymmetric corners
	style.corner_radius_top_left = GOTHIC_CORNER_LARGE
	style.corner_radius_top_right = GOTHIC_CORNER_SMALL
	style.corner_radius_bottom_left = GOTHIC_CORNER_SMALL
	style.corner_radius_bottom_right = GOTHIC_CORNER_LARGE

	# Border
	style.border_color = border_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3

	# Glow
	style.shadow_color = glow_color
	style.shadow_size = glow_size
	style.shadow_offset = Vector2(0, 0)

	return style


## Apply a glow effect to an existing panel
static func apply_panel_glow(panel: PanelContainer, glow_color: Color, glow_size: int = GOTHIC_GLOW_SIZE) -> void:
	var current_style = panel.get_theme_stylebox("panel")
	if current_style is StyleBoxFlat:
		var new_style := current_style.duplicate() as StyleBoxFlat
		new_style.shadow_color = glow_color
		new_style.shadow_size = glow_size
		new_style.shadow_offset = Vector2(0, 0)
		panel.add_theme_stylebox_override("panel", new_style)


## Remove glow effect from a panel
static func remove_panel_glow(panel: PanelContainer) -> void:
	var current_style = panel.get_theme_stylebox("panel")
	if current_style is StyleBoxFlat:
		var new_style := current_style.duplicate() as StyleBoxFlat
		new_style.shadow_color = Color.TRANSPARENT
		new_style.shadow_size = 0
		panel.add_theme_stylebox_override("panel", new_style)


# =============================================================================
# GOTHIC HP/MP BAR METHODS
# =============================================================================


## Create gothic HP bar background style
static func _create_gothic_bar_bg(is_hp: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GOTHIC_HP_BG if is_hp else GOTHIC_MP_BG

	# Asymmetric corners for bars too
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 4

	# Thin inner border
	style.border_color = GOTHIC_BORDER_IRON
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	return style


## Create gothic HP bar fill style
static func _create_gothic_bar_fill(is_hp: bool = true, is_enemy: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	if is_hp:
		style.bg_color = GOTHIC_ENEMY_HP_FILL if is_enemy else GOTHIC_HP_FILL
	else:
		style.bg_color = GOTHIC_MP_FILL

	# Match background corners
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 3

	return style


## Create a ghost bar style for HP drain animation
static func _create_ghost_bar_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.2, 0.1, 0.5)  # Semi-transparent red

	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 3

	return style


## Create a gothic HP bar with ghost bar for drain animation
static func create_gothic_hp_bar_with_ghost(min_size: Vector2 = Vector2(120, 16), is_enemy: bool = false) -> Control:
	var container := Control.new()
	container.custom_minimum_size = min_size
	container.name = "GothicHPBarContainer"

	# Ghost bar (behind actual bar) - shows damage drain
	var ghost_bar := ProgressBar.new()
	ghost_bar.name = "GhostBar"
	ghost_bar.show_percentage = false
	ghost_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	ghost_bar.value = 100
	ghost_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	ghost_bar.add_theme_stylebox_override("fill", _create_ghost_bar_fill())
	container.add_child(ghost_bar)

	# Actual HP bar (on top)
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.show_percentage = false
	hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_bar.value = 100
	hp_bar.add_theme_stylebox_override("background", _create_gothic_bar_bg(true))
	hp_bar.add_theme_stylebox_override("fill", _create_gothic_bar_fill(true, is_enemy))
	container.add_child(hp_bar)

	return container


## Create a standard gothic HP bar (no ghost)
static func create_gothic_hp_bar(min_size: Vector2 = Vector2(120, 16), is_enemy: bool = false) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = "HPBar"
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.value = 100
	bar.add_theme_stylebox_override("background", _create_gothic_bar_bg(true))
	bar.add_theme_stylebox_override("fill", _create_gothic_bar_fill(true, is_enemy))
	return bar


## Create a gothic MP bar
static func create_gothic_mp_bar(min_size: Vector2 = Vector2(100, 12)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = "MPBar"
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.value = 100
	bar.add_theme_stylebox_override("background", _create_gothic_bar_bg(false))
	bar.add_theme_stylebox_override("fill", _create_gothic_bar_fill(false))
	return bar


## Create a gothic corruption bar with purple theme
static func create_gothic_corruption_bar(min_size: Vector2 = Vector2(100, 8)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = "CorruptionBar"
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	bar.value = 0

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.10, 0.8)
	bg.corner_radius_top_left = 3
	bg.corner_radius_bottom_right = 3

	var fill := StyleBoxFlat.new()
	fill.bg_color = GOTHIC_CORRUPTION_FILL
	fill.corner_radius_top_left = 2
	fill.corner_radius_bottom_right = 2

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

	return bar


## Create gothic status icon container
static func create_gothic_status_container() -> HBoxContainer:
	var container := HBoxContainer.new()
	container.name = "StatusIcons"
	container.add_theme_constant_override("separation", 3)
	return container


## Create a gothic label with bone-white text
static func create_gothic_label(
	text: String,
	font_size: int = FONT_NORMAL,
	color: Color = GOTHIC_TEXT_BONE
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Create a gothic header label with ember highlight
static func create_gothic_header_label(text: String) -> Label:
	return create_gothic_label(text, FONT_HEADING, GOTHIC_TEXT_EMBER)
