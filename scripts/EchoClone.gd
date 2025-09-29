extends Area2D
class_name EchoClone

@export var lifetime: float = 1.0
@export var move_speed: float = 900.0
@export var damage: int = 1
@export var alpha: float = 0.7
@export var burst_radius: float = 48.0
@export var burst_damage: int = 2
@export var damage_on_move: bool = false
@export var move_hit_radius: float = 12.0

var path: Array[Vector2] = []
var idx: int = 0
var target: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = null
@onready var shape: CollisionShape2D = null
@onready var trail: CPUParticles2D = null

func _ready():
	set_physics_process(true)
	monitoring = true
	collision_layer = 0
	collision_mask = 4
	# subtle shimmer similar to dash
	trail = CPUParticles2D.new()
	trail.one_shot = true
	trail.emitting = false
	trail.lifetime = 0.10
	trail.amount = 20
	trail.initial_velocity_min = 20
	trail.initial_velocity_max = 40
	trail.spread = 20
	trail.gravity = Vector2.ZERO
	trail.scale_amount_min = 0.25
	trail.scale_amount_max = 0.5
	trail.color = Color(0.7, 0.9, 1.0, 0.6)
	trail.local_coords = false
	add_child(trail)

func setup(texture: Texture2D, scale_v: Vector2, start_pos: Vector2, recorded_path: Array[Vector2], hframes: int = 1, vframes: int = 1, frame_idx: int = 0, flip_h: bool = false, flip_v: bool = false, centered: bool = true):
	path = recorded_path.duplicate()
	idx = 0
	global_position = start_pos
	if not sprite:
		sprite = Sprite2D.new()
		sprite.modulate = Color(1, 1, 1, alpha)
		add_child(sprite)
	if not shape:
		shape = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = 10
		shape.shape = c
		add_child(shape)
	sprite.texture = texture
	sprite.scale = scale_v
	sprite.hframes = max(1, hframes)
	sprite.vframes = max(1, vframes)
	sprite.frame = max(0, frame_idx)
	sprite.flip_h = flip_h
	sprite.flip_v = flip_v
	sprite.centered = centered
	if path.size() > 0:
		target = path[0]
	else:
		target = start_pos

func _physics_process(delta):
	if lifetime > 0:
		lifetime -= delta
	else:
		queue_free()
		return
	if path.is_empty():
		return
	var to_target = target - global_position
	var step = move_speed * delta
	if to_target.length() <= step:
		global_position = target
		idx += 1
		if idx >= path.size():
			path.clear()
			return
		target = path[idx]
	else:
		global_position += to_target.normalized() * step

	if damage_on_move:
		_apply_move_damage()

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
			c.take_damage(damage)

func do_burst():
	# Visual pop
	if sprite:
		var t = create_tween()
		t.tween_property(sprite, "scale", sprite.scale * 1.25, 0.08)
		t.tween_property(sprite, "modulate", Color(1, 1, 1, 0.15), 0.12)
		# quick ring effect
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

	# Damage all enemies in a small radius via physics query to be robust
	var space := get_world_2d().direct_space_state
	if space:
		var circle := CircleShape2D.new()
		circle.radius = burst_radius
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
				c.take_damage(burst_damage)
	queue_free()


