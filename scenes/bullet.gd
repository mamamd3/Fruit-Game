extends Area2D

var velocity: Vector2
const GRAVITY = 75.0

func setup(pos: Vector2, dir: Vector2):
	position = pos + dir * 12
	velocity = dir * 180

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
