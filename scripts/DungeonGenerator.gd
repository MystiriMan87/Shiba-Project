# DungeonGenerator.gd
extends Node2D

@export var room_scenes: Array[PackedScene] = []
@export var start_room: PackedScene
@export var boss_room: PackedScene
@export var num_rooms: int = 10
@export var spacing: int = 100
@export var auto_size: bool = true
@export var default_size: Vector2 = Vector2(640, 360)

signal dungeon_generated
signal room_entered(room)

var rooms: Array = []
var current_room = null
var player = null

enum Dir { NORTH, SOUTH, EAST, WEST }

class Room:
	var scene: PackedScene
	var grid_pos: Vector2i
	var pos: Vector2
	var doors: Dictionary = {}
	var node: Node2D
	var size: Vector2
	var is_start: bool = false
	var is_boss: bool = false
	
	func _init(s: PackedScene, g: Vector2i):
		scene = s
		grid_pos = g
		for d in [Dir.NORTH, Dir.SOUTH, Dir.EAST, Dir.WEST]:
			doors[d] = false

func _ready():
	generate_dungeon()

func generate_dungeon():
	rooms.clear()
	for child in get_children():
		child.queue_free()
	
	var grid = {}
	var positions = []
	var pos = Vector2i.ZERO
	
	var start = Room.new(start_room, pos)
	start.is_start = true
	rooms.append(start)
	grid[pos] = start
	positions.append(pos)
	
	for i in num_rooms - 1:
		var placed = false
		var attempts = 0
		
		while not placed and attempts < 100:
			attempts += 1
			var dir = randi() % 4
			var new_pos = pos
			
			match dir:
				Dir.NORTH: new_pos += Vector2i(0, -1)
				Dir.SOUTH: new_pos += Vector2i(0, 1)
				Dir.EAST: new_pos += Vector2i(1, 0)
				Dir.WEST: new_pos += Vector2i(-1, 0)
			
			if not grid.has(new_pos):
				var scene = boss_room if (i == num_rooms - 2 and boss_room) else room_scenes[randi() % room_scenes.size()]
				var room = Room.new(scene, new_pos)
				room.is_boss = (i == num_rooms - 2 and boss_room)
				
				grid[pos].doors[dir] = true
				room.doors[_opposite(dir)] = true
				
				rooms.append(room)
				grid[new_pos] = room
				positions.append(new_pos)
				pos = new_pos
				placed = true
		
		if not placed:
			pos = positions[randi() % positions.size()]
	
	_instantiate()
	_position_rooms()
	_create_doors()
	dungeon_generated.emit()

func _instantiate():
	for room in rooms:
		var instance = room.scene.instantiate()
		instance.name = "Room_" + str(room.grid_pos)
		add_child(instance)
		room.node = instance
		room.size = _detect_size(instance) if auto_size else default_size

func _detect_size(node: Node2D) -> Vector2:
	var tilemap = _find_tilemap(node)
	if tilemap:
		var rect = tilemap.get_used_rect()
		return Vector2(rect.size * tilemap.tile_set.tile_size)
	return default_size

func _find_tilemap(node: Node) -> TileMap:
	if node is TileMap:
		return node
	for child in node.get_children():
		var result = _find_tilemap(child)
		if result:
			return result
	return null

func _position_rooms():
	for room in rooms:
		var offset = Vector2.ZERO
		for other in rooms:
			if other.grid_pos.x < room.grid_pos.x:
				offset.x += other.size.x + spacing
			if other.grid_pos.y < room.grid_pos.y and other.grid_pos.x == room.grid_pos.x:
				offset.y += other.size.y + spacing
		room.pos = offset
		room.node.position = offset
		
		if room.is_start:
			current_room = room
			_spawn_player(room)

func _create_doors():
	for room in rooms:
		for dir in room.doors:
			if room.doors[dir]:
				var door_name = ["DoorNorth", "DoorSouth", "DoorEast", "DoorWest"][dir]
				var door = room.node.get_node_or_null(door_name)
				
				if not door:
					door = Area2D.new()
					door.name = door_name
					var col = CollisionShape2D.new()
					var shape = RectangleShape2D.new()
					shape.size = Vector2(80, 80)
					col.shape = shape
					door.add_child(col)
					door.position = _door_pos(room, dir)
					room.node.add_child(door)
				
				if door and not door.body_entered.is_connected(_on_door):
					door.body_entered.connect(_on_door.bind(room, dir))

func _door_pos(room: Room, dir: int) -> Vector2:
	match dir:
		Dir.NORTH: return Vector2(room.size.x / 2, 0)
		Dir.SOUTH: return Vector2(room.size.x / 2, room.size.y)
		Dir.EAST: return Vector2(room.size.x, room.size.y / 2)
		Dir.WEST: return Vector2(0, room.size.y / 2)
	return Vector2.ZERO

func _on_door(body: Node2D, from: Room, dir: int):
	if body.is_in_group("player"):
		var next = _room_at(_adjacent(from.grid_pos, dir))
		if next:
			_transition(next, dir)

func _transition(room: Room, from_dir: int):
	if current_room and current_room.node.has_method("on_room_exited"):
		current_room.node.on_room_exited()
	
	current_room = room
	
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if player:
		var spawn = _spawn_pos(room, from_dir)
		player.global_position = spawn
	
	if room.node.has_method("on_room_entered"):
		room.node.on_room_entered()
	
	room_entered.emit(room.node)

func _spawn_player(room: Room):
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		var marker = room.node.get_node_or_null("PlayerSpawn")
		player.global_position = marker.global_position if marker else room.pos + room.size / 2
		if room.node.has_method("on_room_entered"):
			room.node.on_room_entered()

func _spawn_pos(room: Room, dir: int) -> Vector2:
	var base = room.pos
	var size = room.size
	match dir:
		Dir.NORTH: return base + Vector2(size.x / 2, size.y - 100)
		Dir.SOUTH: return base + Vector2(size.x / 2, 100)
		Dir.EAST: return base + Vector2(100, size.y / 2)
		Dir.WEST: return base + Vector2(size.x - 100, size.y / 2)
	return base + size / 2

func _adjacent(pos: Vector2i, dir: int) -> Vector2i:
	match dir:
		Dir.NORTH: return pos + Vector2i(0, -1)
		Dir.SOUTH: return pos + Vector2i(0, 1)
		Dir.EAST: return pos + Vector2i(1, 0)
		Dir.WEST: return pos + Vector2i(-1, 0)
	return pos

func _room_at(pos: Vector2i) -> Room:
	for room in rooms:
		if room.grid_pos == pos:
			return room
	return null

func _opposite(dir: int) -> int:
	match dir:
		Dir.NORTH: return Dir.SOUTH
		Dir.SOUTH: return Dir.NORTH
		Dir.EAST: return Dir.WEST
		Dir.WEST: return Dir.EAST
	return dir

func regenerate():
	generate_dungeon()
