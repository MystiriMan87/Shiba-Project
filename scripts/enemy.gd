extends CharacterBody2D

@export var max_health = 3
@export var speed = 50
@export var damage = 1
@export var knockback_force = 200
@export var detection_range = 150
@export var attack_range = 100  # Increased from 50
@export var attack_cooldown = 2.0

# Wind-up attack system
@export var windup_duration = 1.2
@export var attack_duration = 0.3
@export var attack_reach = 100

# Health and state
var current_health
var is_dead = false
var is_taking_damage = false
var damage_timer = 0.0
var damage_flash_duration = 0.2

# Combat states - SIMPLIFIED
var attack_timer = 0.0
var is_winding_up = false
var windup_timer = 0.0
var is_attacking = false
var attack_active_timer = 0.0
var knockback_velocity = Vector2.ZERO
var knockback_friction = 0.15

# AI States - CLEAR STATE MACHINE
enum EnemyState {
	IDLE,
	CHASING,
	PREPARING_ATTACK,  # Wind-up phase
	ATTACKING,         # Active attack
	COOLDOWN          # Post-attack cooldown
}

var current_state = EnemyState.IDLE
var player_in_detection_range = false

# Chase behavior
var chase_duration = 3.0
var chase_timer = 0.0

# Player reference
var player = null

# Node references
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var health_bar = get_node("HealthBar") if has_node("HealthBar") else null
@onready var detection_area = get_node("DetectionArea") if has_node("DetectionArea") else null
@onready var attack_area = get_node("AttackArea") if has_node("AttackArea") else null
@onready var attack_collision = get_node("AttackArea/CollisionShape2D") if has_node("AttackArea/CollisionShape2D") else null
@onready var windup_bar = get_node("WindupBar") if has_node("WindupBar") else null

func _ready():
	current_health = max_health
	print("=== ENEMY READY ===")
	
	# FIX: Set enemy collision layers
	collision_layer = 4  # Enemy body on layer 4
	collision_mask = 1   # Enemy can collide with player/environment on layer 1
	print("Enemy physics layers - Layer: 4, Mask: 1")
	
	# Set up health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# IMPROVED: Better WindUp bar setup with debugging
	if has_node("WindupBar"):
		windup_bar = get_node("WindupBar")
		if windup_bar is ProgressBar:
			windup_bar.max_value = 100
			windup_bar.value = 0
			windup_bar.visible = false
			windup_bar.modulate = Color.ORANGE
			print("✓ Wind-up bar found and configured: ", windup_bar.name)
		else:
			print("✗ WindupBar node is not a ProgressBar! It's a: ", windup_bar.get_class())
	else:
		print("✗ WindupBar node not found! Available children:")
		for child in get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	
	# Set up attack system
	setup_attack_area()
	setup_detection_area()
	
	# Find player
	call_deferred("find_player")
	
	print("Enemy starting in IDLE state")

func setup_attack_area():
	if not attack_area:
		# Create attack area automatically
		attack_area = Area2D.new()
		attack_area.name = "AttackArea"
		add_child(attack_area)
		
		attack_collision = CollisionShape2D.new()
		attack_area.add_child(attack_collision)
		
		var shape = CircleShape2D.new()
		shape.radius = 30
		attack_collision.shape = shape
		
		print("Auto-created AttackArea")
	
	if attack_area:
		attack_area.monitoring = false
		# FIX: Set proper collision layers for enemy attacks
		attack_area.collision_layer = 4   # Enemy attacks are on layer 4
		attack_area.collision_mask = 1    # Can hit player on layer 1
		
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)
		
		print("Attack area configured - Layer: 4, Mask: 1")

func setup_detection_area():
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_detection_area_entered):
			detection_area.body_entered.connect(_on_detection_area_entered)
		if not detection_area.body_exited.is_connected(_on_detection_area_exited):
			detection_area.body_exited.connect(_on_detection_area_exited)
		print("Detection area configured")

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Found player:", player.name)
	else:
		print("ERROR: No player found! Add player to 'player' group")

