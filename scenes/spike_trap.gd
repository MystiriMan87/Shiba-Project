extends Area2D

@export var linger_time: float = 2.0      
@export var rearm_time: float = 3.0       

@onready var aspr: AnimatedSprite2D = $AnimatedSprite2D
@onready var rearm_timer: Timer = $RearmTimer
var armed: bool = true

func _ready() -> void:
	monitoring = true
	# Ensure timer exists and is configured
	if not rearm_timer:
		rearm_timer = Timer.new()
		rearm_timer.name = "RearmTimer"
		rearm_timer.one_shot = true
		add_child(rearm_timer)
	rearm_timer.wait_time = max(0.0, linger_time)
	if not rearm_timer.timeout.is_connected(_on_RearmTimer_timeout):
		rearm_timer.timeout.connect(_on_RearmTimer_timeout)

	if aspr and "idle" in aspr.sprite_frames.get_animation_names():
		aspr.play("idle")

func _on_body_entered(body: Node) -> void:
	if not armed or not body.is_in_group("player"):
		return

	armed = false
	if aspr and "stab" in aspr.sprite_frames.get_animation_names():
		aspr.play("stab")

	_apply_damage(body)
	# Keep extended for linger_time seconds
	rearm_timer.stop()
	rearm_timer.wait_time = max(0.0, linger_time)
	rearm_timer.start()

func _on_RearmTimer_timeout() -> void:
	# Retract to idle
	if aspr and "idle" in aspr.sprite_frames.get_animation_names():
		aspr.play("idle")

	if rearm_time > 0.0:
		await get_tree().create_timer(rearm_time).timeout

	armed = true

func _apply_damage(player: Node) -> void:
	var hp: int = 0
	if player.has_method("get_current_health"):
		hp = int(player.get_current_health())
	elif player.has_method("get_health"):
		hp = int(player.get_health())
	elif "current_health" in player:
		hp = int(player.current_health)
	elif "health" in player:
		hp = int(player.health)

	# 50% of current HP, rounded up, minimum 1 (pure integer math)
	var dmg: int = max(1, (hp + 1) / 2)

	if player.has_method("take_damage"):
		player.take_damage(dmg, self)
	elif "health" in player:
		player.health = max(0, int(player.health) - dmg)
