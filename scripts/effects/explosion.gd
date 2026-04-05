extends Area2D

var shooter_name = ""

func _ready():
	# Zadaj obrażenia wszystkim w zasięgu
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		if body.has_method("apply_slow") and body.character_name != shooter_name:
			var dmg = Global.characters[shooter_name]["dmg"] * 0.5
			Global.characters[body.character_name]["hp"] -= dmg
	queue_free()
