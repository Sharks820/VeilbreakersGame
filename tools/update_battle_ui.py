#!/usr/bin/env python3
"""Update battle UI scene with action icons."""

content = """[gd_scene load_steps=10 format=3 uid="uid://battle_ui"]

[ext_resource type="Script" path="res://scripts/ui/battle_ui_controller.gd" id="1_controller"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/attack.png" id="2_attack"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/skill.png" id="3_skill"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/item.png" id="4_item"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/defend.png" id="5_defend"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/flee.png" id="6_flee"]
[ext_resource type="Texture2D" path="res://assets/ui/icons/actions/special.png" id="7_purify"]
[ext_resource type="Texture2D" path="res://assets/ui/frames/panel_frame.png" id="8_panel"]
[ext_resource type="Theme" path="res://assets/ui/theme/veilbreakers_theme.tres" id="9_theme"]

[node name="BattleUI" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme = ExtResource("9_theme")
script = ExtResource("1_controller")

[node name="TopBar" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 60.0
grow_horizontal = 2

[node name="HBoxContainer" type="HBoxContainer" parent="TopBar"]
layout_mode = 2
theme_override_constants/separation = 20

[node name="TurnOrderLabel" type="Label" parent="TopBar/HBoxContainer"]
layout_mode = 2
text = "Turn Order:"

[node name="TurnOrderDisplay" type="HBoxContainer" parent="TopBar/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 5

[node name="BattleInfoLabel" type="Label" parent="TopBar/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 10
text = "Round 1"

[node name="PartyPanel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -200.0
grow_horizontal = 2
grow_vertical = 0

[node name="VBoxContainer" type="VBoxContainer" parent="PartyPanel"]
layout_mode = 2

[node name="PartyStatusContainer" type="HBoxContainer" parent="PartyPanel/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 20

[node name="ActionMenu" type="HBoxContainer" parent="PartyPanel/VBoxContainer"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 10

[node name="AttackButton" type="Button" parent="PartyPanel/VBoxContainer/ActionMenu"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="PartyPanel/VBoxContainer/ActionMenu/AttackButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="PartyPanel/VBoxContainer/ActionMenu/AttackButton/VBox"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("2_attack")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="PartyPanel/VBoxContainer/ActionMenu/AttackButton/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Attack"
horizontal_alignment = 1

[node name="SkillButton" type="Button" parent="PartyPanel/VBoxContainer/ActionMenu"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="PartyPanel/VBoxContainer/ActionMenu/SkillButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="PartyPanel/VBoxContainer/ActionMenu/SkillButton/VBox"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("3_skill")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="PartyPanel/VBoxContainer/ActionMenu/SkillButton/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Skills"
horizontal_alignment = 1

[node name="PurifyButton" type="Button" parent="PartyPanel/VBoxContainer/ActionMenu"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="PartyPanel/VBoxContainer/ActionMenu/PurifyButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="PartyPanel/VBoxContainer/ActionMenu/PurifyButton/VBox"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("7_purify")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="PartyPanel/VBoxContainer/ActionMenu/PurifyButton/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Purify"
horizontal_alignment = 1

[node name="ItemButton" type="Button" parent="PartyPanel/VBoxContainer/ActionMenu"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="PartyPanel/VBoxContainer/ActionMenu/ItemButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="PartyPanel/VBoxContainer/ActionMenu/ItemButton/VBox"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("4_item")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="PartyPanel/VBoxContainer/ActionMenu/ItemButton/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Item"
horizontal_alignment = 1

[node name="DefendButton" type="Button" parent="PartyPanel/VBoxContainer/ActionMenu"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="PartyPanel/VBoxContainer/ActionMenu/DefendButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="PartyPanel/VBoxContainer/ActionMenu/DefendButton/VBox"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("5_defend")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="PartyPanel/VBoxContainer/ActionMenu/DefendButton/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Defend"
horizontal_alignment = 1

[node name="FleeButton" type="Button" parent="PartyPanel/VBoxContainer/ActionMenu"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="PartyPanel/VBoxContainer/ActionMenu/FleeButton"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
alignment = 1

[node name="Icon" type="TextureRect" parent="PartyPanel/VBoxContainer/ActionMenu/FleeButton/VBox"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("6_flee")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="PartyPanel/VBoxContainer/ActionMenu/FleeButton/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Flee"
horizontal_alignment = 1

[node name="EnemyInfoPanel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -300.0
offset_top = 80.0
offset_right = -20.0
offset_bottom = 280.0
grow_horizontal = 0

[node name="VBoxContainer" type="VBoxContainer" parent="EnemyInfoPanel"]
layout_mode = 2

[node name="EnemyNameLabel" type="Label" parent="EnemyInfoPanel/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "Enemy Name"
horizontal_alignment = 1

[node name="EnemyHPBar" type="ProgressBar" parent="EnemyInfoPanel/VBoxContainer"]
custom_minimum_size = Vector2(0, 25)
layout_mode = 2
max_value = 1.0
value = 1.0
show_percentage = false

[node name="EnemyHPLabel" type="Label" parent="EnemyInfoPanel/VBoxContainer"]
layout_mode = 2
text = "HP: 100/100"
horizontal_alignment = 1

[node name="CorruptionBar" type="ProgressBar" parent="EnemyInfoPanel/VBoxContainer"]
custom_minimum_size = Vector2(0, 20)
layout_mode = 2
max_value = 1.0
value = 0.8
show_percentage = false

[node name="CorruptionLabel" type="Label" parent="EnemyInfoPanel/VBoxContainer"]
layout_mode = 2
text = "Corruption: 80%"
horizontal_alignment = 1

[node name="StatusEffectsContainer" type="HBoxContainer" parent="EnemyInfoPanel/VBoxContainer"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 5

[node name="SkillMenu" type="PanelContainer" parent="."]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -150.0
offset_right = 200.0
offset_bottom = 150.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="SkillMenu"]
layout_mode = 2

[node name="SkillMenuTitle" type="Label" parent="SkillMenu/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "Skills"
horizontal_alignment = 1

[node name="SkillList" type="VBoxContainer" parent="SkillMenu/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="BackButton" type="Button" parent="SkillMenu/VBoxContainer"]
layout_mode = 2
text = "Back"

[node name="ItemMenu" type="PanelContainer" parent="."]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -150.0
offset_right = 200.0
offset_bottom = 150.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="ItemMenu"]
layout_mode = 2

[node name="ItemMenuTitle" type="Label" parent="ItemMenu/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "Items"
horizontal_alignment = 1

[node name="ItemList" type="VBoxContainer" parent="ItemMenu/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="BackButton" type="Button" parent="ItemMenu/VBoxContainer"]
layout_mode = 2
text = "Back"

[node name="TargetSelector" type="Control" parent="."]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="TargetIndicator" type="Sprite2D" parent="TargetSelector"]

[node name="TargetNameLabel" type="Label" parent="TargetSelector"]
offset_left = -50.0
offset_top = -30.0
offset_right = 50.0
text = "Target"
horizontal_alignment = 1

[node name="MessageBox" type="PanelContainer" parent="."]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -50.0
offset_right = 300.0
offset_bottom = 50.0
grow_horizontal = 2
grow_vertical = 2

[node name="MessageLabel" type="Label" parent="MessageBox"]
layout_mode = 2
text = "Battle message here..."
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 2

[node name="VictoryScreen" type="ColorRect" parent="."]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.7)

[node name="VictoryPanel" type="PanelContainer" parent="VictoryScreen"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -250.0
offset_top = -200.0
offset_right = 250.0
offset_bottom = 200.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="VictoryScreen/VictoryPanel"]
layout_mode = 2

[node name="VictoryTitle" type="Label" parent="VictoryScreen/VictoryPanel/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 36
text = "VICTORY!"
horizontal_alignment = 1

[node name="RewardsContainer" type="VBoxContainer" parent="VictoryScreen/VictoryPanel/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="EXPLabel" type="Label" parent="VictoryScreen/VictoryPanel/VBoxContainer/RewardsContainer"]
layout_mode = 2
text = "EXP Gained: 100"

[node name="GoldLabel" type="Label" parent="VictoryScreen/VictoryPanel/VBoxContainer/RewardsContainer"]
layout_mode = 2
text = "Gold: 50"

[node name="ItemsLabel" type="Label" parent="VictoryScreen/VictoryPanel/VBoxContainer/RewardsContainer"]
layout_mode = 2
text = "Items: Potion x1"

[node name="ContinueButton" type="Button" parent="VictoryScreen/VictoryPanel/VBoxContainer"]
layout_mode = 2
text = "Continue"

[node name="DefeatScreen" type="ColorRect" parent="."]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.8)

[node name="DefeatPanel" type="PanelContainer" parent="DefeatScreen"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -100.0
offset_right = 200.0
offset_bottom = 100.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="DefeatScreen/DefeatPanel"]
layout_mode = 2

[node name="DefeatTitle" type="Label" parent="DefeatScreen/DefeatPanel/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 36
text = "DEFEAT"
horizontal_alignment = 1

[node name="DefeatMessage" type="Label" parent="DefeatScreen/DefeatPanel/VBoxContainer"]
layout_mode = 2
text = "Your party has fallen..."
horizontal_alignment = 1
autowrap_mode = 2

[node name="ButtonsContainer" type="HBoxContainer" parent="DefeatScreen/DefeatPanel/VBoxContainer"]
layout_mode = 2
alignment = 1

[node name="RetryButton" type="Button" parent="DefeatScreen/DefeatPanel/VBoxContainer/ButtonsContainer"]
layout_mode = 2
text = "Retry"

[node name="TitleButton" type="Button" parent="DefeatScreen/DefeatPanel/VBoxContainer/ButtonsContainer"]
layout_mode = 2
text = "Title Screen"
"""

import os
path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scenes", "battle", "battle_ui.tscn")
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print(f"Updated: {path}")
