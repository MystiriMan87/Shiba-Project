extends Area2D
class_name PickupItem

@export var item_id: String = ""
@export var quantity: int = 1
@export var auto_pickup: bool = true
@export var pickup_animation_duration: float = 0.3
@export var hover_animation_enabled: bool = true
@export var hover_amplitude: float = 5.0
@export var hover_speed: float = 2.0

@export_group("Sound Effects")
@export var has_custom_pickup_sound: bool = false
@export var pickup_sound_path: String = ""
@export var pickup_sound_volume: float = 0.0
@export var pickup_sound_pitch: float = 1.0

var item_data: Dictionary = {}
var is_picked_up: bool = false
var original_position: Vector2
var hover_timer: float = 0.0

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var pickup_audio_player: AudioStreamPlayer2D = null

signal item_picked_up(item_data: Dictionary)

func _ready():
	collision_layer = 8
	collision_mask = 0
	
	original_position = global_position
	load_item_data()
	setup_sprite()
	setup_collision_shape()
	setup_pickup_sound() 
	
	print("PickupItem created: ", item_id, " x", quantity, " at layer ", collision_layer)

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
		circle.radius = 20
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
		
	if hover_animation_enabled:
		hover_timer += delta * hover_speed
		var hover_offset = sin(hover_timer) * hover_amplitude
		global_position.y = original_position.y + hover_offset
		
		if sprite:
			sprite.rotation = sin(hover_timer * 0.5) * 0.1

func pickup_item() -> Dictionary:
	"""Called by player's pickup system"""
	if is_picked_up:
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
	"""Set the item this pickup represents"""
	item_id = new_item_id
	quantity = new_quantity
	load_item_data()
	setup_sprite()
	print("Pickup item set to: ", item_id, " x", quantity)

func get_rarity_color(rarity: String) -> Color:
	"""Get color based on item rarity for visual effects"""
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
	"""Alternative pickup trigger for Area2D based players"""
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
