#!/usr/bin/env python3
"""
VEILBREAKERS Style Validation Script
=====================================
Detects violations of the color/style constant system.

Scans all .gd files in scripts/ folder and finds:
1. Color() calls that should use Constants.COLOR_*
2. StyleBoxFlat.new() calls that should use StyleManager

Run with: python tools/validate_style_constants.py
"""

import os
import re
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import Optional

# =============================================================================
# CONFIGURATION
# =============================================================================

# Files to exclude from Color() validation (they define the constants)
COLOR_EXCLUDE_FILES = {
    "constants.gd",
    "ui_style_cache.gd",  # Legacy cache, uses Color() internally
}

# Files to exclude from StyleBoxFlat.new() validation
STYLEBOX_EXCLUDE_FILES = {
    "style_manager.gd",
    "ui_style_cache.gd",
}

# Built-in Color constants that are OK to use
BUILTIN_COLORS = {
    "Color.WHITE",
    "Color.BLACK",
    "Color.TRANSPARENT",
    "Color.RED",
    "Color.GREEN",
    "Color.BLUE",
    "Color.YELLOW",
    "Color.CYAN",
    "Color.MAGENTA",
    "Color.GRAY",
}

# Known color mappings for suggestions
# Maps common color patterns to their Constants.COLOR_* equivalents
COLOR_SUGGESTIONS = {
    # HP/MP bars
    (0.2, 0.8, 0.3): "Constants.COLOR_HP_FILL_ALLY",
    (0.8, 0.2, 0.2): "Constants.COLOR_HP_FILL_ENEMY",
    (0.15, 0.1, 0.1): "Constants.COLOR_HP_BG",
    (0.2, 0.4, 0.9): "Constants.COLOR_MP_FILL",
    (0.3, 0.5, 0.9): "Constants.COLOR_MP_FILL_ALT",
    (0.1, 0.1, 0.15): "Constants.COLOR_MP_BG",
    (0.5, 0.1, 0.6): "Constants.COLOR_CORRUPTION_FILL",
    (0.1, 0.05, 0.1): "Constants.COLOR_CORRUPTION_BG",
    
    # Text colors
    (1.0, 0.85, 0.4): "Constants.COLOR_TEXT_GOLD",
    (0.95, 0.9, 0.8): "Constants.COLOR_TEXT_PARCHMENT",
    (0.5, 0.5, 0.5): "Constants.COLOR_TEXT_DISABLED",
    (0.85, 1.0, 0.9): "Constants.COLOR_TEXT_ALLY",
    (0.95, 0.85, 0.8): "Constants.COLOR_TEXT_ENEMY",
    (1.0, 0.3, 0.3): "Constants.COLOR_TEXT_DAMAGE",
    (0.3, 1.0, 0.5): "Constants.COLOR_TEXT_HEAL",
    (1.0, 0.9, 0.2): "Constants.COLOR_TEXT_CRITICAL",
    
    # Brand colors (Pure)
    (1.0, 0.4, 0.3): "Constants.COLOR_BRAND_SAVAGE",
    (0.6, 0.7, 0.8): "Constants.COLOR_BRAND_IRON",
    (0.4, 0.9, 0.3): "Constants.COLOR_BRAND_VENOM",
    (0.3, 0.8, 1.0): "Constants.COLOR_BRAND_SURGE",
    (0.6, 0.3, 0.8): "Constants.COLOR_BRAND_DREAD",
    (0.8, 0.2, 0.4): "Constants.COLOR_BRAND_LEECH",
    
    # Panel colors
    (0.1, 0.1, 0.15): "Constants.COLOR_PANEL_DARK",
    (0.15, 0.1, 0.1): "Constants.COLOR_PANEL_DARK_RED",
    (0.1, 0.1, 0.18): "Constants.COLOR_PANEL_DARK_BLUE",
    
    # Button colors
    (0.12, 0.12, 0.15): "Constants.COLOR_BTN_NORMAL_BG",
    (0.18, 0.18, 0.22): "Constants.COLOR_BTN_HOVER_BG",
    (0.08, 0.08, 0.1): "Constants.COLOR_BTN_PRESSED_BG",
    (0.4, 0.35, 0.3): "Constants.COLOR_BTN_BORDER",
    (0.6, 0.5, 0.4): "Constants.COLOR_BTN_BORDER_HOVER",
    
    # Font colors
    (0.95, 0.9, 0.8): "Constants.COLOR_FONT_NORMAL",
    (1.0, 0.95, 0.85): "Constants.COLOR_FONT_HOVER",
    (0.6, 0.6, 0.6): "Constants.COLOR_FONT_MUTED",
    (0.7, 0.7, 0.7): "Constants.COLOR_FONT_LABEL",
    (0.7, 0.65, 0.55): "Constants.COLOR_FONT_SUBDUED",
    
    # Scrollbar
    (0.5, 0.45, 0.4): "Constants.COLOR_SCROLLBAR_GRABBER",
    (0.15, 0.12, 0.1): "Constants.COLOR_SCROLLBAR_BG",
    
    # Highlights/Glows
    (1.8, 1.8, 1.8): "Constants.COLOR_FLASH_WHITE",
    (1.5, 0.3, 0.3): "Constants.COLOR_FLASH_DAMAGE",
    (0.5, 1.5, 0.5): "Constants.COLOR_FLASH_HEAL",
    (1.3, 1.3, 1.3): "Constants.COLOR_HOVER_BRIGHTEN",
    (1.0, 1.0, 1.0): "Constants.COLOR_NORMAL",
    (0.0, 0.0, 0.0): "Constants.COLOR_TRANSPARENT (if alpha=0)",
    
    # Border colors
    (0.3, 0.5, 0.4): "Constants.COLOR_BORDER_ALLY",
    (0.5, 0.25, 0.25): "Constants.COLOR_BORDER_ENEMY",
    (0.6, 0.5, 0.3): "Constants.COLOR_BORDER_GOLD",
    (0.4, 0.35, 0.5): "Constants.COLOR_BORDER_PURPLE",
    
    # Target colors
    (0.4, 0.7, 1.0): "Constants.COLOR_TARGET_ALLY",
    (1.0, 0.4, 0.4): "Constants.COLOR_TARGET_ENEMY",
    (0.4, 1.0, 0.7): "Constants.COLOR_TARGET_SELF",
    
    # Status colors
    (0.4, 0.8, 1.0): "Constants.COLOR_STATUS_BUFF",
    (0.6, 0.2, 0.8): "Constants.COLOR_STATUS_POISON",
    (1.0, 0.5, 0.2): "Constants.COLOR_STATUS_BURN",
    (0.5, 0.8, 1.0): "Constants.COLOR_STATUS_FREEZE",
    (1.0, 1.0, 0.4): "Constants.COLOR_STATUS_STUN",
    
    # Modulate colors
    (1.3, 1.1, 0.9): "Constants.COLOR_MODULATE_HOVER",
    (2.0, 0.4, 0.4): "Constants.COLOR_MODULATE_DEATH_START",
    (1.5, 0.3, 0.3): "Constants.COLOR_MODULATE_DEATH_MID",
    (0.4, 0.4, 0.4): "Constants.COLOR_MODULATE_DEATH_FADE",
    (0.2, 0.2, 0.2): "Constants.COLOR_MODULATE_DEATH_END",
    (1.4, 1.3, 1.6): "Constants.COLOR_MODULATE_CAPTURE_GLOW",
    (2.5, 2.2, 2.8): "Constants.COLOR_MODULATE_CAPTURE_FLASH",
    (0.8, 1.4, 0.8): "Constants.COLOR_MODULATE_HEAL",
    (0.8, 0.9, 1.3): "Constants.COLOR_MODULATE_BUFF",
    (1.2, 1.0, 1.4): "Constants.COLOR_MODULATE_DEBUFF",
    
    # Sidebar colors
    (0.08, 0.1, 0.14): "Constants.COLOR_SIDEBAR_ALLY_BG",
    (0.25, 0.4, 0.35): "Constants.COLOR_SIDEBAR_ALLY_BORDER",
    (0.5, 0.85, 0.65): "Constants.COLOR_SIDEBAR_ALLY_HEADER",
    (0.12, 0.15, 0.18): "Constants.COLOR_SIDEBAR_ALLY_SLOT_BG",
    (0.3, 0.45, 0.4): "Constants.COLOR_SIDEBAR_ALLY_SLOT_BORDER",
    (0.14, 0.08, 0.08): "Constants.COLOR_SIDEBAR_ENEMY_BG",
    (0.5, 0.25, 0.25): "Constants.COLOR_SIDEBAR_ENEMY_BORDER",
    (0.9, 0.4, 0.4): "Constants.COLOR_SIDEBAR_ENEMY_HEADER",
    (0.18, 0.12, 0.12): "Constants.COLOR_SIDEBAR_ENEMY_SLOT_BG",
    (0.5, 0.3, 0.3): "Constants.COLOR_SIDEBAR_ENEMY_SLOT_BORDER",
    
    # Victory/XP colors
    (0.85, 0.7, 0.45): "Constants.COLOR_VICTORY_GOLD",
    (0.2, 0.15, 0.1): "Constants.COLOR_VICTORY_OUTLINE",
    (0.6, 0.45, 0.25): "Constants.COLOR_VICTORY_SEPARATOR",
    (0.7, 0.85, 1.0): "Constants.COLOR_STATS_HEADER",
    (1.0, 0.6, 0.4): "Constants.COLOR_STATS_DAMAGE",
    (0.6, 0.8, 1.0): "Constants.COLOR_STATS_DEFENSE",
    (0.8, 0.5, 1.0): "Constants.COLOR_STATS_CAPTURE",
    (0.08, 0.06, 0.04): "Constants.COLOR_XP_BAR_BG",
    (0.4, 0.3, 0.15): "Constants.COLOR_XP_BAR_BORDER",
    (0.4, 0.7, 0.3): "Constants.COLOR_XP_BAR_FILL",
    (0.7, 0.9, 0.7): "Constants.COLOR_XP_TEXT",
    
    # Tooltip
    (0.08, 0.08, 0.12): "Constants.COLOR_TOOLTIP_BG",
    
    # Portrait
    (0.15, 0.15, 0.2): "Constants.COLOR_PORTRAIT_BG_ALLY",
    (0.2, 0.1, 0.1): "Constants.COLOR_PORTRAIT_BG_ENEMY",
    (0.6, 0.3, 0.3): "Constants.COLOR_PORTRAIT_BORDER_ENEMY",
    
    # Indicator colors
    (0.2, 0.6, 1.0): "Constants.COLOR_INDICATOR_ALLY",
    (0.8, 0.2, 0.2): "Constants.COLOR_INDICATOR_ENEMY",
    (0.6, 0.1, 0.6): "Constants.COLOR_INDICATOR_CAPTURE",
}

