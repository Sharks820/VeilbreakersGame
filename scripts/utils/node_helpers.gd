class_name NodeHelpers
extends RefCounted
## NodeHelpers: Centralized helper functions for common node operations.
## Consolidates 148+ is_instance_valid patterns, 45+ queue_free patterns,
## and 14+ get_children iteration patterns.

# =============================================================================
# INSTANCE VALIDATION (148+ duplicates)
# =============================================================================


## Check if node is valid and optionally not queued for deletion
static func is_valid(node: Variant) -> bool:
	return is_instance_valid(node)


## Check if node is valid and is inside tree
static func is_valid_in_tree(node: Variant) -> bool:
	return is_instance_valid(node) and node.is_inside_tree()


## Check if node is valid and visible (for CanvasItem)
static func is_valid_visible(node: Variant) -> bool:
	return is_instance_valid(node) and node is CanvasItem and node.visible


## Safe call a method on node if it exists
static func safe_call(node: Variant, method: String, args: Array = []) -> Variant:
	if not is_instance_valid(node):
		return null
	if not node.has_method(method):
		return null
	return node.callv(method, args)


## Safe get property from node
static func safe_get(node: Variant, property: String, default: Variant = null) -> Variant:
	if not is_instance_valid(node):
		return default
	if property in node:
		return node.get(property)
	return default


## Safe set property on node
static func safe_set(node: Variant, property: String, value: Variant) -> bool:
	if not is_instance_valid(node):
		return false
	if property in node:
		node.set(property, value)
		return true
	return false


# =============================================================================
# QUEUE FREE PATTERNS (45+ duplicates)
# =============================================================================


## Safely queue_free a node if valid
static func safe_free(node: Variant) -> void:
	if is_instance_valid(node):
		node.queue_free()


## Safely free multiple nodes
static func safe_free_all(nodes: Array) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()


## Clear all children from a container
static func clear_children(parent: Node) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		child.queue_free()


## Clear children of a specific type
static func clear_children_of_type(parent: Node, type: Variant) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		if is_instance_of(child, type):
			child.queue_free()


