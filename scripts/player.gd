extends CharacterBody2D

signal player_ready

class EchoGhost:
	extends Area2D
	@export var lifetime: float = 1.0
	@export var move_speed: float = 900.0
	@export var echo_damage: int = 1
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
	@onready var shape: CollisionShape2D = null

	func _ready():
		set_physics_process(true)
		_afterimage_timer = 0.0
		monitoring = true
		collision_layer = 0
		collision_mask = 4
		shape = CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = move_hit_radius
		shape.shape = circ
		add_child(shape)
		if path.is_empty():
			queue_free()
			return
		target = path[0]
		body_entered.connect(_on_body_entered)

	func _on_body_entered(body: Node):
		if body and body.has_method("take_damage"):
			body.take_damage(echo_damage)

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
		target = path[0] if path.size() > 0 else start_pos

	func _physics_process(delta):
		if path.is_empty():
			queue_free()
			return
		if lifetime > 0:
			lifetime -= delta
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
				queue_free()
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
			var timer := get_tree().create_timer(afterimage_lifetime + 0.15)
			timer.timeout.connect(func(): if is_instance_valid(img): img.queue_free())

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
				c.take_damage(echo_damage)

	func do_burst():
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
		var space2 := get_world_2d().direct_space_state
		if space2:
			var circle2 := CircleShape2D.new()
			circle2.radius = burst_radius
			var qp2 := PhysicsShapeQueryParameters2D.new()
			qp2.shape = circle2
			qp2.transform = Transform2D(0.0, global_position)
			qp2.collision_mask = 4
			qp2.collide_with_bodies = true
			qp2.collide_with_areas = true
			var hits2 = space2.intersect_shape(qp2)
			for hit2 in hits2:
				var c2 = hit2.get("collider")
				if c2 and c2.has_method("take_damage"):
					c2.take_damage(burst_damage)
		queue_free()

	func flash_white(duration: float = 0.08):
		if not sprite:
			return
		var original_mod := sprite.modulate
		sprite.modulate = Color(1, 1, 1, 1)
		var t := create_tween()
		t.tween_interval(duration)
		t.tween_callback(func():
			if is_instance_valid(self) and sprite:
				sprite.modulate = original_mod)

# ===== EXPORT VARIABLES =====
@export var speed: float = 300.0
@export var friction: float = 0.2
@export var acceleration: float = 0.1
@export var attack_damage: int = 1
@export var attack_duration: float = 0.4
@export var attack_cooldown: float = 0.1
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.10
@export var dash_cooldown: float = 0.8
@export var dash_iframe_duration: float = 0.1
@export var max_dash_energy: int = 100
@export var dash_cost: int = 25
@export var dash_regen_rate: float = 20.0
@export var dash_afterimage_interval: float = 0.03
@export var dash_afterimage_lifetime: float = 0.2
@export var max_health: int = 5
@export var damage_immunity_duration: float = 0.3
@export var knockback_resistance: float = 0.5
@export var min_animation_speed: float = 0.5
@export var max_animation_speed: float = 4.0
@export var speed_threshold: float = 50.0
@export var swing_arc_degrees: float = 120.0
@export var swing_duration: float = 0.3
@export var swing_offset_distance: float = 30.0
@export var enable_trail_effect: bool = true
@export var trail_fade_duration: float = 0.2
@export var attack_range: float = 50.0
@export var swing_arc_half_angle: float = 60.0
@export var pickup_range: float = 40.0
@export var auto_pickup_enabled: bool = true
@export_group("Sound Effects")
@export var hit_sound_path: String = "res://audio/hit_sound.wav"
@export var hit_sound_volume: float = -10.0
@export var hit_sound_base_pitch: float = 0.8
@export var hit_sound_pitch_variation: float = 0.1
@export var pickup_sound_path: String = "res://audio/pickup_sound.wav"
@export var pickup_sound_volume: float = -5.0
@export var dash_sound_base_pitch: float = 1.0
@export var dash_sound_pitch_variation: float = 0.05
@export var pickup_sound_base_pitch: float = 1.0
@export var pickup_sound_pitch_variation: float = 0.2
@export var hurt_sound_path: String = "res://audio/hurt_sound.wav"
@export var hurt_sound_volume: float = 0.0
@export var hurt_sound_base_pitch: float = 1.0
@export var hurt_sound_pitch_variation: float = 0.1
@export var footstep_sound_path: String = "res://audio/reverb-footstep-cave-basement-abandoned-place-315027.mp3"
@export var footstep_volume: float = -10.0
@export var footstep_pitch_base: float = 1.0
@export var footstep_pitch_variation: float = 0.1
@export var footstep_interval: float = 0.4
@export var trail_color: Color = Color.WHITE
@export var trail_width: float = 3.0
@export var trail_max_alpha: float = 0.8
@export var echo_record_duration: float = 1.0
@export var echo_max_charges: int = 3
@export var echo_move_speed: float = 900.0
@export var echo_burst_damage: int = 2
@export var echo_burst_radius: float = 48.0
@export var echo_recall_sound_path: String = ""
@export var echo_recall_sound_volume: float = 0.0

