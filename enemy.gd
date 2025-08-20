extends CharacterBody2D

@export var max_health = 3
@export var speed = 100
@export var damage = 1
@export var knockback_force = 200
@export var detection_range = 150
@export var attack_range = 30
@export var attack_cooldown = 1.5

# Health and state
var current_health
var is_dead = false
var is_taking_damage = false
var damage_timer = 0.0
var damage_flash_duration = 0.2

# Combat
var attack_timer = 0.0
var knockback_velocity = Vector2.ZERO
var knockback_friction = 0.15
var player_in_detection_range = false

# Chase behavior
var chase_duration = 3.0
var chase_timer = 0.0
var is_chasing = false

# Player reference
var player = null

# Node references
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var health_bar = $HealthBar  # Optional: ProgressBar for health
@onready var detection_area = $DetectionArea  # Optional: Area2D for player detection

func _ready():
	current_health = max_health
	
	# Set up health bar if it exists
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Connect detection area if it exists
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
		
		# Make sure detection area is set up properly
		detection_area.monitoring = true
		detection_area.collision_layer = 0  # Don't collide with anything
		detection_area.collision_mask = 1   # Detect layer 1 (player layer)
		print("Detection area set up for enemy")
	
	# Find player node - multiple fallback methods
	call_deferred("find_player")

func find_player():
	# Method 1: Try to find player by group
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Method 2: Try to find all nodes in player group
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	if not player:
		# Method 3: Search for node named "Player" 
		player = get_tree().get_nodes_in_group("player")
		if player.size() == 0:
			player = find_node_by_name(get_tree().root, "Player")
	
	if player:
		print("Enemy found player: ", player.name)
	else:
		print("WARNING: Enemy could not find player!")

func find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = find_node_by_name(child, target_name)
		if result:
			return result
	return null

func _physics_process(delta):
	if is_dead:
		return
	
	# Handle damage flash timer
	if is_taking_damage:
		damage_timer -= delta
		if damage_timer <= 0:
			is_taking_damage = false
			sprite.modulate = Color.WHITE
	
	# Handle attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# Handle knockback
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction)
	else:
		# Normal AI behavior
		ai_behavior(delta)
	
	move_and_slide()

func ai_behavior(delta):
	if not player:
		# Try to find player again if we lost reference
		find_player()
		return
	
	# Use detection area instead of distance calculation
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if player is in attack range (close distance check)
	if distance_to_player <= attack_range and attack_timer <= 0:
		print("Enemy attacking player! Distance: ", distance_to_player)
		attack_player()
	# Check if player is in detection range using the detection area
	elif player_in_detection_range:
		print("Enemy chasing player! Distance: ", distance_to_player)
		chase_player()
	else:
		# Idle behavior
		velocity = velocity.lerp(Vector2.ZERO, 0.1)

func chase_player():
	if not player:
		return
		
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	
	print("Chasing direction: ", direction, " Velocity: ", velocity)
	
	# Flip sprite based on movement direction
	if sprite:
		if direction.x > 0:
			sprite.flip_h = false
		elif direction.x < 0:
			sprite.flip_h = true

func attack_player():
	attack_timer = attack_cooldown
	
	# Simple damage to player (if player has take_damage method)
	if player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("Enemy attacked player for ", damage, " damage!")
	
	# Add attack animation/effects here
	flash_sprite(Color.RED, 0.1)

func take_damage(amount: int):
	if is_dead:
		return
	
	current_health -= amount
	print("Enemy took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
	
	# Flash sprite when taking damage
	flash_sprite(Color.RED, damage_flash_duration)
	
	# Add knockback effect
	if player:
		var knockback_direction = (global_position - player.global_position).normalized()
		knockback_velocity = knockback_direction * knockback_force
	
	# Check if dead
	if current_health <= 0:
		die()

func flash_sprite(color: Color, duration: float):
	is_taking_damage = true
	damage_timer = duration
	sprite.modulate = color

func die():
	is_dead = true
	print("Enemy died!")
	
	# Disable collision
	collision_shape.disabled = true
	
	# Death animation (simple fade out)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	
	# Optional: Drop items, add score, etc.
	on_death()

func on_death():
	# Override this in inherited enemy classes for specific death behavior
	# Examples: drop coins, items, play death sound, add to score, etc.
	pass

# Detection area callbacks
func _on_detection_area_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("Player entered detection range!")
		player_in_detection_range = true
		if not player:
			player = body  # Set player reference

func _on_detection_area_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("Player left detection range!")
		player_in_detection_range = false

# Utility function to check if enemy is alive
func is_alive() -> bool:
	return not is_dead and current_health > 0
