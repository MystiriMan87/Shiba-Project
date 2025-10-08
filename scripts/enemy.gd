extends CharacterBody2D

@export var scene_path = "res://scenes/enemy.tscn"
@export var max_health = 3
@export var speed = 50
@export var damage = 1
@export var knockback_force = 200
@export var detection_range = 150
@export var attack_range = 100

#@export var drop_chance: float = 0.7
#@export var rare_drop_chance: float = 0.1
#@export var min_drop_quantity: int = 1
#@export var max_drop_quantity: int = 3

#Place holders
#@export var common_drops: Array[String] = ["health_potion", "mana_potion", "coin"]
#@export var uncommon_drops: Array[String] = ["steel_sword", "magic_ring"]
#@export var rare_drops: Array[String] = ["legendary_sword", "ancient_artifact"]

@export var enemy_type: String = "slime" 

@export var jump_force = 300
@export var jump_windup_duration = 0.8
@export var jump_duration = 0.6
@export var jump_cooldown = 2.5
@export var jump_arc_height = 150
@export var land_damage_radius = 40

@export var walk_acceleration: float = 300.0
@export var walk_friction: float = 200.0
@export var walk_animation_speed = 1.0

var current_health
var is_dead = false
var is_taking_damage = false
var damage_timer = 0.0
var damage_flash_duration = 0.2

var attack_timer = 0.0
var knockback_velocity = Vector2.ZERO
var knockback_friction = 0.15

var is_jumping = false
var jump_start_position = Vector2.ZERO
var jump_target_position = Vector2.ZERO
var jump_progress = 0.0
var jump_windup_timer = 0.0

var target_velocity = Vector2.ZERO
var is_moving = false

var landing_timer = 0.0
var landing_duration = 0.5
var state_timer = 0.0

enum SlimeState {
	IDLE,
	WALKING,
	JUMP_WINDUP,
	JUMPING,
	LANDING,
	COOLDOWN
}

var current_state = SlimeState.IDLE
var player_in_detection_range = false

var chase_duration = 3.0
var chase_timer = 0.0
var player = null

signal boss_engaged(name: String, max_health: int, current_health: int)
signal boss_disengaged()
signal boss_health_changed(current_health: int, max_health: int)

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
	collision_layer = 4
	collision_mask = 1
	# Ensure all enemies are discoverable via the common group
	add_to_group("enemies")
	# Safety: ensure exported floats are valid even if scene serialized differently
	if typeof(walk_friction) == TYPE_NIL:
		walk_friction = 200.0
	if typeof(walk_acceleration) == TYPE_NIL:
		walk_acceleration = 300.0
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if has_node("WindupBar"):
		windup_bar = get_node("WindupBar")
		if windup_bar is ProgressBar:
			windup_bar.max_value = 100
			windup_bar.value = 0
			windup_bar.visible = false
			windup_bar.modulate = Color.YELLOW
	
	setup_attack_area()
	setup_detection_area()
	call_deferred("find_player")
	
	if animation_player:
		play_animation("idle")

	# Mark big slime as boss
	if enemy_type == "big_slime":
		add_to_group("boss")

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
	
	if attack_area:
		attack_area.monitoring = false
		attack_area.collision_layer = 4
		attack_area.collision_mask = 1
		
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)

func setup_detection_area():
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_detection_area_entered):
			detection_area.body_entered.connect(_on_detection_area_entered)
		if not detection_area.body_exited.is_connected(_on_detection_area_exited):
			detection_area.body_exited.connect(_on_detection_area_exited)

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if is_dead:
		return
	
	if is_taking_damage:
		damage_timer -= delta
		if damage_timer <= 0:
			is_taking_damage = false
			sprite.modulate = Color.WHITE
	
	if attack_timer > 0:
		attack_timer -= delta
	
	state_timer += delta
	
	if knockback_velocity.length() > 5 and not is_jumping:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction)
		move_and_slide()
		return
	
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
	
	if not is_jumping:
		move_and_slide()

func handle_idle_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	if animation_player:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
			animation_player.speed_scale = 1.0
	
	if player_in_detection_range and player:
		change_state(SlimeState.WALKING)
		chase_timer = chase_duration

