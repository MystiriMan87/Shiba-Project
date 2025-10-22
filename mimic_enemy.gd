extends CharacterBody2D
class_name Mimic

enum State {
	DISGUISED,  # Looks like a chest
	AWAKENING,  # Playing "open" animation before attacking
	HOSTILE,    # Chasing and attacking player
	ATTACKING,  # Currently performing attack
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

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	add_to_group("mimics")
	add_to_group("chests")  
	current_health = max_health
	current_state = State.DISGUISED
	
	setup_detection_area()
	
	setup_attack_area()
	
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	if animation_player and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	
	collision_layer = 0  
	collision_mask = 1  

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
	detection_area.collision_mask = 1 
	
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
	attack_area.collision_mask = 1  
	attack_area.monitoring = false

func _physics_process(delta):
	if attack_timer > 0.0:
		attack_timer -= delta
	
	match current_state:
		State.DISGUISED:
			pass
			
		State.AWAKENING:
			velocity = Vector2.ZERO
			
		State.HOSTILE:
			handle_hostile_state(delta)
		
		State.ATTACKING:
			velocity = Vector2.ZERO
			move_and_slide()
			
		State.DEAD:
			pass

func handle_hostile_state(delta):
	if not player or not is_instance_valid(player):
		player = find_nearest_player()
	
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		print("Distance to player: ", distance, " | Attack range: ", attack_range, " | Attack timer: ", attack_timer)
		
		if distance > chase_range:
			player = null
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
			if animation_player and animation_player.has_animation("idle"):
				animation_player.play("idle")
			move_and_slide()
			return
		
		if distance <= attack_range and attack_timer <= 0.0:
			print("ATTEMPTING ATTACK!")
			velocity = Vector2.ZERO
			perform_attack()
			return  
		else:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
			
			print("Chasing player - velocity: ", velocity)
			
			if animation_player and animation_player.has_animation("run"):
				if animation_player.current_animation != "run":
					animation_player.play("run")
			
			if sprite:
				sprite.flip_h = direction.x < 0
			
			move_and_slide()
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
		move_and_slide()

func perform_attack():
	print("=== PERFORM ATTACK CALLED ===")
	print("Previous state: ", current_state)
	
	current_state = State.ATTACKING
	attack_timer = attack_cooldown
	velocity = Vector2.ZERO
	
	print("New state: ", current_state)
	print("Attack timer set to: ", attack_timer)
	
	if animation_player:
		print("Has animation player")
		if animation_player.has_animation("bite"):
			print("Playing bite animation")
			animation_player.play("bite")
		else:
			print("NO BITE ANIMATION FOUND!")
			current_state = State.HOSTILE
			return
	else:
		print("NO ANIMATION PLAYER!")
	
	await get_tree().create_timer(0.2).timeout
	
	if not is_instance_valid(self) or current_state != State.ATTACKING:
		return
	
	if attack_area:
		print("Checking attack area...")
		print("Attack area monitoring: ", attack_area.monitoring)
		print("Attack area position: ", attack_area.global_position)
		
		attack_area.monitoring = true
		
		await get_tree().process_frame
		
		var bodies = attack_area.get_overlapping_bodies()
		print("Bodies in attack area: ", bodies.size())
		
		for body in bodies:
			print("  Body: ", body.name, " | Groups: ", body.get_groups())
			if body.has_method("take_damage") and body.is_in_group("player"):
				body.take_damage(attack_damage, self)
				print("✓ HIT PLAYER WITH ATTACK AREA!")
				flash_hit()
		
		attack_area.monitoring = false
	
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		print("Manual check - Distance to player: ", distance, " | Attack range: ", attack_range)
		
		if distance <= attack_range:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage, self)
				print("✓ HIT PLAYER WITH MANUAL CHECK!")
				flash_hit()

func flash_hit():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.5), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func interact():
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
	
	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
	else:
		become_hostile()

func become_hostile():
	print("Mimic is now hostile!")
	current_state = State.HOSTILE
	
	collision_layer = 4 
	collision_mask = 8   
	
	player = find_nearest_player()
	
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
	if current_state == State.DISGUISED:
		print("Mimic is invulnerable while disguised! Must interact to wake it.")
		return
	
	if current_state == State.DEAD:
		return
	
	current_health -= amount
	print("Mimic took ", amount, " damage! Health: ", current_health)
	
	flash_damage()
	
	if animation_player and animation_player.has_animation("hurt") and current_state != State.ATTACKING:
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
	
	if animation_player and animation_player.has_animation("die"):
		animation_player.play("die")
	else:
		spawn_loot()
		queue_free()

func spawn_loot():
	print("=== SPAWNING LOOT ===")
	var scene_root = get_tree().current_scene
	if not scene_root:
		print("No scene root!")
		return
	
	print("Loot items: ", loot_items)
	
	for i in range(loot_items.size()):
		var item_id = loot_items[i]
		print("Spawning item: ", item_id)
		
		var angle = (i * TAU) / float(max(1, loot_items.size()))
		var dir = Vector2(cos(angle), sin(angle))
		var spawn_pos = global_position + dir * loot_spawn_radius
		
		print("  Spawn position: ", spawn_pos)
		
		var pickup_scene = load("res://scenes/PickupItem.tscn")
		if not pickup_scene:
			print("  ERROR: Could not load PickupItem.tscn!")
			continue
		
		var pickup = pickup_scene.instantiate()
		if not pickup:
			print("  ERROR: Could not instantiate pickup!")
			continue
		
		scene_root.call_deferred("add_child", pickup)
		
		pickup.global_position = spawn_pos
		
		if pickup.has_method("set_item"):
			pickup.call_deferred("set_item", item_id, 1)
			print("  ✓ Pickup created with set_item()")
		elif pickup.has_method("setup_item"):
			pickup.call_deferred("setup_item", item_id, 1)
			print("  ✓ Pickup created with setup_item()")
		elif "item_id" in pickup:
			pickup.item_id = item_id
			pickup.quantity = 1
			print("  ✓ Pickup created by setting properties")
		else:
			print("  ERROR: Pickup has no method to set item!")
		
		pickup.visible = true
		print("  Pickup added to scene")

func get_knockback_force() -> float:
	return 100.0

func _on_animation_finished(anim_name: String):
	print("Animation finished: ", anim_name, " | Current state: ", current_state)
	
	match anim_name:
		"open":
			become_hostile()
		
		"bite":
			print("Bite animation finished, returning to HOSTILE state")
			current_state = State.HOSTILE
			
			if player and is_instance_valid(player):
				var distance = global_position.distance_to(player.global_position)
				if distance > attack_range and animation_player and animation_player.has_animation("run"):
					animation_player.play("run")
		
		"hurt":
			if current_state == State.HOSTILE:
				if animation_player and animation_player.has_animation("run"):
					animation_player.play("run")
		
		"die":
			spawn_loot()
			queue_free()

func _on_detection_body_entered(body: Node2D):
	if current_state == State.DISGUISED and body.is_in_group("player"):
		print("Player near mimic (still disguised)")

func _on_detection_body_exited(body: Node2D):
	if body == player:
		print("Player left detection range")
