# w Global.gd
extends Node

var game_over = false

var strawberry_health = 100
var grape_health = 70

func _physics_process(delta: float) -> void:
	if Global.game_over:
		return
	if Global.strawberry_health <= 0:
		Global.game_over = true
		get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")
	if Global.grape_health <= 0:
		Global.game_over = true
		get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")
