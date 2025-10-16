extends CharacterBody2D
class_name Mimic

enum State {
	DISGUISED,  # Looks like a chest
	AWAKENING,  # Playing "open" animation before attacking
	HOSTILE,    # Chasing and attacking player
	DEAD        # Defeated
}

@export_group("Mimic Stats")
@export var max_health: int = 8
@export var move_speed: float = 150.0
@export var attack_damage: int = 2
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 50.0
@export var chase_range: float = 300.0

@export_group("Loot")
@export var loot_items: Array[String] = ["health_potion", "coin", "coin"]
@export var loot_spawn_radius: float = 20.0

@export_group("Disguise")
@export var can_be_unlocked: bool = false  # If true, mimic can pretend to be locked

var current_state: State = State.DISGUISED
var current_health: int = 0
var player: Node2D = null
var attack_timer: float = 0.0
var is_attacking: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	add_to_group("mimics")
	add_to_group("chests")  # Also add to chests so player can interact with it
	current_health = max_health
	current_state = State.DISGUISED
	
	# Setup detection area
	setup_detection_area()
	
	# Setup attack area
	setup_attack_area()
	
	# Start in idle (disguised as chest)
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	# Connect animation finished signal
	if animation_player and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	
	# While disguised, mimic shouldn't collide with attacks
	collision_layer = 0  # No collision layer while disguised
	collision_mask = 1   # Still collide with world

func setup_detection_area():
	if not detection_area:
		detection_area = Area2D.new()
		detection_area.name = "DetectionArea"
		add_child(detection_area)
		
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = detection_range
		shape.shape = circle
		detection_area.add_child(shape)
	
	detection_area.collision_layer = 0
	detection_area.collision_mask = 1  # Detect player
	
	if not detection_area.body_entered.is_connected(_on_detection_body_entered):
		detection_area.body_entered.connect(_on_detection_body_entered)
	if not detection_area.body_exited.is_connected(_on_detection_body_exited):
		detection_area.body_exited.connect(_on_detection_body_exited)

func setup_attack_area():
	if not attack_area:
		attack_area = Area2D.new()
		attack_area.name = "AttackArea"
		add_child(attack_area)
		
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = attack_range
		shape.shape = circle
		attack_area.add_child(shape)
	
	attack_area.collision_layer = 0
	attack_area.collision_mask = 1  # Hit player
	attack_area.monitoring = false

func _physics_process(delta):
	match current_state:
		State.DISGUISED:
			# Do nothing, wait for player interaction
			pass
			
		State.AWAKENING:
			# Wait for animation to finish
			pass
			
		State.HOSTILE:
			handle_hostile_state(delta)
			
		State.DEAD:
			# Do nothing, already dead
			pass

func handle_hostile_state(delta):
	if not player or not is_instance_valid(player):
		player = find_nearest_player()
	
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		# Stop chasing if player is too far
		if distance > chase_range:
			player = null
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
			if animation_player and animation_player.has_animation("idle"):
				animation_player.play("idle")
			return
		
		# Attack if in range
		if distance <= attack_range:
			velocity = Vector2.ZERO
			if attack_timer <= 0.0 and not is_attacking:
				perform_attack()
		else:
			# Chase player
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
			
			# Play run animation
			if animation_player and animation_player.has_animation("run"):
				if animation_player.current_animation != "run":
					animation_player.play("run")
			
			# Flip sprite based on direction
			if sprite:
				sprite.flip_h = direction.x < 0
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
	
	if attack_timer > 0.0:
		attack_timer -= delta
	
	move_and_slide()

func perform_attack():
	is_attacking = true
	attack_timer = attack_cooldown
	
	if animation_player and animation_player.has_animation("bite"):
		animation_player.play("bite")
	
	# Enable attack area briefly
	if attack_area:
		attack_area.monitoring = true
		
		# Damage any players in range
		var bodies = attack_area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("take_damage") and body.is_in_group("player"):
				body.take_damage(attack_damage, self)
				print("Mimic attacked player for ", attack_damage, " damage!")
		
		# Disable after a short delay
		await get_tree().create_timer(0.2).timeout
		if attack_area and is_instance_valid(attack_area):
			attack_area.monitoring = false

func interact():
	# This is called when player tries to "open" the mimic thinking it's a chest
	print("=== MIMIC INTERACT CALLED ===")
	print("Current state: ", current_state)
	
	if current_state == State.DISGUISED:
		print("Mimic is waking up!")
		awaken()
	else:
		print("Mimic already awake, state: ", current_state)

func awaken():
	print("Mimic awakens!")
	current_state = State.AWAKENING
	
	# Play the "open" animation (revealing it's a mimic)
	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
	else:
		# If no open animation, go straight to hostile
		become_hostile()

func become_hostile():
	print("Mimic is now hostile!")
	current_state = State.HOSTILE
	
	# Enable enemy collision layer so it can be hit now
	collision_layer = 4  # Enemy layer
	collision_mask = 1   # Collide with world
	
	# Find nearest player
	player = find_nearest_player()
	
	# Play run animation if we have a target
	if player and animation_player and animation_player.has_animation("run"):
		animation_player.play("run")

func find_nearest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	
	var nearest: Node2D = null
	var nearest_distance: float = INF
	
	for p in players:
		if p is Node2D:
			var dist = global_position.distance_to(p.global_position)
			if dist < nearest_distance:
				nearest_distance = dist
				nearest = p
	
	return nearest

func take_damage(amount: int, source: Node = null):
	# While disguised, mimic is invulnerable - only wake up on interaction
	if current_state == State.DISGUISED:
		print("Mimic is invulnerable while disguised! Must interact to wake it.")
		return
	
	if current_state == State.DEAD:
		return
	
	current_health -= amount
	print("Mimic took ", amount, " damage! Health: ", current_health)
	
	# Flash effect
	flash_damage()
	
	# Play hurt animation if available and not attacking
	if animation_player and animation_player.has_animation("hurt") and not is_attacking:
		animation_player.play("hurt")
	
	if current_health <= 0:
		die()

func flash_damage():
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func die():
	current_state = State.DEAD
	print("Mimic died!")
	
	# Play death animation
	if animation_player and animation_player.has_animation("die"):
		animation_player.play("die")
	else:
		spawn_loot()
		queue_free()

func spawn_loot():
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	for i in range(loot_items.size()):
		var angle = (i * TAU) / float(max(1, loot_items.size()))
		var dir = Vector2(cos(angle), sin(angle))
		var spawn_pos = global_position + dir * loot_spawn_radius
		
		var pickup = PickupItem.create_pickup_item(loot_items[i], spawn_pos, 1)
		if pickup:
			scene_root.add_child(pickup)

func get_knockback_force() -> float:
	return 100.0

func _on_animation_finished(anim_name: String):
	match anim_name:
		"open":
			# Finished awakening animation, become hostile
			become_hostile()
		
		"bite":
			# Finished attack animation
			is_attacking = false
			if current_state == State.HOSTILE and player:
				if animation_player and animation_player.has_animation("run"):
					animation_player.play("run")
		
		"hurt":
			# Finished hurt animation, return to appropriate state
			if current_state == State.HOSTILE:
				if animation_player and animation_player.has_animation("run"):
					animation_player.play("run")
		
		"die":
			# Finished death animation, spawn loot and remove
			spawn_loot()
			queue_free()

func _on_detection_body_entered(body: Node2D):
	# Only react if disguised and player gets close
	if current_state == State.DISGUISED and body.is_in_group("player"):
		print("Player near mimic (still disguised)")

func _on_detection_body_exited(body: Node2D):
	if body == player:
		print("Player left detection range")
