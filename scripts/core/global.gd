extends Node
signal kill_feed_message(text: String)

# ── Tryb sieciowy ─────────────────────────────────────────────────────────────
var is_network_game:   bool = false   # true gdy gram przez sieć
var main_game:         Node = null    # odniesienie do głównej instancji gry
var local_player_slot: int  = 0       # który slot kontroluję (1-4), 0 = lokalny

var player1_character: String = ""
var player2_character: String = ""
var player3_character: String = ""
var player4_character: String = ""

# Typ slotu: "player" lub "bot" — ustawiany w menu
var slot_types: Dictionary = { 1: "player", 2: "player", 3: "player", 4: "player" }

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

# Oryginalne staty — NIGDY nie modyfikuj tego słownika.
# Służy jako source-of-truth przy każdym reset_all().
const ORIGINAL_BASE_CHARACTERS: Dictionary = {
	"Strawberry": { "hp": 120, "speed": 85,  "dmg": 25, "range": 120, "fire_rate": 0.7 },
	"Orange":     { "hp": 60,  "speed": 95,  "dmg": 65, "range": 450, "fire_rate": 2.0 },
	"Pineapple":  { "hp": 250, "speed": 55,  "dmg": 40, "range": 80,  "fire_rate": 0.6 },
	"Grape":      { "hp": 90,  "speed": 110, "dmg": 10, "range": 180, "fire_rate": 0.15 },
	"Lemon":      { "hp": 80,  "speed": 90,  "dmg": 15, "range": 300, "fire_rate": 0.8 },
	"Watermelon": { "hp": 300, "speed": 40,  "dmg": 70, "range": 90,  "fire_rate": 1.5 },
}

# Kopia robocza — może być modyfikowana przez mody (thick_skin, seed_collector itp.)
# Resetowana z ORIGINAL_BASE_CHARACTERS na początku każdej rundy.
var base_characters: Dictionary = {}
var characters: Dictionary = {}

