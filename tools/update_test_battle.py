#!/usr/bin/env python3
"""Update test battle scene with action icons."""

content = '''[gd_scene load_steps=8 format=3 uid="uid://test_battle_scene"]

[ext_resource type="Script" path="res://scripts/test/test_battle.gd" id="1_test"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/attack.png" id="2_attack"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/skill.png" id="3_skill"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/item.png" id="4_item"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/special.png" id="5_purify"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/defend.png" id="6_defend"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/flee.png" id="7_flee"]

[node name="TestBattle" type="Node"]
script = ExtResource("1_test")
party_size = 3
party_level = 10
enemy_count = 2
enemy_level = 8
enemy_type = "shadow_imp"
starting_corruption = 25.0
vera_state = 0

[node name="BattleSystem" type="Node" parent="."]

[node name="BattleUI" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Background" type="ColorRect" parent="BattleUI"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.1, 0.1, 0.15, 1)

[node name="PartyPanel" type="Panel" parent="BattleUI"]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -150.0
grow_horizontal = 2
grow_vertical = 0

[node name="PartyContainer" type="HBoxContainer" parent="BattleUI/PartyPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = -10.0
grow_horizontal = 2
grow_vertical = 2

[node name="EnemyPanel" type="Panel" parent="BattleUI"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 120.0
grow_horizontal = 2

[node name="EnemyContainer" type="HBoxContainer" parent="BattleUI/EnemyPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = -10.0
grow_horizontal = 2
grow_vertical = 2
alignment = 1

[node name="ActionMenu" type="HBoxContainer" parent="BattleUI"]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -350.0
offset_top = -230.0
offset_right = 350.0
offset_bottom = -160.0
grow_horizontal = 2
grow_vertical = 0
alignment = 1
theme_override_constants/separation = 15

[node name="AttackButton" type="Button" parent="BattleUI/ActionMenu"]
custom_minimum_size = Vector2(100, 65)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="BattleUI/ActionMenu/AttackButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="BattleUI/ActionMenu/AttackButton/VBox"]
custom_minimum_size = Vector2(32, 32)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("2_attack")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="BattleUI/ActionMenu/AttackButton/VBox"]
layout_mode = 2
text = "Attack"
horizontal_alignment = 1

[node name="SkillButton" type="Button" parent="BattleUI/ActionMenu"]
custom_minimum_size = Vector2(100, 65)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="BattleUI/ActionMenu/SkillButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="BattleUI/ActionMenu/SkillButton/VBox"]
custom_minimum_size = Vector2(32, 32)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("3_skill")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="BattleUI/ActionMenu/SkillButton/VBox"]
layout_mode = 2
text = "Skills"
horizontal_alignment = 1

[node name="ItemButton" type="Button" parent="BattleUI/ActionMenu"]
custom_minimum_size = Vector2(100, 65)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="BattleUI/ActionMenu/ItemButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="BattleUI/ActionMenu/ItemButton/VBox"]
custom_minimum_size = Vector2(32, 32)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("4_item")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="BattleUI/ActionMenu/ItemButton/VBox"]
layout_mode = 2
text = "Items"
horizontal_alignment = 1

[node name="PurifyButton" type="Button" parent="BattleUI/ActionMenu"]
custom_minimum_size = Vector2(100, 65)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="BattleUI/ActionMenu/PurifyButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="BattleUI/ActionMenu/PurifyButton/VBox"]
custom_minimum_size = Vector2(32, 32)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("5_purify")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="BattleUI/ActionMenu/PurifyButton/VBox"]
layout_mode = 2
text = "Purify"
horizontal_alignment = 1

[node name="DefendButton" type="Button" parent="BattleUI/ActionMenu"]
custom_minimum_size = Vector2(100, 65)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="BattleUI/ActionMenu/DefendButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="BattleUI/ActionMenu/DefendButton/VBox"]
custom_minimum_size = Vector2(32, 32)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("6_defend")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="BattleUI/ActionMenu/DefendButton/VBox"]
layout_mode = 2
text = "Defend"
horizontal_alignment = 1

[node name="FleeButton" type="Button" parent="BattleUI/ActionMenu"]
custom_minimum_size = Vector2(100, 65)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="BattleUI/ActionMenu/FleeButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="BattleUI/ActionMenu/FleeButton/VBox"]
custom_minimum_size = Vector2(32, 32)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("7_flee")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="BattleUI/ActionMenu/FleeButton/VBox"]
layout_mode = 2
text = "Flee"
horizontal_alignment = 1

[node name="VERAOverlay" type="CanvasLayer" parent="."]
layer = 10

[node name="VERAEffects" type="Control" parent="VERAOverlay"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="DebugLabel" type="Label" parent="."]
offset_left = 10.0
offset_top = 130.0
offset_right = 400.0
offset_bottom = 250.0
text = "Test Battle Debug Controls:
F5 - Restart Battle
F6 - Win Battle
F7 - Lose Battle
F8 - Cycle VERA State
F9 - Add Corruption"
'''

import os
path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scenes", "test", "test_battle.tscn")
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print(f"Updated: {path}")
