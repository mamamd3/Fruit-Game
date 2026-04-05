extends Area2D

var shooter_name = ""
var lifetime: float = 3.0
var tick_timer: float = 1.0

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	tick_timer -= delta
	if tick_timer <= 0:
		tick_timer = 1.0
		for body in get_overlapping_bodies():
			if body.has_method("apply_poison") and body.character_name != shooter_name:
				Global.characters[body.character_name]["hp"] -= 8
