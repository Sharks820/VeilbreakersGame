# =============================================================================
# VEILBREAKERS Battle UI Animation System
# Handles all UI animations for turn-based combat
# Turn order, skill announcements, damage popups, status indicators
# =============================================================================

class_name BattleUIAnimator
extends Control

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal turn_order_animation_complete
signal skill_announcement_complete
signal action_menu_ready
signal target_selection_ready

# -----------------------------------------------------------------------------
# NODE REFERENCES (Assign in editor or find at ready)
# -----------------------------------------------------------------------------
@export_group("Core UI Elements")
@export var turn_order_bar: Control
@export var action_menu: Control
@export var skill_name_display: Control
@export var target_selector: Control
@export var status_popup_container: Control
@export var message_display: Control

@export_group("Templates")
@export var turn_icon_template: PackedScene
@export var status_popup_template: PackedScene

@export_group("Timing")
@export var turn_icon_slide_time: float = 0.3
@export var skill_name_display_time: float = 1.5
@export var status_popup_time: float = 1.0
@export var message_display_time: float = 1.5

# -----------------------------------------------------------------------------
# BRAND COLORS (for UI theming)
# -----------------------------------------------------------------------------
const BRAND_COLORS = {
	"SAVAGE": Color("c73e3e"),
	"IRON": Color("7b8794"),
	"VENOM": Color("6b9b37"),
	"SURGE": Color("4a90d9"),
	"DREAD": Color("5d3e8c"),
	"LEECH": Color("c75b8a"),
	"NEUTRAL": Color.WHITE,
}

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
var turn_icons: Array = []  # Current turn order icons
var active_popups: Array = []

# -----------------------------------------------------------------------------
# TURN ORDER BAR
# -----------------------------------------------------------------------------
func show_turn_order(order: Array) -> void:
	"""Display/update turn order with animation"""
	if not turn_order_bar or not turn_icon_template:
		return
	
	# Clear old icons
	for icon in turn_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	turn_icons.clear()
	
	# Create new icons
	for i in range(order.size()):
		var entity = order[i]
		var icon = turn_icon_template.instantiate()
		turn_order_bar.add_child(icon)
		turn_icons.append(icon)
		
		# Setup icon appearance
		_setup_turn_icon(icon, entity, i)
		
		# Animate entrance
		icon.modulate.a = 0.0
		icon.position.y -= 50
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(icon, "modulate:a", 1.0, turn_icon_slide_time).set_delay(i * 0.1)
		tween.tween_property(icon, "position:y", 0, turn_icon_slide_time).set_delay(i * 0.1).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(turn_icon_slide_time + order.size() * 0.1).timeout
	turn_order_animation_complete.emit()

func _setup_turn_icon(icon: Control, entity: Node, index: int) -> void:
	"""Configure a turn order icon for an entity"""
	# Assuming icon has: portrait texture, name label, highlight, brand indicator
	if icon.has_node("Portrait") and entity.has_method("get_portrait"):
		icon.get_node("Portrait").texture = entity.get_portrait()
	
	if icon.has_node("NameLabel"):
		icon.get_node("NameLabel").text = entity.display_name if "display_name" in entity else "???"
	
	if icon.has_node("BrandIndicator") and entity.has_method("get_brand"):
		var brand = entity.get_brand()
		icon.get_node("BrandIndicator").modulate = BRAND_COLORS.get(brand, Color.WHITE)
	
	# First in order gets highlight
	if index == 0 and icon.has_node("ActiveHighlight"):
		icon.get_node("ActiveHighlight").visible = true

func highlight_current_turn(entity: Node) -> void:
	"""Highlight the current actor's turn icon"""
	for i in range(turn_icons.size()):
		var icon = turn_icons[i]
		if not is_instance_valid(icon):
			continue
		
		var is_current = (i == 0)  # First icon is current
		
		if icon.has_node("ActiveHighlight"):
			icon.get_node("ActiveHighlight").visible = is_current
		
		# Pulse animation for current
		if is_current:
			var tween = create_tween().set_loops()
			tween.tween_property(icon, "scale", Vector2(1.1, 1.1), 0.5)
			tween.tween_property(icon, "scale", Vector2.ONE, 0.5)

