# PickupItem.gd - Fully Fixed for Godot 4.4
extends Area2D
class_name PickupItem

@export var item_id: String = ""
@export var quantity: int = 1
@export var auto_pickup: bool = true
@export var pickup_animation_duration: float = 0.3
@export var hover_animation_enabled: bool = true
@export var hover_amplitude: float = 5.0
@export var hover_speed: float = 2.0

var item_data: Dictionary = {}
var is_picked_up: bool = false
var original_position: Vector2
var hover_timer: float = 0.0

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null

signal item_picked_up(item_data: Dictionary)

func _ready():
	# FIXED: Set correct collision layers to match player's pickup system
	collision_layer = 8   # Items are on layer 4 (bit 3) - this gives value 8
	collision_mask = 0    # Items don't need to detect anything
	
	# Store original position for hover animation
	original_position = global_position
	
	# Load item data
	load_item_data()
	
	# Set up sprite and collision
	setup_sprite()
	setup_collision_shape()
	
	print("PickupItem created: ", item_id, " x", quantity, " at layer ", collision_layer)

func setup_collision_shape():
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	
	# Create a circle shape for pickup detection
	if not collision_shape.shape:
		var circle = CircleShape2D.new()
		circle.radius = 20  # Slightly larger for easier pickup
		collision_shape.shape = circle

func load_item_data():
	var item_manager = get_node("/root/ItemManager") if has_node("/root/ItemManager") else null
	if item_manager:
		item_data = item_manager.get_item_data(item_id)
		if item_data.is_empty():
			print("Warning: Item data not found for ID: ", item_id)
			# Create fallback data
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
	
	# Load the item's icon as the sprite texture
	var icon_path = item_data.get("icon_path", "res://icon.svg")
	if ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		if texture:
			sprite.texture = texture
			print("Loaded sprite texture: ", icon_path)
			
			# Scale sprite to appropriate size for pickup items
			var target_size = Vector2(32, 32)
			if texture.get_size().x > 0 and texture.get_size().y > 0:
				var scale_x = target_size.x / texture.get_size().x
				var scale_y = target_size.y / texture.get_size().y
				var scale_factor = min(scale_x, scale_y)
				sprite.scale = Vector2(scale_factor, scale_factor)
		else:
			print("Failed to load texture: ", icon_path)
	else:
		print("Texture file doesn't exist: ", icon_path, " - using fallback")
		# Use a simple colored rectangle as fallback
		create_fallback_sprite()

func create_fallback_sprite():
	# Create a simple colored rectangle when texture is missing
	var fallback_texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color = get_rarity_color(item_data.get("rarity", "common"))
	image.fill(color)
	fallback_texture.set_image(image)
	sprite.texture = fallback_texture

func _process(delta):
	if is_picked_up:
		return
		
	# Hover animation
	if hover_animation_enabled:
		hover_timer += delta * hover_speed
		var hover_offset = sin(hover_timer) * hover_amplitude
		global_position.y = original_position.y + hover_offset
		
		# Optional: Add gentle rotation
		if sprite:
			sprite.rotation = sin(hover_timer * 0.5) * 0.1

# This is the key function the player calls
func pickup_item() -> Dictionary:
	"""Called by player's pickup system"""
	if is_picked_up:
		return {}
	
	print("Item being picked up: ", item_id, " x", quantity)
	
	var pickup_data = item_data.duplicate()
	pickup_data["quantity"] = quantity
	
	perform_pickup_animation()
	return pickup_data

# FULLY FIXED: Animation function for Godot 4.4
func perform_pickup_animation():
	if is_picked_up:
		return
		
	is_picked_up = true
	item_picked_up.emit(item_data)
	
	# Disable collision to prevent multiple pickups
	if collision_shape:
		collision_shape.disabled = true
	
	# Play pickup animation - FIXED for Godot 4.4
	if sprite:
		# Store original scale for animation
		var original_scale = sprite.scale
		
		# Create main tween for scale up
		var tween = create_tween()
		tween.tween_property(sprite, "scale", original_scale * 1.5, pickup_animation_duration * 0.3)
		
		# Create second tween for simultaneous effects
		var parallel_tween = create_tween()
		parallel_tween.set_parallel(true)
		parallel_tween.tween_property(sprite, "scale", Vector2.ZERO, pickup_animation_duration * 0.7)
		parallel_tween.tween_property(self, "global_position", global_position + Vector2(0, -30), pickup_animation_duration * 0.7)
		parallel_tween.tween_property(sprite, "modulate:a", 0.0, pickup_animation_duration * 0.7)
		
		# Remove after animation completes
		parallel_tween.tween_callback(queue_free)
	else:
		# No sprite, just remove immediately
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

# FIXED: Static function to create pickup items from code
static func create_pickup_item(item_id: String, spawn_position: Vector2, quantity: int = 1) -> PickupItem:
	# Create the pickup item directly since we don't have a .tscn file
	var pickup = PickupItem.new()
	pickup.global_position = spawn_position
	pickup.set_item(item_id, quantity)
	return pickup

# Additional helper functions for Godot 4.4 compatibility

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

# Connect signals properly in Godot 4.4
func _enter_tree():
	# Connect area signals if auto_pickup is enabled
	if auto_pickup:
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
		if not area_entered.is_connected(_on_area_entered):
			area_entered.connect(_on_area_entered)
