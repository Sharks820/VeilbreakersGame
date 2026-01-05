# Utility Scripts Reference

> **5,285 lines of reusable code - USE THESE, don't reinvent them!**

## Quick Import Guide

All utilities are `class_name` based - no imports needed. Just use them:

```gdscript
# These are globally available:
UIStyleFactory.create_label(...)
AnimationEffects.popup_entrance(...)
NodeHelpers.safe_free(...)
StringHelpers.format_hp(...)
MathHelpers.get_hp_percent(...)
Constants.WAIT_SHORT
```

---

## Utility Overview

| File | Lines | Purpose |
|------|-------|---------|
| **ui_style_factory.gd** | 889 | UI creation, styling, panels, buttons, labels, colors, fonts |
| **animation_effects.gd** | 783 | Tweens, flashes, fades, popups, easing, staggered animations |
| **constants.gd** | 635 | Game balance, timings, multipliers, thresholds |
| **node_helpers.gd** | 385 | Node operations, cleanup, visibility, instantiation |
| **string_helpers.gd** | 304 | Formatting, BBCode, pluralization, battle messages |
| **math_helpers.gd** | 228 | Calculations, percentages, clamping, variance |
| **validation_helpers.gd** | 258 | Input validation, type checking |
| **signal_helpers.gd** | 211 | Signal utilities, EventBus helpers |
| **debug_helpers.gd** | 199 | Debug logging, formatting |
| **brand_system.gd** | 234 | Brand colors, effectiveness, classification |
| **enums.gd** | 381 | All game enumerations |
| **helpers.gd** | 285 | Legacy helpers (prefer specific utilities) |
| **paths.gd** | 172 | File path constants |
| **input_actions.gd** | 87 | Input action names |
| **debug.gd** | 234 | Debug console |

---

## When to Create New Utilities

Create a new utility function when:
1. You write the same pattern **3+ times**
2. The pattern involves **error-prone boilerplate**
3. The pattern has **consistent parameters**

### Where to Add New Utilities

| Pattern Type | Add To |
|--------------|--------|
| UI styling, labels, buttons | ui_style_factory.gd |
| Animations, tweens, effects | animation_effects.gd |
| Node operations, cleanup | node_helpers.gd |
| String formatting | string_helpers.gd |
| Math calculations | math_helpers.gd |
| Magic numbers, timings | constants.gd |

### Utility Function Template

```gdscript
## Brief description of what this does
## @param node: The node to operate on
## @param duration: Animation duration in seconds
## @returns: The created tween, or null if node is invalid
static func my_new_utility(node: CanvasItem, duration: float = 0.3) -> Tween:
    if not is_instance_valid(node):
        return null
    var tween := node.create_tween()
    # ... implementation
    return tween
```

---

## Common Mistakes

### ❌ Don't bypass utilities to "save time"
```gdscript
# This is NOT faster - it's technical debt
var label = Label.new()
label.add_theme_font_size_override("font_size", 14)
```

### ✅ Use the utility - it handles edge cases
```gdscript
# This is consistent, tested, and maintainable
var label = UIStyleFactory.create_label("text", UIStyleFactory.FONT_NORMAL)
```

### ❌ Don't duplicate for "small changes"
```gdscript
# If you need a variant, ADD IT TO THE UTILITY
func my_special_popup():
    popup.modulate.a = 0.0
    popup.scale = Vector2(0.7, 0.7)  # slightly different
    # ... copy-pasted animation code
```

### ✅ Extend the utility with parameters
```gdscript
# Add the variant to AnimationEffects if needed
AnimationEffects.popup_entrance(popup, 0.25, 0.7)  # custom start_scale
```

---

## Enforcement

- **AGENTS.md** requires utility usage - AI agents will follow this
- **CLAUDE.md** requires utility usage - Claude Code will follow this
- **CODE_PATTERNS.md** documents all anti-patterns to avoid
- **duplication_detector.gd** scans for violations (run in editor)

---

*Maintained as part of the code quality initiative. Last updated: v1.06*
