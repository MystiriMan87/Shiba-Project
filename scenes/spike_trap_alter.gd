extends Area2D

@export var linger_time: float = 1.5 
@export var rearm_time: float = 0.4  
@export var damage_fraction: float = 0.5  # 50% of current HP
@onready var ap: AnimationPlayer = $AnimationPlayer
@onready var rearm_timer: Timer = $RearmTimer
@onready var trigger_shape: CollisionShape2D = $CollisionShape2D
var armed := true

func _ready() -> void:
	monitoring = true
	if rearm_timer:
		rearm_timer.one_shot = true
		rearm_timer.wait_time = max(0.0, linger_time)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if ap and ap.has_animation("idle"):
		ap.play("idle")
	# Ensure trigger off while idle
	if trigger_shape:
		trigger_shape.disabled = true

func _on_body_entered(body: Node) -> void:
	if not armed or not body.is_in_group("player"):
		return
	armed = false
	# Play stab visual
	if ap and ap.has_animation("stab"):
		ap.play("stab")
	# Apply damage once
	_apply_damage(body)
	# Keep spikes extended (visual) for linger_time, then retract and start cooldown
	if rearm_timer:
		rearm_timer.wait_time = max(0.0, linger_time)
		rearm_timer.start()
		await rearm_timer.timeout
		# retract (idle)
		if ap and ap.has_animation("idle"):
			ap.play("idle")
		if rearm_time > 0.0:
			await get_tree().create_timer(rearm_time).timeout
	armed = true

func _apply_damage(player: Node) -> void:
	var hp := 0
	if player.has_method("get_current_health"):
		hp = int(player.get_current_health())
	elif player.has_method("get_health"):
		hp = int(player.get_health())
	elif "current_health" in player:
		hp = int(player.current_health)
	elif "health" in player:
		hp = int(player.health)
	var dmg: int = max(1, int(ceil(float(hp) * clamp(damage_fraction, 0.05, 1.0))))
	if player.has_method("take_damage"):
		player.take_damage(dmg, self)
	elif "health" in player:
		player.health = max(0, int(player.health) - dmg)
