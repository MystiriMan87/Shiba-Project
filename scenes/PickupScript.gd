extends Area2D
class_name PickupItem

@export var item_id: String = ""
@export var quantity: int = 1
@export var auto_pickup: bool = true
@export var pickup_animation_duration: float = 0.3
@export var hover_animation_enabled: bool = true
@export var hover_amplitude: float = 5.0
@export var hover_speed: float = 2.0

 
@export var show_name_on_hover: bool = true
@export var hover_name_offset: Vector2 = Vector2(0, -28)
@export var hover_show_radius: float = 28.0

@export var active_collision_layer: int = 8

 
@export var spawn_pickup_delay: float = 0.8

 
@export var thrown_speed_min: float = 140.0
@export var thrown_speed_max: float = 200.0
@export var thrown_deceleration: float = 1400.0

@export_group("Sound Effects")
@export var has_custom_pickup_sound: bool = false
@export var pickup_sound_path: String = ""
@export var pickup_sound_volume: float = 0.0
@export var pickup_sound_pitch: float = 1.0

var item_data: Dictionary = {}
var is_picked_up: bool = false
var original_position: Vector2
var hover_timer: float = 0.0
var pickup_delay_timer: float = 0.0
var is_thrown: bool = false
var throw_velocity: Vector2 = Vector2.ZERO
var activation_pending: bool = false

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var pickup_audio_player: AudioStreamPlayer2D = null
@onready var name_label: Label = null

signal item_picked_up(item_data: Dictionary)

func _ready():
	collision_layer = 0
	collision_mask = 0
	
	original_position = global_position
	# No viewport clamping: we trust the chest to spawn relative to itself
	original_position = global_position
	load_item_data()
	setup_sprite()
	setup_collision_shape()
	setup_pickup_sound() 
	setup_name_label()
	
	pickup_delay_timer = max(pickup_delay_timer, spawn_pickup_delay)
	activation_pending = true
	
	print("PickupItem created: ", item_id, " x", quantity, " at layer ", collision_layer, " pos=", global_position)
	
	# Mouse signals can be unreliable across nodes; use distance-based hover
	input_pickable = true

func setup_pickup_sound():
	if has_custom_pickup_sound and pickup_sound_path != "":
		pickup_audio_player = AudioStreamPlayer2D.new()
		pickup_audio_player.name = "PickupAudioPlayer"
		add_child(pickup_audio_player)
		
		if ResourceLoader.exists(pickup_sound_path):
			var sound = load(pickup_sound_path)
			if sound is AudioStream:
				pickup_audio_player.stream = sound
				pickup_audio_player.volume_db = pickup_sound_volume
				pickup_audio_player.pitch_scale = pickup_sound_pitch
				pickup_audio_player.bus = "Master"

func play_pickup_sound():
	if pickup_audio_player and pickup_audio_player.stream:
		pickup_audio_player.play()

func setup_collision_shape():
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	
	if not collision_shape.shape:
		var circle = CircleShape2D.new()
		circle.radius = 12
		collision_shape.shape = circle

func load_item_data():
	var item_manager = get_node("/root/ItemManager") if has_node("/root/ItemManager") else null
	if item_manager:
		item_data = item_manager.get_item_data(item_id)
		if item_data.is_empty():
			print("Warning: Item data not found for ID: ", item_id)
			item_data = {
				"id": item_id,
				"name": item_id.capitalize().replace("_", " "),
				"icon_path": "res://icon.svg",
				"quantity": quantity,
				"rarity": "common"
			}
	else:
		print("ItemManager not found, using fallback data")
		item_data = {
			"id": item_id,
			"name": item_id.capitalize().replace("_", " "),
			"icon_path": "res://icon.svg", 
			"quantity": quantity,
			"rarity": "common"
		}

func setup_sprite():
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	var icon_path = item_data.get("icon_path", "res://icon.svg")
	if ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		if texture:
			sprite.texture = texture
			var target_size = Vector2(48, 48)
			if texture.get_size().x > 0 and texture.get_size().y > 0:
				var scale_x = target_size.x / texture.get_size().x
				var scale_y = target_size.y / texture.get_size().y
				var scale_factor = min(scale_x, scale_y)
				sprite.scale = Vector2(scale_factor, scale_factor)
	else:
		create_fallback_sprite()

func setup_name_label():
	if not show_name_on_hover:
		return
	if not name_label:
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.visible = false
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		name_label.add_theme_constant_override("shadow_offset_x", 1)
		name_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(name_label)
	
	var name_text = item_data.get("name", item_id.capitalize().replace("_", " "))
	name_label.text = name_text

func create_fallback_sprite():
	var fallback_texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color = get_rarity_color(item_data.get("rarity", "common"))
	image.fill(color)
	fallback_texture.set_image(image)
	sprite.texture = fallback_texture

