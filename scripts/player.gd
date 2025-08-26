extends CharacterBody2D

@export var speed = 300
@export var friction = 0.2
@export var acceleration = 0.1
@export var attack_damage = 1
@export var attack_duration = 0.4
@export var attack_cooldown = 0.1

@export var max_health = 5
@export var damage_immunity_duration = 0.3
@export var knockback_resistance = 0.5

@export var min_animation_speed = 0.5
@export var max_animation_speed = 2.0
@export var speed_threshold = 50

@export var swing_arc_degrees = 120
@export var swing_duration = 0.3
@export var swing_offset_distance = 30
@export var enable_trail_effect = true
@export var trail_fade_duration = 0.2

@export var attack_range = 50
@export var swing_arc_half_angle = 60

var is_attacking = false
var attack_timer = 0.0
var cooldown_timer = 0.0
var last_direction = Vector2.DOWN

var mouse_attack_direction = Vector2.RIGHT
var swing_start_angle = 0.0
var swing_end_angle = 0.0
var swing_current_progress = 0.0
var is_swing_animating = false

var trail_positions = []
var max_trail_length = 8

@export var trail_color = Color.CYAN
@export var trail_width = 3.0
@export var trail_max_alpha = 0.8

var current_health
var is_taking_damage = false
var damage_immunity_timer = 0.0
var damage_flash_timer = 0.0
var damage_flash_duration = 0.1
var player_knockback_velocity = Vector2.ZERO
var knockback_friction = 0.8
var knockback_threshold = 15.0

var current_animation = ""
var is_moving = false

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var attack_area = $AttackArea if has_node("AttackArea") else null
@onready var attack_collision = $AttackArea/CollisionShape2D if has_node("AttackArea/CollisionShape2D") else null
@onready var attack_sprite = $AttackSprite if has_node("AttackSprite") else null
@onready var health_bar = $HealthBar if has_node("HealthBar") else null
@onready var ui_health_bar = $"../UI/HealthBar" if has_node("../UI/HealthBar") else null

func _ready():
	add_to_group("player")
	current_health = max_health
	update_health_display()
	add_to_group("player")
	
	if attack_area:
		attack_area.monitoring = false
		attack_area.collision_layer = 2
		attack_area.collision_mask = 4
		
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	collision_layer = 1
	collision_mask = 1
	
	if animation_player:
		play_animation("Idle_down")

func get_input():
	var input = Vector2()
	if Input.is_action_pressed('move_right'):
		input.x += 1
	if Input.is_action_pressed('move_left'):
		input.x -= 1
	if Input.is_action_pressed('move_down'):
		input.y += 1
	if Input.is_action_pressed('move_up'):
		input.y -= 1
	return input

func _physics_process(delta):
	if damage_immunity_timer > 0:
		damage_immunity_timer -= delta
		
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			damage_flash_timer = damage_flash_duration
			if sprite:
				sprite.modulate = Color.WHITE if sprite.modulate == Color.RED else Color.RED
	else:
		if sprite and sprite.modulate != Color.WHITE:
			sprite.modulate = Color.WHITE
	
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if Input.is_action_just_pressed('Attack') and not is_attacking and cooldown_timer <= 0:
		var mouse_pos = get_global_mouse_position()
		mouse_attack_direction = (mouse_pos - global_position).normalized()
		start_attack()
	
	var direction = get_input()
	is_moving = direction.length() > 0
	
	if direction.length() > 0 and not is_attacking:
		last_direction = direction.normalized()
	
	if player_knockback_velocity.length() > knockback_threshold:
		var knockback_influence = 0.7
		var input_influence = 1.0 - knockback_influence
		
		var target_velocity = (player_knockback_velocity * knockback_influence) + (direction.normalized() * speed * input_influence)
		velocity = velocity.lerp(target_velocity, acceleration)
		
		player_knockback_velocity = player_knockback_velocity.lerp(Vector2.ZERO, knockback_friction)
	else:
		player_knockback_velocity = Vector2.ZERO
		
		if direction.length() > 0:
			velocity = velocity.lerp(direction.normalized() * speed, acceleration)
		else:
			velocity = velocity.lerp(Vector2.ZERO, friction)
	
	update_animation()
	update_sprite_flip(velocity)
	
	if is_swing_animating:
		update_sword_swing_animation(delta)
	
	move_and_slide()

func update_animation():
	if is_attacking:
		return
	
	var new_animation = ""
	var current_speed = velocity.length()
	
	var direction_string = get_direction_string(last_direction)
	
	if is_moving and current_speed > speed_threshold:
		new_animation = "Walk_" + direction_string
	else:
		new_animation = "Idle_" + direction_string
	
	if new_animation != current_animation:
		play_animation(new_animation)
	
	update_animation_speed(current_speed)

func update_animation_speed(current_speed: float):
	if not animation_player:
		return
	
	var speed_ratio = current_speed / speed
	var animation_speed = lerp(min_animation_speed, max_animation_speed, speed_ratio)
	animation_speed = clamp(animation_speed, min_animation_speed, max_animation_speed)
	animation_player.speed_scale = animation_speed

