extends Sprite2D

@export var player_path: NodePath
@export var invert_frames: bool = true         
@export var use_floor_instead_of_round: bool = false  # For discrete steps, set true
@export var low_health_threshold: float = 0.2     # <= 20% triggers optional blink
@export var low_health_blink: bool = false
@export var blink_speed: float = 6.0              # Blink frequency when low

var _player: Node = null
var _max_health: int = 1
var _cur_health: int = 1
var _blink_t: float = 0.0

func _ready() -> void:
	_player = _get_player()
	_sync_from_player()
	_connect_player_signal()
	_apply_frame()

func _process(delta: float) -> void:
	if low_health_blink and _max_health > 0 and float(_cur_health) / float(_max_health) <= low_health_threshold:
		_blink_t += delta * blink_speed
		modulate.a = 0.7 + 0.3 * sin(_blink_t) * 0.5 + 0.15
	else:
		if modulate.a != 1.0:
			modulate.a = 1.0

# External API (optional) - call from UI or gameplay code if you prefer manual updates
func set_health(current: int, max_h: int) -> void:
	_cur_health = max(0, current)
	_max_health = max(1, max_h)
	_apply_frame()

func set_player(p: Node) -> void:
	_player = p
	_sync_from_player()
	_connect_player_signal()
	_apply_frame()

# ——— Internals ———

func _get_player() -> Node:
	if player_path != NodePath():
		var n = get_node_or_null(player_path)
		if n:
			return n
	var candidates = get_tree().get_nodes_in_group("player")
	return candidates[0] if candidates.size() > 0 else null

func _connect_player_signal() -> void:
	if _player and _player.has_signal("health_changed"):
		if not _player.health_changed.is_connected(_on_player_health_changed):
			_player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health: int) -> void:
	_cur_health = max(0, new_health)
	_max_health = _read_max_health(_player, _max_health)
	_apply_frame()

func _sync_from_player() -> void:
	if not _player:
		return
	_cur_health = _read_current_health(_player, _cur_health)
	_max_health = _read_max_health(_player, _max_health)

func _read_current_health(p: Node, fallback: int) -> int:
	if p.has_method("get_current_health"):
		return int(p.get_current_health())
	elif p.has_method("get_health"):
		return int(p.get_health())
	elif "current_health" in p:
		return int(p.current_health)
	elif "health" in p:
		return int(p.health)
	return fallback

func _read_max_health(p: Node, fallback: int) -> int:
	if p.has_method("get_max_health"):
		return int(p.get_max_health())
	elif "max_health" in p:
		return int(p.max_health)
	return fallback

func _apply_frame() -> void:
	var total: int = max(1, hframes * vframes)
	var ratio: float = 0.0
	if _max_health > 0:
		ratio = clamp(float(_cur_health) / float(_max_health), 0.0, 1.0)

	var idx: int
	if use_floor_instead_of_round:
		idx = int(floor(float(total - 1) * ratio))
	else:
		idx = int(round(float(total - 1) * ratio))

	if invert_frames:
		idx = (total - 1) - idx

	frame = clamp(idx, 0, total - 1)
