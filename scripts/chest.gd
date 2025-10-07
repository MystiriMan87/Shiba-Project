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

func clamp_to_viewport(p: Vector2, margin: float = 32.0) -> Vector2:
	var rect: Rect2 = get_viewport().get_visible_rect()
	var min_v = rect.position + Vector2(margin, margin)
	var max_v = rect.position + rect.size - Vector2(margin, margin)
	var x = clamp(p.x, min_v.x, max_v.x)
	var y = clamp(p.y, min_v.y, max_v.y)
	return Vector2(x, y)

# Remove _input - we'll handle this in the player script instead

@export var loot_throw_delay: float = 2.0
@export var loot_throw_spread_degrees: float = 70.0
@export var loot_throw_speed_min: float = 120.0
@export var loot_throw_speed_max: float = 180.0
@export var loot_spawn_offset: Vector2 = Vector2(0, -16)
@export var loot_spawn_radius_base: float = 24.0
@export var loot_spawn_radius_step: float = 10.0

func open_chest():
	if is_locked:
		var item_manager = get_node("/root/ItemManager")
		if item_manager and item_manager.has_item(key_type + "_key"):
			item_manager.remove_item_from_inventory(key_type + "_key", 1)
			is_locked = false
		else:
			print("Need " + key_type + " key!")
			return
			
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		quest_manager.on_chest_opened()
	
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
	
	# Add a subtle bounce/flash for polish
	tween.tween_callback(func():
		if sprite:
			var t = create_tween()
			t.tween_property(sprite, "scale", sprite.scale * 1.06, 0.08)
			t.tween_property(sprite, "modulate:a", 0.95, 0.08)
			t.tween_property(sprite, "scale", sprite.scale, 0.08)
			t.tween_property(sprite, "modulate:a", 1.0, 0.05)
			t.tween_callback(finish_opening)
		else:
			finish_opening()
	)

func finish_opening():
	is_open = true
	is_animating = false
	var scene_root = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if not scene_root:
		return
	var count = loot_items.size()
	if count <= 0:
		return
	var radius = clamp(loot_spawn_radius_base, 16.0, 40.0)
	for i in range(count):
		var angle = (i * TAU) / float(max(1, count))
		var dir = Vector2(cos(angle), sin(angle))
		var target_pos = global_position + loot_spawn_offset + dir * radius
		var start_pos = global_position + Vector2(0, -6)
		var up_pos = start_pos + Vector2(0, -20)
		var pickup: Node = PickupItem.create_pickup_item(loot_items[i], start_pos, 1)
		scene_root.add_child(pickup)
		if pickup is Node2D:
			pickup.z_as_relative = true
			pickup.z_index = 0
			pickup.top_level = false
			(pickup as Node2D).global_position = start_pos
			(pickup as Node2D).modulate.a = 0.0
		if pickup.has_method("set_pickup_delay"):
			pickup.set_pickup_delay(0.6)
		if "auto_pickup" in pickup:
			pickup.auto_pickup = true
		var t = create_tween()
		t.tween_property(pickup, "modulate:a", 1.0, 0.12)
		t.tween_property(pickup, "global_position", up_pos, 0.10)
		t.tween_property(pickup, "global_position", target_pos, 0.18)
	print("Chest spawned ", count, " items at radius ", radius)

func spawn_and_throw_item(item_id: String, direction: Vector2):
	var scene = load("res://scenes/PickupItem.tscn")
	if not scene:
		print("Pickup scene missing for ", item_id)
		return
	
	var pickup = scene.instantiate()
	# Add under the chest's parent so transforms remain consistent with chest scale
	var parent = get_parent() if get_parent() else get_tree().current_scene
	parent.add_child(pickup)
	
	# Compute spawn offset relative to chest's global scale
	var scale_factor = (abs(global_scale.x) + abs(global_scale.y)) * 0.5
	var offset_distance = 8.0 * max(1.0, scale_factor)
	var spawn_pos = global_position + direction.normalized() * offset_distance
	
	if pickup is Node2D:
		pickup.top_level = false
		pickup.z_as_relative = true
		pickup.z_index = 0
		pickup.global_position = spawn_pos
	else:
		pickup.set("global_position", spawn_pos)

	if pickup.has_method("set_item"):
		pickup.set_item(item_id, 1)
	if pickup.has_method("set_pickup_delay"):
		pickup.set_pickup_delay(loot_throw_delay)
	if pickup.has_method("throw_from"):
		var speed = randf_range(loot_throw_speed_min, loot_throw_speed_max) * max(1.0, scale_factor)
		pickup.throw_from(spawn_pos, direction, speed)

	print("Spawned ", item_id, " at ", spawn_pos)

func _on_body_entered(body):
	if body.has_method("add_item_to_inventory"):
		player_near = true

func _on_body_exited(body):
	if body.has_method("add_item_to_inventory"):
		player_near = false

func interact():
	# Player proximity is already checked by the player script,
	# so open as long as we're close enough to interact.
	if not is_open and not is_animating:
		open_chest()
