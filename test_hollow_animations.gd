extends SceneTree

# Auto-plays hollow animations - just watch!
# Run with: godot --path . --script test_hollow_animations.gd

var hollow
var anim_player: AnimationPlayer
var current_anim = 0
var anim_list: PackedStringArray
var timer = 0.0
var anim_duration = 2.5

func _init():
	print("============================================================")
	print("HOLLOW ANIMATION SHOWCASE")
	print("============================================================")
	print("")

	# Load and instance the scene
	var scene = load("res://assets/rigged/hollow/hollow.tscn")
	if scene == null:
		print("[FAIL] Could not load hollow.tscn!")
		quit(1)
		return

	hollow = scene.instantiate()
	root.add_child(hollow)

	# Center and scale
	hollow.position = Vector2(640, 450)
	hollow.scale = Vector2(0.6, 0.6)

	# Get animation player
	anim_player = hollow.get_node("AnimationPlayer")
	anim_list = anim_player.get_animation_list()

	print("Found " + str(anim_list.size()) + " animations!")
	print("Playing each for " + str(anim_duration) + " seconds...")
	print("")

	# Play first animation
	if anim_list.size() > 0:
		print("[1/" + str(anim_list.size()) + "] Playing: " + anim_list[0])
		anim_player.play(anim_list[0])

func _process(delta):
	timer += delta

	if timer >= anim_duration:
		timer = 0.0
		current_anim += 1

		if current_anim >= anim_list.size():
			print("")
			print("============================================================")
			print("ALL " + str(anim_list.size()) + " ANIMATIONS COMPLETE!")
			print("============================================================")
			quit(0)
			return

		var anim_name = anim_list[current_anim]
		print("[" + str(current_anim + 1) + "/" + str(anim_list.size()) + "] Playing: " + anim_name)
		anim_player.play(anim_name)

	return false  # Keep running
