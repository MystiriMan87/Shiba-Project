extends Node2D

@export var spawn_on_enter: bool = true
@export var despawn_on_exit: bool = true
@export var lock_until_cleared: bool = false

var enemy_data: Array = []
var cleared: bool = false
var active: bool = false

func _ready():
	if spawn_on_enter:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy_data.append({"scene": enemy.scene_file_path, "pos": enemy.position})
			enemy.queue_free()
			
func on_room_entered():
	if spawn_on_enter and not active:
		for data in enemy_data:
			if ResourceLoader.exists(data.scene):
				var enemy = load(data.scene).instantiate()
				enemy.position = data.pos
				add_child(enemy)
				if enemy.has_signal("died"):
					enemy.died.connect(_check_cleared)
			if lock_until_cleared:
				_toggle_doors(false)
			active = true
			
func on_room_exited():
	if despawn_on_exit:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_ancestor_of(enemy):
				enemy.process_mode = Node.PROCESS_MODE_DISABLED
		active = false

func _check_cleared():
	await get_tree().create_timer(0.1).timeout
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_ancestor_of(enemy):
			return
	if not cleared:
		cleared = true
		if lock_until_cleared:
			_toggle_doors(true)

func _toggle_doors(enabled: bool):
	for door_name in ["DoorNorth", "DoorSouth", "DoorEast", "DoorWest"]:
		var door = get_node_or_null(door_name)
		if door:
			door.set_deferred("monitoring", enabled)
