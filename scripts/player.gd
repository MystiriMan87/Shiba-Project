extends CharacterBody2D

@export var speed = 300
@export var friction = 0.2
@export var acceleration = 0.1
@export var attack_damage = 1
@export var attack_duration = 0.4
@export var attack_cooldown = 0.1

# Player health system
@export var max_health = 5
@export var damage_immunity_duration = 0.3
@export var knockback_resistance = 0.5

# Animation speed settings
@export var min_animation_speed = 0.5  # Minimum animation speed when barely moving
@export var max_animation_speed = 2.0  # Maximum animation speed at full speed
@export var speed_threshold = 50       # Minimum speed to play walk animation

# Sword animation settings
@export var swing_arc_degrees = 120  # How wide the swing arc is
@export var swing_duration = 0.3     # How long the swing animation takes
@export var swing_offset_distance = 30  # Distance from player center
@export var enable_trail_effect = true
@export var trail_fade_duration = 0.2

# Mouse-based attack settings
@export var attack_range = 50  # How far from player the sword swings
@export var swing_arc_half_angle = 60  # Half the swing arc in degrees (total will be 120°)

# Attack state variables
var is_attacking = false
var attack_timer = 0.0
var cooldown_timer = 0.0
var last_direction = Vector2.DOWN

# Mouse-based attack variables
var mouse_attack_direction = Vector2.RIGHT
var swing_start_angle = 0.0
var swing_end_angle = 0.0
var swing_current_progress = 0.0
var is_swing_animating = false

# Trail effect variables
var trail_positions = []
var max_trail_length = 8

# Add trail visual settings
@export var trail_color = Color.CYAN
@export var trail_width = 3.0
@export var trail_max_alpha = 0.8

# Health and damage variables
var current_health
var is_taking_damage = false
var damage_immunity_timer = 0.0
var damage_flash_timer = 0.0
var damage_flash_duration = 0.1
var player_knockback_velocity = Vector2.ZERO
var knockback_friction = 0.8  # Increased from 0.2 for faster recovery
var knockback_threshold = 15.0  # Minimum knockback speed to override input

# Animation variables
var current_animation = ""
var is_moving = false

# Node references
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var attack_area = $AttackArea if has_node("AttackArea") else null
@onready var attack_collision = $AttackArea/CollisionShape2D if has_node("AttackArea/CollisionShape2D") else null
@onready var attack_sprite = $AttackSprite if has_node("AttackSprite") else null
@onready var health_bar = $HealthBar if has_node("HealthBar") else null
@onready var ui_health_bar = $"../UI/HealthBar" if has_node("../UI/HealthBar") else null

func _ready():
	# Add player to group so camera and enemies can find it
	add_to_group("player")
	print("Player added to 'player' group. Player name: ", name)
	
	# Initialize health
	current_health = max_health
	update_health_display()
	
	  # Make sure player is in the "player" group for UI to find it
	add_to_group("player")
	
	# Set up attack area
	if attack_area:
		attack_area.monitoring = false
		# Set collision layers for proper interaction with enemies
		attack_area.collision_layer = 2  # Player attacks are on layer 2
		attack_area.collision_mask = 4   # Can hit enemies on layer 4
		
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)
		
		print("Player attack area configured")
	else:
		print("WARNING: AttackArea not found - player can't attack!")
	
	# Make sure player physics body is on the right layer
	collision_layer = 1  # Player body is on layer 1 (so enemies can detect it)
	collision_mask = 1   # Player can collide with environment (layer 1)
	
	print("Player physics layers configured - Layer: 1, Mask: 1")
	
	# Start with idle animation
	if animation_player:
		play_animation("Idle_down")
	else:
		print("WARNING: AnimationPlayer not found!")

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
	# Handle damage immunity timer
	if damage_immunity_timer > 0:
		damage_immunity_timer -= delta
		
		# Flash sprite during immunity
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			damage_flash_timer = damage_flash_duration
			if sprite:
				sprite.modulate = Color.WHITE if sprite.modulate == Color.RED else Color.RED
	else:
		# Reset sprite color when not taking damage
		if sprite and sprite.modulate != Color.WHITE:
			sprite.modulate = Color.WHITE
	
	# Handle attack timing
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# Handle attack input with mouse direction
	if Input.is_action_just_pressed('Attack') and not is_attacking and cooldown_timer <= 0:
		# Calculate mouse direction from player
		var mouse_pos = get_global_mouse_position()
		mouse_attack_direction = (mouse_pos - global_position).normalized()
		start_attack()
	
	# Handle movement
	var direction = get_input()
	
	# Check if player is moving
	is_moving = direction.length() > 0
	
	# Update last direction for animations (only when moving and not attacking)
	if direction.length() > 0 and not is_attacking:
		last_direction = direction.normalized()
	
	# Handle knockback with improved logic to prevent getting stuck
	if player_knockback_velocity.length() > knockback_threshold:
		# Apply knockback but allow some player input influence
		var knockback_influence = 0.7  # How much knockback affects movement (0.0 = no knockback, 1.0 = full knockback)
		var input_influence = 1.0 - knockback_influence
		
		# Blend knockback with player input
		var target_velocity = (player_knockback_velocity * knockback_influence) + (direction.normalized() * speed * input_influence)
		velocity = velocity.lerp(target_velocity, acceleration)
		
		# Reduce knockback over time
		player_knockback_velocity = player_knockback_velocity.lerp(Vector2.ZERO, knockback_friction)
	else:
		# Normal movement - no significant knockback
		player_knockback_velocity = Vector2.ZERO  # Clear any remaining weak knockback
		
		if direction.length() > 0:
			velocity = velocity.lerp(direction.normalized() * speed, acceleration)
		else:
			velocity = velocity.lerp(Vector2.ZERO, friction)
	
	# Update animations and sprite flipping
	update_animation()
	update_sprite_flip(velocity)
	
	# Update sword swing animation
	if is_swing_animating:
		update_sword_swing_animation(delta)
	
	move_and_slide()

