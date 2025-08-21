extends CharacterBody2D

@export var max_health = 3
@export var speed = 50
@export var damage = 1
@export var knockback_force = 200
@export var detection_range = 150
@export var attack_range = 100

# Jump attack settings
@export var jump_force = 300
@export var jump_windup_duration = 0.8
@export var jump_duration = 0.6
@export var jump_cooldown = 2.5
@export var jump_arc_height = 150
@export var land_damage_radius = 40

# Walking settings
@export var walk_acceleration = 300
@export var walk_friction = 200
@export var walk_animation_speed = 1.0  # Speed multiplier for walk animation

# Health and state
var current_health
var is_dead = false
var is_taking_damage = false
var damage_timer = 0.0
var damage_flash_duration = 0.2

# Combat and movement states
var attack_timer = 0.0
var knockback_velocity = Vector2.ZERO
var knockback_friction = 0.15

# Jump attack variables
var is_jumping = false
var jump_start_position = Vector2.ZERO
var jump_target_position = Vector2.ZERO
var jump_progress = 0.0
var jump_windup_timer = 0.0

# Walking variables
var target_velocity = Vector2.ZERO
var is_moving = false

# AI States for slime behavior
enum SlimeState {
	IDLE,
	WALKING,       # Walking towards player
	JUMP_WINDUP,   # Preparing to jump attack
	JUMPING,       # Attack jump in the air
	LANDING,       # Just landed from attack
	COOLDOWN       # Post-jump recovery
}

var current_state = SlimeState.IDLE
var player_in_detection_range = false

# Chase behavior
var chase_duration = 3.0
var chase_timer = 0.0

# Player reference
var player = null

# Node references
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var collision_shape = $CollisionShape2D
@onready var health_bar = get_node("HealthBar") if has_node("HealthBar") else null
@onready var detection_area = get_node("DetectionArea") if has_node("DetectionArea") else null
@onready var attack_area = get_node("AttackArea") if has_node("AttackArea") else null
@onready var attack_collision = get_node("AttackArea/CollisionShape2D") if has_node("AttackArea/CollisionShape2D") else null
@onready var windup_bar = get_node("WindupBar") if has_node("WindupBar") else null

func _ready():
	current_health = max_health
	print("=== SLIME ENEMY READY ===")
	
	# Set collision layers
	collision_layer = 4
	collision_mask = 1
	print("Slime physics layers - Layer: 4, Mask: 1")
	
	# Set up health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Set up wind-up bar for jump preparation
	if has_node("WindupBar"):
		windup_bar = get_node("WindupBar")
		if windup_bar is ProgressBar:
			windup_bar.max_value = 100
			windup_bar.value = 0
			windup_bar.visible = false
			windup_bar.modulate = Color.YELLOW
			print("✓ Jump windup bar configured")
		else:
			print("✗ WindupBar node is not a ProgressBar!")
	
	# Set up attack system
	setup_attack_area()
	setup_detection_area()
	
	# Find player
	call_deferred("find_player")
	
	# Start idle animation
	if animation_player:
		play_animation("idle")
	
	print("Slime starting in IDLE state")

func setup_attack_area():
	if not attack_area:
		attack_area = Area2D.new()
		attack_area.name = "AttackArea"
		add_child(attack_area)
		
		attack_collision = CollisionShape2D.new()
		attack_area.add_child(attack_collision)
		
		var shape = CircleShape2D.new()
		shape.radius = land_damage_radius
		attack_collision.shape = shape
		
		print("Auto-created slime attack area")
	
	if attack_area:
		attack_area.monitoring = false
		attack_area.collision_layer = 4
		attack_area.collision_mask = 1
		
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)
		
		print("Slime attack area configured")

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
		print("ERROR: No player found!")