func handle_walking_state(delta):
	if not player:
		change_state(SlimeState.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_range and attack_timer <= 0:
		start_jump_windup()
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
			play_walking_animation()
		else:
			play_animation("idle")
	else:
		change_state(SlimeState.IDLE)

func handle_jump_windup_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	play_animation("jump_prepare")
	
	jump_windup_timer -= delta
	
	if windup_bar:
		var progress = (jump_windup_duration - jump_windup_timer) / jump_windup_duration
		windup_bar.value = progress * 100
		windup_bar.modulate = Color.YELLOW.lerp(Color.RED, progress)
		
		if not windup_bar.visible:
			windup_bar.visible = true
	
	if jump_windup_timer <= 0:
		execute_jump()

func handle_jumping_state(delta):
	jump_progress += delta / jump_duration
	jump_progress = clamp(jump_progress, 0.0, 1.0)
	
	var horizontal_pos = jump_start_position.lerp(jump_target_position, jump_progress)
	
	var arc_progress = jump_progress * 2.0 - 1.0
	var height_offset = jump_arc_height * (1.0 - arc_progress * arc_progress)
	
	global_position = horizontal_pos + Vector2(0, -height_offset)
	
	play_animation_synced("jump_air", jump_duration, 3.0)
	
	sprite.rotation = sin(jump_progress * PI) * 0.3
	
	if jump_progress >= 1.0:
		land_jump()

func handle_landing_state(delta):
	target_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	is_moving = false
	
	play_animation("jump_land")
	
	landing_timer += delta
	
	if landing_timer >= landing_duration:
		change_state(SlimeState.COOLDOWN)
		attack_timer = jump_cooldown
		landing_timer = 0.0

func handle_cooldown_state(delta):
	target_velocity = Vector2.ZERO
	velocity = velocity.move_toward(target_velocity, walk_friction * delta)
	is_moving = false
	
	play_animation("idle")
	
	if attack_timer <= 0:
		change_state(SlimeState.IDLE)

func change_state(new_state: SlimeState):
	state_timer = 0.0
	
	match current_state:
		SlimeState.JUMP_WINDUP:
			if windup_bar:
				windup_bar.visible = false
		SlimeState.JUMPING:
			is_jumping = false
			sprite.rotation = 0
			sprite.modulate = Color.WHITE
			if animation_player:
				animation_player.speed_scale = 1.0
		SlimeState.LANDING:
			landing_timer = 0.0
	
	current_state = new_state
	
	match new_state:
		SlimeState.LANDING:
			landing_timer = 0.0

func play_walking_animation():
	if not animation_player:
		return
	
	var walk_anim = "jump"
	
	if animation_player.has_animation("walk"):
		walk_anim = "walk"
	elif animation_player.has_animation("move"):
		walk_anim = "move"
	
	var speed_ratio = velocity.length() / speed
	var animation_speed = walk_animation_speed * (0.5 + speed_ratio * 0.5)
	
	if animation_player.current_animation != walk_anim:
		animation_player.play(walk_anim)
	
	animation_player.speed_scale = animation_speed

func start_jump_windup():
	change_state(SlimeState.JUMP_WINDUP)
	jump_windup_timer = jump_windup_duration
	
	if windup_bar:
		windup_bar.visible = true
		windup_bar.value = 0
		windup_bar.modulate = Color.YELLOW
	
	if player:
		var player_velocity = Vector2.ZERO
		if player.has_method("get_velocity"):
			player_velocity = player.get_velocity()
		elif "velocity" in player:
			player_velocity = player.velocity
		
		jump_target_position = player.global_position + (player_velocity * jump_windup_duration * 0.5)
	else:
		jump_target_position = global_position + Vector2(50, 0)

func execute_jump():
	change_state(SlimeState.JUMPING)
	is_jumping = true
	jump_progress = 0.0
	jump_start_position = global_position
	
	if windup_bar:
		windup_bar.visible = false
	
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 0.8)