func advance_turn_order() -> void:
	"""Animate the turn order advancing (first icon out, rest slide left)"""
	if turn_icons.is_empty():
		return
	
	var first_icon = turn_icons.pop_front()
	
	# Animate first icon out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(first_icon, "modulate:a", 0.0, 0.2)
	tween.tween_property(first_icon, "position:y", first_icon.position.y - 30, 0.2)
	tween.tween_callback(first_icon.queue_free)
	
	# Slide remaining icons left
	await get_tree().create_timer(0.1).timeout
	
	for i in range(turn_icons.size()):
		var icon = turn_icons[i]
		if not is_instance_valid(icon):
			continue
		
		var target_x = i * (icon.size.x + 10)  # Assuming horizontal layout
		var slide_tween = create_tween()
		slide_tween.tween_property(icon, "position:x", target_x, 0.2).set_ease(Tween.EASE_OUT)

# -----------------------------------------------------------------------------
# ACTION MENU
# -----------------------------------------------------------------------------
func show_action_menu(entity: Node) -> void:
	"""Animate action menu appearing"""
	if not action_menu:
		return
	
	action_menu.visible = true
	action_menu.modulate.a = 0.0
	action_menu.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(action_menu, "modulate:a", 1.0, 0.2)
	tween.tween_property(action_menu, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	action_menu_ready.emit()

func hide_action_menu() -> void:
	"""Animate action menu disappearing"""
	if not action_menu or not action_menu.visible:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(action_menu, "modulate:a", 0.0, 0.15)
	tween.tween_property(action_menu, "scale", Vector2(0.9, 0.9), 0.15)
	tween.tween_callback(func(): action_menu.visible = false)

# -----------------------------------------------------------------------------
# SKILL NAME DISPLAY
# -----------------------------------------------------------------------------
func show_skill_name(skill_name: String, brand: String = "NEUTRAL") -> void:
	"""Display skill name with dramatic animation"""
	if not skill_name_display:
		return
	
	# Configure appearance
	if skill_name_display.has_node("SkillLabel"):
		var label = skill_name_display.get_node("SkillLabel")
		label.text = skill_name
		
		# Brand color
		label.add_theme_color_override("font_color", BRAND_COLORS.get(brand, Color.WHITE))
	
	if skill_name_display.has_node("BrandGlow"):
		skill_name_display.get_node("BrandGlow").modulate = BRAND_COLORS.get(brand, Color.WHITE)
	
	# Animate in
	skill_name_display.visible = true
	skill_name_display.modulate.a = 0.0
	skill_name_display.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	
	# Pop in
	tween.tween_property(skill_name_display, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(skill_name_display, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)
	
	# Settle
	tween.tween_property(skill_name_display, "scale", Vector2.ONE, 0.1)
	
	# Hold
	tween.tween_interval(skill_name_display_time)
	
	# Fade out
	tween.tween_property(skill_name_display, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): 
		skill_name_display.visible = false
		skill_announcement_complete.emit()
	)

# -----------------------------------------------------------------------------
# STATUS POPUPS
# -----------------------------------------------------------------------------
func show_status_popup(target: Node, status_text: String, is_positive: bool) -> void:
	"""Show floating status text near a target"""
	if not status_popup_template or not status_popup_container:
		return
	
	var popup = status_popup_template.instantiate()
	status_popup_container.add_child(popup)
	active_popups.append(popup)
	
	# Position near target
	if target is Node2D:
		popup.global_position = target.global_position + Vector2(0, -50)
	
	# Configure text
	if popup.has_node("Label"):
		var label = popup.get_node("Label")
		label.text = status_text
		label.add_theme_color_override("font_color", Color.GREEN if is_positive else Color.RED)
	
	# Animate
	popup.modulate.a = 0.0
	popup.position.y += 20
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 1.0, 0.15)
	tween.tween_property(popup, "position:y", popup.position.y - 40, 0.3).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_interval(status_popup_time)
	tween.chain().tween_property(popup, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func():
		active_popups.erase(popup)
		popup.queue_free()
	)