func _physics_process(delta):
	if is_dead:
		return
	
	# Handle damage flash
	if is_taking_damage:
		damage_timer -= delta
		if damage_timer <= 0:
			is_taking_damage = false
			sprite.modulate = Color.WHITE
	
	# Handle attack cooldown timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# Handle knockback (but not during jumps)
	if knockback_velocity.length() > 5 and not is_jumping:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction)
		move_and_slide()
		return
	
	# SLIME STATE MACHINE
	match current_state:
		SlimeState.IDLE:
			handle_idle_state(delta)
		
		SlimeState.WALKING:
			handle_walking_state(delta)
		
		SlimeState.JUMP_WINDUP:
			handle_jump_windup_state(delta)
		
		SlimeState.JUMPING:
			handle_jumping_state(delta)
		
		SlimeState.LANDING:
			handle_landing_state(delta)
		
		SlimeState.COOLDOWN:
			handle_cooldown_state(delta)
	
	# Only move_and_slide if not jumping (walking uses normal physics)
	if not is_jumping:
		move_and_slide()

func handle_idle_state(delta):
	# Stop moving
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	# Force idle animation to play
	if animation_player:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
			animation_player.speed_scale = 1.0
			print("Playing idle animation")
	
	# Check if player is in range to start chasing
	if player_in_detection_range and player:
		print("IDLE → WALKING: Player detected, starting to walk")
		current_state = SlimeState.WALKING
		chase_timer = chase_duration

func handle_walking_state(delta):
	if not player:
		current_state = SlimeState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if we should jump attack
	if distance_to_player <= attack_range and attack_timer <= 0:
		print("WALKING → JUMP_WINDUP: Player in attack range")
		start_jump_windup()
		return
	
	# Continue chasing if player is in range
	if player_in_detection_range:
		chase_timer = chase_duration
	else:
		chase_timer -= delta
	
	if chase_timer > 0:
		# Calculate direction to player
		var direction_to_player = (player.global_position - global_position).normalized()
		target_velocity = direction_to_player * speed
		
		# Move towards target velocity with acceleration
		velocity = velocity.move_toward(target_velocity, walk_acceleration * delta)
		
		# Check if we're actually moving
		is_moving = velocity.length() > 5
		
		# Flip sprite based on movement direction
		if sprite and direction_to_player.x != 0:
			sprite.flip_h = direction_to_player.x < 0
		
		# Play appropriate animation based on movement
		if is_moving:
			play_walking_animation()
		else:
			play_animation("idle")
			
		print_rich("[color=green]Walking towards player - Speed: %.1f[/color]" % velocity.length())
	else:
		print("WALKING → IDLE: Lost player")
		current_state = SlimeState.IDLE

func handle_jump_windup_state(delta):
	# Stop moving during windup
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	play_animation("jump_prepare")
	
	jump_windup_timer -= delta
	
	# Update windup progress bar
	if windup_bar:
		var progress = (jump_windup_duration - jump_windup_timer) / jump_windup_duration
		windup_bar.value = progress * 100
		windup_bar.modulate = Color.YELLOW.lerp(Color.RED, progress)
		
		if not windup_bar.visible:
			windup_bar.visible = true
	
	# Start jump when windup complete
	if jump_windup_timer <= 0:
		execute_jump()

func handle_jumping_state(delta):
	# Custom jump movement with arc (no regular physics during jump)
	jump_progress += delta / jump_duration
	jump_progress = clamp(jump_progress, 0.0, 1.0)
	
	# Calculate position along jump arc
	var horizontal_pos = jump_start_position.lerp(jump_target_position, jump_progress)
	
	# Add vertical arc (parabola)
	var arc_progress = jump_progress * 2.0 - 1.0  # -1 to 1
	var height_offset = jump_arc_height * (1.0 - arc_progress * arc_progress)
	
	global_position = horizontal_pos + Vector2(0, -height_offset)
	
	# Play synchronized jump animation
	play_animation_synced("jump_air", jump_duration, 3.0)
	
	# Add rotation during jump
	sprite.rotation = sin(jump_progress * PI) * 0.3
	
	# Check if jump is complete
	if jump_progress >= 1.0:
		land_jump()

func handle_landing_state(delta):
	target_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	is_moving = false
	
	play_animation("jump_land")
	
	# Brief landing state, then go to cooldown
	if not animation_player or not animation_player.is_playing():
		print("LANDING → COOLDOWN")
		current_state = SlimeState.COOLDOWN
		attack_timer = jump_cooldown

func handle_cooldown_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	play_animation("idle")
	
	if attack_timer <= 0:
		print("COOLDOWN → IDLE: Ready to act again")
		current_state = SlimeState.IDLE

