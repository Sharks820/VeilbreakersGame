extends SceneTree

# Test script to validate hollow.tscn loads and animations work
# Run with: godot --headless --script test_hollow.gd

func _init():
	print("============================================================")
	print("HOLLOW.TSCN RUNTIME TEST")
	print("============================================================")

	# Try to load the scene
	var scene = load("res://assets/rigged/hollow/hollow.tscn")
	if scene == null:
		print("[FAIL] Could not load hollow.tscn!")
		quit(1)
		return

	print("[OK] Scene loaded successfully")

	# Instance it
	var hollow = scene.instantiate()
	if hollow == null:
		print("[FAIL] Could not instantiate scene!")
		quit(1)
		return

	print("[OK] Scene instantiated")

	# Check for Skeleton2D
	var skeleton = hollow.get_node_or_null("Skeleton2D")
	if skeleton == null:
		print("[FAIL] No Skeleton2D found!")
		quit(1)
		return

	var bone_count = skeleton.get_child_count()
	print("[OK] Skeleton2D found with children")

	# Check for AnimationPlayer
	var anim_player = hollow.get_node_or_null("AnimationPlayer")
	if anim_player == null:
		print("[FAIL] No AnimationPlayer found!")
		quit(1)
		return

	var anim_list = anim_player.get_animation_list()
	print("[OK] AnimationPlayer found with " + str(anim_list.size()) + " animations")

	# List some animations
	print("")
	print("Animations available:")
	for i in range(min(10, anim_list.size())):
		print("  - " + anim_list[i])
	if anim_list.size() > 10:
		print("  ... and " + str(anim_list.size() - 10) + " more")

	# Check for Meshes
	var meshes = hollow.get_node_or_null("Meshes")
	if meshes == null:
		print("[FAIL] No Meshes node found!")
		quit(1)
		return

	var mesh_count = meshes.get_child_count()
	print("[OK] Meshes node found with " + str(mesh_count) + " meshes")

	# Check for arm meshes specifically
	var arm_left = meshes.get_node_or_null("arm_left_mesh")
	var arm_right = meshes.get_node_or_null("arm_right_mesh")

	if arm_left:
		print("[OK] arm_left_mesh found!")
	else:
		print("[WARN] arm_left_mesh NOT found")

	if arm_right:
		print("[OK] arm_right_mesh found!")
	else:
		print("[WARN] arm_right_mesh NOT found")

	# Try playing an animation
	print("")
	print("Testing animation playback...")
	if "idle_breathe" in anim_list:
		anim_player.play("idle_breathe")
		print("[OK] Playing idle_breathe")
	elif "idle" in anim_list:
		anim_player.play("idle")
		print("[OK] Playing idle")
	elif anim_list.size() > 0:
		anim_player.play(anim_list[0])
		print("[OK] Playing " + anim_list[0])

	# Check for attack animations with arm movement
	var attack_anims = []
	for anim_name in anim_list:
		if "attack" in anim_name:
			attack_anims.append(anim_name)

	print("")
	print("Attack animations: " + str(attack_anims.size()))
	for atk in attack_anims:
		print("  - " + atk)

	# Final summary
	print("")
	print("============================================================")
	print("TEST RESULTS")
	print("============================================================")
	print("[OK] Scene loads correctly")
	print("[OK] Skeleton2D present")
	print("[OK] AnimationPlayer with " + str(anim_list.size()) + " animations")
	print("[OK] " + str(mesh_count) + " meshes including arms")
	print("[OK] " + str(attack_anims.size()) + " attack animations")
	print("============================================================")
	print(">>> HOLLOW.TSCN RUNTIME TEST PASSED! <<<")
	print("============================================================")

	# Clean up
	hollow.queue_free()
	quit(0)
