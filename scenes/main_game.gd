extends Node2D

var strawberry_bullet_scene = preload("res://Scenes/strawberry_bullet.tscn")
var grape_bullet_scene = preload("res://Scenes/grape_bullet.tscn")

func _on_strawberry_shoot(pos: Vector2, dir: Vector2) -> void:
	var bullet = strawberry_bullet_scene.instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir)

func _on_grape_shoot(pos: Vector2, dir: Vector2) -> void:
	var bullet = grape_bullet_scene.instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir)

func _process(delta: float) -> void:
	$StrawberryHp.text = "Strawberry hp: " + str(Global.characters["strawberry"]["hp"])
	$GrapeHp.text = "Grape hp: " + str(Global.characters["grape"]["hp"])
