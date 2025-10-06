extends Node2D

func _ready():
	if has_node("Timer"):
		$Timer.timeout.connect(func(): queue_free())
