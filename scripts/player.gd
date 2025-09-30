extends CharacterBody2D

# Inline echo ghost to avoid external script load issues
class EchoGhost:
	extends Area2D

	@export var lifetime: float = 1.0
	@export var move_speed: float = 900.0
	@export var damage: int = 1
	@export var alpha: float = 0.7
	@export var afterimage_interval: float = 0.04
	@export var afterimage_lifetime: float = 0.18
	@export var damage_on_move: bool = true
	@export var move_hit_radius: float = 12.0
	@export var burst_radius: float = 48.0
	@export var burst_damage: int = 2

	var path: Array[Vector2] = []
	var idx: int = 0
	var target: Vector2 = Vector2.ZERO
	var _afterimage_timer: float = 0.0

	@onready var sprite: Sprite2D = null

	func _ready():
		set_physics_process(true)
		_afterimage_timer = 0.0

	func setup(texture: Texture2D, scale_v: Vector2, start_pos: Vector2, recorded_path: Array[Vector2], hframes: int = 1, vframes: int = 1, frame_idx: int = 0, flip_h: bool = false, flip_v: bool = false, centered: bool = true):
		path = recorded_path.duplicate()
		idx = 0
		global_position = start_pos
		if not sprite:
			sprite = Sprite2D.new()
			sprite.modulate = Color(1, 1, 1, alpha)
			add_child(sprite)
		sprite.texture = texture
		sprite.scale = scale_v
		sprite.hframes = max(1, hframes)
		sprite.vframes = max(1, vframes)
		sprite.frame = max(0, frame_idx)
		sprite.flip_h = flip_h
		sprite.flip_v = flip_v
		sprite.centered = centered
		if path.size() > 0:
			target = path[0]
		else:
			target = start_pos

	func _physics_process(delta):
		if lifetime > 0:
			lifetime -= delta
		elif path.is_empty():
			queue_free()
		if path.is_empty():
			return

		# emit dash-like afterimages while moving along the path
		_afterimage_timer -= delta
		if _afterimage_timer <= 0.0:
			_emit_afterimage()
			_afterimage_timer = afterimage_interval
		var to_target = target - global_position
		var step = move_speed * delta
		if to_target.length() <= step:
			global_position = target
			idx += 1
			if idx >= path.size():
				path.clear()
				return
			target = path[idx]
		else:
			global_position += to_target.normalized() * step

		if damage_on_move:
			_apply_move_damage()

	func _emit_afterimage():
		if not sprite:
			return
		var img := Sprite2D.new()
		img.texture = sprite.texture
		img.hframes = sprite.hframes
		img.vframes = sprite.vframes
		img.frame = sprite.frame
		img.centered = sprite.centered
		img.flip_h = sprite.flip_h
		img.flip_v = sprite.flip_v
		img.scale = sprite.scale
		img.rotation = sprite.rotation
		img.z_index = sprite.z_index
		img.modulate = Color(1, 1, 1, 0.8)
		img.top_level = true
		img.global_position = global_position
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		img.material = mat
		var parent := get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
		if parent:
			parent.add_child(img)
			var t := create_tween()
			t.tween_property(img, "modulate:a", 0.0, afterimage_lifetime)
			t.tween_callback(func(): img.queue_free())

	func _apply_move_damage():
		var space := get_world_2d().direct_space_state
		if not space:
			return
		var circle := CircleShape2D.new()
		circle.radius = move_hit_radius
		var qp := PhysicsShapeQueryParameters2D.new()
		qp.shape = circle
		qp.transform = Transform2D(0.0, global_position)
		qp.collision_mask = 4
		qp.collide_with_bodies = true
		qp.collide_with_areas = true
		var hits = space.intersect_shape(qp)
		for hit in hits:
			var c = hit.get("collider")
			if c and c.has_method("take_damage"):
				c.take_damage(damage)

	func do_burst():
		# quick ring pop for feedback
		var ring := ColorRect.new()
		ring.color = Color(0.4, 0.8, 1.0, 0.6)
		ring.size = Vector2(4, 4)
		ring.position = Vector2(-2, -2)
		ring.z_index = 100
		add_child(ring)
		var r = create_tween()
		r.tween_property(ring, "scale", Vector2(20, 20), 0.2)
		r.tween_property(ring, "modulate:a", 0.0, 0.2)
		r.tween_callback(func(): if is_instance_valid(ring): ring.queue_free())

		var space := get_world_2d().direct_space_state
		if space:
			var circle := CircleShape2D.new()
			circle.radius = burst_radius
			var qp := PhysicsShapeQueryParameters2D.new()
			qp.shape = circle
			qp.transform = Transform2D(0.0, global_position)
			qp.collision_mask = 4
			qp.collide_with_bodies = true
			qp.collide_with_areas = true
			var hits = space.intersect_shape(qp)
			for hit in hits:
				var c = hit.get("collider")
				if c and c.has_method("take_damage"):
					c.take_damage(burst_damage)
		queue_free()