# ===== CONSTANTS =====
const FOOTSTEP_SOUND = preload("res://audio/reverb-footstep-cave-basement-abandoned-place-315027.mp3")
const HIT_SOUND = preload("res://audio/hit_sound.mp3")
const PICKUP_SOUND = preload("res://audio/pickup_sound.mp3")
const HURT_SOUND = preload("res://audio/hurt_sound.mp3")
const SWORD_SLICE_SOUND = preload("res://audio/violent-sword-slice-393848.mp3")
const DASH_SOUND = preload("res://audio/dash-sfx.mp3")

# ===== REGULAR VARIABLES =====
var HitEffectScene := preload("res://scenes/HitEffect.tscn")
var is_attacking: bool = false
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.DOWN
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var is_dash_iframe: bool = false
var dash_flash_timer: float = 0.0
var dash_afterimage_timer: float = 0.0
var dash_energy: int = 0
var mouse_attack_direction: Vector2 = Vector2.RIGHT
var controller_deadzone: float = 0.3
var facing_direction: int = 1
var right_stick_active: bool = false
var swing_start_angle: float = 0.0
var swing_end_angle: float = 0.0
var swing_current_progress: float = 0.0
var is_swing_animating: bool = false
var trail_positions: Array = []
var max_trail_length: int = 8
var magic_ring_sprite: Sprite2D = null
var ring_follow_distance: float = 30.0
var ring_follow_speed: float = 8.0
var current_health: int = 0
var is_taking_damage: bool = false
var damage_immunity_timer: float = 0.0
var damage_flash_timer: float = 0.0
var damage_flash_duration: float = 0.1
var player_knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 0.8
var knockback_threshold: float = 15.0
var current_animation: String = ""
var is_moving: bool = false
var footstep_audio_player: AudioStreamPlayer2D = null
var footstep_timer: float = 0.0
var hit_audio_player: AudioStreamPlayer2D = null
var sword_slice_player: AudioStreamPlayer2D = null
var dash_audio_player: AudioStreamPlayer2D = null
var pickup_audio_player: AudioStreamPlayer2D = null
var hurt_audio_player: AudioStreamPlayer2D = null
var echo_audio_player: AudioStreamPlayer2D = null
var echo_path: Array[Vector2] = []
var echo_timer: float = 0.0
var active_echoes: Array[Node] = []
var echo_spawned_this_dash: bool = false
var echo_charges: int = 3
var last_dash_path: Array[Vector2] = []
var last_dash_start: Vector2 = Vector2.ZERO

signal health_changed(new_health: int)
signal player_died
signal enemy_killed
signal dash_energy_changed(new_energy: int)
signal echoes_changed(count: int)
signal echo_spawned(duration: float)

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var attack_area = $AttackArea if has_node("AttackArea") else null
@onready var attack_collision = $AttackArea/CollisionShape2D if has_node("AttackArea/CollisionShape2D") else null
@onready var attack_sprite = $AttackSprite if has_node("AttackSprite") else null
@onready var health_bar = $HealthBar if has_node("HealthBar") else null
@onready var dash_particles: CPUParticles2D = null
@onready var pickup_area = $PickupArea if has_node("PickupArea") else null
@onready var pickup_collision = $PickupArea/CollisionShape2D if has_node("PickupArea/CollisionShape2D") else null

func _ready():
	var quest_manager = get_node("/root/QuestManager")
	quest_manager.start_quest("tutorial_quest")
	add_to_group("player")
	current_health = max_health
	await get_tree().process_frame 
	await get_tree().process_frame
	health_changed.emit(current_health)
	update_health_display()
	setup_pickup_system()
	setup_sound_effects()
	dash_energy = max_dash_energy
	if Input.get_connected_joypads().size() > 0:
		print("Controller detected for attack direction")
	dash_energy_changed.emit(dash_energy)
	if not InputMap.has_action("recall_echo"):
		InputMap.add_action("recall_echo")
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
		var shift_evt := InputEventKey.new()
		shift_evt.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("dash", shift_evt)
		var shoulder_evt := InputEventJoypadButton.new()
		shoulder_evt.button_index = JOY_BUTTON_LEFT_SHOULDER
		InputMap.action_add_event("dash", shoulder_evt)
		var evq := InputEventKey.new()
		evq.physical_keycode = KEY_Q
		InputMap.action_add_event("recall_echo", evq)
	echo_charges = echo_max_charges
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
	var item_manager = get_node_or_null("/root/ItemManager")
	if item_manager:
		if not item_manager.item_picked_up.is_connected(_on_item_picked_up):
			item_manager.item_picked_up.connect(_on_item_picked_up)
	update_magic_ring_display()
	call_deferred("_refresh_weapon_visual")
	call_deferred("_delayed_weapon_refresh")
	
	await get_tree().create_timer(1.0).timeout
	
	var vc = get_node("/root/VirtualCursor")
	if vc:
		print("Testing virtual cursor...")
		print("VirtualCursor found: ", vc)
		vc.force_activate()
		
		if vc.sprite:
			print("Sprite exists: ", vc.sprite)
			print("Sprite texture: ", vc.sprite.texture)
			print("Sprite visible: ", vc.sprite.visible)
			print("Sprite position: ", vc.sprite.position)
		
		var custom_texture = load("res://icon.svg")
		if custom_texture:
			vc.set_cursor_texture(custom_texture)
			print("Custom texture set!")
	else:
		print("ERROR: VirtualCursor not found in autoload!")
	
	player_ready.emit()