func _physics_process(delta):
	if is_dead:
		return
	
	# Debug: Print current state every 2 seconds
	if Engine.get_process_frames() % 120 == 0:
		print("=== ENEMY STATE: ", EnemyState.keys()[current_state], " ===")
		if player:
			print("Distance to player: ", global_position.distance_to(player.global_position))
		print("Attack timer: ", attack_timer)
	
	# Handle damage flash
	if is_taking_damage:
		damage_timer -= delta
		if damage_timer <= 0:
			is_taking_damage = false
			sprite.modulate = Color.WHITE
	
	# Handle attack cooldown timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# Handle knockback
	if knockback_velocity.length() > 5:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction)
		move_and_slide()
		return
	
	# STATE MACHINE - This is the key fix!
	match current_state:
		EnemyState.IDLE:
			handle_idle_state(delta)
		
		EnemyState.CHASING:
			handle_chase_state(delta)
		
		EnemyState.PREPARING_ATTACK:
			handle_windup_state(delta)
		
		EnemyState.ATTACKING:
			handle_attack_state(delta)
		
		EnemyState.COOLDOWN:
			handle_cooldown_state(delta)
	
	move_and_slide()

func handle_idle_state(delta):
	velocity = velocity.lerp(Vector2.ZERO, 0.1)
	
	# Check if player entered detection range
	if player_in_detection_range and player:
		print("IDLE → CHASING: Player detected")
		current_state = EnemyState.CHASING
		chase_timer = chase_duration

func handle_chase_state(delta):
	if not player:
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# DEBUG: Print detailed state info every few frames
	if Engine.get_process_frames() % 30 == 0:  # Every half second at 60fps
		print("=== CHASE DEBUG ===")
		print("Distance to player: ", distance_to_player)
		print("Attack range: ", attack_range)
		print("Attack timer: ", attack_timer)
		print("Player position: ", player.global_position)
		print("Enemy position: ", global_position)
		print("In attack range: ", distance_to_player <= attack_range)
		print("Attack ready: ", attack_timer <= 0)
	
	# CRITICAL FIX: Check attack range with more generous threshold
	if distance_to_player <= (attack_range + 10) and attack_timer <= 0:  # Added +10 buffer
		print("CHASING → PREPARING_ATTACK: Player in range (", distance_to_player, ") - Attack range: ", attack_range)
		start_attack_preparation()
		return
	
	# Continue chasing if player still in detection or chase timer active
	if player_in_detection_range:
		chase_timer = chase_duration
	else:
		chase_timer -= delta
	
	if chase_timer > 0:
		# Chase the player - SLOW DOWN when getting close
		var direction = (player.global_position - global_position).normalized()
		
		# Slow down when approaching attack range to avoid overshooting
		var chase_speed = speed
		if distance_to_player <= (attack_range + 30):  # Slow down when close
			chase_speed = speed * 0.3  # Much slower approach
			print("SLOWING DOWN - Close to attack range: ", distance_to_player)
		
		velocity = direction * chase_speed
		
		# Flip sprite
		if sprite and direction.x != 0:
			sprite.flip_h = direction.x < 0
		
		# Only print occasionally to avoid spam
		if Engine.get_process_frames() % 60 == 0:
			print("Chasing player, distance:", distance_to_player, " speed:", chase_speed)
	else:
		# Stop chasing
		print("CHASING → IDLE: Lost player")
		current_state = EnemyState.IDLE

func handle_windup_state(delta):
	# STOP MOVING during wind-up
	velocity = Vector2.ZERO
	
	windup_timer -= delta
	
	# IMPROVED: Update wind-up bar with better debugging
	if windup_bar:
		var progress = (windup_duration - windup_timer) / windup_duration
		var new_value = progress * 100
		
		# Debug every 10 frames to avoid spam
		if Engine.get_process_frames() % 10 == 0:
			print("WindUp Progress: ", progress, " | Bar Value: ", windup_bar.value, " → ", new_value)
		
		windup_bar.value = new_value
		windup_bar.modulate = Color.ORANGE.lerp(Color.RED, progress)
		
		# Ensure bar is visible
		if not windup_bar.visible:
			windup_bar.visible = true
			print("Made WindUp bar visible!")
	else:
		print("WindUp bar is null! Cannot update.")
	
	# Wind-up complete
	if windup_timer <= 0:
		execute_attack()

func handle_attack_state(delta):
	# STOP MOVING during attack
	velocity = Vector2.ZERO
	
	attack_active_timer -= delta
	
	print("Attacking... ", attack_active_timer, " seconds left")
	
	if attack_active_timer <= 0:
		end_attack()

func handle_cooldown_state(delta):
	# STOP MOVING during cooldown
	velocity = Vector2.ZERO
	
	if attack_timer <= 0:
		print("COOLDOWN → IDLE: Ready to act again")
		current_state = EnemyState.IDLE

