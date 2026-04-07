# multiplayermanager.gd
extends Node

# Sygnały, które mogą być emitowane przez ten skrypt
signal connected
signal disconnected
signal message_received(message: String, sender_peer_id: int)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)

# Maksymalna liczba graczy
const MAX_PLAYERS: int = 4

# Enum do określania trybu gry (serwer, klient, pojedynczy gracz)
enum Mode { SINGLE_PLAYER, SERVER, CLIENT }

# Aktualny tryb gry i ID bieżącej instancji gracza
var current_mode: Mode = Mode.SINGLE_PLAYER
var peer_id: int = 0

# Obiekt ENetMultiplayerPeer do zarządzania połączeniem sieciowym
var multiplayer: ENetMultiplayerPeer

# Słownik przechowujący ID wszystkich połączonych graczy (wraz z ID serwera)
var connected_players: Dictionary = {}

# Nazwa hosta do nasłuchiwania lub do którego się łączymy
@export var host_address: String = "127.0.0.1"
# Port, na którym nasłuchuje serwer lub do którego się łączymy
@export var port: int = 7777

# Inicjalizacja klasy
func _ready() -> void:
	# Połącz sygnał 'peer_connected' z metodą _on_peer_connected
	# Połącz sygnał 'peer_disconnected' z metodą _on_peer_disconnected
	# Połącz sygnał 'connection_failed' z metodą _on_connection_failed
	# Połącz sygnał 'server_disconnected' z metodą _on_server_disconnected
	# Te sygnały są dostępne tylko wtedy, gdy 'multiplayer' jest ustawiony
	pass

# Metoda do uruchamiania gry w trybie dla jednego gracza
func start_single_player() -> void:
	print("Uruchamianie w trybie dla jednego gracza.")
	current_mode = Mode.SINGLE_PLAYER
	peer_id = 1 # ID dla gracza lokalnego w trybie solo
	connected_players = {peer_id: "Gracz Lokalny"}
	emit_signal("connected")
	emit_signal("player_joined", peer_id)

# Metoda do uruchamiania gry jako serwer (host)
func start_server() -> void:
	print("Uruchamianie jako serwer...")
	multiplayer = ENetMultiplayerPeer.new()
	
	# Ustawienie trybu serwera i limitu graczy
	var error: Error = multiplayer.create_server(port, MAX_PLAYERS)
	if error != OK:
		printerr("Błąd przy tworzeniu serwera: ", error)
		return

	# Przypisanie obiektu multiplayer do globalnego obiektu multiplayer w silniku
	multiplayer_api.multiplayer_peer = multiplayer
	
	# Ustawienie naszego ID gracza
	peer_id = 1 # Serwer zawsze ma ID 1
	current_mode = Mode.SERVER
	connected_players = {peer_id: "Serwer"}
	
	# Połącz potrzebne sygnały z obiektu ENetMultiplayerPeer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("Serwer uruchomiony na por
