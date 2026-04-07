extends Control

@onready var ip_input:     LineEdit = $VBox/IPInput
@onready var port_input:   LineEdit = $VBox/PortInput
@onready var join_button:  Button   = $VBox/JoinButton
@onready var status_label: Label    = $VBox/StatusLabel


func _ready() -> void:
	ip_input.text   = MultiplayerManager.host_address
	port_input.text = str(MultiplayerManager.port)
	status_label.text = ""
	MultiplayerManager.connected.connect(_on_mp_connected)
	MultiplayerManager.disconnected.connect(_on_mp_disconnected)


func _on_local_pressed() -> void:
	MultiplayerManager.start_single_player()
	get_tree().change_scene_to_file("res://Scenes/ui/choose_character.tscn")


func _on_host_pressed() -> void:
	var p = int(port_input.text)
	if p <= 0: p = 7777
	MultiplayerManager.port = p
	MultiplayerManager.start_server()
	get_tree().change_scene_to_file("res://Scenes/ui/lobby.tscn")


func _on_join_pressed() -> void:
	var addr = ip_input.text.strip_edges()
	var p    = int(port_input.text)
	if addr.is_empty(): addr = "127.0.0.1"
	if p <= 0: p = 7777
	MultiplayerManager.host_address = addr
	MultiplayerManager.port         = p
	status_label.text  = "Łączenie z %s:%d..." % [addr, p]
	join_button.disabled = true
	MultiplayerManager.start_client(addr, p)


func _on_mp_connected() -> void:
	if MultiplayerManager.current_mode == MultiplayerManager.Mode.CLIENT:
		get_tree().change_scene_to_file("res://Scenes/ui/lobby.tscn")


func _on_mp_disconnected() -> void:
	status_label.text    = "Połączenie nieudane. Spróbuj ponownie."
	join_button.disabled = false
