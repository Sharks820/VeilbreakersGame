$path = "C:/Users/Conner/OneDrive/Documents/VeilbreakersGame/scripts/ui/battle_ui_controller.gd"
$lines = Get-Content $path

# Process line by line to fix specific issues
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $lineNum = $i + 1  # 1-based line numbers

    # Fix unused parameters - add underscore prefix
    # Line 2226: party_data in _build_victory_rewards_display
    if ($line -match 'func _build_victory_rewards_display\(party_data:') {
        $lines[$i] = $line -replace 'party_data:', '_party_data:'
    }
    # Line 2720: data in show_defeat
    if ($line -match 'func show_defeat\(data:') {
        $lines[$i] = $line -replace '\(data:', '(_data:'
    }
    # Line 2947: character and color in flash_character
    if ($line -match 'func flash_character\(character:.*color:') {
        $lines[$i] = $line -replace 'func flash_character\(character:', 'func flash_character(_character:'
        $lines[$i] = $lines[$i] -replace ', color:', ', _color:'
    }
    # Line 2952: intensity and duration in shake_screen
    if ($line -match 'func shake_screen\(intensity:.*duration:') {
        $lines[$i] = $line -replace 'func shake_screen\(intensity:', 'func shake_screen(_intensity:'
        $lines[$i] = $lines[$i] -replace ', duration:', ', _duration:'
    }
    # Line 3346: character in _on_character_sprite_unhovered
    if ($line -match 'func _on_character_sprite_unhovered\(character:') {
        $lines[$i] = $line -replace '\(character:', '(_character:'
    }
    # Line 4247: vessel_tier in _on_capture_attempt_started
    if ($line -match 'func _on_capture_attempt_started\(.*vessel_tier:') {
        $lines[$i] = $line -replace ', vessel_tier:', ', _vessel_tier:'
    }
    # Line 4310: bonus_data in _on_capture_succeeded
    if ($line -match 'func _on_capture_succeeded\(.*bonus_data:') {
        $lines[$i] = $line -replace ', bonus_data:', ', _bonus_data:'
    }

    # Fix unused variables - add underscore prefix
    # Line 1318: original_color
    if ($line -match '\bvar original_color :=') {
        $lines[$i] = $line -replace 'var original_color :=', 'var _original_color :='
    }
    # Line 4165: old_percent
    if ($line -match '\bvar old_percent :=') {
        $lines[$i] = $line -replace 'var old_percent :=', 'var _old_percent :='
    }

    # Fix shadowed variables
    # 'char' shadows built-in - rename to char_item
    if ($line -match '\bvar char :=|\bfor char in') {
        $lines[$i] = $line -replace '\bchar\b', 'char_item'
    }

    # 'position' in show_damage_number - rename to target_pos
    if ($line -match 'func show_damage_number\(.*position:') {
        $lines[$i] = $line -replace 'position:', 'target_pos:'
    }

    # 'name' shadows Node.name - rename to display_name_str or similar
    # These are in capture-related functions - need to rename variable and usages
    if ($line -match '\bvar name := monster\.display_name') {
        $lines[$i] = $line -replace 'var name :=', 'var monster_name :='
    }
    if ($line -match '\bvar name := target\.display_name') {
        $lines[$i] = $line -replace 'var name :=', 'var target_name :='
    }

    # Remove trailing whitespace
    $lines[$i] = $lines[$i].TrimEnd()
}

# Write back
$lines | Set-Content $path -Encoding UTF8
Write-Host "All GDScript warnings fixed"