# StyleBoxFlat.new() suggestions based on context
STYLEBOX_SUGGESTIONS = {
    "panel": "StyleManager.panel_dark() or StyleManager.custom_panel()",
    "button": "StyleManager.button_normal/hover/pressed/disabled()",
    "hp": "StyleManager.hp_fill() or StyleManager.hp_bg()",
    "mp": "StyleManager.mp_fill() or StyleManager.mp_bg()",
    "corruption": "StyleManager.corruption_fill() or StyleManager.corruption_bg()",
    "tooltip": "StyleManager.tooltip()",
    "portrait": "StyleManager.portrait_frame()",
    "sidebar": "StyleManager.sidebar_ally/enemy()",
    "scrollbar": "StyleManager.scrollbar_grabber/bg()",
    "buff": "StyleManager.buff_panel()",
    "debuff": "StyleManager.debuff_panel()",
    "xp": "StyleManager.xp_fill() or StyleManager.xp_bg()",
    "monster": "StyleManager.monster_row()",
}


# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class Violation:
    """Represents a style violation found in code."""
    file_path: str
    line_number: int
    code: str
    suggestion: Optional[str] = None
    violation_type: str = "color"  # "color" or "stylebox"


# =============================================================================
# PARSING FUNCTIONS
# =============================================================================