func land_jump():
	change_state(SlimeState.LANDING)
	is_jumping = false
	jump_progress = 0.0
	
	sprite.rotation = 0
	sprite.modulate = Color.WHITE
	if animation_player:
		animation_player.speed_scale = 1.0
	
	if attack_area:
		attack_area.monitoring = true
		
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func(): 
			if attack_area:
				attack_area.monitoring = false
		)

	# Big slime unique effect: quake and spawn allies on landing
	if enemy_type == "big_slime":
		# Camera shake
		var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
		if cam and cam.has_method("shake_camera"):
			cam.shake_camera(8.0, 0.18)
		# Spawn 3 slimes erupting from the ground
		_spawn_floor_slimes(3)

func play_animation_synced(anim_name: String, movement_duration: float, speed_multiplier: float = 2.0):
	if not animation_player:
		return
	
	var target_anim = anim_name
	
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
		return
	
	if animation_player.current_animation != target_anim:
		var sync_speed = (anim_length / movement_duration) * speed_multiplier
		
		animation_player.play(target_anim)
		animation_player.speed_scale = sync_speed

func play_animation(anim_name: String, speed_multiplier: float = 1.0):
	if not animation_player:
		return
	
	animation_player.speed_scale = speed_multiplier
	
	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
	else:
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
	
	if current_state == SlimeState.JUMP_WINDUP:
		cancel_jump_windup()
	
	if current_state == SlimeState.WALKING:
		target_velocity = Vector2.ZERO
	
	current_health -= amount
	if get_tree() and get_tree().current_scene and Engine.has_singleton("ParticleEffects") == false:
		# no singleton; call static directly
		if ResourceLoader.exists("res://scripts/Particle_Effects_Manager.gd"):
			var root = get_tree().current_scene
			if root and root.has_method("add_child"):
				ParticleEffects.spawn_damage_number(root, global_position, amount)
	
	if health_bar:
		health_bar.value = current_health

	# Notify UI for boss health updates
	if enemy_type == "big_slime":
		boss_health_changed.emit(current_health, max_health)
	
	flash_sprite(Color.RED, damage_flash_duration)
	
	if player and not is_jumping:
		var knockback_dir = (global_position - player.global_position).normalized()
		knockback_velocity = knockback_dir * knockback_force
	
	if current_health <= 0:
		die()

func cancel_jump_windup():
	change_state(SlimeState.IDLE)
	
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
	
	# Register for respawn BEFORE doing death effects
	var respawn_manager = get_tree().get_first_node_in_group("respawn_manager")
	if respawn_manager:
		respawn_manager.register_enemy_death(self)
	
	# Handle drops (including keys)
	DropSystem.handle_enemy_death(enemy_type, global_position, get_tree())
	drop_keys()

	if enemy_type == "big_slime":
		boss_disengaged.emit()
	
	if windup_bar:
		windup_bar.visible = false
	
	collision_shape.disabled = true
	
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		quest_manager.on_enemy_killed("slime_enemy") 
		
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 0.5), 0.5)
	tween.tween_callback(queue_free)
	
	
	
	
func drop_keys():
	"""Drop keys when enemy dies"""
	var key_drop_chance = 0.3  # 30% chance to drop a key
	
	if randf() < key_drop_chance:
		var key_type = "wooden"  # Default key type
		
		# Different enemies drop different keys
		match enemy_type:
			"skeleton":
				key_type = "iron"  # Skeletons drop iron keys
			"slime":
				key_type = "wooden"  # Slimes drop wooden keys
			_:
				key_type = "wooden"  # Default to wooden
		
		# Spawn the key
		var key_id = key_type + "_key"
		var pickup_scene = load("res://scenes/PickupItem.tscn")
		
		if pickup_scene:
			var pickup = pickup_scene.instantiate()
			get_tree().current_scene.add_child(pickup)
			pickup.global_position = global_position + Vector2(randf_range(-20, 20), -20)
			pickup.set_item(key_id, 1)
			print("Enemy dropped ", key_type, " key!")

