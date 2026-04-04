extends Area2D

var velocity: Vector2
const GRAVITY = 75.0

func setup(pos: Vector2, dir: Vector2):
	position = pos + dir * 12
	velocity = dir * 180

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta




func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Terrain"):
		queue_free()
	elif body.is_in_group("strawberry"):
		Global.strawberry_health -= 10
		print(Global.strawberry_health)
		queue_free()
	elif body.is_in_group("grape"):
		Global.grape_health -= 10
		print(Global.grape_health)
		queue_free()
