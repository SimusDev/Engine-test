extends Path3D

func _process(delta: float) -> void:
	$PathFollow3D.progress += 5 * delta
