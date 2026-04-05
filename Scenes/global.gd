extends Node

var player1_character = ""
var player2_character = ""
var player3_character = ""
var player4_character = ""
var round_over = false
var game_started = false
var players_alive = 4
var winner = ""
var total_players = 4
var current_picking_player = 1
var selected_characters = {}
var available_characters = []
var alive = {}

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
	reset_selection()
	reset_all()

func reset_selection():
	available_characters = base_characters.keys()
	selected_characters = {}
	current_picking_player = 1
	player1_character = ""
	player2_character = ""
	player3_character = ""
	player4_character = ""

func reset_all():
	characters = base_characters.duplicate(true)
	alive = {}
	if player1_character != "": alive[player1_character] = true
	if player2_character != "": alive[player2_character] = true
	if player3_character != "": alive[player3_character] = true
	if player4_character != "": alive[player4_character] = true
	round_over = false
	game_started = false
	winner = ""
	death_order = []
	ranking = []

func pick_character(character_name: String):
	selected_characters[current_picking_player] = character_name
	if current_picking_player == 1:
		player1_character = character_name
	elif current_picking_player == 2:
		player2_character = character_name
	elif current_picking_player == 3:
		player3_character = character_name
	elif current_picking_player == 4:
		player4_character = character_name
	available_characters.erase(character_name)
	current_picking_player += 1

func all_picked() -> bool:
	return current_picking_player > total_players

func build_ranking():
	ranking = []
	for character in alive:
		if alive[character]:
			ranking.append(character)
	var reversed_deaths = death_order.duplicate()
	reversed_deaths.reverse()
	for character in reversed_deaths:
		ranking.append(character)

func _physics_process(_delta: float) -> void:
	if round_over or !game_started:
		return
	if alive.values().count(true) == 1:
		round_over = true
		for character in alive:
			if alive[character]:
				winner = character
		build_ranking()
		get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")
