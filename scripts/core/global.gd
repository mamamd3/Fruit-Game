extends Node
signal kill_feed_message(text: String)

# ── Tryb sieciowy ─────────────────────────────────────────────────────────────
var is_network_game:   bool = false   # true gdy gram przez sieć
var local_player_slot: int  = 0       # który slot kontroluję (1-4), 0 = lokalny

var player1_character: String = ""
var player2_character: String = ""
var player3_character: String = ""
var player4_character: String = ""

var round_over:   bool   = false
var game_started: bool   = false
var winner:       String = ""
var total_players: int   = 4
var current_picking_player: int = 1

var selected_characters:  Dictionary = {}
var available_characters: Array      = []
var alive:                Dictionary = {}

var round_number:   int = 1
var rounds_per_set: int = 5

var points:    Dictionary = {}
var modifiers: Dictionary = {}
var rot_bonus: Dictionary = {}

var death_order:      Array = []
var ranking:          Array = []
var modifier_pickers: Array = []

var shot_counter: Dictionary = {}

var base_characters: Dictionary = {
	"Strawberry": { "hp": 100, "speed": 80,  "dmg": 25, "range": 100, "fire_rate": 0.8 },
	"Orange":     { "hp": 50,  "speed": 90,  "dmg": 50, "range": 400, "fire_rate": 2.5 },
	"Pineapple":  { "hp": 200, "speed": 150, "dmg": 30, "range": 80,  "fire_rate": 0.5 },
	"Grape":      { "hp": 80,  "speed": 100, "dmg": 15, "range": 150, "fire_rate": 0.2 },
}
var characters: Dictionary = {}

