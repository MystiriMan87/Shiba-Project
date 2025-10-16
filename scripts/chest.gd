extends StaticBody2D
class_name Chest

@export var is_locked: bool = true
@export var key_type: String = "wooden"  # wooden, iron, golden
@export var loot_items: Array[String] = ["health_potion", "coin"]
@export var loot_spawn_offset: Vector2 = Vector2(0, 8)  
@export var loot_spawn_radius_base: float = 1.0 
@export var loot_pop_height: float = 5.0
@export var loot_animation_duration: float = 0.25  
@export var can_reclose: bool = false 

var is_open: bool = false
var player_near: bool = false
var is_animating: bool = false

@onready var sprite = $Sprite2D
@onready var area = $Area2D
@onready var animation_player = $AnimationPlayer

func _ready():
	add_to_group("chests")
	
	# Setup area if it doesn't exist
	if not area:
		area = Area2D.new()
		area.name = "Area2D"
		add_child(area)
		var collision = CollisionShape2D.new()
		area.add_child(collision)
		var shape = CircleShape2D.new()
		shape.radius = 40
		collision.shape = shape
		area.collision_layer = 8
		area.collision_mask = 0
	
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited)
	
	# Setup sprite if it doesn't exist
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Setup animation player if it doesn't exist
	if not animation_player:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
		print("⚠ Warning: AnimationPlayer not found. Chest needs 'open' and 'close' animations!")
	
	# Connect to animation finished signal
	if animation_player and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	
	# Set initial state
	if is_open:
		# If chest starts open, play the open animation instantly
		if animation_player and animation_player.has_animation("open"):
			animation_player.play("open")
			animation_player.seek(999, true)  # Jump to end of animation
	else:
		# Start in closed state
		if animation_player and animation_player.has_animation("close"):
			animation_player.play("close")
			animation_player.seek(999, true)  # Jump to end of animation

func interact():
	if is_animating:
		return  # Don't allow interaction while animating
	
	if not is_open:
		# Try to open the chest
		if is_locked:
			if try_unlock():
				open_chest()
			else:
				print("Chest is locked! Need ", key_type, " key.")
				show_locked_message()
		else:
			open_chest()
	else:
		# Chest is already open
		if can_reclose:
			close_chest()
		else:
			print("Chest is already open")

func try_unlock() -> bool:
	var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		print("ItemManager not found!")
		return false
	
	var key_id = key_type + "_key"
	if item_manager.has_item(key_id) > 0:
		item_manager.remove_item_from_inventory(key_id, 1)
		is_locked = false
		print("Unlocked chest with ", key_id)
		show_unlock_message()
		return true
	
	return false

func open_chest():
	if not animation_player:
		print("⚠ No AnimationPlayer found!")
		finish_opening()
		return
	
	if not animation_player.has_animation("open"):
		print("⚠ 'open' animation not found!")
		finish_opening()
		return
	
	is_animating = true
	animation_player.play("open")
	print("Playing chest open animation")
	
	# Notify quest system
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		quest_manager.on_chest_opened()

func close_chest():
	if not animation_player:
		print("⚠ No AnimationPlayer found!")
		is_open = false
		return
	
	if not animation_player.has_animation("close"):
		print("⚠ 'close' animation not found!")
		is_open = false
		return
	
	is_animating = true
	animation_player.play("close")
	print("Playing chest close animation")

func _on_animation_finished(anim_name: String):
	is_animating = false
	
	if anim_name == "open":
		finish_opening()
	elif anim_name == "close":
		is_open = false
		print("Chest closed")

func finish_opening():
	is_open = true
	print("Chest opened! Spawning loot...")
	spawn_loot()

func spawn_loot():
	var scene_root = get_tree().current_scene if get_tree() and get_tree().current_scene else get_parent()
	if not scene_root:
		print("⚠ Could not find scene root to spawn loot")
		return
	
	var count = loot_items.size()
	if count <= 0:
		print("No loot items configured for this chest")
		return
	
	var radius = loot_spawn_radius_base
	
	for i in range(count):
		# Calculate position in a circle around the chest
		var angle = (i * TAU) / float(max(1, count))
		var dir = Vector2(cos(angle), sin(angle))
		
		# Start position (inside/at chest)
		var start_pos = global_position + Vector2(0, -8)
		
		# Arc peak (items jump up)
		var up_pos = start_pos + Vector2(0, -loot_pop_height)
		
		# Final landing position (close to chest)
		var target_pos = global_position + loot_spawn_offset + dir * radius
		
		# Create the pickup item
		var pickup: Node = PickupItem.create_pickup_item(loot_items[i], start_pos, 1)
		if not pickup:
			print("⚠ Failed to create pickup for: ", loot_items[i])
			continue
		
		scene_root.add_child(pickup)
		
		# Setup pickup properties
		if pickup is Node2D:
			pickup.z_as_relative = true
			pickup.z_index = 0
			pickup.top_level = false
			(pickup as Node2D).global_position = start_pos
			(pickup as Node2D).modulate.a = 0.0
		
		if pickup.has_method("set_pickup_delay"):
			pickup.set_pickup_delay(0.4)  # Reduced from 0.6
		
		if "auto_pickup" in pickup:
			pickup.auto_pickup = true
		
		# Animate the item popping out with a nice arc
		var t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUAD)
		
		# Fade in quickly
		t.tween_property(pickup, "modulate:a", 1.0, 0.08)
		
		# Jump up
		t.parallel().tween_property(pickup, "global_position", up_pos, loot_animation_duration * 0.4)
		
		# Fall to landing spot
		t.tween_property(pickup, "global_position", target_pos, loot_animation_duration * 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	print("Spawned ", count, " items from chest")

func show_locked_message():
	if sprite:
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.1)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func show_unlock_message():
	if sprite:
		var t = create_tween()
		t.tween_property(sprite, "scale", sprite.scale * 1.1, 0.1)
		t.tween_property(sprite, "scale", sprite.scale, 0.1)

func _on_body_entered(body):
	if body.has_method("add_item_to_inventory"):
		player_near = true
		print("Player near chest")

func _on_body_exited(body):
	if body.has_method("add_item_to_inventory"):
		player_near = false
		print("Player left chest")
