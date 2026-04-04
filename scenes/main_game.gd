extends Node2D
var strawberry_bullet_scene = preload("res://Scenes/strawberry_bullet.tscn")
var grape_bullet_scene = preload("res://Scenes/grape_bullet.tscn")


func _on_strawberry_shoot(pos: Vector2, dir: Vector2) -> void:
	var strawberry_bullet = strawberry_bullet_scene.instantiate() as Area2D
	$Bullets.add_child(strawberry_bullet)
	strawberry_bullet.setup(pos, dir)
	
func _on_grape_shoot(pos: Vector2, dir: Vector2) -> void:
	var grape_bullet = grape_bullet_scene.instantiate() as Area2D
	$Bullets.add_child(grape_bullet)
	grape_bullet.setup(pos, dir)
