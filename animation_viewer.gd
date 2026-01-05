extends Node2D

# Animation Viewer - cycles through all animations automatically
# Press SPACE to skip to next animation
# Press ESC to quit

@onready var hollow = $Hollow
@onready var label = $Label
var anim_player: AnimationPlayer
var anim_list: PackedStringArray
var current_anim = 0
var timer = 0.0
var anim_duration = 3.0

func _ready():
	anim_player = hollow.get_node("AnimationPlayer")
	anim_list = anim_player.get_animation_list()

	print("HOLLOW ANIMATION VIEWER")
	print("=======================")
	print("Press SPACE to skip to next animation")
	print("Press ESC to quit")
	print("")
	print("Found " + str(anim_list.size()) + " animations")

	_play_current()

func _play_current():
	if current_anim >= anim_list.size():
		current_anim = 0  # Loop back

	var anim_name = anim_list[current_anim]
	anim_player.play(anim_name)
	label.text = "Animation: " + anim_name + " [" + str(current_anim + 1) + "/" + str(anim_list.size()) + "]"
	print("Playing: " + anim_name)
	timer = 0.0

func _process(delta):
	timer += delta
	if timer >= anim_duration:
		current_anim += 1
		_play_current()

func _input(event):
	if event.is_action_pressed("ui_accept"):  # SPACE
		current_anim += 1
		_play_current()
	elif event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()
