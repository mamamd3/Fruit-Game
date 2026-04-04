extends Node

# Tutaj ustawiasz kto gra jaką postacią przed main game
var player1_character = "warrior"
var player2_character = "sniper"

var characters = {
	"strawberry": {"hp": 200, "speed": 80,  "dmg": 30,  "range": 100, "fire_rate": 0.8},
	"orange":  {"hp": 80,  "speed": 90,  "dmg": 100, "range": 400, "fire_rate": 2.5},
	"pineapple":  {"hp": 120, "speed": 200, "dmg": 20,  "range": 80,  "fire_rate": 0.5},
	"grape":  {"hp": 150, "speed": 100, "dmg": 25,  "range": 150, "fire_rate": 0.2}
}
