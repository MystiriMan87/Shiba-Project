extends CharacterBody2D

@export var max_health = 4
@export var speed = 60
@export var damage = 2
@export var attack_range = 80
@export var detection_range = 120
@export var chase_duration = 5.0
@export var attack_cooldown = 2.0
@export var walk_acceleration = 300
@export var walk_friction = 200

var current_health
var is_dead = false
var is_attacking = false
var player = null
var player_in_detection_range = false
var chase_timer = 0.0
var attack_timer = 0.0
var target_velocity = Vector2.ZERO
var is_moving = false

# Manual animation system
var animation_timer = 0.0
var current_frame = 0
var current_anim = "idle"
var frame_duration = 0.2

enum SkeletonState {
	IDLE,
	WALKING,
	ATTACKING,
	DEATH
}

var current_state = SkeletonState.IDLE

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea

func _ready():
	add_to_group("enemies")
	current_health = max_health
	collision_layer = 4
	collision_mask = 1
	
	setup_detection_area()
	call_deferred("find_player")
	
	if animation_player:
		animation_player.play("idle")

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
	
	if attack_timer > 0:
		attack_timer -= delta
	
	match current_state:
		SkeletonState.IDLE:
			handle_idle_state(delta)
		SkeletonState.WALKING:
			handle_walking_state(delta)
		SkeletonState.ATTACKING:
			handle_attacking_state(delta)
		SkeletonState.DEATH:
			handle_death_state(delta)
	
	move_and_slide()

func handle_idle_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	if animation_player:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
	
	if player_in_detection_range and player:
		change_state(SkeletonState.WALKING)
		chase_timer = chase_duration

func handle_walking_state(delta):
	if not player:
		change_state(SkeletonState.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_range and attack_timer <= 0:
		change_state(SkeletonState.ATTACKING)
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
		
		if sprite and direction_to_player.x != 0:
			sprite.flip_h = direction_to_player.x < 0
		
		if is_moving:
			if animation_player:
				var walk_anim = "movement"
				if animation_player.has_animation("walk"):
					walk_anim = "walk"
				elif animation_player.has_animation("move"):
					walk_anim = "move"
				if animation_player.current_animation != walk_anim:
					animation_player.play(walk_anim)
		else:
			if animation_player and animation_player.current_animation != "idle":
				animation_player.play("idle")
	else:
		change_state(SkeletonState.IDLE)

func handle_attacking_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	if not is_attacking:
		start_attack()

func handle_death_state(delta):
	pass

func change_state(new_state: SkeletonState):
	current_state = new_state

func start_attack():
	is_attacking = true
	attack_timer = attack_cooldown
	
	velocity = Vector2.ZERO
	var attack_len := 0.5
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
		attack_len = max(0.05, animation_player.get_animation("attack").length)
	
	var hit_time := attack_len * 0.4
	await get_tree().create_timer(hit_time).timeout
	
	if player and global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage(damage)
	
	await get_tree().create_timer(attack_len - hit_time).timeout
	is_attacking = false
	change_state(SkeletonState.WALKING)

func _noop():
	pass

func take_damage(amount: int):
	if is_dead:
		return
	
	current_health -= amount
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die():
	is_dead = true
	current_state = SkeletonState.DEATH
	
	var death_len := 0.6
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		death_len = max(0.05, animation_player.get_animation("death").length)
	
	var respawn_manager = get_tree().get_first_node_in_group("respawn_manager")
	if respawn_manager:
		respawn_manager.register_enemy_death(self)
	
	collision_shape.disabled = true
	
	await get_tree().create_timer(death_len).timeout
	
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 0.5), 0.6)
	tween.tween_callback(queue_free)

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player_in_detection_range = true
		if not player:
			player = body

func _on_detection_area_exited(body):
	if body.is_in_group("player"):
		player_in_detection_range = false