func _spawn_floor_slimes(count: int):
	var scene_path = "res://scenes/slime_enemy.tscn"
	var slime_scene = load(scene_path)
	if not slime_scene:
		return
	var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if not parent:
		return
	for i in range(count):
		var s = slime_scene.instantiate()
		if not s:
			continue
		parent.add_child(s)
		# Position in a small circle around the big slime
		var angle = (i * TAU) / float(max(1, count))
		var radius = 36 + i * 4
		var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * radius
		s.global_position = spawn_pos + Vector2(0, 12)
		# Little emerge animation (rise and fade in), keep original scale
		if "modulate" in s:
			s.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(s, "global_position", spawn_pos, 0.25)
		tw.tween_property(s, "modulate:a", 1.0, 0.25)
		
#func _spawn_floor_enemies(count: int):
	#var scene_path = "res://scenes/vampire_enemy.tscn"
	#var vampire_scene = load(scene_path)
	#if not vampire_scene:
		#return
	#var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	#if not parent:
		#return
	#for i in range(count):
		#var s = vampire_scene.instantiate()
		#if not s:
			#continue
		#parent.add_child(s)
		#var angle = (i * TAU) / float(max(1, count))
		#var radius = 36 + i * 4
		#var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * radius
		#s.global_position = spawn_pos + Vector2(0, 12)
		#if "modulate" in s:
			#s.modulate.a = 0.0
		#var tw = create_tween()
		#tw.tween_property(s, "global_position", spawn_pos, 0.25)
		#tw.tween_property(s, "modulate:a", 1.0, 0.25)
#func drop_items():
	#"""Handle item dropping when enemy dies"""
	#print("Rolling for item drops...")
#
	#if randf() > drop_chance:
		#print("No items dropped")
		#return
	#
	#var dropped_items: Array[Dictionary] = []
	#var drop_pool: Array[String] = []
	#var rarity_roll = randf()
	#
	#if rarity_roll < rare_drop_chance:
		## Rare drop (10% chance)
		#drop_pool = rare_drops
		#print("Rolling for rare drop!")
	#elif rarity_roll < rare_drop_chance + 0.2:  # 20% chance for uncommon
		## Uncommon drop
		#drop_pool = uncommon_drops
		#print("Rolling for uncommon drop!")
	#else:
		## Common drop
		#drop_pool = common_drops
		#print("Rolling for common drop!")
	#if drop_pool.size() > 0:
		#var random_item = drop_pool[randi() % drop_pool.size()]
		#var quantity = randi_range(min_drop_quantity, max_drop_quantity)
	#
	#var drop_data = {
			#"item_id": random_item,
			#"quantity": quantity,
			#"position": global_position
		#}
		#dropped_items.append(drop_data)
		#
		#print("Dropping: ", random_item, " x", quantity)
		#
		## Spawn the pickup item in the world
		#spawn_pickup_item(drop_data)



func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player_in_detection_range = true
		if not player:
			player = body
		if enemy_type == "big_slime":
			boss_engaged.emit("Lord Slime", max_health, current_health)

func _on_detection_area_exited(body):
	if body.is_in_group("player"):
		player_in_detection_range = false
		if enemy_type == "big_slime":
			boss_disengaged.emit()

func _on_attack_area_body_entered(body):
	if current_state == SlimeState.LANDING:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				var damage_result = body.take_damage(damage, self)
				if damage_result:
					flash_sprite(Color.YELLOW, 0.3)
					apply_player_stun_flash(body)

func apply_player_stun_flash(player_body):
	if not player_body or not player_body.has_method("get_node"):
		return
	
	var player_sprite = null
	if player_body.has_node("Sprite2D"):
		player_sprite = player_body.get_node("Sprite2D")
	elif player_body.has_node("AnimatedSprite2D"):
		player_sprite = player_body.get_node("AnimatedSprite2D")
	
	if not player_sprite:
		return
	
	var stun_duration = 1.0
	if "immunity_duration" in player_body:
		stun_duration = player_body.immunity_duration
	elif "stun_duration" in player_body:
		stun_duration = player_body.stun_duration
	elif "invulnerability_time" in player_body:
		stun_duration = player_body.invulnerability_time
	
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
