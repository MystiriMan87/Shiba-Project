extends StaticBody2D
class_name Chest

@export var is_locked: bool = true
@export var key_type: String = "wooden"  # wooden, iron, golden
@export var loot_items: Array[String] = ["health_potion", "coin"]

var is_open: bool = false
var player_near: bool = false
var is_animating: bool = false

@onready var sprite = $Sprite2D
@onready var area = $Area2D
@onready var animation_player = $AnimationPlayer

func _ready():
	add_to_group("chests")
	if not area:
		area = Area2D.new()
		add_child(area)
		var collision = CollisionShape2D.new()
		area.add_child(collision)
		var shape = CircleShape2D.new()
		shape.radius = 40
		collision.shape = shape
		# Set collision layer to 8 (for player pickup detection)
		area.collision_layer = 8
		area.collision_mask = 0
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Set up sprite
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	
	update_sprite()

func update_sprite():
	if not sprite:
		return
	
	# Try to load chest textures first
	var texture_path = ""
	if is_open:
		texture_path = "res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_open_1.png"
	elif is_locked:
		texture_path = "res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_2.png"
	else:
		texture_path = "res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_1.png"
	
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		# Fallback to colored squares
		var color = Color.GREEN if is_open else (Color.RED if is_locked else Color.BROWN)
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(color)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture

# Remove _input - we'll handle this in the player script instead

func open_chest():
	if is_locked:
		var item_manager = get_node("/root/ItemManager")
		if item_manager and item_manager.has_item(key_type + "_key"):
			item_manager.remove_item_from_inventory(key_type + "_key", 1)
			is_locked = false
		else:
			print("Need " + key_type + " key!")
			return
	
	# Play opening animation
	play_opening_animation()

func play_opening_animation():
	is_animating = true
	
	var frames = [
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_1.png",
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_2.png", 
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_3.png",
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_4.png",
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_open_1.png",
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_open_2.png",
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_open_3.png",
		"res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/chest/chest_open_4.png"
	]
	
	var tween = create_tween()
	var frame_duration = 0.1
	
	for i in range(frames.size()):
		if ResourceLoader.exists(frames[i]):
			tween.tween_callback(func(): sprite.texture = load(frames[i]))
			tween.tween_interval(frame_duration)
	
	tween.tween_callback(finish_opening)

func finish_opening():
	is_open = true
	is_animating = false
	
	# Drop loot
	for item in loot_items:
		spawn_item(item, global_position + Vector2(randf_range(-20, 20), -20))

func spawn_item(item_id: String, pos: Vector2):
	var pickup_scene = load("res://scenes/PickupItem.tscn")
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = pos
		pickup.collision_layer = 8
		pickup.collision_mask = 0
		pickup.set_item(item_id, 1)

func _on_body_entered(body):
	if body.has_method("add_item_to_inventory"):
		player_near = true

func _on_body_exited(body):
	if body.has_method("add_item_to_inventory"):
		player_near = false

func interact():
	if player_near and not is_open and not is_animating:
		open_chest()
