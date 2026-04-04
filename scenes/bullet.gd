extends Area2D

var direction: Vector2

func setup(pos: Vector2, dir: Vector2):
	position = pos + dir * 12
	direction = dir
	
func _physics_process(delta: float) -> void:
	position += direction * 30 * delta