func update_animation():
	if is_attacking:
		# Don't change animation while attacking
		return
	
	var new_animation = ""
	var current_speed = velocity.length()
	
	# Determine direction string for animation
	var direction_string = get_direction_string(last_direction)
	
	# Choose animation based on movement
	if is_moving and current_speed > speed_threshold:
		new_animation = "Walk_" + direction_string
	else:
		new_animation = "Idle_" + direction_string
	
	# Only change animation if it's different from current
	if new_animation != current_animation:
		play_animation(new_animation)
	
	# Update animation speed based on player velocity
	update_animation_speed(current_speed)

func update_animation_speed(current_speed: float):
	if not animation_player:
		return
	
	# Calculate animation speed based on player velocity
	var speed_ratio = current_speed / speed  # Ratio of current speed to max speed
	var animation_speed = lerp(min_animation_speed, max_animation_speed, speed_ratio)
	
	# Clamp to reasonable bounds
	animation_speed = clamp(animation_speed, min_animation_speed, max_animation_speed)
	
	# Apply the speed to the animation player
	animation_player.speed_scale = animation_speed

func get_direction_string(direction: Vector2) -> String:
	# Convert direction vector to animation suffix
	# For left/right movement, we'll use "side" but handle flipping separately
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement is stronger - use "side" for left/right
		return "side"
	else:
		# Vertical movement is stronger
		if direction.y > 0:
			return "down"
		else:
			return "up"

func update_sprite_flip(current_velocity: Vector2):
	if not sprite:
		return
	
	# Only flip for horizontal movement (when moving left/right)
	if abs(current_velocity.x) > abs(current_velocity.y) and abs(current_velocity.x) > speed_threshold:
		# Flip sprite based on horizontal movement direction
		sprite.flip_h = current_velocity.x < 0  # Flip when moving left
	# Keep current flip state for vertical movement or when not moving significantly

func play_animation(animation_name: String):
	if not animation_player:
		return
	
	# Check if the animation exists
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		current_animation = animation_name
		print("Playing animation: ", animation_name)
	else:
		print("Animation not found: ", animation_name)
		# Fallback to a basic animation
		if animation_player.has_animation("Idle_down"):
			animation_player.play("Idle_down")
			current_animation = "Idle_down"

