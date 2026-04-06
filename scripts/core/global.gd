extends Node

signal kill_feed_message(text: String)

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
var modifier_pickers = []  # ← dodaj na górze
# System rund
var round_number = 1
var rounds_per_set = 5  # co ile rund pokazuje opcję resetu
var points = {}
var modifiers = {}
var all_modifiers = ["speed", "armor", "poison", "lifesteal", "explosive", "sticky", "bouncy", "spinning"]

var base_characters = {
	"Strawberry": {"hp": 100, "speed": 80,  "dmg": 25,  "range": 100, "fire_rate": 0.8},
	"Orange":     {"hp": 50,  "speed": 90,  "dmg": 50, "range": 400, "fire_rate": 2.5},
	"Pineapple":  {"hp": 200, "speed": 150, "dmg": 30,  "range": 80,  "fire_rate": 0.5},
	"Grape":      {"hp": 80, "speed": 80, "dmg": 15,  "range": 150, "fire_rate": 0.2}
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
	if player1_character != "":
		alive[player1_character] = true
		if not points.has(player1_character): points[player1_character] = 0
		if not modifiers.has(player1_character): modifiers[player1_character] = []
	if player2_character != "":
		alive[player2_character] = true
		if not points.has(player2_character): points[player2_character] = 0
		if not modifiers.has(player2_character): modifiers[player2_character] = []
	if player3_character != "":
		alive[player3_character] = true
		if not points.has(player3_character): points[player3_character] = 0
		if not modifiers.has(player3_character): modifiers[player3_character] = []
	if player4_character != "":
		alive[player4_character] = true
		if not points.has(player4_character): points[player4_character] = 0
		if not modifiers.has(player4_character): modifiers[player4_character] = []
	round_over = false
	game_started = false
	winner = ""
	death_order = []
	ranking = []

# Reset WSZYSTKIEGO — nowy mecz
func reset_full_game():
	round_number = 1
	points = {}
	modifiers = {}
	reset_selection()
	reset_all()

func is_set_complete() -> bool:
	return round_number % rounds_per_set == 0

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

func assign_points():
	var point_values = [3, 2, 1, 0]
	for i in range(ranking.size()):
		if i < point_values.size():
			var character = ranking[i]
			if not points.has(character):
				points[character] = 0
			points[character] += point_values[i]

func get_modifier_pickers() -> Array:
	var pickers = []
	# Połowa graczy od końca dostaje modyfikator
	# 2 graczy → ostatni 1 gracz
	# 4 graczy → ostatni 2 graczy
	var half = ranking.size() / 2
	var start = ranking.size() - 1
	var end = ranking.size() - half - 1
	for i in range(start, end, -1):
		pickers.append(ranking[i])
	return pickers

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
		assign_points()
		# Co 5 rund → najpierw set_over
		if is_set_complete():
			get_tree().change_scene_to_file("res://scenes/ui/set_over.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ui/round_ended.tscn")

func take_damage(target: String, amount: float, reason: String = ""):
	var armor_mod = modifiers.get(target, [])
	if armor_mod.has("armor"):
		amount *= 0.7
		print(target + " HP: " + str(characters[target]["hp"]) + " → " + str(characters[target]["hp"] - amount) + " (" + reason + ", zmniejszone przez pancerz)")
	else:
		print(target + " HP: " + str(characters[target]["hp"]) + " → " + str(characters[target]["hp"] - amount) + " (" + reason + ")")
	characters[target]["hp"] -= amount
	var msg = reason + "  →  " + target + " -" + str(int(amount)) + " HP"
	kill_feed_message.emit(msg)