def parse_color_values(color_str: str) -> Optional[tuple]:
    """
    Parse Color() call and extract RGB values.
    Returns tuple of (r, g, b) rounded to 2 decimal places, or None if can't parse.
    """
    # Match Color(r, g, b) or Color(r, g, b, a)
    match = re.search(r'Color\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)', color_str)
    if match:
        try:
            r = round(float(match.group(1)), 2)
            g = round(float(match.group(2)), 2)
            b = round(float(match.group(3)), 2)
            return (r, g, b)
        except ValueError:
            return None
    return None


def find_color_suggestion(color_str: str) -> Optional[str]:
    """Find a suggestion for a Color() call based on its values."""
    values = parse_color_values(color_str)
    if values:
        # Try exact match first
        if values in COLOR_SUGGESTIONS:
            return COLOR_SUGGESTIONS[values]
        
        # Try close match (within 0.05 tolerance)
        for known_values, suggestion in COLOR_SUGGESTIONS.items():
            if all(abs(v1 - v2) < 0.05 for v1, v2 in zip(values, known_values)):
                return f"{suggestion} (approximate)"
    
    return None


def find_stylebox_suggestion(line: str, context_lines: list) -> Optional[str]:
    """Find a suggestion for StyleBoxFlat.new() based on context."""
    # Check the line and surrounding context for keywords
    search_text = line.lower()
    for ctx in context_lines:
        search_text += " " + ctx.lower()
    
    for keyword, suggestion in STYLEBOX_SUGGESTIONS.items():
        if keyword in search_text:
            return suggestion
    
    return "StyleManager.custom_panel() or appropriate StyleManager method"