# Take damage function with better enemy interaction - FIXED to prevent movement lock
func take_damage(amount: int, source: Node = null):
	print("=== PLAYER TAKE_DAMAGE CALLED ===")
	print("Damage amount: ", amount)
	print("Source: ", source.name if source else "null")
	print("Current immunity timer: ", damage_immunity_timer)
	
	# Check if player has immunity frames
	if damage_immunity_timer > 0:
		print("Player has immunity - no damage taken!")
		return false  # Return false to indicate no damage was taken
	
	current_health -= amount
	print("Player took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	# Start immunity frames
	damage_immunity_timer = damage_immunity_duration
	damage_flash_timer = damage_flash_duration
	
	# Update health display
	update_health_display()
	
	# Flash sprite red
	if sprite:
		sprite.modulate = Color.RED
	
	# Apply knockback if damage came from an enemy
	if source and source.has_method("get_knockback_force"):
		var knockback_direction = (global_position - source.global_position).normalized()
		var knockback_force = source.get_knockback_force() if source.has_method("get_knockback_force") else 150
		apply_knockback(knockback_direction, knockback_force)
	elif source:
		# Apply default knockback even if enemy doesn't have get_knockback_force method
		var knockback_direction = (global_position - source.global_position).normalized()
		apply_knockback(knockback_direction, 150)
	
	# Check if dead
	if current_health <= 0:
		die()
	
	return true  # Return true to indicate damage was taken

# Update health bar display
func update_health_display():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if ui_health_bar:
		ui_health_bar.max_value = max_health
		ui_health_bar.value = current_health

# Handle player death
func die():
	print("Player died!")
	# Play death animation if it exists
	if animation_player and animation_player.has_animation("death"):
		play_animation("death")
	
	# Add death logic here - restart level, show game over screen, etc.
	# For now, just respawn with full health
	current_health = max_health
	update_health_display()
	
	# Reset immunity (in case of respawn)
	damage_immunity_timer = 0.0
	
	# Clear any remaining knockback
	player_knockback_velocity = Vector2.ZERO
	
	# Reset position to spawn point
	# global_position = Vector2(100, 100)  # Set to your spawn position

# Heal player (useful for health pickups)
func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	print("Player healed for ", amount, "! Health: ", current_health, "/", max_health)
	update_health_display()

# FIXED: Add knockback to player with proper force limiting
func apply_knockback(direction: Vector2, force: float):
	# Apply knockback with resistance and ensure it's not too weak or strong
	var knockback_force = force * knockback_resistance
	# Clamp knockback to reasonable values to prevent getting stuck or flying away
	knockback_force = clamp(knockback_force, 80, 250)
	player_knockback_velocity = direction.normalized() * knockback_force
	print("Player knocked back with force: ", player_knockback_velocity.length())

func start_attack():
	is_attacking = true
	attack_timer = attack_duration
	
	# Start mouse-directed sword swing animation
	start_mouse_sword_swing_animation()
	
	# Play attack animation on player based on mouse direction
	var direction_string = get_direction_string(mouse_attack_direction)
	var attack_animation = "hit_" + direction_string
	play_animation(attack_animation)
	
	# Reset animation speed for attack
	if animation_player:
		animation_player.speed_scale = 1.0
	
	# Enable attack area
	if attack_area:
		attack_area.monitoring = true
		print("Player attack started - monitoring enabled")
	
	# Position attack hitbox towards mouse
	position_attack_hitbox(mouse_attack_direction)
	
	print("Player attack started towards mouse direction: ", mouse_attack_direction)

func start_mouse_sword_swing_animation():
	if not attack_sprite:
		return
	
	is_swing_animating = true
	swing_current_progress = 0.0
	
	# Calculate the base angle towards mouse
	var mouse_angle = mouse_attack_direction.angle()
	
	# Calculate swing arc (swing from -60° to +60° relative to mouse direction)
	swing_start_angle = mouse_angle - deg_to_rad(swing_arc_half_angle)
	swing_end_angle = mouse_angle + deg_to_rad(swing_arc_half_angle)
	
	# Position sword at start of swing
	var start_position = Vector2(cos(swing_start_angle), sin(swing_start_angle)) * attack_range
	attack_sprite.position = start_position
	attack_sprite.rotation = swing_start_angle
	
	# Make sword visible and reset properties
	attack_sprite.visible = true
	attack_sprite.modulate.a = 1.0
	
	# Don't flip the sprite - let rotation handle the direction
	attack_sprite.flip_h = false
	attack_sprite.flip_v = false
	
	# Initialize trail
	if enable_trail_effect:
		trail_positions.clear()
	
	print("Mouse swing started - From angle: ", rad_to_deg(swing_start_angle), " To angle: ", rad_to_deg(swing_end_angle))

func update_sword_swing_animation(delta):
	if not is_swing_animating or not attack_sprite:
		return
	
	# Update swing progress
	swing_current_progress += delta / swing_duration
	swing_current_progress = clamp(swing_current_progress, 0.0, 1.0)
	
	# Use easing for smoother swing motion
	var ease_progress = ease_out_quad(swing_current_progress)
	
	# Calculate current angle by interpolating between start and end angles
	var current_angle = lerp_angle(swing_start_angle, swing_end_angle, ease_progress)
	
	# Position sword at current angle
	var sword_position = Vector2(cos(current_angle), sin(current_angle)) * attack_range
	attack_sprite.position = sword_position
	
	# Since the sword sprite points right (0°) in the texture, 
	# we can use the angle directly
	attack_sprite.rotation = current_angle
	
	# Reset any flipping to ensure consistent appearance
	attack_sprite.flip_v = false
	attack_sprite.flip_h = false
	
	# Update trail effect
	if enable_trail_effect:
		update_sword_trail()
	
	# Check if swing is complete
	if swing_current_progress >= 1.0:
		is_swing_animating = false
		print("Swing animation completed")

# Add this new function to draw the trail
func _draw():
	if not enable_trail_effect or trail_positions.size() < 2:
		return
	
	# Draw trail as connected lines with fading alpha
	for i in range(trail_positions.size() - 1):
		var start_pos = to_local(trail_positions[i])
		var end_pos = to_local(trail_positions[i + 1])
		
		# Calculate alpha based on position in trail (newer = more opaque)
		var alpha = float(i) / float(trail_positions.size() - 1)
		var color = trail_color
		color.a = alpha * trail_max_alpha
		
		# Draw line segment
		draw_line(start_pos, end_pos, color, trail_width)

# Easing function for smoother animation
func ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

func update_sword_trail():
	if not attack_sprite:
		return
	
	# Add current sword tip position to trail
	var sword_tip_offset = Vector2(cos(attack_sprite.rotation), sin(attack_sprite.rotation)) * 20
	var sword_tip_position = attack_sprite.global_position + sword_tip_offset
	trail_positions.append(sword_tip_position)
	
	# Limit trail length
	if trail_positions.size() > max_trail_length:
		trail_positions.pop_front()
	
	# Draw trail using queue_redraw (this will trigger _draw)
	queue_redraw()

func end_attack():
	is_attacking = false
	is_swing_animating = false
	cooldown_timer = attack_cooldown
	
	# Disable attack area
	if attack_area:
		attack_area.monitoring = false
		print("Player attack ended - monitoring disabled")
	
	# Clear trail and stop drawing
	if enable_trail_effect:
		trail_positions.clear()
		queue_redraw()  # Redraw to clear trail
	
	# Hide attack sprite with fade effect
	if attack_sprite:
		fade_out_sword()

func fade_out_sword():
	if not attack_sprite:
		return
	
	# Create fade out tween
	var tween = create_tween()
	tween.tween_property(attack_sprite, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): 
		attack_sprite.visible = false
		attack_sprite.modulate.a = 1.0  # Reset alpha for next use
	)