func start_attack_preparation():
	print("=== STARTING WIND-UP ===")
	print("Current distance: ", global_position.distance_to(player.global_position) if player else "No player")
	print("Attack range: ", attack_range)
	
	current_state = EnemyState.PREPARING_ATTACK
	windup_timer = windup_duration
	
	# Show wind-up bar
	if windup_bar:
		windup_bar.visible = true
		windup_bar.value = 0
		windup_bar.modulate = Color.ORANGE
	
	# Visual indicator
	if sprite:
		sprite.modulate = Color(1.2, 0.9, 0.9)
	
	print("Wind-up started for", windup_duration, "seconds")
	print("Enemy state changed to: PREPARING_ATTACK")

func execute_attack():
	print("=== EXECUTING ATTACK ===")
	current_state = EnemyState.ATTACKING
	attack_active_timer = attack_duration
	attack_timer = attack_cooldown  # Set cooldown timer
	
	# Hide wind-up bar
	if windup_bar:
		windup_bar.visible = false
	
	# Set up attack hitbox
	if player and attack_area and attack_collision:
		var direction_to_player = (player.global_position - global_position).normalized()
		attack_collision.position = direction_to_player * attack_reach
		attack_area.monitoring = true
		
		print("Attack hitbox positioned at:", attack_collision.position)
		print("Attack monitoring ENABLED")
	
	# Flash red during attack
	if sprite:
		sprite.modulate = Color.RED

func end_attack():
	print("=== ATTACK ENDED ===")
	current_state = EnemyState.COOLDOWN
	
	# Disable attack area
	if attack_area:
		attack_area.monitoring = false
		print("Attack monitoring DISABLED")
	
	# Reset sprite
	if sprite:
		sprite.modulate = Color.WHITE
	
	print("Entering cooldown for", attack_cooldown, "seconds")

func _on_attack_area_body_entered(body):
	print("=== HIT DETECTED ===")
	print("Hit body name: ", body.name)
	print("Hit body class: ", body.get_class())
	print("Hit body groups: ", body.get_groups())
	print("Hit body collision layer: ", body.collision_layer)
	print("Current enemy state: ", EnemyState.keys()[current_state])
	print("Attack area monitoring: ", attack_area.monitoring if attack_area else "NULL")
	
	# Only damage during active attack state
	if current_state == EnemyState.ATTACKING:
		if body.is_in_group("player"):
			print("✓ Player confirmed in 'player' group")
			if body.has_method("take_damage"):
				print("✓ Player has take_damage method")
				var damage_result = body.take_damage(damage, self)
				print("Damage result: ", damage_result)
				if damage_result:
					print("SUCCESS: Dealt ", damage, " damage to player!")
					flash_sprite(Color.YELLOW, 0.3)
				else:
					print("FAILED: Player was immune or blocked damage")
			else:
				print("✗ Player missing take_damage method")
		else:
			print("✗ Hit target is not in 'player' group")
	else:
		print("✗ Hit detected but not in ATTACKING state")

func take_damage(amount: int):
	if is_dead:
		return
	
	# Interrupt attack preparation if taking damage
	if current_state == EnemyState.PREPARING_ATTACK:
		cancel_attack_preparation()
	
	current_health -= amount
	print("Enemy took", amount, "damage! Health:", current_health)
	
	if health_bar:
		health_bar.value = current_health
	
	flash_sprite(Color.RED, damage_flash_duration)
	
	# Knockback
	if player:
		var knockback_dir = (global_position - player.global_position).normalized()
		knockback_velocity = knockback_dir * knockback_force
	
	if current_health <= 0:
		die()

func cancel_attack_preparation():
	print("Attack preparation cancelled!")
	current_state = EnemyState.IDLE
	
	if windup_bar:
		windup_bar.visible = false
	
	if sprite:
		sprite.modulate = Color.WHITE

func flash_sprite(color: Color, duration: float):
	if sprite:
		sprite.modulate = color
	is_taking_damage = true
	damage_timer = duration

func die():
	is_dead = true
	current_state = EnemyState.IDLE
	print("Enemy died!")
	
	if windup_bar:
		windup_bar.visible = false
	
	collision_shape.disabled = true
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		print("Player ENTERED detection range")
		player_in_detection_range = true
		if not player:
			player = body

func _on_detection_area_exited(body):
	if body.is_in_group("player"):
		print("Player EXITED detection range")
		player_in_detection_range = false

func is_alive() -> bool:
	return not is_dead and current_health > 0
