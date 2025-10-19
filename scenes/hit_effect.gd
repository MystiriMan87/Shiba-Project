extends Node2D

func _ready():
	if has_node("Timer"):
		$Timer.timeout.connect(func(): queue_free())
	
	if has_node("GPUParticles2D"):
		var particles = get_node("GPUParticles2D")
		particles.emitting = true
		particles.one_shot = true