var modifier_registry: Dictionary = {
	"double_shot":        { "name": "Podwójny strzał",       "emoji": "✌️",  "category": "projectile", "trigger": "on_shoot",   "desc": "Wystrzelasz dodatkowy pocisk obok głównego." },
	"sniper_seed":        { "name": "Pestka snajpera",        "emoji": "🎯",  "category": "projectile", "trigger": "on_shoot",   "desc": "Pocisk leci o 25% szybciej." },
	"fermentation":       { "name": "Fermentacja",            "emoji": "🧪",  "category": "projectile", "trigger": "on_hit",     "desc": "Każdy pocisk zatruwa wroga na 3 sek." },
	"ripe_shot":          { "name": "Dojrzały strzał",        "emoji": "🍑",  "category": "projectile", "trigger": "on_shoot",   "desc": "Co 3. strzał zadaje +30% obrażeń." },
	"shotgun":            { "name": "Shotgun pestek",         "emoji": "💥",  "category": "projectile", "trigger": "on_shoot",   "desc": "Wystrzelasz 4 dodatkowe pociski w wachlarzu." },
	"radioactive_seed":   { "name": "Radioaktywna pestka",    "emoji": "☢️",  "category": "projectile", "trigger": "on_hit",     "desc": "Przy trafieniu zostaje toksyczna plama na 3 sek." },
	"rot_shot":           { "name": "Strzał zgnilizny",       "emoji": "🦠",  "category": "projectile", "trigger": "on_hit",     "desc": "Trafiony wróg gnije o 3 sek szybciej." },
	"magnetic_seed":      { "name": "Magnetyczna pestka",     "emoji": "🧲",  "category": "projectile", "trigger": "on_shoot",   "desc": "Pocisk skręca w kierunku wroga w zasięgu 2m." },
	"thick_skin":         { "name": "Gruba skórka",           "emoji": "🥊",  "category": "defense",    "trigger": "on_apply",   "desc": "Maksymalne HP +25." },
	"juicy_core":         { "name": "Soczyste wnętrze",       "emoji": "💧",  "category": "defense",    "trigger": "on_hit",     "desc": "Odzyskujesz 15% brakującego HP przy trafieniu wroga." },
	"wax_coat":           { "name": "Woskowa powłoka",        "emoji": "🕯️",  "category": "defense",    "trigger": "on_receive", "desc": "Blokujesz pierwsze trafienie w rundzie." },
	"thorn_shield":       { "name": "Kolczasta tarcza",       "emoji": "🌵",  "category": "defense",    "trigger": "on_receive", "desc": "Wrogowie trafiający cię dostają -3 HP." },
	"hard_fruit":         { "name": "Twardy owoc",            "emoji": "🪨",  "category": "defense",    "trigger": "on_receive", "desc": "Redukcja wszystkich obrażeń o 10%." },
	"antirot":            { "name": "Antyzgnilizna",          "emoji": "🧴",  "category": "defense",    "trigger": "passive",    "desc": "Gnijesz o 5 sek wolniej." },
	"preservative":       { "name": "Konserwant",             "emoji": "🛡️",  "category": "defense",    "trigger": "on_apply",   "desc": "Przez pierwsze 15 sek rundy jesteś odporny na efekty negatywne." },
	"second_fruit":       { "name": "Drugi owoc",             "emoji": "🍀",  "category": "defense",    "trigger": "on_lethal",  "desc": "Raz na rundę przeżywasz śmiertelny cios z 5 HP." },
	"still_green":        { "name": "Zielony jeszcze",        "emoji": "🌿",  "category": "defense",    "trigger": "passive",    "desc": "Gdy HP < 30%, regenerujesz 1 HP co 2 sek." },
	"stone_seed":         { "name": "Kamienna pestka",        "emoji": "🗿",  "category": "defense",    "trigger": "on_apply",   "desc": "+8 pancerza, ale -10% prędkości ruchu." },
	"extra_bounce":       { "name": "Dodatkowe odbicie",      "emoji": "↩️",  "category": "bounce",     "trigger": "on_shoot",   "desc": "Pocisk odbija się o +1 powierzchnię więcej." },
	"accelerating_bounce":{ "name": "Przyspieszające odbicie","emoji": "⚡",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Każde odbicie zwiększa prędkość pocisku o 10%." },
	"destroying_bounce":  { "name": "Niszczące odbicie",      "emoji": "💢",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Każde odbicie dodaje +5 DMG." },
	"magnetic_bounce":    { "name": "Magnetyczne odbicie",    "emoji": "🧲",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Po odbiciu pocisk leci w stronę najbliższego wroga przez 2 sek." },
	"mirror_skin":        { "name": "Lustrzana skórka",       "emoji": "🪞",  "category": "defense",    "trigger": "on_receive", "desc": "10% szansa na odbicie ataku wroga." },
	"rage_bounce":        { "name": "Wściekłe odbicie",       "emoji": "😡",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Odbity pocisk zadaje 30% więcej obrażeń." },
	"ripe_sprint":        { "name": "Dojrzały sprint",        "emoji": "👟",  "category": "passive",    "trigger": "on_apply",   "desc": "Prędkość ruchu +15%." },
	"rot_accelerator":    { "name": "Przyspieszacz gnicia",   "emoji": "💀",  "category": "area",       "trigger": "passive",    "desc": "Wrogowie w twoim zasięgu gniją 15% szybciej." },
	"rot_explosion":      { "name": "Gnilna eksplozja",       "emoji": "🌋",  "category": "defense",    "trigger": "passive",    "desc": "Gdy HP < 20%, odpychasz wrogów i leczysz 10 HP (jednorazowo)." },
	"seed_collector":     { "name": "Kolekcjoner pestek",     "emoji": "🌰",  "category": "projectile", "trigger": "on_hit",     "desc": "Każde trafienie bez otrzymania ciosu daje +1 DMG. Reset przy ciosie." },
	"fruit_streak":       { "name": "Owocowa passa",          "emoji": "🔥",  "category": "projectile", "trigger": "on_hit",     "desc": "3 trafienia z rzędu = następny pocisk +30% obrażeń." },
	"mod_duplicator":     { "name": "Duplikator modów",       "emoji": "🔄",  "category": "passive",    "trigger": "on_apply",   "desc": "Losowy posiadany modyfikator zostaje skopiowany." },
	"bouncy":   { "name": "Odbijające pociski", "emoji": "↩️", "category": "bounce",     "trigger": "on_shoot",   "desc": "Pociski odbijają się 4 razy." },
	"spinning": { "name": "Wirujące pociski",   "emoji": "🌪️", "category": "projectile", "trigger": "passive",    "desc": "Pociski poruszają się sinusoidalnie." },
	"poison":   { "name": "Ślad trucizny",      "emoji": "☠️", "category": "area",       "trigger": "passive",    "desc": "Gracz zostawia toksyczny ślad." },
	"lifesteal":{ "name": "Kradzież HP",        "emoji": "🔴", "category": "projectile", "trigger": "on_hit",     "desc": "Odzyskujesz 30% zadanych obrażeń jako HP." },
	"explosive":{ "name": "Eksplodujące",       "emoji": "💣", "category": "projectile", "trigger": "on_hit",     "desc": "Pociski eksplodują przy trafieniu." },
	"sticky":   { "name": "Lepkie pociski",     "emoji": "🐌", "category": "projectile", "trigger": "on_hit",     "desc": "Trafiony wróg jest spowolniony przez 3 sek." },
	"armor":    { "name": "Pancerz",            "emoji": "🛡️", "category": "defense",    "trigger": "on_receive", "desc": "Redukuje obrażenia o 30%." },
	"speed":    { "name": "+20% prędkość",      "emoji": "👟", "category": "passive",    "trigger": "on_apply",   "desc": "Prędkość ruchu +20%." },
}

var all_modifiers: Array = [
	"double_shot", "sniper_seed", "fermentation", "ripe_shot", "shotgun",
	"radioactive_seed", "rot_shot", "magnetic_seed",
	"thick_skin", "juicy_core", "wax_coat", "thorn_shield", "hard_fruit",
	"antirot", "preservative", "second_fruit", "still_green", "stone_seed",
	"extra_bounce", "accelerating_bounce", "destroying_bounce",
	"magnetic_bounce", "mirror_skin", "rage_bounce",
	"ripe_sprint", "rot_accelerator", "rot_explosion",
	"seed_collector", "fruit_streak", "mod_duplicator",
]

func _ready() -> void:
	# Pełny reset przy każdym starcie gry
	round_number = 1
	points       = {}
	modifiers    = {}
	reset_selection()
	reset_all()

func reset_selection() -> void:
	available_characters   = base_characters.keys()
	selected_characters    = {}
	current_picking_player = 1
	player1_character = ""
	player2_character = ""
	player3_character = ""
	player4_character = ""

func reset_all() -> void:
	characters   = base_characters.duplicate(true)
	shot_counter = {}
	rot_bonus    = {}
	alive        = {}
	var all_chars = [player1_character, player2_character, player3_character, player4_character]
	for ch in all_chars:
		if ch == "": continue
		alive[ch] = true
		if not points.has(ch):    points[ch]    = 0
		if not modifiers.has(ch): modifiers[ch] = []
	round_over   = false
	game_started = false
	winner       = ""
	death_order  = []
	ranking      = []

func reset_full_game() -> void:
	round_number = 1
	points       = {}
	modifiers    = {}
	reset_selection()
	reset_all()

func pick_character(character_name: String) -> void:
	selected_characters[current_picking_player] = character_name
	match current_picking_player:
		1: player1_character = character_name
		2: player2_character = character_name
		3: player3_character = character_name
		4: player4_character = character_name
	available_characters.erase(character_name)
	current_picking_player += 1

func all_picked() -> bool:
	return current_picking_player > total_players

func is_set_complete() -> bool:
	return round_number % rounds_per_set == 0

func assign_points() -> void:
	# Remis (gnicie) — nikt nie dostaje punktów
	if Global.winner == "":
		return

	var point_values = [3, 2, 1, 0]
	for i in range(ranking.size()):
		if i < point_values.size():
			var ch = ranking[i]
			if not points.has(ch): points[ch] = 0
			points[ch] += point_values[i]

func get_modifier_pickers() -> Array:
	var half: int = ranking.size() / 2
	var pickers = []
	for i in range(ranking.size() - 1, ranking.size() - half - 1, -1):
		pickers.append(ranking[i])
	return pickers

func build_ranking() -> void:
	ranking = []
	for ch in alive:
		if alive[ch]: ranking.append(ch)
	var rev = death_order.duplicate()
	rev.reverse()
	for ch in rev: ranking.append(ch)

func take_damage(target: String, amount: float, reason: String = "") -> void:
	if amount <= 0.0 or not characters.has(target): return
	characters[target]["hp"] -= amount
	var msg = reason + "  →  " + target + " -" + str(int(amount)) + " HP"
	print(msg)
	kill_feed_message.emit(msg)
	# W trybie sieciowym serwer synchronizuje HP do wszystkich klientów
	if is_network_game and multiplayer.is_server():
		_rpc_sync_hp.rpc(target, float(characters[target]["hp"]))

@rpc("authority", "call_remote", "reliable")
func _rpc_sync_hp(target: String, hp: float) -> void:
	if characters.has(target):
		characters[target]["hp"] = hp

@rpc("authority", "call_local", "reliable")
func rpc_reset_all() -> void:
	reset_all()

# _physics_process USUNIĘTY CAŁKOWICIE
# Koniec rundy wykrywa wyłącznie main_game.gd