func _on_body_entered(body: Node):
	var fx = HitEffectScene.instantiate()
	fx.global_position = body.global_position
	get_tree().current_scene.add_child(fx)
	fx.rotation = get_mouse_attack_direction().angle()
	if fx is GPUParticles2D or fx is CPUParticles2D:
		fx.emitting = true	
	if body and body.has_method("take_damage"):
		body.take_damage(attack_damage)



func setup_sound_effects():
	# Footstep Audio Player
	footstep_audio_player = AudioStreamPlayer2D.new()
	footstep_audio_player.name = "FootstepAudioPlayer"
	add_child(footstep_audio_player)
	if footstep_sound_path != "" and ResourceLoader.exists(footstep_sound_path):
		var footstep_sound = load(footstep_sound_path)
		if footstep_sound is AudioStream:
			footstep_audio_player.stream = footstep_sound
			footstep_audio_player.volume_db = footstep_volume
			footstep_audio_player.bus = "Master"
			footstep_audio_player.max_distance = 500
			footstep_audio_player.attenuation = 0.0
			
	
	
	# Hit Audio Player
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

	# Sword Slice Player
	sword_slice_player = AudioStreamPlayer2D.new()
	sword_slice_player.name = "SwordSlicePlayer"
	add_child(sword_slice_player)
	var violent_slice_path := "res://audio/violent-sword-slice-393848.mp3"
	if ResourceLoader.exists(violent_slice_path):
		var vs = load(violent_slice_path)
		if vs is AudioStream:
			sword_slice_player.stream = vs
			sword_slice_player.bus = "Master"
			sword_slice_player.volume_db = -6.0
			sword_slice_player.max_distance = 2000
			sword_slice_player.attenuation = 0.0

	# Pickup Audio Player
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

	# Hurt Audio Player
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

	# Echo Audio Player
	echo_audio_player = AudioStreamPlayer2D.new()
	echo_audio_player.name = "EchoAudioPlayer"
	add_child(echo_audio_player)
	if echo_recall_sound_path != "" and ResourceLoader.exists(echo_recall_sound_path):
		var er = load(echo_recall_sound_path)
		if er is AudioStream:
			echo_audio_player.stream = er
			echo_audio_player.volume_db = echo_recall_sound_volume
			echo_audio_player.bus = "Master"

	# Dash Audio Player
	dash_audio_player = AudioStreamPlayer2D.new()
	dash_audio_player.name = "DashAudioPlayer"
	add_child(dash_audio_player)
	var dash_sfx_path := "res://audio/dash-sfx.mp3"
	if ResourceLoader.exists(dash_sfx_path):
		var ds = load(dash_sfx_path)
		if ds is AudioStream:
			dash_audio_player.stream = ds
			dash_audio_player.bus = "Master"
			dash_audio_player.volume_db = 0.0
	var sound_configs = [
		["FootstepAudioPlayer", footstep_sound_path, footstep_volume, footstep_audio_player],
		["HitAudioPlayer", hit_sound_path, hit_sound_volume, hit_audio_player],
		["SwordSlicePlayer", "res://audio/violent-sword-slice-393848.mp3", -6.0, sword_slice_player],
		["PickupAudioPlayer", pickup_sound_path, pickup_sound_volume, pickup_audio_player],
		["HurtAudioPlayer", hurt_sound_path, hurt_sound_volume, hurt_audio_player],
		["EchoAudioPlayer", echo_recall_sound_path, echo_recall_sound_volume, echo_audio_player],
		["DashAudioPlayer", "res://audio/dash-sfx.mp3", 0.0, dash_audio_player]
	]
	
	for config in sound_configs:
		var player = AudioStreamPlayer2D.new()
		player.name = config[0]
		add_child(player)
		if config[1] != "" and ResourceLoader.exists(config[1]):
			var sound = load(config[1])
			if sound is AudioStream:
				player.stream = sound
				player.volume_db = config[2]
				player.bus = "Master"
				player.max_distance = 500 if "Footstep" in config[0] else 2000
				player.attenuation = 0.0
		match config[0]:
			"FootstepAudioPlayer": footstep_audio_player = player
			"HitAudioPlayer": hit_audio_player = player
			"SwordSlicePlayer": sword_slice_player = player
			"PickupAudioPlayer": pickup_audio_player = player
			"HurtAudioPlayer": hurt_audio_player = player
			"EchoAudioPlayer": echo_audio_player = player
			"DashAudioPlayer": dash_audio_player = player
			
	footstep_audio_player.stream = FOOTSTEP_SOUND
	hit_audio_player.stream = HIT_SOUND
	pickup_audio_player.stream = PICKUP_SOUND

