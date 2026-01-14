---
name: ralph-autonomous-loop
description: Use when user wants to run an autonomous development loop overnight or for extended periods without supervision - Ralph wraps Claude Code in a bash loop with intelligent exit detection
---

# Ralph Autonomous Development Loop

## Overview

Ralph is Geoffrey Huntley's technique for running Claude Code autonomously in continuous loops until a project is complete. It's a bash wrapper, NOT an MCP.

**Location:** `C:/Users/Conner/Downloads/ralph-claude-code/`

**Announce at start:** "I'm using the ralph-autonomous-loop skill to help you set up autonomous development."

## When to Use Ralph

- User wants to "let Claude work overnight"
- User wants autonomous development without babysitting
- User has a clear PRD/specification they want implemented
- User wants batch processing of many tasks
- User says "run this until done" or "work autonomously"

## When NOT to Use Ralph

- Interactive development (use normal Claude Code)
- Quick fixes or single tasks
- When user wants to review each change
- Exploratory work without clear requirements

## Ralph Commands

### One-Time Installation (if not already done)
```bash
cd C:/Users/Conner/Downloads/ralph-claude-code
./install.sh
```

### Per-Project Setup

**Option A: Import existing PRD**
```bash
ralph-import requirements.md my-project
cd my-project
ralph --monitor
```

**Option B: Manual setup**
```bash
ralph-setup my-project
cd my-project
# Edit PROMPT.md with project goals
# Edit @fix_plan.md with prioritized tasks
ralph --monitor
```

### Running Ralph
```bash
ralph --monitor              # Recommended: tmux monitoring
ralph --verbose              # Show detailed progress
ralph --timeout 30           # 30-minute timeout for complex tasks
ralph --calls 50             # Limit API calls per hour
ralph --status               # Check current status
```

### Monitoring & Control
```bash
ralph-monitor                # Live dashboard (separate terminal)
tmux list-sessions           # View active sessions
tmux attach -t <name>        # Reattach to session
# Ctrl+B then D              # Detach (keeps Ralph running)
```

## Project Structure Ralph Creates

```
my-project/
├── PROMPT.md           # Main instructions for Ralph
├── @fix_plan.md        # Prioritized task list
├── @AGENT.md           # Build/run instructions
├── specs/              # Specifications
├── src/                # Source code
├── logs/               # Execution logs
└── docs/generated/     # Auto-generated docs
```

## How Ralph Knows When to Stop

1. **Dual-condition exit:** Requires BOTH completion indicators AND explicit `EXIT_SIGNAL: true`
2. All tasks in `@fix_plan.md` marked complete
3. Multiple consecutive "done" signals
4. Rate limit reached (prompts user to wait or exit)
5. Circuit breaker opens (stuck loop detected)

## Key Features

| Feature | Description |
|---------|-------------|
| Rate Limiting | 100 calls/hour default, configurable |
| Session Continuity | Preserves context across loops with `--continue` |
| Circuit Breaker | Detects stuck loops, prevents infinite runs |
| 5-Hour API Limit | Detects and prompts for action |
| tmux Integration | Live monitoring dashboard |

## Helping User Set Up Ralph

### Step 1: Check Installation
```bash
which ralph || echo "Not installed"
```

### Step 2: If Not Installed
```bash
cd C:/Users/Conner/Downloads/ralph-claude-code
./install.sh
```

### Step 3: Help Create Project
- If user has PRD: Use `ralph-import`
- If starting fresh: Use `ralph-setup`
- Help them write clear PROMPT.md and @fix_plan.md

### Step 4: Launch
```bash
cd <project>
ralph --monitor
```

## Important Notes

- Ralph runs Claude Code in a loop - this is for AUTONOMOUS work
- User should have a clear spec/PRD before starting
- Ralph works best with well-defined tasks, not exploration
- Session expires after 24 hours by default
- Use `--reset-session` to start fresh context

## Requirements

- Bash 4.0+
- Claude Code CLI installed globally
- tmux (for monitoring)
- jq (for JSON processing)
- Git
