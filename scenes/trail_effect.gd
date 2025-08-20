extends Line2D

@export var max_trail_points = 10
@export var trail_fade_speed = 5.0
@export var trail_width = 3.0
@export var trail_color = Color.CYAN

var trail_positions = []
var is_trailing = false

func _ready():
	# Set up trail appearance
	width = trail_width
	default_color = trail_color
	texture_mode = Line2D.LINE_TEXTURE_STRETCH

func start_trail():
	is_trailing = true
	trail_positions.clear()
	clear_points()
	visible = true

func stop_trail():
	is_trailing = false
	# Fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): 
		visible = false
		modulate.a = 1.0
	)

func _process(delta):
	if not is_trailing:
		return
	
	# Add current position to trail
	var current_pos = global_position
	trail_positions.append(current_pos)
	
	# Limit trail length
	if trail_positions.size() > max_trail_points:
		trail_positions.pop_front()
	
	# Update line points
	clear_points()
	for pos in trail_positions:
		add_point(to_local(pos))

func update_trail_from_sword(sword_global_pos: Vector2):
	"""Call this from sword script to update trail position"""
	if is_trailing:
		trail_positions.append(sword_global_pos)
		
		if trail_positions.size() > max_trail_points:
			trail_positions.pop_front()
		
		# Update line points
		clear_points()
		for pos in trail_positions:
			add_point(to_local(pos))