@export var speed = 300
@export var friction = 0.2
@export var acceleration = 0.1
@export var attack_damage = 1
@export var attack_duration = 0.4
@export var attack_cooldown = 0.1

# Dash settings
@export var dash_speed = 700
@export var dash_duration = 0.10
@export var dash_cooldown = 0.8
@export var dash_iframe_duration = 0.1

# Dash energy (meter)
@export var max_dash_energy: int = 100
@export var dash_cost: int = 25
@export var dash_regen_rate: float = 20.0

# Dash afterimage effect
@export var dash_afterimage_interval = 0.03
@export var dash_afterimage_lifetime = 0.2

@export var max_health = 5
@export var damage_immunity_duration = 0.3
@export var knockback_resistance = 0.5

@export var min_animation_speed = 0.5
@export var max_animation_speed = 4.0
@export var speed_threshold = 50

@export var swing_arc_degrees = 120
@export var swing_duration = 0.3
@export var swing_offset_distance = 30
@export var enable_trail_effect = true
@export var trail_fade_duration = 0.2

@export var attack_range = 50
@export var swing_arc_half_angle = 60

@export var pickup_range = 40
@export var auto_pickup_enabled = true

@export_group("Sound Effects")
@export var hit_sound_path: String = "res://audio/hit_sound.wav"
@export var hit_sound_volume: float = 0.0
@export var hit_sound_base_pitch: float = 0.8
@export var hit_sound_pitch_variation: float = 0.1

@export var pickup_sound_path: String = "res://audio/pickup_sound.wav"
@export var pickup_sound_volume: float = 0.0
@export var pickup_sound_base_pitch: float = 1.0
@export var pickup_sound_pitch_variation: float = 0.2

@export var hurt_sound_path: String = "res://audio/hurt_sound.wav"
@export var hurt_sound_volume: float = 0.0
@export var hurt_sound_base_pitch: float = 1.0
@export var hurt_sound_pitch_variation: float = 0.1

@export var background_music_path: String = "res://audio/background_music.ogg"
@export var background_music_volume: float = -10.0
@export var music_autoplay: bool = true

var is_attacking = false
var attack_timer = 0.0
var cooldown_timer = 0.0
var last_direction = Vector2.DOWN

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO
var is_dash_iframe = false
var dash_flash_timer = 0.0
var dash_afterimage_timer = 0.0

var dash_energy: int = 0

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

signal health_changed(new_health: int)
signal player_died
signal enemy_killed
signal dash_energy_changed(new_energy: int)
signal echoes_changed(count: int)
signal echo_spawned(duration: float)

@export var echo_record_duration: float = 1.0
@export var echo_max_charges: int = 3
@export var echo_move_speed: float = 900.0
@export var echo_burst_damage: int = 2
@export var echo_burst_radius: float = 48.0
@export var echo_recall_sound_path: String = ""
@export var echo_recall_sound_volume: float = 0.0

var echo_path: Array[Vector2] = []
var echo_timer: float = 0.0
var active_echoes: Array[Node] = []
var echo_spawned_this_dash: bool = false
var echo_charges: int = 3
var last_dash_path: Array[Vector2] = []
var last_dash_start: Vector2 = Vector2.ZERO

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var attack_area = $AttackArea if has_node("AttackArea") else null
@onready var attack_collision = $AttackArea/CollisionShape2D if has_node("AttackArea/CollisionShape2D") else null
@onready var attack_sprite = $AttackSprite if has_node("AttackSprite") else null
@onready var health_bar = $HealthBar if has_node("HealthBar") else null

@onready var dash_particles: CPUParticles2D = null

@onready var hit_audio_player: AudioStreamPlayer2D = null
@onready var pickup_audio_player: AudioStreamPlayer2D = null
@onready var hurt_audio_player: AudioStreamPlayer2D = null
@onready var music_player: AudioStreamPlayer = null
@onready var echo_audio_player: AudioStreamPlayer2D = null