func _process(delta):
	if is_picked_up:
		return
	
	# countdown pickup buffer
	if pickup_delay_timer > 0.0:
		pickup_delay_timer -= delta
		if pickup_delay_timer < 0.0:
			pickup_delay_timer = 0.0
	if activation_pending and pickup_delay_timer <= 0.0:
		collision_layer = active_collision_layer
		activation_pending = false

	# simple thrown motion
	if is_thrown:
		if throw_velocity.length() > 0.0:
			global_position += throw_velocity * delta
			var speed = throw_velocity.length()
			speed = max(0.0, speed - thrown_deceleration * delta)
			throw_velocity = throw_velocity.normalized() * speed if speed > 0.0 else Vector2.ZERO
			if speed <= 10.0:
				is_thrown = false

	# if player is overlapping after delay, auto-pickup now
	if auto_pickup and pickup_delay_timer <= 0.0:
		for body in get_overlapping_bodies():
			if body and body.has_method("add_item_to_inventory"):
				var data = pickup_item()
				if not data.is_empty():
					body.add_item_to_inventory(data)
					return
		for area in get_overlapping_areas():
			if area and area.has_method("add_item_to_inventory"):
				var data2 = pickup_item()
				if not data2.is_empty():
					area.add_item_to_inventory(data2)
					return
	if hover_animation_enabled:
		hover_timer += delta * hover_speed
		var hover_offset = sin(hover_timer) * hover_amplitude
		global_position.y = original_position.y + hover_offset
		
		if sprite:
			sprite.rotation = sin(hover_timer * 0.5) * 0.1
		
	# Distance-based hover name display
	if show_name_on_hover and name_label:
		var mouse_pos = get_global_mouse_position()
		var hovering = mouse_pos.distance_to(global_position) <= hover_show_radius
		name_label.visible = hovering
		if hovering:
			name_label.position = hover_name_offset

func pickup_item() -> Dictionary:
	
	if is_picked_up:
		return {}
	if pickup_delay_timer > 0.0:
		return {}
	
	print("Item being picked up: ", item_id, " x", quantity)
	
	play_pickup_sound()
	
	var pickup_data = item_data.duplicate()
	pickup_data["quantity"] = quantity
	
	perform_pickup_animation()
	return pickup_data

func perform_pickup_animation():
	if is_picked_up:
		return
		
	is_picked_up = true
	item_picked_up.emit(item_data)
	
	if collision_shape:
		collision_shape.disabled = true
	
	if sprite:
		var original_scale = sprite.scale
		
		var tween = create_tween()
		tween.tween_property(sprite, "scale", original_scale * 1.5, pickup_animation_duration * 0.3)
		
		var parallel_tween = create_tween()
		parallel_tween.set_parallel(true)
		parallel_tween.tween_property(sprite, "scale", Vector2.ZERO, pickup_animation_duration * 0.7)
		parallel_tween.tween_property(self, "global_position", global_position + Vector2(0, -30), pickup_animation_duration * 0.7)
		parallel_tween.tween_property(sprite, "modulate:a", 0.0, pickup_animation_duration * 0.7)
		
		parallel_tween.tween_callback(queue_free)
	else:
		queue_free()

func set_item(new_item_id: String, new_quantity: int = 1):
	
	item_id = new_item_id
	quantity = new_quantity
	load_item_data()
	setup_sprite()
	print("Pickup item set to: ", item_id, " x", quantity)

func set_pickup_delay(seconds: float):
	
	pickup_delay_timer = max(pickup_delay_timer, seconds)

func throw_from(origin: Vector2, direction: Vector2, speed: float = -1.0):
	
	global_position = origin
	var final_speed = speed if speed > 0.0 else randf_range(thrown_speed_min, thrown_speed_max)
	throw_velocity = direction.normalized() * final_speed
	is_thrown = true

func get_rarity_color(rarity: String) -> Color:
	
	match rarity:
		"common":
			return Color.LIGHT_GRAY
		"uncommon":
			return Color.GREEN
		"rare":
			return Color.BLUE
		"epic":
			return Color.PURPLE
		"legendary":
			return Color.ORANGE
		_:
			return Color.WHITE

static func create_pickup_item(item_id: String, spawn_position: Vector2, quantity: int = 1) -> PickupItem:
	var pickup = PickupItem.new()
	pickup.global_position = spawn_position
	pickup.set_item(item_id, quantity)
	return pickup

func _on_body_entered(body):
	"""Handle automatic pickup when player enters area"""
	if auto_pickup and not is_picked_up and body.has_method("add_item_to_inventory"):
		var pickup_data = pickup_item()
		if not pickup_data.is_empty():
			body.add_item_to_inventory(pickup_data)

func _on_area_entered(area):
	
	if auto_pickup and not is_picked_up and area.has_method("add_item_to_inventory"):
		var pickup_data = pickup_item()
		if not pickup_data.is_empty():
			area.add_item_to_inventory(pickup_data)

func _enter_tree():
	if auto_pickup:
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
		if not area_entered.is_connected(_on_area_entered):
			area_entered.connect(_on_area_entered)

# Mouse signal handlers removed in favor of distance-based check
