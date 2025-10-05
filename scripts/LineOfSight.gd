extends Node2D
class_name LineOfSight

@export var rays: int = 256
@export var max_distance: float = 10000.0
@export_flags_2d_physics var los_collision_mask: int = 0x7FFFFFFF
@export var darkness: Color = Color(0, 0, 0, 0.6) : set = set_darkness
@export_range(0.0, 1.0) var darkness_alpha: float = 0.6 : set = set_darkness_alpha
@export var invert_border: float = 6000.0

var target: Node2D = null
@export var ignore_groups: Array[String] = ["enemies", "skeleton", "pickup", "items", "chests"]
@export_flags_2d_physics var ignore_layers: int = 4 | 8
@export var obey_shadow_zones: bool = false
@export var require_shadow_zone: bool = false
@export var hide_groups: Array[String] = ["enemies", "skeleton", "pickup", "items"]
@export var exempt_light_groups: Array[String] = ["lights", "chests"]

@onready var mask: Polygon2D = Polygon2D.new()

func _ready():
	# Overlay drawn over the world; transparent inside the polygon, dark outside
	add_child(mask)
	mask.invert_enabled = true
	mask.invert_border = invert_border
	_update_mask_color()
	# Render darkness above actors/items but below UI; keep below TileMap layers (negative z)
	mask.z_as_relative = false
	mask.z_index = 500
	set_physics_process(true)

func set_darkness(value: Color) -> void:
	darkness = value
	_update_mask_color()

func set_darkness_alpha(value: float) -> void:
	darkness_alpha = clamp(value, 0.0, 1.0)
	_update_mask_color()

func _update_mask_color() -> void:
	if mask:
		var base = darkness
		mask.color = Color(base.r, base.g, base.b, darkness_alpha)

func set_target(node: Node2D) -> void:
	target = node

func _physics_process(delta: float) -> void:
	if not target:
		# Try to find player automatically
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Node2D:
			target = players[0]
		else:
			return

	# Shadow zone logic
	if obey_shadow_zones:
		# Hard override: any no-shadow zone disables the mask
		if _is_target_in_no_shadow_zone():
			mask.visible = false
			return
		# Optional: only enable when inside a shadow zone
		if require_shadow_zone and not _is_target_in_shadow_zone():
			mask.visible = false
			return
	mask.visible = true

	var origin: Vector2 = target.global_position
	var dss: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not dss:
		return

	var pts: PackedVector2Array = PackedVector2Array()
	pts.resize(rays * 3)
	var idx := 0
	for i in range(rays):
		var base_angle: float = float(i) / float(rays) * TAU
		# Cast three rays per step to reduce gaps at obstacle edges
		var offsets: PackedFloat32Array = PackedFloat32Array([-0.0015, 0.0, 0.0015])
		for off in offsets:
			var ang: float = base_angle + float(off)
			var dir: Vector2 = Vector2(cos(ang), sin(ang))
			var to: Vector2 = origin + dir * max_distance
			var q := PhysicsRayQueryParameters2D.create(origin, to)
			q.collision_mask = los_collision_mask
			q.collide_with_areas = true
			# Exclude the target itself if it is a physics body
			var exclude: Array[RID] = []
			if target is CollisionObject2D:
				exclude.append((target as CollisionObject2D).get_rid())
			q.exclude = exclude
			var hit: Dictionary = dss.intersect_ray(q)
			var p: Vector2 = to
			if hit and hit.has("position"):
				# Skip through ignored colliders (enemies/items), recasting until we hit a wall or nothing
				var current_from: Vector2 = origin
				var safety := 0
				var last_hit: Dictionary = hit
				while last_hit and last_hit.has("position") and safety < 4:
					var collider = last_hit.get("collider")
					var skip: bool = false
					if collider and collider is Node:
						if _node_or_ancestor_in_groups((collider as Node), ignore_groups):
							skip = true
					if not skip and collider is CollisionObject2D:
						if (((collider as CollisionObject2D).collision_layer) & ignore_layers) != 0:
							skip = true
					if skip:
						current_from = last_hit["position"] + dir * 1.5
						# Exclude this collider RID to prevent immediate re-hit
						if collider is CollisionObject2D:
							exclude.append((collider as CollisionObject2D).get_rid())
						var q2 := PhysicsRayQueryParameters2D.create(current_from, to)
						q2.collision_mask = los_collision_mask
						q2.collide_with_areas = true
						q2.exclude = exclude
						last_hit = dss.intersect_ray(q2)
						if not (last_hit and last_hit.has("position")):
							p = to
							break
						# continue loop to test next collider
						safety += 1
					else:
						# Hit a wall/valid occluder
						p = last_hit["position"]
						break
				if safety == 0 and last_hit and last_hit.has("position"):
					p = last_hit["position"]
			pts[idx] = to_local(p)
			idx += 1

	mask.polygon = pts

	# Toggle visibility of nodes in hide_groups based on LOS polygon
	_update_group_visibility()

func _node_or_ancestor_in_groups(n: Node, groups: Array[String]) -> bool:
	var cur: Node = n
	while cur:
		for g in groups:
			if cur.is_in_group(g):
				return true
		cur = cur.get_parent()
	return false

func _is_target_in_no_shadow_zone() -> bool:
	# Look for overlapping Area2Ds around the target that signal no-shadow zones
	if not target or not (target is Node2D):
		return false
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	var xform := Transform2D(0.0, (target as Node2D).global_position)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = xform
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var res := space.intersect_shape(q, 16)
	for r in res:
		if r.has("collider") and r["collider"] is Area2D:
			var a: Area2D = r["collider"]
			if a.is_in_group("no_shadow_zone"):
				return true
	return false

func _is_target_in_shadow_zone() -> bool:
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	var xform := Transform2D(0.0, (target as Node2D).global_position)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = xform
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var res := space.intersect_shape(q, 16)
	for r in res:
		if r.has("collider") and r["collider"] is Area2D:
			var a: Area2D = r["collider"]
			if a.is_in_group("shadow_zone"):
				return true
	return false

func _get_global_polygon() -> PackedVector2Array:
	var poly := PackedVector2Array()
	poly.resize(mask.polygon.size())
	var xf := mask.get_global_transform()
	for i in range(mask.polygon.size()):
		poly[i] = xf * mask.polygon[i]
	return poly

func _update_group_visibility() -> void:
	if hide_groups.is_empty():
		return
	var poly := _get_global_polygon()
	for g in hide_groups:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node2D and n != target and not (n as Node2D).is_in_group("player"):
				var node2d := n as Node2D
				var inside := Geometry2D.is_point_in_polygon(node2d.global_position, poly)
				if node2d is CanvasItem:
					(node2d as CanvasItem).visible = inside

	# Ensure point lights and their torch sprites stay visible even if outside LOS
	if not exempt_light_groups.is_empty():
		for lg in exempt_light_groups:
			for ln in get_tree().get_nodes_in_group(lg):
				if ln is CanvasItem:
					(ln as CanvasItem).visible = true
