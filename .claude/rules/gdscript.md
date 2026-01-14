---
globs: ["*.gd", "scripts/**/*.gd"]
description: GDScript coding standards for Godot 4.5
---

# GDScript Rules

## Type Hints (REQUIRED)
```gdscript
# CORRECT - Explicit types
var value: float = dict.get("key", 0.0)
var items: Array[String] = []

# WRONG - Variant inference
var value := dict.get("key", 0.0)
```

## Null Safety (REQUIRED)
```gdscript
var node := get_node_or_null("/root/Manager")
if node and node.has_method("method"):
    node.method()
```

## Use Utility Classes
- UIStyleFactory for UI styling
- AnimationEffects for tweens
- NodeHelpers for node operations
- StringHelpers for formatting
- Constants for magic numbers

## Signals via EventBus
```gdscript
EventBus.damage_dealt.emit(source, target, amount)
```

## File Structure
```gdscript
class_name ClassName
extends ParentClass
## Brief description

# SIGNALS
signal something_happened(param: Type)

# CONSTANTS
const MY_CONSTANT := 10

# EXPORTS
@export var my_var: int = 0

# STATE
var internal_state: Dictionary = {}
```

## Naming
- Classes: PascalCase
- Functions: snake_case
- Variables: snake_case
- Constants: SCREAMING_SNAKE_CASE
- Private: prefix with `_`
