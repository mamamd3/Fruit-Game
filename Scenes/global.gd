extends Node

var player1_character = "Strawberry"
var player2_character = "Grape"
var round_over = false
var players_alive = 2
var winner = ""
var alive = {
	"Strawberry": true,
	"Grape": true
}


var base_characters = {
	"Strawberry": {"hp": 200, "speed": 80,  "dmg": 30,  "range": 100, "fire_rate": 0.8},
	"Orange":     {"hp": 80,  "speed": 90,  "dmg": 100, "range": 400, "fire_rate": 2.5},
	"Pineapple":  {"hp": 120, "speed": 200, "dmg": 20,  "range": 80,  "fire_rate": 0.5},
	"Grape":      {"hp": 150, "speed": 100, "dmg": 25,  "range": 150, "fire_rate": 0.2}
}
var characters = {}
var death_order = []
var ranking = []

func _ready():
	reset_all()

func reset_all():
	characters = base_characters.duplicate(true)
	# Buduj alive dynamicznie z wybranych postaci
	alive = {}
	alive[player1_character] = true
	alive[player2_character] = true
	round_over = false
	winner = ""
	death_order = []
	ranking = []

func build_ranking():
	ranking = []
	# Żywy gracz = wygrał = pierwsze miejsce
	for character in alive:
		if alive[character]:
			ranking.append(character)
	# Martwi w odwrotnej kolejności śmierci
	var reversed_deaths = death_order.duplicate()
	reversed_deaths.reverse()
	for character in reversed_deaths:
		ranking.append(character)

func _physics_process(_delta: float) -> void:
	if round_over:
		return
	if alive.values().count(true) == 1:
		round_over = true
		# Znajdź zwycięzcę wprost
		for character in alive:
			if alive[character]:
				winner = character
		build_ranking()
		get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")

func _on_gnicie_timeout() -> void:
	round_over = true
	# Nie budujemy rankingu — w draw.tscn czytasz Global.alive
	get_tree().change_scene_to_file("res://Scenes/draw.tscn")
