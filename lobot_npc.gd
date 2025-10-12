extends CharacterBody2D

@export var speed = 40
@export var min_animation_speed = 0.5
@export var max_animation_speed = 1.0
@export var walk_acceleration = 200
@export var walk_friction = 150

@export_group("Wandering")
@export var wander_enabled: bool = true
@export var wander_speed: float = 25.0
@export var wander_radius: float = 80.0
@export var wander_wait_time_min: float = 2.0
@export var wander_wait_time_max: float = 5.0

var target_velocity = Vector2.ZERO
var is_moving = false
var last_speed_ratio: float = 0.0
var facing_direction = "down"

var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO

enum NPCState {
	IDLE,
	WANDERING
}

var current_state = NPCState.IDLE

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("npcs")
	collision_layer = 1
	collision_mask = 1
	spawn_position = global_position
	
	if animation_player:
		animation_player.play("idle_down")
	
	if wander_enabled:
		wander_timer = randf_range(wander_wait_time_min, wander_wait_time_max)

func _physics_process(delta):
	match current_state:
		NPCState.IDLE:
			handle_idle_state(delta)
		NPCState.WANDERING:
			handle_wandering_state(delta)
	
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
	
	if animation_player:
		var idle_anim = "idle_" + facing_direction
		if animation_player.current_animation != idle_anim:
			animation_player.play(idle_anim)
		animation_player.speed_scale = min_animation_speed
	
	if wander_enabled:
		wander_timer -= delta
		if wander_timer <= 0:
			pick_wander_target()
			change_state(NPCState.WANDERING)

func handle_wandering_state(delta):
	var direction_to_target = (wander_target - global_position).normalized()
	target_velocity = direction_to_target * wander_speed
	
	velocity = velocity.move_toward(target_velocity, walk_acceleration * delta)
	
	is_moving = velocity.length() > 5
	last_speed_ratio = clamp(velocity.length() / wander_speed, 0.0, 1.0)
	
	update_direction(direction_to_target)
	
	if is_moving:
		if animation_player:
			var walk_anim = "run_" + facing_direction
			if animation_player.current_animation != walk_anim:
				animation_player.play(walk_anim)
			var anim_speed = lerp(min_animation_speed, max_animation_speed, last_speed_ratio)
			animation_player.speed_scale = anim_speed
	
	if global_position.distance_to(wander_target) < 10:
		wander_timer = randf_range(wander_wait_time_min, wander_wait_time_max)
		change_state(NPCState.IDLE)

func pick_wander_target():
	var angle = randf() * TAU
	var distance = randf_range(wander_radius * 0.3, wander_radius)
	wander_target = spawn_position + Vector2(cos(angle), sin(angle)) * distance

func change_state(new_state: NPCState):
	current_state = new_state
