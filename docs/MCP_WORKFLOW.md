# VEILBREAKERS MCP WORKFLOW
## Integrated Development Pipeline

---

## OVERVIEW

```
                              ┌─────────────────┐
                              │     TRELLO      │
                              │  (Task Central) │
                              └────────┬────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           │                           │                           │
           ▼                           ▼                           ▼
    ┌─────────────┐             ┌─────────────┐             ┌─────────────┐
    │   PLANNING  │             │   BUILDING  │             │   ASSETS    │
    └─────────────┘             └─────────────┘             └─────────────┘
           │                           │                           │
    ┌──────┴──────┐             ┌──────┴──────┐             ┌──────┴──────┐
    │             │             │             │             │             │
    ▼             ▼             ▼             ▼             ▼             ▼
 Memory    Sequential      Godot        Godot         HuggingFace   Image
           Thinking      Screenshots    Editor                     Process
                                                          │
                                                    ┌─────┴─────┐
                                                    ▼           ▼
                                              LottieFiles    Figma
```

---

## 1. TRELLO - Command Center

**Role:** Central task management, sprint planning, bug tracking

### Board Structure
```
VEILBREAKERS GAME DEV
├── 📋 BACKLOG        → All future tasks/features
├── 🎯 SPRINT         → Current sprint tasks (1-2 week cycles)
├── 🔨 IN PROGRESS    → Actively being worked on
├── 🧪 TESTING        → Needs verification/QA
├── ✅ DONE           → Completed this sprint
├── 🐛 BUGS           → Bug reports and fixes
└── 💡 IDEAS          → Feature ideas for later
```

### Labels
| Label | Color | Use |
|-------|-------|-----|
| `battle` | Red | Battle system work |
| `ui` | Blue | UI/UX tasks |
| `art` | Purple | Asset creation |
| `audio` | Green | Sound/music |
| `vera` | Pink | VERA system |
| `monsters` | Orange | Monster-related |
| `critical` | Black | Blockers |

### Workflow Commands
```
"Create a card for [task]"
"Move [card] to In Progress"
"Add bug: [description]"
"What's in the current sprint?"
"Close [card] as done"
```

---

## 2. MEMORY - Project Brain

**Role:** Persistent knowledge across sessions

### What to Store
- **Decisions Made:** Architecture choices, design decisions
- **Entity Relationships:** How systems connect
- **Preferences:** Coding style, naming conventions
- **Progress:** What's been completed, what's blocked

### Usage Pattern
```
START OF SESSION:
  → Read memory graph
  → Recall project context
  → Check last session's work

DURING SESSION:
  → Store new decisions
  → Update entity relationships
  → Track blockers discovered

END OF SESSION:
  → Save session summary
  → Update progress state
```

### Memory Categories
| Entity Type | Examples |
|-------------|----------|
| `System` | BattleSystem, VERASystem, PathSystem |
| `Decision` | "Use brand matrix for damage", "4 paths not 5" |
| `Bug` | Known issues and their status |
| `Preference` | "User prefers Battle Chasers style" |

---

## 3. SEQUENTIAL THINKING - Complex Problem Solver

**Role:** Break down complex problems, multi-step reasoning

### When to Use
- Designing new game systems
- Balancing calculations
- Architecture decisions
- Debugging complex issues
- Multi-step implementation planning

### Example Triggers
```
"Design the skill inheritance system"
"Balance the damage formula for late game"
"Plan the save migration from v1 to v2"
"Debug why monsters aren't spawning correctly"
```

### Output → Trello
Complex plans get broken into Trello cards automatically.

---

## 4. GODOT SCREENSHOTS - Visual Verification

**Role:** Run game, capture screenshots, verify changes

### Workflow
```
1. Make code changes
2. Run project via MCP
3. Capture screenshot
4. Verify visual result
5. Iterate or mark done
```

### Use Cases
| Scenario | Command |
|----------|---------|
| Test battle UI | Run → Screenshot battle scene |
| Verify menu | Run → Navigate to menu → Screenshot |
| Check animations | Run → Trigger action → Screenshot |
| Debug layout | Run → Screenshot problem area |

### Integration
- Screenshots can be attached to Trello cards as proof of completion
- Visual bugs get screenshot evidence

---

## 5. GODOT EDITOR - Direct Manipulation

**Role:** Create scenes, add nodes, modify project

### Capabilities
- Create new scenes (.tscn)
- Add nodes to scenes
- Set node properties
- Load sprites into nodes
- Save scene changes

### When to Use
```
"Create a new scene for the inventory UI"
"Add a Sprite2D node to the player scene"
"Set up the battle arena layout"
```

### Workflow with Screenshots
```
1. Godot Editor → Make changes
2. Godot Screenshots → Run and verify
3. Iterate until correct
4. Mark Trello card done
```

---

## 6. GSAP ANIMATION - Animation Patterns

**Role:** Get professional animation patterns, translate to Godot

### Use Cases
- Button hover effects
- Menu transitions
- Damage number animations
- Screen shake patterns
- UI element entrances/exits

### Translation Pattern
```
GSAP Pattern → Godot Tween Equivalent

gsap.to(element, {
  scale: 1.1,
  duration: 0.3,
  ease: "back.out"
})

↓ Translates to ↓

var tween = create_tween()
tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.3)
     .set_ease(Tween.EASE_OUT)
     .set_trans(Tween.TRANS_BACK)
```

