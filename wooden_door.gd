extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var blocker: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

var is_open := false
var is_animating := false
var player_in_area := false
var last_open_time := 0.0

@export var close_cooldown := 0.25

func _ready():
	if area:
		area.monitoring = true
	
	if sprite:
		sprite.y_sort_enabled = true
	y_sort_enabled = true

func _open() -> void:
	is_animating = true
	anim.play("open")
	await anim.animation_finished
	blocker.disabled = true
	is_open = true
	is_animating = false

func _close() -> void:
	await get_tree().create_timer(0.08).timeout
	if _is_player_overlapping() or (Time.get_ticks_msec() - int(last_open_time * 1000.0)) < int(close_cooldown * 1000.0):
		return
	is_animating = true
	blocker.disabled = false
	anim.play("close")
	await anim.animation_finished
	is_open = false
	is_animating = false

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		if not is_open and not is_animating:
			_open()
			last_open_time = Time.get_ticks_msec() / 1000.0

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		if is_open and not is_animating:
			_close()

func _is_player_overlapping() -> bool:
	if not area:
		return false
	var bodies := area.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player"):
			return true
	return false
