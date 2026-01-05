class_name InputActions
extends RefCounted
## InputActions: Centralized input action name constants.
## Eliminates 20+ hardcoded action strings across UI controllers.

# =============================================================================
# GODOT BUILT-IN UI ACTIONS
# =============================================================================

const ACCEPT := "ui_accept"  # Enter/Space - confirm selection
const CANCEL := "ui_cancel"  # Escape - cancel/back
const UP := "ui_up"  # Arrow up / W
const DOWN := "ui_down"  # Arrow down / S
const LEFT := "ui_left"  # Arrow left / A
const RIGHT := "ui_right"  # Arrow right / D
const FOCUS_NEXT := "ui_focus_next"  # Tab
const FOCUS_PREV := "ui_focus_prev"  # Shift+Tab
const PAGE_UP := "ui_page_up"
const PAGE_DOWN := "ui_page_down"
const HOME := "ui_home"
const END := "ui_end"

# =============================================================================
# CUSTOM GAME ACTIONS
# =============================================================================

const INTERACT := "interact"  # E key - interact with objects/NPCs
const TOGGLE_MENU := "toggle_menu"  # Tab/Esc - open/close menu
const RUN := "ui_shift"  # Shift - run/sprint modifier
const TOGGLE_DEBUG := "toggle_debug"  # F3 - debug overlay

# =============================================================================
# BATTLE ACTIONS
# =============================================================================

const BATTLE_ATTACK := "battle_attack"
const BATTLE_SKILL := "battle_skill"
const BATTLE_ITEM := "battle_item"
const BATTLE_DEFEND := "battle_defend"
const BATTLE_FLEE := "battle_flee"
const BATTLE_CAPTURE := "battle_capture"

# =============================================================================
# QUICK ACCESS HELPERS
# =============================================================================


## Check if event is any accept input (key or mouse)
static func is_accept(event: InputEvent) -> bool:
	return event.is_action_pressed(ACCEPT)


## Check if event is any cancel input (key or mouse)
static func is_cancel(event: InputEvent) -> bool:
	return event.is_action_pressed(CANCEL)


## Check if event is directional input (returns direction vector)
static func get_direction(event: InputEvent) -> Vector2:
	var direction := Vector2.ZERO
	if event.is_action_pressed(UP):
		direction.y -= 1
	if event.is_action_pressed(DOWN):
		direction.y += 1
	if event.is_action_pressed(LEFT):
		direction.x -= 1
	if event.is_action_pressed(RIGHT):
		direction.x += 1
	return direction


## Check if event is navigation (up/down/left/right)
static func is_navigation(event: InputEvent) -> bool:
	return (
		event.is_action_pressed(UP)
		or event.is_action_pressed(DOWN)
		or event.is_action_pressed(LEFT)
		or event.is_action_pressed(RIGHT)
	)


## Check if event is vertical navigation (up/down only)
static func is_vertical_nav(event: InputEvent) -> bool:
	return event.is_action_pressed(UP) or event.is_action_pressed(DOWN)


## Check if event is horizontal navigation (left/right only)
static func is_horizontal_nav(event: InputEvent) -> bool:
	return event.is_action_pressed(LEFT) or event.is_action_pressed(RIGHT)


## Get navigation direction (-1 for up/left, +1 for down/right)
static func get_nav_direction(event: InputEvent) -> int:
	if event.is_action_pressed(UP) or event.is_action_pressed(LEFT):
		return -1
	if event.is_action_pressed(DOWN) or event.is_action_pressed(RIGHT):
		return 1
	return 0
