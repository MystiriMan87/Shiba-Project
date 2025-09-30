extends Node
class_name ParticleEffects

static func spawn_damage_number(scene_root: Node, position: Vector2, amount: int, color: Color = Color(1, 0.85, 0.2)):
	if not scene_root:
		return
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0,0,0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.top_level = false
	label.global_position = position + Vector2(-6, -14)
	label.z_index = 300
	# Add to current scene root; ensure it renders above world but below UI
	if scene_root and scene_root.has_method("add_child"):
		scene_root.add_child(label)
	var t = scene_root.create_tween()
	t.tween_property(label, "global_position", label.global_position + Vector2(0, -22), 0.5)
	t.tween_property(label, "modulate:a", 0.0, 0.5)
	t.tween_callback(func(): if is_instance_valid(label): label.queue_free())
#
#var hit_effect_scene = preload("res://effects/HitEffect.tscn")
#var death_effect_scene = preload("res://effects/DeathEffect.tscn") 
#var damage_effect_scene = preload("res://effects/DamageEffect.tscn")
#
#const HIT_PARTICLES = {
	#"amount": 20,
	#"lifetime": 1.0,
	#"emission_rate": 100,
	#"spread": 45.0,
	#"initial_velocity_min": 50.0,
	#"initial_velocity_max": 150.0,
	#"color_start": Color.YELLOW,
	#"color_end": Color.ORANGE,
	#"scale_start": 1.0,s
	#"scale_end": 0.0
#}
#
#const DAMAGE_PARTICLES = {
	#"amount": 15,
	#"lifetime": 0.8,
	#"emission_rate": 80,
	#"spread": 60.0,
	#"initial_velocity_min": 30.0,
	#"initial_velocity_max": 100.0,
	#"color_start": Color.RED,
	#"color_end": Color.DARK_RED,
	#"scale_start": 0.8,
	#"scale_end": 0.0
#}
#
#const DEATH_PARTICLES = {
	#"amount": 50,
	#"lifetime": 2.0,
	#"emission_rate": 200,
	#"spread": 360.0,
	#"initial_velocity_min": 80.0,
	#"initial_velocity_max": 200.0,
	#"color_start": Color.WHITE,
	#"color_end": Color.GRAY,
	#"scale_start": 1.2,
	#"scale_end": 0.0
#}
#
## Create hit effect when player attacks enemy
#func create_hit_effect(position: Vector2, direction: Vector2 = Vector2.ZERO):
	#var particles = create_particle_effect(HIT_PARTICLES, position, direction)
	#
	## Add some sparks flying in the hit direction
	#if direction != Vector2.ZERO:
		#create_spark_effect(position, direction)
	#
	#print("Hit effect created at: ", position)
#
## Create damage effect when enemy attacks player
#func create_damage_effect(position: Vector2, direction: Vector2 = Vector2.ZERO):
	#var particles = create_particle_effect(DAMAGE_PARTICLES, position, direction)
	#
	## Add some blood-like splatter
	#create_splatter_effect(position, direction)
	#
	#print("Damage effect created at: ", position)
#
## Create death effect when enemy dies
#func create_death_effect(position: Vector2):
	#var particles = create_particle_effect(DEATH_PARTICLES, position)
	#
	## Add explosion-like effect
	#create_explosion_effect(position)
	#
	#print("Death effect created at: ", position)