@onready var pickup_area = $PickupArea if has_node("PickupArea") else null
@onready var pickup_collision = $PickupArea/CollisionShape2D if has_node("PickupArea/CollisionShape2D") else null

func _ready():
	add_to_group("player")
	current_health = max_health
	update_health_display()
	setup_pickup_system()
	setup_sound_effects()
	setup_background_music()
	# Dash particles disabled
	
	# Initialize dash energy
	dash_energy = max_dash_energy
	dash_energy_changed.emit(dash_energy)
	
	# Echo recall action (Q)
	if not InputMap.has_action("recall_echo"):
		InputMap.add_action("recall_echo")
		var evq := InputEventKey.new()
		evq.physical_keycode = KEY_Q
		InputMap.action_add_event("recall_echo", evq)
	# initialize echo charges
	echo_charges = echo_max_charges
	
	# Ensure a "dash" action exists and is bound to Shift
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("dash", ev)
	
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

func setup_sound_effects():
	hit_audio_player = AudioStreamPlayer2D.new()
	hit_audio_player.name = "HitAudioPlayer"
	add_child(hit_audio_player)
	
	if hit_sound_path != "" and ResourceLoader.exists(hit_sound_path):
		var hit_sound = load(hit_sound_path)
		if hit_sound is AudioStream:
			hit_audio_player.stream = hit_sound
			hit_audio_player.volume_db = hit_sound_volume
			hit_audio_player.bus = "Master"
			hit_audio_player.max_distance = 2000
			hit_audio_player.attenuation = 0.0

	pickup_audio_player = AudioStreamPlayer2D.new()
	pickup_audio_player.name = "PickupAudioPlayer"
	add_child(pickup_audio_player)
	
	if pickup_sound_path != "" and ResourceLoader.exists(pickup_sound_path):
		var pickup_sound = load(pickup_sound_path)
		if pickup_sound is AudioStream:
			pickup_audio_player.stream = pickup_sound
			pickup_audio_player.volume_db = pickup_sound_volume
			pickup_audio_player.bus = "Master"
			pickup_audio_player.max_distance = 2000
			pickup_audio_player.attenuation = 0.0

	hurt_audio_player = AudioStreamPlayer2D.new()
	hurt_audio_player.name = "HurtAudioPlayer"
	add_child(hurt_audio_player)
	
	if hurt_sound_path != "" and ResourceLoader.exists(hurt_sound_path):
		var hurt_sound = load(hurt_sound_path)
		if hurt_sound is AudioStream:
			hurt_audio_player.stream = hurt_sound
			hurt_audio_player.volume_db = hurt_sound_volume
			hurt_audio_player.bus = "Master"
			hurt_audio_player.max_distance = 2000
			hurt_audio_player.attenuation = 0.0

	echo_audio_player = AudioStreamPlayer2D.new()
	echo_audio_player.name = "EchoAudioPlayer"
	add_child(echo_audio_player)
	if echo_recall_sound_path != "" and ResourceLoader.exists(echo_recall_sound_path):
		var er = load(echo_recall_sound_path)
		if er is AudioStream:
			echo_audio_player.stream = er
			echo_audio_player.volume_db = echo_recall_sound_volume
			echo_audio_player.bus = "Master"

func play_hit_sound():
	if not hit_audio_player or not hit_audio_player.stream:
		return
	
	if hit_audio_player.playing:
		hit_audio_player.stop()
	
	var final_pitch = hit_sound_base_pitch
	if hit_sound_pitch_variation > 0.0:
		var pitch_offset = randf_range(-hit_sound_pitch_variation, hit_sound_pitch_variation)
		final_pitch += pitch_offset
	
	hit_audio_player.pitch_scale = clamp(final_pitch, 0.1, 3.0)
	hit_audio_player.play()

func play_pickup_sound():
	if not pickup_audio_player or not pickup_audio_player.stream:
		return
	
	if pickup_audio_player.playing:
		pickup_audio_player.stop()
	
	var final_pitch = pickup_sound_base_pitch
	if pickup_sound_pitch_variation > 0.0:
		var pitch_offset = randf_range(-pickup_sound_pitch_variation, pickup_sound_pitch_variation)
		final_pitch += pitch_offset
	
	pickup_audio_player.pitch_scale = clamp(final_pitch, 0.1, 3.0)
	pickup_audio_player.play()

