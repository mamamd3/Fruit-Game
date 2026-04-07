extends Node2D

var character_scenes = {
	"Strawberry": {
		"scene":  preload("res://scenes/characters/strawberry.tscn"),
		"bullet": preload("res://scenes/bullets/strawberry_bullet.tscn")
	},
	"Grape": {
		"scene":  preload("res://scenes/characters/grape.tscn"),
		"bullet": preload("res://scenes/bullets/grape_bullet.tscn")
	},
	"Orange": {
		"scene":  preload("res://scenes/characters/orange.tscn"),
		"bullet": preload("res://scenes/bullets/orange_bullet.tscn")
	},
	"Pineapple": {
		"scene":  preload("res://scenes/characters/pineapple.tscn"),
		"bullet": preload("res://scenes/bullets/pineapple_bullet.tscn")
	}
}

var bullet_scenes:     Dictionary = {}
var player_characters: Dictionary = {}
var kill_feed_script   = preload("res://scripts/ui/kill_feed.gd")
var bot_controller_scn = preload("res://scripts/ai/bot_controller.gd")
var _ending_round: bool = false


func _ready() -> void:
	Global.reset_all()
	_setup_kill_feed()
	Global.game_started = true
	_ending_round = false

	print("=== RUNDA " + str(Global.round_number) + " ===")
	for character in Global.modifiers:
		if Global.modifiers[character].size() > 0:
			print(character + " mody: " + str(Global.modifiers[character]))

	_spawn_player(Global.player1_character, $Players/SpawnPoint1.position, "p1")
	_spawn_player(Global.player2_character, $Players/SpawnPoint2.position, "p2")
	_spawn_player(Global.player3_character, $Players/SpawnPoint3.position, "p3")
	_spawn_player(Global.player4_character, $Players/SpawnPoint4.position, "p4")

	$Gnicie.start()


func _spawn_player(character_name: String, spawn_pos: Vector2, player_prefix: String) -> void:
	if character_name == "":
		return
	var data   = character_scenes[character_name]
	var player = data["scene"].instantiate()
	# Nadaj spójną nazwę węzła — wymagana przez RPC przez sieć
	player.name         = player_prefix
	player.action_left  = player_prefix + "_left"
	player.action_right = player_prefix + "_right"
	player.action_jump  = player_prefix + "_jump"
	player.action_shoot = player_prefix + "_shoot"
	player.position     = spawn_pos
	bullet_scenes[player_prefix]     = data["bullet"]
	player_characters[player_prefix] = character_name
	player.shoot.connect(func(pos, dir): _on_shoot(pos, dir, player_prefix))
	$Players.add_child(player)

	# Bot AI — jeśli slot to bot, dodaj kontroler i wyłącz input gracza
	var slot = int(player_prefix.substr(1))  # "p1" → 1
	if Global.slot_types.get(slot, "player") == "bot":
		var bot = Node.new()
		bot.set_script(bot_controller_scn)
		bot.name = "BotController"
		player.add_child(bot)
		bot.setup(player, character_name)
		# Wyłącz input gracza — bot steruje ruchem
		player.action_left  = ""
		player.action_right = ""
		player.action_jump  = ""
		player.action_shoot = ""

	# W trybie sieciowym przypisz właściciela węzła
	if Global.is_network_game:
		var owner_id = MultiplayerManager.get_peer_for_slot(slot)
		if owner_id > 0:
			player.network_owner_id = owner_id
			player.is_remote = (owner_id != multiplayer.get_unique_id())


func _setup_kill_feed() -> void:
	var canvas        = CanvasLayer.new()
	canvas.layer      = 10
	add_child(canvas)
	var feed          = VBoxContainer.new()
	feed.script       = kill_feed_script
	feed.anchor_right = 1.0
	feed.offset_left  = 4
	feed.offset_top   = 4
	feed.offset_right = -4
	canvas.add_child(feed)


func _on_shoot(pos: Vector2, dir: Vector2, player_prefix: String) -> void:
	if _ending_round:
		return
	if Global.is_network_game:
		# Strzelający klient rozsyła żądanie spawnu pocisku do wszystkich
		_rpc_spawn_bullet.rpc(pos, dir, player_prefix)
	else:
		_do_spawn_bullet(pos, dir, player_prefix)


@rpc("any_peer", "call_local", "reliable")
func _rpc_spawn_bullet(pos: Vector2, dir: Vector2, player_prefix: String) -> void:
	# Walidacja: nadawca może strzelać tylko swoją postacią
	if Global.is_network_game and multiplayer.is_server():
		var sender = multiplayer.get_remote_sender_id()
		if sender > 0:
			var expected_slot = int(player_prefix.substr(1))
			var actual_slot = MultiplayerManager.player_slots.get(sender, -1)
			if expected_slot != actual_slot:
				return  # cheat attempt — ignoruj
	_do_spawn_bullet(pos, dir, player_prefix)


func _do_spawn_bullet(pos: Vector2, dir: Vector2, player_prefix: String) -> void:
	if not bullet_scenes.has(player_prefix):
		return
	var char_name: String = player_characters.get(player_prefix, "")
	if char_name == "":
		return

	var bullet = bullet_scenes[player_prefix].instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir, char_name)

	var extra_dirs: Array = ModifierSystem.get_extra_bullet_dirs(char_name, dir)
	for extra_dir in extra_dirs:
		var extra = bullet_scenes[player_prefix].instantiate() as Area2D
		$Bullets.add_child(extra)
		extra.setup(pos, extra_dir, char_name)


func _on_gnicie_timeout() -> void:
	_end_round("")


func _physics_process(_delta: float) -> void:
	if _ending_round:
		return
	# W trybie sieciowym koniec rundy wykrywa tylko serwer
	if Global.is_network_game and not multiplayer.is_server():
		return
	var alive_count = Global.alive.values().count(true)
	if alive_count <= 1:
		var winner = ""
		for ch in Global.alive:
			if Global.alive[ch]:
				winner = ch
				break
		_end_round(winner)


func _end_round(winning_character: String) -> void:
	if _ending_round:
		return
	_ending_round     = true
	Global.round_over = true
	Global.winner     = winning_character

	if has_node("Gnicie"):
		$Gnicie.stop()

	Global.build_ranking()
	Global.assign_points()

	if winning_character == "":
		Global.modifier_pickers = []

	if Global.is_network_game:
		# Serwer zmienia scenę dla wszystkich
		_rpc_end_round.rpc(winning_character)
	else:
		_do_scene_change()


@rpc("authority", "call_local", "reliable")
func _rpc_end_round(winner: String) -> void:
	Global.winner     = winner
	Global.round_over = true
	_do_scene_change()


func _do_scene_change() -> void:
	if Global.is_set_complete():
		if Global.is_network_game:
			MultiplayerManager.server_change_scene("res://scenes/ui/set_over.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ui/set_over.tscn")
	else:
		if Global.is_network_game:
			MultiplayerManager.server_change_scene("res://scenes/ui/round_ended.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ui/round_ended.tscn")


# ─── SPECTATOR OVERLAY ────────────────────────────────────────────────────────

## Serwer wywołuje tę funkcję na kliencie-obserwatorze, aby pokazał nakładkę.
@rpc("authority", "call_remote", "reliable")
func _rpc_notify_spectating() -> void:
	_show_spectator_overlay()

func _show_spectator_overlay() -> void:
	var canvas        = CanvasLayer.new()
	canvas.layer      = 20
	add_child(canvas)
	var lbl           = Label.new()
	lbl.text          = "OBSERWATOR"
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.anchor_right  = 1.0
	lbl.anchor_bottom = 1.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)