#
## Core function to create particle effects
#func create_particle_effect(config: Dictionary, position: Vector2, direction: Vector2 = Vector2.ZERO) -> GPUParticles2D:
	#var particles = GPUParticles2D.new()
	#
	## Get the current scene to add particles to
	#var current_scene = get_tree().current_scene
	#if not current_scene:
		#print("Warning: No current scene found for particles")
		#return particles
	#
	#current_scene.add_child(particles)
	#particles.global_position = position
	#
	## Configure particle system
	#particles.emitting = true
	#particles.amount = config.amount
	#particles.lifetime = config.lifetime
	#particles.one_shot = true
	#particles.explosiveness = 1.0
	#
	## Create and configure process material
	#var material = ParticleProcessMaterial.new()
	#
	## Emission
	#material.emission = ParticleProcessMaterial.EMISSION_POINT
	#
	## Direction and spread
	#if direction != Vector2.ZERO:
		#material.direction = Vector3(direction.x, direction.y, 0.0)
	#else:
		#material.direction = Vector3(0, -1, 0)  # Default upward
	#
	#material.spread = config.spread
	#material.initial_velocity_min = config.initial_velocity_min
	#material.initial_velocity_max = config.initial_velocity_max
	#
	## Gravity and physics
	#material.gravity = Vector3(0, 98, 0)  # Downward gravity
	#material.linear_accel_min = -20.0
	#material.linear_accel_max = -40.0
	#
	## Color
	#var gradient = Gradient.new()
	#gradient.add_point(0.0, config.color_start)
	#gradient.add_point(1.0, config.color_end)
	#material.color_ramp = gradient
	#
	## Scale
	#var scale_curve = Curve.new()
	#scale_curve.add_point(0.0, config.scale_start)
	#scale_curve.add_point(1.0, config.scale_end)
	#material.scale_curve = scale_curve
	#
	## Alpha fade
	#var alpha_curve = Curve.new()
	#alpha_curve.add_point(0.0, 1.0)
	#alpha_curve.add_point(0.7, 0.8)
	#alpha_curve.add_point(1.0, 0.0)
	#material.alpha_curve = alpha_curve
	#
	#particles.process_material = material
	#
	## Auto-remove after lifetime + buffer
	#var timer = Timer.new()
	#current_scene.add_child(timer)
	#timer.wait_time = config.lifetime + 1.0
	#timer.one_shot = true
	#timer.timeout.connect(func(): 
		#if is_instance_valid(particles):
			#particles.queue_free()
		#timer.queue_free()
	#)
	#timer.start()
	#
	#return particles
#
## Create spark effect for weapon hits
#func create_spark_effect(position: Vector2, direction: Vector2):
	#var sparks = GPUParticles2D.new()
	#var current_scene = get_tree().current_scene
	#current_scene.add_child(sparks)
	#sparks.global_position = position
	#
	#sparks.emitting = true
	#sparks.amount = 10
	#sparks.lifetime = 0.5
	#sparks.one_shot = true
	#sparks.explosiveness = 1.0
	#
	#var material = ParticleProcessMaterial.new()
	#material.direction = Vector3(direction.x, direction.y, 0.0)
	#material.spread = 25.0
	#material.initial_velocity_min = 80.0
	#material.initial_velocity_max = 150.0
	#material.gravity = Vector3(0, 200, 0)
	#
	## Spark colors
	#var gradient = Gradient.new()
	#gradient.add_point(0.0, Color.WHITE)
	#gradient.add_point(0.3, Color.YELLOW)
	#gradient.add_point(1.0, Color.ORANGE)
	#material.color_ramp = gradient
	#
	## Small scale
	#material.scale_min = 0.3
	#material.scale_max = 0.8
	#
	#sparks.process_material = material
	#
	## Auto-remove
	#var timer = Timer.new()
	#current_scene.add_child(timer)
	#timer.wait_time = 1.5
	#timer.one_shot = true
	#timer.timeout.connect(func(): 
		#if is_instance_valid(sparks):
			#sparks.queue_free()
		#timer.queue_free()
	#)
	#timer.start()
