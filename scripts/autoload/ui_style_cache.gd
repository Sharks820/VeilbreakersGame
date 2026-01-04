class_name UIStyleCache
extends Node
## UIStyleCache: Caches and reuses StyleBox instances to prevent memory churn.
## 
## PROBLEM SOLVED:
## The codebase had 97+ StyleBoxFlat.new() calls creating identical styles repeatedly.
## Each StyleBox allocation causes GC pressure and memory fragmentation.
##
## SOLUTION:
## Cache StyleBoxes by a hash of their properties. Reuse existing instances.
## Reduces allocations from 97+ per battle to ~20 unique styles total.

# =============================================================================
# CACHED STYLEBOXES
# =============================================================================

## Cache of StyleBoxFlat instances keyed by property hash
var _flat_cache: Dictionary = {}  # String -> StyleBoxFlat

## Cache of StyleBoxEmpty instances (only need one)
var _empty_style: StyleBoxEmpty = null

## Statistics for debugging
var cache_hits: int = 0
var cache_misses: int = 0

# =============================================================================
# PREDEFINED COMMON STYLES (created once at startup)
# =============================================================================

## Panel backgrounds
var panel_dark: StyleBoxFlat
var panel_dark_red: StyleBoxFlat
var panel_dark_blue: StyleBoxFlat
var panel_transparent: StyleBoxFlat

## HP/MP/Corruption bar fills
var hp_fill_ally: StyleBoxFlat
var hp_fill_enemy: StyleBoxFlat
var hp_bg: StyleBoxFlat
var mp_fill: StyleBoxFlat
var mp_bg: StyleBoxFlat
var corruption_fill: StyleBoxFlat
var corruption_bg: StyleBoxFlat

## Button styles
var btn_normal: StyleBoxFlat
var btn_hover: StyleBoxFlat
var btn_pressed: StyleBoxFlat
var btn_disabled: StyleBoxFlat
var btn_focus: StyleBoxFlat

## Tooltip styles
var tooltip_bg: StyleBoxFlat

## Portrait frames
var portrait_frame_ally: StyleBoxFlat
var portrait_frame_enemy: StyleBoxFlat

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_predefined_styles()

func _create_predefined_styles() -> void:
	## Create all commonly-used styles once at startup
	
	# Panel backgrounds
	panel_dark = _create_flat(
		Color(0.1, 0.1, 0.15, 0.85),
		Color(0.3, 0.25, 0.4, 1.0),
		2, 8
	)
	
	panel_dark_red = _create_flat(
		Color(0.15, 0.1, 0.1, 0.85),
		Color(0.5, 0.25, 0.25, 1.0),
		2, 8
	)
	
	panel_dark_blue = _create_flat(
		Color(0.1, 0.1, 0.18, 0.85),
		Color(0.25, 0.3, 0.5, 1.0),
		2, 8
	)
	
	panel_transparent = _create_flat(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0, 0
	)
	
	# HP bars
	hp_fill_ally = _create_flat(
		Color(0.2, 0.8, 0.3, 1.0),
		Color(0, 0, 0, 0),
		0, 2
	)
	
	hp_fill_enemy = _create_flat(
		Color(0.8, 0.2, 0.2, 1.0),
		Color(0, 0, 0, 0),
		0, 2
	)
	
	hp_bg = _create_flat(
		Color(0.15, 0.1, 0.1, 0.9),
		Color(0, 0, 0, 0),
		0, 2
	)
	
	# MP bars
	mp_fill = _create_flat(
		Color(0.2, 0.4, 0.9, 1.0),
		Color(0, 0, 0, 0),
		0, 2
	)
	
	mp_bg = _create_flat(
		Color(0.1, 0.1, 0.15, 0.9),
		Color(0, 0, 0, 0),
		0, 2
	)
	
	# Corruption bars
	corruption_fill = _create_flat(
		Color(0.5, 0.1, 0.6, 1.0),
		Color(0, 0, 0, 0),
		0, 2
	)
	
	corruption_bg = _create_flat(
		Color(0.1, 0.05, 0.1, 0.9),
		Color(0, 0, 0, 0),
		0, 2
	)
	
	# Button styles
	btn_normal = _create_flat(
		Color(0.12, 0.12, 0.15, 0.95),
		Color(0.4, 0.35, 0.3, 0.8),
		2, 6
	)
	
	btn_hover = _create_flat(
		Color(0.18, 0.18, 0.22, 0.98),
		Color(0.6, 0.5, 0.4, 1.0),
		2, 6
	)
	
	btn_pressed = _create_flat(
		Color(0.08, 0.08, 0.1, 0.98),
		Color(0.5, 0.4, 0.3, 1.0),
		2, 6
	)
	
	btn_disabled = _create_flat(
		Color(0.08, 0.08, 0.1, 0.7),
		Color(0.3, 0.3, 0.3, 0.5),
		2, 6
	)
	
	btn_focus = _create_flat(
		Color(0.18, 0.14, 0.22, 0.95),
		Color(0.7, 0.55, 0.4, 1.0),
		2, 6
	)
	
	# Tooltip
	tooltip_bg = _create_flat(
		Color(0.08, 0.08, 0.12, 0.95),
		Color(0.4, 0.35, 0.5, 1.0),
		1, 4
	)
	
	# Portrait frames
	portrait_frame_ally = _create_flat(
		Color(0.15, 0.15, 0.2, 1.0),
		Color(0.4, 0.35, 0.5, 1.0),
		2, 4
	)
	
	portrait_frame_enemy = _create_flat(
		Color(0.2, 0.1, 0.1, 1.0),
		Color(0.6, 0.3, 0.3, 1.0),
		2, 4
	)