func play_walking_animation():
	"""Play the appropriate walking animation with speed synchronization"""
	if not animation_player:
		return
	
	# Use jump animation for walking (since that's what you have)
	var walk_anim = "jump"  # Your walking cycle animation
	
	# Check if we have other walk animations
	if animation_player.has_animation("walk"):
		walk_anim = "walk"
	elif animation_player.has_animation("move"):
		walk_anim = "move"
	
	# Calculate animation speed based on movement speed
	# Faster movement = faster animation
	var speed_ratio = velocity.length() / speed  # 0 to 1
	var animation_speed = walk_animation_speed * (0.5 + speed_ratio * 0.5)  # 0.5x to 1.0x speed
	
	# Only change animation if not already playing the walk animation
	if animation_player.current_animation != walk_anim:
		animation_player.play(walk_anim)
		print("Started walking animation: ", walk_anim)
	
	# Update animation speed to match movement speed
	animation_player.speed_scale = animation_speed

func start_jump_windup():
	print("=== STARTING JUMP WINDUP ===")
	current_state = SlimeState.JUMP_WINDUP
	jump_windup_timer = jump_windup_duration
	
	# Show windup bar
	if windup_bar:
		windup_bar.visible = true
		windup_bar.value = 0
		windup_bar.modulate = Color.YELLOW
	
	# Store jump target (predict player position)
	if player:
		var player_velocity = Vector2.ZERO
		if player.has_method("get_velocity"):
			player_velocity = player.get_velocity()
		elif "velocity" in player:
			player_velocity = player.velocity
		
		jump_target_position = player.global_position + (player_velocity * jump_windup_duration * 0.5)
	else:
		jump_target_position = global_position + Vector2(50, 0)
	
	print("Jump target set to: ", jump_target_position)

func execute_jump():
	print("=== EXECUTING JUMP ===")
	current_state = SlimeState.JUMPING
	is_jumping = true
	jump_progress = 0.0
	jump_start_position = global_position
	
	# Hide windup bar
	if windup_bar:
		windup_bar.visible = false
	
	# Visual effects for jump start
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 0.8)
	
	print("Jumping from ", jump_start_position, " to ", jump_target_position)

func land_jump():
	print("=== SLIME LANDED ===")
	current_state = SlimeState.LANDING
	is_jumping = false
	jump_progress = 0.0
	
	# Reset sprite effects and animation speed
	sprite.rotation = 0
	sprite.modulate = Color.WHITE
	if animation_player:
		animation_player.speed_scale = 1.0
	
	# Enable attack area for landing damage
	if attack_area:
		attack_area.monitoring = true
		print("Landing damage area activated")
		
		# Disable after brief moment
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func(): 
			if attack_area:
				attack_area.monitoring = false
				print("Landing damage area deactivated")
		)
	
	print("Slime landed at: ", global_position)

func play_animation_synced(anim_name: String, movement_duration: float, speed_multiplier: float = 2.0):
	if not animation_player:
		return
	
	var target_anim = anim_name
	
	# Handle fallback animations
	if not animation_player.has_animation(anim_name):
		match anim_name:
			"jump_air":
				if animation_player.has_animation("jump"):
					target_anim = "jump"
				else:
					target_anim = "idle"
			"jump_prepare":
				if animation_player.has_animation("windup"):
					target_anim = "windup"
				else:
					target_anim = "idle"
			"jump_land":
				if animation_player.has_animation("land"):
					target_anim = "land"
				else:
					target_anim = "idle"
			_:
				if animation_player.has_animation("idle"):
					target_anim = "idle"
				else:
					return
	
	if not animation_player.has_animation(target_anim):
		return
	
	var anim_length = animation_player.get_animation(target_anim).length
	if anim_length <= 0:
		print("Warning: Animation ", target_anim, " has invalid length: ", anim_length)
		return
	
	# Only set up sync when starting a new animation
	if animation_player.current_animation != target_anim:
		var sync_speed = (anim_length / movement_duration) * speed_multiplier
		
		animation_player.play(target_anim)
		animation_player.speed_scale = sync_speed
		
		print("Started synced animation: ", target_anim, " | Speed: ", sync_speed)