#
## Create splatter effect for damage
#func create_splatter_effect(position: Vector2, direction: Vector2):
	#var splatter = GPUParticles2D.new()
	#var current_scene = get_tree().current_scene
	#current_scene.add_child(splatter)
	#splatter.global_position = position
	#
	#splatter.emitting = true
	#splatter.amount = 8
	#splatter.lifetime = 1.2
	#splatter.one_shot = true
	#splatter.explosiveness = 0.8
	#
	#var material = ParticleProcessMaterial.new()
	#material.direction = Vector3(-direction.x, -direction.y, 0.0)  # Opposite to hit direction
	#material.spread = 40.0
	#material.initial_velocity_min = 40.0
	#material.initial_velocity_max = 80.0
	#material.gravity = Vector3(0, 150, 0)
	#
	## Blood-like colors
	#var gradient = Gradient.new()
	#gradient.add_point(0.0, Color.RED)
	#gradient.add_point(0.5, Color.DARK_RED)
	#gradient.add_point(1.0, Color.MAROON)
	#material.color_ramp = gradient
	#
	#material.scale_min = 0.5
	#material.scale_max = 1.5
	#
	#splatter.process_material = material
	#
	## Auto-remove
	#var timer = Timer.new()
	#current_scene.add_child(timer)
	#timer.wait_time = 2.2
	#timer.one_shot = true
	#timer.timeout.connect(func(): 
		#if is_instance_valid(splatter):
			#splatter.queue_free()
		#timer.queue_free()
	#)
	#timer.start()
#
## Create explosion effect for death
#func create_explosion_effect(position: Vector2):
	#var explosion = GPUParticles2D.new()
	#var current_scene = get_tree().current_scene
	#current_scene.add_child(explosion)
	#explosion.global_position = position
	#
	#explosion.emitting = true
	#explosion.amount = 30
	#explosion.lifetime = 1.5
	#explosion.one_shot = true
	#explosion.explosiveness = 1.0
	#
	#var material = ParticleProcessMaterial.new()
	#material.direction = Vector3(0, -1, 0)
	#material.spread = 360.0  # Full circle
	#material.initial_velocity_min = 60.0
	#material.initial_velocity_max = 120.0
	#material.gravity = Vector3(0, 50, 0)  # Light gravity
	#
	## Explosion colors
	#var gradient = Gradient.new()
	#gradient.add_point(0.0, Color.WHITE)
	#gradient.add_point(0.2, Color.YELLOW)
	#gradient.add_point(0.6, Color.ORANGE)
	#gradient.add_point(1.0, Color.RED)
	#material.color_ramp = gradient
	#
	## Scale animation
	#var scale_curve = Curve.new()
	#scale_curve.add_point(0.0, 1.5)
	#scale_curve.add_point(0.3, 1.0)
	#scale_curve.add_point(1.0, 0.0)
	#material.scale_curve = scale_curve
	#
	#explosion.process_material = material
	#
	## Auto-remove
	#var timer = Timer.new()
	#current_scene.add_child(timer)
	#timer.wait_time = 2.5
	#timer.one_shot = true
	#timer.timeout.connect(func(): 
		#if is_instance_valid(explosion):
			#explosion.queue_free()
		#timer.queue_free()
	#)
	#timer.start()
#
## Screen shake for impact effects (call this from camera script)
#func request_camera_shake(intensity: float, duration: float):
	#var camera = get_viewport().get_camera_2d()
	#if camera and camera.has_method("shake_camera"):
		#camera.shake_camera(intensity, duration)
#
## Utility function to get effect position between two objects
#func get_impact_position(attacker_pos: Vector2, target_pos: Vector2, offset_ratio: float = 0.7) -> Vector2:
	#return attacker_pos.lerp(target_pos, offset_ratio)
#
## Function to create screen flash effect
#func create_screen_flash(color: Color = Color.WHITE, duration: float = 0.1):
	#var flash = ColorRect.new()
	#var current_scene = get_tree().current_scene
	#current_scene.add_child(flash)
	#
	## Cover entire screen
	#flash.color = color
	#flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#flash.anchors_preset = Control.PRESET_FULL_RECT
	#
	## Fade out
	#var tween = create_tween()
	#tween.tween_property(flash, "modulate:a", 0.0, duration)
	#tween.tween_callback(func(): flash.queue_free())