func play_sound_with_pitch(player: AudioStreamPlayer2D, base_pitch: float, variation: float):
	if not player or not player.stream:
		return
	if player.playing:
		player.stop()
	var final_pitch = base_pitch + randf_range(-variation, variation) if variation > 0.0 else base_pitch
	player.pitch_scale = clamp(final_pitch, 0.1, 3.0)
	player.play()

func play_hit_sound():
	play_sound_with_pitch(hit_audio_player, hit_sound_base_pitch, hit_sound_pitch_variation)

func play_sword_slice_sound():
	play_sound_with_pitch(sword_slice_player, hit_sound_base_pitch, hit_sound_pitch_variation)

func play_pickup_sound():
	play_sound_with_pitch(pickup_audio_player, pickup_sound_base_pitch, pickup_sound_pitch_variation)

func play_hurt_sound():
	play_sound_with_pitch(hurt_audio_player, hurt_sound_base_pitch, hurt_sound_pitch_variation)

func play_footstep_sound():
	play_sound_with_pitch(footstep_audio_player, footstep_pitch_base, footstep_pitch_variation)

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
			var item_name: String = str(item_data.get("name", item_data.get("id", "Item")))
			var qty: int = int(item_data.get("quantity", 1))
			var txt: String = "+" + (str(qty) + " " if qty > 1 else "") + item_name
			_spawn_potion_popup(txt, Color(1.0, 0.85, 0.2))
	else:
		var ui = get_node("../UI") if has_node("../UI") else null
		if ui and ui.has_method("add_item_to_inventory"):
			var success = ui.add_item_to_inventory(item_data.get("id", ""), item_data.get("quantity", 1))
			if success:
				play_pickup_sound()
				show_pickup_notification(item_data)
				var item_name2: String = str(item_data.get("name", item_data.get("id", "Item")))
				var qty2: int = int(item_data.get("quantity", 1))
				var txt2: String = "+" + (str(qty2) + " " if qty2 > 1 else "") + item_name2
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
	print("Player trying to interact with chests...")
	var chests = get_tree().get_nodes_in_group("chests")
	print("Found ", chests.size(), " objects in 'chests' group")
	
	for chest in chests:
		var distance = chest.global_position.distance_to(global_position)
		print("Distance to ", chest.name, ": ", distance)
		
		if distance < 50:
			print("Interacting with: ", chest.name)
			if chest.has_method("interact"):
				chest.interact()
			break

func check_npc_interaction():
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.has_method("interact") and npc.player_in_range:
			npc.interact()
			break