# =============================================================================
# STYLE CREATION HELPERS
# =============================================================================

func _create_flat(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	## Create a StyleBoxFlat with common settings
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style

# =============================================================================
# CACHED STYLE GETTERS
# =============================================================================

func get_empty() -> StyleBoxEmpty:
	## Get a cached empty StyleBox
	if not _empty_style:
		_empty_style = StyleBoxEmpty.new()
	return _empty_style

func get_flat(
	bg_color: Color,
	border_color: Color = Color(0, 0, 0, 0),
	border_width: int = 0,
	corner_radius: int = 0,
	content_margin: int = -1
) -> StyleBoxFlat:
	## Get a cached StyleBoxFlat with the specified properties.
	## If one with matching properties exists, returns the cached version.
	## Otherwise creates a new one and caches it.
	
	var cache_key := _make_cache_key(bg_color, border_color, border_width, corner_radius, content_margin)
	
	if _flat_cache.has(cache_key):
		cache_hits += 1
		return _flat_cache[cache_key]
	
	cache_misses += 1
	
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	if content_margin >= 0:
		style.set_content_margin_all(content_margin)
	
	_flat_cache[cache_key] = style
	return style

func get_flat_with_margins(
	bg_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	margin_left: int,
	margin_top: int,
	margin_right: int,
	margin_bottom: int
) -> StyleBoxFlat:
	## Get a cached StyleBoxFlat with custom margins per side
	var cache_key := "%s_%s_%d_%d_m%d%d%d%d" % [
		bg_color.to_html(),
		border_color.to_html(),
		border_width,
		corner_radius,
		margin_left, margin_top, margin_right, margin_bottom
	]
	
	if _flat_cache.has(cache_key):
		cache_hits += 1
		return _flat_cache[cache_key]
	
	cache_misses += 1
	
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = margin_left
	style.content_margin_top = margin_top
	style.content_margin_right = margin_right
	style.content_margin_bottom = margin_bottom
	
	_flat_cache[cache_key] = style
	return style

func _make_cache_key(bg_color: Color, border_color: Color, border_width: int, corner_radius: int, content_margin: int) -> String:
	## Create a unique cache key from style properties
	return "%s_%s_%d_%d_%d" % [
		bg_color.to_html(),
		border_color.to_html(),
		border_width,
		corner_radius,
		content_margin
	]

# =============================================================================
# SPECIALIZED GETTERS (for common patterns)
# =============================================================================

func get_hp_bar_fill(is_enemy: bool) -> StyleBoxFlat:
	## Get HP bar fill style (green for allies, red for enemies)
	return hp_fill_enemy if is_enemy else hp_fill_ally

func get_hp_bar_bg() -> StyleBoxFlat:
	## Get HP bar background style
	return hp_bg

func get_mp_bar_fill() -> StyleBoxFlat:
	## Get MP bar fill style
	return mp_fill

func get_mp_bar_bg() -> StyleBoxFlat:
	## Get MP bar background style
	return mp_bg

func get_corruption_bar_fill() -> StyleBoxFlat:
	## Get corruption bar fill style
	return corruption_fill

func get_corruption_bar_bg() -> StyleBoxFlat:
	## Get corruption bar background style
	return corruption_bg

func get_panel_style(variant: String = "dark") -> StyleBoxFlat:
	## Get a panel background style
	match variant:
		"dark_red", "enemy":
			return panel_dark_red
		"dark_blue", "ally":
			return panel_dark_blue
		"transparent":
			return panel_transparent
		_:
			return panel_dark

func get_button_style(state: String) -> StyleBoxFlat:
	## Get button style for a given state
	match state:
		"hover":
			return btn_hover
		"pressed":
			return btn_pressed
		"disabled":
			return btn_disabled
		"focus":
			return btn_focus
		_:
			return btn_normal

func get_portrait_frame(is_enemy: bool) -> StyleBoxFlat:
	## Get portrait frame style
	return portrait_frame_enemy if is_enemy else portrait_frame_ally

func get_tooltip_style() -> StyleBoxFlat:
	## Get tooltip background style
	return tooltip_bg

# =============================================================================
# DEBUG
# =============================================================================

func get_cache_stats() -> Dictionary:
	## Get cache statistics for debugging
	return {
		"hits": cache_hits,
		"misses": cache_misses,
		"cached_styles": _flat_cache.size(),
		"hit_rate": float(cache_hits) / max(1, cache_hits + cache_misses) * 100.0
	}

func print_cache_stats() -> void:
	## Print cache statistics to console
	var stats := get_cache_stats()
	print("[UIStyleCache] Hits: %d, Misses: %d, Cached: %d, Hit Rate: %.1f%%" % [
		stats.hits, stats.misses, stats.cached_styles, stats.hit_rate
	])
