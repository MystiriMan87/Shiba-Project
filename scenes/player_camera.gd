extends Camera2D

@export var follow_speed = 0.0
@export var lookahead_distance = 50.0 
@export var lookahead_smoothing = 3.0 
@export var dead_zone_size = 20.0 

@export var shake_intensity = 0.0
@export var shake_duration = 0.0
var shake_timer = 0.0
var shake_offset = Vector2.ZERO

var player = null
var target_position = Vector2.ZERO
var last_player_position = Vector2.ZERO

var crt_default_vignette_amount: float = 0.5
var crt_default_vignette_intensity: float = 0.35

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			print("Warning: No player found for camera")
			return
	
	global_position = player.global_position
	last_player_position = player.global_position
	target_position = player.global_position
	
	make_current()

	## Attach CRT overlay if not already present
	#if not has_node("CRT"):
		#var crt = preload("res://addons/crt/crt.gd").new()
		#crt.name = "CRT"
		#add_child(crt)
		## Tasteful defaults: milder warp and vignette, subtle scanlines
		#crt.layer = 128
		## Weaker barrel distortion for a subtle fisheye look
		#crt.warp_amount = 0.15
		#crt.vignette_amount = crt_default_vignette_amount
		#crt.vignette_intensity = crt_default_vignette_intensity
		## Tone down image-distorting effects to avoid UI/enemy sprite wobble
		#crt.scan_line_amount = 0.15
		#crt.interference_amount = 0.0
		#crt.grille_amount = 0.02
		#crt.aberation_amount = 0.03
		#crt.pixel_strength = -0.8
		#crt.effect_mix = 0.35
#
	## Add subtle curved edges mask (rounded corners)
	#if not has_node("CornerMask"):
		#var c = ColorRect.new()
		#c.name = "CornerMask"
		#c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		#c.top_level = true
		#c.z_index = 90
		#c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		#c.color = Color(0, 0, 0, 0) # color controlled by shader
		#add_child(c)
		#var mat := ShaderMaterial.new()
		#mat.shader = Shader.new()
		#mat.shader.code = """
			#shader_type canvas_item;
			#uniform float corner_radius = 0.08; // in UV coords (~0..0.2 recommended)
			#uniform float edge_softness = 0.025; // feather width
			#void fragment(){
				#vec2 uv = UV;
				#// Signed distance to a rounded rectangle covering the screen with given corner radius
				#vec2 p = uv - vec2(0.5);
				#vec2 q = abs(p) - (vec2(0.5) - vec2(corner_radius));
				#float sd = length(max(q, vec2(0.0))) - corner_radius;
				#float alpha = smoothstep(0.0, edge_softness, sd);
				#COLOR = vec4(0.0, 0.0, 0.0, alpha);
			#}
		#"""
		#c.material = mat
#
	#else:
		## If CRT already exists, capture its defaults for pulsing
		#var crt = get_node("CRT")
		#crt.layer = 128
		#crt.warp_amount = 0.15
		#crt_default_vignette_amount = crt.vignette_amount
		#crt_default_vignette_intensity = crt.vignette_intensity

func _process(delta):
	print("Current follow_speed: ", follow_speed)
	if not player:
		return
	
	if shake_timer > 0:
		shake_timer -= delta
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		shake_offset = Vector2.ZERO
	
	var player_velocity = (player.global_position - last_player_position) / delta
	last_player_position = player.global_position
	
	var lookahead_offset = Vector2.ZERO
	if player_velocity.length() > 10: 
		lookahead_offset = player_velocity.normalized() * lookahead_distance
		lookahead_offset = lookahead_offset.lerp(Vector2.ZERO, 1.0 / lookahead_smoothing)
	
	target_position = player.global_position + lookahead_offset
	
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target > dead_zone_size:
		global_position = global_position.lerp(target_position, follow_speed * delta)
	
	global_position += shake_offset



func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

#func pulse_vignette(amount_delta: float = 0.4, intensity_delta: float = 0.2, duration: float = 0.2):
	#var crt = get_node_or_null("CRT")
	#if not crt:
		#return
	## Push up values immediately, then tween back to defaults
	#crt.vignette_amount = crt.vignette_amount + amount_delta
	#crt.vignette_intensity = crt.vignette_intensity + intensity_delta
	#var t = create_tween()
	#t.tween_interval(duration)
	#t.tween_callback(func():
		#if is_instance_valid(crt):
			#crt.vignette_amount = crt_default_vignette_amount
			#crt.vignette_intensity = crt_default_vignette_intensity
	#)

func snap_to_player():
	if player:
		global_position = player.global_position
		target_position = player.global_position

func set_limits(left: int, top: int, right: int, bottom: int):
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom

func zoom_to(target_zoom: Vector2, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(self, "zoom", target_zoom, duration)
	tween.tween_callback(func(): print("Zoom complete"))

func get_camera_bounds() -> Rect2:
	var screen_size = get_viewport_rect().size / zoom
	var top_left = global_position - screen_size / 2
	return Rect2(top_left, screen_size)
