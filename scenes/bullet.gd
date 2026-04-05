extends Area2D

var velocity: Vector2
var shooter_name = "Strawberry"  # ← jedyne co zmieniasz między bulletami
const GRAVITY = 75.0

func setup(pos: Vector2, dir: Vector2):
	position = pos + dir *20
	velocity = dir * 180

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Terrain"):
		queue_free()
	if body.is_in_group("strawberry"):
		Global.characters["Strawberry"]["hp"] -= Global.characters[shooter_name]["dmg"]
		print(Global.characters["Strawberry"]["hp"])
		queue_free()
	if body.is_in_group("grape"):
		Global.characters["Grape"]["hp"] -= Global.characters[shooter_name]["dmg"]
		print(Global.characters["Grape"]["hp"])
		queue_free()
	if body.is_in_group("orange"):
		Global.characters["Orange"]["hp"] -= Global.characters[shooter_name]["dmg"]
		print(Global.characters["Orange"]["hp"])
		queue_free()
	if body.is_in_group("pineapple"):
		Global.characters["Pineapple"]["hp"] -= Global.characters[shooter_name]["dmg"]
		print(Global.characters["Pineapple"]["hp"])
		queue_free()