func _input(event):
	if event.is_action_pressed("open_quest_log"):
		var quest_log = get_node_or_null("/root/QuestLogUI")
		if not quest_log:
			quest_log = get_tree().current_scene.get_node_or_null("QuestLogUI")
		if quest_log:
			quest_log.open_quest_log()
	if event.is_action_pressed("interact"):
		check_npc_interaction()
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_RIGHT_X or event.axis == JOY_AXIS_RIGHT_Y:
			var right_stick = Vector2(
				Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
				Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
			if right_stick.length() > controller_deadzone:
				mouse_attack_direction = right_stick.normalized()
				if right_stick.x != 0:
					facing_direction = 1 if right_stick.x > 0 else -1

func _physics_process(delta):
	
	var right_stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if right_stick.length() > controller_deadzone:
		mouse_attack_direction = right_stick.normalized()
		right_stick_active = true
		if right_stick.x != 0:
			facing_direction = 1 if right_stick.x > 0 else -1
		queue_redraw()
	else:
		right_stick_active = false
		if velocity.length() > 0:
			mouse_attack_direction = velocity.normalized()
			queue_redraw()
	if dash_flash_timer > 0.0:
		dash_flash_timer -= delta
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
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			last_dash_path = echo_path.duplicate()
			if echo_path.size() > 1:
				spawn_echo_clone()
			echo_path.clear()
		else:
			dash_afterimage_timer -= delta
			if dash_afterimage_timer <= 0.0:
				emit_dash_afterimage()
				dash_afterimage_timer = dash_afterimage_interval
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if is_dashing:
		echo_timer += delta
		if echo_timer < echo_record_duration:
			echo_path.append(global_position)
	if Input.is_action_just_pressed('Attack') and not is_attacking and cooldown_timer <= 0:
		if not right_stick_active:
			var mouse_pos = get_global_mouse_position()
			mouse_attack_direction = (mouse_pos - global_position).normalized()
		start_attack()
	if Input.is_action_just_pressed('interact'):
		interact_with_chests()
	if Input.is_action_just_pressed('recall_echo'):
		recall_echoes()
	var direction = get_input()
	is_moving = direction.length() > 0
	if direction.length() > 0 and not is_attacking:
		last_direction = direction.normalized()
	if is_moving and velocity.length() > speed_threshold:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			play_footstep_sound()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0
	if Input.is_action_just_pressed('dash') and not is_dashing and dash_cooldown_timer <= 0.0 and not is_attacking and dash_energy >= dash_cost:
		var dash_dir = direction if direction.length() > 0 else last_direction
		start_dash(dash_dir.normalized())
	if is_dashing:
		velocity = dash_direction * dash_speed
		player_knockback_velocity = Vector2.ZERO
	elif player_knockback_velocity.length() > knockback_threshold:
		var target_velocity = (player_knockback_velocity * 0.7) + (direction.normalized() * speed * 0.3)
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
	if not is_dashing and dash_energy < max_dash_energy:
		var before = dash_energy
		dash_energy = min(max_dash_energy, int(round(dash_energy + dash_regen_rate * delta)))
		if dash_energy != before:
			dash_energy_changed.emit(dash_energy)
	if magic_ring_sprite and is_instance_valid(magic_ring_sprite):
		var target_pos = global_position
		if velocity.length() > 10:
			target_pos = global_position - (velocity.normalized() * ring_follow_distance)
		else:
			target_pos = global_position + Vector2(0, ring_follow_distance)
		magic_ring_sprite.global_position = magic_ring_sprite.global_position.lerp(target_pos, ring_follow_speed * delta)
		magic_ring_sprite.position.y += sin(Time.get_ticks_msec() * 0.003) * 0.5
		
func get_damage_against_enemy(enemy: Node) -> int:
	var base_damage = attack_damage
	var item_manager = get_node_or_null("/root/ItemManager")
	if item_manager and item_manager.has_method("has_item"):
		if item_manager.has_item("magic_ring") > 0:
			if enemy.is_in_group("ghosts") or enemy.name.to_lower().contains("ghost"):
				base_damage *= 2
				print("Magic Ring activated! Dealing 2x damage to ghost!")
				_spawn_magic_ring_effect(enemy.global_position)
	return base_damage

func _spawn_magic_ring_effect(position: Vector2):
	var label := Label.new()
	label.text = "✨ GHOST BANE!"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.6, 0.3, 1.0))
	label.modulate.a = 0.0
	label.z_index = 200
	var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if parent:
		parent.add_child(label)
		label.top_level = true
		label.global_position = position + Vector2(0, -20)
		var t = create_tween()
		t.tween_property(label, "modulate:a", 1.0, 0.1)
		t.tween_property(label, "global_position", position + Vector2(0, -40), 0.5)
		t.tween_property(label, "modulate:a", 0.0, 0.3)
		t.tween_callback(func(): label.queue_free())

func start_dash(dir: Vector2):
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_direction = dir
	echo_path.clear()
	if dash_audio_player and dash_audio_player.stream:
		play_sound_with_pitch(dash_audio_player, dash_sound_base_pitch, dash_sound_pitch_variation)
	echo_timer = 0.0
	echo_spawned_this_dash = false
	last_dash_start = global_position
	var before = dash_energy
	dash_energy = max(0, dash_energy - dash_cost)
	if dash_energy != before:
		dash_energy_changed.emit(dash_energy)
	damage_immunity_timer = max(damage_immunity_timer, dash_iframe_duration)
	is_dash_iframe = true
	flash_white(0.08)
	dash_afterimage_timer = 0.0
	var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
	if cam:
		if cam.has_method("shake_camera"):
			cam.shake_camera(4.0, 0.10)
		if cam.has_method("pulse_vignette"):
			cam.pulse_vignette(0.22, 0.16, 0.10)

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
		var timer := get_tree().create_timer(dash_afterimage_lifetime + 0.15)
		timer.timeout.connect(func(): if is_instance_valid(ghost): ghost.queue_free())

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
			sprite.modulate = Color.WHITE)

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
		return "down" if direction.y > 0 else "up"

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
	var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
	if cam:
		if cam.has_method("shake_camera"):
			cam.shake_camera(10.0, 0.18)
		if cam.has_method("pulse_vignette"):
			cam.pulse_vignette(0.30, 0.18, 0.12)
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
		health_bar.max_value = int(max_health)
		health_bar.value = clamp(int(current_health), 0, int(max_health))

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
	#await get_tree().create_timer(1.0).timeout
	#get_tree().change_scene_to_file("res://scenes/world.tscn")

func heal(amount: int):
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	if current_health != old_health:
		health_changed.emit(current_health)
		update_health_display()
		var gained = current_health - old_health
		if gained > 0:
			_spawn_potion_popup("HP +" + str(gained), Color(0.2, 0.9, 0.2))

