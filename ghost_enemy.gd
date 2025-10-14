extends CharacterBody2D

@export var max_health = 4
@export var speed = 60
@export var damage = 2
@export var attack_range = 80
@export var detection_range = 120
@export var chase_duration = 5.0
@export var attack_cooldown = 2.0
@export var attack_hit_ratio = 0.45
@export var min_animation_speed = 0.5
@export var max_animation_speed = 1.3
@export var attack_speed_multiplier = 1.1
@export var separation_distance = 20.0
@export var separation_force = 200.0
@export var walk_acceleration = 300
@export var walk_friction = 200
@export var lunge_speed: float = 150.0
@export var lunge_duration: float = 0.12
@export var enemy_type: String = "Ghost"

@export_group("Wandering")
@export var wander_enabled: bool = true
@export var wander_speed: float = 30.0
@export var wander_radius: float = 100.0
@export var wander_wait_time_min: float = 2.0
@export var wander_wait_time_max: float = 5.0

var current_health
var is_dead = false
var is_attacking = false
var hurt_locked: bool = false
var damage_cooldown: float = 0.25
var damage_timer: float = 0.0
var player = null
var player_in_detection_range = false
var chase_timer = 0.0
var attack_timer = 0.0
var target_velocity = Vector2.ZERO
var is_moving = false
var last_speed_ratio: float = 0.0
var facing_direction = "down"

var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO

enum GoblinState {
	IDLE,
	WANDERING,
	WALKING,
	ATTACKING,
	DEATH
}

var current_state = GoblinState.IDLE

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea

func _ready():
	add_to_group("enemies")
	add_to_group("ghosts")
	current_health = max_health
	collision_layer = 4
	collision_mask = 1
	spawn_position = global_position

	if typeof(walk_friction) == TYPE_NIL:
		walk_friction = 200
	if typeof(walk_acceleration) == TYPE_NIL:
		walk_acceleration = 300
	if typeof(min_animation_speed) == TYPE_NIL:
		min_animation_speed = 0.5
	if typeof(max_animation_speed) == TYPE_NIL:
		max_animation_speed = 1.3
	if typeof(attack_speed_multiplier) == TYPE_NIL:
		attack_speed_multiplier = 1.1
	if typeof(separation_distance) == TYPE_NIL:
		separation_distance = 20.0
	if typeof(separation_force) == TYPE_NIL:
		separation_force = 200.0
	if typeof(speed) == TYPE_NIL:
		speed = 60
	if typeof(lunge_speed) == TYPE_NIL:
		lunge_speed = 150.0
	if typeof(lunge_duration) == TYPE_NIL:
		lunge_duration = 0.12
	if typeof(attack_range) == TYPE_NIL:
		attack_range = 80
	if typeof(detection_range) == TYPE_NIL:
		detection_range = 120
	if typeof(chase_duration) == TYPE_NIL:
		chase_duration = 5.0
	if typeof(attack_cooldown) == TYPE_NIL:
		attack_cooldown = 2.0
	if typeof(attack_hit_ratio) == TYPE_NIL:
		attack_hit_ratio = 0.45
	
	setup_detection_area()
	call_deferred("find_player")
	
	if animation_player:
		animation_player.play("idle_down")
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	
	if wander_enabled:
		wander_timer = randf_range(wander_wait_time_min, wander_wait_time_max)

func setup_detection_area():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if is_dead:
		return
	
	if damage_timer > 0.0:
		damage_timer -= delta
	
	if attack_timer > 0:
		attack_timer -= delta
	
	match current_state:
		GoblinState.IDLE:
			handle_idle_state(delta)
		GoblinState.WANDERING:
			handle_wandering_state(delta)
		GoblinState.WALKING:
			handle_walking_state(delta)
		GoblinState.ATTACKING:
			handle_attacking_state(delta)
		GoblinState.DEATH:
			handle_death_state(delta)
	
	apply_player_separation(delta)
	move_and_collide(velocity * delta)