def is_builtin_color(line: str) -> bool:
    """Check if the line uses a built-in Color constant."""
    for builtin in BUILTIN_COLORS:
        if builtin in line:
            return True
    return False


def is_constants_color(line: str) -> bool:
    """Check if the line already uses Constants.COLOR_*."""
    return "Constants.COLOR_" in line


def is_color_from_method(line: str) -> bool:
    """Check if Color is from a method call like .get_color() or Constants.get_brand_color()."""
    # Skip lines where Color() is the result of a method
    patterns = [
        r'\.get_color\s*\(',
        r'Constants\.get_\w+_color\s*\(',
        r'get_brand_color\s*\(',
        r'get_hp_color\s*\(',
        r'get_highlight_color\s*\(',
        r'get_glow_color\s*\(',
        r'get_panel_color\s*\(',
        r'get_border_color\s*\(',
        r'get_indicator_color\s*\(',
        r'get_status_color\s*\(',
    ]
    for pattern in patterns:
        if re.search(pattern, line):
            return True
    return False


# =============================================================================
# SCANNING FUNCTIONS
# =============================================================================

def scan_file_for_colors(file_path: Path) -> list[Violation]:
    """Scan a file for Color() violations."""
    violations = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        return violations
    
    for i, line in enumerate(lines, 1):
        # Skip comments
        stripped = line.strip()
        if stripped.startswith("#") or stripped.startswith("##"):
            continue
        
        # Find Color() calls with numeric arguments
        # Match Color(number, number, number) patterns
        color_matches = re.finditer(r'Color\s*\(\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+', line)
        
        for match in color_matches:
            # Skip if it's using a built-in constant
            if is_builtin_color(line):
                continue
            
            # Skip if already using Constants.COLOR_*
            if is_constants_color(line):
                continue
            
            # Skip if it's from a helper method
            if is_color_from_method(line):
                continue
            
            # Extract the full Color() call
            start = match.start()
            # Find the closing parenthesis
            paren_count = 0
            end = start
            for j, char in enumerate(line[start:]):
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
                    if paren_count == 0:
                        end = start + j + 1
                        break
            
            color_code = line[start:end]
            suggestion = find_color_suggestion(color_code)
            
            violations.append(Violation(
                file_path=str(file_path),
                line_number=i,
                code=color_code,
                suggestion=suggestion,
                violation_type="color"
            ))
    
    return violations


def scan_file_for_styleboxes(file_path: Path) -> list[Violation]:
    """Scan a file for StyleBoxFlat.new() violations."""
    violations = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        return violations
    
    for i, line in enumerate(lines, 1):
        # Skip comments
        stripped = line.strip()
        if stripped.startswith("#") or stripped.startswith("##"):
            continue
        
        # Find StyleBoxFlat.new() calls
        if "StyleBoxFlat.new()" in line:
            # Get context (surrounding lines)
            context_start = max(0, i - 3)
            context_end = min(len(lines), i + 3)
            context_lines = lines[context_start:context_end]
            
            suggestion = find_stylebox_suggestion(line, context_lines)
            
            violations.append(Violation(
                file_path=str(file_path),
                line_number=i,
                code=stripped,
                suggestion=suggestion,
                violation_type="stylebox"
            ))
    
    return violations