## Remove a node from parent and free it
static func remove_and_free(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	node.queue_free()


# =============================================================================
# CHILDREN ITERATION PATTERNS (14+ duplicates)
# =============================================================================


## Get children of a specific type
static func get_children_of_type(parent: Node, type: Variant) -> Array:
	var result: Array = []
	if not is_instance_valid(parent):
		return result
	for child in parent.get_children():
		if is_instance_of(child, type):
			result.append(child)
	return result


## Get first child of a specific type
static func get_first_child_of_type(parent: Node, type: Variant) -> Variant:
	if not is_instance_valid(parent):
		return null
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
	return null


## Get child count of a specific type
static func count_children_of_type(parent: Node, type: Variant) -> int:
	var count := 0
	if not is_instance_valid(parent):
		return count
	for child in parent.get_children():
		if is_instance_of(child, type):
			count += 1
	return count


## Check if parent has any children of type
static func has_children_of_type(parent: Node, type: Variant) -> bool:
	return get_first_child_of_type(parent, type) != null


## Get visible children only
static func get_visible_children(parent: Node) -> Array:
	var result: Array = []
	if not is_instance_valid(parent):
		return result
	for child in parent.get_children():
		if child is CanvasItem and child.visible:
			result.append(child)
	return result


## Apply a callable to all children
static func for_each_child(parent: Node, callback: Callable) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		callback.call(child)


## Apply a callable to all valid children of a type
static func for_each_child_of_type(parent: Node, type: Variant, callback: Callable) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		if is_instance_of(child, type):
			callback.call(child)


# =============================================================================
# NODE FINDING PATTERNS
# =============================================================================


## Safe find_child with null check
static func safe_find_child(
	parent: Node, name: String, recursive: bool = true, owned: bool = true
) -> Variant:
	if not is_instance_valid(parent):
		return null
	return parent.find_child(name, recursive, owned)


## Safe get_node with null check
static func safe_get_node(node: Node, path: NodePath) -> Variant:
	if not is_instance_valid(node):
		return null
	if not node.has_node(path):
		return null
	return node.get_node(path)


## Find ancestor of type
static func find_ancestor_of_type(node: Node, type: Variant) -> Variant:
	if not is_instance_valid(node):
		return null
	var parent := node.get_parent()
	while parent:
		if is_instance_of(parent, type):
			return parent
		parent = parent.get_parent()
	return null


## Find sibling by name
static func find_sibling(node: Node, name: String) -> Variant:
	if not is_instance_valid(node):
		return null
	var parent := node.get_parent()
	if not parent:
		return null
	return parent.find_child(name, false, false)


# =============================================================================
# VISIBILITY PATTERNS (84+ visible = assignments)
# =============================================================================


## Safely set visibility
static func set_visible(node: Variant, visible: bool) -> void:
	if is_instance_valid(node) and node is CanvasItem:
		node.visible = visible


## Show node if valid
static func show(node: Variant) -> void:
	set_visible(node, true)


## Hide node if valid
static func hide(node: Variant) -> void:
	set_visible(node, false)


## Toggle visibility
static func toggle_visible(node: Variant) -> void:
	if is_instance_valid(node) and node is CanvasItem:
		node.visible = not node.visible


## Set visibility on multiple nodes
static func set_all_visible(nodes: Array, visible: bool) -> void:
	for node in nodes:
		set_visible(node, visible)


## Show all nodes
static func show_all(nodes: Array) -> void:
	set_all_visible(nodes, true)


## Hide all nodes
static func hide_all(nodes: Array) -> void:
	set_all_visible(nodes, false)


# =============================================================================
# MODULATE PATTERNS (48+ modulate = assignments)
# =============================================================================


## Safely set modulate
static func set_modulate(node: Variant, color: Color) -> void:
	if is_instance_valid(node) and node is CanvasItem:
		node.modulate = color


## Reset modulate to white
static func reset_modulate(node: Variant) -> void:
	set_modulate(node, Color.WHITE)


## Set modulate on multiple nodes
static func set_all_modulate(nodes: Array, color: Color) -> void:
	for node in nodes:
		set_modulate(node, color)


## Set alpha only (preserve RGB)
static func set_alpha(node: Variant, alpha: float) -> void:
	if is_instance_valid(node) and node is CanvasItem:
		var c: Color = node.modulate
		c.a = alpha
		node.modulate = c


# =============================================================================
# REPARENTING PATTERNS
# =============================================================================


## Safely reparent a node
static func reparent(node: Node, new_parent: Node, keep_global_transform: bool = false) -> bool:
	if not is_instance_valid(node) or not is_instance_valid(new_parent):
		return false
	if node.get_parent():
		node.reparent(new_parent, keep_global_transform)
	else:
		new_parent.add_child(node)
	return true


## Move node to front (last child = rendered on top)
static func move_to_front(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent:
		parent.move_child(node, parent.get_child_count() - 1)


## Move node to back (first child = rendered behind)
static func move_to_back(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent:
		parent.move_child(node, 0)


# =============================================================================
# INSTANTIATION HELPERS (35+ .instantiate() patterns)
# =============================================================================


## Safely instantiate and add to parent
static func instantiate_to(scene: PackedScene, parent: Node) -> Variant:
	if not scene or not is_instance_valid(parent):
		return null
	var instance := scene.instantiate()
	parent.add_child(instance)
	return instance


## Safely instantiate, add to parent, and position
static func instantiate_at(scene: PackedScene, parent: Node, pos: Vector2) -> Variant:
	var instance: Node = instantiate_to(scene, parent)
	if instance and instance is Node2D:
		instance.position = pos
	elif instance and instance is Control:
		instance.position = pos
	return instance


## Safely instantiate with deferred add (for physics-safe operations)
static func instantiate_deferred(scene: PackedScene, parent: Node) -> Variant:
	if not scene or not is_instance_valid(parent):
		return null
	var instance := scene.instantiate()
	parent.call_deferred("add_child", instance)
	return instance


# =============================================================================
# SIGNAL HELPERS
# =============================================================================


## Safely disconnect all signals from a node
static func disconnect_all_signals(node: Variant, signal_name: String) -> void:
	if not is_instance_valid(node):
		return
	if not node.has_signal(signal_name):
		return
	for connection in node.get_signal_connection_list(signal_name):
		node.disconnect(signal_name, connection["callable"])


## Check if signal is connected to any callable
static func has_signal_connections(node: Variant, signal_name: String) -> bool:
	if not is_instance_valid(node):
		return false
	if not node.has_signal(signal_name):
		return false
	return not node.get_signal_connection_list(signal_name).is_empty()


## Safe connect with duplicate check
static func safe_connect(source: Variant, signal_name: String, target: Callable) -> bool:
	if not is_instance_valid(source):
		return false
	if not source.has_signal(signal_name):
		return false
	if source.is_connected(signal_name, target):
		return true
	source.connect(signal_name, target)
	return true


# =============================================================================
# PROCESS CONTROL
# =============================================================================


## Enable/disable processing for node and all children
static func set_processing_recursive(node: Node, enabled: bool) -> void:
	if not is_instance_valid(node):
		return
	node.set_process(enabled)
	node.set_physics_process(enabled)
	for child in node.get_children():
		set_processing_recursive(child, enabled)


## Pause/unpause node subtree
static func set_paused(node: Node, paused: bool) -> void:
	if not is_instance_valid(node):
		return
	if paused:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		node.process_mode = Node.PROCESS_MODE_INHERIT


# =============================================================================
# UTILITY
# =============================================================================


## Get the root of the scene tree from any node
static func get_scene_root(node: Node) -> Variant:
	if not is_instance_valid(node):
		return null
	if not node.is_inside_tree():
		return null
	return node.get_tree().root


## Check if node is in group
static func in_group(node: Variant, group_name: String) -> bool:
	if not is_instance_valid(node):
		return false
	return node.is_in_group(group_name)


## Safe add to group
static func add_to_group(node: Variant, group_name: String) -> void:
	if is_instance_valid(node) and not node.is_in_group(group_name):
		node.add_to_group(group_name)


## Safe remove from group
static func remove_from_group(node: Variant, group_name: String) -> void:
	if is_instance_valid(node) and node.is_in_group(group_name):
		node.remove_from_group(group_name)