func position_attack_hitbox(direction: Vector2):
	if not attack_collision:
		return
	
	var offset_distance = 32  # Adjust based on your sprite size
	var hitbox_offset = direction * offset_distance
	
	if attack_collision:
		attack_collision.position = hitbox_offset
		print("Attack hitbox positioned at: ", hitbox_offset)
	
	# Optional: Rotate hitbox shape if needed (for rectangular shapes)
	# You might want to keep this as 0 for circular hitboxes
	attack_collision.rotation = direction.angle()

func _on_attack_area_body_entered(body):
	print("Player attack hit: ", body.name)
	
	# Handle what happens when sword hits something
	if body.has_method("take_damage"):
		var damage_dealt = body.take_damage(attack_damage)
		if damage_dealt:
			print("Player hit ", body.name, " for ", attack_damage, " damage!")
		else:
			print("Attack blocked or enemy immune")
	elif body.has_method("on_sword_hit"):
		body.on_sword_hit()
	
	# Add hit effects here (particles, sound, screen shake, etc.)

# Function to check if currently attacking (useful for other scripts)
func get_is_attacking() -> bool:
	return is_attacking

# Function to get current facing direction (now returns mouse direction during attacks)
func get_facing_direction() -> Vector2:
	if is_attacking:
		return mouse_attack_direction
	return last_direction

# Function to get mouse attack direction
func get_mouse_attack_direction() -> Vector2:
	return mouse_attack_direction

# Utility functions for other scripts
func is_alive() -> bool:
	return current_health > 0

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

# Function for enemies to check if they can damage player
func can_take_damage() -> bool:
	return damage_immunity_timer <= 0

# Get knockback resistance (for enemy calculations)
func get_knockback_resistance() -> float:
	return knockback_resistance
