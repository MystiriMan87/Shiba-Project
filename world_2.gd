extends Node2D

@export var debug_spawn_startup_items: bool = false

@export var background_music_path: String = "res://audio/a_dungeon_ambience_loop-79423.mp3"
@export var background_music_volume: float = 0.0
@export var music_autoplay: bool = true
@onready var music_player: AudioStreamPlayer = null

func _ready():
	await get_tree().process_frame
	setup_background_music()
	
	var camera = get_node_or_null("PlayerCamera")
	if camera:
		camera.follow_speed = 0.0
		print("Camera follow speed set to 0 on world_2 load")
	else:
		print("PlayerCamera not found as child of world_2!")
		
	if debug_spawn_startup_items:
		#spawn_pickup_item("iron_sword", Vector2(200, 300))
		spawn_pickup_item("health_potion", Vector2(300, 300), 3)
		#spawn_pickup_item("iron_axe", Vector2(400, 300))
		#spawn_pickup_item("magic_crystal", Vector2(500, 300), 2)
		#spawn_pickup_item("wooden_bow", Vector2(600, 300))
		
		print("Spawned test pickup items")
		
			# Test texture loading
		ItemManager.validate_all_textures()
		
		# Add some items to inventory
		ItemManager.debug_add_test_items()
		
		# Test individual texture loading
		var texture = ItemManager.get_item_texture("health_potion")
		if texture:
			print("Successfully loaded health potion texture!")
		
		# Create a sprite for testing
		var test_sprite = ItemManager.create_item_sprite("coin", Vector2(64, 64))
		add_child(test_sprite)
		test_sprite.position = Vector2(100, 100)

	# Ensure player starts without weapon and give starting consumables
	var item_manager = get_node("/root/ItemManager") if has_node("/root/ItemManager") else null
	if item_manager:
		item_manager.add_item_to_inventory("health_potion", 3)
		item_manager.add_item_to_inventory("dash_flask", 2)

	# Spawn a starting weapon on the floor in the main room (near player)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var spawn_pos = player.global_position + Vector2(120, 40)
		spawn_pickup_item("iron_axe", spawn_pos, 1)

	# Add line-of-sight overlay that follows player
	var los := LineOfSight.new()
	add_child(los)
	los.set_target(player)

func spawn_pickup_item(item_id: String, position: Vector2, quantity: int = 1):
	var pickup = PickupItem.create_pickup_item(item_id, position, quantity)
	add_child(pickup)
	print("Spawned ", item_id, " x", quantity, " at ", position)

func _on_enemy_died(enemy_position: Vector2):
	# Random chance to drop an item
	if randf() < 0.3:  # 30% drop rate
		var possible_items = ["health_potion", "magic_crystal", "iron_sword"]
		var random_item = possible_items[randi() % possible_items.size()]
		var random_quantity = 1
		
		# Sometimes drop more consumables
		if random_item in ["health_potion", "magic_crystal"]:
			random_quantity = randi_range(1, 3)
		
		spawn_pickup_item(random_item, enemy_position, random_quantity)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				# Spawn item at mouse position
				var mouse_pos = get_global_mouse_position()
				spawn_pickup_item("health_potion", mouse_pos)
			KEY_2:
				# Spawn weapon at mouse position
				var mouse_pos = get_global_mouse_position()
				spawn_pickup_item("iron_sword", mouse_pos)
			KEY_3:
				# Debug print inventory
				var item_manager = get_node("/root/ItemManager")
				if item_manager:
					item_manager.debug_print_inventory()

# Function to test if pickup system is working
func test_pickup_system():
	print("=== PICKUP SYSTEM TEST ===")
	
	# Check if ItemManager exists
	var item_manager = get_node("/root/ItemManager")
	if item_manager:
		print("✓ ItemManager found")
		print("Available items: ", item_manager.get_all_item_ids())
	else:
		print("✗ ItemManager not found")
	
	# Check if player exists and has pickup system
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("✓ Player found")
		if player.has_node("PickupArea"):
			print("✓ Player has PickupArea")
			var pickup_area = player.get_node("PickupArea")
			print("  - Pickup area collision_mask: ", pickup_area.collision_mask)
			print("  - Pickup area collision_layer: ", pickup_area.collision_layer)
		else:
			print("✗ Player missing PickupArea")
	else:
		print("✗ Player not found")
	
	print("==========================")
	
	
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