func get_direction_string(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		return "side"
	else:
		if direction.y > 0:
			return "down"
		else:
			return "up"

func update_sprite_flip(current_velocity: Vector2):
	if not sprite:
		return
	
	if abs(current_velocity.x) > abs(current_velocity.y) and abs(current_velocity.x) > speed_threshold:
		sprite.flip_h = current_velocity.x < 0

func play_animation(animation_name: String):
	if not animation_player:
		return
	
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		current_animation = animation_name
	else:
		if animation_player.has_animation("Idle_down"):
			animation_player.play("Idle_down")
			current_animation = "Idle_down"

func take_damage(amount: int, source: Node = null):
	if damage_immunity_timer > 0:
		return false
	
	current_health -= amount
	damage_immunity_timer = damage_immunity_duration
	damage_flash_timer = damage_flash_duration
	update_health_display()
	
	if sprite:
		sprite.modulate = Color.RED
	
	if source and source.has_method("get_knockback_force"):
		var knockback_direction = (global_position - source.global_position).normalized()
		var knockback_force = source.get_knockback_force() if source.has_method("get_knockback_force") else 150
		apply_knockback(knockback_direction, knockback_force)
	elif source:
		var knockback_direction = (global_position - source.global_position).normalized()
		apply_knockback(knockback_direction, 150)
	
	if current_health <= 0:
		die()
	
	return true

func update_health_display():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if ui_health_bar:
		ui_health_bar.max_value = max_health
		ui_health_bar.value = current_health

func die():
	current_health = max_health
	update_health_display()
	damage_immunity_timer = 0.0
	player_knockback_velocity = Vector2.ZERO

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	update_health_display()

func apply_knockback(direction: Vector2, force: float):
	var knockback_force = force * knockback_resistance
	knockback_force = clamp(knockback_force, 80, 250)
	player_knockback_velocity = direction.normalized() * knockback_force

func start_attack():
	is_attacking = true
	attack_timer = attack_duration
	
	start_mouse_sword_swing_animation()
	
	var direction_string = get_direction_string(mouse_attack_direction)
	var attack_animation = "hit_" + direction_string
	play_animation(attack_animation)
	
	if animation_player:
		animation_player.speed_scale = 1.0
	
	if attack_area:
		attack_area.monitoring = true
	
	position_attack_hitbox(mouse_attack_direction)

func start_mouse_sword_swing_animation():
	if not attack_sprite:
		return
	
	is_swing_animating = true
	swing_current_progress = 0.0
	
	var mouse_angle = mouse_attack_direction.angle()
	swing_start_angle = mouse_angle - deg_to_rad(swing_arc_half_angle)
	swing_end_angle = mouse_angle + deg_to_rad(swing_arc_half_angle)
	
	var start_position = Vector2(cos(swing_start_angle), sin(swing_start_angle)) * attack_range
	attack_sprite.position = start_position
	attack_sprite.rotation = swing_start_angle
	attack_sprite.visible = true
	attack_sprite.modulate.a = 1.0
	attack_sprite.flip_h = false
	attack_sprite.flip_v = false
	
	if enable_trail_effect:
		trail_positions.clear()

func update_sword_swing_animation(delta):
	if not is_swing_animating or not attack_sprite:
		return
	
	swing_current_progress += delta / swing_duration
	swing_current_progress = clamp(swing_current_progress, 0.0, 1.0)
	
	var ease_progress = ease_out_quad(swing_current_progress)
	var current_angle = lerp_angle(swing_start_angle, swing_end_angle, ease_progress)
	
	var sword_position = Vector2(cos(current_angle), sin(current_angle)) * attack_range
	attack_sprite.position = sword_position
	attack_sprite.rotation = current_angle
	attack_sprite.flip_v = false
	attack_sprite.flip_h = false
	
	if enable_trail_effect:
		update_sword_trail()
	
	if swing_current_progress >= 1.0:
		is_swing_animating = false

func _draw():
	if not enable_trail_effect or trail_positions.size() < 2:
		return
	
	for i in range(trail_positions.size() - 1):
		var start_pos = to_local(trail_positions[i])
		var end_pos = to_local(trail_positions[i + 1])
		
		var alpha = float(i) / float(trail_positions.size() - 1)
		var color = trail_color
		color.a = alpha * trail_max_alpha
		
		draw_line(start_pos, end_pos, color, trail_width)

func ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

func update_sword_trail():
	if not attack_sprite:
		return
	
	var sword_tip_offset = Vector2(cos(attack_sprite.rotation), sin(attack_sprite.rotation)) * 20
	var sword_tip_position = attack_sprite.global_position + sword_tip_offset
	trail_positions.append(sword_tip_position)
	
	if trail_positions.size() > max_trail_length:
		trail_positions.pop_front()
	
	queue_redraw()

func end_attack():
	is_attacking = false
	is_swing_animating = false
	cooldown_timer = attack_cooldown
	
	if attack_area:
		attack_area.monitoring = false
	
	if enable_trail_effect:
		trail_positions.clear()
		queue_redraw()
	
	if attack_sprite:
		fade_out_sword()

func fade_out_sword():
	if not attack_sprite:
		return
	
	var tween = create_tween()
	tween.tween_property(attack_sprite, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): 
		attack_sprite.visible = false
		attack_sprite.modulate.a = 1.0
	)

func position_attack_hitbox(direction: Vector2):
	if not attack_collision:
		return
	
	var offset_distance = 32
	var hitbox_offset = direction * offset_distance
	
	if attack_collision:
		attack_collision.position = hitbox_offset
	
	attack_collision.rotation = direction.angle()

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage"):
		var damage_dealt = body.take_damage(attack_damage)
	elif body.has_method("on_sword_hit"):
		body.on_sword_hit()

func get_is_attacking() -> bool:
	return is_attacking

func get_facing_direction() -> Vector2:
	if is_attacking:
		return mouse_attack_direction
	return last_direction

func get_mouse_attack_direction() -> Vector2:
	return mouse_attack_direction

func is_alive() -> bool:
	return current_health > 0

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func can_take_damage() -> bool:
	return damage_immunity_timer <= 0

func get_knockback_resistance() -> float:
	return knockback_resistance