var modifier_registry: Dictionary = {
	"double_shot":        { "name": "Podwójny strzał",       "emoji": "✌️",  "category": "projectile", "trigger": "on_shoot",   "desc": "Wystrzelasz dodatkowy pocisk obok głównego." },
	"sniper_seed":        { "name": "Pestka snajpera",        "emoji": "🎯",  "category": "projectile", "trigger": "on_shoot",   "desc": "Pocisk leci o 25% szybciej." },
	"fermentation":       { "name": "Fermentacja",            "emoji": "🧪",  "category": "projectile", "trigger": "on_hit",     "desc": "Każdy pocisk zatruwa wroga na 3 sek." },
	"ripe_shot":          { "name": "Dojrzały strzał",        "emoji": "🍑",  "category": "projectile", "trigger": "on_shoot",   "desc": "Co 3. strzał zadaje +30% obrażeń." },
	"shotgun":            { "name": "Shotgun pestek",         "emoji": "💥",  "category": "projectile", "trigger": "on_shoot",   "desc": "Wystrzelasz 3 dodatkowe pociski w wachlarzu." },
	"radioactive_seed":   { "name": "Radioaktywna pestka",    "emoji": "☢️",  "category": "projectile", "trigger": "on_hit",     "desc": "Przy trafieniu zostaje toksyczna plama na 3 sek." },
	"rot_shot":           { "name": "Strzał zgnilizny",       "emoji": "🦠",  "category": "projectile", "trigger": "on_hit",     "desc": "Trafiony wróg gnije o 3 sek szybciej." },
	"magnetic_seed":      { "name": "Magnetyczna pestka",     "emoji": "🧲",  "category": "projectile", "trigger": "on_shoot",   "desc": "Pocisk skręca w kierunku wroga w zasięgu 2m." },
	"thick_skin":         { "name": "Gruba skórka",           "emoji": "🥊",  "category": "defense",    "trigger": "on_apply",   "desc": "Maksymalne HP +35." },
	"juicy_core":         { "name": "Soczyste wnętrze",       "emoji": "💧",  "category": "defense",    "trigger": "on_hit",     "desc": "Odzyskujesz 15% brakującego HP przy trafieniu wroga." },
	"wax_coat":           { "name": "Woskowa powłoka",        "emoji": "🕯️",  "category": "defense",    "trigger": "on_receive", "desc": "Blokujesz pierwsze trafienie w rundzie." },
	"thorn_shield":       { "name": "Kolczasta tarcza",       "emoji": "🌵",  "category": "defense",    "trigger": "on_receive", "desc": "Wrogowie trafiający cię dostają -5 HP." },
	"hard_fruit":         { "name": "Twardy owoc",            "emoji": "🪨",  "category": "defense",    "trigger": "on_receive", "desc": "Redukcja wszystkich obrażeń o 15%." },
	"antirot":            { "name": "Antyzgnilizna",          "emoji": "🧴",  "category": "defense",    "trigger": "passive",    "desc": "Gnijesz o 10 sek wolniej." },
	"preservative":       { "name": "Konserwant",             "emoji": "🛡️",  "category": "defense",    "trigger": "on_apply",   "desc": "Przez pierwsze 15 sek rundy jesteś odporny na efekty negatywne." },
	"second_fruit":       { "name": "Drugi owoc",             "emoji": "🍀",  "category": "defense",    "trigger": "on_lethal",  "desc": "Raz na rundę przeżywasz śmiertelny cios z 5 HP." },
	"still_green":        { "name": "Zielony jeszcze",        "emoji": "🌿",  "category": "defense",    "trigger": "passive",    "desc": "Gdy HP < 30%, regenerujesz 1 HP co 2 sek." },
	"stone_seed":         { "name": "Kamienna pestka",        "emoji": "🗿",  "category": "defense",    "trigger": "on_apply",   "desc": "+10 pancerza, ale -10% prędkości ruchu." },
	"extra_bounce":       { "name": "Dodatkowe odbicie",      "emoji": "↩️",  "category": "bounce",     "trigger": "on_shoot",   "desc": "Pocisk odbija się o +1 powierzchnię więcej." },
	"accelerating_bounce":{ "name": "Przyspieszające odbicie","emoji": "⚡",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Każde odbicie zwiększa prędkość pocisku o 10%." },
	"destroying_bounce":  { "name": "Niszczące odbicie",      "emoji": "💢",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Każde odbicie dodaje +5 DMG." },
	"magnetic_bounce":    { "name": "Magnetyczne odbicie",    "emoji": "🧲",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Po odbiciu pocisk leci w stronę najbliższego wroga przez 2 sek." },
	"mirror_skin":        { "name": "Lustrzana skórka",       "emoji": "🪞",  "category": "defense",    "trigger": "on_receive", "desc": "10% szansa na odbicie ataku wroga." },
	"rage_bounce":        { "name": "Wściekłe odbicie",       "emoji": "😡",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Odbity pocisk zadaje 40% więcej obrażeń." },
	"ripe_sprint":        { "name": "Dojrzały sprint",        "emoji": "👟",  "category": "passive",    "trigger": "on_apply",   "desc": "Prędkość ruchu +15%." },
	"rot_accelerator":    { "name": "Przyspieszacz gnicia",   "emoji": "💀",  "category": "area",       "trigger": "passive",    "desc": "Wrogowie w twoim zasięgu gniją 15% szybciej." },
	"rot_explosion":      { "name": "Gnilna eksplozja",       "emoji": "🌋",  "category": "defense",    "trigger": "passive",    "desc": "Gdy HP < 20%, odpychasz wrogów i leczysz 10 HP (jednorazowo)." },
	"seed_collector":     { "name": "Kolekcjoner pestek",     "emoji": "🌰",  "category": "projectile", "trigger": "on_hit",     "desc": "Każde trafienie bez otrzymania ciosu daje +1 DMG. Reset przy ciosie." },
	"fruit_streak":       { "name": "Owocowa passa",          "emoji": "🔥",  "category": "projectile", "trigger": "on_hit",     "desc": "3 trafienia z rzędu = następny pocisk +40% obrażeń." },
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
	# Projectile
	"double_shot", "sniper_seed", "fermentation", "ripe_shot", "shotgun",
	"radioactive_seed", "rot_shot", "magnetic_seed",
	"lifesteal", "explosive", "sticky", "spinning",
	# Defense
	"thick_skin", "juicy_core", "wax_coat", "thorn_shield", "hard_fruit",
	"antirot", "preservative", "second_fruit", "still_green", "stone_seed",
	"armor",
	# Bounce
	"extra_bounce", "accelerating_bounce", "destroying_bounce",
	"magnetic_bounce", "mirror_skin", "rage_bounce", "bouncy",
	# Passive / Area
	"ripe_sprint", "rot_accelerator", "rot_explosion",
	"seed_collector", "fruit_streak", "mod_duplicator",
	"poison", "speed",
]

func _ready() -> void:
	_setup_gamepads()
	base_characters = ORIGINAL_BASE_CHARACTERS.duplicate(true)
	round_number    = 1
	points          = {}
	modifiers       = {}
	reset_selection()
	reset_all()

func _setup_gamepads() -> void:
	for i in range(4):
		var prefix = "p" + str(i + 1)
		
		# Skok (A)
		var ev_jump = InputEventJoypadButton.new()
		ev_jump.device = i
		ev_jump.button_index = JOY_BUTTON_A
		InputMap.action_add_event(prefix + "_jump", ev_jump)
		
		# Strzał (X / Right Bumper / Right Trigger)
		var ev_shoot = InputEventJoypadButton.new()
		ev_shoot.device = i
		ev_shoot.button_index = JOY_BUTTON_X
		InputMap.action_add_event(prefix + "_shoot", ev_shoot)
		
		var ev_shoot2 = InputEventJoypadButton.new()
		ev_shoot2.device = i
		ev_shoot2.button_index = JOY_BUTTON_RIGHT_SHOULDER
		InputMap.action_add_event(prefix + "_shoot", ev_shoot2)
		
		var ev_shoot_trigger = InputEventJoypadMotion.new()
		ev_shoot_trigger.device = i
		ev_shoot_trigger.axis = JOY_AXIS_TRIGGER_RIGHT
		ev_shoot_trigger.axis_value = 1.0
		InputMap.action_add_event(prefix + "_shoot", ev_shoot_trigger)
		
		# Lewo (D-Pad Left)
		var ev_left = InputEventJoypadButton.new()
		ev_left.device = i
		ev_left.button_index = JOY_BUTTON_DPAD_LEFT
		InputMap.action_add_event(prefix + "_left", ev_left)
		
		# Lewo (Left Stick -X)
		var ev_stick_l = InputEventJoypadMotion.new()
		ev_stick_l.device = i
		ev_stick_l.axis = JOY_AXIS_LEFT_X
		ev_stick_l.axis_value = -1.0
		InputMap.action_add_event(prefix + "_left", ev_stick_l)
		
		# Prawo (D-Pad Right)
		var ev_right = InputEventJoypadButton.new()
		ev_right.device = i
		ev_right.button_index = JOY_BUTTON_DPAD_RIGHT
		InputMap.action_add_event(prefix + "_right", ev_right)
		
		# Prawo (Left Stick +X)
		var ev_stick_r = InputEventJoypadMotion.new()
		ev_stick_r.device = i
		ev_stick_r.axis = JOY_AXIS_LEFT_X
		ev_stick_r.axis_value = 1.0
		InputMap.action_add_event(prefix + "_right", ev_stick_r)

func reset_selection() -> void:
	available_characters   = base_characters.keys()
	selected_characters    = {}
	current_picking_player = 1
	player1_character = ""
	player2_character = ""
	player3_character = ""
	player4_character = ""

func reset_all() -> void:
	base_characters = ORIGINAL_BASE_CHARACTERS.duplicate(true)
	characters      = ORIGINAL_BASE_CHARACTERS.duplicate(true)
	shot_counter = {}
	rot_bonus.clear()
	alive        = {}
	var all_chars = [player1_character, player2_character, player3_character, player4_character]
	for ch in all_chars:
		if ch == "": continue
		alive[ch] = true
		if not points.has(ch):    points[ch]    = 0
		if not modifiers.has(ch): modifiers[ch] = []
		
		# Wbudowane modyfikatory postaci
		if ch == "Lemon" and not "fermentation" in modifiers[ch]:
			modifiers[ch].append("fermentation")
		if ch == "Watermelon" and not "armor" in modifiers[ch]:
			modifiers[ch].append("armor")
			
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
	if character_name != "":
		available_characters.erase(character_name)
	current_picking_player += 1

func all_picked() -> bool:
	# Przeskocz sloty "off" w liczniku
	var last_active_slot = 0
	for i in range(1, 5):
		if slot_types.get(i, "off") != "off":
			last_active_slot = i
	return current_picking_player > last_active_slot

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
	@warning_ignore("integer_division")
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

func spawn_particles(pos: Vector2, color: Color, amount: int = 15) -> void:
	if main_game == null or not is_instance_valid(main_game): return
	var cp = CPUParticles2D.new()
	cp.position = pos
	cp.emitting = true
	cp.one_shot = true
	cp.explosiveness = 0.9
	cp.amount = amount
	cp.lifetime = 0.5
	cp.spread = 180.0
	cp.gravity = Vector2(0, 300)
	cp.initial_velocity_min = 100
	cp.initial_velocity_max = 200
	cp.scale_amount_min = 3.0
	cp.scale_amount_max = 6.0
	cp.color = color
	main_game.add_child(cp)
	get_tree().create_timer(1.0).timeout.connect(cp.queue_free)