### Already Integrated
The animation system from `veilbreakers-complete` uses these patterns:
- `scripts/battle/animation/` - 11 animation scripts
- `shaders/` - 10 effect shaders

---

## 7. IMAGE PROCESS - Asset Pipeline

**Role:** Crop, resize, convert, batch process images

### Capabilities
| Function | Use Case |
|----------|----------|
| Resize | Scale sprites to game resolution |
| Crop | Extract regions from sprite sheets |
| Convert | PNG ↔ WebP ↔ JPG |
| Rotate | Fix orientation issues |

### Workflow
```
1. Get raw asset (AI generated, downloaded, etc.)
2. Process with image-process MCP
3. Save to assets/ folder
4. Import in Godot
```

### Batch Processing
```
"Resize all icons in assets/ui/icons to 64x64"
"Convert all PNGs in assets/sprites to WebP"
```

---

## 8. HUGGINGFACE - AI Asset Generation

**Role:** Generate sprites, concepts, placeholders with AI

### Models Available
- FLUX (high quality)
- Stable Diffusion variants
- Specialized models

### Use Cases
| Need | Prompt Style |
|------|--------------|
| Monster sprite | "battle chasers style monster, [description], game sprite, white background" |
| Icon | "rpg game icon, [item], detailed, 2D" |
| Background | "fantasy game background, [location], painterly" |
| UI element | "game UI panel, fantasy style, ornate border" |

### Workflow
```
1. Generate with HuggingFace
2. Process with Image Process (resize, crop)
3. Import to Godot
4. Verify with Screenshots
```

### Integration with LoRA
Your Battle Chasers LoRA (trained on scenario.gg) can be referenced for style consistency.

---

## 9. LOTTIEFILES - Animation Library

**Role:** Search and retrieve Lottie animations

### Use Cases
- Loading spinners
- UI transitions
- Success/failure indicators
- Particle-like effects

### Workflow
```
1. Search: "loading spinner fantasy"
2. Get animation data
3. Convert to Godot AnimatedSprite or shader
4. Integrate into UI
```

### Best For
- Quick placeholder animations
- Inspiration for custom animations
- UI polish elements

---

## 10. FIGMA - UI Design Pipeline

**Role:** Extract designs, get layout data, design tokens

### Use Cases
| Task | How |
|------|-----|
| Get UI layout | Extract component positions/sizes |
| Color palette | Pull design tokens |
| Asset export | Get UI elements as images |
| Spacing/typography | Extract design system values |

### Workflow
```
1. Design UI in Figma
2. Extract with MCP → Get positions, sizes, colors
3. Build in Godot matching specs
4. Verify with Screenshots
```

---

## INTEGRATED WORKFLOWS

### A. New Feature Development
```
1. TRELLO      → Create card in Backlog
2. TRELLO      → Move to Sprint when prioritized
3. SEQUENTIAL  → Plan implementation (if complex)
4. MEMORY      → Store design decisions
5. GODOT EDIT  → Build the feature
6. SCREENSHOTS → Verify it works
7. TRELLO      → Move to Done
```

### B. New Art Asset
```
1. TRELLO      → Card: "Create [asset] sprite"
2. HUGGINGFACE → Generate base image
3. IMAGE PROC  → Resize/crop to spec
4. GODOT EDIT  → Import and place in scene
5. SCREENSHOTS → Verify in-game
6. TRELLO      → Done + attach screenshot
```

### C. UI Implementation
```
1. FIGMA       → Design the UI
2. FIGMA MCP   → Extract layout data
3. GSAP        → Get animation patterns
4. GODOT EDIT  → Build UI scene
5. LOTTIE      → Add polish animations
6. SCREENSHOTS → Verify appearance
7. TRELLO      → Done
```

### D. Bug Fix
```
1. TRELLO      → Bug card with description
2. SCREENSHOTS → Reproduce and capture
3. SEQUENTIAL  → Debug complex issues
4. GODOT EDIT  → Apply fix
5. SCREENSHOTS → Verify fix
6. TRELLO      → Close bug card
```

### E. Session Start
```
1. MEMORY      → Read project state
2. TRELLO      → Check current sprint
3. TRELLO      → Pick next task
4. [Work using appropriate MCPs]
5. MEMORY      → Save progress
```

---

## COMMAND QUICK REFERENCE

### Trello
```
"Show my Trello boards"
"Create card: [title] in [list]"
"What's in progress?"
"Move [card] to testing"
```

### Memory
```
"Remember that [decision]"
"What do we know about [topic]?"
"Store: [entity] relates to [entity]"
```

### Godot
```
"Run the game"
"Take a screenshot"
"Create scene: [name]"
"Add node: [type] to [scene]"
```

### Assets
```
"Generate sprite: [description]"
"Resize [image] to [dimensions]"
"Search Lottie for [animation]"
```

---

## MAINTENANCE

### Weekly
- Review Trello board, archive Done cards
- Update Memory with week's decisions
- Clean up unused generated assets

### Per Sprint
- Plan sprint in Trello
- Review Memory for context
- Update this workflow if needed

---

*Last Updated: December 28, 2025*
*Version: 1.0*