func play_hurt_sound():
	if not hurt_audio_player or not hurt_audio_player.stream:
		return
	
	if hurt_audio_player.playing:
		hurt_audio_player.stop()
	
	var final_pitch = hurt_sound_base_pitch
	if hurt_sound_pitch_variation > 0.0:
		var pitch_offset = randf_range(-hurt_sound_pitch_variation, hurt_sound_pitch_variation)
		final_pitch += pitch_offset
	
	hurt_audio_player.pitch_scale = clamp(final_pitch, 0.1, 3.0)
	hurt_audio_player.play()

func setup_background_music():
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	
	if background_music_path != "" and ResourceLoader.exists(background_music_path):
		var music = load(background_music_path)
		if music is AudioStream:
			music_player.stream = music
			music_player.volume_db = background_music_volume
			music_player.bus = "Master"
			music_player.autoplay = music_autoplay
			
			if music_autoplay:
				music_player.play()

func play_background_music():
	if music_player and music_player.stream and not music_player.playing:
		music_player.play()

func stop_background_music():
	if music_player and music_player.playing:
		music_player.stop()

func set_music_volume(volume_db: float):
	if music_player:
		music_player.volume_db = volume_db

func setup_pickup_system():
	if not pickup_area:
		pickup_area = Area2D.new()
		pickup_area.name = "PickupArea"
		pickup_area.collision_layer = 0
		pickup_area.collision_mask = 8
		add_child(pickup_area)
		
		pickup_collision = CollisionShape2D.new()
		pickup_collision.name = "CollisionShape2D"
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = pickup_range
		pickup_collision.shape = circle_shape
		pickup_area.add_child(pickup_collision)
	
	if pickup_area:
		if not pickup_area.area_entered.is_connected(_on_pickup_area_entered):
			pickup_area.area_entered.connect(_on_pickup_area_entered)
		if not pickup_area.body_entered.is_connected(_on_pickup_body_entered):
			pickup_area.body_entered.connect(_on_pickup_body_entered)

func _on_pickup_area_entered(area: Area2D):
	if area.has_method("pickup_item"):
		var item_data = area.pickup_item()
		if not item_data.is_empty():
			add_item_to_inventory(item_data)

func _on_pickup_body_entered(body: Node2D):
	if body.has_method("pickup_item"):
		var item_data = body.pickup_item()
		if not item_data.is_empty():
			add_item_to_inventory(item_data)

func add_item_to_inventory(item_data: Dictionary):
	var item_manager = get_node("/root/ItemManager") if has_node("/root/ItemManager") else null
	
	if item_manager:
		var success = item_manager.add_item_to_inventory(item_data.get("id", ""), item_data.get("quantity", 1))
		if success:
			play_pickup_sound()
			show_pickup_notification(item_data)
			# Cartoony popup for item pickup
			var item_name: String = str(item_data.get("name", item_data.get("id", "Item")))
			var qty: int = int(item_data.get("quantity", 1))
			var qty_prefix: String = ""
			if qty > 1:
				qty_prefix = str(qty) + " "
			var txt: String = "+" + qty_prefix + item_name
			_spawn_potion_popup(txt, Color(1.0, 0.85, 0.2))
	else:
		var ui = get_node("../UI") if has_node("../UI") else null
		if ui and ui.has_method("add_item_to_inventory"):
			var success = ui.add_item_to_inventory(item_data.get("id", ""), item_data.get("quantity", 1))
			if success:
				play_pickup_sound()
				show_pickup_notification(item_data)
				# Cartoony popup for item pickup
				var item_name2: String = str(item_data.get("name", item_data.get("id", "Item")))
				var qty2: int = int(item_data.get("quantity", 1))
				var qty2_prefix: String = ""
				if qty2 > 1:
					qty2_prefix = str(qty2) + " "
				var txt2: String = "+" + qty2_prefix + item_name2
				_spawn_potion_popup(txt2, Color(1.0, 0.85, 0.2))

func show_pickup_notification(item_data: Dictionary):
	var ui = get_node("../UI") if has_node("../UI") else null
	if ui and ui.has_method("show_notification"):
		var item_name = item_data.get("name", item_data.get("id", "Unknown Item"))
		var quantity = item_data.get("quantity", 1)
		var message = "Picked up: " + item_name
		if quantity > 1:
			message += " x" + str(quantity)
		ui.show_notification(message, 2.0)

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

