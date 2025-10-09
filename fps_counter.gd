extends Label

var times := []

var fps := 0


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()

	while times.size() > 0 and times[0] <= now - 1000:
		times.pop_front()

	times.append(now)
	fps = times.size()

	text = str(fps) + " FPS"