func update_direction(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	
	if abs(direction.x) > abs(direction.y):
		facing_direction = "side"
		sprite.flip_h = direction.x < 0
	else:
		if direction.y > 0:
			facing_direction = "down"
		else:
			facing_direction = "up"

func handle_idle_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	if animation_player and not hurt_locked:
		var idle_anim = "idle_" + facing_direction
		if animation_player.current_animation != idle_anim:
			animation_player.play(idle_anim)
		animation_player.speed_scale = min_animation_speed
	
	if player_in_detection_range and player:
		change_state(GoblinState.WALKING)
		chase_timer = chase_duration
		return
	
	if wander_enabled:
		wander_timer -= delta
		if wander_timer <= 0:
			pick_wander_target()
			change_state(GoblinState.WANDERING)

func handle_wandering_state(delta):
	if player_in_detection_range and player:
		change_state(GoblinState.WALKING)
		chase_timer = chase_duration
		return
	
	var direction_to_target = (wander_target - global_position).normalized()
	target_velocity = direction_to_target * wander_speed
	
	velocity = velocity.move_toward(target_velocity, walk_acceleration * delta)
	
	is_moving = velocity.length() > 5
	last_speed_ratio = clamp(velocity.length() / wander_speed, 0.0, 1.0)
	
	update_direction(direction_to_target)
	
	if is_moving and not hurt_locked:
		if animation_player:
			var run_anim = "run_" + facing_direction
			if animation_player.current_animation != run_anim:
				animation_player.play(run_anim)
			var anim_speed = lerp(min_animation_speed, max_animation_speed, last_speed_ratio * 0.7)
			animation_player.speed_scale = anim_speed
	
	if global_position.distance_to(wander_target) < 10:
		wander_timer = randf_range(wander_wait_time_min, wander_wait_time_max)
		change_state(GoblinState.IDLE)

func pick_wander_target():
	var angle = randf() * TAU
	var distance = randf_range(wander_radius * 0.3, wander_radius)
	wander_target = spawn_position + Vector2(cos(angle), sin(angle)) * distance

func handle_walking_state(delta):
	if not player:
		change_state(GoblinState.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_range and attack_timer <= 0 and not hurt_locked:
		change_state(GoblinState.ATTACKING)
		return
	
	if player_in_detection_range:
		chase_timer = chase_duration
	else:
		chase_timer -= delta
	
	if chase_timer > 0:
		var direction_to_player = (player.global_position - global_position).normalized()
		target_velocity = direction_to_player * speed
		
		velocity = velocity.move_toward(target_velocity, walk_acceleration * delta)
		
		is_moving = velocity.length() > 5
		last_speed_ratio = clamp(velocity.length() / speed, 0.0, 1.0)
		
		update_direction(direction_to_player)
		
		if is_moving and not hurt_locked:
			if animation_player:
				var run_anim = "run_" + facing_direction
				if animation_player.current_animation != run_anim:
					animation_player.play(run_anim)
				var anim_speed = lerp(min_animation_speed, max_animation_speed, last_speed_ratio)
				animation_player.speed_scale = anim_speed
		else:
			if animation_player and not hurt_locked:
				var idle_anim = "idle_" + facing_direction
				if animation_player.current_animation != idle_anim:
					animation_player.play(idle_anim)
				animation_player.speed_scale = min_animation_speed
	else:
		wander_timer = randf_range(wander_wait_time_min, wander_wait_time_max)
		change_state(GoblinState.IDLE)

func handle_attacking_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	if not is_attacking:
		start_attack()

func handle_death_state(delta):
	pass

func change_state(new_state: GoblinState):
	current_state = new_state

func start_attack():
	is_attacking = true
	attack_timer = attack_cooldown
	
	velocity = Vector2.ZERO
	var attack_anim = "attack_" + facing_direction
	var attack_len := 0.5
	
	if animation_player:
		animation_player.play(attack_anim)
		var base_speed = lerp(min_animation_speed, max_animation_speed, last_speed_ratio)
		animation_player.speed_scale = base_speed * attack_speed_multiplier
		attack_len = max(0.05, animation_player.get_animation(attack_anim).length)
	
	var scaled: float = max(animation_player.speed_scale, 0.001)
	var hit_time: float = (attack_len * attack_hit_ratio) / scaled
	await get_tree().create_timer(hit_time).timeout
	
	if player and player.has_method("take_damage") and global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage(int(damage), self)
	
	var dir: Vector2 = Vector2.ZERO
	if player:
		dir = (player.global_position - global_position).normalized()
	if dir != Vector2.ZERO:
		velocity = dir * lunge_speed
	
	var rest_time: float = (attack_len - (attack_len * attack_hit_ratio)) / scaled
	var lunge_time: float = min(lunge_duration, max(0.0, rest_time * 0.6))
	if lunge_time > 0.0:
		await get_tree().create_timer(lunge_time).timeout
	velocity = Vector2.ZERO
	var remain_time: float = max(0.0, rest_time - lunge_time)
	if remain_time > 0.0:
		await get_tree().create_timer(remain_time).timeout
	is_attacking = false
	change_state(GoblinState.WALKING)

func apply_player_separation(delta):
	if not player:
		return
	var offset: Vector2 = global_position - player.global_position
	var dist: float = offset.length()
	if dist <= 0.001:
		return
	var min_dist: float = separation_distance
	if dist < min_dist:
		var push_dir: Vector2 = offset / dist
		var penetration: float = min_dist - dist
		var push_speed: float = separation_force * penetration
		velocity += push_dir * push_speed * delta
		var max_correction: float = min(penetration, 8.0)
		global_position += push_dir * max_correction

func _on_animation_finished(anim_name: String) -> void:
	if anim_name.begins_with("attack") and is_attacking:
		is_attacking = false
		change_state(GoblinState.WALKING)
	elif anim_name.begins_with("hurt"):
		hurt_locked = false
		print("Hurt animation finished, unlocked")

func take_damage(amount: int):
	if is_dead or hurt_locked or damage_timer > 0.0:
		return
	
	if get_tree() and get_tree().current_scene:
		ParticleEffects.spawn_damage_number(get_tree().current_scene, global_position + Vector2(0, -18), amount)
	
	current_health -= amount
	damage_timer = damage_cooldown
	
	if animation_player:
		hurt_locked = true
		var hit_anim = "hurt_" + facing_direction
		
		if animation_player.has_animation(hit_anim):
			animation_player.speed_scale = 0.8
			animation_player.play(hit_anim)
		else:
			print("WARNING: Animation not found: ", hit_anim)
			hurt_locked = false
	else:
		hurt_locked = false
	
	if current_health <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	current_state = GoblinState.DEATH
	
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		quest_manager.on_enemy_killed("skeleton_enemy")
	
	var death_anim = "die_" + facing_direction
	var death_len := 0.6
	
	if animation_player:
		animation_player.play(death_anim)
		death_len = max(0.05, animation_player.get_animation(death_anim).length)
	
	var respawn_manager = get_tree().get_first_node_in_group("respawn_manager")
	if respawn_manager:
		respawn_manager.register_enemy_death(self)

	DropSystem.handle_enemy_death(enemy_type, global_position, get_tree())
	#_drop_keys_like_slime()
	
	collision_shape.disabled = true
	
	await get_tree().create_timer(death_len).timeout
	
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 0.5), 0.6)
	tween.tween_callback(queue_free)

#func _drop_keys_like_slime():
	#var key_drop_chance = 0.3
	#if randf() < key_drop_chance:
		#var key_type = "iron"
		#var key_id = key_type + "_key"
		#var pickup_scene = load("res://scenes/PickupItem.tscn")
		#if pickup_scene:
			#var pickup = pickup_scene.instantiate()
			#get_tree().current_scene.add_child(pickup)
			#pickup.global_position = global_position + Vector2(randf_range(-20, 20), -20)
			#pickup.set_item(key_id, 1)

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player_in_detection_range = true
		if not player:
			player = body

func _on_detection_area_exited(body):
	if body.is_in_group("player"):
		player_in_detection_range = false
