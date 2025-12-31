#!/usr/bin/env python3
"""Update dialogue box scene with custom dialogue frame."""

content = """[gd_scene load_steps=3 format=3 uid="uid://dialogue_box"]

[ext_resource type="Script" path="res://scripts/ui/dialogue_controller.gd" id="1_dialogue"]
[ext_resource type="Texture2D" path="res://assets/ui/frames/dialogue_frame.png" id="2_frame"]

[node name="DialogueController" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
script = ExtResource("1_dialogue")

[node name="Portrait" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = -320.0
offset_right = 220.0
offset_bottom = -120.0
grow_vertical = 0
expand_mode = 1
stretch_mode = 5

[node name="DialogueBox" type="Control" parent="."]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -450.0
offset_top = -160.0
offset_right = 450.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 0

[node name="FrameBackground" type="NinePatchRect" parent="DialogueBox"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("2_frame")
patch_margin_left = 80
patch_margin_top = 40
patch_margin_right = 80
patch_margin_bottom = 40

[node name="Content" type="MarginContainer" parent="DialogueBox"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 30
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 30
theme_override_constants/margin_bottom = 20

[node name="VBox" type="VBoxContainer" parent="DialogueBox/Content"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="SpeakerLabel" type="Label" parent="DialogueBox/Content/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.95, 0.85, 0.6, 1)
theme_override_font_sizes/font_size = 22
text = "Speaker"

[node name="HSeparator" type="HSeparator" parent="DialogueBox/Content/VBox"]
layout_mode = 2

[node name="TextLabel" type="RichTextLabel" parent="DialogueBox/Content/VBox"]
custom_minimum_size = Vector2(0, 80)
layout_mode = 2
theme_override_colors/default_color = Color(0.9, 0.85, 0.75, 1)
theme_override_font_sizes/normal_font_size = 18
bbcode_enabled = true
text = "Dialogue text goes here..."
fit_content = true

[node name="ContinueIndicator" type="Control" parent="DialogueBox"]
visible = false
layout_mode = 1
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -40.0
offset_top = -40.0
grow_horizontal = 0
grow_vertical = 0

[node name="Arrow" type="Label" parent="DialogueBox/ContinueIndicator"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -15.0
offset_top = -15.0
offset_right = 15.0
offset_bottom = 15.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.95, 0.85, 0.6, 1)
theme_override_font_sizes/font_size = 24
text = "▼"
horizontal_alignment = 1
vertical_alignment = 1

[node name="ChoicesContainer" type="VBoxContainer" parent="."]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -100.0
offset_right = 150.0
offset_bottom = 100.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 10
"""

import os
path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scenes", "ui", "dialogue_box.tscn")
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print(f"Updated: {path}")
