extends Area2D
class_name ShadowZone

## Drop this node into a scene and size its CollisionShape2D.
## Set `mode` to control whether the line-of-sight shadow works inside it.

enum ZoneMode { ENABLE_SHADOW, DISABLE_SHADOW }

@export var mode: ZoneMode = ZoneMode.DISABLE_SHADOW

func _ready():
	monitoring = true
	monitorable = true
	# Group for quick identification by the LOS system
	if mode == ZoneMode.DISABLE_SHADOW:
		add_to_group("no_shadow_zone")
	else:
		add_to_group("shadow_zone")