func play_animation(anim_name: String, speed_multiplier: float = 1.0):
	if not animation_player:
		return
	
	animation_player.speed_scale = speed_multiplier
	
	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
	else:
		# Fallback animations
		match anim_name:
			"move":
				if animation_player.has_animation("walk"):
					animation_player.play("walk")
				elif animation_player.has_animation("jump"):
					animation_player.play("jump")
			"jump_prepare":
				if animation_player.has_animation("windup"):
					animation_player.play("windup")
			"jump_air":
				if animation_player.has_animation("jump"):
					animation_player.play("jump")
			"jump_land":
				if animation_player.has_animation("land"):
					animation_player.play("land")
			_:
				if animation_player.has_animation("idle"):
					animation_player.play("idle")

func take_damage(amount: int):
	if is_dead:
		return
	
	# Interrupt jump windup if taking damage
	if current_state == SlimeState.JUMP_WINDUP:
		cancel_jump_windup()
	
	# Interrupt walking if taking damage
	if current_state == SlimeState.WALKING:
		# Brief pause when hit, then return to walking
		target_velocity = Vector2.ZERO
	
	current_health -= amount
	print("Slime took", amount, "damage! Health:", current_health)
	
	if health_bar:
		health_bar.value = current_health
	
	flash_sprite(Color.RED, damage_flash_duration)
	
	# Knockback (but not during jump)
	if player and not is_jumping:
		var knockback_dir = (global_position - player.global_position).normalized()
		knockback_velocity = knockback_dir * knockback_force
	
	if current_health <= 0:
		die()

func cancel_jump_windup():
	print("Jump windup cancelled by damage!")
	current_state = SlimeState.IDLE
	
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
	is_jumping = false
	is_moving = false
	current_state = SlimeState.IDLE
	print("Slime died!")
	
	if windup_bar:
		windup_bar.visible = false
	
	collision_shape.disabled = true
	
	# Death animation
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 0.5), 0.5)
	tween.tween_callback(queue_free)

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		print("Player ENTERED slime detection range")
		player_in_detection_range = true
		if not player:
			player = body

func _on_detection_area_exited(body):
	if body.is_in_group("player"):
		print("Player EXITED slime detection range")
		player_in_detection_range = false

func _on_attack_area_body_entered(body):
	print("=== SLIME LANDING HIT ===")
	print("Hit target: ", body.name)
	
	if current_state == SlimeState.LANDING:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				var damage_result = body.take_damage(damage, self)
				if damage_result:
					print("SUCCESS: Slime landing dealt ", damage, " damage!")
					flash_sprite(Color.YELLOW, 0.3)
					apply_player_stun_flash(body)
				else:
					print("Player was immune to landing damage")

func apply_player_stun_flash(player_body):
	if not player_body or not player_body.has_method("get_node"):
		return
	
	var player_sprite = null
	if player_body.has_node("Sprite2D"):
		player_sprite = player_body.get_node("Sprite2D")
	elif player_body.has_node("AnimatedSprite2D"):
		player_sprite = player_body.get_node("AnimatedSprite2D")
	
	if not player_sprite:
		print("Could not find player sprite for flashing effect")
		return
	
	var stun_duration = 1.0
	if "immunity_duration" in player_body:
		stun_duration = player_body.immunity_duration
	elif "stun_duration" in player_body:
		stun_duration = player_body.stun_duration
	elif "invulnerability_time" in player_body:
		stun_duration = player_body.invulnerability_time
	
	print("Applying player flash for ", stun_duration, " seconds")
	
	var flash_tween = create_tween()
	flash_tween.set_loops(int(stun_duration * 6))
	
	flash_tween.tween_method(
		func(alpha): player_sprite.modulate.a = alpha,
		1.0,
		0.3,
		0.08
	)
	flash_tween.tween_method(
		func(alpha): player_sprite.modulate.a = alpha,
		0.3,
		1.0,
		0.08
	)
	
	flash_tween.tween_callback(func(): 
		if player_sprite:
			player_sprite.modulate.a = 1.0
	)

func is_alive() -> bool:
	return not is_dead and current_health > 0

func get_knockback_force() -> float:
	return knockback_force