def scan_directory(scripts_dir: Path) -> tuple[list[Violation], list[Violation]]:
    """Scan all .gd files in the scripts directory."""
    color_violations = []
    stylebox_violations = []
    
    for gd_file in scripts_dir.rglob("*.gd"):
        filename = gd_file.name.lower()
        relative_path = gd_file.relative_to(scripts_dir.parent)
        
        # Check for Color() violations (unless excluded)
        if filename not in COLOR_EXCLUDE_FILES:
            color_violations.extend(scan_file_for_colors(gd_file))
        
        # Check for StyleBoxFlat.new() violations (unless excluded)
        if filename not in STYLEBOX_EXCLUDE_FILES:
            stylebox_violations.extend(scan_file_for_styleboxes(gd_file))
    
    return color_violations, stylebox_violations


# =============================================================================
# REPORTING
# =============================================================================

def print_report(color_violations: list[Violation], stylebox_violations: list[Violation]) -> None:
    """Print the validation report."""
    print("=" * 60)
    print("=== STYLE VALIDATION REPORT ===")
    print("=" * 60)
    print(f"Found {len(color_violations)} Color() violations")
    print(f"Found {len(stylebox_violations)} StyleBoxFlat.new() violations")
    print()
    
    if color_violations:
        print("-" * 60)
        print("--- Color() Violations ---")
        print("-" * 60)
        
        # Group by file
        by_file: dict[str, list[Violation]] = {}
        for v in color_violations:
            if v.file_path not in by_file:
                by_file[v.file_path] = []
            by_file[v.file_path].append(v)
        
        for file_path, violations in sorted(by_file.items()):
            print(f"\n{file_path}:")
            for v in sorted(violations, key=lambda x: x.line_number):
                print(f"  Line {v.line_number}: {v.code}")
                if v.suggestion:
                    print(f"    -> Suggest: {v.suggestion}")
        print()
    
    if stylebox_violations:
        print("-" * 60)
        print("--- StyleBoxFlat.new() Violations ---")
        print("-" * 60)
        
        # Group by file
        by_file: dict[str, list[Violation]] = {}
        for v in stylebox_violations:
            if v.file_path not in by_file:
                by_file[v.file_path] = []
            by_file[v.file_path].append(v)
        
        for file_path, violations in sorted(by_file.items()):
            print(f"\n{file_path}:")
            for v in sorted(violations, key=lambda x: x.line_number):
                print(f"  Line {v.line_number}: {v.code}")
                if v.suggestion:
                    print(f"    -> Suggest: {v.suggestion}")
        print()
    
    if not color_violations and not stylebox_violations:
        print()
        print("No violations found! All code follows the style constant system.")
        print()
    
    print("=" * 60)
    print("=== END OF REPORT ===")
    print("=" * 60)
    
    # Summary
    total = len(color_violations) + len(stylebox_violations)
    if total > 0:
        print(f"\nTotal violations: {total}")
        print("\nTo fix these violations:")
        print("  1. Replace Color() calls with Constants.COLOR_* constants")
        print("  2. Replace StyleBoxFlat.new() with StyleManager methods")
        print("  3. If a color doesn't exist in Constants, add it there first")
        print("\nSee scripts/utils/constants.gd for available COLOR_* constants")
        print("See scripts/autoload/style_manager.gd for available style methods")


# =============================================================================
# MAIN
# =============================================================================

def main() -> int:
    """Main entry point."""
    # Find the scripts directory
    script_dir = Path(__file__).parent.parent / "scripts"
    
    if not script_dir.exists():
        # Try relative to current directory
        script_dir = Path("scripts")
    
    if not script_dir.exists():
        print(f"Error: Could not find scripts directory", file=sys.stderr)
        print(f"Tried: {script_dir.absolute()}", file=sys.stderr)
        return 1
    
    print(f"Scanning: {script_dir.absolute()}")
    print(f"Excluding from Color() check: {', '.join(COLOR_EXCLUDE_FILES)}")
    print(f"Excluding from StyleBoxFlat check: {', '.join(STYLEBOX_EXCLUDE_FILES)}")
    print()
    
    color_violations, stylebox_violations = scan_directory(script_dir)
    print_report(color_violations, stylebox_violations)
    
    # Return non-zero if violations found (useful for CI)
    return 1 if (color_violations or stylebox_violations) else 0


if __name__ == "__main__":
    sys.exit(main())
