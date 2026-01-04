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

## Create enemy tooltip style (red tint)
static func create_enemy_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	style.border_color = Color(0.6, 0.3, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

## Create ally tooltip style (green tint)
static func create_ally_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.08, 0.95)
	style.border_color = Color(0.3, 0.6, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
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

## Create a corruption bar (purple)
static func create_corruption_bar(min_size: Vector2 = Vector2(60, 4)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.05, 0.12, 0.9)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.6, 0.2, 0.7, 1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

## Create an XP bar (gold)
static func create_xp_bar(min_size: Vector2 = Vector2(100, 6)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = min_size
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.05, 0.9)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.75, 0.3, 1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
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
