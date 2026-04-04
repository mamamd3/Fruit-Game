extends Node

var player1_character = "strawberry"
var player2_character = "grape"
var round_over = false
var players_alive = 2
var winner = ""
var alive = {
	"strawberry": true,
	"grape": true
}



var base_characters = {
	"strawberry": {"hp": 200, "speed": 80,  "dmg": 30,  "range": 100, "fire_rate": 0.8},
	"orange":      {"hp": 80,  "speed": 90,  "dmg": 100, "range": 400, "fire_rate": 2.5},
	"pineapple":     {"hp": 120, "speed": 200, "dmg": 20,  "range": 80,  "fire_rate": 0.5},
	"grape":     {"hp": 150, "speed": 100, "dmg": 25,  "range": 150, "fire_rate": 0.2}
}

var characters = {}

func _ready():
	reset_all()

func reset_all():
	characters = base_characters.duplicate(true)
	alive = {
		"strawberry": true,
		"grape": true
	}
	round_over = false

func _physics_process(delta: float) -> void:
	if Global.round_over:
		return
	if Global.alive.values().count(true) == 1:
		Global.round_over = true
		get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")




func _on_gnicie_timeout() -> void:
	Global.round_over = true
	get_tree().change_scene_to_file("res://Scenes/draw.tscn")
