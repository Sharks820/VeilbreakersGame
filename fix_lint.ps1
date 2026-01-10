$path = "C:/Users/Conner/OneDrive/Documents/VeilbreakersGame/scripts/ui/battle_ui_controller.gd"
$content = Get-Content $path -Raw

# Fix unused parameters - prefix with underscore
$content = $content -replace 'func _build_victory_rewards_display\(party_data:', 'func _build_victory_rewards_display(_party_data:'
$content = $content -replace 'func show_defeat\(data:', 'func show_defeat(_data:'
$content = $content -replace 'func flash_character\(character: CharacterBase, color: Color', 'func flash_character(_character: CharacterBase, _color: Color'
$content = $content -replace 'func shake_screen\(intensity: float, duration: float', 'func shake_screen(_intensity: float, _duration: float'
$content = $content -replace 'func _on_character_sprite_unhovered\(character: CharacterBase', 'func _on_character_sprite_unhovered(_character: CharacterBase'
$content = $content -replace 'func _on_capture_attempt_started\(monster: CharacterBase, vessel_tier: int', 'func _on_capture_attempt_started(monster: CharacterBase, _vessel_tier: int'
$content = $content -replace 'func _on_capture_succeeded\(monster: CharacterBase, bonus_data: Dictionary', 'func _on_capture_succeeded(monster: CharacterBase, _bonus_data: Dictionary'

# Fix unused variables - prefix with underscore
$content = $content -replace 'var original_color := ', 'var _original_color := '
$content = $content -replace 'var old_percent := ', 'var _old_percent := '

# Fix shadowed variables - rename to avoid conflicts
# 'char' shadows built-in function
$content = $content -replace '\bvar char := ', 'var char_item := '
$content = $content -replace '\bfor char in ', 'for char_item in '
$content = $content -replace '\bchar\.', 'char_item.'
$content = $content -replace '\bchar\)', 'char_item)'
$content = $content -replace '\bchar,', 'char_item,'

# 'name' shadows Node.name - be careful with context
$content = $content -replace 'var name := monster\.display_name', 'var monster_name := monster.display_name'
$content = $content -replace 'var name := target\.display_name', 'var target_name := target.display_name'
$content = $content -replace '\t\tname \+ " captured', "`t`tmonster_name + "" captured"
$content = $content -replace '\t\tname \+ " escaped', "`t`ttarget_name + "" escaped"

# 'position' shadows Control.position - rename in function parameters
$content = $content -replace 'func show_damage_number\(.*position: Vector2', 'func show_damage_number(amount: int, target_pos: Vector2'

# Fix trailing whitespace - remove whitespace at end of lines
$content = $content -replace '[ \t]+\r?\n', "`n"

# Fix incompatible ternary - ensure both branches return same type
# Line 710 and 3971 - these are likely mixing int and float or similar
# Need to read the specific lines to fix properly

[System.IO.File]::WriteAllText($path, $content)
Write-Host "Basic fixes applied"