# -----------------------------------------------------------------------------
# MESSAGE DISPLAY
# -----------------------------------------------------------------------------
func show_message(text: String, position: Vector2 = Vector2.ZERO) -> void:
	"""Show a message (like 'MISS!' or 'RESISTED!')"""
	if not message_display:
		return
	
	if message_display.has_node("Label"):
		message_display.get_node("Label").text = text
	
	# Center or position
	if position != Vector2.ZERO and message_display is Control:
		# Convert world to screen position if needed
		pass
	
	message_display.visible = true
	message_display.modulate.a = 0.0
	message_display.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.tween_property(message_display, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(message_display, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(message_display, "scale", Vector2.ONE, 0.1)
	tween.tween_interval(message_display_time)
	tween.tween_property(message_display, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): message_display.visible = false)

# -----------------------------------------------------------------------------
# CAPTURE ANNOUNCEMENT
# -----------------------------------------------------------------------------
func show_capture_announcement(monster_name: String, brand: String) -> void:
	"""Celebratory capture success announcement"""
	# This would be a more elaborate UI element
	# For now, use message display
	show_message("CAPTURED: " + monster_name + "!")

# -----------------------------------------------------------------------------
# PHASE ANNOUNCEMENT
# -----------------------------------------------------------------------------
func show_phase_announcement(boss_name: String, phase: int, phase_name: String) -> void:
	"""Boss phase transition announcement"""
	show_message(boss_name + " - " + phase_name)

# -----------------------------------------------------------------------------
# VICTORY/DEFEAT SCREENS
# -----------------------------------------------------------------------------
func show_victory_screen(data: Dictionary) -> void:
	"""Victory screen with exp, drops, stats"""
	# Would animate in a full victory panel
	show_message("VICTORY!")

func show_defeat_screen(data: Dictionary) -> void:
	"""Defeat screen"""
	show_message("DEFEATED...")

# -----------------------------------------------------------------------------
# TARGET SELECTION
# -----------------------------------------------------------------------------
func start_target_selection(valid_targets: Array, selection_type: String = "single") -> void:
	"""Enable target selection mode"""
	if not target_selector:
		return
	
	target_selector.visible = true
	# Configure targeting UI based on selection_type (single, all, aoe, etc.)
	target_selection_ready.emit()

func end_target_selection() -> void:
	"""Disable target selection mode"""
	if target_selector:
		target_selector.visible = false

# -----------------------------------------------------------------------------
# HIDE/SHOW ALL UI
# -----------------------------------------------------------------------------
func hide_all_ui() -> void:
	"""Hide all battle UI for cinematics"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	if turn_order_bar:
		tween.tween_property(turn_order_bar, "modulate:a", 0.0, 0.3)
	if action_menu:
		tween.tween_property(action_menu, "modulate:a", 0.0, 0.3)

func show_all_ui() -> void:
	"""Restore battle UI after cinematics"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	if turn_order_bar:
		tween.tween_property(turn_order_bar, "modulate:a", 1.0, 0.3)
	# Action menu only shown when needed

# -----------------------------------------------------------------------------
# BOSS TITLE CARD
# -----------------------------------------------------------------------------
func show_boss_title_card(boss_name: String, title: String) -> void:
	"""Dramatic boss introduction title"""
	# Would be a custom title card UI element
	# With the boss name in large text, title below
	# Animated with dramatic flair
	
	# Placeholder using message
	show_message(title + "\n" + boss_name)

# -----------------------------------------------------------------------------
# HEALTH BAR ANIMATIONS (called externally when damage/heal happens)
# -----------------------------------------------------------------------------
func animate_health_change(entity: Node, old_value: int, new_value: int, max_value: int) -> void:
	"""Animate a health bar change"""
	# This would find the entity's health bar and animate it
	# Could include:
	# - Smooth drain
	# - Flash on damage
	# - Shake on heavy damage
	# - Color change when low
	pass
