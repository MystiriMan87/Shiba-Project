extends "res://scripts/enemy.gd"

@export var walk_speed = 40
@export var patrol_distance = 100
@export var attack_cooldown = 2.0

var start_position: Vector2
var patrol_direction = 1
var is_patrolling = true
#var attack_timer = 0.0

enum SkeletonState {
	IDLE,
	PATROLLING,
	CHASING,
	ATTACKING,
	RETURNING
}

var current_skeleton_state = SkeletonState.PATROLLING

func _ready():
	super._ready()
	start_position = global_position
	enemy_type = "skeleton"
	
	# Skeleton doesn't jump, so disable jump-related properties
	jump_force = 0
	jump_arc_height = 0
	
	# Debug: Check animation player setup
	print("Skeleton: Animation player found: ", animation_player != null)
	if animation_player:
		print("Skeleton: Available animations: ", animation_player.get_animation_list())
		print("Skeleton: Has walk animation: ", animation_player.has_animation("walk"))
		# Test if we can play an animation
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
			print("Skeleton: Started idle animation")
		else:
			print("Skeleton: Could not start idle animation")
	else:
		print("Skeleton: No animation player found!")
	
	# Wait a frame and check again
	await get_tree().process_frame
	if animation_player:
		print("Skeleton: After frame - Current animation: ", animation_player.current_animation)
		print("Skeleton: After frame - Is playing: ", animation_player.is_playing())

func _physics_process(delta):
	if is_dead:
		return
	
	attack_timer -= delta
	
	match current_skeleton_state:
		SkeletonState.IDLE:
			handle_idle_state(delta)
		SkeletonState.PATROLLING:
			handle_patrol_state(delta)
		SkeletonState.CHASING:
			handle_chase_state(delta)
		SkeletonState.ATTACKING:
			handle_attack_state(delta)
		SkeletonState.RETURNING:
			handle_return_state(delta)
	
	# Check for player detection
	check_player_detection()
	
	# Apply movement
	move_and_slide()

func handle_idle_state(delta):
	# Stay idle for a short time, then start patrolling
	if state_timer <= 0:
		change_skeleton_state(SkeletonState.PATROLLING)
		state_timer = 1.0
	else:
		state_timer -= delta
	
	# Play idle animation
	if animation_player and animation_player.current_animation != "idle":
		play_animation("idle")

func handle_patrol_state(delta):
	if not is_patrolling:
		return
	
	# Move in patrol direction
	var target_velocity = Vector2(walk_speed * patrol_direction, 0)
	velocity = target_velocity
	
	# Check if we've reached patrol boundary
	if abs(global_position.x - start_position.x) > patrol_distance:
		patrol_direction *= -1
		# Flip sprite based on direction
		if sprite:
			sprite.flip_h = patrol_direction < 0
	
	# Play walk animation based on direction
	if animation_player and animation_player.has_animation("walk"):
		if animation_player.current_animation != "walk":
			animation_player.play("walk")
			print("Skeleton: Playing walk animation")
	else:
		print("Skeleton: No walk animation found or no animation player")
	
	# Debug: Print current animation state
	if animation_player:
		print("Skeleton: Current animation: ", animation_player.current_animation)
		print("Skeleton: Is playing: ", animation_player.is_playing())

func handle_chase_state(delta):
	if not player:
		change_skeleton_state(SkeletonState.RETURNING)
		return
	
	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Flip sprite based on direction
	if sprite:
		sprite.flip_h = direction.x < 0
	
	# Check if player is in attack range
	if global_position.distance_to(player.global_position) <= attack_range:
		if attack_timer <= 0:
			change_skeleton_state(SkeletonState.ATTACKING)
		else:
			# Stop and wait for attack cooldown
			velocity = Vector2.ZERO
	
	# Play walk animation while chasing
	if animation_player and animation_player.has_animation("walk"):
		if animation_player.current_animation != "walk":
			animation_player.play("walk")

func handle_attack_state(delta):
	# Stop movement during attack
	velocity = Vector2.ZERO
	
	# Play attack animation
	if animation_player and animation_player.has_animation("attack"):
		if animation_player.current_animation != "attack":
			animation_player.play("attack")
	
	# Attack logic here
	if player and global_position.distance_to(player.global_position) <= attack_range:
		# Deal damage to player
		if player.has_method("take_damage"):
			player.take_damage(damage)
	
	# Return to chasing after attack
	attack_timer = attack_cooldown
	change_skeleton_state(SkeletonState.CHASING)

func handle_return_state(delta):
	# Return to start position
	var direction = (start_position - global_position).normalized()
	velocity = direction * walk_speed
	
	# Flip sprite based on direction
	if sprite:
		sprite.flip_h = direction.x < 0
	
	# Check if we've returned to start position
	if global_position.distance_to(start_position) < 10:
		change_skeleton_state(SkeletonState.PATROLLING)
		velocity = Vector2.ZERO
	
	# Play walk animation while returning
	if animation_player and animation_player.has_animation("walk"):
		if animation_player.current_animation != "walk":
			animation_player.play("walk")

func check_player_detection():
	if not detection_area:
		return
	
	var bodies = detection_area.get_overlapping_bodies()
	player = null
	
	for body in bodies:
		if body.is_in_group("player"):
			player = body
			if current_skeleton_state == SkeletonState.PATROLLING or current_skeleton_state == SkeletonState.IDLE:
				change_skeleton_state(SkeletonState.CHASING)
			break
	
	# If no player detected and we're chasing, return to patrol
	if not player and current_skeleton_state == SkeletonState.CHASING:
		change_skeleton_state(SkeletonState.RETURNING)

func change_skeleton_state(new_state: SkeletonState):
	if current_skeleton_state == new_state:
		return
	
	current_skeleton_state = new_state
	
	# Ensure sprite color is reset when changing states
	if sprite:
		sprite.modulate = Color.WHITE
	
	match new_state:
		SkeletonState.IDLE:
			velocity = Vector2.ZERO
			if animation_player and animation_player.has_animation("idle"):
				animation_player.play("idle")
		SkeletonState.PATROLLING:
			if animation_player and animation_player.has_animation("walk"):
				animation_player.play("walk")
		SkeletonState.CHASING:
			if animation_player and animation_player.has_animation("walk"):
				animation_player.play("walk")
		SkeletonState.ATTACKING:
			if animation_player and animation_player.has_animation("attack"):
				animation_player.play("attack")
		SkeletonState.RETURNING:
			if animation_player and animation_player.has_animation("walk"):
				animation_player.play("walk")

func take_damage(amount: int):
	# Show damage number near skeleton; offset up so it's visible
	if get_tree() and get_tree().current_scene:
		ParticleEffects.spawn_damage_number(get_tree().current_scene, global_position + Vector2(0, -18), amount, Color(1, 0.6, 0.3))
	# Apply base damage processing
	super.take_damage(amount)
	
	# Play hurt animation
	if animation_player and animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	# Reset sprite color after a short delay to prevent permanent red
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	# If we're patrolling and take damage, start chasing
	if current_skeleton_state == SkeletonState.PATROLLING and player:
		change_skeleton_state(SkeletonState.CHASING)

func die():
	# Play death animation once and queue free after it finishes
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		animation_player.loop_mode = AnimationPlayer.LOOP_NONE
		var length = animation_player.get_animation("death").length if animation_player.get_animation("death") else 0.5
		var t = create_tween()
		t.tween_interval(length)
		t.tween_callback(func(): super.die())
	else:
		super.die()