func restore_dash(amount: int):
	var before = dash_energy
	dash_energy = min(max_dash_energy, dash_energy + amount)
	if dash_energy != before:
		dash_energy_changed.emit(dash_energy)
	echo_charges = echo_max_charges
	echoes_changed.emit(active_echoes.size())
	var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
	if cam and cam.has_method("pulse_vignette"):
		cam.pulse_vignette(0.28, 0.22, 0.14)
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
	t.tween_property(label, "scale", Vector2(1.3, 1.3), 0.08)
	t.tween_property(label, "modulate:a", 1.0, 0.08)
	var t2 = create_tween()
	t2.tween_property(label, "global_position", label.global_position + Vector2(0, -36), 0.5)
	t2.tween_property(label, "modulate:a", 0.0, 0.5)
	t2.tween_callback(func(): if is_instance_valid(label): label.queue_free())

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
	var cam = get_tree().current_scene.get_node_or_null("PlayerCamera") if get_tree() and get_tree().current_scene else null
	if cam and cam.has_method("shake_camera"):
		cam.shake_camera(6.0, 0.12)

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
	var ease_progress = 1.0 - (1.0 - swing_current_progress) * (1.0 - swing_current_progress)
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
	if right_stick_active:
		var start_pos = Vector2.ZERO
		var end_pos = mouse_attack_direction * 30
		draw_line(start_pos, end_pos, Color.WHITE, 2.0)
		draw_arc(Vector2.ZERO, attack_range * 0.3, 0, PI/2, 16, Color.WHITE, 1.0)
	if not enable_trail_effect or trail_positions.size() < 2:
		return
	for i in range(trail_positions.size() - 1):
		var trail_start_pos = to_local(trail_positions[i])
		var trail_end_pos = to_local(trail_positions[i + 1])
		var alpha = float(i) / float(trail_positions.size() - 1)
		var color = trail_color
		color.a = alpha * trail_max_alpha
		draw_line(trail_start_pos, trail_end_pos, color, trail_width)

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
		attack_sprite.modulate.a = 1.0)

func position_attack_hitbox(direction: Vector2):
	if not attack_collision:
		return
	var offset_distance = 32
	var hitbox_offset = direction * offset_distance
	if attack_collision:
		attack_collision.position = hitbox_offset
	attack_collision.rotation = direction.angle()

func _on_attack_area_body_entered(body):
	if HitEffectScene:
		var fx = HitEffectScene.instantiate()
		fx.global_position = body.global_position
		var parent = get_tree().current_scene if get_tree() else get_parent()
		if parent:
			parent.add_child(fx)
			fx.rotation = mouse_attack_direction.angle()
			if fx is GPUParticles2D:
				fx.emitting = true
				fx.one_shot = true
			elif fx is CPUParticles2D:
				fx.emitting = true
				fx.one_shot = true
	
	if body.has_method("take_damage"):
		var damage = get_damage_against_enemy(body)
		body.take_damage(damage)
		body.take_damage(damage, self) 
		play_sword_slice_sound()
		enemy_killed.emit()
	elif body.has_method("on_sword_hit"):
		body.on_sword_hit()
		play_sword_slice_sound()
	else:
		play_hit_sound()

func spawn_echo_clone():
	var echo: EchoGhost = EchoGhost.new()
	var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if not parent:
		return
	var tex: Texture2D = sprite.texture if sprite else null
	var scale_v: Vector2 = sprite.scale if sprite else Vector2.ONE
	var hfr: int = sprite.hframes if sprite else 1
	var vfr: int = sprite.vframes if sprite else 1
	var frm: int = sprite.frame if sprite else 0
	var fh: bool = sprite.flip_h if sprite else false
	var fv: bool = sprite.flip_v if sprite else false
	var ctr: bool = sprite.centered if sprite else true
	var start_pos = echo_path[0] if echo_path.size() > 0 else global_position
	echo.move_speed = echo_move_speed
	echo.burst_damage = echo_burst_damage
	echo.burst_radius = echo_burst_radius
	echo.damage_on_move = true
	echo.move_hit_radius = 14.0
	echo.afterimage_interval = 0.03
	echo.afterimage_lifetime = 0.20
	echo.setup(tex, scale_v, start_pos, echo_path, hfr, vfr, frm, fh, fv, ctr)
	parent.add_child(echo)
	echo.flash_white(0.06)
	active_echoes.append(echo)
	while active_echoes.size() > echo_max_charges:
		var old = active_echoes.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	echoes_changed.emit(active_echoes.size())
	echo_spawned.emit(echo_record_duration)