func interact_with_chests():
	var chests = get_tree().get_nodes_in_group("chests")
	for chest in chests:
		if chest.global_position.distance_to(global_position) < 50:
			chest.interact()
			break


func _physics_process(delta):
	# Handle dash white flash (separate from damage flash)
	if dash_flash_timer > 0.0:
		dash_flash_timer -= delta
		if dash_flash_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE

	# Handle damage flash only when not in dash i-frames
	if damage_immunity_timer > 0:
		damage_immunity_timer -= delta
		if not is_dash_iframe:
			damage_flash_timer -= delta
			if damage_flash_timer <= 0:
				damage_flash_timer = damage_flash_duration
				if sprite:
					sprite.modulate = Color.WHITE if sprite.modulate == Color.RED else Color.RED
	else:
		if sprite and sprite.modulate != Color.WHITE and dash_flash_timer <= 0.0:
			sprite.modulate = Color.WHITE
		is_dash_iframe = false
	
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()

	# Dash timers
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			# cache path for later recall (Q)
			last_dash_path = echo_path.duplicate()
			echo_path.clear()
		else:
			# spawn afterimages while dashing
			dash_afterimage_timer -= delta
			if dash_afterimage_timer <= 0.0:
				emit_dash_afterimage()
				dash_afterimage_timer = dash_afterimage_interval
	
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# record echo path while dashing
	if is_dashing:
		echo_timer += delta
		echo_path.append(global_position)
		if echo_timer >= echo_record_duration:
			is_dashing = false
	
	if Input.is_action_just_pressed('Attack') and not is_attacking and cooldown_timer <= 0:
		var mouse_pos = get_global_mouse_position()
		mouse_attack_direction = (mouse_pos - global_position).normalized()
		start_attack()
	
	# Handle chest interaction with E key
	if Input.is_action_just_pressed('interact'):
		interact_with_chests()
	# Echo recall
	if Input.is_action_just_pressed('recall_echo'):
		recall_echoes()
	
	var direction = get_input()
	is_moving = direction.length() > 0
	
	if direction.length() > 0 and not is_attacking:
		last_direction = direction.normalized()

	# Start dash if Shift pressed and we have energy
	if Input.is_action_just_pressed('dash') and not is_dashing and dash_cooldown_timer <= 0.0 and not is_attacking and dash_energy >= dash_cost:
		var dash_dir = direction
		if dash_dir.length() == 0:
			# If no input, dash toward last faced direction
			dash_dir = last_direction
		start_dash(dash_dir.normalized())
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		player_knockback_velocity = Vector2.ZERO
	elif player_knockback_velocity.length() > knockback_threshold:
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

	# Regenerate dash energy when not dashing
	if not is_dashing and dash_energy < max_dash_energy:
		var before = dash_energy
		dash_energy = min(max_dash_energy, int(round(dash_energy + dash_regen_rate * delta)))
		if dash_energy != before:
			dash_energy_changed.emit(dash_energy)

func start_dash(dir: Vector2):
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_direction = dir
	echo_path.clear()
	echo_timer = 0.0
	echo_spawned_this_dash = false
	last_dash_start = global_position

	# Spend dash energy
	var before = dash_energy
	dash_energy = max(0, dash_energy - dash_cost)
	if dash_energy != before:
		dash_energy_changed.emit(dash_energy)
	# brief i-frames during dash start
	damage_immunity_timer = max(damage_immunity_timer, dash_iframe_duration)
	is_dash_iframe = true
	flash_white(0.08)
	# Dash particles disabled
	dash_afterimage_timer = 0.0

	# Camera feedback: shake and vignette pulse
	var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
	if cam:
		if cam.has_method("shake_camera"):
			cam.shake_camera(4.0, 0.10)
		if cam.has_method("pulse_vignette"):
			cam.pulse_vignette(0.22, 0.16, 0.10)

	# spawn echo on dash start if we have room and later on recall

