extends "res://scripts/enemy.gd"

@export var walk_speed = 40
@export var patrol_distance = 100
@export var attack_cooldown = 2.0

var start_position: Vector2
var patrol_direction = 1
var is_patrolling = false
#var attack_timer = 0.0

# Local damage gating so hurt doesn't re-trigger or loop
var hurt_locked: bool = false
@export var damage_cooldown: float = 0.25
# use damage_timer from base enemy.gd

# Attack coordination
var attack_in_progress: bool = false
var damage_scheduled: bool = false

enum SkeletonState {
	IDLE,
	PATROLLING,
	CHASING,
	ATTACKING,
	RETURNING
}

var current_skeleton_state = SkeletonState.IDLE

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
	
	# Connect animation finished once
	if animation_player and not animation_player.animation_finished.is_connected(_on_anim_finished):
		animation_player.animation_finished.connect(_on_anim_finished)

	# Wait a frame and check again
	await get_tree().process_frame
	if animation_player:
		print("Skeleton: After frame - Current animation: ", animation_player.current_animation)
		print("Skeleton: After frame - Is playing: ", animation_player.is_playing())

func _physics_process(delta):
	if is_dead:
		return
	
	attack_timer -= delta
	if damage_timer > 0.0:
		damage_timer -= delta
	
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
	velocity = Vector2.ZERO
	# Always idle until player is detected
	if animation_player and animation_player.current_animation != "idle" and not hurt_locked:
		if animation_player.has_animation("idle"):
			animation_player.play("idle")

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
	
	# Play movement animation (supports either "walk" or "movement")
	_play_movement_anim()

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
	
	# Play movement animation
	_play_movement_anim()

func handle_attack_state(delta):
	# Stop movement during attack
	velocity = Vector2.ZERO
	
	# Play attack animation
	if animation_player and animation_player.has_animation("attack"):
		if not attack_in_progress:
			attack_in_progress = true
			damage_scheduled = false
			animation_player.play("attack")
			# schedule damage roughly mid-animation
			var len: float = 0.5
			if animation_player.get_animation("attack"):
				len = float(animation_player.get_animation("attack").length)
			if not damage_scheduled:
				damage_scheduled = true
				_schedule_attack_hit(max(0.05, min(len * 0.5, len - 0.05)))
	
	# Attack logic here
	# Hit is performed in _schedule_attack_hit()
	
	# Return to chasing after attack
	# Transition back happens in _on_anim_finished when attack ends

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
	
	# Play movement animation
	_play_movement_anim()

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
			if animation_player and animation_player.has_animation("idle") and not hurt_locked:
				animation_player.play("idle")
		SkeletonState.PATROLLING, SkeletonState.CHASING, SkeletonState.RETURNING:
			if not hurt_locked:
				_play_movement_anim()
		SkeletonState.ATTACKING:
			pass

func _play_movement_anim() -> void:
	if not animation_player or hurt_locked:
		return
	var movement_name := "walk"
	if not animation_player.has_animation("walk") and animation_player.has_animation("movement"):
		movement_name = "movement"
	if animation_player.has_animation(movement_name) and animation_player.current_animation != movement_name:
		animation_player.play(movement_name)

func take_damage(amount: int):
	# Show damage number near skeleton; offset up so it's visible
	if get_tree() and get_tree().current_scene:
		ParticleEffects.spawn_damage_number(get_tree().current_scene, global_position + Vector2(0, -18), amount, Color(1, 0.6, 0.3))
	# Apply base damage processing
	if hurt_locked or damage_timer > 0.0:
		return
	damage_timer = damage_cooldown
	super.take_damage(amount)
	
	# Play hurt animation
	if animation_player and animation_player.has_animation("hurt"):
		hurt_locked = true
		animation_player.play("hurt") # clip must have Loop Off in editor
		await animation_player.animation_finished
		hurt_locked = false
		# Resume appropriate animation/state
		match current_skeleton_state:
			SkeletonState.ATTACKING:
				if animation_player.has_animation("attack"):
					animation_player.play("attack")
			SkeletonState.CHASING, SkeletonState.PATROLLING, SkeletonState.RETURNING:
				if animation_player.has_animation("walk"):
					animation_player.play("walk")
			_:
				if animation_player.has_animation("idle"):
					animation_player.play("idle")
	
	# Reset sprite color after a short delay to prevent permanent red
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	# If we're patrolling and take damage, start chasing
	if current_skeleton_state == SkeletonState.PATROLLING and player:
		change_skeleton_state(SkeletonState.CHASING)

func _schedule_attack_hit(delay: float) -> void:
	if delay <= 0.0:
		_do_attack_hit()
		return
	var t = get_tree().create_timer(delay)
	await t.timeout
	_do_attack_hit()

func _do_attack_hit() -> void:
	if current_skeleton_state != SkeletonState.ATTACKING:
		return
	if player and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(int(damage), self)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "attack" and current_skeleton_state == SkeletonState.ATTACKING:
		attack_in_progress = false
		attack_timer = attack_cooldown
		change_skeleton_state(SkeletonState.CHASING)

func die():
	# Play death animation once and queue free after it finishes
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		var length := 0.5
		if animation_player.get_animation("death"):
			length = float(animation_player.get_animation("death").length)
		await get_tree().create_timer(length).timeout
		super.die()
	else:
		super.die()
