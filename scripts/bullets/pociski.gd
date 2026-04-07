extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))