func setup_dash_particles():
	if dash_particles:
		return
	
	dash_particles = CPUParticles2D.new()
	dash_particles.name = "DashParticles"
	add_child(dash_particles)
	
	# Basic white burst behind the player
	dash_particles.emitting = false
	dash_particles.one_shot = true
	dash_particles.amount = 24
	dash_particles.lifetime = 0.20
	dash_particles.preprocess = 0.0
	dash_particles.explosiveness = 0.9
	dash_particles.gravity = Vector2.ZERO
	dash_particles.initial_velocity_min = 120
	dash_particles.initial_velocity_max = 220
	dash_particles.spread = 60
	dash_particles.scale_amount_min = 0.5
	dash_particles.scale_amount_max = 1.0
	dash_particles.color = Color(1, 1, 1, 0.9)
	dash_particles.z_index = -1
	# Ensure particles stay in world space so they don't move with the player after emission
	dash_particles.local_coords = false

	# Generate a small white circle texture so particles are visible
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(3.5, 3.5)
	for y in range(8):
		for x in range(8):
			var d = Vector2(x, y).distance_to(center)
			if d <= 3.0:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	dash_particles.texture = tex

func emit_dash_particles():
	if not dash_particles:
		return
	
	dash_particles.global_position = global_position
	dash_particles.emitting = false
	dash_particles.restart()
	dash_particles.emitting = true

func emit_dash_afterimage():
	if not sprite:
		return
	
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.centered = sprite.centered
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.scale = sprite.scale
	ghost.rotation = sprite.rotation
	ghost.z_index = sprite.z_index
	ghost.modulate = Color(1, 1, 1, 0.8)
	ghost.top_level = true
	ghost.global_position = global_position

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ghost.material = mat

	var parent := get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if parent:
		parent.add_child(ghost)
		var t := create_tween()
		t.tween_property(ghost, "modulate:a", 0.0, dash_afterimage_lifetime)
		t.tween_callback(func(): ghost.queue_free())

func flash_white(duration: float = 0.08):
	if not sprite:
		return
	
	var original_material: Material = sprite.material
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat
	sprite.modulate = Color(1, 1, 1, 1)
	dash_flash_timer = duration
	
	var t = create_tween()
	t.tween_interval(duration)
	t.tween_callback(func():
		sprite.material = original_material
		if dash_flash_timer <= 0.0:
			sprite.modulate = Color.WHITE
	)

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
	
	play_hurt_sound()
	
	current_health -= amount
	damage_immunity_timer = damage_immunity_duration
	damage_flash_timer = damage_flash_duration
	
	health_changed.emit(current_health)
	
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
	if health_bar and is_instance_valid(health_bar):
		var mh = 0
		if typeof(max_health) != TYPE_NIL:
			mh = int(max_health)
		health_bar.max_value = mh
		var cv = 0
		if typeof(current_health) != TYPE_NIL:
			cv = int(current_health)
		health_bar.value = clamp(cv, 0, mh)

func die():
	print("Player died!")
	
	is_attacking = false
	is_swing_animating = false
	velocity = Vector2.ZERO
	player_knockback_velocity = Vector2.ZERO
	
	if animation_player:
		animation_player.stop()
	
	if attack_sprite:
		attack_sprite.visible = false
	
	if attack_area:
		attack_area.monitoring = false
	
	player_died.emit()

func heal(amount: int):
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	
	if current_health != old_health:
		health_changed.emit(current_health)
		update_health_display()
		# Cartoony popup for health gain
		var gained = current_health - old_health
		if gained > 0:
			_spawn_potion_popup("HP +" + str(gained), Color(0.2, 0.9, 0.2))

func restore_dash(amount: int):
	var before = dash_energy
	dash_energy = min(max_dash_energy, dash_energy + amount)
	if dash_energy != before:
		dash_energy_changed.emit(dash_energy)
	# also refill echo charges when drinking dash potion
	echo_charges = echo_max_charges
	echoes_changed.emit(active_echoes.size())

	# Camera vignette pulse feedback on potion use
	var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
	if cam and cam.has_method("pulse_vignette"):
		cam.pulse_vignette(0.28, 0.22, 0.14)

	# Cartoony popup next to player
	_spawn_potion_popup("Dash +", Color(0.2, 0.8, 1.0))

func _spawn_potion_popup(text: String, color: Color = Color.WHITE):
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.modulate.a = 0.0
	label.z_index = 200
	var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if not parent:
		return
	parent.add_child(label)
	label.top_level = true
	label.global_position = global_position + Vector2(0, -24)
	var t = create_tween()
	t.set_parallel(true)
	# Pop scale effect
	t.tween_property(label, "scale", Vector2(1.3, 1.3), 0.08)
	# Fade in
	t.tween_property(label, "modulate:a", 1.0, 0.08)
	var t2 = create_tween()
	# Rise and fade out
	t2.tween_property(label, "global_position", label.global_position + Vector2(0, -36), 0.5)
	t2.tween_property(label, "modulate:a", 0.0, 0.5)
	t2.tween_callback(func(): if is_instance_valid(label): label.queue_free())

