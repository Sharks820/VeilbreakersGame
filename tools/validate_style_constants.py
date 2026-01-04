#!/usr/bin/env python3
"""
Validate Style Constants Usage
Scans GDScript files to find hardcoded Color() and StyleBoxFlat.new() calls
that should use centralized constants.

Run: python tools/validate_style_constants.py
"""

import os
import re
from pathlib import Path

# Files to exclude from Color() check (they define the constants)
COLOR_EXCLUDE = ['constants.gd', 'ui_style_cache.gd']

# Files to exclude from StyleBoxFlat check (they create styles intentionally)
STYLEBOX_EXCLUDE = ['ui_style_cache.gd', 'style_manager.gd']

# Known color mappings for suggestions
COLOR_MAPPINGS = {
    'Color(0.1, 0.1, 0.15, 0.85)': 'Constants.COLOR_PANEL_DARK',
    'Color(0.15, 0.1, 0.1, 0.85)': 'Constants.COLOR_PANEL_DARK_RED',
    'Color(0.12, 0.12, 0.15, 0.95)': 'Constants.COLOR_BTN_NORMAL_BG',
    'Color(0.18, 0.18, 0.22, 0.98)': 'Constants.COLOR_BTN_HOVER_BG',
    'Color(0.2, 0.8, 0.3, 1.0)': 'Constants.COLOR_HP_FILL_ALLY',
    'Color(0.8, 0.2, 0.2, 1.0)': 'Constants.COLOR_HP_FILL_ENEMY',
    'Color(0.15, 0.1, 0.1, 0.9)': 'Constants.COLOR_HP_BG',
    'Color(0.2, 0.4, 0.9, 1.0)': 'Constants.COLOR_MP_FILL',
    'Color(0.1, 0.1, 0.15, 0.9)': 'Constants.COLOR_MP_BG',
    'Color(0.5, 0.1, 0.6, 1.0)': 'Constants.COLOR_CORRUPTION_FILL',
    'Color(0.1, 0.05, 0.1, 0.9)': 'Constants.COLOR_CORRUPTION_BG',
    'Color(0.95, 0.9, 0.8)': 'Constants.COLOR_TEXT_PARCHMENT',
    'Color(0.5, 0.5, 0.5)': 'Constants.COLOR_TEXT_DISABLED',
    'Color(0.6, 0.6, 0.6)': 'Constants.COLOR_FONT_MUTED',
    'Color(0.7, 0.7, 0.7)': 'Constants.COLOR_FONT_LABEL',
    'Color(1.0, 0.3, 0.3)': 'Constants.COLOR_TEXT_DAMAGE',
    'Color(0.3, 1.0, 0.5)': 'Constants.COLOR_TEXT_HEAL',
    'Color(0.4, 0.7, 1.0)': 'Constants.COLOR_TARGET_ALLY',
    'Color(1.0, 0.4, 0.4)': 'Constants.COLOR_TARGET_ENEMY',
    'Color(0, 0, 0, 0)': 'Constants.COLOR_TRANSPARENT',
    'Color(1.0, 1.0, 1.0, 1.0)': 'Constants.COLOR_NORMAL',
    'Color(1.3, 1.1, 0.9, 1.0)': 'Constants.COLOR_MODULATE_HOVER',
    'Color(0.5, 0.5, 0.5, 0.8)': 'Constants.COLOR_MODULATE_DISABLED',
}

def scan_file(filepath):
    """Scan a single file for violations."""
    color_violations = []
    stylebox_violations = []
    
    filename = os.path.basename(filepath)
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines, 1):
        # Skip comments
        stripped = line.strip()
        if stripped.startswith('#'):
            continue
            
        # Check for Color() calls (exclude files that define constants)
        if filename not in COLOR_EXCLUDE:
            # Match Color(...) but not Constants.COLOR_*
            color_matches = re.findall(r'(?<!Constants\.)Color\([^)]+\)', line)
            for match in color_matches:
                # Skip Color.WHITE, Color.BLACK etc (built-in colors)
                if not re.match(r'Color\.[A-Z]+', match):
                    suggestion = COLOR_MAPPINGS.get(match, None)
                    color_violations.append((i, match, suggestion))
        
        # Check for StyleBoxFlat.new() calls
        if filename not in STYLEBOX_EXCLUDE:
            if 'StyleBoxFlat.new()' in line:
                stylebox_violations.append((i, line.strip()))
    
    return color_violations, stylebox_violations

def main():
    scripts_dir = Path(__file__).parent.parent / 'scripts'
    print(f"Scanning: {scripts_dir}")
    print(f"Excluding from Color() check: {', '.join(COLOR_EXCLUDE)}")
    print(f"Excluding from StyleBoxFlat check: {', '.join(STYLEBOX_EXCLUDE)}")
    print()
    
    all_color_violations = {}
    all_stylebox_violations = {}
    total_colors = 0
    total_styleboxes = 0
    
    for root, dirs, files in os.walk(scripts_dir):
        for file in files:
            if file.endswith('.gd'):
                filepath = os.path.join(root, file)
                colors, styleboxes = scan_file(filepath)
                
                if colors:
                    all_color_violations[filepath] = colors
                    total_colors += len(colors)
                if styleboxes:
                    all_stylebox_violations[filepath] = styleboxes
                    total_styleboxes += len(styleboxes)
    
    # Print report
    print("=" * 60)
    print("=== STYLE VALIDATION REPORT ===")
    print("=" * 60)
    print(f"Found {total_colors} Color() violations")
    print(f"Found {total_styleboxes} StyleBoxFlat.new() violations")
    print()
    
    print("-" * 60)
    print("--- Color() Violations ---")
    print("-" * 60)
    for filepath, violations in sorted(all_color_violations.items()):
        print(f"\n{filepath}:")
        for line_num, match, suggestion in violations:
            print(f"  Line {line_num}: {match}")
            if suggestion:
                print(f"    -> Suggest: {suggestion}")
    
    print()
    print("-" * 60)
    print("--- StyleBoxFlat.new() Violations ---")
    print("-" * 60)
    for filepath, violations in sorted(all_stylebox_violations.items()):
        print(f"\n{filepath}:")
        for line_num, line in violations:
            print(f"  Line {line_num}: {line[:80]}...")

if __name__ == '__main__':
    main()