func recall_echoes():
	if echo_charges > 0 and last_dash_path.size() >= 1:
		var ghost := EchoGhost.new()
		var parent = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
		if parent:
			var tex: Texture2D = sprite.texture if sprite else null
			var scale_v: Vector2 = sprite.scale if sprite else Vector2.ONE
			var hfr: int = sprite.hframes if sprite else 1
			var vfr: int = sprite.vframes if sprite else 1
			var frm: int = sprite.frame if sprite else 0
			var fh: bool = sprite.flip_h if sprite else false
			var fv: bool = sprite.flip_v if sprite else false
			var ctr: bool = sprite.centered if sprite else true
			ghost.move_speed = echo_move_speed
			ghost.echo_damage = attack_damage
			ghost.burst_damage = echo_burst_damage
			ghost.burst_radius = echo_burst_radius
			ghost.damage_on_move = true
			ghost.move_hit_radius = 14.0
			ghost.afterimage_interval = 0.04
			ghost.afterimage_lifetime = 0.18
			var path_for_ghost: Array[Vector2] = last_dash_path.duplicate() if last_dash_path.size() >= 1 else [last_dash_start]
			path_for_ghost.append(global_position)
			ghost.setup(tex, scale_v, last_dash_start, path_for_ghost, hfr, vfr, frm, fh, fv, ctr)
			parent.add_child(ghost)
			ghost.flash_white(0.06)
			echo_charges -= 1
			echoes_changed.emit(active_echoes.size())
	for e in active_echoes:
		if is_instance_valid(e) and e.has_method("queue_free"):
			e.queue_free()
	active_echoes.clear()
	echoes_changed.emit(0)
	if echo_audio_player and echo_audio_player.stream:
		if echo_audio_player.playing:
			echo_audio_player.stop()
		echo_audio_player.play()

func update_magic_ring_display():
	var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		print("⚠ ItemManager not found")
		return
	
	var has_ring = item_manager.has_item("magic_ring") > 0
	print("Updating magic ring display. Has ring: ", has_ring)
	
	if has_ring and not magic_ring_sprite:
		# Create the ring sprite
		magic_ring_sprite = Sprite2D.new()
		magic_ring_sprite.name = "MagicRingFollower"
		magic_ring_sprite.z_index = 10  # Changed from -1 to 10 to render ABOVE player
		
		var ring_texture = load("res://Assets/Ring Sprites.png")
		if ring_texture:
			magic_ring_sprite.texture = ring_texture
			magic_ring_sprite.scale = Vector2(1.5, 1.5)
			magic_ring_sprite.modulate = Color(1.2, 1.2, 1.5)
			print("✓ Ring texture loaded")
		else:
			print("✗ Failed to load ring texture")
			return
		
		# IMPORTANT: Add as child of player, not scene
		# This way it moves with the player automatically
		add_child(magic_ring_sprite)
		
		# Position relative to player
		magic_ring_sprite.position = Vector2(0, ring_follow_distance)
		
		print("✓ Magic ring sprite added to player")
		print("  Ring position: ", magic_ring_sprite.position)
		print("  Ring global position: ", magic_ring_sprite.global_position)
		print("  Ring z_index: ", magic_ring_sprite.z_index)
		print("  Ring visible: ", magic_ring_sprite.visible)
		print("  Ring scale: ", magic_ring_sprite.scale)
	
	elif has_ring and magic_ring_sprite:
		# Ring already exists, just make sure it's visible
		magic_ring_sprite.visible = true
		print("✓ Magic ring already exists")
		print("  Is instance valid: ", is_instance_valid(magic_ring_sprite))
		print("  Parent: ", magic_ring_sprite.get_parent())
	
	elif not has_ring and magic_ring_sprite:
		# Player doesn't have ring, remove it
		magic_ring_sprite.queue_free()
		magic_ring_sprite = null
		print("✓ Magic ring removed (player doesn't have it)")
	#var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		print("⚠ ItemManager not found")
		return
	
	#var has_ring = item_manager.has_item("magic_ring") > 0
	print("Updating magic ring display. Has ring: ", has_ring)
	
	if has_ring and not magic_ring_sprite:
		# Create the ring sprite
		magic_ring_sprite = Sprite2D.new()
		magic_ring_sprite.name = "MagicRingFollower"
		magic_ring_sprite.z_index = -1
		
		var ring_texture = load("res://Assets/Ring Sprites.png")
		if ring_texture:
			magic_ring_sprite.texture = ring_texture
			magic_ring_sprite.scale = Vector2(1.5, 1.5)
			magic_ring_sprite.modulate = Color(1.2, 1.2, 1.5)
			print("✓ Ring texture loaded")
		else:
			print("✗ Failed to load ring texture")
		
		# Add to current scene
		var parent = get_tree().current_scene
		if not parent:
			# Fallback: try to get the parent directly
			parent = get_parent()
		
		if parent:
			parent.add_child(magic_ring_sprite)
			magic_ring_sprite.global_position = global_position
			print("✓ Magic ring sprite added to scene")
		else:
			print("✗ Could not find parent to add ring to")
	
	elif has_ring and magic_ring_sprite:
		# Ring already exists, just make sure it's visible
		magic_ring_sprite.visible = true
		print("✓ Magic ring already exists, ensuring visibility")
	
	elif not has_ring and magic_ring_sprite:
		# Player doesn't have ring, remove it
		magic_ring_sprite.queue_free()
		magic_ring_sprite = null
		print("✓ Magic ring removed (player doesn't have it)")
	#var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		return
	#var has_ring = item_manager.has_item("magic_ring") > 0
	if has_ring and not magic_ring_sprite:
		magic_ring_sprite = Sprite2D.new()
		magic_ring_sprite.name = "MagicRingFollower"
		magic_ring_sprite.z_index = -1
		var ring_texture = load("res://Assets/Ring Sprites.png")
		if ring_texture:
			magic_ring_sprite.texture = ring_texture
			magic_ring_sprite.scale = Vector2(1.5, 1.5)
			magic_ring_sprite.modulate = Color(1.2, 1.2, 1.5)
		var parent = get_tree().current_scene
		if parent:
			parent.add_child(magic_ring_sprite)
			magic_ring_sprite.global_position = global_position
	elif not has_ring and magic_ring_sprite:
		magic_ring_sprite.queue_free()
		magic_ring_sprite = null

