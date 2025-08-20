extends CharacterBody2D

@export var speed = 300
@export var friction = 0.2
@export var acceleration = 0.1
@export var attack_damage = 1
@export var attack_duration = 0.4  # How long the attack lasts
@export var attack_cooldown = 0.1   # Cooldown after attack before next attack

# Attack state variables
var is_attacking = false
var attack_timer = 0.0
var cooldown_timer = 0.0
var last_direction = Vector2.DOWN  # Default facing direction

# Node references (assign these in the editor or via code)
@onready var sprite = $Sprite2D  # Your player sprite
@onready var attack_area = $AttackArea  # Area2D node for attack detection
@onready var attack_collision = $AttackArea/CollisionShape2D  # CollisionShape2D child of AttackArea
@onready var attack_sprite = $AttackSprite  # Sprite2D for sword visual (optional)

func _ready():
	# Add player to group so camera and enemies can find it
	add_to_group("player")
	print("Player added to group. Player name: ", name)
	
	# Make sure attack area is initially disabled
	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_body_entered)

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
	# Handle attack timing
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# Handle attack input
	if Input.is_action_just_pressed('Attack') and not is_attacking and cooldown_timer <= 0:
		start_attack()
	
	# Handle movement (now works during attacks too)
	var direction = get_input()
	
	# Update last direction for attacks (only when moving and not attacking)
	if direction.length() > 0 and not is_attacking:
		last_direction = direction.normalized()
		# Update sprite direction here if you have directional sprites
		update_sprite_direction(last_direction)
	
	if direction.length() > 0:
		velocity = velocity.lerp(direction.normalized() * speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	
	move_and_slide()

func start_attack():
	is_attacking = true
	attack_timer = attack_duration
	
	# Enable attack area
	if attack_area:
		attack_area.monitoring = true
	
	# Position attack hitbox based on facing direction
	position_attack_hitbox(last_direction)
	
	# Update sprite to attack animation
	update_attack_sprite(last_direction)
	
	print("Attack started in direction: ", last_direction)

func end_attack():
	is_attacking = false
	cooldown_timer = attack_cooldown
	
	# Disable attack area
	if attack_area:
		attack_area.monitoring = false
	
	# Hide attack sprite
	if attack_sprite:
		attack_sprite.visible = false
	
	# Return to normal sprite
	update_sprite_direction(last_direction)

func position_attack_hitbox(direction: Vector2):
	if not attack_collision:
		return
	
	var offset_distance = 32  # Adjust based on your sprite size
	var hitbox_offset = direction * offset_distance
	
	if attack_collision:
		attack_collision.position = hitbox_offset
	
	# Rotate hitbox shape if needed (for rectangular shapes)
	if direction.x != 0:  # Horizontal attack
		attack_collision.rotation = 0
	else:  # Vertical attack
		attack_collision.rotation = PI/2

func update_attack_sprite(direction: Vector2):
	if not attack_sprite:
		return
	
	attack_sprite.visible = true
	var sword_offset = direction * 24  # Distance from player center
	attack_sprite.position = sword_offset
	
	# Rotate sword sprite based on direction
	if direction == Vector2.RIGHT:
		attack_sprite.rotation = 0
		attack_sprite.flip_h = false
	elif direction == Vector2.LEFT:
		attack_sprite.rotation = 0
		attack_sprite.flip_h = true
	elif direction == Vector2.DOWN:
		attack_sprite.rotation = PI/2
		attack_sprite.flip_h = false
	elif direction == Vector2.UP:
		attack_sprite.rotation = -PI/2
		attack_sprite.flip_h = false

func update_sprite_direction(direction: Vector2):
	if not sprite:
		return
	
	# Update your main sprite based on direction
	# This is where you'd change animation states or sprite frames
	if direction.x > 0:
		sprite.flip_h = false  # Facing right
	elif direction.x < 0:
		sprite.flip_h = true   # Facing left
	# Add up/down sprite changes here if you have them

func _on_attack_area_body_entered(body):
	# Handle what happens when sword hits something
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
		print("Hit enemy for ", attack_damage, " damage!")
	elif body.has_method("on_sword_hit"):
		body.on_sword_hit()
	
	# Add hit effects here (particles, sound, screen shake, etc.)

# Optional: Function to check if currently attacking (useful for other scripts)
func get_is_attacking() -> bool:
	return is_attacking

# Optional: Function to get current facing direction
func get_facing_direction() -> Vector2:
	return last_direction