func get_dash_energy() -> int:
	return dash_energy

func get_max_dash_energy() -> int:
	return max_dash_energy

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

	# Camera feedback: light shake on attack
	var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
	if cam and cam.has_method("shake_camera"):
		cam.shake_camera(4.0, 0.10)

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
		body.take_damage(attack_damage)
		play_hit_sound()
		enemy_killed.emit()
	elif body.has_method("on_sword_hit"):
		body.on_sword_hit()
		play_hit_sound()
	else:
		play_hit_sound()

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

func get_health() -> int:
	return current_health

func can_take_damage() -> bool:
	return damage_immunity_timer <= 0

func get_knockback_resistance() -> float:
	return knockback_resistance

func set_pickup_range(new_range: float):
	pickup_range = new_range
	if pickup_collision and pickup_collision.shape is CircleShape2D:
		pickup_collision.shape.radius = pickup_range

func get_pickup_range() -> float:
	return pickup_range

func toggle_auto_pickup():
	auto_pickup_enabled = !auto_pickup_enabled

func on_enemy_killed():
	enemy_killed.emit()

func get_spawn_position() -> Vector2:
	return Vector2(0, 0)

func spawn_echo_clone():
	var echo: EchoGhost = EchoGhost.new()
	var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if not parent:
		return
	parent.add_child(echo)
	var tex: Texture2D = sprite.texture if sprite else null
	var scale_v: Vector2 = sprite.scale if sprite else Vector2.ONE
	var hfr: int = sprite.hframes if sprite else 1
	var vfr: int = sprite.vframes if sprite else 1
	var frm: int = sprite.frame if sprite else 0
	var fh: bool = sprite.flip_h if sprite else false
	var fv: bool = sprite.flip_v if sprite else false
	var ctr: bool = sprite.centered if sprite else true
	var start_pos = echo_path[0] if echo_path.size() > 0 else global_position
	echo.setup(tex, scale_v, start_pos, echo_path, hfr, vfr, frm, fh, fv, ctr)
	echo.move_speed = echo_move_speed
	echo.burst_damage = echo_burst_damage
	echo.burst_radius = echo_burst_radius
	echo.damage_on_move = true
	active_echoes.append(echo)
	while active_echoes.size() > echo_max_charges:
		var old = active_echoes.pop_front()
		if is_instance_valid(old):
			old.queue_free()
		echoes_changed.emit(active_echoes.size())
	
	echoes_changed.emit(active_echoes.size())
	echo_spawned.emit(echo_record_duration)

func recall_echoes():
	# Spawn a ghost that traces the last dash path from its start to current position
	if echo_charges > 0 and last_dash_path.size() > 1:
		var ghost := EchoGhost.new()
		var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
		if parent:
			parent.add_child(ghost)
			var tex: Texture2D = sprite.texture if sprite else null
			var scale_v: Vector2 = sprite.scale if sprite else Vector2.ONE
			var hfr: int = sprite.hframes if sprite else 1
			var vfr: int = sprite.vframes if sprite else 1
			var frm: int = sprite.frame if sprite else 0
			var fh: bool = sprite.flip_h if sprite else false
			var fv: bool = sprite.flip_v if sprite else false
			var ctr: bool = sprite.centered if sprite else true
			ghost.move_speed = echo_move_speed
			ghost.damage = attack_damage
			ghost.burst_damage = echo_burst_damage
			ghost.burst_radius = echo_burst_radius
			ghost.damage_on_move = true
			var path_for_ghost: Array[Vector2] = last_dash_path.duplicate()
			path_for_ghost.append(global_position)
			ghost.setup(tex, scale_v, last_dash_start, path_for_ghost, hfr, vfr, frm, fh, fv, ctr)
			echo_charges -= 1
			echoes_changed.emit(active_echoes.size())
	# Clear previously queued passive echoes
	for e in active_echoes:
		if is_instance_valid(e) and e.has_method("queue_free"):
			e.queue_free()
	active_echoes.clear()
	echoes_changed.emit(0)
	if echo_audio_player and echo_audio_player.stream:
		if echo_audio_player.playing:
			echo_audio_player.stop()
		echo_audio_player.play()

func get_echo_count() -> int:
	return active_echoes.size()