func _on_item_picked_up(item_data):
	if item_data.get("id") == "magic_ring":
		update_magic_ring_display()

# Getters
func get_is_attacking() -> bool: return is_attacking
func get_facing_direction() -> Vector2: return mouse_attack_direction if is_attacking else last_direction
func get_mouse_attack_direction() -> Vector2: return mouse_attack_direction
func is_alive() -> bool: return current_health > 0
func get_current_health() -> int: return current_health
func get_max_health() -> int: return max_health
func get_health() -> int: return current_health
func can_take_damage() -> bool: return damage_immunity_timer <= 0
func get_knockback_resistance() -> float: return knockback_resistance
func set_pickup_range(new_range: float):
	pickup_range = new_range
	if pickup_collision and pickup_collision.shape is CircleShape2D:
		pickup_collision.shape.radius = pickup_range
func get_pickup_range() -> float: return pickup_range
func toggle_auto_pickup(): auto_pickup_enabled = !auto_pickup_enabled
func on_enemy_killed(): enemy_killed.emit()
func get_spawn_position() -> Vector2: return Vector2(0, 0)
func get_echo_count() -> int: return active_echoes.size()
func get_dash_energy() -> int: return dash_energy
func get_max_dash_energy() -> int: return max_dash_energy

func get_directional_input() -> Vector2:
	var input_vector = Vector2.ZERO
	var raw_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if raw_input.length() > 0:
		var is_controller = Input.get_connected_joypads().size() > 0 and raw_input.length() < 0.99
		
		if is_controller:
			var abs_x = abs(raw_input.x)
			var abs_y = abs(raw_input.y)
			
			if abs_x > abs_y:
				input_vector = Vector2(sign(raw_input.x), 0)
			else:
				input_vector = Vector2(0, sign(raw_input.y))
		else:
			input_vector = raw_input.normalized()
	
	return input_vector
	
func _refresh_weapon_visual():
	await get_tree().process_frame
	
	var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		print("ItemManager not found!")
		return
	
	var equipped = item_manager.get_equipped_weapon()
	if equipped.is_empty():
		print("No weapon equipped")
		return
	
	print("Refreshing weapon visual: ", equipped.get("name", "Unknown"))
	
	# Update attack sprite texture
	if attack_sprite:
		print("BEFORE - Scale: ", attack_sprite.scale, " Texture: ", attack_sprite.texture)
		
		var weapon_texture_path = equipped.get("sprite_path", equipped.get("icon_path", ""))
		if weapon_texture_path != "" and ResourceLoader.exists(weapon_texture_path):
			var weapon_texture = load(weapon_texture_path)
			attack_sprite.texture = weapon_texture
			
			# FIXED: Use weapon_scale from ItemManager data
			var weapon_scale = equipped.get("weapon_scale", 2.5)  # Default to 2.5 if not specified
			attack_sprite.scale = Vector2(weapon_scale, weapon_scale)
			
			# Make sure sprite properties are correct
			attack_sprite.visible = false  # Hidden until attack
			attack_sprite.centered = true
			
			print("AFTER - Scale: ", attack_sprite.scale, " Texture: ", attack_sprite.texture)
			print("✓ Weapon texture updated with scale: ", weapon_scale)
		else:
			print("✗ Weapon texture not found: ", weapon_texture_path)
	else:
		print("✗ attack_sprite not found!")
	
	# Update weapon stats
	if "damage" in equipped:
		attack_damage = equipped.damage
		print("✓ Damage updated: ", attack_damage)
	
	if "attack_range" in equipped:
		attack_range = equipped.attack_range
		print("✓ Range updated: ", attack_range)
	
	if "attack_speed" in equipped:
		var weapon_speed = equipped.attack_speed
		attack_cooldown = 1.0 / weapon_speed
		print("✓ Attack speed updated: ", weapon_speed)
	
	print("Weapon refresh complete!")
	


func _delayed_weapon_refresh():
	await get_tree().create_timer(0.1).timeout  # Wait a bit longer
	_refresh_weapon_visual()
