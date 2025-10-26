extends Sprite2D

@export var player_path: NodePath
var _player: Node = null
var _max_energy: int = 100
var _cur_energy: int = 100

# Frames for dash bar (0-3, where 0 = full, 3 = empty)
var full_frame: int = 0
var empty_frame: int = 3

func _ready() -> void:
	_player = _get_player()
	_sync_from_player()
	_connect_player_signal()
	
	# Start at full energy
	frame = full_frame
	visible = true

func set_energy(current: int, max_e: int) -> void:
	_cur_energy = clamp(current, 0, max_e)
	_max_energy = max(1, max_e)
	
	# Update frame based on energy percentage
	update_dash_bar()

func update_dash_bar() -> void:
	"""Update dash bar frame based on current energy"""
	if _max_energy <= 0:
		return
	
	# Hide the bar completely when energy is 0
	if _cur_energy <= 0:
		visible = false
		return
	
	# Show the bar when there's energy
	visible = true
	
	# Calculate energy percentage (0.0 = empty, 1.0 = full)
	var energy_ratio: float = float(_cur_energy) / float(_max_energy)
	
	# We have 4 frames total (0, 1, 2, 3)
	# Frame 0 = full energy
	# Frame 3 = almost empty (but not quite)
	
	# Calculate which frame (0-3)
	# Invert ratio so high energy = low frame number
	var frame_index: int = int(round((1.0 - energy_ratio) * 3.0))
	
	frame = clamp(frame_index, 0, 3)
	
	# Debug
	print("Dash Energy: %d/%d (%.0f%%) -> frame: %d, visible: %s" % [_cur_energy, _max_energy, energy_ratio * 100, frame, visible])

func reset_dash_bar() -> void:
	"""Reset to full energy"""
	frame = full_frame
	_cur_energy = _max_energy
	visible = true

# ——— Player Connection ———
func _get_player() -> Node:
	if player_path != NodePath():
		var n = get_node_or_null(player_path)
		if n:
			return n
	var candidates = get_tree().get_nodes_in_group("player")
	return candidates[0] if candidates.size() > 0 else null

func _connect_player_signal() -> void:
	if _player and _player.has_signal("dash_energy_changed"):
		if not _player.dash_energy_changed.is_connected(_on_player_dash_changed):
			_player.dash_energy_changed.connect(_on_player_dash_changed)
			print("✓ Dash bar connected to player signal")

func _on_player_dash_changed(new_energy: int) -> void:
	var max_e = _read_max_energy(_player, _max_energy)
	set_energy(new_energy, max_e)
	print("✓ Dash bar received signal: %d/%d" % [new_energy, max_e])

func _sync_from_player() -> void:
	if not _player:
		return
	_cur_energy = _read_current_energy(_player, _cur_energy)
	_max_energy = _read_max_energy(_player, _max_energy)
	update_dash_bar()

func _read_current_energy(p: Node, fallback: int) -> int:
	if p.has_method("get_dash_energy"):
		return int(p.get_dash_energy())
	elif "dash_energy" in p:
		return int(p.dash_energy)
	elif "current_dash_energy" in p:
		return int(p.current_dash_energy)
	return fallback

func _read_max_energy(p: Node, fallback: int) -> int:
	if p.has_method("get_max_dash_energy"):
		return int(p.get_max_dash_energy())
	elif "max_dash_energy" in p:
		return int(p.max_dash_energy)
	return fallback
